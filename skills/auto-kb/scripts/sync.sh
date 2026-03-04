#!/usr/bin/env bash
# auto-kb: 현재 세션 로그 상태 확인
# background-secretary 서브에이전트가 KB 생성 시 참조할 정보를 출력
# 실행: bash sync.sh

set -e

CONFIG_FILE="$HOME/.config/auto-kb/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[skip] 설정 없음 — setup.sh를 먼저 실행하세요."
  exit 0
fi

VAULT_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['vault_path'])")
SESSIONS_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('sessions_path','Sessions'))")
PROJECT=$(basename "$(pwd)")
SESSION_DIR="$VAULT_PATH/$SESSIONS_PATH/$PROJECT"

if [ ! -d "$SESSION_DIR" ]; then
  echo "[skip] 세션 폴더 없음: $SESSION_DIR — 'cc'로 실행하세요."
  exit 0
fi

# 가장 최근 세션 파일 찾기
LATEST=$(ls -t "$SESSION_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$LATEST" ]; then
  echo "[skip] 세션 파일 없음"
  exit 0
fi

LINES=$(wc -l < "$LATEST" | tr -d ' ')
echo "[info] 프로젝트: $PROJECT"
echo "[info] 최근 세션: $(basename "$LATEST") (${LINES}줄)"
echo "[info] vault: $VAULT_PATH"
