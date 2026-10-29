<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10 select-none">
    <!-- Header banner -->
    <div class="apple-glass rounded-2xl p-6 relative overflow-hidden">
      <div class="absolute inset-0 bg-gradient-to-br from-[#627254]/[0.02] to-transparent pointer-events-none"></div>
      <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 relative z-10">
        <div>
          <h2 class="text-lg font-bold font-serif-sc tracking-wider text-zen-ink flex items-center gap-2">
            📚 智能多模态知识仓库与云端互联
          </h2>
          <p class="text-[11px] text-zen-gray mt-1 font-serif-sc">
            对本地产品、行业及营销资产执行语义切片并编译向量，秒速同步 Notion 和 GitHub 云端库，为 AI 智能决策和自动化营销提供即时背景支撑。
          </p>
        </div>
      </div>

      <!-- Stats Cards -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6">
        <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between">
          <span class="text-[9px] text-zen-gray font-bold uppercase tracking-wider">本地向量切片总量 (Chunks)</span>
          <span class="text-xl font-bold font-mono text-zen-ink mt-1">
            {{ totalChunks }} <span class="text-[9px] font-normal text-zen-gray ml-0.5">个</span>
          </span>
        </div>
        <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between">
          <span class="text-[9px] text-zen-gray font-bold uppercase tracking-wider">多云互联状态 (Notion / Git)</span>
          <span class="text-xs font-bold text-indigo-600 mt-2 flex items-center gap-1.5">
            <span class="w-2 h-2 rounded-full bg-zen-green animate-pulse"></span>
            已建立双向握手
          </span>
        </div>
        <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between">
          <span class="text-[9px] text-zen-gray font-bold uppercase tracking-wider">最近向量编译更新</span>
          <span class="text-xs font-bold font-mono text-zen-green mt-2">{{ lastSyncTime }}</span>
        </div>
        <div class="p-3.5 rounded-xl border border-white/40 bg-white/20 shadow-sm flex flex-col justify-between">
          <span class="text-[9px] text-zen-gray font-bold uppercase tracking-wider">物理沙箱安全级别</span>
          <span class="text-xs font-bold text-zen-green mt-2 flex items-center gap-1">
            <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
            ChromaDB 本地安全防护
          </span>
        </div>
      </div>
    </div>

    <!-- Category Tabs Selector Card -->
    <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4">
      <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-black/[0.06] pb-4">
        <div>
          <h3 class="text-xs font-bold text-zen-ink flex items-center gap-2">
            <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
            🗂️ 知识分类脑图管理
          </h3>
          <p class="text-[9px] text-zen-gray mt-0.5">切换不同的专业维度对外贸专有知识库执行维护增删。</p>
        </div>
        <button
          @click="openAddEntryModal"
          class="px-3.5 py-1.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-[10px] font-bold shadow-sm transition-all flex items-center gap-1 active:scale-[0.97] outline-none"
        >
          ＋ 新录入知识条目
        </button>
      </div>

      <!-- Tab headers -->
      <div class="flex flex-wrap gap-1.5 p-1 bg-black/[0.04] rounded-2xl border border-black/[0.02]">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          class="flex-1 min-w-[90px] py-2 px-3 rounded-xl text-[10px] font-bold transition-all duration-300 outline-none flex flex-col items-center justify-center gap-0.5"
          :class="activeTab === tab.id ? 'bg-white text-zen-ink shadow-sm border border-black/[0.03]' : 'text-zen-gray hover:text-zen-ink'"
        >
          <span>{{ tab.label }}</span>
        </button>
      </div>

      <!-- Active Tab Description -->
      <div class="p-3 bg-white/40 rounded-xl border border-white/50 text-[10px] text-zen-gray italic select-text flex justify-between items-center">
        <span>📌 当前分类定位: {{ tabs.find(t => t.id === activeTab)?.desc }}</span>
        <span class="font-mono not-italic font-bold text-zen-green bg-zen-green/10 px-2 py-0.5 rounded-md">
          已编译 {{ filteredItems.length }} 条
        </span>
      </div>

      <!-- Filtered knowledge items list -->
      <div class="space-y-3 max-h-[300px] overflow-y-auto pr-1">
        <div
          v-for="item in filteredItems"
          :key="item.id"
          class="p-4 bg-white/50 hover:bg-white/80 border border-white/60 rounded-2xl shadow-sm transition-all duration-300 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 relative group"
        >
          <div class="space-y-1.5 flex-1 pr-4">
            <h4 class="text-xs font-bold text-indigo-950 flex items-center gap-1.5">
              <span class="w-1.5 h-1.5 rounded-full bg-indigo-500"></span>
              {{ item.title }}
            </h4>
            <p class="text-[10px] leading-relaxed text-zen-gray font-serif-sc whitespace-pre-wrap select-text">
              {{ item.content }}
            </p>
          </div>
          <div class="flex sm:flex-col items-end gap-1.5 select-none shrink-0 self-stretch justify-between sm:justify-center border-t sm:border-t-0 border-black/[0.03] pt-2 sm:pt-0">
            <span class="text-[8px] text-zen-gray font-mono bg-black/[0.04] px-2 py-0.5 rounded-md">
              更新于 {{ item.date }}
            </span>
            <button
              @click="deleteItem(item.id)"
              class="text-[9px] text-zen-crimson hover:underline opacity-0 group-hover:opacity-100 transition-opacity outline-none"
            >
              删除条目
            </button>
          </div>
        </div>
        <div v-if="!filteredItems.length" class="py-12 text-center text-zen-gray text-xs italic bg-white/20 border border-dashed border-white/60 rounded-2xl">
          暂无此维度的本地知识内容，请点击上方“新录入知识条目”或执行云端同步。
        </div>
      </div>
    </div>

    <!-- Main Ingestion Columns -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      
      <!-- Left Column: Ingest Local Documents -->
      <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4 flex flex-col justify-between">
        <div class="space-y-4">
          <h3 class="text-xs font-bold text-zen-ink flex items-center gap-2">
            <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
            📥 本地文档语义切片与向量入库 (Local Documents Ingestion)
          </h3>
          
          <div class="space-y-3.5 text-xs">
            <!-- Text Input area -->
            <div class="space-y-1.5">
              <div class="flex justify-between items-center">
                <label class="block text-[10px] text-zen-gray font-bold">粘贴产品文字或知识段落</label>
                <select
                  v-model="manualIngestTab"
                  class="bg-white/50 border border-white/60 rounded-lg px-2 py-0.5 text-[8px] font-bold outline-none focus:bg-white focus:border-zen-green"
                >
                  <option v-for="t in tabs" :key="t.id" :value="t.id">{{ t.label.split(' ')[1] }}</option>
                </select>
              </div>
              <textarea
                v-model="localTextToIngest"
                rows="4"
                placeholder="请在此粘贴需要 AI 学习的产品参数、售后指导或海关规定内容。AI 会自动将其切片并进行语义嵌入计算..."
                class="w-full bg-white/40 border border-white/60 rounded-2xl p-3 outline-none focus:bg-white focus:border-zen-green transition-all leading-relaxed text-[11px]"
              ></textarea>
            </div>

            <!-- Drag and Drop emulation -->
            <div class="space-y-1.5">
              <label class="block text-[10px] text-zen-gray font-bold">或者直接拖拽本地 PDF / DOCX 资产</label>
              <div
                @click="triggerFileSelect"
                class="border-2 border-dashed border-white/80 hover:border-zen-green bg-white/20 hover:bg-white/40 rounded-2xl py-5 text-center cursor-pointer transition-all duration-300 relative select-none"
              >
                <span class="text-xl mb-1 block">📄</span>
                <span class="text-[10px] font-bold text-zen-ink">点击选择或拖拽产品彩页/规格说明书文件</span>
                <p class="text-[8px] text-zen-gray mt-0.5">支持扩展名：.pdf, .docx, .xlsx, .txt (文件最大 10MB)</p>
                <input type="file" ref="fileInputRef" @change="handleFileSelected" class="hidden" accept=".pdf,.docx,.xlsx,.txt" />
              </div>
              
              <div v-if="selectedFileName" class="flex items-center justify-between p-2.5 bg-white/60 border border-white/80 rounded-xl mt-2 animate-fadeIn text-[10px]">
                <span class="truncate font-semibold text-zen-ink">📎 {{ selectedFileName }}</span>
                <button @click="clearSelectedFile" class="text-zen-crimson hover:underline font-bold">清除</button>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-4 space-y-4">
          <div class="flex justify-end">
            <button
              @click="ingestLocalData"
              :disabled="isIngestingLocal || (!localTextToIngest.trim() && !selectedFileName)"
              class="px-5 py-2.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-xs font-bold shadow-md transition-all active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed outline-none flex items-center gap-1.5"
            >
              <span>⚙️</span>
              <span>{{ isIngestingLocal ? 'AI 语义编译切片中...' : 'AI 一键语义切片并编译入库' }}</span>
            </button>
          </div>

          <!-- Simulated terminal progress log -->
          <transition
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="transform scale-95 opacity-0"
            enter-to-class="transform scale-100 opacity-100"
          >
            <div v-if="showIngestLogs" class="bg-black/90 border border-white/10 rounded-2xl p-4 font-mono text-[9px] text-green-400 space-y-1 max-h-36 overflow-y-auto shadow-inner">
              <div class="flex justify-between items-center text-zen-gray border-b border-white/10 pb-1 mb-1.5 select-none">
                <span>TERMINAL: chroma-ingest-engine</span>
                <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
              </div>
              <div v-for="(line, idx) in ingestTerminalLines" :key="idx" class="leading-relaxed">
                {{ line }}
              </div>
              <div v-if="isIngestingLocal" class="inline-flex items-center gap-1">
                <span class="inline-block w-1 h-2.5 bg-green-400 animate-pulse"></span>
                <span>数据切片向量计算中...</span>
              </div>
            </div>
          </transition>
        </div>
      </div>

      <!-- Right Column: Cloud Document Connector (Notion & GitHub switcher) -->
      <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4 flex flex-col justify-between">
        <div class="space-y-4">
          <div class="flex justify-between items-center border-b border-black/[0.06] pb-3">
            <h3 class="text-xs font-bold text-zen-ink flex items-center gap-2">
              <span class="w-1.5 h-3 bg-purple-500 rounded-full"></span>
              ☁️ 多平台云端文档库同步中心
            </h3>
            
            <!-- Connection Mode Switcher -->
            <div class="flex bg-black/[0.06] p-0.5 rounded-lg text-[9px] font-bold select-none border border-black/[0.02]">
              <button
                @click="cloudProvider = 'notion'"
                class="px-2.5 py-1 rounded"
                :class="cloudProvider === 'notion' ? 'bg-white shadow-sm text-purple-700' : 'text-zen-gray hover:text-zen-ink'"
              >
                Notion
              </button>
              <button
                @click="cloudProvider = 'github'"
                class="px-2.5 py-1 rounded"
                :class="cloudProvider === 'github' ? 'bg-white shadow-sm text-indigo-700' : 'text-zen-gray hover:text-zen-ink'"
              >
                GitHub
              </button>
            </div>
          </div>

          <div class="space-y-3.5 text-xs">
            <!-- Notion Connection form -->
            <div class="p-4 bg-white/20 border border-white/40 rounded-2xl space-y-3 animate-fadeIn" v-if="cloudProvider === 'notion'">
              <div class="space-y-1">
                <label class="block text-[9px] text-zen-gray font-bold">Notion Integration Token (集成密钥)</label>
                <input
                  type="password"
                  v-model="notionToken"
                  placeholder="secret_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                  class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
                />
              </div>
              
              <div class="grid grid-cols-2 gap-3">
                <div class="space-y-1">
                  <label class="block text-[9px] text-zen-gray font-bold">Database ID (数据盘ID)</label>
                  <input
                    type="text"
                    v-model="notionDatabaseId"
                    placeholder="32位数据库 Hash ID..."
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
                  />
                </div>
                <div class="space-y-1">
                  <label class="block text-[9px] text-zen-gray font-bold">Page ID (独立页面ID - 选填)</label>
                  <input
                    type="text"
                    v-model="notionPageId"
                    placeholder="可选填..."
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
                  />
                </div>
              </div>
            </div>

            <!-- GitHub Connection form -->
            <div class="p-4 bg-white/20 border border-white/40 rounded-2xl space-y-3 animate-fadeIn" v-else>
              <div class="space-y-1">
                <label class="block text-[9px] text-zen-gray font-bold">GitHub Repository (文档仓库链接)</label>
                <input
                  type="text"
                  v-model="githubRepo"
                  placeholder="ZenSpecialty/ForeignTrade-KB"
                  class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
                />
              </div>
              
              <div class="grid grid-cols-2 gap-3">
                <div class="space-y-1">
                  <label class="block text-[9px] text-zen-gray font-bold">Branch (拉取分支)</label>
                  <input
                    type="text"
                    v-model="githubBranch"
                    placeholder="main"
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
                  />
                </div>
                <div class="space-y-1">
                  <label class="block text-[9px] text-zen-gray font-bold">Personal Access Token (个人访问令牌)</label>
                  <input
                    type="password"
                    v-model="githubToken"
                    placeholder="github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxx"
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="pt-4 space-y-4">
          <div class="flex justify-between items-center text-[9px] text-zen-gray select-none gap-2">
            <span>自动解析拉取的文件树结构并将其导入 ChromaDB 本地向量库中</span>
            <button
              @click="syncCloudDocs"
              :disabled="isSyncingCloud || (cloudProvider === 'notion' && !notionToken) || (cloudProvider === 'github' && !githubRepo)"
              class="px-5 py-2.5 bg-purple-600 hover:bg-purple-700 text-white rounded-xl text-xs font-bold shadow-md transition-all active:scale-95 disabled:opacity-40 disabled:cursor-not-allowed outline-none flex items-center gap-1.5 shrink-0"
            >
              <span>🔄</span>
              <span>{{ isSyncingCloud ? '正在同步云端内容...' : '一键极速抓取并同步云端知识' }}</span>
            </button>
          </div>

          <!-- Simulated Notion/GitHub Sync Logs -->
          <transition
            enter-active-class="transition duration-300 ease-out"
            enter-from-class="transform scale-95 opacity-0"
            enter-to-class="transform scale-100 opacity-100"
          >
            <div v-if="showCloudLogs" class="bg-black/90 border border-white/10 rounded-2xl p-4 font-mono text-[9px] text-purple-400 space-y-1 max-h-36 overflow-y-auto shadow-inner">
              <div class="flex justify-between items-center text-zen-gray border-b border-white/10 pb-1 mb-1.5 select-none">
                <span>TERMINAL: cloud-sync-service</span>
                <span class="w-1.5 h-1.5 rounded-full animate-pulse" :class="cloudProvider === 'notion' ? 'bg-purple-500' : 'bg-indigo-500'"></span>
              </div>
              <div v-for="(line, idx) in cloudTerminalLines" :key="idx" class="leading-relaxed">
                {{ line }}
              </div>
              <div v-if="isSyncingCloud" class="inline-flex items-center gap-1">
                <span class="inline-block w-1 h-2.5 bg-purple-400 animate-pulse"></span>
                <span>抓取并解析 Markdown 文件切片中...</span>
              </div>
            </div>
          </transition>
        </div>
      </div>

    </div>

    <!-- AI Marketing Anchoring Hub (知识脑图动态注入面板) -->
    <div class="apple-glass rounded-3xl p-6 border border-white/50 space-y-4">
      <div>
        <h3 class="text-xs font-bold text-zen-ink flex items-center gap-2">
          <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
          🧠 AI 智能营销与知识库关联注入 (Dynamic Knowledge Injection)
        </h3>
        <p class="text-[9px] text-zen-gray mt-0.5">
          这是管理知识库并在 AI 营销中灵活调用的最佳方式！在此为每个外贸动作绑定不同的知识分类，AI 在执行该动作时会自动检索并装载对应分类的知识切片作为背景增强（RAG），让回答始终基于你的真实产品与业务资料。
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div class="p-4 bg-white/30 border border-white/50 rounded-2xl space-y-3.5 shadow-sm hover:translate-y-[-2px] transition-all duration-300">
          <div class="flex justify-between items-center">
            <span class="text-[10px] font-bold text-indigo-950">📩 邮件营销与开发信 (Email Marketing)</span>
            <span class="w-2 h-2 rounded-full bg-zen-green animate-pulse"></span>
          </div>
          <div class="space-y-1.5 text-xs">
            <label class="block text-[8px] text-zen-gray font-bold uppercase tracking-wider">绑定关联知识脑图</label>
            <select
              v-model="marketingAnchors.emailGen"
              class="w-full bg-white/60 border border-white/60 rounded-xl px-3 py-2 text-[10px] font-bold outline-none focus:bg-white focus:border-zen-green"
            >
              <option v-for="t in tabs" :key="t.id" :value="t.id">{{ t.label }}</option>
            </select>
          </div>
          <p class="text-[9px] text-zen-gray leading-relaxed font-serif-sc">
            AI 编写营销开发信时，将自动注入绑定的知识。推荐绑定 <strong class="text-indigo-600">✍️ 营销话术</strong>，装载最佳开发信和痛点模板。
          </p>
        </div>

        <div class="p-4 bg-white/30 border border-white/50 rounded-2xl space-y-3.5 shadow-sm hover:translate-y-[-2px] transition-all duration-300">
          <div class="flex justify-between items-center">
            <span class="text-[10px] font-bold text-indigo-950">💰 外贸形式报价与谈判 (Smart Quotation)</span>
            <span class="w-2 h-2 rounded-full bg-zen-green animate-pulse"></span>
          </div>
          <div class="space-y-1.5 text-xs">
            <label class="block text-[8px] text-zen-gray font-bold uppercase tracking-wider">绑定关联知识脑图</label>
            <select
              v-model="marketingAnchors.quoteReply"
              class="w-full bg-white/60 border border-white/60 rounded-xl px-3 py-2 text-[10px] font-bold outline-none focus:bg-white focus:border-zen-green"
            >
              <option v-for="t in tabs" :key="t.id" :value="t.id">{{ t.label }}</option>
            </select>
          </div>
          <p class="text-[9px] text-zen-gray leading-relaxed font-serif-sc">
            AI 执行报价推荐及价格谈判审计时，自动校对规格成本。推荐绑定 <strong class="text-indigo-600">📦 产品参数</strong>，装载产品彩页及 MOQ 策略。
          </p>
        </div>

        <div class="p-4 bg-white/30 border border-white/50 rounded-2xl space-y-3.5 shadow-sm hover:translate-y-[-2px] transition-all duration-300">
          <div class="flex justify-between items-center">
            <span class="text-[10px] font-bold text-indigo-950">🔍 市场调研与客户决策 (Market Research)</span>
            <span class="w-2 h-2 rounded-full bg-zen-green animate-pulse"></span>
          </div>
          <div class="space-y-1.5 text-xs">
            <label class="block text-[8px] text-zen-gray font-bold uppercase tracking-wider">绑定关联知识脑图</label>
            <select
              v-model="marketingAnchors.marketResearch"
              class="w-full bg-white/60 border border-white/60 rounded-xl px-3 py-2 text-[10px] font-bold outline-none focus:bg-white focus:border-zen-green"
            >
              <option v-for="t in tabs" :key="t.id" :value="t.id">{{ t.label }}</option>
            </select>
          </div>
          <p class="text-[9px] text-zen-gray leading-relaxed font-serif-sc">
            AI 智能洞察客户询盘并生成深度 GTM 路线图时，引入政策保障。推荐绑定 <strong class="text-indigo-600">🌐 行业动态</strong>，装载海关与能效限制。
          </p>
        </div>
      </div>
    </div>

    <!-- Inline modal to Add manual knowledge entry -->
    <ZenModal :open="isAddEntryModalOpen" title="＋ 新增录入外贸专有知识脑图" @close="isAddEntryModalOpen = false">
      <div class="space-y-4 text-xs text-zen-ink">
        <div class="space-y-1.5">
          <label class="block font-bold">选择知识所处分类目录</label>
          <select
            v-model="newEntryForm.category"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
          >
            <option v-for="t in tabs" :key="t.id" :value="t.id">{{ t.label }}</option>
          </select>
        </div>

        <div class="space-y-1.5">
          <label class="block font-bold">知识条目标题名称</label>
          <input
            type="text"
            v-model="newEntryForm.title"
            placeholder="如 EX-XT-500 特种柔性折叠水囊能效指标"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green"
          />
        </div>

        <div class="space-y-1.5">
          <label class="block font-bold">知识核心内容详细参数</label>
          <textarea
            v-model="newEntryForm.content"
            rows="4"
            placeholder="详细录入此知识条目的核心要点，AI 会根据这些文本进行嵌入匹配，生成最符合商务的对答..."
            class="w-full bg-white/40 border border-white/60 rounded-xl p-3 text-xs outline-none focus:bg-white focus:border-zen-green leading-relaxed"
          ></textarea>
        </div>
      </div>
      <template #footer>
        <button
          @click="submitNewEntry"
          class="px-5 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          确认录入本地 ChromaDB 🚀
        </button>
        <button
          @click="isAddEntryModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          取消
        </button>
      </template>
    </ZenModal>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import ZenModal from './ZenModal.vue';

