/* Global Agent P3 — web subset (L0 nav/snapshot + localStorage tasks; no CRM write / no real send) */
(function () {
  const RISK = {
    "context.get_snapshot": "L0",
    "nav.open_section": "L0",
    "nav.switch_workbench": "L0",
    "schedule.open_day": "L0",
    "daily.open_report": "L0",
    "task.create": "L1",
    "task.set_status": "L1",
    "task.delete": "L2",
    "agent.undo_last": "L1",
    "crm.search_customers": "L0",
    "crm.send_email": "L3",
    "external.publish": "L3"
  };

  const MODULE_BY_TAB = {
    overview: "总览", roster: "员工档案", tasks: "任务看板",
    scheduleCenter: "任务与日程中心", dailySummary: "每日总结", dailySeo: "每日 SEO",
    tradeLeads: "客户与线索", crmCustomers: "客户管理", tradePipeline: "开发进度",
    tradeQuotes: "询盘与报价", rooms: "群聊协作", routines: "定时巡检",
    hiring: "招聘规划", rules: "规则与文档", projects: "网站项目"
  };

  function summarize(params) {
    return Object.keys(params || {}).map(k => k + "=" + params[k]).join(", ").slice(0, 120);
  }

  function snapshot(state) {
    const wb = (state.workbenches || []).find(w => w.id === state.activeWorkbenchId) || {};
    const tasks = (typeof scopedTasks === "function" ? scopedTasks() : (state.data && state.data.tasks) || []).slice(0, 12)
      .map(t => ({ id: t.id, title: t.title, status: t.status }));
    return {
      activeWorkbenchId: state.activeWorkbenchId,
      workbenchName: wb.name || "",
      tab: state.tab,
      tasks,
      note: "Web 子集：不能写回 git / 不能真发信；CRM 仅提示用 Mac"
    };
  }

  async function execute(name, params, state, api) {
    const risk = RISK[name] || "L0";
    if (risk === "L2" || risk === "L3") {
      const ok = window.confirm("【" + risk + "】" + name + "\n" + summarize(params) + (risk === "L3" ? "\n（Web 不会真发外网）" : ""));
      if (!ok) return { ok: false, detail: "用户取消", ms: 0 };
    }
    const t0 = performance.now();
    let ok = true, detail = "";
    try {
      switch (name) {
        case "context.get_snapshot":
          detail = JSON.stringify(snapshot(state), null, 2); break;
        case "nav.open_section": {
          const tab = MODULE_BY_TAB[params.sectionId] || params.sectionId;
          if (api.setTab) await api.setTab(tab); else { state.tab = tab; api.render && api.render(); }
          detail = "opened " + tab; break;
        }
        case "nav.switch_workbench":
          if (api.switchWorkbench) api.switchWorkbench(params.workbenchId);
          detail = "workbench=" + params.workbenchId; break;
        case "task.create": {
          const id = "t-agent-" + Date.now();
          state.data.tasks = state.data.tasks || [];
          state.data.tasks.push({ id, title: params.title || "未命名", status: params.status || "待办", note: params.note || "", executor: params.executor || "", reviewer: params.reviewer || "用户" });
          api.saveLocal && api.saveLocal(); api.render && api.render();
          detail = "created " + id; break;
        }
        case "task.set_status": {
          const t = (state.data.tasks || []).find(x => x.id === params.id);
          if (!t) { ok = false; detail = "not found"; break; }
          t.status = params.status; api.saveLocal && api.saveLocal(); api.render && api.render();
          detail = "status " + params.id; break;
        }
        case "task.delete": {
          state.data.tasks = (state.data.tasks || []).filter(x => x.id !== params.id);
          api.saveLocal && api.saveLocal(); api.render && api.render();
          detail = "deleted " + params.id; break;
        }
        case "crm.search_customers":
          ok = false; detail = "Web 无 private CRM：请用 Mac「超级工作台」App"; break;
        case "crm.send_email":
        case "external.publish":
          ok = false; detail = "L3 已拦截（Web 永不外发）"; break;
        default:
          ok = false; detail = "Web 未实现: " + name;
      }
    } catch (e) {
      ok = false; detail = String(e);
    }
    return { ok, detail, ms: Math.round(performance.now() - t0), argsSummary: summarize(params) };
  }

  function providersFromLocal() {
    try {
      const g = JSON.parse(localStorage.getItem("sw.global.models") || "null");
      if (g && Array.isArray(g.providers) && g.providers.length) {
        return g.providers.map((p) => ({
          id: p.id, name: p.name, baseURL: p.baseUrl || p.baseURL, model: p.model, hasKey: !!(p.apiKey && String(p.apiKey).trim())
        }));
      }
    } catch (_) {}
    try { return JSON.parse(localStorage.getItem("sw.agent.providers") || "[]"); } catch (_) { return []; }
  }
  function saveProviders(list) {
    localStorage.setItem("sw.agent.providers", JSON.stringify(list || []));
    if (window.SWSharedModels && Array.isArray(list)) {
      window.SWSharedModels.loadProviders().then((cur) => {
        const byId = Object.fromEntries((cur || []).map((p) => [p.id, p]));
        list.forEach((p) => {
          const id = p.id || "default";
          const prev = byId[id] || { id, name: p.name || id, type: "openai-compatible", status: true, apiKey: "", modelGroup: "custom", availableModels: [] };
          byId[id] = {
            ...prev,
            baseUrl: p.baseURL || p.baseUrl || prev.baseUrl || "",
            model: p.model || prev.model || "deepseek-chat",
            previewUrl: String(p.baseURL || p.baseUrl || prev.baseUrl || "").replace(/\/+$/, "") + "/chat/completions"
          };
        });
        const key = (localStorage.getItem("sw.agent.apiKey") || "").trim();
        if (key) {
          const first = list[0] && list[0].id;
          if (first && byId[first] && !byId[first].apiKey) byId[first].apiKey = key;
        }
        return window.SWSharedModels.saveProviders(Object.values(byId));
      }).catch(() => {});
    }
  }

  function mount(api) {
    if (document.getElementById("swAgentRoot")) return;
    const root = document.createElement("div");
    root.id = "swAgentRoot";
    root.innerHTML = `
      <button type="button" id="swAgentFab" title="全局 Agent">✦</button>
      <div id="swAgentPanel" hidden>
        <div class="sw-agent-head"><strong>全局 Agent</strong><span class="muted">P3 Web 子集</span>
          <button type="button" id="swAgentSettings">设置</button>
          <button type="button" id="swAgentClose">×</button></div>
        <div id="swAgentLog" class="sw-agent-log"></div>
        <div class="sw-agent-composer">
          <input id="swAgentInput" placeholder="例：快照 / 打开看板 / 建任务 …" />
          <button type="button" id="swAgentSend">发送</button>
        </div>
      </div>`;
    document.body.appendChild(root);
    const panel = document.getElementById("swAgentPanel");
    const log = document.getElementById("swAgentLog");
    function line(role, text) {
      const d = document.createElement("div");
      d.className = "sw-agent-msg sw-agent-" + role;
      d.textContent = text;
      log.appendChild(d); log.scrollTop = log.scrollHeight;
    }
    line("assistant", "Web 子集：导航/快照/本地任务。CRM 与真发信请用 Mac。");
    function open() { panel.hidden = false; document.getElementById("swAgentInput").focus(); }
    function close() { panel.hidden = true; }
    document.getElementById("swAgentFab").onclick = () => { panel.hidden ? open() : close(); };
    document.getElementById("swAgentClose").onclick = close;
    document.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); panel.hidden ? open() : close(); }
      if (e.key === "Escape" && !panel.hidden) close();
    });
    document.getElementById("swAgentSettings").onclick = () => {
      if (typeof window.SWOpenGlobalSettings === "function") {
        window.SWOpenGlobalSettings();
        return;
      }
      const cur = providersFromLocal();
      const base = prompt("Provider Base URL", (cur[0] && cur[0].baseURL) || "https://api.deepseek.com");
      if (base == null) return;
      const model = prompt("Model id", (cur[0] && cur[0].model) || "deepseek-chat");
      if (model == null) return;
      const key = prompt("API Key（明文存 localStorage，勿用生产密钥）", "");
      const list = [{ id: "default", baseURL: base, model, hasKey: !!(key && key.trim()) }];
      if (key && key.trim()) localStorage.setItem("sw.agent.apiKey", key.trim());
      saveProviders(list);
      alert("已保存 Provider（建议用侧栏「设置」编辑全局配置）");
    };
    async function send() {
      const input = document.getElementById("swAgentInput");
      const text = (input.value || "").trim();
      if (!text) return;
      input.value = "";
      line("user", text);
      const state = api.getState();
      const actions = [];
      if (/快照|状态/.test(text)) actions.push(["context.get_snapshot", {}]);
      if (/外贸/.test(text)) actions.push(["nav.switch_workbench", { workbenchId: "trade" }]);
      if (/超级|综合/.test(text)) actions.push(["nav.switch_workbench", { workbenchId: "general" }]);
      if (/看板/.test(text)) actions.push(["nav.open_section", { sectionId: "tasks" }]);
      if (/日报/.test(text)) actions.push(["nav.open_section", { sectionId: "dailySummary" }]);
      if (/SEO|seo/.test(text)) actions.push(["nav.open_section", { sectionId: "dailySeo" }]);
      if (/搜客户|找客户/.test(text)) actions.push(["crm.search_customers", { query: text.replace(/搜客户|找客户/g, "").trim() }]);
      const m = text.match(/建任务\s*(.+)/);
      if (m) actions.push(["task.create", { title: m[1].trim() }]);
      if (!actions.length) actions.push(["context.get_snapshot", {}]);
      for (const [name, params] of actions) {
        const r = await execute(name, params, state, api);
        line("tool", name + " · " + (r.ok ? "OK" : "FAIL") + " · " + r.detail.slice(0, 400));
      }
    }
    document.getElementById("swAgentSend").onclick = send;
    document.getElementById("swAgentInput").addEventListener("keydown", (e) => {
      if (e.key === "Enter") send();
    });
    if (/agentOpen=1/.test(location.search)) {
      open();
      document.getElementById("swAgentInput").value = "快照";
      setTimeout(send, 400);
    }
  }

  window.SWGlobalAgent = { mount, execute, providersFromLocal, saveProviders };
})();
