# HiveOS transition package with SRBMiner backend

This package provides real Pearl mining while the native ChatGPTminer consensus
engine is under development. It uses the user-supplied SRBMiner 3.7.7 ELF as
the GPU backend and ChatGPTminer scripts for HiveOS configuration, monitoring,
and the transparent 2% schedule.

## HiveOS flight sheet

- Coin: PRL
- Wallet and worker template: `%WAL%.%WORKER_NAME%`
- Pool: `stratum+tcp://prl.kryptex.network:7048`
- Algorithm: `pearlhash` (selected automatically)
- Password: `x` (selected automatically)

Upload and extract
`chatgptminer-0.2.0-hiveos-srb-backend-linux-x64.tar.gz` as a Custom Miner.
HiveOS launches `h-run.sh`; no separate command-line arguments are required.

The launcher mines to the flight-sheet wallet for 2940 seconds, then to
`prl1pgdkhaj8h5pdu33rczlzj5ljvx37dh0zpynwj3kjzvv054w8p2lxsz0003y`
for 60 seconds. Each 3000-second wall-clock cycle is therefore 98% user and 2%
developer. Transitions restart the backend and are written to
`/var/log/miner/custom/chatgptminer.log`.

SRBMiner may apply its own upstream developer fee in addition to this wrapper.
The package cannot remove or account for that internal fee.

## Validation on the rig

After launch, check:

```bash
tail -f /var/log/miner/custom/chatgptminer.log
curl --silent http://127.0.0.1:21373/ | jq .
```

The log must show `pearlhash`, the Kryptex endpoint, GPU initialization, a new
job, and eventually accepted shares. A running process or displayed hashrate
alone does not prove that shares are accepted.

