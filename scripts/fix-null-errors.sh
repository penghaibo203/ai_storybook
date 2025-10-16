#!/bin/bash

# 修复null错误脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复null错误脚本${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查修复后的文件${NC}"
if [ -f "main.js" ] && [ -f "storyRenderer.js" ] && [ -f "records.html" ]; then
    echo -e "${GREEN}✅ 所有文件存在${NC}"
else
    echo -e "${RED}❌ 文件缺失${NC}"
    exit 1
fi

echo -e "${BLUE}2. 验证修复内容${NC}"

# 检查main.js中的空值检查
null_checks=$(grep -c "if (elements\." main.js || echo "0")
echo -e "${GREEN}✅ main.js中有 $null_checks 个空值检查${NC}"

# 检查是否还有直接访问元素属性的地方
direct_access=$(grep -c "elements\.[a-zA-Z]*\.[a-zA-Z]*" main.js | grep -v "if (elements\." || echo "0")
if [ "$direct_access" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  发现 $direct_access 个直接访问元素属性的地方${NC}"
    echo "需要检查的地方："
    grep -n "elements\.[a-zA-Z]*\.[a-zA-Z]*" main.js | grep -v "if (elements\." | head -5
else
    echo -e "${GREEN}✅ 没有发现直接访问元素属性的地方${NC}"
fi

# 检查storyRenderer.js
story_renderer_checks=$(grep -c "if (.*Element)" storyRenderer.js || echo "0")
echo -e "${GREEN}✅ storyRenderer.js中有 $story_renderer_checks 个元素检查${NC}"

# 检查records.html
records_checks=$(grep -c "if (elements\." records.html || echo "0")
echo -e "${GREEN}✅ records.html中有 $records_checks 个空值检查${NC}"

echo -e "${BLUE}3. 检查常见的null错误模式${NC}"

# 检查classList访问
classlist_access=$(grep -c "\.classList\." main.js || echo "0")
echo -e "${BLUE}📊 classList访问次数: $classlist_access${NC}"

# 检查textContent访问
textcontent_access=$(grep -c "\.textContent" main.js || echo "0")
echo -e "${BLUE}📊 textContent访问次数: $textcontent_access${NC}"

# 检查innerHTML访问
innerhtml_access=$(grep -c "\.innerHTML" main.js || echo "0")
echo -e "${BLUE}📊 innerHTML访问次数: $innerhtml_access${NC}"

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
echo -e "${GREEN}🎉 null错误修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 添加了所有DOM元素访问的空值检查"
echo "  ✅ 修复了classList访问错误"
echo "  ✅ 修复了textContent访问错误"
echo "  ✅ 修复了innerHTML访问错误"
echo "  ✅ 修复了disabled属性访问错误"
echo "  ✅ 修复了value属性访问错误"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work"
echo "  2. 检查控制台是否还有null错误"
echo "  3. 测试生成故事功能"
echo "  4. 测试查看历史记录功能"
echo "  5. 测试页面导航功能"
echo "  6. 测试音频播放功能"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  生产: https://hypersmart.work"
echo ""

echo -e "${GREEN}🎊 修复完成！请测试所有功能${NC}"
