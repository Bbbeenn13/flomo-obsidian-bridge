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
$pendingReviewSuffix = [regex]::Unescape('\u5f85\u5ba1\u6838')
$approvedReviewSuffix = [regex]::Unescape('\u5df2\u5ba1\u6838')
$pendingReviewRelativePath = "$([string]$config.reviewRoot)/$yearText/${fileDateText}_${pendingReviewSuffix}.md"
$approvedReviewRelativePath = "$([string]$config.reviewRoot)/$yearText/${fileDateText}_${approvedReviewSuffix}.md"
$legacyReviewRelativePath = "$([string]$config.reviewRoot)/$yearText/$fileDateText.md"
$dailyRelativePath = "$([string]$config.dailyRoot)/$yearText/${fileDateText}_Codex.md"
$pendingReviewPath = Join-Path $vaultPath ($pendingReviewRelativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
$approvedReviewPath = Join-Path $vaultPath ($approvedReviewRelativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
$legacyReviewPath = Join-Path $vaultPath ($legacyReviewRelativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
$dailyPath = Join-Path $vaultPath ($dailyRelativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))
$marker = "<!-- flomo-observer-review: $dateText -->"

$reviewRelativePath = $null
$reviewPath = $null
if (Test-Path -LiteralPath $pendingReviewPath -PathType Leaf) {
    $reviewRelativePath = $pendingReviewRelativePath
    $reviewPath = $pendingReviewPath
} elseif (Test-Path -LiteralPath $legacyReviewPath -PathType Leaf) {
    $reviewRelativePath = $legacyReviewRelativePath
    $reviewPath = $legacyReviewPath
} elseif (Test-Path -LiteralPath $approvedReviewPath -PathType Leaf) {
    $reviewRelativePath = $approvedReviewRelativePath
    $reviewPath = $approvedReviewPath
} else {
    throw "Review draft not found. Checked: $pendingReviewPath; $legacyReviewPath; $approvedReviewPath"
}

$review = Get-Content -Raw -Encoding UTF8 -LiteralPath $reviewPath
$requiredMarkers = @(
    'type: observer_daily_draft',
    "date: $dateText",
    "approved_destination: $dailyRelativePath",
    'keywords:'
)
foreach ($requiredMarker in $requiredMarkers) {
    if (-not $review.Contains($requiredMarker)) {
        throw "Review draft is missing required marker: $requiredMarker"
    }
}

function Get-ReviewSection {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$HeadingPattern,
        [switch]$Optional
    )

    $pattern = '(?ms)^## (?<heading>' + $HeadingPattern + ')\s*\r?\n(?<body>.*?)(?=^## |\z)'
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success -or [string]::IsNullOrWhiteSpace($match.Groups['body'].Value)) {
        if ($Optional) {
            return $null
        }
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
$cbt = Get-ReviewSection -Content $review -HeadingPattern '\u53ef\u4ee5\u53e6\u884c\u62c6\u89e3\u7684\u5361\u70b9' -Optional
$materials = Get-ReviewSection -Content $review -HeadingPattern '\u7d20\u6750\u7d22\u5f15'

$keywordsMatch = [regex]::Match($review, '(?m)^keywords:\s*(?<value>\[[^\r\n]*\])\s*$')
if (-not $keywordsMatch.Success) {
    throw 'Review draft keywords must use a one-line YAML array.'
}
$keywordsValue = $keywordsMatch.Groups['value'].Value
$keywordsInner = $keywordsValue.Trim('[', ']').Trim()
$keywordCount = 0
if (-not [string]::IsNullOrWhiteSpace($keywordsInner)) {
    $keywordCount = @($keywordsInner.Split(',') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
}
if ($keywordCount -gt 5) {
    throw "Review draft has too many keywords: $keywordCount"
}

$lineEnding = "`r`n"
$sourceLabel = [regex]::Unescape('\u6765\u6e90')
$reviewAlias = [regex]::Unescape('\u5ba1\u6838\u7a3f')
$approvedLabel = [regex]::Unescape('\u7ecf\u672c\u4eba\u5ba1\u6838\u786e\u8ba4')
$fullWidthColon = [char]0xFF1A
$fullWidthSemicolon = [char]0xFF1B
$ideographicPeriod = [char]0x3002
$approvedReviewLink = "$([string]$config.reviewRoot)/$yearText/${fileDateText}_${approvedReviewSuffix}"
$sourceLine = "> ${sourceLabel}${fullWidthColon}[[$approvedReviewLink|flomo ${reviewAlias}]]${fullWidthSemicolon}${approvedLabel}${ideographicPeriod}"
$dailyLines = @(
    '---',
    'type: codex_observer_daily',
    "date: $dateText",
    "keywords: $keywordsValue",
    'source: flomo',
    "review_source: `"[[$approvedReviewLink]]`"",
    'generated_by: codex',
    '---',
    '',
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
    ''
)
if ($null -ne $cbt) {
    $dailyLines += @(
        ('# ' + $cbt.Heading),
        '',
        $cbt.Body,
        ''
    )
}
$dailyLines += @(
    ('# ' + $materials.Heading),
    '',
    $materials.Body,
    '',
    '---',
    '',
    $sourceLine,
    '',
    $marker,
    ''
)
$dailyEntry = $dailyLines -join $lineEnding

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

function Get-GitStatusPaths {
    param([Parameter(Mandatory = $true)][string]$Line)

    $pathText = $Line.Substring(3).Replace('\', '/')
    if ($pathText.Contains(' -> ')) {
        return @($pathText.Split(' -> ') | ForEach-Object { $_.Trim() })
    }
    return @($pathText)
}

$existingChanges = @(& $gitCommand.Source -C $vaultPath -c core.quotePath=false status --porcelain)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to inspect Vault Git status.'
}
$reviewRootPrefix = "$([string]$config.reviewRoot)/"
$unexpectedExisting = @($existingChanges | Where-Object {
    $paths = @(Get-GitStatusPaths -Line $_)
    @($paths | Where-Object { -not $_.StartsWith($reviewRootPrefix) }).Count -gt 0
})
if ($unexpectedExisting.Count -gt 0) {
    throw "Vault has non-review changes before approval: $($unexpectedExisting -join '; ')"
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
[IO.File]::WriteAllText($approvedReviewPath, $approvedReview, $utf8)
if ($reviewPath -ne $approvedReviewPath) {
    Remove-Item -LiteralPath $reviewPath
}

$changed = @(& $gitCommand.Source -C $vaultPath -c core.quotePath=false status --porcelain)
$expectedSuffixes = @(
    $reviewRelativePath,
    $approvedReviewRelativePath,
    $dailyRelativePath
)
$unexpected = @($changed | Where-Object {
    $paths = @(Get-GitStatusPaths -Line $_)
    @($paths | Where-Object {
        $path = $_
        -not ($expectedSuffixes -contains $path) -and -not $path.StartsWith($reviewRootPrefix)
    }).Count -gt 0
})
if ($unexpected.Count -gt 0) {
    throw "Unexpected Vault files changed during approval: $($unexpected -join '; ')"
}

Write-Host "Approved review: $approvedReviewPath"
Write-Host "Daily note ready: $dailyPath"
