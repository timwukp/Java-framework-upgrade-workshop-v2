#!/bin/bash
# Maintainer tests for scripts/ (not needed by participants). Works on a throwaway clone in $TMPDIR,
# never on your checkout.
#
#   tools/test-scripts.sh          quick: arguments, refusals, resets, compare, smoke without an app
#   tools/test-scripts.sh --full   also real builds and smoke tests per stage; needs JAVA8_HOME,
#                                  JAVA21_HOME and JAVA25_HOME, Maven on PATH and network access
#
# Prints one PASS/FAIL line per check; exits 1 if any check failed.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
FULL=no; [ "${1:-}" = --full ] && FULL=yes
W=$(mktemp -d "${TMPDIR:-/tmp}/ws-test.XXXXXX")
trap 'rm -rf "$W"' EXIT
FAILS=0
ok()  { printf 'PASS  %s\n' "$1"; }
bad() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS + 1)); }
# expect CODE "description" command...  (runs in the current directory, output to $W/out)
expect() { local want=$1 what=$2; shift 2; "$@" > "$W/out" 2>&1 < /dev/null; local got=$?
           if [ "$got" = "$want" ]; then ok "$what (exit $got)"; else bad "$what: exit $got, expected $want"; sed 's/^/      /' "$W/out" | tail -n 8; fi; }

# A clone of the current commit, plus the working copy of scripts/ (so uncommitted changes are tested).
git clone -q "$ROOT" "$W/repo" || { echo "clone failed"; exit 1; }
rm -rf "$W/repo/scripts" && cp -R "$ROOT/scripts" "$W/repo/scripts" && chmod +x "$W/repo/scripts/"*.sh
echo "scripts/" >> "$W/repo/.git/info/exclude"
S="$W/repo/scripts"; APP="$W/repo/sample-app"
cd "$APP" || exit 1
parent() { awk '/<parent>/ {p=1} p && /<version>/ {sub(/.*<version>/, ""); sub(/<\/version>.*/, ""); print; exit}' pom.xml; }
# Back to the clean checkout between tests (no commits: the clone's history is never written).
clean_tree() { git checkout -q -- . && git clean -qfd -- .; }

echo "== Arguments and refusals"
(cd "$W/repo" && expect 3 "verify-stage outside sample-app" "$S/verify-stage.sh" 1)
(cd "$W/repo" && expect 3 "compare-stage outside sample-app" "$S/compare-stage.sh" 1)
(cd "$W/repo" && expect 3 "reset-to-stage outside sample-app" "$S/reset-to-stage.sh" 1 --yes)
expect 2 "verify-stage without a stage" "$S/verify-stage.sh"
expect 2 "verify-stage stage 9" "$S/verify-stage.sh" 9
expect 2 "verify-stage 2 --jdk 8 (not a workshop variant)" "$S/verify-stage.sh" 2 --jdk 8
expect 2 "compare-stage 0" "$S/compare-stage.sh" 0
expect 2 "reset-to-stage 5" "$S/reset-to-stage.sh" 5
expect 2 "check-env --stage 7" "$S/check-env.sh" --stage 7
expect 2 "smoke --stage 5" env APP_ADMIN_PASSWORD=x "$S/smoke.sh" --stage 5
touch dirty.txt
expect 4 "reset-to-stage with uncommitted changes" "$S/reset-to-stage.sh" 1 --yes
rm -f dirty.txt
expect 4 "reset-to-stage without typing yes" "$S/reset-to-stage.sh" 1
"$S/check-env.sh" > "$W/out" 2>&1; rc=$?
if [ "$rc" = 0 ] || [ "$rc" = 1 ]; then ok "check-env runs (exit $rc)"; else bad "check-env: exit $rc"; cat "$W/out"; fi

echo "== Resets and compare"
for n in 1 2 3; do
    case $n in 1) ref=stage-1-boot27-java21; boot=2.7.18 ;; 2) ref=stage-2-boot35-java21; boot=3.5.16 ;; 3) ref=stage-3-boot41-java25; boot=4.1.1 ;; esac
    expect 0 "reset-to-stage $n" "$S/reset-to-stage.sh" $n --yes
    [ "$(parent)" = "$boot" ] && diff -r "../solutions/$ref/src" src > /dev/null && ok "stage $n: pom and src match the reference" || bad "stage $n: pom or src differ"
    expect 0 "compare-stage $n right after the reset" "$S/compare-stage.sh" $n
    printf '\n' >> src/main/java/com/example/usermanagement/UserManagementApplication.java
    expect 1 "compare-stage $n after an edit" "$S/compare-stage.sh" $n
    clean_tree
done
"$S/reset-to-stage.sh" 3-final --yes > "$W/out" 2>&1 && grep -q 'block-deploy-and-push.json .kiro/hooks/' "$W/out" \
    && grep -q 'git tag -f -a stage-3-final' "$W/out" && ok "reset-to-stage 3-final prints the hook copy and the tag" || bad "reset-to-stage 3-final output"
