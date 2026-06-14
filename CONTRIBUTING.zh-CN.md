# 贡献指南

语言：简体中文 | [English](CONTRIBUTING.md)

感谢你帮助改进这个安装脚本。

## 工作流

1. Bug、功能建议或文档修改请先开 Issue。
2. Pull Request 尽量保持范围清晰，方便审查。
3. 不要提交真实 API Key、Token、带有密钥的截图或本机凭据。

## 开发验证

提交 PR 前，请先执行 dry run：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install-claude-code-deepseek.ps1 `
  -DeepSeekApiKey sk-test `
  -SkipClaudeInstall `
  -NoPersist `
  -NoVerify `
  -WhatIf
```

## 提交信息

使用 Conventional Commits：

```text
feat: add winget install option
fix: handle missing claude command after install
docs: update DeepSeek setup notes
```

可选：

```powershell
git config commit.template .gitmessage
```

## PR 自检

- 改动范围只涉及安装脚本、文档或项目元数据。
- dry run 可以通过。
- 行为变化已更新文档。
- 没有提交任何密钥。
