#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
version="${1:-0.2.0}"
binary="$project_dir/out/bin/chatgptminer"
archive="$project_dir/dist/chatgptminer-${version}-hiveos-linux-x64.tar.gz"

if [[ ! -x "$binary" ]]; then
    echo "Binary is missing; run scripts/build.sh first" >&2
    exit 1
fi

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/miner"
install -m 0755 "$binary" "$stage/miner/chatgptminer"
install -m 0755 "$project_dir/hiveos/h-run.sh" "$stage/h-run.sh"
install -m 0755 "$project_dir/hiveos/h-config.sh" "$stage/h-config.sh"
install -m 0755 "$project_dir/hiveos/h-stats.sh" "$stage/h-stats.sh"
install -m 0644 "$project_dir/hiveos/h-manifest.conf" "$stage/h-manifest.conf"
install -m 0644 "$project_dir/RUN.md" "$stage/RUN.md"

mkdir -p "$project_dir/dist"
tar -C "$stage" -czf "$archive" .
sha256sum "$archive" > "$archive.sha256"
echo "$archive"
