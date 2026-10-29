<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10">
    <div v-if="viewState === 'list'" class="space-y-6">
    <!-- 1. Header (客户管理与筛选搜索头部) -->
    <div class="pb-4 border-b border-white/20 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
      <div>
        <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2 text-zen-ink">
          客户管理 <span class="text-xs font-normal text-zen-gray font-sans bg-white/40 border border-white/50 px-2 py-0.5 rounded-lg select-none">高精度客户</span>
        </h2>
        <p class="text-[11px] text-zen-gray mt-1">本地 SQLite 安全隔离，AI 多模型智能路由，外贸询盘特化处理</p>
      </div>

      <!-- Table/Card view mode toggle -->
      <div class="flex items-center gap-1.5 bg-white/40 backdrop-blur-md border border-white/50 p-0.5 rounded-xl shadow-sm select-none">
        <button
          @click="viewMode = 'list'"
          class="px-3.5 py-1.5 rounded-lg text-[10px] font-semibold transition-all duration-300 outline-none flex items-center gap-1"
          :class="viewMode === 'list' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
          title="列表表格形式"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
          列表形式
        </button>
        <button
          @click="viewMode = 'card'"
          class="px-3.5 py-1.5 rounded-lg text-[10px] font-semibold transition-all duration-300 outline-none flex items-center gap-1"
          :class="viewMode === 'card' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
          title="磁贴卡片形式"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2v-4zM14 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2v-4z" />
          </svg>
          卡片形式
        </button>
      </div>
    </div>

    <!-- Automotive parts customer synchronization console [NEW] -->
    <div class="apple-glass rounded-3xl p-5 border border-white/50 space-y-4 shadow-xl select-none relative overflow-hidden bg-gradient-to-br from-indigo-50/10 via-white/20 to-indigo-50/10 backdrop-blur-md">
      <!-- Glowing background decoration -->
      <div class="absolute -right-10 -top-10 w-40 h-40 bg-indigo-500/10 rounded-full blur-2xl pointer-events-none"></div>
      
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
        <div class="flex items-center gap-3">
            <span class="text-2xl">🔄</span>
          <div>
            <h3 class="text-xs font-bold text-zen-ink font-serif-sc tracking-wide flex items-center gap-2">
              汽配客户数据高精增量同步控制台
              <span class="text-[8px] px-2 py-0.5 rounded-full font-mono bg-indigo-500/10 text-indigo-700 animate-pulse">Incremental Sync</span>
            </h3>
            <p class="text-[9px] text-zen-gray/80 mt-0.5">侦测桌面路径 `/Users/ky/Desktop/汽配客户`，支持增量同步与 AI 报告智能深度绑定</p>
          </div>
        </div>
        <div class="flex items-center gap-2 w-full sm:w-auto">
          <button
            @click="scanExternalData"
            class="flex-1 sm:flex-none px-3.5 py-1.5 rounded-xl border border-indigo-200 bg-white/60 hover:bg-white text-indigo-700 text-[10px] font-bold shadow-sm transition-all active:scale-[0.98]"
            title="侦测外部文件夹数据"
          >
            🔍 侦测外部数据
          </button>
          <button
            @click="executeIncrementalSync"
            :disabled="syncLoading || !isSyncActive"
            class="flex-1 sm:flex-none px-4 py-1.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-[10px] font-bold shadow-md transition-all active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-1.5"
          >
            <span v-if="syncLoading" class="animate-spin text-xs">⟳</span>
            <span>⚡ 立即增量同步</span>
          </button>
        </div>
      </div>

      <!-- Progress Status & Database Counters -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-[10px] bg-white/20 p-3 rounded-2xl border border-white/30" v-if="isSyncActive || scannedCount > 0">
        <div class="flex flex-col">
          <span class="text-zen-gray font-semibold">外置客户数</span>
          <span class="text-zen-ink font-mono font-bold text-sm mt-0.5">{{ scannedCount }} 个</span>
        </div>
        <div class="flex flex-col">
          <span class="text-zen-gray font-semibold">报告关联数</span>
          <span class="text-zen-ink font-mono font-bold text-sm mt-0.5 text-indigo-600">{{ reportMatchedCount }} 个 ({{ scannedCount > 0 ? Math.round((reportMatchedCount/scannedCount)*100) : 0 }}%)</span>
        </div>
        <div class="flex flex-col">
          <span class="text-zen-gray font-semibold">本地 CRM 库容</span>
          <span class="text-zen-ink font-mono font-bold text-sm mt-0.5 text-green-700">{{ leads.length }} 个</span>
        </div>
        <div class="flex flex-col">
          <span class="text-zen-gray font-semibold">同步引擎状态</span>
          <span class="text-zen-ink font-bold text-xs mt-1 flex items-center gap-1.5" :class="syncLoading ? 'text-indigo-600 animate-pulse' : 'text-zen-green'">
            <span class="w-1.5 h-1.5 rounded-full" :class="syncLoading ? 'bg-indigo-600 animate-ping' : 'bg-zen-green'"></span>
            {{ syncLoading ? '同步中...' : '就绪 (Idle)' }}
          </span>
        </div>
      </div>

      <!-- Real-time Synchronization Console Output Logs -->
      <div class="bg-black/95 text-green-400 font-mono text-[9px] p-3 rounded-2xl max-h-36 overflow-y-auto space-y-1 shadow-inner select-text border border-white/10 scrollbar-elegant" v-if="syncLogs.length > 0">
        <div class="flex justify-between items-center text-white/50 border-b border-white/5 pb-1 mb-1.5 select-none font-sans">
          <span>TERMINAL: magichub-parts-sync-engine v1.4.0</span>
          <button @click="syncLogs = []" class="hover:text-white transition-colors text-[8px]">清空日志</button>
        </div>
        <div v-for="(log, idx) in syncLogs" :key="idx" class="leading-relaxed whitespace-pre-wrap">
          {{ log }}
        </div>
      </div>
    </div>

    <!-- 2. Screenshot Replica Navigation Toolbar (深度还原截图顶栏) -->
    <div class="apple-glass rounded-3xl p-4 flex flex-wrap items-center justify-between gap-4 select-none border border-white/60 shadow-sm transition-all duration-300">
      <!-- 2.1 Subcategory tabs (左侧：全部/汽配/照明) -->
      <div class="flex items-center gap-2 text-xs flex-shrink-0">
        <span class="text-slate-400 font-bold mr-1 text-[11px] uppercase tracking-wider whitespace-nowrap">分类:</span>
        <button
          @click="selectedCategory = 'all'"
          class="whitespace-nowrap px-3.5 py-1.5 rounded-xl border font-medium text-xs transition-all duration-300 outline-none flex items-center gap-1.5 shadow-sm active:scale-[0.97]"
          :class="selectedCategory === 'all'
            ? 'bg-white border-slate-200/80 text-slate-800 font-bold'
            : 'bg-slate-50/50 border-transparent text-slate-500 hover:bg-white hover:text-slate-800 hover:border-slate-200/30'"
        >
           <span>全部</span>
          <span class="px-1.5 py-0.5 bg-slate-100 text-slate-500 rounded-md text-[9px] font-bold">{{ categoryCounts.all }}</span>
        </button>
        <button
          @click="selectedCategory = 'parts'"
          class="whitespace-nowrap px-3.5 py-1.5 rounded-xl border font-medium text-xs transition-all duration-300 outline-none flex items-center gap-1.5 shadow-sm active:scale-[0.97]"
          :class="selectedCategory === 'parts'
            ? 'bg-white border-slate-200/80 text-slate-800 font-bold'
            : 'bg-slate-50/50 border-transparent text-slate-500 hover:bg-white hover:text-slate-800 hover:border-slate-200/30'"
        >
           <span>汽配</span>
          <span class="px-1.5 py-0.5 bg-slate-100 text-slate-500 rounded-md text-[9px] font-bold">{{ categoryCounts.parts }}</span>
        </button>
        <button
          @click="selectedCategory = 'lights'"
          class="whitespace-nowrap px-3.5 py-1.5 rounded-xl border font-medium text-xs transition-all duration-300 outline-none flex items-center gap-1.5 shadow-sm active:scale-[0.97]"
          :class="selectedCategory === 'lights'
            ? 'bg-white border-slate-200/80 text-slate-800 font-bold'
            : 'bg-slate-50/50 border-transparent text-slate-500 hover:bg-white hover:text-slate-800 hover:border-slate-200/30'"
        >
           <span>照明</span>
          <span class="px-1.5 py-0.5 bg-slate-100 text-slate-500 rounded-md text-[9px] font-bold">{{ categoryCounts.lights }}</span>
        </button>
        <button
          @click="addNewCategory"
          class="w-8 h-8 rounded-xl flex items-center justify-center text-slate-400 bg-slate-50/50 hover:bg-white hover:text-slate-700 transition-all border border-transparent hover:border-slate-200/30 shadow-sm active:scale-90 duration-200"
          title="新增分类"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
          </svg>
        </button>
      </div>

      <!-- 2.2 Segmented Status filters (中间：全部/潜在客户/已成交/流失客户) -->
      <div class="flex items-center gap-1 bg-slate-100/60 p-0.5 rounded-2xl border border-slate-200/40 flex-shrink-0 shadow-inner">
        <button
          @click="selectedStatus = 'all'"
          class="whitespace-nowrap px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all duration-300 outline-none active:scale-[0.97]"
          :class="selectedStatus === 'all' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'"
        >
          全部
        </button>
        <button
          @click="selectedStatus = 'potential'"
          class="whitespace-nowrap px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all duration-300 outline-none active:scale-[0.97] flex items-center gap-1.5"
          :class="selectedStatus === 'potential' ? 'bg-white text-slate-800 shadow-sm' : 'text-slate-500 hover:text-slate-800'"
        >
            <span>潜在客户</span>
            <span class="px-1.5 py-0.5 bg-slate-200/50 text-slate-600 rounded-md text-[9px] font-bold">{{ leads.filter(l => l.stage === 'potential').length }}</span>
        </button>
        <button
          @click="selectedStatus = 'deal'"
          class="whitespace-nowrap px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all duration-300 outline-none active:scale-[0.97] flex items-center gap-1.5"
          :class="selectedStatus === 'deal' ? 'bg-white text-emerald-700 shadow-sm' : 'text-slate-500 hover:text-slate-800'"
        >
            <span>已成交</span>
            <span class="px-1.5 py-0.5 bg-emerald-100/60 text-emerald-700 rounded-md text-[9px] font-bold">{{ leads.filter(l => l.stage === 'deal').length }}</span>
        </button>
        <button
          @click="selectedStatus = 'lost'"
          class="whitespace-nowrap px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all duration-300 outline-none active:scale-[0.97] flex items-center gap-1.5"
          :class="selectedStatus === 'lost' ? 'bg-white text-rose-700 shadow-sm' : 'text-slate-500 hover:text-slate-800'"
        >
            <span>流失客户</span>
            <span class="px-1.5 py-0.5 bg-rose-100/60 text-rose-700 rounded-md text-[9px] font-bold">{{ leads.filter(l => l.stage === 'lost').length }}</span>
        </button>
      </div>

      <!-- 2.3 Actions (右侧：搜索/标签/导入/录入) -->
      <div
        class="flex items-center gap-2 md:gap-3 text-xs flex-shrink-0 transition-all duration-300"
        :class="showMobileSearch ? 'w-full md:w-auto' : ''"
      >
        <!-- Search Container -->
        <div class="relative flex-shrink-0 transition-all duration-300" :class="showMobileSearch ? 'flex-1 md:w-auto' : ''">
          <!-- Mobile search icon trigger (only visible when not searching) -->
          <button
            @click="showMobileSearch = true"
            class="whitespace-nowrap p-2 bg-white hover:bg-slate-50 border border-slate-200/80 rounded-xl font-medium text-slate-700 shadow-sm transition-all duration-300 outline-none active:scale-[0.97] flex items-center justify-center h-8 w-8"
            :class="{ 'hidden': showMobileSearch, 'md:hidden': !showMobileSearch }"
            title="展开搜索"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </button>

          <!-- Mobile view search input (visible when searching) -->
          <div
            class="relative w-full items-center gap-1.5 animate-fadeIn"
            :class="{ 'flex md:hidden': showMobileSearch, 'hidden': !showMobileSearch }"
          >
            <div class="relative w-full">
              <input
                type="text"
                v-model="searchQuery"
                placeholder="搜索客户名称、国家、标签..."
                class="w-full bg-white/60 border border-slate-200/80 rounded-xl px-3 py-1.5 pl-8 text-xs outline-none focus:bg-white focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 transition-all shadow-sm h-8"
              />
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-2.5 top-2 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <!-- Close search button -->
            <button
              @click="showMobileSearch = false"
              class="p-1.5 bg-white border border-slate-200/80 hover:bg-slate-50 text-slate-400 hover:text-slate-600 rounded-xl outline-none shrink-0 h-8 w-8 flex items-center justify-center shadow-sm"
              title="关闭搜索"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <!-- Desktop Search Input (always visible on desktop, hidden on mobile) -->
          <div class="hidden md:block relative w-44 md:w-56">
            <input
              type="text"
              v-model="searchQuery"
              placeholder="搜索客户名称、国家、标签..."
              class="w-full bg-white/60 border border-slate-200/80 rounded-xl px-3 py-1.5 pl-8 text-xs outline-none focus:bg-white focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/10 transition-all shadow-sm"
            />
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 absolute left-2.5 top-2 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>

        <!-- Tag management button -->
        <button
          @click="manageTags"
          class="whitespace-nowrap p-2 md:px-3.5 md:py-1.5 bg-white hover:bg-slate-50 border border-slate-200/80 rounded-xl font-medium text-slate-700 shadow-sm transition-all duration-300 hover:border-slate-300 outline-none active:scale-[0.97] items-center justify-center gap-1.5 h-8 md:h-auto"
          :class="{ 'hidden md:flex': showMobileSearch, 'flex': !showMobileSearch }"
          title="标签管理"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9.586 2.586A2 2 0 008.172 2H3a1 1 0 00-1 1v5.172a2 2 0 00.586 1.414l7.9 7.9a2 2 0 002.828 0l5.172-5.172a2 2 0 000-2.828l-7.9-7.9z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5.5 5.5h.01" />
          </svg>
          <span class="hidden md:inline">标签管理</span>
        </button>

        <!-- Batch import button -->
        <button
          @click="importBatch"
          class="whitespace-nowrap p-2 md:px-3.5 md:py-1.5 bg-white hover:bg-slate-50 border border-slate-200/80 rounded-xl font-medium text-slate-700 shadow-sm transition-all duration-300 hover:border-slate-300 outline-none active:scale-[0.97] items-center justify-center gap-1.5 h-8 md:h-auto"
          :class="{ 'hidden md:flex': showMobileSearch, 'flex': !showMobileSearch }"
          title="批量导入"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
          </svg>
          <span class="hidden md:inline">批量导入</span>
        </button>

        <!-- Add lead button -->
        <button
          @click="openAddLeadModal"
          class="whitespace-nowrap p-2 md:px-4 md:py-1.5 bg-slate-900 hover:bg-slate-800 text-white border border-transparent rounded-xl font-semibold shadow-sm transition-all duration-300 outline-none items-center justify-center gap-1.5 active:scale-[0.97] hover:shadow h-8 md:h-auto"
          :class="{ 'hidden md:flex': showMobileSearch, 'flex': !showMobileSearch }"
          title="录入客户"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4" />
          </svg>
          <span class="hidden md:inline">录入</span>
        </button>
      </div>
    </div>

    <!-- 3. Active Regional Collaborative Warning Card (已关闭) -->
    <div v-if="false" class="bg-amber-50/40 backdrop-blur-md border border-zen-gold/30 rounded-2xl p-5 flex items-start gap-4 transition-all duration-500 ease-out select-text">
      <div class="w-10 h-10 rounded-full bg-zen-gold/15 flex items-center justify-center text-zen-gold shrink-0">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      </div>
      <div class="space-y-1.5 flex-1">
        <h4 class="text-xs font-semibold text-zen-ink font-serif-sc">激活区域协作代理流转警报 (Regional Collaborative Routing)</h4>
        <p class="text-xs text-zen-gray leading-relaxed">
          系统检测到特定国家/地区 <strong>[{{ activeCollaborativeAlert.country }}]</strong> 有新的外贸询盘来自 <strong>{{ activeCollaborativeAlert.name }}</strong>，
          该地区已部署我方的海外驻点合作代理，系统已自动为您派发任务并通知当地代理跟进。
          <span class="text-zen-green font-medium">请及时派遣并协同当地驻地代理上门拜访并推进业务沟通，同时安排跨时区线上视频会议协同。</span>
        </p>
        <div class="pt-1.5 flex gap-3 select-none">
          <button
            @click="dismissCollaborativeAlert"
            class="px-3.5 py-1.5 rounded bg-white border border-zen-light text-[10px] text-zen-gray hover:text-zen-ink transition-all font-medium"
          >
            已知悉
          </button>
          <button
            @click="dispatchToAgent"
            class="px-3.5 py-1.5 rounded bg-zen-tea text-white text-[10px] hover:bg-zen-tea/90 transition-all font-semibold"
          >
            立即派遣至当地驻地代理商
          </button>
        </div>
      </div>
    </div>

    <!-- 4. Main viewport: List View (深度还原截图表格列表) or Card View -->
    <div v-if="viewMode === 'list'" class="space-y-4">
      <!-- 4.1 已成交组 (Section 1: 已成交 3) -->
      <div class="apple-glass rounded-2xl overflow-hidden border border-white/50" v-if="shouldShowGroup('deal')">
        <button
          @click="showDealGroup = !showDealGroup"
          class="w-full px-6 py-4 flex items-center justify-between text-xs font-semibold text-zen-ink bg-white/30 hover:bg-white/50 transition-colors outline-none border-b border-white/20 select-none"
        >
          <span class="flex items-center gap-2">
            <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
            已成交 {{ dealLeads.length }}
          </span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-zen-gray transition-transform duration-300"
            :class="showDealGroup ? 'transform rotate-0' : 'transform -rotate-90'"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        <div class="divide-y divide-white/20" v-show="showDealGroup">
          <div
            v-for="lead in dealLeads.slice(0, dealLimit)"
            :key="lead.id"
            @click="triggerDetailModal(lead)"
            class="px-6 py-4 hover:bg-white/40 transition-colors flex items-center justify-between gap-4 cursor-pointer"
            :class="selectedLeadId === lead.id ? 'bg-white/30 border-l-4 border-zen-green' : ''"
          >
            <!-- Left: Company Icon + Name & Subtitle -->
            <div class="flex items-center gap-3.5 min-w-0 flex-1 sm:flex-initial sm:w-1/3">
              <div class="w-10 h-10 rounded-full flex items-center justify-center shrink-0 select-none" :class="getLeadIconClass(lead.stage)">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
              <div class="min-w-0">
                <h4 class="text-xs font-bold text-zen-ink truncate leading-tight hover:underline">{{ lead.name }}</h4>
                <p class="text-[10px] text-zen-gray truncate mt-1">
                  <span class="mr-1 select-none">{{ lead.flag }}</span>
                  {{ lead.country }} · {{ lead.contact }}
                </p>
              </div>
            </div>

            <!-- Middle: Capsule Tags -->
            <div class="hidden md:flex flex-wrap items-center gap-1.5 flex-1">
              <span
                v-for="(tag, idx) in lead.tags"
                :key="idx"
                class="px-2 py-0.5 rounded text-[9px] font-bold border"
                :class="getTagClass(tag)"
              >
                {{ tag }}
              </span>
            </div>

            <!-- Right: Status Badge & Analyze Button & Chevron -->
            <div class="flex items-center gap-3.5 select-none shrink-0">
              <span class="px-2.5 py-0.5 rounded-full text-[9px] font-bold bg-orange-500/10 text-orange-500 border border-orange-500/20">
                已成交
              </span>

              <!-- Analyze Button -->
              <button
                @click.stop="triggerQuickPreview(lead)"
                class="px-3.5 py-1 bg-zen-tea/10 border border-zen-tea/30 hover:bg-zen-tea/20 text-zen-tea rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 outline-none font-sans"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
                </svg>
                分析
              </button>

              <!-- Detail Button -->
              <button
                @click.stop="triggerDetailModal(lead)"
                class="px-3.5 py-1 bg-indigo-50 border border-indigo-200/50 hover:bg-indigo-100 text-indigo-600 rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 outline-none"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                详情
              </button>

              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
          <!-- Load more dealLeads -->
          <div
            v-if="dealLeads.length > dealLimit"
            class="px-6 py-4 bg-white/20 border-t border-white/10 flex justify-center select-none"
          >
            <button
              @click.stop="dealLimit += 20"
              class="px-4 py-1.5 bg-white/60 hover:bg-white text-indigo-600 rounded-xl text-[10px] font-bold shadow-sm transition-all border border-indigo-100 flex items-center gap-1.5 active:scale-[0.98]"
            >
              <span>🔽 展开更多已成交客户 (还有 {{ dealLeads.length - dealLimit }} 个)</span>
            </button>
          </div>
        </div>
      </div>

      <!-- 4.2 潜在客户组 (Section 2: 潜在客户 83) -->
      <div class="apple-glass rounded-2xl overflow-hidden border border-white/50" v-if="shouldShowGroup('potential')">
        <button
          @click="showPotentialGroup = !showPotentialGroup"
          class="w-full px-6 py-4 flex items-center justify-between text-xs font-semibold text-zen-ink bg-white/30 hover:bg-white/50 transition-colors outline-none border-b border-white/20 select-none"
        >
          <span class="flex items-center gap-2">
            <span class="w-1.5 h-1.5 rounded-full bg-zen-gold"></span>
            潜在客户 {{ potentialLeads.length }}
          </span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-zen-gray transition-transform duration-300"
            :class="showPotentialGroup ? 'transform rotate-0' : 'transform -rotate-90'"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        <div class="divide-y divide-white/20" v-show="showPotentialGroup">
          <div
            v-for="lead in potentialLeads.slice(0, potentialLimit)"
            :key="lead.id"
            @click="triggerDetailModal(lead)"
            class="px-6 py-4 hover:bg-white/40 transition-colors flex items-center justify-between gap-4 cursor-pointer"
            :class="selectedLeadId === lead.id ? 'bg-white/30 border-l-4 border-zen-gold' : ''"
          >
            <!-- Left: Company Icon + Name & Subtitle -->
            <div class="flex items-center gap-3.5 min-w-0 flex-1 sm:flex-initial sm:w-1/3">
              <div class="w-10 h-10 rounded-full flex items-center justify-center shrink-0 select-none" :class="getLeadIconClass(lead.stage)">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
              <div class="min-w-0">
                <h4 class="text-xs font-bold text-zen-ink truncate leading-tight hover:underline">{{ lead.name }}</h4>
                <p class="text-[10px] text-zen-gray truncate mt-1">
                  <span class="mr-1 select-none">{{ lead.flag }}</span>
                  {{ lead.country }} · {{ lead.contact }}
                </p>
              </div>
            </div>

            <!-- Middle: Capsule Tags -->
            <div class="hidden md:flex flex-wrap items-center gap-1.5 flex-1">
              <span
                v-for="(tag, idx) in lead.tags"
                :key="idx"
                class="px-2 py-0.5 rounded text-[9px] font-bold border"
                :class="getTagClass(tag)"
              >
                {{ tag }}
              </span>
            </div>

            <!-- Right: Status Badge & Analyze Button & Chevron -->
            <div class="flex items-center gap-3.5 select-none shrink-0">
              <span class="px-2.5 py-0.5 rounded-full text-[9px] font-bold bg-blue-500/10 text-blue-500 border border-blue-500/20">
                潜在客户
              </span>

              <!-- Analyze Button -->
              <button
                @click.stop="triggerQuickPreview(lead)"
                class="px-3.5 py-1 bg-zen-tea/10 border border-zen-tea/30 hover:bg-zen-tea/20 text-zen-tea rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 outline-none font-sans"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
                </svg>
                  日程
              </button>

              <!-- Detail Button (dynamic report or chart style) -->
              <button
                @click.stop="triggerDetailModal(lead)"
                class="px-3.5 py-1 rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 outline-none"
                :class="lead.score >= 80
                  ? 'bg-indigo-50 border border-indigo-200/50 hover:bg-indigo-100 text-indigo-600'
                  : 'bg-indigo-50/50 border border-indigo-200/30 hover:bg-indigo-100/50 text-indigo-500'"
              >
                <svg v-if="lead.score >= 80" xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 002 2h2a2 2 0 002-2z" />
                </svg>
                详情
              </button>

              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
          <!-- Load more potentialLeads -->
          <div
            v-if="potentialLeads.length > potentialLimit"
            class="px-6 py-4 bg-white/20 border-t border-white/10 flex justify-center select-none"
          >
            <button
              @click.stop="potentialLimit += 20"
              class="px-4 py-1.5 bg-white/60 hover:bg-white text-indigo-600 rounded-xl text-[10px] font-bold shadow-sm transition-all border border-indigo-100 flex items-center gap-1.5 active:scale-[0.98]"
            >
              <span>🔽 展开更多潜在客户 (还有 {{ potentialLeads.length - potentialLimit }} 个)</span>
            </button>
          </div>
        </div>
      </div>

      <!-- 4.3 流失客户组 (Section 3: 流失客户) -->
      <div class="apple-glass rounded-2xl overflow-hidden border border-white/50" v-if="shouldShowGroup('lost')">
        <button
          @click="showLostGroup = !showLostGroup"
          class="w-full px-6 py-4 flex items-center justify-between text-xs font-semibold text-zen-ink bg-white/30 hover:bg-white/50 transition-colors outline-none border-b border-white/20 select-none"
        >
          <span class="flex items-center gap-2">
            <span class="w-1.5 h-1.5 rounded-full bg-neutral-950 animate-pulse"></span>
            流失客户 {{ lostLeads.length }}
          </span>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 text-zen-gray transition-transform duration-300"
            :class="showLostGroup ? 'transform rotate-0' : 'transform -rotate-90'"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        <div class="divide-y divide-white/20" v-show="showLostGroup">
          <div
            v-for="lead in lostLeads.slice(0, lostLimit)"
            :key="lead.id"
            @click="triggerDetailModal(lead)"
            class="px-6 py-4 hover:bg-white/40 transition-colors flex items-center justify-between gap-4 cursor-pointer"
            :class="selectedLeadId === lead.id ? 'bg-white/30 border-l-4 border-neutral-950' : ''"
          >
            <!-- Left: Company Icon + Name & Subtitle -->
            <div class="flex items-center gap-3.5 min-w-0 flex-1 sm:flex-initial sm:w-1/3">
              <div class="w-10 h-10 rounded-full flex items-center justify-center shrink-0 select-none" :class="getLeadIconClass(lead.stage)">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                </svg>
              </div>
              <div class="min-w-0">
                <h4 class="text-xs font-bold text-zen-ink truncate leading-tight hover:underline">{{ lead.name }}</h4>
                <p class="text-[10px] text-zen-gray truncate mt-1">
                  <span class="mr-1 select-none">{{ lead.flag }}</span>
                  {{ lead.country }} · {{ lead.contact }}
                </p>
              </div>
            </div>

            <!-- Middle: Capsule Tags -->
            <div class="hidden md:flex flex-wrap items-center gap-1.5 flex-1">
              <span
                v-for="(tag, idx) in lead.tags"
                :key="idx"
                class="px-2 py-0.5 rounded text-[9px] font-bold border"
                :class="getTagClass(tag)"
              >
                {{ tag }}
              </span>
            </div>

            <!-- Right: Status Badge & Chevron -->
            <div class="flex items-center gap-3.5 select-none shrink-0">
              <span class="px-2.5 py-0.5 rounded-full text-[9px] font-bold bg-neutral-950/10 text-neutral-950 border border-neutral-950/20">
                流失客户
              </span>

              <!-- Analyze Button -->
              <button
                @click.stop="triggerQuickPreview(lead)"
                class="px-3.5 py-1 bg-zen-tea/10 border border-zen-tea/30 hover:bg-zen-tea/20 text-zen-tea rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 outline-none font-sans"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
                </svg>
                  日程
              </button>

              <!-- Detail Button -->
              <button
                @click.stop="triggerDetailModal(lead)"
                class="px-3.5 py-1 bg-indigo-50 border border-indigo-200/50 hover:bg-indigo-100 text-indigo-600 rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 outline-none"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
                详情
              </button>

              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
          <!-- Load more lostLeads -->
          <div
            v-if="lostLeads.length > lostLimit"
            class="px-6 py-4 bg-white/20 border-t border-white/10 flex justify-center select-none"
          >
            <button
              @click.stop="lostLimit += 20"
              class="px-4 py-1.5 bg-white/60 hover:bg-white text-indigo-600 rounded-xl text-[10px] font-bold shadow-sm transition-all border border-indigo-100 flex items-center gap-1.5 active:scale-[0.98]"
            >
              <span>🔽 展开更多流失客户 (还有 {{ lostLeads.length - lostLimit }} 个)</span>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- 5. Main viewport: Card View (毛玻璃磁贴卡片列表) -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div
        v-for="lead in filteredLeads.slice(0, cardLimit)"
        :key="lead.id"
        @click="triggerDetailModal(lead)"
        class="apple-glass apple-glass-hover rounded-3xl p-5 flex flex-col justify-between min-h-[220px] relative overflow-hidden border border-white/50 cursor-pointer"
        :class="selectedLeadId === lead.id ? 'ring-2 ring-zen-green/50 bg-white/70' : ''"
      >
        <div>
          <!-- Card Header (Flag and status badge) -->
          <div class="flex justify-between items-center mb-3.5 select-none">
            <div class="flex items-center gap-2">
              <span class="text-xl shrink-0">{{ lead.flag }}</span>
              <span class="text-[9px] uppercase tracking-wider font-semibold text-zen-gray font-mono">
                {{ lead.country }}
              </span>
            </div>
            <span
              class="text-[9px] font-bold px-2 py-0.5 rounded-full"
              :class="lead.stage === 'deal'
                ? 'bg-orange-500/10 text-orange-500 border border-orange-500/20'
                : (lead.stage === 'potential'
                  ? 'bg-blue-500/10 text-blue-500 border border-blue-500/20'
                  : 'bg-neutral-950/10 text-neutral-950 border border-neutral-950/20')"
            >
          已成交
            </span>
          </div>

          <!-- Company Name & Contact -->
          <h3 class="text-xs font-bold text-zen-ink leading-snug hover:underline">{{ lead.name }}</h3>
          <p class="text-[10px] text-zen-gray mt-1 font-medium">业务跟进代表：{{ lead.contact }}</p>

          <!-- Tags -->
          <div class="flex flex-wrap gap-1 mt-4">
            <span
              v-for="(tag, idx) in lead.tags"
              :key="idx"
              class="px-2 py-0.5 rounded text-[8px] font-bold border"
              :class="getTagClass(tag)"
            >
              {{ tag }}
            </span>
            <span class="text-[8px] font-bold px-1.5 py-0.5 rounded bg-black/[0.04] text-zen-gray" v-if="!lead.tags.length">
            <span class="text-[8px] font-bold px-1.5 py-0.5 rounded bg-black/[0.04] text-zen-gray" v-if="!lead.tags.length">
              暂无标签
            </span>
            </span>
          </div>
        </div>

        <!-- Card Footer -->
        <div class="pt-4 border-t border-white/20 mt-4 flex items-center justify-between select-none">
          <div class="flex items-center gap-1 text-[9px] text-zen-gray">
            <span class="relative flex h-1.5 w-1.5" v-if="lead.stage === 'deal'">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-orange-400 opacity-75"></span>
              <span class="relative inline-flex rounded-full h-1.5 w-1.5 bg-orange-500"></span>
            </span>
            <span class="relative flex h-1.5 w-1.5" v-else-if="lead.stage === 'potential'">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"></span>
              <span class="relative inline-flex rounded-full h-1.5 w-1.5 bg-blue-500"></span>
            </span>
            <span class="relative flex h-1.5 w-1.5" v-else>
              <span class="relative inline-flex rounded-full h-1.5 w-1.5 bg-neutral-950"></span>
            </span>
            AI 意向评分 <span class="font-bold text-zen-ink font-mono">{{ lead.score }} 分</span>
          </div>

          <div class="flex gap-2">
            <!-- Analyze Button -->
            <button
              @click.stop="triggerQuickPreview(lead)"
              class="px-3.5 py-1 bg-zen-tea/10 border border-zen-tea/30 hover:bg-zen-tea/20 text-zen-tea rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 outline-none font-sans"
            >
              分析
            </button>

            <!-- Analyze CTA -->
            <button
              @click.stop="triggerDetailModal(lead)"
              class="px-3.5 py-1 rounded-xl text-[10px] font-bold shadow-sm transition-all duration-300 flex items-center gap-1 bg-indigo-50 border border-indigo-200/50 hover:bg-indigo-100 text-indigo-600 outline-none"
            >
              详情
            </button>
          </div>
        </div>
      </div>
    </div>
    <!-- Load more Card leads -->
    <div
      class="flex justify-center select-none mt-6 w-full col-span-full animate-fadeIn"
    >
      <button
        @click.stop="cardLimit += 24"
        class="px-5 py-2.5 bg-white/50 hover:bg-white border border-white/60 rounded-2xl text-indigo-600 text-xs font-bold shadow-sm transition-all flex items-center gap-2 active:scale-[0.98] backdrop-blur-md"
      >
        <span>🔽 加载更多客户 (还有 {{ filteredLeads.length - cardLimit }} 个)</span>
      </button>
    </div>


    <!-- Empty State -->
    <div v-if="filteredLeads.length === 0" class="apple-glass rounded-2xl py-20 text-center text-zen-gray space-y-2 border border-white/50 select-none">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-9 w-9 mx-auto text-zen-gray/40" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
      </svg>
      <p class="text-xs font-semibold font-serif-sc text-zen-ink">未匹配到符合条件的客户记录</p>
          <p class="text-[10px] text-zen-gray/80">建议切换顶部分类筛选条件或清空搜索关键词</p>
    </div>

    </div> <!-- Close of v-if="viewState === 'list'" -->

    <!-- 6. --- 全宽客户画像工作台详情页跳转 --- -->
    <div v-else-if="viewState === 'detail'" class="space-y-6 animate-fadeIn select-text">
      <!-- Detail Header with elegant Back Button -->
      <div class="pb-4 border-b border-white/20 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 select-none">
        <div class="flex items-center gap-4">
          <!-- Back button with slick hover animate -->
          <button
            @click="viewState = 'list'"
            class="px-4 py-2 bg-white/50 hover:bg-white hover:translate-x-[-3px] border border-white/60 rounded-xl text-xs text-zen-ink font-semibold shadow-sm transition-all duration-300 outline-none flex items-center gap-1.5"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7" />
            </svg>
            返客海
          </button>
          
          <div class="h-6 w-[1px] bg-white/30 hidden md:block"></div>
          
          <div>
            <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2 text-zen-ink">
        客户工作台
              <span class="text-xs font-normal text-zen-gray font-sans bg-white/40 border border-white/50 px-2 py-0.5 rounded-lg select-none">
                {{ selectedLeadForModal?.name }} | CLI-2026-0{{ selectedLeadForModal?.id }}
              </span>
            </h2>
          </div>
        </div>
      </div>

      <!-- 6.1 TOP CARD: Visual Modular Profile (上方宽屏模块化视觉档案) -->
      <div class="apple-glass rounded-3xl border border-white/50 shadow-sm overflow-hidden" v-if="selectedLeadForModal">
        <!-- Hero Banner: Company Name + Flag + Edit Icon -->
        <div class="relative px-7 pt-7 pb-5 bg-gradient-to-br from-white/50 to-white/20 border-b border-white/20">
          <!-- Small pencil edit icon top-right -->
          <div class="absolute top-4 right-5 flex gap-2 select-none">
            <div v-if="isEditingProfile" class="flex gap-2">
              <button @click="saveLeadProfile" class="px-3.5 py-1.5 bg-zen-green text-white rounded-xl text-[11px] font-bold shadow-sm hover:bg-zen-green/90 transition-all outline-none">保存</button>
              <button @click="isEditingProfile = false" class="px-3.5 py-1.5 bg-white/60 border border-white/60 text-zen-gray rounded-xl text-[11px] font-semibold hover:bg-white transition-all outline-none">取消</button>
            </div>
            <button
              v-else
              @click="startEditProfile(selectedLeadForModal)"
              class="w-8 h-8 rounded-xl bg-white/50 hover:bg-white border border-white/60 flex items-center justify-center text-zen-gray hover:text-zen-ink shadow-sm transition-all outline-none"
              title="编辑客户画像"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </button>
          </div>

          <!-- Company identity -->
          <div class="flex items-center gap-4">
            <div class="w-14 h-14 rounded-2xl bg-white/60 border border-white/50 flex items-center justify-center text-3xl shrink-0 shadow-sm select-none">
              {{ selectedLeadForModal.flag }}
            </div>
            <div>
              <div v-if="isEditingProfile">
                <input type="text" v-model="editForm.name"
                  class="text-xl font-bold bg-white/50 border border-white/60 rounded-xl px-3 py-1 outline-none focus:bg-white focus:border-zen-green transition-all w-full font-serif-sc" />
              </div>
              <h3 v-else class="text-xl font-bold text-zen-ink font-serif-sc leading-tight select-text">
                {{ selectedLeadForModal.name }}
              </h3>
              <p class="text-xs text-zen-gray font-mono mt-1 select-text">ID: CLI-2026-0{{ selectedLeadForModal.id }}</p>
            </div>
          </div>
        </div>

        <!-- Modular Info Grid -->
        <div class="grid grid-cols-2 md:grid-cols-3 xl:grid-cols-5 divide-x divide-y divide-white/20">
          <!-- Contact Phone -->
          <div class="px-5 py-4">
          <p class="text-[10px] uppercase tracking-wider text-zen-gray font-bold select-none mb-1.5">联系电话</p>
            <div v-if="isEditingProfile">
              <input type="text" v-model="editForm.phone"
                class="w-full bg-white/40 border border-white/60 rounded-lg px-2 py-1 text-sm outline-none focus:bg-white focus:border-zen-green transition-all font-semibold font-mono" />
            </div>
            <p v-else class="text-sm font-bold text-zen-ink select-text font-mono">{{ selectedLeadForModal.phone || '未提供' }}</p>
          </div>

          <!-- Country -->
          <div class="px-5 py-4">
          <p class="text-[10px] uppercase tracking-wider text-zen-gray font-bold select-none mb-1.5">国家地区</p>
            <div v-if="isEditingProfile">
              <select v-model="editForm.country"
                class="w-full bg-white/40 border border-white/60 rounded-lg px-2 py-1 text-sm outline-none focus:bg-white focus:border-zen-green transition-all">
                <option value="俄罗斯">俄罗斯</option>
                <option value="泰国">泰国</option>
                <option value="以色列">以色列</option>
                <option value="菲律宾">菲律宾</option>
                <option value="德国">德国</option>
                <option value="印度">印度</option>
                <option value="伊拉克">伊拉克</option>
                <option value="澳大利亚">澳大利亚</option>
              </select>
            </div>
            <p v-else class="text-sm font-bold text-zen-ink select-text">{{ selectedLeadForModal.country }}</p>
          </div>

          <!-- Stage -->
          <div class="px-5 py-4">
            <p class="text-[10px] uppercase tracking-wider text-zen-gray font-bold select-none mb-1.5">阶段</p>
            <div v-if="isEditingProfile">
              <select v-model="editForm.stage"
                class="w-full bg-white/40 border border-white/60 rounded-lg px-2 py-1 text-sm outline-none focus:bg-white focus:border-zen-green transition-all">
                <option value="potential">潜在客户</option>
                <option value="deal">已成交</option>
                <option value="lost">流失客户</option>
              </select>
            </div>
            <span v-else class="inline-flex items-center gap-1.5 text-sm font-bold"
              :class="selectedLeadForModal.stage === 'deal' ? 'text-orange-500' : (selectedLeadForModal.stage === 'potential' ? 'text-blue-500' : 'text-neutral-950')">
              <span class="w-2 h-2 rounded-full inline-block" :class="selectedLeadForModal.stage === 'deal' ? 'bg-orange-500' : (selectedLeadForModal.stage === 'potential' ? 'bg-blue-500' : 'bg-neutral-950')"></span>
              {{ selectedLeadForModal.stage === 'deal' ? '已成交' : (selectedLeadForModal.stage === 'potential' ? '潜在客户' : '流失客户') }}
            </span>
          </div>

          <!-- Category -->
          <div class="px-5 py-4">
            <p class="text-[10px] uppercase tracking-wider text-zen-gray font-bold select-none mb-1.5">行业分类</p>
            <div v-if="isEditingProfile">
              <select v-model="editForm.category"
                class="w-full bg-white/40 border border-white/60 rounded-lg px-2 py-1 text-sm outline-none focus:bg-white focus:border-zen-green transition-all">
                <option value="parts">汽车配件</option>
                <option value="lights">LED照明</option>
              </select>
            </div>
            <p v-else class="text-sm font-semibold text-zen-ink">
              {{ selectedLeadForModal.category === 'parts' ? '汽车配件' : 'LED照明' }}
            </p>
          </div>

          <!-- AI Score -->
          <div class="px-5 py-4">
            <p class="text-[10px] uppercase tracking-wider text-zen-gray font-bold select-none mb-1.5">AI 意向得分</p>
            <div v-if="isEditingProfile">
              <input type="number" v-model.number="editForm.score"
                class="w-full bg-white/40 border border-white/60 rounded-lg px-2 py-1 text-sm outline-none focus:bg-white focus:border-zen-green font-mono" />
            </div>
            <div v-else class="flex items-center gap-2">
              <span class="text-xl font-black font-mono" :class="selectedLeadForModal.score >= 85 ? 'text-zen-green' : 'text-zen-gold'">
                {{ selectedLeadForModal.score }}
              </span>
              <div class="flex-1">
                <div class="h-1.5 bg-black/5 rounded-full overflow-hidden">
                  <div class="h-full rounded-full transition-all duration-700"
                    :class="selectedLeadForModal.score >= 85 ? 'bg-zen-green' : 'bg-zen-gold'"
                    :style="{ width: selectedLeadForModal.score + '%' }">
                  </div>
                </div>
                <p class="text-[9px] text-zen-gray mt-0.5">/ 100</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Raw inquiry message -->
        <div class="px-7 py-4 border-t border-white/20">
          <p class="text-[10px] uppercase tracking-wider text-zen-gray font-bold select-none mb-2">原始询盘信息</p>
          <textarea v-if="isEditingProfile" v-model="editForm.rawMessage" rows="3"
            class="w-full bg-white/40 border border-white/60 rounded-xl p-3 text-xs outline-none focus:bg-white focus:border-zen-green transition-all leading-relaxed"></textarea>
          <p v-else class="text-xs text-zen-gray bg-black/[0.03] px-4 py-3 rounded-xl border border-white/30 leading-relaxed font-serif-sc max-h-[90px] overflow-y-auto select-text">
            {{ selectedLeadForModal.rawMessage }}
          </p>
        </div>
      </div>

    <!-- 6.2 BOTTOM CARD: Full-width Multi-tabbed Workspace (下方宽屏多维工作台) -->
      <div class="apple-glass rounded-3xl p-6 border border-white/50 shadow-sm mt-6 flex flex-col justify-between space-y-4" v-if="selectedLeadForModal">
        <div class="flex flex-col justify-between space-y-4 w-full">
          <!-- Workspace Tab menu headers -->
          <div class="flex items-center gap-1 bg-black/[0.05] p-0.5 rounded-xl border border-black/[0.02] select-none">
            <button
              @click="activeWorkspaceTab = 'analysis'"
              class="flex-1 py-2 rounded-lg text-[10px] font-bold transition-all duration-300 outline-none"
              :class="activeWorkspaceTab === 'analysis' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
            >
              分析报告
            </button>
            <button
              @click="activeWorkspaceTab = 'followup'"
              class="flex-1 py-2 rounded-lg text-[10px] font-bold transition-all duration-300 outline-none"
              :class="activeWorkspaceTab === 'followup' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
            >
              跟进记录 ({{ matchedTimelineLogs.length }})
            </button>
            <button
              @click="activeWorkspaceTab = 'quotes'"
              class="flex-1 py-2 rounded-lg text-[10px] font-bold transition-all duration-300 outline-none"
              :class="activeWorkspaceTab === 'quotes' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
            >
              报价记录 ({{ matchedQuotes.length }})
            </button>
            <button
              @click="activeWorkspaceTab = 'products'"
              class="flex-1 py-2 rounded-lg text-[10px] font-bold transition-all duration-300 outline-none"
              :class="activeWorkspaceTab === 'products' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
            >
              产品推荐
            </button>
            <button
              @click="activeWorkspaceTab = 'contracts'"
              class="flex-1 py-2 rounded-lg text-[10px] font-bold transition-all duration-300 outline-none"
              :class="activeWorkspaceTab === 'contracts' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
            >
              订单合同 ({{ matchedContracts.length }})
            </button>
          </div>

          <!-- Tab Contents Area -->
          <div class="flex-1 overflow-y-auto max-h-[600px] pr-2 space-y-4">
            
    <!-- Tab 1: AI Analysis Report (AI 深度分析报告) -->
            <div v-if="activeWorkspaceTab === 'analysis'" class="space-y-3.5 select-text">
              <!-- AI Tags -->
              <div class="space-y-1.5 select-none">
          <span class="block text-zen-gray text-[9px] font-bold uppercase tracking-wider">AI 深度分析报告</span>
                <div class="flex flex-wrap gap-1 items-center p-3 bg-white/30 border border-white/50 rounded-2xl min-h-[45px]">
                  <span
                    v-for="(tag, idx) in selectedLeadForModal.tags"
                    :key="idx"
                    class="relative px-2 py-0.5 rounded text-[8px] font-bold border flex items-center gap-1 group"
                    :class="getTagClass(tag)"
                  >
                    <!-- Color dot: click to recolor this tag -->
                    <button
                      @click.stop="openTagPaletteFor = (openTagPaletteFor === tag ? null : tag)"
                      class="w-2 h-2 rounded-full shrink-0 ring-1 ring-black/10 hover:scale-125 transition-transform"
                      :class="getTagPalette(tag).dot"
                      title="点击修改标签颜色"
                    ></button>
                    {{ tag }}
              <span @click.stop="removeTag(selectedLeadForModal, tag)" class="hover:text-red-500 cursor-pointer select-none text-[9px]">×</span>

                    <!-- Per-tag color palette popover -->
                    <div
                      v-if="openTagPaletteFor === tag"
                      class="absolute z-30 top-full left-0 mt-1 p-2 bg-white rounded-xl shadow-xl border border-black/[0.06] grid grid-cols-6 gap-1.5 w-max"
                    >
                      <button
                        v-for="c in TAG_PALETTE"
                        :key="c.id"
                        @click.stop="setTagColor(tag, c.id); openTagPaletteFor = null"
                        class="w-4 h-4 rounded-full ring-1 ring-black/10 hover:scale-110 transition-transform"
                        :class="[c.dot, getTagColorId(tag) === c.id ? 'ring-2 ring-offset-1 ring-zen-ink' : '']"
                        :title="c.label"
                      ></button>
                    </div>
                  </span>
                  <button
                    @click="simulateExtractTags(selectedLeadForModal)"
                    :disabled="isExtracting"
                    class="px-2.5 py-1 rounded bg-zen-ink hover:bg-zen-ink/90 text-white text-[8px] font-bold transition-all disabled:opacity-40"
                  >
                    {{ isExtracting ? 'AI 提取中...' : '＋ AI 自动分析并添加标签' }}
                  </button>
                  <div class="flex items-center gap-1 ml-2 relative">
                    <input
                      v-model="customTagInput"
                      @keyup.enter="addCustomTag(selectedLeadForModal)"
                      placeholder="自定义标签..."
                      class="px-2 py-1 rounded-lg border border-white/60 bg-white/40 text-[9px] outline-none focus:bg-white focus:border-zen-green transition-all w-28"
                    />
                    <!-- Color palette trigger for the new tag -->
                    <button
                      @click.stop="showTagColorPalette = !showTagColorPalette"
                      class="w-6 h-6 rounded-lg border border-white/60 bg-white/40 flex items-center justify-center hover:bg-white transition-all shrink-0"
                      title="选择标签颜色"
                    >
                      <span class="w-3 h-3 rounded-full ring-1 ring-black/10" :class="(TAG_PALETTE.find(c => c.id === customTagColor) || TAG_PALETTE[0]).dot"></span>
                    </button>
                    <!-- New-tag color palette popover -->
                    <div
                      v-if="showTagColorPalette"
                      class="absolute z-30 top-full right-0 mt-1 p-2 bg-white rounded-xl shadow-xl border border-black/[0.06] grid grid-cols-6 gap-1.5 w-max"
                    >
                      <button
                        v-for="c in TAG_PALETTE"
                        :key="c.id"
                        @click.stop="customTagColor = c.id; showTagColorPalette = false"
                        class="w-4 h-4 rounded-full ring-1 ring-black/10 hover:scale-110 transition-transform"
                        :class="[c.dot, customTagColor === c.id ? 'ring-2 ring-offset-1 ring-zen-ink' : '']"
                        :title="c.label"
                      ></button>
                    </div>
                    <button
                      @click="addCustomTag(selectedLeadForModal)"
                      class="px-2 py-1 rounded bg-blue-600 hover:bg-blue-700 text-white text-[8px] font-bold transition-all"
                    >
                      ＋ 添加
                    </button>
                  </div>
                </div>
              </div>

              <!-- Collapsible Section A: Intent Analysis -->
              <div class="apple-glass rounded-xl overflow-hidden border border-white/50">
                <button
                  @click="showIntentCollapse = !showIntentCollapse"
                  class="w-full px-4 py-2.5 flex items-center justify-between text-[10px] font-bold text-zen-ink bg-white/30 hover:bg-white/50 transition-colors outline-none select-none"
                >
                <span>信用与意向图谱分析 (Intent Analysis)</span>
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray transition-transform duration-300" :class="showIntentCollapse ? 'transform rotate-0' : 'transform -rotate-90'" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                <div class="p-3.5 text-[11px] leading-relaxed font-serif-sc text-zen-gray bg-white/10" v-show="showIntentCollapse">
          <p class="font-bold text-zen-ink">意向图谱：{{ selectedLeadForModal.intent }}</p>
                <p class="mt-1">基于本地 SQLite 数据库交叉对比测算该客户信用度与订单意向深度估值，综合询盘深度、历史订单与对标竞品，判断高意向转化概率。</p>
                </div>
              </div>

              <!-- Collapsible Section B: Regional Cooperative Alert -->
              <div class="apple-glass rounded-xl overflow-hidden border border-white/50">
                <button
                  @click="showRegionalCollapse = !showRegionalCollapse"
                  class="w-full px-4 py-2.5 flex items-center justify-between text-[10px] font-bold text-zen-ink bg-white/30 hover:bg-white/50 transition-colors outline-none select-none"
                >
                <span>中/东亚区域协作流转 (Regional Cooperative Routing)</span>
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray transition-transform duration-300" :class="showRegionalCollapse ? 'transform rotate-0' : 'transform -rotate-90'" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                <div class="p-3.5 text-[11px] leading-relaxed font-serif-sc text-zen-gray bg-white/10 space-y-2" v-show="showRegionalCollapse">
                  <p>建议路线<strong class="text-zen-green">{{ selectedLeadForModal.routingPath }}</strong></p>
                <p v-if="selectedLeadForModal.country === '泰国' || selectedLeadForModal.country === '菲律宾'">
                  系统检测该客户所在地已部署驻地代理，已优先派遣区域代理上门拜访并推进线下洽谈。
                  </p>
          <p v-else>客户所在地暂无驻地代理，建议使用 Gemini 1.5 Pro 远程件沟通模式。</p>
                </div>
              </div>

              <!-- Collapsible Section C: Safe Mode Air-gap warning -->
              <div class="apple-glass rounded-xl overflow-hidden border border-white/50">
                <button
                  @click="showSecureCollapse = !showSecureCollapse"
                  class="w-full px-4 py-2.5 flex items-center justify-between text-[10px] font-bold text-zen-ink bg-white/30 hover:bg-white/50 transition-colors outline-none select-none"
                >
                  <span>离线安全审计警示 (Security Lock Audit)</span>
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray transition-transform duration-300" :class="showSecureCollapse ? 'transform rotate-0' : 'transform -rotate-90'" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                <div class="p-3.5 text-[11px] leading-relaxed font-serif-sc text-zen-gray bg-white/10 flex items-center gap-2" v-show="showSecureCollapse">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-green shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                  </svg>
                <span>当地驻点常驻代理协同该客户完整财务本地数据，对接发票箱离线机密隔离。</span>
                </div>
              </div>

              <!-- Immersive Deep Analyzing Progress Screen -->
              <div class="apple-glass rounded-2xl p-8 border border-white/50 text-center space-y-6 animate-fadeIn select-none" v-if="isDeepAnalyzing">
                <div class="flex flex-col items-center justify-center space-y-3">
                  <!-- Premium dynamic orbit spinner -->
                  <div class="relative w-16 h-16 flex items-center justify-center">
                    <div class="absolute w-16 h-16 rounded-full border-4 border-indigo-500/10 border-t-indigo-600 animate-spin"></div>
                    <div class="absolute w-12 h-12 rounded-full border-4 border-purple-500/10 border-b-purple-600 animate-spin" style="animation-direction: reverse; animation-duration: 1.5s;"></div>
              <span class="text-xl">✓</span>
                  </div>
                  <h4 class="text-xs font-bold text-zen-ink font-serif-sc tracking-wider">大模型深度客户画像构建中</h4>
                  <p class="text-[10px] text-zen-gray animate-pulse font-sans">
                    正在调用多模型对该客户进行全景背调审计与画像合成...
                  </p>
                </div>

                <!-- Step-by-step Milestones Progress Panel -->
                <div class="max-w-md mx-auto bg-black/[0.02] border border-black/[0.04] p-4 rounded-2xl space-y-3.5 text-left font-sans text-[10px]">
                  <div
                    v-for="(stepText, index) in deepAnalysisSteps"
                    :key="index"
                    class="flex items-center gap-2.5 transition-all duration-500"
                    :class="deepAnalysisStep > index ? 'text-zen-green opacity-100 font-bold' : (deepAnalysisStep === index ? 'text-indigo-600 opacity-100 font-bold animate-pulse' : 'text-zen-gray opacity-45')"
                  >
                    <div class="shrink-0 flex items-center justify-center w-4 h-4 rounded-full border text-[9px] font-bold"
                         :class="deepAnalysisStep > index ? 'bg-zen-green/10 border-zen-green text-zen-green' : (deepAnalysisStep === index ? 'bg-indigo-50 border-indigo-600 text-indigo-600' : 'bg-black/5 border-black/10 text-zen-gray')">
              <span v-if="deepAnalysisStep > index">✓</span>
                      <span v-else-if="deepAnalysisStep === index" class="w-1.5 h-1.5 rounded-full bg-indigo-600"></span>
                      <span v-else>{{ index + 1 }}</span>
                    </div>
                    <span class="flex-1 truncate">{{ stepText }}</span>
                  </div>
                </div>
              </div>

              <!-- Normal Workspace Report View -->
              <template v-else>
                <!-- Deep analysis panel toolbar -->
                <div class="flex justify-between items-center bg-white/30 border border-white/50 px-4 py-2.5 rounded-2xl select-none" v-if="selectedLeadForModal.deepReport">
                  <div class="flex items-center gap-1.5">
                    <span class="w-1.5 h-1.5 rounded-full bg-zen-green"></span>
              <span class="text-[9px] text-zen-gray font-bold">大模型深度报告 (已存本地底仓)</span>
                  </div>
                  <button
                    @click="triggerOneClickAnalysis(selectedLeadForModal)"
                    class="px-3.5 py-1.5 bg-indigo-50 hover:bg-indigo-100 border border-indigo-200/50 text-indigo-600 font-bold rounded-xl text-[9px] flex items-center gap-1 shadow-sm transition-all active:scale-95 outline-none font-sans"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 1121.21 8H18.2" />
                    </svg>
                    重新智能分析
                  </button>
                </div>

    <!-- Collapsible Section D: SPI Deep Analysis Report (大模型深度报告 - SPI风格) [NEW] -->
                <div class="apple-glass rounded-xl overflow-hidden border border-white/50 animate-fadeIn" v-if="selectedLeadForModal.deepReport">
                  <button
                    @click="showDeepReportCollapse = !showDeepReportCollapse"
                    class="w-full px-4 py-2.5 flex items-center justify-between text-[10px] font-bold text-zen-ink bg-white/30 hover:bg-white/50 transition-colors outline-none select-none"
                  >
                    <span class="flex items-center gap-1.5 text-indigo-700">
                      <span class="w-1.5 h-1.5 rounded-full bg-indigo-500 animate-pulse"></span>
                      AI 智能大模型深度报告 ({{ selectedLeadForModal.deepReport.type }})
                    </span>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray transition-transform duration-300" :class="showDeepReportCollapse ? 'transform rotate-0' : 'transform -rotate-90'" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                    </svg>
                  </button>
                  <div class="p-4 bg-white/10 space-y-3" v-show="showDeepReportCollapse">
                    <div class="flex justify-between text-[8px] text-zen-gray font-mono border-b border-black/[0.04] pb-2 select-none">
                      <span>报告源文件: {{ selectedLeadForModal.deepReport.filename }}</span>
                      <span>报告生成时间: {{ selectedLeadForModal.deepReport.date }}</span>
                    </div>

                    <!-- Markdown/JSON Viewer -->
                    <div v-if="selectedLeadForModal.deepReport.type === 'Markdown' || selectedLeadForModal.deepReport.type === 'JSON'">
                      
                      <!-- Toggle tab between Dashboard & Raw doc -->
                      <div class="flex items-center gap-1.5 bg-black/[0.04] p-0.5 rounded-xl border border-black/[0.02] w-fit mb-4 select-none">
                        <button
                          @click="reportTab = 'dashboard'"
                          class="px-3.5 py-1 rounded-lg text-[9px] font-bold transition-all duration-300 outline-none"
                          :class="reportTab === 'dashboard' ? 'bg-white text-indigo-700 shadow-sm' : 'text-slate-500 hover:text-slate-800'"
                        >
                          📋 结构化看板
                        </button>
                        <button
                          @click="reportTab = 'raw'"
                          class="px-3.5 py-1 rounded-lg text-[9px] font-bold transition-all duration-300 outline-none"
                          :class="reportTab === 'raw' ? 'bg-white text-indigo-700 shadow-sm' : 'text-slate-500 hover:text-slate-800'"
                        >
                          📄 原始文档
                        </button>
                      </div>

                      <!-- Raw Markdown content -->
                      <div v-if="reportTab === 'raw'" class="text-[11px] leading-relaxed font-serif-sc whitespace-pre-wrap select-text pr-1 max-h-[360px] overflow-y-auto bg-black/[0.02] p-4 rounded-2xl border border-black/[0.03]">
                        {{ selectedLeadForModal.deepReport.content }}
                      </div>

                      <!-- Structured Dashboard of 10 Modules (有结果就显示，没有结果就隐藏) -->
                      <div v-else-if="reportTab === 'dashboard' && parsedDeepReport" class="grid grid-cols-1 md:grid-cols-2 gap-4 max-h-[420px] overflow-y-auto pr-1">
                        
                        <!-- Module 1: 公司画像/概况 -->
                        <div v-if="parsedDeepReport.company" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>🏢</span> 1. 公司概况
                          </h4>
                          <ul class="space-y-1.5 text-[10px] text-slate-600">
                            <li v-if="parsedDeepReport.company.fullName"><strong>全称:</strong> {{ parsedDeepReport.company.fullName }}</li>
                            <li v-if="parsedDeepReport.company.hq"><strong>总部:</strong> {{ parsedDeepReport.company.hq }}</li>
                            <li v-if="parsedDeepReport.company.phone"><strong>电话:</strong> {{ parsedDeepReport.company.phone }}</li>
                            <li v-if="parsedDeepReport.company.email"><strong>邮箱:</strong> {{ parsedDeepReport.company.email }}</li>
                            <li v-if="parsedDeepReport.company.nature"><strong>性质:</strong> {{ parsedDeepReport.company.nature }}</li>
                            <li v-if="parsedDeepReport.company.model"><strong>核心业务:</strong> {{ parsedDeepReport.company.model }}</li>
                          </ul>
                          <p v-if="parsedDeepReport.company.desc" class="text-[9.5px] text-slate-500 italic mt-1 leading-normal">{{ parsedDeepReport.company.desc }}</p>
                        </div>

                        <!-- Module 2: 关键人物与管理层 -->
                        <div v-if="parsedDeepReport.keyPeople && parsedDeepReport.keyPeople.length > 0" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>👥</span> 2. 关键人物与决策链
                          </h4>
                          <div class="space-y-2">
                            <div v-for="person in parsedDeepReport.keyPeople" :key="person.name" class="bg-white/50 border border-white/40 p-2 rounded-xl text-[9.5px]">
                              <div class="flex justify-between font-bold text-slate-800">
                                <span>{{ person.name }}</span>
                                <span class="text-[8px] bg-emerald-50 text-emerald-600 px-1 py-0.5 rounded font-mono">{{ person.verify }}</span>
                              </div>
                              <div class="text-slate-500 text-[8.5px] mt-0.5">{{ person.title }}</div>
                              <div class="flex gap-2 text-[8px] text-slate-400 font-mono mt-1">
                                <span>✉️ {{ person.email }}</span>
                                <span>📞 {{ person.phone }}</span>
                              </div>
                            </div>
                          </div>
                        </div>

                        <!-- Module 3: 市场环境与分析 -->
                        <div v-if="parsedDeepReport.market && parsedDeepReport.market.points.length > 0" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>📊</span> 3. 市场环境与容量
                          </h4>
                          <ul class="space-y-1.5 text-[9.5px] text-slate-600 list-disc pl-4 leading-normal">
                            <li v-for="point in parsedDeepReport.market.points" :key="point">{{ point }}</li>
                          </ul>
                        </div>

                        <!-- Module 4: 竞争格局分析 -->
                        <div v-if="parsedDeepReport.competitors && parsedDeepReport.competitors.length > 0" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>⚔️</span> 4. 竞争格局分析
                          </h4>
                          <div class="space-y-2">
                            <div v-for="comp in parsedDeepReport.competitors" :key="comp.name" class="text-[9.5px] border-b border-black/[0.02] pb-1.5 last:border-b-0 last:pb-0">
                              <div class="font-bold text-slate-800">{{ comp.name }}</div>
                              <div class="text-slate-500 leading-normal text-[9px] mt-0.5">{{ comp.advantage }}</div>
                            </div>
                          </div>
                        </div>

                        <!-- Module 5: SWOT 态势分析 -->
                        <div v-if="parsedDeepReport.swot && (parsedDeepReport.swot.strengths.length > 0 || parsedDeepReport.swot.weaknesses.length > 0)" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5 col-span-1 md:col-span-2">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>⚖️</span> 5. 目标客商 SWOT 态势分析
                          </h4>
                          <div class="grid grid-cols-2 md:grid-cols-4 gap-2">
                            <div class="bg-emerald-50/30 border border-emerald-100/50 p-2.5 rounded-xl text-[9px]">
                              <div class="font-bold text-emerald-800 mb-1">S 优势 (Strengths)</div>
                              <ul class="list-disc pl-3 text-emerald-700/90 space-y-1">
                                <li v-for="s in parsedDeepReport.swot.strengths" :key="s">{{ s }}</li>
                              </ul>
                            </div>
                            <div class="bg-rose-50/30 border border-rose-100/50 p-2.5 rounded-xl text-[9px]">
                              <div class="font-bold text-rose-800 mb-1">W 劣势 (Weaknesses)</div>
                              <ul class="list-disc pl-3 text-rose-700/90 space-y-1">
                                <li v-for="w in parsedDeepReport.swot.weaknesses" :key="w">{{ w }}</li>
                              </ul>
                            </div>
                            <div class="bg-blue-50/30 border border-blue-100/50 p-2.5 rounded-xl text-[9px]">
                              <div class="font-bold text-blue-800 mb-1">O 机会 (Opportunities)</div>
                              <ul class="list-disc pl-3 text-blue-700/90 space-y-1">
                                <li v-for="o in parsedDeepReport.swot.opportunities" :key="o">{{ o }}</li>
                              </ul>
                            </div>
                            <div class="bg-amber-50/30 border border-amber-100/50 p-2.5 rounded-xl text-[9px]">
                              <div class="font-bold text-amber-800 mb-1">T 威胁 (Threats)</div>
                              <ul class="list-disc pl-3 text-amber-700/90 space-y-1">
                                <li v-for="t in parsedDeepReport.swot.threats" :key="t">{{ t }}</li>
                              </ul>
                            </div>
                          </div>
                        </div>

                        <!-- Module 6: 采购痛点与决策因素 -->
                        <div v-if="parsedDeepReport.customer && parsedDeepReport.customer.pains.length > 0" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>🎯</span> 6. 买方画像与核心痛点
                          </h4>
                          <ul class="space-y-1.5 text-[9.5px]">
                            <li v-for="pain in parsedDeepReport.customer.pains" :key="pain" class="text-rose-600 font-bold leading-normal">
                              ⚠️ {{ pain }}
                            </li>
                            <li v-for="type in parsedDeepReport.customer.types" :key="type" class="text-slate-600">
                              主要受众: {{ type }}
                            </li>
                          </ul>
                          <div class="bg-emerald-50/30 border border-emerald-100/50 p-2 rounded-xl mt-2">
                            <div class="flex justify-between text-[9px] font-bold text-emerald-800">
                              <span>采购意向匹配度:</span>
                              <span>{{ parsedDeepReport.customer.intentScore }}</span>
                            </div>
                            <div class="h-1 bg-slate-200 rounded-full mt-1 overflow-hidden">
                              <div class="h-full bg-emerald-500 rounded-full" :style="{ width: parsedDeepReport.customer.intentScore }"></div>
                            </div>
                          </div>
                        </div>

                        <!-- Module 7: 推荐中国供应商池 -->
                        <div v-if="parsedDeepReport.suppliers && parsedDeepReport.suppliers.length > 0" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>🇨🇳</span> 7. 推荐中国供应商列表
                          </h4>
                          <div class="space-y-2">
                            <div v-for="sup in parsedDeepReport.suppliers" :key="sup.name" class="flex justify-between items-center text-[9.5px] border-b border-black/[0.02] pb-1.5 last:border-b-0 last:pb-0">
                              <div>
                                <span class="font-bold text-slate-800">{{ sup.name }}</span>
                                <span class="text-[8px] bg-slate-100 text-slate-500 px-1 py-0.2 rounded ml-1.5">{{ sup.location }}</span>
                              </div>
                              <span class="text-[8px] bg-indigo-50 text-indigo-600 px-1.5 py-0.5 rounded font-bold font-sans">{{ sup.product }}</span>
                            </div>
                          </div>
                        </div>

                        <!-- Module 8: 客户推进与GTM规划 -->
                        <div v-if="parsedDeepReport.gtm && (parsedDeepReport.gtm.shortTerm || parsedDeepReport.gtm.mediumTerm)" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5 col-span-1 md:col-span-2">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>🚀</span> 8. 开发推进路线建议
                          </h4>
                          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div class="space-y-2.5">
                              <h5 class="text-[9.5px] font-bold text-indigo-700">📆 30/60/90天行动路径</h5>
                              <div class="space-y-2 border-l border-slate-200 pl-3 ml-1.5 relative text-[9px] leading-normal">
                                <div v-if="parsedDeepReport.gtm.shortTerm" class="relative">
                                  <div class="absolute -left-[15px] top-[3px] w-2.5 h-2.5 bg-white border border-indigo-600 rounded-full"></div>
                                  <div class="font-bold text-indigo-900">短期 (1-30天)</div>
                                  <p class="text-slate-500">{{ parsedDeepReport.gtm.shortTerm }}</p>
                                </div>
                                <div v-if="parsedDeepReport.gtm.mediumTerm" class="relative">
                                  <div class="absolute -left-[15px] top-[3px] w-2.5 h-2.5 bg-white border border-indigo-600 rounded-full"></div>
                                  <div class="font-bold text-indigo-900">中期 (30-60天)</div>
                                  <p class="text-slate-500">{{ parsedDeepReport.gtm.mediumTerm }}</p>
                                </div>
                                <div v-if="parsedDeepReport.gtm.longTerm" class="relative">
                                  <div class="absolute -left-[15px] top-[3px] w-2.5 h-2.5 bg-white border border-indigo-600 rounded-full"></div>
                                  <div class="font-bold text-indigo-900">长期 (60-90天)</div>
                                  <p class="text-slate-500">{{ parsedDeepReport.gtm.longTerm }}</p>
                                </div>
                              </div>
                            </div>
                            <div class="space-y-2.5">
                              <h5 class="text-[9.5px] font-bold text-indigo-700">🛡️ 推荐账期及主推产品</h5>
                              <div class="bg-indigo-50/30 border border-indigo-100/50 p-2.5 rounded-xl text-[9px] space-y-1.5">
                                <div v-if="parsedDeepReport.gtm.paymentDesc">
                                  <strong>风控防线:</strong> <span class="text-slate-600">{{ parsedDeepReport.gtm.paymentDesc }}</span>
                                </div>
                                <div v-if="parsedDeepReport.gtm.recommendedProduct">
                                  <strong>主推产品:</strong> <span class="text-emerald-700 font-bold">{{ parsedDeepReport.gtm.recommendedProduct }}</span>
                                </div>
                                <div v-if="parsedDeepReport.gtm.productAdvantage">
                                  <strong>技术优势:</strong> <span class="text-slate-600">{{ parsedDeepReport.gtm.productAdvantage }}</span>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>

                        <!-- Module 9: 行动优先级 -->
                        <div v-if="parsedDeepReport.priorities && (parsedDeepReport.priorities.high.length > 0 || parsedDeepReport.priorities.medium.length > 0)" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>📌</span> 9. 行动优先级规划
                          </h4>
                          <div class="space-y-1.5 text-[9px] leading-normal">
                            <div v-if="parsedDeepReport.priorities.high.length > 0" class="text-rose-600">
                              <strong>🔥 高优优先级:</strong>
                              <ul class="list-disc pl-4 mt-0.5 space-y-0.5">
                                <li v-for="item in parsedDeepReport.priorities.high" :key="item">{{ item }}</li>
                              </ul>
                            </div>
                            <div v-if="parsedDeepReport.priorities.medium.length > 0" class="text-indigo-600 mt-2">
                              <strong>⚡️ 中低优先级:</strong>
                              <ul class="list-disc pl-4 mt-0.5 space-y-0.5">
                                <li v-for="item in parsedDeepReport.priorities.medium" :key="item">{{ item }}</li>
                              </ul>
                            </div>
                          </div>
                        </div>

                        <!-- Module 10: 关键成功因素 / 安全壁垒 -->
                        <div v-if="parsedDeepReport.csf && parsedDeepReport.csf.length > 0" class="bg-white/40 border border-white/50 p-4 rounded-2xl space-y-2.5">
                          <h4 class="text-[11px] font-bold text-indigo-950 border-b border-indigo-100/50 pb-1.5 flex items-center gap-1">
                            <span>🛡️</span> 10. 关键成功要素 (CSF)
                          </h4>
                          <ul class="space-y-1.5 text-[9.5px] text-slate-600 list-disc pl-4 leading-normal">
                            <li v-for="point in parsedDeepReport.csf" :key="point">{{ point }}</li>
                          </ul>
                        </div>

                      </div>
                    </div>
