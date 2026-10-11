# Module 1: Setup and assessment (60 minutes)

You get to know Kiro IDE 1.x, make it safe for the agent to run Maven, and assess the legacy app
before anything changes. No application code changes in this module.

## What you'll do

- Tour Kiro IDE 1.x; switch to Supervised mode.
- Allow `mvn *` for **this workspace only**; deny deploys.
- Create branch `workshop` and tag `stage-0`.
- Review shipped and generated steering.
- Assess with **Plan**; save `MIGRATION-NOTES.md`.
- Inspect the shipped hooks and reviewer.

## Prerequisites

- [Participant setup](../docs/participant-setup.md) is done on **macOS or Linux** (Windows: use a
  Linux VM or cloud desktop; WSL2 is untested).
- JDK 8 is active; `mvn -B clean verify` passed with **Tests run: 14** (9 service + 5 web). Always
  read your own number.
- You started Kiro with `kiro .` from that terminal in `sample-app/` and trusted the workspace.
  **After any JDK change, quit Kiro and restart it from that terminal with `kiro .`**
  ([docs](https://kiro.dev/docs/getting-started/first-project/)).
- A paid Kiro plan or organization seat (prompts use credits).

**Hook state:** `verify-after-spec-task` **on** (fires only after spec tasks, so quiet today);
`jakarta-import-guard` **off**.

Run commands from `sample-app/` in Kiro's terminal (``Ctrl+` ``).

## Time box

| Part | Topic | Minutes |
|---|---|---|
| 1 | Kiro IDE 1.x tour | 10 |
| 2 | Workspace trust and permissions | 8 |
| 3 | Git baseline | 5 |
| 4 | Steering | 12 |
| 5 | Assessment with the Plan workflow | 18 |
| 6 | Shipped hooks and reviewer agent (look only) | 7 |
| | **Total** | **60** |

Instructor demos (5 minutes at most) are inside these boxes.

**If you run late:** skip the Exercise 1.3 prompt, combine Part 5 prompts C and D into one message,
and fix `tech.md` (Exercise 4.2, step 4) during the break.

---

## Part 1: Kiro IDE 1.x tour (10 minutes)

### Exercise 1.1: Open the chat and find the workflows (2 minutes)

**Goal:** know where each kind of session starts and how to switch agents.

**Steps**

1. Press **Cmd+L** (macOS) or **Ctrl+L** (Linux). On **Let's build**, type (Default agent) or pick
   **Spec**, **Quick Spec**, **Bug Fix** or **Plan**.
2. Click the **agent selector** (agent name, bottom bar of the chat input). Groups: **Built-in**,
   **User** or **Global** (`~/.kiro/agents/`; label depends on your build), **Workspace**
   (`.kiro/agents/`). Switching keeps the conversation; the selector is disabled while the agent is
   executing a multi-step workflow.
3. Click the **Kiro ghost icon** in the activity bar: **Specs**, **Agent Hooks**, **Steering**,
   **MCP Servers**.

<details><summary>Background: the built-in workflows and slash commands</summary>

You can also open the chat from the Command Palette with **Kiro: Open Chat**.

| Built-in workflow | What it does | Where you use it |
|---|---|---|
| Spec | Requirements → design → tasks, with approval gates | Module 2 onwards |
| Quick Spec | Generates requirements, design and tasks in one pass, without approval gates | Module 3 |
| Bug Fix | Root cause → fix design → implementation (`bugfix.md`) | Module 5 |
| Plan | Read-only: explores the codebase and produces a plan without making changes | Part 5 of this module |

- The agent selector sits next to the model picker. **Built-in** lists Default, Spec, Quick Spec,
  Bug Fix and Plan.
- The IDE has **no `/spec` or `/plan` slash command** (those are CLI commands). Start Spec and Plan
  sessions from the Let's build screen or the agent selector. `/quick-spec` and `/bug-fix` do exist
  as IDE slash commands.

Docs: [Chat](https://kiro.dev/docs/ide/chat/) · [Setup](https://kiro.dev/docs/ide/setup/) ·
[Slash commands](https://kiro.dev/docs/ide/chat/slash-commands/)

</details>

**Verify:** **migration-reviewer** is under **Workspace**. If not, the workspace isn't trusted (Part 2).

**Checkpoint:** nothing changed.

### Exercise 1.2: Switch to Supervised mode (2 minutes)

**Goal:** review every edit before it lands.

**Steps:** turn off the **Autopilot** switch in the chat, or set **Settings → Agent → Agent Autonomy**
(`kiroAgent.agentAutonomy`) to **Supervised**. Edits then arrive as hunks to **Accept**, **Reject**
or **Chat inline** (or **Accept All** / **Reject All**).

<details><summary>Background: Autopilot vs Supervised, and why Supervised here</summary>

- **Autopilot** (the default): Kiro creates files, modifies code and runs commands without asking at
  each step.
- **Supervised**: Kiro yields for your approval after each turn that contains file edits. **Chat
  inline** is a conversation about that one hunk.

Why Supervised for this workshop:

- A migration edit can compile and still change behavior: a security matcher, a validation
  annotation, a test assertion. Reviewing hunks is where you catch that.
- You are here to learn what the agent does. In Supervised mode you see every change it makes.
- Rejecting one hunk now is cheaper than untangling a multi-file change later.

Autonomy is the coarse control. Permission rules (Part 2) are the fine control, and they apply in
both modes: in Autopilot, your `ask` and `deny` rules still gate commands.

Docs: [Autopilot](https://kiro.dev/docs/ide/chat/autopilot/)

</details>

**Verify:** Settings → search "Agent Autonomy" → **Supervised**.

**Checkpoint:** IDE setting; nothing to commit.

### Exercise 1.3: Context providers and Cmd/Ctrl+L (4 minutes)

**Goal:** give the agent exactly the context you mean.

Type `#` to pick a context provider (today: `#codebase`, `#current`, `#pom.xml`, manual steering).
If `#url` (Modules 2–3) fails, paste the module's quoted section instead.

<details><summary>Background: all 14 context providers, and other ways to send a selection</summary>

| Provider | Adds | Used in this workshop for |
|---|---|---|
| `#codebase` | Relevant files found across the project | Inventories (Part 5) |
| `#file` | A specific file: type `#` and the file name, e.g. `#pom.xml` | Pinned versions (Part 5) |
| `#folder` | A folder and its contents, e.g. `#src/test/` | Test-only questions |
| `#git diff` | The current Git changes | Reviewing a stage before you commit |
| `#terminal` | Recent terminal output and command history | Feeding Maven errors to the agent |
| `#problems` | All problems in the current file | Compiler errors in the open file |
| `#url` | A web page, e.g. `#url:https://…` | Pointing at an official migration guide. If it fails or is slow (for example, web fetch is disabled on your network), paste the quoted section from the module instead. |
| `#code` | A code snippet you paste | Asking about a snippet outside the repo |
| `#repository` | A map of the repository structure | Orientation |
| `#current` | The file active in the editor | Questions about the open file |
| `#steering` | A specific steering file, e.g. `#steering:migration-standards.md` | Checking a rule |
| `#docs` | Documentation files, e.g. `#docs:<file>` | Your own docs |
| `#spec` | All files of a spec (requirements, design, tasks) | Modules 2 to 5 |
| `#mcp` | Tools, prompts and resources from an MCP server | Not used in the core labs (only Module 4's optional AWS Transform lab) |

You can combine providers in one message, for example `#codebase #pom.xml …`.

In the Exercise 1.3 check, "everything else" behind HTTP Basic includes `/api/users/**`. If the answer
claims something the code doesn't show, note it: agents can be confidently wrong.

**Cmd+Shift+L** / **Ctrl+Shift+L** starts a new session with the selection instead of adding it to
the current chat, and right-click → **Kiro > Ask Kiro** offers quick actions. The old inline
(in-editor) chat was retired in IDE 1.0.

Docs: [Chat: context providers](https://kiro.dev/docs/ide/chat/) ·
[Keyboard shortcuts](https://kiro.dev/docs/ide/editor/keyboard-shortcuts/) ·
[What's new in IDE 1.0](https://kiro.dev/docs/ide/whats-new-v1/)

</details>

**Steps:** in `config/SecurityConfig.java`, select the whole `configure(HttpSecurity http)` method,
press **Cmd+L** / **Ctrl+L** to add it to the chat, and send:

**Ask Kiro**

```text
Explain what the selected method allows without authentication, which requests need a login, and where CSRF protection is switched off. Then list which of its APIs are deprecated or removed in later Spring Security versions, and mark anything you are not sure about as "unverified". Answer only; do not change any files.
```

**Verify**

```bash
grep -nE "permitAll|authenticated|ignoringAntMatchers|httpBasic" src/main/java/com/example/usermanagement/config/SecurityConfig.java
```

Look for: `/api/public/**` open, everything else behind HTTP Basic, CSRF ignored for `/api/**`. Note
claims the code doesn't support.

**Checkpoint:** answer only. **Reject** any hunks.

### Exercise 1.4: Checkpoints and their limits (2 minutes)

**Goal:** know what Kiro can undo, and what it can't.

**Steps:** scroll up to the **checkpoint** marker of your Exercise 1.3 prompt (don't click it).
**Revert** (above the chat input) undoes the agent's latest turn; **Restore** on a marker rolls agent
edits and context back to it. Neither undoes your edits or changes by shell commands (e.g. `mvn`) or
MCP tools; git does.

<details><summary>Background: the three undo tools in detail</summary>

| Tool | Undoes | Does not undo |
|---|---|---|
| **Revert** (above the chat input) | The file changes of the agent's latest turn | Earlier turns, shell commands |
| **Restore** on a checkpoint marker | Agent file changes **and** Kiro's context back to that point, across several turns | Your manual edits, formatter runs, files changed by shell commands the agent ran (e.g. `mvn`), changes made by MCP tools |
| **git** (Part 3) | Anything you committed before | Nothing you didn't commit |

- If Kiro snapshotted a file and you then edit that file by hand (or run a formatter on it),
  restoring a checkpoint can lose your edits.
- Conversation "rewind" (forking the chat at an earlier turn) is a CLI feature, not an IDE one.

Docs: [Checkpoints and rewind](https://kiro.dev/docs/checkpoints/)

</details>

**Verify:** you can point to a checkpoint marker.

**Checkpoint:** none. The lesson is Part 3: commit before every agent run.

---

## Part 2: Workspace trust and permissions (8 minutes)

### Exercise 2.1: Confirm the workspace is trusted (1 minute)

**Goal:** make sure `.kiro/` is loaded. An untrusted workspace loads no agents, steering, MCP, skills
or workflows, and asks before **every** shell command.

**Steps:** check that:

1. Kiro panel → **Steering** lists `migration-standards`, `migration-playbook`, `pom-rules`, `test-rules`.
2. Agent selector → **Workspace** lists `migration-reviewer`.
3. Typing `/` lists `migration-playbook`, `migration-reviewer` and the two skills
   `jakarta-namespace-migration` and `spring-security-lambda-dsl`.

**Verify:** all show up; if not, see Troubleshooting.

**Checkpoint:** none.

### Exercise 2.2: First shell command and "Always allow" (4 minutes)

**Goal:** let the agent run Maven without asking, in this workspace only, and confirm its JDK.

**Steps**

1. Start a new session (**+** in the chat panel, or **Cmd+T** / **Ctrl+T**) and send the first prompt.
2. At the approval prompt choose **Always allow**, pattern `mvn *` (widen Kiro's suggestion if it's
   narrower), **Apply to: This workspace**. If **Always allow** isn't offered, choose **Allow**.
3. Send the second prompt. It should run **without** a prompt.

<details><summary>Background: the approval prompt</summary>

- Without any configuration, everything except workspace reads, read-only git and system-info
  commands prompts, including `mvn`.
- Skip the workflow picker in the new session; you want the Default agent.
- Kiro suggests a generalized pattern; edit it if it is narrower, such as `mvn -v`.
- If **Always allow** isn't offered, Kiro couldn't verify a working saved rule and hid the persistent
  options (see the troubleshooting details).

</details>

**Ask Kiro**

```text
Run `mvn -v` in the workspace root and tell me the Maven version and the Java version it reports. Do not run anything else.
```

```text
Run `mvn -B -q clean compile` in the workspace root and tell me whether it succeeded. Do not change any files.
```

**Verify**

- The first answer reports **Java version 1.8.0_…**. If 21 or 25: make JDK 8 active in a terminal
  ([setup](../docs/participant-setup.md#switch-the-jdk-per-terminal)), restart Kiro there with
  `kiro .`, repeat.
- The second command didn't prompt (`-q` prints nothing on success).
- The rule is outside the repository:

```bash
grep -rn "mvn" ~/.kiro/workspace-roots/
git status
```

Look for: `mvn *` in a `permissions.yaml`, and nothing new in `git status`.

**Checkpoint:** repository unchanged.

### Exercise 2.3: Why rules are per user, and what never to pre-approve (3 minutes)

**Goal:** close the gap `mvn *` leaves: it also matches `mvn deploy`.

**Steps:** add this rule to `~/.kiro/settings/permissions.yaml` yourself (create the file or use its
`rules:` key); the agent may never write there.

```yaml
rules:
  - capability: shell
    match: ["mvn *deploy*"]
    effect: deny
```

`deny` beats `allow` in every scope, in all projects. Leave `git push`, publish and release
prompting; never **Always allow** them.

<details><summary>Background: why the workshop can't ship this rule for you, and two rules of thumb</summary>

- Permission rules live in your home directory: `~/.kiro/settings/permissions.yaml` (all workspaces)
  or `~/.kiro/workspace-roots/<hash>/permissions.yaml` (one workspace). Both are outside the repository.
- The docs are explicit: "A cloned repo cannot inject permission rules - trust is something you
  configure on your own machine." If a repository could pre-approve commands, cloning it would be
  enough to run them.
- A custom agent profile *can* carry its own rules (the reviewer agent does, see Part 6), but it only
  loads in a trusted workspace, and a `deny` in any scope always wins.
- `mvn *` also matches `mvn clean deploy`. The sample app has no deployment target; the deny rule makes
  the boundary explicit. When an unexpected command prompts, you can also choose **Always deny**.
- Compound commands (`cd x && mvn test`) are split and each part is approved separately. Ask the agent
  for single commands run from the workspace root.
- Headless runs (Module 7) treat every `ask` as `deny`, so they need explicit allow rules.

Docs: [Permissions](https://kiro.dev/docs/permissions/)

</details>

**Verify:** `cat ~/.kiro/settings/permissions.yaml` shows the `mvn *deploy*` deny rule.

**Checkpoint:** repository unchanged.

---

## Part 3: Git baseline (5 minutes)

**Goal:** a known-good stage 0 with the test count recorded.

**Steps:** run Maven yourself (no credits):

```bash
git status
git switch -c workshop
mvn -B clean verify | tail -n 30
```

Read **Tests run** in your output: expect **14**; if not, stop and ask the instructor. Then tag:

```bash
git tag -a stage-0 -m "Stage 0: Java 8, Spring Boot 2.2.4, Tests run: 14"
git show stage-0 --no-patch
```

**For the rest of the day, commit before every agent run** (unless `git status` is clean):

```bash
git add -A
git commit -m "checkpoint: before <what the agent is about to do>"
```

<details><summary>Background: why commit before every agent run</summary>

Checkpoints don't capture files changed by shell commands or MCP tools, and Restore can't bring back
what it never captured. A commit can. After the agent's turn, `git diff` (or `#git diff` in chat)
shows exactly what changed, and `git restore <file>` undoes a file.

</details>

**Verify**

```bash
git branch --show-current
git tag -l "stage-*"
```

Look for: `workshop` and `stage-0`. **Source Control** (**Ctrl+Shift+G**) should show the repository;
if not, see Troubleshooting.

**Checkpoint:** tag `stage-0`.

---

## Part 4: Steering (12 minutes)

Steering files (`.kiro/steering/`) tell the agent how to work here. Their front matter (first in the
file) sets when each loads: `always` (default), `fileMatch`, `manual` or `auto`.

<details><summary>Background: inclusion modes</summary>

| Inclusion | Loads | Reference by hand |
|---|---|---|
| `always` (the default) | In every interaction | Not needed |
| `fileMatch` + `fileMatchPattern` | When files matching the pattern are in context | Not needed |
| `manual` | Only when you reference it | `#<name>` or `/<name>` |
| `auto` + `name` + `description` | When your request matches the description | `/<name>` |

Docs: [Steering](https://kiro.dev/docs/steering/)

</details>

### Exercise 4.1: Inspect the shipped steering (5 minutes)

**Goal:** know which rules the agent follows and when: `migration-standards` (`always`), `pom-rules`
and `test-rules` (`fileMatch`), `migration-playbook` (`manual`).

<details><summary>Background: what each shipped steering file enforces</summary>

| File | Inclusion | What it enforces |
|---|---|---|
| `migration-standards.md` | `always` | The four stages and their versions; one stage at a time; never invent versions; only Jakarta EE packages move to `jakarta.*`; a change is done only when `mvn -B clean verify` passes **and the test count did not go down**; no deleting or disabling tests; never two Maven builds at once |
| `pom-rules.md` | `fileMatch` on `**/pom.xml` | Bump the Boot parent first; remove `<version>` from managed dependencies; set `java.version`; confirm resolved versions with `dependency:tree` |
| `test-rules.md` | `fileMatch` on `src/test/**/*.java` | Keep every scenario; report Tests run before and after; JUnit Jupiter from stage 2; web tests keep covering auth, validation and `X-Request-Id`, and include a successful create (`validUserIsCreated`) |
| `migration-playbook.md` | `manual` | The stage-by-stage checklist, each trap with the symptom you'd see if you missed it |

</details>

**Steps**

1. Open each file (Kiro panel → **Steering**); look at the front matter.
2. Open `pom.xml` and send the first prompt (`pom-rules` should load).
3. Send the second prompt (or type `/migration-playbook`).

**Ask Kiro**

```text
#current Which workspace steering rules apply when you change this file? Quote the rule about dependency versions. Answer only; do not change any files.
```

```text
#migration-playbook For stage 1, list each trap and the symptom I would see if it were missed. Answer only.
```

**Verify**

```bash
cat .kiro/steering/pom-rules.md
sed -n '/## Stage 1/,/## Stage 2/p' .kiro/steering/migration-playbook.md
```

Look for: answer 1 quotes `pom-rules` ("Remove `<version>` tags from dependencies the parent
manages"); answer 2 lists validation silently ignored, fewer or zero tests run, circular references,
the Lombok pin.

<details><summary>Background: steering can be wrong too</summary>

These answers came from **your** steering, not from the model's own knowledge. That is the point of
steering, and also its risk: steering can be wrong too. Facts in it still need checking against the
official Spring migration guides. The `fileMatch` patterns are `**/pom.xml` (`pom-rules`) and
`src/test/**/*.java` (`test-rules`); the rule loads because the file is in context.

</details>

**Checkpoint:** nothing changed.

### Exercise 4.2: Generate foundation steering and review it critically (7 minutes)

**Goal:** add `product.md`, `tech.md` and `structure.md`, which load in **every** interaction,
without steering the agent wrong.

**Steps**

1. Check that `git status` is clean.
2. Kiro panel → **Steering** → **Generate Steering Docs** (or **+** → **Foundation steering files**).
3. Review the three files: versions match `pom.xml` (Java `1.8`, Boot
   `2.2.4.RELEASE`); legacy patterns are labelled "current state (stage 0)", not conventions; no
   invented facts; no other target versions; no secrets; short.
4. Fix it by hand or with the prompt below (accept only `tech.md` hunks).

**Ask Kiro**

```text
Edit .kiro/steering/tech.md only. Label the stack section "Current state (stage 0)" and use the exact versions from #pom.xml. Add one line saying that the legacy patterns in this code (field injection, java.util.Date, JUnit 4 runners, WebSecurityConfigurerAdapter, javax.* imports) are migration targets, not conventions to copy. Add one line that points to migration-standards.md for the staged target versions. Remove anything that no file in this repository supports.
```

**Verify**

```bash
ls .kiro/steering
head -n 5 .kiro/steering/tech.md
grep -nE "2\.2\.4|1\.8" .kiro/steering/tech.md
```

Look for: seven files; any front matter on line 1; versions matching `pom.xml`.

<details><summary>Background: the review checklist in full</summary>

- Foundation files are included in every interaction by default, so a wrong line in them reaches every
  prompt for the rest of the day. Keep `tech.md` true as you go: when you commit a stage later,
  update its "current state" line.
- Kiro analyzes the repository and writes the three files to `.kiro/steering/`. Outside Supervised
  mode, open the three files to review them.
- **Versions.** `tech.md` must match `pom.xml`: Java `1.8`, Spring Boot `2.2.4.RELEASE` (which
  manages Spring Framework 5.2.3).
- **Legacy written as convention.** Generated docs describe the code as it is. If they say "use
  field injection", "write tests with JUnit 4 and `@RunWith`" or "configure security by extending
  `WebSecurityConfigurerAdapter`", they tell the agent to keep exactly what you're migrating away
  from. Reword these as "current state (stage 0)".
- **Invented facts.** Delete any CI pipeline, deployment target, team, SLA or database claim that no
  file in the repository supports.
- **Conflicts.** `migration-standards.md` owns the staged targets. Delete any other target version.
- **Secrets.** None belong in steering.
- **Length.** Shorter is better; these files are in every prompt's context.
- A file without front matter is included always.

Docs: [Steering: foundation files](https://kiro.dev/docs/steering/)

</details>

**Checkpoint**

```bash
git add .kiro/steering
git commit -m "Add reviewed foundation steering (product, tech, structure)"
```

---

## Part 5: Assessment with the Plan workflow (18 minutes)

**Goal:** a read-only inventory of the migration surface, saved to `MIGRATION-NOTES.md`.

### Exercise 5.1: Start a Plan session (1 minute)

**Steps**

1. Start a new session (**+** or **Cmd+T** / **Ctrl+T**) and choose **Plan**.
2. Plan only reads and searches: no file writes, commands or MCP tools, and it saves nothing.
3. Answer clarifying questions as `1=a, 2=b`, or skip. A good answer: "Assessment only. The staged
   targets are in migration-standards."

> **Do not approve a plan in this module.** Per the docs, "Once you approve the plan, execution begins
> automatically": the agent starts implementing.

<details><summary>Background: what Plan can and can't do</summary>

| Can | Can't |
|---|---|
| Read files, use code intelligence, search with grep and glob, search the web | Write files, run commands, use MCP tools |

- The agent name in the chat input shows **Plan**. The plan lives only in the conversation; nothing is
  saved to `.kiro/specs/`.
- You can answer clarifying questions in your own words too.
- After approval, Plan mode exits. Today you only assess; implementation starts in Module 2, with a
  spec.

Docs: [Plan mode](https://kiro.dev/docs/specs/plan/)

</details>

### Exercise 5.2: Inventory the migration surface (10 minutes)

Send each prompt, then run its check yourself: `grep` is the ground truth.

**Ask Kiro (A: `javax.*` imports)**

```text
#codebase This is an assessment only; do not propose code changes. List every import from javax.* in src/main/java and src/test/java, grouped by package (javax.persistence, javax.validation, javax.servlet, anything else). For each group, say whether it moves to jakarta.* in Spring Boot 3 or stays because it is a JDK package. Give file paths. Also list the javax.* artifacts declared in pom.xml.
```

**Verify (A)**

```bash
grep -rn "^import javax\." src
grep -n "javax" pom.xml
```

Look for: `entity/User.java`, `controller/UserController.java`, `web/RequestIdFilter.java`; three
`javax` artifacts (servlet, persistence, validation).

**Ask Kiro (B: Spring Security)**

```text
#codebase Describe the Spring Security setup: the configuration class and its base class, the request matchers and what each one permits, CSRF rules, the authentication mechanism, and how users and passwords are created. Then list each API used here that is deprecated or removed in Spring Security 6 or 7. Mark anything you are not sure about as "unverified".
```

**Verify (B)**

```bash
grep -nE "extends|antMatchers|authorizeRequests|csrf|and\(\)|inMemoryAuthentication" src/main/java/com/example/usermanagement/config/SecurityConfig.java
```

Look for: `WebSecurityConfigurerAdapter`, `antMatchers`, `authorizeRequests`, `ignoringAntMatchers`,
`and()` chaining, in-memory users (passwords from environment variables or generated).

**Ask Kiro (C: tests)**

```text
#codebase Which test frameworks, runners and test slices do the tests use? For each test class give its runner annotation and the number of @Test methods. Which Spring Boot upgrade would make these tests stop running without failing the build, and why? Mark anything you are not sure about as "unverified".
```

**Verify (C)**

```bash
grep -rnE "@RunWith|@WebMvcTest|@MockBean|import org.junit" src/test
grep -rc "@Test" src/test/java
```

Look for: JUnit 4, `SpringRunner`, `MockitoJUnitRunner`, `@WebMvcTest`, `@MockBean`; `@Test` counts
9 + 5 = 14. Expected answer: Spring Boot 2.4 removed the JUnit Vintage engine from
`spring-boot-starter-test`, so JUnit 4 tests can silently stop running.

**Ask Kiro (D: pinned versions)** (type `#` and pick `pom.xml`)

```text
#pom.xml List every explicit <version> and every property that pins a version. For each, say whether the Spring Boot parent already manages that artifact, and what could break when the parent is upgraded while the pin stays. Mark anything you are not sure about as "unverified".
```

**Verify (D)**

```bash
grep -nE "<version>|<java.version>" pom.xml
mvn -B dependency:tree -Dincludes=org.projectlombok,javax.persistence,javax.validation
```

Look for: parent `2.2.4.RELEASE`, `java.version` `1.8`, pins on `javax.persistence-api`,
`validation-api` and `lombok` `1.18.10` (which can't run on JDK 16+).

<details><summary>Background: where the answers come from</summary>

- Plan can't run commands, which is why you run every check yourself.
- Kiro's answer for prompt A should name the same files and packages; note every file it missed or
  invented.
- Modules 3 and 4 check the Spring Security "removed in" claims against the Spring Security
  migration guides.
- For prompt C, your playbook steering says the same thing about JUnit Vintage, so Kiro may be
  repeating it. The primary source is the Spring Boot 2.4 release notes. The per-file counts are 9 in
  `UserServiceTest` and 5 in `UserControllerTest`. The fifth web test, `validUserIsCreated`, posts a
  valid user whose JSON omits `active` and expects 201; it is the one that catches the Jackson 3 trap
  in Module 4.
- For prompt D, the key risk Kiro should name is that Lombok 1.18.10 can't run on JDK 16 or later.

</details>

**Checkpoint:** read-only so far.

### Exercise 5.3: Why not Java 21 right now? (2 minutes)

**Ask Kiro**

```text
Why can't this project move to Java 21 while it is still on Spring Boot 2.2.4? Name every blocker you can find in this codebase and its dependencies, and for each one name the official source I should check to confirm it. Then explain why the staged path in migration-standards upgrades to Spring Boot 2.7.18 before changing the JDK.
```

**Verify:** the answer covers at least:

- **Spring Boot 2.2.4 is documented as compatible up to Java 13; the last 2.2 patch (2.2.13) up to
  Java 15.**
- **Lombok 1.18.10** fails on JDK 16+.
- **Spring Boot 2.7.18** "requires Java 8 and is compatible up to and including Java 21": upgrade the
  framework on JDK 8 first, then switch the JDK (Module 2).

If Kiro states another range, ask for its source.

<details><summary>Background: sources for the Java ranges</summary>

- System Requirements:
  [2.2.4](https://docs.spring.io/spring-boot/docs/2.2.4.RELEASE/reference/html/getting-started.html) ·
  [2.2.13](https://docs.spring.io/spring-boot/docs/2.2.13.RELEASE/reference/html/getting-started.html) ·
  [2.7.18](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/getting-started.html).
- Java 21 is outside the 2.2 range either way.
- Verified in the 2026-10-10 dry run (Corretto 21): this baseline doesn't even compile on JDK 21. The
  Lombok 1.18.10 pin fails first, with `java.lang.IllegalAccessError: class
  lombok.javac.apt.LombokProcessor ... cannot access class
  com.sun.tools.javac.processing.JavacProcessingEnvironment`. The same pin on Boot 2.7 fails the same
  way, which is why Module 2 removes it.
- `migration-standards` tells the agent never to invent version numbers, and this is the kind of
  claim that rule exists for.

> Verify: for 2.2, the Java upper bound in the "System Requirements" section of the Spring Boot 2.2.x
> reference documentation changed across 2.2.x patch releases. Check the page for the patch version you
> care about.

</details>

### Exercise 5.4: Save the findings to `MIGRATION-NOTES.md` (5 minutes)

Plan saves nothing, so switch the **same** session to Default (history comes along).

**Steps**

1. Check that `git status` is clean.
2. When the agent is idle, select **Default** in the agent selector. Don't approve any plan.
3. Send the prompt; **Accept** the `MIGRATION-NOTES.md` hunk, **Reject** anything else.

**Ask Kiro**

```text
Create MIGRATION-NOTES.md in the workspace root from the assessment in this conversation. Use these sections: Baseline (Java, Spring Boot and Spring Framework versions from pom.xml; Tests run: 14, as recorded in the stage-0 tag), javax.* inventory, Spring Security, Tests, Pinned versions, Why not Java 21 yet, Staged path (from migration-standards), Open questions. Keep each item to one line, keep every "unverified" mark, and add file paths where you have them. Do not change any other file.
```

<details><summary>Background: example output (yours will differ)</summary>

```text
## Baseline
- Java 1.8, Spring Boot 2.2.4.RELEASE (Spring Framework 5.2.3), Tests run: 14
## javax.* inventory
- javax.persistence: entity/User.java -> jakarta.persistence in Spring Boot 3
...
```

Supervised mode lets you check the result before it lands.

Docs: [Plan mode](https://kiro.dev/docs/specs/plan/) · [Chat: switching agents](https://kiro.dev/docs/ide/chat/)

</details>

**Verify**

```bash
git status --short
grep -nE "Tests run|unverified" MIGRATION-NOTES.md
```

Look for: only `?? MIGRATION-NOTES.md`, and `Tests run: 14`. Fix anything your checks contradicted.

**Checkpoint**

```bash
git add MIGRATION-NOTES.md
git commit -m "Module 1: assessment notes"
```

---

## Part 6: Shipped hooks and the reviewer agent (7 minutes)

**Goal:** know what runs automatically later. Don't run, enable or edit anything.

### Exercise 6.1: The two hooks (4 minutes)

**Steps:** open Kiro panel → **Agent Hooks**, then read the two definitions:

```bash
cat .kiro/hooks/verify-after-spec-task.json
grep -nE '"trigger"|"enabled"' .kiro/hooks/*.json
```

| Hook | Trigger | Action | State |
|---|---|---|---|
| `verify-after-spec-task` | `PostTaskExec` (after each spec task) | One `mvn -B clean verify`; reports `Tests run` and `BUILD SUCCESS`, or the last 80 lines on failure | **On** |
| `jakarta-import-guard` | `PostFileSave`, `\.java$` | Reports Jakarta EE APIs still imported from `javax.*` in a file the agent saved | **Off** until Module 3 Part 1 |

From Module 2 on: the hook passes even if fewer tests ran (green is not done; read the count), and
you wait for it (Kiro output panel) before running Maven yourself, since builds share `target/`.

<details><summary>Background: why the hooks are built this way</summary>

- **Command, not agent, actions.** Command hooks run a shell command in the project root. They're
  deterministic and use no credits; agent-prompt hooks start a new agent loop and do use credits.
- **stdout on success, stderr on failure.** On a non-zero exit, Kiro sends the command's **stderr** to
  the agent; on success, stdout is added to its context. Maven prints its errors to stdout, so the hook
  captures the output, prints the `Tests run` / `BUILD` summary on stdout, and on failure copies the
  last 80 lines to stderr with `1>&2`. That is what lets a test failure reach the agent, and why the
  agent doesn't need to build again after a task.
- **`clean`.** Maven may not recompile after a JDK switch or a version bump, which would hide exactly
  the errors the later modules want you to see.
- **`timeout: 900`.** The default is 60 seconds, too short for a Maven build.
- **`PostTaskExec` only fires around spec tasks**, so it stays quiet during today's chats.
- **File hooks fire only on agent edits.** Your own saves never trigger `jakarta-import-guard`.
- **The guard is disabled** because in stages 0 and 1 `javax.*` imports are correct, so it would flag
  every file (`javax.persistence`, `javax.validation`, `javax.servlet` and similar). A `PostFileSave`
  hook can't block anything; it reports. Blocking uses exit code 2 on `PreToolUse`,
  `UserPromptSubmit` or `PreTaskExec`.
- You'll enable the guard in Module 3 with the eye icon in the Agent Hooks panel. Writes to
  `.kiro/hooks/` always ask for approval, even with allow rules.

> Verify: the docs don't say whether hook commands go through your permission rules. If they do, the
> verify hook's command (it starts with `out=$(mvn …`) may not match your `mvn *` rule from Part 2,
> and you'd see an approval prompt the first time it runs.

Docs: [Hooks](https://kiro.dev/docs/hooks/) · [Hook types](https://kiro.dev/docs/hooks/types/) ·
[Hook actions](https://kiro.dev/docs/hooks/actions/) · [Managing hooks](https://kiro.dev/docs/hooks/management/)

</details>

### Exercise 6.2: The reviewer agent and the skills (3 minutes)

**Steps**

1. Run `sed -n '1,20p' .kiro/agents/migration-reviewer.md`.
2. `tools: ["read", "shell"]`: no `write` tool, and it's told not to modify files, but it has a
   shell: **run `git status` after every review**. Only its Maven build and read-only git run
   unprompted; plugin goals, deploy, changing git commands and `rm` are denied.
3. Two **skills** ship, `jakarta-namespace-migration` and `spring-security-lambda-dsl`, for Module 3.
   Each activates when a request matches its description, or via `/<skill name>`.

<details><summary>Background: how the reviewer works</summary>

- **Markdown agent.** The front matter is the configuration and the body is the system prompt. It
  appears in the agent selector under **Workspace** and as `/migration-reviewer`.
- **Permission rules.** Allowed without a prompt: `mvn -B verify`, `mvn -B -q verify`, `mvn verify`,
  `mvn -v`, `git diff`, `git status`, `git log`, `git show`. Denied: `mvn *:*` (plugin goals such as
  `versions:set`), `mvn *deploy*`, `git push`, `git commit`, `git reset`, `git checkout`,
  `git restore`, `git stash`, `rm`. Anything else prompts. A deny wins in every scope.
- **`resources`.** `file://.kiro/steering/**/*.md` and `skill://.kiro/skills/*/SKILL.md` hand it the
  steering and skills explicitly. Skills load their name and description up front and the full
  content on demand.
- **Trust.** Workspace agents load only in a trusted workspace. That's why you saw it in Part 2.
- **When you'll use it.** At the end of a stage, switch to it and ask it to review the stage's diff
  (for example `git diff stage-1..HEAD`). It should run `mvn -B verify` once and reply with a findings
  table and a "ready to commit" or "not ready" verdict. Module 5 uses it with sub-agents; when two
  reviewers run in parallel, only one of them runs Maven.

Docs: [Custom agents](https://kiro.dev/docs/custom-agents/) ·
[Creating custom agents](https://kiro.dev/docs/custom-agents/creating/) · [Skills](https://kiro.dev/docs/skills/)

</details>

**Verify:** `/` lists `migration-reviewer` and both skills. Don't select them.

**Checkpoint:** the module's work is committed.

```bash
git status
git log --oneline -3
```

Look for: a clean tree; two commits after `stage-0` (steering, notes).

---

## Checklist

- [ ] **Supervised** mode is on; you can start each workflow, switch agents and use `#` providers.
- [ ] You know Revert and Restore miss shell and MCP changes; git doesn't.
- [ ] Steering, `migration-reviewer` and both skills are visible.
- [ ] `mvn *` is allowed for **this workspace**, `mvn *deploy*` is denied, and the agent's `mvn -v`
      reports Java 1.8.
- [ ] Branch `workshop`; tag `stage-0` records `Tests run: 14`.
- [ ] Foundation steering and `MIGRATION-NOTES.md` are reviewed and committed.
- [ ] You can explain each hook, the reviewer, and why the guard is off.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| The agent's `mvn -v` reports Java 21 or 25 | Kiro wasn't started from a JDK 8 terminal | Quit Kiro; restart it with `kiro .` from a JDK 8 terminal. |
| `#git diff` is empty, or Source Control shows no repository | The offer to open the parent folder's repository was dismissed | > Verify: Command Palette → **Git: Open Repository** → repository root, or set `git.openRepositoryInParentFolders` to `always`. |

<details><summary>More troubleshooting</summary>

| Symptom | Cause | Fix |
|---|---|---|
| The agent's `mvn -v` reports Java 21 or 25 (more) | The agent's shell uses the JDK of the environment Kiro was started from | Switch per terminal ([setup](../docs/participant-setup.md#switch-the-jdk-per-terminal)), then restart Kiro from that terminal with `kiro .` and ask again. |
| No **Always allow** in the approval prompt | Kiro hides it when it can't verify a working saved rule | Choose **Allow** for now. Add `- capability: shell` / `match: ["mvn *"]` / `effect: allow` to `~/.kiro/settings/permissions.yaml` yourself (this applies to all workspaces). |
| Kiro still asks before every `mvn` command | Workspace untrusted (it asks before every shell command), or the saved pattern is too narrow (e.g. `mvn -v`) | Trust the workspace; change the rule's pattern to `mvn *`. |
| One command produces two approval prompts | Compound commands (`&&`, `;`, `\|`) are split and approved per part | Ask for single commands run from the workspace root. |
| Steering, the agent or the skills don't appear | Workspace untrusted, or the repository root is open | Open `sample-app/` and trust it. |
| The `pom.xml` question doesn't mention `pom-rules` | `pom.xml` wasn't in context, or the front matter isn't on line 1 | Open `pom.xml` and use `#current` or `#pom.xml`; check the file's first line is `---`. |
| No **Generate Steering Docs** button | Different panel state in your build | Click **+** in the Steering section and choose **Foundation steering files**. |
| Generated `tech.md` presents legacy patterns as conventions | Foundation docs describe the code as it is | Reword them as "current state (stage 0)" (Exercise 4.2). |
| Plan started editing files | A plan was approved; execution begins automatically | Stop the agent, use **Revert** or **Restore**, then check `git status` and `git restore <file>` for anything left. Don't approve plans in this module. |
| Plan says it can't create `MIGRATION-NOTES.md` | Plan mode is read-only | Switch the session to **Default** with the agent selector (Exercise 5.4). |
| The agent selector is greyed out | The agent is executing a multi-step workflow | Wait until it's idle. |
| Kiro's inventory disagrees with your `grep` | The model missed or invented something | Trust `grep`. Correct the notes and mark the claim "unverified". |
| Hunks were applied without review | Autopilot is still on | Switch to Supervised (Exercise 1.2). |
| `git switch` is not a git command | Git older than 2.23 | Use `git checkout -b workshop`, and upgrade Git before Module 2. |
| `#git diff` is empty (more) | The workspace (`sample-app/`) is a subfolder of the git repository. Kiro, like VS Code, may offer to open the repository found in a parent folder | Accept the offer. If you dismissed it, use the fix in the main table and reload the window; the instructor's dry run confirms the exact control. The terminal `git` commands work either way. |
| The test count in Part 3 isn't 14 | Local edits, wrong JDK, or a changed environment | Run `git status` and `mvn -v`, and ask the instructor before continuing. |

</details>

## Kiro features used

<details><summary>Feature list with docs links</summary>

| Feature | Docs |
|---|---|
| Opening a project with `kiro .` | <https://kiro.dev/docs/getting-started/first-project/> |
| Let's build screen, built-in workflows, agent selector | <https://kiro.dev/docs/ide/setup/> · <https://kiro.dev/docs/ide/chat/> |
| Autopilot vs Supervised (`kiroAgent.agentAutonomy`) | <https://kiro.dev/docs/ide/chat/autopilot/> |
| Context providers (14) | <https://kiro.dev/docs/ide/chat/> |
| Cmd/Ctrl+L, Cmd/Ctrl+Shift+L, Cmd/Ctrl+T, Ctrl+Shift+G, Kiro > Ask Kiro | <https://kiro.dev/docs/ide/editor/keyboard-shortcuts/> · <https://kiro.dev/docs/ide/whats-new-v1/> |
| Checkpoints, Restore, Revert | <https://kiro.dev/docs/checkpoints/> |
| Workspace trust, permissions, Always allow, deny rules | <https://kiro.dev/docs/permissions/> |
| Steering (`always`, `fileMatch`, `manual`), Generate Steering Docs | <https://kiro.dev/docs/steering/> |
| Slash commands (manual steering, agents, skills) | <https://kiro.dev/docs/ide/chat/slash-commands/> |
| Plan mode | <https://kiro.dev/docs/specs/plan/> |
| Hooks (v1 JSON, `PostTaskExec`, `PostFileSave`, command actions) | <https://kiro.dev/docs/hooks/> · <https://kiro.dev/docs/hooks/types/> · <https://kiro.dev/docs/hooks/actions/> · <https://kiro.dev/docs/hooks/management/> |
| Custom agents (Markdown, tools, permissions, resources) | <https://kiro.dev/docs/custom-agents/> · <https://kiro.dev/docs/custom-agents/creating/> |
| Skills | <https://kiro.dev/docs/skills/> |
| Credits | <https://kiro.dev/pricing/> |

</details>

## Next

[Module 2: Runway, Spring Boot 2.7 and Java 21](02-runway-boot27-java21.md): a Feature spec takes
the app to Spring Boot 2.7.18, then JDK 21.
