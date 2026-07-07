# Open WebUI 品牌化 Compose 挂载计划

## 执行状态

本地部署层改造已完成：已新增 `deploy/open-webui/static/` 静态资源、`custom.css`、`loader.js`、`manifest.json`，并在根层 `docker-compose.yml` 追加单文件只读挂载和 `EXTERNAL_PWA_MANIFEST_URL`。已通过本地 compose 渲染、静态资源尺寸、manifest JSON、`loader.js` 语法和 `git diff --check` 校验；测试环境仍需 Portainer Pull and redeploy 后做运行时核验。

## 结论

可以在不修改上游源码、不自建镜像、不改官方镜像本体的前提下完成大部分品牌化要求。执行边界是：只在私库根层维护静态资源和 compose bind mount，由 Portainer Git Stack 重新部署后生效。

本计划覆盖：

- 左上品牌位显示应用图标 + `Indieark Chat`；桌面端优先复用 Open WebUI 侧边栏顶部原生结构，移动端聊天栏提供同样结构的 CSS 兜底。
- 浏览器 favicon、PWA 图标、登录/侧边栏默认图标使用 `C:\Users\Windows\Downloads\image.webp` 派生资源。
- 开屏图标 `splash.png` / `splash-dark.png` 使用同一张 `image.webp` 派生资源。
- 网页标题显示为 `Indieark Chat`，不使用会追加 ` (Open WebUI)` 的 `WEBUI_NAME` 环境变量路线。
- CSS 仅调整全局色调和 dither 背景层，不重写页面内容和组件样式。

## 不变量

- 不改 `upstream/open-webui/`。
- 不写 Dockerfile，不构建私有镜像，继续使用 `ghcr.io/open-webui/open-webui:main`。
- 只改根层部署资产和 `docker-compose.yml`。
- 静态资源必须进入 Git 仓库；不能依赖 `C:\Users\Windows\Downloads\image.webp` 这种本机临时路径供测试环境部署。
- 不挂载整个 `/app/backend/open_webui/static` 目录，只挂载需要覆盖的单个文件，避免覆盖上游自带静态资源。
- 失败回滚应只需要移除 bind mount 或恢复静态资产，不影响 Open WebUI 数据卷。

## 当前事实依据

- 上游 `app.html` 已加载 `/static/custom.css` 和 `/static/loader.js`。
- 测试容器只读核验过 `STATIC_DIR=/app/backend/open_webui/static`，当前 `custom.css` 存在但为空。
- 上游启动时会清理并重拷贝 `STATIC_DIR`，所以挂载整个 static 目录风险高；单文件 bind mount 更稳。
- 当前上游 `WEBUI_NAME=Indieark Chat` 会被 `env.py` 改成 `Indieark Chat (Open WebUI)`，不满足“网页名字改成 Indieark Chat”的精确要求。
- PWA `/manifest.json` 由后端动态生成；本次不使用 `WEBUI_NAME`，改用上游已支持的 `EXTERNAL_PWA_MANIFEST_URL` 指向容器内静态 `/static/manifest.json`。
- 当前上游静态目录包含这些品牌相关入口：`favicon.png`、`favicon-96x96.png`、`favicon.svg`、`favicon.ico`、`favicon-dark.png`、`apple-touch-icon.png`、`splash.png`、`splash-dark.png`、`logo.png`、`web-app-manifest-192x192.png`、`web-app-manifest-512x512.png`。
- `4-qa-agent` 的可复用视觉边界是“只改皮肤，不改内容 / 布局 / 导航 / 按钮 / 字段 / 功能”；本次 Open WebUI CSS 也沿用这个边界。
- `4-qa-agent` 色调真源来自 Steam_UI token，并且必须同时覆盖暗色与亮色：
  - 暗色：深蓝黑底 `#0b0f19` / `#171a21` / `#1b2838`，主行动色 `#66c0f4`，辅助文字 `#c7d5e0`，低频绿色 accent `#4c6b22`。
  - 亮色：亮白玻璃底 `#f8f9fa` / `#ffffff` / `rgba(255,255,255,0.82)`，主行动色 `#4facfe`，文字 `#2a2925` / `#5f5c55`，弱阴影与弱 glow。
