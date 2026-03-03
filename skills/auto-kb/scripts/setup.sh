#!/usr/bin/env bash
# auto-kb: 환경 감지 및 자동 셋업
# 실행: bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh

set -e

PLUGIN_ROOT="$HOME/.claude/plugins/auto-kb"

# [1] shell function 설치 확인 및 자동 추가
SHELL_RC=""
case "$SHELL" in
  */zsh)  SHELL_RC="$HOME/.zshrc" ;;
  */bash) SHELL_RC="$HOME/.bashrc" ;;
  *)      SHELL_RC="$HOME/.profile" ;;
esac

FUNC_NAME="${ALIAS_NAME:-cc}"
FUNC_MARKER="# auto-kb:${FUNC_NAME}"
FUNC_FRESH=0
FUNC_CONFLICT=0

# 이전 버전(alias) 자동 제거
if [ -n "$SHELL_RC" ] && grep -q "auto-docs/.claude_raw.md" "$SHELL_RC" 2>/dev/null; then
  python3 -c "
import re, pathlib
rc = pathlib.Path('$SHELL_RC')
text = rc.read_text()
text = re.sub(r'\n# auto-kb: Claude 세션 자동 로깅\nalias ${FUNC_NAME}=.*\n', '\n', text)
rc.write_text(text)
print('[migrate] 이전 alias 제거 완료')
"
fi

if [ -n "$SHELL_RC" ]; then
  if grep -qF "$FUNC_MARKER" "$SHELL_RC" 2>/dev/null; then
    : # auto-kb function 이미 설치됨
  elif grep -qE "^(function ${FUNC_NAME} |${FUNC_NAME}\(\))" "$SHELL_RC" 2>/dev/null || \
       grep -qE "^alias ${FUNC_NAME}=" "$SHELL_RC" 2>/dev/null; then
    FUNC_CONFLICT=1
    EXISTING=$(grep -E "^(function ${FUNC_NAME} |${FUNC_NAME}\(\)|alias ${FUNC_NAME}=)" "$SHELL_RC" | head -1)
  else
    cat >> "$SHELL_RC" << 'AUTOKB_FUNC'

# auto-kb:cc
cc() {
  local auto_kb="$(pwd)/.auto-kb"
  mkdir -p "$auto_kb"
  [ -d "$auto_kb/.git" ] || git -C "$auto_kb" init -b main >/dev/null 2>&1
  local gi="$(pwd)/.gitignore"
  if [ -f "$gi" ] && ! grep -qF '.auto-kb/' "$gi" 2>/dev/null; then
    printf '\n# auto-kb session logs\n.auto-kb/\n' >> "$gi"
  fi
  AUTO_DOCS="$auto_kb" script -q -a "$auto_kb/.claude_raw.md" claude
}
AUTOKB_FUNC

    # ALIAS_NAME이 cc가 아니면 함수 이름 치환
    if [ "$FUNC_NAME" != "cc" ]; then
      python3 -c "
import pathlib
rc = pathlib.Path('$SHELL_RC')
text = rc.read_text()
text = text.replace('# auto-kb:cc', '# auto-kb:${FUNC_NAME}')
text = text.replace('cc() {', '${FUNC_NAME}() {')
rc.write_text(text)
"
    fi
    FUNC_FRESH=1
  fi
fi

# [2] settings.json auto-approve 항목 확인 및 자동 추가
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

# [3] settings.json Stop 훅 등록
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
if [ "$FUNC_CONFLICT" -eq 1 ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  [충돌] 이미 다른 용도의 '${FUNC_NAME}' 이 존재합니다               ║"
  echo "╠══════════════════════════════════════════════════════════════╣"
  echo "║  기존: $EXISTING"
  echo "║                                                              ║"
  echo "║  해결 방법 (택 1):                                          ║"
  echo "║  A) 기존 함수/alias를 변경한 뒤 다시 setup.sh 실행          ║"
  echo "║  B) 다른 이름으로 설치:                                     ║"
  echo "║     ALIAS_NAME=ccc bash $PLUGIN_ROOT/skills/auto-kb/scripts/setup.sh"
  echo "╚══════════════════════════════════════════════════════════════╝"
elif [ "$FUNC_FRESH" -eq 1 ]; then
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║  auto-kb 초기 설정 완료 — 지금 바로 적용하려면:             ║"
  echo "╠══════════════════════════════════════════════════════════════╣"
  echo "║  1. 이 Claude 세션을 종료하세요 (exit 또는 Ctrl+D)          ║"
  echo "║  2. 터미널을 완전히 닫고 새로 여세요                        ║"
  echo "║  3. 프로젝트 디렉토리에서 '${FUNC_NAME}' 로 실행하세요               ║"
  echo "║     → <프로젝트>/.auto-kb/ 에 세션 로그 + KB 자동 생성      ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
else
  echo "[check] function '${FUNC_NAME}' 이미 설치됨"
  echo "[check] 환경 점검 완료"
fi
