# project-with-reflect

一个**会蒸馏自己的** meta-skill。

你是否同时管理多个项目？是否要记住好几台机器、服务的连接方式？是否厌烦了反复写大段重复的
prompt、向 Claude 一遍遍解释同一个项目的来龙去脉？

它帮你把每个 **project** 管起来——worktree、log、reflect、沉淀出**长期知识库**；也帮你管起
**服务器 / 设备 / API / MCP**，每个都成为可直接调用的 `/<name>` skill；而且全程 **Obsidian 友好**
（rules / 知识 / dashboard 都是干净可读的 Markdown）。

**核心逻辑：**

- **万物皆 skill** —— project，以及每个 connection（ssh host / serial device / HTTP API / MCP），注册后都得到自己的 `/<name>`。
- **工作时自动 log** —— commit、决定、关键发现、error + 修复，随手记进当前 stream。
- **`reflect` 蒸馏自己** —— 先 capture 这次 session，再把 log 提炼成**精简、可读的 rules**，下次自动加载。
- **动手前先加载** —— Claude 先读已有 rules / decisions / 知识，不再重复解释、重复犯错。

> **核心循环 core loop：** `work（自动 log）→ /<project> reflect（capture + 提炼）→ 精简可读 rules → 下次更好`

## 快速上手 Quick start

```
# 1. 安装（在 Claude Code 里）
/plugin marketplace add initialneil/project-with-reflect
/plugin install project-with-reflect@project-with-reflect

# 2. 注册一个 project → 生成 /myapp skill
/register-project myapp ~/code/myapp

# 3. 照常开发；关键时刻自动 log
/myapp …

# 4. session 收尾：capture 这次 session + 提炼成 rules
/myapp reflect
/myapp log and reflect    # 同义 —— reflect 本来就会先 capture
```

也能把设备 / 服务变成 skill——`/register-device`、`/register-api`、`/register-mcp`、
`/register-machine`；project `bind` 之后可直接 build / flash / 调用（见下文）。

## 首次运行：选 root  First run

首次运行会询问 `$PROJECT_WITH_REFLECT_ROOT` 放哪。**推荐用一个 custom、可同步、可读的
路径** —— 你的 Obsidian vault，或一个云文件同步文件夹（Dropbox / Google Drive / OneDrive /
iCloud / Nutstore），在其中用一个 `Project-with-Reflect` 文件夹，这样 rules 和 knowledge
能跨机器同步、也方便阅读；`~/.project-with-reflect` 是不同步的默认值。（Notion / Google Docs
不是本地文件夹，不能作为 root —— root 必须是真实的本地目录。）选择会被保存（pointer + shell rc）。

## 结构 The model

```
$PROJECT_WITH_REFLECT_ROOT/
  projects/<name>/    每个 project 的 skill + 状态
  machines/<name>/    ssh / cloud-server 指针（磁盘上不存密码）
  devices/<name>/      硬件 flash target（board、port、flash/monitor）
  knowledge/          全局、可被 agent 使用的模块，project 按需 opt-in
  memories/           长期全局事实（保持精简）
  templates/ scripts/ registry.json
```

每个 project：
```
projects/<name>/
  SKILL.md             自包含的 dispatcher + behavioral contract
  <name>.md            人类看的 dashboard —— 由 reflect 重新生成
  rules/<topic>.md     模块化、可读的 rules；按需加载；可被 promote
  workstreams/<branch>/ stream.json + log.md （log 按 lane 存放）
  decisions.md         试过 / 选定 / 否决的想法 —— 提议前先查
  evals/<eval>/  tasks/<task>.md  knowledge/  config.json
```

## 命令 Actions

**总体**（`/project-with-reflect`，无参数 → `help`）：`help` · `list` · `status` ·
`register-project` · `register-machine` · `register-device` · `register-knowledge` ·
`register-agent` · `meta-reflect`。

**单个 project**（`/<name>`）：`bootstrap` · `status` · `list` · `help` · `reflect [--reground]` ·
`streams` · `register-branch <b> --base <x>` · `<branch> [pr|rebase|reset]` ·
`register-eval <e>` · `eval all` · `register-task <t>` · `use-knowledge <k>` · `note "…"`。

