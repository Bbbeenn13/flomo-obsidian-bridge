[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [datetime]$Date,
    [string]$ConfigPath,
    [switch]$Approve,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if (-not $Approve -and -not $DryRun) {
    throw 'Explicit approval is required. Re-run with -Approve.'
}

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $projectRoot 'bridge.config.json'
}
if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
    throw "Bridge config not found: $ConfigPath"
}

$config = Get-Content -Raw -Encoding UTF8 -LiteralPath $ConfigPath | ConvertFrom-Json
$requiredKeys = @('vaultPath', 'reviewRoot', 'dailyRoot')
foreach ($key in $requiredKeys) {
    if ($null -eq $config.$key -or [string]::IsNullOrWhiteSpace([string]$config.$key)) {
        throw "Missing required config value: $key"
    }
}

$vaultPath = [IO.Path]::GetFullPath([string]$config.vaultPath)
if (-not (Test-Path -LiteralPath $vaultPath -PathType Container)) {
    throw "Obsidian vault not found: $vaultPath"
}

$day = $Date.Date
$dateText = $day.ToString('yyyy-MM-dd')
$fileDateText = $day.ToString('yyyy.MM.dd')
$yearText = $day.ToString('yyyy')
$reviewRelativePath = "$([string]$config.reviewRoot)/$yearText/$fileDateText.md"
$dailyRelativePath = "$([string]$config.dailyRoot)/$yearText/$fileDateText.md"
$reviewPath = Join-Path $vaultPath ($reviewRelativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
$dailyPath = Join-Path $vaultPath ($dailyRelativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
$marker = "<!-- flomo-observer-review: $dateText -->"

if (-not (Test-Path -LiteralPath $reviewPath -PathType Leaf)) {
    throw "Review draft not found: $reviewPath"
}

$review = Get-Content -Raw -Encoding UTF8 -LiteralPath $reviewPath
$requiredMarkers = @(
    'type: observer_daily_draft',
    "date: $dateText",
    "approved_destination: $dailyRelativePath"
)
foreach ($requiredMarker in $requiredMarkers) {
    if (-not $review.Contains($requiredMarker)) {
        throw "Review draft is missing required marker: $requiredMarker"
    }
}

function Get-ReviewSection {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$HeadingPattern
    )

    $pattern = '(?ms)^## (?<heading>' + $HeadingPattern + ')\s*\r?\n(?<body>.*?)(?=^## |\z)'
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success -or [string]::IsNullOrWhiteSpace($match.Groups['body'].Value)) {
        throw "Review draft section is missing or empty: $HeadingPattern"
    }
    return [pscustomobject]@{
        Heading = $match.Groups['heading'].Value
        Body = $match.Groups['body'].Value.Trim()
    }
}

$today = Get-ReviewSection -Content $review -HeadingPattern '\u4eca\u5929\u7684\u6211'
$mines = Get-ReviewSection -Content $review -HeadingPattern '\u503c\u5f97\u7559\u4e0b\u7684\u77ff'
$unresolved = Get-ReviewSection -Content $review -HeadingPattern '\u8fd8\u6ca1\u60f3\u5b8c\u7684\u5730\u65b9'
$carry = Get-ReviewSection -Content $review -HeadingPattern '\u5e26\u5230\u660e\u5929'

$lineEnding = "`r`n"
$sourceLabel = [regex]::Unescape('\u6765\u6e90')
$reviewAlias = [regex]::Unescape('\u5ba1\u6838\u7a3f')
$approvedLabel = [regex]::Unescape('\u7ecf\u672c\u4eba\u5ba1\u6838\u786e\u8ba4')
$fullWidthColon = [char]0xFF1A
$fullWidthSemicolon = [char]0xFF1B
$ideographicPeriod = [char]0x3002
$sourceLine = "> ${sourceLabel}${fullWidthColon}[[AI_Review/$yearText/$fileDateText|flomo ${reviewAlias}]]${fullWidthSemicolon}${approvedLabel}${ideographicPeriod}"
$dailyEntry = @(
    ('# ' + $today.Heading),
    '',
    $today.Body,
    '',
    ('# ' + $mines.Heading),
    '',
    $mines.Body,
    '',
    ('# ' + $unresolved.Heading),
    '',
    $unresolved.Body,
    '',
    ('# ' + $carry.Heading),
    '',
    $carry.Body,
    '',
    '---',
    '',
    $sourceLine,
    '',
    $marker,
    ''
) -join $lineEnding

if ($DryRun) {
    Write-Output "Review: $reviewPath"
    Write-Output "Destination: $dailyPath"
    Write-Output $dailyEntry
    return
}

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($null -eq $gitCommand) {
    throw 'Git is not available on PATH.'
}
$existingChanges = @(& $gitCommand.Source -C $vaultPath status --porcelain)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to inspect Vault Git status.'
}
if ($existingChanges.Count -gt 0) {
    throw "Vault must be clean before approval: $($existingChanges -join '; ')"
}

$existingDaily = ''
if (Test-Path -LiteralPath $dailyPath -PathType Leaf) {
    $existingDaily = Get-Content -Raw -Encoding UTF8 -LiteralPath $dailyPath
}

if ($review.Contains('review_status: approved') -and $existingDaily.Contains($marker)) {
    Write-Host "Daily review was already approved: $dailyPath"
    return
}
if (-not $review.Contains('review_status: pending')) {
    throw 'Review draft is not pending approval.'
}
if ($existingDaily.Contains($marker)) {
    throw "Daily destination already contains the approval marker: $marker"
}

$dailyDirectory = Split-Path -Parent $dailyPath
[IO.Directory]::CreateDirectory($dailyDirectory) | Out-Null
if ([string]::IsNullOrWhiteSpace($existingDaily)) {
    $newDaily = $dailyEntry
} else {
    $newDaily = $existingDaily.TrimEnd() + $lineEnding + $lineEnding + '---' + $lineEnding + $lineEnding + $dailyEntry
}

$approvedReview = $review.Replace('review_status: pending', 'review_status: approved')
$pendingTitle = [regex]::Unescape('\u65e5\u8bb0\u8349\u7a3f\uff08\u5f85\u5ba1\u6838\uff09')
$approvedTitle = [regex]::Unescape('\u65e5\u8bb0\u8349\u7a3f\uff08\u5df2\u5ba1\u6838\uff09')
$approvedReview = $approvedReview.Replace($pendingTitle, $approvedTitle)
$approvedReview = $approvedReview -replace '(?m)^- \[ \] ', '- [x] '

$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($dailyPath, $newDaily, $utf8)
[IO.File]::WriteAllText($reviewPath, $approvedReview, $utf8)

$changed = @(& $gitCommand.Source -C $vaultPath status --porcelain)
$expectedSuffixes = @(
    $reviewRelativePath,
    $dailyRelativePath
)
$unexpected = @($changed | Where-Object {
    $line = $_
    -not ($expectedSuffixes | Where-Object { $line.EndsWith($_) })
})
if ($unexpected.Count -gt 0) {
    throw "Unexpected Vault files changed during approval: $($unexpected -join '; ')"
}

Write-Host "Approved review: $reviewPath"
Write-Host "Daily note ready: $dailyPath"
