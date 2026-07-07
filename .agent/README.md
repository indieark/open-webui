# `.agent/` — AI 系统提示词与规则

本目录按 `00000-model/02-项目模板` 的项目骨架保留，用于存放项目级 AI 行为规则。

## 目录结构

```text
.agent/
└── rules/
    ├── dev.md
    ├── roop.md
    └── open-webui-compat.md
```

## 规则格式

```markdown
---
trigger: always_on
description: "规则说明"
---

# 规则标题

规则内容...
```

不支持自动加载 `.agent/rules/` 的 AI 工具，应以根目录 [AGENTS.md](../AGENTS.md) 和 [AGENT.md](../AGENT.md) 为准。
