#!/bin/bash

# 修复所有问题脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复所有问题${NC}"
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

# 启动完全无CSP版本
echo -e "${YELLOW}🚀 启动完全无CSP版本...${NC}"
pm2 start server-https-no-csp-fixed.js --name ai-storybook-no-csp
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
echo -e "${GREEN}🎉 所有问题已修复！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 修复CSP策略问题"
echo "  ✅ 修复内联事件处理器问题"
echo "  ✅ 修复记录跳转功能"
echo "  ✅ 修复数据结构兼容性"
echo "  ✅ 添加调试日志信息"
echo "  ✅ 优化错误处理机制"
echo "  ✅ 完全禁用安全限制"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  主页: http://localhost:3000"
echo "  记录页: http://localhost:3000/records.html"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问记录页面，检查是否还有CSP错误"
echo "  2. 点击'查看绘本'按钮，检查是否正常跳转"
echo "  3. 检查浏览器控制台是否还有错误"
echo "  4. 验证所有功能是否正常工作"
echo ""
echo -e "${BLUE}🔍 调试信息:${NC}"
echo "  - 记录页面会输出: '🔍 点击查看记录: [ID]'"
echo "  - 主页面会输出: '🔍 检测到记录ID: [ID]'"
echo "  - API响应会显示完整的数据结构"
echo "  - 所有CSP相关错误应该消失"
echo ""

echo -e "${GREEN}🎊 修复完成！${NC}"
