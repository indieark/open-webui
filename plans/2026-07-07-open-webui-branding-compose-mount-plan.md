# Open WebUI 品牌化 Compose 挂载计划

## 执行状态

早期单文件 bind mount 路线已被测试环境 Portainer 实测否定：Stack 部署目录里缺失的 `deploy/open-webui/static/*.png` 会被 Docker 自动创建成目录，导致“目录挂载到容器文件路径”的 `not a directory` 错误。当前执行路线已调整为：根层 `docker-compose.yml` 不再挂载静态文件，而是在官方容器启动时用内联 bootstrap 生成 `custom.css`、`loader.js`、manifest 和图标资源；本地部署层实现和静态校验已完成，测试环境仍需 Portainer Pull and redeploy 后做运行时核验。

## 结论

可以在不修改上游源码、不自建镜像、不改官方镜像本体的前提下完成大部分品牌化要求。执行边界是：只改私库根层 `docker-compose.yml` 的启动包装逻辑，由容器启动时在自身 filesystem 内生成静态资源，避免依赖 Portainer 宿主机上的 bind mount 文件。

本计划覆盖：

- 左上品牌位显示应用图标 + `IndieArk Chat`；桌面端优先复用 Open WebUI 侧边栏顶部原生结构，移动端聊天栏提供同样结构的 CSS 兜底。
- 浏览器 favicon、PWA 图标、登录/侧边栏默认图标使用 `C:\Users\Windows\Downloads\image.webp` 派生资源。
- 开屏图标 `splash.png` / `splash-dark.png` 使用同一张 `image.webp` 派生资源。
- 网页标题显示为 `IndieArk Chat`，不使用会追加 ` (Open WebUI)` 的 `WEBUI_NAME` 环境变量路线。
- CSS 作为部署层皮肤覆盖：保留页面内容、组件结构和上游源码不变，但按用户截图反馈收口暗色 surface、侧栏按钮、输入区按钮、下拉菜单、悬浮工具条、右侧控制抽屉、滚动条和开关色调。

## 不变量

- 不改 `upstream/open-webui/`。
- 不写 Dockerfile，不构建私有镜像，继续使用 `ghcr.io/open-webui/open-webui:main`。
- 只改根层部署资产、计划文档和 `docker-compose.yml`。
- 部署不能依赖 `C:\Users\Windows\Downloads\image.webp` 或 Portainer 宿主机上的相对路径文件；图标源必须随 compose bootstrap 自包含。
- 不挂载整个 `/app/backend/open_webui/static` 目录，也不挂载单个 static 文件；避免 Portainer 缺失 bind 源时把文件路径创建成目录。
- 失败回滚应只需要恢复 `docker-compose.yml` 的 `command`，不影响 Open WebUI 数据卷。

## 当前事实依据

- 上游 `app.html` 已加载 `/static/custom.css` 和 `/static/loader.js`。
- 测试容器只读核验过 `STATIC_DIR=/app/backend/open_webui/static`，当前 `custom.css` 存在但为空。
- 上游启动时会清理并重拷贝 `STATIC_DIR`，所以 bootstrap 需要启动时先写一次，等待 `/health` 可用后再写一次，覆盖上游初始化后的默认 static。
- 当前上游 `WEBUI_NAME=IndieArk Chat` 会被 `env.py` 改成 `IndieArk Chat (Open WebUI)`，不满足“网页名字改成 IndieArk Chat”的精确要求。
- PWA `/manifest.json` 由后端动态生成；本次不使用 `WEBUI_NAME`，改用上游已支持的 `EXTERNAL_PWA_MANIFEST_URL` 指向容器内静态 `/static/manifest.json`。
- 当前上游静态目录包含这些品牌相关入口：`favicon.png`、`favicon-96x96.png`、`favicon.svg`、`favicon.ico`、`favicon-dark.png`、`apple-touch-icon.png`、`splash.png`、`splash-dark.png`、`logo.png`、`web-app-manifest-192x192.png`、`web-app-manifest-512x512.png`。
- Portainer Git Stack 在测试环境的实际 compose 运行目录不能保证包含仓库静态文件；缺失 bind 源会被 Docker 创建为目录，因此品牌化资产必须由容器内部生成或由镜像内置。
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
- `brand-indieark-logo-charcoal.svg` 和 `brand-indieark-logo-white.svg` 可复制自 `C:\Vibe_Coding\IndieArk\00000-model\01-复用资产\assets\INDIEARK Text Logo\` 作为备用品牌素材；本次最终执行不把 SVG 挂载进容器，左上品牌位使用 `source-image.webp` 派生的图标 + `IndieArk Chat` 文本。

## Compose 启动生成

在 `docker-compose.yml` 的 `open-webui.volumes` 只保留数据卷，不再追加任何 static bind mount：

```yaml
services:
  open-webui:
    volumes:
      - open-webui:/app/backend/data
