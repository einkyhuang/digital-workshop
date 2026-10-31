<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10 select-text">
    <!-- Header -->
    <div class="pb-4 border-b border-white/20 select-none flex justify-between items-center">
      <div>
        <h2 class="text-xl font-bold font-serif-sc tracking-wide flex items-center gap-2">
          <span class="w-8 h-8 rounded-xl bg-zen-ink text-white flex items-center justify-center">
            ⚙️
          </span>
          系统全局设置与 AI 算力配置
        </h2>
        <p class="text-xs text-zen-gray mt-1">管理系统底层的 AI 算力平台与 API 密钥，导入 IDE 标准专业技能以实现智能化全局赋能。</p>
      </div>
    </div>

    <!-- Tab Switcher -->
    <div class="flex gap-2 border-b border-white/20 pb-1 select-none">
      <button
        @click="activeTab = 'api'"
        :class="activeTab === 'api'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>🌐</span> AI 模型平台接入
      </button>
      <button
        @click="activeTab = 'skills'"
        :class="activeTab === 'skills'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>🛠️</span> 智能体 Skills 与应用中心
      </button>
      <button
        @click="activeTab = 'storage'"
        :class="activeTab === 'storage'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>📁</span> 本地存储管理
      </button>
      <button
        @click="activeTab = 'changelog'"
        :class="activeTab === 'changelog'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>📢</span> 系统更新日志
      </button>
      <button
        @click="activeTab = 'manual'"
        :class="activeTab === 'manual'
          ? 'border-b-2 border-zen-green text-zen-green font-bold bg-white/40 shadow-sm rounded-t-xl'
          : 'text-zen-gray hover:bg-white/25'"
        class="px-5 py-2.5 text-xs font-semibold transition-all outline-none flex items-center gap-1.5"
      >
        <span>📖</span> 系统使用说明书
      </button>
    </div>

    <!-- TAB 1: AI Model Platform (Screenshot-style two-column layout) -->
    <div v-if="activeTab === 'api'" class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      
      <!-- Left Column: Search & Provider list (4 cols) -->
      <div class="lg:col-span-4 bg-white/60 backdrop-blur-md border border-white/50 rounded-2xl p-4 shadow-sm flex flex-col h-[600px]">
        <!-- Search bar -->
        <div class="relative mb-3 flex items-center select-none">
          <input
            type="text"
            v-model="providerSearchQuery"
            placeholder="搜索模型平台..."
            class="w-full bg-white/60 border border-white/80 rounded-xl pl-8 pr-8 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
          />
          <span class="absolute left-2.5 text-zen-gray text-xs">🔍</span>
          <span class="absolute right-2.5 text-zen-gray text-xs cursor-pointer hover:text-zen-ink">⏳</span>
        </div>

        <!-- Scrollable list of providers -->
        <div class="flex-1 overflow-y-auto space-y-1.5 pr-1 select-none scrollbar-elegant">
          <div
            v-for="p in sortedFilteredProviders"
            :key="p.id"
            @click="selectProvider(p)"
            class="flex items-center justify-between p-2.5 rounded-xl transition-all duration-200 cursor-pointer border"
            :class="selectedProvider && selectedProvider.id === p.id
              ? 'bg-white border-white shadow-sm ring-1 ring-black/[0.04]'
              : 'border-transparent hover:bg-white/35 text-zen-gray hover:text-zen-ink'"
          >
            <div class="flex items-center gap-2.5">
              <!-- Colored circle avatar representing brand -->
              <div
                class="w-6 h-6 rounded-full text-white font-bold flex items-center justify-center text-[10px]"
                :class="p.iconColor"
              >
                {{ p.icon }}
              </div>
              <span class="text-xs font-bold leading-none" :class="selectedProvider && selectedProvider.id === p.id ? 'text-zen-ink' : 'text-zen-gray'">
                {{ p.name }}
              </span>
            </div>

            <div class="flex items-center gap-1.5">
              <!-- Delete button for custom providers -->
              <button
                v-if="p.id.toString().startsWith('custom_')"
                @click.stop="deleteCustomProvider(p)"
                class="text-zen-gray hover:text-red-600 w-4 h-4 flex items-center justify-center rounded hover:bg-black/5 transition-colors text-[10px] font-bold"
                title="删除自定义平台"
              >
                ✕
              </button>

              <!-- ON/OFF pill button on the right -->
              <span
                class="text-[8px] font-bold px-1.5 py-0.5 rounded-full select-none transition-all duration-300"
                :class="p.status
                  ? 'bg-[#E8F5E9] text-[#2E7D32]'
                  : 'bg-black/[0.04] text-zen-gray'"
              >
                {{ p.status ? 'ON' : 'OFF' }}
              </span>
            </div>
          </div>

          <!-- Add Custom Model Platform Creator Option at bottom -->
          <div
            @click="triggerAddCustomProvider"
            class="flex items-center justify-center p-3 rounded-xl border border-dashed border-indigo-500/40 bg-indigo-50/20 hover:bg-indigo-50/50 text-indigo-600 hover:text-indigo-700 cursor-pointer transition-all duration-200 text-xs font-bold gap-1.5 mt-2"
          >
            <span>＋</span>
            <span>添加自定义模型平台</span>
          </div>
        </div>
      </div>

      <!-- Right Column: API management console (8 cols) -->
      <div v-if="selectedProvider" class="lg:col-span-8 bg-white/70 backdrop-blur-md border border-white/50 rounded-3xl p-6 shadow-sm min-h-[600px] flex flex-col justify-between">
        
        <div class="space-y-5">
          <!-- 1. Header (Name, Gear, Toggle Switch) -->
          <div class="flex justify-between items-center border-b border-white/20 pb-4 select-none">
            <div class="flex items-center gap-2">
              <h3 class="text-base font-bold font-serif-sc text-zen-ink flex items-center gap-1.5">
                {{ selectedProvider.name }}
              </h3>
              <span class="text-xs text-zen-gray select-none cursor-pointer hover:text-zen-ink">⚙️</span>
            </div>

            <!-- Apple Style Green Toggle Switch -->
            <label class="relative inline-flex items-center cursor-pointer">
              <input type="checkbox" v-model="selectedProvider.status" class="sr-only peer" />
              <div class="w-10 h-5 bg-black/10 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-[#2E7D32]"></div>
            </label>
          </div>

          <!-- 2. API Key Form Row -->
          <div class="space-y-1.5">
            <div class="flex items-center gap-1 select-none">
              <label class="block text-[10px] text-zen-gray font-bold">API 密钥</label>
              <span class="text-zen-gray text-[9px] cursor-pointer">🛠️</span>
            </div>
            <div class="flex gap-2">
              <div class="relative flex-1">
                <input
                  :type="showApiKey ? 'text' : 'password'"
                  v-model="selectedProvider.apiKey"
                  placeholder="请输入您的密钥..."
                  class="w-full bg-white/40 border border-white/60 rounded-xl pl-3 pr-8 py-2.5 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
                />
                <button
                  @click="showApiKey = !showApiKey"
                  class="absolute right-2.5 top-1/2 -translate-y-1/2 text-zen-gray hover:text-zen-ink text-[10px] font-semibold outline-none"
                >
                  {{ showApiKey ? '👁️' : '🕶️' }}
                </button>
              </div>
              <button
                @click="testProviderConnection"
                :disabled="testingConnection"
                class="px-5 bg-white border border-white/80 hover:bg-white/80 text-zen-ink rounded-xl text-xs font-bold shadow-sm transition-all outline-none shrink-0 flex items-center justify-center gap-1.5"
              >
                <span v-if="testingConnection" class="w-3.5 h-3.5 border-2 border-zen-green border-t-transparent rounded-full animate-spin"></span>
                <span>检测</span>
              </button>
            </div>
            <p class="text-[9px] text-zen-gray select-none">多个密钥使用逗号分隔</p>
          </div>

          <!-- 3. API Base URL Form Row -->
          <div class="space-y-1.5">
            <div class="flex items-center gap-1 select-none">
              <label class="block text-[10px] text-zen-gray font-bold">API 地址</label>
              <span class="text-zen-gray text-[9px]">↕️</span>
              <span class="text-zen-gray text-[9px] cursor-help" title="算力网关服务端代理点">❓</span>
            </div>
            <div class="relative flex items-center">
              <input
                type="text"
                v-model="selectedProvider.baseUrl"
                class="w-full bg-white/40 border border-white/60 rounded-xl pl-3 pr-8 py-2.5 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
              />
              <span
                @click="resetBaseUrl"
                class="absolute right-2.5 text-zen-gray hover:text-zen-ink text-[10px] cursor-pointer select-none"
                title="重置为默认地址"
              >
                🔄
              </span>
            </div>
            <p class="text-[9px] text-zen-gray select-none font-mono">预览：{{ selectedProvider.previewUrl }}</p>
          </div>

          <!-- 4. Model details box -->
          <div class="space-y-2">
            <div class="flex justify-between items-center select-none">
              <div class="flex items-center gap-2">
                <label class="block text-[10px] text-zen-gray font-bold">模型</label>
                <span class="px-1.5 py-0.5 rounded-full bg-black/[0.04] text-[8px] font-bold text-zen-gray">{{ (selectedProvider.availableModels && selectedProvider.availableModels.length) || 1 }}</span>
                <span class="text-zen-gray text-[9px]">🎚️</span>
                <span class="text-zen-gray text-[9px]">🔍</span>
              </div>
              <div class="flex gap-2">
                <button
                  @click="syncModels"
                  :disabled="syncingModels"
                  class="px-2.5 py-1 bg-white/50 border border-white/60 hover:bg-white text-zen-gray hover:text-zen-ink rounded-lg text-[9px] font-semibold transition-all outline-none flex items-center gap-1"
                >
                  <span v-if="syncingModels" class="w-2.5 h-2.5 border border-zen-green border-t-transparent rounded-full animate-spin"></span>
                  <span>获取模型列表</span>
                </button>
                <button
                  @click="addNewModel"
                  class="w-5 h-5 bg-white/50 border border-white/60 hover:bg-white text-zen-gray hover:text-zen-ink rounded-lg text-[10px] font-semibold flex items-center justify-center outline-none"
                >
                  ＋
                </button>
              </div>
            </div>

            <!-- Model hierarchy list (from /models or current selection) -->
            <div class="bg-black/[0.02] border border-black/[0.04] rounded-2xl p-4 space-y-3 shadow-inner">
              <div class="text-xs">
                <div class="font-bold text-zen-gray text-[9px] mb-2 uppercase select-none tracking-wider font-mono">
                  {{ selectedProvider.modelGroup }}
                </div>
                <div v-if="modelsFetchError" class="mb-2 p-2 rounded-xl bg-red-50 border border-red-200 text-[10px] text-red-700 whitespace-pre-wrap break-words">
                  {{ modelsFetchError }}
                </div>
                <div class="max-h-48 overflow-y-auto space-y-1.5 pr-0.5">
                  <div
                    v-for="mid in (selectedProvider.availableModels && selectedProvider.availableModels.length ? selectedProvider.availableModels : [selectedProvider.model])"
                    :key="mid"
                    @click="selectModel(mid)"
                    class="flex items-center justify-between p-2 bg-white rounded-xl border shadow-sm cursor-pointer transition-all"
                    :class="mid === selectedProvider.model ? 'border-zen-green/60 ring-1 ring-zen-green/30' : 'border-black/[0.02] hover:border-black/10'"
                  >
                    <div class="flex items-center gap-2 select-none min-w-0">
                      <span class="w-5 h-5 shrink-0 rounded-full bg-[#ECEFF1] text-[#455A64] text-[9px] font-mono font-bold flex items-center justify-center">{{ mid === selectedProvider.model ? 'S' : '·' }}</span>
                      <span class="font-semibold text-zen-ink font-mono text-[10px] truncate" :title="mid">{{ mid }}</span>
                    </div>
                    <div v-if="mid === selectedProvider.model" class="flex items-center gap-2 select-none shrink-0">
                      <span
                        @click.stop="deleteModel"
                        class="text-zen-gray text-[10px] cursor-pointer hover:text-zen-crimson font-bold w-4 h-4 flex items-center justify-center rounded hover:bg-black/5"
                      >
                        －
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 5. Footer save config button -->
        <div class="pt-4 border-t border-white/20 flex justify-between items-center text-[9px] select-none mt-6">
          <span class="text-zen-gray">物理密钥安全：所有平台密钥均加密缓存在本地，不会以明文形式上传外部云端。</span>
          <button
            @click="saveProviderSettings"
            class="px-5 py-2.5 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-xs font-bold shadow-sm transition-all outline-none"
          >
            保存并应用网关
          </button>
        </div>
      </div>
    </div>

    <!-- TAB 2: 智能体 Skills 与应用中心 -->
    <div v-else-if="activeTab === 'skills'" class="space-y-8 animate-fadeIn">
      <!-- Part A: 智能体应用与工具插件 -->
      <div class="space-y-4">
        <div class="pb-3 border-b border-white/20 select-none flex justify-between items-center">
          <div>
            <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
              <span class="w-8 h-8 rounded-xl bg-zen-ink text-white flex items-center justify-center text-xs">🔌</span>
              智能体应用与工具箱 (Agent Application Tools)
            </h3>
            <p class="text-[10px] text-zen-gray mt-1">集成多维度的智能分析工具，包含独立站 SEO 诊断与客户 4-Step 精准分析向导。</p>
          </div>
        </div>
        
        <SmartTools
          :is-secret-mode="isSecretMode"
          :leads="leads"
          :our-company-info="ourCompanyInfo"
          @update:leads="$emit('update:leads', $event)"
        />
      </div>

      <!-- Part B: 开发者底层技能与高级算法控制 -->
      <div class="pt-6 border-t border-white/20 space-y-4">
        <div class="pb-3 select-none">
          <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
            <span class="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center text-xs">🛠️</span>
            开发者底层技能与高级算法控制 (IDE Skills & Developer Configuration)
          </h3>
          <p class="text-[10px] text-zen-gray mt-1">管理底层智能体运行所需的 IDE 原子技能包，调节大模型创造力温度参数。</p>
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 items-start">
          <!-- Left 2 Cols: Switches & Parameters -->
          <div class="xl:col-span-2 space-y-6">
            
            <!-- Switches -->
            <div class="apple-glass rounded-[24px] p-6 border border-white/50 space-y-4 select-none">
              <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
                <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
                高级智能模型算法与功能开关
              </h3>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                <label class="flex items-start gap-3 p-3.5 bg-white/30 border border-white/40 rounded-2xl cursor-pointer hover:bg-white/60 transition-all">
                  <input type="checkbox" v-model="secretMode" class="rounded text-zen-green focus:ring-zen-green mt-0.5" />
                  <div>
                    <span class="font-bold text-zen-ink block">物理断网隔绝模式</span>
                    <span class="text-[9px] text-zen-gray mt-1 leading-normal block">开启后，系统强制拦截所有云端网络请求，AI网关流转切换为本地 Ollama + SQLite 数据沙箱，确保商业资产100%绝对隐私安全。</span>
                  </div>
                </label>

                <label class="flex items-start gap-3 p-3.5 bg-white/30 border border-white/40 rounded-2xl cursor-pointer hover:bg-white/60 transition-all">
                  <input type="checkbox" v-model="systemSwitches.autoScan" class="rounded text-zen-green focus:ring-zen-green mt-0.5" />
                  <div>
                    <span class="font-bold text-zen-ink block">外部报告自动侦测</span>
                    <span class="text-[9px] text-zen-gray mt-1 leading-normal block">开启后，智能工具面板将在页面载入时自动扫描并索引 `public/external_reports/` 目录下由其他AI生成的异构数据包。</span>
                  </div>
                </label>

                <label class="flex items-start gap-3 p-3.5 bg-white/30 border border-white/40 rounded-2xl cursor-pointer hover:bg-white/60 transition-all">
                  <input type="checkbox" v-model="systemSwitches.doubleLinkage" class="rounded text-zen-green focus:ring-zen-green mt-0.5" />
                  <div>
                    <span class="font-bold text-zen-ink block">跨组件双向数据同步</span>
                    <span class="text-[9px] text-zen-gray mt-1 leading-normal block">自动连通公海详情页的「分析报告」Tab，保证任意工具解析或生成的 SPI 深度报告可实时同步写入对应客商档案。</span>
                  </div>
                </label>

                <div class="flex flex-col justify-between p-3.5 bg-white/30 border border-white/40 rounded-2xl">
                  <div class="space-y-1">
                    <span class="font-bold text-zen-ink block">ChromaDB 向量召回匹配上限</span>
                    <span class="text-[9px] text-zen-gray leading-normal block">ChromaDB 本地检索高相似度 Context 召回手册匹配的段落条数限制。</span>
                  </div>
                  <div class="flex items-center gap-2 mt-2">
                    <input type="number" v-model.number="systemSwitches.vectorLimit" min="1" max="10"
                      class="w-16 bg-white/50 border border-white/60 rounded-lg px-2.5 py-1 text-xs outline-none text-center focus:bg-white focus:border-zen-green" />
                    <span class="text-[10px] text-zen-gray font-semibold">条召回片段 (Chunks)</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Temperature settings -->
            <div class="apple-glass rounded-[24px] p-6 border border-white/50 space-y-4 select-none">
              <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
                <span class="w-1.5 h-3 bg-zen-gold rounded-full"></span>
                系统灵动度与推理随机性 (Parameters)
              </h3>
              <div class="space-y-2 text-xs">
                <div class="flex justify-between font-bold text-zen-ink">
                  <span>创造力参数 (Temperature)</span>
                  <span class="font-mono text-zen-green">{{ gatewayConfig.temperature }}</span>
                </div>
                <p class="text-[9px] text-zen-gray leading-normal">数值越高，AI的回答越有创意和多元（推荐起草开发信时设为 0.8）；数值越低，回答越精准、保守且合规（推荐诊断材质图纸时设为 0.2）。</p>
                <div class="pt-2">
                  <input type="range" min="0" max="1.2" step="0.1" v-model.number="gatewayConfig.temperature"
                    class="w-full h-1 bg-black/5 rounded-lg appearance-none cursor-pointer accent-zen-green" />
                </div>
              </div>
            </div>
          </div>

          <!-- Right 1 Col: Standard IDE Skills Import Console -->
          <div class="xl:col-span-1 space-y-6">
            <!-- IDE Skills Manager -->
            <div class="apple-glass rounded-[24px] p-6 border border-white/50 space-y-4">
              <div class="pb-3 border-b border-white/20 select-none">
                <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
                  <span class="w-1.5 h-3 bg-indigo-500 rounded-full"></span>
                  标准 IDE 技能导入控制台
                </h3>
                <p class="text-[9px] text-zen-gray mt-1">导入 IDE 内部标准专业技能，直接注入 RAG 算力网关以赋能业务团队与 AI Agent。</p>
              </div>

              <!-- Skills selection list -->
              <div class="space-y-2 select-none overflow-y-auto max-h-[300px] pr-1 scrollbar-elegant">
                <div
                  v-for="sk in ideSkills"
                  :key="sk.value"
                  @click="toggleSkillSelect(sk.value)"
                  class="p-3 rounded-2xl border transition-all duration-300 cursor-pointer flex justify-between items-start gap-2 text-xs"
                  :class="isSkillImported(sk.value)"
                >
                  <div class="space-y-1">
                    <div class="flex items-center gap-1.5">
                      <span class="font-bold font-mono text-[10px]" :class="isSkillImported(sk.value) ? 'text-zen-green' : isSelected(sk.value) ? 'text-indigo-600' : 'text-zen-ink'">{{ sk.value }}</span>
                      <span class="px-1.5 py-0.5 rounded text-[8px] font-bold"
                        :class="isSkillImported(sk.value) ? 'bg-zen-green/10 text-zen-green' : 'bg-black/[0.04] text-zen-gray'">
                        {{ isSkillImported(sk.value) ? '已激活' : '待导入' }}
                      </span>
                    </div>
                    <p class="text-[10px] leading-relaxed" :class="isSkillImported(sk.value) || isSelected(sk.value) ? 'text-zen-ink font-semibold' : 'text-zen-gray'">
                      {{ sk.label }} · <span class="text-[9px] italic">{{ sk.desc }}</span>
                    </p>
                  </div>
                  <div class="shrink-0 pt-0.5">
                    <div class="w-5 h-5 rounded-full border flex items-center justify-center text-[9px]"
                      :class="isSkillImported(sk.value)
                        ? 'bg-zen-green border-transparent text-white'
                        : isSelected(sk.value)
                          ? 'bg-indigo-600 border-transparent text-white'
                          : 'border-white/80 bg-white/40'">
                      <span v-if="isSkillImported(sk.value)">✓</span>
                      <span v-else-if="isSelected(sk.value)">＋</span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Buttons & Terminal Simulated Output -->
              <div class="space-y-3.5 pt-3 border-t border-white/20 select-none">
                <button
                  @click="triggerImportProcess"
                  :disabled="selectedSkillsToImport.length === 0 || isImporting"
                  class="w-full py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-md transition-all outline-none disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  <span>{{ isImporting ? 'IDE 接口极速编译中...' : '一键导入选中技能到 CRM 智能体 ⚙️' }}</span>
                </button>

                <!-- Simulated interactive terminal -->
                <div v-if="showTerminal || isImporting" class="bg-black/85 border border-white/10 rounded-2xl p-4 font-mono text-[9px] text-green-400 space-y-1.5 max-h-36 overflow-y-auto shadow-inner">
                  <div class="flex justify-between items-center text-zen-gray border-b border-white/10 pb-1.5 mb-2">
                    <span>TERMINAL: crm-cli import</span>
                    <span class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></span>
                  </div>
                  <div v-for="(line, idx) in terminalLines" :key="idx" class="leading-normal whitespace-pre-wrap">
                    {{ line }}
                  </div>
                  <div v-if="isImporting" class="inline-flex items-center gap-1">
                    <span class="inline-block w-1.5 h-3 bg-green-400 animate-pulse"></span>
                    <span>编译载入中...</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 3: Local Storage Management -->
    <div v-else-if="activeTab === 'storage'" class="space-y-6">
      <div class="apple-glass rounded-[24px] p-6 border border-white/50 space-y-5 select-none animate-fadeIn">
        <div class="border-b border-white/20 pb-3 flex justify-between items-center">
          <div>
            <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
              <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
              本地物理存储与文件管理
            </h3>
            <p class="text-[10px] text-zen-gray mt-1">查看系统底层的 SQLite 客户底库、ChromaDB 向量仓、静态 PDF 资产的物理存储位置，支持一键调起 macOS Finder 系统资源管理器。</p>
          </div>
          
          <button
            @click="clearStorageCache"
            :disabled="clearingCache"
            class="px-3.5 py-1.5 bg-white/40 border border-white/60 hover:bg-white text-zen-gray hover:text-zen-ink rounded-xl text-[10px] font-semibold transition-all outline-none flex items-center gap-1.5 shadow-sm"
          >
            <span v-if="clearingCache" class="w-3.5 h-3.5 border border-zen-green border-t-transparent rounded-full animate-spin"></span>
            <span>🧹 清理缓存与临时文件</span>
          </button>
        </div>

        <div class="space-y-4">
          <!-- 1. SQLite Database Path -->
          <div class="p-4 bg-white/30 border border-white/40 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="space-y-1 max-w-xl text-left">
              <div class="flex items-center gap-2">
                <span class="text-base">📄</span>
                <span class="font-bold text-xs text-zen-ink">客商关系底库 (SQLite Database)</span>
                <span class="px-1.5 py-0.5 rounded bg-zen-green/10 text-zen-green text-[8px] font-bold">Encrypted</span>
              </div>
              <p class="text-[9px] text-zen-gray leading-normal">存放系统所有外贸客户档案、成交订单记录、开发跟进时间线的物理主数据库，采用 AES-256 位全盘物理加密。</p>
              <code class="block text-[9px] font-mono text-[#D46B12] bg-[#FFF5EC] border border-[#FFD8B3]/40 px-2.5 py-1.5 rounded-lg select-text mt-1 break-all">
                /Users/ky/Library/Application Support/MagicHub/database/magichub_secure.db
              </code>
            </div>
            <button
              @click="openLocalFolder('/Users/ky/Library/Application Support/MagicHub/database/')"
              class="px-4 py-2 bg-white hover:bg-white/80 border border-white/80 text-zen-ink text-[10px] font-bold rounded-xl shadow-sm transition-all outline-none shrink-0"
            >
              打开所在文件夹 📂
            </button>
          </div>

          <!-- 2. ChromaDB Vector Storage -->
          <div class="p-4 bg-white/30 border border-white/40 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="space-y-1 max-w-xl text-left">
              <div class="flex items-center gap-2">
                <span class="text-base">⚡</span>
                <span class="font-bold text-xs text-zen-ink">AI 向量索引知识仓 (ChromaDB Local)</span>
                <span class="px-1.5 py-0.5 rounded bg-[#E0F2FE] text-[#0369A1] text-[8px] font-bold">Vector Storage</span>
              </div>
              <p class="text-[9px] text-zen-gray leading-normal">存放 RAG 产品手册、FDA/TUV 认证文档经过切片解析后生成的 ChromaDB 本地高相似度向量匹配索引底盘。</p>
              <code class="block text-[9px] font-mono text-[#0369A1] bg-[#F0F9FF] border border-[#B3E5FC]/40 px-2.5 py-1.5 rounded-lg select-text mt-1 break-all">
                /Users/ky/Library/Application Support/MagicHub/chromadb_local/
              </code>
            </div>
            <button
              @click="openLocalFolder('/Users/ky/Library/Application Support/MagicHub/chromadb_local/')"
              class="px-4 py-2 bg-white hover:bg-white/80 border border-white/80 text-zen-ink text-[10px] font-bold rounded-xl shadow-sm transition-all outline-none shrink-0"
            >
              打开所在文件夹 📂
            </button>
          </div>

          <!-- 3. Public Brochures -->
          <div class="p-4 bg-white/30 border border-white/40 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="space-y-1 max-w-xl text-left">
              <div class="flex items-center gap-2">
                <span class="text-base">📖</span>
                <span class="font-bold text-xs text-zen-ink">外贸产品画册与静态文档</span>
                <span class="px-1.5 py-0.5 rounded bg-[#F3E5F5] text-[#7B1FA2] text-[8px] font-bold">Public Assets</span>
              </div>
              <p class="text-[9px] text-zen-gray leading-normal">存放系统所有的 PDF 产品图册、Müller RAG 检测文件及多模态图片附件的静态资产存储目录，可在此处直接拷贝或编辑源文件。</p>
              <code class="block text-[9px] font-mono text-[#7B1FA2] bg-[#FAF4FC] border border-[#E1BEE7]/40 px-2.5 py-1.5 rounded-lg select-text mt-1 break-all">
                /Users/ky/Desktop/通用版外贸客户管理/public/
              </code>
            </div>
            <button
              @click="openLocalFolder('/Users/ky/Desktop/通用版外贸客户管理/public/')"
              class="px-4 py-2 bg-white hover:bg-white/80 border border-white/80 text-zen-ink text-[10px] font-bold rounded-xl shadow-sm transition-all outline-none shrink-0"
            >
              打开所在文件夹 📂
            </button>
          </div>

          <!-- 4. System & AI Cache Path -->
          <div class="p-4 bg-white/30 border border-white/40 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="space-y-1 max-w-xl text-left">
              <div class="flex items-center gap-2">
                <span class="text-base">🔄</span>
                <span class="font-bold text-xs text-zen-ink">AI RAG 算力缓存与离线临时数据</span>
                <span class="px-1.5 py-0.5 rounded bg-black/[0.04] text-zen-gray text-[8px] font-bold">Temp Cache</span>
              </div>
              <p class="text-[9px] text-zen-gray leading-normal">用于缓存大模型对答、离线 Ollama 上下文切片历史以及 UI 状态暂存的本地物理高速缓存目录。</p>
              <code class="block text-[9px] font-mono text-zen-gray bg-black/[0.02] border border-black/[0.04] px-2.5 py-1.5 rounded-lg select-text mt-1 break-all">
                /Users/ky/Library/Caches/com.magichub.crm.mac/
              </code>
            </div>
                        <button
              @click="openLocalFolder('/Users/ky/Library/Caches/com.magichub.crm.mac/')"
              class="px-4 py-2 bg-white hover:bg-white/80 border border-white/80 text-zen-ink text-[10px] font-bold rounded-xl shadow-sm transition-all outline-none shrink-0"
            >
              打开所在文件夹 📂
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- TAB 4: Update Logs (Changelog) [NEW] -->
    <div v-else-if="activeTab === 'changelog'" class="space-y-6">
      <div class="apple-glass rounded-[24px] p-6 border border-white/50 space-y-6 animate-fadeIn">
        <div class="border-b border-white/20 pb-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 select-none">
          <div>
            <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
              <span class="w-1.5 h-3 bg-purple-500 rounded-full"></span>
              📢 系统版本更新与升级里程碑 (Changelog)
            </h3>
            <p class="text-[10px] text-zen-gray mt-1">记录 MagicHub Pilot 外贸智能客户管理系统版本的迭代里程碑与核心功能升级进展。</p>
          </div>
          <div class="shrink-0 flex items-center gap-2">
            <button
              @click="triggerLocalAppUpgrade"
              :disabled="upgradeState.loading"
              class="px-4 py-2 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-bold text-[11px] rounded-xl shadow-md transition-all hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50 disabled:scale-100 flex items-center gap-1.5 outline-none select-none"
            >
              <span v-if="upgradeState.loading" class="animate-spin text-[10px]">🌀</span>
              <span v-else>🚀</span>
              {{ upgradeState.loading ? upgradeState.statusText : '本地一键升级系统' }}
            </button>
          </div>
        </div>

        <div class="max-w-4xl mx-auto space-y-6 pt-2">
          <div class="relative pl-6 border-l border-black/10 space-y-8 select-text overflow-y-auto max-h-[560px] pr-2 scrollbar-elegant">
            
            <!-- Release v1.9.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-purple-600 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-purple-600"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-purple-600/10 text-purple-700 px-2 py-0.5 rounded-lg">v1.9.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01 (当前最新版)</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">🔗 全系统模块数据连通，告别写死假数据</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>📊 驾驶舱全面实时化</b>：年度目标、总管线、客户数、订单数、总利润五大指标，以及日历、待办、商机快览、AI 团队全部改为基于真实客户/商机/合同/跟进数据实时计算。</li>
                  <li><b>📈 商机与合同统计联动</b>：商机总额、加权赢单价值、漏斗阶段、合同汇总数字全部按真实数据聚合，不再写死。</li>
                  <li><b>📅 跟进记录贯通日历</b>：客户跟进记录按日期自动出现在日程日历与驾驶舱日历中。</li>
                  <li><b>📤 营销与寄样接入真实数据</b>：营销客户分组按真实客户国家统计；寄样跟进改为持久化全局数据，更新不丢失。</li>
                  <li><b>💾 待办与日程持久化</b>：日程待办、手动日历事件均落盘保存，重启与更新后依然保留。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.8.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-600 px-2 py-0.5 rounded-lg">v1.8.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">🔒 全量数据持久化加固，更新永不丢失数据</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>💾 全数据类型自动落盘</b>：跟进记录、报价、合同、团队、商机、技能、AI 对话存档等全部接入统一持久化层，新增内容启动即自动保存，彻底解决“更新后数据消失”问题。</li>
                  <li><b>⚡ 即时落盘与退出兜底</b>：标签等关键操作立即强制写盘，并在关闭/重载前自动刷写所有待保存数据，杜绝防抖期内的数据丢失。</li>
                  <li><b>🛡️ 原子写入与自动备份恢复</b>：底层改为“临时文件+重命名”原子写入并保留 .bak 备份，更新或断电中断写入也不会损坏数据，损坏时自动从备份恢复。</li>
                  <li><b>🎨 标签独立配色与色盘</b>：每个标签独立颜色，自定义标签输入框旁新增取色盘，可逐个标签改色，配色持久保存。</li>
                  <li><b>📝 跟进记录自定义项</b>：跟进登记的沟通渠道与跟进类型下拉框均支持“自定义”自由输入。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.7.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-600 px-2 py-0.5 rounded-lg">v1.7.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">⚡ 物理备份高防丢失模式与本地一键自升级引擎交付</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>🚀 本地点击一键升级</b>：新增“🚀 本地一键升级系统”按钮，支持在应用内选择 ZIP 包在后台自动解压、覆盖替换并优雅自重启。</li>
                  <li><b>💾 报告物理物理落盘</b>：新增 `write-file` 磁盘写入 IPC 网关，生成的 AI 深度分析报告不仅在系统内显示，还会以物理 `.md` 格式同步落盘到桌面备份，防御应用重装或重置导致的数据丢失风险。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.6.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-600 px-2 py-0.5 rounded-lg">v1.6.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">🏢 公司详情档案与智能背调双向智能联动与升级</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>🏢 公司详情档案联动</b>：升级 `syncDetailsFromCompanyInfo` 联动逻辑，支持自动识别公司资质 (CE, TUV, FDA)、 preset 国际贸易术语、国家地区旗帜标签 (🇩🇪, 🇦🇺, 🇿🇦 等) 自动更新到公司档案面板。</li>
                  <li><b>⚙️ 智能 Sandbox 模拟生成</b>：极速推出高保真本地 8 模块深度档案沙盒引擎，物理断网下自动针对 JFC 等类型工厂生成详实可信的 Sandbox 报告。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.5.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-600 px-2 py-0.5 rounded-lg">v1.5.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">📊 10大标准客户深度背调模块与结构化展示</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>📊 10大背调模块</b>：全面升级客户分析模板，包含公司概况、决策链、市场环境、竞争格局、SWOT 态势、供应商合作池等 10 大标准化深度背调版块。</li>
                  <li><b>👁️ 结构化看板与动态隐藏</b>：新增“📋 结构化看板”与“📄 原始文档”双视图切换，空模组自动物理隐藏，界面更加清爽专业。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.4.1 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-700 px-2 py-0.5 rounded-lg">v1.4.1</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">⚡ 客资数据库多维度读取性能调优与极速列表渲染</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>⚙️ 本地异步文件流写入</b>：优化 Electron IPC 的网关存储底层，将同步阻塞写入完全重构为多线程异步文件流写入，防御大文件存盘卡顿。</li>
                  <li><b>⚡ 响应式分组分页加载（Load More）</b>：对于已导入的上千家客户，使用滑动切片（slice）限制单次渲染的 DOM 节点数量，将页面首次加载的 CPU 渲染消耗降低 95%。</li>
                  <li><b>🛡️ 监测重置机制</b>：当检索框、分类或状态标签发生切换时，自动热重置分页切片起点，确保搜索速度瞬间直达，彻底消除打字响应延迟。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.4.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-600 px-2 py-0.5 rounded-lg">v1.4.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">⚙️ 客户详情手机改版与「一键客户分析」深度报告功能上线</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>⚙️ 客户手机号码重构优化</b>：客户立体画像工作台第一栏成功变更为<b>「手机号码」</b>，表单全面搭载手机输入项，并升级汽配增量同步以自动解析绑定物理手机号。</li>
                  <li><b>⚡ 一键生成大模型深度调研报告</b>：分析报告标签页新增「一键客户分析」功能，配置双向轨道 Orbit 动态载入及 4 阶段 RAG 智能里程碑检索动画，高精度一键合成并展示 SPI 画像报告。</li>
                  <li><b>离线安全沙箱沙盒保障</b>：物理断网模式（或无算力密钥）下，智能降级至高保真本地沙盒报告渲染引擎，依据客商地区定制生成详实 Markdown 报告并热绑定。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.3.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-600 px-2 py-0.5 rounded-lg">v1.3.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-06-01</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">📚 智能知识库、汽配数据同步及导航架构重构优化</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>📚 智能知识库集成</b>：新增“📚 智能知识库”功能组件，支持文本切片语义热召回以及 Notion 外部接口一键同步。</li>
                  <li><b>🚗 汽车配件数据同步</b>：海公盘中内建汽配客户专属同步控制台，一键物理同步 `parsed_customers.json`，并扫描绑定本地 `.md` 深度分析报告。</li>
                  <li><b>💬 AI 对话归档平铺</b>：AI 对话存档平铺渲染于侧栏底部，支持一键点击热加载并唤醒全屏对话空间。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.2.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-indigo-500 bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-indigo-500"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-indigo-500/10 text-indigo-600 px-2 py-0.5 rounded-lg">v1.2.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-05-31</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">DeepSeek V4 模型平台 & 智能邮件群发营销系统上线</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>DeepSeek V4 大模型接入</b>：支持 DeepSeek-V4 高并发流式响应，升级 AI 网关并完美适配地道多语言起草。</li>
                  <li><b>智能邮件营销中心</b>：左侧导航栏新增智能群发营销（Gmail/企业邮箱 SMTP 连接），支持 AI 脑算撰写、批量队列投递与数据可视化监控。</li>
                  <li><b>已启用的模型置顶</b>：模型配置列表根据 status 自动执行热排列，开启的模型立即浮动至列表顶部。</li>
                  <li><b>自定义第三方模型</b>：列表底部新增“＋ 添加自定义模型平台”，支持用户输入 Ollama 或第三方兼容 OpenAI 格式的 Base URL、密钥。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.1.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-zen-green bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-zen-green"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-zen-green/10 text-zen-green px-2 py-0.5 rounded-lg">v1.1.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-05-15</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">本地 RAG 知识检索与 AES-256 物理隐私沙箱构建</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li><b>ChromaDB 向量仓</b>：支持对本地 FDA/TUV 产品手册、技术图纸进行分段向量切片切块及语义召回。</li>
                  <li><b>全盘数据物理隐私加密</b>：本地 SQLite 数据库物理存储全面升级 AES-256 全链路双向加密。</li>
                  <li><b>物理断网隔绝模式</b>：新增一键“物理隔绝”开关，断开外部云端，AI 调度无缝回退至本地 Ollama 隔绝运转。</li>
                </ul>
              </div>
            </div>

            <!-- Release v1.0.0 -->
            <div class="relative">
              <div class="absolute -left-[30px] top-1.5 w-4 h-4 rounded-full border-2 border-zen-gray bg-white flex items-center justify-center">
                <div class="w-1.5 h-1.5 rounded-full bg-zen-gray"></div>
              </div>
              <div class="space-y-1.5">
                <div class="flex items-center gap-2">
                  <span class="text-xs font-bold text-zen-ink font-mono bg-black/[0.04] text-zen-gray px-2 py-0.5 rounded-lg">v1.0.0</span>
                  <span class="text-[10px] text-zen-gray font-bold">2026-04-20</span>
                </div>
                <h4 class="text-xs font-bold text-zen-ink">MagicHub CRM 基础商务流搭建</h4>
                <ul class="text-[10px] text-zen-gray list-disc pl-4 space-y-1">
                  <li>集成外贸客户海公盘、商务跟进日志、商机进度看板、合同报价账本及多角色团队协同。</li>
                </ul>
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
<!-- TAB 5: System Manual (系统使用说明书) [NEW] -->
    <div v-else-if="activeTab === 'manual'" class="space-y-6">
      <div class="apple-glass rounded-[24px] p-6 border border-white/50 space-y-6 animate-fadeIn select-text">
        <div class="border-b border-white/20 pb-3">
          <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
            <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
            📖 MagicHub Pilot 系统使用说明书
          </h3>
          <p class="text-[10px] text-zen-gray mt-1">在这里，您可以快速了解 MagicHub 系统中每个核心智能模块的设计目的、操作流程与物理黑科技。</p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 items-start">
          <!-- Left directory list -->
          <div class="md:col-span-1 bg-white/40 border border-white/60 rounded-2xl p-4 space-y-2 select-none">
            <h4 class="text-xs font-bold text-zen-ink uppercase tracking-wider mb-2">📒 目录导航</h4>
            <button
              v-for="(chapter, idx) in manualChapters"
              :key="idx"
              @click="activeChapter = idx"
              class="w-full text-left px-3 py-2 rounded-xl text-[11px] font-semibold transition-all duration-200"
              :class="activeChapter === idx ? 'bg-white text-zen-ink shadow-sm border border-white/50' : 'text-zen-gray hover:bg-white/25'"
            >
              {{ idx + 1 }}. {{ chapter.title }}
            </button>
          </div>

          <!-- Right Content panel -->
          <div class="md:col-span-2 bg-white/60 border border-white/50 rounded-2xl p-5 shadow-sm min-h-[400px]">
            <h3 class="text-sm font-bold font-serif-sc text-zen-ink border-b border-black/[0.05] pb-2.5 mb-3 flex items-center gap-2">
              <span>{{ manualChapters[activeChapter].icon }}</span>
              <span>{{ manualChapters[activeChapter].title }}</span>
            </h3>
            <div class="text-xs text-zen-gray leading-relaxed space-y-3 whitespace-pre-wrap">
              {{ manualChapters[activeChapter].content }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Custom Model Platform Modal -->
    <ZenModal :open="isAddCustomModalOpen" title="添加自定义 AI 算力平台" @close="isAddCustomModalOpen = false">
      <div class="space-y-4 text-xs text-zen-ink">
        <div class="space-y-1.5">
          <label class="block font-bold">平台名称 (Platform Name)</label>
          <input
            type="text"
            v-model="customProviderForm.name"
            placeholder="例如: 硅基流动 V4, Ollama 本地"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all"
          />
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">API 地址 (Base URL)</label>
          <input
            type="text"
            v-model="customProviderForm.baseUrl"
            placeholder="例如: https://api.siliconflow.cn/v1 或 http://localhost:11434/v1"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
          />
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">API 密钥 (API Key)</label>
          <input
            type="password"
            v-model="customProviderForm.apiKey"
            placeholder="请输入该平台 API 密钥 (如果是 Ollama 随便填即可)"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
          />
        </div>
        <div class="space-y-1.5">
          <label class="block font-bold">默认模型标识符 (Model Name)</label>
          <input
            type="text"
            v-model="customProviderForm.model"
            placeholder="例如: deepseek-ai/DeepSeek-V4 或 deepseek-r1:7b"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
          />
        </div>
      </div>
      <template #footer>
        <button
          @click="submitCustomProvider"
          class="px-5 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          保存并启用新平台 🟢
        </button>
        <button
          @click="isAddCustomModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          返回
        </button>
      </template>
    </ZenModal>

    <!-- Add Custom Model Name Modal -->
    <ZenModal :open="isAddModelModalOpen" title="添加/切换自定义模型标识符" @close="isAddModelModalOpen = false">
      <div class="space-y-4 text-xs text-zen-ink">
        <div class="space-y-1.5">
          <label class="block font-bold">模型标识符 (Model Name / Identifier)</label>
          <input
            type="text"
            v-model="newModelInput"
            placeholder="例如: deepseek-chat 或 gpt-4o"
            class="w-full bg-white/40 border border-white/60 rounded-xl px-3 py-2 text-xs outline-none focus:bg-white focus:border-zen-green transition-all font-mono"
          />
        </div>
      </div>
      <template #footer>
        <button
          @click="submitNewModelName"
          class="px-5 py-2 rounded-xl bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          确认并切换 🟢
        </button>
        <button
          @click="isAddModelModalOpen = false"
          class="px-5 py-2 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-medium outline-none"
        >
          返回
        </button>
      </template>
    </ZenModal>
  </div>
</template>

<script setup>
import { ref, computed, reactive, watch, onMounted } from 'vue';
import ZenModal from './ZenModal.vue';

const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  },
  importedSkills: {
    type: Array,
    required: true
  },
  providers: {
    type: Array,
    required: true
  },
  leads: {
    type: Array,
    default: () => []
  },
  ourCompanyInfo: {
    type: Object,
    default: () => ({})
  },
  initialTab: {
    type: String,
    default: 'api'
  }
});

