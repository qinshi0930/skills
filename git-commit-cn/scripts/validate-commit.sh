#!/bin/bash
# 验证 Git 提交信息是否符合中文规范
# 用法: ./validate-commit.sh "提交信息"
# 依赖: GNU grep（需支持 -P PCRE）；macOS BSD grep 需先安装 coreutils/grep 并用 ggrep 调用

set -e

COMMIT_MSG="$1"

if [ -z "$COMMIT_MSG" ]; then
    echo "❌ 错误: 请提供提交信息"
    echo "用法: $0 \"type(scope): 中文描述\""
    exit 1
fi

# 验证格式: <type>(<scope>): <中文描述> 或 <type>: <中文描述>
# 描述部分只要求包含至少 1 个中文字符，不限定中文字符位于首尾或中间
if echo "$COMMIT_MSG" | grep -qP '^(feat|fix|docs|style|refactor|test|chore|perf|build|ci|revert)(\([a-z0-9-]+\))?: .*[\x{4e00}-\x{9fff}].*$'; then
    echo "✅ 提交信息格式正确"
    echo ""
    echo "📋 解析结果:"
    
    # 提取 type
    TYPE=$(echo "$COMMIT_MSG" | grep -oP '^(feat|fix|docs|style|refactor|test|chore|perf|build|ci|revert)')
    echo "  Type: $TYPE"
    
    # 提取 scope (如果有)
    if echo "$COMMIT_MSG" | grep -qP '^\w+\('; then
        SCOPE=$(echo "$COMMIT_MSG" | grep -oP '^\w+\(\K[^)]+')
        echo "  Scope: $SCOPE"
    fi
    
    # 提取描述
    DESC=$(echo "$COMMIT_MSG" | sed -E 's/^[a-z]+(\([a-z0-9-]+\))?: //')
    echo "  描述: $DESC"
    
    exit 0
else
    echo "❌ 提交信息格式不符合规范"
    echo ""
    echo "📝 正确格式: <type>(<scope>): <中文描述>"
    echo ""
    echo "示例:"
    echo "  feat(auth): 新增用户登录功能"
    echo "  fix(api): 修复获取用户信息接口的异常"
    echo "  docs: 更新 README 安装说明"
    echo ""
    echo "支持的 type:"
    echo "  feat, fix, docs, style, refactor, test, chore, perf, build, ci, revert"
    echo ""
    exit 1
fi
