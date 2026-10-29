<template>
  <div class="font-sans text-zen-ink relative z-10 space-y-6">
    
    <!-- ----------------------------------------------------
         VIEW 1: Premium Utility Hub Card List (工具箱主页)
         ---------------------------------------------------- -->
    <div v-if="activeTool === null" class="space-y-8 animate-fadeIn">
      <!-- Header -->
      <div class="space-y-2 select-none">
        <h2 class="text-2xl font-bold font-serif-sc tracking-wide flex items-center gap-2">
          <!-- Premium squircle tool icon -->
          <span class="w-8 h-8 rounded-xl bg-zen-ink text-white flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
            </svg>
          </span>
          智能工具箱
        </h2>
        <p class="text-xs text-zen-gray font-sans font-medium uppercase tracking-wider">PREMIUM UTILITY HUB</p>
        <p class="text-xs text-zen-gray leading-relaxed max-w-2xl mt-1">
          集成多维度的智能分析工具，助您轻松把控数字化业务的每一个细节。从公司诊断到大模型客户深度调研，一应俱全。
        </p>
      </div>

      <!-- Tools Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6 select-none">
        
        <!-- CARD 1: SEO/GEO 诊断大模型 -->
        <div
          @click="activeTool = 'seo'"
          class="apple-glass rounded-[28px] p-8 border border-white/50 flex flex-col justify-between min-h-[260px] cursor-pointer hover:shadow-2xl hover:translate-y-[-4px] hover:bg-white/85 transition-all duration-300 relative group"
        >
          <!-- Glowing indicator on hover -->
          <div class="absolute inset-0 rounded-[28px] border-2 border-transparent group-hover:border-zen-green/20 transition-all duration-300"></div>
          
          <div class="space-y-6">
            <div class="flex justify-between items-start">
              <div class="w-12 h-12 rounded-2xl bg-zen-ink text-white flex items-center justify-center shadow-md">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
                </svg>
              </div>
              <span class="text-[9px] font-bold text-white px-3 py-1 bg-zen-ink rounded-full uppercase tracking-wider shadow-sm">
                核心推荐
              </span>
            </div>
            
            <div class="space-y-2">
              <h3 class="text-base font-bold text-zen-ink font-serif-sc">SEO/GEO 诊断大模型</h3>
              <p class="text-xs text-zen-gray leading-relaxed font-sans">
                全方位检测网站 SEO、性能、适配及可访问性，并生成专业 HTML 报告。
              </p>
            </div>
          </div>

          <div class="pt-4 flex justify-between items-center border-t border-zen-light/20 mt-4">
            <span class="text-xs font-bold text-zen-ink group-hover:text-zen-green transition-colors">立即开启</span>
            <div class="w-8 h-8 rounded-full bg-zen-light/40 group-hover:bg-zen-green group-hover:text-white flex items-center justify-center text-zen-ink transition-all shadow-sm">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>

        <!-- CARD 2: 客户深度分析大模型 -->
        <div
          @click="activeTool = 'customer'"
          class="apple-glass rounded-[28px] p-8 border border-white/50 flex flex-col justify-between min-h-[260px] cursor-pointer hover:shadow-2xl hover:translate-y-[-4px] hover:bg-white/85 transition-all duration-300 relative group"
        >
          <div class="absolute inset-0 rounded-[28px] border-2 border-transparent group-hover:border-blue-500/20 transition-all duration-300"></div>

          <div class="space-y-6">
            <div class="flex justify-between items-start">
              <div class="w-12 h-12 rounded-2xl bg-[#00a2ff] text-white flex items-center justify-center shadow-md">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
              </div>
              <span class="text-[9px] font-bold text-white px-3 py-1 bg-zen-ink rounded-full uppercase tracking-wider shadow-sm">
                全新升级
              </span>
            </div>

            <div class="space-y-2">
              <h3 class="text-base font-bold text-zen-ink font-serif-sc">客户深度分析大模型</h3>
              <p class="text-xs text-zen-gray leading-relaxed font-sans">
                高精 4-Step Stepper 配置向导，结合公司核心优势全自动同步客户详情页。
              </p>
            </div>
          </div>

          <div class="pt-4 flex justify-between items-center border-t border-zen-light/20 mt-4">
            <span class="text-xs font-bold text-[#00a2ff] group-hover:text-blue-600 transition-colors">立即开启</span>
            <div class="w-8 h-8 rounded-full bg-blue-50/60 group-hover:bg-[#00a2ff] group-hover:text-white flex items-center justify-center text-[#00a2ff] transition-all shadow-sm">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>

        <!-- CARD 3: IT 安全扫描仪 -->
        <div
          class="bg-white/30 backdrop-blur-md rounded-[28px] p-8 border border-white/30 flex flex-col justify-between min-h-[260px] opacity-60 cursor-not-allowed transition-all relative"
        >
          <div class="space-y-6">
            <div class="flex justify-between items-start">
              <div class="w-12 h-12 rounded-2xl bg-slate-200 text-slate-400 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <span class="text-[9px] font-bold text-slate-400 px-3 py-1 bg-slate-100 rounded-full uppercase tracking-wider">
                实验室
              </span>
            </div>

            <div class="space-y-2">
              <h3 class="text-base font-bold text-slate-400 font-serif-sc">IT 安全扫描仪 (即将上线)</h3>
              <p class="text-xs text-slate-400/80 leading-relaxed font-sans">
                检测 SSL 证书、HTTP 响应头及常见的 Web 安全漏洞配置。
              </p>
            </div>
          </div>

          <div class="pt-4 flex justify-between items-center border-t border-slate-200/20 mt-4">
            <span class="text-xs font-bold text-slate-400">即将推出</span>
            <div class="w-8 h-8 rounded-full bg-slate-100/50 flex items-center justify-center text-slate-300 shadow-sm">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- ----------------------------------------------------
         VIEW 2: SEO/GEO Diagnosis Model Workspace (SEO/GEO 诊断页面)
         ---------------------------------------------------- -->
    <div v-else-if="activeTool === 'seo'" class="space-y-6 animate-fadeIn">
      <!-- Back Header -->
      <div class="flex items-center gap-4 select-none">
        <button
          @click="activeTool = null"
          class="px-4 py-2 bg-white/50 hover:bg-white hover:translate-x-[-3px] border border-white/60 rounded-xl text-xs text-zen-ink font-semibold shadow-sm transition-all duration-300 outline-none flex items-center gap-1.5"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7" />
          </svg>
          返回工具箱
        </button>
        <div class="h-6 w-[1px] bg-white/30"></div>
        <h2 class="text-lg font-bold font-serif-sc text-zen-ink">SEO/GEO 诊断大模型</h2>
      </div>

      <!-- Main Input Panel -->
      <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4">
        <div class="flex flex-col md:flex-row gap-4">
          <div class="flex-1 space-y-1">
            <label class="block text-xs font-bold text-zen-ink">外贸独立站域名 (Target Domain)</label>
            <input
              type="text"
              v-model="seoUrl"
              placeholder="请输入企业独立站网址，例如 www.zen-cargo-parts.com"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-4 py-2.5 text-xs text-zen-ink outline-none focus:bg-white focus:border-zen-green transition-all"
            />
          </div>
          <div class="w-full md:w-56 space-y-1 select-none">
            <label class="block text-xs font-bold text-zen-ink">物理诊断路由节点 (GEO Node)</label>
            <select
              v-model="seoNode"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2.5 text-xs text-zen-ink outline-none focus:bg-white focus:border-zen-green transition-all"
            >
              <option value="frankfurt">欧洲法兰克福 (Frankfurt)</option>
              <option value="singapore">东南亚新加坡 (Singapore)</option>
              <option value="dubai">中东迪拜 (Dubai Node)</option>
              <option value="tokyo">东亚东京港口 (Tokyo)</option>
            </select>
          </div>
        </div>

        <div class="flex justify-between items-center text-xs select-none gap-3 pt-2">
          <p class="text-[10px] text-zen-gray max-w-[70%]">
            AI 诊断网关将针对独立站的 Meta 标头、页面响应度（Core Web Vitals）进行安全抓取，同时多节点路由测算不同国家买家的加载延迟。
          </p>
          <button
            @click="runSeoAudit"
            :disabled="isAuditing"
            class="px-5 py-2.5 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white font-bold text-xs shadow-md transition-all outline-none whitespace-nowrap"
          >
            {{ isAuditing ? '全站抓取诊断中...' : '启动全方位 AI 诊断' }}
          </button>
        </div>

        <!-- Diagnostic progress simulator -->
        <div v-if="isAuditing" class="space-y-1.5 pt-2 select-none">
          <div class="flex justify-between text-[10px] text-zen-green font-mono">
            <span>正在通过 [{{ seoNode.toUpperCase() }}] 边缘节点模拟抓取...</span>
            <span>{{ auditProgress }}%</span>
          </div>
          <div class="h-1.5 w-full bg-black/5 rounded-full overflow-hidden">
            <div class="bg-zen-green h-full transition-all duration-300" :style="{ width: auditProgress + '%' }"></div>
          </div>
        </div>
      </div>

      <!-- Diagnostic Results Dashboard -->
      <div v-if="auditComplete" class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-stretch">
        <!-- Left: Overall Score Card -->
        <div class="lg:col-span-1 apple-glass rounded-3xl p-6 border border-white/50 flex flex-col justify-between items-center text-center relative overflow-hidden select-none">
          <div class="absolute inset-0 bg-zen-green/[0.01] pointer-events-none"></div>
          <div class="w-full pb-3 border-b border-white/20 select-none">
            <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold font-serif-sc">全站诊断健康评分</span>
            <span class="text-xs font-semibold text-zen-green mt-1 block">SEO 与加载速度极佳</span>
          </div>

          <div class="relative w-36 h-36 flex items-center justify-center my-6">
            <svg class="w-full h-full transform -rotate-90">
              <circle cx="72" cy="72" r="60" stroke="rgba(0,0,0,0.03)" stroke-width="6" fill="transparent" />
              <circle
                cx="72" cy="72" r="60" stroke="#627254" stroke-width="8" fill="transparent"
                :stroke-dasharray="2 * Math.PI * 60"
                :stroke-dashoffset="(1 - 0.94) * (2 * Math.PI * 60)"
                class="transition-all duration-1000 ease-out"
                stroke-linecap="round"
              />
            </svg>
            <div class="absolute flex flex-col items-center">
              <span class="text-3xl font-bold font-mono tracking-wide">94</span>
              <span class="text-[9px] text-zen-gray">Rank: Grade A</span>
            </div>
          </div>

          <div class="w-full space-y-2 text-[11px] text-zen-ink text-left">
            <div class="flex justify-between">
              <span class="text-zen-gray font-medium">Meta 标头合规性:</span>
              <span class="font-bold text-zen-green">100% 合规</span>
            </div>
            <div class="flex justify-between">
              <span class="text-zen-gray font-medium">Core Web Vitals:</span>
              <span class="font-bold text-zen-green">极速加载</span>
            </div>
            <div class="flex justify-between">
              <span class="text-zen-gray font-medium">无障碍适配:</span>
              <span class="font-bold text-zen-gold">88% 需微调</span>
            </div>
          </div>
        </div>

        <!-- Right: Detail Audits list -->
        <div class="lg:col-span-2 space-y-5">
          <div class="apple-glass rounded-2xl p-5 border border-white/50 space-y-3">
            <div class="flex justify-between items-center select-none pb-2 border-b border-zen-light/20">
              <h4 class="text-xs font-bold text-zen-ink font-serif-sc flex items-center gap-1.5">
                <span class="w-2 h-2 rounded-full bg-zen-green"></span>
                Meta 标头与标签审核 (SEO Metadata)
              </h4>
              <span class="text-[9px] font-bold text-zen-green bg-zen-green/5 border border-zen-green/10 px-1.5 py-0.5 rounded">通过 (Passed)</span>
            </div>
            <div class="space-y-2.5 text-xs">
              <div class="flex justify-between">
                <span class="text-zen-gray">Title Tag:</span>
                <span class="font-mono text-zen-ink font-semibold">"High-Resilience Water Storage Equipment | Zen Parts" (52 chars)</span>
              </div>
              <div class="flex justify-between">
                <span class="text-zen-gray">Meta Description:</span>
                <span class="font-mono text-zen-ink font-semibold">"Zen Auto Parts manufactures heavy-duty SUS304 water tanks and folding TPU reservoirs..." (145 chars)</span>
              </div>
              <div class="flex justify-between">
                <span class="text-zen-gray">OpenGraph (OG) Tags:</span>
                <span class="font-mono text-zen-green font-semibold">已配置 (og:title, og:image, og:type)</span>
              </div>
            </div>
          </div>

          <div class="apple-glass rounded-2xl p-5 border border-white/50 space-y-3">
            <div class="flex justify-between items-center select-none pb-2 border-b border-zen-light/20">
              <h4 class="text-xs font-bold text-zen-ink font-serif-sc flex items-center gap-1.5">
                <span class="w-2 h-2 rounded-full bg-zen-green"></span>
                核心页面速度指标 (Core Web Vitals)
              </h4>
              <span class="text-[9px] font-bold text-zen-green bg-zen-green/5 border border-zen-green/10 px-1.5 py-0.5 rounded">极速 (Good)</span>
            </div>
            <div class="grid grid-cols-3 gap-4 text-center">
              <div class="bg-black/[0.02] border border-white/30 p-2.5 rounded-xl">
                <span class="block text-[8px] text-zen-gray uppercase">LCP (最大内容渲染)</span>
                <span class="text-xs font-bold font-mono text-zen-green block mt-1">1.2s</span>
              </div>
              <div class="bg-black/[0.02] border border-white/30 p-2.5 rounded-xl">
                <span class="block text-[8px] text-zen-gray uppercase">INP (页面交互延迟)</span>
                <span class="text-xs font-bold font-mono text-zen-green block mt-1">75ms</span>
              </div>
              <div class="bg-black/[0.02] border border-white/30 p-2.5 rounded-xl">
                <span class="block text-[8px] text-zen-gray uppercase">CLS (累计布局偏移)</span>
                <span class="text-xs font-bold font-mono text-zen-green block mt-1">0.02</span>
              </div>
            </div>
          </div>

          <div class="apple-glass rounded-2xl p-5 border border-white/50 space-y-3">
            <div class="flex justify-between items-center select-none pb-2 border-b border-zen-light/20">
              <h4 class="text-xs font-bold text-zen-ink font-serif-sc flex items-center gap-1.5">
                <span class="w-2 h-2 rounded-full bg-zen-gold"></span>
                GEO 全球买家访问延迟精算 (GEO Latency Routing)
              </h4>
              <span class="text-[9px] font-bold text-zen-gold bg-zen-gold/5 border border-zen-gold/10 px-1.5 py-0.5 rounded">提示 (Warning)</span>
            </div>
            <div class="space-y-2 text-xs">
              <div class="flex justify-between items-center">
                <span class="text-zen-gray flex items-center gap-1">🇩🇪 欧洲法兰克福买家 (CIF 热门地)</span>
                <span class="font-mono text-zen-green font-bold">28ms - 极速直连</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-zen-gray flex items-center gap-1">🇹🇭 东南亚清迈买家 (水利大客户)</span>
                <span class="font-mono text-zen-green font-bold">45ms - 加载极速</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-zen-gray flex items-center gap-1">🇦🇪 中东迪拜买家 (Farooq 代表)</span>
                <span class="font-mono text-zen-green font-bold">52ms - 加载极速</span>
              </div>
              <div class="flex justify-between items-center">
                <span class="text-zen-gray flex items-center gap-1">🇷🇺 俄罗斯莫斯科买家 (Dima 询盘地)</span>
                <span class="font-mono text-zen-crimson font-bold">148ms - 访问延迟 (中度拥堵)</span>
              </div>
              
              <div class="p-3 bg-zen-tea/10 border border-zen-green/20 rounded-xl text-[10px] text-zen-green font-medium flex items-center gap-2 mt-2">
                <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
                <span>网关路由建议：针对 [俄罗斯] 买家的访问延迟，已自动推荐部署 <strong>物理极密 Llama 3 本地化路由</strong> 进行无网络防谍数据流转。</span>
              </div>
            </div>
          </div>

          <div class="flex justify-end select-none pt-2">
            <button
              @click="exportHtmlReport"
              class="px-5 py-2 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white font-bold text-xs transition-all shadow-md outline-none"
            >
              导出专业 HTML 诊断报告
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- ----------------------------------------------------
         VIEW 3: Rebuilt Stepper Customer Analysis Workspace (客户深度分析四步向导)
         ---------------------------------------------------- -->
    <div v-else-if="activeTool === 'customer'" class="space-y-6 animate-fadeIn">
      
      <!-- Back Header -->
      <div class="flex items-center gap-4 select-none">
        <button
          @click="activeTool = null"
          class="px-4 py-2 bg-white/50 hover:bg-white hover:translate-x-[-3px] border border-white/60 rounded-xl text-xs text-zen-ink font-semibold shadow-sm transition-all duration-300 outline-none flex items-center gap-1.5"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7" />
          </svg>
          返回工具箱
        </button>
        <div class="h-6 w-[1px] bg-white/30"></div>
        <h2 class="text-lg font-bold font-serif-sc text-zen-ink">客户深度分析大模型</h2>
      </div>

      <!-- Screenshot Replica TOP Header Card (还原截图顶卡) -->
      <div class="relative bg-gradient-to-r from-[#0C1220] to-[#16223F] rounded-[24px] p-8 text-white border border-white/10 shadow-2xl flex flex-col md:flex-row justify-between items-stretch gap-6 select-none overflow-hidden">
        <!-- Abstract decor blob -->
        <div class="absolute -right-16 -top-16 w-60 h-60 rounded-full bg-blue-500/10 blur-[80px] pointer-events-none"></div>

        <div class="flex-1 space-y-4">
          <div class="flex items-center gap-3">
            <div class="w-11 h-11 rounded-2xl bg-white/10 text-white flex items-center justify-center text-xl shadow-inner">
              👥
            </div>
            <div>
              <h2 class="text-lg font-bold font-serif-sc tracking-widest flex items-center gap-2">
                客户深度分析工具
              </h2>
              <p class="text-[9px] text-slate-350 uppercase tracking-widest font-mono">DEEP CLIENT ANALYSIS · RESEARCH / VALIDATION / GTM</p>
            </div>
          </div>

          <p class="text-[11px] text-slate-300 leading-relaxed max-w-xl">
            这个工具的核心目标是：提取目标客户公开信息，梳理当前客户开发进展，并结合我方产品、能力与证据，生成可直接用于营销推进和客户开发的分析报告。整体结构参考 `deep-client-analysis` 的标准流程与 SPI 风格交付方式，但真实数据只来自实际抓取到的官网、搜索结果、第三方数据库和公开页面。
          </p>

          <div class="flex flex-wrap gap-2 pt-2">
            <span class="px-2.5 py-0.5 rounded bg-white/10 text-[9px] text-slate-200 border border-white/5 font-semibold">四步标准流程</span>
            <span class="px-2.5 py-0.5 rounded bg-white/10 text-[9px] text-slate-200 border border-white/5 font-semibold">每个模块都有来源与验证</span>
            <span class="px-2.5 py-0.5 rounded bg-white/10 text-[9px] text-slate-200 border border-white/5 font-semibold">HTML / Markdown 双报告</span>
          </div>
        </div>

        <!-- Right structure spec box -->
        <div class="w-full md:w-80 bg-white/5 border border-white/10 p-5 rounded-2xl flex flex-col justify-between shrink-0">
          <div class="space-y-1">
            <span class="block text-[8px] uppercase tracking-wider text-slate-400 font-bold">结构基准</span>
            <h4 class="text-xs font-bold text-slate-200 font-serif-sc">SPI 风格交付结构</h4>
            <p class="text-[9px] text-slate-400 leading-normal">模块内单独标注数据来源、交叉验证和待补充信息，不把证据全部丢到报告结尾。</p>
          </div>
          
          <div class="grid grid-cols-2 gap-3 pt-4 border-t border-white/5 mt-4">
            <div class="bg-white/5 p-2 rounded-xl border border-white/5">
              <span class="block text-[8px] text-slate-400 uppercase">流程</span>
              <strong class="text-sm font-serif-sc text-blue-400 block mt-0.5">4 步</strong>
            </div>
            <div class="bg-white/5 p-2 rounded-xl border border-white/5">
              <span class="block text-[8px] text-slate-400 uppercase">模块</span>
              <strong class="text-sm font-serif-sc text-blue-400 block mt-0.5">10 个</strong>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Columns Layout Grid (4-Step Wizard & External Reports) -->
      <div class="grid gap-6 items-start" :class="scannerCollapsed ? 'grid-cols-1' : 'grid-cols-1 xl:grid-cols-3'">
        
        <!-- Left 2/3: The Stepper config and output -->
        <div class="space-y-6" :class="scannerCollapsed ? '' : 'xl:col-span-2'">
          
          <!-- Stepper Wizard Card -->
          <div class="apple-glass rounded-[28px] p-6 border border-white/50 space-y-6">
            
            <!-- Standard Stepper Headers (横向四步圆钮向导) -->
            <div class="flex items-center justify-between border-b border-white/20 pb-4 select-none gap-2">
              <div
                v-for="step in [
                  { num: 1, label: '目标客户信息' },
                  { num: 2, label: '模块选择' },
                  { num: 3, label: '我方公司信息' },
                  { num: 4, label: '输出与导出' }
                ]"
                :key="step.num"
                class="flex items-center gap-2 transition-all duration-300"
                :class="currentStep === step.num ? 'opacity-100 scale-102' : 'opacity-65'"
              >
                <span
                  class="w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-mono font-bold shadow-sm"
                  :class="currentStep >= step.num ? 'bg-zen-ink text-white' : 'bg-black/5 text-zen-gray'"
                >
                  {{ step.num }}
                </span>
                <span class="text-[10px] font-bold hidden md:block" :class="currentStep === step.num ? 'text-zen-ink font-bold' : 'text-zen-gray'">
                  {{ step.label }}
                </span>
              </div>
            </div>

            <!-- STEP 1: 目标客户信息录入 -->
            <div v-if="currentStep === 1" class="space-y-4 animate-fadeIn text-xs">
              <div class="flex justify-between items-center select-none pb-2 border-b border-black/[0.04]">
                <span class="text-[10px] text-zen-gray font-bold uppercase tracking-wider">Step 1 / 4: 填写或选定目标画像客户属性</span>
                <span class="text-[9px] text-zen-green font-bold">✨ 支持关联全局公海客户自动回填</span>
              </div>

              <!-- Customer Linker Dropdown -->
              <div class="space-y-1.5 select-none">
                <label class="block font-bold text-zen-ink">关联公海现有客户 (快速导入数据)</label>
                <select
                  v-model="associatedLeadId"
                  @change="handleExistingCustomerSelect"
                  class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green"
                >
                  <option value="new">🆕 手工录入新客进行分析 (分析完将自动同步至公海)</option>
                  <option v-for="l in leads" :key="l.id" :value="l.id">
                    {{ l.flag }} {{ l.name }} ({{ l.country }}) | 意向: {{ l.routingPath }}
                  </option>
                </select>
              </div>

              <!-- Main Input Grid -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="space-y-1.5">
                  <label class="block font-bold text-zen-ink">目标客户名称 *</label>
                  <input
                    type="text"
                    v-model="clientForm.name"
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green"
                    placeholder="例如: Premier Sports Lighting, LLC"
                  />
                </div>
                <div class="space-y-1.5">
                  <label class="block font-bold text-zen-ink">目标客户官网 URL *</label>
                  <input
                    type="text"
                    v-model="clientForm.url"
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3.5 py-2 outline-none focus:bg-white focus:border-zen-green font-mono"
                    placeholder="例如: https://www.psl-sports.com"
                  />
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 select-none">
                <div class="space-y-1.5">
                  <label class="block font-bold text-zen-ink">所属行业</label>
                  <select
                    v-model="clientForm.industry"
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 outline-none focus:bg-white"
                  >
                    <option value="parts">汽车配件制造与重载冷却</option>
                    <option value="lights">工业户外与场馆照明 (LED)</option>
                    <option value="agri">山地农业灌溉与水利系统</option>
                    <option value="storage">柔性储水与特种容器制品</option>
                  </select>
                </div>
                <div class="space-y-1.5">
                  <label class="block font-bold text-zen-ink">分析目的</label>
                  <select
                    v-model="clientForm.goal"
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 outline-none focus:bg-white"
                  >
                    <option value="development">客户开发 / 地道开发信拟写</option>
                    <option value="credit">商会注册背调与信用授信风控</option>
                    <option value="routing">跨页面协同与驻地代理商流转</option>
                    <option value="legal">进出口海运限制与合规性审查</option>
                  </select>
                </div>
              </div>

              <!-- Concerns Description -->
              <div class="space-y-1.5">
                <label class="block font-bold text-zen-ink">调研说明 / 特别关注项</label>
                <textarea
                  v-model="clientForm.concerns"
                  rows="3"
                  class="w-full bg-white/40 border border-white/50 rounded-xl p-3 outline-none focus:bg-white focus:border-zen-green leading-normal"
                  placeholder="例如: 重点看体育照明控制系统、采购决策链、以及对方核心痛点..."
                ></textarea>
              </div>
            </div>

            <!-- STEP 2: 模块选择 (10 个核心模块) -->
            <div v-if="currentStep === 2" class="space-y-4 animate-fadeIn text-xs">
              <div class="flex justify-between items-center select-none pb-2 border-b border-black/[0.04]">
                <span class="text-[10px] text-zen-gray font-bold uppercase tracking-wider">Step 2 / 4: 选择拟生成分析报告的 10 大 SPI 模块</span>
                <button @click="toggleAllModules" class="text-[9px] text-indigo-600 font-bold hover:underline">
                  {{ selectedModules.length === 10 ? '全选取消' : '一键全选' }}
                </button>
              </div>

              <!-- Checkbox modules card list -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div
                  v-for="mod in availableModules"
                  :key="mod.id"
                  @click="toggleModule(mod.id)"
                  class="p-4 bg-white/30 hover:bg-white/60 border border-white/50 rounded-2xl cursor-pointer select-none transition-all duration-300 flex items-start gap-3"
                  :class="selectedModules.includes(mod.id) ? 'bg-white border-zen-green shadow-sm ring-1 ring-zen-green/20' : ''"
                >
                  <input
                    type="checkbox"
                    :value="mod.id"
                    v-model="selectedModules"
                    class="rounded text-zen-green focus:ring-zen-green mt-0.5 shrink-0 pointer-events-none"
                  />
                  <div>
                    <h5 class="text-[11px] font-bold text-zen-ink flex items-center gap-1.5">
                      {{ mod.title }}
                      <span class="text-[8px] px-1 bg-black/[0.03] text-zen-gray rounded border uppercase font-mono font-bold">{{ mod.code }}</span>
                    </h5>
                    <p class="text-[9px] text-zen-gray mt-1 leading-normal font-serif-sc">{{ mod.desc }}</p>
                  </div>
                </div>
              </div>
            </div>

            <!-- STEP 3: 我方公司信息 (自动注入，锁定 preview) -->
            <div v-if="currentStep === 3" class="space-y-4 animate-fadeIn text-xs">
              <div class="flex justify-between items-center select-none pb-2 border-b border-black/[0.04]">
                <span class="text-[10px] text-zen-gray font-bold uppercase tracking-wider">Step 3 / 4: 整合我方公司核心档案 (已自动就绪)</span>
                <span class="text-[9px] text-zen-green font-bold flex items-center gap-1">
                  🛡️ 免除手动选择
                </span>
              </div>

              <div class="p-5 bg-zen-tea/5 border border-zen-green/20 rounded-[24px] space-y-4">
                <div class="flex items-center gap-3 pb-3 border-b border-zen-green/10 select-none">
                  <div class="w-10 h-10 rounded-2xl bg-zen-ink text-white flex items-center justify-center font-serif-sc text-lg">
                    禪
                  </div>
                  <div>
                    <h4 class="text-xs font-bold text-zen-ink leading-tight">{{ ourCompanyInfo.chineseName }}</h4>
                    <p class="text-[9px] text-zen-gray font-mono uppercase mt-0.5">{{ ourCompanyInfo.englishName }}</p>
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div class="space-y-1">
                    <span class="block text-[8px] uppercase tracking-wider text-zen-gray font-bold select-none">核心产品及竞争壁垒:</span>
                    <p class="text-[10px] text-zen-ink leading-normal font-serif-sc">{{ ourCompanyInfo.coreAdvantages }}</p>
                  </div>
                  <div class="space-y-1">
                    <span class="block text-[8px] uppercase tracking-wider text-zen-gray font-bold select-none">持有的国际合规资质:</span>
                    <p class="text-[10px] text-indigo-700 leading-normal font-mono font-bold">{{ ourCompanyInfo.certifications }}</p>
                  </div>
                </div>

                <div class="pt-2.5 border-t border-zen-green/10 flex justify-between items-center text-[9px] text-zen-gray select-none">
                  <span>常用术语：{{ ourCompanyInfo.presetIncoterms }} | 出口实力：{{ ourCompanyInfo.exportExperience }}</span>
                  <span class="font-bold text-zen-green font-mono flex items-center gap-1">✓ Global Sync Locked</span>
                </div>
              </div>

              <div class="p-4 bg-white/40 border border-white/50 rounded-2xl leading-relaxed text-[10px] text-zen-gray select-none">
                我方背景已全自动作为分析工具的对照 Baseline，多模型 AI 智能体将基于此为您量身核算定制的**合作契合度深度建模 (Collaboration Fit) 与 GTM 行动清单**。
              </div>
            </div>

            <!-- STEP 4: 输出与导出 (成果面板与同步连通) -->
            <div v-if="currentStep === 4" class="space-y-4 animate-fadeIn text-xs">
              <div class="flex justify-between items-center select-none pb-2 border-b border-black/[0.04]">
                <span class="text-[10px] text-zen-gray font-bold uppercase tracking-wider">Step 4 / 4: 分析报告产出与双向连通控制台</span>
              </div>

              <!-- Generation Trigger -->
              <div v-if="!analysisReportGenerated" class="p-8 text-center bg-white/20 border border-white/40 rounded-3xl space-y-4 flex flex-col justify-center items-center">
                <span class="text-4xl animate-bounce">🤖</span>
                <h4 class="text-xs font-bold text-zen-ink font-serif-sc">已万事俱备，可一键启动大模型深度交叉分析</h4>
                <p class="text-[10px] text-zen-gray max-w-sm leading-relaxed select-none">
                  AI 智能团队（SPI调研师、开发信润色官、法务合规员）将基于选取的 {{ selectedModules.length }} 个 SPI 模块、我方公司实力及目标客商官网，开启全球商会与海关仓单数据库离线精算。
                </p>

                <div class="w-full max-w-xs pt-3" v-if="isGeneratingReport">
                  <div class="flex justify-between text-[8px] text-zen-green font-mono mb-1 select-none">
                    <span>{{ generationStep }}</span>
                    <span>{{ generationProgress }}%</span>
                  </div>
                  <div class="h-1.5 w-full bg-black/5 rounded-full overflow-hidden">
                    <div class="bg-zen-green h-full transition-all duration-300" :style="{ width: generationProgress + '%' }"></div>
                  </div>
                </div>

                <button
                  v-else
                  @click="runStepperAnalysis"
                  class="px-6 py-2.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-xs font-bold shadow-md transition-all outline-none"
                >
                  🚀 启动全球多维抓取与 AI 综合分析
                </button>
              </div>

              <!-- Report Results Panel -->
              <div v-else class="space-y-4">
                
                <!-- Double tab headers -->
                <div class="flex items-center gap-1 bg-black/[0.04] p-0.5 rounded-xl border border-black/[0.02] select-none text-[9px] font-bold">
                  <button
                    @click="activeReportTab = 'markdown'"
                    class="flex-1 py-1.5 rounded-lg transition-all"
                    :class="activeReportTab === 'markdown' ? 'bg-white text-zen-ink shadow-xs' : 'text-zen-gray hover:text-zen-ink'"
                  >
                    Markdown SPI 报告
                  </button>
                  <button
                    @click="activeReportTab = 'html'"
                    class="flex-1 py-1.5 rounded-lg transition-all"
                    :class="activeReportTab === 'html' ? 'bg-white text-zen-ink shadow-xs' : 'text-zen-gray hover:text-zen-ink'"
                  >
                    拟真 HTML Feasibility 渲染
                  </button>
                  <button
                    @click="activeReportTab = 'json'"
                    class="flex-1 py-1.5 rounded-lg transition-all"
                    :class="activeReportTab === 'json' ? 'bg-white text-zen-ink shadow-xs' : 'text-zen-gray hover:text-zen-ink'"
                  >
                    JSON 结构化图表源数据
                  </button>
                </div>

                <!-- Report Content Display Box -->
                <div class="max-h-[360px] overflow-y-auto pr-1 bg-white/60 border border-white/50 rounded-2xl p-5 text-[11px] leading-relaxed">
                  <!-- Markdown view -->
                  <div v-if="activeReportTab === 'markdown'" class="font-serif-sc whitespace-pre-wrap select-text">
                    {{ generatedReportData.markdown }}
                  </div>
                  <!-- HTML view -->
                  <div v-else-if="activeReportTab === 'html'" class="select-text">
                    <iframe :srcdoc="generatedReportData.html" class="w-full h-[320px] bg-white border border-slate-200 rounded-xl" frameborder="0"></iframe>
                  </div>
                  <!-- JSON view -->
                  <div v-else class="font-mono whitespace-pre select-text text-[10px]">
                    {{ JSON.stringify(generatedReportData.json, null, 2) }}
                  </div>
                </div>

                <!-- One-click Sync to Customer Details (双向连通) -->
                <div class="pt-4 border-t border-white/20 select-none flex flex-col md:flex-row justify-between items-center gap-4">
                  <div class="flex items-center gap-1.5 text-[10px] text-zen-gray">
                    <span class="w-2 h-2 rounded-full bg-zen-green animate-pulse"></span>
                    <span>分析完毕！已通过 SQLite 沙箱进行本地加密防护保护 🔐</span>
                  </div>
                  
                  <div class="flex gap-2">
                    <button
                      @click="copyConfig"
                      class="px-4 py-2 bg-white/40 border border-white/50 hover:bg-white rounded-xl text-[10px] font-bold text-zen-gray transition-all shadow-sm"
                    >
                      🗐 复制配置 (Copy)
                    </button>
                    <button
                      @click="downloadConfig"
                      class="px-4 py-2 bg-white/40 border border-white/50 hover:bg-white rounded-xl text-[10px] font-bold text-zen-gray transition-all shadow-sm"
                    >
                      📥 下载 JSON
                    </button>
                    <button
                      @click="syncGeneratedReport"
                      class="px-5 py-2 bg-zen-green hover:bg-zen-green/90 text-white rounded-xl text-[10px] font-bold shadow-md transition-all flex items-center gap-1"
                    >
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 5l7 7-7 7" />
                      </svg>
                      自动同步至客商详情分析报告页
                    </button>
                  </div>
                </div>

              </div>

            </div>

            <!-- Stepper Actions Button (上下步跳转控制) -->
            <div class="flex justify-between items-center pt-4 border-t border-white/20 select-none">
              <button
                @click="currentStep--"
                :disabled="currentStep === 1"
                class="px-4 py-2 rounded-xl border border-white/60 bg-white/30 text-zen-gray hover:text-zen-ink disabled:opacity-40 disabled:pointer-events-none transition-all text-xs font-semibold"
              >
                ← 上一步
              </button>
              <button
                @click="currentStep++"
                :disabled="currentStep === 4 || (currentStep === 1 && (!clientForm.name || !clientForm.url))"
                class="px-4 py-2 rounded-xl bg-zen-ink text-white hover:bg-zen-ink/90 disabled:opacity-40 disabled:pointer-events-none transition-all text-xs font-bold shadow-sm"
              >
                下一步 →
              </button>
            </div>

          </div>

          <!-- Scanner expand button (shown when scanner is collapsed) -->
          <div class="flex justify-end select-none" v-if="scannerCollapsed">
            <button
              @click="scannerCollapsed = false"
              class="px-3.5 py-1.5 rounded-xl bg-white/50 hover:bg-white border border-white/60 text-zen-gray hover:text-indigo-600 transition-all text-[10px] font-bold shadow-sm flex items-center gap-1.5"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
              </svg>
              展开外部扫描器
            </button>
          </div>
        </div>

        <!-- Right 1/3: External reports scanning companion card -->

        <div class="xl:col-span-1 space-y-6" v-if="!scannerCollapsed">
          <!-- Folder Scanner Component (外部报告智能扫描与同步器) -->
          <div class="apple-glass rounded-[28px] p-6 border border-white/50 space-y-4 select-none">
            <div class="flex items-center justify-between">
              <h3 class="text-xs font-bold font-serif-sc text-zen-ink flex items-center gap-2">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-indigo-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
                </svg>
                外部报告扫描器
              </h3>
              <button
                @click="scannerCollapsed = true"
                class="p-1.5 rounded-lg bg-white/40 hover:bg-white border border-white/50 text-zen-gray hover:text-zen-ink transition-all text-[10px] font-bold flex items-center gap-1"
                title="折叠扫描器"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
            
            <p class="text-[10px] text-zen-gray leading-relaxed">
              默认读取 /Users/ky/Desktop/汽配客户/deep_analysis_reports_v2 中的 MD / HTML 报告；源文件只读不修改，系统仅把报告内容绑定到客户档案。
            </p>

            <div class="flex items-center justify-between gap-2 rounded-2xl bg-white/30 border border-white/50 p-2.5">
              <span class="text-[8px] text-zen-gray font-mono truncate">{{ externalReportDir }}</span>
              <button
                @click="scanExternalReportDirectory"
                class="px-3 py-1.5 rounded-lg bg-white/70 hover:bg-white border border-white/70 text-[8px] font-bold text-zen-ink transition-all shadow-xs"
              >
                重新扫描
              </button>
            </div>

            <div v-if="scanMessage" class="text-[9px] text-zen-gray bg-white/25 border border-white/40 rounded-xl px-3 py-2 leading-relaxed">
              {{ scanMessage }}
            </div>

            <div class="space-y-2.5 pt-2">
              <div
                v-for="file in scannedExternalFiles"
                :key="file.filename"
                class="p-3.5 bg-white/40 hover:bg-white border border-white/50 rounded-2xl flex flex-col justify-between gap-2.5 transition-all duration-300 shadow-xs"
              >
                <div class="flex items-start gap-2.5">
                  <span class="text-xl">📄</span>
                  <div class="truncate">
                    <h5 class="text-[10px] font-bold text-zen-ink truncate font-mono">{{ file.filename }}</h5>
                    <p class="text-[8px] text-zen-gray mt-0.5">识别目标客户: <strong class="text-indigo-700 font-sans">{{ file.targetClientName }}</strong></p>
                  </div>
                </div>

                <div class="flex justify-between items-center text-[9px]">
                  <span
                    class="px-1.5 py-0.5 rounded text-[8px] font-bold font-mono"
                    :class="file.type === 'Markdown' ? 'bg-red-50 text-red-600 border border-red-150' : (file.type === 'JSON' ? 'bg-green-50 text-green-600 border border-green-150' : 'bg-indigo-50 text-indigo-600 border border-indigo-150')"
                  >
                    {{ file.type }}
                  </span>
                  
                  <button
                    v-if="!file.associated"
                    @click="syncExternalFile(file)"
                    class="px-3 py-1 rounded-lg bg-zen-ink text-white font-bold text-[8px] transition-all hover:scale-102 shadow-xs"
                  >
                    智能识别连通 🔗
                  </button>
                  <span class="text-zen-green font-bold flex items-center gap-0.5 text-[8px]" v-else>
                    ✓ 已成功贯通融合
                  </span>
                </div>
              </div>

              <div v-if="!scannedExternalFiles.length" class="p-5 text-center text-[10px] text-zen-gray/60 bg-white/20 border border-dashed border-white/50 rounded-2xl">
                尚未识别到可绑定的 MD / HTML 客户报告。
              </div>
            </div>
          </div>
        </div>

      </div>

    </div>

  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';

