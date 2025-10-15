#!/bin/bash

# 原生部署脚本（非Docker，非root）
# 使用PM2 + 本地Nginx配置

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
APP_NAME="ai-storybook"
PORT=3000

echo -e "${GREEN}🚀 AI英文绘本应用 - 原生部署${NC}"
echo "=============================================="

# 检查环境变量
echo -e "${YELLOW}🔍 检查环境变量...${NC}"
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js未安装，请先安装Node.js${NC}"
    echo "安装指南: https://nodejs.org/"
    exit 1
fi

# 检查PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}📦 安装PM2...${NC}"
    npm install -g pm2
fi

# 安装依赖
echo -e "${YELLOW}📦 安装依赖...${NC}"
npm install --production

# 创建日志目录
echo -e "${YELLOW}📁 创建日志目录...${NC}"
mkdir -p logs

# 设置环境变量
echo -e "${YELLOW}🔧 设置环境变量...${NC}"
cat > .env << EOF
NODE_ENV=production
PORT=$PORT
COZE_API_TOKEN=$COZE_API_TOKEN
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978
EOF

# 停止现有PM2进程
echo -e "${YELLOW}🛑 停止现有PM2进程...${NC}"
pm2 stop "$APP_NAME" || true
pm2 delete "$APP_NAME" || true

# 启动应用
echo -e "${YELLOW}🚀 启动应用...${NC}"
# 优先使用.cjs文件，如果不存在则使用.mjs
if [ -f "ecosystem.config.cjs" ]; then
    pm2 start ecosystem.config.cjs --env production
elif [ -f "ecosystem.config.mjs" ]; then
    pm2 start ecosystem.config.mjs --env production
else
    echo -e "${RED}❌ PM2配置文件不存在${NC}"
    exit 1
fi
pm2 save

# 等待服务启动
echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
sleep 5

# 健康检查
echo -e "${YELLOW}🏥 执行健康检查...${NC}"
for i in {1..30}; do
    if curl -f -s http://localhost:$PORT/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 应用健康检查通过${NC}"
        break
    fi
    echo "等待应用启动... ($i/30)"
    sleep 2
done

# 显示服务状态
echo -e "${YELLOW}📊 显示服务状态...${NC}"
pm2 status

# 显示访问信息
echo ""
echo -e "${GREEN}🎉 原生部署完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  HTTP: http://localhost:$PORT"
echo "  HTTP: http://127.0.0.1:$PORT"
echo ""
echo -e "${BLUE}📋 管理命令:${NC}"
echo "  查看应用日志: pm2 logs $APP_NAME"
echo "  重启应用: pm2 restart $APP_NAME"
echo "  停止应用: pm2 stop $APP_NAME"
echo "  查看状态: pm2 status"
echo "  监控面板: pm2 monit"
echo ""
echo -e "${BLUE}🔧 高级管理:${NC}"
echo "  设置开机自启: pm2 startup"
echo "  保存当前配置: pm2 save"
echo "  重载配置: pm2 reload $APP_NAME"
echo "  查看详细信息: pm2 show $APP_NAME"
echo ""

# 检查是否需要配置反向代理
read -p "是否需要配置Nginx反向代理? (y/n): " setup_nginx
if [[ $setup_nginx =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🔧 配置Nginx反向代理...${NC}"
    
    # 创建Nginx配置模板
    cat > nginx.conf.template << EOF
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    
    echo -e "${GREEN}✅ Nginx配置模板已创建: nginx.conf.template${NC}"
    echo "请将此配置添加到您的Nginx站点配置中"
fi

echo -e "${GREEN}🎊 原生部署完成！${NC}"
