#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
node "$ROOT/超级工作台应用/scripts/check-website-privacy.mjs" "$@"
