#!/usr/bin/env python3
"""Maintainer checks for the workshop docs (not needed by participants).

    python3 tools/check-docs.py

1. Every relative Markdown link points to an existing file, and every #anchor to an existing heading
   (GitHub's heading-to-anchor rules).
2. Runbooks (files containing "<!-- runbook max-lines=N -->") stay short and use the runbook rules:
   no <details>, no "> Verify" author notes, no "dry run" provenance, no "Checkpoint" label, no "ask the
   instructor", prompt lines of at most 100 characters.
3. "Exercise N.M" references resolve to a "### N.M" heading when module N is a runbook.
4. Every copy of the javax import regex in the docs equals the one in jakarta-import-guard.json.
5. Translations (files containing "<!-- source: <path> @ <commit or blob id> -->") contain every code
   block of the English source byte for byte; a warning if the source changed since that version
   (record the blob id: git hash-object <path>).

Exit code 0 when there are no errors (warnings don't fail).
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SKIP_DIRS = {".git", "target", "node_modules", ".kiro-cache"}
errors, warnings = [], []


def md_files():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for f in filenames:
            if f.endswith(".md"):
                yield os.path.join(dirpath, f)


def rel(path):
    return os.path.relpath(path, ROOT)


FENCE = re.compile(r"^(\s*)(`{3,}|~{3,})(.*)$")


def split_fences(text):
    """Yield (in_fence, info, line_no, line); fence lines themselves count as in_fence."""
    for kind, info, no, line in fence_kinds(text):
        yield kind != "text", info, no, line


def fence_kinds(text):
    """Yield (kind, info, line_no, line) with kind = text | open | code | close."""
    marker, info = "", ""
    for no, line in enumerate(text.splitlines(), 1):
        m = FENCE.match(line)
        if not marker:
            if m:
                marker, info = m.group(2), m.group(3).strip()
                yield "open", info, no, line
            else:
                yield "text", "", no, line
        elif m and m.group(2)[0] == marker[0] and len(m.group(2)) >= len(marker) and not m.group(3).strip():
            yield "close", info, no, line
            marker = ""
        else:
            yield "code", info, no, line


def code_blocks(text):
    blocks, cur = [], []
    for kind, _info, _no, line in fence_kinds(text):
        if kind == "open":
            cur = []
        elif kind == "code":
            cur.append(line)
        elif kind == "close":
            blocks.append("\n".join(cur))
    return blocks


def slugify(heading):
    s = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", heading)  # links: keep the text
    # Inline HTML tags are dropped, but text inside `code spans` stays (GitHub renders it as text).
    parts = re.split(r"(`[^`]*`)", s)
    s = "".join(p if p.startswith("`") else re.sub(r"<[^>]+>", "", p) for p in parts)
    s = s.strip().lower()
    s = re.sub(r"[^\w\- ]", "", s)
    return s.replace(" ", "-")


def anchors_of(path, cache={}):
    if path in cache:
        return cache[path]
    text = open(path, encoding="utf-8").read()
    seen, result = {}, set()
    for in_fence, _i, _n, line in split_fences(text):
        if in_fence:
            continue
        m = re.match(r"^#{1,6}\s+(.*?)\s*#*\s*$", line)
        if m:
            base = slugify(m.group(1))
            n = seen.get(base, 0)
            result.add(base if n == 0 else f"{base}-{n}")
            seen[base] = n + 1
        for a in re.findall(r'<a\s+(?:id|name)="([^"]+)"', line):
            result.add(a)
    cache[path] = result
    return result


LINK = re.compile(r"(?<!!)\[(?:[^\]\\]|\\.)*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")


def strip_inline_code(line):
    return re.sub(r"`[^`]*`", "", line)


def check_links(path):
    text = open(path, encoding="utf-8").read()
    for in_fence, _i, no, line in split_fences(text):
        if in_fence:
            continue
        for target in LINK.findall(strip_inline_code(line)):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target):
                continue  # http:, https:, mailto:
            file_part, _, anchor = target.partition("#")
            dest = os.path.normpath(os.path.join(os.path.dirname(path), file_part)) if file_part else path
            if not os.path.exists(dest):
                errors.append(f"{rel(path)}:{no}: broken link {target} (no such file)")
                continue
            if anchor and dest.endswith(".md") and anchor not in anchors_of(dest):
                errors.append(f"{rel(path)}:{no}: broken anchor {target}")


RUNBOOK = re.compile(r"<!--\s*runbook\s+max-lines=(\d+)\s*-->")
FORBIDDEN = [
    (re.compile(r"<details", re.I), "<details> block"),
    (re.compile(r"^\s*>\s*Verify", re.M), "\"> Verify\" author note"),
    (re.compile(r"dry run", re.I), "\"dry run\" provenance"),
    (re.compile(r"\*\*Checkpoint"), "\"Checkpoint\" label (use Commit)"),
    (re.compile(r"ask the instructor", re.I), "\"ask the instructor\" (link a troubleshooting entry)"),
]


def check_runbook(path, text):
    m = RUNBOOK.search(text)
    if not m:
        return False
    limit, n = int(m.group(1)), len(text.splitlines())
    if n > limit:
        errors.append(f"{rel(path)}: {n} lines, over the runbook limit of {limit}")
    for kind, info, no, line in fence_kinds(text):
        if kind == "text":
            for rx, what in FORBIDDEN:
                if rx.search(line):
                    errors.append(f"{rel(path)}:{no}: {what}")
        elif kind == "code" and info == "prompt" and len(line) > 100:
            errors.append(f"{rel(path)}:{no}: prompt line of {len(line)} characters (max 100)")
    return True


def check_exercise_refs(runbook_ids, runbook_paths):
    rx = re.compile(r"\bExercises? (\d)\.(\d+)(?:\s*[–-]\s*(\d)\.(\d+))?")
    # While some modules still use the old Part.Exercise numbering, "Exercise 2.4" outside a runbook may
    # mean another module's exercise, so only runbooks are checked until all seven modules are converted.
    paths = md_files() if len(runbook_ids) == 7 else runbook_paths
    for path in paths:
        text = open(path, encoding="utf-8").read()
        for in_fence, _i, no, line in split_fences(text):
            if in_fence:
                continue
            for m in rx.finditer(line):
                mod = m.group(1)
                if mod in runbook_ids and f"{mod}.{m.group(2)}" not in runbook_ids[mod]:
                    errors.append(f"{rel(path)}:{no}: Exercise {mod}.{m.group(2)} has no heading in module {mod}")


def check_javax_regex():
    hook = os.path.join(ROOT, "sample-app/.kiro/hooks/jakarta-import-guard.json")
    cmd = json.load(open(hook, encoding="utf-8"))["hooks"][0]["action"]["command"]
    want = re.search(r"grep -nE '([^']+)'", cmd).group(1)
    for path in md_files():
        text = open(path, encoding="utf-8").read()
        for no, line in enumerate(text.splitlines(), 1):
            # Only full copies of the guard's regex (the ones listing the Jakarta EE packages).
            for got in re.findall(r"'(\^import \(static \)\?javax\\\.\(\([^']*)'", line):
                if got != want:
                    errors.append(f"{rel(path)}:{no}: javax regex differs from jakarta-import-guard.json")


SOURCE = re.compile(r"<!--\s*source:\s*(\S+)\s*@\s*([0-9a-f]{7,40})\s*-->")


def check_translations(path, text):
    m = SOURCE.search(text)
    if not m:
        return
    src_rel, sha = m.groups()
    src = os.path.normpath(os.path.join(ROOT, src_rel))
    if not os.path.exists(src):
        errors.append(f"{rel(path)}: source {src_rel} not found")
        return
    src_text = open(src, encoding="utf-8").read()
    for block in code_blocks(text):
        if block not in src_text:
            errors.append(f"{rel(path)}: a code block is not byte-identical to {src_rel}:\n    {block.splitlines()[0] if block else '(empty)'}")
    try:
        kind = subprocess.run(["git", "-C", ROOT, "cat-file", "-t", sha], capture_output=True, text=True, check=True).stdout.strip()
        spec = sha if kind == "blob" else f"{sha}:{src_rel}"
        old = subprocess.run(["git", "-C", ROOT, "cat-file", "-p", spec] if kind == "blob" else ["git", "-C", ROOT, "show", spec],
                             capture_output=True, text=True, check=True).stdout
        if old != src_text:
            warnings.append(f"{rel(path)}: {src_rel} changed after {sha}; update the translation and its source line")
    except (subprocess.CalledProcessError, FileNotFoundError):
        warnings.append(f"{rel(path)}: can't read {src_rel} at {sha} (shallow clone or unknown commit)")


def main():
    runbook_ids, runbook_paths = {}, []
    for path in sorted(md_files()):
        text = open(path, encoding="utf-8").read()
        check_links(path)
        if check_runbook(path, text):
            runbook_paths.append(path)
            m = re.match(r"0(\d)-", os.path.basename(path))
            if m and rel(os.path.dirname(path)) == "modules":
                runbook_ids[m.group(1)] = {f"{a}.{b}" for a, b in re.findall(r"^###\s+(\d)\.(\d+)\s", text, re.M)}
        check_translations(path, text)
    check_exercise_refs(runbook_ids, runbook_paths)
    check_javax_regex()
    for w in warnings:
        print("WARN ", w)
    for e in errors:
        print("ERROR", e)
    print(f"{len(errors)} error(s), {len(warnings)} warning(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
