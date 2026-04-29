---
name: git-pre-push
description: 守护 PR 工作流全链路的中文 Git 技能。在 commit 前拦截主分支直提并引导创建 feature 分支，在 push 前执行三级降级自动创建 PR，按改动规模要求 SDD 迷你 spec。Use when the user commits, pushes, creates a pull request, runs git hooks, or mentions PR workflow, SDD spec, protected branch, or pre-commit/pre-push checks.
---

# Git PR 工作流守门技能

## 核心目标

在 Git 工作流的两个关键时点强制落地 PR 工作流 + SDD 规范：

1. **commit 前**：禁止直接向受保护分支（`main`/`master`/`release/*`/`prod`）提交，强制走 feature 分支 → PR 合入路径。
2. **push 前**：禁止直推受保护分支，能力可用时自动创建 PR；按累计变更规模要求 spec 落地。

所有面向用户的提示、告警、引导文案使用**中文**；分支名、命令、路径、文件名保持英文原文。

与 `git-commit-cn` 分工：后者管 **commit message 格式**；本技能管 **commit 能不能写进主分支、能不能推上去、推上去后要不要自动建 PR**。

## 四象限决策表

技能触发后先做两个事实判断：**是否在受保护分支**、**是否存在对应 spec**，据此路由：

| 当前分支 | Spec 存在 | 路径 | 行为要点 |
|---|---|---|---|
| 主分支 | 有 | 拦截 + 简化确认 | 采用 spec 中的分支名与意图，一句话确认后切分支 commit |
| 主分支 | 无 | 拦截 + 完整审查 | 走审查引导；按阈值决定是否同步生成迷你 spec |
| feature | 有 | 放行 + 一致性核对 | 不拦截；核对 diff 是否在 spec 范围内，超范围提示拆分或更新 spec |
| feature | 无 | 放行 + 最小检查 | 不拦截；commit message 交给 `git-commit-cn`；push 前再核算累计规模 |

## Commit 阶段行为

### 触发与路径

- `pre-commit` hook 与 AI 对话"提交当前改动"两条路径均走同一套判定。
- 调用 `scripts/lib/detect-branch.sh` 判断当前分支；调用 `scripts/lib/detect-spec.sh` 匹配 spec。
- 调用 `scripts/lib/diff-size.sh` 计算暂存区新增行数与文件数（已扣除白名单）。

### 主分支 + 无 spec 的审查引导

当处于此象限时，AI 层必须输出以下结构，让用户三选一：

```
[审查] 本次变更意图推断：
  - 推断摘要：<一句话>
  - 影响文件：<列表>
  - 推断类型：feat / fix / ...（调用 git-commit-cn 的 type 规则）
  - 推断 scope：<模块名，可空>
  - 建议分支名：<type>/<scope>-<slug>
  - 是否超阈值：是 / 否（新增 >50 行 或 变更 >3 文件）

请选择：
  [1] 采纳并切分支（若超阈值则同步生成 specs/<slug>.md）
  [2] 改写分支名 / type / scope 后切分支
  [3] 放弃本次 commit（使用 git stash 或 git restore）
```

### 分支冲突三分法

新建分支前执行 `scripts/lib/conflict-check.sh` 判定：

- 仅本地同名 → 默认复用（`git checkout <name>`），用户确认。
- 仅远端同名 → `git fetch && git checkout -b <name> origin/<name>` 复用。
- 本地远端都有且分叉 → **停下**，输出分叉情况，用户选择 rebase / merge / 放弃，**禁止静默覆盖**。
- 都不存在 → `git checkout -b <name>` 新建。

### 工作区保全

切分支前若有未提交改动，必须通过 `git stash push -u` 或 `git reset --soft` 确保改动跟着过去，绝不丢代码。

## Push 阶段行为

### 三级降级

`pre-push` hook 与 AI 对话均按优先级执行：

