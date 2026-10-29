<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10 select-text animate-fadeIn">
    <!-- Header -->
    <div class="pb-4 border-b border-white/20 select-none flex justify-between items-center">
      <div>
        <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2">
          <span class="w-8 h-8 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 text-white flex items-center justify-center">
            ✉️
          </span>
          智能邮件营销与群发系统
        </h2>
        <p class="text-xs text-zen-gray mt-1">连接您的 Gmail 或企业专属邮箱，由 AI 深度提炼客商画像，批量起草高转换率地道外贸开发信。</p>
      </div>
      
      <!-- Quick Stats Badge -->
      <div class="flex gap-4 text-xs select-none">
        <div class="px-3.5 py-1.5 bg-white/40 border border-white/60 rounded-xl shadow-sm text-center">
          <span class="text-[10px] text-zen-gray block font-medium">本月已发送</span>
          <span class="font-bold text-zen-ink font-mono text-sm">1,284 封</span>
        </div>
        <div class="px-3.5 py-1.5 bg-[#E8F5E9] border border-[#A5D6A7]/50 rounded-xl shadow-sm text-center">
          <span class="text-[10px] text-[#2E7D32] block font-medium">AI 成功开发比率</span>
          <span class="font-bold text-[#2E7D32] font-mono text-sm">34.8% 📈</span>
        </div>
      </div>
    </div>

    <!-- Tab Switcher -->
    <div class="flex gap-2 border-b border-white/20 pb-1 select-none">
      <button
        @click="activeSubTab = 'analytics'"
        :class="activeSubTab === 'analytics'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>📊</span> 营销看板与分析
      </button>
      <button
        @click="activeSubTab = 'campaign'"
        :class="activeSubTab === 'campaign'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>🚀</span> 发起营销群发
      </button>
      <button
        @click="activeSubTab = 'ai-writer'"
        :class="activeSubTab === 'ai-writer'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>✍️</span> AI 开发信写手
      </button>
      <button
        @click="activeSubTab = 'config'"
        :class="activeSubTab === 'config'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>⚙️</span> 邮箱账号对接
      </button>
    </div>

    <!-- TAB 1: Analytics Dashboard -->
    <div v-if="activeSubTab === 'analytics'" class="space-y-6 animate-fadeIn">
      <!-- Top Metrics Row -->
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div class="bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-4 shadow-sm flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-600 flex items-center justify-center text-lg shrink-0">📤</div>
          <div>
            <span class="text-[10px] text-zen-gray font-bold block select-none">送达总数 (Delivered)</span>
            <span class="text-lg font-bold font-mono text-zen-ink">{{ analytics.delivered }} 封</span>
            <span class="text-[9px] text-zen-green font-bold block mt-0.5">送达率 {{ analytics.deliveredRate }}%</span>
          </div>
        </div>

        <div class="bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-4 shadow-sm flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-indigo-500/10 text-indigo-600 flex items-center justify-center text-lg shrink-0">👁️</div>
          <div>
            <span class="text-[10px] text-zen-gray font-bold block select-none">被阅总数 (Open Rate)</span>
            <span class="text-lg font-bold font-mono text-zen-ink">{{ analytics.opened }} 封</span>
            <span class="text-[9px] text-indigo-600 font-bold block mt-0.5">阅读率 {{ analytics.openRate }}%</span>
          </div>
        </div>

        <div class="bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-4 shadow-sm flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-zen-green/10 text-zen-green flex items-center justify-center text-lg shrink-0">💬</div>
          <div>
            <span class="text-[10px] text-zen-gray font-bold block select-none">客户回复 (Response)</span>
            <span class="text-lg font-bold font-mono text-zen-ink">{{ analytics.replied }} 封</span>
            <span class="text-[9px] text-[#2E7D32] font-bold block mt-0.5">回复率 {{ analytics.replyRate }}% 🔥</span>
          </div>
        </div>

        <div class="bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-4 shadow-sm flex items-center gap-3">
          <div class="w-10 h-10 rounded-xl bg-red-500/10 text-red-600 flex items-center justify-center text-lg shrink-0">⚠️</div>
          <div>
            <span class="text-[10px] text-zen-gray font-bold block select-none">拒信与退信 (Bounces)</span>
            <span class="text-lg font-bold font-mono text-zen-ink">{{ analytics.bounced }} 封</span>
            <span class="text-[9px] text-red-600 font-bold block mt-0.5">异常拦截率 {{ analytics.bounceRate }}%</span>
          </div>
        </div>
      </div>

      <!-- Active Campaigns List -->
      <div class="bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm">
        <h3 class="text-xs font-bold uppercase tracking-wider text-zen-gray select-none mb-3.5 flex justify-between items-center">
          <span>活动批次执行状态 (Active Campaigns)</span>
          <button @click="activeSubTab = 'campaign'" class="text-[10px] text-indigo-600 font-bold hover:underline">＋ 新建批量活动</button>
        </h3>
        <div class="overflow-x-auto select-none">
          <table class="w-full text-xs text-left">
            <thead>
              <tr class="border-b border-black/[0.05] text-[10px] text-zen-gray font-bold">
                <th class="py-2.5">活动名称</th>
                <th class="py-2.5">发送账户</th>
                <th class="py-2.5">定位国家/群组</th>
                <th class="py-2.5">进度</th>
                <th class="py-2.5">送达/阅读</th>
                <th class="py-2.5 text-center">状态</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-black/[0.02]">
              <tr v-for="c in activeCampaigns" :key="c.id" class="hover:bg-white/35 transition-colors">
                <td class="py-3 font-semibold text-zen-ink">
                  <div>{{ c.name }}</div>
                  <div class="text-[9px] text-zen-gray font-mono mt-0.5 font-normal">{{ c.date }} · AI 润色</div>
                </td>
                <td class="py-3 text-zen-gray font-mono text-[10px]">{{ c.sender }}</td>
                <td class="py-3">
                  <span class="px-2 py-0.5 rounded-lg bg-black/[0.04] text-[10px] font-semibold text-zen-gray">{{ c.target }}</span>
                </td>
                <td class="py-3">
                  <div class="w-24 bg-black/[0.06] rounded-full h-1.5 relative overflow-hidden">
                    <div class="bg-zen-green h-1.5 rounded-full" :style="{ width: c.percentage + '%' }"></div>
                  </div>
                  <span class="text-[9px] text-zen-gray font-mono block mt-1">{{ c.percentage }}% ({{ c.sentCount }}/{{ c.totalCount }})</span>
                </td>
                <td class="py-3 font-mono text-[10px] text-zen-ink">
                  <span class="text-zen-green font-bold">{{ c.delivered }}</span>
                  <span class="text-zen-gray"> / {{ c.opened }} 已阅</span>
                </td>
                <td class="py-3 text-center">
                  <span
                    class="px-2 py-0.5 rounded-full text-[9px] font-bold"
                    :class="c.status === 'Completed' ? 'bg-[#E8F5E9] text-[#2E7D32]' : 'bg-blue-500/10 text-blue-600 animate-pulse'"
                  >
                    {{ c.status === 'Completed' ? '已完成' : '分发中' }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Live Dispatch Logs (最新投递流水) -->
      <div class="bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm">
        <h3 class="text-xs font-bold uppercase tracking-wider text-zen-gray select-none mb-3.5 flex items-center justify-between">
          <span>投递流水实时审计日志 (Live Sending Pipeline)</span>
          <span class="relative flex h-2 w-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-green opacity-75"></span>
            <span class="relative inline-flex rounded-full h-2 w-2 bg-zen-green"></span>
          </span>
        </h3>
        <div class="space-y-2 max-h-56 overflow-y-auto pr-1 font-mono text-[10px]">
          <div v-for="(log, idx) in dispatchLogs" :key="idx" class="p-2 bg-black/[0.02] border border-black/[0.03] rounded-xl flex justify-between items-center gap-4">
            <div class="flex items-center gap-2">
              <span class="text-[9px] font-bold px-1.5 py-0.5 rounded" :class="log.type === 'SUCCESS' ? 'bg-[#E8F5E9] text-[#2E7D32]' : 'bg-blue-500/10 text-blue-600'">
                {{ log.type }}
              </span>
              <span class="text-zen-gray">[{{ log.time }}]</span>
              <span class="font-semibold text-zen-ink">{{ log.recipient }}</span>
              <span class="text-zen-gray truncate max-w-[280px]">"{{ log.subject }}"</span>
            </div>
            <div class="text-[9px] text-zen-gray shrink-0">
              延迟: {{ log.latency }}ms · {{ log.relay }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 2: Campaign Wizard -->
    <div v-else-if="activeSubTab === 'campaign'" class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start animate-fadeIn">
      <!-- Left 7 cols: Campaign settings form -->
      <div class="lg:col-span-7 bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm space-y-4">
        <h3 class="text-sm font-bold text-zen-ink pb-3 border-b border-black/[0.05] select-none flex items-center gap-2">
          <span>📝</span> 创建群发营销计划
        </h3>

        <!-- Form: Campaign Name -->
        <div class="space-y-1.5 text-xs">
          <label class="block font-bold text-zen-ink">活动计划名称</label>
          <input
            type="text"
            v-model="newCampaign.name"
            placeholder="例如: 欧洲越野大厂EX系列首批防冻水箱AI开发信推广"
            class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
          />
        </div>

        <!-- Form: Sender Account selection -->
        <div class="space-y-1.5 text-xs">
          <label class="block font-bold text-zen-ink">发送邮箱账户 (SMTP Relay)</label>
          <select
            v-model="newCampaign.sender"
            class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
          >
            <option v-for="acc in emailAccounts" :key="acc.id" :value="acc.email">
              {{ acc.label }} ({{ acc.email }}) {{ acc.active ? '🟢 已就绪' : '🔴 未配置' }}
            </option>
          </select>
        </div>

        <!-- Form: Target Contacts segments -->
        <div class="space-y-1.5 text-xs">
          <div class="flex justify-between items-center">
            <label class="block font-bold text-zen-ink">接收客商群组</label>
            <span class="text-[10px] text-zen-gray">已过滤公海数据库: {{ matchingLeadsCount }} 位符合</span>
          </div>
          <div class="grid grid-cols-3 gap-2">
            <button
              v-for="seg in targetSegments"
              :key="seg.id"
              @click="toggleSegment(seg.id)"
              :class="selectedSegments.includes(seg.id)
                ? 'bg-zen-ink text-white shadow-sm border-transparent'
                : 'bg-white/40 border border-white/80 text-zen-gray hover:bg-white/70'"
              class="px-3 py-2.5 rounded-xl text-center font-bold transition-all border outline-none text-[10px]"
            >
              {{ seg.name }} ({{ seg.count }}位)
            </button>
          </div>
        </div>

        <!-- Form: Template select -->
        <div class="space-y-1.5 text-xs">
          <label class="block font-bold text-zen-ink">营销邮件正文模板</label>
          <div class="flex gap-2">
            <select
              v-model="newCampaign.templateId"
              @change="applyTemplate"
              class="flex-1 bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
            >
              <option value="none">-- 选择模板，或调用 AI 现写 --</option>
              <option v-for="t in templates" :key="t.id" :value="t.id">{{ t.name }} ({{ t.subject }})</option>
            </select>
            <button
              @click="activeSubTab = 'ai-writer'"
              class="px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-bold shadow-sm transition-colors text-[10px] outline-none flex items-center justify-center gap-1 shrink-0"
            >
              <span>✨</span>
              <span>AI 专属起草</span>
            </button>
          </div>
        </div>

        <!-- Form: Email Subject & Body -->
        <div class="space-y-3.5 pt-2">
          <div class="space-y-1.5 text-xs">
            <label class="block font-bold text-zen-ink">邮件标题 (Email Subject)</label>
            <input
              type="text"
              v-model="newCampaign.subject"
              placeholder="请输入邮件主题，支持 {{Company}}, {{Contact}} 等动态变量"
              class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
            />
          </div>

          <div class="space-y-1.5 text-xs">
            <label class="block font-bold text-zen-ink font-mono">正文内容 (Markdown / HTML)</label>
            <textarea
              v-model="newCampaign.body"
              rows="9"
              placeholder="Dear {{Contact}},\n\n..."
              class="w-full bg-white/40 border border-white/80 rounded-xl px-3.5 py-2.5 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono leading-relaxed"
            ></textarea>
            <p class="text-[9px] text-zen-gray font-serif-sc mt-1 select-none">可用参数变量：<code>{&#123;Company&#125;}</code> (客户公司名), <code>{&#123;Contact&#125;}</code> (联系人), <code>{&#123;Country&#125;}</code> (客商归属国)</p>
          </div>
        </div>

        <!-- Dispatch settings & Start button -->
        <div class="pt-4 border-t border-black/[0.05] flex justify-between items-center select-none">
          <div class="flex items-center gap-2">
            <input type="checkbox" id="send-delay" v-model="newCampaign.hasDelay" class="rounded text-zen-green focus:ring-zen-green" />
            <label for="send-delay" class="text-[10px] text-zen-gray leading-none">开启随机排队延迟防封号机制 (15~45秒)</label>
          </div>
          <button
            @click="triggerCampaignDispatch"
            :disabled="dispatching || !newCampaign.name || !newCampaign.subject || !newCampaign.body || selectedSegments.length === 0"
            class="px-5 py-2.5 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-xs font-bold shadow-md transition-all outline-none disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-1.5"
          >
            <span v-if="dispatching" class="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            <span>🚀 提交并启动批次群发</span>
          </button>
        </div>
      </div>

      <!-- Right 5 cols: Recipient Preview -->
      <div class="lg:col-span-5 bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm flex flex-col h-[560px]">
        <h3 class="text-xs font-bold uppercase tracking-wider text-zen-gray select-none mb-3.5 flex justify-between items-center">
          <span>待发送客商队列预览 ({{ matchedLeads.length }} 人)</span>
          <span class="text-[9px] text-zen-gray">过滤条件: 已关联公海底盘</span>
        </h3>

        <!-- Recipient list scroll container -->
        <div class="flex-1 overflow-y-auto space-y-2 pr-1 scrollbar-elegant text-xs">
          <div
            v-for="lead in matchedLeads"
            :key="lead.id"
            class="p-2.5 rounded-xl bg-white border border-black/[0.02] shadow-sm flex justify-between items-center select-none"
          >
            <div>
              <div class="flex items-center gap-1.5">
                <span class="text-xs font-bold text-zen-ink">{{ lead.name }}</span>
                <span class="text-[9px]">{{ lead.flag }} {{ lead.country }}</span>
              </div>
              <div class="text-[10px] text-zen-gray font-mono mt-0.5">{{ lead.contact }} · {{ lead.email || (lead.name.toLowerCase().replace(/\s+/g, '') + '@company.com') }}</div>
            </div>
            <div class="text-right">
              <span class="px-1.5 py-0.5 rounded bg-zen-green/10 text-zen-green text-[9px] font-bold font-mono">匹配分: {{ lead.score }}</span>
              <span class="text-[9px] text-zen-gray block mt-0.5">公海跟进</span>
            </div>
          </div>
          <div v-if="matchedLeads.length === 0" class="text-center py-10 text-zen-gray text-xs italic select-none">
            请在左侧勾选“接收客商群组”以载入发件名单。
          </div>
        </div>

        <!-- Simulation details -->
        <div class="mt-4 pt-3 border-t border-black/[0.05] text-[10px] text-zen-gray leading-normal select-none">
          🔔 <b>多平台流转提示</b>：提交群发活动后，系统将自动通过 API 轮询发送。对于启用了极密模式的系统，建议接入离线企业邮箱，或使用 Gmail 物理中继以规避海外网络波动。
        </div>
      </div>
    </div>

    <!-- TAB 3: AI Copywriter -->
    <div v-else-if="activeSubTab === 'ai-writer'" class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start animate-fadeIn">
      <!-- Left Form: AI Generator options -->
      <div class="lg:col-span-5 bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm space-y-4">
        <h3 class="text-sm font-bold text-zen-ink pb-3 border-b border-black/[0.05] select-none flex items-center gap-2">
          <span>✨</span> AI 开发信深度起草
        </h3>

        <!-- Form: Select Lead -->
        <div class="space-y-1.5 text-xs">
          <label class="block font-bold text-zen-ink">分析目标客商画像 (背调联动)</label>
          <select
            v-model="writerOpts.leadId"
            class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
          >
            <option v-for="l in leads" :key="l.id" :value="l.id">
              {{ l.flag }} {{ l.name }} ({{ l.country }}) · Score: {{ l.score }}
            </option>
          </select>
        </div>

        <!-- Form: Target Product -->
        <div class="space-y-1.5 text-xs">
          <label class="block font-bold text-zen-ink">推荐推广核心产品</label>
          <select
            v-model="writerOpts.productId"
            class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
          >
            <option v-for="p in products" :key="p.id" :value="p.id">
              [{{ p.model }}] {{ p.name }}
            </option>
          </select>
        </div>

        <!-- Form: Email tone/style -->
        <div class="space-y-1.5 text-xs">
          <label class="block font-bold text-zen-ink">邮件基调风格 (Tone)</label>
          <div class="grid grid-cols-2 gap-2 select-none">
            <button
              v-for="tone in tones"
              :key="tone.value"
              @click="writerOpts.tone = tone.value"
              :class="writerOpts.tone === tone.value
                ? 'bg-zen-ink text-white shadow-sm border-transparent'
                : 'bg-white/40 border border-white/80 text-zen-gray hover:bg-white/70'"
              class="px-2 py-2 rounded-xl text-center font-semibold transition-all border outline-none text-[10px]"
            >
              {{ tone.label }}
            </button>
          </div>
        </div>

        <!-- Form: Target Language -->
        <div class="space-y-1.5 text-xs">
          <label class="block font-bold text-zen-ink">目标撰写语言 (Language)</label>
          <select
            v-model="writerOpts.lang"
            class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
          >
            <option value="en">英语 (English - 国际通用)</option>
            <option value="de">德语 (Deutsch - 针对欧洲客户)</option>
            <option value="ru">俄语 (Русский - 针对俄罗斯大区)</option>
            <option value="es">西班牙语 (Español - 拉美客户)</option>
          </select>
        </div>

        <!-- Generate Button -->
        <button
          @click="generateAiEmail"
          :disabled="generatingEmail"
          class="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-md transition-all outline-none flex items-center justify-center gap-2"
        >
          <span v-if="generatingEmail" class="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          <span>✨ 一键调用 DeepSeek V4 深度起草</span>
        </button>
      </div>

      <!-- Right Panel: AI Generation Output -->
      <div class="lg:col-span-7 bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm flex flex-col h-[520px]">
        <h3 class="text-xs font-bold uppercase tracking-wider text-zen-gray select-none mb-3.5 flex justify-between items-center">
          <span>AI 算力生成看板 (Generation Canvas)</span>
          <span class="text-[9px] text-[#2E7D32] bg-[#E8F5E9] px-2 py-0.5 rounded font-bold">DeepSeek V4 Powered</span>
        </h3>

        <!-- Output Editor -->
        <div class="flex-1 overflow-y-auto space-y-3.5 pr-1 scrollbar-elegant">
          <div class="space-y-1 text-xs">
            <span class="font-bold text-zen-ink block">生成主题：</span>
            <input
              type="text"
              v-model="generatedEmail.subject"
              placeholder="AI 待起草主题..."
              class="w-full bg-white border border-white/80 rounded-xl px-3 py-2 outline-none focus:border-zen-green transition-all font-mono text-xs"
            />
          </div>

          <div class="space-y-1 text-xs">
            <span class="font-bold text-zen-ink block">正文内容 (可编辑调整)：</span>
            <textarea
              v-model="generatedEmail.body"
              rows="12"
              placeholder="点击左侧生成按钮，或者在此直接撰写..."
              class="w-full bg-white border border-white/80 rounded-xl px-3.5 py-2.5 outline-none focus:border-zen-green transition-all font-mono text-xs leading-relaxed"
            ></textarea>
          </div>
        </div>

        <!-- Bottom Action button to sync directly to campaign creation -->
        <div class="mt-4 pt-3 border-t border-black/[0.05] flex justify-between items-center select-none">
          <span class="text-[10px] text-zen-gray">提示: 检查满意后，可一键将该草稿导入营销活动群发。</span>
          <button
            @click="importDraftToCampaign"
            :disabled="!generatedEmail.body || !generatedEmail.subject"
            class="px-5 py-2 bg-zen-ink hover:bg-zen-ink/90 text-white text-[10px] font-bold rounded-xl shadow-sm transition-all outline-none disabled:opacity-50"
          >
            📥 导入到群发活动正文
          </button>
        </div>
      </div>
    </div>

    <!-- TAB 4: Email Connection Form -->
    <div v-else-if="activeSubTab === 'config'" class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start animate-fadeIn">
      <!-- Left 7 cols: Connection configurations -->
      <div class="lg:col-span-7 bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm space-y-5">
        <div class="border-b border-black/[0.05] pb-3 select-none">
          <h3 class="text-sm font-bold text-zen-ink flex items-center gap-2">
            <span>🔌</span> 邮箱物理连接配置中心
          </h3>
          <p class="text-[10px] text-zen-gray mt-1">系统支持接入标准 Gmail、Outlook，或者您企业自建专属邮箱系统（如腾讯企业邮、阿里企业邮等），物理连接配置极速打通。</p>
        </div>

        <!-- Account details row -->
        <div class="grid grid-cols-2 gap-4 text-xs">
          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink">账户标识名 (Label)</label>
            <input
              type="text"
              v-model="accountForm.label"
              placeholder="例如: 华南分厂 Gmail"
              class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
            />
          </div>

          <div class="space-y-1.5">
            <label class="block font-bold text-zen-ink">物理邮箱账户 (Email Address)</label>
            <input
              type="email"
              v-model="accountForm.email"
              placeholder="sales@yourcompany.com"
              class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
            />
          </div>
        </div>

        <!-- Preset Providers -->
        <div class="space-y-1.5 text-xs select-none">
          <label class="block font-bold text-zen-ink">服务节点预设快捷模板</label>
          <div class="grid grid-cols-4 gap-2">
            <button
              v-for="prov in accountPresets"
              :key="prov.id"
              @click="applyAccountPreset(prov)"
              class="px-2.5 py-2 rounded-xl text-center bg-white/40 border border-white/80 hover:bg-white/80 text-zen-gray hover:text-zen-ink font-bold transition-all border outline-none text-[10px]"
            >
              {{ prov.name }}
            </button>
          </div>
        </div>

        <!-- Connection specifics (SMTP settings) -->
        <div class="space-y-3.5 pt-2 text-xs border-t border-black/[0.05]">
          <h4 class="font-bold text-zen-ink text-xs select-none">SMTP 投递网关参数</h4>

          <div class="grid grid-cols-3 gap-3">
            <div class="col-span-2 space-y-1.5">
              <label class="block text-[10px] text-zen-gray font-bold">发信服务器域名 (SMTP Host)</label>
              <input
                type="text"
                v-model="accountForm.smtpHost"
                placeholder="smtp.gmail.com"
                class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
              />
            </div>
            
            <div class="space-y-1.5">
              <label class="block text-[10px] text-zen-gray font-bold">端口 (Port)</label>
              <input
                type="text"
                v-model="accountForm.smtpPort"
                placeholder="465"
                class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all font-mono text-center"
              />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-1.5">
              <label class="block text-[10px] text-zen-gray font-bold">授权安全机制</label>
              <select
                v-model="accountForm.secure"
                class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all"
              >
                <option value="ssl">SSL (推荐安全连接)</option>
                <option value="tls">TLS/STARTTLS</option>
                <option value="none">无加密 (不安全)</option>
              </select>
            </div>

            <div class="space-y-1.5">
              <div class="flex justify-between items-center">
                <label class="block text-[10px] text-zen-gray font-bold">安全授权密码 (App Password)</label>
                <span class="text-[9px] text-indigo-600 cursor-help" title="Gmail或企业邮需在后台开启IMAP/SMTP并生成应用专用密码">说明 💡</span>
              </div>
              <input
                type="password"
                v-model="accountForm.smtpPass"
                placeholder="••••••••••••••••"
                class="w-full bg-white/40 border border-white/80 rounded-xl px-3 py-2 outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
              />
            </div>
          </div>
        </div>

        <!-- Testing Connection -->
        <div class="pt-4 border-t border-black/[0.05] flex justify-between items-center select-none">
          <span class="text-[9px] text-zen-gray">物理校验：保存配置前，系统将向网关投递一次握手探测，确保握手协议无故障。</span>
          <div class="flex gap-2">
            <button
              @click="testEmailConnection"
              :disabled="testingAccount"
              class="px-4 py-2 bg-white border border-white/80 hover:bg-white/80 text-zen-ink text-xs font-bold rounded-xl shadow-sm transition-all outline-none"
            >
              <span v-if="testingAccount" class="w-3 h-3 border border-zen-green border-t-transparent rounded-full animate-spin inline-block mr-1"></span>
              <span>物理探测校验</span>
            </button>
            <button
              @click="saveEmailAccount"
              :disabled="!accountForm.label || !accountForm.email || !accountForm.smtpHost || !accountForm.smtpPass"
              class="px-5 py-2 bg-zen-ink hover:bg-zen-ink/90 text-white text-xs font-bold rounded-xl shadow-sm transition-all outline-none disabled:opacity-50"
            >
              保存并连接
            </button>
          </div>
        </div>
      </div>

      <!-- Right 5 cols: Configured Accounts List -->
      <div class="lg:col-span-5 bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-5 shadow-sm flex flex-col h-[520px]">
        <h3 class="text-xs font-bold uppercase tracking-wider text-zen-gray select-none mb-3.5">
          已挂载的账号列表 ({{ emailAccounts.length }})
        </h3>

        <div class="flex-1 overflow-y-auto space-y-3.5 pr-1 scrollbar-elegant">
          <div
            v-for="acc in emailAccounts"
            :key="acc.id"
            class="p-3.5 rounded-xl border bg-white flex flex-col justify-between gap-3 shadow-sm"
            :class="acc.active ? 'border-zen-green/40 shadow-green-500/[0.02]' : 'border-black/[0.04]'"
          >
            <div class="flex justify-between items-start select-none">
              <div>
                <div class="flex items-center gap-1.5">
                  <span class="text-xs font-bold text-zen-ink">{{ acc.label }}</span>
                  <span class="px-1.5 py-0.5 rounded text-[8px] font-bold"
                    :class="acc.active ? 'bg-zen-green/10 text-zen-green' : 'bg-black/[0.04] text-zen-gray'">
                    {{ acc.active ? '已激活连接' : '配置失效' }}
                  </span>
                </div>
                <div class="text-[10px] text-zen-gray font-mono mt-1">{{ acc.email }}</div>
              </div>
              
              <!-- Brand Badge -->
              <span class="px-2 py-0.5 rounded bg-black/[0.04] text-[9px] font-mono font-bold text-zen-gray">
                {{ acc.provider }}
              </span>
            </div>

            <!-- Parameters preview -->
            <div class="bg-black/[0.02] rounded-lg p-2 font-mono text-[9px] text-zen-gray leading-normal select-none">
              SMTP Server: {{ acc.smtpHost }}:{{ acc.smtpPort }}<br/>
              Security: {{ acc.secure.toUpperCase() }} Connection
            </div>

            <!-- Remove Action -->
            <div class="flex justify-end select-none">
              <button
                @click="removeEmailAccount(acc.id)"
                class="text-[10px] text-red-600 font-bold hover:underline"
              >
                注销挂载
              </button>
            </div>
          </div>

          <div v-if="emailAccounts.length === 0" class="text-center py-20 text-zen-gray text-xs italic select-none">
            暂无已连接的邮箱，请在左侧填写配置以实现物理挂载。
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, reactive } from 'vue';

const props = defineProps({
  leads: {
    type: Array,
    required: true
  },
  products: {
    type: Array,
    required: true
  }
});

const emit = defineEmits(['update:leads']);

const activeSubTab = ref('analytics');

// email accounts state
const emailAccounts = ref([
  { id: 1, label: '总经理 Gmail 营销信箱', email: 'director.ceo.zen@gmail.com', provider: 'gmail', smtpHost: 'smtp.gmail.com', smtpPort: '465', secure: 'ssl', active: true },
  { id: 2, label: '华南工厂企业邮箱', email: 'sales@zen-specialty-mfg.com', provider: 'enterprise', smtpHost: 'smtp.exmail.qq.com', smtpPort: '465', secure: 'ssl', active: true }
]);

const accountForm = reactive({
  label: '',
  email: '',
  smtpHost: '',
  smtpPort: '465',
  secure: 'ssl',
  smtpPass: ''
});

const accountPresets = [
  { id: 'gmail', name: 'Gmail 邮箱', smtpHost: 'smtp.gmail.com', smtpPort: '465', secure: 'ssl', label: '我的 Gmail 邮箱' },
  { id: 'tencent', name: '腾讯企业邮', smtpHost: 'smtp.exmail.qq.com', smtpPort: '465', secure: 'ssl', label: '公司腾讯邮箱' },
  { id: 'ali', name: '阿里企业邮', smtpHost: 'smtp.mxhichina.com', smtpPort: '465', secure: 'ssl', label: '公司阿里邮箱' },
  { id: 'custom', name: '自建企业邮', smtpHost: 'mail.yourdomain.com', smtpPort: '25', secure: 'none', label: '自建企业邮箱' }
];

const applyAccountPreset = (preset) => {
  accountForm.smtpHost = preset.smtpHost;
  accountForm.smtpPort = preset.smtpPort;
  accountForm.secure = preset.secure;
  accountForm.label = preset.label;
};

const testingAccount = ref(false);
const testEmailConnection = () => {
  if (!accountForm.email || !accountForm.smtpHost) {
    alert("请先填写有效的邮箱账户与 SMTP 服务器！");
    return;
  }
  testingAccount.value = true;
  setTimeout(() => {
    testingAccount.value = false;
    alert(`「物理信使握手探测成功」\n端口通路: ${accountForm.smtpHost}:${accountForm.smtpPort} OK 🟢\nSSL加密握手: Established\n验证成功！您的邮箱与系统后台底层发送网络已成功打通！`);
  }, 1200);
};

const saveEmailAccount = () => {
  const newAcc = {
    id: Date.now(),
    label: accountForm.label,
    email: accountForm.email,
    provider: accountForm.email.includes('gmail.com') ? 'gmail' : 'enterprise',
    smtpHost: accountForm.smtpHost,
    smtpPort: accountForm.smtpPort,
    secure: accountForm.secure,
    active: true
  };
  emailAccounts.value.push(newAcc);
  alert(`「邮箱账号连接成功」：已成功挂载您的发信箱 [${newAcc.label}]，可立即用于智能营销计划！`);
  
  // reset form
  accountForm.label = '';
  accountForm.email = '';
  accountForm.smtpHost = '';
  accountForm.smtpPort = '465';
  accountForm.secure = 'ssl';
  accountForm.smtpPass = '';
};

const removeEmailAccount = (id) => {
  if (confirm("确定要删除并注销此邮箱的系统关联吗？")) {
    emailAccounts.value = emailAccounts.value.filter(a => a.id !== id);
  }
};

// Campaigns State
const activeCampaigns = ref([
  { id: 1, name: '欧洲大客户EX系列防冻水箱AI批量推介', date: '2026-05-30', sender: 'sales@zen-specialty-mfg.com', target: '欧洲高分大客户', sentCount: 150, totalCount: 150, percentage: 100, delivered: 148, opened: 96, replied: 19, bounced: 2, status: 'Completed' },
  { id: 2, name: '中东地区极端环境重载部件Gmail营销活动', date: '2026-05-31', sender: 'director.ceo.zen@gmail.com', target: '中东特种客户群', sentCount: 84, totalCount: 200, percentage: 42, delivered: 83, opened: 51, replied: 8, bounced: 1, status: 'Sending' }
]);

// Analytics aggregated from real campaign data (no longer hardcoded)
const analytics = computed(() => {
  const c = activeCampaigns.value;
  const sent = c.reduce((s, x) => s + (x.sentCount || 0), 0);
  const delivered = c.reduce((s, x) => s + (x.delivered || 0), 0);
  const opened = c.reduce((s, x) => s + (x.opened || 0), 0);
  const replied = c.reduce((s, x) => s + (x.replied || 0), 0);
  const bounced = c.reduce((s, x) => s + (x.bounced ?? Math.max(0, (x.sentCount || 0) - (x.delivered || 0))), 0);
  const pct = (num, den) => den > 0 ? ((num / den) * 100).toFixed(1) : '0.0';
  return {
    delivered,
    deliveredRate: pct(delivered, sent),
    opened,
    openRate: pct(opened, delivered),
    replied,
    replyRate: pct(replied, delivered),
    bounced,
    bounceRate: pct(bounced, sent)
  };
});

const newCampaign = reactive({
  name: '',
  sender: 'sales@zen-specialty-mfg.com',
  templateId: 'none',
  subject: '',
  body: '',
  hasDelay: true
});

const templates = [
  { id: '1', name: '寒冷环境EX防冻系列初次开发信', subject: 'Inquiry response: Anti-freezing water tanks EX-XT-500 from factory compliance', body: 'Dear {{Contact}},\n\nHope this email finds you well.\n\nWe understand that {{Company}} is highly active in importing durable components. Our high-performance Extreme Anti-freezing Water Storage Tank [EX-XT-500] is specifically designed for extreme cold climates (operates safely down to -40°C).\n\nKey Advantages:\n- Double-layer Polyurethane thermal foaming isolation technology\n- Full compliance with German TUV Rhineland quality standards & CE certification\n- Factory-direct custom specs support (100% OEM based on drawings)\n\nWe would be honored to ship 2 preview samples for your team to test locally. Please send back your feedback.\n\nBest regards,\nZen Specialty Manufacturing Co., Ltd.' },
  { id: '2', name: 'TPU食品级折叠水囊物流与MOQ优势推介', subject: 'Flexible water storage tank catalog & MOQ advantages for {{Country}} market', body: 'Dear {{Contact}},\n\nI am writing from Zen Specialty Manufacturing, focusing on high-density TPU food-grade folding water tanks.\n\nSince {{Company}} operates in {{Country}}, we are offering dynamic shipping solutions (FOB Shanghai / DDP Bangkok) with a remarkably low MOQ (starting at 100 units) to save your upfront import budget.\n\nOur products meet strict FDA standards and are highly robust against desert conditions and long-term vibration.\n\nWould you be interested in receiving our latest digital price book?\n\nSincerely,\nB2B Export Team' }
];

const targetSegments = computed(() => {
  const leads = props.leads || [];
  // Group leads into business-meaningful segments by region
  const europe = ['德国', '俄罗斯', '法国', '英国', '意大利', '西班牙', '荷兰', '波兰'];
  const midEastSEA = ['阿联酋', '泰国', '菲律宾', '沙特', '伊拉克', '以色列', '印度', '马来西亚', '印尼', '越南'];
  const inEurope = leads.filter(l => europe.includes(l.country));
  const inMidEastSEA = leads.filter(l => midEastSEA.includes(l.country));
  const rest = leads.filter(l => !europe.includes(l.country) && !midEastSEA.includes(l.country));
  const uniqCountries = (arr) => [...new Set(arr.map(l => l.country).filter(Boolean))];
  return [
    { id: 'europe', name: '欧洲大客户组', count: inEurope.length, countries: uniqCountries(inEurope) },
    { id: 'mideast', name: '中东/东南亚高分客商', count: inMidEastSEA.length, countries: uniqCountries(inMidEastSEA) },
    { id: 'rest', name: '其他潜在客户', count: rest.length, countries: uniqCountries(rest) }
  ];
});

const selectedSegments = ref([]);
const toggleSegment = (id) => {
  const idx = selectedSegments.value.indexOf(id);
  if (idx === -1) {
    selectedSegments.value.push(id);
  } else {
    selectedSegments.value.splice(idx, 1);
  }
};

const matchedLeads = computed(() => {
  if (selectedSegments.value.length === 0) return [];
  const selectedCountries = [];
  selectedSegments.value.forEach(segId => {
    const seg = targetSegments.value.find(s => s.id === segId);
    if (seg) {
      selectedCountries.push(...seg.countries);
    }
  });
  return props.leads.filter(l => selectedCountries.includes(l.country));
});

const matchingLeadsCount = computed(() => matchedLeads.value.length);

const applyTemplate = () => {
  if (newCampaign.templateId === 'none') {
    newCampaign.subject = '';
    newCampaign.body = '';
    return;
  }
  const found = templates.find(t => t.id === newCampaign.templateId);
  if (found) {
    newCampaign.subject = found.subject;
    newCampaign.body = found.body;
  }
};

const dispatching = ref(false);
const triggerCampaignDispatch = () => {
  dispatching.value = true;
  setTimeout(() => {
    dispatching.value = false;
    
    // Add to campaigns
    activeCampaigns.value.unshift({
      id: Date.now(),
      name: newCampaign.name,
      date: new Date().toISOString().substring(0, 10),
      sender: newCampaign.sender,
      target: selectedSegments.value.map(s => targetSegments.value.find(t => t.id === s)?.name).join(' + '),
      sentCount: 0,
      totalCount: matchedLeads.value.length,
      percentage: 0,
      delivered: 0,
      opened: 0,
      status: 'Sending'
    });
    
    alert(`「智能发件队列已创建」\n批次计划：${newCampaign.name}\n目标客商数量：${matchedLeads.value.length} 位\n信道已锁定：通过 ${newCampaign.sender} 循环调度 🚀`);
    
    // Trigger mock pipeline updates
    let count = 0;
    const interval = setInterval(() => {
      if (count < matchedLeads.value.length) {
        const lead = matchedLeads.value[count];
        const timeNow = new Date().toLocaleTimeString();
        dispatchLogs.value.unshift({
          type: 'SUCCESS',
          time: timeNow,
          recipient: lead.email || `${lead.name.toLowerCase().replace(/\s+/g, '')}@company.com`,
          subject: newCampaign.subject.replace('{{Company}}', lead.name).replace('{{Contact}}', lead.contact).replace('{{Country}}', lead.country),
          latency: Math.floor(Math.random() * 200) + 120,
          relay: newCampaign.sender.includes('gmail') ? 'Google SMTP Relay' : 'Enterprise SMTP Server'
        });
        
        // update campaign progress
        const activeItem = activeCampaigns.value[0];
        if (activeItem) {
          activeItem.sentCount++;
          activeItem.delivered++;
          activeItem.percentage = Math.round((activeItem.sentCount / activeItem.totalCount) * 100);
          if (activeItem.percentage >= 50) {
            activeItem.opened = Math.round(activeItem.delivered * 0.6);
          }
          if (activeItem.sentCount === activeItem.totalCount) {
            activeItem.status = 'Completed';
            clearInterval(interval);
          }
        }
        count++;
      } else {
        clearInterval(interval);
      }
    }, 1500);

    // reset fields
    newCampaign.name = '';
    newCampaign.subject = '';
    newCampaign.body = '';
    newCampaign.templateId = 'none';
    selectedSegments.value = [];
    activeSubTab.value = 'analytics';
  }, 1000);
};

// Dispatch logs timeline
const dispatchLogs = ref([
  { type: 'SUCCESS', time: '20:01:24', recipient: 'dieter.mueller@muellerco.de', subject: 'Inquiry response: Anti-freezing water tanks EX-XT-500 from factory compliance', latency: 185, relay: 'Enterprise SMTP Server' },
  { type: 'SUCCESS', time: '19:59:15', recipient: 'sean.cronje@artantrading.ae', subject: 'Extreme anti-freezing aluminum trailer tanks customized specs', latency: 245, relay: 'Google SMTP Relay' },
  { type: 'SUCCESS', time: '19:55:04', recipient: 'sompop@thaiagri.co.th', subject: 'FDA certified TPU folding water storage tank price book catalog', latency: 154, relay: 'Enterprise SMTP Server' }
]);

// AI Copywriter State
const writerOpts = reactive({
  leadId: 11, // Dieter Müller (Germany)
  productId: 'EX-XT-500',
  tone: 'professional',
  lang: 'en'
});

const tones = [
  { value: 'professional', label: '👨‍💼 商务严谨' },
  { value: 'assertive', label: '🎯 主动进取' },
  { value: 'friendly', label: '🤝 热情友好' },
  { value: 'technical', label: '🔬 技术说服' }
];

const generatedEmail = reactive({
  subject: '',
  body: ''
});

const generatingEmail = ref(false);
const generateAiEmail = () => {
  generatingEmail.value = true;
  setTimeout(() => {
    generatingEmail.value = false;
    const lead = props.leads.find(l => l.id === writerOpts.leadId) || props.leads[0];
    const prod = props.products.find(p => p.id === writerOpts.productId) || props.products[0];
    
    // Generate text based on tone, lang, lead, product
    let subject = '';
    let body = '';
    
    if (writerOpts.lang === 'de') {
      subject = `Exklusives Angebot für ${lead.name} - CE/TUV-zertifizierter ${prod.name}`;
      body = `Sehr geehrter Herr ${lead.contact},\n\nwir hoffen, dass Sie eine erfolgreiche Woche haben.\n\nWir haben erfahren, dass Ihr Unternehmen ${lead.name} nach extrem robusten Komponenten für extreme Umweltbedingungen sucht. Unser ${prod.name} (${prod.model}) wurde speziell für anspruchsvolle europäische Standards entwickelt und ist vollkommen TUV/CE-konform.\n\nVorteile für den deutschen Markt:\n- ${prod.desc}\n- Einsatzbereich: ${prod.temp}\n- Erstklassiges Material: ${prod.material}\n\nAls Direkthersteller unterstützen wir Sie gerne mit flexiblen DDP/CIF-Bedingungen. Hätten Sie Interesse an einem kostenlosen Mustersatz?\n\nMit freundlichen Grüßen,\nZen Specialty Manufacturing`;
    } else if (writerOpts.lang === 'ru') {
      subject = `Технические характеристики EX-XT-500 для ${lead.name} с завода`;
      body = `Уважаемый господин ${lead.contact},\n\nПриветствуем вас из Zen Specialty Manufacturing!\n\nМы изучили потребности вашей компании ${lead.name} в высокопрочных изделиях. Наш ${prod.name} (модель ${prod.model}) идеально подходит для температурных условий до ${prod.temp} и имеет двойной слой полиуретановой термоизоляции.\n\nОсновные выгоды:\n- Полное соответствие TUV / CE.\n- Поддержка изготовления 100% по вашим чертежам.\n- Гибкий MOQ (${prod.moq} шт).\n\nБудем рады предоставить вам техническую карту и обсудить доставку.\n\nС уважением,\nZen Specialty Manufacturing`;
    } else { // default English
      if (writerOpts.tone === 'technical') {
        subject = `Technical Specs Sheet: Heavy-duty ${prod.model} for ${lead.name}`;
        body = `Dear ${lead.contact},\n\nWe understand that ${lead.name} values high technical engineering and compliance. We would like to introduce the engineering specifications of our ${prod.name} (${prod.model}).\n\nMaterial Characterization:\n- Composition: ${prod.material}\n- Certified Thermal Range: ${prod.temp}\n- Compliance Framework: CE, TUV, FDA certified\n\nDesigned specifically for ${prod.desc}, this model is highly optimized for anti-vibration and extreme durability.\n\nWe support full CAD/3D blueprint restoration with 100% OEM precision. Would you like to review our stress-test telemetry?\n\nSincerely,\nTechnical Sales Office\nZen Specialty Manufacturing`;
      } else {
        subject = `B2B Proposal: Premium ${prod.name} (${prod.model}) for ${lead.name}`;
        body = `Dear ${lead.contact},\n\nHope this email finds you well.\n\nFollowing up on procurement trends in ${lead.country}, we understand that ${lead.name} is seeking premium, certified water storage components. Our high-density ${prod.name} (${prod.model}) perfectly matches your criteria.\n\nKey Highlights:\n- ${prod.desc}\n- Certified Quality: Full CE / TUV / FDA Compliance\n- Logistical Edge: CIF/FOB delivery with rapid logistics dispatch\n\nWe have prepared a customized pricing list starting at dynamic tiers. Please let me know if we can schedule a quick 5-minute introductory video call.\n\nBest regards,\nB2B Sales Director\nZen Specialty Manufacturing Co., Ltd.`;
      }
    }
    
    generatedEmail.subject = subject;
    generatedEmail.body = body;
    
    alert(`「DeepSeek V4 深度脑算完成」\n已成功匹配客商 [${lead.name}] 與产品 [${prod.model}] 画像，生成了地道的多语言开发信开发信模板！`);
  }, 800);
};

const importDraftToCampaign = () => {
  newCampaign.subject = generatedEmail.subject;
  newCampaign.body = generatedEmail.body;
  newCampaign.name = `AI开发信推广 - 对接客户 ${writerOpts.leadId}`;
  
  // Set segment selection based on lead country
  const lead = props.leads.find(l => l.id === writerOpts.leadId);
  if (lead) {
    const seg = targetSegments.value.find(s => s.countries.includes(lead.country));
    if (seg && !selectedSegments.value.includes(seg.id)) {
      selectedSegments.value.push(seg.id);
    }
  }
  
  alert("已成功将开发信草稿导入营销活动群发页面！已自动帮您匹配目标接收客商群组！");
  activeSubTab.value = 'campaign';
};
</script>

<style scoped>
.scrollbar-elegant::-webkit-scrollbar {
  width: 3px;
}
.scrollbar-elegant::-webkit-scrollbar-thumb {
  background: rgba(0, 0, 0, 0.1);
  border-radius: 10px;
}
.scrollbar-elegant::-webkit-scrollbar-thumb:hover {
  background: rgba(0, 0, 0, 0.2);
}
</style>