const totalChunks = ref(544);
const lastSyncTime = ref('2026-06-01 12:45');

const activeTab = ref('products');
const manualIngestTab = ref('products');

const tabs = [
  { id: 'products', label: '📦 产品参数', desc: '产品型号、规格参数、起订量及价格区间等' },
  { id: 'industry', label: '🌐 行业动态', desc: '行业研究、海关政策、市场准入门槛等' },
  { id: 'sourcing', label: '🎯 开发采购', desc: '新客开发话术、供应链合作模式、采购流程等' },
  { id: 'marketing', label: '✍️ 营销话术', desc: '开发信模板、跟进模板、痛点攻坚话术等' },
  { id: 'skills', label: '🛠️ 业务技能', desc: 'RAG 提示词技巧、常用外贸计算公式等' }
];

const knowledgeItems = ref({
  products: [
    { id: 'p1', title: 'EX-XT-500 特种柔性折叠水囊', content: '材质: 食品级 TPU; 温度范围: -40℃ ~ 70℃; 认证: FDA、CE、TUV; 起订量: 100个; 价格: $195 USD。', date: '2026-05-28' },
    { id: 'p2', title: 'EX-XT-300 加固型防爆底盘护甲', content: '材质: 赛车级镁铝合金; 厚度: 5.5mm; 规格: 匹配日本/德国全系重型越野赛车底盘; 抗冲击力: 120kJ; 价格: $420 USD。', date: '2026-05-29' }
  ],
  industry: [
    { id: 'i1', title: '德国 TUV 认证产品能效标识新规 (2026)', content: '德国联邦环保局要求自 2026 年起，所有进入欧盟的耐低温储水设备需具备 Class A 等级低耗能与零微塑排放标识。', date: '2026-05-25' },
    { id: 'i2', title: '菲律宾马尼拉港口清关关税与特别附加税', content: '汽车配件类进口申报税率维持在 7.2%，但对于重型改装件新增 1.5% 的港口维护基金附加税。', date: '2026-05-30' }
  ],
  sourcing: [
    { id: 's1', title: '高意向大客二级筛选漏斗标准', content: '1. 年采购额大于50万美元；2. 拥有自主设计/RAG 蓝图导入能力；3. 首次交易愿意接受 30% TT 预付首款。', date: '2026-05-18' }
  ],
  marketing: [
    { id: 'm1', title: '低起订量 (MOQ) 预算节约开发信模板', content: '主题: Flexible cargo solutions with 100 units low MOQ budget saver.\n正文突出前置采购预算节约，以及对 FOB 灵活多口岸交货的全面支持，大幅缩减贸易风险。', date: '2026-05-22' }
  ],
  skills: [
    { id: 'sk1', title: '外贸询盘多路 RAG 路由提示词模版', content: '系统角色定位：资深外贸精算师。任务：对询盘文本进行实体识别（产品、国家、规模），并返回匹配的 ChromaDB 向量参数。', date: '2026-05-20' }
  ]
});

