import React, { useState, useEffect } from 'react';
import {
  Globe,
  ExternalLink,
  FolderOpen,
  Code2,
  X,
  User,
  Phone,
  MessageSquare,
  Mail,
  Building,
  DollarSign,
  CreditCard,
  KeyRound,
  ShieldCheck,
  Calendar,
  Save,
  Plus,
  Trash2,
  Clock,
  Sparkles,
  CheckCircle2,
  Copy,
  Check
} from 'lucide-react';
import { api } from '../api';

export default function WebsiteDetailModal({
  websiteId,
  isOpen,
  onClose,
  onUpdated,
  onOpenLocal,
  onOpenEditor
}) {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saveSuccess, setSaveSuccess] = useState(false);
  const [project, setProject] = useState(null);
  const [activeTab, setActiveTab] = useState('crm'); // 'crm' | 'finance' | 'assets' | 'follow_ups'
  const [copiedKey, setCopiedKey] = useState(null);

  // Form states
  const [formData, setFormData] = useState({
    name: '',
    url: '',
    status: 'in_progress',
    category: '进行中',
    framework: 'React',
    description: '',
    // Services
    services: [],
    // CRM
    client_name: '',
    client_phone: '',
    client_wechat: '',
    client_email: '',
    client_company: '',
    // Finance
    total_amount: 0,
    deposit_amount: 0,
    paid_amount: 0,
    unpaid_amount: 0,
    payment_status: 'pending',
    // Service duration
    service_start_date: '',
    service_end_date: '',
    // Assets & credentials
    assets_credentials: ''
  });

  // Services catalog states
  const [availableServices, setAvailableServices] = useState(['网站搭建', 'SEO/GEO', '科学上网']);
  const [customServiceInput, setCustomServiceInput] = useState('');

  // Follow-up inputs
  const [newFollowUp, setNewFollowUp] = useState('');
  const [followUpType, setFollowUpType] = useState('note');
  const [addingFollowUp, setAddingFollowUp] = useState(false);

  useEffect(() => {
    if (isOpen && websiteId) {
      loadProjectDetail();
    }
  }, [isOpen, websiteId]);

  const loadProjectDetail = async () => {
    setLoading(true);
    try {
      const [res, srvRes] = await Promise.all([
        api.getWebsiteDetail(websiteId),
        api.getWebsiteServices()
      ]);

      if (srvRes?.success && Array.isArray(srvRes.data)) {
        setAvailableServices(srvRes.data);
      }

      if (res.success && res.data) {
        const d = res.data;
        setProject(d);

        let parsedServices = [];
        if (Array.isArray(d.services)) {
          parsedServices = d.services;
        } else if (d.services) {
          try {
            parsedServices = JSON.parse(d.services);
          } catch {
            parsedServices = typeof d.services === 'string' ? d.services.split(',').map((s) => s.trim()).filter(Boolean) : [];
          }
        }

        const tot = d.total_amount !== undefined && d.total_amount !== null ? parseFloat(d.total_amount) || 0 : 0;
        const dep = d.deposit_amount !== undefined && d.deposit_amount !== null ? parseFloat(d.deposit_amount) || 0 : 0;
        const unp = d.unpaid_amount !== undefined && d.unpaid_amount !== null
          ? parseFloat(d.unpaid_amount) || 0
          : Math.max(0, tot - dep);
        const pd = d.paid_amount !== undefined && d.paid_amount !== null
          ? parseFloat(d.paid_amount) || 0
          : Math.max(0, tot - unp);

        setFormData({
          name: d.name || '',
          url: d.url || '',
          status: d.status || 'in_progress',
          category: d.category || '进行中',
          framework: d.framework || 'React',
          description: d.description || '',
          services: parsedServices,
          client_name: d.client_name || '',
          client_phone: d.client_phone || '',
          client_wechat: d.client_wechat || '',
          client_email: d.client_email || '',
          client_company: d.client_company || '',
          total_amount: tot,
          deposit_amount: dep,
          paid_amount: pd,
          unpaid_amount: unp,
          payment_status: d.payment_status || 'pending',
          service_start_date: d.service_start_date || '',
          service_end_date: d.service_end_date || '',
          assets_credentials: d.assets_credentials || ''
        });
      }
    } catch (e) {
      console.error('[Load Website Detail Error]:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleTotalAmountChange = (val) => {
    const tot = val === '' ? '' : parseFloat(val) || 0;
    const dep = parseFloat(formData.deposit_amount) || 0;
    const numTot = typeof tot === 'number' ? tot : 0;
    const autoUnpaid = Math.max(0, numTot - dep);
    setFormData((prev) => ({
      ...prev,
      total_amount: val,
      unpaid_amount: autoUnpaid,
      paid_amount: dep
    }));
  };

  const handleDepositAmountChange = (val) => {
    const dep = val === '' ? '' : parseFloat(val) || 0;
    const tot = parseFloat(formData.total_amount) || 0;
    const numDep = typeof dep === 'number' ? dep : 0;
    const autoUnpaid = Math.max(0, tot - numDep);
    setFormData((prev) => ({
      ...prev,
      deposit_amount: val,
      unpaid_amount: autoUnpaid,
      paid_amount: numDep
    }));
  };

  const handleUnpaidAmountChange = (val) => {
    const unp = val === '' ? '' : parseFloat(val) || 0;
    const tot = parseFloat(formData.total_amount) || 0;
    const numUnp = typeof unp === 'number' ? unp : 0;
    const calcPaid = Math.max(0, tot - numUnp);
    setFormData((prev) => ({
      ...prev,
      unpaid_amount: val,
      paid_amount: calcPaid
    }));
  };

  const handleToggleService = (srv) => {
    setFormData((prev) => {
      const current = prev.services || [];
      if (current.includes(srv)) {
        return { ...prev, services: current.filter((s) => s !== srv) };
      } else {
        return { ...prev, services: [...current, srv] };
      }
    });
  };

  const handleAddCustomService = async (e) => {
    if (e) e.preventDefault();
    const val = customServiceInput.trim();
    if (!val) return;

    // Immediately toggle select on current form
    setFormData((prev) => {
      const current = prev.services || [];
      return {
        ...prev,
        services: current.includes(val) ? current : [...current, val]
      };
    });

    // Sync to global pool
    try {
      const res = await api.addWebsiteService(val);
      if (res.success && Array.isArray(res.data)) {
        setAvailableServices(res.data);
      }
    } catch (err) {
      console.error('Failed to sync custom service to pool:', err);
    }
    setCustomServiceInput('');
  };

  const handleDeleteServiceOption = async (srv, e) => {
    e.stopPropagation();
    if (['网站搭建', 'SEO/GEO', '科学上网'].includes(srv)) return;
    if (!window.confirm(`确定要从可选服务库中移除“${srv}”吗？`)) return;
    try {
      const res = await api.deleteWebsiteService(srv);
      if (res.success && Array.isArray(res.data)) {
        setAvailableServices(res.data);
      }
      setFormData((prev) => ({
        ...prev,
        services: (prev.services || []).filter((s) => s !== srv)
      }));
    } catch (err) {
      console.error(err);
    }
  };

  const handleSave = async (e) => {
    if (e) e.preventDefault();
    setSaving(true);
    setSaveSuccess(false);
    try {
      const res = await api.updateWebsite(websiteId, formData);
      if (res.success) {
        setProject(res.data);
        if (onUpdated) onUpdated(res.data);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 2500);
      }
    } catch (e) {
      console.error('[Save Website Error]:', e);
      alert('保存失败: ' + e.message);
    } finally {
      setSaving(false);
    }
  };

  const handleAddFollowUp = async (e) => {
    e.preventDefault();
    if (!newFollowUp.trim()) return;
    setAddingFollowUp(true);
    try {
      const res = await api.addFollowUp(websiteId, newFollowUp, followUpType);
      if (res.success) {
        setNewFollowUp('');
        loadProjectDetail();
      }
    } catch (e) {
      console.error(e);
    } finally {
      setAddingFollowUp(false);
    }
  };

  const handleDeleteFollowUp = async (followUpId) => {
    if (!window.confirm('确定要删除该条跟进记录吗？')) return;
    try {
      await api.deleteFollowUp(followUpId);
      loadProjectDetail();
    } catch (e) {
      console.error(e);
    }
  };

  const handleCopy = (text, key) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 1800);
  };

  const handleApplyDurationPreset = (months) => {
    const today = new Date();
    const startDateStr = formData.service_start_date || today.toISOString().split('T')[0];
    const start = new Date(startDateStr);
    const end = new Date(start);
    end.setMonth(end.getMonth() + months);
    const endDateStr = end.toISOString().split('T')[0];
    setFormData((prev) => ({
      ...prev,
      service_start_date: startDateStr,
      service_end_date: endDateStr
    }));
  };

  const getServiceDurationInfo = (startStr, endStr) => {
    if (!startStr && !endStr) return null;
    const now = new Date();
    now.setHours(0, 0, 0, 0);

    if (startStr && !endStr) {
      return { label: '生效中', badgeClass: 'bg-blue-50 text-blue-700 border border-blue-200' };
    }
    if (!startStr && endStr) {
      const end = new Date(endStr);
      end.setHours(0, 0, 0, 0);
      const diffDays = Math.round((end - now) / (1000 * 60 * 60 * 24));
      if (diffDays < 0) {
        return { label: `逾期 ${Math.abs(diffDays)} 天`, badgeClass: 'bg-rose-50 text-rose-700 border border-rose-200' };
      }
      return { label: `剩 ${diffDays} 天`, badgeClass: 'bg-emerald-50 text-emerald-700 border border-emerald-200' };
    }

    const start = new Date(startStr);
    const end = new Date(endStr);
    start.setHours(0, 0, 0, 0);
    end.setHours(0, 0, 0, 0);

    const diffDays = Math.round((end - now) / (1000 * 60 * 60 * 24));
    if (diffDays < 0) {
      return {
        label: `逾期 ${Math.abs(diffDays)} 天`,
        badgeClass: 'bg-rose-50 text-rose-700 border border-rose-200'
      };
    } else if (diffDays === 0) {
      return {
        label: '今日到期',
        badgeClass: 'bg-amber-50 text-amber-700 border border-amber-200'
      };
    } else if (diffDays <= 30) {
      return {
        label: `剩 ${diffDays} 天`,
        badgeClass: 'bg-amber-50 text-amber-800 border border-amber-200'
      };
    } else {
      return {
        label: `剩 ${diffDays} 天`,
        badgeClass: 'bg-emerald-50 text-emerald-700 border border-emerald-200'
      };
    }
  };

  if (!isOpen) return null;

  const total = parseFloat(formData.total_amount) || 0;
  const deposit = parseFloat(formData.deposit_amount) || 0;
  const unpaid = formData.unpaid_amount !== undefined && formData.unpaid_amount !== null && formData.unpaid_amount !== ''
    ? parseFloat(formData.unpaid_amount) || 0
    : Math.max(0, total - deposit);
  const paid = formData.paid_amount !== undefined && formData.paid_amount !== null && formData.paid_amount !== ''
    ? parseFloat(formData.paid_amount) || 0
    : Math.max(0, total - unpaid);
  const durationInfo = getServiceDurationInfo(formData.service_start_date, formData.service_end_date);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-xs p-3 sm:p-6 animate-fade-in">
      <div className="bg-white border border-zinc-200/90 rounded-2xl w-full max-w-4xl max-h-[92vh] shadow-[0_20px_50px_rgba(0,0,0,0.15)] flex flex-col overflow-hidden text-zinc-900">
        
        {/* Top Header */}
        <div className="p-4 sm:p-5 bg-white border-b border-zinc-100 flex items-center justify-between shrink-0">
          <div className="flex items-center space-x-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-zinc-950 text-white flex items-center justify-center shadow-xs shrink-0">
              <Globe className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <div className="flex items-center space-x-2">
                <h2 className="text-base font-semibold text-zinc-950 tracking-tight truncate">
                  {formData.name || '客户网站详情'}
                </h2>
                <span className={`px-2 py-0.5 rounded-md text-[11px] font-medium ${
                  formData.status === 'in_progress'
                    ? 'bg-amber-50 text-amber-700 border border-amber-200'
                    : formData.status === 'delivered'
                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                    : 'bg-zinc-100 text-zinc-600 border border-zinc-200'
                }`}>
                  {formData.status === 'in_progress' ? '进行中' : formData.status === 'delivered' ? '已交付' : '已暂停'}
                </span>
              </div>
              <div className="flex items-center space-x-2 text-xs text-zinc-500 mt-0.5">
                {formData.url ? (
                  <a
                    href={formData.url}
                    target="_blank"
                    rel="noreferrer"
                    className="text-zinc-800 hover:text-black hover:underline flex items-center space-x-1 font-mono font-medium truncate"
                  >
                    <span>{formData.url}</span>
                    <ExternalLink className="w-3 h-3 text-zinc-400" />
                  </a>
                ) : (
                  <span className="text-zinc-400 italic">未配置线上网址</span>
                )}
                {project?.local_path && (
                  <span className="hidden sm:inline text-zinc-400 truncate">• {project.local_path}</span>
                )}
              </div>

              {/* Header Active Services & Duration Badges */}
              <div className="flex items-center space-x-2 flex-wrap mt-1 gap-y-1">
                {Array.isArray(formData.services) && formData.services.length > 0 && (
                  <div className="flex items-center space-x-1 flex-wrap">
                    <span className="text-[10px] text-zinc-400 font-medium">已订服务:</span>
                    {formData.services.map((srv) => (
                      <span
                        key={srv}
                        className="px-1.5 py-0.2 rounded text-[10px] font-medium bg-zinc-100 text-zinc-800 border border-zinc-200"
                      >
                        {srv}
                      </span>
                    ))}
                  </div>
                )}
                {durationInfo && (
                  <div className="relative group/duration inline-flex items-center">
                    <div
                      className={`flex items-center space-x-1 px-2 py-0.2 rounded text-[10px] font-mono font-medium cursor-help transition-all shadow-2xs hover:shadow-xs ${durationInfo.badgeClass}`}
                      title={`服务时间: ${formData.service_start_date || '未定'} ~ ${formData.service_end_date || '未定'}`}
                    >
                      <Clock className="w-3 h-3" />
                      <span>{durationInfo.label}</span>
                    </div>

                    {/* Hover Tooltip: Show Start and End Dates */}
                    <div className="absolute top-full left-0 mt-1 hidden group-hover/duration:flex flex-col items-start z-50 pointer-events-none animate-fade-in">
                      <div className="bg-zinc-900 text-white text-[10px] font-mono font-medium px-2 py-1 rounded-md shadow-lg whitespace-nowrap flex items-center space-x-1 border border-zinc-700">
                        <Calendar className="w-3 h-3 text-zinc-300" />
                        <span>{formData.service_start_date || '未定'} ~ {formData.service_end_date || '未定'}</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="flex items-center space-x-1.5">
            {project?.local_path && (
              <>
                <button
                  type="button"
                  onClick={() => onOpenLocal(project.local_path)}
                  className="hidden sm:flex items-center space-x-1 px-2.5 py-1 bg-zinc-50 hover:bg-zinc-100 border border-zinc-200/80 rounded-lg text-xs font-medium text-zinc-700 transition"
                  title="在 macOS 访达中打开"
                >
                  <FolderOpen className="w-3.5 h-3.5 text-zinc-500" />
                  <span>访达</span>
                </button>
                <button
                  type="button"
                  onClick={() => onOpenEditor(project.local_path)}
                  className="hidden sm:flex items-center space-x-1 px-2.5 py-1 bg-zinc-50 hover:bg-zinc-100 border border-zinc-200/80 rounded-lg text-xs font-medium text-zinc-700 transition"
                  title="在代码编辑器中打开"
                >
                  <Code2 className="w-3.5 h-3.5 text-zinc-500" />
                  <span>IDE</span>
                </button>
              </>
            )}

            <button
              onClick={onClose}
              className="w-7 h-7 rounded-md hover:bg-zinc-100 text-zinc-400 hover:text-zinc-700 flex items-center justify-center transition"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Tab Switcher Pills */}
        <div className="px-5 py-2 bg-zinc-50 border-b border-zinc-200/70 flex items-center space-x-1.5 overflow-x-auto shrink-0">
          {[
            { id: 'crm', label: '客户资料与服务', icon: User, count: (formData.services || []).length },
            { id: 'finance', label: '财务金额与款项', icon: DollarSign, badge: total > 0 ? (unpaid > 0 ? `未收¥${unpaid.toLocaleString()}` : '已结清') : null },
            { id: 'assets', label: '资产账号与密码', icon: KeyRound },
            { id: 'follow_ups', label: '跟进历史记录', icon: Clock, count: project?.follow_ups?.length || 0 }
          ].map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-1.5 px-3 py-1 rounded-lg text-xs font-medium transition whitespace-nowrap ${
                  isActive
                    ? 'bg-zinc-950 text-white shadow-xs'
                    : 'bg-white text-zinc-600 hover:text-zinc-900 border border-zinc-200/80 hover:bg-zinc-50'
                }`}
              >
                <Icon className="w-3.5 h-3.5" />
                <span>{tab.label}</span>
                {tab.count !== undefined && tab.count > 0 && (
                  <span className={`px-1 py-0.2 rounded text-[10px] font-mono ${
                    isActive ? 'bg-white/20 text-white' : 'bg-zinc-100 text-zinc-600'
                  }`}>
                    {tab.count}
                  </span>
                )}
                {tab.badge && (
                  <span className={`px-1.5 py-0.2 rounded text-[10px] font-mono ${
                    isActive ? 'bg-white/20 text-white' : 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                  }`}>
                    {tab.badge}
                  </span>
                )}
              </button>
            );
          })}
        </div>

        {/* Modal Body Area */}
        <div className="p-6 overflow-y-auto flex-1 space-y-6">
          {loading ? (
            <div className="py-20 text-center text-slate-400 text-xs">加载项目详情数据中...</div>
          ) : (
            <>
              {/* TAB 1: CRM & Client Profile */}
              {activeTab === 'crm' && (
                <div className="space-y-5 animate-in fade-in duration-100">
                  {/* 已订购服务交付项 */}
                  <div className="bg-white rounded-2xl p-5 border border-[#e5e1d8] shadow-2xs space-y-3.5">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <div className="w-6 h-6 rounded-lg bg-amber-500/10 text-amber-600 flex items-center justify-center">
                          <Sparkles className="w-3.5 h-3.5" />
                        </div>
                        <div>
                          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-800 flex items-center space-x-1.5">
                            <span>已订购服务交付项</span>
                            <span className="text-[10px] px-1.5 py-0.2 rounded-full bg-slate-100 text-slate-600 font-mono">
                              已选 {(formData.services || []).length} 项
                            </span>
                          </h3>
                          <p className="text-[11px] text-slate-400 mt-0.5">
                            点击标签直接为本项目启用/取消；新增的自定义服务将同步沉淀至全局库，其他项目亦可一键复用
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Selectable Service Chips */}
                    <div className="flex items-center flex-wrap gap-2 pt-1">
                      {Array.from(new Set([...availableServices, ...(formData.services || [])])).map((srv) => {
                        const isSelected = (formData.services || []).includes(srv);
                        const isDefault = ['网站搭建', 'SEO/GEO', '科学上网'].includes(srv);

                        return (
                          <button
                            key={srv}
                            type="button"
                            onClick={() => handleToggleService(srv)}
                            className={`group flex items-center space-x-1.5 px-3 py-1.5 rounded-full text-xs font-bold transition-all ${
                              isSelected
                                ? 'bg-black text-[#eefb40] shadow-2xs ring-1 ring-black'
                                : 'bg-[#f6f4f0] text-slate-700 hover:bg-[#ebe7de] hover:text-slate-900 border border-[#e2ded6]'
                            }`}
                          >
                            {isSelected ? (
                              <CheckCircle2 className="w-3.5 h-3.5 text-[#eefb40]" />
                            ) : (
                              <Plus className="w-3.5 h-3.5 text-slate-400 group-hover:text-slate-700" />
                            )}
                            <span>{srv}</span>

                            {!isDefault && (
                              <span
                                onClick={(e) => handleDeleteServiceOption(srv, e)}
                                className="ml-1 text-slate-400 hover:text-red-500 rounded-full p-0.5 hover:bg-black/10 transition"
                                title="从全局可选库中移除此自定义服务"
                              >
                                <X className="w-2.5 h-2.5" />
                              </span>
                            )}
                          </button>
                        );
                      })}
                    </div>

                    {/* Custom Service Input */}
                    <div className="pt-2 flex items-center gap-2 max-w-lg">
                      <div className="relative flex-1">
                        <input
                          type="text"
                          placeholder="输入自定义服务名称 (如: 海外服务器部署、社媒运营)..."
                          value={customServiceInput}
                          onChange={(e) => setCustomServiceInput(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') {
                              e.preventDefault();
                              handleAddCustomService();
                            }
                          }}
                          className="w-full px-3 py-1.5 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black placeholder-slate-400"
                        />
                      </div>
                      <button
                        type="button"
                        onClick={handleAddCustomService}
                        disabled={!customServiceInput.trim()}
                        className="px-3.5 py-1.5 bg-black hover:bg-slate-800 disabled:opacity-40 text-white rounded-xl text-xs font-bold shadow-2xs transition flex items-center space-x-1 shrink-0"
                      >
                        <Plus className="w-3.5 h-3.5 text-[#eefb40]" />
                        <span>添加并同步至所有项目</span>
                      </button>
                    </div>
                  </div>

                  {/* 服务时间与服务周期 */}
                  <div className="bg-white rounded-2xl p-5 border border-[#e5e1d8] shadow-2xs space-y-4">
                    <div className="flex items-center justify-between flex-wrap gap-2">
                      <div className="flex items-center space-x-2">
                        <div className="w-6 h-6 rounded-lg bg-indigo-500/10 text-indigo-600 flex items-center justify-center">
                          <Clock className="w-3.5 h-3.5" />
                        </div>
                        <div>
                          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-800 flex items-center space-x-2">
                            <span>服务时间与服务周期</span>
                            {durationInfo && (
                              <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${durationInfo.badgeClass}`}>
                                {durationInfo.label}
                              </span>
                            )}
                          </h3>
                          <p className="text-[11px] text-slate-400 mt-0.5">
                            记录服务开始与截止日期，系统自动跟踪计算剩余服务天数及到期提醒
                          </p>
                        </div>
                      </div>

                      {/* Quick Presets: +1年, +6个月, +3个月, 清空 */}
                      <div className="flex items-center space-x-1.5">
                        <span className="text-[10px] text-slate-400 font-medium hidden sm:inline">快捷期限定制:</span>
                        <button
                          type="button"
                          onClick={() => handleApplyDurationPreset(12)}
                          className="px-2.5 py-1 bg-[#f6f4f0] hover:bg-[#eae6dc] text-slate-700 rounded-lg text-[11px] font-bold transition active:scale-95"
                          title="从开始日期（或今天）起算 +1年"
                        >
                          +1 年
                        </button>
                        <button
                          type="button"
                          onClick={() => handleApplyDurationPreset(6)}
                          className="px-2.5 py-1 bg-[#f6f4f0] hover:bg-[#eae6dc] text-slate-700 rounded-lg text-[11px] font-bold transition active:scale-95"
                          title="从开始日期（或今天）起算 +6个月"
                        >
                          +6 个月
                        </button>
                        <button
                          type="button"
                          onClick={() => handleApplyDurationPreset(3)}
                          className="px-2.5 py-1 bg-[#f6f4f0] hover:bg-[#eae6dc] text-slate-700 rounded-lg text-[11px] font-bold transition active:scale-95"
                          title="从开始日期（或今天）起算 +3个月"
                        >
                          +3 个月
                        </button>
                        {(formData.service_start_date || formData.service_end_date) && (
                          <button
                            type="button"
                            onClick={() => setFormData({ ...formData, service_start_date: '', service_end_date: '' })}
                            className="px-2 py-1 text-slate-400 hover:text-red-500 rounded-lg text-[10px] font-bold transition"
                            title="清空服务时间"
                          >
                            清空
                          </button>
                        )}
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-1">
                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center space-x-1.5">
                          <Calendar className="w-3.5 h-3.5 text-indigo-500" />
                          <span>服务开始时间</span>
                        </label>
                        <input
                          type="date"
                          value={formData.service_start_date || ''}
                          onChange={(e) => setFormData({ ...formData, service_start_date: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black font-mono font-medium"
                        />
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center space-x-1.5">
                          <Clock className="w-3.5 h-3.5 text-indigo-500" />
                          <span>服务结束时间</span>
                        </label>
                        <input
                          type="date"
                          value={formData.service_end_date || ''}
                          onChange={(e) => setFormData({ ...formData, service_end_date: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black font-mono font-medium"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="bg-white rounded-2xl p-5 border border-[#e5e1d8] shadow-2xs space-y-4">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 flex items-center space-x-1.5">
                      <User className="w-4 h-4 text-slate-600" />
                      <span>客户主体与决策人信息</span>
                    </h3>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          客户姓名 / 称呼
                        </label>
                        <input
                          type="text"
                          placeholder="例如：陈总、David"
                          value={formData.client_name}
                          onChange={(e) => setFormData({ ...formData, client_name: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                        />
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          所属公司 / 品牌全称
                        </label>
                        <input
                          type="text"
                          placeholder="例如：杭州某某进出口贸易有限公司"
                          value={formData.client_company}
                          onChange={(e) => setFormData({ ...formData, client_company: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                        />
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center space-x-1">
                          <Phone className="w-3.5 h-3.5 text-slate-500" />
                          <span>联系电话 / 手机</span>
                        </label>
                        <input
                          type="text"
                          placeholder="例如：13800000000"
                          value={formData.client_phone}
                          onChange={(e) => setFormData({ ...formData, client_phone: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black font-mono"
                        />
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center space-x-1">
                          <MessageSquare className="w-3.5 h-3.5 text-emerald-600" />
                          <span>微信号 / WhatsApp / 微信名</span>
                        </label>
                        <input
                          type="text"
                          placeholder="例如：wxid_xxx / +86 138xxx"
                          value={formData.client_wechat}
                          onChange={(e) => setFormData({ ...formData, client_wechat: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black font-mono"
                        />
                      </div>

                      <div className="sm:col-span-2">
                        <label className="block text-xs font-semibold text-slate-700 mb-1 flex items-center space-x-1">
                          <Mail className="w-3.5 h-3.5 text-blue-500" />
                          <span>客户商务电子邮箱</span>
                        </label>
                        <input
                          type="email"
                          placeholder="contact@client-domain.com"
                          value={formData.client_email}
                          onChange={(e) => setFormData({ ...formData, client_email: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black font-mono"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Project Basic Overrides */}
                  <div className="bg-white rounded-2xl p-5 border border-[#e5e1d8] shadow-2xs space-y-4">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">
                      项目属性与技术规格
                    </h3>
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          网站与项目名称
                        </label>
                        <input
                          type="text"
                          value={formData.name}
                          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                        />
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          归档阶段状态
                        </label>
                        <select
                          value={formData.status}
                          onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black font-bold"
                        >
                          <option value="in_progress">🚀 进行中</option>
                          <option value="delivered">✅ 已交付完工</option>
                          <option value="infrastructure">🛠 基础建设</option>
                          <option value="inactive">⏸ 已暂停/挂了</option>
                        </select>
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          技术框架
                        </label>
                        <input
                          type="text"
                          value={formData.framework}
                          onChange={(e) => setFormData({ ...formData, framework: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                        />
                      </div>

                      <div className="sm:col-span-3">
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          线上网址 URL
                        </label>
                        <input
                          type="url"
                          value={formData.url}
                          placeholder="https://example.com"
                          onChange={(e) => setFormData({ ...formData, url: e.target.value })}
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs font-mono text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                        />
                      </div>

                      <div className="sm:col-span-3">
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          项目需求及商务备忘
                        </label>
                        <textarea
                          rows={2}
                          value={formData.description}
                          onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                          placeholder="记录该网站的业务模式、设计风格要求、交付范围..."
                          className="w-full px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 2: Finance & Payments */}
              {activeTab === 'finance' && (
                <div className="space-y-5 animate-in fade-in duration-100">
                  {/* Financial KPI Dashboard Cards */}
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5">
                    <div className="bg-white rounded-2xl p-4 border border-[#e5e1d8] shadow-2xs">
                      <span className="text-[11px] font-semibold text-slate-500">成交总金额</span>
                      <div className="text-2xl font-black font-mono text-slate-900 mt-1">
                        ¥{total.toLocaleString()}
                      </div>
                      <span className="text-[10px] text-slate-400">合同约定全款</span>
                    </div>

                    <div className="bg-white rounded-2xl p-4 border border-[#e5e1d8] shadow-2xs">
                      <span className="text-[11px] font-semibold text-slate-500">已约定定金</span>
                      <div className="text-2xl font-black font-mono text-amber-600 mt-1">
                        ¥{deposit.toLocaleString()}
                      </div>
                      <span className="text-[10px] text-slate-400">预付/启动款</span>
                    </div>

                    <div className="bg-white rounded-2xl p-4 border border-[#e5e1d8] shadow-2xs bg-rose-50/40">
                      <span className="text-[11px] font-semibold text-rose-800">未收款项</span>
                      <div className="text-2xl font-black font-mono text-rose-600 mt-1">
                        ¥{unpaid.toLocaleString()}
                      </div>
                      <span className="text-[10px] text-rose-700">待收结算余款</span>
                    </div>

                    <div className="bg-white rounded-2xl p-4 border border-[#e5e1d8] shadow-2xs bg-emerald-50/40">
                      <span className="text-[11px] font-semibold text-emerald-800">已结算收款</span>
                      <div className="text-2xl font-black font-mono text-emerald-600 mt-1">
                        ¥{paid.toLocaleString()}
                      </div>
                      <span className="text-[10px] text-emerald-700">累计已到账</span>
                    </div>
                  </div>

                  {/* Financial Form Fields */}
                  <div className="bg-white rounded-2xl p-5 border border-[#e5e1d8] shadow-2xs space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 flex items-center space-x-1.5">
                        <CreditCard className="w-4 h-4 text-slate-600" />
                        <span>合同款项录入与未收核算</span>
                      </h3>
                      <span className="text-[11px] text-slate-400 hidden sm:inline">
                        未收款根据总金额与定金自动核算，支持手动修改
                      </span>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          成交总金额 (元)
                        </label>
                        <div className="relative">
                          <span className="absolute left-3 top-2 text-slate-400 text-xs font-mono">¥</span>
                          <input
                            type="number"
                            min="0"
                            step="100"
                            value={formData.total_amount}
                            onChange={(e) => handleTotalAmountChange(e.target.value)}
                            placeholder="0"
                            className="w-full pl-7 pr-3 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs font-mono font-bold text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                          />
                        </div>
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-700 mb-1">
                          首期定金 (元)
                        </label>
                        <div className="relative">
                          <span className="absolute left-3 top-2 text-slate-400 text-xs font-mono">¥</span>
                          <input
                            type="number"
                            min="0"
                            step="100"
                            value={formData.deposit_amount}
                            onChange={(e) => handleDepositAmountChange(e.target.value)}
                            placeholder="0"
                            className="w-full pl-7 pr-3 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs font-mono font-bold text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                          />
                        </div>
                      </div>

                      <div>
                        <div className="flex items-center justify-between mb-1">
                          <label className="block text-xs font-semibold text-slate-700">
                            未收款 (元)
                          </label>
                          <button
                            type="button"
                            onClick={() => {
                              const t = parseFloat(formData.total_amount) || 0;
                              const d = parseFloat(formData.deposit_amount) || 0;
                              handleUnpaidAmountChange(Math.max(0, t - d));
                            }}
                            className="text-[10px] text-indigo-600 hover:text-indigo-800 hover:underline font-medium"
                            title="根据【成交总金额 - 首期定金】自动重算"
                          >
                            按差额重算
                          </button>
                        </div>
                        <div className="relative">
                          <span className="absolute left-3 top-2 text-rose-500 text-xs font-mono font-bold">¥</span>
                          <input
                            type="number"
                            min="0"
                            step="100"
                            value={formData.unpaid_amount !== undefined ? formData.unpaid_amount : unpaid}
                            onChange={(e) => handleUnpaidAmountChange(e.target.value)}
                            placeholder="自动核算或手动输入"
                            className="w-full pl-7 pr-3 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs font-mono font-bold text-rose-700 focus:bg-white focus:ring-2 focus:ring-black"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Progress Bar */}
                    <div className="pt-2">
                      <div className="flex items-center justify-between text-xs font-semibold text-slate-600 mb-1.5">
                        <span>收款完成进度</span>
                        <span>{total > 0 ? Math.round((paid / total) * 100) : 0}%</span>
                      </div>
                      <div className="w-full h-3 bg-[#ede9e3] rounded-full overflow-hidden">
                        <div
                          className="h-full bg-emerald-500 rounded-full transition-all duration-300"
                          style={{ width: `${total > 0 ? Math.min(100, Math.round((paid / total) * 100)) : 0}%` }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB 3: Assets & Credentials */}
              {activeTab === 'assets' && (
                <div className="space-y-4 animate-in fade-in duration-100">
                  <div className="bg-white rounded-2xl p-5 border border-[#e5e1d8] shadow-2xs space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 flex items-center space-x-1.5">
                        <KeyRound className="w-4 h-4 text-slate-600" />
                        <span>网站资产、域名、服务器与后台账号密码</span>
                      </h3>
                      <button
                        type="button"
                        onClick={() => handleCopy(formData.assets_credentials, 'assets')}
                        className="flex items-center space-x-1 text-xs text-slate-600 hover:text-black font-bold px-2.5 py-1 bg-[#f6f4f0] rounded-full transition"
                      >
                        {copiedKey === 'assets' ? (
                          <>
                            <Check className="w-3.5 h-3.5 text-emerald-600" />
                            <span>已复制全文本</span>
                          </>
                        ) : (
                          <>
                            <Copy className="w-3.5 h-3.5" />
                            <span>一键复制全部凭证</span>
                          </>
                        )}
                      </button>
                    </div>

                    <p className="text-xs text-slate-500 leading-relaxed">
                      请在此记录该项目的域名解析提供商（Cloudflare/阿里/Godaddy）、服务器SSH、宝塔面板、WordPress后台、Stripe/PayPal支付密钥等敏感资产信息。数据完全本地持久化在您的 Mac 中。
                    </p>

                    <textarea
                      rows={10}
                      value={formData.assets_credentials}
                      onChange={(e) => setFormData({ ...formData, assets_credentials: e.target.value })}
                      placeholder={`【网站后台】\n后台地址: https://example.com/wp-admin\n账号: admin\n密码: ••••••••\n\n【域名解析 Cloudflare】\n账号: client@gmail.com\n密码: ••••••••\n\n【服务器 / 宝塔面板】\nIP: 192.168.1.1\nSSH端口: 22\n账号: root / 密码: ••••••••`}
                      className="w-full px-4 py-3 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs font-mono text-slate-900 leading-relaxed focus:bg-white focus:ring-2 focus:ring-black"
                    />
                  </div>
                </div>
              )}

              {/* TAB 4: Follow-up Timeline */}
              {activeTab === 'follow_ups' && (
                <div className="space-y-5 animate-in fade-in duration-100">
                  {/* Add Follow-up Form */}
                  <div className="bg-white rounded-2xl p-4 border border-[#e5e1d8] shadow-2xs space-y-3">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 flex items-center space-x-1.5">
                      <Plus className="w-4 h-4 text-slate-600" />
                      <span>新增一条跟进沟通记录</span>
                    </h3>

                    <form onSubmit={handleAddFollowUp} className="space-y-3">
                      <div className="flex items-center space-x-2">
                        <select
                          value={followUpType}
                          onChange={(e) => setFollowUpType(e.target.value)}
                          className="px-3 py-1.5 bg-[#f6f4f0] border border-[#ebe7de] rounded-full text-xs font-bold text-slate-700"
                        >
                          <option value="note">📝 备忘记录</option>
                          <option value="call">📞 电话沟通</option>
                          <option value="meeting">🤝 视频会议</option>
                          <option value="payment">💰 催款/到账</option>
                          <option value="milestone">🏁 阶段交付</option>
                        </select>
                        <span className="text-[11px] text-slate-400">选择跟进类型</span>
                      </div>

                      <div className="flex items-start space-x-2">
                        <textarea
                          rows={2}
                          required
                          value={newFollowUp}
                          onChange={(e) => setNewFollowUp(e.target.value)}
                          placeholder="例如：今天与客户确认了首页横幅设计与多语言切换方案，预计周五前交付演示版..."
                          className="flex-1 px-3.5 py-2 bg-[#f6f4f0] border border-[#ebe7de] rounded-xl text-xs text-slate-900 focus:bg-white focus:ring-2 focus:ring-black"
                        />
                        <button
                          type="submit"
                          disabled={addingFollowUp}
                          className="px-4 py-2 bg-black hover:bg-slate-800 text-[#eefb40] rounded-xl text-xs font-bold shadow-xs transition shrink-0"
                        >
                          {addingFollowUp ? '保存中...' : '提交记录'}
                        </button>
                      </div>
                    </form>
                  </div>

                  {/* Follow-up Timeline List */}
                  <div className="space-y-3">
                    <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">
                      历史跟进时间线 ({project?.follow_ups?.length || 0})
                    </h3>

                    {(!project?.follow_ups || project.follow_ups.length === 0) ? (
                      <div className="bg-white rounded-2xl p-8 text-center text-slate-400 text-xs border border-[#e5e1d8]">
                        暂无任何跟进记录，可在上方添加第一条客户沟通纪要
                      </div>
                    ) : (
                      project.follow_ups.map((item) => (
                        <div
                          key={item.id}
                          className="bg-white rounded-2xl p-4 border border-[#e5e1d8] shadow-2xs space-y-1.5 group hover:border-slate-300 transition"
                        >
                          <div className="flex items-center justify-between text-xs">
                            <div className="flex items-center space-x-2">
                              <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-[#f6f4f0] text-slate-800 border border-[#e5e1d8]">
                                {item.type === 'call' ? '📞 电话' : item.type === 'meeting' ? '🤝 会议' : item.type === 'payment' ? '💰 款项' : item.type === 'milestone' ? '🏁 里程碑' : '📝 备忘'}
                              </span>
                              <span className="text-[11px] font-mono text-slate-400">
                                {new Date(item.created_at).toLocaleString('zh-CN')}
                              </span>
                            </div>
                            <button
                              onClick={() => handleDeleteFollowUp(item.id)}
                              className="opacity-0 group-hover:opacity-100 text-slate-400 hover:text-rose-600 p-1 rounded transition"
                              title="删除记录"
                            >
                              <Trash2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                          <p className="text-xs text-slate-800 leading-relaxed whitespace-pre-wrap pl-1">
                            {item.content}
                          </p>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}
            </>
          )}
        </div>

        {/* Modal Bottom Action Bar */}
        <div className="p-3.5 sm:p-4 bg-white border-t border-zinc-100 flex items-center justify-between shrink-0">
          <div className="text-[11px] text-zinc-400 font-normal">
            修改将自动保存到本地 SQLite 数据库
          </div>

          <div className="flex items-center space-x-2">
            <button
              type="button"
              onClick={onClose}
              className="px-3 py-1.5 bg-zinc-100 hover:bg-zinc-200/80 text-zinc-600 rounded-lg text-xs font-medium transition"
            >
              关闭
            </button>
            <button
              type="button"
              onClick={handleSave}
              disabled={saving}
              className={`px-4 py-1.5 rounded-lg text-xs font-medium shadow-xs transition flex items-center space-x-1.5 active:scale-95 ${
                saveSuccess
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'bg-zinc-950 hover:bg-zinc-800 text-white'
              }`}
            >
              {saveSuccess ? (
                <>
                  <Check className="w-3.5 h-3.5 text-white" />
                  <span>已保存！</span>
                </>
              ) : (
                <>
                  <Save className="w-3.5 h-3.5" />
                  <span>{saving ? '正在保存...' : '保存档案'}</span>
                </>
              )}
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
