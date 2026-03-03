#!/usr/bin/env bash
# auto-kb: 환경 감지 및 자동 셋업
# 실행: bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh

set -e

PLUGIN_ROOT="$HOME/.claude/plugins/auto-kb"
AUTO_DOCS="${AUTO_DOCS:-$HOME/Documents/auto-docs}"

# [1] auto-docs 폴더 및 git 초기화
if [ ! -d "$AUTO_DOCS/.git" ]; then
  mkdir -p "$AUTO_DOCS"
  git -C "$AUTO_DOCS" init
  git -C "$AUTO_DOCS" checkout -b main 2>/dev/null || true
  echo "[setup] auto-docs git 초기화 완료: $AUTO_DOCS"
fi

# [2] 세션 로그 파일 존재 확인
RAW_MISSING=0
if [ ! -f "$AUTO_DOCS/.claude_raw.md" ]; then
  RAW_MISSING=1
fi

# [3] shell alias 설치 확인 및 자동 추가
SHELL_RC=""
case "$SHELL" in
  */zsh)  SHELL_RC="$HOME/.zshrc" ;;
  */bash) SHELL_RC="$HOME/.bashrc" ;;
  *)      SHELL_RC="$HOME/.profile" ;;
esac

ALIAS_NAME="${ALIAS_NAME:-cc}"
ALIAS_LINE="alias ${ALIAS_NAME}='script -q -a \"$HOME/Documents/auto-docs/.claude_raw.md\" claude'"
ALIAS_FRESH=0
ALIAS_CONFLICT=0

if [ -n "$SHELL_RC" ]; then
  if grep -q "auto-docs/.claude_raw.md" "$SHELL_RC" 2>/dev/null; then
    : # auto-kb alias 이미 설치됨 — 스킵
  elif grep -qE "^alias ${ALIAS_NAME}=" "$SHELL_RC" 2>/dev/null; then
    ALIAS_CONFLICT=1
    EXISTING=$(grep -E "^alias ${ALIAS_NAME}=" "$SHELL_RC" | head -1)
  else
    printf "\n# auto-kb: Claude 세션 자동 로깅\n%s\n" "$ALIAS_LINE" >> "$SHELL_RC"
    ALIAS_FRESH=1
  fi
fi

# [4] settings.json auto-approve 항목 확인 및 자동 추가
SETTINGS="$HOME/.claude/settings.json"
ENTRIES=(
  "Bash(bash $PLUGIN_ROOT/skills/auto-kb/scripts/setup.sh:*)"
  "Bash(bash $PLUGIN_ROOT/skills/auto-kb/scripts/sync.sh:*)"
  "Bash(bash $PLUGIN_ROOT/skills/auto-kb/scripts/blog.sh:*)"
  'Bash(git add:*)'
  'Bash(nohup:*)'
)

if [ -f "$SETTINGS" ]; then
  ADDED=0
  for ENTRY in "${ENTRIES[@]}"; do
    if ! grep -qF "$ENTRY" "$SETTINGS" 2>/dev/null; then
      python3 -c "
import json
with open('$SETTINGS', 'r') as f:
    s = json.load(f)
entry = '$ENTRY'
allow = s.setdefault('permissions', {}).setdefault('allow', [])
if entry not in allow:
    allow.append(entry)
with open('$SETTINGS', 'w') as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
print('[setup] auto-approve 추가: ' + entry)
"
      ADDED=1
    fi
  done
  [ "$ADDED" -eq 0 ] && echo "[check] settings.json auto-approve 항목 모두 설치됨"
else
  echo "[warning] settings.json 없음 — 수동으로 추가 필요"
fi

# [5] settings.json Stop 훅 등록
HOOK_CMD="bash $PLUGIN_ROOT/hooks/auto_kb_hook.sh"

if [ -f "$SETTINGS" ]; then
  python3 -c "
import json

with open('$SETTINGS', 'r') as f:
    s = json.load(f)

hook_cmd = '$HOOK_CMD'
stop_groups = s.setdefault('hooks', {}).setdefault('Stop', [])

already = any(
    any(h.get('command', '') == hook_cmd for h in g.get('hooks', []))
    for g in stop_groups
)

if not already:
    stop_groups.append({'hooks': [{'type': 'command', 'command': hook_cmd}]})
    with open('$SETTINGS', 'w') as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
    print('[setup] Stop 훅 등록 완료: ' + hook_cmd)
else:
    print('[check] Stop 훅 이미 등록됨')
"
fi

# 최종 상태 보고
if [ "$ALIAS_CONFLICT" -eq 1 ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  [충돌] 이미 다른 용도의 '${ALIAS_NAME}' alias가 존재합니다          ║"
  echo "╠══════════════════════════════════════════════════════════════╣"
  echo "║  기존: $EXISTING"
  echo "║                                                              ║"
  echo "║  해결 방법 (택 1):                                          ║"
  echo "║  A) 기존 alias 이름을 변경한 뒤 다시 setup.sh 실행          ║"
  echo "║  B) 다른 이름으로 설치:                                     ║"
  echo "║     ALIAS_NAME=ccc bash $PLUGIN_ROOT/skills/auto-kb/scripts/setup.sh"
  echo "╚══════════════════════════════════════════════════════════════╝"
elif [ "$ALIAS_FRESH" -eq 1 ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  auto-kb 초기 설정 완료 — 지금 바로 적용하려면:     ║"
  echo "╠══════════════════════════════════════════════════════╣"
  echo "║  1. 이 Claude 세션을 종료하세요 (exit 또는 Ctrl+D)  ║"
  echo "║  2. 터미널을 완전히 닫고 새로 여세요                ║"
  echo "║  3. 이후 Claude는 항상 '${ALIAS_NAME}' 로 실행하세요          ║"
  echo "║     ${ALIAS_NAME} = 세션 자동 로깅 + Claude Code               ║"
  echo "╚══════════════════════════════════════════════════════╝"
elif [ "$RAW_MISSING" -eq 1 ]; then
  echo ""
  echo "[warning] 세션 로깅 비활성 상태 — 현재 Claude가 '${ALIAS_NAME}' 없이 실행 중입니다."
  echo "          이 세션을 종료 후 터미널을 새로 열고 '${ALIAS_NAME}' 로 재시작하세요."
else
  echo "[check] alias '${ALIAS_NAME}' 이미 설치됨"
  echo "[check] 환경 점검 완료"
fi
