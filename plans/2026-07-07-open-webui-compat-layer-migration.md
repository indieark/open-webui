# Open WebUI 兼容层与上游独立更新迁移计划

日期：2026-07-07

## 结论

可以改造成类似 `gadget/CLIProxyAPI` 的兼容层结构，而且值得做。

当前 `indieark/open-webui` 仍是 Open WebUI 上游源码平铺在仓库根部。私库相对公共上游 `open-webui/open-webui@ecd48e2f718220a6400ecf49eafd4867a38feb10` 的真实增量只有根级 `docker-compose.yml`，当前 `origin/main` 为 `3960faf1d6062cea99fe269f141cc41e1f284b0b`。测试环境已经通过 Portainer stack `open-webui` 部署在 `192.168.10.66:3000`，当前运行镜像是公共上游 `ghcr.io/open-webui/open-webui:main`，镜像 revision 为 `ecd48e2f718220a6400ecf49eafd4867a38feb10`。

因此计划需要调整为“先保护已运行的 Portainer/Compose 私库兼容层，再谈上游源码独立跟踪”。如果后续要加部署默认值、搜索能力、OpenAI hosted web search 适配、Portainer/GHCR 规则或本地补丁，必须先把“上游源码”和“IndieArk 兼容层”分开，否则每次 upstream 更新都会把私库设计混在冲突里。

本计划已经补齐为可执行 runbook，但本轮仍只修改计划文档，不执行目录搬迁、脚本改造、构建、部署或生产重启。

## 当前结构

```text
.
├── backend/                 # Open WebUI 上游后端源码
├── src/                     # Open WebUI 上游前端源码
├── static/                  # Open WebUI 上游静态资源
├── docs/                    # Open WebUI 上游文档
├── scripts/                 # Open WebUI 上游脚本
├── .github/workflows/       # Open WebUI 上游 CI
├── Dockerfile               # Open WebUI 上游 Dockerfile
├── docker-compose.yaml      # Open WebUI 上游示例 Compose
├── docker-compose.yml       # IndieArk Portainer 部署增量
├── package.json
├── pyproject.toml
└── README.md                # Open WebUI 上游 README
```

问题清单：

- 根目录同时承载上游源码和 IndieArk 部署配置，边界不清。
- 只有 `origin=indieark/open-webui`，尚未建立 `upstream-open-webui` 远端和 compare-first 同步流程。
- 私库部署文件 `docker-compose.yml` 与上游示例文件同处根目录，后续上游若新增同名文件会冲突。
- 没有 `UPSTREAMS.md`、`docs/compatibility-layer.md`、`docs/repository-maintenance.md`、`scripts/sync-upstream.*` 这类维护入口。
- Web Search / hosted tool / Portainer / GHCR 等私库行为如果直接改 `backend/` 或 `src/`，后续同步成本会迅速上升。

## 当前测试环境事实

只读核验时间：2026-07-07，已二次核验远端 ref 和测试机容器状态。

测试环境 `192.168.10.66` 当前事实：

- Docker host：`vm-dev-01`
- Compose project：`open-webui`
- Container：`open-webui`
- Service：`open-webui`
- Published port：`0.0.0.0:3000 -> 8080/tcp` 和 `[::]:3000 -> 8080/tcp`
- Image：`ghcr.io/open-webui/open-webui:main`
- Image revision：`ecd48e2f718220a6400ecf49eafd4867a38feb10`
- Image id：`sha256:a26effeb220e132482bf7e0560b3404843e7bc40d23051144e062960df8df6b0`
- Container status：running，healthy
- Started at：`2026-07-06T14:28:00.541291759Z`
- Logical compose volume：`open-webui:/app/backend/data`
- Actual Docker volume：`open-webui_open-webui`
- Local HTTP smoke：`http://127.0.0.1:3000/` 返回 `200`
- Environment keys confirmed：`WEBUI_SECRET_KEY`、`OLLAMA_BASE_URL=http://host.docker.internal:11434`、遥测关闭项；未在输出中保留 secret 值
- 本次核验未做写入、未 pull 镜像、未重启容器、未修改 Portainer stack。

这说明当前私库设计的运行面不是私有 Open WebUI runtime 镜像，而是“公共上游镜像 + IndieArk Portainer Compose 兼容层”。结构迁移第一阶段不得改变这个运行面。