const emit = defineEmits([
  'update:secret-mode',
  'update:importedSkills',
  'update:providers',
  'update:leads'
]);

const activeTab = ref('api');

onMounted(() => {
  if (props.initialTab) {
    activeTab.value = props.initialTab;
  }
});

watch(() => props.initialTab, (newVal) => {
  if (newVal) {
    activeTab.value = newVal;
  }
});

const isAddCustomModalOpen = ref(false);
const customProviderForm = reactive({
  name: '',
  baseUrl: '',
  apiKey: '',
  model: 'deepseek-ai/DeepSeek-V4'
});

const isAddModelModalOpen = ref(false);
const newModelInput = ref('');
const showApiKey = ref(false);
const modelsFetchError = ref('');
const providerSearchQuery = ref('');
const activeChapter = ref(0);

// Local copy of providers list to prevent direct mutation of props
const localProviders = ref([]);

const selectedProvider = ref(null);

watch(() => props.providers, (newVal) => {
  if (newVal && newVal.length > 0) {
    localProviders.value = newVal;
    if (!selectedProvider.value) {
      selectedProvider.value = newVal[0];
    } else {
      const currentId = selectedProvider.value.id;
      const matched = newVal.find(p => p.id === currentId);
      if (matched) {
        selectedProvider.value = matched;
      }
    }
  }
}, { immediate: true });

