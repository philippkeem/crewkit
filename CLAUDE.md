# Crewkit 프로젝트 컨텍스트

## 프로젝트 개요

**Crewkit**은 Claude Code를 전문가 팀으로 만드는 범용 오픈소스 스킬 프레임워크.

- **목적**: gstack + superpowers의 장점을 합쳐서 완전히 새로운 자체 프레임워크로 설계
- **타겟**: 오픈소스 공개 (누구나 사용 가능)
- **핵심 차별점**: 적은 스킬(5개 역할) + 자동 연계(파이프라인) + 실시간 모니터(상태바)

### 해결하는 문제

| 기존 문제 | Crewkit 해결책 |
|-----------|---------------|
| 스킬이 너무 많아 진입장벽 높음 | 5개 역할 + 6개 커맨드로 단순화 |
| 스킬 간 연계 부족 | 파이프라인 엔진으로 자동 연결 |
| 스킬 활용 투명성 부족 | 실시간 모니터(상태바)로 가시성 확보 |

---

## 설계 (승인 완료)

상세 설계 문서: `docs/plans/2026-03-15-crewkit-framework-design.md`

### 아키텍처

```
crewkit/
├── engine/           # 코어 엔진 (라우터, 파이프라인, 모니터, 핸드오프)
├── roles/            # 5개 역할 (planner, builder, reviewer, tester, shipper)
├── presets/          # 4개 파이프라인 프리셋
├── install/          # 설치/진단 스킬
├── .crewkit.yml.example
├── setup             # CLI 설치 스크립트
├── README.md
└── package.json
```

### 5개 역할

| 역할 | 전문 분야 | 참고 출처 |
|------|-----------|-----------|
| **Planner** | 설계, 아키텍처, 디버깅 (3가지 모드: product/architecture/debug) | gstack plan-ceo-review + plan-eng-review + superpowers brainstorming |
| **Builder** | TDD 구현, 병렬 에이전트 | superpowers TDD + executing-plans + parallel-agents |
| **Reviewer** | 보안, 성능, 품질 게이트 (A/B/C/D 점수) | gstack review + superpowers code-review + verification |
| **Tester** | 유닛 테스트, diff-QA, 브라우저 테스트 (4가지 모드) | gstack browse + qa + setup-browser-cookies |
| **Shipper** | 릴리즈, 체인지로그, 회고 | gstack ship + retro + superpowers finishing-branch |

### 6개 워크플로우 커맨드

| 커맨드 | 파이프라인 |
|--------|-----------|
| `/crew plan` | planner |
| `/crew build` | planner → builder → reviewer |
| `/crew fix` | planner(debug) → builder → tester |
| `/crew review` | reviewer → tester |
| `/crew ship` | reviewer → tester → shipper |
| `/crew qa` | tester |

### 5개 관리 커맨드

`/crew install` `/crew update` `/crew doctor` `/crew config` `/crew status`

### 공통 옵션

`--skip <role>` `--only <role>` `--dry-run` `--resume`

### 모니터 (상태바)

```
[crewkit] build │ ██████░░░░ 2/3 │ builder │ 테스트 실행 중... 12/12 pass
```

파이프라인 전체 진행률 + 현재 역할 + 현재 도구/작업을 실시간 표시.

### 역할 간 핸드오프

각 역할 완료 시 구조화된 데이터를 다음 역할에 전달:
- planner → { design, files, decisions, plan_steps }
- builder → { changes, tests, coverage, build_status }
- reviewer → { score, approved, issues, summary }
- tester → { passed, failed, coverage, screenshots, report }

---

## Git 정보

- **계정**: philippkeem@gmail.com
- **SSH**: `git@github.com-philippkeem:philippkeem/crewkit.git`
- **SSH Key**: `~/.ssh/id_ed25519_crewkit`
- **SSH Host**: `github.com-philippkeem` (SSH config에 별도 Host alias 설정됨)

### 현재 상태

- Git init 완료
- Remote 설정 완료
- SSH 인증 테스트 통과
- **초기 커밋 + push 아직 안 함**
- **Git 브랜치 정책 미정** — 사용자가 이 세션에서 정할 예정

---

## 나의 역할

- **CTO** (20년차 전문가)
- 겸업: 마케팅 + 디자인
- 업무 원칙: 기획 소통 → 합의 → 코딩 진행
- 답변 원칙: 사실 기반, 근거 있는 답변
- **Co-Authored-By 라인 절대 추가하지 않음**

---

## 다음 할 일

1. ~~Git 브랜치 정책 수립~~ ✅ `docs/GIT_POLICY.md` 완료
2. 초기 커밋 + push
3. ~~구현 계획(implementation plan) 작성~~ ✅ 설계 문서 기반 직접 구현
4. ~~스킬 파일 실제 동작하도록 구현~~ ✅ v0.1.0 구현 완료
5. 실제 프로젝트에서 `/crew build` 테스트
6. GitHub Actions CI 설정
7. 브라우저 테스트 바이너리 구현 (`roles/tester/browse/`)
