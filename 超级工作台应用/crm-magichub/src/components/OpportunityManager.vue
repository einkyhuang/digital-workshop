<template>
  <div class="space-y-6 font-sans text-zen-ink">
    <!-- Header -->
    <div class="pb-4 border-b border-zen-light/30">
      <h2 class="text-xl font-semibold font-serif-sc tracking-wide">商机与项目漏斗 (Opportunities)</h2>
      <p class="text-xs text-zen-gray mt-1">追踪销售漏斗，预测成交概率并利用 AI 动态匹配推进策略。</p>
    </div>

    <!-- Metrics Row -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 border border-white/50 shadow-sm">
        <span class="block text-[10px] text-zen-gray font-semibold uppercase tracking-wider">活跃商机总额</span>
        <span class="text-xl font-semibold block mt-1.5">{{ formatCNY(totalDealAmount) }}</span>
        <p class="text-[9px] text-zen-gray mt-1">包含当前处于跟进、报价及谈判中的所有意向商机。</p>
      </div>
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 border border-white/50 shadow-sm">
        <span class="block text-[10px] text-zen-gray font-semibold uppercase tracking-wider">AI 预测加权赢单价值</span>
        <span class="text-xl font-semibold text-zen-green block mt-1.5">{{ formatCNY(weightedWinValue) }}</span>
        <p class="text-[9px] text-zen-gray mt-1">基于各商机金额与 AI 赢单概率智能加权计算。</p>
      </div>
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 border border-white/50 shadow-sm">
        <span class="block text-[10px] text-zen-gray font-semibold uppercase tracking-wider">平均赢单概率</span>
        <span class="text-xl font-semibold block mt-1.5">{{ avgProbability }}%</span>
        <p class="text-[9px] text-zen-gray mt-1">当前全部活跃商机的 AI 预测赢单率平均值。</p>
      </div>
    </div>

    <!-- Visual Pipeline Funnel -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50">
      <h3 class="text-sm font-semibold font-serif-sc mb-5 flex items-center gap-2">
        <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
        商机流转漏斗推进图
      </h3>
      <div class="flex flex-col md:flex-row items-stretch justify-between gap-4">
        <div
          v-for="(stage, idx) in stages"
          :key="idx"
          class="flex-1 rounded-xl p-4 border border-zen-light/50 bg-zen-paper/30 flex flex-col justify-between hover:border-zen-green/40 hover:bg-white transition-all duration-300 shadow-sm"
        >
          <div>
            <div class="flex justify-between items-center text-[10px] text-zen-gray mb-2">
              <span class="font-mono font-semibold">{{ stage.phase }}</span>
              <span>{{ stage.count }}个项目</span>
            </div>
            <h4 class="text-xs font-semibold font-serif-sc mb-1">{{ stage.name }}</h4>
            <span class="text-sm font-semibold text-zen-ink font-mono">{{ stage.amount }}</span>
          </div>
          <div class="mt-4 pt-2.5 border-t border-zen-light/20 flex justify-between items-center text-[9px] text-zen-gray select-none">
            <span>转化率: {{ stage.ratio }}%</span>
            <span class="text-zen-green font-medium">路由: {{ isSecretMode ? 'Llama3' : stage.model }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Active Deals List -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50">
      <h3 class="text-sm font-semibold font-serif-sc mb-4 flex items-center gap-2">
        <span class="w-1.5 h-3 bg-zen-green rounded-full"></span>
        活跃商机明细账目 (Active Deals Ledger)
      </h3>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs text-zen-ink">
          <thead>
            <tr class="border-b border-zen-light/40 text-zen-gray font-serif-sc text-[10px] uppercase tracking-wider">
              <th class="py-3 font-medium">商机/项目名称</th>
              <th class="py-3 font-medium">客户企业</th>
              <th class="py-3 font-medium">金额价值</th>
              <th class="py-3 font-medium">当前阶段</th>
              <th class="py-3 font-medium text-center">AI 赢单率</th>
              <th class="py-3 font-medium">下步跟进动作</th>
              <th class="py-3 font-medium text-right">操作</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zen-light/20 text-[11px]">
            <tr
              v-for="deal in deals"
              :key="deal.id"
              class="transition-all duration-500"
              :class="highlightedDealId === deal.id ? 'bg-zen-green/10 font-bold border-l-2 border-zen-green animate-pulse' : 'hover:bg-zen-paper/20'"
            >
              <td class="py-3.5 pr-2 font-medium">{{ deal.title }}</td>
              <td class="py-3.5 pr-2">
                <span class="mr-1">{{ deal.flag }}</span>
                <span>{{ deal.client }}</span>
              </td>
              <td class="py-3.5 pr-2 font-semibold font-mono">{{ deal.amount }}</td>
              <td class="py-3.5 pr-2">
                <span class="px-2 py-0.5 rounded bg-zen-paper border border-zen-light text-[9px] font-medium">
                  {{ deal.stage }}
                </span>
              </td>
              <td class="py-3.5 text-center font-semibold font-mono text-zen-green">
                {{ deal.probability }}%
              </td>
              <td class="py-3.5 pr-2 text-zen-gray max-w-[160px] truncate" :title="deal.nextStep">
                {{ deal.nextStep }}
              </td>
              <td class="py-3.5 text-right select-none">
                <button
                  @click="openAiSuggest(deal)"
                  class="text-zen-green hover:text-zen-ink font-semibold"
                >
                  AI 推进策略 ➡️
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Interactive AI Strategy ZenModal -->
    <ZenModal :open="strategyModalOpen" :title="'AI 项目推进策略建议 | ' + (selectedDeal?.title || '')" @close="strategyModalOpen = false">
      <div class="space-y-4 text-xs leading-relaxed" v-if="selectedDeal">
        <div class="flex justify-between items-center border-b border-zen-light/35 pb-2.5">
          <div class="flex items-center gap-2">
            <span>{{ selectedDeal.flag }}</span>
            <div>
              <p class="font-semibold text-zen-ink font-serif-sc">{{ selectedDeal.client }}</p>
              <p class="text-[10px] text-zen-gray">商机金额：{{ selectedDeal.amount }} | 预计赢单率：{{ selectedDeal.probability }}%</p>
            </div>
          </div>
        </div>

        <div class="space-y-3 bg-zen-paper/60 p-4 rounded-xl border border-zen-light/20">
          <span class="block text-[9px] text-zen-gray font-semibold uppercase tracking-wider flex items-center gap-1.5">
            <span class="relative flex h-1.5 w-1.5">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-green opacity-75"></span>
              <span class="relative inline-flex rounded-full h-1.5 w-1.5 bg-zen-green"></span>
            </span>
            {{ isSecretMode ? 'Ollama 本地极密推荐建议 (物理脱敏)' : 'Gemini 智能网关推进策略 (云端精算)' }}
          </span>
          <p class="text-[11px] text-zen-ink font-serif-sc leading-relaxed whitespace-pre-wrap">
            {{ selectedDeal.aiStrategy }}
          </p>
        </div>

        <div class="p-3 bg-zen-green/5 border border-zen-green/20 rounded-xl flex items-center gap-2" v-if="isSecretMode">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-green shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
          </svg>
          <span class="text-[9px] text-zen-green font-medium">商业情报本地防护锁激活：策略生成不经公有云。</span>
        </div>
      </div>
      <template #footer>
        <button
          @click="strategyModalOpen = false"
          class="px-5 py-2 rounded-lg bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold"
        >
          采纳并更新待办
        </button>
        <button
          @click="strategyModalOpen = false"
          class="px-5 py-2 rounded-lg border border-zen-light text-zen-gray text-xs hover:text-zen-ink hover:bg-zen-light/20 transition-all font-medium"
        >
          返回
        </button>
      </template>
    </ZenModal>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import ZenModal from './ZenModal.vue';

const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  },
  deals: {
    type: Array,
    required: true
  },
  jumpToOpportunityId: {
    type: Number,
    default: null
  }
});

