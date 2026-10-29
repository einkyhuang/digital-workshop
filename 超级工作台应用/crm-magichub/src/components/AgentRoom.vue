<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10">
    <!-- Header -->
    <div class="apple-glass rounded-2xl p-6 relative overflow-hidden">
      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h2 class="text-lg font-bold font-serif-sc tracking-wider text-zen-ink flex items-center gap-2">
            🤝 多 Agent 协同工作室
          </h2>
          <p class="text-[11px] text-zen-gray mt-1 font-serif-sc">
            把团队里的 AI 角色拉进同一个对话，围绕一个任务多视角协同。每个 Agent 都用自己的人设、技能和模型偏好回应。
          </p>
        </div>
        <button
          @click="openCreateRoomModal"
          class="px-4 py-2 bg-zen-ink text-white rounded-xl text-xs font-bold shadow-sm hover:bg-zen-ink/90 transition-all active:scale-[0.97] outline-none"
        >
          ＋ 新建协同对话
        </button>
      </div>
    </div>

    <!-- Two-column workspace -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
      <!-- Left: Room list -->
      <aside class="lg:col-span-3 apple-glass rounded-2xl p-4 border border-white/50 space-y-3 self-start">
        <h3 class="text-[10px] font-bold uppercase tracking-wider text-zen-gray select-none">协同对话列表</h3>
        <div class="space-y-1.5 max-h-[640px] overflow-y-auto pr-1">
          <button
            v-for="room in rooms"
            :key="room.id"
            @click="activeRoomId = room.id"
            class="w-full text-left px-3 py-2.5 rounded-xl border transition-all duration-200 outline-none group"
            :class="activeRoomId === room.id
              ? 'bg-white border-white/80 shadow-sm'
              : 'bg-white/30 border-white/40 hover:bg-white/60'"
          >
            <div class="flex justify-between items-center">
              <span class="text-xs font-bold text-zen-ink truncate">{{ room.name }}</span>
              <button
                v-if="rooms.length > 1"
                @click.stop="deleteRoom(room.id)"
                class="opacity-0 group-hover:opacity-100 text-[10px] text-zen-gray hover:text-zen-crimson"
                title="删除"
              >✕</button>
            </div>
            <div class="flex items-center gap-1 mt-1.5">
              <span v-for="m in roomMembers(room).slice(0, 4)" :key="m.id" class="text-[10px]">{{ m.emoji || '🤖' }}</span>
              <span v-if="roomMembers(room).length > 4" class="text-[9px] text-zen-gray">+{{ roomMembers(room).length - 4 }}</span>
              <span class="ml-auto text-[8px] text-zen-gray font-mono">{{ (room.messages || []).length }}条</span>
            </div>
          </button>
          <div v-if="!rooms.length" class="py-8 text-center text-[10px] text-zen-gray/60 italic">
            暂无对话，点上方"新建协同对话"开始。
          </div>
        </div>
      </aside>

      <!-- Right: Chat area -->
      <main class="lg:col-span-9 apple-glass rounded-2xl border border-white/50 flex flex-col" style="min-height: 640px;">
        <template v-if="activeRoom">
          <!-- Room header -->
          <div class="px-5 py-3.5 border-b border-white/30 flex items-center justify-between gap-3 select-none">
            <div class="flex items-center gap-2 min-w-0">
              <h3 class="text-sm font-bold font-serif-sc text-zen-ink truncate">{{ activeRoom.name }}</h3>
              <span class="text-[9px] text-zen-gray bg-white/50 px-2 py-0.5 rounded-full border border-white/40 shrink-0">
                {{ roomMembers(activeRoom).length }} 位 Agent
              </span>
            </div>
            <div class="flex items-center gap-2 shrink-0">
              <button
                @click="openManageMembersModal"
                class="text-[10px] text-zen-gray hover:text-zen-ink bg-white/40 hover:bg-white border border-white/50 rounded-lg px-2.5 py-1 outline-none"
                title="管理参与者"
              >👥 成员</button>
              <button
                @click="continueDiscussion"
                :disabled="isThinking || !aiMembers.length"
                class="text-[10px] bg-zen-tea/10 text-zen-tea hover:bg-zen-tea/20 border border-zen-tea/30 rounded-lg px-2.5 py-1 outline-none disabled:opacity-40"
                title="让 AI 角色之间继续讨论一轮"
              >🔄 继续讨论</button>
              <button
                @click="clearRoomMessages"
                class="text-[10px] text-zen-gray hover:text-zen-crimson bg-white/40 hover:bg-white border border-white/50 rounded-lg px-2.5 py-1 outline-none"
                title="清空当前对话"
              >🧹 清空</button>
            </div>
          </div>

          <!-- Member chips -->
          <div class="px-5 pt-3 pb-2 flex flex-wrap gap-1.5 border-b border-white/20 bg-white/10">
            <span
              v-for="m in roomMembers(activeRoom)"
              :key="m.id"
              class="px-2 py-0.5 rounded-full text-[9px] font-semibold border bg-white/60 border-white/50 text-zen-ink flex items-center gap-1"
              :title="m.role"
            >
              <span>{{ m.emoji || '🤖' }}</span>
              <span>{{ m.name }}</span>
              <span v-if="!m.isAi" class="text-[8px] text-zen-gold ml-0.5">人工</span>
            </span>
            <span v-if="!roomMembers(activeRoom).length" class="text-[10px] text-zen-gray italic">
              暂未添加 Agent，点击"成员"按钮选择参与者。
            </span>
          </div>

          <!-- Message list -->
          <div ref="scrollRef" class="flex-1 overflow-y-auto p-5 space-y-3.5">
            <div v-for="msg in activeRoom.messages || []" :key="msg.id">
              <!-- User message -->
              <div v-if="msg.role === 'user'" class="flex justify-end">
                <div class="max-w-[78%] bg-zen-ink text-white rounded-2xl rounded-tr-sm px-4 py-2.5 text-xs leading-relaxed whitespace-pre-wrap shadow-sm">
                  {{ msg.content }}
                </div>
              </div>

              <!-- Agent message -->
              <div v-else-if="msg.role === 'agent'" class="flex justify-start gap-2.5">
                <div class="w-8 h-8 rounded-full bg-white border border-white/60 flex items-center justify-center text-base shrink-0 shadow-sm select-none" :title="msg.agentRole || ''">
                  {{ msg.agentEmoji || '🤖' }}
                </div>
                <div class="max-w-[78%]">
                  <div class="flex items-baseline gap-1.5 mb-1 select-none">
                    <span class="text-[11px] font-bold text-zen-ink">{{ msg.agentName }}</span>
                    <span class="text-[9px] text-zen-gray">{{ msg.agentRole }}</span>
                    <span v-if="msg.model" class="text-[8px] text-zen-gray/60 font-mono">{{ msg.model }}</span>
                  </div>
                  <div
                    class="rounded-2xl rounded-tl-sm px-4 py-2.5 text-xs leading-relaxed whitespace-pre-wrap shadow-sm border"
                    :class="msg.error ? 'bg-rose-50 border-rose-200 text-rose-700' : 'bg-white border-white/60 text-zen-ink'"
                  >
                    {{ msg.content }}
                  </div>
                </div>
              </div>

              <!-- System hint -->
              <div v-else class="text-center text-[10px] text-zen-gray/60 italic select-none">
                {{ msg.content }}
              </div>
            </div>

            <div v-if="isThinking" class="flex items-center gap-2 text-[11px] text-zen-gray italic px-1">
              <span class="inline-flex h-2 w-2 rounded-full bg-zen-green animate-pulse"></span>
              {{ thinkingLabel }} 正在思考...
            </div>

            <div v-if="!(activeRoom.messages || []).length && !isThinking" class="py-12 text-center text-[11px] text-zen-gray/60 italic">
              提示：直接发言所有 AI Agent 会按顺序协同回应；输入 <code class="bg-white/40 border border-white/60 rounded px-1">@姓名</code> 可指定单个 Agent 回应。
            </div>
          </div>

          <!-- Input -->
          <div class="border-t border-white/30 p-4 bg-white/20">
            <div class="flex flex-col sm:flex-row gap-2">
              <textarea
                v-model="inputText"
                rows="2"
                placeholder="输入需要团队协同处理的任务，例如：评估这个客户的合作风险... 输入 @姓名 可单独点名某个 Agent。"
                @keyup.enter.exact="onEnterSend"
                class="flex-1 bg-white/60 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all resize-none"
              ></textarea>
              <button
                @click="sendMessage"
                :disabled="isThinking || !inputText.trim() || !aiMembers.length"
                class="self-end sm:self-stretch px-5 py-2.5 bg-zen-green hover:bg-zen-green/90 text-white rounded-xl text-xs font-bold shadow-sm transition-all active:scale-[0.97] outline-none disabled:opacity-40 disabled:cursor-not-allowed"
              >
                发送
              </button>
            </div>
            <div class="flex justify-between items-center mt-2 text-[9px] text-zen-gray select-none">
              <span>Enter 发送 · Shift+Enter 换行</span>
              <span v-if="!aiMembers.length" class="text-zen-crimson">需至少添加一名 AI 成员才能发送</span>
            </div>
          </div>
        </template>

        <div v-else class="flex-1 flex flex-col items-center justify-center text-center p-12">
          <div class="text-3xl mb-3">🤝</div>
          <p class="text-sm text-zen-gray mb-2">还没有协同对话</p>
          <button
            @click="openCreateRoomModal"
            class="px-4 py-2 bg-zen-ink text-white rounded-xl text-xs font-bold shadow-sm hover:bg-zen-ink/90"
          >
            ＋ 新建协同对话
          </button>
        </div>
      </main>
    </div>

    <!-- Create Room Modal -->
    <ZenModal :open="createRoomOpen" title="🤝 新建协同对话" @close="createRoomOpen = false">
      <div class="space-y-4 text-xs text-zen-ink">
        <div class="space-y-1.5">
          <label class="block font-bold">对话主题/任务名称</label>
          <input
            type="text"
            v-model="newRoomName"
            placeholder="如：评估德国 Müller 防冻水箱合作风险"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
          />
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">从团队中选择参与的 Agent</label>
          <p class="text-[10px] text-zen-gray">从「团队管理」里已建立的成员中勾选。AI 成员会自动回应；人工成员标注用于后续派发任务。</p>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-[280px] overflow-y-auto">
            <label
              v-for="m in teamMembers"
              :key="m.id"
              class="flex items-start gap-2 p-2.5 rounded-xl border bg-white/30 hover:bg-white/60 cursor-pointer transition-all"
              :class="newRoomMemberIds.includes(m.id) ? 'border-zen-green/60 bg-white' : 'border-white/40'"
            >
              <input type="checkbox" :value="m.id" v-model="newRoomMemberIds" class="mt-1" />
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-1.5">
                  <span class="text-base">{{ m.emoji || '🤖' }}</span>
                  <span class="font-bold text-zen-ink truncate">{{ m.name }}</span>
                  <span v-if="!m.isAi" class="text-[8px] text-zen-gold bg-zen-gold/10 px-1 py-0.5 rounded">人工</span>
                </div>
                <p class="text-[10px] text-zen-gray leading-relaxed mt-0.5 line-clamp-2">{{ m.desc || m.role }}</p>
              </div>
            </label>
            <div v-if="!teamMembers.length" class="md:col-span-2 text-center py-8 text-zen-gray/60 italic text-[10px]">
              团队管理里暂无成员，请先去「团队管理」添加。
            </div>
          </div>
        </div>
      </div>
      <template #footer>
        <button
          @click="confirmCreateRoom"
          class="px-5 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 font-semibold outline-none"
        >
          创建协同对话 🚀
        </button>
        <button
          @click="createRoomOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white font-medium outline-none"
        >
          取消
        </button>
      </template>
    </ZenModal>

    <!-- Manage Members Modal -->
    <ZenModal :open="manageMembersOpen" title="👥 管理协同对话成员" @close="manageMembersOpen = false">
      <div class="space-y-3 text-xs text-zen-ink" v-if="activeRoom">
        <p class="text-[10px] text-zen-gray">勾选/取消勾选下面的成员来调整本次协同对话的参与者。</p>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-2 max-h-[320px] overflow-y-auto">
          <label
            v-for="m in teamMembers"
            :key="m.id"
            class="flex items-start gap-2 p-2.5 rounded-xl border bg-white/30 hover:bg-white/60 cursor-pointer transition-all"
            :class="(activeRoom.memberIds || []).includes(m.id) ? 'border-zen-green/60 bg-white' : 'border-white/40'"
          >
            <input
              type="checkbox"
              :checked="(activeRoom.memberIds || []).includes(m.id)"
              @change="toggleMember(m.id)"
            />
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-1.5">
                <span class="text-base">{{ m.emoji || '🤖' }}</span>
                <span class="font-bold text-zen-ink truncate">{{ m.name }}</span>
                <span v-if="!m.isAi" class="text-[8px] text-zen-gold bg-zen-gold/10 px-1 py-0.5 rounded">人工</span>
              </div>
              <p class="text-[10px] text-zen-gray mt-0.5 line-clamp-2">{{ m.desc || m.role }}</p>
            </div>
          </label>
        </div>
      </div>
      <template #footer>
        <button
          @click="manageMembersOpen = false"
          class="px-5 py-2 rounded-xl bg-zen-ink text-white text-xs hover:bg-zen-ink/90 font-semibold outline-none"
        >
          完成
        </button>
      </template>
    </ZenModal>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted } from 'vue';
