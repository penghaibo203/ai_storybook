#!/bin/bash

# HTTPS启动脚本
# 使用内置HTTPS支持，无需Nginx

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 启动AI英文绘本应用 - HTTPS模式${NC}"
echo "=============================================="

# 检查环境变量
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

# 检查SSL证书
echo -e "${YELLOW}🔐 检查SSL证书...${NC}"
if [ ! -f "ssl/hypersmart.work_bundle.crt" ] || [ ! -f "ssl/hypersmart.work.key" ]; then
    echo -e "${YELLOW}⚠️  SSL证书文件不存在${NC}"
    echo "将启动HTTP模式，如需HTTPS请准备证书文件:"
    echo "  - ssl/hypersmart.work_bundle.crt"
    echo "  - ssl/hypersmart.work.key"
    echo ""
    echo "如需生成证书，请运行:"
    echo "  ./scripts/generate-ssl.sh"
    echo ""
    read -p "是否继续启动HTTP模式? (y/n): " continue_http
    if [[ ! $continue_http =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ 启动已取消${NC}"
        exit 1
    fi
    echo -e "${YELLOW}🌐 启动HTTP模式...${NC}"
    npm start
    exit 0
fi

echo -e "${GREEN}✅ SSL证书文件存在${NC}"

# 检查.env文件
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ 加载.env文件${NC}"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${YELLOW}⚠️  .env文件不存在，使用环境变量${NC}"
fi

# 创建日志目录
mkdir -p logs

# 启动HTTPS应用
echo -e "${GREEN}🚀 启动HTTPS应用...${NC}"
echo "环境: $NODE_ENV"
echo "HTTP端口: $PORT"
echo "HTTPS端口: $HTTPS_PORT"
echo ""

# 使用PM2启动HTTPS版本
if command -v pm2 &> /dev/null; then
    echo -e "${BLUE}使用PM2启动HTTPS服务...${NC}"
    pm2 start ecosystem-https.config.cjs --env production
    pm2 save
    
    echo -e "${BLUE}📊 应用状态:${NC}"
    pm2 status
    
    echo -e "${BLUE}📋 管理命令:${NC}"
    echo "  查看日志: pm2 logs ai-storybook-https"
    echo "  重启应用: pm2 restart ai-storybook-https"
    echo "  停止应用: pm2 stop ai-storybook-https"
    echo "  监控面板: pm2 monit"
else
    echo -e "${BLUE}直接启动HTTPS服务...${NC}"
    node server-https.js
fi

echo -e "${GREEN}🎊 HTTPS应用启动完成！${NC}"
