#!/usr/bin/env bash
# Derive the narrower packs from a directory of 5120x1440 (32:9) masters.
#
#   ./scripts/make-variants.sh [MASTERS_DIR] [OUT_DIR]
#
# Defaults: MASTERS_DIR=~/.config/omarchy/themes, OUT_DIR=./backgrounds
#
# Each target is cut from the master at its own aspect ratio and scaled, so the
# result is never stretched. Note that the two TALLER formats (5120x2160 and
# 3840x1600) are better produced from the ORIGINAL artwork than from a 32:9
# master, which has already discarded the vertical detail they need; the packs
# published in releases are built that way. This script is the convenient
# approximation for anyone regenerating locally.
set -euo pipefail
SRC=${1:-$HOME/.config/omarchy/themes}
OUT=${2:-./backgrounds}
command -v magick >/dev/null 2>&1 || { echo "needs imagemagick" >&2; exit 1; }

# name:width:height
TARGETS="32x9:5120:1440 5k2k:5120:2160 21x9-1600:3840:1600 21x9:3440:1440 21x9-1080p:2560:1080"

n=0
for f in "$SRC"/*/backgrounds/*; do
  [ -f "$f" ] || continue
  slug=$(basename "$(dirname "$(dirname "$f")")"); b=$(basename "$f")
  [ "$(magick identify -format '%wx%h' "$f[0]" 2>/dev/null)" = "5120x1440" ] || continue
  for t in $TARGETS; do
    name=${t%%:*}; rest=${t#*:}; tw=${rest%%:*}; th=${rest#*:}
    mkdir -p "$OUT/$name/$slug"
    if [ "$name" = 32x9 ]; then
      cp -f "$f" "$OUT/$name/$slug/$b"
    else
      cw=$(( 1440 * tw / th )); cw=$(( cw - cw % 2 ))
      magick "$f" -gravity center -crop "${cw}x1440+0+0" +repage \
        -filter Lanczos -resize "${tw}x${th}!" -quality 95 "$OUT/$name/$slug/$b"
    fi
  done
  n=$((n+1)); echo "ok  $slug/$b"
done
echo "derived $(echo $TARGETS | wc -w) packs from $n masters -> $OUT"
