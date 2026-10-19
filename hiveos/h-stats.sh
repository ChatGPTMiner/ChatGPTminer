#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$script_dir/h-manifest.conf"

api_port="${PRL_API_PORT:-$MINER_API_PORT}"
raw="$(curl --connect-timeout 2 --max-time 5 --silent --noproxy '*' "http://127.0.0.1:$api_port/" 2>/dev/null || true)"

if [[ -z "$raw" ]] || ! jq -e '.algorithms[0]' >/dev/null 2>&1 <<< "$raw"; then
    printf '0\n'
    printf '{"hs":[0],"hs_units":"khs","total_hs":0,"temp":[0],"fan":[0],"uptime":0,"ver":"%s","ar":[0,0],"algo":"pearlhash"}\n' "$CUSTOM_VERSION"
    exit 0
fi

stats="$(jq -c --arg ver "$CUSTOM_VERSION" '
    .algorithms[0] as $a |
    [(.gpu_devices // [])[] | (.id | tostring)] as $ids |
    {
      hs: [$ids[] as $id | (($a.hashrate.gpu["gpu" + $id] // 0) / 1000)],
      hs_units: "khs",
      total_hs: (($a.hashrate.now // $a.hashrate["1min"] // 0) / 1000),
      temp: [range(0; ($ids | length)) | 0],
      fan: [range(0; ($ids | length)) | 0],
      uptime: (.mining_time // 0),
      ver: (.miner_version // $ver),
      ar: [($a.shares.accepted // 0), ($a.shares.rejected // 0)],
      algo: ($a.name // "pearlhash"),
      bus_numbers: [(.gpu_devices // [])[] | (.bus_id // 0)]
    }
' <<< "$raw")"

total_khs="$(jq -r '.total_hs // 0' <<< "$stats")"
printf '%s\n%s\n' "$total_khs" "$stats"

