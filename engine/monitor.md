# Monitor (Status Bar)

## Purpose

Provide real-time visibility into what Crewkit is doing. The user should always know:
1. Which command is running
2. Overall pipeline progress
3. Current active role
4. What tool/action is being executed right now

## Layout

```
[crewkit] <command> │ <progress-bar> <current>/<total> │ <role> │ <action>
```

### Components

| Component | Description | Example |
|-----------|-------------|---------|
| command | The /crew command being executed | `build`, `fix`, `ship` |
| progress-bar | Visual bar showing pipeline progress | `██████░░░░` |
| current/total | Numeric progress | `2/3` |
| role | Currently active role name | `planner`, `builder` |
| action | Current tool or task description | `Grep 실행중...` |

## State Transitions

### Normal Flow
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner  │ 요구사항 분석 중...
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner  │ 설계 문서 작성 중...
[crewkit] build │ ██████░░░░ 2/3 │ builder  │ 테스트 작성 중...
[crewkit] build │ ██████░░░░ 2/3 │ builder  │ 구현 중... Edit 실행
[crewkit] build │ ██████░░░░ 2/3 │ builder  │ 테스트 실행 중... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer │ diff 분석 중...
[crewkit] build │ ██████████ 3/3 │ reviewer │ 보안 체크... Score: A
✅ crewkit build 완료 │ 3/3 │ 소요: 4m 32s
```

### Error/Pause
```
[crewkit] build │ ██████░░░░ 2/3 │ reviewer │ ❌ Score: D — 2개 critical 이슈
⏸ 파이프라인 중단 │ /crew status로 이슈 확인 │ 수정 후 /crew resume
```

### Completion
```
✅ crewkit <command> 완료 │ <n>/<n> │ 소요: <elapsed>
```

## Implementation

Use Claude Code's statusline feature to render the monitor. Each role updates the status as it progresses through its steps.

### Update Points
- Role start: update role name and action
- Tool call: update action with tool name
- Substep completion: update action description
- Role completion: increment progress bar
- Pipeline completion: show final summary
- Error: show error indicator and pause message

## Verbosity Levels

Controlled by `.crewkit.yml` → `monitor.verbose`:

| Level | Shows |
|-------|-------|
| `false` | command + progress bar + role only |
| `true` (default) | + current tool/action details |
