#!/bin/bash

# 简化原生HTTPS部署脚本（跨平台兼容）
# 假设必要工具已安装

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DOMAIN="hypersmart.work"
APP_NAME="ai-storybook"
PORT=3000

echo -e "${GREEN}🚀 AI英文绘本应用 - 简化原生HTTPS部署${NC}"
echo "=============================================="

# 检查环境变量
echo -e "${YELLOW}🔍 检查环境变量...${NC}"
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

# 检查必要工具
echo -e "${YELLOW}🔧 检查必要工具...${NC}"

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js未安装${NC}"
    echo "请先安装Node.js: https://nodejs.org/"
    exit 1
fi

# 检查PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}📦 安装PM2...${NC}"
    npm install -g pm2
fi

# 检查SSL证书
echo -e "${YELLOW}🔐 检查SSL证书...${NC}"
if [ ! -f "ssl/hypersmart.work_bundle.crt" ] || [ ! -f "ssl/hypersmart.work.key" ]; then
    echo -e "${RED}❌ SSL证书文件不存在${NC}"
    echo "请确保以下文件存在:"
    echo "  - ssl/hypersmart.work_bundle.crt"
    echo "  - ssl/hypersmart.work.key"
    echo ""
    echo "如需生成证书，请运行:"
    echo "  ./scripts/generate-ssl.sh"
    exit 1
fi

echo -e "${GREEN}✅ SSL证书文件存在${NC}"

# 安装依赖
echo -e "${YELLOW}📦 安装依赖...${NC}"
npm install --production

# 创建日志目录
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
pm2 start ecosystem.config.cjs --env production
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

# 创建Nginx配置模板
echo -e "${YELLOW}🔧 创建Nginx配置模板...${NC}"
cat > nginx-https.conf << EOF
# HTTPS配置模板
# 请将此配置添加到您的Nginx站点配置中

# HTTP重定向到HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS配置
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # SSL证书配置
    ssl_certificate $(pwd)/ssl/hypersmart.work_bundle.crt;
    ssl_certificate_key $(pwd)/ssl/hypersmart.work.key;
    
    # SSL安全配置
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20";
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # 安全头部
    add_header X-Frame-Options "DENY";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    
    # 静态文件缓存
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files \$uri @app;
    }
    
    # 代理到Node.js应用
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
        proxy_redirect off;
    }
    
    # 健康检查
    location /health {
        proxy_pass http://localhost:$PORT/health;
        access_log off;
    }
}
EOF

# 显示访问信息
echo ""
echo -e "${GREEN}🎉 简化原生HTTPS部署完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  HTTP: http://localhost:$PORT"
echo "  HTTPS: https://$DOMAIN (需要配置Nginx)"
echo ""
echo -e "${BLUE}📋 管理命令:${NC}"
echo "  查看应用日志: pm2 logs $APP_NAME"
echo "  重启应用: pm2 restart $APP_NAME"
echo "  停止应用: pm2 stop $APP_NAME"
echo "  查看状态: pm2 status"
echo "  监控面板: pm2 monit"
echo ""
echo -e "${BLUE}🔧 Nginx配置:${NC}"
echo "  Nginx配置文件已创建: nginx-https.conf"
echo "  请将此配置添加到您的Nginx站点配置中"
echo "  然后重启Nginx服务"
echo ""

# 检查是否需要配置Nginx
read -p "是否需要帮助配置Nginx? (y/n): " setup_nginx
if [[ $setup_nginx =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🔧 Nginx配置指南:${NC}"
    echo ""
    echo "1. 将nginx-https.conf的内容复制到您的Nginx配置中"
    echo "2. 测试配置: nginx -t"
    echo "3. 重启Nginx:"
    echo "   - Ubuntu/Debian: sudo systemctl restart nginx"
    echo "   - CentOS/RHEL: sudo systemctl restart nginx"
    echo "   - macOS: brew services restart nginx"
    echo ""
    echo "4. 验证HTTPS: curl -k https://$DOMAIN/health"
fi

echo -e "${GREEN}🎊 简化原生HTTPS部署完成！${NC}"
