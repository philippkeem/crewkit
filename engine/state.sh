#!/bin/bash
# Crewkit state management helper
# Usage: source this file or call functions directly

CREWKIT_DIR=".crewkit"
STATE_FILE="$CREWKIT_DIR/state.json"

# Initialize pipeline state
crewkit_init_state() {
  local command="$1"
  local args="$2"
  local roles="$3"  # comma-separated: "planner,builder,reviewer"

  mkdir -p "$CREWKIT_DIR"

  local roles_json=$(echo "$roles" | tr ',' '\n' | sed 's/^/    "/;s/$/"/' | paste -sd ',' - | sed 's/^/[/;s/$/]/')
  local total=$(echo "$roles" | tr ',' '\n' | wc -l | tr -d ' ')

  cat > "$STATE_FILE" << EOF
{
  "pipeline_id": "$(date +%s)",
  "command": "$command",
  "args": "$args",
  "roles": $roles_json,
  "total_roles": $total,
  "current_role_index": 0,
  "status": "running",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "completed_at": null,
  "pause_reason": null,
  "handoffs": {}
}
EOF
  echo "$STATE_FILE"
}

# Read current state
crewkit_read_state() {
  if [ -f "$STATE_FILE" ]; then
    cat "$STATE_FILE"
  else
    echo '{"status": "none"}'
  fi
}

# Update current role index
crewkit_advance_role() {
  local new_index="$1"
  if command -v jq &> /dev/null; then
    local tmp=$(mktemp)
    jq ".current_role_index = $new_index" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  else
    # Fallback: sed-based update
    sed -i '' "s/\"current_role_index\": [0-9]*/\"current_role_index\": $new_index/" "$STATE_FILE"
  fi
}

# Save handoff data for a role
crewkit_save_handoff() {
  local role="$1"
  local handoff_file="$CREWKIT_DIR/handoff-${role}.json"
  # Read from stdin
  cat > "$handoff_file"
  echo "$handoff_file"
}

# Read handoff data for a role
crewkit_read_handoff() {
  local role="$1"
  local handoff_file="$CREWKIT_DIR/handoff-${role}.json"
  if [ -f "$handoff_file" ]; then
    cat "$handoff_file"
  else
    echo "{}"
  fi
}

# Pause pipeline
crewkit_pause() {
  local reason="$1"
  if command -v jq &> /dev/null; then
    local tmp=$(mktemp)
    jq ".status = \"paused\" | .pause_reason = \"$reason\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  else
    sed -i '' 's/"status": "running"/"status": "paused"/' "$STATE_FILE"
  fi
}

# Complete pipeline
crewkit_complete() {
  if command -v jq &> /dev/null; then
    local tmp=$(mktemp)
    jq ".status = \"complete\" | .completed_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  else
    sed -i '' 's/"status": "running"/"status": "complete"/' "$STATE_FILE"
  fi
}

# Generate progress bar
crewkit_progress_bar() {
  local current="$1"
  local total="$2"
  local filled=$(( current * 10 / total ))
  local empty=$(( 10 - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo "$bar"
}

# Format status line
crewkit_status_line() {
  local command="$1"
  local current="$2"
  local total="$3"
  local role="$4"
  local action="$5"
  local bar=$(crewkit_progress_bar "$current" "$total")
  echo "[crewkit] $command │ $bar $current/$total │ $role │ $action"
}
