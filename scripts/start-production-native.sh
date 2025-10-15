#!/bin/bash

# 生产环境原生启动脚本
# 使用PM2管理进程

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 启动AI英文绘本应用 - 生产环境（原生）${NC}"
echo "=============================================="

# 检查环境变量
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

# 检查PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${RED}❌ PM2未安装，请先安装PM2${NC}"
    echo "安装命令: npm install -g pm2"
    exit 1
fi

# 检查.env文件
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ 加载.env文件${NC}"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${YELLOW}⚠️  .env文件不存在，使用环境变量${NC}"
fi

# 创建日志目录
mkdir -p logs

# 启动应用
echo -e "${GREEN}🚀 启动应用...${NC}"
echo "环境: $NODE_ENV"
echo "端口: $PORT"
echo ""

# 使用PM2启动
pm2 start ecosystem.config.cjs --env production

# 显示状态
echo -e "${BLUE}📊 应用状态:${NC}"
pm2 status

echo -e "${BLUE}📋 管理命令:${NC}"
echo "  查看日志: pm2 logs ai-storybook"
echo "  重启应用: pm2 restart ai-storybook"
echo "  停止应用: pm2 stop ai-storybook"
echo "  监控面板: pm2 monit"
echo ""

echo -e "${GREEN}🎊 应用启动完成！${NC}"