统一的 ergonomic：**注册一个 handle → 得到 `/<name>-<handle>`**
（branch → workstream，eval → test case，task → runbook）。

## Bootstrap

两个 `bootstrap` 帮你从零到可用：

- **`/project-with-reflect bootstrap [path]`** —— （重新）配置 root：询问 `$PROJECT_WITH_REFLECT_ROOT`
  放哪（推荐可同步、可读的路径）并建好。用于注册前的初始化、迁移 root、或修复丢失的 pointer。
- **`/<name> bootstrap`** —— *用已有内容给一个刚注册的 project 灌入初始记忆。* Claude 读 repo 的文档
  （README、specs、CHANGELOG）、浏览代码、并结合当前 session，做一次初始 reflect：写出
  `rules/<topic>.md` 模块、把已做的决定填进 `decisions.md`、生成 `<name>.md` dashboard。这样今天注册的
  project 一开始就是满的，而不是空的 —— 提炼，而非杜撰。

## Behavioral contract（让它真正有用的关键）

每个生成的 `/<name>` 都会让 Claude 在**动手前**：
1. **先加载，再提议** —— 读 `<name>.md` + `decisions.md` + 匹配的 rule modules。
2. **提议前先查 ledger** —— 如果它已在 `decisions.md` 里，引用它，绝不盲目重复提议。
3. **绝不擅自改 guarded state** —— dataset、训练 settings、branch/release 约定都是 invariants。
4. **主动 surface** 相关的 rules 和已注册的 evals。

正是这个 contract，让记录 log 变成**更少**的重复劳动，而不是更多的文件。

## 实例 Worked examples

**在一个本身基于更旧 branch 的 version branch 上做 bug-fix stream：**
```
/app register-branch v090 --base v080 --track-only   # 记录 lineage：v090 基于 v080
/app register-branch v090-bug-fix --base v090        # 从 origin/v090 fork，PR 回 v090
/app-v090-bug-fix                                     # 开发；自动 log
/app-v090-bug-fix pr                                  # rebase 到 v090；若 v090 落后 v080 → 提示并询问；gh pr create --base v090
# …PR 合并后…
/app-v090-bug-fix reset                               # 把这条 lane 重置到最新 v090，准备下一个 PR
```
version lineage 就是 `base` 指针链 `v080 ← v090 ← v090-bug-fix`；一个 workstream 是
**可复用的 lane**，不是一次性的。

**横跨一个 device 和一台 cloud server 的固件 project：**
```
/register-machine gcs-server     # 还没有？描述它 —— Claude 引导 provider 配置 + billing + firewall，先确认费用
/register-device cardputer-adv   # autodetect board + /dev/cu.usb*；写 device.json + flash/monitor
/register-project splattingavatar ~/code/splattingavatar
/splattingavatar bind --device cardputer-adv --server gcs-server
/splattingavatar build && /splattingavatar flash && /splattingavatar monitor   # 把 server endpoint 编进固件、通过 USB flash、看它连上 server
```

## Reflect = bounded update

`reflect` 是 **log-and-reflect**：它先 **capture 这次 session**（把这段对话里还没记进 log
的关键事件追加进去——project 发现进当前 stream 的 log，设备/API 的发现进对应 connection 的
log），**再**把新条目折叠进对应的 `rules/<topic>.md` + `decisions.md`，修正错误的 rules，
**太长就拆 module**，重新生成 `<name>.md`，归档已消化的 log，并报告改了什么。所以一句
`/<project> reflect` 就是整个 session 收尾的习惯，不用单独“log”一步。`--reground` 会对某个
module 做完整重写。可读性说了算。

## 致谢 Acknowledgements

灵感来自我亲爱的朋友、清华的 Zhaolong WANG。

并借鉴了这些项目的思路：
- [hermes-agent](https://github.com/nousresearch/hermes-agent) —— closed learning loop。
- [grounding-rules](https://github.com/initialneil/grounding-rules) —— 精简、可读的 rules。
- [planning-with-files](https://github.com/othmanadi/planning-with-files) —— 基于 hook 的磁盘工作记忆。

## License

MIT © initialneil
