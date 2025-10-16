#!/bin/bash

# 获取服务运行日志脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo -e "${GREEN}📋 服务日志获取工具${NC}"
    echo "=============================================="
    echo -e "${BLUE}用法:${NC}"
    echo "  $0 [选项]"
    echo ""
    echo -e "${BLUE}选项:${NC}"
    echo "  -h, --help          显示帮助信息"
    echo "  -a, --all           显示所有日志"
    echo "  -e, --error         只显示错误日志"
    echo "  -w, --warn          显示警告和错误日志"
    echo "  -i, --info          显示信息、警告和错误日志"
    echo "  -f, --follow        实时跟踪日志"
    echo "  -n, --lines N       显示最后N行日志"
    echo "  -t, --tail N        显示最后N行日志（默认100行）"
    echo "  -s, --since TIME    显示指定时间之后的日志"
    echo "  -u, --until TIME    显示指定时间之前的日志"
    echo "  -g, --grep PATTERN  过滤包含指定模式的日志"
    echo "  -o, --output FILE   将日志输出到文件"
    echo "  --pm2               显示PM2进程日志"
    echo "  --nginx             显示Nginx日志"
    echo "  --system            显示系统日志"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo "  $0 -f                    # 实时跟踪日志"
    echo "  $0 -n 50                 # 显示最后50行"
    echo "  $0 -e -g 'error'         # 显示包含'error'的错误日志"
    echo "  $0 -s '2024-01-01'       # 显示2024年1月1日之后的日志"
    echo "  $0 --pm2 -f              # 实时跟踪PM2日志"
    echo "  $0 -o logs.txt           # 将日志保存到文件"
    echo ""
}

# 默认参数
LINES=100
FOLLOW=false
LEVEL="all"
GREP_PATTERN=""
SINCE=""
UNTIL=""
OUTPUT_FILE=""
LOG_SOURCE="app"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -a|--all)
            LEVEL="all"
            shift
            ;;
        -e|--error)
            LEVEL="error"
            shift
            ;;
        -w|--warn)
            LEVEL="warn"
            shift
            ;;
        -i|--info)
            LEVEL="info"
            shift
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        -t|--tail)
            LINES="$2"
            shift 2
            ;;
        -s|--since)
            SINCE="$2"
            shift 2
            ;;
        -u|--until)
            UNTIL="$2"
            shift 2
            ;;
        -g|--grep)
            GREP_PATTERN="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --pm2)
            LOG_SOURCE="pm2"
            shift
            ;;
        --nginx)
            LOG_SOURCE="nginx"
            shift
            ;;
        --system)
            LOG_SOURCE="system"
            shift
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查PM2是否运行
check_pm2() {
    if ! command -v pm2 &> /dev/null; then
        echo -e "${RED}❌ PM2未安装${NC}"
        return 1
    fi
    
    if ! pm2 list | grep -q "ai-storybook"; then
        echo -e "${YELLOW}⚠️  PM2进程'ai-storybook'未运行${NC}"
        return 1
    fi
    
    return 0
}

# 获取PM2日志
get_pm2_logs() {
    echo -e "${BLUE}📊 获取PM2日志...${NC}"
    
    if ! check_pm2; then
        return 1
    fi
    
    local cmd="pm2 logs ai-storybook"
    
    if [[ "$FOLLOW" == true ]]; then
        cmd="$cmd --follow"
    else
        cmd="$cmd --lines $LINES"
    fi
    
    if [[ -n "$GREP_PATTERN" ]]; then
        cmd="$cmd | grep '$GREP_PATTERN'"
    fi
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        cmd="$cmd > $OUTPUT_FILE"
        echo -e "${GREEN}📁 日志已保存到: $OUTPUT_FILE${NC}"
    fi
    
    eval $cmd
}

# 获取Nginx日志
get_nginx_logs() {
    echo -e "${BLUE}🌐 获取Nginx日志...${NC}"
    
    local nginx_log_path="/var/log/nginx"
    local access_log="$nginx_log_path/access.log"
    local error_log="$nginx_log_path/error.log"
    
    if [[ ! -f "$access_log" && ! -f "$error_log" ]]; then
        echo -e "${YELLOW}⚠️  Nginx日志文件未找到${NC}"
        return 1
    fi
    
    local cmd=""
    
    if [[ "$FOLLOW" == true ]]; then
        if [[ -f "$error_log" ]]; then
            cmd="tail -f $error_log"
        else
            cmd="tail -f $access_log"
        fi
    else
        if [[ -f "$error_log" ]]; then
            cmd="tail -n $LINES $error_log"
        else
            cmd="tail -n $LINES $access_log"
        fi
    fi
    
    if [[ -n "$GREP_PATTERN" ]]; then
        cmd="$cmd | grep '$GREP_PATTERN'"
    fi
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        cmd="$cmd > $OUTPUT_FILE"
        echo -e "${GREEN}📁 日志已保存到: $OUTPUT_FILE${NC}"
    fi
    
    eval $cmd
}

