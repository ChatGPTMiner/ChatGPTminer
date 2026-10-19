#!/usr/bin/env bash

CHATGPTMINER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINER_LOG_BASENAME="${CUSTOM_LOG_BASENAME:-/var/log/miner/custom/chatgptminer}"

miner_ver() {
  printf '%s\n' "${CUSTOM_VERSION:-0.3.7}"
}

miner_api_port() {
  printf '%s\n' "${CUSTOM_API_PORT:-9200}"
}

miner_config_gen() (
  hive_config_dir="${HIVE_CONFIG_DIR:-/hive-config}"
  set -a
  if [[ -f "$hive_config_dir/rig.conf" ]]; then
    # shellcheck disable=SC1090
    . "$hive_config_dir/rig.conf"
  fi
  if [[ -f "$hive_config_dir/wallet.conf" ]]; then
    # shellcheck disable=SC1090
    . "$hive_config_dir/wallet.conf"
  fi
  set +a
  RGMINER_CONFIG="$CHATGPTMINER_DIR/config.env" \
    "$CHATGPTMINER_DIR/h-config-rgminer.sh"
)

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  miner_config_gen
fi
