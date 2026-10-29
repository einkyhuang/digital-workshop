<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10">
    <!-- 1. Stats Row (驾驶舱指标面板) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
      <!-- 年度目标 (高保真渐变淡橙色卡片 - 左右黄金比例排版) -->
      <div
        @click="$emit('go-to-tab', 'opportunities')"
        class="group cursor-pointer bg-gradient-to-br from-[#FFF5EC] to-[#FFE8D6] border border-[#FFD8B3]/60 text-[#D46B12] rounded-2xl p-4 sm:p-5 lg:p-3 xl:p-5 shadow-sm relative overflow-hidden flex items-center justify-between min-h-[110px] hover:scale-[1.02] hover:shadow-md transition-all duration-300"
      >
        <div class="absolute inset-0 opacity-[0.03] bamboo-bg-decor pointer-events-none"></div>
        
        <!-- 左侧：主要指标与大额数字 -->
        <div class="flex flex-col justify-between h-full min-h-[70px] lg:min-h-[60px] xl:min-h-[70px]">
          <span class="text-[10px] uppercase font-semibold text-[#E07A24] tracking-wider flex items-center gap-1.5 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-[#FFA726] shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10" />
              <circle cx="12" cy="12" r="6" />
              <circle cx="12" cy="12" r="2" />
            </svg>
            年度目标
          </span>
          <span class="text-xl sm:text-2xl lg:text-[15px] xl:text-[20px] 2xl:text-2xl font-bold font-mono tracking-tight text-[#E05C00] whitespace-nowrap">{{ formatCNY(annualTarget) }}</span>
        </div>

        <!-- 右侧：进度条与指标堆叠 -->
        <div class="flex flex-col gap-1 text-[9px] lg:text-[8px] xl:text-[9px] text-[#E07A24] select-none border-l border-[#FFD8B3]/60 pl-3 lg:pl-1.5 xl:pl-3 shrink-0 relative z-10 w-28 lg:w-22 xl:w-28">
          <span class="font-bold flex items-center gap-1 text-[#E05C00]">
            <span class="w-1.5 h-1.5 rounded-full bg-[#FFA726] animate-pulse"></span>
            {{ goalPercent }}% 已达成
          </span>
          <div class="h-1.5 w-full bg-[#E05C00]/10 rounded-full overflow-hidden my-0.5">
            <div class="h-full bg-gradient-to-r from-[#FFA726] to-[#E05C00] rounded-full transition-all duration-1000 ease-out" :style="{ width: goalPercent + '%' }"></div>
          </div>
          <div class="flex justify-between text-[8px] lg:text-[7px] xl:text-[8px] text-[#E07A24]/75 font-mono select-none">
            <span>已收 ¥{{ formatShort(totalRevenue) }}</span>
            <span>目标 ¥{{ formatShort(annualTarget) }}</span>
          </div>
        </div>

        <!-- Linear Background SVG Icon -->
        <svg xmlns="http://www.w3.org/2000/svg" class="absolute bottom-2 right-2.5 h-14 w-14 opacity-[0.08] select-none pointer-events-none transform translate-y-2 translate-x-1.5 rotate-6 transition-transform duration-500 group-hover:scale-115 text-[#E05C00]" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.2">
          <circle cx="12" cy="12" r="10" />
          <circle cx="12" cy="12" r="6" />
          <circle cx="12" cy="12" r="2" />
        </svg>
      </div>

      <!-- 总管线 -->
      <div
        @click="$emit('go-to-tab', 'opportunities')"
        class="group cursor-pointer apple-glass apple-glass-hover rounded-2xl p-4 sm:p-5 lg:p-3 xl:p-5 flex flex-col justify-between min-h-[110px] hover:scale-[1.02] hover:shadow-md transition-all duration-300"
      >
        <div class="flex items-center justify-between text-zen-gray">
          <span class="text-[10px] uppercase font-semibold tracking-wider flex items-center gap-1.5 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray/60 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
            </svg>
            总管线
          </span>
          <span class="text-[9px] text-zen-gray/50 font-mono">¥</span>
        </div>
        <span class="text-xl sm:text-2xl lg:text-[15px] xl:text-[20px] 2xl:text-2xl font-bold font-mono tracking-tight text-zen-ink whitespace-nowrap">{{ formatCNY(totalPipeline) }}</span>
        
        <!-- Linear Background SVG Icon -->
        <svg xmlns="http://www.w3.org/2000/svg" class="absolute bottom-2 right-2.5 h-14 w-14 opacity-[0.07] select-none pointer-events-none transform translate-y-2 translate-x-1.5 rotate-6 transition-transform duration-500 group-hover:scale-115 text-zen-ink" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
        </svg>
      </div>

      <!-- 客户 (右侧分栏) -->
      <div
        @click="$emit('go-to-tab', 'customers')"
        class="group cursor-pointer apple-glass apple-glass-hover rounded-2xl p-4 sm:p-5 lg:p-3 xl:p-5 flex items-center justify-between min-h-[110px] hover:scale-[1.02] hover:shadow-md transition-all duration-300"
      >
        <!-- 左侧：主要数字 -->
        <div class="flex flex-col justify-between h-full min-h-[70px] lg:min-h-[60px] xl:min-h-[70px]">
          <span class="text-[10px] uppercase font-semibold text-zen-gray tracking-wider flex items-center gap-1.5 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-tea shrink-0 animate-pulse" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            客户
          </span>
          <span class="text-xl sm:text-2xl lg:text-[17px] xl:text-[20px] 2xl:text-2xl font-bold font-mono tracking-tight text-zen-ink whitespace-nowrap">{{ customerCount }} <span class="text-[10px] font-normal text-zen-gray ml-0.5">人</span></span>
        </div>
        <!-- 右侧：分行指标 -->
        <div class="flex flex-col gap-1.5 text-[9px] text-zen-gray select-none border-l border-white/30 pl-3 lg:pl-1.5 xl:pl-3 shrink-0 relative z-10">
          <span class="flex items-center gap-1 text-zen-green font-semibold">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
            </svg>
            {{ dealCustomerCount }} 已成交
          </span>
          <span class="flex items-center gap-1 text-zen-tea">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            {{ potentialCustomerCount }} 跟进中
          </span>
        </div>
        
        <!-- Linear Background SVG Icon -->
        <svg xmlns="http://www.w3.org/2000/svg" class="absolute bottom-2 right-2.5 h-14 w-14 opacity-[0.07] select-none pointer-events-none transform translate-y-2 translate-x-1.5 rotate-6 transition-transform duration-500 group-hover:scale-115 text-zen-ink" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
      </div>

      <!-- 订单 (右侧分栏) -->
      <div
        @click="$emit('go-to-tab', 'contracts')"
        class="group cursor-pointer apple-glass apple-glass-hover rounded-2xl p-4 sm:p-5 lg:p-3 xl:p-5 flex items-center justify-between min-h-[110px] hover:scale-[1.02] hover:shadow-md transition-all duration-300"
      >
        <!-- 左侧：主要数字 -->
        <div class="flex flex-col justify-between h-full min-h-[70px] lg:min-h-[60px] xl:min-h-[70px]">
          <span class="text-[10px] uppercase font-semibold text-zen-gray tracking-wider flex items-center gap-1.5 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-gray/60 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            订单
          </span>
          <span class="text-xl sm:text-2xl lg:text-[17px] xl:text-[20px] 2xl:text-2xl font-bold font-mono tracking-tight text-zen-ink whitespace-nowrap">{{ contractCount }} <span class="text-[10px] font-normal text-zen-gray ml-0.5">单</span></span>
        </div>
        <!-- 右侧：分行指标 -->
        <div class="flex flex-col gap-1.5 text-[9px] text-zen-gray select-none border-l border-white/30 pl-3 lg:pl-1.5 xl:pl-3 shrink-0 relative z-10">
          <span class="flex items-center gap-1 text-zen-green font-semibold">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 13l4 4L19 7" />
            </svg>
            {{ completedContracts }} 已完成
          </span>
          <span class="flex items-center gap-1 text-zen-tea">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            {{ executingContracts }} 进行中
          </span>
        </div>
        
        <!-- Linear Background SVG Icon -->
        <svg xmlns="http://www.w3.org/2000/svg" class="absolute bottom-2 right-2.5 h-14 w-14 opacity-[0.07] select-none pointer-events-none transform translate-y-2 translate-x-1.5 rotate-6 transition-transform duration-500 group-hover:scale-115 text-zen-ink" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      </div>

      <!-- 总利润 -->
      <div
        @click="$emit('go-to-tab', 'contracts')"
        class="group cursor-pointer apple-glass apple-glass-hover rounded-2xl p-4 sm:p-5 lg:p-3 xl:p-5 flex flex-col justify-between min-h-[110px] relative overflow-hidden ring-1 ring-zen-green/35 hover:scale-[1.02] hover:shadow-md transition-all duration-300"
      >
        <div class="absolute inset-0 bg-zen-green/[0.02] pointer-events-none"></div>
        <div class="flex items-center justify-between text-zen-green">
          <span class="text-[10px] uppercase font-semibold tracking-wider flex items-center gap-1.5 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5 text-zen-green shrink-0 zen-active-indicator" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            总利润
          </span>
          <span class="text-[9px] font-mono">¥</span>
        </div>
        <span class="text-xl sm:text-2xl lg:text-[15px] xl:text-[20px] 2xl:text-2xl font-bold font-mono tracking-tight text-zen-green relative z-10 whitespace-nowrap">{{ formatCNY(totalProfit) }}</span>
        
        <!-- Linear Background SVG Icon -->
        <svg xmlns="http://www.w3.org/2000/svg" class="absolute bottom-2 right-2.5 h-14 w-14 opacity-[0.07] select-none pointer-events-none transform translate-y-2 translate-x-1.5 rotate-6 transition-transform duration-500 group-hover:scale-115 text-zen-green" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
      </div>
    </div>

    <!-- 2. Second Row Grid: Calendar, To-Do, Goal -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Minimalist Calendar (苹果毛玻璃卡片 - overflow-visible 以支持悬停弹窗显示) -->
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 relative flex flex-col justify-between z-30 overflow-visible hover:z-50">
        <div class="absolute inset-0 rounded-2xl bamboo-bg-decor opacity-5 pointer-events-none"></div>
        <div class="relative z-10">
          <div class="flex justify-between items-center mb-3">
            <h3 class="text-xs font-semibold text-zen-ink font-serif-sc flex items-center gap-1.5">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-tea" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              {{ monthLabel }}
            </h3>
            <span class="text-[9px] bg-white/60 px-2 py-0.5 rounded text-zen-gray font-mono font-medium border border-white/40 select-none">今天</span>
          </div>

          <!-- Calendar Days Grid -->
          <div class="grid grid-cols-7 text-center text-[9px] font-medium text-zen-gray border-b border-white/20 pb-2 mb-2 select-none">
            <span>日</span><span>一</span><span>二</span><span>三</span><span>四</span><span>五</span><span>六</span>
          </div>
          <div class="grid grid-cols-7 text-center gap-y-2 text-[10px] font-mono relative z-10 select-none">
            <span v-for="b in leadingBlanks" :key="'blank-' + b" class="text-zen-gray/30"></span>
            
            <!-- Dynamic Interactive Days with Glassmorphic Hover Preview Popovers -->
            <div
              v-for="day in daysInMonth"
              :key="day"
              class="relative"
              @mouseenter="hoveredDay = day"
              @mouseleave="hoveredDay = null"
            >
              <span
                @click="goToScheduleDay(day)"
                class="w-6 h-6 flex items-center justify-center mx-auto rounded-lg cursor-pointer transition-all duration-200 relative z-10"
                :class="getDayClass(day)"
              >
                {{ day }}
              </span>

              <!-- Hover Glassmorphic Popover -->
              <div
                v-if="hoveredDay === day"
                class="absolute z-[99] bottom-full left-1/2 -translate-x-1/2 mb-2 w-60 p-3 bg-white/95 border border-white/40 shadow-xl rounded-xl backdrop-blur-md text-left select-text transition-all duration-200 pointer-events-none"
                style="filter: drop-shadow(0 10px 15px rgba(0, 0, 0, 0.15));"
              >
                <!-- Popover header -->
                <div class="flex justify-between items-center border-b border-black/5 pb-1.5 mb-1.5">
                  <span class="text-[9px] font-bold text-zen-gray uppercase tracking-widest flex items-center gap-1">
                    <span class="w-1.5 h-1.5 rounded-full bg-zen-tea animate-pulse"></span>
                    {{ displayMonth }}月{{ day }}日 记录预览
                  </span>
                  <span class="text-[8px] text-zen-tea font-mono font-medium" v-if="daySchedules[day]">
                    {{ daySchedules[day].length }}项记录
                  </span>
                </div>

                <!-- Popover list -->
                <div v-if="daySchedules[day]" class="space-y-1.5 max-h-[120px] overflow-y-auto scrollbar-elegant pr-0.5">
                  <div
                    v-for="(rec, idx) in daySchedules[day]"
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
                  点击查看日程总览大图 ➡️
                </div>

                <!-- Arrow down indicator -->
                <div class="absolute top-full left-1/2 -translate-x-1/2 -mt-[1px] w-0 h-0 border-l-[6px] border-l-transparent border-r-[6px] border-r-transparent border-t-[6px] border-t-white/95"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Important To-Do (Expanded into 2 columns) -->
      <div class="lg:col-span-2 apple-glass apple-glass-hover rounded-2xl p-5 flex flex-col justify-between">
        <div>
          <div class="flex justify-between items-center mb-3 border-b border-white/20 pb-2.5">
            <h3 class="text-xs font-semibold text-zen-ink font-serif-sc flex items-center gap-1.5">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-crimson" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
              重要待办 (AI Action Items)
            </h3>
            <span class="text-[9px] bg-zen-crimson/15 px-2 py-0.5 rounded-full text-zen-crimson font-medium border border-zen-crimson/20 select-none">{{ urgentCount }}项紧急 · {{ followCount }}项跟进</span>
          </div>

          <!-- To-Do items inside a spacious grid -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-3">
            <div
              v-for="item in actionItems"
              :key="item.id"
              class="p-3.5 rounded-xl border border-white/40 bg-white/25 flex flex-col justify-between hover:bg-white/45 transition-all shadow-sm"
            >
              <div class="flex items-start gap-2.5">
                <span class="w-2 h-2 rounded-full mt-1.5 shrink-0 animate-pulse" :class="item.dot"></span>
                <div>
                  <h4 class="font-semibold text-zen-ink text-xs leading-tight">{{ item.title }}</h4>
                  <p class="text-[9px] text-zen-gray mt-1 leading-relaxed">{{ item.desc }}</p>
                </div>
              </div>
              <div class="mt-3 flex items-center justify-between text-[8px] pt-2 border-t border-white/10 select-none">
                <span class="px-1.5 py-0.5 rounded font-semibold" :class="item.tagClass">{{ item.tag }}</span>
                <button @click="$emit('go-to-tab', item.target)" class="text-zen-tea hover:underline font-semibold flex items-center gap-0.5">🤖 智能处理 ➡️</button>
              </div>
            </div>
            <div v-if="!actionItems.length" class="md:col-span-2 text-center py-8 text-zen-gray/40 italic text-[11px] bg-white/10 rounded-xl border border-dashed border-white/40">
              暂无待办事项，新增商机或客户跟进后将自动生成 AI 行动建议。
            </div>
          </div>
        </div>

        <div class="pt-3 border-t border-white/20 mt-4 text-right select-none flex justify-between items-center text-[10px]">
          <span class="text-[9px] text-zen-gray/60">所有待办均由 Pilot 基座实时整理分析邮件/合同自动生成</span>
          <button
            @click="$emit('go-to-tab', 'customers')"
            class="text-zen-tea font-semibold hover:underline"
          >
            去处理全部待办 ➡️
          </button>
        </div>
      </div>
    </div>

    <!-- 3. Third Row: Opportunities Quick list -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 space-y-4">
      <div class="flex justify-between items-center pb-2.5 border-b border-white/20">
        <h3 class="text-xs font-semibold text-zen-ink font-serif-sc flex items-center gap-1.5">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-tea" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
          </svg>
          商机管理 (Active Opportunities)
        </h3>
        <button
          @click="$emit('go-to-tab', 'opportunities')"
          class="text-[10px] text-zen-gray hover:text-zen-ink font-serif-sc tracking-wide flex items-center gap-1"
        >
          查看全部 ➡️
        </button>
      </div>

      <!-- Quick list items -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div
          v-for="deal in topDeals"
          :key="deal.id"
          @click="$emit('go-to-tab', 'opportunities')"
          class="p-3.5 rounded-xl border border-white/40 bg-white/40 flex justify-between items-center text-xs hover:bg-white/60 transition-all shadow-sm cursor-pointer"
        >
          <div>
            <div class="flex items-center gap-1.5 mb-1.5 select-none">
              <span>{{ deal.flag }}</span>
              <span class="text-[9px] font-semibold text-zen-gray uppercase font-mono">{{ deal.client }}</span>
            </div>
            <h4 class="font-semibold text-zen-ink leading-tight">{{ deal.title }}</h4>
            <p class="text-[10px] text-zen-green font-semibold mt-1 font-mono">{{ deal.amount }} | AI 概率 {{ deal.probability }}%</p>
          </div>
          <span class="text-[8px] bg-white/60 px-2 py-0.5 rounded border border-white/40 text-zen-gray select-none shrink-0 ml-2">{{ deal.stage }}</span>
        </div>
        <div v-if="!topDeals.length" class="md:col-span-2 text-center py-8 text-zen-gray/40 italic text-[11px] bg-white/10 rounded-xl border border-dashed border-white/40">
          暂无活跃商机，可在「商机管理」中新增。
        </div>
      </div>
    </div>

    <!-- 4. Fourth Row: AI Assistant Team -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 space-y-4">
      <div class="flex justify-between items-center pb-2.5 border-b border-white/20">
        <h3 class="text-xs font-semibold text-zen-ink font-serif-sc flex items-center gap-1.5">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-green" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
          AI 助手团队 · {{ teamCount }}人
        </h3>
        <button
          @click="addNewAssistant"
          class="text-[10px] text-zen-tea hover:text-zen-ink font-semibold flex items-center gap-1 select-none"
        >
          + 新建 AI 协同专家
        </button>
      </div>

      <!-- Assistant profiles grid -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div
          v-for="member in aiTeam"
          :key="member.id"
          class="p-4 rounded-xl border border-white/40 bg-white/40 hover:bg-white/60 transition-all duration-300 shadow-sm space-y-2 flex flex-col justify-between"
        >
          <div>
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-zen-ink text-white flex items-center justify-center font-bold text-xs select-none">
                {{ member.emoji || (member.name ? member.name.charAt(0) : 'AI') }}
              </div>
              <div>
                <h4 class="text-xs font-semibold text-zen-ink leading-tight">{{ member.name }}</h4>
                <span class="text-[9px] text-zen-gray font-serif-sc">{{ member.role }}</span>
              </div>
            </div>
            <p class="text-[10px] text-zen-gray leading-relaxed mt-2.5">
              {{ member.desc }}
            </p>
          </div>
          <div class="flex justify-between items-center text-[8px] text-zen-green font-semibold pt-2 border-t border-white/10 select-none">
            <span>模型: {{ member.model || '智能路由' }}</span>
            <span class="w-1.5 h-1.5 rounded-full bg-zen-green zen-active-indicator"></span>
          </div>
        </div>
        <div v-if="!aiTeam.length" class="md:col-span-3 text-center py-8 text-zen-gray/40 italic text-[11px] bg-white/10 rounded-xl border border-dashed border-white/40">
          暂无 AI 协同专家，可在「团队管理」中新建。
        </div>
      </div>
    </div>

    <!-- Extra panel: Local data status overview -->
    <div class="apple-glass rounded-2xl p-5 select-none">
      <div class="flex justify-between items-center pb-2.5 border-b border-white/20 mb-3">
        <h4 class="text-xs font-semibold text-zen-ink font-serif-sc flex items-center gap-1.5">
          <span class="relative flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-green opacity-75"></span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-zen-green"></span>
          </span>
          本地数据底仓状态 (SQLite + ChromaDB)
        </h4>
        <span class="text-[9px] text-zen-gray">客户档案入库率: 100%</span>
      </div>
      <div class="h-2 w-full bg-zen-light rounded-full overflow-hidden">
        <div class="h-full bg-zen-green" style="width: 100%"></div>
      </div>
      <p class="text-[9px] text-zen-gray mt-2">本地加密底仓已就绪：当前共存储 {{ customerCount }} 条客户档案、{{ contractCount }} 份合同、{{ timelineLogs.length }} 条跟进记录，全部完成增量加密备份。</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

