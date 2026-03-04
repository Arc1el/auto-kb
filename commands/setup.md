---
description: auto-kb 초기 설정 — Obsidian vault 설정 및 cc 셸 함수 설치
---

auto-kb 플러그인 초기 설정을 실행한다. 이 커맨드는 대화형 셸 스크립트를 실행하므로 반드시 터미널에서 직접 실행해야 한다.

아래 명령어를 실행:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/auto-kb/scripts/setup.sh
```

`--reconfigure` 인자를 전달하면 vault를 재설정할 수 있다:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/auto-kb/scripts/setup.sh --reconfigure
```
