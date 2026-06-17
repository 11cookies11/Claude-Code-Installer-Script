# 我做了一个 Claude Code Windows 离线安装脚本：一键打包、离线安装、自动接入 DeepSeek

> 文章目的：让读者知道这个项目解决什么问题、为什么值得用、怎么快速上手。  
> 项目地址：https://github.com/11cookies11/Claude-Code-Installer-Script

---

## 封面图

**插图位：`docs/assets/comics/00-cover.png`**

**画面描述：** 一个程序员坐在 Windows 电脑前，屏幕上是 `npm install failed`、`proxy timeout`、`optional dependency missing` 等错误。旁边一个可爱的 AI 机器人递过来一个写着 `Offline Installer` 的工具箱。

**AI 绘图提示词：**

> 漫画风格，年轻程序员在 Windows 电脑前调试命令行，屏幕上有 npm error、proxy error、permission denied、optional dependency missing 等报错，旁边一个可爱的 AI 机器人递出写着 Offline Installer 的工具箱，明亮科技感，轻松幽默，中文互联网技术文章封面，16:9

---

## 一、为什么我要做这个项目？

最近我在 Windows 上折腾 Claude Code 的安装和使用时，发现真正麻烦的地方并不只是“运行一个安装命令”。

官方安装方式本身已经很完整。但在真实使用场景里，经常会遇到这些问题：

```text
npm optional dependency 拉不下来
代理环境混乱
公司、实验室、内网机器不能随便联网
一台机器装好了，另一台机器又要重来
Node.js 版本、npm cache、环境变量都要手动处理
```

这些问题单独看都不难，但它们叠加在一起，就会让安装过程变得很不稳定。

于是我做了一个小工具：

> **Claude Code Offline Installer Script**  
> 一个面向 Windows 的 Claude Code 离线安装与 DeepSeek 配置脚本。

它的目标很简单：

> **在一台有网的 Windows 机器上提前准备好 Claude Code、Node.js、npm 缓存和校验文件，然后复制到另一台 Windows 机器上离线安装，并自动配置 DeepSeek API。**

---

## 插图 1：安装失败的日常

**插图位：`docs/assets/comics/01-install-pain.png`**

**画面描述：** 程序员在四台 Windows 电脑前重复安装 Claude Code：第一台成功，第二台卡 npm，第三台卡代理，第四台缺 optional dependency。

**AI 绘图提示词：**

> 漫画风，程序员在四台 Windows 电脑前安装开发工具，第一台显示 success，第二台显示 npm error，第三台显示 proxy timeout，第四台显示 optional dependency missing，表情崩溃但幽默，技术文章插图，扁平明亮配色，16:9

---

## 二、我想解决的不是“安装”，而是“可复现安装”

很多工具“能装上”并不难，难的是：

```text
今天能装，明天还能不能装？
我这台能装，另一台还能不能装？
有网络能装，没网络还能不能装？
我自己能装，别人能不能照着装？
```

这就是我写这个项目的原因。

我希望整个流程可以变成：

```text
联网机器：准备离线包
离线机器：运行安装脚本
输入 token：直接启动 Claude Code
```

所以这个项目采用了两步流程：

```powershell
.\prepare-offline-package.ps1
```

负责在联网机器上准备资源。

```powershell
.\install-claude-code-deepseek.ps1
```

负责在目标机器上离线安装和配置。

---

## 插图 2：两段式安装流程

**插图位：`docs/assets/comics/02-two-step-workflow.png`**

**画面描述：** 左边是联网 Windows 电脑，运行 `prepare-offline-package.ps1` 生成 `vendor/`；右边是离线 Windows 电脑，运行 `install-claude-code-deepseek.ps1` 完成安装。

**AI 绘图提示词：**

> 漫画风技术流程图，左边一台有网络图标的 Windows 电脑运行 prepare-offline-package.ps1，生成一个写着 vendor 的离线包，右边一台断网的 Windows 电脑运行 install-claude-code-deepseek.ps1 并成功启动 Claude Code，中间用 U 盘或文件夹传递，清晰简洁，16:9

---

## 三、这个脚本到底做了什么？

简单说，它做了四件事：

