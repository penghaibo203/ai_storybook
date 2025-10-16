#!/bin/bash

# 测试记录跳转功能

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 测试记录跳转功能${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

# 检查服务是否运行
echo -e "${BLUE}🔍 检查服务状态...${NC}"
if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 服务运行正常${NC}"
else
    echo -e "${RED}❌ 服务未运行，请先启动服务${NC}"
    exit 1
fi

# 测试API接口
echo -e "${BLUE}🔍 测试API接口...${NC}"

# 测试获取记录列表
echo -e "${YELLOW}📋 测试获取记录列表...${NC}"
records_response=$(curl -s http://localhost:3000/api/records)
echo "记录列表响应: $records_response"

# 检查是否有记录
if echo "$records_response" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ 记录列表API正常${NC}"
    
    # 尝试获取第一个记录的ID
    first_record_id=$(echo "$records_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$first_record_id" ]; then
        echo -e "${YELLOW}📖 测试获取单个记录: $first_record_id${NC}"
        
        # 测试获取单个记录
        record_response=$(curl -s "http://localhost:3000/api/records/$first_record_id")
        echo "单个记录响应: $record_response"
        
        if echo "$record_response" | grep -q '"success":true'; then
            echo -e "${GREEN}✅ 单个记录API正常${NC}"
            
            # 检查记录数据结构
            echo -e "${YELLOW}📋 检查记录数据结构...${NC}"
            if echo "$record_response" | grep -q '"title"'; then
                echo -e "${GREEN}✅ 记录包含title字段${NC}"
            else
                echo -e "${RED}❌ 记录缺少title字段${NC}"
            fi
            
            if echo "$record_response" | grep -q '"input"'; then
                echo -e "${GREEN}✅ 记录包含input字段${NC}"
            else
                echo -e "${RED}❌ 记录缺少input字段${NC}"
            fi
            
            if echo "$record_response" | grep -q '"story"'; then
                echo -e "${GREEN}✅ 记录包含story字段${NC}"
            else
                echo -e "${RED}❌ 记录缺少story字段${NC}"
            fi
            
            if echo "$record_response" | grep -q '"images"'; then
                echo -e "${GREEN}✅ 记录包含images字段${NC}"
            else
                echo -e "${RED}❌ 记录缺少images字段${NC}"
            fi
            
        else
            echo -e "${RED}❌ 单个记录API异常${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  没有找到记录ID${NC}"
    fi
else
    echo -e "${RED}❌ 记录列表API异常${NC}"
fi

# 测试页面访问
echo -e "${BLUE}🔍 测试页面访问...${NC}"

# 测试记录页面
echo -e "${YELLOW}📄 测试记录页面...${NC}"
if curl -f -s http://localhost:3000/records.html > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 记录页面可访问${NC}"
else
    echo -e "${RED}❌ 记录页面无法访问${NC}"
fi

# 测试主页面
echo -e "${YELLOW}🏠 测试主页面...${NC}"
if curl -f -s http://localhost:3000/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 主页面可访问${NC}"
else
    echo -e "${RED}❌ 主页面无法访问${NC}"
fi

# 测试带参数的URL
if [ -n "$first_record_id" ]; then
    echo -e "${YELLOW}🔗 测试带参数的URL...${NC}"
    if curl -f -s "http://localhost:3000/?record=$first_record_id" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 带参数的URL可访问${NC}"
    else
        echo -e "${RED}❌ 带参数的URL无法访问${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 测试完成！${NC}"
echo "=============================================="
echo -e "${BLUE}📋 测试结果总结:${NC}"
echo "  - 服务状态: 正常"
echo "  - API接口: 已测试"
echo "  - 页面访问: 已测试"
echo "  - 数据结构: 已检查"
echo ""
echo -e "${BLUE}🔧 如果跳转仍有问题，请检查:${NC}"
echo "  1. 浏览器控制台是否有错误信息"
echo "  2. 网络请求是否成功"
echo "  3. 记录数据是否完整"
echo "  4. JavaScript是否正确执行"
echo ""
echo -e "${BLUE}🌐 手动测试步骤:${NC}"
echo "  1. 访问 http://localhost:3000/records.html"
echo "  2. 点击任意记录的'查看绘本'按钮"
echo "  3. 检查是否跳转到主页面并显示绘本内容"
echo "  4. 查看浏览器控制台的调试信息"
echo ""
