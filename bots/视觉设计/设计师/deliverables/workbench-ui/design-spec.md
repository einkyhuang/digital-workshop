# 超级工作台 · 视觉设计规范（改版）

> 设计师：画眉 · 交付给开发（大可可）· 2026-10-29  
> 参考：`/workspace/preview/cards-v6.png`、`webprojects.png`，以及现有 `Theme.swift` / `EmployeeCard.swift` / `style.css`

本规范只约定**员工档案紧凑组布局**、**网站项目卡片视图**、**详情弹窗**三块。卡片白底、圆形头像/图标不可改。

---

## 1. 设计 Token（CSS 变量，可直接粘贴）

```css
:root {
  /* 表面 */
  --sw-page-bg: #F6F7F8;          /* Theme.pageBg ≈ rgb(0.965,0.968,0.973) */
  --sw-card-bg: #FFFFFF;
  --sw-sidebar-bg: #F0F1F3;
  --sw-overlay: rgba(15, 17, 21, 0.45);

  /* 边框 / 分割 */
  --sw-border: rgba(0, 0, 0, 0.08);
  --sw-border-soft: rgba(0, 0, 0, 0.06);
  --sw-border-group: rgba(0, 0, 0, 0.10);

  /* 文字 */
  --sw-text: #111111;
  --sw-text-secondary: #737373;  /* 副标题 / role */
  --sw-text-muted: #8A8A8E;      /* 编号字、组标签 */
  --sw-text-inverse: #FFFFFF;

  /* 强调 */
  --sw-accent: #111111;          /* 主按钮、编号徽章 */
  --sw-accent-hover: #000000;
  --sw-focus: #3B82F6;

  /* 状态 · 员工 */
  --sw-status-online: #22C55E;   /* 在线 */
  --sw-status-busy: #F59E0B;     /* 忙碌 */
  --sw-status-idle: #9CA3AF;     /* 空闲 */

  /* 状态 · 网站项目（胶囊） */
  --sw-proj-progress-bg: #DBEAFE;
  --sw-proj-progress-fg: #1D4ED8;   /* 进行中 */
  --sw-proj-done-bg: #DCFCE7;
  --sw-proj-done-fg: #15803D;       /* 已交付 */
  --sw-proj-build-bg: #EDE9FE;
  --sw-proj-build-fg: #6D28D9;      /* 筹建中 / 功能基础建设 */
  --sw-proj-hold-bg: #FFEDD5;
  --sw-proj-hold-fg: #C2410C;       /* 挂起 / 已暂停 */

  /* 圆角 */
  --sw-radius-card: 28px;        /* 员工 / 项目主卡片 */
  --sw-radius-group: 20px;       /* 组容器 */
  --sw-radius-panel: 16px;       /* 弹窗内区块、详情面板 */
  --sw-radius-modal: 20px;       /* 弹窗外壳 */
  --sw-radius-badge: 8px;        /* 编号徽章 */
  --sw-radius-pill: 999px;       /* 胶囊 / 筛选 chip */
  --sw-radius-btn: 10px;

  /* 间距 */
  --sw-space-1: 4px;
  --sw-space-2: 8px;
  --sw-space-3: 12px;
  --sw-space-4: 16px;
  --sw-space-5: 20px;
  --sw-space-6: 24px;
  --sw-space-8: 32px;

  /* 阴影 */
  --sw-shadow-card: 0 8px 20px rgba(0, 0, 0, 0.06);
  --sw-shadow-card-hover: 0 16px 28px rgba(0, 0, 0, 0.12);
  --sw-shadow-avatar: 0 4px 12px rgba(0, 0, 0, 0.08);
  --sw-shadow-modal: 0 24px 64px rgba(0, 0, 0, 0.18);

  /* 字号字重 */
  --sw-font: system-ui, -apple-system, "SF Pro Text", "Segoe UI", "PingFang SC",
             "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
  --sw-fs-page-title: 28px;      /* font-weight: 700 */
  --sw-fs-group-title: 15px;     /* 600 */
  --sw-fs-card-name: 18px;       /* 700 · 紧凑员工卡；项目名同 */
  --sw-fs-card-sub: 12px;        /* 400 · 副标题 */
  --sw-fs-badge: 11px;           /* 700 */
  --sw-fs-pill: 11px;            /* 600 */
  --sw-fs-code: 13px;            /* 500 · 头像下编号 */
  --sw-fs-body: 13px;
  --sw-fs-caption: 12px;

  /* 断点 */
  --sw-bp-sm: 720px;
  --sw-bp-md: 1100px;
  --sw-bp-lg: 1440px;
}
```

