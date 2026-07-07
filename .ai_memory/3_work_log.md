# 工作日志

## 2026-07-07

- 执行 Open WebUI 兼容层迁移：官方上游进入 `upstream/open-webui/`，根目录改为 IndieArk 兼容层。
- 增加同步脚本和兼容层验证脚本，Bash / PowerShell no-op 检查通过。
- 补齐 `00000-model` 项目模板风格的本地治理骨架。
- 修复 Portainer Git stack 的根层 compose：显式注入 `CHAT_STREAM_RESPONSE_CHUNK_MAX_BUFFER_SIZE` 和 `AIOHTTP_READ_BUFSIZE`，避免 Portainer 变量表只参与 `${VAR}` 替换但不进入容器 runtime env。
- 完成 Open WebUI 品牌化部署层实现：不挂载 static 文件，不改上游源码，改为官方容器启动时生成 IndieArk 图标、manifest、`custom.css` 和 `loader.js`。
- 按用户截图反馈收口深色 UI 灰面：覆盖右侧控制抽屉、侧栏按钮、输入区按钮、工具/上传下拉菜单、富文本/选中文本悬浮栏、滚动条和开关色调。
- 同步 README、docs、plans 和 `.ai_memory`，保持品牌化 bootstrap、部署约束和后续 Portainer redeploy 核验口径一致。
