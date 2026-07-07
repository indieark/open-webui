param(
    [switch]$SkipVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $PSCommandPath
$repoRoot = Split-Path -Parent $scriptDir

function Invoke-NativeStep {
    param(
        [string]$Label,
        [scriptblock]$Script
    )

    Write-Host $Label
    & $Script
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: $Label"
    }
}

Push-Location $repoRoot
try {
    $status = git status --porcelain
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: git status --porcelain"
    }
    if ($status) {
        throw "Working tree is dirty. Commit or stash current changes before syncing upstream."
    }

    git remote get-url upstream-open-webui *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Missing remote: upstream-open-webui. Run: git remote add upstream-open-webui https://github.com/open-webui/open-webui.git"
    }

    Invoke-NativeStep "git fetch upstream-open-webui main --no-tags" {
        git fetch upstream-open-webui main --no-tags
    }

    $subtreeLog = git log --grep="git-subtree-dir: upstream/open-webui" --format=%B -n 1
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: git log subtree metadata"
    }

    $latestSplitLine = $subtreeLog | Where-Object { $_ -match "^git-subtree-split: " } | Select-Object -Last 1
    if (-not $latestSplitLine) {
        throw "Cannot find git-subtree-split for upstream/open-webui."
    }

    $latestSplit = $latestSplitLine -replace "^git-subtree-split: ", ""
    $remoteHead = git rev-parse upstream-open-webui/main
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed: git rev-parse upstream-open-webui/main"
    }

    if ($latestSplit -eq $remoteHead) {
        Write-Host "No upstream delta: open-webui/open-webui@$remoteHead"
        exit 0
    }

    Write-Host "Upstream delta detected:"
    Invoke-NativeStep "git log --oneline $latestSplit..$remoteHead" {
        git log --oneline "$latestSplit..$remoteHead"
    }

    Invoke-NativeStep "git subtree pull --prefix=upstream/open-webui upstream-open-webui main --squash" {
        git subtree pull --prefix=upstream/open-webui upstream-open-webui main --squash
    }

    if (-not $SkipVerify) {
        Invoke-NativeStep "bash scripts/verify-compat.sh" {
            bash scripts/verify-compat.sh
        }
    }

    Write-Host "Upstream sync completed. Review git status before committing."
}
finally {
    Pop-Location
}