```text
1. 准备 Claude Code 离线 npm 缓存
2. 下载并打包 Windows 版 Node.js
3. 生成 manifest.json 和 checksums.sha256
4. 离线安装后自动配置 DeepSeek API 环境变量
```

联网准备阶段会生成：

```text
vendor/
  manifest.json
  checksums.sha256
  npm-cache/
  node/
```

这个 `vendor/` 就是离线安装所需的核心资源目录。

如果你只想用默认配置，在联网 Windows 机器上运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\prepare-offline-package.ps1
```

脚本会自动准备默认资源。

---

## 插图 3：离线包工厂

**插图位：`docs/assets/comics/03-offline-package-factory.png`**

**画面描述：** 一个自动化工厂流水线：左边输入 Claude Code、Node.js、npm package、checksum，右边输出一个完整的 `vendor/` 离线安装包。

**AI 绘图提示词：**

> 漫画风自动化工厂，传送带左边有 Claude Code、Node.js、npm package、checksum 文件图标，右边打包成一个写着 vendor 的离线安装箱，小机器人在流水线上检查文件，技术感，可爱，16:9

---

## 四、离线安装：复制过去，运行脚本

准备好离线包之后，把整个仓库复制到目标 Windows 机器上，然后运行：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-claude-code-deepseek.ps1
```

安装脚本会自动做几件事：

```text
检查当前机器是否已经有 claude 命令
如果没有，就从 vendor 离线安装 Claude Code
读取 manifest.json
校验 checksums.sha256
配置 DeepSeek 环境变量
启动 Claude Code
```

也就是说，目标机器不需要重新联网下载 npm 包。

---

## 插图 4：U 盘拷过去就能装

**插图位：`docs/assets/comics/04-copy-to-offline-machine.png`**

**画面描述：** 一个程序员把写着 `vendor` 的 U 盘插到另一台没有网络的电脑上，电脑弹出 `Ready to install`。

**AI 绘图提示词：**

> 漫画风，程序员把写着 vendor offline package 的 U 盘插入一台没有网络图标的 Windows 电脑，屏幕显示 Ready to install，旁边有离线小岛和断网符号，轻松技术风，明亮配色，16:9

---

## 五、安装时只需要输入 DeepSeek Token

我不希望用户面对一堆环境变量，所以安装脚本默认是向导模式。

你只需要输入 DeepSeek API Token，然后选两个东西：

```text
1. 访问权限等级
2. 会话入口
```

默认会配置这些环境变量：

```powershell
ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
ANTHROPIC_AUTH_TOKEN=<你的 DeepSeek Token>
ANTHROPIC_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_OPUS_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_SONNET_MODEL=deepseek-v4-pro[1m]
ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
CLAUDE_CODE_EFFORT_LEVEL=max
```

这里的 token 就是你在 DeepSeek 控制台创建的 API Key。它应该像密码一样保管，不要提交到 GitHub，也不要发到聊天记录或公开截图里。

---

## 插图 5：只输入一次 Token

**插图位：`docs/assets/comics/05-token-key.png`**

**画面描述：** 一把写着 `sk-token` 的钥匙从 DeepSeek 控制台飞到 PowerShell 窗口，旁边写着“只输入一次 token”。

**AI 绘图提示词：**

> 漫画风，一把写着 sk-token 的钥匙从 DeepSeek 控制台飞向 PowerShell 终端窗口，终端中有“请输入 DeepSeek API Token”，画面简洁，强调安全输入，科技感，可爱，16:9

---

## 六、三种权限模式：保守、平衡、全开

安装向导里有三个权限等级：

```text
1. 保守模式：Ask for approval
2. 平衡模式：Approve for me
3. 全开模式：Full access
```

对应 Claude Code 的权限参数：

```text
default
acceptEdits
bypassPermissions
```

我的建议是：

```text
第一次使用：选保守模式
日常开发：选平衡模式
完全信任当前目录和脚本时：再考虑全开模式
```

全开模式确实很爽，但也要谨慎。它更适合你已经确认项目目录可信、脚本可信、没有敏感文件乱放的环境。

---

## 插图 6：三种权限模式

**插图位：`docs/assets/comics/06-permission-modes.png`**

**画面描述：** 三个按钮：保守模式是戴头盔的小机器人，平衡模式是拿工具箱的小机器人，全开模式是火箭喷射的小机器人。

