import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { execFile } from 'child_process';
import util from 'util';
import db from './db.js';

const execFileAsync = util.promisify(execFile);

const DEFAULT_BASE_DIR = '/Users/ky/Desktop/定制网站-客户版';

const CATEGORY_MAP = [
  { folder: '进行中', status: 'in_progress', label: '进行中' },
  { folder: '已交付', status: 'delivered', label: '已交付' },
  { folder: '功能基础建设', status: 'infrastructure', label: '功能基础建设' },
  { folder: '挂了', status: 'inactive', label: '已暂停/挂了' }
];

const STANDALONE_PROJECTS = [
  {
    path: '/Users/ky/Desktop/南驰新能源',
    name: '南驰新能源',
    category: '已交付',
    status: 'delivered',
    description: '南驰新能源 / 北京惟尔鑫商贸官网',
    framework: 'React / HTML',
    url: 'https://www.oxlion.hk/'
  },
  {
    path: '/Users/ky/Desktop/高仿鞋子',
    name: '高仿鞋子 (ZOVLUX)',
    category: '已交付',
    status: 'delivered',
    description: 'ZOVLUX | Luxury Sneakers & Streetwear Atelier 潮鞋独立站',
    framework: 'React',
    url: 'https://tryzovlux.com/'
  },
  {
    path: '/Users/ky/Desktop/Gongly',
    name: 'Gongly',
    category: '已交付',
    status: 'delivered',
    description: 'Gongly 冰淇淋机与商用制冷设备品牌官网与海外营销',
    framework: 'React',
    url: 'https://gongly.com'
  },
  {
    path: '/Users/ky/Desktop/网站-重庆云昇',
    name: '网站-重庆云昇',
    category: '已交付',
    status: 'delivered',
    description: '重庆云昇广告传媒有限公司 / 每日看点网站平台',
    framework: 'HTML/CSS',
    url: 'https://looooook.net/'
  },
  {
    path: '/Users/ky/Desktop/Trailnxt',
    name: 'Trailnxt',
    category: '进行中',
    status: 'in_progress',
    description: 'Trailnxt 户外探险与越野装备品牌网站',
    framework: 'React',
    url: 'https://trailnxt.com'
  },
  {
    path: '/Users/ky/Desktop/MGOO',
    name: 'MGOO',
    category: '进行中',
    status: 'in_progress',
    description: 'MGOO 服装柔性供应链与跨境定制官网',
    framework: 'React',
    url: 'https://mgoofashion.com/'
  },
  {
    path: '/Users/ky/Desktop/木马谣泳衣',
    name: '木马谣泳衣 (Momasong)',
    category: '已交付',
    status: 'delivered',
    description: 'Momasong 木马谣独立站与跨境泳装品牌',
    framework: 'Shopify',
    url: 'https://momasong.com'
  },
  {
    path: '/Users/ky/Desktop/深圳晟源',
    name: '深圳晟源 (SUNWIN)',
    category: '已交付',
    status: 'delivered',
    description: 'SUNWIN 晟源科技外贸官网、SEO 与产品目录',
    framework: 'React',
    url: 'https://sunwin-global.com/'
  },
  {
    path: '/Users/ky/Desktop/英摩客网站',
    name: '英摩客网站 (Umccoy)',
    category: '已交付',
    status: 'delivered',
    description: 'Umccoy - Enterprise SSD Supply & Sourcing Partner',
    framework: 'HTML/CSS',
    url: ''
  },
  {
    path: '/Users/ky/Desktop/布料网站',
    name: '布料网站 (Zhanfa Textile)',
    category: '已交付',
    status: 'delivered',
    description: 'Guangzhou Zhanfa Textile | High-Performance Outdoor & Technical Fabrics Manufacturer',
    framework: 'React',
    url: 'https://zhanfatextile.com/'
  }
];

