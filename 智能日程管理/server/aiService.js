import db from './db.js';
import { websiteService } from './websiteService.js';

/**
 * Intelligent Chinese date and time heuristic extractor
 */
export function parseDateTimeChinese(text, baseDate = new Date()) {
  const result = {
    dueDate: null,
    dueTime: null,
    cleanedText: text
  };

  const now = new Date(baseDate);
  let targetDate = null;

  // 1. Relative Days: 今天, 明天, 后天, 大后天
  if (/大后天/.test(text)) {
    targetDate = new Date(now);
    targetDate.setDate(targetDate.getDate() + 3);
  } else if (/后天/.test(text)) {
    targetDate = new Date(now);
    targetDate.setDate(targetDate.getDate() + 2);
  } else if (/明天|明儿|次日/.test(text)) {
    targetDate = new Date(now);
    targetDate.setDate(targetDate.getDate() + 1);
  } else if (/今天|今日|傍晚|今晚/.test(text)) {
    targetDate = new Date(now);
  }

  // 2. Weekdays: (下周|本周|这周|周|星期)[一二三四五六日天1-7]
  const weekMap = { '一': 1, '1': 1, '二': 2, '2': 2, '三': 3, '3': 3, '四': 4, '4': 4, '五': 5, '5': 5, '六': 6, '6': 6, '日': 0, '天': 0, '7': 0 };
  const weekMatch = text.match(/(下周|本周|这周|下星期|星期|周)([一二三四五六日天1-7])/);
  if (weekMatch) {
    const isNext = weekMatch[1].includes('下');
    const targetDay = weekMap[weekMatch[2]];
    const currentDay = now.getDay();
    let diff = targetDay - currentDay;
    if (diff <= 0) diff += 7;
    if (isNext && !weekMatch[1].includes('这')) diff += 7;
    targetDate = new Date(now);
    targetDate.setDate(targetDate.getDate() + diff);
  }

  // 3. Explicit month & day: X月X日 / X月X号 / X-X / X/X
  const explicitDateMatch = text.match(/(\d{1,2})月(\d{1,2})[日号]|(\d{4})[-/](\d{1,2})[-/](\d{1,2})/);
  if (explicitDateMatch) {
    if (explicitDateMatch[1] && explicitDateMatch[2]) {
      const year = now.getFullYear();
      const month = parseInt(explicitDateMatch[1], 10) - 1;
      const day = parseInt(explicitDateMatch[2], 10);
      targetDate = new Date(year, month, day);
    } else if (explicitDateMatch[3]) {
      targetDate = new Date(
        parseInt(explicitDateMatch[3], 10),
        parseInt(explicitDateMatch[4], 10) - 1,
        parseInt(explicitDateMatch[5], 10)
      );
    }
  }

  if (targetDate) {
    const y = targetDate.getFullYear();
    const m = String(targetDate.getMonth() + 1).padStart(2, '0');
    const d = String(targetDate.getDate()).padStart(2, '0');
    result.dueDate = `${y}-${m}-${d}`;
  }

  // 4. Time extraction
  const timeMatch = text.match(/(早上|早晨|上午|中午|下午|傍晚|晚上)?\s*(\d{1,2})(?:点|:|：)(\d{1,2})?(?:分|半)?/);
  if (timeMatch) {
    const period = timeMatch[1] || '';
    let hour = parseInt(timeMatch[2], 10);
    let minute = 0;

    if (text.includes(`${timeMatch[2]}点半`)) {
      minute = 30;
    } else if (timeMatch[3]) {
      minute = parseInt(timeMatch[3], 10);
    }

    if (period.includes('下午') || period.includes('晚上') || period.includes('傍晚')) {
      if (hour < 12) hour += 12;
    } else if (period.includes('中午')) {
      if (hour < 11) hour += 12;
    }

    result.dueTime = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`;
  }

  return result;
}

/**
 * Intelligent Project Matcher for Reminders/Tasks
 */
export function matchProject(text, projects) {
  if (!projects || projects.length === 0) return null;

  for (const p of projects) {
    if (text.toLowerCase().includes(p.name.toLowerCase())) {
      return p;
    }
  }

  for (const p of projects) {
    const keywords = [p.name];
    if (p.name.includes('外贸')) keywords.push('客户', '订单', '报价', '询盘', '货代', '出口', '海运');
    if (p.name.includes('日程') || p.name.includes('管理')) keywords.push('系统', '功能', '代码', '测试', '开发', '优化', 'AI');
    if (p.name.includes('健康') || p.name.includes('生活')) keywords.push('运动', '健身', '医院', '买药', '跑步', '做饭', '超市', '阅读');

    for (const kw of keywords) {
      if (text.toLowerCase().includes(kw.toLowerCase())) {
        return p;
      }
    }
  }

  return projects.find(p => p.name.includes('日常')) || projects[0];
}

/**
 * Intelligent Matcher for Website Projects
 */
export function matchWebsiteProject(text, websites) {
  if (!websites || websites.length === 0) return null;
  const lower = text.toLowerCase();

  // 1. Direct case-insensitive match
  for (const w of websites) {
    if (lower.includes(w.name.toLowerCase())) return w;
  }

  // 2. Clean alphanumeric / Chinese match
  for (const w of websites) {
    const clean = w.name.replace(/[^\u4e00-\u9fa5a-zA-Z0-9]/g, '').toLowerCase();
    if (clean.length >= 2 && lower.includes(clean)) return w;
  }

  // 3. Known project aliases & brand names
  for (const w of websites) {
    const wName = w.name.toLowerCase();
    if (wName.includes('mgoo') && lower.includes('mgoo')) return w;
    if (wName.includes('木马谣') && (lower.includes('木马谣') || lower.includes('momasong'))) return w;
    if (wName.includes('鞋子') && (lower.includes('鞋') || lower.includes('zovlux'))) return w;
    if (wName.includes('南驰') && (lower.includes('南驰') || lower.includes('oxlion'))) return w;
    if (wName.includes('云昇') && (lower.includes('云昇') || lower.includes('看点'))) return w;
    if (wName.includes('英摩客') && (lower.includes('英摩客') || lower.includes('umccoy'))) return w;
    if (wName.includes('布料') && (lower.includes('布料') || lower.includes('zhanfa'))) return w;
    if (wName.includes('trailnxt') && lower.includes('trailnxt')) return w;
    if (wName.includes('gongly') && lower.includes('gongly')) return w;
    if (wName.includes('jamc') && lower.includes('jamc')) return w;
    if (wName.includes('nordic') && lower.includes('nordic')) return w;
    if (wName.includes('bravo') && lower.includes('bravo')) return w;
    if (w.url && lower.includes(w.url.replace(/^https?:\/\//, '').split('/')[0].toLowerCase())) return w;
  }

  return null;
}

/**
 * Detect task priority from text
 */
export function detectPriority(text) {
  if (/紧急|立刻|重要|抓紧|尽快|最高|高优|P0|加急/.test(text)) {
    return 'high';
  }
  if (/稍微|有空|不急|低优|之后|随便|P2|备忘/.test(text)) {
    return 'low';
  }
  return 'medium';
}

/**
 * Clean task title from raw speech
 */
export function extractTaskTitle(text) {
  let cleaned = text
    .replace(/^(帮我|请|麻烦|提醒我|安排一下|安排|记录|创建一个日程|创建任务|建立任务|建立日程|增加待办|提醒我去|记得去|记得)/g, '')
    .replace(/(明天|今天|后天|大后天|下周[一二三四五六日天]|本周[一二三四五六日天]|上午|下午|中午|晚上|早上|\d{1,2}点(\d{1,2}分|半)?)/g, '')
    .replace(/[，。！？,.!]/g, ' ')
    .trim();

  if (cleaned.length < 2) {
    cleaned = text.trim();
  }
  return cleaned;
}

/**
 * Main AI Engine: Unified LLM and Heuristic handler
 */
export const aiService = {
  /**
   * Process a user message in AI chat
   */
  async processChatMessage(userMessage, context = {}) {
    const settings = this.getSettings();
    const projects = db.prepare(`SELECT * FROM projects WHERE status = 'active'`).all();
    const websites = websiteService.getAllWebsites();

    // Check if user has configured LLM API key
    if (settings.llm_api_key && settings.llm_api_key.trim().length > 0) {
      try {
        return await this.callLLM(userMessage, projects, websites, settings);
      } catch (err) {
        console.warn('[LLM Call Failed, fallback to Heuristic Engine]:', err.message);
      }
    }

    // Heuristic Engine with comprehensive website project and task support
    return this.parseByHeuristics(userMessage, projects, websites);
  },

  /**
   * Process an external reminder from macOS Reminders (Reverse Recognition)
   */
  async classifyExternalReminder(reminderTitle, reminderBody) {
    const projects = db.prepare(`SELECT * FROM projects WHERE status = 'active'`).all();
    const settings = this.getSettings();

    const fullText = `${reminderTitle} ${reminderBody || ''}`;

    if (settings.llm_api_key && settings.llm_api_key.trim().length > 0) {
      try {
        const websites = websiteService.getAllWebsites();
        const prompt = `识别此来自苹果提醒事项的任务，请分析归类到最匹配的项目看板中。\n任务标题: ${reminderTitle}\n任务备注: ${reminderBody || '无'}\n已有项目列表: ${projects.map(p => p.name).join(', ')}`;
        const parsed = await this.callLLM(prompt, projects, websites, settings);
        if (parsed && parsed.task) {
          return {
            projectName: parsed.task.projectName,
            projectId: parsed.task.projectId,
            priority: parsed.task.priority || 'medium',
            title: parsed.task.title || reminderTitle
          };
        }
      } catch (e) {
        console.warn('[LLM Classify Failed]:', e.message);
      }
    }

    // Heuristic matching
    const matched = matchProject(fullText, projects);
    const priority = detectPriority(fullText);

    return {
      projectName: matched ? matched.name : '日常综合待办',
      projectId: matched ? matched.id : null,
      priority,
      title: reminderTitle
    };
  },

  getSettings() {
    const rows = db.prepare(`SELECT key, value FROM settings`).all();
    const map = {};
    for (const r of rows) map[r.key] = r.value;
    return map;
  },

  /**
   * High performance Heuristic Parser covering Website Projects and Tasks
   */
  parseByHeuristics(text, projects, websites = []) {
    if (!websites || websites.length === 0) {
      websites = websiteService.getAllWebsites();
    }

    const trimmed = text.trim();

    // -------------------------------------------------------------
    // INTENT 1: Modify Existing Website Project
    // e.g. "把MGOO的成交金额改成20000，定金10000"
    //      "木马谣泳衣的状态改成进行中"
    //      "给Trailnxt添加服务SEO/GEO"
    // -------------------------------------------------------------
    const matchedWebsite = matchWebsiteProject(trimmed, websites);
    const hasModifyAction = /(改|变|设|修|更|加|增|调|续|结清|完成|交付|暂停)/.test(trimmed);

    if (matchedWebsite && hasModifyAction) {
      const updates = {};
      const changesList = [];

      // A. Total Deal Amount
      const totalMatch = trimmed.match(/(?:成交金额|合同金额|合同总额|总金额|总额|成交价|签约金额|总价|总计)[：:\s=为是到成改换设]*(?:¥|￥)?(\d+(?:\.\d+)?)/);
      if (totalMatch) {
        updates.total_amount = parseFloat(totalMatch[1]);
        changesList.push(`💰 成交金额设为 **¥${updates.total_amount.toLocaleString()}**`);
      }

      // B. Deposit Amount
      const depositMatch = trimmed.match(/(?:定金|预付款|首付)[：:\s=为是到成改换设]*(?:¥|￥)?(\d+(?:\.\d+)?)/);
      if (depositMatch) {
        updates.deposit_amount = parseFloat(depositMatch[1]);
        changesList.push(`💵 定金设为 **¥${updates.deposit_amount.toLocaleString()}**`);
      }

      // C. Paid Amount
      const paidMatch = trimmed.match(/(?:已收|已收款|已到账|已付|回款)[：:\s=为是到成改换设]*(?:¥|￥)?(\d+(?:\.\d+)?)/);
      if (paidMatch) {
        updates.paid_amount = parseFloat(paidMatch[1]);
        changesList.push(`✅ 已收款设为 **¥${updates.paid_amount.toLocaleString()}**`);
      }

      // Quick "结清" shortcut
      if (/全部结清|已全额结清|尾款已结|已结清/.test(trimmed)) {
        const curTotal = updates.total_amount !== undefined ? updates.total_amount : (matchedWebsite.total_amount || 0);
        if (curTotal > 0) {
          updates.paid_amount = curTotal;
          updates.unpaid_amount = 0;
          changesList.push(`🎉 标记为 **全部结清** (已收 ¥${curTotal.toLocaleString()})`);
        }
      }

      // D. Status Update
      if (/进行中|在做|启动|开始/.test(trimmed)) {
        updates.status = 'in_progress';
        changesList.push(`🚀 归档状态切换为 **进行中**`);
      } else if (/已交付|已完工|交付完工|已验收|交付/.test(trimmed)) {
        updates.status = 'delivered';
        changesList.push(`✅ 归档状态切换为 **已交付**`);
      } else if (/已暂停|暂停|挂了|挂起/.test(trimmed)) {
        updates.status = 'inactive';
        changesList.push(`⏸ 归档状态切换为 **已暂停**`);
      } else if (/基础建设|功能建设/.test(trimmed)) {
        updates.status = 'infrastructure';
        changesList.push(`🛠 归档状态切换为 **基础建设**`);
      }

      // E. Live Website URL
      const urlMatch = trimmed.match(/(?:https?:\/\/[^\s，,]+|[a-zA-Z0-9][-a-zA-Z0-9]*\.[a-zA-Z]{2,}(?:\/[^\s，,]*)?)/i);
      if (urlMatch && !urlMatch[0].includes('localhost')) {
        let finalUrl = urlMatch[0];
        if (!finalUrl.startsWith('http')) finalUrl = `https://${finalUrl}`;
        updates.url = finalUrl;
        changesList.push(`🌐 线上网址更新为 [${finalUrl}](${finalUrl})`);
      }

      // F. Services (SEO/GEO, 网站搭建, 科学上网, custom)
      const currentServices = Array.isArray(matchedWebsite.services)
        ? [...matchedWebsite.services]
        : (matchedWebsite.services ? JSON.parse(matchedWebsite.services) : []);

      const servicesToAdd = [];
      if (/SEO|GEO/i.test(trimmed) && !currentServices.includes('SEO/GEO')) {
        servicesToAdd.push('SEO/GEO');
      }
      if (/(网站搭建|搭建官网|做网站|独立站建设)/.test(trimmed) && !currentServices.includes('网站搭建')) {
        servicesToAdd.push('网站搭建');
      }
      if (/(科学上网|外网加速|梯子|网络)/.test(trimmed) && !currentServices.includes('科学上网')) {
        servicesToAdd.push('科学上网');
      }

      // Custom service extraction, e.g. "添加服务：海外服务器部署"
      const srvMatch = trimmed.match(/(?:添加服务|增加服务|订购服务|服务)[：:\s=为是到成]*([^\s,，;；]+)/);
      if (srvMatch && srvMatch[1]) {
        const customSrv = srvMatch[1].trim();
        if (customSrv && !currentServices.includes(customSrv) && !servicesToAdd.includes(customSrv)) {
          servicesToAdd.push(customSrv);
        }
      }

      if (servicesToAdd.length > 0) {
        updates.services = [...currentServices, ...servicesToAdd];
        changesList.push(`⚡️ 订购服务新增 **${servicesToAdd.join('、')}**`);
      }

      // G. Client Profile & Contacts
      const phoneMatch = trimmed.match(/(?:电话|手机|手机号|联系方式)[：:\s=为是到成]*([0-9\-+]{7,15})/);
      if (phoneMatch) {
        updates.client_phone = phoneMatch[1].trim();
        changesList.push(`📞 客户电话更新为 **${updates.client_phone}**`);
      }

      const clientNameMatch = trimmed.match(/(?:客户名|客户姓名|联系人|称呼)[：:\s=为是到成]*([^\s,，;；]+)/);
      if (clientNameMatch) {
        updates.client_name = clientNameMatch[1].trim();
        changesList.push(`👤 客户称呼更新为 **${updates.client_name}**`);
      }

      // H. Service Start & End Dates
      const dateRangeMatch = trimmed.match(/(?:服务时间|服务周期|合同期|服务期)[从:：\s]*(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})[到至~~\s-]+(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})/);
      if (dateRangeMatch) {
        updates.service_start_date = dateRangeMatch[1].replace(/\//g, '-').replace(/\./g, '-');
        updates.service_end_date = dateRangeMatch[2].replace(/\//g, '-').replace(/\./g, '-');
        changesList.push(`📅 服务时间设为 **${updates.service_start_date} 至 ${updates.service_end_date}**`);
      } else {
        const startMatch = trimmed.match(/(?:服务开始时间|开始时间|起效时间|生效日期)[：:\s=为是到成]*(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})/);
        if (startMatch) {
          updates.service_start_date = startMatch[1].replace(/\//g, '-').replace(/\./g, '-');
          changesList.push(`📅 服务开始时间设为 **${updates.service_start_date}**`);
        }
        const endMatch = trimmed.match(/(?:服务结束时间|结束时间|到期时间|截止日期)[：:\s=为是到成]*(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})/);
        if (endMatch) {
          updates.service_end_date = endMatch[1].replace(/\//g, '-').replace(/\./g, '-');
          changesList.push(`📅 服务结束时间设为 **${updates.service_end_date}**`);
        }
      }

      // If at least one attribute was updated:
      if (Object.keys(updates).length > 0) {
        const updatedProject = websiteService.updateWebsite(matchedWebsite.id, updates);
        const reply = `✅ **已智能更新项目【${updatedProject.name}】**：\n` +
          changesList.map(c => `• ${c}`).join('\n') +
          `\n\n📌 档案当前总成交额 **¥${(updatedProject.total_amount || 0).toLocaleString()}**，未收尾款 **¥${(updatedProject.unpaid_amount || 0).toLocaleString()}**。页面已联动刷新！`;

        return {
          intent: 'update_website_project',
          websiteId: matchedWebsite.id,
          project: updatedProject,
          reply
        };
      }
    }

    // -------------------------------------------------------------
    // INTENT 2: Create New Website Project
    // e.g. "新建客户项目：晨光文具，成交金额18000，定金6000"
    //      "创建项目：安踏跨境独立站"
    // -------------------------------------------------------------
    const createProjectMatch = trimmed.match(/(?:新建|新增|创建|增加)(?:客户|网站|项目)?(?:项目|客户|网站)?(?:：|:|\s+)?([^\s,，:：]+)/);
    const hasCreateIntent = /(新建|新增|创建|增加客户项目|新建网站)/.test(trimmed);

    if (hasCreateIntent && createProjectMatch && createProjectMatch[1] && !trimmed.includes('提醒我') && !trimmed.includes('待办')) {
      const projName = createProjectMatch[1].replace(/(项目|客户|网站)$/, '').trim() || createProjectMatch[1].trim();

      if (projName.length >= 2) {
        const newProjData = { name: projName, status: 'in_progress' };

        const totalMatch = trimmed.match(/(?:成交金额|合同金额|合同总额|总金额|总额|金额)[：:\s=为是到成]*(?:¥|￥)?(\d+(?:\.\d+)?)/);
        if (totalMatch) newProjData.total_amount = parseFloat(totalMatch[1]);

        const depositMatch = trimmed.match(/(?:定金|预付款|首付)[：:\s=为是到成]*(?:¥|￥)?(\d+(?:\.\d+)?)/);
        if (depositMatch) newProjData.deposit_amount = parseFloat(depositMatch[1]);

        const newServices = [];
        if (/SEO|GEO/i.test(trimmed)) newServices.push('SEO/GEO');
        if (/网站搭建|建站|独立站/.test(trimmed)) newServices.push('网站搭建');
        if (/科学上网|外网/.test(trimmed)) newServices.push('科学上网');

        const srvMatch = trimmed.match(/(?:服务|订购服务)[：:\s=为是到成]*([^\s,，;；]+)/);
        if (srvMatch && srvMatch[1] && !newServices.includes(srvMatch[1].trim())) {
          newServices.push(srvMatch[1].trim());
        }
        if (newServices.length > 0) newProjData.services = newServices;

        const dateRangeMatch = trimmed.match(/(?:服务时间|服务周期|合同期|服务期)[从:：\s]*(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})[到至~~\s-]+(\d{4}[-/.]\d{1,2}[-/.]\d{1,2})/);
        if (dateRangeMatch) {
          newProjData.service_start_date = dateRangeMatch[1].replace(/\//g, '-').replace(/\./g, '-');
          newProjData.service_end_date = dateRangeMatch[2].replace(/\//g, '-').replace(/\./g, '-');
        }

        const createdProject = websiteService.createWebsite(newProjData);

        const reply = `🎉 **已为您成功新建客户网站项目【${createdProject.name}】**：\n` +
          `• 📁 **归属阶段**：🚀 进行中\n` +
          `• 💰 **成交金额**：¥${(createdProject.total_amount || 0).toLocaleString()}\n` +
          `• 💵 **约定定金**：¥${(createdProject.deposit_amount || 0).toLocaleString()}\n` +
          `• ⚡️ **已订服务**：${createdProject.services?.length > 0 ? createdProject.services.join('、') : '网站搭建 (默认)'}\n` +
          (createdProject.service_start_date ? `• 📅 **服务周期**：${createdProject.service_start_date} 至 ${createdProject.service_end_date || '未定'}\n` : '') +
          `\n✅ 已存入 SQLite 数据库并在列表首行置顶呈现！`;

        return {
          intent: 'create_website_project',
          project: createdProject,
          reply
        };
      }
    }

    // -------------------------------------------------------------
    // INTENT 3: Financial & Project Queries
    // e.g. "有哪些项目未结清？" "目前总成交金额多少？" "统计一下进行中的项目"
    // -------------------------------------------------------------
    if (/未结清|未收|尾款|欠款|催收|回款率|总成交|财务统计|年度目标|有多少项目|项目概况/.test(trimmed)) {
      const unpaidProjects = websites.filter(w => (parseFloat(w.unpaid_amount) || 0) > 0);
      const totalDeal = websites.reduce((sum, w) => sum + (parseFloat(w.total_amount) || 0), 0);
      const totalPaid = websites.reduce((sum, w) => sum + (parseFloat(w.paid_amount) || 0), 0);
      const totalUnpaid = websites.reduce((sum, w) => sum + (parseFloat(w.unpaid_amount) || 0), 0);
      const inProgressCount = websites.filter(w => w.status === 'in_progress').length;
      const deliveredCount = websites.filter(w => w.status === 'delivered').length;

      let reply = `📊 **客户定制项目财务与经营概况速览**：\n\n` +
        `• 💼 **已建档案**：共 **${websites.length}** 个项目（🚀 进行中 **${inProgressCount}** 个 · ✅ 已交付 **${deliveredCount}** 个）\n` +
        `• 💰 **总成交金额**：**¥${totalDeal.toLocaleString()}**\n` +
        `• 💵 **实际已回款**：**¥${totalPaid.toLocaleString()}**\n` +
        `• ⏳ **待收尾款**：**¥${totalUnpaid.toLocaleString()}**（共 **${unpaidProjects.length}** 笔待收）\n\n`;

      if (unpaidProjects.length > 0) {
        reply += `📌 **待回款重点项目清单**：\n` +
          unpaidProjects.slice(0, 8).map(p => `• **${p.name}**：待收 ¥${parseFloat(p.unpaid_amount).toLocaleString()} (合同总额 ¥${(parseFloat(p.total_amount) || 0).toLocaleString()})`).join('\n');
        if (unpaidProjects.length > 8) {
          reply += `\n• *(其余还有 ${unpaidProjects.length - 8} 个项目待收款，可在总表中筛选查看)*`;
        }
      } else {
        reply += `✨ 目前所有项目款项均已全额结清！`;
      }

      return {
        intent: 'query_info',
        reply
      };
    }

    // -------------------------------------------------------------
    // INTENT 4: Create Task / Reminder (Default fallback)
    // -------------------------------------------------------------
    const dateTime = parseDateTimeChinese(trimmed);
    const matchedProject = matchProject(trimmed, projects);
    const priority = detectPriority(trimmed);
    const title = extractTaskTitle(trimmed);

    const task = {
      title,
      description: `由 AI 智能助理根据指令快速解析建立`,
      dueDate: dateTime.dueDate,
      dueTime: dateTime.dueTime,
      projectId: matchedProject ? matchedProject.id : null,
      projectName: matchedProject ? matchedProject.name : '日常待办',
      priority
    };

    const reply = `已为您智能规划并建立待办日程：\n` +
      `📌 **任务**：${task.title}\n` +
      `📁 **归属项目**：${task.projectName}\n` +
      `⏰ **规划时间**：${task.dueDate || '未指定日期'}${task.dueTime ? ' ' + task.dueTime : ''}\n` +
      `⚡️ **优先级**：${task.priority === 'high' ? '🔥 紧急重要' : task.priority === 'low' ? '🌱 低优先' : '🔹 正常'}\n` +
      `\n✅ 已同步至看板，并将自动推送到 Mac 提醒事项！`;

    return {
      intent: 'create_task',
      task,
      reply
    };
  },

  /**
   * Call external OpenAI-compatible API (DeepSeek, GPT-4o, etc.)
   */
  async callLLM(userPrompt, projects, websites, settings) {
    const baseUrl = (settings.llm_base_url || 'https://api.deepseek.com/v1').replace(/\/+$/, '');
    const model = settings.llm_model || 'deepseek-chat';
    const apiKey = settings.llm_api_key;

    const projectNames = projects.map(p => `"${p.name}" (ID: ${p.id})`).join(', ');
    const websiteSummary = (websites || []).slice(0, 30).map(w => `"${w.name}" (ID: ${w.id}, 状态: ${w.status}, 成交: ¥${w.total_amount||0}, 定金: ¥${w.deposit_amount||0}, 尾款: ¥${w.unpaid_amount||0})`).join('\n');
    const todayStr = new Date().toISOString().split('T')[0];

    const systemPrompt = `你是一个智能项目管理与日程助理。今天是 ${todayStr}。
系统现有项目列表如下：
[${projectNames}]

客户定制网站项目如下：
${websiteSummary}

用户可以通过自然语言执行以下四种操作之一：
1. 修改现有项目档案（例如修改成交金额、定金、状态、网址、服务）: intent = "update_website_project"
2. 新建客户网站项目: intent = "create_website_project"
3. 创建待办日程: intent = "create_task"
4. 通用对话或财务统计查询: intent = "general_chat"

请严格输出符合以下 JSON 格式的内容（不要包含 markdown 代码块包裹之外的文字）：
{
  "intent": "update_website_project" | "create_website_project" | "create_task" | "general_chat",
  "websiteId": "匹配的网站ID (修改时必填)",
  "updates": {
    "total_amount": 数字或null,
    "deposit_amount": 数字或null,
    "paid_amount": 数字或null,
    "status": "in_progress" | "delivered" | "inactive" | null,
    "services": ["网站搭建", "SEO/GEO", "科学上网"] 或null,
    "service_start_date": "YYYY-MM-DD" 或 null,
    "service_end_date": "YYYY-MM-DD" 或 null,
    "url": "网址" 或 null
  },
  "projectData": {
    "name": "新项目名",
    "total_amount": 数字,
    "deposit_amount": 数字,
    "status": "in_progress",
    "services": ["网站搭建"],
    "service_start_date": "YYYY-MM-DD",
    "service_end_date": "YYYY-MM-DD"
  },
  "task": {
    "title": "任务简明标题",
    "description": "详细备注说明",
    "dueDate": "YYYY-MM-DD" 或者 null,
    "dueTime": "HH:mm" 或者 null,
    "projectId": "匹配的项目ID或null",
    "priority": "high" | "medium" | "low"
  },
  "reply": "友好的Markdown格式回复，条理清晰地向用户反馈操作结果与数据"
}`;

    const resp = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        temperature: 0.2,
        response_format: { type: 'json_object' }
      })
    });

    if (!resp.ok) {
      const errText = await resp.text();
      throw new Error(`LLM API returned ${resp.status}: ${errText}`);
    }

    const data = await resp.json();
    const content = data.choices[0]?.message?.content;
    const parsed = JSON.parse(content);
    return parsed;
  }
};
