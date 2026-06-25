# project-with-reflect

一个**会蒸馏自己的** meta-skill。

你是否同时管理多个项目？是否要记住好几台机器、服务的连接方式？是否厌烦了反复写大段重复的
prompt、向 Claude 一遍遍解释同一个项目的来龙去脉？

它帮你把每个 **project** 管起来——worktree、log、reflect、沉淀出**长期知识库**；也帮你管理一切你
要**操作的东西**（connection），每个都成为可直接调用的 `/<name>` skill：

- **服务器** —— ssh 部署 / 看日志 / 跑命令
- **训练机** —— GPU 机器：跑训练 / `nvidia-smi`，记住它的 quirks（如重启后 `nvidia-smi -pl 300`）
- **设备 device** —— USB / 串口烧录目标（开发板…）：flash / monitor / REPL
- **API** —— HTTP / WebSocket 服务（只把 key 的环境变量**名字**落盘，绝不存 key 本身）
- **MCP** —— MCP server，直接用它的 `mcp__<name>__*` tools

而且全程 **Obsidian 友好**（rules / 知识 / dashboard 都是干净可读的 Markdown）。

**核心逻辑：**

- **万物皆 skill** —— project 和上面每个 connection，注册后都得到自己的 `/<name>`。
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

# 3. 开一条 workstream lane —— 直接说它基于哪条（worktree / branch / 仅追踪，按 project 的 mode）
/register-branch my-feature 基于 main        # → 生成 /myapp-my-feature

# 4. 照常开发；关键时刻自动 log
/myapp-my-feature …                          # （或直接 /myapp 用主 lane）

# 5. session 收尾：capture 这次 session + 提炼成精简 rules
/log-and-reflect          # 在 repo 里任意位置 —— 自动按 cwd 找到 project
# （≡ /myapp reflect —— reflect 本来就会先 capture）
```

**远程 / 多 repo 的 project** —— 代码在服务器上（本地没有 checkout）、还可能横跨多个 repo？直接
**用大白话描述**就行 —— Claude 会替你注册 host、记录各个 root，不用记任何 flag 语法：

```
/register-project myapp —— 它在 gpubox 服务器的 /srv/myapp，另外还用到 /srv/dataset 这个数据集 repo
```
如果 gpubox 还不是 connection，Claude 会先把它注册成 ssh connection（key-based，磁盘上不存密码），
把两个 repo 记为 root 并 bind 上 host。然后 `/myapp bootstrap` 通过 ssh 从这些 repo seed 出
rules + decisions。之后你在本地（同步的 lane 目录）跑 Claude；`/myapp` 通过 `/gpubox` 在 host 上
build / test，而 planning / 工作文件都留在 vault 里，绝不弄乱服务器或你的 `~`。

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
  projects/<name>/      每个 project 的 skill + 状态
  connections/<name>/   你操作的一切 —— ssh | serial | http | mcp —— 每个都是自己的 /<name> skill
  knowledge/            全局、可被 agent 使用的参考笔记，project 按需 opt-in
  memories/             长期全局事实（保持精简）
  agents/  templates/  scripts/  registry.json
```

connection **磁盘上不存任何 secret** —— 只存放 key 的环境变量**名字**（如 `SONIOX_API_KEY`），
绝不存 key 本身或 ssh 密码。

每个 project：
```
projects/<name>/
  SKILL.md             自包含的 dispatcher + behavioral contract
  <name>.md            人类看的 dashboard（含 ## TODO backlog）—— 由 reflect 重新生成
  rules/<topic>.md     模块化、可读的 rules；按需加载
  workstreams/<branch>/ stream.json + log.md （log 按 lane 存放）
  decisions.md         试过 / 选定 / 否决的想法 —— 提议前先查
  evals/<eval>/  tasks/<task>.md  config.json
```

每个 connection（一个 skill，按 transport）：
```
connections/<name>/
  connection.json      transport + facts（port/board · ssh alias · base_url/key_env · mcp tools · docs_url）
  <name>.md            facts（frontmatter）+ 学到的 ## Quirks
  SKILL.md   log.md    /<name> flash|monitor|call|… → reflect 把 log 折叠进 quirks
```

