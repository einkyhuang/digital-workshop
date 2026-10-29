# MagicHub 完整内嵌 · 外贸工作台

## 方案

切换到「外贸工作台」时，内容区改为 **完整 MagicHub Vue UI**（驾驶舱/客户/营销/…），顶部保留工作台分段切换。

- **Mac**：`TradeMagicHubHost` + `WKWebView` 加载 `超级工作台应用/app/magichub/`；`MagicHubBridge`（WKScriptMessageHandler）替代 Electron IPC；设置与客户数据写入 `data/private/crm/settings/`（gitignore）。
- **Web 本地**：iframe 挂载 `./magichub/` + `magichub-bridge-web.js`（localStorage）。
- **Pages**：不发布客户明细；展示隐私降级说明。

## 构建

```bash
cd 超级工作台应用/crm-magichub
./build-for-workbench.sh   # 产出 app/magichub（不含大图/PDF，运行时 symlink private）
```

原目录 `/Users/ky/Desktop/网站标准/通用版外贸客户管理` **只读**，改动仅在 `crm-magichub/` 副本。
