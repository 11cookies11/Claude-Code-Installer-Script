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

这里脚本里说的 token，就是 DeepSeek 控制台里创建出来的 API Key。你可以按下面一步一步来：

1. 打开 DeepSeek 控制台并登录你的账号。
2. 在页面里找到 `API Keys`、`API 密钥` 或 `密钥管理` 入口，点进去。
3. 点击 `New Key`、`创建密钥` 或类似按钮，新建一个 Key。
4. 如果页面让你填写备注，可以随便写一个方便自己识别的名字，比如 `Claude Code`。
5. 密钥创建成功后，页面通常只会显示一次完整值，立刻复制它。
6. 复制出来的值一般会以 `sk-` 开头，这个就是脚本要输入的 `ANTHROPIC_AUTH_TOKEN`。
7. 如果页面支持下载或保存，请只保存到你自己安全的位置，不要发到聊天记录里，也不要提交到仓库。

如果你以后忘了这个值，通常需要回到 DeepSeek 控制台重新创建一个新的 Key。把它当成密码保管就行。

## 日志在哪里

脚本启动后会自动写日志到：

```text
%TEMP%\Claude-Code-Installer-Script\logs\install-YYYYMMDD-HHMMSS.log
```

如果脚本出错，窗口里也会提示这份日志的具体路径。你可以先打开这份日志看最后几行，通常就能知道为什么会退出。
