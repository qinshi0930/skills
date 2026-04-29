#!/usr/bin/env bash
# 分支判定相关函数。通过 source 引入。
# 导出函数：
#   gpp_current_branch
#   gpp_is_protected_branch <branch>
#   gpp_default_branch [remote]

# 返回当前分支名（detached HEAD 返回空）
gpp_current_branch() {
  git symbolic-ref --short -q HEAD 2>/dev/null || echo ""
}

# 判定是否受保护分支。默认黑名单 + 仓库 .githooks/protected-branches 覆盖。
# 支持通配符：以 * 结尾的前缀匹配（如 release/*）。
gpp_is_protected_branch() {
  branch="$1"
  [ -z "$branch" ] && return 1

  default_list="main master develop release/* prod production"
  config_file=".githooks/protected-branches"
  patterns="$default_list"
  if [ -f "$config_file" ]; then
    # 过滤空行与 # 注释
    extra="$(grep -vE '^\s*(#|$)' "$config_file" | tr '\n' ' ')"
    patterns="$patterns $extra"
  fi

  for pattern in $patterns; do
    case "$branch" in
      "$pattern") return 0 ;;
      *)
        # 支持 <prefix>/* 形式
        case "$pattern" in
          */\*)
            prefix="${pattern%/\*}"
            case "$branch" in
              "$prefix"/*) return 0 ;;
            esac
            ;;
        esac
        ;;
    esac
  done

  return 1
}

# 探测远端默认分支：优先 symbolic-ref，其次回退 main/master。
gpp_default_branch() {
  remote="${1:-origin}"
  ref="$(git symbolic-ref --short -q "refs/remotes/$remote/HEAD" 2>/dev/null || echo "")"
  if [ -n "$ref" ]; then
    echo "${ref#"$remote"/}"
    return
  fi
  if git show-ref --verify --quiet "refs/remotes/$remote/main"; then
    echo "main"
  elif git show-ref --verify --quiet "refs/remotes/$remote/master"; then
    echo "master"
  else
    echo "main"
  fi
}
