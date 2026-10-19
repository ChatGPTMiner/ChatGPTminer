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
| Core unit checks | Passed | CTest: 1/1 test, 6 assertions |
| Native CUDA library loading | Not run | No licensed Pearl library and no CUDA toolkit |
| NVIDIA GPU discovery | Partially passed | CLI ran safely and reported 0 devices; no hardware validation |
| Pearl algorithm vectors | Blocked | No licensed implementation or independent specification/vectors |
| Kryptex pool connection | Blocked | Exact PRL endpoint/protocol not supplied or established |
| Pool error/reconnect | Blocked | Pool client pending |
| Start/stop and CUDA cleanup | Blocked | CUDA engine pending |
| Configuration failure path | Passed | Valid config reaches engine gate and exits 3 with explicit error |
| HiveOS shell syntax/config mapping | Passed | `bash -n`; wallet, worker, host and port assertions passed |
| HiveOS statistics adapter | Partial | Valid zero-value JSON emitted; live statistics await engine |
| Ampere SM 86 | Not run | Requires real RTX 30 rig |
| Ada SM 89 | Not run | Requires real RTX 40 rig |
| Blackwell SM 120 | Not run | Requires real RTX 50 rig and supporting toolkit/driver |

Hardware validation must cover at least one GPU from each generation, mixed
multi-GPU selection, insufficient VRAM, forced pool disconnect, invalid share,
TLS failure, SIGINT/SIGTERM during work, and a sustained mining run. Hashrate,
accepted/rejected shares, power, and thermals must come from those runs; none
are claimed here.

