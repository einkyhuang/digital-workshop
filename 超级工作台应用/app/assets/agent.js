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
    "crm_stats": "L0",
    "system_overview": "L0",
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

  function chineseToolName(name) {
    const map = {
      "context.get_snapshot": "读取工作台快照",
      "nav.open_section": "打开模块",
      "nav.switch_workbench": "切换工作台",
      "task.create": "创建任务",
      "task.set_status": "更新任务状态",
      "task.delete": "删除任务",
      "crm_stats": "客户统计",
      "system_overview": "系统总览",
      "crm.search_customers": "搜索客户",
      "crm.send_email": "发送邮件",
      "external.publish": "外发发布",
      "agent.undo_last": "撤销上一步"
    };
    return map[name] || name;
  }
  function toolSummary(name, detail) {
    const label = chineseToolName(name);
    let obj = null;
    try { obj = typeof detail === "string" ? JSON.parse(detail) : detail; } catch (_) {}
    if (name === "crm.search_customers" && obj) {
      const q = obj.query || "";
      const c = obj.count != null ? obj.count : (Array.isArray(obj.results) ? obj.results.length : 0);
      return q ? (label + "「" + q + "」· " + c + " 条") : (label + " · " + c + " 条");
    }
    if (obj && obj.note) return label + " · " + String(obj.note).slice(0, 40);
    const s = String(detail || "").replace(/\s+/g, " ").slice(0, 80);
    return s ? (label + " · " + s) : label;
  }
  function prettyToolJSON(detail) {
    try { return JSON.stringify(JSON.parse(detail), null, 2); } catch (_) { return String(detail || ""); }
  }

  function skillCatalog() {
    const base = [
      { value: "deep-client-analysis", label: "深度客户分析与调研", desc: "客商画像与竞争格局报告" },
      { value: "a11y-debugging", label: "无障碍网页测试", desc: "" },
      { value: "audit", label: "技术质量审计", desc: "" },
      { value: "optimize", label: "性能极限调优", desc: "" },
      { value: "polish", label: "设计微小细节精修", desc: "" }
    ];
    try {
      const prefs = JSON.parse(localStorage.getItem("sw.workbench.prefs") || "null");
      if (prefs && Array.isArray(prefs.importedSkills)) {
        prefs.importedSkills.forEach((s) => {
          if (!base.some((b) => b.value === s.value)) {
            base.push({ value: s.value, label: s.label || s.value, desc: s.desc || "" });
          }
        });
      }
    } catch (_) {}
    return base;
  }

  function enabledProvidersDetailed() {
    try {
      if (window.SWSharedModels && typeof window.SWSharedModels.loadProviders === "function") {
        /* sync path may be promise — fall through to local */
      }
    } catch (_) {}
    try {
      const g = JSON.parse(localStorage.getItem("sw.global.models") || "null");
      if (g && Array.isArray(g.providers)) {
        return g.providers
          .filter((p) => p && (p.status === true || p.status === undefined))
          .map((p) => ({
            id: p.id,
            name: p.name || p.id,
            model: p.model || "",
            models: Array.isArray(p.availableModels) && p.availableModels.length ? p.availableModels : (p.model ? [p.model] : [])
          }));
      }
    } catch (_) {}
    return providersFromLocal().map((p) => ({
      id: p.id, name: p.name || p.id, model: p.model || "", models: p.model ? [p.model] : []
    }));
  }

  function mount(api) {
    if (document.getElementById("swAgentRoot")) return;
    const root = document.createElement("div");
    root.id = "swAgentRoot";
    root.innerHTML = `
      <button type="button" id="swAgentFab" title="全局 Agent">✦</button>
      <div id="swAgentPanel" hidden>
        <div class="sw-agent-head"><strong>全局 Agent</strong><span class="muted">模型 · Skills</span>
          <button type="button" id="swAgentSettings">设置</button>
          <button type="button" id="swAgentClose">×</button></div>
        <div id="swAgentLog" class="sw-agent-log"></div>
        <div class="sw-agent-composer-card">
          <div id="swAgentSkillTags" class="sw-agent-tags" hidden></div>
          <textarea id="swAgentInput" rows="2" placeholder="向 AI 提问"></textarea>
          <div class="sw-agent-toolbar">
            <div class="sw-agent-tools">
              <button type="button" id="swAgentAttach" class="sw-agent-icon-btn" title="添加文件（仅记录文件名）">+</button>
              <div class="sw-agent-chip-wrap">
                <button type="button" id="swAgentModelBtn" class="sw-agent-chip" title="选择模型">⚡ <span id="swAgentModelLabel">选择模型</span> ▾</button>
                <div id="swAgentModelMenu" class="sw-agent-menu" hidden></div>
              </div>
              <div class="sw-agent-chip-wrap">
                <button type="button" id="swAgentSkillBtn" class="sw-agent-chip" title="选择技能">✦ <span id="swAgentSkillLabel">技能</span> ▾</button>
                <div id="swAgentSkillMenu" class="sw-agent-menu" hidden></div>
              </div>
              <div class="sw-agent-chip-wrap">
                <button type="button" id="swAgentMoreBtn" class="sw-agent-chip">☰ 更多</button>
                <div id="swAgentMoreMenu" class="sw-agent-menu" hidden>
                  <button type="button" data-more="clear">清空对话</button>
                  <button type="button" data-more="reload">刷新模型 / Skills</button>
                  <button type="button" data-more="settings">打开全局设置…</button>
                </div>
              </div>
            </div>
            <div class="sw-agent-actions">
              <button type="button" id="swAgentMic" class="sw-agent-icon-btn" disabled title="语音输入暂未启用">🎤</button>
              <button type="button" id="swAgentSend" class="sw-agent-send" disabled title="发送（Enter；Shift+Enter 换行）">↑</button>
            </div>
          </div>
          <input type="file" id="swAgentFile" multiple hidden />
        </div>
      </div>`;
    document.body.appendChild(root);
    const panel = document.getElementById("swAgentPanel");
    const log = document.getElementById("swAgentLog");
    const input = document.getElementById("swAgentInput");
    const sendBtn = document.getElementById("swAgentSend");
    const skillTags = document.getElementById("swAgentSkillTags");

    let selectedProviderId = localStorage.getItem("sw.agent.selectedProviderId") || "";
    let selectedModel = localStorage.getItem("sw.agent.model") || "";
    let selectedSkills = [];
    try { selectedSkills = JSON.parse(localStorage.getItem("sw.agent.selectedSkills") || "[]"); } catch (_) { selectedSkills = []; }
    let attachmentNames = [];

    function line(role, text) {
      const d = document.createElement("div");
      d.className = "sw-agent-msg sw-agent-" + role;
      d.textContent = text;
      log.appendChild(d); log.scrollTop = log.scrollHeight;
    }
    line("assistant", "Web 子集：导航/快照/本地任务。可选择模型与 Skills（Skills 正文在 Web 仅注入元数据摘要）。");

    function persist() {
      localStorage.setItem("sw.agent.selectedProviderId", selectedProviderId || "");
      localStorage.setItem("sw.agent.model", selectedModel || "");
      localStorage.setItem("sw.agent.selectedSkills", JSON.stringify(selectedSkills));
    }

    function updateSendState() {
      sendBtn.disabled = !(input.value || "").trim();
      sendBtn.classList.toggle("ready", !sendBtn.disabled);
    }

    function renderSkillTags() {
      const cat = skillCatalog();
      const map = Object.fromEntries(cat.map((s) => [s.value, s.label]));
      if (!selectedSkills.length) {
        skillTags.hidden = true;
        skillTags.innerHTML = "";
        document.getElementById("swAgentSkillLabel").textContent = "技能";
        return;
      }
      skillTags.hidden = false;
      skillTags.innerHTML = selectedSkills.map((id) =>
        `<span class="sw-agent-tag">✦ ${map[id] || id}<button type="button" data-rm="${id}" aria-label="移除">×</button></span>`
      ).join("");
      document.getElementById("swAgentSkillLabel").textContent = "技能 " + selectedSkills.length;
      skillTags.querySelectorAll("[data-rm]").forEach((b) => {
        b.onclick = () => {
          selectedSkills = selectedSkills.filter((x) => x !== b.getAttribute("data-rm"));
          persist(); renderSkillTags();
        };
      });
    }

    function shortModel(m) {
      if (!m) return "选择模型";
      const s = String(m).split("/").pop();
      return s.length > 18 ? s.slice(0, 16) + "…" : s;
    }

    function refreshModelChip() {
      document.getElementById("swAgentModelLabel").textContent = shortModel(selectedModel);
    }

    function buildModelMenu() {
      const menu = document.getElementById("swAgentModelMenu");
      const groups = enabledProvidersDetailed();
      if (!groups.length) {
        menu.innerHTML = '<div class="sw-agent-menu-empty">无已启用模型</div>';
        return;
      }
      if (!selectedProviderId || !groups.some((g) => g.id === selectedProviderId)) {
        selectedProviderId = groups[0].id;
        selectedModel = groups[0].models[0] || groups[0].model || selectedModel;
      }
      menu.innerHTML = groups.map((g) => {
        const items = (g.models.length ? g.models : (g.model ? [g.model] : [])).map((mid) => {
          const on = selectedProviderId === g.id && selectedModel === mid ? " ✓" : "";
          return `<button type="button" data-pid="${g.id}" data-mid="${mid}">${mid}${on}</button>`;
        }).join("");
        const emptyModels = '<div class="sw-agent-menu-empty">无模型</div>';
        return `<div class="sw-agent-menu-section"><div class="sw-agent-menu-title">${g.name}</div>${items || emptyModels}</div>`;
      }).join("");
      menu.querySelectorAll("[data-pid]").forEach((b) => {
        b.onclick = () => {
          selectedProviderId = b.getAttribute("data-pid");
          selectedModel = b.getAttribute("data-mid");
          persist(); refreshModelChip(); menu.hidden = true;
        };
      });
      refreshModelChip();
    }

    function buildSkillMenu() {
      const menu = document.getElementById("swAgentSkillMenu");
      const cat = skillCatalog();
      menu.innerHTML = cat.map((s) => {
        const on = selectedSkills.includes(s.value) ? " ✓" : "";
        return `<button type="button" data-sid="${s.value}">${s.label}${on}</button>`;
      }).join("") || '<div class="sw-agent-menu-empty">暂无 Skills</div>';
      menu.querySelectorAll("[data-sid]").forEach((b) => {
        b.onclick = () => {
          const id = b.getAttribute("data-sid");
          if (selectedSkills.includes(id)) selectedSkills = selectedSkills.filter((x) => x !== id);
          else selectedSkills.push(id);
          persist(); renderSkillTags(); buildSkillMenu();
        };
      });
    }

    function hideMenus(except) {
      ["swAgentModelMenu", "swAgentSkillMenu", "swAgentMoreMenu"].forEach((id) => {
        if (id !== except) document.getElementById(id).hidden = true;
      });
    }

    function open() { panel.hidden = false; input.focus(); buildModelMenu(); buildSkillMenu(); renderSkillTags(); updateSendState(); }
    function close() { panel.hidden = true; hideMenus(); }
    document.getElementById("swAgentFab").onclick = () => { panel.hidden ? open() : close(); };
    document.getElementById("swAgentClose").onclick = close;
    document.addEventListener("keydown", (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") { e.preventDefault(); panel.hidden ? open() : close(); }
      if (e.key === "Escape" && !panel.hidden) close();
    });
    document.getElementById("swAgentSettings").onclick = () => {
      if (typeof window.SWOpenGlobalSettings === "function") { window.SWOpenGlobalSettings(); return; }
      const cur = providersFromLocal();
      const base = prompt("Provider Base URL", (cur[0] && cur[0].baseURL) || "https://api.deepseek.com");
      if (base == null) return;
      const model = prompt("Model id", (cur[0] && cur[0].model) || selectedModel || "deepseek-chat");
      if (model == null) return;
      const key = prompt("API Key（明文存 localStorage，勿用生产密钥）", "");
      const list = [{ id: "default", baseURL: base, model, hasKey: !!(key && key.trim()) }];
      if (key && key.trim()) localStorage.setItem("sw.agent.apiKey", key.trim());
      saveProviders(list);
      selectedProviderId = "default"; selectedModel = model; persist(); refreshModelChip();
      alert("已保存 Provider（建议用侧栏「设置」编辑全局配置）");
    };

    document.getElementById("swAgentModelBtn").onclick = (e) => {
      e.stopPropagation();
      const m = document.getElementById("swAgentModelMenu");
      const openNow = m.hidden; hideMenus(); buildModelMenu(); m.hidden = !openNow;
    };
    document.getElementById("swAgentSkillBtn").onclick = (e) => {
      e.stopPropagation();
      const m = document.getElementById("swAgentSkillMenu");
      const openNow = m.hidden; hideMenus(); buildSkillMenu(); m.hidden = !openNow;
    };
    document.getElementById("swAgentMoreBtn").onclick = (e) => {
      e.stopPropagation();
      const m = document.getElementById("swAgentMoreMenu");
      const openNow = m.hidden; hideMenus(); m.hidden = !openNow;
    };
    document.getElementById("swAgentMoreMenu").onclick = (e) => {
      const t = e.target.closest("[data-more]");
      if (!t) return;
      const act = t.getAttribute("data-more");
      if (act === "clear") { log.innerHTML = ""; line("assistant", "对话已清空。"); }
      if (act === "reload") { buildModelMenu(); buildSkillMenu(); line("assistant", "已刷新模型 / Skills 列表。"); }
      if (act === "settings") document.getElementById("swAgentSettings").click();
      hideMenus();
    };
    document.addEventListener("click", () => hideMenus());

    document.getElementById("swAgentAttach").onclick = () => document.getElementById("swAgentFile").click();
    document.getElementById("swAgentFile").onchange = (e) => {
      const files = Array.from(e.target.files || []);
      attachmentNames = files.map((f) => f.name);
      if (attachmentNames.length) line("assistant", "已选择附件（仅文件名）：" + attachmentNames.join(", "));
      e.target.value = "";
    };

    async function send() {
      const text = (input.value || "").trim();
      if (!text) return;
      input.value = "";
      updateSendState();
      let display = text;
      if (attachmentNames.length) display += "\\n\\n（附件：" + attachmentNames.join(", ") + "）";
      line("user", display);
      const state = api.getState();
      const actions = [];
      if (/快照|状态/.test(text)) actions.push(["context.get_snapshot", {}]);
      if (/外贸/.test(text)) actions.push(["nav.switch_workbench", { workbenchId: "trade" }]);
      if (/超级|综合/.test(text)) actions.push(["nav.switch_workbench", { workbenchId: "general" }]);
      if (/看板/.test(text)) actions.push(["nav.open_section", { sectionId: "tasks" }]);
      if (/日报/.test(text)) actions.push(["nav.open_section", { sectionId: "dailySummary" }]);
      if (/SEO|seo/.test(text)) actions.push(["nav.open_section", { sectionId: "dailySeo" }]);
      if (/搜客户|找客户/.test(text)) actions.push(["crm.search_customers", { query: text.replace(/搜客户|找客户/g, "").trim() }]);
      const m = text.match(/建任务\\s*(.+)/);
      if (m) actions.push(["task.create", { title: m[1].trim() }]);
      if (!actions.length) actions.push(["context.get_snapshot", {}]);
      if (selectedSkills.length) {
        const cat = skillCatalog();
        const labels = selectedSkills.map((id) => {
          const s = cat.find((x) => x.value === id);
          return s ? (s.label + "：" + (s.desc || id)) : id;
        });
        line("assistant", "【Skills 上下文摘要】\\n" + labels.join("\\n") + (selectedModel ? ("\\n模型：" + selectedModel) : ""));
      } else if (selectedModel) {
        line("assistant", "使用模型：" + selectedModel + (selectedProviderId ? (" @" + selectedProviderId) : ""));
      }
      const toolResults = [];
      for (const [name, params] of actions) {
        const r = await execute(name, params, state, api);
        toolResults.push({ name, r });
      }
      if (toolResults.length === 1) {
        const { name, r } = toolResults[0];
        line("tool", "▸ " + toolSummary(name, r.detail));
      } else if (toolResults.length > 1) {
        line("tool", "▸ 已调用 " + toolResults.length + " 个工具");
        toolResults.forEach(({ name, r }) => {
          line("tool", "  · " + toolSummary(name, r.detail));
        });
      }
      // Always leave a short assistant summary (web has no LLM loop).
      const summaryLines = toolResults.map(({ name, r }) => "• " + toolSummary(name, r.detail));
      line("assistant", summaryLines.join("\n") || "已处理。");
      attachmentNames = [];
    }
    sendBtn.onclick = send;
    input.addEventListener("input", updateSendState);
    input.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        send();
      }
    });
    buildModelMenu();
    renderSkillTags();
    updateSendState();
    if (/agentOpen=1/.test(location.search)) {
      open();
      input.value = "快照";
      updateSendState();
      setTimeout(send, 400);
    }
  }

  window.SWGlobalAgent = { mount, execute, providersFromLocal, saveProviders };
})();
