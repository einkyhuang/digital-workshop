# 书库 · 知识蒸馏为 Skills

把书本、网页、视频里的可执行知识，提炼成其他 bot / IDE 工具可调用的 `SKILL.md`。

## 目录

| 路径 | 用途 |
|------|------|
| `待蒸馏/` | 放入待处理的书本（pdf/epub/mobi/azw3/txt/docx） |
| `待蒸馏/视频/` | 本地视频文件（mp4/mkv/webm/mov 等） |
| `链接清单.md` | 网页 URL、YouTube 链接排队（一行一条，可加备注） |
| `已蒸馏/` | 处理完成后，原书/原视频移入此处（不删除） |
| `样例skill/` | 试蒸馏产出的草稿 skill |
| `蒸馏记录.md` | 每条蒸馏的书名/链接、章节数、skill 路径、日期 |
| `_work/` | 临时文本/字幕，不入库 |

## 流程

1. 用户把书放入 `待蒸馏/`，或把链接写入 `链接清单.md`，或把视频放入 `待蒸馏/视频/`
2. Bot「蒸馏师-书本转技能」用便宜模型逐章/逐段提炼方法、步骤、清单、判据、示例
3. 用较强模型合成一份 `SKILL.md`（YAML frontmatter + 适用场景 / 核心原则 / 可执行步骤 / 检查清单 / 提示词模板 / 常见错误 / 出处）
4. Skill 草稿写入共享 skills 目录（试跑阶段写入 `样例skill/`）；原件移到 `已蒸馏/`
5. 在 `蒸馏记录.md` 追加一行

## 按来源的读取方法与限制

| 来源 | 读取方式 | 限制 |
|------|----------|------|
| PDF（文字层） | `pdftotext` | 扫描版无文字层时需 OCR（tesseract）；当前 box 可能未装 tesseract |
| EPUB/MOBI | `ebooklib` 解包 HTML，或 `ebook-convert`（需 Calibre） | DRM / 空壳 iBooks 占位文件（0 字节）无法读 |
| DOCX/TXT | pandoc 或直接读 | pandoc 可能未装；纯文本最稳 |
| 网页链接 | `requests` + readability/html2text | **登录墙 / 付费墙**抓不到正文；反爬可能拦截 |
| YouTube | `yt-dlp` 拉字幕或音频 → `faster-whisper` 转写 | **无字幕**时必须 whisper，慢且吃 CPU；地区锁/私密视频会失败 |
| 本地视频 | `ffmpeg` 抽音频 → `faster-whisper` | 长视频耗时长；无声/音乐轨几乎无文本可提炼 |

## 工具状态（box）

见最近一次检查记录；安装优先用 `/workspace/.distill-venv`。

## 安全

- **书本/视频/音频/字幕原文不进公开 Git**：见根目录与本目录 `.gitignore`
- 蒸馏产出的 skill **不得大段照抄原文**（单段引用不超过两句），只保留方法与结构
- 永不打印 API Key