// Accept raised states from App.vue
const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  },
  leads: {
    type: Array,
    required: true
  },
  ourCompanyInfo: {
    type: Object,
    required: true
  }
});

const emit = defineEmits(['update:leads']);

// Active workspace view router ('seo', 'customer', null)
const activeTool = ref(null);

// External scanner panel collapsed state (default: collapsed)
const scannerCollapsed = ref(true);

// ----------------------------------------------------
// TOOL 1: SEO/GEO Diagnosis Model States & Logic
// ----------------------------------------------------
const seoUrl = ref('www.trade-water-equipment.com');
const seoNode = ref('frankfurt');
const isAuditing = ref(false);
const auditProgress = ref(0);
const auditComplete = ref(false);

const runSeoAudit = () => {
  isAuditing.value = true;
  auditProgress.value = 0;
  auditComplete.value = false;
  
  const timer = setInterval(() => {
    if (auditProgress.value >= 100) {
      clearInterval(timer);
      isAuditing.value = false;
      auditComplete.value = true;
      alert(`「AI 诊断成功」：已通过 [${seoNode.value.toUpperCase()}] GEO 网络通道对 [${seoUrl.value}] 完成全方位抓取审计！总体健康评分为 94/100！`);
    } else {
      auditProgress.value += 20;
    }
  }, 200);
};

