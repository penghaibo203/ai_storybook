#!/bin/bash

# 部署移动端优化版本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}📱 部署移动端优化版本${NC}"
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
echo -e "${GREEN}🎉 移动端优化版本已部署！${NC}"
echo "=============================================="
echo -e "${BLUE}📱 移动端优化内容:${NC}"
echo "  ✅ 响应式布局 - 支持所有屏幕尺寸"
echo "  ✅ 触摸友好 - 44px最小触摸目标"
echo "  ✅ 字体优化 - 移动端可读性提升"
echo "  ✅ 按钮优化 - 适合手指操作"
echo "  ✅ 滚动优化 - 流畅的触摸滚动"
echo "  ✅ 视口设置 - 防止意外缩放"
echo "  ✅ 性能优化 - 硬件加速动画"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  主页: http://localhost:3000"
echo "  记录页: http://localhost:3000/records.html"
echo "  移动端测试: http://localhost:3000/mobile-test.html"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}📏 支持的屏幕尺寸:${NC}"
echo "  📱 超小屏手机: ≤360px"
echo "  📱 小屏手机: ≤480px"
echo "  📱 手机: ≤768px"
echo "  📱 平板: ≤1024px"
echo "  💻 桌面端: >1024px"
echo ""
echo -e "${BLUE}🧪 测试建议:${NC}"
echo "  1. 使用手机浏览器访问"
echo "  2. 测试不同屏幕方向"
echo "  3. 验证触摸交互"
echo "  4. 检查字体可读性"
echo "  5. 测试按钮点击"
echo ""

echo -e "${GREEN}🎊 部署完成！${NC}"