import ZenModal from './ZenModal.vue';

const props = defineProps({
  teamMembers: { type: Array, default: () => [] },
  callAiApi: { type: Function, required: true },
  ourCompanyInfo: { type: Object, default: () => ({}) }
});

// ── Persistent rooms ────────────────────────────────────────────────────────
const STORAGE_KEY = 'magichub_agent_rooms';
const rooms = ref([]);
const activeRoomId = ref(null);

const loadRooms = async () => {
  try {
    let saved = null;
    if (window.electronAPI?.loadSettings) {
      const res = await window.electronAPI.loadSettings(STORAGE_KEY);
      if (res?.success && Array.isArray(res.data)) saved = res.data;
    }
    if (!saved) {
      const local = localStorage.getItem(STORAGE_KEY);
      if (local) saved = JSON.parse(local);
    }
    if (Array.isArray(saved)) rooms.value = saved;
    if (rooms.value.length) activeRoomId.value = rooms.value[0].id;
  } catch (e) {
    console.error('[AgentRoom] load failed', e);
  }
};

const persistRooms = async () => {
  try {
    const plain = JSON.parse(JSON.stringify(rooms.value));
    localStorage.setItem(STORAGE_KEY, JSON.stringify(plain));
    if (window.electronAPI?.saveSettings) {
      await window.electronAPI.saveSettings(STORAGE_KEY, plain);
    }
  } catch (e) {
    console.error('[AgentRoom] persist failed', e);
  }
};

