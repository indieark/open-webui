---
trigger: always_on
description: "AI 记忆系统与归档协议"
---

# 记忆持久化协议

## 记忆目录

`.ai_memory/` 保存本仓库跨会话上下文。

| 文件 | 写入模式 | 职责 |
| --- | --- | --- |
| `0_archive_context.md` | 追加 | 思维复盘和方案演变 |
| `1_project_context.md` | 只读为主 | 已确认的架构事实、不变量和长期约束 |
| `2_active_task.md` | 覆写 | 当前任务快照 |
| `3_work_log.md` | 追加 | 开发流水账 |

## 新会话启动

1. 读取 `1_project_context.md`。
2. 读取 `2_active_task.md`。
3. 读取 `0_archive_context.md` 最后 50 行。
4. 再结合 `README.md`、`UPSTREAMS.md`、`docs/README.md` 判断当前任务。

## 归档触发

用户说“总结归档”“归档总结”“Archive Context”“Compress History”时，按上述四文件职责更新记忆，并同步相关 README / plans / docs 索引。
