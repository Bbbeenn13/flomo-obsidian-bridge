[CmdletBinding()]
param(
    [datetime]$Date = (Get-Date),
    [string]$ConfigPath,
    [string]$GeneratedFile,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $projectRoot 'bridge.config.json'
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Bridge config not found: $ConfigPath"
}

$config = Get-Content -Raw -Encoding UTF8 -LiteralPath $ConfigPath | ConvertFrom-Json
$requiredKeys = @('vaultPath', 'reviewRoot', 'dailyRoot', 'timezone', 'recentDailyNotes', 'maxMines', 'maxReportCharacters')
foreach ($key in $requiredKeys) {
    if ($null -eq $config.$key -or [string]::IsNullOrWhiteSpace([string]$config.$key)) {
        throw "Missing required config value: $key"
    }
}

$vaultPath = [IO.Path]::GetFullPath([string]$config.vaultPath)
if (-not (Test-Path -LiteralPath $vaultPath -PathType Container)) {
    throw "Obsidian vault not found: $vaultPath"
}
if (-not (Test-Path -LiteralPath (Join-Path $vaultPath 'CLAUDE.md') -PathType Leaf)) {
    throw "Vault schema not found: $(Join-Path $vaultPath 'CLAUDE.md')"
}

$codexCommand = Get-Command codex -ErrorAction SilentlyContinue
if ($null -eq $codexCommand) {
    throw 'Codex CLI is not available on PATH.'
}

$token = [Environment]::GetEnvironmentVariable('FLOMO_MCP_TOKEN', 'Process')
if ([string]::IsNullOrWhiteSpace($token)) {
    $token = [Environment]::GetEnvironmentVariable('FLOMO_MCP_TOKEN', 'User')
}
if ([string]::IsNullOrWhiteSpace($token)) {
    throw 'FLOMO_MCP_TOKEN is not configured for this user.'
}
$env:FLOMO_MCP_TOKEN = $token

$day = $Date.Date
$dateText = $day.ToString('yyyy-MM-dd')
$fileDateText = $day.ToString('yyyy.MM.dd')
$yearText = $day.ToString('yyyy')
$startTime = "${dateText}T00:00:00+08:00"
$endTime = $day.AddDays(1).ToString('yyyy-MM-dd') + 'T00:00:00+08:00'

$reviewRoot = Join-Path $vaultPath ([string]$config.reviewRoot)
$reviewYear = Join-Path $reviewRoot $yearText
$outputPath = Join-Path $reviewYear ($fileDateText + '.md')
$dailyDestination = "$([string]$config.dailyRoot)/$yearText/${fileDateText}_Codex.md"
$runDir = Join-Path $projectRoot '.runs'
[IO.Directory]::CreateDirectory($runDir) | Out-Null
if ([string]::IsNullOrWhiteSpace($GeneratedFile)) {
    $temporaryOutputPath = Join-Path $runDir ("generated-$dateText-$PID.md")
} else {
    $temporaryOutputPath = [IO.Path]::GetFullPath($GeneratedFile)
    if (-not (Test-Path -LiteralPath $temporaryOutputPath -PathType Leaf)) {
        throw "Generated file not found: $temporaryOutputPath"
    }
}

$promptTemplatePath = Join-Path $projectRoot 'prompts\daily-review.md'
if (-not (Test-Path -LiteralPath $promptTemplatePath -PathType Leaf)) {
    throw "Prompt template not found: $promptTemplatePath"
}

$prompt = Get-Content -Raw -Encoding UTF8 -LiteralPath $promptTemplatePath
$replacements = [ordered]@{
    '{{DATE}}' = $dateText
    '{{TIMEZONE}}' = [string]$config.timezone
    '{{START_TIME}}' = $startTime
    '{{END_TIME}}' = $endTime
    '{{VAULT_PATH}}' = $vaultPath
    '{{TEMP_OUTPUT_PATH}}' = $temporaryOutputPath
    '{{REVIEW_DESTINATION}}' = $outputPath
    '{{DAILY_DESTINATION}}' = $dailyDestination
    '{{RECENT_DAILY_NOTES}}' = [string]$config.recentDailyNotes
    '{{MAX_MINES}}' = [string]$config.maxMines
    '{{MAX_REPORT_CHARACTERS}}' = [string]$config.maxReportCharacters
}
foreach ($entry in $replacements.GetEnumerator()) {
    $prompt = $prompt.Replace($entry.Key, $entry.Value)
}

if ($prompt -match '\{\{[A-Z_]+\}\}') {
    throw 'The rendered prompt still contains unresolved placeholders.'
}

if ($DryRun) {
    Write-Output $prompt
    return
}

if ([string]::IsNullOrWhiteSpace($GeneratedFile) -and (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    $existingReview = Get-Content -Raw -Encoding UTF8 -LiteralPath $outputPath
    if ($existingReview.Contains('review_status: approved')) {
        throw "Refusing to overwrite an approved review: $outputPath"
    }
}

[IO.Directory]::CreateDirectory($reviewYear) | Out-Null
$lastMessagePath = Join-Path $runDir ("last-message-$dateText.txt")

$before = @{}
if (Test-Path -LiteralPath $reviewRoot -PathType Container) {
    Get-ChildItem -LiteralPath $reviewRoot -Recurse -File | ForEach-Object {
        $before[$_.FullName] = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }
}

if ([string]::IsNullOrWhiteSpace($GeneratedFile)) {
    $arguments = @(
        'exec',
        '--ephemeral',
        '--sandbox', 'workspace-write',
        '--cd', $projectRoot,
        '--output-last-message', $lastMessagePath,
        $prompt
    )

    Write-Host "Generating review packet for $dateText ..."
    & $codexCommand.Source @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Codex exited with code $LASTEXITCODE"
    }
} else {
    Write-Host "Validating existing generated review for $dateText ..."
}

if (-not (Test-Path -LiteralPath $temporaryOutputPath -PathType Leaf)) {
    throw "Codex completed without creating the expected temporary output: $temporaryOutputPath"
}

$generated = Get-Content -Raw -Encoding UTF8 -LiteralPath $temporaryOutputPath
if ($generated.Length -gt [int]$config.maxReportCharacters) {
    throw "Generated review is too long: $($generated.Length) characters; limit is $($config.maxReportCharacters)."
}
$requiredMarkers = @(
    'type: observer_daily_draft',
    'mode: observer_journal',
    "date: $dateText",
    'source: flomo',
    'review_status: pending',
    'approved_destination:',
    'cbt_followup:',
    'keywords:',
    'memo_count:',
    'memo_ids:',
    'generated_by: codex'
)
foreach ($marker in $requiredMarkers) {
    if (-not $generated.Contains($marker)) {
        throw "Generated review is missing required marker: $marker"
    }
}

[IO.File]::WriteAllText($outputPath, $generated, (New-Object System.Text.UTF8Encoding($false)))

$changed = New-Object System.Collections.Generic.List[string]
Get-ChildItem -LiteralPath $reviewRoot -Recurse -File | ForEach-Object {
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    if (-not $before.ContainsKey($_.FullName) -or $before[$_.FullName] -ne $hash) {
        $changed.Add($_.FullName)
    }
}

$unexpected = @($changed | Where-Object { $_ -ne $outputPath })
if ($unexpected.Count -gt 0) {
    throw "Unexpected review files changed: $($unexpected -join ', ')"
}

Write-Host "Review packet ready: $outputPath"
