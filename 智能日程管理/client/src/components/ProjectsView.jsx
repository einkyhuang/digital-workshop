import React, { useState } from 'react';
import { Plus, Edit2, Trash2, X } from 'lucide-react';

export default function ProjectsView({ projects, onSaveProject, onDeleteProject }) {
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingProject, setEditingProject] = useState(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    color: '#3b82f6'
  });

  const colorPalette = [
    '#3b82f6', // Blue
    '#8b5cf6', // Violet
    '#ec4899', // Pink
    '#10b981', // Emerald
    '#f59e0b', // Amber
    '#06b6d4', // Cyan
    '#f43f5e', // Rose
    '#6366f1'  // Indigo
  ];

  const handleOpenCreate = () => {
    setEditingProject(null);
    setFormData({ name: '', description: '', color: '#3b82f6' });
    setIsModalOpen(true);
  };

  const handleOpenEdit = (project) => {
    setEditingProject(project);
    setFormData({
      name: project.name,
      description: project.description || '',
      color: project.color || '#3b82f6'
    });
    setIsModalOpen(true);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.name.trim()) return;
    onSaveProject(formData, editingProject?.id);
    setIsModalOpen(false);
  };

  return (
    <div className="space-y-4">
      {/* Top action header */}
      <div className="flex items-center justify-between bg-white border border-zinc-200/90 px-4 py-3 rounded-xl shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
        <div>
          <h2 className="text-xs font-semibold text-zinc-950">项目与分类体系</h2>
          <p className="text-[11px] text-zinc-400 mt-0.5">
            AI 建立日程时将自动语义匹配归属到这些项目中，支持看板多维进度追踪
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="flex items-center space-x-1 px-3 py-1.5 bg-zinc-950 hover:bg-zinc-800 text-white rounded-lg text-xs font-medium shadow-xs transition"
        >
          <Plus className="w-3.5 h-3.5" />
          <span>新建分类</span>
        </button>
      </div>

      {/* Project Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
        {projects.map((project) => {
          const total = project.total_tasks || 0;
          const done = project.done_tasks || 0;
          const active = project.active_tasks || 0;
          const percentage = total > 0 ? Math.round((done / total) * 100) : 0;

          return (
            <div
              key={project.id}
              className="bg-white border border-zinc-200/80 hover:border-zinc-300 rounded-xl p-4 space-y-3 transition shadow-[0_1px_2px_rgba(0,0,0,0.02)] flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center space-x-2">
                    <span
                      className="w-2.5 h-2.5 rounded-full shrink-0"
                      style={{ backgroundColor: project.color }}
                    />
                    <h3 className="font-semibold text-zinc-950 text-xs tracking-tight">{project.name}</h3>
                  </div>

                  <div className="flex items-center space-x-0.5">
                    <button
                      onClick={() => handleOpenEdit(project)}
                      className="p-1 text-zinc-400 hover:text-zinc-700 hover:bg-zinc-100 rounded-md transition"
                      title="编辑分类"
                    >
                      <Edit2 className="w-3 h-3" />
                    </button>
                    <button
                      onClick={() => onDeleteProject(project.id)}
                      className="p-1 text-zinc-400 hover:text-rose-600 hover:bg-rose-50 rounded-md transition"
                      title="删除分类"
                    >
                      <Trash2 className="w-3 h-3" />
                    </button>
                  </div>
                </div>

                <p className="text-[11px] text-zinc-500 line-clamp-2 leading-relaxed min-h-[32px]">
                  {project.description || '暂无项目描述'}
                </p>
              </div>

              {/* Progress & Stats */}
              <div className="space-y-1.5 pt-2.5 border-t border-zinc-100">
                <div className="flex items-center justify-between text-[11px]">
                  <span className="text-zinc-400">完成率</span>
                  <span className="font-mono text-zinc-800 font-medium">{percentage}%</span>
                </div>
                {/* Progress bar */}
                <div className="w-full h-1.5 bg-zinc-100 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-300"
                    style={{
                      width: `${percentage}%`,
                      backgroundColor: project.color
                    }}
                  />
                </div>

                <div className="flex items-center justify-between text-[10px] text-zinc-400 pt-1 font-mono">
                  <span>进行中: <strong className="text-zinc-700">{active}</strong></span>
                  <span>已完成: <strong className="text-emerald-600">{done}</strong></span>
                  <span>总计: <strong className="text-zinc-700">{total}</strong></span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Project Create/Edit Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-xs p-4 animate-fade-in">
          <div className="bg-white border border-zinc-200 rounded-2xl w-full max-w-sm shadow-[0_20px_50px_rgba(0,0,0,0.15)] p-5 space-y-4">
            <div className="flex items-center justify-between pb-2 border-b border-zinc-100">
              <h3 className="font-semibold text-zinc-950 text-xs">
                {editingProject ? '编辑分类' : '新建分类'}
              </h3>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-zinc-400 hover:text-zinc-700 p-1 rounded-md"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-3.5">
              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  分类名称 <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="例如：外贸客户跟进"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  分类色彩
                </label>
                <div className="flex items-center space-x-2 pt-1">
                  {colorPalette.map((c) => (
                    <button
                      key={c}
                      type="button"
                      onClick={() => setFormData({ ...formData, color: c })}
                      className={`w-5 h-5 rounded-full transition-transform ${
                        formData.color === c ? 'scale-125 ring-2 ring-zinc-900 ring-offset-2' : 'hover:scale-110'
                      }`}
                      style={{ backgroundColor: c }}
                    />
                  ))}
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  分类描述
                </label>
                <textarea
                  rows="2"
                  placeholder="简述该分类的业务范畴..."
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                />
              </div>

              <div className="pt-2 flex items-center justify-end space-x-2 border-t border-zinc-100">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-3 py-1.5 text-xs text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 rounded-lg transition"
                >
                  取消
                </button>
                <button
                  type="submit"
                  className="px-3 py-1.5 bg-zinc-950 hover:bg-zinc-800 text-white rounded-lg text-xs font-medium shadow-xs transition"
                >
                  保存分类
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
