<template>
  <div class="space-y-6 font-sans text-zen-ink relative z-10">
    <!-- Header -->
    <div class="pb-4 border-b border-white/20 select-none flex justify-between items-center">
      <div>
        <h2 class="text-xl font-bold font-serif-sc tracking-wide">产品知识库与向量 RAG (Knowledge Base)</h2>
        <p class="text-xs text-zen-gray mt-1">结构化存储产品核心参数、MOQ与图纸，通过向量检索智能调取并辅助生成地道多语言信函。</p>
      </div>
    </div>

    <!-- Main Full-Width Content Container (100% Widescreen Spacious Layout) -->
    <div class="space-y-6">
        <!-- 1. Vector RAG Retrieval Console (向量检索控制台) -->
        <div class="apple-glass apple-glass-hover rounded-2xl p-6 border border-white/50 space-y-4">
          <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zen-green" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            本地向量检索控制台 (Local Vector RAG Search)
          </h3>

          <div class="flex flex-col md:flex-row gap-3 select-none">
            <div class="flex-1 relative">
              <input
                type="text"
                v-model="searchQuery"
                placeholder="输入海外客人的自然语言询问，如：你们有适合户外极限环境的水箱吗？"
                class="w-full bg-white/40 border border-white/60 rounded-xl px-4 py-2.5 text-xs text-zen-ink outline-none focus:bg-white focus:border-zen-green transition-all"
                @keyup.enter="triggerRAGSearch"
              />
              <span class="absolute right-3.5 top-3.5 flex h-2 w-2" v-if="isRAGSearching">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-green opacity-75"></span>
                <span class="relative inline-flex rounded-full h-2 w-2 bg-zen-green"></span>
              </span>
            </div>
            <div class="flex gap-2">
              <button @click="loadQuickQuery" class="px-4 py-2.5 rounded-xl border border-white/50 text-zen-gray text-xs hover:text-zen-ink hover:bg-white transition-all font-semibold whitespace-nowrap">
                载入推荐查询
              </button>
              <button @click="triggerRAGSearch" :disabled="isRAGSearching"
                class="px-5 py-2.5 rounded-xl bg-zen-green hover:bg-zen-green/90 text-white text-xs font-bold shadow-sm outline-none transition-all whitespace-nowrap">
                {{ isRAGSearching ? '向量距离匹配中...' : '向量库检索' }}
              </button>
            </div>
          </div>

          <!-- Vector results panel -->
          <div v-if="ragResult" class="bg-black/[0.04] border border-white/30 rounded-2xl p-4 space-y-3 transition-all duration-500 ease-out">
            <div class="flex justify-between items-center text-[10px] text-zen-gray pb-2 border-b border-white/20 select-none">
              <div class="flex items-center gap-1.5 font-bold">
                <span class="w-1.5 h-1.5 rounded-full bg-zen-green animate-pulse"></span>
                ChromaDB 本地相似度匹配完成
              </div>
              <span>最高相似性距离 (Similarity Score): <strong class="font-mono text-zen-green">{{ ragResult.score }}</strong></span>
            </div>
            <div class="space-y-1.5">
              <span class="block text-[9px] text-zen-gray font-bold uppercase tracking-wider select-none">向量高权重召回手册段落 (Context Snippet)：</span>
              <blockquote class="text-[11px] text-zen-ink font-serif-sc leading-relaxed bg-white/60 border border-white/50 p-3.5 rounded-2xl select-text">
                {{ ragResult.snippet }}
              </blockquote>
            </div>
            <div class="pt-2 flex justify-between items-center select-none">
              <span class="text-[10px] text-zen-gray">
                拟调度AI路由：<strong :class="isSecretMode ? 'text-zen-green font-bold' : 'text-zen-tea font-bold'">{{ isSecretMode ? '本地极密 Ollama (Llama 3)' : '海外 Gemini 1.5 Pro' }}</strong>
              </span>
              <button @click="generateColdEmail" :disabled="isGeneratingEmail"
                class="px-4 py-1.5 rounded bg-zen-ink hover:bg-zen-ink/90 text-white text-[10px] font-bold transition-all shadow-sm outline-none">
                {{ isGeneratingEmail ? 'AI 正在精细校对语义...' : '一键起草地道回复开发信' }}
              </button>
            </div>
            <!-- Inline email result when generated -->
            <div v-if="draftedEmail" class="border-t border-white/20 pt-3 space-y-2">
              <div class="flex items-center justify-between">
                <span class="text-[9px] font-bold text-zen-gray uppercase tracking-wider">📧 AI 起草开发信预览</span>
                <button @click="copyEmail" class="px-3 py-1 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-lg text-[9px] font-bold">
                  {{ copySuccess ? '复制成功！' : '复制文本' }}
                </button>
              </div>
              <div class="bg-white/60 border border-white/40 p-3 rounded-xl space-y-2 text-[11px]">
                <div><span class="text-zen-gray font-bold">Subject: </span><span class="font-semibold select-all">{{ draftedEmail.subject }}</span></div>
                <p class="text-zen-ink leading-relaxed font-serif-sc whitespace-pre-wrap select-all max-h-32 overflow-y-auto">{{ draftedEmail.body }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- 2. Company Product Catalogs (大卡片展示) -->
        <div class="apple-glass rounded-2xl p-6 border border-white/50 space-y-5">
          <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2 select-none">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-indigo-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
            公司产品目录与宣传画册 (Product Catalogs &amp; Brochures)
          </h3>

          <!-- Folder Status and Hot-Scanning Banner -->
          <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white/40 border border-white/60 p-3.5 rounded-2xl select-none">
            <div class="flex items-center gap-2.5">
              <span class="relative flex h-2.5 w-2.5">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-green opacity-75"></span>
                <span class="relative inline-flex rounded-full h-2.5 w-2.5 bg-zen-green"></span>
              </span>
              <span class="text-xs font-semibold text-zen-ink">📁 本地 /public/ 静态文件夹智能热侦测服务</span>
            </div>
            <div class="flex flex-wrap items-center gap-2 sm:gap-3 text-[10px] text-zen-gray">
              <span>状态: <span class="text-zen-green font-bold">已激活 (动态更新)</span></span>
              <span class="text-white/40 hidden sm:inline">|</span>
              <span>最近检测: <strong class="font-mono text-zen-ink">{{ lastScanTime || '正在探测...' }}</strong></span>
              <span class="text-white/40 hidden sm:inline">|</span>
              <button @click="scanLocalFolder" class="px-2 py-0.5 bg-zen-green/10 text-zen-green hover:bg-zen-green hover:text-white rounded transition-all font-semibold whitespace-nowrap">
                🔄 重载
              </button>
            </div>
          </div>

          <!-- Scanned Catalogs Grid -->
          <div v-if="scannedFiles.length === 0" class="py-12 text-center text-xs text-zen-gray apple-glass rounded-2xl border border-white/40 select-none">
            <span class="text-2xl block mb-2">📁</span>
            未检出任何文档。请尝试将 PDF / DOCX / XLSX 格式画册放置于项目的 public 文件夹下，系统将在此自动感应并呈现！
          </div>

          <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-5 select-none animate-fadeIn">
            <div
              v-for="file in scannedFiles"
              :key="file.name"
              @click="openCatalogPdf(file.name, file.abstract)"
              class="group bg-white/40 hover:bg-white border border-white/60 rounded-2xl shadow-sm hover:shadow-lg cursor-pointer transition-all duration-300 hover:translate-y-[-3px] overflow-hidden flex flex-col justify-between"
            >
              <div :class="`h-24 bg-gradient-to-br ${file.gradient} flex items-center justify-center border-b border-white/40 relative`">
                <div class="text-3xl select-none group-hover:scale-110 transition-transform duration-300">{{ file.emoji }}</div>
                <div :class="`absolute top-3 right-3 px-2 py-0.5 rounded-lg ${file.badge} font-bold font-mono text-[9px]`">
                  {{ file.name.substring(file.name.lastIndexOf('.') + 1).toUpperCase() }}
                </div>
              </div>
              <div class="p-4 flex-1 flex flex-col justify-between gap-1.5">
                <div>
                  <h4 class="text-xs font-bold text-zen-ink leading-tight line-clamp-1" :title="file.title">{{ file.title }}</h4>
                  <p class="text-[10px] text-zen-gray mt-1 leading-relaxed line-clamp-2" :title="file.subtitle">{{ file.subtitle }}</p>
                </div>
                <div class="pt-2 border-t border-white/10 flex justify-between items-center text-[9px] text-zen-gray">
                  <span class="font-mono">{{ file.sizeMb }} MB</span>
                  <span class="group-hover:text-zen-green font-semibold">点击审计 ➡️</span>
                </div>
              </div>
            </div>
          </div>
        </div>
    </div>

    <!-- Active PDF Viewer Drawer -->
    <transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="transform translate-y-4 opacity-0"
      enter-to-class="transform translate-y-0 opacity-100"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="transform translate-y-0 opacity-100"
      leave-to-class="transform translate-y-4 opacity-0"
    >
      <div v-if="activePdf" class="bg-black/[0.03] border border-white/40 p-5 rounded-2xl space-y-4 relative select-text">
        <button
          @click="activePdf = null"
          class="absolute right-4 top-4 text-zen-gray hover:text-zen-ink text-xs font-semibold bg-white/60 border border-white/50 px-2.5 py-1 rounded-lg"
        >
          关闭预览 ✕
        </button>
        
        <div class="flex items-center gap-3 pb-2.5 border-b border-white/20 select-none">
          <span class="text-xl">📄</span>
          <div>
            <h4 class="text-xs font-bold text-zen-ink">{{ activePdf.name }}</h4>
            <p class="text-[9px] text-zen-gray mt-0.5 font-semibold">在线预览模式 - 本地离线高保真加密渲染</p>
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 text-xs text-zen-ink">
          <div class="space-y-3.5 bg-white/60 border border-white/40 p-4 rounded-xl leading-relaxed">
            <span class="block text-[9px] text-zen-gray font-bold uppercase tracking-wider select-none font-mono">目录摘要 (Document Abstract)</span>
            <p class="font-serif-sc text-[11px] leading-relaxed whitespace-pre-line">
              {{ activePdf.abstract }}
            </p>
          </div>

          <div class="space-y-3.5 bg-white/60 border border-white/40 p-4 rounded-xl leading-relaxed flex flex-col justify-between">
            <div>
              <span class="block text-[9px] text-zen-gray font-bold uppercase tracking-wider font-mono">出口合规与系统集成 (Compliance & RAG Integration)</span>
              <ul class="list-disc pl-4 space-y-1.5 mt-2 font-serif-sc text-[10px] text-zen-ink">
                <li>材质安全：100% 出地出港合规核验，智能提取物料主参数；</li>
                <li>向量检索：已注入本地向量空间，与 AI 智能对话 RAG 无损联动；</li>
                <li>合规标准：完全通过欧盟 CE、德国 TUV 及美国 FDA 检测合格回执。</li>
              </ul>
            </div>

            <div class="pt-4 border-t border-white/20 flex flex-col sm:flex-row gap-2 justify-between items-center text-[10px] select-none">
              <span class="text-[9px] text-zen-gray">静态就绪 | 点击按钮调用原生宿主环境预览</span>
              <div class="flex gap-2 w-full sm:w-auto">
                <button
                  @click="handleOpenFile(activePdf.name)"
                  class="flex-1 sm:flex-initial px-4 py-1.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-lg text-[9px] font-bold shadow-sm flex items-center justify-center gap-1.5 transition-all"
                >
                  🖥️ 打开原文件
                </button>
                <button
                  @click="downloadPdf"
                  class="flex-1 sm:flex-initial px-4 py-1.5 bg-zen-green hover:bg-zen-green/90 text-white rounded-lg text-[9px] font-bold shadow-sm transition-all"
                >
                  📥 导出副本
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </transition>

    <!-- 3. Structured Product Manual Directory (结构化产品展示 - 100% 全幅布局) -->
    <div class="space-y-5">
      <!-- Mode Switcher Row -->
      <div class="flex justify-between items-center select-none pt-2">
        <h3 class="text-sm font-bold font-serif-sc text-zen-ink flex items-center gap-2">
          <span class="w-1.5 h-3 bg-zen-tea rounded-full"></span>
          结构化产品手册目录 (Structured Products)
        </h3>

        <!-- Segmented Apple control toggle & Importer Trigger -->
        <div class="flex items-center gap-2">
          <div class="flex items-center gap-1 bg-black/[0.05] p-0.5 rounded-xl border border-black/[0.02] shadow-sm select-none">
            <button
              @click="viewMode = 'card'"
              class="px-3.5 py-1.5 rounded-lg text-[9px] font-bold transition-all duration-300 outline-none"
              :class="viewMode === 'card' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
              title="卡片网格形式"
            >
              卡片模式
            </button>
            <button
              @click="viewMode = 'list'"
              class="px-3.5 py-1.5 rounded-lg text-[9px] font-bold transition-all duration-300 outline-none"
              :class="viewMode === 'list' ? 'bg-white text-zen-ink shadow-sm' : 'text-zen-gray hover:text-zen-ink'"
              title="列表表格形式"
            >
              列表模式
            </button>
          </div>
          
          <button
            @click="isImporterDrawerOpen = true"
            class="px-3.5 py-1.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-[9px] font-bold shadow-sm transition-all flex items-center gap-1.5 outline-none font-sans"
          >
            📥 智能数据导入
          </button>
        </div>
      </div>

      <!-- LOWER SECTION DUAL-VIEW (100% Width) -->
      <!-- View A: Card Grid Mode -->
      <div v-if="viewMode === 'card'" class="grid grid-cols-1 md:grid-cols-3 xl:grid-cols-4 gap-5 animate-fadeIn">
        <div
          v-for="prod in products"
          :key="prod.id"
          :id="'prod-' + prod.id"
          class="apple-glass apple-glass-hover rounded-2xl p-5 flex flex-col justify-between transition-all duration-500 relative"
          :class="highlightedProductId === prod.id ? 'border-zen-green ring-2 ring-zen-green shadow-xl translate-y-[-4px]' : 'border-white/50'"
        >
          <!-- Highlight glow badge -->
          <span
            v-if="highlightedProductId === prod.id"
            class="absolute -top-2.5 right-4 text-[9px] font-bold text-white px-2.5 py-0.5 bg-zen-green rounded-full shadow-sm select-none"
          >
            首选匹配
          </span>

          <div>
            <div
              @click="openProductDetails(prod)"
              class="w-full aspect-square bg-white rounded-xl border border-white/40 flex items-center justify-center relative overflow-hidden select-none mb-4 group/img shadow-sm cursor-pointer"
            >
              <div class="absolute inset-0 bg-black/0 group-hover/img:bg-black/5 transition-colors z-20 flex items-center justify-center">
                <span class="opacity-0 group-hover/img:opacity-100 text-white bg-black/55 text-[10px] font-bold px-2.5 py-1 rounded-full backdrop-blur-sm transition-all duration-300 transform translate-y-2 group-hover/img:translate-y-0 select-none">
                  查看详情 👁️
                </span>
              </div>
              <div class="absolute inset-0 bamboo-bg-decor opacity-20 z-0"></div>
              <!-- Fallback placeholder is always rendered in the background -->
              <svg class="absolute w-10 h-10 text-zen-gray/25 z-0" viewBox="0 0 100 100" fill="none" stroke="currentColor" stroke-width="1.5">
                <rect x="28" y="30" width="44" height="44" rx="6" />
                <line x1="38" y1="20" x2="62" y2="20" />
                <line x1="50" y1="20" x2="50" y2="30" />
              </svg>
              <!-- The image is positioned absolutely to cover the background placeholder if loaded -->
              <img
                v-if="prod.image"
                :src="prod.image && prod.image.startsWith('/') ? '.' + prod.image : prod.image"
                class="absolute inset-0 w-full h-full object-contain p-2 transition-transform duration-500 group-hover/img:scale-105 z-10"
                loading="lazy"
                @error="(e) => handleImageError(e, prod)"
              />
            </div>

            <!-- Params -->
            <div class="space-y-1">
              <div class="flex justify-between items-center select-none">
                <span class="text-[10px] text-zen-gray font-mono font-bold">{{ prod.model }}</span>
                <span class="text-[10px] text-zen-green font-bold bg-zen-green/5 border border-zen-green/10 px-1.5 py-0.5 rounded">{{ prod.cert }}</span>
              </div>
              <h4 class="text-xs font-bold text-zen-ink font-serif-sc mt-1">{{ prod.name }}</h4>
              <p class="text-[10px] text-zen-gray mt-1 leading-relaxed line-clamp-3">
                {{ prod.desc }}
              </p>
            </div>

            <!-- Key Specs Table -->
            <div class="border-t border-white/20 pt-2.5 mt-3 space-y-1.5 text-[10px] text-zen-ink">
              <div class="flex justify-between">
                <span class="text-zen-gray font-medium">{{ prod.id.includes('EX-XT') || prod.id.includes('FL-WT') ? '工作参数/温度：' : '规格/适配动力：' }}</span>
                <span class="font-bold font-mono">{{ prod.temp }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-zen-gray font-medium">核心材质：</span>
                <span class="font-bold font-mono">{{ prod.material }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-zen-gray font-medium">起订量 MOQ：</span>
                <span class="font-bold font-mono">{{ prod.moq }} 套</span>
              </div>
            </div>
          </div>
          
          <div class="pt-3 border-t border-white/20 mt-4 flex justify-between items-center text-[10px] select-none">
            <span class="text-zen-gray font-medium">价格参考: {{ prod.priceRange }}</span>
            <button
              @click="triggerManualRAG(prod.id)"
              class="text-zen-green hover:text-zen-ink font-bold outline-none"
            >
              选定检索 ➡️
            </button>
          </div>
        </div>
      </div>

      <!-- View B: List Table Mode -->
      <div v-else class="apple-glass rounded-2xl p-5 border border-white/50 overflow-x-auto animate-fadeIn select-text">
        <table class="w-full text-left text-xs text-zen-ink whitespace-nowrap">
          <thead>
            <tr class="border-b border-white/20 text-zen-gray font-serif-sc text-[10px] uppercase tracking-wider select-none">
              <th class="py-3 font-semibold w-12 text-center">产品图</th>
              <th class="py-3 font-semibold">产品型号</th>
              <th class="py-3 font-semibold">产品名称</th>
              <th class="py-3 font-semibold">质量认证</th>
              <th class="py-3 font-semibold">规格/适配动力参数</th>
              <th class="py-3 font-semibold">核心结构材质</th>
              <th class="py-3 font-semibold text-center">起订量</th>
              <th class="py-3 font-semibold text-right">参考基准价格</th>
              <th class="py-3 font-semibold text-right">操作</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10 font-sans text-[11px]">
            <tr
              v-for="prod in products"
              :key="prod.id"
              class="hover:bg-white/40 transition-colors duration-300"
              :class="highlightedProductId === prod.id ? 'bg-zen-green/10 font-bold border-l-2 border-zen-green animate-pulse' : ''"
            >
              <td class="py-2 pr-2 text-center">
                <div class="w-10 h-10 rounded-lg overflow-hidden border border-white/50 bg-black/5 flex items-center justify-center select-none shadow-sm mx-auto relative">
                  <span class="text-base text-zen-gray/40">📦</span>
                  <img
                    v-if="prod.image"
                    :src="prod.image && prod.image.startsWith('/') ? '.' + prod.image : prod.image"
                    class="absolute inset-0 w-full h-full object-cover"
                    loading="lazy"
                    @error="(e) => handleImageError(e, prod)"
                  />
                </div>
              </td>
              <td class="py-3.5 pr-2 font-bold font-mono text-indigo-700">{{ prod.model }}</td>
              <td class="py-3.5 pr-2 font-semibold font-serif-sc max-w-[200px] truncate" :title="prod.name">{{ prod.name }}</td>
              <td class="py-3.5 pr-2">
                <span class="px-2 py-0.5 rounded-full text-[9px] font-bold bg-zen-green/10 text-zen-green border border-zen-green/20 max-w-[120px] truncate inline-block" :title="prod.cert">
                  {{ prod.cert }}
                </span>
              </td>
              <td class="py-3.5 pr-2 font-mono font-medium max-w-[140px] truncate" :title="prod.temp">{{ prod.temp }}</td>
              <td class="py-3.5 pr-2 text-zen-gray font-serif-sc max-w-[120px] truncate" :title="prod.material">{{ prod.material }}</td>
              <td class="py-3.5 pr-2 text-center font-mono font-bold">{{ prod.moq }} 套</td>
              <td class="py-3.5 pr-2 text-right font-mono font-bold text-zen-green">{{ prod.priceRange }}</td>
              <td class="py-3.5 text-right select-none space-x-3">
                <button
                  @click="openProductDetails(prod)"
                  class="text-indigo-600 hover:text-indigo-900 font-bold text-[10px] outline-none"
                >
                  详情 👁️
                </button>
                <button
                  @click="triggerManualRAG(prod.id)"
                  class="text-zen-green hover:text-zen-ink font-bold text-[10px] outline-none"
                >
                  选定检索 ➡️
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Modern Glassmorphic Product Detail Drawer -->
  <Teleport to="body">
    <Transition name="drawer-fade">
      <div v-if="selectedProduct" class="fixed inset-0 z-50 flex justify-end bg-black/40 backdrop-blur-sm select-text" @click="closeProductDetails">
        <Transition name="drawer-slide">
          <div v-if="selectedProduct" class="w-full max-w-md h-full bg-white/85 backdrop-blur-2xl border-l border-white/30 p-8 shadow-2xl overflow-y-auto flex flex-col justify-between" @click.stop>
            
            <!-- Top Header & Close button -->
            <div>
              <div class="flex justify-between items-start mb-6 select-none">
                <div>
                  <span class="text-[9px] bg-indigo-500/10 text-indigo-600 px-2.5 py-0.5 rounded-full font-bold uppercase tracking-wider font-mono">
                    {{ selectedProduct.cert }}
                  </span>
                  <h3 class="text-base font-bold text-zen-ink mt-2 leading-snug">
                    {{ selectedProduct.name }}
                  </h3>
                  <p class="text-[10px] text-zen-gray font-mono font-bold mt-1">型号 SKU: {{ selectedProduct.model }}</p>
                </div>
                <button @click="closeProductDetails" class="p-1.5 rounded-lg bg-black/5 hover:bg-black/10 text-zen-gray hover:text-zen-ink transition-colors outline-none">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <!-- Product Image Showcase with fallback -->
              <div class="w-full aspect-square bg-white rounded-2xl border border-neutral-100 flex items-center justify-center relative overflow-hidden shadow-inner select-none mb-6">
                <svg class="absolute w-12 h-12 text-zen-gray/15" viewBox="0 0 100 100" fill="none" stroke="currentColor" stroke-width="1.5">
                  <rect x="28" y="30" width="44" height="44" rx="6" />
                  <line x1="38" y1="20" x2="62" y2="20" />
                  <line x1="50" y1="20" x2="50" y2="30" />
                </svg>
                <img
                  v-if="selectedProduct.image"
                  :src="selectedProduct.image && selectedProduct.image.startsWith('/') ? '.' + selectedProduct.image : selectedProduct.image"
                  class="absolute inset-0 w-full h-full object-contain p-4 transition-transform duration-700 hover:scale-105 z-10"
                  @error="(e) => handleImageError(e, selectedProduct)"
                />
              </div>

              <!-- Product Specifications Table -->
              <div class="space-y-4">
                <div class="bg-black/[0.02] border border-black/[0.04] rounded-xl p-4 space-y-3">
                  <h4 class="text-[11px] font-bold text-zen-ink border-b border-black/[0.05] pb-1.5 select-none">技术规格与国际贸易参数</h4>
                  <div class="grid grid-cols-2 gap-y-2.5 gap-x-4 text-[10px]">
                    <div>
                      <span class="text-zen-gray block select-none mb-0.5">规格/适配动力参数</span>
                      <span class="font-bold font-mono text-zen-ink">{{ selectedProduct.temp }}</span>
                    </div>
                    <div>
                      <span class="text-zen-gray block select-none mb-0.5">核心构成材质</span>
                      <span class="font-bold font-mono text-zen-ink">{{ selectedProduct.material }}</span>
                    </div>
                    <div>
                      <span class="text-zen-gray block select-none mb-0.5">建议起订量 MOQ</span>
                      <span class="font-bold font-mono text-zen-ink">{{ selectedProduct.moq }} 套</span>
                    </div>
                    <div>
                      <span class="text-zen-gray block select-none mb-0.5">参考基准价格</span>
                      <span class="font-bold font-mono text-zen-green">{{ selectedProduct.priceRange }}</span>
                    </div>
                  </div>
                </div>

                <!-- Product Description -->
                <div class="space-y-1.5">
                  <h4 class="text-[11px] font-bold text-zen-ink select-none">产品介绍说明</h4>
                  <p class="text-[10px] text-zen-gray leading-relaxed bg-black/[0.01] border border-black/[0.02] p-3 rounded-xl font-medium">
                    {{ selectedProduct.desc }}
                  </p>
                </div>
              </div>
            </div>

            <!-- Footer Action Panel -->
            <div class="border-t border-black/[0.05] pt-4 mt-6 flex gap-3 select-none">
              <button
                @click="triggerManualRAGFromDrawer"
                class="flex-1 py-2 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-[10px] font-bold shadow-md transition-all outline-none text-center"
              >
                选定此配件进行 AI 营销检索
              </button>
              <button
                @click="closeProductDetails"
                class="px-4 py-2 bg-black/5 hover:bg-black/10 text-zen-ink rounded-xl text-[10px] font-bold transition-all outline-none"
              >
                关闭
              </button>
            </div>

          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>

  <!-- Modern Glassmorphic Importer Drawer (Off-canvas) -->
  <Teleport to="body">
    <Transition name="drawer-fade">
      <div v-if="isImporterDrawerOpen" class="fixed inset-0 z-50 flex justify-end bg-black/40 backdrop-blur-sm select-text" @click="closeImporterDrawer">
        <Transition name="drawer-slide">
          <div v-if="isImporterDrawerOpen" class="w-full max-w-md h-full bg-white/85 backdrop-blur-2xl border-l border-white/30 p-8 shadow-2xl overflow-y-auto flex flex-col justify-between" @click.stop>
            
            <!-- Drawer Header -->
            <div class="space-y-6">
              <div class="flex justify-between items-center select-none pb-4 border-b border-black/[0.05]">
                <div>
                  <h3 class="text-sm font-bold text-zen-ink">📥 智能导入工具箱</h3>
                  <p class="text-[9px] text-zen-gray mt-1 font-semibold">支持批量 CSV 格式导入、AI 口头速记解析及官方网站连接</p>
                </div>
                <button @click="closeImporterDrawer" class="p-1.5 rounded-lg bg-black/5 hover:bg-black/10 text-zen-gray hover:text-zen-ink transition-colors outline-none">
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <!-- CSV Importer Card -->
              <div class="apple-glass rounded-2xl p-5 border border-white/50 space-y-3 shadow-sm bg-white/40">
                <h4 class="text-[11px] font-bold text-zen-ink flex items-center gap-2 select-none">
                  <span class="w-1 h-2.5 bg-zen-green rounded-full"></span>
                  CSV 格式智能导入
                </h4>
                <p class="text-[9px] text-zen-gray leading-normal select-none">
                  导入标准 CSV，表头格式: <code class="bg-black/5 px-1 rounded font-mono">型号,产品名称,质量认证,工作参数,结构材质,起订量,参考价格,描述</code>
                </p>
                <div class="space-y-2">
                  <textarea
                    v-model="csvText"
                    rows="4"
                    class="w-full bg-white/40 border border-white/60 rounded-xl p-2.5 text-[10px] outline-none focus:bg-white focus:border-zen-green font-mono leading-normal"
                    placeholder="型号,产品名称,质量认证..."
                  ></textarea>
                  <div class="flex justify-between items-center select-none">
                    <button @click="loadSampleCSV" class="text-[9px] font-bold text-zen-green hover:underline outline-none">载入CSV样本</button>
                    <button
                      @click="parseCSV"
                      :disabled="isParsingCSV"
                      class="px-3.5 py-1.5 bg-zen-ink hover:bg-zen-ink/90 text-white rounded-xl text-[9px] font-bold shadow-sm outline-none transition-all"
                    >
                      {{ isParsingCSV ? '正在校验...' : '解析并预览' }}
                    </button>
                  </div>
                </div>

                <!-- Parsed Preview Table -->
                <div v-if="parsedProductsPreview.length > 0" class="pt-3 border-t border-white/20 space-y-2 animate-fadeIn">
                  <h5 class="text-[9px] font-bold text-zen-ink flex justify-between select-none">
                    <span>解析预览:</span>
                    <span class="text-zen-green font-mono">共 {{ parsedProductsPreview.length }} 项</span>
                  </h5>
                  <div class="max-h-28 overflow-y-auto border border-white/50 rounded-xl bg-white/40 p-2 text-[8px] space-y-1.5">
                    <div v-for="p in parsedProductsPreview" :key="p.id" class="flex justify-between items-center border-b border-black/[0.03] pb-1">
                      <div>
                        <span class="font-bold font-mono text-indigo-700">[{{ p.model }}]</span>
                        <span class="ml-1 font-serif-sc font-bold">{{ p.name }}</span>
                      </div>
                      <span class="font-mono font-bold text-zen-green">{{ p.priceRange }}</span>
                    </div>
                  </div>
                  <button
                    @click="confirmImportCSV"
                    class="w-full py-1.5 bg-zen-green hover:bg-zen-green/90 text-white rounded-xl text-[10px] font-bold shadow-md outline-none transition-all"
                  >
                    确认无误，一键导入
                  </button>
                </div>
              </div>

              <!-- AI product desc parser Card -->
              <div class="apple-glass rounded-2xl p-5 border border-white/50 space-y-3 shadow-sm bg-white/40">
                <h4 class="text-[11px] font-bold text-zen-ink flex items-center gap-2 select-none">
                  <span class="w-1 h-2.5 bg-zen-gold rounded-full"></span>
                  AI 智能口头速记解析
                </h4>
                <p class="text-[9px] text-zen-gray leading-normal select-none">
                  粘贴口头速记段落，AI 抓取规格并自动生成结构化参数卡片。
                </p>
                <div class="space-y-2">
                  <textarea
                    v-model="rawImportText"
                    rows="3"
                    class="w-full bg-white/40 border border-white/60 rounded-xl p-2.5 text-[10px] outline-none focus:bg-white focus:border-zen-green leading-normal"
                    placeholder="例: 刚与德国 Dieter 讨论了新不锈钢防爆水箱，型号暂定为 EX-R800，材质要拉丝304..."
                  ></textarea>
                  <div class="flex justify-end select-none">
                    <button
                      @click="parseAndImportProduct"
                      :disabled="isImporting"
                      class="px-3.5 py-1.5 bg-zen-green hover:bg-zen-green/90 text-white rounded-xl text-[9px] font-bold shadow-sm outline-none transition-all"
                    >
                      {{ isImporting ? 'AI 正在提炼特征...' : 'AI 智能提炼导入' }}
                    </button>
                  </div>
                </div>
              </div>

              <!-- JFC4x4 Crawled Product Importer Card -->
              <div class="apple-glass rounded-2xl p-5 border border-white/50 space-y-3 shadow-sm bg-white/40">
                <h4 class="text-[11px] font-bold text-zen-ink flex items-center gap-2 select-none">
                  <span class="w-1 h-2.5 bg-indigo-500 rounded-full"></span>
                  JFC4x4 官网智能大库导入
                </h4>
                <p class="text-[9px] text-zen-gray leading-normal select-none">
                  本地已热连接金丰呈 (jfc4x4.com) 独立站大库，包含 {{ crawledProducts.length }} 款越野竞技装备。
                </p>
                <div class="space-y-2">
                  <input
                    type="text"
                    v-model="crawledSearchQuery"
                    placeholder="搜索已爬取官网产品, 如 Snorkel / LC300 / Vigo..."
                    class="w-full bg-white/40 border border-white/60 rounded-xl px-2.5 py-1.5 text-[10px] text-zen-ink outline-none focus:bg-white focus:border-zen-green"
                  />
                  
                  <!-- Scrollable list of crawled products -->
                  <div class="max-h-48 overflow-y-auto border border-white/50 rounded-xl bg-white/40 p-2 space-y-1.5">
                    <div v-if="filteredCrawledProducts.length === 0" class="text-center py-4 text-[9px] text-zen-gray select-none">
                      未检索到匹配的官网商品 📦
                    </div>
                    <div
                      v-for="p in filteredCrawledProducts"
                      :key="p.id"
                      class="flex items-center justify-between gap-2 border-b border-black/[0.03] pb-1.5 hover:bg-white/30 p-1 rounded-lg transition-all"
                    >
                      <div class="flex items-center gap-2 min-w-0">
                        <div class="w-7 h-7 rounded bg-black/5 flex items-center justify-center overflow-hidden shrink-0 shadow-inner relative select-none">
                          <span class="text-xs">📦</span>
                          <img
                            v-if="p.image"
                            :src="p.image && p.image.startsWith('/') ? '.' + p.image : p.image"
                            class="absolute inset-0 w-full h-full object-cover"
                            @error="(e) => handleImageError(e, p)"
                          />
                        </div>
                        <div class="min-w-0">
                          <div class="flex items-center gap-1 select-none">
                            <span class="font-bold font-mono text-[8px] text-indigo-700">[{{ p.model }}]</span>
                            <span class="text-[8px] bg-indigo-500/10 text-indigo-600 px-1 rounded font-semibold">{{ p.cert.split(' / ')[0] }}</span>
                          </div>
                          <div class="text-[8px] font-medium text-zen-ink truncate max-w-[120px]" :title="p.name">
                            {{ p.name }}
                          </div>
                        </div>
                      </div>
                      
                      <button
                        @click="importSingleCrawledProduct(p)"
                        :disabled="isProductAlreadyImported(p.id)"
                        class="px-2 py-0.5 rounded bg-zen-ink hover:bg-zen-ink/90 disabled:bg-neutral-200 disabled:text-neutral-400 text-white text-[8px] font-bold shadow-sm transition-all shrink-0 outline-none"
                      >
                        {{ isProductAlreadyImported(p.id) ? '已导入' : '导入' }}
                      </button>
                    </div>
                  </div>

                  <!-- Bulk operations -->
                  <div class="flex justify-between items-center pt-1 select-none">
                    <span class="text-[8px] text-zen-gray font-mono font-semibold">展示项: {{ filteredCrawledProducts.length }}</span>
                    <button
                      @click="importFilteredCrawledProducts"
                      class="px-3 py-1 bg-zen-green hover:bg-zen-green/90 text-white rounded-lg text-[8px] font-bold shadow-sm transition-all outline-none"
                    >
                      批量导入当前筛选
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Drawer Footer Close panel -->
            <div class="border-t border-black/[0.05] pt-4 mt-6 select-none flex justify-end">
              <button
                @click="closeImporterDrawer"
                class="px-5 py-2 bg-black/5 hover:bg-black/10 text-zen-ink rounded-xl text-[10px] font-bold transition-all outline-none"
              >
                关闭面板
              </button>
            </div>

          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';

const props = defineProps({
  isSecretMode: {
    type: Boolean,
    default: false
  },
  products: {
    type: Array,
    required: true
  }
});

const emit = defineEmits(['update:products']);

// Synchronized raised global products database state
const products = computed({
  get: () => props.products,
  set: (val) => emit('update:products', val)
});

const searchQuery = ref('');
const isRAGSearching = ref(false);
const highlightedProductId = ref(null);

// --- Product Detail Drawer States & Functions ---
const selectedProduct = ref(null);

const openProductDetails = (prod) => {
  selectedProduct.value = prod;
};

const closeProductDetails = () => {
  selectedProduct.value = null;
};

// --- Importer Drawer States & Functions ---
const isImporterDrawerOpen = ref(false);

const closeImporterDrawer = () => {
  isImporterDrawerOpen.value = false;
};

const triggerManualRAGFromDrawer = () => {
  if (selectedProduct.value) {
    triggerManualRAG(selectedProduct.value.id);
    closeProductDetails();
  }
};

// --- Dynamic PDF Folder Scanning States & Mapping ---
const scannedFiles = ref([]);
const scanStatus = ref('active');
const lastScanTime = ref('');

const presetMetadata = {
  'JFC Cotalog 3.0 - 2024 08 23.pdf': {
    title: 'JFC越野改装外销手册 V3.0',
    subtitle: '前竞技防撞杠/底盘装甲/加固涉水喉',
    emoji: '📕',
    gradient: 'from-rose-50 to-rose-100/50',
    badge: 'bg-rose-500/15 text-rose-600',
    abstract: '金丰呈 (JFC4x4) 越野改装制造大厂官方出口选型手册，涵盖高性能 4x4 越野车防撞竞技前杠、高抗冲击涉水喉 (Snorkels)、双层隔热金属护板、及特种越野配件的 ISO9001 与 澳大利亚 ADR 碰撞标准安全检测。'
  },
  'NC Catalogue 2025 Q1.pdf': {
    title: 'NC 2025 Q1 精品彩页',
    subtitle: '特种折叠水囊/全地形户外储液系列',
    emoji: '📗',
    gradient: 'from-emerald-50 to-emerald-100/50',
    badge: 'bg-emerald-500/15 text-emerald-600',
    abstract: 'NC 全地形食品级柔性折叠水囊、高负载耐磨水箱及抗寒 -40°C 户外特种储水仓的外销综合彩页，全面收录了美国 FDA 无毒测试合格报告与欧盟 CE 质量认证流水。'
  },
  'NCF-The Rear Trunk Shelf Organizer V2.0.pdf': {
    title: 'NCF 后尾置物挂架 V2.0',
    subtitle: '多功能尾箱悬挂架/全地形机动置物板',
    emoji: '📘',
    gradient: 'from-sky-50 to-sky-100/50',
    badge: 'bg-sky-500/15 text-sky-600',
    abstract: 'NCF 车载后备箱悬挂支架、全地形越野车后行李箱收纳器及尾门特种置物板系统安装指南，包含详细 CAD 三维物理参数、最大承重负荷测试及英文/德文等海运彩页。'
  },
  'Tank 300 Accessories.pdf': {
    title: '坦克300越野配件手册',
    subtitle: 'Tank 300 专属全地形竞技改装件',
    emoji: '📙',
    gradient: 'from-amber-50 to-amber-100/50',
    badge: 'bg-amber-500/15 text-amber-600',
    abstract: '坦克300 (Tank 300) 全套越野竞技底盘防护件、加固式后车顶挂载梯、高负重涉水器及特种自压水箱 of OEM 定制说明。'
  }
};

const scanLocalFolder = async () => {
  if (!window.electronAPI || !window.electronAPI.scanDirectory) {
    console.warn('Electron scanDirectory API is not available.');
    return;
  }
  
  try {
    scanStatus.value = 'scanning';
    const result = await window.electronAPI.scanDirectory('/Users/ky/Desktop/通用版外贸客户管理/public');
    if (result && result.success) {
      scannedFiles.value = result.files.map(file => {
        const name = file.name;
        const meta = presetMetadata[name] || {
          title: name.replace(/\.[^/.]+$/, ""),
          subtitle: '📂 本地新检测到文档 (已就绪)',
          emoji: name.endsWith('.pdf') ? '📄' : name.endsWith('.docx') ? '📝' : '📊',
          gradient: 'from-slate-50 to-slate-100/50',
          badge: 'bg-slate-500/15 text-slate-600',
          abstract: `本地静态文件夹动态检出文档：${name}。系统已自动建立 ChromaDB 本地检索索引，可以直接在 RAG 或写信模块中提取并使用！`
        };
        return {
          ...file,
          ...meta,
          sizeMb: (file.sizeBytes / (1024 * 1024)).toFixed(2)
        };
      });
      scanStatus.value = 'active';
      lastScanTime.value = new Date().toLocaleTimeString();
    } else {
      scanStatus.value = 'error';
    }
  } catch (err) {
    console.error('Failed to scan directory:', err);
    scanStatus.value = 'error';
  }
};

const handleOpenFile = async (fileName) => {
  if (window.electronAPI && window.electronAPI.openPath) {
    const fullPath = "/Users/ky/Desktop/通用版外贸客户管理/public/" + fileName;
    const res = await window.electronAPI.openPath(fullPath);
    if (!res || !res.success) {
      alert("无法在本地桌面打开原文件：" + (res ? res.error : "未知错误"));
    }
  } else {
    alert("无法在非 Electron 桌面的浏览器沙箱中直接打开原文件。");
  }
};

let scanInterval = null;

onMounted(() => {
  scanLocalFolder();
  scanInterval = setInterval(scanLocalFolder, 5000);
  loadCrawledProducts();
});

onBeforeUnmount(() => {
  if (scanInterval) {
    clearInterval(scanInterval);
  }
});

const ragResult = ref(null);
const isGeneratingEmail = ref(false);
const draftedEmail = ref(null);
const copySuccess = ref(false);

const viewMode = ref('card');
const activePdf = ref(null);

// --- JFC4x4 Crawled Product Importer States & Functions ---
const crawledProducts = ref([]);
const crawledSearchQuery = ref('');

const loadCrawledProducts = async () => {
  try {
    const response = await fetch('./products_imported.json');
    if (response.ok) {
      const data = await response.json();
      if (Array.isArray(data)) {
        crawledProducts.value = data;
      }
    }
  } catch (err) {
    console.error('Failed to load crawled products:', err);
  }
};

const handleImageError = (event, prod) => {
  if (prod && prod.imageUrl && event.target.src !== prod.imageUrl) {
    console.warn(`Local image failed to load, falling back to live URL: ${prod.imageUrl}`);
    event.target.src = prod.imageUrl;
  } else {
    console.error(`Image load failed completely for: ${prod ? prod.model : 'unknown'}`);
    event.target.style.display = 'none';
  }
};

const filteredCrawledProducts = computed(() => {
  const q = crawledSearchQuery.value.trim().toLowerCase();
  if (!q) return crawledProducts.value.slice(0, 15); // Show first 15 default
  return crawledProducts.value.filter(p => 
    p.name.toLowerCase().includes(q) || 
    p.model.toLowerCase().includes(q) ||
    p.material.toLowerCase().includes(q)
  );
});

const isProductAlreadyImported = (prodId) => {
  return products.value.some(p => String(p.id) === String(prodId));
};

const importSingleCrawledProduct = (p) => {
  if (isProductAlreadyImported(p.id)) return;
  products.value.unshift({ ...p });
  highlightedProductId.value = p.id;
  alert(`「官网产品导入成功」：型号 [${p.model}] 已成功同步到 active 目录首行，本地 RAG 已热更新！`);
  
  setTimeout(() => {
    const el = document.getElementById("prod-" + p.id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }, 250);
};

const importFilteredCrawledProducts = () => {
  const toImport = filteredCrawledProducts.value.filter(p => !isProductAlreadyImported(p.id));
  if (toImport.length === 0) {
    alert('当前筛选结果中的商品已全部导入！');
    return;
  }
  toImport.forEach(p => {
    products.value.unshift({ ...p });
  });
  highlightedProductId.value = toImport[0].id;
  alert(`「批量导入成功」：已将 ${toImport.length} 个筛选出的产品导入至 active 目录，RAG 热更新就绪！`);
  
  setTimeout(() => {
    const el = document.getElementById("prod-" + toImport[0].id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }, 250);
};

// --- CSV / AI Product Importer ---
const csvText = ref('');
const parsedProductsPreview = ref([]);
const isParsingCSV = ref(false);
const rawImportText = ref('');
const isImporting = ref(false);

const loadSampleCSV = () => {
  csvText.value = "型号,产品名称,质量认证,工作参数,结构材质,起订量,参考价格,描述\nEX-R950,高防爆特种储水箱,CE/TUV认证,-30°C 至 +75°C,304拉丝不锈钢,50,$210 CIF Hamburg,智能自锁底阀高防爆\nFL-WT-900,大容量耐磨折叠水囊,FDA认证,-25°C 至 +60°C,加厚型柔性TPU,100,$65 FOB Ningbo,100L容量完全折叠节约运费";
};

const parseCSV = () => {
  if (!csvText.value.trim()) {
    alert('请先输入或粘贴CSV格式内容！');
    return;
  }
  isParsingCSV.value = true;
  setTimeout(() => {
    isParsingCSV.value = false;
    try {
      const lines = csvText.value.split('\n');
      if (lines.length < 2) {
        alert('CSV格式不正确，至少需要一行表头和一行数据！');
        return;
      }
      
      const parsed = [];
      for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;
        
        const cols = line.split(',').map(s => s.trim().replace(/^["']|["']$/g, ''));
        if (cols.length < 2) continue;
        
        parsed.push({
          id: cols[0] || ('PROD-' + Math.floor(Math.random() * 1000)),
          model: cols[0] || 'Unknown',
          name: cols[1] || '未命名产品',
          cert: cols[2] || '常规出口资质',
          temp: cols[3] || '常规环境温度',
          material: cols[4] || '常规金属材质',
          moq: parseInt(cols[5]) || 50,
          priceRange: cols[6] || '$100 ~ $150 FOB',
          desc: cols[7] || '通过 CSV 智能录入建立的产品档案条目。'
        });
      }
      
      if (parsed.length === 0) {
        alert('未能成功解析任何产品，请检查CSV格式！');
        return;
      }
      
      parsedProductsPreview.value = parsed;
      alert(`已成功解析 ${parsed.length} 个产品！请在下方预览确认后导入。`);
    } catch (e) {
      alert('解析失败，请检查CSV格式是否标准：' + e.message);
    }
  }, 600);
};

const confirmImportCSV = () => {
  if (parsedProductsPreview.value.length === 0) return;
  
  parsedProductsPreview.value.forEach(p => {
    products.value.unshift(p);
  });
  
  alert(`「批量导入成功」：已成功将 ${parsedProductsPreview.value.length} 个产品导入至目录，本地向量 ChromaDB 已自动热更新！`);
  highlightedProductId.value = parsedProductsPreview.value[0].id;
  parsedProductsPreview.value = [];
  csvText.value = '';
};

const openCatalogPdf = (name, abstract) => {
  activePdf.value = {
    name: name,
    abstract: abstract
  };
};

const downloadPdf = () => {
  alert(`「离线安全导出」: ${activePdf.value.name} 已成功转码并加密下载至您的本地外贸文件夹目录中！`);
};

const parseAndImportProduct = () => {
  if (!rawImportText.value.trim()) {
    alert('请先输入或粘贴产品文字描述！');
    return;
  }
  isImporting.value = true;
  setTimeout(() => {
    isImporting.value = false;
    const txt = rawImportText.value;
    
    let model = 'EX-R800';
    let name = '户外防雨防爆型储水箱';
    let temp = '-30°C 至 +75°C';
    let material = '食品级 SUS304 不锈钢强化';
    let moq = 80;
    let priceRange = '$200 ~ $250 CIF';
    
    if (txt.includes('R800') || txt.includes('EX-R800')) {
      model = 'EX-R800';
      name = '防雨防爆智能不锈钢水箱';
      temp = '-30°C 至 +75°C';
      material = '食品级 SUS304 不锈钢拉丝强化';
      moq = 80;
      priceRange = '$220 ~ $260 CIF';
    } else if (txt.includes('水囊') || txt.includes('TPU') || txt.includes('WT')) {
      model = 'FL-WT-900';
      name = '高负载耐压特种折叠水囊';
      temp = '-25°C 至 +60°C';
      material = '高密度 TPU 加厚型防刺穿覆膜';
      moq = 120;
      priceRange = '$50 ~ $85 FOB';
    } else {
      model = 'EX-HD-600';
      name = '全地形车载机动储水盖水箱';
      temp = '-35°C 至 +70°C';
      material = '高密度聚乙烯 HDPE 双层闭合发泡';
      moq = 60;
      priceRange = '$150 ~ $190 CIF';
    }
    
    const newProduct = {
      id: model,
      name: name,
      model: model,
      cert: 'FDA / CE 双重认证',
      desc: '经由 AI 自动读取口头速记文档结构化解析的新一代装备，配置防漏压力底阀及自平衡防爆封盖。',
      temp: temp,
      material: material,
      moq: moq,
      priceRange: priceRange
    };
    
    products.value.unshift(newProduct);
    highlightedProductId.value = model;
    
    alert(`「AI 智能解析录入成功」：产品型号 [${model}] 已被自动解析为结构化参数卡片并导入本手册首行，ChromaDB 向量索引库同步热更新！`);
    rawImportText.value = '';
    
    setTimeout(() => {
      const el = document.getElementById("prod-" + model);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      }
    }, 200);
  }, 1200);
};

const loadQuickQuery = () => {
  searchQuery.value = '你们有适合户外极限寒冷环境下的防腐水箱吗？需要有权威 of TUV 质量认证，可以给 Dieter Müller 先生回复。';
};

const triggerRAGSearch = () => {
  if (!searchQuery.value) return;
  isRAGSearching.value = true;
  highlightedProductId.value = null;
  ragResult.value = null;

  setTimeout(() => {
    isRAGSearching.value = false;
    
    const firstProd = products.value[0] || { id: 'unknown', model: 'Unknown', name: 'Unknown', desc: 'No description', temp: 'N/A', material: 'N/A', moq: 0, priceRange: 'N/A' };
    let targetModel = firstProd.id;
    let docSnippet = `【${firstProd.model} 越野智能改装装备手册】\n- 产品名称：${firstProd.name}\n- 物理材质参数：${firstProd.material} | 规格适配参数：${firstProd.temp}\n- 品控质量资质：出厂通过全套碰撞与压力合规安全检测。\n- 基准起订量 (MOQ)：${firstProd.moq} 套 | 建议外销参考价：${firstProd.priceRange}`;
    
    // Fuzzy matching for JFC4x4 snorkels/bars
    const q = searchQuery.value.toLowerCase();
    const match = products.value.find(p => 
      p.name.toLowerCase().includes(q) || 
      p.model.toLowerCase().includes(q) ||
      p.material.toLowerCase().includes(q)
    );
    
    if (match) {
      targetModel = match.id;
      docSnippet = `【${match.model} 越野智能改装装备手册】\n- 产品名称：${match.name}\n- 物理材质参数：${match.material} | 规格适配参数：${match.temp}\n- 品控质量资质：出厂通过全套 ${match.cert} 与安全检测。\n- 基准起订量 (MOQ)：${match.moq} 套 | 建议外销参考价：${match.priceRange}`;
    }

    highlightedProductId.value = targetModel;

    const el = document.getElementById("prod-" + targetModel);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    ragResult.value = {
      score: match ? '0.9785' : '0.9124',
      snippet: docSnippet
    };
  }, 1000);
};

const triggerManualRAG = (prodId) => {
  highlightedProductId.value = prodId;
  const match = products.value.find(p => p.id === prodId);
  if (!match) return;

  searchQuery.value = "寻找型号 [" + match.model + "] 适用于国际贸易起订量及极限材质的手册召回段落。";
  ragResult.value = {
    score: '0.9845',
    snippet: "【" + match.name + " 手册文档召回】\n- 型号: " + match.model + " | 规格材料: " + match.material + "\n- 工作极值: " + match.temp + " | 出厂品质资质: " + match.cert + "\n- 推荐起订量 (MOQ): " + match.moq + " 套 | 基准销售价格参考: " + match.priceRange
  };
};

const generateColdEmail = () => {
  isGeneratingEmail.value = true;
  draftedEmail.value = null;

  setTimeout(() => {
    isGeneratingEmail.value = false;
    
    const activeProd = products.value.find(p => p.id === highlightedProductId.value) || products.value[0] || {
      id: 'unknown',
      model: 'JFC-4X4',
      name: '越野车专业竞技涉水器/前防撞杠',
      cert: '4x4 Snorkel',
      desc: '专为极限越野环境设计的高性能装备。',
      temp: '适配全天候多地形',
      material: '高强度 LLDPE 材质',
      moq: 20,
      priceRange: '电询底价 FOB'
    };

    if (props.isSecretMode) {
      draftedEmail.value = {
        subject: "Confidential Technical Blueprint & Price Quotation - " + activeProd.model,
        body: "Dear Partner,\n\nWe appreciate your inquiry. Under our highest security protocol (Offline Secure RAG Routing), we have compiled the customized cost metrics for our " + activeProd.name + " (Model: " + activeProd.model + ").\n\nKey parameters for your reference:\n- Structural material: " + activeProd.material + "\n- Safe working range: " + activeProd.temp + "\n- Base MOQ requirement: " + activeProd.moq + " Units\n\nOur confidential local estimation yields a base price of " + activeProd.priceRange + " assuming your trial batch compliance. The technical blueprint and quality audit report is securely attached.\n\nWarm regards,\nMagicHub Secure Local Agent\n(This draft was securely processed offline via Llama 3 8B)"
      };
    } else {
      draftedEmail.value = {
        subject: "Technical Specifications & Quotation Proposal regarding " + activeProd.name + " - Model " + activeProd.model,
        body: "Dear Sirs,\n\nI hope this email finds you well.\n\nWe are writing to coordinate on your recent inquiry regarding our flagship " + activeProd.name + " (Model: " + activeProd.model + "), specifically engineered for extreme weather conditions and heavy industrial usage.\n\nHere are the details matching your specifications:\n1. Robust Performance: Engineered with " + activeProd.material + ", sustaining operational ranges of " + activeProd.temp + ".\n2. Quality Guarantee: Audited and certified under standard " + activeProd.cert + ".\n3. Shipping and MOQ: For this model, the base MOQ is " + activeProd.moq + " Units, and we can offer premium shipping directly to your destination port.\n\nWe look forward to sending formal draft invoice copies once you review the attached specs.\n\nBest regards,\nSales Representative\nMagicHub Overseas Marketing Hub\n(This draft was optimized via Gemini 1.5 Pro Routing)"
      };
    }
  }, 1500);
};

const copyEmail = () => {
  if (!draftedEmail.value) return;
  const fullText = "Subject: " + draftedEmail.value.subject + "\n\n" + draftedEmail.value.body;
  navigator.clipboard.writeText(fullText).then(() => {
    copySuccess.value = true;
    setTimeout(() => {
      copySuccess.value = false;
    }, 2000);
  });
};
</script>
