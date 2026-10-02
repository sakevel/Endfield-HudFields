local ID = 'hud-fields'
local function reset()
    assert(ZML.set(ID, 'show_uid', true)); assert(ZML.set(ID, 'show_ping', true))
    assert(ZML.set(ID, 'uid_format', 'UID: {uid}')); assert(ZML.set(ID, 'ping_format', '{ping}ms'))
end
function makeCtrl(active)
    local ping = { activeSelf = active ~= false }
    function ping:SetActive(v) self.activeSelf = v end
    local v = {
        text = { text = 'UID: 123456 VER:fixture', richText = true, enabled = true },
        pingNubTxt = { text = '42ms', richText = true },
        pingCon = { gameObject = ping }, text01 = { text = 'untouched' },
        textNode = { SetState = function(self, s) self.state = s end },
        config = { PING_VALUE_STAGE = '0,100,200', PING_COLOR_STAGE = 'green,yellow,red' },
    }
    return { view = v }
end
local function update(c, ping)
    c.view.pingNubTxt.text = tostring(ping) .. 'ms'; H.updated(c, ping)
end
function verifyHelper()
    reset()
    assert(ZML.mod(ID).version == '0.1.2' and #ZML.mod(ID).config.fields == 4)
    assert(not ZML.set(ID, 'uid_format', string.rep('x', 129)))
    assert(not ZML.set(ID, 'uid_format', 'bad\ntext'))
    local c = makeCtrl(); H.bind(c)
    assert(c.view.text.text == 'UID: 123456 VER:fixture' and c.view.text.richText)
    assert(c.view.pingNubTxt.text == '42ms')
    assert(ZML.set(ID, 'show_uid', false)); assert(not c.view.text.enabled)
    assert(ZML.set(ID, 'show_ping', false)); assert(not c.view.pingCon.gameObject.activeSelf)
    assert(c.view.text01.text == 'untouched')
    assert(ZML.set(ID, 'uid_format', '匿名 {uid} % <b> {uid}'))
    assert(c.view.text.text == '匿名 123456 % <b> 123456' and not c.view.text.richText)
    assert(ZML.set(ID, 'ping_format', '延迟 {ping} % <b>'))
    update(c, 999); assert(c.view.pingNubTxt.text == '延迟 999 % <b>')
    update(c, 10); assert(c.view.pingNubTxt.text == '延迟 10 % <b>')
    assert(ZML.set(ID, 'uid_format', '')); assert(c.view.text.text == '')
    assert(ZML.set(ID, 'ping_format', "error('not code')")); assert(c.view.pingNubTxt.text == "error('not code')")
    reset(); assert(c.view.text.enabled and c.view.pingCon.gameObject.activeSelf)
    assert(c.view.text.text == 'UID: 123456 VER:fixture' and c.view.pingNubTxt.text == '10ms')
    assert(c.view.text.richText and c.view.pingNubTxt.richText)
    local cloud = makeCtrl(false); H.bind(cloud)
    assert(not cloud.view.pingCon.gameObject.activeSelf)
    H.close(cloud); H.close(cloud)
    H.close(c)
    assert(ZML.set(ID, 'uid_format', 'after close')); assert(c.view.text.text == 'UID: 123456 VER:fixture')
    -- Manage subscription state per instance
    reset(); H.bind(c); H.bind(c); H.close(c)
    assert(ZML.set(ID, 'uid_format', 'after rebind close')); assert(c.view.text.text == 'UID: 123456 VER:fixture')
    -- Isolate view errors from controller execution
    H.bind({ view = {} }); H.updated({}, 1); H.close({})
    reset()
    local broken = makeCtrl(); H.bind(broken)
    local fields, failOnce = broken.view.text, true
    broken.view.text = setmetatable({}, {
        __index = fields,
        __newindex = function(_, k, value)
            if k == 'text' and failOnce then failOnce = false; error('fixture setter failure') end
            fields[k] = value
        end,
    })
    assert(ZML.set(ID, 'uid_format', 'setter fails'))
    assert(broken.view.text.text == 'UID: 123456 VER:fixture')
    assert(ZML.set(ID, 'uid_format', 'must not resubscribe'))
    assert(broken.view.text.text == 'UID: 123456 VER:fixture')
    -- Virtual API failure at bind leaves native untouched.
    local manager = LuaManagerInst
    LuaManagerInst = { LoadLua = function() return 'not valid lua ]' end }
    local unavailable = makeCtrl(); TestFreshHelper.bind(unavailable)
    assert(unavailable.view.text.text == 'UID: 123456 VER:fixture' and unavailable.view.pingCon.gameObject.activeSelf)
    LuaManagerInst = manager
    reset()
end
function setupHL()
    local op = {}; setmetatable(op, { __shl = function(_, rhs) return rhs end })
    op.Return = function() return op end
    HL = { Class = function() return setmetatable({}, { __newindex = function(t, k, v)
            if v ~= op then rawset(t, k, v) end -- Default field value initialization
        end }) end, Commit = function() end,
        Override = function() return op end, Method = function() return op end,
        StaticMethod = function() return op end, Field = function() return op end,
        StaticField = function() return op end }
    require_ex = function() return { UICtrl = {} } end
    PanelId = { UIDPanel = 17 }; BEYOND_INNER_DEBUG = false
    CS = { Beyond = { CloudGame = { enabled = false }, Cfg = { RemoteNetworkCfg = {
        instance = { data = { channel = 'public' } } } } } }
    GameInstance = { player = { playerInfoSystem = { roleId = '123456' } },
        netClientManager = { GetPing = function(self) return self.ping or 42 end } }
    UIConst = { COMMON_UI_TIME_UPDATE_INTERVAL = 1 }
    UIUtils = { getColorByString = function(s) return s end }
    string.split = function(s)
        local t = {}; for v in s:gmatch('[^,]+') do t[#t + 1] = v end; return t
    end
end
function verifyController()
    reset()
    local c = makeCtrl(); setmetatable(c, { __index = UIDPanelCtrl })
    c._StartCoroutine = function(self, fn) self.pingCoroutine = fn; return 9 end
    c._ClearCoroutine = function(self, handle) assert(handle == 9); self.pingCoroutine = nil; return nil end
    c:OnCreate(nil)
    assert(c.view.text.text == 'UID: 123456' and c.m_updatePingValueCor == 9)
    assert(ZML.set(ID, 'uid_format', '游客')); assert(c.view.text.text == '游客')
    assert(ZML.set(ID, 'ping_format', '{ping} 毫秒'))
    for _, value in ipairs({ 42, -1, 999, 120, 1000, 0 }) do
        GameInstance.netClientManager.ping = value; c:_UpdatePingInfo()
        local clamped = value < 0 or value >= 999
        assert(c.view.pingNubTxt.text == tostring(clamped and 999 or value) .. ' 毫秒')
        assert(c.view.textNode.state == (clamped and 'Warning' or 'Normal'))
    end
    assert(c.view.pingCon.color == 'green')
    assert(ZML.set(ID, 'show_ping', false)); c:_UpdatePingInfo()
    assert(not c.view.pingCon.gameObject.activeSelf)
    c:OnClose(); assert(c.m_updatePingValueCor == nil and c.view.text.text == 'UID: 123456')
    assert(c.view.pingNubTxt.text == '0ms' and c.view.pingCon.gameObject.activeSelf)
    reset(); c:OnCreate(); assert(c.view.text.text == 'UID: 123456'); c:OnClose()
    CS.Beyond.CloudGame.enabled = true
    local cloud = makeCtrl(); setmetatable(cloud, { __index = UIDPanelCtrl }); cloud:OnCreate()
    assert(not cloud.view.pingCon.gameObject.activeSelf and cloud.m_updatePingValueCor == nil)
    assert(ZML.set(ID, 'show_ping', true)); assert(not cloud.view.pingCon.gameObject.activeSelf)
    cloud:OnClose()
end
