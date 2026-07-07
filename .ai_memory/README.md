# `.ai_memory/` — AI 长期记忆系统

本目录按 `00000-model/02-项目模板` 的项目骨架保留，用于记录本仓库的跨会话事实和执行状态。

| 文件 | 写入模式 | 用途 |
| --- | --- | --- |
| `0_archive_context.md` | 追加 | 记录方案变化、迁移原因和关键推理 |
| `1_project_context.md` | 只读为主 | 记录已确认的架构事实和不变量 |
| `2_active_task.md` | 覆写 | 记录当前任务进度和下一步 |
| `3_work_log.md` | 追加 | 记录每日简要变更流水 |

更新记忆时，同步检查 `README.md`、`AGENT.md` / `AGENTS.md`、`docs/README.md` 和 `plans/README.md` 的口径是否一致。
