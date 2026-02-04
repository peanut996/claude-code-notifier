#!/bin/bash

#==============================================================================
# Claude Code Notification Hook Script
# This script displays system notifications when Claude Code triggers hooks
# https://github.com/anthropics/claude-code
#==============================================================================

#==============================================================================
# Notification Configuration
#==============================================================================
DESKTOP_ENABLED="true"   # Set to "false" to disable desktop notifications

#==============================================================================
# Hook Event Configuration (set to "true" to enable, "false" to disable)
# See: https://code.claude.com/docs/en/hooks
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

#==============================================================================
# Email Configuration (optional - set EMAIL_ENABLED="true" to enable)
#==============================================================================
EMAIL_ENABLED="false"
EMAIL_TO=""
EMAIL_FROM=""
SMTP_HOST=""
SMTP_PORT="25"

# Read JSON input from stdin
input=$(cat)

# Extract message and event from JSON input
message=$(echo "$input" | jq -r '.message // "Claude Code Notification"')
hook_event=$(echo "$input" | jq -r '.hook_event_name // "Unknown"')

# Fallback if jq is not available
if [ $? -ne 0 ] || [ "$message" = "null" ]; then
  message="Claude Code Notification"
fi

#==============================================================================
# Extract additional context from JSON input
#==============================================================================
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
agent_type=$(echo "$input" | jq -r '.agent_type // ""')

#==============================================================================
# Customize message based on event type
#==============================================================================
case "$hook_event" in
  "SessionStart")
    message="Session started"
    ;;
  "SessionEnd")
    message="Session completed"
    ;;
  "Stop")
    message="Response finished"
    ;;
  "Notification")
    message="$message"
    ;;
  "UserPromptSubmit")
    message="Prompt submitted"
    ;;
  "PreToolUse")
    message="Tool starting: $tool_name"
    ;;
  "PostToolUse")
    message="Tool completed: $tool_name"
    ;;
  "PostToolUseFailure")
    message="Tool failed: $tool_name"
    ;;
  "PermissionRequest")
    message="Permission needed: $tool_name"
    ;;
  "SubagentStart")
    message="Subagent started: $agent_type"
    ;;
  "SubagentStop")
    message="Subagent finished: $agent_type"
    ;;
  "PreCompact")
    message="Context compaction starting"
    ;;
  *)
    message="$hook_event: $message"
    ;;
esac

#==============================================================================
# Check if this event type is enabled
#==============================================================================
event_enabled="false"
case "$hook_event" in
  "SessionStart")
    [ "$EVENT_SESSION_START" = "true" ] && event_enabled="true"
    ;;
  "SessionEnd")
    [ "$EVENT_SESSION_END" = "true" ] && event_enabled="true"
    ;;
  "Stop")
    [ "$EVENT_STOP" = "true" ] && event_enabled="true"
    ;;
  "Notification")
    [ "$EVENT_NOTIFICATION" = "true" ] && event_enabled="true"
    ;;
  "UserPromptSubmit")
    [ "$EVENT_USER_PROMPT_SUBMIT" = "true" ] && event_enabled="true"
    ;;
  "PreToolUse")
    [ "$EVENT_PRE_TOOL_USE" = "true" ] && event_enabled="true"
    ;;
  "PostToolUse")
    [ "$EVENT_POST_TOOL_USE" = "true" ] && event_enabled="true"
    ;;
  "PostToolUseFailure")
    [ "$EVENT_POST_TOOL_USE_FAILURE" = "true" ] && event_enabled="true"
    ;;
  "PermissionRequest")
    [ "$EVENT_PERMISSION_REQUEST" = "true" ] && event_enabled="true"
    ;;
  "SubagentStart")
    [ "$EVENT_SUBAGENT_START" = "true" ] && event_enabled="true"
    ;;
  "SubagentStop")
    [ "$EVENT_SUBAGENT_STOP" = "true" ] && event_enabled="true"
    ;;
  "PreCompact")
    [ "$EVENT_PRE_COMPACT" = "true" ] && event_enabled="true"
    ;;
  *)
    [ "$EVENT_OTHER" = "true" ] && event_enabled="true"
    ;;
