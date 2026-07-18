[CmdletBinding()]
param(
    [datetime]$Date = (Get-Date),
    [string]$ConfigPath,
    [string]$LogRoot,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$runDailyScript = Join-Path $PSScriptRoot 'run-daily.ps1'
if (-not (Test-Path -LiteralPath $runDailyScript -PathType Leaf)) {
    throw "Daily runner not found: $runDailyScript"
}

if ([string]::IsNullOrWhiteSpace($LogRoot)) {
    $LogRoot = Join-Path $projectRoot '.runs\scheduled-logs'
}
$LogRoot = [IO.Path]::GetFullPath($LogRoot)
[IO.Directory]::CreateDirectory($LogRoot) | Out-Null

$dateText = $Date.Date.ToString('yyyy-MM-dd')
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$logPath = Join-Path $LogRoot "$dateText-$stamp.log"

$arguments = @{
    Date = $dateText
}
if (-not [string]::IsNullOrWhiteSpace($ConfigPath)) {
    $arguments.ConfigPath = $ConfigPath
}
if ($DryRun) {
    $arguments.DryRun = $true
}

Start-Transcript -LiteralPath $logPath -Append | Out-Null
try {
    Write-Host "Scheduled flomo observer run started: $dateText"
    Write-Host "Project root: $projectRoot"
    Write-Host "Log: $logPath"

    & $runDailyScript @arguments

    Write-Host "Scheduled flomo observer run completed: $dateText"
}
finally {
    Stop-Transcript | Out-Null
}

Write-Host "Scheduled run log: $logPath"
