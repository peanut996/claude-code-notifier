# Claude Code Notifier

Desktop notifications for [Claude Code](https://claude.com/claude-code) hook events.

Get notified when Claude Code starts a session, finishes responding, encounters errors, and more.

## Features

- Desktop notifications for all 12 Claude Code hook events
- Cross-platform support (macOS, Linux, Windows WSL)
- Configurable per-event filtering
- Optional email notifications
- Easy install/uninstall scripts

## Installation

### Quick Install (One-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/peanut996/claude-code-notifier/master/install.sh | bash
```

### Clone & Install

```bash
git clone https://github.com/peanut996/claude-code-notifier.git
cd claude-code-notifier
./install.sh
```

### Manual Install

1. Copy the notifier script:
```bash
cp claude-code-notifier.sh ~/.claude/
chmod +x ~/.claude/claude-code-notifier.sh
```

2. Add hooks to `~/.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
    "SessionEnd": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
    "Notification": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}]
  }
}
```

## Dependencies

| Platform | Dependency | Install |
|----------|------------|---------|
| macOS | `terminal-notifier` | `brew install terminal-notifier` |
| macOS | `jq` | `brew install jq` |
| Linux | `notify-send` | `sudo apt install libnotify-bin` |
| Linux | `jq` | `sudo apt install jq` |

## Notification Icon (macOS)

The notifier uses the `-sender` flag to display the Claude icon. This requires **Claude Desktop** to be installed.

Download Claude Desktop from: https://claude.ai/download

> **Note:** The `-appIcon` flag in terminal-notifier has known issues and doesn't work reliably. The `-sender` flag is used instead, which displays the icon of the specified app (Claude Desktop).

## Configuration

Edit `~/.claude/claude-code-notifier.sh` to customize which events trigger notifications:

```bash
#==============================================================================
# Hook Event Configuration (set to "true" to enable, "false" to disable)
#==============================================================================
EVENT_SESSION_START="true"           # When a session begins or resumes
EVENT_SESSION_END="true"             # When a session terminates
EVENT_STOP="true"                    # When Claude finishes responding
EVENT_NOTIFICATION="true"            # When Claude Code sends a notification
EVENT_USER_PROMPT_SUBMIT="false"     # When you submit a prompt
EVENT_PRE_TOOL_USE="false"           # Before a tool call executes
EVENT_POST_TOOL_USE="false"          # After a tool call succeeds
EVENT_POST_TOOL_USE_FAILURE="true"   # After a tool call fails
EVENT_PERMISSION_REQUEST="true"      # When a permission dialog appears
EVENT_SUBAGENT_START="false"         # When a subagent is spawned
EVENT_SUBAGENT_STOP="false"          # When a subagent finishes
EVENT_PRE_COMPACT="true"             # Before context compaction
EVENT_OTHER="true"                   # For any unrecognized events
```

### Recommended Settings

For most users, enable only these events to avoid notification fatigue:

| Event | Recommended | Why |
|-------|-------------|-----|
| `SessionStart` | Enable | Know when Claude is ready |
| `SessionEnd` | Enable | Know when session ends |
| `Stop` | Enable | Know when Claude finishes responding |
| `Notification` | Enable | Permission prompts, idle alerts |
| `PostToolUseFailure` | Enable | Know when something fails |
| `PermissionRequest` | Enable | Know when approval is needed |
| `PreCompact` | Enable | Know when context is compacting |
| Others | Disable | Can be very noisy |

## Hook Events

All 12 Claude Code hook events are supported:

| Event | Description |
|-------|-------------|
| `SessionStart` | When a session begins or resumes |
| `SessionEnd` | When a session terminates |
| `Stop` | When Claude finishes responding |
| `Notification` | When Claude Code sends a notification |
| `UserPromptSubmit` | When you submit a prompt |
| `PreToolUse` | Before a tool call executes |
| `PostToolUse` | After a tool call succeeds |
| `PostToolUseFailure` | After a tool call fails |
| `PermissionRequest` | When a permission dialog appears |
| `SubagentStart` | When a subagent is spawned |
| `SubagentStop` | When a subagent finishes |
| `PreCompact` | Before context compaction |

## Email Notifications (Optional)

To enable email notifications, edit the script:

```bash
EMAIL_ENABLED="true"
EMAIL_TO="your-email@example.com"
EMAIL_FROM="claude-code@example.com"
SMTP_HOST="smtp.example.com"
SMTP_PORT="25"
```

## Uninstall

```bash
./uninstall.sh
```

Or manually:
```bash
rm ~/.claude/claude-code-notifier.sh
# Then remove the "hooks" section from ~/.claude/settings.json
```

## Troubleshooting

### Notifications not appearing

1. Verify the script is executable:
   ```bash
   chmod +x ~/.claude/claude-code-notifier.sh
   ```

2. Test the script manually:
   ```bash
   echo '{"hook_event_name":"Stop"}' | ~/.claude/claude-code-notifier.sh
   ```

3. Check that `jq` is installed:
   ```bash
   jq --version
   ```

4. On macOS, check that `terminal-notifier` is installed:
   ```bash
   terminal-notifier -help
   ```

### Too many notifications

Disable noisy events in the script configuration:
```bash
EVENT_PRE_TOOL_USE="false"
EVENT_POST_TOOL_USE="false"
EVENT_USER_PROMPT_SUBMIT="false"
```

## Documentation

- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)

## License

MIT
