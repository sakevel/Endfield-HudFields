# 原生 HUD 契约与补丁机制

本文档说明游戏界面左下角 UID 面板的内部结构与自定义 HUD 字段的注入契约。

---

## 1. 原生 UIDPanel 结构

游戏主界面的 UID 与延迟信息由 `UI/Panels/UIDPanel/UIDPanelCtrl` 控制：
- **生命周期入口**：
  - `OnCreate`：初始化基础视图组件，读取角色 UID 赋值给 `view.text`，并启动原生协程 `_UpdatePingInfo` 持续轮询网络延迟；
  - `OnClose`：清理网络轮询协程与注册的监听器。
- **视图组件**：
  - `view.text`：左下角显示的 UID 文本控件；
  - `view.pingNubTxt`：显示网络延迟数值的文本控件；
  - `view.pingCon`：延迟状态图标及色块容器。

---

## 2. 补丁注入契约

### 2.1 局部 Helper 注入
- 模组通过加载器机制向 `UIDPanelCtrl.lua` 注入轻量补丁函数。
- 注入逻辑独立包裹在局部闭包中，不污染全局 Lua 环境，不覆盖已有的原生字段或业务逻辑。

### 2.2 字段占位符解析
- 支持在格式串中自由组合 `{fps}`、`{ping}`、`{uid}`、`{time}`、`{vram}` 等动态变量。
- 网络延迟读取原生 `NetClientInst:GetPing()`，帧率由主循环时间步长平滑计算。
- 面板关闭或模组停用时，自动复原原始 UID 与延迟显示。
