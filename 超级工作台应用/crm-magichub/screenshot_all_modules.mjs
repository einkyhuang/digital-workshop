import { chromium } from 'playwright';
import { existsSync, mkdirSync } from 'fs';
import path from 'path';

const OUTPUT_DIR = '/Users/ky/Desktop/自有项目代码管理/forwelike---专业出海建站与seo/public/ai';

// The 15 modules in order - matching the nav buttons
const modules = [
  { name: '驾驶舱',   file: 'dashboard.png'    },
  { name: '日程管理', file: 'schedule.png'      },
  { name: '客户管理', file: 'customers.png'     },
  { name: '智能营销', file: 'marketing.png'     },
  { name: '商机管理', file: 'opportunities.png' },
  { name: '跟进记录', file: 'followup.png'      },
  { name: '寄样跟进', file: 'samples.png'       },
  { name: '报价记录', file: 'quotes.png'        },
  { name: '订单合同', file: 'contracts.png'     },
  { name: '产品管理', file: 'products.png'      },
  { name: '知识仓库', file: 'knowledge.png'     },
  { name: '公司信息', file: 'company.png'       },
  { name: '团队管理', file: 'team.png'          },
  { name: 'Agent 协同', file: 'agentRoom.png'  },
  { name: '系统设置', file: 'settings.png'      },
  { name: 'Forwelike 专区', file: 'forwelike.png' }
];

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 },
    deviceScaleFactor: 2, // Retina quality
  });
  const page = await context.newPage();

  console.log('Navigating to http://localhost:5173/ ...');
  await page.goto('http://localhost:5173/', { waitUntil: 'networkidle', timeout: 15000 });
  
  // Wait for the app to fully render
  await page.waitForSelector('nav button, button[class*="nav"]', { timeout: 10000 }).catch(() => {});
  await page.waitForTimeout(2000);

  for (const mod of modules) {
    console.log(`Capturing: ${mod.name} → ${mod.file}`);
    
    // Try to click the nav button by text content
    const btn = page.locator(`button, [role="button"]`).filter({ hasText: mod.name }).first();
    
    try {
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500); // Wait for content to load
    } catch (e) {
      console.warn(`  Could not click button "${mod.name}": ${e.message}`);
      // Try alternative: click by partial text
      try {
        await page.click(`text="${mod.name}"`, { timeout: 3000 });
        await page.waitForTimeout(1500);
      } catch (e2) {
        console.warn(`  Alternative click also failed: ${e2.message}`);
      }
    }

    const outputPath = path.join(OUTPUT_DIR, mod.file);
    await page.screenshot({ path: outputPath, fullPage: false });
    console.log(`  ✓ Saved to ${outputPath}`);
  }

  await browser.close();
  console.log('\n✅ All screenshots complete!');
})();
