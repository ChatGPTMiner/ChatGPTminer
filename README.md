# ChatGPTminer

Research prototype for a modular Pearl (PRL) GPU miner targeting NVIDIA
Ampere, Ada Lovelace, and Blackwell GPUs.

The current revision provides configuration, GPU discovery, architecture
selection, DevFee scheduling interfaces, tests, and HiveOS launch files. It
does **not** contain a Pearl mining engine or pool client. The reference Akoya
repository has no license granting reuse of its own source code; see
[`LICENSE_AUDIT.md`](LICENSE_AUDIT.md).

Build and test instructions are in [`BUILD.md`](BUILD.md). Runtime settings are
in [`RUN.md`](RUN.md).

