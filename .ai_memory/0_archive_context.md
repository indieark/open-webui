# 归档上下文

## 2026-07-07 Open WebUI 私库兼容层迁移

起点：`indieark/open-webui` 原本是 Open WebUI 上游源码平铺在仓库根部，私库真实增量主要是根级 `docker-compose.yml`。测试环境已经部署在 `192.168.10.66:3000`，运行公共上游镜像 `ghcr.io/open-webui/open-webui:main`。

决策：采用类似 `gadget/CLIProxyAPI` 的结构，把官方上游独立放入 `upstream/open-webui/`，根目录保留 IndieArk 兼容层、部署入口、同步脚本、文档和计划。第一阶段不切私有镜像，因为当前运行面不是私有 runtime patch，而是 Portainer/Compose 兼容层。

执行：已在 `main` 上完成本地结构迁移，提交链包括计划、subtree add、根层兼容层重排、PowerShell 同步脚本修复和执行记录。测试环境未 redeploy、未重启、未切镜像。
