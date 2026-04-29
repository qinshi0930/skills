#!/usr/bin/env bash
# 阈值核算相关函数。通过 source 引入。
# 阈值：新增行数 > 50 或 变更文件数 > 3。
# 依赖：gpp_path_exempted（来自 exemptions.sh）
#
# 导出函数：
#   gpp_diff_exceeds_threshold <base> <head>
#   gpp_diff_stats <base> <head>
#   gpp_staged_exceeds_threshold

: "${GPP_LINE_THRESHOLD:=50}"
: "${GPP_FILE_THRESHOLD:=3}"

# 内部：核算 <base>..<head> 扣除白名单后的 (added_lines, file_count)，打印 "added files"
_gpp_accumulate_range() {
  base="$1"
  head="$2"
  git diff --numstat "$base" "$head" | awk -v exempt_fn="gpp_path_exempted" '
    BEGIN { added=0; files=0 }
    {
      # 跳过二进制行（numstat 对二进制文件输出 - -）
      if ($1 == "-" || $2 == "-") next
      path=$3
      # gsub for renames "old => new"
      if (path ~ / => /) {
        gsub(/.* => /, "", path)
        gsub(/[{}]/, "", path)
      }
      paths[NR]=path
      added_map[NR]=$1
    }
    END {
      for (i in paths) {
        cmd = exempt_fn " \"" paths[i] "\" >/dev/null 2>&1"
        if (system(cmd) != 0) {
          added += added_map[i]
          files++
        }
      }
      printf "%d %d", added, files
    }
  '
}

# 单独用 shell 循环实现避免 awk 调 system 的开销问题
_gpp_accumulate_range_shell() {
  base="$1"
  head="$2"
  added=0
  files=0
  while IFS=$'\t' read -r a d path; do
    [ -z "$path" ] && continue
    [ "$a" = "-" ] && continue
    # 处理 rename "old => new" 或 "prefix{old => new}suffix"
    case "$path" in
      *" => "*)
        path="$(echo "$path" | sed 's/.*=> //; s/[{}]//g')"
        ;;
    esac
    if gpp_path_exempted "$path"; then
      continue
    fi
    added=$((added + a))
    files=$((files + 1))
  done <<EOF
$(git diff --numstat "$base" "$head")
EOF
  printf "%d %d" "$added" "$files"
}

gpp_diff_exceeds_threshold() {
  base="$1"
  head="$2"
  set -- $(_gpp_accumulate_range_shell "$base" "$head")
  added="$1"
  files="$2"
  if [ "$added" -gt "$GPP_LINE_THRESHOLD" ] || [ "$files" -gt "$GPP_FILE_THRESHOLD" ]; then
    return 0
  fi
  return 1
}

gpp_diff_stats() {
  base="$1"
  head="$2"
  set -- $(_gpp_accumulate_range_shell "$base" "$head")
  added="$1"
  files="$2"
  echo "新增 ${added} 行 / 变更 ${files} 个文件（已扣除白名单）"
}

# staged 版本：用于 pre-commit 场景
_gpp_accumulate_staged() {
  added=0
  files=0
  while IFS=$'\t' read -r a d path; do
    [ -z "$path" ] && continue
    [ "$a" = "-" ] && continue
    case "$path" in
      *" => "*)
        path="$(echo "$path" | sed 's/.*=> //; s/[{}]//g')"
        ;;
    esac
    if gpp_path_exempted "$path"; then
      continue
    fi
    added=$((added + a))
    files=$((files + 1))
  done <<EOF
$(git diff --cached --numstat)
EOF
  printf "%d %d" "$added" "$files"
}

gpp_staged_exceeds_threshold() {
  set -- $(_gpp_accumulate_staged)
  added="$1"
  files="$2"
  if [ "$added" -gt "$GPP_LINE_THRESHOLD" ] || [ "$files" -gt "$GPP_FILE_THRESHOLD" ]; then
    return 0
  fi
  return 1
}