// Dynamic filtering based on tab and searching queries
const searchQuery = ref('');
const filteredItems = computed(() => {
  const list = knowledgeItems.value[activeTab.value] || [];
  if (!searchQuery.value.trim()) return list;
  const q = searchQuery.value.toLowerCase();
  return list.filter(item =>
    item.title.toLowerCase().includes(q) ||
    item.content.toLowerCase().includes(q)
  );
});

// Local Document ingestion fields
const localTextToIngest = ref('');
const fileInputRef = ref(null);
const selectedFileName = ref('');
const selectedFileSize = ref('');
const isIngestingLocal = ref(false);
const showIngestLogs = ref(false);
const ingestTerminalLines = ref([]);

// Cloud Sync Connection Hub
const cloudProvider = ref('notion');
const notionToken = ref('secret_notion_integration_zen_manufacturing_2026');
const notionDatabaseId = ref('db_f8e1d79fce1306b267219f448e81d79f');
const notionPageId = ref('');

// GitHub connection fields
const githubRepo = ref('ZenSpecialty/ForeignTrade-KB');
const githubBranch = ref('main');
const githubToken = ref('github_pat_11AYW3ZJ0u78229skal129salkx');

const isSyncingCloud = ref(false);
const showCloudLogs = ref(false);
const cloudTerminalLines = ref([]);

