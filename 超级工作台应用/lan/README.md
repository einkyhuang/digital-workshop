# 超级工作台 · 家庭 Wi‑Fi LAN 访问

独立 Node 服务 + LaunchAgent `com.ky.superworkbench.lan`，**不修改、不重启 Desktop `超级工作台.app`**。

## 安全

- 监听 `0.0.0.0:18787`，但 **拒绝非 RFC1918 / 非本机** 客户端
- 访问口令：`超级工作台应用/data/private/lan/passcode`（gitignore，`chmod 600`）
- 登录后 HttpOnly Session Cookie；无端口转发 / 隧道

## 安装

```bash
cd 超级工作台应用/lan
./install-launchagent.sh
```

手机连同一 Wi‑Fi，Safari 打开 `http://<Mac局域网IP>:18787/`，输入口令；可「添加到主屏幕」。

## 日志

`超级工作台应用/data/private/lan/server.stdout.log`