```

说明：

- `command` 覆盖官方镜像默认 `bash start.sh`，但最后仍 `exec bash start.sh`，保持官方启动路径。
- bootstrap 作为后台任务运行，先写入 static 文件，然后等待 `http://127.0.0.1:8080/health`，服务就绪后再写一次，解决上游启动阶段清理 `STATIC_DIR` 的问题。
- 图标源以 WebP base64 内联到 compose 中，使用官方镜像内已有 Python / Pillow 生成 PNG、ICO 和 SVG wrapper。
- `EXTERNAL_PWA_MANIFEST_URL` 继续指向容器内 `/static/manifest.json`。

## 左上品牌位方案

优先复用 Open WebUI 侧边栏顶部原生 `favicon + WEBUI_NAME` 结构，不改 Svelte 源码。

策略：

- 左侧图标使用 `source-image.webp` 派生的 `favicon.png`，保持和 favicon / PWA / splash 同源。
- `loader.js` 把运行时品牌文本从 `Open WebUI` 替换为 `IndieArk Chat`，避免使用会追加 ` (Open WebUI)` 的 `WEBUI_NAME` 环境变量。
- `custom.css` 只对侧边栏品牌图标做尺寸、圆角和轻微 glow 处理，符合截图中的“图标 + 名称”结构。
- 移动端聊天栏在侧边栏不可见时，用 CSS `::before` / `::after` 兜底显示小图标 + `IndieArk Chat`；窄屏降级为 `Chat`，避免挤压模型选择器和右侧按钮。
- 如果后续上游 DOM 结构变动导致选择器失效，只更新 `custom.css` / `loader.js`，不碰上游源码。

执行前需要用浏览器或 DOM 截图确认选择器命中当前品牌位，避免影响设置页导航或模型选择器。

## CSS 色调与 Dither 边界

本计划的 CSS 边界经历过一次收敛和一次扩展：

- 初始边界：只改色调，加 dither 背景，不重写 Open WebUI 的页面内容、组件结构或上游源码。
- 用户后续截图确认：暗色态仍有大量默认灰色，需要继续覆盖右侧“对话高级设置”抽屉、侧栏按钮、输入区按钮、工具/上传下拉菜单、富文本浮动工具条、选中文本悬浮栏、底部悬浮圆形按钮、滚动条和开关色调。

最终执行边界：

- 不改 `upstream/open-webui/`，不改 Svelte 组件源码，不构建私有镜像。
- 不改页面内容、导航结构、字段、交互功能、数据流和组件 DOM 结构。
- 允许通过 `deploy/open-webui/static/custom.css` 覆盖颜色、surface、border、hover/selected、shadow、scrollbar、switch 和品牌 token。
- 允许通过 `loader.js` 替换运行时品牌文本、标题、meta 和 `oled-dark` 辅助 class。
- 允许通过 `docker-compose.yml` command bootstrap 把上述静态资源写入官方容器内部 static 目录。
- 不把 Open WebUI 改成 4-qa-agent 的完整 Steam_UI 组件库，只迁移 4-qa-agent 的色调、明暗主题思路和 dither 背景语言。

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

执行时 `custom.css` 的 CSS 变更按这个顺序组织：

1. IndieArk token：默认暗色，`html.light` 覆盖亮色，`html.oled-dark` 覆盖极暗底色。
2. 最外层背景色和 dither 背景：处理 `html` / `body` / route shell。
3. dither pseudo layer：暗色和亮色分开规则。
4. 暗色 surface 系统：Tailwind gray token、modal/dropdown/card/input、右侧控制抽屉、输入区、侧栏、悬浮栏、滚动条、开关。
5. 左上品牌位标识。
6. 必要的主题降级和 reduced-motion 规则。

验收时如果发现新的默认灰色面，应优先确认是否属于上游 `dark:bg-gray-*` / `dark:hover:bg-gray-*` / `role="menu"` / `role="switch"` 这类可由部署层 CSS 覆盖的 surface。只有在不改源码、不改 DOM、不影响功能的前提下，才继续补 `custom.css` 选择器。

分析完整性补充：

- 当前计划已覆盖部署入口、资源生成、标题修正、左上品牌位、全局色调、dither 背景和暗色 surface 收口。
- 当前计划必须保留两个主题验收路径：暗色/`oled-dark` 与亮色都要分别看，不允许只在暗色截图通过就判定完成。
- 当前计划仍不覆盖完整 Steam_UI 组件迁移，因为用户明确要求页面内容和组件样式不变。

## 网页标题方案

不使用 `WEBUI_NAME=IndieArk Chat`，因为当前上游会追加 ` (Open WebUI)`。

推荐通过挂载 `/static/loader.js` 实现最小标题修正：

- `loader.js` 由上游 `app.html` 原生加载，当前文件为空，适合作为部署层轻量品牌脚本入口。
- 脚本只做三件事：把初始标题 `Open WebUI` 改成 `IndieArk Chat`；把路由标题里的 `Open WebUI` 后缀替换成 `IndieArk Chat`；同步 `apple-mobile-web-app-title` / `description` 等 meta。
- 使用 `MutationObserver` 监听 `<title>` 被 Svelte 后续更新的情况，只替换品牌后缀，不破坏聊天标题前缀。

