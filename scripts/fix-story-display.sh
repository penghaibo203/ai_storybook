#!/bin/bash

# 修复故事显示问题脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔧 修复故事显示问题${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查故事显示修复${NC}"
if grep -q "添加show类来显示故事区域" main.js && grep -q "故事容器已显示" main.js; then
    echo -e "${GREEN}✅ 故事显示修复已添加${NC}"
else
    echo -e "${RED}❌ 故事显示修复未添加${NC}"
    exit 1
fi

echo -e "${BLUE}2. 检查CSS样式${NC}"
if grep -q "display: none" index.html && grep -q ".story-section.show" index.html; then
    echo -e "${GREEN}✅ CSS样式配置正确${NC}"
else
    echo -e "${RED}❌ CSS样式配置有问题${NC}"
    exit 1
fi

echo -e "${BLUE}3. 重启服务应用修复${NC}"
pm2 restart all || pm2 start server.js --name ai-storybook --env production
pm2 save

echo -e "${BLUE}4. 等待服务启动${NC}"
sleep 3

echo -e "${BLUE}5. 检查服务状态${NC}"
pm2 status

echo -e "${BLUE}6. 测试本地服务${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地服务正常${NC}"
else
    echo -e "${RED}❌ 本地服务异常${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 故事显示问题修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 在displayStory函数中添加了show类"
echo "  ✅ 确保story-section容器正确显示"
echo "  ✅ 添加了故事容器显示的调试日志"
echo ""
echo -e "${BLUE}🎯 问题分析:${NC}"
echo "  📊 故事数据已正确渲染到DOM"
echo "  📊 页面元素已成功创建和添加"
echo "  📊 问题在于CSS显示状态控制"
echo "  📊 story-section默认display:none，需要show类"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work/?record=story_mgtdbe52_8qz96"
echo "  2. 观察故事是否正确显示"
echo "  3. 检查控制台是否显示'故事容器已显示'日志"
echo "  4. 测试页面导航功能"
echo ""
echo -e "${BLUE}🌐 测试URL:${NC}"
echo "  带参数: https://hypersmart.work/?record=story_mgtdbe52_8qz96"
echo ""

echo -e "${GREEN}🎊 故事显示问题修复完成！请测试故事显示功能${NC}"
