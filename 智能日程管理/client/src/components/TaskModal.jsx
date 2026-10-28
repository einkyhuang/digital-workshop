import React, { useState, useEffect } from 'react';
import { X, Folder, CheckCircle } from 'lucide-react';

export default function TaskModal({ isOpen, onClose, onSave, task, projects }) {
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    project_id: '',
    priority: 'medium',
    status: 'todo',
    due_date: '',
    due_time: ''
  });

  useEffect(() => {
    if (task) {
      setFormData({
        title: task.title || '',
        description: task.description || '',
        project_id: task.project_id || (projects[0]?.id || ''),
        priority: task.priority || 'medium',
        status: task.status || 'todo',
        due_date: task.due_date || '',
        due_time: task.due_time || ''
      });
    } else {
      setFormData({
        title: '',
        description: '',
        project_id: projects[0]?.id || '',
        priority: 'medium',
        status: 'todo',
        due_date: new Date().toISOString().split('T')[0],
        due_time: '10:00'
      });
    }
  }, [task, projects, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.title.trim()) return;
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-xs p-4 animate-fade-in">
      <div className="bg-white border border-zinc-200 rounded-2xl w-full max-w-md shadow-[0_20px_50px_rgba(0,0,0,0.15)] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="px-5 py-3.5 border-b border-zinc-100 flex items-center justify-between bg-white">
          <div className="flex items-center space-x-2">
            <span className="p-1 rounded-md bg-zinc-100 text-zinc-700">
              <CheckCircle className="w-4 h-4" />
            </span>
            <h3 className="text-xs font-semibold text-zinc-950">
              {task ? '编辑日程任务' : '新建日程待办'}
            </h3>
          </div>
          <button
            onClick={onClose}
            className="text-zinc-400 hover:text-zinc-700 p-1 rounded-md hover:bg-zinc-100 transition"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleSubmit} className="p-5 space-y-3.5">
          <div>
            <label className="block text-[11px] font-medium text-zinc-600 mb-1">
              任务 / 日程标题 <span className="text-rose-500">*</span>
            </label>
            <input
              type="text"
              required
              placeholder="例如：准备外贸客户合同草案"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 placeholder-zinc-400 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white transition"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                归属分类
              </label>
              <div className="relative">
                <select
                  value={formData.project_id}
                  onChange={(e) => setFormData({ ...formData, project_id: e.target.value })}
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white transition appearance-none cursor-pointer"
                >
                  <option value="">(未分类)</option>
                  {projects.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name}
                    </option>
                  ))}
                </select>
                <Folder className="w-3.5 h-3.5 text-zinc-400 absolute right-2.5 top-2 pointer-events-none" />
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                优先级
              </label>
              <select
                value={formData.priority}
                onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
                className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white transition cursor-pointer"
              >
                <option value="high">🔥 紧急重要</option>
                <option value="medium">🔹 正常优先</option>
                <option value="low">🌱 低优先级</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                截止 / 安排日期
              </label>
              <input
                type="date"
                value={formData.due_date}
                onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
                className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white transition font-mono"
              />
            </div>

            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                具体时间 (可选)
              </label>
              <input
                type="time"
                value={formData.due_time}
                onChange={(e) => setFormData({ ...formData, due_time: e.target.value })}
                className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white transition font-mono"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-medium text-zinc-600 mb-1">
              任务状态
            </label>
            <div className="grid grid-cols-4 gap-1.5">
              {[
                { id: 'todo', label: '待办' },
                { id: 'in_progress', label: '进行中' },
                { id: 'done', label: '已完成' },
                { id: 'archived', label: '归档' }
              ].map((st) => (
                <button
                  type="button"
                  key={st.id}
                  onClick={() => setFormData({ ...formData, status: st.id })}
                  className={`py-1.5 text-xs font-medium rounded-lg border transition ${
                    formData.status === st.id
                      ? 'bg-zinc-950 border-zinc-950 text-white shadow-xs'
                      : 'bg-zinc-50 border-zinc-200 text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100'
                  }`}
                >
                  {st.label}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-medium text-zinc-600 mb-1">
              详细描述 (将同步至 Mac 提醒事项备注)
            </label>
            <textarea
              rows={3}
              placeholder="输入任务具体需求或背景信息..."
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 placeholder-zinc-400 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white transition resize-none"
            />
          </div>

          {/* Footer Buttons */}
          <div className="pt-2.5 border-t border-zinc-100 flex items-center justify-end space-x-2">
            <button
              type="button"
              onClick={onClose}
              className="px-3 py-1.5 text-xs text-zinc-600 hover:text-zinc-900 rounded-lg hover:bg-zinc-100 transition"
            >
              取消
            </button>
            <button
              type="submit"
              className="px-3.5 py-1.5 bg-zinc-950 hover:bg-zinc-800 text-white text-xs font-medium rounded-lg shadow-xs transition flex items-center space-x-1"
            >
              <span>{task ? '保存修改' : '创建并同步'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
