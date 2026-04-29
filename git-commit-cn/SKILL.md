---
name: git-commit-cn
description: 生成符合 Conventional Commits 规范的中文 Git 提交信息、Issue 标题与描述、PR 标题与描述。type 前缀必须为英文,描述内容必须为中文。Use when writing git commit messages, creating GitHub/GitLab issues, writing PR descriptions, or when the user mentions commit, issue, PR, or changelog.
---

# Git 中文提交规范

## 核心规则

所有 Git 相关描述信息必须遵循以下格式:

```
<type>(<scope>): <中文简要描述>
```

### Type 类型(必须为英文)

| Type | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat(auth): 新增用户登录功能` |
| `fix` | 修复 Bug | `fix(api): 修复获取用户信息接口的异常` |
| `docs` | 文档更新 | `docs: 更新 README 安装说明` |
| `style` | 代码格式调整 | `style: 统一代码缩进格式` |
| `refactor` | 代码重构 | `refactor(user): 重构用户模块代码结构` |
| `test` | 测试相关 | `test(auth): 添加登录功能单元测试` |
| `chore` | 构建或辅助工具变动 | `chore: 更新依赖版本` |
| `perf` | 性能优化 | `perf(query): 优化数据库查询性能` |
| `build` | 构建系统变更 | `build: 升级 webpack 配置` |
| `ci` | CI/CD 配置变更 | `ci: 添加自动化测试工作流` |
| `revert` | 回滚提交 | `revert: 回滚错误的样式修改` |

### Scope 模块标识(可选)

- 使用英文标识模块,如: `auth`, `api`, `ui`, `user`, `query`
- 如果变更涉及多个模块或不明确,可省略 scope

### 描述内容(必须为中文)

- 冒号后紧跟一个空格,然后是中文描述
- 简要说明变更内容,不超过 50 字符
- 语气专业、简洁,避免冗长

## 详细描述(Body)要求

如果提交较复杂,添加详细描述:

- **必须使用中文**编写
- 使用结构化表达(分点说明)
- 解释**为什么**做这个变更(而非**如何做**)
- 不允许出现整段英文(除非是代码、命令或专有名词)

示例:

```
feat(guestbook): 新增留言簿功能模块

- 实现留言的增删改查 API
- 集成 Supabase 数据库存储
- 添加前端表单验证与提交反馈
- 支持用户登录状态检测

Closes #123
```

## 智能推断规则

当用户提供不符合规范的输入时,自动转换:

| 用户输入关键词 | 推断 Type |
|----------------|-----------|
| 新增/添加/实现/add/implement | `feat` |
| 修复/bug/错误/fix | `fix` |
| 优化/提升性能/optimize/perf | `perf` |
| 重构/refactor | `refactor` |
| 文档/doc/readme | `docs` |
| 测试/test | `test` |
| 其他不明确情况 | `chore` |

## 自动修正机制

遇到不符合规范的输入时:

1. **英文描述** → 自动翻译为中文
2. **缺少 type** → 根据语义自动推断
3. **中文 type** → 转换为对应英文(如"修复" → `fix`)
4. **格式错误** → 自动重写为标准格式

### 转换示例

**输入:** `fix login bug`

**输出:**
```
fix(auth): 修复登录功能中的异常问题

修复用户登录时 token 验证失败的错误
```

**输入:** `新增支付功能`

**输出:**
```
feat(payment): 新增支付功能

集成支付宝和微信支付接口
```

**输入:** `update readme`

**输出:**
```
docs: 更新项目说明文档内容

补充安装步骤和环境变量配置说明
```

## 禁止行为

- ❌ 使用中文作为 type(如"新增"、"修复")
- ❌ 标题全英文
- ❌ 中英文混杂(除非必要术语)
- ❌ 描述过于冗长或含糊

## Issue 和 PR 描述规范

### Issue 标题

```
<type>(<scope>): <中文问题描述>
```

示例:
- `fix(auth): 登录页面在移动端样式错乱`
- `feat(api): 需要支持批量删除功能`

### Issue 描述

- 使用中文描述问题背景、复现步骤、预期行为
- 附上相关截图或日志(如有)
- 标注优先级和标签

### PR 标题

与 commit message 格式一致,关联相关 Issue:

```
feat(guestbook): 新增留言簿功能模块

Closes #123, #456
```

### PR 描述

```markdown
## 变更摘要

简要说明此 PR 的变更内容

## 变更类型

- [ ] feat: 新功能
- [ ] fix: Bug 修复
- [ ] docs: 文档更新
- [ ] refactor: 重构
- [ ] test: 测试相关
- [ ] chore: 构建/工具变更

## 相关 Issue

Closes #123

## 测试说明

描述如何测试这些变更
```

## Changelog 生成

生成更新日志时使用中文:

```markdown
## [1.2.0] - 2026-04-20

### 新增
- 用户登录与认证功能
- 留言簿模块

### 修复
- 修复移动端样式兼容性问题
- 修复数据库连接池泄漏

### 优化
- 提升首页加载性能 40%
```

## 辅助脚本

使用脚本验证和格式化提交信息:

```bash
# 验证提交信息格式
bash ~/.qoder/skills/git-commit-cn/scripts/validate-commit.sh "feat(auth): 新增登录功能"

# 自动转换英文为中文格式
bash ~/.qoder/skills/git-commit-cn/scripts/format-commit.sh "fix login bug"
```

> 运行环境提示：两个脚本依赖 GNU grep 的 `-P`（PCRE）选项。Linux 默认可用；macOS 默认的 BSD grep 不支持，请先 `brew install grep`，并以 `ggrep` 调用（或将 `/usr/local/opt/grep/libexec/gnubin` 加入 PATH）。

## 工作流程

### 生成 Commit Message

1. 分析 `git diff` 或用户描述的变更
2. 推断合适的 type 和 scope
3. 生成中文标题和详细描述
4. 验证格式符合规范

### 创建 Issue

1. 确认问题类型和影响范围
2. 生成标准标题
3. 编写中文描述(背景、复现步骤、预期行为)
4. 建议标签和优先级

### 编写 PR 描述

1. 汇总所有 commit message
2. 生成变更摘要
3. 关联相关 Issue
4. 提供测试说明

## 注意事项

- 优先保证语义清晰,而非逐字翻译
- 保持简洁,避免冗长废话
- 代码、命令、专有名词可保留英文
- 统一团队提交风格,提高可读性
