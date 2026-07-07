# AGENTS.md

你是在 `gadget/open-webui` 内协作的编码代理。默认使用简体中文。

## 仓库边界

- `upstream/open-webui/` 是官方 `open-webui/open-webui` subtree，默认不直接改。
- 根目录、`compat/`、`scripts/`、`docs/`、`plans/` 是 IndieArk 私库兼容层。
- 能通过 Compose、环境变量、entrypoint、脚本、post-build patch、Open WebUI pipe/function 或 adapter 解决的问题，不进入 upstream subtree。
- 必须修改 upstream subtree 时，先在 `docs/compatibility-layer.md` 登记例外，写清原因、文件、恢复规则和验证命令。

## 部署约束

- 测试环境是 `192.168.10.66:3000`，Portainer stack / Compose project 为 `open-webui`。
- 服务名和容器名保持 `open-webui`。
- 数据卷保持 `open-webui:/app/backend/data`，测试机实际 Docker volume 为 `open-webui_open-webui`。
- 第一阶段稳定入口继续使用 `ghcr.io/open-webui/open-webui:main`。
- `WEBUI_SECRET_KEY`、搜索 provider key、OpenAI key、Portainer credential 不得写入仓库。
- 不得执行会影响测试环境的重启、redeploy、volume/network 改动，除非用户明确确认。

## 常用验证

```bash
WEBUI_SECRET_KEY=verify-placeholder docker compose config --quiet
bash scripts/verify-compat.sh
bash scripts/sync-upstream.sh
```

Windows 原生命令环境可用：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-upstream.ps1
```

## 计划与文档

- 新计划放在 `plans/`，并同步更新 `plans/README.md`。
- 当前部署事实以 `docs/deployment.md` 为准。
- 上游同步规则以 `UPSTREAMS.md` 和 `docs/repository-maintenance.md` 为准。
