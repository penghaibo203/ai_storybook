#!/bin/bash

# HTTPS部署脚本
# 用于部署AI英文绘本应用到生产环境

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
DOCKER_COMPOSE_FILE="docker-compose.https.yml"

echo -e "${GREEN}🚀 AI英文绘本应用 - HTTPS部署脚本${NC}"
echo "=============================================="

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker未安装，请先安装Docker${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose未安装，请先安装Docker Compose${NC}"
    exit 1
fi

# 检查环境变量
echo -e "${YELLOW}🔍 检查环境变量...${NC}"
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

# 检查SSL证书
echo -e "${YELLOW}🔐 检查SSL证书...${NC}"
if [ ! -f "ssl/fullchain.pem" ] || [ ! -f "ssl/privkey.pem" ]; then
    echo -e "${YELLOW}⚠️  SSL证书不存在，运行证书生成脚本...${NC}"
    ./scripts/generate-ssl.sh
fi

# 停止现有容器
echo -e "${YELLOW}🛑 停止现有容器...${NC}"
docker-compose -f "$DOCKER_COMPOSE_FILE" down || true

# 构建新镜像
echo -e "${YELLOW}🔨 构建应用镜像...${NC}"
docker-compose -f "$DOCKER_COMPOSE_FILE" build --no-cache

# 启动服务
echo -e "${YELLOW}🚀 启动服务...${NC}"
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d

# 等待服务启动
echo -e "${YELLOW}⏳ 等待服务启动...${NC}"
sleep 10

# 健康检查
echo -e "${YELLOW}🏥 执行健康检查...${NC}"
for i in {1..30}; do
    if curl -f -s http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 应用健康检查通过${NC}"
        break
    fi
    echo "等待应用启动... ($i/30)"
    sleep 2
done

# 检查服务状态
echo -e "${YELLOW}📊 检查服务状态...${NC}"
docker-compose -f "$DOCKER_COMPOSE_FILE" ps

# 测试HTTPS连接
echo -e "${YELLOW}🔒 测试HTTPS连接...${NC}"
if curl -k -f -s https://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✅ HTTPS连接正常${NC}"
else
    echo -e "${RED}❌ HTTPS连接失败${NC}"
    echo "请检查Nginx配置和SSL证书"
fi

# 显示访问信息
echo ""
echo -e "${GREEN}🎉 部署完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🌐 访问地址:${NC}"
echo "  HTTP:  http://$DOMAIN (自动重定向到HTTPS)"
echo "  HTTPS: https://$DOMAIN"
echo ""
echo -e "${BLUE}📋 管理命令:${NC}"
echo "  查看日志: docker-compose -f $DOCKER_COMPOSE_FILE logs -f"
echo "  重启服务: docker-compose -f $DOCKER_COMPOSE_FILE restart"
echo "  停止服务: docker-compose -f $DOCKER_COMPOSE_FILE down"
echo ""
echo -e "${BLUE}🔧 监控命令:${NC}"
echo "  容器状态: docker-compose -f $DOCKER_COMPOSE_FILE ps"
echo "  资源使用: docker stats"
echo "  Nginx日志: docker logs ai-storybook-nginx"
echo ""

# 设置自动重启（可选）
read -p "是否设置系统启动时自动启动服务? (y/n): " auto_start
if [[ $auto_start =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}🔧 设置自动启动...${NC}"
    
    # 创建systemd服务文件
    sudo tee /etc/systemd/system/ai-storybook.service > /dev/null << EOF
[Unit]
Description=AI Storybook Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/docker-compose -f $(pwd)/$DOCKER_COMPOSE_FILE up -d
ExecStop=/usr/bin/docker-compose -f $(pwd)/$DOCKER_COMPOSE_FILE down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ai-storybook.service
    
    echo -e "${GREEN}✅ 自动启动已配置${NC}"
fi

echo -e "${GREEN}🎊 部署脚本执行完成！${NC}"
