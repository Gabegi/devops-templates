$ErrorActionPreference = "Stop"

# ---------------- CONFIG ----------------
$PROJECT = "<your-project>"
$REPO    = "<your-repo>"
$PROD_BUILD_DEF_ID = <id>   # az pipelines list -o table
$DEV_BUILD_DEF_ID  = <id>   # can be the same id if you reuse one pipeline
# -----------------------------------------

$REPO_ID = az repos show --project $PROJECT --repository $REPO --query id -o tsv

az repos policy build create `
  --repository-id $REPO_ID --branch production `
  --build-definition-id $PROD_BUILD_DEF_ID `
  --display-name "CI - production" --blocking true --enabled true `
  --queue-on-source-update-only false --manual-queue-only false --valid-duration 0

az repos policy build create `
  --repository-id $REPO_ID --branch development `
  --build-definition-id $DEV_BUILD_DEF_ID `
  --display-name "CI - development" --blocking true --enabled true `
  --queue-on-source-update-only false --manual-queue-only false --valid-duration 0

Write-Host "Build validation added to production and development."