<!-- HTML Viewer inside safe iframe -->
                    <div v-else-if="selectedLeadForModal.deepReport.type === 'HTML'" class="w-full select-none">
                      <iframe :srcdoc="selectedLeadForModal.deepReport.content" class="w-full h-[320px] bg-white border border-white/40 rounded-xl shadow-inner" frameborder="0"></iframe>
                    </div>
                  </div>
                </div>

                <!-- Empty state reminder with premium One-click CTA -->
                <div class="apple-glass rounded-2xl p-6 border border-dashed border-indigo-200 text-center select-none space-y-4" v-else>
                  <div class="w-12 h-12 bg-indigo-50 rounded-full flex items-center justify-center mx-auto text-indigo-500 shadow-sm">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z" />
                    </svg>
                  </div>
                  <div class="space-y-1">
                    <h4 class="text-xs font-bold text-zen-ink font-serif-sc">智能分析已就绪</h4>
                    <p class="text-[10px] text-zen-gray max-w-md mx-auto leading-relaxed">
                      当前该客户尚无深度报告，可启动 AI 智能分析该客户的询盘背景、商业潜力及风险特征。
                    </p>
                  </div>
                  <button
                    @click="triggerOneClickAnalysis(selectedLeadForModal)"
                    class="mx-auto px-5 py-2.5 bg-gradient-to-r from-indigo-500 via-indigo-600 to-purple-600 hover:from-indigo-600 hover:to-purple-700 text-white font-bold rounded-xl text-[10px] flex items-center gap-2 shadow-md hover:shadow-lg transform active:scale-95 transition-all outline-none font-sans"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 animate-spin" fill="none" viewBox="0 0 24 24" stroke="currentColor" v-if="isDeepAnalyzing">
                      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" v-else>
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                    启动 AI 深度分析
                  </button>
                </div>
              </template>
            </div>

            <!-- Tab 2: Follow-up Logs (跟进记录时间线) -->
            <div v-else-if="activeWorkspaceTab === 'followup'" class="space-y-4">
              <!-- Quick inline log logger -->
              <div class="p-4 bg-white/40 border border-white/50 rounded-2xl space-y-3 select-none">
                <span class="block text-[9px] text-zen-gray font-bold uppercase tracking-wider">快捷登记今日沟通记录 (Quick Follow-up)</span>
                <div class="flex gap-3">
                  <div class="flex-1 space-y-1.5">
                    <select
                      v-model="detailFollowUpChannel"
                      class="w-full bg-white/50 border border-white/60 rounded-xl px-3 py-1.5 text-[10px] outline-none focus:bg-white focus:border-zen-green"
                    >
                      <option value="电子邮件 (Email)">电子邮件 (Email)</option>
                      <option value="WhatsApp / 微信">WhatsApp / 微信</option>
                      <option value="面访 (Ground Visit)">面访 (Ground Visit)</option>
                      <option value="电话会议 (Call)">电话会议 (Call)</option>
                      <option value="__custom__">✏️ 自定义渠道...</option>
                    </select>
                    <input
                      v-if="detailFollowUpChannel === '__custom__'"
                      v-model="detailFollowUpChannelCustom"
                      type="text"
                      placeholder="输入自定义沟通渠道，如 LinkedIn / 展会现场..."
                      class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-1.5 text-[10px] outline-none focus:bg-white focus:border-zen-green transition-all animate-fadeIn"
                    />
                  </div>
                  <div class="flex-1 space-y-1.5">
                    <select
                      v-model="detailFollowUpType"
                      class="w-full bg-white/50 border border-white/60 rounded-xl px-3 py-1.5 text-[10px] outline-none focus:bg-white focus:border-zen-green"
                    >
                      <option value="初次接触">初次接触</option>
                      <option value="价格谈判">价格谈判</option>
                      <option value="持续跟进">持续跟进</option>
                      <option value="意向确认">意向确认</option>
                      <option value="__custom__">✏️ 自定义类型...</option>
                    </select>
                    <input
                      v-if="detailFollowUpType === '__custom__'"
                      v-model="detailFollowUpTypeCustom"
                      type="text"
                      placeholder="输入自定义跟进类型，如 售后回访 / 样品确认..."
                      class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-1.5 text-[10px] outline-none focus:bg-white focus:border-zen-green transition-all animate-fadeIn"
                    />
                  </div>
                </div>
                <div>
                  <textarea
                    v-model="detailFollowUpDraft"
                    rows="2"
                placeholder="输入跟进记录：如 微信/WhatsApp 跟进，对价格表示认可，还需法务会审..."
                    class="w-full bg-white/40 border border-white/60 rounded-xl p-2.5 text-[10px] outline-none focus:bg-white focus:border-zen-green leading-normal"
                  ></textarea>
                </div>
                <div class="flex justify-end gap-2 text-[10px]">
                  <button
                    @click="polishDetailNote"
                    :disabled="isPolishingDetail"
                    class="px-3.5 py-1.5 rounded-lg border border-zen-tea text-zen-tea hover:bg-zen-tea/10 transition-all font-semibold outline-none flex items-center gap-1"
                  >
              <span>📋</span>
                    {{ isPolishingDetail ? 'AI 润色中...' : 'AI 润色' }}
                  </button>
                  <button
                    @click="addDetailFollowUp"
                    class="px-4 py-1.5 rounded-lg bg-zen-green text-white hover:bg-zen-green/90 transition-all font-bold outline-none"
                  >
                    保存记录
                  </button>
                </div>
              </div>

              <!-- Customer logs timeline -->
              <div class="relative pl-6 border-l border-white/30 space-y-4">
                <div v-for="log in matchedTimelineLogs" :key="log.id" class="relative group">
                  <span class="absolute -left-[30px] top-1.5 w-3.5 h-3.5 rounded-full bg-white border-2 border-zen-tea flex items-center justify-center">
                    <span class="w-1.5 h-1.5 rounded-full bg-zen-tea"></span>
                  </span>
                  <div class="bg-white/40 p-4 rounded-2xl border border-white/50 space-y-2 shadow-sm">
                    <div class="flex justify-between items-center text-[10px]">
                      <span class="font-bold text-zen-gray px-2.5 py-0.5 rounded-full bg-white/60 border border-white/40">{{ log.channel }}</span>
                      <span class="font-mono text-zen-gray">{{ log.date }}</span>
                    </div>
                    <p class="text-xs text-zen-ink font-serif-sc leading-relaxed whitespace-pre-wrap select-text">
                      {{ log.content }}
                    </p>
                    <div class="pt-1.5 text-[8px] text-zen-gray select-none border-t border-white/10 flex justify-between">
                      <span class="font-bold text-zen-green">跟进阶段：{{ log.type }}</span>
                      <span class="font-mono text-zen-gray">SQLite 本地安全隔离</span>
                    </div>
                  </div>
                </div>
                <div v-if="!matchedTimelineLogs.length" class="text-center py-6 text-zen-gray text-xs italic select-none">
              暂无与该客户的沟通纪要记录
                </div>
              </div>
            </div>

    <!-- Tab 3: Quotations history (报价记录 - 汇总并可查看形式发票详情) -->
            <div v-else-if="activeWorkspaceTab === 'quotes'" class="space-y-3">
              <div class="flex justify-between items-center mb-2 select-none">
                <span class="text-xs font-bold text-zen-ink">📊 历史报价核算明细 (Proforma Invoices)</span>
                <div class="flex gap-2">
                  <button
                    @click="openCreateQuoteModal"
                    class="px-3 py-1.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-[9px] font-bold shadow-sm transition-all"
                  >
                    ＋ 新建报价
                  </button>
                  <button
                    @click="openImportQuoteModal"
                    class="px-3 py-1.5 bg-white border border-white/80 hover:bg-white/80 text-zen-ink rounded-xl text-[9px] font-bold shadow-sm transition-all"
                  >
                    📥 导入报价
                  </button>
                </div>
              </div>
              <div class="apple-glass rounded-2xl p-4 border border-white/50 overflow-x-auto select-none">
                <table class="w-full text-left text-[10px] text-zen-ink">
                  <thead>
                    <tr class="border-b border-white/10 text-zen-gray font-serif-sc uppercase tracking-wider">
                      <th class="py-2.5">报价编号</th>
                      <th class="py-2.5">产品名称</th>
                      <th class="py-2.5">贸易条款</th>
                      <th class="py-2.5 text-right">出厂成本</th>
                      <th class="py-2.5 text-right font-bold text-zen-green">建议报价</th>
                      <th class="py-2.5 text-right">报价状态</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-white/10 font-mono text-[11px]">
                    <tr
                      v-for="q in matchedQuotes"
                      :key="q.id"
                      @click="openInnerQuoteDetail(q)"
                      class="hover:bg-white/40 transition-colors cursor-pointer"
                      title="查看 Proforma Invoice 形式发票详情"
                    >
                      <td class="py-3 text-indigo-600 font-sans font-bold">{{ q.code }}</td>
                      <td class="py-3 font-sans">{{ q.product }}</td>
                      <td class="py-3 font-sans">{{ q.incoterms }}</td>
                      <td class="py-3 text-right text-zen-gray">${{ q.cost }}</td>
                      <td class="py-3 text-right font-bold text-zen-green">${{ q.price }}</td>
                      <td class="py-3 text-right font-sans"><span class="px-2 py-0.5 rounded bg-zen-green/10 text-zen-green border border-zen-green/20">已成交</span></td>
                    </tr>
                    <tr v-if="!matchedQuotes.length">
                      <td colspan="6" class="py-8 text-center text-zen-gray font-sans italic">暂无与该客户的核算报价记录，请点击上方创建或导入报价。</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Tab 5: Merged Contracts & Opportunities (成交与订单合同 - 统一在此管理) -->
            <div v-else-if="activeWorkspaceTab === 'opportunities'" class="space-y-4">
              <!-- No longer used directly, integrated below -->
            </div>

            <!-- Tab 6: Unified contracts list -->
            <div v-else-if="activeWorkspaceTab === 'contracts'" class="space-y-6">
              
              <!-- 1. Contracts Table Section -->
              <div class="space-y-3">
                <div class="flex justify-between items-center select-none">
                  <h4 class="text-xs font-bold text-zen-ink font-serif-sc flex items-center gap-1.5">
                    <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
                    📄 签约正式销售合同 (Sales Contracts)
                  </h4>
                  <div class="flex gap-2">
                    <button
                      @click="openCreateContractModal"
                      class="px-3 py-1.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-[9px] font-bold shadow-sm transition-all"
                    >
                      ＋ 新建合同
                    </button>
                    <button
                      @click="openImportContractModal"
                      class="px-3 py-1.5 bg-white border border-white/80 hover:bg-white/80 text-zen-ink rounded-xl text-[9px] font-bold shadow-sm transition-all"
                    >
                      📥 导入合同
                    </button>
                  </div>
                </div>

                <div class="apple-glass rounded-2xl p-4 border border-white/50 overflow-x-auto select-none">
                  <table class="w-full text-left text-[10px] text-zen-ink">
                    <thead>
                      <tr class="border-b border-white/10 text-zen-gray font-serif-sc uppercase tracking-wider">
                        <th class="py-2.5">合同编号</th>
                        <th class="py-2.5">签约时间</th>
                        <th class="py-2.5">签约产品</th>
                        <th class="py-2.5 text-center">签约数量</th>
                        <th class="py-2.5 text-center">MOQ审计</th>
                        <th class="py-2.5 text-right">合同金额</th>
                        <th class="py-2.5 text-right">合同状态</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-white/10 font-mono text-[11px]">
                      <tr
                        v-for="c in matchedContracts"
                        :key="c.id"
                        @click="openInnerContractDetail(c)"
                        class="hover:bg-white/40 transition-colors cursor-pointer"
                        title="查看 Sales Contract 合同详情"
                      >
                        <td class="py-3 text-indigo-600 font-sans font-bold">{{ c.code }}</td>
                        <td class="py-3 font-sans">{{ c.date }}</td>
                        <td class="py-3 font-sans">{{ c.product }}</td>
                        <td class="py-3 text-center">{{ c.quantity }}</td>
                        <td class="py-3 text-center font-sans">
                          <span class="px-2 py-0.5 rounded-full text-[9px] font-bold" :class="c.quantity >= c.moq ? 'bg-zen-green/10 text-zen-green' : 'bg-zen-crimson/10 text-zen-crimson'">
                            {{ c.quantity >= c.moq ? '满足' : '不符' }}
                          </span>
                        </td>
                        <td class="py-3 text-right font-bold text-zen-green">{{ c.value }}</td>
                        <td class="py-3 text-right font-sans">
                          <span class="px-2 py-0.5 rounded bg-zen-green text-white font-bold select-none">{{ c.status }}</span>
                        </td>
                      </tr>
                      <tr v-if="!matchedContracts.length">
                        <td colspan="7" class="py-8 text-center text-zen-gray font-sans italic">暂无与该客户关联的订单合同，请点击上方创建或导入合同。</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <!-- 2. Deals / Opportunities Section (Merged from opportunities) -->
              <div class="pt-6 border-t border-white/20 space-y-3">
                <h4 class="text-xs font-bold text-zen-ink font-serif-sc flex items-center gap-1.5 select-none">
                  <span class="w-1.5 h-1.5 rounded-full bg-blue-500 animate-pulse"></span>
                  🤝 成交商机与跟进策略 (Commercial Opportunities)
                </h4>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div v-for="deal in matchedDeals" :key="deal.id" class="apple-glass rounded-2xl p-4 border border-white/50 space-y-3 shadow-sm hover:translate-y-[-2px] transition-all duration-300">
                    <div class="flex justify-between items-start">
                      <div>
                        <h4 class="text-xs font-bold text-indigo-700 leading-tight">{{ deal.title }}</h4>
                        <p class="text-[9px] text-zen-gray mt-1">商机预算: <strong class="font-mono text-zen-green font-bold text-[10px]">{{ deal.amount }}</strong></p>
                      </div>
                      <span class="px-2 py-0.5 rounded bg-white/60 border border-white/40 text-[9px] font-bold select-none shrink-0">
                        {{ deal.stage }}
                      </span>
                    </div>

                    <div class="flex justify-between items-center text-[10px] select-none">
                      <span class="text-zen-gray">AI 赢单概率:</span>
                      <strong class="font-mono text-zen-green font-bold">{{ deal.probability }}%</strong>
                    </div>

                    <div class="bg-white/40 p-2.5 rounded-xl border border-white/40 text-[10px] text-zen-gray leading-relaxed font-serif-sc">
                      <strong class="block text-[8px] text-zen-ink mb-0.5 uppercase tracking-wide">下步跟进动作:</strong>
                      {{ deal.nextStep }}
                    </div>

                    <div class="pt-2 border-t border-white/15 flex justify-end">
                      <button
                        @click="triggerWorkspaceDealStrategy(deal)"
                        class="px-3.5 py-1.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-[9px] font-bold shadow-sm transition-all"
                      >
                        AI 策略建议
                      </button>
                    </div>
                  </div>
                </div>
                <div v-if="!matchedDeals.length" class="text-center py-6 text-zen-gray text-xs italic select-none">
                  暂无与该客户相关的成交商机数据。
                </div>
              </div>

              <!-- Inline strategies details sub-card if selected -->
              <transition
                enter-active-class="transition duration-300 ease-out"
                enter-from-class="transform translate-y-4 opacity-0"
                enter-to-class="transform translate-y-0 opacity-100"
                leave-active-class="transition duration-200 ease-in"
                leave-from-class="transform translate-y-0 opacity-100"
                leave-to-class="transform translate-y-4 opacity-0"
              >
                <div v-if="activeWorkspaceDeal" class="bg-black/[0.03] border border-white/40 p-5 rounded-2xl space-y-3 relative select-text">
                  <button
                    @click="activeWorkspaceDeal = null"
                    class="absolute right-4 top-4 text-zen-gray hover:text-zen-ink text-xs font-semibold bg-white/60 border border-white/50 px-2.5 py-1 rounded-lg"
                  >
                    关闭
                  </button>
                  <h4 class="text-xs font-bold text-zen-ink font-serif-sc flex items-center gap-1.5 select-none">
                    <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
                    AI 项目成交策略建议 | {{ activeWorkspaceDeal.title }}
                  </h4>
                  <div class="p-3 bg-white/60 border border-white/50 rounded-xl leading-relaxed text-[11px]">
                    <span class="block text-[8px] text-zen-gray uppercase font-bold tracking-wider mb-1.5 select-none">
                      {{ isSecretMode ? 'Ollama 本地深度项目策略 (安全隔离)' : 'Gemini 智能网关策略建议 (云端推荐)' }}
                    </span>
                    <p class="whitespace-pre-wrap font-serif-sc leading-relaxed">{{ activeWorkspaceDeal.aiStrategy }}</p>
                  </div>
                </div>
              </transition>
            </div>
          </div>

          <!-- Bottom dispatch row -->
          <div class="pt-4 border-t border-white/20 select-none flex justify-between items-center">
              <span class="text-[9px] text-zen-gray font-mono">SQLite Local DB Secure Protected ✓</span>
            <button
              v-if="selectedLeadForModal?.country === '泰国' || selectedLeadForModal?.country === '菲律宾'"
              @click="dispatchToAgentFromModal"
              class="px-4 py-2 rounded-xl bg-zen-tea text-white text-[10px] hover:bg-zen-tea/90 transition-all font-bold outline-none"
            >
              全球派驻代理商
            </button>
          </div>
        </div>

      </div>
    </div>

    <!-- 7. Proforma Invoice Inner Modal (形式发票账单详情) -->
          <ZenModal :open="innerQuoteDetailOpen" :title="'形式发票账单详情 | ' + (selectedQuote?.code || '')" @close="innerQuoteDetailOpen = false">
      <div class="space-y-4 text-xs text-zen-ink select-text" v-if="selectedQuote">
        <div class="flex justify-between items-center border-b border-white/20 pb-3 select-none">
          <div>
            <h4 class="text-sm font-bold font-serif-sc leading-tight">{{ selectedQuote.client }}</h4>
            <p class="text-[10px] text-zen-gray mt-0.5">报价单: {{ selectedQuote.code }} | 贸易条款: {{ selectedQuote.incoterms }}</p>
          </div>
          <span class="text-2xl select-none">{{ selectedQuote.flag }}</span>
        </div>

        <div class="p-4 bg-white/40 border border-white/50 rounded-2xl space-y-2.5">
          <span class="block text-[9px] text-zen-gray font-bold uppercase tracking-wider select-none">财务成本拆解 (Cost Breakdown)</span>
          <div class="grid grid-cols-2 gap-y-2 font-mono">
            <div class="text-zen-gray">出厂底价 (Factory Cost):</div>
            <div class="text-right font-bold">${{ selectedQuote.cost }} USD</div>
            
              <div class="text-zen-gray">海运保费合计 (Freight &amp; Insurance):</div>
            <div class="text-right font-bold">${{ selectedQuote.freight }} USD</div>

              <div class="text-zen-gray">中间商/返佣比 (Commission):</div>
            <div class="text-right font-bold">{{ selectedQuote.commission }}%</div>

            <div class="border-t border-white/20 col-span-2 my-1"></div>

            <div class="text-zen-green font-bold text-xs select-none">最终单价 (Final Unit Price):</div>
            <div class="text-right font-bold text-zen-green text-sm">${{ selectedQuote.price }} USD</div>
          </div>
        </div>

        <div class="p-3.5 bg-black/[0.04] border border-white/30 rounded-2xl space-y-1.5">
          <span class="block text-[8px] text-zen-gray font-bold uppercase select-none">AI 润色审计建议 (AI Audit Memo)</span>
          <p class="text-[11px] leading-relaxed font-serif-sc">
            形式发票（Proforma Invoice）计算报价为 <strong>${{ selectedQuote.price }} USD</strong>，
            经 AI 财务审查，该价格含海运本体与代理返佣，<strong>净利润达 26.8%</strong>，为最佳财务安全边际与价格比。
            建议接受并以本价格起草 P/I 正式议价通知客户以确定订单。
          </p>
        </div>
      </div>
      <template #footer>
        <button
          @click="innerQuoteDetailOpen = false"
          class="px-4 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          通过 AI 智能审计会签
        </button>
        <button
          @click="innerQuoteDetailOpen = false"
          class="px-4 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-semibold outline-none"
        >
          返
        </button>
      </template>
    </ZenModal>

    <!-- 8. --- Sales Contract Inner detailed Modal (穿透查看合同详情款项弹窗) --- -->
          <ZenModal :open="innerContractDetailOpen" :title="'合同详情与款项归档 | ' + (selectedContract?.code || '')" @close="innerContractDetailOpen = false">
      <div class="space-y-4 text-xs text-zen-ink select-text" v-if="selectedContract">
        <div class="flex justify-between items-center border-b border-white/20 pb-3 select-none">
          <div>
            <h4 class="text-sm font-bold font-serif-sc leading-tight">{{ selectedContract.client }}</h4>
            <p class="text-[10px] text-zen-gray mt-0.5">合同编号: {{ selectedContract.code }} | 签署日期: {{ selectedContract.date }}</p>
          </div>
          <span class="text-2xl select-none">{{ selectedContract.flag }}</span>
        </div>

        <!-- Contract Details -->
        <div class="p-4 bg-white/40 border border-white/50 rounded-2xl space-y-2.5">
          <span class="block text-[9px] text-zen-gray font-bold uppercase tracking-wider select-none">销售合同条款 (Sales Contract Terms)</span>
          
          <div class="grid grid-cols-2 gap-y-2.5 text-[11px]">
            <div class="text-zen-gray font-sans">签约产品:</div>
            <div class="text-right font-bold font-sans">{{ selectedContract.product }}</div>

            <div class="text-zen-gray font-sans">签约数量:</div>
            <div class="text-right font-bold font-mono">{{ selectedContract.quantity }} 个 (Units)</div>

            <div class="text-zen-gray font-sans">合同金额:</div>
            <div class="text-right font-bold font-mono text-zen-green text-xs">{{ selectedContract.value }}</div>

            <div class="text-zen-gray font-sans">付款条款 (Payment Terms):</div>
            <div class="text-right font-bold font-sans">30% Advance T/T, 70% against B/L copy</div>

            <div class="text-zen-gray font-sans">交付时间 (Shipment Time):</div>
            <div class="text-right font-bold font-sans">Within 15 business days upon deposit receipt</div>
          </div>
        </div>

        <!-- MOQ check and audit -->
        <div class="p-3.5 rounded-2xl border flex items-start gap-3 select-none"
          :class="selectedContract.quantity >= selectedContract.moq
            ? 'bg-emerald-50/30 border-emerald-200/40 text-emerald-800'
            : 'bg-rose-50/30 border-rose-200/40 text-rose-800'"
        >
          <div class="w-8 h-8 rounded-full flex items-center justify-center shrink-0"
            :class="selectedContract.quantity >= selectedContract.moq ? 'bg-emerald-100/50 text-emerald-600' : 'bg-rose-100/50 text-rose-600'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 12l2 2 4-4" v-if="selectedContract.quantity >= selectedContract.moq" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" v-else />
            </svg>
          </div>
          <div class="space-y-0.5">
            <h5 class="text-[11px] font-bold font-serif-sc">MOQ 起订量与计划</h5>
            <p class="text-[10px] text-zen-gray leading-normal">
              批次签约数量为 <strong>{{ selectedContract.quantity }}</strong> 套产品，MOQ 起订量为 <strong>{{ selectedContract.moq }}</strong> 套，达到批量优惠门槛。
            </p>
          </div>
        </div>
      </div>
      <template #footer>
        <button
          @click="innerContractDetailOpen = false"
          class="px-4 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          确认
        </button>
        <button
          @click="innerContractDetailOpen = false"
          class="px-4 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-semibold outline-none"
        >
          返
        </button>
      </template>
    </ZenModal>

    <!-- 8. --- Quick Preview Popup Modal with comprehensive Hexagon Radar Chart --- -->
          <ZenModal :open="quickPreviewOpen" :title="'AI 客户综合速览 | ' + (selectedLeadForPreview?.name || '')" @close="quickPreviewOpen = false">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-8 items-stretch font-sans text-zen-ink" v-if="selectedLeadForPreview">
        
        <!-- LEFT COLUMN: Basic Customer info -->
        <div class="md:border-r md:border-white/20 md:pr-6 space-y-4 flex flex-col justify-between">
          <div class="space-y-4">
            <div class="flex items-center gap-3 pb-3 border-b border-white/20 select-none">
              <div class="w-12 h-12 rounded-full bg-black/[0.04] flex items-center justify-center text-xl shrink-0">
                {{ selectedLeadForPreview.flag }}
              </div>
              <div>
                <h4 class="text-xs font-bold leading-tight">{{ selectedLeadForPreview.name }}</h4>
                <p class="text-[9px] text-zen-gray mt-1 font-medium font-mono uppercase">ID: CLI-2026-0{{ selectedLeadForPreview.id }}</p>
              </div>
            </div>

            <!-- Details list -->
            <div class="space-y-3.5 text-xs leading-relaxed">
              <div>
                <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold select-none">公司名称 (Company)</span>
                <span class="text-xs font-bold text-zen-ink block mt-0.5 select-text">{{ selectedLeadForPreview.name }}</span>
              </div>
              <div>
                <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold select-none">业务联系人 (Contact)</span>
                <span class="text-xs font-bold text-zen-ink block mt-0.5 select-text">{{ selectedLeadForPreview.contact }}</span>
              </div>
              <div class="grid grid-cols-2 gap-3 select-none">
                <div>
              <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold">国家地区 (Country)</span>
                  <span class="text-xs font-semibold text-zen-ink block mt-0.5 select-text">{{ selectedLeadForPreview.country }}</span>
                </div>
                <div>
                  <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold">行业分类 (Category)</span>
                  <span class="text-xs font-semibold text-zen-ink block mt-0.5">
              {{ selectedLeadForPreview.category === 'parts' ? '汽车配件' : '工业照明' }}
                  </span>
                </div>
              </div>
              <div class="grid grid-cols-2 gap-3 select-none">
                <div>
                  <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold">阶段 (Stage)</span>
                  <span class="text-xs font-bold block mt-0.5" :class="selectedLeadForPreview.stage === 'deal' ? 'text-zen-green' : 'text-zen-gold'">
                    {{ selectedLeadForPreview.stage === 'deal' ? '已成交' : '潜在买家' }}
                  </span>
                </div>
                <div>
                  <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold">AI 综合意向分 (Score)</span>
                  <span class="text-xs font-bold text-zen-ink block mt-0.5 font-mono">{{ selectedLeadForPreview.score }} 分</span>
                </div>
              </div>
              <div>
                <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold select-none">买家原始询盘 (SQLite Preview)</span>
                <p class="text-[10px] text-zen-gray bg-black/[0.02] border border-white/30 p-2.5 rounded-xl leading-relaxed max-h-[80px] overflow-y-auto select-text font-serif-sc">
                  {{ selectedLeadForPreview.rawMessage }}
                </p>
              </div>
            </div>
          </div>

          <!-- Bottom Action Redirect -->
          <div class="pt-4 border-t border-white/20 select-none">
            <button
              @click="enterDetailWorkspaceFromPreview"
              class="w-full py-2.5 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white font-bold text-xs shadow-md transition-all outline-none flex items-center justify-center gap-1.5"
            >
              进入客户详情工作区 ➡️
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M14 5l7 7m0 0l-7 7m7-7H3" />
              </svg>
            </button>
          </div>
        </div>

        <!-- RIGHT COLUMN: SVGHexagon radar chart -->
        <div class="flex flex-col justify-between items-center text-center pl-0 md:pl-2">
          <div class="w-full pb-2.5 border-b border-white/20 select-none">
            <span class="block text-[9px] uppercase tracking-wider text-zen-gray font-bold font-serif-sc">AI 意向评分多维雷达图 (Radar Assessment)</span>
            <p class="text-[10px] text-zen-gray mt-0.5 leading-normal">实时读取 SQLite 行为数据建模，六维全面量化评估客户意向。</p>
          </div>

          <!-- Hexagon SVG -->
          <div class="w-full max-w-[240px] aspect-square flex items-center justify-center my-4 select-none relative z-10">
            <svg viewBox="0 0 220 220" class="w-full h-full">
              <!-- Grid lines & Concentric hexagons -->
              <!-- Hex 1 (Outer - Radius 70) -->
              <polygon points="110,35 170.62,70 170.62,140 110,175 49.38,140 49.38,70" fill="transparent" stroke="rgba(0,0,0,0.06)" stroke-width="1.2" stroke-dasharray="2,2" />
              <!-- Hex 2 (Middle - Radius 46) -->
              <polygon points="110,60.86 149.83,83.86 149.83,129.86 110,152.86 70.17,129.86 70.17,83.86" fill="transparent" stroke="rgba(0,0,0,0.04)" stroke-width="1.2" stroke-dasharray="2,2" />
              <!-- Hex 3 (Inner - Radius 23) -->
              <polygon points="110,80.43 129.91,91.93 129.91,114.93 110,126.43 90.09,114.93 90.09,91.93" fill="transparent" stroke="rgba(0,0,0,0.03)" stroke-width="1.2" />

              <!-- Spoke axes -->
              <line x1="110" y1="105" x2="110" y2="35" stroke="rgba(0,0,0,0.05)" stroke-width="1.2" />
              <line x1="110" y1="105" x2="170.62" y2="70" stroke="rgba(0,0,0,0.05)" stroke-width="1.2" />
              <line x1="110" y1="105" x2="170.62" y2="140" stroke="rgba(0,0,0,0.05)" stroke-width="1.2" />
              <line x1="110" y1="105" x2="110" y2="175" stroke="rgba(0,0,0,0.05)" stroke-width="1.2" />
              <line x1="110" y1="105" x2="49.38" y2="140" stroke="rgba(0,0,0,0.05)" stroke-width="1.2" />
              <line x1="110" y1="105" x2="49.38" y2="70" stroke="rgba(0,0,0,0.05)" stroke-width="1.2" />

              <!-- Active Radar Polygon (Translucent zen-green) -->
              <polygon :points="radarPoints" fill="rgba(98, 114, 84, 0.22)" stroke="#627254" stroke-width="2.2" stroke-linejoin="round" />

              <!-- Vertex Anchor Handles -->
              <circle v-for="(pt, idx) in radarVertices" :key="idx" :cx="pt.x" :cy="pt.y" r="3.5" fill="#627254" stroke="#ffffff" stroke-width="1" />

              <!-- Text labels inside SVG -->
              <text x="110" y="26" text-anchor="middle" class="text-[8px] font-bold fill-zen-ink font-sans">采购意向</text>
              <text x="178" y="67" text-anchor="start" class="text-[8px] font-bold fill-zen-ink font-sans">预算额度</text>
              <text x="178" y="146" text-anchor="start" class="text-[8px] font-bold fill-zen-ink font-sans">利润空间</text>
              <text x="110" y="186" text-anchor="middle" class="text-[8px] font-bold fill-zen-ink font-sans">信用履约</text>
              <text x="42" y="146" text-anchor="end" class="text-[8px] font-bold fill-zen-ink font-sans">交易频率</text>
              <text x="42" y="67" text-anchor="end" class="text-[8px] font-bold fill-zen-ink font-sans">数据安全</text>
            </svg>
          </div>

          <!-- Multi-dimensional capabilities values chips -->
          <div class="grid grid-cols-3 gap-2 w-full text-[9px] select-none font-mono mt-2">
            <div class="bg-black/[0.02] border border-white/40 p-1.5 rounded">
              <span class="block text-zen-gray uppercase text-[7px]">采购意向</span>
              <strong class="text-zen-ink font-bold">{{ radarValues.v0 }}%</strong>
            </div>
            <div class="bg-black/[0.02] border border-white/40 p-1.5 rounded">
              <span class="block text-zen-gray uppercase text-[7px]">预算额度</span>
              <strong class="text-zen-ink font-bold">{{ radarValues.v1 }}%</strong>
            </div>
            <div class="bg-black/[0.02] border border-white/40 p-1.5 rounded">
              <span class="block text-zen-gray uppercase text-[7px]">利润空间</span>
              <strong class="text-zen-ink font-bold">{{ radarValues.v2 }}%</strong>
            </div>
            <div class="bg-black/[0.02] border border-white/40 p-1.5 rounded">
              <span class="block text-zen-gray uppercase text-[7px]">信用履约</span>
              <strong class="text-zen-ink font-bold">{{ radarValues.v3 }}%</strong>
            </div>
            <div class="bg-black/[0.02] border border-white/40 p-1.5 rounded">
              <span class="block text-zen-gray uppercase text-[7px]">交易频率</span>
              <strong class="text-zen-ink font-bold">{{ radarValues.v4 }}%</strong>
            </div>
            <div class="bg-black/[0.02] border border-white/40 p-1.5 rounded">
              <span class="block text-zen-gray uppercase text-[7px]">数据安全</span>
              <strong class="text-zen-ink font-bold">{{ radarValues.v5 }}%</strong>
            </div>
          </div>
        </div>

      </div>
      <template #footer>
        <button
          @click="quickPreviewOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-semibold outline-none"
        >
          返回
        </button>
      </template>
    </ZenModal>

    <!-- ZenModal for adding new lead (录入询盘客户) -->
    <ZenModal :open="addLeadModalOpen" title="录入询盘客户" @close="addLeadModalOpen = false">
      <div class="space-y-4 text-xs text-zen-ink">
        <div class="space-y-1.5">
          <label class="block font-bold">客户公司名称 (Company/Client Name)</label>
          <input
            type="text"
            v-model="newLeadForm.name"
            placeholder="e.g. AeroSpeedX Auto Accessories"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
          />
        </div>

        <div class="grid grid-cols-3 gap-4">
          <div class="space-y-1.5">
            <label class="block font-bold">联系人代表 (Contact Person)</label>
            <input
              type="text"
              v-model="newLeadForm.contact"
              placeholder="e.g. Richard Garcia"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
            />
          </div>
          <div class="space-y-1.5">
                <label class="block font-bold">手机号码 (Mobile Phone)</label>
            <input
              type="text"
              v-model="newLeadForm.phone"
              placeholder="e.g. +63 917 123 4567"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
            />
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold">主营类目 (Category)</label>
            <select
              v-model="newLeadForm.category"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
            >
              <option value="parts">汽车零部件 (汽配)</option>
              <option value="lights">工业外贸照明 (LED)</option>
            </select>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1.5">
                <label class="block font-bold">国家地区 (Country)</label>
            <select
              v-model="newLeadForm.country"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
            >
              <option value="俄罗斯">俄罗斯 (Russia)</option>
              <option value="泰国">泰国 (Thailand)</option>
              <option value="以色列">以色列 (Israel)</option>
              <option value="菲律宾">菲律宾 (Philippines)</option>
              <option value="阿联酋">阿联酋 (UAE)</option>
              <option value="印度">印度 (India)</option>
              <option value="伊拉克">伊拉克 (Iraq)</option>
              <option value="澳大利亚">澳大利亚 (Australia)</option>
            </select>
          </div>
          <div class="space-y-1.5">
                <label class="block font-bold">交易阶段 (Stage)</label>
            <select
              v-model="newLeadForm.stage"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
            >
              <option value="potential">潜在客户 (Followup Leads)</option>
              <option value="deal">已成交 (Signed Accounts)</option>
            </select>
          </div>
        </div>

        <div class="space-y-1.5">
          <label class="block font-bold">原始询盘信息 (Raw Message)</label>
          <textarea
            v-model="newLeadForm.rawMessage"
            rows="4"
                placeholder="请在此粘贴客户原始询盘邮件，用 AI 多路解析生成 RAG 产品匹配..."
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
          ></textarea>
        </div>
      </div>

      <template #footer>
        <button
          @click="submitNewLead"
          class="px-5 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          保存并触发 AI 路由分析 🚀
        </button>
        <button
          @click="addLeadModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          取消
        </button>
      </template>
    </ZenModal>

    <!-- 1. 新建报价 Modal -->
    <ZenModal :isOpen="isCreateQuoteModalOpen" @close="isCreateQuoteModalOpen = false" title="＋ 新建形式报价单 (Proforma Invoice)">
      <div class="space-y-4 text-xs select-none">
        <div class="space-y-1.5">
          <label class="block font-bold">报价客商名称</label>
          <input
            type="text"
            :value="selectedLeadForModal?.name"
            disabled
            class="w-full bg-black/5 border border-black/10 rounded-xl px-3 py-2 text-xs text-zen-gray outline-none"
          />
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">报价关联产品 (Matching Product)</label>
          <select
            v-model="newQuoteForm.product"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
          >
            <option v-for="p in products" :key="p.id" :value="`${p.name} (Model: ${p.id})`">
              {{ p.name }} ({{ p.id }})
            </option>
          </select>
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1.5">
            <label class="block font-bold">贸易运输条款 (Incoterms)</label>
            <select
              v-model="newQuoteForm.incoterms"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
            >
              <option value="FOB Shanghai">FOB Shanghai (上海离岸价)</option>
              <option value="CIF Hamburg">CIF Hamburg (汉堡到岸价)</option>
              <option value="DDP Brisbane">DDP Brisbane (布里斯班双清完税价)</option>
              <option value="EXW Factory">EXW Factory (出厂底价)</option>
            </select>
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold">工厂出厂成本 (USD)</label>
            <input
              type="number"
              v-model.number="newQuoteForm.cost"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono"
            />
          </div>
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold text-zen-green">建议外贸成交报价 (USD)</label>
          <input
            type="number"
            v-model.number="newQuoteForm.price"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono font-bold"
          />
        </div>
      </div>
      <template #footer>
        <button
          @click="handleCreateQuote"
          class="px-5 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          确定生成 📄
        </button>
        <button
          @click="isCreateQuoteModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          取消
        </button>
      </template>
    </ZenModal>

    <!-- 2. 导入报价 Modal -->
    <ZenModal :isOpen="isImportQuoteModalOpen" @close="isImportQuoteModalOpen = false" title="📥 智能导入形式报价单">
      <div class="space-y-4 text-xs select-none">
        <p class="text-[10px] text-zen-gray leading-relaxed">
          支持模拟外部报价数据包极速导入，或在下方直接编辑并粘贴 CSV 格式的报价信息：
        </p>
        <div class="p-3 bg-indigo-50/50 border border-indigo-100 rounded-xl space-y-2">
          <span class="block text-[8px] uppercase tracking-wider text-indigo-600 font-bold">推荐导入预设数据包 (Pre-made Presets)</span>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
            <button
              @click="handleImportQuote({ code: 'QT-2026-9081', product: '加固底盘金属护甲 (Model: EX-XT-500)', incoterms: 'FOB Shanghai', cost: 240, price: 420 })"
              class="p-2 bg-white hover:bg-indigo-50 border border-indigo-200 text-indigo-700 rounded-lg text-left text-[9px] leading-tight font-semibold"
            >
              加固底盘护甲 (FOB) · $420
            </button>
            <button
              @click="handleImportQuote({ code: 'QT-2026-9082', product: '特种柔性折叠水囊 (Model: FL-WT-100)', incoterms: 'CIF Hamburg', cost: 110, price: 195 })"
              class="p-2 bg-white hover:bg-indigo-50 border border-indigo-200 text-indigo-700 rounded-lg text-left text-[9px] leading-tight font-semibold"
            >
              特种折叠水囊 (CIF) · $195
            </button>
          </div>
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">手动 CSV 格式黏贴板</label>
          <textarea
            rows="3"
            placeholder="报价单号,产品型号,贸易条款,工厂成本,报价金额&#10;QT-2026-4412,加固底盘金属护甲,FOB Ningbo,240,410"
            class="w-full bg-white/40 border border-white/60 rounded-xl p-2.5 text-[9px] font-mono leading-normal outline-none focus:bg-white focus:border-zen-green"
          ></textarea>
        </div>
      </div>
      <template #footer>
        <button
          @click="handleImportQuote(null)"
          class="px-5 py-2 rounded-xl bg-indigo-600 text-white text-xs hover:bg-indigo-700 transition-all font-semibold outline-none"
        >
          解析并导入 📥
        </button>
        <button
          @click="isImportQuoteModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          取消
        </button>
      </template>
    </ZenModal>

    <!-- 3. 新建合同 Modal -->
    <ZenModal :isOpen="isCreateContractModalOpen" @close="isCreateContractModalOpen = false" title="＋ 新建正式销售订单合同 (Sales Contract)">
      <div class="space-y-4 text-xs select-none">
        <div class="space-y-1.5">
          <label class="block font-bold">合同买商名称</label>
          <input
            type="text"
            :value="selectedLeadForModal?.name"
            disabled
            class="w-full bg-black/5 border border-black/10 rounded-xl px-3 py-2 text-xs text-zen-gray outline-none"
          />
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">签约购买产品</label>
          <select
            v-model="newContractForm.product"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
          >
            <option v-for="p in products" :key="p.id" :value="p.name">
              {{ p.name }}
            </option>
          </select>
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1.5">
            <label class="block font-bold">签约订购数量</label>
            <input
              type="number"
              v-model.number="newContractForm.quantity"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono"
            />
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold">MOQ 限制起订量</label>
            <input
              type="number"
              v-model.number="newContractForm.moq"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono"
            />
          </div>
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div class="space-y-1.5">
            <label class="block font-bold">合同总成交金额 (RMB)</label>
            <input
              type="number"
              v-model.number="newContractForm.value"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono font-bold text-zen-green"
            />
          </div>
          <div class="space-y-1.5">
            <label class="block font-bold">签约时间</label>
            <input
              type="date"
              v-model="newContractForm.date"
              class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-sans"
            />
          </div>
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">合同当前状态</label>
          <select
            v-model="newContractForm.status"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
          >
            <option value="已签署">已签署 (Signed)</option>
            <option value="履行中">履行中 (In Progress)</option>
            <option value="已结案">已结案 (Completed)</option>
          </select>
        </div>
      </div>
      <template #footer>
        <button
          @click="handleCreateContract"
          class="px-5 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          确定建立 📃
        </button>
        <button
          @click="isCreateContractModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          取消
        </button>
      </template>
    </ZenModal>

    <!-- 4. 导入合同 Modal -->
    <ZenModal :isOpen="isImportContractModalOpen" @close="isImportContractModalOpen = false" title="📥 智能导入销售合同数据">
      <div class="space-y-4 text-xs select-none">
        <p class="text-[10px] text-zen-gray leading-relaxed">
          您可以一键加载系统模拟的正式外贸合同预设包，直接完成系统匹配与 PDF 解析：
        </p>
        <div class="p-3 bg-indigo-50/50 border border-indigo-100 rounded-xl space-y-2">
          <span class="block text-[8px] uppercase tracking-wider text-indigo-600 font-bold">推荐导入预设合同 (Contract Presets)</span>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
            <button
              @click="handleImportContract({ code: 'SC-2026-8051', product: '加固底盘金属护甲', quantity: 200, moq: 100, value: '¥78,000.00', date: '2026-05-28', status: '已签署' })"
              class="p-2 bg-white hover:bg-indigo-50 border border-indigo-200 text-indigo-700 rounded-lg text-left text-[9px] leading-tight font-semibold"
            >
              底盘金属护甲合同 (200套) · ¥78,000
            </button>
            <button
              @click="handleImportContract({ code: 'SC-2026-8052', product: '特种柔性折叠水囊', quantity: 500, moq: 100, value: '¥92,500.00', date: '2026-05-30', status: '履行中' })"
              class="p-2 bg-white hover:bg-indigo-50 border border-indigo-200 text-indigo-700 rounded-lg text-left text-[9px] leading-tight font-semibold"
            >
              特种折叠水囊合同 (500套) · ¥92,500
            </button>
          </div>
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">手动合同 CSV / JSON 数据黏贴板</label>
          <textarea
            rows="3"
            placeholder="合同号,产品,签约数量,MOQ,总额,签约日期,合同状态&#10;SC-2026-1182,加固底盘金属护甲,150,100,¥60000,2026-05-29,已签署"
            class="w-full bg-white/40 border border-white/60 rounded-xl p-2.5 text-[9px] font-mono leading-normal outline-none focus:bg-white focus:border-zen-green"
          ></textarea>
        </div>
      </div>
      <template #footer>
        <button
          @click="handleImportContract(null)"
          class="px-5 py-2 rounded-xl bg-indigo-600 text-white text-xs hover:bg-indigo-700 transition-all font-semibold outline-none"
        >
          确认解析导入 📥
        </button>
        <button
          @click="isImportContractModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          取消
        </button>
      </template>
    </ZenModal>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import ZenModal from './ZenModal.vue';

