# auto-kb

> Claude Code 세션 로그를 프로젝트별로 자동 커밋하고, 백그라운드 KB(지식 베이스) 문서를 자동 생성하는 플러그인

## 한눈에 보기

```
~/my-project/ 에서 cc 실행
│
├─ .auto-kb/ 자동 생성 (프로젝트별 독립 git repo)
│   ├─ .claude_raw.md   ← 세션 전체 기록
│   └─ docs/kb/          ← KB 문서 자동 생성
│
├─ [자동] Stop 훅: 매 턴 종료마다 미커밋 줄 수 체크
│         3000줄 이상 → sync.sh 자동 실행
│
└─ [자동] auto-kb 스킬: 복잡한 작업 완료 시 자동 트리거
          → sync.sh 실행
              ├─ git add + commit (.auto-kb 내부 repo)
              └─ KB 에이전트 (백그라운드)
                    └─ .auto-kb/docs/kb/ 문서 생성/업데이트
```

**프로젝트마다 `.auto-kb/` 폴더가 독립적으로 생성**되어 세션 로그와 KB가 섞이지 않습니다.

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

- shell function `cc` 등록 (`~/.zshrc` / `~/.bashrc`)
- `settings.json` auto-approve 권한 추가
- Stop 훅 자동 등록
- 이전 버전(alias 방식) 자동 감지 및 제거

### 설치 후

터미널을 완전히 닫고 새로 연 뒤, **프로젝트 디렉토리에서** `cc`로 실행:

```bash
cd ~/my-project
cc   # → .auto-kb/ 자동 생성 + Claude Code 실행
```

## 프로젝트별 `.auto-kb/` 구조

```
~/my-project/
  .auto-kb/
    .git/              # 독립 git repo (프로젝트 git과 별개)
    .claude_raw.md     # 이 프로젝트 전용 세션 로그
    docs/kb/           # 이 프로젝트 전용 KB 문서
```

- `cc`를 실행한 디렉토리에 자동 생성됩니다.
- 프로젝트의 `.gitignore`에 `.auto-kb/`가 자동으로 추가됩니다.

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
ls .auto-kb/docs/kb/                       # 현재 프로젝트 KB 문서
git -C .auto-kb log --oneline              # 커밋 히스토리
cat /tmp/auto_kb_hook.log                  # 훅 실행 로그
```

## 설정

### alias 이름 변경

기본 function `cc`가 충돌하면 다른 이름으로 설치:

```bash
ALIAS_NAME=ccc bash ~/.claude/plugins/auto-kb/skills/auto-kb/scripts/setup.sh
```

## 삭제

```bash
rm -rf ~/.claude/plugins/auto-kb
```

`settings.json`의 훅/auto-approve 항목과 shell rc 파일의 function은 수동 제거가 필요합니다.

## 라이선스

MIT

## 감사 및 출처

- [`skills/obsidian-cli`](skills/obsidian-cli/SKILL.md), [`skills/obsidian-markdown`](skills/obsidian-markdown/SKILL.md) 파일은 [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) 에서 가져왔습니다. MIT 라이선스 © Stephan Ango (kepano)
