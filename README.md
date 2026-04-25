# 🧠 AI Skills Repository

A curated collection of custom AI skills designed to enhance software engineering workflows, automation, and development best practices.

## 🚀 Included Skills

### 🛠️ git-commit
**Purpose**: Automates the creation of atomic commits following the [Conventional Commits](https://www.conventionalcommits.org/) standard.

**Key Features**:
- **Atomic Commits**: Automatically groups changes logically by module or functionality.
- **Ticket Support**: Integrates ticket IDs (e.g., Jira, GitHub Issues) into the commit scope.
- **Character Limit**: Ensures concise messages (max 300 characters).

### 🔍 code-review
**Purpose**: Performs a comprehensive code review of the current branch against `main`, focusing on TypeScript, best practices, and SOLID principles.

**Key Features**:
- **Automatic Diff**: Compares implementation with the `main` branch.
- **In-Line Suggestions**: Adds comments directly above the code with problem descriptions and corrections.
- **Clean Code & SOLID**: Enforces high-quality architectural standards.

## 📦 Dependencies

This repository depends on the following tools:

- **[RTK (AI Agent Tooling)](https://github.com/rtk-ai/rtk)**: The underlying framework used by the skills to interact with the environment (git, filesystem, etc.).

## 🛠️ How to Use This Repository

This repository is designed to be cloned or referenced by AI agents compatible with the **Antigravity Skills** system.

1. **Installation**: Copy the desired skill folder into your local skills directory.
2. **Configuration**: Ensure the agent has the necessary permissions to execute the commands defined in the `SKILL.md` file.

---
*Developed with ❤️ by krealalejo*
