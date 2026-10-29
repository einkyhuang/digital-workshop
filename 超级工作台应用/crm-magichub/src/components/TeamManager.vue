<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10 select-text">
    <!-- Header -->
    <div class="pb-4 border-b border-white/20 select-none flex justify-between items-center">
      <div>
        <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2">
          <span class="w-8 h-8 rounded-xl bg-zen-ink text-white flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          </span>
          智能团队与 AI 赋能中心 (Team &amp; Agent Center)
        </h2>
        <p class="text-xs text-zen-gray mt-1">查看外贸团队与 AI 智能体配置，像 Open Claw 一样为业务员和 AI 分配专属技能、进行调校与高密定义。</p>
      </div>
    </div>

    <!-- Statistics Summary Panel -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 select-none">
      <div class="apple-glass rounded-2xl p-5 border border-white/50 shadow-sm flex flex-col justify-between">
        <span class="block text-[10px] uppercase tracking-wider text-zen-gray font-bold">团队总编制</span>
        <span class="text-2xl font-bold block mt-2">{{ teamMembers.length }} 位成员</span>
        <p class="text-xs text-zen-gray mt-1">含 {{ teamMembers.filter(m => m.isAi).length }} 位 AI Agent / {{ teamMembers.filter(m => !m.isAi).length }} 位人类业务代表</p>
      </div>
      <div class="apple-glass rounded-2xl p-5 border border-white/50 shadow-sm flex flex-col justify-between">
        <span class="block text-[10px] uppercase tracking-wider text-zen-gray font-bold">总技能分配数</span>
        <span class="text-2xl font-bold block mt-2 text-zen-green">{{ totalAssignedSkills }} 个赋能技能</span>
        <p class="text-xs text-zen-gray mt-1">已激活：市场背调、法务合规、多语言润色...</p>
      </div>
      <div class="apple-glass rounded-2xl p-5 border border-white/50 shadow-sm flex flex-col justify-between">
        <span class="block text-[10px] uppercase tracking-wider text-zen-gray font-bold">AI 智能网关状态</span>
        <span class="text-2xl font-bold block mt-2 text-indigo-700">Open Claw Sync 🔒</span>
        <p class="text-xs text-zen-gray mt-1">ChromaDB 本地向量仓与提示词指令底盘同步正常</p>
      </div>
    </div>

    <!-- Team Grid (full width, 3 col) -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
      <div
        v-for="member in teamMembers"
        :key="member.id"
        @click="openMemberModal(member)"
        class="apple-glass rounded-[24px] p-6 border flex flex-col justify-between min-h-[200px] cursor-pointer hover:shadow-xl hover:translate-y-[-2px] transition-all duration-300 relative group border-white/50 hover:bg-white/70"
      >
        <!-- Top Row -->
        <div>
          <div class="flex justify-between items-start">
            <div class="flex items-center gap-3">
              <span class="text-3xl select-none w-12 h-12 rounded-2xl bg-black/[0.03] flex items-center justify-center">
                {{ member.emoji }}
              </span>
              <div>
                <h4 class="text-sm font-bold leading-tight flex items-center gap-1.5">
                  {{ member.name }}
                  <span
                    class="px-2 py-0.5 rounded-full text-[9px] font-bold uppercase select-none shrink-0"
                    :class="member.isAi ? 'bg-indigo-50 text-indigo-600 border border-indigo-200' : 'bg-zen-green/10 text-zen-green border border-zen-green/20'"
                  >
                    {{ member.isAi ? 'AI Agent' : 'Human' }}
                  </span>
                </h4>
                <p class="text-xs text-zen-gray mt-0.5">{{ member.role }}</p>
              </div>
            </div>
            <!-- Arrow hint -->
            <span class="opacity-0 group-hover:opacity-100 transition-opacity text-zen-gray text-xs">⚙️</span>
          </div>

          <!-- Desc -->
          <p class="text-xs text-zen-gray leading-relaxed font-serif-sc mt-4 line-clamp-2 select-text">
            {{ member.desc }}
          </p>
        </div>

        <!-- Skills & Model Info -->
        <div class="pt-4 border-t border-white/20 mt-4 select-none flex justify-between items-center text-[10px]">
          <div class="flex flex-wrap gap-1 max-w-[70%]">
            <span
              v-for="sk in member.skills"
              :key="sk"
              class="px-1.5 py-0.5 rounded bg-black/[0.04] text-zen-gray border border-black/[0.03] text-[9px] tracking-tight uppercase"
            >
              {{ getSkillLabel(sk) }}
            </span>
            <span v-if="!member.skills.length" class="text-zen-gray italic text-[9px]">暂未赋予技能</span>
          </div>
          <span class="font-mono text-zen-gray shrink-0 font-bold text-[10px]" v-if="member.isAi">⚙️ {{ member.model }}</span>
          <span class="text-zen-green font-bold shrink-0 text-[10px]" v-else>🟢 驻地活跃</span>
        </div>

        <!-- Click hint -->
        <div class="absolute bottom-3 right-4 opacity-0 group-hover:opacity-100 transition-opacity text-[9px] text-zen-gray font-semibold select-none">
          点击赋能配置 →
        </div>
      </div>
    </div>

    <!-- Open Claw Modal Overlay -->
    <transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div v-if="showModal && selectedMember" class="fixed inset-0 z-50 flex items-center justify-center p-6" @click.self="showModal = false">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-zen-ink/20 backdrop-blur-sm"></div>

        <!-- Modal Card -->
        <div class="relative w-full max-w-lg apple-glass rounded-[28px] p-7 border border-white/50 shadow-2xl z-10 max-h-[90vh] overflow-y-auto">
          <!-- Header -->
          <div class="flex items-center justify-between pb-4 border-b border-white/20 mb-5 select-none">
            <div class="flex items-center gap-3">
              <span class="text-2xl">{{ selectedMember.emoji }}</span>
              <div>
                <h3 class="text-base font-bold font-serif-sc text-zen-ink flex items-center gap-2">
                  Open Claw 赋能台
                  <span class="text-[10px] font-normal text-zen-gray font-mono bg-black/[0.04] px-2 py-0.5 rounded-lg">{{ selectedMember.isAi ? 'AI Agent' : 'Human' }}</span>
                </h3>
                <p class="text-xs text-zen-gray mt-0.5">{{ selectedMember.name }} · {{ selectedMember.role }}</p>
              </div>
            </div>
            <button @click="showModal = false" class="w-8 h-8 rounded-xl bg-black/[0.04] hover:bg-black/[0.08] flex items-center justify-center text-zen-gray hover:text-zen-ink transition-all outline-none">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
            </button>
          </div>

          <!-- Form Fields -->
          <div class="space-y-4 text-sm font-sans" v-if="editForm">
            <!-- Name & Emoji -->
            <div class="grid grid-cols-3 gap-3">
              <div class="col-span-2 space-y-1">
                <label class="block text-xs text-zen-gray font-bold">成员代号 *</label>
                <input type="text" v-model="editForm.name"
                  class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-sm outline-none focus:bg-white focus:border-zen-green transition-all" />
              </div>
              <div class="col-span-1 space-y-1">
                <label class="block text-xs text-zen-gray font-bold">头像 Emoji</label>
                <input type="text" v-model="editForm.emoji"
                  class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-sm text-center outline-none focus:bg-white focus:border-zen-green transition-all" />
              </div>
            </div>

            <!-- Role -->
            <div class="space-y-1">
              <label class="block text-xs text-zen-gray font-bold">职责概要</label>
              <input type="text" v-model="editForm.role"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-sm outline-none focus:bg-white focus:border-zen-green transition-all" />
            </div>

            <!-- Skills -->
            <div class="space-y-2">
              <label class="block text-xs text-zen-gray font-bold">专业技能赋予 (Skills)</label>
              <div class="p-3 bg-white/30 border border-white/50 rounded-2xl space-y-2">
                <label v-for="sk in availableSkills" :key="sk.value"
                  class="flex items-center gap-2 cursor-pointer text-xs select-none hover:text-zen-ink text-zen-gray">
                  <input type="checkbox" :value="sk.value" v-model="editForm.skills"
                    class="rounded text-zen-green focus:ring-zen-green" />
                  <span>{{ sk.label }} <strong class="text-[10px] font-mono opacity-70">({{ sk.desc }})</strong></span>
                </label>
              </div>
            </div>

            <!-- AI Tuning -->
            <div class="space-y-3 pt-3 border-t border-white/10" v-if="selectedMember.isAi">
              <span class="block text-[10px] uppercase tracking-wider text-zen-gray font-bold select-none">AI Agent 大模型调校参数</span>
              <div class="space-y-1">
                <label class="block text-xs text-zen-gray font-bold">后端算力引擎</label>
                <select v-model="editForm.model"
                  class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-sm outline-none focus:bg-white focus:border-zen-green transition-all">
                  <option value="Gemini 1.5 Pro">Gemini 1.5 Pro (云端高级)</option>
                  <option value="DeepSeek V3">DeepSeek V3 (高速开发信)</option>
                  <option value="Llama 3 (Offline)">Llama 3 (本地物理隔离/断网模式)</option>
                </select>
              </div>
              <div class="space-y-1">
                <div class="flex justify-between text-xs text-zen-gray font-bold">
                  <span>创新灵动度 (Temperature)</span>
                  <span class="font-mono">{{ editForm.temperature }}</span>
                </div>
                <input type="range" min="0" max="1" step="0.1" v-model.number="editForm.temperature"
                  class="w-full h-1 bg-black/5 rounded-lg appearance-none cursor-pointer accent-zen-green" />
              </div>
              <div class="space-y-1">
                <label class="block text-xs text-zen-gray font-bold">大模型提示词指令 (System Instruction)</label>
                <textarea v-model="editForm.instruction" rows="4"
                  class="w-full bg-white/40 border border-white/50 rounded-xl p-3 text-xs font-mono leading-normal outline-none focus:bg-white focus:border-zen-green transition-all"
                  placeholder="请输入用于定义该 Agent 核心行为的 System Instruction..."></textarea>
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="pt-5 border-t border-white/20 mt-5 flex justify-end gap-3 select-none">
            <button @click="showModal = false"
              class="px-5 py-2 rounded-xl border border-white/50 bg-white/40 hover:bg-white text-zen-gray text-sm font-semibold transition-all outline-none">
              取消
            </button>
            <button @click="saveMemberChanges"
              class="px-6 py-2 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-sm font-bold shadow-sm transition-all outline-none">
              更新并重载 Agent
            </button>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

