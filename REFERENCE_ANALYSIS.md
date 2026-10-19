# Akoya reference analysis

This document records observations from Akoya Miner commit
`0e42b2a50b4cb62cb8995b77420226c2182137ce`. It contains no copied source or
protocol definitions.

## Source layout and execution

- `src/Akoya.Miner` owns startup, reconnect, workers, share construction,
  metrics, and HiveOS output.
- `src/Akoya.Pool` owns registration, bidirectional gRPC streaming, ping,
  heartbeat, session persistence, share results, and reconnect hints.
- `src/Akoya.Crypto` contains managed BLAKE3, commitment, deterministic noise,
  jackpot reconstruction, and Merkle/audit helpers.
- `src/Akoya.Cuda` calls the CUDA Driver API.
- `src/Akoya.PearlGemm` and `src/Akoya.Mining` are native ABI bindings.
- `native/pearl-gemm` implements CUDA/ROCm work; `native/pearl-blake3` and
  `native/pearl-mining-capi` implement host Merkle operations in Rust.

The .NET host is published as Native AOT and loads two native libraries: the
GPU GEMM library and the host mining/Merkle library.

## CUDA and validation path

The native C ABI exposes architecture/profile checks, scratch sizing, keyed
tensor hashes, B-seed expansion, commitment hashes, noise generation, workspace
installation, and single/batched iterations.

For each job state, B is expanded from the pool seed, hashed into a keyed
Merkle structure, committed, and noised. For each candidate nonce, A is
generated, hashed/committed, and noised. The hot path then performs integer
GEMM and builds the canonical tile transcript. Consumer Ampere/Ada kernels use
a headless transcript path; Blackwell has a dedicated SM 120a implementation;
fallback paths materialize a transcript buffer and run a finalization kernel.
BLAKE3 hashes the transcript and compares it to the 256-bit target. A pinned
host signal carries a winning tile to the host.

On a hit, host code reconstructs the selected A/B slices and deterministic
noise, recomputes the jackpot words and claimed BLAKE3 hash, builds keyed Merkle
proofs, optionally opens audit paths, and constructs a share. A live-target
guard rechecks the claimed hash before enqueueing it. The pool performs final
verification and returns accepted/rejected status.

The native build profiles observed are:

- Ampere: SM 80 and SM 86.
- Ada: SM 89.
- Consumer Blackwell: SM 120a.
- Portable fallback: SM 80/86 plus its fallback behavior.
- Separate non-consumer profiles exist for Hopper SM 90a and B200 SM 100a.

## Pool protocol

Akoya speaks a custom V2 protobuf/gRPC protocol, not conventional Stratum. It
registers the miner/GPU inventory, obtains session identity, then opens a
bidirectional stream. The miner side sends authentication, shares, heartbeats,
and pings. The pool side sends jobs, share results, difficulty updates, pongs,
errors, and reconnect hints. TLS is enabled by default. A persisted identity
allows resume across reconnects.

The inspected code defaults to Akoya Pool. It does not demonstrate Kryptex
compatibility. Kryptex support therefore requires a confirmed endpoint and a
protocol match or a separate adapter; changing only the hostname is not enough
evidence.

## HiveOS

Akoya maps the flight-sheet wallet/worker and URL into environment variables,
selects a per-architecture native library using compute capability, verifies
the CUDA runtime, starts its AOT binary, and converts a miner-written JSON
snapshot into HiveOS statistics. The meaningful Pearl performance unit used by
the reference is TMAD/s (trillion multiply-add operations per second), even
though HiveOS transport fields retain generic `hs` names.

