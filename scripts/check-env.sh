#!/bin/sh
# Am I ready? Checks your tools, JDKs, Maven cache and workspace without building anything.
# Run it from sample-app/.
#
#   ../scripts/check-env.sh [--stage N]     N = 0, 1, 2 or 3 (default 0: the start of the day)
#
# Prints PASS / WARN / FAIL per line. Exit: 0 no FAIL, 1 at least one FAIL, 2 usage.
set -eu
. "$(dirname -- "$0")/lib.sh"

STAGE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --stage) [ $# -ge 2 ] || die "$EXIT_USAGE" "Usage: ../scripts/check-env.sh [--stage 0|1|2|3]"; STAGE=$2; shift 2 ;;
        *) die "$EXIT_USAGE" "Usage: ../scripts/check-env.sh [--stage 0|1|2|3]" ;;
    esac
done
stage_info "$STAGE" || die "$EXIT_USAGE" "Usage: ../scripts/check-env.sh [--stage 0|1|2|3]"

FAILS=0
pass() { printf 'PASS  %s\n' "$*"; }
warnl() { printf 'WARN  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; FAILS=$((FAILS + 1)); }

# version_ge A B: true if version A >= B (numeric, dot-separated).
version_ge() {
    [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -n 1)" = "$2" ]
}

say "== Environment check for stage $STAGE (JDK $STAGE_JDK, Spring Boot $STAGE_BOOT)"

# Operating system
case "$(uname -s)" in
    Darwin|Linux) pass "OS: $(uname -s)" ;;
    *) fail "OS: $(uname -s). The workshop supports macOS and Linux only." ;;
esac

# Folder
if [ -f pom.xml ] && [ -d .kiro ]; then
    pass "Folder: $(basename -- "$(pwd)") (pom.xml and .kiro/ found)"
else
    fail "Folder: run this from sample-app/ (the folder with pom.xml and .kiro/)"
fi

# Tools
if command -v git >/dev/null 2>&1; then
    v=$(git --version | sed -n 's/^git version \([0-9][0-9.]*\).*/\1/p')
    if version_ge "$v" 2.23; then pass "git $v"; else fail "git $v: need 2.23 or later (for git switch)"; fi
else fail "git not found"; fi

if command -v mvn >/dev/null 2>&1; then
    v=$(mvn -v 2>/dev/null | sed -n 's/^Apache Maven \([0-9][0-9.]*\).*/\1/p')
    if version_ge "${v:-0}" 3.9; then pass "Maven $v"; else fail "Maven ${v:-?}: need 3.9 or later"; fi
else fail "mvn not found"; fi

if command -v python3 >/dev/null 2>&1 && python3 --version >/dev/null 2>&1; then
    pass "$(python3 --version 2>&1)"
else fail "python3 not found (macOS: install the Xcode Command Line Tools)"; fi

if command -v curl >/dev/null 2>&1; then pass "curl $(curl --version | sed -n '1s/^curl \([^ ]*\).*/\1/p')"
else fail "curl not found"; fi

if command -v kiro >/dev/null 2>&1; then pass "kiro command on PATH"
else warnl "kiro command not on PATH: you can't start Kiro with 'kiro .' from this terminal (see participant setup)"; fi

# JDK of this terminal and of Maven
jm=$(java_major); mm=$(mvn_java_major)
if [ "$jm" = "$STAGE_JDK" ] && [ "$mm" = "$STAGE_JDK" ]; then
    pass "JDK $STAGE_JDK in this terminal (java and Maven agree)"
else
    fail "JDK: java is ${jm:-none}, Maven runs on ${mm:-none}; stage $STAGE needs $STAGE_JDK in both"
fi

# Installed JDKs (8, 21, 25)
have_jdk() {
    _want=$1
    if [ -x /usr/libexec/java_home ]; then
        _q=$(java_version_for "$_want")
        /usr/libexec/java_home -v "$_q" >/dev/null 2>&1 && return 0
    fi
    for _d in /usr/lib/jvm/* "$HOME"/.sdkman/candidates/java/* /opt/jdk-* \
              /Library/Java/JavaVirtualMachines/*/Contents/Home "$HOME"/Library/Java/JavaVirtualMachines/*/Contents/Home \
              /opt/homebrew/opt/openjdk*/libexec/openjdk.jdk/Contents/Home /usr/local/opt/openjdk*/libexec/openjdk.jdk/Contents/Home; do
        [ -f "$_d/release" ] || continue
        _v=$(sed -n 's/^JAVA_VERSION="\(.*\)"/\1/p' "$_d/release" | major_of)
        [ "$_v" = "$_want" ] && return 0
    done
    return 1
}
for j in 8 21 25; do
    if have_jdk "$j"; then pass "JDK $j installed"
    elif [ "$j" = 25 ]; then warnl "JDK 25 not found: Module 4 then uses the 'No JDK 25' variant (java.version 21)"
    else fail "JDK $j not found"; fi
done

# Maven cache (participant setup, section 7)
cache="$HOME/.m2/repository/org/springframework/boot/spring-boot"
missing=""
for b in 2.2.4.RELEASE 2.7.18 3.5.16 4.1.1; do [ -d "$cache/$b" ] || missing="${missing:+$missing, }$b"; done
if [ -z "$missing" ]; then pass "Maven cache has Spring Boot 2.2.4.RELEASE, 2.7.18, 3.5.16 and 4.1.1"
else warnl "Maven cache is missing Spring Boot $missing: run the pre-download (participant setup, section 7)"; fi

# Workspace content
if [ -d .kiro/steering ]; then
    n=0
    for s in migration-standards migration-playbook pom-rules test-rules; do [ -f ".kiro/steering/$s.md" ] && n=$((n + 1)); done
    if [ "$n" -eq 4 ]; then pass "4 steering files in .kiro/steering/"; else fail "$n of 4 workshop steering files in .kiro/steering/"; fi
fi
if [ -d .kiro/hooks ]; then
    got=$(hook_states); exp=$(expected_hooks "$STAGE")
    if [ "$got" = "$exp" ]; then
        pass "Hook files: $got"
    else
        warnl "Hook files: $got; at the start of Module $STAGE_MODULE_NEXT expected: $exp"
    fi
    say "      (This reads the \"enabled\" field in .kiro/hooks/*.json. The Agent Hooks panel in Kiro is authoritative.)"
fi

# Git state
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    br=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
    tags=$(git tag -l 'stage-*' | tr '\n' ' ')
    pass "Git branch: $br; stage tags: ${tags:-none}"
    if [ -n "$(git status --porcelain)" ]; then warnl "Uncommitted changes (git status --short shows them)"; fi
fi

say ""
say "Check by hand (a script can't see these): Kiro signed in; workspace trusted; Kiro started from"
say "this terminal with 'kiro .'; a paid plan or organization seat for the full day."
if [ "$FAILS" -gt 0 ]; then say "$FAILS check(s) failed."; exit "$EXIT_FAIL"; fi
say "No failed checks."