## 目标结构

```text
.
├── upstream/open-webui/          # Open WebUI 公共上游 subtree，默认不直接改
├── compat/                       # IndieArk 兼容层代码与补丁
│   ├── config/                   # 默认配置、环境变量模板、搜索 provider 配置
│   ├── patches/                  # 必须 post-build 或 runtime 注入的补丁
│   └── entrypoint/               # 容器入口包装、数据初始化和环境映射
├── scripts/
│   ├── sync-upstream.sh          # Bash compare-first 同步入口
│   ├── sync-upstream.ps1         # PowerShell compare-first 同步入口
│   ├── verify-compat.sh          # 兼容层验证入口
│   └── build-private-image.*     # 如需私有镜像时再启用
├── docs/
│   ├── README.md                 # 文档中心
│   ├── architecture.md           # 上游 subtree + 根兼容层架构
│   ├── deployment.md             # Portainer、Compose、域名、卷、环境变量
│   ├── compatibility-layer.md    # 私库补丁和兼容层索引
│   └── repository-maintenance.md # 上游同步、冲突、恢复规则
├── plans/
│   ├── README.md
│   └── 2026-07-07-open-webui-compat-layer-migration.md
├── UPSTREAMS.md                  # 上游远端、基线、同步命令和不变量
├── AGENTS.md                     # 本仓协作规则
├── README.md                     # IndieArk 私库入口，不再使用上游 README
├── docker-compose.yml            # 当前 Portainer 稳定部署入口
├── docker-compose.local.yml      # 本地按私库源码构建时使用
└── Dockerfile                    # 私有镜像入口；无私有源码补丁时可保持很薄
```

分层依据：

- `upstream/open-webui/` 只跟踪 `open-webui/open-webui`，默认按 upstream 内容维护。
- 根目录、`compat/`、`scripts/`、`docs/`、`plans/` 属于 IndieArk 私库兼容层。
- 能通过 Compose、环境变量、entrypoint、post-build patch 或 wrapper 解决的问题，不进入 `upstream/open-webui/`。
- 只有上游没有扩展点且必须改源码时，才允许 subtree 例外；例外必须写入 `docs/compatibility-layer.md` 和 `docs/repository-maintenance.md`。

## 必须保持的不变量

1. 测试环境入口不变：`192.168.10.66:3000` 继续指向 Open WebUI；迁移计划不得默认改端口。
2. Compose project 不变：测试环境 stack/project 名继续是 `open-webui`。如果 project 名变化，Compose 会生成不同的命名卷，存在“看起来启动成功但数据为空”的风险。
3. 数据卷不变：逻辑卷继续使用 `open-webui:/app/backend/data`；测试环境实际 Docker 卷为 `open-webui_open-webui`，不得在迁移中改名、删除或改容器内路径。
4. 默认服务入口不变：`open-webui` 服务名、`container_name: open-webui`、`3000:8080` 端口映射保持当前部署语义。
5. 当前稳定镜像不变：第一阶段继续使用 `ghcr.io/open-webui/open-webui:main`。只有出现真实私有 runtime patch 并完成验证后，才考虑切到 `ghcr.io/indieark/open-webui:*`。
6. `WEBUI_SECRET_KEY` 仍是 Portainer stack 必填环境变量，不写入仓库。
7. Ollama 连接默认仍为 `http://host.docker.internal:11434`，并保留 `extra_hosts: host.docker.internal:host-gateway`。
8. 遥测关闭不变：`SCARF_NO_ANALYTICS=true`、`DO_NOT_TRACK=true`、`ANONYMIZED_TELEMETRY=false`。
9. 上游更新只从 `open-webui/open-webui` 进入 `upstream/open-webui/`，不得把 IndieArk 兼容层反向混入上游目录。
10. 同步前必须 compare-first；无真实 upstream delta 时 no-op，不构建、不提交、不推送。
11. 任何测试环境 Portainer stack 变更、镜像切换、重建或容器重启都必须另行确认；本计划阶段不做测试环境写操作。
12. 生产部署不在本计划范围内；若未来生产部署，必须单独写生产核验与回滚计划。

## 执行边界

可执行目标：

