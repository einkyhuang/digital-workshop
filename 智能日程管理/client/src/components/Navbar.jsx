import React from 'react';
import {
  LayoutDashboard,
  CalendarDays,
  FolderKanban,
  Sparkles,
  Settings,
  Plus,
  Apple,
  Globe,
  RefreshCw
} from 'lucide-react';

export default function Navbar({
  currentTab,
  setCurrentTab,
  onOpenNewTask,
  syncStatus,
  isSyncing,
  onTriggerSync,
  websiteCount = 0
}) {
  // 5 primary workspace tabs
  const primaryTabs = [
    { id: 'kanban', label: '看板', icon: LayoutDashboard },
    { id: 'calendar', label: '日历', icon: CalendarDays },
    { id: 'projects', label: '项目库', icon: FolderKanban },
    { id: 'websites', label: '客户网站', icon: Globe, count: websiteCount },
    { id: 'ai', label: 'AI 助手', icon: Sparkles }
  ];

  return (
    <header className="sticky top-0 z-40 bg-white/90 backdrop-blur-md border-b border-slate-200/80 shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14">
          {/* Left: Brand */}
          <div
            onClick={() => setCurrentTab('kanban')}
            className="flex items-center space-x-2.5 cursor-pointer shrink-0 select-none group"
          >
            <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-indigo-600 to-violet-600 flex items-center justify-center shadow-sm shadow-indigo-500/20 group-hover:scale-105 transition-transform">
              <Sparkles className="w-4 h-4 text-white" />
            </div>
            <div className="flex items-center space-x-1.5">
              <span className="font-bold text-sm tracking-tight text-slate-900">
                SmartPlan
              </span>
              <span className="text-[10px] px-1.5 py-0.2 rounded-md bg-slate-100 text-slate-600 font-medium border border-slate-200/60 hidden sm:inline">
                Hub
              </span>
            </div>
          </div>

          {/* Center: Segmented Navigation Control */}
          <nav className="flex items-center bg-slate-100/80 p-1 rounded-xl border border-slate-200/70 shadow-2xs">
            {primaryTabs.map((item) => {
              const Icon = item.icon;
              const isActive = currentTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setCurrentTab(item.id)}
                  className={`relative flex items-center space-x-1.5 px-3 py-1.5 rounded-lg text-xs transition-all duration-150 ${
                    isActive
                      ? 'bg-white text-indigo-600 shadow-xs font-semibold'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-white/50 font-medium'
                  }`}
                >
                  <Icon className={`w-3.5 h-3.5 ${isActive ? 'text-indigo-600' : 'text-slate-500'}`} />
                  <span className="whitespace-nowrap">{item.label}</span>
                  {item.count !== undefined && item.count > 0 && (
                    <span
                      className={`px-1.5 py-0.2 text-[10px] rounded-full font-mono font-semibold leading-none ${
                        isActive
                          ? 'bg-indigo-50 text-indigo-700'
                          : 'bg-slate-200/80 text-slate-600'
                      }`}
                    >
                      {item.count}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>

          {/* Right: Actions & Integrations */}
          <div className="flex items-center space-x-2 shrink-0">
            {/* Apple Reminders Sync Status Pill & Trigger */}
            <div className="flex items-center bg-slate-100/90 rounded-xl border border-slate-200 p-0.5">
              <button
                onClick={() => setCurrentTab('sync')}
                className={`flex items-center space-x-1 px-2.5 py-1 rounded-lg text-xs font-medium transition ${
                  currentTab === 'sync'
                    ? 'bg-white text-slate-900 shadow-2xs font-semibold'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
                title="点击查看 Mac 提醒事项同步日志与配置"
              >
                <Apple className="w-3.5 h-3.5 text-slate-700" />
                <span className="hidden md:inline">Mac 提醒</span>
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              </button>

              <button
                onClick={onTriggerSync}
                disabled={isSyncing}
                title="即时触发双向同步"
                className="p-1 text-slate-500 hover:text-slate-800 hover:bg-white rounded-lg transition"
              >
                <RefreshCw className={`w-3 h-3 text-indigo-600 ${isSyncing ? 'animate-spin' : ''}`} />
              </button>
            </div>

            {/* Settings Tab Button */}
            <button
              onClick={() => setCurrentTab('settings')}
              title="系统设置 (API Key 与模型参数)"
              className={`p-2 rounded-xl border transition ${
                currentTab === 'settings'
                  ? 'bg-indigo-50 text-indigo-600 border-indigo-200 shadow-2xs'
                  : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50 hover:text-slate-900'
              }`}
            >
              <Settings className="w-4 h-4" />
            </button>

            {/* Quick Add Task */}
            <button
              onClick={onOpenNewTask}
              className="flex items-center space-x-1 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-semibold shadow-xs shadow-indigo-600/30 transition whitespace-nowrap"
            >
              <Plus className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">新建待办</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}