- `4-qa-agent` dither 真源是 `AgentDitherBackground.tsx` 的 WebGL/Three shader：蓝色波纹、Bayer dither、低透明度背景层。Open WebUI 不改源码时不能直接复用 React/Three 组件，只能在 `custom.css` 中做静态/轻动画 CSS 背景近似。
- `4-qa-agent` 的亮色 dither 并没有直接关闭，而是降低透明度、切换 `mix-blend-mode: multiply`、降低饱和度，并叠加白色遮罩来保证可读性；Open WebUI 计划也应采用双主题 dither，而不是只做暗色。
- Open WebUI 当前主题由 `<html>` 上的 `dark` / `light` / `oled-dark` 类控制；`custom.css` 需要分别处理 `.dark`、`.light`，并让 `oled-dark` 继承暗色策略。

## 推荐目录结构

新增根层部署资产：

```text
deploy/
  open-webui/
    static/
      custom.css
      loader.js
      manifest.json
      favicon.png
      favicon-96x96.png
      favicon.svg
      favicon.ico
      favicon-dark.png
      apple-touch-icon.png
      splash.png
      splash-dark.png
      logo.png
      web-app-manifest-192x192.png
      web-app-manifest-512x512.png
      source-image.webp
```

来源规则：

- `source-image.webp` 复制自 `C:\Users\Windows\Downloads\image.webp`，作为 favicon、PWA 图标、开屏图的单一来源。
- `brand-indieark-logo-charcoal.svg` 和 `brand-indieark-logo-white.svg` 可复制自 `C:\Vibe_Coding\IndieArk\00000-model\01-复用资产\assets\INDIEARK Text Logo\` 作为备用品牌素材；本次最终执行不把 SVG 挂载进容器，左上品牌位使用 `source-image.webp` 派生的图标 + `Indieark Chat` 文本。

## Compose 挂载

在 `docker-compose.yml` 的 `open-webui.volumes` 保留数据卷，并追加单文件只读挂载：

```yaml
services:
  open-webui:
    volumes:
      - open-webui:/app/backend/data
      - ./deploy/open-webui/static/custom.css:/app/backend/open_webui/static/custom.css:ro
      - ./deploy/open-webui/static/loader.js:/app/backend/open_webui/static/loader.js:ro
      - ./deploy/open-webui/static/manifest.json:/app/backend/open_webui/static/manifest.json:ro
      - ./deploy/open-webui/static/favicon.png:/app/backend/open_webui/static/favicon.png:ro
      - ./deploy/open-webui/static/favicon-96x96.png:/app/backend/open_webui/static/favicon-96x96.png:ro
      - ./deploy/open-webui/static/favicon.svg:/app/backend/open_webui/static/favicon.svg:ro
      - ./deploy/open-webui/static/favicon.ico:/app/backend/open_webui/static/favicon.ico:ro
      - ./deploy/open-webui/static/favicon-dark.png:/app/backend/open_webui/static/favicon-dark.png:ro
      - ./deploy/open-webui/static/apple-touch-icon.png:/app/backend/open_webui/static/apple-touch-icon.png:ro
      - ./deploy/open-webui/static/splash.png:/app/backend/open_webui/static/splash.png:ro
      - ./deploy/open-webui/static/splash-dark.png:/app/backend/open_webui/static/splash-dark.png:ro
      - ./deploy/open-webui/static/logo.png:/app/backend/open_webui/static/logo.png:ro
      - ./deploy/open-webui/static/web-app-manifest-192x192.png:/app/backend/open_webui/static/web-app-manifest-192x192.png:ro
      - ./deploy/open-webui/static/web-app-manifest-512x512.png:/app/backend/open_webui/static/web-app-manifest-512x512.png:ro
