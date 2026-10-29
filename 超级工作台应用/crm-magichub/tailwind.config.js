/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        zen: {
          bg: '#F9FBFA',       // 极简禅意绿白背景
          paper: '#F3F5F4',    // 宣纸质感淡灰白
          ink: '#1A2220',      // 沉稳水墨黑
          gray: '#5F6F6C',     // 远山雾灰
          light: '#E5E8E7',    // 清爽淡灰
          green: '#627254',    // 禅意竹绿
          tea: '#8E9E88',      // 淡雅茶绿
          crimson: '#C98B8B',  // 柔和朱砂红
          gold: '#C2A478',     // 磨砂泥金
        }
      },
      fontFamily: {
        serif: ['"Noto Serif SC"', 'Playfair Display', 'Georgia', 'serif'],
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
      },
      boxShadow: {
        'zen': '0 4px 20px -2px rgba(98, 114, 84, 0.05), 0 2px 10px -1px rgba(0, 0, 0, 0.01)',
        'zen-lg': '0 12px 30px -4px rgba(98, 114, 84, 0.08), 0 4px 15px -2px rgba(0, 0, 0, 0.02)',
        'zen-focus': '0 0 0 3px rgba(98, 114, 84, 0.15)',
      }
    },
  },
  plugins: [],
}