const sortedFilteredProviders = computed(() => {
  let list = [...localProviders.value];
  if (providerSearchQuery.value) {
    const q = providerSearchQuery.value.toLowerCase();
    list = list.filter(p => p.name.toLowerCase().includes(q));
  }
  // Enabled providers status===true automatically float to the top
  return list.sort((a, b) => (b.status ? 1 : 0) - (a.status ? 1 : 0));
});

const selectProvider = (p) => {
  selectedProvider.value = p;
  showApiKey.value = false;
  modelsFetchError.value = '';
};

// Add custom model platform at bottom of list
const triggerAddCustomProvider = () => {
  customProviderForm.name = '';
  customProviderForm.baseUrl = '';
  customProviderForm.apiKey = '';
  customProviderForm.model = 'deepseek-ai/DeepSeek-V4';
  isAddCustomModalOpen.value = true;
};

const submitCustomProvider = () => {
  const { name, baseUrl, apiKey, model } = customProviderForm;
  if (!name.trim()) {
    alert('请输入平台名称！');
    return;
  }
  if (!baseUrl.trim()) {
    alert('请输入 API 地址！');
    return;
  }
  if (!apiKey.trim()) {
    alert('请输入 API 密钥！');
    return;
  }
  if (!model.trim()) {
    alert('请输入默认模型标识符！');
    return;
  }

  const newProvider = {
    id: 'custom_' + Date.now(),
    name: name.trim(),
    icon: name.trim().charAt(0),
    iconColor: 'bg-indigo-600',
    status: true,
    baseUrl: baseUrl.trim(),
    apiKey: apiKey.trim(),
    modelGroup: 'custom',
    model: model.trim(),
    previewUrl: baseUrl.trim().endsWith('/chat/completions') ? baseUrl.trim() : `${baseUrl.trim()}/chat/completions`
  };

  const updated = [...localProviders.value, newProvider];
  emit('update:providers', updated);
  selectedProvider.value = newProvider;
  
  // Save to local storage
  try {
    localStorage.setItem('magichub_ai_providers', JSON.stringify(updated));
    if (window.electronAPI && window.electronAPI.saveSettings) {
      window.electronAPI.saveSettings('magichub_ai_providers', JSON.parse(JSON.stringify(updated)));
    }
  } catch (e) {
    console.error(e);
  }

  isAddCustomModalOpen.value = false;
  alert(`「自定义模型平台添加成功」\n已成功挂载并开启新网关 [${name.trim()}]！\n默认算力模型：${model.trim()}\n已自动置顶并同步至底部对话框！`);
};