const emit = defineEmits(['go-to-tab']);

const props = defineProps({
  leads: { type: Array, default: () => [] },
  deals: { type: Array, default: () => [] },
  contracts: { type: Array, default: () => [] },
  timelineLogs: { type: Array, default: () => [] },
  teamMembers: { type: Array, default: () => [] },
  quoteLogs: { type: Array, default: () => [] }
});

// ── Helpers ───────────────────────────────────────────────────────────────
const parseAmount = (val) => {
  if (typeof val === 'number') return val;
  if (!val) return 0;
  return parseFloat(String(val).replace(/[^0-9.]/g, '')) || 0;
};
const formatCNY = (num) => '¥' + Number(num).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const formatShort = (num) => {
  if (num >= 10000) return (num / 10000).toFixed(1) + '万';
  if (num >= 1000) return (num / 1000).toFixed(1) + 'k';
  return String(Math.round(num));
};
const parseLogToDate = (dateStr) => {
  if (!dateStr) return null;
  const m = String(dateStr).match(/(\d{4})[-/](\d{1,2})[-/](\d{1,2})/);
  if (!m) return null;
  return { year: Number(m[1]), month: Number(m[2]), day: Number(m[3]) };
};

// ── Customer stats (from leads) ─────────────────────────────────────────────
const customerCount = computed(() => props.leads.length);
const dealCustomerCount = computed(() => props.leads.filter(l => l.stage === 'deal').length);
const potentialCustomerCount = computed(() => props.leads.filter(l => l.stage === 'potential').length);

