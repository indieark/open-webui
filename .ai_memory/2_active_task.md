# 当前任务

更新时间：2026-07-07

## 当前状态

- Open WebUI 私库兼容层结构迁移已完成，上游源码继续独立位于 `upstream/open-webui/`。
- Portainer compose 环境变量注入已完成：`CHAT_STREAM_RESPONSE_CHUNK_MAX_BUFFER_SIZE` 和 `AIOHTTP_READ_BUFSIZE` 已显式进入根层 `docker-compose.yml` 的 service `environment:`。
- 品牌化和自定义 UI 皮肤本地实现已完成：官方容器启动时生成 IndieArk 图标、manifest、`custom.css` 和 `loader.js`。
- `IndieArk Chat` 命名已统一，A 大写。
- CSS 已覆盖 4-qa-agent 风格明暗色调、dither 背景、暗色 surface、侧栏按钮、输入区按钮、工具/上传下拉菜单、浮动工具栏、右侧控制抽屉、滚动条和开关色调。
- 本轮只推送仓库变更；不自动 redeploy Portainer，不重启测试环境容器。

## 下一步

- 用户在 Portainer Stack `open-webui` 执行 Pull and redeploy。
- 部署后只读核验容器内 `/app/backend/open_webui/static/{custom.css,loader.js,manifest.json,favicon.png,splash.png,logo.png}`。
- 浏览器分别核验内网 `http://192.168.10.66:3000` 和外网 `https://chat.indieark.tech` 的标题、favicon、开屏图、左上品牌位、深色菜单/侧栏/悬浮栏/滚动条。

## 注意

- 不改 `upstream/open-webui/`。
- 不回到 static 单文件 bind mount 路线。
- 不提交 secret。
- Portainer redeploy、容器重启、镜像切换、volume/network 变更仍需用户明确确认。
