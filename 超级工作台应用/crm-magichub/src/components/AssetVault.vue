<script setup>
import { computed, onMounted, ref, watch } from "vue";
import {
  CATEGORIES,
  TWO_FACTOR_OPTIONS,
  cardFields,
  categoryTabs,
  copyTextForField,
  fileRecord,
  filterAccounts,
  generatePassword,
  parseCSV,
  patchHasValue,
  splitRecord,
} from "../lib/assetVault.js";

defineOptions({ inheritAttrs: false });

const accounts = ref([]);
const query = ref("");
const category = ref("全部");
const message = ref("密码和 API 密钥只在 Mac 应用里复制。这个页面可以复制账号、邮箱和登录地址，不会显示密钥。");
const unavailable = ref(false);
const showForm = ref(false);
const generated = ref("");
const generatedVisible = ref(false);
const nativeVault = ref(false);
const copiedKey = ref("");
let copyTimer = 0;

const blank = () => ({
  id: "",
  platform: "",
  category: "电商",
  loginURL: "",
  username: "",
  email: "",
  notes: "",
  twoFactor: "none",
  tags: "",
  company: "",
  brand: "",
  password: "",
  apiKey: "",
  recoveryCodes: "",
});

const form = ref(blank());

const categories = computed(() => categoryTabs(accounts.value));

const formCategories = computed(() => {
  const current = String(form.value.category || "").trim();
  if (current && !CATEGORIES.includes(current)) return [...CATEGORIES, current];
  return CATEGORIES;
});

const visible = computed(() => filterAccounts(accounts.value, { query: query.value, category: category.value }));

watch(categories, (tabs) => {
  if (!tabs.includes(category.value)) category.value = "全部";
});

function api() {
  return typeof window !== "undefined" ? window.electronAPI : null;
}

onMounted(async () => {
  nativeVault.value = api()?.platform === "darwin" && typeof api()?.saveAsset === "function";
  await reload();
});

async function reload() {
  const bridge = api();
  try {
    if (bridge?.listAssets) {
      const result = await bridge.listAssets();
      accounts.value = result?.accounts || [];
      unavailable.value = false;
      return;
    }
    const response = await fetch("/api/assets", { credentials: "same-origin", cache: "no-store" });
    if (!response.ok) throw new Error("no api");
    const result = await response.json();
    accounts.value = result.accounts || [];
    unavailable.value = false;
  } catch {
    accounts.value = [];
    unavailable.value = true;
    message.value = "这里读不到本机档案。请在 Mac「超级工作台」里打开资产管理；网页不会把密码存进浏览器。";
  }
}

function openNew() {
  form.value = blank();
  showForm.value = true;
}

function openEdit(account) {
  form.value = {
    ...blank(),
    ...account,
    tags: (account.tags || []).join(", "),
    email: account.email || "",
    password: "",
    apiKey: "",
    recoveryCodes: "",
  };
  showForm.value = true;
}

function payloadFromForm() {
  const draft = { ...form.value };
  for (const key of ["password", "apiKey", "recoveryCodes"]) {
    if (!String(draft[key] || "").trim()) delete draft[key];
  }
  return splitRecord(draft);
}

async function save() {
  let split;
  try {
    split = payloadFromForm();
  } catch {
    message.value = "请填写平台名称";
    return;
  }
  const bridge = api();
  const hasSecret = patchHasValue(split.patch);
  try {
    if (nativeVault.value && bridge?.saveAsset) {
      const result = await bridge.saveAsset({ ...fileRecord(split.account), ...split.patch });
      if (!result?.success) throw new Error(result?.error || "保存失败");
      message.value = hasSecret ? "档案已保存，密钥已写入钥匙串，页面上不再保留。" : "档案已保存。";
    } else if (!unavailable.value) {
      const response = await fetch("/api/assets", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ account: fileRecord(split.account) }),
      });
      const result = await response.json();
      if (!result?.success) throw new Error(result?.error || "保存失败");
      message.value = hasSecret
        ? "档案已保存。密码没有写入文件，请到 Mac 超级工作台里再存进钥匙串。"
        : "档案已保存。这个网页不能保存密码。";
    } else {
      message.value = "当前环境不能写入本机档案。";
      return;
    }
    form.value = blank();
    showForm.value = false;
    await reload();
  } catch (error) {
    message.value = error?.message || "保存失败";
  }
}

