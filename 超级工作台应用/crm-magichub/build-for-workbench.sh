#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_ROOT="$(cd "$ROOT/.." && pwd)"
PRIV="$APP_ROOT/data/private/crm"
OUT="$APP_ROOT/app/magichub"
cd "$ROOT"
mkdir -p /tmp/mh-public-bak
shopt -s nullglob
for x in product-images seeds products_imported.json thumbs; do
  if [ -e "public/$x" ] || [ -L "public/$x" ]; then
    rm -rf "/tmp/mh-public-bak/$x"
    mv "public/$x" "/tmp/mh-public-bak/$x" 2>/dev/null || true
  fi
done
for f in public/*.pdf; do
  bn=$(basename "$f")
  mv "$f" "/tmp/mh-public-bak/$bn"
done
npm run build
for x in /tmp/mh-public-bak/*; do
  [ -e "$x" ] || continue
  bn=$(basename "$x")
  rm -rf "public/$bn"
  mv "$x" "public/$bn"
done
rm -rf "$OUT"
mkdir -p "$OUT"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude '*.pdf' --exclude 'product-images' --exclude 'seeds' \
    --exclude 'products_imported.json' --exclude 'thumbs' --exclude 'external_reports' \
    dist/ "$OUT/"
else
  cp -a dist/. "$OUT/"
  rm -rf "$OUT/product-images" "$OUT/seeds" "$OUT/thumbs" "$OUT/external_reports" 2>/dev/null || true
  rm -f "$OUT/products_imported.json" 2>/dev/null || true
  find "$OUT" -maxdepth 1 -name '*.pdf' -delete 2>/dev/null || true
fi
if [ -d "$PRIV" ]; then
  ln -sfn "$PRIV/thumbs/products" "$OUT/product-images"
  ln -sfn "$PRIV/products/products_imported.json" "$OUT/products_imported.json"
  mkdir -p "$OUT/seeds"
  ln -sfn "$PRIV/leads/leads_seed.json" "$OUT/seeds/leads_seed.json"
  mkdir -p "$PRIV/derived/external_reports"
  ln -sfn "$PRIV/derived/external_reports" "$OUT/external_reports"
  for f in "$PRIV/pdfs/originals"/*.pdf; do
    [ -f "$f" ] || continue
    ln -sfn "$f" "$OUT/$(basename "$f")"
  done
fi
echo "Built MagicHub -> $OUT ($(du -sh "$OUT" | awk '{print $1}'))"
