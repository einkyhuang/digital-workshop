import React from 'react';
import { Calendar, Clock, CheckCircle2, Circle, Apple } from 'lucide-react';

export default function CalendarView({ tasks, onTaskStatusChange, onEditTask }) {
  // Group tasks by date
  const todayStr = new Date().toISOString().split('T')[0];
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toISOString().split('T')[0];

  const grouped = {
    today: [],
    tomorrow: [],
    upcoming: [],
    nodate: []
  };

  tasks.forEach((t) => {
    if (!t.due_date) {
      grouped.nodate.push(t);
    } else if (t.due_date === todayStr) {
      grouped.today.push(t);
    } else if (t.due_date === tomorrowStr) {
      grouped.tomorrow.push(t);
    } else {
      grouped.upcoming.push(t);
    }
  });

  // Sort upcoming by date
  grouped.upcoming.sort((a, b) => (a.due_date > b.due_date ? 1 : -1));

  const renderSection = (title, list, dotColor, dateLabel) => {
    return (
      <div className="bg-white border border-zinc-200/90 rounded-xl p-4 space-y-3 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
        <div className="flex items-center justify-between pb-2 border-b border-zinc-100">
          <div className="flex items-center space-x-2">
            <span className={`w-1.5 h-1.5 rounded-full ${dotColor}`} />
            <h3 className="text-xs font-semibold text-zinc-900">{title}</h3>
            {dateLabel && (
              <span className="text-[11px] text-zinc-400 font-mono">({dateLabel})</span>
            )}
          </div>
          <span className="text-[10px] px-1.5 py-0.2 rounded bg-zinc-100 text-zinc-500 font-mono border border-zinc-200">
            {list.length} 项
          </span>
        </div>

        {list.length === 0 ? (
          <p className="text-xs text-zinc-400 py-3 text-center">暂无日程安排</p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2.5">
            {list.map((task) => (
              <div
                key={task.id}
                onClick={() => onEditTask(task)}
                className="bg-[#fcfcfd] hover:bg-zinc-50 border border-zinc-200/80 rounded-lg p-2.5 space-y-2 cursor-pointer transition shadow-[0_1px_2px_rgba(0,0,0,0.01)]"
              >
                <div className="flex items-center justify-between">
                  {task.project_name ? (
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
                  ) : (
                    <span className="text-[10px] text-zinc-400">未分类</span>
                  )}
                  {task.apple_reminder_id && (
                    <span className="flex items-center space-x-0.5 text-[10px] text-zinc-500 font-mono">
                      <Apple className="w-3 h-3 text-zinc-600" />
                      <span>已同步</span>
                    </span>
                  )}
                </div>

                <div className="flex items-start space-x-2">
                  <button
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation();
                      onTaskStatusChange(task.id, task.status === 'done' ? 'todo' : 'done');
                    }}
                    className="mt-0.5 text-zinc-400 hover:text-emerald-600 transition"
                  >
                    {task.status === 'done' ? (
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                    ) : (
                      <Circle className="w-3.5 h-3.5" />
                    )}
                  </button>
                  <p
                    className={`text-xs font-medium leading-snug ${
                      task.status === 'done' ? 'line-through text-zinc-400' : 'text-zinc-900'
                    }`}
                  >
                    {task.title}
                  </p>
                </div>

                <div className="flex items-center space-x-3 text-[10px] text-zinc-400 pt-1 border-t border-zinc-100 font-mono">
                  {task.due_date && (
                    <span className="flex items-center space-x-1">
                      <Calendar className="w-3 h-3 text-zinc-400" />
                      <span>{task.due_date}</span>
                    </span>
                  )}
                  {task.due_time && (
                    <span className="flex items-center space-x-1">
                      <Clock className="w-3 h-3 text-zinc-400" />
                      <span>{task.due_time}</span>
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-4">
      {renderSection('今日日程 (Today)', grouped.today, 'bg-rose-500', todayStr)}
      {renderSection('明日规划 (Tomorrow)', grouped.tomorrow, 'bg-amber-500', tomorrowStr)}
      {renderSection('未来计划 (Upcoming)', grouped.upcoming, 'bg-blue-500')}
      {renderSection('待排期 (Backlog)', grouped.nodate, 'bg-zinc-400')}
    </div>
  );
}