onMounted(loadRooms);
watch(rooms, persistRooms, { deep: true });

// ── Active room helpers ─────────────────────────────────────────────────────
const activeRoom = computed(() => rooms.value.find(r => r.id === activeRoomId.value) || null);

const roomMembers = (room) => {
  if (!room) return [];
  return (room.memberIds || [])
    .map(id => props.teamMembers.find(m => m.id === id))
    .filter(Boolean);
};

const aiMembers = computed(() => roomMembers(activeRoom.value).filter(m => m.isAi));

// ── Create Room flow ────────────────────────────────────────────────────────
const createRoomOpen = ref(false);
const newRoomName = ref('');
const newRoomMemberIds = ref([]);

const openCreateRoomModal = () => {
  newRoomName.value = '';
  // Default-select all AI members so it's one click away from a useful room
  newRoomMemberIds.value = props.teamMembers.filter(m => m.isAi).map(m => m.id);
  createRoomOpen.value = true;
};

const confirmCreateRoom = () => {
  const name = newRoomName.value.trim() || '未命名协同对话';
  if (!newRoomMemberIds.value.length) {
    alert('请至少选择一位参与的 Agent。');
    return;
  }
  const room = {
    id: 'room-' + Date.now(),
    name,
    memberIds: [...newRoomMemberIds.value],
    messages: [],
    createdAt: new Date().toISOString()
  };
  rooms.value = [room, ...rooms.value];
  activeRoomId.value = room.id;
  createRoomOpen.value = false;
};

