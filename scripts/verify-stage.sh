#!/bin/sh
# Build the workspace once and check it is a finished stage: the right JDK and Spring Boot parent,
# a green clean build, Tests run: 14 with no failures, errors or skips, and class files for the
# right Java version. Run it from sample-app/ while no hook or agent build is running.
#
#   ../scripts/verify-stage.sh N [--jdk 8|21]     N = 0, 1, 2 or 3
#
#   --jdk 8   stage 1 before the JDK switch (Module 2, Phase A: Spring Boot 2.7.18 on JDK 8)
#   --jdk 21  stage 3 without JDK 25 (Module 4's "No JDK 25" variant, java.version 21)
#
# Exit: 0 passed, 1 a check failed, 2 usage, 3 wrong folder or JDK. The full Maven log is in
# verify-stage.log (ignored by git).
set -eu
. "$(dirname -- "$0")/lib.sh"

usage() { die "$EXIT_USAGE" "Usage: ../scripts/verify-stage.sh 0|1|2|3 [--jdk 8|21]"; }
[ $# -ge 1 ] || usage
STAGE=$1; shift
stage_info "$STAGE" || usage
JDK=$STAGE_JDK
while [ $# -gt 0 ]; do
    case "$1" in
        --jdk) [ $# -ge 2 ] || usage; JDK=$2; shift 2 ;;
        *) usage ;;
    esac
done
case "$STAGE:$JDK" in
    "$STAGE:$STAGE_JDK" | 1:8 | 3:21) ;;
    *) die "$EXIT_USAGE" "--jdk $JDK is not a workshop variant of stage $STAGE (use 1 --jdk 8 or 3 --jdk 21)." ;;
esac
MAJOR=$(class_major_for "$JDK")
JAVA_VERSION=$(java_version_for "$JDK")
require_workspace

say "== Stage $STAGE: JDK $JDK, Spring Boot $STAGE_BOOT, $TESTS_EXPECTED tests"

# 1. JDK: the terminal's java and the one Maven uses must both be the expected one.
got_java=$(java_major); got_mvn=$(mvn_java_major)
say "+ java -version  -> ${got_java:-not found}"
say "+ mvn -v         -> Java ${got_mvn:-not found}"
if [ "$got_java" != "$JDK" ] || [ "$got_mvn" != "$JDK" ]; then
    die "$EXIT_ENV" "FAIL: this terminal must use JDK $JDK (java: ${got_java:-none}, Maven: ${got_mvn:-none}).
Switch the JDK (docs/participant-setup.md, \"Switch the JDK per terminal\"), then run this again."
fi

# 2. The pom: parent version and java.version.
parent=$(pom_parent_version); javav=$(pom_java_version)
say "+ pom.xml parent -> $parent, java.version -> $javav"
fail=0
if [ "$parent" != "$STAGE_BOOT" ]; then
    say "FAIL: the parent is $parent; stage $STAGE uses $STAGE_BOOT."; fail=1
fi
if [ "$javav" != "$JAVA_VERSION" ]; then
    say "FAIL: java.version is $javav; expected $JAVA_VERSION for JDK $JDK."; fail=1
fi
[ "$fail" -eq 0 ] || exit "$EXIT_FAIL"

# 3. One clean build. Keep Maven's exit code (a pipe into tail would hide it).
say "Builds share target/: make sure no hook or agent build is running."
say "+ mvn -B clean verify > verify-stage.log 2>&1"
rc=0
mvn -B clean verify > verify-stage.log 2>&1 || rc=$?

# The same two lines the verify-after-spec-task hook reports.
grep -E 'Tests run:|BUILD (SUCCESS|FAILURE)' verify-stage.log | tail -n 2 || true

# Surefire's overall summary is the last "Tests run" line without "Time elapsed".
summary=$(grep -E '^\[(INFO|WARNING|ERROR)\] Tests run: [0-9]+, Failures: [0-9]+, Errors: [0-9]+, Skipped: [0-9]+$' verify-stage.log \
          | tail -n 1 | sed -E 's/^\[[A-Z]+\] //') || true
want="Tests run: $TESTS_EXPECTED, Failures: 0, Errors: 0, Skipped: 0"

if [ "$rc" -ne 0 ]; then
    say "FAIL: the build failed (Maven exit code $rc). First errors:"
    grep -E '^\[ERROR\]' verify-stage.log | head -n 15 || true
    say "Full log: verify-stage.log. Symptoms and fixes: docs/troubleshooting.md"
    exit "$EXIT_FAIL"
fi
if [ "$summary" != "$want" ]; then
    say "FAIL: the build is green, but the test summary is \"${summary:-missing}\"; expected \"$want\"."
    say "A green build with fewer tests is a failed stage. See docs/troubleshooting.md (Tests run is lower than 14)."
    exit "$EXIT_FAIL"
fi

# 4. Class files compiled for the expected Java version.
class=target/classes/com/example/usermanagement/UserManagementApplication.class
if ! command -v javap >/dev/null 2>&1; then
    warn "javap is not on PATH (it ships with the JDK); class-file check skipped."
    got_major=$MAJOR
else
    got_major=$(javap -v "$class" 2>/dev/null | sed -n 's/.*major version: *\([0-9]*\).*/\1/p' | head -n 1)
    say "+ javap -v $class | grep \"major version\"  -> ${got_major:-?}"
fi
if [ "$got_major" != "$MAJOR" ]; then
    say "FAIL: class files have major version ${got_major:-?}; expected $MAJOR for Java $JDK."
    exit "$EXIT_FAIL"
fi

say "PASS: stage $STAGE, Java $JDK, Spring Boot $STAGE_BOOT, $summary, class files major $MAJOR."
if [ "$JDK" = "$STAGE_JDK" ]; then
    say "Tag message for this stage: \"Stage $STAGE: Java $JDK, Spring Boot $(boot_short "$STAGE_BOOT"), Tests run: $TESTS_EXPECTED\""
fi
