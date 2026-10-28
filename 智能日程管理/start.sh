#!/bin/bash

# SmartPlan Hub - 智能日程与项目管理系统启动脚本
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=================================================="
echo "🚀 正在启动 SmartPlan 智能日程与项目管理系统..."
echo "=================================================="

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "❌ 未检测到 Node.js，请先安装 Node.js"
    exit 1
fi

# Ensure client dist is built if not present
if [ ! -d "client/dist" ]; then
    echo "📦 首次运行，正在构建前端页面..."
    npm run build
fi

# Kill any existing process on port 3300
PORT=3300
PID=$(lsof -ti:$PORT)
if [ ! -z "$PID" ]; then
    echo "⚠️ 端口 3300 已被占用 (PID: $PID)，正在释放..."
    kill -9 $PID
fi

echo "✨ 启动本地服务..."
node server/index.js &
SERVER_PID=$!

sleep 1.5

# Open browser
echo "🌐 正在打开浏览器..."
open "http://localhost:3300"

echo "✅ 系统运行中！访问地址: http://localhost:3300"
echo "💡 提示: 按 Ctrl+C 可停止运行"

# Trap exit to cleanup
trap "echo '正在停止系统...'; kill $SERVER_PID; exit 0" SIGINT SIGTERM

wait $SERVER_PID