```

说明：

- 相对路径适配 Portainer Git Stack 从仓库目录部署。
- 如果 Portainer 对相对 bind mount 的解析异常，再评估测试机绝对路径，但优先不要引入宿主机外部资产目录。

## 左上品牌位方案

优先复用 Open WebUI 侧边栏顶部原生 `favicon + WEBUI_NAME` 结构，不改 Svelte 源码。

策略：

- 左侧图标使用 `source-image.webp` 派生的 `favicon.png`，保持和 favicon / PWA / splash 同源。
- `loader.js` 把运行时品牌文本从 `Open WebUI` 替换为 `Indieark Chat`，避免使用会追加 ` (Open WebUI)` 的 `WEBUI_NAME` 环境变量。
- `custom.css` 只对侧边栏品牌图标做尺寸、圆角和轻微 glow 处理，符合截图中的“图标 + 名称”结构。
- 移动端聊天栏在侧边栏不可见时，用 CSS `::before` / `::after` 兜底显示小图标 + `Indieark Chat`；窄屏降级为 `Chat`，避免挤压模型选择器和右侧按钮。
- 如果后续上游 DOM 结构变动导致选择器失效，只更新 `custom.css` / `loader.js`，不碰上游源码。

执行前需要用浏览器或 DOM 截图确认选择器命中当前品牌位，避免影响设置页导航或模型选择器。

## CSS 色调与 Dither 边界

用户本轮明确收窄 CSS 范围：只改色调，加 dither 背景。不要借此重写 Open WebUI 的页面内容、组件结构或组件样式。

允许改：

- `html` / `body` / 顶层 app 容器的背景色、背景图层和基础颜色变量。
- 全局品牌 token，例如 `--indieark-bg-base`、`--indieark-bg-deep`、`--indieark-primary`、`--indieark-text-secondary`。
- 页面最外层 dither 背景层，例如 `body::before` 或等价 fixed pseudo layer。
- 只为让 dither 可见而调整最外层 route/shell 背景的透明度；调整必须限定在外层背景，不碰消息气泡、输入框、按钮、卡片、模型选择器、菜单、弹窗等具体组件。

禁止改：

- 不改消息气泡圆角、边框、阴影、padding、字体大小和布局。
- 不改输入框、发送按钮、模型选择器、侧边栏条目、菜单、modal 的组件样式。
- 不把 Open WebUI 改成 4-qa-agent 的完整 Steam_UI 组件库。
- 不引入 React/Three/WebGL 运行时代码来复刻 `AgentDitherBackground.tsx`。

色调目标分为暗色和亮色两套，不只做暗色：

```css
:root {
  --indieark-bg-base: #0b0f19;
  --indieark-bg-deep: #171a21;
  --indieark-bg-nav: #1b2838;
  --indieark-primary: #66c0f4;
  --indieark-primary-glow: rgba(102, 192, 244, 0.4);
  --indieark-text-primary: #f2f2f2;
  --indieark-text-secondary: #c7d5e0;
  --indieark-text-muted: #67707b;
  --indieark-accent: #4c6b22;
}

