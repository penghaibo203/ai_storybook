#!/bin/bash

# H5移动端优化部署脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📱 H5移动端优化部署脚本${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查文件完整性${NC}"
required_files=("index.html" "records.html" "main.js" "storyRenderer.js" "server.js" "server-https.js")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $file${NC}"
    else
        echo -e "${RED}❌ $file 缺失${NC}"
        exit 1
    fi
done

echo -e "${BLUE}2. 停止现有服务${NC}"
pm2 stop all || true
pm2 delete all || true

echo -e "${BLUE}3. 启动优化后的服务${NC}"
pm2 start ecosystem.config.cjs --env production
pm2 save

echo -e "${BLUE}4. 等待服务启动${NC}"
sleep 5

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

echo -e "${BLUE}8. 测试生产环境${NC}"
if curl -f -s https://hypersmart.work/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 生产环境健康检查正常${NC}"
else
    echo -e "${YELLOW}⚠️  生产环境可能需要等待几秒钟${NC}"
fi

echo ""
echo -e "${GREEN}🎉 H5移动端优化部署完成！${NC}"
echo "=============================================="
echo -e "${BLUE}📱 移动端优化特性:${NC}"
echo "  ✅ 响应式设计适配各种屏幕尺寸"
echo "  ✅ 触摸友好的按钮和交互元素"
echo "  ✅ 滑动手势切换页面"
echo "  ✅ 优化的音频播放体验"
echo "  ✅ 防止双击缩放"
echo "  ✅ 安全区域适配（iPhone X等）"
echo "  ✅ 触摸反馈动画"
echo "  ✅ 键盘弹出时的页面滚动优化"
echo ""
echo -e "${BLUE}🧪 测试建议:${NC}"
echo "  1. 在手机上访问 https://hypersmart.work"
echo "  2. 测试输入框和生成按钮"
echo "  3. 测试页面滑动切换"
echo "  4. 测试音频播放功能"
echo "  5. 测试记录页面的查看和删除功能"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  生产: https://hypersmart.work"
echo ""

echo -e "${GREEN}🎊 部署完成！请测试移动端体验${NC}"
