# 测试与验证指南

本文档介绍 Endfield-HudFields（左下角信息模组）的自动化测试套件与功能验证方法。

---

## 自动化测试

项目包含 Native C++ 合约测试与 Python / Lua 模板格式化测试：

```powershell
ctest --test-dir build -C Release --output-on-failure
```

### 测试套件说明

- **PatchTests (`tests/patch_tests.cpp`)**：
  - 验证对原生 `UI/Panels/UID/UIDPanel` 脚本的修补锚点唯一性与注入逻辑。
  - 验证重入、异常回滚与源码语法正确性。

- **PluginTests (`tests/plugin_tests.cpp`)**：
  - 验证 Native 插件导出符号 `ZML_PluginV1`。
  - 验证清单加载与内部事件订阅机制。

- **LuaTests (`tests/lua_tests.py` / `tests/display_mock.lua`)**：
  - 验证 `{ping}` 与 `{uid}` 占位符的格式化替换逻辑。
  - 验证包含特殊字符、超长文本、空字符串时的边界安全。
  - 测试隐藏延迟与隐藏 UID 状态下的原生控件可见性切换。

---

## 实机功能验证清单

在游戏主场景中进行以下测试：

1. **可见性切换**：
   - 在模组设置中关闭「显示网络延迟」，确认主界面左下角的延迟文字与信号图标同时隐藏。
   - 关闭「显示 UID」，确认左下角的 UID 文字隐藏。

2. **模板自定义**：
   - 修改延迟文字模板（例如改为 `{ping} 毫秒`），确认主界面即时更新。
   - 修改 UID 文字模板（例如改为 `UID: 已隐藏`），确认主界面即时呈现对应文本。
