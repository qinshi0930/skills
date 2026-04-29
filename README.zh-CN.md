# 代理技能

## 关于

这是我自用的 skills 工具仓库，用于日常的 agent 工作流。

## 技能目录

### Git 与提交工具

- git-commit-cn - 生成符合 Conventional Commits 规范的中文 Git 提交信息。type 前缀必须为英文，描述内容必须为中文。(source: custom)
- git-pre-push - 守护 PR 工作流全链路。在 commit 前拦截主分支直推并引导切换 feature 分支，在 push 前按三级降级自动创建 PR，对超阈值改动强制要求 SDD 迷你 spec。(source: custom)
