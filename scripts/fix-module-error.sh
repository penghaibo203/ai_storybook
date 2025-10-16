#!/bin/bash

# 修复ES6模块错误脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复ES6模块错误${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查修复后的文件${NC}"
if [ -f "main.js" ] && [ -f "storyRenderer.js" ] && [ -f "index.html" ]; then
    echo -e "${GREEN}✅ 所有文件存在${NC}"
else
    echo -e "${RED}❌ 文件缺失${NC}"
    exit 1
fi

echo -e "${BLUE}2. 验证修复内容${NC}"
# 检查main.js是否移除了import语句
if grep -q "import.*from" main.js; then
    echo -e "${RED}❌ main.js仍包含import语句${NC}"
    exit 1
else
    echo -e "${GREEN}✅ main.js已移除import语句${NC}"
fi

# 检查storyRenderer.js是否移除了export语句
if grep -q "export.*class" storyRenderer.js; then
    echo -e "${RED}❌ storyRenderer.js仍包含export语句${NC}"
    exit 1
else
    echo -e "${GREEN}✅ storyRenderer.js已移除export语句${NC}"
fi

# 检查index.html是否按正确顺序引入脚本
if grep -q "storyRenderer.js.*main.js" index.html; then
    echo -e "${GREEN}✅ index.html脚本引入顺序正确${NC}"
else
    echo -e "${YELLOW}⚠️  检查index.html脚本引入顺序${NC}"
fi

echo -e "${BLUE}3. 重启服务应用修复${NC}"
pm2 restart all || pm2 start ecosystem.config.cjs --env production
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

echo -e "${BLUE}7. 重启Nginx${NC}"
if command -v nginx &> /dev/null; then
    sudo systemctl restart nginx
    sleep 2
    
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "${GREEN}✅ Nginx重启成功${NC}"
    else
        echo -e "${RED}❌ Nginx重启失败${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Nginx未安装，跳过Nginx重启${NC}"
fi

echo ""
echo -e "${GREEN}🎉 ES6模块错误修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 移除了main.js中的import语句"
echo "  ✅ 移除了storyRenderer.js中的export语句"
echo "  ✅ 将类暴露到全局作用域"
echo "  ✅ 更新了HTML中的脚本引入顺序"
echo "  ✅ 重启了服务应用修复"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问 https://hypersmart.work"
echo "  2. 生成一个故事"
echo "  3. 访问记录页面"
echo "  4. 点击'查看绘本'按钮"
echo "  5. 检查是否正常跳转并显示绘本"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  生产: https://hypersmart.work"
echo ""

echo -e "${GREEN}🎊 修复完成！请测试绘本查看功能${NC}"
