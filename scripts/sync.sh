#!/usr/bin/env bash
# 云端 ↔ 本地同步：先拉取，再提交并推送本地改动
set -euo pipefail
cd "$(dirname "$0")/.."
cp data/workspace.json app/data/workspace.json 2>/dev/null || true
git pull --rebase --autostash
git add -A
if ! git diff --cached --quiet; then
  git commit -m "sync: $(date '+%Y-%m-%d %H:%M')"
fi
git push
echo "同步完成"
