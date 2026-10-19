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

