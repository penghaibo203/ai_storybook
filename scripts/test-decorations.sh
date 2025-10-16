#!/bin/bash

# 测试装饰元素显示逻辑

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🎨 测试装饰元素显示逻辑${NC}"
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
echo -e "${GREEN}🎉 装饰元素测试环境已准备就绪！${NC}"
echo "=============================================="
echo -e "${BLUE}🎨 装饰元素显示逻辑:${NC}"
echo "  ✅ 页面初始加载时：装饰元素隐藏"
echo "  ✅ 绘本生成成功时：装饰元素显示"
echo "  ✅ 绘本生成失败时：装饰元素隐藏"
echo "  ✅ 加载历史记录成功时：装饰元素显示"
echo "  ✅ 加载历史记录失败时：装饰元素隐藏"
echo ""
echo -e "${BLUE}🌐 测试地址:${NC}"
echo "  主页: http://localhost:3000"
echo "  生产地址: https://hypersmart.work"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问主页，确认装饰元素不显示"
echo "  2. 输入故事主题，点击生成"
echo "  3. 生成成功后，确认装饰元素显示"
echo "  4. 刷新页面，确认装饰元素重新隐藏"
echo ""

echo -e "${GREEN}🎊 测试环境准备完成！${NC}"