**AI 绘图提示词：**

> 漫画风，三个并排的 AI 小机器人按钮，左边保守模式戴安全头盔，中间平衡模式拿工具箱，右边全开模式像火箭一样冲出去，分别标注 Ask for approval、Approve for me、Full access，技术产品说明插图，16:9

---

## 七、三种会话入口：新对话、继续上次、选择历史

启动 Claude Code 时，我也做了一个简单菜单：

```text
1. 新对话
2. 继续上次
3. 历史选择
```

也就是：

```powershell
claude
claude --continue
claude --resume
```

这个功能不复杂，但对普通用户很友好。

很多人第一次用 Claude Code 时，不知道该直接开新会话，还是继续之前的任务。脚本把它做成菜单，减少记忆成本。

---

## 插图 7：三扇会话入口门

**插图位：`docs/assets/comics/07-conversation-doors.png`**

**画面描述：** 一个漫画角色站在三扇门前：新对话、继续上次、历史选择。每扇门后面都有不同的终端聊天窗口。

**AI 绘图提示词：**

> 漫画风，程序员角色站在三扇发光的门前，门上分别写着 新对话、继续上次、历史选择，门后是不同的 Claude Code 终端会话窗口，轻松幽默，技术教程插图，16:9

---

## 八、如果你想自动化，也支持非交互模式

如果你不是手动安装，而是想写进自己的部署流程，可以使用非交互模式：

```powershell
.\install-claude-code-deepseek.ps1 `
  -NonInteractive `
  -ConversationMode Continue `
  -PermissionMode acceptEdits `
  -DeepSeekApiKey "sk-..."
```

常用参数包括：

```text
-DeepSeekApiKey       DeepSeek API Token
-OfflineRoot          离线资源目录
-InstallRoot          安装目录
-UseSystemNode        使用系统 Node.js
-SkipClaudeInstall    只配置环境变量
-SkipChecksum         跳过校验
-NoVerify             跳过 claude --version 检查
-ConversationMode     New / Continue
-PermissionMode       default / acceptEdits / bypassPermissions
-NonInteractive       非交互模式
```

---

## 插图 8：机器人自动部署

**插图位：`docs/assets/comics/08-noninteractive-bot.png`**

**画面描述：** 一个机器人在夜间自动执行脚本，旁边有 `CI / Batch / NonInteractive` 标签。

**AI 绘图提示词：**

> 漫画风，夜晚的电脑机房，一个小机器人自动运行 PowerShell 脚本，屏幕上显示 NonInteractive、CI、Batch Mode，旁边有绿色成功勾，适合技术文章，16:9

---

## 九、为什么我加了日志和校验？

安装脚本最怕的问题是：

```text
失败了，但不知道为什么失败
包坏了，但继续安装
路径错了，但错误信息不清楚
```

所以这个项目做了两层处理。

第一，自动写日志：

```text
%TEMP%\Claude-Code-Installer-Script\logs\install-YYYYMMDD-HHMMSS.log
```

如果脚本失败，可以先看日志最后几行。

第二，校验离线包：

```text
checksums.sha256
```

安装前会逐个计算文件 hash。如果文件不存在或者 hash 不匹配，会直接中止。

这对离线包很重要。因为离线包往往要经过 U 盘、网盘、压缩包、Release 下载，中间任何一步损坏，都会导致后面出现奇怪问题。

---

## 插图 9：侦探机器人查日志

**插图位：`docs/assets/comics/09-log-detective.png`**

**画面描述：** 一个侦探小机器人拿着放大镜检查 log 文件和 checksum 文件，旁边有损坏的 zip 包。

**AI 绘图提示词：**

> 漫画风，侦探 AI 小机器人拿着放大镜检查 install log 和 checksums.sha256 文件，旁边有一个损坏的 zip 包和红色警告标志，技术排错主题，幽默清晰，16:9

---

## 十、发布包也自动化了

我还加了一个 GitHub Actions release workflow。

打 tag 时会自动：

```text
运行 smoke tests
重新生成离线资源
构建 release zip
验证 zip 根目录结构
上传 release asset
```

我希望用户下载 Release 包之后，不需要理解仓库结构，直接解压运行：

```powershell
.\install-claude-code-deepseek.ps1
```

