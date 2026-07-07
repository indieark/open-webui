# AI 协作入口

本文件是 `gadget/open-webui` 的 AI 协作入口，按 `00000-model/02-项目模板` 的本地项目骨架保留。通用协作规则同时维护在 [AGENTS.md](AGENTS.md)，两者口径必须保持一致。

## 项目定位

本仓库是 IndieArk 的 Open WebUI 私库兼容层：

- 官方上游源码独立放在 `upstream/open-webui/`。
- 根目录承载 IndieArk 兼容层、部署入口、同步脚本、文档和计划。
- 当前测试环境仍使用公共上游镜像 `ghcr.io/open-webui/open-webui:main`，不是私有 runtime 镜像。

## 启动流程

1. 读取 `.ai_memory/1_project_context.md`，确认长期事实和不变量。
2. 读取 `.ai_memory/2_active_task.md`，确认当前任务状态。
3. 读取 `.ai_memory/0_archive_context.md` 的最后 50 行，了解最近迁移脉络。
4. 阅读 [UPSTREAMS.md](UPSTREAMS.md) 和 [docs/deployment.md](docs/deployment.md)，再处理上游同步或部署问题。

## 目录与权限

| 目录/文件 | 用途 | 规则 |
| --- | --- | --- |
| `upstream/open-webui/` | 官方上游 subtree | 默认只通过同步脚本更新 |
| `compat/` | IndieArk 兼容层 | 优先放私库配置、pipe/function/adapter、补丁入口 |
| `docs/` | 当前事实文档 | 部署和维护口径以这里为准 |
| `plans/` | 计划和执行记录 | 新增计划必须同步 `plans/README.md` |
| `.agent/rules/` | AI 行为规则 | 与 `AGENTS.md` 保持一致 |
| `.ai_memory/` | 跨会话记忆 | 结构性变更后同步更新 |
| `.exp/` | 可复用经验沉淀 | 需要提炼经验时再扩展 |
| `.ui/` | UI 风格入口 | 如未来做前端定制，再引用共享 UI 规范 |
| `MEMO.md` | 人类私人笔记 | AI 不读取、不引用 |

## 关键不变量

- 测试环境 `192.168.10.66:3000` 不因仓库结构迁移自动变化。
- Compose project、service、container 均保持 `open-webui`。
- 数据卷保持 `open-webui:/app/backend/data`，测试机实际 volume 为 `open-webui_open-webui`。
- 上游同步必须 compare-first；无 delta 时 no-op。
- 测试环境 Portainer 写操作、容器重启、镜像切换必须用户另行确认。
