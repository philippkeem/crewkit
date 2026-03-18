#!/bin/bash
# Crewkit state management helper
# Usage: source this file or call functions directly

CREWKIT_DIR=".crewkit"
STATE_FILE="$CREWKIT_DIR/state.json"
HISTORY_FILE="$CREWKIT_DIR/history.jsonl"

# Initialize pipeline state
crewkit_init_state() {
  local command="$1"
  local args="$2"
  local stages="$3"  # JSON array of stages: '[{"roles":["planner"]},{"roles":["reviewer","security"],"parallel":true}]'
  local config_hash="${4:-defaults}"  # SHA256 hash of .crewkit.yml, or "defaults"

  mkdir -p "$CREWKIT_DIR" "$CREWKIT_DIR/artifacts"

  # Preserve previous handoffs for delta comparison (only from completed runs)
  local prev_status=""
  if [ -f "$STATE_FILE" ] && command -v jq &> /dev/null; then
    prev_status=$(jq -r '.status // ""' "$STATE_FILE" 2>/dev/null)
  fi

  if [ "$prev_status" = "complete" ]; then
    for f in "$CREWKIT_DIR"/handoff-*.json; do
      [ -f "$f" ] && cp "$f" "${f/handoff-/prev-handoff-}"
    done
  fi

  local pipeline_id
  pipeline_id="$(date +%s)"

  # Read previous completed run ID from history
  local prev_run_id="null"
  if [ -f "$HISTORY_FILE" ]; then
    prev_run_id=$(grep '"status":"complete"' "$HISTORY_FILE" | tail -1 | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    [ -n "$prev_run_id" ] && prev_run_id="\"$prev_run_id\"" || prev_run_id="null"
  fi

  cat > "$STATE_FILE" << EOF
{
  "state_version": 1,
  "pipeline_id": "$pipeline_id",
  "command": "$command",
  "args": "$args",
  "config_hash": "$config_hash",
  "stages": $stages,
  "current_stage_index": 0,
  "status": "running",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "completed_at": null,
  "pause_reason": null,
  "failed_role": null,
  "retries": {},
  "previous_run_id": $prev_run_id,
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

# Update current stage index
crewkit_advance_stage() {
  local new_index="$1"
  if command -v jq &> /dev/null; then
    local tmp=$(mktemp)
    jq ".current_stage_index = $new_index | .stages[$new_index - 1].status = \"complete\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  else
    sed -i '' "s/\"current_stage_index\": [0-9]*/\"current_stage_index\": $new_index/" "$STATE_FILE"
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

# Read previous run's handoff for delta comparison
crewkit_read_prev_handoff() {
  local role="$1"
  local prev_file="$CREWKIT_DIR/prev-handoff-${role}.json"
  if [ -f "$prev_file" ]; then
    cat "$prev_file"
  else
    echo "{}"
  fi
}

# Pause pipeline
crewkit_pause() {
  local reason="$1"
  local failed_role="${2:-}"
  if command -v jq &> /dev/null; then
    local tmp=$(mktemp)
    jq --arg reason "$reason" --arg role "$failed_role" \
      '.status = "paused" | .pause_reason = $reason | .failed_role = $role' \
      "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  else
    sed -i '' 's/"status": "running"/"status": "paused"/' "$STATE_FILE"
  fi
}

# Record retry attempt
crewkit_record_retry() {
  local role="$1"
  if command -v jq &> /dev/null; then
    local tmp=$(mktemp)
    jq ".retries[\"$role\"] = ((.retries[\"$role\"] // 0) + 1)" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  fi
}

# Get retry count for a role
crewkit_retry_count() {
  local role="$1"
  if command -v jq &> /dev/null && [ -f "$STATE_FILE" ]; then
    jq -r ".retries[\"$role\"] // 0" "$STATE_FILE"
  else
    echo "0"
  fi
}

# Complete pipeline
crewkit_complete() {
  local completed_at
  completed_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  if command -v jq &> /dev/null; then
    local tmp=$(mktemp)
    jq ".status = \"complete\" | .completed_at = \"$completed_at\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  else
    sed -i '' 's/"status": "running"/"status": "complete"/' "$STATE_FILE"
  fi

  # Append to history
  crewkit_append_history
}

# Append completed run to history (atomic write to prevent corruption)
crewkit_append_history() {
  if command -v jq &> /dev/null && [ -f "$STATE_FILE" ]; then
    local entry
    entry=$(jq -c '{
      id: .pipeline_id,
      command: .command,
      args: .args,
      status: .status,
      started_at: .started_at,
      completed_at: .completed_at,
      stages_executed: [.stages[].roles[]],
      duration_seconds: (
        ((.completed_at // now | todate) | fromdateiso8601) -
        (.started_at | fromdateiso8601)
      )
    }' "$STATE_FILE" 2>/dev/null)

    if [ -n "$entry" ]; then
      # Atomic append: write to temp file then rename to avoid corruption
      local tmp
      tmp=$(mktemp "${HISTORY_FILE}.XXXXXX")
      if [ -f "$HISTORY_FILE" ]; then
        cp "$HISTORY_FILE" "$tmp"
      fi
      echo "$entry" >> "$tmp"

      # Enforce max entries (default: 100)
      local max_entries=100
      local line_count
      line_count=$(wc -l < "$tmp" 2>/dev/null | tr -d ' ')
      if [ "$line_count" -gt "$max_entries" ] 2>/dev/null; then
        local excess=$((line_count - max_entries))
        tail -n +"$((excess + 1))" "$tmp" > "${tmp}.trimmed" && mv "${tmp}.trimmed" "$tmp"
      fi

      mv "$tmp" "$HISTORY_FILE"
    fi
  fi
}

# Read execution history
crewkit_read_history() {
  local count="${1:-10}"
  if [ -f "$HISTORY_FILE" ]; then
    tail -n "$count" "$HISTORY_FILE"
  else
    echo "[]"
  fi
}

# Compute config hash for change detection on resume
crewkit_config_hash() {
  local config_file="${1:-.crewkit.yml}"
  if [ -f "$config_file" ]; then
    shasum -a 256 "$config_file" 2>/dev/null | cut -d' ' -f1
  else
    echo "defaults"
  fi
}

# Check if config has changed since pipeline was initialized
crewkit_config_changed() {
  local current_hash
  current_hash=$(crewkit_config_hash)
  if command -v jq &> /dev/null && [ -f "$STATE_FILE" ]; then
    local saved_hash
    saved_hash=$(jq -r '.config_hash // "unknown"' "$STATE_FILE" 2>/dev/null)
    [ "$current_hash" != "$saved_hash" ]
  else
    return 1  # can't determine, assume unchanged
  fi
}

# Migrate state file from older schema versions
crewkit_migrate_state() {
  if command -v jq &> /dev/null && [ -f "$STATE_FILE" ]; then
    local version
    version=$(jq -r '.state_version // 0' "$STATE_FILE" 2>/dev/null)
    if [ "$version" -lt 1 ] 2>/dev/null; then
      # Migrate v0 → v1: add state_version and config_hash
      local tmp=$(mktemp)
      jq '.state_version = 1 | .config_hash = (.config_hash // "unknown")' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi
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

# Format status line (single role)
crewkit_status_line() {
  local command="$1"
  local current="$2"
  local total="$3"
  local role="$4"
  local action="$5"
  local bar=$(crewkit_progress_bar "$current" "$total")
  echo "[crewkit] $command │ $bar $current/$total │ $role │ $action"
}

# Format status line (parallel roles)
crewkit_parallel_status_line() {
  local command="$1"
  local current="$2"
  local total="$3"
  local roles="$4"  # e.g., "reviewer + security"
  local action="$5"
  local bar=$(crewkit_progress_bar "$current" "$total")
  echo "[crewkit] $command │ $bar $current/$total │ $roles │ $action"
}