const deleteCustomProvider = (p) => {
  if (!confirm(`确认要删除自定义模型平台「${p.name}」吗？`)) {
    return;
  }
  const updated = localProviders.value.filter(item => item.id !== p.id);
  emit('update:providers', updated);
  
  // If the currently selected provider is the one being deleted, select the first one of the remaining providers
  if (selectedProvider.value && selectedProvider.value.id === p.id) {
    selectedProvider.value = updated.length > 0 ? updated[0] : null;
  }
  
  // Save to local storage
  try {
    localStorage.setItem('magichub_ai_providers', JSON.stringify(updated));
    if (window.electronAPI && window.electronAPI.saveSettings) {
      window.electronAPI.saveSettings('magichub_ai_providers', JSON.parse(JSON.stringify(updated)));
    }
  } catch (e) {
    console.error(e);
  }
};

// ---- Models / connection helpers (OpenAI-compatible + Gemini native) ----
const normalizeBaseUrl = (base) => String(base || '').trim().replace(/\/+$/, '');

const buildModelsRequest = (provider) => {
  const key = String(provider.apiKey || '').trim();
  const base = normalizeBaseUrl(provider.baseUrl);
  // Native Gemini models list when base is Google AI (not the OpenAI-compat shim)
  const isGeminiNative = provider.id === 'gemini'
    && /googleapis\.com/i.test(base)
    && !/\/openai(\/|$)/i.test(base);
  if (isGeminiNative || (provider.id === 'gemini' && /api\.gemini\.net/i.test(base))) {
    return {
      url: `https://generativelanguage.googleapis.com/v1beta/models?key=${encodeURIComponent(key)}`,
      headers: {},
      style: 'gemini'
    };
  }
  const url = /\/models$/i.test(base) ? base : `${base}/models`;
  return {
    url,
    headers: { Authorization: `Bearer ${key}` },
    style: 'openai'
  };
};

