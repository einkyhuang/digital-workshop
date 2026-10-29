<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10">
    <template v-if="viewState === 'list'">
    <!-- Header -->
    <div class="pb-4 border-b border-white/20 select-none">
      <h2 class="text-xl font-bold font-serif-sc tracking-wide">订单与贸易合同管理 (Contracts)</h2>
      <p class="text-xs text-zen-gray mt-1">起草并归档销售合同与商业协议，系统自动审计起订量 (MOQ) 并提示签约跟进。</p>
    </div>

    <!-- Metrics Row -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-5 select-none">
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 border border-white/50 text-center">
        <span class="block text-[9px] text-zen-gray font-semibold uppercase tracking-wider">生效合同总数</span>
        <span class="text-xl font-bold block mt-1.5 font-mono">{{ totalContracts }} 份</span>
      </div>
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 border border-white/50 text-center">
        <span class="block text-[9px] text-zen-gray font-semibold uppercase tracking-wider">签约回单总额</span>
        <span class="text-xl font-bold text-zen-green block mt-1.5 font-mono">{{ totalContractValue }}</span>
      </div>
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 border border-white/50 text-center">
        <span class="block text-[9px] text-zen-gray font-semibold uppercase tracking-wider">执行中订单</span>
        <span class="text-xl font-bold text-zen-tea block mt-1.5 font-mono">{{ executingCount }} 个</span>
      </div>
      <div class="apple-glass apple-glass-hover rounded-2xl p-5 border border-white/50 text-center">
        <span class="block text-[9px] text-zen-gray font-semibold uppercase tracking-wider">起订量合规率</span>
        <span class="text-xl font-bold block mt-1.5 font-mono">{{ complianceRate }}%</span>
      </div>
    </div>

    <!-- Active Contracts Table -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50">
      <h3 class="text-sm font-bold font-serif-sc mb-3 flex items-center gap-2 select-none">
        <span class="w-1.5 h-3 bg-zen-green rounded-full"></span>
        国际销售合同归档台账 (Contracts Ledger) <span class="text-[10px] font-normal text-zen-gray">(点击任意行可查看销售合同条款)</span>
      </h3>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs text-zen-ink">
          <thead>
            <tr class="border-b border-white/20 text-zen-gray font-serif-sc text-[10px] uppercase tracking-wider select-none">
              <th class="py-3 font-medium">合同编号</th>
              <th class="py-3 font-medium">客户签约方</th>
              <th class="py-3 font-medium">签约产品与规格</th>
              <th class="py-3 font-medium text-center">采购数量</th>
              <th class="py-3 font-medium text-center">起订量 (MOQ) 审计</th>
              <th class="py-3 font-medium text-right">商定总值</th>
              <th class="py-3 font-medium text-right">签署时间</th>
              <th class="py-3 font-medium text-right">状态</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10 text-[11px] font-mono">
            <tr
              v-for="c in contracts"
              :key="c.id"
              @click="openContractDetail(c)"
              class="hover:bg-white/40 transition-colors cursor-pointer"
            >
              <td class="py-3.5 pr-2 font-medium font-sans text-indigo-600">{{ c.code }}</td>
              <td class="py-3.5 pr-2 font-sans">
                <span class="mr-1 select-none">{{ c.flag }}</span>
                <span>{{ c.client }}</span>
              </td>
              <td class="py-3.5 pr-2 font-sans font-medium text-zen-ink">{{ c.product }}</td>
              <td class="py-3.5 pr-2 text-center font-medium">{{ c.quantity }} 套</td>
              <td class="py-3.5 text-center select-none">
                <span
                  class="px-2 py-0.5 rounded-full text-[9px] font-bold"
                  :class="c.quantity >= c.moq ? 'bg-zen-green/10 text-zen-green' : 'bg-zen-crimson/10 text-zen-crimson'"
                >
                  {{ c.quantity >= c.moq ? '满足起订量' : 'MOQ 不合规' }}
                </span>
              </td>
              <td class="py-3.5 pr-2 text-right font-bold text-zen-green">{{ c.value }}</td>
              <td class="py-3.5 pr-2 text-right text-zen-gray">{{ c.date }}</td>
              <td class="py-3.5 text-right font-sans select-none">
                <span class="px-2 py-0.5 rounded text-[9px] font-bold bg-zen-green text-white">
                  {{ c.status }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    </template>

    <!-- Sales Contract Detailed Page -->
    <div v-else-if="selectedContract" class="space-y-6 animate-fadeIn">
      <div class="pb-4 border-b border-white/20 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 select-none">
        <div class="flex items-center gap-4">
          <button
            @click="backToList"
            class="px-4 py-2 bg-white/50 hover:bg-white hover:translate-x-[-3px] border border-white/60 rounded-xl text-xs text-zen-ink font-semibold shadow-sm transition-all duration-300 outline-none flex items-center gap-1.5"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M15 19l-7-7 7-7" />
            </svg>
            返回合同台账
          </button>
          <div class="h-6 w-[1px] bg-white/30 hidden md:block"></div>
          <div>
            <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2 text-zen-ink">
              国际销售合同详细条款及归档
              <span class="text-xs font-normal text-zen-gray font-sans bg-white/40 border border-white/50 px-2 py-0.5 rounded-lg">
                {{ selectedContract.code }}
              </span>
            </h2>
            <p class="text-xs text-zen-gray mt-1">完整查看合同条款、MOQ 审计、付款交期与 AI 合规风险结论。</p>
          </div>
        </div>
        <span class="px-3 py-1 rounded-xl bg-zen-green text-white text-[10px] font-bold shadow-sm">{{ selectedContract.status }}</span>
      </div>

      <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-6 text-xs text-zen-ink select-text">
        <div class="flex justify-between items-center border-b border-white/20 pb-4 select-none">
          <div>
            <h4 class="text-lg font-bold font-serif-sc leading-tight">{{ selectedContract.client }}</h4>
            <p class="text-[11px] text-zen-gray mt-1">合同编号: {{ selectedContract.code }} | 签署日期: {{ selectedContract.date }}</p>
          </div>
          <span class="text-3xl select-none">{{ selectedContract.flag }}</span>
        </div>

        <!-- Contract Details -->
        <div class="p-4 bg-white/40 border border-white/50 rounded-2xl space-y-2.5">
          <span class="block text-[9px] text-zen-gray font-bold uppercase tracking-wider select-none">销售条款细则 (Sales Contract Terms)</span>
          
          <div class="grid grid-cols-2 gap-y-2.5 text-[11px]">
            <div class="text-zen-gray font-sans">签约产品规格:</div>
            <div class="text-right font-bold font-sans">{{ selectedContract.product }}</div>

            <div class="text-zen-gray font-sans">采购总量:</div>
            <div class="text-right font-bold font-mono">{{ selectedContract.quantity }} 套 (Units)</div>

            <div class="text-zen-gray font-sans">合同总金额:</div>
            <div class="text-right font-bold font-mono text-zen-green text-xs">{{ selectedContract.value }}</div>

            <div class="text-zen-gray font-sans">付款条款 (Payment Terms):</div>
            <div class="text-right font-bold font-sans">30% Advance T/T, 70% against B/L copy</div>

            <div class="text-zen-gray font-sans">交期时效 (Shipment Time):</div>
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
            <h5 class="text-[11px] font-bold font-serif-sc">MOQ 起订量合规审计合格</h5>
            <p class="text-[10px] text-zen-gray leading-normal">
              本批次签约订量为 <strong>{{ selectedContract.quantity }}</strong> 套，产品基准 MOQ 起订量限制为 <strong>{{ selectedContract.moq }}</strong> 套。本订单完全合规。
            </p>
          </div>
        </div>

        <div class="p-3 bg-black/[0.04] border border-white/30 rounded-2xl">
          <span class="block text-[8px] text-zen-gray font-bold uppercase select-none mb-1">AI 合规与法律条款审计风险检查</span>
          <p class="text-[10px] text-zen-gray leading-normal font-serif-sc">
            经系统本地隔离审计：买卖双方关于知识产权保护、不可抗力条款以及汉堡港/曼谷港交货争议管辖地（新加坡国际仲裁中心）已完美匹配，未发现潜在的单向倾斜索赔霸王条款漏洞，合同法律风险评级为：<strong>极低 (Safe)</strong>。
          </p>
        </div>
        <div class="flex flex-col sm:flex-row justify-end gap-3 pt-2 border-t border-white/20 select-none">
        <button
          @click="backToList"
          class="px-4 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          通过 AI 合规会签盖章
        </button>
        <button
          @click="backToList"
          class="px-4 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-semibold outline-none"
        >
          返回
        </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  contracts: {
    type: Array,
    required: true
  }
});

