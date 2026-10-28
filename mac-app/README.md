# 数字工坊.app（未签名）

## 安装
1. 把仓库放到 `~/数字工坊`（`git clone … ~/数字工坊`）
2. 把 `数字工坊.app` 拖到「应用程序」或 Dock
3. **第一次打开**：右键 → 打开（未签名，系统会拦截双击）

## 行为
启动器会打开本地的 `app/index.html`（优先 `~/数字工坊/app/index.html`）。

可选无边框窗口：
```bash
DIGITAL_WORKSHOP_CHROME_APP=1 open -a 数字工坊
# 或
数字工坊.app/Contents/MacOS/launcher --app
```
