请创建一个名为 **git-pre-push** 的技能，用于守护 PR 工作流的**全链路**（本地 commit 前 + push 前两个时点）。该技能必须严格遵循以下规范。所有面向用户的提示、错误信息、引导文案一律使用**中文**。

---

## 一、技能目标

在本地 Git 工作流的两个守门点上强制落地 Pull Request 工作流与 SDD（Spec-Driven Development）规范：

1. **commit 前**：禁止直接向本地主分支（`main` / `master` / `release/*` 等受保护分支）提交，强制走 feature 分支 → PR 合入路径；并按改动规模要求存在对应的 spec 文档。
2. **push 前**：禁止直推受保护分支，在能力可用时自动创建 PR；按**累计变更规模**重新核算并要求 spec 落地。

技能与 `git-commit-cn` 职责分离：`git-commit-cn` 管 **commit message 怎么写**，本技能管 **commit 能不能写进主分支、分支能不能推上去、推上去之后要不要自动 PR**。

---

## 二、核心设计决策总表

| 编号 | 决策项 | 采用方案 |
|---|---|---|
| D1 | 技能核心定位 | 三级降级：优先自动创建 PR（调用 `gh`/`glab`）→ 引导用户手动创建 PR → 仅拦截直推受保护分支 |
| D2 | 技能边界 | 单 skill 同时覆盖 commit 前与 push 前两个守门点，不拆分 |
| D3 | commit 拦截后交互 | 审查后引导：展示 diff 意图摘要 + 推断的 type/scope/分支名，用户三选一（采纳 / 改写 / 放弃） |
| D4 | 场景判定入口 | 两阶段短路：先判"是否在主分支"，再判"是否存在对应 spec"；构成四象限决策表 |
| D5 | 主分支 + 无 spec 的审查粒度 | 按改动规模分级：`>50 行新增` 或 `>3 个文件` 任一命中则走迷你 spec 流程，否则零 spec 仅对话确认 |
| D6 | 分支名冲突处理 | 三分法：本地同名 → 复用；远端同名 → fetch 后复用；本地远端分叉 → 停下来让用户决定，禁止静默覆盖 |
| D7 | push 阶段 spec 补写判定 | push 前按 `origin/<base>...HEAD` 重新核算累计 diff，超阈值且无 spec 则阻止，要求补写迷你 spec |
| D8 | 落地形态 | 双轨分层：AI 层做语义审查 / 起草 / 推断 / 自动化；Hook 层做硬拦截（确定性规则，毫秒返回） |
| D9 | Hook 安装方式 | 裸 shell hook + `git config core.hooksPath .githooks`，不绑 Node.js/husky |
| D10 | 包文件结构 | 分目录：`hooks/` 入口、`scripts/` + `scripts/lib/` 复用逻辑、`templates/` 纯文本模板 |
| D11 | 迷你 spec 模板 | 极简三段：变更意图 / 变更范围 / 验收点 |
| D12 | 跳过机制 | 组合：白名单文件（常态豁免）+ commit trailer `Skip-SDD:`（事件豁免）；禁止裸 `--no-verify` 静默跳过 |

---

## 三、四象限决策表（D4 展开）

技能启动后（无论是 commit 前还是 push 前被触发），先执行两个事实判断：

1. 当前是否在受保护分支？
2. 是否能找到与当前分支（或待创建分支）绑定的 spec 文件？

据此路由到以下四种行为路径：

| 当前分支 | Spec 存在性 | 路径 | 行为要点 |
|---|---|---|---|
| 主分支 | 有 spec | **拦截 + 简化确认** | 直接采用 spec 里的分支名与意图，展示一句话确认，切分支 commit |
| 主分支 | 无 spec | **拦截 + 完整审查** | 走 D3 审查流程；根据 D5 阈值决定是否同步生成迷你 spec |
| feature 分支 | 有 spec | **放行 + 一致性核对** | 不拦截 commit；运行 "当前 diff 是否落在 spec 范围内" 核对，超范围则提示拆分或更新 spec |
| feature 分支 | 无 spec | **放行 + 最小检查** | 不拦截 commit；仅把 commit message 交给 `git-commit-cn` 检查；push 前按 D7 再核算累计规模 |

---

## 四、Commit 阶段行为规范

### 4.1 触发时机
- `pre-commit` hook：在用户执行 `git commit` 时调用。
- AI 对话触发：用户在 Agent 会话里要求"提交当前改动"时。