// AI Marketing dynamic anchoring maps
const marketingAnchors = ref({
  emailGen: 'marketing',
  quoteReply: 'products',
  marketResearch: 'industry'
});

// --- [NEW] Persistence: load & save knowledge base + anchors to local storage / Electron ---
const KB_STORAGE_KEY = 'magichub_knowledge_base';
const KB_ANCHORS_KEY = 'magichub_knowledge_anchors';

const persistKnowledge = async () => {
  try {
    const payload = JSON.stringify(knowledgeItems.value);
    localStorage.setItem(KB_STORAGE_KEY, payload);
    localStorage.setItem(KB_ANCHORS_KEY, JSON.stringify(marketingAnchors.value));
    if (window.electronAPI?.saveSettings) {
      await window.electronAPI.saveSettings(KB_STORAGE_KEY, JSON.parse(JSON.stringify(knowledgeItems.value)));
      await window.electronAPI.saveSettings(KB_ANCHORS_KEY, JSON.parse(JSON.stringify(marketingAnchors.value)));
    }
  } catch (e) {
    console.error('[MagicHub] Failed to persist knowledge base:', e);
  }
};

const loadKnowledge = async () => {
  try {
    let savedItems = null;
    let savedAnchors = null;
    if (window.electronAPI?.loadSettings) {
      const resItems = await window.electronAPI.loadSettings(KB_STORAGE_KEY);
      if (resItems?.success && resItems.data) savedItems = resItems.data;
      const resAnchors = await window.electronAPI.loadSettings(KB_ANCHORS_KEY);
      if (resAnchors?.success && resAnchors.data) savedAnchors = resAnchors.data;
    }
    if (!savedItems) {
      const local = localStorage.getItem(KB_STORAGE_KEY);
      if (local) savedItems = JSON.parse(local);
    }
    if (!savedAnchors) {
      const localA = localStorage.getItem(KB_ANCHORS_KEY);
      if (localA) savedAnchors = JSON.parse(localA);
    }
    if (savedItems && typeof savedItems === 'object') {
      // Merge so newly added default categories still appear
      knowledgeItems.value = { ...knowledgeItems.value, ...savedItems };
    }
    if (savedAnchors && typeof savedAnchors === 'object') {
      marketingAnchors.value = { ...marketingAnchors.value, ...savedAnchors };
    }
  } catch (e) {
    console.error('[MagicHub] Failed to load knowledge base:', e);
  }
};

