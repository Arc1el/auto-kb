---
name: auto-kb
description: This skill should be used automatically after completing any complex task, bug fix, refactor, or significant coding session. Commit the session log to auto-docs and launch the background KB documentation agent — without waiting for the user to ask.
---

# Auto KB Sync

자동으로 세션 로그를 커밋하고 KB 문서화 에이전트를 백그라운드로 실행한다.
실제 로직은 `scripts/` 폴더의 셸 스크립트가 담당한다.

## 트리거 조건

다음 중 하나라도 해당하면 즉시 실행:
- 복잡한 작업(버그 수정, 리팩터, 기능 구현 등)이 완료됐을 때
- 사용자가 "완료", "됐어", "고마워" 등으로 작업 종료를 암시할 때
- 긴 디버깅 세션이 끝났을 때
- 사용자가 명시적으로 요청할 때

**중요: 사용자가 따로 요청하지 않아도 자동 실행한다.**

## 스크립트

| 파일 | 역할 |
|------|------|
| `scripts/setup.sh` | 환경 감지, shell function 설치, auto-approve 등록 |
| `scripts/sync.sh [커밋메시지]` | 세션 로그 커밋 + KB 에이전트 백그라운드 실행 |

## 동작 원리

`cc`로 Claude를 실행하면 현재 프로젝트 디렉토리에 `.auto-kb/` 폴더가 생성된다.
세션 로그와 KB 문서는 모두 이 프로젝트별 `.auto-kb/` 안에 저장된다.

```
<프로젝트>/
  .auto-kb/
    .git/              # 독립 git repo
    .claude_raw.md     # 세션 로그
    docs/kb/           # KB 문서
```

## 실행 절차

### 0단계: 환경 셋업

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh
```

### 1-2단계: 커밋 + 에이전트 실행

커밋 메시지는 이번 세션 작업 내용을 한 줄로 요약해 인자로 전달한다.

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/sync.sh "feat: <이번 작업 핵심 내용>"
```

- `.auto-kb/` 폴더가 없으면 자동으로 건너뜀
- `.claude_raw.md` 가 없으면 자동으로 건너뜀
- 변경사항이 없으면 ("nothing to commit") 자동으로 건너뜀

### 3단계: 사용자에게 간단히 보고

한 줄로만 보고한다:
> "커밋 완료 & KB 에이전트 백그라운드 실행 중 (PID: XXXXX)"

길게 설명하지 않는다.