### 4.2 判定流程
1. 读取当前分支名，判断是否受保护分支。受保护列表默认 `main`、`master`、`release/*`、`prod`；允许通过 `.githooks/protected-branches` 配置覆盖。
2. 若不在主分支 → 进入四象限右半（放行路径）。
3. 若在主分支 → 扫描 spec 路径（默认 `specs/`、`docs/specs/`、`.specs/`），按分支命名约定 `<type>/<slug>` ↔ `specs/<slug>.md` 双向匹配。
4. 计算本次暂存区改动规模：新增行数（`git diff --cached --numstat` 汇总）+ 变更文件数。
5. 执行路径对应的行为（见 §三 四象限）。

### 4.3 审查后引导交互（D3）
当处于"主分支 + 无 spec"象限时，AI 必须输出以下结构化信息，让用户三选一：

```
[审查] 本次变更意图推断：
  - 推断摘要：<一句话>
  - 影响文件：<列表>
  - 推断类型：feat / fix / ...（基于 git-commit-cn 的 type 规则）
  - 推断 scope：<模块名，可空>
  - 建议分支名：<type>/<scope>-<slug>
  - 是否超阈值：是 / 否（>50 行 或 >3 文件）

请选择：
  [1] 采纳并切分支（若超阈值则同步生成 specs/<slug>.md）
  [2] 改写分支名 / type / scope 后切分支
  [3] 放弃本次 commit（提示使用 git stash 或 git restore）
```

### 4.4 分支冲突处理（D6）
在创建新分支前必须执行：

```bash
# 本地是否存在同名分支
git show-ref --verify --quiet refs/heads/<name>
# 远端是否存在同名分支
git ls-remote --heads origin <name>
# 若两者都有，判断是否分叉
git fetch origin <name>
git rev-list --left-right --count <name>...origin/<name>
```

根据检测结果：
- 仅本地同名 → 默认 `git checkout <name>` 复用，提示用户确认。
- 仅远端同名 → `git fetch && git checkout -b <name> origin/<name>` 复用，提示用户确认。
- 本地远端都有且分叉（counts 非 `0 0`）→ **必须停下**，输出分叉情况，让用户选择 rebase / merge / 放弃，**禁止**自动切。
- 都不存在 → `git checkout -b <name>` 新建。

---

## 五、Push 阶段行为规范

### 5.1 三级降级（D1）
`pre-push` hook 与 AI 对话均按以下优先级执行：

1. **Level 1 自动 PR**：检测本机有 `gh` / `glab` 且已登录 → 调用对应 CLI 创建 PR。PR 标题与描述交由 `git-commit-cn` 与 `templates/pr-description.md` 模板协同生成，完成后返回 PR URL。CLI 存在但执行失败（未登录 / 403 / 网络错误）时自动降级到 Level 2。
2. **Level 2 引导 PR**：未检测到 CLI 或 CLI 执行失败 → push 到 feature 分支（自动 `--set-upstream`），然后**必须输出可点击的 compare URL**，格式如下：

   | 平台 | URL 模版 |
   |---|---|
   | GitHub | `https://github.com/<owner>/<repo>/compare/<base>...<head>?expand=1` |
   | GitLab | `https://gitlab.com/<owner>/<repo>/-/merge_requests/new?merge_request%5Bsource_branch%5D=<head>&merge_request%5Btarget_branch%5D=<base>` |
   | Gitee  | `https://gitee.com/<owner>/<repo>/compare/<base>...<head>` |

   `<owner>/<repo>` 从 `git remote get-url origin` 解析，兼容 `git@host:owner/repo.git` 与 `https://host/owner/repo(.git)?` 两种形式。输出使用 `[降级]` 前缀，用户能直接复制或 Cmd+Click 进入浏览器。
3. **Level 3 仅拦截**：当前分支是受保护分支 → 直接阻止 push，提示必须走 feature 分支 + PR 流程。

### 5.2 累计 diff 核算（D7）
push 前必须计算累计变更规模。base sha 按以下优先级逐级 fallback，避免全新分支 / 远端无默认分支时被误放行：

```bash
BASE=$(git merge-base HEAD "origin/$default_branch" 2>/dev/null) \
  || BASE=$(git merge-base HEAD "$default_branch" 2>/dev/null) \
  || for fb in main master develop; do
       BASE=$(git merge-base HEAD "$fb" 2>/dev/null) && break
     done
[ -z "$BASE" ] && exit_with "[阻止] 无法定位与默认分支的共同祖先，拒绝推送以防误放行"

git diff --numstat "$BASE"..HEAD | ...
```

