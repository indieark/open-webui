# 兼容层

`compat/` 用于承载 IndieArk 私库兼容层中无法仅靠根级 Compose 或文档表达的内容。

当前第一阶段没有 runtime patch。稳定部署仍直接使用 `ghcr.io/open-webui/open-webui:main`。

允许放入本目录的内容：

- 环境变量模板和默认配置说明。
- Open WebUI pipe/function/adapter。
- entrypoint 或 post-build patch。
- 只属于 IndieArk 部署形态的 wrapper。

不允许放入本目录的内容：

- 真实 secret、token、key。
- 未登记原因的 upstream 源码复制件。
- 会改变测试环境数据卷或 Portainer stack 名称的脚本。