发布包里的结构大概是：

```text
install-claude-code-deepseek.ps1
src/
  README.md
  README.zh-CN.md
  vendor/
```

脚本会自动识别 `src\vendor`，不用手动传路径。

---

## 插图 10：GitHub Actions 打包流水线

**插图位：`docs/assets/comics/10-release-pipeline.png`**

**画面描述：** GitHub Actions 流水线把源码、vendor、README、install 脚本打成 zip 发布包。

**AI 绘图提示词：**

> 漫画风 GitHub Actions 自动流水线，源码文件、README、vendor 离线包、install 脚本进入机器，输出一个 Release ZIP 礼盒，旁边有绿色 checks passed，技术开源项目插图，16:9

---

## 十一、我也写了基础 smoke test

虽然这只是一个安装脚本，但我还是加了基础测试。

测试脚本会检查：

```text
PowerShell 语法是否正确
模拟 claude 命令
验证 DeepSeek 环境变量是否写入
验证 continue 模式参数是否正确
验证 skip launch 时不会启动 claude
```

这部分不是为了“显得高级”，而是为了避免以后改脚本时把基本流程改坏。

---

## 插图 11：测试机器人打勾

**插图位：`docs/assets/comics/11-smoke-test.png`**

**画面描述：** 一个测试机器人拿着清单，检查 PowerShell syntax、环境变量、启动参数，全部打勾。

**AI 绘图提示词：**

> 漫画风，测试机器人拿着 checklist，项目包括 PowerShell syntax、ANTHROPIC_AUTH_TOKEN、ANTHROPIC_BASE_URL、claude args，全部绿色打勾，背景是终端窗口，技术可爱风，16:9

---

## 十二、适合谁用？

这个工具比较适合这些人：

```text
Windows 用户
经常被 npm / 代理 / optional dependency 折腾的人
想在多台机器上复现 Claude Code 环境的人
需要在离线或弱网环境部署的人
想用 DeepSeek 作为 Claude Code 后端模型的人
喜欢把开发环境工具链脚本化的人
```

不太适合这些人：

```text
只在一台机器上正常在线使用的人
不想折腾第三方 API 的人
完全不了解 PowerShell 的人
对 token 安全没有基本意识的人
```

如果你只是普通在线安装，官方安装方式就够了。

但如果你希望把 Claude Code 的 Windows 部署变成一个**可复制、可离线、可校验、可自动化**的流程，这个脚本就比较有价值。

---

## 插图 12：四类用户围着工具箱

**插图位：`docs/assets/comics/12-target-users.png`**

**画面描述：** 学生、独立开发者、公司内网工程师、AI 工具玩家围在一张桌子前，中间是 Claude Code 离线安装包。

**AI 绘图提示词：**

> 漫画风，学生、独立开发者、公司内网工程师、AI 工具玩家四个人围在桌子前，中间放着 Claude Code Offline Installer 工具箱，大家表情轻松，技术社区分享风，16:9

---

## 十三、安全说明：这是非官方工具，Token 要保管好

需要强调几点：

```text
1. 这是非官方辅助脚本
2. 不要把 DeepSeek Token 提交到仓库
3. 不要把 token 发到聊天记录或公开截图里
4. Full access 模式要谨慎使用
5. 如果 token 泄露，立刻去 DeepSeek 控制台轮换
```

另外，`vendor/` 目录可能很大，默认不建议提交到源码仓库里。除非你明确要通过 Release 分发完整离线包。

---

## 插图 13：Token 保险箱

**插图位：`docs/assets/comics/13-token-safe.png`**

**画面描述：** 一个保险箱里放着 API Token，旁边有机器人守卫，远处有“不要提交到 GitHub”的红色标语。

**AI 绘图提示词：**

> 漫画风，一个保险箱里锁着 API Token 钥匙，旁边有 AI 机器人守卫，背景有红色警示牌“不要提交到 GitHub”，安全主题，简洁清晰，技术插图，16:9

---

## 十四、快速使用指南

### 1. 克隆仓库

```powershell
git clone https://github.com/11cookies11/Claude-Code-Installer-Script.git
cd Claude-Code-Installer-Script
```