const props = defineProps({
  teamMembers: {
    type: Array,
    required: true
  },
  importedSkills: {
    type: Array,
    required: true
  }
});

const emit = defineEmits(['update:teamMembers']);

const selectedMember = ref(null);
const editForm = ref(null);
const showModal = ref(false);

const getSkillLabel = (sk) => {
  const match = props.importedSkills.find(s => s.value === sk);
  if (match) {
    // Return a short, compact title for tags rendering
    return match.label.length > 5 ? match.label.substring(0, 4) + '..' : match.label;
  }
  return sk;
};

const availableSkills = computed(() => {
  return props.importedSkills;
});

const totalAssignedSkills = computed(() => {
  return props.teamMembers.reduce((sum, m) => sum + (m.skills?.length || 0), 0);
});

const openMemberModal = (member) => {
  selectedMember.value = member;
  editForm.value = JSON.parse(JSON.stringify(member));
  showModal.value = true;
};

const saveMemberChanges = () => {
  const index = props.teamMembers.findIndex(m => m.id === selectedMember.value.id);
  if (index !== -1) {
    const updatedList = [...props.teamMembers];
    updatedList[index] = { ...editForm.value };
    emit('update:teamMembers', updatedList);
    selectedMember.value = updatedList[index];
    showModal.value = false;
    alert(`「Open Claw 数据就绪」：已成功对团队成员 [${editForm.value.name}] 进行了重新赋能，并对它的 RAG 技能及 System Instruction 进行了全新写入存盘！`);
  }
};

watch(() => props.teamMembers, (newVal) => {
  if (selectedMember.value) {
    const found = newVal.find(m => m.id === selectedMember.value.id);
    if (found) selectedMember.value = found;
  }
}, { deep: true });
</script>
