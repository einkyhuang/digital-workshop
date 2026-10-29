<template>
  <div class="space-y-0 font-sans text-zen-ink relative z-10 select-text">

    <!-- ── Header ── -->
    <div class="pb-5 border-b border-white/20 select-none flex justify-between items-start flex-wrap gap-3">
      <div>
        <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2">
          <span class="w-8 h-8 rounded-xl bg-zen-ink text-white flex items-center justify-center font-serif-sc text-sm shadow-md">司</span>
          我方公司档案库 · 智能分析中心
        </h2>
        <p class="text-xs text-zen-gray mt-1">企业全维度档案 · AI 多模块深度分析 · 实时更新至全系统底盘</p>
      </div>
      <!-- Tab switch -->
      <div class="flex items-center gap-1 bg-black/[0.05] p-0.5 rounded-xl border border-black/[0.02] shadow-sm">
        <button v-for="tab in mainTabs" :key="tab.id" @click="activeMain = tab.id"
          class="px-3 py-1.5 rounded-lg text-[10px] font-bold transition-all duration-200 outline-none whitespace-nowrap"
          :class="activeMain === tab.id ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'">
          {{ tab.label }}
        </button>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════
         VIEW A: 档案详情页（多模块智能分析）
    ══════════════════════════════════════════════ -->
    <div v-if="activeMain === 'detail'" class="pt-6 space-y-6 animate-fadeIn">

      <!-- Brand Hero Card -->
      <div class="bg-gradient-to-br from-neutral-900 via-neutral-800 to-neutral-900 text-white rounded-[28px] p-7 border border-white/10 shadow-xl relative overflow-hidden">
        <div class="absolute -right-20 -top-20 w-64 h-64 rounded-full bg-white/5 blur-3xl pointer-events-none"></div>
        <div class="absolute left-0 bottom-0 w-32 h-32 rounded-full bg-zen-green/10 blur-2xl pointer-events-none"></div>
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-5 relative z-10">
          <div class="flex items-center gap-5">
            <div class="w-16 h-16 rounded-[20px] bg-gradient-to-br from-white/20 to-white/5 backdrop-blur border border-white/20 flex items-center justify-center font-serif-sc text-3xl font-bold shadow-inner text-white select-none shrink-0">
              {{ ourCompanyInfo.chineseName ? ourCompanyInfo.chineseName.substring(0,1) : '禅' }}
            </div>
            <div>
              <div class="flex items-center gap-2 flex-wrap">
                <h3 class="text-xl font-bold font-serif-sc tracking-wide text-white">{{ ourCompanyInfo.chineseName }}</h3>
                <span class="text-[8px] px-2 py-0.5 bg-zen-green/80 text-white rounded-full font-bold font-mono select-none">{{ analysisReport.creditGrade || 'AAA' }}</span>
                <span v-if="analysisReport.isVerified" class="text-[8px] px-2 py-0.5 bg-indigo-500/80 text-white rounded-full font-bold font-mono select-none">AI 已核验</span>
              </div>
              <p class="text-xs text-neutral-300 font-mono mt-1 uppercase tracking-wider">{{ ourCompanyInfo.englishName }}</p>
              <div class="flex flex-wrap gap-x-4 gap-y-1 mt-2 text-[10px] text-neutral-400 font-mono">
                <span>🌐 <a :href="ourCompanyInfo.website" target="_blank" class="text-zen-green hover:underline">{{ ourCompanyInfo.website }}</a></span>
                <span>📍 {{ ourCompanyInfo.address }}</span>
              </div>
            </div>
          </div>
          <div class="flex gap-2 shrink-0 select-none flex-wrap">
            <button @click="activeMain = 'analysis'" :disabled="isRunningAnalysis"
              class="px-4 py-2 bg-zen-green hover:bg-zen-green/90 rounded-xl text-xs font-bold transition-all text-white outline-none flex items-center gap-1.5 shadow-lg">
              <span v-if="isRunningAnalysis" class="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
              <span v-else>🧠</span>
              {{ isRunningAnalysis ? '分析中...' : 'AI 深度分析' }}
            </button>
            <button @click="activeMain = 'edit'" class="px-4 py-2 bg-white/15 hover:bg-white/25 rounded-xl text-xs font-bold transition-all text-white outline-none border border-white/10">
              ✏️ 编辑档案
            </button>
          </div>
        </div>
        <!-- Quick KPI strip -->
        <div class="mt-5 pt-5 border-t border-white/10 grid grid-cols-2 sm:grid-cols-4 gap-4 select-none">
          <div v-for="kpi in companyKPIs" :key="kpi.label" class="text-center">
            <div class="text-lg font-bold font-mono" :class="kpi.color">{{ kpi.value }}</div>
            <div class="text-[9px] text-neutral-400 mt-0.5 uppercase tracking-wider">{{ kpi.label }}</div>
          </div>
        </div>
      </div>

      <!-- Analysis Module Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-5">

        <!-- ── Col 1-2: Modules ── -->
        <div class="lg:col-span-2 space-y-5">

          <!-- Module 1: Certifications -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 space-y-3">
            <h4 class="text-[10px] font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none uppercase tracking-wider">
              <span class="w-1.5 h-3 bg-indigo-500 rounded-full"></span>
              国际准入认证墙 (Qualifications & Certifications)
            </h4>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div v-for="cert in certifications" :key="cert.code"
                class="bg-white/50 border border-white rounded-2xl p-4 flex items-start gap-3 shadow-sm hover:shadow-md transition-all cursor-default">
                <span class="text-2xl select-none">{{ cert.flag }}</span>
                <div>
                  <span class="block text-xs font-bold text-zen-ink">{{ cert.name }}</span>
                  <span class="block text-[9px] text-zen-gray mt-0.5 leading-normal">{{ cert.desc }}</span>
                  <span class="inline-block text-[8px] font-bold px-1.5 py-0.5 rounded mt-1.5 font-mono select-none border"
                    :class="cert.badgeClass">{{ cert.status }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Module 2: Product Matrix -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 space-y-3">
            <h4 class="text-[10px] font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none uppercase tracking-wider">
              <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
              主营产品矩阵与核心工艺壁垒 (Product Matrix)
            </h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div v-for="prod in productMatrix" :key="prod.name"
                class="bg-white/40 border border-white/60 rounded-2xl p-4 space-y-1.5 hover:bg-white/60 transition-all cursor-default">
                <div class="flex items-center justify-between">
                  <span class="text-xs font-bold text-zen-ink">{{ prod.icon }} {{ prod.name }}</span>
                  <span class="text-[8px] font-bold px-2 py-0.5 rounded-full font-mono select-none"
                    :class="prod.tier === '旗舰' ? 'bg-zen-gold/20 text-zen-gold border border-zen-gold/30' : 'bg-slate-100 text-slate-600 border border-slate-200'">
                    {{ prod.tier }}
                  </span>
                </div>
                <p class="text-[9px] text-zen-gray leading-normal">{{ prod.desc }}</p>
                <div class="flex items-center gap-1 flex-wrap mt-1">
                  <span v-for="tag in prod.tags" :key="tag"
                    class="text-[7px] px-1.5 py-0.5 bg-black/[0.04] border border-black/[0.06] rounded font-mono text-zen-gray select-none">{{ tag }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Module 3: Export Track Record -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 space-y-3">
            <h4 class="text-[10px] font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none uppercase tracking-wider">
              <span class="w-1.5 h-3 bg-zen-gold rounded-full"></span>
              国际贸易履约实力与出口履历 (Export Track Record)
            </h4>
            <p class="text-[11px] font-serif-sc text-zen-ink leading-relaxed bg-white/40 border border-white/60 rounded-2xl p-4">{{ ourCompanyInfo.exportExperience }}</p>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div v-for="stat in exportStats" :key="stat.label"
                class="bg-black/[0.02] border border-white/40 rounded-xl p-3 text-center cursor-default">
                <div class="text-base font-bold font-mono" :class="stat.color">{{ stat.value }}</div>
                <div class="text-[9px] text-zen-gray mt-0.5 leading-tight">{{ stat.label }}</div>
              </div>
            </div>
          </div>

          <!-- Module 4: Competitive Positioning -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 space-y-3">
            <h4 class="text-[10px] font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none uppercase tracking-wider">
              <span class="w-1.5 h-3 bg-rose-400 rounded-full"></span>
              市场竞争定位与差异化优势 (Competitive Positioning)
            </h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div v-for="adv in competitiveAdvantages" :key="adv.title"
                class="bg-white/40 border border-white/60 p-4 rounded-2xl space-y-1.5 hover:bg-white/60 transition-all">
                <span class="block text-xs font-bold text-zen-ink">{{ adv.icon }} {{ adv.title }}</span>
                <p class="text-[9px] text-zen-gray leading-normal">{{ adv.desc }}</p>
              </div>
            </div>
          </div>

          <!-- Module 5: Global Agent Network -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 space-y-3">
            <h4 class="text-[10px] font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none uppercase tracking-wider">
              <span class="w-1.5 h-3 bg-teal-500 rounded-full"></span>
              全球代理配送仓储网络 (Global Agent Network)
            </h4>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div v-for="node in agentNetwork" :key="node.region"
                class="bg-white/40 border border-white/60 rounded-2xl p-4 hover:bg-white/60 transition-all cursor-default">
                <div class="flex items-center gap-2 mb-2">
                  <span class="text-lg">{{ node.flag }}</span>
                  <div>
                    <span class="block text-[10px] font-bold text-zen-ink">{{ node.region }}</span>
                    <span class="block text-[8px] text-zen-gray font-mono">{{ node.port }}</span>
                  </div>
                </div>
                <div class="space-y-1">
                  <div class="flex justify-between text-[9px]">
                    <span class="text-zen-gray">交货术语</span>
                    <span class="font-mono font-bold text-indigo-600">{{ node.incoterm }}</span>
                  </div>
                  <div class="flex justify-between text-[9px]">
                    <span class="text-zen-gray">状态</span>
                    <span class="font-bold text-zen-green">{{ node.status }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Module 6: Financial Risk Profile -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 space-y-3">
            <h4 class="text-[10px] font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none uppercase tracking-wider">
              <span class="w-1.5 h-3 bg-emerald-500 rounded-full"></span>
              财务安全与风控档案 (Financial Risk Profile)
            </h4>
            <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
              <div v-for="risk in financialRisks" :key="risk.label"
                class="bg-white/40 border border-white/60 rounded-xl p-3 space-y-1 cursor-default">
                <div class="text-[9px] text-zen-gray uppercase tracking-wider font-bold">{{ risk.label }}</div>
                <div class="text-xs font-bold font-mono" :class="risk.color">{{ risk.value }}</div>
                <div class="text-[8px] text-zen-gray leading-tight">{{ risk.note }}</div>
              </div>
            </div>
          </div>

        </div>

        <!-- ── Col 3: Credit Score + AI Status ── -->
        <div class="space-y-5">

          <!-- Credit Score Card -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 flex flex-col items-center text-center space-y-3">
            <span class="text-[9px] uppercase tracking-wider text-zen-gray font-bold font-serif-sc select-none">商业信用等级</span>
            <div class="relative w-24 h-24 select-none">
              <svg class="w-24 h-24 -rotate-90" viewBox="0 0 36 36">
                <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none" stroke="#e5e7eb" stroke-width="3"/>
                <path d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  fill="none" stroke="#22c55e" stroke-width="3" stroke-dasharray="92, 100" stroke-linecap="round"/>
              </svg>
              <div class="absolute inset-0 flex flex-col items-center justify-center">
                <span class="text-xl font-bold font-mono text-zen-ink">92</span>
                <span class="text-[8px] text-zen-gray font-mono">/ 100</span>
              </div>
            </div>
            <div class="space-y-1 w-full text-left">
              <div v-for="item in creditItems" :key="item.label" class="flex justify-between text-[10px]">
                <span class="text-zen-gray">{{ item.label }}</span>
                <span class="font-bold" :class="item.color">{{ item.value }}</span>
              </div>
            </div>
          </div>

          <!-- AI Analysis Status -->
          <div class="apple-glass rounded-[24px] p-5 border border-white/50 space-y-3">
            <span class="text-[9px] uppercase tracking-wider text-zen-gray font-bold select-none flex items-center gap-1.5">
              <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
              AI 分析模块状态
            </span>
            <div class="space-y-2">
              <div v-for="mod in aiModuleStatus" :key="mod.name"
                class="flex items-center justify-between text-[10px]">
                <span class="text-zen-gray">{{ mod.name }}</span>
                <span class="font-bold font-mono" :class="mod.ready ? 'text-zen-green' : 'text-slate-400'">
                  {{ mod.ready ? '✓ 就绪' : '待更新' }}
                </span>
              </div>
            </div>
          </div>

          <!-- Quick action -->
          <div class="space-y-2 select-none">
            <button @click="runDeepAnalysis"
              class="w-full py-2.5 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-xs font-bold shadow-md transition-all outline-none flex items-center justify-center gap-2">
              🧠 一键生成全维度分析报告
            </button>
            <button @click="activeMain = 'edit'"
              class="w-full py-2 rounded-xl bg-white/60 hover:bg-white border border-white/60 text-zen-ink text-xs font-bold transition-all outline-none">
              ✏️ 编辑公司档案
            </button>
            <button @click="activeMain = 'analysis'"
              class="w-full py-2 rounded-xl bg-white/60 hover:bg-white border border-white/60 text-zen-ink text-xs font-bold transition-all outline-none">
              📊 查看 AI 分析报告
            </button>
          </div>

          <!-- RAG sync status -->
          <div class="p-4 bg-white/40 border border-white/50 rounded-2xl text-[10px] text-zen-gray leading-relaxed select-none">
            <p class="font-bold text-zen-ink flex items-center gap-1.5">
              <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
              AI RAG 数据链路同步
            </p>
            <p class="mt-1.5">公司档案已建立向量 ChromaDB 镜像，AI 营销、报价单审计、形式发票生成将自动调取此底盘数据。</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════
         VIEW B: AI 深度分析报告
    ══════════════════════════════════════════════ -->
    <div v-else-if="activeMain === 'analysis'" class="pt-6 space-y-5 animate-fadeIn">
      <!-- Generate trigger -->
      <div v-if="!analysisReport.generated" class="apple-glass rounded-[24px] p-10 border border-white/50 text-center space-y-5">
        <div class="w-16 h-16 rounded-[20px] bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-3xl mx-auto shadow-xl">🧠</div>
        <h3 class="text-base font-bold font-serif-sc text-zen-ink">AI 全维度公司深度分析</h3>
        <p class="text-xs text-zen-gray max-w-lg mx-auto leading-relaxed">
          基于公司档案数据，AI 将生成包含品牌定位、竞争格局、财务风控、全球市场机会、产品策略、出口路线、营销话术等 8 个专业模块的深度分析报告。
        </p>
        <button @click="runDeepAnalysis" :disabled="isRunningAnalysis"
          class="px-8 py-3 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-xs font-bold shadow-xl transition-all outline-none flex items-center gap-2 mx-auto">
          <span v-if="isRunningAnalysis" class="w-3 h-3 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          <span>{{ isRunningAnalysis ? '生成中...' : '🧠 立即生成分析报告' }}</span>
        </button>
        <div v-if="isRunningAnalysis" class="space-y-2 max-w-sm mx-auto">
          <div v-for="(step, i) in analysisSteps" :key="i" class="flex items-center gap-2 text-xs text-zen-gray">
            <span v-if="analysisProgress > i" class="text-zen-green text-xs">✓</span>
            <span v-else-if="analysisProgress === i" class="w-3 h-3 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin shrink-0"></span>
            <span v-else class="w-3 h-3 border border-slate-300 rounded-full shrink-0"></span>
            <span :class="analysisProgress >= i ? 'text-zen-ink font-medium' : ''">{{ step }}</span>
          </div>
        </div>
      </div>

      <!-- Report content -->
      <div v-else class="space-y-5">
        <!-- Report header -->
        <div class="bg-gradient-to-br from-neutral-900 to-neutral-800 text-white rounded-[24px] p-6 border border-white/10 shadow-xl relative overflow-hidden">
          <div class="absolute -right-10 -top-10 w-40 h-40 rounded-full bg-white/5 blur-2xl pointer-events-none"></div>
          <div class="flex justify-between items-start relative z-10">
            <div>
              <div class="text-[9px] text-neutral-400 uppercase tracking-widest font-mono mb-2">AI DEEP ANALYSIS REPORT · SPI GRADE</div>
              <h3 class="text-lg font-bold font-serif-sc">{{ ourCompanyInfo.chineseName }}</h3>
              <p class="text-xs text-neutral-300 font-mono mt-0.5">{{ ourCompanyInfo.englishName }}</p>
              <p class="text-[9px] text-neutral-500 font-mono mt-2">生成时间：{{ analysisReport.date }} · 模型：{{ analysisReport.model }}</p>
            </div>
            <div class="text-right shrink-0">
              <div class="text-3xl font-bold font-mono text-zen-green">{{ analysisReport.overallScore }}</div>
              <div class="text-[9px] text-neutral-400 font-mono">综合实力评分</div>
              <button @click="runDeepAnalysis" class="mt-3 px-3 py-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-[9px] font-bold text-white border border-white/10 transition-all outline-none">
                🔄 重新生成
</button>
            </div>
          </div>
        </div>

        <!-- Sandbox Mode Warning -->
        <div v-if="analysisReport.model && (analysisReport.model.includes('Sandbox') || analysisReport.model.includes('沙盒'))" 
          class="p-4 bg-yellow-500/10 border border-yellow-500/20 text-yellow-700 dark:text-yellow-400 rounded-2xl text-[10px] leading-relaxed flex items-center justify-between select-none">
          <div class="flex items-center gap-2">
            <span>⚠️</span>
            <span>由于系统尚未启用真实的 AI API 密钥（或开启了极密断网模式），当前已自动激活 <b>MagicHub 物理沙盒</b> 为您预先提炼并生成了高保真、高度定制的商业画像报告。</span>
          </div>
          <button @click="goToSettings" class="px-2.5 py-1 bg-yellow-500/20 hover:bg-yellow-500/30 rounded-lg text-[9px] font-bold transition-all whitespace-nowrap">
            去配置密钥 ⚙️
          </button>
        </div>

        <!-- 8 Analysis Modules -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-5">
          <div v-for="mod in analysisReport.modules" :key="mod.title"
            class="apple-glass rounded-[20px] p-5 border border-white/50 space-y-3">
            <div class="flex items-center justify-between select-none">
              <h4 class="text-xs font-bold font-serif-sc text-zen-ink flex items-center gap-2">
                <span class="text-base">{{ mod.icon }}</span>
                {{ mod.title }}
              </h4>
              <span class="text-[9px] font-bold font-mono px-2 py-0.5 rounded-full border"
                :class="mod.score >= 85 ? 'text-zen-green bg-zen-green/10 border-zen-green/30' : mod.score >= 70 ? 'text-indigo-600 bg-indigo-50 border-indigo-100' : 'text-zen-gold bg-zen-gold/10 border-zen-gold/30'">
                {{ mod.score }} 分
              </span>
            </div>
            <p class="text-[10px] text-zen-gray leading-relaxed">{{ mod.summary }}</p>
            <div class="space-y-1.5">
              <div v-for="point in mod.points" :key="point"
                class="flex items-start gap-1.5 text-[10px] text-zen-ink">
                <span class="text-zen-green font-bold mt-0.5 shrink-0">▸</span>
                <span>{{ point }}</span>
              </div>
            </div>
            <div v-if="mod.action" class="mt-2 pt-2 border-t border-white/20">
              <p class="text-[9px] text-indigo-600 font-bold">💡 建议：{{ mod.action }}</p>
            </div>
          </div>
        </div>

        <!-- Strategic conclusion -->
        <div class="apple-glass rounded-[24px] p-6 border border-white/50 space-y-3">
          <h4 class="text-xs font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
            <span class="text-base">🎯</span>战略结论与下一步行动建议
          </h4>
          <p class="text-[10px] text-zen-gray leading-relaxed">{{ analysisReport.conclusion }}</p>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-3 mt-2">
            <div v-for="action in analysisReport.nextActions" :key="action.label"
              class="bg-white/50 border border-white rounded-xl p-3 space-y-1">
              <span class="text-[9px] font-bold text-zen-ink">{{ action.icon }} {{ action.label }}</span>
              <p class="text-[9px] text-zen-gray leading-normal">{{ action.desc }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════════════════════════════════════════════
         VIEW C: 编辑 / AI 导入
    ══════════════════════════════════════════════ -->
    <div v-else class="pt-6 grid grid-cols-1 lg:grid-cols-3 gap-5 animate-fadeIn">
      <!-- Edit form -->
      <div class="lg:col-span-2 apple-glass rounded-[28px] p-6 border border-white/50 space-y-4">
        <h3 class="text-xs font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
          <span class="w-1.5 h-3 bg-zen-green rounded-full"></span>编辑公司核心档案
        </h3>
        <div class="space-y-4 text-xs font-sans">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-1.5">
              <label class="block font-bold text-zen-ink select-none">公司中文名称 *</label>
              <input type="text" v-model="editForm.chineseName" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="例如：禅能特种制造有限公司"/>
            </div>
            <div class="space-y-1.5">
              <label class="block font-bold text-zen-ink select-none">英文名称 (English Name) *</label>
              <input type="text" v-model="editForm.englishName" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="Zen Specialty Manufacturing Co., Ltd."/>
            </div>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-1.5">
              <label class="block font-bold text-zen-ink select-none">官网地址 URL</label>
              <input type="text" v-model="editForm.website" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all font-mono" placeholder="https://www.example.com"/>
            </div>
            <div class="space-y-1.5">
              <label class="block font-bold text-zen-ink select-none">预设贸易术语 (Incoterms)</label>
              <input type="text" v-model="editForm.presetIncoterms" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="CIF Hamburg, FOB Shanghai, DDP Bangkok"/>
            </div>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-1.5">
              <label class="block font-bold text-zen-ink select-none">成立年份</label>
              <input type="text" v-model="editForm.foundedYear" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="例如：2010"/>
            </div>
            <div class="space-y-1.5">
              <label class="block font-bold text-zen-ink select-none">员工规模</label>
              <input type="text" v-model="editForm.employeeCount" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="例如：200-500人"/>
            </div>
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink select-none">主营产品与核心工艺优势 *</label>
            <textarea v-model="editForm.coreAdvantages" rows="3" class="w-full bg-white/40 border border-white/50 rounded-xl p-3 outline-none focus:bg-white focus:border-zen-green transition-all leading-normal" placeholder="请输入企业拳头产品和工艺优势..."></textarea>
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink select-none">国际认证资质 (Certifications)</label>
            <textarea v-model="editForm.certifications" rows="2" class="w-full bg-white/40 border border-white/50 rounded-xl p-3 outline-none focus:bg-white focus:border-zen-green transition-all leading-normal" placeholder="例如：欧盟 CE、德国 TUV、美国 FDA..."></textarea>
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink select-none">出口贸易履约实力 (Export Strength)</label>
            <textarea v-model="editForm.exportExperience" rows="2" class="w-full bg-white/40 border border-white/50 rounded-xl p-3 outline-none focus:bg-white focus:border-zen-green transition-all leading-normal" placeholder="例如：12年出口经验，支持欧洲、中东多地代理网络..."></textarea>
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink select-none">公司地址 (Address)</label>
            <input type="text" v-model="editForm.address" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="请输入工商注册工厂地址"/>
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink select-none">年出口额 (Annual Export Value)</label>
            <input type="text" v-model="editForm.annualExport" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="例如：USD 2,000,000"/>
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink select-none">主要出口目标市场 (Target Markets)</label>
            <input type="text" v-model="editForm.targetMarkets" class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green transition-all" placeholder="例如：德国、澳大利亚、泰国、中东"/>
          </div>
        </div>
        <div class="pt-4 border-t border-white/20 select-none flex justify-end gap-3">
          <button @click="activeMain = 'detail'" class="px-4 py-2 rounded-xl border border-white/60 bg-white/40 text-zen-ink text-xs font-bold transition-all outline-none">取消</button>
          <button @click="saveInfo" class="px-4 py-2 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-xs font-bold transition-all outline-none">保存档案</button>
        </div>
      </div>

      <!-- AI Importer Column -->
      <div class="apple-glass rounded-[28px] p-6 border border-white/50 space-y-4 h-fit">
        <h3 class="text-xs font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
          <span class="w-1.5 h-3 bg-indigo-500 rounded-full animate-pulse"></span>
          AI 智能企业画像提炼
        </h3>
        <p class="text-[10px] text-zen-gray leading-relaxed">
          粘贴公司简介、宣传册文案、官网正文或随便几句介绍，AI 将为您提炼出专业画像字段，并一键双向覆盖至公司档案底座。
        </p>
        <div class="space-y-3">
          <textarea v-model="aiRawInput" rows="12" 
            class="w-full bg-white/40 border border-white/50 rounded-xl p-3 text-xs outline-none focus:bg-white focus:border-indigo-500 transition-all leading-normal placeholder:text-slate-400"
            placeholder="在此处粘贴任意格式的公司宣传介绍文本..."></textarea>
          
          <div class="p-3 bg-black/[0.02] border border-black/[0.04] rounded-xl space-y-1.5 select-none">
            <span class="block text-[8px] font-bold text-zen-gray uppercase tracking-widest">提炼核心维度</span>
            <div class="flex flex-wrap gap-1">
              <span v-for="field in aiExtractFields" :key="field"
                class="text-[8px] px-2 py-0.5 bg-white border border-black/[0.05] rounded-full text-slate-600 font-medium">
                {{ field }}
              </span>
            </div>
          </div>

          <button @click="runAiCompanyAnalysis" :disabled="isAnalyzingCompany"
            class="w-full py-2.5 bg-gradient-to-br from-indigo-500 to-purple-600 hover:from-indigo-600 hover:to-purple-700 text-white rounded-xl text-xs font-bold shadow-md transition-all outline-none flex items-center justify-center gap-1.5 select-none disabled:opacity-50">
            <span v-if="isAnalyzingCompany" class="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            <span v-else>🤖</span>
            {{ isAnalyzingCompany ? '智能分析提炼中...' : '开始 AI 智能提炼' }}
          </button>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

const props = defineProps({
  ourCompanyInfo: { type: Object, required: true },
  callAiApi: { type: Function, default: null },
  activeAiModel: { type: String, default: '' },
  isSecretMode: { type: Boolean, default: false }
});

const emit = defineEmits(['update:ourCompanyInfo', 'go-to-tab']);

const goToSettings = () => {
  emit('go-to-tab', 'settings');
};

const mainTabs = [
  { id: 'detail', label: '📄 档案详情' },
  { id: 'analysis', label: '🧠 AI 分析报告' },
  { id: 'edit', label: '✏️ 编辑/AI导入' },
];
const activeMain = ref('detail');

const editForm = ref({ ...props.ourCompanyInfo });

// ── Reactive display data ──
const certifications = ref([]);
const productMatrix = ref([]);
const exportStats = ref([]);
const competitiveAdvantages = ref([]);
const agentNetwork = ref([]);
const financialRisks = ref([]);

const analysisReport = ref({
  generated: false,
  date: '',
  model: '',
  overallScore: 0,
  creditGrade: '',
  isVerified: false,
  modules: [],
  conclusion: '',
  nextActions: []
});

const isRunningAnalysis = ref(false);
const analysisProgress = ref(0);

const analysisSteps = [
  '正在提取核心企业资质与主营特色...',
  '正在评估多重认证与行业壁垒...',
  '正在抓取全球目标市场及供应链痛点...',
  '正在挖掘财务流动性与资信状况...',
  '正在构建八维度出海营销及AI转型战略...',
  '全案深度提炼报告编译完成'
];

const companyKPIs = computed(() => [
  { label: '自身实力评分', value: analysisReport.value.overallScore || '89', color: 'text-indigo-600' },
  { label: '海关等级', value: analysisReport.value.creditGrade || 'AA+', color: 'text-zen-green' },
  { label: '出口目的国', value: exportStats.value[0] ? exportStats.value[0].value : '10+', color: 'text-zen-gold' },
  { label: '复购满意度', value: '98.5%', color: 'text-zen-ink' }
]);

const aiExtractFields = [
  '中文/英文官方名称', '官网主页 URL', '主营方向与技术壁垒', '成立年份与雇员规模', '主要出口市场', '预设常用交付术语'
];

const saveInfo = () => {
  analysisReport.value.generated = false;
  emit('update:ourCompanyInfo', { ...editForm.value });
  activeMain.value = 'detail';
};

const syncDetailsFromCompanyInfo = (info) => {
  if (!info) return;
  const certStr = (info.certifications || '').toLowerCase();
  const advStr = (info.coreAdvantages || '').toLowerCase();
  const nameStr = (info.chineseName || '').toLowerCase() + ' ' + (info.englishName || '').toLowerCase();
  
  const isJfc = advStr.includes('jfc') || advStr.includes('越野') || nameStr.includes('jfc') || nameStr.includes('金丰') || nameStr.includes('改装');

  // 1. Dynamic Certifications Wall
  const newCerts = [];
  if (certStr.includes('ce')) {
    newCerts.push({ flag: '🇪🇺', code: 'CE', name: '欧盟 CE 认证', status: 'PASS · 全产品链', badgeClass: 'text-zen-green bg-zen-green/10 border-zen-green/20', desc: '符合欧盟安全、卫生和环保要求，具备欧洲市场准入权。' });
  }
  if (certStr.includes('tuv') || certStr.includes('莱茵')) {
    newCerts.push({ flag: '🇩🇪', code: 'TUV', name: '德国 TUV 莱茵', status: 'AUDITED · 铂金级', badgeClass: 'text-indigo-600 bg-indigo-50 border-indigo-100', desc: '莱茵品质安全认证，通过工厂硬件与生产一致性审计。' });
  }
  if (certStr.includes('fda')) {
    newCerts.push({ flag: '🇺🇸', code: 'FDA', name: '美国 FDA 注册', status: 'REGISTERED', badgeClass: 'text-rose-600 bg-rose-50 border-rose-100', desc: '美国食品药品监督管理局认证，获得北美市场合规准入。' });
  }
  if (certStr.includes('adr')) {
    newCerts.push({ flag: '🇦🇺', code: 'ADR', name: '澳大利亚 ADR 认证', status: 'VERIFIED · 符合性', badgeClass: 'text-emerald-600 bg-emerald-50 border-emerald-100', desc: '澳大利亚设计法则(ADR)越野防撞竞技碰撞安全性合规验证。' });
  }
  if (certStr.includes('iso')) {
    newCerts.push({ flag: '🌐', code: 'ISO9001', name: 'ISO 9001 质量管理体系', status: 'CERTIFIED', badgeClass: 'text-amber-600 bg-amber-50 border-amber-100', desc: '国际标准化质量管理体系，覆盖研发、生产与交付全链路。' });
  }
  if (certStr.includes('sgs')) {
    newCerts.push({ flag: '🇨🇭', code: 'SGS', name: '瑞士 SGS 深度验厂', status: 'SGS VERIFIED', badgeClass: 'text-teal-600 bg-teal-50 border-teal-100', desc: '瑞士通用公证行独立第三方深度工厂实力与质量管理核验。' });
  }

  // Fallback certs if none parsed
  if (newCerts.length === 0) {
    if (isJfc) {
      newCerts.push({ flag: '🇦🇺', code: 'ADR', name: '澳大利亚 ADR 认证', status: 'VERIFIED · 符合性', badgeClass: 'text-emerald-600 bg-emerald-50 border-emerald-100', desc: '澳大利亚设计法则(ADR)越野防撞竞技碰撞安全性合规验证。' });
      newCerts.push({ flag: '🇪🇺', code: 'CE', name: '欧盟 CE 认证', status: 'PASS · 全产品链', badgeClass: 'text-zen-green bg-zen-green/10 border-zen-green/20', desc: '符合欧盟安全、卫生和环保要求，具备欧洲市场准入权。' });
    } else {
      newCerts.push({ flag: '🇪🇺', code: 'CE', name: '欧盟 CE 认证', status: 'PASS · 全产品链', badgeClass: 'text-zen-green bg-zen-green/10 border-zen-green/20', desc: '符合欧盟安全、卫生 and 环保要求，具备欧洲市场准入权。' });
      newCerts.push({ flag: '🌐', code: 'ISO9001', name: 'ISO 9001 质量管理体系', status: 'CERTIFIED', badgeClass: 'text-amber-600 bg-amber-50 border-amber-100', desc: '国际标准化质量管理体系，覆盖研发、生产与交付全链路。' });
    }
  }
  certifications.value = newCerts;

  // 2. Dynamic Product Matrix
  const newProducts = [];
  if (isJfc) {
    newProducts.push({ icon: '🛡️', name: 'JFC4x4 越野竞技前防撞杠', tier: '旗舰', desc: '高硬度轻量航空铝合金与加厚高锰钢冲压结合，高防撞吸能。', tags: ['ADR认证', '越野改装', 'OEM定制'] });
    newProducts.push({ icon: '🚜', name: '底盘重载防擦高分子金属护甲', tier: '旗舰', desc: '高强度防沙石碰撞护板，专车开模底盘防护装甲。', tags: ['重载防护', '底盘防护', '高韧度'] });
    newProducts.push({ icon: '🐾', name: '竞技型高韧脱困沙板', tier: '标准', desc: '特种工程高抗冲塑料，低温不脆化，沙漠救援脱困必选。', tags: ['特种塑料', '极限脱困', '专利设计'] });
    newProducts.push({ icon: '🌬️', name: '4x4 专车定制涉水器/涉沙喉', tier: '标准', desc: '聚乙烯一体滚塑成型，极限防水涉水呼吸进气。', tags: ['涉水喉', '高密封性', '滚塑工艺'] });
  } else {
    newProducts.push({ icon: '❄️', name: 'EX-XT 极寒防冻水箱系列', tier: '旗舰', desc: '三层防冻专利结构，独家 -40°C 极寒西伯利亚防爆防冻工艺。', tags: ['防冻专利', 'TUV认证', '西伯利亚防爆'] });
    newProducts.push({ icon: '💧', name: 'FL-WT 食品级折叠水囊', tier: '旗舰', desc: '食品级 FDA TPU 材质，便携折叠户外储水与重力自流出水。', tags: ['FDA认证', 'TPU食品级', '轻量便携'] });
    newProducts.push({ icon: '🛡️', name: '特种重工业抗酸碱储液囊', tier: '联名款', desc: '高抗张防化复合织物，严苛工业危废及危化品暂存。', tags: ['重工业', '防渗漏', '定制规格'] });
  }
  productMatrix.value = newProducts;

  // 3. Dynamic Export Stats
  const annual = (info.annualExport || '').toUpperCase();
  let exportVal = 'USD 300万+';
  if (annual) {
    exportVal = annual;
  }
  
  const targetMkt = info.targetMarkets || '欧洲、中东、澳大利亚';
  const countries = targetMkt.split(/[、,，\s]+/).filter(Boolean);
  const countStr = countries.length > 0 ? `${countries.length}个` : '10+个';

  exportStats.value = [
    { label: '出口目的国', value: countStr, color: 'text-indigo-600' },
    { label: '年出口规模', value: exportVal, color: 'text-zen-green' },
    { label: '复购率', value: '78%', color: 'text-zen-gold' },
    { label: '主要市场', value: targetMkt.split(/[、,，\s]+/)[0] || '欧美地区', color: 'text-zen-ink' }
  ];

  // 4. Dynamic Competitive Positioning
  const newAdv = [];
  if (isJfc) {
    newAdv.push({ icon: '🌍', title: '澳大利亚 ADR 竞技碰撞合规', desc: '产品符合澳大利亚车辆改装设计法则，免去客户海外清关和上牌安全合规风险。' });
    newAdv.push({ icon: '⚡', title: '物理图纸 100% 高保真打样', desc: '支持客户 3D CAD 图纸 15 天打样交样，极速技术审单与柔性快速交付。' });
  } else {
    newAdv.push({ icon: '❄️', title: '极寒 -40°C 防冻专利工艺', desc: '解决西伯利亚、北欧严寒冻裂痛点，是业内高溢价高安全性的优势代表。' });
    newAdv.push({ icon: '⚡', title: '快速柔性制造响应', desc: '支持 OEM/ODM 快速启动，提供 48 小时极速技术审单和报价反馈，15天交样。' });
  }
  newAdv.push({ icon: '🔒', title: '多国大厂级品质准入壁垒', desc: '持有 CE/TUV/FDA/ISO9001 等资质，是全球高端买家首选的铂金级长期供应商。' });
  competitiveAdvantages.value = newAdv;

  // 5. Dynamic Global Agent Network
  const newAgents = [];
  const flags = { '德国': '🇩🇪', '澳大利亚': '🇦🇺', '澳洲': '🇦🇺', '泰国': '🇹🇭', '美国': '🇺🇸', '南非': '🇿🇦', '中东': '🇦🇪', '阿联酋': '🇦🇪', '欧洲': '🇪🇺', '汉堡': '🇩🇪', '曼谷': '🇹🇭', '墨尔本': '🇦🇺', '迪拜': '🇦🇪', '布里斯班': '🇦🇺', '悉尼': '🇦🇺' };
  
  const presetTerms = info.presetIncoterms || 'CIF Hamburg, FOB Ningbo, DDP Brisbane';
  const terms = presetTerms.split(/[、,;\s]+/).filter(Boolean);
  
  for (const term of terms) {
    if (!term) continue;
    let foundFlag = '🌐';
    let region = '全球货运';
    let port = '协同港口';
    let incoterm = 'FOB';
    
    const parts = term.trim().split(/\s+/);
    if (parts.length > 0) {
      if (['FOB', 'CIF', 'DDP', 'DDU', 'EXW', 'CFR', 'FCA'].includes(parts[0].toUpperCase())) {
        incoterm = parts[0].toUpperCase();
        if (parts.length > 1) {
          port = parts.slice(1).join(' ');
        }
      } else {
        port = parts.join(' ');
      }
    }
    
    for (const [k, f] of Object.entries(flags)) {
      if (port.includes(k) || term.includes(k)) {
        foundFlag = f;
        region = k;
        break;
      }
    }
    if (region === '全球货运') {
      if (port.toLowerCase().includes('hamburg')) { foundFlag = '🇩🇪'; region = '德国'; }
      else if (port.toLowerCase().includes('melbourne') || port.toLowerCase().includes('brisbane') || port.toLowerCase().includes('sydney')) { foundFlag = '🇦🇺'; region = '澳大利亚'; }
      else if (port.toLowerCase().includes('bangkok')) { foundFlag = '🇹🇭'; region = '泰国'; }
      else if (port.toLowerCase().includes('dubai')) { foundFlag = '🇦🇪'; region = '阿联酋'; }
    }
    
    newAgents.push({
      flag: foundFlag,
      region: region,
      port: port,
      incoterm: incoterm,
      status: '协同代理在库'
    });
  }
  
  if (newAgents.length === 0) {
    newAgents.push({ flag: '🇩🇪', region: '德国', port: 'Hamburg Port', incoterm: 'CIF', status: '协同代理在库' });
    newAgents.push({ flag: '🇦🇺', region: '澳大利亚', port: 'Melbourne Port', incoterm: 'DDP', status: '协同代理在库' });
  }
  agentNetwork.value = newAgents;

  // 6. Dynamic Financial Risk Profile
  financialRisks.value = [
    { label: '流动比率 (CR)', value: '2.14', color: 'text-zen-green', note: '短期偿债与变现充沛' },
    { label: '速动比率 (QR)', value: '1.68', color: 'text-indigo-600', note: '速动资产变现高' },
    { label: '信保额度 (SINOSURE)', value: 'USD 50万+', color: 'text-zen-gold', note: '支持高额信保账期' }
  ];
};

watch(() => props.ourCompanyInfo, (v) => {
  editForm.value = { ...v };
  if (!analysisReport.value.generated) {
    syncDetailsFromCompanyInfo(v);
  }
}, { deep: true, immediate: true });

async function runDeepAnalysis() {
  if (isRunningAnalysis.value) return;
  isRunningAnalysis.value = true;
  analysisProgress.value = 0;
  activeMain.value = 'analysis';

  const progressInterval = setInterval(() => { if (analysisProgress.value < 4) analysisProgress.value++; }, 600);

  const advStr = (props.ourCompanyInfo.coreAdvantages || '').toLowerCase();
  const nameStr = (props.ourCompanyInfo.chineseName || '').toLowerCase() + ' ' + (props.ourCompanyInfo.englishName || '').toLowerCase();
  const isJfc = advStr.includes('jfc') || advStr.includes('越野') || nameStr.includes('jfc') || nameStr.includes('金丰') || nameStr.includes('改装');

  try {
    let finalReportText = '';
    if (!props.isSecretMode && props.callAiApi) {
      const systemPrompt = `你是一个顶尖的外贸企业画像多维度分析专家。你的任务是根据我方公司档案数据，进行深度商业评估，并输出一份全维度的企业深度分析报告。
必须输出为合法的 JSON 格式（只返回 JSON 块，大括号必须完全闭合，以 \`\`\`json 开始，以 \`\`\` 结束，不要包含任何其他解释性文本）。

JSON 结构必须严格包含以下字段：
{
  "overallScore": [评分数字，0-100],
  "creditGrade": "[海关信用评级，如 AAA, AA+, AA]",
  "isVerified": true,
  "modules": [
    {
      "icon": "[表情符号]",
      "title": "[模块名称，必须按顺序包含八大模块：国际准入认证墙、主营产品矩阵与核心工艺壁垒、国际贸易履约实力与出口履历、市场竞争定位与差异化优势、全球代理配送仓储网络、财务安全与风控档案、AI数字营销与智能报价、出海合规与法律风控]",
      "score": [模块评分数字],
      "summary": "[模块结论概要]",
      "points": ["[要点分析一]", "[要点分析二]", "[要点分析三]"],
      "action": "[AI 战略建议结论]"
    }
  ],
  "conclusion": "[整体战略结论汇总，字数在100-200字]",
  "nextActions": [
    { "icon": "[图标]", "label": "[行动方向名称]", "desc": "[详细落地建议内容]" }
  ],
  
  "dynamicCertifications": [
    { "flag": "🇪🇺", "code": "CE", "name": "欧盟 CE 认证", "status": "PASS · 全产品链", "badgeClass": "text-zen-green bg-zen-green/10 border-zen-green/20", "desc": "符合欧盟安全合规，具备欧洲市场准入权。" }
  ],
  "dynamicProductMatrix": [
    { "icon": "🛡️", "name": "[产品名称]", "tier": "旗舰", "desc": "[产品与工艺描述]", "tags": ["[标签一]", "[标签二]"] }
  ],
  "dynamicExportStats": [
    { "label": "[统计维度]", "value": "[统计值]", "color": "text-indigo-600" }
  ],
  "dynamicCompetitiveAdvantages": [
    { "icon": "🌍", "title": "[优势名称]", "desc": "[详细解析]" }
  ],
  "dynamicAgentNetwork": [
    { "flag": "🇩🇪", "region": "德国", "port": "Hamburg Port", "incoterm": "CIF", "status": "协同代理在库" }
  ],
  "dynamicFinancialRisks": [
    { "label": "流动比率", "value": "2.14", "color": "text-zen-green", "note": "短期偿债充沛" }
  ]
}`;

      const userPrompt = `需要分析的公司信息如下：
${JSON.stringify(props.ourCompanyInfo, null, 2)}`;

      const fullPrompt = `${systemPrompt}\n\n${userPrompt}`;
      const res = await props.callAiApi(fullPrompt);
      if (res && !res.startsWith('⚠️')) finalReportText = res;
    }

    clearInterval(progressInterval);
    analysisProgress.value = 5;

    let parsedData = null;
    if (finalReportText) {
      try {
        const jsonMatch = finalReportText.match(/\{[\s\S]*\}/);
        if (jsonMatch) parsedData = JSON.parse(jsonMatch[0]);
      } catch (e) {
        console.error('Failed to parse AI deep report JSON:', e, finalReportText);
      }
    }

    if (parsedData) {
      analysisReport.value = { ...parsedData, generated: true, date: new Date().toLocaleDateString('zh-CN'), model: props.activeAiModel || 'MagicHub AI Engine' };
      
      if (parsedData.dynamicCertifications) certifications.value = parsedData.dynamicCertifications;
      if (parsedData.dynamicProductMatrix) productMatrix.value = parsedData.dynamicProductMatrix;
      if (parsedData.dynamicExportStats) exportStats.value = parsedData.dynamicExportStats;
      if (parsedData.dynamicCompetitiveAdvantages) competitiveAdvantages.value = parsedData.dynamicCompetitiveAdvantages;
      if (parsedData.dynamicAgentNetwork) agentNetwork.value = parsedData.dynamicAgentNetwork;
      if (parsedData.dynamicFinancialRisks) financialRisks.value = parsedData.dynamicFinancialRisks;
      
    } else {
      syncDetailsFromCompanyInfo(props.ourCompanyInfo);

      const sandboxModules = isJfc ? [
        {
          icon: '🛡️',
          title: '国际准入认证墙',
          score: 95,
          summary: '我方已获得澳大利亚 ADR 车辆改装安全碰撞符合性验证及欧盟 CE 全产品链认证，在全球核心高壁垒改装市场具备绝对的准入话语权。',
          points: [
            '已获得欧盟 CE 全产品链认证，可无阻碍进入欧洲 27 国及其相关辐射地区。',
            '竞技前杠系列通过澳大利亚 ADR 碰撞安全性与行人保护等法规验证，属顶级合规水平。',
            '持有 ISO9001 质量认证与焊接特种质量证书，海外大客户对生产质量和一致性高度信任。'
          ],
          action: '每年定期执行澳大利亚改装协会 ADR 碰撞指标复审，维持准入绝对护城河。'
        },
        {
          icon: '📦',
          title: '主营产品与工艺壁垒',
          score: 92,
          summary: '主打旗舰级 JFC4x4 竞技前杠、高硬度底盘金属装甲、特种滚塑涉水喉与脱困防沙板，工艺设计水平极佳，研发快反能力强。',
          points: [
            '前竞技杠采用航空级轻量铝合金与加厚高锰钢冲压结合，在保证抗冲强度的同时实现车辆减重。',
            '竞技脱困沙板采用特种工程塑料配方，-35°C 冰极严寒环境不脆化，沙漠救援性能优良。',
            '专车定制涉水器/沙喉采用一次性滚塑工艺，壁厚均匀，防水防沙防震，气密性能业内领先。'
          ],
          action: '将高拉伸吸能特殊锰钢冲压工艺提交国际 PCT 专利池申请，加固排他性门槛。'
        },
        {
          icon: '🌍',
          title: '国际贸易履约实力与出口履历',
          score: 90,
          summary: '15 年特种越野竞技装备全球出口与多国越野极限路况测试经验，年出口额达百万级美金，大客户粘性极佳。',
          points: [
            '品牌产品畅销澳大利亚、美国、西欧、南非等全球 4x4 改装文化核心大国，买家多为高端批发商。',
            '出口订单履约率达到 99.8%，并支持 OEM/ODM CAD 物理图纸 15 天高保真极速打样与交样。',
            '团队对国际特种越野特种体积配件、超重货物的拼箱、国际物流与特种清关协作经验丰富。'
          ],
          action: '申报海关 AEO 高级认证，进一步获取全球越野改装零配件的极速通关和检查减免特权。'
        },
        {
          icon: '⚡',
          title: '市场竞争定位与差异化优势',
          score: 88,
          summary: '坚定立足于中高端竞技级越野改装配件大厂的定位，避开无牌低质竞技杠同质化价格战，利用卓越品质及品牌联名获取高溢价。',
          points: [
            '本厂配件对比常规副厂件在极限抗张撕裂、防锈防酸雨漆膜附着力上均高出 45% 以上。',
            '联名 JFC4x4 国际顶级越野改装商进行全球首发与实车保障测试，极具社群信任资产。',
            '48 小时极速技术审单和工艺核验响应，极大地提高了海外专业改装大客商的开发意愿。'
          ],
          action: '在 YouTube / Instagram 上传实车沙漠拖拽、极限越野碰撞硬核测试视频，拉动 C端需求。'
        },
        {
          icon: '✈️',
          title: '全球代理配送仓储网络',
          score: 86,
          summary: '在澳大利亚墨尔本与布里斯班、德国汉堡等多地配有常备协同港口库与本地代理，提供 FOB/CIF/DDP 灵活交付选项。',
          points: [
            '墨尔本及布里斯班协同代理仓库可满足大批量拼箱的本地 DDP 清关及卡车快速派送。',
            '欧洲汉堡协同仓保持核心改装件常规在库，可支持西欧/北欧越野商 48 小时极速补货。',
            '支持多样化贸易术语，在报价和提单管理中完全闭环，最大限度压缩买家采购综合物流成本。'
          ],
          action: '扩建美国西海岸洛杉矶协同库，利用本地高时效配送抢占北美大脚车与皮卡竞技杠改装红利。'
        },
        {
          icon: '💎',
          title: '财务安全与风控档案',
          score: 92,
          summary: '公司资金流动性极强，短期偿债比率指标健康，持有中信保（SINOSURE）高额支持，资信等级 AAA。',
          points: [
            '流动比率 2.14，速动比率高达 1.68，资金链极强，支持原材料淡季超前备料。',
            '中信保单笔或大客户授信总保额达 USD 50万+，具备支持特大账期、灵活信用证的商务实力。',
            '工商与海关记录零违法、零欠税、零涉诉，商业声誉在国际承兑和信贷体系中处于 AAA 级。'
          ],
          action: '针对资信评估极佳的澳大利亚改装品牌大买家，可适度推行信保覆盖下的 OA 30天账期。'
        },
        {
          icon: '🧠',
          title: 'AI数字营销与智能报价',
          score: 85,
          summary: '已全面接通 MagicHub CRM 系统底座，打通了企业画像向量化与 AI 智能营销引擎的数字化飞轮。',
          points: [
            '本厂核心优势、专利及 ADR 认证数据已完全镜射至 ChromaDB 向量库，AI 具备高度专业问答能力。',
            'CRM 沟通记录和海关数据背调一键联通，实现 floating AI 极速生成极其地道、高转化的越野改装开发信。',
            '支持多语种外贸跟进文案自动包装，使我们对中东（阿拉伯语）、南非等多语种客户的开拓无文化断层。'
          ],
          action: '将 AI 智能报价与 CAD 3D 快速出图模块集成，实现“询盘-AI算料报价-效果图” 48小时出案。'
        },
        {
          icon: '⚖️',
          title: '出海合规与法律风控',
          score: 87,
          summary: '严格遵守多国车辆安全改装要求与环保健康标准，利用金融避险工具锁汇，全力规避跨国法务风险。',
          points: [
            '产品钢材涂层符合 RoHS 环保检测规范，废气与焊接排放达到国内最新绿色大厂环保标准。',
            '常态化采取远期结售汇与多币种对冲操作，抵御 USD/RMB 汇率短期剧烈波动引起的利润缩水。',
            '悉尼与汉堡的合作法律顾问团队对新产品进行外观检索，防止遭遇海外车辆零配件设计侵权指控。'
          ],
          action: '对最新款的越野防撞前杠，在主要出口目标国提前提起外观与结构国际专利审查申请。'
        }
      ] : [
        {
          icon: '🛡️',
          title: '国际准入认证墙',
          score: 94,
          summary: '我方已获得欧盟 CE 全产品链认证、美国 FDA 食品级材质注册与 ISO9001 质量认证体系，具备极为牢固的跨国准入安全资质壁垒。',
          points: [
            '已通过欧盟 CE 安全质量体系认证，无阻碍销往欧盟 27 国及其相关辐射采购商。',
            '折叠水囊等核心产品获美国 FDA 注册，TPU 材质 100% 符合食品级接触标准，安全性高。',
            '通过德国 TUV 莱茵铂金级质量体系审计，精细化制造和生产一致性控制达到世界一流水准。'
          ],
          action: '为工业抗酸碱储液囊系列增设德国 DIN 环保防渗透级别认证，撬动欧洲高端危化招标项目。'
        },
        {
          icon: '📦',
          title: '主营产品与工艺壁垒',
          score: 91,
          summary: '主力生产 EX-XT 极寒防冻专利水箱、食品级折叠水囊、特种酸碱耐腐工业储液囊，拥有多项技术专利工艺储备，硬核防爆防裂。',
          points: [
            '极寒水箱采用三层复合发泡专利结构，能轻松受耐 -40°C 极寒西伯利亚冻融测试。',
            '折叠水囊采用特种 TPU 高气密织物，耐穿刺、易折叠，自带专利野外极速重力出水阀。',
            '防化储液囊拥有极其强悍的极限抗张强度与耐酸碱高分子防腐涂层，保障危废安全暂存。'
          ],
          action: '将 -40°C 极寒三层结构专利申请国际 PCT 专利保护，防止核心技术流失与仿冒。'
        },
        {
          icon: '🌍',
          title: '国际贸易履约实力与出口履历',
          score: 89,
          summary: '拥有 12 年以上特种工业液体容器、极寒耐温装备国际出口贸易履历，年订单量 400+，满意度达到 98.5%。',
          points: [
            '产品常年出口北欧、西伯利亚地区、加拿大、中东水利设施等恶劣气候和工业苛刻环境。',
            '年均复购率高达 78%，外贸大客户合作关系维持在 8 年以上，忠诚度极高。',
            '外贸履约单证与危废运输规范完全合规，能协助海外买家妥善解决复杂的港口准入要求。'
          ],
          action: '针对极寒地区取暖与水利采购的周期性，提前 3 个月在 CRM 系统部署 AI 智能需求预测。'
        },
        {
          icon: '⚡',
          title: '市场竞争定位与差异化优势',
          score: 87,
          summary: '专注于高溢价特种液体存储及极寒防护系统方案提供商，摒弃常规塑料水箱低端价格战，靠专利防冻及食品级高标准溢价。',
          points: [
            '极寒 -40°C 循环不爆裂是行业的稀缺核心技术，可支持 20%-35% 的高溢价空间。',
            '48 小时内快速提供定制储能水箱 CAD 图样及 15 天高保真物理交样服务，效率突出。',
            '不仅卖容器，更提供野外应急饮水、工地泥浆暂存、危废防护等多场景一站式成套定制方案。'
          ],
          action: '在国际特种防护物资展览会展示 -40°C 实测防爆冻融检测报告，直击极寒工业客户痛点。'
        },
        {
          icon: '✈️',
          title: '全球代理配送仓储网络',
          score: 85,
          summary: '在德国汉堡、泰国曼谷等多地设有协同代理仓库与履约配送网点，提供 FOB/CIF/DDP 等常用国际贸易术语一站式选择。',
          points: [
            '汉堡港协同代理仓库提供西欧、北欧冬季应急取暖与水袋备件的 48 小时极速本地派送补货。',
            '曼谷协同点积极参与东南亚水利环保基建项目，支持大批量特种储液袋本地 DDP 配送交付。',
            '报价与清关单据管理完全闭环，能动态估算并推荐最省运费的联运物流模式，让买家采购更无忧。'
          ],
          action: '联络俄罗斯海参崴及圣彼得堡的专业代理，在极寒市场前哨构建更低成本的协同补给网。'
        },
        {
          icon: '💎',
          title: '财务安全与风控档案',
          score: 91,
          summary: '公司资金流动性极强，短期偿债与变现充沛，财务安全处于行业金字塔尖，享有中信保高额授信，信用评级 AAA。',
          points: [
            '速动比率达 1.68，资产变现与抗汇率波动现金储备充足，淡季备料无任何利息负担。',
            '中信保（SINOSURE）最高可提供单笔 USD 50万+ 信用风险担保，全面降低国际承兑汇票坏账风险。',
            'AAA 级海关和税务信用，无任何司法纠纷，在全球信保及银行结算体系中具备极佳的资信实力。'
          ],
          action: '对符合条件的北欧市政水利长期大客户，提供以信保为支撑的 OA 30天/60天灵活账期。'
        },
        {
          icon: '🧠',
          title: 'AI数字营销与智能报价',
          score: 84,
          summary: '企业底座与 MagicHub AI 系统完全接通，打通了极寒防冻专利知识召回与数字化获客闭环。',
          points: [
            '工厂专利工艺与 EX-XT 数据已载入 ChromeDB 向量底座，AI 具备完美的极寒工业容器技术答疑实力。',
            '海关数据与 CRM 沟通脉络全打通，实现 floating AI 一键生成德语、俄语、英语地道开发信。',
            '支持向北欧及中东客户自动撰写特种环保储液、极寒防冻的差异化营销话术和社交媒体文案。'
          ],
          action: '建立三层发泡防冻极限测试的 AI 动态渲染展示视频，用直观的数据动画作为询盘跟进利器。'
        },
        {
          icon: '⚖️',
          title: '出海合规与法律风控',
          score: 86,
          summary: 'TPU 水囊材质完全符合欧盟 REACH 与 RoHS 环保指令，外贸防范远期外汇风险策略健全。',
          points: [
            '折叠储水材质成分通过全球权威检测，100% 环保，绝无重金属与有毒塑料溶出。',
            '长期采取外汇银行远期锁汇（Forward Contracts）规避 USD/RMB 汇率波动带来的财务损益。',
            '悉尼与汉堡的合作法律顾问团队对定制合同的知识产权进行前置检索，防止外观与技术侵权风控。'
          ],
          action: '在新品水囊上，增加清晰的欧盟多语种食品接触及温度警示合规标识，做到风控无盲区。'
        }
      ];

      analysisReport.value = {
        generated: true,
        date: new Date().toLocaleDateString('zh-CN'),
        model: 'MagicHub Local Sandbox',
        overallScore: 89,
        creditGrade: 'AA+',
        modules: sandboxModules,
        conclusion: isJfc ? 
          '综合商业画像极佳。我方在越野改装这一高净值、高溢价细分赛道中，凭借澳大利亚 ADR 碰撞与 CE 认证形成坚实壁垒，支持 OEM CAD 物理图纸 15 天高保真快速出样。出口履历与全球港口配送库十分完备，财务安全性 AAA 级。未来应深化 AI 营销文案的生成和社群测试视频推广，进一步提高海外越野大买家开发转化率。' :
          '企业核心竞争力过硬。在极寒 -40°C 耐温 EX-XT 水箱与食品级 FDA TPU 折叠容器这一高毛利率工业细分领域，我方持有无可替代的三层防冻发泡工艺专利，财务状况 AAA 级且支持长信保账期合作。后续应全力依靠 MagicHub 智能 CRM 系统深化 AI 大客户数字化营销，将防冻工艺壁垒转化为地道、精准的海外询盘订单开发优势。',
        nextActions: isJfc ? [
          { icon: '🚀', label: '深化 ADR 碰撞复审与合规', desc: '定期与澳大利亚车辆改装协会复审竞技前杠碰撞安全性，维护 ADR 国际合规护城护栏。' },
          { icon: '📦', label: '轻量化钛合金前杠研发', desc: '利用本厂高锰钢与航空铝合金工艺优势，研发超高端钛合金前杠，实现 45% 的高溢价空间。' },
          { icon: '🌐', label: '拓展美西协同库', desc: '在洛杉矶或旧金山枢纽增设特种越野配件协同代理仓库，提升北美市场配送时效与大买家体验。' }
        ] : [
          { icon: '🚀', label: '极寒防冻专利 PCT 申请', desc: '针对 -40°C EX-XT 极寒防冻三层水箱结构提交 PCT 国际专利申请，防御抄袭。' },
          { icon: '🛡️', label: '德国 DIN 工业环保认证', desc: '为特种防化储液容器增设 DIN 工业级环保防漏验证，进入欧盟更高端市政水利基建招标采购池。' },
          { icon: '🌐', label: '布局俄罗斯协同网络', desc: '在圣彼得堡及海参崴寻找本地协同仓储代理，在极寒市场前哨站建立 48 小时补货网络，提升溢价。' }
        ]
      };
    }
  } finally {
    isRunningAnalysis.value = false;
    analysisProgress.value = 6;
  }
}

// ── AI Company Importer ───────────────────────────────────────────────────────
const aiRawInput = ref('');
const isAnalyzingCompany = ref(false);

async function runAiCompanyAnalysis() {
  if (!aiRawInput.value.trim()) { alert('请先粘贴公司简介或官网域名！'); return; }
  isAnalyzingCompany.value = true;

  try {
    let extractedText = '';

    if (!props.isSecretMode && props.callAiApi) {
      const systemPrompt = `你是一个顶尖的外贸企业画像提炼专家。你的任务是根据用户粘贴的公司简介、官网正文、或者是宣传彩页内容，提炼并输出该公司档案的关键信息字段。
必须输出为合法的 JSON 格式（只返回 JSON 块，大括号必须完全闭合，不要包含任何其他解释性文本）。
字段如果无法在文本中找到，请结合上下文进行合理推断或保留原有默认值，不要返回空或未定义（对于英文名称、主要优势、认证、贸易术语等，如果原文本没有，可结合公司名称和产品类型进行高度专业地提炼，以确保画像的高价值度）：
{
  "chineseName": "[提炼出的中文名称]",
  "englishName": "[提炼出的英文名称，若无则合理翻译或提炼，例如 XXX Specialty Manufacturing Co., Ltd.]",
  "coreAdvantages": "[主营产品与核心技术/工艺优势，字数在40-100字，需要专业地道，体现技术壁垒]",
  "certifications": "[国际资质认证，如：欧盟 CE, 德国 TUV, 美国 FDA, ISO 9001, SGS 等]",
  "exportExperience": "[出口履约实力，如：12年出口经验，支持全球配送仓储代理网络，复购率高等，字数在30-80字]",
  "website": "[公司官网地址，如无则推测或保持原状]",
  "presetIncoterms": "[常用贸易术语，如：FOB Shanghai, CIF Hamburg, DDP Bangkok]",
  "address": "[详细办公或工厂地址]",
  "foundedYear": "[成立年份数字，如：2012]",
  "employeeCount": "[员工规模，如：100-200人]",
  "annualExport": "[年出口额，如：USD 200万+]",
  "targetMarkets": "[主要出口国家或市场，如：德国、澳大利亚、泰国、中东]"
}`;

      const userPrompt = `原有的公司信息如下：
- 中文名称: ${props.ourCompanyInfo.chineseName || ''}
- 英文名称: ${props.ourCompanyInfo.englishName || ''}
- 优势: ${props.ourCompanyInfo.coreAdvantages || ''}
- 认证: ${props.ourCompanyInfo.certifications || ''}
- 经验: ${props.ourCompanyInfo.exportExperience || ''}
- 官网: ${props.ourCompanyInfo.website || ''}
- 贸易术语: ${props.ourCompanyInfo.presetIncoterms || ''}
- 地址: ${props.ourCompanyInfo.address || ''}
- 成立年份: ${props.ourCompanyInfo.foundedYear || ''}
- 员工数: ${props.ourCompanyInfo.employeeCount || ''}
- 出口额: ${props.ourCompanyInfo.annualExport || ''}
- 市场: ${props.ourCompanyInfo.targetMarkets || ''}

现在，请根据下面用户最新粘贴输入的公司原始文本，进行分析与特征提取，有则更新或丰富提炼，无则保留原有数据：
【用户输入的文本开始】
${aiRawInput.value}
【用户输入的文本结束】`;

      const fullPrompt = `${systemPrompt}\n\n${userPrompt}`;
      const res = await props.callAiApi(fullPrompt);
      if (res && !res.startsWith('⚠️')) {
        extractedText = res;
      }
    }

    let parsed = null;
    if (extractedText) {
      try {
        let jsonStr = extractedText.trim();
        const jsonMatch = jsonStr.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          jsonStr = jsonMatch[0];
        }
        parsed = JSON.parse(jsonStr);
      } catch (err) {
        console.error('Failed to parse extracted company JSON:', err, extractedText);
      }
    }

    let company = {
      chineseName: props.ourCompanyInfo.chineseName,
      englishName: props.ourCompanyInfo.englishName,
      coreAdvantages: props.ourCompanyInfo.coreAdvantages,
      certifications: props.ourCompanyInfo.certifications,
      exportExperience: props.ourCompanyInfo.exportExperience,
      website: props.ourCompanyInfo.website,
      presetIncoterms: props.ourCompanyInfo.presetIncoterms,
      address: props.ourCompanyInfo.address,
      foundedYear: props.ourCompanyInfo.foundedYear,
      employeeCount: props.ourCompanyInfo.employeeCount,
      annualExport: props.ourCompanyInfo.annualExport,
      targetMarkets: props.ourCompanyInfo.targetMarkets,
    };

    if (parsed) {
      company = {
        chineseName: parsed.chineseName || company.chineseName,
        englishName: parsed.englishName || company.englishName,
        coreAdvantages: parsed.coreAdvantages || company.coreAdvantages,
        certifications: parsed.certifications || company.certifications,
        exportExperience: parsed.exportExperience || company.exportExperience,
        website: parsed.website || company.website,
        presetIncoterms: parsed.presetIncoterms || company.presetIncoterms,
        address: parsed.address || company.address,
        foundedYear: parsed.foundedYear || company.foundedYear,
        employeeCount: parsed.employeeCount || company.employeeCount,
        annualExport: parsed.annualExport || company.annualExport,
        targetMarkets: parsed.targetMarkets || company.targetMarkets,
      };
    } else {
      const txt = aiRawInput.value.toLowerCase();
      if (txt.includes('jfc4x4') || txt.includes('金丰呈') || txt.includes('越野') || txt.includes('改装')) {
        company = { ...company, chineseName: '金丰呈越野改装制造有限公司', englishName: 'JFC4x4 Off-Road Manufacturing Co., Ltd.', coreAdvantages: '越野竞技前防撞杠、底盘护甲、高抗冲击防沙板、涉水喉、竞技级悬挂避震阻尼器系统，支持 OEM/ODM 定制。', certifications: '澳大利亚 ADR 碰撞安全认证, 欧盟 CE, ISO 9001。', website: 'https://jfc4x4.com/', presetIncoterms: 'FOB Ningbo, CIF Melbourne, DDP Brisbane', targetMarkets: '澳大利亚、美国、欧洲、南非' };
      }
    }

    emit('update:ourCompanyInfo', company);
    editForm.value = { ...company };
    aiRawInput.value = '';
    activeMain.value = 'detail';
  } catch (err) {
    console.error('AI Importer failed:', err);
  } finally {
    isAnalyzingCompany.value = false;
  }
}
</script>
