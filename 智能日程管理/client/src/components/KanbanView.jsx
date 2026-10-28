import React, { useState } from 'react';
import {
  Plus,
  Sparkles,
  Calendar,
  Clock,
  Apple,
  Filter,
  Search,
  ArrowRight,
  ArrowLeft,
  Trash2,
  Edit2,
  Loader2
} from 'lucide-react';

export default function KanbanView({
  tasks,
  projects,
  onTaskStatusChange,
  onEditTask,
  onDeleteTask,
  onOpenNewTask,
  onQuickAiInput,
  isAiProcessing
}) {
  const [selectedProjectId, setSelectedProjectId] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [quickInput, setQuickInput] = useState('');

  const columns = [
    { id: 'todo', title: '待办清单', dot: 'bg-amber-500' },
    { id: 'in_progress', title: '进行中', dot: 'bg-blue-500' },
    { id: 'done', title: '已完成', dot: 'bg-emerald-500' },
    { id: 'archived', title: '归档', dot: 'bg-zinc-400' }
  ];

  // Filter tasks
  const filteredTasks = tasks.filter((t) => {
    const matchesProject = selectedProjectId === 'all' || t.project_id === selectedProjectId;
    const matchesSearch =
      t.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (t.description && t.description.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (t.project_name && t.project_name.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesProject && matchesSearch;
  });

  const handleQuickSubmit = (e) => {
    e.preventDefault();
    if (!quickInput.trim() || isAiProcessing) return;
    onQuickAiInput(quickInput);
    setQuickInput('');
  };

  const getPriorityBadge = (priority) => {
    switch (priority) {
      case 'high':
        return (
          <span className="inline-flex items-center space-x-1 px-1.5 py-0.5 rounded text-[10px] bg-rose-50 text-rose-700 border border-rose-200/80 font-medium">
            <span className="w-1 h-1 rounded-full bg-rose-500" />
            <span>高优先</span>
          </span>
        );
      case 'low':
        return (
          <span className="inline-flex items-center space-x-1 px-1.5 py-0.5 rounded text-[10px] bg-zinc-100 text-zinc-600 border border-zinc-200">
            <span className="w-1 h-1 rounded-full bg-zinc-400" />
            <span>低优先</span>
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center space-x-1 px-1.5 py-0.5 rounded text-[10px] bg-zinc-50 text-zinc-700 border border-zinc-200">
            <span className="w-1 h-1 rounded-full bg-blue-500" />
            <span>普通</span>
          </span>
        );
    }
  };

  const getNextStatus = (current) => {
    if (current === 'todo') return 'in_progress';
    if (current === 'in_progress') return 'done';
    if (current === 'done') return 'archived';
    return null;
  };

  const getPrevStatus = (current) => {
    if (current === 'archived') return 'done';
    if (current === 'done') return 'in_progress';
    if (current === 'in_progress') return 'todo';
    return null;
  };

  return (
    <div className="space-y-4">
      {/* AI Quick Input Bar (Codex Style) */}
      <div className="bg-white border border-zinc-200/90 rounded-xl p-2.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
        <form onSubmit={handleQuickSubmit} className="flex items-center gap-2">
          <div className="flex items-center space-x-1.5 pl-1 shrink-0 text-zinc-800">
            <Sparkles className="w-4 h-4 text-zinc-900" />
            <span className="text-xs font-medium">AI 速记:</span>
          </div>
          <div className="relative flex-1">
            <input
              type="text"
              placeholder="输入如：“明天下午3点跟进外贸客户报价，准备样品图”，AI 自动提取日期、匹配分类并同步至 Mac 提醒事项"
              value={quickInput}
              onChange={(e) => setQuickInput(e.target.value)}
              disabled={isAiProcessing}
              className="w-full px-3 py-1.5 bg-transparent text-xs text-zinc-900 placeholder-zinc-400 focus:outline-none font-normal"
            />
          </div>
          <button
            type="submit"
            disabled={isAiProcessing || !quickInput.trim()}
            className="px-3 py-1.5 bg-zinc-950 hover:bg-zinc-800 disabled:opacity-30 text-white rounded-lg text-xs font-medium transition flex items-center space-x-1.5 shrink-0 shadow-xs"
          >
            {isAiProcessing ? (
              <>
                <Loader2 className="w-3.5 h-3.5 animate-spin text-zinc-300" />
                <span>解析中...</span>
              </>
            ) : (
              <span>添加并同步</span>
            )}
          </button>
        </form>
      </div>

      {/* Filter and Toolbar */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-white border border-zinc-200/90 px-3 py-2 rounded-xl shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
        <div className="flex items-center space-x-2.5 flex-1 min-w-[260px]">
          {/* Project filter */}
          <div className="flex items-center space-x-1.5 bg-zinc-50 px-2.5 py-1 rounded-lg border border-zinc-200/80">
            <Filter className="w-3 h-3 text-zinc-400" />
            <select
              value={selectedProjectId}
              onChange={(e) => setSelectedProjectId(e.target.value)}
              className="bg-transparent text-xs text-zinc-700 font-medium focus:outline-none cursor-pointer"
            >
              <option value="all">全部分类 ({tasks.length})</option>
              {projects.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          </div>

          {/* Search box */}
          <div className="relative flex-1 max-w-xs">
            <Search className="w-3 h-3 text-zinc-400 absolute left-2.5 top-2" />
            <input
              type="text"
              placeholder="快速搜索任务..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-7 pr-3 py-1 bg-zinc-50 border border-zinc-200/80 rounded-lg text-xs text-zinc-800 placeholder-zinc-400 focus:outline-none focus:ring-1 focus:ring-zinc-900"
            />
          </div>
        </div>

        {/* Total stats */}
        <div className="flex items-center space-x-3 text-xs text-zinc-500 font-normal">
          <span>待办 <strong className="text-zinc-900 font-mono">{tasks.filter(t => t.status === 'todo').length}</strong></span>
          <span>•</span>
          <span>进行中 <strong className="text-zinc-900 font-mono">{tasks.filter(t => t.status === 'in_progress').length}</strong></span>
          <span>•</span>
          <span>已完成 <strong className="text-zinc-900 font-mono">{tasks.filter(t => t.status === 'done').length}</strong></span>
        </div>
      </div>

      {/* Kanban Columns */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3.5">
        {columns.map((col) => {
          const colTasks = filteredTasks.filter((t) => t.status === col.id);
          return (
            <div
              key={col.id}
              className="bg-[#fcfcfd] border border-zinc-200/80 rounded-xl flex flex-col min-h-[520px] overflow-hidden"
            >
              {/* Column Header */}
              <div className="px-3 py-2.5 border-b border-zinc-200/70 flex items-center justify-between bg-white">
                <div className="flex items-center space-x-2">
                  <span className={`w-1.5 h-1.5 rounded-full ${col.dot}`} />
                  <span className="text-xs font-semibold text-zinc-900">
                    {col.title}
                  </span>
                  <span className="text-xs text-zinc-400 font-mono font-normal">
                    {colTasks.length}
                  </span>
                </div>
                {col.id === 'todo' && (
                  <button
                    onClick={onOpenNewTask}
                    className="p-1 text-zinc-400 hover:text-zinc-800 hover:bg-zinc-100 rounded-md transition"
                    title="新建待办"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>

              {/* Column Tasks */}
              <div className="p-2.5 space-y-2 flex-1 overflow-y-auto">
                {colTasks.length === 0 ? (
                  <div className="h-28 flex flex-col items-center justify-center text-zinc-400 border border-dashed border-zinc-200 rounded-lg text-xs">
                    <span>暂无{col.title}</span>
                  </div>
                ) : (
                  colTasks.map((task) => (
                    <div
                      key={task.id}
                      className="group bg-white hover:bg-white border border-zinc-200/80 hover:border-zinc-300 rounded-lg p-3 shadow-[0_1px_2px_rgba(0,0,0,0.02)] transition-all space-y-2 relative"
                    >
                      {/* Top Badges */}
                      <div className="flex items-center justify-between">
                        <div className="flex items-center space-x-1 flex-wrap gap-1">
                          {task.project_name && (
                            <span
                              className="px-1.5 py-0.2 rounded text-[10px] font-medium border"
                              style={{
                                backgroundColor: `${task.project_color || '#3b82f6'}10`,
                                borderColor: `${task.project_color || '#3b82f6'}25`,
                                color: task.project_color || '#2563eb'
                              }}
                            >
                              {task.project_name}
                            </span>
                          )}
                          {getPriorityBadge(task.priority)}
                        </div>

                        {/* Apple Reminder Sync Badge */}
                        {task.apple_reminder_id ? (
                          <span
                            title="已与 Mac 提醒事项双向同步"
                            className="flex items-center space-x-0.5 text-[10px] text-zinc-500 font-mono"
                          >
                            <Apple className="w-3 h-3 text-zinc-700" />
                          </span>
                        ) : null}
                      </div>

                      {/* Task Title */}
                      <h4
                        className={`text-xs font-medium leading-snug ${
                          task.status === 'done' || task.status === 'archived'
                            ? 'text-zinc-400 line-through'
                            : 'text-zinc-900'
                        }`}
                      >
                        {task.title}
                      </h4>

                      {/* Task Description Preview */}
                      {task.description && (
                        <p className="text-[11px] text-zinc-500 line-clamp-2 leading-relaxed">
                          {task.description}
                        </p>
                      )}

                      {/* Date & Time */}
                      {(task.due_date || task.due_time) && (
                        <div className="flex items-center space-x-2 text-[10px] text-zinc-400 pt-1 border-t border-zinc-100 font-mono">
                          {task.due_date && (
                            <div className="flex items-center space-x-1">
                              <Calendar className="w-3 h-3 text-zinc-400" />
                              <span>{task.due_date}</span>
                            </div>
                          )}
                          {task.due_time && (
                            <div className="flex items-center space-x-1">
                              <Clock className="w-3 h-3 text-zinc-400" />
                              <span>{task.due_time}</span>
                            </div>
                          )}
                        </div>
                      )}

                      {/* Card Actions */}
                      <div className="pt-1.5 flex items-center justify-between border-t border-zinc-100">
                        <div className="flex items-center space-x-0.5">
                          {getPrevStatus(task.status) && (
                            <button
                              onClick={() =>
                                onTaskStatusChange(task.id, getPrevStatus(task.status))
                              }
                              title="回退状态"
                              className="p-1 rounded text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 transition"
                            >
                              <ArrowLeft className="w-3 h-3" />
                            </button>
                          )}
                          {getNextStatus(task.status) && (
                            <button
                              onClick={() =>
                                onTaskStatusChange(task.id, getNextStatus(task.status))
                              }
                              title="推进状态"
                              className="p-1 rounded text-zinc-500 hover:text-zinc-900 hover:bg-zinc-100 transition flex items-center space-x-1"
                            >
                              <ArrowRight className="w-3 h-3" />
                            </button>
                          )}
                        </div>

                        <div className="flex items-center space-x-0.5 opacity-80 group-hover:opacity-100 transition">
                          <button
                            onClick={() => onEditTask(task)}
                            title="编辑"
                            className="p-1 rounded text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 transition"
                          >
                            <Edit2 className="w-3 h-3" />
                          </button>
                          <button
                            onClick={() => onDeleteTask(task.id)}
                            title="删除"
                            className="p-1 rounded text-zinc-400 hover:text-rose-600 hover:bg-rose-50 transition"
                          >
                            <Trash2 className="w-3 h-3" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
