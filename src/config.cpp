#include "pearl/config.hpp"
#include <cstdlib>
#include <sstream>
#include <stdexcept>

namespace pearl {
namespace {
std::string env_or(const char* primary, const char* compatible, std::string fallback = {}) {
    if (const char* value = std::getenv(primary); value && *value) return value;
    if (compatible) if (const char* value = std::getenv(compatible); value && *value) return value;
    return fallback;
}

bool bool_env(const char* primary, const char* compatible, bool fallback) {
    const auto value = env_or(primary, compatible);
    if (value.empty()) return fallback;
    if (value == "1" || value == "true" || value == "TRUE") return true;
    if (value == "0" || value == "false" || value == "FALSE") return false;
    throw std::invalid_argument(std::string(primary) + " must be true/false or 1/0");
}
}

MinerConfig MinerConfig::from_environment() {
    MinerConfig c;
    c.wallet = env_or("PRL_WALLET", "AKOYA_POOL_WALLET");
    c.worker = env_or("PRL_WORKER", "AKOYA_POOL_WORKER", "default");
    c.pool_host = env_or("PRL_POOL_HOST", "AKOYA_POOL_HOST", "prl.kryptex.network");
    c.log_level = env_or("PRL_LOG_LEVEL", "AKOYA_LOG_LEVEL", "info");
    c.tls = bool_env("PRL_POOL_TLS", "AKOYA_POOL_TLS", false);
    const auto port = env_or("PRL_POOL_PORT", "AKOYA_POOL_PORT", "7048");
    c.pool_port = std::stoi(port);

    const auto gpus = env_or("PRL_GPU_INDICES", "AKOYA_GPU_INDICES", "all");
    if (gpus != "all") {
        std::stringstream stream(gpus);
        std::string item;
        while (std::getline(stream, item, ',')) c.gpu_indices.push_back(std::stoi(item));
    }
    return c;
}

std::optional<std::string> MinerConfig::validate_for_mining() const {
    if (wallet.empty()) return "PRL_WALLET (or AKOYA_POOL_WALLET) is required";
    if (pool_host.empty()) return "PRL_POOL_HOST (or AKOYA_POOL_HOST) is required; use the Kryptex PRL endpoint";
    if (pool_port < 1 || pool_port > 65535) return "pool port must be between 1 and 65535";
    return std::nullopt;
}
} // namespace pearl

