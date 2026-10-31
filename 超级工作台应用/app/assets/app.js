(function () {
  const LS_KEY = "digital-workshop-v2";
  const TABS = ["总览", "员工档案", "网站项目", "任务看板", "任务与日程中心", "每日总结", "每日 SEO", "客户与线索", "客户管理", "开发进度", "询盘与报价", "群聊协作", "定时巡检", "招聘规划", "规则与文档"];
  /** Plug 搜搜 field spec / 画眉 visual tokens via ../data/ui-config.json (mirrored here for static Pages). */
  const WEBSITE_UI = {
    defaultView: "list",
    omitFields: ["client_phone","client_wechat","client_email","assets_credentials"],
    listColumns: [
      {key:"name",title:"项目名称"},{key:"status",title:"状态"},{key:"client",title:"客户"},
      {key:"url",title:"网址"},{key:"framework",title:"框架"},{key:"services",title:"服务"},
      {key:"progress",title:"进度"},{key:"payment",title:"付款"},{key:"deadline",title:"服务截止"},
      {key:"owner",title:"负责人"},{key:"updated",title:"最近更新"}
    ],
    detailTabs: [
      { id: "basic", title: "基本信息" },
      { id: "client", title: "客户" },
      { id: "hosting", title: "域名和主机" },
      { id: "seo", title: "SEO 状态" },
      { id: "progress", title: "进度和里程碑" },
      { id: "notes", title: "备注和链接" }
    ],
    statusMap: {
      in_progress: { label: "进行中", category: "进行中", progress: 55, pill: "progress" },
      delivered: { label: "已交付", category: "已交付", progress: 100, pill: "done" },
      infrastructure: { label: "筹建中", category: "功能基础建设", progress: 25, pill: "build" },
      inactive: { label: "挂起", category: "已暂停/挂了", progress: 0, pill: "hold" }
    },
    p0Ids: ["robots_txt","ai_crawler_allow","sitemap_xml","ssr_readable","title_h1_meta","canonical","https_status"]
  };

  const COLS = ["待办", "进行中", "验收", "完成"];
  const state = {
    tab: "总览",
    data: null,
    selectedId: null,
    editTaskId: null,
    layerFilter: "全部",
    source: "embedded",
    targetsFile: null,
    emailDaily: [],
    expandedEmail: null,
    uiConfig: null,
    webPageSize: 40,
    webShown: 40,
    botById: {},
    botsByGroup: {},
    kpiCache: null,
  };

  function rebuildIndexes() {
    const bots = (state.data && state.data.bots) || [];
    const byId = Object.create(null);
    const byGroup = Object.create(null);
    for (const b of bots) {
      byId[b.id] = b;
      const gs = botGroups(b);
      for (const g of gs) {
        if (!byGroup[g]) byGroup[g] = [];
        byGroup[g].push(b);
      }
    }
    state.botById = byId;
    state.botsByGroup = byGroup;
    state.kpiCache = null;
  }

  function toast(msg) {
    const el = document.getElementById("toast");
    el.textContent = msg;
    el.hidden = false;
    clearTimeout(toast._t);
    toast._t = setTimeout(() => { el.hidden = true; }, 2600);
  }

  function clone(x) { return JSON.parse(JSON.stringify(x)); }

  function defaultData() {
    const emb = window.__EMBEDDED_WORKSPACE__;
    if (emb && emb.bots) return clone(emb);
    return { version: 5, bots: [], tasks: [], vacancies: [], groups: [], routines: [], rules: [], groupsOrder: [] };
  }

  function loadLocal() {
    try {
      const raw = localStorage.getItem(LS_KEY);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch (_) { return null; }
  }

  function saveLocal() {
    try {
      localStorage.setItem(LS_KEY, JSON.stringify({
        bots: state.data.bots,
        tasks: state.data.tasks,
        vacancies: state.data.vacancies,
        selectedId: state.selectedId,
        groups: state.data.groups,
        routines: state.data.routines,
        rules: state.data.rules,
      }));
    } catch (_) {}
  }


  const TAB_NAV_LABEL = {
    "总览": "总览",
    "员工档案": "员工",
    "任务看板": "看板",
    "任务与日程中心": "任务日程",
    "每日总结": "日报",
    "每日 SEO": "日SEO",
    "客户与线索": "线索",
    "客户管理": "客户",
    "开发进度": "开发",
    "询盘与报价": "询价",
    "群聊协作": "群聊",
    "定时巡检": "巡检",
    "招聘规划": "招聘",
    "规则与文档": "规则",
    "网站项目": "网站"
  };
  const MODULE_TAB = {
    overview: "总览", roster: "员工档案", tasks: "任务看板",
    scheduleCenter: "任务与日程中心", dailySummary: "每日总结", dailySeo: "每日 SEO",
    tradeLeads: "客户与线索", crmCustomers: "客户管理", tradePipeline: "开发进度", tradeQuotes: "询盘与报价",
    rooms: "群聊协作", routines: "定时巡检", hiring: "招聘规划",
    rules: "规则与文档", projects: "网站项目"
  };

  /** MagicHub menus (外贸工作台 outer sidebar). Order matches crm-magichub App.vue. */
  const MAGICHUB_NAV = [
    { id: "dashboard", name: "驾驶舱" },
    { id: "schedule", name: "日程管理" },
    { id: "customers", name: "客户管理" },
    { id: "marketing", name: "智能营销" },
    { id: "opportunities", name: "商机管理" },
    { id: "followup", name: "跟进记录" },
    { id: "samples", name: "寄样跟进" },
    { id: "quotes", name: "报价记录" },
    { id: "contracts", name: "订单合同" },
    { id: "products", name: "产品管理" },
    { id: "knowledge", name: "知识仓库" },
    { id: "company", name: "公司信息" },
    { id: "team", name: "团队管理" },
    { id: "agentRoom", name: "Agent 协同" },
    { id: "forwelike", name: "Forwelike 专区" }
  ];
  function magicHubTabId() {
    return state.magicHubTab || localStorage.getItem("sw.mhTab") || "dashboard";
  }
  function setMagicHubTab(id) {
    const tab = id || "dashboard";
    state.magicHubTab = tab;
    try { localStorage.setItem("sw.mhTab", tab); } catch (_) {}
    const frame = document.getElementById("magichubFrame");
    if (frame && frame.contentWindow) {
      try { frame.contentWindow.postMessage({ type: "sw-set-tab", tab }, "*"); } catch (_) {}
      try {
        if (typeof frame.contentWindow.__swSetTab === "function") frame.contentWindow.__swSetTab(tab);
      } catch (_) {}
    }
  }

  function workbenchTabs() {
    const wb = (state.workbenches || []).find(w => w.id === state.activeWorkbenchId) || (state.workbenches || [])[0];
    if (!wb || !wb.modules) return TABS.filter(x => !["客户与线索","客户管理","开发进度","询盘与报价"].includes(x));
    return wb.modules.map(m => MODULE_TAB[m]).filter(Boolean);
  }
  async function loadWorkbenches() {
    try {
      const res = await fetch("./data/workbenches.json", { cache: "no-store" });
      if (res.ok) {
        const doc = await res.json();
        state.workbenches = doc.workbenches || [];
        const saved = localStorage.getItem("sw.activeWorkbenchId");
        const def = doc.defaultId || (state.workbenches[0] && state.workbenches[0].id);
        state.activeWorkbenchId = state.workbenches.some(w => w.id === saved) ? saved : def;
      }
    } catch (_) {}
    try {
      const res = await fetch("./data/trade-leads-index.json", { cache: "no-store" });
      if (res.ok) state.tradeIndex = await res.json();
    } catch (_) {}
  }
  function renderWorkbenchSegment() {
    const list = state.workbenches || [];
    if (!list.length) return "";
    return list.map(w => {
      const active = w.id === state.activeWorkbenchId;
      const label = w.shortName || w.name;
      return `<button type="button" class="wb-seg ${active ? "wb-seg--active" : ""}" data-wb="${esc(w.id)}" role="tab" aria-selected="${active ? "true" : "false"}">${esc(label)}</button>`;
    }).join("");
  }
  function renderTradeKeyStrip() {
    const hints = ((state.workbenches || []).find(w => w.id === state.activeWorkbenchId) || {}).summaryHints || {};
    if (!hints.showTradeCounts) return "";
    const c = (state.tradeIndex && state.tradeIndex.counts) || {};
    const cells = [["线索", c.leadsTotal], ["优质", c.leadsQualified], ["档案", c.profiles], ["开发中", c.inProgressDev], ["询盘", c.inquiriesOpen], ["报价草稿", c.quotesDraft]]
      .map(([k, v]) => `<div class="daily-card"><div class="muted" style="font-size:12px">${esc(k)}</div><div style="font-size:22px;font-weight:700">${v == null ? "—" : v}</div></div>`)
      .join("");
    const act = (state.tradeIndex && state.tradeIndex.latestActivity)
      ? `<p class="muted" style="margin-top:8px">${esc(state.tradeIndex.latestActivity)}</p>` : "";
    return `<section class="section-shell"><div class="section-shell__head"><h3 class="section-shell__title">外贸关键指标</h3><span class="section-shell__badge">聚合</span></div>
      <p class="muted" style="font-size:12px">仅计数 · 客户名/金额见 private</p>
      <div class="kpi-grid" style="grid-template-columns:repeat(auto-fill,minmax(120px,1fr))">${cells}</div>${act}</section>`;
  }
  function bindWorkbenchSegment() {
    document.querySelectorAll(".wb-seg[data-wb]").forEach((el) => {
      el.onclick = () => switchWorkbench(el.getAttribute("data-wb"));
    });
  }
  function switchWorkbench(id) {
    state.activeWorkbenchId = id;
    try { localStorage.setItem("sw.activeWorkbenchId", id); } catch (_) {}
    if (id === "trade") {
      state.magicHubTab = magicHubTabId();
    } else {
      const tabs = workbenchTabs();
      if (!tabs.includes(state.tab)) state.tab = tabs[0] || "总览";
    }
    render();
  }
  function scopedBots() {
    const wb = (state.workbenches || []).find(w => w.id === state.activeWorkbenchId);
    const bots = state.data.bots || [];
    if (!wb || !wb.botGroupIds || !wb.botGroupIds.length) return bots;
    const set = new Set(wb.botGroupIds);
    return bots.filter(b => set.has(b.group) || (b.groups || []).some(g => set.has(g)));
  }
  function scopedTasks() {
    const wb = (state.workbenches || []).find(w => w.id === state.activeWorkbenchId);
    const tasks = state.data.tasks || [];
    if (!wb || !wb.botGroupIds || !wb.botGroupIds.length) return tasks;
    const names = new Set(scopedBots().map(b => b.name));
    return tasks.filter(t => names.has(t.executor) || names.has(t.reviewer) || [...names].some(n => (t.executor || "").includes(n)));
  }
  async function loadScheduleMonth(ym) {
    if (state.scheduleLoadedMonth === ym) return;
    const map = {};
    let days = [];
    try {
      const idxRes = await fetch("./data/schedule/" + ym + ".index.json", { cache: "no-store" });
      if (idxRes.ok) { const idx = await idxRes.json(); days = idx.dates || []; }
    } catch (_) {}
    await Promise.all(days.map(async (date) => {
      try {
        const res = await fetch("./data/schedule/" + date + ".json", { cache: "no-store" });
        if (!res.ok) return;
        const doc = await res.json();
        if (doc && doc.date) map[doc.date] = doc;
      } catch (_) {}
    }));
    try {
      const res = await fetch("./data/daily-reports-index.json", { cache: "no-store" });
      if (res.ok) {
        const idx = await res.json();
        state.dailyReportDates = idx.dates || [];
        for (const d of state.dailyReportDates) {
          if (!d.startsWith(ym)) continue;
          if (!map[d]) map[d] = { version: 1, date: d, tasks: [], schedule: [], meta: {} };
          map[d].meta = Object.assign({}, map[d].meta || {}, { hasDailyReport: true });
        }
      }
    } catch (_) {}
    state.scheduleByDate = map;
    state.scheduleLoadedMonth = ym;
  }
  function shiftCalMonth(delta) {
    const [y, m] = (state.calMonth || "2026-10").split("-").map(Number);
    const dt = new Date(y, m - 1 + delta, 1);
    state.calMonth = dt.getFullYear() + "-" + String(dt.getMonth() + 1).padStart(2, "0");
    state.scheduleLoadedMonth = null;
    render();
  }
  function renderScheduleCenter() {
    const ym = state.calMonth || new Date().toISOString().slice(0, 7);
    state.calMonth = ym;
    const [y, m] = ym.split("-").map(Number);
    const first = new Date(y, m - 1, 1);
    let startPad = (first.getDay() + 6) % 7;
    const daysInMonth = new Date(y, m, 0).getDate();
    const cells = [];
    for (let i = 0; i < startPad; i++) cells.push(null);
    for (let d = 1; d <= daysInMonth; d++) cells.push(ym + "-" + String(d).padStart(2, "0"));
    while (cells.length % 7) cells.push(null);
    const today = new Date();
    const todayStr = today.getFullYear() + "-" + String(today.getMonth() + 1).padStart(2, "0") + "-" + String(today.getDate()).padStart(2, "0");
    const week = ["一","二","三","四","五","六","日"].map(w => `<div class="cal-weekday">${w}</div>`).join("");
    const grid = cells.map(date => {
      if (!date) return `<div class="cal-cell cal-cell--empty"></div>`;
      const doc = (state.scheduleByDate || {})[date] || {};
      const tn = (doc.tasks || []).length, sn = (doc.schedule || []).length;
      const hasEmail = !!(doc.meta && doc.meta.hasEmailSummary);
      const hasReport = !!(doc.meta && doc.meta.hasDailyReport);
      const isToday = date === todayStr, sel = date === state.calSelected;
      return `<button type="button" class="cal-cell ${isToday ? "cal-cell--today" : ""} ${sel ? "cal-cell--sel" : ""}" data-cal-day="${date}">
        <div class="cal-cell__day">${Number(date.slice(8))}${isToday ? '<span class="cal-dot"></span>' : ""}</div>
        <div class="cal-cell__meta">${tn ? `<span class="cal-tag cal-tag--task">${tn} 任务</span>` : ""}${sn ? `<span class="cal-tag cal-tag--sched">${sn} 日程</span>` : ""}
        <span class="cal-flags">${hasEmail ? "✉️" : ""}${hasReport ? "📄" : ""}</span></div></button>`;
    }).join("");
    const detail = state.calSelected ? renderCalDayDetail(state.calSelected) : `<p class="muted">点击日期查看当日详情。</p>`;
    return `<h2 class="section-title">任务与日程中心</h2>
      <p class="muted">仅加载当月 · 邮件正文不在 Pages 展示</p>
      <div class="cal-toolbar"><button type="button" class="btn" data-cal-shift="-1">‹</button><strong>${y}年 ${m}月</strong>
      <button type="button" class="btn" data-cal-shift="1">›</button><button type="button" class="btn" data-cal-today="1">今天</button></div>
      <div class="cal-weekdays">${week}</div><div class="cal-grid">${grid}</div><div class="cal-detail">${detail}</div>`;
  }
  function renderCalDayDetail(date) {
    const doc = (state.scheduleByDate || {})[date] || { tasks: [], schedule: [], meta: {} };
    const tasks = (doc.tasks || []).map(t => `<div class="cal-item"><span class="pill">${esc(t.status || "待办")}</span> <strong>${esc(t.title)}</strong>
      <div class="muted" style="font-size:12px">${esc(t.ownerName || t.ownerBotId || "")}</div></div>`).join("") || `<p class="muted">本日暂无任务</p>`;
    const sched = (doc.schedule || []).map(s => `<div class="cal-item"><strong>${esc(s.title)}</strong> <span class="muted">${esc(s.who || "")}</span></div>`).join("") || `<p class="muted">本日暂无日程</p>`;
    const hasEmail = !!(doc.meta && doc.meta.hasEmailSummary);
    const hasReport = !!(doc.meta && doc.meta.hasDailyReport);
    const emailBlock = hasEmail ? `<div class="callout warn"><strong>有邮件总结</strong>正文仅 Mac 本地可读。</div>` : `<p class="muted">无邮件总结标记</p>`;
    const reportBlock = hasReport ? `<button type="button" class="btn primary" data-open-daily="${date}">打开「每日总结」</button>` : `<p class="muted">无纪纪日报</p>`;
    return `<div class="cal-detail-card"><h3>${esc(date)}</h3><h4>任务</h4>${tasks}<h4>日程</h4>${sched}<h4>邮件</h4>${emailBlock}<h4>日报</h4>${reportBlock}</div>`;
  }

  async function loadSeoFeedIndex() {
    if (state.seoFeedIndex) return;
    const paths = ["./data/feeds/seo/index.json", "../data/feeds/seo/index.json", "data/feeds/seo/index.json"];
    for (const p of paths) {
      try {
        const res = await fetch(p, { cache: "no-store" });
        if (res.ok) { state.seoFeedIndex = await res.json(); return; }
      } catch (_) {}
    }
    state.seoFeedIndex = { dates: [] };
  }
  async function loadSeoFeedDay(date) {
    state.seoFeedDate = date;
    state.seoFeedDay = null;
    const files = [`${date}.json`, `${date}.md`];
    for (const f of files) {
      for (const base of ["./data/feeds/seo/", "../data/feeds/seo/", "data/feeds/seo/"]) {
        try {
          const res = await fetch(base + f, { cache: "no-store" });
          if (!res.ok) continue;
          if (f.endsWith(".json")) state.seoFeedDay = await res.json();
          else state.seoFeedDay = { date, summary: await res.text(), articles: [], keywords: [], checks: [], issues: [] };
          return;
        } catch (_) {}
      }
    }
  }
  function renderDailySeo() {
    const idx = state.seoFeedIndex || { dates: [] };
    const dates = idx.dates || [];
    const sel = state.seoFeedDate || (dates[0] && dates[0].date) || null;
    if (sel && sel !== state.seoFeedDate) { /* will load below */ }
    const list = dates.length
      ? dates.map(d => `<button type="button" class="daily-date ${d.date === sel ? "active" : ""}" data-seo-date="${esc(d.date)}"><strong>${esc(d.date)}</strong><div class="muted">${esc(d.summary || "")}</div></button>`).join("")
      : `<p class="muted">暂无 SEO feed。Bot 写入 data/feeds/seo/YYYY-MM-DD.json 后运行 rebuild-feeds-index.mjs</p>`;
    const day = state.seoFeedDay;
    let pane = `<p class="muted">选择日期</p>`;
    if (sel && day) {
      const arts = (day.articles || []).map(a => `<div class="daily-card feed-article"><h4>${esc(a.title || a.id || "")}</h4>
        <p>${esc(a.primaryKeyword || "")} · ${esc(a.status || "")}</p>
        ${a.url ? `<p><a href="${esc(a.url)}" target="_blank" rel="noopener">${esc(a.url)}</a></p>` : ""}
        ${a.notes ? `<p class="muted">${esc(a.notes)}</p>` : ""}</div>`).join("") || `<div class="daily-card"><p class="muted">无文章</p></div>`;
      const kws = (day.keywords || []).map(k => `<span class="feed-chip">${esc(k.term || "")}</span>`).join("") || `<span class="muted">无</span>`;
      const checks = (day.checks || []).map(c => `<div class="daily-card"><h4>${esc(c.name || c.id)}</h4><p>${esc(c.status || "")} — ${esc(c.detail || "")}</p></div>`).join("") || "";
      const issues = (day.issues || []).map(i => `<div class="daily-card"><h4>${esc(i.title || "问题")}</h4><p class="muted">${esc(i.severity || "")}</p><p>${esc(i.detail || "")}</p></div>`).join("") || `<div class="daily-card"><p class="muted">无问题</p></div>`;
      pane = `<h3 class="feed-day-title">每日 SEO · ${esc(sel)}</h3>
        <p class="feed-day-body">${esc(day.summary || "")}</p>
        <h4>文章</h4>${arts}
        <h4>关键词</h4><div>${kws}</div>
        <h4>日检</h4>${checks}
        <h4>问题</h4>${issues}`;
    } else if (sel) {
      pane = `<p class="muted">加载 ${esc(sel)}…</p>`;
    }
    return `<h2 class="section-title">每日 SEO</h2><p class="muted">搜搜-SEO专家 · data/feeds/seo/</p><div class="daily-layout"><aside class="daily-aside">${list}</aside><section class="daily-main">${pane}</section></div>`;
  }

  function renderDailySummary() {
    const dates = state.dailyReportDates || [];
    const sel = state.dailyReportDate || dates[0] || null;
    if (sel) state.dailyReportDate = sel;
    const list = dates.length ? dates.map(d => `<button type="button" class="daily-date ${d === sel ? "active" : ""}" data-daily-date="${d}">${d}</button>`).join("") : `<p class="muted">暂无日报索引</p>`;
    let hosted = false;
    try { hosted = (location.hostname || "").endsWith("github.io") || (location.hostname || "").endsWith("pages.dev"); } catch (_) {}
    const pane = !sel ? `<p class="muted">选择日期</p>` : `<h3>团队日报 ${esc(sel)}</h3><div class="callout warn"><strong>隐私降级</strong>日报全文不进 Pages，请用 Mac 应用查看。</div>
      <div class="daily-cards"><div class="daily-card"><h4>完成事项</h4><p class="muted">仅本地可见</p></div><div class="daily-card"><h4>交付物</h4><p class="muted">仅本地可见</p></div><div class="daily-card"><h4>卡住的事</h4><p class="muted">仅本地可见</p></div><div class="daily-card"><h4>待用户决定的事</h4><p class="muted">仅本地可见</p></div></div>`;
    return `<h2 class="section-title">每日总结</h2><div class="daily-layout"><aside class="daily-aside">${list}</aside><section class="daily-main">${pane}</section></div>`;
  }

  async function loadCrmIndexes() {
    if (state.crmIndexLoaded) return;
    state.crmIndexLoaded = true;
    state.crmLeadsIndex = null;
    state.crmPdfIndex = null;
    state.crmThumbIndex = null;
    state.crmPage = 0;
    state.crmPageRows = [];
    if (isHostedPages()) return; // private CRM never on Pages
    const tryFetch = async (paths) => {
      for (const p of paths) {
        try {
          const res = await fetch(p, { cache: "no-store" });
          if (res.ok) return await res.json();
        } catch (_) {}
      }
      return null;
    };
    state.crmLeadsIndex = await tryFetch([
      "./data/private/crm/leads/leads-index.json",
      "../data/private/crm/leads/leads-index.json",
      "./data/crm/leads-index.json",
      "../data/crm/leads-index.json",
    ]);
    state.crmPdfIndex = await tryFetch([
      "./data/private/crm/pdfs/pdf-index.json",
      "../data/private/crm/pdfs/pdf-index.json",
      "./data/crm/pdf-index.json",
    ]);
    state.crmThumbIndex = await tryFetch([
      "./data/private/crm/thumbs/thumb-index.json",
      "../data/private/crm/thumbs/thumb-index.json",
      "./data/crm/thumb-index.json",
    ]);
    await loadCrmPage(0);
  }

  async function loadCrmPage(page) {
    state.crmPage = page;
    const t0 = performance.now();
    if (isHostedPages()) {
      state.crmPageRows = (state.crmLeadsIndex && state.crmLeadsIndex.sample) || [];
      state.crmPageMs = Math.round(performance.now() - t0);
      return;
    }
    const name = `page-${String(page).padStart(4, "0")}.json`;
    const paths = [
      `./data/private/crm/leads/${name}`,
      `../data/private/crm/leads/${name}`,
    ];
    let rows = null;
    for (const p of paths) {
      try {
        const res = await fetch(p, { cache: "no-store" });
        if (res.ok) { rows = await res.json(); break; }
      } catch (_) {}
    }
    state.crmPageRows = Array.isArray(rows) ? rows : ((state.crmLeadsIndex && state.crmLeadsIndex.sample) || []);
    state.crmPageMs = Math.round(performance.now() - t0);
  }

  function renderCrmCustomers() {
    const idx = state.crmLeadsIndex || {};
    const pdfs = (state.crmPdfIndex && state.crmPdfIndex.items) || [];
    const thumbs = state.crmThumbIndex || {};
    const rows = state.crmPageRows || [];
    const page = state.crmPage || 0;
    const pageCount = idx.pageCount || 1;
    const cards = [
      ["客户总数", idx.total],
      ["本页条数", rows.length],
      ["产品缩略图", thumbs.total],
      ["PDF 目录", (state.crmPdfIndex && state.crmPdfIndex.total) || pdfs.length],
      ["本页加载", state.crmPageMs != null ? state.crmPageMs + "ms" : "—"],
    ].map(([k,v]) => `<div class="daily-card"><div class="muted" style="font-size:12px">${esc(k)}</div><div style="font-size:22px;font-weight:700">${v == null ? "—" : esc(String(v))}</div></div>`).join("");
    const list = rows.map(r => `<div class="crm-row" style="padding:10px 12px;border-bottom:1px solid rgba(0,0,0,.06)">
      <div style="font-weight:600">${esc(r.company || "未命名客户")}</div>
      <div class="muted" style="font-size:12px">${esc([r.country,r.status,r.email].filter(Boolean).join(" · "))}</div>
    </div>`).join("") || `<p class="muted">无本页数据（Pages 托管仅显示公开样例；本地请打开 private/crm）</p>`;
    const pdfList = pdfs.map(p => `<div class="daily-card"><div style="font-weight:600">${esc(p.name)}</div><div class="muted" style="font-size:12px">${p.bytes ? Math.round(p.bytes/1048576)+" MB" : ""} · 按需打开原文</div></div>`).join("") || `<p class="muted">无 PDF 索引</p>`;
    return `<h2 class="section-title">客户管理</h2>
      <p class="muted">MagicHub 优化合并 · 分页客户 / WebP 缩略图 / PDF 仅索引 · 不阻塞工作台启动</p>
      <div class="daily-cards" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:12px;margin:12px 0">${cards}</div>
      <div style="display:flex;gap:16px;align-items:flex-start">
        <div style="flex:1;min-width:0;background:#fff;border-radius:12px;border:1px solid rgba(0,0,0,.06)">
          <div style="display:flex;align-items:center;gap:8px;padding:12px 14px;border-bottom:1px solid rgba(0,0,0,.06)">
            <strong>客户列表（分页）</strong>
            <span class="muted" style="margin-left:auto">第 ${page+1} / ${pageCount} 页</span>
            <button type="button" class="btn" data-crm-page="${Math.max(0,page-1)}" ${page<=0?"disabled":""}>上一页</button>
            <button type="button" class="btn" data-crm-page="${Math.min(pageCount-1,page+1)}" ${page>=pageCount-1?"disabled":""}>下一页</button>
          </div>
          <div style="max-height:520px;overflow:auto">${list}</div>
        </div>
        <div style="width:280px">${pdfList}<p class="muted" style="margin-top:10px;font-size:12px">缩略图与原图在 private/crm/（gitignore）</p></div>
      </div>`;
  }


  function isTradeWorkbench() {
    return state.activeWorkbenchId === "trade";
  }

  function renderTradeMagicHub() {
    const hosted = isHostedPages();
    if (hosted) {
      return `<div class="section-title-row"><h2 class="section-title">外贸工作台</h2></div>
        <div class="callout warn" style="margin:16px">
          <strong>隐私降级（Pages）</strong>
          MagicHub 客户/订单/产品等明细仅存本机 <code>data/private/crm</code>，不会发布到 Pages。
          请在 Mac「超级工作台」应用内打开外贸工作台以使用完整 MagicHub（驾驶舱、客户管理、智能营销等）。
        </div>
        <div class="daily-cards" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px">
          <div class="daily-card"><div class="muted">公开线索索引</div><div style="font-size:28px;font-weight:700">${(state.tradeIndex&&state.tradeIndex.counts&&state.tradeIndex.counts.leadsTotal)!=null?state.tradeIndex.counts.leadsTotal:"—"}</div></div>
          <div class="daily-card"><div class="muted">CRM 客户（本地）</div><div style="font-size:28px;font-weight:700">${(state.crmLeadsIndex&&state.crmLeadsIndex.total)||"—"}</div></div>
        </div>`;
    }
    // Local web: full-page iframe (embed=1 hides MagicHub aside; outer sidebar drives tabs)
    const tab = encodeURIComponent(magicHubTabId());
    return `<iframe id="magichubFrame" title="MagicHub" src="./magichub/index.html?embed=1&tab=${tab}" style="border:0;width:100%;height:calc(100vh - 56px);background:#f3f4f6"></iframe>`;
  }

  function renderTradeModule(kind) {
    const c = (state.tradeIndex && state.tradeIndex.counts) || {};
    const act = (state.tradeIndex && state.tradeIndex.latestActivity) || "—";
    const title = kind === "leads" ? "客户与线索" : kind === "pipeline" ? "开发进度" : "询盘与报价";
    const cards = kind === "leads" ? [["线索总数", c.leadsTotal], ["已分层优质", c.leadsQualified], ["客户档案", c.profiles]]
      : kind === "pipeline" ? [["开发中", c.inProgressDev], ["员工（本台）", scopedBots().length], ["待办+进行中", scopedTasks().filter(t => t.status === "待办" || t.status === "进行中").length]]
      : [["开口询盘", c.inquiriesOpen], ["报价草稿", c.quotesDraft]];
    const grid = cards.map(([k, v]) => `<div class="daily-card"><div class="muted" style="font-size:12px">${esc(k)}</div><div style="font-size:28px;font-weight:700">${v == null ? "—" : v}</div></div>`).join("");
    return `<h2 class="section-title">${title}</h2><p class="muted">公开仅聚合计数</p><div class="daily-cards" style="display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px">${grid}</div><p class="muted" style="margin-top:12px">最近动态：${esc(act)}</p>`;
  }

  function isHostedPages() {
    try {
      const h = location.hostname || "";
      return h.endsWith("github.io") || h.endsWith("pages.dev");
    } catch (_) { return false; }
  }

  async function tryLoadPrivateWebsiteProjects() {
    if (isHostedPages()) return null; // private/ never published — avoid 404 storm
    const paths = [
      "./data/private/websiteProjects.local.json",
      "../data/private/websiteProjects.local.json",
      "data/private/websiteProjects.local.json",
    ];
    for (const p of paths) {
      try {
        const res = await fetch(p, { cache: "no-store" });
        if (!res.ok) continue;
        const json = await res.json();
        if (json && Array.isArray(json.projects)) return json.projects;
        if (Array.isArray(json)) return json;
      } catch (_) {}
    }
    return null;
  }

  async function loadData() {
    const cached = loadLocal();
    const paths = isHostedPages()
      ? ["./data/workspace.json"]
      : ["./data/workspace.json", "../data/workspace.json", "../../data/workspace.json", "data/workspace.json"];
    for (const p of paths) {
      try {
        const res = await fetch(p, { cache: "no-store" });
        if (res.ok) {
          const json = await res.json();
          state.data = cached && cached.bots && cached.bots.length
            ? Object.assign({}, json, {
                bots: cached.bots,
                tasks: cached.tasks || json.tasks,
                vacancies: cached.vacancies || json.vacancies,
                groups: cached.groups || json.groups,
                routines: cached.routines || json.routines,
                rules: cached.rules || json.rules,
              })
            : json;
          const priv = await tryLoadPrivateWebsiteProjects();
          if (priv && priv.length) {
            state.data.websiteProjects = priv;
            state.source = "json:" + p + " + private" + (cached ? " + localStorage" : "");
          } else {
            state.source = "json:" + p + (cached ? " + localStorage" : "");
          }
          state.selectedId = (cached && cached.selectedId) || state.data.bots[0].id;
          state.editTaskId = (state.data.tasks[0] && state.data.tasks[0].id) || null;
          rebuildIndexes();
          return;
        }
      } catch (_) {}
    }
    const base = defaultData();
    if (cached && cached.bots && cached.bots.length) {
      state.data = Object.assign({}, base, {
        bots: cached.bots,
        tasks: cached.tasks || base.tasks,
        vacancies: cached.vacancies || base.vacancies,
        groups: cached.groups || base.groups,
        routines: cached.routines || base.routines,
        rules: cached.rules || base.rules,
      });
      state.source = "embedded + localStorage";
      state.selectedId = cached.selectedId || base.bots[0].id;
    } else {
      state.data = base;
      state.source = "embedded";
      state.selectedId = base.bots[0].id;
    }
    state.editTaskId = (state.data.tasks[0] && state.data.tasks[0].id) || null;
    rebuildIndexes();
  }


  async function maybeApplyStressOverlay() {
    try {
      const q = new URLSearchParams(location.search || "");
      if (q.get("stress") !== "1") return;
      // Local / CI harness only — never shipped as public data.
      const host = location.hostname || "";
      if (host && host !== "localhost" && host !== "127.0.0.1") return;
      const res = await fetch("/tmp/sw-stress-workspace.json", { cache: "no-store" }).catch(() => null);
      // Also try sibling path served by stress harness
      let json = null;
      if (res && res.ok) json = await res.json();
      if (!json) {
        const res2 = await fetch("./data/stress-workspace.local.json", { cache: "no-store" }).catch(() => null);
        if (res2 && res2.ok) json = await res2.json();
      }
      if (!json) return;
      if (Array.isArray(json.bots) && json.bots.length) state.data.bots = json.bots;
      if (Array.isArray(json.websiteProjects) && json.websiteProjects.length) state.data.websiteProjects = json.websiteProjects;
      if (Array.isArray(json.groupsOrder) && json.groupsOrder.length) state.data.groupsOrder = json.groupsOrder;
      state.source = (state.source || "") + " + stress";
      rebuildIndexes();
    } catch (_) {}
  }

  function botGroups(b) {
    if (b.groups && b.groups.length) return b.groups;
    if (b.group) return [b.group];
    return ["其他"];
  }
  function botInGroup(b, g) { return botGroups(b).indexOf(g) >= 0; }
  function displayNick(n) {
    if (!n) return "";
    const i = n.indexOf("-");
    return i >= 0 ? n.slice(0, i) : n;
  }
  function displayTitle(n, role) {
    if (n && n.indexOf("-") >= 0) {
      const t = n.slice(n.indexOf("-") + 1);
      if (t) return t;
    }
    return role || "";
  }
  function avatarSrc(b) {
    return "./avatars/" + encodeURIComponent(b.id) + ".png";
  }
  function groupOrder() {
    return (state.data.groupsOrder && state.data.groupsOrder.length)
      ? state.data.groupsOrder
      : ["管理中枢","网站项目","服装外贸","运营管理","战略决策","视觉设计","短剧组","外贸营销","个人成长","内容营销"];
  }
  function moneyFmt(v) {
    if (v == null || v === "" || Number(v) === 0) return "—";
    return String(v);
  }

  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function statusBadge(s) {
    const cls = s === "在线" ? "ok" : s === "忙碌" ? "busy" : "";
    return `<span class="badge ${cls}">${esc(s)}</span>`;
  }

  async function setTab(tab) {
    state.tab = tab;
    if (tab === "客户管理") {
      await loadCrmIndexes();
    }
    if (tab === "每日 SEO") {
      await loadSeoFeedIndex();
      const d = state.seoFeedDate || (state.seoFeedIndex && state.seoFeedIndex.dates && state.seoFeedIndex.dates[0] && state.seoFeedIndex.dates[0].date);
      if (d) await loadSeoFeedDay(d);
    }
    render();
  }

  function botNames() {
    return state.data.bots.map((b) => b.name);
  }

  function selectedBot() {
    return state.data.bots.find((b) => b.id === state.selectedId) || state.data.bots[0];
  }

  function selectedTask() {
    return state.data.tasks.find((t) => t.id === state.editTaskId) || state.data.tasks[0];
  }

  function updateBot(id, patch) {
    state.data.bots = state.data.bots.map((b) => (b.id === id ? Object.assign({}, b, patch) : b));
    saveLocal();
    render();
  }

  function updateTask(id, patch) {
    const cur = state.data.tasks.find((t) => t.id === id);
    if (!cur) return;
    const next = Object.assign({}, cur, patch);
    if (next.executor && next.reviewer && next.executor === next.reviewer) {
      toast("执行人与验收人不能相同");
      return;
    }
    state.data.tasks = state.data.tasks.map((t) => (t.id === id ? next : t));
    saveLocal();
    render();
  }

  function moveTask(id, dir) {
    const t = state.data.tasks.find((x) => x.id === id);
    if (!t) return;
    const i = COLS.indexOf(t.status);
    const ni = i + dir;
    if (ni < 0 || ni >= COLS.length) return;
    updateTask(id, { status: COLS[ni] });
  }

  function deleteTask(id) {
    state.data.tasks = state.data.tasks.filter((t) => t.id !== id);
    if (state.editTaskId === id) state.editTaskId = (state.data.tasks[0] && state.data.tasks[0].id) || null;
    saveLocal();
    render();
  }

  function addTask() {
    const title = (document.getElementById("newTitle") || {}).value || "";
    const note = (document.getElementById("newNote") || {}).value || "";
    const executor = (document.getElementById("newExec") || {}).value || "";
    const reviewer = (document.getElementById("newReview") || {}).value || "";
    if (!title.trim()) { toast("请填写任务标题"); return; }
    if (executor === reviewer) { toast("执行人与验收人必须不同"); return; }
    const id = "t-" + Date.now();
    state.data.tasks.push({ id, title: title.trim(), status: "待办", note: note.trim() || "—", executor, reviewer });
    state.editTaskId = id;
    saveLocal();
    render();
    toast("已添加任务");
  }

  function confirmHire(id) {
    state.data.vacancies = state.data.vacancies.map((v) =>
      v.id === id ? Object.assign({}, v, { confirmed: true }) : v
    );
    saveLocal();
    render();
    toast("已本地标记「确认招聘」（未真正创建 Bot）");
  }

  function doExport() {
    const payload = Object.assign({}, state.data, { exportedAt: new Date().toISOString() });
    const text = JSON.stringify(payload, null, 2);
    const blob = new Blob([text], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "数字工坊-工作台.json";
    a.click();
    URL.revokeObjectURL(a.href);
    toast("已导出 JSON");
  }

  function doImport(file) {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const json = JSON.parse(reader.result);
        if (!json.bots || !json.tasks) throw new Error("缺少 bots/tasks");
        state.data = Object.assign(defaultData(), json);
        state.selectedId = (json.selectedId) || state.data.bots[0].id;
        state.editTaskId = (state.data.tasks[0] && state.data.tasks[0].id) || null;
        saveLocal();
        render();
        toast("导入成功");
      } catch (e) {
        toast("导入失败：" + e.message);
      }
    };
    reader.readAsText(file);
  }

  function resetDefault() {
    if (!confirm("恢复内置默认数据？本地改动会清空。")) return;
    localStorage.removeItem(LS_KEY);
    state.data = defaultData();
    state.selectedId = state.data.bots[0].id;
    state.editTaskId = state.data.tasks[0].id;
    state.source = "embedded";
    render();
    toast("已恢复默认");
  }


  const PRIVACY_LABEL = "仅本地可见";

  function moneyFmtCNY(v) {
    if (v == null || v === "") return "—";
    const n = Number(v);
    if (!Number.isFinite(n)) return "—";
    return "¥" + Math.round(n).toLocaleString("zh-CN");
  }

  function pctRate(n, d) {
    if (d == null || !(Number(d) > 0) || n == null) return "—";
    return ((Number(n) / Number(d)) * 100).toFixed(1) + "%";
  }

  /** Mirror bots/运营管理/财务官/files/calc_website_dashboard.py */
  function computeWebsiteKPI(projects, targets) {
    const list = projects || [];
    const allNil = !list.length || list.every(p =>
      p.totalAmount == null && p.paidAmount == null && p.unpaidAmount == null && p.depositAmount == null
    );
    const now = new Date();
    // Asia/Shanghai approx via locale
    const fmt = new Intl.DateTimeFormat("en-CA", { timeZone: "Asia/Shanghai", year: "numeric", month: "2-digit", day: "2-digit" });
    const asOf = fmt.format(now); // YYYY-MM-DD
    const [Y, M] = asOf.split("-").map(Number);
    if (allNil) {
      return { amountsAvailable: false, asOf, portfolioContract:0, portfolioPaid:0, portfolioUnpaid:0, portfolioOverdue:0,
        yearContract:0, yearPaid:0, monthContract:0, yearContractTarget:null, yearCollectionTarget:null,
        pricedCount:0, zeroPlaceholderCount:0, overdueRiskCount:0, quality:[] };
    }
    const parseDay = (s) => {
      if (!s) return null;
      const h = String(s).slice(0, 10);
      if (!/^\d{4}-\d{2}-\d{2}$/.test(h)) {
        try {
          const d = new Date(s);
          if (!isNaN(d)) {
            return fmt.format(d);
          }
        } catch (_) {}
        return null;
      }
      return h;
    };
    let portfolioC=0,portfolioP=0,portfolioU=0,portfolioO=0;
    let yC=0,yP=0,mC=0,mP=0;
    let zeroN=0,pricedN=0,riskN=0,qFallback=0,qMissing=0;
    for (const p of list) {
      const t = Number(p.totalAmount)||0;
      const pd = Number(p.paidAmount)||0;
      const u = p.unpaidAmount != null ? (Number(p.unpaidAmount)||0) : Math.max(t-pd,0);
      if (t===0 && pd===0) zeroN++;
      if (t>0) pricedN++;
      let cdate = parseDay(p.serviceStartDate);
      let csrc = "serviceStartDate";
      if (!cdate) {
        cdate = parseDay(p.createdAt);
        csrc = cdate ? "createdAt_fallback" : "missing";
        if (csrc==="createdAt_fallback") qFallback++;
        if (csrc==="missing") qMissing++;
      }
      const end = parseDay(p.deadline) || parseDay(p.serviceEndDate);
      const overdue = u>0.01 && end && end < asOf;
      const ps = p.paymentStatus||"";
      const risk = u>0.01 && !end && p.status==="delivered" && ps!=="fully_paid";
      if (risk) riskN++;
      portfolioC+=t; portfolioP+=pd; portfolioU+=u;
      if (overdue) portfolioO+=u;
      if (cdate) {
        const [cy,cm] = cdate.split("-").map(Number);
        if (cy===Y) {
          yC+=t; yP+=pd;
          if (cm===M) { mC+=t; mP+=pd; }
        }
      }
    }
    let yCT=null, yColT=null;
    const yp = targets && targets.websiteProjects && targets.websiteProjects.yearly;
    if (yp && yp.year===Y) {
      yCT = yp.contractTarget;
      yColT = yp.collectionTarget;
    }
    const quality = [];
    if (zeroN) quality.push({kind:"zero_amount_placeholder", count:zeroN, label:"零金额占位"});
    if (qFallback) quality.push({kind:"date_fallback_createdAt", count:qFallback, label:"缺 serviceStartDate（回退 createdAt）"});
    if (qMissing) quality.push({kind:"date_missing", count:qMissing, label:"无合同归属日"});
    if (riskN) quality.push({kind:"overdue_risk_no_end_date", count:riskN, label:"待收无截止日期（逾期风险）"});
    return {
      amountsAvailable: true, asOf,
      portfolioContract: portfolioC, portfolioPaid: portfolioP, portfolioUnpaid: portfolioU, portfolioOverdue: portfolioO,
      yearContract: yC, yearPaid: yP, monthContract: mC, monthPaid: mP,
      yearContractTarget: yCT, yearCollectionTarget: yColT,
      pricedCount: pricedN, zeroPlaceholderCount: zeroN, overdueRiskCount: riskN, quality
    };
  }

  async function loadOverviewExtras() {
    const tryFetch = async (paths) => {
      for (const p of paths) {
        try {
          const res = await fetch(p, { cache: "no-store" });
          if (res.ok) return await res.json();
        } catch (_) {}
      }
      return null;
    };
    // private targets — only works on file/localhost with private present
    if (!isHostedPages()) {
      state.targetsFile = await tryFetch([
        "./data/private/targets.local.json",
        "../data/private/targets.local.json",
        "data/private/targets.local.json"
      ]);
    } else {
      state.targetsFile = null;
    }
    const uiPaths = isHostedPages() ? ["./data/ui-config.json"] : ["./data/ui-config.json","../data/ui-config.json","data/ui-config.json"];
    const mailPaths = isHostedPages() ? ["./data/email-daily.json"] : ["./data/email-daily.json","../data/email-daily.json","data/email-daily.json"];
    const ui = await tryFetch(uiPaths);
    if (ui) state.uiConfig = ui;
    const mail = await tryFetch(mailPaths);
    if (mail && Array.isArray(mail.items)) {
      state.emailDaily = mail.items.slice().sort((a,b)=>String(b.date).localeCompare(String(a.date)));
    } else state.emailDaily = [];
    if (!state.expandedEmail && state.emailDaily[0]) state.expandedEmail = state.emailDaily[0].date;
  }

  function renderOverview() {
    const bots = scopedBots();
    const webs = state.data.websiteProjects || [];
    const tasks = scopedTasks();
    const wbHints = ((state.workbenches || []).find(w => w.id === state.activeWorkbenchId) || {}).summaryHints || {};
    const kpi = computeWebsiteKPI(webs, state.targetsFile);
    const privacy = !kpi.amountsAvailable;
    const priv = (v) => privacy ? PRIVACY_LABEL : v;
    const ringPct = (n, d) => {
      if (d == null || !(Number(d) > 0) || n == null) return null;
      return Math.min(100, (Number(n) / Number(d)) * 100);
    };
    const ringStyle = (pct, color) => {
      if (pct == null) return `background:conic-gradient(${color} 0%, var(--sw-ring-track) 0)`;
      return `background:conic-gradient(${color} ${pct.toFixed(1)}%, var(--sw-ring-track) 0)`;
    };
    const urgencyClass = (u) => {
      if (u === "高") return "high";
      if (u === "中") return "mid";
      return "low";
    };

    const kpiCards = [
      { cls: "", icon: "¥", val: priv(moneyFmtCNY(kpi.portfolioContract)), label: "合同总额", detail: "全库 Σ totalAmount" },
      { cls: "kpi-card--paid", icon: "收", val: priv(moneyFmtCNY(kpi.portfolioPaid)), label: "已收", detail: "全库 Σ paidAmount" },
      { cls: "kpi-card--unpaid", icon: "待", val: priv(moneyFmtCNY(kpi.portfolioUnpaid)), label: "待收", detail: "存量 · 主卡" },
      { cls: "kpi-card--overdue", icon: "逾", val: priv(moneyFmtCNY(kpi.portfolioOverdue)), label: "逾期", detail: kpi.overdueRiskCount ? ("另有风险 " + kpi.overdueRiskCount) : "有截止日且待收" },
      { cls: "kpi-card--count", icon: "#", val: priv(String(kpi.pricedCount)), label: "有金额项目", detail: "totalAmount > 0" },
    ].map(c => `
      <article class="kpi-card ${c.cls}">
        <div class="kpi-top"><div class="kpi-icon">${c.icon}</div></div>
        <div class="kpi-value">${esc(c.val)}</div>
        <div class="kpi-label">${esc(c.label)}</div>
        <div class="kpi-detail">${esc(c.detail)}</div>
      </article>`).join("");

    const cRate = privacy ? null : ringPct(kpi.yearContract, kpi.yearContractTarget);
    const pRate = privacy ? null : ringPct(kpi.yearPaid, kpi.yearCollectionTarget);
    const goals = [
      {
        paid: false,
        color: "#3B82F6",
        pct: cRate,
        label: privacy ? PRIVACY_LABEL : pctRate(kpi.yearContract, kpi.yearContractTarget),
        title: "合同目标",
        sub: "完成率",
        detail: privacy ? "—" : (kpi.yearContractTarget == null ? "目标待设定" : ("本年合同 " + moneyFmtCNY(kpi.yearContract) + " / " + moneyFmtCNY(kpi.yearContractTarget)))
      },
      {
        paid: true,
        color: "#10B981",
        pct: pRate,
        label: privacy ? PRIVACY_LABEL : pctRate(kpi.yearPaid, kpi.yearCollectionTarget),
        title: "回款目标",
        sub: "完成率",
        detail: privacy ? "—" : (kpi.yearCollectionTarget == null ? "目标待设定" : ("本年已收 " + moneyFmtCNY(kpi.yearPaid) + " / " + moneyFmtCNY(kpi.yearCollectionTarget)))
      },
      {
        paid: false,
        color: "#8B5CF6",
        pct: privacy ? null : 100,
        label: privacy ? PRIVACY_LABEL : moneyFmtCNY(kpi.yearContract).replace("¥", "¥"),
        title: "本年合同额",
        sub: "合同归属年",
        detail: privacy ? "—" : moneyFmtCNY(kpi.yearContract)
      },
      {
        paid: false,
        color: "#F59E0B",
        pct: privacy ? null : (kpi.yearContract > 0 ? Math.min(100, (kpi.monthContract / kpi.yearContract) * 100) : null),
        label: privacy ? PRIVACY_LABEL : moneyFmtCNY(kpi.monthContract),
        title: "本月合同额",
        sub: "合同归属月",
        detail: privacy ? "—" : moneyFmtCNY(kpi.monthContract)
      },
    ].map(g => `
      <article class="goal-card ${g.paid ? "goal-card--paid" : ""}">
        <div class="ring-wrap">
          <div class="ring" style="${ringStyle(g.pct, g.color)}"></div>
          <div class="ring-label">${esc(g.label.length > 6 ? g.label.slice(0, 6) : g.label)}</div>
        </div>
        <div class="goal-text">
          <div class="v">${esc(g.title)}</div>
          <div class="l">${esc(g.sub)}</div>
          <div class="d">${esc(g.detail)}</div>
        </div>
      </article>`).join("");

    const qualityHtml = (kpi.quality || []).length
      ? `<div class="quality">数据质量：${esc(kpi.quality.map(q => q.label + " " + q.count).join(" · "))}</div>`
      : "";

    const statusKeys = [["in_progress","进行中","#1D4ED8"],["delivered","已交付","#15803D"],["infrastructure","筹建","#6D28D9"],["inactive","挂起","#C2410C"]];
    const statusHtml = statusKeys.map(([k,lab,col]) => {
      const n = webs.filter(w => w.status === k).length;
      return `<div class="dist-row-item"><span class="dot" style="background:${col}"></span>${esc(lab)}<span class="cnt">${n}</span></div>`;
    }).join("");
    const payKeys = [["fully_paid","已结清"],["deposit_paid","已付定金"],["pending","待收款"]];
    const payHtml = payKeys.map(([k,lab]) => {
      const n = webs.filter(w => (w.paymentStatus || "") === k).length;
      return `<div class="dist-row-item"><span>${esc(lab)}</span><span class="cnt">${n}</span></div>`;
    }).join("") + `<div class="dist-row-item"><span>逾期风险(无截止)</span><span class="cnt">${kpi.overdueRiskCount || 0}</span></div>`;

    const top = webs.filter(w => w.status === "in_progress" || w.status === "infrastructure")
      .sort((a, b) => (b.progress || 0) - (a.progress || 0)).slice(0, 5);
    const topHtml = top.length ? top.map(w => {
      const st = (WEBSITE_UI.statusMap[w.status] || {}).label || w.status;
      const pill = w.status === "infrastructure" ? "pill-build" : "pill-prog";
      return `<div class="prio-item"><span class="pill ${pill}">${esc(st)} · ${w.progress || 0}%</span><span class="prio-name">${esc(w.name)}</span><span class="prio-pct">${w.progress || 0}%</span></div>`;
    }).join("") : `<p class="muted">暂无进行中项目</p>`;

    const colMeta = [
      ["待办", "kdot-todo"],
      ["进行中", "kdot-doing"],
      ["验收", "kdot-review"],
      ["完成", "kdot-done"],
    ];
    const colMap = { "待办": [], "进行中": [], "验收": [], "完成": [] };
    for (const t of tasks) {
      const st = t.status === "审核" ? "验收" : t.status;
      (colMap[st] || colMap["待办"]).push(t);
    }
    const kanban = colMeta.map(([col, dot]) => {
      const items = (colMap[col] || []).slice(0, 8).map(t =>
        `<div class="task-chip"><div class="task-chip__title">${esc(t.title)}</div><div class="task-chip__meta">工作台</div></div>`
      ).join("") || `<div class="muted" style="font-size:12px;padding:8px">—</div>`;
      return `<div class="kanban-col"><div class="kanban-col__head"><span class="kdot ${dot}"></span>${esc(col)} <span class="n">${(colMap[col]||[]).length}</span></div>${items}</div>`;
    }).join("");

    let emailHtml = "";
    if (!state.emailDaily.length) {
      emailHtml = `<div class="quality" style="background:#F8FAFC;color:#737373">暂无每日邮件总结。放入 bots/外贸营销/超级邮件助手/deliverables/email-daily/YYYY-MM-DD.json 后同步。</div>`;
    } else {
      emailHtml = state.emailDaily.map(day => {
        const open = state.expandedEmail === day.date;
        const cats = day["清理分类"] || {};
        const catStr = Object.keys(cats).map(k => k + " " + cats[k]).join(" · ");
        const tags = (day["话题标签"] || []).map(t => `<span class="ecap ecap-clean">${esc(t)}</span>`).join("");
        const cards = (day["重要邮件"] || []).map(m => {
          const u = m["紧急度"] || "";
          const uc = urgencyClass(u);
          return `<article class="email-card email-card--${uc}">
            <div class="email-card__bar"></div>
            <div class="email-card__body">
              <div class="email-card__top">
                <span class="email-card__company">${esc(m["发件方"] || "—")}</span>
                <span class="email-card__urgency">${esc(u)}</span>
              </div>
              <div class="email-card__subject">${esc(m["主题"] || "—")}</div>
              <div class="email-card__summary">${esc(m["摘要"] || "")}</div>
              ${m["待办"] ? `<div class="email-card__todo">待办：${esc(m["待办"])}</div>` : ""}
            </div>
          </article>`;
        }).join("");
        return `<div class="email-day">
          <button type="button" class="email-day__head" data-email-day="${esc(day.date)}">
            <span class="email-day__date">${esc(day.date)}</span>
            <span class="ecap ecap-new">新${day["新邮件数"] ?? 0}</span>
            <span class="ecap ecap-clean">清理${day["已清理数"] ?? 0}</span>
            <span class="ecap ecap-pend">待回${day["待回复数"] ?? 0}</span>
            <span style="margin-left:auto;color:#8A8A8E;font-size:12px">${open ? "▴" : "▾"}</span>
          </button>
          ${open ? `<div>
            ${day.source ? `<p class="muted" style="font-size:12px;margin:8px 0">${esc(day.source)}</p>` : ""}
            ${catStr ? `<p class="muted" style="font-size:12px">清理：${esc(catStr)}</p>` : ""}
            <div style="display:flex;flex-wrap:wrap;gap:6px;margin:6px 0">${tags}</div>
            <div class="email-grid">${cards || '<p class="muted">重要邮件正文仅 Mac 本地可读（Pages 已脱敏）</p>'}</div>
          </div>` : ""}
        </div>`;
      }).join("");
    }

    const order = groupOrder();
    const shortCard = (b) => `<button type="button" class="emp-card dense" data-bot="${esc(b.id)}">
        <div class="emp-avatar-wrap dense"><img class="emp-avatar-img dense" src="${avatarSrc(b)}" alt="" loading="lazy" decoding="async" onerror="this.onerror=null;this.style.display='none';this.nextElementSibling.style.display='flex'"/><div class="emp-avatar-fallback dense" style="display:none">${esc((b.name||'?')[0])}</div></div>
        <div class="emp-meta dense"><span class="emp-pill">${esc(b.code||"—")}</span><span class="dot ok"></span></div>
        <div class="emp-name dense">${esc(displayNick(b.name))}</div>
        <div class="emp-role dense">${esc(displayTitle(b.name,b.role))}</div>
      </button>`;
    let roster = "";
    for (const g of order) {
      const items = state.botsByGroup[g] || bots.filter(b => botInGroup(b, g));
      if (!items.length) continue;
      roster += `<div class="group-shell"><div class="group-head"><h3>${esc(g)}</h3><span class="badge">${items.length}</span></div><div class="emp-grid dense ov-row">${items.map(shortCard).join("")}</div></div>`;
    }

    return `
      <div class="overview-main">
      <div class="section-title-row"><h2 class="section-title">工作台总览</h2></div>
      <p class="muted"><b>网站业绩</b> · 日程 · 邮件 · 员工 · 基准 ${esc(kpi.asOf)} · ${privacy ? "金额" + PRIVACY_LABEL : "本地完整金额"} · v2</p>
      <div class="overview-stack">
      ${renderTradeKeyStrip()}
      ${wbHints.showWebsiteProjects === false ? "" : `<section class="section-shell">
        <div class="section-shell__head"><h3 class="section-shell__title">网站项目看板</h3><span class="section-shell__badge">${webs.length}</span></div>
        <div class="section-shell__meta">口径：金算盘 · CNY</div>
        <div class="section-subhead" style="margin-top:0">存量健康</div>
        <div class="kpi-grid">${kpiCards}</div>
        <div class="section-subhead">本年目标完成率</div>
        <div class="goal-grid">${goals}</div>
        ${qualityHtml}
        <div class="dist-row">
          <div class="dist-box"><h4>状态分布</h4>${statusHtml}</div>
          <div class="dist-box"><h4>收款状态</h4>${payHtml}</div>
        </div>
        <div class="section-subhead">进行中优先</div>
        <div class="prio-list">${topHtml}</div>
      </section>`}
      <section class="section-shell">
        <div class="section-shell__head"><h3 class="section-shell__title">日程管理 · 任务看板</h3><span class="section-shell__badge">${tasks.length}</span></div>
        <div class="section-shell__meta">只读 · 工作台任务</div>
        <div class="kanban-row">${kanban}</div>
      </section>
      <section class="section-shell">
        <div class="section-shell__head"><h3 class="section-shell__title">邮件看板</h3><span class="section-shell__badge">${state.emailDaily.length}</span></div>
        <div class="section-shell__meta">信鸽-邮件助手 · email-daily</div>
        ${emailHtml}
      </section>
      <section class="section-shell">
        <div class="section-shell__head"><h3 class="section-shell__title">员工看板</h3><span class="section-shell__badge">${bots.length}</span></div>
        <div class="roster-groups-ov">${roster}</div>
      </section>
      </div>
      </div>`;
  }

function renderRoster() {
    const order = groupOrder();
    const filter = state.layerFilter;
    const q = (document.getElementById("q") && document.getElementById("q").value || "").toLowerCase();
    const match = (b) => !q || (b.name+b.role+(b.group||"")+ (b.code||"")).toLowerCase().includes(q);
    const all = (state.data.bots||[]).filter(match);
    const chips = ["全部"].concat(order);
    const chipHtml = chips.map(g => {
      const n = g==="全部" ? all.length : all.filter(b => botInGroup(b,g)).length;
      return `<button type="button" class="chip ${filter===g?"active":""}" data-layer="${esc(g)}">${esc(g)} ${n}</button>`;
    }).join("");
    // Same card + group shell markup as overview 员工看板
    const rosterCard = (b) => `
      <button type="button" class="emp-card dense" data-bot="${esc(b.id)}">
        <div class="emp-avatar-wrap dense"><img class="emp-avatar-img dense" src="${avatarSrc(b)}" alt="" loading="lazy" decoding="async" onerror="this.onerror=null;this.style.display='none';this.nextElementSibling.style.display='flex'"/><div class="emp-avatar-fallback dense" style="display:none">${esc((b.name||'?')[0])}</div></div>
        <div class="emp-meta dense"><span class="emp-pill">${esc(b.code||"—")}</span><span class="dot ok"></span></div>
        <div class="emp-name dense">${esc(displayNick(b.name))}</div>
        <div class="emp-role dense">${esc(displayTitle(b.name,b.role))}</div>
      </button>`;
    const groups = (filter==="全部" ? order : [filter]).map(g => {
      const items = all.filter(b => botInGroup(b,g));
      if (!items.length) return "";
      return `<div class="group-shell"><div class="group-head"><h3>${esc(g)}</h3><span class="badge">${items.length}</span></div><div class="emp-grid dense ov-row">${items.map(rosterCard).join("")}</div></div>`;
    }).join("");
    return `
      <h2 class="section-title">员工档案 <span class="badge">${all.length}</span></h2>
      <p class="muted">员工实时对话与工作摘要请在 Mac「超级工作台」App 打开（私有目录 Application Support/超级工作台/conversations/）。</p>
      <div class="filters">${chipHtml}</div>
      <div class="roster-groups-ov">${groups}</div>`;
  }

  function renderProjects() {
    const webs = state.data.websiteProjects || [];
    const products = state.data.projects || [];
    if (!state.webView) state.webView = WEBSITE_UI.defaultView || "list";
    if (!state.webCat) state.webCat = "全部";
    if (!state.webTab) state.webTab = "crm";
    const sync = state.data.smartplanSync || {};
    const catCount = Object.create(null);
    for (const w of webs) catCount[w.category] = (catCount[w.category] || 0) + 1;
    const cats = ["全部"].concat(Object.keys(catCount).sort());
    const filtered = webs.filter(w => state.webCat === "全部" || w.category === state.webCat)
      .slice().sort((a,b) => {
        const ua=a.updatedAt||"", ub=b.updatedAt||"";
        if (ua!==ub) return ua>ub?-1:1;
        return statusRank(a.status)-statusRank(b.status);
      });
    const productLink = products[0]
      ? `<button type="button" class="btn" id="openProduct" title="产品项目（不混入列表）">${esc(products[0].shortName||products[0].name)}</button>`
      : "";
    const toolbar = `
      <div class="web-toolbar">
        <div class="filters">
          <button type="button" class="chip ${state.webView==="list"?"active":""}" data-webview="list">列表</button>
          <button type="button" class="chip ${state.webView==="cards"?"active":""}" data-webview="cards">卡片</button>
        </div>
        <div class="filters">${cats.map(c=>{
          const n=c==="全部"?webs.length:(catCount[c]||0);
          return `<button type="button" class="chip ${state.webCat===c?"active":""}" data-webcat="${esc(c)}">${esc(c)} ${n}</button>`;
        }).join("")}</div>
        <span class="muted">SmartPlan ${esc(sync.source||"—")} · ${webs.length}</span>
        <span style="flex:1"></span>
        ${productLink}
      </div>`;

    if (!state.webShown || state.webShown < state.webPageSize) state.webShown = state.webPageSize;
    const page = filtered.slice(0, state.webShown);
    const hasMore = filtered.length > page.length;
    let body = "";
    if (state.webView === "cards") {
      body = `<div class="web-card-grid">${page.map(w => webCard(w)).join("")}</div>`;
    } else {
      body = `<div class="web-table-wrap"><table class="web-table">
        <thead><tr><th>项目</th><th>客户</th><th>状态</th><th>进度</th><th>截止</th><th>负责人</th></tr></thead>
        <tbody>${page.map(w => webListRow(w)).join("")}</tbody>
      </table></div>`;
    }
    if (hasMore) {
      body += `<div style="text-align:center;padding:16px"><button type="button" class="btn" id="webLoadMore">加载更多（已显示 ${page.length}/${filtered.length}）</button></div>`;
    }
    const modal = state.selectedWebId ? webDetailModal(webs.find(x=>x.id===state.selectedWebId)) : "";
    return `<h2 class="section-title">网站项目</h2>${toolbar}${body}${modal}`;
  }

  function statusRank(s) {
    return s==="in_progress"?0:s==="infrastructure"?1:s==="delivered"?2:s==="inactive"?3:9;
  }
  function statusLabel(s) {
    return (WEBSITE_UI.statusMap[s]||{}).label || s;
  }
  function ownerName(id) {
    const b = (id && state.botById[id]) || (state.data.bots||[]).find(x=>x.id===id);
    return b ? displayNick(b.name) : "—";
  }
  function webListRow(w) {
    const owner = state.botById[w.ownerBotId||""] || (state.data.bots||[]).find(b=>b.id===(w.ownerBotId||""));
    const av = owner ? `<img class="web-owner" src="${avatarSrc(owner)}" alt="" loading="lazy" decoding="async" onerror="this.onerror=null;this.style.display='none'"/>` : `<span class="web-owner empty">—</span>`;
    const pill = (WEBSITE_UI.statusMap[w.status]||{}).pill || "hold";
    const pay = w.paymentStatus==="fully_paid"?"已结清":w.paymentStatus==="deposit_paid"?"已付定金":"待付款";
    const url = (w.url||"").replace(/^https?:\/\//,"");
    const svc = (w.services||[]).slice(0,2).join(" · ") || "—";
    const dead = w.deadline||w.serviceEndDate||"—";
    const upd = (w.updatedAt||"").slice(0,10)||"—";
    return `<tr class="web-row" data-web="${esc(w.id)}">
      <td><div class="web-namecell"><span class="web-init ${esc(w.status)}">${esc((w.name||"?").slice(0,1))}</span><div><strong>${esc(w.name)}</strong></div></div></td>
      <td><span class="status-pill status-pill--${pill}">${esc(w.category||statusLabel(w.status))}</span></td>
      <td>${esc(w.clientName||w.clientCompany||"—")}</td>
      <td class="mono">${esc(url||"—")}</td>
      <td>${esc(w.framework||"—")}</td>
      <td>${esc(svc)}</td>
      <td><div class="bar"><i style="width:${esc(String(w.progress||0))}%"></i></div> ${esc(String(w.progress||0))}%</td>
      <td>${esc(pay)}</td>
      <td class="mono">${esc(dead)}</td>
      <td>${av}</td>
      <td class="mono" title="${esc(w.updatedAt||"")}">${esc(upd)}</td>
    </tr>`;
  }
function webCard(w) {
    return `<button type="button" class="web-card emp-card" data-web="${esc(w.id)}">
      <div class="emp-avatar-wrap dense"><div class="web-init big ${esc(w.status)}">${esc((w.name||"?").slice(0,1).toUpperCase())}</div></div>
      <div class="emp-meta dense"><span class="emp-pill">${esc((w.framework||"WEB").slice(0,6))}</span>
        <span class="badge status-${esc(w.status)}">${esc(w.category||"")}</span></div>
      <div class="emp-name dense">${esc(w.name)}</div>
      <div class="emp-role dense">${esc(w.clientName||w.clientCompany||"—")}</div>
      <div class="bar" style="width:100%;margin-top:8px"><i style="width:${esc(String(w.progress||0))}%"></i></div>
    </button>`;
  }
  function webDetailModal(w) {
    if (!w) return "";
    const tab = state.webTab || "crm";
    const tabs = WEBSITE_UI.detailTabs.map(t =>
      `<button type="button" class="chip ${tab===t.id?"active":""}" data-webtab="${t.id}">${t.title}</button>`).join("");
    let pane = "";
    if (tab === "crm") {
      pane = `<div class="props">
        <div class="row"><div class="k">客户</div><div>${esc(w.clientName||"—")}</div></div>
        <div class="row"><div class="k">公司</div><div>${esc(w.clientCompany||"—")}</div></div>
        <div class="row"><div class="k">服务</div><div>${esc((w.services||[]).join(" · ")||"—")}</div></div>
        <div class="row"><div class="k">周期</div><div>${esc(w.serviceStartDate||"—")} → ${esc(w.deadline||w.serviceEndDate||"—")}</div></div>
        <div class="row"><div class="k">负责人</div><div>${esc(ownerName(w.ownerBotId))}</div></div>
      </div>`;
    } else if (tab === "finance") {
      pane = `<div class="props">
        <div class="row"><div class="k">总额</div><div>${esc(moneyFmt(w.totalAmount))}</div></div>
        <div class="row"><div class="k">定金</div><div>${esc(moneyFmt(w.depositAmount))}</div></div>
        <div class="row"><div class="k">已付</div><div>${esc(moneyFmt(w.paidAmount))}</div></div>
        <div class="row"><div class="k">未付</div><div>${esc(moneyFmt(w.unpaidAmount))}</div></div>
        <div class="row"><div class="k">付款</div><div>${esc(w.paymentStatus||"—")}</div></div>
      </div>`;
    } else {
      pane = `<div class="props">
        <div class="row"><div class="k">URL</div><div>${esc(w.url||"—")}</div></div>
        <div class="row"><div class="k">框架</div><div>${esc(w.framework||"—")}</div></div>
        <div class="row"><div class="k">路径</div><div><code>${esc(w.localPath||"—")}</code></div></div>
        <div class="row"><div class="k">描述</div><div>${esc(w.description||w.detail||"—")}</div></div>
        <div class="row"><div class="k">进度</div><div>${esc(String(w.progress||0))}%</div></div>
      </div>
      <div class="card-actions" style="margin-top:12px">
        <select id="webStatus">${Object.keys(WEBSITE_UI.statusMap).map(k=>{
          const m=WEBSITE_UI.statusMap[k];
          return `<option value="${k}|${m.category}" ${w.status===k?"selected":""}>${m.label}</option>`;
        }).join("")}</select>
        <button type="button" class="btn primary" id="saveWebStatus">保存状态（同步时写回）</button>
      </div>`;
    }
    return `<div class="modal-backdrop modal-overlay" id="webModal">
      <div class="modal-card modal">
        <div class="modal-head">
          <div><h3>${esc(w.name)} <span class="badge status-${esc(w.status)}">${esc(w.category||"")}</span></h3>
            <p class="muted">${esc(w.url||"未配置线上网址")}</p></div>
          <button type="button" class="btn" id="closeWebModal">关闭</button>
        </div>
        <div class="filters" style="padding:8px 16px">${tabs}</div>
        <div class="modal-body">${pane}</div>
        <p class="muted" style="padding:0 16px 12px">联系方式/凭证不同步。字段配置：data/ui-config.json</p>
      </div>
    </div>`;
  }

function renderKanban() {
    const tasks = scopedTasks();
    const edit = selectedTask();
    const names = botNames();
    const cols = COLS.map((c) => {
      const items = tasks.filter((t) => t.status === c).map((t) =>
        `<div class="task ${edit && t.id === edit.id ? "selected" : ""}" data-task="${esc(t.id)}" draggable="true">
          <div class="t">${esc(t.title)}</div>
          <div class="m">执行：${esc(t.executor)} · 验收：${esc(t.reviewer)}</div>
          <div class="m">${esc(t.note)}</div>
        </div>`
      ).join("");
      return `<div class="col" data-col="${esc(c)}"><h3>${c}（${tasks.filter((t)=>t.status===c).length}）</h3>${items || '<p class="muted">拖入卡片</p>'}</div>`;
    }).join("");
    const optBots = names.map((n) => `<option value="${esc(n)}">${esc(n)}</option>`).join("");
    const optReview = names.concat(["用户"]).map((n) => `<option value="${esc(n)}">${esc(n)}</option>`).join("");
    return `
      <h2 class="section-title">任务看板</h2>
      <p class="muted">拖拽卡片到任意列改状态（localStorage；Pages 不能写仓库文件）。亦可 ←/→。</p>
      <div class="kanban">${cols}</div>
      ${edit ? `
      <h3>编辑选中任务</h3>
      <div class="field"><label>标题</label><input id="editTitle" value="${esc(edit.title)}"/></div>
      <div class="field"><label>备注</label><input id="editNote" value="${esc(edit.note)}"/></div>
      <div class="field"><label>执行人</label><select id="editExec">${names.map((n)=>`<option ${n===edit.executor?"selected":""}>${esc(n)}</option>`).join("")}</select></div>
      <div class="field"><label>验收人</label><select id="editReview">${names.concat(["用户"]).map((n)=>`<option ${n===edit.reviewer?"selected":""}>${esc(n)}</option>`).join("")}</select></div>
      <div class="field"><label>状态</label><select id="editStatus">${COLS.map((c)=>`<option ${c===edit.status?"selected":""}>${c}</option>`).join("")}</select></div>
      <div class="card-actions">
        <button type="button" id="saveTask" class="btn primary">保存</button>
        <button type="button" id="movePrev">← 上一列</button>
        <button type="button" id="moveNext">下一列 →</button>
        <button type="button" id="delTask">删除</button>
      </div>` : ""}
      <hr style="border-color:var(--border);margin:20px 0"/>
      <h3>新增任务</h3>
      <div class="field"><label>标题</label><input id="newTitle" placeholder="任务标题"/></div>
      <div class="field"><label>备注</label><input id="newNote" placeholder="约束或依赖"/></div>
      <div class="field"><label>执行人</label><select id="newExec">${optBots}</select></div>
      <div class="field"><label>验收人</label><select id="newReview">${optReview}</select></div>
      <button type="button" class="btn primary" id="addTask">添加任务</button>`;
  }

  function renderGroups() {
    const g = (state.data.groups || [])[0];
    if (!g) return "<p>暂无群聊</p>";
    const steps = (g.steps || []).map((s) =>
      `<div class="step"><h4>${esc(s.title)}</h4><p>${esc(s.detail)}</p></div>`
    ).join("");
    return `
      <h2 class="section-title">群聊协作</h2>
      <div class="props">
        <div class="row"><div class="k">群名</div><div>${esc(g.name)}</div></div>
        <div class="row"><div class="k">成员</div><div>${esc((g.members||[]).join(" · "))}</div></div>
        <div class="row"><div class="k">日期</div><div>${esc(g.date)}</div></div>
      </div>
      ${steps}
      <div class="callout"><strong>交接铁律</strong>交付物存成文件；下一岗读文件接着干；干活与验收分开。</div>`;
  }

  function renderRoutines() {
    const rows = (state.data.routines || []).map((r) =>
      `<tr><td>${esc(r.name)}</td><td>${esc(r.when)}</td><td>${esc(r.who)}</td><td>${esc(r.what)}</td><td><span class="badge warn">${esc(r.status || "规划中，未启用")}</span></td></tr>`
    ).join("");
    return `
      <h2 class="section-title">定时巡检</h2>
      <div class="callout warn"><strong>规划中，未启用</strong>以下定时任务仅为规划清单，尚未真正创建或调度。</div>
      <table><thead><tr><th>任务</th><th>节奏</th><th>负责人</th><th>内容</th><th>状态</th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  }

  function renderHire() {
    const vac = state.data.vacancies || [];
    const rows = vac.map((v) =>
      `<tr>
        <td>${esc(v.name)}${v.priority ? "（建议优先）" : ""}</td>
        <td>${esc(v.layer)}</td><td>${esc(v.duty)}</td><td>${esc(v.toolNote)}</td>
        <td>${v.confirmed ? '<span class="badge ok">已确认招聘</span>' : '<span class="badge">待确认</span>'}</td>
        <td><button type="button" data-hire="${esc(v.id)}" class="btn">${v.confirmed ? "已确认" : "确认招聘"}</button></td>
      </tr>`
    ).join("");
    return `
      <h2 class="section-title">招聘规划</h2>
      <p class="muted">点「确认招聘」仅本地标记，不会自动创建 Bot。</p>
      <table><thead><tr><th>岗位</th><th>层级</th><th>职责</th><th>工具备注</th><th>状态</th><th></th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  }

  function renderRules() {
    const items = (state.data.rules || []).map((r) =>
      `<li>${esc(r.text)} <span class="badge">${esc(r.meta)}</span></li>`
    ).join("");
    return `
      <h2 class="section-title">规则与文档</h2>
      <ul class="check">${items}</ul>
      <div class="callout warn"><strong>权限边界</strong>外部模型只能作为工具调用，不能替换 Bot 的大脑。Key 由你加密提供。仓库中请勿提交任何 Token。</div>
      <div class="step"><h4>派单</h4><p>幕僚长拆解并指定执行人与验收人。</p></div>
      <div class="step"><h4>执行</h4><p>执行人交付文件化结果到群聊/工作台。</p></div>
      <div class="step"><h4>验收</h4><p>验收人核对；通过后才可进入对外动作审批。</p></div>
      <div class="step"><h4>复盘</h4><p>缺口与教训写回规则与测试用例。</p></div>`;
  }

  function renderMain() {
    const map = {
      "总览": renderOverview,
      "员工档案": renderRoster,
      "任务看板": renderKanban,
      "任务与日程中心": renderScheduleCenter,
      "每日总结": renderDailySummary,
      "每日 SEO": () => renderDailySeo(),
      "客户与线索": () => renderTradeModule("leads"),
      "客户管理": () => renderCrmCustomers(),
      "开发进度": () => renderTradeModule("pipeline"),
      "询盘与报价": () => renderTradeModule("quotes"),
      "群聊协作": renderGroups,
      "定时巡检": renderRoutines,
      "招聘规划": renderHire,
      "规则与文档": renderRules,
      "网站项目": renderProjects,
    };
    if (isTradeWorkbench()) {
      document.getElementById("main").innerHTML = renderTradeMagicHub();
    } else {
      document.getElementById("main").innerHTML = (map[state.tab] || renderOverview)();
    }
    bindMain();
  }

  function bindMain() {
    document.querySelectorAll("[data-bot]").forEach((el) => {
      el.onclick = () => { state.selectedId = el.getAttribute("data-bot"); state.tab = "员工档案"; saveLocal(); render(); };
    });
    document.querySelectorAll("[data-layer]").forEach((el) => {
      el.onclick = () => { state.layerFilter = el.getAttribute("data-layer"); render(); };
    });
    document.querySelectorAll("[data-task]").forEach((el) => {
      el.onclick = () => { state.editTaskId = el.getAttribute("data-task"); render(); };
    });
    document.querySelectorAll("[data-hire]").forEach((el) => {
      el.onclick = () => confirmHire(el.getAttribute("data-hire"));
    });
    const saveBot = document.getElementById("saveBot");
    if (saveBot) saveBot.onclick = () => {
      updateBot(selectedBot().id, {
        status: document.getElementById("botStatus").value,
        progress: Math.max(0, Math.min(100, Number(document.getElementById("botProgress").value) || 0)),
        okr: document.getElementById("botOkr").value,
        weekly: document.getElementById("botWeekly").value,
      });
      toast("档案已保存到本地");
    };
    const saveTask = document.getElementById("saveTask");
    if (saveTask) saveTask.onclick = () => {
      updateTask(selectedTask().id, {
        title: document.getElementById("editTitle").value,
        note: document.getElementById("editNote").value,
        executor: document.getElementById("editExec").value,
        reviewer: document.getElementById("editReview").value,
        status: document.getElementById("editStatus").value,
      });
      toast("任务已保存");
    };
    const mp = document.getElementById("movePrev");
    if (mp) mp.onclick = () => moveTask(selectedTask().id, -1);
    const mn = document.getElementById("moveNext");
    if (mn) mn.onclick = () => moveTask(selectedTask().id, 1);
    const dt = document.getElementById("delTask");
    if (dt) dt.onclick = () => { deleteTask(selectedTask().id); toast("已删除"); };
    const at = document.getElementById("addTask");
    if (at) at.onclick = addTask;
    let dragId = null;
    document.querySelectorAll(".task[draggable]").forEach((el) => {
      el.addEventListener("dragstart", (e) => {
        dragId = el.getAttribute("data-task");
        el.classList.add("task--dragging");
        try { e.dataTransfer.setData("text/plain", dragId); e.dataTransfer.effectAllowed = "move"; } catch (_) {}
      });
      el.addEventListener("dragend", () => {
        el.classList.remove("task--dragging");
        document.querySelectorAll(".col.col--drop").forEach((c) => c.classList.remove("col--drop"));
        dragId = null;
      });
    });
    document.querySelectorAll(".col[data-col]").forEach((col) => {
      col.addEventListener("dragover", (e) => { e.preventDefault(); col.classList.add("col--drop"); });
      col.addEventListener("dragleave", () => col.classList.remove("col--drop"));
      col.addEventListener("drop", (e) => {
        e.preventDefault();
        col.classList.remove("col--drop");
        const id = dragId || (e.dataTransfer && e.dataTransfer.getData("text/plain"));
        const status = col.getAttribute("data-col");
        if (id && status) { updateTask(id, { status }); toast("已移动到「" + status + "」（localStorage）"); }
      });
    });
    document.querySelectorAll("[data-cal-shift]").forEach((el) => {
      el.onclick = () => shiftCalMonth(Number(el.getAttribute("data-cal-shift")));
    });
    const calToday = document.querySelector("[data-cal-today]");
    if (calToday) calToday.onclick = () => {
      const n = new Date();
      state.calMonth = n.getFullYear() + "-" + String(n.getMonth() + 1).padStart(2, "0");
      state.scheduleLoadedMonth = null;
      state.calSelected = state.calMonth + "-" + String(n.getDate()).padStart(2, "0");
      render();
    };
    document.querySelectorAll("[data-cal-day]").forEach((el) => {
      el.onclick = () => { state.calSelected = el.getAttribute("data-cal-day"); render(); };
    });
    document.querySelectorAll("[data-open-daily]").forEach((el) => {
      el.onclick = () => { state.dailyReportDate = el.getAttribute("data-open-daily"); state.tab = "每日总结"; render(); };
    });
    document.querySelectorAll("[data-daily-date]").forEach((el) => {
      el.onclick = () => { state.dailyReportDate = el.getAttribute("data-daily-date"); render(); };
    });
    document.querySelectorAll("[data-seo-date]").forEach((el) => {
      el.onclick = async () => {
        await loadSeoFeedDay(el.getAttribute("data-seo-date"));
        render();
      };
    });
    document.querySelectorAll("[data-wb]").forEach((el) => {
      el.onclick = () => switchWorkbench(el.getAttribute("data-wb"));
    });
    document.querySelectorAll("[data-crm-page]").forEach((el) => {
      el.onclick = async () => {
        const p = Number(el.getAttribute("data-crm-page") || "0");
        await loadCrmPage(p);
        render();
      };
    });
    if (state.tab === "任务与日程中心" && state.scheduleLoadedMonth !== state.calMonth) {
      loadScheduleMonth(state.calMonth).then(() => render());
    }
    if (state.tab === "每日总结" && !(state.dailyReportDates || []).length) {
      fetch("./data/daily-reports-index.json", { cache: "no-store" }).then(r => r.ok ? r.json() : null).then(idx => {
        if (!idx) return;
        state.dailyReportDates = idx.dates || [];
        if (!state.dailyReportDate && state.dailyReportDates[0]) state.dailyReportDate = state.dailyReportDates[0];
        render();
      }).catch(() => {});
    }
  }


  function render() {
    const wb = (state.workbenches || []).find(w => w.id === state.activeWorkbenchId) || (state.workbenches || [])[0];
    const titleEl = document.getElementById("wbTitle");
    if (titleEl) titleEl.textContent = (wb && (wb.shortName || wb.name)) || "超级工作台";
    const ds = document.getElementById("dataSource");
    if (ds) ds.textContent = "数据源：" + state.source;
    const seg = document.getElementById("wbSegment");
    if (seg) {
      seg.innerHTML = renderWorkbenchSegment();
      bindWorkbenchSegment();
    }
    const tabs = document.getElementById("tabs");
    if (isTradeWorkbench()) {
      const cur = magicHubTabId();
      tabs.innerHTML = MAGICHUB_NAV.map((t) =>
        `<button type="button" class="${cur === t.id ? "active" : ""}" data-mh-tab="${t.id}"><span class="nav-label">${esc(t.name)}</span></button>`
      ).join("");
      tabs.querySelectorAll("[data-mh-tab]").forEach((el) => {
        el.onclick = () => {
          setMagicHubTab(el.getAttribute("data-mh-tab"));
          // Re-render sidebar active only (avoid remounting iframe)
          tabs.querySelectorAll("[data-mh-tab]").forEach((b) => {
            b.classList.toggle("active", b.getAttribute("data-mh-tab") === state.magicHubTab);
          });
        };
      });
    } else {
      tabs.innerHTML = workbenchTabs().map((t) =>
        `<button type="button" class="${state.tab === t ? "active" : ""}" data-tab="${t}"><span class="nav-label">${TAB_NAV_LABEL[t] || t}</span></button>`
      ).join("");
      tabs.querySelectorAll("[data-tab]").forEach((el) => {
        el.onclick = () => setTab(el.getAttribute("data-tab"));
      });
    }
    renderMain();
    const more = document.getElementById("webLoadMore");
    if (more) more.onclick = () => { state.webShown = (state.webShown || state.webPageSize) + state.webPageSize; render(); };
    // Reset paging when switching category/view via chips (handled below)
  }

  window.addEventListener("message", (ev) => {
    try {
      const d = ev && ev.data;
      if (!d || d.type !== "sw-tab-changed" || !d.tab) return;
      if (state.magicHubTab === d.tab) return;
      state.magicHubTab = String(d.tab);
      try { localStorage.setItem("sw.mhTab", state.magicHubTab); } catch (_) {}
      if (isTradeWorkbench()) {
        document.querySelectorAll("#tabs [data-mh-tab]").forEach((b) => {
          b.classList.toggle("active", b.getAttribute("data-mh-tab") === state.magicHubTab);
        });
      }
    } catch (_) {}
  });

  async function boot() {
    state.calMonth = state.calMonth || new Date().toISOString().slice(0, 7);
    state.scheduleByDate = state.scheduleByDate || {};
    state.dailyReportDates = state.dailyReportDates || [];
    state.workbenches = state.workbenches || [];
    state.tradeIndex = state.tradeIndex || null;
    state.magicHubTab = state.magicHubTab || localStorage.getItem("sw.mhTab") || "dashboard";
    await loadWorkbenches();
    bindWorkbenchSegment();
    document.getElementById("btnExport").onclick = doExport;
    document.getElementById("btnReset").onclick = resetDefault;
    document.getElementById("fileImport").onchange = (e) => {
      const f = e.target.files && e.target.files[0];
      if (f) doImport(f);
      e.target.value = "";
    };
    // Instant first paint from embedded/localStorage — then refresh from JSON.
    try {
      const cached = loadLocal();
      const base = defaultData();
      if (cached && cached.bots && cached.bots.length) {
        state.data = Object.assign({}, base, {
          bots: cached.bots,
          tasks: cached.tasks || base.tasks,
          vacancies: cached.vacancies || base.vacancies,
          groups: cached.groups || base.groups,
          routines: cached.routines || base.routines,
          rules: cached.rules || base.rules,
        });
        state.source = "embedded + localStorage (preview)";
        state.selectedId = cached.selectedId || base.bots[0].id;
      } else {
        state.data = base;
        state.source = "embedded (preview)";
        state.selectedId = base.bots[0].id;
      }
      state.editTaskId = (state.data.tasks[0] && state.data.tasks[0].id) || null;
      rebuildIndexes();
      render();
    } catch (_) {}
    await loadData();
    await maybeApplyStressOverlay();
    await loadOverviewExtras();
    render();
  }

  boot().then(() => {
    if (window.SWGlobalAgent) {
      window.SWGlobalAgent.mount({
        getState: () => state,
        setTab,
        switchWorkbench,
        saveLocal,
        render
      });
    }
  });
})();


/* ---- Global model settings (shared with MagicHub) ---- */
(function wireGlobalSettings() {
  function $(id) { return document.getElementById(id); }
  async function openSettings() {
    const modal = $("swSettingsModal");
    const body = $("swSettingsBody");
    if (!modal || !body) return;
    modal.hidden = false;
    body.textContent = "加载中…";
    try {
      if (!window.SWSharedModels) throw new Error("shared-models.js 未加载");
      const doc = await window.SWSharedModels.loadDocument();
      const providers = doc.providers || [];
      body.innerHTML = "";
      providers.forEach((p, idx) => {
        const row = document.createElement("div");
        row.className = "sw-settings-row";
        row.dataset.idx = String(idx);
        row.innerHTML =
          '<label><input type="checkbox" data-f="status"' + (p.status ? " checked" : "") + "/> " +
          (p.name || p.id) + " <span class=\"muted\">(" + (p.id || "") + ")</span></label>" +
          '<label>Base URL</label><input data-f="baseUrl" value="' + String(p.baseUrl || p.baseURL || "").replace(/"/g, "&quot;") + '"/>' +
          '<label>Model</label><input data-f="model" value="' + String(p.model || "").replace(/"/g, "&quot;") + '"/>' +
          '<label>API Key（留空保留）</label><input data-f="apiKey" type="password" placeholder="' +
          (p.apiKey ? "•••• 已保存" : "未设置") + '" autocomplete="off"/>';
        body.appendChild(row);
      });
      body._providers = providers;
    } catch (e) {
      body.textContent = "加载失败: " + e;
    }
  }
  async function saveSettings() {
    const body = $("swSettingsBody");
    if (!body || !body._providers) return;
    const rows = [...body.querySelectorAll(".sw-settings-row")];
    const providers = body._providers.map((p, i) => {
      const row = rows[i];
      if (!row) return p;
      const next = { ...p };
      const st = row.querySelector('[data-f="status"]');
      const base = row.querySelector('[data-f="baseUrl"]');
      const model = row.querySelector('[data-f="model"]');
      const key = row.querySelector('[data-f="apiKey"]');
      if (st) next.status = !!st.checked;
      if (base) next.baseUrl = base.value.trim();
      if (model) next.model = model.value.trim();
      if (key && key.value.trim()) next.apiKey = key.value.trim();
      next.previewUrl = String(next.baseUrl || "").replace(/\/+$/, "") + "/chat/completions";
      next.type = next.type || "openai-compatible";
      return next;
    });
    await window.SWSharedModels.saveProviders(providers);
    alert("已保存全局模型配置（与外贸工作台共用）");
    $("swSettingsModal").hidden = true;
  }
  function closeSettings() {
    const modal = $("swSettingsModal");
    if (modal) modal.hidden = true;
  }
  function boot() {
    const btn = $("btnGlobalSettings");
    if (btn) btn.addEventListener("click", openSettings);
    const close = $("swSettingsClose");
    if (close) close.addEventListener("click", closeSettings);
    const save = $("swSettingsSave");
    if (save) save.addEventListener("click", saveSettings);
    const modal = $("swSettingsModal");
    if (modal) modal.addEventListener("click", (e) => { if (e.target === modal) closeSettings(); });
    window.SWOpenGlobalSettings = openSettings;
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
  else boot();
})();
