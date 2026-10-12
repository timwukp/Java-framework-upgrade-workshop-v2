#!/bin/sh
# Reset your workspace to the reference state of a stage, when you are behind or stuck.
# Replaces pom.xml and src/ only. Your .kiro/ folder, specs and git history stay.
# It never commits, tags, switches the JDK or changes hooks: it prints those steps for you to type.
#
#   ../scripts/reset-to-stage.sh 0|1|2|3|3-final
#
#   0        restart Module 2 (from your stage-0 tag, or from origin/main)
#   1        start Module 3        2  start Module 4        3  start Module 5
#   3-final  start Module 6 or 7 (stage 3 plus the Module 5 deploy-and-push guard)
#
# Exit: 0 reset done, 2 usage, 3 wrong folder or source missing, 4 refused (uncommitted changes, or no "yes").
set -eu
. "$(dirname -- "$0")/lib.sh"

YES=no
ARG=""
for a in "$@"; do
    case "$a" in
        --yes) YES=yes ;;            # for the maintainers' test harness; not documented for participants
        *) if [ -z "$ARG" ]; then ARG=$a; else ARG=bad; fi ;;
    esac
done
case "$ARG" in
    0|1|2|3) STAGE=$ARG; FINAL=no ;;
    3-final) STAGE=3; FINAL=yes ;;
    *) die "$EXIT_USAGE" "Usage: ../scripts/reset-to-stage.sh 0|1|2|3|3-final" ;;
esac
stage_info "$STAGE"
require_workspace

if [ -n "$(git status --porcelain)" ]; then
    die "$EXIT_REFUSED" "You have uncommitted changes. Save them first (they stay in your history):
  git add -A && git commit -m \"WIP before reset\"
then run this again."
fi

# Where the reference state comes from.
if [ "$STAGE" = 0 ]; then
    if git rev-parse -q --verify 'stage-0^{commit}' >/dev/null; then SRC=stage-0
    elif git rev-parse -q --verify 'origin/main^{commit}' >/dev/null; then SRC=origin/main
    else die "$EXIT_ENV" "No stage-0 tag and no origin/main: find the baseline commit with git log --oneline."; fi
    WHAT="pom.xml and src/ from $SRC"
else
    REF="$SOLUTIONS_DIR/$STAGE_REF"
    [ -f "$REF/pom.xml" ] && [ -d "$REF/src" ] || die "$EXIT_ENV" "Reference not found: $REF"
    WHAT="pom.xml and src/ from ../solutions/$STAGE_REF"
fi

say "This replaces your pom.xml and src/ with $WHAT."
say "Your work stays in your git history; .kiro/ and your specs are not touched."
if [ "$YES" != yes ]; then
    printf 'Type yes to continue: '
    read -r answer || answer=""
    [ "$answer" = yes ] || die "$EXIT_REFUSED" "Nothing changed."
fi

if [ "$STAGE" = 0 ]; then
    run git restore --source="$SRC" --staged --worktree -- pom.xml src
else
    run cp "$REF/pom.xml" pom.xml
    run rm -r src
    run cp -R "$REF/src" src
fi

BOOT=$(boot_short "$STAGE_BOOT")
if [ "$FINAL" = yes ]; then
    TAG=stage-3-final; MSG="Stage 3 verified (reference reset): Java 25, Spring Boot $BOOT, Tests run: $TESTS_EXPECTED"
    NEXT="Module 6 or 7"
else
    TAG=stage-$STAGE; MSG="Stage $STAGE (reference reset): Java $STAGE_JDK, Spring Boot $BOOT, Tests run: $TESTS_EXPECTED"
    NEXT="Module $STAGE_MODULE_NEXT"
fi

say ""
say "Done. Now type these steps yourself (they are part of the workshop):"
say "1. Make JDK $STAGE_JDK the default for new terminals, quit Kiro, open a new terminal in sample-app/"
say "   and start Kiro with: kiro .   (docs/participant-setup.md, \"Switch the JDK per terminal\")"
say "2. ../scripts/verify-stage.sh $STAGE"
step=3
if [ "$FINAL" = yes ] && [ ! -f .kiro/hooks/block-deploy-and-push.json ]; then
    say "$step. cp ../solutions/kiro-reference/hooks/block-deploy-and-push.json .kiro/hooks/"; step=$((step + 1))
fi
if [ "$STAGE" = 0 ] && [ "$SRC" = stage-0 ]; then
    say "$step. git add -A && git commit -m \"Reset to stage 0\" --allow-empty   (stage-0 already exists; no new tag)"
else
    say "$step. git add -A && git commit -m \"Reset to reference stage $ARG\""; step=$((step + 1))
    say "$step. git tag -f -a $TAG -m \"$MSG\""
fi
say "Then, in the Agent Hooks panel, set the hooks for $NEXT: $(expected_hooks "$STAGE")"
say "(the hook files say now: $(hook_states))."
