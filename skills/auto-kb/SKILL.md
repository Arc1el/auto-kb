---
name: auto-kb
description: This skill should be used automatically after completing any complex task, bug fix, refactor, or significant coding session. Delegate KB generation to the background-secretary subagent — without waiting for the user to ask.
---

# Auto KB Sync

작업 완료 시 background-secretary 서브에이전트에 KB 문서화를 자동 위임한다.
세션 로그는 Obsidian vault에서 직접 관리된다.

## 트리거 조건

다음 중 하나라도 해당하면 즉시 실행:
- 복잡한 작업(버그 수정, 리팩터, 기능 구현 등)이 완료됐을 때
- 사용자가 "완료", "됐어", "고마워" 등으로 작업 종료를 암시할 때
- 긴 디버깅 세션이 끝났을 때
- 사용자가 명시적으로 요청할 때

**중요: 사용자가 따로 요청하지 않아도 자동 실행한다.**

## 실행 절차

### 1단계: 환경 확인

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh
```

### 2단계: 세션 상태 확인

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/sync.sh
```

### 3단계: KB 문서화 위임

**background-secretary 서브에이전트**에 KB 문서 생성/업데이트를 위임한다.
서브에이전트는 백그라운드에서 실행되므로 메인 대화를 차단하지 않는다.

서브에이전트가 수행하는 작업:
1. `~/.config/auto-kb/config.json`에서 vault 설정 읽기
2. 최근 세션 로그 분석
3. Obsidian vault에 KB 문서 생성/업데이트 (`obsidian create`)

### 4단계: 사용자에게 간단히 보고

한 줄로만 보고한다:
> "background-secretary에 KB 생성 위임 완료"

길게 설명하지 않는다.
