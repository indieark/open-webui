# 归档上下文

## 2026-07-07 Open WebUI 私库兼容层迁移

起点：`indieark/open-webui` 原本是 Open WebUI 上游源码平铺在仓库根部，私库真实增量主要是根级 `docker-compose.yml`。测试环境已经部署在 `192.168.10.66:3000`，运行公共上游镜像 `ghcr.io/open-webui/open-webui:main`。

决策：采用类似 `gadget/CLIProxyAPI` 的结构，把官方上游独立放入 `upstream/open-webui/`，根目录保留 IndieArk 兼容层、部署入口、同步脚本、文档和计划。第一阶段不切私有镜像，因为当前运行面不是私有 runtime patch，而是 Portainer/Compose 兼容层。

执行：已在 `main` 上完成本地结构迁移，提交链包括计划、subtree add、根层兼容层重排、PowerShell 同步脚本修复和执行记录。测试环境未 redeploy、未重启、未切镜像。

## 2026-07-07 Open WebUI 品牌化与部署层 CSS 收口

起点：用户要求不改上游源码、不改 Docker 本体，通过 compose 挂载或等价方式完成 IndieArk Chat 品牌化：左上品牌位、favicon/PWA/开屏图、网页标题、4-qa-agent 风格色调和 dither 背景。早期计划曾考虑 Portainer Git Stack bind mount `deploy/open-webui/static/*.png` 到容器 static 文件。

转折：测试环境实际部署时报 `not a directory`，原因是 Portainer stack 运行目录缺失 bind 源文件时 Docker 会把宿主机源路径创建为目录，导致目录被挂载到容器文件路径。最终否定单文件 static bind mount 路线。

最终决策：保持官方镜像 `ghcr.io/open-webui/open-webui:main` 和上游源码独立性，根层 `docker-compose.yml` 覆盖 command 但最后仍 `exec bash start.sh`。启动 bootstrap 用内联 Python/Pillow 在容器内部生成 `source-image.webp`、favicon、PWA 图标、splash、`manifest.json`、`custom.css` 和 `loader.js`；启动前写一次，等待 `/health` 后再写一次，覆盖上游启动清理 static 后的默认文件。

CSS 边界演变：最初只要求改色调和 dither，不动组件样式。用户后续截图指出暗色主题仍有大量默认灰色，包括右侧“对话高级设置”抽屉、侧栏按钮、浮动工具栏、滚动条、工具菜单和上传菜单。最终边界调整为：不改源码、不改 DOM、不改功能，但允许部署层 `custom.css` 覆盖颜色、surface、hover/selected、滚动条、开关和品牌 token。

当前实现事实：

- 维护入口：`deploy/open-webui/static/`。
- 同步入口：`docker-compose.yml` 内联 `CUSTOM_CSS`、`LOADER_JS`、`MANIFEST_JSON`。
- 品牌名统一为 `IndieArk Chat`。
- `loader.js` 替换运行时 `Open WebUI` 文本、标题和 meta，并为 `oled-dark` 加 `indieark-oled-dark`。
- `custom.css` 覆盖明暗主题 token、dither 背景、深色 Tailwind gray token、modal/dropdown/input/card surface、右侧控制抽屉、侧栏 hover/selected、输入区圆形按钮、富文本/选中文本浮动栏、工具/上传下拉菜单、`role="switch"` 开关和滚动条。
- 文档已同步到 README、docs、plans 和 `.ai_memory`。

验证链：`docker compose -f docker-compose.yml config`、内联 bootstrap Python compile、`node --check deploy/open-webui/static/loader.js`、`python -m json.tool deploy/open-webui/static/manifest.json`、`git diff --check`。

下一步：推送后由用户在 Portainer Stack `open-webui` 执行 Pull and redeploy。部署后只读核验容器内 static 文件和浏览器内外网 UI。不要自动 redeploy，不要重启容器，不要改 volume/network。
