## ChatGPTminer v0.2.0 — HiveOS preview

Первый предварительный пакет ChatGPTminer для Linux x64 и HiveOS.

### В составе

- нативный C++20 бинарник без зависимости от .NET Runtime;
- обнаружение NVIDIA GPU и классификация Ampere, Ada и Blackwell;
- Kryptex Stratum TCP-клиент для `prl.kryptex.network:7048`;
- subscribe, authorize, notify, submit и reconnect;
- HiveOS `h-run.sh`, `h-config.sh`, `h-stats.sh` и manifest;
- прозрачная конфигурация DevFee 2%;
- SHA-256 файл для проверки архива.

### Статус

Это preview-релиз инфраструктуры. Pearl CUDA Engine и декодер реального
`mining.notify` ещё не завершены, поэтому пакет пока не добывает shares.

### Установка в HiveOS

Загрузите `chatgptminer-0.2.0-hiveos-linux-x64.tar.gz` как Custom Miner.
Укажите шаблон `%WAL%.%WORKER_NAME%` и URL
`stratum+tcp://prl.kryptex.network:7048`.

Проверьте архив файлом `.sha256` из assets релиза.
