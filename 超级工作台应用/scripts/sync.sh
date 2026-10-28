#!/usr/bin/env bash
# 云端 ↔ 本地同步：在「超级工作台应用」内维护数据，在仓库根目录提交推送
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$APP_DIR/.." && pwd)"
cd "$APP_DIR"
mkdir -p app/data
cp -f data/workspace.json app/data/workspace.json
cd "$REPO_ROOT"
git pull --rebase --autostash
git add -A
if ! git diff --cached --quiet; then
  git commit -m "sync: $(date '+%Y-%m-%d %H:%M')"
fi
git push
echo "同步完成（仓库根：$REPO_ROOT）"
