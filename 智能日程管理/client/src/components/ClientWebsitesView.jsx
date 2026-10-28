import React, { useState, useMemo } from 'react';
import {
  Globe,
  ExternalLink,
  FolderOpen,
  Code2,
  RefreshCw,
  Search,
  CheckCircle2,
  Archive,
  Layers,
  Edit3,
  X,
  Copy,
  Check,
  ChevronDown,
  ChevronRight,
  Boxes,
  List,
  Target,
  DollarSign,
  Wallet,
  Clock,
  TrendingUp,
  Pencil,
  Calendar
} from 'lucide-react';
import WebsiteDetailModal from './WebsiteDetailModal';

export default function ClientWebsitesView({
  websites,
  onScanWebsites,
  onUpdateWebsite,
  onOpenLocal,
  onOpenEditor,
  isScanning
}) {
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState('grouped'); // 'grouped' or 'flat'
  const [expandedGroups, setExpandedGroups] = useState({}); // Default all collapsed
  const [selectedDetailId, setSelectedDetailId] = useState(null); // Detail modal target id
  const [editingItem, setEditingItem] = useState(null);
  const [copiedId, setCopiedId] = useState(null);
  const [actionFeedback, setActionFeedback] = useState(null);

  // Annual Target Amount State (persisted to localStorage)
  const [annualTarget, setAnnualTarget] = useState(() => {
    const saved = localStorage.getItem('website_annual_target');
    return saved ? parseFloat(saved) || 1000000 : 1000000;
  });
  const [isEditingTarget, setIsEditingTarget] = useState(false);
  const [targetInput, setTargetInput] = useState('');

  const handleStartEditTarget = (e) => {
    e.stopPropagation();
    setTargetInput(annualTarget.toString());
    setIsEditingTarget(true);
  };

  const handleSaveTarget = (e) => {
    e.preventDefault();
    const val = parseFloat(targetInput);
    if (!isNaN(val) && val >= 0) {
      setAnnualTarget(val);
      localStorage.setItem('website_annual_target', val.toString());
    }
    setIsEditingTarget(false);
  };

  // Edit form state
  const [formData, setFormData] = useState({
    name: '',
    url: '',
    status: 'delivered',
    category: '已交付',
    framework: 'HTML/CSS',
    description: ''
  });

  const getSiteGroup = (item) => {
    const url = (item.url || '').toLowerCase();
    const name = (item.name || '').toLowerCase();
    const path = (item.local_path || '').toLowerCase();

    if (url.includes('nordicbeyondtravel.com') || name.includes('nordic') || path.includes('nordic')) {
      return {
        key: 'nordic',
        brand: 'Nordic Beyond (北欧超越旅行)',
        subTitle: '跨项目整合（包含：测试版后台、超越旅行、冰岛定制）',
        canonicalUrl: 'https://nordicbeyondtravel.com/'
      };
    }
    if (name.includes('miracle') || path.includes('miracle')) {
      return {
        key: 'miracle',
        brand: 'Miracle Logistics (奇迹物流)',
        subTitle: '跨项目整合（包含：物流主站、克隆系统）',
        canonicalUrl: ''
      };
    }
    if (url.includes('zovlux') || name.includes('高仿鞋子') || name.includes('zovlux')) {
      return {
        key: 'zovlux',
        brand: 'ZOVLUX 潮鞋独立站',
        subTitle: 'Luxury Sneakers & Streetwear Atelier',
        canonicalUrl: 'https://tryzovlux.com/'
      };
    }
    if (name.includes('南驰') || url.includes('oxlion')) {
      return {
        key: 'oxlion',
        brand: '南驰新能源 (Oxlion)',
        subTitle: '北京惟尔鑫商贸 / 海外官网',
        canonicalUrl: 'https://www.oxlion.hk/'
      };
    }
    if (name.includes('ww') || url.includes('wwinsights')) {
      return {
        key: 'ww',
        brand: 'WW Insights Global',
        subTitle: '全球行业智库与出海咨询',
        canonicalUrl: 'https://wwinsightsglobal.com/'
      };
    }
    if (name.includes('fomosa') || url.includes('fomosa')) {
      return {
        key: 'fomosa',
        brand: 'FOMOSA (斯图加特)',
        subTitle: '斯图加特餐饮与品牌独立站',
        canonicalUrl: 'https://www.fomosastuttgart.com/'
      };
    }
    if (name.includes('创兴') || url.includes('cxedgeband')) {
      return {
        key: 'cxedgeband',
        brand: '北京创兴塑胶制品',
        subTitle: 'CX Edgeband 现代家具封边条官网',
        canonicalUrl: 'https://cxedgeband.com/'
      };
    }
    if (name.includes('冰箱贴') || url.includes('frozendecor')) {
      return {
        key: 'frozendecor',
        brand: 'Frozen Decor (冰箱贴定制)',
        subTitle: '文创礼品与海外家居定制平台',
        canonicalUrl: 'https://frozendecor.com/'
      };
    }
    if (name.includes('木马谣') || url.includes('momasong')) {
      return {
        key: 'momasong',
        brand: '木马谣泳衣 (Momasong)',
        subTitle: '跨境泳装独立品牌 Shopify 站',
        canonicalUrl: 'https://momasong.com'
      };
    }
    if (name.includes('gongly') || url.includes('gongly')) {
      return {
        key: 'gongly',
        brand: 'Gongly 冰淇淋机',
        subTitle: '商用制冷与冰淇淋机品牌外贸官网',
        canonicalUrl: 'https://gongly.com'
      };
    }
    if (name.includes('trailnxt') || url.includes('trailnxt')) {
      return {
        key: 'trailnxt',
        brand: 'Trailnxt 户外探险',
        subTitle: '越野探险与户外越野装备品牌站',
        canonicalUrl: 'https://trailnxt.com'
      };
    }
    if (name.includes('mgoo') || url.includes('mgoofashion') || path.includes('mgoo')) {
      return {
        key: 'mgoo',
        brand: 'MGOO 服装柔性定制',
        subTitle: '服装柔性供应链与跨境定制官网',
        canonicalUrl: 'https://mgoofashion.com/'
      };
    }
    if (name.includes('积木') || url.includes('rbrickstem')) {
      return {
        key: 'rbrickstem',
        brand: '积木 (RBrick STEM)',
        subTitle: '智能积木与机器人教育平台',
        canonicalUrl: 'https://rbrickstem.com/'
      };
    }
    if (name.toLowerCase().includes('hopeseed') || url.includes('hopeseed')) {
      return {
        key: 'hopeseed',
        brand: 'HopeSeed Wellness',
        subTitle: 'HopeSeed 滋补健康与海外个护独立站',
        canonicalUrl: 'https://www.hopeseedwellness.com/'
      };
    }
    if (name.toLowerCase().includes('sunwin') || name.includes('晟源') || url.includes('sunwin')) {
      return {
        key: 'sunwin',
        brand: '深圳晟源 (SUNWIN)',
        subTitle: '晟源科技外贸官网与高精产品目录',
        canonicalUrl: 'https://sunwin-global.com/'
      };
    }
    if (name.includes('重庆云') || name.includes('云昇') || name.includes('云晟') || url.includes('looooook.net')) {
      return {
        key: 'looooook',
        brand: '重庆云昇传媒 (Looooook)',
        subTitle: '重庆云昇传媒 / 每日看点新媒体平台',
        canonicalUrl: 'https://looooook.net/'
      };
    }
    if (name.toLowerCase().includes('lumihair') || url.includes('lumihair')) {
      return {
        key: 'lumihair',
        brand: 'Lumihair 假发美发独立站',
        subTitle: '假发定制与时尚美发跨境独立站',
        canonicalUrl: 'https://lumihairshop.com/'
      };
    }
    if (name.includes('宥森') || url.includes('yoosenly')) {
      return {
        key: 'yoosenly',
        brand: '宥森贸易 (Yoosenly)',
        subTitle: '宥森贸易进出口与跨境供应链官网',
        canonicalUrl: 'https://yoosenly.com/'
      };
    }
    if (name.toLowerCase().includes('jamc') || url.includes('jamcjewelry')) {
      return {
        key: 'jamcjewelry',
        brand: 'JAMC Jewelry (美国珠宝独立站)',
        subTitle: '美国轻奢珠宝与高定首饰品牌海外官网',
        canonicalUrl: 'https://jamcjewelry.com/'
      };
    }

    // Fallback domain
    if (url && !url.includes('your-custom') && !url.includes('your-domain')) {
      const domainMatch = url.match(/^https?:\/\/(?:www\.)?([^\/]+)/);
      if (domainMatch) {
        return {
          key: domainMatch[1],
          brand: item.name,
          subTitle: item.description || domainMatch[1],
          canonicalUrl: url
        };
      }
    }

    return {
      key: 'proj_' + item.id,
      brand: item.name,
      subTitle: item.description || '',
      canonicalUrl: item.url || ''
    };
  };

  // Financial KPI Metrics
  const financialStats = useMemo(() => {
    let totalDeal = 0;
    let totalPaid = 0;
    let totalUnpaid = 0;
    let contractedCount = 0;
    let unpaidCount = 0;

    for (const w of websites) {
      const total = parseFloat(w.total_amount) || 0;
      const deposit = parseFloat(w.deposit_amount) || 0;
      let unpaid = parseFloat(w.unpaid_amount);
      if (isNaN(unpaid) || unpaid === null || unpaid === undefined) {
        unpaid = Math.max(0, total - deposit);
      }
      const paid = w.paid_amount !== undefined && w.paid_amount !== null ? (parseFloat(w.paid_amount) || 0) : Math.max(0, total - unpaid);

      if (total > 0) {
        contractedCount++;
      }
      if (unpaid > 0) {
        unpaidCount++;
      }

      totalDeal += total;
      totalPaid += paid;
      totalUnpaid += unpaid;
    }

    const avgDeal = contractedCount > 0 ? Math.round(totalDeal / contractedCount) : 0;
    const collectionRate = totalDeal > 0 ? Math.min(100, Math.round((totalPaid / totalDeal) * 100)) : 0;
    const targetProgress = annualTarget > 0 ? Number(((totalDeal / annualTarget) * 100).toFixed(1)) : 0;
    const targetPaidProgress = annualTarget > 0 ? Number(((totalPaid / annualTarget) * 100).toFixed(1)) : 0;

    return {
      totalDeal,
      totalPaid,
      totalUnpaid,
      contractedCount,
      unpaidCount,
      avgDeal,
      collectionRate,
      targetProgress,
      targetPaidProgress
    };
  }, [websites, annualTarget]);

  // Grouped and filtered structure
  const groupedData = useMemo(() => {
    const q = searchQuery.toLowerCase();
    const map = new Map();

    for (const item of websites) {
      // Filter status
      const matchesStatus =
        selectedStatus === 'all'
          ? true
          : selectedStatus === 'unpaid'
          ? ((parseFloat(item.unpaid_amount) || 0) > 0 || (parseFloat(item.total_amount) || 0) - (parseFloat(item.paid_amount) || 0) > 0)
          : item.status === selectedStatus;
      if (!matchesStatus) continue;

      // Filter query
      const matchesSearch =
        !q ||
        item.name.toLowerCase().includes(q) ||
        (item.url && item.url.toLowerCase().includes(q)) ||
        (item.description && item.description.toLowerCase().includes(q)) ||
        (item.framework && item.framework.toLowerCase().includes(q));

      if (!matchesSearch) continue;

      const groupMeta = getSiteGroup(item);
      if (!map.has(groupMeta.key)) {
        map.set(groupMeta.key, {
          key: groupMeta.key,
          brand: groupMeta.brand,
          subTitle: groupMeta.subTitle,
          canonicalUrl: groupMeta.canonicalUrl,
          items: []
        });
      }

      const group = map.get(groupMeta.key);
      if (!group.canonicalUrl && item.url) group.canonicalUrl = item.url;
      group.items.push(item);
    }

    const getGroupStatusRank = (items) => {
      // If group has any in_progress, it ranks as 1 (进行中)
      if (items.some((it) => it.status === 'in_progress')) return 1;
      // If group has delivered, it ranks as 2 (已交付)
      if (items.some((it) => it.status === 'delivered')) return 2;
      // Infrastructure ranks as 3
      if (items.some((it) => it.status === 'infrastructure')) return 3;
      // Inactive / paused always last
      return 99;
    };

    return Array.from(map.values()).sort((a, b) => {
      // 1. Strict status rank: 进行中 (1) -> 已交付 (2) -> 基础建设 (3) -> 已暂停 (99)
      const rankA = getGroupStatusRank(a.items);
      const rankB = getGroupStatusRank(b.items);
      if (rankA !== rankB) {
        return rankA - rankB;
      }

      // 2. Alphabetical by brand name within same status tier
      return a.brand.localeCompare(b.brand, 'zh-Hans-CN');
    });
  }, [websites, selectedStatus, searchQuery]);

  // Flat list filtered
  const flatFiltered = useMemo(() => {
    const q = searchQuery.toLowerCase();
    const statusPriority = (status) => {
      switch (status) {
        case 'in_progress':
          return 1;
        case 'delivered':
          return 2;
        case 'infrastructure':
          return 3;
        case 'inactive':
          return 99; // Inactive always last
        default:
          return 50;
      }
    };

    return websites
      .filter((w) => {
        const matchesStatus =
          selectedStatus === 'all'
            ? true
            : selectedStatus === 'unpaid'
            ? ((parseFloat(w.unpaid_amount) || 0) > 0 || (parseFloat(w.total_amount) || 0) - (parseFloat(w.paid_amount) || 0) > 0)
            : w.status === selectedStatus;
        const matchesSearch =
          !q ||
          w.name.toLowerCase().includes(q) ||
          (w.url && w.url.toLowerCase().includes(q)) ||
          (w.description && w.description.toLowerCase().includes(q)) ||
          (w.framework && w.framework.toLowerCase().includes(q));
        return matchesStatus && matchesSearch;
      })
      .sort((a, b) => {
        const prioA = statusPriority(a.status);
        const prioB = statusPriority(b.status);
        if (prioA !== prioB) return prioA - prioB;
        return a.name.localeCompare(b.name, 'zh-Hans-CN');
      });
  }, [websites, selectedStatus, searchQuery]);

  // Status counts
  const countInProgress = websites.filter((w) => w.status === 'in_progress').length;
  const countDelivered = websites.filter((w) => w.status === 'delivered').length;
  const countInfra = websites.filter((w) => w.status === 'infrastructure').length;
  const countInactive = websites.filter((w) => w.status === 'inactive').length;

  const toggleGroup = (key) => {
    setExpandedGroups((prev) => ({
      ...prev,
      [key]: !prev[key]
    }));
  };

  const handleOpenEdit = (item) => {
    setEditingItem(item);
    setFormData({
      name: item.name || '',
      url: item.url || '',
      status: item.status || 'delivered',
      category: item.category || '已交付',
      framework: item.framework || 'HTML/CSS',
      description: item.description || ''
    });
  };

  const handleSaveEdit = (e) => {
    e.preventDefault();
    if (!editingItem) return;

    let cat = formData.category;
    if (formData.status === 'in_progress') cat = '进行中';
    else if (formData.status === 'delivered') cat = '已交付';
    else if (formData.status === 'infrastructure') cat = '功能基础建设';
    else if (formData.status === 'inactive') cat = '已暂停/挂了';

    onUpdateWebsite(editingItem.id, { ...formData, category: cat });
    setEditingItem(null);
  };

  const handleCopyUrl = (url, id) => {
    if (!url) return;
    navigator.clipboard.writeText(url);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 1800);
  };

  const handleTriggerOpenLocal = async (localPath, name) => {
    try {
      await onOpenLocal(localPath);
      setActionFeedback(`已在访达中打开: ${name}`);
      setTimeout(() => setActionFeedback(null), 2500);
    } catch (e) {
      console.error(e);
    }
  };

  const handleTriggerOpenEditor = async (localPath, name) => {
    try {
      await onOpenEditor(localPath);
      setActionFeedback(`正在编辑器中打开: ${name}`);
      setTimeout(() => setActionFeedback(null), 2500);
    } catch (e) {
      console.error(e);
    }
  };

  const getInitials = (name) => {
    if (!name) return 'WS';
    const clean = name.replace(/[^a-zA-Z0-9\u4e00-\u9fa5]/g, '');
    if (clean.length <= 2) return clean.toUpperCase();
    return clean.slice(0, 2).toUpperCase();
  };

  const renderStatusPill = (status) => {
    if (status === 'in_progress') {
      return (
        <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-amber-50 text-amber-700 border border-amber-200">
          <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse" />
          <span>进行中</span>
        </span>
      );
    }
    if (status === 'delivered') {
      return (
        <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
          <CheckCircle2 className="w-3 h-3 text-emerald-600" />
          <span>已交付</span>
        </span>
      );
    }
    if (status === 'infrastructure') {
      return (
        <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-indigo-50 text-indigo-700 border border-indigo-200">
          <Layers className="w-3 h-3 text-indigo-600" />
          <span>基础建设</span>
        </span>
      );
    }
    return (
      <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[11px] font-medium bg-zinc-100 text-zinc-500 border border-zinc-200">
        <Archive className="w-3 h-3" />
        <span>已暂停</span>
      </span>
    );
  };

  /**
   * Helper to style the circular avatar button at the front of each project:
   * Clean, subtle neutral-tinted styling for Codex Desktop aesthetic
   */
  const getStatusCircleStyle = (status) => {
    switch (status) {
      case 'in_progress':
        return 'bg-amber-50 text-amber-700 border border-amber-200 shadow-xs hover:border-amber-300';
      case 'delivered':
        return 'bg-emerald-50 text-emerald-700 border border-emerald-200 shadow-xs hover:border-emerald-300';
      case 'inactive':
        return 'bg-zinc-100 text-zinc-500 border border-zinc-200 shadow-xs hover:border-zinc-300';
      case 'infrastructure':
      default:
        return 'bg-indigo-50 text-indigo-700 border border-indigo-200 shadow-xs hover:border-indigo-300';
    }
  };

  /**
   * Helper to compute badge status for service period
   */
  const getServiceDurationBadge = (startStr, endStr) => {
    if (!endStr) {
      if (startStr) return { label: '生效中', className: 'bg-blue-50 text-blue-700 border border-blue-200' };
      return null;
    }
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    const end = new Date(endStr);
    end.setHours(0, 0, 0, 0);
    const diffDays = Math.round((end - now) / (1000 * 60 * 60 * 24));
    if (diffDays < 0) {
      return { label: `逾期 ${Math.abs(diffDays)} 天`, className: 'bg-rose-50 text-rose-700 border border-rose-200' };
    }
    if (diffDays === 0) {
      return { label: '今日到期', className: 'bg-amber-50 text-amber-700 border border-amber-200' };
    }
    if (diffDays <= 30) {
      return { label: `剩 ${diffDays} 天`, className: 'bg-amber-50 text-amber-800 border border-amber-200' };
    }
    return { label: `剩 ${diffDays} 天`, className: 'bg-emerald-50 text-emerald-700 border border-emerald-200' };
  };

  const renderSingleRow = (item, isSubItem = false) => {
    return (
      <tr
        key={item.id}
        className={`hover:bg-zinc-50/80 transition-colors group ${
          isSubItem ? 'bg-zinc-50/30' : 'bg-white'
        }`}
      >
        {/* Column 1: Website Name with Initial Circular Avatar Button */}
        <td className={`py-3 px-3.5 ${isSubItem ? 'pl-8' : ''}`}>
          <div className="flex items-center space-x-3">
            {isSubItem ? (
              <button
                type="button"
                onClick={() => setSelectedDetailId(item.id)}
                title={`状态: ${item.status} (点击查看项目档案)`}
                className={`w-6 h-6 rounded-full flex items-center justify-center font-bold text-[10px] shrink-0 transition hover:scale-105 active:scale-95 ${getStatusCircleStyle(
                  item.status
                )}`}
              >
                ↳
              </button>
            ) : (
              <button
                type="button"
                onClick={() => setSelectedDetailId(item.id)}
                title={`状态: ${
                  item.status === 'in_progress'
                    ? '进行中'
                    : item.status === 'delivered'
                    ? '已交付'
                    : '已暂停'
                } (点击查看项目档案)`}
                className={`w-9 h-9 rounded-full flex items-center justify-center font-black text-xs shrink-0 transition hover:scale-105 active:scale-95 ${getStatusCircleStyle(
                  item.status
                )}`}
              >
                {getInitials(item.name)}
              </button>
            )}
            <div className="space-y-0.5 min-w-0">
              <div className="flex items-center space-x-1.5 flex-wrap">
                <button
                  type="button"
                  onClick={() => setSelectedDetailId(item.id)}
                  title="点击打开项目详情与客户CRM档案"
                  className="font-bold text-sm text-slate-900 hover:text-indigo-600 hover:underline text-left flex items-center space-x-1.5 group/btn"
                >
                  <span className="truncate">{item.name}</span>
                  <span className="opacity-0 group-hover/btn:opacity-100 text-[10px] px-1.5 py-0.2 rounded-full bg-indigo-50 text-indigo-600 font-normal shrink-0">
                    详情
                  </span>
                </button>
              </div>

              {item.description && (
                <p className="text-[11px] text-slate-500 line-clamp-1 max-w-xs">
                  {item.description}
                </p>
              )}
            </div>
          </div>
        </td>

        {/* Column 2: Ordered Services (原本技术栈位置显示订购项目) */}
        <td className="py-3 px-3">
          {Array.isArray(item.services) && item.services.length > 0 ? (
            <div className="flex items-center space-x-1 flex-wrap gap-y-1">
              {item.services.map((srv) => {
                let badgeClass = "bg-[#f4f1ea] text-slate-700 border-[#e2ded6]";
                if (srv.includes('SEO') || srv.includes('GEO')) {
                  badgeClass = "bg-emerald-50 text-emerald-800 border-emerald-200";
                } else if (srv.includes('搭建') || srv.includes('网站')) {
                  badgeClass = "bg-blue-50 text-blue-800 border-blue-200";
                } else if (srv.includes('上网') || srv.includes('科学')) {
                  badgeClass = "bg-purple-50 text-purple-800 border-purple-200";
                }
                return (
                  <span
                    key={srv}
                    className={`inline-flex items-center text-[10px] font-bold px-2 py-0.5 rounded-full border shadow-2xs whitespace-nowrap ${badgeClass}`}
                  >
                    {srv}
                  </span>
                );
              })}
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setSelectedDetailId(item.id)}
              className="text-[11px] text-slate-300 hover:text-slate-600 transition"
              title="点击设置订购项目"
            >
              未设置
            </button>
          )}
        </td>

        {/* Column 3: Live Website Link */}
        <td className="py-3 px-3">
          {item.url ? (
            <div className="flex items-center space-x-1.5">
              <a
                href={item.url}
                target="_blank"
                rel="noreferrer"
                className="text-xs text-blue-600 hover:text-blue-800 hover:underline font-mono truncate max-w-[180px] font-medium"
                title={item.url}
              >
                {item.url.replace(/^https?:\/\//, '')}
              </a>
              <button
                onClick={() => handleCopyUrl(item.url, item.id)}
                className="p-1 text-slate-400 hover:text-slate-700 rounded transition"
                title="复制网址"
              >
                {copiedId === item.id ? (
                  <Check className="w-3.5 h-3.5 text-emerald-600" />
                ) : (
                  <Copy className="w-3.5 h-3.5" />
                )}
              </button>
            </div>
          ) : (
            <button
              onClick={() => handleOpenEdit(item)}
              className="text-[11px] text-slate-400 hover:text-slate-800 border border-dashed border-slate-300 px-2 py-0.5 rounded-full transition"
            >
              + 添加网址
            </button>
          )}
        </td>

        {/* Column 4: Local Path Buttons */}
        <td className="py-3 px-3">
          <div className="flex items-center space-x-1.5">
            <button
              onClick={() => handleTriggerOpenLocal(item.local_path, item.name)}
              className="flex items-center space-x-1 px-2.5 py-1 bg-white hover:bg-[#f6f4f0] text-slate-800 rounded-full text-[11px] font-bold border border-[#e2ded6] shadow-2xs transition"
              title="在访达中高亮打开此目录"
            >
              <FolderOpen className="w-3 h-3 text-indigo-600" />
              <span>访达</span>
            </button>

            <button
              onClick={() => handleTriggerOpenEditor(item.local_path, item.name)}
              className="flex items-center space-x-1 px-2.5 py-1 bg-white hover:bg-[#f6f4f0] text-slate-800 rounded-full text-[11px] font-bold border border-[#e2ded6] shadow-2xs transition"
              title="在代码编辑器中打开"
            >
              <Code2 className="w-3 h-3 text-slate-600" />
              <span>IDE</span>
            </button>
          </div>
        </td>

        {/* Column 5: Status Pill */}
        <td className="py-3 px-3 whitespace-nowrap">
          {renderStatusPill(item.status)}
        </td>

        {/* Column 6: Service Duration (Default remaining days, hover to view start & end dates) */}
        <td className="py-3 px-3 whitespace-nowrap text-xs">
          {item.service_start_date || item.service_end_date ? (
            (() => {
              const badge = getServiceDurationBadge(item.service_start_date, item.service_end_date);
              const dateRangeText = (item.service_start_date && item.service_end_date)
                ? `${item.service_start_date} ~ ${item.service_end_date}`
                : (item.service_start_date ? `自 ${item.service_start_date} 起生效` : `至 ${item.service_end_date} 截止`);

              return (
                <div className="relative group/duration inline-flex items-center">
                  <button
                    type="button"
                    onClick={() => setSelectedDetailId(item.id)}
                    className={`inline-flex items-center space-x-1.5 px-2.5 py-1 rounded-full text-xs font-mono font-bold transition-all shadow-2xs hover:shadow-xs hover:scale-105 cursor-pointer ${
                      badge ? badge.className : 'bg-slate-100 text-slate-700'
                    }`}
                    title={`服务时间: ${dateRangeText} (点击编辑)`}
                  >
                    <Clock className="w-3 h-3 shrink-0" />
                    <span>{badge ? badge.label : '未定期限'}</span>
                  </button>

                  {/* Hover Tooltip: Show Start and End Dates */}
                  <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover/duration:flex flex-col items-center z-50 pointer-events-none animate-in fade-in zoom-in-95 duration-150">
                    <div className="bg-slate-900 text-white text-[11px] font-mono font-medium px-2.5 py-1.5 rounded-lg shadow-xl whitespace-nowrap flex items-center space-x-1.5 border border-slate-700">
                      <Calendar className="w-3 h-3 text-[#eefb40]" />
                      <span>{dateRangeText}</span>
                    </div>
                    <div className="w-2 h-2 bg-slate-900 rotate-45 -mt-1 border-r border-b border-slate-700" />
                  </div>
                </div>
              );
            })()
          ) : (
            <button
              type="button"
              onClick={() => setSelectedDetailId(item.id)}
              className="text-[11px] text-slate-300 hover:text-slate-600 transition"
              title="点击设置服务时间"
            >
              未设置
            </button>
          )}
        </td>

        {/* Column 7: Total Deal Amount */}
        <td className="py-3 px-3 whitespace-nowrap font-mono text-xs">
          {parseFloat(item.total_amount) > 0 ? (
            <span className="font-bold text-slate-900">
              ¥{parseFloat(item.total_amount).toLocaleString()}
            </span>
          ) : (
            <span className="text-slate-300 font-sans">-</span>
          )}
        </td>

        {/* Column 7: Deposit Amount */}
        <td className="py-3 px-3 whitespace-nowrap font-mono text-xs">
          {parseFloat(item.deposit_amount) > 0 ? (
            <span className="text-slate-600 font-semibold">
              ¥{parseFloat(item.deposit_amount).toLocaleString()}
            </span>
          ) : (
            <span className="text-slate-300 font-sans">-</span>
          )}
        </td>

        {/* Column 8: Unpaid Balance */}
        <td className="py-3 px-3 whitespace-nowrap font-mono text-xs">
          {(() => {
            const total = parseFloat(item.total_amount) || 0;
            const deposit = parseFloat(item.deposit_amount) || 0;
            const unpaid =
              item.unpaid_amount !== undefined && item.unpaid_amount !== null
                ? parseFloat(item.unpaid_amount)
                : Math.max(0, total - deposit);

            if (total > 0 && unpaid <= 0) {
              return (
                <span className="inline-flex items-center px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-[#eef7ec] text-[#2c6e26] border border-[#d5ead1]">
                  已结清
                </span>
              );
            }
            if (unpaid > 0) {
              return (
                <span className="font-bold text-[#b45309]">
                  ¥{unpaid.toLocaleString()}
                </span>
              );
            }
            return <span className="text-slate-300 font-sans">-</span>;
          })()}
        </td>

        {/* Column 10: Tech Framework (移动到后面) */}
        <td className="py-3 px-3 whitespace-nowrap">
          <span className="px-2 py-0.5 rounded-md text-[10px] font-semibold bg-[#f4f1ea] text-slate-700 border border-[#e5e1d8]">
            {item.framework || 'HTML/CSS'}
          </span>
        </td>

        {/* Column 11: Edit Action with circular border */}
        <td className="py-3 px-3 text-right pr-4 whitespace-nowrap">
          <button
            type="button"
            onClick={() => setSelectedDetailId(item.id)}
            className="w-8 h-8 rounded-full border border-[#dcd7cb] hover:border-black bg-white hover:bg-[#f6f4f0] text-slate-600 hover:text-black inline-flex items-center justify-center transition shadow-2xs hover:shadow-xs active:scale-95"
            title="查看与编辑项目财务CRM档案"
          >
            <Edit3 className="w-3.5 h-3.5" />
          </button>
        </td>
      </tr>
    );
  };

  return (
    <div className="space-y-4">
      {/* Top Bento Financial KPI Cards (Sticky Top Container) */}
      <div className="sticky top-0 z-30 pt-1 pb-3 bg-[#f7f7f8]/95 backdrop-blur-md transition-all">
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
          {/* Card 1: 年度目标金额 */}
          <div className="p-3.5 rounded-xl bg-zinc-950 text-white border border-zinc-800 shadow-xs flex flex-col justify-between transition-all">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-1.5">
                <Target className="w-3.5 h-3.5 text-zinc-300" />
                <span className="text-[11px] font-medium text-zinc-300">年度目标金额</span>
              </div>
              <button
                onClick={handleStartEditTarget}
                className="p-1 rounded-md text-zinc-400 hover:text-white hover:bg-zinc-800 transition"
                title="设定/修改年度目标"
              >
                <Pencil className="w-3 h-3" />
              </button>
            </div>

            <div className="mt-1">
              {isEditingTarget ? (
                <form onSubmit={handleSaveTarget} className="flex items-center space-x-1 my-0.5">
                  <span className="text-xs font-mono text-zinc-400">¥</span>
                  <input
                    type="number"
                    autoFocus
                    value={targetInput}
                    onChange={(e) => setTargetInput(e.target.value)}
                    className="w-24 px-1.5 py-0.5 bg-zinc-800 text-white text-xs font-mono rounded border border-zinc-700 focus:outline-none focus:ring-1 focus:ring-zinc-400"
                  />
                  <button type="submit" className="px-1.5 py-0.5 bg-white text-black text-[10px] font-medium rounded">
                    存
                  </button>
                  <button type="button" onClick={() => setIsEditingTarget(false)} className="px-1 py-0.5 text-zinc-400 text-[10px]">
                    ✕
                  </button>
                </form>
              ) : (
                <div className="text-xl sm:text-2xl font-semibold font-mono tracking-tight text-white flex items-baseline">
                  <span className="text-xs text-zinc-400 mr-0.5 font-normal">¥</span>
                  <span>{annualTarget.toLocaleString()}</span>
                </div>
              )}
            </div>

            <div className="mt-1.5">
              <div className="flex items-center justify-between text-[10px] text-zinc-400 mb-1 font-mono">
                <span>签约达成</span>
                <span className="text-zinc-200 font-medium">{financialStats.targetProgress}%</span>
              </div>
              <div className="w-full h-1.5 bg-zinc-800 rounded-full overflow-hidden">
                <div
                  className="h-full bg-white rounded-full transition-all duration-500"
                  style={{ width: `${Math.min(100, Math.max(0, financialStats.targetProgress))}%` }}
                />
              </div>
            </div>
          </div>

          {/* Card 2: 已成交总金额 */}
          <div
            onClick={() => setSelectedStatus('all')}
            className={`p-3.5 rounded-xl transition-all flex flex-col justify-between cursor-pointer ${
              selectedStatus === 'all'
                ? 'bg-white border-2 border-zinc-900 shadow-sm'
                : 'bg-white border border-zinc-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)] hover:border-zinc-300'
            }`}
            title="点击查看全部项目"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-1.5">
                <DollarSign className="w-3.5 h-3.5 text-zinc-500" />
                <span className="text-[11px] font-medium text-zinc-600">已成交总金额</span>
              </div>
              <span className="text-[10px] font-mono text-zinc-500 bg-zinc-100 px-1.5 py-0.2 rounded border border-zinc-200">
                {financialStats.contractedCount} 签约
              </span>
            </div>

            <div className="mt-1">
              <div className="text-xl sm:text-2xl font-semibold font-mono tracking-tight text-zinc-950 flex items-baseline">
                <span className="text-xs text-zinc-400 mr-0.5 font-normal">¥</span>
                <span>{financialStats.totalDeal.toLocaleString()}</span>
              </div>
            </div>

            <div className="text-[10px] text-zinc-400 font-mono mt-1 truncate">
              均单 ¥{financialStats.avgDeal.toLocaleString()}
            </div>
          </div>

          {/* Card 3: 实际已收款项 */}
          <div className="p-3.5 rounded-xl bg-white border border-zinc-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)] hover:border-zinc-300 transition-all flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-1.5">
                <Wallet className="w-3.5 h-3.5 text-emerald-600" />
                <span className="text-[11px] font-medium text-zinc-700">实际已收款项</span>
              </div>
              <span className="text-[10px] font-mono text-emerald-700 bg-emerald-50 px-1.5 py-0.2 rounded border border-emerald-200 font-medium">
                回款 {financialStats.collectionRate}%
              </span>
            </div>

            <div className="mt-1">
              <div className="text-xl sm:text-2xl font-semibold font-mono tracking-tight text-zinc-950 flex items-baseline">
                <span className="text-xs text-zinc-400 mr-0.5 font-normal">¥</span>
                <span>{financialStats.totalPaid.toLocaleString()}</span>
              </div>
            </div>

            <div className="text-[10px] text-zinc-400 font-mono mt-1 truncate">
              累计定金与阶段款项到账
            </div>
          </div>

          {/* Card 4: 未收金额 / 尾款 */}
          <div
            onClick={() => setSelectedStatus(selectedStatus === 'unpaid' ? 'all' : 'unpaid')}
            className={`p-3.5 rounded-xl transition-all flex flex-col justify-between cursor-pointer ${
              selectedStatus === 'unpaid'
                ? 'bg-amber-50/50 border-2 border-amber-600 shadow-sm'
                : 'bg-white border border-zinc-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)] hover:border-zinc-300'
            }`}
            title="点击筛选待收尾款项目"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-1.5">
                <Clock className="w-3.5 h-3.5 text-amber-600" />
                <span className="text-[11px] font-medium text-zinc-700">待收尾款金额</span>
              </div>
              <span className="text-[10px] font-mono text-amber-800 bg-amber-50 px-1.5 py-0.2 rounded border border-amber-200">
                {financialStats.unpaidCount} 待回款
              </span>
            </div>

            <div className="mt-1">
              <div className="text-xl sm:text-2xl font-semibold font-mono tracking-tight text-amber-700 flex items-baseline">
                <span className="text-xs text-amber-600 mr-0.5 font-normal">¥</span>
                <span>{financialStats.totalUnpaid.toLocaleString()}</span>
              </div>
            </div>

            <div className="text-[10px] text-zinc-400 font-mono mt-1 truncate">
              {selectedStatus === 'unpaid' ? '已筛选待收尾款 (点击重置)' : '点击筛选待回款客户'}
            </div>
          </div>

          {/* Card 5: 结清率与概况 */}
          <div className="p-3.5 rounded-xl bg-white border border-zinc-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.02)] hover:border-zinc-300 transition-all flex flex-col justify-between">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-1.5">
                <TrendingUp className="w-3.5 h-3.5 text-zinc-600" />
                <span className="text-[11px] font-medium text-zinc-600">回款结清率</span>
              </div>
              <span className="text-[10px] font-mono text-zinc-500 bg-zinc-100 px-1.5 py-0.2 rounded border border-zinc-200">
                {websites.length} 档案
              </span>
            </div>

            <div className="mt-1">
              <div className="text-xl sm:text-2xl font-semibold font-mono tracking-tight text-zinc-950">
                {financialStats.collectionRate}
                <span className="text-xs text-zinc-400 ml-0.5 font-normal">%</span>
              </div>
            </div>

            <div className="text-[10px] text-zinc-400 font-mono mt-1 truncate flex items-center space-x-1.5">
              <span>进行中 {countInProgress}</span>
              <span>•</span>
              <span>已交付 {countDelivered}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Main Table Card */}
      <div className="bg-white border border-zinc-200/90 rounded-xl p-4 shadow-[0_1px_2px_rgba(0,0,0,0.02)] space-y-3.5">
        {/* Table Top Controls */}
        <div className="space-y-2.5 pb-2.5 border-b border-zinc-100">
          {/* Row 1: Status Filter Segmented Controls & Action Buttons */}
          <div className="flex items-center justify-between flex-wrap gap-2">
            <div className="flex items-center flex-wrap gap-1">
              {[
                { id: 'all', label: '全部项目', count: websites.length },
                { id: 'in_progress', label: '进行中', count: countInProgress },
                { id: 'delivered', label: '已交付', count: countDelivered },
                { id: 'infrastructure', label: '基础建设', count: countInfra },
                { id: 'inactive', label: '已暂停', count: countInactive },
                { id: 'unpaid', label: '待收尾款', count: financialStats.unpaidCount, isAmber: true }
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setSelectedStatus(tab.id)}
                  className={`px-2.5 py-1 rounded-lg text-xs font-medium transition flex items-center space-x-1.5 ${
                    selectedStatus === tab.id
                      ? 'bg-zinc-950 text-white shadow-xs'
                      : 'bg-zinc-50 text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100 border border-zinc-200/70'
                  }`}
                >
                  <span>{tab.label}</span>
                  <span
                    className={`text-[10px] px-1 py-0.2 rounded font-mono ${
                      selectedStatus === tab.id
                        ? 'bg-white/20 text-white'
                        : 'text-zinc-400'
                    }`}
                  >
                    {tab.count}
                  </span>
                </button>
              ))}
            </div>

            <div className="flex items-center space-x-2">
              {actionFeedback && (
                <span className="text-xs text-zinc-900 font-medium flex items-center space-x-1 bg-emerald-50 text-emerald-800 border border-emerald-200 px-2.5 py-1 rounded-md animate-fade-in">
                  <Check className="w-3 h-3 text-emerald-600" />
                  <span>{actionFeedback}</span>
                </span>
              )}

              <button
                onClick={() => handleTriggerOpenLocal('/Users/ky/Desktop/定制网站-客户版', '客户定制网站主目录')}
                className="px-2.5 py-1 bg-white hover:bg-zinc-50 text-zinc-700 rounded-lg text-xs font-medium border border-zinc-200/90 shadow-[0_1px_2px_rgba(0,0,0,0.02)] transition flex items-center space-x-1.5"
              >
                <FolderOpen className="w-3.5 h-3.5 text-zinc-500" />
                <span>打开主目录</span>
              </button>

              <button
                onClick={onScanWebsites}
                disabled={isScanning}
                className="px-2.5 py-1 bg-zinc-950 hover:bg-zinc-800 disabled:opacity-40 text-white rounded-lg text-xs font-medium shadow-xs transition flex items-center space-x-1.5"
              >
                <RefreshCw className={`w-3 h-3 ${isScanning ? 'animate-spin' : ''}`} />
                <span>{isScanning ? '扫描中...' : '重新扫描'}</span>
              </button>
            </div>
          </div>

          {/* Row 2: Search Input & View Switcher */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2.5 pt-0.5">
            <div className="flex items-center space-x-2.5 w-full sm:w-auto">
              <div className="relative flex-1 sm:w-72">
                <Search className="w-3.5 h-3.5 text-zinc-400 absolute left-2.5 top-2" />
                <input
                  type="text"
                  placeholder="搜索客户、网站名称、域名、技术栈..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-8 pr-3 py-1 bg-zinc-50 border border-zinc-200/80 rounded-lg text-xs text-zinc-900 placeholder-zinc-400 focus:outline-none focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                />
              </div>

              {/* View Mode Switcher */}
              <div className="flex items-center bg-zinc-100 p-0.5 rounded-lg border border-zinc-200/70">
                <button
                  onClick={() => setViewMode('grouped')}
                  className={`flex items-center space-x-1 px-2.5 py-1 rounded-md text-xs font-medium transition ${
                    viewMode === 'grouped'
                      ? 'bg-white text-zinc-950 shadow-xs'
                      : 'text-zinc-500 hover:text-zinc-900'
                  }`}
                  title="按网站品牌聚合归类显示"
                >
                  <Boxes className="w-3 h-3" />
                  <span>品牌归类</span>
                </button>
                <button
                  onClick={() => setViewMode('flat')}
                  className={`flex items-center space-x-1 px-2.5 py-1 rounded-md text-xs font-medium transition ${
                    viewMode === 'flat'
                      ? 'bg-white text-zinc-950 shadow-xs'
                      : 'text-zinc-500 hover:text-zinc-900'
                  }`}
                  title="平铺展开所有独立工程"
                >
                  <List className="w-3 h-3" />
                  <span>全部展开</span>
                </button>
              </div>
            </div>

            <span className="text-xs text-zinc-400 font-mono whitespace-nowrap">
              {viewMode === 'grouped' ? (
                <>
                  共 <strong className="text-zinc-800 font-semibold">{groupedData.length}</strong> 个品牌（
                  <strong className="text-zinc-800 font-semibold">{flatFiltered.length}</strong> 个工程）
                </>
              ) : (
                <>
                  显示 <strong className="text-zinc-800 font-semibold">{flatFiltered.length}</strong> 个项目
                </>
              )}
            </span>
          </div>
        </div>

        {/* Table Rows Container */}
        <div className="overflow-x-auto overflow-y-auto max-h-[calc(100vh-325px)] min-h-[460px] rounded-lg border border-zinc-200/80 shadow-[0_1px_2px_rgba(0,0,0,0.01)] bg-white">
          <table className="w-full text-left border-collapse table-fixed min-w-[1380px]">
            <colgroup>
              <col className="w-[19%]" />
              <col className="w-[13%]" />
              <col className="w-[14%]" />
              <col className="w-[10%]" />
              <col className="w-[7%]" />
              <col className="w-[9%]" />
              <col className="w-[7%]" />
              <col className="w-[7%]" />
              <col className="w-[7%]" />
              <col className="w-[4%]" />
              <col className="w-[3%]" />
            </colgroup>
            <thead className="sticky top-0 z-20 bg-zinc-50 border-b border-zinc-200/80">
              <tr className="text-[11px] font-medium text-zinc-500 uppercase tracking-wider">
                <th className="py-2.5 px-3.5 bg-zinc-50">客户网站与项目</th>
                <th className="py-2.5 px-3 bg-zinc-50">订购服务</th>
                <th className="py-2.5 px-3 bg-zinc-50">线上网址</th>
                <th className="py-2.5 px-3 bg-zinc-50">本地工程</th>
                <th className="py-2.5 px-3 bg-zinc-50">状态</th>
                <th className="py-2.5 px-3 bg-zinc-50">服务期</th>
                <th className="py-2.5 px-3 bg-zinc-50">签约金额</th>
                <th className="py-2.5 px-3 bg-zinc-50">定金</th>
                <th className="py-2.5 px-3 bg-zinc-50">未结</th>
                <th className="py-2.5 px-3 bg-zinc-50">技术栈</th>
                <th className="py-2.5 px-3 text-right pr-4 bg-zinc-50">操作</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-100 text-xs">
              {viewMode === 'grouped' ? (
                groupedData.length === 0 ? (
                  <tr>
                    <td colSpan={11} className="py-12 text-center text-slate-400 text-xs">
                      未检索到符合条件的客户网站项目
                    </td>
                  </tr>
                ) : (
                  groupedData.map((group) => {
                    const isMulti = group.items.length > 1;
                    const isExpanded = Boolean(expandedGroups[group.key]); // Default collapsed

                    if (!isMulti) {
                      // Single item group renders directly
                      return renderSingleRow(group.items[0], false);
                    }

                    // Calculate aggregated finances for multi-project group
                    const groupTotalAmount = group.items.reduce(
                      (sum, i) => sum + (parseFloat(i.total_amount) || 0),
                      0
                    );
                    const groupDepositAmount = group.items.reduce(
                      (sum, i) => sum + (parseFloat(i.deposit_amount) || 0),
                      0
                    );
                    const groupUnpaidAmount = group.items.reduce((sum, i) => {
                      const total = parseFloat(i.total_amount) || 0;
                      const paid = parseFloat(i.paid_amount) || 0;
                      const unpaid =
                        i.unpaid_amount !== undefined && i.unpaid_amount !== null
                          ? parseFloat(i.unpaid_amount)
                          : Math.max(0, total - paid);
                      return sum + unpaid;
                    }, 0);

                    // Aggregated distinct services in this brand group
                    const groupServices = Array.from(
                      new Set(group.items.flatMap((i) => (Array.isArray(i.services) ? i.services : [])))
                    );

                    // Compute overall status for the group row
                    const hasInProgress = group.items.some((i) => i.status === 'in_progress');
                    const allDelivered = group.items.every((i) => i.status === 'delivered');
                    const allInactive = group.items.every((i) => i.status === 'inactive');

                    let groupStatus = 'infrastructure';
                    if (hasInProgress) groupStatus = 'in_progress';
                    else if (allDelivered) groupStatus = 'delivered';
                    else if (allInactive) groupStatus = 'inactive';

                    // Multi-item group header + collapsible children
                    return (
                      <React.Fragment key={'group_' + group.key}>
                        {/* Group summary row (Exactly 10 columns matching thead) */}
                        <tr className="bg-zinc-50/70 border-t border-zinc-200/80 hover:bg-zinc-100/70 transition">
                          {/* Col 1: Brand & Toggle */}
                          <td className="py-3 px-3.5">
                            <div className="flex items-center space-x-3">
                              <button
                                type="button"
                                onClick={() => setSelectedDetailId(group.items[0]?.id)}
                                title={`状态: ${
                                  groupStatus === 'in_progress'
                                    ? '进行中'
                                    : groupStatus === 'delivered'
                                    ? '已交付'
                                    : groupStatus === 'inactive'
                                    ? '已暂停'
                                    : '其它'
                                } (点击查看项目档案)`}
                                className={`w-9 h-9 rounded-full font-black flex items-center justify-center text-xs shrink-0 transition hover:scale-105 active:scale-95 ${getStatusCircleStyle(
                                  groupStatus
                                )}`}
                              >
                                {getInitials(group.brand)}
                              </button>

                              <div className="space-y-0.5 min-w-0">
                                <div className="flex items-center space-x-1.5 flex-wrap">
                                  <button
                                    type="button"
                                    onClick={() => setSelectedDetailId(group.items[0]?.id)}
                                    title="点击查看项目详情档案"
                                    className="font-black text-sm text-slate-900 hover:text-indigo-600 hover:underline tracking-tight truncate text-left"
                                  >
                                    {group.brand}
                                  </button>

                                  {/* 折叠/展开箭头（位于标题后面） */}
                                  <button
                                    type="button"
                                    onClick={() => toggleGroup(group.key)}
                                    className="w-5 h-5 rounded-md bg-[#eae5da] hover:bg-black hover:text-[#eefb40] text-slate-700 flex items-center justify-center transition shrink-0"
                                    title={isExpanded ? '收起归类项目' : '展开归类项目'}
                                  >
                                    {isExpanded ? (
                                      <ChevronDown className="w-3.5 h-3.5" />
                                    ) : (
                                      <ChevronRight className="w-3.5 h-3.5" />
                                    )}
                                  </button>

                                  <span className="px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-[#eefb40] text-black shrink-0">
                                    聚合 {group.items.length} 个
                                  </span>
                                </div>
                                <p className="text-[11px] text-slate-500 font-medium truncate">
                                  {group.subTitle}
                                </p>
                              </div>
                            </div>
                          </td>

                          {/* Col 2: Group Ordered Services (原本技术栈位置显示订购项目) */}
                          <td className="py-3 px-3">
                            {groupServices.length > 0 ? (
                              <div className="flex items-center space-x-1 flex-wrap gap-y-1">
                                {groupServices.map((srv) => {
                                  let badgeClass = "bg-[#f4f1ea] text-slate-700 border-[#e2ded6]";
                                  if (srv.includes('SEO') || srv.includes('GEO')) {
                                    badgeClass = "bg-emerald-50 text-emerald-800 border-emerald-200";
                                  } else if (srv.includes('搭建') || srv.includes('网站')) {
                                    badgeClass = "bg-blue-50 text-blue-800 border-blue-200";
                                  } else if (srv.includes('上网') || srv.includes('科学')) {
                                    badgeClass = "bg-purple-50 text-purple-800 border-purple-200";
                                  }
                                  return (
                                    <span
                                      key={srv}
                                      className={`inline-flex items-center text-[10px] font-bold px-2 py-0.5 rounded-full border shadow-2xs whitespace-nowrap ${badgeClass}`}
                                    >
                                      {srv}
                                    </span>
                                  );
                                })}
                              </div>
                            ) : (
                              <span className="text-slate-300 font-sans">-</span>
                            )}
                          </td>

                          {/* Col 3: Group Canonical URL */}
                          <td className="py-3 px-3">
                            {group.canonicalUrl ? (
                              <div className="flex items-center space-x-1.5">
                                <a
                                  href={group.canonicalUrl}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="text-xs text-blue-600 hover:text-blue-800 hover:underline font-mono truncate max-w-[180px] font-bold"
                                  title={group.canonicalUrl}
                                >
                                  {group.canonicalUrl.replace(/^https?:\/\//, '')}
                                </a>
                                <button
                                  onClick={() => handleCopyUrl(group.canonicalUrl, group.key)}
                                  className="p-1 text-slate-400 hover:text-slate-700 rounded transition shrink-0"
                                  title="复制网址"
                                >
                                  {copiedId === group.key ? (
                                    <Check className="w-3.5 h-3.5 text-emerald-600" />
                                  ) : (
                                    <Copy className="w-3.5 h-3.5" />
                                  )}
                                </button>
                              </div>
                            ) : (
                              <span className="text-[11px] text-slate-400 italic">待分配统一网址</span>
                            )}
                          </td>

                          {/* Col 4: Quick open all / folder count */}
                          <td className="py-3 px-3">
                            <span className="text-[11px] text-slate-600 font-medium">
                              包含 {group.items.length} 处本地工程
                            </span>
                          </td>

                          {/* Col 5: Group Status summary */}
                          <td className="py-3 px-3 whitespace-nowrap">
                            {group.items.some((i) => i.status === 'in_progress') ? (
                              <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-full bg-[#eefb40]/90 text-black text-[10px] font-bold">
                                <span className="w-1.5 h-1.5 rounded-full bg-black animate-pulse" />
                                <span>进行中</span>
                              </span>
                            ) : (
                              <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-full bg-[#eef7ec] text-[#2c6e26] text-[10px] font-bold border border-[#d5ead1]">
                                <CheckCircle2 className="w-3 h-3 text-[#2c6e26]" />
                                <span>已交付</span>
                              </span>
                            )}
                          </td>

                          {/* Col 6: Group Service Period */}
                          <td className="py-3 px-3 whitespace-nowrap text-xs">
                            {(() => {
                              const withDates = group.items.filter((i) => i.service_start_date || i.service_end_date);
                              if (withDates.length === 0) return <span className="text-slate-300 font-sans">-</span>;
                              if (withDates.length === 1) {
                                const item = withDates[0];
                                const badge = getServiceDurationBadge(item.service_start_date, item.service_end_date);
                                const dateRangeText = (item.service_start_date && item.service_end_date)
                                  ? `${item.service_start_date} ~ ${item.service_end_date}`
                                  : (item.service_start_date ? `自 ${item.service_start_date} 起生效` : `至 ${item.service_end_date} 截止`);

                                return (
                                  <div className="relative group/duration inline-flex items-center">
                                    <span
                                      className={`inline-flex items-center space-x-1.5 px-2.5 py-1 rounded-full text-xs font-mono font-bold transition-all shadow-2xs hover:shadow-xs cursor-help ${
                                        badge ? badge.className : 'bg-slate-100 text-slate-700'
                                      }`}
                                      title={`服务时间: ${dateRangeText}`}
                                    >
                                      <Clock className="w-3 h-3 shrink-0" />
                                      <span>{badge ? badge.label : '未定期限'}</span>
                                    </span>

                                    {/* Hover Tooltip: Show Start and End Dates */}
                                    <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover/duration:flex flex-col items-center z-50 pointer-events-none animate-in fade-in zoom-in-95 duration-150">
                                      <div className="bg-slate-900 text-white text-[11px] font-mono font-medium px-2.5 py-1.5 rounded-lg shadow-xl whitespace-nowrap flex items-center space-x-1.5 border border-slate-700">
                                        <Calendar className="w-3 h-3 text-[#eefb40]" />
                                        <span>{dateRangeText}</span>
                                      </div>
                                      <div className="w-2 h-2 bg-slate-900 rotate-45 -mt-1 border-r border-b border-slate-700" />
                                    </div>
                                  </div>
                                );
                              }
                              return (
                                <span className="text-[11px] text-slate-600 font-medium">
                                  {withDates.length} 个项目已设服务期
                                </span>
                              );
                            })()}
                          </td>

                          {/* Col 7: Group Total Amount */}
                          <td className="py-3 px-3 whitespace-nowrap font-mono text-xs">
                            {groupTotalAmount > 0 ? (
                              <span className="font-bold text-slate-900">
                                ¥{groupTotalAmount.toLocaleString()}
                              </span>
                            ) : (
                              <span className="text-slate-300 font-sans">-</span>
                            )}
                          </td>

                          {/* Col 7: Group Deposit Amount */}
                          <td className="py-3 px-3 whitespace-nowrap font-mono text-xs">
                            {groupDepositAmount > 0 ? (
                              <span className="text-slate-600 font-semibold">
                                ¥{groupDepositAmount.toLocaleString()}
                              </span>
                            ) : (
                              <span className="text-slate-300 font-sans">-</span>
                            )}
                          </td>

                          {/* Col 8: Group Unpaid Balance */}
                          <td className="py-3 px-3 whitespace-nowrap font-mono text-xs">
                            {groupTotalAmount > 0 && groupUnpaidAmount <= 0 ? (
                              <span className="inline-flex items-center px-1.5 py-0.5 rounded-full text-[10px] font-bold bg-[#eef7ec] text-[#2c6e26] border border-[#d5ead1]">
                                全部结清
                              </span>
                            ) : groupUnpaidAmount > 0 ? (
                              <span className="font-bold text-[#b45309]">
                                ¥{groupUnpaidAmount.toLocaleString()}
                              </span>
                            ) : (
                              <span className="text-slate-300 font-sans">-</span>
                            )}
                          </td>

                          {/* Col 10: Group Tech summary (移动到后面) */}
                          <td className="py-3 px-3 whitespace-nowrap">
                            <span className="px-2 py-0.5 rounded-md text-[10px] font-semibold bg-[#eae5da] text-slate-700">
                              聚合组
                            </span>
                          </td>

                          {/* Col 11: Action with circular border */}
                          <td className="py-3 px-3 text-right pr-4 whitespace-nowrap">
                            <button
                              type="button"
                              onClick={() => toggleGroup(group.key)}
                              className="w-8 h-8 rounded-full border border-[#dcd7cb] hover:border-black bg-white hover:bg-[#f6f4f0] text-slate-700 hover:text-black inline-flex items-center justify-center transition shadow-2xs hover:shadow-xs active:scale-95"
                              title={isExpanded ? '收起归类项目' : '展开归类项目'}
                            >
                              {isExpanded ? (
                                <ChevronDown className="w-4 h-4" />
                              ) : (
                                <ChevronRight className="w-4 h-4" />
                              )}
                            </button>
                          </td>
                        </tr>

                        {/* Expanded sub-projects */}
                        {isExpanded &&
                          group.items.map((subItem) => renderSingleRow(subItem, true))}
                      </React.Fragment>
                    );
                  })
                )
              ) : (
                // Flat mode
                flatFiltered.length === 0 ? (
                  <tr>
                    <td colSpan={11} className="py-12 text-center text-slate-400 text-xs">
                      未检索到符合条件的客户网站项目
                    </td>
                  </tr>
                ) : (
                  flatFiltered.map((item) => renderSingleRow(item, false))
                )
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Edit Website Modal */}
      {editingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-xs p-4 animate-fade-in">
          <div className="bg-white border border-zinc-200 rounded-2xl w-full max-w-md shadow-[0_20px_50px_rgba(0,0,0,0.15)] p-5 space-y-3.5">
            <div className="flex items-center justify-between pb-2.5 border-b border-zinc-100">
              <div className="flex items-center space-x-2">
                <div className="w-6 h-6 rounded-md bg-zinc-950 text-white flex items-center justify-center font-bold text-xs">
                  <Globe className="w-3.5 h-3.5" />
                </div>
                <h3 className="font-semibold text-zinc-950 text-xs">
                  编辑客户网站档案
                </h3>
              </div>
              <button
                onClick={() => setEditingItem(null)}
                className="text-zinc-400 hover:text-zinc-700 p-1 rounded-md"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleSaveEdit} className="space-y-3">
              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  网站名称
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  线上网址链接
                </label>
                <input
                  type="url"
                  placeholder="https://example.com"
                  value={formData.url}
                  onChange={(e) => setFormData({ ...formData, url: e.target.value })}
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs font-mono focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                    归档阶段
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                    className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:ring-1 focus:ring-zinc-900 focus:bg-white cursor-pointer"
                  >
                    <option value="in_progress">进行中</option>
                    <option value="delivered">已交付完工</option>
                    <option value="infrastructure">基础建设</option>
                    <option value="inactive">已暂停</option>
                  </select>
                </div>

                <div>
                  <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                    技术栈
                  </label>
                  <input
                    type="text"
                    value={formData.framework}
                    onChange={(e) => setFormData({ ...formData, framework: e.target.value })}
                    className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:ring-1 focus:ring-zinc-900 focus:bg-white"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-medium text-zinc-600 mb-1">
                  备注描述
                </label>
                <textarea
                  rows={2}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-3 py-1.5 bg-zinc-50 border border-zinc-200 rounded-lg text-zinc-900 text-xs focus:ring-1 focus:ring-zinc-900 focus:bg-white resize-none"
                />
              </div>

              <div className="flex items-center justify-end space-x-2 pt-2 border-t border-zinc-100">
                <button
                  type="button"
                  onClick={() => setEditingItem(null)}
                  className="px-3 py-1.5 bg-zinc-100 hover:bg-zinc-200/80 text-zinc-600 rounded-lg text-xs font-medium transition"
                >
                  取消
                </button>
                <button
                  type="submit"
                  className="px-3.5 py-1.5 bg-zinc-950 hover:bg-zinc-800 text-white rounded-lg text-xs font-medium shadow-xs transition"
                >
                  保存修改
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Full Customer & Project CRM Detail Modal */}
      <WebsiteDetailModal
        websiteId={selectedDetailId}
        isOpen={Boolean(selectedDetailId)}
        onClose={() => setSelectedDetailId(null)}
        onUpdated={(updatedProject) => {
          if (onUpdateWebsite) {
            onUpdateWebsite(updatedProject.id, updatedProject);
          }
        }}
        onOpenLocal={onOpenLocal}
        onOpenEditor={onOpenEditor}
      />
    </div>
  );
}
