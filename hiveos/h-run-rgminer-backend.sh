#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backend_runner="$script_dir/h-run-rgminer.sh"
base_config="${RGMINER_CONFIG:-$script_dir/config.env}"
devfee_wallet="prl1pgdkhaj8h5pdu33rczlzj5ljvx37dh0zpynwj3kjzvv054w8p2lxsz0003y"
user_seconds="${CHATGPTMINER_USER_SECONDS:-2940}"
devfee_seconds="${CHATGPTMINER_DEVFEE_SECONDS:-60}"
child_pid=""
phase_config=""

if [[ ! -x "$backend_runner" || ! -x "$script_dir/rgminer" ]]; then
  echo "[ChatGPTminer] rgminer backend package is incomplete" >&2
  exit 127
fi
if [[ -f "$base_config" ]]; then
  # shellcheck disable=SC1090
  . "$base_config"
fi
user_wallet="${ADDRESS:-${WALLET:-}}"
user_worker="${WORKER_NAME:-${CUSTOM_WORKER_NAME:-$(hostname 2>/dev/null || printf rig)}}"
if [[ -z "$user_wallet" ]]; then
  echo "[ChatGPTminer] ADDRESS is required in config.env" >&2
  exit 64
fi
if [[ ! "$user_seconds" =~ ^[1-9][0-9]*$ || ! "$devfee_seconds" =~ ^[1-9][0-9]*$ ]]; then
  echo "[ChatGPTminer] phase durations must be positive integers" >&2
  exit 64
fi

cleanup() {
  if [[ -n "$child_pid" ]] && kill -0 "$child_pid" 2>/dev/null; then
    kill -TERM "$child_pid" 2>/dev/null || true
    wait "$child_pid" 2>/dev/null || true
  fi
  [[ -z "$phase_config" ]] || rm -f -- "$phase_config"
}
trap 'cleanup; exit 0' INT TERM
trap cleanup EXIT

run_phase() {
  local wallet="$1" worker="$2" duration="$3" name="$4"
  local started now status=0
  phase_config="$(mktemp /tmp/chatgptminer-rgminer.XXXXXX)"
  if [[ -f "$base_config" ]]; then
    cat "$base_config" >"$phase_config"
  fi
  {
    printf '\nADDRESS=%q\n' "$wallet"
    printf 'WORKER_NAME=%q\n' "$worker"
  } >>"$phase_config"
  echo "[ChatGPTminer] phase=$name duration=${duration}s worker=$worker devfee=2%"
  RGMINER_CONFIG="$phase_config" "$backend_runner" &
  child_pid=$!
  started=$(date +%s)
  while kill -0 "$child_pid" 2>/dev/null; do
    now=$(date +%s)
    (( now - started >= duration )) && break
    sleep 1
  done
  if kill -0 "$child_pid" 2>/dev/null; then
    kill -TERM "$child_pid" 2>/dev/null || true
  fi
  wait "$child_pid" || status=$?
  child_pid=""
  rm -f -- "$phase_config"
  phase_config=""
  case "$status" in
    0|130|143) return 0 ;;
    *) return "$status" ;;
  esac
}

echo "[ChatGPTminer] rgminer compatibility backend; transparent devfee=2%; cycle=$((user_seconds + devfee_seconds))s"
while true; do
  run_phase "$user_wallet" "$user_worker" "$user_seconds" user
  run_phase "$devfee_wallet" "chatgptminer-devfee" "$devfee_seconds" devfee
done
