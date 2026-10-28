(function () {
  const LS_KEY = "digital-workshop-v2";
  const TABS = ["总览", "员工档案", "任务看板", "群聊协作", "定时巡检", "招聘规划", "规则与文档"];
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
    const rows = bots.map((b) =>
      `<tr><td>${esc(b.name)}</td><td>${esc(b.layer)}</td><td>${statusBadge(b.status)}</td><td>${b.progress}%</td><td>${esc(b.lastDelivery.length > 40 ? b.lastDelivery.slice(0, 40) + "…" : b.lastDelivery)}</td></tr>`
    ).join("");
    return `
      <h2 class="section-title">总览</h2>
      <p class="muted">数据来自真实 Bot 与 2026-10-29「服装客户开发」测试。Token 均为「待接入」。页内改动写入 localStorage，可用导出/导入同步到仓库 data/。</p>
      <div class="cards">
        <div class="card"><div class="v">${bots.length}</div><div class="l">数字员工数</div></div>
        <div class="card"><div class="v">${inProg}</div><div class="l">进行中任务</div></div>
        <div class="card"><div class="v">${delivered}</div><div class="l">本周交付</div></div>
        <div class="card"><div class="v">${(state.data.groups || []).length}</div><div class="l">群聊数</div></div>
      </div>
      <div class="callout"><strong>落地建议</strong>先稳住：幕僚长（已就位）+ 反调官（待招，建议优先）+ 执行岗。发信/发布/购买/删除须人工审批。</div>
      <div class="diagram">
        <div class="node">你</div><span class="arrow">→</span>
        <div class="node">最强大脑<br/><span class="muted">幕僚长</span></div><span class="arrow">→</span>
        <div class="node">Studio<br/><span class="muted">挖掘·Threadway·SEO·Hoppi·邮件</span></div><span class="arrow">→</span>
        <div class="node">群聊协作</div><span class="arrow">→</span>
        <div class="node">汇总汇报</div>
      </div>
      <table><thead><tr><th>岗位</th><th>层级</th><th>状态</th><th>进度</th><th>最近交付</th></tr></thead>
      <tbody>${rows}</tbody></table>`;
  }

  function renderRoster() {
    const filter = state.layerFilter;
    const bots = filter === "全部" ? state.data.bots : state.data.bots.filter((b) => b.layer === filter);
    const sel = selectedBot();
    const layers = ["全部", "幕僚室", "Studio执行层", "生活层"];
    const list = bots.map((b) =>
      `<button type="button" class="${b.id === sel.id ? "active" : ""}" data-bot="${esc(b.id)}">${esc(b.name)}<br/><span class="muted">${esc(b.layer)} · ${esc(b.status)}</span></button>`
    ).join("");
    return `
      <h2 class="section-title">员工档案</h2>
      <div class="tabs" style="margin-bottom:12px">${layers.map((l) =>
        `<button type="button" class="${filter === l ? "active" : ""}" data-layer="${esc(l)}">${esc(l)}</button>`
      ).join("")}</div>
      <div class="layout-2">
        <div class="list">${list}</div>
        <div>
          <div class="props">
            <div class="row"><div class="k">岗位名称</div><div>${esc(sel.name)}</div></div>
            <div class="row"><div class="k">角色</div><div>${esc(sel.role)}</div></div>
            <div class="row"><div class="k">层级</div><div>${esc(sel.layer)}</div></div>
            <div class="row"><div class="k">当前状态</div><div>${statusBadge(sel.status)}</div></div>
            <div class="row"><div class="k">工具与模型</div><div>${esc(sel.tools)}</div></div>
            <div class="row"><div class="k">最近交付</div><div>${esc(sel.lastDelivery)}</div></div>
          </div>
          <div class="field"><label>改状态</label>
            <select id="botStatus">${["在线","忙碌","空闲"].map((s)=>`<option ${s===sel.status?"selected":""}>${s}</option>`).join("")}</select>
          </div>
          <div class="field"><label>本周进度 %</label><input id="botProgress" type="number" min="0" max="100" value="${sel.progress}"/></div>
          <div class="field"><label>OKR</label><input id="botOkr" value="${esc(sel.okr)}"/></div>
          <div class="field"><label>周报</label><textarea id="botWeekly">${esc(sel.weekly)}</textarea></div>
          <div class="card-actions"><button type="button" class="btn primary" id="saveBot">保存档案改动</button></div>
          <div class="callout" style="margin-top:14px"><strong>职责</strong>${esc(sel.duty)}</div>
          <div class="callout"><strong>知识库</strong>${esc(sel.knowledge)}</div>
          <div class="callout"><strong>技能库</strong>${esc(sel.skills)}</div>
          <div class="callout"><strong>记忆</strong>${esc(sel.memory)}</div>
          <div class="callout"><strong>测试用例</strong>${esc(sel.testCases)}</div>
          <div class="callout warn"><strong>Token</strong>${esc(sel.token)}。外部 API Key 按 Bot 单独存放，不要共用。</div>
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
    };
    document.getElementById("main").innerHTML = (map[state.tab] || renderOverview)();
    bindMain();
  }

  function bindMain() {
    document.querySelectorAll("[data-bot]").forEach((el) => {
      el.onclick = () => { state.selectedId = el.getAttribute("data-bot"); saveLocal(); render(); };
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
