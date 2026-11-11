<script setup>
import { computed, onMounted, ref } from "vue";
import {
  CATEGORIES,
  TWO_FACTOR_OPTIONS,
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
const message = ref("密码、API 密钥和恢复码只进 Mac 钥匙串。这个页面不保存密钥，也不能一次读出全部密码。");
const unavailable = ref(false);
const showForm = ref(false);
const generated = ref("");
const generatedVisible = ref(false);
const nativeVault = ref(false);

const blank = () => ({
  id: "",
  platform: "",
  category: "电商",
  loginURL: "",
  username: "",
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

const categories = computed(() => {
  const extras = accounts.value.map((item) => item.category).filter((item) => item && !CATEGORIES.includes(item));
  return ["全部", ...CATEGORIES, ...new Set(extras)];
});

const visible = computed(() => filterAccounts(accounts.value, { query: query.value, category: category.value }));

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
</script>

<template>
  <div class="space-y-5 text-zen-ink">
    <div class="apple-glass rounded-2xl p-6">
      <h2 class="text-lg font-bold font-serif-sc">资产管理</h2>
      <p class="text-[12px] text-zen-gray mt-2 leading-relaxed">{{ message }}</p>
      <div class="flex flex-wrap gap-2 mt-4">
        <input v-model="query" class="flex-1 min-w-[180px] rounded-xl border border-black/10 px-3 py-2 text-sm" placeholder="搜索平台、用户名、备注、标签" />
        <select v-model="category" class="rounded-xl border border-black/10 px-3 py-2 text-sm">
          <option v-for="item in categories" :key="item" :value="item">{{ item }}</option>
        </select>
        <button type="button" class="px-3 py-2 rounded-xl bg-zen-ink text-white text-sm" @click="openNew">新建</button>
        <label class="px-3 py-2 rounded-xl border border-black/10 text-sm cursor-pointer">
          导入 CSV
          <input type="file" accept=".csv,text/csv" class="hidden" @change="importFile" />
        </label>
      </div>
    </div>

    <div v-if="showForm" class="apple-glass rounded-2xl p-6 space-y-3">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <label class="text-xs">平台<input v-model="form.platform" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
        <label class="text-xs">分类
          <select v-model="form.category" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm">
            <option v-for="item in CATEGORIES" :key="item" :value="item">{{ item }}</option>
          </select>
        </label>
        <label class="text-xs">登录地址<input v-model="form.loginURL" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" placeholder="https://" /></label>
        <label class="text-xs">用户名<input v-model="form.username" class="mt-1 w-full rounded-xl border border-black/10 px-3 py-2 text-sm" /></label>
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

    <div v-if="!visible.length" class="apple-glass rounded-2xl p-6 text-sm text-zen-gray">没有账号。新建一条，或把 Markdown 旁边的 JSON 放到本机 private/资产管理/ 后刷新。</div>
    <article v-for="account in visible" :key="account.id" class="apple-glass rounded-2xl p-5">
      <div class="flex flex-wrap items-center gap-2">
        <h3 class="font-bold">{{ account.platform }}</h3>
        <span class="text-[11px] px-2 py-0.5 rounded-full bg-black/5">{{ account.category }}</span>
        <span v-if="account.hasSecret" class="text-[11px] px-2 py-0.5 rounded-full bg-emerald-100">钥匙串</span>
        <span class="text-[11px] text-zen-gray">{{ factorLabel(account.twoFactor) }}</span>
      </div>
      <p class="text-sm mt-2">{{ account.username }}</p>
      <p v-if="account.notes" class="text-xs text-zen-gray mt-1">{{ account.notes }}</p>
      <div class="flex gap-2 mt-3">
        <button v-if="account.loginURL" type="button" class="text-xs underline" @click="openLogin(account)">打开登录页</button>
        <button type="button" class="text-xs underline" @click="openEdit(account)">编辑</button>
        <button type="button" class="text-xs underline" @click="remove(account)">删除</button>
      </div>
    </article>
  </div>
</template>
