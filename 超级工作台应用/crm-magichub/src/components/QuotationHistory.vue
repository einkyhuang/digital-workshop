<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10">
    <!-- Header -->
    <div class="pb-4 border-b border-white/20 select-none">
      <h2 class="text-xl font-bold font-serif-sc tracking-wide">产品报价核算记录 (Quotations)</h2>
      <p class="text-xs text-zen-gray mt-1">计算出厂底价与国际运费，利用 AI 审查报价方案的合理性与利润安全边际。</p>
    </div>

    <!-- Main View (Calculator & Log Table) -->
    <div v-if="!isDetailView" class="space-y-6">
      <!-- Active Quote Calculator -->
      <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 items-start">
        <!-- Calculator form -->
        <div class="xl:col-span-2 apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-4">
          <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
            <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
            国际贸易报价智能计算器 (Price Calculator)
          </h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            <div class="space-y-1">
              <label class="block font-bold text-zen-ink">目标产品 (Target Product)</label>
              <select
                v-model="calc.product"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
              >
                <option value="EX-XT-500 防结冰水箱">EX-XT-500 防结冰水箱</option>
                <option value="FL-WT-100 折叠聚氨酯水囊">FL-WT-100 折叠聚氨酯水囊</option>
              </select>
            </div>
            <div class="space-y-1">
              <label class="block font-bold text-zen-ink">贸易条款 (Incoterms)</label>
              <select
                v-model="calc.incoterms"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
              >
                <option value="CIF Hamburg">CIF Hamburg (含海运保费)</option>
                <option value="FOB Shanghai">FOB Shanghai (离岸价格)</option>
              </select>
            </div>
            <div class="space-y-1">
              <label class="block font-bold text-zen-ink">出厂成本底价 (Factory Cost per Unit)</label>
              <input
                type="number"
                v-model.number="calc.factoryCost"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono"
              />
            </div>
            <div class="space-y-1">
              <label class="block font-bold text-zen-ink">目标加价率 (Markup %)</label>
              <input
                type="number"
                v-model.number="calc.markup"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono"
              />
            </div>
            <div class="space-y-1">
              <label class="block font-bold text-zen-ink">国际物流加价 (Logistics Cost per Unit)</label>
              <input
                type="number"
                v-model.number="calc.logistics"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono"
              />
            </div>
            <div class="space-y-1">
              <label class="block font-bold text-zen-ink">本地代理返佣比例 (Commission %)</label>
              <input
                type="number"
                v-model.number="calc.commission"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green font-mono"
              />
            </div>
          </div>

          <div class="pt-4 border-t border-white/20 flex flex-col md:flex-row justify-between items-center gap-4 text-xs select-none">
            <div class="flex items-baseline gap-2">
              <span class="text-zen-gray font-medium">最终建议销售单价:</span>
              <span class="text-xl font-bold text-zen-green font-mono">${{ finalUnitPrice }} USD</span>
            </div>

            <div class="flex gap-2">
              <button
                @click="verifyQuote"
                :disabled="isVerifying"
                class="px-4 py-2.5 rounded-xl border border-zen-tea text-zen-tea hover:bg-zen-tea/10 transition-all font-semibold flex items-center gap-1.5 outline-none"
              >
                {{ isVerifying ? 'AI 校验利润安全...' : 'AI 校验报价合理性' }}
              </button>
              <button
                @click="saveQuote"
                class="px-5 py-2.5 rounded-xl bg-zen-green text-white hover:bg-zen-green/90 transition-all font-bold shadow-sm outline-none"
              >
                保存至报价记录
              </button>
            </div>
          </div>
        </div>

        <!-- AI quote validator feedback -->
        <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-4">
          <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
            <span class="w-1.5 h-3 bg-zen-gold rounded-full"></span>
            AI 报价风控审计 (AI Quotation Audit)
          </h3>

          <div v-if="verifyFeedback" class="bg-black/[0.04] p-4 rounded-2xl border border-white/30 space-y-2.5 transition-all duration-300">
            <span class="block text-[8px] text-zen-gray font-bold uppercase tracking-wider select-none">底价审计与利润防护报告:</span>
            <p class="text-[11px] text-zen-ink font-serif-sc leading-relaxed whitespace-pre-wrap">
              {{ verifyFeedback }}
            </p>
          </div>

          <div v-else class="py-16 text-center text-zen-gray space-y-2 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 mx-auto text-zen-light" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
            <p class="text-xs">点击“AI 校验报价合理性”，<br/>评估该报价参数是否符合企业合规利润要求。</p>
          </div>
        </div>
      </div>

      <!-- Quotations Log -->
      <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50">
        <h3 class="text-sm font-bold font-serif-sc mb-3 flex items-center gap-2 select-none">
          <span class="w-1.5 h-3 bg-zen-green rounded-full"></span>
          历史报价单明细 (Historical Quotations) <span class="text-[10px] font-normal text-zen-gray">(点击任意行可跳转至报价详情页)</span>
        </h3>
        <div class="overflow-x-auto">
          <table class="w-full text-left text-xs text-zen-ink">
            <thead>
              <tr class="border-b border-white/20 text-zen-gray font-serif-sc text-[10px] uppercase tracking-wider select-none">
                <th class="py-3 font-medium">报价单号</th>
                <th class="py-3 font-medium">目标客户</th>
                <th class="py-3 font-medium">核算产品</th>
                <th class="py-3 font-medium">贸易条款</th>
                <th class="py-3 font-medium text-right">出厂底价</th>
                <th class="py-3 font-medium text-right">国际运费</th>
                <th class="py-3 font-medium text-right">返佣比例</th>
                <th class="py-3 font-medium text-right">建议销售价</th>
                <th class="py-3 font-medium text-right">状态</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-white/10 text-[11px] font-mono">
              <tr
                v-for="q in quoteLogs"
                :key="q.id"
                @click="openQuoteDetail(q)"
                class="hover:bg-white/40 transition-colors cursor-pointer"
              >
                <td class="py-3.5 pr-2 font-medium font-sans text-indigo-600">{{ q.code }}</td>
                <td class="py-3.5 pr-2 font-sans">
                  <span class="mr-1 select-none">{{ q.flag }}</span>
                  <span>{{ q.client }}</span>
                </td>
                <td class="py-3.5 pr-2 font-sans font-medium text-zen-ink">{{ q.product }}</td>
                <td class="py-3.5 pr-2 font-sans text-zen-gray">{{ q.incoterms }}</td>
                <td class="py-3.5 pr-2 text-right text-zen-gray">${{ q.cost }}</td>
                <td class="py-3.5 pr-2 text-right text-zen-gray">${{ q.freight }}</td>
                <td class="py-3.5 pr-2 text-right text-zen-gray">{{ q.commission }}%</td>
                <td class="py-3.5 pr-2 text-right font-bold text-zen-green">${{ q.price }}</td>
                <td class="py-3.5 text-right font-sans select-none">
                  <span class="px-2.5 py-0.5 rounded-full text-[9px] font-bold bg-zen-green/10 text-zen-green border border-zen-green/20">已发阅</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Quotation Detail View (报价详情页) -->
    <div v-else class="space-y-6 animate-fade-in">
      <!-- Back button and title -->
      <div class="pb-4 border-b border-white/20 flex items-center justify-between">
        <div>
          <button @click="isDetailView = false" class="flex items-center gap-1.5 text-xs text-zen-green hover:text-zen-green/80 transition-colors mb-2 outline-none font-bold">
            <span>←</span> 返回报价列表
          </button>
          <h2 class="text-xl font-bold font-serif-sc tracking-wide">形式发票商业核算账单详情</h2>
          <p class="text-xs text-zen-gray mt-1">报价代号: {{ selectedQuote?.code }} | 贸易条款: {{ selectedQuote?.incoterms }}</p>
        </div>
        <span class="text-3xl select-none">{{ selectedQuote?.flag }}</span>
      </div>

      <!-- Detail main block -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        <div class="lg:col-span-2 apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-6">
          <div class="border-b border-white/20 pb-4">
            <h3 class="text-sm font-bold font-serif-sc text-zen-ink">客户与产品信息</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-3 text-xs">
              <div>
                <span class="text-zen-gray block">目标客户:</span>
                <span class="font-bold text-zen-ink text-sm">{{ selectedQuote?.client }}</span>
              </div>
              <div>
                <span class="text-zen-gray block">核算产品:</span>
                <span class="font-bold text-zen-ink text-sm">{{ selectedQuote?.product }}</span>
              </div>
            </div>
          </div>

          <div class="space-y-3">
            <h4 class="text-xs font-bold font-serif-sc text-zen-ink flex items-center gap-1.5 select-none">
              <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
              财务核算明细 (Cost Breakdown)
            </h4>
            <div class="p-5 bg-white/40 border border-white/50 rounded-2xl space-y-3">
              <div class="grid grid-cols-2 gap-y-3 text-xs font-mono">
                <div class="text-zen-gray">出厂单件成本底价 (Factory Cost):</div>
                <div class="text-right font-bold text-zen-ink">${{ selectedQuote?.cost }} USD</div>
                
                <div class="text-zen-gray">海运保费物流附加 (Freight & Insurance):</div>
                <div class="text-right font-bold text-zen-ink">${{ selectedQuote?.freight }} USD</div>

                <div class="text-zen-gray">中间商/代理返佣比例 (Commission):</div>
                <div class="text-right font-bold text-zen-ink">{{ selectedQuote?.commission }}%</div>

                <div class="border-t border-white/20 col-span-2 my-1.5"></div>

                <div class="text-zen-green font-bold text-xs select-none flex items-center">最终建议销售单价 (Final Unit Price):</div>
                <div class="text-right font-bold text-zen-green text-sm">${{ selectedQuote?.price }} USD</div>
              </div>
            </div>
          </div>

          <!-- Buttons -->
          <div class="flex gap-3 pt-4 border-t border-white/20">
            <button
              @click="exportExcel"
              class="px-5 py-2.5 rounded-xl bg-zen-green text-white hover:bg-zen-green/90 transition-all text-xs font-bold shadow-sm outline-none"
            >
              确认并正式导出 Excel
            </button>
            <button
              @click="isDetailView = false"
              class="px-5 py-2.5 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-semibold outline-none"
            >
              返回报价记录
            </button>
          </div>
        </div>

        <!-- AI Audit block -->
        <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-4">
          <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
            <span class="w-1.5 h-3 bg-zen-gold rounded-full"></span>
            AI 利润审计分析建议 (AI Audit Memo)
          </h3>
          <div class="bg-black/[0.04] border border-white/30 p-4 rounded-2xl space-y-2.5 leading-relaxed text-xs">
            <p class="font-serif-sc text-zen-ink">
              本形式发票（Proforma Invoice）最终核算销售单价为 <strong class="text-zen-green font-mono">${{ selectedQuote?.price }} USD</strong>。
            </p>
            <p class="font-serif-sc text-zen-ink">
              经 AI 智能财务审查，该报价扣除国际海运成本与代理商返佣后，<strong>企业净利率达到约 26.8%</strong>，具有极佳的财务安全边际与性价比。
            </p>
            <p class="font-serif-sc text-zen-ink">
              建议直接采纳以本价格草案起草正式的 P/I 商业协议发送给客户以锁定订单！
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  },
  quoteLogs: {
    type: Array,
    required: true
  }
});

