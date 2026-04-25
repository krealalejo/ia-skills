---
name: code-review
description: >
  Performs a comprehensive code review of the current branch against main.
  Trigger: /review [task_description] or "review this branch", "check my code".
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- Before creating a pull request to ensure code quality.
- To check if implementation aligns with best practices and SOLID principles.
- To identify TypeScript errors, readability issues, or poor naming conventions.

## Critical Patterns

- **Comparison Base**: Always diff against the `main` branch.
- **Review Scope**:
  - **TypeScript**: Check for `any` types, missing interfaces, or type mismatches.
  - **Best Practices**: Ensure efficient logic, proper error handling, and performance considerations.
  - **Readability**: Code should be easy to follow.
  - **Naming**: Variables, functions, and classes must have clear, descriptive names.
  - **Clean Code**: Dry (Don't Repeat Yourself), Kiss (Keep It Simple, Stupid).
  - **SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion.
- **Output Format**:
  - Add comments **immediately above** the problematic line.
  - Each comment must include:
    - **Affected Lines**: (e.g., `Lines: 12-14`)
    - **Problem**: Concise description of what's wrong.
    - **Suggestion**: Actionable advice to fix or improve the code.
- **Language**: Always perform the review and write comments in **English**.

## Workflow

1.  **Diff Analysis**: Run `git diff main...HEAD` (or equivalent) to identify changed files and lines.
2.  **Implementation Check**: If a task description is provided, verify that the implementation meets the requirements.
3.  **Heuristic Review**: Apply the criteria listed in "Critical Patterns".
4.  **Comment Placement**: Insert review comments as block comments (e.g., `/** ... */` for TS/JS) directly in the file above the target line.

## Code Examples

### Review Comment Style

```typescript
/**
 * Affected Lines: 45
 * Problem: Use of 'any' type bypasses TypeScript's safety.
 * Suggestion: Define an interface for the user object instead of using 'any'.
 */
const processUser = (user: any) => { ... }
```

## Commands

```bash
# General review
/review

# Review with task context
/review "Implemented JWT authentication and user session management"
```
