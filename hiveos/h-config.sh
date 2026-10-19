#!/usr/bin/env bash
set -u
template="${CUSTOM_TEMPLATE:-}"
export PRL_WALLET="${template%%.*}"
worker="${template#*.}"
[[ "$worker" == "$template" ]] && worker="${WORKER_NAME:-default}"
export PRL_WORKER="$worker"
pool="${CUSTOM_URL%%,*}"
pool="${pool#*://}"
export PRL_POOL_HOST="${pool%%:*}"
export PRL_POOL_PORT="${pool##*:}"
[[ "$PRL_POOL_PORT" == "$pool" ]] && export PRL_POOL_PORT=443
export PRL_POOL_TLS="${PRL_POOL_TLS:-1}"
export PRL_GPU_INDICES="${PRL_GPU_INDICES:-all}"
export PRL_LOG_LEVEL="${PRL_LOG_LEVEL:-info}"
export PRL_API_PORT="${PRL_API_PORT:-21373}"

# Accept only documented PRL_* overrides from HiveOS Custom user config.
# Lines may be separated by newlines or semicolons.
if [[ -n "${CUSTOM_USER_CONFIG:-}" ]]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="${line#${line%%[![:space:]]*}}"
        line="${line%${line##*[![:space:]]}}"
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^PRL_(GPU_INDICES|LOG_LEVEL|API_PORT|POOL_TLS)=.*$ ]] || continue
        export "$line"
    done < <(printf '%s\n' "$CUSTOM_USER_CONFIG" | tr ';' '\n')
fi

