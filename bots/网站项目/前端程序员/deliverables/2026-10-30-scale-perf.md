# 超级工作台 · 启动与大规模可扩展优化

时间：2026-10-30（Asia/Shanghai）

## 瓶颈（优化前）
1. **ContentView 外层 ScrollView 包住网站项目页** → 内层 `LazyVStack`/`LazyVGrid` 失效，200 项目会一次全部物化。
2. **缺少索引**：员工按组过滤、项目负责人查找、分类计数均为反复 O(n) 扫描。
3. **首屏等待辅助数据**：`loadAsync` 等 sqlite/邮件日报齐活才上屏（已部分异步，现改为 **core 先上屏**）。
4. **Web 网站列表一次 innerHTML 全量**；总览员工板全量拼接。

## 改动（视觉不变：卡片尺寸 / 分组 flow-wrap 保持）
### Mac
- `ContentView`：网站项目页不再套外层 ScrollView，懒加载生效。
- `WorkspaceStore`：`botById` / `botsByGroup` 索引；KPI 缓存；**分阶段加载**（core JSON 先 `isCoreLoaded`，辅助数据后台）。
- 压测夹具：仅 `/tmp/sw-stress-workspace.json` + `touch /tmp/sw-enable-stress` 或 `defaults SWStressFixture`（**不入库**）。
- Overview / Roster / Projects 使用索引；负责人查找走 `bot(id:)`。

### Web
- `rebuildIndexes()`；网站列表 **分页 40 +「加载更多」**（卡片 CSS 不变）。
- `?stress=1` 仅 localhost 叠加 `stress-workspace.local.json`（gitignore）。
- 脚本：`超级工作台应用/scripts/gen-stress-fixture.mjs` → 默认写 `/tmp`。

## 计时（冷启动 / 首窗）
| 场景 | 指标 | 结果 |
|--|--|--|
| Mac 基线（22 员工 / 53 项目） | 窗口出现 | **≈0.86s** |
| Mac 压测（100 / 200） | 窗口出现 | **≈0.71s**（分阶段加载，夹具合并后仍可快速出窗） |
| Web 资源串行 | index+js+css+json | **≈12ms**（本地） |
| Web 索引+首屏拼装 | 基线 / 压测 | **≈3ms / ≈5ms**（数据路径） |

## 压测说明
- 合成数据：100 员工 + 200 网站项目，假名「压测员工* / 压测站点*」，金额字段 null。
- 生成：`node 超级工作台应用/scripts/gen-stress-fixture.mjs`
- **未提交**任何 stress JSON 到公开 data。

## 截图
- Mac 基线：`bots/网站项目/前端程序员/deliverables/sw-scale-mac-baseline.png`
- Mac 压测：`bots/网站项目/前端程序员/deliverables/sw-scale-mac-stress.png`
- Web 基线：`bots/网站项目/前端程序员/deliverables/sw-scale-web-baseline.png`
- Web 压测：`bots/网站项目/前端程序员/deliverables/sw-scale-web-stress.png`