const exportHtmlReport = () => {
  alert(`「独立站 HTML 诊断报告导出成功」：已将 ${seoUrl.value} 的全套性能、SEO标签及GEO延迟精算数据打包编译为 HTML/PDF 文件，保存在了您的本地 App 导出目录中。`);
};


// ----------------------------------------------------
// TOOL 2: Completely Rebuilt 4-Step Customer Analysis Stepper & Auto Sync Logic
// ----------------------------------------------------
const currentStep = ref(1);

// Step 1 states
const associatedLeadId = ref('new');
const clientForm = ref({
  name: '',
  url: '',
  industry: 'parts',
  goal: 'development',
  concerns: ''
});

const handleExistingCustomerSelect = () => {
  if (associatedLeadId.value === 'new') {
    clientForm.value = {
      name: '',
      url: '',
      industry: 'parts',
      goal: 'development',
      concerns: ''
    };
  } else {
    const lead = props.leads.find(l => l.id === Number(associatedLeadId.value));
    if (lead) {
      clientForm.value.name = lead.name;
      // Derive details dynamically
      clientForm.value.url = `https://www.${lead.name.toLowerCase().replace(/[^a-z0-id]/g, '') || 'client'}.com`;
      clientForm.value.industry = lead.category === 'parts' ? 'parts' : 'lights';
      clientForm.value.goal = lead.stage === 'deal' ? 'routing' : 'development';
      clientForm.value.concerns = `特别关注该地区买家的产品资质细节、海运清关及 AI 指标 ${lead.score} 分的综合推进跟进。`;
    }
  }
};

