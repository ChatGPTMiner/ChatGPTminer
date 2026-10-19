#include "pearl/gpu_manager.hpp"
#include <array>
#include <dlfcn.h>
#include <stdexcept>

namespace pearl {
namespace {
using CUdevice = int;
using CUresult = int;
using Init = CUresult (*)(unsigned int);
using DeviceCount = CUresult (*)(int*);
using DeviceGet = CUresult (*)(CUdevice*, int);
using DeviceName = CUresult (*)(char*, int, CUdevice);
using ComputeCapability = CUresult (*)(int*, int*, CUdevice);
using TotalMemory = CUresult (*)(std::size_t*, CUdevice);

template<class T> T symbol(void* lib, const char* name) {
    auto result = reinterpret_cast<T>(dlsym(lib, name));
    if (!result) throw std::runtime_error(std::string("missing CUDA symbol: ") + name);
    return result;
}
}

GpuFamily GpuManager::classify(int major, int minor) {
    if (major == 8 && (minor == 0 || minor == 6 || minor == 7)) return GpuFamily::Ampere;
    if (major == 8 && minor == 9) return GpuFamily::Ada;
    if (major == 12) return GpuFamily::Blackwell;
    return GpuFamily::Unsupported;
}

const char* GpuManager::family_name(GpuFamily family) {
    switch (family) {
        case GpuFamily::Ampere: return "Ampere";
        case GpuFamily::Ada: return "Ada Lovelace";
        case GpuFamily::Blackwell: return "Blackwell";
        default: return "unsupported";
    }
}

std::vector<GpuInfo> GpuManager::discover() const {
    void* lib = dlopen("libcuda.so.1", RTLD_NOW | RTLD_LOCAL);
    if (!lib) return {};
    try {
        const auto init = symbol<Init>(lib, "cuInit");
        const auto count_fn = symbol<DeviceCount>(lib, "cuDeviceGetCount");
        const auto get_fn = symbol<DeviceGet>(lib, "cuDeviceGet");
        const auto name_fn = symbol<DeviceName>(lib, "cuDeviceGetName");
        const auto cc_fn = symbol<ComputeCapability>(lib, "cuDeviceComputeCapability");
        const auto mem_fn = symbol<TotalMemory>(lib, "cuDeviceTotalMem_v2");
        int count = 0;
        if (init(0) != 0 || count_fn(&count) != 0) { dlclose(lib); return {}; }
        std::vector<GpuInfo> result;
        for (int i = 0; i < count; ++i) {
            CUdevice device{}; std::array<char, 256> name{}; int major{}, minor{}; std::size_t memory{};
            if (get_fn(&device, i) || name_fn(name.data(), name.size(), device) ||
                cc_fn(&major, &minor, device) || mem_fn(&memory, device)) continue;
            result.push_back({i, name.data(), memory, major, minor, classify(major, minor)});
        }
        dlclose(lib);
        return result;
    } catch (...) { dlclose(lib); throw; }
}
} // namespace pearl