- 把当前平铺 fork 改造成 `upstream/open-webui/` 上游 subtree + 根级 IndieArk 兼容层。
- 保留当前测试环境部署语义，不改变 `open-webui` stack、`open-webui` container、`3000:8080`、`open-webui_open-webui` 数据卷和公共上游镜像来源。
- 建立后续上游同步的 compare-first / no-op 维护入口。

禁止事项：

- 不把 `WEBUI_SECRET_KEY`、搜索 provider key、OpenAI key 或 Portainer credential 写入仓库。
- 不执行 `docker compose down -v`、`docker volume rm`、`docker rm`、`docker restart`、Portainer redeploy 或任何会影响测试环境运行的写操作。
- 不在没有 `docs/compatibility-layer.md` 记录的情况下修改 `upstream/open-webui/` 内文件。
- 不用 `git reset --hard` 或重写共享历史回滚。

停止条件：

- `git ls-remote` 显示官方上游已经不是计划内基线，且 `git log <old>..<new>` 包含部署、数据迁移、认证、搜索或模型 provider 相关改动。
- 当前测试环境不是 `open-webui` project / `open-webui` container / `open-webui_open-webui` volume。
- `docker compose config --quiet` 不能通过，或解析后的 volume / port / image 与不变量冲突。
- subtree 导入后 `git-subtree-split` 不是预期官方 upstream commit。

## 执行 Runbook

以下步骤按顺序执行。每个阶段通过验证点后再进入下一阶段；任一验证失败，先停下并记录原因，不继续迁移。

### P0：基线确认

执行目录：

```bash
cd /c/Vibe_Coding/IndieArk/gadget/open-webui
```

本地与远端基线：

```bash
git status --short --branch
git rev-parse HEAD
git ls-remote origin refs/heads/main
git ls-remote https://github.com/open-webui/open-webui.git refs/heads/main
git diff --name-status ecd48e2f718220a6400ecf49eafd4867a38feb10..HEAD
```

预期结果：

- `HEAD` 与 `origin/main` 均为 `3960faf1d6062cea99fe269f141cc41e1f284b0b`，除当前计划文件外没有未知改动。
- 官方上游 `main` 为 `ecd48e2f718220a6400ecf49eafd4867a38feb10`。
- 私库相对官方上游的业务 delta 只有根级 `docker-compose.yml`。

测试环境只读核验：

```powershell
$sshArgs = @(
  "-i", "$env:USERPROFILE\.ssh\codex_portainer_ops_ed25519",
  "-p", "22",
  "-o", "BatchMode=yes",
  "-o", "ConnectTimeout=10",
  "ops@192.168.10.66"
)

ssh @sshArgs @'
set -e
hostname
docker ps --filter name=^/open-webui$ --format 'name={{.Names}} image={{.Image}} status={{.Status}} ports={{.Ports}}'
docker compose ls --format json 2>/dev/null | grep -i 'open-webui' || true
docker inspect open-webui --format 'project={{index .Config.Labels "com.docker.compose.project"}} service={{index .Config.Labels "com.docker.compose.service"}} image={{.Config.Image}} image_id={{.Image}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'
docker inspect open-webui --format '{{range .Mounts}}mount={{.Name}}:{{.Destination}} type={{.Type}}{{"\n"}}{{end}}'
docker inspect open-webui --format 'revision={{index .Config.Labels "org.opencontainers.image.revision"}}'
docker exec open-webui sh -lc 'printf "WEBUI_BUILD_VERSION=%s\n" "$WEBUI_BUILD_VERSION"' 2>/dev/null || true
curl -sS -o /dev/null -w 'http=%{http_code}\n' http://127.0.0.1:3000/ || true
'@
```

预期结果：

- `project=open-webui`，`service=open-webui`。
- `image=ghcr.io/open-webui/open-webui:main`。
- `health=healthy`。
- `mount=open-webui_open-webui:/app/backend/data type=volume`。
- `revision` 与 `WEBUI_BUILD_VERSION` 均为 `ecd48e2f718220a6400ecf49eafd4867a38feb10`。
- `http=200`。

验证点：

```bash
git status --short --branch
git diff --stat ecd48e2f718220a6400ecf49eafd4867a38feb10..HEAD
git diff -- docker-compose.yml
```

### P1：建立执行分支和计划保护点

计划文件本身先作为第一笔可审计变更进入迁移分支，避免后续结构改动和计划改动混在一起。

