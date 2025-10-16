#!/bin/bash

# AI英文绘本服务端启动脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 AI英文绘本服务端启动脚本${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 检查Node.js版本
echo -e "${BLUE}1. 检查Node.js环境${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js版本: $NODE_VERSION${NC}"
    
    # 检查版本是否满足要求 (>= 16.0.0)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1 | sed 's/v//')
    if [ "$NODE_MAJOR" -lt 16 ]; then
        echo -e "${RED}❌ Node.js版本过低，需要 >= 16.0.0${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Node.js未安装${NC}"
    exit 1
fi

# 检查PM2
echo -e "${BLUE}2. 检查PM2进程管理器${NC}"
if command -v pm2 &> /dev/null; then
    PM2_VERSION=$(pm2 --version)
    echo -e "${GREEN}✅ PM2版本: $PM2_VERSION${NC}"
else
    echo -e "${YELLOW}⚠️  PM2未安装，正在安装...${NC}"
    npm install -g pm2
    echo -e "${GREEN}✅ PM2安装完成${NC}"
fi

# 检查依赖
echo -e "${BLUE}3. 检查项目依赖${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  依赖未安装，正在安装...${NC}"
    npm install
    echo -e "${GREEN}✅ 依赖安装完成${NC}"
else
    echo -e "${GREEN}✅ 依赖已安装${NC}"
fi

# 检查环境变量
echo -e "${BLUE}4. 检查环境配置${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ 环境变量文件存在${NC}"
    if grep -q "COZE_API_TOKEN" .env; then
        echo -e "${GREEN}✅ API Token已配置${NC}"
    else
        echo -e "${YELLOW}⚠️  API Token未配置，请检查.env文件${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  .env文件不存在，将使用默认配置${NC}"
fi

# 检查数据目录
echo -e "${BLUE}5. 检查数据目录${NC}"
if [ ! -d "data" ]; then
    mkdir -p data
    echo -e "${GREEN}✅ 数据目录已创建${NC}"
else
    echo -e "${GREEN}✅ 数据目录存在${NC}"
fi

# 停止现有进程
echo -e "${BLUE}6. 停止现有进程${NC}"
pm2 stop all 2>/dev/null || true
pm2 delete all 2>/dev/null || true

# 选择启动模式
echo -e "${BLUE}7. 选择启动模式${NC}"
echo "请选择启动模式："
echo "1) HTTP模式 (端口3000)"
echo "2) HTTPS模式 (端口3443)"
echo "3) 开发模式 (自动重启)"
echo "4) 集群模式 (多进程)"

read -p "请输入选择 (1-4): " choice

case $choice in
    1)
        echo -e "${GREEN}🚀 启动HTTP模式${NC}"
        pm2 start server.js --name ai-storybook-http --env production
        ;;
    2)
        echo -e "${GREEN}🚀 启动HTTPS模式${NC}"
        if [ -f "server-https.js" ]; then
            pm2 start server-https.js --name ai-storybook-https --env production
        else
            echo -e "${RED}❌ HTTPS服务器文件不存在${NC}"
            exit 1
        fi
        ;;
    3)
        echo -e "${GREEN}🚀 启动开发模式${NC}"
        pm2 start server.js --name ai-storybook-dev --env development --watch
        ;;
    4)
        echo -e "${GREEN}🚀 启动集群模式${NC}"
        if [ -f "ecosystem.config.cjs" ]; then
            pm2 start ecosystem.config.cjs --env production
        else
            pm2 start server.js --name ai-storybook-cluster --instances max --env production
        fi
        ;;
    *)
        echo -e "${YELLOW}⚠️  无效选择，使用默认HTTP模式${NC}"
        pm2 start server.js --name ai-storybook --env production
        ;;
esac

# 保存PM2配置
pm2 save

# 等待服务启动
echo -e "${BLUE}8. 等待服务启动${NC}"
sleep 3

# 检查服务状态
echo -e "${BLUE}9. 检查服务状态${NC}"
pm2 status

# 测试服务
echo -e "${BLUE}10. 测试服务${NC}"
case $choice in
    2)
        if curl -f -s https://localhost:3443/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ HTTPS服务正常${NC}"
            echo -e "${BLUE}🌐 访问地址: https://localhost:3443${NC}"
        else
            echo -e "${YELLOW}⚠️  HTTPS服务可能未完全启动，请稍等${NC}"
        fi
        ;;
    *)
        if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ HTTP服务正常${NC}"
            echo -e "${BLUE}🌐 访问地址: http://localhost:3000${NC}"
        else
            echo -e "${YELLOW}⚠️  HTTP服务可能未完全启动，请稍等${NC}"
        fi
        ;;
esac

echo ""
echo -e "${GREEN}🎉 服务启动完成！${NC}"
echo "=============================================="
echo -e "${BLUE}📋 常用命令:${NC}"
echo "  查看状态: pm2 status"
echo "  查看日志: pm2 logs"
echo "  重启服务: pm2 restart all"
echo "  停止服务: pm2 stop all"
echo "  删除服务: pm2 delete all"
echo ""
echo -e "${BLUE}📊 监控命令:${NC}"
echo "  实时日志: pm2 logs --lines 50"
echo "  监控面板: pm2 monit"
echo "  查看详情: pm2 show ai-storybook"
echo ""

# 设置PM2开机自启
echo -e "${BLUE}11. 设置开机自启${NC}"
read -p "是否设置PM2开机自启? (y/n): " auto_start
if [[ $auto_start =~ ^[Yy]$ ]]; then
    pm2 startup
    echo -e "${GREEN}✅ 开机自启已设置${NC}"
    echo -e "${YELLOW}💡 请按照提示运行生成的命令${NC}"
fi

echo -e "${GREEN}🎊 启动脚本执行完成！${NC}"
