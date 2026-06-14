# Security Policy

Language: English | [Simplified Chinese](SECURITY.zh-CN.md)

## Reporting a Vulnerability

Please do not open a public issue for token leaks, command injection risks, or
other sensitive security problems. Report them privately to the repository
maintainer.

Include:

- Affected script version or commit.
- Steps to reproduce.
- Potential impact.
- Relevant logs with all secrets removed.

## Secret Handling

This repository must never contain real DeepSeek keys or Claude Code tokens. If
a token is accidentally committed or shared, rotate it immediately.
