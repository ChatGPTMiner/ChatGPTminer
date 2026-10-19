#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/h-config.sh"
binary="$script_dir/miner/chatgptminer"
if [[ ! -x "$binary" ]]; then
    echo "[ChatGPTminer] executable is missing: $binary" >&2
    exit 127
fi
exec "$binary" mine

