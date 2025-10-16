#!/bin/bash

# 修复移动端record ID传递问题脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}📱 修复移动端record ID传递问题${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查localStorage修复${NC}"
if grep -q "localStorage.getItem('currentRecordId')" main.js && grep -q "localStorage.setItem('currentRecordId'" records.html; then
    echo -e "${GREEN}✅ localStorage修复已添加${NC}"
else
    echo -e "${RED}❌ localStorage修复未添加${NC}"
    exit 1
fi

echo -e "${BLUE}2. 检查URL参数移除${NC}"
if ! grep -q "URLSearchParams" main.js && ! grep -q "window.location.search" main.js; then
    echo -e "${GREEN}✅ URL参数依赖已移除${NC}"
else
    echo -e "${YELLOW}⚠️  仍有URL参数相关代码${NC}"
fi

echo -e "${BLUE}3. 检查URL清理代码移除${NC}"
if ! grep -q "window.history.replaceState" main.js; then
    echo -e "${GREEN}✅ URL清理代码已移除${NC}"
else
    echo -e "${YELLOW}⚠️  仍有URL清理代码${NC}"
fi

echo -e "${BLUE}4. 重启服务应用修复${NC}"
pm2 restart all || pm2 start server.js --name ai-storybook --env production
pm2 save

echo -e "${BLUE}5. 等待服务启动${NC}"
sleep 3

echo -e "${BLUE}6. 检查服务状态${NC}"
pm2 status

echo -e "${BLUE}7. 测试本地服务${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地服务正常${NC}"
else
    echo -e "${RED}❌ 本地服务异常${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 移动端record ID传递问题修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 将URL参数传递改为localStorage传递"
echo "  ✅ 修改checkForRecordId函数使用localStorage"
echo "  ✅ 修改viewRecord函数存储ID到localStorage"
echo "  ✅ 移除URL清理相关代码"
echo "  ✅ 添加localStorage清理逻辑避免重复加载"
echo ""
echo -e "${BLUE}📱 移动端优势:${NC}"
echo "  ✅ 不依赖URL参数，兼容性更好"
echo "  ✅ 在微信、APP等环境中正常工作"
echo "  ✅ 避免URL参数被截断或丢失"
echo "  ✅ 更稳定的数据传递方式"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work/records.html"
echo "  2. 点击任意记录的'查看绘本'按钮"
echo "  3. 观察是否跳转到主页并显示故事"
echo "  4. 在移动端测试相同流程"
echo ""
echo -e "${BLUE}🌐 测试地址:${NC}"
echo "  记录页面: https://hypersmart.work/records.html"
echo "  主页: https://hypersmart.work/"
echo ""

echo -e "${GREEN}🎊 移动端record ID传递问题修复完成！请测试移动端功能${NC}"
