# 数字工坊（digital-workshop）

所有 Bot、项目和工作台的数据统一放在本文件夹。

## 公网预览
**https://einkyhuang.github.io/digital-workshop/**

> **注意：本仓库为公开（Public）。**  
> 免费 GitHub 账号无法给私有仓库开 Pages，所以改成了公开。  
> 仓库里只有 Bot 岗位职责、测试用买家公开信息、开发信草稿，**没有** API Key / Token / 密码。  
> 不要把密钥写进本仓库。若以后需要私密部署，请升级 GitHub Pro 再改回私有，或换私有静态托管。

仓库：https://github.com/einkyhuang/digital-workshop

## 目录结构
```
app/                 工作台网页（双击 index.html 本地打开；也是 Pages 站点根）
  assets/            CSS / JS
  data/workspace.json  网页读取的数据副本
data/workspace.json  主数据（Bot / 任务 / 群聊 / 巡检 / 招聘 / 规则）
bots/<名字>/         每个真实 Bot 一文件夹：profile.md + deliverables/
projects/看板/       本工作台项目说明
projects/服装客户开发/  群聊测试项目说明
scripts/sync.sh      云端 ↔ 本地同步
mac-app/数字工坊.app  Mac 启动器（未签名）
```

## 本地打开
1. `git clone https://github.com/einkyhuang/digital-workshop.git ~/数字工坊`
2. 双击 `~/数字工坊/app/index.html`，或打开 `mac-app/数字工坊.app`
3. **Mac App 第一次打开**：右键 → 打开（未签名）

## 同步
云端 = GitHub 仓库；本地 = git clone。

1. 在网页上改完 →「导出 JSON」→ 覆盖 `data/workspace.json`
2. 运行：`./scripts/sync.sh`（pull --rebase → add → commit → push）
3. Bot 交付物直接写入 `bots/<名字>/deliverables/` 后同样 sync

`sync.sh` 会把 `data/workspace.json` 复制到 `app/data/`，保证 Pages 与本地一致。
