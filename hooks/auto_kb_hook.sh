#!/usr/bin/env bash
# auto-kb: Stop hook — 3000줄 이상 추가 시 자동 sync

PLUGIN_ROOT="$HOME/.claude/plugins/auto-kb"
AUTO_DOCS="${AUTO_DOCS:-$HOME/Documents/auto-docs}"
FORCE_THRESHOLD=3000

# .claude_raw.md 없으면 스킵
[ -f "$AUTO_DOCS/.claude_raw.md" ] || exit 0

# git repo 없으면 스킵
[ -d "$AUTO_DOCS/.git" ] || exit 0

# 미커밋 추가 줄 수 체크
ADDED_LINES=$(git -C "$AUTO_DOCS" diff HEAD -- .claude_raw.md 2>/dev/null \
  | grep "^+" | grep -v "^+++" | wc -l | tr -d ' ')

[ "${ADDED_LINES:-0}" -ge "$FORCE_THRESHOLD" ] || exit 0

# 임계값 초과 → sync 실행 (백그라운드)
bash "$PLUGIN_ROOT/skills/auto-kb/scripts/sync.sh" \
  "chore: 자동 싱크 (${ADDED_LINES}줄 추가)" \
  > /tmp/auto_kb_hook.log 2>&1 &
