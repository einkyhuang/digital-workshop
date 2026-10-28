import React, { useState, useEffect } from 'react';
import { Save, Cpu, Apple, Check } from 'lucide-react';

export default function SettingsView({ settings, onSaveSettings, availableLists = [] }) {
  const [formData, setFormData] = useState({
    reminder_list_name: 'AI 智能日程',
    auto_sync_interval: '20',
    auto_sync_enabled: 'true',
    llm_provider: 'deepseek',
    llm_base_url: 'https://api.deepseek.com/v1',
    llm_api_key: '',
    llm_model: 'deepseek-chat'
  });
  const [savedSuccess, setSavedSuccess] = useState(false);

  useEffect(() => {
    if (settings) {
      setFormData((prev) => ({ ...prev, ...settings }));
    }
  }, [settings]);

  const presetProviders = [
    { id: 'deepseek', name: 'DeepSeek', url: 'https://api.deepseek.com/v1', model: 'deepseek-chat' },
    { id: 'openai', name: 'OpenAI', url: 'https://api.openai.com/v1', model: 'gpt-4o-mini' },
    { id: 'qwen', name: '阿里云通义千问', url: 'https://dashscope.aliyuncs.com/compatible-mode/v1', model: 'qwen-plus' },
    { id: 'moonshot', name: 'Moonshot (Kimi)', url: 'https://api.moonshot.cn/v1', model: 'moonshot-v1-8k' },
    { id: 'ollama', name: 'Ollama 本地大模型', url: 'http://localhost:11434/v1', model: 'qwen2.5:7b' }
  ];

  const handleProviderSelect = (providerId) => {
    const found = presetProviders.find((p) => p.id === providerId);
    if (found) {
      setFormData({
        ...formData,
        llm_provider: found.id,
        llm_base_url: found.url,
        llm_model: found.model
      });
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSaveSettings(formData);
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 2500);
  };

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* AI Engine Settings Card */}
        <div className="bg-white border border-zinc-200/90 rounded-xl p-4 space-y-3.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="flex items-center space-x-2.5 pb-2.5 border-b border-zinc-100">
            <div className="w-7 h-7 rounded-lg bg-zinc-100 text-zinc-700 flex items-center justify-center">
              <Cpu className="w-3.5 h-3.5" />
            </div>
            <div>
              <h3 className="font-semibold text-zinc-950 text-xs">AI 模型参数配置</h3>
              <p className="text-[11px] text-zinc-400">
                兼容标准 OpenAI 接口规范，支持云端大模型与本地 Ollama 实例
              </p>
            </div>
          </div>

          <div className="space-y-3">
            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1.5">
                模型快捷预设
              </label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                {presetProviders.map((p) => (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => handleProviderSelect(p.id)}
                    className={`p-2 rounded-lg border text-left text-xs transition ${
                      formData.llm_provider === p.id
                        ? 'bg-zinc-950 border-zinc-950 text-white shadow-xs'
                        : 'bg-zinc-50 border-zinc-200/80 text-zinc-700 hover:bg-zinc-100'
                    }`}
                  >
                    <div className="font-medium">{p.name}</div>
                    <div className={`text-[10px] font-mono mt-0.5 ${formData.llm_provider === p.id ? 'text-zinc-300' : 'text-zinc-400'}`}>
                      {p.model}
                    </div>
                  </button>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  API Base URL
                </label>
                <input
                  type="text"
                  value={formData.llm_base_url}
                  onChange={(e) => setFormData({ ...formData, llm_base_url: e.target.value })}
                  placeholder="https://api.deepseek.com/v1"
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs font-mono focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  模型标识 (Model)
                </label>
                <input
                  type="text"
                  value={formData.llm_model}
                  onChange={(e) => setFormData({ ...formData, llm_model: e.target.value })}
                  placeholder="deepseek-chat"
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs font-mono focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                />
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                API Key
              </label>
              <input
                type="password"
                value={formData.llm_api_key}
                onChange={(e) => setFormData({ ...formData, llm_api_key: e.target.value })}
                placeholder="sk-..."
                className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs font-mono focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white"
              />
              <p className="text-[11px] text-zinc-400 mt-1">
                💡 即使暂未填入 API Key，系统内建中文自然语言解析器依然能直接提取时间与待办。
              </p>
            </div>
          </div>
        </div>

        {/* Apple Reminders Settings Card */}
        <div className="bg-white border border-zinc-200/90 rounded-xl p-4 space-y-3.5 shadow-[0_1px_2px_rgba(0,0,0,0.02)]">
          <div className="flex items-center space-x-2.5 pb-2.5 border-b border-zinc-100">
            <div className="w-7 h-7 rounded-lg bg-zinc-100 text-zinc-700 flex items-center justify-center">
              <Apple className="w-3.5 h-3.5" />
            </div>
            <div>
              <h3 className="font-semibold text-zinc-950 text-xs">Mac 提醒事项联通</h3>
              <p className="text-[11px] text-zinc-400">
                双向同步的目标系统清单与轮询频率
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                目标清单名称
              </label>
              <input
                type="text"
                value={formData.reminder_list_name}
                onChange={(e) => setFormData({ ...formData, reminder_list_name: e.target.value })}
                placeholder="AI 智能日程"
                className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white"
              />
              {availableLists.length > 0 && (
                <div className="mt-1.5 flex flex-wrap gap-1">
                  <span className="text-[10px] text-zinc-400">可用清单:</span>
                  {availableLists.map((l, i) => (
                    <button
                      key={i}
                      type="button"
                      onClick={() => setFormData({ ...formData, reminder_list_name: l })}
                      className="text-[10px] text-zinc-600 hover:text-zinc-900 hover:underline px-0.5"
                    >
                      {l}
                    </button>
                  ))}
                </div>
              )}
            </div>

            <div>
              <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                自动同步频次 (秒)
              </label>
              <select
                value={formData.auto_sync_interval}
                onChange={(e) => setFormData({ ...formData, auto_sync_interval: e.target.value })}
                className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white cursor-pointer"
              >
                <option value="10">10 秒 (极速响应)</option>
                <option value="20">20 秒 (推荐默认)</option>
                <option value="60">60 秒 (低负载)</option>
              </select>
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="flex items-center justify-end space-x-2 pt-1">
          {savedSuccess && (
            <span className="text-xs text-emerald-600 font-medium flex items-center space-x-1 animate-fade-in mr-2">
              <Check className="w-3.5 h-3.5" />
              <span>设置已保存！</span>
            </span>
          )}
          <button
            type="submit"
            className="px-4 py-1.5 bg-zinc-950 hover:bg-zinc-800 text-white rounded-lg text-xs font-medium shadow-xs transition flex items-center space-x-1.5"
          >
            <Save className="w-3.5 h-3.5" />
            <span>保存配置</span>
          </button>
        </div>
      </form>
    </div>
  );
}