---

## 2. 员工档案 · 紧凑组布局

### 2.1 目标

- 每个业务组放入**淡边框圆角容器**（group shell）。
- 组与组在同一行自适应排布：一行放得下几个就几个。
- **管理中枢**固定排第一（`groupsOrder[0]`）。
- 组内员工卡仍为白底圆角卡；**头像尺寸与圆形裁切不可改**（紧凑模式 84/92）。

### 2.2 组网格（推荐 CSS Grid）

```css
.roster-groups {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: var(--sw-space-4);
  align-items: start;
}

@media (min-width: 1100px) {
  .roster-groups {
    grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  }
}

@media (min-width: 1440px) {
  .roster-groups {
    grid-template-columns: repeat(auto-fill, minmax(420px, 1fr));
  }
}
```

> SwiftUI 等价：外层用 `LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 16)], spacing: 16)`；组容器内再用 `LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12)` 放员工卡。

### 2.3 组容器

```css
.group-shell {
  background: var(--sw-card-bg);
  border: 1px solid var(--sw-border-group);
  border-radius: var(--sw-radius-group);
  padding: var(--sw-space-3) var(--sw-space-3) var(--sw-space-4);
  box-shadow: none; /* 组壳不加重阴影，避免与卡片叠影 */
}

.group-shell__head {
  display: flex;
  align-items: center;
  gap: var(--sw-space-2);
  margin-bottom: var(--sw-space-3);
  padding: 0 var(--sw-space-1);
}

.group-shell__title {
  margin: 0;
  font-size: var(--sw-fs-group-title);
  font-weight: 600;
  color: var(--sw-text);
}

.group-shell__count {
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: var(--sw-radius-pill);
  background: rgba(0, 0, 0, 0.06);
  color: var(--sw-text-muted);
}

.group-shell__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 12px;
}
```

### 2.4 员工卡（紧凑，贴合现有 EmployeeCard compact）

| 属性 | 值 |
|------|-----|
| 背景 | `#FFFFFF`（不可改深色） |
| 圆角 | `28px` |
| 边框 | `1px solid rgba(0,0,0,0.06)` |
| 阴影 | `0 8px 20px rgba(0,0,0,0.06)`；hover `0 16px 28px rgba(0,0,0,0.12)` |
| 内边距 | 上 12 / 左右 14 / 下 14 |
| 最小高度 | `240px` |
| 头像外圈 | `92×92` 白底圆 + shadow |
| 头像图 | `84×84` 圆形裁切 + 白描边 3–4px（**不可改**） |
| 编号字 | 13px / 500 / `#8A8A8E`，头像下 10px |
| 状态点 | 5px 圆，在线 `#22C55E` |
| 编号徽章 | 黑底白字 11px/700，圆角 8，padding 5×10 |
| 组标签 | 11px / 500 / `#8A8A8E`，右对齐 |
| 姓名 | 18px / 700 |
| 副标题 | 12px / `#737373` |

```css
.emp-card {
  background: var(--sw-card-bg);
  border: 1px solid var(--sw-border-soft);
  border-radius: var(--sw-radius-card);
  box-shadow: var(--sw-shadow-card);
  padding: 12px 14px 14px;
  min-height: 240px;
  display: flex;
  flex-direction: column;
  align-items: center;
  transition: transform .18s ease, box-shadow .18s ease;
}
.emp-card:hover {
  transform: translateY(-3px) scale(1.02);
  box-shadow: var(--sw-shadow-card-hover);
}
.emp-avatar-wrap {
  width: 92px; height: 92px; border-radius: 50%;
  background: #fff; display: grid; place-items: center;
  box-shadow: var(--sw-shadow-avatar);
}
.emp-avatar {
  width: 84px; height: 84px; border-radius: 50%;
  object-fit: cover; border: 3px solid #fff;
}
.emp-pill {
  background: var(--sw-accent); color: #fff;
  font-size: var(--sw-fs-badge); font-weight: 700;
  padding: 5px 10px; border-radius: var(--sw-radius-badge);
}
```

### 2.5 组顺序

固定优先：`管理中枢` → `网站项目` → `服装外贸` → `运营管理` → `战略决策` → `视觉设计` → …（沿用 `groupsOrder`）。空组不渲染。

---

## 3. 网站项目 · 卡片视图（与员工卡统一）

从列表改成网格卡片，视觉语言对齐员工卡：白底、大圆角、圆形图标、编号徽章、状态胶囊、加粗项目名 + 副标题。

### 3.1 网格

