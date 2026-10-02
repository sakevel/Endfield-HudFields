#pragma once
#include <algorithm>
#include <string>
#include <string_view>
#include <vector>
namespace hud_fields {
inline bool patch(std::string_view source, std::string_view helper, std::string& output) {
    if (helper.empty() || helper.find('\0') != helper.npos || source.find("_zmlHudFields") != source.npos)
        return false;
    // Normalize line endings before applying patches.
    std::string input(source);
    for (size_t p = 0; (p = input.find("\r\n", p)) != input.npos;) input.erase(p, 1);
    struct Change { size_t at; std::string text; };
    std::vector<Change> changes;
    const std::vector<std::pair<std::string_view, std::string>> rules{
        {"UIDPanelCtrl = HL.Class('UIDPanelCtrl', uiCtrl.UICtrl)",
         "local _zmlHudFields = (function()\n" + std::string(helper) + "\nend)()\n"},
        {"    end\nend\n\nUIDPanelCtrl.OnClose", "\n    _zmlHudFields.bind(self)"},
        {"UIDPanelCtrl.OnClose = HL.Override() << function(self)\n", "    _zmlHudFields.close(self)\n"},
        {"    self.view.pingNubTxt.text = string.format(\"%sms\", clampPingValue)\n",
         "    _zmlHudFields.updated(self, clampPingValue)\n"},
    };
    for (size_t i = 0; i < rules.size(); ++i) {
        const auto& [anchor, text] = rules[i];
        auto pos = input.find(anchor);
        if (pos == input.npos || input.find(anchor, pos + anchor.size()) != input.npos) return false;
        if (i == 1) pos += std::string_view("    end").size();
        if (i >= 2) pos += anchor.size();
        changes.push_back({pos, text});
    }
    for (auto anchor : {"UIDPanelCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)",
                        "self.view.text.text = string.format(\"UID: %s\", GameInstance.player.playerInfoSystem.roleId)",
                        "self.view.pingCon.gameObject:SetActive(enablePing)",
                        "UIDPanelCtrl._UpdatePingInfo = HL.Method() << function(self)",
                        "local pingValue = NetClientInst:GetPing()", "HL.Commit(UIDPanelCtrl)"}) {
        auto pos = input.find(anchor);
        if (pos == input.npos || input.find(anchor, pos + std::string_view(anchor).size()) != input.npos) return false;
    }
    std::sort(changes.begin(), changes.end(), [](const auto& a, const auto& b) { return a.at > b.at; });
    for (const auto& change : changes) input.insert(change.at, change.text);
    output = std::move(input);
    return true;
}
}
