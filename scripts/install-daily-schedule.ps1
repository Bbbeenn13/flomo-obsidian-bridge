[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$At,
    [string]$TaskName = 'Flomo Obsidian Daily Review',
    [switch]$Replace
)

$ErrorActionPreference = 'Stop'

if ($At -notmatch '^(?<hour>\d{1,2}):(?<minute>\d{2})$') {
    throw 'Time must use HH:mm format, for example: 23:30'
}

$hour = [int]$Matches.hour
$minute = [int]$Matches.minute
if ($hour -lt 0 -or $hour -gt 23 -or $minute -lt 0 -or $minute -gt 59) {
    throw 'Time must be a valid 24-hour clock value, for example: 23:30'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$scheduledRunner = Join-Path $PSScriptRoot 'run-scheduled-daily.ps1'
if (-not (Test-Path -LiteralPath $scheduledRunner -PathType Leaf)) {
    throw "Scheduled runner not found: $scheduledRunner"
}

$powershellCommand = Get-Command powershell.exe -ErrorAction SilentlyContinue
if ($null -eq $powershellCommand) {
    throw 'powershell.exe is not available on PATH.'
}

$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($null -ne $existingTask -and -not $Replace) {
    throw "Scheduled task already exists: $TaskName. Re-run with -Replace to update it."
}

$startTime = (Get-Date).Date.AddHours($hour).AddMinutes($minute)
$actionArgument = "-NoProfile -ExecutionPolicy Bypass -File `"$scheduledRunner`""
$action = New-ScheduledTaskAction `
    -Execute $powershellCommand.Source `
    -Argument $actionArgument `
    -WorkingDirectory $projectRoot
$trigger = New-ScheduledTaskTrigger -Daily -At $startTime
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)
$principal = New-ScheduledTaskPrincipal `
    -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive `
    -RunLevel Limited

if ($PSCmdlet.ShouldProcess($TaskName, 'Register daily scheduled task')) {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description 'Generate a pending flomo observer journal draft in Obsidian AI_Review once per day.' `
        -Force | Out-Null

    Write-Host "Scheduled task installed: $TaskName"
} else {
    Write-Host "Scheduled task not installed because -WhatIf was used: $TaskName"
}
Write-Host "Runs daily at: $($startTime.ToString('HH:mm'))"
Write-Host "Command: $($powershellCommand.Source) $actionArgument"
Write-Host "Logs: $(Join-Path $projectRoot '.runs\scheduled-logs')"
