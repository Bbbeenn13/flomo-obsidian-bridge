[CmdletBinding()]
param(
    [datetime]$Date = (Get-Date),
    [string]$VaultPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'vault'),
    [string]$ConfigPath,
    [string]$VaultBranch = 'codex/flomo-review-staging',
    [switch]$DryRun,
    [switch]$NoPush
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$runDailyScript = Join-Path $PSScriptRoot 'run-daily.ps1'
if (-not (Test-Path -LiteralPath $runDailyScript -PathType Leaf)) {
    throw "Daily runner not found: $runDailyScript"
}

$VaultPath = [IO.Path]::GetFullPath($VaultPath)
if (-not (Test-Path -LiteralPath (Join-Path $VaultPath '.git') -PathType Container)) {
    throw "Vault checkout is not a Git repository: $VaultPath"
}

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $gitCommand) {
    throw 'Git is not available on PATH.'
}

if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $sourceConfigPath = Join-Path $projectRoot 'bridge.config.json'
} else {
    $sourceConfigPath = [IO.Path]::GetFullPath($ConfigPath)
}
if (-not (Test-Path -LiteralPath $sourceConfigPath -PathType Leaf)) {
    throw "Bridge config not found: $sourceConfigPath"
}

$runDir = Join-Path $projectRoot '.runs'
[IO.Directory]::CreateDirectory($runDir) | Out-Null
$dateText = $Date.Date.ToString('yyyy-MM-dd')
$ciConfigPath = Join-Path $runDir "bridge.github-$dateText-$PID.json"
$config = Get-Content -Raw -Encoding UTF8 -LiteralPath $sourceConfigPath | ConvertFrom-Json
$config.vaultPath = $VaultPath
[IO.File]::WriteAllText($ciConfigPath, ($config | ConvertTo-Json -Depth 10), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "GitHub daily review run: $dateText"
Write-Host "Vault checkout: $VaultPath"

if ($DryRun) {
    & $runDailyScript -Date $dateText -ConfigPath $ciConfigPath -DryRun
    Write-Host 'Skipping Vault commit and push because -DryRun was used.'
    return
}

& $runDailyScript -Date $dateText -ConfigPath $ciConfigPath

$changed = @(& $gitCommand.Source -C $VaultPath -c core.quotePath=false status --porcelain)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to inspect Vault Git status.'
}
if ($changed.Count -eq 0) {
    Write-Host "No Vault changes to commit for $dateText."
    return
}

$unexpected = @($changed | Where-Object {
    $pathText = $_.Substring(3).Replace('\', '/')
    -not $pathText.StartsWith('AI_Review/')
})
if ($unexpected.Count -gt 0) {
    throw "Unexpected Vault paths changed: $($unexpected -join '; ')"
}

& $gitCommand.Source -C $VaultPath add AI_Review
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stage Vault AI_Review changes.'
}

& $gitCommand.Source -C $VaultPath commit -m "chore: add flomo observer review $dateText"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit Vault review changes.'
}

if ($NoPush) {
    Write-Host 'Skipping Vault push because -NoPush was used.'
    return
}

& $gitCommand.Source -C $VaultPath push origin "HEAD:$VaultBranch"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to push Vault changes to origin/$VaultBranch."
}

Write-Host "Vault review pushed to origin/$VaultBranch for $dateText."
