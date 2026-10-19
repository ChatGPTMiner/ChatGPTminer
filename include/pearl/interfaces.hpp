#pragma once

#include "pearl/config.hpp"
#include "pearl/gpu_manager.hpp"
#include <chrono>
#include <memory>
#include <string>

namespace pearl {

struct ShareResult { bool accepted{}; std::string reason; };

class ICudaEngine {
public:
    virtual ~ICudaEngine() = default;
    virtual void initialize(const GpuInfo&) = 0;
    virtual void stop() noexcept = 0;
};

class IPoolManager {
public:
    virtual ~IPoolManager() = default;
    virtual void connect(const MinerConfig&) = 0;
    virtual void stop() noexcept = 0;
};

class IShareValidator {
public:
    virtual ~IShareValidator() = default;
    virtual bool validate() = 0;
};

class IAutoTuner {
public:
    virtual ~IAutoTuner() = default;
    virtual void observe(const GpuInfo&) = 0;
};

class IDevFeeManager {
public:
    virtual ~IDevFeeManager() = default;
    virtual double percentage() const noexcept = 0;
    virtual const std::string& wallet() const noexcept = 0;
    virtual bool developer_window(std::chrono::seconds elapsed) const noexcept = 0;
};

std::unique_ptr<IDevFeeManager> make_devfee_manager();

} // namespace pearl