规则：
- 三级 fallback 全部失败 → **必须阻止 push**，不得默认放行。
- 汇总**扣除白名单**后的新增行数与文件数。超阈值（`>50 行` 或 `>3 文件`）且**当前分支没有对应 spec 文件** → 阻止 push，调用 AI 层起草迷你 spec：
  - 输入：`git log --oneline "$BASE"..HEAD` + 累计 diff
  - 输出：填好三段内容的 `specs/<slug>.md` 草稿，交用户过一遍后落盘
  - 落盘后重试 push

### 5.3 强制推送
- 禁止对受保护分支执行 `--force`。
- 对 feature 分支允许 `--force-with-lease`（视为更安全），裸 `--force` 需在对话里二次确认。

### 5.4 分支删除保护
`git push --delete <branch>` 与 `git push <remote> :<branch>` 等价于 "删除远端分支"，stdin 特征为 `local_sha` 全零 (`0000000000000000000000000000000000000000`)。Hook 必须：

1. 识别全零 local_sha → 进入删除分支分支。
2. 若被删除的 `remote_ref` 命中受保护分支列表 → **阻止**，输出 `[阻止] 禁止删除远端受保护分支 '<branch>'`。
3. 若为非保护分支 → 直接放行，**不做** SDD / spec / 累计 diff 核算（删除操作本身无 diff）。

---

## 六、Spec 模板规范（D11）

位置：`templates/spec.md`。内容骨架：

```markdown
---
branch: <type>/<slug>
created: <YYYY-MM-DD>
mode: mini
---

# <spec 标题>

## 变更意图
<一句话：这次改动解决什么问题 / 实现什么能力>

## 变更范围
- <受影响模块或文件列表（可由 git diff --name-only 自动填充）>

## 验收点
- [ ] <判断"完成"的可观察标准>
```

规则：
- 三段全部必填。
- 变更意图与变更范围由 AI 自动起草，验收点**必须**由用户至少勾选或补充一条，不得全空。
- 文件名约定：`specs/<slug>.md`，与分支名 `<type>/<slug>` 的 slug 部分一致，构成双向绑定。
- YAML front-matter 的 `mode: mini` 用于未来区分完整 SDD spec。

---

## 七、双轨分层契约（D8）

### 7.1 AI 层职责
- 意图审查、摘要生成、type/scope 推断
- 迷你 spec 起草、PR 标题与描述生成
- 分支冲突分叉情况的自然语言解读与建议
- 自动调用 `gh`/`glab` 创建 PR

### 7.2 Hook 层职责
- 主分支保护（黑名单匹配）
- 分支 ↔ spec 双向绑定的文件存在性检查
- 累计 diff 超阈值但无 spec 时的**硬拦截**
- 白名单路径过滤
- 读取最近 commit message 的 `Skip-SDD:` trailer

### 7.3 Hook 失败的引流
Hook 拦截时必须输出中文错误信息 + 引导下一步：

```
[阻止] 当前位于受保护分支 main，不允许直接 commit。
请使用 AI 完成此操作：在对话中说明变更意图，技能会自动审查并创建 feature 分支。
或手动执行：git checkout -b <type>/<scope>-<slug>
```

---

## 八、Hook 安装方式（D9）

- 仓库根目录创建 `.githooks/` 目录，提交进版本库。
- 将 skill 包内 `hooks/pre-commit`、`hooks/pre-push` 软链或复制到 `.githooks/`。
- 执行 `git config core.hooksPath .githooks` 激活。
- 提供 `scripts/install-hooks.sh` 与 `scripts/uninstall-hooks.sh`，安装输出必须明确告知：

```
[完成] 已将 hook 写入 .githooks/，并设置 core.hooksPath=.githooks。
[提示] 服务端 branch protection 是最后一道防线，建议在 GitHub/GitLab 侧同步开启。
```

- 安装操作幂等：检测已有 hook 时 append 而非覆盖。
- 明确**不引入 husky/Node.js**，保持跨语言项目通用。

---

## 九、包文件结构（D10）

```
git-pre-push/
├── SKILL.md                     # 主指令文件（给 AI 的规则）
├── hooks/
│   ├── pre-commit               # commit 前入口（source lib 后分发）
│   └── pre-push                 # push 前入口
├── scripts/
│   ├── install-hooks.sh
│   ├── uninstall-hooks.sh
│   ├── create-pr.sh             # 调 gh/glab 创建 PR
│   └── lib/
│       ├── detect-branch.sh     # 受保护分支判定、当前分支读取
│       ├── detect-spec.sh       # 分支 ↔ spec 双向匹配
│       ├── diff-size.sh         # 阈值核算（含白名单过滤）
│       ├── exemptions.sh        # 白名单与 Skip-SDD trailer 解析
│       └── conflict-check.sh    # 分支冲突三分法
└── templates/
    ├── spec.md                  # 迷你 spec 模板
    └── pr-description.md        # PR 描述模板
```