# 获取系统日志
get_system_logs() {
    echo -e "${BLUE}🖥️  获取系统日志...${NC}"
    
    local cmd="journalctl"
    
    # 添加时间过滤
    if [[ -n "$SINCE" ]]; then
        cmd="$cmd --since '$SINCE'"
    fi
    
    if [[ -n "$UNTIL" ]]; then
        cmd="$cmd --until '$UNTIL'"
    fi
    
    # 添加日志级别过滤
    case $LEVEL in
        "error")
            cmd="$cmd --priority=err"
            ;;
        "warn")
            cmd="$cmd --priority=warning"
            ;;
        "info")
            cmd="$cmd --priority=info"
            ;;
    esac
    
    # 添加行数限制
    if [[ "$FOLLOW" == true ]]; then
        cmd="$cmd --follow"
    else
        cmd="$cmd --lines $LINES"
    fi
    
    # 过滤应用相关日志
    cmd="$cmd | grep -i 'ai-storybook\\|node\\|pm2\\|nginx'"
    
    if [[ -n "$GREP_PATTERN" ]]; then
        cmd="$cmd | grep '$GREP_PATTERN'"
    fi
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        cmd="$cmd > $OUTPUT_FILE"
        echo -e "${GREEN}📁 日志已保存到: $OUTPUT_FILE${NC}"
    fi
    
    eval $cmd
}

# 获取应用日志
get_app_logs() {
    echo -e "${BLUE}📱 获取应用日志...${NC}"
    
    # 检查日志文件
    local log_files=(
        "./logs/app.log"
        "./logs/error.log"
        "./logs/combined.log"
        "./pm2-logs/ai-storybook-out.log"
        "./pm2-logs/ai-storybook-error.log"
    )
    
    local found_logs=()
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            found_logs+=("$log_file")
        fi
    done
    
    if [[ ${#found_logs[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  未找到应用日志文件，尝试获取PM2日志...${NC}"
        get_pm2_logs
        return $?
    fi
    
    echo -e "${GREEN}📁 找到日志文件:${NC}"
    for log_file in "${found_logs[@]}"; do
        echo -e "  - $log_file"
    done
    echo ""
    
    # 构建命令
    local cmd=""
    if [[ ${#found_logs[@]} -eq 1 ]]; then
        cmd="tail"
    else
        cmd="tail"
    fi
    
    if [[ "$FOLLOW" == true ]]; then
        cmd="$cmd -f"
    else
        cmd="$cmd -n $LINES"
    fi
    
    # 添加文件
    for log_file in "${found_logs[@]}"; do
        cmd="$cmd $log_file"
    done
    
    if [[ -n "$GREP_PATTERN" ]]; then
        cmd="$cmd | grep '$GREP_PATTERN'"
    fi
    
    if [[ -n "$OUTPUT_FILE" ]]; then
        cmd="$cmd > $OUTPUT_FILE"
        echo -e "${GREEN}📁 日志已保存到: $OUTPUT_FILE${NC}"
    fi
    
    eval $cmd
}

# 显示服务状态
show_status() {
    echo -e "${PURPLE}📊 服务状态概览${NC}"
    echo "=============================================="
    
    # PM2状态
    if command -v pm2 &> /dev/null; then
        echo -e "${BLUE}🔄 PM2进程状态:${NC}"
        pm2 list | grep -E "(ai-storybook|Name)" || echo "  无相关进程"
        echo ""
    fi
    
    # 端口占用
    echo -e "${BLUE}🌐 端口占用情况:${NC}"
    netstat -tlnp 2>/dev/null | grep -E ":3000|:3443" || echo "  端口3000/3443未被占用"
    echo ""
    
    # 磁盘使用
    echo -e "${BLUE}💾 磁盘使用情况:${NC}"
    df -h . | tail -1
    echo ""
    
    # 内存使用
    echo -e "${BLUE}🧠 内存使用情况:${NC}"
    free -h | grep -E "Mem|Swap"
    echo ""
}

# 主函数
main() {
    echo -e "${GREEN}📋 服务日志获取工具${NC}"
    echo "=============================================="
    
    # 显示参数信息
    echo -e "${CYAN}📝 参数信息:${NC}"
    echo "  日志源: $LOG_SOURCE"
    echo "  日志级别: $LEVEL"
    echo "  行数: $LINES"
    echo "  实时跟踪: $FOLLOW"
    [[ -n "$GREP_PATTERN" ]] && echo "  过滤模式: $GREP_PATTERN"
    [[ -n "$SINCE" ]] && echo "  开始时间: $SINCE"
    [[ -n "$UNTIL" ]] && echo "  结束时间: $UNTIL"
    [[ -n "$OUTPUT_FILE" ]] && echo "  输出文件: $OUTPUT_FILE"
    echo ""
    
    # 显示服务状态
    show_status
    
    # 根据日志源获取日志
    case $LOG_SOURCE in
        "pm2")
            get_pm2_logs
            ;;
        "nginx")
            get_nginx_logs
            ;;
        "system")
            get_system_logs
            ;;
        "app")
            get_app_logs
            ;;
        *)
            echo -e "${RED}❌ 未知的日志源: $LOG_SOURCE${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✅ 日志获取完成${NC}"
}

# 运行主函数
main "$@"