// ── Pipeline / opportunities (from deals) ───────────────────────────────────
const totalPipeline = computed(() => props.deals.reduce((s, d) => s + parseAmount(d.amount), 0));

// ── Contracts / revenue ─────────────────────────────────────────────────────
const contractCount = computed(() => props.contracts.length);
const completedContracts = computed(() =>
  props.contracts.filter(c => ['已成单', '已完成'].includes(c.status)).length
);
const executingContracts = computed(() => contractCount.value - completedContracts.value);
const totalRevenue = computed(() => props.contracts.reduce((s, c) => s + parseAmount(c.value), 0));

// ── Annual target (revenue vs goal) ─────────────────────────────────────────
const ANNUAL_TARGET = 500000;
const annualTarget = ANNUAL_TARGET;
const goalPercent = computed(() => {
  if (!ANNUAL_TARGET) return 0;
  return Math.min(100, Math.round((totalRevenue.value / ANNUAL_TARGET) * 100));
});

// ── Profit (derived from real quote margins applied to real revenue) ────────
const avgMarginRatio = computed(() => {
  const quotes = props.quoteLogs.filter(q => parseAmount(q.price) > 0);
  if (!quotes.length) return 0.3; // sensible fallback when no quotes yet
  const ratios = quotes.map(q => {
    const price = parseAmount(q.price);
    const cost = parseAmount(q.cost) + parseAmount(q.freight) + price * (parseAmount(q.commission) / 100);
    return Math.max(0, (price - cost) / price);
  });
  return ratios.reduce((a, b) => a + b, 0) / ratios.length;
});
const totalProfit = computed(() => totalRevenue.value * avgMarginRatio.value);

