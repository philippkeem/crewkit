# Crewkit Git Policy

> Top 10 GitHub 오픈소스 프로젝트(React, Vue, Next.js, TensorFlow, Flutter, VS Code, TypeScript, Angular, Svelte, Tailwind CSS)의 공통 패턴을 기반으로 설계.

---

## 1. 브랜치 전략: Trunk-Based Development

단일 `main` 브랜치를 trunk로 사용한다. `main`은 항상 배포 가능한 상태를 유지한다.

```
main (protected)
 ├── feat/42-pipeline-engine     ← 기능 개발
 ├── fix/57-router-crash         ← 버그 수정
 ├── docs/update-contributing    ← 문서
 └── chore/ci-setup              ← 설정/인프라
```

**장기 브랜치 없음** — release 브랜치, develop 브랜치 만들지 않는다. 릴리즈는 태그로 관리한다.

---

## 2. 브랜치 네이밍

```
<type>/<issue-number>-<short-description>
```

| Type | 용도 | 예시 |
|------|------|------|
| `feat/` | 새 기능 | `feat/12-pipeline-engine` |
| `fix/` | 버그 수정 | `fix/34-router-null-check` |
| `docs/` | 문서 변경 | `docs/api-reference` |
| `chore/` | CI, 설정, 리팩토링 | `chore/eslint-setup` |
| `perf/` | 성능 개선 | `perf/monitor-rendering` |
| `test/` | 테스트 추가/수정 | `test/planner-unit-tests` |

- 이슈가 있으면 번호를 포함한다 (`feat/12-...`)
- 이슈가 없으면 번호 생략 가능 (`docs/api-reference`)
- 소문자, 하이픈(`-`) 구분

---

## 3. 커밋 메시지: Conventional Commits

