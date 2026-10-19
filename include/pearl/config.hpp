#pragma once

#include <optional>
#include <string>
#include <vector>

namespace pearl {

struct MinerConfig {
    std::string wallet;
    std::string worker;
    std::string pool_host;
    int pool_port{443};
    bool tls{true};
    std::vector<int> gpu_indices;
    std::string log_level{"info"};

    static MinerConfig from_environment();
    std::optional<std::string> validate_for_mining() const;
};

} // namespace pearl

