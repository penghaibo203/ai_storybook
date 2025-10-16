#!/bin/bash

# 修复CSP infird.com脚本阻止问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔧 修复CSP infird.com脚本阻止问题${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查CSP配置修复${NC}"
if grep -q "https://infird.com" server.js && grep -q "https://infird.com" server-https.js; then
    echo -e "${GREEN}✅ CSP配置已添加infird.com域名${NC}"
else
    echo -e "${RED}❌ CSP配置未完全修复${NC}"
    exit 1
fi

echo -e "${BLUE}2. 重启服务应用CSP修复${NC}"
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
echo -e "${GREEN}🎉 CSP infird.com修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 在server.js中添加了https://infird.com到scriptSrc"
echo "  ✅ 在server.js中添加了https://infird.com到scriptSrcElem"
echo "  ✅ 在server-https.js中添加了https://infird.com到scriptSrc"
echo "  ✅ 在server-https.js中添加了https://infird.com到scriptSrcElem"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work"
echo "  2. 检查控制台是否还有CSP错误"
echo "  3. 测试生成故事功能"
echo "  4. 测试查看历史记录功能"
echo "  5. 测试页面导航功能"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  生产: https://hypersmart.work"
echo ""

echo -e "${GREEN}🎊 CSP修复完成！请测试所有功能${NC}"
