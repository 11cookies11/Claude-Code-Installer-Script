# Claude Code 发布包使用说明

这个文件夹和根目录下的 `install-claude-code-deepseek.ps1` 是发布包的标准结构。

## 打开方式

解压后直接在发布包根目录运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-claude-code-deepseek.ps1
```

脚本会自动识别 `src\vendor`，所以你不需要手工指定离线资源路径。

## 你会看到什么

发布包根目录只有：

- `install-claude-code-deepseek.ps1`
- `src/`

`src/` 里包含：

- `README.zh-CN.md`
- `README.md`
- `vendor/`

其中 `vendor/` 是由 release workflow 重新打包出来的最新离线资源。

## 默认交互流程

脚本启动后，通常只需要你输入 DeepSeek Token，然后按顺序选两项：

1. 访问权限等级
2. 会话入口

如果你想直接自动化运行，也可以传 `-NonInteractive`。

## 常用验证

```powershell
claude --version
claude doctor
```

## DeepSeek Token 怎么获取

这里脚本里说的 token，就是 DeepSeek 控制台里创建出来的 API Key。你可以按这个最短路径来拿：

1. 打开 DeepSeek 控制台并登录
2. 进入 API Keys 或密钥管理页面
3. 新建一个 Key
4. 复制生成的密钥值，通常以 `sk-` 开头

这个值就是脚本启动时要输入的 `ANTHROPIC_AUTH_TOKEN`。请把它当成密码一样保管，不要提交到仓库，也不要发到聊天记录里。
