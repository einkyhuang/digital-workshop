<template>
  <div class="space-y-6 font-sans text-zen-ink">
    <!-- Header -->
    <div class="pb-4 border-b border-zen-light/30">
      <h2 class="text-xl font-semibold font-serif-sc tracking-wide">客户跟进记录 (Follow-up Logs)</h2>
      <p class="text-xs text-zen-gray mt-1">记录与客户的历次沟通要点，并使用 AI 对口头记录进行高度专业化润色。</p>
    </div>

    <!-- 1. Statistics Header (顶部新增可视化统计报表) -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-5 select-none animate-fadeIn">
      <!-- Card 1: 客户大盘 -->
      <div class="apple-glass rounded-2xl p-5 border border-white/50 shadow-sm flex flex-col justify-between">
        <div>
          <span class="block text-[10px] text-zen-gray font-semibold uppercase tracking-wider">客户大盘概览</span>
          <span class="text-xl font-bold block mt-2 text-zen-ink">{{ leads.length }} 家客商</span>
        </div>
        <p class="text-[9px] text-zen-gray mt-2 leading-relaxed">覆盖全局数据库中 {{ new Set(leads.map(l => l.country)).size }} 个国家与地区的驻地渠道。</p>
      </div>

      <!-- Card 2: 成交率 -->
      <div class="apple-glass rounded-2xl p-5 border border-white/50 shadow-sm flex flex-col justify-between">
        <div>
          <span class="block text-[10px] text-zen-gray font-semibold uppercase tracking-wider">开发成交状态</span>
          <div class="flex items-baseline gap-2 mt-2">
            <span class="text-xl font-bold text-zen-green">{{ leads.filter(l => l.stage === 'deal').length }} 成交</span>
            <span class="text-xs text-zen-gray">/ {{ leads.filter(l => l.stage !== 'deal').length }} 跟进中</span>
          </div>
        </div>
        <p class="text-[9px] text-zen-gray mt-2 leading-relaxed">当前总体赢单率：{{ Math.round((leads.filter(l => l.stage === 'deal').length / leads.length) * 100) }}%</p>
      </div>

      <!-- Card 3: 开发进展 -->
      <div class="apple-glass rounded-2xl p-5 border border-white/50 shadow-sm flex flex-col justify-between">
        <div>
          <span class="block text-[10px] text-zen-gray font-semibold uppercase tracking-wider">沟通进展记录</span>
          <span class="text-xl font-bold block mt-2 text-zen-ink">{{ timelineLogs.length }} 条跟进</span>
        </div>
        <p class="text-[9px] text-zen-gray mt-2 leading-relaxed">AI 智能分析网关安全防护运行中 🔒</p>
      </div>

      <!-- Card 4: 具体商机 -->
      <div class="apple-glass rounded-2xl p-4 border border-white/50 shadow-sm flex flex-col justify-between">
        <span class="block text-[10px] text-zen-gray font-semibold uppercase tracking-wider mb-1.5">活跃具体商机 (点击跳转)</span>
        <div class="space-y-1.5 overflow-y-auto max-h-[70px] pr-1 scrollbar-thin">
          <div
            v-for="deal in deals"
            :key="deal.id"
            @click="jumpToDeal(deal.id)"
            class="text-[9px] bg-white/40 hover:bg-white hover:border-zen-green border border-white/40 px-2 py-1 rounded flex justify-between items-center cursor-pointer transition-all duration-300 shadow-sm hover:translate-x-0.5"
            :title="'点击立即跳转查看该商机 AI 推进建议'"
          >
            <span class="truncate font-semibold max-w-[90px] text-indigo-700">{{ deal.title }}</span>
            <strong class="font-mono text-zen-green text-[8px] shrink-0">{{ deal.amount }}</strong>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick follow-up form -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-4">
      <h3 class="text-sm font-semibold font-serif-sc text-zen-ink flex items-center gap-2">
        <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
        录入新沟通纪要 (New Follow-up Note)
      </h3>
      <div class="space-y-3">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="block text-[10px] font-semibold text-zen-ink mb-1">选定客户</label>
            <select
              v-model="newLog.client"
              class="w-full bg-zen-paper border border-zen-light/60 rounded-lg px-3 py-2 text-xs outline-none focus:border-zen-green"
            >
              <option v-for="l in leads" :key="l.id" :value="l.name + ' (' + l.country + ')'">
                {{ l.name }} ({{ l.country }}) {{ l.flag }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-[10px] font-semibold text-zen-ink mb-1">跟进渠道</label>
            <select
              v-model="newLog.channel"
              class="w-full bg-zen-paper border border-zen-light/60 rounded-lg px-3 py-2 text-xs outline-none focus:border-zen-green"
            >
              <option value="电子邮件 (Email)">电子邮件 (Email)</option>
              <option value="WhatsApp / 微信">WhatsApp / 微信</option>
              <option value="地面拜访 (Ground Visit)">地面拜访 (Ground Visit)</option>
              <option value="电话会议 (Call)">电话会议 (Call)</option>
            </select>
          </div>
          <div>
            <label class="block text-[10px] font-semibold text-zen-ink mb-1">沟通分类</label>
            <select
              v-model="newLog.type"
              class="w-full bg-zen-paper border border-zen-light/60 rounded-lg px-3 py-2 text-xs outline-none focus:border-zen-green"
            >
              <option value="需求确认">需求确认</option>
              <option value="报价回馈">报价回馈</option>
              <option value="样品跟进">样品跟进</option>
              <option value="合同修改">合同修改</option>
            </select>
          </div>
        </div>

        <div>
          <label class="block text-[10px] font-semibold text-zen-ink mb-1">简略纪要速记 (草稿笔记)</label>
          <textarea
            rows="3"
            v-model="newLog.draft"
            placeholder="在此输入随手记下的要点，例如：德国Müller对防冻满意，但卡在运费，预算紧，问能不能打折..."
            class="w-full bg-zen-paper border border-zen-light/60 rounded-lg px-3 py-2 text-xs outline-none focus:border-zen-green"
          ></textarea>
        </div>

        <div class="flex justify-end gap-3 pt-2">
          <!-- AI polish button -->
          <button
            @click="polishNote"
            :disabled="isPolishing"
            class="px-4 py-2 rounded-lg border border-zen-tea text-zen-tea hover:bg-zen-tea/10 transition-all font-semibold text-xs flex items-center gap-1.5 outline-none"
          >
            <span class="relative flex h-2 w-2" v-if="isPolishing">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-tea opacity-75"></span>
              <span class="relative inline-flex rounded-full h-2 w-2 bg-zen-tea"></span>
            </span>
            {{ isPolishing ? 'AI 正在提炼润色...' : 'AI 智能润色纪要' }}
          </button>
          <button
            @click="addFollowUp"
            class="px-5 py-2 rounded-lg bg-zen-green text-white hover:bg-zen-green/90 transition-all font-semibold text-xs outline-none shadow-sm"
          >
            保存记录
          </button>
        </div>
      </div>
    </div>

    <!-- Timeline of logs -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-6">
      <div class="flex justify-between items-center">
        <h3 class="text-sm font-semibold font-serif-sc text-zen-ink flex items-center gap-2">
          <span class="w-1.5 h-3 bg-zen-green rounded-full"></span>
          历史跟进与未来待办时间线 (Timeline & Tasks)
        </h3>
        <span class="text-[9px] bg-yellow-500/10 text-yellow-600 border border-yellow-500/20 px-2 py-0.5 rounded-full font-bold select-none flex items-center gap-1">
          ⏰ 待办提醒：本周 2 个需回访客商
        </span>
      </div>

      <div class="relative pl-6 border-l border-white/30 space-y-6">
        <div v-for="log in timelineLogs" :key="log.id" class="relative group">
          <!-- Chronological circle -->
          <span class="absolute -left-[30px] top-1.5 w-3.5 h-3.5 rounded-full bg-white border-2 border-zen-tea flex items-center justify-center">
            <span class="w-1.5 h-1.5 rounded-full bg-zen-tea"></span>
          </span>

          <div class="bg-white/40 group-hover:bg-white/60 p-4 rounded-2xl border border-white/50 transition-all duration-300 shadow-sm space-y-2">
            <!-- Timeline Item Header -->
            <div class="flex justify-between items-start flex-wrap gap-2 text-xs">
              <div class="flex items-center gap-2">
                <span class="font-bold text-zen-ink">{{ log.client }}</span>
                <span class="text-[10px] text-zen-gray px-2 py-0.5 rounded-full bg-white/60 border border-white/50">{{ log.channel }}</span>
                <!-- Jump button to go to the customer detail workspace page -->
                <button
                  v-if="getLeadIdForLog(log)"
                  @click="jumpToCustomerDetail(log)"
                  class="px-2 py-0.5 rounded-lg border border-zen-tea/30 hover:border-zen-tea bg-white/50 text-[9px] text-zen-tea font-bold shadow-sm transition-all duration-300 hover:translate-x-0.5 flex items-center gap-0.5 select-none"
                  title="一键穿透跳转至该客商全屏立体画像工作台"
                >
                  🔍 穿透画像
                </button>
              </div>
              <span class="text-[10px] text-zen-gray font-mono">{{ log.date }}</span>
            </div>

            <!-- Content -->
            <p class="text-xs text-zen-ink font-serif-sc leading-relaxed whitespace-pre-wrap select-text">
              {{ log.content }}
            </p>

            <!-- Metadata tags -->
            <div class="flex justify-between items-center pt-2 border-t border-zen-light/20 text-[9px] text-zen-gray select-none">
              <span class="font-medium text-zen-green">跟进分类: {{ log.type }}</span>
              <span class="font-mono">已启用本地算力校对</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  },
  timelineLogs: {
    type: Array,
    required: true
  },
  leads: {
    type: Array,
    required: true
  },
  deals: {
    type: Array,
    required: true
  }
});