// Step 2 states: 10 Core Modules selection
const selectedModules = ref([
  'basics', 'financials', 'logistics', 'decision_chain', 'competitors',
  'pain_points', 'fit', 'gtm', 'roadmap', 'risk'
]);

const availableModules = [
  { id: 'basics', title: '企业工商背景', code: 'REGISTRIES', desc: '检索商会注册流水、成立年限与股东合规性。' },
  { id: 'financials', title: '财务与采购规模', code: 'FINANCIALS', desc: '核算年营业额规模、商业授信评级及授信等级。' },
  { id: 'logistics', title: '供应链与报关物流', code: 'SUPPLY CHAIN', desc: '提取海关提单记录、常用集装箱装箱习惯及物流痛点。' },
  { id: 'decision_chain', title: '采购决策链人脉', code: 'DECISION CHAIN', desc: '透视关键决策人的岗位（CEO/技术总监）及联络概率。' },
  { id: 'competitors', title: '本地竞争对手分析', code: 'COMPETITORS', desc: '扫描买家在本地主要采用哪家 PVC/低端水容器进行组装。' },
  { id: 'pain_points', title: '核心痛点与性能诉求', code: 'PAIN POINTS', desc: '提取冬季低温环境抗冻、CE认证、起订量卡点细节。' },
  { id: 'fit', title: '合作契合度深度建模', code: 'FIT MODEL', desc: '比对我方优势产品与资质，评估契合距离得分。' },
  { id: 'gtm', title: 'GTM 推进战术', code: 'GTM TACTICS', desc: '制定地缘阶梯折扣、蓝图发送以及货代比价比率比对。' },
  { id: 'roadmap', title: '执行清单路线图', code: 'ROADMAP', desc: '拟定周一、周三的具体邮件与协同派发拜访日程。' },
  { id: 'risk', title: '地缘风险与地差测算', code: 'RISK RATINGS', desc: '评估当地汇率浮动、港口拥堵及代理商分销风险。' }
];

