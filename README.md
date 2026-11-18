# Self-use subscription rules

个人网络规则与配置模板，位于 [Clash/config](Clash/config/)。

Stash、Mihomo 和 OpenClash 共用同一份生成配置：

`base.yml`（或 `base_mini.yml`） → `meta.yml` → `proxy-providers.yml` → 自己的 provider 配置。

Stash DNS 配置要求 iOS/tvOS 3.6+、macOS 4.3+。

离线启动前，可将已下载的 `rule_provider/` 缓存复制到客户端资源目录。
