#include "pearl/gpu_manager.hpp"
#include "pearl/interfaces.hpp"
#include <chrono>
#include <iostream>

int main() {
    int failures = 0;
    auto expect = [&](bool value, const char* name) {
        if (!value) { std::cerr << "FAIL: " << name << '\n'; ++failures; }
    };
    expect(pearl::GpuManager::classify(8, 6) == pearl::GpuFamily::Ampere, "SM 8.6");
    expect(pearl::GpuManager::classify(8, 9) == pearl::GpuFamily::Ada, "SM 8.9");
    expect(pearl::GpuManager::classify(12, 0) == pearl::GpuFamily::Blackwell, "SM 12.0");
    expect(pearl::GpuManager::classify(7, 5) == pearl::GpuFamily::Unsupported, "unsupported SM");
    auto fee = pearl::make_devfee_manager();
    expect(fee->percentage() == 2.0, "developer fee percent");
    expect(fee->developer_window(std::chrono::seconds(0)), "developer window start");
    expect(!fee->developer_window(std::chrono::seconds(72)), "developer window end");
    if (!failures) std::cout << "6 checks passed\n";
    return failures ? 1 : 0;
}

