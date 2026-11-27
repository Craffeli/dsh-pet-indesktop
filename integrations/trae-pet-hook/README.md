# Trae → dsh-pet 联动桥

用 Trae 官方 Hook 机制（`hooks.json`）把 Trae 智能体的生命周期事件写给桌宠，
走桌宠已有的统一协议文件 `agent-events/trae.jsonl`，**不需要改桌宠代码、不需要重启桌宠**。

## 事件映射

| Trae Hook 事件 | 桌宠状态 | 效果 |
|---|---|---|
| `SessionStart` | `idle` | 会话建立，桌宠回待机 |
| `UserPromptSubmit` | `thinking` | 你发消息后，桌宠开始"思考" |
| `PreToolUse` | `working` | 工具开跑，过程气泡带工具名 |
| `Stop` | `attention` | 回合结束，桌宠报完成/待确认 |

只读取 `session_id`、`hook_event_name`、`tool_name`；**不落** prompt、tool_input、
tool_response、命令全文或文件内容。脚本任何异常都静默 `exit 0`，不会阻塞 Trae。

## 安装

1. 复制脚本到 Trae 用户目录：

   ```powershell
   New-Item -ItemType Directory -Force "$env:USERPROFILE\.trae-cn\pet-hooks" | Out-Null
   Copy-Item integrations\trae-pet-hook\trae-pet-hook.ps1 "$env:USERPROFILE\.trae-cn\pet-hooks\" -Force
   ```

2. 把 `hooks.json.example` 的内容合并进全局 Hook 配置
   `%USERPROFILE%\.trae-cn\hooks.json`（已有文件先备份）。

3. 打开 Trae **设置 → Hooks**：
   - 全局 Hook 打开开关（首次会弹安全确认，确认后启用）；
   - **运行方式** 选 **本地自动运行**（脚本要写 `%APPDATA%` 下的桌宠事件目录，
     沙箱运行可能写不进去）。

4. 验证：在 Trae 里发一条消息，观察桌宠
   `%APPDATA%\dsh-pet-standalone*\pet-<pid>.log` 里出现
   `播放联动音效 event=start agent=trae`，或直接看
   `<config.dir>\agent-events\trae.jsonl` 是否新增行。

## 排错

- **没有事件**：先确认设置里 Hook 已启用、运行方式是"本地自动运行"；
  再看 Trae「设置 → Hooks → 运行日志」。
- **桌宠没反应**：确认右键「Agent 联动 → Trae」已勾选。
- **多实例/变体**：脚本默认找 `%APPDATA%\dsh-pet-standalone*` 下最新的
  带 `config.json` 的目录；也可用环境变量 `DSH_PET_AGENT_EVENTS_DIR` 直接指定
  `agent-events` 目录。

## 与 hub_event_cache 的关系

桌宠自带的 `TraeMonitor` 也会读 Trae 的 `hub_event_cache`（SOLO/Agent 任务产物）。
两者同时可用时，SOLO 任务可能收到两份事件；普通对话只有本 Hook 这一条通道。
