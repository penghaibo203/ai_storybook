#!/bin/bash

# 生产环境启动脚本
# 设置正确的环境变量和配置

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 启动AI英文绘本应用 - 生产环境${NC}"
echo "=============================================="

# 设置生产环境变量
export NODE_ENV=production
export PORT=3000

# 检查环境变量
if [ -z "$COZE_API_TOKEN" ]; then
    echo -e "${YELLOW}⚠️  环境变量 COZE_API_TOKEN 未设置${NC}"
    echo "请设置: export COZE_API_TOKEN=your_token_here"
    exit 1
fi

# 检查.env文件
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ 加载.env文件${NC}"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${YELLOW}⚠️  .env文件不存在，使用环境变量${NC}"
fi

# 创建必要的目录
mkdir -p public/css

# 启动应用
echo -e "${GREEN}🚀 启动应用...${NC}"
echo "环境: $NODE_ENV"
echo "端口: $PORT"
echo "域名: www.hypersmart.work"
echo ""

node server.js
