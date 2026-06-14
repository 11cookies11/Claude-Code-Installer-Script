#Requires -Version 5.1
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter()]
    [string]$DeepSeekApiKey,

    [Parameter()]
    [string]$OfflineRoot,

    [Parameter()]
    [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA "ClaudeCodeOffline"),

    [Parameter()]
    [switch]$UseSystemNode,

    [Parameter()]
    [switch]$SkipClaudeInstall,

    [Parameter()]
    [switch]$SkipChecksum,

    [Parameter()]
    [string]$Model = "deepseek-v4-pro[1m]",

    [Parameter()]
    [string]$OpusModel = "deepseek-v4-pro[1m]",

    [Parameter()]
    [string]$SonnetModel = "deepseek-v4-pro[1m]",

    [Parameter()]
    [string]$HaikuModel = "deepseek-v4-flash",

    [Parameter()]
    [string]$SubagentModel = "deepseek-v4-flash",

    [Parameter()]
    [string]$EffortLevel = "max",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$BaseUrl = "https://api.deepseek.com/anthropic",

    [Parameter()]
    [switch]$NoPersist,

    [Parameter()]
    [switch]$NoVerify,

    [Parameter()]
    [ValidateSet("Run", "Skip")]
    [string]$LaunchMode = "Run",

    [Parameter()]
    [ValidateSet("default", "acceptEdits", "bypassPermissions")]
    [string]$PermissionMode,

    [Parameter()]
    [ValidateSet("New", "Continue", "Resume")]
    [string]$ConversationMode,

    [Parameter()]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:InstallerLogPath = $null
$script:InstallerTranscriptStarted = $false

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-WarningLine {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "警告: $Message" -ForegroundColor Yellow
}

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host ""
    Write-Host "== $Title ==" -ForegroundColor Green
}

function Read-Choice {
    param(
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)][string[]]$Options,
        [Parameter()][int]$DefaultIndex = 1
    )

    while ($true) {
        Write-Host $Prompt -ForegroundColor Cyan
        for ($i = 0; $i -lt $Options.Count; $i++) {
            $label = $Options[$i]
            if (($i + 1) -eq $DefaultIndex) {
                Write-Host ("  [{0}] {1} (default)" -f ($i + 1), $label)
            }
            else {
                Write-Host ("  [{0}] {1}" -f ($i + 1), $label)
            }
        }

        $raw = Read-Host "请选择"
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $DefaultIndex
        }

        $choice = 0
        if ([int]::TryParse($raw, [ref]$choice) -and $choice -ge 1 -and $choice -le $Options.Count) {
            return $choice
        }

        Write-WarningLine "请输入 1 到 $($Options.Count) 之间的数字。"
    }
}

function Read-SecretValue {
    param([Parameter(Mandatory)][string]$Prompt)

    $secure = Read-Host $Prompt -AsSecureString
    return ConvertTo-PlainText -SecureString $secure
}

function Get-DeepSeekDefaults {
    return [pscustomobject]@{
        BaseUrl       = "https://api.deepseek.com/anthropic"
        Model         = "deepseek-v4-pro[1m]"
        OpusModel     = "deepseek-v4-pro[1m]"
        SonnetModel   = "deepseek-v4-pro[1m]"
        HaikuModel    = "deepseek-v4-flash"
        SubagentModel = "deepseek-v4-flash"
        EffortLevel   = "max"
    }
}

function Resolve-OfflineRoot {
    param([Parameter(Mandatory)][string]$ScriptRootValue)

    $candidates = @(
        (Join-Path $ScriptRootValue "vendor"),
        (Join-Path $ScriptRootValue "src\vendor")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $candidates[0]
}

function Start-InstallerLogging {
    $logRoot = Join-Path ([System.IO.Path]::GetTempPath()) "Claude-Code-Installer-Script\logs"
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:InstallerLogPath = Join-Path $logRoot "install-$timestamp.log"

    try {
        Start-Transcript -LiteralPath $script:InstallerLogPath -Force | Out-Null
        $script:InstallerTranscriptStarted = $true
        Write-Host "日志文件: $script:InstallerLogPath" -ForegroundColor DarkGray
    }
    catch {
        $script:InstallerLogPath = $null
        Write-WarningLine "无法启动日志记录，后续只会输出到屏幕。"
    }
}

function Stop-InstallerLogging {
    if ($script:InstallerTranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            # Ignore transcript shutdown errors.
        }
        finally {
            $script:InstallerTranscriptStarted = $false
        }
    }
}