## 命令 Actions

> 你用**大白话**说要做什么 —— 下面的名字和 flag 是 Claude 替你填的，不用背（比如「开一条 v081，
> 基于 v080，只追踪」「Soniox 这个 API，key 在 `SONIOX_API_KEY`」）。

**总体**（`/project-with-reflect`，无参数 → `help`）：`help` · `list` · `status` ·
`register-project` · `register-machine` · `register-device` · `register-api` · `register-mcp` ·
`register-knowledge` · `register-agent` · `update` · `meta-reflect`。

**单个 project**（`/<name>`）：`bootstrap` · `status` · `list` · `help` ·
`reflect [<target>] [--reground]` · `note "…"` · `todo` · `bind --connection <c> [--build "…"]` ·
`build` · `flash` · `monitor` · `streams` · `register-branch <b> --base <x>` ·
`<branch> [pr|rebase|reset]` · `register-eval <e>` · `eval all` · `register-task <t>` ·
`use-knowledge <k>`。

**单个 connection**（`/<name>`，按 transport）：ssh `<cmd>` · serial `flash | monitor | reconnect wifi | repl` ·
http/mcp `<call>` —— 外加 `status` · `note "…"` · `update "…"` · `reflect`（把 log 折叠进 `## Quirks`）。

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
5. **了解你的 connections**（服务器 / 训练机 / 设备 / API / MCP）—— 通过 connection 自己的 `/<name>`
   skill 去操作它（会自动套用它学到的 quirks）；`connection.json` 提供硬事实，绝不靠猜 port / host / endpoint。

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
/register-device cardputer-adv   # autodetect board + /dev/cu.usb*；写 connection.json + flash/monitor
/register-machine gcs-server     # ssh connection；还没有？描述它 —— Claude 引导 provider 配置 + billing，先确认费用
/register-project splattingavatar ~/code/splattingavatar
/splattingavatar bind --connection cardputer-adv --connection gcs-server
/splattingavatar build && /splattingavatar flash && /splattingavatar monitor   # 把 server endpoint 编进固件、通过 USB flash、看它连上 server
```
每个也都是自己的 skill —— `/cardputer-adv flash`、`/gcs-server <cmd>`；project 里的 `flash`/`monitor`
会委托给它，于是它学到的 quirks 自动生效。

## Reflect = bounded update

`reflect` 是 **log-and-reflect**：它先 **capture 这次 session**（把这段对话里还没记进 log
的关键事件追加进去——project 发现进当前 stream 的 log，设备/API 的发现进对应 connection 的
log），**再**把新条目折叠进对应的 `rules/<topic>.md` + `decisions.md`，修正错误的 rules，
**太长就拆 module**，重新生成 `<name>.md`，归档已消化的 log，并报告改了什么。所以一句
`/<project> reflect` 就是整个 session 收尾的习惯，不用单独“log”一步。可以 `/<project> reflect`，
或在 repo 里任意位置用 **`/log-and-reflect`**（自动按 cwd 找到 project）。`--reground` 会对某个
module 做完整重写。可读性说了算。

`reflect` 还会**标记代码改进项**（log 里反复出现的失败、被反复改的模块）—— 你按正常开发去改，或用
`todo` 先记下；它**绝不擅自改源码**。而且 log 不靠你盯着：两个非阻塞 **hook**（每次 `git commit` 提醒、
compaction 前 flush）+ reflect 的 capture-first 兜底，让 log 始终是新的。

## 致谢 Acknowledgements

Inspired by my dear friend Zhaolong WANG from Tsinghua.

并借鉴了这些项目的思路：
- [hermes-agent](https://github.com/nousresearch/hermes-agent) —— closed learning loop。
- [grounding-rules](https://github.com/initialneil/grounding-rules) —— 精简、可读的 rules。
- [planning-with-files](https://github.com/othmanadi/planning-with-files) —— 基于 hook 的磁盘工作记忆。

## License

MIT © initialneil
