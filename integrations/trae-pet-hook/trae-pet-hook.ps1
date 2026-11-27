# -*- coding: utf-8 -*-
<#
Trae → dsh-pet 联动桥（Hook 命令）。

Trae 在 SessionStart / UserPromptSubmit / PreToolUse / Stop 事件里把 JSON 从 stdin
传进来；本脚本只读取事件名、会话 ID 和工具名，追加一行到桌宠统一协议文件：

    <config.dir>/agent-events/trae.jsonl

隐私红线：不落 prompt、tool_input、tool_response、文件内容或命令全文。
绝不阻塞 Trae：任何异常都静默 exit 0，不输出 stdout（不改变智能体决策）。
#>
$ErrorActionPreference = 'SilentlyContinue'

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $data = $raw | ConvertFrom-Json
} catch {
    exit 0
}

$eventName = [string]$data.hook_event_name
$sessionId = [string]$data.session_id
$toolName = [string]$data.tool_name

$state = ''
switch ($eventName) {
    'SessionStart' { $state = 'idle' }
    'UserPromptSubmit' { $state = 'thinking' }
    'PreToolUse' { $state = 'working' }
    'Stop' { $state = 'attention' }
    default { exit 0 }
}

function Resolve-PetEventsDir {
    if ($env:DSH_PET_AGENT_EVENTS_DIR) {
        return $env:DSH_PET_AGENT_EVENTS_DIR
    }
    $fallback = Join-Path $env:APPDATA 'dsh-pet-standalone-webm-chat\agent-events'
    try {
        $candidates = Get-ChildItem $env:APPDATA -Directory -Filter 'dsh-pet-standalone*' |
            Sort-Object LastWriteTime -Descending
        foreach ($candidate in $candidates) {
            if (Test-Path (Join-Path $candidate.FullName 'config.json')) {
                return (Join-Path $candidate.FullName 'agent-events')
            }
        }
    } catch { }
    return $fallback
}

$dir = Resolve-PetEventsDir
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$line = [ordered]@{
    ts        = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() / 1000.0
    agent     = 'trae'
    state     = $state
    sessionId = $sessionId
}
if ($toolName) { $line.tool = $toolName }

try {
    $json = $line | ConvertTo-Json -Compress
    [System.IO.File]::AppendAllText(
        (Join-Path $dir 'trae.jsonl'),
        $json + "`n",
        [System.Text.UTF8Encoding]::new($false)
    )
} catch { }

exit 0
