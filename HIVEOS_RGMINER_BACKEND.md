# HiveOS rgminer compatibility package

This transition build uses the operator-supplied rgminer 1.1.3b binary while
the independent Pearl CUDA engine remains under development. It preserves the
working rgminer HiveOS contract: algorithm `pearl`, API port `9200`, metrics at
`/metrics`, and `--stratum` pool endpoints.

Build the archive without executing the supplied binary:

```bash
./scripts/package-hiveos-rgminer-backend.sh /path/to/rgminer-1.1.3b-hiveos.tar.gz
```

In the HiveOS flight sheet, put the PRL address in **Wallet and worker
template**, the worker in the usual HiveOS worker field, and the endpoint in
**Pool URL**. `h-config.sh` converts those HiveOS fields into `ADDRESS`,
`WORKER_NAME`, and `POOLS` automatically. A typical plaintext pool value is
`stratum+tcp://host:port`; use the pool's documented TLS URL when applicable.
The wrapper alternates 2940 seconds on the user's wallet and 60 seconds on the
documented developer wallet. Each phase change reconnects the backend.

The uploaded launcher advertises separate Ampere and Ada CUDA 12 backends and
a Blackwell CUDA 13 backend. Its embedded diagnostic text requires NVIDIA
driver 595.58.03 or newer for Blackwell. These claims were observed by static
inspection and still require testing on actual RTX 30, 40, and 50 hardware.

Startup and backend output is written to
`/var/log/miner/custom/chatgptminer.log`. When that directory cannot be
created, the wrapper falls back to `/tmp/chatgptminer.log`.

Use `chatgptminer-0.3.7` as the HiveOS **Custom Miner name**. The archive is
flat: `h-run.sh`, `h-config.sh`, the backend, and the manifest are at its root.
HiveOS extracts them directly into `/hive/miners/custom`, which is the path
used by its `miner` screen session.

The archive omits mutable `config.env` and `rgminer_disabled_gpus` files.
HiveOS creates them under its runtime account, avoiding a root-owned file that
prevents `h-config.sh` from saving flight-sheet settings.

`h-config.sh` implements the HiveOS sourced-hook contract (`miner_ver`,
`miner_api_port`, and `miner_config_gen`). The original rgminer standalone
generator is retained as `h-config-rgminer.sh` and is called by the hook.

When HiveOS invokes `h-run.sh` without first exporting the flight-sheet
variables, the wrapper loads `/hive-config/rig.conf` and
`/hive-config/wallet.conf`, regenerates `config.env`, and continues normally.
