# 超级工作台 · 总览页 v2 视觉规范

> 设计师：画眉 · 2026-10-29  
> 承接：`design-spec.md` token · 参考：`/workspace/preview/overview-v3.png` · `OverviewView.swift`  
> 目标：浅色白底、层次与留白更高级；KPI / 任务 / 邮件 / 员工四块更有设计感。

---

## 1. Token 继承与 v2 增补

沿用 v1 的 `--sw-*` 基础变量，总览页额外增加：

```css
:root {
  /* —— 继承 v1（勿改） —— */
  --sw-page-bg: #F6F7F8;
  --sw-card-bg: #FFFFFF;
  --sw-sidebar-bg: #F0F1F3;
  --sw-border: rgba(0, 0, 0, 0.08);
  --sw-border-soft: rgba(0, 0, 0, 0.06);
  --sw-border-group: rgba(0, 0, 0, 0.10);
  --sw-text: #111111;
  --sw-text-secondary: #737373;
  --sw-text-muted: #8A8A8E;
  --sw-accent: #111111;
  --sw-focus: #3B82F6;
  --sw-radius-card: 28px;
  --sw-radius-group: 20px;
  --sw-radius-panel: 16px;
  --sw-radius-badge: 8px;
  --sw-radius-pill: 999px;
  --sw-shadow-card: 0 8px 20px rgba(0, 0, 0, 0.06);
  --sw-shadow-card-hover: 0 16px 28px rgba(0, 0, 0, 0.12);
  --sw-font: system-ui, -apple-system, "SF Pro Text", "Segoe UI", "PingFang SC",
             "Hiragino Sans GB", "Microsoft YaHei", sans-serif;

  /* —— v2 总览增补 —— */
  --sw-shadow-elevated: 0 12px 40px rgba(17, 17, 17, 0.06), 0 2px 8px rgba(17, 17, 17, 0.04);
  --sw-shadow-kpi: 0 4px 16px rgba(17, 17, 17, 0.04);
  --sw-radius-kpi: 18px;
  --sw-radius-section: 24px;

  /* KPI 微渐变底（极淡，保持浅色） */
  --sw-grad-blue: linear-gradient(145deg, #FFFFFF 0%, #F0F6FF 100%);
  --sw-grad-green: linear-gradient(145deg, #FFFFFF 0%, #F0FDF6 100%);
  --sw-grad-amber: linear-gradient(145deg, #FFFFFF 0%, #FFF8ED 100%);
  --sw-grad-rose: linear-gradient(145deg, #FFFFFF 0%, #FFF1F2 100%);
  --sw-grad-violet: linear-gradient(145deg, #FFFFFF 0%, #F5F3FF 100%);

  /* 图标容器色 */
  --sw-icon-blue: #EFF6FF;
  --sw-icon-blue-fg: #2563EB;
  --sw-icon-green: #ECFDF5;
  --sw-icon-green-fg: #059669;
  --sw-icon-amber: #FFFBEB;
  --sw-icon-amber-fg: #D97706;
  --sw-icon-rose: #FFF1F2;
  --sw-icon-rose-fg: #E11D48;
  --sw-icon-violet: #F5F3FF;
  --sw-icon-violet-fg: #7C3AED;

  /* 邮件紧急度色条 */
  --sw-urgency-high: #EF4444;      /* 高 */
  --sw-urgency-mid: #F59E0B;       /* 中 */
  --sw-urgency-low: #94A3B8;       /* 低 */
  --sw-urgency-high-bg: #FEF2F2;
  --sw-urgency-mid-bg: #FFFBEB;
  --sw-urgency-low-bg: #F8FAFC;

  /* 环形进度轨 */
  --sw-ring-track: #E8ECF0;
  --sw-ring-contract: #3B82F6;
  --sw-ring-paid: #10B981;

  /* 总览字号 */
  --sw-fs-kpi: 28px;          /* 700 · tabular-nums */
  --sw-fs-kpi-sm: 22px;
  --sw-fs-section: 18px;      /* 700 */
  --sw-fs-label: 12px;        /* 600 */
  --sw-fs-detail: 11px;       /* 400 muted */

  /* 断点（内容区宽度，不含侧栏） */
  --sw-bp-1280: 1280px;
  --sw-bp-1440: 1440px;
  --sw-bp-1920: 1920px;
  --sw-bp-ultrawide: 2560px;
}
```

---

## 2. 全宽自适应栅格

侧栏固定 **260px**（`SWTheme.sidebarWidth`）。下表「内容宽」≈ 视口 − 侧栏 − 左右边距。

