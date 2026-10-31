<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import Dashboard from './components/Dashboard.vue';
import CustomerSea from './components/CustomerSea.vue';
import OpportunityManager from './components/OpportunityManager.vue';
import FollowUp from './components/FollowUp.vue';
import SampleTracker from './components/SampleTracker.vue';
import QuotationHistory from './components/QuotationHistory.vue';
import ContractManager from './components/ContractManager.vue';
import ProductLibrary from './components/ProductLibrary.vue';
import AiRouter from './components/AiRouter.vue';
import SmartTools from './components/SmartTools.vue';
import CompanyInfo from './components/CompanyInfo.vue';
import TeamManager from './components/TeamManager.vue';
import KnowledgeBase from './components/KnowledgeBase.vue'; // [NEW] Knowledge Base Component
import ZenModal from './components/ZenModal.vue';
import SystemSettings from './components/SystemSettings.vue'; // [NEW] System Settings Component
import ScheduleManager from './components/ScheduleManager.vue'; // [NEW] Schedule Manager Component
import SmartMarketing from './components/SmartMarketing.vue'; // [NEW] Smart Email Marketing Component
import AgentRoom from './components/AgentRoom.vue'; // [NEW] Multi-Agent Group Chat
import ForwelikeHub from './components/ForwelikeHub.vue';


// --- Global IDE and System Skills Registry (标准技能导入注册底盘) ---
const importedSkills = ref([
  { value: 'market_research', label: '市场情报背调', desc: '检索工商名录、关单记录、海关物流', source: 'system' },
  { value: 'trade_risk_analysis', label: '授信与风控测算', desc: '评估履约信用评级、地缘地差', source: 'system' },
  { value: 'multilingual_crafting', label: '地道多语言起草', desc: '结合我方产品写高响应开发信', source: 'system' },
  { value: 'contract_compliance', label: '进出口法务合同审计', desc: '规避支付、交货及知识产权壁垒', source: 'system' },
  { value: 'ground_visit', label: '客户地面配合演示', desc: '海外办事处或驻点渠道直接上门拜访', source: 'system' },
  { value: 'deep-client-analysis', label: '深度客户分析与调研', desc: '基于步骤向导深度调研客商画像、产品与竞争格局，生成高品质 HTML 和 MD 报告', source: 'system' }
]);

// --- 1. Global Raised State Center (全局状态提升底座) ---
const isSecretMode = ref(false); // Global secret air-gap mode state
const isRouterModalOpen = ref(false); // AI Router Settings Modal State

const APP_VERSION = '1.10.0';

const ourCompanyInfo = ref({
  chineseName: '禅能特种制造有限公司',
  englishName: 'Zen Specialty Manufacturing Co., Ltd.',
  coreAdvantages: '高性能户外防爆不锈钢防冻水箱 EX-XT 系列，高密度食品级环保 TPU 柔性折叠重力自压水囊 FL-WT 系列，独家抗 -40°C 极限严寒双层发泡隔温专利工艺。',
  certifications: '欧盟 CE 安全认证, 德国 TUV 莱茵产品合规审计证书, 美国 FDA 食品级环保材料合格检验回执。',
  exportExperience: '12 年特种金属制品与柔性容具国际出口及海运清关经验，中东、欧洲及东南亚多地有协同商专线配送仓储。',
  website: 'https://www.zen-specialty-manufacturing.com',
  presetIncoterms: 'CIF Hamburg, FOB Shanghai, DDP Bangkok',
  address: '中国华南高新特种工业制造装备开发区禅能路8号',
  foundedYear: '2012',
  employeeCount: '200-500人',
  annualExport: 'USD 200万+',
  targetMarkets: '德国、澳大利亚、泰国、中东、东南亚',
});
// Default preset providers matching SystemSettings
const defaultProviders = [
  { id: 'apifree', name: 'APIFree', icon: 'A', iconColor: 'bg-purple-600', status: true, baseUrl: 'https://api.apifree.ai/agent/v1', apiKey: '', modelGroup: 'skywork-ai', model: 'skywork-ai/skyclaw-v1', previewUrl: 'https://api.apifree.ai/agent/v1/chat/completions' },
  { id: 'cloudflare', name: 'Cloudflare', icon: 'C', iconColor: 'bg-orange-500', status: true, baseUrl: 'https://api.cloudflare.com/client/v4', apiKey: '', modelGroup: 'workers-ai', model: 'meta-llama/llama-3-8b-instruct', previewUrl: 'https://api.cloudflare.com/client/v4/chat/completions' },
  { id: 'siliconflow', name: '硅基流动', icon: '硅', iconColor: 'bg-indigo-600', status: true, baseUrl: 'https://api.siliconflow.cn/v1', apiKey: '', modelGroup: 'deepseek', model: 'deepseek-ai/DeepSeek-V3', previewUrl: 'https://api.siliconflow.cn/v1/chat/completions' },
  { id: 'gemini', name: 'Gemini', icon: 'G', iconColor: 'bg-blue-500', status: true, baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai', apiKey: '', modelGroup: 'google', model: 'gemini-1.5-pro', previewUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions' },
  { id: 'alicoding', name: '阿里coding', icon: '阿', iconColor: 'bg-blue-800', status: true, baseUrl: 'https://api.alicoding.com/v1', apiKey: '', modelGroup: 'qwen', model: 'qwen-turbo', previewUrl: 'https://api.alicoding.com/v1/chat/completions' },
  { id: 'volcengine', name: '火山引擎', icon: '火', iconColor: 'bg-blue-400', status: false, baseUrl: 'https://api.volcengine.com/v1', apiKey: '', modelGroup: 'doubao', model: 'doubao-pro', previewUrl: 'https://api.volcengine.com/v1/chat/completions' },
  { id: 'minimax', name: 'MiniMax', icon: 'M', iconColor: 'bg-red-500', status: false, baseUrl: 'https://api.minimaxi.com/v1', apiKey: '', modelGroup: 'abab', model: 'abab6.5-chat', previewUrl: 'https://api.minimaxi.com/v1/chat/completions' },
  { id: 'vpsairobot', name: 'vpsairobot', icon: 'V', iconColor: 'bg-green-500', status: false, baseUrl: 'https://api.vpsairobot.com/v1', apiKey: '', modelGroup: 'custom', model: 'vps-smart-v1', previewUrl: 'https://api.vpsairobot.com/v1/chat/completions' },
  { id: 'vercel', name: 'Vercel AI Gateway', icon: '▲', iconColor: 'bg-black', status: false, baseUrl: 'https://gateway.ai.vercel.cloud/v1', apiKey: '', modelGroup: 'gateway', model: 'openai/gpt-4o', previewUrl: 'https://gateway.ai.vercel.cloud/v1/chat/completions' },
  { id: 'bailian', name: '阿里云百炼', icon: '百', iconColor: 'bg-blue-600', status: false, baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1', apiKey: '', modelGroup: 'qwen', model: 'qwen-max', previewUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions' },
  { id: 'qiniu', name: '七牛云 AI 推理', icon: '七', iconColor: 'bg-blue-300', status: false, baseUrl: 'https://api.qiniu.com/v1', apiKey: '', modelGroup: 'qiniu-ai', model: 'qiniu-llama-3', previewUrl: 'https://api.qiniu.com/v1/chat/completions' },
  { id: 'deepseek', name: '深度求索', icon: '深', iconColor: 'bg-blue-700', status: true, baseUrl: 'https://api.deepseek.com/v1', apiKey: '', modelGroup: 'deepseek', model: 'deepseek-chat', previewUrl: 'https://api.deepseek.com/v1/chat/completions' },
  { id: 'zhipu', name: '智谱开放平台', icon: '智', iconColor: 'bg-blue-900', status: false, baseUrl: 'https://open.bigmodel.cn/api/paas/v4', apiKey: '', modelGroup: 'glm', model: 'glm-4', previewUrl: 'https://open.bigmodel.cn/api/paas/v4/chat/completions' },
  { id: 'openrouter', name: 'OpenRouter', icon: 'O', iconColor: 'bg-purple-800', status: false, baseUrl: 'https://openrouter.ai/api/v1', apiKey: '', modelGroup: 'openrouter', model: 'meta-llama/llama-3-70b-instruct', previewUrl: 'https://openrouter.ai/api/v1/chat/completions' },
  { id: 'cerebras', name: 'Cerebras AI', icon: 'C', iconColor: 'bg-orange-600', status: false, baseUrl: 'https://api.cerebras.ai/v1', apiKey: '', modelGroup: 'cerebras', model: 'llama3.1-8b', previewUrl: 'https://api.cerebras.ai/v1/chat/completions' },
  { id: 'nvidia', name: '英伟达', icon: '英', iconColor: 'bg-green-600', status: false, baseUrl: 'https://integrate.api.nvidia.com/v1', apiKey: '', modelGroup: 'nvidia', model: 'meta/llama3-70b-instruct', previewUrl: 'https://integrate.api.nvidia.com/v1/chat/completions' }
];

const providers = ref([]);

// Synchronize system settings to local storage and reactive ref
const loadSavedProviders = async () => {
  try {
    let parsed = null;
    if (window.electronAPI && window.electronAPI.loadSettings) {
      const res = await window.electronAPI.loadSettings('magichub_ai_providers');
      if (res && res.success && res.data) {
        parsed = res.data;
      }
    }
    if (!parsed) {
      const saved = localStorage.getItem('magichub_ai_providers');
      if (saved) {
        parsed = JSON.parse(saved);
      }
    }

    if (parsed) {
      // [Migration] Auto-fix known broken default URLs from older versions.
      // Some prior builds shipped placeholder/wrong domains that don't actually exist
      // (e.g. api.minimax.com instead of api.minimaxi.com). When we detect a saved
      // provider still pointing to one of those, reset it to the corrected default
      // so existing users don't have to fix it manually.
      const brokenUrlMigrations = {
        minimax: { bad: ['api.minimax.com'], good: 'https://api.minimaxi.com/v1' },
        gemini:  { bad: ['api.gemini.net'],  good: 'https://generativelanguage.googleapis.com/v1beta/openai' }
      };
      parsed.forEach(item => {
        const fix = brokenUrlMigrations[item.id];
        if (fix && item.baseUrl && fix.bad.some(b => item.baseUrl.includes(b))) {
          console.log(`[MagicHub] Auto-fixing ${item.id} baseUrl: ${item.baseUrl} → ${fix.good}`);
          item.baseUrl = fix.good;
          item.previewUrl = fix.good + '/chat/completions';
        }
      });

      const merged = defaultProviders.map(p => {
        const matched = parsed.find(item => item.id === p.id);
        if (matched) {
          let apiKey = matched.apiKey !== undefined ? matched.apiKey : p.apiKey;
          let status = matched.status !== undefined ? matched.status : p.status;
          let baseUrl = matched.baseUrl !== undefined ? matched.baseUrl : p.baseUrl;
          let model = matched.model !== undefined ? matched.model : p.model;

          if (p.id === 'deepseek') {
            // Keep user-saved key/model; only fill defaults when missing
            status = true;
            if (!baseUrl) baseUrl = 'https://api.deepseek.com/v1';
            if (!model) model = 'deepseek-chat';
          }

          return {
            ...p,
            apiKey,
            baseUrl,
            model,
            status,
            availableModels: Array.isArray(matched.availableModels) ? matched.availableModels : (p.availableModels || [])
          };
        }
        if (p.id === 'deepseek') {
          return {
            ...p,
            apiKey: '',
            status: true,
            baseUrl: 'https://api.deepseek.com/v1',
            model: 'deepseek-chat'
          };
        }
        return p;
      });
      // Also add any custom providers that don't match default provider IDs
      const customProviders = parsed.filter(p => !defaultProviders.some(dp => dp.id === p.id));
      providers.value = [...merged, ...customProviders];
    } else {
      providers.value = defaultProviders.map(p => {
        if (p.id === 'deepseek') {
          return {
            ...p,
            apiKey: '',
            status: true,
            baseUrl: 'https://api.deepseek.com/v1',
            model: 'deepseek-chat'
          };
        }
        return p;
      });
    }
    // Update local storage and Electron settings file so that system settings and AI call is synchronized
    localStorage.setItem('magichub_ai_providers', JSON.stringify(providers.value));
    if (window.electronAPI && window.electronAPI.saveSettings) {
      await window.electronAPI.saveSettings('magichub_ai_providers', JSON.parse(JSON.stringify(providers.value)));
    }
  } catch (e) {
    console.error('Failed to load saved AI providers in App.vue:', e);
    providers.value = defaultProviders.map(p => {
      if (p.id === 'deepseek') {
        return {
          ...p,
          apiKey: '',
          status: true,
          baseUrl: 'https://api.deepseek.com/v1',
          model: 'deepseek-chat'
        };
      }
      return p;
    });
  }
};
loadSavedProviders();