async function remove(account) {
  if (!window.confirm(`删除「${account.platform}」？钥匙串里的对应密码也会在 Mac 应用里一并删除。`)) return;
  const bridge = api();
  if (nativeVault.value && bridge?.deleteAsset) {
    await bridge.deleteAsset(account.id);
  } else {
    await fetch(`/api/assets?id=${encodeURIComponent(account.id)}`, { method: "DELETE", credentials: "same-origin" });
  }
  await reload();
}

function openLogin(account) {
  if (!account.loginURL) return;
  window.open(account.loginURL, "_blank", "noopener");
}

function makePassword() {
  generated.value = generatePassword({ length: 20 });
  generatedVisible.value = false;
  if (showForm.value && nativeVault.value) {
    form.value.password = generated.value;
  }
}

async function copyGenerated() {
  if (!generated.value) return;
  try {
    await navigator.clipboard.writeText(generated.value);
    const copied = generated.value;
    message.value = "已复制生成的密码。若浏览器允许读取剪贴板，大约 45 秒后会清掉。";
    setTimeout(async () => {
      try {
        const current = await navigator.clipboard.readText();
        if (current === copied) await navigator.clipboard.writeText("");
      } catch {
        /* 浏览器不允许回读剪贴板时，不覆盖用户后来复制的内容。 */
      }
    }, 45000);
  } catch {
    message.value = "浏览器没有允许写入剪贴板。";
  }
}

async function importFile(event) {
  const file = event.target.files && event.target.files[0];
  event.target.value = "";
  if (!file) return;
  const text = await file.text();
  const bridge = api();
  if (nativeVault.value && bridge?.importAssetsCsv) {
    const result = await bridge.importAssetsCsv(text);
    message.value = `导入 ${result?.imported || 0} 条，密钥写入钥匙串 ${result?.secretsStored || 0} 条。`;
    await reload();
    return;
  }
  const parsed = parseCSV(text);
  let imported = 0;
  let dropped = 0;
  for (const row of parsed.rows) {
    if (patchHasValue(row.patch)) dropped += 1;
    if (unavailable.value) continue;
    const response = await fetch("/api/assets", {
      method: "POST",
      credentials: "same-origin",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ account: fileRecord(row.account) }),
    });
    const result = await response.json();
    if (result?.success) imported += 1;
  }
  message.value = unavailable.value
    ? "网页不能导入到本机。请在 Mac 超级工作台里导入，密码才会进钥匙串。"
    : `导入 ${imported} 条档案。已丢弃 ${dropped} 条里的密码，没有写进文件。`;
  if (!unavailable.value) await reload();
}

function factorLabel(id) {
  return TWO_FACTOR_OPTIONS.find((item) => item.id === id)?.label || "无";
}

const FIELD_ICONS = {
  person: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="8" cy="5.5" r="2.2"/><path d="M3.2 13.2c.7-2.2 2.4-3.3 4.8-3.3s4.1 1.1 4.8 3.3"/></svg>',
  envelope: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="2.2" y="4" width="11.6" height="8" rx="1.2"/><path d="M3 5l5 3.4L13 5"/></svg>',
  key: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="6" cy="8" r="2.3"/><path d="M8 8h6M12 8v2"/></svg>',
  api: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 4L2.8 8 6 12M10 4l3.2 4L10 12"/></svg>',
  link: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M7 9l2-2"/><path d="M6.2 6.2l-1.2-1.2a2.2 2.2 0 013.1-3.1L9.3 3"/><path d="M9.8 9.8l1.2 1.2a2.2 2.2 0 01-3.1 3.1L6.7 13"/></svg>',
};

