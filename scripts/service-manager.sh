#!/bin/bash

# AI英文绘本服务管理脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 服务名称
SERVICE_NAME="ai-storybook"

# 显示帮助信息
show_help() {
    echo -e "${GREEN}AI英文绘本服务管理脚本${NC}"
    echo "=============================================="
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start     启动服务"
    echo "  stop      停止服务"
    echo "  restart   重启服务"
    echo "  status    查看状态"
    echo "  logs      查看日志"
    echo "  monitor   监控面板"
    echo "  health    健康检查"
    echo "  update    更新服务"
    echo "  backup    备份数据"
    echo "  help      显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 start"
    echo "  $0 logs --lines 50"
    echo "  $0 monitor"
}

# 启动服务
start_service() {
    echo -e "${BLUE}🚀 启动服务...${NC}"
    
    # 检查是否已在运行
    if pm2 list | grep -q "$SERVICE_NAME.*online"; then
        echo -e "${YELLOW}⚠️  服务已在运行${NC}"
        return 0
    fi
    
    # 启动服务
    if [ -f "ecosystem.config.cjs" ]; then
        pm2 start ecosystem.config.cjs --env production
    else
        pm2 start server.js --name "$SERVICE_NAME" --env production
    fi
    
    pm2 save
    echo -e "${GREEN}✅ 服务启动成功${NC}"
}

# 停止服务
stop_service() {
    echo -e "${BLUE}🛑 停止服务...${NC}"
    pm2 stop "$SERVICE_NAME" 2>/dev/null || pm2 stop all
    echo -e "${GREEN}✅ 服务已停止${NC}"
}

# 重启服务
restart_service() {
    echo -e "${BLUE}🔄 重启服务...${NC}"
    pm2 restart "$SERVICE_NAME" 2>/dev/null || pm2 restart all
    echo -e "${GREEN}✅ 服务重启成功${NC}"
}

# 查看状态
show_status() {
    echo -e "${BLUE}📊 服务状态:${NC}"
    pm2 status
    echo ""
    
    # 显示详细信息
    if pm2 list | grep -q "$SERVICE_NAME.*online"; then
        echo -e "${BLUE}📋 服务详情:${NC}"
        pm2 show "$SERVICE_NAME" 2>/dev/null || echo "服务详情获取失败"
    fi
}

# 查看日志
show_logs() {
    echo -e "${BLUE}📝 服务日志:${NC}"
    if [ "$1" = "--lines" ] && [ -n "$2" ]; then
        pm2 logs --lines "$2"
    else
        pm2 logs --lines 50
    fi
}

# 监控面板
show_monitor() {
    echo -e "${BLUE}📊 启动监控面板...${NC}"
    pm2 monit
}

# 健康检查
health_check() {
    echo -e "${BLUE}🏥 健康检查:${NC}"
    
    # 检查PM2进程
    if pm2 list | grep -q "$SERVICE_NAME.*online"; then
        echo -e "${GREEN}✅ PM2进程正常${NC}"
    else
        echo -e "${RED}❌ PM2进程异常${NC}"
        return 1
    fi
    
    # 检查HTTP服务
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HTTP服务正常${NC}"
    else
        echo -e "${RED}❌ HTTP服务异常${NC}"
        return 1
    fi
    
    # 检查API接口
    if curl -f -s http://localhost:3000/api/records > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API接口正常${NC}"
    else
        echo -e "${RED}❌ API接口异常${NC}"
        return 1
    fi
    
    echo -e "${GREEN}🎉 所有检查通过！${NC}"
}

# 更新服务
update_service() {
    echo -e "${BLUE}🔄 更新服务...${NC}"
    
    # 备份当前版本
    echo "备份当前版本..."
    cp -r . ../ai-storybook-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
    
    # 停止服务
    stop_service
    
    # 更新依赖
    echo "更新依赖..."
    npm install --production
    
    # 重启服务
    start_service
    
    echo -e "${GREEN}✅ 服务更新完成${NC}"
}

# 备份数据
backup_data() {
    echo -e "${BLUE}💾 备份数据...${NC}"
    
    BACKUP_DIR="backups/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 备份数据文件
    if [ -d "data" ]; then
        cp -r data "$BACKUP_DIR/"
        echo -e "${GREEN}✅ 数据文件已备份到 $BACKUP_DIR${NC}"
    fi
    
    # 备份日志
    if [ -d "logs" ]; then
        cp -r logs "$BACKUP_DIR/"
        echo -e "${GREEN}✅ 日志文件已备份到 $BACKUP_DIR${NC}"
    fi
    
    # 备份配置文件
    cp .env "$BACKUP_DIR/" 2>/dev/null || true
    cp package.json "$BACKUP_DIR/" 2>/dev/null || true
    
    echo -e "${GREEN}✅ 备份完成${NC}"
}

# 主函数
main() {
    case "$1" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2" "$3"
            ;;
        monitor)
            show_monitor
            ;;
        health)
            health_check
            ;;
        update)
            update_service
            ;;
        backup)
            backup_data
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 检查PM2是否安装
if ! command -v pm2 &> /dev/null; then
    echo -e "${RED}❌ PM2未安装，请先安装PM2${NC}"
    exit 1
fi

# 执行主函数
main "$@"
