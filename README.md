# auto-kb

> Claude Code 세션 로그를 프로젝트별로 Obsidian vault에 직접 기록하고, **background-secretary 서브에이전트**가 KB 문서를 자동 생성하는 플러그인

## 아키텍처

```
~/my-project/ 에서 cc (= claude) 실행
│
├─ [자동] Stop 훅: JSONL transcript → 클린 마크다운 변환
│         obsidian_session_hook.py 가 매 턴 후 실행
│         ├─ Sessions/my-project/2026-03-03_143022.md  ← 세션별 로그 (클린)
│         └─ ANSI 코드 없음, 구조화된 User/Assistant 형식
│
├─ KB/my-project/*.md                        ← KB 문서
└─ Blog/my-project/*.md                      ← 블로그 변환
│
└─ [자동] auto-kb 스킬: 복잡한 작업 완료 시 자동 트리거
          └─ background-secretary 서브에이전트에 위임
                ├─ 세션 로그 분석
                ├─ obsidian-cli로 KB 문서 생성/업데이트
                └─ 프로젝트별 학습 축적 (memory: project)
```

### 핵심 설계

| 항목 | 설명 |
|------|------|
| 저장소 | Obsidian vault (단일 소스 오브 트루스) |
| 세션 구분 | `cc` 실행마다 타임스탬프 파일 생성 (채팅방처럼 독립) |
| KB 생성 | background-secretary 서브에이전트 (haiku, background) |
| 학습 | `memory: project` — 프로젝트별 패턴 축적 |
| 설정 | `~/.config/auto-kb/config.json` — vault 경로, 폴더 구조 |

## 설치

### 1. 마켓플레이스 등록 + 플러그인 설치

Claude Code 내에서:

```
/plugin marketplace add Arc1el/auto-kb
/plugin install auto-kb@auto-kb-marketplace
```

### 2. 초기 설정

설치 후 Claude Code 내에서 셋업 커맨드 실행:

```
/auto-kb:setup
```

대화형으로 설정:

1. **Obsidian vault 선택** — `obsidian list`에서 자동 감지 또는 직접 입력
2. **폴더 구조 설정** — Sessions/KB/Blog 경로 (기본값 제공)
3. **`cc` shell function 설치** — 세션 로깅 래퍼

### 3. 사용

터미널을 새로 열고, **프로젝트 디렉토리에서** `cc`로 실행:

```bash
cd ~/my-project
cc   # → Claude Code 실행 + Obsidian vault에 세션 로그 자동 기록
```

> 마켓플레이스를 통해 설치하면 agents, hooks, skills, commands가 모든 세션에서 자동 로딩됩니다.
> `cc`는 세션 로그 기록만 추가합니다.

### 업데이트

```
/plugin marketplace update auto-kb-marketplace
/plugin update auto-kb@auto-kb-marketplace
```

## Obsidian Vault 내 구조

```
<Vault>/
├── Sessions/
│   └── my-project/
│       ├── 2026-03-03_143022.md    ← cc 1회차
│       ├── 2026-03-03_161545.md    ← cc 2회차
│       └── 2026-03-04_091230.md    ← cc 3회차
├── KB/
│   └── my-project/
│       ├── topic-a.md
│       └── topic-b.md
└── Blog/
    └── my-project/
        └── topic-a-blog.md
```

## 구성 요소

| 파일 | 역할 |
|------|------|
| `agents/background-secretary.md` | KB 생성 + 블로그 변환 서브에이전트 |
| `skills/auto-kb/SKILL.md` | 작업 완료 시 자동 트리거 |
| `commands/setup.md` | `/auto-kb:setup` 초기 설정 |
| `commands/kb-sync.md` | `/auto-kb:kb-sync` 수동 KB 동기화 |
| `commands/blog.md` | `/auto-kb:blog` 블로그 변환 |
| `hooks/auto_kb_hook.sh` | Stop 훅 — obsidian_session_hook.py 호출 |
| `hooks/obsidian_session_hook.py` | JSONL → 클린 Obsidian 마크다운 변환 |
| `skills/auto-kb/scripts/setup.sh` | 대화형 환경 셋업 스크립트 |
| `skills/auto-kb/scripts/sync.sh` | 세션 상태 확인 |

## 수동 실행

```
/auto-kb:kb-sync
/auto-kb:blog
```

## 설정

### 설정 파일

`~/.config/auto-kb/config.json`:

```json
{
  "vault": "My Vault",
  "vault_path": "/path/to/vault",
  "sessions_path": "Sessions",
  "kb_path": "KB",
  "blog_path": "Blog"
}
```

### vault 재설정

```
/auto-kb:setup --reconfigure
```

### alias 이름 변경

```bash
ALIAS_NAME=ccc bash <plugin-root>/skills/auto-kb/scripts/setup.sh
```

## 삭제

Claude Code 내에서:

```
/plugin uninstall auto-kb@auto-kb-marketplace
/plugin marketplace remove auto-kb-marketplace
```

shell rc 파일(`~/.zshrc` 등)에서 `# auto-kb:cc` 블록과 `~/.config/auto-kb/` 디렉토리는 수동 제거:

```bash
rm -rf ~/.config/auto-kb
```

## 라이선스

MIT

## 감사 및 출처

- `skills/obsidian-cli`, `skills/obsidian-markdown` 파일은 [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills)에서 가져왔습니다. MIT 라이선스 (c) Stephan Ango (kepano)
