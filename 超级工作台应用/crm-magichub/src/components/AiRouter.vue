<template>
  <div class="space-y-6 font-sans">
    <!-- Header -->
    <div class="flex justify-between items-center pb-4 border-b border-zen-light/30">
      <div>
        <h2 class="text-xl font-semibold font-serif-sc text-zen-ink tracking-wide">AI 智能路由网关 (AI Router)</h2>
        <p class="text-xs text-zen-gray mt-1">根据任务类型与数据密级，动态调度国内外云端模型与本地离线算力。</p>
      </div>

      <!-- Quick Toggle for Secret Mode -->
      <div class="flex items-center gap-3 bg-zen-paper p-1.5 rounded-xl border border-zen-light/40">
        <span class="text-xs font-medium pl-2 select-none" :class="isSecretMode ? 'text-zen-tea font-semibold' : 'text-zen-gray'">
          {{ isSecretMode ? '极密模式 (已启用)' : '普通模式 (云端辅助)' }}
        </span>
        <button
          @click="toggleSecretMode"
          class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-300 ease-in-out focus:outline-none focus:ring-2 focus:ring-zen-green/20"
          :class="isSecretMode ? 'bg-zen-green' : 'bg-zen-light'"
        >
          <span
            class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-300 ease-in-out"
            :class="isSecretMode ? 'translate-x-5' : 'translate-x-0'"
          />
        </button>
      </div>
    </div>

    <!-- Active Routing Diagram -->
    <div class="apple-glass rounded-2xl p-6 border border-white/50 relative overflow-hidden">
      <!-- Background bamboo decor -->
      <div class="absolute inset-0 bamboo-bg-decor"></div>

      <h3 class="text-sm font-semibold text-zen-ink font-serif-sc mb-6 flex items-center gap-2 relative z-10">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-green" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
        </svg>
        网关流量拓扑图 (Active Gateway Topology)
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-7 items-center justify-between gap-4 py-4 relative z-10">
        <!-- Client UI -->
        <div class="col-span-1 md:col-span-2 bg-zen-bg rounded-xl p-4 border border-zen-light/40 flex flex-col items-center justify-center text-center shadow-sm">
          <div class="w-10 h-10 rounded-full bg-zen-ink text-white flex items-center justify-center mb-2 font-serif-sc">
            Zen
          </div>
          <span class="text-xs font-semibold text-zen-ink">MagicHub 业务层</span>
          <span class="text-[10px] text-zen-gray mt-0.5">本地数据及输入</span>
        </div>

        <!-- Arrows 1 -->
        <div class="col-span-1 flex justify-center text-zen-tea">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 transform rotate-90 md:rotate-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M14 5l7 7m0 0l-7 7m7-7H3" />
          </svg>
        </div>

        <!-- Router Node -->
        <div class="col-span-1 md:col-span-1 bg-zen-paper rounded-xl p-4 border border-zen-light flex flex-col items-center justify-center text-center shadow-sm relative">
          <div class="w-8 h-8 rounded-full flex items-center justify-center mb-2" :class="isSecretMode ? 'bg-zen-tea/10 text-zen-green zen-active-indicator' : 'bg-zen-light/60 text-zen-ink'">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
            </svg>
          </div>
          <span class="text-xs font-semibold text-zen-ink">路由网关</span>
          <span class="text-[9px] text-zen-tea font-medium mt-0.5" v-if="isSecretMode">极密接管中</span>
          <span class="text-[9px] text-zen-gray mt-0.5" v-else>云端自适应</span>
        </div>

        <!-- Arrows 2 -->
        <div class="col-span-1 flex justify-center text-zen-tea">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 transform rotate-90 md:rotate-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M14 5l7 7m0 0l-7 7m7-7H3" />
          </svg>
        </div>

        <!-- Models Options -->
        <div class="col-span-1 md:col-span-2 space-y-3">
          <!-- Domestic Node -->
          <div
            class="flex items-center justify-between p-2.5 rounded-lg border text-xs transition-all duration-300"
            :class="isSecretMode ? 'bg-zen-paper/30 border-zen-light/30 text-zen-gray/50 line-through' : 'bg-white border-zen-light shadow-sm text-zen-ink hover:border-zen-green/40'"
          >
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 rounded-full" :class="isSecretMode ? 'bg-zen-light' : 'bg-zen-tea zen-active-indicator'"></div>
              <div>
                <p class="font-medium text-[11px]">国内低能耗通道</p>
                <p class="text-[9px] text-zen-gray">DeepSeek V2 (批量清洗)</p>
              </div>
            </div>
            <span class="text-[9px] bg-zen-light/50 px-1.5 py-0.5 rounded text-zen-gray select-none">云端</span>
          </div>

          <!-- Overseas Node -->
          <div
            class="flex items-center justify-between p-2.5 rounded-lg border text-xs transition-all duration-300"
            :class="isSecretMode ? 'bg-zen-paper/30 border-zen-light/30 text-zen-gray/50 line-through' : 'bg-white border-zen-light shadow-sm text-zen-ink hover:border-zen-green/40'"
          >
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 rounded-full" :class="isSecretMode ? 'bg-zen-light' : 'bg-zen-tea zen-active-indicator'"></div>
              <div>
                <p class="font-medium text-[11px]">海外多语言生成</p>
                <p class="text-[9px] text-zen-gray">Gemini 1.5 Pro / Claude</p>
              </div>
            </div>
            <span class="text-[9px] bg-zen-light/50 px-1.5 py-0.5 rounded text-zen-gray select-none">云端</span>
          </div>

          <!-- Local Node -->
          <div
            class="flex items-center justify-between p-2.5 rounded-lg border text-xs transition-all duration-300"
            :class="isSecretMode ? 'bg-zen-tea/5 border-zen-green text-zen-ink zen-secure-active' : 'bg-white border-zen-light text-zen-ink shadow-sm hover:border-zen-green/40'"
          >
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 rounded-full" :class="isSecretMode ? 'bg-zen-green zen-active-indicator' : 'bg-zen-light'"></div>
              <div>
                <p class="font-medium text-[11px]">极密本地离线通道</p>
                <p class="text-[9px] text-zen-gray">Ollama Llama 3 8B (断网)</p>
              </div>
            </div>
            <span class="text-[9px] px-1.5 py-0.5 rounded font-semibold select-none" :class="isSecretMode ? 'bg-zen-green text-white' : 'bg-zen-light text-zen-gray'">本地</span>
          </div>
        </div>
      </div>

      <!-- Safe Wave Status -->
      <div v-if="isSecretMode" class="mt-4 p-3 bg-zen-tea/10 border border-zen-green/30 rounded-xl flex items-center gap-2.5">
        <span class="relative flex h-2.5 w-2.5">
          <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-green opacity-75"></span>
          <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-zen-green"></span>
        </span>
        <p class="text-[11px] text-zen-green font-medium">
          极密断网隔离模式已激活。外网 API 请求已全部熔断，所有敏感计算及开发信生成正在物理隔离的本地 Llama 3 8B 算力中安全生成。
        </p>
      </div>
    </div>

    <!-- Models Profiles Configuration -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Cloud Settings -->
      <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-4">
        <h3 class="text-sm font-semibold font-serif-sc text-zen-ink flex items-center gap-2">
          <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
          云端模型参数配置 (Cloud Model Configs)
        </h3>

        <div class="space-y-3.5">
          <!-- Domestic key -->
          <div>
            <label class="block text-xs font-semibold text-zen-ink mb-1.5">国内高并发模型密钥 (DeepSeek / Qwen)</label>
            <div class="relative">
              <input
                type="password"
                value="sk-deepseek-v2-xxxxxxxxxxxxxxxxxxxx"
                disabled
                class="w-full bg-zen-paper border border-zen-light/60 rounded-lg px-3 py-2 text-xs text-zen-gray/80 outline-none"
              />
              <span class="absolute right-3 top-2.5 flex h-2 w-2">
                <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
            </div>
            <p class="text-[9px] text-zen-gray mt-1">负责：询盘静默批量清洗，单季度 ~19,000 条高速打分标签提取。</p>
          </div>

          <!-- Overseas key -->
          <div>
            <label class="block text-xs font-semibold text-zen-ink mb-1.5">海外高质量多语种密钥 (Gemini / Claude)</label>
            <div class="relative">
              <input
                type="password"
                value="gemini-api-key-1.5-pro-xxxxxxxx"
                disabled
                class="w-full bg-zen-paper border border-zen-light/60 rounded-lg px-3 py-2 text-xs text-zen-gray/80 outline-none"
              />
              <span class="absolute right-3 top-2.5 flex h-2 w-2">
                <span class="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
            </div>
            <p class="text-[9px] text-zen-gray mt-1">负责：中东、欧美市场地道开发信起草与核心商业条款谈判辅助。</p>
          </div>
        </div>
      </div>

      <!-- Local Settings -->
      <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-4">
        <h3 class="text-sm font-semibold font-serif-sc text-zen-ink flex items-center gap-2">
          <span class="w-1.5 h-3 bg-zen-green rounded-full"></span>
          本地物理隔绝参数配置 (Local Model Configs)
        </h3>

        <div class="space-y-3.5">
          <!-- Ollama Host -->
          <div>
            <label class="block text-xs font-semibold text-zen-ink mb-1.5">Ollama 本地服务器地址 (Host IP)</label>
            <input
              type="text"
              value="http://127.0.0.1:11434"
              disabled
              class="w-full bg-zen-paper border border-zen-light/60 rounded-lg px-3 py-2 text-xs text-zen-gray/80 outline-none"
            />
            <p class="text-[9px] text-zen-gray mt-1">系统将自动检测本地 11434 端口下的离线 Ollama 运行状态。</p>
          </div>

          <!-- Ollama model list -->
          <div>
            <label class="block text-xs font-semibold text-zen-ink mb-1.5">预载本地大模型 (Loaded Models)</label>
            <div class="flex items-center justify-between p-2 rounded-lg bg-zen-paper border border-zen-light text-[11px] text-zen-ink">
              <span class="font-mono">llama3:8b-instruct-q4_K_M</span>
              <span class="text-[9px] font-medium text-zen-green px-1.5 py-0.5 bg-white border border-zen-green/20 rounded">运行中</span>
            </div>
            <p class="text-[9px] text-zen-gray mt-1">负责：极致隐私级别的底价核算、核心高密设计图纸回复本地起草。</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Models comparison table -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50">
      <h3 class="text-sm font-semibold font-serif-sc text-zen-ink mb-4 flex items-center gap-2">
        <span class="w-1.5 h-3 bg-zen-gold rounded-full"></span>
        AI 模型性价比与安全评测参考
      </h3>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs text-zen-ink">
          <thead>
            <tr class="border-b border-zen-light/40 text-zen-gray font-serif-sc text-[10px] uppercase tracking-wider">
              <th class="py-2.5 font-medium">模型通道</th>
              <th class="py-2.5 font-medium">适合任务</th>
              <th class="py-2.5 font-medium">单价估算 (1M Tokens)</th>
              <th class="py-2.5 font-medium">安全防护等级</th>
              <th class="py-2.5 font-medium">生成质量与语感</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zen-light/20 text-[11px]">
            <tr>
              <td class="py-3 font-medium">DeepSeek V2 (国内)</td>
              <td class="py-3 text-zen-gray">19k+ 海量客户资产快速清洗与评估</td>
              <td class="py-3">约 1.0 RMB</td>
              <td class="py-3 text-amber-600 font-medium">常规云端安全</td>
              <td class="py-3 text-zen-gray">中规中矩，逻辑性强</td>
            </tr>
            <tr>
              <td class="py-3 font-medium">Gemini 1.5 Pro (海外)</td>
              <td class="py-3 text-zen-gray">欧美、中东高端开发信，多语种商业谈判</td>
              <td class="py-3">约 15.0 RMB</td>
              <td class="py-3 text-amber-600 font-medium">高防护云端合规</td>
              <td class="py-3 text-zen-green font-semibold">极为地道，富有同理心</td>
            </tr>
            <tr>
              <td class="py-3 font-medium">Ollama Llama 3 8B (本地)</td>
              <td class="py-3 text-zen-gray">财务底价核算、保密图纸参数方案起草</td>
              <td class="py-3 text-zen-green font-semibold">0.0 RMB (完全离线)</td>
              <td class="py-3 text-zen-green font-semibold">物理断网级绝对隔离</td>
              <td class="py-3 text-zen-gray">满足基础交流，语调精炼</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['update:secret-mode']);

const toggleSecretMode = () => {
  emit('update:secret-mode', !props.isSecretMode);
};
</script>
