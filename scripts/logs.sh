#!/bin/bash

# 简化的日志查看脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助
show_help() {
    echo -e "${GREEN}📋 日志查看工具${NC}"
    echo "=============================================="
    echo -e "${BLUE}用法:${NC}"
    echo "  $0 [选项]"
    echo ""
    echo -e "${BLUE}选项:${NC}"
    echo "  -h, --help      显示帮助"
    echo "  -f, --follow    实时跟踪日志"
    echo "  -n N            显示最后N行（默认50行）"
    echo "  -e, --error     只显示错误日志"
    echo "  -g PATTERN      过滤包含指定内容的日志"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo "  $0              # 显示最后50行日志"
    echo "  $0 -f           # 实时跟踪日志"
    echo "  $0 -n 100       # 显示最后100行"
    echo "  $0 -e           # 只显示错误日志"
    echo "  $0 -g 'error'   # 过滤包含'error'的日志"
    echo ""
}

# 默认参数
LINES=50
FOLLOW=false
ERROR_ONLY=false
GREP_PATTERN=""

# 解析参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n)
            LINES="$2"
            shift 2
            ;;
        -e|--error)
            ERROR_ONLY=true
            shift
            ;;
        -g)
            GREP_PATTERN="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}❌ 未知参数: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查PM2状态
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

# 获取日志
get_logs() {
    echo -e "${BLUE}📊 获取服务日志...${NC}"
    
    if ! check_pm2; then
        echo -e "${YELLOW}⚠️  尝试查找其他日志文件...${NC}"
        
        # 查找可能的日志文件
        local log_files=(
            "./logs/app.log"
            "./logs/error.log"
            "./logs/combined.log"
            "./pm2-logs/ai-storybook-out.log"
            "./pm2-logs/ai-storybook-error.log"
        )
        
        local found_log=""
        for log_file in "${log_files[@]}"; do
            if [[ -f "$log_file" ]]; then
                found_log="$log_file"
                break
            fi
        done
        
        if [[ -z "$found_log" ]]; then
            echo -e "${RED}❌ 未找到任何日志文件${NC}"
            return 1
        fi
        
        echo -e "${GREEN}📁 找到日志文件: $found_log${NC}"
        
        local cmd="tail"
        if [[ "$FOLLOW" == true ]]; then
            cmd="$cmd -f"
        else
            cmd="$cmd -n $LINES"
        fi
        
        cmd="$cmd $found_log"
        
        if [[ "$ERROR_ONLY" == true ]]; then
            cmd="$cmd | grep -i 'error\\|exception\\|failed'"
        fi
        
        if [[ -n "$GREP_PATTERN" ]]; then
            cmd="$cmd | grep '$GREP_PATTERN'"
        fi
        
        eval $cmd
        return $?
    fi
    
    # 使用PM2获取日志
    local cmd="pm2 logs ai-storybook"
    
    if [[ "$FOLLOW" == true ]]; then
        cmd="$cmd --follow"
    else
        cmd="$cmd --lines $LINES"
    fi
    
    if [[ "$ERROR_ONLY" == true ]]; then
        cmd="$cmd | grep -i 'error\\|exception\\|failed'"
    fi
    
    if [[ -n "$GREP_PATTERN" ]]; then
        cmd="$cmd | grep '$GREP_PATTERN'"
    fi
    
    eval $cmd
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}📊 服务状态:${NC}"
    
    if command -v pm2 &> /dev/null; then
        pm2 list | grep -E "(ai-storybook|Name)" || echo "  无相关进程"
    else
        echo "  PM2未安装"
    fi
    
    echo ""
}

# 主函数
main() {
    echo -e "${GREEN}📋 日志查看工具${NC}"
    echo "=============================================="
    
    show_status
    
    get_logs
    
    echo ""
    echo -e "${GREEN}✅ 完成${NC}"
}

# 运行主函数
main "$@"
