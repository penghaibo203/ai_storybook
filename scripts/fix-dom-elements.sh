#!/bin/bash

# 修复DOM元素错误脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复DOM元素错误${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查修复后的文件${NC}"
if [ -f "main.js" ] && [ -f "index.html" ]; then
    echo -e "${GREEN}✅ 所有文件存在${NC}"
else
    echo -e "${RED}❌ 文件缺失${NC}"
    exit 1
fi

echo -e "${BLUE}2. 验证修复内容${NC}"
# 检查main.js是否添加了空值检查
if grep -q "if (elements.generateBtn)" main.js; then
    echo -e "${GREEN}✅ main.js已添加空值检查${NC}"
else
    echo -e "${RED}❌ main.js缺少空值检查${NC}"
    exit 1
fi

# 检查是否创建了音频播放器
if grep -q "音频播放器元素已创建" main.js; then
    echo -e "${GREEN}✅ 音频播放器创建逻辑已添加${NC}"
else
    echo -e "${RED}❌ 音频播放器创建逻辑缺失${NC}"
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
echo -e "${GREEN}🎉 DOM元素错误修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 修正了DOM元素ID映射"
echo "  ✅ 添加了空值检查防止错误"
echo "  ✅ 创建了音频播放器元素"
echo "  ✅ 修复了事件绑定逻辑"
echo "  ✅ 更新了页面显示函数"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work"
echo "  2. 检查控制台是否还有错误"
echo "  3. 测试生成故事功能"
echo "  4. 测试页面导航功能"
echo "  5. 测试音频播放功能"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  生产: https://hypersmart.work"
echo ""

echo -e "${GREEN}🎊 修复完成！请测试所有功能${NC}"
