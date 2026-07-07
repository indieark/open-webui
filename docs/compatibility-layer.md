# 兼容层

固定规则：所有私库改动优先放在根目录兼容层，尽量不修改 `upstream/open-webui/`。

## 当前兼容层索引

| 主题 | 位置 | 状态 |
| --- | --- | --- |
| Portainer stable compose | `docker-compose.yml` | 已启用，保持测试环境当前语义 |
| 本地构建 override | `docker-compose.local.yml` | 已提供 |
| 私有镜像薄包装 | `Dockerfile` | 已提供，仍基于公共上游镜像 |
| Web Search 环境模板 | `compat/config/web-search.env.example` | 已提供，不含 secret |
| 上游同步脚本 | `scripts/sync-upstream.sh`, `scripts/sync-upstream.ps1` | 已提供 |
| 兼容层验证 | `scripts/verify-compat.sh` | 已提供 |

## Subtree 例外

当前没有已登记的 `upstream/open-webui/` 本地补丁。

新增例外必须按此格式登记：

| 主题 | upstream 路径 | 原因 | 恢复规则 | 验证 |
| --- | --- | --- | --- | --- |
| 示例 | `upstream/open-webui/...` | 根层无法承载的最小原因 | 上游同步冲突时如何恢复 | 具体测试命令 |

登记后再改源码。未登记的 upstream subtree 修改应视为需要撤回或重新设计。

## 优先级

1. Compose/env/Portainer 配置。
2. `compat/` 下的 pipe/function/adapter 或 wrapper。
3. entrypoint 或 post-build patch。
4. 已登记的最小 upstream subtree 补丁。

Web Search 和 OpenAI hosted tool 适配也遵循该顺序。