| 视口 | 内容区边距 | Gutter | 区块间距 | KPI 列 | 目标完成率列 | 任务看板列 | 邮件列 | 员工组内卡 min |
|------|------------|--------|----------|--------|--------------|------------|--------|----------------|
| **1280** | 24px | 12px | 20px | 2→4（自适应） | 2 | 4（可横滑） | 1 | 160px |
| **1440** | 32px | 14px | 24px | 4 | 2–4 | 4 | 1–2 | 160px |
| **1920** | 40px | 16px | 28px | 5 | 4 | 4 | 2 | 180px |
| **≥2560** | 48px；内容 `max-width: 1680px` 居中 | 20px | 32px | 5 | 4 | 4 | 2 | 200px |

### 2.1 CSS 骨架

```css
.overview-main {
  padding: 28px 32px 64px;
  max-width: 100%;
}
.overview-stack {
  display: flex;
  flex-direction: column;
  gap: 24px;
}

/* KPI 存量行 */
.kpi-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
  gap: 12px;
}

/* 目标完成率 */
.goal-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 12px;
}

/* 任务四列 */
.kanban-row {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

/* 邮件 */
.email-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 10px;
}

@media (max-width: 1279px) {
  .overview-main { padding: 20px 24px 56px; }
  .kanban-row {
    grid-template-columns: repeat(4, minmax(180px, 1fr));
    overflow-x: auto;
  }
}
@media (min-width: 1440px) {
  .overview-main { padding: 28px 32px 64px; }
  .overview-stack { gap: 24px; }
  .kpi-grid { gap: 14px; grid-template-columns: repeat(auto-fill, minmax(170px, 1fr)); }
}
@media (min-width: 1920px) {
  .overview-main { padding: 32px 40px 72px; }
  .overview-stack { gap: 28px; }
  .kpi-grid { gap: 16px; grid-template-columns: repeat(5, 1fr); }
  .goal-grid { grid-template-columns: repeat(4, 1fr); gap: 16px; }
  .email-grid { grid-template-columns: 1fr 1fr; gap: 14px; }
  .kanban-row { gap: 16px; }
}
@media (min-width: 2560px) {
  .overview-main {
    padding: 40px 48px 80px;
    max-width: calc(1680px + 96px);
    margin-inline: auto;
  }
  .overview-stack { gap: 32px; }
  .kpi-grid, .goal-grid, .kanban-row { gap: 20px; }
}

/* 员工看板：组壳外层随宽重排（同 v1） */
.roster-groups-ov {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 16px;
}
@media (min-width: 1920px) {
  .roster-groups-ov { grid-template-columns: repeat(auto-fill, minmax(400px, 1fr)); gap: 20px; }
}
```

### 2.2 重排说明

1. **1280**：KPI 以 `minmax(160)` auto-fill，常见 2×3 或 一行 4；任务四列偏窄时可横向滚动，禁止挤成两行破坏看板语义。  
2. **1440**：KPI 稳 4–5 列；目标卡 2–4；任务四列舒适。  
3. **1920**：KPI 固定 5 列对齐「存量五卡」；目标 4 列；邮件双列展开重要信。  
4. **超宽**：内容区锁 1680，避免无限拉伸导致行距空洞；gutter 提到 20。

---

## 3. 区块外壳（Section Shell）

四块共用白底大壳，比 v3「灰底嵌卡」更有浮起感：

```css
.section-shell {
  background: var(--sw-card-bg);
  border: 1px solid var(--sw-border-group);
  border-radius: var(--sw-radius-section);
  padding: 20px 22px 22px;
  box-shadow: var(--sw-shadow-elevated);
}
.section-shell__head {
  display: flex; align-items: center; gap: 10px;
  margin-bottom: 6px;
}
.section-shell__title {
  margin: 0; font-size: var(--sw-fs-section); font-weight: 700; letter-spacing: -0.01em;
}
.section-shell__badge {
  font-size: 11px; font-weight: 700;
  padding: 2px 8px; border-radius: 999px;
  background: rgba(0,0,0,.06); color: var(--sw-text-muted);
}
.section-shell__meta {
  font-size: 12px; color: var(--sw-text-muted); margin-bottom: 16px;
}
.section-subhead {
  font-size: 12px; font-weight: 600; color: var(--sw-text-secondary);
  margin: 16px 0 10px;
}
```

---

## 4. 网站项目 KPI 卡（精致化）

### 4.1 结构

