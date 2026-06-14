#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()]
    [string]$ClaudeCodeVersion = "latest",

    [Parameter()]
    [int]$NodeMajor = 22,

    [Parameter()]
    [ValidateSet("x64", "arm64")]
    [string[]]$Platforms = @("x64", "arm64"),

    [Parameter()]
    [string]$VendorRoot,

    [Parameter()]
    [switch]$SkipNode,

    [Parameter()]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-NpmJson {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $output = & npm @Arguments --json
    if ($LASTEXITCODE -ne 0) {
        throw "npm $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }

    ($output | Out-String) | ConvertFrom-Json
}

function Resolve-ClaudeCodeVersion {
    param([Parameter(Mandatory)][string]$RequestedVersion)

    if ($RequestedVersion -eq "latest") {
        $info = Invoke-NpmJson -Arguments @("view", "@anthropic-ai/claude-code", "version")
        return [string]$info
    }

    return $RequestedVersion
}

function Resolve-NodeVersion {
    param([Parameter(Mandatory)][int]$Major)

    Write-Step "正在解析最新的 Node.js v$Major 版本"
    $index = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json"
    $release = $index |
        Where-Object { $_.version -like "v$Major.*" } |
        Sort-Object { [version]($_.version.TrimStart("v")) } -Descending |
        Select-Object -First 1

    if (-not $release) {
        throw "无法解析 Node.js v$Major 版本。"
    }

    return $release.version.TrimStart("v")
}

function Save-NodeArchive {
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Architecture,
        [Parameter(Mandatory)][string]$NodeRoot
    )

    $fileName = "node-v$Version-win-$Architecture.zip"
    $uri = "https://nodejs.org/dist/v$Version/$fileName"
    $path = Join-Path $NodeRoot $fileName

    Write-Step "正在下载 $fileName"
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
    }

    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        & $curl.Source -L --fail --retry 3 --silent --show-error --output $path $uri
        if ($LASTEXITCODE -ne 0) {
            throw "curl 下载 $uri 失败，退出码 $LASTEXITCODE。"
        }
    }
    else {
        Invoke-WebRequest -Uri $uri -OutFile $path -UseBasicParsing
    }

    if (-not (Test-Path -LiteralPath $path) -or (Get-Item -LiteralPath $path).Length -le 0) {
        throw "下载到的 Node.js 压缩包为空: $path"
    }

    [pscustomobject]@{
        architecture = $Architecture
        path         = "node/$fileName"
        sha256       = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
    }
}

function Add-NpmPackageToOfflineCache {
    param(
        [Parameter(Mandatory)][string]$PackageSpec,
        [Parameter(Mandatory)][string]$CacheRoot
    )

    Write-Step "正在缓存 npm 包 $PackageSpec"
    & npm cache add $PackageSpec --cache $CacheRoot
    if ($LASTEXITCODE -ne 0) {
        throw "npm cache add $PackageSpec 失败，退出码 $LASTEXITCODE。"
    }
}

function Write-Checksums {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter()][object[]]$Entries = @()
    )

    $checksumPath = Join-Path $Root "checksums.sha256"
    $lines = foreach ($entry in $Entries) {
        "$($entry.sha256)  $($entry.path)"
    }

    Set-Content -LiteralPath $checksumPath -Value $lines -Encoding ASCII
}

$npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
if (-not $npm) {
    throw "未找到 npm。请先在联网准备机器上安装 Node.js。"
}

if ([string]::IsNullOrWhiteSpace($VendorRoot)) {
    $VendorRoot = Join-Path $ScriptRoot "vendor"
}

if ((Test-Path -LiteralPath $VendorRoot) -and $Force.IsPresent) {
    Remove-Item -LiteralPath $VendorRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $VendorRoot -Force | Out-Null
$npmCache = Join-Path $VendorRoot "npm-cache"
$nodeRoot = Join-Path $VendorRoot "node"
New-Item -ItemType Directory -Path $npmCache -Force | Out-Null
New-Item -ItemType Directory -Path $nodeRoot -Force | Out-Null

$resolvedClaudeVersion = Resolve-ClaudeCodeVersion -RequestedVersion $ClaudeCodeVersion
Write-Step "正在准备 Claude Code $resolvedClaudeVersion"

$optionalDependencies = Invoke-NpmJson -Arguments @(
    "view",
    "@anthropic-ai/claude-code@$resolvedClaudeVersion",
    "optionalDependencies"
)

$packageSpecs = New-Object System.Collections.Generic.List[string]
$packageSpecs.Add("@anthropic-ai/claude-code@$resolvedClaudeVersion")
foreach ($platform in $Platforms) {
    $packageName = "@anthropic-ai/claude-code-win32-$platform"
    $platformVersion = $optionalDependencies.$packageName
    if (-not $platformVersion) {
        throw "Claude Code $resolvedClaudeVersion 未声明可选依赖 $packageName。"
    }
    $packageSpecs.Add("$packageName@$platformVersion")
}

foreach ($packageSpec in $packageSpecs) {
    Add-NpmPackageToOfflineCache -PackageSpec $packageSpec -CacheRoot $npmCache
}

& npm cache verify --cache $npmCache | Out-Host
if ($LASTEXITCODE -ne 0) {
    throw "npm 缓存验证失败，退出码 $LASTEXITCODE。"
}

$checksumEntries = @()
$nodeVersion = $null
$nodeFiles = @()
if (-not $SkipNode.IsPresent) {
    $nodeVersion = Resolve-NodeVersion -Major $NodeMajor
    foreach ($platform in $Platforms) {
        $nodeFiles += Save-NodeArchive -Version $nodeVersion -Architecture $platform -NodeRoot $nodeRoot
    }
    $checksumEntries += $nodeFiles
}

$manifest = [ordered]@{
    schemaVersion = 1
    createdAt     = (Get-Date).ToUniversalTime().ToString("o")
    claudeCode    = [ordered]@{
        version  = $resolvedClaudeVersion
        packages = @($packageSpecs)
    }
    node          = [ordered]@{
        version = $nodeVersion
        files   = @($nodeFiles)
    }
    deepseek      = [ordered]@{
        baseUrl       = "https://api.deepseek.com/anthropic"
        opusModel     = "deepseek-v4-pro[1m]"
        sonnetModel   = "deepseek-v4-pro[1m]"
        haikuModel    = "deepseek-v4-flash"
        subagentModel = "deepseek-v4-flash"
        effortLevel   = "max"
    }
}

$manifestPath = Join-Path $VendorRoot "manifest.json"
($manifest | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Checksums -Root $VendorRoot -Entries $checksumEntries

Write-Step "离线包准备完成"
Write-Host "资源目录: $VendorRoot"
Write-Host "请将整个仓库连同 vendor 目录一起复制到离线 Windows 机器。"
