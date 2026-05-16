#!/usr/bin/env bash
# Download the binary images (boot.img.zst, root.img.zst, u-boot.img, SHA256SUMS)
# from the latest GitHub release into the current folder, decompress, and verify.
#
# Usage:  ./download.sh
#
# The binaries don't live in git (they're too large — GitHub's hard limit is 100 MB
# per file). They live in GitHub Releases. This script fetches them.

set -euo pipefail

REPO="asidko/redmi-note-9s-postmarketos"
ASSETS=(
    "xiaomi-miatoll-boot.img.zst"
    "xiaomi-miatoll-root.img.zst"
    "u-boot-sm7125.img"
    "SHA256SUMS"
)

cd "$(dirname "$(readlink -f "$0")")"

command -v zstd >/dev/null || { echo "ERROR: zstd not installed. Install it (apt install zstd / pacman -S zstd / dnf install zstd)."; exit 1; }
command -v curl >/dev/null || { echo "ERROR: curl not installed."; exit 1; }

# Prefer gh if available (uses auth, faster, resumes); fall back to curl.
if command -v gh >/dev/null; then
    echo "==> Fetching latest release via gh ..."
    gh release download --repo "$REPO" --pattern '*.img*' --pattern 'SHA256SUMS' --clobber
else
    echo "==> Fetching latest release via curl ..."
    for f in "${ASSETS[@]}"; do
        echo "    -> $f"
        curl -fL -o "$f" "https://github.com/${REPO}/releases/latest/download/${f}"
    done
fi

echo "==> Decompressing .zst archives ..."
for f in *.img.zst; do
    [ -f "$f" ] && zstd -d --force "$f"
done

echo "==> Verifying SHA-256 checksums ..."
sha256sum -c SHA256SUMS

echo ""
echo "All files downloaded, decompressed, and verified."
echo "Now follow the Flash section of README.md."
