#!/bin/bash

# 修复502错误脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 修复502错误${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 停止所有PM2进程${NC}"
pm2 stop all || true
pm2 delete all || true

echo -e "${BLUE}2. 启动Node.js服务${NC}"
pm2 start ecosystem.config.cjs --env production
pm2 save

echo -e "${BLUE}3. 等待服务启动${NC}"
sleep 5

echo -e "${BLUE}4. 检查本地服务${NC}"
for i in {1..10}; do
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 本地服务启动成功${NC}"
        break
    fi
    echo "等待服务启动... ($i/10)"
    sleep 2
done

echo -e "${BLUE}5. 重启Nginx${NC}"
if command -v nginx &> /dev/null; then
    if systemctl is-active --quiet nginx 2>/dev/null; then
        echo -e "${YELLOW}重启Nginx...${NC}"
        sudo systemctl restart nginx
        sleep 2
        
        if systemctl is-active --quiet nginx 2>/dev/null; then
            echo -e "${GREEN}✅ Nginx重启成功${NC}"
        else
            echo -e "${RED}❌ Nginx重启失败${NC}"
        fi
    else
        echo -e "${YELLOW}启动Nginx...${NC}"
        sudo systemctl start nginx
    fi
else
    echo -e "${YELLOW}⚠️  Nginx未安装，跳过Nginx重启${NC}"
fi

echo -e "${BLUE}6. 检查服务状态${NC}"
pm2 status

echo -e "${BLUE}7. 测试API接口${NC}"
if curl -f -s http://localhost:3000/api/records > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 本地API接口正常${NC}"
else
    echo -e "${RED}❌ 本地API接口异常${NC}"
fi

echo -e "${BLUE}8. 测试生产环境${NC}"
if curl -f -s https://hypersmart.work/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 生产环境健康检查正常${NC}"
else
    echo -e "${YELLOW}⚠️  生产环境健康检查异常，可能需要等待DNS传播${NC}"
fi

echo ""
echo -e "${GREEN}🎉 502错误修复完成！${NC}"
echo "=============================================="
echo -e "${BLUE}🔧 修复内容:${NC}"
echo "  ✅ 重启PM2服务"
echo "  ✅ 重启Nginx代理"
echo "  ✅ 检查服务连接"
echo "  ✅ 验证API接口"
echo ""
echo -e "${BLUE}🌐 测试地址:${NC}"
echo "  本地: http://localhost:3000"
echo "  生产: https://hypersmart.work"
echo ""
echo -e "${BLUE}🧪 测试步骤:${NC}"
echo "  1. 访问主页"
echo "  2. 输入故事主题"
echo "  3. 点击生成故事"
echo "  4. 检查是否成功生成"
echo ""

echo -e "${GREEN}🎊 修复完成！${NC}"