// Lightweight keyword retrieval used by the global AI bridge (simulated RAG recall)
const retrieveKnowledge = (queryText = '', categoryId = null, limit = 4) => {
  const q = String(queryText || '').toLowerCase();
  const pickFrom = categoryId && knowledgeItems.value[categoryId]
    ? [...knowledgeItems.value[categoryId]]
    : Object.values(knowledgeItems.value).flat();

  const scored = pickFrom.map(item => {
    const haystack = `${item.title} ${item.content}`.toLowerCase();
    let score = 0;
    if (q) {
      q.split(/[\s,，。、]+/).filter(w => w.length > 1).forEach(token => {
        if (haystack.includes(token)) score += 1;
      });
    }
    return { item, score };
  });

  const hasQuery = q.trim().length > 0;
  const filtered = hasQuery ? scored.filter(s => s.score > 0) : scored;
  filtered.sort((a, b) => b.score - a.score);
  const chosen = (filtered.length ? filtered : scored).slice(0, limit).map(s => s.item);
  return chosen;
};

// Build a system-prompt-ready knowledge context block for a given AI marketing scenario
const buildKnowledgeContext = (scenarioKey, queryText = '') => {
  // scenarioKey maps to marketingAnchors (emailGen / quoteReply / marketResearch); fallback: search all
  const categoryId = marketingAnchors.value[scenarioKey] || null;
  const items = retrieveKnowledge(queryText, categoryId, 4);
  if (!items.length) return '';
  const label = tabs.find(t => t.id === categoryId)?.label || '综合知识库';
  const lines = items.map((it, i) => `${i + 1}. 【${it.title}】${it.content}`).join('\n');
  return `以下是来自企业知识仓库「${label}」的相关背景资料，请在回答时优先参考这些事实：\n${lines}`;
};

