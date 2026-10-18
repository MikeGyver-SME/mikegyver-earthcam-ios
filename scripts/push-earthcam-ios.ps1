<#
.SYNOPSIS
  Commit / push / tag helper for the mikegyver-earthcam-ios repo.

.DESCRIPTION
  Run from the repo root (the folder containing ios/, .github/).
  Commits everything, pushes to origin main, and optionally tags a version
  to trigger the TestFlight workflow.

.EXAMPLE
  .\scripts\push-earthcam-ios.ps1 -Message "EarthCam iOS v1.0.0" -Tag v1.0.0

.EXAMPLE
  .\scripts\push-earthcam-ios.ps1 -Message "tweak widget copy"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [string]$Tag = "",

    [string]$Remote = "origin",
    [string]$Branch = "main"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed with exit $LASTEXITCODE" }
}

# Sanity: must be run from the repo root.
if (-not (Test-Path ".\ios\project.yml")) {
    throw "Run this from the earthcam-ios repo root (ios\project.yml not found)."
}

Invoke-Git @("add", "-A")
Invoke-Git @("commit", "-m", $Message)
Invoke-Git @("push", $Remote, $Branch)

if ($Tag -ne "") {
    Invoke-Git @("tag", $Tag)
    Invoke-Git @("push", $Remote, $Tag)
    Write-Host "Tagged $Tag — the TestFlight workflow should start in GitHub Actions." -ForegroundColor Green
} else {
    Write-Host "Pushed without a tag (no build triggered). Add -Tag vX.Y.Z to build." -ForegroundColor Yellow
}
