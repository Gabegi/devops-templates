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


# Env variables
Structure: yes, infra/envs/dev.tfvars and infra/envs/prod.tfvars is fine. One thing to flag — the pipeline I gave you doesn't set a workingDirectory on the Terraform tasks, so it currently runs from the repo root, not infra/. You'll need to add workingDirectory: '$(System.DefaultWorkingDirectory)/infra' to each Terraform task, and then tfvarsFile: 'envs/dev.tfvars'

Standard pattern: keep tfvars in git for non-sensitive values, put real secrets in Azure Key Vault, then either link them into an Azure DevOps variable group (Library > Variable group > "link secrets from Key Vault") and reference as pipeline variables, or pull them directly in Terraform via an azurerm_key_vault_secret data source. Either way, nothing sensitive touches a .tfvars file.

# ado environments
  Job terraform_apply: Environment dev could not be found. The environment does not exist or has not been authorized for use.

This can't be fixed in the YAML — the dev and prod environments must be created manually in the ADO UI. Here's exactly what to do:

1. Go to Pipelines > Environments in Azure DevOps
2. Click New environment
3. Name it dev, type None, click Create
4. Repeat for prod

For the prod approval gate (so Apply pauses for sign-off before deploying to prod):

5. Open the prod environment
6. Click the ... menu > Approvals and checks
7. Add an Approvals check and set the approvers

Once both environments exist the pipeline will pick them up automatically — no YAML change needed

# merge conflics ADO
Azure DevOps doesn't have a built-in web conflict editor by default. 
Web-based — install the free "Pull Request Merge Conflict Extension" from the Marketplace (an org admin adds it once); it adds a "Resolve conflicts" tab directly on the PR page.

Top-right of any Azure DevOps page — select the shopping bag icon, then select Browse Marketplace. From there, search for an extension and click "Get it free" to install it into your org. Microsoft Learn

Go to the shopping bag icon → Browse Marketplace → search for it (or go straight to marketplace.visualstudio.com/items?itemName=ms-devlabs.conflicts-tab) → Get it free → pick [yourorganisation] from the org dropdown → Install. No file download, no VSIXInstaller needed.

# merge conflics in github desktop
For conflicts: merge the target branch into yours (Branch menu → Merge into current branch). GitHub Desktop lists the conflicted files — click one to open it in your configured external editor, resolve the markers, mark it resolved, then commit and push, same as the general local-resolve flow.