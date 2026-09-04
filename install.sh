#!/usr/bin/env bash
# One-shot installer: fetch the pack matching this monitor, install it, and add
# the Omarchy menu rows.   ./install.sh [RATIO] [--replace] [--no-menu]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
CLI="$HERE/bin/omarchy-ultrawide"

for dep in magick python3 curl; do
  command -v "$dep" >/dev/null 2>&1 || { echo "install.sh: missing dependency: $dep" >&2; exit 1; }
done

args=(); menu=1
for a in "$@"; do [ "$a" = --no-menu ] && menu=0 || args+=("$a"); done

# packs live outside the repo so a git clone stays small
DATA=${OMARCHY_ULTRAWIDE_DATA:-~/.local/share/omarchy-ultrawide}
if [ ! -d "$DATA/backgrounds" ]; then
  echo "==> fetching image packs"
  "$CLI" fetch
fi

echo "==> installing"
"$CLI" install "${args[@]:-}"

if [ "$menu" = 1 ]; then
  echo "==> adding Omarchy menu rows (Style -> Ultrawide backgrounds)"
  "$CLI" menu || true
fi

mkdir -p ~/.local/bin && ln -sf "$CLI" ~/.local/bin/omarchy-ultrawide
echo "==> linked ~/.local/bin/omarchy-ultrawide"
echo
"$CLI" status || true
echo
echo "Done. For mixed monitor setups also run:"
echo "  omarchy plugin add https://github.com/johnsideserf/omarchy-ultrawide-background"
echo "  omarchy-ultrawide enable"