esac

# Exit early if this event type is disabled
if [ "$event_enabled" = "false" ]; then
  exit 0
fi

#==============================================================================
# Detect operating system and show notification accordingly
#==============================================================================
if [ "$DESKTOP_ENABLED" = "true" ]; then
  case "$(uname -s)" in
    Darwin*)
      # macOS - use terminal-notifier with Claude logo
      terminal-notifier -title "Claude Code" -message "$message" -sound default -sender "com.anthropic.claudefordesktop" -appIcon ~/.claude/claude-logo.png
      ;;

    Linux*)
      # Linux - use notify-send
      if command -v notify-send >/dev/null 2>&1; then
        notify-send "Claude Code" "$message" -i dialog-information
      else
        echo "notify-send not found. Install libnotify-bin package."
        echo "Claude Code: $message"
      fi
      ;;

    CYGWIN*|MINGW*|MSYS*)
      # Windows - use PowerShell toast notification
      powershell.exe -Command "
      [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null;
      [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null;
      \$template = @'
      <toast>
          <visual>
              <binding template=\"ToastGeneric\">
                  <text>Claude Code</text>
                  <text>$message</text>
              </binding>
          </visual>
      </toast>
'@;
      \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;
      \$xml.LoadXml(\$template);
      \$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml);
      [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast);"
      ;;

    *)
      # Fallback - just echo to terminal
      echo "Claude Code Notification: $message"
      ;;
  esac
fi

#==============================================================================
# Send email notification (if enabled)
#==============================================================================
send_email() {
  # Set subject based on event type
  local subject
  case "$hook_event" in
    "SessionStart")
      subject="Claude Code: Session Started"
      ;;
    "SessionEnd")
      subject="Claude Code: Session Completed"
      ;;
    "Stop")
      subject="Claude Code: Response Ready"
      ;;
    "Notification")
      subject="Claude Code: $message"
      ;;
    "UserPromptSubmit")
      subject="Claude Code: Prompt Submitted"
      ;;
    "PreToolUse")
      subject="Claude Code: Tool Starting - $tool_name"
      ;;
    "PostToolUse")
      subject="Claude Code: Tool Completed - $tool_name"
      ;;
    "PostToolUseFailure")
      subject="Claude Code: Tool Failed - $tool_name"
      ;;
    "PermissionRequest")
      subject="Claude Code: Permission Needed - $tool_name"
      ;;
    "SubagentStart")
      subject="Claude Code: Subagent Started - $agent_type"
      ;;
    "SubagentStop")
      subject="Claude Code: Subagent Finished - $agent_type"
      ;;
    "PreCompact")
      subject="Claude Code: Context Compaction"
      ;;
    *)
      subject="Claude Code: $hook_event"
      ;;
  esac
  # Create email content
  local email_content="From: $EMAIL_FROM
To: $EMAIL_TO
Subject: $subject
Date: $(date -R)
Content-Type: text/plain; charset=UTF-8

$message
"

  # Send via netcat (works without additional tools)
  {
    echo "EHLO $(hostname)"
    sleep 0.2
    echo "MAIL FROM:<$EMAIL_FROM>"
    sleep 0.2
    echo "RCPT TO:<$EMAIL_TO>"
    sleep 0.2
    echo "DATA"
    sleep 0.2
    echo "$email_content"
    echo "."
    sleep 0.2
    echo "QUIT"
  } | nc -w 5 "$SMTP_HOST" "$SMTP_PORT" >/dev/null 2>&1
}

# Send email if enabled and configured
if [ "$EMAIL_ENABLED" = "true" ] && [ -n "$EMAIL_TO" ]; then
  send_email &
fi
