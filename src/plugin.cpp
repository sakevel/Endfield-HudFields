#include "zml_plugin.h"
#include "patch.hpp"
#include <filesystem>
#include <fstream>
#include <iterator>
namespace {
const ZmlHost* hostApi{};
std::string helper;
int rewrite(void*, const char* source, size_t size, ZmlSink sink, void* writer) {
    try {
        if (!source || !sink) return 0;
        std::string patched;
        if (!hud_fields::patch(std::string_view(source, size), helper, patched)) {
            hostApi->log(hostApi->owner, "UIDPanelCtrl patch rejected");
            return 0;
        }
        sink(writer, patched.data(), patched.size());
        return 1;
    } catch (...) { return 0; }
}
int initialise(const ZmlHost* host) {
    if (!host || host->size != sizeof(ZmlHost) || host->abi != 1 || !host->mod_directory ||
        !host->transform_lua || !host->log) return 0;
    try {
        const auto directory = std::filesystem::path(std::u8string(reinterpret_cast<const char8_t*>(host->mod_directory)));
        const auto file = directory / L"hud-fields.lua";
        if (std::filesystem::file_size(file) > 32 * 1024) return 0;
        std::ifstream stream(file, std::ios::binary);
        if (!stream) return 0;
        std::string data{std::istreambuf_iterator<char>(stream), {}};
        if (data.empty() || data.find('\0') != data.npos) return 0;
        helper = std::move(data);
        hostApi = host;
        return host->transform_lua(host->owner, "UI/Panels/UIDPanel/UIDPanelCtrl", rewrite, nullptr);
    } catch (...) { return 0; }
}
const ZmlPlugin plugin{sizeof(ZmlPlugin), 1, "hud-fields", initialise};
}
extern "C" __declspec(dllexport) const ZmlPlugin* ZML_PluginV1() { return &plugin; }