const deleteRoom = (id) => {
  if (!confirm('确认删除该协同对话？聊天历史将一并清除。')) return;
  rooms.value = rooms.value.filter(r => r.id !== id);
  if (activeRoomId.value === id) {
    activeRoomId.value = rooms.value[0]?.id || null;
  }
};

const clearRoomMessages = () => {
  if (!activeRoom.value) return;
  if (!confirm('确认清空该对话的所有消息？')) return;
  activeRoom.value.messages = [];
};

// ── Manage members ──────────────────────────────────────────────────────────
const manageMembersOpen = ref(false);
const openManageMembersModal = () => { manageMembersOpen.value = true; };
const toggleMember = (id) => {
  if (!activeRoom.value) return;
  const ids = activeRoom.value.memberIds || [];
  activeRoom.value.memberIds = ids.includes(id)
    ? ids.filter(x => x !== id)
    : [...ids, id];
};

// ── Chat orchestration ──────────────────────────────────────────────────────
const inputText = ref('');
const isThinking = ref(false);
const thinkingLabel = ref('');
const scrollRef = ref(null);

const scrollToBottom = () => {
  nextTick(() => {
    const el = scrollRef.value;
    if (el) el.scrollTop = el.scrollHeight;
  });
};

const buildAgentSystemPrompt = (agent) => {
  const parts = [];
  parts.push(`你正在参加一个外贸 CRM 团队的多人协同对话。你的身份：${agent.name}（${agent.role}）。`);
  if (agent.desc) parts.push(`你的专长：${agent.desc}`);
  if (agent.instruction) parts.push(`核心准则：${agent.instruction}`);
  if (agent.skills && agent.skills.length) parts.push(`技能标签：${agent.skills.join('、')}`);
  if (props.ourCompanyInfo?.chineseName) {
    parts.push(`我方公司：${props.ourCompanyInfo.chineseName}（${props.ourCompanyInfo.englishName || ''}）。`);
  }
  parts.push('对话规则：');
  parts.push('- 始终以"我"自称，保持自己的角色视角；不要扮演其他成员，也不要复读他们的话。');
  parts.push('- 如果其他成员已经覆盖了某个角度，可在此基础上补充新的、属于你专业范围的观点。');
  parts.push('- 回复要简洁专业，控制在 200 字以内，重点突出，避免空话套话。');
  parts.push('- 用中文回复。');
  return parts.join('\n');
};

