# HiveOS rgminer compatibility package

This transition build uses the operator-supplied rgminer 1.1.3b binary while
the independent Pearl CUDA engine remains under development. It preserves the
working rgminer HiveOS contract: algorithm `pearl`, API port `9200`, metrics at
`/metrics`, and `--stratum` pool endpoints.

Build the archive without executing the supplied binary:

```bash
./scripts/package-hiveos-rgminer-backend.sh /path/to/rgminer-1.1.3b-hiveos.tar.gz
```

In HiveOS, set `ADDRESS`, `WORKER_NAME`, and `POOLS` in the Custom Miner
configuration. A typical plaintext pool value is
`stratum+tcp://host:port`; use the pool's documented TLS URL when applicable.
The wrapper alternates 2940 seconds on the user's wallet and 60 seconds on the
documented developer wallet. Each phase change reconnects the backend.

The uploaded launcher advertises separate Ampere and Ada CUDA 12 backends and
a Blackwell CUDA 13 backend. Its embedded diagnostic text requires NVIDIA
driver 595.58.03 or newer for Blackwell. These claims were observed by static
inspection and still require testing on actual RTX 30, 40, and 50 hardware.
