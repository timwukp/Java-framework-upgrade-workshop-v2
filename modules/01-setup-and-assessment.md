<!-- runbook max-lines=450 -->
# Module 1: Setup and assessment (60 minutes)

Module 1 of 5 · [← Participant setup](../docs/participant-setup.md) · [Module 2 →](02-runway-boot27-java21.md) ·
[Day sheet](../docs/quick-reference.md) · [Troubleshooting](../docs/troubleshooting.md) ·
[Why and background](why/01-setup-and-assessment.md)

You get to know Kiro IDE 1.x, make it safe for the agent to run Maven, and assess the legacy app
before anything changes. No application code changes in this module.

## At a glance

| | |
|---|---|
| **Goal** | A safe Kiro setup, a recorded baseline (`stage-0`), reviewed steering and a written assessment |
| **Time** | 60 minutes |
| **Start** | [Participant setup](../docs/participant-setup.md) done; JDK 8 active; Kiro started with `kiro .` from that terminal in `sample-app/`; workspace trusted; a paid plan or organization seat |
| **Hooks** | `verify-after-spec-task` **on** (it fires only after spec tasks, so it stays quiet today), `jakarta-import-guard` **off** |
| **End** | Branch `workshop`, tag `stage-0`: `Stage 0: Java 8, Spring Boot 2.2.4, Tests run: 14`; two commits (steering, notes) |
| **You produce** | Supervised mode, a `mvn *` allow rule and a deploy deny rule, foundation steering, `MIGRATION-NOTES.md` |
| **Running late** | Skip the prompt in Exercise 1.3; in Exercise 1.12 send [prompts C and D as one message](why/01-setup-and-assessment.md#112-inventory-the-migration-surface); fix `tech.md` (Exercise 1.10, step 4) during the break |

**After any JDK change, quit Kiro and restart it from that terminal with `kiro .`** ([docs](https://kiro.dev/docs/getting-started/first-project/)).

### How to read the exercises

**Goal**, **Do** (steps), **Prompt** (paste into the chat), **Expect** (what you should see), **If not**
(link to the fix), **Commit**, **Why** (link to the background). **Attach first**: type `#` (or `/`),
choose the item from the menu, then paste the prompt after it. **Expected output** is what a build or
the app prints; an **Example answer** is one possible agent answer (yours will differ).

### Words you'll meet

| Word | Meaning |
|---|---|
| **Hunk** | One proposed change in a file. In Supervised mode you **Accept** or **Reject** each hunk. |
| **Steering** | Rules files in `.kiro/steering/` the agent follows: `always`, `fileMatch` (when matching files are in context) or `manual` (when you reference them). |
| **Spec** | A planned change: `requirements.md` → `design.md` → `tasks.md` under `.kiro/specs/<name>/`. From Module 2. |
| **Hook** | A command in `.kiro/hooks/*.json` that runs on an event, for example `PostTaskExec` (after each spec task). |
| **Skill** | Know-how in `.kiro/skills/<name>/SKILL.md`; the agent loads it when a request matches its description, or with `/<name>`. |
| **Power** | Skills (and optionally MCP servers) packaged for sharing and installed per user. Module 4. |
| **MCP** | Model Context Protocol: servers that give the agent extra tools. Not used in the core labs. |
| **Kiro checkpoint** | The undo marker Kiro creates per prompt (Exercise 1.4). Not a git commit. |
| **Kiro output panel** | Where Kiro writes hook logs. Unconfirmed: the docs give no menu path for it. |

## Before you start

From `sample-app/` in Kiro's terminal (``Ctrl+` ``):

`../scripts/check-env.sh` → **Expect:** no `FAIL` lines (a `WARN` for JDK 25 is fine). **If not:** fix
what the line names ([participant setup, section 9](../docs/participant-setup.md#9-am-i-ready)).

## Exercises

| # | Exercise | Min |
|---|---|---|
| 1.1 | [Open the chat and find the workflows](#11-open-the-chat-and-find-the-workflows) | 2 |
| 1.2 | [Switch to Supervised mode](#12-switch-to-supervised-mode) | 2 |
| 1.3 | [Context providers and Cmd/Ctrl+L](#13-context-providers-and-cmdctrll) | 4 |
| 1.4 | [Checkpoints and their limits](#14-checkpoints-and-their-limits) | 2 |
| 1.5 | [Confirm the workspace is trusted](#15-confirm-the-workspace-is-trusted) | 1 |
| 1.6 | [First shell command and "Always allow"](#16-first-shell-command-and-always-allow) | 4 |
| 1.7 | [What never to pre-approve](#17-what-never-to-pre-approve) | 3 |
| 1.8 | [Git baseline: branch `workshop`, tag `stage-0`](#18-git-baseline-branch-workshop-tag-stage-0) | 5 |
| 1.9 | [Inspect the shipped steering](#19-inspect-the-shipped-steering) | 5 |
| 1.10 | [Generate foundation steering and review it critically](#110-generate-foundation-steering-and-review-it-critically) | 7 |
| 1.11 | [Start a Plan session](#111-start-a-plan-session) | 1 |
| 1.12 | [Inventory the migration surface](#112-inventory-the-migration-surface) | 10 |
| 1.13 | [Why not Java 21 right now?](#113-why-not-java-21-right-now) | 2 |
| 1.14 | [Save the findings to `MIGRATION-NOTES.md`](#114-save-the-findings-to-migration-notesmd) | 5 |
| 1.15 | [The shipped hooks, reviewer and skills (look only)](#115-the-shipped-hooks-reviewer-and-skills-look-only) | 7 |

## Kiro IDE 1.x tour

### 1.1 Open the chat and find the workflows
**Goal:** know where each kind of session starts and how to switch agents.

**Do**
1. Press **Cmd+L** (macOS) or **Ctrl+L** (Linux). On **Let's build**, type (Default agent) or pick
   **Spec**, **Quick Spec**, **Bug Fix** or **Plan**.
2. Click the **agent selector** (agent name, bottom bar of the chat input). Groups: **Built-in**,
   **User** or **Global** (`~/.kiro/agents/`; label depends on your build), **Workspace**
   (`.kiro/agents/`). Switching keeps the conversation; the selector is disabled while the agent is
   executing a multi-step workflow.
3. Click the **Kiro ghost icon** in the activity bar: **Specs**, **Agent Hooks**, **Steering**,
   **MCP Servers**.

**Expect:** you found the four workflows, the agent selector and the Kiro panel. **Commit:** nothing
changed. **Why:** [the workflows and slash commands](why/01-setup-and-assessment.md#11-open-the-chat-and-find-the-workflows)

### 1.2 Switch to Supervised mode
**Goal:** review every edit before it lands.

**Do:** turn off the **Autopilot** switch in the chat, or set **Settings → Agent → Agent Autonomy**
(`kiroAgent.agentAutonomy`) to **Supervised**. Edits then arrive as hunks to **Accept**, **Reject** or
**Chat inline** (or **Accept All** / **Reject All**).

**Expect:** Settings → search "Agent Autonomy" → **Supervised**. **Commit:** IDE setting; nothing to
commit. **Why:** [Autopilot vs Supervised](why/01-setup-and-assessment.md#12-switch-to-supervised-mode)

### 1.3 Context providers and Cmd/Ctrl+L
**Goal:** give the agent exactly the context you mean. Type `#` to pick a context provider (today:
`#codebase`, `#current`, `#pom.xml`, manual steering); [all 14 providers](why/01-setup-and-assessment.md#13-context-providers-and-cmdctrll).

**Do:** in `config/SecurityConfig.java`, select the whole `configure(HttpSecurity http)` method, press
**Cmd+L** / **Ctrl+L** to add it to the chat, and send:

**Prompt**

```prompt
Explain what the selected method allows without authentication, which requests need a login, and
where CSRF protection is switched off. Then list which of its APIs are deprecated or removed in
later Spring Security versions, and mark anything you are not sure about as "unverified". Answer
only; do not change any files.
```

Then check: `grep -nE "permitAll|authenticated|ignoringAntMatchers|httpBasic" src/main/java/com/example/usermanagement/config/SecurityConfig.java`

**Expect:** `/api/public/**` open, everything else behind HTTP Basic, CSRF ignored for `/api/**`. Note
claims the code doesn't support: agents can be confidently wrong. **Commit:** answer only; **Reject**
any hunks.

### 1.4 Checkpoints and their limits
**Goal:** know what Kiro can undo, and what it can't.

**Do:** scroll up to the **checkpoint** marker of your Exercise 1.3 prompt (don't click it).

**Expect:** you can point to a checkpoint marker. **Revert** (above the chat input) undoes the agent's
latest turn; **Restore** on a marker rolls agent edits and context back to it. Neither undoes your
edits or changes by shell commands (e.g. `mvn`) or MCP tools; git does. That is why you commit before
every agent run (Exercise 1.8). **Why:** [the three undo tools](why/01-setup-and-assessment.md#14-checkpoints-and-their-limits)

## Workspace trust and permissions

### 1.5 Confirm the workspace is trusted
**Goal:** make sure `.kiro/` is loaded. An untrusted workspace loads no agents, steering, MCP, skills
or workflows, and asks before **every** shell command.

**Do:** check that
1. Kiro panel → **Steering** lists `migration-standards`, `migration-playbook`, `pom-rules`, `test-rules`;
2. agent selector → **Workspace** lists `migration-reviewer`;
3. typing `/` lists `migration-playbook`, `migration-reviewer` and the two skills
   `jakarta-namespace-migration` and `spring-security-lambda-dsl`.

**Expect:** all show up. **If not:** [T-K01](../docs/troubleshooting.md#t-k01-steering-files-custom-agents-or-skills-dont-appear)

### 1.6 First shell command and "Always allow"
**Goal:** let the agent run Maven without asking, in this workspace only, and confirm its JDK.

**Do**
1. Start a new session (**+** in the chat panel, or **Cmd+T** / **Ctrl+T**); skip the workflow picker
   (you want the Default agent) and send prompt 1.
2. At the approval prompt choose **Always allow**, pattern `mvn *` (widen Kiro's suggestion if it's
   narrower, such as `mvn -v`), **Apply to: This workspace**. If **Always allow** isn't offered,
   choose **Allow** ([T-K03](../docs/troubleshooting.md#t-k03-no-always-allow-in-the-approval-prompt)).
3. Send prompt 2. It should run **without** a prompt.
4. Check that the rule is outside the repository: `grep -rn "mvn" ~/.kiro/workspace-roots/; git status`

**Prompt 1**

```prompt
Run `mvn -v` in the workspace root and tell me the Maven version and the Java version it reports. Do
not run anything else.
```

**Prompt 2**

```prompt
Run `mvn -B -q clean compile` in the workspace root and tell me whether it succeeded. Do not change
any files.
```

**Expect:** answer 1 reports **Java version 1.8.0_…**; prompt 2 ran without approval (`-q` prints
nothing on success); `mvn *` is in a `permissions.yaml`, and `git status` shows nothing new.\
**If not:** Java 21 or 25 → [T-A02](../docs/troubleshooting.md#t-a02-the-agents-or-the-hooks-java-is-not-your-terminals) ·
still asked every time → [T-K02](../docs/troubleshooting.md#t-k02-kiro-asks-before-every-mvn-command) ·
two prompts for one command → [T-K04](../docs/troubleshooting.md#t-k04-one-command-produces-two-approval-prompts)\
**Why:** [the approval prompt](why/01-setup-and-assessment.md#16-first-shell-command-and-always-allow)

### 1.7 What never to pre-approve
**Goal:** close the gap `mvn *` leaves: it also matches `mvn deploy`.

**Do:** add this rule to `~/.kiro/settings/permissions.yaml` yourself (create the file or use its
`rules:` key); the agent may never write there.

```yaml
rules:
  - capability: shell
    match: ["mvn *deploy*"]
    effect: deny
```

`deny` beats `allow` in every scope, in all projects. Leave `git push`, publish and release prompting;
never **Always allow** them.

**Expect:** `cat ~/.kiro/settings/permissions.yaml` shows the `mvn *deploy*` deny rule; the repository
is unchanged. **Why:** [why the workshop can't ship this rule for you](why/01-setup-and-assessment.md#17-what-never-to-pre-approve)

### 1.8 Git baseline: branch `workshop`, tag `stage-0`
**Goal:** a known-good stage 0 with the test count recorded.

**Do:** run Maven yourself (no credits):

```bash
git status
git switch -c workshop
mvn -B clean verify | tail -n 30
```

Read **Tests run** in your output: expect **14**. Then tag it, and see what the shortcut for this
check prints (you use it at the start and end of every module from now on):

```bash
git tag -a stage-0 -m "Stage 0: Java 8, Spring Boot 2.2.4, Tests run: 14"
git show stage-0 --no-patch
../scripts/verify-stage.sh 0
```

**For the rest of the day, commit before every agent run** (unless `git status` is clean):
`git add -A && git commit -m "checkpoint: before <what the agent is about to do>"`

**Expect:** `git branch --show-current` prints `workshop`, `git tag -l "stage-*"` prints `stage-0`, and
the script ends with `PASS: stage 0, …, Tests run: 14, …`. **Source Control** (**Ctrl+Shift+G**) shows
the repository.\
**If not:** count isn't 14 → [T-A14](../docs/troubleshooting.md#t-a14-the-baseline-test-count-isnt-14) ·
`git switch` unknown → [T-A13](../docs/troubleshooting.md#t-a13-git-switch-is-not-a-git-command) ·
no repository in Source Control → [T-K06](../docs/troubleshooting.md#t-k06-git-diff-is-empty-or-source-control-shows-no-repository)\
**Why:** [why commit before every agent run](why/01-setup-and-assessment.md#18-git-baseline-branch-workshop-tag-stage-0)

## Steering

Steering files (`.kiro/steering/`) tell the agent how to work here. Their front matter (first in the
file) sets when each loads: `always` (default), `fileMatch`, `manual` or `auto`
([inclusion modes](why/01-setup-and-assessment.md#steering)).

### 1.9 Inspect the shipped steering
**Goal:** know which rules the agent follows and when: `migration-standards` (`always`), `pom-rules`
and `test-rules` (`fileMatch`), `migration-playbook` (`manual`).

**Do**
1. Open each file (Kiro panel → **Steering**); look at the front matter.
2. Open `pom.xml`. **Attach first:** `#current`. Send prompt 1 (`pom-rules` should load).
3. **Attach first:** `#migration-playbook` (or type `/migration-playbook`). Send prompt 2.
4. Check: `cat .kiro/steering/pom-rules.md` and
   `sed -n '/## Stage 1/,/## Stage 2/p' .kiro/steering/migration-playbook.md`

**Prompt 1**

```prompt
Which workspace steering rules apply when you change this file? Quote the rule about dependency
versions. Answer only; do not change any files.
```

**Prompt 2**

```prompt
For stage 1, list each trap and the symptom I would see if it were missed. Answer only.
```

**Expect:** answer 1 quotes `pom-rules` ("Remove `<version>` tags from dependencies the parent
manages"); answer 2 lists validation silently ignored, fewer or zero tests run, circular references,
the Lombok pin. **If not:** [T-K07](../docs/troubleshooting.md#t-k07-the-pomxml-question-doesnt-mention-pom-rules)\
**Why:** [what each file enforces, and why steering can be wrong too](why/01-setup-and-assessment.md#19-inspect-the-shipped-steering)

### 1.10 Generate foundation steering and review it critically
**Goal:** add `product.md`, `tech.md` and `structure.md`, which load in **every** interaction, without
steering the agent wrong.

**Do**
1. Check that `git status` is clean.
2. Kiro panel → **Steering** → **Generate Steering Docs** (or **+** → **Foundation steering files**).
3. Review the three files: versions match `pom.xml` (Java `1.8`, Boot `2.2.4.RELEASE`); legacy
   patterns are labelled "current state (stage 0)", not conventions; no invented facts; no other target
   versions; no secrets; short ([the full checklist](why/01-setup-and-assessment.md#110-generate-foundation-steering-and-review-it-critically)).
4. Fix it by hand or with the prompt below (accept only `tech.md` hunks). **Attach first:** `#pom.xml`.
5. Check: `ls .kiro/steering`, `head -n 5 .kiro/steering/tech.md` and
   `grep -nE "2\.2\.4|1\.8" .kiro/steering/tech.md`

**Prompt**

```prompt
Edit .kiro/steering/tech.md only. Label the stack section "Current state (stage 0)" and use the
exact versions from pom.xml. Add one line saying that the legacy patterns in this code (field
injection, java.util.Date, JUnit 4 runners, WebSecurityConfigurerAdapter, javax.* imports) are
migration targets, not conventions to copy. Add one line that points to migration-standards.md for
the staged target versions. Remove anything that no file in this repository supports.
```

**Expect:** seven files; any front matter on line 1; versions matching `pom.xml`.\
**If not:** [T-K08](../docs/troubleshooting.md#t-k08-no-generate-steering-docs-button) ·
[T-K09](../docs/troubleshooting.md#t-k09-generated-techmd-presents-legacy-patterns-as-conventions)\
**Commit:** `git add .kiro/steering && git commit -m "Add reviewed foundation steering (product, tech, structure)"`

## Assessment with the Plan workflow

**Goal:** a read-only inventory of the migration surface, saved to `MIGRATION-NOTES.md`.

### 1.11 Start a Plan session
**Do**
1. Start a new session (**+** or **Cmd+T** / **Ctrl+T**) and choose **Plan**. Plan only reads and
   searches: no file writes, commands or MCP tools, and it saves nothing.
2. Answer clarifying questions as `1=a, 2=b`, or skip. A good answer: "Assessment only. The staged
   targets are in migration-standards."

**Watch out:** **do not approve a plan in this module.** Per the docs, "Once you approve the plan,
execution begins automatically": the agent starts implementing
([T-K10](../docs/troubleshooting.md#t-k10-plan-started-editing-files)).\
**Why:** [what Plan can and can't do](why/01-setup-and-assessment.md#111-start-a-plan-session)

### 1.12 Inventory the migration surface
**Goal:** four answers, each checked with `grep`: `grep` is the ground truth. Send each prompt in the
Plan session, then run its check yourself. **Attach first** for A, B and C: `#codebase`; for D:
`#pom.xml` (type `#` and pick `pom.xml`).

| Prompt | Check | Expect |
|---|---|---|
| A: `javax.*` imports | `grep -rn "^import javax\." src` and `grep -n "javax" pom.xml` | `entity/User.java`, `controller/UserController.java`, `web/RequestIdFilter.java`; three `javax` artifacts (servlet, persistence, validation) |
| B: Spring Security | `grep -nE "extends\|antMatchers\|authorizeRequests\|csrf\|and\(\)\|inMemoryAuthentication" src/main/java/com/example/usermanagement/config/SecurityConfig.java` | `WebSecurityConfigurerAdapter`, `antMatchers`, `authorizeRequests`, `ignoringAntMatchers`, `and()` chaining, in-memory users (passwords from environment variables or generated) |
| C: tests | `grep -rnE "@RunWith\|@WebMvcTest\|@MockBean\|import org.junit" src/test` and `grep -rc "@Test" src/test/java` | JUnit 4, `SpringRunner`, `MockitoJUnitRunner`, `@WebMvcTest`, `@MockBean`; `@Test` counts 9 + 5 = 14. Expected answer: Spring Boot 2.4 removed the JUnit Vintage engine from `spring-boot-starter-test`, so JUnit 4 tests can silently stop running. |
| D: pinned versions | `grep -nE "<version>\|<java.version>" pom.xml` and `mvn -B dependency:tree -Dincludes=org.projectlombok,javax.persistence,javax.validation` | parent `2.2.4.RELEASE`, `java.version` `1.8`, pins on `javax.persistence-api`, `validation-api` and `lombok` `1.18.10` (which can't run on JDK 16+) |

**Prompt A**

```prompt
This is an assessment only; do not propose code changes. List every import from javax.* in
src/main/java and src/test/java, grouped by package (javax.persistence, javax.validation,
javax.servlet, anything else). For each group, say whether it moves to jakarta.* in Spring Boot 3 or
stays because it is a JDK package. Give file paths. Also list the javax.* artifacts declared in
pom.xml.
```

**Prompt B**

```prompt
Describe the Spring Security setup: the configuration class and its base class, the request matchers
and what each one permits, CSRF rules, the authentication mechanism, and how users and passwords are
created. Then list each API used here that is deprecated or removed in Spring Security 6 or 7. Mark
anything you are not sure about as "unverified".
```

**Prompt C**

```prompt
Which test frameworks, runners and test slices do the tests use? For each test class give its runner
annotation and the number of @Test methods. Which Spring Boot upgrade would make these tests stop
running without failing the build, and why? Mark anything you are not sure about as "unverified".
```

**Prompt D**

```prompt
List every explicit <version> and every property that pins a version. For each, say whether the
Spring Boot parent already manages that artifact, and what could break when the parent is upgraded
while the pin stays. Mark anything you are not sure about as "unverified".
```

**If not:** the answers disagree with `grep` → [T-K13](../docs/troubleshooting.md#t-k13-kiros-inventory-disagrees-with-your-grep)\
**Commit:** read-only so far. **Why:** [where the answers come from](why/01-setup-and-assessment.md#112-inventory-the-migration-surface)

### 1.13 Why not Java 21 right now?
**Prompt**

```prompt
Why can't this project move to Java 21 while it is still on Spring Boot 2.2.4? Name every blocker
you can find in this codebase and its dependencies, and for each one name the official source I
should check to confirm it. Then explain why the staged path in migration-standards upgrades to
Spring Boot 2.7.18 before changing the JDK.
```

**Expect:** the answer covers at least:
- **Spring Boot 2.2.4 is documented as compatible up to Java 13; the last 2.2 patch (2.2.13) up to
  Java 15.**
- **Lombok 1.18.10** fails on JDK 16+.
- **Spring Boot 2.7.18** "requires Java 8 and is compatible up to and including Java 21": upgrade the
  framework on JDK 8 first, then switch the JDK (Module 2).

If Kiro states another range, ask for its source. **Why:** [sources for the Java ranges](why/01-setup-and-assessment.md#113-why-not-java-21-right-now)

### 1.14 Save the findings to `MIGRATION-NOTES.md`
**Goal:** keep the assessment. Plan saves nothing, so switch the **same** session to Default (the
history comes along).

**Do**
1. Check that `git status` is clean.
2. When the agent is idle, select **Default** in the agent selector. Don't approve any plan.
3. Send the prompt; **Accept** the `MIGRATION-NOTES.md` hunk, **Reject** anything else.
4. Check: `git status --short` and `grep -nE "Tests run|unverified" MIGRATION-NOTES.md`

**Prompt**

```prompt
Create MIGRATION-NOTES.md in the workspace root from the assessment in this conversation. Use these
sections: Baseline (Java, Spring Boot and Spring Framework versions from pom.xml; Tests run: 14, as
recorded in the stage-0 tag), javax.* inventory, Spring Security, Tests, Pinned versions, Why not
Java 21 yet, Staged path (from migration-standards), Open questions. Keep each item to one line,
keep every "unverified" mark, and add file paths where you have them. Do not change any other file.
```

**Expect:** only `?? MIGRATION-NOTES.md`, and `Tests run: 14`. Fix anything your checks contradicted.\
**If not:** [T-K11](../docs/troubleshooting.md#t-k11-plan-says-it-cant-create-migration-notesmd) ·
[T-K12](../docs/troubleshooting.md#t-k12-the-agent-selector-is-greyed-out)\
**Commit:** `git add MIGRATION-NOTES.md && git commit -m "Module 1: assessment notes"`\
**Why:** [an example result](why/01-setup-and-assessment.md#114-save-the-findings-to-migration-notesmd)

### 1.15 The shipped hooks, reviewer and skills (look only)
**Goal:** know what runs automatically later. Don't run, enable or edit anything.

**Do**
1. Open Kiro panel → **Agent Hooks**, then read the two definitions:
   `cat .kiro/hooks/verify-after-spec-task.json` and `grep -nE '"trigger"|"enabled"' .kiro/hooks/*.json`
2. Read the reviewer: `sed -n '1,20p' .kiro/agents/migration-reviewer.md`

| Hook | Trigger | Action | State |
|---|---|---|---|
| `verify-after-spec-task` | `PostTaskExec` (after each spec task) | One `mvn -B clean verify`; reports `Tests run` and `BUILD SUCCESS`, or the last 80 lines on failure | **On** |
| `jakarta-import-guard` | `PostFileSave`, `\.java$` | Reports Jakarta EE APIs still imported from `javax.*` in a file the agent saved | **Off** until Module 3 |

**Expect:** you can say three things for later.
- The verify hook passes even if fewer tests ran (green is not done; read the count). Wait for it
  (Kiro output panel) before running Maven yourself: builds share `target/`.
- `migration-reviewer` has `tools: ["read", "shell"]`: no `write` tool, but a shell, so **run
  `git status` after every review**. Only its Maven build and read-only git run unprompted.
- The skills `jakarta-namespace-migration` and `spring-security-lambda-dsl` (Module 3) activate when a
  request matches their description, or via `/<skill name>`. Don't select them now.

**Why:** [why the hooks are built this way](why/01-setup-and-assessment.md#115-the-shipped-hooks-reviewer-and-skills-look-only)

## Finish: check the module's work

`git status --short && git log --oneline -3 && git tag -n1 -l "stage-*"`

**Expect:** a clean tree; two commits after `stage-0` (steering, notes); `stage-0` with `Tests run: 14`.

## Check yourself

- [ ] **Supervised** mode is on; you can start each workflow, switch agents and use `#` providers.
- [ ] You know Revert and Restore miss shell and MCP changes; git doesn't.
- [ ] `mvn *` is allowed for **this workspace**, `mvn *deploy*` is denied, and the agent's `mvn -v`
  reports Java 1.8.
- [ ] Branch `workshop`; tag `stage-0` records `Tests run: 14`.
- [ ] Foundation steering and `MIGRATION-NOTES.md` are reviewed and committed.
- [ ] You can explain each hook, the reviewer, and why the guard is off.

**Something else?** [Setup and JDK](../docs/troubleshooting.md#a-setup-and-jdk) · [Kiro](../docs/troubleshooting.md#k-kiro) · [Recovery](../docs/troubleshooting.md#x-recovery)

## Next

[Module 2: Runway, Spring Boot 2.7 and Java 21 →](02-runway-boot27-java21.md): a Feature spec, the
verify hook after every task, and the first two silent traps.
