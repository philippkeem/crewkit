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
| action | Current tool or task description (localized) | `analyzing...` / `분석 중...` |

## State Transitions

### Normal Flow (Sequential Stages)

Action messages are displayed in the user's locale. Examples by language:

#### English (locale: en)
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ analyzing requirements...
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ writing design doc...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ writing tests...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ implementing... Edit
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ running tests... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ running in parallel...
[crewkit] build │ ██████████ 3/3 │ reviewer ✓ security ✓ │ stage complete
✅ crewkit build complete │ 3/3 │ elapsed: 4m 32s │ score:B security:PASS
```

#### Korean (locale: ko)
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ 요구사항 분석 중...
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ 설계 문서 작성 중...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ 테스트 작성 중...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ 구현 중... Edit
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ 테스트 실행 중... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ 병렬 실행 중...
[crewkit] build │ ██████████ 3/3 │ reviewer ✓ security ✓ │ 스테이지 완료
✅ crewkit build 완료 │ 3/3 │ 소요: 4m 32s │ score:B security:PASS
```

#### Japanese (locale: ja)
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ 要件分析中...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ テスト実行中... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ 並列実行中...
✅ crewkit build 完了 │ 3/3 │ 所要: 4m 32s │ score:B security:PASS
```

#### Chinese (locale: zh)
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ 分析需求中...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ 运行测试中... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ 并行执行中...
✅ crewkit build 完成 │ 3/3 │ 耗时: 4m 32s │ score:B security:PASS
```

#### Spanish (locale: es)
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ analizando requisitos...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ ejecutando tests... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ ejecución en paralelo...
✅ crewkit build completo │ 3/3 │ tiempo: 4m 32s │ score:B security:PASS
```

#### French (locale: fr)
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ analyse des exigences...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ exécution des tests... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ exécution en parallèle...
✅ crewkit build terminé │ 3/3 │ durée: 4m 32s │ score:B security:PASS
```

#### German (locale: de)
```
[crewkit] build │ ██░░░░░░░░ 1/3 │ planner            │ Anforderungen analysieren...
[crewkit] build │ ██████░░░░ 2/3 │ builder            │ Tests ausführen... 12/12 pass
[crewkit] build │ ██████████ 3/3 │ reviewer + security │ parallele Ausführung...
✅ crewkit build abgeschlossen │ 3/3 │ Dauer: 4m 32s │ score:B security:PASS
```

### Babysit Mode
```
# English
[crewkit] babysit │ ██████░░░░ │ CI running... 3/5 checks passed
[crewkit] babysit │ ████████░░ │ retrying flaky test... attempt 2/3
[crewkit] babysit │ ██████████ │ ✅ all checks passed — auto-merge enabled

# Korean
[crewkit] babysit │ ██████░░░░ │ CI 실행 중... 3/5 체크 통과
[crewkit] babysit │ ████████░░ │ 불안정 테스트 재시도 중... 2/3회
[crewkit] babysit │ ██████████ │ ✅ 모든 체크 통과 — 자동 머지 활성화
```

### Error/Pause
```
# English — reviewer gate
[crewkit] build │ ██████████ 3/3 │ reviewer │ ❌ Score: D — 2 critical issues
⏸ Pipeline paused │ check issues with /crew status │ fix and /crew resume

# English — security gate
[crewkit] build │ ██████████ 3/3 │ security │ ❌ FAIL — 1 critical vulnerability
⏸ Pipeline paused │ fix security issues │ /crew resume or /crew resume --retry security

# Korean
[crewkit] build │ ██████████ 3/3 │ reviewer │ ❌ Score: D — 2개 critical 이슈
⏸ 파이프라인 중단 │ /crew status로 이슈 확인 │ 수정 후 /crew resume

[crewkit] build │ ██████████ 3/3 │ security │ ❌ FAIL — 1개 critical 취약점
⏸ 파이프라인 중단 │ 보안 이슈 수정 필요 │ /crew resume 또는 /crew resume --retry security
```

### Completion
```
# English
✅ crewkit <command> complete │ <n>/<n> │ elapsed: <elapsed>

# Korean
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

---

## Flow Diagram

### Status Bar Rendering

```
[crewkit] <cmd> │ <bar> <n>/<total> │ <role> │ <action>
     │               │                  │          │
     │               │                  │          └── current tool/task
     │               │                  └── active role name
     │               └── ██████░░░░ visual progress
     └── build / fix / ship / qa / review
```

### Update Trigger Points

```
Pipeline start ──► [crewkit] build │ ░░░░░░░░░░ 0/3 │ --- │ initializing...
  │
  ├── role start ──► [crewkit] build │ ██░░░░░░░░ 1/3 │ planner │ starting...
  │   │
  │   ├── tool call ──► ... │ planner │ Glob: searching files...
  │   ├── substep ───► ... │ planner │ writing design doc...
  │   └── role done ──► ... │ planner │ ✓ complete
  │
  ├── next role ──► [crewkit] build │ ██████░░░░ 2/3 │ builder │ starting...
  │   └── (same trigger cycle)
  │
  └── pipeline done ──► ✅ crewkit build complete │ 3/3 │ elapsed: 4m 32s
```

### State Transitions

```
RUNNING ──────────────────────────────────► COMPLETE
   │                                           │
   │   gate fail or error                      │
   └──► PAUSED ──► /crew resume ──► RUNNING ───┘
            │
            └── show: ⏸ Pipeline paused │ reason
```
