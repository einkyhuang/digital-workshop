# 日程日文件格式（供各 Bot 写入）

路径约定（仓库根相对）：

```
超级工作台应用/data/schedule/YYYY-MM-DD.json
```

时区默认 `Asia/Shanghai`。工作台「任务与日程中心」**按月懒加载**该目录下当月文件。

## Schema

```json
{
  "version": 1,
  "date": "2026-10-30",
  "timezone": "Asia/Shanghai",
  "updatedAt": "2026-10-30T12:00:00+08:00",
  "tasks": [
    {
      "id": "t-unique",
      "title": "任务标题",
      "ownerBotId": "seo",
      "ownerName": "搜搜-SEO专家",
      "status": "进行中",
      "dueAt": "2026-10-30T18:00:00+08:00",
      "note": "可选备注（勿写客户真名/金额）"
    }
  ],
  "schedule": [
    {
      "id": "s-unique",
      "title": "日程标题",
      "startAt": "2026-10-30T09:00:00+08:00",
      "endAt": "2026-10-30T09:30:00+08:00",
      "who": "大可可-最强大脑",
      "kind": "meeting"
    }
  ],
  "meta": {
    "hasEmailSummary": true,
    "hasDailyReport": true,
    "emailSource": "bots/外贸营销/超级邮件助手/deliverables/email-daily/YYYY-MM-DD.json",
    "dailyReportSource": "bots/管理中枢/总结助手/deliverables/日报-YYYY-MM-DD.md"
  }
}
```

### 字段说明

| 字段 | 必填 | 说明 |
|--|--|--|
| `version` | 是 | 当前为 `1` |
| `date` | 是 | `YYYY-MM-DD`，须与文件名一致 |
| `timezone` | 建议 | 默认 Asia/Shanghai |
| `tasks[]` | 否 | 当日任务；`status` 建议：待办 / 进行中 / 验收 / 完成 |
| `schedule[]` | 否 | 当日日程块；`kind` 建议：`meeting` / `routine` / `focus` / `other` |
| `meta.hasEmailSummary` | 否 | 是否存在信鸽当日邮件总结（正文见私有路径，不进 Pages） |
| `meta.hasDailyReport` | 否 | 是否存在纪纪当日日报 |

## 隐私

- **禁止**在本文件写入客户真名、合同金额、未脱敏联系方式。
- 邮件正文只写在 `bots/外贸营销/超级邮件助手/deliverables/email-daily/`（工作台日历详情本地可读；GitHub Pages **不展示正文**，仅展示「有邮件总结」标记）。
- 纪纪日报见 `bots/管理中枢/总结助手/deliverables/日报-YYYY-MM-DD.md`。

## 写入方

任意 Bot 在完成「某日安排/任务落库」后，可用原子写覆盖或合并同日 JSON。推荐先读再合并 `tasks`/`schedule` 数组（按 `id` 去重）。


## 月索引（可选，利于网页按需加载）

```
超级工作台应用/data/schedule/YYYY-MM.index.json
```

```json
{ "month": "2026-10", "dates": ["2026-10-29", "2026-10-30"] }
```

网页端优先读月索引再按需拉日文件，避免盲扫 31 天。
