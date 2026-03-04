#!/usr/bin/env python3
"""auto-kb: Stop hook — JSONL transcript → clean Obsidian markdown"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path

CONFIG_FILE = Path.home() / ".config" / "auto-kb" / "config.json"
STATE_FILE = Path.home() / ".config" / "auto-kb" / "session_state.json"


def read_config():
    if not CONFIG_FILE.exists():
        return None
    try:
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
    except Exception:
        return None


def load_state():
    if not STATE_FILE.exists():
        return {}
    try:
        return json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_state(state):
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        tmp = STATE_FILE.with_suffix(".tmp")
        tmp.write_text(json.dumps(state, indent=2), encoding="utf-8")
        os.replace(tmp, STATE_FILE)
    except Exception:
        pass


def get_project_name(payload, transcript_path):
    # 1) cwd from payload (most reliable)
    cwd = payload.get("cwd") or payload.get("workingDirectory")
    if cwd:
        name = Path(cwd).name
        return name if name else "home"

    # 2) decode from transcript path directory name
    # ~/.claude/projects/-Users-jayden-Documents-my-project/xxx.jsonl
    encoded = transcript_path.parent.name
    home_encoded = str(Path.home()).replace("/", "-")  # e.g. -Users-jayden
    if encoded.startswith(home_encoded):
        rest = encoded[len(home_encoded):].lstrip("-")
        if rest:
            # Take last component as project name
            parts = [p for p in rest.split("-") if p]
            return parts[-1] if parts else rest
        return "home"
    return encoded.lstrip("-") or "home"


def is_pure_tool_content(content):
    if not isinstance(content, list):
        return False
    return all(
        isinstance(c, dict) and c.get("type") in ("tool_result", "tool_use")
        for c in content
        if isinstance(c, dict)
    )


def extract_text(content):
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict) and item.get("type") == "text":
                parts.append(item.get("text", ""))
            elif isinstance(item, str):
                parts.append(item)
        return "\n".join(p for p in parts if p).strip()
    return ""


def parse_messages(transcript_path):
    messages = []
    try:
        with open(transcript_path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    msg = json.loads(line)
                except Exception:
                    continue

                # Determine role
                t = msg.get("type")
                if t in ("user", "assistant"):
                    role = t
                else:
                    inner = msg.get("message", {})
                    role = inner.get("role") if isinstance(inner, dict) else None

                if role not in ("user", "assistant"):
                    continue

                # Get content
                inner = msg.get("message", {})
                if isinstance(inner, dict):
                    content = inner.get("content")
                else:
                    content = msg.get("content")

                # Skip purely tool content
                if is_pure_tool_content(content):
                    continue

                text = extract_text(content)
                if text:
                    messages.append((role, text))
    except Exception:
        pass
    return messages


def format_markdown(messages, session_id, project, now_str):
    lines = [
        "---",
        f"project: {project}",
        f"session_id: {session_id}",
        f"date: {now_str}",
        "tags: [session]",
        "---",
        "",
        f"# {project} — {now_str}",
        "",
    ]
    for role, text in messages:
        if role == "user":
            lines.append(f"## User\n\n{text}\n")
        else:
            lines.append(f"## Assistant\n\n{text}\n")
    return "\n".join(lines)


def main():
    config = read_config()
    if not config:
        sys.exit(0)

    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {}

    session_id = (
        payload.get("sessionId")
        or payload.get("session_id")
        or (payload.get("session") or {}).get("id")
    )
    transcript = (
        payload.get("transcriptPath")
        or payload.get("transcript_path")
        or (payload.get("transcript") or {}).get("path")
    )

    if not session_id or not transcript:
        sys.exit(0)

    transcript_path = Path(transcript).expanduser().resolve()
    if not transcript_path.exists():
        sys.exit(0)

    state = load_state()

    messages = parse_messages(transcript_path)
    if not messages:
        sys.exit(0)

    vault_path = Path(config["vault_path"])
    sessions_path = config.get("sessions_path", "Sessions")
    project = get_project_name(payload, transcript_path)

    session_dir = vault_path / sessions_path / project
    session_dir.mkdir(parents=True, exist_ok=True)

    now = datetime.now()
    now_str = now.strftime("%Y-%m-%d %H:%M:%S")
    timestamp = now.strftime("%Y-%m-%d_%H%M%S")

    # Reuse existing file for same session, or create new one
    output_file = Path(state[session_id]) if state.get(session_id) else session_dir / f"{timestamp}.md"

    content = format_markdown(messages, session_id, project, now_str)
    output_file.write_text(content, encoding="utf-8")

    state[session_id] = str(output_file)
    save_state(state)

    sys.exit(0)


if __name__ == "__main__":
    main()
