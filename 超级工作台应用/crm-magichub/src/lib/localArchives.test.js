import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import os from 'os';
import path from 'path';
import {
  mergeLeadsWithArchives,
  persistableLeads,
  mergeKnowledge,
  persistableKnowledge,
  markdownToHtml,
  buildLiveDocs,
  effectiveCategory,
} from './localArchives.js';
import { scanCustomerArchives, scanKnowledgeFiles } from './localArchivesScan.js';

function write(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text);
}

test('sample archive folders surface in front with markdown analysis attached', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'mh-archives-'));
  const lights = path.join(root, '客户档案', '照明', '客户', 'Fixture Lights Co');
  const apparel = path.join(root, '客户档案', '服装', '客户', 'Fixture Apparel Co');
  const fabric = path.join(root, '客户档案', '布料', '客户', 'Fixture Fabric Co');
  write(path.join(lights, '档案.md'), [
    '# Fixture Lights Co',
    '| 字段 | 内容 |',
    '| --- | --- |',
    '| 国家/地区 | 德国 |',
    '| 关键人姓名/职位 | Ada Fixture |',
    '| 电话 | +49 000 |',
    '',
    '- **星级：4**',
  ].join('\n'));
  const analysis = [
    '# 深度分析',
    '',
    '## 公司概况',
    '',
    '- 公司: Fixture Lights Co',
    '',
    '| 字段 | 内容 |',
    '| --- | --- |',
    '| 状态 | 夹具 |',
    '',
    '<script>alert(1)</script>',
  ].join('\n');
  const plan = ['# 30天营销规划', '', '1. 第 1 周核对规格', '', '2. 第 2 周寄样'].join('\n');
  write(path.join(lights, '深度分析.md'), analysis);
  write(path.join(lights, '30天营销规划.md'), plan);
  write(path.join(lights, '深度分析.html'), '<html><body>ignore me</body></html>');
  write(path.join(apparel, '深度分析.md'), '# 深度分析\n\n服装夹具条目\n');
  write(path.join(fabric, '30天营销规划.md'), '# 30天营销规划\n\n布料夹具条目\n');
  const touch = (file, iso) => {
    const when = new Date(iso);
    fs.utimesSync(file, when, when);
  };
  touch(path.join(apparel, '深度分析.md'), '2026-12-01T00:00:00Z');
  touch(path.join(lights, '深度分析.md'), '2026-11-01T00:00:00Z');
  touch(path.join(fabric, '30天营销规划.md'), '2026-10-01T00:00:00Z');

  const archives = scanCustomerArchives(path.join(root, '客户档案'));
  const names = archives.map((item) => item.name);
  assert.deepEqual(names.sort(), ['Fixture Apparel Co', 'Fixture Fabric Co', 'Fixture Lights Co']);
  const lightsMeta = archives.find((item) => item.name === 'Fixture Lights Co');
  assert.equal(lightsMeta.category, 'lights');
  assert.equal(lightsMeta.country, '德国');
  assert.equal(lightsMeta.contact, 'Ada Fixture');
  assert.equal(lightsMeta.score, 80);
  assert.ok(lightsMeta.files.analysis.endsWith('深度分析.md'));
  assert.ok(lightsMeta.files.plan.endsWith('30天营销规划.md'));
  assert.equal(lightsMeta.files.html, undefined);
  assert.equal(JSON.stringify(lightsMeta).includes('ignore me'), false);

  const apparelMeta = archives.find((item) => item.name === 'Fixture Apparel Co');
  const fabricMeta = archives.find((item) => item.name === 'Fixture Fabric Co');
  assert.equal(apparelMeta.category, 'apparel');
  assert.equal(fabricMeta.category, 'fabric');

  const library = [
    { id: 1, name: 'Alpha Parts', category: 'parts', stage: 'deal', tags: ['汽配'] },
    { id: 2, name: 'Fixture Lights Co', category: 'parts', stage: 'deal', tags: ['已有'], deepReport: { type: 'Markdown', content: '库内旧报告', filename: 'old.md' } },
    { id: 3, name: 'Omega End', category: 'lights', stage: 'potential', tags: [] },
  ];
  const merged = mergeLeadsWithArchives(library, archives);
  assert.equal(merged[0].name, 'Fixture Apparel Co');
  assert.ok(merged.slice(0, 3).every((lead) => lead.archiveBacked));
  assert.equal(merged.filter((lead) => lead.name === 'Fixture Lights Co').length, 1);
  const matched = merged.find((lead) => lead.id === 2);
  assert.equal(matched.archiveOnly, false);
  assert.equal(matched.category, 'parts');
  assert.equal(effectiveCategory(matched), 'lights');
  assert.equal(matched.deepReport.content, '库内旧报告');
  assert.ok(matched.archiveFiles.analysis);

  const apparelLead = merged.find((lead) => lead.name === 'Fixture Apparel Co');
  const fabricLead = merged.find((lead) => lead.name === 'Fixture Fabric Co');
  assert.equal(apparelLead.archiveOnly, true);
  assert.equal(apparelLead.category, 'apparel');
  assert.equal(fabricLead.category, 'fabric');
  assert.equal(String(apparelLead.id).startsWith('archive:'), true);

  const docs = await buildLiveDocs(lightsMeta.files, (filePath) => fs.readFileSync(filePath, 'utf8'));
  assert.deepEqual(docs.map((doc) => doc.id), ['analysis', 'plan', 'profile']);
  const analysisDoc = docs.find((doc) => doc.id === 'analysis');
  const planDoc = docs.find((doc) => doc.id === 'plan');
  assert.match(analysisDoc.html, /<h1>深度分析<\/h1>/);
  assert.match(analysisDoc.html, /<h2>公司概况<\/h2>/);
  assert.match(analysisDoc.html, /<table>/);
  assert.match(analysisDoc.html, /&lt;script&gt;alert\(1\)&lt;\/script&gt;/);
  assert.equal(analysisDoc.html.includes('<script>'), false);
  assert.match(planDoc.html, /<h1>30天营销规划<\/h1>/);
  assert.match(planDoc.html, /<ol>/);

  const saved = persistableLeads(merged);
  assert.deepEqual(saved.map((lead) => lead.id), [1, 2, 3]);
  assert.equal(saved[1].deepReport.content, '库内旧报告');
  assert.equal(saved[1].archiveFiles, undefined);
  assert.equal(saved[1].category, 'parts');
  assert.equal(JSON.stringify(saved).includes('深度分析'), false);
  assert.equal(JSON.stringify(saved).includes('archive:'), false);

  const again = mergeLeadsWithArchives(saved, archives);
  assert.equal(again.filter((lead) => lead.archiveBacked).length, 3);
  assert.deepEqual(persistableLeads(again).map((lead) => lead.id), [1, 2, 3]);

  const manual = [...merged, { id: 99, name: '手工新客', category: 'parts', stage: 'potential' }];
  assert.equal(persistableLeads(manual).at(-1).name, '手工新客');
});

