#!/bin/bash

# 修复root权限问题的脚本
# 用于解决HTTPS部署时的权限问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复root权限问题${NC}"
echo "=============================================="

# 检查当前用户
CURRENT_USER=$(whoami)
echo -e "${BLUE}当前用户: $CURRENT_USER${NC}"

if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  检测到以root权限运行${NC}"
    echo ""
    echo -e "${BLUE}解决方案:${NC}"
    echo "1. 退出root用户，使用普通用户运行部署脚本"
    echo "2. 或者使用简化部署脚本（需要预先准备SSL证书）"
    echo ""
    echo -e "${BLUE}推荐操作:${NC}"
    echo "1. 退出root: exit"
    echo "2. 切换到普通用户: su - your_username"
    echo "3. 运行部署: ./scripts/deploy-https.sh"
    echo ""
    echo -e "${BLUE}或者使用简化部署:${NC}"
    echo "1. 确保SSL证书存在: ssl/hypersmart.work_bundle.crt, ssl/hypersmart.work.key"
    echo "2. 运行: ./scripts/deploy-https-simple.sh"
    echo ""
    
    read -p "是否继续使用简化部署? (y/n): " use_simple
    if [[ $use_simple =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🔧 使用简化部署...${NC}"
        ./scripts/deploy-https-simple.sh
    else
        echo -e "${RED}❌ 请使用普通用户权限运行部署脚本${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 当前以普通用户权限运行${NC}"
    echo "可以正常使用部署脚本"
    echo ""
    echo -e "${BLUE}可用命令:${NC}"
    echo "  ./scripts/deploy-https.sh          # 完整HTTPS部署"
    echo "  ./scripts/generate-ssl.sh          # 生成SSL证书"
    echo "  ./scripts/deploy-https-simple.sh   # 简化HTTPS部署"
fi

echo -e "${GREEN}🎊 权限检查完成！${NC}"