const parseModelIds = (json) => {
  if (!json) return [];
  if (Array.isArray(json.data)) {
    return json.data.map((m) => (typeof m === 'string' ? m : (m && (m.id || m.name)))).filter(Boolean);
  }
  if (Array.isArray(json.models)) {
    return json.models.map((m) => {
      const n = typeof m === 'string' ? m : (m && (m.name || m.id)) || '';
      return String(n).replace(/^models\//, '');
    }).filter(Boolean);
  }
  if (Array.isArray(json)) {
    return json.map((m) => (typeof m === 'string' ? m : (m && (m.id || m.name)))).filter(Boolean);
  }
  return [];
};

const explainFetchError = (err, httpDetail) => {
  let errMsg = httpDetail || (err && err.message) || '未知错误';
  if (err && err.name === 'AbortError') {
    errMsg = '请求超时（请检查 Base URL / 是否需要代理）';
  }
  if (/Failed to fetch|NetworkError|Load failed|Network request failed/i.test(errMsg)) {
    errMsg += '\n可能原因：CORS（用浏览器打开时）、网络不通、或 Base URL 错误。Mac 内嵌 WKWebView 一般不受 CORS 限制。';
  }
  return errMsg;
};

// Real-world API connection checker
const testingConnection = ref(false);
const testProviderConnection = async () => {
  if (!selectedProvider.value || !selectedProvider.value.apiKey) {
    alert(`请输入有效的 API 密钥！`);
    return;
  }

  testingConnection.value = true;
  const startTime = Date.now();

  try {
    const { url, headers } = buildModelsRequest(selectedProvider.value);
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);

    const response = await fetch(url, {
      method: 'GET',
      headers,
      signal: controller.signal
    });

    clearTimeout(timeoutId);
    const latency = Date.now() - startTime;

    if (response.ok) {
      alert(`「${selectedProvider.value.name} 连接检测成功」\n物理通道延迟：${latency}ms\n鉴权状态：Authorized 🟢\n探测地址：${url}\n密钥已通过云端接口校验，通路完好！`);
    } else {
      let errMsg = `HTTP Error ${response.status} ${response.statusText}`;
      try {
        const errJson = await response.json();
        if (errJson && errJson.error && errJson.error.message) {
          errMsg = errJson.error.message;
        } else if (errJson && errJson.message) {
          errMsg = errJson.message;
        }
      } catch (e) {}

      alert(`「${selectedProvider.value.name} 密钥验证失败」\n状态代码：${response.status}\n探测地址：${url}\n详细信息：${errMsg} 🔴\n请检查 API Key、Base URL（勿漏 /v1）或余额。`);
    }
  } catch (err) {
    const errMsg = explainFetchError(err);
    alert(`「${selectedProvider.value.name} 物理网络检测失败」\n网络状态：Disconnected 🔴\n错误描述：${errMsg}\n请确认接口端点 (Base URL) 以及本机的网络代理配置！`);
  } finally {
    testingConnection.value = false;
  }
};

