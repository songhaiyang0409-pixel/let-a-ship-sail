# V2FUN AUTOMATION PROBE 01

Date: 2026-08-28

## Result

Automation level achieved: Level 1 — official documentation research only.

Zero V2FUN credits were spent. No subscription, billing, account security,
cookies, tokens, private endpoints, CAPTCHA, or undocumented API requests were
used.

## Official API / SDK / CLI / MCP findings

The official Help Center exposes browser user guides, FAQ, credits, and export
information, but no public API reference, SDK package, CLI, MCP server, API
authentication guide, or supported automation endpoint was found:

- https://v2fun.ai/help
- https://v2fun.ai/help/3DModel-user-guide
- https://v2fun.ai/help/credits-consume

An official blog article mentions a task-based API as a possible production
workflow, but it does not provide an actionable public API specification or
access procedure. This is not sufficient authorization or documentation for
automation.

## Browser probe

The official public pages were readable. The Codex in-app browser connection
was attempted twice, but its browser runtime exited during setup with a
Windows sandbox helper refresh error. The required browser documentation
troubleshooting path was followed.

Local inspection found:

- Microsoft Edge executable present.
- Node, npm, npx, Playwright, Selenium, ChromeDriver, and EdgeDriver were not
  available through the checked command paths.
- No dependency was installed.

Because the official Terms prohibit unauthorized scripts, plugins, and
automation tools, no fallback browser-driver automation was attempted.

Login state: unknown. No cookies or session stores were inspected.

## Exact stop point

Stopped before reaching an authenticated V2FUN workspace, before uploading any
image, before reading a live generation configuration or live credit cost, and
before any Generate/Create action.

Therefore this probe did not verify:

- image upload acceptance in the logged-in workspace;
- live model, texture, topology, or quality controls;
- live credit price for a configured operation;
- automated download of an existing account asset.

## Officially documented downstream formats

V2FUN's official pages describe static and animated 3D exports and document
GLB/glTF, FBX, and OBJ in its export guidance. The platform's motion guide
specifically lists GLB and FBX for uploaded models. Actual options still need
to be checked in the selected asset's export menu.

For this Godot project, GLB is the preferred first handoff. FBX is useful when
animation or Blender continuation is required. OBJ is suitable only for static
geometry and normally needs separate MTL/texture files.

## Future credit guardrail

Any future V2FUN production run must receive an explicit maximum budget
MAX_V2FUN_CREDITS = N from the user.

Before every credit-consuming action:

1. Read the cost displayed by the official UI.
2. Refuse to continue if the cost is missing or exceeds the remaining budget.
3. Record asset/task name, displayed cost, result status, cumulative authorized
   credits, cumulative used credits, and downloaded filename.
4. Never store passwords, cookies, tokens, or session data in the audit.

The official credit guide says generation actions display their required cost
before execution and may pre-deduct credits when a task is created:
https://v2fun.ai/help/credits-consume

## Proposed post-download Godot workflow

After the user manually generates and downloads an asset, Codex can safely
automate the local portion:

1. Preserve the original package in assets/third_party/incoming with a
   source note and checksum.
2. Inspect GLB/FBX/OBJ structure, mesh count, vertex/triangle counts, UVs,
   materials, textures, animations, pivot, axes, and dimensions.
3. Normalize scale non-destructively to the project convention
   1 Godot unit approximately 1 meter.
4. Create an optimized derivative only when needed, keeping the original.
5. Import the derivative into an isolated AssetGallery preview.
6. Check material mapping, shadow behavior, file size, and representative
   mobile performance.
7. Capture screenshots for human art-direction approval.
8. Move only approved derivatives into the approved asset area.

## Licensing caution

The official Help Center describes generated assets as private by default, while
the Terms distinguish paid-customer output ownership from free-customer
Creative Commons licensing. Commercial use should not be assumed until the
applicable plan and current Terms are checked for the actual account.

Official references:

- https://v2fun.ai/help/v2fun-asset-private
- https://v2fun.ai/agreement/terms
- https://v2fun.ai/help/v2fun-export-content
- https://v2fun.ai/blog/ai-3d-model-export-formats-guide

## Files and tools changed

- Added: V2FUN_AUTOMATION_PROBE_01_REPORT.md
- Game production files changed: none
- Local automation dependencies installed: none

Conclusion: Codex cannot currently demonstrate reliable direct V2FUN control in
this environment. The safe practical plan is user-managed generation/download,
followed by Codex-automated local asset validation and Godot integration.
