# devops-templates
ci/cd pipelines templates and git best practices

# A common and clean layout for repositories:

/
├── infra/          # Terraform
├── src/            # .NET application code
└── .pipelines/     # CI/CD pipeline definitions

The dot prefix on .pipelines/ is optional — use pipelines/ if you prefer it visible and prominent. Some teams also name it .github/workflows/ or deploy/ depending on the platform (GitHub Actions, Azure DevOps, etc.).

A few quick tradeoffs:
- infra/ vs terraform/ — infra/ is slightly more future-proof if you ever add non-Terraform infra (Bicep, scripts, etc.)
- src/ vs the project name — src/ is idiomatic for .NET monorepos; if it's a single service you could put the .sln at the root instead
- .pipelines/ — Azure DevOps convention; swap for .github/workflows/ if using GitHub Actions