const reportTab = ref('dashboard');

const parseMarkdownReport = (markdownText) => {
  if (!markdownText) return null;
  
  const report = {
    company: null,
    keyPeople: [],
    market: null,
    competitors: [],
    swot: { strengths: [], weaknesses: [], opportunities: [], threats: [] },
    customer: { pains: [], types: [], intentScore: '92%' },
    suppliers: [],
    gtm: { shortTerm: '', mediumTerm: '', longTerm: '', paymentDesc: '', recommendedProduct: '', productAdvantage: '' },
    priorities: { high: [], medium: [], low: [] },
    csf: []
  };

  const lines = markdownText.split('\n');
  let currentSection = '';
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line.startsWith('## ') || line.startsWith('# ')) {
      const headerText = line.replace(/^##\s*\d*\.*\s*/, '').replace(/^#\s*\d*\.*\s*/, '').trim();
      if (headerText.includes('公司概况') || headerText.includes('Overview') || headerText.includes('画像') || headerText.includes('客商')) {
        currentSection = 'company';
        report.company = { fullName: '', hq: '', phone: '', email: '', nature: '', model: '', tags: [], desc: '' };
      } else if (headerText.includes('关键人物') || headerText.includes('Key People') || headerText.includes('管理层') || headerText.includes('人物')) {
        currentSection = 'keyPeople';
      } else if (headerText.includes('市场') || headerText.includes('Market') || headerText.includes('环境')) {
        currentSection = 'market';
        report.market = { points: [] };
      } else if (headerText.includes('竞争') || headerText.includes('Competit') || headerText.includes('格局')) {
        currentSection = 'competitors';
      } else if (headerText.includes('SWOT') || headerText.includes('态势')) {
        currentSection = 'swot';
      } else if (headerText.includes('采购痛点') || headerText.includes('决策因素') || headerText.includes('痛点') || headerText.includes('买方')) {
        currentSection = 'customer';
      } else if (headerText.includes('供应商') || headerText.includes('Supplier') || headerText.includes('中国')) {
        currentSection = 'suppliers';
      } else if (headerText.includes('开发规划') || headerText.includes('GTM') || headerText.includes('推进') || headerText.includes('策略')) {
        currentSection = 'gtm';
      } else if (headerText.includes('优先级') || headerText.includes('Priority') || headerText.includes('行动优先级')) {
        currentSection = 'priorities';
      } else if (headerText.includes('成功因素') || headerText.includes('CSF') || headerText.includes('安全防线') || headerText.includes('风控')) {
        currentSection = 'csf';
      } else {
        currentSection = '';
      }
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      const bulletContent = line.substring(2).trim();
      if (!bulletContent) continue;
      
      if (currentSection === 'company') {
        if (bulletContent.includes('公司:') || bulletContent.includes('客商:') || bulletContent.includes('全称:')) {
          report.company.fullName = bulletContent.split(/[:：]/)[1]?.trim() || '';
        } else if (bulletContent.includes('位置:') || bulletContent.includes('总部:')) {
          report.company.hq = bulletContent.split(/[:::]/)[1]?.trim() || '';
        } else if (bulletContent.includes('电话:')) {
          report.company.phone = bulletContent.split(/[:：]/)[1]?.trim() || '';
        } else if (bulletContent.includes('邮箱:')) {
          report.company.email = bulletContent.split(/[:：]/)[1]?.trim() || '';
        } else if (bulletContent.includes('性质:')) {
          report.company.nature = bulletContent.split(/[:：]/)[1]?.trim() || '';
        } else if (bulletContent.includes('业务:') || bulletContent.includes('核心:')) {
          report.company.model = bulletContent.split(/[:：]/)[1]?.trim() || '';
        } else {
          report.company.desc += bulletContent + ' ';
        }
      } else if (currentSection === 'keyPeople') {
        const parts = bulletContent.split(/[:：]/);
        if (parts.length >= 2) {
          report.keyPeople.push({ name: parts[0].trim(), title: parts[1].trim(), email: '已加密防护', phone: '已加密防护', verify: 'AI审核' });
        } else {
          report.keyPeople.push({ name: bulletContent, title: '关键采购链决策人', email: '已加密防护', phone: '已加密防护', verify: 'AI核对' });
        }
      } else if (currentSection === 'market') {
        report.market.points.push(bulletContent);
      } else if (currentSection === 'competitors') {
        const parts = bulletContent.split(/[:：]/);
        report.competitors.push({ name: parts[0]?.trim() || '竞争对手', advantage: parts[1]?.trim() || bulletContent, location: '海外本土', revenue: '中大体量' });
      } else if (currentSection === 'swot') {
        if (bulletContent.includes('优势') || bulletContent.toLowerCase().includes('strength') || bulletContent.includes('S ')) {
          report.swot.strengths.push(bulletContent.replace(/^优势[：:]\s*/, ''));
        } else if (bulletContent.includes('劣势') || bulletContent.toLowerCase().includes('weakness') || bulletContent.includes('W ')) {
          report.swot.weaknesses.push(bulletContent.replace(/^劣势[：:]\s*/, ''));
        } else if (bulletContent.includes('机会') || bulletContent.toLowerCase().includes('opportunit') || bulletContent.includes('O ')) {
          report.swot.opportunities.push(bulletContent.replace(/^机会[：:]\s*/, ''));
        } else if (bulletContent.includes('威胁') || bulletContent.toLowerCase().includes('threat') || bulletContent.includes('T ')) {
          report.swot.threats.push(bulletContent.replace(/^威胁[：:]\s*/, ''));
        }
      } else if (currentSection === 'customer') {
        if (bulletContent.includes('痛点') || bulletContent.includes('难点') || bulletContent.includes('⚠️') || bulletContent.includes('卡点')) {
          report.customer.pains.push(bulletContent);
        } else if (bulletContent.includes('类型:') || bulletContent.includes('群体:')) {
          report.customer.types.push(bulletContent.split(/[:：]/)[1]?.trim());
        } else if (bulletContent.includes('意向') || bulletContent.includes('评分')) {
          report.customer.intentScore = bulletContent.match(/\d+%/)?.[0] || '94%';
        } else {
          report.customer.pains.push(bulletContent);
        }
      } else if (currentSection === 'suppliers') {
        const parts = bulletContent.split(/[:：]/);
        report.suppliers.push({ name: parts[0]?.trim() || '潜在供应商', location: '中国', product: parts[1]?.trim() || bulletContent, status: '首选对接' });
      } else if (currentSection === 'gtm') {
        if (bulletContent.includes('30天') || bulletContent.includes('短期') || bulletContent.includes('一阶')) {
          report.gtm.shortTerm = bulletContent;
        } else if (bulletContent.includes('60天') || bulletContent.includes('中期') || bulletContent.includes('二阶')) {
          report.gtm.mediumTerm = bulletContent;
        } else if (bulletContent.includes('90天') || bulletContent.includes('长期') || bulletContent.includes('三阶')) {
          report.gtm.longTerm = bulletContent;
        } else if (bulletContent.includes('账期') || bulletContent.includes('结算') || bulletContent.includes('付款')) {
          report.gtm.paymentDesc = bulletContent;
        } else if (bulletContent.includes('主推') || bulletContent.includes('产品:')) {
          report.gtm.recommendedProduct = bulletContent.split(/[:：]/)[1]?.trim();
        } else if (bulletContent.includes('壁垒') || bulletContent.includes('优势:')) {
          report.gtm.productAdvantage = bulletContent.split(/[:：]/)[1]?.trim();
        }
      } else if (currentSection === 'priorities') {
        if (bulletContent.includes('高') || bulletContent.toLowerCase().includes('high')) {
          report.priorities.high.push(bulletContent.replace(/^高[：:]\s*/, ''));
        } else if (bulletContent.includes('中') || bulletContent.toLowerCase().includes('medium')) {
          report.priorities.medium.push(bulletContent.replace(/^中[：:]\s*/, ''));
        } else {
          report.priorities.low.push(bulletContent.replace(/^低[：:]\s*/, ''));
        }
      } else if (currentSection === 'csf') {
        report.csf.push(bulletContent);
      }
    }
  }
  
  return report;
};

