#!/usr/bin/env bash
# auto-kb: 환경 감지 및 자동 셋업
# 실행: /auto-kb:setup (Claude Code 내) 또는 직접 bash setup.sh
# 재설정: bash setup.sh --reconfigure

set -e

CONFIG_DIR="$HOME/.config/auto-kb"
CONFIG_FILE="$CONFIG_DIR/config.json"
RECONFIGURE=0

[ "$1" = "--reconfigure" ] && RECONFIGURE=1

# ── [1] Obsidian vault 설정 ──────────────────────────────────────────────────

configure_vault() {
  mkdir -p "$CONFIG_DIR"

  echo ""
  echo "┌──────────────────────────────────────────────────┐"
  echo "│  auto-kb: Obsidian Vault 설정                    │"
  echo "└──────────────────────────────────────────────────┘"
  echo ""

  # obsidian CLI로 vault 목록 시도
  VAULTS_JSON=""
  if command -v obsidian >/dev/null 2>&1; then
    VAULTS_JSON=$(obsidian vaults 2>/dev/null || echo "")
  fi

  VAULT_PATH=""

  if [ -n "$VAULTS_JSON" ]; then
    echo "  감지된 Obsidian vault:"
    echo ""
    python3 -c "
import json, sys
try:
    vaults = json.loads('''$VAULTS_JSON''')
    if isinstance(vaults, list):
        for i, v in enumerate(vaults):
            name = v.get('name', 'Unknown')
            path = v.get('path', '')
            print(f'  [{i+1}] {name}')
            print(f'      {path}')
            print()
    elif isinstance(vaults, dict):
        for i, (name, path) in enumerate(vaults.items()):
            print(f'  [{i+1}] {name}')
            print(f'      {path}')
            print()
except:
    pass
"
    echo "  번호를 입력하거나, vault 경로를 직접 입력하세요."
    echo -n "  → "
    read -r INPUT

    if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
      VAULT_PATH=$(python3 -c "
import json
try:
    vaults = json.loads('''$VAULTS_JSON''')
    idx = int('$INPUT') - 1
    if isinstance(vaults, list) and 0 <= idx < len(vaults):
        print(vaults[idx].get('path', ''))
    elif isinstance(vaults, dict):
        items = list(vaults.items())
        if 0 <= idx < len(items):
            print(items[idx][1])
except:
    pass
")
      VAULT_NAME=$(python3 -c "
import json
try:
    vaults = json.loads('''$VAULTS_JSON''')
    idx = int('$INPUT') - 1
    if isinstance(vaults, list) and 0 <= idx < len(vaults):
        print(vaults[idx].get('name', ''))
    elif isinstance(vaults, dict):
        items = list(vaults.items())
        if 0 <= idx < len(items):
            print(items[idx][0])
except:
    pass
")
    else
      VAULT_PATH="$INPUT"
      VAULT_NAME=$(basename "$VAULT_PATH")
    fi
  else
    echo "  obsidian CLI를 찾을 수 없습니다."
    echo "  vault 경로를 직접 입력하세요."
    echo -n "  → "
    read -r VAULT_PATH
    VAULT_NAME=$(basename "$VAULT_PATH")
  fi

  # 경로 확장 (~/ 처리)
  VAULT_PATH="${VAULT_PATH/#\~/$HOME}"

  if [ -z "$VAULT_PATH" ] || [ ! -d "$VAULT_PATH" ]; then
    echo "[error] 유효하지 않은 vault 경로: $VAULT_PATH"
    exit 1
  fi

  # 커스텀 경로 설정
  echo ""
  echo "  KB/Session/Blog 경로 (vault 내 상대 경로, 기본값 사용시 Enter):"
  echo -n "  Sessions 경로 [Sessions]: "
  read -r SESSIONS_PATH
  SESSIONS_PATH="${SESSIONS_PATH:-Sessions}"

  echo -n "  KB 경로 [KB]: "
  read -r KB_PATH
  KB_PATH="${KB_PATH:-KB}"

  echo -n "  Blog 경로 [Blog]: "
  read -r BLOG_PATH
  BLOG_PATH="${BLOG_PATH:-Blog}"

  python3 -c "
import json, pathlib
config = {
    'vault': '$VAULT_NAME',
    'vault_path': '$VAULT_PATH',
    'sessions_path': '$SESSIONS_PATH',
    'kb_path': '$KB_PATH',
    'blog_path': '$BLOG_PATH'
}
pathlib.Path('$CONFIG_FILE').write_text(json.dumps(config, indent=2, ensure_ascii=False))
print()
print('[done] 설정 저장: $CONFIG_FILE')
print(f'       vault: {config[\"vault\"]} ({config[\"vault_path\"]})')
print(f'       Sessions: {config[\"sessions_path\"]}/')
print(f'       KB: {config[\"kb_path\"]}/')
print(f'       Blog: {config[\"blog_path\"]}/')
"
}

if [ "$RECONFIGURE" -eq 1 ] || [ ! -f "$CONFIG_FILE" ]; then
  configure_vault
else
  echo "[check] vault 설정 존재: $CONFIG_FILE"
  echo "        재설정: /auto-kb:setup --reconfigure"
fi

# ── [1.5] vault 디렉토리 생성 ────────────────────────────────────────────────
VAULT_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE'))['vault_path'])" 2>/dev/null)
SESSIONS_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('sessions_path','Sessions'))" 2>/dev/null)
KB_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('kb_path','KB'))" 2>/dev/null)
BLOG_PATH=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('blog_path','Blog'))" 2>/dev/null)