// Convert internal messages to OpenAI-style history for a given agent.
// Other agents' replies are framed as user messages to keep the model focused
// on its own persona while still seeing the discussion context.
const buildHistoryFor = (agent, messages) => {
  return messages.map(m => {
    if (m.role === 'user') {
      return { role: 'user', content: m.content };
    }
    if (m.role === 'agent') {
      if (m.agentId === agent.id) {
        return { role: 'assistant', content: m.content };
      }
      return { role: 'user', content: `[${m.agentName} · ${m.agentRole}] ${m.content}` };
    }
    return null;
  }).filter(Boolean);
};

const callAgent = async (agent, history) => {
  // Map agent.model (string label) to a configured provider id when possible
  // — fall back to whatever provider is currently active.
  const systemPrompt = buildAgentSystemPrompt(agent);
  try {
    const reply = await props.callAiApi('', '', {
      systemPrompt,
      history,
      temperature: agent.temperature ?? 0.7,
      maxTokens: agent.maxTokens || 800
    });
    return { content: reply, error: typeof reply === 'string' && reply.startsWith('⚠️') };
  } catch (e) {
    return { content: '⚠️ ' + (e.message || '调用失败'), error: true };
  }
};

const pushAgentMessage = (agent, result) => {
  if (!activeRoom.value) return;
  activeRoom.value.messages.push({
    id: 'msg-' + Date.now() + '-' + Math.random().toString(36).slice(2, 6),
    role: 'agent',
    agentId: agent.id,
    agentName: agent.name,
    agentRole: agent.role,
    agentEmoji: agent.emoji || '🤖',
    model: agent.model || '',
    content: result.content,
    error: result.error,
    createdAt: new Date().toISOString()
  });
  scrollToBottom();
};

