#!/bin/bash

# 修复URL清理时机问题脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔧 修复URL清理时机问题${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查URL清理修复${NC}"
if grep -q "延迟清除URL参数" main.js && grep -q "setTimeout" main.js; then
    echo -e "${GREEN}✅ URL清理时机已修复${NC}"
else
    echo -e "${RED}❌ URL清理时机未修复${NC}"
    exit 1
fi

echo -e "${BLUE}2. 重启服务应用修复${NC}"
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
echo -e "${GREEN}🎉 URL清理时机修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 将URL清理从立即执行改为延迟1秒执行"
echo "  ✅ 确保故事完全显示后再清理URL参数"
echo "  ✅ 添加了URL清理完成的日志输出"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work/?record=story_mgtdbe52_8qz96"
echo "  2. 观察故事是否正确显示"
echo "  3. 检查URL是否在1秒后变为 https://hypersmart.work/"
echo "  4. 查看控制台调试日志"
echo ""
echo -e "${BLUE}🌐 测试URL:${NC}"
echo "  带参数: https://hypersmart.work/?record=story_mgtdbe52_8qz96"
echo "  清理后: https://hypersmart.work/"
echo ""

echo -e "${GREEN}🎊 URL清理时机修复完成！请测试故事显示功能${NC}"
