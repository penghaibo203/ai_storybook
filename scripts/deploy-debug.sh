#!/bin/bash

# 部署调试版本脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🐛 部署调试版本${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查调试代码${NC}"
if grep -q "StoryRenderer.render 被调用" storyRenderer.js && grep -q "开始渲染故事页面" main.js; then
    echo -e "${GREEN}✅ 调试代码已添加${NC}"
else
    echo -e "${RED}❌ 调试代码缺失${NC}"
    exit 1
fi

echo -e "${BLUE}2. 重启服务应用调试版本${NC}"
pm2 restart all || pm2 start server.js --name ai-storybook --env production
pm2 save

echo -e "${BLUE}3. 等待服务启动${NC}"
sleep 3

echo -e "${BLUE}4. 检查服务状态${NC}"
pm2 status

echo -e "${BLUE}5. 测试本地服务${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地服务正常${NC}"
else
    echo -e "${RED}❌ 本地服务异常${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 调试版本部署完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🐛 调试功能:${NC}"
echo "  ✅ 添加了storyRenderer.render调试日志"
echo "  ✅ 添加了renderCurrentPage调试日志"
echo "  ✅ 添加了displayStory调试日志"
echo "  ✅ 添加了数据流追踪日志"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work"
echo "  2. 点击查看历史绘本"
echo "  3. 打开浏览器开发者工具控制台"
echo "  4. 查看详细的调试日志"
echo "  5. 根据日志定位问题"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  生产: https://hypersmart.work"
echo ""

echo -e "${GREEN}🎊 调试版本已部署！请测试并查看控制台日志${NC}"
