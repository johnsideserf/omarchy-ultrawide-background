#!/usr/bin/env bash
# Derive narrower ultrawide variants from the 5120x1440 (32:9) masters by
# centre-cropping (full height kept, nothing regenerated).
#   32:9  5120x1440  master
#   21:9  3440x1440  centre crop
#   21:9  2560x1080  centre crop to 2.370:1 then scale
set -euo pipefail
SRC=${1:-~/.config/omarchy/themes}      # where the 5120x1440 masters live
OUT=${2:-./backgrounds}
for f in "$SRC"/*/backgrounds/*; do
  [ -f "$f" ] || continue
  slug=$(basename "$(dirname "$(dirname "$f")")"); b=$(basename "$f")
  dims=$(magick identify -format '%wx%h' "$f[0]")
  [ "$dims" = "5120x1440" ] || { echo "skip $slug/$b ($dims)"; continue; }
  mkdir -p "$OUT/32x9/$slug" "$OUT/21x9/$slug" "$OUT/21x9-1080p/$slug"
  cp "$f" "$OUT/32x9/$slug/$b"
  magick "$f" -gravity center -crop 3440x1440+0+0 +repage -quality 95 "$OUT/21x9/$slug/$b"
  magick "$f" -gravity center -crop 3413x1440+0+0 +repage -resize 2560x1080! -quality 95 "$OUT/21x9-1080p/$slug/$b"
  echo "ok   $slug/$b"
done
