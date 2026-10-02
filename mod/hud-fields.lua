-- Helper injected for UIDPanelCtrl.
local states = setmetatable({}, { __mode = "k" })
local api
local function service()
    if not api then
        local fn, err = loadstring(LuaManagerInst:LoadLua("ZML/Api"), "@ZML/Api")
        assert(fn, err)
        api = fn()
        assert(api.api_version == 1)
    end
    return api
end
local function format(template, key, value)
    -- Pattern replacement treating formatted input as string data.
    return (template:gsub("{" .. key .. "}", function() return value end))
end
local function restore(s)
    s.view.text.text = s.uidText
    s.view.text.richText = s.uidRich
    s.view.text.enabled = s.uidEnabled
    s.view.pingNubTxt.text = s.pingText
    s.view.pingNubTxt.richText = s.pingRich
    s.view.pingCon.gameObject:SetActive(s.pingActive)
end
local function apply(s)
    local v, cfg = s.view, s.values
    v.text.enabled = s.uidEnabled and cfg.show_uid ~= "false"
    v.pingCon.gameObject:SetActive(s.pingActive and cfg.show_ping ~= "false")
    local uidTemplate = cfg.uid_format or "UID: {uid}"
    local pingTemplate = cfg.ping_format or "{ping}ms"
    -- Format text with dynamic placeholders.
    v.text.text = uidTemplate == "UID: {uid}" and s.uidText or format(uidTemplate, "uid", s.uid)
    v.text.richText = uidTemplate == "UID: {uid}" and s.uidRich or false
    v.pingNubTxt.text = pingTemplate == "{ping}ms" and s.pingText or format(pingTemplate, "ping", s.ping)
    v.pingNubTxt.richText = pingTemplate == "{ping}ms" and s.pingRich or false
end
local function detach(ctrl)
    local s = states[ctrl]
    if not s then return end
    states[ctrl] = nil
    if s.unsubscribe then pcall(s.unsubscribe) end
    -- Cleanup on view destruction.
    pcall(restore, s)
end
local function failed(ctrl)
    detach(ctrl)
    if api then pcall(api.report, "hud-fields", "display_error") end
end
local function guarded(ctrl, fn)
    if not pcall(fn) then failed(ctrl) end
end
local H = {}
function H.bind(ctrl)
    detach(ctrl)
    guarded(ctrl, function()
        local zml = service()
        local v = ctrl.view
        local s = {
            view = v, values = assert(zml.get("hud-fields")),
            uidText = v.text.text, uidRich = v.text.richText, uidEnabled = v.text.enabled,
            pingText = v.pingNubTxt.text, pingRich = v.pingNubTxt.richText,
            pingActive = v.pingCon.gameObject.activeSelf,
        }
        s.uid = s.uidText:match("UID:%s*(%S+)") or ""
        s.ping = s.pingText:match("^(.-)ms$") or ""
        states[ctrl] = s
        s.unsubscribe = zml.subscribe("hud-fields", function(_, _, values)
            guarded(ctrl, function() s.values = values; apply(s) end)
        end)
        apply(s)
        zml.report("hud-fields", "hud_bound")
    end)
end
function H.updated(ctrl, ping)
    local s = states[ctrl]
    if not s then return end
    guarded(ctrl, function()
        -- Cache native text value before replacement.
        s.pingText = s.view.pingNubTxt.text
        s.ping = tostring(ping)
        apply(s)
    end)
end
H.close = detach
return H
