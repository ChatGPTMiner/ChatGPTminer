#!/usr/bin/env bash
set -euo pipefail
. "$RGMINER_CONFIG"
printf '%s|%s|%s\n' "$ADDRESS" "$WORKER_NAME" "$POOLS" >>"${MOCK_PHASE_LOG:?}"
sleep 10