const toggleAllModules = () => {
  if (selectedModules.value.length === 10) {
    selectedModules.value = [];
  } else {
    selectedModules.value = availableModules.map(m => m.id);
  }
};

const toggleModule = (modId) => {
  const index = selectedModules.value.indexOf(modId);
  if (index !== -1) {
    selectedModules.value.splice(index, 1);
  } else {
    selectedModules.value.push(modId);
  }
};

// Step 4 states: Report compiler simulation
const isGeneratingReport = ref(false);
const generationProgress = ref(0);
const generationStep = ref('');
const analysisReportGenerated = ref(false);
const activeReportTab = ref('markdown');
const generatedReportData = ref({ markdown: '', html: '', json: {} });

const runStepperAnalysis = () => {
  if (selectedModules.value.length === 0) {
    alert('请至少在第二步选择 1 个分析模块！');
    return;
  }
  isGeneratingReport.value = true;
  generationProgress.value = 0;
  generationStep.value = '正在触发多网关模拟抓取网页数据...';
  
  const steps = [
    { p: 25, s: '网页抓取完成，正在交叉检索商会与报备报关单...' },
    { p: 50, s: '报关单分析通过，正在整合我方公司全局档案竞争力...' },
    { p: 75, s: '正在编排多 Agent（SPI/开发信/法务）交叉提炼与报告编译...' },
    { p: 100, s: '报告编译完成，进入离线沙箱存盘机制!' }
  ];
  
  let currentIdx = 0;
  const timer = setInterval(() => {
    if (currentIdx < steps.length) {
      generationProgress.value = steps[currentIdx].p;
      generationStep.value = steps[currentIdx].s;
      currentIdx++;
    } else {
      clearInterval(timer);
      isGeneratingReport.value = false;
      analysisReportGenerated.value = true;
      compileSPIReportOutputs();
      alert(`「大模型分析就绪」已成功生成针对 [${clientForm.value.name}] 的高保真 SPI 格式背景调研报告！包含已选 ${selectedModules.value.length} 个调研模块！`);
    }
  }, 400);
};

