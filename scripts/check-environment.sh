#!/bin/bash

# 环境检查脚本
# 检查部署环境是否满足要求

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 AI英文绘本应用 - 环境检查脚本${NC}"
echo "=============================================="

# 检查结果
CHECKS_PASSED=0
CHECKS_TOTAL=0

# 检查函数
check_item() {
    local name="$1"
    local command="$2"
    local required="$3"
    
    ((CHECKS_TOTAL++))
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $name${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}❌ $name (必需)${NC}"
        else
            echo -e "${YELLOW}⚠️  $name (可选)${NC}"
        fi
        return 1
    fi
}

# 检查版本函数
check_version() {
    local name="$1"
    local command="$2"
    local min_version="$3"
    local required="$4"
    
    ((CHECKS_TOTAL++))
    
    if eval "$command" >/dev/null 2>&1; then
        local version=$(eval "$command" 2>/dev/null | head -1)
        echo -e "${GREEN}✅ $name: $version${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}❌ $name (必需)${NC}"
        else
            echo -e "${YELLOW}⚠️  $name (可选)${NC}"
        fi
        return 1
    fi
}

echo -e "${BLUE}📋 基础环境检查${NC}"
echo "----------------------------------------"

# 检查操作系统
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${GREEN}✅ 操作系统: Linux${NC}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}✅ 操作系统: macOS${NC}"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo -e "${GREEN}✅ 操作系统: Windows${NC}"
else
    echo -e "${YELLOW}⚠️  操作系统: $OSTYPE${NC}"
fi

# 检查必需工具
check_item "Node.js" "node --version" "true"
check_item "npm" "npm --version" "true"
check_item "Git" "git --version" "true"

# 检查Node.js版本
NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//' | cut -d. -f1)
if [ -n "$NODE_VERSION" ] && [ "$NODE_VERSION" -ge 18 ]; then
    echo -e "${GREEN}✅ Node.js版本: $(node --version) (>= 18.0.0)${NC}"
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
else
    echo -e "${RED}❌ Node.js版本: $(node --version) (需要 >= 18.0.0)${NC}"
    ((CHECKS_TOTAL++))
fi

# 检查可选工具
echo ""
echo -e "${BLUE}📋 可选工具检查${NC}"
echo "----------------------------------------"

check_item "Docker" "docker --version" "false"
check_item "Docker Compose" "docker-compose --version" "false"
check_item "PM2" "pm2 --version" "false"
check_item "Nginx" "nginx -v" "false"
check_item "Certbot" "certbot --version" "false"

# 检查端口占用
echo ""
echo -e "${BLUE}📋 端口检查${NC}"
echo "----------------------------------------"

check_item "端口3000可用" "! lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null" "false"
check_item "端口80可用" "! lsof -Pi :80 -sTCP:LISTEN -t >/dev/null" "false"
check_item "端口443可用" "! lsof -Pi :443 -sTCP:LISTEN -t >/dev/null" "false"

# 检查网络连接
echo ""
echo -e "${BLUE}📋 网络连接检查${NC}"
echo "----------------------------------------"

check_item "Coze API连接" "curl -s --connect-timeout 5 https://api.coze.cn >/dev/null" "false"
check_item "GitHub连接" "curl -s --connect-timeout 5 https://github.com >/dev/null" "false"
check_item "NPM注册表连接" "curl -s --connect-timeout 5 https://registry.npmjs.org >/dev/null" "false"

# 检查项目文件
echo ""
echo -e "${BLUE}📋 项目文件检查${NC}"
echo "----------------------------------------"

check_item "package.json" "[ -f package.json ]" "true"
check_item "server.js" "[ -f server.js ]" "true"
check_item "api.js" "[ -f api.js ]" "true"
check_item "index.html" "[ -f index.html ]" "true"

# 检查环境变量
echo ""
echo -e "${BLUE}📋 环境变量检查${NC}"
echo "----------------------------------------"

if [ -n "$COZE_API_TOKEN" ]; then
    echo -e "${GREEN}✅ COZE_API_TOKEN 已设置${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠️  COZE_API_TOKEN 未设置${NC}"
fi
((CHECKS_TOTAL++))

if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env 文件存在${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠️  .env 文件不存在${NC}"
fi
((CHECKS_TOTAL++))

# 检查磁盘空间
echo ""
echo -e "${BLUE}📋 系统资源检查${NC}"
echo "----------------------------------------"

DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 90 ]; then
    echo -e "${GREEN}✅ 磁盘使用率: ${DISK_USAGE}%${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ 磁盘使用率: ${DISK_USAGE}% (过高)${NC}"
fi
((CHECKS_TOTAL++))

# 检查内存
if command -v free &> /dev/null; then
    MEMORY_GB=$(free -g | awk 'NR==2{print $2}')
    if [ "$MEMORY_GB" -ge 1 ]; then
        echo -e "${GREEN}✅ 可用内存: ${MEMORY_GB}GB${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  可用内存: ${MEMORY_GB}GB (建议 >= 1GB)${NC}"
        ((CHECKS_PASSED++))
    fi
    ((CHECKS_TOTAL++))
fi

# 显示检查结果
echo ""
echo -e "${BLUE}📊 检查结果${NC}"
echo "=============================================="

if [ $CHECKS_PASSED -eq $CHECKS_TOTAL ]; then
    echo -e "${GREEN}🎉 所有检查通过！环境完全满足要求。${NC}"
    exit 0
elif [ $CHECKS_PASSED -ge $((CHECKS_TOTAL * 3 / 4)) ]; then
    echo -e "${YELLOW}⚠️  大部分检查通过 ($CHECKS_PASSED/$CHECKS_TOTAL)，可以继续部署。${NC}"
    exit 0
else
    echo -e "${RED}❌ 多项检查失败 ($CHECKS_PASSED/$CHECKS_TOTAL)，请解决以下问题：${NC}"
    echo ""
    echo -e "${YELLOW}🔧 建议解决方案：${NC}"
    
    # 提供解决方案
    if ! command -v node &> /dev/null; then
        echo "  - 安装Node.js: https://nodejs.org/"
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "  - 安装Docker: https://docs.docker.com/get-docker/"
    fi
    
    if [ -z "$COZE_API_TOKEN" ]; then
        echo "  - 设置环境变量: export COZE_API_TOKEN=your_token_here"
    fi
    
    if [ ! -f ".env" ]; then
        echo "  - 创建.env文件: cp env.example .env"
    fi
    
    exit 1
fi
