import React, { useState, useRef, useEffect } from 'react';
import {
  Sparkles,
  ArrowUp,
  Loader2,
  X,
  CheckCircle2,
  Calendar,
  ChevronRight,
  TrendingUp,
  FolderPlus,
  Command
} from 'lucide-react';

export default function FloatingAiBar({
  onSendCommand,
  isProcessing = false,
  onOpenWebsiteDetail,
  onNavigateTab
}) {
  const [prompt, setPrompt] = useState('');
  const [lastResult, setLastResult] = useState(null);
  const [isExpanded, setIsExpanded] = useState(false);
  const inputRef = useRef(null);

  const samplePrompts = [
    { label: '查未收款', text: '查一下现在有哪些项目未结清款项？' },
    { label: '改项目金额', text: '把MGOO的成交金额改成25000，定金12000' },
    { label: '加订购服务', text: '给Trailnxt添加服务SEO/GEO和网站搭建' },
    { label: '新建客户', text: '新建客户项目：晨光文具，成交金额18000，定金6000' },
    { label: '安排日程', text: '明天上午10点提醒我找陈总确认定金' }
  ];

  const handleSubmit = async (e) => {
    if (e) e.preventDefault();
    const text = prompt.trim();
    if (!text || isProcessing) return;

    try {
      const res = await onSendCommand(text);
      if (res) {
        setLastResult(res);
        setIsExpanded(true);
        setPrompt('');
      }
    } catch (err) {
      setLastResult({
        success: false,
        reply: `⚠️ 执行出错: ${err.message}`
      });
      setIsExpanded(true);
    }
  };

  const handlePickSample = (sampleText) => {
    setPrompt(sampleText);
    if (inputRef.current) {
      inputRef.current.focus();
    }
  };

  // Keyboard shortcut: Cmd+K or Ctrl+K to focus input
  useEffect(() => {
    const handleKeyDown = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        inputRef.current?.focus();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  return (
    <div className="absolute bottom-5 left-0 right-0 z-40 px-4 pointer-events-none flex justify-center">
      <div className="w-full max-w-3xl pointer-events-auto">
        {/* Floating AI Execution Result Card */}
        {isExpanded && lastResult && (
          <div className="mb-2 bg-white/95 backdrop-blur-xl border border-zinc-200/90 rounded-2xl shadow-[0_16px_40px_rgba(0,0,0,0.12)] p-4 animate-fade-in space-y-3 max-h-[60vh] overflow-y-auto">
            {/* Header info */}
            <div className="flex items-center justify-between pb-2 border-b border-zinc-100">
              <div className="flex items-center space-x-2">
                {lastResult.intent === 'update_website_project' && (
                  <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
                    <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                    <span>项目档案已修改</span>
                  </span>
                )}
                {lastResult.intent === 'create_website_project' && (
                  <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-zinc-900 text-white">
                    <FolderPlus className="w-3 h-3 text-zinc-300" />
                    <span>新建客户项目成功</span>
                  </span>
                )}
                {lastResult.intent === 'create_task' && (
                  <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-blue-50 text-blue-700 border border-blue-200">
                    <Calendar className="w-3 h-3" />
                    <span>待办日程已同步</span>
                  </span>
                )}
                {(lastResult.intent === 'query_info' || lastResult.intent === 'general_chat') && (
                  <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-zinc-100 text-zinc-800 border border-zinc-200">
                    <TrendingUp className="w-3 h-3 text-zinc-600" />
                    <span>AI 数据速报</span>
                  </span>
                )}
                <span className="text-[10px] text-zinc-400 font-mono">
                  {new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                </span>
              </div>

              <button
                onClick={() => setIsExpanded(false)}
                className="p-1 text-zinc-400 hover:text-zinc-700 rounded-md hover:bg-zinc-100 transition"
                title="关闭速报"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>

            {/* Formatted Reply Body */}
            <div className="text-xs text-zinc-800 leading-relaxed space-y-1 whitespace-pre-line font-normal">
              {lastResult.reply}
            </div>

            {/* Quick Actions / Link Card */}
            <div className="flex items-center justify-between pt-2 border-t border-zinc-100 flex-wrap gap-2">
              <div className="flex items-center space-x-2">
                {lastResult.project && onOpenWebsiteDetail && (
                  <button
                    onClick={() => {
                      onOpenWebsiteDetail(lastResult.project.id);
                      setIsExpanded(false);
                    }}
                    className="flex items-center space-x-1 px-2.5 py-1 bg-zinc-50 hover:bg-zinc-100 text-zinc-900 rounded-lg text-xs font-medium border border-zinc-200 transition"
                  >
                    <span>查看【{lastResult.project.name}】档案</span>
                    <ChevronRight className="w-3 h-3 text-zinc-400" />
                  </button>
                )}

                {lastResult.task && onNavigateTab && (
                  <button
                    onClick={() => {
                      onNavigateTab('kanban');
                      setIsExpanded(false);
                    }}
                    className="flex items-center space-x-1 px-2.5 py-1 bg-zinc-50 hover:bg-zinc-100 text-zinc-900 rounded-lg text-xs font-medium border border-zinc-200 transition"
                  >
                    <span>在看板查看新待办</span>
                    <ChevronRight className="w-3 h-3 text-zinc-400" />
                  </button>
                )}
              </div>

              <div className="flex items-center space-x-2">
                {onNavigateTab && (
                  <button
                    onClick={() => {
                      onNavigateTab('ai');
                      setIsExpanded(false);
                    }}
                    className="text-[11px] text-zinc-500 hover:text-zinc-900 transition font-medium"
                  >
                    打开完整对话
                  </button>
                )}
                <button
                  onClick={() => setIsExpanded(false)}
                  className="px-2.5 py-0.5 text-xs text-zinc-500 hover:text-zinc-800 font-medium rounded-md hover:bg-zinc-100 transition"
                >
                  收起
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Floating Input Composer Bar (Codex Style) */}
        <form
          onSubmit={handleSubmit}
          className="relative flex items-center bg-white/95 backdrop-blur-xl rounded-2xl border border-zinc-200/90 shadow-[0_10px_30px_rgba(0,0,0,0.08)] hover:border-zinc-300 focus-within:border-zinc-400 focus-within:shadow-[0_14px_36px_rgba(0,0,0,0.12)] transition-all p-1.5 pl-3 pr-2 gap-2.5"
        >
          {/* AI Badge */}
          <div className="flex items-center space-x-1.5 shrink-0">
            <div className="w-6 h-6 rounded-lg bg-zinc-900 text-white flex items-center justify-center font-medium text-xs shadow-xs">
              <Sparkles className="w-3 h-3 fill-white" />
            </div>
          </div>

          {/* Text Input */}
          <input
            ref={inputRef}
            type="text"
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            disabled={isProcessing}
            placeholder="向 AI 发送指令（如：“查未收款”、“把MGOO的成交金额改成25000”、“明天上午10点提醒我找陈总”）..."
            className="w-full bg-transparent text-xs text-zinc-900 placeholder:text-zinc-400 focus:outline-none font-normal"
          />

          {/* Quick Samples Chips */}
          {!prompt && (
            <div className="hidden lg:flex items-center space-x-1.5 shrink-0">
              {samplePrompts.slice(0, 3).map((sp) => (
                <button
                  key={sp.label}
                  type="button"
                  onClick={() => handlePickSample(sp.text)}
                  className="px-2 py-0.5 rounded-md text-[10px] font-medium bg-zinc-100 hover:bg-zinc-200/80 text-zinc-600 hover:text-zinc-900 transition whitespace-nowrap"
                >
                  {sp.label}
                </button>
              ))}
            </div>
          )}

          {/* Clear prompt */}
          {prompt && (
            <button
              type="button"
              onClick={() => setPrompt('')}
              className="p-1 text-zinc-400 hover:text-zinc-700 rounded-full"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          )}

          {/* Send Button */}
          <button
            type="submit"
            disabled={!prompt.trim() || isProcessing}
            className="w-7 h-7 bg-zinc-950 hover:bg-zinc-800 disabled:opacity-20 text-white rounded-full flex items-center justify-center shadow-xs transition active:scale-95 shrink-0"
            title="发送指令"
          >
            {isProcessing ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin text-zinc-300" />
            ) : (
              <ArrowUp className="w-3.5 h-3.5 text-white" />
            )}
          </button>
        </form>
      </div>
    </div>
  );
}
