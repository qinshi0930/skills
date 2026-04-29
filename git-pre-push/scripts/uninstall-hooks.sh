#!/usr/bin/env bash
# 卸载 git-pre-push：清理 core.hooksPath 与 .githooks 下由本技能写入的文件。
# 不会删除 exemptions.yml 与 protected-branches（团队配置）。

set -eu

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "[阻止] 当前目录不是 Git 仓库。" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
TARGET_DIR="$REPO_ROOT/.githooks"

removed=0
for h in pre-commit pre-push; do
  f="$TARGET_DIR/$h"
  if [ -f "$f" ] && grep -q "git-pre-push" "$f" 2>/dev/null; then
    rm -f "$f"
    removed=$((removed + 1))
  fi
done

if [ -d "$TARGET_DIR/lib" ]; then
  rm -rf "$TARGET_DIR/lib"
fi

# 若 core.hooksPath 目前指向 .githooks，还原默认
current="$(git config --get core.hooksPath || true)"
if [ "$current" = ".githooks" ]; then
  git config --unset core.hooksPath
fi

cat <<EOF
[完成] 已卸载 git-pre-push（清理 $removed 个 hook 文件与 lib/ 目录）。
[提示]
  - 保留了 .githooks/exemptions.yml 与 protected-branches（团队配置）。
    如需彻底清理，请手动删除 $TARGET_DIR。
  - core.hooksPath 设置已还原为默认（.git/hooks/）。
EOF