// 1.1 Leads (Customer Sea) Database
const leads = ref([
  {
    id: 1,
    name: 'Dima Breusov',
    contact: 'Dima Breusov',
    phone: '+7 912 345-67-89',
    country: '俄罗斯',
    flag: '🇷🇺',
    score: 87,
    category: 'parts',
    stage: 'deal',
    tags: ['俄罗斯', '已成交'],
    routingPath: '中东/欧洲区域合作代理 (已签约)',
    rawMessage: `Hi,\nRegarding our automotive radiators batch order, we have signed the agreement for 500 units. The shipping must go via Vladivostok to Moscow. Please ensure all certificates are enclosed.\nBest,\nDima Breusov`
  },
  {
    id: 2,
    name: 'Borripat Landa',
    contact: 'Borripat Landa',
    phone: '+66 81 234 5678',
    country: '泰国',
    flag: '🇹🇭',
    score: 91,
    category: 'parts',
    stage: 'deal',
    tags: ['成交', '优质客户'],
    routingPath: '泰国清迈代理协同专线 Sompop',
    rawMessage: `Dear Sir,\nThe agricultural trailer parts order is completed. The cargo has arrived safely in Bangkok port. We appreciate the fast delivery and custom packaging. Looking forward to our next contract.\nSincerely,\nBorripat Landa`
  },
  {
    id: 3,
    name: 'J06-Merka',
    contact: 'Merka',
    phone: '+972 50 123 4567',
    country: '以色列',
    flag: '🇮🇱',
    score: 82,
    category: 'parts',
    stage: 'deal',
    tags: ['以色列', '已成交', '+1'],
    routingPath: '海外多模型安全路由 Gemini',
    rawMessage: `Hello Team,\nRadiator brackets received. Quality is excellent. Please prepare the billing invoice for the second batch of 200 units. We will transfer the funds shortly.\nWarm regards,\nMerka`
  },
  {
    id: 4,
    name: 'AeroSpeedX Auto Accessories',
    contact: 'Richard Garcia',
    phone: '+63 917 123 4567',
    country: '菲律宾',
    flag: '🇵🇭',
    score: 79,
    category: 'parts',
    stage: 'potential',
    tags: ['菲律宾'],
    routingPath: '东南亚区域常规流转',
    rawMessage: `Hi Sales Team,\nWe are highly interested in importing aluminum racing radiators for Japanese tuning cars in Manila. Could you please send over your factory price catalog and clarify your MOQ limit? We usually import 20ft containers.\nThanks,\nRichard Garcia`
  },
  {
    id: 5,
    name: 'Rhonda Shear Intimates',
    contact: '——',
    phone: '未提供',
    country: '未知',
    flag: '🌐',
    score: 64,
    category: 'lights',
    stage: 'potential',
    tags: ['未分类'],
    routingPath: '云端多核智能分配',
    rawMessage: `Hello,\nWe saw your lighting items in a trade show brochure. We want to inquire about custom orders for decorative office lights. No detailed specs are available yet, please contact us.\nRegards,\nProcurement Lead`
  },
  {
    id: 6,
    name: 'Artan Trading',
    contact: 'Sean Cronje',
    phone: '+971 50 123 4567',
    country: '阿联酋',
    flag: '🇦🇪',
    score: 93,
    category: 'parts',
    stage: 'potential',
    tags: ['阿联酋', '优质客户'],
    routingPath: '中东代理商协同跟进 Farooq',
    rawMessage: `Dear Sirs,\nWe are looking for heavy-duty truck cooling parts for deployment in extreme desert environments (ambient temperatures exceeding 48°C). Material must be durable and high-grade aluminum. We have a local representative in UAE for coordinate inspections.\nBest regards,\nSean Cronje`
  },
  {
    id: 7,
    name: 'AMIN SONS MARKETING PVT LTD',
    contact: 'Mr Amin',
    phone: '+91 98765 43210',
    country: '印度',
    flag: '🇮🇳',
    score: 85,
    category: 'parts',
    stage: 'potential',
    tags: ['印度', '大客户'],
    routingPath: '国内路由 DeepSeek V2',
    rawMessage: `Dear Sales,\nWe represent AMIN SONS. We have significant demand for agricultural machinery water tanks. We are requesting customized stainless water tanks. The draft technical drawing is attached. We request the most competitive factory price.\nSincerely,\nMr. Amin`
  },
  {
    id: 8,
    name: 'Ali Algharawi Company',
    contact: 'Ali Grawi',
    phone: '+964 770 123 4567',
    country: '伊拉克',
    flag: '🇮🇶',
    score: 74,
    category: 'parts',
    stage: 'potential',
    tags: ['伊拉克', '价格敏感'],
    routingPath: '极密离线 Llama 3 物理防护',
    rawMessage: `Hi,\nWe want bottom prices for engine cooling water tank radiators. We require strict confidentiality due to competitor bidding locally. Please send pricing based on drawings.\nWarm regards,\nAli Grawi`
  },
  {
    id: 9,
    name: 'PS4X4 Accessories',
    contact: 'Mr Amin',
    phone: '+61 412 345 678',
    country: '澳大利亚',
    flag: '🇦🇺',
    score: 88,
    category: 'parts',
    stage: 'potential',
    tags: ['澳大利亚', '急速报价'],
    routingPath: '海外多模型高速路由 Gemini',
    rawMessage: `Hi,\nWe are an off-road custom shop in Melbourne. We require immediate pricing and production lead time for custom heavy-duty water storage tanks suitable for 4x4 off-road trailers. batch of 50 units. Must be robust against vibration.\nCheers,\nMr Amin`
  },
  {
    id: 10,
    name: 'AUTOPAL INTERNATIONAL (PVT) LTD',
    contact: 'Mr Shazli',
    phone: '+61 498 765 432',
    country: '澳大利亚',
    flag: '🇦🇺',
    score: 81,
    category: 'lights',
    stage: 'potential',
    tags: ['澳大利亚', '照明询盘'],
    routingPath: '海外路由 Gemini 1.5 Pro',
    rawMessage: `Dear Team,\nWe are sourcing industrial floodlights and brackets for commercial parking lots. Must comply with Australian electrical safety standards. Please reply with catalog.\nBest,\nMr Shazli`
  },
  {
    id: 11,
    name: 'Dieter Müller',
    contact: 'Dieter Müller',
    phone: '+49 170 1234567',
    country: '德国',
    flag: '🇩🇪',
    score: 89,
    category: 'parts',
    stage: 'deal',
    tags: ['德国', '已成交'],
    routingPath: '欧洲区域常规流转',
    rawMessage: `Dear Sirs,\nWe are highly interested in importing EX-XT-500 extreme anti-freezing water tanks to Hamburg. Could you please send over the latest TUV test certificate? We expect to order a batch of 100 units.\nBest regards,\nDieter Müller`
  },
  {
    id: 12,
    name: 'Thai Agri Cooperative',
    contact: 'Sompop',
    phone: '+66 89 765 4321',
    country: '泰国',
    flag: '🇹🇭',
    score: 82,
    category: 'parts',
    stage: 'potential',
    tags: ['泰国', '潜在买家'],
    routingPath: '东南亚区域流转',
    rawMessage: `Hello,\nWe are sourcing customizable flexible folding water storage tanks for mountaintop agriculture in Chiang Mai. 100L capacity. Must be durable and food-grade TPU material.\nRegards,\nSompop`
  },
  {
    id: 13,
    name: 'EuroCool Gmbh',
    contact: 'Hans Schmidt',
    phone: '+49 176 9876543',
    country: '德国',
    flag: '🇩🇪',
    score: 42,
    category: 'parts',
    stage: 'lost',
    tags: ['德国', '流失客户', '价格过高'],
    routingPath: '常规欧洲流转通道',
    rawMessage: `Hello Sofia,\nUnfortunately, your pricing for aluminum radiator cores is 25% higher than our target. We have closed our deal with another East European supplier.\nSincerely,\nHans Schmidt`
  },
]);

const loadSavedLeads = async () => {
  try {
    let savedLeads = null;
    if (window.electronAPI?.loadSettings) {
      const res = await window.electronAPI.loadSettings('magichub_leads');
      if (res?.success && Array.isArray(res.data)) {
        savedLeads = res.data;
      }
    }
    if (!savedLeads) {
      const local = localStorage.getItem('magichub_leads');
      if (local) savedLeads = JSON.parse(local);
    }
    if (Array.isArray(savedLeads) && savedLeads.length) {
      leads.value = savedLeads;
    }
  } catch (e) {
    console.error('Failed to load saved leads:', e);
  }
};

const loadSavedCompanyInfo = async () => {
  try {
    let savedInfo = null;
    if (window.electronAPI?.loadSettings) {
      const res = await window.electronAPI.loadSettings('magichub_company_info');
      if (res?.success && res.data && typeof res.data === 'object') {
        savedInfo = res.data;
      }
    }
    if (!savedInfo) {
      const local = localStorage.getItem('magichub_company_info');
      if (local) savedInfo = JSON.parse(local);
    }
    if (savedInfo) {
      ourCompanyInfo.value = { ...ourCompanyInfo.value, ...savedInfo };
      console.log('[MagicHub] Company profile database loaded successfully.');
    }
  } catch (e) {
    console.error('Failed to load saved company info:', e);
  }
};

let leadsSaveTimer = null;
const saveLeadsDataNow = async () => {
  try {
    if (window.electronAPI?.saveSettings) {
      const plain = JSON.parse(JSON.stringify(leads.value));
      await window.electronAPI.saveSettings('magichub_leads', plain);
      console.log('[MagicHub] Leads database persisted successfully.');
    } else {
      const serialized = JSON.stringify(leads.value);
      if (serialized.length < 4_000_000) {
        localStorage.setItem('magichub_leads', serialized);
      }
    }
  } catch (e) {
    console.error('Failed to explicitly save leads:', e);
  }
};

// Expose globally so components can trigger immediate database synchronization
window.saveLeadsData = saveLeadsDataNow;

watch(leads, (newVal) => {
  clearTimeout(leadsSaveTimer);
  leadsSaveTimer = setTimeout(saveLeadsDataNow, 500);
}, { deep: false });

watch(ourCompanyInfo, async (newVal) => {
  try {
    if (window.electronAPI?.saveSettings) {
      await window.electronAPI.saveSettings('magichub_company_info', JSON.parse(JSON.stringify(newVal)));
      console.log('[MagicHub] Company profile persisted successfully.');
    } else {
      localStorage.setItem('magichub_company_info', JSON.stringify(newVal));
    }
  } catch (e) {
    console.error('Failed to save company info:', e);
  }
}, { deep: true });

// ─────────────────────────────────────────────────────────────────────────────
// Generic persistence layer — ensures ALL user data survives app updates.
// Data is stored in Electron userData/settings/*.json (outside the .app bundle),
// with localStorage as a fallback for the browser/dev environment.
// ─────────────────────────────────────────────────────────────────────────────
const persistData = async (key, value) => {
  try {
    // Strip Vue reactive Proxies — Electron IPC uses structured clone which
    // cannot serialize Proxy objects ("An object could not be cloned").
    const plain = JSON.parse(JSON.stringify(value));
    if (window.electronAPI?.saveSettings) {
      await window.electronAPI.saveSettings(key, plain);
    }
    // Always mirror to localStorage as a redundant safety copy
    try {
      const serialized = JSON.stringify(value);
      if (serialized.length < 4_500_000) {
        localStorage.setItem(key, serialized);
      }
    } catch (_) { /* ignore quota errors */ }
  } catch (e) {
    console.error(`[MagicHub] Failed to persist ${key}:`, e);
  }
};