职责边界：
- `hooks/` 文件极短，只做入口分发，不写业务逻辑。
- `scripts/lib/` 暴露纯 shell 函数，被 hooks 和其它脚本共同 `source`。
- `scripts/*.sh` 是可独立执行的命令。
- `templates/` 不含任何逻辑，纯文本骨架。

---

## 十、跳过机制与审计（D12）

### 10.1 白名单（常态豁免）
位置：`.githooks/exemptions.yml`，随仓库版本化，团队可 review。

默认内容（包含基础设施与 spec 文件本身，避免自身维护被自身拦截）：
```yaml
paths:
  - "**/*.md"
  - "docs/**"
  - "specs/**"               # spec 文件本身的维护不走 SDD 流程
  - ".specs/**"
  - ".githooks/**"            # hook 基础设施；否则维护 hook 时会被自身拦截
  - ".gitignore"
  - "CHANGELOG.md"
  - "LICENSE"
  - "package.json"           # 仅 version 字段变更时豁免（需在 hook 内做字段粒度判断）
```

命中规则：`diff-size.sh` 在核算前先把命中白名单的路径从 diff 里剔除，剔除后仍超阈值才进入 spec 补写流程。

### 10.2 Commit Trailer（事件豁免）
用户在最近一次 commit message 末尾附加：

```
Skip-SDD: <中文理由>
```

Hook 识别到 trailer 后放行，不再检查 spec 存在性与累计规模。Trailer 随 commit 永久进入 git 历史，可通过 `git log --all --grep="Skip-SDD"` 审计。

### 10.3 优先级与禁令
Hook 拦截判定顺序：
1. 先过白名单 → 命中则放行
2. 再读最近 commit 的 `Skip-SDD:` trailer → 有则放行
3. 都没有才进入 §三 四象限标准流程

禁令：
- 严禁将 `--no-verify` 作为常规跳过方式，skill 文档与 `install-hooks` 输出都必须警示该用法。
- 严禁跳过机制让用户以为能绕过服务端 branch protection 与 CI。明文写入文档：**本地跳过仅关闭本地 hook，不影响远端治理链。**

---

## 十一、与其他技能的协同

- **git-commit-cn**：本技能在需要生成 commit message / PR 标题 / PR 描述时，必须调用 `git-commit-cn` 的规范（Conventional Commits + 中文描述），不自行实现格式规则。
- **Skip-SDD trailer 中的理由**：允许使用中文自由表达，但**不受** `git-commit-cn` 的 type 前缀约束，这是一个独立的 trailer 字段。

---

## 十二、关键输出格式

所有面向用户的提示统一使用三级前缀：

| 前缀 | 含义 | 场景 |
|---|---|---|
| `[通过]` | 检查通过 | commit/push 放行、PR 创建成功 |
| `[提示]` | 中性信息 | 显示推断结果、展示可选操作 |
| `[降级]` | 功能可用但降格 | Level 1 CLI 不可用/执行失败 → 改提供 compare URL |
| `[阻止]` | 硬拦截，必须处理 | 受保护分支、缺失 spec、分支分叉冲突 |

所有提示内容必须为中文；命令、路径、分支名、文件名保持英文原文。

---

## 十三、请生成的交付物

请基于以上规范生成完整的 skill 定义，包括：

1. `SKILL.md` 主指令文件（含 frontmatter 的 `name` 与 `description`）
2. `hooks/pre-commit`、`hooks/pre-push` 入口脚本
3. `scripts/` 下的安装、卸载、PR 创建脚本
4. `scripts/lib/` 下的各复用函数库
5. `templates/spec.md` 与 `templates/pr-description.md`
6. 关键交互场景的示例（四象限每一格至少一个对话/命令示例）

---

## 十四、参考实现索引

本目录 `reference/` 下附有一份已通过本地 bare repo + 真实 GitHub 远端冲烟测试的参考实现，是本 skill 的**唯一权威落地产物**。LLM 在生成新 skill 时，**默认路径是直接读取并复用下列参考文件**而非按上文自然语言规范重写，以保证不同 LLM 产出的 skill 在结构与行为上保持一致。

### 14.1 SKILL 入口
| 参考文件 | 对应规范条款 | 说明 |
|---|---|---|
| [reference/SKILL.md](reference/SKILL.md) | §七、§一 | 主指令文件，四象限决策树与三级降级规范的 AI 层落地 |