function Get-LaunchProfile {
    param([Parameter(Mandatory)][int]$Choice)

    switch ($Choice) {
        1 {
            return [pscustomobject]@{
                Name          = "保守模式（Ask for approval）"
                PermissionMode = "default"
                LaunchMode    = "Run"
                Description   = "每一步都先问你，最稳妥"
            }
        }
        2 {
            return [pscustomobject]@{
                Name          = "平衡模式（Approve for me）"
                PermissionMode = "acceptEdits"
                LaunchMode    = "Run"
                Description   = "常规编辑自动放行，兼顾效率和控制"
            }
        }
        3 {
            return [pscustomobject]@{
                Name          = "全开模式（Full access）"
                PermissionMode = "bypassPermissions"
                LaunchMode    = "Run"
                Description   = "几乎不打断你，适合可信的本地环境"
            }
        }
        default {
            return [pscustomobject]@{
                Name          = "平衡模式（Approve for me）"
                PermissionMode = "acceptEdits"
                LaunchMode    = "Run"
                Description   = "常规编辑自动放行，兼顾效率和控制"
            }
        }
    }
}

function Get-ConversationProfile {
    param([Parameter(Mandatory)][int]$Choice)

    switch ($Choice) {
        1 {
            return [pscustomobject]@{
                Name        = "新对话"
                Mode        = "New"
                Description = "直接开启一段全新的会话"
            }
        }
        2 {
            return [pscustomobject]@{
                Name        = "继续上次"
                Mode        = "Continue"
                Description = "接着最近一次会话继续聊"
            }
        }
        3 {
            return [pscustomobject]@{
                Name        = "历史选择"
                Mode        = "Resume"
                Description = "打开历史会话选择器，手动挑一个"
            }
        }
        default {
            return [pscustomobject]@{
                Name        = "新对话"
                Mode        = "New"
                Description = "直接开启一段全新的会话"
            }
        }
    }
}

function ConvertTo-PlainText {
    param([Parameter(Mandatory)][securestring]$SecureString)

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Test-IsWindows {
    if ($PSVersionTable.PSEdition -eq "Desktop") {
        return $true
    }

    return [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Windows
    )
}

function Get-WindowsArchitecture {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { return "x64" }
        "ARM64" { return "arm64" }
        default { throw "Unsupported Windows architecture: $env:PROCESSOR_ARCHITECTURE" }
    }
}

function Add-PathSegment {
    param(
        [Parameter(Mandatory)][string]$PathValue,
        [Parameter(Mandatory)][string]$Segment
    )

    if ([string]::IsNullOrWhiteSpace($Segment)) {
        return $PathValue
    }

    $parts = @($PathValue -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($parts -contains $Segment) {
        return $PathValue
    }

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        return $Segment
    }

    return "$PathValue;$Segment"
}

function Add-UserPath {
    param([Parameter(Mandatory)][string[]]$Segments)

    foreach ($segment in $Segments) {
        if (-not (Test-Path -LiteralPath $segment)) {
            continue
        }

        $env:Path = Add-PathSegment -PathValue $env:Path -Segment $segment
    }

    if ($NoPersist.IsPresent) {
        return
    }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    foreach ($segment in $Segments) {
        if (Test-Path -LiteralPath $segment) {
            $userPath = Add-PathSegment -PathValue $userPath -Segment $segment
        }
    }

    [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
}

function Read-OfflineManifest {
    param([Parameter(Mandatory)][string]$Root)

    $manifestPath = Join-Path $Root "manifest.json"
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Offline manifest not found: $manifestPath. Run prepare-offline-package.ps1 on an online machine first."
    }

    Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}

function Test-OfflineChecksums {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)]$Manifest
    )

    if ($SkipChecksum.IsPresent) {
        Write-WarningLine "已跳过校验文件验证。"
        return
    }

    $checksumPath = Join-Path $Root "checksums.sha256"
    if (-not (Test-Path -LiteralPath $checksumPath)) {
        throw "未找到校验文件: $checksumPath"
    }

    Write-Step "正在验证离线包校验"
    $lines = Get-Content -LiteralPath $checksumPath | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_) -and -not $_.TrimStart().StartsWith("#")
    }

    foreach ($line in $lines) {
        $parts = $line -split "\s+", 2
        if ($parts.Count -ne 2) {
            throw "校验行格式无效: $line"
        }

        $expected = $parts[0].ToLowerInvariant()
        $relativePath = $parts[1].Trim()
        $filePath = Join-Path $Root $relativePath
        if (-not (Test-Path -LiteralPath $filePath)) {
            throw "校验目标不存在: $filePath"
        }

        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $filePath).Hash.ToLowerInvariant()
        if ($actual -ne $expected) {
            throw "文件校验不匹配: ${relativePath}，期望 $expected，实际 $actual"
        }
    }

    $npmCache = Join-Path $Root "npm-cache"
    if (Test-Path -LiteralPath $npmCache) {
        $npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
        if ($npm) {
            & $npm.Source cache verify --cache $npmCache | Out-Host
            if ($LASTEXITCODE -ne 0) {
                throw "npm 缓存验证失败，退出码 $LASTEXITCODE。"
            }
        }
        else {
            Write-WarningLine "当前还没有可用的 npm，安装时会再检查缓存完整性。"
        }
    }

    $null = $Manifest
}