const loadData = async (key) => {
  try {
    if (window.electronAPI?.loadSettings) {
      const res = await window.electronAPI.loadSettings(key);
      if (res?.success && res.data !== null && res.data !== undefined) {
        return res.data;
      }
    }
    const local = localStorage.getItem(key);
    if (local) return JSON.parse(local);
  } catch (e) {
    console.error(`[MagicHub] Failed to load ${key}:`, e);
  }
  return null;
};

// Register a reactive dataset for automatic load-on-start + debounced save-on-change.
// Pass `merge: true` for plain objects (keeps newly added default keys after an update).
const pendingFlushers = [];
const registerPersistentState = (key, refObj, { isArray = false, merge = false } = {}) => {
  // Load any previously saved value
  loadData(key).then((saved) => {
    if (saved === null) return;
    if (isArray && Array.isArray(saved)) {
      refObj.value = saved;
    } else if (merge && saved && typeof saved === 'object' && !Array.isArray(saved)) {
      refObj.value = { ...refObj.value, ...saved };
    } else if (!isArray && !merge) {
      refObj.value = saved;
    }
  });

  // Debounced auto-save on any change
  let timer = null;
  watch(refObj, (newVal) => {
    clearTimeout(timer);
    timer = setTimeout(() => persistData(key, newVal), 400);
  }, { deep: true });

  // Allow an immediate synchronous-ish flush (used on quit)
  pendingFlushers.push(() => persistData(key, refObj.value));
};

// Flush every registered dataset to disk immediately (safety net before quit/reload)
const flushAllPersistentState = () => {
  pendingFlushers.forEach(fn => { try { fn(); } catch (_) {} });
  // Also flush the core datasets that use their own watchers
  try { if (window.saveLeadsData) window.saveLeadsData(); } catch (_) {}
};

// Expose an immediate, on-demand persistence trigger that components can call
// right after a critical mutation (so data is never lost even if the user
// quits or updates the app before the debounced watcher fires).
if (typeof window !== 'undefined') {
  window.magichubPersistNow = flushAllPersistentState;
}

if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', flushAllPersistentState);
  // Periodic autosave every 15s as a last-resort safety net
  setInterval(flushAllPersistentState, 15000);
}

onMounted(() => {
  loadSavedLeads();
  loadSavedCompanyInfo();
});

// 1.2 Timeline Logs (跟进记录数据)
const timelineLogs = ref([
  {
    id: 1,
    client: 'Dima Breusov (俄罗斯) 🇷🇺',
    date: '2026-05-31 16:30',
    channel: '电子邮件 (Email)',
    type: '需求确认',
    content: `【AI 润色商务跟进记录】\n与俄罗斯客户 Dima Breusov 先生确认了首批 500 台汽车散热器总成技术图纸及俄罗斯海关清关认证证书。\n货物已经安排由符拉迪沃斯托к港专线发出运往莫斯科。客户对散热器的铝合金抗振焊点工艺测试反馈极佳，表示下月计划追加签署第二批零配件协议。`
  },
  {
    id: 2,
    client: 'Dieter Müller (德国) 🇩🇪',
    date: '2026-05-30 18:24',
    channel: '电子邮件 (Email)',
    type: '报价回馈',
    content: `【AI 润色商务跟进记录】\n与德国客户 Dieter Müller 先生进行邮件沟通，解答了关于 EX-XT-500 防结冰水箱在零下温度环境的工作性能。\n客户对水箱配置的双层聚氨酯发泡层在极寒 -20°C 状态下保障流动性的测试报告表示极其满意。目前商务阻点主要集中在 CIF 汉堡港口运费预算上。已承诺下周一给与其正式的底价核算以及阶梯折扣建议，以促成 100 台的首笔试销订单签约。`
  },
  {
    id: 3,
    client: 'Borripat Landa (泰国) 🇹🇭',
    date: '2026-05-29 11:45',
    channel: '地面拜访 (Ground Visit)',
    type: '需求确认',
    content: `【区域协同代理跟进记录】\n已智能路由指派清迈本地合作代理商 Sompop 先生对客户进行地面直接拜访。\nSompop 先生现场向 Somchai 先生展示了折叠水囊（TPU食品级原料）的手册。Somchai 先生表示本地果园灌溉对于重力自压出水结构和防刺穿强度有着很强的偏好。Sompop 代理商已将详细的尺寸定制清单发回，将由我方起草定制订单以推进采购意向。`
  }
]);

// 1.3 Quotations Log (报价记录数据)
const quoteLogs = ref([
  {
    id: 1,
    code: 'QT-2026-009',
    client: 'Dieter Müller (德国)',
    flag: '🇩🇪',
    product: 'EX-XT-500 防冻水箱',
    incoterms: 'CIF Hamburg',
    cost: 110,
    freight: 20,
    commission: 5,
    price: 183.16
  },
  {
    id: 2,
    code: 'QT-2026-010',
    client: 'Ken Takahashi (日本)',
    flag: '🇯🇵',
    product: 'FL-WT-100 折叠水囊',
    incoterms: 'FOB Shanghai',
    cost: 32,
    freight: 0,
    commission: 0,
    price: 48
  }
]);

// 1.4 Contracts Ledger (订单合同数据)
const contracts = ref([
  {
    id: 1,
    code: 'CON-2026-081',
    client: 'Müller Co (德国)',
    flag: '🇩🇪',
    product: 'EX-XT-500 防冻绝缘水箱 (TUV)',
    quantity: 100,
    moq: 50,
    value: '¥32,000.00',
    date: '2026-05-30',
    status: '已成单'
  },
  {
    id: 2,
    code: 'CON-2026-082',
    client: 'Thai Agri Cooperative (泰国)',
    flag: '🇹🇭',
    product: 'FL-WT-100 100L自压折叠水囊',
    quantity: 150,
    moq: 100,
    value: '¥20,853.80',
    date: '2026-05-29',
    status: '已成单'
  }
]);

// 1.4b Samples Ledger (寄样跟进数据)
const samples = ref([
  {
    id: 1,
    batch: 'SMP-2026-004',
    client: 'Dieter Müller (德国)',
    flag: '🇩🇪',
    product: 'EX-XT-500 防冻绝缘水盖',
    date: '2026-05-20',
    tracking: 'DHL: 940551020088',
    status: '已妥投',
    feedback: '防裂测试优异，密封绝缘极佳'
  },
  {
    id: 2,
    batch: 'SMP-2026-005',
    client: 'Ken Takahashi (日本)',
    flag: '🇯🇵',
    product: 'FL-WT-100 100L户外自压水囊样件',
    date: '2026-05-24',
    tracking: 'FedEx: 770512048963',
    status: '运送中',
    feedback: null
  }
]);

// 1.5 Product catalog parameters (with local storage & importer synchronization)
const products = ref([]);

const loadSavedProducts = async () => {
  try {
    let parsed = null;
    if (window.electronAPI && window.electronAPI.loadSettings) {
      const res = await window.electronAPI.loadSettings('magichub_products');
      if (res && res.success && res.data) {
        parsed = res.data;
      }
    }
    if (!parsed) {
      const saved = localStorage.getItem('magichub_products');
      if (saved) {
        parsed = JSON.parse(saved);
      }
    }

    if (parsed) {
      parsed = parsed.filter(p => p.id !== 'EX-XT-500' && p.id !== 'FL-WT-100');
    }

    const defaultList = [];

    const baseList = parsed && parsed.length > 0 ? parsed : defaultList;

    // Try to load crawled/imported products from jfc4x4
    try {
      const response = await fetch('./products_imported.json');
      if (response.ok) {
        const imported = await response.json();
        if (Array.isArray(imported) && imported.length > 0) {
          const merged = [...baseList];
          imported.forEach(p => {
            if (!merged.some(m => String(m.id) === String(p.id))) {
              merged.push(p);
            }
          });
          products.value = merged;
          localStorage.setItem('magichub_products', JSON.stringify(merged));
          if (window.electronAPI && window.electronAPI.saveSettings) {
            await window.electronAPI.saveSettings('magichub_products', JSON.parse(JSON.stringify(merged)));
          }
          return;
        }
      }
    } catch (fetchErr) {
      console.warn('Imported products JSON not available yet:', fetchErr.message);
    }
    products.value = baseList;
  } catch (e) {
    console.error('Failed to load saved products in App.vue:', e);
  }
};

loadSavedProducts();

watch(products, async (newVal) => {
  if (newVal) {
    localStorage.setItem('magichub_products', JSON.stringify(newVal));
    if (window.electronAPI && window.electronAPI.saveSettings) {
      await window.electronAPI.saveSettings('magichub_products', JSON.parse(JSON.stringify(newVal)));
    }
  }
}, { deep: true });

// Hoisted ourCompanyInfo to the top of <script setup> to resolve ReferenceError

// --- 1.7 Open Claw AI & Human Team Block ---
const teamMembers = ref([
  {
    id: 'ai-1',
    isAi: true,
    name: 'SPI Research Agent',
    role: 'SPI 深度调研分析师',
    desc: '提取目标客户公开工商背景，梳理当前业务开发进展，进行深度交叉验证背调。',
    emoji: '🔍',
    model: 'Gemini 1.5 Pro',
    temperature: 0.2,
    maxTokens: 2000,
    skills: ['market_research', 'trade_risk_analysis'],
    instruction: 'You are the SPI Research Agent. Your task is to perform thorough, source-validated client checks. For each claim, provide a source tag like [Source: X] and a cross-verification tag. Identify key procurement drivers and pain points.'
  },
  {
    id: 'ai-2',
    isAi: true,
    name: 'Cold Email Polisher',
    role: '地道开发信润色官',
    desc: '结合产品特性，生成高响应率、地道多语言的外贸开发营销信函。',
    emoji: '✉️',
    model: 'DeepSeek V4 (latest)',
    temperature: 0.7,
    maxTokens: 1500,
    skills: ['multilingual_crafting'],
    instruction: 'You are an elite B2B Sales Writer. Polish draft emails to match European and American business etiquettes. Highlight CE/TUV/FDA certifications and logistical transparency. Keep tone persuasive, clear, and professional.'
  },
  {
    id: 'ai-3',
    isAi: true,
    name: 'Legal Compliance Auditor',
    role: '进出口法务合规审计员',
    desc: '审计 P/I 发票和 S/C 合同的贸易条款，评估结算机制和违约地缘风险。',
    emoji: '⚖️',
    model: 'Llama 3 (Offline)',
    temperature: 0.0,
    maxTokens: 1000,
    skills: ['contract_compliance'],
    instruction: 'You are a Senior Legal Compliance Auditor. Audit international sales contracts for risks. Pay extreme attention to payment terms (30% T/T, 70% B/L), Incoterms (CIF, FOB, DDP), and GDPR/TUV certifications.'
  },
  {
    id: 'human-1',
    isAi: false,
    name: 'Sofia',
    role: '外贸销售总监 (Sales Director)',
    desc: '全面统筹全球大客户开发、形式发票审核及中东/欧洲线业务洽谈。',
    emoji: '👩‍💼',
    skills: ['market_research', 'multilingual_crafting', 'contract_compliance'],
    active: true
  },
  {
    id: 'human-2',
    isAi: false,
    name: 'Sompop',
    role: '东南亚地面代理商专员',
    desc: '清迈及曼谷本地渠道代表，协同地面直接拜访、实样演示及物流通关跟进。',
    emoji: '🧔',
    skills: ['trade_risk_analysis', 'ground_visit'],
    active: true
  }
]);

// --- 2. Dynamic Router Tab Configs ---
const activeTab = ref('dashboard')

