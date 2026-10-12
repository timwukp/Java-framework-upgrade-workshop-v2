# Day sheet (quick reference)

One page for the workshop day. More: [migration cheat sheet](migration-cheat-sheet.md) (what changes
at each stage) · [troubleshooting](troubleshooting.md) (symptoms and fixes) ·
[Kiro feature reference](kiro-feature-reference.md) (features, file formats, docs links) ·
[scripts](../scripts/README.md).

## The day at a glance

Every stage has **14 tests** (9 service + 5 web). Run everything from `sample-app/`.

| Module | Starts from | JDK | Hooks (verify / guard) | Ends with tag |
|---|---|---|---|---|
| 1 Setup and assessment | the baseline | 8 | on / off | `stage-0` |
| 2 Spring Boot 2.7 + Java 21 | `stage-0` | 8, then **21** in the JDK-switch step | on / off | `stage-1` |
| 3 Spring Boot 3.5 + Jakarta EE | `stage-1` | 21 | guard **on** at the start (stays on); verify **paused** while the build is red on purpose, **on** again before the end | `stage-2` |
| 4 Spring Boot 4.1 + Java 25 | `stage-2` | 21, then **25** in the Java 25 part | on / on | `stage-3` |
| 5 Quality gates | `stage-3` | 25 | on / on (verify paused only for the Bugfix demo or lab) | `stage-3-final` |
| 6, 7 (optional) | `stage-3-final` | 25 | on / on | — |

"verify" is `verify-after-spec-task`, "guard" is `jakarta-import-guard`. Switch hooks with the eye
icon in the Agent Hooks panel.

