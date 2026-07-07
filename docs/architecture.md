# 架构

本仓库采用两层结构：

```text
IndieArk root
├── upstream/open-webui/  # 官方 upstream subtree
└── root compat layer     # README, docs, scripts, compat, Compose, Dockerfile
```

## 上游层

`upstream/open-webui/` 对应 `open-webui/open-webui:main`。当前同步基线是：

```text
ecd48e2f718220a6400ecf49eafd4867a38feb10
```

默认不直接修改该目录。上游更新通过 `scripts/sync-upstream.*` 进入，并以 `git-subtree-split` 记录作为 compare-first 基线。

## 兼容层

根目录承载 IndieArk 私库设计：

- `docker-compose.yml` 保持当前 Portainer 稳定部署入口。
- `docker-compose.local.yml` 和 `Dockerfile` 仅用于本地或未来私有镜像构建。
- `compat/` 承载未来 pipe/function/adapter、配置模板或补丁。
- `scripts/` 承载同步和验证。
- `docs/` 与 `plans/` 承载维护规则和计划。

## 为什么第一阶段不切私有镜像

测试环境当前运行的是公共上游镜像：

```text
ghcr.io/open-webui/open-webui:main
```

私库现有差异主要是 Portainer/Compose 兼容层，不是运行时代码补丁。因此第一阶段切私有镜像会增加部署风险，但不会带来功能收益。只有出现真实 runtime patch，并完成构建、digest、smoke test 和回滚 tag 后，才考虑把稳定部署入口切到 `ghcr.io/indieark/open-webui:*`。
