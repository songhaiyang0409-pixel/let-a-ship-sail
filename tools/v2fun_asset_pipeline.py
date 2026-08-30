#!/usr/bin/env python3
"""Non-destructive local intake and inspection for manually downloaded V2FUN assets."""

from __future__ import annotations

import hashlib
import json
import shutil
import struct
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlparse


PROJECT_ROOT = Path(__file__).resolve().parents[1]
INBOX_ROOT = PROJECT_ROOT / "V2FUN_INBOX"
INCOMING_DIR = INBOX_ROOT / "incoming"
ORIGINALS_DIR = INBOX_ROOT / "originals"
WORKING_DIR = INBOX_ROOT / "working"
REPORTS_DIR = INBOX_ROOT / "reports"
PREVIEWS_DIR = INBOX_ROOT / "previews"
LEDGER_PATH = INBOX_ROOT / "ledger.json"
SUPPORTED = {".glb", ".gltf", ".fbx", ".obj"}
EXCLUDED_DIRS = {"originals", "working", "reports", "previews"}


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def project_rel(path: Path) -> str:
    return path.relative_to(PROJECT_ROOT).as_posix()


def ensure_structure() -> None:
    for directory in (INBOX_ROOT, INCOMING_DIR, ORIGINALS_DIR, WORKING_DIR, REPORTS_DIR, PREVIEWS_DIR):
        directory.mkdir(parents=True, exist_ok=True)
    if not LEDGER_PATH.exists():
        LEDGER_PATH.write_text("[]\n", encoding="utf-8")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_png_size(data: bytes) -> tuple[int, int] | None:
    if len(data) >= 24 and data[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", data[16:24])
    return None


def read_jpeg_size(data: bytes) -> tuple[int, int] | None:
    if len(data) < 4 or data[:2] != b"\xff\xd8":
        return None
    cursor = 2
    while cursor + 9 < len(data):
        if data[cursor] != 0xFF:
            cursor += 1
            continue
        marker = data[cursor + 1]
        cursor += 2
        if marker in {0xD8, 0xD9}:
            continue
        if cursor + 2 > len(data):
            return None
        length = struct.unpack(">H", data[cursor:cursor + 2])[0]
        if marker in set(range(0xC0, 0xC4)) | set(range(0xC5, 0xC8)) | set(range(0xC9, 0xCC)) | set(range(0xCD, 0xD0)):
            if cursor + 7 <= len(data):
                height, width = struct.unpack(">HH", data[cursor + 3:cursor + 7])
                return width, height
        if length < 2:
            return None
        cursor += length
    return None


def image_size(path: Path) -> tuple[int, int] | None:
    try:
        data = path.read_bytes()
        return read_png_size(data[:64]) or read_jpeg_size(data[:65536])
    except OSError:
        return None


def parse_glb(path: Path) -> tuple[dict, bytes, list[str]]:
    missing: list[str] = []
    data = path.read_bytes()
    if len(data) < 20 or data[:4] != b"glTF":
        raise ValueError("invalid GLB header")
    _, version, declared_length = struct.unpack("<4sII", data[:12])
    if version != 2:
        raise ValueError(f"unsupported GLB version {version}")
    if declared_length > len(data):
        raise ValueError("GLB declares a length larger than the file")
    cursor = 12
    json_chunk: bytes | None = None
    binary_chunk = b""
    while cursor + 8 <= len(data):
        chunk_length, chunk_type = struct.unpack("<II", data[cursor:cursor + 8])
        chunk = data[cursor + 8:cursor + 8 + chunk_length]
        if chunk_type == 0x4E4F534A:
            json_chunk = chunk
        elif chunk_type == 0x004E4942:
            binary_chunk = chunk
        cursor += 8 + chunk_length
    if json_chunk is None:
        raise ValueError("GLB JSON chunk is missing")
    document = json.loads(json_chunk.rstrip(b" \t\r\n\x00").decode("utf-8"))
    for buffer in document.get("buffers", []):
        uri = buffer.get("uri")
        if uri and not uri.startswith("data:"):
            external = path.parent / unquote(urlparse(uri).path)
            if not external.exists():
                missing.append(str(external))
    return document, binary_chunk, missing


def parse_gltf(path: Path) -> tuple[dict, bytes, list[str]]:
    document = json.loads(path.read_text(encoding="utf-8"))
    missing: list[str] = []
    for buffer in document.get("buffers", []):
        uri = buffer.get("uri")
        if uri and not uri.startswith("data:"):
            external = path.parent / unquote(urlparse(uri).path)
            if not external.exists():
                missing.append(str(external))
    for image in document.get("images", []):
        uri = image.get("uri")
        if uri and not uri.startswith("data:"):
            external = path.parent / unquote(urlparse(uri).path)
            if not external.exists():
                missing.append(str(external))
    return document, b"", missing


def accessor_count(document: dict, accessor_index: int | None) -> int:
    if accessor_index is None:
        return 0
    accessors = document.get("accessors", [])
    if accessor_index < 0 or accessor_index >= len(accessors):
        return 0
    return int(accessors[accessor_index].get("count", 0))


def gltf_image_sizes(path: Path, document: dict, binary: bytes) -> list[dict]:
    results: list[dict] = []
    for image in document.get("images", []):
        uri = image.get("uri")
        size: tuple[int, int] | None = None
        image_name = image.get("name") or uri or "embedded-image"
        if uri and not uri.startswith("data:"):
            external = path.parent / unquote(urlparse(uri).path)
            size = image_size(external) if external.exists() else None
        elif image.get("bufferView") is not None:
            views = document.get("bufferViews", [])
            view_index = int(image["bufferView"])
            if 0 <= view_index < len(views):
                view = views[view_index]
                start = int(view.get("byteOffset", 0))
                end = start + int(view.get("byteLength", 0))
                payload = binary[start:end]
                size = read_png_size(payload[:64]) or read_jpeg_size(payload[:65536])
        results.append({"name": image_name, "resolution": list(size) if size else None})
    return results


def inspect_gltf(path: Path) -> dict:
    document, binary, missing = parse_glb(path) if path.suffix.lower() == ".glb" else parse_gltf(path)
    vertices = 0
    triangles = 0
    primitive_count = 0
    material_indices: set[int] = set()
    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            primitive_count += 1
            position_accessor = primitive.get("attributes", {}).get("POSITION")
            position_count = accessor_count(document, position_accessor)
            vertices += position_count
            index_count = accessor_count(document, primitive.get("indices"))
            if index_count:
                mode = int(primitive.get("mode", 4))
                triangles += index_count // 3 if mode in {4, 5, 6} else 0
            else:
                triangles += position_count // 3
            if primitive.get("material") is not None:
                material_indices.add(int(primitive["material"]))
    return {
        "mesh_count": len(document.get("meshes", [])),
        "primitive_count": primitive_count,
        "vertex_count": vertices,
        "triangle_count": triangles,
        "polygon_count": triangles,
        "material_count": len(document.get("materials", [])) or len(material_indices),
        "texture_count": len(document.get("textures", [])),
        "image_count": len(document.get("images", [])),
        "texture_resolutions": gltf_image_sizes(path, document, binary),
        "animation_count": len(document.get("animations", [])),
        "skeleton_count": len(document.get("skins", [])),
        "missing_external_textures": missing,
        "inspection_note": "GLB/glTF JSON and accessors inspected with the local standard-library parser.",
    }


def inspect_obj(path: Path) -> dict:
    vertex_count = 0
    triangle_count = 0
    materials: set[str] = set()
    mtllibs: list[Path] = []
    texture_paths: list[Path] = []
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for raw in handle:
            line = raw.strip()
            if line.startswith("v "):
                vertex_count += 1
            elif line.startswith("f "):
                corners = line.split()[1:]
                triangle_count += max(0, len(corners) - 2)
            elif line.startswith("usemtl "):
                materials.add(line.split(maxsplit=1)[1].strip())
            elif line.startswith("mtllib "):
                for name in line.split()[1:]:
                    mtllibs.append(path.parent / name)
    for mtl in mtllibs:
        if not mtl.exists():
            continue
        with mtl.open("r", encoding="utf-8", errors="replace") as handle:
            for raw in handle:
                line = raw.strip()
                if line.lower().startswith(("map_kd ", "map_ks ", "map_bump ", "bump ", "map_d ")):
                    texture_paths.append(mtl.parent / line.split(maxsplit=1)[1].strip())
    missing = [str(p) for p in texture_paths if not p.exists()]
    resolutions = []
    for texture_path in texture_paths:
        if texture_path.exists():
            size = image_size(texture_path)
            resolutions.append({"name": texture_path.name, "resolution": list(size) if size else None})
    return {
        "mesh_count": 1,
        "primitive_count": 1,
        "vertex_count": vertex_count,
        "triangle_count": triangle_count,
        "polygon_count": triangle_count,
        "material_count": len(materials),
        "texture_count": len(texture_paths),
        "image_count": len(texture_paths),
        "texture_resolutions": resolutions,
        "animation_count": 0,
        "skeleton_count": 0,
        "missing_external_textures": missing,
        "inspection_note": "OBJ geometry and MTL texture references inspected with the local standard-library parser.",
    }


def inspect_fbx(path: Path) -> dict:
    return {
        "mesh_count": None,
        "primitive_count": None,
        "vertex_count": None,
        "triangle_count": None,
        "polygon_count": None,
        "material_count": None,
        "texture_count": None,
        "image_count": None,
        "texture_resolutions": [],
        "animation_count": None,
        "skeleton_count": None,
        "missing_external_textures": [],
        "inspection_note": "FBX structural inspection unavailable: Blender/Assimp is not installed. The original was preserved unchanged.",
    }


def inspect_asset(path: Path) -> dict:
    suffix = path.suffix.lower()
    try:
        if suffix in {".glb", ".gltf"}:
            return inspect_gltf(path)
        if suffix == ".obj":
            return inspect_obj(path)
        if suffix == ".fbx":
            return inspect_fbx(path)
        return {"inspection_note": "Unsupported format"}
    except Exception as exc:
        return {
            "mesh_count": None,
            "primitive_count": None,
            "vertex_count": None,
            "triangle_count": None,
            "polygon_count": None,
            "material_count": None,
            "texture_count": None,
            "image_count": None,
            "texture_resolutions": [],
            "animation_count": None,
            "skeleton_count": None,
            "missing_external_textures": [],
            "inspection_note": f"Inspection error: {exc}",
            "parse_error": True,
        }


def classify(details: dict) -> tuple[str, list[str]]:
    flags: list[str] = []
    triangles = details.get("triangle_count")
    if triangles is None:
        flags.append("geometry statistics unavailable")
    elif triangles >= 300_000:
        flags.append("very high triangle count; mobile optimization required")
    elif triangles >= 100_000:
        flags.append("high triangle count; mobile optimization likely required")
    resolutions = [item.get("resolution") for item in details.get("texture_resolutions", [])]
    if any(size and max(size) > 2048 for size in resolutions):
        flags.append("texture larger than 2048px")
    if details.get("missing_external_textures"):
        flags.append("missing external texture or material dependency")
    if details.get("parse_error"):
        return "C", flags + ["parser failed; reference-only until inspected with a DCC tool"]
    if details.get("inspection_note", "").startswith("FBX structural"):
        return "B", flags + ["FBX requires Blender/Assimp inspection before approval"]
    if triangles is not None and triangles <= 80_000 and not details.get("missing_external_textures") and not flags:
        return "A", flags
    return "B", flags


def load_ledger() -> list[dict]:
    try:
        return json.loads(LEDGER_PATH.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []


def unique_copy_path(directory: Path, stem: str, suffix: str, digest8: str) -> Path:
    candidate = directory / f"{stem}__{digest8}{suffix}"
    counter = 2
    while candidate.exists():
        candidate = directory / f"{stem}__{digest8}_{counter}{suffix}"
        counter += 1
    return candidate


def referenced_dependency_paths(path: Path) -> list[Path]:
    dependencies: list[Path] = []
    if path.suffix.lower() == ".gltf":
        try:
            document = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return dependencies
        for item in document.get("buffers", []) + document.get("images", []):
            uri = item.get("uri")
            if uri and not uri.startswith("data:"):
                dependencies.append(path.parent / unquote(urlparse(uri).path))
    elif path.suffix.lower() == ".obj":
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            return dependencies
        for line in lines:
            if line.strip().lower().startswith("mtllib "):
                for name in line.split()[1:]:
                    dependencies.append(path.parent / name)
        for mtl in list(dependencies):
            if not mtl.exists():
                continue
            try:
                mtl_lines = mtl.read_text(encoding="utf-8", errors="replace").splitlines()
            except OSError:
                continue
            for line in mtl_lines:
                if line.strip().lower().startswith(("map_kd ", "map_ks ", "map_bump ", "bump ", "map_d ")):
                    dependencies.append(mtl.parent / line.split(maxsplit=1)[1].strip())
    return [item for item in dict.fromkeys(dependencies) if item.exists()]


def copy_asset_package(source: Path, destination_root: Path, digest8: str) -> Path:
    dependencies = referenced_dependency_paths(source)
    if not dependencies:
        target = unique_copy_path(destination_root, source.stem, source.suffix.lower(), digest8)
        shutil.copy2(source, target)
        return target
    package_dir = destination_root / f"{source.stem}__{digest8}"
    package_dir.mkdir(parents=True, exist_ok=True)
    target = package_dir / source.name
    shutil.copy2(source, target)
    source_parent = source.parent.resolve()
    for dependency in dependencies:
        try:
            relative = dependency.resolve().relative_to(source_parent)
        except ValueError:
            relative = Path(dependency.name)
        dependency_target = package_dir / relative
        dependency_target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dependency, dependency_target)
    return target


def write_asset_report(report_path: Path, source: Path, original: Path, derivative: Path, digest: str, details: dict, classification: str, flags: list[str]) -> None:
    lines = [
        f"# V2FUN Asset Inspection — {source.name}",
        "",
        "- source: V2FUN manual download",
        f"- processed_utc: {now_utc()}",
        f"- original_filename: {source.name}",
        f"- format: {source.suffix.lower().lstrip('.')}",
        f"- file_size_bytes: {source.stat().st_size}",
        f"- sha256: {digest}",
        f"- preserved_original: {project_rel(original)}",
        f"- working_derivative: {project_rel(derivative)}",
        f"- dependency_package_files: {len(referenced_dependency_paths(source))}",
        f"- technical_classification: {classification}",
        "- optimization: none; safe pass-through derivative created",
        "",
        "## Inspection",
        "",
    ]
    labels = [
        ("mesh_count", "mesh count"),
        ("primitive_count", "primitive count"),
        ("vertex_count", "vertex count"),
        ("triangle_count", "triangle count"),
        ("polygon_count", "polygon count"),
        ("material_count", "material count"),
        ("texture_count", "texture count"),
        ("image_count", "image count"),
        ("animation_count", "animation count"),
        ("skeleton_count", "skeleton count"),
    ]
    for key, label in labels:
        lines.append(f"- {label}: {details.get(key)}")
    lines.append(f"- texture resolutions: {details.get('texture_resolutions', [])}")
    lines.append(f"- missing external textures: {details.get('missing_external_textures', [])}")
    lines.append(f"- inspection note: {details.get('inspection_note', '')}")
    lines.extend(["", "## Mobile risk flags", ""])
    lines.extend(f"- {flag}" for flag in (flags or ["none detected by the available checks"]))
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def process() -> int:
    ensure_structure()
    ledger = load_ledger()
    processed_hashes = {entry.get("sha256") for entry in ledger}
    candidates: list[Path] = []
    for path in INBOX_ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in SUPPORTED:
            continue
        relative_parts = path.relative_to(INBOX_ROOT).parts
        if relative_parts and relative_parts[0].lower() in EXCLUDED_DIRS:
            continue
        candidates.append(path)
    candidates.sort()
    new_count = 0
    for source in candidates:
        digest = sha256_file(source)
        if digest in processed_hashes:
            continue
        digest8 = digest[:8]
        original = copy_asset_package(source, ORIGINALS_DIR, digest8)
        derivative = copy_asset_package(source, WORKING_DIR, digest8)
        details = inspect_asset(source)
        technical_classification, flags = classify(details)
        report_path = REPORTS_DIR / f"{source.stem}__{digest8}.md"
        write_asset_report(report_path, source, original, derivative, digest, details, technical_classification, flags)
        ledger.append({
            "original_filename": source.name,
            "source": "V2FUN",
            "date_processed_utc": now_utc(),
            "sha256": digest,
            "original_path": project_rel(original),
            "derivative_path": project_rel(derivative),
            "report_path": project_rel(report_path),
            "original_statistics": details,
            "derivative_statistics": details,
            "optimization_performed": "none; pass-through derivative",
            "godot_asset_path": project_rel(derivative),
            "technical_classification": technical_classification,
            "notes": flags,
        })
        processed_hashes.add(digest)
        new_count += 1
        print(f"PROCESSED|{source.name}|class={technical_classification}|report={project_rel(report_path)}")
    LEDGER_PATH.write_text(json.dumps(ledger, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"V2FUN_INBOX_DONE|new_assets={new_count}|ledger={project_rel(LEDGER_PATH)}")
    if new_count == 0:
        print("V2FUN_INBOX_NOTE|no new GLB/GLTF/FBX/OBJ files found; no real asset validation performed")
    return 0


if __name__ == "__main__":
    sys.exit(process())
