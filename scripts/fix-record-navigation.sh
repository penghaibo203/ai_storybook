#!/bin/bash

# 修复记录跳转功能

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复记录跳转功能${NC}"
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
echo -e "${GREEN}🎉 记录跳转功能修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 修复记录数据结构兼容性"
echo "  ✅ 添加调试日志信息"
echo "  ✅ 优化字段名称处理"
echo "  ✅ 增强错误处理机制"
echo ""
echo -e "${BLUE}🌐 测试地址:${NC}"
echo "  记录页面: http://localhost:3000/records.html"
echo "  主页面: http://localhost:3000"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问记录页面"
echo "  2. 点击'查看绘本'按钮"
echo "  3. 检查是否跳转到主页面"
echo "  4. 查看浏览器控制台调试信息"
echo ""
echo -e "${BLUE}🔍 调试信息:${NC}"
echo "  - 记录页面会输出: '🔍 点击查看记录: [ID]'"
echo "  - 主页面会输出: '🔍 检测到记录ID: [ID]'"
echo "  - API响应会显示完整的数据结构"
echo ""

echo -e "${GREEN}🎊 修复完成！${NC}"
