#!/usr/bin/env bash
# auto-kb: 세션 로그 커밋 + KB 에이전트 백그라운드 실행
# 실행: bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/sync.sh "커밋 메시지"
# 인자 없으면 기본 메시지 사용

set -e

AUTO_DOCS="${AUTO_DOCS:-$HOME/Documents/auto-docs}"
COMMIT_MSG="${1:-"chore: 세션 로그 동기화"}"

# [1] .claude_raw.md 존재 확인
if [ ! -f "$AUTO_DOCS/.claude_raw.md" ]; then
  echo "[skip] .claude_raw.md 없음 — 로깅 비활성 상태. setup.sh를 먼저 실행하세요."
  exit 0
fi

# [2] 변경사항 확인 후 커밋
cd "$AUTO_DOCS"
git add .claude_raw.md

if git diff --cached --quiet; then
  echo "[skip] 변경사항 없음 — 커밋 및 에이전트 실행 건너뜀"
else
  git commit -m "$COMMIT_MSG"
  echo "[done] 커밋: $COMMIT_MSG"

  # [3] 백그라운드 KB 에이전트 실행 (커밋이 실제로 발생한 경우에만)
  nohup env -u CLAUDECODE claude --dangerously-skip-permissions --add-dir "$AUTO_DOCS" -p \
"작업 디렉토리는 $AUTO_DOCS 야. \
1. 우선 bash로 'git -C $AUTO_DOCS rev-parse HEAD~1 2>/dev/null' 실행해서 이전 커밋이 존재하는지 확인해. \
존재하면 'git -C $AUTO_DOCS diff HEAD~1 HEAD'를, 없으면 'git -C $AUTO_DOCS show HEAD'를 실행해서 변경 내용을 분석해. \
이 diff 안에는 claude_raw.md 세션 대화(시행착오, 에러 로그 등)가 모두 들어있어. \
이를 바탕으로 이번 작업의 핵심 주제와 해결 과정을 파악해라. \
2. '$AUTO_DOCS/docs/kb/' 폴더(없으면 생성) 내에 이 주제와 관련된 기존 마크다운(.md) 문서가 있는지 검색해라. \
3. 관련 문서가 존재한다면 그 파일을 읽고 이번 업데이트 내용을 하단에 자연스럽게 이어서 작성해라. \
4. 관련 문서가 없다면 적절한 제목으로 새 마크다운 문서를 생성해라. \
5. 모든 문서 작업이 끝나면 조용히 종료해라." \
  > /dev/null 2>&1 &
  echo "[done] KB 에이전트 실행됨 (PID: $!)"
fi
