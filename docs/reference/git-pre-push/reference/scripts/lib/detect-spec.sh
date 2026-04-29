#!/usr/bin/env bash
# Spec 检测相关函数。通过 source 引入。
# 导出函数：
#   gpp_branch_slug <branch>
#   gpp_find_spec_for_branch <branch>
#   gpp_diff_covered_by_spec <spec-file>

# 从分支名 <type>/<slug> 取 slug；无前缀则整个分支名即 slug。
gpp_branch_slug() {
  branch="$1"
  case "$branch" in
    */*) echo "${branch#*/}" ;;
    *) echo "$branch" ;;
  esac
}

# 在若干约定目录中寻找与分支对应的 spec 文件。
# 命中返回相对路径并 exit 0；未命中返回空且 exit 1。
gpp_find_spec_for_branch() {
  branch="$1"
  slug="$(gpp_branch_slug "$branch")"
  [ -z "$slug" ] && return 1

  for dir in specs docs/specs .specs; do
    candidate="$dir/$slug.md"
    if [ -f "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

# 读取 spec 的『变更范围』段，判断当前 staged diff 涉及的文件是否全部在范围内。
# 简化实现：范围段内每个 - 前缀的条目作为 glob；全部命中返回 0，否则返回 1。
gpp_diff_covered_by_spec() {
  spec_file="$1"
  [ -f "$spec_file" ] || return 0  # spec 不存在时不报错

  # 抽取『变更范围』下一段到下一个 ## 或 EOF
  scope_block="$(awk '
    /^## 变更范围/ { capture=1; next }
    /^## / { capture=0 }
    capture && /^[ \t]*-/ { gsub(/^[ \t]*-[ \t]*/, ""); print }
  ' "$spec_file")"

  [ -z "$scope_block" ] && return 0

  # 获取 staged 改动文件（pre-commit 场景）
  files="$(git diff --cached --name-only)"
  [ -z "$files" ] && return 0

  missing=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    matched=0
    while IFS= read -r pattern; do
      [ -z "$pattern" ] && continue
      case "$f" in
        $pattern) matched=1; break ;;
      esac
    done <<EOF
$scope_block
EOF
    if [ "$matched" = "0" ]; then
      missing=1
    fi
  done <<EOF
$files
EOF

  [ "$missing" = "0" ]
}
