/**
 * Local customer archives + knowledge files.
 * Markdown on disk is the source of truth. This module only merges lightweight
 * pointers into the in-memory lists and renders Markdown to HTML.
 * It does not draft, rewrite, or persist report bodies.
 *
 * Folder contract (under 超级工作台应用/data/private/, gitignored):
 *   客户档案/{照明|服装|布料}/客户/{公司名}/深度分析.md
 *   客户档案/{照明|服装|布料}/客户/{公司名}/30天营销规划.md
 *   知识库/{产品参数|行业动态|开发采购|营销话术|业务技能}/{标题}.md
 * HTML siblings (深度分析.html 等) are ignored.
 */

export const CUSTOMER_CATEGORY_FOLDERS = {
  照明: { id: 'lights', label: '照明' },
  服装: { id: 'apparel', label: '服装' },
  布料: { id: 'fabric', label: '布料' },
  汽配: { id: 'parts', label: '汽配' },
  lights: { id: 'lights', label: '照明' },
  apparel: { id: 'apparel', label: '服装' },
  fabric: { id: 'fabric', label: '布料' },
  parts: { id: 'parts', label: '汽配' },
};

export const CATEGORY_LABELS = {
  parts: '汽配',
  lights: '照明',
  apparel: '服装',
  fabric: '布料',
};

export const KNOWLEDGE_FOLDERS = {
  产品: 'products',
  产品参数: 'products',
  products: 'products',
  行业: 'industry',
  行业动态: 'industry',
  industry: 'industry',
  开发: 'sourcing',
  开发采购: 'sourcing',
  采购: 'sourcing',
  sourcing: 'sourcing',
  营销: 'marketing',
  营销话术: 'marketing',
  marketing: 'marketing',
  技能: 'skills',
  业务技能: 'skills',
  skills: 'skills',
};

export const KNOWLEDGE_LABELS = {
  products: '产品参数',
  industry: '行业动态',
  sourcing: '开发采购',
  marketing: '营销话术',
  skills: '业务技能',
};

const LIVE_DOC_SPECS = [
  ['analysis', '深度分析', 'analysis'],
  ['plan', '30天营销规划', 'plan'],
  ['profile', '客户档案', 'profile'],
  ['followup', '跟进记录', 'followup'],
];

const EPHEMERAL_LEAD_KEYS = [
  'archiveBacked',
  'archiveOnly',
  'archiveKey',
  'archiveFolder',
  'archiveFiles',
  'archiveUpdatedAt',
  'archiveCategory',
  'archiveCategoryLabel',
  'libraryIndex',
];

export function customerCategory(folderName) {
  return CUSTOMER_CATEGORY_FOLDERS[folderName] || { id: folderName, label: folderName };
}

export function knowledgeCategoryFromFolder(folderName) {
  if (!folderName) return { id: 'industry', label: KNOWLEDGE_LABELS.industry };
  const mapped = KNOWLEDGE_FOLDERS[folderName];
  if (mapped) return { id: mapped, label: KNOWLEDGE_LABELS[mapped] || mapped };
  return { id: folderName, label: folderName };
}

export function categoryLabel(id, fallback = '') {
  if (!id) return fallback;
  return CATEGORY_LABELS[id] || fallback || id;
}

export function effectiveCategory(lead) {
  if (!lead) return '';
  return lead.archiveCategory || lead.category || '';
}

