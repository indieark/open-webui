# 仓库维护

## 当前状态

- 私库：`indieark/open-webui`
- 官方上游：`open-webui/open-webui`
- 官方 subtree 路径：`upstream/open-webui/`
- 当前 split：`ecd48e2f718220a6400ecf49eafd4867a38feb10`
- 根目录：IndieArk 兼容层

## 日常同步

```bash
bash scripts/sync-upstream.sh
```

无 upstream delta 时脚本 no-op。出现 delta 时脚本执行 subtree pull，然后运行兼容层验证。

PowerShell：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-upstream.ps1
```

## 验证

```bash
bash scripts/verify-compat.sh
WEBUI_SECRET_KEY=verify-placeholder docker compose config --quiet
WEBUI_SECRET_KEY=verify-placeholder docker compose -f docker-compose.yml -f docker-compose.local.yml config --quiet
```

如果实际修改了 `upstream/open-webui/` 源码，再进入该目录执行对应前后端测试。

## 冲突处理

- `upstream/open-webui/` 内冲突默认优先上游。
- 根级 `docker-compose.yml`、`compat/`、`scripts/`、`docs/`、`plans/` 冲突默认保留 IndieArk 兼容层。
- 任何必须保留的 upstream subtree 修改，都要先写入 `docs/compatibility-layer.md`。

## 回滚

代码回滚使用 `git revert`，不要重写共享历史。

部署回滚：

- 保持 Portainer stack/project 名为 `open-webui`。
- 镜像恢复到 `ghcr.io/open-webui/open-webui:main`。
- 保留 `open-webui_open-webui` volume。
- 禁止 `docker compose down -v`。

## 测试环境只读核验

```powershell
$sshArgs = @(
  "-i", "$env:USERPROFILE\.ssh\codex_portainer_ops_ed25519",
  "-p", "22",
  "-o", "BatchMode=yes",
  "ops@192.168.10.66"
)

ssh @sshArgs "docker ps --filter name=^/open-webui$ --format 'name={{.Names}} image={{.Image}} status={{.Status}} ports={{.Ports}}'"
```

任何写操作、重启或 redeploy 都必须另行确认。
