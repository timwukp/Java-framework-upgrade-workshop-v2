<!-- runbook max-lines=260 -->
# Module 5: Quality gates (30 minutes)

Module 5 of 5 · [← Module 4](04-spring-boot-4-java25.md) · [Module 6 (optional) →](06-platform-deployment.md) ·
[Day sheet](../docs/quick-reference.md) · [Troubleshooting](../docs/troubleshooting.md) ·
[Why and background](why/05-quality-gates.md)

Stage 3 (Java 25, Spring Boot 4.1) passes four quality gates before you call the migration done.

## At a glance

| | |
|---|---|
| **Goal** | A reviewed, guarded and verified stage 3, tagged `stage-3-final` |
| **Time** | 30 minutes: 8 review, 7 guard hook, 5 Bugfix demo, 10 final verification |
| **Start** | Tag `stage-3` on branch `workshop`; the `stage-0` tag records `Tests run: 14`; JDK 25 active; workspace trusted. Behind? `../scripts/reset-to-stage.sh 3` |
| **Hooks** | `verify-after-spec-task` **on**, `jakarta-import-guard` **on**; Exercise 5.3 adds `block-deploy-and-push` |
| **End** | Tag `stage-3-final`: `Stage 3 verified: Java 25, Spring Boot 4.1.1, Tests run: 14, reviewed, secret scan clean` |
| **You produce** | Two reviews, a committed `PreToolUse` hook, the `stage-3-final` tag |
| **Running late** | Do Exercises 5.1 and 5.4 only; do 5.2, 5.3 and Extra 5.A afterwards |

## Before you start

`../scripts/verify-stage.sh 3` and `git tag -l "stage-*"`\
**Expect:** `PASS: stage 3, Java 25, Spring Boot 4.1.1, Tests run: 14, …`; tags `stage-0` to `stage-3`; a
clean `git status --short`. **If not:** reset with `../scripts/reset-to-stage.sh 3`.

## Exercises

