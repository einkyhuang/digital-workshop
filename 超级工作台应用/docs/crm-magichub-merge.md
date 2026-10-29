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


## 统一侧栏（外贸工作台）

外贸模式下 **只保留一层侧栏**：

1. 顶部千问风格「超级工作台｜外贸工作台」分段不变。
2. 其下展示 **MagicHub 菜单**（驾驶舱 → … → Forwelike 专区），样式对齐工作台侧栏字号/行高。
3. MagicHub 自身 `aside` 在 `?embed=1` / `data-sw-embed` / Mac host 下隐藏。
4. 外层点击 → bridge/`__swSetTab` / `postMessage` 切 tab；MagicHub 内切 tab → `tab-changed` 回写外层高亮。

- Mac：`SidebarView` + `MagicHubNav` + `MagicHubWebView` push/sync。
- Web：`#tabs` 渲染 `MAGICHUB_NAV`；iframe `./magichub/index.html?embed=1&tab=…`。