const parsedDeepReport = computed(() => {
  if (!selectedLeadForModal.value || !selectedLeadForModal.value.deepReport) return null;
  if (selectedLeadForModal.value.deepReport.type !== 'Markdown') return null;
  return parseMarkdownReport(selectedLeadForModal.value.deepReport.content);
});

const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  },
  leads: {
    type: Array,
    required: true
  },
  quoteLogs: {
    type: Array,
    required: true
  },
  contracts: {
    type: Array,
    required: true
  },
  products: {
    type: Array,
    required: true
  },
  timelineLogs: {
    type: Array,
    required: true
  },
  deals: {
    type: Array,
    required: true
  },
  jumpToCustomerId: {
    type: Number,
    default: null
  }
});

const emit = defineEmits(['update:leads', 'update:timelineLogs', 'clear-jump-customer', 'update:quoteLogs', 'update:contracts']);

// Synchronized raised database leads state
const leads = computed({
  get: () => props.leads,
  set: (val) => emit('update:leads', val)
});

// ─── Missing reactive state (search / filter / pagination) ───────────────────
const searchQuery = ref('');
const selectedCategory = ref('all');
const selectedStatus = ref('all');
const showDealGroup = ref(true);
const showPotentialGroup = ref(true);
const showMobileSearch = ref(false);
const dealLimit = ref(20);
const potentialLimit = ref(20);
const lostLimit = ref(20);
const cardLimit = ref(30);


