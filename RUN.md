# Run

List NVIDIA devices and their architecture:

```bash
./out/bin/chatgptminer list-gpus
```

Run the available self-checks:

```bash
./out/bin/chatgptminer selftest
```

Configuration uses `PRL_*` variables and accepts the corresponding Akoya names
for compatibility:

| Setting | Compatible name | Meaning |
|---|---|---|
| `PRL_WALLET` | `AKOYA_POOL_WALLET` | User Pearl wallet; required |
| `PRL_WORKER` | `AKOYA_POOL_WORKER` | Worker name |
| `PRL_POOL_HOST` | `AKOYA_POOL_HOST` | Pool host; default `prl.kryptex.network` |
| `PRL_POOL_PORT` | `AKOYA_POOL_PORT` | Pool port, default 7048 |
| `PRL_POOL_TLS` | `AKOYA_POOL_TLS` | `1/0` or `true/false` |
| `PRL_GPU_INDICES` | `AKOYA_GPU_INDICES` | `all` or comma-separated indices |
| `PRL_LOG_LEVEL` | `AKOYA_LOG_LEVEL` | Log level |

Example shape, after a Kryptex endpoint and the licensed engine are integrated:

```bash
PRL_WALLET=prl1yourwallet \
PRL_WORKER=rig01 \
PRL_POOL_HOST=prl.kryptex.network \
PRL_POOL_PORT=7048 \
PRL_POOL_TLS=0 \
PRL_GPU_INDICES=all \
./out/bin/chatgptminer mine
```

Test the Stratum subscription, authorization, reconnect, and incoming message
stream without starting the engine:

```bash
PRL_WALLET=prl1yourwallet ./out/bin/chatgptminer pool-probe
```

Stop it with Ctrl-C, or pass a duration in seconds after `pool-probe`.

The current `mine` command validates configuration and then exits with code 3
because the Pearl job decoder and CUDA engine are incomplete. No user
wallet is embedded in source. The developer wallet and 2% schedule are printed
by `selftest` and documented in `ARCHITECTURE.md`.

For HiveOS, place the release directory so that `hiveos/` and `out/` remain
siblings. Set the wallet/worker template and the confirmed Kryptex endpoint in
the flight sheet. `h-run.sh` maps these values and launches the native binary;
`h-stats.sh` currently emits zero values because mining statistics do not yet
exist.