| # | Exercise | Min |
|---|---|---|
| 5.1 | [Review the migration with the `migration-reviewer` agent](#51-review-the-migration-with-the-migration-reviewer-agent) | 5 |
| 5.2 | [Delegate one review to a sub-agent](#52-delegate-one-review-to-a-sub-agent) | 3 |
| 5.3 | [A guard hook in plain English: block deploy goals and `git push`](#53-a-guard-hook-in-plain-english-block-deploy-goals-and-git-push) | 7 |
| | [Demo: a Bugfix spec on a deliberate regression](#demo-a-bugfix-spec-on-a-deliberate-regression) | 5 |
| 5.4 | [Prove stage 3 and tag `stage-3-final`](#54-prove-stage-3-and-tag-stage-3-final) | 10 |
| | [Extra 5.A: the Bugfix lab yourself](#extra-5a-the-bugfix-lab-yourself) (optional, 20–30) | — |

## Review

### 5.1 Review the migration with the `migration-reviewer` agent
**Goal:** an independent review of the code and build changes since stage 0, against the workspace
standards.

**Do**
1. Run `cat .kiro/agents/migration-reviewer.md`. The agent has no `write` tool and is told not to modify
   files. Only `mvn -B verify`, `mvn -v` and read-only git run unprompted; plugin goals, deploy, push,
   commit, reset and `rm` are denied. It has `shell`, so check `git status` after every review.
2. Start a new chat session. Click the agent name (for example **Default**) in the chat input bar and
   choose **migration-reviewer**.
3. Send the prompt. Don't run Maven yourself until the review finishes.

**Prompt**

```prompt
Review the migration from the stage-0 tag to the current commit, code and build only:
git diff stage-0..HEAD -- pom.xml src
Run mvn -B verify once and report the Tests run / Failures / Errors / Skipped totals.
Compare the number of @Test methods with the test sources at stage-0 (git show and git diff are
allowed).
Check it against the steering files and the jakarta-namespace-migration skill.
Use the table format from your instructions and finish with the one-line verdict.
```

**Expect:** it runs `mvn -B verify` without asking and returns a findings table, `Tests run: 14…` and a
verdict ([example](why/05-quality-gates.md#51-review-the-migration-with-the-migration-reviewer-agent));
`git status --short` prints nothing.\
**If not:** [T-K01](../docs/troubleshooting.md#t-k01-steering-files-custom-agents-or-skills-dont-appear) ·
[T-K36](../docs/troubleshooting.md#t-k36-git-status-shows-changes-after-a-review) ·
[T-K37](../docs/troubleshooting.md#t-k37-the-reviewer-ignores-the-migration-standards) ·
[T-K38](../docs/troubleshooting.md#t-k38-the-reviewer-asks-before-git-grep-or-mvn--b-clean-verify)\
**Commit:** nothing. Keep the `Tests run` line for Exercise 5.2. Fix any **blocker** with the Default
agent before Exercise 5.4, then `git add -A && git commit -m "Module 5: fix reviewer blockers"`.

### 5.2 Delegate one review to a sub-agent
**Goal:** the Default agent delegates a tests-only review to a `migration-reviewer` sub-agent, which
runs in its own context.

**Do:** switch the selector back to **Default** and name the agent explicitly (more predictable than
letting Kiro pick one). Paste your line from Exercise 5.1 in place of the placeholder:

```prompt
Use the migration-reviewer agent as a sub-agent to review only the tests: git diff stage-0..HEAD --
src/test
Another reviewer already ran the build, so the sub-agent must not run Maven. Use this result:
<paste the Tests run line from Exercise 5.1>
Then show me its findings table and its verdict.
```

**Expect:** a second findings table; `git status --short` prints nothing. Trust findings both reviews
raise first. Only one reviewer runs Maven: two builds in one `target/` fail randomly.\
**If not:** [T-K39](../docs/troubleshooting.md#t-k39-use-the-migration-reviewer-agent-fails) ·
[T-K40](../docs/troubleshooting.md#t-k40-delegation-runs-in-the-background)\
**Why:** [sub-agents, and two reviewers in parallel](why/05-quality-gates.md#52-delegate-one-review-to-a-sub-agent)

## Guard

### 5.3 A guard hook in plain English: block deploy goals and `git push`
**Goal:** no agent in this workspace runs a deploy goal or `git push`, enforced by a hook committed with
the code.

**Do**
1. In the Kiro panel, under **Agent Hooks**, click **+** and select **Ask Kiro to create a hook**. Send:

   ```prompt
   Create a PreToolUse hook block-deploy-and-push for the shell tools (matcher "shell"): a command
   action (not an agent prompt, so no credits), timeout 10 seconds, v1 format, in
   .kiro/hooks/block-deploy-and-push.json.
   It reads the tool-call JSON on stdin and blocks, case-insensitive, only a mvn/gradle/gradlew
   deploy
   goal (mvn deploy, mvn clean deploy, mvn wildfly:deploy) and git push (also git -C dir push), not
   paths like deploy/zos. To block, print "Blocked by workspace policy: deploy and git push are run
   by
   humans, not the agent." to stderr and exit 2. Otherwise exit 0 silently.
   ```

2. Approve the file write (writes to `.kiro/hooks/` always prompt, even in Autopilot).
3. Compare with the reference:
   `diff .kiro/hooks/block-deploy-and-push.json ../solutions/kiro-reference/hooks/block-deploy-and-push.json`.
   Wording and layout may differ; the tests below decide. **Fast path** (or if a test fails): copy the
   reference: `cp ../solutions/kiro-reference/hooks/block-deploy-and-push.json .kiro/hooks/`
4. Test it in the terminal with two fake payloads:

   ```bash
   HOOK_CMD=$(python3 -c "import json; print(json.load(open('.kiro/hooks/block-deploy-and-push.json'))['hooks'][0]['action']['command'])")
   echo '{"tool_name":"shell","tool_input":{"command":"git push origin workshop"}}' | sh -c "$HOOK_CMD"; echo "exit=$?"
   echo '{"tool_name":"shell","tool_input":{"command":"mkdir -p deploy/zos"}}' | sh -c "$HOOK_CMD"; echo "exit=$?"
   ```

5. Test it in Kiro (Default agent) with a harmless command. If Kiro asks to approve the `echo`, choose
   **Allow** (not Always allow). Then check that `Run mvn -B -q validate and tell me the exit code.`
   still works.

   ```prompt
   Run exactly this shell command and tell me what happened: echo mvn deploy
   ```

**Expect:** the terminal test prints the "Blocked by workspace policy" message and `exit=2`, then only
`exit=0`. In Kiro, the hook blocks the `echo` and the agent quotes the message (else see the hook log
in the Kiro output panel); `mvn -B -q validate` still runs.\
**If not:** [T-K41](../docs/troubleshooting.md#t-k41-the-module-5-hook-never-fires) ·
[T-K42](../docs/troubleshooting.md#t-k42-the-module-5-hook-doesnt-block-or-blocks-too-much) ·
[T-K44](../docs/troubleshooting.md#t-k44-kiro-asks-you-to-approve-echo-mvn-deploy)\
**Why:** [the reference file, what the pattern matches, why exit 2, and its limits](why/05-quality-gates.md#53-a-guard-hook-in-plain-english-block-deploy-goals-and-git-push)\
**Commit:** `git add .kiro/hooks/block-deploy-and-push.json && git commit -m "Module 5: PreToolUse hook blocks deploy goals and git push"`

## Demo: a Bugfix spec on a deliberate regression

> **Instructor demo (5 minutes).** A regression gets a **Bugfix spec**: `bugfix.md` lists **Current**,
> **Expected** (SHALL) and **Unchanged Behavior** (SHALL CONTINUE TO, the regression requirements). On a
> throwaway branch the CSRF exemption in `SecurityConfig.java` is narrowed from `/api/**` to
> `/api/public/**`, so the two POST web tests get 403. With `verify-after-spec-task` paused, a Bug Fix
> spec lists the unchanged behavior and the root cause; the right fix restores `/api/**` instead of
> editing the test or switching CSRF off. Nothing changes in your workspace. **Self-paced:** do
> [Extra 5.A](#extra-5a-the-bugfix-lab-yourself) after Exercise 5.4.

## Verify and tag

### 5.4 Prove stage 3 and tag `stage-3-final`
**Goal:** repeatable proof that stage 3 builds on JDK 25, keeps its 14 tests, and holds no secrets.

**Do**
1. Check in the Kiro output panel that no agent or hook build is running, then:
   `../scripts/verify-stage.sh 3`
2. Compare with stage 0 (the runtime count is the authority; the static `@Test` count is a second
   check that doesn't depend on notes):

   ```bash
   git show stage-0 --no-patch
   git grep -c '@Test' stage-0 -- src/test | awk -F: '{s+=$NF} END {print "stage-0 @Test methods:", s}'
   git grep -c '@Test' HEAD -- src/test | awk -F: '{s+=$NF} END {print "HEAD    @Test methods:", s}'
   ```

3. Scan the code and build files for secrets:

   ```bash
   git grep -n -I -i -E '(password|passwd|secret|api[_-]?key|token)[[:space:]]*[=:]' HEAD -- pom.xml src
   git diff stage-0..HEAD -- pom.xml src | grep -n -i -E '^\+.*(password|passwd|secret|api[_-]?key|token)'
   git ls-files | grep -E '(^|/)\.env$|\.log$'
   ```

4. Tag it (the hook only stops the agent; you decide when to push):

   ```bash
   git status --short
   git tag -a stage-3-final -m "Stage 3 verified: Java 25, Spring Boot 4.1.1, Tests run: 14, reviewed, secret scan clean"
   git tag --list 'stage-*'
   ```

**Expect:** step 1 prints `PASS: stage 3, Java 25, …, Tests run: 14, Failures: 0, Errors: 0, Skipped: 0,
…`; step 2 shows `Tests run: 14` in the tag message and 14 `@Test` methods at both revisions; step 3
shows only placeholders such as `${DB_PASSWORD:}`, added lines that handle passwords in code
(`PasswordEncoder`, `.password(…)`), and nothing from the last command; tag `stage-3-final` exists and
`git status --short` prints nothing. A number other than 14: find out why before you tag.\
**If not:** [T-B02](../docs/troubleshooting.md#t-b02-tests-run-is-lower-than-14) ·
[T-B23](../docs/troubleshooting.md#t-b23-the-secret-scan-finds-a-literal-password) ·
[T-X03](../docs/troubleshooting.md#t-x03-git-grep--stage-0-or-another-tag-says-bad-revision)\
**Why:** [more on the test count and the secret scan](why/05-quality-gates.md#54-prove-stage-3-and-tag-stage-3-final)

## Extras (optional, outside the core time)

### Extra 5.A: the Bugfix lab yourself
Break the CSRF exemption on a throwaway branch (`m5-bugfix-lab`), then fix it with a Bugfix spec and
watch the "SHALL CONTINUE TO" requirements stop a fix that turns the build green but changes behavior.
About 20–30 minutes of agent time; `stage-3-final` never depends on it. The steps, prompt, an example
`bugfix.md` and an alternative regression are on the
[why page](why/05-quality-gates.md#extra-5a-the-bugfix-lab-yourself).

## Check yourself

- [ ] The reviewer and a tests-only sub-agent reviewed the migration; `git status` stayed clean.
- [ ] `block-deploy-and-push.json` is committed and passed the terminal and Kiro tests.
- [ ] You can name the three sections of `bugfix.md`.
- [ ] `../scripts/verify-stage.sh 3` passes on JDK 25 with 14 tests; the secret scan found only
  placeholders.
- [ ] Tag `stage-3-final` created; both workspace hooks are on.

**Something else?** [Kiro](../docs/troubleshooting.md#k-kiro) · [Build and tests](../docs/troubleshooting.md#b-build-and-tests) · [Recovery](../docs/troubleshooting.md#x-recovery)

## Next

You finished the core day. Before you leave:
- Note what you would change for one of your own services, starting from the
  [migration cheat sheet](../docs/migration-cheat-sheet.md) and the shipped `.kiro/` assets
  (steering, hooks, the reviewer agent, skills, and the reference copies in `solutions/kiro-reference/`).
- Optional: [Module 6, platform deployment →](06-platform-deployment.md) (containers, WAR on JBoss EAP /
  WildFly and WebSphere / Open Liberty, z/OS) and [Module 7, scale out →](07-scale-out-cli-web.md)
  (sharing a power, headless CI, Kiro Web, Workflows).
- After the workshop, set your usual default JDK again
  ([Change the JDK for Kiro](../docs/participant-setup.md#change-the-jdk-for-kiro-modules-2-and-4-and-after-a-reset)).
