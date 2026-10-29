#!/usr/bin/env node
/**
 * 超级工作台 · LAN-only server (home Wi-Fi)
 * - Bind 0.0.0.0 but REJECT non-RFC1918 / non-loopback clients
 * - Passcode gate + httpOnly session cookie
 * - Serves 超级工作台应用/app + authenticated private CRM/settings
 * - Does NOT touch Desktop 超级工作台.app
 *
 * Env:
 *   SW_LAN_PORT (default 8787)
 *   SW_LAN_HOST (default 0.0.0.0)
 *   SW_LAN_REPO  absolute path to repo root (iCloud 超级工作台)
 *   SW_LAN_PASSCODE_FILE  override passcode path
 */
import http from "http";
import https from "https";
import fs from "fs";
import path from "path";
import crypto from "crypto";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.SW_LAN_PORT || 8787);
const HOST = process.env.SW_LAN_HOST || "0.0.0.0";

function detectRepo() {
  if (process.env.SW_LAN_REPO) return process.env.SW_LAN_REPO;
  // lan/ -> 超级工作台应用 -> repo
  return path.resolve(__dirname, "../..");
}
const REPO = detectRepo();
const APP_ROOT = path.join(REPO, "超级工作台应用/app");
const PRIVATE_ROOT = path.join(REPO, "超级工作台应用/data/private");
const LAN_DIR = path.join(PRIVATE_ROOT, "lan");
const PASS_FILE =
  process.env.SW_LAN_PASSCODE_FILE || path.join(LAN_DIR, "passcode");
const SECRET_FILE = path.join(LAN_DIR, "session-secret");
const COOKIE = "sw_lan_sess";
const SESSION_TTL_MS = 7 * 24 * 3600 * 1000;

function ensureLanSecrets() {
  fs.mkdirSync(LAN_DIR, { recursive: true });
  if (!fs.existsSync(PASS_FILE)) {
    const code = crypto.randomBytes(4).toString("hex"); // 8 hex chars
    fs.writeFileSync(PASS_FILE, code + "\n", { mode: 0o600 });
    try { fs.chmodSync(PASS_FILE, 0o600); } catch (_) {}
  } else {
    try { fs.chmodSync(PASS_FILE, 0o600); } catch (_) {}
  }
  if (!fs.existsSync(SECRET_FILE)) {
    fs.writeFileSync(SECRET_FILE, crypto.randomBytes(32).toString("hex") + "\n", {
      mode: 0o600,
    });
    try { fs.chmodSync(SECRET_FILE, 0o600); } catch (_) {}
  }
}

function readPasscode() {
  return fs.readFileSync(PASS_FILE, "utf8").trim();
}
function readSecret() {
  return fs.readFileSync(SECRET_FILE, "utf8").trim();
}

function isRfc1918OrLocal(ip) {
  let x = String(ip || "").replace(/^::ffff:/, "");
  if (x === "::1" || x === "127.0.0.1") return true;
  // IPv6 unique local fc00::/7 — allow for completeness
  if (x.startsWith("fc") || x.startsWith("fd") || x.startsWith("fe80:")) return true;
  const m = x.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
  if (!m) return false;
  const a = +m[1], b = +m[2];
  if (a === 10) return true;
  if (a === 192 && b === 168) return true;
  if (a === 172 && b >= 16 && b <= 31) return true;
  if (a === 127) return true;
  return false;
}

function clientIp(req) {
  // Do NOT trust X-Forwarded-For (no tunnels); socket only
  return req.socket.remoteAddress || "";
}

function parseCookies(req) {
  const h = req.headers.cookie || "";
  const out = {};
  h.split(";").forEach((p) => {
    const i = p.indexOf("=");
    if (i < 0) return;
    out[p.slice(0, i).trim()] = decodeURIComponent(p.slice(i + 1).trim());
  });
  return out;
}

function sign(payload, secret) {
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  const sig = crypto.createHmac("sha256", secret).update(body).digest("base64url");
  return body + "." + sig;
}
function verify(token, secret) {
  if (!token || !token.includes(".")) return null;
  const [body, sig] = token.split(".");
  const expect = crypto.createHmac("sha256", secret).update(body).digest("base64url");
  const a = Buffer.from(sig);
  const b = Buffer.from(expect);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  try {
    const data = JSON.parse(Buffer.from(body, "base64url").toString("utf8"));
    if (!data || !data.exp || Date.now() > data.exp) return null;
    return data;
  } catch {
    return null;
  }
}

