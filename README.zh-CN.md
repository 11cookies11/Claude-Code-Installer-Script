# Claude Code 离线安装脚本

这是一个面向 Windows 的 Claude Code 离线安装与 DeepSeek 配置脚本。

语言：简体中文 | [English](README.md)

## 这个脚本做什么

本项目采用两步流程：

1. 在有网络的 Windows 机器上运行 `prepare-offline-package.ps1`
2. 将整个仓库连同 `vendor/` 目录复制到离线 Windows 机器，再运行 `install-claude-code-deepseek.ps1`

安装时只需要输入 DeepSeek 的 `ANTHROPIC_AUTH_TOKEN`。Claude Code、Windows 平台包、Node.js、校验文件和安装元数据都会提前准备好。

主入口脚本默认以向导模式运行：它会先检测 `claude` 是否已安装，缺失时从离线包安装，然后只让你输入 token，再从一个简短菜单里选启动预设，最后直接启动 Claude Code。

## 联网准备离线包

在有网络且已安装 npm 的机器上运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\prepare-offline-package.ps1
```

脚本会生成：

```text
vendor/
  manifest.json
  checksums.sha256
  npm-cache/
  node/
```

默认会同时准备 `win32-x64` 和 `win32-arm64` 资源。

常用选项：

```powershell
.\prepare-offline-package.ps1 -ClaudeCodeVersion latest
.\prepare-offline-package.ps1 -ClaudeCodeVersion 2.1.177 -Platforms x64
.\prepare-offline-package.ps1 -SkipNode
.\prepare-offline-package.ps1 -Force
```

## 离线安装

将整个仓库复制到离线 Windows 机器后运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-claude-code-deepseek.ps1
```

脚本会先检查 Claude Code 是否已安装；如果没有，就直接从离线包安装。然后它只会询问 DeepSeek token，再让你从以下访问权限等级里选一个：

1. 保守模式（Ask for approval）
2. 平衡模式（Approve for me）
3. 全开模式（Full access）

接着再从以下会话入口里选一个：

1. 新对话
2. 继续上次
3. 历史选择

无论选哪一个，DeepSeek 默认值都固定为：

```powershell
$env:ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
$env:ANTHROPIC_AUTH_TOKEN="<你输入的 token>"
$env:ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
$env:CLAUDE_CODE_EFFORT_LEVEL="max"
```

安装完成后，建议重新打开终端，然后运行：

```powershell
claude --version
claude doctor
```

如果你要自动化运行，可以加 `-NonInteractive`。

默认向导里，用户只需要输入 DeepSeek token，然后从三个访问权限等级和三个会话入口里各选一次。

非交互模式示例：

```powershell
.\install-claude-code-deepseek.ps1 -NonInteractive -ConversationMode Continue -PermissionMode acceptEdits -DeepSeekApiKey "sk-..."
```

## GitHub Release 包

如果你下载的是 GitHub Release 的压缩包，解压后根目录只会看到：

- `install-claude-code-deepseek.ps1`
- `src/`

直接在解压后的根目录运行安装脚本即可。脚本会自动识别 `src\vendor` 里的最新离线资源，不需要你手工指定路径。

`src/` 目录里会放：

- `README.zh-CN.md`
- `README.md`
- `vendor/`

release workflow 会在打包时重新生成 `vendor/`，所以发布包会带上最新的离线资源。

## DeepSeek Token 怎么获取

这里脚本里说的 token，就是 DeepSeek 控制台里创建出来的 API Key。你可以按下面一步一步来：

1. 打开 DeepSeek 控制台并登录你的账号。
2. 在页面里找到 `API Keys`、`API 密钥` 或 `密钥管理` 入口，点进去。
3. 点击 `New Key`、`创建密钥` 或类似按钮，新建一个 Key。
4. 如果页面让你填写备注，可以随便写一个方便自己识别的名字，比如 `Claude Code`。
5. 密钥创建成功后，页面通常只会显示一次完整值，立刻复制它。
6. 复制出来的值一般会以 `sk-` 开头，这个就是脚本要输入的 `ANTHROPIC_AUTH_TOKEN`。
7. 如果页面支持下载或保存，请只保存到你自己安全的位置，不要发到聊天记录里，也不要提交到仓库。

