# Contributing

Language: English | [Simplified Chinese](CONTRIBUTING.zh-CN.md)

Thanks for helping improve this installer.

## Workflow

1. Open an issue for bugs, feature requests, or documentation changes.
2. Keep pull requests focused and easy to review.
3. Do not include real API keys, tokens, screenshots with secrets, or local
   machine-specific credentials.

## Development

Run the script in dry-run mode before opening a PR:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-claude-code-deepseek.ps1 `
  -DeepSeekApiKey sk-test `
  -SkipClaudeInstall `
  -NoPersist `
  -NoVerify `
  -WhatIf
```

## Commit Messages

Use Conventional Commits:

```text
feat: add winget install option
fix: handle missing claude command after install
docs: update DeepSeek setup notes
```

Optional:

```powershell
git config commit.template .gitmessage
```

## Pull Request Checklist

- The change is scoped to the installer, documentation, or project metadata.
- The dry run succeeds.
- Documentation is updated when behavior changes.
- No secrets are committed.
