#!/bin/bash

# 测试API接口脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 测试API接口${NC}"
echo "=============================================="

# 测试本地API
echo -e "${BLUE}1. 测试本地健康检查${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地健康检查正常${NC}"
    curl -s http://localhost:3000/health | jq . 2>/dev/null || curl -s http://localhost:3000/health
else
    echo -e "${RED}❌ 本地健康检查失败${NC}"
fi

echo ""
echo -e "${BLUE}2. 测试本地记录API${NC}"
if curl -f -s http://localhost:3000/api/records > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地记录API正常${NC}"
    curl -s http://localhost:3000/api/records | jq . 2>/dev/null || curl -s http://localhost:3000/api/records
else
    echo -e "${RED}❌ 本地记录API失败${NC}"
fi

echo ""
echo -e "${BLUE}3. 测试本地生成故事API${NC}"
echo "发送测试请求..."
response=$(curl -s -X POST http://localhost:3000/api/generate-story \
  -H "Content-Type: application/json" \
  -d '{"input":"测试故事"}' \
  -w "HTTP_CODE:%{http_code}")

http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
response_body=$(echo "$response" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ 本地生成故事API正常${NC}"
    echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
elif [ "$http_code" = "502" ]; then
    echo -e "${RED}❌ 本地生成故事API返回502错误${NC}"
    echo "响应内容: $response_body"
else
    echo -e "${YELLOW}⚠️  本地生成故事API返回HTTP $http_code${NC}"
    echo "响应内容: $response_body"
fi

echo ""
echo -e "${BLUE}4. 测试生产环境健康检查${NC}"
if curl -f -s https://hypersmart.work/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 生产环境健康检查正常${NC}"
    curl -s https://hypersmart.work/health | jq . 2>/dev/null || curl -s https://hypersmart.work/health
else
    echo -e "${RED}❌ 生产环境健康检查失败${NC}"
fi

echo ""
echo -e "${BLUE}5. 测试生产环境记录API${NC}"
if curl -f -s https://hypersmart.work/api/records > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 生产环境记录API正常${NC}"
    curl -s https://hypersmart.work/api/records | jq . 2>/dev/null || curl -s https://hypersmart.work/api/records
else
    echo -e "${RED}❌ 生产环境记录API失败${NC}"
fi

echo ""
echo -e "${BLUE}6. 测试生产环境生成故事API${NC}"
echo "发送测试请求..."
response=$(curl -s -X POST https://hypersmart.work/api/generate-story \
  -H "Content-Type: application/json" \
  -d '{"input":"测试故事"}' \
  -w "HTTP_CODE:%{http_code}")

http_code=$(echo "$response" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
response_body=$(echo "$response" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$http_code" = "200" ]; then
    echo -e "${GREEN}✅ 生产环境生成故事API正常${NC}"
    echo "$response_body" | jq . 2>/dev/null || echo "$response_body"
elif [ "$http_code" = "502" ]; then
    echo -e "${RED}❌ 生产环境生成故事API返回502错误${NC}"
    echo "响应内容: $response_body"
else
    echo -e "${YELLOW}⚠️  生产环境生成故事API返回HTTP $http_code${NC}"
    echo "响应内容: $response_body"
fi

echo ""
echo -e "${GREEN}🎯 测试完成${NC}"
echo "=============================================="
