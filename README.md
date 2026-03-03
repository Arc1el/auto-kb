# auto-kb

> Claude Code 세션 로그를 자동 커밋하고, 백그라운드 KB(지식 베이스) 문서를 자동 생성하는 플러그인

## 한눈에 보기

```
cc (alias로 Claude 실행)
│  ← .claude_raw.md에 세션 전체 기록
▼
작업 수행
│
├─ [자동] Stop 훅: 매 턴 종료마다 미커밋 줄 수 체크
│         3000줄 이상 → sync.sh 자동 실행
│
└─ [자동] auto-kb 스킬: 복잡한 작업 완료 시 자동 트리거
          → sync.sh 실행
              │
              ├─ git add + commit
              └─ KB 에이전트 (백그라운드)
                    └─ docs/kb/ 문서 생성/업데이트
```

## 설치

### 방법 1: 원클릭 설치

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Arc1el/auto-kb/main/install.sh)
```

### 방법 2: 수동 설치

```bash
# 1. 클론
git clone https://github.com/Arc1el/auto-kb.git ~/.claude/plugins/auto-kb

# 2. 초기 셋업
bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh
```

### 업데이트

```bash
git -C ~/.claude/plugins/auto-kb pull
```

### 셋업이 자동으로 처리하는 항목

- `~/Documents/auto-docs/` 폴더 및 git 초기화
- shell alias `cc` 등록 (`~/.zshrc` / `~/.bashrc`)
- `settings.json` auto-approve 권한 추가
- Stop 훅 자동 등록

### 설치 후

터미널을 완전히 닫고 새로 연 뒤 `cc`로 실행:

```bash
cc   # = script -q -a ~/Documents/auto-docs/.claude_raw.md claude
```

## 구성 요소

| 파일 | 역할 |
|------|------|
| `skills/auto-kb/SKILL.md` | 작업 완료 시 자동 트리거 |
| `skills/auto-kb/scripts/setup.sh` | 최초 1회 환경 셋업 |
| `skills/auto-kb/scripts/sync.sh` | 커밋 + KB 에이전트 실행 |
| `skills/auto-kb/scripts/blog.sh` | KB 문서 → 블로그 포스트 변환 |
| `commands/kb-sync.md` | `/kb-sync` 수동 실행 커맨드 |
| `commands/blog.md` | `/blog` 블로그 변환 커맨드 |
| `hooks/auto_kb_hook.sh` | Stop 훅 — 3000줄 이상 시 자동 sync |
| `.claude-plugin/plugin.json` | 플러그인 메타데이터 + 훅 자동 등록 |

## 수동 실행

```
/kb-sync
```

## 결과물

```bash
ls ~/Documents/auto-docs/docs/kb/           # KB 문서
git -C ~/Documents/auto-docs log --oneline   # 커밋 히스토리
cat /tmp/auto_kb_hook.log                    # 훅 실행 로그
```

## 설정

### 경로 변경

기본 경로 `~/Documents/auto-docs`를 바꾸려면 `AUTO_DOCS` 환경변수를 설정:

```bash
export AUTO_DOCS="$HOME/my-custom-path"
```

### alias 이름 변경

기본 alias `cc`가 충돌하면 다른 이름으로 설치:

```bash
ALIAS_NAME=ccc bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh
```

## 삭제

```bash
rm -rf ~/.claude/plugins/auto-kb
```

`settings.json`의 훅/auto-approve 항목과 shell rc 파일의 alias는 수동 제거가 필요합니다.

## 라이선스

MIT
