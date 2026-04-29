#!/usr/bin/env bash
# 调用 gh / glab CLI 自动创建 Pull Request。
# 用法：
#   create-pr.sh [--title <标题>] [--body-file <文件>] [--base <默认分支>]
# 若未提供标题 / 正文，会调用 git log 生成简单占位，建议由 AI 层替换。

set -eu

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$SKILL_DIR/scripts/lib/detect-branch.sh"

title=""
body_file=""
base=""

while [ $# -gt 0 ]; do
  case "$1" in
    --title) title="$2"; shift 2 ;;
    --body-file) body_file="$2"; shift 2 ;;
    --base) base="$2"; shift 2 ;;
    *) echo "[阻止] 未识别参数：$1" >&2; exit 1 ;;
  esac
done

[ -z "$base" ] && base="$(gpp_default_branch origin)"
head_branch="$(gpp_current_branch)"

if [ -z "$head_branch" ] || [ "$head_branch" = "$base" ]; then
  echo "[阻止] 当前分支为空或等于默认分支 '$base'，无法创建 PR。" >&2
  exit 1
fi

# 兜底标题
if [ -z "$title" ]; then
  last_msg="$(git log -1 --format=%s)"
  title="$last_msg"
fi

# 兜底正文
if [ -z "$body_file" ]; then
  tmp="$(mktemp)"
  body_file="$tmp"
  template="$SKILL_DIR/templates/pr-description.md"
  if [ -f "$template" ]; then
    cp "$template" "$body_file"
  else
    git log --oneline "origin/$base..HEAD" > "$body_file"
  fi
fi

# 平台探测
url="$(git remote get-url origin 2>/dev/null || echo "")"
# 将 git remote URL 转为 https 形式的 owner/repo
_gpp_repo_slug() {
  raw="$1"
  slug="${raw#git@*:}"
  slug="${slug#https://*/}"
  slug="${slug#http://*/}"
  slug="${slug%.git}"
  echo "$slug"
}

case "$url" in
  *github*)
    slug="$(_gpp_repo_slug "$url")"
    compare_url="https://github.com/$slug/compare/$base...$head_branch?expand=1"
    if ! command -v gh >/dev/null 2>&1; then
      echo "[降级] 未检测到 gh CLI，请手动在浏览器创建 PR：" >&2
      echo "    $compare_url" >&2
      exit 2
    fi
    if ! gh pr create --title "$title" --body-file "$body_file" --base "$base" --head "$head_branch"; then
      echo "[降级] gh pr create 执行失败（可能未登录或无权限），请改用浏览器：" >&2
      echo "    $compare_url" >&2
      exit 2
    fi
    ;;
  *gitlab*)
    slug="$(_gpp_repo_slug "$url")"
    compare_url="https://gitlab.com/$slug/-/merge_requests/new?merge_request%5Bsource_branch%5D=$head_branch&merge_request%5Btarget_branch%5D=$base"
    if ! command -v glab >/dev/null 2>&1; then
      echo "[降级] 未检测到 glab CLI，请手动在浏览器创建 MR：" >&2
      echo "    $compare_url" >&2
      exit 2
    fi
    if ! glab mr create --title "$title" --description "$(cat "$body_file")" --target-branch "$base" --source-branch "$head_branch"; then
      echo "[降级] glab mr create 执行失败，请改用浏览器：" >&2
      echo "    $compare_url" >&2
      exit 2
    fi
    ;;
  *)
    echo "[提示] 未能识别远端平台（非 GitHub / GitLab），请手动创建 PR。" >&2
    echo "    标题：$title"
    echo "    正文：$body_file"
    exit 2
    ;;
esac