// Expose the retrieval bridge globally so the floating AI assistant (App.vue) can inject knowledge
onMounted(() => {
  loadKnowledge();
  window.magichubKnowledge = {
    retrieve: retrieveKnowledge,
    buildContext: buildKnowledgeContext,
    getAnchors: () => ({ ...marketingAnchors.value }),
    getCategories: () => tabs.map(t => ({ id: t.id, label: t.label }))
  };
});

watch(knowledgeItems, persistKnowledge, { deep: true });
watch(marketingAnchors, persistKnowledge, { deep: true });

// Manual Knowledge Entry Modal
const isAddEntryModalOpen = ref(false);
const newEntryForm = ref({
  category: 'products',
  title: '',
  content: ''
});

const openAddEntryModal = () => {
  newEntryForm.value = {
    category: activeTab.value,
    title: '',
    content: ''
  };
  isAddEntryModalOpen.value = true;
};

const submitNewEntry = () => {
  const form = newEntryForm.value;
  if (!form.title.trim() || !form.content.trim()) {
    alert('请将标题和核心内容填写完整！');
    return;
  }
  
  const newItem = {
    id: 'custom_' + Date.now(),
    title: form.title,
    content: form.content,
    date: new Date().toISOString().substring(0, 10)
  };
  
  if (!knowledgeItems.value[form.category]) {
    knowledgeItems.value[form.category] = [];
  }
  
  knowledgeItems.value[form.category].unshift(newItem);
  totalChunks.value += 3; // Simulate向量切片编译
  lastSyncTime.value = new Date().toISOString().replace('T', ' ').substring(0, 16);
  
  isAddEntryModalOpen.value = false;
  alert('🚀 本地新增知识录入 ChromaDB 编译成功！该知识已被注入至 ' + tabs.find(t => t.id === form.category).label + '，AI 自动同步关联营销上下文。');
};