function Expand-BundledNode {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][string]$Architecture,
        [Parameter(Mandatory)]$Manifest
    )

    $nodeEntry = @($Manifest.node.files | Where-Object { $_.architecture -eq $Architecture }) | Select-Object -First 1
    if (-not $nodeEntry) {
        throw "没有为 Windows $Architecture 准备内置 Node.js 压缩包。"
    }

    $zipPath = Join-Path $Root $nodeEntry.path
    if (-not (Test-Path -LiteralPath $zipPath)) {
        throw "未找到内置 Node.js 压缩包: $zipPath"
    }

    $toolsRoot = Join-Path $TargetRoot "tools"
    $nodeHome = Join-Path $toolsRoot ([IO.Path]::GetFileNameWithoutExtension($zipPath))
    if (Test-Path -LiteralPath (Join-Path $nodeHome "npm.cmd")) {
        return $nodeHome
    }

    Write-Step "正在解压内置 Node.js"
    New-Item -ItemType Directory -Path $toolsRoot -Force | Out-Null
    Expand-Archive -LiteralPath $zipPath -DestinationPath $toolsRoot -Force

    if (-not (Test-Path -LiteralPath (Join-Path $nodeHome "npm.cmd"))) {
        throw "内置 Node.js 解压后未找到 npm.cmd: $nodeHome"
    }

    return $nodeHome
}

function Install-ClaudeCodeOffline {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)]$Manifest
    )

    $architecture = Get-WindowsArchitecture
    $prefix = Join-Path $TargetRoot "npm-global"
    $cache = Join-Path $Root "npm-cache"

    if (-not (Test-Path -LiteralPath $cache)) {
        throw "未找到离线 npm 缓存: $cache"
    }

    New-Item -ItemType Directory -Path $prefix -Force | Out-Null

    $nodeHome = $null
    if ($UseSystemNode.IsPresent) {
        $npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
        if (-not $npm) {
            throw "未找到系统 npm。请移除 `-UseSystemNode`，或先安装 Node.js。"
        }
        $npmPath = $npm.Source
    }
    else {
        $nodeHome = Expand-BundledNode -Root $Root -TargetRoot $TargetRoot -Architecture $architecture -Manifest $Manifest
        $npmPath = Join-Path $nodeHome "npm.cmd"
        $env:Path = Add-PathSegment -PathValue $env:Path -Segment $nodeHome
    }

    $version = $Manifest.claudeCode.version
    Write-Step "正在从离线 npm 缓存安装 Claude Code $version"
    & $npmPath install --global --offline --cache $cache --prefix $prefix --omit=dev "@anthropic-ai/claude-code@$version" | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "离线安装失败，退出码 $LASTEXITCODE。"
    }

    $pathSegments = @($prefix)
    if ($nodeHome) {
        $pathSegments += $nodeHome
    }
    Add-UserPath -Segments $pathSegments

    return $prefix
}

function Set-DeepSeekEnvironment {
    param(
        [Parameter(Mandatory)][string]$ApiKey,
        [Parameter(Mandatory)][string]$Endpoint,
        [Parameter(Mandatory)][string]$ModelName,
        [Parameter(Mandatory)][string]$DefaultOpusModel,
        [Parameter(Mandatory)][string]$DefaultSonnetModel,
        [Parameter(Mandatory)][string]$DefaultHaikuModel,
        [Parameter(Mandatory)][string]$ClaudeSubagentModel,
        [Parameter(Mandatory)][string]$ClaudeEffortLevel,
        [Parameter(Mandatory)][bool]$Persist
    )

    $values = [ordered]@{
        ANTHROPIC_BASE_URL             = $Endpoint
        ANTHROPIC_AUTH_TOKEN           = $ApiKey
        ANTHROPIC_MODEL                = $ModelName
        ANTHROPIC_DEFAULT_OPUS_MODEL   = $DefaultOpusModel
        ANTHROPIC_DEFAULT_SONNET_MODEL = $DefaultSonnetModel
        ANTHROPIC_DEFAULT_HAIKU_MODEL  = $DefaultHaikuModel
        CLAUDE_CODE_SUBAGENT_MODEL     = $ClaudeSubagentModel
        CLAUDE_CODE_EFFORT_LEVEL       = $ClaudeEffortLevel
    }

    $removeValues = @("ANTHROPIC_API_KEY")
    Write-Step "正在配置 DeepSeek 环境变量"
    foreach ($name in $values.Keys) {
        [Environment]::SetEnvironmentVariable($name, $values[$name], "Process")
        if ($Persist) {
            [Environment]::SetEnvironmentVariable($name, $values[$name], "User")
        }
    }

    foreach ($name in $removeValues) {
        [Environment]::SetEnvironmentVariable($name, $null, "Process")
        if ($Persist) {
            [Environment]::SetEnvironmentVariable($name, $null, "User")
        }
    }

    if ($Persist) {
        Write-Host "DeepSeek 配置已保存到当前用户环境变量。"
        Write-Host "请重新打开一个终端，再运行 claude，以便 Windows 刷新环境变量。"
    }
    else {
        Write-Host "DeepSeek 配置仅对当前 PowerShell 进程生效。"
    }
}

