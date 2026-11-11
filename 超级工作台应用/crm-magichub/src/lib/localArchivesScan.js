/**
 * Node scanner for the folder contract in localArchives.js.
 * Used by tests and the LAN server. The Mac app scans in Swift.
 */
import fs from 'fs';
import path from 'path';
import {
  customerCategory,
  knowledgeCategoryFromFolder,
  parseProfileFields,
  markdownPreview,
  splitFrontmatter,
  KNOWLEDGE_LABELS,
} from './localArchives.js';

export const CUSTOMER_MARKDOWN = {
  '档案.md': 'profile',
  '深度分析.md': 'analysis',
  '30天营销规划.md': 'plan',
  '跟进记录.md': 'followup',
};

const SKIP_KNOWLEDGE_NAMES = new Set(['归档规则.md', 'README.md', 'readme.md']);

function safeStat(filePath) {
  try {
    return fs.statSync(filePath);
  } catch {
    return null;
  }
}

function insideRoot(rootReal, candidate) {
  const stat = safeStat(candidate);
  if (!stat) return null;
  try {
    const real = fs.realpathSync(candidate);
    if (real !== rootReal && !real.startsWith(rootReal + path.sep)) return null;
    return stat;
  } catch {
    return null;
  }
}

export function scanCustomerArchives(rootDir, { limit = 500 } = {}) {
  const rootStat = safeStat(rootDir);
  if (!rootStat?.isDirectory()) return [];
  let rootReal;
  try {
    rootReal = fs.realpathSync(rootDir);
  } catch {
    return [];
  }
  const archives = [];
  let categories = [];
  try {
    categories = fs.readdirSync(rootDir);
  } catch {
    return [];
  }
  for (const categoryName of categories) {
    if (!categoryName || categoryName.startsWith('.')) continue;
    const categoryPath = path.join(rootDir, categoryName);
    if (!insideRoot(rootReal, categoryPath)?.isDirectory()) continue;
    const customersPath = path.join(categoryPath, '客户');
    if (!insideRoot(rootReal, customersPath)?.isDirectory()) continue;
    const category = customerCategory(categoryName);
    let companies = [];
    try {
      companies = fs.readdirSync(customersPath);
    } catch {
      continue;
    }
    for (const company of companies) {
      if (!company || company.startsWith('.')) continue;
      if (archives.length >= limit) return archives;
      const folder = path.join(customersPath, company);
      const folderStat = insideRoot(rootReal, folder);
      if (!folderStat?.isDirectory()) continue;
      let names = [];
      try {
        names = fs.readdirSync(folder);
      } catch {
        continue;
      }
      const files = {};
      let updatedMs = folderStat.mtimeMs || 0;
      const profileBits = {};
      for (const name of names) {
        const role = CUSTOMER_MARKDOWN[name];
        if (!role) continue;
        const filePath = path.join(folder, name);
        const fileStat = insideRoot(rootReal, filePath);
        if (!fileStat?.isFile()) continue;
        files[role] = filePath;
        if (fileStat.mtimeMs > updatedMs) updatedMs = fileStat.mtimeMs;
        if (role === 'profile' && fileStat.size <= 256 * 1024) {
          try {
            Object.assign(profileBits, parseProfileFields(fs.readFileSync(filePath, 'utf8')));
          } catch {
            /* profile is optional */
          }
        }
      }
      if (!Object.keys(files).length) continue;
      const archiveKey = `${category.id}/${company}`;
      archives.push({
        archiveKey,
        id: `archive:${encodeURIComponent(archiveKey)}`,
        name: company,
        category: category.id,
        categoryLabel: category.label,
        folder,
        updatedAt: new Date(updatedMs).toISOString(),
        country: profileBits.country || '',
        contact: profileBits.contact || '',
        phone: profileBits.phone || '',
        email: profileBits.email || '',
        ...(Number.isFinite(profileBits.score) ? { score: profileBits.score } : {}),
        files,
      });
    }
  }
  archives.sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)));
  return archives;
}

export function knowledgeCategoryFromPath(folderName) {
  return knowledgeCategoryFromFolder(folderName);
}

function walkMarkdown(dir, rootReal, out, limit) {
  if (out.length >= limit) return;
  let names = [];
  try {
    names = fs.readdirSync(dir);
  } catch {
    return;
  }
  for (const name of names) {
    if (out.length >= limit) return;
    if (!name || name.startsWith('.')) continue;
    const full = path.join(dir, name);
    const stat = insideRoot(rootReal, full);
    if (!stat) continue;
    if (stat.isDirectory()) {
      walkMarkdown(full, rootReal, out, limit);
      continue;
    }
    if (!stat.isFile() || !name.toLowerCase().endsWith('.md')) continue;
    if (SKIP_KNOWLEDGE_NAMES.has(name)) continue;
    out.push(full);
  }
}

export function scanKnowledgeFiles(rootDir, { limit = 500 } = {}) {
  const rootStat = safeStat(rootDir);
  if (!rootStat?.isDirectory()) return [];
  let rootReal;
  try {
    rootReal = fs.realpathSync(rootDir);
  } catch {
    return [];
  }
  const files = [];
  walkMarkdown(rootDir, rootReal, files, limit);
  const items = [];
  for (const filePath of files) {
    let text = '';
    let stat;
    try {
      stat = fs.statSync(filePath);
      text = fs.readFileSync(filePath, 'utf8');
    } catch {
      continue;
    }
    const relative = path.relative(rootDir, filePath).split(path.sep).join('/');
    const parts = relative.split('/');
    const folderName = parts.length > 1 ? parts[0] : '';
    const mapped = knowledgeCategoryFromFolder(folderName);
    const { meta, body } = splitFrontmatter(text);
    const override = meta.category || meta.分类;
    const category = override
      ? (knowledgeCategoryFromFolder(override).id || override)
      : mapped.id;
    const label = KNOWLEDGE_LABELS[category] || mapped.label || category;
    const heading = (body.match(/^#{1,3}\s+(.+)$/m) || [])[1];
    const title = meta.title || meta.标题 || heading || path.basename(filePath, '.md');
    const date = (meta.date || meta.日期 || '').slice(0, 10) || new Date(stat.mtimeMs).toISOString().slice(0, 10);
    items.push({
      id: `kbfile:${encodeURIComponent(relative)}`,
      title,
      category,
      categoryLabel: label,
      date,
      content: markdownPreview(text),
      preview: markdownPreview(text),
      filePath,
      source: 'archive-file',
      updatedAt: new Date(stat.mtimeMs).toISOString(),
    });
  }
  items.sort((a, b) => String(b.updatedAt).localeCompare(String(a.updatedAt)));
  return items;
}

export function isAllowedLocalText(repoRoot, filePath) {
  if (!filePath || typeof filePath !== 'string') return false;
  const resolved = path.resolve(filePath);
  if (!resolved.toLowerCase().endsWith('.md')) return false;
  const roots = [
    path.join(repoRoot, '超级工作台应用/data/private/客户档案'),
    path.join(repoRoot, '超级工作台应用/data/private/知识库'),
  ];
  return roots.some((root) => {
    const base = path.resolve(root);
    return resolved === base || resolved.startsWith(base + path.sep);
  });
}
