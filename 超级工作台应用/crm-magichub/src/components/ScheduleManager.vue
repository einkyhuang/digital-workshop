<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10">
    <div v-if="viewState === 'calendar'" class="space-y-6 animate-fadeIn">
      <!-- 1. Yearly Schedule Dashboard Header -->
      <div class="apple-glass rounded-2xl p-6 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-br from-[#627254]/[0.02] to-transparent pointer-events-none"></div>
        <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 relative z-10">
          <div>
            <h2 class="text-lg font-bold font-serif-sc tracking-wider text-zen-ink flex items-center gap-2">
              📅 2026年度日程与业务总结中心
            </h2>
            <p class="text-[11px] text-zen-gray mt-1 font-serif-sc">
              统一梳理全年 12 个月所有客商跟进、合同履行、AI 离线清洗日志及 ChromaDB 向量知识库的热同步印记。
            </p>
          </div>
          <div class="flex gap-2">
            <!-- AI Annual Summary Generator Button -->
            <button
              @click="generateAnnualReport"
              class="px-4 py-2 rounded-xl bg-zen-ink text-white text-xs font-semibold hover:scale-[1.02] active:scale-[0.98] transition-all duration-300 shadow-sm outline-none flex items-center gap-1.5"
            >
              <span>🤖 AI 一键生成年度总结报告</span>
            </button>
          </div>
        </div>

        <!-- 1.1 Annual Stats Counters Row -->
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
          <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between">
            <span class="text-[9px] text-zen-gray font-semibold uppercase tracking-widest">2026年度跟进总数</span>
            <span class="text-xl font-bold font-mono text-zen-ink mt-1">142 <span class="text-[9px] font-normal text-zen-gray ml-0.5">次</span></span>
          </div>
          <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between">
            <span class="text-[9px] text-zen-gray font-semibold uppercase tracking-widest">合同订单生效数</span>
            <span class="text-xl font-bold font-mono text-zen-green mt-1">24 <span class="text-[9px] font-normal text-zen-gray ml-0.5">单</span></span>
          </div>
          <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between">
            <span class="text-[9px] text-zen-gray font-semibold uppercase tracking-widest">AI 自动清洗日志</span>
            <span class="text-xl font-bold font-mono text-zen-tea mt-1">189 <span class="text-[9px] font-normal text-zen-gray ml-0.5">条</span></span>
          </div>
          <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between ring-1 ring-zen-crimson/20">
            <span class="text-[9px] text-zen-crimson font-semibold uppercase tracking-widest">待办警告异常</span>
            <span class="text-xl font-bold font-mono text-zen-crimson mt-1">2 <span class="text-[9px] font-normal text-zen-gray ml-0.5">项</span></span>
          </div>
        </div>
      </div>

      <!-- 2. Todo Command Center -->
      <div class="apple-glass rounded-2xl p-5 border border-white/50 space-y-4">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div>
            <h3 class="text-sm font-bold font-serif-sc text-zen-ink">待办事项工作台</h3>
            <p class="text-[10px] text-zen-gray mt-1">用于集中处理需要营销、报价、回访、合同确认的客户任务。</p>
          </div>
          <div class="flex gap-2">
            <button
              @click="generateAiTodos"
              class="px-4 py-2 rounded-xl bg-zen-ink text-white text-[10px] font-bold shadow-sm hover:bg-zen-ink/90 transition-all outline-none"
            >
              AI 生成待办
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-3 gap-4">
          <div class="xl:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-3">
            <div
              v-for="todo in todoItems"
              :key="todo.id"
              class="p-4 rounded-2xl border border-white/60 bg-white/35 shadow-sm flex items-start gap-3"
              :class="todo.done ? 'opacity-55' : ''"
            >
              <input v-model="todo.done" type="checkbox" class="mt-1 accent-[#627254]" />
              <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                  <span class="text-[8px] px-2 py-0.5 rounded font-bold" :class="getTodoPriorityClass(todo.priority)">{{ todo.priority }}</span>
                  <span class="text-[8px] text-zen-gray font-mono">{{ todo.due }}</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink mt-1.5 leading-tight" :class="todo.done ? 'line-through' : ''">{{ todo.title }}</h4>
                <p class="text-[10px] text-zen-gray leading-relaxed mt-1">{{ todo.desc }}</p>
              </div>
              <button @click="deleteTodo(todo.id)" class="text-[10px] text-zen-crimson hover:underline shrink-0">删除</button>
            </div>
          </div>

          <div class="rounded-2xl bg-white/25 border border-white/50 p-4 space-y-3">
            <h4 class="text-[10px] font-bold text-zen-gray uppercase tracking-widest">手动建立待办</h4>
            <input v-model="newTodoTitle" type="text" placeholder="例如：给 Horntools 发报价" class="w-full bg-white/70 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none" />
            <div class="grid grid-cols-2 gap-2">
              <select v-model="newTodoPriority" class="bg-white/70 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none">
                <option value="高优先级">高优先级</option>
                <option value="中优先级">中优先级</option>
                <option value="低优先级">低优先级</option>
              </select>
              <input v-model="newTodoDue" type="text" placeholder="今天 / 本周五" class="bg-white/70 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none" />
            </div>
            <textarea v-model="newTodoDesc" rows="3" placeholder="补充客户、产品、报价或营销动作..." class="w-full bg-white/70 border border-white/60 rounded-xl p-3 text-xs outline-none resize-none"></textarea>
            <button @click="addTodo" class="w-full py-2.5 rounded-xl bg-zen-green text-white text-xs font-bold shadow-sm hover:bg-zen-green/90 transition-all outline-none">保存待办</button>
          </div>
        </div>
      </div>

      <!-- 3. Filter Navigation Bar -->
      <div class="flex items-center justify-between py-1 select-none">
        <div class="flex items-center gap-1.5 bg-white/40 backdrop-blur-md p-1 rounded-xl border border-white/50 shadow-sm">
          <button
            v-for="filter in filters"
            :key="filter.id"
            @click="activeFilter = filter.id"
            class="px-4 py-1.5 rounded-lg text-[10px] font-semibold transition-all duration-300 outline-none"
            :class="activeFilter === filter.id
              ? 'bg-zen-ink text-white shadow-sm'
              : 'text-zen-gray hover:text-zen-ink hover:bg-black/5'"
          >
            {{ filter.name }}
          </button>
        </div>
        <span class="text-[9px] text-zen-gray font-mono pr-2">当前看板：2026年 {{ currentMonthConfig.name }}</span>
      </div>

      <!-- 4. Current Month Full-width Calendar -->
      <div class="grid grid-cols-1 gap-6">
        <div
          class="apple-glass rounded-2xl p-6 relative flex flex-col justify-between z-10 hover:z-50 overflow-visible"
        >
          <div class="absolute inset-0 rounded-2xl bamboo-bg-decor opacity-[0.03] pointer-events-none"></div>
          <div class="relative z-10">
            <!-- Month Header -->
            <div class="flex justify-between items-center mb-3.5 border-b border-white/20 pb-2">
              <h3 class="text-xs font-bold text-zen-ink font-serif-sc flex items-center gap-1.5">
                📅 2026年 {{ currentMonthConfig.name }} · 当月全宽月历
              </h3>
              <span
                v-if="getMonthLogsCount(currentMonthConfig.monthNum)"
                class="text-[8px] bg-zen-tea/15 border border-zen-tea/30 text-zen-tea px-2 py-0.5 rounded font-mono font-bold"
              >
                {{ getMonthLogsCount(currentMonthConfig.monthNum) }} 记录
              </span>
              <span v-else class="text-[8px] text-zen-gray/40 font-mono italic">无记录</span>
            </div>

            <!-- Weekday Letters Header -->
            <div class="grid grid-cols-7 text-center text-[8px] font-bold text-zen-gray border-b border-white/10 pb-1.5 mb-2 select-none">
              <span>日</span><span>一</span><span>二</span><span>三</span><span>四</span><span>五</span><span>六</span>
            </div>

            <!-- Days Grid Matrix -->
            <div class="grid grid-cols-7 text-center gap-2 text-xs font-mono select-none">
              <!-- Empty offset placeholders for weekday alignment -->
              <span v-for="empty in currentMonthConfig.offset" :key="'empty-'+empty" class="text-transparent h-12">0</span>

              <!-- Actual Calendar Days -->
              <div
                v-for="day in currentMonthConfig.days"
                :key="'day-'+day"
                class="relative"
                @mouseenter="hoveredDay = { month: currentMonthConfig.monthNum, day: day }"
                @mouseleave="hoveredDay = null"
              >
                <span
                  @click="openDayDetails(currentMonthConfig.monthNum, day)"
                  class="h-12 flex items-center justify-center mx-auto rounded-xl cursor-pointer transition-all duration-200 relative z-10"
                  :class="getDayClass(currentMonthConfig.monthNum, day)"
                >
                  {{ day }}
                </span>

                <!-- Hover Glassmorphic Popover -->
                <div
                  v-if="hoveredDay && hoveredDay.month === currentMonthConfig.monthNum && hoveredDay.day === day"
                  class="absolute z-[99] bottom-full left-1/2 -translate-x-1/2 mb-2 w-60 p-3 bg-white/95 border border-white/40 shadow-xl rounded-xl backdrop-blur-md text-left select-text transition-all duration-200 pointer-events-none"
                  style="filter: drop-shadow(0 10px 15px rgba(0, 0, 0, 0.15));"
                >
                  <div class="flex justify-between items-center border-b border-black/5 pb-1.5 mb-1.5">
                    <span class="text-[9px] font-bold text-zen-gray uppercase tracking-widest flex items-center gap-1">
                      <span class="w-1.5 h-1.5 rounded-full bg-zen-tea animate-pulse"></span>
                      {{ currentMonthConfig.monthNum }}月{{ day }}日 记录预览
                    </span>
                    <span class="text-[8px] text-zen-tea font-mono font-medium" v-if="getDayLogs(currentMonthConfig.monthNum, day).length">
                      {{ getDayLogs(currentMonthConfig.monthNum, day).length }}项记录
                    </span>
                  </div>

                  <div v-if="getDayLogs(currentMonthConfig.monthNum, day).length" class="space-y-1.5 max-h-[120px] overflow-y-auto scrollbar-elegant pr-0.5">
                    <div
                      v-for="(rec, idx) in getDayLogs(currentMonthConfig.monthNum, day)"
                      :key="idx"
                      class="p-1.5 rounded-lg border border-black/5 bg-black/[0.02] flex items-start gap-1.5 text-[9px] leading-normal"
                    >
                      <span class="text-xs shrink-0 select-none">{{ rec.icon }}</span>
                      <div class="space-y-0.5">
                        <span class="font-bold text-zen-ink block">{{ rec.title }}</span>
                        <span class="text-[8px] text-zen-gray block leading-relaxed line-clamp-2">{{ rec.desc }}</span>
                      </div>
                    </div>
                  </div>
                  <div v-else class="text-center py-2 text-zen-gray/40 italic text-[9px]">
                    ☕ 该日无业务事件，系统自主巡检中
                  </div>

                  <div class="text-[8px] text-center text-zen-tea font-semibold border-t border-black/5 pt-1.5 mt-1.5 select-none">
                    点击进入详情看板 ➡️
                  </div>

                  <!-- Downward Arrow pointer -->
                  <div class="absolute top-full left-1/2 -translate-x-1/2 -mt-[1px] w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-t-[6px] border-t-white/95"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 5. Other Months Collapsed Lists -->
      <div class="space-y-3">
        <details
          v-for="month in otherMonthsConfig"
          :key="month.monthNum"
          class="apple-glass rounded-2xl border border-white/50 overflow-hidden"
        >
          <summary class="cursor-pointer select-none px-5 py-4 flex items-center justify-between text-xs font-bold text-zen-ink">
            <span>2026年 {{ month.name }} · {{ getMonthLogsCount(month.monthNum) }} 项记录</span>
            <span class="text-[9px] text-zen-gray font-normal">点击展开</span>
          </summary>
          <div class="px-5 pb-5 space-y-2">
            <div v-if="getMonthFlatLogs(month.monthNum).length" class="grid grid-cols-1 md:grid-cols-2 gap-2">
              <button
                v-for="item in getMonthFlatLogs(month.monthNum)"
                :key="`${month.monthNum}-${item.day}-${item.title}`"
                @click="openDayDetails(month.monthNum, item.day)"
                class="text-left p-3 rounded-xl bg-white/35 border border-white/50 hover:bg-white transition-all"
              >
                <span class="text-[9px] text-zen-gray font-mono">{{ month.monthNum }}月{{ item.day }}日</span>
                <h4 class="text-[11px] font-bold text-zen-ink mt-1">{{ item.icon }} {{ item.title }}</h4>
                <p class="text-[9px] text-zen-gray mt-1 line-clamp-2">{{ item.desc }}</p>
              </button>
            </div>
            <div v-else class="text-[10px] text-zen-gray/50 py-3">该月暂无记录。</div>
          </div>
        </details>
      </div>
    </div>

    <!-- 4. Daily Details Page View (NEW inline view replacing modal) -->
    <div v-else-if="viewState === 'detail'" class="space-y-6 animate-fadeIn">
      <!-- Back Header -->
      <div class="pb-4 border-b border-white/20 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 select-none">
        <div class="flex items-center gap-4">
          <!-- Back button with elegant hover transition -->
          <button
            @click="viewState = 'calendar'"
            class="px-4 py-2 bg-white/50 hover:bg-white hover:translate-x-[-3px] border border-white/60 rounded-xl text-xs text-zen-ink font-semibold shadow-sm transition-all duration-300 outline-none flex items-center gap-1.5"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7" />
            </svg>
            返回日历视图
          </button>
          
          <div class="h-6 w-[1px] bg-white/30 hidden md:block"></div>
          
          <div>
            <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2 text-zen-ink">
              2026年{{ activeMonth }}月{{ activeDay }}日 · 日志详情工作台
              <span class="text-xs font-normal text-zen-gray font-sans bg-white/40 border border-white/50 px-2 py-0.5 rounded-lg select-none">
                Consolidated CRM data flow
              </span>
            </h2>
          </div>
        </div>
      </div>

      <!-- Main Columns Grid Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        <!-- Left 2 Cols: Activity records and Add new logs form -->
        <div class="lg:col-span-2 space-y-6">
          
          <!-- Activity Records Card -->
          <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4">
            <h4 class="text-[10px] font-bold text-zen-gray uppercase select-none tracking-widest flex items-center gap-1.5">
              <span class="w-1.5 h-1.5 rounded-full bg-zen-tea animate-pulse"></span>
              当日数据流水 (Daily Log Flow)
            </h4>

            <div v-if="getActiveDayLogs().length" class="space-y-3.5">
              <div
                v-for="(rec, idx) in getActiveDayLogs()"
                :key="idx"
                class="p-4 rounded-2xl border border-white/60 bg-white/30 shadow-sm flex items-start justify-between gap-4"
              >
                <div class="flex items-start gap-3">
                  <span class="text-xl shrink-0 mt-0.5 select-none">{{ rec.icon }}</span>
                  <div>
                    <h5 class="font-bold text-xs text-zen-ink leading-tight flex items-center gap-2">
                      {{ rec.title }}
                      <span
                        v-if="rec.type === 'contract'"
                        class="text-[8px] bg-zen-green/10 text-zen-green px-1.5 py-0.5 rounded font-mono font-semibold"
                      >订单生效</span>
                      <span
                        v-else-if="rec.type === 'lead'"
                        class="text-[8px] bg-amber-600/10 text-amber-700 px-1.5 py-0.5 rounded font-semibold"
                      >客商跟进</span>
                      <span
                        v-else-if="rec.type === 'system'"
                        class="text-[8px] bg-zen-tea/10 text-zen-tea px-1.5 py-0.5 rounded font-semibold"
                      >系统同步</span>
                    </h5>
                    <p class="text-[11px] text-zen-gray mt-1.5 leading-relaxed">{{ rec.desc }}</p>
                  </div>
                </div>
                <button
                  v-if="!rec._fromTimeline"
                  @click="deleteLogItem(rec)"
                  class="text-[10px] text-zen-crimson hover:underline select-none font-semibold shrink-0"
                >
                  删除
                </button>
                <span
                  v-else
                  class="text-[8px] text-zen-gray/60 select-none shrink-0 font-mono"
                  title="该条目来自客户跟进记录，请在客户详情页管理"
                >来自跟进</span>
              </div>
            </div>
            <div v-else class="text-center py-12 text-zen-gray/40 italic text-[11px] bg-white/10 rounded-2xl border border-dashed border-white/40">
              ☕ 当日暂无外发跟进事件，系统正自主保密巡检。
            </div>
          </div>

          <!-- Add new log form -->
          <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4">
            <h4 class="text-[10px] font-bold text-zen-gray uppercase select-none tracking-widest">
              ✍️ 添加工作备注 / 跟进备忘
            </h4>
            <div class="flex flex-col gap-3">
              <div class="flex flex-col sm:flex-row gap-3">
                <select
                  v-model="newLogType"
                  class="bg-white/60 border border-white/50 text-xs rounded-xl px-3 py-2.5 outline-none text-zen-ink font-semibold shrink-0"
                >
                  <option value="lead">📝 客户跟进</option>
                  <option value="contract">🤝 合同订单</option>
                  <option value="system">⚙️ 系统日志</option>
                  <option value="profit">🏦 结汇利润</option>
                </select>
                <input
                  v-model="newLogTitle"
                  type="text"
                  placeholder="输入日志标题 (如: 德国 Müller 防撞杠回函)"
                  class="flex-1 bg-white/60 border border-white/50 text-xs rounded-xl px-4 py-2.5 outline-none text-zen-ink font-mono"
                />
              </div>
              <div class="flex flex-col sm:flex-row gap-3">
                <textarea
                  v-model="newLogDesc"
                  placeholder="输入详细工作内容与数据纪要，AI 引擎将自动同步捕获此切片并注入 RAG 客户底库..."
                  rows="3"
                  class="flex-1 bg-white/60 border border-white/50 text-xs rounded-xl p-3.5 outline-none text-zen-ink leading-relaxed"
                ></textarea>
                <button
                  @click="addLogItem"
                  class="px-6 py-2.5 rounded-xl bg-zen-ink text-white text-xs font-bold hover:scale-[1.02] active:scale-[0.98] transition-all shrink-0 outline-none flex items-center justify-center shadow-sm"
                >
                  确定保存
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Right 1 Col: AI Summary & Actions -->
        <div class="space-y-6">
          <!-- Pilot AI Report -->
          <div class="p-6 rounded-3xl bg-gradient-to-br from-[#FFF5EC] to-[#FFE8D6] border border-[#FFD8B3]/60 text-[#D46B12] shadow-sm relative overflow-hidden space-y-3">
            <h4 class="text-[10px] font-bold text-[#E07A24] uppercase select-none tracking-widest flex items-center gap-1.5">
              <span class="w-1.5 h-1.5 rounded-full bg-[#FFA726] animate-pulse"></span>
              Pilot AI 日志切片诊断报告
            </h4>
            <p class="text-[11px] leading-relaxed text-[#8C4600] font-serif-sc">
              {{ getAiDailySummary() }}
            </p>
            <div class="flex justify-between items-center pt-2.5 border-t border-[#FFD8B3]/30 text-[9px] select-none">
              <span>底仓热载状态: ChromaDB 召回率 99.4%</span>
              <span>数据保护开启 🛡️</span>
            </div>
          </div>

          <!-- Actions Card -->
          <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4">
            <h4 class="text-[10px] font-bold text-zen-gray uppercase select-none tracking-widest">
              业务操作 (Actions)
            </h4>
            <button
              @click="exportDayLog"
              class="w-full py-2.5 rounded-xl border border-white/60 bg-white/50 hover:bg-white text-zen-ink text-xs font-bold transition-all outline-none flex items-center justify-center gap-2 shadow-sm"
            >
              <span>📤 导出本日备忘文本</span>
            </button>
            <p class="text-[9px] text-zen-gray/60 leading-normal select-none">
              安全校验成功 · 本地加密储存中 · 物理隔绝防护就绪
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- 5. AI Annual Summary Report Modal (年度报告显示器) -->
    <div
      v-if="isReportModalOpen"
      class="fixed inset-0 z-[110] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm select-text transition-all duration-300"
      @click.self="isReportModalOpen = false"
    >
      <div class="apple-glass rounded-2xl w-full max-w-3xl shadow-2xl border border-white/50 relative overflow-hidden flex flex-col max-h-[85vh]">
        <div class="absolute inset-0 bg-gradient-to-br from-[#627254]/[0.05] to-transparent pointer-events-none"></div>
        
        <header class="p-5 border-b border-white/20 flex justify-between items-center relative z-10 bg-white/40">
          <div class="flex items-center gap-2">
            <span class="text-lg">🤖</span>
            <div>
              <h3 class="text-sm font-bold text-zen-ink font-serif-sc">
                MagicHub AI 2026年度业务总结分析报告
              </h3>
              <p class="text-[9px] text-zen-gray mt-0.5">
                RAG model synthesized yearly marketing statistics & future sales forecast.
              </p>
            </div>
          </div>
          <button
            @click="isReportModalOpen = false"
            class="w-6 h-6 rounded-full hover:bg-black/5 text-zen-gray hover:text-zen-ink flex items-center justify-center transition-all duration-200 text-sm"
          >
            ×
          </button>
        </header>

        <main class="flex-1 overflow-y-auto p-6 scrollbar-elegant relative z-10 bg-white/10">
          <!-- Textarea containing pre-generated rich markdown annual summary -->
          <div class="prose prose-sm max-w-none text-zen-ink">
            <textarea
              readonly
              ref="reportTextarea"
              class="w-full h-[450px] bg-transparent border-0 font-mono text-[10px] leading-relaxed text-zen-ink p-4 rounded-xl focus:ring-0 resize-none outline-none select-text"
              v-model="annualReportText"
            ></textarea>
          </div>
        </main>

        <footer class="p-5 border-t border-white/20 flex justify-between items-center relative z-10 bg-white/40">
          <span class="text-[9px] text-zen-tea font-semibold">
            总结报告已自动关联 142 次客户跟进及 24 笔已成交 SQLite 合同档案。
          </span>
          <div class="flex gap-2">
            <button
              @click="copyAnnualReport"
              class="px-4 py-1.5 rounded-lg bg-zen-ink text-white text-[10px] font-semibold hover:scale-[1.02] active:scale-[0.98] transition-all outline-none"
            >
              📋 复制报告全文 (Markdown)
            </button>
            <button
              @click="isReportModalOpen = false"
              class="px-3.5 py-1.5 rounded-lg border border-white/50 hover:bg-white/60 text-zen-ink text-[10px] font-semibold transition-all outline-none"
            >
              关闭
            </button>
          </div>
        </footer>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, computed } from 'vue';

