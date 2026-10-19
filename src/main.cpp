#include "pearl/config.hpp"
#include "pearl/gpu_manager.hpp"
#include "pearl/interfaces.hpp"
#include <iomanip>
#include <iostream>

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
                std::cout << "Pearl algorithm check: BLOCKED (licensed implementation/specification required)\n";
            }
            return 0;
        }
        if (command == "mine") {
            const auto config = pearl::MinerConfig::from_environment();
            if (const auto error = config.validate_for_mining()) {
                std::cerr << "Configuration error: " << *error << '\n'; return 2;
            }
            std::cerr << "Mining engine unavailable: Akoya source has no license granting reuse.\n";
            return 3;
        }
        std::cout << "ChatGPTminer 0.1.0 research prototype\n"
                     "Usage: chatgptminer list-gpus | selftest | mine\n";
        return command == "help" ? 0 : 64;
    } catch (const std::exception& ex) {
        std::cerr << "Fatal: " << ex.what() << '\n'; return 1;
    }
}

