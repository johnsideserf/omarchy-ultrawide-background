#!/usr/bin/env bash
# One-shot installer: fetch the pack matching this monitor, install it, and add
# the Omarchy menu rows.   ./install.sh [RATIO] [--replace] [--no-menu]
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
CLI="$HERE/bin/omarchy-ultrawide"

# magick is only needed by scripts/make-variants.sh, not by an install
for dep in python3 curl tar; do
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
case "$HERE" in
  "$HOME/.config/omarchy/plugins/"*)
    echo "Done. Mixed monitor setup? Swap in the per-screen renderer with:"
    echo "  omarchy-ultrawide enable"
    ;;
  *)
    echo "Done. For mixed monitor setups, also install the plugin:"
    echo "  omarchy plugin add https://github.com/johnsideserf/omarchy-ultrawide-background"
    echo "  omarchy-ultrawide enable"
    ;;
esac