1. **Level 1 自动 PR**：检测 `gh` 或 `glab` 已登录 → 调用 `scripts/create-pr.sh` 创建 PR。PR 标题/描述由 `git-commit-cn` 生成，合并 `templates/pr-description.md` 骨架。
2. **Level 2 引导 PR**：无 CLI 或未登录 → push feature 分支（`--set-upstream`）后输出可点击 PR 链接（根据 `git remote get-url origin` 推断 GitHub/GitLab/Gitee）。
3. **Level 3 仅拦截**：当前就是受保护分支 → 阻止 push，提示必须走 feature 分支 + PR 流程。

### 累计 diff 核算

push 前必须重新核算：

```bash
BASE=$(git merge-base HEAD origin/<default-branch>)
git diff --numstat "$BASE"..HEAD
```

扣除白名单后汇总新增行数与文件数。**超阈值且当前分支无对应 spec 文件** → 阻止 push，AI 层基于 `git log --oneline "$BASE"..HEAD` + 累计 diff 起草 `specs/<slug>.md`，用户确认后落盘重试。

### 强制推送

- 受保护分支 `--force` / `--force-with-lease` 一律禁止。
- feature 分支允许 `--force-with-lease`；裸 `--force` 需二次确认。

## 迷你 Spec 模板

位置：`templates/spec.md`。结构：

```markdown
---
branch: <type>/<slug>
created: <YYYY-MM-DD>
mode: mini
---

# <spec 标题>

## 变更意图
<一句话：解决什么问题 / 实现什么能力>

## 变更范围
- <受影响模块或文件列表（可由 git diff --name-only 填充）>

## 验收点
- [ ] <判断"完成"的可观察标准>
```

规则：
- 三段全部必填。
- 意图与范围由 AI 起草；**验收点必须由用户至少勾选或补充一条**，不得全空。
- 文件名：`specs/<slug>.md`，与分支 `<type>/<slug>` 的 slug 部分一致，构成双向绑定。

## 双轨分层契约

- **AI 层**：意图审查、摘要生成、type/scope 推断、迷你 spec 起草、PR 标题/描述生成、分叉情况解读、调 CLI 创建 PR。
- **Hook 层**：主分支黑名单、分支↔spec 存在性检查、累计 diff 超阈值硬拦截、白名单过滤、读取 `Skip-SDD:` trailer。

Hook 拦截输出必须**中文 + 引流**：

```
[阻止] 当前位于受保护分支 main，不允许直接 commit。
请通过 AI 完成此操作（在对话中说明变更意图，技能会自动审查并创建 feature 分支），
或手动执行：git checkout -b <type>/<scope>-<slug>
```

## 跳过机制与审计

### 白名单（常态豁免）

位置：`.githooks/exemptions.yml`，随仓库版本化。默认：

```yaml
paths:
  - "**/*.md"
  - "docs/**"
  - ".gitignore"
  - "CHANGELOG.md"
  - "LICENSE"
```

`diff-size.sh` 在核算前先剔除命中白名单的路径。

### Commit Trailer（事件豁免）

用户在最近一次 commit message 末尾加：

```
Skip-SDD: <中文理由>
```

Hook 识别到 trailer 后放行。Trailer 随 commit 进入 git 历史，`git log --all --grep="Skip-SDD"` 可审计。

### 优先级与禁令

Hook 判定顺序：白名单 → `Skip-SDD` trailer → 四象限标准流程。

- 严禁将 `--no-verify` 作为常规跳过；文档与安装输出必须警示。
- 明文写入：**本地跳过仅关闭本地 hook，不影响远端 branch protection 与 CI**。

## 安装与激活

运行 `scripts/install-hooks.sh` 安装：

- 创建仓库根目录 `.githooks/`（进入版本库）
- 复制 `hooks/pre-commit`、`hooks/pre-push` 到 `.githooks/`
- 执行 `git config core.hooksPath .githooks`
- 创建默认 `.githooks/exemptions.yml`、`.githooks/protected-branches`
- 输出当前激活状态与后续操作提示

幂等：已存在 hook 则 append 而非覆盖。卸载用 `scripts/uninstall-hooks.sh`。

**不引入 husky / Node.js**，保持跨语言项目通用。

