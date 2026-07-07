# IndieArk Open WebUI

这是 IndieArk 的 Open WebUI 私库兼容层。公共上游源码独立放在 `upstream/open-webui/`，根目录只承载 IndieArk 的部署入口、兼容层、同步脚本、计划和维护文档。

当前测试环境运行面保持不变：

- Host: `192.168.10.66`
- Portainer stack / Compose project: `open-webui`
- Container: `open-webui`
- Published port: `3000:8080`
- Image: `ghcr.io/open-webui/open-webui:main`
- Data volume: `open-webui_open-webui:/app/backend/data`

## 目录

```text
.
├── upstream/open-webui/     # 官方 open-webui/open-webui subtree
├── compat/                  # IndieArk 兼容层配置和未来补丁入口
├── docs/                    # 当前私库文档
├── scripts/                 # 上游同步和兼容层验证脚本
├── plans/                   # 计划和归档
├── .agent/                  # 00000-model 风格的 AI 规则骨架
├── .ai_memory/              # 跨会话项目记忆
├── .exp/                    # 可复用经验沉淀入口
├── .ui/                     # UI 风格入口
├── AGENT.md                 # AI 协作入口，兼容 00000-model 模板
├── AGENTS.md                # Codex/多工具协作入口
├── docker-compose.yml       # 测试环境/Portainer 稳定入口
├── docker-compose.local.yml # 本地构建 override
├── Dockerfile               # 私有镜像薄包装入口
└── UPSTREAMS.md             # 上游同步单一入口
```

## 快速验证

```bash
WEBUI_SECRET_KEY=verify-placeholder docker compose config --quiet
bash scripts/verify-compat.sh
```

## 维护规则

- 默认不要直接修改 `upstream/open-webui/`。
- 能通过 Compose、环境变量、entrypoint、脚本、pipe/function 或根层 wrapper 解决的问题，必须留在根层兼容层。
- 必须修改上游源码时，先在 `docs/compatibility-layer.md` 登记 subtree 例外，再做最小补丁和回归验证。
- 上游同步必须 compare-first；无真实 upstream delta 时 no-op，不构建、不提交、不推送。
- 测试环境 Portainer stack 变更、镜像切换、重建或容器重启必须另行确认。

文档入口见 [docs/README.md](docs/README.md)。上游同步入口见 [UPSTREAMS.md](UPSTREAMS.md)。

本仓库也保留了 `00000-model/02-项目模板` 的基础治理结构：`.agent/`、`.ai_memory/`、`.exp/`、`.ui/`、`AGENT.md` 和 `MEMO.md`。这些文件只承载本仓当前事实和协作规则，不复制共享资产库的业务内容。
