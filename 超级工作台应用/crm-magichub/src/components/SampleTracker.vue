<template>
  <div class="space-y-6 font-sans text-zen-ink">
    <!-- Header -->
    <div class="pb-4 border-b border-zen-light/30">
      <h2 class="text-xl font-semibold font-serif-sc tracking-wide">寄样与测试测试跟进 (Sample Tracker)</h2>
      <p class="text-xs text-zen-gray mt-1">精细管理向海外客户寄送的样品进度、跟踪物流状态并智能收集测试反馈。</p>
    </div>

    <!-- Active Samples Table -->
    <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50">
      <h3 class="text-sm font-semibold font-serif-sc mb-4 flex items-center gap-2">
        <span class="w-1.5 h-3 bg-zen-green rounded-full"></span>
        寄样状态管理明细
      </h3>
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs text-zen-ink">
          <thead>
            <tr class="border-b border-zen-light/40 text-zen-gray font-serif-sc text-[10px] uppercase tracking-wider">
              <th class="py-3 font-medium">样品批次</th>
              <th class="py-3 font-medium">客户名</th>
              <th class="py-3 font-medium">寄送产品</th>
              <th class="py-3 font-medium">发出日期</th>
              <th class="py-3 font-medium">国际快递单号</th>
              <th class="py-3 font-medium">状态</th>
              <th class="py-3 font-medium text-center">测试反馈</th>
              <th class="py-3 font-medium text-right">操作</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zen-light/20 text-[11px]">
            <tr v-for="sample in samples" :key="sample.id" class="hover:bg-zen-paper/20 transition-colors">
              <td class="py-3.5 pr-2 font-mono font-medium">{{ sample.batch }}</td>
              <td class="py-3.5 pr-2">
                <span class="mr-1">{{ sample.flag }}</span>
                <span>{{ sample.client }}</span>
              </td>
              <td class="py-3.5 pr-2 font-medium">{{ sample.product }}</td>
              <td class="py-3.5 pr-2 text-zen-gray font-mono">{{ sample.date }}</td>
              <td class="py-3.5 pr-2 font-mono text-zen-gray">{{ sample.tracking }}</td>
              <td class="py-3.5 pr-2">
                <span
                  class="px-2 py-0.5 rounded text-[9px] font-semibold"
                  :class="sample.status === '已妥投' ? 'bg-zen-green/10 text-zen-green' : (sample.status === '运送中' ? 'bg-zen-tea/15 text-zen-tea' : 'bg-zen-light text-zen-gray')"
                >
                  {{ sample.status }}
                </span>
              </td>
              <td class="py-3.5 text-center">
                <span class="font-medium text-zen-green" v-if="sample.feedback">
                  {{ sample.feedback }}
                </span>
                <span class="text-zen-gray italic" v-else>暂无反馈</span>
              </td>
              <td class="py-3.5 text-right select-none">
                <button
                  @click="openFollowupDraft(sample)"
                  class="text-zen-green hover:text-zen-ink font-semibold text-[10px]"
                >
                  起草跟进信 ➡️
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- AI Follow-up draft ZenModal -->
    <ZenModal :open="draftModalOpen" :title="'样品反馈 AI 关怀信起草 | ' + (selectedSample?.client || '')" @close="draftModalOpen = false">
      <div class="space-y-4 text-xs" v-if="selectedSample">
        <div class="flex justify-between items-center pb-2.5 border-b border-zen-light/35">
          <div>
            <p class="font-semibold text-zen-ink font-serif-sc">产品: {{ selectedSample.product }}</p>
            <p class="text-[10px] text-zen-gray">物流状态: {{ selectedSample.status }} ({{ selectedSample.tracking }})</p>
          </div>
        </div>

        <div class="bg-zen-paper/60 p-4 rounded-xl border border-zen-light/30 space-y-2">
          <div class="flex justify-between text-[8px] text-zen-gray font-semibold uppercase">
            <span>邮件预览 (Subject: Feedback on {{ selectedSample.product }} samples)</span>
            <span class="text-zen-tea">Gemini Route</span>
          </div>
          <p class="text-[11px] text-zen-ink leading-relaxed font-serif-sc whitespace-pre-wrap select-all">
            {{ emailDraft }}
          </p>
        </div>
      </div>
      <template #footer>
        <button
          @click="copyDraft"
          class="px-5 py-2 rounded-lg bg-zen-ink text-white text-xs hover:bg-zen-ink/90 transition-all font-semibold shadow-sm flex items-center justify-center gap-1.5"
        >
          {{ copySuccess ? '复制成功！' : '复制邮件文本' }}
        </button>
        <button
          @click="draftModalOpen = false"
          class="px-5 py-2 rounded-lg border border-zen-light text-zen-gray text-xs hover:text-zen-ink hover:bg-zen-light/20 transition-all font-medium"
        >
          返回
        </button>
      </template>
    </ZenModal>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import ZenModal from './ZenModal.vue';

const props = defineProps({
  samples: {
    type: Array,
    default: () => []
  }
});

const emit = defineEmits(['update:samples']);

const samples = computed({
  get: () => props.samples,
  set: (val) => emit('update:samples', val)
});

const draftModalOpen = ref(false);
const selectedSample = ref(null);
const emailDraft = ref('');
const copySuccess = ref(false);

const openFollowupDraft = (sample) => {
  selectedSample.value = sample;
  emailDraft.value = `Dear ${sample.client.split(' ')[0]},\n\nI hope this email finds you well.\n\nI am writing to follow up on the samples of ${sample.product} shipped under tracking number ${sample.tracking}.\n\nAccording to our records, the shipment status is currently "${sample.status}". We would be deeply appreciative if your technical team could share the test feedback, especially regarding material durability and seal compliance under your outdoor simulations. Please let us know if we can offer further guidance.\n\nWarm regards,\nSales Representative\nMagicHub Intelligent System`;
  draftModalOpen.value = false;
  setTimeout(() => {
    draftModalOpen.value = true;
  }, 50);
};

const copyDraft = () => {
  navigator.clipboard.writeText(emailDraft.value).then(() => {
    copySuccess.value = true;
    setTimeout(() => {
      copySuccess.value = false;
    }, 2000);
  });
};
</script>