```
┌────────────────────────────┐
│ [图标]              ↗ 环图 │
│ ¥67,600                    │  ← 28px Bold tabular
│ 合同总额                   │  ← 12px Semibold
│ 全库 Σ totalAmount         │  ← 11px muted
│ ▁▂▃▅▇ mini spark（可选）   │
└────────────────────────────┘
```

### 4.2 样式

```css
.kpi-card {
  position: relative;
  background: var(--sw-grad-blue); /* 按语义换色 */
  border: 1px solid var(--sw-border-soft);
  border-radius: var(--sw-radius-kpi);
  padding: 16px 16px 14px;
  box-shadow: var(--sw-shadow-kpi);
  min-height: 118px;
  overflow: hidden;
}
.kpi-card::after {
  /* 右上角极淡光晕，增加层次，不抢数据 */
  content: "";
  position: absolute; top: -40%; right: -20%;
  width: 120px; height: 120px; border-radius: 50%;
  background: radial-gradient(circle, rgba(59,130,246,.08), transparent 70%);
  pointer-events: none;
}
.kpi-card--paid   { background: var(--sw-grad-green); }
.kpi-card--unpaid { background: var(--sw-grad-amber); }
.kpi-card--overdue{ background: var(--sw-grad-rose); }
.kpi-card--count  { background: var(--sw-grad-violet); }

.kpi-icon {
  width: 32px; height: 32px; border-radius: 10px;
  display: grid; place-items: center;
  font-size: 14px; font-weight: 700;
  background: var(--sw-icon-blue); color: var(--sw-icon-blue-fg);
  margin-bottom: 12px;
}
.kpi-card--paid .kpi-icon   { background: var(--sw-icon-green); color: var(--sw-icon-green-fg); }
.kpi-card--unpaid .kpi-icon { background: var(--sw-icon-amber); color: var(--sw-icon-amber-fg); }
.kpi-card--overdue .kpi-icon{ background: var(--sw-icon-rose); color: var(--sw-icon-rose-fg); }
.kpi-card--count .kpi-icon  { background: var(--sw-icon-violet); color: var(--sw-icon-violet-fg); }

.kpi-value {
  font-size: var(--sw-fs-kpi); font-weight: 700;
  font-variant-numeric: tabular-nums; letter-spacing: -0.02em;
  line-height: 1.15; color: var(--sw-text);
}
.kpi-label { font-size: var(--sw-fs-label); font-weight: 600; margin-top: 6px; }
.kpi-detail { font-size: var(--sw-fs-detail); color: var(--sw-text-muted); margin-top: 4px; }
```

### 4.3 环形进度（目标完成率）

直径 **56px**，轨宽 **5px**，中心显示百分比（13px / 700）。

```css
.ring {
  width: 56px; height: 56px; border-radius: 50%;
  background: conic-gradient(var(--sw-ring-contract) calc(var(--p) * 1%), var(--sw-ring-track) 0);
  display: grid; place-items: center;
  flex-shrink: 0;
}
.ring::before {
  content: ""; width: 44px; height: 44px; border-radius: 50%; background: #fff;
}
.ring-label {
  position: absolute; font-size: 12px; font-weight: 700;
  font-variant-numeric: tabular-nums;
}
.goal-card {
  display: flex; align-items: center; gap: 14px;
  background: #fff;
  border: 1px solid var(--sw-border-soft);
  border-radius: var(--sw-radius-kpi);
  padding: 14px 16px;
  box-shadow: var(--sw-shadow-kpi);
  background-image: var(--sw-grad-blue);
}
```

SwiftUI：`Gauge` / 自定义 `Circle().trim` 描边即可。

### 4.4 迷你趋势（可选）

高度 24px，5–7 个竖条，圆角 2px；颜色取图标前景色 35% 透明。无历史数据时隐藏，勿用假数据。

### 4.5 数据质量条

沿用橙底：`background: #FFEDD5; color: #C2410C; radius: 10; padding: 10×12`。

---

## 5. 任务看板精致化

```css
.kanban-col {
  background: var(--sw-page-bg);
  border: 1px solid var(--sw-border-soft);
  border-radius: 14px;
  padding: 12px;
  min-height: 200px;
}
.kanban-col__head {
  display: flex; align-items: center; gap: 6px; margin-bottom: 10px;
}
.kanban-dot { width: 8px; height: 8px; border-radius: 50%; }
.kanban-dot--todo { background: #3B82F6; }
.kanban-dot--doing { background: #F59E0B; }
.kanban-dot--review { background: #8B5CF6; }
.kanban-dot--done { background: #22C55E; }

.task-chip {
  background: #fff;
  border: 1px solid var(--sw-border-soft);
  border-radius: 12px;
  padding: 10px 10px 8px;
  box-shadow: 0 2px 6px rgba(0,0,0,.03);
  margin-bottom: 8px;
}
.task-chip__title { font-size: 12px; font-weight: 600; line-height: 1.35; }
.task-chip__meta { font-size: 10px; color: var(--sw-text-muted); margin-top: 4px; }
```

