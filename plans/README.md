# 计划索引

这是 `gadget/open-webui/` 的计划与归档索引。新增、移动、废弃或归档计划文档时，必须同步更新本文件。

当前单一信息源：

- 当前仓库：`indieark/open-webui`
- 公共上游：`open-webui/open-webui`
- 迁移前私库基线：`3960faf1d6062cea99fe269f141cc41e1f284b0b`
- 当前公共上游 subtree split：`ecd48e2f718220a6400ecf49eafd4867a38feb10`

| 日期 | 计划 | 状态 | 说明 |
| --- | --- | --- | --- |
| 2026-07-07 | [Open WebUI 品牌化 Compose 挂载计划](2026-07-07-open-webui-branding-compose-mount-plan.md) | 本地实现完成，待部署核验 | 早期 compose 单文件 bind mount 已被测试环境 Portainer 实测否定，会因缺失源文件被 Docker 创建成目录而部署失败；当前改为不挂载 static 文件，由官方容器启动时生成图标、manifest、`custom.css` 和 `loader.js`。本地已实现左上品牌位“应用图标 + `IndieArk Chat`”、favicon/PWA/开屏图替换、`IndieArk Chat` 网页标题修正、4-qa-agent 风格色调、dither 背景、深色 surface/菜单/侧栏/悬浮栏/滚动条/开关收口。待 Portainer Pull and redeploy 后做运行时核验。 |
| 2026-07-07 | [Open WebUI 全局自定义 CSS 注入计划](2026-07-07-open-webui-global-custom-css-plan.md) | 已并入品牌化计划 | 已确认 Open WebUI 当前会加载 `/static/custom.css`，测试容器真实 `STATIC_DIR` 为 `/app/backend/open_webui/static`；早期 `deploy/open-webui/custom.css` 路线已收敛到 `deploy/open-webui/static/custom.css`，并由品牌化计划统一执行。 |
| 2026-07-07 | [Open WebUI 兼容层与上游独立更新迁移计划](2026-07-07-open-webui-compat-layer-migration.md) | 结构迁移已执行 | 已将当前平铺 fork 改造为类似 `CLIProxyAPI` 的结构：上游源码独立跟踪在 `upstream/open-webui/`，根目录承载 IndieArk 兼容层、部署、同步脚本、文档与验证规则；本地验证和同步 no-op 已通过；已补齐 `00000-model/02-项目模板` 风格基础骨架；未改测试环境 Portainer stack，未重启容器，未切私有镜像。 |
