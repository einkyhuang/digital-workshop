import React, { useState, useRef, useEffect } from 'react';
import { Bot, User, ArrowUp, Sparkles, Apple, Calendar, Folder, Trash2, ArrowRight, Loader2 } from 'lucide-react';

export default function AiChatView({
  history,
  onSendMessage,
  onClearHistory,
  isProcessing
}) {
  const [input, setInput] = useState('');
  const messagesEndRef = useRef(null);

  const samplePrompts = [
    '明天下午3点跟进外贸客户报价，准备样品清单',
    '周五上午10点组织智能日程管理项目的代码评审会',
    '今晚8点去健身房跑步锻炼40分钟',
    '下周一整理年度核心目标并提交周报'
  ];

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [history, isProcessing]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!input.trim() || isProcessing) return;
    onSendMessage(input);
    setInput('');
  };

  const handleSelectSample = (sample) => {
    if (isProcessing) return;
    onSendMessage(sample);
  };

  return (
    <div className="bg-white border border-zinc-200/90 rounded-2xl flex flex-col h-[calc(100vh-140px)] min-h-[550px] overflow-hidden shadow-[0_1px_3px_rgba(0,0,0,0.02)]">
      {/* Chat Header */}
      <div className="px-5 py-3 border-b border-zinc-200/80 bg-white flex items-center justify-between">
        <div className="flex items-center space-x-2.5">
          <div className="w-7 h-7 rounded-lg bg-zinc-900 text-white flex items-center justify-center shadow-xs">
            <Sparkles className="w-3.5 h-3.5 fill-white" />
          </div>
          <div>
            <h3 className="font-semibold text-zinc-900 text-xs flex items-center space-x-1.5">
              <span>智能日程 AI 助手</span>
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
            </h3>
            <p className="text-[10px] text-zinc-400">
              自然语言日程解析 • 语义归类 • 双向联通 Mac 提醒事项
            </p>
          </div>
        </div>

        <button
          onClick={onClearHistory}
          className="text-zinc-400 hover:text-zinc-700 text-xs flex items-center space-x-1 px-2.5 py-1 rounded-md hover:bg-zinc-100 transition"
          title="清空对话记录"
        >
          <Trash2 className="w-3.5 h-3.5" />
          <span>清空记录</span>
        </button>
      </div>

      {/* Messages Scroll Area */}
      <div className="flex-1 overflow-y-auto p-5 space-y-4 bg-[#fbfbfb]">
        {/* Welcome Message if history is empty */}
        {history.length === 0 && (
          <div className="max-w-lg mx-auto py-10 text-center space-y-4">
            <div className="w-10 h-10 rounded-xl bg-zinc-100 border border-zinc-200 text-zinc-800 mx-auto flex items-center justify-center">
              <Bot className="w-5 h-5 text-zinc-700" />
            </div>
            <div>
              <h4 className="text-sm font-semibold text-zinc-900">
                我是您的智能项目与日程管家
              </h4>
              <p className="text-xs text-zinc-500 leading-relaxed max-w-sm mx-auto mt-1">
                支持日常对话、待办提取、客户项目金额修改与日程排期，数据自动双向联通 Mac 提醒事项。
              </p>
            </div>

            <div className="pt-2 text-left space-y-2">
              <p className="text-[11px] text-zinc-400 font-medium">快速体验指令：</p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {samplePrompts.map((p, idx) => (
                  <button
                    key={idx}
                    onClick={() => handleSelectSample(p)}
                    className="text-left text-xs p-2.5 rounded-xl bg-white hover:bg-zinc-50 border border-zinc-200/80 text-zinc-700 hover:text-zinc-950 transition leading-snug flex items-center justify-between group shadow-2xs"
                  >
                    <span className="truncate pr-2">{p}</span>
                    <ArrowRight className="w-3 h-3 opacity-0 group-hover:opacity-100 text-zinc-600 transition shrink-0" />
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Message items */}
        {history.map((msg) => {
          const isUser = msg.role === 'user';
          let parsedMeta = null;
          if (msg.metadata) {
            try {
              parsedMeta = JSON.parse(msg.metadata);
            } catch (e) {}
          }

          return (
            <div
              key={msg.id}
              className={`flex items-start space-x-2.5 ${isUser ? 'flex-row-reverse space-x-reverse' : ''}`}
            >
              {/* Avatar */}
              <div
                className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 text-xs font-medium ${
                  isUser
                    ? 'bg-zinc-800 text-white shadow-xs'
                    : 'bg-zinc-950 text-white shadow-xs'
                }`}
              >
                {isUser ? <User className="w-3.5 h-3.5" /> : <Bot className="w-3.5 h-3.5" />}
              </div>

              {/* Message Body */}
              <div
                className={`max-w-[82%] rounded-2xl p-3.5 text-xs space-y-2 ${
                  isUser
                    ? 'bg-zinc-950 text-white rounded-tr-xs shadow-sm'
                    : 'bg-white border border-zinc-200/80 text-zinc-800 rounded-tl-xs shadow-[0_1px_2px_rgba(0,0,0,0.02)]'
                }`}
              >
                <div className="whitespace-pre-wrap leading-relaxed font-normal">
                  {msg.content}
                </div>

                {/* If a task was created in this assistant response, render card */}
                {parsedMeta?.task && (
                  <div className="mt-2 bg-zinc-50 border border-zinc-200 rounded-xl p-2.5 space-y-1.5 text-zinc-700">
                    <div className="flex items-center justify-between text-[10px]">
                      <span className="font-medium text-zinc-900 flex items-center space-x-1">
                        <Sparkles className="w-3 h-3 text-zinc-700" />
                        <span>已创建日程卡片</span>
                      </span>
                      <span className="flex items-center space-x-1 text-emerald-700 bg-emerald-50 px-1.5 py-0.2 rounded border border-emerald-200 font-mono">
                        <Apple className="w-3 h-3 text-emerald-600" />
                        <span>已同步 Mac 提醒</span>
                      </span>
                    </div>

                    <p className="text-xs font-semibold text-zinc-900">
                      {parsedMeta.task.title}
                    </p>

                    <div className="flex items-center space-x-3 text-[10px] text-zinc-400 pt-1 border-t border-zinc-200 font-mono">
                      {parsedMeta.task.project_name && (
                        <span className="flex items-center space-x-1">
                          <Folder className="w-3 h-3 text-zinc-400" />
                          <span>{parsedMeta.task.project_name}</span>
                        </span>
                      )}
                      {parsedMeta.task.due_date && (
                        <span className="flex items-center space-x-1">
                          <Calendar className="w-3 h-3 text-zinc-400" />
                          <span>{parsedMeta.task.due_date} {parsedMeta.task.due_time || ''}</span>
                        </span>
                      )}
                    </div>
                  </div>
                )}
              </div>
            </div>
          );
        })}

        {/* Processing Indicator */}
        {isProcessing && (
          <div className="flex items-start space-x-2.5">
            <div className="w-7 h-7 rounded-lg bg-zinc-950 text-white flex items-center justify-center shrink-0 shadow-xs">
              <Bot className="w-3.5 h-3.5" />
            </div>
            <div className="bg-white border border-zinc-200 rounded-2xl rounded-tl-xs px-3.5 py-2.5 text-xs text-zinc-500 flex items-center space-x-2 shadow-xs">
              <Loader2 className="w-3.5 h-3.5 animate-spin text-zinc-600" />
              <span>AI 正在解析日程并同步至 Mac 提醒事项...</span>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input Form */}
      <div className="p-3 border-t border-zinc-200/80 bg-white">
        <form onSubmit={handleSubmit} className="flex items-center space-x-2">
          <input
            type="text"
            placeholder="输入日程或指令，如：“明天下午2点跟进客户并准备合同”..."
            value={input}
            onChange={(e) => setInput(e.target.value)}
            disabled={isProcessing}
            className="flex-1 px-3.5 py-2 bg-zinc-50 border border-zinc-200/80 rounded-xl text-zinc-900 placeholder-zinc-400 text-xs focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white transition"
          />
          <button
            type="submit"
            disabled={isProcessing || !input.trim()}
            className="w-8 h-8 bg-zinc-950 hover:bg-zinc-800 disabled:opacity-20 text-white rounded-lg flex items-center justify-center shadow-xs transition shrink-0"
            title="发送"
          >
            {isProcessing ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin text-zinc-300" />
            ) : (
              <ArrowUp className="w-4 h-4 text-white" />
            )}
          </button>
        </form>
      </div>
    </div>
  );
}
