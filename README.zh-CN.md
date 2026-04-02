# 代理技能

## 关于

这是我自用的 skills 工具仓库，用于日常的 agent 工作流。

## 来源

- https://github.com/mattpocock/skills
- https://github.com/obra/superpowers/tree/main/skills
- 未在上述两个来源中找到的 skill 统一标注为 https://skills.sh/。

## 技能目录

### 规划与设计

- write-a-prd - 通过用户访谈、代码库探索和模块设计创建 PRD，并提交为 GitHub issue (source: https://github.com/mattpocock/skills)
- prd-to-plan - 将 PRD 转换为多阶段实现计划，采用 tracer-bullet 垂直切片，并保存为 ./plans/ 下的本地 Markdown 文件 (source: https://github.com/mattpocock/skills)
- prd-to-issues - 将 PRD 拆分为可独立领取的 GitHub issues，采用 tracer-bullet 垂直切片 (source: https://github.com/mattpocock/skills)
- grill-me - 对方案或设计进行高强度追问，直到所有决策分支闭合 (source: https://github.com/mattpocock/skills)
- design-an-interface - 使用并行子代理为模块生成多种差异化接口设计方案 (source: https://github.com/mattpocock/skills)
- request-refactor-plan - 通过用户访谈生成细粒度重构计划，并提交为 GitHub issue (source: https://github.com/mattpocock/skills)
- brainstorming - 在任何创意或功能实现前进行头脑风暴，探索意图、需求与设计 (source: https://github.com/obra/superpowers/tree/main/skills)

### 开发与测试

- tdd - 采用 red-green-refactor 的测试驱动开发流程 (source: https://github.com/mattpocock/skills)
- test-driven-development - 在实现任何功能或修复前先写测试 (source: https://github.com/obra/superpowers/tree/main/skills)
- improve-codebase-architecture - 探索架构改进点，聚焦更深的模块边界和可测试性 (source: https://github.com/mattpocock/skills)
- migrate-to-shoehorn - 将测试中的 `as` 类型断言迁移到 @total-typescript/shoehorn (source: https://github.com/mattpocock/skills)
- scaffold-exercises - 创建包含章节、题目、解答与讲解且能通过 lint 的练习目录结构 (source: https://github.com/mattpocock/skills)

### 调试与 QA

- systematic-debugging - 在遇到 bug、测试失败或异常行为时采用系统化调试流程 (source: https://github.com/obra/superpowers/tree/main/skills)
- triage-issue - 通过探索代码库定位问题根因，并提交带 TDD 修复计划的 GitHub issue (source: https://github.com/mattpocock/skills)
- qa - 以交互式 QA 方式收集问题并提交 GitHub issues，同时补充上下文信息 (source: https://github.com/mattpocock/skills)

### 执行与流程

- executing-plans - 在独立会话中执行已写好的实现计划，并设置审查检查点 (source: https://github.com/obra/superpowers/tree/main/skills)
- subagent-driven-development - 在当前会话中使用子代理执行独立任务的实现计划 (source: https://github.com/obra/superpowers/tree/main/skills)
- dispatching-parallel-agents - 在没有共享状态的前提下并行处理多个独立任务 (source: https://github.com/obra/superpowers/tree/main/skills)
- using-git-worktrees - 在开始特性开发或执行计划前创建隔离的 git worktree (source: https://github.com/obra/superpowers/tree/main/skills)
- finishing-a-development-branch - 当实现完成且测试通过后，决定如何整合分支 (source: https://github.com/obra/superpowers/tree/main/skills)

### 评审与验证

- requesting-code-review - 在完成任务、实现重要功能或合并前请求代码评审 (source: https://github.com/obra/superpowers/tree/main/skills)
- receiving-code-review - 在采纳代码评审反馈前进行技术验证与审慎处理 (source: https://github.com/obra/superpowers/tree/main/skills)
- verification-before-completion - 在宣称完成、修复或通过之前进行验证，再提交或创建 PR (source: https://github.com/obra/superpowers/tree/main/skills)

### 工具与 Git

- setup-pre-commit - 配置 Husky 预提交钩子、lint-staged、Prettier、类型检查与测试 (source: https://github.com/mattpocock/skills)
- git-guardrails-claude-code - 配置 Claude Code 钩子以阻止危险的 git 命令执行 (source: https://github.com/mattpocock/skills)

### 写作与知识

- write-a-skill - 创建结构完善、渐进式引导且资源齐全的技能包 (source: https://github.com/mattpocock/skills)
- edit-article - 通过重组章节、提升清晰度与收紧表述来改进文章 (source: https://github.com/mattpocock/skills)
- ubiquitous-language - 提取 DDD 统一语言词汇表、标记歧义，并保存到 UBIQUITOUS_LANGUAGE.md (source: https://github.com/mattpocock/skills)
- obsidian-vault - 在 Obsidian 笔记库中搜索、创建与管理笔记，包含 wikilinks 和索引 (source: https://github.com/mattpocock/skills)

### 技能运营

- using-superpowers - 在任何对话开始时使用，用于建立技能使用规范并要求先调用技能 (source: https://github.com/obra/superpowers/tree/main/skills)
- writing-plans - 在编码前基于规格说明或需求编写多步骤实现计划 (source: https://github.com/obra/superpowers/tree/main/skills)
- writing-skills - 用于创建新技能、编辑技能或验证技能是否可用 (source: https://github.com/obra/superpowers/tree/main/skills)
- find-skills - 帮助用户发现并安装适配具体需求的 agent 技能 (source: https://skills.sh/)