const deleteItem = (id) => {
  if (confirm('确认要在本地 ChromaDB 中删除该切片条目吗？删除后，AI 将不再检索此上下文。')) {
    const list = knowledgeItems.value[activeTab.value] || [];
    knowledgeItems.value[activeTab.value] = list.filter(item => item.id !== id);
    totalChunks.value -= 3;
    alert('已成功清除本地 ChromaDB 切片索引。');
  }
};

// Ingest local files selection triggers
const triggerFileSelect = () => {
  if (fileInputRef.value) {
    fileInputRef.value.click();
  }
};

const handleFileSelected = (event) => {
  const file = event.target.files[0];
  if (file) {
    selectedFileName.value = file.name;
    const kb = (file.size / 1024).toFixed(1);
    selectedFileSize.value = `${kb} KB`;
  }
};

const clearSelectedFile = () => {
  selectedFileName.value = '';
  selectedFileSize.value = '';
  if (fileInputRef.value) {
    fileInputRef.value.value = '';
  }
};

// Ingest local files pipeline execution
const ingestLocalData = () => {
  if (!localTextToIngest.value.trim() && !selectedFileName.value) return;
  
  isIngestingLocal.value = true;
  showIngestLogs.value = true;
  ingestTerminalLines.value = [];
  
  const addLog = (text, delay) => {
    return new Promise((resolve) => {
      setTimeout(() => {
        ingestTerminalLines.value.push(text);
        resolve();
      }, delay);
    });
  };

  const targetCategory = manualIngestTab.value;
  const targetLabel = tabs.find(t => t.id === targetCategory).label;

  Promise.resolve()
    .then(() => addLog('>> Initializing local document parser...', 300))
    .then(() => {
      if (selectedFileName.value) {
        return addLog(`>> Reading binary stream of physical file [${selectedFileName.value}] (${selectedFileSize.value})...`, 500);
      } else {
        return addLog('>> Scanning manual pasted text input stream (length: ' + localTextToIngest.value.length + ' chars)...', 500);
      }
    })
    .then(() => addLog('>> Executing RecursiveCharacterTextSplitter (chunkSize: 500, overlap: 50)...', 600))
    .then(() => addLog('>> Found 18 highly structured text fragments (chunks). Generating embeddings...', 600))
    .then(() => addLog('>> Sending chunks to local Llama3 embedding model (1536 dimensions)...', 800))
    .then(() => addLog('>> Embedding computation finished. Computing distance matrices...', 700))
    .then(() => addLog('>> Synchronizing collections with ChromaDB vector storage index...', 500))
    .then(() => addLog('>> [Success] 18 new vectors successfully synched to ChromaDB local storage!', 400))
    .then(() => {
      isIngestingLocal.value = false;
      totalChunks.value += 18;
      const now = new Date();
      lastSyncTime.value = now.getFullYear() + '-' + 
        String(now.getMonth() + 1).padStart(2, '0') + '-' + 
        String(now.getDate()).padStart(2, '0') + ' ' + 
        String(now.getHours()).padStart(2, '0') + ':' + 
        String(now.getMinutes()).padStart(2, '0');
      
      // Insert to reactive state
      const manualItem = {
        id: 'manual_' + Date.now(),
        title: selectedFileName.value ? `文件解析: ${selectedFileName.value}` : '手动录入产品规格',
        content: localTextToIngest.value.trim() || `基于拖拽文件 [${selectedFileName.value}] 生成切片向量，ChromaDB 语义匹配度 98%。`,
        date: now.toISOString().substring(0, 10)
      };
      
      if (!knowledgeItems.value[targetCategory]) {
        knowledgeItems.value[targetCategory] = [];
      }
      knowledgeItems.value[targetCategory].unshift(manualItem);
        
      localTextToIngest.value = '';
      clearSelectedFile();
      alert(`✨ 语义切片及向量编译成功！新导入的 18 条知识片段已完美保存并锚定至 [${targetLabel}]！`);
    });
};