**JDK switch (Modules 2 and 4, and after a reset):** make the new JDK the default for new terminals,
quit Kiro completely, open a new terminal in `sample-app/`, start Kiro with `kiro .`, and ask the
agent for `mvn -v`. How: [Switch the JDK per terminal](participant-setup.md#switch-the-jdk-per-terminal).

## Scripts

| Command (from `sample-app/`) | Does |
|---|---|
| `../scripts/check-env.sh --stage N` | Tools, JDK of terminal and Maven, Maven cache, steering and hook files. No build. |
| `../scripts/verify-stage.sh N` | One clean build; passes only with the right JDK and parent and `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` |
| `../scripts/compare-stage.sh N` | Your `pom.xml` and `src/` against the stage 1, 2 or 3 reference |
| `../scripts/reset-to-stage.sh N` | Catch up: reference `pom.xml` and `src/` for stage 0, 1, 2, 3 or `3-final`; prints the steps you type next |
| `../scripts/smoke.sh` | The running-app checks below; needs `APP_ADMIN_PASSWORD` exported |

Git commits and tags, JDK switches, Kiro restarts and hook switches stay manual: they are part of
what you learn.

## Every time

- **Supervised** mode (`kiroAgent.agentAutonomy`): review each hunk before it is applied.
- **Commit before every agent run.** Kiro checkpoints don't capture shell commands (Maven, OpenRewrite)
  or manual edits.
- **One build at a time.** After a spec task, read the hook's result in the Kiro output, or run Maven
  yourself only after the hook has finished (builds share `target/`).
- **Always `clean`** (`mvn -B clean verify`): otherwise Maven may skip the recompile after a JDK or
  version change and hide a trap.
- **Read your own `Tests run`.** A green build with fewer tests is a failed step.
- **After a JDK switch**, quit Kiro and start it from that terminal with `kiro .`.
- **Trust** the workspace, or repo steering, agents and skills won't load. Approve `mvn *` once with
  **Always allow** for this workspace; never pre-approve deploy or push.
- After a review by `migration-reviewer`, run `git status`: it has no `write` tool, but it has `shell`.

## Start the right kind of session

| You want to… | Use |
|---|---|
| Understand the code without changing anything | **Plan** workflow (read-only) |
| A reviewed, multi-step change | **Spec** (requirements → design → tasks) |
| A change whose scope is already defined (Modules 3 and 4: a whole stage from the playbook), in one pass without approval gates | **Quick Spec**, then review the files before any task runs |
| Fix a regression, with guards against breaking more | **Bug Fix** (`bugfix.md`) |
| Ask questions, iterate freely | Default agent |
| A specialist | Agent selector → `migration-reviewer` |

Context in chat: `#codebase` · `#file` (type `#` plus a file name) · `#folder` · `#git diff` ·
`#terminal` · `#problems` · `#spec` · `#steering` · `#docs` · `#url` · `#code` · `#current` ·
`#repository` · `#mcp`. Select code and press **Cmd/Ctrl+L** to add it to the chat.

## What the running app answers

`../scripts/smoke.sh` checks these, or call them with `curl -u admin:"$APP_ADMIN_PASSWORD" …`:

| Request | Stages 0–1 | Stages 2–3 |
|---|---|---|
| `GET /api/users` without credentials | 401 | 401 |
| `GET /api/users` as admin | 200, with an `X-Request-Id` header | 200, with an `X-Request-Id` header |
| `POST /api/users` with an invalid e-mail | 400 | 400 |
| `POST /api/users` with name and e-mail only | 201, `"active":true`, ISO-8601 `createdDate` | 201, `"active":true`, ISO-8601 `createdDate` |
| The same e-mail again | 400 | 400 |
| `GET /api/users/999999` | 404 | 404 |
| `GET /api/users/` (trailing slash) | 200 | **404** (Spring Framework 6+) |

Class-file major version (`javap -v … | grep "major version"`): **52** Java 8 · **65** Java 21 ·
**69** Java 25.

## Most common problems

| Symptom | Go to |
|---|---|
| `BUILD SUCCESS` but `Tests run: 0` | [T-B01](troubleshooting.md#t-b01-build-success-but-tests-run-0-or-no-tests-run-line) |
| Tests run is lower than 14 | [T-B02](troubleshooting.md#t-b02-tests-run-is-lower-than-14) |
| `expected:<400> but was:<201>` | [T-B03](troubleshooting.md#t-b03-invaliduserisrejectedbybeanvalidation-expected400-but-was201) |
| Random compile or Surefire errors | [T-B04](troubleshooting.md#t-b04-random-compile-or-surefire-errors-that-go-away-on-a-rerun-or-a-corrupt-jar) |
| The agent's Java isn't your terminal's | [T-A02](troubleshooting.md#t-a02-the-agents-or-the-hooks-java-is-not-your-terminals) |
| The verify hook never runs | [T-K15](troubleshooting.md#t-k15-the-verify-hook-never-runs) |
| `cannot find symbol` for getters on JDK 25 | [T-B11](troubleshooting.md#t-b11-cannot-find-symbol-for-getters-setters-or-constructors-on-jdk-25) |
| Every create returns 400 on Spring Boot 4 | [T-B12](troubleshooting.md#t-b12-validuseriscreated-status-expected201-but-was400-every-create-returns-400) |
| A web test gets 403 | [T-B13](troubleshooting.md#t-b13-a-web-test-gets-403-instead-of-400-or-201) |
| Behind or stuck | [T-X04](troubleshooting.md#t-x04-you-are-behind-or-your-workspace-is-broken) |

## Raw commands

```bash
mvn -B clean verify
```
```bash
mvn -B dependency:tree -Dincludes=org.projectlombok,net.bytebuddy
```
```bash
mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true -Dmaven.compiler.showWarnings=true | grep -iE "deprecat|removal"
```
```bash
grep -rnE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])' src
```

Annotated stage tags carry the test count (`stage-0`, `stage-1`, `stage-2`, `stage-3`, then
`stage-3-final` in Module 5):

```bash
git tag -a stage-1 -m "Stage 1: Java 21, Spring Boot 2.7.18, Tests run: 14" && git tag -n1 -l "stage-*"
```

Behind? Use the one reset procedure in [solutions/README.md](../solutions/README.md), run from
`sample-app/`.
