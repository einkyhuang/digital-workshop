import React from 'react';
import {
  LayoutDashboard,
  CalendarDays,
  FolderKanban,
  Sparkles,
  Settings,
  Apple,
  Globe,
  ChevronDown,
  Layers,
  RefreshCw,
  Bot
} from 'lucide-react';

export default function Sidebar({
  currentTab,
  setCurrentTab,
  projects = [],
  websiteCount = 0,
  tasksCount = 0,
  syncStatus,
  onTriggerSync,
  isSyncing
}) {
  const navItemsPrimary = [
    {
      id: 'kanban',
      label: '项目看板',
      icon: LayoutDashboard,
      count: tasksCount
    },
    {
      id: 'calendar',
      label: '日程规划',
      icon: CalendarDays
    },
    {
      id: 'websites',
      label: '客户网站档案',
      icon: Globe,
      count: websiteCount,
      highlight: true
    },
    {
      id: 'projects',
      label: '分类管理',
      icon: FolderKanban,
      count: projects.length
    }
  ];

  const navItemsSystem = [
    {
      id: 'ai',
      label: 'AI 对话管家',
      icon: Bot,
      badge: 'GPT/AI'
    },
    {
      id: 'sync',
      label: 'Mac 提醒事项',
      icon: Apple,
      statusDot: true
    },
    {
      id: 'settings',
      label: '系统与模型',
      icon: Settings
    }
  ];

  return (
    <aside className="w-64 bg-[#fbfbfb] border-r border-[#e5e5e7] flex flex-col justify-between shrink-0 h-screen select-none z-30">
      {/* Top Section */}
      <div className="flex-1 overflow-y-auto px-3.5 pt-8 pb-3 space-y-4">
        {/* Brand Header */}
        <div className="flex items-center justify-between px-1.5 pt-1">
          <div
            className="flex items-center space-x-2.5 cursor-pointer group"
            onClick={() => setCurrentTab('kanban')}
          >
            <div className="w-7 h-7 rounded-lg bg-zinc-900 text-white flex items-center justify-center shadow-xs transition group-hover:bg-black">
              <Sparkles className="w-3.5 h-3.5 fill-white" />
            </div>
            <div>
              <div className="flex items-center space-x-1.5">
                <span className="font-semibold text-xs text-zinc-900 tracking-tight">
                  SmartPlan Hub
                </span>
                <span className="text-[9px] font-mono px-1 py-0.2 bg-zinc-200/70 text-zinc-600 rounded">
                  v1.2
                </span>
              </div>
              <p className="text-[10px] text-zinc-400 font-medium">
                桌面日程与客户管理
              </p>
            </div>
          </div>

          <button
            onClick={() => setCurrentTab('settings')}
            className="w-6 h-6 rounded-md hover:bg-zinc-200/60 flex items-center justify-center text-zinc-400 hover:text-zinc-700 transition"
            title="偏好设置"
          >
            <Settings className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Workspace Pill */}
        <div className="bg-white hover:bg-zinc-50 border border-zinc-200/80 rounded-xl p-2 px-2.5 flex items-center justify-between cursor-pointer transition shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="flex items-center space-x-2 truncate">
            <div className="w-5 h-5 rounded-md bg-zinc-100 flex items-center justify-center text-zinc-600 shrink-0">
              <Layers className="w-3 h-3" />
            </div>
            <div className="truncate">
              <p className="text-[11px] font-medium text-zinc-900 leading-tight truncate">
                个人主工作区
              </p>
              <p className="text-[9px] text-zinc-400">
                {websiteCount} 网站 • {projects.length} 分类
              </p>
            </div>
          </div>
          <ChevronDown className="w-3.5 h-3.5 text-zinc-400 shrink-0" />
        </div>

        {/* Section 1: 工作台 */}
        <div className="space-y-0.5">
          <div className="text-[10px] font-semibold text-zinc-400 uppercase tracking-wider px-2 py-1">
            工作台
          </div>
          {navItemsPrimary.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setCurrentTab(item.id)}
                className={`w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-xs transition-all duration-100 ${
                  isActive
                    ? 'bg-[#efeff0] text-zinc-950 font-medium shadow-[inset_0_1px_0_rgba(255,255,255,0.7)]'
                    : 'text-zinc-600 hover:bg-[#f4f4f5] hover:text-zinc-900'
                }`}
              >
                <div className="flex items-center space-x-2.5">
                  <Icon
                    className={`w-4 h-4 ${
                      isActive ? 'text-zinc-950' : 'text-zinc-400'
                    }`}
                  />
                  <span>{item.label}</span>
                </div>
                {item.count !== undefined && (
                  <span
                    className={`text-[10px] font-mono px-1.5 py-0.2 rounded ${
                      isActive
                        ? 'bg-zinc-300/60 text-zinc-900 font-semibold'
                        : 'text-zinc-400'
                    }`}
                  >
                    {item.count}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Section 2: 系统与服务 */}
        <div className="space-y-0.5 pt-2">
          <div className="text-[10px] font-semibold text-zinc-400 uppercase tracking-wider px-2 py-1">
            AI 与系统
          </div>
          {navItemsSystem.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setCurrentTab(item.id)}
                className={`w-full flex items-center justify-between px-2.5 py-1.5 rounded-lg text-xs transition-all duration-100 ${
                  isActive
                    ? 'bg-[#efeff0] text-zinc-950 font-medium shadow-[inset_0_1px_0_rgba(255,255,255,0.7)]'
                    : 'text-zinc-600 hover:bg-[#f4f4f5] hover:text-zinc-900'
                }`}
              >
                <div className="flex items-center space-x-2.5">
                  <Icon
                    className={`w-4 h-4 ${
                      isActive ? 'text-zinc-950' : 'text-zinc-400'
                    }`}
                  />
                  <span>{item.label}</span>
                </div>
                {item.badge && (
                  <span className="text-[9px] font-mono px-1 py-0.2 rounded bg-zinc-200/60 text-zinc-600 font-medium">
                    {item.badge}
                  </span>
                )}
                {item.statusDot && (
                  <span className="flex items-center space-x-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                    <span className="text-[9px] text-zinc-400 font-mono">同步中</span>
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Bottom Section */}
      <div className="p-3 border-t border-[#e5e5e7] space-y-2.5 bg-[#fbfbfb]">
        {/* Sync Status Tile */}
        <div className="bg-white border border-zinc-200/80 rounded-xl p-2.5 flex items-center justify-between shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="flex items-center space-x-2">
            <span className="w-2 h-2 rounded-full bg-emerald-500 shrink-0" />
            <div>
              <p className="text-[11px] font-medium text-zinc-800 leading-tight">
                Mac 提醒事项
              </p>
              <p className="text-[9px] text-zinc-400">
                {isSyncing ? '正在双向同步...' : '已双向实时联通'}
              </p>
            </div>
          </div>
          <button
            onClick={() => onTriggerSync()}
            disabled={isSyncing}
            className="w-6 h-6 rounded-md hover:bg-zinc-100 flex items-center justify-center text-zinc-500 hover:text-zinc-900 transition disabled:opacity-40"
            title="立即触发同步"
          >
            <RefreshCw
              className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`}
            />
          </button>
        </div>

        {/* User Profile Bar */}
        <div className="flex items-center justify-between px-1">
          <div className="flex items-center space-x-2">
            <div className="w-6 h-6 rounded-full bg-zinc-900 text-white font-medium text-[10px] flex items-center justify-center">
              KY
            </div>
            <div>
              <p className="text-[11px] font-medium text-zinc-800 leading-tight">
                KY Workspace
              </p>
              <p className="text-[9px] text-zinc-400">本地数据已持久化</p>
            </div>
          </div>
          <span className="text-[9px] font-mono text-zinc-400 px-1 py-0.5 rounded bg-zinc-100">
            ARM64
          </span>
        </div>
      </div>
    </aside>
  );
}
