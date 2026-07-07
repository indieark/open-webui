# 项目核心知识库

## 项目目标

`gadget/open-webui` 是 IndieArk 的 Open WebUI 私库兼容层。目标是在保留私库部署设计的同时，让官方 `open-webui/open-webui` 上游源码可以独立同步和更新。

## 当前结构

- 官方上游 subtree：`upstream/open-webui/`
- 根级兼容层：`README.md`、`AGENT.md`、`AGENTS.md`、`UPSTREAMS.md`、`docs/`、`plans/`、`compat/`、`scripts/`、`docker-compose.yml`
- 当前官方上游 split：`ecd48e2f718220a6400ecf49eafd4867a38feb10`
- 上游 remote：`upstream-open-webui=https://github.com/open-webui/open-webui.git`

## 部署事实

测试环境只读核验事实：

- Host：`192.168.10.66`
- Compose project / stack：`open-webui`
- Service / container：`open-webui`
- Published port：`3000:8080`
- Stable image：`ghcr.io/open-webui/open-webui:main`
- Data volume：`open-webui_open-webui:/app/backend/data`
- 迁移执行期间未修改 Portainer stack、未重启容器、未切私有镜像。

## 不变量

- 默认不直接修改 `upstream/open-webui/`。
- 上游同步必须 compare-first；无 delta 时 no-op。
- 根级 `docker-compose.yml` 必须保持当前测试环境部署语义。
- `WEBUI_SECRET_KEY` 和搜索 provider key 不入库。
- 测试环境写操作必须另行确认。
- `docs/deployment.md` 是部署事实源，`UPSTREAMS.md` 是上游同步事实源，`docs/compatibility-layer.md` 是本地补丁事实源。
