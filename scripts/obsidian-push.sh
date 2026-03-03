#!/usr/bin/env bash
# auto-kb: KB + Blog 문서를 Obsidian vault에 동기화
# 실행: bash obsidian-push.sh
# 환경변수:
#   OBSIDIAN_VAULT  - vault 경로 (기본: ~/Documents/Obsidian Vault)
#   AUTO_DOCS       - .auto-kb 경로 (기본: 자동 탐색)

OBSIDIAN_CLI="${OBSIDIAN_CLI:-/Applications/Obsidian.app/Contents/MacOS/obsidian}"
VAULT_PATH="${OBSIDIAN_VAULT:-$HOME/Documents/Obsidian Vault}"

find_auto_kb() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    [ -d "$dir/.auto-kb" ] && echo "$dir/.auto-kb" && return 0
    dir="$(dirname "$dir")"
  done
  return 1
}

AUTO_DOCS="${AUTO_DOCS:-$(find_auto_kb 2>/dev/null || echo "")}"

if [ -z "$AUTO_DOCS" ]; then
  echo "[error] .auto-kb 폴더를 찾을 수 없음 — 프로젝트 디렉토리에서 실행하세요."
  exit 1
fi

KB_DIR="$AUTO_DOCS/docs/kb"
PROJECT=$(basename "$(dirname "$AUTO_DOCS")")

if [ ! -d "$KB_DIR" ]; then
  echo "[skip] KB 폴더 없음: $KB_DIR — 먼저 sync를 실행해 KB 문서를 생성하세요."
  exit 0
fi

if [ ! -d "$VAULT_PATH" ]; then
  echo "[error] Obsidian vault 없음: $VAULT_PATH"
  echo "        OBSIDIAN_VAULT 환경변수로 경로를 지정하세요."
  exit 1
fi

echo "[push] 프로젝트: $PROJECT"
echo "[push] vault:   $VAULT_PATH"
echo ""

# ── KB 문서 동기화 ──────────────────────────────────────────────────────────
KB_DEST="$VAULT_PATH/KB/$PROJECT"
mkdir -p "$KB_DEST"

KB_COUNT=0
for file in "$KB_DIR"/*.md; do
  [ -f "$file" ] || continue
  [[ "$(basename "$file")" == *-blog.md ]] && continue  # blog 파일은 아래서 처리

  fname=$(basename "$file")
  cp "$file" "$KB_DEST/$fname"
  echo "[done] KB/$PROJECT/$fname"
  KB_COUNT=$((KB_COUNT + 1))
done

# ── Blog 문서 동기화 ────────────────────────────────────────────────────────
BLOG_DEST="$VAULT_PATH/Blog/$PROJECT"
mkdir -p "$BLOG_DEST"

BLOG_COUNT=0
for file in "$KB_DIR"/*-blog.md; do
  [ -f "$file" ] || continue

  fname=$(basename "$file")
  cp "$file" "$BLOG_DEST/$fname"
  echo "[done] Blog/$PROJECT/$fname"
  BLOG_COUNT=$((BLOG_COUNT + 1))
done

echo ""
echo "[완료] KB: ${KB_COUNT}개, Blog: ${BLOG_COUNT}개 → Obsidian"

# ── obsidian CLI로 태그 설정 (Obsidian이 실행 중일 때만) ──────────────────
if command -v "$OBSIDIAN_CLI" >/dev/null 2>&1; then
  "$OBSIDIAN_CLI" daily:read >/dev/null 2>&1 && OBSIDIAN_RUNNING=true || OBSIDIAN_RUNNING=false
else
  OBSIDIAN_RUNNING=false
fi

if [ "$OBSIDIAN_RUNNING" = "true" ] && [ "$KB_COUNT" -gt 0 ]; then
  echo ""
  echo "[obsidian] Obsidian 실행 중 — 태그 갱신 중..."
  for file in "$KB_DEST"/*.md; do
    [ -f "$file" ] || continue
    fname=$(basename "$file")
    fpath="KB/$PROJECT/$fname"
    "$OBSIDIAN_CLI" property:set name="tags" value='["kb","auto-generated"]' path="$fpath" silent 2>/dev/null && \
      echo "[tag] $fpath" || true
  done
fi