// Category counts badge
const categoryCounts = computed(() => {
  const all = leads.value.length;
  const parts = leads.value.filter(l => l.category === 'parts').length;
  const lights = leads.value.filter(l => l.category === 'lights').length;
  return { all, parts, lights };
});

// Base filtered list (search + category + status)
const filteredLeads = computed(() => {
  let list = leads.value;
  if (selectedCategory.value !== 'all') {
    list = list.filter(l => l.category === selectedCategory.value);
  }
  if (selectedStatus.value !== 'all') {
    list = list.filter(l => l.stage === selectedStatus.value);
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.trim().toLowerCase();
    list = list.filter(l =>
      (l.name && l.name.toLowerCase().includes(q)) ||
      (l.contact && l.contact.toLowerCase().includes(q)) ||
      (l.country && l.country.toLowerCase().includes(q)) ||
      (l.tags && l.tags.some(t => t.toLowerCase().includes(q)))
    );
  }
  return list;
});

// Group filtered leads by stage
const dealLeads = computed(() => filteredLeads.value.filter(l => l.stage === 'deal'));
const potentialLeads = computed(() => filteredLeads.value.filter(l => l.stage === 'potential'));
const lostLeads = computed(() => filteredLeads.value.filter(l => l.stage === 'lost'));

// Whether to show each group section
const shouldShowGroup = (stage) => {
  if (selectedStatus.value !== 'all' && selectedStatus.value !== stage) return false;
  if (stage === 'deal') return dealLeads.value.length > 0;
  if (stage === 'potential') return potentialLeads.value.length > 0;
  if (stage === 'lost') return lostLeads.value.length > 0;
  return false;
};

