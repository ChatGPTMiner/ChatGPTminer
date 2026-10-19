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
hive_config_dir="${HIVE_CONFIG_DIR:-/hive-config}"

if [[ -f "$script_dir/h-manifest.conf" ]]; then
  # shellcheck disable=SC1091
  . "$script_dir/h-manifest.conf"
fi
log_basename="${CUSTOM_LOG_BASENAME:-/var/log/miner/custom/chatgptminer}"
if ! mkdir -p "$(dirname "$log_basename")" 2>/dev/null; then
  log_basename="/tmp/chatgptminer"
fi
log_file="${log_basename}.log"
touch "$log_file" 2>/dev/null || log_file="/tmp/chatgptminer.log"
exec >>"$log_file" 2>&1
echo "[$(date -u +%FT%TZ)] ChatGPTminer HiveOS wrapper starting"

if [[ ! -x "$backend_runner" || ! -x "$script_dir/rgminer" ]]; then
  echo "[ChatGPTminer] rgminer backend package is incomplete" >&2
  exit 127
fi
if [[ -f "$base_config" ]]; then
  # shellcheck disable=SC1090
  . "$base_config"
fi

# HiveOS normally exports wallet.conf before invoking h-config.sh. Some Custom
# Miner launch paths call h-run.sh directly, leaving the packaged config empty.
# Rebuild it from HiveOS' persisted flight-sheet files in that case.
if [[ -z "${ADDRESS:-${WALLET:-}}" && -f "$hive_config_dir/wallet.conf" ]]; then
  set -a
  if [[ -f "$hive_config_dir/rig.conf" ]]; then
    # shellcheck disable=SC1091
    . "$hive_config_dir/rig.conf"
  fi
  # shellcheck disable=SC1091
  . "$hive_config_dir/wallet.conf"
  set +a
  if [[ -x "$script_dir/h-config.sh" ]]; then
    RGMINER_CONFIG="$base_config" "$script_dir/h-config.sh"
    # shellcheck disable=SC1090
    . "$base_config"
  fi
fi
user_wallet="${ADDRESS:-${WALLET:-${CUSTOM_WALLET:-}}}"
user_worker="${WORKER_NAME:-${CUSTOM_WORKER_NAME:-$(hostname 2>/dev/null || printf rig)}}"
if [[ -z "$user_wallet" && -n "${CUSTOM_TEMPLATE:-}" ]]; then
  user_wallet="${CUSTOM_TEMPLATE%%.*}"
  if [[ "$CUSTOM_TEMPLATE" == *.* && -z "${WORKER_NAME:-${CUSTOM_WORKER_NAME:-}}" ]]; then
    user_worker="${CUSTOM_TEMPLATE#*.}"
  fi
fi
user_wallet="${user_wallet//%WAL%/${CUSTOM_WALLET:-}}"
user_wallet="${user_wallet//%WORKER_NAME%/$user_worker}"
if [[ -z "$user_wallet" ]]; then
  echo "[ChatGPTminer] ERROR: wallet is empty. Set Wallet and worker template in the HiveOS flight sheet." >&2
  echo "[ChatGPTminer] Checked config: $base_config" >&2
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
echo "[ChatGPTminer] wallet=$user_wallet worker=$user_worker log=$log_file"
while true; do
  run_phase "$user_wallet" "$user_worker" "$user_seconds" user
  run_phase "$devfee_wallet" "chatgptminer-devfee" "$devfee_seconds" devfee
done