```css
.project-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 14px;
}
```

### 3.2 项目卡结构

```
┌─────────────────────────┐
│      (圆形图标 64)       │
│         W 12             │  ← 浅灰编号字
│   ● ● ●                  │
│  [W12]        [进行中]    │  ← 黑编号徽章 + 状态胶囊
│  Trailnxt                │  ← 18px Bold
│  客户 · React            │  ← 12px muted
└─────────────────────────┘
```

```css
.proj-card {
  background: var(--sw-card-bg);
  border: 1px solid var(--sw-border-soft);
  border-radius: var(--sw-radius-card);
  box-shadow: var(--sw-shadow-card);
  padding: 18px 16px 16px;
  min-height: 220px;
  display: flex;
  flex-direction: column;
  align-items: center;
  cursor: pointer;
  transition: transform .18s ease, box-shadow .18s ease;
}
.proj-card:hover {
  transform: translateY(-3px) scale(1.02);
  box-shadow: var(--sw-shadow-card-hover);
}
.proj-card.is-selected {
  outline: 2px solid var(--sw-focus);
  outline-offset: 2px;
}

.proj-icon {
  width: 64px; height: 64px; border-radius: 50%;
  display: grid; place-items: center;
  font-size: 22px; font-weight: 700; color: #fff;
  box-shadow: var(--sw-shadow-avatar);
  /* 按品类给渐变，示例： */
  background: linear-gradient(135deg, #3B82F6, #8B5CF6);
}

.proj-code {
  margin-top: 10px;
  font-size: var(--sw-fs-code);
  font-weight: 500;
  color: var(--sw-text-muted);
  letter-spacing: 0.04em;
}

.proj-meta-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  margin-top: auto;
  padding-top: 16px;
  gap: 8px;
}

.proj-name {
  width: 100%;
  text-align: left;
  font-size: var(--sw-fs-card-name);
  font-weight: 700;
  color: var(--sw-text);
  margin-top: 10px;
  line-height: 1.25;
}
.proj-sub {
  width: 100%;
  text-align: left;
  font-size: var(--sw-fs-card-sub);
  color: var(--sw-text-secondary);
  margin-top: 4px;
}
```

### 3.3 编号徽章 & 状态胶囊

```css
.proj-badge {
  background: var(--sw-accent);
  color: #fff;
  font-size: var(--sw-fs-badge);
  font-weight: 700;
  padding: 5px 10px;
  border-radius: var(--sw-radius-badge);
  flex-shrink: 0;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: var(--sw-fs-pill);
  font-weight: 600;
  padding: 3px 10px;
  border-radius: var(--sw-radius-pill);
  white-space: nowrap;
}
.status-pill--progress { background: var(--sw-proj-progress-bg); color: var(--sw-proj-progress-fg); }
.status-pill--done     { background: var(--sw-proj-done-bg);     color: var(--sw-proj-done-fg); }
.status-pill--build    { background: var(--sw-proj-build-bg);    color: var(--sw-proj-build-fg); }
.status-pill--hold     { background: var(--sw-proj-hold-bg);     color: var(--sw-proj-hold-fg); }
```

| 展示文案 | category / status | 类名 | 背景 | 前景 |
|---------|-------------------|------|------|------|
| 进行中 | `进行中` / `in_progress` | `--progress` | `#DBEAFE` | `#1D4ED8` |
| 已交付 | `已交付` / `delivered` | `--done` | `#DCFCE7` | `#15803D` |
| 筹建中 | `功能基础建设` / `infrastructure` | `--build` | `#EDE9FE` | `#6D28D9` |
| 挂起 | `已暂停/挂了` / `inactive` | `--hold` | `#FFEDD5` | `#C2410C` |

胶囊内可附进度：`进行中 · 55%`（字重仍 600，百分比同色）。

### 3.4 圆形图标色板（按首字母/品类轮换）

| 索引 | 渐变 |
|------|------|
| 0 | `#3B82F6 → #8B5CF6` |
| 1 | `#06B6D4 → #3B82F6` |
| 2 | `#F59E0B → #EF4444` |
| 3 | `#10B981 → #059669` |
| 4 | `#EC4899 → #8B5CF6` |

图标内显示项目名首字母（大写拉丁）或中文首字，22px / 700 / 白。

---

## 4. 详情弹窗版式

用于员工详情、项目详情（替代当前整页跳转或窄侧栏编辑 sheet 时可复用）。

### 4.1 遮罩与外壳

