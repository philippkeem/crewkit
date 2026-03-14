# Crewkit — Claude Code 플러그인 프레임워크 설계

> 작성일: 2026-03-15
> 상태: 설계 승인 완료

---

## 1. 개요

**Crewkit**은 Claude Code를 전문가 팀으로 만드는 범용 오픈소스 스킬 프레임워크.

gstack(Garry Tan)과 superpowers의 장점을 참고하되, 다음 문제를 해결한다:

| 기존 문제 | Crewkit 해결책 |
|-----------|---------------|
| 스킬이 너무 많아 진입장벽 높음 | 5개 역할 + 6개 커맨드로 단순화 |
| 스킬 간 연계 부족 | 파이프라인 엔진으로 자동 연결 |
| 스킬 활용 투명성 부족 | 실시간 모니터(상태바)로 가시성 확보 |

### 핵심 원칙

- 사용자는 `/crew <의도>`만 입력
- engine이 의도 해석 → preset 선택 → 역할 순서대로 호출
- monitor가 전체 파이프라인 진행률을 실시간 표시

---

## 2. 아키텍처

```
crewkit/
├── engine/
│   ├── SKILL.md               # /crew 진입점 + 커맨드 라우팅
│   ├── pipeline.md            # 파이프라인 실행 엔진
│   ├── monitor.md             # 상태바 렌더링
│   └── handoff.md             # 역할 간 데이터 전달 스펙
│
├── roles/
│   ├── planner/SKILL.md       # 설계 (product/architecture/debug)
│   ├── builder/SKILL.md       # 구현 (TDD + 병렬 에이전트)
│   ├── reviewer/SKILL.md      # 코드 리뷰 (보안/성능/품질)
│   ├── tester/SKILL.md        # QA (unit/diff-qa/browse/full)
│   └── shipper/SKILL.md       # 릴리즈 (PR/머지/회고)
│
├── presets/
│   ├── full-cycle.md          # plan → build → review → test → ship
│   ├── quick-fix.md           # debug → build → test
│   ├── review-only.md         # review → test
│   └── ship-only.md           # review → test → ship
│
├── install/
│   ├── SKILL.md               # /crew install 대화형 설치
│   └── doctor.md              # /crew doctor 환경 진단
│
├── setup                      # CLI 설치 스크립트
├── .crewkit.yml.example       # 설정 파일 예시
├── package.json
├── LICENSE
└── README.md
```

---

## 3. 커맨드 체계

### 워크플로우 커맨드 (6개)

| 커맨드 | 의도 | 파이프라인 |
|--------|------|-----------|
| `/crew plan` | 아이디어 → 설계 | planner |
| `/crew build` | 설계 → 구현 | planner → builder → reviewer |
| `/crew fix` | 버그 수정 | planner(debug) → builder → tester |
| `/crew review` | 코드 리뷰 | reviewer → tester |
| `/crew ship` | 릴리즈 | reviewer → tester → shipper |
| `/crew qa` | QA 테스트 | tester |

### 관리 커맨드 (5개)

| 커맨드 | 설명 |
|--------|------|
| `/crew install` | 대화형 설치 |
| `/crew update` | 최신 버전 업데이트 |
| `/crew doctor` | 환경 진단 |
| `/crew config` | 설정 편집 |
| `/crew status` | 파이프라인 상태/이력 |

### 공통 옵션

```bash
--skip <role>      # 특정 역할 건너뛰기
--only <role>      # 특정 역할만 실행
--dry-run          # 시뮬레이션
--resume           # 중단된 파이프라인 이어서
```

---

## 4. 5개 역할 상세

### 4-1. Planner (설계자)

참고: gstack `plan-ceo-review` + `plan-eng-review` + superpowers `brainstorming` + `writing-plans`

| 모드 | 트리거 | 동작 |
|------|--------|------|
| product | 새 기능, 아이디어 | CEO 관점 — 10-star 제품 사고, 스코프 조정 |
| architecture | 기술 설계 | 엔지니어 관점 — 데이터 플로우, 에지케이스, 테스트 매트릭스 |
| debug | `/crew fix` | 체계적 디버깅 — 가설 수립 → 검증 → 근본 원인 |

자동 모드 선택: engine이 컨텍스트(git diff, 사용자 입력)를 분석하여 결정.

### 4-2. Builder (구현자)

참고: superpowers `TDD` + `executing-plans` + `parallel-agents`

- TDD 강제: 테스트 먼저 → 구현 → 커버리지 확인
- 계획 실행: planner의 설계 문서를 단계별로 실행
- 병렬 에이전트: 독립 작업이면 자동으로 병렬 디스패치
- 완료 조건: 테스트 통과 + 빌드 성공

### 4-3. Reviewer (검토자)

참고: gstack `review` + superpowers `code-review` + `verification`