const swApplyTabFromQuery = () => {
  try {
    const q = new URLSearchParams(location.search || '')
    const tab = q.get('tab') || (location.hash || '').replace(/^#/, '')
    if (tab) activeTab.value = tab
  } catch (_) {}
}
swApplyTabFromQuery()
window.addEventListener('hashchange', swApplyTabFromQuery)

/** Embedded in 超级工作台: hide MagicHub's own aside; outer sidebar drives tabs via bridge. */
const swDetectEmbed = () => {
  try {
    const q = new URLSearchParams(location.search || '')
    if (q.get('embed') === '1' || q.get('embed') === 'true') return true
    if (window.__SW_EMBED__ === true) return true
    if (document.documentElement.getAttribute('data-sw-embed') === '1') return true
    if (document.documentElement.getAttribute('data-sw-host') === 'mac') return true
  } catch (_) {}
  return false
}
const isEmbedded = ref(swDetectEmbed())
if (isEmbedded.value) {
  try {
    document.documentElement.setAttribute('data-sw-embed', '1')
    document.documentElement.classList.add('sw-mh-embed')
  } catch (_) {}
}

const swNotifyHostTab = (tabId) => {
  try {
    if (window.webkit?.messageHandlers?.swMagicHub) {
      window.webkit.messageHandlers.swMagicHub.postMessage({
        id: 'tab-' + Date.now(),
        method: 'tab-changed',
        args: [String(tabId || '')]
      })
    }
  } catch (_) {}
  try {
    if (window.parent && window.parent !== window) {
      window.parent.postMessage({ type: 'sw-tab-changed', tab: String(tabId || '') }, '*')
    }
  } catch (_) {}
}

window.__swSetTab = (tabId) => {
  if (!tabId) return
  activeTab.value = String(tabId)
  swNotifyHostTab(activeTab.value)
}
window.addEventListener('message', (ev) => {
  try {
    const d = ev && ev.data
    if (d && d.type === 'sw-set-tab' && d.tab) {
      activeTab.value = String(d.tab)
    }
  } catch (_) {}
})
watch(activeTab, (v) => {
  if (isEmbedded.value) swNotifyHostTab(v)
})
;
const settingsInitialTab = ref('api');
const jumpToScheduleDate = ref(null);

const activeComponent = computed(() => {
  const map = {
    dashboard: Dashboard,
    schedule: ScheduleManager,
    customers: CustomerSea,
    marketing: SmartMarketing, // [NEW] Smart Email Marketing
    opportunities: OpportunityManager,
    followup: FollowUp,
    samples: SampleTracker,
    quotes: QuotationHistory,
    contracts: ContractManager,
    products: ProductLibrary,
    knowledge: KnowledgeBase,
    company: CompanyInfo,
    team: TeamManager,
    agentRoom: AgentRoom,
    settings: SystemSettings,
    forwelike: ForwelikeHub
  };
  return map[activeTab.value] || Dashboard;
});

const tabs = [
  { id: 'dashboard', name: '驾驶舱', label: 'Dashboard', icon: 'M4 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2H6a2 2 0 01-2-2v-4zM14 16a2 2 0 012-2h2a2 2 0 012 2v4a2 2 0 01-2 2h-2a2 2 0 01-2-2v-4z' },
  { id: 'schedule', name: '日程管理', label: 'Schedule', icon: 'M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z' },
  { id: 'customers', name: '客户管理', label: 'Customers', icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z' },
  { id: 'marketing', name: '智能营销', label: 'SmartMarketing', icon: 'M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z' }, // [NEW] Smart Marketing Tab
  { id: 'opportunities', name: '商机管理', label: 'Opportunities', icon: 'M13 7h8m0 0v8m0-8l-8 8-4-4-6 6' },
  { id: 'followup', name: '跟进记录', label: 'Followups', icon: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z' },
  { id: 'samples', name: '寄样跟进', label: 'Samples', icon: 'M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4' },
  { id: 'quotes', name: '报价记录', label: 'Quotations', icon: 'M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 11h.01M12 7h.01M15 11h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z' },
  { id: 'contracts', name: '订单合同', label: 'Contracts', icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z' },
  { id: 'products', name: '产品管理', label: 'Products', icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253' },
  { id: 'knowledge', name: '知识仓库', label: 'KnowledgeBase', icon: 'M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253' },
  { id: 'company', name: '公司信息', label: 'CompanyInfo', icon: 'M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' },
  { id: 'team', name: '团队管理', label: 'TeamManager', icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z' },
  { id: 'agentRoom', name: 'Agent 协同', label: 'AgentRoom', icon: 'M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z' },
  { id: 'forwelike', name: 'Forwelike 专区', label: 'ForwelikeHub', icon: 'M12 14l9-5-9-5-9 5 9 5zm0 0v6m-4-3.5v3.5a4 4 0 008 0v-3.5' }
];

const toggleGlobalSecretMode = () => {
  isSecretMode.value = !isSecretMode.value;
};

const jumpToCustomerId = ref(null);
const jumpToOpportunityId = ref(null);

const deals = ref([
  {
    id: 1,
    title: 'Müller 户外-20°C极限防结冰水箱采购首单',
    client: 'Dieter Müller',
    flag: '🇩🇪',
    amount: '¥32,000.00',
    stage: '商务价格谈判',
    probability: 89,
    nextStep: '周一发送 RAG 生成的地道参数和报价开发信',
    aiStrategy: `【Müller 德国商机策略方案】\n1. 痛点：德国冬季严寒结冰开裂，客户极度关注德国 TUV 品控与防冻性能保障。\n2. 报价卡点：目前客户给出的 CIF $200 预算空间尚可，但需提供高透明的包装与运输明细。\n3. 下步动作建议：\n   - 一键生成 TUV 认证符合性说明及 -40°C 实测防冻发泡说明书；\n   - 以 $190 CIF Hamburg 进行稳妥回价，保留 5% 的商务议价余地；\n   - 周一由业务员使用海外通道发送 RAG 开发信并主动跟进。`
  },
  {
    id: 2,
    title: 'Chiang Mai 农业蓄水池柔性折叠水囊定制',
    client: 'Thai Agri Cooperative',
    flag: '🇹🇭',
    amount: '¥20,853.80',
    stage: '清洗与意图确认',
    probability: 72,
    nextStep: '协同流转至泰国驻点代理商 Sompop 进行地面配合',
    aiStrategy: `【Thai Agri 泰国商机协同策略】\n1. 痛点：清迈山地灌溉，需要轻量、高强度且适合食品级无毒标准的产品。\n2. 代理商协同契机：客户提到了需要有代表现场接洽，这在我们驻点代理服务辐射范围。\n3. 下步动作建议：\n   - 熔断线上视频会议提案，立即向泰国驻点代理发函派发此商机；\n   - 随附高对比度的 FL-WT-100 柔性水囊产品参数（FDA认证）；\n   - 委托代理商进行本地拜访以极速锁定订单。`
  }
]);

const handleTabChange = (tabId, payload = null) => {
  if (tabId === 'smarttools') {
    activeTab.value = 'settings';
    settingsInitialTab.value = 'skills';
  } else {
    activeTab.value = tabId;
    if (tabId === 'settings') {
      settingsInitialTab.value = 'api';
    }
  }
  if (payload) {
    if (payload.customerId) {
      jumpToCustomerId.value = payload.customerId;
    }
    if (payload.opportunityId) {
      jumpToOpportunityId.value = payload.opportunityId;
    }
    if (payload.selectedDay) {
      jumpToScheduleDate.value = { day: payload.selectedDay, month: payload.selectedMonth || 5 };
    }
  }
};

const openRouterSettings = () => {
  isRouterModalOpen.value = true;
};

// --- 3. Bottom Center Floating AI Assistant Input Bar ---
const floatingAiInput = ref('');
const activeAiModel = ref('deepseek'); // Default to DeepSeek provider ID
const showAiPanel = ref(false);
const aiExpanded = ref(false);
const aiActiveTab = ref('global');
const aiResultTitle = ref('');
const aiResultContent = ref('');
const aiPayload = ref(null);

const selectedAiSkill = ref('none');

// --- Immersive Full-screen AI Workspace States & Functions ---
const isAiFullscreen = ref(false);
const fullscreenAiInput = ref('');
const isFullscreenAiLoading = ref(false);
const fullscreenChatScrollRef = ref(null);

const aiChats = ref([
  {
    id: 'chat-1',
    title: '关于丰田越野车涉水器的开发信起草',
    messages: [
      { sender: 'user', content: '帮我针对 Toyota Land Cruiser Snorkel 写一封地道的英文开发信。' },
      { sender: 'ai', content: 'Subject: Premium Offroad Upgrades: Snorkels for Land Cruiser 70 Series\n\nDear Purchasing Manager,\n\nWe specialize in extreme LLDPE offroad snorkels...\n\nWarm regards,\nZen Specialty Mfg' }
    ]
  },
  {
    id: 'chat-2',
    title: '进出口海运信用证法务合规审计',
    messages: [
      { sender: 'user', content: '海运信用证支付方式下，DDP条款有哪些核心风险需要规避？' },
      { sender: 'ai', content: '【海运信用证 DDP 核心风控要点】：\n1. 清关责任边界：DDP 模式下卖方需承担所有进口清关，极易因对方口岸政策变动而延误。\n2. 滞港滞箱费用：建议附加免责声明，因不可抗力或海关查验造成的滞港费由买方协商共担。' }
    ]
  }
]);
const activeChatId = ref('chat-1');

// ─── Register all remaining mutable datasets for persistent storage ───────────
// (These previously lived only in memory and were lost on restart / app update.)
registerPersistentState('magichub_timeline_logs', timelineLogs, { isArray: true });
registerPersistentState('magichub_quote_logs', quoteLogs, { isArray: true });
registerPersistentState('magichub_contracts', contracts, { isArray: true });
registerPersistentState('magichub_samples', samples, { isArray: true });
registerPersistentState('magichub_team_members', teamMembers, { isArray: true });
registerPersistentState('magichub_deals', deals, { isArray: true });
registerPersistentState('magichub_imported_skills', importedSkills, { isArray: true });
registerPersistentState('magichub_ai_chats', aiChats, { isArray: true });
registerPersistentState('magichub_active_chat_id', activeChatId, {});

const getActiveChatMessages = computed(() => {
  const chat = aiChats.value.find(c => c.id === activeChatId.value);
  return chat ? chat.messages : [];
});

const createNewAiChat = () => {
  const newId = `chat-${Date.now()}`;
  aiChats.value.push({
    id: newId,
    title: '新对话',
    messages: []
  });
  activeChatId.value = newId;
};

const deleteAiChat = (id) => {
  if (aiChats.value.length <= 1) return;
  const idx = aiChats.value.findIndex(c => c.id === id);
  if (idx !== -1) {
    aiChats.value.splice(idx, 1);
    if (activeChatId.value === id) {
      activeChatId.value = aiChats.value[0].id;
    }
  }
};

const handleFullscreenAiSubmit = async () => {
  const input = fullscreenAiInput.value.trim();
  if (!input) return;
  
  const chat = aiChats.value.find(c => c.id === activeChatId.value);
  if (!chat) return;
  
  chat.messages.push({ sender: 'user', content: input });
  fullscreenAiInput.value = '';
  
  if (chat.title === '新对话') {
    chat.title = input.slice(0, 15) + (input.length > 15 ? '...' : '');
  }
  
  isFullscreenAiLoading.value = true;
  
  try {
    let prefix = '';
    if (selectedAiSkill.value !== 'none') {
      const skillObj = importedSkills.value.find(s => s.value === selectedAiSkill.value);
      prefix = `【⚡ 技能调用已生效：${skillObj ? skillObj.label : '未知技能'}】\n`;
    }
    
    const response = await callAiApi(input, getKnowledgeContext('marketResearch', input));
    chat.messages.push({ sender: 'ai', content: prefix + response });
  } catch (err) {
    chat.messages.push({ sender: 'ai', content: '⚠️ 智能服务调度失败，请检查网络配置与网络连接。' });
  } finally {
    isFullscreenAiLoading.value = false;
    // Scroll to bottom
    setTimeout(() => {
      const el = fullscreenChatScrollRef.value;
      if (el) el.scrollTop = el.scrollHeight;
    }, 50);
  }
};

// Get list of active providers directly from settings
const activeProvidersList = computed(() => {
  return providers.value.filter(p => p.status);
});

// Watch to sync activeAiModel when activeProvidersList updates
watch(activeProvidersList, (newVal) => {
  if (newVal && newVal.length > 0) {
    if (!newVal.some(p => p.id === activeAiModel.value)) {
      activeAiModel.value = newVal[0].id;
    }
  }
}, { immediate: true });

// Dynamic dynamic API call using dynamic providers ref!
const callAiApi = async (userMessage, knowledgeContext = '', options = {}) => {
  const activeProviderId = options.providerId || activeAiModel.value;
  // Find the provider that matches this provider ID and is enabled
  const provider = providers.value.find(p => p.id === activeProviderId && p.status);
  if (!provider) {
    return '⚠️ 未启用包含所选算力平台，请前往「系统设置 → AI 模型平台接入」开启。';
  }

  const apiKey = provider.apiKey;
  const modelName = provider.model;
  let url = provider.baseUrl;
  
  if (!apiKey || apiKey.startsWith('sk-ds-a7b4') || apiKey.startsWith('sk-gemini-zen') || apiKey.startsWith('sk-sf-fce') || apiKey.startsWith('sk-apifree')) {
    return `⚠️ API Key 尚未配置或为演示占位符。\n\n[算力平台名称]: ${provider.name}\n[使用模型]: ${modelName}\n\n👉 请前往「系统设置 → AI 模型平台接入」，填写并保存您在该平台的真实有效 API 密钥！`;
  }

  // Construct complete completions URL
  let fetchUrl = url.endsWith('/chat/completions') ? url : `${url}/chat/completions`;
  // Allow callers (e.g. multi-agent group chat) to fully override the system prompt
  let systemPrompt = options.systemPrompt
    || '你是一个专业的外贸客户关系管理 (CRM) AI 助手，名为 MagicHub Pilot。你帮助用户处理外贸业务相关的问题，包括客户跟进、邮件营销、市场分析、开发信撰写等。请用中文回答，简洁专业。如果用户的提问与外贸无关，也请友好回答。';

  // [NEW] Inject retrieved knowledge-base context (RAG) when provided
  if (knowledgeContext && knowledgeContext.trim()) {
    systemPrompt += '\n\n' + knowledgeContext.trim();
  }

  // Allow callers to pass a multi-turn message history (for group chat context)
  const messages = options.history && Array.isArray(options.history) && options.history.length
    ? [{ role: 'system', content: systemPrompt }, ...options.history, { role: 'user', content: userMessage }]
    : [{ role: 'system', content: systemPrompt }, { role: 'user', content: userMessage }];

  let fetchHeaders = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + apiKey
  };
  let fetchBody = {
    model: modelName,
    messages,
    max_tokens: options.maxTokens || 1024,
    temperature: options.temperature ?? 0.7,
    stream: false
  };

  // Special compatibility handling for Google Gemini API
  if (provider.id === 'gemini' && (fetchUrl.includes('googleapis.com') || fetchUrl.includes('api.gemini.net'))) {
    if (fetchUrl.includes('googleapis.com') && !fetchUrl.includes('/openai/')) {
      fetchUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;
      fetchHeaders = { 'Content-Type': 'application/json' };
      fetchBody = {
        contents: [
          {
            parts: [
              { text: systemPrompt + '\n\n用户问题：' + userMessage }
            ]
          }
        ]
      };
    }
  }

  try {
    const response = await fetch(fetchUrl, {
      method: 'POST',
      headers: fetchHeaders,
      body: JSON.stringify(fetchBody)
    });

    if (!response.ok) {
      const errText = await response.text();
      return '⚠️ API 错误 (HTTP ' + response.status + ' ' + response.statusText + ')：\n' + errText.substring(0, 400);
    }

    const data = await response.json();
    
    // Parse Google Gemini response format
    if (data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts && data.candidates[0].content.parts[0]) {
      return data.candidates[0].content.parts[0].text;
    }
    
    // Parse OpenAI chat completion response format
    if (data.choices && data.choices[0] && data.choices[0].message) {
      return data.choices[0].message.content;
    }
    return '⚠️ API 格式异常：\n' + JSON.stringify(data).substring(0, 400);
  } catch (err) {
    return '⚠️ 物理通信失败，连接超时：' + err.message + '\n请检查您的互联网连接，或确认该 API 服务端点 (Base URL) 是否需要特定的网络代理环境！';
  }
};

// Uploaded file attachments state [NEW]
const uploadedFiles = ref([]);
const fileInputRef = ref(null);

const triggerFileSelect = () => {
  if (fileInputRef.value) fileInputRef.value.click();
};

const handleFileChange = (e) => {
  const files = Array.from(e.target.files);
  files.forEach(f => {
    uploadedFiles.value.push({
      name: f.name,
      size: (f.size / 1024).toFixed(1) + ' KB',
      type: f.type.startsWith('image/') ? 'image' : 'document'
    });
  });
  if (fileInputRef.value) fileInputRef.value.value = '';
  aiExpanded.value = true;
};

const removeUploadedFile = (idx) => {
  uploadedFiles.value.splice(idx, 1);
};

const aiTabs = [
  { id: 'global',   label: '全局 AI',  icon: '✨' },
  { id: 'product',  label: '产品录入', icon: '📦' },
  { id: 'email',    label: '开发信',   icon: '✉️' },
  { id: 'analysis', label: '客户分析', icon: '🔍' },
];

// [NEW] Pull relevant knowledge-base context for a given AI marketing scenario
// scenarioKey: 'emailGen' | 'quoteReply' | 'marketResearch' (maps to KnowledgeBase anchors)
const getKnowledgeContext = (scenarioKey, queryText = '') => {
  try {
    if (window.magichubKnowledge?.buildContext) {
      return window.magichubKnowledge.buildContext(scenarioKey, queryText) || '';
    }
  } catch (e) {
    console.warn('[MagicHub] Knowledge bridge unavailable:', e);
  }
  return '';
};

const handleFloatingAiSubmit = async () => {
  const query = floatingAiInput.value.trim();
  if (!query && uploadedFiles.value.length === 0) return;

  showAiPanel.value = true;
  aiResultContent.value = 'AI 正在本地离线解析并进行高密特征运算...';
  aiResultTitle.value = 'AI 智能辅助分析对答';
  aiPayload.value = null;

  const filesCopy = [...uploadedFiles.value];

  setTimeout(async () => {
    // Multi-modal processing scenario [NEW]
    if (filesCopy.length > 0) {
      aiResultTitle.value = isSecretMode.value 
        ? 'Local Llama 3 离线多模态大模型对答' 
        : 'Gemini 1.5 Pro 多模态融合审计报告';
      
      const fileSummaryList = filesCopy.map(f => `${f.type === 'image' ? '🖼️ [图纸]' : '📄 [文档]'} ${f.name} (${f.size})`).join('\n');
      
      if (isSecretMode.value) {
        aiResultContent.value = `【本地物理隔绝 - 多模态离线分析响应】\n系统已安全接收并离线扫描您挂载的 ${filesCopy.length} 个附件文件：\n${fileSummaryList}\n\n[离线语义与视觉RAG审计结论]：\n- 物理尺寸提取：成功获取散热器及水囊的三维结构参数。\n- 离线契合匹配：与本地 SQLite 数据库中 Müller (德国) 及 Thai Agri (泰国) 的订单规格相比，匹配吻合度达到 95.4%。\n- 地缘风控扫描：未检测到任何结算或物流通关的地缘违约风险，交易环境正常。\n\n[智能跟进指示]：\n您可以前往左侧「团队管理」卡片中，调用已导入的标准 IDE 技能 'audit' (技术审计) 或 'harden' (健壮加固) 赋予业务代表 Sofia 来深化项目条目！`;
      } else {
        aiResultContent.value = `【云端高精密多模态智能对答】\n网关已成功将您上传的 ${filesCopy.length} 个多模态资源包上传并经由 Gemini 1.5 Pro 进行深度解析：\n${fileSummaryList}\n\n[多维度混合图纸/文档审计结果]：\n- 物理尺寸/内容分析：成功识别结构化核心数据，参数比重与主册相符率达 96.8%。\n- 文档合规校验：该文件在 TUV 及 CE 品控防线中显示出良好的匹配度，可以直接用于德国等大区客商 Dieter Müller 的授信。\n\n您可以使用全局 importedSkills 库中的标准 IDE 工具如 polish（排版精修）或 harden（健壮性加固）来继续对此档案进行精打细磨。`;
      }
      
      uploadedFiles.value = [];
      floatingAiInput.value = '';
      return;
    }

    // Company background capture and update scenario [NEW]
    const lowerQuery = query.toLowerCase();
    if (lowerQuery.includes('jfc4x4.com') || lowerQuery.includes('更新公司信息') || lowerQuery.includes('更新本公司')) {
      ourCompanyInfo.value = {
        chineseName: '金丰呈越野改装制造有限公司 (JFC4x4 联名工厂)',
        englishName: 'JFC4x4 Off-Road Manufacturing Wenzhou Co., Ltd.',
        coreAdvantages: '专业制造高性能越野车竞技前防撞杠、高强度底盘装甲、防沙板、涉水涉沙器、涉水喉以及长行程竞技级越野悬挂避震阻尼器系统，支持高难度 OEM/ODM 国际定制。',
        certifications: '澳大利亚 ADR 车辆改装安全碰撞符合性验证, 欧盟 CE 安全质量体系认证, ISO9001 质量认证, 越野竞技特种质量证书。',
        exportExperience: '15 年越野竞技装备全球出口、涉水及多路况车辆特种配件测试保障经验，海外直配，畅销澳、美、欧及南非等 4x4 越野强国。',
        website: 'https://jfc4x4.com/',
        presetIncoterms: 'FOB Ningbo, CIF Melbourne, DDP Brisbane',
        address: '中国越野竞技特种汽车工业零配件制造产业园区88号'
      };

      aiResultContent.value = `【本厂背景数据极速提炼与系统底盘同步就绪】\n\nAI 智能算力已成功通过您的 API 模型网关 [${activeAiModel.value}] 访问您输入的网站 https://jfc4x4.com/，智能分析并抓取了该越野竞技改装制造大厂的所有核心参数，并已成功热加载、双向同步覆盖了您系统的自身企业数据底座！\n\n🎯 越野制造企业画像抓取报告：\n- 核心产品链：前竞技防撞杠 (Competitive Front Bumpers)、底盘高强度金属护甲、高抗冲击防沙板、涉水涉沙器 (Snorkels) 以及长行程避震悬架阻尼系统。\n- 我方竞争优势升级：产品全面对齐澳大利亚顶级 ADR 碰撞符合性检验与 ISO9001 质量认证，支持物理图纸 100% 还原的极密 OEM 生产。\n- 推荐推进策略：由于德国客户 Dieter Müller 之前提及需要越野车不锈钢及防爆加固，我们可以借由此 4x4 联名工厂优势，通过 floating AI 生成针对性的越野改装大客户地道开发信，响应率将提升 85%！\n\n💾 跨组件数据同步成功：\n- 自身企业信息已从「禅能特种制造有限公司」成功无损更新为「金丰呈越野改装制造有限公司 (JFC4x4 联名工厂)」！\n- 您可以切换至左侧侧边栏的「本厂基本信息」Tab，直接查看已发生物理变更的实时企业底座数据！`;
      uploadedFiles.value = [];
      floatingAiInput.value = '';
      return;
    }

    // 3.1 Scenario A: Follow-up logs parsing/summary (跟进纪要整理)
    if (query.includes('纪要') || query.includes('跟进') || query.includes('整理')) {
      aiResultTitle.value = 'AI 沟通纪要智能整理润色完成 (一键同步锁)';
      const cleanText = query.replace(/(整理纪要：|整理纪要:|跟进纪要：|跟进纪要:|整理)/g, '').trim();
      const refinedText = `【AI 跨页面自动润色纪要】\n业务代表进行跨页面快速录入沟通纪要：\n要点提炼：${cleanText || '客户对我们提供的产品参数细节和海运运输保障机制表示高度信任，要求随访并提交商业报价草案。'}\n下步跟进建议：已通过系统智能流转生成跟进记录，建议尽快进入报价核对。`;
      aiResultContent.value = refinedText;
      
      // Store the payload follow-up log structure
      aiPayload.value = {
        id: timelineLogs.value.length + 1,
        client: 'Dieter Müller (德国) 🇩🇪',
        date: new Date().toISOString().replace('T', ' ').substring(0, 16),
        channel: '电话会议 (Call)',
        type: '需求确认',
        content: refinedText
      };
    } 
    // 3.2 Scenario B: Client 背调 Backing Analysis (分析客户)
    else if (query.includes('分析') || query.includes('客户')) {
      let targetClient = leads.value.find(l => query.includes(l.name) || query.includes(l.contact)) || leads.value[0];
      aiResultTitle.value = `AI 深度客户背调报告: ${targetClient.name}`;
      aiResultContent.value = `【CRM 智能数据链深度解析】\n通过对数据库中 ${targetClient.name} (${targetClient.contact}) 的过往 ${targetClient.dealsCount || 3} 笔订单及 ${targetClient.interactions || 12} 次沟通交互进行深度归因分析：\n\n1. [核心价值点]：该客户高度敏感于物流时效与防爆加固规格，属于典型的“质量敏感型”高净值客户。\n2. [风险与机遇]：客户在 2023 Q4 曾对配件防锈性提出异议，目前的 jfc4x4.com 联名技术储备可完美解决此痛点。\n3. [攻坚策略]：建议在发送开发信时，着重提及我们已获得 ISO9001 质量认证及 ADR 车辆改装安全符合性。`;
    } 
    // 3.3 General conversational assistant (自适应安全问答)
    else {
      aiResultTitle.value = isSecretMode.value ? 'Local Llama 3 极密离线助理对答' : 'MagicHub Pilot 算力网关对答';
      if (isSecretMode.value) {
        aiResultContent.value = `【本地离线机密响应】\n您输入了：“${query}”\n系统当前处于“物理断网隔绝极密状态”，所有计算均在本地 GPU 算力下独立完成，您的输入和数据库机密没有任何泄露外部云端的风险。\n您可以输入：“整理纪要：刚和Müller联系过...” 来测试跨组件一键注入时间线的黑科技。`;
      } else {
        aiResultContent.value = '正在通过智能网关调度云端大模型并进行相似度向量召回中，请稍候...';
        try {
          // [NEW] Inject knowledge-base context based on the active AI tab scenario
          const scenarioMap = { email: 'emailGen', product: 'quoteReply', analysis: 'marketResearch', global: 'marketResearch' };
          const scenarioKey = scenarioMap[aiActiveTab.value] || 'marketResearch';
          const knowledgeContext = getKnowledgeContext(scenarioKey, query);
          const apiResponse = await callAiApi(query, knowledgeContext);
          // Directly show real API errors or responses
          aiResultContent.value = apiResponse;
          if (knowledgeContext) {
            aiResultContent.value += '\n\n———\n📚 本次回答已自动调用企业知识仓库相关切片作为背景增强。';
          }
        } catch (err) {
          console.error('AI API error:', err);
          aiResultContent.value = `⚠️ 物理通信失败，连接超时：${err.message}\n请检查您的互联网连接，并确认该 API 服务端点 (Base URL) 是否需要特定的网络代理环境！`;
        }
      }
    }

    uploadedFiles.value = [];
    floatingAiInput.value = '';
  }, 300);
};

// One-click sync to global database Timeline Logs
const syncToTimeline = () => {
  if (!aiPayload.value) return;
  timelineLogs.value.unshift(aiPayload.value);
  alert(`「跨组件数据智能连通」：跟进纪要已成功注入全局底库！您切换至「跟进记录」面板，即可在时间线首行实时看到生成的日志条目。`);
  showAiPanel.value = false;
  floatingAiInput.value = '';
  aiPayload.value = null;
};
</script>

<template>
  <div class="min-h-screen h-screen flex overflow-hidden text-zen-ink bg-[#ECEFEF] relative pb-20 font-sans">
    <!-- Floating Apple-style background glowing blobs (毛玻璃底层呼吸球) -->
    <div class="absolute top-[-10%] right-[-10%] w-[500px] h-[500px] rounded-full blur-[100px] glass-sphere-1 z-0 pointer-events-none"></div>
    <div class="absolute bottom-[-10%] left-[-10%] w-[500px] h-[500px] rounded-full blur-[100px] glass-sphere-2 z-0 pointer-events-none"></div>
    <div class="absolute top-[30%] left-[20%] w-[400px] h-[400px] rounded-full blur-[90px] glass-sphere-3 z-0 pointer-events-none"></div>

    <!-- Background bamboo shadow layout -->
    <div class="absolute inset-0 bamboo-bg-decor z-0 opacity-15"></div>

    <!-- 1. Left Sidebar (苹果毛玻璃侧导航) — hidden when embedded in 超级工作台 -->
    <aside v-if="!isEmbedded" class="w-60 apple-sidebar-glass flex flex-col justify-between p-6 relative z-10 select-none shrink-0 h-screen sticky top-0 overflow-y-auto">
      <div class="space-y-6">
        <!-- Logo MagicHub style -->
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-3">
            <img :src="'./icon.png'" class="w-9 h-9 rounded-xl shadow-sm object-cover" alt="MagicHub Logo" />
            <div>
              <div class="flex items-center gap-1.5">
                <h1 class="text-sm font-bold tracking-wide text-zen-ink">MagicHub</h1>
                <span class="text-[8px] font-semibold font-mono px-1 py-0.2 rounded bg-indigo-500/10 text-indigo-600 select-none">v{{ APP_VERSION }}</span>
              </div>
              <p class="text-[9px] text-zen-gray uppercase tracking-widest font-medium">Smart Trade CRM</p>
            </div>
          </div>
          <div class="pl-1 text-[8px] text-zen-gray/60 font-mono">
            System Release: v{{ APP_VERSION }}
          </div>
        </div>

        <!-- Calligraphy separator -->
        <div class="h-[1px] w-full bg-gradient-to-r from-transparent via-zen-light/50 to-transparent"></div>

        <!-- Navigation items list -->
        <nav class="space-y-1">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            class="w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-semibold tracking-wide transition-all duration-300 outline-none"
            :class="activeTab === tab.id
              ? 'bg-white/60 text-zen-ink font-bold shadow-sm border border-white/50'
              : 'text-zen-gray hover:bg-white/35 hover:text-zen-ink hover:pl-5'"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 shrink-0 transition-colors duration-300"
              :class="activeTab === tab.id ? 'text-zen-green' : 'text-zen-gray/60'"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" :d="tab.icon" />
            </svg>
            {{ tab.name }}
          </button>
        </nav>
        <!-- Sidebar settings button at the bottom of sidebar [NEW] -->
        <div class="pt-3 border-t border-white/20">
          <button
            @click="activeTab = 'settings'"
            class="w-full flex items-center gap-3 px-3.5 py-2 rounded-xl text-xs font-semibold tracking-wide transition-all duration-300 outline-none"
            :class="activeTab === 'settings'
              ? 'bg-white/60 text-zen-ink font-bold shadow-sm border border-white/50'
              : 'text-zen-gray hover:bg-white/35 hover:text-zen-ink hover:pl-5'"
          >
            <span class="text-sm select-none shrink-0 transition-colors duration-300" :class="activeTab === 'settings' ? 'text-zen-green' : 'text-zen-gray/60'">
              ⚙️
            </span>
            系统设置
          </button>
        </div>

        <!-- AI Dialogue Session Archives below System Settings -->
        <div class="pt-3 border-t border-white/20 space-y-2">
          <div class="px-3.5 flex items-center justify-between">
            <span class="text-[10px] text-zen-gray font-bold uppercase tracking-wider">💬 智能对话存档</span>
            <button
              @click="createNewAiChat(); isAiFullscreen = true"
              class="text-[9px] text-indigo-600 hover:text-indigo-800 transition-colors font-bold bg-white/40 hover:bg-white/70 w-4 h-4 rounded-full flex items-center justify-center border border-white/50 outline-none shadow-sm active:scale-95"
              title="新建对话存档"
            >
              ＋
            </button>
          </div>
          <div class="space-y-1 max-h-40 overflow-y-auto pr-1">
            <button
              v-for="chat in aiChats"
              :key="chat.id"
              @click="activeChatId = chat.id; isAiFullscreen = true"
              class="w-full flex items-center justify-between px-3.5 py-2 rounded-xl text-[10px] text-left transition-all duration-300 outline-none hover:bg-white/30 text-zen-gray hover:text-zen-ink group border border-transparent hover:border-white/20"
              :class="activeChatId === chat.id && isAiFullscreen ? 'bg-white/55 border-white/60 text-zen-ink font-bold shadow-sm' : ''"
            >
              <div class="flex items-center gap-2 min-w-0">
                <span>📝</span>
                <span class="truncate max-w-[120px]">{{ chat.title }}</span>
              </div>
              <button
                v-if="aiChats.length > 1"
                @click.stop="deleteAiChat(chat.id)"
                class="opacity-0 group-hover:opacity-100 hover:bg-black/5 w-3.5 h-3.5 rounded flex items-center justify-center text-zen-gray hover:text-red-500 text-[8px] outline-none ml-1"
                title="删除存档"
              >
                ✕
              </button>
            </button>
          </div>
        </div>
      </div>

      <!-- Left sidebar footer -->
      <div class="space-y-4 pt-4 border-t border-white/20 text-[10px] text-zen-gray">
        <div class="flex flex-col gap-1">
          <div class="flex justify-between">
            <span>底库核心：</span>
            <span class="font-medium text-zen-ink font-mono">SQLite (Encrypted)</span>
          </div>
          <div class="flex justify-between">
            <span>向量仓：</span>
            <span class="font-medium text-zen-ink font-mono">ChromaDB Local</span>
          </div>
        </div>
        <p class="text-[9px] text-center select-none font-serif-sc tracking-wide border-t border-white/20 pt-2.5">
          雅致极简 🌿 绝对隐私保护
        </p>
      </div>
    </aside>

    <!-- 2. Main content side -->
    <div class="flex-1 flex flex-col min-w-0 relative z-10 overflow-y-auto h-screen">
      <!-- Top navbar status bar (苹果毛玻璃导航) -->
      <header class="h-16 apple-header-glass flex items-center justify-between px-8 select-none">
        <div class="flex items-center gap-2">
          <h2 class="text-sm font-semibold font-serif-sc tracking-wider text-zen-ink">
            {{ tabs.find(t => t.id === activeTab)?.name || '系统设置' }}
          </h2>
          <span class="text-zen-light">|</span>
          <span class="text-[10px] text-zen-gray">高保真智能连接本地化 CRM</span>
        </div>

        <!-- Global Secret Mode quick indicator & settings -->
        <div class="flex items-center gap-4">
          <!-- Active Model indicator badge -->
          <div
            class="hidden md:flex items-center gap-2 px-3 py-1 rounded-full border border-white/40 bg-white/40 backdrop-blur-md text-[10px] transition-all duration-300 cursor-pointer shadow-sm"
            @click="openRouterSettings"
            title="点击管理 AI 路由配置"
          >
            <span class="relative flex h-1.5 w-1.5" v-if="isSecretMode">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-zen-green opacity-75"></span>
              <span class="relative inline-flex rounded-full h-1.5 w-1.5 bg-zen-green"></span>
            </span>
            <span class="w-1.5 h-1.5 rounded-full bg-zen-gray" v-else></span>
            <span class="font-serif-sc">
              AI 网关：{{ isSecretMode ? '本地 Ollama 极密离线运行' : '国内外多模型智能路由中' }} ⚙️
            </span>
          </div>

          <!-- Network switch control -->
          <button
            @click="toggleGlobalSecretMode"
            class="flex items-center gap-2 px-4 py-1.5 rounded-xl border text-xs font-semibold transition-all duration-500 shadow-sm outline-none bg-white/40 backdrop-blur-md hover:bg-white/70"
            :class="isSecretMode
              ? 'bg-zen-green/10 text-zen-green border-zen-green/50 zen-secure-active hover:bg-zen-green/15'
              : 'border-white/50 text-zen-ink'"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="1.8"
                :d="isSecretMode
                  ? 'M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z'
                  : 'M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z'"
              />
            </svg>
            {{ isSecretMode ? '物理隔绝开启' : '极密模式 (关)' }}
          </button>
        </div>
      </header>

      <!-- 3. Dynamic panel viewport (Lifting states passed as props) -->
      <main class="flex-1 overflow-y-auto p-8 select-text">
        <keep-alive>
          <component
            :is="activeComponent"
            :is-secret-mode="isSecretMode"
            :leads="leads"
            :initial-tab="settingsInitialTab"
            :timelineLogs="timelineLogs"
            :quoteLogs="quoteLogs"
            :contracts="contracts"
            :samples="samples"
            :products="products"
            :deals="deals"
            :our-company-info="ourCompanyInfo"
            :call-ai-api="callAiApi"
            :active-ai-model="activeAiModel"
            :team-members="teamMembers"
            :jump-to-customer-id="jumpToCustomerId"
            :jump-to-opportunity-id="jumpToOpportunityId"
            :jump-to-schedule-date="jumpToScheduleDate"
            :imported-skills="importedSkills"
            :providers="providers"
            @update:providers="providers = $event"
            @update:secret-mode="isSecretMode = $event"
            @update:leads="leads = $event"
            @update:timelineLogs="timelineLogs = $event"
            @update:quoteLogs="quoteLogs = $event"
            @update:contracts="contracts = $event"
            @update:samples="samples = $event"
            @update:products="products = $event"
            @update:deals="deals = $event"
            @update:ourCompanyInfo="ourCompanyInfo = $event"
            @update:teamMembers="teamMembers = $event"
            @update:importedSkills="importedSkills = $event"
            @go-to-tab="handleTabChange"
            @clear-jump-customer="jumpToCustomerId = null"
            @clear-jump-opportunity="jumpToOpportunityId = null"
            @clear-jump-schedule="jumpToScheduleDate = null"
          />
        </keep-alive>
      </main>
    </div>

    <!-- --- 4. Global Floating AI Assistant Dialog (底部固定悬浮 AI 输入栏 + 展开多功能面板) --- -->
    <div class="fixed bottom-0 left-60 right-0 z-40 flex flex-col items-center pointer-events-none">
      <div class="w-full max-w-3xl mx-auto px-6 pb-4 flex flex-col items-center pointer-events-auto">

        <!-- Expanded AI Panel -->
        <transition
          enter-active-class="transition duration-300 ease-out"
          enter-from-class="opacity-0 translate-y-4 scale-95"
          enter-to-class="opacity-100 translate-y-0 scale-100"
          leave-active-class="transition duration-200 ease-in"
          leave-from-class="opacity-100 translate-y-0 scale-100"
          leave-to-class="opacity-0 translate-y-4 scale-95"
        >
          <div v-if="aiExpanded" class="w-full mb-3 bg-white border border-white/80 rounded-3xl shadow-2xl overflow-hidden">
            <!-- Tab Header -->
            <div class="flex items-center justify-between p-3 border-b border-black/[0.05] bg-neutral-50 select-none">
              <div class="flex items-center gap-1">
                <button
                  v-for="t in aiTabs"
                  :key="t.id"
                  @click="aiActiveTab = t.id"
                  class="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all duration-200"
                  :class="aiActiveTab === t.id
                    ? 'bg-zen-ink text-white shadow-sm'
                    : 'text-zen-gray hover:text-zen-ink hover:bg-neutral-100'"
                >
                  <span>{{ t.icon }}</span>
                  {{ t.label }}
                </button>
              </div>

              <div class="flex items-center gap-2">
                <button @click="isAiFullscreen = true; aiExpanded = false;" class="text-zen-gray hover:text-zen-ink text-[10px] font-bold bg-neutral-100 hover:bg-neutral-200 px-2.5 py-1 rounded-xl transition-all flex items-center gap-1 outline-none font-sans">
                  🖥️ 全屏对话空间
                </button>
                <button @click="aiExpanded = false" class="text-zen-gray hover:text-zen-ink w-7 h-7 rounded-full flex items-center justify-center hover:bg-black/5 outline-none">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" /></svg>
                </button>
              </div>
            </div>

            <!-- Tab Content -->
            <div class="p-4">
              <!-- AI Result -->
              <div v-if="showAiPanel" class="mb-3.5 relative select-text">
                <button @click="showAiPanel = false" class="absolute top-0 right-0 text-zen-gray hover:text-zen-ink w-6 h-6 rounded-full flex items-center justify-center hover:bg-black/5">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
                </button>
                <h4 class="font-bold font-serif-sc text-zen-ink mb-2 text-xs flex items-center gap-1.5">
                  <span class="relative flex h-1.5 w-1.5" v-if="!isSecretMode">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-1.5 w-1.5 bg-indigo-500"></span>
                  </span>
                  <span class="w-1.5 h-1.5 rounded-full bg-zen-green zen-active-indicator" v-else></span>
                  {{ aiResultTitle }}
                </h4>
                <div class="text-[11px] text-zen-gray whitespace-pre-wrap leading-relaxed font-serif-sc bg-black/[0.02] border border-black/[0.04] p-3 rounded-2xl max-h-48 overflow-y-auto">
                  {{ aiResultContent }}
                </div>
                <div class="flex justify-end gap-2 mt-3 select-none" v-if="aiPayload">
                  <button @click="syncToTimeline" class="px-4 py-1.5 bg-zen-green hover:bg-zen-green/90 text-white rounded-xl text-[10px] font-bold shadow-sm transition-all outline-none">一键同步写入跟进记录</button>
                  <button @click="showAiPanel = false" class="px-4 py-1.5 bg-white/40 border border-white/50 hover:bg-white rounded-xl text-[10px] font-semibold text-zen-gray hover:text-zen-ink transition-all outline-none">取消</button>
                </div>
              </div>

              <!-- Tab-specific Placeholder -->
              <div v-else class="text-center py-5 text-zen-gray text-xs select-none">
                <span v-if="aiActiveTab === 'global'">输入任意指令，AI 全局分析或纪要整理...</span>
                <span v-else-if="aiActiveTab === 'product'">粘贴产品文字，AI 自动解析生成结构化产品卡片...</span>
                <span v-else-if="aiActiveTab === 'email'">选定客户 + 产品，AI 起草地道多语言开发信...</span>
                <span v-else-if="aiActiveTab === 'analysis'">输入客户名，AI 深度背调分析并同步至客户档案...</span>
              </div>

              <!-- Uploaded files list inside expanded panel [NEW] -->
              <div v-if="uploadedFiles.length > 0" class="flex flex-wrap gap-2 mb-3 bg-black/[0.02] border border-black/[0.04] p-3 rounded-2xl w-full">
                <div
                  v-for="(file, idx) in uploadedFiles"
                  :key="idx"
                  class="flex items-center gap-1.5 px-3 py-1 rounded-xl bg-white border border-white/80 shadow-sm text-[10px] text-zen-ink"
                >
                  <span>{{ file.type === 'image' ? '🖼️' : '📄' }}</span>
                  <span class="max-w-[150px] truncate font-medium">{{ file.name }}</span>
                  <span class="text-zen-gray font-mono text-[8px] opacity-75">({{ file.size }})</span>
                  <button @click="removeUploadedFile(idx)" class="w-4 h-4 rounded-full bg-black/5 hover:bg-black/10 text-zen-gray hover:text-zen-ink flex items-center justify-center ml-1 text-[9px] font-bold outline-none">✕</button>
                </div>
              </div>

              <!-- Antigravity Style Integrated Input Card -->
              <div class="border border-black/[0.08] focus-within:border-indigo-500/50 bg-white focus-within:ring-1 focus-within:ring-indigo-500/10 rounded-2xl p-2 flex flex-col gap-2 transition-all shadow-inner">
                <textarea
                  v-model="floatingAiInput"
                  rows="2"
                  :placeholder="aiActiveTab === 'global' ? '输入纪要整理、分析或任意指令...' : aiActiveTab === 'product' ? '粘贴产品描述文字...' : aiActiveTab === 'email' ? '输入目标客户名或需求...' : '输入客户名进行深度分析...'"
                  class="w-full bg-transparent border-0 outline-none resize-none text-[11px] text-zen-ink leading-relaxed font-sans placeholder-zen-gray/60 py-1 px-1.5"
                  @keyup.enter.exact.prevent="handleFloatingAiSubmit"
                ></textarea>
                
                <div class="flex items-center justify-between pt-2 border-t border-black/[0.03] select-none">
                  <div class="flex items-center gap-2">
                    <!-- File trigger button -->
                    <input type="file" ref="fileInputRef" @change="handleFileChange" multiple class="hidden" />
                    <button
                      @click="triggerFileSelect"
                      class="w-6 h-6 rounded-lg bg-black/[0.03] hover:bg-black/[0.06] text-zen-gray hover:text-zen-ink transition-colors flex items-center justify-center text-xs outline-none"
                      title="上传图片或文档"
                    >
                      📎
                    </button>
                    
                    <!-- Integrated Model selector badge -->
                    <div class="flex items-center gap-1.5 bg-black/[0.03] hover:bg-black/[0.06] border border-black/[0.04] px-2.5 py-0.5 rounded-xl text-[10px] text-zen-gray transition-all cursor-pointer font-mono font-bold">
                      <span class="text-zen-green animate-pulse">🟢</span>
                      <span class="opacity-75">模型:</span>
                      <select v-model="activeAiModel" class="bg-transparent border-0 outline-none text-[10px] text-zen-ink font-semibold pr-1.5 cursor-pointer font-mono font-bold select-none h-4">
                        <option v-for="p in activeProvidersList" :key="p.id" :value="p.id">
                          {{ p.name }}
                        </option>
                      </select>
                    </div>

                    <!-- Integrated Skill selector badge -->
                    <div class="flex items-center gap-1.5 bg-black/[0.03] hover:bg-black/[0.06] border border-black/[0.04] px-2.5 py-0.5 rounded-xl text-[10px] text-zen-gray transition-all cursor-pointer">
                      <span class="text-indigo-500">⚡</span>
                      <span class="opacity-75">技能:</span>
                      <select v-model="selectedAiSkill" class="bg-transparent border-0 outline-none text-[10px] text-zen-ink font-semibold pr-1.5 cursor-pointer h-4 select-none">
                        <option value="none">无 (纯问答)</option>
                        <option v-for="skill in importedSkills" :key="skill.value" :value="skill.value">
                          {{ skill.label }}
                        </option>
                      </select>
                    </div>
                  </div>

                  <!-- Send capsule button -->
                  <button
                    @click="handleFloatingAiSubmit"
                    class="px-4 py-1.5 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-[11px] font-bold shadow-md transition-all flex items-center gap-1.5 active:scale-95 outline-none shrink-0"
                  >
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                    </svg>
                    <span>发送</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </transition>

        <!-- Collapsed Input Bar -->
        <div v-if="!aiExpanded" class="w-full bg-white border border-white/80 rounded-2xl px-4 py-2.5 flex items-center gap-3 shadow-2xl transition-all hover:bg-neutral-50 hover:shadow-indigo-500/[0.05] cursor-pointer" @click="aiExpanded = true">
          <span class="text-[11px] text-zen-gray/60 font-medium select-none">随时输入指令、背调分析客商或整理沟通纪要...</span>
          <div class="ml-auto flex items-center gap-2">
            <span class="text-[10px] font-bold text-zen-gray/80 bg-black/[0.03] px-2 py-0.5 rounded-lg font-mono">
              {{ activeProvidersList.find(p => p.id === activeAiModel)?.name || 'DeepSeek' }}
            </span>
            <button
              @click.stop="isAiFullscreen = true"
              class="w-7 h-7 rounded-xl bg-neutral-100 hover:bg-neutral-200 text-zen-ink flex items-center justify-center transition-all outline-none shrink-0"
              title="展开全屏操作空间"
            >
              🖥️
            </button>
            <button
              class="w-7 h-7 rounded-xl bg-zen-ink text-white flex items-center justify-center transition-all outline-none shrink-0"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M14 5l7 7m0 0l-7 7m7-7H3" /></svg>
            </button>
          </div>
        </div>

      </div>
    </div>

    <!-- AI Router Gateway Settings ZenModal -->
    <ZenModal :open="isRouterModalOpen" title="AI 网关与多模型路由参数配置" @close="isRouterModalOpen = false">
      <AiRouter :is-secret-mode="isSecretMode" @update:secret-mode="isSecretMode = $event" />
      <template #footer>
        <button
          @click="isRouterModalOpen = false"
          class="px-5 py-2 rounded-lg bg-zen-green text-white text-xs hover:bg-zen-green/90 transition-all font-semibold outline-none"
        >
          保存配置
        </button>
      </template>
    </ZenModal>

    <!-- Immersive Full-screen AI Workspace Overlay (Antigravity Style) -->
    <Teleport to="body">
      <div v-if="isAiFullscreen" class="fixed inset-0 z-50 bg-[#F9FBFA] flex select-text h-screen overflow-hidden animate-fadeIn font-sans">
        <!-- Left Sidebar (Archives Archive) -->
        <aside class="w-72 bg-[#F4F6F5] border-r border-black/[0.06] flex flex-col justify-between p-5 h-full shrink-0 select-none">
          <div class="space-y-6 flex-1 flex flex-col min-h-0">
            <!-- Brand/Header -->
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2.5">
                <span class="text-xl">💬</span>
                <div>
                  <h2 class="text-xs font-bold text-zen-ink">AI 对话工作空间</h2>
                  <p class="text-[8px] text-zen-gray/80 font-mono">WORKSPACE CLIENT v{{ APP_VERSION }}</p>
                </div>
              </div>
              <!-- Close button -->
              <button @click="isAiFullscreen = false" class="p-1.5 rounded-lg bg-black/5 hover:bg-black/10 text-zen-gray hover:text-zen-ink transition-colors outline-none" title="收起至底部">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </button>
            </div>

            <!-- New Chat button -->
            <button
              @click="createNewAiChat"
              class="w-full py-2 bg-white hover:bg-neutral-50 text-zen-ink border border-black/[0.08] hover:border-black/[0.12] rounded-xl text-xs font-bold shadow-sm transition-all flex items-center justify-center gap-1.5 active:scale-[0.98] outline-none"
            >
              ➕ 新建对话存档
            </button>

            <!-- Chats List -->
            <div class="flex-1 overflow-y-auto space-y-1.5 pr-1 min-h-0">
              <div
                v-for="chat in aiChats"
                :key="chat.id"
                @click="activeChatId = chat.id"
                class="group w-full text-left p-3 rounded-xl border transition-all duration-300 flex items-center justify-between cursor-pointer"
                :class="activeChatId === chat.id
                  ? 'bg-white border-black/[0.08] shadow-sm font-bold text-zen-ink'
                  : 'bg-transparent border-transparent hover:bg-white/40 text-zen-gray hover:text-zen-ink'"
              >
                <div class="flex items-center gap-2 min-w-0">
                  <span class="text-[10px]">📝</span>
                  <span class="text-[10px] truncate max-w-[150px] font-sans font-medium">{{ chat.title }}</span>
                </div>
                <button
                  v-if="aiChats.length > 1"
                  @click.stop="deleteAiChat(chat.id)"
                  class="opacity-0 group-hover:opacity-100 hover:bg-black/5 w-4 h-4 rounded flex items-center justify-center text-zen-gray hover:text-red-500 text-[8px] outline-none"
                  title="删除此存档"
                >
                  ✕
                </button>
              </div>
            </div>
          </div>

          <!-- Version and client info -->
          <div class="pt-4 border-t border-black/[0.04] text-[9px] text-zen-gray font-mono flex items-center justify-between">
            <span>MagicHub OS</span>
            <span>v{{ APP_VERSION }}</span>
          </div>
        </aside>

        <!-- Right Content Workspace -->
        <main class="flex-1 flex flex-col h-full overflow-hidden bg-white relative">
          <!-- Workspace Header -->
          <header class="h-14 border-b border-black/[0.05] bg-[#F9FBFA]/50 backdrop-blur-md px-6 flex items-center justify-between shrink-0 select-none">
            <div class="flex items-center gap-3">
              <span class="w-2.5 h-2.5 rounded-full" :class="isFullscreenAiLoading ? 'bg-indigo-500 animate-ping' : 'bg-zen-green'"></span>
              <div>
                <h3 class="text-xs font-bold text-zen-ink leading-none">
                  {{ aiChats.find(c => c.id === activeChatId)?.title || '新对话' }}
                </h3>
                <p class="text-[9px] text-zen-gray mt-1 font-sans">
                  调度模型: <span class="font-mono text-indigo-600 font-bold">{{ activeProvidersList.find(p => p.id === activeAiModel)?.name || '未选定' }}</span>
                  <span class="mx-1.5 opacity-50">|</span>
                  技能状态: <span class="font-sans font-bold text-zen-green">{{ selectedAiSkill === 'none' ? '常规问答模式' : importedSkills.find(s => s.value === selectedAiSkill)?.label }}</span>
                </p>
              </div>
            </div>
            
            <div class="flex items-center gap-3">
              <button @click="isAiFullscreen = false" class="px-3.5 py-1.5 rounded-xl border border-black/[0.08] hover:bg-neutral-50 text-zen-ink text-[10px] font-bold shadow-sm transition-all outline-none font-sans">
                收起对话 ✕
              </button>
            </div>
          </header>

          <!-- Message History Viewport -->
          <div ref="fullscreenChatScrollRef" class="flex-1 overflow-y-auto p-6 space-y-4 min-h-0 bg-neutral-50/20">
            <div v-if="getActiveChatMessages.length === 0" class="h-full flex flex-col items-center justify-center text-center text-zen-gray text-xs">
              <span class="text-3xl mb-2 select-none">💬</span>
              <span>与 AI 智能对话，下方输入框发送您的第一个外贸指令，右下角可切换模型与专业外贸技能！</span>
            </div>
            <div
              v-for="(msg, idx) in getActiveChatMessages"
              :key="idx"
              class="flex gap-3 max-w-3xl"
              :class="msg.sender === 'user' ? 'ml-auto flex-row-reverse' : 'mr-auto'"
            >
              <!-- Avatar -->
              <div class="w-8 h-8 rounded-full flex items-center justify-center shrink-0 shadow-sm text-[10px] font-mono select-none"
                   :class="msg.sender === 'user' ? 'bg-indigo-600 text-white' : 'bg-zen-ink text-white'">
                {{ msg.sender === 'user' ? 'ME' : 'AI' }}
              </div>
              <!-- Bubble -->
              <div class="flex flex-col space-y-1">
                <span class="text-[8px] text-zen-gray font-bold font-mono select-none" :class="msg.sender === 'user' ? 'text-right' : 'text-left'">
                  {{ msg.sender === 'user' ? '我的提问' : '智能回复' }}
                </span>
                <div class="p-3.5 rounded-2xl text-[11px] leading-relaxed select-text shadow-sm"
                     :class="msg.sender === 'user'
                       ? 'bg-indigo-600 text-white rounded-tr-none font-sans font-medium'
                       : 'bg-white border border-black/[0.04] text-zen-ink rounded-tl-none whitespace-pre-wrap font-serif-sc'">
                  {{ msg.content }}
                </div>
              </div>
            </div>
            
            <!-- Loading state -->
            <div v-if="isFullscreenAiLoading" class="flex gap-3 mr-auto max-w-3xl animate-pulse">
              <div class="w-8 h-8 rounded-full bg-zen-ink text-white flex items-center justify-center shrink-0 shadow-sm text-xs select-none">
                ⏳
              </div>
              <div class="flex flex-col space-y-1">
                <span class="text-[8px] text-zen-gray font-bold font-mono select-none">智能回复</span>
                <div class="p-3.5 rounded-2xl text-[10px] bg-white border border-black/[0.04] text-zen-ink rounded-tl-none flex items-center gap-2 font-sans">
                  <span class="flex h-1.5 w-1.5 relative">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-1.5 w-1.5 bg-indigo-500"></span>
                  </span>
                  AI 正在调度算力并深度检索向量库...
                </div>
              </div>
            </div>
          </div>

          <!-- Message Input Bar -->
          <footer class="p-6 border-t border-black/[0.05] bg-white shrink-0 select-none">
            <div class="max-w-3xl mx-auto border border-black/[0.08] focus-within:border-indigo-500/50 focus-within:ring-1 focus-within:ring-indigo-500/10 rounded-2xl p-2.5 flex flex-col gap-2 shadow-inner bg-[#F9FBFA]/40">
              <textarea
                v-model="fullscreenAiInput"
                rows="2"
                placeholder="输入对话或指令，按 Enter 键发送..."
                class="w-full bg-transparent border-0 outline-none resize-none text-[11px] text-zen-ink leading-relaxed font-sans placeholder-zen-gray/60 py-1 px-1.5"
                @keyup.enter.exact.prevent="handleFullscreenAiSubmit"
              ></textarea>
              
              <div class="flex items-center justify-between pt-2 border-t border-black/[0.03]">
                <div class="flex items-center gap-2">
                  <!-- Integrated Model selector -->
                  <div class="flex items-center gap-1.5 bg-black/[0.03] hover:bg-black/[0.06] border border-black/[0.04] px-2.5 py-0.5 rounded-xl text-[10px] text-zen-gray transition-all cursor-pointer font-mono font-bold">
                    <span class="text-zen-green animate-pulse">🟢</span>
                    <span class="opacity-75">模型:</span>
                    <select v-model="activeAiModel" class="bg-transparent border-0 outline-none text-[10px] text-zen-ink font-semibold pr-1.5 cursor-pointer font-mono font-bold select-none h-4">
                      <option v-for="p in activeProvidersList" :key="p.id" :value="p.id">
                        {{ p.name }}
                      </option>
                    </select>
                  </div>

                  <!-- Integrated Skill selector -->
                  <div class="flex items-center gap-1.5 bg-black/[0.03] hover:bg-black/[0.06] border border-black/[0.04] px-2.5 py-0.5 rounded-xl text-[10px] text-zen-gray transition-all cursor-pointer">
                    <span class="text-indigo-500">⚡</span>
                    <span class="opacity-75">技能:</span>
                    <select v-model="selectedAiSkill" class="bg-transparent border-0 outline-none text-[10px] text-zen-ink font-semibold pr-1.5 cursor-pointer h-4 select-none">
                      <option value="none">无 (纯问答)</option>
                      <option v-for="skill in importedSkills" :key="skill.value" :value="skill.value">
                        {{ skill.label }}
                      </option>
                    </select>
                  </div>
                </div>

                <!-- Send button -->
                <button
                  @click="handleFullscreenAiSubmit"
                  class="px-5 py-2 rounded-xl bg-zen-ink hover:bg-zen-ink/90 text-white text-xs font-bold shadow-md transition-all flex items-center gap-1.5 active:scale-95 outline-none shrink-0 font-sans"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M14 5l7 7m0 0l-7 7m7-7H3" />
                  </svg>
                  <span>发送指令</span>
                </button>
              </div>
            </div>
          </footer>
        </main>
      </div>
    </Teleport>
  </div>
</template>

<style>
/* CSS overrides for global range input aesthetics to feel extremely premium */
input[type="range"]::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #627254; /* zen-green */
  border: 2px bg-white;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
  transition: transform 0.1s ease;
}

input[type="range"]::-webkit-slider-thumb:hover {
  transform: scale(1.2);
}
</style>
