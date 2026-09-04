#!/usr/bin/env bash
# Download the image packs from the GitHub release into ./backgrounds/.
set -euo pipefail
HERE=$(cd "$(dirname "$0")/.." && pwd)
REPO=${OMARCHY_ULTRAWIDE_REPO:-johnsideserf/omarchy-ultrawide-backgrounds}
TAG=${1:-latest}
url() { if [ "$TAG" = latest ]; then echo "https://github.com/$REPO/releases/latest/download/$1"; else echo "https://github.com/$REPO/releases/download/$TAG/$1"; fi; }
mkdir -p "$HERE/backgrounds"; cd "$HERE/backgrounds"
for pack in 32x9 21x9 21x9-1080p; do
  [ -d "$pack" ] && { echo "have $pack"; continue; }
  echo "fetching $pack ..."; curl -fsSL "$(url "$pack.tar.zst")" -o "$pack.tar.zst"
  tar --zstd -xf "$pack.tar.zst" && rm -f "$pack.tar.zst" && echo "ok $pack"
done
