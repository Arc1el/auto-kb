#!/usr/bin/env bash
# auto-kb: KB 문서 → 블로그 포맷 변환
# 실행: bash blog.sh [파일명1 파일명2 ...]  ← 인자 없으면 대화형 선택

AUTO_DOCS="${AUTO_DOCS:-$HOME/Documents/auto-docs}"
KB_DIR="$AUTO_DOCS/docs/kb"

# KB 폴더 확인
if [ ! -d "$KB_DIR" ]; then
  echo "[error] KB 폴더 없음: $KB_DIR"
  echo "        먼저 sync를 실행해 KB 문서를 생성하세요."
  exit 1
fi

# 인자로 파일명이 직접 전달된 경우 선택 단계 스킵
if [ $# -gt 0 ]; then
  SELECTED=("$@")
else
  # 블로그 버전 없는 KB 문서 목록 수집 (macOS 호환)
  CANDIDATES=()
  while IFS= read -r filepath; do
    CANDIDATES+=("$(basename "$filepath")")
  done < <(find "$KB_DIR" -maxdepth 1 -name "*.md" ! -name "*-blog.md" | sort)

  if [ ${#CANDIDATES[@]} -eq 0 ]; then
    echo "[skip] 변환 대상 KB 문서가 없습니다. (모두 블로그 버전 존재)"
    exit 0
  fi

  # 대화형 선택
  echo ""
  echo "┌─────────────────────────────────────────────────┐"
  echo "│  블로그 미생성 KB 문서 목록                     │"
  echo "├─────────────────────────────────────────────────┤"
  for i in "${!CANDIDATES[@]}"; do
    printf "│  [%2d] %-43s│\n" "$((i+1))" "${CANDIDATES[$i]}"
  done
  echo "├─────────────────────────────────────────────────┤"
  echo "│  선택: 번호 입력 (예: 1,3 또는 all)             │"
  echo "└─────────────────────────────────────────────────┘"
  echo -n "→ "
  read -r INPUT

  SELECTED=()
  if [ "$INPUT" = "all" ]; then
    SELECTED=("${CANDIDATES[@]}")
  else
    IFS=',' read -ra NUMS <<< "$INPUT"
    for NUM in "${NUMS[@]}"; do
      NUM=$(echo "$NUM" | tr -d ' ')
      IDX=$((NUM - 1))
      if [ "$IDX" -ge 0 ] && [ "$IDX" -lt "${#CANDIDATES[@]}" ]; then
        SELECTED+=("${CANDIDATES[$IDX]}")
      else
        echo "[warn] 유효하지 않은 번호: $NUM — 건너뜀"
      fi
    done
  fi
fi

if [ ${#SELECTED[@]} -eq 0 ]; then
  echo "[skip] 선택된 파일 없음"
  exit 0
fi

# 선택된 파일마다 블로그 변환 에이전트 실행
echo ""
for FNAME in "${SELECTED[@]}"; do
  SRC="$KB_DIR/$FNAME"
  BLOG_NAME="${FNAME%.md}-blog.md"
  DEST="$KB_DIR/$BLOG_NAME"

  if [ ! -f "$SRC" ]; then
    echo "[warn] 파일 없음: $SRC — 건너뜀"
    continue
  fi

  echo "[run] 블로그 변환 중: $FNAME → $BLOG_NAME"

  nohup env -u CLAUDECODE claude --dangerously-skip-permissions \
    --add-dir "$KB_DIR" -p \
"아래 KB 문서를 개발자 블로그 포스트로 변환해줘.

[원본 파일]: $SRC
[출력 파일]: $DEST

변환 규칙:
1. 원본 파일을 읽어서 내용을 파악해라.
2. 블로그 포스트 형식으로 재작성해라:
   - 제목: 독자의 관심을 끄는 제목 (기술적이되 읽고 싶게)
   - 도입부: 어떤 문제를 해결했는지, 왜 이 글을 읽어야 하는지
   - 본문: 핵심 내용을 스토리텔링 방식으로 설명 (단순 나열 X)
   - 코드 예시: 있다면 설명과 함께 포함
   - 마무리: 핵심 요약 + 배운 점 또는 다음 단계
3. 분량: 1000~2000자 내외 (원본 내용에 따라 조절)
4. 말투: 한국어, 친근하지만 전문적인 개발자 블로그 톤
5. 완성된 블로그 포스트를 $DEST 에 저장해라.
6. 저장 완료 후 조용히 종료해라." \
    >> "/tmp/auto_kb_blog.log" 2>&1 &

  echo "[done] 에이전트 실행됨 (PID: $!) → $BLOG_NAME"
done

echo ""
echo "[log] 진행 상황: tail -f /tmp/auto_kb_blog.log"
