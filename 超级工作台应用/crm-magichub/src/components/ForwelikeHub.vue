<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10 select-text animate-fadeIn">
    <!-- Header -->
    <div class="pb-4 border-b border-white/20 select-none flex justify-between items-center">
      <div>
        <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2">
          <span class="w-8 h-8 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 text-white flex items-center justify-center">
            🎓
          </span>
          Forwelike 专区
        </h2>
        <p class="text-xs text-zen-gray mt-1">集成 Forwelike 知识讲堂实战教案与新一代 AI 智能营销工具套件，为您的出海业务赋能。</p>
      </div>

      <!-- Tab Switcher -->
      <div class="flex bg-white/45 border border-white/60 p-1 rounded-xl shadow-sm text-xs gap-1 select-none">
        <button
          @click="currentTab = 'marketing'; activeTool = null"
          :class="currentTab === 'marketing' ? 'bg-zen-ink text-white font-bold' : 'text-zen-gray hover:text-zen-ink'"
          class="px-4 py-1.5 rounded-lg transition-all outline-none"
        >
          智能营销
        </button>
        <button
          @click="currentTab = 'learning'; activeCourse = null"
          :class="currentTab === 'learning' ? 'bg-zen-ink text-white font-bold' : 'text-zen-gray hover:text-zen-ink'"
          class="px-4 py-1.5 rounded-lg transition-all outline-none"
        >
          Forwelike 学习
        </button>
      </div>
    </div>

    <!-- ========================================== -->
    <!-- TAB 1: SMART MARKETING PANEL               -->
    <!-- ========================================== -->
    <div v-if="currentTab === 'marketing'" class="space-y-6">
      
      <!-- Marketing Hub Dashboard View -->
      <div v-if="activeTool === null" class="space-y-6 animate-fadeIn">
        <!-- Hero section -->
        <div class="relative rounded-3xl p-6 md:p-8 overflow-hidden bg-gradient-to-r from-slate-900 to-indigo-950 text-white shadow-xl select-none">
          <div class="relative z-10 max-w-2xl space-y-2">
            <span class="px-2.5 py-1 bg-indigo-500/20 border border-indigo-500/30 rounded-full text-indigo-300 text-[10px] font-black tracking-wider uppercase">
              智能营销中心
            </span>
            <h2 class="text-xl md:text-2xl font-black tracking-tight leading-tight">使用 AI 工具套件及雷达数据赋能品牌出海</h2>
            <p class="text-gray-300 text-xs leading-relaxed font-normal">
              全场景打通客户对话收集、开发信群发、社媒精准挖客、意向画像分析以及搜索引擎收录权重，助您高效建立全球买家渠道网络。
            </p>
          </div>
          <div class="absolute -top-12 -right-12 w-64 h-64 bg-indigo-600/15 rounded-full blur-3xl" />
          <div class="absolute -bottom-16 -left-16 w-80 h-80 bg-blue-600/10 rounded-full blur-3xl" />
        </div>

        <!-- Marketing Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 select-none">
          <div
            v-for="tool in marketingTools"
            :key="tool.id"
            @click="selectTool(tool.id)"
            class="group flex flex-col justify-between p-5 rounded-2xl border border-white/50 bg-white/60 hover:bg-white/90 shadow-sm hover:shadow-md hover:scale-[1.01] transition-all duration-300 cursor-pointer apple-glass"
          >
            <div class="space-y-4">
              <div class="flex items-center justify-between">
                <div class="p-3 bg-white rounded-xl shadow-sm" :class="tool.iconColor">
                  <!-- Render SVG Icon -->
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" :d="tool.iconPath" />
                  </svg>
                </div>
                <span class="px-2 py-0.5 bg-white/80 backdrop-blur text-gray-500 border border-gray-100 rounded text-[9px] font-bold">
                  {{ tool.badge }}
                </span>
              </div>
              
              <div>
                <h3 class="text-sm font-bold text-gray-800 flex items-center gap-1 group-hover:text-indigo-600 transition-colors">
                  {{ tool.title }}
                  <span class="opacity-0 group-hover:opacity-100 transition-opacity ml-1">→</span>
                </h3>
                <p class="text-xs text-zen-gray mt-1.5 leading-relaxed">
                  {{ tool.desc }}
                </p>
              </div>
            </div>
            
            <div class="border-t border-gray-200/20 pt-3.5 mt-4 text-[10px] text-zen-gray font-medium">
              {{ tool.stats }}
            </div>
          </div>
        </div>
      </div>

      <!-- View: AI Chat Transcripts (AI 对话管理) -->
      <div v-else-if="activeTool === 'marketing-aichat'" class="space-y-6 animate-fadeIn">
        <div class="flex items-center gap-4 select-none pb-2 border-b border-white/10">
          <button @click="activeTool = null" class="px-3 py-1.5 bg-white/50 hover:bg-white border border-white/60 rounded-xl text-xs text-zen-ink font-semibold flex items-center gap-1">
            ← 返回营销中心
          </button>
          <h3 class="text-base font-bold">AI 对话数据管理</h3>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          <!-- Session List (Left 5) -->
          <div class="lg:col-span-5 bg-white/60 border border-white/50 rounded-2xl p-4 shadow-sm flex flex-col h-[550px] overflow-hidden apple-glass">
            <h4 class="text-xs font-bold text-zen-gray mb-3">实时访客对话列表 (Google Web Widget)</h4>
            <div class="overflow-y-auto space-y-2 flex-1 pr-1">
              <div
                v-for="session in mockSessions"
                :key="session.id"
                @click="selectedSession = session"
                :class="selectedSession?.id === session.id ? 'bg-white/80 border-indigo-300' : 'bg-white/30 border-transparent hover:bg-white/50'"
                class="p-3 rounded-xl border transition-all cursor-pointer flex justify-between items-start gap-2 shadow-sm"
              >
                <div class="min-w-0 flex-1 space-y-1">
                  <div class="flex items-center gap-1.5">
                    <span class="text-xs font-bold text-zen-ink">{{ session.customerName || '匿名访客' }}</span>
                    <span class="text-[9px] px-1 bg-black/[0.04] text-zen-gray font-mono">{{ session.country }}</span>
                  </div>
                  <p class="text-[10px] text-zen-gray truncate">{{ session.lastMessage }}</p>
                </div>
                <div class="text-right shrink-0">
                  <span class="text-[8px] text-zen-gray font-mono block">{{ session.time }}</span>
                  <span class="text-[9px] font-bold px-1.5 py-0.2 rounded mt-1 inline-block" :class="session.isAcquired ? 'bg-emerald-50 text-emerald-600' : 'bg-indigo-50 text-indigo-600'">
                    {{ session.isAcquired ? '已建档' : '跟进中' }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Active Chat View (Right 7) -->
          <div class="lg:col-span-7 bg-white/60 border border-white/50 rounded-2xl p-5 shadow-sm flex flex-col h-[550px] overflow-hidden apple-glass">
            <div v-if="selectedSession" class="flex flex-col h-full">
              <!-- Visitor KP Info Header -->
              <div class="pb-3 border-b border-black/[0.05] flex justify-between items-start">
                <div>
                  <h4 class="text-sm font-bold text-zen-ink">{{ selectedSession.customerName || '访客信息详情' }}</h4>
                  <p class="text-[10px] text-zen-gray mt-0.5 font-mono">
                    IP: {{ selectedSession.ip }} · 客户端: {{ selectedSession.device }}
                  </p>
                </div>
                <!-- Action: Import as Lead -->
                <button
                  @click="importChatAsLead(selectedSession)"
                  :disabled="selectedSession.isAcquired"
                  class="px-3.5 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-[10px] font-bold shadow-sm transition-all disabled:opacity-50"
                >
                  {{ selectedSession.isAcquired ? '✓ 已保存到客户' : '＋ 一键导入CRM' }}
                </button>
              </div>

              <!-- Message History transcripts -->
              <div class="flex-1 overflow-y-auto my-4 space-y-3.5 pr-1 text-xs">
                <div
                  v-for="(msg, idx) in selectedSession.messages"
                  :key="idx"
                  :class="msg.sender === 'visitor' ? 'justify-end' : 'justify-start'"
                  class="flex items-start gap-2.5"
                >
                  <div v-if="msg.sender === 'ai'" class="w-7 h-7 rounded-lg bg-indigo-600 text-white flex items-center justify-center shrink-0">
                    🤖
                  </div>
                  <div
                    :class="msg.sender === 'visitor' ? 'bg-indigo-50 border-indigo-100 text-zen-ink rounded-br-none ml-10' : 'bg-white border-gray-150 text-zen-ink rounded-bl-none mr-10'"
                    class="p-3 rounded-2xl border leading-relaxed shadow-sm font-normal"
                  >
                    {{ msg.content }}
                    <span class="block text-[8px] text-zen-gray text-right mt-1.5 font-mono">{{ msg.time }}</span>
                  </div>
                  <div v-if="msg.sender === 'visitor'" class="w-7 h-7 rounded-lg bg-slate-900 text-white flex items-center justify-center shrink-0">
                    👤
                  </div>
                </div>
              </div>

              <!-- Customer Edit panel -->
              <div class="pt-3 border-t border-black/[0.05] grid grid-cols-3 gap-2.5 text-xs">
                <div class="space-y-1">
                  <label class="block text-[10px] text-zen-gray font-bold">客户姓名</label>
                  <input v-model="selectedSession.customerName" type="text" class="w-full bg-white border border-gray-200 rounded-lg px-2 py-1 px-3" />
                </div>
                <div class="space-y-1">
                  <label class="block text-[10px] text-zen-gray font-bold">电子邮箱</label>
                  <input v-model="selectedSession.email" type="text" class="w-full bg-white border border-gray-200 rounded-lg px-2 py-1 px-3" />
                </div>
                <div class="space-y-1">
                  <label class="block text-[10px] text-zen-gray font-bold">联系电话</label>
                  <input v-model="selectedSession.phone" type="text" class="w-full bg-white border border-gray-200 rounded-lg px-2 py-1 px-3" />
                </div>
              </div>
            </div>
            <div v-else class="flex flex-col items-center justify-center h-full text-zen-gray text-center select-none space-y-2">
              <span class="text-4xl">💬</span>
              <p class="text-xs">请在左侧列表中点击选择一条访客对话记录</p>
            </div>
          </div>
        </div>
      </div>

      <!-- View: Reused Email Marketing (智能邮件营销) -->
      <div v-else-if="activeTool === 'marketing-email'" class="space-y-6 animate-fadeIn">
        <div class="flex items-center gap-4 select-none pb-2 border-b border-white/10">
          <button @click="activeTool = null" class="px-3 py-1.5 bg-white/50 hover:bg-white border border-white/60 rounded-xl text-xs text-zen-ink font-semibold flex items-center gap-1">
            ← 返回营销中心
          </button>
          <h3 class="text-base font-bold">智能邮件营销中心</h3>
        </div>
        <!-- Load the main SmartMarketing component -->
        <SmartMarketing :leads="leads" :ourCompanyInfo="ourCompanyInfo" />
      </div>

      <!-- View: AI Lead Search (智能客户搜索) -->
      <div v-else-if="activeTool === 'marketing-search'" class="space-y-6 animate-fadeIn">
        <div class="flex items-center gap-4 select-none pb-2 border-b border-white/10">
          <button @click="activeTool = null" class="px-3 py-1.5 bg-white/50 hover:bg-white border border-white/60 rounded-xl text-xs text-zen-ink font-semibold flex items-center gap-1">
            ← 返回营销中心
          </button>
          <h3 class="text-base font-bold">智能客户搜索引擎</h3>
        </div>

        <!-- Search Bar -->
        <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4">
          <div class="flex gap-3">
            <input
              type="text"
              v-model="searchQuery"
              placeholder="输入行业、国家与产品痛点需求检索潜在客商 (例如: 寻找采购户外特种水箱的德国买家)"
              class="flex-1 bg-white/40 border border-white/60 rounded-xl px-4 py-2.5 text-xs text-zen-ink outline-none focus:bg-white focus:border-zen-green transition-all"
            />
            <button
              @click="runLeadSearch"
              :disabled="isSearching"
              class="px-5 py-2.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-xs font-bold transition-all shadow-md"
            >
              {{ isSearching ? '智能雷达探测中...' : '启动 AI 深度挖掘' }}
            </button>
          </div>
          
          <!-- simulated progress -->
          <div v-if="isSearching" class="space-y-1.5 select-none text-[10px] text-zen-green font-mono">
            <div class="flex justify-between">
              <span>{{ searchProgressText }}</span>
              <span>{{ searchProgress }}%</span>
            </div>
            <div class="h-1 w-full bg-black/5 rounded-full overflow-hidden">
              <div class="bg-zen-green h-full transition-all duration-300" :style="{ width: searchProgress + '%' }"></div>
            </div>
          </div>
        </div>

        <!-- Search Results -->
        <div v-if="searchComplete" class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          <!-- Results Table (Left 7) -->
          <div class="lg:col-span-7 bg-white/60 border border-white/50 rounded-2xl p-5 shadow-sm apple-glass overflow-x-auto">
            <h4 class="text-xs font-bold text-zen-gray mb-3.5">探测到的海关关单与社媒关联客商 (Matching Leads)</h4>
            <table class="w-full text-xs text-left border-collapse">
              <thead>
                <tr class="border-b border-black/[0.05] text-[10px] text-zen-gray font-bold">
                  <th class="py-2.5">企业名称</th>
                  <th class="py-2.5">国家/地区</th>
                  <th class="py-2.5">匹配度</th>
                  <th class="py-2.5">主要采购项</th>
                  <th class="py-2.5 text-center">状态</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-black/[0.02]">
                <tr
                  v-for="lead in searchLeads"
                  :key="lead.id"
                  @click="selectedLead = lead"
                  :class="selectedLead?.id === lead.id ? 'bg-white/40 font-bold' : 'hover:bg-white/20'"
                  class="cursor-pointer transition-colors"
                >
                  <td class="py-3 font-semibold text-zen-ink">
                    {{ lead.company }}
                    <span class="block text-[9px] text-zen-gray font-mono mt-0.5 font-normal">{{ lead.contact_name }} ({{ lead.title }})</span>
                  </td>
                  <td class="py-3 text-zen-gray">{{ lead.country }}</td>
                  <td class="py-3 font-mono font-bold text-zen-green">{{ lead.score }}%</td>
                  <td class="py-3 text-zen-gray truncate max-w-[120px]">{{ lead.products }}</td>
                  <td class="py-3 text-center">
                    <span class="px-2 py-0.5 rounded-full text-[9px] font-bold" :class="lead.saved ? 'bg-emerald-50 text-emerald-600' : 'bg-gray-100 text-gray-500'">
                      {{ lead.saved ? '已存档' : '待导入' }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Lead Detail view drawer (Right 5) -->
          <div class="lg:col-span-5 bg-white/60 border border-white/50 rounded-2xl p-5 shadow-sm apple-glass flex flex-col justify-between min-h-[480px]">
            <div v-if="selectedLead" class="space-y-4 text-xs">
              <div class="pb-3 border-b border-black/[0.05] flex justify-between items-start">
                <div>
                  <h4 class="text-sm font-bold text-zen-ink">{{ selectedLead.company }}</h4>
                  <a :href="'http://' + selectedLead.website" target="_blank" class="text-[10px] text-indigo-600 hover:underline mt-0.5 block font-mono">
                    🔗 {{ selectedLead.website }}
                  </a>
                </div>
                <button
                  @click="importLeadToCrm(selectedLead)"
                  :disabled="selectedLead.saved"
                  class="px-3.5 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-[10px] font-bold shadow-sm"
                >
                  {{ selectedLead.saved ? '✓ 已保存' : '一键导入 CRM' }}
                </button>
              </div>

              <!-- Stepper details tabs -->
              <div class="space-y-3">
                <div>
                  <span class="text-[10px] text-zen-gray font-bold block uppercase tracking-wider mb-1">🎯 采购背景画像:</span>
                  <p class="text-zen-ink leading-relaxed bg-white/40 p-2.5 rounded-xl border border-white/60">
                    {{ selectedLead.description }}
                  </p>
                </div>

                <!-- KP Decision Makers -->
                <div>
                  <span class="text-[10px] text-zen-gray font-bold block uppercase tracking-wider mb-1">👤 关键决策人 (KP):</span>
                  <div class="space-y-1.5">
                    <div class="bg-white/40 border border-white/60 p-2 rounded-xl flex justify-between items-center">
                      <div>
                        <span class="font-bold text-zen-ink">{{ selectedLead.contact_name }}</span>
                        <span class="text-[9px] text-zen-gray ml-1.5 font-mono">{{ selectedLead.title }}</span>
                      </div>
                      <span class="text-[9px] font-bold px-1.5 bg-rose-50 text-rose-500 rounded">核心影响人</span>
                    </div>
                    <div class="bg-white/40 border border-white/60 p-2 rounded-xl flex justify-between items-center">
                      <div>
                        <span class="font-bold text-zen-ink">Alexander Wood</span>
                        <span class="text-[9px] text-zen-gray ml-1.5 font-mono">Chief Engineer (技术总监)</span>
                      </div>
                      <span class="text-[9px] font-bold px-1.5 bg-amber-50 text-amber-500 rounded">技术评估者</span>
                    </div>
                  </div>
                </div>

                <!-- Outreach Email Draft -->
                <div>
                  <div class="flex justify-between items-center mb-1">
                    <span class="text-[10px] text-zen-gray font-bold uppercase tracking-wider">📧 AI 生成开发信推荐:</span>
                    <button @click="copyOutreachDraft(selectedLead)" class="text-[9px] text-indigo-600 hover:underline">复制开发信正文</button>
                  </div>
                  <div class="bg-slate-900 text-slate-100 p-3 rounded-xl font-mono text-[9px] leading-relaxed max-h-40 overflow-y-auto select-text">
                    <strong>Subject:</strong> {{ selectedLead.outreachSubject }}<br/><br/>
                    {{ selectedLead.outreachBody }}
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="flex flex-col items-center justify-center h-full text-zen-gray text-center select-none space-y-2 py-10">
              <span class="text-3xl">🔍</span>
              <p class="text-xs">请在左侧列表中点击选择一个客商进行详细背调画像</p>
            </div>
          </div>
        </div>
      </div>

      <!-- View: Reused SEO/GEO Diagnostics (智能 SEO & GEO 诊断) -->
      <div v-else-if="activeTool === 'marketing-seo' || activeTool === 'marketing-geo'" class="space-y-6 animate-fadeIn">
        <div class="flex items-center gap-4 select-none pb-2 border-b border-white/10">
          <button @click="activeTool = null" class="px-3 py-1.5 bg-white/50 hover:bg-white border border-white/60 rounded-xl text-xs text-zen-ink font-semibold flex items-center gap-1">
            ← 返回营销中心
          </button>
          <h3 class="text-base font-bold">{{ activeTool === 'marketing-seo' ? '智能 SEO 排名霸屏引擎' : '新一代 GEO 流量先锋诊断' }}</h3>
        </div>
        <!-- Load the SmartTools SEO component directly -->
        <SmartTools :ourCompanyInfo="ourCompanyInfo" :leads="leads" />
      </div>

      <!-- View: World Marketing Calendar (世界营销日历) -->
      <div v-else-if="activeTool === 'marketing-calendar'" class="space-y-6 animate-fadeIn">
        <div class="flex items-center gap-4 select-none pb-2 border-b border-white/10">
          <button @click="activeTool = null" class="px-3 py-1.5 bg-white/50 hover:bg-white border border-white/60 rounded-xl text-xs text-zen-ink font-semibold flex items-center gap-1">
            ← 返回营销中心
          </button>
          <h3 class="text-base font-bold">世界营销与节点推广日历</h3>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
          <!-- Calendar Month grid list (Left 6) -->
          <div class="lg:col-span-6 bg-white/60 border border-white/50 rounded-2xl p-5 shadow-sm apple-glass flex flex-col h-[520px]">
            <div class="flex justify-between items-center mb-4 select-none">
              <h4 class="text-xs font-bold text-zen-gray">2026年营销热点月份导航</h4>
              <!-- Month selection dropdown -->
              <select v-model="selectedMonth" class="bg-white border border-gray-200 text-xs px-2 py-1 rounded-lg">
                <option v-for="m in 12" :key="m" :value="m">{{ m }}月</option>
              </select>
            </div>
            
            <div class="overflow-y-auto space-y-2 flex-1 pr-1">
              <div
                v-for="h in holidays.filter(x => x.month === selectedMonth)"
                :key="h.id"
                @click="selectedHoliday = h"
                :class="selectedHoliday?.id === h.id ? 'bg-white/80 border-indigo-300' : 'bg-white/30 border-transparent hover:bg-white/50'"
                class="p-3.5 rounded-xl border transition-all cursor-pointer shadow-sm"
              >
                <div class="flex justify-between items-start">
                  <div>
                    <span class="text-xs font-bold text-zen-ink">{{ h.name }}</span>
                    <span class="text-[9px] text-zen-gray font-mono block mt-0.5">{{ h.date }} · {{ h.enName }}</span>
                  </div>
                  <span class="px-2 py-0.5 rounded-full text-[9px] font-bold" :class="h.level === 'High' ? 'bg-rose-50 text-rose-600' : 'bg-indigo-50 text-indigo-600'">
                    {{ h.level === 'High' ? '特高热度' : '中度热度' }}
                  </span>
                </div>
                <div class="mt-2.5 flex flex-wrap gap-1">
                  <span v-for="c in h.countries.slice(0, 4)" :key="c" class="px-1.5 py-0.2 bg-black/[0.04] text-[8px] text-zen-gray font-semibold rounded">
                    {{ c }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Month Holiday AI write detailed box (Right 6) -->
          <div class="lg:col-span-6 bg-white/60 border border-white/50 rounded-2xl p-5 shadow-sm apple-glass flex flex-col justify-between min-h-[520px]">
            <div v-if="selectedHoliday" class="space-y-4 text-xs">
              <div class="pb-3 border-b border-black/[0.05]">
                <span class="px-2.5 py-0.5 bg-rose-50 border border-rose-100 rounded text-rose-600 text-[10px] font-bold">
                  {{ selectedHoliday.date }}
                </span>
                <h4 class="text-sm font-bold text-zen-ink mt-2">{{ selectedHoliday.name }} ({{ selectedHoliday.enName }})</h4>
                <p class="text-[10px] text-zen-gray mt-0.5">影响市场范围: {{ selectedHoliday.countries.join(', ') }}</p>
              </div>

              <div class="space-y-3">
                <div>
                  <span class="text-[10px] text-zen-gray font-bold block uppercase tracking-wider mb-1">🎁 推荐促销品类:</span>
                  <div class="flex flex-wrap gap-1.5">
                    <span v-for="cat in selectedHoliday.hotCategories" :key="cat" class="px-2 py-0.5 bg-emerald-50 border border-emerald-100 text-emerald-700 rounded-md font-bold text-[10px]">
                      {{ cat }}
                    </span>
                  </div>
                </div>

                <div>
                  <span class="text-[10px] text-zen-gray font-bold block uppercase tracking-wider mb-1">💡 节日获客企划方案:</span>
                  <p class="text-zen-ink bg-white/40 p-3 rounded-xl border border-white/60 leading-relaxed">
                    {{ selectedHoliday.marketingTip }}
                  </p>
                </div>

                <div>
                  <div class="flex justify-between items-center mb-1">
                    <span class="text-[10px] text-zen-gray font-bold uppercase tracking-wider">✍️ AI 节日开发信模板:</span>
                    <button @click="generateHolidayPlan(selectedHoliday)" class="text-[9px] text-indigo-600 hover:underline">一键保存至汇总库</button>
                  </div>
                  <div class="bg-slate-900 text-slate-100 p-3 rounded-xl font-mono text-[9px] leading-relaxed max-h-40 overflow-y-auto select-text">
                    {{ selectedHoliday.promptTemplate }}
                  </div>
                </div>
              </div>
            </div>
            <div v-else class="flex flex-col items-center justify-center h-full text-zen-gray text-center select-none space-y-2 py-10">
              <span class="text-3xl">📅</span>
              <p class="text-xs">请在左侧列表中点击选择一个营销节日查看企划详情</p>
            </div>
          </div>
        </div>
      </div>

      <!-- View: Marketing Plans list (营销方案汇总库) -->
      <div v-else-if="activeTool === 'marketing-plans'" class="space-y-6 animate-fadeIn">
        <div class="flex items-center gap-4 select-none pb-2 border-b border-white/10">
          <button @click="activeTool = null" class="px-3 py-1.5 bg-white/50 hover:bg-white border border-white/60 rounded-xl text-xs text-zen-ink font-semibold flex items-center gap-1">
            ← 返回营销中心
          </button>
          <h3 class="text-base font-bold">出海营销方案汇总库</h3>
        </div>

        <div class="bg-white/60 border border-white/50 rounded-2xl p-5 shadow-sm apple-glass min-h-[450px]">
          <div class="flex justify-between items-center mb-4 select-none">
            <h4 class="text-xs font-bold text-zen-gray">已保存方案列表 (MagicHub Storage)</h4>
            <button @click="clearAllPlans" class="text-[9px] text-red-500 hover:underline">清空方案库</button>
          </div>

          <div v-if="plans.length > 0" class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div v-for="plan in plans" :key="plan.id" class="p-4 rounded-xl bg-white border border-gray-200/60 shadow-sm flex flex-col justify-between space-y-3">
              <div class="space-y-2">
                <div class="flex justify-between items-start">
                  <span class="px-2 py-0.5 bg-indigo-50 border border-indigo-100 rounded text-indigo-600 font-bold text-[9px]">
                    {{ plan.channel }}
                  </span>
                  <span class="text-[9px] text-zen-gray font-mono">{{ plan.createdAt }}</span>
                </div>
                <h5 class="font-bold text-xs text-zen-ink">{{ plan.title }}</h5>
                <p class="text-[10px] text-zen-gray leading-relaxed">{{ plan.summary }}</p>
              </div>

              <div class="flex justify-between items-center border-t border-black/[0.04] pt-2 mt-2">
                <div class="flex gap-1">
                  <span v-for="t in plan.tags" :key="t" class="px-1.5 py-0.2 bg-black/[0.04] text-[8px] text-zen-gray font-semibold rounded">
                    #{{ t }}
                  </span>
                </div>
                <button @click="deletePlan(plan.id)" class="text-[9px] text-red-500 hover:underline">删除</button>
              </div>
            </div>
          </div>
          <div v-else class="flex flex-col items-center justify-center h-full text-zen-gray text-center select-none space-y-2 py-20">
            <span class="text-4xl">📂</span>
            <p class="text-xs">暂无已保存的营销企划方案</p>
            <p class="text-[10px] text-zen-gray/80">您可以在「世界营销日历」中选择节日方案一键保存到此处</p>
          </div>
        </div>
      </div>

    </div>

    <!-- ========================================== -->
    <!-- TAB 2: FORWELIKE LEARNING PANEL            -->
    <!-- ========================================== -->
    <div v-else-if="currentTab === 'learning'" class="space-y-6">
      
      <!-- Catalog Grid View -->
      <div v-if="!activeCourse" class="space-y-6 animate-fadeIn">
        <!-- Hero Header -->
        <div class="relative rounded-3xl p-6 md:p-8 overflow-hidden bg-gradient-to-r from-slate-950 to-indigo-950 text-white shadow-xl select-none">
          <div class="relative z-10 max-w-2xl space-y-2">
            <span class="px-2.5 py-1 bg-indigo-500/20 border border-indigo-500/30 rounded-full text-indigo-300 text-[10px] font-black tracking-wider uppercase flex items-center gap-1.5 w-fit">
              📖 Forwelike 知识讲堂
            </span>
            <h2 class="text-xl md:text-2xl font-black tracking-tight leading-tight">外贸出海实战课 · 课程列表</h2>
            <p class="text-gray-300 text-xs leading-relaxed font-normal">
              拒绝理论说教，只教可以直接复制的拿单功夫。汇集十六年外贸独立站运营、搜索引擎霸屏优化以及大客户谈判博弈的实战教案。
            </p>
          </div>
          
          <!-- Background blobs -->
          <div class="absolute -top-12 -right-12 w-64 h-64 bg-indigo-600/15 rounded-full blur-3xl" />
          <div class="absolute -bottom-16 -left-16 w-80 h-80 bg-blue-600/10 rounded-full blur-3xl" />
        </div>

        <!-- Grid of Tutorial Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 select-none">
          <div 
            v-for="item in courses"
            :key="item.id"
            @click="handleOpenCourse(item)"
            class="group flex flex-col justify-between p-5 rounded-2xl border border-gray-200/50 bg-white hover:bg-white/80 shadow-sm hover:shadow-md hover:scale-[1.01] transition-all duration-300 cursor-pointer apple-glass"
          >
            <div class="space-y-4">
              <div class="flex items-center justify-between">
                <div class="p-3 bg-[#F4F6F5] rounded-xl shadow-sm text-indigo-600">
                  <span class="text-lg">📚</span>
                </div>
                <span class="px-2 py-0.5 bg-indigo-50 border border-indigo-100 text-indigo-600 rounded text-[9px] font-bold">
                  {{ item.tag }}
                </span>
              </div>
              
              <div>
                <h3 class="text-sm font-bold text-gray-800 flex items-center gap-1 group-hover:text-indigo-600 transition-colors">
                  {{ item.title }} 
                  <span class="opacity-0 group-hover:opacity-100 transition-opacity ml-1">→</span>
                </h3>
                <p class="text-xs text-zen-gray mt-1.5 leading-relaxed line-clamp-3">
                  {{ item.description }}
                </p>
              </div>
            </div>
            
            <div class="border-t border-gray-200/20 pt-3.5 mt-4 flex items-center justify-between text-[10px] text-zen-gray font-medium">
              <span>{{ item.duration }}</span>
              <span class="font-bold text-zen-ink">{{ item.price }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Full Page Detail View -->
      <div v-else class="space-y-6 animate-slide-in">
        <!-- Breadcrumbs & Navigation Row -->
        <div class="flex items-center justify-between border-b border-gray-200 pb-3 select-none">
          <button
            @click="activeCourse = null"
            class="inline-flex items-center gap-1 text-xs font-bold text-indigo-600 hover:text-indigo-700 transition"
          >
            ← 返回课程列表
          </button>
          <div class="text-[10px] text-zen-gray font-bold flex items-center gap-1.5">
            <span>Forwelike 知识讲堂</span>
            <span>/</span>
            <span class="text-zen-ink">{{ activeCourse.title }}</span>
          </div>
        </div>

        <!-- Banner -->
        <div class="p-6 md:p-8 rounded-3xl bg-white border border-white/50 shadow-sm relative overflow-hidden apple-glass">
          <div class="relative z-10 max-w-4xl space-y-4">
            <span class="px-2.5 py-0.5 bg-indigo-50 border border-indigo-100 rounded text-indigo-600 text-[10px] font-bold">
              {{ activeCourse.tag }}
            </span>
            <div class="flex flex-col md:flex-row md:items-center gap-4">
              <div class="p-3 bg-[#F4F6F5] rounded-2xl shadow-sm shrink-0 w-fit text-xl">
                🎓
              </div>
              <div>
                <h1 class="text-xl md:text-2xl font-black text-gray-800 leading-tight">
                  {{ activeCourse.title }}
                </h1>
                <p class="text-xs text-zen-gray font-bold tracking-wide uppercase mt-1">
                  {{ activeCourse.subtitle }}
                </p>
              </div>
            </div>
            <p class="text-xs text-zen-gray leading-relaxed max-w-3xl">
              {{ activeCourse.description }}
            </p>
          </div>
          <div class="absolute top-0 right-0 w-56 h-56 bg-white/10 rounded-full blur-2xl" />
        </div>

        <!-- Details Content Columns -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
          <!-- Left Column: Outcomes & Syllabus -->
          <div class="lg:col-span-8 space-y-6">
            
            <!-- Outcomes -->
            <div class="glass-panel p-5 space-y-3 bg-white border border-white/50 shadow-sm apple-glass">
              <h4 class="text-xs font-black text-gray-700 uppercase tracking-wider flex items-center gap-1.5">
                🎯 课程预期收获
              </h4>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3 bg-indigo-50/15 p-4 rounded-xl border border-indigo-50/50">
                <div v-for="(out, idx) in activeCourse.outcomes" :key="idx" class="flex items-start gap-2 text-xs text-zen-ink leading-relaxed">
                  <span class="text-indigo-600 shrink-0 mt-0.5">✓</span>
                  <span>{{ out }}</span>
                </div>
              </div>
            </div>

            <!-- Syllabus -->
            <div class="glass-panel p-5 space-y-4 bg-white border border-white/50 shadow-sm apple-glass">
              <h4 class="text-xs font-black text-gray-700 uppercase tracking-wider flex items-center gap-1.5">
                📖 详细授课章节目录
              </h4>
              <div class="space-y-3.5">
                <div v-for="(ch, idx) in activeCourse.syllabus" :key="idx" class="border border-gray-200/60 rounded-2xl overflow-hidden shadow-sm bg-white/40">
                  <button
                    @click="expandedChapter = expandedChapter === idx ? null : idx"
                    class="w-full flex items-center justify-between p-4 hover:bg-white/80 text-left transition-colors outline-none"
                  >
                    <div>
                      <span class="text-[10px] font-black text-indigo-600 uppercase tracking-wider">
                        {{ ch.duration }}
                      </span>
                      <h5 class="font-black text-gray-800 text-xs mt-0.5">{{ ch.title }}</h5>
                    </div>
                    <span class="text-xs text-zen-gray transition-transform" :class="expandedChapter === idx ? 'rotate-180' : ''">
                      ▼
                    </span>
                  </button>
                  
                  <div v-if="expandedChapter === idx" class="p-4 bg-white border-t border-gray-150 space-y-4 text-xs leading-relaxed text-zen-ink">
                    <p class="font-semibold text-zen-gray italic bg-slate-50 p-3 rounded-xl">{{ ch.description }}</p>
                    <div class="space-y-2 mt-2 pl-2">
                      <span class="text-[10px] font-black text-zen-gray uppercase block tracking-wider">核心知识点与实战：</span>
                      <div v-for="(pt, pIdx) in ch.points" :key="pIdx" class="flex items-start gap-2 text-zen-gray">
                        <span class="text-indigo-600 shrink-0 font-bold">•</span>
                        <span>{{ pt }}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

          </div>

          <!-- Right Column: Metadata Overview -->
          <div class="lg:col-span-4 space-y-6">
            
            <!-- Stats Card -->
            <div class="glass-panel p-5 space-y-4 bg-white border border-white/50 shadow-sm apple-glass">
              <h4 class="text-xs font-black text-gray-700 uppercase tracking-wider">
                📋 课程概览
              </h4>
              
              <div class="space-y-3.5 text-xs text-zen-gray">
                <div class="flex justify-between items-center border-b border-gray-100 pb-2">
                  <span class="text-zen-gray">课程价格:</span>
                  <span class="text-lg font-black text-indigo-600">{{ activeCourse.price }}</span>
                </div>
                <div class="flex justify-between items-center border-b border-gray-100 pb-2">
                  <span class="text-zen-gray">授课时长:</span>
                  <span class="font-bold text-zen-ink">{{ activeCourse.duration }}</span>
                </div>
              </div>

              <!-- Target Audience -->
              <div class="space-y-2 pt-2 border-t border-gray-100">
                <span class="font-bold text-gray-700 block text-xs">👥 适合人群:</span>
                <div class="flex flex-wrap gap-1">
                  <span v-for="t in activeCourse.targetAudience" :key="t" class="px-2 py-0.5 bg-gray-50 border border-gray-200 text-zen-gray rounded text-[9px] font-bold">
                    {{ t }}
                  </span>
                </div>
              </div>

              <!-- Tools Used -->
              <div class="space-y-2 pt-2 border-t border-gray-100">
                <span class="font-bold text-gray-700 block text-xs">🛠️ 核心实操工具:</span>
                <div class="flex flex-wrap gap-1">
                  <span v-for="t in activeCourse.toolsUsed" :key="t" class="px-2 py-0.5 bg-emerald-50 border border-emerald-100 text-emerald-700 rounded text-[9px] font-bold">
                    {{ t }}
                  </span>
                </div>
              </div>

              <!-- Action button -->
              <button
                @click="alertOrderRequest"
                class="w-full py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-xs rounded-xl shadow-sm transition mt-4"
              >
                立即预约咨询
              </button>
            </div>

            <!-- Tips Banner -->
            <div class="p-4 bg-slate-900 text-white rounded-3xl space-y-2 relative overflow-hidden select-none">
              <div class="relative z-10">
                <h5 class="font-black text-xs text-white">需要企业内训定制？</h5>
                <p class="text-[9px] text-gray-400 leading-relaxed mt-1">
                  如果您需要根据自身的产品品类和团队运营能力量身定制专属的实战课程体系，可点击立即联系顾问或发送邮件。
                </p>
                <div class="text-[9px] font-mono text-indigo-300 mt-2">
                  📧 support@forwelike.com
                </div>
              </div>
              <div class="absolute bottom-[-15px] right-[-15px] w-16 h-16 bg-indigo-600/30 rounded-full blur-xl" />
            </div>

          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import SmartMarketing from './SmartMarketing.vue';
import SmartTools from './SmartTools.vue';

// Define Props from App.vue
const props = defineProps({
  leads: Array,
  ourCompanyInfo: Object,
  callAiApi: Function,
  activeAiModel: String
});

// View Navigation state
const currentTab = ref('marketing'); // 'marketing' or 'learning'
const activeTool = ref(null);       // null or subview key

// ----------------------------------------------------
// Tab 1: Smart Marketing State & Data
// ----------------------------------------------------
const marketingTools = [
  {
    id: 'marketing-aichat',
    title: 'AI 对话管理',
    desc: '查看并管理客户端 AI 采购助手的实时对话记录，提取客户意向与联系信息。',
    iconPath: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z', // MessageSquare SVG
    iconColor: 'text-indigo-600',
    badge: '实时同步',
    stats: '累计对话 4,820 次 · 转化率 14.8%'
  },
  {
    id: 'marketing-email',
    title: '智能邮件营销',
    desc: '利用 AI 一键撰写针对性的开发信，向目标客户自动发送产品宣传与报价。',
    iconPath: 'M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z', // Mail SVG
    iconColor: 'text-purple-600',
    badge: '高效获客',
    stats: '已发送 12,400 封 · 送达率 98.4%'
  },
  {
    id: 'marketing-search',
    title: '智能客户搜索',
    desc: '输入行业与国家，由 AI 在全球主流社交媒体与海关数据中挖掘采购商。',
    iconPath: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z', // Search SVG
    iconColor: 'text-amber-600',
    badge: '精准挖掘',
    stats: '已发现 1,240 个采购商 · 精准度 92%'
  },
  {
    id: 'marketing-analysis',
    title: '智能客户分析',
    desc: '多维度智能分析采购商的成交规模、画像与偏好，生成针对性谈判建议。',
    iconPath: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 002 2h2a2 2 0 002-2', // BarChart SVG
    iconColor: 'text-emerald-600',
    badge: '决策画像',
    stats: '已聚类 5 个核心客户群组'
  },
  {
    id: 'marketing-seo',
    title: '智能 SEO 系统',
    desc: '一键完成图片 Alt 与页面 Meta 缺失修复，根据核心词自动化生成高权重收录文章。',
    iconPath: 'M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L18 14l-6.857 2.286L9 23l-2.286-6.857L0 14l6.857-2.286L9 5z', // Sparkles SVG
    iconColor: 'text-sky-600',
    badge: '收录优化',
    stats: '健康度 88分 · 已保存 24 个关键词'
  },
  {
    id: 'marketing-geo',
    title: '智能 GEO 系统',
    desc: '面向 ChatGPT Search、Gemini、Perplexity 等生成式 AI 搜索引擎进行引用率与品牌声誉优化。',
    iconPath: 'M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9', // Globe SVG
    iconColor: 'text-rose-600',
    badge: '新一代AI优化',
    stats: 'AI 提置率 34.2% · 友好度 92分'
  },
  {
    id: 'marketing-calendar',
    title: '世界营销日历',
    desc: '查询并追踪全球不同国家地区的核心节日与热卖节点，利用 AI 推荐营销策划与广告策略。',
    iconPath: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z', // Calendar SVG
    iconColor: 'text-orange-600',
    badge: '营销热点',
    stats: '已包含 7 个国家 · 24 个重点促销节日'
  },
  {
    id: 'marketing-plans',
    title: '营销方案汇总库',
    desc: '汇聚邮件营销、AI 智能方案及世界营销日历生成的所有方案，统一管理、筛选与归档复用。',
    iconPath: 'M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2', // Clipboard List SVG
    iconColor: 'text-violet-600',
    badge: '统一汇总',
    stats: '已归档 8 份方案 · 涵盖 3 大渠道来源'
  }
];

const selectTool = (toolId) => {
  activeTool.value = toolId;
  if (toolId === 'marketing-aichat' && mockSessions.value.length > 0) {
    selectedSession.value = mockSessions.value[0];
  }
  if (toolId === 'marketing-search') {
    selectedLead.value = null;
    searchComplete.value = false;
  }
  if (toolId === 'marketing-calendar') {
    selectedHoliday.value = holidays.value[0];
  }
};

// --- View: AI Chat transcripts states & methods ---
const selectedSession = ref(null);
const mockSessions = ref([
  {
    id: 'session-1',
    customerName: 'Dieter Müller',
    country: '德国',
    ip: '82.165.12.34',
    device: 'Desktop Chrome (macOS)',
    lastMessage: '需要一份防冻重力自压水囊的德语报价，急！',
    time: '2 小时前',
    isAcquired: true,
    email: 'd.mueller@mueller-outdoor.de',
    phone: '+49 176 1234567',
    messages: [
      { sender: 'visitor', content: 'Hi, I need information about your TPU folding water bladder. Do you ship to Hamburg?', time: '14:20' },
      { sender: 'ai', content: 'Hello! Yes, Zen Specialty Manufacturing offers worldwide shipping, including CIF Hamburg options. Our TPU folding water bladders (FL-WT series) are food-grade, certified by FDA, and feature anti-freeze insulation for temperatures down to -40°C. How many liters do you need?', time: '14:21' },
      { sender: 'visitor', content: 'Great. We are planning to order 200 units of 5000L water bladder. Can you send a quick quote to d.mueller@mueller-outdoor.de?', time: '14:22' },
      { sender: 'ai', content: 'Certainly! I have recorded your request for 200 units of 5000L FL-WT folding water bladders. A formal quotation (CIF Hamburg terms) is being drafted. Our sales representative Dieter will email you within 1 hour. Thank you!', time: '14:23' }
    ]
  },
  {
    id: 'session-2',
    customerName: 'Tariq Aziz',
    country: '阿联酋',
    ip: '91.74.83.11',
    device: 'iPhone Safari (iOS)',
    lastMessage: '请问不锈钢水箱有防晒认证吗？中东极热天气使用。',
    time: '1 天前',
    isAcquired: false,
    email: 'tariq.aziz@gulf-oasis.ae',
    phone: '+971 50 987 6543',
    messages: [
      { sender: 'visitor', content: 'Hello, do your SUS304 water tanks withstand direct desert sunlight in UAE?', time: 'Yesterday' },
      { sender: 'ai', content: 'Hello! Yes, our SUS304/SUS316 water tanks (EX-XT series) feature an exclusive double-layer insulation foaming process that keeps water temperature stable and prevents evaporation/overheating under direct sunlight (up to 60°C ambient). They are widely used in agricultural and industrial irrigation in the Gulf region.', time: 'Yesterday' },
      { sender: 'visitor', content: 'Awesome. I need 20 units of 20,000L tanks. Please save my contact tariq.aziz@gulf-oasis.ae. Let someone call me.', time: 'Yesterday' }
    ]
  }
]);

const importChatAsLead = (session) => {
  if (session.isAcquired) return;
  
  const flagMap = { '德国': '🇩🇪', '阿联酋': '🇦🇪', '美国': '🇺🇸', '英国': '🇬🇧', '泰国': '🇹🇭' };
  const newLead = {
    id: Date.now(),
    name: session.customerName || '未命名客商',
    contact: session.customerName || '未命名联系人',
    phone: session.phone || '',
    country: session.country || '海外',
    flag: flagMap[session.country] || '🌍',
    score: 85,
    category: 'parts',
    stage: 'inquiry',
    tags: [session.country, 'AI客服线索'],
    routingPath: 'AI 自动对话抓取',
    rawMessage: `客户邮箱: ${session.email || '未填'}\n最后咨询: ${session.lastMessage}\n\n对话摘要:\n${session.messages.map(m => (m.sender === 'visitor' ? '访客' : 'AI') + ': ' + m.content).join('\n')}`
  };
  
  props.leads.push(newLead);
  session.isAcquired = true;
  alert('🎉 线索已成功建档并导入 MagicHub CRM！可在【客户管理】中查看跟进。');
};

// --- View: AI Lead Search states & methods ---
const isSearching = ref(false);
const searchComplete = ref(false);
const searchProgress = ref(0);
const searchProgressText = ref('');
const selectedLead = ref(null);
const searchLeads = ref([]);

const runLeadSearch = () => {
  if (!searchQuery.value.trim()) {
    alert('请输入搜索关键词！');
    return;
  }
  isSearching.value = true;
  searchComplete.value = false;
  selectedLead.value = null;
  searchProgress.value = 0;
  
  const steps = [
    { text: '分析检索关键词并提取语义...', duration: 600 },
    { text: '探测 Google Maps 与全球商业名录...', duration: 800 },
    { text: '抓取欧美海关物流关单记录...', duration: 900 },
    { text: '过滤无效或死链企业，爬取邮箱与 LinkedIn 接口...', duration: 700 },
    { text: '整理画像与匹配度测算，完成渲染...', duration: 500 }
  ];
  
  let currentStep = 0;
  
  const nextStep = () => {
    if (currentStep < steps.length) {
      searchProgressText.value = steps[currentStep].text;
      searchProgress.value = Math.min(100, Math.floor(((currentStep + 1) / steps.length) * 100));
      setTimeout(() => {
        currentStep++;
        nextStep();
      }, steps[currentStep].duration);
    } else {
      isSearching.value = false;
      searchComplete.value = true;
      // Load mock search results
      searchLeads.value = [
        {
          id: 'lead-1',
          company: 'Zenith Agri Holdings Ltd',
          contact_name: 'Sarah Jenkins',
          title: 'Procurement Director',
          email: 's.jenkins@zenithagri.com',
          phone: '+1 512 893 2341',
          country: '美国',
          score: 94,
          products: '特种折叠水囊',
          website: 'www.zenithagri.com',
          description: '美国德克萨斯州大型农业灌溉服务商，正寻找可信赖的 TPU 高容积折叠蓄水容具（FL-WT 系列匹配），预算主要针对大容量灌溉水囊，年采购规模约 50 万美元。',
          outreachSubject: 'Premium TPU Folding Water Bladder - Quote Request for Zenith Agri',
          outreachBody: 'Dear Sarah Jenkins,\n\nWe noticed Zenith Agri is looking for high-capacity, heavy-duty TPU flexible water tanks for irrigation. Zen Specialty manufactures premium, FDA-certified, food-grade TPU bladders (FL-WT series) designed to survive harsh temperatures from -40°C to 60°C. We offer flexible MOQs and direct shipping CIF Houston port. Would you like a catalog and a free sample fabric?\n\nBest regards,\nMagicHub Copilot',
          saved: false
        },
        {
          id: 'lead-2',
          company: 'Müller Water Systems GmbH',
          contact_name: 'Hans Müller',
          title: 'Purchasing Manager',
          email: 'h.mueller@mueller-wasser.de',
          phone: '+49 69 987654',
          country: '德国',
          score: 91,
          products: '防爆不锈钢保温水箱',
          website: 'www.mueller-wasser.de',
          description: '德国法兰克福工业循环水设备制造商，急需双层发泡隔温防爆不锈钢水箱（EX-XT 系列匹配）来满足新季度欧洲环保标准，对品控和 TUV/CE 证书十分敏感。',
          outreachSubject: 'TUV-Certified Anti-Freeze SUS304 Water Tanks - direct supply',
          outreachBody: 'Dear Hans Müller,\n\nI understand Müller Water Systems is expanding its industrial circulation lines in Europe. Zen Specialty produces premium double-layer foamed insulation SUS304/SUS316 water tanks (EX-XT series) with full TUV and CE compliance. Our patented insulation process prevents freezing under -40°C. We can ship DDP Frankfurt. Let us know if you want the engineering blueprints.\n\nSincerely,\nMagicHub Copilot',
          saved: false
        },
        {
          id: 'lead-3',
          company: 'Bangkok Aqua Agri Co., Ltd',
          contact_name: 'Somchai K.',
          title: 'Operations Manager',
          email: 'somchai@bangkok-aqua.co.th',
          phone: '+66 2 456 7890',
          country: '泰国',
          score: 88,
          products: '重力折叠蓄水容具',
          website: 'www.bangkok-aqua.co.th',
          description: '泰国清迈大型山地灌溉系统承包商，需要便携、易组装的田间临时蓄水重力囊。需要有本地代理接洽支持。',
          outreachSubject: 'FDA TPU Flexible Reservoirs for Hill Irrigation - Sompop Partner',
          outreachBody: 'Dear Somchai K.,\n\nFor Bangkok Aqua\'s mountain irrigation projects, we offer heavy-duty food-grade flexible reservoirs. Our local agent Sompop in Thailand is ready to assist you with on-site deployment. We provide FDA-approved materials with 10 years design life. Can we schedule a brief call with Sompop this Friday?\n\nBest,\nMagicHub Copilot',
          saved: false
        }
      ];
      selectedLead.value = searchLeads.value[0];
    }
  };
  
  nextStep();
};

const importLeadToCrm = (lead) => {
  if (lead.saved) return;
  const flagMap = { '美国': '🇺🇸', '德国': '🇩🇪', '泰国': '🇹🇭', '英国': '🇬🇧' };
  const newLead = {
    id: Date.now(),
    name: lead.company,
    contact: lead.contact_name,
    phone: lead.phone,
    country: lead.country,
    flag: flagMap[lead.country] || '🌍',
    score: lead.score,
    category: 'parts',
    stage: 'inquiry',
    tags: [lead.country, 'AI挖客录入'],
    routingPath: 'AI 智能引擎主动检索',
    rawMessage: `客商官网: ${lead.website}\n主要意向: ${lead.products}\n商商机背景:\n${lead.description}\n\n首封开发信草稿:\n主题: ${lead.outreachSubject}\n正文:\n${lead.outreachBody}`
  };
  
  props.leads.push(newLead);
  lead.saved = true;
  alert(`🎉 成功导入 CRM 客户库！您可以在【客户管理】中搜索到 [${lead.company}] 并启动邮件群发活动。`);
};

const copyOutreachDraft = (lead) => {
  const text = `Subject: ${lead.outreachSubject}\n\n${lead.outreachBody}`;
  navigator.clipboard.writeText(text).then(() => {
    alert('✓ 邮件正文已成功复制到剪贴板！');
  });
};

// --- View: World Marketing Calendar states & methods ---
const selectedMonth = ref(1);
const selectedHoliday = ref(null);
const holidays = ref([
  { id: 'h1', name: '元旦与新年假期', enName: "New Year's Day", date: '1月1日', month: 1, countries: ['Global', '美国', '德国', '阿联酋'], level: 'High', hotCategories: ['水库设备', '便携折叠水袋'], marketingTip: '新年伊始，市政灌溉采购项目与极地极端防冻设备蓄水采购招标开始发布预算，重点营销抗 -40°C 发泡保温防冻专利工艺。', promptTemplate: 'Dear Partner,\n\nHappy New Year! As you plan your water storage assets for 2026, protect your system from winter freeze with Zen patented double-layer insulation tanks. Contact us for the winter discount...' },
  { id: 'h2', name: '日本成人之日', enName: 'Coming of Age Day', date: '1月12日', month: 1, countries: ['日本'], level: 'Medium', hotCategories: ['礼品周边'], marketingTip: '日本冬季寒冷多雪，可推广轻巧便携防爆阀抗严寒水阀。', promptTemplate: '新年防严寒管阀促销开发信...' },
  { id: 'h3', name: '沙特建国日', enName: 'Saudi Founding Day', date: '2月22日', month: 2, countries: ['沙特阿拉伯'], level: 'High', hotCategories: ['高热防晒水箱', '折叠蓄水囊'], marketingTip: '沙特气候炎热干燥，蒸发严重。主推具有高遮光率、防腐耐暴晒、防蒸发盖的不锈钢水箱与抗UV材料重力折叠囊，切入中东农业用水。', promptTemplate: 'Dear Contractor,\n\nProtect your water assets from sandstorm and extreme heat. Our UV-resistant TPU water bladders offer reliable, zero-evaporation water storage under 50°C desert heat...' },
  { id: 'h4', name: '斋月筹备季', enName: 'Ramadan Preparation', date: '3月12日', month: 3, countries: ['阿联酋', '沙特', '中东地区'], level: 'High', hotCategories: ['管网配件', '高密度蓄水池'], marketingTip: '中东进入斋月准备期，水利工程设施提前采备以应对休假。主打快速履约、DDP迪拜双清专线，保障工期。', promptTemplate: 'Ramadan Preparation Special Offer for Water Storage Equipments...' },
  { id: 'h5', name: '欧洲春耕开耕季', enName: 'European Spring Farming', date: '4月5日', month: 4, countries: ['德国', '法国', '英国'], level: 'High', hotCategories: ['农业微灌水袋', '自压重力囊'], marketingTip: '春耕拉开序幕，欧洲农庄需要灵活部署的灌溉蓄水设备。主推 FL-WT 系列自压折叠重力水袋，突出其免水泥硬化、10分钟快速展开。', promptTemplate: 'Maximize your agricultural efficiency this spring. Get custom flexible field reservoirs...' }
]);

const plans = ref([]);
onMounted(() => {
  const local = localStorage.getItem('magichub_marketing_plans');
  if (local) {
    plans.value = JSON.parse(local);
  } else {
    plans.value = [
      { id: 'p1', title: '德国冬季防爆隔温水箱开发活动', channel: '邮件营销', createdAt: '2026-07-01', summary: '针对德国 Müller 客户进行的 -20°C 极寒水箱定制邮件，突出 CE 与 TUV 认证。', tags: ['德国', '极寒防冻', 'B2B'] },
      { id: 'p2', title: '斋月阿联酋快速送货计划', channel: '世界营销日历', createdAt: '2026-07-04', summary: '斋月期间发出的中东水箱快速空运与 DDP 双清空仓锁定方案。', tags: ['中东', '斋月', '快捷空运'] }
    ];
    localStorage.setItem('magichub_marketing_plans', JSON.stringify(plans.value));
  }
});

const generateHolidayPlan = (holiday) => {
  const newPlan = {
    id: 'plan-' + Date.now(),
    title: `${holiday.name}出海营销促案`,
    channel: '世界营销日历',
    createdAt: new Date().toISOString().split('T')[0],
    summary: `基于 ${holiday.date} ${holiday.name} 节日数据生成的专项促销话术模板。`,
    tags: [holiday.countries[0], '节日大促', holiday.hotCategories[0]]
  };
  plans.value.unshift(newPlan);
  localStorage.setItem('magichub_marketing_plans', JSON.stringify(plans.value));
  alert(`✓ 方案已保存！可在【营销方案汇总库】中查看。`);
};

const deletePlan = (id) => {
  plans.value = plans.value.filter(p => p.id !== id);
  localStorage.setItem('magichub_marketing_plans', JSON.stringify(plans.value));
};

const clearAllPlans = () => {
  if (confirm('确定要清空方案库吗？')) {
    plans.value = [];
    localStorage.setItem('magichub_marketing_plans', JSON.stringify([]));
  }
};

// ----------------------------------------------------
// Tab 2: Forwelike Learning State & Data
// ----------------------------------------------------
const activeCourse = ref(null);
const expandedChapter = ref(0);

const handleOpenCourse = (course) => {
  activeCourse.value = course;
  expandedChapter.value = 0;
};

const courses = [
  {
    id: 'starter',
    title: '独立站从 0 到 1 极速起步实战营',
    subtitle: 'Build & Scale: 0 to 1 Independent Station Bootcamp',
    description: '深度剖析欧美买家采购心理，手把手带你完成高转化独立站策划、内容架构设计与极速上线起步配置。无需编程基础，快速搭建起符合欧美本土审美的高询盘独立站。',
    duration: '12 课时 · 精品小班课',
    price: '¥4,980',
    tag: '经典返场',
    outcomes: [
      '主导完成符合欧美审美的独立站 UI/UX 结构策划',
      '掌握从产品上架、SEO 标签书写到询盘表单配置的全套 SOP',
      '掌握多节点边缘路由加速与独立站测速分析方法',
      '掌握独立站基础信任信号构建（Review/Case/隐私协议）'
    ],
    targetAudience: ['外贸SOHO/创业者', '传统工贸企业老板', '外贸运营/推广专员', '跨境电商转型卖家'],
    toolsUsed: ['WordPress', 'Elementor', 'Google Analytics 4', 'GSC', 'Lighthouse'],
    syllabus: [
      {
        title: '章节一：独立站定位与高询盘网站策划',
        duration: '3 课时',
        description: '深度剖析欧美采购商采购链路与决策心流，确立高询盘导向的页面策划架构。',
        points: [
          '欧美 B2B 买家画像与采购决策心流分析',
          '高询盘率独立站信息架构 (IA) 黄金排版法则',
          '产品详情页 (PDP) 与公司介绍页 (About us) 文案策划 SOP',
          '如何设置低阻力询盘表单与即时聊天组件'
        ]
      },
      {
        title: '章节二：主流建站系统实装与核心配置',
        duration: '3 课时',
        description: '独立站基础设施建设，包括服务器选型、域名部署、多端适配与安全规范。',
        points: [
          '域名选购、企业邮箱解析与 DNS 多节点加速方案',
          '精选自适应外贸主题与框架深度重构',
          '独立站后台安全设置与高可用防黑备份机制',
          '支付接口、隐私政策 (GDPR) 与商誉信任信号部署'
        ]
      },
      {
        title: '章节三：符合欧美本土化审美的视觉与内容架构',
        duration: '3 课时',
        description: '全球化品牌美学构建，消除“中式英语”与土味排版，极大化视觉转化率。',
        points: [
          '欧美本土化配色、字体与视觉网格系统设计规范',
          '高转化率 Landing Page 实战布局拆解',
          '“关于我们”与“客户案例 (Case Studies)”高信誉背书写作',
          '常见第三方认证徽章、资质文件的高效排布与设计'
        ]
      },
      {
        title: '章节四：极速上线部署与多维度性能测速优化',
        duration: '3 课时',
        description: '实现全球秒开的技术调优规范，彻底解决 Core Web Vitals 指标红线问题。',
        points: [
          'Cloudflare CDN 边缘节点网络布控与解析缓存优化',
          '首屏核心渲染速度（LCP）与交互延迟（INP）技术调优 SOP',
          '使用 Lighthouse 与 GTmetrix 进行实机性能深度审计',
          '上线发布前的技术 Checklist 逐项排查与正式发布'
        ]
      }
    ]
  },
  {
    id: 'seo-geo',
    title: 'Google SEO 霸屏与 GEO 流量先锋课',
    subtitle: 'SEO & GEO: AI Search Optimization Masterclass',
    description: '全面布局生成式 AI 搜索时代。涵盖技术 SEO 核心提速、高权重外部链接矩阵建设，以及针对 ChatGPT / SearchGPT / Perplexity 等生成式引擎的引言与召回优化（GEO）最新前沿实战打法。',
    duration: '16 课时 · 深度前沿实战',
    price: '¥3,980',
    tag: '热门推荐',
    outcomes: [
      '核心网页指标（Core Web Vitals）技术提速优化 SOP',
      'ChatGPT/Perplexity 召回算法机制与语义实体优化',
      '高质量引文与外链（Backlinks）获取路径与执行策略',
      'JSON-LD 结构化数据与 FAQ 智能引文布控方案'
    ],
    targetAudience: ['中高级外贸SEO推广', '独立站运营总监', '希望突破自然流量瓶颈的企业', '品牌出海市场负责人'],
    toolsUsed: ['Semrush', 'Ahrefs', 'Google Search Console', 'Screaming Frog', 'SearchGPT'],
    syllabus: [
      {
        title: '章节一：新一代技术 SEO 底座与站内诊断',
        duration: '4 课时',
        description: '打造高权重网站的技术骨架，解决谷歌爬虫抓取与索引障碍。',
        points: [
          '最新 Google 爬虫抓取管道（Crawl Budget）优化原理',
          '技术 SEO 诊断：XML 站点地图、Robots.txt 极佳部署策略',
          'JSON-LD 结构化数据与 Schema 标记智能布控实战',
          '全站重定向（301/302）与死链/孤岛页面一键修复方案'
        ]
      },
      {
        title: '章节二：高意图关键词矩阵规划与内容霸屏',
        duration: '4 课时',
        description: '利用专业工具挖掘海量商机词，布局高质量内容获取谷歌第一页排名。',
        points: [
          '使用 Semrush/Ahrefs 逆向挖掘竞品高价值流量词与痛点词',
          'Google EEAT 谷歌内容品质标准与 SEO 深度文章创作 SOP',
          '站内 Silo 孤岛面包屑结构规划与页面权重流转调优',
          '谷歌富媒体摘要 (Rich Snippets) 与 FAQ 问题抢占技巧'
        ]
      },
      {
        title: '章节三：生成式 AI 搜索时代 (GEO) 召回突破',
        duration: '4 课时',
        description: '迎接 AI 搜索革命，全面优化 ChatGPT、Perplexity 等生成式引擎的引文与召回。',
        points: [
          '生成式引擎（SearchGPT / Perplexity / Gemini）推荐底层逻辑',
          '语义实体 (Entities) 优化与多节点引文（Citations）智能布控',
          '通过第三方独立测评、行业推荐目录打入 AI 搜索生成摘要',
          '实战演练：GEO 实体词关联性与引文召回率提升调优'
        ]
      },
      {
        title: '章节四：高权重外链（Backlinks）获取与矩阵构建',
        duration: '4 课时',
        description: '安全、稳定地获取高质量外部链接，快速提升域名权威度 (DA/DR)。',
        points: [
          '高价值外链类型：客座投稿 (Guest Posting) 与新闻媒体外链',
          '使用 Ahrefs 进行竞品外链追踪与机会窃取实操',
          '大模型批量外链开发邀约信（强相关、高回复）写作 SOP',
          '外链健康度审计：垃圾外链识别、降权防范与屏蔽机制'
        ]
      }
    ]
  },
  {
    id: 'marketing',
    title: '外贸开发信与精准 B2B 拓客大师班',
    subtitle: 'AI Prospecting & B2B Email Masterclass',
    description: '摆脱无效群发。教授利用大模型进行 KP 级客户背调与高回复率个性化邮件撰写。融合发信网关与网络探测机制，最大化发信送达率与回复率。',
    duration: '10 课时 · 实操模板+方法论',
    price: '¥1,980',
    tag: '超值特惠',
    outcomes: [
      '使用 ChatGPT/Perplexity 进行目标企业 KP 决策链解析与背调',
      '大模型自动化发信话术优化（破冰/痛点触达/催复 SOP）',
      '防拦截 SMTP 发信物理网关配置与探测机制原理',
      '多渠道商务开发日历搭建与物流/时差轴协同'
    ],
    targetAudience: ['外贸业务员', '外贸SOHO创业者', '销售团队负责人', '主动式获客推广专员'],
    toolsUsed: ['Perplexity', 'LinkedIn Sales Navigator', 'SMTP/IMAP', 'DeBounce'],
    syllabus: [
      {
        title: '章节一：目标买家画像解构与 KP 决策链挖掘',
        duration: '2 课时',
        description: '利用大模型与网络工具全网定位潜在采购决策人，获取最精准联系方式。',
        points: [
          '利用谷歌高级搜索指令与 LinkedIn 精准定位目标买家',
          '使用 Perplexity AI 解析目标企业商业背景与核心决策人 (KP)',
          '决策人关键邮箱、联系电话深度探测与 DeBounce 双重清洗过滤',
          '建立客户画像卡：公司规模、核心产品线及潜在采购痛点预测'
        ]
      },
      {
        title: '章节二：AI 驱动的千人千面开发信撰写 SOP',
        duration: '3 课时',
        description: '告别垃圾群发，利用 AI 批量定制高针对性、高回复率的个性化邮件。',
        points: [
          '大模型深度调校：如何让 AI 说话“像专业欧美外贸人”',
          '高转化率开发信的黄金三段式话典与高阶破冰句设计',
          '针对不同决策人角色（采购/研发/老板）话术分层设计',
          '防止进入垃圾箱的发信敏感词库过滤与多语种本地化润色'
        ]
      },
      {
        title: '章节三：物理开发信发信网关与网络探测配置',
        duration: '3 课时',
        description: '发信基础设施的技术优化，从根本上解决邮件被系统拒信、退信问题。',
        points: [
          '发信域名解析底座配置：SPF, DKIM, DMARC 记录合规校验',
          '物理多域名矩阵搭建与防封邮箱安全预热 (Warm-up) 指标控制',
          '物理发信网关与网络链路探测技术实操',
          '多发信账号自动轮询与每日发信限额的安全策略配置'
        ]
      },
      {
        title: '章节四：多渠道商务跟进日历与客户池管理',
        duration: '2 课时',
        description: '建立闭环拓客节奏，合理规划邮件、社媒、电话等触达矩阵。',
        points: [
          '客户跟进漏斗设计：从“首次触达”到“送样谈判”的动作标准',
          '邮件 + LinkedIn + WhatsApp 三位一体跨时区跟进日历设计',
          '批量发信后的高意图回复提取与客户池快速流转归档',
          '流失客户激活与定期拜访话术体系部署'
        ]
      }
    ]
  },
  {
    id: 'negotiation',
    title: '外贸谈判 36 计：高转化商务沟通与逼单心法',
    subtitle: '36 Stratagems of B2B Negotiation & Closing',
    description: 'Forwelike 团队 16 年外贸一线实战心法总结。基于《孙子兵法》与三十六计之谋略，深度解构欧美、中东等不同区域买家的商务谈判心理。手把手拆解跨文化谈判、价值主张锚定报价、临门逼单及复购增长模型。',
    duration: '14 课时 · 真实案例演练',
    price: '¥3,280',
    tag: '独家心法',
    outcomes: [
      '用孙子兵法思维应对大客户报价、议价及让步博弈',
      '避开低价竞争陷阱，通过“价值主张锚定法”实现高客单成交',
      '掌握一套完整的催款、锁定订单及阻击流失客户的逼单 SOP',
      '运用“金蝉脱壳”等谋略，实现客诉危机的完美化解与老客户召回'
    ],
    targetAudience: ['外贸业务主管/总监', '外贸老业务员', '经常遭遇“有询盘无成交”的团队', 'SOHO 业务开拓者'],
    toolsUsed: ['B2B 议价心法数据库', '买家谈判心理分层模型', '36计谈判话典库', '危机客诉应对模板'],
    syllabus: [
      {
        title: '第一篇：胜战计——询盘初筛与主导权布控 (1-6计)',
        duration: '3 课时',
        description: '在多方询盘涌入与竞争对手比价的混乱市场中，以多维度背景探测与博弈谋略，穿透虚实，牢牢掌控商务谈判主动权。',
        points: [
          '【瞒天过海】买家隐藏真实采购量时，通过辅助辅料配套设计刺探其真实年采购规模',
          '【围魏救赵】绕开价格死结，通过追问其下游交期延迟惩罚，逼迫买家做出合理妥协',
          '【借刀杀人】借助海关客观提单数据、原材料成本红线，击穿买家盲目压价',
          '【以逸待劳】冷处理买家压价纠缠，用专业消磨其施压耐心',
          '【趁火打劫】捕获买家现有供应商暴雷或受阻的危机时刻，提供备用极速履约通道一击即中',
          '【声东击西】表面死守某一主力型号的价格，暗中将底牌转为配件赠送或售后保修升级让利'
        ]
      },
      {
        title: '第二篇：敌战计——决策链穿透与防比价博弈 (7-12计)',
        duration: '3 课时',
        description: '探明买家真实决策链条，防范其使用“比价套路”，并在价格交锋的暗战中，巧施谋略锁定高利润整单合同。',
        points: [
          '【无中生有】针对观望买家，创造“排产特惠名额本周即将截止”的紧迫氛围，促成早定金支付',
          '【暗度陈仓】表面应对标准品比价，暗中推荐非标定制件，令买家偏离对手的比价轨道',
          '【隔岸观火】客户宣称有对手极低报价时，保持定力提供质量质检检验标准，静待其暴雷',
          '【笑里藏刀】对买家提供极佳的商务沟通与情绪价值，但对合同红线与付款条件坚守寸步不让',
          '【李代桃僵】牺牲个别打样费用或运费补贴的微小让步，保住整机核心高额利润',
          '【顺手牵羊】在发票签字的最后关头，顺势搭售高毛利周边配件提升总单价'
        ]
      },
      {
        title: '第三篇：攻战计——破冰建信与欲擒故纵 (13-18计)',
        duration: '3 课时',
        description: '越过中间层深入核心决策人，在谈判进入拉锯时实施欲擒故纵与抛砖引玉，快速破冰并建立深度商业信任。',
        points: [
          '【打草惊蛇】使用反问式高阶技术提问测试客户是中介还是终端大客户',
          '【借尸还魂】面对跟丢的旧项目，借由其所在国政策变更重新触达激活',
          '【调虎离山】在谈判陷入僵局时，要求开展双方高层技术对接，将采购经理“调离”主战场',
          '【欲擒故纵】买家拖延付款时，告知产能不足本周暂缓为其锁单，使其为锁单反向催款',
          '【抛砖引玉】向客户分享高价值的行业解析白皮书，吸引并交换客户的核心图纸与真实预算',
          '【擒贼擒王】直接切入核心研发总监或老板进行有效沟通'
        ]
      },
      {
        title: '第四篇：混战计——议价僵局与技术化解 (19-24计)',
        duration: '3 课时',
        description: '在谈判中盘胶着阶段，利用釜底抽薪、排他性标准引导等方式化解价格战，并建立全套安全解套体系防范风险。',
        points: [
          '【釜底抽薪】查明买家降价深层动因，主动帮其砍掉多余参数与冗余设计产品降本',
          '【混水摸鱼】针对复杂的采购规格书，合理配置我司占优的排他性参数标准',
          '【金蝉脱壳】发生品质客诉时，提供预备的赔付退换与延长质保承诺，规避连带惩罚',
          '【关门捉贼】针对不签保密协议却索要技术图纸的套样买家，限制授权一键锁定',
          '【远交近攻】主力攻坚海外高毛利区域 of 直接终端大客户，对本地低价批发商做好防守',
          '【假道伐虢】利用帮助海外客户代做本地认证契机，逐步介入并全面控制供应链'
        ]
      }
    ]
  },
  {
    id: 'ai-website-2h',
    title: '2小时学会 AI 极速建站',
    subtitle: 'Speed Build: 2-Hour AI Web Creation Masterclass',
    description: '针对零基础学员的极速通关课。主要讲解如何借助大语言模型（LLM）与无代码托管平台，在短短 2 小时内，完成独立站骨架设计、文案自动生成、SEO元标签布控及上线。',
    duration: '2 小时 · 极速实战营',
    price: '¥3,980',
    tag: '极速通关',
    outcomes: [
      '使用 AI 快速生成符合欧美审美的高质量建站文案',
      '大模型（LLM）驱动下的 10 分钟独立站骨架设计与搭建',
      '自动化布局 SEO 元数据、描述及关键词匹配 SOP',
      '实现 2 小时内独立站正式上线与多端自适应发布'
    ],
    targetAudience: ['零基础建站新手', '外贸业务开发专员', '出海项目快速验证团队', '企业高管/决策人'],
    toolsUsed: ['Vite + Tailwind', 'v0.dev / Bolt.new', 'Cursor / Antigravity', 'Netlify / Vercel'],
    syllabus: [
      {
        title: '章节一：AI 极速创意与建站骨架搭建',
        duration: '0.5 小时',
        description: '利用前沿 LLM 快速梳理建站大纲，用提示词生成出海落地页代码框架。',
        points: [
          '大语言模型辅助目标市场分析与高转化关键词智能提取',
          '使用 AI 一键生成符合欧美高转化标准的企业定位与文案内容',
          'v0 / Bolt.new 等 AI UI 辅助工具入门与代码骨架极速生成',
          '本地项目初始化、Vite 快速运行与项目依赖一键部署'
        ]
      },
      {
        title: '章节二：无代码工具与 AI 一键上线',
        duration: '0.5 小时',
        description: '不写一行代码，通过 AI 赋能的界面编辑器修改元素与视觉风格。',
        points: [
          'AI 网页布局调整：拖拽排版与多端自适应实时预览优化',
          '借助 AI 快速替换欧美风格无版权高清大图与品牌标志设计',
          '头部导航栏、特色区块、页脚与交互按钮的布局重构',
          '利用 AI 修复排版错位及移动端体验调优'
        ]
      },
      {
        title: '章节三：自动化 SEO 与表单配置',
        duration: '0.5 小时',
        description: '快速部署 SEO 元数据与在线收集询盘表单，让网站兼具流量与转化。',
        points: [
          '提示词批量生成全站 Title/Description/Keywords 元数据',
          '配置低摩擦询盘收集表单、Google Form 与 AI 在线客服插件',
          '一键测试全站超链接与询盘邮件即时收发测试',
          '静态资源自动压缩与首屏渲染极速优化配置'
        ]
      },
      {
        title: '章节四：域名绑定与全球正式发布',
        duration: '0.5 小时',
        description: '使用现代云服务将网站免费发布至全球节点，配置安全证书与搜索引擎索引。',
        points: [
          '在 Netlify 或 Vercel 进行项目一键托管与版本部署',
          '自定义域名绑定、DNS 配置与 SSL 免费安全证书一键获取',
          '谷歌站长平台 (Google Search Console) 的所有权验证与站点地图提交',
          '全网发布上线，获取全球秒开的外贸独立站链接'
        ]
      }
    ]
  },
  {
    id: 'dev-mindset',
    title: '超新思维：用编程思维做外贸',
    subtitle: 'Super New Thinking: Tech-Driven Foreign Trade Automation',
    description: '主张用编程思维重构外贸营销与客户 analysis 流程。深入讲解如何借助 IDE 编写数据清洗脚本，并结合 Crawlab 分布式爬虫管理系统以及大模型智能体实现拓客全自动闭环。',
    duration: '10 课时 · 颠覆级思维实战',
    price: '¥6,980',
    tag: '前沿力荐',
    outcomes: [
      '掌握用编程思维解构销售漏斗，实现流程化、模块化与全天候自动化',
      '学会利用 Codex、Antigravity 等 IDE 编写数据采集与清洗脚本',
      '学会部署并操作 Crawlab 分布式爬虫管理系统进行大规模客群挖掘',
      '掌握智能开发工具与外贸 EDM、物理发信送达网关的深度融合应用'
    ],
    targetAudience: ['想实现流程自动化的外贸SOHO', '外贸团队技术负责人', '希望用AI赋能业务的高级销售', '技术型出海创业者'],
    toolsUsed: ['Codex / Antigravity', 'Crawlab (小龙虾)', 'Python / Node.js', 'n8n / Make'],
    syllabus: [
      {
        title: '章节一：编程思维解构与出海全链路自动化认知',
        duration: '2 课时',
        description: '打破传统业务员的机械性操作，学会像软件工程师一样利用逻辑与模块重构出海业务线。',
        points: [
          '“外贸工程师”思维拆解：流程化、模块化、代码化与全天候自动化',
          '外贸业务流中的 API 接口、Webhook 触发与数据传输原理解析',
          'n8n / Make 等可视化集成工具与 CRM / 邮件收发的联动机制',
          '实战演练：用流程图重新拆解您团队现有的客户跟进流程并标识自动化节点'
        ]
      },
      {
        title: '章节二：基于 IDE 工具（Codex / Antigravity）的智能化营销与脚本编写',
        duration: '2 课时',
        description: '核心讲解如何利用智能开发环境（Codex / Antigravity）进行大模型提示词开发与营销代码编写。',
        points: [
          '使用人类自然语言与 Antigravity / Codex 协作，快速编写出网页抓取与去重脚本',
          '静态网页与动态加载网页的数据提取技巧 (BeautifulSoup / Playwright) 的编写调优',
          '使用 IDE 快速调试发信接口调用脚本，规避代码层面的报错与环境依赖问题',
          '实战演练：在 Antigravity 界面中，一键生成一个能抓取特定展会企业名录的代码脚本'
        ]
      },
      {
        title: '章节三：分布式抓取管理平台 Crawlab 的客户分析实操',
        duration: '2 课时',
        description: '结合 Crawlab 分布式爬虫管理系统进行大规模海外目标客群抓取与分布式运行调度。',
        points: [
          '分布式爬虫管理平台 Crawlab 的架构认知与本地/云端一键部署',
          '在 Crawlab 中配置多节点爬虫任务队列、执行日志监控与定时运行策略',
          '批量提取全球潜在买家的联系信息、产品痛点，实现客户数据的结构化存储与清洗',
          '实战演练：在 Crawlab 平台部署一个爬虫节点，完成特定品类客户特征的清洗分析'
        ]
      },
      {
        title: '章节四：工具与外贸营销的深度融合应用',
        duration: '2 课时',
        description: '深度剖析：IDE 工具与自动化流如何深度咬合外贸开发信营销（EDM）。',
        points: [
          '基于物理送达探测 + 智能体客群背景洞察 + 动态邮件撰写的营销闭环',
          '一键输入公司域名，调用智能体接口自动生成客户背景调查分析报告',
          '构建全自动可视化外贸拓客漏斗看板，实时 analysis 送达率、回复率并自动分类高意图询盘',
          '团队日常运作中的维护：脚本防阻断策略与大模型额度控制'
        ]
      },
      {
        title: '章节五：颠覆级外贸工程师营销实战大闭环',
        duration: '2 课时',
        description: '串联前面所有模块：抓取脚本编写 → 分布式大规模调度 → 背景画像与询盘判定 → 全自动精准营销触达。',
        points: [
          '如何将前面章节的“爬虫抓取数据 → AI画像 → 发信网关”通过 Webhook 串联为闭环',
          '发信状态监控、退信自动过滤与高意图回复的二次自动跟进配置',
          '构建可视化的拓客数据大盘，实现每日自动挖掘并联系 50 个精准意向客户的自动化闭环',
          '实战演练：部署并运行一个全自动的外贸拓客闭环流水线并进行实机测试'
        ]
      }
    ]
  }
];
</script>

<style scoped>
.animate-fadeIn {
  animation: fadeIn 0.35s ease-out forwards;
}
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
.animate-slide-in {
  animation: slideIn 0.3s ease-out forwards;
}
@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateX(10px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}
</style>
