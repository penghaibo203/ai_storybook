#!/bin/bash

# AI英文绘本应用 - 快速部署脚本
# 支持开发环境、生产环境和HTTPS部署

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
APP_NAME="ai-storybook"
DOMAIN="hypersmart.work"
DEFAULT_PORT=3000

echo -e "${GREEN}🚀 AI英文绘本应用 - 快速部署脚本${NC}"
echo "=============================================="

# 检查系统要求
check_requirements() {
    echo -e "${YELLOW}🔍 检查系统要求...${NC}"
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js未安装${NC}"
        echo "请安装Node.js 18.0.0或更高版本"
        exit 1
    fi
    
    # 检查npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}❌ npm未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 系统要求检查通过${NC}"
}

# 安装依赖
install_dependencies() {
    echo -e "${YELLOW}📦 安装依赖...${NC}"
    
    if [ ! -f "package.json" ]; then
        echo -e "${RED}❌ package.json文件不存在${NC}"
        exit 1
    fi
    
    npm install
    echo -e "${GREEN}✅ 依赖安装完成${NC}"
}

# 配置环境变量
setup_environment() {
    echo -e "${YELLOW}⚙️  配置环境变量...${NC}"
    
    if [ ! -f ".env" ]; then
        if [ -f "env.example" ]; then
            cp env.example .env
            echo -e "${YELLOW}📝 已创建.env文件，请编辑配置${NC}"
        else
            echo -e "${YELLOW}📝 创建.env文件...${NC}"
            cat > .env << EOF
# Coze API 配置
COZE_API_TOKEN=your_coze_api_token_here
COZE_BASE_URL=https://api.coze.cn
COZE_WORKFLOW_ID=7561291747888807978

# 服务器配置
PORT=3000
NODE_ENV=development
EOF
        fi
        
        echo -e "${RED}⚠️  请编辑.env文件，设置真实的API Token${NC}"
        echo "文件位置: $(pwd)/.env"
        read -p "按Enter键继续..." 
    fi
}

# 开发环境部署
deploy_development() {
    echo -e "${YELLOW}🛠️  部署开发环境...${NC}"
    
    # 检查端口是否被占用
    if lsof -Pi :$DEFAULT_PORT -sTCP:LISTEN -t >/dev/null; then
        echo -e "${YELLOW}⚠️  端口 $DEFAULT_PORT 已被占用${NC}"
        read -p "是否继续? (y/n): " continue_deploy
        if [[ ! $continue_deploy =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${BLUE}🚀 启动开发服务器...${NC}"
    echo "访问地址: http://localhost:$DEFAULT_PORT"
    echo "按 Ctrl+C 停止服务器"
    echo ""
    
    npm run dev
}

# 生产环境部署
deploy_production() {
    echo -e "${YELLOW}🏭 部署生产环境...${NC}"
    
    # 检查PM2是否安装
    if ! command -v pm2 &> /dev/null; then
        echo -e "${YELLOW}📦 安装PM2...${NC}"
        npm install -g pm2
    fi
    
    # 构建生产版本
    echo -e "${YELLOW}🔨 构建生产版本...${NC}"
    npm run build 2>/dev/null || echo "跳过构建步骤"
    
    # 启动PM2
    echo -e "${YELLOW}🚀 启动PM2进程...${NC}"
    pm2 start server.js --name "$APP_NAME" --env production
    
    # 保存PM2配置
    pm2 save
    pm2 startup
    
    echo -e "${GREEN}✅ 生产环境部署完成${NC}"
    echo "管理命令:"
    echo "  查看状态: pm2 status"
    echo "  查看日志: pm2 logs $APP_NAME"
    echo "  重启应用: pm2 restart $APP_NAME"
    echo "  停止应用: pm2 stop $APP_NAME"
}

# HTTPS部署
deploy_https() {
    echo -e "${YELLOW}🔒 部署HTTPS环境...${NC}"
    
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
    if [ -z "$COZE_API_TOKEN" ]; then
        echo -e "${RED}❌ 环境变量 COZE_API_TOKEN 未设置${NC}"
        echo "请设置: export COZE_API_TOKEN=your_token_here"
        exit 1
    fi
    
    # 运行HTTPS部署脚本
    if [ -f "scripts/deploy-https.sh" ]; then
        ./scripts/deploy-https.sh
    else
        echo -e "${YELLOW}🔧 使用Docker Compose部署...${NC}"
        docker-compose -f docker-compose.https.yml up -d
    fi
}

# 健康检查
health_check() {
    echo -e "${YELLOW}🏥 执行健康检查...${NC}"
    
    local url="http://localhost:$DEFAULT_PORT"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url/health" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 应用健康检查通过${NC}"
            return 0
        fi
        echo "等待应用启动... ($attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ 健康检查失败${NC}"
    return 1
}

# 显示部署信息
show_deployment_info() {
    echo ""
    echo -e "${GREEN}🎉 部署完成！${NC}"
    echo "=============================================="
    echo -e "${BLUE}🌐 访问信息:${NC}"
    echo "  本地访问: http://localhost:$DEFAULT_PORT"
    echo "  健康检查: http://localhost:$DEFAULT_PORT/health"
    echo ""
    echo -e "${BLUE}📋 管理命令:${NC}"
    echo "  查看日志: npm run dev (开发) 或 pm2 logs $APP_NAME (生产)"
    echo "  停止服务: Ctrl+C (开发) 或 pm2 stop $APP_NAME (生产)"
    echo "  重启服务: pm2 restart $APP_NAME (生产)"
    echo ""
    echo -e "${BLUE}🔧 故障排除:${NC}"
    echo "  检查端口: lsof -i :$DEFAULT_PORT"
    echo "  检查进程: ps aux | grep node"
    echo "  查看日志: tail -f logs/app.log"
    echo ""
}

# 主菜单
show_menu() {
    echo -e "${BLUE}请选择部署类型:${NC}"
    echo "1) 开发环境 (npm run dev)"
    echo "2) 生产环境 (PM2)"
    echo "3) HTTPS环境 (Docker)"
    echo "4) 仅安装依赖"
    echo "5) 健康检查"
    echo "6) 退出"
    echo ""
}

# 主函数
main() {
    # 检查是否在项目目录
    if [ ! -f "package.json" ]; then
        echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
        exit 1
    fi
    
    # 检查系统要求
    check_requirements
    
    while true; do
        show_menu
        read -p "请输入选择 (1-6): " choice
        
        case $choice in
            1)
                install_dependencies
                setup_environment
                deploy_development
                break
                ;;
            2)
                install_dependencies
                setup_environment
                deploy_production
                show_deployment_info
                break
                ;;
            3)
                install_dependencies
                setup_environment
                deploy_https
                show_deployment_info
                break
                ;;
            4)
                install_dependencies
                echo -e "${GREEN}✅ 依赖安装完成${NC}"
                ;;
            5)
                health_check
                ;;
            6)
                echo -e "${YELLOW}👋 退出部署脚本${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ 无效选择，请重新输入${NC}"
                ;;
        esac
    done
}

# 运行主函数
main "$@"