function fieldsFor(account) {
  return cardFields(account);
}

function iconSvg(name) {
  return FIELD_ICONS[name] || FIELD_ICONS.person;
}

async function copyField(account, field) {
  const text = copyTextForField(field);
  if (!text) return;
  try {
    await navigator.clipboard.writeText(text);
    const token = `${account.id}:${field.id}`;
    copiedKey.value = token;
    message.value = "已复制";
    window.clearTimeout(copyTimer);
    copyTimer = window.setTimeout(() => {
      if (copiedKey.value === token) copiedKey.value = "";
    }, 1600);
  } catch {
    message.value = "浏览器没有允许写入剪贴板。";
  }
}
</script>

<template>
  <div class="space-y-5 text-zen-ink">
    <div class="apple-glass rounded-2xl p-6">
      <h2 class="text-lg font-bold font-serif-sc">资产管理</h2>
      <p class="text-[12px] text-zen-gray mt-2 leading-relaxed">{{ message }}</p>
      <div class="flex flex-wrap gap-2 mt-4">
        <input v-model="query" class="flex-1 min-w-[180px] rounded-xl border border-black/10 bg-white px-3 py-2 text-sm" placeholder="搜索平台、账号、邮箱、备注、标签" />
        <button type="button" class="px-3 py-2 rounded-xl bg-zen-ink text-white text-sm" @click="openNew">新建</button>
        <label class="px-3 py-2 rounded-xl border border-black/10 text-sm cursor-pointer bg-white">
          导入 CSV
          <input type="file" accept=".csv,text/csv" class="hidden" @change="importFile" />
        </label>
      </div>
      <div class="flex flex-wrap gap-2 mt-3">
        <button
          v-for="item in categories"
          :key="item"
          type="button"
          class="px-3 py-1.5 rounded-full text-sm border"
          :class="category === item ? 'bg-zen-ink text-white border-zen-ink' : 'bg-white border-black/10 text-zen-ink'"
          @click="category = item"
        >{{ item }}</button>
      </div>
    </div>

    <div v-if="showForm" class="apple-glass rounded-2xl p-6 space-y-3">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <label class="text-xs">平台<input v-model="form.platform" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
        <label class="text-xs">分类
          <select v-model="form.category" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm bg-white">
            <option v-for="item in formCategories" :key="item" :value="item">{{ item }}</option>
          </select>
        </label>
        <label class="text-xs">登录地址<input v-model="form.loginURL" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm bg-white" placeholder="https://" /></label>
        <label class="text-xs">账号<input v-model="form.username" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm bg-white" /></label>
        <label class="text-xs">邮箱<input v-model="form.email" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm bg-white" placeholder="可选" /></label>
        <label class="text-xs">二次验证
          <select v-model="form.twoFactor" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm">
            <option v-for="item in TWO_FACTOR_OPTIONS" :key="item.id" :value="item.id">{{ item.label }}</option>
          </select>
        </label>
        <label class="text-xs">标签<input v-model="form.tags" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" placeholder="用逗号分隔" /></label>
        <label class="text-xs">公司<input v-model="form.company" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
        <label class="text-xs">品牌<input v-model="form.brand" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
      </div>
      <label class="text-xs block">备注<textarea v-model="form.notes" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" rows="2" placeholder="不要在备注里写密码"></textarea></label>
      <div v-if="nativeVault" class="grid grid-cols-1 md:grid-cols-3 gap-3">
        <label class="text-xs">密码（只写入钥匙串）<input v-model="form.password" type="password" autocomplete="new-password" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
        <label class="text-xs">API 密钥<input v-model="form.apiKey" type="password" autocomplete="off" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
        <label class="text-xs">恢复码<input v-model="form.recoveryCodes" type="password" autocomplete="off" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
      </div>
      <p v-else class="text-[12px] text-zen-gray">浏览器里不能保存密码。要写入钥匙串，请用 Mac 超级工作台。</p>
      <div class="flex gap-2">
        <button type="button" class="px-3 py-2 rounded-xl bg-zen-ink text-white text-sm" @click="save">保存</button>
        <button type="button" class="px-3 py-2 rounded-xl border border-black/10 text-sm" @click="showForm = false">取消</button>
      </div>
    </div>

    <div class="apple-glass rounded-2xl p-6">
      <div class="flex flex-wrap items-center gap-2">
        <h3 class="text-sm font-bold">密码生成器</h3>
        <button type="button" class="px-3 py-1.5 rounded-xl border border-black/10 text-xs" @click="makePassword">生成</button>
        <button type="button" class="px-3 py-1.5 rounded-xl border border-black/10 text-xs" @click="generatedVisible = !generatedVisible">{{ generatedVisible ? "隐藏" : "显示" }}</button>
        <button type="button" class="px-3 py-1.5 rounded-xl border border-black/10 text-xs" @click="copyGenerated">复制</button>
      </div>
      <input :type="generatedVisible ? 'text' : 'password'" :value="generated" readonly class="mt-3 w-full rounded-xl border border-black/10 px-3 py-2 text-sm font-mono" placeholder="生成结果只留在本页，不会写入文件" />
    </div>

    <div v-if="!visible.length" class="apple-glass rounded-2xl p-6 text-sm text-zen-gray">没有符合筛选的账号。</div>
    <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <article v-for="account in visible" :key="account.id" class="apple-glass rounded-2xl p-5 bg-white/80 flex flex-col gap-3">
        <div class="flex items-start justify-between gap-2">
          <h3 class="font-bold leading-snug">{{ account.platform }}</h3>
          <span class="shrink-0 text-[11px] px-2 py-0.5 rounded-full bg-black/5 text-zen-gray">{{ account.category }}</span>
        </div>
        <div v-if="account.hasSecret || (account.twoFactor && account.twoFactor !== 'none')" class="flex flex-wrap items-center gap-2 text-[11px] text-zen-gray">
          <span v-if="account.hasSecret" class="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800">钥匙串</span>
          <span v-if="account.twoFactor && account.twoFactor !== 'none'">{{ factorLabel(account.twoFactor) }}</span>
        </div>
        <div class="space-y-1.5">
          <div v-for="field in fieldsFor(account)" :key="field.id" class="flex items-center gap-2 rounded-xl bg-black/[0.03] px-3 py-2">
            <span class="shrink-0 text-zen-gray" v-html="iconSvg(field.icon)"></span>
            <button
              v-if="!field.secret"
              type="button"
              class="flex-1 min-w-0 flex items-center gap-2 text-left"
              @click="copyField(account, field)"
            >
              <span class="w-16 shrink-0 text-[12px] text-zen-gray">{{ field.label }}</span>
              <span class="flex-1 min-w-0 truncate text-sm">{{ field.value }}</span>
              <span class="shrink-0 text-[12px]" :class="copiedKey === account.id + ':' + field.id ? 'text-emerald-700 font-semibold' : 'text-zen-gray'">
                {{ copiedKey === account.id + ':' + field.id ? "已复制" : "复制" }}
              </span>
            </button>
            <div v-else class="flex-1 min-w-0 flex items-center gap-2">
              <span class="w-16 shrink-0 text-[12px] text-zen-gray">{{ field.label }}</span>
              <span class="flex-1 min-w-0 text-sm text-zen-gray">{{ field.hint }}</span>
            </div>
            <button v-if="field.id === 'loginURL'" type="button" class="shrink-0 text-[12px] underline" @click="openLogin(account)">打开</button>
          </div>
        </div>
        <p v-if="account.notes" class="text-xs text-zen-gray line-clamp-2">{{ account.notes }}</p>
        <div class="flex gap-3 mt-auto">
          <button type="button" class="text-xs underline" @click="openEdit(account)">编辑</button>
          <button type="button" class="text-xs underline" @click="remove(account)">删除</button>
        </div>
      </article>
    </div>
  </div>
</template>