// Sync Notion / GitHub Cloud Docs
const syncCloudDocs = () => {
  isSyncingCloud.value = true;
  showCloudLogs.value = true;
  cloudTerminalLines.value = [];
  
  const addLog = (text, delay) => {
    return new Promise((resolve) => {
      setTimeout(() => {
        cloudTerminalLines.value.push(text);
        resolve();
      }, delay);
    });
  };

  if (cloudProvider.value === 'notion') {
    Promise.resolve()
      .then(() => addLog('>> Initializing Notion Sync Connection client...', 300))
      .then(() => addLog('>> Sending request to Notion API: https://api.notion.com/v1/databases/' + notionDatabaseId.value + '/query...', 600))
      .then(() => addLog('>> Connection established. Handshake authorized (OAuth verified) 🟢', 400))
      .then(() => addLog('>> Found 5 associated Page Blocks inside the database. Pulling elements...', 700))
      .then(() => addLog('>> Converting Notion Blocks to clean Markdown structure...', 800))
      .then(() => addLog('>> Successfully pulled 5 documents: "卡车车顶帐篷安装规范", "HORNING-BUMPER 材质规格表" etc.', 600))
      .then(() => addLog('>> Running character splitting. Generated 32 document chunks.', 600))
      .then(() => addLog('>> Connecting to local embedding engine. Compiling vectors...', 700))
      .then(() => addLog('>> Synchronizing collections with ChromaDB vector storage index...', 500))
      .then(() => addLog('>> [Success] Sync Notion Docs successfully! 32 vectors added.', 400))
      .then(() => {
        isSyncingCloud.value = false;
        totalChunks.value += 32;
        const now = new Date();
        lastSyncTime.value = now.getFullYear() + '-' + 
          String(now.getMonth() + 1).padStart(2, '0') + '-' + 
          String(now.getDate()).padStart(2, '0') + ' ' + 
          String(now.getHours()).padStart(2, '0') + ':' + 
          String(now.getMinutes()).padStart(2, '0');
        
        // Push simulated sync pages to categories
        knowledgeItems.value.products.unshift({
          id: 'notion_1',
          title: 'Notion同步: HORNING-BUMPER 材质规格表',
          content: 'Notion云数据库拉取：钢质防撞前杠规格，抗拉强度 >= 520MPa，带双绞盘定位支架。',
          date: now.toISOString().substring(0, 10)
        });
        
        knowledgeItems.value.industry.unshift({
          id: 'notion_2',
          title: 'Notion同步: 卡车车顶帐篷安装规范',
          content: 'Notion云数据库拉取：防雨性能 A 级，抗风等级 8 级，清关需具备 ISO9001 溯源认证。',
          date: now.toISOString().substring(0, 10)
        });
          
        alert('✨ Notion 云端数据库同步成功！已抓取并编译 32 条 Markdown 知识片段至 ChromaDB 本地库！');
      });
  } else {
    // GitHub Sync
    Promise.resolve()
      .then(() => addLog('>> Initializing Git Connector repository handler...', 300))
      .then(() => addLog(`>> Cloning remote repository: https://github.com/${githubRepo.value}.git [branch: ${githubBranch.value}]...`, 800))
      .then(() => addLog('>> Handshake authorized. Fetching latest commit files...', 500))
      .then(() => addLog('>> Downloaded 8 markdown documents from Git tree directory...', 600))
      .then(() => addLog('>> Executing Git diff parsing and document metadata loading...', 600))
      .then(() => addLog('>> Chunking Markdown contents. Generated 45 document chunks.', 500))
      .then(() => addLog('>> Compiling Git knowledge index to local Llama3 embedding model...', 800))
      .then(() => addLog('>> [Success] GitHub remote repository synced successfully! 45 vectors added.', 400))
      .then(() => {
        isSyncingCloud.value = false;
        totalChunks.value += 45;
        const now = new Date();
        lastSyncTime.value = now.getFullYear() + '-' + 
          String(now.getMonth() + 1).padStart(2, '0') + '-' + 
          String(now.getDate()).padStart(2, '0') + ' ' + 
          String(now.getHours()).padStart(2, '0') + ':' + 
          String(now.getMinutes()).padStart(2, '0');
        
        // Push simulated git sync items
        knowledgeItems.value.skills.unshift({
          id: 'git_1',
          title: 'Git同步: B2B 外贸开发信黄金提示词工程规范',
          content: '从 ForeignTrade-KB 仓库拉取：外贸核心 RAG 邮件重构模版与提示词微调说明，含 24 种情景响应词。',
          date: now.toISOString().substring(0, 10)
        });
        
        knowledgeItems.value.marketing.unshift({
          id: 'git_2',
          title: 'Git同步: 赛车散热器询盘报价模板',
          content: '从 ForeignTrade-KB 仓库拉取：如何通过 FOB Shanghai 条件回应日本/马尼拉多口岸运费，提升赢单概率。',
          date: now.toISOString().substring(0, 10)
        });
        
        alert('✨ GitHub 远程文档仓库同步成功！已下载并切片编译 45 条 Git Markdown 知识条目至 ChromaDB 本地库！');
      });
  }
};
</script>

<style scoped>
/* Scrollbar overrides for high fidelity logs */
.scrollbar-elegant::-webkit-scrollbar {
  width: 4px;
}
.scrollbar-elegant::-webkit-scrollbar-track {
  background: transparent;
}
.scrollbar-elegant::-webkit-scrollbar-thumb {
  background: rgba(98, 114, 84, 0.2);
  border-radius: 9px;
}
.scrollbar-elegant::-webkit-scrollbar-thumb:hover {
  background: rgba(98, 114, 84, 0.4);
}
</style>
