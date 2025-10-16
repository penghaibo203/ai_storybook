#!/bin/bash

# 诊断502错误脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 诊断502错误${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查PM2进程状态${NC}"
if command -v pm2 &> /dev/null; then
    pm2 list
else
    echo -e "${RED}❌ PM2未安装${NC}"
fi

echo ""
echo -e "${BLUE}2. 检查端口占用情况${NC}"
netstat -tlnp 2>/dev/null | grep -E ":3000|:3443" || echo "  端口3000/3443未被占用"

echo ""
echo -e "${BLUE}3. 检查本地服务健康状态${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地服务正常${NC}"
    curl -s http://localhost:3000/health | head -3
else
    echo -e "${RED}❌ 本地服务异常${NC}"
fi

echo ""
echo -e "${BLUE}4. 检查API接口${NC}"
if curl -f -s http://localhost:3000/api/records > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API接口正常${NC}"
else
    echo -e "${RED}❌ API接口异常${NC}"
fi

echo ""
echo -e "${BLUE}5. 检查Nginx状态${NC}"
if command -v nginx &> /dev/null; then
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "${GREEN}✅ Nginx正在运行${NC}"
    else
        echo -e "${RED}❌ Nginx未运行${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Nginx未安装${NC}"
fi

echo ""
echo -e "${BLUE}6. 检查生产环境连接${NC}"
if curl -f -s https://hypersmart.work/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 生产环境健康检查正常${NC}"
else
    echo -e "${RED}❌ 生产环境健康检查异常${NC}"
    echo "响应内容:"
    curl -s https://hypersmart.work/health | head -5
fi

echo ""
echo -e "${BLUE}7. 检查API接口响应${NC}"
echo "测试API接口:"
api_response=$(curl -s -w "HTTP_CODE:%{http_code}" https://hypersmart.work/api/records 2>/dev/null || echo "CONNECTION_FAILED")
if [[ "$api_response" == *"HTTP_CODE:200"* ]]; then
    echo -e "${GREEN}✅ API接口正常${NC}"
elif [[ "$api_response" == *"HTTP_CODE:502"* ]]; then
    echo -e "${RED}❌ API接口返回502错误${NC}"
    echo "响应内容:"
    echo "$api_response" | sed 's/HTTP_CODE:[0-9]*$//' | head -5
elif [[ "$api_response" == "CONNECTION_FAILED" ]]; then
    echo -e "${RED}❌ 连接失败${NC}"
else
    echo -e "${YELLOW}⚠️  API接口异常${NC}"
    echo "响应内容:"
    echo "$api_response" | head -5
fi

echo ""
echo -e "${BLUE}8. 检查系统资源${NC}"
echo "内存使用: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "磁盘使用: $(df -h . | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
echo "负载: $(uptime | awk -F'load average:' '{print $2}')"

echo ""
echo -e "${GREEN}🎯 诊断完成${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 可能的解决方案:${NC}"
echo "  1. 重启PM2服务: pm2 restart all"
echo "  2. 重启Nginx: sudo systemctl restart nginx"
echo "  3. 检查防火墙设置"
echo "  4. 检查SSL证书是否过期"
echo "  5. 检查Nginx配置是否正确"
echo ""