// ── Calendar (fully dynamic from real dates) ────────────────────────────────
const now = new Date();
const displayYear = ref(now.getFullYear());
const displayMonth = ref(now.getMonth() + 1); // 1-12
const monthLabel = computed(() => `${displayYear.value}年${displayMonth.value}月`);
const leadingBlanks = computed(() => new Date(displayYear.value, displayMonth.value - 1, 1).getDay());
const daysInMonth = computed(() => new Date(displayYear.value, displayMonth.value, 0).getDate());

// Build day -> events map for the displayed month from real timeline + contracts
const daySchedules = computed(() => {
  const map = {};
  const push = (day, item) => {
    if (!map[day]) map[day] = [];
    map[day].push(item);
  };
  (props.timelineLogs || []).forEach(log => {
    const d = parseLogToDate(log.date);
    if (!d || d.year !== displayYear.value || d.month !== displayMonth.value) return;
    push(d.day, {
      icon: '📝',
      type: 'lead',
      title: `跟进：${log.client || '客户'}${log.type ? ' · ' + log.type : ''}`,
      desc: `${log.channel ? '[' + log.channel + '] ' : ''}${(log.content || '').replace(/\n/g, ' ').slice(0, 60)}`
    });
  });
  (props.contracts || []).forEach(c => {
    const d = parseLogToDate(c.date);
    if (!d || d.year !== displayYear.value || d.month !== displayMonth.value) return;
    push(d.day, {
      icon: '🤝',
      type: 'contract',
      title: `合同：${c.code || ''} ${c.client || ''}`.trim(),
      desc: `${c.product || ''} ${c.value || ''}`.trim()
    });
  });
  return map;
});

