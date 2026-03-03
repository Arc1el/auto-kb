#!/usr/bin/env bash
# auto-kb 원클릭 설치 스크립트
# 실행: bash <(curl -fsSL https://raw.githubusercontent.com/jayden/auto-kb/main/install.sh)

set -e

INSTALL_DIR="$HOME/.claude/plugins/auto-kb"
REPO_URL="https://github.com/Arc1el/auto-kb.git"

echo ""
echo "┌──────────────────────────────────────┐"
echo "│  auto-kb 플러그인 설치               │"
echo "└──────────────────────────────────────┘"
echo ""

# [1] 기존 설치 확인
if [ -d "$INSTALL_DIR" ]; then
  if [ -d "$INSTALL_DIR/.git" ]; then
    echo "[update] 기존 설치 감지 — pull로 업데이트합니다."
    git -C "$INSTALL_DIR" pull
  else
    echo "[error] $INSTALL_DIR 이 이미 존재하지만 git 저장소가 아닙니다."
    echo "        수동으로 삭제 후 다시 시도하세요: rm -rf $INSTALL_DIR"
    exit 1
  fi
else
  # [2] 플러그인 디렉토리 생성 및 클론
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
  echo "[done] 클론 완료: $INSTALL_DIR"
fi

# [3] 초기 셋업 실행
echo ""
bash "$INSTALL_DIR/skills/auto-kb/scripts/setup.sh"
