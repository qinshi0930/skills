#!/usr/bin/env bash
# 在当前 Git 仓库中安装 git-pre-push 钩子。
# 行为：
#   1. 创建 .githooks/ 并复制 hooks/pre-commit、hooks/pre-push
#   2. 设置 core.hooksPath=.githooks
#   3. 生成默认 .githooks/exemptions.yml 与 .githooks/protected-branches（若不存在）
#   4. 输出激活状态

set -eu

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_SRC="$SKILL_DIR/hooks"
LIB_SRC="$SKILL_DIR/scripts/lib"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[阻止] 当前目录不是 Git 仓库。" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
TARGET_DIR="$REPO_ROOT/.githooks"
TARGET_LIB="$TARGET_DIR/lib"

mkdir -p "$TARGET_DIR" "$TARGET_LIB"

for h in pre-commit pre-push; do
  src="$HOOKS_SRC/$h"
  dst="$TARGET_DIR/$h"
  if [ -f "$dst" ] && ! grep -q "git-pre-push" "$dst" 2>/dev/null; then
    # 已存在他人 hook：追加而非覆盖
    backup="$dst.backup.$(date +%s)"
    mv "$dst" "$backup"
    echo "[提示] 已将原有 $h 备份到 $(basename "$backup")"
  fi
  cp "$src" "$dst"
  # 调整 lib 路径引用：安装后 lib 在同目录 lib/ 下
  sed -i.bak \
    -e 's|LIB_DIR="\$SKILL_DIR/scripts/lib"|LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" \&\& pwd)/lib"|' \
    "$dst"
  rm -f "$dst.bak"
  chmod +x "$dst"
done

# 拷贝 lib
cp "$LIB_SRC"/*.sh "$TARGET_LIB/"
chmod +x "$TARGET_LIB"/*.sh 2>/dev/null || true

# 生成默认白名单
EXEMPT_FILE="$TARGET_DIR/exemptions.yml"
if [ ! -f "$EXEMPT_FILE" ]; then
  cat > "$EXEMPT_FILE" <<'YML'
# git-pre-push 白名单：命中以下路径的改动不计入 spec 阈值核算
# 可按团队需要扩展
paths:
  - "**/*.md"
  - "docs/**"
  - "specs/**"
  - ".specs/**"
  - ".githooks/**"
  - ".gitignore"
  - "CHANGELOG.md"
  - "LICENSE"
YML
fi

# 生成默认受保护分支列表
PROT_FILE="$TARGET_DIR/protected-branches"
if [ ! -f "$PROT_FILE" ]; then
  cat > "$PROT_FILE" <<'LIST'
# git-pre-push 受保护分支：支持 <prefix>/* 通配
# 默认（已内置，无需重复）：main master develop release/* prod production
# 以下为项目追加项，每行一条
LIST
fi

# 激活 hooksPath
git config core.hooksPath .githooks

cat <<EOF
[完成] git-pre-push 已安装到 $TARGET_DIR，core.hooksPath=.githooks。

[提示]
  - 请将 .githooks/ 目录加入版本控制，团队成员 clone 后需各自再执行一次：
        git config core.hooksPath .githooks
    或运行：bash $SKILL_DIR/scripts/install-hooks.sh
  - 服务端 branch protection 是最后一道防线，建议在 GitHub/GitLab 同步开启。
  - 紧急跳过：在 commit message 末尾追加 'Skip-SDD: <中文理由>' 可放行当次。
  - 严禁以 --no-verify 作为常规跳过手段。
EOF