- 자동 분석: git diff 기반, 변경 파일/라인 스캔
- 체크리스트: SQL 안전성, 신뢰 경계, 보안(OWASP), 성능
- 점수 부여: A/B/C/D 등급 + 구체적 이슈 리스트
- 게이트: C 이하면 파이프라인 중단, 수정 요청

### 4-4. Tester (테스터)

참고: gstack `browse` + `qa` + `setup-browser-cookies`

| 모드 | 동작 |
|------|------|
| unit | 테스트 실행 + 커버리지 리포트 |
| diff-qa | git diff 분석 → 영향받는 화면만 자동 테스트 |
| browse | headless 브라우저로 실제 URL 접속/인터랙션/스크린샷 |
| full | 전체 QA 체크리스트 순회 |

쿠키/세션 관리 내장으로 로그인 상태 테스트 가능.

### 4-5. Shipper (배포자)

참고: gstack `ship` + `retro` + superpowers `finishing-a-development-branch`

- 프리플라이트: reviewer 통과 + tester 통과 확인
- 자동 릴리즈: 버전 범프 → CHANGELOG → 커밋 → PR 생성
- 배포 전략: 프로젝트 설정에 따라 (PR만, 자동 머지, 직접 push)
- 회고: ship 완료 후 자동으로 커밋 분석 + 회고 리포트 생성/저장

---

## 5. 역할 간 데이터 전달 (Handoff)

각 역할이 완료되면 핸드오프 객체를 다음 역할에 전달:

```
planner → { design: "...", files: [...], decisions: [...] }
builder → { changes: [...], tests: [...], coverage: "87%" }
reviewer → { issues: [...], approved: true, score: "A" }
tester  → { passed: 12, failed: 0, screenshots: [...] }
```

---

## 6. 모니터 (상태바)

### 표시 레이아웃

```
[crewkit] <커맨드> │ <진행률바> <n/total> │ <현재 역할> │ <현재 작업>
```

### 상태 변화 예시

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

### 에러/중단 시

```
[crewkit] build │ ██████░░░░ 2/3 │ reviewer │ ❌ Score: D — 2개 critical 이슈
⏸ 파이프라인 중단 │ /crew status로 이슈 확인 │ 수정 후 /crew resume
```

---

## 7. 설치 및 설정

### CLI 설치

```bash
git clone https://github.com/crewkit/crewkit.git ~/.claude/skills/crewkit
cd ~/.claude/skills/crewkit && ./setup
```

### Claude Code 내 설치

```bash
/crew install                  # 대화형 설치
/crew install --global         # 글로벌
/crew install --project        # 프로젝트 레벨
```

### 설치 흐름

```
[crewkit] install │ ██░░░░░░░░ 1/4 │ 환경 확인...
  ✓ Claude Code, ✓ Git, ✗ Bun → 설치 (Y/n)

[crewkit] install │ ████░░░░░░ 2/4 │ Bun 설치...
  ✓ Bun v1.2.x

[crewkit] install │ ██████░░░░ 3/4 │ Crewkit 설치...
  ✓ ~/.claude/skills/crewkit/ 생성
  ✓ Chromium 빌드
  ✓ settings.json 등록

[crewkit] install │ ████████░░ 4/4 │ 설정...
  ? 범위: 글로벌/프로젝트
  ? 게이트: A/B/C
  ? 브라우저 테스트: Y/n

✅ 설치 완료! /crew build 로 시작하세요.
```

### 프로젝트 설정 (.crewkit.yml)

```yaml
project:
  name: "my-app"
  stack: "next.js + typescript"

pipeline:
  build:
    skip: []
    reviewer:
      gate: "B"
  ship:
    strategy: "pr"           # pr | auto-merge | direct-push
    changelog: true
    version-bump: "semver"

tester:
  browse:
    base-url: "http://localhost:3000"
    cookies-from: "chrome"
  coverage:
    minimum: 80

monitor:
  verbose: true
```

설정 없이도 합리적 기본값으로 동작 (gate: C, strategy: pr, coverage: 80%).

### 환경 진단

```
/crew doctor

  환경: ✓ Claude Code, ✓ Git, ✓ Bun, ✓ Chromium
  설정: ✓ skills/crewkit/, ✓ settings.json, ✓ .crewkit.yml
  역할: ✓ planner, ✓ builder, ✓ reviewer, ✓ tester, ✓ shipper
  ✅ 모든 항목 정상
```

---

## 8. 참고 출처

| 기능 | 출처 |
|------|------|
| headless 브라우저, diff-qa, 코드 리뷰, 릴리즈 자동화, 회고 | [gstack](https://github.com/garrytan/gstack) |
| brainstorming, TDD, 체계적 디버깅, 완료 전 검증, 병렬 에이전트 | superpowers |
| 파이프라인 엔진, 모니터 상태바, 역할 기반 설계 | Crewkit 자체 설계 |