test('knowledge markdown is merged in front and stripped on save', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'mh-kb-'));
  const kb = path.join(root, '知识库');
  write(path.join(kb, '产品参数', 'fixture-spec.md'), [
    '---',
    'title: 夹具规格',
    'date: 2026-11-01',
    '---',
    '',
    '# 夹具规格',
    '',
    '- 只读 Markdown',
    '',
    '<img src=x onerror=alert(1)>',
  ].join('\n'));
  write(path.join(kb, '产品参数', 'fixture-spec.html'), '<p>ignore</p>');
  write(path.join(kb, '展会笔记', 'booth.md'), '# 展会\n\n临时分类\n');

  const items = scanKnowledgeFiles(kb);
  assert.equal(items.some((item) => item.filePath.endsWith('.html')), false);
  const spec = items.find((item) => item.title === '夹具规格');
  assert.equal(spec.category, 'products');
  assert.equal(spec.source, 'archive-file');
  assert.match(spec.id, /^kbfile:/);
  const extra = items.find((item) => item.category === '展会笔记');
  assert.ok(extra);

  const saved = {
    products: [{ id: 'p1', title: '旧条目', content: '保留', date: '2026-05-01' }],
    industry: [],
  };
  const merged = mergeKnowledge(saved, items);
  assert.equal(merged.products[0].title, '夹具规格');
  assert.equal(merged.products[1].title, '旧条目');
  assert.equal(merged['展会笔记'][0].title, '展会');

  const html = markdownToHtml(fs.readFileSync(spec.filePath, 'utf8'));
  assert.match(html, /<h1>夹具规格<\/h1>/);
  assert.match(html, /<ul><li>只读 Markdown<\/li><\/ul>/);
  assert.match(html, /&lt;img/);
  assert.equal(html.includes('<img'), false);

  const persisted = persistableKnowledge(merged);
  assert.deepEqual(persisted.products.map((item) => item.id), ['p1']);
  assert.equal(persisted['展会笔记'].length, 0);
  assert.equal(JSON.stringify(persisted).includes('kbfile:'), false);

  const reloaded = mergeKnowledge(persisted, items);
  assert.equal(reloaded.products[0].id, spec.id);
  assert.equal(reloaded.products[1].id, 'p1');
});
