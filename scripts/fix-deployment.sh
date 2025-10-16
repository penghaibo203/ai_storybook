#!/bin/bash

# 修复部署问题脚本
# 解决CSS/JS资源加载和CSP问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复AI英文绘本应用部署问题${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 检查文件结构...${NC}"

# 检查必要文件
required_files=("index.html" "main.js" "style.css" "storyRenderer.js" "server-https.js")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ 缺少文件: $file${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ 所有必要文件存在${NC}"

# 检查PM2进程
echo -e "${YELLOW}🔍 检查PM2进程...${NC}"
if pm2 list | grep -q "ai-storybook"; then
    echo -e "${YELLOW}🛑 停止现有PM2进程...${NC}"
    pm2 stop ai-storybook || true
    pm2 delete ai-storybook || true
fi

# 重新安装依赖
echo -e "${YELLOW}📦 重新安装依赖...${NC}"
npm install --production

# 设置环境变量
echo -e "${YELLOW}🔧 设置环境变量...${NC}"
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

cat > .env << EOF
NODE_ENV=production
PORT=3000
COZE_API_TOKEN=$COZE_API_TOKEN
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978
EOF

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

# 测试静态文件
echo -e "${YELLOW}🔍 测试静态文件访问...${NC}"
if curl -f -s http://localhost:3000/main.js > /dev/null 2>&1; then
    echo -e "${GREEN}✅ main.js 可访问${NC}"
else
    echo -e "${RED}❌ main.js 无法访问${NC}"
fi

if curl -f -s http://localhost:3000/style.css > /dev/null 2>&1; then
    echo -e "${GREEN}✅ style.css 可访问${NC}"
else
    echo -e "${RED}❌ style.css 无法访问${NC}"
fi

# 显示服务状态
echo -e "${YELLOW}📊 显示服务状态...${NC}"
pm2 status

# 创建Nginx配置建议
echo -e "${YELLOW}📋 创建Nginx配置建议...${NC}"
cat > nginx-fix.conf << EOF
# 修复后的Nginx配置
# 请将此配置添加到您的Nginx站点配置中

# HTTP重定向到HTTPS
server {
    listen 80;
    server_name hypersmart.work www.hypersmart.work;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS配置
server {
    listen 443 ssl http2;
    server_name hypersmart.work www.hypersmart.work;

    # SSL证书配置
    ssl_certificate /path/to/ssl/hypersmart.work_bundle.crt;
    ssl_certificate_key /path/to/ssl/hypersmart.work.key;
    
    # SSL安全配置
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20";
    ssl_prefer_server_ciphers on;
    
    # 安全头部
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "DENY";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    
    # 静态文件缓存和代理
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        expires 1d;
        add_header Cache-Control "public";
    }
    
    # 代理到Node.js应用
    location / {
        proxy_pass http://localhost:3000;
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
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
EOF

# 显示修复结果
echo ""
echo -e "${GREEN}🎉 部署问题修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  域名: https://hypersmart.work (需要配置Nginx)"
echo ""
echo -e "${BLUE}📋 管理命令:${NC}"
echo "  查看应用日志: pm2 logs ai-storybook"
echo "  重启应用: pm2 restart ai-storybook"
echo "  停止应用: pm2 stop ai-storybook"
echo "  查看状态: pm2 status"
echo ""
echo -e "${BLUE}🔧 Nginx配置:${NC}"
echo "  修复后的Nginx配置已创建: nginx-fix.conf"
echo "  请将此配置添加到您的Nginx站点配置中"
echo "  然后重启Nginx服务"
echo ""
echo -e "${YELLOW}⚠️  重要提示:${NC}"
echo "  1. 确保Nginx正确代理所有静态文件到 localhost:3000"
echo "  2. 检查SSL证书路径是否正确"
echo "  3. 重启Nginx后测试: curl -k https://hypersmart.work/health"
echo ""

echo -e "${GREEN}🎊 修复完成！${NC}"