const pushHumanReminder = (agent) => {
  if (!activeRoom.value) return;
  activeRoom.value.messages.push({
    id: 'msg-' + Date.now() + '-h',
    role: 'system',
    content: `⏳ 人工成员 ${agent.name}（${agent.role}）已收到任务，等待线下跟进。`,
    createdAt: new Date().toISOString()
  });
};

// Detect @mention to a specific agent
const findMentionedAgent = (text, members) => {
  const m = text.match(/@([^\s@：:，,。.]+)/);
  if (!m) return null;
  const name = m[1];
  return members.find(x => x.name === name || x.name?.includes(name) || name.includes(x.name)) || null;
};

const onEnterSend = (e) => {
  // Plain Enter sends; Shift+Enter inserts a newline
  if (e.shiftKey) return;
  e.preventDefault();
  sendMessage();
};

const sendMessage = async () => {
  if (!activeRoom.value || isThinking.value) return;
  const text = inputText.value.trim();
  if (!text) return;
  if (!aiMembers.value.length) {
    alert('当前对话尚未添加 AI 成员，无法触发协同回应。');
    return;
  }

  // Append user message
  activeRoom.value.messages.push({
    id: 'msg-' + Date.now() + '-u',
    role: 'user',
    content: text,
    createdAt: new Date().toISOString()
  });
  inputText.value = '';
  scrollToBottom();

  // Determine which agents respond
  const allMembers = roomMembers(activeRoom.value);
  const mentioned = findMentionedAgent(text, allMembers);
  const responders = mentioned
    ? [mentioned]
    : aiMembers.value;

  isThinking.value = true;
  try {
    for (const agent of responders) {
      thinkingLabel.value = agent.name;
      if (!agent.isAi) {
        pushHumanReminder(agent);
        continue;
      }
      const history = buildHistoryFor(agent, activeRoom.value.messages);
      // Drop the trailing user message — callAiApi appends it from userMessage param
      // Actually we want the full context including the user msg, but our wrapper
      // adds userMessage separately. Use empty userMessage and full history.
      const result = await callAgent(agent, history);
      pushAgentMessage(agent, result);
    }
  } finally {
    isThinking.value = false;
    thinkingLabel.value = '';
  }
};

// Let agents continue discussing among themselves without new user input.
const continueDiscussion = async () => {
  if (!activeRoom.value || isThinking.value) return;
  if (!aiMembers.value.length) return;
  // Insert a system nudge as a "user" prompt asking for continued discussion
  const nudge = '请基于以上讨论继续推进：补充新观点、提出可执行的下一步或指出尚未覆盖的风险点。';
  activeRoom.value.messages.push({
    id: 'msg-' + Date.now() + '-u',
    role: 'user',
    content: nudge,
    createdAt: new Date().toISOString()
  });
  scrollToBottom();
  isThinking.value = true;
  try {
    for (const agent of aiMembers.value) {
      thinkingLabel.value = agent.name;
      const history = buildHistoryFor(agent, activeRoom.value.messages);
      const result = await callAgent(agent, history);
      pushAgentMessage(agent, result);
    }
  } finally {
    isThinking.value = false;
    thinkingLabel.value = '';
  }
};
</script>
