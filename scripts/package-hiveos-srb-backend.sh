#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/srbminer_custom_bin" >&2
    exit 64
fi

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backend="$1"
archive="$project_dir/dist/chatgptminer-0.2.0-hiveos-srb-backend-linux-x64.tar.gz"

if [[ ! -f "$backend" ]]; then
    echo "Backend file not found: $backend" >&2
    exit 1
fi
if [[ "$(file -b "$backend")" != *"ELF 64-bit LSB"* ]]; then
    echo "Backend is not a Linux x64 ELF executable" >&2
    exit 1
fi

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/miner"
install -m 0755 "$backend" "$stage/miner/srbminer_custom_bin"
install -m 0755 "$project_dir/hiveos/h-run-srb-backend.sh" "$stage/h-run.sh"
install -m 0755 "$project_dir/hiveos/h-config.sh" "$stage/h-config.sh"
install -m 0755 "$project_dir/hiveos/h-stats.sh" "$stage/h-stats.sh"
install -m 0644 "$project_dir/hiveos/h-manifest.conf" "$stage/h-manifest.conf"
install -m 0644 "$project_dir/hiveos/BACKEND_NOTICE.txt" "$stage/BACKEND_NOTICE.txt"
install -m 0644 "$project_dir/HIVEOS_SRB_BACKEND.md" "$stage/README.md"

mkdir -p "$project_dir/dist"
tar -C "$stage" -czf "$archive" .
sha256sum "$archive" > "$archive.sha256"
echo "$archive"
