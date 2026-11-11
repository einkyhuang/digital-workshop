/**
 * 已登录的局域网接口。只收发明文元数据。
 * 请求里如果带了密码，会丢弃并在结果里标明 secretsDropped，不会写盘，也不会回显。
 */
import { assetRoot, deleteAccount, importCsv, listAccounts, saveAccount } from "./asset-vault-store.mjs";
import { redactAssetJsonText } from "../app/assets/asset-vault.mjs";

const MAX_BODY = 600_000;

export function redactPrivateAssetBody(rel, ext, bodyBuffer) {
  const parts = String(rel || "").split(/[/\\]/);
  if (!parts.includes("资产管理")) return null;
  if (String(ext || "").toLowerCase() !== ".json") return { status: 404, body: "" };
  return {
    status: 200,
    body: redactAssetJsonText(bodyBuffer.toString("utf8")),
    contentType: "application/json; charset=utf-8",
  };
}

export async function handleAssetVault(req, res, url, ctx) {
  if (url.pathname !== "/api/assets") return false;
  const root = assetRoot(ctx.privateRoot);
  const sendJSON = (status, payload) => {
    ctx.send(res, status, JSON.stringify(payload), { "Content-Type": "application/json; charset=utf-8" });
  };
  try {
    if (req.method === "GET") {
      sendJSON(200, {
        success: true,
        accounts: listAccounts(root),
        secretsAvailable: false,
        note: "密码只保存在 Mac 应用的钥匙串里，这个接口不返回密钥。",
      });
      return true;
    }
    if (req.method === "DELETE") {
      const id = url.searchParams.get("id") || "";
      const removed = deleteAccount(root, id);
      sendJSON(200, { success: true, removed });
      return true;
    }
    if (req.method === "POST") {
      const raw = await ctx.readBody(req);
      if (raw.length > MAX_BODY) {
        sendJSON(413, { success: false, error: "请求过大" });
        return true;
      }
      let parsed;
      try {
        parsed = JSON.parse(raw.toString("utf8") || "{}");
      } catch {
        sendJSON(400, { success: false, error: "无效的 JSON" });
        return true;
      }
      if (parsed && typeof parsed.csv === "string") {
        const result = importCsv(root, parsed.csv);
        sendJSON(200, {
          success: true,
          imported: result.imported,
          skipped: result.skipped,
          secretsDropped: result.secretsDropped,
          secretsStored: 0,
          errors: result.errors,
        });
        return true;
      }
      const input = parsed && parsed.account && typeof parsed.account === "object" ? parsed.account : parsed;
      const saved = saveAccount(root, input);
      sendJSON(200, {
        success: true,
        account: saved.account,
        secretsDropped: saved.secretsDropped,
        secretsStored: 0,
      });
      return true;
    }
    ctx.send(res, 405, "Method Not Allowed\n");
    return true;
  } catch (error) {
    const code = error && (error.code === "invalid-id" || error.code === "invalid-platform" || error.code === "path-escape") ? 400 : 500;
    sendJSON(code, { success: false, error: error.code === "invalid-id" ? "无效的条目 id" : error.code === "path-escape" ? "路径越界" : error.code === "invalid-platform" ? "缺少平台名称" : "没有写入" });
    return true;
  }
}