function timingSafeEqualStr(a, b) {
  const ba = Buffer.from(String(a));
  const bb = Buffer.from(String(b));
  if (ba.length !== bb.length) {
    crypto.timingSafeEqual(ba, ba); // burn
    return false;
  }
  return crypto.timingSafeEqual(ba, bb);
}

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".webmanifest": "application/manifest+json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".gif": "image/gif",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".webp": "image/webp",
  ".woff2": "font/woff2",
  ".map": "application/json",
  ".md": "text/markdown; charset=utf-8",
  ".txt": "text/plain; charset=utf-8",
  ".pdf": "application/pdf",
};

function safeJoin(root, rel) {
  const cleaned = path.normalize(rel).replace(/^(\.\.(\/|\\|$))+/, "");
  const full = path.resolve(root, cleaned);
  if (!full.startsWith(path.resolve(root))) return null;
  return full;
}

function send(res, code, body, headers = {}) {
  const buf = Buffer.isBuffer(body) ? body : Buffer.from(body || "");
  res.writeHead(code, {
    "Content-Length": buf.length,
    "Cache-Control": "no-store",
    "X-Content-Type-Options": "nosniff",
    ...headers,
  });
  res.end(buf);
}

function loginPage(err) {
  return `<!DOCTYPE html><html lang="zh-Hans"><head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"/>
<meta name="apple-mobile-web-app-capable" content="yes"/>
<meta name="apple-mobile-web-app-title" content="超级工作台"/>
<meta name="theme-color" content="#111"/>
<title>登录 · 超级工作台 LAN</title>
<style>
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#f5f5f7;margin:0;display:flex;min-height:100vh;align-items:center;justify-content:center;padding:24px}
.card{background:#fff;border-radius:16px;padding:28px 24px;max-width:360px;width:100%;box-shadow:0 8px 30px rgba(0,0,0,.08)}
h1{font-size:20px;margin:0 0 6px}p{color:#666;font-size:13px;margin:0 0 18px;line-height:1.5}
input{width:100%;box-sizing:border-box;font-size:18px;padding:14px 12px;border-radius:12px;border:1px solid #ddd;margin-bottom:12px}
button{width:100%;font-size:16px;padding:14px;border:0;border-radius:12px;background:#111;color:#fff;font-weight:600}
.err{color:#b00020;font-size:13px;margin-bottom:10px}
.note{font-size:11px;color:#999;margin-top:14px}
</style></head><body><div class="card">
<h1>超级工作台 · 局域网</h1>
<p>仅家庭 Wi‑Fi（RFC1918）。口令存在本机私钥文件，不进 git。</p>
${err ? `<div class="err">${err}</div>` : ""}
<form method="POST" action="/login" autocomplete="current-password">
<input type="password" name="passcode" inputmode="text" placeholder="访问口令" required autofocus/>
<button type="submit">进入</button>
</form>
<p class="note">登录后可「分享 → 添加到主屏幕」。请勿端口转发或暴露到公网。</p>
</div></body></html>`;
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on("data", (c) => chunks.push(c));
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}

ensureLanSecrets();
const SECRET = readSecret();

