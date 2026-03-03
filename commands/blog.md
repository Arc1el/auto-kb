---
description: KB 문서를 블로그 포스트로 변환
allowed-tools: Bash(bash:*), Bash(find:*), Bash(ls:*), Bash(echo:*)
---

현재 프로젝트의 `.auto-kb/docs/kb/` 내 KB 문서 목록을 확인하고, 사용자가 선택한 파일을 블로그 포스트로 변환한다.

## 실행 절차

### 1. 블로그 미생성 문서 목록 확인

```bash
find "${AUTO_DOCS:-.auto-kb}/docs/kb" \
  -maxdepth 1 -name "*.md" ! -name "*-blog.md" \
  | sort | nl -ba
```

위 결과를 사용자에게 보여주고, 어떤 파일을 블로그로 변환할지 선택하도록 안내한다.
(AskUserQuestion 또는 텍스트로 선택 요청)

### 2. 선택된 파일로 blog.sh 실행

선택된 파일명을 공백으로 구분해 인자로 전달한다:

```bash
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/blog.sh <파일명1> <파일명2> ...
```

파일명은 경로 없이 파일명만 전달한다 (예: `claude-code-setup.md`).

### 3. 완료 보고

실행된 에이전트 수와 출력 파일명을 한 줄로 보고한다.
로그 확인: `tail -f /tmp/auto_kb_blog.log`
