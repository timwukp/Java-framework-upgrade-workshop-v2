# Module 3: Spring Boot 3.5 and Jakarta EE (105 minutes)

You move the service from stage 1 (Spring Boot 2.7.18, Java 21, `javax.*`) to stage 2 (Spring Boot
3.5.16, Java 21, Jakarta EE 10): the state in `solutions/stage-2-boot35-java21/`. 3.5.16 is a
waypoint that keeps the jump to 4.1 small. Kiro edits, skills guide it, a hook checks its Java saves,
and the test count tells you whether it worked.

## What you'll do

- Turn on the import guard, plan with a **Quick Spec**, and bump the parent to 3.5.16.
- Migrate `javax.*` → `jakarta.*` and Spring Security with two shipped skills.
- Write your own `junit4-to-jupiter` skill, drop JUnit 4 without losing a test, and tag `stage-2`.

## Prerequisites

- Module 2 is complete: tag `stage-1`, Boot 2.7.18 on Java 21, **Tests run: 14** (9 service + 5
  web). Every check expects 14; read your own number each time.
- Behind? Use the one reset procedure,
  [solutions/README.md → Reset your workspace to a stage](../solutions/README.md#reset-your-workspace-to-a-stage-the-one-procedure-all-modules-use),
  row **Module 3**, from `sample-app/`.
- Trusted workspace, `mvn *` allowed (Module 1), **Supervised** autonomy, `MIGRATION-NOTES.md` present.
- **Hook states at the start:** `verify-after-spec-task` **on**, `jakarta-import-guard` **off** (Kiro
  panel → **Agent Hooks**).

Commands run from `sample-app/` in Kiro's integrated terminal.

**Build rules.** Always `clean` (`mvn -B clean verify`, `mvn -B -q clean compile`,
`mvn -B clean test-compile`): after a version bump Maven may skip recompiling and hide errors. One
build at a time: start yours only when the agent is idle and no hook run shows in the Kiro output
panel. Prompts before your checks tell the agent not to build.

<details><summary>Background: why this stage, and why 3.5 is not the destination</summary>

| Fact | Source (verbatim) |
|---|---|
| Java 17 is the new floor | "Spring Boot 3.0 requires Java 17 or later. Java 8 is no longer supported. It also requires Spring Framework 6.0." ([Spring Boot 3.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide)) |
| Jakarta EE 10, Servlet 6.0 | "Spring Boot 3.0 has upgraded to the version that is included in Jakarta EE 10. For example, Spring Boot 3.0 uses the Servlet 6.0 and JPA 3.1 specifications." (same guide) |
| The package rename | "Jakarta EE now uses jakarta packages rather than javax." (same guide) |
| 2.x deprecations are gone | "Classes, methods and properties that were deprecated in Spring Boot 2.x have been removed in this release." (same guide) |
| 3.5 is a waypoint | `"eol":"2026-06-30"`, `"latest":"3.5.16"` ([endoflife.date, Spring Boot 3.5](https://endoflife.date/api/spring-boot/3.5.json)). Open-source support for 3.5 ended on 2026-06-30, and 3.5.16 is the latest 3.5 release listed. |
| Reach the latest 3.5.x before 4.0 | "Before you start the upgrade, make sure to upgrade to the latest available 3.5.x version." ([Spring Boot 4.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide)) and "we strongly recommend that you upgrade to Spring Boot 3.5 before migrating to Spring Boot 4.0." ([Spring Boot 4.0 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Release-Notes)) |

So you go to 3.5.16 to make the jump to 4.1 (Module 4) small, not to stay there.

The 3.0 guide also says: "Before upgrading to Spring Boot 3.0, consider upgrading your Spring Boot 2.7
application to Spring Security 5.8." This workshop skips that intermediate step because its security
configuration is one small class, and the skill writes the lambda DSL straight away.

What the 3.5.16 parent manages (from the Spring Boot BOM at tag `v3.5.16`; you'll confirm some of
these with Maven in Exercise 2.3): Spring Framework 6.2.19, Spring Security 6.5.11, Hibernate
6.6.53.Final (group `org.hibernate.orm`), Byte Buddy 1.17.8, Lombok 1.18.46, JUnit Jupiter 5.12.2,
Mockito 5.17.0.

</details>

## Time box

| Part | Topic | Minutes |
|---|---|---|
| 1 | Turn on the Jakarta import guard | 10 |
| 2 | Quick Spec and the parent bump | 13 |
| 3 | Jakarta namespace with a shipped skill | 22 |
| 4 | Spring Security 6 in Supervised mode | 25 |
| 5 | Write your own skill: JUnit 4 to Jupiter | 25 |
| 6 | Clean up, record, tag `stage-2` | 10 |
| | **Total** | **105** |

Exercises 2.4 and 3.1 are optional, outside the box. **If you run late:** skip them, copy the
reference skill in Exercise 5.1, and skip the reference diff in Exercise 6.2.

### The build is red on purpose for a while

| After | `mvn -B -q clean compile` | Tests run | `verify-after-spec-task` | `jakarta-import-guard` |
|---|---|---|---|---|
| Start | passes | 14 | on | off |
| Part 1 | passes | 14 | on | **on** |
| Part 2 | **fails** in 4 files | — | **paused** (Ex 2.1) | on |
| Part 3 | **fails** in `SecurityConfig.java` only | — | paused | on |
| Part 4 | passes | 14 (JUnit 4 on Vintage) | **on again** (Ex 4.3, step 6) | on |
| Parts 5–6 | passes | 14 (JUnit Jupiter only) | on | on |

Boot 3 has no `javax.*` APIs and no `WebSecurityConfigurerAdapter`, hence the red parts; the paused
hook doesn't feed those expected errors to the agent.

---

## Part 1: Turn on the Jakarta import guard (10 minutes)

### Exercise 1.1: Start from a green stage 1 (3 minutes)

**Goal:** know your starting point.

**Steps**

```bash
git status
git tag -l "stage-*"
mvn -v
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
```

**Verify:** clean tree, tags `stage-0` and `stage-1`, `Java version: 21…`, `BUILD SUCCESS`,
`Tests run: 14, Failures: 0, Errors: 0, Skipped: 0`. Not Java 21? Make JDK 21 active in a terminal
([setup](../docs/participant-setup.md#switch-the-jdk-per-terminal)), quit Kiro, and restart it there
with `kiro .`, so the agent and hooks use it too.

**Checkpoint:** nothing changed.

### Exercise 1.2: Read the guard, and dry-run its command (4 minutes)

**Goal:** know what the guard checks and how findings reach the agent.

**Steps**

1. Read the hook: `cat .kiro/hooks/jakarta-import-guard.json`
2. In short: when the **agent** saves a `.java` file, the `grep` prints Jakarta EE imports still on
   `javax.*` to stderr and exits 1, so the agent gets them. It reports, never blocks; JDK packages
   such as `javax.sql` pass. It ships off: stages 0–1 use `javax.*`.

<details><summary>Background: the guard field by field, and why JDK javax.* packages are excluded</summary>

| Field | Value | What it means |
|---|---|---|
| `trigger` | `PostFileSave` | Runs after a file is saved. The docs: "File triggers respond only to changes made by the agent. Manual editor changes do not trigger File Create, File Save, or File Delete hooks." Your own edits are never checked. |
| `matcher` | `\\.java$` | For file events the matcher is a regex on the file path, so only Java files are checked. |
| `action.type` | `command` | A shell command in the project root. Command actions don't use credits; agent-prompt actions do. |
| `{{filePath}}` | inside the command | "The `{{filePath}}` template variable is available for file-related triggers." Kiro replaces it with the path of the saved file. (The command also receives session context as JSON on stdin; this hook doesn't need it.) |
| `grep … 1>&2` | | Matching import lines are printed to **stderr**. |
| `exit 1` | when a line matches | Per the docs, exit code 0 adds stdout to the agent's context, and any other exit code sends **stderr** to the agent. A finding therefore reaches the agent as an error report. |
| (no block) | | `PostFileSave` can't block anything; blocking (exit code 2) exists only for `PreToolUse`, `UserPromptSubmit` and `PreTaskExec`. The guard reports; the agent fixes. |
| (no `timeout`) | | The 60-second default is plenty for `grep`. |
| `enabled` | `false` | Shipped off: in stages 0 and 1, `javax.*` imports are correct, so the guard would flag every file. |

**Why JDK `javax.*` packages are excluded.** Only Java EE / Jakarta EE APIs moved to `jakarta.*`.
Packages such as `javax.sql`, `javax.crypto`, `javax.net`, `javax.naming`, `javax.security.auth`,
`javax.management`, `javax.transaction.xa` and the JAXP part of `javax.xml` belong to the JDK and keep
their names; renaming them breaks the build. So the regex names the Jakarta EE packages one by one
instead of matching every `javax.`:

- whole packages: `persistence`, `validation`, `servlet`, `inject`, `jms`, `mail`, `websocket`, `ejb`,
  `faces`, `el`, `xml.bind` (JAXB), `xml.ws` (JAX-WS), `ws.rs` (JAX-RS);
- `javax.annotation.PostConstruct`, `PreDestroy`, `Resource` and `javax.annotation.security.*`
  (but not `javax.annotation.Nonnull` or `javax.annotation.processing`);
- `javax.transaction.` followed by a class name or `*`, so `javax.transaction.Transactional` matches
  and the JDK's `javax.transaction.xa` does not.

It's the same list as in the jakarta skill and `migration-standards.md`.

Verified in the 2026-10-10 dry run (the command run as a plain shell command on Linux): it exits 1 on
a file with `javax.persistence` imports and 0 on the same file with `jakarta` ones. That run didn't
cover whether and when Kiro fires the hook.

Docs: [Hooks](https://kiro.dev/docs/hooks/) · [Hook types](https://kiro.dev/docs/hooks/types/) ·
[Hook actions](https://kiro.dev/docs/hooks/actions/) ·
[Hooks in IDE 1.0](https://kiro.dev/docs/ide/whats-new-v1/hooks/)

</details>

3. Dry-run the command on `User.java`, and once on JDK-only imports:

   ```bash
   grep -nE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])' src/main/java/com/example/usermanagement/entity/User.java
   printf 'import javax.sql.DataSource;\nimport javax.crypto.Cipher;\nimport javax.transaction.xa.XAResource;\n' | grep -cE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])'
   ```

**Verify:** the first command lists 11 `javax.persistence` and `javax.validation` import lines; the
second prints `0`.

**Checkpoint:** nothing changed.

### Exercise 1.3: Enable the guard (3 minutes)

**Goal:** from now on, every Java file the agent saves is checked.

**Steps:** do this yourself (agent writes to `.kiro/hooks/` always ask): click the **eye icon** next
to `jakarta-import-guard` in **Agent Hooks**, or set `"enabled": true` in its JSON file.

**Verify:** `git diff .kiro/hooks/` shows `"enabled": true` and the panel shows it enabled (eye icon
left the file unchanged? the panel state counts).

<details><summary>Background: where the eye icon stores its state</summary>

When the agent writes into `.kiro/hooks/`, Kiro always asks for approval, even with allow rules.
That's why you toggle the hook yourself.

> Verify: if you used the eye icon and `git diff` shows nothing, your build stores the toggle outside
> the file. The panel state is what counts for today. To share the setting with your team, set it in
> the JSON file.

Docs: [Managing hooks](https://kiro.dev/docs/hooks/management/) ·
[Permissions](https://kiro.dev/docs/permissions/)

</details>

**Checkpoint** (skip if `git status` is clean)

```bash
git add .kiro/hooks/jakarta-import-guard.json
git commit -m "Module 3: enable jakarta-import-guard"
```

---

## Part 2: Quick Spec and the parent bump (13 minutes)

### Exercise 2.1: Pause the verify hook while the build is meant to be red (1 minute)

**Goal:** stop `verify-after-spec-task` from reporting failures you expect.

Until Part 4 the code can't compile; the hook would hand those errors to the agent as work, out of
order and skill-less.

**Steps:** **Agent Hooks** → eye icon next to `verify-after-spec-task` (off). You turn it on again in
Exercise 4.3, step 6.

**Verify:** `verify-after-spec-task` disabled, `jakarta-import-guard` enabled.

**Checkpoint:** none.

<details><summary>Background: why pause the hook, and what the toggle may change</summary>

The `PostTaskExec` hook would run Maven after the task, fail, and hand the compile errors to the agent
as something to fix: the jakarta and security work, out of order and without the skills. A guard
helps when the expected state is green.

If the toggle changed the JSON file, that's fine; it's back to enabled before the end of Part 4.

</details>

### Exercise 2.2: Plan the stage with Quick Spec (7 minutes)

**Goal:** a reviewed `requirements.md`, `design.md` and `tasks.md` under `.kiro/specs/`.

Quick Spec writes all three in one pass, without approval gates: fine here, because the playbook
defines the stage and you review before any task runs.

<details><summary>Background: what the docs say about Quick Spec</summary>

Quick Spec "is a session mode that auto-generates requirements, design, and tasks in a single pass",
without approval gates. The docs add a caveat: "For features where requirements quality is critical -
compliance-sensitive domains, high-stakes systems, unfamiliar territory - a standard Feature Spec with
explicit review gates is usually the better fit." For a production service, prefer a Feature spec
(Requirements-First), as in Module 2. If you want the gates today, start a **Spec** session instead and
send the same prompt.

Docs: [Quick Spec](https://kiro.dev/docs/specs/quick-spec/) · [Specs](https://kiro.dev/docs/specs/) ·
[Feature specs](https://kiro.dev/docs/specs/feature-specs/) ·
[Specs best practices](https://kiro.dev/docs/specs/best-practices/)

</details>

**Steps**

1. With a clean `git status`, start a new session (**+** in the chat panel) and choose **Quick Spec**
   on **Let's build**, or type `/quick-spec`.
2. Send the prompt. Answer clarifying questions in one line (for example `1=a, 2=b`).
3. Review the files; fix missing, merged or misordered tasks in `tasks.md`, then **Sync Files**.

**Ask Kiro**

```text
#migration-playbook Create a spec named spring-boot-3-upgrade for stage 2: Spring Boot 2.7.18 to 3.5.16 on Java 21 (Jakarta EE 10), following the playbook's stage 2 items and migration-standards. Write the requirements in EARS form and include: mvn -B clean verify passes on JDK 21; Tests run stays 14; no Jakarta EE API is imported from javax.*; security behaviour is unchanged (401 for unauthenticated requests to /api/users, CSRF ignored only for /api/**, BCrypt passwords, no hard-coded passwords). Create exactly these tasks, one concern each, in this order:
1. pom.xml only: set the spring-boot-starter-parent version to 3.5.16; if there is a byte-buddy.version override, remove it and its comment (3.5.16 manages Byte Buddy itself); add org.springframework.boot:spring-boot-properties-migrator with runtime scope and a comment saying it is temporary; update the parent comment and the description element for stage 2, and drop pom.xml comments that only explain stage-1 changes. The code is expected not to compile after this task (javax.* imports, WebSecurityConfigurerAdapter). Do not change any Java file in this task.
2. javax.* to jakarta.* using the jakarta-namespace-migration skill, without touching SecurityConfig.java.
3. SecurityConfig to a SecurityFilterChain bean with the lambda DSL using the spring-security-lambda-dsl skill; the web-layer tests keep their assertions.
4. Rename the configuration keys that spring-boot-properties-migrator reports at startup.
5. JUnit 4 to JUnit Jupiter for both test classes, then remove junit-vintage-engine and junit:junit.
6. Remove explicit hibernate.dialect properties, return ProblemDetail from ApiExceptionHandler, record remaining deprecation warnings in MIGRATION-NOTES.md, and remove spring-boot-properties-migrator.
Do not run Maven yourself after a task; the verify hook runs mvn -B clean verify and reports the Tests run line. Quote that line in your summary. Do not invent version numbers.
```

**Verify**

```bash
ls .kiro/specs/spring-boot-3-upgrade/
git status --short
```

Look for: three new files (other folder name? use it wherever this module says
`spring-boot-3-upgrade`); six tasks in your order; task 1 `pom.xml` only, red build expected; the
migrator temporary, removed last; EARS requirements (`WHEN … THE SYSTEM SHALL …`) with the count and
the four security behaviours; no versions except 3.5.16 and Java 21.

**Checkpoint**

```bash
git add .kiro/specs
git commit -m "Module 3: stage 2 spec (Quick Spec)"
```

### Exercise 2.3: Run task 1: the 3.5.16 parent and the properties migrator (5 minutes)

**Goal:** a reviewed single-file parent bump, and a compiler-made to-do list.

**Steps**

1. In `tasks.md`, click the first task item (the paused hook runs no build afterwards).
2. **Accept** `pom.xml` hunks that match task 1; **reject** any `.java` hunk.

<details><summary>Expected shape of the new dependency</summary>

```xml
<!-- Temporary: reports renamed configuration keys at startup. Remove before tagging stage-2. -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-properties-migrator</artifactId>
    <scope>runtime</scope>
</dependency>
```

Accept: parent `3.5.16`, any `byte-buddy.version` override and its comment gone, the migrator added,
the parent comment and `<description>` updated, stage-1-only comments removed.

</details>

**Verify**

```bash
grep -nE "<version>3\.5\.16|byte-buddy|properties-migrator" pom.xml
mvn -B dependency:tree -Dincludes=org.springframework:spring-core,org.springframework.security:spring-security-core,org.hibernate.orm:hibernate-core,net.bytebuddy:byte-buddy
mvn -B -q clean compile | grep -oE "[A-Za-z]+\.java" | sort -u
```

Look for:

- Parent `3.5.16`, the migrator, no `byte-buddy` line: the stage-1 reference has no override, and
  if you added one in Module 2, 3.5.16 now manages that version itself (`pom-rules.md`).
- `spring-core` 6.2.19, `spring-security-core` 6.5.11, `hibernate-core` 6.6.53.Final (new group
  `org.hibernate.orm`), `byte-buddy` 1.17.8. (No `-q` on `dependency:tree`: it prints at INFO.)
- Errors in `User.java`, `UserController.java`, `RequestIdFilter.java`, `SecurityConfig.java`: your
  to-do list for Parts 3 and 4. Without `clean`, Maven may list none.

<details><summary>Background: notes on these checks</summary>

- Clicking the task item moves its status to in progress, then done.
- 1.17.8 is also the version Module 2's fallback override pins (only if an error named Byte Buddy);
  the parent now manages it, so such a pin has no reason left (`pom-rules.md`). The 2026-10-10 dry
  run needed no override at stage 1 (Corretto 21).
- `dependency:tree` doesn't need the code to compile. Don't add `-q` to it: the tree is printed at
  INFO level, which `-q` hides.
- The compile errors in `User.java`, `UserController.java` and `RequestIdFilter.java` come from
  `javax.*` imports; the one in `SecurityConfig.java` from `WebSecurityConfigurerAdapter`.

</details>

**Checkpoint**

```bash
git add -A
git commit -m "Stage 2, task 1: Spring Boot 3.5.16 parent and properties migrator (does not compile yet)"
```

A red commit on `workshop` is fine; the `stage-2` tag must be green.

### Exercise 2.4 (optional, outside the time box): Predict the migrator's report (2 minutes)

You predict from the migration guide what the migrator will report at startup in Exercise 4.3.

<details><summary>Optional exercise: predict what the properties migrator will report</summary>

**Goal:** know what the migrator does, when you'll see its report, and what it can't see.

The 3.0 guide: "Spring Boot provides a spring-boot-properties-migrator module." The 4.0 guide describes
the same module: "this will not only analyze your application's environment and print diagnostics at
startup, but also temporarily migrate properties at runtime for you." It reports **at startup**, so you
can't read its report until the application compiles and starts. You'll do that in Exercise 4.3.
Predict it now.

**Ask Kiro**

```text
#url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide Which keys in src/main/resources/application.properties and src/main/resources/application-postgres.properties are renamed or removed in Spring Boot 3, according to this guide? Quote the guide for each one. Answer only; do not change any files.
```

**Verify**

```bash
grep -n "max-http" src/main/resources/application.properties
```

Look for: the answer should name `server.max-http-header-size` and quote the guide:
"server.max-http-header-size has been deprecated and a replacement, server.max-http-request-header-size,
has been introduced. Both properties now only apply to the request header size".

Two things to remember:

- **Don't rename it yet.** You want to see the migrator catch it. That's how you learn what it catches
  in services where nobody planted the trap.
- **The migrator only knows Spring Boot's own keys.** `spring.jpa.properties.hibernate.dialect` is
  passed straight through to Hibernate, so the migrator won't mention it. Part 6 handles it.
- **Reported doesn't mean migrated.** Predict, too, whether the migrator will map this key to its
  replacement at runtime. Exercise 4.3 shows the answer.

**Checkpoint:** nothing changed.

Docs: [Chat: context providers (`#url`)](https://kiro.dev/docs/ide/chat/)

</details>

---

## Part 3: Jakarta namespace with a shipped skill (22 minutes)

A skill (`.kiro/skills/<name>/SKILL.md`) loads only its name and description up front; the rest
loads when a request matches the description, or when you type `/` and its name.

<details><summary>Background: how skills activate, in the docs' words</summary>

Per the docs: "At startup, Kiro loads only the name and description of each skill". The full
instructions load when the skill activates, in one of two ways:

- **Automatically:** "Kiro matches your request against skill descriptions and loads the relevant
  skill".
- **As a slash command:** "Type / followed by the skill name to invoke it directly".

Docs: [Skills](https://kiro.dev/docs/skills/) ·
[Slash commands](https://kiro.dev/docs/ide/chat/slash-commands/)

Why Autopilot here and Supervised in Part 4: match the autonomy to the risk.

</details>

**Autonomy: Autopilot.** Renaming imports is mechanical, and the compiler, the guard and git check
it. Part 4 (security) goes back to Supervised.

### Exercise 3.1 (optional, outside the time box): How a skill gets picked (5 minutes)

You describe the jakarta task without naming the skill, and see whether the description makes Kiro
pick it.

<details><summary>Optional exercise: see a skill description do its job</summary>

**Goal:** see the description do its job.

**Steps**

1. Look at the skill's front matter. The `description` is what Kiro matches your requests against:

   ```bash
   sed -n '1,4p' .kiro/skills/jakarta-namespace-migration/SKILL.md
   ```

2. Type `/` in the chat input. The menu lists `jakarta-namespace-migration` and
   `spring-security-lambda-dsl`. Don't select either.
3. Start a new session (Default agent) and send the prompt below. It describes the task without
   naming the skill.

**Ask Kiro**

```text
I need to move this service's Java EE imports from javax.* to jakarta.* for Spring Boot 3. Is there a workspace skill for that? If so, use it and list, from the skill, which javax packages move, which must not be touched, and which files in src/ are affected. Answer only; do not change any files.
```

**Verify**

```bash
sed -n '/## 1/,/## 2/p' .kiro/skills/jakarta-namespace-migration/SKILL.md
grep -rlE '^import javax\.' src
```

Look for: the answer should name `jakarta-namespace-migration`, repeat its move table and its "Do not
touch" list, and name the three files `entity/User.java`, `controller/UserController.java` and
`web/RequestIdFilter.java`.

> Verify: the docs describe how skills activate, not how the chat shows it. If the answer doesn't
> mention the skill, it may have answered from general knowledge. That's why Exercise 3.3 invokes the
> skill explicitly.

**Checkpoint:** nothing changed (`git status`).

</details>

### Exercise 3.2: Watch the guard catch a leftover (6 minutes)

**Goal:** see a `PostFileSave` hook feed a finding back to the agent.

**Steps**

1. Switch to **Autopilot** (chat switch, or Settings → Agent → Agent Autonomy,
   `kiroAgent.agentAutonomy`), with a clean `git status`.
2. Send this deliberately incomplete edit.

**Ask Kiro**

```text
In src/main/java/com/example/usermanagement/entity/User.java, change only the javax.persistence imports to jakarta.persistence. Leave every other line unchanged, including the javax.validation imports. Then stop and tell me, word for word, whether a hook reported anything after you saved the file.
```

**Verify**

```bash
git diff --stat
grep -n "^import javax" src/main/java/com/example/usermanagement/entity/User.java
```

Look for: only `User.java` changed, its three `javax.validation.constraints` imports left. The agent
should quote the guard's lines; either way, read the guard's result in the hook log (Kiro output
panel). If the agent then fixes them, the loop works.

<details><summary>Example of the agent's reply (yours will differ)</summary>

```text
After the save, the jakarta-import-guard hook reported:
15:import javax.validation.constraints.Email;
16:import javax.validation.constraints.NotNull;
17:import javax.validation.constraints.Size;
Jakarta EE API still imported from javax.* - migrate it to jakarta.* (JDK packages such as javax.sql stay).
```

Some agents fix the three imports right away in response. That's the feedback loop working. Either
outcome is fine; Exercise 3.3 finishes the job. If nothing was reported, see Troubleshooting.

Docs: [Hook types: file triggers](https://kiro.dev/docs/hooks/types/) ·
[Hook troubleshooting](https://kiro.dev/docs/hooks/troubleshooting/)

</details>

**Checkpoint**

```bash
git add -A
git commit -m "Module 3: guard hook demo (User.java persistence imports)"
```

### Exercise 3.3: Migrate the namespace with the skill (13 minutes)

**Goal:** Jakarta EE imports on `jakarta.*`, JDK packages untouched, `SecurityConfig.java` left for
Part 4.

The prompt fences off `SecurityConfig.java`: the security skill's description ("Use when …
WebSecurityConfigurerAdapter, antMatchers, authorizeRequests or and() fail to compile") matches your
errors, so the agent could start task 3 early.

**Steps**

1. Stay in Autopilot. Type `/jakarta-namespace-migration`, select it, and type the rest of the prompt
   in the same message (other spec name? type `#spec` and pick it).
2. When the agent is idle, run the checks.

**Ask Kiro**

```text
/jakarta-namespace-migration #spec:spring-boot-3-upgrade Implement task 2. Follow the skill step by step: main and test sources, non-Java files, and pom.xml. Do not edit src/main/java/com/example/usermanagement/config/SecurityConfig.java; its WebSecurityConfigurerAdapter errors are task 3. Finish with the skill's final search (section 3, step 4). Do not run Maven; I compile the project myself, and it cannot pass until task 3 is done.
```

**Verify**

```bash
git diff --stat
grep -rnE '^import (static )?javax\.' src
grep -rhoE '^import jakarta\.[a-z]+' src | sort | uniq -c
grep -n "javax" pom.xml
mvn -B -q clean compile | grep -oE "[A-Za-z]+\.java" | sort -u
```

Look for: `User.java`, `UserController.java`, `RequestIdFilter.java` changed, `SecurityConfig.java`
not; no `import javax.` line;
`jakarta.persistence` 8, `jakarta.servlet` 4, `jakarta.validation` 4; no `javax` in `pom.xml` (delete
any leftover comment about removed pins); compile errors only in `SecurityConfig.java`. Another file?
Send `#terminal Fix the remaining javax errors outside SecurityConfig.java with the skill. Do not run Maven.`
and compile again. If the agent changed `SecurityConfig.java`, undo that file only:

```bash
git restore src/main/java/com/example/usermanagement/config/SecurityConfig.java
```

<details><summary>Background: notes on these checks</summary>

- `pom.xml` may also show a changed comment.
- No `import javax.` lines at all: this app happens to use no JDK `javax` packages. In your own
  services, imports such as `javax.sql.DataSource` stay, and that is correct.
- `jakarta.persistence` 8, `jakarta.servlet` 4, `jakarta.validation` 4 are the same counts the `javax`
  imports had.
- Module 2 already removed the explicit `javax.servlet`, `javax.persistence` and `validation-api`
  dependencies; if your `pom.xml` still declares any of them, the skill removes them now.
- If the agent changed `SecurityConfig.java` anyway, restore it: Part 4 migrates it under review.

</details>

**Checkpoint**

```bash
git add -A
git commit -m "Stage 2, task 2: javax to jakarta (SecurityConfig still pending)"
```

### Exercise 3.4: Back to Supervised, and what just protected you (3 minutes)

**Goal:** leave Autopilot deliberately.

**Steps:** switch back to **Supervised**. Your safety nets here were the compiler, the guard, the
skill's steps, git and your prompt boundary; the table shows what each can't catch.

<details><summary>Background: the safety nets in this part, and what each can't catch</summary>

| Safety net | Caught | Can't catch |
|---|---|---|
| Compiler | Every `javax.*` import of an API no longer on the classpath | String literals (for example JPA hint names) and XML files such as `persistence.xml` |
| `jakarta-import-guard` | Leftover Jakarta EE imports in any Java file the agent saves | Your own edits, files the agent didn't save, non-Java files |
| The skill's own steps | Non-Java files, `pom.xml` pins, the final search | Whatever the agent skips; check its report |
| git | Anything, as long as you committed first | Nothing you didn't commit |
| Your prompt boundary | The security skill starting early | Nothing by itself; the agent has to respect it |

Docs: [Autopilot and Supervised mode](https://kiro.dev/docs/ide/chat/autopilot/) ·
[Checkpoints](https://kiro.dev/docs/checkpoints/)

</details>

**Verify:** the Autopilot switch is off.

**Checkpoint:** nothing to commit.

---

## Part 4: Spring Security 6 in Supervised mode (25 minutes)

`SecurityConfig` still extends `WebSecurityConfigurerAdapter`, removed in Spring Security 6. You move
it to a `SecurityFilterChain` bean with the lambda DSL, which Spring Security 7 requires. A security
change can compile and still change who gets in, so you review each hunk in **Supervised** mode.

<details><summary>Background: the sources for the lambda DSL and Supervised mode</summary>

"The Lambda DSL is the preferred way to configure Spring Security, the prior configuration style will
not be valid in Spring Security 7 where the usage of the Lambda DSL will be required."
([Spring Security 6.5: Preparing for 7.0](https://docs.spring.io/spring-security/reference/6.5/migration-7/configuration.html))

Supervised mode, per the docs: "Kiro yields for your approval after each turn that contains file
edits", and each hunk has **Accept**, **Reject** and **Chat inline**.

</details>

### Exercise 4.1: Migrate `SecurityConfig`, one hunk at a time (10 minutes)

**Goal:** the same security rules, as beans and lambdas, reviewed line by line.

**Steps**

1. In **Supervised** mode with a clean tree, type `/spring-security-lambda-dsl`, select it, and type
   the rest of the prompt.
2. Review every hunk against the table; use **Chat inline** to ask before you decide.

**Ask Kiro**

```text
/spring-security-lambda-dsl #spec:spring-boot-3-upgrade Implement task 3 for src/main/java/com/example/usermanagement/config/SecurityConfig.java only. Replace WebSecurityConfigurerAdapter with a SecurityFilterChain bean using the lambda DSL, and the in-memory users with an InMemoryUserDetailsManager bean. Keep every rule in its original order, keep BCrypt and the generated-password fallback, and do not add permitAll rules or disable CSRF. Do not change any test, and do not run Maven; I compile it myself.
```

**Review each hunk**

| Accept if | Reject, or ask with Chat inline, if |
|---|---|
| No `extends` any more; `@Configuration` and `@EnableWebSecurity` kept | A rule missing, reordered or loosened |
| `@Bean SecurityFilterChain securityFilterChain(HttpSecurity http)` returns `http.build()` | A new `permitAll()`, or `csrf` disabled instead of ignored for `/api/**` |
| `csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))` | `antMatchers`, `authorizeRequests` or `.and()` left |
| `authorizeHttpRequests`: `/api/public/**` permitAll, `/api/users/**` authenticated, then `anyRequest().authenticated()` | A password literal anywhere |
| `httpBasic(Customizer.withDefaults())` | `NoOpPasswordEncoder` or `{noop}` |
| A `UserDetailsService` bean: `new InMemoryUserDetailsManager(...)`, BCrypt passwords from `passwordOrGenerated(...)` | Tests or other classes edited |

Two judgement calls (the reference makes both) are in the box below.

<details><summary>Judgement calls, and the reference shape of the filter chain (solutions/stage-2-boot35-java21/)</summary>

- The `@Value` fields may move into the bean method's parameters. Either form is fine.
- The agent may change `isEmpty()` to `isBlank()` in `passwordOrGenerated`. That's a small behaviour
  change: a password made only of spaces now gets a generated one. The reference solution makes it;
  accept it only if you agree.

Reference shape (the agent's layout may differ):

```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/public/**").permitAll()
            .requestMatchers("/api/users/**").authenticated()
            .anyRequest().authenticated())
        .httpBasic(Customizer.withDefaults());
    return http.build();
}
```

</details>

**Verify**

```bash
git diff --stat
grep -nE "WebSecurityConfigurerAdapter|antMatchers|authorizeRequests|\.and\(\)|inMemoryAuthentication" src/main/java/com/example/usermanagement/config/SecurityConfig.java
grep -nE "SecurityFilterChain|ignoringRequestMatchers|requestMatchers|InMemoryUserDetailsManager|BCryptPasswordEncoder|passwordOrGenerated" src/main/java/com/example/usermanagement/config/SecurityConfig.java
mvn -B -q clean compile
```

Look for: only `SecurityConfig.java` changed, no output from the first `grep`, the new APIs in the
second, a silent compile.

<details><summary>Background: why the compile is silent and the guard quiet</summary>

With `-q`, a successful compile prints nothing. The guard hook stayed quiet because the file has no
`javax` imports.

</details>

**Checkpoint**

```bash
git add -A
git commit -m "Stage 2, task 3: SecurityFilterChain and lambda DSL"
```

### Exercise 4.2: The `@WebMvcTest` trap (8 minutes)

**Goal:** the web tests exercise **your** security configuration, not a default one.

**Steps**

1. Run the tests (JUnit 4 still runs on Vintage until Part 5):

   ```bash
   mvn -B clean verify | grep -E "Tests run:|expected" | tail -n 6
   ```

2. `invalidUserIsRejectedByBeanValidation` fails with `Status expected:<400> but was:<403>`
   (verified in the 2026-10-10 dry run, Corretto 21). Expect the other POST test,
   `validUserIsCreated`, to fail the same way (`<201>`, got `<403>`). Ask Kiro for the root cause first.

**Ask Kiro**

```text
#terminal The web-layer tests changed behaviour after the SecurityConfig migration. Explain the root cause before changing anything: which security configuration does @WebMvcTest(UserController.class) load now, and which did it load while SecurityConfig extended WebSecurityConfigurerAdapter? Then propose the smallest change to UserControllerTest that makes it exercise our SecurityConfig. Do not change assertions or production code, and wait for my go-ahead before editing.
```

**What's going on.** `@WebMvcTest` loads beans that *implement* `WebSecurityConfigurer` or
`SecurityFilterChain`. The old adapter class did; the new class only declares a bean, so the test gets
Boot's default security, which refuses token-less POSTs (403). Fix: `@Import(SecurityConfig.class)`.

<details><summary>Background: the @WebMvcTest javadoc, verbatim</summary>

The [`@WebMvcTest` javadoc for Spring Boot 3.5](https://docs.spring.io/spring-boot/3.5/api/java/org/springframework/boot/test/autoconfigure/web/servlet/WebMvcTest.html)
says "component scanning is limited to beans annotated with:" `@Controller`, `@ControllerAdvice` and
`@JsonComponent`, "as well as beans that implement:" a list that includes `Filter`,
`SecurityFilterChain` and `WebSecurityConfigurer`.

- The old `SecurityConfig` extended `WebSecurityConfigurerAdapter`, which is a `WebSecurityConfigurer`,
  so the slice picked it up.
- The new `SecurityConfig` is a plain `@Configuration` class. It *declares* a `SecurityFilterChain`
  bean but implements neither type, so the slice skips it.
- The javadoc goes on: "By default, tests annotated with @WebMvcTest will also auto-configure Spring
  Security and MockMvc". The test now runs against Spring Boot's default security, which doesn't
  ignore CSRF for `/api/**`. A POST without a CSRF token is refused with 403 before validation runs.
- `RequestIdFilter` is a `Filter`, so it's still picked up. That's why the `X-Request-Id` assertion
  keeps passing.

The javadoc also names the fix: "Typically @WebMvcTest is used in combination with @MockitoBean or
@Import to create any collaborators required by your @Controller beans."

Note that without the import, `unauthenticatedRequestIsRejected` passes against Spring Boot's default
security too, so a green web test alone proves nothing about your rules. The skill's section 4
describes the same trap.

The failing run. The first line is from the 2026-10-10 dry run (Corretto 21). That run predates
`validUserIsCreated`, so the second line and the totals are the expected result with 14 tests:

```text
[ERROR]   UserControllerTest.invalidUserIsRejectedByBeanValidation:... Status expected:<400> but was:<403>
[ERROR]   UserControllerTest.validUserIsCreated:... Status expected:<201> but was:<403>
[ERROR] Tests run: 14, Failures: 2, Errors: 0, Skipped: 0
```

Docs: [Chat: context providers (`#terminal`)](https://kiro.dev/docs/ide/chat/) ·
[Autopilot: Chat inline](https://kiro.dev/docs/ide/chat/autopilot/)

</details>

3. If Kiro proposes `@Import(SecurityConfig.class)`, reply
   `Go ahead. Do not run Maven; I run the tests myself.` Accept only the import and the annotation.

**Verify**

```bash
grep -n "@Import" src/test/java/com/example/usermanagement/controller/UserControllerTest.java
git diff --stat
mvn -B clean verify | grep "Tests run:" | tail -n 1
```

Look for: the `@Import`, only `UserControllerTest.java` changed (no assertion), and
`Tests run: 14, Failures: 0, Errors: 0, Skipped: 0`.

**Checkpoint**

```bash
git add -A
git commit -m "Stage 2, task 3: web test imports SecurityConfig"
```

### Exercise 4.3: Re-check behaviour on the running app, and read the migrator report (7 minutes)

**Goal:** re-check security on a real server, act on the migrator's report, re-enable the verify
hook.

**Steps**

1. Start the app and keep the log:

   ```bash
   mvn -B spring-boot:run | tee target/run.log
   ```

2. After `Started UserManagementApplication`, in a **second** terminal (`sample-app/`), read the
   migrator report and the admin password (or use your `APP_ADMIN_PASSWORD`):

   ```bash
   grep -n -B4 -A3 "max-http-header-size" target/run.log
   grep "Generated password for this run" target/run.log
   ```

   Look for: an **ERROR** from `PropertiesMigrationListener` about keys "no longer supported", with
   `Key: server.max-http-header-size` and a `Reason` naming `server.max-http-request-header-size`
   (as in the 2026-10-10 dry run). The app still starts. Copy those lines; note any
   `hibernate.dialect` warning.

3. Check the behaviour:

   ```bash
   PW=<admin password from the log>
   curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/users
   curl -s -o /dev/null -w "%{http_code}\n" -u "admin:$PW" http://localhost:8080/api/users
   curl -s -o /dev/null -w "%{http_code}\n" -u "admin:$PW" -H 'Content-Type: application/json' -d '{"name":"J","email":"not-an-email"}' http://localhost:8080/api/users
   curl -s -o /dev/null -w "%{http_code}\n" -u "admin:$PW" http://localhost:8080/api/users/
   ```

   Expect `401` (no credentials), `200` (admin: the BCrypt password fallback works), `400` (invalid
   POST without a CSRF token: CSRF still ignored for `/api/**`), `404` (trailing slash; Part 6). The
   2026-10-10 dry run got exactly these on stage 2; the trailing slash still gave 200 on stage 1.

4. Stop the app with **Ctrl+C**, then send the prompt with your copied lines in place of `<paste>`.

**Ask Kiro**

```text
#spec:spring-boot-3-upgrade Implement task 4. Here is the spring-boot-properties-migrator report from startup: <paste>. Rename each reported key in src/main/resources/application*.properties to the replacement key named in its Reason line, keep the values, and update the comment above each key. Change nothing else, and do not run Maven.
```

5. Accept the hunk if it changes only that key and its comment.
6. Turn `verify-after-spec-task` back **on** with the eye icon. It stays on to the end of the module.

<details><summary>Background: the dispatch-type rule, and why you rename instead of relying on the migrator</summary>

The invalid `POST` row: "Spring Security 6.0 applies authorization to every dispatch type" (3.0
guide), so the error dispatch is authorized too; a `401` here would point at that. The four checks
match the skill's section 3, "Behaviour to re-check".

In the Verify step, comments may still mention the old key name; only the key itself must change.

The 4.0 guide says the migrator can "temporarily migrate properties at runtime", but not this key.
Verified in the 2026-10-10 dry run (Boot 3.5.16): it goes into the ERROR report of keys that are "no
longer supported", with the reason "Replacement key 'server.max-http-request-header-size' uses an
incompatible target type". The old key is not mapped, so your 16KB value has no effect until you
rename the key yourself. Keys the migrator can map are reported separately, as a warning, and even
those only for the current run: once you remove the migrator, an old key that Spring Boot no longer
binds is ignored without any message. So rename every reported key now.

Docs: [Hooks: managing](https://kiro.dev/docs/hooks/management/) ·
[Specs best practices (`#spec`)](https://kiro.dev/docs/specs/best-practices/)

</details>

**Verify**

```bash
grep -rn "^server.max-http" src/main/resources
git status --short
```

Look for: only `server.max-http-request-header-size=16KB` as a key; `application.properties` changed
(plus the hook file, if the eye icon writes to it); both hooks enabled.

**Checkpoint**

```bash
git add -A
git commit -m "Stage 2, task 4: renamed header-size property"
```

---

## Part 5: Write your own skill: JUnit 4 to Jupiter (25 minutes)

You'll migrate JUnit 4 tests in every service, so write the "how" once, as a skill. Its
`description` says what it does **and when to use it**; that drives activation.

<details><summary>Background: the docs' file rules, and why a skill instead of steering</summary>

Rules for the file: `.kiro/skills/<name>/SKILL.md`; `name` matches the folder; `description` up to
1,024 characters, saying what the skill does and when to use it. `$ARGUMENTS` placeholders are
substituted only in the CLI, so write the skill for "the test classes in this workspace", not for
parameters.

Front matter `name`, per the docs: "Must match folder name. Lowercase letters, numbers, and hyphens
only (max 64 chars)."

`test-rules.md` already says **what** the target is (JUnit Jupiter from stage 2). A skill says
**how**, step by step, including how to prove that no test got lost. And unlike an `always` steering
file, it costs almost no context until it's needed: only its name and description load up front.

</details>

**The count is the proof.** With `junit-vintage-engine` present, JUnit 4 and Jupiter tests both run.
Only after you remove it and `junit:junit` does a missed class fail to compile; the total must still be
14. The verify hook passes whenever the build passes; only the count shows a drop.

### Exercise 5.1: Write the skill (10 minutes)

**Goal:** a skill any agent session can follow to migrate JUnit 4 tests safely.

**Steps**

1. Create `.kiro/skills/junit4-to-jupiter/SKILL.md` (`mkdir -p` the folder) from this skeleton,
   front matter on line 1:

   ```markdown
   ---
   name: junit4-to-jupiter
   description: Migrate JUnit 4 tests to JUnit Jupiter without losing a test, then remove junit-vintage-engine and junit:junit. Use when upgrading tests for Spring Boot 3 or 4, or when org.junit.Test, @RunWith or org.junit.Assert appear in test sources.
   ---

   # JUnit 4 → JUnit Jupiter

   ## 0. Record the baseline
   ## 1. Map annotations and APIs
   | JUnit 4 | JUnit Jupiter |
   |---|---|
   | `@Before` | `@BeforeEach` |
   ## 2. Apply, one class at a time
   ## 3. Remove JUnit 4 from the build
   ## 4. Never
   ```

2. Complete it yourself. It must cover:
   - `@Before`/`@After` → `@BeforeEach`/`@AfterEach`; a null-only teardown can go (Jupiter creates a
     new test instance per method).
   - `@Test(expected = …)` → `assertThrows` around only the throwing call.
   - `org.junit.Assert` → `org.junit.jupiter.api.Assertions`; the message parameter moves to last.
   - `@RunWith(MockitoJUnitRunner.class)` → `@ExtendWith(MockitoExtension.class)`
     (`org.mockito.junit.jupiter.MockitoExtension`).
   - Drop `@RunWith(SpringRunner.class)`: `@WebMvcTest` already carries the Spring extension.
   - `public` is optional (package-private is the Jupiter convention).
   - Verification: baseline ("Tests run" and `@Test` count), per-class runs, removing
     `junit-vintage-engine` and `junit:junit`, a `grep` for leftover `org.junit.` imports, same total.
   - "Never": no deleted, emptied or `@Disabled` tests, no loosened assertions, no production code.
   - `@MockBean` and `@Import` stay (`@MockBean` is Module 4).

   Running late? Copy the reference skill and read it:

   ```bash
   cp ../solutions/kiro-reference/skills/junit4-to-jupiter/SKILL.md .kiro/skills/junit4-to-jupiter/SKILL.md
   ```

<details><summary>Background: more skeleton rows, and the javadoc lines behind the SpringRunner rule</summary>

Two more mapping rows that the original skeleton listed:

| JUnit 4 | JUnit Jupiter |
|---|---|
| `@Test(expected = X.class)` | `@Test` + `assertThrows(X.class, () -> ...)` around the throwing call only |
| `@RunWith(MockitoJUnitRunner.class)` | `@ExtendWith(MockitoExtension.class)` |

The `@WebMvcTest` javadoc shows that the annotation is itself annotated with
`@ExtendWith(org.springframework.test.context.junit.jupiter.SpringExtension.class)`, and says: "When
using JUnit 4, this annotation should be used in combination with @RunWith(SpringRunner.class)."

Docs: [Skills](https://kiro.dev/docs/skills/)

</details>

**Verify**

```bash
head -n 4 .kiro/skills/junit4-to-jupiter/SKILL.md
ls .kiro/skills/
```

Look for: `---` on line 1, `name: junit4-to-jupiter`, a `description` line, three skill folders, and
`junit4-to-jupiter` in the `/` menu (not listed? see Troubleshooting).

<details><summary>Background: when a new skill shows up in the / menu</summary>

> Verify: if the new skill isn't listed, check the folder name, the `name` value and that the front
> matter starts on line 1. The docs don't say whether a new skill appears without reopening the
> workspace; if it still doesn't show, reload the window.

</details>

**Checkpoint:** commit in Exercise 5.2.

### Exercise 5.2: Have Kiro review your skill (3 minutes)

**Goal:** a second pair of eyes before the skill drives an agent.

**Ask Kiro**

```text
#src/test/java Review .kiro/skills/junit4-to-jupiter/SKILL.md as a Kiro skill author. Is the front matter valid (name equals the folder name; the description says what the skill does and when to use it)? Does the body cover @Before/@After, @Test(expected) with assertThrows, Assert to Assertions including the message parameter order, MockitoJUnitRunner to MockitoExtension, removing SpringRunner, optional public modifiers, and verification by test count before and after removing junit-vintage-engine and junit:junit? Name anything in these two test classes that the skill does not cover. Answer only; do not change any files.
```

**Steps:** fix the gaps by hand. You're the author; the agent is the reviewer.

**Verify:** your section 3 ends with a test count compared to the baseline, not "the build passes"
(Module 2's Vintage trap).

**Checkpoint**

```bash
git add .kiro/skills/junit4-to-jupiter
git commit -m "Module 3: add junit4-to-jupiter skill"
```

### Exercise 5.3: Migrate both test classes with your skill (8 minutes)

**Goal:** JUnit Jupiter only, JUnit 4 gone from the build, `Tests run: 14`.

**Steps**

1. Stay in **Supervised**. Type `/junit4-to-jupiter`, select it, and type the rest of the first prompt.
2. Review the hunks: every `@Test` kept (renames are fine); `assertThrows` wraps only the service
   call, not the `when(...)`; no assertion, `verify(...)` or `@Disabled` change; the null-only
   `tearDown()` may go; `@MockBean`, `@WithMockUser` and `@Import` untouched.
3. Send the second prompt and accept the `pom.xml` hunks. Wait until the agent is idle.

**Ask Kiro**

```text
/junit4-to-jupiter #spec:spring-boot-3-upgrade Implement the first half of task 5: migrate both test classes in src/test/java to JUnit Jupiter, following the skill one class at a time. The baseline is Tests run: 14 (tag stage-1); use it instead of building it again, and report each class's test count from the skill's per-class runs. Keep every test scenario and assertion. Keep @MockBean, @WithMockUser and @Import(SecurityConfig.class) exactly as they are. Do not edit pom.xml or production code yet.
```

```text
Now finish task 5: remove org.junit.vintage:junit-vintage-engine and junit:junit from pom.xml as described in section 3 of the junit4-to-jupiter skill, and replace the Vintage comment with one line saying the tests use JUnit Jupiter only. Run the skill's leftover searches, but do not run Maven; I run the final build myself.
```

<details><summary>Alternative: run task 5 as a spec task, with the verify hook</summary>

Instead of the first prompt, click task 5 in `tasks.md`. Kiro can activate your skill automatically
when the task matches its description. The re-enabled `verify-after-spec-task` hook then runs
`mvn -B clean verify` and reports the `Tests run` line: read it in the Kiro output panel, or run the
build under **Verify** only after the hook has finished. Afterwards, ask "Which skills did you use for
task 5?" to find out whether your description did its job.

Docs: [Skills](https://kiro.dev/docs/skills/) · [Specs](https://kiro.dev/docs/specs/) ·
[Hooks](https://kiro.dev/docs/hooks/)

</details>

**Verify**

```bash
grep -rnE 'import (static )?org\.junit\.(Test|Before|After|BeforeClass|AfterClass|Ignore|Rule|Assert|Assume|runner)' src/test
grep -rnE '@RunWith|@Test\(' src/test
grep -nE 'junit-vintage-engine|<artifactId>junit</artifactId>' pom.xml
grep -rc "@Test" src/test/java
mvn -B clean verify | grep "Tests run:" | tail -n 1
```

Look for: no output from the first three commands, `@Test` counts 5 and 9, and
`Tests run: 14, Failures: 0, Errors: 0, Skipped: 0`. Lower? Don't commit; find the missing test with
`git diff stage-1 -- src/test`.

<details><summary>Example output, and a review note (yours will differ)</summary>

```text
src/test/java/com/example/usermanagement/controller/UserControllerTest.java:5
src/test/java/com/example/usermanagement/service/UserServiceTest.java:9
[INFO] Tests run: 14, Failures: 0, Errors: 0, Skipped: 0
```

The `@Test` counts are the same as at stage 1. In the hunk review, renaming `testCreateUser` to
`createUser` is fine, and so is deleting the `@After tearDown()` that only sets `testUser = null`.

</details>

**Checkpoint**

```bash
git add -A
git commit -m "Stage 2, task 5: JUnit Jupiter only (Tests run: 14)"
```

### Exercise 5.4: Improve the skill, and take it with you (4 minutes)

**Goal:** turn what you just reviewed into a better skill.

**Steps**

1. For each hunk you rejected or questioned in Exercise 5.3, add a line to "Never" or the mapping.
2. Borrow what you missed from the reference (for example the strict-stubs note):

   ```bash
   diff .kiro/skills/junit4-to-jupiter/SKILL.md ../solutions/kiro-reference/skills/junit4-to-jupiter/SKILL.md
   ```

<details><summary>Background: where else a skill can live</summary>

- **This repository:** `.kiro/skills/`, shared with your team through git.
- **All your projects:** `~/.kiro/skills/` (IDE and CLI). When names clash, "workspace skills take
  priority over global skills."
- **Other teams:** skills follow the open Agent Skills standard, and Kiro can import a skill from a
  GitHub subdirectory URL or a local folder. Module 4 packages skills into a power.

The reference also has an `@Rule ExpectedException` row worth borrowing.

Docs: [Skills](https://kiro.dev/docs/skills/) · [Powers](https://kiro.dev/docs/powers/)

</details>

**Verify:** `git diff` shows only your skill file changed.

**Checkpoint**

```bash
git add .kiro/skills/junit4-to-jupiter
git commit -m "Module 3: refine junit4-to-jupiter skill"
```

---

## Part 6: Clean up, record, tag `stage-2` (10 minutes)

### Exercise 6.1: Final cleanup task (5 minutes)

**Goal:** no explicit Hibernate dialects, `ProblemDetail` error bodies, and no migrator.

Hibernate 6 detects the dialect itself. `ProblemDetail` (RFC 9457) replaces the hand-rolled error
map, as in the stage-2 reference (in your own services, agree a new error body with clients first).
The migrator has done its job.

<details><summary>Background: dialects, trailing slashes and ProblemDetail</summary>

- **Hibernate dialects.** Boot 3.5.16 manages Hibernate 6.6. Hibernate 6 detects the dialect from the
  database connection, so `spring.jpa.properties.hibernate.dialect` (`H2Dialect`, and
  `PostgreSQL10Dialect` in the postgres profile) is usually unnecessary. The migrator only knows Spring
  Boot's own keys; this one is passed straight through to Hibernate, so the migrator doesn't mention
  it.

  > Verify: the Spring Boot 3.0 migration guide doesn't cover dialects. It only says "Spring Boot 3.0
  > uses Hibernate 6.1 by default. Please see the Hibernate 6.0 and 6.1 migration guides to learn how
  > this may affect your application." Check dialect detection and the version-specific PostgreSQL
  > dialects in the Hibernate ORM 6 migration guides, and watch the startup log for a Hibernate warning
  > about the dialect property. The postgres profile isn't covered by the tests; if you use it, start
  > the app with it once.

- **Trailing slashes.** "As of Spring Framework 6.0, the trailing slash matching configuration option
  has been deprecated and its default value set to false." So "\"GET /some/greeting/\" doesn't match
  anymore by default and will result in an HTTP 404 error" (3.0 guide). You saw this in Exercise 4.3.
  Verified in the 2026-10-10 dry run: `GET /api/users/` returns 200 on stages 0–1 and 404 on stages 2–3.
  The app needs no change; clients that call `/api/users/` must drop the slash. The guide shows a
  temporary `configurer.setUseTrailingSlashMatch(true)` in a `WebMvcConfigurer`, but the option itself
  is deprecated, so don't build on it.
- **`ProblemDetail`.** Spring Framework 6 can return RFC 9457 problem details instead of the
  hand-rolled `{status, error}` map in `ApiExceptionHandler`. Clients see a different error body, so
  treat it as an API change, not a refactoring.
- **The migrator.** "Once you're done with the migration, please make sure to remove this module from
  your project's dependencies." (3.0 guide)

</details>

**Steps:** with a clean tree, send the prompt and review the hunks.

**Ask Kiro**

```text
#spec:spring-boot-3-upgrade Implement the code part of task 6. 1) Remove spring.jpa.properties.hibernate.dialect from application.properties and application-postgres.properties, and update the JPA comment. 2) In ApiExceptionHandler, return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, ex.getMessage()) instead of the hand-rolled map. 3) Remove spring-boot-properties-migrator from pom.xml. Change nothing else, and do not run Maven; I run the build myself.
```

**Verify**

```bash
grep -rn "^spring.jpa.properties.hibernate.dialect" src/main/resources
grep -n "properties-migrator" pom.xml
grep -n "ProblemDetail" src/main/java/com/example/usermanagement/controller/ApiExceptionHandler.java
mvn -B clean verify | grep "Tests run:" | tail -n 1
```

Look for: no output from the first two commands, `ProblemDetail` in the handler, `Tests run: 14`
with no failures.

**Checkpoint:** commit together with Exercise 6.2.

### Exercise 6.2: Record deprecations for Module 4, and tag `stage-2` (5 minutes)

**Goal:** a green, tagged stage 2, both hooks on, a to-do list for Module 4.

**Steps**

1. List the deprecation warnings (`clean` recompiles everything, so all show):

   ```bash
   mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true | grep -iE "deprecat|removal"
   ```

   Look for: `MockBean` in `UserControllerTest` (deprecated since Boot 3.4, removed in Boot 4).

2. Add `Stage 2 → 3: deprecations to fix first` to `MIGRATION-NOTES.md`: one line per warning (file,
   API, replacement if known, else "unverified").
3. In `tasks.md`, choose **Sync Files**.
4. Set the "current state" line in `.kiro/steering/tech.md` to Java 21, Spring Boot 3.5.16.
5. In **Agent Hooks**, check both hooks are enabled; turn the verify hook on if it is still off.
6. Commit and tag:

   ```bash
   git add -A
   git commit -m "Stage 2 complete: Spring Boot 3.5.16, Jakarta EE 10, JUnit Jupiter"
   git tag -a stage-2 -m "Stage 2: Java 21, Spring Boot 3.5.16, Tests run: 14"
   git show stage-2 --no-patch
   ```

<details><summary>Background: the @MockBean deprecation and removal, verbatim</summary>

The Spring Boot 3.4 release notes, section "Deprecation of @MockBean and @SpyBean" (quote checked
against the [Spring Boot 3.4 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.4-Release-Notes)
on 2026-10-09): "@MockBean and @SpyBean have been deprecated in favor of @MockitoBean and
@MockitoSpyBean in Spring Framework."

Boot 4 drops it: "Spring Boot's @MockBean and @SpyBean support has been removed in this release"
([4.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide)).

This is why the playbook's stage 3 starts with "Fix every deprecation warning from stage 2 first".

Sync Files, per the docs: "Kiro will automatically mark completed tasks."

Docs: [Specs best practices (Sync Files)](https://kiro.dev/docs/specs/best-practices/) ·
[Steering](https://kiro.dev/docs/steering/) · [Custom agents](https://kiro.dev/docs/custom-agents/)

</details>

<details><summary>Optional: compare with the reference solution, and a reviewer pass</summary>

```bash
diff ../solutions/stage-2-boot35-java21/pom.xml pom.xml
diff -r ../solutions/stage-2-boot35-java21/src src
```

Expect only cosmetic differences: comments, test method names, layout. If you skipped the optional
Module 2 Part 4, differences in `User`, `UserService` and `UserController` are expected. Any other
difference in a dependency, an import, a security rule or a property is worth a second look.

If you have time left, switch to the `migration-reviewer` agent and ask it to review
`git diff stage-1..stage-2 -- pom.xml src`. It has no write tool and is instructed not to modify
files, but it can run shell commands; run `git status` after the review.

</details>

**Checkpoint:** tag `stage-2` exists. **Hook states at the end of this module:**
`verify-after-spec-task` **on**, `jakarta-import-guard` **on**. Module 4 starts from this state.

---

## Checklist

<details><summary>Checklist: tick these off before you start Module 4</summary>

- [ ] `jakarta-import-guard` is enabled, and you can explain `PostFileSave`, `{{filePath}}`, why stderr
      reaches the agent, and why JDK `javax.*` packages are excluded.
- [ ] You watched the guard report a leftover `javax.validation` import back to the agent.
- [ ] A Quick Spec for stage 2 is committed under `.kiro/specs/`, and **Sync Files** marked the
      finished tasks.
- [ ] The parent is `3.5.16`; no `byte-buddy.version` override (removed if you added one in Module 2)
      and no `spring-boot-properties-migrator`.
- [ ] The guard regex finds no Jakarta EE `javax.*` import in `src/`, and no JDK package was
      renamed.
- [ ] `SecurityConfig` is a plain `@Configuration` class with a `SecurityFilterChain` bean (lambda DSL)
      and an `InMemoryUserDetailsManager` bean; no `antMatchers`, `authorizeRequests` or `.and()`.
- [ ] `UserControllerTest` has `@Import(SecurityConfig.class)`, and you can explain why.
- [ ] On the running app: 401 without credentials, 200 as admin, 400 for an invalid POST, 404 with a
      trailing slash.
- [ ] `server.max-http-request-header-size` replaces the old key: the migrator's ERROR report found
      it, and you renamed it (the migrator doesn't map it).
- [ ] `.kiro/skills/junit4-to-jupiter/SKILL.md` exists with valid front matter and is listed under `/`.
- [ ] The tests are JUnit Jupiter only; `junit-vintage-engine` and `junit:junit` are gone; Tests run is
      still 14.
- [ ] No `hibernate.dialect` properties; `ApiExceptionHandler` returns `ProblemDetail`; deprecations
      recorded in `MIGRATION-NOTES.md`.
- [ ] Both hooks are enabled: `verify-after-spec-task` and `jakarta-import-guard`.
- [ ] Tag `stage-2` exists and its message records `Tests run: 14`.

</details>

## Troubleshooting

<details><summary>Troubleshooting table: symptom, cause, fix</summary>

| Symptom | Cause | Fix |
|---|---|---|
| The guard never reports anything | Hook disabled; you edited the file yourself (file hooks fire only on agent edits); or the file isn't `.java` | Check the eye icon in the Agent Hooks panel, let the agent make the edit, and read the hook log in the Kiro output panel. |
| The guard flags a file that only uses JDK packages | A JDK or third-party `javax.*` package that the list doesn't account for | Adjust the regex in `jakarta-import-guard.json` and the skill together; never rename JDK packages to `jakarta`. |
| After task 1 the agent starts fixing compile errors | `verify-after-spec-task` was still enabled, or the agent went beyond the task | Reject the Java hunks, `git restore` the files, disable the verify hook (Exercise 2.1). |
| The compile check lists no files right after the parent bump | Incremental compile: Maven found "nothing to compile" | Keep `clean` in the command (`mvn -B -q clean compile`). |
| Random compile or Surefire errors that don't repeat | Two Maven builds at once (yours, the agent's or the hook's) share `target/` | Wait until the agent is idle and the hook run has finished, then run `mvn -B clean verify` once. |
| Quick Spec produced different or merged tasks | The model reorganized the plan | Edit `tasks.md` to match the six tasks, then choose **Sync Files**. |
| `#spec:spring-boot-3-upgrade` finds nothing | Kiro named the spec folder differently | Type `#spec`, press Enter and pick your spec from the list. |
| `dependency:tree` prints nothing | You added `-q`, which hides INFO output | Run it without `-q`. |
| The agent edited `SecurityConfig.java` in Part 3 | The security skill's description matched the compile errors | `git restore` that file and repeat with the boundary from the prompt. |
| Compile errors in files other than `SecurityConfig.java` after Part 3 | A missed import, or a JDK package renamed (for example `jakarta.sql`) | Rerun the skill's search step; JDK packages go back to `javax`. |
| Text typed after `/skill-name` seems ignored | Your build handles a skill slash command on its own | Send `/skill-name` alone first, then the prompt as the next message. |
| `invalidUserIsRejectedByBeanValidation` gets 403 instead of 400 (and `validUserIsCreated` 403 instead of 201) | `@WebMvcTest` doesn't scan the plain `@Configuration` class, so default security (CSRF on) applies | Add `@Import(SecurityConfig.class)` to `UserControllerTest` (Exercise 4.2). |
| All web tests pass without `@Import` | They pass against Spring Boot's default security too | Add the import anyway, so the tests exercise your rules. |
| `mvn spring-boot:run` fails with "Port 8080 was already in use" | Another app, or an earlier run, is still running | Stop it (Ctrl+C in its terminal) and start again. |
| No migrator report in `target/run.log` | The dependency is missing or not `runtime` scope, or you renamed the key already | Check `pom.xml`; the report appears only while an old key is present. |
| An ERROR from `PropertiesMigrationListener` at startup, yet the app runs | Expected: it lists keys that are no longer supported, such as `server.max-http-header-size`, and doesn't map them | Rename the key yourself (Exercise 4.3, task 4). |
| The invalid `POST` returns 401 on the running app | The error dispatch is denied (Spring Security 6 authorizes every dispatch type) | Review the rules with the skill's section 3; don't open `/error` to everyone without understanding why. |
| `curl …/api/users/` returns 404 | Trailing-slash matching is off by default since Spring Framework 6.0 | Expected. Fix the client, not the server. |
| `/junit4-to-jupiter` isn't in the `/` menu | Folder name and `name` differ, front matter not on line 1, or invalid characters | Fix the front matter; reload the window if it still doesn't appear. |
| "package org.junit does not exist" after removing JUnit 4 | A class still uses JUnit 4 | Rerun the skill on that class. |
| "Mockito is currently self-attaching to enable the inline-mock-maker. This will no longer work in future releases of the JDK…" in the build output | Mockito 5, managed by 3.5.16, attaches itself at runtime on JDK 21+ | Expected noise, not a failure (seen in the 2026-10-10 dry run on stages 2 and 3). |
| `UnnecessaryStubbingException` after the migration | `MockitoExtension` uses strict stubs | Remove or correct the unused stub; don't make the class lenient. |
| Tests run is lower than 14 | A test was dropped or lost its `@Test` | `git diff stage-1 -- src/test`, restore the test, and don't commit until the count matches. The verify hook still passes in this case; only the count shows it. |
| No deprecation warnings listed | Incremental compile skipped the classes | Keep `clean` in the command (Exercise 6.2). |
| Module 4 starts with the verify hook off | Exercise 4.3, step 6 was skipped | Turn `verify-after-spec-task` on with the eye icon (Exercise 6.2, step 5). |

</details>

## Kiro features used

<details><summary>Feature list with docs links</summary>

| Feature | Docs |
|---|---|
| Hooks: `PostFileSave`, `PostTaskExec`, matcher, `{{filePath}}`, command actions, exit codes | <https://kiro.dev/docs/hooks/> · <https://kiro.dev/docs/hooks/types/> · <https://kiro.dev/docs/hooks/actions/> · <https://kiro.dev/docs/ide/whats-new-v1/hooks/> |
| Enabling and disabling hooks (eye icon), hook logs | <https://kiro.dev/docs/hooks/management/> · <https://kiro.dev/docs/hooks/troubleshooting/> |
| Always-ask writes to `.kiro/hooks/` | <https://kiro.dev/docs/permissions/> |
| Quick Spec (and Feature spec as the gated alternative) | <https://kiro.dev/docs/specs/quick-spec/> · <https://kiro.dev/docs/specs/feature-specs/> |
| Spec tasks, Sync Files, `#spec` | <https://kiro.dev/docs/specs/> · <https://kiro.dev/docs/specs/best-practices/> |
| Skills: using, activating (description and `/name`), writing; packaging into powers | <https://kiro.dev/docs/skills/> · <https://kiro.dev/docs/powers/> |
| Slash commands | <https://kiro.dev/docs/ide/chat/slash-commands/> |
| Autopilot vs Supervised, Accept / Reject / Chat inline | <https://kiro.dev/docs/ide/chat/autopilot/> |
| Context providers `#url`, `#terminal`, `#spec`, folders | <https://kiro.dev/docs/ide/chat/> |
| Manual steering reference (`#migration-playbook`), `tech.md` | <https://kiro.dev/docs/steering/> |
| Checkpoints (and why you commit first) | <https://kiro.dev/docs/checkpoints/> |
| Custom agent (optional review) | <https://kiro.dev/docs/custom-agents/> |

</details>

## Next

[Module 4: Spring Boot 4.1 and Java 25](04-spring-boot-4-java25.md): your recorded deprecations
first, then Spring Boot 4.1.1, Jackson 3, the modular starters, Java 25 and a power.
