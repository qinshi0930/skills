#!/usr/bin/env bash
# 白名单与 Skip-SDD trailer 解析。通过 source 引入。
# 导出函数：
#   gpp_path_exempted <path>
#   gpp_all_staged_exempted
#   gpp_has_skip_trailer <commit-sha>

# 读取 .githooks/exemptions.yml 的 paths: 段（简化 yaml 解析，仅支持扁平列表）
_gpp_load_exemption_patterns() {
  config=".githooks/exemptions.yml"
  # 默认白名单
  cat <<EOF
**/*.md
docs/**
specs/**
.specs/**
.githooks/**
.gitignore
CHANGELOG.md
LICENSE
EOF
  [ -f "$config" ] || return
  awk '
    BEGIN { in_paths=0 }
    /^paths:[ \t]*$/ { in_paths=1; next }
    /^[A-Za-z_]+:/ { in_paths=0 }
    in_paths && /^[ \t]*-[ \t]*/ {
      sub(/^[ \t]*-[ \t]*/, "")
      gsub(/^["'"'"']|["'"'"']$/, "")
      if (length($0) > 0) print
    }
  ' "$config"
}

# 将 glob 风格的模式转成 shell case 可匹配的形式并尝试匹配。
# 对 **/ 前缀做特殊处理：同时匹配顶层与子目录下的文件。
# 例：**/*.md 既要匹配 README.md（顶层），也要匹配 docs/a.md（子目录）。
gpp_path_exempted() {
  path="$1"
  [ -z "$path" ] && return 1

  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue

    # 生成一组候选 shell 模式
    candidates=""
    case "$pattern" in
      "**/"*)
        rest="${pattern#**/}"
        # 顶层情况
        candidates="$rest"
        # 子目录递归情况：使用 * 匹配任意前缀（POSIX case 中 * 可跨 /）
        candidates="$candidates
*/$rest"
        ;;
      *"**"*)
        # 其它位置出现 ** → 降级为 *
        candidates="$(echo "$pattern" | sed 's|\*\*|*|g')"
        ;;
      *)
        candidates="$pattern"
        ;;
    esac

    while IFS= read -r shell_pat; do
      [ -z "$shell_pat" ] && continue
      case "$path" in
        $shell_pat) return 0 ;;
      esac
    done <<INNER
$candidates
INNER
  done <<EOF
$(_gpp_load_exemption_patterns)
EOF

  return 1
}

# staged 的每个文件都命中白名单 → 0；否则 1
gpp_all_staged_exempted() {
  files="$(git diff --cached --name-only)"
  [ -z "$files" ] && return 1
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if ! gpp_path_exempted "$f"; then
      return 1
    fi
  done <<EOF
$files
EOF
  return 0
}

# 判断指定 commit 的 message 是否含 Skip-SDD trailer
gpp_has_skip_trailer() {
  sha="$1"
  [ -z "$sha" ] && return 1
  message="$(git log -1 --format=%B "$sha" 2>/dev/null)"
  echo "$message" | grep -qE '^Skip-SDD:[ \t]*.+'
}
