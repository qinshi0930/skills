#!/usr/bin/env bash
# 分支冲突三分法判定。通过 source 引入或独立执行。
# 导出函数：
#   gpp_conflict_status <branch>
#     输出枚举：none / local-only / remote-only / in-sync / divergent
#
# 使用：
#   status="$(gpp_conflict_status feat/auth-login)"
#   case "$status" in
#     none) git checkout -b "$name" ;;
#     local-only) git checkout "$name" ;;
#     remote-only) git fetch && git checkout -b "$name" "origin/$name" ;;
#     in-sync) git checkout "$name" ;;
#     divergent) ... ;;
#   esac

gpp_conflict_status() {
  branch="$1"
  remote="${2:-origin}"
  [ -z "$branch" ] && { echo "none"; return; }

  has_local=0
  has_remote=0

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    has_local=1
  fi

  if git ls-remote --heads --exit-code "$remote" "$branch" >/dev/null 2>&1; then
    has_remote=1
  fi

  if [ "$has_local" = "0" ] && [ "$has_remote" = "0" ]; then
    echo "none"
    return
  fi
  if [ "$has_local" = "1" ] && [ "$has_remote" = "0" ]; then
    echo "local-only"
    return
  fi
  if [ "$has_local" = "0" ] && [ "$has_remote" = "1" ]; then
    echo "remote-only"
    return
  fi

  # 两侧都有：判断是否分叉
  git fetch --quiet "$remote" "$branch" 2>/dev/null || true
  if ! git rev-parse --verify --quiet "refs/remotes/$remote/$branch" >/dev/null; then
    echo "local-only"
    return
  fi

  counts="$(git rev-list --left-right --count "$branch...$remote/$branch" 2>/dev/null || echo "0 0")"
  ahead="$(echo "$counts" | awk '{print $1}')"
  behind="$(echo "$counts" | awk '{print $2}')"

  if [ "$ahead" = "0" ] && [ "$behind" = "0" ]; then
    echo "in-sync"
  elif [ "$ahead" = "0" ] || [ "$behind" = "0" ]; then
    # 单向领先 / 落后——允许复用
    echo "local-only"
  else
    echo "divergent"
  fi
}

# 命令行入口：直接调用可打印状态
if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  gpp_conflict_status "$@"
fi
