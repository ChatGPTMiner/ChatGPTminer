#include "pearl/stratum_client.hpp"
#include <algorithm>
#include <cerrno>
#include <cstring>
#include <netdb.h>
#include <stdexcept>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include <utility>

namespace pearl {
namespace {
std::string escape_json(const std::string& value) {
    std::string out;
    for (const char c : value) {
        if (c == '"' || c == '\\') out.push_back('\\');
        if (c == '\n') { out += "\\n"; continue; }
        out.push_back(c);
    }
    return out;
}

bool contains(const std::string& text, const std::string& needle) {
    return text.find(needle) != std::string::npos;
}
}

StratumClient::StratumClient(MinerConfig config, EventHandler handler)
    : config_(std::move(config)), handler_(std::move(handler)) {}

StratumClient::~StratumClient() { close_socket(); }

void StratumClient::connect_once() {
    addrinfo hints{}; hints.ai_family = AF_UNSPEC; hints.ai_socktype = SOCK_STREAM;
    addrinfo* addresses = nullptr;
    const auto port = std::to_string(config_.pool_port);
    const int rc = getaddrinfo(config_.pool_host.c_str(), port.c_str(), &hints, &addresses);
    if (rc != 0) throw std::runtime_error(std::string("pool DNS failed: ") + gai_strerror(rc));
    for (auto* address = addresses; address; address = address->ai_next) {
        socket_ = socket(address->ai_family, address->ai_socktype, address->ai_protocol);
        if (socket_ >= 0 && connect(socket_, address->ai_addr, address->ai_addrlen) == 0) break;
        close_socket();
    }
    freeaddrinfo(addresses);
    if (socket_ < 0) throw std::runtime_error(std::string("pool connect failed: ") + std::strerror(errno));
    handler_({StratumEvent::Kind::Connected, config_.pool_host + ':' + port});

    send_line("{\"id\":1,\"method\":\"mining.subscribe\",\"params\":[\"ChatGPTminer/0.2.0\"]}");
    const auto user = escape_json(config_.wallet + '.' + config_.worker);
    send_line("{\"id\":2,\"method\":\"mining.authorize\",\"params\":[\"" + user + "\",\"x\"]}");
}

void StratumClient::run(std::atomic_bool& stop) {
    auto delay = std::chrono::seconds(1);
    while (!stop.load()) {
        try {
            connect_once();
            delay = std::chrono::seconds(1);
            std::string line;
            while (!stop.load() && read_line(line, stop)) handler_(classify_line(line));
        } catch (const std::exception& ex) {
            handler_({StratumEvent::Kind::Disconnected, ex.what()});
        }
        close_socket();
        if (stop.load()) break;
        const auto until = std::chrono::steady_clock::now() + delay;
        while (!stop.load() && std::chrono::steady_clock::now() < until)
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        delay = std::min(delay * 2, std::chrono::seconds(30));
    }
}

void StratumClient::submit(std::string job_id, std::string nonce, std::string result) {
    if (socket_ < 0) throw std::runtime_error("share submitted while disconnected");
    const auto id = next_id_++;
    const auto user = escape_json(config_.wallet + '.' + config_.worker);
    send_line("{\"id\":" + std::to_string(id) + ",\"method\":\"mining.submit\",\"params\":[\"" +
              user + "\",\"" + escape_json(job_id) + "\",\"" + escape_json(nonce) + "\",\"" +
              escape_json(result) + "\"]}");
}

void StratumClient::send_line(const std::string& line) {
    const std::string framed = line + '\n';
    std::size_t sent = 0;
    while (sent < framed.size()) {
        const auto n = send(socket_, framed.data() + sent, framed.size() - sent, MSG_NOSIGNAL);
        if (n <= 0) throw std::runtime_error(std::string("pool send failed: ") + std::strerror(errno));
        sent += static_cast<std::size_t>(n);
    }
}

bool StratumClient::read_line(std::string& line, std::atomic_bool& stop) {
    line.clear();
    while (!stop.load()) {
        char c{};
        const auto n = recv(socket_, &c, 1, 0);
        if (n == 0) return false;
        if (n < 0) {
            if (errno == EINTR) continue;
            throw std::runtime_error(std::string("pool receive failed: ") + std::strerror(errno));
        }
        if (c == '\n') return true;
        if (c != '\r') line.push_back(c);
        if (line.size() > 1024 * 1024) throw std::runtime_error("pool line exceeds 1 MiB");
    }
    return false;
}

void StratumClient::close_socket() noexcept {
    if (socket_ >= 0) { shutdown(socket_, SHUT_RDWR); close(socket_); socket_ = -1; }
}

StratumEvent StratumClient::classify_line(const std::string& line) {
    if (contains(line, "\"method\":\"mining.notify\"") || contains(line, "\"method\": \"mining.notify\""))
        return {StratumEvent::Kind::Job, line};
    if (contains(line, "\"id\":2") && contains(line, "\"result\":true"))
        return {StratumEvent::Kind::Authorized, line};
    if (contains(line, "\"result\":true")) return {StratumEvent::Kind::Accepted, line};
    if (contains(line, "\"error\":") && !contains(line, "\"error\":null"))
        return {StratumEvent::Kind::Rejected, line};
    return {StratumEvent::Kind::Connected, line};
}
} // namespace pearl
