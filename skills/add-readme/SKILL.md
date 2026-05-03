---
name: add-readme
description: >
  Creates or updates a README.md file following the KRA project structure.
  Trigger: /add-readme, "create a readme", "generate readme", "actualizar readme".
license: Apache-2.0
metadata:
  author: krealalejo∫
  version: "1.0"
---

## When to Use

- When an existing project needs its README updated to match the standard.
- When a project is missing critical information like stack, commands, or architecture.

## Critical Patterns

The README MUST follow this exact structure and style:

1.  **Title**: `# {project-name}`
2.  **Description**: A concise paragraph explaining the project's purpose.
3.  **Stack**: A bolded line starting with `**Stack:**` followed by the main technologies (e.g., `**Stack:** Nuxt **4**, Vue **3**, Tailwind CSS`).
4.  **Separator**: Use `---` between sections.
5.  **Prerequisites**: List Node/Java versions and essential tools.
6.  **Quick Start**: Numbered steps to get the project running.
7.  **Commands**: A table with columns `Action` and `Command`.
8.  **Pages/Endpoints**:
    - For Web: Table with `Path`, `Description`, `Access`.
    - For API: Table with `Method`, `Path`, `Description`, `Auth`.
9.  **Architecture**: A Mermaid diagram showing the components and their interactions, followed by a brief text explanation of the structure.
10. **Source layout**: A markdown code block with the folder structure.
11. **Configuration**: A table with `Variable` and `Purpose` for environment variables.
12. **Deployment**: A paragraph describing how the project is deployed (usually Terraform + GitHub Actions).

## Code Examples

### Stack Format
```markdown
**Stack:** Spring Boot **3.5**, Java **25**, **DDD**-style layering, AWS SDK **v2**.
```

### Table Format
```markdown
| Action | Command |
|--------|---------|
| Run dev | `yarn dev` |
| Test | `yarn test` |
```

## Commands

```bash
/add-readme [context]
```

## Resources

- **Templates**: See [assets/template.md](assets/template.md) for the base structure.