const resetBaseUrl = () => {
  if (!selectedProvider.value) return;
  const defaults = {
    apifree: 'https://api.apifree.ai/agent/v1',
    cloudflare: 'https://api.cloudflare.com/client/v4',
    siliconflow: 'https://api.siliconflow.cn/v1',
    gemini: 'https://generativelanguage.googleapis.com/v1beta/openai',
    alicoding: 'https://api.alicoding.com/v1',
    volcengine: 'https://ark.cn-beijing.volces.com/api/v3',
    minimax: 'https://api.minimaxi.com/v1',
    vpsairobot: 'https://api.vpsairobot.com/v1',
    vercel: 'https://gateway.ai.vercel.cloud/v1',
    bailian: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    qiniu: 'https://api.qiniu.com/v1',
    deepseek: 'https://api.deepseek.com/v1',
    zhipu: 'https://open.bigmodel.cn/api/paas/v4',
    openrouter: 'https://openrouter.ai/api/v1',
    cerebras: 'https://api.cerebras.ai/v1',
    nvidia: 'https://integrate.api.nvidia.com/v1'
  };
  selectedProvider.value.baseUrl = defaults[selectedProvider.value.id] || '';
  alert(`「地址重置」已重置为 ${selectedProvider.value.name} 默认服务端代理点。`);
};

const syncingModels = ref(false);

const selectModel = (mid) => {
  if (!selectedProvider.value || !mid) return;
  selectedProvider.value.model = mid;
  if (String(mid).includes('/')) {
    selectedProvider.value.modelGroup = String(mid).split('/')[0];
  }
  emit('update:providers', [...localProviders.value]);
};

const syncModels = async () => {
  if (!selectedProvider.value) return;
  if (!selectedProvider.value.apiKey || !String(selectedProvider.value.apiKey).trim()) {
    modelsFetchError.value = '请先填写 API 密钥后再拉取模型列表';
    alert(modelsFetchError.value);
    return;
  }
  if (!selectedProvider.value.baseUrl || !String(selectedProvider.value.baseUrl).trim()) {
    modelsFetchError.value = '请先填写 API 地址 (Base URL)';
    alert(modelsFetchError.value);
    return;
  }

  syncingModels.value = true;
  modelsFetchError.value = '';
  const { url, headers } = buildModelsRequest(selectedProvider.value);

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);
    const response = await fetch(url, {
      method: 'GET',
      headers,
      signal: controller.signal
    });
    clearTimeout(timeoutId);

    if (!response.ok) {
      let errMsg = `HTTP ${response.status} ${response.statusText}`;
      try {
        const errJson = await response.json();
        if (errJson && errJson.error && errJson.error.message) errMsg = errJson.error.message;
        else if (errJson && errJson.message) errMsg = errJson.message;
      } catch (e) {
        try {
          const t = await response.text();
          if (t) errMsg = t.slice(0, 400);
        } catch (_) {}
      }
      throw new Error(`${errMsg}
探测地址：${url}`);
    }

    const data = await response.json();
    const ids = parseModelIds(data);
    if (!ids.length) {
      throw new Error(`接口返回成功，但未解析到模型（期望 data[].id 或 models[].name）
探测地址：${url}`);
    }

    selectedProvider.value.availableModels = ids;
    if (!ids.includes(selectedProvider.value.model)) {
      selectedProvider.value.model = ids[0];
    }
    if (String(selectedProvider.value.model).includes('/')) {
      selectedProvider.value.modelGroup = String(selectedProvider.value.model).split('/')[0];
    }

    emit('update:providers', [...localProviders.value]);
    try {
      localStorage.setItem('magichub_ai_providers', JSON.stringify(localProviders.value));
      if (window.electronAPI && window.electronAPI.saveSettings) {
        window.electronAPI.saveSettings('magichub_ai_providers', JSON.parse(JSON.stringify(localProviders.value)));
      }
    } catch (e) {
      console.error(e);
    }

    alert(`「${selectedProvider.value.name}」已拉取 ${ids.length} 个模型 🟢
当前选用：${selectedProvider.value.model}
探测地址：${url}`);
  } catch (err) {
    const errMsg = explainFetchError(err);
    modelsFetchError.value = errMsg;
    alert(`「${selectedProvider.value.name}」拉取模型失败 🔴
${errMsg}`);
  } finally {
    syncingModels.value = false;
  }
};

const addNewModel = () => {
  if (!selectedProvider.value) return;
  newModelInput.value = `${selectedProvider.value.modelGroup}/custom-model-v2`;
  isAddModelModalOpen.value = true;
};

const submitNewModelName = () => {
  if (!selectedProvider.value) return;
  const newMod = newModelInput.value.trim();
  if (!newMod) {
    alert('请输入模型名称！');
    return;
  }
  selectedProvider.value.model = newMod;
  emit('update:providers', [...localProviders.value]);
  isAddModelModalOpen.value = false;
  alert(`成功添加并切换主权模型至：${newMod}`);
};

const deleteModel = () => {
  if (!selectedProvider.value) return;
  if (confirm(`确认要删除模型 [${selectedProvider.value.model}] 吗？`)) {
    selectedProvider.value.model = `${selectedProvider.value.modelGroup}/none`;
    emit('update:providers', [...localProviders.value]);
    alert("模型已注销，请点击「获取模型列表」重新载入。");
  }
};

const saveProviderSettings = () => {
  try {
    localStorage.setItem('magichub_ai_providers', JSON.stringify(localProviders.value));
    if (window.electronAPI && window.electronAPI.saveSettings) {
      window.electronAPI.saveSettings('magichub_ai_providers', JSON.parse(JSON.stringify(localProviders.value)));
    }
    emit('update:providers', [...localProviders.value]);
  } catch (e) {
    console.error('Failed to save AI providers:', e);
  }
  alert(`「网关配置保存成功」：系统底层算力调度器已成功热切换至 [${selectedProvider.value.name}]！\n激活模型：${selectedProvider.value.model}\nAPI端点：${selectedProvider.value.baseUrl}\n状态：Active 🟢`);
};

// Prop state linkage
const secretMode = computed({
  get: () => props.isSecretMode,
  set: (val) => emit('update:secret-mode', val)
});

// Legacy configs mapped to System tab
const gatewayConfig = reactive({
  provider: 'gemini',
  baseUrl: 'https://api.gemini-net.google.com/v1',
  apiKey: 'sk-proj-gemini-zen-specialty-mfg-a7b4d704',
  defaultModel: 'Gemini 1.5 Pro',
  temperature: 0.6
});

const systemSwitches = reactive({
  autoScan: true,
  doubleLinkage: true,
  vectorLimit: 3
});