html.light {
  --indieark-bg-base: #f8f9fa;
  --indieark-bg-deep: #ffffff;
  --indieark-bg-nav: rgba(255, 255, 255, 0.82);
  --indieark-primary: #4facfe;
  --indieark-primary-glow: rgba(79, 172, 254, 0.16);
  --indieark-text-primary: #2a2925;
  --indieark-text-secondary: #5f5c55;
  --indieark-text-muted: #8c867a;
  --indieark-accent: #2b8a3e;
}
```

Dither 背景目标：

- 放在所有内容背后，`pointer-events: none`，不参与布局。
- 默认低透明度，避免影响 Open WebUI 原有可读性。
- 暗色主题使用 CSS 多层背景近似 4-qa-agent 的蓝色 dither 波纹：深蓝黑底、径向 Steam 蓝高光、低透明度 Bayer/像素点纹理。
- 亮色主题同样要有 dither，但需要按 4-qa-agent 亮色做法降低存在感：更低 opacity、`mix-blend-mode: multiply` 或等价效果、低饱和度、冷白/浅蓝遮罩，不能沿用暗色的强蓝发光。
- 支持 `prefers-reduced-motion: reduce`：如果后续加入轻动画，降级为静态背景。
- `oled-dark` 归入暗色策略，但背景底色可以更深，避免和 Open WebUI OLED 黑冲突。

执行时 `custom.css` 的 CSS 变更应按这个顺序组织：

1. IndieArk token：默认暗色，`html.light` 覆盖亮色，`html.oled-dark` 覆盖极暗底色。
2. 最外层背景色：只处理 `html` / `body` / route shell，不处理具体组件。
3. dither pseudo layer：暗色和亮色分开规则。
4. 左上品牌位标识。
5. 必要的主题降级和 reduced-motion 规则。

验收时如果发现 dither 被上游 `bg-white` / `dark:bg-gray-*` 外层盖住，只允许最小化处理外层 shell 背景；不能为了露出 dither 去改具体组件表面。

分析完整性补充：

- 当前计划已覆盖部署入口、资源挂载、标题修正、左上品牌位、全局色调和 dither 背景。
- 当前计划必须保留两个主题验收路径：暗色/`oled-dark` 与亮色都要分别看，不允许只在暗色截图通过就判定完成。
- 当前计划仍不覆盖完整 Steam_UI 组件迁移，因为用户明确要求页面内容和组件样式不变。

## 网页标题方案

不使用 `WEBUI_NAME=Indieark Chat`，因为当前上游会追加 ` (Open WebUI)`。

推荐通过挂载 `/static/loader.js` 实现最小标题修正：

- `loader.js` 由上游 `app.html` 原生加载，当前文件为空，适合作为部署层轻量品牌脚本入口。
- 脚本只做三件事：把初始标题 `Open WebUI` 改成 `Indieark Chat`；把路由标题里的 `Open WebUI` 后缀替换成 `Indieark Chat`；同步 `apple-mobile-web-app-title` / `description` 等 meta。
- 使用 `MutationObserver` 监听 `<title>` 被 Svelte 后续更新的情况，只替换品牌后缀，不破坏聊天标题前缀。

示例目标效果：

- 首页：`Indieark Chat`
- 工作区：`Workspace • Indieark Chat`
- 单个对话页：`对话标题 • Indieark Chat`

## 图标与开屏资源生成

用 `source-image.webp` 派生所有位图资源，推荐使用本机 bundled Python + Pillow：

- `favicon.png`：64x64 PNG。
- `favicon-96x96.png`：96x96 PNG。
- `favicon.ico`：包含 16x16、32x32、48x48、64x64。
- `favicon-dark.png`：64x64 PNG，当前可先与 `favicon.png` 同源。
- `apple-touch-icon.png`：180x180 PNG。
- `logo.png`：500x500 PNG，匹配 `/manifest.json` 当前声明。
- `web-app-manifest-192x192.png`：192x192 PNG。
- `web-app-manifest-512x512.png`：512x512 PNG。
- `splash.png` / `splash-dark.png`：建议 512x512 或 768x768 透明 PNG，保持图标中心不裁切。
- `favicon.svg`：用一个 SVG wrapper 引用或内嵌同源图像；如果浏览器优先选择 SVG，这个文件也必须替换，避免仍显示上游图标。

## 执行步骤

1. 创建 `deploy/open-webui/static/`。
2. 复制 `C:\Users\Windows\Downloads\image.webp` 到 `deploy/open-webui/static/source-image.webp`。
3. 可选复制 `00000-model` 的 IndieArk 文字 logo SVG 到 `deploy/open-webui/static/` 作为备用素材；本次执行不挂载、不用于顶栏。
4. 使用 Pillow 从 `source-image.webp` 生成 favicon、PWA 图标和 splash 资源。
5. 编写 `deploy/open-webui/static/manifest.json`，让 PWA 名称、短名称、描述和图标都指向 Indieark Chat 资产。
6. 编写 `deploy/open-webui/static/custom.css`，只处理全局色调、dither 背景层、左上品牌位和必要尺寸控制；不重写 Open WebUI 组件样式。
7. 编写 `deploy/open-webui/static/loader.js`，只处理标题和 meta 品牌名替换。
8. 修改 `docker-compose.yml`，追加上述单文件 `:ro` bind mount，并设置 `EXTERNAL_PWA_MANIFEST_URL=http://127.0.0.1:8080/static/manifest.json`。
9. 本地校验 compose：

   ```bash
   docker compose -f docker-compose.yml config
   ```

