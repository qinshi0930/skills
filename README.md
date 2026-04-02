# Agent Skills

## About

This is my personal skills toolbox repository for agent workflows.

## Sources

Upstream sources for these skills:

- https://github.com/mattpocock/skills
- https://github.com/obra/superpowers/tree/main/skills
- Skills not found in the two sources are labeled as https://skills.sh/.

## Skill Catalog

Catalog organized by category:

### Planning & Design

- write-a-prd - Create a PRD through user interview, codebase exploration, and module design, then submit it as a GitHub issue. (source: https://github.com/mattpocock/skills)
- prd-to-plan - Turn a PRD into a multi-phase implementation plan using tracer-bullet vertical slices, saved as a local Markdown file in ./plans/. (source: https://github.com/mattpocock/skills)
- prd-to-issues - Break a PRD into independently grabbable GitHub issues using tracer-bullet vertical slices. (source: https://github.com/mattpocock/skills)
- grill-me - Interview the user relentlessly about a plan or design until every branch is resolved. (source: https://github.com/mattpocock/skills)
- design-an-interface - Generate multiple radically different interface designs for a module using parallel subagents. (source: https://github.com/mattpocock/skills)
- request-refactor-plan - Create a detailed refactor plan with tiny commits via user interview, then file it as a GitHub issue. (source: https://github.com/mattpocock/skills)
- brainstorming - Use before any creative work to explore user intent, requirements, and design. (source: https://github.com/obra/superpowers/tree/main/skills)

### Development & Testing

- tdd - Test-driven development with red-green-refactor loop. (source: https://github.com/mattpocock/skills)
- test-driven-development - Use when implementing any feature or bugfix, before writing implementation code. (source: https://github.com/obra/superpowers/tree/main/skills)
- improve-codebase-architecture - Explore a codebase for architectural improvement, focusing on deeper modules and testability. (source: https://github.com/mattpocock/skills)
- migrate-to-shoehorn - Migrate test files from `as` type assertions to `@total-typescript/shoehorn`. (source: https://github.com/mattpocock/skills)
- scaffold-exercises - Create exercise directory structures with sections, problems, solutions, and explainers that pass linting. (source: https://github.com/mattpocock/skills)

### Debugging & QA

- systematic-debugging - Use when encountering a bug, test failure, or unexpected behavior, before proposing fixes. (source: https://github.com/obra/superpowers/tree/main/skills)
- triage-issue - Triage a bug by exploring the codebase and create a GitHub issue with a TDD-based fix plan. (source: https://github.com/mattpocock/skills)
- qa - Interactive QA session where issues are reported conversationally and filed as GitHub issues with context. (source: https://github.com/mattpocock/skills)

### Execution & Workflow

- executing-plans - Use when you have a written implementation plan to execute in a separate session with review checkpoints. (source: https://github.com/obra/superpowers/tree/main/skills)
- subagent-driven-development - Use when executing implementation plans with independent tasks in the current session. (source: https://github.com/obra/superpowers/tree/main/skills)
- dispatching-parallel-agents - Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies. (source: https://github.com/obra/superpowers/tree/main/skills)
- using-git-worktrees - Use when starting feature work that needs isolation from the current workspace or before executing implementation plans. (source: https://github.com/obra/superpowers/tree/main/skills)
- finishing-a-development-branch - Use when implementation is complete, tests pass, and you need to decide how to integrate the work. (source: https://github.com/obra/superpowers/tree/main/skills)

### Review & Verification

- requesting-code-review - Use when completing tasks, implementing major features, or before merging. (source: https://github.com/obra/superpowers/tree/main/skills)
- receiving-code-review - Use when receiving code review feedback before implementing suggestions. (source: https://github.com/obra/superpowers/tree/main/skills)
- verification-before-completion - Use when about to claim work is complete, fixed, or passing, before committing or creating PRs. (source: https://github.com/obra/superpowers/tree/main/skills)

### Tooling & Git

- setup-pre-commit - Set up Husky pre-commit hooks with lint-staged (Prettier), type checking, and tests in the current repo. (source: https://github.com/mattpocock/skills)
- git-guardrails-claude-code - Set up Claude Code hooks to block dangerous git commands before they execute. (source: https://github.com/mattpocock/skills)

### Writing & Knowledge

- write-a-skill - Create new agent skills with proper structure, progressive disclosure, and bundled resources. (source: https://github.com/mattpocock/skills)
- edit-article - Edit and improve articles by restructuring sections, improving clarity, and tightening prose. (source: https://github.com/mattpocock/skills)
- ubiquitous-language - Extract a DDD-style ubiquitous language glossary, flag ambiguities, and save to UBIQUITOUS_LANGUAGE.md. (source: https://github.com/mattpocock/skills)
- obsidian-vault - Search, create, and manage notes in the Obsidian vault with wikilinks and index notes. (source: https://github.com/mattpocock/skills)

### Skill Ops

- using-superpowers - Use when starting any conversation, establishing how to find and use skills before any response. (source: https://github.com/obra/superpowers/tree/main/skills)
- writing-plans - Use when you have a spec or requirements for a multi-step task, before touching code. (source: https://github.com/obra/superpowers/tree/main/skills)
- writing-skills - Use when creating new skills, editing existing skills, or verifying skills work before deployment. (source: https://github.com/obra/superpowers/tree/main/skills)
- find-skills - Help users discover and install agent skills for specific tasks. (source: https://skills.sh/)
