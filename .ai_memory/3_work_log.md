# 工作日志

## 2026-07-07

- 执行 Open WebUI 兼容层迁移：官方上游进入 `upstream/open-webui/`，根目录改为 IndieArk 兼容层。
- 增加同步脚本和兼容层验证脚本，Bash / PowerShell no-op 检查通过。
- 补齐 `00000-model` 项目模板风格的本地治理骨架。
- 修复 Portainer Git stack 的根层 compose：显式注入 `CHAT_STREAM_RESPONSE_CHUNK_MAX_BUFFER_SIZE` 和 `AIOHTTP_READ_BUFSIZE`，避免 Portainer 变量表只参与 `${VAR}` 替换但不进入容器 runtime env。