function Test-ClaudeCommand {
    $claude = Get-Command claude -ErrorAction SilentlyContinue
    if (-not $claude) {
        Write-WarningLine "当前终端还看不到 claude 命令。"
        Write-WarningLine "请打开新终端后再运行: claude --version"
        return
    }

    Write-Step "正在验证 Claude Code"
    & $claude.Source --version
    if ($LASTEXITCODE -ne 0) {
        throw "claude --version 失败，退出码 $LASTEXITCODE。"
    }
}

function Install-IfNeeded {
    param(
        [Parameter(Mandatory)][string]$OfflineRootValue,
        [Parameter(Mandatory)][string]$InstallRootValue
    )

    $manifest = Read-OfflineManifest -Root $OfflineRootValue
    Test-OfflineChecksums -Root $OfflineRootValue -Manifest $manifest
    $installPrefix = Install-ClaudeCodeOffline -Root $OfflineRootValue -TargetRoot $InstallRootValue -Manifest $manifest
    Write-Host "Claude Code 已安装到: $installPrefix"
}

function Invoke-ClaudeLaunch {
    param(
        [Parameter(Mandatory)][string]$Mode,
        [Parameter(Mandatory)][string]$PermissionModeValue
    )

    switch ($Mode) {
        "Run" {
            Write-Step "正在启动 Claude Code"
            & claude --permission-mode $PermissionModeValue
        }
        "Skip" {
            Write-Step "已跳过 Claude Code 启动"
        }
        default {
            throw "Unknown launch mode: $Mode"
        }
    }
}