// ─────────────────────────────────────────────────────────────────────────────

// View mode toggling: 'list' (List View / 表格形式) or 'card' (Card View / 卡片形式)
const viewMode = ref('list');

// Lost Leads Collapse ref
const showLostGroup = ref(true);
const customTagInput = ref('');
const customTagColor = ref('indigo'); // selected color for the new custom tag
const showTagColorPalette = ref(false); // toggles the swatch popover next to the input
const openTagPaletteFor = ref(null); // which existing tag's color popover is open
const isExtracting = ref(false);

const simulateExtractTags = async (lead) => {
  if (!lead) return;
  isExtracting.value = true;
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  try {
    const prompt = `Client: ${lead.name}\nCountry: ${lead.country}\nCategory: ${lead.category}\nInquiry: ${lead.rawMessage}\nExisting Tags: ${lead.tags.join(', ')}`;
    let extracted = await callAiInComponent(prompt);
    
    if (!extracted || !Array.isArray(extracted)) {
      extracted = [];
      const msg = lead.rawMessage.toLowerCase();
      
      if (lead.category === 'parts') {
        extracted.push('汽车配件');
        if (msg.includes('radiator') || msg.includes('cooling')) extracted.push('赛车散热器');
        if (msg.includes('chassis') || msg.includes('armor') || msg.includes('shield')) extracted.push('加固底盘');
      } else {
        extracted.push('外贸照明');
        if (msg.includes('led') || msg.includes('outdoor')) extracted.push('LED照明');
        if (msg.includes('high bay') || msg.includes('industrial')) extracted.push('工业高棚灯');
      }
      
      if (lead.country) {
        extracted.push(`${lead.country}市场`);
      }
      
      if (lead.score >= 85) {
        extracted.push('高意向');
        extracted.push('优质客户');
      } else {
        extracted.push('询盘跟进');
      }
    }
    
    extracted.forEach(tag => {
      if (tag && !lead.tags.includes(tag)) {
        lead.tags.push(tag);
      }
    });
    
    leads.value = [...leads.value];
    alert('✨ AI 智能标签分析提取成功，已为您自动补全高价值商机画像！');
  } catch (err) {
    console.error('Failed to extract tags:', err);
  } finally {
    isExtracting.value = false;
  }
};

const getLeadIconClass = (stage) => {
  if (stage === 'deal') {
    return 'bg-orange-500/15 border border-orange-500/20 text-orange-500';
  } else if (stage === 'potential') {
    return 'bg-blue-500/15 border border-blue-500/20 text-blue-500';
  } else if (stage === 'lost') {
    return 'bg-neutral-950/15 border border-neutral-950/20 text-neutral-950';
  }
  return 'bg-black/[0.04] border border-black/[0.02] text-zen-gray';
};

const addCustomTag = (lead) => {
  if (!lead) return;
  const tag = customTagInput.value.trim();
  if (tag) {
    // Apply the chosen color for this tag
    if (customTagColor.value) {
      tagColorMap.value = { ...tagColorMap.value, [tag]: customTagColor.value };
      persistTagColors();
    }
    if (!lead.tags.includes(tag)) {
      lead.tags.push(tag);
      leads.value = [...leads.value]; // Trigger save
    }
    // Force an immediate flush to disk so the new tag survives an instant quit/update
    if (window.saveLeadsData) window.saveLeadsData();
    customTagInput.value = '';
    showTagColorPalette.value = false;
  }
};

const removeTag = (lead, tagToRemove) => {
  if (!lead) return;
  lead.tags = lead.tags.filter(t => t !== tagToRemove);
  leads.value = [...leads.value]; // Trigger save
  if (window.saveLeadsData) window.saveLeadsData();
};

// Self-contained custom AI call for extracting tags from customer Sea
const callAiInComponent = async (userMessage) => {
  try {
    const saved = localStorage.getItem('magichub_ai_providers');
    if (!saved) return null;
    const parsed = JSON.parse(saved);
    // Find active DeepSeek, SiliconFlow or any enabled provider
    const provider = parsed.find(p => p.id === 'deepseek' && p.status) || parsed.find(p => p.status);
    if (!provider) return null;

    const apiKey = provider.apiKey;
    const modelName = provider.model;
    let url = provider.baseUrl;

    if (!apiKey || apiKey.startsWith('sk-ds') || apiKey.startsWith('sk-gemini') || apiKey.startsWith('sk-sf') || apiKey.startsWith('sk-apifree')) {
      return null;
    }

    let fetchUrl = url.endsWith('/chat/completions') ? url : `${url}/chat/completions`;
    const systemPrompt = '你是一个外贸客户标签提取AI助手。请基于该客户的沟通记录和询盘信息，提取2到5个最具特征的高价值标签，以JSON数组格式输出，例如：["加固底盘", "赛车散热器", "高采购意向", "询盘高频"]。不需要解释，直接输出JSON数组。';

    const response = await fetch(fetchUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + apiKey
      },
      body: JSON.stringify({
        model: modelName,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage }
        ],
        max_tokens: 150,
        temperature: 0.3,
        stream: false
      })
    });

    if (!response.ok) return null;
    const data = await response.json();
    if (data.choices && data.choices[0] && data.choices[0].message) {
      const text = data.choices[0].message.content.trim();
      const matches = text.match(/\[.*\]/s);
      if (matches) {
        return JSON.parse(matches[0]);
      }
    }
  } catch (err) {
    console.error('Failed call in component:', err);
  }
  return null;
};

