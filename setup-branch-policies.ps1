$ErrorActionPreference = "Stop"

# ---------------- CONFIG: fill these in ----------------
$ORG     = "https://dev.azure.com/"
$PROJECT = ""
$REPO    = ""
# Build validation skipped for now - no pipeline yet. Run add-build-validation.ps1 later once you have one.
# ---------------------------------------------------------
 
az devops configure --defaults organization=$ORG project=$PROJECT
$REPO_ID = az repos show --repository $REPO --query id -o tsv
Write-Host "Repo ID: $REPO_ID"

# Set production as the default branch
az repos update --repository $REPO --default-branch production
Write-Host "Default branch set to: production"

Write-Host "== PRODUCTION =="
 
# Minimum 1 reviewer; creator's own vote doesn't count; votes reset on new push
az repos policy approver-count create `
  --repository-id $REPO_ID --branch production `
  --minimum-approver-count 1 --creator-vote-counts false `
  --allow-downvotes false --reset-on-source-push true `
  --blocking true --enabled true
 
# All PR comments must be resolved before completion
az repos policy comment-required create `
  --repository-id $REPO_ID --branch production `
  --blocking true --enabled true
 
# Merge type restricted to No-fast-forward only (preserves development's full commit history)
az repos policy merge-strategy create `
  --repository-id $REPO_ID --branch production `
  --allow-no-fast-forward true `
  --allow-squash false --allow-rebase false --allow-rebase-merge false `
  --blocking true --enabled true
 
Write-Host "== DEVELOPMENT =="
 
# Merge type restricted to Squash only (condenses each feature branch into one commit)
az repos policy merge-strategy create `
  --repository-id $REPO_ID --branch development `
  --allow-squash true `
  --allow-no-fast-forward false --allow-rebase false --allow-rebase-merge false `
  --blocking true --enabled true
 
Write-Host "== LOCKING BRANCHES =="
# Explicitly lock both branches at the ref level so direct pushes are rejected even for admins
foreach ($branch in @("production", "development")) {
    $sha = az repos ref list --repository $REPO_ID --filter "heads/$branch" --query "[0].objectId" -o tsv
    az rest --method POST `
        --uri "${ORG}${PROJECT}/_apis/git/repositories/${REPO_ID}/refs?api-version=7.1" `
        --body "[{`"name`":`"refs/heads/$branch`",`"oldObjectId`":`"$sha`",`"newObjectId`":`"$sha`",`"isLocked`":true}]" | Out-Null
    Write-Host "Locked: $branch"
}

Write-Host "Done. production is the default branch. production and development are locked and require PRs."
Write-Host "Build validation NOT set yet - run add-build-validation.ps1 once you have a CI pipeline."
Write-Host "Reminder: enforce 'feature/' naming via a script step in your CI pipeline."