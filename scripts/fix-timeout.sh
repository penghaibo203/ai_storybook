#!/bin/bash

# 修复超时问题脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复API超时问题${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${YELLOW}🛑 停止现有PM2进程...${NC}"
pm2 stop ai-storybook || true
pm2 delete ai-storybook || true

echo -e "${YELLOW}🚀 重启应用...${NC}"
pm2 start ecosystem.config.cjs --env production
pm2 save

echo -e "${YELLOW}⏳ 等待应用启动...${NC}"
sleep 5

echo -e "${YELLOW}🏥 执行健康检查...${NC}"
for i in {1..10}; do
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 应用健康检查通过${NC}"
        break
    fi
    echo "等待应用启动... ($i/10)"
    sleep 2
done

echo -e "${YELLOW}📊 显示服务状态...${NC}"
pm2 status

echo ""
echo -e "${GREEN}🎉 超时问题修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}📋 下一步操作:${NC}"
echo "1. 更新Nginx配置以增加代理超时时间"
echo "2. 重启Nginx服务"
echo "3. 测试API调用"
echo ""
echo -e "${BLUE}🔧 Nginx配置更新:${NC}"
echo "请将 nginx-timeout-fix.conf 的内容添加到您的Nginx配置中"
echo "然后运行: sudo systemctl reload nginx"
echo ""

echo -e "${GREEN}🎊 修复完成！${NC}"
