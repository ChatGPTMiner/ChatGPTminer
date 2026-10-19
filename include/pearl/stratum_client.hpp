#pragma once

#include "pearl/config.hpp"
#include <atomic>
#include <chrono>
#include <functional>
#include <string>

namespace pearl {

struct StratumEvent {
    enum class Kind { Connected, Authorized, Job, Accepted, Rejected, Disconnected };
    Kind kind;
    std::string payload;
};

class StratumClient {
public:
    using EventHandler = std::function<void(const StratumEvent&)>;

    explicit StratumClient(MinerConfig config, EventHandler handler);
    ~StratumClient();
    StratumClient(const StratumClient&) = delete;
    StratumClient& operator=(const StratumClient&) = delete;

    void run(std::atomic_bool& stop);
    void submit(std::string job_id, std::string nonce, std::string result);

    static StratumEvent classify_line(const std::string& line);

private:
    MinerConfig config_;
    EventHandler handler_;
    int socket_{-1};
    unsigned next_id_{3};

    void connect_once();
    void close_socket() noexcept;
    void send_line(const std::string& line);
    bool read_line(std::string& line, std::atomic_bool& stop);
};

} // namespace pearl