const compileSPIReportOutputs = () => {
  const cName = clientForm.value.name;
  const cUrl = clientForm.value.url;
  const cInd = clientForm.value.industry === 'parts' ? '汽车配件与特种冷却' : (clientForm.value.industry === 'lights' ? '工业户外LED照明' : '柔性储水与农业蓄水');
  
  const markdownText = `# SPI 风格客户深度背景背调报告 | ${cName}
*报告性质: SPI Delivery System | 检索距离: 0.115 (极高置信) | 生成时间: 2026-05-31*

---

## 1. 目标客商工商背景 (Registries & Basics)
* **目标客商**: ${cName} (登记 URL: ${cUrl})
* **经营资质**: 该客商属于当地核心采购代理商，深耕 [${cInd}] 领域。 
* **信用等级**: AI 综合授信评估为 Grade AA+，违约概率极低。 ` + "`[Source: Local Chamber registries]`" + `

---

## 2. 核心痛点与性能诉求 (Pain Points & Spec Demands)
* **核心诉求**: 客商高度关注产品在严苛条件下的极限物理性能与无渗漏。 ` + "`[Cross-Verified: Technical Forums & RFC]`" + `
* **痛点说明**: 鉴于地缘限制，起订量折扣 (MOQ) 及地道的中英文测试报告是打消其最终付款决策的核心顾虑。 ` + "`[Info Gap: 需下周确认其具体的阶梯付款账期]`" + `

---

## 3. 合作契合度深度建模 (Collaboration Fit & Gap Analysis)
* **契合状态**: **高度契合**
* **我方优势匹配**: AI 已自动匹配并获取了我方公司 [${props.ourCompanyInfo.chineseName}] 的主营核心优势，我方的 [${props.ourCompanyInfo.coreAdvantages}] 竞争壁垒与持有的 [${props.ourCompanyInfo.certifications}] 资质认证完全覆盖了买家对极限防爆、FDA食品安全级水容器的品控要求。

---

## 4. 定制行动路线图 (GTM Action Roadmap)
* [ ] **GTM 第一步**：周一由业务代表发送结合了我方资质的多语言回复开发信草案；
* [ ] **GTM 第二步**：提供符合其官网要求的 CAD 设计参数与我方出厂检测说明书；
* [ ] **GTM 第三步**：锁定 $180 ~ $220 CIF 的阶梯起订折扣，打破决策瓶颈。`;

  const htmlText = `<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: -apple-system, sans-serif; padding: 20px; color: #2c3e50; line-height: 1.6; background: rgba(255,255,255,0.7); }
    h1 { color: #627254; font-size: 16px; border-bottom: 2px solid #627254; padding-bottom: 8px; }
    .badge { display: inline-block; font-size: 8px; background: #627254; color: white; padding: 2px 6px; border-radius: 4px; font-weight: bold; }
    .item { background: rgba(0,0,0,0.02); padding: 12px; border-radius: 10px; margin-bottom: 12px; font-size: 11px; border: 1px solid rgba(0,0,0,0.04); }
    strong { color: #111; }
  </style>
</head>
<body>
  <h1>🇹🇭 ${cName} 可行性背调 HTML 报告</h1>
  <div class="item">
    <strong>企业工商注册名录</strong>: 已验证 ${cUrl}，主营性质对标 [${cInd}]，为中大型合规进口商。 <span class="badge">Source: SQLite secure db</span>
  </div>
  <div class="item">
    <strong>我方合作契合度分析</strong>: 客商对高端储水阀与隔温防冻防爆要求高。我方 [${props.ourCompanyInfo.chineseName}] 提供的 [${props.ourCompanyInfo.coreAdvantages}] 专利技术以及拥有的 [${props.ourCompanyInfo.certifications}] 证书，契合得分 94.8%！ <span class="badge">Verified by SPI model</span>
  </div>
  <div class="item">
    <strong>推进战术</strong>: 以预设术语 [${props.ourCompanyInfo.presetIncoterms}] 给与对方高透明阶梯报价，随信附寄正式出厂报告。
  </div>
</body>
</html>`;

  generatedReportData.value = {
    markdown: markdownText,
    html: htmlText,
    json: {
      client: cName,
      website: cUrl,
      associatedLeadId: associatedLeadId.value,
      industrySelected: cInd,
      activeModules: selectedModules.value,
      matchingScore: 94.8,
      ourMatchingCompetencies: props.ourCompanyInfo.coreAdvantages,
      dateGenerated: new Date().toISOString().substring(0, 10)
    }
  };
};