```bash
git switch main
git pull --ff-only origin main
git switch -c chore/open-webui-compat-layer-migration
git add plans/README.md plans/2026-07-07-open-webui-compat-layer-migration.md
git commit -m "docs: plan open-webui compatibility layer migration"
```

可选保护点：

```bash
git branch archive/open-webui-pre-compat-layer-3960faf1 3960faf1d6062cea99fe269f141cc41e1f284b0b
```

验证点：

```bash
git status --short --branch
git log --oneline -3
```

### P2：导入官方上游 subtree

执行命令：

```bash
git remote get-url upstream-open-webui >/dev/null 2>&1 || \
  git remote add upstream-open-webui https://github.com/open-webui/open-webui.git

git fetch upstream-open-webui main --no-tags
UPSTREAM_HEAD="$(git rev-parse upstream-open-webui/main)"
test "$UPSTREAM_HEAD" = "ecd48e2f718220a6400ecf49eafd4867a38feb10"
test ! -e upstream/open-webui
git subtree add --prefix=upstream/open-webui upstream-open-webui main --squash
```

验证 subtree 元数据：

```bash
git log -1 --format=%B | rg "git-subtree-dir: upstream/open-webui|git-subtree-split: ecd48e2f718220a6400ecf49eafd4867a38feb10"
test -f upstream/open-webui/package.json
test -f upstream/open-webui/backend/open_webui/config.py
test -f upstream/open-webui/docker-compose.yaml
```

如果 `test "$UPSTREAM_HEAD" = ...` 失败：

- 停止迁移。
- 用 `git log --oneline ecd48e2f718220a6400ecf49eafd4867a38feb10..upstream-open-webui/main` 看新增提交。
- 如果新增提交影响部署、数据、认证、搜索或 provider，先更新本计划的基线和风险说明。
- 如果只是文档或无运行影响，可以把计划基线更新为新的 upstream head 后再执行。

### P3：清理根部上游文件，只保留私库兼容层

当前根目录已经是上游源码平铺形态。导入 subtree 后，根部上游文件要从根目录删除或替换成 IndieArk 入口；私库 `docker-compose.yml` 和 `plans/` 保留。

生成官方上游文件清单并删除根部对应文件：

```bash
mkdir -p .tmp/open-webui-migration
git ls-tree -r --name-only upstream-open-webui/main > .tmp/open-webui-migration/upstream-root-files.txt
grep -vxF 'docker-compose.yml' .tmp/open-webui-migration/upstream-root-files.txt |
  tr '\n' '\0' |
  xargs -0 git rm -r --ignore-unmatch --
```

删除后必须重新创建或保留的根级私库文件：

- `README.md`：IndieArk 私库入口，指向 `docs/README.md`、`UPSTREAMS.md` 和当前部署入口。
- `AGENTS.md`：本仓协作规则，明确 `upstream/open-webui/` 默认不改。
- `UPSTREAMS.md`：官方上游 remote、subtree 路径、当前 `git-subtree-split` 基线、同步命令、no-op 规则。
- `docker-compose.yml`：当前 Portainer 稳定部署入口，继续使用 `ghcr.io/open-webui/open-webui:main`。
- `docker-compose.local.yml`：仅本地构建私有镜像时使用，不替代测试环境 stable compose。
- `Dockerfile`：私有镜像薄包装；第一阶段可只 `FROM ghcr.io/open-webui/open-webui:main`，后续有真实补丁再扩展。
- `.gitignore`：根级私库忽略规则，不能直接依赖上游根 `.gitignore` 的位置。
- `compat/README.md`：兼容层代码、配置、patch 的占位入口。
- `scripts/sync-upstream.sh`、`scripts/sync-upstream.ps1`、`scripts/verify-compat.sh`。
- `docs/README.md`、`docs/architecture.md`、`docs/deployment.md`、`docs/compatibility-layer.md`、`docs/repository-maintenance.md`。
- `plans/README.md` 与本计划文件。

验证点：

```bash
test -d upstream/open-webui/backend
test -d upstream/open-webui/src
test -f upstream/open-webui/README.md
test -f docker-compose.yml
test -f plans/2026-07-07-open-webui-compat-layer-migration.md
test ! -d backend
test ! -d src
test ! -f package.json
git status --short
```

### P4：落地根级文档和维护规则骨架