clean_tree
expect 0 "reset-to-stage 0 (from origin/main)" "$S/reset-to-stage.sh" 0 --yes
[ "$(parent)" = 2.2.4.RELEASE ] && git diff --quiet origin/main -- pom.xml src && ok "stage 0: pom and src match origin/main" || bad "stage 0 differs from origin/main"
clean_tree

echo "== Smoke test without an app"
expect 3 "smoke without APP_ADMIN_PASSWORD" env -u APP_ADMIN_PASSWORD "$S/smoke.sh"
PW="pw-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
expect 3 "smoke with the app down" env APP_ADMIN_PASSWORD="$PW" "$S/smoke.sh" --base-url http://127.0.0.1:1
if grep -q "$PW" "$W/out"; then bad "smoke printed the password"; else ok "smoke never prints the password"; fi

if [ "$FULL" = yes ]; then
    for v in JAVA8_HOME JAVA21_HOME JAVA25_HOME; do [ -x "${!v:-}/bin/java" ] || { bad "$v not set to a JDK"; FULL=no; }; done
fi
if [ "$FULL" = yes ]; then
    use() { export JAVA_HOME=$1 PATH="$1/bin:$ORIG_PATH"; }
    ORIG_PATH=$PATH
    edit() { python3 - "$@" <<'PY'
import sys
path, old, new = sys.argv[1:4]
s = open(path).read()
assert old in s, f"not found in {path}: {old!r}"
open(path, "w").write(s.replace(old, new, 1))
PY
    }
    smoke_stage() { # stage
        local jar pid i
        jar=$(ls target/*.jar | head -n 1)
        APP_ADMIN_PASSWORD="$PW" "$JAVA_HOME/bin/java" -jar "$jar" --server.port=18080 > "$W/app.log" 2>&1 & pid=$!
        for i in $(seq 1 120); do curl -s -o /dev/null http://localhost:18080/api/users && break; sleep 1; done
        expect 0 "smoke stage $1 on the running app" env APP_ADMIN_PASSWORD="$PW" "$S/smoke.sh" --stage "$1" --base-url http://localhost:18080
        if grep -q "$PW" "$W/out"; then bad "smoke printed the password"; fi
        kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    }

    echo "== Full: builds"
    use "$JAVA8_HOME"
    expect 0 "verify-stage 0 on JDK 8" "$S/verify-stage.sh" 0
    smoke_stage 0
    use "$JAVA21_HOME"
    expect 3 "verify-stage 0 on JDK 21 (wrong JDK)" "$S/verify-stage.sh" 0
    use "$JAVA8_HOME"
    edit pom.xml "<version>2.2.4.RELEASE</version>" "<version>2.7.18</version>"
    expect 1 "verify-stage 1 --jdk 8 after the bare parent bump (Tests run: 0)" "$S/verify-stage.sh" 1 --jdk 8
    grep -q 'Tests run: 0' "$W/out" && ok "the Tests run: 0 state is reported" || bad "Tests run: 0 not shown"
    git checkout -q -- pom.xml

    use "$JAVA21_HOME"
    clean_tree; "$S/reset-to-stage.sh" 1 --yes > /dev/null
    expect 0 "verify-stage 1 on JDK 21" "$S/verify-stage.sh" 1
    smoke_stage 1
    edit pom.xml "<artifactId>spring-boot-starter-validation</artifactId>" "<artifactId>spring-boot-starter</artifactId>"
    expect 1 "verify-stage 1 without the validation starter (400 vs 201)" "$S/verify-stage.sh" 1
    cp ../solutions/stage-1-boot27-java21/pom.xml pom.xml

    clean_tree; "$S/reset-to-stage.sh" 2 --yes > /dev/null
    expect 0 "verify-stage 2 on JDK 21" "$S/verify-stage.sh" 2
    smoke_stage 2

    clean_tree; "$S/reset-to-stage.sh" 3 --yes > /dev/null
    edit pom.xml "<java.version>25</java.version>" "<java.version>21</java.version>"
    expect 0 "verify-stage 3 --jdk 21 (No JDK 25 variant)" "$S/verify-stage.sh" 3 --jdk 21
    cp ../solutions/stage-3-boot41-java25/pom.xml pom.xml
    use "$JAVA25_HOME"
    expect 0 "verify-stage 3 on JDK 25" "$S/verify-stage.sh" 3
    smoke_stage 3
    U=src/main/java/com/example/usermanagement/entity/User.java
    edit "$U" "import lombok.Data;" "import lombok.AllArgsConstructor;
import lombok.Data;"
    edit "$U" "@NoArgsConstructor
" "@NoArgsConstructor
@AllArgsConstructor
"
    expect 1 "verify-stage 3 with @AllArgsConstructor (Jackson 3 trap)" "$S/verify-stage.sh" 3
    cp "../solutions/stage-3-boot41-java25/$U" "$U"
    expect 0 "check-env --stage 3 on JDK 25" "$S/check-env.sh" --stage 3
fi

echo ""
if [ "$FAILS" -gt 0 ]; then echo "$FAILS check(s) failed."; exit 1; fi
echo "All checks passed."