## 输出格式

统一三级前缀：

| 前缀 | 含义 |
|---|---|
| `[通过]` | 检查通过 |
| `[提示]` | 中性信息 / 可选操作 |
| `[阻止]` | 硬拦截必须处理 |

中文文本 + 英文命令/路径/分支名。

## 工作流示例

### 示例 1：主分支 + 小改动（场景 2 快捷）

```
用户：帮我提交这个 typo 修复
AI：[提示] 当前在 main 分支，不允许直接提交。
    [审查] 变更意图：修复 README 拼写错误
    影响文件：README.md
    推断类型：docs
    建议分支名：docs/readme-typo
    是否超阈值：否（1 行 / 1 文件，且命中 **/*.md 白名单）
    是否采纳？
用户：采纳
AI：已切到 docs/readme-typo，完成 commit。message 遵循 git-commit-cn：
    docs: 修复 README 拼写错误
```

### 示例 2：主分支 + 中等改动 + 无 spec（走迷你 spec）

```
用户：我要提交刚才改的登录模块
AI：[审查] 变更意图：重构登录流程，新增 JWT 验证
    影响文件：src/auth/*.ts（4 个）、tests/auth/*.test.ts（2 个）
    推断类型：refactor、scope：auth
    建议分支名：refactor/auth-jwt
    是否超阈值：是（180 行 / 6 文件）→ 将生成 specs/auth-jwt.md
    是否采纳？
用户：采纳
AI：已生成 specs/auth-jwt.md（三段），请补充验收点：
    - [ ] ____
（用户填入验收点）→ 切分支 → commit
```

### 示例 3：feature 分支 + 有 spec（核对模式）

```
用户：提交当前改动
AI：[通过] 当前在 feat/auth-login 分支，已绑定 specs/auth-login.md。
    本次 diff 覆盖：src/auth/login.ts、src/auth/session.ts
    spec "变更范围" 列出：src/auth/login.ts、src/auth/session.ts、src/auth/token.ts
    ✓ 在 spec 范围内
    commit message: feat(auth): 补充会话超时处理
```

### 示例 4：push 阶段（Level 1 自动 PR）

```
用户：推送当前分支
AI：[通过] 累计变更：120 行 / 4 文件，已绑定 specs/auth-login.md。
    检测到 gh 已登录 → 正在创建 PR ...
    [通过] PR 已创建：https://github.com/org/repo/pull/42
    标题：feat(auth): 新增基于 JWT 的登录认证
```

### 示例 5：push 阶段累计超阈值但无 spec

```
用户：推送 feat/bugfix-suite
AI：[阻止] feat/bugfix-suite 累计 210 行 / 7 文件，超阈值但未找到 specs/bugfix-suite.md。
    已根据 git log 起草迷你 spec：
    （展示三段草稿）
    请补充验收点后确认落盘并重试 push。
```

## 辅助脚本

| 脚本 | 用途 |
|---|---|
| `scripts/install-hooks.sh` | 安装 hook 与默认配置 |
| `scripts/uninstall-hooks.sh` | 卸载并清理 `core.hooksPath` |
| `scripts/create-pr.sh` | 调 `gh`/`glab` 自动创建 PR |
| `scripts/lib/detect-branch.sh` | 受保护分支判定、当前分支读取 |
| `scripts/lib/detect-spec.sh` | 分支 ↔ spec 双向匹配 |
| `scripts/lib/diff-size.sh` | 阈值核算（含白名单过滤） |
| `scripts/lib/exemptions.sh` | 白名单与 `Skip-SDD` trailer 解析 |
| `scripts/lib/conflict-check.sh` | 分支冲突三分法 |

## 注意事项

- 所有 shell 脚本使用 POSIX 兼容语法 + `git` 命令，不依赖 Node/Python。
- Hook 层保持毫秒级返回，**不**在 hook 内调 LLM。
- 服务端 branch protection 是最后一道防线，本地 hook 是第一道；README 必须建议两者同开。
- 所有对外提示中文；内部日志可英文。
