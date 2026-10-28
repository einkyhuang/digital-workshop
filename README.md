# 数字工坊（digital-workshop）

所有 Bot、项目和工作台的数据都统一放在这个文件夹里。

## 目录结构
```
app/            工作台网页（index.html，双击就能打开；也是 GitHub Pages 的站点）
  data/         给网页读取的数据副本（sync.sh 会自动从 data/ 复制过来）
data/           主数据 workspace.json（Bot、任务、群聊、定时任务、招聘、规则）
bots/<名字>/    每个 Bot 一个文件夹：profile.md（职责/工具/测试用例）+ deliverables/ 交付物
projects/       每个项目一个文件夹（看板、服装客户开发……）
scripts/sync.sh 云端与本地同步脚本
mac-app/        数字工坊.app（Mac 启动器）
```

## 打开方式
- 公网：GitHub Pages 网址（见仓库 Settings → Pages）
- 本地：双击 `app/index.html`，或者打开 `数字工坊.app`

## 同步（云端 = GitHub 仓库，本地 = git clone）
1. 第一次使用：`git clone https://github.com/einkyhuang/digital-workshop.git ~/数字工坊`
2. 在网页上改完内容后，点「导出 JSON」，用导出的文件覆盖 `data/workspace.json`
3. 运行 `./scripts/sync.sh`（先拉取，再提交，再推送）
4. Bot 的交付物直接写进 `bots/<名字>/deliverables/`，然后同样运行 sync.sh

注意：仓库里不要放任何 Token、密码或 API Key。