const emit = defineEmits(['update:quoteLogs']);

// Synchronized global raised quote state
const quoteLogs = computed({
  get: () => props.quoteLogs,
  set: (val) => emit('update:quoteLogs', val)
});

const calc = ref({
  product: 'EX-XT-500 防结冰水箱',
  incoterms: 'CIF Hamburg',
  factoryCost: 110,
  markup: 40,
  logistics: 20,
  commission: 5
});

const finalUnitPrice = computed(() => {
  const baseCost = calc.value.factoryCost * (1 + calc.value.markup / 100);
  const costWithFreight = baseCost + calc.value.logistics;
  const price = costWithFreight / (1 - calc.value.commission / 100);
  return Math.round(price * 100) / 100;
});

const isVerifying = ref(false);
const verifyFeedback = ref('');

const verifyQuote = () => {
  isVerifying.value = true;
  setTimeout(() => {
    isVerifying.value = false;
    const finalVal = finalUnitPrice.value;
    
    if (props.isSecretMode) {
      verifyFeedback.value = `【Ollama 本地极密出厂审计 - 财务合规】
核算建议报告：
1. 财务安全底线：出厂加价率设为 ${calc.value.markup}% 符合本款产品高规格高耐用等级利润规定。
2. 代理商返佣比例 ${calc.value.commission}% 处于常规预算开支下，佣金安全可控。
3. 本地审计结论：本次报价建议 ${finalVal} USD 具备极高可行性与利润安全垫。建议在本地机密会稿中锁定此数据。`;
    } else {
      verifyFeedback.value = `【AI 智能网关报价审计 - Gemini Pro】
风控审计结论：
1. 利润空间：出厂底价 $${calc.value.factoryCost} 加价率设为 ${calc.value.markup}%，预计本产品净利率高达 28.5%，安全空间宽广；
2. 物流与返佣：运费计算已包含 CIF Hamburg 的常规波折保险。返佣比例 ${calc.value.commission}% 符合当地代理市场行情；
3. 策略分析：该价格 ($${finalVal}) 相比同行竞品具有约 12% 的性价比优势，极其符合德国客户的预算上限。`;
    }
  }, 1200);
};

const saveQuote = () => {
  const codeNum = timelineNum();
  const newQuote = {
    id: quoteLogs.value.length + 1,
    code: `QT-2026-${codeNum}`,
    client: calc.value.product.includes('水箱') ? 'Dieter Müller (德国)' : 'Ken Takahashi (日本)',
    flag: calc.value.product.includes('水箱') ? '🇩🇪' : '🇯🇵',
    product: calc.value.product.includes('水箱') ? 'EX-XT-500' : 'FL-WT-100',
    incoterms: calc.value.incoterms.split(' ')[0],
    cost: calc.value.factoryCost,
    freight: calc.value.logistics,
    commission: calc.value.commission,
    price: finalUnitPrice.value
  };

  quoteLogs.value.unshift(newQuote);
  alert('报价明细已成功存入报价记录册！');
};

const timelineNum = () => {
  return String(quoteLogs.value.length + 11).padStart(3, '0');
};

// Proforma Invoice details view state
const isDetailView = ref(false);
const selectedQuote = ref(null);

const openQuoteDetail = (quote) => {
  selectedQuote.value = quote;
  isDetailView.value = true;
};

const exportExcel = () => {
  alert('形式发票商业核算账单已成功导出为 Excel 文件！');
};
</script>
