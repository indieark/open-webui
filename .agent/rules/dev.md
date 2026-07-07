---
trigger: always_on
description: "Open WebUI 私库的基础开发规则"
---

# 基础开发规则

- 默认使用简体中文沟通和写文档，代码标识符、命令、外部专名保持英文。
- 修改前先确认当前工作树状态，避免混入无关改动。
- 默认不直接修改 `upstream/open-webui/`；需要修改时先在 `docs/compatibility-layer.md` 登记 subtree 例外。
- 能通过 Compose、环境变量、`compat/`、脚本、pipe/function/adapter 承载的问题，优先留在根级兼容层。
- 不提交 secret、token、key、Portainer credential 或真实 provider key。
- 非平凡结构或部署改动先写 `plans/`，并同步 `plans/README.md`。
- 不读取 `MEMO.md`。