列头字重 600；数量用 muted 11px。单列最多展示 8 条，溢出滚动。

---

## 6. 邮件总结卡 · 紧急度色条

左侧 **4px** 色条贯穿卡片；紧急度文字同色。

| 紧急度 | 色条 / 文字 | 浅底（可选 hover） |
|--------|-------------|-------------------|
| **高** | `#EF4444` | `#FEF2F2` |
| **中** | `#F59E0B` | `#FFFBEB` |
| **低** | `#94A3B8` | `#F8FAFC` |

```css
.email-card {
  display: grid;
  grid-template-columns: 4px 1fr;
  background: #fff;
  border: 1px solid var(--sw-border-soft);
  border-radius: 14px;
  overflow: hidden;
  box-shadow: var(--sw-shadow-kpi);
}
.email-card__bar { background: var(--sw-urgency-mid); }
.email-card--high .email-card__bar { background: var(--sw-urgency-high); }
.email-card--high { background: linear-gradient(90deg, var(--sw-urgency-high-bg), #fff 28%); }
.email-card--mid .email-card__bar { background: var(--sw-urgency-mid); }
.email-card--low .email-card__bar { background: var(--sw-urgency-low); }

.email-card__body { padding: 12px 14px; }
.email-card__top {
  display: flex; justify-content: space-between; align-items: center; gap: 8px;
}
.email-card__company { font-size: 12px; font-weight: 700; }
.email-card__urgency {
  font-size: 11px; font-weight: 700;
}
.email-card--high .email-card__urgency { color: var(--sw-urgency-high); }
.email-card--mid .email-card__urgency { color: var(--sw-urgency-mid); }
.email-card--low .email-card__urgency { color: var(--sw-urgency-low); }
.email-card__subject { font-size: 13px; font-weight: 600; margin-top: 4px; }
.email-card__summary { font-size: 12px; color: var(--sw-text-secondary); margin-top: 4px; }
.email-card__todo {
  font-size: 11px; color: var(--sw-proj-progress-fg, #1D4ED8);
  margin-top: 6px; font-weight: 500;
}
```

日汇总头：日期 Bold + 胶囊「新 / 清理 / 待回」（新→蓝底、清理→灰底、待回→橙底）。

---

## 7. 员工看板

- 组壳 + 紧凑员工卡：**完全沿用 v1**（`group-shell`、头像外 92 / 内 84、白底、圆角 28）。  
- **头像不可改尺寸、不可改圆形裁切。**  
- 总览内可不展示全部组：可默认折叠「仅管理中枢 + 网站项目 + 视觉设计」，或全部展开但组用 `roster-groups-ov` 自适应。

---

## 8. 层次与高级感原则

1. **两层阴影**：区块壳用 `--sw-shadow-elevated`；内嵌 KPI/任务/邮件用更轻的 `--sw-shadow-kpi`。  
2. **微渐变只作底色**：白→极淡色，对比度保持浅色主题，禁止大面积饱和渐变。  
3. **字重阶梯**：区块标题 700 → KPI 数字 700 → 标签 600 → 说明 400 muted。  
4. **留白**：区块内上下 20–22；KPI 内图标与数字间距 12；区块之间 ≥24。  
5. **数字**：一律 `tabular-nums` / monospacedDigit，金额千分位。

---

## 9. 实现检查清单

1. [ ] 四断点边距 / gutter / 列数按表实现（含超宽 max-width 1680）。  
2. [ ] KPI 卡：图标 + 大数字 + 微渐变 +（目标卡）环形进度。  
3. [ ] 任务四列色点与 chip 阴影。  
4. [ ] 邮件左侧紧急度色条：高红 / 中橙 / 低灰。  
5. [ ] 员工头像规格不变。  
6. [ ] 不引入暗色 `#0f1115` 体系。

---

## 10. 交付

| 文件 | 说明 |
|------|------|
| `design-spec-v2.md` | 本规范 |
| `mockup-v2.html` | 静态总览效果 |
| `mockup-v2-1440.png` | 1440 宽截图 |
| `mockup-v2-1920.png` | 1920 宽截图 |
| `mood-overview-v2.png` | 可选氛围图（生成成功才有） |

路径：`bots/视觉设计/设计师/deliverables/workbench-ui/`
