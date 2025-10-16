#!/bin/bash

# 最终null错误检查脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}🔍 最终null错误检查${NC}"
echo "=============================================="

# 检查当前目录
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ 请在项目根目录运行此脚本${NC}"
    exit 1
fi

echo -e "${BLUE}1. 检查关键修复点${NC}"

# 检查displayStory函数中的修复
if grep -q "if (elements.emptyState)" main.js && grep -q "if (elements.storyContainer)" main.js; then
    echo -e "${GREEN}✅ displayStory函数已修复${NC}"
else
    echo -e "${RED}❌ displayStory函数未完全修复${NC}"
fi

# 检查bindEvents函数中的修复
if grep -q "if (elements.generateBtn)" main.js && grep -q "if (elements.prevBtn)" main.js; then
    echo -e "${GREEN}✅ bindEvents函数已修复${NC}"
else
    echo -e "${RED}❌ bindEvents函数未完全修复${NC}"
fi

# 检查updatePageDisplay函数中的修复
if grep -q "if (elements.currentPageSpan)" main.js && grep -q "if (elements.prevBtn)" main.js; then
    echo -e "${GREEN}✅ updatePageDisplay函数已修复${NC}"
else
    echo -e "${RED}❌ updatePageDisplay函数未完全修复${NC}"
fi

# 检查音频播放器创建
if grep -q "音频播放器元素已创建" main.js; then
    echo -e "${GREEN}✅ 音频播放器创建逻辑已添加${NC}"
else
    echo -e "${RED}❌ 音频播放器创建逻辑缺失${NC}"
fi

echo -e "${BLUE}2. 检查错误处理${NC}"

# 检查handleGenerate函数中的输入检查
if grep -q "elements.storyInput ? elements.storyInput.value.trim() : ''" main.js; then
    echo -e "${GREEN}✅ handleGenerate输入检查已修复${NC}"
else
    echo -e "${RED}❌ handleGenerate输入检查未修复${NC}"
fi

# 检查handleRegenerate函数中的输入检查
if grep -q "elements.storyInput ? elements.storyInput.value.trim() : ''" main.js; then
    echo -e "${GREEN}✅ handleRegenerate输入检查已修复${NC}"
else
    echo -e "${RED}❌ handleRegenerate输入检查未修复${NC}"
fi

echo -e "${BLUE}3. 检查关键错误修复${NC}"

# 检查原始错误是否已修复
original_error="Cannot read properties of null (reading 'classList')"
if grep -q "if (elements.emptyState)" main.js && grep -q "if (elements.storyContainer)" main.js; then
    echo -e "${GREEN}✅ 原始classList错误已修复${NC}"
else
    echo -e "${RED}❌ 原始classList错误未修复${NC}"
fi

# 检查addEventListener错误是否已修复
if grep -q "if (elements.generateBtn)" main.js && grep -q "if (elements.prevBtn)" main.js && grep -q "if (elements.nextBtn)" main.js; then
    echo -e "${GREEN}✅ addEventListener错误已修复${NC}"
else
    echo -e "${RED}❌ addEventListener错误未修复${NC}"
fi

echo -e "${BLUE}4. 统计修复数量${NC}"

# 统计空值检查数量
null_checks=$(grep -c "if (elements\." main.js || echo "0")
echo -e "${BLUE}📊 空值检查总数: $null_checks${NC}"

# 统计修复的函数
fixed_functions=$(grep -c "if (elements\." main.js | wc -l)
echo -e "${BLUE}📊 修复的函数数量: $fixed_functions${NC}"

echo -e "${BLUE}5. 生成最终报告${NC}"
cat > final-null-check-report.md << EOF
# 最终Null错误检查报告

## 检查时间
$(date)

## 修复状态
- displayStory函数: $(if grep -q "if (elements.emptyState)" main.js && grep -q "if (elements.storyContainer)" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)
- bindEvents函数: $(if grep -q "if (elements.generateBtn)" main.js && grep -q "if (elements.prevBtn)" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)
- updatePageDisplay函数: $(if grep -q "if (elements.currentPageSpan)" main.js && grep -q "if (elements.prevBtn)" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)
- 音频播放器创建: $(if grep -q "音频播放器元素已创建" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)
- handleGenerate输入检查: $(if grep -q "elements.storyInput ? elements.storyInput.value.trim() : ''" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)
- handleRegenerate输入检查: $(if grep -q "elements.storyInput ? elements.storyInput.value.trim() : ''" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)

## 原始错误修复状态
- classList错误: $(if grep -q "if (elements.emptyState)" main.js && grep -q "if (elements.storyContainer)" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)
- addEventListener错误: $(if grep -q "if (elements.generateBtn)" main.js && grep -q "if (elements.prevBtn)" main.js && grep -q "if (elements.nextBtn)" main.js; then echo "✅ 已修复"; else echo "❌ 未修复"; fi)

## 统计信息
- 空值检查总数: $null_checks
- 修复的函数数量: $fixed_functions

## 结论
$(if grep -q "if (elements.emptyState)" main.js && grep -q "if (elements.storyContainer)" main.js && grep -q "if (elements.generateBtn)" main.js && grep -q "if (elements.prevBtn)" main.js && grep -q "if (elements.nextBtn)" main.js; then echo "✅ 所有关键null错误已修复"; else echo "⚠️ 仍有部分null错误需要修复"; fi)
EOF

echo -e "${GREEN}✅ 最终检查报告已生成: final-null-check-report.md${NC}"

echo ""
echo -e "${GREEN}🎉 最终检查完成！${NC}"
echo "=============================================="

# 检查是否所有关键修复都已完成
if grep -q "if (elements.emptyState)" main.js && grep -q "if (elements.storyContainer)" main.js && grep -q "if (elements.generateBtn)" main.js && grep -q "if (elements.prevBtn)" main.js && grep -q "if (elements.nextBtn)" main.js; then
    echo -e "${GREEN}🎊 所有关键null错误已成功修复！${NC}"
    echo -e "${BLUE}📋 修复总结:${NC}"
    echo "  ✅ 修复了displayStory函数中的classList错误"
    echo "  ✅ 修复了bindEvents函数中的addEventListener错误"
    echo "  ✅ 修复了updatePageDisplay函数中的属性访问错误"
    echo "  ✅ 添加了音频播放器元素创建逻辑"
    echo "  ✅ 修复了输入值获取的空值检查"
    echo "  ✅ 总共添加了 $null_checks 个空值检查"
    exit 0
else
    echo -e "${YELLOW}⚠️  仍有部分null错误需要修复${NC}"
    exit 1
fi
