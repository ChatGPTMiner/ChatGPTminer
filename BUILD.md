# Build

## Current prototype

Requirements: Linux x64, a C++20 compiler, CMake 3.20+, and `libdl`. CUDA
Toolkit is not required for the control-plane build. GPU discovery loads
`libcuda.so.1` at runtime when an NVIDIA driver is present.

```bash
git clone <your ChatGPTminer URL>
cd ChatGPTminer
chmod +x scripts/build.sh hiveos/*.sh
./scripts/build.sh
```

The binary is installed as `out/bin/chatgptminer`. The script configures a
Release build, compiles, runs CTest, and installs the executable.

## CUDA test kernel

The repository contains an independent, non-consensus CUDA test backend. It
performs signed int8 GEMM with `dp4a`, builds a deterministic test transcript,
checks a 64-bit target, and atomically reports the first winning tile through a
C ABI. Build it on a CUDA machine with:

```bash
cmake -S . -B build-cuda \
  -DCMAKE_BUILD_TYPE=Release \
  -DPEARL_BUILD_CUDA_TEST_KERNEL=ON \
  -DCMAKE_CUDA_ARCHITECTURES="86;89"
cmake --build build-cuda --parallel
```

For a toolkit that supports consumer Blackwell, add architecture `120` (or the
toolkit-specific `120a` spelling). The test digest is deliberately not the
Pearl BLAKE3/Merkle consensus digest and must never be submitted to a pool.

Equivalent manual commands:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build build --parallel
ctest --test-dir build --output-on-failure
cmake --install build --prefix out
```

## Future Pearl CUDA build requirements

Akoya's documentation specifies CUDA Toolkit 12.4+ for its general CUDA code
and CUDA 12.8 for newer architectures. Its SM 120a Blackwell target requires a
toolkit that supports that target. The runtime driver must be new enough for
the CUDA runtime used by the final binary. Exact minimum driver versions must
be pinned against the selected CUDA release notes during integration.

Planned build targets are SM 86 for RTX 30, SM 89 for RTX 40, and SM 120a for
RTX 50, with one runtime-selected library per family. These targets have not
been compiled in this environment because `nvcc` and an NVIDIA GPU are absent.

If Native AOT is retained for a future .NET host, install the exact .NET SDK
selected by the project plus `clang` and `zlib` development headers. The
current prototype is a native C++ executable and needs no .NET runtime.