export function normalizeCompanyName(name) {
  return String(name || '')
    .normalize('NFKC')
    .toLowerCase()
    .replace(/[\s\u3000._\-/\\|,，.。'"“”‘’()（）[\]【】]+/g, '');
}

export function isArchiveOnlyLead(lead) {
  if (!lead || typeof lead !== 'object') return false;
  if (lead.archiveOnly === true) return true;
  return typeof lead.id === 'string' && lead.id.startsWith('archive:');
}

export function isArchiveKnowledge(item) {
  if (!item || typeof item !== 'object') return false;
  if (item.source === 'archive-file') return true;
  return typeof item.id === 'string' && item.id.startsWith('kbfile:');
}

const FLAGS = {
  德国: '🇩🇪',
  美国: '🇺🇸',
  日本: '🇯🇵',
  阿联酋: '🇦🇪',
  泰国: '🇹🇭',
  法国: '🇫🇷',
  英国: '🇬🇧',
  意大利: '🇮🇹',
  西班牙: '🇪🇸',
  韩国: '🇰🇷',
  印度: '🇮🇳',
  越南: '🇻🇳',
  新加坡: '🇸🇬',
  澳大利亚: '🇦🇺',
  加拿大: '🇨🇦',
  巴西: '🇧🇷',
  土耳其: '🇹🇷',
  沙特: '🇸🇦',
  菲律宾: '🇵🇭',
  荷兰: '🇳🇱',
  俄罗斯: '🇷🇺',
};

export function flagForCountry(country) {
  const text = String(country || '');
  for (const [name, flag] of Object.entries(FLAGS)) {
    if (text.includes(name)) return flag;
  }
  return '🌐';
}

export function splitFrontmatter(markdown) {
  const raw = String(markdown || '').replace(/^\uFEFF/, '');
  if (!raw.startsWith('---')) return { meta: {}, body: raw };
  const end = raw.indexOf('\n---', 3);
  if (end < 0) return { meta: {}, body: raw };
  const block = raw.slice(3, end).replace(/^\n/, '');
  const body = raw.slice(end + 4).replace(/^\n/, '');
  const meta = {};
  for (const line of block.split('\n')) {
    const matched = line.match(/^([A-Za-z0-9_\-\u4e00-\u9fff]+)\s*:\s*(.*)$/);
    if (!matched) continue;
    meta[matched[1].trim()] = matched[2].trim().replace(/^["']|["']$/g, '');
  }
  return { meta, body };
}

export function parseProfileFields(markdown) {
  const text = String(markdown || '');
  const fields = {};
  for (const line of text.split('\n')) {
    if (line.includes('|')) {
      const cells = line.split('|').map((cell) => cell.trim()).filter(Boolean);
      if (cells.length >= 2 && !/^:?-+:?$/.test(cells[0])) fields[cells[0]] = cells[1];
    }
    const bullet = line.match(/^[-*]\s*(.+?)\s*[:：]\s*(.+)$/);
    if (bullet && !fields[bullet[1].trim()]) fields[bullet[1].trim()] = bullet[2].trim();
  }
  const country = fields['国家/地区'] || fields['国家'] || fields['地区'] || '';
  const contact = fields['关键人姓名/职位'] || fields['关键人'] || fields['联系人'] || '';
  const phone = fields['电话'] || '';
  const email = fields['邮箱'] || '';
  let score = null;
  const starSource = fields['星级'] || '';
  const starMatch = String(starSource || text).match(/星级[：:\s]*\**\s*(\d+(?:\.\d+)?)/) || (starSource && String(starSource).match(/(\d+(?:\.\d+)?)/));
  if (starMatch) {
    const n = Number(starMatch[1]);
    if (Number.isFinite(n)) score = Math.max(0, Math.min(100, Math.round(n <= 5 ? n * 20 : n)));
  }
  return { country, contact, phone, email, score };
}

export function markdownPreview(markdown, limit = 180) {
  const { body } = splitFrontmatter(markdown);
  const plain = body
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/[#>*_`|[\]()\-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return plain.slice(0, limit);
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function inlineMarkdown(escaped) {
  let html = escaped.replace(/`([^`]+)`/g, '<code>$1</code>');
  html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  html = html.replace(/(^|[^*])\*([^*\n]+)\*/g, '$1<em>$2</em>');
  html = html.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_match, text, url) => {
    const safe = /^(https?:|mailto:|#|\/)/i.test(url) ? url : '#';
    return `<a href="${safe}" target="_blank" rel="noopener noreferrer">${text}</a>`;
  });
  return html;
}

function renderTable(rows) {
  const parsed = rows
    .map((row) => row.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((cell) => cell.trim()))
    .filter((cells) => cells.length && !cells.every((cell) => /^:?-+:?$/.test(cell)));
  if (!parsed.length) return '';
  const head = parsed[0].map((cell) => `<th>${inlineMarkdown(escapeHtml(cell))}</th>`).join('');
  const body = parsed.slice(1).map((row) => `<tr>${row.map((cell) => `<td>${inlineMarkdown(escapeHtml(cell))}</td>`).join('')}</tr>`).join('');
  return `<table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>`;
}

/** Markdown in, structured HTML out. Raw HTML in the source is escaped, never executed. */
export function markdownToHtml(markdown) {
  const { body } = splitFrontmatter(markdown);
  const lines = String(body || '').replace(/\r\n/g, '\n').split('\n');
  const html = [];
  const paragraph = [];
  let index = 0;

  const flushParagraph = () => {
    if (!paragraph.length) return;
    const text = paragraph.join('\n');
    paragraph.length = 0;
    html.push(`<p>${inlineMarkdown(escapeHtml(text)).replace(/\n/g, '<br>')}</p>`);
  };

  while (index < lines.length) {
    const line = lines[index];
    if (line.startsWith('```')) {
      flushParagraph();
      const buf = [];
      index += 1;
      while (index < lines.length && !lines[index].startsWith('```')) {
        buf.push(lines[index]);
        index += 1;
      }
      if (index < lines.length) index += 1;
      html.push(`<pre><code>${escapeHtml(buf.join('\n'))}</code></pre>`);
      continue;
    }
    if (!line.trim()) {
      flushParagraph();
      index += 1;
      continue;
    }
    if (/^(\*\*\*|---|___)\s*$/.test(line.trim())) {
      flushParagraph();
      html.push('<hr>');
      index += 1;
      continue;
    }
    const heading = line.match(/^(#{1,4})\s+(.*)$/);
    if (heading) {
      flushParagraph();
      const level = heading[1].length;
      html.push(`<h${level}>${inlineMarkdown(escapeHtml(heading[2]))}</h${level}>`);
      index += 1;
      continue;
    }
    if (line.startsWith('>')) {
      flushParagraph();
      const buf = [];
      while (index < lines.length && lines[index].startsWith('>')) {
        buf.push(lines[index].replace(/^>\s?/, ''));
        index += 1;
      }
      html.push(`<blockquote>${inlineMarkdown(escapeHtml(buf.join('\n'))).replace(/\n/g, '<br>')}</blockquote>`);
      continue;
    }
    if (/^\s*\|/.test(line)) {
      flushParagraph();
      const rows = [];
      while (index < lines.length && /^\s*\|/.test(lines[index])) {
        rows.push(lines[index]);
        index += 1;
      }
      const table = renderTable(rows);
      if (table) html.push(table);
      continue;
    }
    if (/^\s*[-*]\s+/.test(line)) {
      flushParagraph();
      const items = [];
      while (index < lines.length && /^\s*[-*]\s+/.test(lines[index])) {
        items.push(lines[index].replace(/^\s*[-*]\s+/, ''));
        index += 1;
      }
      html.push(`<ul>${items.map((item) => `<li>${inlineMarkdown(escapeHtml(item))}</li>`).join('')}</ul>`);
      continue;
    }
    if (/^\s*\d+[.)]\s+/.test(line)) {
      flushParagraph();
      const items = [];
      while (index < lines.length && /^\s*\d+[.)]\s+/.test(lines[index])) {
        items.push(lines[index].replace(/^\s*\d+[.)]\s+/, ''));
        index += 1;
      }
      html.push(`<ol>${items.map((item) => `<li>${inlineMarkdown(escapeHtml(item))}</li>`).join('')}</ol>`);
      continue;
    }
    paragraph.push(line);
    index += 1;
  }
  flushParagraph();
  return html.join('\n');
}

export function leadFromArchive(meta) {
  const category = meta.category || 'lights';
  const label = meta.categoryLabel || categoryLabel(category);
  const score = Number.isFinite(meta.score) ? meta.score : 75;
  const tags = ['客户档案'];
  if (label) tags.push(label);
  if (meta.files?.analysis) tags.push('深度分析');
  if (meta.files?.plan) tags.push('30天规划');
  const archiveKey = meta.archiveKey || `${category}/${meta.name || ''}`;
  return {
    id: meta.id || `archive:${encodeURIComponent(archiveKey)}`,
    name: meta.name,
    contact: meta.contact || '见客户档案',
    phone: meta.phone || '',
    email: meta.email || '',
    country: meta.country || '未注明',
    flag: flagForCountry(meta.country),
    score,
    category,
    stage: 'potential',
    tags,
    routingPath: '本地客户档案',
    rawMessage: `来自本地客户档案（${label}）。打开客户时从 Markdown 读取深度分析和 30 天营销规划。`,
    archiveBacked: true,
    archiveOnly: true,
    archiveKey,
    archiveFolder: meta.folder || '',
    archiveFiles: meta.files || {},
    archiveUpdatedAt: meta.updatedAt || '',
    archiveCategory: category,
    archiveCategoryLabel: label,
  };
}

function overlayArchive(lead, meta) {
  lead.archiveBacked = true;
  lead.archiveOnly = false;
  lead.archiveKey = meta.archiveKey;
  lead.archiveFolder = meta.folder || '';
  lead.archiveFiles = meta.files || {};
  lead.archiveUpdatedAt = meta.updatedAt || '';
  lead.archiveCategory = meta.category || lead.category;
  lead.archiveCategoryLabel = meta.categoryLabel || categoryLabel(lead.archiveCategory);
}

/**
 * Pin archive customers at the front. Match an existing library lead by company
 * name instead of inserting a second card. Does not copy report bodies.
 */
export function mergeLeadsWithArchives(leads, archives) {
  const incoming = Array.isArray(leads) ? leads : [];
  const library = [];
  for (const lead of incoming) {
    if (!lead || typeof lead !== 'object') continue;
    if (isArchiveOnlyLead(lead)) continue;
    library.push({ ...lead });
  }
  library.forEach((lead, index) => {
    if (!Number.isInteger(lead.libraryIndex)) lead.libraryIndex = index;
  });

  const byName = new Map();
  for (const lead of library) {
    const key = normalizeCompanyName(lead.name);
    if (key && !byName.has(key)) byName.set(key, lead);
  }

  const pinned = [];
  const pinnedIds = new Set();
  const sorted = [...(archives || [])].sort((a, b) => String(b.updatedAt || '').localeCompare(String(a.updatedAt || '')));
  for (const meta of sorted) {
    if (!meta || !meta.name) continue;
    const existing = byName.get(normalizeCompanyName(meta.name));
    if (existing) {
      if (pinnedIds.has(existing.id)) continue;
      overlayArchive(existing, meta);
      pinned.push(existing);
      pinnedIds.add(existing.id);
      continue;
    }
    const created = leadFromArchive(meta);
    if (pinnedIds.has(created.id)) continue;
    pinned.push(created);
    pinnedIds.add(created.id);
  }
  const rest = library.filter((lead) => !pinnedIds.has(lead.id));
  return [...pinned, ...rest];
}

/** Drop archive-only cards and live pointers. Restore the library's original order. */
export function persistableLeads(leads) {
  if (!Array.isArray(leads)) return leads;
  const library = [];
  const appended = [];
  for (const lead of leads) {
    if (!lead || typeof lead !== 'object') continue;
    if (isArchiveOnlyLead(lead)) continue;
    const index = Number.isInteger(lead.libraryIndex) ? lead.libraryIndex : null;
    const copy = { ...lead };
    for (const key of EPHEMERAL_LEAD_KEYS) delete copy[key];
    if (copy.deepReport?.liveFromArchive) delete copy.deepReport;
    if (copy.marketingPlan?.liveFromArchive) delete copy.marketingPlan;
    if (index === null) appended.push(copy);
    else library.push({ index, lead: copy });
  }
  library.sort((a, b) => a.index - b.index);
  return [...library.map((entry) => entry.lead), ...appended];
}

export function mergeKnowledge(saved, fileItems) {
  const base = saved && typeof saved === 'object' && !Array.isArray(saved) ? saved : {};
  const out = {};
  for (const [key, value] of Object.entries(base)) {
    out[key] = Array.isArray(value) ? value.filter((item) => !isArchiveKnowledge(item)) : value;
  }
  const groups = new Map();
  for (const item of fileItems || []) {
    if (!item || !item.category) continue;
    const copy = { ...item, source: 'archive-file' };
    if (!groups.has(item.category)) groups.set(item.category, []);
    groups.get(item.category).push(copy);
  }
  for (const [category, items] of groups) {
    items.sort((a, b) => String(b.updatedAt || b.date || '').localeCompare(String(a.updatedAt || a.date || '')));
    const existing = Array.isArray(out[category]) ? out[category] : [];
    out[category] = [...items, ...existing];
  }
  return out;
}

export function persistableKnowledge(data) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return data;
  const out = {};
  for (const [key, value] of Object.entries(data)) {
    if (!Array.isArray(value)) {
      out[key] = value;
      continue;
    }
    out[key] = value.filter((item) => !isArchiveKnowledge(item)).map((item) => {
      const copy = { ...item };
      delete copy.filePath;
      delete copy.source;
      delete copy.updatedAt;
      delete copy.preview;
      return copy;
    });
  }
  return out;
}

export async function buildLiveDocs(files, readText) {
  const docs = [];
  for (const [id, title, key] of LIVE_DOC_SPECS) {
    const filePath = files?.[key];
    if (!filePath || String(filePath).toLowerCase().endsWith('.html')) continue;
    let content = '';
    let error = '';
    try {
      content = await readText(filePath);
    } catch (err) {
      error = err?.message || String(err);
    }
    docs.push({
      id,
      title,
      filename: String(filePath).split(/[/\\]/).pop(),
      html: content ? markdownToHtml(content) : '',
      error,
    });
  }
  return docs;
}
