# Open WebUI 全局自定义 CSS 注入计划

## 执行状态

已并入 [Open WebUI 品牌化 Compose 挂载计划](2026-07-07-open-webui-branding-compose-mount-plan.md) 执行。最终落点从本计划早期建议的 `deploy/open-webui/custom.css` 收敛为 `deploy/open-webui/static/custom.css`，并通过单文件只读挂载覆盖 `/app/backend/open_webui/static/custom.css`；同时补充了 `loader.js`、PWA manifest 和图标 / splash 资源挂载。

## 结论

可行，但当前镜像的稳妥挂载目标不是 `/app/build/static/custom.css`，而是 `/app/backend/open_webui/static/custom.css`。

依据：

- `upstream/open-webui/src/app.html` 已内置加载：`<link rel="stylesheet" href="/static/custom.css" crossorigin="use-credentials" />`。
- `upstream/open-webui/backend/open_webui/main.py` 将 `/static` 挂载到后端 `STATIC_DIR`。
- 测试容器只读核验：`STATIC_DIR=/app/backend/open_webui/static`，当前 `/app/backend/open_webui/static/custom.css` 存在但为空文件。

因此只要把我们维护的 `custom.css` 挂载到容器内该路径，所有用户都会加载同一份全局样式。

## 目标

在不修改上游源码、不自建私有镜像的前提下，通过根层部署兼容配置让测试环境和后续部署统一加载 IndieArk 全局 UI 样式。

## 不变量

- 保持 `upstream/open-webui/` 独立，不改上游源码。
- 保持官方镜像 `ghcr.io/open-webui/open-webui:main`，不引入私有兼容镜像。
- CSS 文件作为 IndieArk 根层部署资产管理，可被 GitOps/Portainer redeploy 保留。
- 所有用户共享同一份全局样式。
- 样式失败不能影响 Open WebUI 启动；最坏情况应退回默认 UI。

## 推荐结构

新增根层文件：

```text
deploy/
  open-webui/
    custom.css
```

修改根层 `docker-compose.yml`：

```yaml
services:
  open-webui:
    volumes:
      - open-webui:/app/backend/data
      - ./deploy/open-webui/custom.css:/app/backend/open_webui/static/custom.css:ro
```

说明：

- 使用相对路径是为了让 Portainer Git Stack 从仓库部署时能拿到同仓文件。
- 如果 Portainer 对相对 bind mount 的解析不符合预期，再切换为测试机绝对路径，例如 `/opt/indieark/open-webui/custom.css:/app/backend/open_webui/static/custom.css:ro`，但这会增加主机侧资产管理成本。

## CSS 初版建议

先放最小、低风险版本，不要大面积覆盖结构类名：

```css
:root {
  --indieark-primary: #00d4ff;
  --indieark-accent: #00ff9d;
}

#send-message-button {
  background-color: var(--indieark-primary) !important;
  color: #000 !important;
}

textarea,
input[type="text"] {
  background-color: #1a1a2e !important;
}
```

注意：

- `#send-message-button` 等选择器要以当前前端实际 DOM 为准。若上游改类名或 id，样式可能失效。
- 避免一开始覆盖大量 Tailwind 动态类，否则后续上游 UI 更新时更容易冲突。
- `message-bubble` 这类类名必须先确认真实存在，不存在则不会生效。

## 执行步骤

1. 创建 `deploy/open-webui/custom.css`。
2. 将 `docker-compose.yml` 的 `open-webui.volumes` 增加 CSS 只读挂载。
3. 本地校验 compose：

   ```bash
   docker compose -f docker-compose.yml config
   ```

4. 提交并推送到 `origin/main`。
5. 在 Portainer Stack `open-webui` 执行 Pull and redeploy。
6. 测试机只读核验：

   ```bash
   docker exec open-webui sh -lc 'ls -l /app/backend/open_webui/static/custom.css && head -n 20 /app/backend/open_webui/static/custom.css'
   curl -I http://127.0.0.1:3000/static/custom.css
   ```

7. 浏览器打开 `http://192.168.10.66:3000/static/custom.css` 或登录 UI 后检查样式。

## 验证标准

- `docker compose config` 通过。
- 容器内 `/app/backend/open_webui/static/custom.css` 内容等于仓库文件。
- `/static/custom.css` HTTP 返回 200，`Content-Type` 为 CSS 或可被浏览器识别。
- UI 中至少一个低风险样式生效，例如发送按钮颜色。
- 容器保持 healthy，`3000` 端口正常。

## 回滚

最小回滚：

1. 将 `deploy/open-webui/custom.css` 清空或移除高风险规则。
2. 推送并 Portainer redeploy。

完整回滚：

1. 移除 `docker-compose.yml` 中的 CSS bind mount。
2. 推送并 Portainer redeploy。

## 风险

- Portainer Git Stack 对相对 bind mount 的工作目录解析可能和本地 Docker Compose 不一致，需要部署后核验。
- 上游 DOM 结构和类名可能变化，CSS 选择器需要随版本维护。
- 外网 Cloudflare Access 不影响 CSS 本身加载，只要用户已通过 Access 并能访问主页面，`/static/custom.css` 会同域加载。
