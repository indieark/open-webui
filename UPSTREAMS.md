# Upstreams

本仓库只跟踪一个公共上游：

| Name | URL | Branch | Local path | Current split |
| --- | --- | --- | --- | --- |
| `upstream-open-webui` | `https://github.com/open-webui/open-webui.git` | `main` | `upstream/open-webui/` | `ecd48e2f718220a6400ecf49eafd4867a38feb10` |

## 不变量

- 上游源码只进入 `upstream/open-webui/`。
- 根目录是 IndieArk 兼容层，不反向混入 upstream subtree。
- 同步前必须 compare-first。
- 无真实 upstream delta 时 no-op，不构建、不提交、不推送。
- 有 delta 时只提交 upstream delta 和必要兼容层修复。

## 同步

优先使用脚本：

```bash
bash scripts/sync-upstream.sh
```

Windows 原生命令环境：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-upstream.ps1
```

脚本读取最新 subtree squash commit message 中的 `git-subtree-split`，再和 `upstream-open-webui/main` 比较。不要用 `git subtree split --prefix=upstream/open-webui HEAD` 直接等值比较 upstream head，因为 squash subtree 的 split commit 可能不是官方原始 commit。

## 手动同步

```bash
git remote get-url upstream-open-webui >/dev/null 2>&1 || \
  git remote add upstream-open-webui https://github.com/open-webui/open-webui.git

git fetch upstream-open-webui main --no-tags
git log --oneline <last-git-subtree-split>..upstream-open-webui/main
git subtree pull --prefix=upstream/open-webui upstream-open-webui main --squash
bash scripts/verify-compat.sh
```

## 冲突规则

- 冲突在 `upstream/open-webui/` 内：默认优先官方上游，除非该文件已在 `docs/compatibility-layer.md` 登记为 subtree 例外。
- 冲突在根级 `docker-compose.yml`、`compat/`、`scripts/`、`docs/`、`plans/`：优先保留 IndieArk 兼容层语义。
- 同步后必须确认 `docker-compose.yml` 仍保持 `open-webui` service/container、`3000:8080`、`open-webui:/app/backend/data` 和 `ghcr.io/open-webui/open-webui:main` 的第一阶段稳定部署语义。
