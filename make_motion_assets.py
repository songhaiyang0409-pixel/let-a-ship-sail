from pathlib import Path
import math

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parent
UPPER = ROOT / "upper_scene_9x16.png"
LOWER = ROOT / "lower_scene_9x16.png"


def normalize(src: Path, dst: Path, size=(1080, 1920)) -> Image.Image:
    image = Image.open(src).convert("RGB").resize(size, Image.Resampling.LANCZOS)
    image.save(dst, quality=95)
    return image


upper = normalize(UPPER, ROOT / "upper_scene_9x16_1080x1920.jpg")
normalize(LOWER, ROOT / "lower_scene_9x16_1080x1920.jpg")


# Build a compact 9:16 looping GIF. The base image receives a gentle camera/boat bob,
# a tiny roll, and phase-shifted horizontal water displacement that makes the wake and
# wave texture feel alive without changing the illustration's content.
W, H = 1080, 1920
base = upper.resize((W, H), Image.Resampling.LANCZOS)
base_array = np.asarray(base).astype(np.float32)
frames = []
frame_count = 12
water_start = int(H * 0.47)

for index in range(frame_count):
    phase = 2.0 * math.pi * index / frame_count

    # Subtle forward glide and rocking motion.
    zoom = 1.0 + 0.008 * math.sin(phase)
    scaled = base.resize((round(W * zoom), round(H * zoom)), Image.Resampling.BICUBIC)
    left = (scaled.width - W) // 2 + round(1.5 * math.sin(phase))
    top = (scaled.height - H) // 2 + round(2.0 * math.cos(phase))
    moving = Image.new("RGB", (W, H))
    moving.paste(scaled, (-left, -top))
    moving = moving.rotate(0.45 * math.sin(phase), resample=Image.Resampling.BICUBIC)
    moving = moving.resize((W, H), Image.Resampling.BICUBIC)

    arr = np.asarray(moving).astype(np.float32)
    y = np.arange(H)[:, None]
    x = np.arange(W)[None, :]
    water_amount = np.clip((y - water_start) / 70.0, 0.0, 1.0)
    horizontal = water_amount * (5.0 * np.sin(phase * 1.25 + y * 0.055))
    vertical = water_amount * (2.4 * np.sin(phase * 1.7 + y * 0.035))
    source_y = np.clip(np.rint(y + vertical), 0, H - 1).astype(np.int32)
    source_x = np.clip(np.rint(x + horizontal), 0, W - 1).astype(np.int32)
    warped = arr[source_y, source_x]
    arr = arr * (1.0 - water_amount[:, :, None]) + warped * water_amount[:, :, None]

    # Slightly vary water brightness with the wave phase for animated glints.
    glint = (0.985 + 0.02 * np.sin(phase * 1.4 + y * 0.045))[:, :, None]
    arr[water_start:] = np.clip(arr[water_start:] * glint[water_start:], 0, 255)
    frames.append(Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB"))


gif_path = ROOT / "upper_scene_motion_9x16.gif"
frames[0].save(
    gif_path,
    save_all=True,
    append_images=frames[1:],
    duration=90,
    loop=0,
    optimize=True,
    disposal=2,
)

print(f"created {gif_path}")
print(f"still size: {upper.size}; gif size: {frames[0].size}; frames: {len(frames)}")
