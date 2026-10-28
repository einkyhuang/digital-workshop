import React from 'react';
import { Apple, RefreshCw, ArrowUpRight, ArrowDownLeft, ListOrdered, ShieldCheck } from 'lucide-react';

export default function SyncLogsView({
  syncStatus,
  logs = [],
  isSyncing,
  onTriggerSync
}) {
  return (
    <div className="space-y-4">
      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
        <div className="bg-white border border-zinc-200/90 rounded-xl p-4 space-y-2 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-medium text-zinc-400">Mac 监听清单</span>
            <div className="w-6 h-6 rounded-md bg-zinc-100 flex items-center justify-center text-zinc-700">
              <Apple className="w-3.5 h-3.5" />
            </div>
          </div>
          <div>
            <p className="text-base font-semibold text-zinc-950 font-mono">
              {syncStatus?.targetList || 'AI 智能日程'}
            </p>
            <p className="text-[11px] text-emerald-600 mt-0.5 flex items-center space-x-1 font-medium">
              <ShieldCheck className="w-3 h-3" />
              <span>AppleScript 权限正常</span>
            </p>
          </div>
        </div>

        <div className="bg-white border border-zinc-200/90 rounded-xl p-4 space-y-2 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-medium text-zinc-400">总待办与同步量</span>
            <div className="w-6 h-6 rounded-md bg-zinc-100 flex items-center justify-center text-zinc-700">
              <ListOrdered className="w-3.5 h-3.5" />
            </div>
          </div>
          <div>
            <p className="text-base font-semibold text-zinc-950 font-mono">
              {syncStatus?.totalCount || 0} <span className="text-xs font-normal text-zinc-400">条</span>
            </p>
            <p className="text-[11px] text-zinc-400 mt-0.5 font-mono">
              待推送未绑定: <strong className="text-zinc-700">{syncStatus?.unsyncedCount || 0}</strong>
            </p>
          </div>
        </div>

        <div className="bg-white border border-zinc-200/90 rounded-xl p-4 space-y-2 flex flex-col justify-between shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-medium text-zinc-400">双向同步触发器</span>
            <button
              onClick={onTriggerSync}
              disabled={isSyncing}
              className="flex items-center space-x-1 px-2.5 py-1 bg-zinc-950 hover:bg-zinc-800 disabled:opacity-40 text-white rounded-lg text-xs font-medium shadow-xs transition"
            >
              <RefreshCw className={`w-3 h-3 ${isSyncing ? 'animate-spin' : ''}`} />
              <span>{isSyncing ? '同步中...' : '立即同步'}</span>
            </button>
          </div>
          <div>
            <p className="text-[11px] text-zinc-500 font-mono">
              上次检测: <span className="text-zinc-900 font-medium">{syncStatus?.lastSync ? new Date(syncStatus.lastSync).toLocaleTimeString() : '刚刚'}</span>
            </p>
            <p className="text-[10px] text-zinc-400">后台自动轮询机制已就绪</p>
          </div>
        </div>
      </div>

      {/* Explanatory banner */}
      <div className="bg-white border border-zinc-200/80 rounded-xl p-3 flex items-center space-x-3 text-xs text-zinc-600 shadow-[0_1px_2px_rgba(0,0,0,0.01)]">
        <div className="w-6 h-6 rounded-md bg-zinc-100 text-zinc-700 flex items-center justify-center shrink-0">
          <Apple className="w-3.5 h-3.5" />
        </div>
        <div className="text-[11px] leading-relaxed">
          <strong className="text-zinc-900">双向同步机制：</strong>
          本地建立日程 ➔ 自动同步到 Mac 提醒事项；在 iPhone / Mac / Siri 提醒事项添加 ➔ AI 自动匹配归类并同步回本地看板。
        </div>
      </div>

      {/* Live Sync Logs Table */}
      <div className="bg-white border border-zinc-200/90 rounded-xl overflow-hidden shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
        <div className="px-4 py-3 border-b border-zinc-100 flex items-center justify-between bg-white">
          <h3 className="font-semibold text-zinc-950 text-xs">同步审计记录</h3>
          <span className="text-[10px] text-zinc-400 font-mono">共 {logs.length} 条</span>
        </div>

        <div className="divide-y divide-zinc-100">
          {logs.length === 0 ? (
            <div className="py-10 text-center text-xs text-zinc-400">
              暂无同步记录，当系统与 Mac 提醒事项发生数据交互时将在此呈现
            </div>
          ) : (
            logs.map((log) => {
              const isInbound = log.direction === 'from_reminders';
              return (
                <div key={log.id} className="p-3 hover:bg-zinc-50/70 transition flex items-start justify-between gap-3 text-xs">
                  <div className="flex items-start space-x-2.5">
                    <span
                      className={`p-1 rounded-md shrink-0 mt-0.5 ${
                        isInbound
                          ? 'bg-blue-50 text-blue-600 border border-blue-200/60'
                          : 'bg-emerald-50 text-emerald-600 border border-emerald-200/60'
                      }`}
                    >
                      {isInbound ? (
                        <ArrowDownLeft className="w-3.5 h-3.5" />
                      ) : (
                        <ArrowUpRight className="w-3.5 h-3.5" />
                      )}
                    </span>
                    <div>
                      <div className="flex items-center space-x-2">
                        <span className="font-medium text-zinc-900">
                          {log.action === 'created'
                            ? '新建待办'
                            : log.action === 'updated'
                            ? '更新状态/内容'
                            : '反向导入'}
                        </span>
                        <span className="text-[10px] text-zinc-400 font-mono">
                          {isInbound ? 'Mac ➔ 本地' : '本地 ➔ Mac'}
                        </span>
                      </div>
                      <p className="text-[11px] text-zinc-500 mt-0.5">
                        {log.details || log.task_title || '数据同步成功'}
                      </p>
                    </div>
                  </div>
                  <span className="text-[10px] text-zinc-400 font-mono shrink-0">
                    {new Date(log.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                  </span>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
