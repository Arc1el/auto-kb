---
description: 세션 로그 커밋 후 KB 문서화 에이전트 실행
allowed-tools: Bash(bash:*), Bash(chmod:*)
---

auto-docs 세션 로그를 커밋하고 KB 문서화 에이전트를 백그라운드로 실행한다.
아래 단계를 순서대로 실행한다. 추가 설명 없이 도구 호출만 한다.

## 1. 환경 셋업

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh
```

## 2. 커밋 + 에이전트 실행

현재 세션의 작업 내용을 한 줄로 요약해 인자로 전달한다.

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/sync.sh "feat: <작업 요약>"
```

완료 후 커밋 해시와 에이전트 PID를 한 줄로 보고한다.
