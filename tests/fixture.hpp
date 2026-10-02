#pragma once
#include <string>
// Original test fixture, not bundled game code. Contracts exercised by patch().
inline std::string fixture() {
    return R"(local uiCtrl = require_ex('UI/Panels/Base/UICtrl')
local PANEL_ID = PanelId.UIDPanel
local NetClientInst = GameInstance.netClientManager
UIDPanelCtrl = HL.Class('UIDPanelCtrl', uiCtrl.UICtrl)
UIDPanelCtrl.OnCreate = HL.Override(HL.Any) << function(self, arg)
    self.view.text.text = string.format("UID: %s", GameInstance.player.playerInfoSystem.roleId)
    local enablePing = self:_EnablePing()
    self.view.pingCon.gameObject:SetActive(enablePing)
    if enablePing then
        self:_UpdatePingInfo()
    end
end

UIDPanelCtrl.OnClose = HL.Override() << function(self)
end
UIDPanelCtrl._EnablePing = HL.Method().Return(HL.Boolean) << function(self)
    return not CS.Beyond.CloudGame.enabled
end
UIDPanelCtrl._UpdatePingInfo = HL.Method() << function(self)
    local pingValue = NetClientInst:GetPing()
    local pingWarning = pingValue < 0 or pingValue >= 999
    local clampPingValue = pingWarning and 999 or pingValue
    self.view.textNode:SetState(pingWarning and "Warning" or "Normal" )
    self.view.pingNubTxt.text = string.format("%sms", clampPingValue)
    if pingWarning then return end
    self.view.pingCon.color = "native-color"
end
HL.Commit(UIDPanelCtrl)
)";
}
