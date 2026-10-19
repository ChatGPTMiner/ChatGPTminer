#include "pearl/config.hpp"
#include "pearl/gpu_manager.hpp"
#include "pearl/interfaces.hpp"
#include "pearl/stratum_client.hpp"
#include <atomic>
#include <chrono>
#include <csignal>
#include <iomanip>
#include <iostream>
#include <thread>

namespace {
std::atomic_bool stop_requested{false};
void request_stop(int) { stop_requested.store(true); }
}

int main(int argc, char** argv) {
    const std::string command = argc > 1 ? argv[1] : "help";
    try {
        pearl::GpuManager gpu_manager;
        const auto gpus = gpu_manager.discover();
        if (command == "list-gpus" || command == "selftest") {
            std::cout << "Detected NVIDIA GPUs: " << gpus.size() << '\n';
            for (const auto& gpu : gpus) {
                std::cout << '[' << gpu.index << "] " << gpu.name << ", "
                          << std::fixed << std::setprecision(1)
                          << (gpu.memory_bytes / 1073741824.0) << " GiB, SM "
                          << gpu.compute_major << '.' << gpu.compute_minor << ", "
                          << pearl::GpuManager::family_name(gpu.family) << '\n';
            }
            if (command == "selftest") {
                const auto fee = pearl::make_devfee_manager();
                std::cout << "DevFee: " << fee->percentage() << "% -> " << fee->wallet() << '\n';
                std::cout << "GPU runtime check: " << (gpus.empty() ? "SKIPPED (no NVIDIA GPU/driver)" : "PASS") << '\n';
                std::cout << "Pearl algorithm check: PENDING (live job capture, vectors, CUDA hardware)\n";
            }
            return 0;
        }
        if (command == "pool-probe") {
            const auto config = pearl::MinerConfig::from_environment();
            if (const auto error = config.validate_for_mining()) {
                std::cerr << "Configuration error: " << *error << '\n'; return 2;
            }
            if (config.tls) {
                std::cerr << "Configuration error: Kryptex endpoint uses stratum+tcp; set PRL_POOL_TLS=0\n";
                return 2;
            }
            std::signal(SIGINT, request_stop);
            std::signal(SIGTERM, request_stop);
            const int seconds = argc > 2 ? std::stoi(argv[2]) : 0;
            std::jthread deadline;
            if (seconds > 0) deadline = std::jthread([seconds] {
                std::this_thread::sleep_for(std::chrono::seconds(seconds));
                stop_requested.store(true);
            });
            pearl::StratumClient client(config, [](const pearl::StratumEvent& event) {
                static const char* names[] = {"connected", "authorized", "job", "accepted", "rejected", "disconnected"};
                std::cout << "pool " << names[static_cast<int>(event.kind)] << ": " << event.payload << '\n';
            });
            client.run(stop_requested);
            return 0;
        }
        if (command == "mine") {
            const auto config = pearl::MinerConfig::from_environment();
            if (const auto error = config.validate_for_mining()) {
                std::cerr << "Configuration error: " << *error << '\n'; return 2;
            }
            std::cerr << "Mining engine unavailable: clean-room Pearl job decoder and CUDA engine are not complete.\n";
            return 3;
        }
        std::cout << "ChatGPTminer 0.2.0 research prototype\n"
                     "Usage: chatgptminer list-gpus | selftest | pool-probe [seconds] | mine\n";
        return command == "help" ? 0 : 64;
    } catch (const std::exception& ex) {
        std::cerr << "Fatal: " << ex.what() << '\n'; return 1;
    }
}

