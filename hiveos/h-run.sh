#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/h-manifest.conf"
. "$script_dir/h-config.sh"
binary="$script_dir/miner/chatgptminer"
if [[ ! -x "$binary" ]]; then
    echo "[ChatGPTminer] executable is missing: $binary" >&2
    exit 127
fi

if pgrep -f "$binary mine" >/dev/null 2>&1; then
    echo "[ChatGPTminer] miner is already running" >&2
    exit 1
fi

mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")"
echo "[$(date -u +%FT%TZ)] algorithm=pearlhash pool=$PRL_POOL_HOST:$PRL_POOL_PORT worker=$PRL_WORKER api=$PRL_API_PORT" \
    >> "$CUSTOM_LOG_BASENAME.log"

exec "$binary" mine >> "$CUSTOM_LOG_BASENAME.log" 2>&1

