#!/bin/bash

#==============================================================================
# Claude Code Notifier - Uninstallation Script
#==============================================================================

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
NOTIFIER_SCRIPT="claude-code-notifier.sh"

echo "Claude Code Notifier - Uninstallation"
echo "======================================"
echo ""

# Remove notifier script
if [ -f "$CLAUDE_DIR/$NOTIFIER_SCRIPT" ]; then
  rm "$CLAUDE_DIR/$NOTIFIER_SCRIPT"
  echo "Removed: $CLAUDE_DIR/$NOTIFIER_SCRIPT"
else
  echo "Notifier script not found."
fi

# Remove hooks from settings.json
if [ -f "$SETTINGS_FILE" ]; then
  if jq -e '.hooks' "$SETTINGS_FILE" >/dev/null 2>&1; then
    read -p "Remove hooks from settings.json? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"
      jq 'del(.hooks)' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
      mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
      echo "Removed hooks from $SETTINGS_FILE"
      echo "Backup saved to $SETTINGS_FILE.backup"
    fi
  fi
fi

echo ""
echo "Uninstallation complete."