export const websiteService = {
  /**
   * Scan client websites directory and standalone projects, then sync into SQLite
   */
  async scanDirectory(baseDir = DEFAULT_BASE_DIR) {
    const now = new Date().toISOString();
    const scannedProjects = [];

    // Helper to upsert a project
    const upsertProject = (projectData) => {
      const existing = db.prepare(`SELECT * FROM website_projects WHERE local_path = ?`).get(projectData.local_path);
      if (existing) {
        db.prepare(`
          UPDATE website_projects
          SET name = CASE WHEN (name IS NOT NULL AND name != '') THEN name ELSE ? END,
              category = ?,
              status = ?,
              framework = ?,
              last_modified = ?,
              url = CASE WHEN (url IS NULL OR url = '') THEN ? ELSE url END,
              description = CASE WHEN (description IS NULL OR description = '') THEN ? ELSE description END,
              updated_at = ?
          WHERE id = ?
        `).run(
          projectData.name,
          projectData.category,
          projectData.status,
          projectData.framework,
          projectData.last_modified,
          projectData.url,
          projectData.description,
          now,
          existing.id
        );
      } else {
        const id = crypto.randomUUID();
        db.prepare(`
          INSERT INTO website_projects (
            id, name, category, status, local_path, url, framework, description, last_modified, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).run(
          id,
          projectData.name,
          projectData.category,
          projectData.status,
          projectData.local_path,
          projectData.url,
          projectData.framework,
          projectData.description,
          projectData.last_modified,
          now,
          now
        );
      }
      scannedProjects.push(projectData);
    };

    // 1. Scan /Users/ky/Desktop/定制网站-客户版
    if (fs.existsSync(baseDir)) {
      for (const cat of CATEGORY_MAP) {
        const catPath = path.join(baseDir, cat.folder);
        if (!fs.existsSync(catPath) || !fs.statSync(catPath).isDirectory()) continue;

        const items = fs.readdirSync(catPath);
        for (const item of items) {
          if (item.startsWith('.') || item.endsWith('.zip')) continue;
          const itemPath = path.join(catPath, item);
          try {
            const stat = fs.statSync(itemPath);
            if (!stat.isDirectory()) continue;

            const mtime = stat.mtime.toISOString().split('T')[0] + ' ' + stat.mtime.toTimeString().slice(0, 5);

            const projectData = {
              name: item.trim(),
              category: cat.label,
              status: cat.status,
              local_path: itemPath,
              url: '',
              framework: 'HTML/CSS',
              description: '',
              last_modified: mtime
            };

            // Check package.json
            const pkgPath = path.join(itemPath, 'package.json');
            if (fs.existsSync(pkgPath)) {
              try {
                const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
                if (pkg.description) projectData.description = pkg.description;
                if (pkg.homepage && !pkg.homepage.startsWith('http://localhost')) {
                  projectData.url = pkg.homepage;
                }
                const deps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };
                if (deps['next']) projectData.framework = 'Next.js';
                else if (deps['astro']) projectData.framework = 'Astro';
                else if (deps['vite']) projectData.framework = 'Vite';
                else if (deps['react']) projectData.framework = 'React';
                else if (deps['vue']) projectData.framework = 'Vue';
                else if (deps['tailwindcss']) projectData.framework = 'Tailwind HTML';
              } catch (e) {}
            }

            // Check CNAME
            const cnamePath = path.join(itemPath, 'CNAME');
            if (fs.existsSync(cnamePath)) {
              try {
                const c = fs.readFileSync(cnamePath, 'utf8').trim();
                if (c && !c.includes(' ')) {
                  projectData.url = `https://${c}`;
                }
              } catch (e) {}
            }

            // Check HTML title & canonical link
            for (const htmlRel of ['index.html', 'index.htm', 'home.html', 'public/index.html', 'dist/index.html']) {
              const hp = path.join(itemPath, htmlRel);
              if (fs.existsSync(hp)) {
                try {
                  const htmlContent = fs.readFileSync(hp, 'utf8').slice(0, 10000);
                  const titleMatch = htmlContent.match(/<title>([^<]+)<\/title>/i);
                  if (titleMatch && !projectData.description) {
                    projectData.description = titleMatch[1].trim();
                  }
                  const canonMatch = htmlContent.match(/<link[^>]*rel=["']canonical["'][^>]*href=["'](https?:\/\/[^"']+)["']/i);
                  if (canonMatch && !projectData.url) {
                    projectData.url = canonMatch[1].trim();
                  }
                } catch (e) {}
              }
            }

            // Check README / Config files
            if (!projectData.url) {
              for (const rname of ['README.md', 'readme.md', 'wrangler.toml', 'vercel.json']) {
                const rp = path.join(itemPath, rname);
                if (fs.existsSync(rp)) {
                  try {
                    const content = fs.readFileSync(rp, 'utf8');
                    const urls = content.match(/https?:\/\/(?:www\.)?([a-zA-Z0-9\-]+\.(?:com|cn|org|net|top|io|cc|co|xyz)[^\s"'>\)]*)/g);
                    if (urls) {
                      for (const u of urls) {
                        if (!/github|w3\.org|schema\.org|google|unsplash|esm\.sh|cloudflare|npmjs/.test(u)) {
                          projectData.url = u.trim();
                          break;
                        }
                      }
                    }
                  } catch (e) {}
                }
              }
            }

            // Custom specific project domain matching
            if (!projectData.url) {
              const lowerName = item.toLowerCase();
              if (lowerName.includes('nordic') || lowerName.includes('nordicbeyond')) {
                projectData.url = 'https://nordicbeyondtravel.com/';
              } else if (lowerName === 'ww' || lowerName.includes('wwinsights')) {
                projectData.url = 'https://wwinsightsglobal.com/';
              } else if (lowerName.includes('fomosa')) {
                projectData.url = 'https://www.fomosastuttgart.com/';
              } else if (lowerName.includes('创兴') || lowerName.includes('cxedgeband')) {
                projectData.url = 'https://cxedgeband.com/';
              } else if (lowerName.includes('冰箱贴') || lowerName.includes('frozendecor')) {
                projectData.url = 'https://frozendecor.com/';
              } else if (lowerName.includes('积木') || lowerName.includes('rbrickstem')) {
                projectData.url = 'https://rbrickstem.com/';
              } else if (lowerName.includes('hopeseed')) {
                projectData.url = 'https://www.hopeseedwellness.com/';
              } else if (lowerName.includes('sunwin') || lowerName.includes('晟源')) {
                projectData.url = 'https://sunwin-global.com/';
              } else if (lowerName.includes('重庆云') || lowerName.includes('云昇') || lowerName.includes('云晟')) {
                projectData.url = 'https://looooook.net/';
              } else if (lowerName.includes('lumihair')) {
                projectData.url = 'https://lumihairshop.com/';
              } else if (lowerName.includes('宥森') || lowerName.includes('yoosenly')) {
                projectData.url = 'https://yoosenly.com/';
              } else if (lowerName.includes('jamc') || lowerName.includes('jamcjewelry')) {
                projectData.url = 'https://jamcjewelry.com/';
              }
            }

            // Heuristics
            if (!projectData.url) {
              const cleanName = item.toLowerCase().replace(/[^a-z0-9]/g, '');
              if (cleanName === 'jxcrafts') projectData.url = 'https://jxcrafts.com';
              else if (cleanName === 'genrises') projectData.url = 'https://genrises.com';
              else if (cleanName === 'bravooption' || cleanName.includes('bravooption')) projectData.url = 'https://bravooption.com';
            }

            upsertProject(projectData);
          } catch (err) {
            console.error(`[Website Service]: Error scanning item ${item}:`, err.message);
          }
        }
      }
    }

    // 2. Scan Standalone Desktop Projects
    for (const standalone of STANDALONE_PROJECTS) {
      if (fs.existsSync(standalone.path)) {
        try {
          const stat = fs.statSync(standalone.path);
          const mtime = stat.mtime.toISOString().split('T')[0] + ' ' + stat.mtime.toTimeString().slice(0, 5);
          const pData = {
            name: standalone.name,
            category: standalone.category,
            status: standalone.status,
            local_path: standalone.path,
            url: standalone.url || '',
            framework: standalone.framework || 'HTML/CSS',
            description: standalone.description || '',
            last_modified: mtime
          };
          upsertProject(pData);
        } catch (err) {
          console.error(`[Website Service]: Error scanning standalone ${standalone.name}:`, err.message);
        }
      }
    }

    console.log(`[Website Service]: Scanned and synchronized ${scannedProjects.length} client website projects in total.`);
    return this.getAllWebsites();
  },

  /**
   * Get all website projects with filtering
   */
  getAllWebsites(category = null, search = '') {
    let query = `SELECT * FROM website_projects WHERE 1=1`;
    const params = [];

    if (category && category !== 'all') {
      query += ` AND status = ?`;
      params.push(category);
    }

    if (search && search.trim()) {
      query += ` AND (name LIKE ? OR description LIKE ? OR url LIKE ? OR framework LIKE ? OR services LIKE ?)`;
      const kw = `%${search.trim()}%`;
      params.push(kw, kw, kw, kw, kw);
    }

    // Sort order: in_progress first, delivered, infrastructure, inactive
    query += ` ORDER BY 
      CASE status 
        WHEN 'in_progress' THEN 1 
        WHEN 'delivered' THEN 2 
        WHEN 'infrastructure' THEN 3 
        WHEN 'inactive' THEN 4 
        ELSE 5 
      END,
      last_modified DESC, name ASC`;

    const rows = db.prepare(query).all(...params);
    return rows.map((r) => {
      let parsedServices = [];
      if (r.services) {
        try {
          parsedServices = JSON.parse(r.services);
        } catch {
          parsedServices = typeof r.services === 'string' ? r.services.split(',').map((s) => s.trim()).filter(Boolean) : [];
        }
      }
      return { ...r, services: Array.isArray(parsedServices) ? parsedServices : [] };
    });
  },

  /**
   * Get single website project by id with follow-ups
   */
  getWebsiteById(id) {
    const project = db.prepare(`SELECT * FROM website_projects WHERE id = ?`).get(id);
    if (!project) return null;
    const followUps = db.prepare(`SELECT * FROM website_follow_ups WHERE website_id = ? ORDER BY created_at DESC`).all(id);

    let parsedServices = [];
    if (project.services) {
      try {
        parsedServices = JSON.parse(project.services);
      } catch {
        parsedServices = typeof project.services === 'string' ? project.services.split(',').map((s) => s.trim()).filter(Boolean) : [];
      }
    }

    return { ...project, services: Array.isArray(parsedServices) ? parsedServices : [], follow_ups: followUps };
  },

  /**
   * Get all available service tags (global pool)
   */
  getAvailableServices() {
    const defaultServices = ['网站搭建', 'SEO/GEO', '科学上网'];
    const row = db.prepare(`SELECT value FROM settings WHERE key = 'website_available_services'`).get();
    let stored = [];
    if (row && row.value) {
      try {
        stored = JSON.parse(row.value);
      } catch {
        stored = [];
      }
    }

    // Also collect all distinct services across all projects in the database
    const allProjectServices = db.prepare(`SELECT services FROM website_projects WHERE services IS NOT NULL AND services != ''`).all();
    const fromProjects = [];
    for (const p of allProjectServices) {
      try {
        const arr = JSON.parse(p.services);
        if (Array.isArray(arr)) fromProjects.push(...arr);
      } catch {
        if (typeof p.services === 'string') {
          fromProjects.push(...p.services.split(',').map((s) => s.trim()).filter(Boolean));
        }
      }
    }

    // Merge and deduplicate preserving order
    const merged = Array.from(new Set([...defaultServices, ...stored, ...fromProjects].map((s) => String(s).trim()).filter(Boolean)));
    return merged;
  },

  /**
   * Add a custom service to the global pool
   */
  addAvailableService(serviceName) {
    if (!serviceName || typeof serviceName !== 'string' || !serviceName.trim()) {
      return this.getAvailableServices();
    }
    const clean = serviceName.trim();
    const current = this.getAvailableServices();
    if (!current.includes(clean)) {
      current.push(clean);
      db.prepare(`INSERT OR REPLACE INTO settings (key, value) VALUES ('website_available_services', ?)`).run(JSON.stringify(current));
    }
    return current;
  },

  /**
   * Remove a service from global pool
   */
  removeAvailableService(serviceName) {
    if (!serviceName) return this.getAvailableServices();
    const clean = String(serviceName).trim();
    const current = this.getAvailableServices().filter((s) => s !== clean);
    db.prepare(`INSERT OR REPLACE INTO settings (key, value) VALUES ('website_available_services', ?)`).run(JSON.stringify(current));
    return current;
  },

  /**
   * Update project details (including CRM, finances, assets, services)
   */
  updateWebsite(id, data) {
    const now = new Date().toISOString();
    const current = db.prepare(`SELECT * FROM website_projects WHERE id = ?`).get(id);
    if (!current) throw new Error('网站项目不存在');

    // Calculate unpaid and paid amounts with auto-calculation or manual override
    let total = data.total_amount !== undefined ? parseFloat(data.total_amount) || 0 : (current.total_amount || 0);
    let deposit = data.deposit_amount !== undefined ? parseFloat(data.deposit_amount) || 0 : (current.deposit_amount || 0);

    let unpaid;
    let paid;

    if (data.unpaid_amount !== undefined && data.unpaid_amount !== null && data.unpaid_amount !== '') {
      unpaid = Math.max(0, parseFloat(data.unpaid_amount) || 0);
      paid = data.paid_amount !== undefined ? parseFloat(data.paid_amount) || 0 : Math.max(0, total - unpaid);
    } else if (data.paid_amount !== undefined && data.paid_amount !== null && data.paid_amount !== '') {
      paid = parseFloat(data.paid_amount) || 0;
      unpaid = Math.max(0, total - paid);
    } else {
      unpaid = current.unpaid_amount !== undefined && current.unpaid_amount !== null
        ? current.unpaid_amount
        : Math.max(0, total - deposit);
      paid = current.paid_amount || deposit;
    }

    let paymentStatus = data.payment_status || current.payment_status || 'pending';
    if (total > 0 && unpaid <= 0) {
      paymentStatus = 'fully_paid';
    } else if (paid > 0 || deposit > 0) {
      paymentStatus = 'deposit_paid';
    } else {
      paymentStatus = 'pending';
    }

    const nameVal = (data.name !== undefined && data.name !== null && data.name.trim() !== '') ? data.name.trim() : current.name;
    const urlVal = (data.url !== undefined && data.url !== null && data.url.trim() !== '') ? data.url.trim() : current.url;

    // Handle services array / json string
    let servicesVal = undefined;
    if (data.services !== undefined) {
      let arr = [];
      if (Array.isArray(data.services)) {
        arr = data.services.map((s) => String(s).trim()).filter(Boolean);
      } else if (typeof data.services === 'string') {
        try {
          arr = JSON.parse(data.services);
          if (!Array.isArray(arr)) arr = [data.services];
        } catch {
          arr = data.services.split(',').map((s) => s.trim()).filter(Boolean);
        }
      }
      servicesVal = JSON.stringify(arr);
      // Synchronize any custom service into global pool
      for (const s of arr) {
        this.addAvailableService(s);
      }
    }

    const startDateVal = data.service_start_date !== undefined ? data.service_start_date : current.service_start_date;
    const endDateVal = data.service_end_date !== undefined ? data.service_end_date : current.service_end_date;

    db.prepare(`
      UPDATE website_projects
      SET name = ?,
          url = ?,
          category = COALESCE(?, category),
          status = COALESCE(?, status),
          description = COALESCE(?, description),
          framework = COALESCE(?, framework),
          client_name = COALESCE(?, client_name),
          client_phone = COALESCE(?, client_phone),
          client_wechat = COALESCE(?, client_wechat),
          client_email = COALESCE(?, client_email),
          client_company = COALESCE(?, client_company),
          total_amount = ?,
          deposit_amount = ?,
          paid_amount = ?,
          unpaid_amount = ?,
          payment_status = ?,
          assets_credentials = COALESCE(?, assets_credentials),
          services = COALESCE(?, services),
          service_start_date = ?,
          service_end_date = ?,
          updated_at = ?
      WHERE id = ?
    `).run(
      nameVal,
      urlVal,
      data.category,
      data.status,
      data.description,
      data.framework,
      data.client_name,
      data.client_phone,
      data.client_wechat,
      data.client_email,
      data.client_company,
      total,
      deposit,
      paid,
      unpaid,
      paymentStatus,
      data.assets_credentials,
      servicesVal,
      startDateVal,
      endDateVal,
      now,
      id
    );

    return this.getWebsiteById(id);
  },

  /**
   * Create a new website project (manual or via AI)
   */
  createWebsite(data) {
    const now = new Date().toISOString();
    const id = crypto.randomUUID();
    const name = (data.name || '新定制网站项目').trim();
    const status = data.status || 'in_progress';
    const category = status === 'in_progress' ? '进行中' : status === 'delivered' ? '已交付' : status === 'inactive' ? '挂了' : '功能基础建设';
    const localPath = data.local_path || path.join(DEFAULT_BASE_DIR, category, name);
    const mtime = now.split('T')[0] + ' ' + now.slice(11, 16);

    let total = parseFloat(data.total_amount) || 0;
    let deposit = parseFloat(data.deposit_amount) || 0;
    let paid = parseFloat(data.paid_amount) || 0;
    let unpaid = Math.max(0, total - paid);
    let paymentStatus = data.payment_status || (paid >= total && total > 0 ? 'fully_paid' : (deposit > 0 || paid > 0 ? 'deposit_paid' : 'pending'));

    let servicesJson = '[]';
    if (data.services) {
      const arr = Array.isArray(data.services) ? data.services : (typeof data.services === 'string' ? data.services.split(',').map((s) => s.trim()).filter(Boolean) : []);
      servicesJson = JSON.stringify(arr);
      for (const s of arr) this.addAvailableService(s);
    }

    db.prepare(`
      INSERT INTO website_projects (
        id, name, category, status, local_path, url, framework, description, last_modified,
        client_name, client_phone, client_wechat, client_email, client_company,
        total_amount, deposit_amount, paid_amount, unpaid_amount, payment_status,
        assets_credentials, services, service_start_date, service_end_date, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `).run(
      id,
      name,
      category,
      status,
      localPath,
      data.url || '',
      data.framework || 'React',
      data.description || '',
      mtime,
      data.client_name || '',
      data.client_phone || '',
      data.client_wechat || '',
      data.client_email || '',
      data.client_company || '',
      total,
      deposit,
      paid,
      unpaid,
      paymentStatus,
      data.assets_credentials || '',
      servicesJson,
      data.service_start_date || '',
      data.service_end_date || '',
      now,
      now
    );

    return this.getWebsiteById(id);
  },

  /**
   * Add a follow-up record
   */
  addFollowUp(websiteId, content, type = 'note') {
    const id = crypto.randomUUID();
    const now = new Date().toISOString();
    db.prepare(`
      INSERT INTO website_follow_ups (id, website_id, content, type, created_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(id, websiteId, content.trim(), type, now);
    return db.prepare(`SELECT * FROM website_follow_ups WHERE id = ?`).get(id);
  },

  /**
   * Delete a follow-up record
   */
  deleteFollowUp(id) {
    db.prepare(`DELETE FROM website_follow_ups WHERE id = ?`).run(id);
    return { success: true };
  },

  /**
   * Open local directory in Finder
   */
  async openInFinder(localPath) {
    if (!fs.existsSync(localPath)) {
      throw new Error(`本地路径不存在: ${localPath}`);
    }
    await execFileAsync('/usr/bin/open', [localPath]);
    return { success: true };
  },

  /**
   * Open local project in IDE / code editor
   */
  async openInEditor(localPath) {
    if (!fs.existsSync(localPath)) {
      throw new Error(`本地路径不存在: ${localPath}`);
    }

    // Try opening in Antigravity or MiniMax Code or fallback open
    try {
      if (fs.existsSync('/Applications/Antigravity IDE.app')) {
        await execFileAsync('/usr/bin/open', ['-a', 'Antigravity IDE', localPath]);
        return { success: true, app: 'Antigravity IDE' };
      } else if (fs.existsSync('/Applications/MiniMax Code.app')) {
        await execFileAsync('/usr/bin/open', ['-a', 'MiniMax Code', localPath]);
        return { success: true, app: 'MiniMax Code' };
      } else {
        await execFileAsync('/usr/bin/open', [localPath]);
        return { success: true, app: 'Finder' };
      }
    } catch (e) {
      await execFileAsync('/usr/bin/open', [localPath]);
      return { success: true, app: 'Finder' };
    }
  }
};