const server = http.createServer(async (req, res) => {
  const ip = clientIp(req);
  if (!isRfc1918OrLocal(ip)) {
    send(res, 403, "Forbidden: non-private client IP\n", {
      "Content-Type": "text/plain; charset=utf-8",
    });
    return;
  }

  const url = new URL(req.url || "/", `http://${req.headers.host || "localhost"}`);
  const cookies = parseCookies(req);
  const sess = verify(cookies[COOKIE], SECRET);
  const authed = !!sess;

  // health (authed not required, still RFC1918-only)
  if (url.pathname === "/lan-health") {
    send(res, 200, JSON.stringify({ ok: true, lan: true, authed }), {
      "Content-Type": "application/json",
    });
    return;
  }

  if (url.pathname === "/login" && req.method === "GET") {
    if (authed) {
      res.writeHead(302, { Location: "/" });
      res.end();
      return;
    }
    send(res, 200, loginPage(""), { "Content-Type": "text/html; charset=utf-8" });
    return;
  }

  if (url.pathname === "/login" && req.method === "POST") {
    const raw = await readBody(req);
    const params = new URLSearchParams(raw.toString("utf8"));
    const got = params.get("passcode") || "";
    const want = readPasscode();
    if (!timingSafeEqualStr(got, want)) {
      send(res, 401, loginPage("口令不正确"), {
        "Content-Type": "text/html; charset=utf-8",
      });
      return;
    }
    const token = sign({ v: 1, exp: Date.now() + SESSION_TTL_MS }, SECRET);
    res.writeHead(302, {
      Location: "/",
      "Set-Cookie": `${COOKIE}=${encodeURIComponent(token)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${Math.floor(SESSION_TTL_MS / 1000)}`,
    });
    res.end();
    return;
  }

  if (url.pathname === "/logout") {
    res.writeHead(302, {
      Location: "/login",
      "Set-Cookie": `${COOKIE}=; Path=/; HttpOnly; Max-Age=0`,
    });
    res.end();
    return;
  }

  if (!authed) {
    if (url.pathname.startsWith("/api/")) {
      send(res, 401, JSON.stringify({ error: "login required" }), {
        "Content-Type": "application/json",
      });
      return;
    }
    res.writeHead(302, { Location: "/login" });
    res.end();
    return;
  }

  // Magichub settings API → private/crm/settings
  if (url.pathname.startsWith("/api/mh/settings/")) {
    const key = decodeURIComponent(url.pathname.slice("/api/mh/settings/".length));
    if (!/^[a-zA-Z0-9._-]+$/.test(key)) {
      send(res, 400, JSON.stringify({ error: "bad key" }), {
        "Content-Type": "application/json",
      });
      return;
    }
    const settingsDir = path.join(PRIVATE_ROOT, "crm/settings");
    fs.mkdirSync(settingsDir, { recursive: true });
    const fp = path.join(settingsDir, `magichub_${key}.json`);
    if (req.method === "GET") {
      if (!fs.existsSync(fp)) {
        send(res, 200, JSON.stringify({ success: true, data: null }), {
          "Content-Type": "application/json",
        });
        return;
      }
      const data = JSON.parse(fs.readFileSync(fp, "utf8"));
      send(res, 200, JSON.stringify({ success: true, data }), {
        "Content-Type": "application/json",
      });
      return;
    }
    if (req.method === "PUT" || req.method === "POST") {
      const raw = await readBody(req);
      let parsed;
      try {
        parsed = JSON.parse(raw.toString("utf8"));
      } catch {
        send(res, 400, JSON.stringify({ success: false, error: "invalid json" }), {
          "Content-Type": "application/json",
        });
        return;
      }
      const data = parsed && Object.prototype.hasOwnProperty.call(parsed, "data") ? parsed.data : parsed;
      // atomic write
      const tmp = fp + ".tmp";
      fs.writeFileSync(tmp, JSON.stringify(data, null, 2));
      fs.renameSync(tmp, fp);
      send(res, 200, JSON.stringify({ success: true }), {
        "Content-Type": "application/json",
      });
      return;
    }
    send(res, 405, "Method Not Allowed\n");
    return;
  }

  // Any file under data/private (authenticated + path traversal safe)
  if (url.pathname.startsWith("/private-data/")) {
    const rel = url.pathname.slice("/private-data/".length);
    const full = safeJoin(PRIVATE_ROOT, rel);
    if (!full || !fs.existsSync(full) || fs.statSync(full).isDirectory()) {
      send(res, 404, "Not Found\n");
      return;
    }
    const ext = path.extname(full).toLowerCase();
    send(res, 200, fs.readFileSync(full), {
      "Content-Type": MIME[ext] || "application/octet-stream",
    });
    return;
  }


  // Authenticated private tree (CRM assets)
  if (url.pathname.startsWith("/private-crm/")) {
    const rel = url.pathname.slice("/private-crm/".length);
    const full = safeJoin(path.join(PRIVATE_ROOT, "crm"), rel);
    if (!full || !fs.existsSync(full) || fs.statSync(full).isDirectory()) {
      send(res, 404, "Not Found\n");
      return;
    }
    const ext = path.extname(full).toLowerCase();
    send(res, 200, fs.readFileSync(full), {
      "Content-Type": MIME[ext] || "application/octet-stream",
    });
    return;
  }

  // Static app
  let rel = decodeURIComponent(url.pathname);
  if (rel === "/") rel = "/index.html";
  const full = safeJoin(APP_ROOT, "." + rel);
  if (!full || !fs.existsSync(full) || fs.statSync(full).isDirectory()) {
    send(res, 404, "Not Found\n", { "Content-Type": "text/plain; charset=utf-8" });
    return;
  }
  const ext = path.extname(full).toLowerCase();
  // Inject LAN bridge hint into magichub index if needed — served as-is; bridge-web patched separately
  send(res, 200, fs.readFileSync(full), {
    "Content-Type": MIME[ext] || "application/octet-stream",
  });
});

server.listen(PORT, HOST, () => {
  const passPath = PASS_FILE;
  console.log(
    JSON.stringify({
      event: "sw-lan-listen",
      host: HOST,
      port: PORT,
      repo: REPO,
      app: APP_ROOT,
      passcodeFile: passPath,
      note: "Passcode not logged. Clients must be RFC1918/loopback.",
    })
  );
});
