---
description: KB + Blog 문서를 Obsidian vault에 동기화
allowed-tools: Bash(bash:*), Bash(mkdir:*)
---

현재 프로젝트의 `.auto-kb/docs/kb/` 문서를 Obsidian vault에 동기화한다.

## 실행

```bash
bash ~/.claude/plugins/auto-kb/scripts/obsidian-push.sh
```

환경변수로 vault 경로 지정 가능:

```bash
OBSIDIAN_VAULT="/Users/jayden/Documents/Obsidian Vault" \
  bash ~/.claude/plugins/auto-kb/scripts/obsidian-push.sh
```

## 결과 구조

```
Obsidian Vault/
├── KB/
│   └── <프로젝트명>/
│       ├── topic-a.md
│       └── topic-b.md
└── Blog/
    └── <프로젝트명>/
        ├── topic-a-blog.md
        └── topic-b-blog.md
```

## 완료 보고

동기화된 파일 수를 한 줄로 보고한다:
> "KB: X개, Blog: Y개 → Obsidian 동기화 완료"
