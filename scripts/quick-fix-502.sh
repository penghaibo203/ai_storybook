#!/bin/bash

# 快速修复502错误脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}⚡ 快速修复502错误${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查PM2状态${NC}"
pm2 list

echo -e "${BLUE}2. 重启PM2服务${NC}"
pm2 restart all || pm2 start ecosystem.config.cjs --env production
pm2 save

echo -e "${BLUE}3. 等待服务启动${NC}"
sleep 3

echo -e "${BLUE}4. 检查本地服务${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地服务正常${NC}"
else
    echo -e "${RED}❌ 本地服务异常，尝试直接启动${NC}"
    pm2 stop all
    pm2 start server.js --name ai-storybook
    sleep 3
fi

echo -e "${BLUE}5. 重启Nginx${NC}"
if command -v nginx &> /dev/null; then
    sudo systemctl restart nginx
    sleep 2
    echo -e "${GREEN}✅ Nginx已重启${NC}"
fi

echo -e "${BLUE}6. 最终检查${NC}"
pm2 status

echo ""
echo -e "${GREEN}🎉 快速修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🧪 现在可以测试:${NC}"
echo "  1. 访问 https://hypersmart.work"
echo "  2. 输入故事主题"
echo "  3. 点击生成故事"
echo ""

# 自动测试
echo -e "${BLUE}7. 自动测试API${NC}"
if curl -f -s https://hypersmart.work/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 生产环境健康检查正常${NC}"
else
    echo -e "${YELLOW}⚠️  生产环境可能需要等待几秒钟${NC}"
fi

echo -e "${GREEN}🎊 修复完成！请测试生成故事功能${NC}"
