#!/bin/bash

# 重启应用并启用绘本记录功能

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 重启应用并启用绘本记录功能${NC}"
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

# 创建数据目录
echo -e "${YELLOW}📁 创建数据目录...${NC}"
mkdir -p data

# 重新安装依赖
echo -e "${YELLOW}📦 重新安装依赖...${NC}"
npm install --production

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

# 测试新功能
echo -e "${YELLOW}🧪 测试绘本记录功能...${NC}"
if curl -f -s http://localhost:3000/api/records > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 绘本记录API正常${NC}"
else
    echo -e "${RED}❌ 绘本记录API异常${NC}"
fi

# 显示服务状态
echo -e "${YELLOW}📊 显示服务状态...${NC}"
pm2 status

echo ""
echo -e "${GREEN}🎉 绘本记录功能已启用！${NC}"
echo "=============================================="
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  主页: http://localhost:3000"
echo "  记录页: http://localhost:3000/records.html"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}📋 新功能:${NC}"
echo "  ✅ 自动保存生成的绘本记录"
echo "  ✅ 查看所有历史绘本"
echo "  ✅ 点击标题重新查看绘本"
echo "  ✅ 删除不需要的记录"
echo "  ✅ 统计信息显示"
echo ""
echo -e "${BLUE}📁 数据存储:${NC}"
echo "  记录文件: ./data/storybook-records.json"
echo "  自动创建数据目录"
echo ""

echo -e "${GREEN}🎊 重启完成！${NC}"