10. 提交并推送到 `origin/main`。
11. 在 Portainer Stack `open-webui` 执行 Pull and redeploy。
12. 部署后只读核验容器内文件：

   ```bash
   docker exec open-webui sh -lc 'ls -l /app/backend/open_webui/static/{custom.css,loader.js,favicon.png,splash.png,logo.png}'
   curl -I http://127.0.0.1:3000/static/custom.css
   curl -I http://127.0.0.1:3000/static/favicon.png
   curl -I http://127.0.0.1:3000/static/splash.png
   ```

13. 浏览器核验内网 `http://192.168.10.66:3000` 和外网 `https://chat.indieark.tech`。

## 验证标准

- `docker compose config` 通过。
- 容器仍使用官方镜像 `ghcr.io/open-webui/open-webui:main`。
- 容器内挂载文件存在，且内容来自仓库 `deploy/open-webui/static/`。
- `/static/favicon.png`、`/static/splash.png`、`/static/custom.css`、`/static/loader.js`、`/static/manifest.json` HTTP 返回 200。
- `/manifest.json` 返回 `name: Indieark Chat`，不再由默认 `Open WebUI` manifest 兜底。
- 浏览器标签页标题为 `Indieark Chat` 或 `页面标题 • Indieark Chat`，不出现 `Open WebUI` 或 `Indieark Chat (Open WebUI)`。
- 开屏图、登录页默认图标、侧边栏默认图标不再显示上游默认图标。
- 左上品牌位显示应用图标 + `Indieark Chat`，移动端聊天栏兜底不遮挡模型选择器和右侧按钮。
- 暗色/`oled-dark` 页面整体色调接近 `4-qa-agent` 的深蓝黑 + Steam 蓝高光；亮色页面整体色调接近 `4-qa-agent` 的亮白玻璃 + Steam 青蓝弱高光。
- 暗色和亮色都存在 dither 背景，但亮色必须明显更弱，不影响文字可读性、点击和滚动。
- 消息、输入框、按钮、菜单、模型选择器等组件样式保持 Open WebUI 原状。
- 容器 healthy，`3000` 端口正常。

## 回滚

最小回滚：

1. 移除 `custom.css` 中左上品牌位规则，保留图标资源。
2. 或清空 `loader.js`，只回滚标题修正。
3. 推送后 Portainer redeploy。

完整回滚：

1. 移除 `docker-compose.yml` 中新增的静态文件 bind mount。
2. 推送后 Portainer redeploy。

## 风险与注意事项

- `custom.css` 依赖上游 DOM 结构，后续上游更新可能需要调整选择器。
- dither 背景可能被上游外层实体背景遮住；执行时只能处理最外层背景透明度，不能扩大成组件重皮肤。
- `loader.js` 当前上游为空；如果未来上游开始使用该文件，升级时需要对比并合并上游内容，避免覆盖新逻辑。
- favicon 存在浏览器缓存，需要用无痕窗口或清缓存验证。
- Cloudflare Access 不影响同域静态资源加载；只要主页面通过 Access，`/static/*` 应同域可访问。
- Portainer Git Stack 的 bind mount 相对路径必须部署后核验，不能只凭本地 compose 通过判定成功。