Angular/Vue/Svelte가 사용하는 [Conventional Commits](https://www.conventionalcommits.org/) 표준을 따른다.

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

### Type

| Type | 설명 | 릴리즈 영향 |
|------|------|------------|
| `feat` | 새 기능 | minor 버전 bump |
| `fix` | 버그 수정 | patch 버전 bump |
| `docs` | 문서만 변경 | - |
| `style` | 코드 의미 변경 없음 (포맷팅) | - |
| `refactor` | 버그 수정도 기능 추가도 아닌 코드 변경 | - |
| `perf` | 성능 개선 | patch 버전 bump |
| `test` | 테스트 추가/수정 | - |
| `build` | 빌드 시스템/외부 의존성 | - |
| `ci` | CI 설정 변경 | - |
| `chore` | 기타 (src/test 미변경) | - |

### Scope

crewkit의 모듈명을 scope로 사용한다:

```
engine, router, pipeline, monitor, handoff
planner, builder, reviewer, tester, shipper
presets, install, cli
```

### 예시

```
feat(pipeline): add parallel step execution

fix(router): handle missing role gracefully

docs(readme): add installation instructions

chore(ci): configure GitHub Actions workflow

feat(planner)!: redesign output format

BREAKING CHANGE: planner output now uses structured JSON instead of plain text.
```

### Breaking Changes

- 커밋 type 뒤에 `!`를 붙인다: `feat(engine)!: ...`
- footer에 `BREAKING CHANGE: <설명>` 작성
- major 버전 bump 트리거

---

## 4. PR (Pull Request) 정책

### 4.1 머지 방식: Squash Merge

**Squash merge만 허용한다.** (Top 10 프로젝트 전원 동일)

- PR의 모든 커밋이 하나의 커밋으로 합쳐져 main에 들어간다
- main 히스토리가 깔끔하게 유지된다
- PR 제목이 최종 커밋 메시지가 되므로, PR 제목을 Conventional Commits 형식으로 작성한다

### 4.2 PR 필수 요건

| 요건 | 설명 |
|------|------|
| CI 통과 | 모든 자동화 테스트/린트 통과 필수 |
| 리뷰 승인 | 최소 1명의 리뷰어 승인 필수 |
| 충돌 해결 | main과 충돌 없어야 함 |
| PR 템플릿 | 변경 사항, 테스트 방법, 관련 이슈 기술 |

### 4.3 PR 제목 형식

PR 제목 = squash merge 커밋 메시지이므로 Conventional Commits를 따른다:

```
feat(pipeline): add step retry with backoff
fix(monitor): correct progress calculation
docs: update contributing guide
```

### 4.4 PR 크기

- **작게 유지한다.** 파일 변경 10개 이하 권장
- 큰 기능은 여러 PR로 나눈다
- 리뷰어가 30분 내에 리뷰할 수 있는 크기가 이상적

---

## 5. main 브랜치 보호 규칙

GitHub Branch Protection으로 다음을 설정한다:

```yaml
main:
  require_pull_request:
    required_approving_review_count: 1
    dismiss_stale_reviews: true
    require_code_owner_reviews: false   # CODEOWNERS 추가 시 true로 변경
  require_status_checks:
    strict: true                        # main 최신 상태 기준으로 CI 통과 필요
    contexts:
      - "ci/test"
      - "ci/lint"
  require_linear_history: true          # squash merge 강제
  allow_force_pushes: false
  allow_deletions: false
```

---

## 6. 릴리즈 전략: Semver + Tags

[Semantic Versioning](https://semver.org/)을 따른다.

```
v<major>.<minor>.<patch>[-<prerelease>]
```

| 변경 종류 | 버전 bump | 예시 |
|-----------|-----------|------|
| Breaking change | major | `v1.0.0` → `v2.0.0` |
| 새 기능 (`feat`) | minor | `v1.0.0` → `v1.1.0` |
| 버그 수정 (`fix`) | patch | `v1.0.0` → `v1.0.1` |

### 릴리즈 프로세스

1. main에서 릴리즈 준비가 되면 `v*` 태그를 생성한다
2. GitHub Release를 만들고 changelog를 작성한다
3. `v1.0.0` 이전까지는 `v0.x.y`로 빠르게 iteration한다

### Pre-release

```
v0.1.0-alpha.1
v0.1.0-beta.1
v0.1.0-rc.1
v0.1.0          ← stable
```

---

## 7. 외부 기여자 워크플로우 (Fork & PR)

모든 외부 기여자는 Fork → PR 워크플로우를 따른다:

```bash
# 1. Fork & Clone
git clone https://github.com/<your-username>/crewkit.git
cd crewkit
git remote add upstream https://github.com/philippkeem/crewkit.git

# 2. 브랜치 생성
git checkout -b feat/42-new-feature

# 3. 작업 & 커밋
git commit -m "feat(engine): add new feature"

# 4. upstream 동기화
git fetch upstream
git rebase upstream/main

# 5. Push & PR
git push origin feat/42-new-feature
# GitHub에서 PR 생성
```

---

## 8. 금지 사항

| 금지 | 이유 | 참고 프로젝트 |
|------|------|--------------|
| `main`에 직접 push | 리뷰 없는 변경 방지 | 전원 |
| Force push (`--force`) | 히스토리 손실 방지 | TypeScript 명시적 금지 |
| Merge commit (non-squash) | 히스토리 오염 방지 | 전원 squash merge |
| 스타일만 변경하는 PR | 리뷰 리소스 낭비 | Flutter, Tailwind |
| 승인 없는 대규모 리팩토링 | 이슈/RFC 먼저 논의 | Svelte RFC 프로세스 |

---

## 9. 이슈 & 라벨 시스템

### 이슈 타입 라벨

| 라벨 | 설명 |
|------|------|
| `bug` | 버그 리포트 |
| `feature` | 기능 요청 |
| `docs` | 문서 개선 |
| `good first issue` | 첫 기여자용 쉬운 이슈 |
| `help wanted` | 기여 환영하는 이슈 |

### 우선순위 라벨

| 라벨 | 설명 |
|------|------|
| `priority: critical` | 즉시 수정 |
| `priority: high` | 다음 릴리즈 전 수정 |
| `priority: medium` | 계획에 포함 |
| `priority: low` | 여유 있을 때 |

### 모듈 라벨

`scope: engine` `scope: planner` `scope: builder` `scope: reviewer` `scope: tester` `scope: shipper`

---

## 10. 기여 가이드 (Contributing Guide)

### 10.1 시작하기

```bash
# Fork 후 클론
git clone https://github.com/<your-username>/crewkit.git
cd crewkit
git remote add upstream https://github.com/philippkeem/crewkit.git

# 의존성 설치
npm install
```

### 10.2 기여 프로세스

```
1. 이슈 확인/생성  →  2. Fork & 브랜치  →  3. 구현  →  4. 테스트  →  5. PR 제출  →  6. 리뷰  →  7. 머지
```

#### Step 1: 이슈 먼저

- 버그 수정: 기존 이슈가 없으면 새로 생성한다
- 새 기능: 이슈에서 **먼저 논의**한 후 구현한다 (불필요한 작업 방지)
- `good first issue` 라벨이 붙은 이슈는 첫 기여자에게 적합하다

#### Step 2: 브랜치 생성

```bash
git fetch upstream
git checkout -b feat/42-my-feature upstream/main
```

#### Step 3: 구현

- 기존 코드 스타일을 따른다
- 변경 범위를 최소화한다 — 한 PR에 한 가지 목적
- 스타일만 변경하는 PR은 받지 않는다

#### Step 4: 테스트

```bash
npm test                # 전체 테스트
npm run lint            # 린트 검사
```

- 새 기능에는 반드시 테스트를 포함한다
- 버그 수정에는 재현 테스트를 포함한다
- 기존 테스트가 깨지지 않는지 확인한다

#### Step 5: PR 제출

```bash
git fetch upstream
git rebase upstream/main
git push origin feat/42-my-feature
```

GitHub에서 PR을 생성하고 아래 템플릿을 따른다:

```markdown
## 변경 사항
- 무엇을 왜 변경했는지 설명

## 관련 이슈
Closes #42

## 테스트
- [ ] 새 테스트 추가
- [ ] 기존 테스트 통과 확인
- [ ] 린트 통과 확인
```

#### Step 6: 리뷰 대응

- 리뷰어 피드백에 새 커밋으로 대응한다 (force push 금지)
- 모든 대화가 resolve 되어야 머지 가능하다

#### Step 7: 머지

- 메인테이너가 squash merge로 머지한다
- PR 제목이 최종 커밋 메시지가 된다

### 10.3 코드 스타일

| 항목 | 규칙 |
|------|------|
| 들여쓰기 | 2 spaces |
| 문자열 | 작은따옴표 (`'`) |
| 세미콜론 | 사용 안 함 |
| 줄 길이 | 100자 이하 권장 |
| 파일명 | kebab-case (`pipeline-engine.js`) |
| 변수/함수 | camelCase |
| 상수 | UPPER_SNAKE_CASE |

### 10.4 커밋 품질 체크리스트

PR 제출 전 확인:

- [ ] Conventional Commits 형식의 커밋 메시지
- [ ] 테스트 추가/수정 완료
- [ ] `npm test` 통과
- [ ] `npm run lint` 통과
- [ ] 불필요한 파일 미포함 (`.env`, `node_modules`, `.DS_Store`)
- [ ] 문서 업데이트 (API 변경 시)

### 10.5 대규모 변경 (RFC)

아키텍처 변경, 새로운 역할 추가, API 변경 등 대규모 변경은 RFC(Request for Comments) 프로세스를 따른다:

1. GitHub Issue에 `rfc` 라벨로 제안서 작성
2. 최소 7일간 커뮤니티 논의
3. 메인테이너 승인 후 구현 시작

### 10.6 행동 강령 (Code of Conduct)

모든 기여자는 상호 존중하며 협력한다. 차별, 비하, 괴롭힘은 허용하지 않는다. 위반 시 메인테이너가 조치한다.

---

## 11. 참고한 프로젝트

| 프로젝트 | Stars | 핵심 차용 요소 |
|----------|-------|---------------|
| React | ~244k | Trunk-based, squash merge |
| TensorFlow | ~194k | CLA, 단계적 리뷰 |
| VS Code | ~183k | 월간 릴리즈, 라벨 시스템 |
| Flutter | ~176k | 테스트 필수, revert-first 문화 |
| Next.js | ~138k | Pre-release 채널 |
| TypeScript | ~108k | Force push 금지, PR 제목 = 커밋 |
| Angular | ~100k | Conventional Commits (원조) |
| Tailwind CSS | ~94k | CODEOWNERS, 기능 PR 신중 |
| Svelte | ~86k | Changesets, RFC 프로세스 |
| Vue | ~53k | Conventional Commits, git hooks 검증 |
