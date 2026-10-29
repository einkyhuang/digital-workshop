# 印花产品图库

来源：企业微信微盘公开分享  
链接：https://drive.weixin.qq.com/s?k=AMgAqAdCAAoxkvZIpz  
分享人：庄耀骏 @广州展发纺织

## 本地同步

```bash
/home/box/tools/wedrive-sync.mjs
```

- 图片落到 `images/`（已 gitignore，不进公开仓库）
- 只提交 `manifest.json`（文件名、大小、数量、同步时间）
- 幂等：同名同大小跳过

## 当前限制（2026-10-29 探测）

该分享的 `auth_type=2`，页面文案为「Permission set for the folder. Log in to view.」。  
**未登录无法列出或下载任何文件。** 需分享方改为「任何人可查看/下载」，或人工登录后另做会话同步。

## 到 Mac 的路径

Mac 上的超级工作台是 git clone：`git pull` 只会拿到 `manifest.json`，拿不到 `images/`。可选：

1. 分享改为公开后，在 Mac 上跑同一脚本（或 CopyFromBox 把 box 上的 `images/` 拷过去）
2. 用户在企业微信里手动下载/导出后放进本目录 `images/`