const syncGeneratedReport = () => {
  let targetLead = null;
  let updatedLeads = [...props.leads];
  
  if (associatedLeadId.value !== 'new') {
    targetLead = props.leads.find(l => l.id === Number(associatedLeadId.value));
  }
  
  if (!targetLead) {
    // Create new custom lead first in global array
    const newId = props.leads.length + 1;
    targetLead = {
      id: newId,
      name: clientForm.value.name,
      contact: 'Procurement Director',
      country: '海外客商',
      flag: '🌐',
      score: 85,
      category: clientForm.value.industry === 'parts' ? 'parts' : 'lights',
      stage: 'potential',
      tags: ['大模型分析', '新录入'],
      routingPath: '智能 CRM 自识别流转',
      rawMessage: `手工分析录入客户。官网: ${clientForm.value.url}。主营: ${cIndText(clientForm.value.industry)}。目的: ${cGoalText(clientForm.value.goal)}。关注点: ${clientForm.value.concerns}`
    };
    updatedLeads.push(targetLead);
  }
  
  // Update leads deepReport property to store this report
  updatedLeads = updatedLeads.map(l => {
    if (l.id === targetLead.id) {
      return {
        ...l,
        deepReport: {
          type: 'Markdown',
          filename: `${targetLead.name.replace(/\s+/g, '_')}_SPI_Analysis.md`,
          content: generatedReportData.value.markdown,
          date: new Date().toISOString().substring(0, 10)
        }
      };
    }
    return l;
  });
  
  emit('update:leads', updatedLeads);
  alert(`「跨页面数据融合成功」：针对客商 [${targetLead.name}] 的 SPI 风格深度分析报告已成功写入本地 SQLite 加密数据管线！您在左侧切换至「客户管理」->「客户画像工作台」-> 底部「分析报告」Tab 即可立即看到完整的高保真渲染！`);
};

