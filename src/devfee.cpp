#include "pearl/interfaces.hpp"

namespace pearl {
namespace {
class TransparentDevFee final : public IDevFeeManager {
    const std::string wallet_{"prl1pgdkhaj8h5pdu33rczlzj5ljvx37dh0zpynwj3kjzvv054w8p2lxsz0003y"};
public:
    double percentage() const noexcept override { return 2.0; }
    const std::string& wallet() const noexcept override { return wallet_; }
    bool developer_window(std::chrono::seconds elapsed) const noexcept override {
        constexpr auto cycle = 3600;
        constexpr auto fee_seconds = 72;
        return elapsed.count() % cycle < fee_seconds;
    }
};
}

std::unique_ptr<IDevFeeManager> make_devfee_manager() {
    return std::make_unique<TransparentDevFee>();
}
} // namespace pearl

