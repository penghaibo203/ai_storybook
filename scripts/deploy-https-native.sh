#!/bin/bash

# 原生HTTPS部署脚本（非Docker）
# 使用PM2 + Nginx直接部署

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
APP_DIR="/opt/ai-storybook"
NGINX_CONF="/etc/nginx/sites-available/ai-storybook"
NGINX_ENABLED="/etc/nginx/sites-enabled/ai-storybook"
PM2_APP_NAME="ai-storybook"

echo -e "${GREEN}🚀 AI英文绘本应用 - 原生HTTPS部署${NC}"
echo "=============================================="

# 检查是否以root权限运行
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ 此脚本需要root权限运行${NC}"
    echo "请使用: sudo ./scripts/deploy-https-native.sh"
    exit 1
fi

# 检查环境变量
echo -e "${YELLOW}🔍 检查环境变量...${NC}"
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

# 检查必要工具
echo -e "${YELLOW}🔧 检查必要工具...${NC}"

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "ubuntu"
        elif command -v yum &> /dev/null; then
            echo "centos"
        elif command -v dnf &> /dev/null; then
            echo "fedora"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo -e "${BLUE}检测到操作系统: $OS${NC}"

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}📦 安装Node.js...${NC}"
    case $OS in
        "ubuntu")
            curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
            apt-get install -y nodejs
            ;;
        "centos"|"fedora")
            curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
            if command -v yum &> /dev/null; then
                yum install -y nodejs
            else
                dnf install -y nodejs
            fi
            ;;
        "macos")
            echo -e "${RED}❌ 请使用Homebrew安装Node.js: brew install node${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}❌ 不支持的操作系统，请手动安装Node.js${NC}"
            exit 1
            ;;
    esac
fi

# 检查PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}📦 安装PM2...${NC}"
    npm install -g pm2
fi

# 检查Nginx
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}📦 安装Nginx...${NC}"
    case $OS in
        "ubuntu")
            apt-get update
            apt-get install -y nginx
            ;;
        "centos"|"fedora")
            if command -v yum &> /dev/null; then
                yum install -y nginx
            else
                dnf install -y nginx
            fi
            ;;
        "macos")
            echo -e "${RED}❌ 请使用Homebrew安装Nginx: brew install nginx${NC}"
            exit 1
            ;;
        *)
            echo -e "${RED}❌ 不支持的操作系统，请手动安装Nginx${NC}"
            exit 1
            ;;
    esac
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

# 创建应用目录
echo -e "${YELLOW}📁 创建应用目录...${NC}"
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/logs"

# 复制应用文件
echo -e "${YELLOW}📋 复制应用文件...${NC}"
cp -r . "$APP_DIR/"
cd "$APP_DIR"

# 安装依赖
echo -e "${YELLOW}📦 安装依赖...${NC}"
npm install --production

# 设置环境变量
echo -e "${YELLOW}🔧 设置环境变量...${NC}"
cat > "$APP_DIR/.env" << EOF
NODE_ENV=production
PORT=3000
COZE_API_TOKEN=$COZE_API_TOKEN
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978
EOF

# 停止现有PM2进程
echo -e "${YELLOW}🛑 停止现有PM2进程...${NC}"
pm2 stop "$PM2_APP_NAME" || true
pm2 delete "$PM2_APP_NAME" || true

# 启动应用
echo -e "${YELLOW}🚀 启动应用...${NC}"
pm2 start server.js --name "$PM2_APP_NAME" --env production
pm2 save
pm2 startup

# 配置Nginx
echo -e "${YELLOW}🔧 配置Nginx...${NC}"

# 创建Nginx配置
cat > "$NGINX_CONF" << EOF
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
    ssl_certificate $APP_DIR/ssl/hypersmart.work_bundle.crt;
    ssl_certificate_key $APP_DIR/ssl/hypersmart.work.key;
    
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
    
    # 错误页面
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

# 启用站点
echo -e "${YELLOW}🔗 启用Nginx站点...${NC}"
ln -sf "$NGINX_CONF" "$NGINX_ENABLED"

# 测试Nginx配置
echo -e "${YELLOW}🧪 测试Nginx配置...${NC}"
nginx -t

# 重启Nginx
echo -e "${YELLOW}🔄 重启Nginx...${NC}"
case $OS in
    "ubuntu"|"centos"|"fedora")
        systemctl restart nginx
        systemctl enable nginx
        ;;
    "macos")
        brew services restart nginx
        ;;
    *)
        echo -e "${YELLOW}⚠️  请手动重启Nginx服务${NC}"
        ;;
esac

# 等待服务启动
echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
sleep 5

# 健康检查
echo -e "${YELLOW}🏥 执行健康检查...${NC}"
for i in {1..30}; do
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 应用健康检查通过${NC}"
        break
    fi
    echo "等待应用启动... ($i/30)"
    sleep 2
done

# 测试HTTPS连接
echo -e "${YELLOW}🔒 测试HTTPS连接...${NC}"
if curl -k -f -s https://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✅ HTTPS连接正常${NC}"
else
    echo -e "${RED}❌ HTTPS连接失败${NC}"
    echo "请检查Nginx配置和SSL证书"
fi

# 显示服务状态
echo -e "${YELLOW}📊 显示服务状态...${NC}"
echo ""
echo -e "${BLUE}PM2进程状态:${NC}"
pm2 status
echo ""
echo -e "${BLUE}Nginx状态:${NC}"
case $OS in
    "ubuntu"|"centos"|"fedora")
        systemctl status nginx --no-pager -l
        ;;
    "macos")
        brew services list | grep nginx
        ;;
    *)
        echo "请手动检查Nginx状态"
        ;;
esac

# 显示访问信息
echo ""
echo -e "${GREEN}🎉 原生HTTPS部署完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  HTTP:  http://$DOMAIN (自动重定向到HTTPS)"
echo "  HTTPS: https://$DOMAIN"
echo ""
echo -e "${BLUE}📋 管理命令:${NC}"
echo "  查看应用日志: pm2 logs $PM2_APP_NAME"
echo "  重启应用: pm2 restart $PM2_APP_NAME"
echo "  停止应用: pm2 stop $PM2_APP_NAME"
echo "  查看Nginx日志: tail -f /var/log/nginx/access.log"
echo "  查看错误日志: tail -f /var/log/nginx/error.log"
echo ""
echo -e "${BLUE}🔧 监控命令:${NC}"
echo "  PM2状态: pm2 status"
echo "  PM2监控: pm2 monit"
echo "  Nginx状态: systemctl status nginx (Linux) 或 brew services list (macOS)"
echo "  系统资源: htop"
echo ""

echo -e "${GREEN}🎊 原生HTTPS部署完成！${NC}"
