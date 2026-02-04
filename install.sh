#!/bin/bash

#==============================================================================
# Claude Code Notifier - Installation Script
# Usage: ./install.sh (from cloned repo)
#==============================================================================

set -e

REPO_URL="https://raw.githubusercontent.com/anthropics/claude-code-notifier/main"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
NOTIFIER_SCRIPT="claude-code-notifier.sh"

# Detect if running locally (from cloned repo) or remotely (via curl)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd)"
if [ -f "$SCRIPT_DIR/$NOTIFIER_SCRIPT" ]; then
  LOCAL_INSTALL="true"
else
  LOCAL_INSTALL="false"
fi

echo ""
echo "Claude Code Notifier - Installation"
echo "===================================="
echo ""

#==============================================================================
# Check dependencies
#==============================================================================
check_dependencies() {
  local missing=()

  if ! command -v jq >/dev/null 2>&1; then
    missing+=("jq")
  fi

  case "$(uname -s)" in
    Darwin*)
      if ! command -v terminal-notifier >/dev/null 2>&1; then
        missing+=("terminal-notifier")
      fi
      ;;
    Linux*)
      if ! command -v notify-send >/dev/null 2>&1; then
        missing+=("libnotify-bin")
      fi
      ;;
  esac

  if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing dependencies: ${missing[*]}"
    echo ""
    case "$(uname -s)" in
      Darwin*)
        echo "Install with: brew install ${missing[*]}"
        ;;
      Linux*)
        echo "Install with: sudo apt install ${missing[*]}"
        ;;
    esac
    echo ""
    echo "Continuing installation anyway..."
  else
    echo "All dependencies found."
  fi
}

#==============================================================================
# Install notifier script
#==============================================================================
install_notifier() {
  mkdir -p "$CLAUDE_DIR"

  if [ "$LOCAL_INSTALL" = "true" ]; then
    echo "Installing from local repo..."
    cp "$SCRIPT_DIR/$NOTIFIER_SCRIPT" "$CLAUDE_DIR/$NOTIFIER_SCRIPT"
  else
    echo "Downloading notifier script..."
    curl -fsSL "$REPO_URL/$NOTIFIER_SCRIPT" -o "$CLAUDE_DIR/$NOTIFIER_SCRIPT"
  fi

  chmod +x "$CLAUDE_DIR/$NOTIFIER_SCRIPT"
  echo "Installed: $CLAUDE_DIR/$NOTIFIER_SCRIPT"
}

#==============================================================================
# Generate hooks configuration
#==============================================================================
generate_hooks_json() {
  cat <<'EOF'
{
  "SessionStart": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "SessionEnd": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "Stop": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "Notification": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "PreToolUse": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "PostToolUse": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "PostToolUseFailure": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "PermissionRequest": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "SubagentStart": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "SubagentStop": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}],
  "PreCompact": [{"hooks": [{"type": "command", "command": "~/.claude/claude-code-notifier.sh"}]}]
}
EOF
}

#==============================================================================
# Update settings.json with hooks
#==============================================================================
update_settings() {
  echo ""
  echo "Configuring Claude Code hooks..."

  local hooks_json
  hooks_json=$(generate_hooks_json)

  if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
    echo "Backed up: $SETTINGS_FILE.backup"

    if jq -e '.hooks' "$SETTINGS_FILE" >/dev/null 2>&1; then
      echo "Existing hooks found - merging..."
      jq --argjson new_hooks "$hooks_json" '.hooks = (.hooks // {}) * $new_hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
      mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    else
      jq --argjson hooks "$hooks_json" '.hooks = $hooks' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
      mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    fi
  else
    echo "Creating new settings.json..."
    jq -n --argjson hooks "$hooks_json" '{hooks: $hooks}' > "$SETTINGS_FILE"
  fi

  echo "Hooks configured in $SETTINGS_FILE"
}

#==============================================================================
# Main
#==============================================================================
main() {
  check_dependencies
  install_notifier
  update_settings

  echo ""
  echo "===================================="
  echo "Installation Complete!"
  echo "===================================="
  echo ""
  echo "To customize notifications, edit:"
  echo "  $CLAUDE_DIR/$NOTIFIER_SCRIPT"
  echo ""
  echo "Sending test notification..."
  echo '{"hook_event_name":"Notification","message":"Installation successful!"}' | "$CLAUDE_DIR/$NOTIFIER_SCRIPT"
  echo ""
  echo "Done!"
}

main
