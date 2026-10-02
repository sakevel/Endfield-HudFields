# Public SDK snapshot

`include/zml_plugin.h` 是 ZML 的公开 C ABI1 快照。

升级时人工比较新头文件/ABI，更新快照并重新跑 DLL/配置集成测试。Lua API 使用 ZML/Api 的 api_version=1、get、subscribe、report。
