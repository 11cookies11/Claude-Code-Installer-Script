# Claude Code Offline Installer Script

Windows offline installer for Claude Code with DeepSeek API environment
configuration.

Language: English | [Simplified Chinese](README.zh-CN.md)

## What It Does

This repository uses a two-step workflow:

1. Run `prepare-offline-package.ps1` on an online Windows machine.
2. Copy this repository, including `vendor/`, to the offline Windows machine and
   run `install-claude-code-deepseek.ps1`.

Only the DeepSeek token is provided at install time. Claude Code, its Windows
platform package, Node.js, checksums, and install metadata are prepared ahead of
time.

The main entry point opens as a wizard by default. It detects whether `claude`
is already installed, installs it from the offline bundle when needed, asks for
only the DeepSeek token, lets you pick one launch preset, and then starts
Claude Code.

## Prepare Online Package

On a machine with internet access and npm available:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\prepare-offline-package.ps1
```

The script creates:

```text
vendor/
  manifest.json
  checksums.sha256
  npm-cache/
  node/
```

By default it prepares both `win32-x64` and `win32-arm64` resources.

Useful options:

```powershell
.\prepare-offline-package.ps1 -ClaudeCodeVersion latest
.\prepare-offline-package.ps1 -ClaudeCodeVersion 2.1.177 -Platforms x64
.\prepare-offline-package.ps1 -SkipNode
.\prepare-offline-package.ps1 -Force
```

## Install Offline

Copy the whole repository to the offline Windows machine, then run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-claude-code-deepseek.ps1 -DeepSeekApiKey "sk-..."
```

Open a new terminal after the script finishes, then verify:

```powershell
claude --version
claude doctor
```

For automation or scripted use, add `-NonInteractive`.

In the default wizard, the only inputs are the DeepSeek token, one access
level, and one conversation entry:

1. Ask for approval
2. Approve for me
3. Full access

Then choose one conversation entry:

1. New chat
2. Continue last
3. Choose history

Non-interactive example:

```powershell
.\install-claude-code-deepseek.ps1 -NonInteractive -ConversationMode Continue -PermissionMode acceptEdits -DeepSeekApiKey "sk-..."
```

## GitHub Release Package

If you download the GitHub Release archive, the extracted root contains only:

- `install-claude-code-deepseek.ps1`
- `src/`

Run the installer from the extracted root. It automatically detects
`src\vendor`, so you do not need to pass an offline resource path by hand.

The `src/` folder contains:

- `README.zh-CN.md`
- `README.md`
- `vendor/`

The release workflow regenerates `vendor/` at publish time, so the archive
always carries fresh offline resources.

## How to Get the DeepSeek Token

The token mentioned by the script is the API key created in the DeepSeek
console. Follow these steps:

1. Open the DeepSeek console and sign in to your account.
2. Find the `API Keys`, `API Key`, `Key Management`, or similar page.
3. Click `New Key`, `Create Key`, or the matching button to generate one.
4. If a note or label field appears, you can name it something easy to recognize,
   such as `Claude Code`.
5. After the key is created, the full value is usually shown only once, so copy
   it right away.
6. The copied value usually starts with `sk-`; that is the value the script
   asks for as `ANTHROPIC_AUTH_TOKEN`.
7. If the console offers a save or download option, store it only in a place
   you control, not in chat logs or source control.

If you lose the value later, you will usually need to create a new key in the
DeepSeek console. Treat it like a password.

## Install Parameters

| Parameter | Default | Description |
| --- | --- | --- |
| `-DeepSeekApiKey` | prompt | DeepSeek API key. If omitted, the script prompts securely. |
| `-OfflineRoot` | `.\vendor` | Directory produced by `prepare-offline-package.ps1`. |
| `-InstallRoot` | `%LOCALAPPDATA%\ClaudeCodeOffline` | Local install directory for bundled Node.js and Claude Code npm prefix. |
| `-UseSystemNode` | false | Use system npm instead of bundled Node.js. |
| `-SkipClaudeInstall` | false | Only configure DeepSeek environment variables. |
| `-SkipChecksum` | false | Skip `checksums.sha256` validation. |
| `-Model` | `deepseek-v4-pro[1m]` | Value written to `ANTHROPIC_MODEL` in non-interactive mode. |
| `-OpusModel` | `deepseek-v4-pro[1m]` | Value written to `ANTHROPIC_DEFAULT_OPUS_MODEL` in non-interactive mode. |
| `-SonnetModel` | `deepseek-v4-pro[1m]` | Value written to `ANTHROPIC_DEFAULT_SONNET_MODEL` in non-interactive mode. |
| `-HaikuModel` | `deepseek-v4-flash` | Value written to `ANTHROPIC_DEFAULT_HAIKU_MODEL` in non-interactive mode. |
| `-SubagentModel` | `deepseek-v4-flash` | Value written to `CLAUDE_CODE_SUBAGENT_MODEL` in non-interactive mode. |
| `-EffortLevel` | `max` | Value written to `CLAUDE_CODE_EFFORT_LEVEL` in non-interactive mode. |
| `-NoPersist` | false | Only affects whether the Claude Code install path is written to the user PATH. |
| `-NoVerify` | false | Skip the final `claude --version` check. |
| `-LaunchMode` | `Run` | `Run` or `Skip` in non-interactive mode for a new chat. |
| `-ConversationMode` | `New` | Non-interactive conversation entry. Use `New` or `Continue`; `Resume` is only available in the interactive menu. |
| `-PermissionMode` | `acceptEdits` | Non-interactive permission preset. Use `default`, `acceptEdits`, or `bypassPermissions`. |
| `-NonInteractive` | false | Bypass the wizard and use parameters directly. |

## Environment Variables

The script configures:

- `ANTHROPIC_BASE_URL`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_MODEL`
- `ANTHROPIC_DEFAULT_OPUS_MODEL`
- `ANTHROPIC_DEFAULT_SONNET_MODEL`
- `ANTHROPIC_DEFAULT_HAIKU_MODEL`
- `CLAUDE_CODE_SUBAGENT_MODEL`
- `CLAUDE_CODE_EFFORT_LEVEL`

The script only sets `ANTHROPIC_AUTH_TOKEN` by default and leaves
`ANTHROPIC_API_KEY` unset to avoid Claude Code's dual-auth warning.

## Offline Boundary

`install-claude-code-deepseek.ps1` does not download Claude Code, Node.js, or
packages. It reads local files from `vendor/` and only accepts the DeepSeek token
from the user.

## Security Notes

When persistence is enabled, the token is stored in the current Windows user's
environment variables. Do not commit secrets to this repository. Rotate the
DeepSeek token immediately if it is accidentally shared.

Generated `vendor/` contents can be large. Keep them out of source control unless
you intentionally publish a full offline bundle.

## License

See `LICENSE`.
