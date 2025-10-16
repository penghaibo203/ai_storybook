#!/bin/bash

# 启动完全无CSP版本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 启动完全无CSP版本${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 停止现有PM2进程
echo -e "${YELLOW}🛑 停止现有PM2进程...${NC}"
pm2 stop all || true
pm2 delete all || true

# 启动完全无CSP版本
echo -e "${YELLOW}🚀 启动完全无CSP版本...${NC}"
pm2 start ecosystem-no-csp.config.cjs --env production
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
echo -e "${GREEN}🎉 完全无CSP版本已启动！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 版本特点:${NC}"
echo "  ✅ 完全禁用CSP策略"
echo "  ✅ 允许所有外部脚本加载"
echo "  ✅ 允许所有内联事件处理器"
echo "  ✅ 禁用所有安全限制"
echo "  ✅ 解决infird.com脚本问题"
echo "  ✅ 解决记录跳转问题"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  主页: http://localhost:3000"
echo "  记录页: http://localhost:3000/records.html"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问记录页面"
echo "  2. 点击'查看绘本'按钮"
echo "  3. 检查是否正常跳转并显示绘本"
echo "  4. 检查浏览器控制台是否还有CSP错误"
echo ""

echo -e "${GREEN}🎊 启动完成！${NC}"