const cIndText = (ind) => {
  const map = { parts: '汽配冷却', lights: '户外照明', agri: '山地灌溉', storage: '特种储水' };
  return map[ind] || ind;
};

const cGoalText = (goal) => {
  const map = { development: '客户开发', credit: '履约风控', routing: '代理协同', legal: '合规审查' };
  return map[goal] || goal;
};

const copyConfig = () => {
  navigator.clipboard.writeText(JSON.stringify(generatedReportData.value.json, null, 2));
  alert('报告 JSON 源数据已成功复制到您的系统剪贴板！');
};

const downloadConfig = () => {
  const blob = new Blob([JSON.stringify(generatedReportData.value.json, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${clientForm.value.name.replace(/\s+/g, '_')}_SPI_Analysis.json`;
  a.click();
  URL.revokeObjectURL(url);
  alert('报告 JSON 配置参数已成功触发下载并保存至您的本地电脑！');
};


// ----------------------------------------------------
// TOOL 3: Simulated Folder scanner logic (文件智能识别与连通)
// ----------------------------------------------------
const externalReportDir = '/Users/ky/Desktop/汽配客户/deep_analysis_reports_v2';
const scanMessage = ref('');
const scannedExternalFiles = ref([]);

const normalizeReportBase = (filename) => filename
  .replace(/\.(md|html)$/i, '')
  .replace(/-analysis$/i, '');

const inferClientNameFromFilename = (filename) => {
  return normalizeReportBase(filename)
    .split('-')
    .filter(Boolean)
    .map(part => part.length <= 4 && /\d/.test(part) ? part.toUpperCase() : part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
};

const scanExternalReportDirectory = async () => {
  scanMessage.value = '正在扫描汽配客户报告目录...';
  try {
    if (!window.electronAPI?.scanDirectory) {
      scanMessage.value = '当前为浏览器预览模式，无法直接读取本机汽配报告目录；Electron 桌面版可自动扫描。';
      return;
    }

    const result = await window.electronAPI.scanDirectory(externalReportDir);
    if (!result.success) throw new Error(result.error || '扫描失败');

    const reportFiles = result.files
      .filter(file => /\.(md|html)$/i.test(file.name) && !/^(summary_report|daily_summary_template|Email修复报告)/i.test(file.name))
      .sort((a, b) => a.name.localeCompare(b.name));

    const grouped = reportFiles.reduce((acc, file) => {
      const base = normalizeReportBase(file.name);
      if (!acc[base]) acc[base] = [];
      acc[base].push(file);
      return acc;
    }, {});

    scannedExternalFiles.value = Object.entries(grouped).map(([base, files]) => {
      const preferred = files.find(file => /\.md$/i.test(file.name)) || files[0];
      const type = /\.md$/i.test(preferred.name) ? 'Markdown' : 'HTML';
      return {
        filename: preferred.name,
        type,
        targetClientName: inferClientNameFromFilename(preferred.name),
        filePath: `${externalReportDir}/${preferred.name}`,
        associated: props.leads.some(lead => isLikelySameClient(lead.name, inferClientNameFromFilename(preferred.name))),
        source: 'local'
      };
    });

    scanMessage.value = `已识别 ${scannedExternalFiles.value.length} 份客户报告，优先采用 Markdown，同名 HTML 作为备选。`;
  } catch (e) {
    console.error(e);
    scanMessage.value = `扫描失败：${e.message}`;
  }
};

const normalizeClientName = (name) => String(name || '')
  .toLowerCase()
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .replace(/[^a-z0-9]+/g, '');

const isLikelySameClient = (a, b) => {
  const left = normalizeClientName(a);
  const right = normalizeClientName(b);
  return left && right && (left === right || left.includes(right) || right.includes(left));
};

const syncExternalFile = async (fileObj) => {
  try {
    let content = '';
    if (fileObj.source === 'local') {
      const result = await window.electronAPI.readFile(fileObj.filePath);
      if (!result.success) throw new Error(result.error || '读取失败');
      content = result.content;
    } else {
      const response = await fetch(fileObj.filePath);
      if (!response.ok) throw new Error('File not found');
      content = await response.text();
    }
    
    // Find matched lead inside leads prop
    const targetLead = props.leads.find(l => isLikelySameClient(l.name, fileObj.targetClientName));
    if (targetLead) {
      const updatedLeads = props.leads.map(l => {
        if (l.id === targetLead.id) {
          return {
            ...l,
            deepReport: {
              type: fileObj.type,
              filename: fileObj.filename,
              content: content,
              date: new Date().toISOString().substring(0, 10)
            }
          };
        }
        return l;
      });
      emit('update:leads', updatedLeads);
      fileObj.associated = true;
      alert(`「外部报告智能识别连通成功」：系统已只读读取 [${fileObj.filename}]，并绑定到客户 [${targetLead.name}] 的分析报告页。源文件和原有客户数据均未被删除或覆盖。`);
    } else {
      alert(`在现有公海客户名录中未匹配到名为 [${fileObj.targetClientName}] 的客户，请检查文件名或先录入该客户基本信息！`);
    }
  } catch (e) {
    console.error(e);
    alert(`读取本地外部报告文件 [${fileObj.filename}] 失败，请确认该文件已妥善存放在 /public/external_reports/ 文件夹中！`);
  }
};

onMounted(() => {
  scanExternalReportDirectory();
});
</script>

<style scoped>
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(6px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.animate-fadeIn {
  animation: fadeIn 0.4s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}

/* line clamp utility for premium cards */
.truncate-3-lines {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
