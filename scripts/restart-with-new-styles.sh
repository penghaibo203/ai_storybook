#!/bin/bash

# 重启应用并应用新的样式优化

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎨 重启应用并应用新的样式优化${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 停止现有PM2进程
echo -e "${YELLOW}🛑 停止现有PM2进程...${NC}"
pm2 stop ai-storybook || true
pm2 delete ai-storybook || true

# 启动应用
echo -e "${YELLOW}🚀 启动应用...${NC}"
pm2 start ecosystem.config.cjs --env production
pm2 save

# 等待服务启动
echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
sleep 5

# 健康检查
echo -e "${YELLOW}🏥 执行健康检查...${NC}"
for i in {1..10}; do
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 应用健康检查通过${NC}"
        break
    fi
    echo "等待应用启动... ($i/10)"
    sleep 2
done

# 显示服务状态
echo -e "${YELLOW}📊 显示服务状态...${NC}"
pm2 status

echo ""
echo -e "${GREEN}🎉 样式优化已应用！${NC}"
echo "=============================================="
echo -e "${BLUE}🎨 样式优化内容:${NC}"
echo "  ✅ 页码指示器 - 红色渐变 + 弹跳动画 + 书本图标"
echo "  ✅ 播放按钮 - 更大尺寸 + 金色边框 + 浮动动画 + 波纹效果"
echo "  ✅ 故事文本 - 渐变文字 + 国旗动画 + 发光效果 + 装饰星星"
echo "  ✅ 响应式设计 - 移动端适配优化"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  主页: http://localhost:3000"
echo "  样式预览: http://localhost:3000/style-preview.html"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}📱 新特性:${NC}"
echo "  🎭 丰富的动画效果"
echo "  🌈 鲜艳的渐变色彩"
echo "  ✨ 可爱的装饰元素"
echo "  📱 完美的移动端适配"
echo "  🎯 符合小朋友审美"
echo ""

echo -e "${GREEN}🎊 重启完成！${NC}"
