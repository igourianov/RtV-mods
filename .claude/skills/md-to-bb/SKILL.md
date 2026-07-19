---
name: md-to-bb
description: Convert markdown to Nexus BBCode. Use when preparing a README or mod description for a Nexus mod page, or when the user asks to convert markdown to BB/BBCode.
---

## 1. Convert

File input, writes `<name>.bb.txt` beside the source and prints the path:

```bash
node .claude/skills/md-to-bb/md2bb.mjs likhos-vostac/README.md
```

Text input (pasted markdown, a snippet, a section), prints BBCode to stdout:

```bash
printf '%s' "$MARKDOWN" | node .claude/skills/md-to-bb/md2bb.mjs
```

Never hand-convert. The script is the source of truth, so output stays byte-identical between runs and the copy is never silently reworded.

## 2. Report

Relay any `warning:` lines the script emits on stderr. They mark constructs with no BBCode equivalent that need a human decision:

- **table flattened** - Nexus has no table tag, rows are emitted as `a | b` text. Suggest a list instead.
- **raw HTML passed through** - the tag will render literally on Nexus. Suggest removing it.

For file input, report the output path. For text input, return the BBCode in a fenced block so it can be copied.

## Mapping

| Markdown | BBCode |
|---|---|
| `#` / `##` / `###` | `[size=6][b]` / `[size=5][b]` / `[size=4][b]` (h4-h6 clamp to `size=3`) |
| `**bold**` | `[b]` |
| `*italic*` | `[i]` |
| `~~strike~~` | `[s]` |
| `` `code` `` | `[font=Courier New]` |
| fenced block | `[code]` |
| `*` / `1.` lists, nested | `[list]` / `[list=1]` with `[*]` |
| `[text](url)` | `[url=url]text[/url]` |
| `![alt](url)` | `[img]url[/img]` |
| `>` | `[quote]` |
| `---` | `[line]` |

Courier New is deliberate: it is metric-compatible on Windows, macOS and Linux. Consolas is Windows-only and silently falls back to the proportional body font elsewhere. To change it, edit `CODE_FONT` at the top of `md2bb.mjs`.
