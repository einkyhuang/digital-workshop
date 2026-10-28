(function () {
  const LS_KEY = "digital-workshop-v2";
  const TABS = ["总览", "员工档案", "项目", "任务看板", "群聊协作", "定时巡检", "招聘规划", "规则与文档"];
  const COLS = ["待办", "进行中", "验收", "完成"];
  const state = {
    tab: "总览",
    data: null,
    selectedId: null,
    editTaskId: null,
    layerFilter: "全部",
    source: "embedded",
  };

  function toast(msg) {
    const el = document.getElementById("toast");
    el.textContent = msg;
    el.hidden = false;
    clearTimeout(toast._t);
    toast._t = setTimeout(() => { el.hidden = true; }, 2600);
  }

  function clone(x) { return JSON.parse(JSON.stringify(x)); }

  function defaultData() {
    return clone(window.__EMBEDDED_WORKSPACE__);
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

  async function loadData() {
    const cached = loadLocal();
    const paths = ["./data/workspace.json", "../data/workspace.json", "../../data/workspace.json", "data/workspace.json"];
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
          state.source = "json:" + p + (cached ? " + localStorage" : "");
          state.selectedId = (cached && cached.selectedId) || state.data.bots[0].id;
          state.editTaskId = (state.data.tasks[0] && state.data.tasks[0].id) || null;
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
  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function statusBadge(s) {
    const cls = s === "在线" ? "ok" : s === "忙碌" ? "busy" : "";
    return `<span class="badge ${cls}">${esc(s)}</span>`;
  }

  function setTab(tab) {
    state.tab = tab;
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

  function renderOverview() {
    const bots = state.data.bots;
    const tasks = state.data.tasks;
    const inProg = tasks.filter((t) => t.status === "进行中").length;
    const delivered = bots.filter((b) => b.lastDelivery && b.lastDelivery !== "暂无").length;
    const order = groupOrder();
    const shortName = (n) => displayNick(n);
    const spaced = (code) => {
      if (!code) return "—";
      if (code.length >= 2 && /[A-Za-z]/.test(code[0])) return code[0] + " " + code.slice(1);
      return code;
    };
    const card = (b) => `<button type="button" class="emp-card" data-bot="${esc(b.id)}">
        <div class="emp-avatar-wrap"><img class="emp-avatar-img" src="${avatarSrc(b)}" alt="" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"/><div class="emp-avatar-fallback" style="display:none">${esc((b.name||'?')[0])}</div></div>
        <div class="emp-code">${esc(spaced(b.code||""))}</div>
        <div class="emp-dots"><span class="dot ${b.status==="在线"?"ok":""}"></span><span class="dot"></span><span class="dot"></span></div>
        <div class="emp-meta"><span class="emp-pill">${esc(b.code||"—")}</span><span class="emp-layer">${esc(b.group||"")}</span></div>
        <div class="emp-name">${esc(displayNick(b.name))}</div>
        <div class="emp-role">${esc(displayTitle(b.name, b.role))}</div>
      </button>`;
    let groupsHtml = "";
    for (const g of order) {
      const items = bots.filter((b) => botInGroup(b, g));
      if (!items.length) continue;
      groupsHtml += `<div class="group-block"><div class="group-head"><h3>${esc(g)}</h3><span class="badge">${items.length}</span></div><div class="emp-grid">${items.map(card).join("")}</div></div>`;
    }
    return `
      <h2 class="section-title">工作台总览</h2>
      <p class="muted">数据来自 workspace.json · 共 ${bots.length} 位员工 · ${order.length} 个分组</p>
      <div class="cards">
        <div class="card"><div class="v">${bots.length}</div><div class="l">数字员工</div></div>
        <div class="card"><div class="v">${inProg}</div><div class="l">进行中</div></div>
        <div class="card"><div class="v">${delivered}</div><div class="l">本周交付</div></div>
        <div class="card"><div class="v">${order.length}</div><div class="l">业务分组</div></div>
      </div>
      ${groupsHtml}`;
  }

function renderRoster() {
    const filter = state.layerFilter; // reused as group filter
    const order = groupOrder();
    const chips = ["全部"].concat(order);
    const botsAll = state.data.bots || [];
    const q = (state.searchText||"").trim().toLowerCase();
    const match = (b) => !q || (b.name+b.role+(b.group||"")).toLowerCase().includes(q);
    const bots = botsAll.filter(match).filter((b) => filter === "全部" || botInGroup(b, filter));
    const shortName = (n) => displayNick(n);
    const spaced = (code) => {
      if (!code) return "—";
      if (code.length >= 2 && /[A-Za-z]/.test(code[0])) return code[0] + " " + code.slice(1);
      return code;
    };
    const card = (b) => `<button type="button" class="emp-card" data-bot="${esc(b.id)}">
        <div class="emp-avatar-wrap"><img class="emp-avatar-img" src="${avatarSrc(b)}" alt="" onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"/><div class="emp-avatar-fallback" style="display:none">${esc((b.name||'?')[0])}</div></div>
        <div class="emp-code">${esc(spaced(b.code||""))}</div>
        <div class="emp-dots"><span class="dot ${b.status==="在线"?"ok":""}"></span><span class="dot"></span><span class="dot"></span></div>
        <div class="emp-meta"><span class="emp-pill">${esc(b.code||"—")}</span><span class="emp-layer">${esc(b.group||b.layer||"")}</span></div>
        <div class="emp-name">${esc(displayNick(b.name))}</div>
        <div class="emp-role">${esc(displayTitle(b.name, b.role))}</div>
      </button>`;
    let body = "";
    if (filter === "全部") {
      for (const g of order) {
        const items = bots.filter((b) => botInGroup(b, g));
        if (!items.length) continue;
        body += `<div class="group-block"><div class="group-head"><h3>${esc(g)}</h3><span class="badge">${items.length}</span></div><div class="emp-grid">${items.map(card).join("")}</div></div>`;
      }
    } else {
      body = `<div class="emp-grid">${bots.map(card).join("")}</div>`;
    }
    const sel = selectedBot();
    return `
      <h2 class="section-title">员工档案</h2>
      <div class="tabs" style="margin-bottom:12px">${chips.map((l) => {
        const count = l==="全部"?botsAll.length:botsAll.filter(b=>botInGroup(b,l)).length;
        return `<button type="button" class="${filter === l ? "active" : ""}" data-layer="${esc(l)}">${esc(l)} ${count}</button>`;
      }).join("")}</div>
      ${body}
      <div class="callout" style="margin-top:16px"><strong>${esc(sel.name)} · ${esc(sel.code||"")} · ${esc(sel.group||"")}</strong>${esc(sel.role)}<br/>工具/模型：${esc(sel.tools)}<br/>职责：${esc(sel.duty)}</div>`;
  }

  function renderProjects() {
    const products = state.data.projects || [];
    const webs = state.data.websiteProjects || [];
    if (!state.projectSubTab) state.projectSubTab = "websites";
    if (!state.webCat) state.webCat = "全部";
    const sync = state.data.smartplanSync || {};
    const cats = ["全部"].concat(Array.from(new Set(webs.map(w => w.category))).sort());
    const filtered = webs.filter(w => state.webCat === "全部" || w.category === state.webCat);
    if (!state.selectedWebId && filtered[0]) state.selectedWebId = filtered[0].id;
    if (!state.selectedProjectId && products[0]) state.selectedProjectId = products[0].id;
    const w = filtered.find(x => x.id === state.selectedWebId) || filtered[0];
    const p = products.find(x => x.id === state.selectedProjectId) || products[0];
    const tabs = `
      <div class="filters" style="margin-bottom:12px">
        <button type="button" class="${state.projectSubTab==="websites"?"active":""}" data-psub="websites">网站项目（${webs.length}）</button>
        <button type="button" class="${state.projectSubTab==="products"?"active":""}" data-psub="products">产品项目（${products.length}）</button>
      </div>
      <p class="muted">SmartPlan 同步：${esc(sync.source||"—")} · ${esc(String(sync.count||0))} 条 · ${esc(sync.direction||"")} · ${esc(sync.lastSyncAt||"")}</p>`;

    if (state.projectSubTab === "products") {
      if (!products.length) return `<h2 class="section-title">项目</h2>${tabs}<p class="muted">暂无产品项目</p>`;
      const owner = (state.data.bots||[]).find(b => b.id === p.ownerBotId);
      const collabs = (p.collabBotIds||[]).map(id => (state.data.bots||[]).find(b => b.id === id)).filter(Boolean);
      return `<h2 class="section-title">项目</h2>${tabs}
        <div class="layout-2">
          <div class="list">${products.map(x => `
            <button type="button" class="${x.id===p.id?"active":""}" data-project="${esc(x.id)}">
              ${esc(x.name)}<br/><span class="muted">${esc(x.category)} · ${esc(x.status)}</span>
            </button>`).join("")}</div>
          <div>
            <h3>${esc(p.name)}</h3>
            <p>${esc(p.summary)}</p>
            <div class="callout"><strong>启动</strong><code>${esc((p.run&&p.run.command)||"")}</code> → ${esc((p.run&&p.run.url)||"")}</div>
            <h4>匹配员工</h4>
            <div class="emp-grid">${[owner,...collabs].filter(Boolean).map(b=>`<div class="emp-card" style="min-height:100px"><div class="emp-name">${esc(displayNick(b.name))}</div><div class="emp-role">${esc(b.role)}</div></div>`).join("")}</div>
          </div>
        </div>`;
    }

    const catBar = `<div class="filters">${cats.map(c => {
      const n = c==="全部"? webs.length : webs.filter(x=>x.category===c).length;
      return `<button type="button" class="${state.webCat===c?"active":""}" data-webcat="${esc(c)}">${esc(c)} ${n}</button>`;
    }).join("")}</div>`;

    if (!w) return `<h2 class="section-title">项目</h2>${tabs}${catBar}<p class="muted">暂无网站项目。请运行 scripts/sync-smartplan.sh</p>`;

    const owner = (state.data.bots||[]).find(b => b.id === (w.ownerBotId||""));
    return `<h2 class="section-title">项目</h2>${tabs}${catBar}
      <div class="layout-2">
        <div class="list">${filtered.map(x => `
          <button type="button" class="${x.id===w.id?"active":""}" data-web="${esc(x.id)}">
            ${esc(x.name)}<br/><span class="muted">${esc(x.clientName||x.clientCompany||"—")} · ${esc(x.category)} · ${esc(String(x.progress||0))}%</span>
          </button>`).join("")}</div>
        <div>
          <h3>${esc(w.name)} <span class="badge">${esc(w.category)}</span> <span class="badge">${esc(w.status)}</span></h3>
          <p>${esc(w.description||"")}</p>
          <div class="props">
            <div class="row"><div class="k">客户</div><div>${esc(w.clientName||"—")} / ${esc(w.clientCompany||"—")}</div></div>
            <div class="row"><div class="k">进度</div><div>${esc(String(w.progress||0))}%</div></div>
            <div class="row"><div class="k">截止</div><div>${esc(w.deadline||w.serviceEndDate||"—")}</div></div>
            <div class="row"><div class="k">负责人</div><div>${esc(owner?owner.name:"未指定")}</div></div>
            <div class="row"><div class="k">URL</div><div>${esc(w.url||"—")}</div></div>
            <div class="row"><div class="k">框架</div><div>${esc(w.framework||"—")}</div></div>
            <div class="row"><div class="k">付款</div><div>${esc(w.paymentStatus||"—")} · 总额 ${esc(String(w.totalAmount||0))}</div></div>
            <div class="row"><div class="k">路径</div><div><code>${esc(w.localPath||"—")}</code></div></div>
          </div>
          <div class="card-actions" style="margin-top:12px">
            <label>改状态 </label>
            <select id="webStatus">
              <option value="in_progress|进行中" ${w.status==="in_progress"?"selected":""}>进行中</option>
              <option value="delivered|已交付" ${w.status==="delivered"?"selected":""}>已交付</option>
              <option value="infrastructure|功能基础建设" ${w.status==="infrastructure"?"selected":""}>功能基础建设</option>
              <option value="inactive|已暂停/挂了" ${w.status==="inactive"?"selected":""}>已暂停/挂了</option>
            </select>
            <button type="button" class="btn primary" id="saveWebStatus">保存状态（本地，同步时写回）</button>
          </div>
          <p class="muted">不同步电话/微信/邮箱/凭证。写回：PUT /api/websites/:id（需 SmartPlan :3300）。</p>
        </div>
      </div>`;
  }

function renderKanban() {
    const tasks = state.data.tasks;
    const edit = selectedTask();
    const names = botNames();
    const cols = COLS.map((c) => {
      const items = tasks.filter((t) => t.status === c).map((t) =>
        `<div class="task ${edit && t.id === edit.id ? "selected" : ""}" data-task="${esc(t.id)}">
          <div class="t">${esc(t.title)}</div>
          <div class="m">执行：${esc(t.executor)} · 验收：${esc(t.reviewer)}</div>
          <div class="m">${esc(t.note)}</div>
        </div>`
      ).join("");
      return `<div class="col"><h3>${c}（${tasks.filter((t)=>t.status===c).length}）</h3>${items || '<p class="muted">空</p>'}</div>`;
    }).join("");
    const optBots = names.map((n) => `<option value="${esc(n)}">${esc(n)}</option>`).join("");
    const optReview = names.concat(["用户"]).map((n) => `<option value="${esc(n)}">${esc(n)}</option>`).join("");
    return `
      <h2 class="section-title">任务看板</h2>
      <p class="muted">点击卡片选中；用 ← / → 在 待办→进行中→验收→完成 间移动。执行人与验收人必须不同。</p>
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
      "群聊协作": renderGroups,
      "定时巡检": renderRoutines,
      "招聘规划": renderHire,
      "规则与文档": renderRules,
      "项目": renderProjects,
    };
    document.getElementById("main").innerHTML = (map[state.tab] || renderOverview)();
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
  }

  function render() {
    document.getElementById("dataSource").textContent = "数据源：" + state.source;
    const tabs = document.getElementById("tabs");
    tabs.innerHTML = TABS.map((t) =>
      `<button type="button" class="${state.tab === t ? "active" : ""}" data-tab="${t}">${t}</button>`
    ).join("");
    tabs.querySelectorAll("[data-tab]").forEach((el) => {
      el.onclick = () => setTab(el.getAttribute("data-tab"));
    });
    renderMain();
  }

  async function boot() {
    await loadData();
    document.getElementById("btnExport").onclick = doExport;
    document.getElementById("btnReset").onclick = resetDefault;
    document.getElementById("fileImport").onchange = (e) => {
      const f = e.target.files && e.target.files[0];
      if (f) doImport(f);
      e.target.value = "";
    };
    render();
  }

  boot();
})();