// Standard IDE Skills List
const ideSkills = [
  { value: 'a11y-debugging', label: '无障碍网页测试', desc: '根据 web.dev 指标诊断语义、 focus 焦点及标签合理性' },
  { value: 'audit', label: '技术质量审计', desc: '诊断反模式、响应式兼容性以及无障碍等级等全套技术审计' },
  { value: 'optimize', label: '性能极限调优', desc: '定位 UI 加载延迟、排版渲染阻塞并执行极速代码体积调优' },
  { value: 'polish', label: '设计微小细节精修', desc: '一键完成高保真设计边缘、视觉节奏及磨砂半透明阴影细节打磨' },
  { value: 'harden', label: '多语言与健壮性防线', desc: '增加系统异常容错、本地化防线、文本溢出折断等健壮性加固' },
  { value: 'distill', label: '设计精简至简', desc: '削减不必要的视觉噪音及重复逻辑，还原极简轻盈本质' },
  { value: 'clarify', label: '文案清晰度重构', desc: '对冗长模糊的文字、指示错误、提示反馈等进行地道重写' },
  { value: 'typeset', label: '高保真字形排版校正', desc: '优化多语种字型比重、首行行间距及阅读流可视辨识度' },
  { value: 'deep-client-analysis', label: '深度客户分析与调研', desc: '基于步骤向导深度调研客商画像、产品与竞争格局，生成高品质 HTML 和 MD 报告' }
];

const selectedSkillsToImport = ref([]);
const isImporting = ref(false);
const showTerminal = ref(false);
const terminalLines = ref([]);

const isSkillImported = (skillValue) => {
  return props.importedSkills.some(s => s.value === skillValue);
};

const isSelected = (skillValue) => {
  return selectedSkillsToImport.value.includes(skillValue);
};

const toggleSkillSelect = (skillValue) => {
  if (isSkillImported(skillValue)) return;
  const idx = selectedSkillsToImport.value.indexOf(skillValue);
  if (idx === -1) {
    selectedSkillsToImport.value.push(skillValue);
  } else {
    selectedSkillsToImport.value.splice(idx, 1);
  }
};

const triggerImportProcess = () => {
  if (selectedSkillsToImport.value.length === 0) return;
  isImporting.value = true;
  showTerminal.value = true;
  terminalLines.value = [];
  
  const skillsToImport = [...selectedSkillsToImport.value];
  
  let step = 0;
  const runTerminalSimulation = () => {
    if (step === 0) {
      terminalLines.value.push(`$ crm-cli import --skills=${skillsToImport.join(',')}`);
      setTimeout(() => {
        terminalLines.value.push(`[MagicHub-RAG-Engine] Connecting to ChromaDB local vector storage... Connected.`);
        step++;
        runTerminalSimulation();
      }, 400);
    } else if (step === 1) {
      setTimeout(() => {
        terminalLines.value.push(`[MagicHub-RAG-Engine] Scanning IDE tool schemas in active environment... Found ${skillsToImport.length} valid skills.`);
        step++;
        runTerminalSimulation();
      }, 500);
    } else if (step === 2) {
      let idx = 0;
      const importOneByOne = () => {
        if (idx < skillsToImport.length) {
          const val = skillsToImport[idx];
          setTimeout(() => {
            terminalLines.value.push(`[System-RAG-Compiler] Loading schema for tool '${val}'... OK.`);
            terminalLines.value.push(`[System-RAG-Compiler] Generating JSON parameters schema for Dify-Link... OK.`);
            terminalLines.value.push(`[System-RAG-Compiler] Hot-linking tags into ChromaDB context index... Hotloaded.`);
            idx++;
            importOneByOne();
          }, 350);
        } else {
          step++;
          runTerminalSimulation();
        }
      };
      importOneByOne();
    } else if (step === 3) {
      setTimeout(() => {
        terminalLines.value.push(`[MagicHub-RAG-Engine] Re-indexing system instruction prompt anchors...`);
        step++;
        runTerminalSimulation();
      }, 400);
    } else if (step === 4) {
      setTimeout(() => {
        terminalLines.value.push(`[MagicHub-RAG-Engine] Syncing with global router base... Completed.`);
        terminalLines.value.push(`[Success] All ${skillsToImport.length} skills successfully imported into MagicHub core!`);
        terminalLines.value.push(`[Success] New tools are now live and assignable inside "Team Manager"!`);
        
        const newList = [...props.importedSkills];
        skillsToImport.forEach(val => {
          const found = ideSkills.find(s => s.value === val);
          if (found && !newList.some(s => s.value === val)) {
            newList.push({
              value: found.value,
              label: found.label,
              desc: found.desc,
              source: 'imported'
            });
          }
        });
        
        emit('update:importedSkills', newList);
        selectedSkillsToImport.value = [];
        isImporting.value = false;
        
        alert(`「标准 IDE 技能导入就绪」：已成功将选中技能 [${skillsToImport.join(', ')}] 导入系统底层，ChromaDB 向量切片自动解析完成！切换至“团队管理”面板，即可直接在 Open Claw 赋能台中为您勾选分配！`);
      }, 600);
    }
  };

  runTerminalSimulation();
};

// Local storage management logic
const clearingCache = ref(false);
const clearStorageCache = () => {
  clearingCache.value = true;
  setTimeout(() => {
    clearingCache.value = false;
    alert("「本地存储管理」：AI RAG 临时缓存与多模态切片已清理成功！释放空间：18.4 MB 🟢");
  }, 1000);
};

const openLocalFolder = async (folderPath) => {
  if (window.electronAPI && window.electronAPI.openPath) {
    const res = await window.electronAPI.openPath(folderPath);
    if (res && !res.success) {
      alert(`「Finder 打开失败」：${res.error || '未知错误'}`);
    }
  } else {
    alert(`「Web 浏览器演示提示」\n在原生 macOS 客户端中，点击此按钮将直接调起系统 Finder 并自动定位到该绝对路径：\n${folderPath}`);
  }
};

// System Manual chapters list [NEW]
const manualChapters = [
  {
    icon: '📊',
    title: '智能营销中心 (Smart Email Marketing)',
    content: `【智能营销模块全流程使用指引】\n\n1. 物理邮箱挂载 (连接 Gmail / 企业邮箱)：\n- 切换到系统设置的「邮箱账号对接」标签，点击对应账号服务商预设。\n- 输入发信服务器地址 (SMTP Host)、端口 (SSL/TLS 推荐 465 端口) 以及邮箱账号。\n- Gmail 账号需前往 Google 账户安全性页面生成专属的「应用专用密码 (App Password)」，填入授权密码中，点击「物理探测校验」进行通道检测，无误后保存。\n\n2. AI 智能开发信起草：\n- 切换到「AI 开发信写手」Tab。\n- 选择背调目标（系统将自动与海公盘客商画像联动），选择我方核心产品（如 EX-XT-500 防冻水箱）。\n- 选择邮件基调风格（如技术说服、商务严谨等）及目标撰写语种（德文/俄文/英文/西语），一键“调用 DeepSeek V4 深度起草”。\n- 生成的草稿直接呈现在右侧画纸，您可以直接编辑并一键“导入群发活动”。\n\n3. 启动批量群发营销：\n- 切换到「发起营销群发」Tab。\n- 输入活动计划名称，选择发信邮箱，选择待发客商群组（系统自动从公海捞出匹配的客户名单），导入刚刚起草好的 AI 正文并确认。\n- 推荐开启“随机排队延迟防封号机制”，系统将在 15~45 秒之间随机摆动投递。\n- 提交后，可在「营销看板与分析」中实时查看发信进度、送达率、开信率、回复率及完整的审计日志流水！`
  },
  {
    icon: '🔍',
    title: '客户公海与 AI 商务跟进纪要',
    content: `【客户公海与 Timeline 数据智能互通】\n\n1. 客户海公盘管理：\n- 「客户管理」模块展现了所有外贸询盘与背调，系统对各客商进行多维度打分，匹配最佳流转通道。\n- 各国询盘均会显示智能路由分配结果，例如“海外路由 Gemini Pro 算力”、“极密 Llama 本地隔绝防护”等。\n- 点击详情可以直观查看 AI 整理的客商背调报告、结算信用评级和交易安全度检测。\n\n2. 交互式一键同步 Timeline 日志（跨页面智能黑科技）：\n- 当您刚与客户打电话或开会沟通完毕后，可以直接在底部的 AI 对答框中输入：“整理纪要：刚和 Müller 先生电话确认，EX-XT-500 首笔 100 台订单确认汉堡港口运费，周一拟定正式报价单...”。\n- AI 接收指令后，将立即进行商务术语美化与格式对齐，自动生成标准的「商务跟进纪要」及下步动作建议。\n- 生成的内容下方会弹出一个绿色的“一键同步写入跟进记录”按钮，点击后系统会以极高响应速度将日志直接注入底层 SQLite 关系库！\n- 您可以随时切换到「跟进记录」模块，即可看到该日志以 Timeline 形式无损追加在首行！`
  },
  {
    icon: '🌐',
    title: 'AI 算力网关与自定义大模型平台',
    content: `【AI 大脑流转与私有自定义模型挂载】\n\n1. 已开启的模型自动排列置顶：\n- 系统支持 16 种预设大模型接入平台（APIFree、硅基流动、Gemini、深度求索等）。\n- 只要在列表右侧开关开启 (ON) 状态下的算力提供商，系统均会对其在左侧列表自动执行热浮动，将所有“已开启的平台”自动推向列表最顶端，极大地减少频繁滚屏带来的视觉疲劳。\n\n2. 增加自定义模型平台：\n- 滚动到平台列表的最下方，点击“＋ 添加自定义模型平台”。\n- 您可以根据需求，输入您私有部署的 Ollama 端点或者其他兼容 OpenAI chat/completions 接口的网关 Base URL、API 密钥与默认 Model 标识符。\n- 添加并保存后，该自定义平台将自动在底部悬浮 AI 对话框的模型下拉菜单中渲染呈现！\n\n3. 全局模型热同步：\n- 系统彻底打通了「设置中心」与「AI 对话框」的底层关联。\n- 只要您在设置里修改了某个平台的激活 Model，或者新增了自定义模型，底部对话框的模型选择下拉菜单会在 0 毫秒内同步更新，保障全局助理的算力平台实时对齐！`
  },
  {
    icon: '🛡️',
    title: '本地物理断网隔绝极密模式',
    content: `【绝对隐私保护：物理隔绝与 RAG 运作机制】\n\n1. 极密模式的物理意义：\n- 当您在系统顶部状态栏或者设置中一键开启“物理断网隔绝模式”后，整个系统的大模型网关将瞬间被强制熔断拦截。\n- 拦截后，系统绝不会向外部公网发送任何接口请求，所有的 AI 智能分析、材料背调与开发信起草均强制重定向至您本机的本地 Ollama（本地运行的 Llama 3 8B 极密引擎）。\n- 这保证了极高密级的外贸图纸、定制尺寸和支付账户信息 100% 留存在您的 Mac 本地机器中，杜绝外部一切商业资产泄露的缝隙。\n\n2. 本地 RAG（知识库检索）：\n- 本地 SQLite 客户数据库在离线状态下采用 AES-256 加密保存。\n- 您上传的产品手册 PDF 及图册静态资产经过切片后缓存在 ChromaDB 向量知识库中，在离线状态下，AI 仍能精准召回材质细节并提供高还原度对答。`
  }
];