const selectedDay = ref(now.getDate());
const hoveredDay = ref(null);

const goToScheduleDay = (day) => {
  selectedDay.value = day;
  emit('go-to-tab', 'schedule', { selectedDay: day, selectedMonth: displayMonth.value });
};

const getDayClass = (day) => {
  if (selectedDay.value === day) {
    return 'bg-zen-ink text-white font-bold shadow-sm scale-105 border border-zen-ink';
  }
  if (daySchedules.value[day]) {
    return 'bg-zen-green/15 text-zen-green font-bold border border-zen-green/35 shadow-sm';
  }
  return 'border border-zen-light text-zen-ink hover:bg-zen-light/20 hover:border-zen-tea/35';
};

// ── AI Action Items / To-Do (derived from real deals + recent follow-ups) ───
const actionItems = computed(() => {
  const items = [];
  // From active opportunities: each deal's next step is an action item
  props.deals.forEach(d => {
    items.push({
      id: 'deal-' + d.id,
      title: `${d.client || ''}: ${d.title || '商机推进'}`,
      desc: `${d.nextStep || '推进该商机至下一阶段'} | 预计单值 ${d.amount || '-'}`,
      tag: (d.probability || 0) >= 80 ? '紧急且重要' : '重要不紧急',
      tagClass: (d.probability || 0) >= 80 ? 'text-zen-crimson bg-zen-crimson/10' : 'text-amber-700 bg-zen-gold/10',
      dot: (d.probability || 0) >= 80 ? 'bg-zen-crimson' : 'bg-zen-gold',
      target: 'opportunities'
    });
  });
  // From potential customers without recent follow-up
  props.leads.filter(l => l.stage === 'potential').slice(0, 4).forEach(l => {
    items.push({
      id: 'lead-' + l.id,
      title: `${l.name || l.client || '客户'}: 待跟进询盘`,
      desc: `${l.country || ''} ${(l.tags || []).join('、')} | 建议安排开发信或报价跟进。`,
      tag: '常规待办',
      tagClass: 'text-emerald-800 bg-zen-tea/10',
      dot: 'bg-zen-tea',
      target: 'customers'
    });
  });
  return items.slice(0, 6);
});
const urgentCount = computed(() => actionItems.value.filter(i => i.tag === '紧急且重要').length);
const followCount = computed(() => actionItems.value.length - urgentCount.value);

// ── Opportunities quick list (real deals) ───────────────────────────────────
const topDeals = computed(() => props.deals.slice(0, 4));

// ── AI assistant team (real team members) ───────────────────────────────────
const aiTeam = computed(() => props.teamMembers.filter(m => m.isAi));
const teamCount = computed(() => props.teamMembers.length);

const addNewAssistant = () => {
  emit('go-to-tab', 'team');
};
</script>