根级文档是私库设计的单一入口，内容要覆盖“当前是什么、以后怎么同步、哪里能改、哪里不能改”。

文件内容要求：

| 文件 | 必须包含 |
| --- | --- |
| `README.md` | 项目定位；测试环境入口；稳定部署命令；文档入口；上游源码位置；禁止直接改 `upstream/open-webui/` 的规则 |
| `AGENTS.md` | 默认中文；兼容层优先；计划放 `plans/`；测试环境写操作需确认；敏感信息不入库；验证命令 |
| `UPSTREAMS.md` | `upstream-open-webui=https://github.com/open-webui/open-webui.git`；subtree path `upstream/open-webui`；当前 split `ecd48e2f718220a6400ecf49eafd4867a38feb10`；sync/runbook；冲突规则 |
| `docs/README.md` | 文档阅读路线和单一事实源索引 |
| `docs/architecture.md` | `upstream/open-webui/` 与根级兼容层的边界图；为什么第一阶段不切私有镜像 |
| `docs/deployment.md` | `192.168.10.66:3000`、Portainer stack、service/container、image、volume、env keys、Web Search gate |
| `docs/compatibility-layer.md` | 当前兼容层索引；已知 subtree 例外为空；新增例外登记格式 |
| `docs/repository-maintenance.md` | 上游同步、no-op、冲突恢复、验证、回滚、部署确认门 |

根级 `README.md` 和 `docs/deployment.md` 必须把 `docker-compose.yaml` 说清楚：上游示例已移到 `upstream/open-webui/docker-compose.yaml`，根级稳定部署入口只认 `docker-compose.yml`。

验证点：

```bash
git diff --check
rg -n "upstream/open-webui|ghcr.io/open-webui/open-webui:main|open-webui_open-webui|3000:8080|git-subtree-split|ENABLE_WEB_SEARCH" README.md AGENTS.md UPSTREAMS.md docs plans
```

### P5：恢复当前部署兼容层

第一阶段 `docker-compose.yml` 必须保持当前测试环境语义，不切私有镜像。

根级 `docker-compose.yml` 目标内容必须保留这些语义：

- service：`open-webui`
- container：`open-webui`
- image：`ghcr.io/open-webui/open-webui:main`
- ports：`3000:8080`
- volume：`open-webui:/app/backend/data`
- required env：`WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY:?set WEBUI_SECRET_KEY in Portainer stack environment variables}`
- Ollama：`OLLAMA_BASE_URL=http://host.docker.internal:11434`
- `extra_hosts`：`host.docker.internal:host-gateway`
- telemetry off：`SCARF_NO_ANALYTICS=true`、`DO_NOT_TRACK=true`、`ANONYMIZED_TELEMETRY=false`

`docker-compose.local.yml` 仅用于本地按私库结构构建，不能被 Portainer 测试环境默认引用。建议语义：

- service 名仍为 `open-webui`。
- build context 为根目录。
- Dockerfile 从根级 `Dockerfile` 进入，再引用 `upstream/open-webui/`。
- volume、port 和环境变量与 stable compose 一致。

根级 `Dockerfile` 第一阶段建议保持薄包装：

```dockerfile
FROM ghcr.io/open-webui/open-webui:main
```

只有出现真实私有 runtime patch 时，才扩展为多阶段构建或 post-build patch，并同步修改 `docs/compatibility-layer.md`。

验证点：

```bash
test -f docker-compose.yml
docker compose config --quiet
docker compose -f docker-compose.yml -f docker-compose.local.yml config --quiet
rg -n '"3000:8080"|open-webui:/app/backend/data|ghcr.io/open-webui/open-webui:main' docker-compose.yml
docker compose config | rg -n 'published: "3000"|target: 8080|source: open-webui|target: /app/backend/data|image: ghcr.io/open-webui/open-webui:main'
git diff --check
```

### P6：Web Search / hosted tool 兼容层规划

本轮用户问题暴露的搜索能力，应在兼容层表达，不直接改上游业务代码。

最小路径：

