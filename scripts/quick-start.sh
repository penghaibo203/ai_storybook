#!/bin/bash

# AI英文绘本快速启动脚本

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 AI英文绘本快速启动${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo "❌ 请在项目根目录运行此脚本"
    exit 1
fi

# 停止现有进程
echo -e "${BLUE}停止现有进程...${NC}"
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# 启动服务
echo -e "${BLUE}启动服务...${NC}"
pm2 start server.js --name ai-storybook --env production

# 保存配置
pm2 save

# 等待启动
sleep 2

# 显示状态
pm2 status

echo ""
echo -e "${GREEN}✅ 服务启动完成！${NC}"
echo -e "${BLUE}🌐 访问地址: http://localhost:3000${NC}"
echo -e "${BLUE}📋 查看日志: pm2 logs${NC}"
echo -e "${BLUE}🔄 重启服务: pm2 restart all${NC}"
