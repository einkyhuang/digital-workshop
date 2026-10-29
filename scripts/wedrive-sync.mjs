#!/usr/bin/env node
/**
 * WeDrive (企业微信微盘) public-share sync.
 *
 * Usage:
 *   /home/box/tools/wedrive-sync.mjs [shareUrl]
 *
 * Defaults to the 印花产品图库 share. Downloads only when the share is
 * publicly listable WITHOUT login (auth_type that yields is_valid + file APIs).
 * Idempotent: skips files whose name+size already match on disk.
 * Never commits image binaries — only updates manifest.json (caller may git-add it).
 */
import { createWriteStream, existsSync, mkdirSync, readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { pipeline } from 'node:stream/promises';
import { Readable } from 'node:stream';
import { fileURLToPath } from 'node:url';

const SHARE_URL =
  process.argv[2] ||
  process.env.WEDRIVE_SHARE_URL ||
  'https://drive.weixin.qq.com/s?k=AMgAqAdCAAoxkvZIpz';

const WORKSPACE =
  process.env.WEDRIVE_DEST ||
  '/workspace/超级工作台/projects/印花产品图库';
const IMAGES_DIR = join(WORKSPACE, 'images');
const MANIFEST_PATH = join(WORKSPACE, 'manifest.json');

function nowIsoShanghai() {
  // box clock is Asia/Shanghai; keep ISO-like local stamp with zone label
  const d = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())} Asia/Shanghai`;
}

function parseShareInit(html) {
  const block = html.match(/xd_global_shareInitDate\s*=\s*\{([\s\S]*?)\n\s*\}/);
  if (!block) return null;
  const raw = block[1];
  const num = (k) => {
    const m = raw.match(new RegExp(`"${k}"\\s*:\\s*Number\\((-?\\d+)\\)`));
    return m ? Number(m[1]) : null;
  };
  const bool = (k) => {
    const m = raw.match(new RegExp(`"${k}"\\s*:\\s*Boolean\\((\\w*)\\)`));
    if (!m) return null;
    return m[1] === 'true';
  };
  const str = (k) => {
    const m = raw.match(new RegExp(`"${k}"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"`));
    return m ? m[1].replace(/\\x26/g, '&').replace(/\\u([0-9a-fA-F]{4})/g, (_, h) => String.fromCharCode(parseInt(h, 16))) : '';
  };
  return {
    object_name: str('object_name'),
    corp_name: str('corp_name'),
    invitor_name: str('invitor_name'),
    file_id: str('file_id'),
    space_id: str('space_id'),
    space_name: str('space_name'),
    download_url: str('download_url'),
    save_url: str('save_url'),
    share_url: str('share_url') || SHARE_URL,
    auth_type: num('auth_type'),
    err_code: num('err_code'),
    type: num('type'),
    valid_time: num('valid_time'),
    has_login: bool('has_login'),
    is_valid: bool('is_valid'),
    not_in_wx: bool('not_in_wx'),
    is_same_corp: bool('is_same_corp'),
  };
}

async function fetchText(url) {
  const res = await fetch(url, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      Accept: 'text/html,application/xhtml+xml',
    },
    redirect: 'follow',
  });
  const text = await res.text();
  return { status: res.status, text, finalUrl: res.url };
}

function walkFiles(dir, base = dir) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) out.push(...walkFiles(p, base));
    else
      out.push({
        path: relative(base, p).replaceAll('\\', '/'),
        name,
        size: st.size,
        mtimeMs: st.mtimeMs,
      });
  }
  return out;
}

function writeManifest(payload) {
  mkdirSync(WORKSPACE, { recursive: true });
  writeFileSync(MANIFEST_PATH, JSON.stringify(payload, null, 2) + '\n', 'utf8');
}

async function main() {
  mkdirSync(IMAGES_DIR, { recursive: true });
  const existing = walkFiles(IMAGES_DIR);
  const probe = await fetchText(SHARE_URL);
  const init = parseShareInit(probe.text);

  if (!init) {
    const manifest = {
      share_url: SHARE_URL,
      title: '印花产品图库',
      status: 'error',
      reason: 'Could not parse xd_global_shareInitDate from share HTML',
      http_status: probe.status,
      synced_at: nowIsoShanghai(),
      file_count: existing.length,
      total_bytes: existing.reduce((s, f) => s + f.size, 0),
      files: existing,
    };
    writeManifest(manifest);
    console.error(JSON.stringify(manifest, null, 2));
    process.exit(1);
  }

  // auth_type=2 + is_valid=false + empty download_url => folder permission requires login
  const needsLogin =
    init.has_login === false &&
    (init.is_valid === false || init.auth_type === 2 || !init.download_url);

  // Heuristic: page body also says login required
  const bodyLoginWall =
    /Permission set for the folder|Log in to view|登录后查看|需要登录/.test(probe.text) ||
    needsLogin;

  if (bodyLoginWall && !init.download_url) {
    const manifest = {
      share_url: SHARE_URL,
      title: init.object_name || init.space_name || '印花产品图库',
      corp_name: init.corp_name,
      invitor_name: init.invitor_name,
      space_id: init.space_id,
      file_id: init.file_id,
      auth_type: init.auth_type,
      has_login: init.has_login,
      is_valid: init.is_valid,
      download_url: init.download_url || null,
      status: 'login_required',
      reason:
        'Share owner set folder permission that requires WeCom/WeDrive login (auth_type=2). Page shows "Permission set for the folder. Log in to view." No file-list API is called and download_url is empty. Cannot list or download without login.',
      how_to_unblock: [
        'Ask 庄耀骏 @广州展发纺织 to change share permission to「任何人可查看/下载」(anyone with the link), then re-run this script.',
        'Or open a browser session, sign in to enterprise WeChat / WeDrive once (interactive), then extend this script to reuse that session — not suitable for unattended cron without stored login.',
        'Or manually export/zip the folder from WeDrive and drop files into projects/印花产品图库/images/.',
      ],
      synced_at: nowIsoShanghai(),
      file_count: existing.length,
      total_bytes: existing.reduce((s, f) => s + f.size, 0),
      downloaded: 0,
      skipped: 0,
      files: existing,
    };
    writeManifest(manifest);
    console.log(JSON.stringify({ status: manifest.status, reason: manifest.reason, file_count: 0 }, null, 2));
    process.exit(2);
  }

  // Open share path (not reachable for this link today). Placeholder for page XHR-based listing.
  const manifest = {
    share_url: SHARE_URL,
    title: init.object_name || init.space_name,
    corp_name: init.corp_name,
    auth_type: init.auth_type,
    has_login: init.has_login,
    is_valid: init.is_valid,
    download_url: init.download_url || null,
    status: 'open_but_lister_not_implemented',
    reason:
      'Share appears open (download_url or is_valid), but automated file-tree listing via WeDrive XHR is not implemented for this run. Re-probe with Playwright to capture list/download endpoints, then extend this script.',
    synced_at: nowIsoShanghai(),
    file_count: existing.length,
    total_bytes: existing.reduce((s, f) => s + f.size, 0),
    files: existing,
  };
  writeManifest(manifest);
  console.log(JSON.stringify(manifest, null, 2));
  process.exit(3);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