### 2. 在联网 Windows 机器上准备离线包

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\prepare-offline-package.ps1
```

### 3. 把整个仓库复制到目标机器

确保包含：

```text
install-claude-code-deepseek.ps1
prepare-offline-package.ps1
vendor/
README.zh-CN.md
README.md
```

### 4. 在目标机器运行安装脚本

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-claude-code-deepseek.ps1
```

### 5. 输入 DeepSeek Token

Token 通常长这样：

```text
sk-xxxxxxxxxxxxxxxx
```

### 6. 选择权限模式

第一次使用推荐：

```text
保守模式（Ask for approval）
```

日常开发推荐：

```text
平衡模式（Approve for me）
```

### 7. 选择会话入口

第一次使用可以选：

```text
新对话
```

### 8. 验证安装

重新打开终端后运行：

```powershell
claude --version
claude doctor
```

---

## 插图 14：五步流程图

**插图位：`docs/assets/comics/14-quickstart-flow.png`**

**画面描述：** 一张漫画流程图：下载仓库 → 准备离线包 → 拷贝到目标机器 → 输入 token → 启动 Claude Code。

**AI 绘图提示词：**

> 漫画风流程图，五个步骤：下载仓库、准备离线包、复制到目标机器、输入 DeepSeek Token、启动 Claude Code，每一步都有可爱图标，适合知乎技术教程，横向 16:9

---

## 十五、为什么我要开源这个项目？

因为我发现很多时候，开发效率不是被“大问题”卡住，而是被这些小问题反复消耗：

```text
环境变量忘了怎么配
npm 包又拉不下来
optional dependency 又缺了
Node.js 又不一致
另一台电脑又要重新装
```

这些东西单独看都不难，但它们叠在一起，就会让人非常烦。

所以我想把它们整理成一个完整流程：

```text
能准备
能安装
能校验
能记录日志
能配置 API
能启动 Claude Code
能发布离线包
能做基础测试
```

这样以后无论是我自己换电脑，还是别人想在 Windows 上快速体验 Claude Code + DeepSeek，都可以少踩一点坑。

---

## 插图 15：开源工具箱

**插图位：`docs/assets/comics/15-open-source-toolbox.png`**

**画面描述：** 一个程序员把工具箱放到开源广场，其他开发者拿走使用、修 bug、提 PR。

**AI 绘图提示词：**

> 漫画风，一个程序员把写着 Open Source Tool 的工具箱放在广场上，其他开发者围过来使用、修 bug、提交 PR，背景有 GitHub 风格代码元素但不要官方 logo，温暖技术社区氛围，16:9

---

## 十六、后续计划

后面我可能会继续完善：

```text
1. 增加更友好的 GUI 安装界面
2. 支持更多 Anthropic 兼容 API
3. 增加卸载脚本
4. 增加环境检测报告
5. 增加更完整的测试用例
6. 优化 Release 包下载和使用说明
7. 补充更多常见错误排查文档
```

如果你刚好也在 Windows 上使用 Claude Code，或者想把 Claude Code 接入 DeepSeek，可以试试这个项目。

项目地址：

```text
https://github.com/11cookies11/Claude-Code-Installer-Script
```

如果它帮你节省了安装时间，也欢迎 Star、提 Issue 或 PR。

---

## 结尾图

**插图位：`docs/assets/comics/16-success-ending.png`**

**画面描述：** 程序员终于成功启动 Claude Code，之前满屏报错的电脑变成干净的终端，小机器人在旁边举牌“环境终于好了”。

**AI 绘图提示词：**

> 漫画风，程序员终于在 Windows 终端中成功运行 Claude Code，屏幕显示启动成功，旁边可爱的 AI 机器人举牌“环境终于好了”，前景有被丢到一边的 npm error 纸团，温暖幽默，知乎技术文章结尾图，16:9

---

## 结语

我越来越感觉，AI 编程工具本身很重要，但**让工具稳定进入自己的开发环境**同样重要。

一个工具，如果每次安装都靠运气，它就很难真正成为生产力。

所以这个项目的目标不是“炫技”，而是把 Claude Code 在 Windows 上的部署流程变得更可复制：

```text
一次准备
多次安装
离线可用
配置清晰
失败可查
```

希望这个小工具能帮到和我一样，被 Windows、npm、代理、环境变量折腾过的人。
