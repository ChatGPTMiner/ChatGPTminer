# Test report

Date: 2026-10-19. Environment: Linux x64 cloud container.

## Environment observed before build

- NVIDIA GPU: unavailable
- `nvidia-smi`: unavailable
- CUDA compiler (`nvcc`): unavailable
- CMake: unavailable at initial inspection
- GCC: 14.2.0

## Test matrix

| Check | Status | Evidence / limitation |
|---|---|---|
| Source provenance | Passed | Akoya and CUTLASS commits recorded in `LICENSE_AUDIT.md` |
| C++ compilation | Passed | GCC 14.2.0, Release build, no compiler warnings |
| Core unit checks | Passed | CTest: 1/1 test, 9 assertions |
| Native CUDA library loading | Not run | No licensed Pearl library and no CUDA toolkit |
| Independent CUDA test kernel | Source complete, not compiled | DP4A GEMM/target C ABI added; environment has no `nvcc` or GPU |
| NVIDIA GPU discovery | Partially passed | CLI ran safely and reported 0 devices; no hardware validation |
| Pearl algorithm vectors | Blocked | No licensed implementation or independent specification/vectors |
| Kryptex pool connection | Environment blocked | Endpoint identified as `prl.kryptex.network:7048`; runtime DNS policy rejected lookup |
| Pool error/reconnect | Partial pass | Client retried DNS failures with backoff; live handshake awaits published network setting |
| Start/stop and CUDA cleanup | Blocked | CUDA engine pending |
| Configuration failure path | Passed | Valid config reaches engine gate and exits 3 with explicit error |
| HiveOS shell syntax/config mapping | Passed | `bash -n`; wallet, worker, host and port assertions passed |
| HiveOS statistics adapter | Passed for contract | Mock API: two GPUs, kH/s conversion, shares, uptime and bus IDs verified |
| Ampere SM 86 | Not run | Requires real RTX 30 rig |
| Ada SM 89 | Not run | Requires real RTX 40 rig |
| Blackwell SM 120 | Not run | Requires real RTX 50 rig and supporting toolkit/driver |

## rgminer 1.1.3b compatibility sample

The operator-supplied archive was inspected without executing its binary. Tar
paths were safe, the executable was a stripped Linux x86-64 PIE, and the HiveOS
scripts passed shell syntax checks after integration. Static strings advertise
separate Ampere and Ada CUDA 12 backends plus a Blackwell CUDA 13 backend; the
launcher reports a minimum Blackwell driver of 595.58.03. The package contract
uses algorithm `pearl`, API port 9200, and JSON metrics at `/metrics`.

Real pool authorization, backend download or extraction, CUDA loading,
hashrate, share acceptance, the 49/1-minute wallet switch, and all GPU-family
claims remain untested because this cloud environment has no NVIDIA GPU.

The v0.3.1 wrapper also has a flight-sheet fallback when `config.env` has not
been generated and redirects startup errors and backend output to the manifest
log path (or `/tmp/chatgptminer.log` if that path is unavailable).

Hardware validation must cover at least one GPU from each generation, mixed
multi-GPU selection, insufficient VRAM, forced pool disconnect, invalid share,
TLS failure, SIGINT/SIGTERM during work, and a sustained mining run. Hashrate,
accepted/rejected shares, power, and thermals must come from those runs; none
are claimed here.

