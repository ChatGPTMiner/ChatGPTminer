#!/usr/bin/env bash
set -euo pipefail
# The mining engine does not emit live statistics until the licensed Pearl
# implementation is integrated. Return a valid zero-value HiveOS payload.
printf '0\n'
printf '{"hs":[0],"hs_units":"hs","total_hs":0,"temp":[0],"fan":[0],"uptime":0,"ver":"0.1.0","ar":[0,0],"algo":"pearl"}\n'

