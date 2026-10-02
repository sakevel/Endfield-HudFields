# 左下角信息 / Endfield-HudFields

适用于《明日方舟：终末地》的主界面 HUD 信息定制模组。支持独立控制左下角网络延迟与 UID 的显示，并支持自定义文本显示模板。

---

## 功能特性

- **独立可见性控制**：支持分别显示或隐藏网络延迟数值、信号图标以及底栏 UID。
- **自定义文本模板**：支持使用占位符自定义文字格式（如 `{ping}ms`、`UID: {uid}`），亦可填写固定文本（如 `UID: 已隐藏`）。
- **即时生效**：在模组菜单中修改后即时刷新主界面显示，无需重启游戏。

---

## 配置说明

在游戏内按 `ESC` →「模组菜单」→「左下角信息」→「模组配置」：

| 设置项 | 默认值 | 说明 |
|---|---|---|
| **显示网络延迟** | 开启 | 控制左下角延迟数值及网络信号图标的可见性 |
| **延迟显示文字** | `{ping}ms` | 格式模板，`{ping}` 会被替换为当前实际网络延迟 |
| **显示 UID** | 开启 | 控制左下角 UID 文字的可见性 |
| **UID 显示文字** | `UID: {uid}` | 格式模板，`{uid}` 会被替换为当前真实 UID |

---

## 构建与安装

### 构建

```powershell
.\tools\build.ps1
.\tools\package.ps1
```

构建产物位于 `build/package/Release/hud-fields`。

### 安装

退出游戏后，使用 ModLoader 的安装工具进行部署：

```powershell
..\Endfield-ModLoader\tools\install-mod.ps1 -ModPackage .\build\package\Release\hud-fields
```

个人配置保存在 `%LOCALAPPDATA%\ZML\mods\hud-fields\config.ini`。