if [ -n "$VAULT_PATH" ] && [ -d "$VAULT_PATH" ]; then
  mkdir -p "$VAULT_PATH/$SESSIONS_PATH"
  mkdir -p "$VAULT_PATH/$KB_PATH"
  mkdir -p "$VAULT_PATH/$BLOG_PATH"
  echo "[done] vault 디렉토리 준비: Sessions / KB / Blog"
fi

# ── [2] 이전 cc 함수 정리 (마이그레이션) ────────────────────────────────────
# v3.1 이하: script -q 또는 claude "$@" 래퍼가 shell rc에 설치되어 있었음
# v3.2+: Stop 훅이 자동 처리하므로 cc 함수 불필요 → 제거

SHELL_RC=""
case "$SHELL" in
  */zsh)  SHELL_RC="$HOME/.zshrc" ;;
  */bash) SHELL_RC="$HOME/.bashrc" ;;
  *)      SHELL_RC="$HOME/.profile" ;;
esac

if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
  if grep -q "# auto-kb:" "$SHELL_RC" 2>/dev/null || \
     grep -q "auto-docs/.claude_raw.md" "$SHELL_RC" 2>/dev/null || \
     grep -q "\.auto-kb" "$SHELL_RC" 2>/dev/null || \
     grep -q "\-\-plugin-dir" "$SHELL_RC" 2>/dev/null; then
    python3 -c "
import re, pathlib
rc = pathlib.Path('$SHELL_RC')
text = rc.read_text()
# 모든 auto-kb cc 관련 블록 제거 (다양한 형태)
text = re.sub(r'\n# auto-kb:[^\n]*\n\w+\(\) \{[^}]*\}\n?', '\n', text, flags=re.DOTALL)
text = re.sub(r'\n# auto-kb: Claude 세션 자동 로깅\nalias \w+=.*\n', '\n', text)
rc.write_text(text)
print('[migrate] shell rc에서 auto-kb cc 함수 제거 완료')
" && echo "[done] $SHELL_RC 정리"
  else
    echo "[check] shell rc 정리 불필요"
  fi
fi

# ── [3] 이전 수동 등록 정리 (마이그레이션) ───────────────────────────────────
# 마켓플레이스로 설치하면 plugin.json의 hooks가 자동 적용되므로
# settings.json에 수동 등록된 auto-kb 훅과 auto-approve 항목을 정리한다

SETTINGS="$HOME/.claude/settings.json"

if [ -f "$SETTINGS" ]; then
  python3 -c "
import json

with open('$SETTINGS', 'r') as f:
    s = json.load(f)

changed = False

# 수동 등록된 auto-kb 훅 제거
stop_groups = s.get('hooks', {}).get('Stop', [])
original_len = len(stop_groups)
filtered = [
    g for g in stop_groups
    if not any('auto_kb_hook' in h.get('command', '') for h in g.get('hooks', []))
]
if len(filtered) < original_len:
    s['hooks']['Stop'] = filtered
    if not filtered:
        del s['hooks']['Stop']
    if not s['hooks']:
        del s['hooks']
    changed = True
    print('[migrate] settings.json에서 수동 등록된 auto-kb 훅 제거')

# 수동 등록된 auto-kb auto-approve 항목 제거
allow = s.get('permissions', {}).get('allow', [])
original_allow = len(allow)
allow = [e for e in allow if 'auto-kb' not in e and 'auto_kb' not in e]
if len(allow) < original_allow:
    s['permissions']['allow'] = allow
    changed = True
    print('[migrate] settings.json에서 수동 등록된 auto-kb auto-approve 항목 제거')

if changed:
    with open('$SETTINGS', 'w') as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
else:
    print('[check] settings.json 정리 불필요 — 정상')
"
fi

# ── 최종 상태 보고 ──────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  auto-kb 설정 완료                                          ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  이제 그냥 'claude' 로 실행하면 됩니다                      ║"
echo "║  Stop 훅이 자동으로 세션을 Obsidian에 기록합니다            ║"
echo "║                                                              ║"
echo "║  vault 재설정: /auto-kb:setup --reconfigure                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
