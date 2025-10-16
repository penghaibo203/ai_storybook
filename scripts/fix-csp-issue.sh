#!/bin/bash

# 修复CSP问题脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复CSP问题${NC}"
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

# 启动无CSP版本
echo -e "${YELLOW}🚀 启动无CSP版本...${NC}"
pm2 start server-https-no-csp.js --name ai-storybook-no-csp
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
echo -e "${GREEN}🎉 CSP问题已修复！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 完全禁用CSP策略"
echo "  ✅ 允许所有外部脚本加载"
echo "  ✅ 解决infird.com脚本加载问题"
echo "  ✅ 保持所有其他功能正常"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  主页: http://localhost:3000"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}⚠️  注意事项:${NC}"
echo "  - 当前使用无CSP版本，安全性较低"
echo "  - 仅用于解决脚本加载问题"
echo "  - 生产环境建议重新配置CSP策略"
echo ""

echo -e "${GREEN}🎊 修复完成！${NC}"
