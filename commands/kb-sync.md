---
description: 세션 상태 확인 후 background-secretary 서브에이전트에 KB 문서화 위임
allowed-tools: Bash(bash:*)
---

현재 프로젝트의 세션 로그를 확인하고 background-secretary 서브에이전트에 KB 생성을 위임한다.

## 1. 환경 확인

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh
```

## 2. 세션 상태 확인

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/sync.sh
```

## 3. KB 생성 위임

**background-secretary 서브에이전트**에 KB 문서 생성/업데이트를 위임한다.

## 4. vault 재설정

vault를 변경하려면:

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh --reconfigure
```
