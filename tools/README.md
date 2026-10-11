# Maintainer tools

Checks for people who change this workshop. Participants don't need them.

| Command (from the repository root) | Checks |
|---|---|
| `python3 tools/check-docs.py` | Relative links and `#anchors`; the runbook rules in every module (`<!-- runbook max-lines=N -->`: length, no `<details>`, no "> Verify" notes or dry-run provenance, prompt lines of at most 100 characters); every "Exercise N.M" reference; every copy of the `javax` regex against `jakarta-import-guard.json`; the translations |
| `tools/test-scripts.sh` | The learner scripts on a throwaway clone: arguments, refusals, resets, `compare-stage`, `smoke` without an app |
| `tools/test-scripts.sh --full` | The same plus real builds and smoke tests at every stage; needs `JAVA8_HOME`, `JAVA21_HOME`, `JAVA25_HOME`, Maven and network access |

## Writing a module

Each module is a **runbook** (what to do and what to expect) with a **why page** in `modules/why/` (the
reasons, sources, examples and evidence). Keep the layout of the existing modules:

- an "At a glance" card, "Before you start", a linked exercise table;
- exercises numbered `Module.Exercise` (`3.12`), each with **Goal**, **Do**, **Prompt** (a
  ` ```prompt ` fence), **Expect**, **If not** (a link to `docs/troubleshooting.md`), **Commit** and
  **Why** (a link to the why page, whose heading repeats the exercise heading);
- `#` and `/` tokens on an **Attach first** line, not inside the prompt;
- new symptoms go into `docs/troubleshooting.md` with the next free ID in their group;
- anything not yet confirmed in a Kiro build goes into the verification log's U-list.

## Translations

`README.zh-TW.md` and `docs/cheat-sheet.zh-TW.md` translate `README.md` and `docs/quick-reference.md`.
Their first line records the English version they match:

```text
<!-- source: README.md @ <blob id> -->
```

When you change one of those two English pages, update the translation in the same pull request (or
open a follow-up) and set the new id with `git hash-object README.md`. Commands, file names, prompts,
expected outputs and Kiro UI labels stay in English in the translation; `check-docs.py` fails if a
code block differs from the English page and warns when the English page changed after the recorded
version.
