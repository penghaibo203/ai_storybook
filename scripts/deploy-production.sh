#!/bin/bash

# AI英文绘本生产环境部署脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🚀 AI英文绘本生产环境部署${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 检查是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  检测到root用户，建议使用普通用户运行${NC}"
    read -p "是否继续? (y/n): " continue_as_root
    if [[ ! $continue_as_root =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}1. 检查系统环境${NC}"
# 检查操作系统
OS=$(uname -s)
echo "操作系统: $OS"

# 检查Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js未安装${NC}"
    exit 1
fi

# 检查PM2
if command -v pm2 &> /dev/null; then
    PM2_VERSION=$(pm2 --version)
    echo -e "${GREEN}✅ PM2: $PM2_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  PM2未安装，正在安装...${NC}"
    npm install -g pm2
fi

echo -e "${BLUE}2. 安装项目依赖${NC}"
npm install --production

echo -e "${BLUE}3. 检查环境配置${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env文件不存在，创建示例文件${NC}"
    cat > .env << EOF
# Coze API配置
COZE_API_TOKEN=your_api_token_here

# 服务器配置
NODE_ENV=production
PORT=3000

# 日志配置
LOG_LEVEL=info
EOF
    echo -e "${YELLOW}⚠️  请编辑.env文件配置API Token${NC}"
fi

echo -e "${BLUE}4. 创建必要目录${NC}"
mkdir -p data logs

echo -e "${BLUE}5. 停止现有服务${NC}"
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

echo -e "${BLUE}6. 启动生产服务${NC}"
# 使用集群模式启动
if [ -f "ecosystem.config.cjs" ]; then
    pm2 start ecosystem.config.cjs --env production
else
    pm2 start server.js --name ai-storybook --instances max --env production
fi

pm2 save

echo -e "${BLUE}7. 等待服务启动${NC}"
sleep 5

echo -e "${BLUE}8. 检查服务状态${NC}"
pm2 status

echo -e "${BLUE}9. 测试服务${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 服务健康检查通过${NC}"
else
    echo -e "${YELLOW}⚠️  服务可能未完全启动，请检查日志${NC}"
fi

echo -e "${BLUE}10. 配置Nginx (可选)${NC}"
if command -v nginx &> /dev/null; then
    echo -e "${GREEN}✅ Nginx已安装${NC}"
    read -p "是否配置Nginx反向代理? (y/n): " config_nginx
    if [[ $config_nginx =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}配置Nginx反向代理...${NC}"
        
        # 创建Nginx配置
        sudo tee /etc/nginx/sites-available/ai-storybook > /dev/null << EOF
server {
    listen 80;
    server_name _;
    
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
    }
}
EOF
        
        # 启用站点
        sudo ln -sf /etc/nginx/sites-available/ai-storybook /etc/nginx/sites-enabled/
        
        # 测试配置
        sudo nginx -t
        
        # 重启Nginx
        sudo systemctl restart nginx
        
        echo -e "${GREEN}✅ Nginx配置完成${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Nginx未安装，跳过反向代理配置${NC}"
fi

echo -e "${BLUE}11. 设置开机自启${NC}"
read -p "是否设置PM2开机自启? (y/n): " auto_start
if [[ $auto_start =~ ^[Yy]$ ]]; then
    pm2 startup
    echo -e "${GREEN}✅ 开机自启已设置${NC}"
    echo -e "${YELLOW}💡 请按照提示运行生成的命令${NC}"
fi

echo ""
echo -e "${GREEN}🎉 生产环境部署完成！${NC}"
echo "=============================================="
echo -e "${BLUE}📋 服务信息:${NC}"
echo "  服务名称: ai-storybook"
echo "  运行模式: 集群模式"
echo "  进程数量: $(pm2 list | grep ai-storybook | wc -l)"
echo "  内存使用: $(pm2 list | grep ai-storybook | awk '{print $10}' | head -1)"
echo ""
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  本地: http://localhost:3000"
if command -v nginx &> /dev/null; then
    echo "  外网: http://$(curl -s ifconfig.me):80"
fi
echo ""
echo -e "${BLUE}📊 管理命令:${NC}"
echo "  查看状态: pm2 status"
echo "  查看日志: pm2 logs"
echo "  重启服务: pm2 restart all"
echo "  停止服务: pm2 stop all"
echo "  监控面板: pm2 monit"
echo ""

echo -e "${GREEN}🎊 部署完成！服务正在运行中${NC}"
