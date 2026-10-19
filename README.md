# ChatGPTminer

Research prototype for a modular Pearl (PRL) GPU miner targeting NVIDIA
Ampere, Ada Lovelace, and Blackwell GPUs.

The current revision provides configuration, GPU discovery, architecture
selection, a reconnecting Kryptex Stratum client, DevFee scheduling interfaces,
tests, and HiveOS launch files. It does **not** yet contain the Pearl job decoder
or CUDA mining engine. The implementation is being written independently; see
[`LICENSE_AUDIT.md`](LICENSE_AUDIT.md).

Build and test instructions are in [`BUILD.md`](BUILD.md). Runtime settings are
in [`RUN.md`](RUN.md).