function Invoke-InteractiveWizard {
    param(
        [Parameter(Mandatory)][string]$OfflineRootValue,
        [Parameter(Mandatory)][string]$InstallRootValue
    )

    Write-Section "Claude Code 离线向导"
    $claudeInstalled = [bool](Get-Command claude -ErrorAction SilentlyContinue)
    if ($claudeInstalled) {
        Write-Host "当前机器已经可以使用 Claude Code。"
    }
    else {
        Write-WarningLine "Claude Code 还没有安装。"
        Install-IfNeeded -OfflineRootValue $OfflineRootValue -InstallRootValue $InstallRootValue
    }

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        throw "Claude Code 仍然不可用，安装后请重新打开终端再运行此脚本。"
    }

    $apiKey = Read-SecretValue -Prompt "请输入 DeepSeek API Token"
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        throw "必须提供 DeepSeek API Token。"
    }

    $profileChoice = Read-Choice -Prompt "请选择访问权限等级" -Options @(
        "保守模式（Ask for approval）",
        "平衡模式（Approve for me）",
        "全开模式（Full access）"
    ) -DefaultIndex 2

    $profile = Get-LaunchProfile -Choice $profileChoice
    Write-Host ""
    Write-Host ("已选择权限: {0} - {1}" -f $profile.Name, $profile.Description)

    $conversationChoice = Read-Choice -Prompt "请选择会话入口" -Options @(
        "新对话：从头开始",
        "继续上次：接着最近一次",
        "历史选择：从列表里挑"
    ) -DefaultIndex 1

    $conversation = Get-ConversationProfile -Choice $conversationChoice
    Write-Host ("已选择会话: {0} - {1}" -f $conversation.Name, $conversation.Description)

    $defaults = Get-DeepSeekDefaults
    Set-DeepSeekEnvironment `
        -ApiKey $apiKey `
        -Endpoint $defaults.BaseUrl `
        -ModelName $defaults.Model `
        -DefaultOpusModel $defaults.OpusModel `
        -DefaultSonnetModel $defaults.SonnetModel `
        -DefaultHaikuModel $defaults.HaikuModel `
        -ClaudeSubagentModel $defaults.SubagentModel `
        -ClaudeEffortLevel $defaults.EffortLevel `
        -Persist $false

    switch ($conversation.Mode) {
        "Continue" {
            Write-Step "正在继续上次对话"
            & claude --continue --permission-mode $profile.PermissionMode
        }
        "Resume" {
            Write-Step "正在打开历史会话选择器"
            & claude --resume --permission-mode $profile.PermissionMode
        }
        default {
            Invoke-ClaudeLaunch -Mode $profile.LaunchMode -PermissionModeValue $profile.PermissionMode
        }
    }
}

Start-InstallerLogging
try {
    if (-not (Test-IsWindows)) {
        throw "此安装脚本仅适用于 Windows。"
    }

    if ([string]::IsNullOrWhiteSpace($OfflineRoot)) {
        $OfflineRoot = Resolve-OfflineRoot -ScriptRootValue $ScriptRoot
    }

    if ($NonInteractive.IsPresent -and [string]::IsNullOrWhiteSpace($DeepSeekApiKey)) {
        $DeepSeekApiKey = Read-SecretValue -Prompt "请输入 DeepSeek API Token"
    }

    if (-not $NonInteractive.IsPresent) {
        Invoke-InteractiveWizard -OfflineRootValue $OfflineRoot -InstallRootValue $InstallRoot
        return
    }

    if ([string]::IsNullOrWhiteSpace($DeepSeekApiKey)) {
        $DeepSeekApiKey = Read-SecretValue -Prompt "请输入 DeepSeek API Token"
    }

    if ([string]::IsNullOrWhiteSpace($DeepSeekApiKey)) {
        throw "必须提供 DeepSeek API Token。"
    }

    if ($DeepSeekApiKey -notmatch "^sk-") {
        Write-WarningLine "Token 不是以 sk- 开头，仍将继续。"
    }

    $claudeInstalled = [bool](Get-Command claude -ErrorAction SilentlyContinue)
    if (-not $claudeInstalled) {
        if ($SkipClaudeInstall.IsPresent) {
            throw "Claude Code 未安装，但传入了 `-SkipClaudeInstall`。"
        }

        $manifest = Read-OfflineManifest -Root $OfflineRoot
        Test-OfflineChecksums -Root $OfflineRoot -Manifest $manifest

        if ($PSCmdlet.ShouldProcess("Claude Code", "install from offline package")) {
            $installPrefix = Install-ClaudeCodeOffline -Root $OfflineRoot -TargetRoot $InstallRoot -Manifest $manifest
            Write-Host "Claude Code 已安装到: $installPrefix"
        }

        $claudeInstalled = [bool](Get-Command claude -ErrorAction SilentlyContinue)
    }

    if ($PSCmdlet.ShouldProcess("current user environment", "configure DeepSeek variables")) {
        Set-DeepSeekEnvironment `
            -ApiKey $DeepSeekApiKey `
            -Endpoint $BaseUrl `
            -ModelName $Model `
            -DefaultOpusModel $OpusModel `
            -DefaultSonnetModel $SonnetModel `
            -DefaultHaikuModel $HaikuModel `
            -ClaudeSubagentModel $SubagentModel `
            -ClaudeEffortLevel $EffortLevel `
            -Persist $false
    }

    if (-not $NoVerify.IsPresent) {
        Test-ClaudeCommand
    }

    switch ($ConversationMode) {
        "Continue" {
            Write-Step "正在继续上次对话"
            & claude --continue --permission-mode ($(if ($PermissionMode) { $PermissionMode } else { "acceptEdits" }))
        }
        "Resume" {
            throw '历史选择仅适用于交互向导；请直接运行脚本并在菜单里选择“历史选择”。'
        }
        default {
            Invoke-ClaudeLaunch -Mode $LaunchMode -PermissionModeValue ($(if ($PermissionMode) { $PermissionMode } else { "acceptEdits" }))
        }
    }
    Write-Step "完成"
}
catch {
    Write-Host ""
    Write-Host "发生错误，脚本已中止。" -ForegroundColor Red
    if ($script:InstallerLogPath) {
        Write-Host "日志文件: $script:InstallerLogPath" -ForegroundColor Yellow
    }
    Write-Error $_
    if (-not $NonInteractive.IsPresent) {
        try {
            Read-Host "按回车退出" | Out-Null
        }
        catch {
        }
    }
    throw
}
finally {
    Stop-InstallerLogging
}
