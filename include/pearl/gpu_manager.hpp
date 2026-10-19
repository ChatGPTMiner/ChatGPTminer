#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace pearl {

enum class GpuFamily { Ampere, Ada, Blackwell, Unsupported };

struct GpuInfo {
    int index{};
    std::string name;
    std::uint64_t memory_bytes{};
    int compute_major{};
    int compute_minor{};
    GpuFamily family{GpuFamily::Unsupported};
};

class GpuManager {
public:
    std::vector<GpuInfo> discover() const;
    static GpuFamily classify(int major, int minor);
    static const char* family_name(GpuFamily family);
};

} // namespace pearl

