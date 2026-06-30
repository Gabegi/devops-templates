$ErrorActionPreference = "Stop"

# ---------------- CONFIG: fill these in ----------------
$ORG          = "https://dev.azure.com/<your-org>"   # no trailing slash
$PROJECT      = "<your-project>"
$APPROVER_ID  = ""   # optional: az devops user show --user <email> --query id -o tsv
# ---------------------------------------------------------

az devops configure --defaults organization=$ORG project=$PROJECT

# 1. Create the production environment
$envBody = @{ name = "production"; description = "Production deployment environment" } | ConvertTo-Json
$env = az rest --method POST `
    --uri "${ORG}/${PROJECT}/_apis/distributedtask/environments?api-version=7.1-preview.1" `
    --body $envBody --headers "Content-Type=application/json" | ConvertFrom-Json
$ENV_ID = [string]$env.id
Write-Host "Environment created: production (id=$ENV_ID)"

# 2. Branch Control check — only pipelines running on development can use this environment
$branchControlBody = @{
    type     = @{ id = "fe1de3ee-a436-41b4-bb20-f6eb4cb879a7"; name = "Task Check" }
    settings = @{
        displayName  = "Branch Control"
        definitionRef = @{
            id      = "9159b3d5-fc18-4625-a0bd-bb1f4e1f6a45"
            name    = "Gate.BranchControl"
            version = "0.0.1"
        }
        inputs = @{
            allowedBranches          = "refs/heads/development"
            ensureProtectionOfBranch = "true"
            allowUnknownStatusBranch = "false"
        }
        retryOnError = $false
    }
    resource = @{ type = "environment"; id = $ENV_ID }
    timeout  = 43200
} | ConvertTo-Json -Depth 10

az rest --method POST `
    --uri "${ORG}/${PROJECT}/_apis/pipelines/checks/configurations?api-version=7.1-preview.1" `
    --body $branchControlBody --headers "Content-Type=application/json" | Out-Null
Write-Host "Check added: Branch Control (only development branch can deploy to production)"

# 3. Approval check — requires a human sign-off before every production deployment
#    Set APPROVER_ID above to enable; skip for now if you don't have a user ID yet
if ($APPROVER_ID) {
    $approvalBody = @{
        type     = @{ id = "8c6f20a7-a545-4486-9777-f762fafe0d4d"; name = "Approval" }
        settings = @{
            approvers                = @(@{ id = $APPROVER_ID })
            instructions             = "Approve production deployment"
            minRequiredApprovers     = 1
            requesterCannotBeApprover = $true
        }
        resource = @{ type = "environment"; id = $ENV_ID }
        timeout  = 43200
    } | ConvertTo-Json -Depth 10

    az rest --method POST `
        --uri "${ORG}/${PROJECT}/_apis/pipelines/checks/configurations?api-version=7.1-preview.1" `
        --body $approvalBody --headers "Content-Type=application/json" | Out-Null
    Write-Host "Check added: Approval (approver=$APPROVER_ID, requester cannot self-approve)"
} else {
    Write-Host "APPROVER_ID not set — skipping Approval check. Fill it in and re-run to add."
}

Write-Host "Done. production environment requires: (1) pipeline from development branch, (2) manual approval if configured."
