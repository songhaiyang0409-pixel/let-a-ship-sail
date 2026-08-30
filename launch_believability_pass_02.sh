#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
exec godot --path . scenes/staging/believability_pass_02/AutonomousWorldOceanBelievabilityPass02.tscn "$@"
