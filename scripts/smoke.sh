#!/bin/sh
# Smoke-test the running app: the same calls at every stage, with the expected status codes.
# Start the app first (in another terminal, with APP_ADMIN_PASSWORD exported there too).
#
#   ../scripts/smoke.sh [--stage N] [--base-url URL]
#
#   --stage N       0-3; default: read from pom.xml (sets the trailing-slash expectation)
#   --base-url URL  default http://localhost:8080; add a context root for a server deployment,
#                   for example http://localhost:8080/user-management
#
# The admin password comes only from the environment variable APP_ADMIN_PASSWORD (user name from
# APP_ADMIN_USERNAME, default admin). It is never printed and never passed on a command line.
# Exit: 0 all passed, 1 a check failed, 2 usage, 3 no password or the app is not reachable.
set -eu
. "$(dirname -- "$0")/lib.sh"

usage() { die "$EXIT_USAGE" "Usage: ../scripts/smoke.sh [--stage 0|1|2|3] [--base-url URL]"; }
STAGE=""; BASE=http://localhost:8080
while [ $# -gt 0 ]; do
    case "$1" in
        --stage) [ $# -ge 2 ] || usage; STAGE=$2; shift 2 ;;
        --base-url) [ $# -ge 2 ] || usage; BASE=${2%/}; shift 2 ;;
        *) usage ;;
    esac
done
if [ -z "$STAGE" ] && [ -f pom.xml ]; then STAGE=$(stage_for_boot "$(pom_parent_version)"); fi
if [ -n "$STAGE" ]; then stage_info "$STAGE" || usage; fi

if [ -z "${APP_ADMIN_PASSWORD:-}" ]; then
    die "$EXIT_ENV" "APP_ADMIN_PASSWORD is not set. In this terminal and in the one that starts the app, run:
  printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD
(choose any local password; it is never stored)."
fi
ADMIN=${APP_ADMIN_USERNAME:-admin}
URL="$BASE/api/users"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/smoke.XXXXXX")
trap 'rm -rf "$TMP"' EXIT INT TERM
# curl reads the credentials from a config file, so the password is not visible in the process list.
esc=$(printf '%s' "$ADMIN:$APP_ADMIN_PASSWORD" | sed 's/\\/\\\\/g; s/"/\\"/g')
( umask 077; printf 'user = "%s"\n' "$esc" > "$TMP/auth" )

code=$(curl -s -o /dev/null -w '%{http_code}' "$URL" || true)
if [ "$code" = 000 ]; then
    die "$EXIT_ENV" "The app is not reachable at $URL. Start it first (for example: mvn spring-boot:run), then run this again."
fi

FAILS=0
# check LABEL EXPECTED SHOWN-COMMAND -- curl arguments...
check() {
    _label=$1; _want=$2; _shown=$3; shift 4
    printf '+ %s\n' "$_shown"
    _got=$(curl -s -D "$TMP/headers" -o "$TMP/body" -w '%{http_code}' "$@" || true)
    if [ "$_got" = "$_want" ]; then printf 'PASS  %-34s %s\n' "$_label" "$_got"
    else printf 'FAIL  %-34s got %s, expected %s\n' "$_label" "$_got" "$_want"; FAILS=$((FAILS + 1)); fi
}
A='-K <credentials from APP_ADMIN_PASSWORD>'
J="-H 'Content-Type: application/json'"
EMAIL="smoke-$(date +%s)-$$@example.com"
VALID="{\"name\":\"Smoke Test\",\"email\":\"$EMAIL\"}"

say "== Smoke test against $URL${STAGE:+ (stage $STAGE)}"
check "No credentials" 401 "curl $URL" -- "$URL"
check "List users" 200 "curl $A $URL" -- -K "$TMP/auth" "$URL"
if grep -qi '^x-request-id:' "$TMP/headers"; then printf 'PASS  %-34s %s\n' "X-Request-Id header" present
else printf 'FAIL  %-34s missing\n' "X-Request-Id header"; FAILS=$((FAILS + 1)); fi
check "Invalid user (Bean Validation)" 400 "curl $A $J -d '{\"name\":\"J\",\"email\":\"not-an-email\"}' $URL" -- \
    -K "$TMP/auth" -H 'Content-Type: application/json' -d '{"name":"J","email":"not-an-email"}' "$URL"
check "Valid user (no \"active\" field)" 201 "curl $A $J -d '$VALID' $URL" -- \
    -K "$TMP/auth" -H 'Content-Type: application/json' -d "$VALID" "$URL"
body=$(cat "$TMP/body")
if printf '%s' "$body" | grep -q '"active":true'; then printf 'PASS  %-34s %s\n' "Created user is active" '"active":true'
else printf 'FAIL  %-34s %s\n' "Created user is active" "body: $body"; FAILS=$((FAILS + 1)); fi
if printf '%s' "$body" | grep -qE '"createdDate":"[0-9]{4}-'; then printf 'PASS  %-34s %s\n' "createdDate is ISO-8601" yes
else printf 'FAIL  %-34s %s\n' "createdDate is ISO-8601" "body: $body"; FAILS=$((FAILS + 1)); fi
check "Duplicate e-mail" 400 "curl $A $J -d '$VALID' $URL" -- \
    -K "$TMP/auth" -H 'Content-Type: application/json' -d "$VALID" "$URL"
check "Unknown id" 404 "curl $A $URL/999999" -- -K "$TMP/auth" "$URL/999999"
case "$STAGE" in
    0|1) check "Trailing slash (stages 0-1: 200)" 200 "curl $A $URL/" -- -K "$TMP/auth" "$URL/" ;;
    2|3) check "Trailing slash (stages 2-3: 404)" 404 "curl $A $URL/" -- -K "$TMP/auth" "$URL/" ;;
    *)   say "INFO  Trailing slash not checked (stage unknown; use --stage N)" ;;
esac

if [ "$FAILS" -gt 0 ]; then say "$FAILS check(s) failed. See docs/troubleshooting.md (Running app)."; exit "$EXIT_FAIL"; fi
say "All checks passed."
