#!/bin/bash

# 服务监控和调试脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 显示帮助
show_help() {
    echo -e "${GREEN}🔍 服务监控和调试工具${NC}"
    echo "=============================================="
    echo -e "${BLUE}用法:${NC}"
    echo "  $0 [命令]"
    echo ""
    echo -e "${BLUE}命令:${NC}"
    echo "  status          显示服务状态"
    echo "  logs            显示实时日志"
    echo "  errors          显示错误日志"
    echo "  restart         重启服务"
    echo "  health          健康检查"
    echo "  performance     性能监控"
    echo "  debug           调试信息"
    echo "  clean           清理日志"
    echo "  backup          备份日志"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo "  $0 status        # 显示服务状态"
    echo "  $0 logs          # 实时日志"
    echo "  $0 errors        # 错误日志"
    echo "  $0 restart       # 重启服务"
    echo ""
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态${NC}"
    echo "=============================================="
    
    # PM2状态
    if command -v pm2 &> /dev/null; then
        echo -e "${CYAN}🔄 PM2进程:${NC}"
        pm2 list | grep -E "(ai-storybook|Name)" || echo "  无相关进程"
        echo ""
        
        # 进程详细信息
        if pm2 list | grep -q "ai-storybook"; then
            echo -e "${CYAN}📋 进程详情:${NC}"
            pm2 show ai-storybook | grep -E "(status|uptime|cpu|memory|restarts)" || true
            echo ""
        fi
    else
        echo -e "${YELLOW}⚠️  PM2未安装${NC}"
    fi
    
    # 端口占用
    echo -e "${CYAN}🌐 端口占用:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ":3000|:3443" || echo "  端口3000/3443未被占用"
    echo ""
    
    # 系统资源
    echo -e "${CYAN}💾 系统资源:${NC}"
    echo "  内存使用: $(free -h | grep Mem | awk '{print $3"/"$2}')"
    echo "  磁盘使用: $(df -h . | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
    echo "  负载: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
}

# 显示实时日志
show_logs() {
    echo -e "${BLUE}📋 实时日志${NC}"
    echo "=============================================="
    echo -e "${YELLOW}按 Ctrl+C 退出日志查看${NC}"
    echo ""
    
    if command -v pm2 &> /dev/null && pm2 list | grep -q "ai-storybook"; then
        pm2 logs ai-storybook --follow
    else
        echo -e "${YELLOW}⚠️  PM2进程未运行，尝试查找日志文件...${NC}"
        local log_files=(
            "./logs/app.log"
            "./logs/error.log"
            "./pm2-logs/ai-storybook-out.log"
            "./pm2-logs/ai-storybook-error.log"
        )
        
        for log_file in "${log_files[@]}"; do
            if [[ -f "$log_file" ]]; then
                echo -e "${GREEN}📁 跟踪日志文件: $log_file${NC}"
                tail -f "$log_file"
                return
            fi
        done
        
        echo -e "${RED}❌ 未找到日志文件${NC}"
    fi
}

# 显示错误日志
show_errors() {
    echo -e "${BLUE}❌ 错误日志${NC}"
    echo "=============================================="
    
    if command -v pm2 &> /dev/null && pm2 list | grep -q "ai-storybook"; then
        echo -e "${CYAN}PM2错误日志:${NC}"
        pm2 logs ai-storybook --err --lines 50 | grep -i "error\|exception\|failed\|warn" || echo "  无错误日志"
        echo ""
    fi
    
    # 查找错误日志文件
    local error_logs=(
        "./logs/error.log"
        "./pm2-logs/ai-storybook-error.log"
    )
    
    for log_file in "${error_logs[@]}"; do
        if [[ -f "$log_file" ]]; then
            echo -e "${CYAN}错误日志文件: $log_file${NC}"
            tail -n 50 "$log_file" | grep -i "error\|exception\|failed\|warn" || echo "  无错误日志"
            echo ""
        fi
    done
}

# 重启服务
restart_service() {
    echo -e "${BLUE}🔄 重启服务${NC}"
    echo "=============================================="
    
    if command -v pm2 &> /dev/null; then
        if pm2 list | grep -q "ai-storybook"; then
            echo -e "${YELLOW}正在重启PM2进程...${NC}"
            pm2 restart ai-storybook
            pm2 save
            echo -e "${GREEN}✅ 服务重启完成${NC}"
        else
            echo -e "${YELLOW}PM2进程未运行，尝试启动...${NC}"
            pm2 start ecosystem.config.cjs --env production
            pm2 save
            echo -e "${GREEN}✅ 服务启动完成${NC}"
        fi
    else
        echo -e "${RED}❌ PM2未安装${NC}"
    fi
}

# 健康检查
health_check() {
    echo -e "${BLUE}🏥 健康检查${NC}"
    echo "=============================================="
    
    # 检查HTTP服务
    echo -e "${CYAN}HTTP服务检查:${NC}"
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HTTP服务正常 (端口3000)${NC}"
    else
        echo -e "${RED}❌ HTTP服务异常 (端口3000)${NC}"
    fi
    
    # 检查HTTPS服务
    echo -e "${CYAN}HTTPS服务检查:${NC}"
    if curl -f -s -k https://localhost:3443/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HTTPS服务正常 (端口3443)${NC}"
    else
        echo -e "${YELLOW}⚠️  HTTPS服务异常 (端口3443)${NC}"
    fi
    
    # 检查API接口
    echo -e "${CYAN}API接口检查:${NC}"
    if curl -f -s http://localhost:3000/api/records > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API接口正常${NC}"
    else
        echo -e "${RED}❌ API接口异常${NC}"
    fi
    
    echo ""
}