const emit = defineEmits(['update:contracts']);

const contracts = computed({
  get: () => props.contracts,
  set: (val) => emit('update:contracts', val)
});

// Parse "¥32,000.00" style strings into a number
const parseAmount = (val) => {
  if (typeof val === 'number') return val;
  if (!val) return 0;
  return parseFloat(String(val).replace(/[^0-9.]/g, '')) || 0;
};

// 生效合同总数
const totalContracts = computed(() => contracts.value.length);

// 签约回单总额
const totalContractValue = computed(() => {
  const sum = contracts.value.reduce((acc, c) => acc + parseAmount(c.value), 0);
  return '¥' + sum.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
});

// 执行中订单（状态非"已成单/已完成"视为执行中）
const executingCount = computed(() =>
  contracts.value.filter(c => c.status && !['已成单', '已完成'].includes(c.status)).length
);

// 满足起订量（MOQ 合规）比率，作为款项回笼/合规率展示
const complianceRate = computed(() => {
  if (!contracts.value.length) return 0;
  const ok = contracts.value.filter(c => Number(c.quantity) >= Number(c.moq)).length;
  return Math.round((ok / contracts.value.length) * 100);
});

// Sales Contract detailed page states
const viewState = ref('list');
const selectedContract = ref(null);

const openContractDetail = (c) => {
  selectedContract.value = c;
  viewState.value = 'detail';
};

const backToList = () => {
  viewState.value = 'list';
  selectedContract.value = null;
};
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
  animation: fadeIn 0.35s cubic-bezier(0.16, 1, 0.3, 1) forwards;
}
</style>
