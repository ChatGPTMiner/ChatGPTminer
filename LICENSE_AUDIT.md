# License audit

Audit date: 2026-10-19.

## Reference repository

- Repository: `https://github.com/akoyapool/akoya-miner`
- Inspected commit: `0e42b2a50b4cb62cb8995b77420226c2182137ce`
- CUTLASS submodule commit: `25e252bdce504932d83f43f07c4b8cc7f9b8e2b6`

At the inspected commit, the repository contains no root `LICENSE`, `COPYING`,
or `NOTICE` file and no license declaration for its C#, CUDA/C++, Rust, shell,
protobuf, or documentation files. The README calls the project open source,
but that statement does not grant the permissions normally supplied by a
software license.

The README identifies NVIDIA CUTLASS as BSD-3-Clause. CUTLASS is a separate Git
submodule and retains its own license. That license does not cover Akoya's own
code.

## Decision

No Akoya source, protobuf schema, scripts, binaries, or generated derivatives
are included in ChatGPTminer. Observed public behavior and high-level component
boundaries are recorded for interoperability research. Before integrating
Akoya code, obtain a license from its copyright holder that permits use,
modification, redistribution, commercial distribution, and the intended 2%
developer fee model.

ChatGPTminer itself currently has no distribution license because the owner has
not selected one. Until a project license is added, third parties have no
general permission to copy or distribute this repository.

This is an engineering audit, not legal advice.