# 性能监控
performance_monitor() {
    echo -e "${BLUE}⚡ 性能监控${NC}"
    echo "=============================================="
    
    # CPU使用率
    echo -e "${CYAN}CPU使用率:${NC}"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | xargs -I {} echo "  CPU: {}%"
    
    # 内存使用
    echo -e "${CYAN}内存使用:${NC}"
    free -h | grep Mem | awk '{print "  已用: " $3 " / " $2 " (" $3/$2*100 "%)"}'
    
    # 磁盘I/O
    echo -e "${CYAN}磁盘使用:${NC}"
    df -h . | tail -1 | awk '{print "  已用: " $3 " / " $2 " (" $5 ")"}'
    
    # 网络连接
    echo -e "${CYAN}网络连接:${NC}"
    netstat -an | grep -E ":3000|:3443" | wc -l | xargs -I {} echo "  活跃连接: {}"
    
    echo ""
}

# 调试信息
debug_info() {
    echo -e "${BLUE}🐛 调试信息${NC}"
    echo "=============================================="
    
    # 系统信息
    echo -e "${CYAN}系统信息:${NC}"
    echo "  操作系统: $(uname -a)"
    echo "  Node.js版本: $(node --version 2>/dev/null || echo '未安装')"
    echo "  NPM版本: $(npm --version 2>/dev/null || echo '未安装')"
    echo "  PM2版本: $(pm2 --version 2>/dev/null || echo '未安装')"
    echo ""
    
    # 环境变量
    echo -e "${CYAN}环境变量:${NC}"
    echo "  NODE_ENV: ${NODE_ENV:-'未设置'}"
    echo "  PORT: ${PORT:-'未设置'}"
    echo "  HTTPS_PORT: ${HTTPS_PORT:-'未设置'}"
    echo ""
    
    # 配置文件
    echo -e "${CYAN}配置文件:${NC}"
    [[ -f "package.json" ]] && echo "  ✅ package.json" || echo "  ❌ package.json"
    [[ -f "ecosystem.config.cjs" ]] && echo "  ✅ ecosystem.config.cjs" || echo "  ❌ ecosystem.config.cjs"
    [[ -f ".env" ]] && echo "  ✅ .env" || echo "  ❌ .env"
    [[ -f "ssl/hypersmart.work_bundle.crt" ]] && echo "  ✅ SSL证书" || echo "  ❌ SSL证书"
    echo ""
    
    # 日志文件
    echo -e "${CYAN}日志文件:${NC}"
    local log_files=(
        "./logs/app.log"
        "./logs/error.log"
        "./pm2-logs/ai-storybook-out.log"
        "./pm2-logs/ai-storybook-error.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            local size=$(du -h "$log_file" | cut -f1)
            echo "  ✅ $log_file ($size)"
        else
            echo "  ❌ $log_file"
        fi
    done
    echo ""
}

# 清理日志
clean_logs() {
    echo -e "${BLUE}🧹 清理日志${NC}"
    echo "=============================================="
    
    # 清理PM2日志
    if command -v pm2 &> /dev/null; then
        echo -e "${YELLOW}清理PM2日志...${NC}"
        pm2 flush
        echo -e "${GREEN}✅ PM2日志已清理${NC}"
    fi
    
    # 清理应用日志
    local log_files=(
        "./logs/app.log"
        "./logs/error.log"
        "./pm2-logs/ai-storybook-out.log"
        "./pm2-logs/ai-storybook-error.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            echo -e "${YELLOW}清理日志文件: $log_file${NC}"
            > "$log_file"
            echo -e "${GREEN}✅ 已清理${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ 日志清理完成${NC}"
}

# 备份日志
backup_logs() {
    echo -e "${BLUE}💾 备份日志${NC}"
    echo "=============================================="
    
    local backup_dir="./logs/backup/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    echo -e "${YELLOW}创建备份目录: $backup_dir${NC}"
    
    # 备份PM2日志
    if command -v pm2 &> /dev/null; then
        pm2 logs ai-storybook --lines 1000 > "$backup_dir/pm2_logs.txt" 2>/dev/null || true
        echo -e "${GREEN}✅ PM2日志已备份${NC}"
    fi
    
    # 备份应用日志
    local log_files=(
        "./logs/app.log"
        "./logs/error.log"
        "./pm2-logs/ai-storybook-out.log"
        "./pm2-logs/ai-storybook-error.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            cp "$log_file" "$backup_dir/"
            echo -e "${GREEN}✅ 已备份: $(basename "$log_file")${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ 日志备份完成: $backup_dir${NC}"
}

# 主函数
main() {
    case "${1:-status}" in
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "errors")
            show_errors
            ;;
        "restart")
            restart_service
            ;;
        "health")
            health_check
            ;;
        "performance")
            performance_monitor
            ;;
        "debug")
            debug_info
            ;;
        "clean")
            clean_logs
            ;;
        "backup")
            backup_logs
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ 未知命令: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
