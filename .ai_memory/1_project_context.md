# 项目核心知识库

## 项目目标

`gadget/open-webui` 是 IndieArk 的 Open WebUI 私库兼容层。目标是在保留私库部署设计的同时，让官方 `open-webui/open-webui` 上游源码可以独立同步和更新。

## 当前结构

- 官方上游 subtree：`upstream/open-webui/`
- 根级兼容层：`README.md`、`AGENT.md`、`AGENTS.md`、`UPSTREAMS.md`、`docs/`、`plans/`、`compat/`、`scripts/`、`docker-compose.yml`
- 部署层静态资产：`deploy/open-webui/static/`
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

## 品牌与部署层 UI

- IndieArk 品牌化不改 `upstream/open-webui/`，不构建私有镜像。
- 根级 `docker-compose.yml` 使用启动 bootstrap 在官方容器内部生成 static 资源：`custom.css`、`loader.js`、manifest、favicon、PWA 图标和 splash 图。
- `deploy/open-webui/static/` 是品牌资源和 CSS/JS 的维护入口；修改后必须同步 `docker-compose.yml` 的内联常量。
- `custom.css` 保留 Open WebUI 页面内容、组件结构和交互功能，只覆盖 IndieArk 色调、dither 背景、暗色 surface、侧栏/菜单/悬浮栏/滚动条/开关等视觉 token。
- `loader.js` 负责把 `Open WebUI` 运行时品牌文本、标题和 meta 替换为 `IndieArk Chat`，并给 `oled-dark` 主题补充 `indieark-oled-dark` class。
- 不能回到 Portainer static 单文件 bind mount 路线；缺失 bind 源会被 Docker 创建成目录，导致文件挂载报 `not a directory`。

## 不变量

- 默认不直接修改 `upstream/open-webui/`。
- 上游同步必须 compare-first；无 delta 时 no-op。
- 根级 `docker-compose.yml` 必须保持当前测试环境部署语义。
- `WEBUI_SECRET_KEY` 和搜索 provider key 不入库。
- 测试环境写操作必须另行确认。
- `docs/deployment.md` 是部署事实源，`UPSTREAMS.md` 是上游同步事实源，`docs/compatibility-layer.md` 是本地补丁事实源。
- 品牌和全局 UI 皮肤事实源是 `plans/2026-07-07-open-webui-branding-compose-mount-plan.md`，维护入口是 `deploy/open-webui/static/`。
