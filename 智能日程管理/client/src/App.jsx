import React, { useState, useEffect, useCallback } from 'react';
import Sidebar from './components/Sidebar';
import TopHeader from './components/TopHeader';
import KanbanView from './components/KanbanView';
import CalendarView from './components/CalendarView';
import ProjectsView from './components/ProjectsView';
import AiChatView from './components/AiChatView';
import SyncLogsView from './components/SyncLogsView';
import SettingsView from './components/SettingsView';
import ClientWebsitesView from './components/ClientWebsitesView';
import TaskModal from './components/TaskModal';
import FloatingAiBar from './components/FloatingAiBar';
import WebsiteDetailModal from './components/WebsiteDetailModal';
import { api } from './api';

export default function App() {
  const [currentTab, setCurrentTab] = useState('websites'); // Default or user choice
  const [tasks, setTasks] = useState([]);
  const [projects, setProjects] = useState([]);
  const [websites, setWebsites] = useState([]);
  const [syncStatus, setSyncStatus] = useState(null);
  const [syncLogs, setSyncLogs] = useState([]);
  const [settings, setSettings] = useState(null);
  const [availableLists, setAvailableLists] = useState([]);
  const [aiHistory, setAiHistory] = useState([]);
  const [globalSearch, setGlobalSearch] = useState('');

  const [isSyncing, setIsSyncing] = useState(false);
  const [isAiProcessing, setIsAiProcessing] = useState(false);
  const [isScanningWebsites, setIsScanningWebsites] = useState(false);

  // Modal State
  const [isTaskModalOpen, setIsTaskModalOpen] = useState(false);
  const [editingTask, setEditingTask] = useState(null);
  const [aiOpenedWebsiteId, setAiOpenedWebsiteId] = useState(null);

  // Load initial data
  const loadData = useCallback(async () => {
    try {
      const [tasksRes, projectsRes, statusRes, logsRes, settingsRes, listsRes, websitesRes] = await Promise.all([
        api.getTasks(),
        api.getProjects(),
        api.getSyncStatus(),
        api.getSyncLogs(),
        api.getSettings(),
        api.getRemindersLists(),
        api.getWebsites()
      ]);

      if (tasksRes.success) setTasks(tasksRes.data);
      if (projectsRes.success) setProjects(projectsRes.data);
      if (statusRes.success) setSyncStatus(statusRes.data);
      if (logsRes.success) setSyncLogs(logsRes.data);
      if (settingsRes.success) setSettings(settingsRes.data);
      if (listsRes.success) setAvailableLists(listsRes.data);
      if (websitesRes.success) setWebsites(websitesRes.data);
    } catch (err) {
      console.error('[Error loading data]:', err);
    }
  }, []);

  const loadAiHistory = useCallback(async () => {
    try {
      const res = await api.getAiHistory();
      if (res.success) setAiHistory(res.data);
    } catch (e) {
      console.error('[Error loading AI history]:', e);
    }
  }, []);

  useEffect(() => {
    loadData();
    loadAiHistory();

    // Auto refresh data every 8s to catch background reverse sync changes
    const timer = setInterval(() => {
      loadData();
    }, 8000);

    return () => clearInterval(timer);
  }, [loadData, loadAiHistory]);

  // Task Handlers
  const handleTaskStatusChange = async (taskId, newStatus) => {
    try {
      const res = await api.updateTask(taskId, { status: newStatus });
      if (res.success) {
        setTasks((prev) => prev.map((t) => (t.id === taskId ? res.data : t)));
        loadData();
      }
    } catch (e) {
      console.error('[Error updating task status]:', e);
    }
  };

  const handleOpenNewTask = () => {
    setEditingTask(null);
    setIsTaskModalOpen(true);
  };

  const handleEditTask = (task) => {
    setEditingTask(task);
    setIsTaskModalOpen(true);
  };

  const handleSaveTask = async (formData) => {
    try {
      if (editingTask) {
        const res = await api.updateTask(editingTask.id, formData);
        if (res.success) {
          setTasks((prev) => prev.map((t) => (t.id === editingTask.id ? res.data : t)));
        }
      } else {
        const res = await api.createTask(formData);
        if (res.success) {
          setTasks((prev) => [res.data, ...prev]);
        }
      }
      setIsTaskModalOpen(false);
      loadData();
    } catch (e) {
      console.error('[Error saving task]:', e);
    }
  };

  const handleDeleteTask = async (taskId) => {
    if (!window.confirm('确定要删除此任务吗？关联的 Mac 提醒事项也将一并移除。')) return;
    try {
      await api.deleteTask(taskId);
      setTasks((prev) => prev.filter((t) => t.id !== taskId));
      loadData();
    } catch (e) {
      console.error('[Error deleting task]:', e);
    }
  };

  // AI Prompt Handlers
  const handleGlobalAiCommand = async (text) => {
    setIsAiProcessing(true);
    try {
      const res = await api.sendAiMessage(text);
      if (res.success) {
        await loadData();
        loadAiHistory();
      }
      return res;
    } catch (e) {
      console.error('[Global AI Error]:', e);
      throw e;
    } finally {
      setIsAiProcessing(false);
    }
  };

  const handleQuickAiInput = async (text) => {
    setIsAiProcessing(true);
    try {
      const res = await api.sendAiMessage(text);
      if (res.success) {
        loadData();
        loadAiHistory();
      }
    } catch (e) {
      console.error('[AI Quick Input Error]:', e);
    } finally {
      setIsAiProcessing(false);
    }
  };

  const handleSendAiMessage = async (text) => {
    setIsAiProcessing(true);
    try {
      const res = await api.sendAiMessage(text);
      if (res.success) {
        loadData();
        loadAiHistory();
      }
    } catch (e) {
      console.error('[AI Message Error]:', e);
    } finally {
      setIsAiProcessing(false);
    }
  };

  const handleClearAiHistory = async () => {
    if (!window.confirm('确定要清空与 AI 助手的对话记录吗？')) return;
    try {
      await api.clearAiHistory();
      setAiHistory([]);
    } catch (e) {
      console.error('[Error clearing history]:', e);
    }
  };

  // Sync Trigger
  const handleTriggerSync = async () => {
    setIsSyncing(true);
    try {
      await api.triggerSync();
      await loadData();
    } catch (e) {
      console.error('[Sync Error]:', e);
    } finally {
      setTimeout(() => setIsSyncing(false), 500);
    }
  };

  // Project Handlers
  const handleSaveProject = async (formData, id) => {
    try {
      if (id) {
        await api.updateProject(id, formData);
      } else {
        await api.createProject(formData);
      }
      loadData();
    } catch (e) {
      console.error('[Error saving project]:', e);
    }
  };

  const handleDeleteProject = async (id) => {
    if (!window.confirm('确定要删除该项目分类吗？')) return;
    try {
      await api.deleteProject(id);
      loadData();
    } catch (e) {
      console.error('[Error deleting project]:', e);
    }
  };

  // Settings Handlers
  const handleSaveSettings = async (formData) => {
    try {
      await api.updateSettings(formData);
      loadData();
    } catch (e) {
      console.error('[Error saving settings]:', e);
    }
  };

  // Website Handlers
  const handleScanWebsites = async () => {
    setIsScanningWebsites(true);
    try {
      const res = await api.scanWebsites();
      if (res.success) setWebsites(res.data);
    } catch (e) {
      console.error('[Error scanning websites]:', e);
    } finally {
      setIsScanningWebsites(false);
    }
  };

  const handleUpdateWebsite = async (id, data) => {
    try {
      if (data && data.id === id && data.updated_at) {
        setWebsites((prev) => prev.map((w) => (w.id === id ? data : w)));
        loadData();
        return;
      }
      const res = await api.updateWebsite(id, data);
      if (res.success) {
        setWebsites((prev) => prev.map((w) => (w.id === id ? res.data : w)));
        loadData();
      }
    } catch (e) {
      console.error('[Error updating website]:', e);
    }
  };

  const handleOpenLocalWebsite = async (localPath) => {
    return await api.openLocalWebsite(localPath);
  };

  const handleOpenEditorWebsite = async (localPath) => {
    return await api.openEditorWebsite(localPath);
  };

  return (
    <div className="h-screen w-screen bg-[#f7f7f8] text-zinc-900 flex overflow-hidden font-sans selection:bg-zinc-900 selection:text-white">
      {/* Native macOS window drag strip */}
      <div className="fixed top-0 left-0 right-0 h-8 z-50 select-none [app-region:drag] pointer-events-none" />

      {/* Fixed Left Sidebar (Codex Desktop Minimalist style) */}
      <Sidebar
        currentTab={currentTab}
        setCurrentTab={setCurrentTab}
        projects={projects}
        websiteCount={websites.length}
        tasksCount={tasks.length}
        syncStatus={syncStatus}
        onTriggerSync={handleTriggerSync}
        isSyncing={isSyncing}
      />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 h-screen relative overflow-hidden bg-[#f7f7f8]">
        {/* Scrollable Viewport (pb-24 reserves comfortable space for the bottom floating AI bar) */}
        <div className="flex-1 overflow-y-auto px-6 lg:px-9 pt-7 pb-28 flex flex-col">
          <TopHeader
            currentTab={currentTab}
            onOpenNewTask={handleOpenNewTask}
            syncStatus={syncStatus}
            isSyncing={isSyncing}
            onTriggerSync={handleTriggerSync}
            searchQuery={globalSearch}
            setSearchQuery={setGlobalSearch}
            tasksCount={tasks.length}
            websiteCount={websites.length}
          />

          <main className="flex-1">
            {currentTab === 'kanban' && (
              <KanbanView
                tasks={tasks}
                projects={projects}
                onTaskStatusChange={handleTaskStatusChange}
                onEditTask={handleEditTask}
                onDeleteTask={handleDeleteTask}
                onOpenNewTask={handleOpenNewTask}
                onQuickAiInput={handleQuickAiInput}
                isAiProcessing={isAiProcessing}
              />
            )}

            {currentTab === 'calendar' && (
              <CalendarView
                tasks={tasks}
                onTaskStatusChange={handleTaskStatusChange}
                onEditTask={handleEditTask}
              />
            )}

            {currentTab === 'projects' && (
              <ProjectsView
                projects={projects}
                onSaveProject={handleSaveProject}
                onDeleteProject={handleDeleteProject}
              />
            )}

            {currentTab === 'websites' && (
              <ClientWebsitesView
                websites={websites}
                onScanWebsites={handleScanWebsites}
                onUpdateWebsite={handleUpdateWebsite}
                onOpenLocal={handleOpenLocalWebsite}
                onOpenEditor={handleOpenEditorWebsite}
                isScanning={isScanningWebsites}
              />
            )}

            {currentTab === 'ai' && (
              <AiChatView
                history={aiHistory}
                onSendMessage={handleSendAiMessage}
                onClearHistory={handleClearAiHistory}
                isProcessing={isAiProcessing}
                onSwitchToKanban={() => setCurrentTab('kanban')}
              />
            )}

            {currentTab === 'sync' && (
              <SyncLogsView
                syncStatus={syncStatus}
                logs={syncLogs}
                isSyncing={isSyncing}
                onTriggerSync={handleTriggerSync}
                availableLists={availableLists}
              />
            )}

            {currentTab === 'settings' && (
              <SettingsView
                settings={settings}
                onSaveSettings={handleSaveSettings}
                availableLists={availableLists}
              />
            )}
          </main>
        </div>

        {/* Floating AI Command Bar (Pinned at Bottom across views, hidden on dedicated AI chat tab) */}
        {currentTab !== 'ai' && (
          <FloatingAiBar
            onSendCommand={handleGlobalAiCommand}
            isProcessing={isAiProcessing}
            onOpenWebsiteDetail={(id) => setAiOpenedWebsiteId(id)}
            onNavigateTab={(tab) => setCurrentTab(tab)}
          />
        )}
      </div>

      {/* Task Creation & Edit Modal */}
      <TaskModal
        isOpen={isTaskModalOpen}
        onClose={() => setIsTaskModalOpen(false)}
        onSave={handleSaveTask}
        task={editingTask}
        projects={projects}
      />

      {/* Detail Modal opened from Floating AI Bar */}
      {aiOpenedWebsiteId && (
        <WebsiteDetailModal
          websiteId={aiOpenedWebsiteId}
          isOpen={Boolean(aiOpenedWebsiteId)}
          onClose={() => setAiOpenedWebsiteId(null)}
          onUpdated={(updated) => {
            handleUpdateWebsite(updated.id, updated);
          }}
          onOpenLocal={handleOpenLocalWebsite}
          onOpenEditor={handleOpenEditorWebsite}
        />
      )}
    </div>
  );
}
