const API_BASE = '/api';

export const api = {
  // Projects
  async getProjects() {
    const res = await fetch(`${API_BASE}/projects`);
    return await res.json();
  },
  async createProject(data) {
    const res = await fetch(`${API_BASE}/projects`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await res.json();
  },
  async updateProject(id, data) {
    const res = await fetch(`${API_BASE}/projects/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await res.json();
  },
  async deleteProject(id) {
    const res = await fetch(`${API_BASE}/projects/${id}`, { method: 'DELETE' });
    return await res.json();
  },

  // Tasks
  async getTasks(params = {}) {
    const query = new URLSearchParams(params).toString();
    const res = await fetch(`${API_BASE}/tasks?${query}`);
    return await res.json();
  },
  async createTask(data) {
    const res = await fetch(`${API_BASE}/tasks`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await res.json();
  },
  async updateTask(id, data) {
    const res = await fetch(`${API_BASE}/tasks/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await res.json();
  },
  async deleteTask(id) {
    const res = await fetch(`${API_BASE}/tasks/${id}`, { method: 'DELETE' });
    return await res.json();
  },

  // AI Chat
  async sendAiMessage(message) {
    const res = await fetch(`${API_BASE}/ai/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message })
    });
    return await res.json();
  },
  async getAiHistory() {
    const res = await fetch(`${API_BASE}/ai/history`);
    return await res.json();
  },
  async clearAiHistory() {
    const res = await fetch(`${API_BASE}/ai/history`, { method: 'DELETE' });
    return await res.json();
  },

  // Sync
  async getSyncStatus() {
    const res = await fetch(`${API_BASE}/sync/status`);
    return await res.json();
  },
  async triggerSync() {
    const res = await fetch(`${API_BASE}/sync/now`, { method: 'POST' });
    return await res.json();
  },
  async getSyncLogs() {
    const res = await fetch(`${API_BASE}/sync/logs`);
    return await res.json();
  },

  // Reminders Lists & Settings
  async getRemindersLists() {
    const res = await fetch(`${API_BASE}/reminders/lists`);
    return await res.json();
  },
  async getSettings() {
    const res = await fetch(`${API_BASE}/settings`);
    return await res.json();
  },
  async updateSettings(data) {
    const res = await fetch(`${API_BASE}/settings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await res.json();
  },

  // Client Websites
  async getWebsites(params = {}) {
    const query = new URLSearchParams(params).toString();
    const res = await fetch(`${API_BASE}/websites?${query}`);
    return await res.json();
  },
  async scanWebsites(baseDir) {
    const res = await fetch(`${API_BASE}/websites/scan`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ baseDir })
    });
    return await res.json();
  },
  async updateWebsite(id, data) {
    const res = await fetch(`${API_BASE}/websites/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    });
    return await res.json();
  },
  async getWebsiteDetail(id) {
    const res = await fetch(`${API_BASE}/websites/${id}`);
    return await res.json();
  },
  async addFollowUp(websiteId, content, type = 'note') {
    const res = await fetch(`${API_BASE}/websites/${websiteId}/follow-ups`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ content, type })
    });
    return await res.json();
  },
  async deleteFollowUp(followUpId) {
    const res = await fetch(`${API_BASE}/websites/follow-ups/${followUpId}`, {
      method: 'DELETE'
    });
    return await res.json();
  },
  async openLocalWebsite(path) {
    const res = await fetch(`${API_BASE}/websites/open-local`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ path })
    });
    return await res.json();
  },
  async openEditorWebsite(path) {
    const res = await fetch(`${API_BASE}/websites/open-editor`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ path })
    });
    return await res.json();
  },
  async getWebsiteServices() {
    const res = await fetch(`${API_BASE}/website-services`);
    return await res.json();
  },
  async addWebsiteService(name) {
    const res = await fetch(`${API_BASE}/website-services`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name })
    });
    return await res.json();
  },
  async deleteWebsiteService(name) {
    const res = await fetch(`${API_BASE}/website-services/${encodeURIComponent(name)}`, {
      method: 'DELETE'
    });
    return await res.json();
  }
};
