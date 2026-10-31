# 全局模型配置

超级工作台（Mac / Web）与外贸工作台（MagicHub）共用同一份 AI 模型/API 配置。

## 存储位置（不进 git）

- macOS：`~/Library/Application Support/超级工作台/models.json`
- Linux（LAN/开发）：`~/.local/share/超级工作台/models.json`
- 浏览器回退：`localStorage["sw.global.models"]`
- Mac Keychain（按 provider id）：`com.ky.superworkbench.models` / `provider:<id>`

## 读写入口

- Swift：`SharedModelStore`；MagicHub WKWebView 经 `save-settings` / `load-settings`（key=`magichub_ai_providers` 或 `sw_global_models`）
- Electron / LAN：`global-models-store.cjs`
- Web：`app/assets/shared-models.js`

首次加载会从旧的 `magichub_ai_providers`、UserDefaults `sw.agent.*`、以及旧 Keychain 单密钥迁移。
