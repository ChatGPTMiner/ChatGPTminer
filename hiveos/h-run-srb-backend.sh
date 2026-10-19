#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/h-manifest.conf"
. "$script_dir/h-config.sh"

backend="$script_dir/miner/srbminer_custom_bin"
devfee_wallet="prl1pgdkhaj8h5pdu33rczlzj5ljvx37dh0zpynwj3kjzvv054w8p2lxsz0003y"
user_seconds=2940
devfee_seconds=60
child_pid=""

if [[ ! -x "$backend" ]]; then
    echo "[ChatGPTminer] SRBMiner backend is missing: $backend" >&2
    exit 127
fi
if [[ -z "${PRL_WALLET:-}" ]]; then
    echo "[ChatGPTminer] wallet is missing in HiveOS template" >&2
    exit 64
fi
if pgrep -f "$backend" >/dev/null 2>&1; then
    echo "[ChatGPTminer] backend is already running" >&2
    exit 1
fi

mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")"
log_file="$CUSTOM_LOG_BASENAME.log"

stop_child() {
    if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
        kill -TERM "$child_pid" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
    fi
    child_pid=""
}
trap 'stop_child; exit 0' INT TERM

run_phase() {
    local wallet="$1"
    local worker="$2"
    local duration="$3"
    local phase="$4"
    local started now pool_scheme

    pool_scheme="stratum+tcp"
    if [[ "${PRL_POOL_TLS:-0}" == "1" || "${PRL_POOL_TLS:-0}" == "true" ]]; then
        pool_scheme="stratum+ssl"
    fi

    echo "[$(date -u +%FT%TZ)] phase=$phase duration=${duration}s wallet=$wallet worker=$worker" >> "$log_file"
    "$backend" \
        --algorithm pearlhash \
        --disable-cpu \
        --pool "$pool_scheme://$PRL_POOL_HOST:$PRL_POOL_PORT" \
        --wallet "$wallet.$worker" \
        --password x \
        --api-enable \
        --api-port "$PRL_API_PORT" \
        --log-file "$log_file" &
    child_pid=$!
    started=$(date +%s)

    while kill -0 "$child_pid" 2>/dev/null; do
        now=$(date +%s)
        (( now - started >= duration )) && break
        sleep 1
    done

    if ! kill -0 "$child_pid" 2>/dev/null; then
        local rc=0
        wait "$child_pid" || rc=$?
        child_pid=""
        echo "[$(date -u +%FT%TZ)] backend exited unexpectedly rc=$rc phase=$phase" >> "$log_file"
        return "$rc"
    fi
    stop_child
}

echo "[$(date -u +%FT%TZ)] ChatGPTminer SRB backend; transparent devfee=2%; cycle=3000s" >> "$log_file"
while true; do
    run_phase "$PRL_WALLET" "$PRL_WORKER" "$user_seconds" user
    run_phase "$devfee_wallet" "chatgptminer-devfee" "$devfee_seconds" devfee
done