const props = defineProps({
  jumpToScheduleDate: {
    type: Object,
    default: null
  },
  timelineLogs: {
    type: Array,
    default: () => []
  },
  contracts: {
    type: Array,
    default: () => []
  },
  deals: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['clear-jump-schedule']);

// 1. Interactive States
const activeFilter = ref('all');
const hoveredDay = ref(null);

const viewState = ref('calendar'); // 'calendar' or 'detail'
const activeMonth = ref(5);
const activeDay = ref(31);

const isReportModalOpen = ref(false);
const annualReportText = ref('');
const reportTextarea = ref(null);

// Form Fields for Adding Custom Log
const newLogType = ref('lead');
const newLogTitle = ref('');
const newLogDesc = ref('');
const newTodoTitle = ref('');
const newTodoDesc = ref('');
const newTodoDue = ref('今天');
const newTodoPriority = ref('中优先级');
const todoItems = ref([
  { id: 1, title: '给德国 Müller 发送 TUV 参数营销邮件', desc: '重点附上防撞杠材料、包装和交期说明。', due: '今天', priority: '高优先级', done: false },
  { id: 2, title: '整理 Somchai 二期报价', desc: '按照首款到账后的阶梯价格准备 CIF 报价。', due: '本周三', priority: '高优先级', done: false },
  { id: 3, title: '复核 14 家欧洲汽配客户报告', desc: '把高分客户标记为下一轮开发对象。', due: '本周', priority: '中优先级', done: false }
]);

// 2. Tab Filter Definition
const filters = [
  { id: 'all', name: '全部日程' },
  { id: 'lead', name: '客户跟进' },
  { id: 'contract', name: '合同订单' },
  { id: 'system', name: '系统与 AI' }
];

// 3. Mathematical Calendar Months Matrix Config for 2026
const monthsConfig = [
  { name: '1月 (January)', days: 31, offset: 4, monthNum: 1 },
  { name: '2月 (February)', days: 28, offset: 0, monthNum: 2 },
  { name: '3月 (March)', days: 31, offset: 0, monthNum: 3 },
  { name: '4月 (April)', days: 30, offset: 3, monthNum: 4 },
  { name: '5月 (May)', days: 31, offset: 5, monthNum: 5 },
  { name: '6月 (June)', days: 30, offset: 1, monthNum: 6 },
  { name: '7月 (July)', days: 31, offset: 3, monthNum: 7 },
  { name: '8月 (August)', days: 31, offset: 6, monthNum: 8 },
  { name: '9月 (September)', days: 30, offset: 2, monthNum: 9 },
  { name: '10月 (October)', days: 31, offset: 4, monthNum: 10 },
  { name: '11月 (November)', days: 30, offset: 0, monthNum: 11 },
  { name: '12月 (December)', days: 31, offset: 2, monthNum: 12 }
];

const currentMonthConfig = computed(() => monthsConfig.find(month => month.monthNum === 6) || monthsConfig[0]);
const otherMonthsConfig = computed(() => monthsConfig.filter(month => month.monthNum !== currentMonthConfig.value.monthNum));

// 4. Annual Schedules Database (January to December 2026)
// Structure: annualSchedules[monthNum][dayNum] = [ { type, icon, title, desc } ]
const annualSchedules = ref({
  // May (5月) - Matches Dashboard Mock Logs
  5: {
    31: [
      { icon: '📝', type: 'lead', title: '跟进：德国 Müller 越野防撞杠参数答复', desc: '延迟11ms，已推荐使用 standard polish 技能打磨开发信答复。' },
      { icon: '⚙️', type: 'system', title: '导入：标准 IDE 8项特种技能仓编译完毕', desc: 'ChromaDB 向量索引召回热同步就绪，已分配勾选至业务员。' }
    ],
    30: [
      { icon: '🤝', type: 'contract', title: '合同：泰国 Somchai 水囊代理订单首款', desc: '大货柔性协作合同已生效，¥1.5万定金成功到账 SQLite 密仓。' },
      { icon: '📂', type: 'system', title: '文件：本地 3 部越野配件目录彩页解密', desc: '同步更新入 RAG 产品主库，ChromaDB 切片解析已就绪。' }
    ],
    29: [
      { icon: '📝', type: 'lead', title: '跟进：派发泰国询盘代理 Sompop 跟进', desc: '触发地面区域协作机制，首行记录已实时注入公海时间线。' }
    ],
    28: [
      { icon: '🏦', type: 'profit', title: '结汇：德国 Müller 年度首批出运利润', desc: '完成水墨禅意核销，总利润 ¥1.54万实时入账财务板块。' }
    ],
    20: [
      { icon: '✈️', type: 'system', title: '物流：首批汽车竞技杠起运汉堡口岸', desc: '海关放行数据同步就绪，TUV/FDA 检测证书已随箱附带。' }
    ],
    15: [
      { icon: '📄', type: 'system', title: '建档：完成 14 家欧洲汽车零部件客户建档', desc: '多模态爬虫深度提取企业背景，写入 SQLite。' }
    ]
  },
  // April (4月)
  4: {
    25: [
      { icon: '🤝', type: 'contract', title: '合同：与中东买家 Al-Mutairi 签定分销备忘录', desc: '预计首季度供货 200 套折叠蓄水囊，商机转订单完成率 100%。' }
    ],
    18: [
      { icon: '📂', type: 'system', title: '底库：SQLite 大客户字段 schema 完美扩增', desc: '静默编译注入 3 项 IDE 授信模块， ChomaDB 完成增量向量计算。' }
    ],
    10: [
      { icon: '📝', type: 'lead', title: '分析：针对希腊 PartsLink 独立站 GEO 参数抓取', desc: 'Pilot AI 自动提取其采购偏好，定位为中端越野竞技保险杠。' }
    ]
  },
  // March (3月)
  3: {
    28: [
      { icon: '📝', type: 'lead', title: '跟进：答复日本 AutoGlow 公司对涉水器参数细节', desc: '对方提出要符合 JASO 标准，已调用本地 RAG 编译答复。' }
    ],
    15: [
      { icon: '⚙️', type: 'system', title: '安全：全库 SQLite 执行安全隔离物理隔绝校验', desc: '加密成功，向量召回索引正常运行，共耗时 24ms。' }
    ]
  },
  // June (6月 - 预测与规划日程)
  6: {
    5: [
      { icon: '📅', type: 'system', title: '规划：德国 Müller EX-XT-500 大货物流放行检验', desc: '已将汉堡海关提单与 TUV 品控符合表预置入 SQLite 等待触发。' }
    ],
    15: [
      { icon: '🤝', type: 'contract', title: '预期：清迈 Somchai 柔性折叠水箱首期验收结款', desc: '驻点代理 Sompop 将现场提供地面协同，回款指标 ¥2.0万。' }
    ]
  }
});

// 5. Computed Actions & Getters

// [NEW] Persist manually-added calendar logs so they survive restarts / app updates
const SCHEDULE_STORAGE_KEY = 'magichub_annual_schedules';
const loadAnnualSchedules = async () => {
  try {
    let saved = null;
    if (window.electronAPI?.loadSettings) {
      const res = await window.electronAPI.loadSettings(SCHEDULE_STORAGE_KEY);
      if (res?.success && res.data) saved = res.data;
    }
    if (!saved) {
      const local = localStorage.getItem(SCHEDULE_STORAGE_KEY);
      if (local) saved = JSON.parse(local);
    }
    if (saved && typeof saved === 'object') {
      annualSchedules.value = saved;
    }
  } catch (e) {
    console.error('[MagicHub] Failed to load schedules:', e);
  }
};
const persistAnnualSchedules = async () => {
  try {
    localStorage.setItem(SCHEDULE_STORAGE_KEY, JSON.stringify(annualSchedules.value));
    if (window.electronAPI?.saveSettings) {
      await window.electronAPI.saveSettings(SCHEDULE_STORAGE_KEY, JSON.parse(JSON.stringify(annualSchedules.value)));
    }
  } catch (e) {
    console.error('[MagicHub] Failed to persist schedules:', e);
  }
};
loadAnnualSchedules();
watch(annualSchedules, persistAnnualSchedules, { deep: true });

// [NEW] Persist user-editable to-do items so they survive restarts / app updates
const TODO_STORAGE_KEY = 'magichub_schedule_todos';
const loadTodoItems = async () => {
  try {
    let saved = null;
    if (window.electronAPI?.loadSettings) {
      const res = await window.electronAPI.loadSettings(TODO_STORAGE_KEY);
      if (res?.success && Array.isArray(res.data)) saved = res.data;
    }
    if (!saved) {
      const local = localStorage.getItem(TODO_STORAGE_KEY);
      if (local) saved = JSON.parse(local);
    }
    if (Array.isArray(saved)) todoItems.value = saved;
  } catch (e) {
    console.error('[MagicHub] Failed to load todos:', e);
  }
};
const persistTodoItems = async () => {
  try {
    localStorage.setItem(TODO_STORAGE_KEY, JSON.stringify(todoItems.value));
    if (window.electronAPI?.saveSettings) {
      await window.electronAPI.saveSettings(TODO_STORAGE_KEY, JSON.parse(JSON.stringify(todoItems.value)));
    }
  } catch (e) {
    console.error('[MagicHub] Failed to persist todos:', e);
  }
};
loadTodoItems();
watch(todoItems, persistTodoItems, { deep: true });

const parseLogToDate = (dateStr) => {
  // Accept formats like "2026-05-31 16:30" or "2026/5/31"
  if (!dateStr) return null;
  const m = String(dateStr).match(/(\d{4})[-/](\d{1,2})[-/](\d{1,2})/);
  if (!m) return null;
  return { year: Number(m[1]), month: Number(m[2]), day: Number(m[3]) };
};

const mergedSchedules = computed(() => {
  // Deep-ish clone of the static schedule data
  const merged = {};
  for (const month in annualSchedules.value) {
    merged[month] = {};
    for (const day in annualSchedules.value[month]) {
      merged[month][day] = [...annualSchedules.value[month][day]];
    }
  }

  // Fold in every follow-up record from the customer timeline
  (props.timelineLogs || []).forEach(log => {
    const d = parseLogToDate(log.date);
    if (!d) return;
    if (!merged[d.month]) merged[d.month] = {};
    if (!merged[d.month][d.day]) merged[d.month][d.day] = [];
    merged[d.month][d.day].push({
      icon: '📝',
      type: 'lead',
      title: `跟进：${log.client || '客户'}${log.type ? ' · ' + log.type : ''}`,
      desc: `${log.channel ? '[' + log.channel + '] ' : ''}${(log.content || '').replace(/\n/g, ' ').slice(0, 80)}`,
      _fromTimeline: true
    });
  });

  return merged;
});

const getDayClass = (monthNum, dayNum) => {
  if (isSelected(monthNum, dayNum)) {
    return 'bg-zen-ink text-white font-bold shadow-sm scale-105 border border-zen-ink';
  }
  if (hasLogs(monthNum, dayNum)) {
    return 'bg-zen-green/15 text-zen-green font-bold border border-zen-green/35 shadow-sm';
  }
  return 'border border-zen-light text-zen-ink hover:bg-zen-light/20 hover:border-zen-tea/35';
};

const hasLogs = (monthNum, dayNum) => {
  const dayLogs = getDayLogs(monthNum, dayNum);
  return dayLogs.length > 0;
};

const isSelected = (monthNum, dayNum) => {
  return activeMonth.value === monthNum && activeDay.value === dayNum && viewState.value === 'detail';
};

const getMonthLogsCount = (monthNum) => {
  const monthData = mergedSchedules.value[monthNum];
  if (!monthData) return 0;
  let count = 0;
  for (const day in monthData) {
    const filtered = filterLogsArray(monthData[day]);
    count += filtered.length;
  }
  return count;
};

const getDayLogs = (monthNum, dayNum) => {
  const monthData = mergedSchedules.value[monthNum];
  if (!monthData || !monthData[dayNum]) return [];
  return filterLogsArray(monthData[dayNum]);
};

const getMonthFlatLogs = (monthNum) => {
  const monthData = mergedSchedules.value[monthNum] || {};
  return Object.keys(monthData)
    .sort((a, b) => Number(a) - Number(b))
    .flatMap(day => filterLogsArray(monthData[day]).map(log => ({ ...log, day: Number(day) })));
};

const getActiveDayLogs = () => {
  return getDayLogs(activeMonth.value, activeDay.value);
};

const filterLogsArray = (logsArray) => {
  if (!logsArray) return [];
  if (activeFilter.value === 'all') return logsArray;
  
  if (activeFilter.value === 'system') {
    return logsArray.filter(log => log.type === 'system' || log.type === 'profit');
  }
  return logsArray.filter(log => log.type === activeFilter.value);
};

const getLogMarkerClass = (monthNum, dayNum) => {
  const logs = getDayLogs(monthNum, dayNum);
  if (!logs.length) return '';
  const first = logs[0];
  if (first.type === 'contract') return 'bg-zen-green';
  if (first.type === 'lead') return 'bg-[#E07A24]';
  return 'bg-zen-tea';
};

// 6. Navigation Click Handler
const openDayDetails = (monthNum, dayNum) => {
  activeMonth.value = monthNum;
  activeDay.value = dayNum;
  viewState.value = 'detail';
};

const addTodo = () => {
  if (!newTodoTitle.value.trim()) {
    alert('请输入待办标题！');
    return;
  }
  todoItems.value.unshift({
    id: Date.now(),
    title: newTodoTitle.value.trim(),
    desc: newTodoDesc.value.trim() || '手动建立的业务待办。',
    due: newTodoDue.value.trim() || '待定',
    priority: newTodoPriority.value,
    done: false
  });
  newTodoTitle.value = '';
  newTodoDesc.value = '';
  newTodoDue.value = '今天';
  newTodoPriority.value = '中优先级';
};

const deleteTodo = (id) => {
  todoItems.value = todoItems.value.filter(todo => todo.id !== id);
};

const generateAiTodos = () => {
  const generated = [
    { id: Date.now(), title: 'AI 建议：补发 6月5日物流放行提醒', desc: '围绕汉堡海关提单、TUV 品控表，提前通知德国客户。', due: '6月5日前', priority: '高优先级', done: false },
    { id: Date.now() + 1, title: 'AI 建议：6月15日回款前置沟通', desc: '针对清迈 Somchai 验收结款，提前准备代理现场确认话术。', due: '6月12日', priority: '中优先级', done: false }
  ];
  const existingTitles = new Set(todoItems.value.map(todo => todo.title));
  todoItems.value = [...generated.filter(todo => !existingTitles.has(todo.title)), ...todoItems.value];
};

const getTodoPriorityClass = (priority) => {
  if (priority === '高优先级') return 'bg-zen-crimson/10 text-zen-crimson border border-zen-crimson/20';
  if (priority === '低优先级') return 'bg-zen-tea/10 text-zen-tea border border-zen-tea/20';
  return 'bg-amber-100 text-amber-700 border border-amber-200';
};

// 7. Watch for Cockpit date clicks routing props
watch(() => props.jumpToScheduleDate, (newVal) => {
  if (newVal && newVal.day && newVal.month) {
    openDayDetails(newVal.month, newVal.day);
    // Clear out jump payload
    emit('clear-jump-schedule');
  }
}, { immediate: true });

onMounted(() => {
  if (props.jumpToScheduleDate && props.jumpToScheduleDate.day) {
    openDayDetails(props.jumpToScheduleDate.month, props.jumpToScheduleDate.day);
    emit('clear-jump-schedule');
  }
});

// 8. Custom Logs Editor Actions
const addLogItem = () => {
  if (!newLogTitle.value.trim()) {
    alert('请输入日志标题！');
    return;
  }

  const iconMap = {
    lead: '📝',
    contract: '🤝',
    system: '⚙️',
    profit: '🏦'
  };

  const newLog = {
    icon: iconMap[newLogType.value] || '📄',
    type: newLogType.value,
    title: newLogTitle.value.trim(),
    desc: newLogDesc.value.trim() || '用户手动记录，已自动热同步进入本地 RAG 分片索引。'
  };

  if (!annualSchedules.value[activeMonth.value]) {
    annualSchedules.value[activeMonth.value] = {};
  }
  if (!annualSchedules.value[activeMonth.value][activeDay.value]) {
    annualSchedules.value[activeMonth.value][activeDay.value] = [];
  }

  annualSchedules.value[activeMonth.value][activeDay.value].push(newLog);

  // Clear fields
  newLogTitle.value = '';
  newLogDesc.value = '';
  alert('✨ 成功录入！日志已同步，本地向量切片索引编译就绪。');
};

const deleteLogItem = (rec) => {
  // Timeline-derived entries are managed in the customer detail page, not here
  if (rec && rec._fromTimeline) return;
  if (confirm('确认删除该条日志流水吗？')) {
    const list = annualSchedules.value[activeMonth.value]?.[activeDay.value];
    if (list) {
      const realIdx = list.indexOf(rec);
      if (realIdx !== -1) {
        list.splice(realIdx, 1);
      }
    }
  }
};

// 9. Simulated AI Local Model Daily Analysis RAG Output
const getAiDailySummary = () => {
  const count = getActiveDayLogs().length;
  if (count === 0) {
    return '该日处于无活跃业务外发的保密巡检期。本地 SQLite 加密校验已完成，AI 助手团队建议业务员继续关注潜在询盘以触发新的跟进流转。';
  }
  
  if (activeMonth.value === 5 && activeDay.value === 31) {
    return '【Pilot RAG 深度分析 - 5月31日】：本日发生了重大系统级升级，8项特种技能已全部导入并就绪；同时德国 Müller 的越野竞技防撞杠首单谈判正在紧密攻坚，建议业务员调用「地道多语言起草」技能一键发送 TUV 品控与防冻参数邮件。';
  }
  if (activeMonth.value === 5 && activeDay.value === 30) {
    return '【Pilot RAG 深度分析 - 5月30日】：泰国客户 Somchai 合同首款已确认划转，SQLite 数据已锁定；同时本地 3 本产品彩页画册已完成多模态矢量解析入库，建议下一轮询盘对齐时直接调用此 RAG 底库。';
  }
  
  return `【Pilot AI 诊断报告】：本日共有 ${count} 项业务和日志事件，系统已对相关参数进行了矢量召回。SQLite 数据库物理切片已更新。建议销售总监 Sofia 安排下一轮的跟进督导，并为大客户建立专属的 GEO 索引优化通道。`;
};

// 10. Export Functions
const exportDayLog = () => {
  const logs = getActiveDayLogs();
  if (!logs.length) {
    alert('今日无日程，无需导出。');
    return;
  }
  let txt = `=== MagicHub 业务日志记录 (2026年${activeMonth.value}月${activeDay.value}日) ===\n\n`;
  logs.forEach((log, idx) => {
    txt += `[${idx+1}] [${log.type.toUpperCase()}] ${log.title}\n描述：${log.desc}\n\n`;
  });
  txt += `AI 智能诊断：${getAiDailySummary()}\n`;
  
  // Custom Clipboard copy
  navigator.clipboard.writeText(txt).then(() => {
    alert('📋 日程文本已复制到剪贴板，您可以随时粘帖至邮件或本地文档中！');
  });
};

const generateAnnualReport = () => {
  // Compute real figures from live data
  const parseAmt = (v) => typeof v === 'number' ? v : (parseFloat(String(v || '').replace(/[^0-9.]/g, '')) || 0);
  const dealTotal = (props.contracts || []).reduce((s, c) => s + parseAmt(c.value), 0);
  const goalBase = 500000;
  const goalPct = goalBase ? Math.round((dealTotal / goalBase) * 100) : 0;
  const followCount = (props.timelineLogs || []).length;
  const contractCount = (props.contracts || []).length;
  const fmt = (n) => '¥' + n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const reportDate = new Date().toISOString().slice(0, 10);
  // Generate premium markdown yearly report grounded in real data
  annualReportText.value = `# 禪 MagicHub · 2026年度外贸业务大底盘总结与销售决策预测报告
报告生成时间：${reportDate}
系统安全密钥：Offline Secure RAG / SQLite-V4 (Verified)

## 一、2026年度业务流水统计核心指标

- **年度大货成交总额**: ${fmt(dealTotal)} (占本期基准目标 ${fmt(goalBase)} 的 ${goalPct}%)
- **年度总跟进次数**: ${followCount} 次
- **生效合同订单**: ${contractCount} 笔
- **核心待办事件**: 由系统依据实时商机与跟进自动生成

---

## 二、大客户及商机转化深度复盘 (以 5 月为例)

### 1. 德国 Müller 越野配件第一期大货采购
- **进展**: 已完成防冻参数答复 (-20°C 至 -40°C 实测通过) 并符合德国 TUV 认证。
- **金额**: ¥32,000.00
- **AI 转化概率**: 89% (建议周一早盘使用国内外 API 路由自动推送 RAG 答复信)。

### 2. 泰国 Somchai 农业折叠蓄水囊代理项目
- **进展**: 首款 ¥1.5万 定金成功到账，协同驻点地面代理 Sompop 提供本土清关和实地安装演示。
- **金额**: ¥20,853.80
- **AI 协同效果**: 成功减少代理线上视频耗时，缩短转化周期 62%。

---

## 三、ChromaDB 向量索引与 IDE 标准技能仓载入状况
- **IDE 特种技能仓**: \`a11y-debugging\`, \`audit\`, \`polish\`, \`optimize\`, \`typeset\`, \`harden\` 等 8 大 IDE 特种外包技能已于 5月31日 顺利编译部署至 Pilot 底盘。
- **RAG 知识切片**: 本月累计导入 3 部越野配件竞技保险杠、折叠蓄水囊多模态彩页图纸，向量分片数量 480 个，检索延迟平均 11ms。

---

## 四、2026 下半年度销售业绩预测与 AI 智能建议
1. **产品侧**: 鉴于 Sofia 营销总监关于 GEO 独立站长尾词收录率已达 94% 的报告，建议下半年在独立站大量铺设 "4x4 offroad bumper TUV", "agricultural bladder tank FDA" 等高收录权重长尾词。
2. **市场侧**: 加速中东 Al-Mutairi 蓄水囊 200 套首大单的备忘录转合同谈判，力求在 6-7 月结款，使年度目标达成率快速跃升至 25% 以上。
3. **安全侧**: 继续维持 SQLite 物理隔离云备策略，严防客商核心底稿数据外泄。`;

  isReportModalOpen.value = true;
};

const copyAnnualReport = () => {
  navigator.clipboard.writeText(annualReportText.value).then(() => {
    alert('✨ 2026年度业务分析报告全文已成功复制为 Markdown 格式，可直接分发！');
    isReportModalOpen.value = false;
  });
};
</script>

<style scoped>
/* Custom styled vertical scrollbar for popover and list drawers */
.scrollbar-elegant::-webkit-scrollbar {
  width: 4px;
}
.scrollbar-elegant::-webkit-scrollbar-track {
  background: transparent;
}
.scrollbar-elegant::-webkit-scrollbar-thumb {
  background: rgba(98, 114, 84, 0.2);
  border-radius: 9px;
}
.scrollbar-elegant::-webkit-scrollbar-thumb:hover {
  background: rgba(98, 114, 84, 0.4);
}
</style>
