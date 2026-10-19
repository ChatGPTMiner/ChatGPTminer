# Architecture

## Scope of version 0.1

Version 0.1 establishes boundaries that allow the Pearl implementation to be
integrated without coupling pool sessions, CUDA resources, monitoring, or
future tuning. The control-plane prototype compiles and can enumerate NVIDIA
devices through the CUDA Driver API. Mining is deliberately disabled until a
licensed Pearl implementation and an authorized pool protocol specification
are available.

## Components

| Component | Responsibility | Version 0.1 status |
|---|---|---|
| Miner Core | Lifecycle, cancellation, worker ownership, graceful shutdown | CLI shell present; mining loop pending |
| GPU Manager | Enumerate devices, memory and compute capability; select devices | Implemented with `libcuda.so.1` |
| CUDA Engine | Own contexts, streams, buffers, Pearl GEMM/BLAKE3 kernels | Interface only |
| Pool Manager | TLS connection, jobs, share submission and reconnect policy | Interface only |
| Share Validator | CPU/GPU cross-check before submission | Interface only |
| Monitoring | Logs, per-GPU throughput, accepted/rejected counters, HiveOS JSON | Output contract planned; zero HiveOS payload only |
| Auto Tuner | Select family-specific kernel parameters | Interface only |
| DevFee Manager | Transparent 2% schedule and developer wallet | Schedule implemented; pool switching pending |
| HiveOS Integration | Translate flight-sheet values and launch/stat scripts | Initial scripts present |

All components run in one process. A future Miner Core owns one worker per
selected GPU and a shared Pool Manager. Each worker owns a CUDA context, its
streams, and buffers. Jobs are immutable snapshots distributed to workers;
shares pass through Share Validator before the pool queue.

## GPU architecture policy

Runtime classification is based on compute capability:

| Family | Compute capability | Planned kernel |
|---|---:|---|
| Ampere RTX 30 | 8.6 (8.0/8.7 accepted for related devices) | Ampere implementation |
| Ada RTX 40 | 8.9 | Ada implementation |
| Blackwell RTX 50 | 12.x | SM 12.0 implementation |

Unsupported devices are reported and must not enter the mining loop. Mixed rigs
select a kernel per GPU. Allocation failures must identify the device and
requested bytes, clean up that worker, and allow independently valid workers to
continue when policy permits.

The inspected Akoya build maps Ampere to SM 80/86, Ada to SM 89, and consumer
Blackwell to SM 120a. It also has a portable path and separate B200 SM 100a
code. Those facts inform the boundaries only; no Akoya implementation was
copied.

## Pearl data path to integrate

The Akoya reference describes the proof of work as low-rank-noised integer GEMM.
GPU work generates/commits input state, performs GEMM, hashes candidate tile
transcripts with BLAKE3, compares against the live target, and returns winning
coordinates and proof material. Host code builds Merkle proofs, rechecks the
claimed hash against the current target, and submits the share.

The reference pool transport is bidirectional gRPC over HTTP/2 with TLS,
session identity, server-pushed jobs, heartbeat/ping traffic, share results,
and reconnect hints. Kryptex compatibility has not been established: an exact
Kryptex PRL endpoint and protocol documentation or capture are required.

## DevFee behavior

`IDevFeeManager` exposes a fixed 2% rate and wallet
`prl1pgdkhaj8h5pdu33rczlzj5ljvx37dh0zpynwj3kjzvv054w8p2lxsz0003y`.
The initial scheduler reserves the first 72 seconds of every 3600-second cycle.
It does not yet switch pool sessions, so no developer mining occurs in this
revision. Production integration must display the rate and wallet at startup,
avoid discarding user shares at boundaries, and report user/dev intervals.

## Minimal integration plan

1. Obtain an explicit license for Akoya code, or a standalone Pearl consensus
   and pool protocol specification with test vectors.
2. Add the native Pearl library behind `ICudaEngine`; preserve its C ABI and
   validate BLAKE3/GEMM results against published vectors.
3. Implement the Kryptex transport behind `IPoolManager` after its actual
   protocol and endpoint are confirmed.
4. Connect workers, pre-submit validation, counters, reconnect/backoff, and
   bounded shutdown in Miner Core.
5. Add per-family binaries or fatbins and exercise each on real RTX 30/40/50
   hardware before performance work.