- 在 `docs/deployment.md` 记录 Open WebUI Web Search 的五个 gate：全局 `ENABLE_WEB_SEARCH`、搜索引擎、provider key、用户权限、模型 capability/default feature。
- 在 `compat/config/web-search.env.example` 给出可选环境变量模板，但不提交真实 key。
- 在 `docker-compose.yml` 中只放安全的、默认关闭或无 secret 的开关；需要 secret 的 provider key 由 Portainer stack environment 注入。
- 推荐先接一个明确搜索 provider，例如已有内网 SearXNG；没有内网服务时，再在 Brave/Tavily/Jina 中选一个。

OpenAI 官方 `web_search` 路径：

- 先确认当前 upstream 是否已支持 Responses API hosted tool 透传。
- 如果不支持，优先做 Open WebUI pipe / function / adapter，并放在 `compat/` 或部署配置中。
- 如果必须改 `upstream/open-webui/backend/`，先在 `docs/compatibility-layer.md` 登记 subtree 例外，再加最小补丁和回归测试。

验证点：

```bash
rg -n "ENABLE_WEB_SEARCH|WEB_SEARCH_ENGINE|web_search|Responses API|hosted tool" docker-compose*.yml docs compat upstream/open-webui/backend/open_webui
```

### P7：同步脚本

新增 `scripts/sync-upstream.sh` 和 `scripts/sync-upstream.ps1`，行为参考 `CLIProxyAPI`，但 no-op 判断不能简单比较 `git subtree split` 生成的 commit 与 upstream head。因为 `--squash` 后 split commit 可能不是 upstream 原始 commit。

正确基线来源：

- 读取最新 subtree merge/squash commit message 中的 `git-subtree-split: <sha>`。
- 将该 `<sha>` 与 `git rev-parse upstream-open-webui/main` 比较。
- 两者相同则 no-op。
- 两者不同才进入 `git subtree pull --prefix=upstream/open-webui upstream-open-webui main --squash`。

Bash 脚本关键逻辑：

```bash
latest_split="$(
  git log --grep='git-subtree-dir: upstream/open-webui' --format=%B -n 1 |
    sed -n 's/^git-subtree-split: //p' |
    tail -n 1
)"
remote_head="$(git rev-parse upstream-open-webui/main)"

if [[ -z "$latest_split" ]]; then
  echo "Cannot find git-subtree-split for upstream/open-webui." >&2
  exit 1
fi

if [[ "$latest_split" == "$remote_head" ]]; then
  echo "No upstream delta: open-webui/open-webui@$remote_head"
  exit 0
fi

git log --oneline "$latest_split..$remote_head"
git subtree pull --prefix=upstream/open-webui upstream-open-webui main --squash
```

脚本完整行为：

1. 检查工作树干净。
2. 确认 `upstream-open-webui` remote 存在，不存在则提示命令，不静默猜测。
3. `git fetch upstream-open-webui main --no-tags`。
4. 读取最新 `git-subtree-split`。
5. 对比 remote head；无 delta 时 no-op，不构建、不提交、不推送。
6. 有 delta 时打印 commit range，再执行 subtree pull。
7. 执行 `scripts/verify-compat.sh`。
8. 输出需要人工检查和提交的文件。

`scripts/verify-compat.sh` 最小行为：

```bash
#!/usr/bin/env bash
set -euo pipefail
git diff --check
docker compose config --quiet
rg -n "open-webui_open-webui|3000:8080|ghcr.io/open-webui/open-webui:main|upstream/open-webui" README.md UPSTREAMS.md docs plans docker-compose.yml
```

PowerShell 版本保持同等语义，优先用于 Windows 原生命令环境。

验证点：

```bash
bash scripts/sync-upstream.sh
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/sync-upstream.ps1
bash scripts/verify-compat.sh
```

冲突处理规则：

- 冲突在 `upstream/open-webui/` 内：默认优先上游，除非是已登记 subtree 例外。
- 冲突在根级 `docker-compose.yml`、`compat/`、`scripts/`、`docs/`：优先保留 IndieArk 兼容层语义。
- 同步后如果出现上游生成资产或格式噪声，只提交真实 upstream delta 和必要兼容层修复。

### P8：本地验收链

结构迁移后至少执行：

```bash
git status --short --branch
git diff --check
docker compose config --quiet
bash scripts/verify-compat.sh
bash scripts/sync-upstream.sh
```

`scripts/sync-upstream.sh` 在当前基线下应输出 no-op；如果它尝试 pull，说明 subtree 基线判断错误，必须修脚本后再继续。

如果根级私有镜像或 upstream 源码被实际改动，再执行：