const emit = defineEmits(['update:deals', 'clear-jump-opportunity']);

// Parse strings like "¥32,000.00" or "$190" into a number
const parseAmount = (val) => {
  if (typeof val === 'number') return val;
  if (!val) return 0;
  const num = String(val).replace(/[^0-9.]/g, '');
  return parseFloat(num) || 0;
};

const formatCNY = (num) => '¥' + num.toLocaleString('zh-CN', { minimumFractionDigits: 2, maxFractionDigits: 2 });

const deals = computed({
  get: () => props.deals,
  set: (val) => emit('update:deals', val)
});

// 活跃商机总额：所有商机金额之和
const totalDealAmount = computed(() =>
  deals.value.reduce((sum, d) => sum + parseAmount(d.amount), 0)
);

// AI 预测加权赢单价值：金额 × 赢单概率
const weightedWinValue = computed(() =>
  deals.value.reduce((sum, d) => sum + parseAmount(d.amount) * ((d.probability || 0) / 100), 0)
);

// 平均赢单率（作为"平均推进健康度"展示）
const avgProbability = computed(() => {
  if (!deals.value.length) return 0;
  const total = deals.value.reduce((sum, d) => sum + (d.probability || 0), 0);
  return Math.round(total / deals.value.length);
});

// 动态漏斗：按商机阶段分组统计真实数量与金额
const stageDefs = [
  { phase: '01', name: '清洗与意图确认', ratio: '85', model: 'DeepSeek' },
  { phase: '02', name: '技术核算报价', ratio: '60', model: 'DeepSeek' },
  { phase: '03', name: '商务价格谈判', ratio: '42', model: 'Gemini' },
  { phase: '04', name: '合同拟定待签', ratio: '95', model: 'Gemini' }
];

const stages = computed(() => stageDefs.map(def => {
  const matched = deals.value.filter(d => d.stage === def.name);
  const amount = matched.reduce((sum, d) => sum + parseAmount(d.amount), 0);
  return {
    ...def,
    count: matched.length,
    amount: formatCNY(amount)
  };
}));

const strategyModalOpen = ref(false);
const selectedDeal = ref(null);
const highlightedDealId = ref(null);

const openAiSuggest = (deal) => {
  selectedDeal.value = deal;
  strategyModalOpen.value = false;
  setTimeout(() => {
    strategyModalOpen.value = true;
  }, 50);
};

// Listen to global jump requests to high-light specific opportunity and trigger AI strategic suggestion modal
watch(() => props.jumpToOpportunityId, (newVal) => {
  if (newVal) {
    const deal = deals.value.find(d => d.id === newVal);
    if (deal) {
      highlightedDealId.value = newVal;
      openAiSuggest(deal);
      
      // Clear visual highlight pulsing state after 4 seconds
      setTimeout(() => {
        highlightedDealId.value = null;
      }, 4000);
    }
    // Inform parent to clear the jump parameter
    emit('clear-jump-opportunity');
  }
}, { immediate: true });
</script>