如果你以后忘了这个值，通常需要回到 DeepSeek 控制台重新创建一个新的 Key。把它当成密码保管就行。

## 安装脚本参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `-DeepSeekApiKey` | 提示输入 | DeepSeek API Token。省略时脚本会安全提示输入。 |
| `-OfflineRoot` | `.\vendor` | `prepare-offline-package.ps1` 生成的离线资源目录。 |
| `-InstallRoot` | `%LOCALAPPDATA%\ClaudeCodeOffline` | 本地安装目录，用于放置内置 Node.js 和 Claude Code npm 前缀。 |
| `-UseSystemNode` | false | 使用系统 npm，而不是离线包里的 Node.js。 |
| `-SkipClaudeInstall` | false | 只配置 DeepSeek 环境变量，不安装 Claude Code。 |
| `-SkipChecksum` | false | 跳过 `checksums.sha256` 校验。 |
| `-Model` | `deepseek-v4-pro[1m]` | 非交互模式下写入 `ANTHROPIC_MODEL`。 |
| `-OpusModel` | `deepseek-v4-pro[1m]` | 非交互模式下写入 `ANTHROPIC_DEFAULT_OPUS_MODEL`。 |
| `-SonnetModel` | `deepseek-v4-pro[1m]` | 非交互模式下写入 `ANTHROPIC_DEFAULT_SONNET_MODEL`。 |
| `-HaikuModel` | `deepseek-v4-flash` | 非交互模式下写入 `ANTHROPIC_DEFAULT_HAIKU_MODEL`。 |
| `-SubagentModel` | `deepseek-v4-flash` | 非交互模式下写入 `CLAUDE_CODE_SUBAGENT_MODEL`。 |
| `-EffortLevel` | `max` | 非交互模式下写入 `CLAUDE_CODE_EFFORT_LEVEL`。 |
| `-NoPersist` | false | 仅影响 Claude Code 安装后的 PATH 是否写入用户环境变量。 |
| `-NoVerify` | false | 跳过最后的 `claude --version` 检查。 |
| `-LaunchMode` | `Run` | 非交互模式下的新建对话启动方式，可选 `Run` 或 `Skip`。 |
| `-ConversationMode` | `New` | 非交互模式下的会话入口，可选 `New` 或 `Continue`；`Resume` 仅在交互菜单里使用。 |
| `-PermissionMode` | `acceptEdits` | 非交互模式下的权限预设，可选 `default`、`acceptEdits` 或 `bypassPermissions`。 |
| `-NonInteractive` | false | 跳过向导，直接使用参数运行。 |

## 配置的环境变量

脚本会配置：

- `ANTHROPIC_BASE_URL`
- `ANTHROPIC_AUTH_TOKEN`
- `ANTHROPIC_MODEL`
- `ANTHROPIC_DEFAULT_OPUS_MODEL`
- `ANTHROPIC_DEFAULT_SONNET_MODEL`
- `ANTHROPIC_DEFAULT_HAIKU_MODEL`
- `CLAUDE_CODE_SUBAGENT_MODEL`
- `CLAUDE_CODE_EFFORT_LEVEL`

脚本默认只写入 `ANTHROPIC_AUTH_TOKEN`，不会同时设置 `ANTHROPIC_API_KEY`，这样可以避免 Claude Code 提示双鉴权冲突。

## 离线边界

`install-claude-code-deepseek.ps1` 不会联网下载 Claude Code、Node.js 或 npm 包。它只读取 `vendor/` 本地文件，并接收你输入的 DeepSeek token。

## 安全说明

如果选择持久化，token 会保存到当前 Windows 用户的环境变量中。不要把密钥提交到仓库。如果 token 泄露，请立刻去 DeepSeek 控制台轮换。

生成的 `vendor/` 目录可能比较大。除非你明确要分发完整离线包，否则不要把它提交到仓库。

## 许可证

见 `LICENSE`。
