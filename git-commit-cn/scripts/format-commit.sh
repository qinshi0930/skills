#!/bin/bash
# 自动格式化提交信息为中文规范
# 用法: ./format-commit.sh "原始提交信息"
# 依赖: GNU grep（需支持 -P PCRE）；macOS BSD grep 需先安装 coreutils/grep 并用 ggrep 调用

set -e

RAW_INPUT="$1"

if [ -z "$RAW_INPUT" ]; then
    echo "❌ 错误: 请提供提交信息"
    echo "用法: $0 \"提交信息\""
    exit 1
fi

# 推断 type
infer_type() {
    local input="$1"
    local input_lower=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    
    if echo "$input_lower" | grep -qE '(feat|feature|新增|添加|实现|add|implement|new)'; then
        echo "feat"
    elif echo "$input_lower" | grep -qE '(fix|bug|修复|错误|error|issue)'; then
        echo "fix"
    elif echo "$input_lower" | grep -qE '(perf|优化|提升|性能|optimize|performance|improve)'; then
        echo "perf"
    elif echo "$input_lower" | grep -qE '(refactor|重构|restructure)'; then
        echo "refactor"
    elif echo "$input_lower" | grep -qE '(docs|doc|文档|readme|documentation)'; then
        echo "docs"
    elif echo "$input_lower" | grep -qE '(test|测试|spec|单元测试|integration)'; then
        echo "test"
    elif echo "$input_lower" | grep -qE '(style|样式|格式|format|lint|prettier)'; then
        echo "style"
    elif echo "$input_lower" | grep -qE '(build|构建|webpack|vite|babel|compile)'; then
        echo "build"
    elif echo "$input_lower" | grep -qE '(ci|cd|deploy|部署|pipeline|workflow|github action)'; then
        echo "ci"
    elif echo "$input_lower" | grep -qE '(revert|回滚|撤销|rollback)'; then
        echo "revert"
    else
        echo "chore"
    fi
}

# 简单翻译(常见词汇映射)
translate_to_chinese() {
    local text="$1"
    
    # 这里可以扩展更多翻译规则
    # 当前版本主要做格式规范化,复杂翻译需要 AI 辅助
    
    # 移除常见英文前缀
    text=$(echo "$text" | sed -E 's/^(add|added|feat|feature|new)\s*//gi')
    text=$(echo "$text" | sed -E 's/^(fix|fixed|bug|patch)\s*//gi')
    text=$(echo "$text" | sed -E 's/^(update|updated|upd)\s*//gi')
    text=$(echo "$text" | sed -E 's/^(remove|removed|delete|del)\s*//gi')
    text=$(echo "$text" | sed -E 's/^(optimize|improve|perf)\s*//gi')
    text=$(echo "$text" | sed -E 's/^(refactor|restructure)\s*//gi')
    
    echo "$text"
}

# 提取 scope(如果存在)
extract_scope() {
    local input="$1"
    if echo "$input" | grep -qP '^\w+\('; then
        echo "$input" | grep -oP '^\w+\(\K[^)]+'
    fi
}

# 主逻辑
TYPE=$(infer_type "$RAW_INPUT")
SCOPE=$(extract_scope "$RAW_INPUT")

# 清理输入,移除已有的 type 和 scope
CLEAN_INPUT=$(echo "$RAW_INPUT" | sed -E 's/^[a-z]+(\([a-z0-9-]+\))?:\s*//gi')

# 翻译为中文(简单版本)
CHINESE_DESC=$(translate_to_chinese "$CLEAN_INPUT")

# 如果描述仍为英文,提示用户手动翻译
if echo "$CHINESE_DESC" | grep -qP '[a-zA-Z]{4,}'; then
    echo "⚠️  检测到英文描述,建议翻译为中文"
    echo ""
    echo "📝 建议格式:"
    if [ -n "$SCOPE" ]; then
        echo "  $TYPE($SCOPE): [请翻译为中文] $CHINESE_DESC"
    else
        echo "  $TYPE: [请翻译为中文] $CHINESE_DESC"
    fi
    echo ""
    echo "或者我可以帮您生成完整的中文提交信息,请告诉我:"
    echo "  - 具体变更了什么功能?"
    echo "  - 解决了什么问题?"
else
    # 生成格式化后的提交信息
    if [ -n "$SCOPE" ]; then
        FORMATTED="$TYPE($SCOPE): $CHINESE_DESC"
    else
        FORMATTED="$TYPE: $CHINESE_DESC"
    fi
    
    echo "✅ 格式化完成:"
    echo ""
    echo "  $FORMATTED"
    echo ""
    echo "💡 提示:"
    echo "  - 如需添加详细描述,请另起一行"
    echo "  - 关联 Issue: 在末尾添加 'Closes #123'"
fi
