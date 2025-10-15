#!/bin/bash

# SSL证书生成脚本
# 用于生成开发环境自签名证书或配置生产环境证书

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
DOMAIN="hypersmart.work"
SSL_DIR="./ssl"
CERT_DIR="/etc/ssl/certs"
KEY_DIR="/etc/ssl/private"

echo -e "${GREEN}🔐 SSL证书配置脚本${NC}"
echo "=================================="

# 检查是否以root权限运行
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ 请不要以root权限运行此脚本${NC}"
   echo "请使用普通用户权限运行，脚本会在需要时请求sudo权限"
   exit 1
fi

# 创建SSL目录
echo -e "${YELLOW}📁 创建SSL目录...${NC}"
mkdir -p "$SSL_DIR"

# 选择证书类型
echo -e "${YELLOW}请选择证书类型:${NC}"
echo "1) 开发环境自签名证书"
echo "2) 生产环境Let's Encrypt证书"
echo "3) 导入现有证书"
read -p "请输入选择 (1-3): " choice

case $choice in
    1)
        echo -e "${YELLOW}🔧 生成开发环境自签名证书...${NC}"
        
        # 生成私钥
        openssl genrsa -out "$SSL_DIR/dev-key.pem" 2048
        
        # 生成证书签名请求
        openssl req -new -key "$SSL_DIR/dev-key.pem" -out "$SSL_DIR/dev.csr" -subj "/C=CN/ST=State/L=City/O=Organization/CN=$DOMAIN"
        
        # 生成自签名证书
        openssl x509 -req -days 365 -in "$SSL_DIR/dev.csr" -signkey "$SSL_DIR/dev-key.pem" -out "$SSL_DIR/dev-cert.pem"
        
        # 清理临时文件
        rm "$SSL_DIR/dev.csr"
        
        echo -e "${GREEN}✅ 开发环境证书生成完成${NC}"
        echo "证书文件: $SSL_DIR/dev-cert.pem"
        echo "私钥文件: $SSL_DIR/dev-key.pem"
        ;;
        
    2)
        echo -e "${YELLOW}🌐 配置Let's Encrypt证书...${NC}"
        
        # 检查certbot是否安装
        if ! command -v certbot &> /dev/null; then
            echo -e "${YELLOW}📦 安装certbot...${NC}"
            sudo apt update
            sudo apt install -y certbot python3-certbot-nginx
        fi
        
        # 获取证书
        echo -e "${YELLOW}🔐 获取Let's Encrypt证书...${NC}"
        read -p "请输入邮箱地址: " email
        sudo certbot certonly --webroot -w /var/www/html -d "$DOMAIN" -d "www.$DOMAIN" --email "$email" --agree-tos --non-interactive
        
        # 复制证书到项目目录
        sudo cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/"
        sudo cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/"
        sudo cp "/etc/letsencrypt/live/$DOMAIN/cert.pem" "$SSL_DIR/"
        sudo cp "/etc/letsencrypt/live/$DOMAIN/chain.pem" "$SSL_DIR/"
        
        # 设置权限
        sudo chown $USER:$USER "$SSL_DIR"/*
        chmod 644 "$SSL_DIR"/*.pem
        chmod 600 "$SSL_DIR/privkey.pem"
        
        echo -e "${GREEN}✅ Let's Encrypt证书配置完成${NC}"
        ;;
        
    3)
        echo -e "${YELLOW}📁 导入现有证书...${NC}"
        echo "请将以下文件放入 $SSL_DIR 目录:"
        echo "- fullchain.pem (完整证书链)"
        echo "- privkey.pem (私钥)"
        echo "- cert.pem (服务器证书)"
        echo "- chain.pem (中间证书)"
        echo ""
        read -p "按Enter键继续..." 
        ;;
        
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

# 验证证书
echo -e "${YELLOW}🔍 验证证书...${NC}"
if [ -f "$SSL_DIR/fullchain.pem" ] && [ -f "$SSL_DIR/privkey.pem" ]; then
    echo -e "${GREEN}✅ 证书文件存在${NC}"
    
    # 检查证书有效期
    if command -v openssl &> /dev/null; then
        echo "证书信息:"
        openssl x509 -in "$SSL_DIR/fullchain.pem" -text -noout | grep -E "(Not Before|Not After|Subject:|Issuer:)"
    fi
else
    echo -e "${RED}❌ 证书文件缺失${NC}"
    exit 1
fi

# 生成Nginx配置
echo -e "${YELLOW}📝 生成Nginx配置...${NC}"
cat > hypersmart.work_nginx/nginx.conf << EOF
# 自动生成的Nginx配置
# 请根据实际部署情况调整路径

upstream ai_storybook_backend {
    server ai-storybook:3000;
}

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL证书配置 - 请根据实际路径调整
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    
    # SSL安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    
    # 安全头
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # 代理配置
    location / {
        proxy_pass http://ai_storybook_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

echo -e "${GREEN}🎉 SSL配置完成！${NC}"
echo ""
echo "下一步操作:"
echo "1. 检查证书文件: ls -la $SSL_DIR/"
echo "2. 启动应用: docker-compose -f docker-compose.https.yml up -d"
echo "3. 测试HTTPS: curl -k https://$DOMAIN"
echo ""
echo -e "${YELLOW}⚠️  注意: 请确保域名 $DOMAIN 已正确解析到服务器IP${NC}"