### 14.2 Hook 层实现（硬拦截）
| 参考文件 | 对应规范条款 | 说明 |
|---|---|---|
| [reference/hooks/pre-commit](reference/hooks/pre-commit) | §四、4.1~4.2 | commit 前入口；白名单短路 + 主分支拦截 + spec 范围一致性 |
| [reference/hooks/pre-push](reference/hooks/pre-push) | §五全节 | push 前入口；删除保护 + 受保护分支拦截 + Skip-SDD trailer + 累计 diff 三级 fallback |

### 14.3 scripts/lib 函数库（纯函数，被上层 source）
| 参考文件 | 对应规范条款 | 导出函数 / 职责 |
|---|---|---|
| [reference/scripts/lib/detect-branch.sh](reference/scripts/lib/detect-branch.sh) | §4.2 / §5.1 | `gpp_current_branch`、`gpp_is_protected_branch`、`gpp_default_branch` |
| [reference/scripts/lib/detect-spec.sh](reference/scripts/lib/detect-spec.sh) | §六、§4.2 | `gpp_branch_slug`、`gpp_find_spec_for_branch`、`gpp_diff_covered_by_spec` |
| [reference/scripts/lib/diff-size.sh](reference/scripts/lib/diff-size.sh) | §D5 / §5.2 | `gpp_diff_exceeds_threshold`、`gpp_diff_stats`、`gpp_staged_exceeds_threshold` |
| [reference/scripts/lib/exemptions.sh](reference/scripts/lib/exemptions.sh) | §10.1 / §10.2 | `gpp_path_exempted`、`gpp_all_staged_exempted`、`gpp_has_skip_trailer` |
| [reference/scripts/lib/conflict-check.sh](reference/scripts/lib/conflict-check.sh) | §4.4 / D6 | `gpp_conflict_status`：返回 `none/local-only/remote-only/in-sync/divergent` |

### 14.4 scripts 可执行命令
| 参考文件 | 对应规范条款 | 说明 |
|---|---|---|
| [reference/scripts/install-hooks.sh](reference/scripts/install-hooks.sh) | §八 | 幂等安装；写入 `.githooks/`、设 `core.hooksPath`、生成默认 exemptions/protected-branches |
| [reference/scripts/uninstall-hooks.sh](reference/scripts/uninstall-hooks.sh) | §八 | 清理 skill 写入的 hook 与 lib，保留团队配置文件 |
| [reference/scripts/create-pr.sh](reference/scripts/create-pr.sh) | §5.1 | 调 gh/glab 创建 PR；CLI 不可用或执行失败时输出平台对应的 compare/merge_requests 链接 |

### 14.5 templates 模板
| 参考文件 | 对应规范条款 | 说明 |
|---|---|---|
| [reference/templates/spec.md](reference/templates/spec.md) | §六 / D11 | 迷你 spec 三段模板，含 YAML front-matter |
| [reference/templates/pr-description.md](reference/templates/pr-description.md) | §5.1 / §十一 | PR 描述模板，与 `git-commit-cn` 协同填充 |

### 14.6 使用约束
- 参考实现已通过本地 bare repo + 真实 GitHub 远端的端到端验证，是本 skill 的**权威落地形态**。LLM 在生成新 skill 时，**必须优先直接复用 `reference/` 下的参考文件**（按原文件相对路径、文件名、可执行位原样拷贝），而不是按本 prompt 自由重写。
- 仅当**明确存在以下情形之一**时，才允许在参考实现基础上做改动：
  - 目标运行环境与参考实现不兼容（如 Git 版本、shell 解释器、OS 差异），需最小化适配；
  - 用户显式要求偏离某条规范（如调整受保护分支列表、阈值、白名单）；
  - 参考实现中发现的 bug，需同步修复。
  其它情形一律**以参考实现为准**，不要替换为 LLM 的等价改写。
- 复用时必须保持文件相对路径与文件名一致（包括 `hooks/`、`scripts/lib/`、`templates/` 子目录层级与 `.sh` 可执行位），避免打破 skill 内部的 source 与路径推算逻辑。
- 本 prompt 与参考实现之间的定位：**prompt 描述设计意图与验收标准，参考实现是唯一权威的落地产物**。如二者表述冲突，先读代码行为再回查 prompt 上下文，不要用 prompt 的自然语言片段覆盖已验证的实现。
- 参考 shell 脚本已考虑可移植性（POSIX 优先 + bash 补充，不依赖 Node.js/Python/husky），LLM 不得擅自改写为其它语言或运行时。
