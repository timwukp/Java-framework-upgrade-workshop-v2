# Module 5: why and background

[← Back to the Module 5 runbook](../05-quality-gates.md)

The runbook keeps only what you do and what you should see. This page holds the reasons, the reference
files, the optional lab and the evidence. Headings match the runbook's exercises.

## 5.1 Review the migration with the `migration-reviewer` agent

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
Tests run: 14, Failures: 0, Errors: 0, Skipped: 0 (stage-0 sources: 14 @Test methods)
Verdict: ready to commit
```

Docs: [Custom agents](https://kiro.dev/docs/custom-agents/) ·
[Creating agents](https://kiro.dev/docs/custom-agents/creating/) ·
[Configuration reference](https://kiro.dev/docs/custom-agents/configuration-reference/) ·
[Steering](https://kiro.dev/docs/steering/) · [Skills](https://kiro.dev/docs/skills/) ·
[Permissions — workspace trust](https://kiro.dev/docs/permissions/)

## 5.2 Delegate one review to a sub-agent

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

## 5.3 A guard hook in plain English: block deploy goals and `git push`

The reference, `solutions/kiro-reference/hooks/block-deploy-and-push.json`:

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

Verified in the 2026-10-10 dry run (Amazon Linux 2023, the reference command run as a plain shell
command, outside Kiro): exit 2 for `mvn clean deploy`, `mvn wildfly:deploy`, `git push origin main`,
`git -C sample-app push` and `echo mvn deploy`; exit 0 for `mvn -B clean verify`, `mkdir -p deploy/zos`
and `cat .kiro/steering/deploy-container.md`. That proves the pattern, not how Kiro runs the hook.

> Unconfirmed: the docs don't say which shell Kiro uses to run hook commands. `sh -c` in the terminal test
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

## 5.4 Prove stage 3 and tag `stage-3-final`

- `*.log` files are git-ignored in this repository, so `build.log` stays untracked.
- Module 1 recorded the baseline in the `stage-0` tag message. The runtime number is the authority;
  the static count of `@Test` methods is a second check that doesn't depend on notes. At stage 0 the
  sample app's test sources contain 14 `@Test` methods.
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

## Extra 5.A: the Bugfix lab yourself

About 20–30 minutes of agent time, on its own branch, after Exercise 5.4.

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

   `invalidUserIsRejectedByBeanValidation` (expects 400) and `validUserIsCreated` (expects 201) fail
   with 403, because a POST now needs a CSRF token. The other 12 tests pass.

5. Start a Bugfix spec. On the **Let's build** screen of a new session, choose **Bug Fix**. In an
   existing session, pick **Bug Fix** from the agent selector, or use `/bug-fix`.

**Ask Kiro**

```text
#terminal Authenticated API calls broke after a security config cleanup: mvn -B clean verify fails in
invalidUserIsRejectedByBeanValidation and validUserIsCreated, which now get 403 Forbidden instead of
400 Bad Request and 201 Created.
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
- `Failures: 0, Errors: 0`, and a count of at least 14. It may be higher if the regression-test
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
`stage-3-final` points at the commit you verified in Exercise 5.4 either way.

**Lab troubleshooting**

| Symptom | Likely cause | Fix |
|---|---|---|
| No **Bug Fix** option on the Let's build screen | The entry point differs between builds | Use the agent selector → **Bug Fix**, or `/bug-fix` |
| The fix adds `.with(csrf())` to the test or disables CSRF | A green build without the original behavior | Reject the task; point to the Expected/Unchanged requirements; restore `/api/**` |
| Spec tasks no longer report a `Tests run` line after the lab | `verify-after-spec-task` is still paused | Re-enable it in the Agent Hooks panel |
| `mvn -B clean verify` stays green after the regression | Your web test doesn't load `SecurityConfig` | Check for `@Import(SecurityConfig.class)`; or confirm the 403 with `curl` against `mvn spring-boot:run` and describe that symptom |

Docs: [Bugfix specs](https://kiro.dev/docs/specs/bugfix-specs/) · [Specs](https://kiro.dev/docs/specs/) ·
[Checkpoints](https://kiro.dev/docs/checkpoints/)


### Alternative regression: remove `spring-boot-starter-validation`

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
  `<version>` line, and the build passes with at least 14 tests.


## Evidence

From the 2026-10-10 dry run (Amazon Linux 2023): the reference hook command, run as a plain shell
command outside Kiro, exits 2 for `mvn clean deploy`, `mvn wildfly:deploy`, `git push origin main`,
`git -C sample-app push` and `echo mvn deploy`, and 0 for `mvn -B clean verify`, `mkdir -p deploy/zos`
and `cat .kiro/steering/deploy-container.md`. That proves the pattern, not how Kiro runs the hook. See
the [verification log](../../docs/verification-log.md).

Unconfirmed in a Kiro build: which shell Kiro uses for hook commands; the field names of the shell
tool's `PreToolUse` payload; where the agent picker sits in your build.

## Docs

Custom agents, sub-agents, `resources`, hooks v1, workspace trust, Bugfix specs, `#terminal`,
checkpoints.

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
