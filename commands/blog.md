---
description: KB 문서를 블로그 포스트로 변환
allowed-tools: Bash(bash:*), Bash(obsidian:*)
---

현재 프로젝트의 KB 문서를 블로그 포스트로 변환한다.

## 실행 절차

### 1. KB 문서 목록 확인

설정 파일에서 vault 경로를 읽고, 블로그 버전이 없는 KB 문서를 조회한다:

```bash
obsidian search query="" path="KB/$(basename "$(pwd)")" limit=50
```

위 결과에서 `-blog.md`가 아닌 파일만 필터링해 사용자에게 보여준다.

### 2. background-secretary 서브에이전트에 위임

선택된 파일 목록과 함께 **background-secretary 서브에이전트**에 블로그 변환을 위임한다.

### 3. 완료 보고

위임 완료를 한 줄로 보고한다.
