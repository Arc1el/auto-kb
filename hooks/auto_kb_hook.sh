#!/usr/bin/env bash
# auto-kb: Stop hook — 세션 로그가 일정 줄 이상이면 알림
# 서브에이전트 트리거는 할 수 없으므로 마커만 남김

CONFIG_FILE="$HOME/.config/auto-kb/config.json"
CONFIG_DIR="$HOME/.config/auto-kb"
FORCE_THRESHOLD=3000

[ -f "$CONFIG_FILE" ] || exit 0

VAULT_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['vault_path'])" 2>/dev/null)
SESSIONS_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('sessions_path','Sessions'))" 2>/dev/null)

[ -n "$VAULT_PATH" ] || exit 0

PROJECT=$(basename "$(pwd)")
SESSION_DIR="$VAULT_PATH/$SESSIONS_PATH/$PROJECT"

[ -d "$SESSION_DIR" ] || exit 0

LATEST=$(ls -t "$SESSION_DIR"/*.md 2>/dev/null | head -1)
[ -n "$LATEST" ] || exit 0

MARKER_FILE="$CONFIG_DIR/last_sync_${PROJECT}.pos"
LAST_POS=0
[ -f "$MARKER_FILE" ] && LAST_POS=$(cat "$MARKER_FILE" 2>/dev/null || echo 0)

CURRENT_LINES=$(wc -l < "$LATEST" | tr -d ' ')
UNPROCESSED=$((CURRENT_LINES - LAST_POS))

[ "$UNPROCESSED" -ge "$FORCE_THRESHOLD" ] || exit 0

echo "$CURRENT_LINES" > "$MARKER_FILE"
echo "[auto-kb] ${UNPROCESSED}줄 미처리 감지 ($(basename "$LATEST"))" \
  >> /tmp/auto_kb_hook.log 2>&1
