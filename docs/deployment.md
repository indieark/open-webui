# 部署

## 测试环境快照

只读核验日期：2026-07-07

| 项 | 当前值 |
| --- | --- |
| Host | `192.168.10.66` |
| Hostname | `vm-dev-01` |
| Portainer stack / Compose project | `open-webui` |
| Service | `open-webui` |
| Container | `open-webui` |
| Published port | `0.0.0.0:3000->8080/tcp`, `[::]:3000->8080/tcp` |
| Image | `ghcr.io/open-webui/open-webui:main` |
| Image id | `sha256:a26effeb220e132482bf7e0560b3404843e7bc40d23051144e062960df8df6b0` |
| Image revision / `WEBUI_BUILD_VERSION` | `ecd48e2f718220a6400ecf49eafd4867a38feb10` |
| Status | running, healthy |
| Volume | `open-webui_open-webui:/app/backend/data` |
| HTTP smoke | `http://127.0.0.1:3000/` returned `200` |

本次结构迁移不修改测试环境，不重启容器，不 pull 镜像，不改 Portainer stack。

## 稳定 Compose

根级 [docker-compose.yml](../docker-compose.yml) 是当前 Portainer 稳定入口，必须保持：

- service: `open-webui`
- container: `open-webui`
- image: `ghcr.io/open-webui/open-webui:main`
- ports: `3000:8080`
- volume: `open-webui:/app/backend/data`
- required env: `WEBUI_SECRET_KEY`
- Ollama: `OLLAMA_BASE_URL=http://host.docker.internal:11434`
- telemetry disabled: `SCARF_NO_ANALYTICS=true`, `DO_NOT_TRACK=true`, `ANONYMIZED_TELEMETRY=false`

配置验证：

```bash
WEBUI_SECRET_KEY=verify-placeholder docker compose config --quiet
```

## 本地构建

[docker-compose.local.yml](../docker-compose.local.yml) 是本地 override：

```bash
WEBUI_SECRET_KEY=local-dev docker compose -f docker-compose.yml -f docker-compose.local.yml config --quiet
```

第一阶段根级 `Dockerfile` 是薄包装，仍基于公共上游镜像。

## Web Search

当前 stable compose 未默认启用 Web Search。启用搜索至少要同时满足五个 gate：

1. 全局启用，例如 `ENABLE_WEB_SEARCH=true`。
2. 配置搜索引擎，例如 `WEB_SEARCH_ENGINE=searxng`。
3. 注入 provider URL 或 API key，不得提交真实 key。
4. 管理端给用户或角色打开对应权限。
5. 模型侧开启搜索 capability 或默认功能。

可选环境模板见 [../compat/config/web-search.env.example](../compat/config/web-search.env.example)。

OpenAI hosted `web_search` 不会因为模型本身支持就自动在 Open WebUI 生效。需要先确认 upstream 是否支持 Responses API hosted tool 透传；不支持时优先通过 pipe/function/adapter 承载，必须改 upstream 源码时先登记 subtree 例外。

## 部署确认门

以下操作必须用户明确确认：

- Portainer stack redeploy。
- `docker restart` / `docker compose up` / `docker compose down`。
- 切换到 `ghcr.io/indieark/open-webui:*`。
- 改 project 名、container 名、端口、volume 名或 `/app/backend/data` 挂载路径。

禁止执行：

```bash
docker compose down -v
docker volume rm open-webui_open-webui
```