```css
.modal-overlay {
  position: fixed;
  inset: 0;
  background: var(--sw-overlay);
  backdrop-filter: blur(4px);
  display: grid;
  place-items: center;
  z-index: 1000;
  padding: 24px;
}

.modal {
  width: min(920px, 100%);
  max-height: min(860px, calc(100vh - 48px));
  background: var(--sw-page-bg);
  border-radius: var(--sw-radius-modal);
  box-shadow: var(--sw-shadow-modal);
  border: 1px solid var(--sw-border);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

@media (max-width: 720px) {
  .modal { width: 100%; max-height: 100%; border-radius: 16px 16px 0 0; align-self: end; }
}
```

### 4.2 分区

| 区 | 高度/行为 | 内容 |
|----|-----------|------|
| **头部** | 固定，padding 20×24 | 左：头像/图标 56 + 标题区；右：关闭按钮 |
| **正文** | `flex:1; overflow:auto`，padding 0 24 24 | 信息块网格（白底 `--sw-radius-panel`） |
| **操作区** | 固定底栏，padding 14×24 | 左次要、右主按钮；顶部分割线 |

```css
.modal__header {
  display: flex;
  align-items: flex-start;
  gap: 16px;
  padding: 20px 24px;
  background: var(--sw-card-bg);
  border-bottom: 1px solid var(--sw-border-soft);
}
.modal__title {
  font-size: 20px;
  font-weight: 700;
  margin: 0;
}
.modal__subtitle {
  font-size: 12px;
  color: var(--sw-text-muted);
  margin-top: 4px;
}
.modal__close {
  margin-left: auto;
  width: 32px; height: 32px;
  border-radius: 8px;
  border: 1px solid var(--sw-border);
  background: #fff;
  color: var(--sw-text-muted);
  font-size: 18px;
  line-height: 1;
  cursor: pointer;
  display: grid; place-items: center;
}
.modal__close:hover { background: var(--sw-page-bg); color: var(--sw-text); }

.modal__body {
  flex: 1;
  overflow: auto;
  padding: 20px 24px 24px;
  display: grid;
  grid-template-columns: 1fr 320px;
  gap: 14px;
  align-content: start;
}
@media (max-width: 720px) {
  .modal__body { grid-template-columns: 1fr; }
}

.modal__section {
  background: var(--sw-card-bg);
  border: 1px solid var(--sw-border-soft);
  border-radius: var(--sw-radius-panel);
  padding: 16px;
}

.modal__footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 14px 24px;
  background: var(--sw-card-bg);
  border-top: 1px solid var(--sw-border-soft);
}

.btn {
  font-size: 13px; font-weight: 600;
  padding: 8px 14px;
  border-radius: var(--sw-radius-btn);
  border: 1px solid var(--sw-border);
  background: #fff;
  cursor: pointer;
}
.btn-primary {
  background: var(--sw-accent);
  color: #fff;
  border-color: var(--sw-accent);
}
.btn-primary:hover { background: var(--sw-accent-hover); }
```

### 4.3 交互约定

- Esc / 点遮罩空白 / 点关闭按钮 → 关闭。
- 弹窗打开时 `body { overflow: hidden }`。
- 焦点落在关闭按钮或首个可编辑字段；Tab 循环锁在弹窗内。

---

## 5. 筛选 Chip（沿用现有）

```css
.filter-chip {
  padding: 6px 12px;
  border-radius: var(--sw-radius-pill);
  border: 1px solid var(--sw-border);
  background: #fff;
  font-size: 13px;
  cursor: pointer;
}
.filter-chip.is-active {
  background: var(--sw-accent);
  color: #fff;
  border-color: var(--sw-accent);
}
```

---

## 6. 实现检查清单（给开发）

1. [ ] `RosterGridView`：组外包 `group-shell`；组级 `adaptive min 340`；组内卡 `adaptive min 160`；`管理中枢` 第一。
2. [ ] `EmployeeCard(compact: true)`：白底、头像 84/92 不变。
3. [ ] 网站项目：列表改 `project-grid` 卡片；圆形图标 + `W##` 徽章 + 状态胶囊四色。
4. [ ] 详情统一用本规范 modal（员工 / 项目可共用壳）。
5. [ ] 颜色只用本文 CSS 变量；不要引入暗色 web preview 那套 `#0f1115`。

---

## 7. 交付文件

| 文件 | 说明 |
|------|------|
| `design-spec.md` | 本规范 |
| `mockup.html` | 静态效果图（员工组 + 项目卡 + 弹窗） |
| `mockup.png` | 1440 宽截图 |

路径：`bots/视觉设计/设计师/deliverables/workbench-ui/`