示例目标效果：

- 首页：`IndieArk Chat`
- 工作区：`Workspace • IndieArk Chat`
- 单个对话页：`对话标题 • IndieArk Chat`

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
5. 编写 `deploy/open-webui/static/manifest.json`，让 PWA 名称、短名称、描述和图标都指向 IndieArk Chat 资产。
6. 编写 `deploy/open-webui/static/custom.css`，只处理全局色调、dither 背景层、左上品牌位和必要尺寸控制；不重写 Open WebUI 组件样式。
7. 编写 `deploy/open-webui/static/loader.js`，只处理标题和 meta 品牌名替换。
8. 修改 `docker-compose.yml`，移除 static 单文件 bind mount，改为 `command: ["bash", "-lc", "..."]` 在容器内生成上述静态文件，并设置 `EXTERNAL_PWA_MANIFEST_URL=http://127.0.0.1:8080/static/manifest.json`。
9. 本地校验 compose：

   ```bash
   docker compose -f docker-compose.yml config
   ```

10. 校验内联 Python bootstrap 能被编译：

   ```bash
   awk "/python - <<'PY'/{flag=1;next} /^        PY$/{flag=0} flag{sub(/^        /, \"\"); print}" docker-compose.yml | python -c "import sys; compile(sys.stdin.read(), 'compose-bootstrap', 'exec')"
   ```

11. 提交并推送到 `origin/main`。
12. 在 Portainer Stack `open-webui` 执行 Pull and redeploy。
13. 部署后只读核验容器内文件：

   ```bash
   docker exec open-webui sh -lc 'ls -l /app/backend/open_webui/static/{custom.css,loader.js,favicon.png,splash.png,logo.png}'
   curl -I http://127.0.0.1:3000/static/custom.css
   curl -I http://127.0.0.1:3000/static/favicon.png
   curl -I http://127.0.0.1:3000/static/splash.png
   ```

14. 浏览器核验内网 `http://192.168.10.66:3000` 和外网 `https://chat.indieark.tech`。

## 验证标准

- `docker compose config` 通过。
- 容器仍使用官方镜像 `ghcr.io/open-webui/open-webui:main`。
- 容器内生成文件存在，且 `docker inspect open-webui` 不再出现 `deploy/open-webui/static/*.png` 这类 bind mount。
- `/static/favicon.png`、`/static/splash.png`、`/static/custom.css`、`/static/loader.js`、`/static/manifest.json` HTTP 返回 200。
- `/manifest.json` 返回 `name: IndieArk Chat`，不再由默认 `Open WebUI` manifest 兜底。
- 浏览器标签页标题为 `IndieArk Chat` 或 `页面标题 • IndieArk Chat`，不出现 `Open WebUI` 或 `IndieArk Chat (Open WebUI)`。
- 开屏图、登录页默认图标、侧边栏默认图标不再显示上游默认图标。
- 左上品牌位显示应用图标 + `IndieArk Chat`，移动端聊天栏兜底不遮挡模型选择器和右侧按钮。
- 暗色/`oled-dark` 页面整体色调接近 `4-qa-agent` 的深蓝黑 + Steam 蓝高光；亮色页面整体色调接近 `4-qa-agent` 的亮白玻璃 + Steam 青蓝弱高光。
- 暗色和亮色都存在 dither 背景，但亮色必须明显更弱，不影响文字可读性、点击和滚动。
- 消息内容、输入流程、按钮功能、菜单结构、模型选择器结构保持 Open WebUI 原状；暗色 surface、hover/selected、滚动条、开关和品牌色可由 `custom.css` 收口为 IndieArk 色调。
- 容器 healthy，`3000` 端口正常。

## 回滚

最小回滚：

1. 移除 `custom.css` 中左上品牌位规则，保留图标资源。
2. 或清空 `loader.js`，只回滚标题修正。
3. 推送后 Portainer redeploy。

完整回滚：

1. 恢复 `docker-compose.yml` 中的 `command` 为官方默认 `bash start.sh`，或直接移除 `command`。
2. 推送后 Portainer redeploy。

## 风险与注意事项

- `custom.css` 依赖上游 DOM 结构，后续上游更新可能需要调整选择器。
- dither 背景可能被上游外层实体背景遮住；执行时只能处理最外层背景透明度，不能扩大成组件重皮肤。
- `loader.js` 当前上游为空；如果未来上游开始使用该文件，升级时需要对比并合并上游内容，避免覆盖新逻辑。
- favicon 存在浏览器缓存，需要用无痕窗口或清缓存验证。
- Cloudflare Access 不影响同域静态资源加载；只要主页面通过 Access，`/static/*` 应同域可访问。
- 由于 `command` 内联内容较长，每次改 CSS / JS / 图标都必须同时跑 compose config 和内联 Python compile 校验。