const emit = defineEmits(['update:timelineLogs', 'go-to-tab']);

// Synchronized raised timelineLogs database state
const timelineLogs = computed({
  get: () => props.timelineLogs,
  set: (val) => emit('update:timelineLogs', val)
});

const newLog = ref({
  client: '',
  channel: '电子邮件 (Email)',
  type: '需求确认',
  draft: ''
});

onMounted(() => {
  if (props.leads && props.leads.length > 0) {
    newLog.value.client = props.leads[0].name + ' (' + props.leads[0].country + ')';
  }
});

const isPolishing = ref(false);

const getLeadIdForLog = (log) => {
  if (!props.leads) return null;
  const found = props.leads.find(l => log.client.includes(l.name));
  return found ? found.id : null;
};

const jumpToCustomerDetail = (log) => {
  const leadId = getLeadIdForLog(log);
  if (leadId) {
    emit('go-to-tab', 'customers', { customerId: leadId });
  } else {
    alert('未找到对应的客户档案，请先在客户公海建档！');
  }
};

const jumpToDeal = (dealId) => {
  emit('go-to-tab', 'opportunities', { opportunityId: dealId });
};

const polishNote = () => {
  if (!newLog.value.draft) {
    alert('请先输入简要跟进速记！');
    return;
  }
  isPolishing.value = true;
  setTimeout(() => {
    isPolishing.value = false;
    const rawNote = newLog.value.draft;
    
    // AI polishing templates
    let polishedText = '';
    if (props.isSecretMode) {
      polishedText = `【本地 Llama 3 极密润色纪要 - 离线安全】\n沟通纪要总结如下：\n与客户展开了关于产品各项机密细节的交流。已对客户重点关切的底价核算明细、起订量弹性折扣进行了安全评估。鉴于商业高密保护机制，已向其说明财务核算的严谨性。客户对防腐规格表示认可，同意在保证信息物理绝密的前提下推进下一步合同文本校审流程。`;
    } else {
      polishedText = `【AI 智能网关润色纪要 - Gemini 路由】\n与该客户进行了深入 touchpoint 沟通。详细对答记录如下：\n1. 客户对我们提供的产品参数细节表示出强烈兴趣，尤其就定制尺寸和材料资质认证（TUV/CE/FDA）展开确认；\n2. 价格商务谈判点：客户反馈预算空间有限，期望提供灵活阶梯折扣或承担部分港口运费；\n3. 下步动作建议：\n   - 下周内起草符合西方商务合规的正式中英文版双向开发协议信函并及时发出，协助代理商地面推进。`;
    }

    newLog.value.draft = polishedText;
  }, 1200);
};

const addFollowUp = () => {
  if (!newLog.value.draft) {
    alert('请填写跟进纪要内容！');
    return;
  }
  
  const now = new Date();
  const formatTime = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

  const logEntry = {
    id: timelineLogs.value.length + 1,
    client: newLog.value.client,
    date: formatTime,
    channel: newLog.value.channel,
    type: newLog.value.type,
    content: newLog.value.draft
  };

  // Reassign through the computed setter so the parent ref updates and persists
  timelineLogs.value = [logEntry, ...timelineLogs.value];
  newLog.value.draft = '';
  if (window.magichubPersistNow) window.magichubPersistNow();
  alert('跟进记录已成功存盘！');
};
</script>
