import React from 'react';
import { Search, Plus, RefreshCw, Command } from 'lucide-react';

export default function TopHeader({
  currentTab,
  onOpenNewTask,
  syncStatus,
  isSyncing,
  onTriggerSync,
  searchQuery,
  setSearchQuery,
  tasksCount = 0,
  websiteCount = 0
}) {
  const getTabInfo = () => {
    switch (currentTab) {
      case 'kanban':
        return {
          title: '项目看板与待办',
          subtitle: `共 ${tasksCount} 项任务 • 待办/进行中/完成全流程看板`
        };
      case 'calendar':
        return {
          title: '日程规划日历',
          subtitle: '按时间与周期排期规划 • 自动同步 Mac 提醒事项'
        };
      case 'websites':
        return {
          title: '客户定制网站档案库',
          subtitle: `已收录归档 ${websiteCount} 个定制网站 • 财务、服务期与本地开发资产`
        };
      case 'projects':
        return {
          title: '分类体系管理',
          subtitle: '多维业务与标签归类 • AI 自动语义归集'
        };
      case 'ai':
        return {
          title: 'AI 对话管家',
          subtitle: '自然语言指令交互 • 支持多模态模型与本地模型'
        };
      case 'sync':
        return {
          title: 'Mac 提醒事项同步',
          subtitle: '苹果生态双向同步引擎 • 毫秒级防重防环同步'
        };
      case 'settings':
        return {
          title: '系统设置与模型',
          subtitle: 'LLM 提供商密钥、端点配置及本地偏好'
        };
      default:
        return {
          title: '工作区概览',
          subtitle: '系统稳定运行中'
        };
    }
  };

  const { title, subtitle } = getTabInfo();

  return (
    <header className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6 pb-2">
      {/* Title & Subtitle */}
      <div>
        <h1 className="text-xl font-semibold text-zinc-950 tracking-tight">
          {title}
        </h1>
        <p className="text-xs text-zinc-500 mt-0.5 font-normal">
          {subtitle}
        </p>
      </div>

      {/* Right Controls (Codex Minimalist style) */}
      <div className="flex items-center space-x-2">
        {/* Search Input with Cmd+K hint */}
        <div className="relative">
          <Search className="w-3.5 h-3.5 text-zinc-400 absolute left-2.5 top-2.5" />
          <input
            type="text"
            placeholder="全站快速搜索..."
            value={searchQuery || ''}
            onChange={(e) => setSearchQuery && setSearchQuery(e.target.value)}
            className="pl-8 pr-12 py-1.5 bg-white rounded-lg border border-zinc-200/90 text-xs text-zinc-900 placeholder-zinc-400 focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:border-zinc-900 shadow-[0_1px_2px_rgba(0,0,0,0.02)] w-44 lg:w-56 transition"
          />
          <div className="absolute right-2 top-2 flex items-center space-x-0.5 text-[10px] text-zinc-400 font-mono bg-zinc-100 px-1 py-0.2 rounded border border-zinc-200 pointer-events-none">
            <Command className="w-2.5 h-2.5" />
            <span>K</span>
          </div>
        </div>

        {/* Sync Trigger Button */}
        <button
          onClick={onTriggerSync}
          disabled={isSyncing}
          className="flex items-center space-x-1.5 px-2.5 py-1.5 bg-white hover:bg-zinc-50 text-zinc-700 rounded-lg text-xs font-medium border border-zinc-200/90 shadow-[0_1px_2px_rgba(0,0,0,0.02)] transition disabled:opacity-40"
          title="即时双向同步 Mac 提醒事项"
        >
          <RefreshCw className={`w-3.5 h-3.5 text-zinc-500 ${isSyncing ? 'animate-spin' : ''}`} />
          <span className="hidden md:inline">{isSyncing ? '同步中' : '双向同步'}</span>
        </button>

        {/* Primary Action Button */}
        <button
          onClick={onOpenNewTask}
          className="flex items-center space-x-1.5 px-3 py-1.5 bg-zinc-950 hover:bg-zinc-800 text-white rounded-lg text-xs font-medium shadow-xs transition active:scale-[0.98]"
        >
          <Plus className="w-3.5 h-3.5 text-zinc-300" />
          <span>新建待办</span>
        </button>
      </div>
    </header>
  );
}