```bash
cd upstream/open-webui
npm ci --force
npm run check
npm run test:frontend
npm run build
```

后端改动再执行：

```bash
cd upstream/open-webui
python -m compileall backend/open_webui
ruff check backend
```

如果只是保持 Compose 直接使用 upstream GHCR 镜像，不强制本地完整构建；但必须跑 `docker compose config --quiet`。

提交建议：

```bash
git status --short
git add README.md AGENTS.md UPSTREAMS.md .gitignore Dockerfile docker-compose.yml docker-compose.local.yml compat scripts docs plans
git commit -m "chore: split open-webui upstream and compatibility layer"
```

如果 P2 的 `git subtree add` 已经单独生成提交，则最终历史建议至少有三类提交：

1. `docs: plan open-webui compatibility layer migration`
2. subtree add 生成的 `Squashed 'upstream/open-webui/' content ...`
3. `chore: split open-webui upstream and compatibility layer`

### P9：测试环境部署与验证

部署不是本计划阶段内容。执行迁移并推送后，测试环境 Portainer 动作必须单独确认。

部署前只读核验：

- 当前 Portainer stack 使用的 compose 内容。
- 当前容器 image、labels、created time。
- 当前 Docker volume 是否仍为 `open-webui_open-webui`。
- `/app/backend/data` 是否仍是数据挂载点。

部署后只读验证：

- 页面可访问。
- 登录状态和用户数据未丢。
- Ollama 连接仍可用。
- Web Search 若本轮启用，验证一个公开查询并查看 sources。
- 容器日志无迁移错误。

部署确认门：

- 如果 `docker-compose.yml` 仍使用 `ghcr.io/open-webui/open-webui:main`，理论上只是 Portainer stack 配置重应用，仍需确认后再执行。
- 如果切到 `ghcr.io/indieark/open-webui:*`，必须先有镜像构建记录、image digest、回滚 tag 和本地 smoke 结果。
- 不允许在没有数据备份确认的情况下改变 volume 名称、project 名或 container 内挂载路径。

## 回滚方法

代码结构回滚：

- 如果迁移尚未合并，直接删除迁移分支。
- 如果已提交但未推送，`git revert <migration-commit>`，不要 reset 共享历史。
- 如果已推送，创建回滚 PR / revert commit，恢复到 `3960faf1d6062cea99fe269f141cc41e1f284b0b` 语义。

部署回滚：

- Portainer stack 恢复到迁移前 compose。
- 镜像 tag 恢复到迁移前运行值：`ghcr.io/open-webui/open-webui:main`。
- 不删除 `open-webui_open-webui` Docker volume。
- 禁止执行 `docker compose down -v`。

## 执行清单

- [ ] P0 基线确认完成。
- [ ] P1 执行分支和计划保护点完成。
- [ ] P2 官方上游 subtree 导入完成，并确认 `git-subtree-split` 基线。
- [ ] P3 根部上游文件清理完成，只保留私库兼容层。
- [ ] P4 根级文档和维护规则骨架完成。
- [ ] P5 当前 Portainer 部署语义恢复完成。
- [ ] P6 Web Search / hosted tool 兼容层方案确认。
- [ ] P7 同步脚本完成并能 no-op。
- [ ] P8 本地验收链通过。
- [ ] P9 测试环境只读核验和部署确认另行完成。

## 决策点

1. 稳定部署镜像是否继续直接使用 `ghcr.io/open-webui/open-webui:main`，还是迁移后切到 `ghcr.io/indieark/open-webui:main`。
   - 建议：结构迁移第一阶段必须继续保持当前测试环境语义；只有加入私有 runtime 补丁后再切私有镜像。
2. Web Search 先接哪个 provider。
   - 建议：如果已有内网 SearXNG，优先 SearXNG；否则选 Brave/Tavily/Jina 中成本和密钥管理最清晰的一个。
3. 是否需要 OpenAI 官方 `web_search` hosted tool 适配。
   - 建议：先验证 upstream 是否已支持 Responses API hosted tool 透传；不支持时单独立计划，不混进结构迁移。
4. 是否要在执行迁移前只读核验测试环境 Portainer。
   - 建议：执行代码结构迁移前至少保留本计划中的测试环境快照；切换镜像、端口、project 名或 compose 前必须重新核验。
