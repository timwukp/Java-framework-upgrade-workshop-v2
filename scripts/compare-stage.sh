#!/bin/sh
# Compare your workspace with the reference solution of a stage: pom.xml and the whole src/ tree.
# Run it from sample-app/. It changes nothing.
#
#   ../scripts/compare-stage.sh N     N = 1, 2 or 3
#
# Exit: 0 identical, 1 differences shown, 2 usage, 3 wrong folder or reference missing.
# Differences are not automatically wrong: the reference is one correct answer, not the only one.
set -eu
. "$(dirname -- "$0")/lib.sh"

[ $# -eq 1 ] || die "$EXIT_USAGE" "Usage: ../scripts/compare-stage.sh 1|2|3"
case "$1" in 1|2|3) ;; *) die "$EXIT_USAGE" "Usage: ../scripts/compare-stage.sh 1|2|3 (stage 0 is the starting point: use git diff stage-0)" ;; esac
stage_info "$1"
require_workspace

REF="$SOLUTIONS_DIR/$STAGE_REF"
[ -f "$REF/pom.xml" ] || die "$EXIT_ENV" "Reference not found: $REF"
REL="../solutions/$STAGE_REF"

rc=0
printf '+ diff -u %s/pom.xml pom.xml\n' "$REL"
diff -u "$REF/pom.xml" pom.xml || rc=1
printf '+ diff -ru %s/src src\n' "$REL"
diff -ru "$REF/src" src || rc=1

if [ "$rc" -eq 0 ]; then
    say "Identical to the stage $1 reference."
else
    say ""
    say "Differences above: lines with - are the reference, lines with + are yours."
    say "Must match: the parent ($STAGE_BOOT), java.version ($STAGE_JAVA_VERSION), the 14 tests and what they assert."
    say "May differ: formatting, comments, ordering, and equivalent code."
fi
exit "$rc"
