$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$patchPath = Join-Path $repoRoot 'codex_relay/CODEX_RELAY_LATEST.patch'
$scenePath = 'scenes/staging/reconstruction_04/NorthAtlanticWorldReconstruction04.tscn'
$journeyTest = 'tests/reconstruction_04_journey_check.gd'

function Invoke-GitApplyCheck([string[]]$ExtraArgs) {
    & git apply @ExtraArgs --check $patchPath 2>$null
    return ($LASTEXITCODE -eq 0)
}

if (-not (Test-Path 'project.godot')) { throw 'project.godot not found. Run this from the repository copy.' }
if (-not (Test-Path $patchPath)) { throw 'Codex relay patch not found.' }
if (-not (Test-Path $scenePath)) { throw "Authoritative scene not found: $scenePath" }

Write-Host '== Let a Ship Sail: authoritative A-to-B launcher =='
Write-Host ('Repository: ' + $repoRoot)

# Never overwrite conflicting local work. Apply only when Git proves the cumulative
# patch is cleanly applicable. If the reverse check succeeds, the patch is already
# materialized in this working tree and we leave it alone.
if (Invoke-GitApplyCheck @()) {
    Write-Host 'Applying verified cumulative Codex relay patch...'
    & git apply --check $patchPath
    if ($LASTEXITCODE -ne 0) { throw 'git apply --check failed.' }
    & git apply $patchPath
    if ($LASTEXITCODE -ne 0) { throw 'git apply failed.' }
    Write-Host 'Relay patch applied.'
}
elseif (Invoke-GitApplyCheck @('--reverse')) {
    Write-Host 'Relay patch is already applied in this working tree.'
}
else {
    throw 'Relay patch cannot be applied cleanly and is not already applied. No files were changed. Preserve local work and let the project manager inspect the conflict.'
}

& godot --version
if ($LASTEXITCODE -ne 0) { throw 'Godot is not available on PATH.' }

Write-Host 'Running authoritative journey regression check...'
& godot --headless --path . -s $journeyTest
if ($LASTEXITCODE -ne 0) { throw 'Authoritative journey regression check failed. Game launch aborted.' }

Write-Host 'Launching authoritative A-to-B journey...'
& godot --path . $scenePath
