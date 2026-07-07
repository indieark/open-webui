# 计划索引

这是 `gadget/open-webui/` 的计划与归档索引。新增、移动、废弃或归档计划文档时，必须同步更新本文件。

当前单一信息源：

- 当前仓库：`indieark/open-webui`
- 公共上游：`open-webui/open-webui`
- 当前本地基线：`3960faf1d6062cea99fe269f141cc41e1f284b0b`
- 当前公共上游基线：`ecd48e2f718220a6400ecf49eafd4867a38feb10`

| 日期 | 计划 | 状态 | 说明 |
| --- | --- | --- | --- |
| 2026-07-07 | [Open WebUI 兼容层与上游独立更新迁移计划](2026-07-07-open-webui-compat-layer-migration.md) | 可执行计划 | 将当前平铺 fork 改造为类似 `CLIProxyAPI` 的结构：上游源码独立跟踪，根目录承载 IndieArk 兼容层、部署、同步脚本、文档与验证规则；已补入测试环境 `192.168.10.66:3000` 运行中约束、执行 runbook、停止条件、subtree 基线判断、文件清单和验收门；当前仍只规划，不改源码、不动测试环境。 |