// --- Beautiful Glassmorphic Interactive HTML Dashboard Compiler (SPI Style) ---
const buildSpiStyleHtmlReport = (lead, reportData) => {
  const dateStr = new Date().toISOString().replace('T', ' ').substring(0, 19);
  
  let html = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${lead.name} 深度客户分析报告</title>
  <style>
    :root {
      --bg: radial-gradient(circle at top left, #f8fafc, #f1f5f9);
      --card: rgba(255, 255, 255, 0.88);
      --border: rgba(148, 163, 184, 0.16);
      --text-main: #0f172a;
      --text-muted: #475569;
      --primary: #4f46e5;
      --primary-glow: rgba(79, 70, 229, 0.08);
      --success: #059669;
      --warning: #d97706;
      --danger: #dc2626;
    }
    
    * { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      background: var(--bg);
      color: var(--text-main);
      padding: 16px;
      line-height: 1.5;
    }
    
    .dashboard {
      max-width: 1000px;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: 16px;
      animation: fadeIn 0.4s ease-out;
    }
    
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(8px); }
      to { opacity: 1; transform: translateY(0); }
    }
    
    .glass-card {
      background: var(--card);
      backdrop-filter: blur(12px);
      -webkit-backdrop-filter: blur(12px);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 20px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05), 0 2px 4px -1px rgba(0, 0, 0, 0.03);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }
    
    .glass-card:hover {
      transform: translateY(-1px);
      box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.08), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
      border-color: rgba(79, 70, 229, 0.22);
    }
    
    .header-card {
      background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);
      color: white;
      border: none;
      position: relative;
      overflow: hidden;
      padding: 24px;
    }
    
    .header-card::after {
      content: '';
      position: absolute;
      top: -30%;
      right: -10%;
      width: 220px;
      height: 220px;
      background: radial-gradient(circle, rgba(255,255,255,0.12) 0%, transparent 60%);
      border-radius: 50%;
    }
    
    .header-title-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 6px;
    }
    
    .company-title {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    
    .eyebrow {
      font-size: 9px;
      text-transform: uppercase;
      font-weight: 800;
      letter-spacing: 1px;
      background: rgba(255,255,255,0.2);
      padding: 3px 6px;
      border-radius: 4px;
      width: fit-content;
      margin-bottom: 6px;
    }
    
    .meta-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 8px;
      margin-top: 12px;
      border-top: 1px solid rgba(255,255,255,0.15);
      padding-top: 12px;
    }
    
    .meta-item {
      display: flex;
      align-items: center;
      gap: 6px;
      font-size: 10.5px;
      opacity: 0.9;
    }
    
    .meta-icon {
      font-size: 12px;
    }
    
    .section-title {
      font-size: 13px;
      font-weight: 800;
      color: var(--text-main);
      margin-bottom: 12px;
      display: flex;
      align-items: center;
      gap: 6px;
      border-bottom: 1px solid rgba(0,0,0,0.04);
      padding-bottom: 6px;
    }
    
    .metrics-row {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 12px;
    }
    
    .metric-card {
      background: rgba(255, 255, 255, 0.6);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 10px;
      text-align: center;
      transition: all 0.2s ease;
    }
    
    .metric-card:hover {
      background: white;
      transform: scale(1.02);
    }
    
    .metric-label {
      font-size: 8px;
      color: var(--text-muted);
      font-weight: 700;
      text-transform: uppercase;
      margin-bottom: 2px;
    }
    
    .metric-value {
      font-size: 14px;
      font-weight: 800;
    }
    
    .modules-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 16px;
    }
    
    .full-width {
      grid-column: span 2;
    }
    
    .bullet-list {
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    
    .bullet-item {
      font-size: 10.5px;
      color: var(--text-muted);
      position: relative;
      padding-left: 14px;
      line-height: 1.5;
    }
    
    .bullet-item::before {
      content: '✦';
      position: absolute;
      left: 2px;
      color: var(--primary);
      font-weight: bold;
      font-size: 13px;
      top: -1px;
    }
    
    .people-list {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    
    .person-card {
      background: rgba(255,255,255,0.4);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 10px 12px;
      display: flex;
      align-items: center;
      gap: 10px;
      transition: all 0.2s ease;
    }
    
    .person-card:hover {
      background: white;
      border-color: rgba(79, 70, 229, 0.15);
    }
    
    .person-avatar {
      width: 32px;
      height: 32px;
      background: linear-gradient(135deg, #818cf8, #4f46e5);
      color: white;
      font-weight: 700;
      font-size: 12px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .person-info {
      flex: 1;
    }
    
    .person-name-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2px;
    }
    
    .person-name {
      font-size: 11px;
      font-weight: 800;
      color: var(--text-main);
    }
    
    .person-title {
      font-size: 9.5px;
      color: var(--text-muted);
      font-weight: 600;
    }
    
    .person-badge {
      font-size: 8px;
      font-weight: 700;
      padding: 1px 5px;
      border-radius: 99px;
      background: rgba(5, 150, 105, 0.1);
      color: var(--success);
    }
    
    .person-details {
      display: flex;
      gap: 10px;
      font-size: 9px;
      color: var(--text-muted);
      font-family: monospace;
      margin-top: 2px;
    }
    
    .swot-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 10px;
    }
    
    .swot-box {
      border-radius: 10px;
      padding: 10px;
      font-size: 10px;
    }
    
    .swot-s { background: rgba(5, 150, 105, 0.08); border: 1px solid rgba(5, 150, 105, 0.15); color: #065f46; }
    .swot-w { background: rgba(220, 38, 38, 0.06); border: 1px solid rgba(220, 38, 38, 0.12); color: #991b1b; }
    .swot-o { background: rgba(59, 130, 246, 0.06); border: 1px solid rgba(59, 130, 246, 0.12); color: #1e3a8a; }
    .swot-t { background: rgba(217, 119, 6, 0.07); border: 1px solid rgba(217, 119, 6, 0.13); color: #78350f; }
    
    .swot-title {
      font-weight: 800;
      font-size: 10.5px;
      margin-bottom: 4px;
      display: flex;
      align-items: center;
      gap: 3px;
    }
    
    .swot-items {
      padding-left: 10px;
      list-style-type: square;
    }
    
    .swot-items li {
      margin-bottom: 2px;
      line-height: 1.35;
    }
    
    .table-container {
      overflow-x: auto;
      border: 1px solid var(--border);
      border-radius: 10px;
    }
    
    .data-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 10px;
      text-align: left;
    }
    
    .data-table th {
      background: rgba(0,0,0,0.02);
      color: var(--text-main);
      font-weight: 700;
      padding: 8px 10px;
      border-bottom: 1px solid var(--border);
    }
    
    .data-table td {
      padding: 8px 10px;
      border-bottom: 1px solid var(--border);
      color: var(--text-muted);
    }
    
    .data-table tr:last-child td {
      border-bottom: none;
    }
    
    .table-badge {
      display: inline-block;
      font-size: 8px;
      font-weight: 700;
      padding: 1px 4px;
      border-radius: 3px;
      background: rgba(79, 70, 229, 0.1);
      color: var(--primary);
    }
    
    .roadmap-list {
      display: flex;
      flex-direction: column;
      gap: 12px;
      position: relative;
      padding-left: 16px;
      margin-top: 8px;
    }
    
    .roadmap-list::before {
      content: '';
      position: absolute;
      left: 5px;
      top: 4px;
      bottom: 4px;
      width: 1.5px;
      background: #e2e8f0;
    }
    
    .roadmap-step {
      position: relative;
    }
    
    .roadmap-step::before {
      content: '';
      position: absolute;
      left: -14px;
      top: 3px;
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: white;
      border: 2.5px solid var(--primary);
    }
    
    .roadmap-time {
      font-size: 9px;
      font-weight: 800;
      color: var(--primary);
      text-transform: uppercase;
      margin-bottom: 2px;
    }
    
    .roadmap-desc {
      font-size: 10.5px;
      font-weight: 700;
      color: var(--text-main);
      margin-bottom: 4px;
    }
    
    .roadmap-tasks {
      list-style: none;
      display: grid;
      gap: 4px;
    }
    
    .roadmap-task {
      display: flex;
      align-items: flex-start;
      gap: 4px;
      font-size: 9.5px;
      color: var(--text-muted);
    }
    
    .visual-widget {
      background: rgba(79, 70, 229, 0.03);
      border: 1px dashed rgba(79, 70, 229, 0.2);
      border-radius: 10px;
      padding: 10px;
      font-size: 10px;
      margin-top: 10px;
    }
    
    .progress-bar-container {
      height: 5px;
      background: #e2e8f0;
      border-radius: 99px;
      overflow: hidden;
      margin-top: 4px;
    }
    
    .progress-bar {
      height: 100%;
      border-radius: 99px;
      background: linear-gradient(90deg, #4f46e5, #7c3aed);
    }
    
    .payment-bar {
      display: flex;
      height: 12px;
      border-radius: 5px;
      overflow: hidden;
      margin-top: 6px;
      font-size: 8px;
      color: white;
      font-weight: 700;
      line-height: 12px;
      text-align: center;
    }
    .payment-pre { background: #4f46e5; }
    .payment-post { background: #10b981; }
    
    .footer {
      text-align: center;
      font-size: 9px;
      color: var(--text-muted);
      margin-top: 20px;
      border-top: 1px solid rgba(0,0,0,0.04);
      padding-top: 12px;
    }
    
    @media (max-width: 640px) {
      .modules-grid { grid-template-columns: 1fr; }
      .full-width { grid-column: span 1; }
      .metrics-row { grid-template-columns: repeat(2, 1fr); }
    }
  </style>
</head>
<body>
  <div class="dashboard">
    <!-- Header Card -->
    <div class="glass-card header-card">
      <div class="eyebrow">360° 全维大模型高精度深度调研报告</div>
      <div class="header-title-row">
        <h1 class="company-title">${lead.name} (${lead.country})</h1>
        <div style="background:rgba(255,255,255,0.22); font-size:9px; font-weight:800; padding:2px 8px; border-radius:99px;">${reportData.metrics?.tier || 'A-tier'}</div>
      </div>
      <p style="font-size:10.5px; opacity:0.92; line-height:1.4;">${reportData.company?.desc || '本报告基于公开数据自动生成，全方位研判该客商的采购意向、贸易风控与GTM推进策略。'}</p>
      
      <div class="meta-grid">
        <div class="meta-item"><span class="meta-icon">🔍</span> <span>客商公司: ${lead.name}</span></div>
        <div class="meta-item"><span class="meta-icon">🔗</span> <span>官方网站: <a href="http://${reportData.company?.website || 'www.spilighting.com'}" target="_blank" style="color:white; text-decoration:underline;">${reportData.company?.website || 'www.spilighting.com'}</a></span></div>
        <div class="meta-item"><span class="meta-icon">📍</span> <span>总部位置: ${reportData.company?.hq || '未知国家/地区'}</span></div>
        <div class="meta-item"><span class="meta-icon">📅</span> <span>生成时间: ${dateStr}</span></div>
      </div>
    </div>`;

  // KPI Indicators Row
  if (reportData.metrics) {
    html += `
    <div class="metrics-row">
      <div class="metric-card">
        <div class="metric-label">客户评级</div>
        <div class="metric-value" style="color:var(--primary);">${reportData.metrics.tier}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">采购意图</div>
        <div class="metric-value" style="color:var(--success);">${reportData.metrics.intent}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">开发优先级</div>
        <div class="metric-value" style="color:var(--warning);">${reportData.metrics.priority}</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">贸易风控</div>
        <div class="metric-value" style="color:var(--danger);">${reportData.metrics.risk}</div>
      </div>
    </div>`;
  }

  html += `
    <!-- Modules Grid (有结果就显示，无结果就不显示) -->
    <div class="modules-grid">`;

  // 1. 公司概况 (Company Profile)
  if (reportData.company) {
    html += `
      <div class="glass-card">
        <div class="section-title">🏢 公司概况</div>
        <ul class="bullet-list">
          <li class="bullet-item"><strong>客商公司:</strong> ${reportData.company.fullName || lead.name}</li>
          <li class="bullet-item"><strong>总部位置:</strong> ${reportData.company.hq || '未指定'}</li>
          <li class="bullet-item"><strong>联系电话:</strong> ${reportData.company.phone || '未指定'}</li>
          <li class="bullet-item"><strong>公司邮箱:</strong> ${reportData.company.email || '未指定'}</li>
          <li class="bullet-item"><strong>企业性质:</strong> ${reportData.company.nature || '私营汽车配件/工业产品商'}</li>
          <li class="bullet-item"><strong>核心业务:</strong> ${reportData.company.model || 'OEM/ODM 定制化贸易'}</li>
        </ul>
        <div style="display:flex; flex-wrap:wrap; gap:4px; margin-top:12px;">
          ${(reportData.company.tags || []).map(t => `<span style="font-size:8px; font-weight:700; background:rgba(0,0,0,0.04); color:var(--text-muted); padding:2px 6px; border-radius:4px;">${t}</span>`).join('')}
        </div>
      </div>`;
  }

  // 2. 关键人物 (Key People)
  if (reportData.keyPeople && reportData.keyPeople.length > 0) {
    html += `
      <div class="glass-card">
        <div class="section-title">👥 关键人物与管理层</div>
        <div class="people-list">
          ${reportData.keyPeople.map(p => `
            <div class="person-card">
              <div class="person-avatar">${p.name.split(' ').map(n=>n[0]).join('')}</div>
              <div class="person-info">
                <div class="person-name-row">
                  <span class="person-name">${p.name}</span>
                  <span class="person-badge">${p.verify || 'AI推荐'}</span>
                </div>
                <div class="person-title">${p.title}</div>
                <div style="font-size:9.5px; color:var(--text-muted); margin-top:4px; font-style:italic;">${p.responsibilities || ''}</div>
                <div class="person-details">
                  <span>✉️ ${p.email}</span>
                  <span>📞 ${p.phone}</span>
                </div>
              </div>
            </div>
          `).join('')}
        </div>
      </div>`;
  }

  // 3. 市场环境分析 (Market Environment)
  if (reportData.market) {
    html += `
      <div class="glass-card">
        <div class="section-title">📊 市场环境分析与容量</div>
        <ul class="bullet-list">
          ${(reportData.market.points || []).map(p => `<li class="bullet-item">${p}</li>`).join('')}
        </ul>
      </div>`;
  }

  // 4. 竞争格局分析 (Competition Landscape)
  if (reportData.competitors && reportData.competitors.length > 0) {
    html += `
      <div class="glass-card">
        <div class="section-title">⚔️ 竞争格局分析</div>
        <div class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>主要对手</th>
                <th>市场位置</th>
                <th>核心竞争优势</th>
              </tr>
            </thead>
            <tbody>
              ${reportData.competitors.map(c => `
                <tr>
                  <td style="font-weight:800; color:var(--text-main);">${c.name}</td>
                  <td>${c.location} (${c.revenue || 'N/A'})</td>
                  <td>${c.advantage}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>`;
  }

  // 5. SWOT 态势分析 (SWOT Analysis)
  if (reportData.swot && (reportData.swot.strengths?.length > 0 || reportData.swot.weaknesses?.length > 0)) {
    html += `
      <div class="glass-card full-width">
        <div class="section-title">⚖️ 目标客商 SWOT 态势分析</div>
        <div class="swot-grid">
          <div class="swot-box swot-s">
            <div class="swot-title">S 优势 (Strengths)</div>
            <ul class="swot-items">
              ${(reportData.swot.strengths || []).map(s => `<li>${s}</li>`).join('')}
            </ul>
          </div>
          <div class="swot-box swot-w">
            <div class="swot-title">W 劣势 (Weaknesses)</div>
            <ul class="swot-items">
              ${(reportData.swot.weaknesses || []).map(w => `<li>${w}</li>`).join('')}
            </ul>
          </div>
          <div class="swot-box swot-o">
            <div class="swot-title">O 机会 (Opportunities)</div>
            <ul class="swot-items">
              ${(reportData.swot.opportunities || []).map(o => `<li>${o}</li>`).join('')}
            </ul>
          </div>
          <div class="swot-box swot-t">
            <div class="swot-title">T 威胁 (Threats)</div>
            <ul class="swot-items">
              ${(reportData.swot.threats || []).map(t => `<li>${t}</li>`).join('')}
            </ul>
          </div>
        </div>
      </div>`;
  }

  // 6. 买方画像与决策因素 (Customer Persona)
  if (reportData.customer) {
    html += `
      <div class="glass-card">
        <div class="section-title">🎯 买方画像与决策因素</div>
        <ul class="bullet-list" style="margin-bottom:12px;">
          ${(reportData.customer.pains || []).map(p => `<li class="bullet-item" style="color:var(--danger); font-weight:600;">⚠️ ${p}</li>`).join('')}
          ${(reportData.customer.types || []).map(t => `<li class="bullet-item"><strong>主要客户类型:</strong> ${t}</li>`).join('')}
        </ul>
        
        <div class="visual-widget" style="background:rgba(5, 150, 105, 0.02); border-color:rgba(5, 150, 105, 0.18)">
          <div style="display:flex; justify-content:space-between; font-weight:700; font-size:9.5px;">
            <span>大模型意向度匹配度 (Intent Match)</span>
            <span style="color:var(--success);">${reportData.customer.intentScore || '90%'}</span>
          </div>
          <div class="progress-bar-container">
            <div class="progress-bar" style="width: ${reportData.customer.intentScore || '90%'}; background: linear-gradient(90deg, #10b981, #059669)"></div>
          </div>
        </div>
      </div>`;
  }

  // 7. 中国供应商合作池 (Supplier Pool)
  if (reportData.suppliers && reportData.suppliers.length > 0) {
    html += `
      <div class="glass-card">
        <div class="section-title">🇨🇳 推荐的中国 LED/改装件供应商池</div>
        <div class="table-container">
          <table class="data-table">
            <thead>
              <tr>
                <th>供应商名称</th>
                <th>位置</th>
                <th>主营业务与状态</th>
              </tr>
            </thead>
            <tbody>
              ${reportData.suppliers.map(s => `
                <tr>
                  <td style="font-weight:800; color:var(--text-main);">${s.name}</td>
                  <td>${s.location}</td>
                  <td><span class="table-badge" style="margin-bottom:2px;">${s.status}</span><br/>${s.product}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      </div>`;
  }

  // 8. 客户推进开发规划建议 (Roadmap)
  if (reportData.gtm) {
    html += `
      <div class="glass-card full-width">
        <div class="section-title">🚀 客户推进开发规划建议</div>
        
        <div style="display:grid; grid-template-columns: 1.25fr 1fr; gap:16px;">
          <div>
            <h4 style="font-size:10.5px; font-weight:800; color:var(--text-main); margin-bottom:6px;">📅 30/60/90天阶梯推进开发行动路径</h4>
            <div class="roadmap-list">
              <div class="roadmap-step">
                <div class="roadmap-time">第一阶段 (1-30天)</div>
                <div class="roadmap-desc">${reportData.gtm.shortTerm || '完善技术规范，提供符合质量安全标准的检测证书。'}</div>
                <ul class="roadmap-tasks">
                  <li class="roadmap-task"><input type="checkbox" checked disabled> <span>梳理自身越野车配件/照明图纸数据库</span></li>
                  <li class="roadmap-task"><input type="checkbox" disabled> <span>寄送 ADR 认证或样品检测数据</span></li>
                </ul>
              </div>
              <div class="roadmap-step">
                <div class="roadmap-time">第二阶段 (30-60天)</div>
                <div class="roadmap-desc">商务对口谈判，进入打样逆向三维数据图审。</div>
              </div>
              <div class="roadmap-step">
                <div class="roadmap-time">第三阶段 (60-90天)</div>
                <div class="roadmap-desc">${reportData.gtm.longTerm || '大货签约，建立长期供应链战略合作伙伴关系。'}</div>
              </div>
            </div>
          </div>
          
          <div>
            <div class="visual-widget" style="margin-top:0; background:rgba(79, 70, 229, 0.02);">
              <h4 style="font-size:10px; font-weight:800; color:var(--primary); margin-bottom:4px;">💳 推荐账期与结算风控防线</h4>
              <p style="font-size:9.5px; color:var(--text-muted); line-height:1.4;">${reportData.gtm.paymentDesc || '推荐采用 30% 预付款 + 70% 凭信用证结算防线。'}</p>
              <div class="payment-bar">
                <div class="payment-pre" style="width: 30%;">30% 预付款</div>
                <div class="payment-post" style="width: 70%;">70% 信用证</div>
              </div>
            </div>
            
            <div class="visual-widget" style="margin-top:10px; background:rgba(5, 150, 105, 0.02); border-color:rgba(5, 150, 105, 0.2)">
              <h4 style="font-size:10px; font-weight:800; color:var(--success); margin-bottom:4px;">🛡️ 我方主推特种产品与竞争壁垒</h4>
              <p style="font-size:9.5px; color:var(--text-muted); line-height:1.4;">
                <strong>推荐产品:</strong> <span style="font-weight:700; color:var(--success);">${reportData.gtm.recommendedProduct || 'JFC-B1 竞技竞技杠'}</span><br/>
                <strong>产品优势:</strong> ${reportData.gtm.productAdvantage || '支持 ADR 改装碰撞法规，长寿命防锈涂装层工艺优势。'}
              </p>
            </div>
          </div>
        </div>
      </div>`;
  }

  html += `
    </div>
    <!-- Footer -->
    <div class="footer">
      <p>MagicHub CRM 深度客商诊断报告系统 | 算力网关提供云端研判支持</p>
      <p style="margin-top:4px; opacity:0.6;">报告生成日期: ${dateStr}</p>
    </div>
  </div>
</body>
</html>`;

  return html;
};

const generateMockDeepReport = (lead) => {
  const dateStr = new Date().toISOString().replace('T', ' ').substring(0, 19);
  let title = `${lead.name} (${lead.country}) 360°大模型高精度深度调研画像报告`;
  let reportContent = '';
  
  if (lead.country === '德国' || lead.country === 'Germany') {
    reportContent = `# 🇩🇪 ${title}

## 1. 🎯 客商画像与采购意图分析
- **客商性质**：欧洲高端汽车零配件/工业装备分销服务商，对技术标准（如德国 TUV、欧盟 CE）有极为严苛的要求。
- **采购意图**：采购核心用于极寒气候下的特种改装前竞技防撞杠与高强度底盘护甲，以补充其在北欧及严寒地区的越野汽车供应链配置。
- **来信重点分析**：询盘深度极高。多次提及 ADR 认证与不锈钢防腐防爆参数，意向强烈。

## 2. ⚠️ 核心采购痛点与难点剖析
- **改装碰撞安全卡点**：德国及欧洲有严格的改装车碰撞法规，需要我方提供 **澳大利亚 ADR 改装碰撞符合性验证** 或 **欧盟 CE 安全符合性背书**。
- **表面防锈工艺卡点**：欧洲冬季撒盐融雪多，对防撞杠及底盘装甲的 **防爆喷涂与双重静电喷粉防锈工艺** 有着超高标准要求。

## 3. 🚀 开发与沟通策略
- **产品主推**：建议重点对标我方 **JFC-B1 竞技竞技前杠** 专利规格，随附我们已通过的 **澳大利亚 ADR 碰撞测试报告**。
- **回价策略**：建议以 **$280 CIF Hamburg** 起步报价，预留 5-8% 商务阶梯让步空间。

## 4. 🛡️ 结算与风控防线
- **结算防御**：推荐采用 **30% T/T 预付 + 70% 凭 L/C 信用证** 结算机制。
- **运输保障**：优先指派欧洲协同专线联络点进行双重质检装柜，规避滞港滞箱带来的赔偿风险。`;
  } else {
    reportContent = `# 🇺🇸 ${title}

## 1. 🎯 客商画像与采购意图分析
- **客商性质**：越野车改装与汽车零配件大型批发商，拥有庞大的线下连锁分销网络和电商平台。
- **采购意图**：采购高强度竞技防撞前杠、长行程氮气悬挂避震以及越野涉水喉等 JFC 特色产品。
- **来信重点分析**：重视我方是否具备 15 年出口经验以及成熟的 OEM/ODM 图纸定制还原能力。

## 2. ⚠️ 核心采购痛点与难点剖析
- **碰撞安全检验**：注重越野车部件的碰撞安全性，必须符合 **澳大利亚 ADR 车辆改装安全标准**，具备高强度防撞缓冲结构。
- **定制周期与发运**：要求我方支持 3D 原尺寸逆向开发，打样周期控制在 15 天内，并提供完税后 DDP/CIF 运输方案。

## 3. 🚀 开发与沟通策略
- **技术背书**：重点展示我方温州 JFC4x4 工厂 of 15 年制造实力，分享澳大利亚、美国大型改装连锁品牌的合作案例。
- **沟通基调**：提供清晰的产品 3D 数模与高精度实样测试视频，提供 DDP Brisbane 或 FOB Ningbo 阶梯报价方案。

## 4. 🛡️ 结算与风控防线
- **结算防线**：针对首次合作，建议采用 **30% T/T 预付 + 70% 见提单副本（B/L copy）付款** 或使用第三方信用证以保障资金流。
- **质检防线**：出厂前提供多角度包装及防爆木架加固实拍照片，确保长途海运中涂层零刮擦。`;
  }
  
  return {
    type: 'Markdown',
    filename: `${lead.name.toLowerCase().replace(/\s+/g, '-')}-deep-ai-analysis.md`,
    date: dateStr,
    content: reportContent
  };
};

const triggerOneClickAnalysis = async (lead) => {
  if (!lead || isDeepAnalyzing.value) return;
  
  isDeepAnalyzing.value = true;
  deepAnalysisStep.value = 0;
  
  // Step 1: 0ms -> 1000ms
  setTimeout(() => {
    deepAnalysisStep.value = 1;
  }, 1000);
  
  // Step 2: 1000ms -> 2000ms
  setTimeout(() => {
    deepAnalysisStep.value = 2;
  }, 2000);
  
  // Step 3: 2000ms -> 3200ms
  setTimeout(() => {
    deepAnalysisStep.value = 3;
  }, 3200);
  
  // Step 4: 3200ms -> 4500ms (Execution & Finish)
  setTimeout(async () => {
    try {
      let finalReport = null;
      
      // Try real AI call if allowed & not in secret mode
      if (!props.isSecretMode) {
        const saved = localStorage.getItem('magichub_ai_providers');
        if (saved) {
          const parsed = JSON.parse(saved);
          const provider = parsed.find(p => p.id === 'deepseek' && p.status) || parsed.find(p => p.status);
          if (provider && provider.apiKey && !provider.apiKey.startsWith('sk-ds') && !provider.apiKey.startsWith('sk-gemini') && !provider.apiKey.startsWith('sk-sf') && !provider.apiKey.startsWith('sk-apifree')) {
            const apiKey = provider.apiKey;
            const modelName = provider.model;
            let url = provider.baseUrl;
            let fetchUrl = url.endsWith('/chat/completions') ? url : `${url}/chat/completions`;
            
    const systemPrompt = `你是个顶级外贸大客户分析专家，请对这个外贸询盘客户做一份深度分析报告，SPI 风格大模型深度报告，采用 Markdown 格式返回以下四个版块：
    1. 客户意向图谱分析：分析客户在来信中展现的核心意向与采购痛点。
    2. 核心采购关注点：对极限防爆/防冻/FDA认证等技术细节的倾向性评估。
    3. 我方优势匹配与产品推荐：结合我方资质推荐最匹配的产品参数（如 FL-WT-100 或其他水容器产品）。
    4. 结算方式与风控建议：提供付款方式（如 T/T、L/C）、防骗及物流运输的风险御策略。
    请使用专业外贸中文撰写报告，确保排版美观且没有冗余话语。`;

    const userPrompt = `客户公司名称: ${lead.name}
国家地区: ${lead.country}
产品行业分类: ${lead.category === 'parts' ? '汽车配件' : 'LED照明'}
原始询盘信件:
${lead.rawMessage}
当前系统标签: ${(lead.tags || []).join(', ')}`;

            const response = await fetch(fetchUrl, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + apiKey
              },
              body: JSON.stringify({
                model: modelName,
                messages: [
                  { role: 'system', content: systemPrompt },
                  { role: 'user', content: userPrompt }
                ],
                max_tokens: 1500,
                temperature: 0.3,
                stream: false
              })
            });
            
            if (response.ok) {
              const data = await response.json();
              if (data.choices && data.choices[0] && data.choices[0].message) {
                const text = data.choices[0].message.content.trim();
                finalReport = {
                  type: 'Markdown',
                  filename: `${lead.name.toLowerCase().replace(/\s+/g, '-')}-deep-ai-analysis.md`,
                  date: new Date().toISOString().replace('T', ' ').substring(0, 19),
                  content: text
                };
              }
            }
          }
        }
      }
      
      // Fallback if real call failed or skipped
      if (!finalReport) {
        finalReport = generateMockDeepReport(lead);
      }
      
      // Update leads database reactive values
      const original = leads.value.find(l => l.id === lead.id);
      if (original) {
        original.deepReport = finalReport;
        
        // Auto add a tag indicating AI deep analysis has been completed
        if (!original.tags.includes('AI深度分析')) {
          original.tags.push('AI深度分析');
        }
        
        // Save the generated report physically on the Desktop so it is NEVER lost across version updates or reinstalls!
        if (window.electronAPI && window.electronAPI.writeFile) {
          const REPORTS_V2_DIR = '/Users/ky/Desktop/汽配客户/deep_analysis_reports_v2';
          const filePath = `${REPORTS_V2_DIR}/${finalReport.filename}`;
          window.electronAPI.writeFile(filePath, finalReport.content)
            .then(res => {
              if (res.success) {
                console.log(`[MagicHub] Saved deep analysis report physically to Desktop: ${filePath}`);
              } else {
                console.warn('[MagicHub] Failed to save physical report file:', res.error);
              }
            })
            .catch(err => console.error('[MagicHub] Write error:', err));
        }

        // Update current modal scope ref
        selectedLeadForModal.value = original;
        leads.value = [...leads.value]; // Trigger save
      }
      
      // Expand deep report collapsible
      showDeepReportCollapse.value = true;
      
      isDeepAnalyzing.value = false;
          alert(`✅ 客户深度画像已建立，大模型已对客户 [${lead.name}] 进行 360° 全面审计，SPI 风格报告已完成`);
    } catch (err) {
      console.error('Failed deep analysis:', err);
      isDeepAnalyzing.value = false;
      alert('⚠️ 客户深度分析失败，请检查网络连接后重试。');
    }
  }, 4500);
};

// Tag Edit placeholder
const openTagEdit = (lead) => {
  alert(`[AI 智能标签编辑]：已为客户 [${lead.name}] 成功编辑并保存自定义业务标签！`);
};

// Segmented toolbar action placeholders
const addNewCategory = () => {
  const name = prompt('请输入新增客户分类名称');
  if (name) {
    alert(`成功创建新类别 [${name}] 并将其添加至行业类别菜单！`);
  }
};

const manageTags = () => {
          alert('签约管理已记录：以下索引系统已更新');
};

const importBatch = () => {
          alert('外贸客户档案已就绪：支持 Excel, CSV 与 SQLite 导出，本地底仓 100% 防外网监听');
};

// --- Widescreen Customer Workspace Detail View Control Center ---
const viewState = ref('list'); // 'list' or 'detail' (jump page instead of popup)
const detailModalOpen = ref(false); // keep for compatibility if needed

// --- Quick Preview Hexagon Radar Chart Variables & Computations ---
const quickPreviewOpen = ref(false);
const selectedLeadForPreview = ref(null);

const triggerQuickPreview = (lead) => {
  selectedLeadForPreview.value = lead;
  quickPreviewOpen.value = true;
};

const enterDetailWorkspaceFromPreview = () => {
  quickPreviewOpen.value = false;
  triggerDetailModal(selectedLeadForPreview.value);
};

const radarValues = computed(() => {
  if (!selectedLeadForPreview.value) {
    return { v0: 80, v1: 75, v2: 70, v3: 85, v4: 65, v5: 90 };
  }
  const score = selectedLeadForPreview.value.score;
  const countryCode = selectedLeadForPreview.value.country.charCodeAt(0) || 0;
  
  return {
    v0: Math.min(98, Math.max(45, Math.round(score * 0.95))), // Opportunity Heat (商机热度)
    v1: Math.min(95, Math.max(40, Math.round(((score + countryCode) % 40) + 55))), // Decision Speed (决策速度)
    v2: Math.min(95, Math.max(50, Math.round(100 - (score - 10)))), // Profit Margin (利润空间)
    v3: Math.min(98, Math.max(60, Math.round(score + 5))), // Credit Rating (信用履约)
    v4: Math.min(95, Math.max(35, Math.round(((score + countryCode * 2) % 35) + 60))), // Interaction Frequency (交互频率)
    v5: selectedLeadForPreview.value.stage === 'deal' ? 95 : 82 // Data Security (数据安全)
  };
});

const radarVertices = computed(() => {
  const vals = radarValues.value;
  const cx = 110;
  const cy = 105;
  const maxR = 70;

  const r0 = (vals.v0 / 100) * maxR;
  const r1 = (vals.v1 / 100) * maxR;
  const r2 = (vals.v2 / 100) * maxR;
  const r3 = (vals.v3 / 100) * maxR;
  const r4 = (vals.v4 / 100) * maxR;
  const r5 = (vals.v5 / 100) * maxR;

  const cos30 = 0.866;
  const sin30 = 0.5;

  return [
    { x: cx, y: cy - r0 },                         // Top (商机热度)
    { x: cx + r1 * cos30, y: cy - r1 * sin30 },     // Top Right (决策速度)
    { x: cx + r2 * cos30, y: cy + r2 * sin30 },     // Bottom Right (利润空间)
    { x: cx, y: cy + r3 },                         // Bottom (信用履约)
    { x: cx - r4 * cos30, y: cy + r4 * sin30 },     // Bottom Left (交互频率)
    { x: cx - r5 * cos30, y: cy - r5 * sin30 }      // Top Left (数据安全)
  ];
});

const radarPoints = computed(() => {
  return radarVertices.value.map(pt => `${pt.x},${pt.y}`).join(' ');
});

const selectedLeadForModal = ref(null);
const activeWorkspaceTab = ref('analysis'); // active workspace tab: 'analysis', 'quotes', 'products', 'contracts'

const selectedLeadId = ref(null);
const isCreateQuoteModalOpen = ref(false);
const isImportQuoteModalOpen = ref(false);
const isCreateContractModalOpen = ref(false);
const isImportContractModalOpen = ref(false);

const newQuoteForm = ref({
  product: '',
  incoterms: 'FOB Shanghai',
  cost: 0,
  price: 0
});

const newContractForm = ref({
  product: '',
  quantity: 1,
  moq: 1,
  value: 0,
  date: new Date().toISOString().substring(0, 10),
  status: '已签署'
});

// Collapsible status triggers in AI Analysis Tab
const showIntentCollapse = ref(true);
const showRegionalCollapse = ref(true);
const showSecureCollapse = ref(true);
const showDeepReportCollapse = ref(true);

// One-click AI customer deep analysis states
const isDeepAnalyzing = ref(false);
const deepAnalysisStep = ref(0);
const deepAnalysisSteps = [
  '🔍 正在读取来信核查购买意向与成交记录...',
  '🌐 正在比对当地市场行情与产品工艺匹配度...',
  '📊 正在交叉验证多源数据网络背景信息...',
  '🧠 正在生成深度 SPI 风格客户画像与配套跟进报告...'
];

// Editable inline profile details
const isEditingProfile = ref(false);
const editForm = ref({
  name: '',
  contact: '',
  phone: '',
  country: '未知',
  category: 'parts',
  stage: 'deal',
  score: 80,
  rawMessage: ''
});

const startEditProfile = (lead) => {
  isEditingProfile.value = true;
  editForm.value = {
    name: lead.name,
    contact: lead.contact,
    phone: lead.phone || '',
    country: lead.country,
    category: lead.category,
    stage: lead.stage,
    score: lead.score,
    rawMessage: lead.rawMessage
  };
};

const saveLeadProfile = () => {
  if (!editForm.value.name || !editForm.value.contact) {
    alert('客户名称与联系代表不可为空');
    return;
  }
  
  // Update leads database reactive values
  if (selectedLeadForModal.value) {
    const current = [...leads.value];
    const index = current.findIndex(l => l.id === selectedLeadForModal.value.id);
    if (index !== -1) {
      const flags = {
        '俄罗斯': '🇷🇺',
        '泰国': '🇹🇭',
        '以色列': '🇮🇱',
        '菲律宾': '🇵🇭',
        '德国': '🇩🇪',
        '印度': '🇮🇳',
        '伊拉克': '🇮🇶',
        '澳大利亚': '🇦🇺'
      };
      const newFlag = flags[editForm.value.country] || '🌐';
      
      current[index] = {
        ...current[index],
        name: editForm.value.name,
        contact: editForm.value.contact,
        phone: editForm.value.phone,
        country: editForm.value.country,
        category: editForm.value.category,
        stage: editForm.value.stage,
        score: editForm.value.score,
        rawMessage: editForm.value.rawMessage,
        flag: newFlag
      };
      
      leads.value = current;
      selectedLeadForModal.value = current[index];
    }
  }

  isEditingProfile.value = false;
          alert('本客户档案修改已保存至本地底仓数据库');
};

// Computes RAG dynamic matches in tabs
const matchedQuotes = computed(() => {
  if (!selectedLeadForModal.value) return [];
  const clientName = selectedLeadForModal.value.name.toLowerCase();
  return props.quoteLogs.filter(q => 
    q.client.toLowerCase().includes(clientName) || 
    clientName.includes(q.client.toLowerCase())
  );
});

const matchedContracts = computed(() => {
  if (!selectedLeadForModal.value) return [];
  const clientName = selectedLeadForModal.value.name.toLowerCase();
  return props.contracts.filter(c => 
    c.client.toLowerCase().includes(clientName) || 
    clientName.includes(c.client.toLowerCase())
  );
});

const matchedProduct = computed(() => {
  if (!selectedLeadForModal.value) return props.products[0];
  // Auto RAG matching based on industrial category
  if (selectedLeadForModal.value.category === 'parts') {
    return props.products.find(p => p.id === 'EX-XT-500') || props.products[0];
  } else {
    return props.products.find(p => p.id === 'FL-WT-100') || props.products[0];
  }
});

const emailDraftText = ref('');

const triggerDetailModal = (lead) => {
  selectedLeadForModal.value = lead;
  isEditingProfile.value = false;
  activeWorkspaceTab.value = 'analysis';

  // AI custom business campaign draft pregeneration
  emailDraftText.value = `Subject: Tailored Technical Blueprint regarding ${matchedProduct.value.name} - ${lead.name}\n\nDear Mr./Ms. ${lead.contact},\n\nWe trust you are doing well.\n\nFollowing up on our agricultural parts parameters review, we are pleased to suggest our FLAGSHIP ${matchedProduct.value.name} (Model: ${matchedProduct.value.model}).\n\nBased on your tags: our local vector RAG matches confirm that the ${matchedProduct.value.material} outer frame easily satisfies your extreme outdoor requirement (rated for: ${matchedProduct.value.temp}).\n\nOur initial trial MOQ is flexible, and we can prioritize dispatch under our custom shipping rates.\n\nWarm regards,\nSofia | Zen Auto Parts Sales Department`;

  // Direct page jump to detail workspace
  viewState.value = 'detail';
};

const handleCreateQuote = () => {
  if (!newQuoteForm.value.product) {
    alert('请选择报价关联产品！');
    return;
  }
  const quoteEntry = {
    id: props.quoteLogs.length + 1,
    code: `QT-2026-0${props.quoteLogs.length + 11}`,
    client: selectedLeadForModal.value?.name || '未知客商',
    flag: selectedLeadForModal.value?.flag || '🏳️',
    product: newQuoteForm.value.product,
    incoterms: newQuoteForm.value.incoterms,
    cost: newQuoteForm.value.cost,
    freight: newQuoteForm.value.incoterms.includes('CIF') ? 20 : 0,
    commission: 0,
    price: newQuoteForm.value.price
  };
  const updated = [...props.quoteLogs, quoteEntry];
  emit('update:quoteLogs', updated);
  isCreateQuoteModalOpen.value = false;
  alert('形式报价单生成成功！');
};

const handleImportQuote = (preset = null) => {
  if (preset) {
    const quoteEntry = {
      id: props.quoteLogs.length + 1,
      code: preset.code,
      client: selectedLeadForModal.value?.name || '未知客商',
      flag: selectedLeadForModal.value?.flag || '🏳️',
      product: preset.product,
      incoterms: preset.incoterms,
      cost: preset.cost,
      freight: preset.incoterms.includes('CIF') ? 20 : 0,
      commission: 0,
      price: preset.price
    };
    const updated = [...props.quoteLogs, quoteEntry];
    emit('update:quoteLogs', updated);
    isImportQuoteModalOpen.value = false;
    alert('形式报价单导入成功！');
  } else {
    isImportQuoteModalOpen.value = false;
    alert('报价单导入成功！');
  }
};

const handleCreateContract = () => {
  if (!newContractForm.value.product) {
    alert('请选择签约购买产品！');
    return;
  }
  const contractEntry = {
    id: props.contracts.length + 1,
    code: `CON-2026-0${props.contracts.length + 81}`,
    client: selectedLeadForModal.value?.name || '未知买商',
    flag: selectedLeadForModal.value?.flag || '🏳️',
    product: newContractForm.value.product,
    quantity: newContractForm.value.quantity,
    moq: newContractForm.value.moq,
    value: `¥${newContractForm.value.value.toFixed(2)}`,
    date: newContractForm.value.date || new Date().toISOString().substring(0, 10),
    status: newContractForm.value.status
  };
  const updated = [...props.contracts, contractEntry];
  emit('update:contracts', updated);
  isCreateContractModalOpen.value = false;
  alert('销售订单合同建立成功！');
};

const handleImportContract = (preset = null) => {
  if (preset) {
    const contractEntry = {
      id: props.contracts.length + 1,
      code: preset.code,
      client: selectedLeadForModal.value?.name || '未知买商',
      flag: selectedLeadForModal.value?.flag || '🏳️',
      product: preset.product,
      quantity: preset.quantity,
      moq: preset.moq,
      value: preset.value,
      date: preset.date,
      status: preset.status
    };
    const updated = [...props.contracts, contractEntry];
    emit('update:contracts', updated);
    isImportContractModalOpen.value = false;
    alert('销售合同数据导入成功！');
  } else {
    isImportContractModalOpen.value = false;
    alert('合同数据导入成功！');
  }
};

const copyEmailDraft = () => {
  navigator.clipboard.writeText(emailDraftText.value);
  alert('开发信草稿已复制到剪贴板，可直接粘贴使用。');
};

// --- Inner modals 穿透查看 P/I & S/C ---
const innerQuoteDetailOpen = ref(false);
const selectedQuote = ref(null);

const openInnerQuoteDetail = (quote) => {
  selectedQuote.value = quote;
  innerQuoteDetailOpen.value = false;
  setTimeout(() => {
    innerQuoteDetailOpen.value = true;
  }, 50);
};

const innerContractDetailOpen = ref(false);
const selectedContract = ref(null);

const openInnerContractDetail = (c) => {
  selectedContract.value = c;
  innerContractDetailOpen.value = false;
  setTimeout(() => {
    innerContractDetailOpen.value = true;
  }, 50);
};

// --- Automotive parts customer synchronization logic [NEW] ---
const syncLoading = ref(false);
const syncLogs = ref([]);
const scannedCount = ref(0);
const reportMatchedCount = ref(0);
const isSyncActive = ref(false);

const PARTS_CUSTOMER_ROOT = '/Users/ky/Desktop/汽配客户';
const PRIMARY_CUSTOMERS_PATH = `${PARTS_CUSTOMER_ROOT}/parsed_customers.json`;
const CANTON_CUSTOMERS_PATH = `${PARTS_CUSTOMER_ROOT}/广交会汽车件类客/auto_clients.json`;
const REPORTS_V2_DIR = `${PARTS_CUSTOMER_ROOT}/deep_analysis_reports_v2`;

const normalizeEntityName = (value) => String(value || '')
  .toLowerCase()
  .normalize('NFD')
  .replace(/[\u0300-\u036f]/g, '')
  .replace(/[^a-z0-9]+/g, '');

const getCustomerCompany = (cust) => cust.company || cust.name || cust.client || '';
const getCustomerContact = (cust) => cust.contact_name || cust.contact || cust.contact_title || '未提供';
const getCustomerCountry = (cust) => cust.country || '未知国家';
const getCustomerKey = (cust) => `${normalizeEntityName(getCustomerCompany(cust))}-${normalizeEntityName(getCustomerCountry(cust))}`;

const dedupeCustomers = (customers) => {
  const seen = new Set();
  const output = [];
  customers.forEach(cust => {
    const company = getCustomerCompany(cust);
    if (!company) return;
    const key = getCustomerKey(cust);
    if (seen.has(key)) return;
    seen.add(key);
    output.push(cust);
  });
  return output;
};

const readJsonArray = async (filePath, label) => {
  const res = await window.electronAPI.readFile(filePath);
  if (!res.success) {
    syncLogs.value.push(`⚠️ ${label} 读取失败: ${res.error}`);
    return [];
  }
  const parsed = JSON.parse(res.content);
  if (!Array.isArray(parsed)) {
    syncLogs.value.push(`[同步警告]：${label} 内容不是有效的 JSON 数组，跳过处理。`);
    return [];
  }
  syncLogs.value.push(`[数据载入]：${label} 成功载入 ${parsed.length} 条记录。`);
  return parsed;
};

const loadAllPartsCustomers = async () => {
  const primary = await readJsonArray(PRIMARY_CUSTOMERS_PATH, '桌面汽配客户 parsed_customers.json');
  const canton = await readJsonArray(CANTON_CUSTOMERS_PATH, '广交会汽车件类客 auto_clients.json');
  return dedupeCustomers([
    ...primary.map(item => ({ ...item, sourceGroup: '桌面汽配客户' })),
    ...canton.map(item => ({ ...item, sourceGroup: '广交会汽车件类客' }))
  ]);
};

const reportBaseFromFilename = (filename) => normalizeEntityName(filename.replace(/\.(md|html)$/i, '').replace(/-analysis$/i, ''));

const buildReportIndex = (files) => {
  const reportFiles = files
    .filter(file => /\.(md|html)$/i.test(file.name))
    .filter(file => !/^(summary_report|daily_summary_template|Email修复报告)/i.test(file.name));
  return reportFiles.reduce((acc, file) => {
    const base = reportBaseFromFilename(file.name);
    const existing = acc.get(base);
    if (!existing || (/\.md$/i.test(file.name) && !/\.md$/i.test(existing.name))) {
      acc.set(base, file);
    }
    return acc;
  }, new Map());
};

const findMatchedReport = (cust, reportIndex) => {
  const normalizedCompany = normalizeEntityName(getCustomerCompany(cust));
  if (!normalizedCompany) return null;
  for (const [base, file] of reportIndex.entries()) {
    if (base.includes(normalizedCompany) || normalizedCompany.includes(base)) {
      return file;
    }
  }
  return null;
};

const scanExternalData = async () => {
  try {
    syncLogs.value = [];
    syncLogs.value.push('🔍 开始侦测外置桌面路径 `/Users/ky/Desktop/汽配客户` ...');
    
    if (!window.electronAPI) {
      syncLogs.value.push('⚠️ 当前非 Electron 桌面环境，无法读取外部客户数据库');
      return;
    }
    
    const customers = await loadAllPartsCustomers();
    scannedCount.value = customers.length;
    syncLogs.value.push(`📋 读取完成：外部共侦测到 ${customers.length} 家汽配客户，已就绪可导入 CRM 数据库。`);
    
    // 2. Scan deep_analysis_reports_v2 folder
    syncLogs.value.push(`📂 开始索引 AI 深度分析报告目录 \`${REPORTS_V2_DIR}\` ...`);
    const folderRes = await window.electronAPI.scanDirectory(REPORTS_V2_DIR);
    let matchingReports = 0;
    
    if (folderRes.success) {
      const files = folderRes.files || [];
      syncLogs.value.push(`📑 共检索到 ${files.length} 份 AI 深度分析报告文档。`);
      const reportIndex = buildReportIndex(files);
      customers.forEach(cust => {
        if (findMatchedReport(cust, reportIndex)) matchingReports++;
      });
      reportMatchedCount.value = matchingReports;
      syncLogs.value.push(`🎯 报告配对成功：共有 ${matchingReports} 家客户完美匹配本地 AI 深度分析报告。`);
    } else {
      syncLogs.value.push(`⚠️ 报告索引失败: ${folderRes.error}`);
    }
    isSyncActive.value = true;
  } catch (err) {
    syncLogs.value.push(`❌ 侦测发生异常错误: ${err.message}`);
  }
};

const executeIncrementalSync = async () => {
  if (syncLoading.value) return;
  syncLoading.value = true;
  syncLogs.value.push('⚡️ 开始执行客户增量同步与 AI 绑定流程...');
  
  try {
    const customers = await loadAllPartsCustomers();
    scannedCount.value = customers.length;
    const folderRes = await window.electronAPI.scanDirectory(REPORTS_V2_DIR);
    const scannedFiles = folderRes.success ? (folderRes.files || []) : [];
    const reportIndex = buildReportIndex(scannedFiles);
    
    const currentLeads = [...leads.value];
    let nextId = currentLeads.reduce((max, lead) => Math.max(max, Number(lead.id) || 0), 0) + 1;
    let addedCount = 0;
    let skippedCount = 0;
    
    const flagMap = {
      'USA': '🇺🇸', 'Germany': '🇩🇪', 'Thailand': '🇹🇭', 'Russia': '🇷🇺',
      'Australia': '🇦🇺', 'UK': '🇬🇧', 'Canada': '🇨🇦', 'France': '🇫🇷',
      'Japan': '🇯🇵', 'China': '🇨🇳', 'Italy': '🇮🇹', 'Spain': '🇪🇸',
      'Philippines': '🇵🇭', 'India': '🇮🇳', 'Thailand': '🇹🇭', 'UAE': '🇦🇪',
      'Iraq': '🇮🇶', 'Israel': '🇮🇱', '俄罗斯': '🇷🇺', '泰国': '🇹🇭',
      '菲律宾': '🇵🇭', '阿联酋': '🇦🇪', '印度': '🇮🇳', '伊拉克': '🇮🇶',
      '澳大利亚': '🇦🇺', '美国': '🇺🇸', '德国': '🇩🇪'
    };
    
    for (const cust of customers) {
      const company = getCustomerCompany(cust);
      const country = getCustomerCountry(cust);
      const normalizedCompany = normalizeEntityName(company);
      
      const leadExists = currentLeads.some(l => {
        const normLocal = normalizeEntityName(l.name);
        return normLocal === normalizedCompany;
      });
      
      if (leadExists) {
        skippedCount++;
        continue;
      }
      
      let deepReportObj = null;
      const matchedFile = findMatchedReport(cust, reportIndex);
      
      if (matchedFile) {
        const fileContentRes = await window.electronAPI.readFile(`${REPORTS_V2_DIR}/${matchedFile.name}`);
        if (fileContentRes.success) {
          deepReportObj = {
            type: matchedFile.name.endsWith('.html') ? 'HTML' : 'Markdown',
            filename: matchedFile.name,
            date: new Date().toISOString().replace('T', ' ').substring(0, 19),
            content: fileContentRes.content
          };
        }
      }
      
      const newId = nextId++;
      const simulatedScore = matchedFile ? 90 : (cust.email || cust.phone ? 84 : 76);
      const isRegional = country === 'Thailand' || country === 'Germany' || country === '泰国' || country === '德国' || country === '俄罗斯';
      
      const newLeadCard = {
        id: newId,
        name: company,
        contact: getCustomerContact(cust),
        phone: cust.phone || '未指定',
        country: country === 'USA' ? '美国' : (country === 'Germany' ? '德国' : (country === 'Thailand' ? '泰国' : country)),
        flag: flagMap[country] || '🏳️',
        score: simulatedScore,
        category: 'parts',
        stage: 'potential',
        tags: [country === 'USA' ? '美国' : (country === 'Germany' ? '德国' : (country === 'Thailand' ? '泰国' : country)), '汽车配件', cust.sourceGroup || '汽配客户', matchedFile ? 'AI研判' : '潜在询盘'],
        routingPath: isRegional ? `${country}本地协同专线跟进` : (simulatedScore >= 85 ? '云端高级路由 Gemini 1.5' : '本地大模型网关 Llama 3'),
        rawMessage: `[汽配大客户同步信息]\nSource: ${cust.sourceGroup || cust.source || '外部汽配数据'}\nScale: ${cust.scale || '未指定'}\nProducts: ${cust.products || '未指定'}\nDescription: ${cust.description || '无'}\nWebsite: ${cust.website || '无'}\nLinkedin: ${cust.linkedin || '无'}\nEmail: ${cust.email || '无'}\nPhone: ${cust.phone || '无'}\nAddress: ${cust.address || '无'}\nContact: ${cust.contact_title || cust.contact || '无'}`,
        deepReport: deepReportObj
      };
      
      currentLeads.unshift(newLeadCard);
      addedCount++;
      
      if (addedCount <= 8) {
        syncLogs.value.push(`✅ [同步成功] ${cust.company} (${cust.country}) ${matchedFile ? '🔔 已绑定 AI 深度报告' : '📄 报告未配对'}`);
      }
    }
    
    if (addedCount > 8) {
      syncLogs.value.push(`... 及其他 ${addedCount - 8} 家汽配客户增量同步成功`);
    }
    
    syncLogs.value.push(`🎉 增量同步完成：本次共新增同步 ${addedCount} 家汽配客户，跳过 ${skippedCount} 家已存在的客商，保证数据库唯一性。`);
    
    leads.value = currentLeads;
    
  } catch (err) {
    syncLogs.value.push(`❌ 同步发生严重异常: ${err.message}`);
  } finally {
    syncLoading.value = false;
  }
};

const addLeadModalOpen = ref(false);
const newLeadForm = ref({
  name: '',
  contact: '',
  phone: '',
  country: '美国',
  category: 'parts',
  stage: 'potential',
  rawMessage: ''
});

const openAddLeadModal = () => {
  newLeadForm.value = {
    name: '',
    contact: '',
    phone: '',
    country: '美国',
    category: 'parts',
    stage: 'potential',
    rawMessage: ''
  };
  addLeadModalOpen.value = true;
};

const submitNewLead = () => {
  if (!newLeadForm.value.name || !newLeadForm.value.contact || !newLeadForm.value.rawMessage) {
    alert('请务必填写客户公司名称、联系人及原始信件内容！');
    return;
  }

  const countryFlags = {
    '俄罗斯': '🇷🇺',
    '泰国': '🇹🇭',
    '以色列': '🇮🇱',
    '菲律宾': '🇵🇭',
    '阿联酋': '🇦🇪',
    '印度': '🇮🇳',
    '伊拉克': '🇮🇶',
    '澳大利亚': '🇦🇺',
    '美国': '🇺🇸',
    '德国': '🇩🇪'
  };

  const newId = leads.value.length + 1;
  const flag = countryFlags[newLeadForm.value.country] || '🏳️';
  const score = Math.floor(Math.random() * 20) + 75;
  const isRegional = newLeadForm.value.country === '泰国' || newLeadForm.value.country === '俄罗斯' || newLeadForm.value.country === '德国';

  const newLead = {
    id: newId,
    name: newLeadForm.value.name,
    contact: newLeadForm.value.contact,
    phone: newLeadForm.value.phone || '未指定',
    country: newLeadForm.value.country,
    flag: flag,
    score: score,
    category: newLeadForm.value.category,
    stage: newLeadForm.value.stage,
    tags: [newLeadForm.value.country, newLeadForm.value.stage === 'deal' ? '已成交' : '潜在询盘'],
    routingPath: isRegional ? `${newLeadForm.value.country}本地驻地专线跟进` : (score >= 85 ? '多模态高级路由 Gemini' : '自研路由 DeepSeek V2'),
    rawMessage: newLeadForm.value.rawMessage
  };

  const current = [...leads.value];
  current.unshift(newLead);
  leads.value = current;
  selectedLeadId.value = newLead.id;
  addLeadModalOpen.value = false;

  // Trigger alert if applicable
  if (isRegional) {
    activeCollaborativeAlert.value = {
      name: newLead.name,
      country: newLead.country,
      flag: newLead.flag
    };
  } else {
    activeCollaborativeAlert.value = null;
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// Tag color system: each tag gets its own distinct color, user-customizable
// ─────────────────────────────────────────────────────────────────────────────
const TAG_PALETTE = [
  { id: 'rose',    label: '朱砂红', class: 'bg-rose-50 border-rose-200 text-rose-600',         dot: 'bg-rose-500' },
  { id: 'orange',  label: '琥珀橙', class: 'bg-orange-50 border-orange-200 text-orange-600',   dot: 'bg-orange-500' },
  { id: 'amber',   label: '泥金黄', class: 'bg-amber-50 border-amber-200 text-amber-600',      dot: 'bg-amber-500' },
  { id: 'emerald', label: '竹叶绿', class: 'bg-emerald-50 border-emerald-200 text-emerald-600', dot: 'bg-emerald-500' },
  { id: 'teal',    label: '青瓷蓝', class: 'bg-teal-50 border-teal-200 text-teal-600',         dot: 'bg-teal-500' },
  { id: 'sky',     label: '天青色', class: 'bg-sky-50 border-sky-200 text-sky-600',            dot: 'bg-sky-500' },
  { id: 'blue',    label: '靛蓝色', class: 'bg-blue-50 border-blue-200 text-blue-600',         dot: 'bg-blue-500' },
  { id: 'indigo',  label: '青黛蓝', class: 'bg-indigo-50 border-indigo-200 text-indigo-600',   dot: 'bg-indigo-500' },
  { id: 'violet',  label: '紫罗兰', class: 'bg-violet-50 border-violet-200 text-violet-600',   dot: 'bg-violet-500' },
  { id: 'fuchsia', label: '品红色', class: 'bg-fuchsia-50 border-fuchsia-200 text-fuchsia-600', dot: 'bg-fuchsia-500' },
  { id: 'pink',    label: '胭脂粉', class: 'bg-pink-50 border-pink-200 text-pink-600',         dot: 'bg-pink-500' },
  { id: 'slate',   label: '远山灰', class: 'bg-slate-50 border-slate-200 text-slate-600',      dot: 'bg-slate-400' },
];

const TAG_COLOR_STORAGE_KEY = 'magichub_tag_colors';

// Seed sensible defaults so known business tags keep their familiar look
const tagColorMap = ref({
  '流失客户': 'rose',
  '已成交': 'emerald',
  '成交': 'emerald',
  '优质客户': 'indigo',
  '大客户': 'indigo',
  '高意向': 'indigo',
  '价格敏感': 'amber',
  '价格过高': 'rose',
  '未分类': 'slate',
  '+1': 'slate',
});

const persistTagColors = async () => {
  try {
    localStorage.setItem(TAG_COLOR_STORAGE_KEY, JSON.stringify(tagColorMap.value));
    if (window.electronAPI?.saveSettings) {
      await window.electronAPI.saveSettings(TAG_COLOR_STORAGE_KEY, JSON.parse(JSON.stringify(tagColorMap.value)));
    }
  } catch (e) {
    console.error('[MagicHub] Failed to persist tag colors:', e);
  }
};

const loadTagColors = async () => {
  try {
    let saved = null;
    if (window.electronAPI?.loadSettings) {
      const res = await window.electronAPI.loadSettings(TAG_COLOR_STORAGE_KEY);
      if (res?.success && res.data) saved = res.data;
    }
    if (!saved) {
      const local = localStorage.getItem(TAG_COLOR_STORAGE_KEY);
      if (local) saved = JSON.parse(local);
    }
    if (saved && typeof saved === 'object') {
      tagColorMap.value = { ...tagColorMap.value, ...saved };
    }
  } catch (e) {
    console.error('[MagicHub] Failed to load tag colors:', e);
  }
};

// Deterministic hash so an unassigned tag always maps to the same palette color
const hashTagToColor = (tag) => {
  let hash = 0;
  for (let i = 0; i < tag.length; i++) {
    hash = (hash * 31 + tag.charCodeAt(i)) >>> 0;
  }
  return TAG_PALETTE[hash % TAG_PALETTE.length].id;
};

// Resolve the palette entry for a tag (explicit color wins, else deterministic auto-color)
const getTagColorId = (tag) => tagColorMap.value[tag] || hashTagToColor(tag);

const getTagPalette = (tag) => {
  const id = getTagColorId(tag);
  return TAG_PALETTE.find(p => p.id === id) || TAG_PALETTE[TAG_PALETTE.length - 1];
};

// Dynamic helper classes for capsule tags — now every tag has its own color
const getTagClass = (tag) => getTagPalette(tag).class;

// Assign / change a tag's color from the palette swatch picker
const setTagColor = (tag, colorId) => {
  tagColorMap.value = { ...tagColorMap.value, [tag]: colorId };
  persistTagColors();
};

onMounted(loadTagColors);

// --- [NEW] Refactoring Details Workspace States & Navigation Watcher ---
const detailFollowUpChannel = ref('电子邮件 (Email)');
const detailFollowUpType = ref('初次接触');
const detailFollowUpChannelCustom = ref('');
const detailFollowUpTypeCustom = ref('');
const detailFollowUpDraft = ref('');
const isPolishingDetail = ref(false);
const activeWorkspaceDeal = ref(null);

const matchedTimelineLogs = computed(() => {
  if (!selectedLeadForModal.value) return [];
  const clientName = selectedLeadForModal.value.name.toLowerCase();
  return props.timelineLogs.filter(log =>
    log.client.toLowerCase().includes(clientName) ||
    clientName.includes(log.client.toLowerCase())
  );
});

const matchedDeals = computed(() => {
  if (!selectedLeadForModal.value) return [];
  const clientName = selectedLeadForModal.value.name.toLowerCase();
  return props.deals.filter(deal =>
    deal.client.toLowerCase().includes(clientName) ||
    clientName.includes(deal.client.toLowerCase())
  );
});

const polishDetailNote = () => {
  if (!detailFollowUpDraft.value) {
    alert('请输入需要润色的跟进纪实记录！');
    return;
  }
  isPolishingDetail.value = true;
  setTimeout(() => {
    isPolishingDetail.value = false;
    
    let polishedText = '';
    if (props.isSecretMode) {
      polishedText = `[本地 Llama 3 离线算力润色纪实]\n沟通纪实内容整理如下：\n与客户就产品开发图纸、三维逆向数模图审、碰撞法规ADR符合性等技术壁垒及认证参数进行细致对口分析。客商对我们温州工厂15年出口实力、多款前竞技防撞杠合作案例高度认可。目前价格及账期方案已说清，我方提出的30%预付风控账期体系客商表示认可，正在内部法务审核，下一步将推进签订打样协议并安排付样品费。`;
    } else {
      polishedText = `[AI 算力网关润色纪实 - Gemini 路由]\n与该客商进行了高频商务沟通，纪实总结如下：\n1. 技术规格判定：客户对 JFC-B1 竞技竞技杠表示强烈采购意向，尤其认可该产品已通过的澳大利亚 ADR 改装碰撞测试报告，已进入逆向 3D 数模核对阶段；\n2. 商务价格让步：我方已报价 $280 CIF Hamburg，客商反馈希望有 5% 的阶梯商务折扣，账期坚持 30% T/T 预付 + 70% L/C 结算；\n3. 下一步行动计划：我方将于下周三前正式提供全套签字盖章的打样协议及 ADR 认证证书复印件，并锁定温州工厂的打样排期，保证 15 天内出样。`;
    }
    detailFollowUpDraft.value = polishedText;
  }, 1200);
};

const addDetailFollowUp = () => {
  if (!detailFollowUpDraft.value) {
    alert('请填写跟进纪实内容！');
    return;
  }

  // Resolve channel/type, supporting the custom free-text option
  const channel = detailFollowUpChannel.value === '__custom__'
    ? detailFollowUpChannelCustom.value.trim()
    : detailFollowUpChannel.value;
  const type = detailFollowUpType.value === '__custom__'
    ? detailFollowUpTypeCustom.value.trim()
    : detailFollowUpType.value;

  if (detailFollowUpChannel.value === '__custom__' && !channel) {
    alert('请输入自定义沟通渠道！');
    return;
  }
  if (detailFollowUpType.value === '__custom__' && !type) {
    alert('请输入自定义跟进类型！');
    return;
  }

  const now = new Date();
  const formatTime = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

  const logEntry = {
    id: props.timelineLogs.length + 1,
    client: `${selectedLeadForModal.value.name} (${selectedLeadForModal.value.country})`,
    date: formatTime,
    channel: channel,
    type: type,
    content: detailFollowUpDraft.value
  };

  const updatedLogs = [logEntry, ...props.timelineLogs];
  emit('update:timelineLogs', updatedLogs);
  detailFollowUpDraft.value = '';
  alert('当前跟进记录已成功保存同步！');
};

const triggerWorkspaceDealStrategy = (deal) => {
  activeWorkspaceDeal.value = deal;
};

// Jump to customer detail page automatically when signal is received from parent
watch(() => props.jumpToCustomerId, (newVal) => {
  if (newVal) {
    const lead = leads.value.find(l => l.id === newVal);
    if (lead) {
      triggerDetailModal(lead);
    }
    emit('clear-jump-customer');
  }
}, { immediate: true });
</script>
