# Shared helpers for the workshop scripts. Sourced by the other scripts, not run on its own.
# POSIX sh (macOS /bin/sh, dash, bash). No passwords are read or printed here.

EXIT_OK=0        # all checks passed
EXIT_FAIL=1      # a check failed (build red, wrong test count, wrong version, differences found)
EXIT_USAGE=2     # wrong arguments
EXIT_ENV=3       # wrong environment: folder, JDK, missing tool, app not running, no password
EXIT_REFUSED=4   # refused: uncommitted changes, or you did not confirm

TESTS_EXPECTED=14

SCRIPTS_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(dirname -- "$SCRIPTS_DIR")
SOLUTIONS_DIR="$REPO_ROOT/solutions"

say()  { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die()  { _code=$1; shift; printf '%s\n' "$*" >&2; exit "$_code"; }

# Print a command, then run it. Use only for commands without secrets.
run() { printf '+ %s\n' "$*"; "$@"; }

# Stage table. Sets STAGE_JDK, STAGE_BOOT, STAGE_JAVA_VERSION, STAGE_MAJOR, STAGE_REF, STAGE_MODULE_NEXT.
stage_info() {
    case "$1" in
        0) STAGE_JDK=8;  STAGE_BOOT=2.2.4.RELEASE; STAGE_REF="";                      STAGE_MODULE_NEXT=2 ;;
        1) STAGE_JDK=21; STAGE_BOOT=2.7.18;        STAGE_REF=stage-1-boot27-java21;   STAGE_MODULE_NEXT=3 ;;
        2) STAGE_JDK=21; STAGE_BOOT=3.5.16;        STAGE_REF=stage-2-boot35-java21;   STAGE_MODULE_NEXT=4 ;;
        3) STAGE_JDK=25; STAGE_BOOT=4.1.1;         STAGE_REF=stage-3-boot41-java25;   STAGE_MODULE_NEXT=5 ;;
        *) return 1 ;;
    esac
    STAGE_JAVA_VERSION=$(java_version_for "$STAGE_JDK")
    STAGE_MAJOR=$(class_major_for "$STAGE_JDK")
}

# Spring Boot version without the .RELEASE suffix, for tag messages.
boot_short() { printf '%s\n' "${1%.RELEASE}"; }

java_version_for() { case "$1" in 8) echo 1.8 ;; *) echo "$1" ;; esac; }
class_major_for()  { case "$1" in 8) echo 52 ;; 21) echo 65 ;; 25) echo 69 ;; *) echo "?" ;; esac; }

# Must run from sample-app/ (the Kiro workspace): pom.xml and .kiro/ next to each other.
require_workspace() {
    if [ ! -f pom.xml ] || [ ! -d .kiro ]; then
        die "$EXIT_ENV" "Run this from sample-app/ (the folder with pom.xml and .kiro/), for example:
  cd sample-app && ../scripts/$(basename -- "$0") ..."
    fi
}

# Major Java version of the 'java' command on PATH (8, 21, 25), or empty.
java_major() {
    command -v java >/dev/null 2>&1 || return 0
    # Not just line 1: "Picked up JAVA_TOOL_OPTIONS: ..." can come first.
    java -version 2>&1 | sed -n 's/.* version "\([^"]*\)".*/\1/p' | head -n 1 | major_of
}

# Major Java version Maven runs on, from 'mvn -v'.
mvn_java_major() {
    command -v mvn >/dev/null 2>&1 || return 0
    mvn -v 2>/dev/null | sed -n 's/^Java version: \([^,]*\).*/\1/p' | major_of
}

# Reads a version string such as 1.8.0_412 or 21.0.8 on stdin and prints 8 or 21.
major_of() {
    read -r _v || return 0
    case "$_v" in
        1.*) _v=${_v#1.}; printf '%s\n' "${_v%%.*}" ;;
        *)   _v=${_v%%[._+-]*}; printf '%s\n' "$_v" ;;
    esac
}

# Version of the <parent> in ./pom.xml.
pom_parent_version() {
    awk '/<parent>/ {p=1} p && /<version>/ {sub(/.*<version>/, ""); sub(/<\/version>.*/, ""); print; exit}' pom.xml
}

# <java.version> property in ./pom.xml.
pom_java_version() {
    sed -n 's/.*<java.version>\([^<]*\)<\/java.version>.*/\1/p' pom.xml | head -n 1
}

# Stage number for a parent version, or empty.
stage_for_boot() {
    case "$1" in
        2.2.4.RELEASE) echo 0 ;; 2.7.18) echo 1 ;; 3.5.16) echo 2 ;; 4.1.1) echo 3 ;;
    esac
}

# State of a hook file's "enabled" field: on, off, unset or missing.
hook_state() {
    _f=".kiro/hooks/$1.json"
    [ -f "$_f" ] || { echo missing; return 0; }
    case "$(sed -nE 's/.*"enabled"[[:space:]]*:[[:space:]]*(true|false).*/\1/p' "$_f" | head -n 1)" in
        true) echo on ;; false) echo off ;; *) echo unset ;;
    esac
}

# Both workspace hooks, as "verify-after-spec-task on, jakarta-import-guard off".
hook_states() { echo "verify-after-spec-task $(hook_state verify-after-spec-task), jakarta-import-guard $(hook_state jakarta-import-guard)"; }

# Expected hook states at the START of the module that follows a stage.
expected_hooks() {
    case "$1" in
        0|1) echo "verify-after-spec-task on, jakarta-import-guard off" ;;
        *)   echo "verify-after-spec-task on, jakarta-import-guard on" ;;
    esac
}