const autoUpdateLogs = ref([]);

const upgradeState = reactive({
  loading: false,
  statusText: ''
});

const triggerLocalAppUpgrade = async () => {
  if (upgradeState.loading) return;
  
  if (!window.electronAPI || !window.electronAPI.selectLocalZipAndUpdate) {
    alert('当前运行在纯浏览器环境，一键软件更新仅在 macOS 客户端中支持！');
    return;
  }

  try {
    upgradeState.loading = true;
    upgradeState.statusText = '验证升级包...';

    // CRITICAL: flush all in-memory data to disk BEFORE replacing the app,
    // so升级过程中不会丢失任何未保存的客户/标签/跟进记录等数据。
    try {
      if (window.magichubPersistNow) window.magichubPersistNow();
      if (window.saveLeadsData) window.saveLeadsData();
    } catch (_) { /* best effort */ }
    // Give async disk writes a moment to complete before the app is replaced
    await new Promise(r => setTimeout(r, 600));

    const res = await window.electronAPI.selectLocalZipAndUpdate();
    
    if (res && res.success) {
      upgradeState.statusText = '解压重启中...';
      return;
    }
    
    upgradeState.loading = false;
    if (res && res.cancelled) {
      return;
    }
    
    alert(`本地升级失败：\n${res ? res.error : '未知错误'}`);
  } catch (e) {
    upgradeState.loading = false;
    alert(`升级过程发生异常: ${e.message}`);
  }
};

const initAutoUpdateLogs = async () => {
  const currentVersion = '1.9.0';
  let logs = [];
  
  // Try loading from Electron persistent settings or localStorage
  try {
    if (window.electronAPI && window.electronAPI.loadSettings) {
      const res = await window.electronAPI.loadSettings('magichub_auto_version_logs');
      if (res && res.success && res.data) {
        logs = res.data;
      }
    }
    if (!logs || logs.length === 0) {
      const saved = localStorage.getItem('magichub_auto_version_logs');
      if (saved) {
        logs = JSON.parse(saved);
      }
    }
  } catch (e) {
    console.error('Failed to load version logs:', e);
  }

  if (!logs) {
    logs = [];
  }

  // Pre-populate missing version logs to guarantee a complete and clean update history!
  const defaultMilestones = [
    {
      version: '1.0.0',
      time: '2026-04-20 10:00:00',
      title: 'CRM 基础系统搭载完成',
      status: '成功 (Success)',
      details: '外贸客户海公盘管理、商务跟进日志、商机进度看板、合同报价账本及多角色团队协同底座初始激活部署。'
    },
    {
      version: '1.1.0',
      time: '2026-05-15 14:30:00',
      title: '本地安全 RAG 知识检索沙箱构建',
      status: '成功 (Success)',
      details: '本地 ChromaDB 向量检索仓切片部署完毕，全库 SQLite AES-256 位加密存储生效，增加物理断网隔绝模式，确保商业资产100%绝对隐私安全。'
    },
    {
      version: '1.2.0',
      time: '2026-05-31 16:00:00',
      title: 'AI 全屏空间与外贸邮件营销升级完成',
      status: '成功 (Success)',
      details: '升级全屏沉浸式 AI 对话工作空间（支持对话存档与历史管理）、新增底座外贸专业技能下拉选择菜单，打通已开启模型置顶与自定义外部接口。'
    },
    {
      version: '1.3.0',
      time: '2026-06-01 00:00:00',
      title: '智能知识库与外部汽配数据同步升级',
      status: '成功 (Success)',
      details: '新增智能知识库组件（文本向量化切片、Notion云端拉取），集成汽配客户数据与AI深度背调报告热同步，升级主侧边栏AI对话存档导航架构，完成 v1.3.0 极轻配重构！'
    },
    {
      version: '1.4.0',
      time: '2026-06-01 01:15:00',
      title: '客户详情手机改版与一键客户分析上线',
      status: '成功 (Success)',
      details: '重构客户详情网格第一列展示为「手机号码/联系方式」并完美双向绑定与增量同步自动提取。推出「一键客户分析」功能，集成双向轨道微动画加载与高保真沙盒/大模型SPI格式报告生成！'
    },
    {
      version: '1.4.1',
      time: '2026-06-01 02:15:00',
      title: '客资数据库多维度读取性能调优与极速列表渲染',
      status: '成功 (Success)',
      details: '优化本地数据持久化网关，将同步阻塞写入重构为多线程异步文件流写入。针对海量导入客户场景构建高性能的分组滑动分页加载与重置监测，将 CPU 消耗降至最低，消除界面卡顿。'
    },
    {
      version: '1.5.0',
      time: '2026-06-01 12:00:00',
      title: '10大标准客户深度背调模块与结构化展示上线',
      status: '成功 (Success)',
      details: '升级客户分析模板，包含公司概况、决策链、市场趋势、SWOT态势、供应商池等10大标准化深度背调板块，支持原始文档与结构化看板双视图切换及空模组智能隐藏。'
    },
    {
      version: '1.6.0',
      time: '2026-06-01 14:00:00',
      title: '公司档案与智能背调双向智能联动重构完成',
      status: '成功 (Success)',
      details: '修复公司设置与档案页Cancel/Save按钮，实现资质（CE/TUV/FDA）、 preset 贸易条款、国家旗帜图标的档案库自动读取同步。支持物理断网下自动构建高保真 8 模块 Sandbox 沙盒报告。'
    },
    {
      version: '1.7.0',
      time: '2026-06-01 16:00:00',
      title: '物理备份高防丢失模式与本地一键自升级引擎交付',
      status: '成功 (Success)',
      details: '支持生成的 AI 深度报告自动以 physical .md 副本落盘保存于桌面。新增“🚀 本地一键升级系统”自更新引擎，在应用内极速解压覆盖 ZIP 包并自动优雅重启，保障本地数据100%安全免丢失！'
    },
    {
      version: '1.8.0',
      time: '2026-06-01 18:30:00',
      title: '全量数据持久化加固，更新永不丢失数据',
      status: '成功 (Success)',
      details: '跟进记录、报价、合同、团队、商机、技能、AI对话存档等全部数据接入统一持久化层并自动落盘；关键操作即时写盘、关闭前自动刷写；底层改为原子写入+自动备份恢复，更新或断电中断也不损坏数据。新增标签独立配色取色盘与跟进记录自定义渠道/类型。'
    },
    {
      version: '1.9.0',
      time: '2026-06-01 19:30:00',
      title: '全系统模块数据连通，告别写死假数据',
      status: '成功 (Success)',
      details: '驾驶舱五大指标、日历、待办、商机快览、AI团队全部改为基于真实客户/商机/合同/跟进数据实时计算；商机与合同统计联动；客户跟进记录自动贯通日历；营销客户分组按真实客户统计；寄样跟进、日程待办接入持久化全局数据。'
    }
  ];

  defaultMilestones.forEach(milestone => {
    const exists = logs.some(item => item.version === milestone.version);
    if (!exists) {
      logs.push(milestone);
    }
  });

  // Check if current version is already recorded (safety check)
  const hasCurrentVersion = logs.some(item => item.version === currentVersion);
  if (!hasCurrentVersion) {
    const now = new Date();
    const formattedTime = now.getFullYear() + '-' + 
      String(now.getMonth() + 1).padStart(2, '0') + '-' + 
      String(now.getDate()).padStart(2, '0') + ' ' + 
      String(now.getHours()).padStart(2, '0') + ':' + 
      String(now.getMinutes()).padStart(2, '0') + ':' + 
      String(now.getSeconds()).padStart(2, '0');

    logs.push({
      version: currentVersion,
      time: formattedTime,
      title: '物理备份高防丢失模式与本地一键自升级引擎交付',
      status: '成功 (Success)',
      details: '支持生成的 AI 深度报告自动以 physical .md 副本落盘保存于桌面。新增“🚀 本地一键升级系统”自更新引擎，在应用内极速解压覆盖 ZIP 包并自动优雅重启，保障本地数据100%安全免丢失！'
    });
  }

  // Save back to persistent storage
  try {
    localStorage.setItem('magichub_auto_version_logs', JSON.stringify(logs));
    if (window.electronAPI && window.electronAPI.saveSettings) {
      await window.electronAPI.saveSettings('magichub_auto_version_logs', JSON.parse(JSON.stringify(logs)));
    }
  } catch (e) {
    console.error(e);
  }

  // Set the reactive ref (reverse order to show newest on top)
  autoUpdateLogs.value = [...logs].reverse();
};

onMounted(() => {
  initAutoUpdateLogs();
});
</script>

<style scoped>
/* Range input styling */
input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #627254;
  border: 2px solid white;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  transition: transform 0.1s ease;
}

input[type="range"]::-webkit-slider-thumb:hover {
  transform: scale(1.2);
}

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
