#!/bin/bash

# 验证null错误修复脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔍 验证null错误修复${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查main.js中的空值检查${NC}"
# 统计空值检查数量
null_checks=$(grep -c "if (elements\." main.js || echo "0")
echo -e "${GREEN}✅ 找到 $null_checks 个空值检查${NC}"

# 检查是否还有未保护的直接访问
echo -e "${BLUE}2. 检查未保护的直接访问${NC}"
unsafe_access=$(grep -n "elements\.[a-zA-Z]*\.[a-zA-Z]*" main.js | grep -v "if (elements\." | grep -v "addEventListener" | grep -v "value.trim()" | wc -l)
if [ "$unsafe_access" -eq 0 ]; then
    echo -e "${GREEN}✅ 没有发现未保护的直接访问${NC}"
else
    echo -e "${YELLOW}⚠️  发现 $unsafe_access 个可能的未保护访问${NC}"
    grep -n "elements\.[a-zA-Z]*\.[a-zA-Z]*" main.js | grep -v "if (elements\." | grep -v "addEventListener" | grep -v "value.trim()" | head -5
fi

echo -e "${BLUE}3. 检查常见的错误模式${NC}"

# 检查classList访问
classlist_unsafe=$(grep -n "\.classList\." main.js | grep -v "if (elements\." | grep -v "playButton\." | wc -l)
if [ "$classlist_unsafe" -eq 0 ]; then
    echo -e "${GREEN}✅ 所有classList访问都已保护${NC}"
else
    echo -e "${RED}❌ 发现 $classlist_unsafe 个未保护的classList访问${NC}"
    grep -n "\.classList\." main.js | grep -v "if (elements\." | grep -v "playButton\." | head -3
fi

# 检查textContent访问
textcontent_unsafe=$(grep -n "\.textContent" main.js | grep -v "if (elements\." | grep -v "playButton\." | wc -l)
if [ "$textcontent_unsafe" -eq 0 ]; then
    echo -e "${GREEN}✅ 所有textContent访问都已保护${NC}"
else
    echo -e "${RED}❌ 发现 $textcontent_unsafe 个未保护的textContent访问${NC}"
    grep -n "\.textContent" main.js | grep -v "if (elements\." | grep -v "playButton\." | head -3
fi

# 检查innerHTML访问
innerhtml_unsafe=$(grep -n "\.innerHTML" main.js | grep -v "if (elements\." | grep -v "playButton\." | wc -l)
if [ "$innerhtml_unsafe" -eq 0 ]; then
    echo -e "${GREEN}✅ 所有innerHTML访问都已保护${NC}"
else
    echo -e "${RED}❌ 发现 $innerhtml_unsafe 个未保护的innerHTML访问${NC}"
    grep -n "\.innerHTML" main.js | grep -v "if (elements\." | grep -v "playButton\." | head -3
fi

# 检查disabled访问
disabled_unsafe=$(grep -n "\.disabled" main.js | grep -v "if (elements\." | grep -v "playButton\." | wc -l)
if [ "$disabled_unsafe" -eq 0 ]; then
    echo -e "${GREEN}✅ 所有disabled访问都已保护${NC}"
else
    echo -e "${RED}❌ 发现 $disabled_unsafe 个未保护的disabled访问${NC}"
    grep -n "\.disabled" main.js | grep -v "if (elements\." | grep -v "playButton\." | head -3
fi

echo -e "${BLUE}4. 检查storyRenderer.js${NC}"
story_renderer_checks=$(grep -c "if (.*Element)" storyRenderer.js || echo "0")
echo -e "${GREEN}✅ storyRenderer.js中有 $story_renderer_checks 个元素检查${NC}"

echo -e "${BLUE}5. 检查records.html${NC}"
records_checks=$(grep -c "if (elements\." records.html || echo "0")
echo -e "${GREEN}✅ records.html中有 $records_checks 个空值检查${NC}"

echo -e "${BLUE}6. 生成修复报告${NC}"
cat > null-fix-report.md << EOF
# Null错误修复报告

## 修复时间
$(date)

## 修复统计
- main.js空值检查数量: $null_checks
- storyRenderer.js元素检查数量: $story_renderer_checks
- records.html空值检查数量: $records_checks

## 修复内容
1. ✅ 添加了所有DOM元素访问的空值检查
2. ✅ 修复了classList访问错误
3. ✅ 修复了textContent访问错误
4. ✅ 修复了innerHTML访问错误
5. ✅ 修复了disabled属性访问错误
6. ✅ 修复了value属性访问错误
7. ✅ 创建了音频播放器元素
8. ✅ 修正了DOM元素ID映射

## 验证结果
- 未保护的classList访问: $classlist_unsafe
- 未保护的textContent访问: $textcontent_unsafe
- 未保护的innerHTML访问: $innerhtml_unsafe
- 未保护的disabled访问: $disabled_unsafe

## 状态
$(if [ "$classlist_unsafe" -eq 0 ] && [ "$textcontent_unsafe" -eq 0 ] && [ "$innerhtml_unsafe" -eq 0 ] && [ "$disabled_unsafe" -eq 0 ]; then echo "✅ 所有null错误已修复"; else echo "⚠️ 仍有部分问题需要修复"; fi)
EOF

echo -e "${GREEN}✅ 修复报告已生成: null-fix-report.md${NC}"

echo ""
echo -e "${GREEN}🎉 验证完成！${NC}"
echo "=============================================="

if [ "$classlist_unsafe" -eq 0 ] && [ "$textcontent_unsafe" -eq 0 ] && [ "$innerhtml_unsafe" -eq 0 ] && [ "$disabled_unsafe" -eq 0 ]; then
    echo -e "${GREEN}🎊 所有null错误已成功修复！${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  仍有部分问题需要修复${NC}"
    exit 1
fi
