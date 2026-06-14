#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

function Assert-True {
    param(
        [Parameter(Mandatory)][bool]$Condition,
        [Parameter(Mandatory)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Test-PowerShellSyntax {
    param([Parameter(Mandatory)][string]$Path)

    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors) {
        $message = ($errors | ForEach-Object { $_.Message }) -join "`n"
        throw "PowerShell syntax check failed: $Path`n$message"
    }
}

function Set-FakeClaudeCommand {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Remove-Item Function:\claude -ErrorAction SilentlyContinue
    }

    function global:claude {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Args
        )

        if ($env:TEST_CLAUDE_ENV_LOG) {
            Get-ChildItem Env: |
                Sort-Object Name |
                ForEach-Object { "{0}={1}" -f $_.Name, $_.Value } |
                Set-Content -LiteralPath $env:TEST_CLAUDE_ENV_LOG -Encoding ASCII
        }

        if ($env:TEST_CLAUDE_ARG_LOG) {
            "ARGS=$($Args -join ' ')" | Set-Content -LiteralPath $env:TEST_CLAUDE_ARG_LOG -Encoding ASCII
        }

        return
    }
}

Test-PowerShellSyntax -Path (Join-Path $Root "install-claude-code-deepseek.ps1")
Test-PowerShellSyntax -Path (Join-Path $Root "prepare-offline-package.ps1")

$tempRoot = Join-Path $env:TEMP "claude-code-installer-smoke"
Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

Set-FakeClaudeCommand

$envLog = Join-Path $tempRoot "claude-env.log"
$argLog = Join-Path $tempRoot "claude-args.log"

$env:TEST_CLAUDE_ENV_LOG = $envLog
$env:TEST_CLAUDE_ARG_LOG = $argLog

Write-Host "==> Running continue-mode smoke test" -ForegroundColor Cyan
& (Join-Path $Root "install-claude-code-deepseek.ps1") `
    -NonInteractive `
    -SkipClaudeInstall `
    -NoVerify `
    -DeepSeekApiKey "sk-test-token" `
    -ConversationMode Continue `
    -PermissionMode default
if (-not $?) {
    throw "install-claude-code-deepseek.ps1 reported a failure."
}

Assert-True (Test-Path -LiteralPath $envLog) "Claude env log was not created."
Assert-True (Test-Path -LiteralPath $argLog) "Claude arg log was not created."

$envContent = Get-Content -LiteralPath $envLog -Raw
$argContent = Get-Content -LiteralPath $argLog -Raw

Assert-True ($envContent -match "ANTHROPIC_AUTH_TOKEN=sk-test-token") "ANTHROPIC_AUTH_TOKEN was not found in the env log."
Assert-True ($envContent -notmatch "ANTHROPIC_API_KEY=") "ANTHROPIC_API_KEY should not appear in the env log."
Assert-True ($argContent -match "ARGS=--continue --permission-mode default") "Continue-mode arguments were not captured correctly."
Assert-True ($envContent -match "ANTHROPIC_BASE_URL=https://api\.deepseek\.com/anthropic") "DeepSeek base URL was not found in the env log."

Remove-Item -LiteralPath $envLog, $argLog -Force

Write-Host "==> Running skip-launch smoke test" -ForegroundColor Cyan
& (Join-Path $Root "install-claude-code-deepseek.ps1") `
    -NonInteractive `
    -SkipClaudeInstall `
    -NoVerify `
    -DeepSeekApiKey "sk-test-token" `
    -ConversationMode New `
    -LaunchMode Skip `
    -PermissionMode acceptEdits
if (-not $?) {
    throw "install-claude-code-deepseek.ps1 reported a failure."
}

Assert-True (-not (Test-Path -LiteralPath $argLog)) "Claude should not be called when launch is skipped."

Write-Host "Smoke tests passed" -ForegroundColor Green
