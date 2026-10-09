# Module 5 — Quality gates (30 minutes)

Stage 3 (Java 25, Spring Boot 4.1) passes four quality gates before you call the migration done.

## What you'll do

- Review the migration with the **`migration-reviewer` custom agent**, directly and as a **sub-agent**.
- Write a **`PreToolUse` hook** in plain English that blocks deploy goals and `git push`.
- Watch a **Bugfix spec** keep "SHALL CONTINUE TO" requirements (demo; optional lab).
- Verify the build, the test count and secrets; tag `stage-3-final`.

| Part | Topic | Time |
|---|---|---|
| 1 | Reviewer agent and sub-agent | 8 min |
| 2 | Guard hook in plain English | 7 min |
| 3 | Bugfix spec (instructor demo) | 5 min |
| 4 | Final verification and tag | 10 min |

> Running late? Do Parts 1 and 4 only (the agenda's fallback); do Part 2 and the lab later.

## Prerequisites

- Module 4 is finished: tag `stage-3`, Spring Boot 4.1.1, `java.version` 25, 13 tests passing on
  JDK 25, everything committed. Behind? Use the Module 5 row of
  [Reset your workspace to a stage](../solutions/README.md).
- Branch `workshop`; the `stage-0` tag message records `Tests run: 13`.
- `sample-app/` is **trusted**, and JDK 25 is active in your terminal.
- **Hooks at the start:** `verify-after-spec-task` **on**, `jakarta-import-guard` **on**.

Checks, from `sample-app/`:

```bash
git status --short
git tag --list 'stage-*'
mvn -v
grep -n -A2 '<artifactId>spring-boot-starter-parent</artifactId>' pom.xml
```

Expect: no `git status` output; `stage-0` and `stage-3` tags; `Java version: 25…`; parent `4.1.1`.

---

## Part 1 — Review with the `migration-reviewer` agent (8 min)

### Exercise 5.1 — Select the agent and review the migration

**Goal:** an independent review of the code and build changes since stage 0, against the workspace
standards.

**Steps**

1. Run `cat .kiro/agents/migration-reviewer.md`. The agent has no `write` tool and is told not to
   modify files. Only `mvn -B verify`, `mvn -v` and read-only git run unprompted; plugin goals, deploy,
   push, commit, reset and `rm` are denied (full list below). It has `shell`, so check `git status`
   after every review.
2. Start a new chat session. Click the agent name (for example **Default**) in the chat input bar and
   choose **migration-reviewer**.
3. Send the prompt. Don't run Maven yourself until the review finishes.

**Ask Kiro**

```text
Review the migration from the stage-0 tag to the current commit, code and build only:
git diff stage-0..HEAD -- pom.xml src
Run mvn -B verify once and report the Tests run / Failures / Errors / Skipped totals.
Compare the number of @Test methods with the test sources at stage-0 (git show and git diff are allowed).
Check it against the steering files and the jakarta-namespace-migration skill.
Use the table format from your instructions and finish with the one-line verdict.
```

It should run `mvn -B verify` without asking and return a findings table, `Tests run: 13…` and a
verdict.

**Verify:** `git status --short` prints nothing (otherwise `git diff`, then `git restore <file>`).

**Checkpoint.** Nothing to commit. Keep the `Tests run` line for Exercise 5.2. Fix any **blocker** with
the Default agent before Part 4, then `git add -A && git commit -m "Module 5: fix reviewer blockers"`.

<details><summary>Background: the agent's front matter, how steering and skills reach it, and an example review</summary>

| Front-matter field | What it does in this agent |
|---|---|
| `tools: ["read", "shell"]` | The agent can read files and run commands. It has no `write` tool, so it can't edit files directly. Its instructions also tell it not to modify files. |
| `permissions.rules` | Lets `mvn -B verify`, `mvn -B -q verify`, `mvn verify`, `mvn -v`, `git diff*`, `git status*`, `git log*` and `git show*` run without prompting. Denies `mvn *:*` (plugin goals), `mvn *deploy*`, `git push*`, `git commit*`, `git reset*`, `git checkout*`, `git restore*`, `git stash*` and `rm *`. A deny rule always wins; any other command prompts. |
| `resources` | `file://.kiro/steering/**/*.md` and `skill://.kiro/skills/*/SKILL.md`. |

Kiro doesn't load workspace custom agents, steering or skills in an untrusted workspace, which is why
the workspace must be trusted.

**Why `resources` matters.** The workspace's steering files and skills reach this agent through
`resources`. The steering docs say that steering files are not included automatically when you use
a custom agent, and the skills docs say that custom agents don't load skills unless they are listed
with `skill://`. The two schemes load differently:

- `file://` resources are loaded into the agent's context when it starts. Here that covers every
  steering file, including the `always`, `fileMatch` and `manual` ones.
- `skill://` resources start with only the skill's name and description. The full `SKILL.md` loads
  when the agent decides it needs it.

The configuration reference also describes inherited default resources, which you can switch off with
`chat.disableInheritingDefaultResources`. Because the reviewer lists its resources explicitly, it gets
the same standards whichever way that setting is configured.

If the agent selector isn't in the chat input bar in your build, the Creating agents page also
mentions an agent picker in the chat pane header. The switch applies to the current session from your
next message. If the agent tries a command on its deny list, Kiro refuses it.

Example review (yours will differ):

```text
| Severity   | File:line                  | Finding                                              | Suggested fix                         |
|------------|----------------------------|------------------------------------------------------|---------------------------------------|
| should-fix | pom.xml:57                 | Dependency pins a version the Boot parent manages     | Remove <version>, let the BOM manage it |
| nit        | UserController.java:24     | Field injection left in one place                     | Use constructor injection             |
Tests run: 13, Failures: 0, Errors: 0, Skipped: 0 (stage-0 sources: 13 @Test methods)
Verdict: ready to commit
```

Docs: [Custom agents](https://kiro.dev/docs/custom-agents/) ·
[Creating agents](https://kiro.dev/docs/custom-agents/creating/) ·
[Configuration reference](https://kiro.dev/docs/custom-agents/configuration-reference/) ·
[Steering](https://kiro.dev/docs/steering/) · [Skills](https://kiro.dev/docs/skills/) ·
[Permissions — workspace trust](https://kiro.dev/docs/permissions/)

</details>

### Exercise 5.2 — Delegate one review to a sub-agent

**Goal:** the Default agent delegates a tests-only review to a `migration-reviewer` sub-agent, which
runs in its own context.

**Steps:** switch the selector back to **Default** and name the agent explicitly (more predictable
than letting Kiro pick one).

**Ask Kiro** (paste your line from Exercise 5.1)

```text
Use the migration-reviewer agent as a sub-agent to review only the tests: git diff stage-0..HEAD -- src/test
Another reviewer already ran the build, so the sub-agent must not run Maven. Use this result:
<paste the Tests run line from Exercise 5.1>
Then show me its findings table and its verdict.
```

Only one reviewer runs Maven: two builds in one `target/` fail randomly.

**Verify:** `git status --short` prints nothing. Trust findings both reviews raise first.
**Checkpoint:** nothing to commit.

<details><summary>Background: sub-agents, and two reviewers in parallel</summary>

- Sub-agents share the workspace (files, steering, MCP servers) but each keeps its own conversation
  and context window. That is why one reviewer can concentrate on tests while another reads `pom.xml`.
- Sub-agents inherit the parent session's permission rules, combined with their own on a deny-wins
  basis. The reviewer's deny list still applies.
- If you have turned on Workflows (Module 7), delegating to a custom agent runs as a background
  workflow instead. That is expected.
- In the IDE, workspace agents also show up as slash commands, so typing `/migration-reviewer` is
  another way to call it.

If you have time, try two reviewers in parallel. Only the first one builds:

```text
Use the migration-reviewer agent twice, in parallel:
1. one reviewer for production code only: git diff stage-0..HEAD -- src/main pom.xml
   This reviewer runs mvn -B verify once.
2. one reviewer for tests only: git diff stage-0..HEAD -- src/test
   This reviewer must not run Maven; it uses the build result from reviewer 1.
Then merge both reports into one table, mark findings that both reviewers raised, and give one verdict.
```

Docs: [Sub-agents](https://kiro.dev/docs/custom-agents/subagents/) ·
[Slash commands](https://kiro.dev/docs/ide/chat/slash-commands/) ·
[Chat — agent selector](https://kiro.dev/docs/ide/chat/)

</details>

---

## Part 2 — A guard hook written in natural language (7 min)

### Exercise 5.3 — Block deploy goals and `git push`

**Goal:** no agent in this workspace runs a deploy goal or `git push`, enforced by a hook committed
with the code.

**Steps**

1. In the Kiro panel, under **Agent Hooks**, click **+** and select **Ask Kiro to create a hook**.
2. Describe the hook:

**Ask Kiro**

```text
Create a PreToolUse hook block-deploy-and-push for the shell tools (matcher "shell"): a command action
(not an agent prompt, so no credits), timeout 10 seconds, v1 format, in .kiro/hooks/block-deploy-and-push.json.
It reads the tool-call JSON on stdin and blocks, case-insensitive, only a mvn/gradle/gradlew deploy goal
(mvn deploy, mvn clean deploy, mvn wildfly:deploy) and git push (also git -C dir push), not paths like
deploy/zos. To block, print "Blocked by workspace policy: deploy and git push are run by humans, not
the agent." to stderr and exit 2. Otherwise exit 0 silently.
```

3. Approve the file write. Writes to `.kiro/hooks/` always prompt, even in Autopilot.
4. Compare the file with the reference, `../solutions/kiro-reference/hooks/block-deploy-and-push.json`:

```json
{
  "version": "v1",
  "hooks": [
    {
      "name": "block-deploy-and-push",
      "description": "Humans deploy and push, not the agent. Blocks shell tool calls that run a Maven/Gradle deploy goal or git push.",
      "trigger": "PreToolUse",
      "matcher": "shell",
      "action": {
        "type": "command",
        "command": "payload=$(cat); if printf '%s' \"$payload\" | grep -qiE '(mvn|gradlew?)[^\"]*[[:space:]][a-z:-]*deploy([[:space:]\"\\\\]|$)|git[^\"]*[[:space:]]push([[:space:]\"\\\\]|$)'; then echo 'Blocked by workspace policy: deploy and git push are run by humans, not the agent.' 1>&2; exit 2; fi; exit 0"
      },
      "timeout": 10
    }
  ]
}
```

**What the pattern matches.** Only `mvn`, `gradle` or `gradlew` followed by a word ending in `deploy`
(`deploy`, `wildfly:deploy`), and `git` followed by the word `push`, within one JSON string. Paths
such as `deploy/zos/…` or `deploy-container.md` don't match. Exit `2` blocks under every reading of
the docs. If your file fails the tests, copy the reference into `.kiro/hooks/`.

**Verify (terminal)** with two fake payloads:

```bash
HOOK_CMD=$(python3 -c "import json; print(json.load(open('.kiro/hooks/block-deploy-and-push.json'))['hooks'][0]['action']['command'])")
echo '{"tool_name":"shell","tool_input":{"command":"git push origin workshop"}}' | sh -c "$HOOK_CMD"; echo "exit=$?"
echo '{"tool_name":"shell","tool_input":{"command":"mkdir -p deploy/zos"}}' | sh -c "$HOOK_CMD"; echo "exit=$?"
```

Expect the "Blocked by workspace policy" message and `exit=2`, then only `exit=0`.

**Verify (in Kiro, Default agent)** with a harmless command:

```text
Run exactly this shell command and tell me what happened: echo mvn deploy
```

If Kiro asks to approve the `echo`, choose **Allow** (not Always allow). The hook should then block it,
and the agent should quote the message (else see the hook log in the Kiro output panel). Then check
that `Run mvn -B -q validate and tell me the exit code.` still works.

**Checkpoint:** `git add .kiro/hooks/block-deploy-and-push.json && git commit -m "Module 5: PreToolUse
hook blocks deploy goals and git push"`

<details><summary>Background: how the hook pieces work, why exit 2, and its limits</summary>

Why a hook: the reviewer's deny list protects only the reviewer, and permission rules are per user
and can't be shipped in a repository. A hook file in `.kiro/hooks/` is committed with the code, so
everyone who opens the workspace gets it.

How the pieces work:

- `"version": "v1"` and the PascalCase trigger are the IDE 1.0 format. Older `.kiro.hook` files don't
  run until you migrate them.
- For `PreToolUse`, `matcher` is matched against the tool name. `shell` is the built-in category for
  all shell command tools.
- A `command` action receives the session context as JSON on stdin. The docs show the payload fields
  for MCP tools (`tool_name`, `tool_input`) but not for the built-in shell tool. That's why the hook
  searches the whole payload rather than one field, and why the field names in the terminal test are
  only illustrative.
- `[^"]*` stops a match at the next quote, so both words of a match must sit in the same JSON string.
  A working directory named "deploy" therefore doesn't match either.
- The terminal test can also feed it `mvn -B clean verify`; that should exit 0. The in-Kiro test uses
  `echo mvn deploy`, a harmless command, so nothing happens even if the hook fails.
- In the `deploy` alternative, `deploy` must be followed by a space, a quote, a backslash or the end of
  the text; `git -C dir push` matches because `push` is a separate word after `git`.
- On a blocking exit, Kiro returns stderr to the agent, so the agent learns why it was stopped.
- The timeout defaults to 60 seconds. A text check needs far less.
- Writes to `.kiro/hooks/` prompt even when an allow rule matches.

> Verify: the docs don't say which shell Kiro uses to run hook commands. `sh -c` in the terminal test
> is a close approximation; the in-IDE test is the one that counts.

**Why `exit 2`.** The docs disagree on which exit code blocks:

- The Hook actions page says any non-zero exit from a Pre Tool Use command blocks the tool call.
- What's new in IDE 1.0 says only exit code 2 blocks `PreToolUse`, `UserPromptSubmit` and
  `PreTaskExec`, and treats any other non-zero code as an error, not a block.
- The CLI exit-codes reference lists `2` as "(PreToolUse only) Block tool execution; STDERR returned
  to LLM".

`exit 2` blocks under every reading, so use it for intentional blocks and don't count on `exit 1`.
The workspace's `jakarta-import-guard` hook uses `exit 1` on purpose: it runs on `PostFileSave`, which
reports a problem to the agent rather than blocking anything. Under the "only 2 blocks" reading, a
hook that crashes fails open. Test it so you know it really blocks.

Limits to keep in mind:

- This is a text-pattern guardrail, not a security boundary. A script, an alias or a goal written
  differently (for example `mvn deploy:deploy-file`) can get around it, and it can over-match (for
  example a `-DskipDeploy` property on a `mvn` command). Keep the permission deny rules as well.
- `PreToolUse` fires on the **agent's** tool calls only. It doesn't stop you from pushing from your own
  terminal, which is intended.
- **File hooks fire only on agent edits.** `PostFileCreate`, `PostFileSave` and `PostFileDelete` (for
  example `jakarta-import-guard`) ignore changes you make in the editor. The Bugfix lab relies on that.

Docs: [Hooks](https://kiro.dev/docs/hooks/) · [Hook triggers](https://kiro.dev/docs/hooks/types/) ·
[Hook actions](https://kiro.dev/docs/hooks/actions/) ·
[Hooks in IDE 1.0](https://kiro.dev/docs/ide/whats-new-v1/hooks/) ·
[Exit codes](https://kiro.dev/docs/reference/exit-codes/) ·
[Permissions (Kiro-scope paths always ask)](https://kiro.dev/docs/permissions/)

</details>

---

## Part 3 — Bugfix spec on a deliberate regression: instructor demo (5 min)

**Goal:** see why a regression gets a **Bugfix spec**: `bugfix.md` lists **Current**, **Expected**
(SHALL) and **Unchanged Behavior** (SHALL CONTINUE TO, the regression requirements).

**What the instructor shows:** the CSRF exemption in `SecurityConfig.java` narrowed from `/api/**` to
`/api/public/**` on a throwaway branch, so one web test gets 403 instead of 400. With
`verify-after-spec-task` paused (the build is red on purpose until the fix), a Bug Fix spec lists the
unchanged behavior and the root cause. The right fix restores `/api/**`; it doesn't edit the test or
switch CSRF off. Then the hook is re-enabled.

**Checkpoint:** nothing changes in your workspace; the optional lab lets you try it.

---

## Part 4 — Final verification and tag (10 min)

### Exercise 5.4 — Prove stage 3 and tag `stage-3-final`

**Goal:** repeatable proof that stage 3 builds on JDK 25, keeps its 13 tests, and holds no secrets.

**Steps and Verify**

1. Check in the Kiro output panel that no agent or hook build is running, then build:

   ```bash
   mvn -v
   mvn -B clean verify | tee build.log
   grep -E 'BUILD (SUCCESS|FAILURE)' build.log
   grep -E '^\[(INFO|WARNING|ERROR)\] Tests run:' build.log | tail -1
   ```

   Expect `Java version: 25…`, `BUILD SUCCESS` and `Tests run: 13, Failures: 0, Errors: 0` (read your
   own number).

2. Compare with stage 0:

   ```bash
   git show stage-0 --no-patch
   git grep -c '@Test' stage-0 -- src/test | awk -F: '{s+=$NF} END {print "stage-0 @Test methods:", s}'
   git grep -c '@Test' HEAD -- src/test | awk -F: '{s+=$NF} END {print "HEAD    @Test methods:", s}'
   ```

   Expect `Tests run: 13` in the tag message and 13 `@Test` methods at both revisions.

3. Scan the code and build files for secrets:

   ```bash
   git grep -n -I -i -E '(password|passwd|secret|api[_-]?key|token)[[:space:]]*[=:]' HEAD -- pom.xml src
   git diff stage-0..HEAD -- pom.xml src | grep -n -i -E '^\+.*(password|passwd|secret|api[_-]?key|token)'
   git ls-files | grep -E '(^|/)\.env$|\.log$'
   ```

   Expect only placeholders such as `${DB_PASSWORD:}`, added lines that handle passwords in code
   (`PasswordEncoder`, `.password(…)`), and nothing from the last command.

4. Tag it. The hook only stops the agent; you decide when to push.

   ```bash
   git status --short
   git tag -a stage-3-final -m "Stage 3 verified: Java 25, Spring Boot 4.1.1, Tests run: 13, reviewed, secret scan clean"
   git tag --list 'stage-*'
   ```

   If your build showed a number other than 13, find out why before you tag.

**Checkpoint:** tag `stage-3-final` exists; `git status --short` prints nothing.

<details><summary>Background: more on the test count and the secret scan</summary>

- `*.log` files are git-ignored in this repository, so `build.log` stays untracked.
- Module 1 recorded the baseline in the `stage-0` tag message. The runtime number is the authority;
  the static count of `@Test` methods is a second check that doesn't depend on notes. At stage 0 the
  sample app's test sources contain 13 `@Test` methods.
- Fewer tests usually means a JUnit 4 class was left without an engine, or a test was dropped. The
  `test-rules` steering forbids both.
- The placeholders you should see include `@Value("${app.security.admin.password:}")` in
  `SecurityConfig.java` and the `${…:}` values in `application.properties`.
- No passwords belong in this repository, so every hit must be an empty value or a `${...}`
  placeholder, and no literal value may be added by the migration. The scan covers only `pom.xml` and
  `src`, so specs, notes, steering and skills (which mention passwords in prose) don't flood it.
- No `.env` and no log files may be tracked: the startup log prints generated passwords, and it must
  never be committed.
- This grep is a smoke test. In CI, use a dedicated secret scanner.
- The tag message should describe only what you did.

</details>

---

## Optional lab — Exercise 5.5: Bugfix spec yourself (after Part 4)

About 20–30 minutes of agent time, on its own branch.

<details><summary>Optional lab: break the CSRF exemption, then fix it with a Bugfix spec</summary>

**Goal:** see the "SHALL CONTINUE TO" requirements stop a fix that turns the build green but changes
behavior. A Feature spec is the wrong tool for a regression; the docs say Feature specs are "not ideal
for" bug fixes. The Bugfix spec also produces a `design.md` (root cause, fix approach, properties to
test) and a `tasks.md`.

**Steps**

1. Work on a throwaway branch, so `stage-3-final` never depends on this lab:

   ```bash
   git switch -c m5-bugfix-lab
   ```

2. In the Agent Hooks panel, pause `verify-after-spec-task` (eye icon). The build stays red on purpose
   until the fix task, and a red hook result after the "reproduce the bug" task would push the agent
   to fix the bug too early. You re-enable it in step 10.
3. Introduce the regression **by hand**. In `src/main/java/com/example/usermanagement/config/SecurityConfig.java`,
   change `csrf.ignoringRequestMatchers("/api/**")` to `csrf.ignoringRequestMatchers("/api/public/**")`.
   Manual edits don't trigger file hooks, and checkpoints don't capture them, so commit right away:

   ```bash
   git commit -am "lab: narrow the CSRF exemption (deliberate regression)"
   ```

4. Look at the symptom in Kiro's terminal:

   ```bash
   mvn -B clean verify
   ```

   `invalidUserIsRejectedByBeanValidation` fails: it expects 400 and gets 403, because the POST now
   needs a CSRF token. The other 12 tests pass.

5. Start a Bugfix spec. On the **Let's build** screen of a new session, choose **Bug Fix**. In an
   existing session, pick **Bug Fix** from the agent selector, or use `/bug-fix`.

**Ask Kiro**

```text
#terminal Authenticated API calls broke after a security config cleanup: mvn -B clean verify fails in
invalidUserIsRejectedByBeanValidation, which now gets 403 Forbidden instead of 400 Bad Request.
Expected: authenticated clients of the stateless HTTP Basic API can POST /api/users without a CSRF token,
as at stage 3; invalid input is rejected with 400 before UserService.createUser is called.
Must not change: unauthenticated requests still get 401, /api/public/** stays public, CSRF protection
stays on for non-API paths, Bean Validation, the X-Request-Id response header, valid users are still
created with 201, and the number of tests must not go down. Do not change the tests to fit the bug.
The verify hook is paused for this lab: run mvn -B clean verify once at the end of each task yourself
and quote the Tests run line in your summary.
```

6. Review `bugfix.md` before approving it. Look at the **Unchanged Behavior** section.

   Example (yours will differ):

   ```markdown
   ### Current Behavior (Defect)
   * WHEN an authenticated client POSTs to /api/users without a CSRF token THEN the system responds
     403 Forbidden

   ### Expected Behavior (Correct)
   * WHEN an authenticated client POSTs a user with an invalid email THEN the system SHALL respond
     400 Bad Request without calling UserService.createUser

   ### Unchanged Behavior (Regression Prevention)
   * WHEN an unauthenticated client calls /api/users THEN the system SHALL CONTINUE TO respond 401
   * WHEN an authenticated client POSTs a valid user THEN the system SHALL CONTINUE TO respond 201 Created
   * WHEN the service sends any response THEN the system SHALL CONTINUE TO include the X-Request-Id header
   * WHEN the test suite runs THEN the system SHALL CONTINUE TO run at least as many tests as before
   ```

   If one of your "must not change" items is missing, add it, either by editing `bugfix.md` or by
   asking in the spec chat. Then continue to the design.

7. Read the root cause and fix approach in `design.md`. Watch for the tempting wrong fixes: adding
   `.with(csrf())` to the test, or `csrf.disable()`. Both turn the build green, but the first bends the
   test to the bug (the `test-rules` steering forbids loosened tests) and the second changes the CSRF
   rules for every path. The right fix restores `ignoringRequestMatchers("/api/**")`.
8. Read `tasks.md`. The docs say bugfix tasks come with property-based tests that check that the bug
   reproduces, that it is fixed, and that nothing else regressed. Check which test library they want.
   A new test dependency is a `pom.xml` change, which the `pom-rules` steering asks you to justify.
   Plain JUnit Jupiter tests are fine if you prefer them. **Run all Tasks** runs only required tasks,
   so check which test tasks are marked optional.
9. Run the tasks **one at a time**, not with Run all Tasks. Tasks in the same wave run concurrently,
   and two Maven builds in one `target/` give random failures.
10. When the last task is done, re-enable `verify-after-spec-task` in the Agent Hooks panel.

**Verify**

```bash
grep -n "ignoringRequestMatchers" src/main/java/com/example/usermanagement/config/SecurityConfig.java
mvn -B clean verify | grep -E '^\[(INFO|WARNING|ERROR)\] Tests run:' | tail -1
ls .kiro/specs/
```

Expect:

- The exemption is `/api/**` again.
- `Failures: 0, Errors: 0`, and a count of at least 13. It may be higher if the regression-test
  tasks ran.
- A new spec folder containing `bugfix.md`, `design.md` and `tasks.md`.

**Checkpoint**

```bash
git add -A
git commit -m "fix: restore the CSRF exemption for /api/** (bugfix spec)"
git switch workshop
```

Merging is optional: `git merge --no-ff m5-bugfix-lab -m "Module 5: bugfix spec lab"` keeps the spec
and any new regression tests on `workshop`. Without the merge, `workshop` stays exactly as tagged.
`stage-3-final` points at the commit you verified in Part 4 either way.

**Lab troubleshooting**

| Symptom | Likely cause | Fix |
|---|---|---|
| No **Bug Fix** option on the Let's build screen | The entry point differs between builds | Use the agent selector → **Bug Fix**, or `/bug-fix` |
| The fix adds `.with(csrf())` to the test or disables CSRF | A green build without the original behavior | Reject the task; point to the Expected/Unchanged requirements; restore `/api/**` |
| Spec tasks no longer report a `Tests run` line after the lab | `verify-after-spec-task` is still paused | Re-enable it in the Agent Hooks panel |
| `mvn -B clean verify` stays green after the regression | Your web test doesn't load `SecurityConfig` | Check for `@Import(SecurityConfig.class)`; or confirm the 403 with `curl` against `mvn spring-boot:run` and describe that symptom |

Docs: [Bugfix specs](https://kiro.dev/docs/specs/bugfix-specs/) · [Specs](https://kiro.dev/docs/specs/) ·
[Checkpoints](https://kiro.dev/docs/checkpoints/)

</details>

<details><summary>Background: the alternative regression (remove spring-boot-starter-validation)</summary>

The lab can also start from a dependency regression. It shows the Module 2 trap again.

- **Break it:** in `pom.xml`, delete the whole `<dependency>` block for `spring-boot-starter-validation`
  by hand, check with `grep -n "spring-boot-starter-validation" pom.xml` (it should print nothing), and
  commit (`git commit -am "lab: remove spring-boot-starter-validation (deliberate regression)"`).
- **Symptom:** `mvn -B clean verify` shows either compile errors for `jakarta.validation` or a failing
  `invalidUserIsRejectedByBeanValidation` test, depending on what else is on the classpath. With
  compile errors, the bugfix's exploration test can't even compile, which is why the CSRF regression
  is the default.
- **Prompt:** "Input validation is broken after a dependency cleanup … Expected: POST /api/users with an
  invalid name or email is rejected with 400 Bad Request before UserService.createUser is called …
  Prefer dependencies managed by the Spring Boot parent; do not add version pins."
- **Wrong fix to watch for:** adding only the `jakarta.validation` **API** makes the code compile, but
  without a provider `@Valid` is silently ignored. The Expected and Unchanged requirements, together
  with the existing test, catch it. The right fix restores `spring-boot-starter-validation` without a
  `<version>`.
- **Verify:** `grep -n -A2 "spring-boot-starter-validation" pom.xml` shows the starter with no
  `<version>` line, and the build passes with at least 13 tests.

</details>

---

## Checklist

- [ ] The reviewer and a tests-only sub-agent reviewed the migration; `git status` stayed clean.
- [ ] `block-deploy-and-push.json` is committed and passed the terminal and Kiro tests.
- [ ] You can name the three sections of `bugfix.md`.
- [ ] `mvn -B clean verify` passes on JDK 25 with 13 tests; the secret scan found only placeholders.
- [ ] Tag `stage-3-final` created; both workspace hooks are on.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `migration-reviewer` is missing | Workspace untrusted, repo root opened, or invalid front matter | Trust and open `sample-app/`; check the YAML; new session |
| Random compile or Surefire errors | Two Maven builds overlapping in `target/` | Wait, then rerun `mvn -B clean verify` |
| The hook doesn't block, or blocks too much | Exit 1, a crash, or a broader pattern | Copy the reference file; rerun the terminal test |
| Fewer than 13 tests | A JUnit 4 class without an engine, or a deleted test | Migrate to JUnit Jupiter; restore deleted tests |

<details><summary>Background: more troubleshooting</summary>

| Symptom | Likely cause | Fix |
|---|---|---|
| `git status` shows changes after a review | A shell command you approved changed a file | `git diff` to inspect, `git restore <file>` to undo |
| The reviewer ignores the migration standards | `resources` lines changed or removed | Restore `file://.kiro/steering/**/*.md` and `skill://.kiro/skills/*/SKILL.md` |
| The reviewer asks before `git grep` or `mvn -B clean verify` | Only the commands in its allow list run without a prompt | Approve once, or ask it to use `git show` / `git diff` and `mvn -B verify` |
| "Use the migration-reviewer agent" fails | Agent name misspelled; an unknown agent name fails rather than falling back | Use the exact file name without `.md`, or `/migration-reviewer` |
| Delegation runs in the background | Workflows are enabled, so custom-agent delegation becomes a workflow run | Expected; follow it in the workflow view, or disable Workflows |
| The new hook never fires | Hook disabled (eye icon), invalid JSON, or a matcher that doesn't match shell tools | Check the Agent Hooks panel and the Kiro output panel; set `"matcher": "shell"` |
| The hook blocks every shell command | The pattern matches something in every payload, for example a working-directory path containing "deploy" | Use the reference pattern, which matches only deploy goals and `git push` |
| Kiro asks before writing the hook file | Writes to `.kiro/hooks/` always ask | Expected; approve it |
| Kiro asks you to approve `echo mvn deploy` | `echo` is not in the default allow list | Choose **Allow** (not Always allow); the hook should then block it |
| `mvn -v` shows Java 21 | `JAVA_HOME`/`PATH` still points at JDK 21 | Switch to JDK 25 (see participant setup) and open a new terminal |
| `git grep … stage-0` says "bad revision" | The `stage-0` tag is missing | Find the baseline commit with `git log --oneline` and `git tag stage-0 <commit>` |
| The secret scan finds a literal password | A value was hard-coded during the migration | Replace it with `${ENV_VAR:}`; if it was ever real, rotate it |

</details>

## Kiro features used

Custom agents, sub-agents, `resources`, hooks v1, workspace trust, Bugfix specs, `#terminal`,
checkpoints.

<details><summary>Background: docs for each feature</summary>

| Feature | Docs |
|---|---|
| Custom agents (Markdown front matter, `tools`, `permissions.rules`, `resources`) | https://kiro.dev/docs/custom-agents/ · https://kiro.dev/docs/custom-agents/creating/ · https://kiro.dev/docs/custom-agents/configuration-reference/ |
| Agent selector | https://kiro.dev/docs/ide/chat/ |
| Sub-agents (isolated context) | https://kiro.dev/docs/custom-agents/subagents/ |
| Agents and `/bug-fix` as slash commands | https://kiro.dev/docs/ide/chat/slash-commands/ |
| Steering and skills reaching a custom agent | https://kiro.dev/docs/steering/ · https://kiro.dev/docs/skills/ |
| Hooks v1 (`PreToolUse`, `command` action, exit 2, timeout) | https://kiro.dev/docs/hooks/ · https://kiro.dev/docs/hooks/types/ · https://kiro.dev/docs/hooks/actions/ · https://kiro.dev/docs/ide/whats-new-v1/hooks/ |
| Exit codes (hook exit 2) | https://kiro.dev/docs/reference/exit-codes/ |
| Workspace trust and always-ask Kiro paths | https://kiro.dev/docs/permissions/ |
| Bugfix spec (`bugfix.md`, SHALL CONTINUE TO) | https://kiro.dev/docs/specs/bugfix-specs/ |
| Specs (tasks, Run all Tasks) | https://kiro.dev/docs/specs/ |
| `#terminal` context provider | https://kiro.dev/docs/ide/chat/ |
| Checkpoints (manual edits are not captured) | https://kiro.dev/docs/checkpoints/ |

</details>

## Next

- Wrap-up: what you would change for one of your own services.
- Optional [Module 6 — Platform deployment](06-platform-deployment.md): containers and WAR deployment.
- Optional [Module 7 — Scale out](07-scale-out-cli-web.md): powers, headless CI and Kiro Web.
