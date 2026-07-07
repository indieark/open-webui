# 当前任务

更新时间：2026-07-07

## 当前状态

- 已完成 Open WebUI 私库兼容层结构迁移。
- 已补齐 `00000-model/02-项目模板` 风格的本地治理骨架：`AGENT.md`、`.agent/`、`.ai_memory/`、`.exp/`、`.ui/`、`MEMO.md`。
- 正在修复测试环境 Portainer compose 部署层环境变量注入：`CHAT_STREAM_RESPONSE_CHUNK_MAX_BUFFER_SIZE` 和 `AIOHTTP_READ_BUFSIZE` 必须显式写入根层 `docker-compose.yml` 的 service `environment:`。
- 本地 `main` 领先 `origin/main`，待提交并 push。

## 下一步

- 运行 `git diff --check`、`bash scripts/verify-compat.sh`、两个 sync no-op 检查。
- 提交 compose 部署层修复并 push。
- Portainer Git stack 需要拉取并重新部署后，两个变量才会进入运行中容器。

## 注意

不要自动 redeploy 测试环境。Portainer stack、容器重启、镜像切换仍需用户明确确认。
