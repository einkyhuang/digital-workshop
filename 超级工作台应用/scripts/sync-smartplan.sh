#!/bin/bash
# Wrapper: import SmartPlan website projects into workspace.json; optional --push
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
exec node "超级工作台应用/scripts/sync-smartplan.mjs" "$@"
