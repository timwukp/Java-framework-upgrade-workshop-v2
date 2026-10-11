# Module 4: Spring Boot 4.1 and Java 25 (80 minutes)

You move the service from stage 2 (Spring Boot 3.5.16, Java 21) to stage 3, the target: Spring Boot
4.1.1 on Java 25. An optional [appendix](#appendix-optional-outside-the-80-minutes-accelerators),
outside the 80 minutes, covers the AWS Transform power and OpenRewrite.

## What you'll do

- Import the `java-modernization` power and use it in a **Plan** session.
- Replace `@MockBean` with `@MockitoBean` while still on 3.5.16.
- Run a Quick Spec: Jackson properties, Spring Boot 4.1.1 with modular starters (and the Jackson 3
  trap it exposes), then Java 25 with Lombok declared as an annotation processor.
- Check the test count, the class file version and the running app; tag `stage-3`.

## Prerequisites

- Module 3 is complete: tag `stage-2`, Spring Boot 3.5.16, `java.version` 21, and
  `mvn -B clean verify` passes on JDK 21 with **Tests run: 14** (9 service + 5 web tests). Read your
  own number; if it isn't 14, fix that first.
- `MIGRATION-NOTES.md` has the section `Stage 2 → 3: deprecations to fix first` (Module 3, Ex 6.2).
- Behind? Use the [reset procedure](../solutions/README.md#reset-your-workspace-to-a-stage-the-one-procedure-all-modules-use),
  row "Module 4".
- JDK 25 is installed ([setup, section 1](../docs/participant-setup.md#1-jdks-8-21-and-25)); JDK 21
  stays the default until Part 4.
- `sample-app/` is trusted, `mvn *` is allowed, and autonomy is **Supervised**.
- **Hooks:** `verify-after-spec-task` **on** and `jakarta-import-guard` **on**, for the whole module.

All commands run from `sample-app/` in Kiro's integrated terminal unless stated otherwise.

## What Spring Boot 4 changes

Java 17 is the floor; Jakarta EE 11 and Spring Framework 7 are the baseline; starters are modular;
Jackson 3 (`tools.jackson`) replaces Jackson 2; `@MockBean` is gone; 3.x deprecations are removed.

<details><summary>Background: what Spring Boot 4 changes, with verbatim sources and managed versions</summary>

| Change | Source (verbatim) |
|---|---|
| Java 17 is the floor, the latest LTS is encouraged | "Spring Boot 4.0 requires Java 17 or later. Using the latest LTS release of Java is encouraged." ([Spring Boot 4.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide)) |
| Jakarta EE 11 | "Spring Boot 4 is based on Jakarta EE 11 and requires a Servlet 6.1 baseline." (same guide) |
| Spring Framework 7 | "In particular, you must use Spring Framework 7.x." (same guide) |
| Modular jars and starters | "Spring Boot 4.0 has a new modular design and now ships smaller focused modules rather than several large jars." (same guide) |
| Jackson 3 | "Spring Boot now uses Jackson 3 as its preferred JSON library. Jackson 3 uses new group IDs and package names with com.fasterxml.jackson becoming tools.jackson." (same guide) |
| `@MockBean` is gone | "Spring Boot's @MockBean and @SpyBean support has been removed in this release, in favor of @MockitoBean and @MockitoSpyBean support." (same guide) |
| 3.x deprecations are gone | "Classes, methods and properties that were deprecated in Spring Boot 3.x have been removed in this release." (same guide) |
| Start from the latest 3.5.x | "Before you start the upgrade, make sure to upgrade to the latest available 3.5.x version." (same guide). You're on 3.5.16. |
| Spring Security 7 needs the lambda DSL | "the prior configuration style will not be valid in Spring Security 7 where the usage of the Lambda DSL will be required." ([Spring Security 6.5: Preparing for 7.0](https://docs.spring.io/spring-security/reference/6.5/migration-7/configuration.html)) |
| 4.1 removes 4.0's deprecations | "Classes, methods and properties that were deprecated in Spring Boot 4.0 have been removed in this release." ([Spring Boot 4.1 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.1-Release-Notes)) |

Three things to keep in mind:

- **Jackson annotations keep their old package.** "An exception to this is the jackson-annotations
  module which continues to use the com.fasterxml.jackson.core group ID and
  com.fasterxml.jackson.annotation package."
- **Hibernate is 7.x.** The 4.0 release notes list "Hibernate 7.2", and the 4.1.1 parent manages 7.4.5.
- **Jackson 3 has stricter defaults.** Two show up in this module (verified in the 2026-10-10 dry
  run): a JSON body that omits a primitive can fail with 400 (`FAIL_ON_NULL_FOR_PRIMITIVES`,
  Exercise 3.4), and JSON properties are written in alphabetical order (Exercise 4.3).

What the 4.1.1 parent manages, from the Spring Boot BOM at tag `v4.1.1`
([`platform/spring-boot-dependencies/build.gradle`](https://github.com/spring-projects/spring-boot/blob/v4.1.1/platform/spring-boot-dependencies/build.gradle)
and [`gradle.properties`](https://github.com/spring-projects/spring-boot/blob/v4.1.1/gradle.properties)).
You can confirm some of these with Maven in Exercise 3.4.

| Library | 3.5.16 | 4.1.1 |
|---|---|---|
| Spring Framework (`spring-core`) | 6.2.19 | 7.0.9 |
| Spring Security (`spring-security-core`) | 6.5.11 | 7.1.1 |
| Hibernate ORM (`org.hibernate.orm:hibernate-core`) | 6.6.53.Final | 7.4.5.Final |
| Jackson `jackson-databind` | 2.21.4 (`com.fasterxml.jackson.core`) | 3.1.5 (`tools.jackson.core`) |
| JUnit (JUnit BOM) | 5.12.2 | 6.0.3 |
| Mockito | 5.17.0 | 5.23.0 |
| Byte Buddy | 1.17.8 | 1.18.11 |
| Lombok | 1.18.46 | 1.18.46 |

Per [endoflife.date](https://endoflife.date/spring-boot) (checked 2026-10-08), 4.1.1 is the latest 4.1
release, and open-source support for 4.1 runs until 2027-07-31. Java 25 is an LTS release.

</details>

## Time box

| Part | Topic | Minutes |
|---|---|---|
| 1 | Import the `java-modernization` power, then plan with it | 15 |
| 2 | Fix deprecations on 3.5 first | 10 |
| 3 | Quick Spec `stage-3-boot4`: Jackson properties, then Spring Boot 4.1.1 | 25 |
| 4 | Java 25, with Lombok as an annotation processor | 25 |
| 5 | Commit and tag `stage-3` | 5 |
| | **Total** | **80** |

**If you run late:** the instructor demos the power import (Exercise 1.2, at most 5 minutes); skip the
app start in Exercise 4.3 but keep its class-file check. Never skip the test-count checks or the
`stage-3` tag.

### The build stays green, with one planned exception

Unlike Module 3, every step keeps the build passing, except one: the 4.1.1 parent exposes a Jackson 3
trap that only `validUserIsCreated` catches (Exercise 3.4). **Any other red build means a change is
incomplete.**

| After | Spring Boot | `java.version` | JDK | `mvn -B clean verify` | Tests run |
|---|---|---|---|---|---|
| Part 2 | 3.5.16 | 21 | 21 | passes | 14 |
| Task 1 (Jackson properties) | 3.5.16 | 21 | 21 | passes | 14 |
| Task 2 (Spring Boot 4.1.1) | 4.1.1 | 21 | 21 | **fails**: `validUserIsCreated` | 14, Failures: 1 |
| Task 2 fix (no `@AllArgsConstructor` on `User`) | 4.1.1 | 21 | 21 | passes | 14 |
| Task 3 (Java 25, Lombok processor) | 4.1.1 | 25 | 25 | passes | 14 |

The framework moves first, then the JDK (Boot 4 runs on Java 17+): one variable at a time.

### How to read the test count after a spec task

After each spec task the verify hook runs **one** `mvn -B clean verify` and gives the agent the
`Tests run` line and `BUILD SUCCESS` (on failure, the last 80 lines). The agent quotes it; the run
also shows in the Kiro output panel.

- The hook passes **even if fewer tests ran**. Only the number shows a missing test: green is not
  done.
- Your own `mvn -B clean verify` only **after the hook has finished**: two builds share `target/`.

---

## Part 1: Import the `java-modernization` power, then plan with it (15 minutes)

### Exercise 1.1: Read the power before you install it (4 minutes)

**Goal:** know what a power is and how it activates.

**Steps**

1. Look at the power (outside the workspace, so the agent can't see it until you install it):

   ```bash
   find ../powers/java-modernization -type f | sort
   cat ../powers/java-modernization/plugin.json
   grep -m2 -E "^(name|description):" ../powers/java-modernization/skills/*/SKILL.md
   ```

2. Read the `keywords` array. **Keywords are the activation triggers**: when one appears in your
   conversation, the power activates and its skills load as needed.

<details><summary>Background: the power format, and powers vs workspace skills</summary>

"Powers follow the Agent Plugins specification — an open, vendor-neutral format for packaging reusable
components that extend AI agents." A power is a folder with:

- **`plugin.json`** (required). Its required fields are `$schema`, `name`, `version`, `description`,
  `author` and `keywords`.
- **`skills/`** (optional). Agent Skills in the same `SKILL.md` format as `.kiro/skills/`.
- **`mcp.json`** (optional). MCP servers that bring tools.

The older `POWER.md` format still works, but the docs recommend `plugin.json` for new powers. The
workshop power is skills-only, which the docs list as a valid shape.

On keywords: "Instead of loading all MCP tools at once, powers activate dynamically based on keywords in
your conversation." Inside the power, each skill works like any other skill. At startup Kiro loads only
its `name` and `description`, and it loads the full instructions when your request matches.

| | Workspace skill (`.kiro/skills/<name>/SKILL.md`) | Power (`plugin.json` + `skills/` + optional `mcp.json`) |
|---|---|---|
| Where it lives | Committed in this repository | A folder, a public GitHub repository, or the registry at [kiro.dev/powers](https://kiro.dev/powers/) |
| Who gets it | Everyone who clones and trusts this workspace | Each user who installs it, in any workspace |
| How it activates | Its `description` matches your request, or you type `/<name>` | A `keywords` entry matches your conversation; then its skills load as needed |
| Can bring tools | No MCP servers; it can bundle scripts, references and assets | Yes, through `mcp.json` |
| How it updates | `git pull` | Powers panel → the power → **Check for updates** → **Install updates** |
| Best for | Know-how specific to this codebase and this team | Know-how you reuse across many services |

The docs' own guidance: skills are for "reusable workflows you want to share or import from others",
and "For MCP integrations, powers are usually a better fit". Powers carry no extra charge.

Where a power's MCP servers end up (the optional appendix installs one that has them):

- In the Agent Plugins format, Kiro manages them internally and "automatically namespaces server
  names to avoid conflicts". They're not written to your `~/.kiro/settings/mcp.json`.
- In the legacy `POWER.md` format, they're registered in `~/.kiro/settings/mcp.json` under a Powers
  section.

Docs: [Powers](https://kiro.dev/docs/powers/) · [Create powers](https://kiro.dev/docs/powers/create/) ·
[Skills](https://kiro.dev/docs/skills/)

</details>

**Verify:** which keyword would a prompt about "MockitoBean" match? Why doesn't cloning the repository
install the power for a teammate?

**Checkpoint:** nothing changed (`git status`).

### Exercise 1.2: Import the power from a folder (3 minutes)

**Goal:** the power is installed for you.

**Steps**

1. Open the **Powers** panel (the Ghosty icon with the lightning bolt).
2. Choose **Add Custom Power** → **Import power from a folder**.
3. Select `powers/java-modernization`, the folder that contains `plugin.json` (not `powers/`, not the
   repository root).
4. Click **Install**.

**Verify:** `java-modernization` is listed in the Powers panel; `git status --short` prints nothing.

**Checkpoint:** nothing to commit. Installing a power is a per-user action.

<details><summary>Background: package root, custom agents and powers; docs</summary>

A power needs "a valid plugin.json or POWER.md file at its package root".

> Verify: how your Kiro build shows an installed custom power; the docs describe only the import steps.

Custom agents have their own `includePowers` setting; the docs example sets it to `false`. Check
the [custom agents docs](https://kiro.dev/docs/custom-agents/) for its default before you expect
`migration-reviewer` to use this power in Module 5.

Docs: [Install powers](https://kiro.dev/docs/powers/installation/) ·
[Create powers: test locally](https://kiro.dev/docs/powers/create/)

</details>

### Exercise 1.3: Plan the upgrade with the power (8 minutes)

**Goal:** a read-only plan for stage 3 that names every file to change.

**Steps**

1. Click **+** in the chat panel and choose **Plan** on **Let's build**. Plan can't write files or run
   commands.
2. Send the prompt below (keywords "Spring Boot 4", "Java 25"). Answer clarifying questions briefly:
   "Plan only. Targets are in migration-standards."

> **Don't approve the plan.** "Once you approve the plan, execution begins automatically."

**Ask Kiro**

```text
Plan the Spring Boot 4.1 and Java 25 upgrade for this project: from stage 2 (Spring Boot 3.5.16, Java 21) to stage 3 in migration-standards (Spring Boot 4.1.1, Java 25). List every file that must change, what changes in it and why, in the order you would make the changes. Mark which changes can be made now, while the project is still on Spring Boot 3.5.16. Say explicitly whether SecurityConfig needs changes for Spring Security 7. At the end, name the powers, skills and steering files you used. Mark anything you are not sure about as "unverified". This is a plan only; do not change any files.
```

<details><summary>Example plan (yours will differ), and an optional follow-up question</summary>

```text
1. UserControllerTest: @MockBean -> @MockitoBean (possible now, on 3.5.16)
2. JacksonConfig: Jackson2ObjectMapperBuilderCustomizer -> spring.jackson.* properties (possible now)
3. pom.xml: parent 4.1.x; spring-boot-starter-web -> spring-boot-starter-webmvc;
   spring-boot-starter-webmvc-test and spring-boot-starter-security-test
4. UserControllerTest: @WebMvcTest import moves to org.springframework.boot.webmvc.test.autoconfigure
5. pom.xml: java.version 25 (after switching to JDK 25)
SecurityConfig: no change, it already uses the lambda DSL.
Used: power java-modernization (spring-boot-4-upgrade, java-25-adoption), steering migration-standards, pom-rules
```

A plan may miss that Lombok must be declared as an annotation processor on JDK 23 and later. You add
that in task 3. It may also miss the Jackson 3 trap that task 2 exposes (Exercise 3.4).

To see which knowledge was used, ask:

```text
Which powers or skills did you load for this plan, and which statements came from them?
```

Expect the power or its `spring-boot-4-upgrade` skill to be named. The workspace skill
`spring-security-lambda-dsl` may appear too, because its description mentions Spring Boot 4. If the
power wasn't used, rephrase with a keyword from `plugin.json`, for example "MockitoBean" or
"Jackson 3".

> Verify: how your Kiro build shows that a power or skill was activated (for example, a marker in the
> chat). The docs describe activation by keywords and descriptions, not the indicator. The agent's
> own answer is the fallback evidence.

Docs: [Plan mode](https://kiro.dev/docs/specs/plan/) · [Powers](https://kiro.dev/docs/powers/) ·
[Chat](https://kiro.dev/docs/ide/chat/)

</details>

**Verify:** Plan can't run commands, so your `grep` is the ground truth:

```bash
grep -nE "<artifactId>spring-boot-starter|spring-security-test|<java.version>" pom.xml
grep -rnE "^import .*(MockBean|WebMvcTest|jackson)" src
ls src/main/java/com/example/usermanagement/config/
grep -nE "and\(\)|antMatchers|authorizeRequests|WebSecurityConfigurerAdapter" src/main/java/com/example/usermanagement/config/SecurityConfig.java
```

Look for: the starters and `java.version` 21; the `MockBean`, `WebMvcTest` and Jackson imports;
`JacksonConfig.java`; **no output** from the last command (lambda DSL already). The plan should cover
each item, with `@MockBean` and Jackson doable on 3.5.16.

**Checkpoint:** read-only (`git status`).

---

## Part 2: Fix deprecations on 3.5 first (10 minutes)

### Exercise 2.1: Start from a green stage 2 and list the deprecations (4 minutes)

**Goal:** know your starting point, and see what Boot 4 will remove.

**Steps**

```bash
git status
git tag -l "stage-*"
mvn -v
grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
grep -n -A6 "deprecations to fix first" MIGRATION-NOTES.md
```

Then list the deprecation warnings. `clean` forces a full recompile; `test-compile` includes the tests,
where `@MockBean` lives. Don't add `-q`: it hides warnings.

```bash
mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true -Dmaven.compiler.showWarnings=true | grep -iE "deprecat|removal"
```

<details><summary>Example warning (yours will differ)</summary>

```text
[WARNING] /…/controller/UserControllerTest.java:[9,48] org.springframework.boot.test.mock.mockito.MockBean in org.springframework.boot.test.mock.mockito has been deprecated and marked for removal
```

</details>

**Verify:** a clean tree; tags `stage-0` to `stage-2`; Java 21; parent `3.5.16`; `Tests run: 14,
Failures: 0, Errors: 0, Skipped: 0`; at least the `MockBean` deprecation. Note other warnings in
`MIGRATION-NOTES.md`; fix on 3.5 only those with a replacement there.

> **Expected noise:** warnings that a Java agent was loaded dynamically or "Mockito is currently
> self-attaching to enable the inline-mock-maker" come from Mockito 5 on JDK 21+, not from the
> migration (seen in stages 2 and 3 in the 2026-10-10 dry run).

**Checkpoint:** if you added notes, commit them (`git add MIGRATION-NOTES.md && git commit -m "Notes:
stage 2 deprecation listing"`).

### Exercise 2.2: `@MockBean` → `@MockitoBean`, still on 3.5.16 (6 minutes)

**Goal:** one moving part fewer for the Boot 4 bump. `@MockitoBean` comes from Spring Framework 6.2,
which 3.5.16 already manages.

<details><summary>Background: why @MockitoBean already works on 3.5.16</summary>

- The 4.0 guide names the replacement: `@MockBean` support is removed "in favor of @MockitoBean and
  @MockitoSpyBean support".
- `@MockitoBean` is a Spring Framework annotation (`org.springframework.test.context.bean.override.mockito`),
  not a Spring Boot one. 3.5.16 manages Spring Framework 6.2.19, so the annotation should already be
  on your classpath. The build in this exercise proves it.
- One rule from the 4.0 guide: "The new annotations are allowed to be used as fields in test classes,
  but not in @Configuration classes." Your mock is a field in a test class.

Docs: [Chat: Default agent](https://kiro.dev/docs/ide/chat/) ·
[Autopilot vs Supervised](https://kiro.dev/docs/ide/chat/autopilot/)

</details>

**Steps**

1. Check that the tree is clean (`git status`). Commit before every agent run.
2. New session (**+**), Default agent. Send the prompt below.
3. **Accept** only the import and the annotation in `UserControllerTest.java`.

**Ask Kiro**

```text
We are still on Spring Boot 3.5.16 and Java 21 (stage 2). In src/test/java/com/example/usermanagement/controller/UserControllerTest.java, replace Spring Boot's deprecated @MockBean with Spring Framework's @MockitoBean from org.springframework.test.context.bean.override.mockito. Change only that import and that annotation; keep every test, every assertion, @WithMockUser and @Import(SecurityConfig.class). Do not touch pom.xml or any other file. Then run `mvn -B clean verify` as a single command without pipes and report the Tests run, Failures, Errors and Skipped totals.
```

**Verify** (after the agent's build). The `grep` skips comments:

```bash
git diff --stat
grep -rnE '^import .*Mock(ito)?Bean;|^[[:space:]]*@Mock(ito)?Bean' src/test
mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true -Dmaven.compiler.showWarnings=true | grep -iE "deprecat|removal"
```

Look for: only `UserControllerTest.java` changed; two `MockitoBean` lines (import and annotation); no
`MockBean` warning; the agent reported `Tests run: 14` with no failures.

**Checkpoint**

```bash
git add -A
git commit -m "Stage 3 prep: @MockBean -> @MockitoBean on Spring Boot 3.5.16"
```

---

## Part 3: Quick Spec `stage-3-boot4` (25 minutes)

The spec puts the changes in order, gates each one with the verify hook, and keeps a reviewable
record in `.kiro/specs/`.

### Exercise 3.1: Create the spec (6 minutes)

**Goal:** `requirements.md`, `design.md` and `tasks.md`, with three tasks in two phases. Quick Spec
writes all three in one pass, without approval gates; you review them before any task runs.

<details><summary>Background: Quick Spec vs a Feature Spec</summary>

Quick Spec "is a session mode that auto-generates requirements, design, and tasks in a single pass",
without approval gates. You review the files before any task runs. The docs advise a Feature Spec with
review gates "for features where requirements quality is critical". For a production service, prefer
that. To use it today, start a **Spec** session, choose **Feature** and **Requirements-First**, and send
the same prompt.

Docs: [Quick Spec](https://kiro.dev/docs/specs/quick-spec/) · [Feature specs](https://kiro.dev/docs/specs/feature-specs/) ·
[Specs](https://kiro.dev/docs/specs/)

</details>

**Steps**

1. Check that the tree is clean (`git status`).
2. New session (**+**), choose **Quick Spec** (on **Let's build**, or in the agent selector).
3. Send the prompt below. If your stage-2 count isn't 14, use your number. Answer clarifying questions
   in one line.

**Ask Kiro**

```text
Create a spec named stage-3-boot4 for stage 3 in migration-standards: upgrade this service from Spring Boot 3.5.16 on Java 21 to Spring Boot 4.1.1 on Java 25 (Spring Framework 7, Spring Security 7, Jackson 3, Hibernate 7, JUnit 6). Use the java-modernization power's skills and the official Spring Boot 4.0 migration guide as the source of truth. Write the requirements in EARS notation.

Constraints:
- Two phases. Phase A runs on JDK 21 and keeps java.version 21. Phase B moves the build to Java 25; I switch the JDK myself before phase B.
- Baseline: the stage-2 tag records Tests run: 14. Do not run Maven yourself after a task; the verify hook runs `mvn -B clean verify` and reports the Tests run line. Quote that line in your summary. A task is done only if the build passes AND Tests run is at least 14.
- Create exactly three tasks, in this order:
  1. (Phase A, still Spring Boot 3.5.16) Delete config/JacksonConfig.java and configure the same behaviour in application.properties with spring.jackson.default-property-inclusion=non_null and spring.jackson.time-zone=UTC. Do not add a JsonMapperBuilderCustomizer, spring-boot-jackson2 or spring.jackson.use-jackson2-defaults. Drop comments in application.properties that only explain stage-2 changes.
  2. (Phase A) In one task: set the spring-boot-starter-parent version to 4.1.1 and remove the stage-2 comment above it; replace spring-boot-starter-web with spring-boot-starter-webmvc; replace spring-boot-starter-test with spring-boot-starter-webmvc-test (test scope); replace org.springframework.security:spring-security-test with org.springframework.boot:spring-boot-starter-security-test (test scope); change the @WebMvcTest import in UserControllerTest to org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest. If UserControllerTest still uses @MockBean, replace it with @MockitoBean. No classic starters, no other new dependencies, no version pins. Change only pom.xml and UserControllerTest in this task. If the verify hook then reports a failing test, do not fix it: change no test, add no property, quote the failing test and its assertion message, and stop. I diagnose it and tell you the fix.
  3. (Phase B) First run `mvn -v` and stop unless it reports Java 25. Then set java.version to 25 and change the pom description to "Stage 3: Spring Boot 4.1 on Java 25 (Jakarta EE 11)". Declare Lombok as an annotation processor, because JDK 23+ no longer runs processors found only on the class path: add org.apache.maven.plugins:maven-compiler-plugin (no version; the parent manages it) with annotationProcessorPaths containing org.projectlombok:lombok at version ${lombok.version}, and a one-line XML comment saying why. ${lombok.version} is the parent-managed version, not a pin.
- Do not change SecurityConfig; it already uses a SecurityFilterChain bean with the lambda DSL. Keep @Import(SecurityConfig.class), @MockitoBean and @WithMockUser in UserControllerTest.
- Behaviour must not change: 401 for unauthenticated requests to /api/users, 201 for a valid POST /api/users, 400 for an invalid POST /api/users that never reaches UserService, 404 for unknown ids, an X-Request-Id header on every response, null fields left out of JSON, dates in UTC.
- Never delete, disable or weaken a test. Do not start the application or run git commands; I do both.
- Out of scope: Java language modernization, virtual threads, new features. Do not invent version numbers.
```

**Verify:** `ls .kiro/specs/stage-3-boot4/` shows `requirements.md`, `design.md` and `tasks.md`, and
`git status --short` shows only new files under `.kiro/specs/`. If Kiro chose another folder name, use
it wherever this module says `stage-3-boot4`.

**Checkpoint:** commit in Exercise 3.2, after the review.

### Exercise 3.2: Review the spec before any task runs (4 minutes)

**Goal:** catch a wrong task before it costs credits and a revert.

**Steps:** open the three files and check:

- [ ] **Three tasks, in order** (Jackson, Boot 4.1.1, Java 25), each quoting the hook's `Tests run`
      line instead of running Maven itself.
- [ ] **Task 2 stops on red:** it changes only `pom.xml` and `UserControllerTest.java`, and quotes a
      failing test instead of fixing it.
- [ ] **Phase B gate:** task 3 starts with `mvn -v` and stops unless it reports 25.
- [ ] **Lombok processor:** task 3 puts Lombok in `maven-compiler-plugin` `annotationProcessorPaths`
      at `${lombok.version}`; no `<version>` on the plugin.
- [ ] **No bridges** (`-classic` starters, `spring-boot-jackson2`, `use-jackson2-defaults`), no pins,
      no `SecurityConfig.java` edits.
- [ ] **Requirements** state the test count and behaviours as `WHEN … THE SYSTEM SHALL …`.
- [ ] **Versions:** only 3.5.16, 4.1.1, 21, 25 and 14. Delete invented ones.

If something is off, edit `tasks.md` or `requirements.md` and choose **Sync Files**.

<details><summary>Background: why no bridges</summary>

The classic starters and `spring-boot-jackson2` exist for big codebases that can't move in one step.
The 4.0 guide recommends moving away from the classic starters "eventually", and calls
`spring-boot-jackson2` deprecated: it "will be removed in a future release".

Docs: [Specs best practices (Sync Files)](https://kiro.dev/docs/specs/best-practices/)

</details>

> **Don't use Run all Tasks.** Task 3 needs JDK 25 (Part 4). Click each task item in `tasks.md`.

**Checkpoint**

```bash
git add .kiro/specs
git commit -m "Module 4: stage 3 spec (Quick Spec)"
```

### Exercise 3.3: Task 1, the Jackson settings as properties (5 minutes)

**Goal:** remove the Jackson 2 code while still on 3.5.16, without changing the JSON. The two
`spring.jackson.*` properties work on both 3.5 and 4.1, so the Boot 4 bump won't touch the JSON setup.

<details><summary>Background: why properties beat code here, and when code is right</summary>

`JacksonConfig` uses `Jackson2ObjectMapperBuilderCustomizer` with `com.fasterxml.jackson.databind`
types. Boot 4 replaces both. The 4.0 guide lists "Jackson2ObjectMapperBuilderCustomizer to
JsonMapperBuilderCustomizer", and Jackson 3 moves `com.fasterxml.jackson` to `tools.jackson`. You could
port the class. For these two settings, properties are better:

1. **They survive the upgrade unchanged.** `spring.jackson.default-property-inclusion` and
   `spring.jackson.time-zone` work on both 3.5 and 4.1. Code you don't have needs no migration.
2. **They split the risk.** You change the JSON setup on 3.5, where it's proven by the tests. The
   Boot 4 bump in task 2 then doesn't touch it at all. (Jackson 3's own new defaults still change
   behaviour; Exercise 3.4 shows one.)
3. **They're configuration, not code.** You can see and change them per profile without a rebuild,
   and Spring Boot maps them to whichever Jackson version it uses.

Code still has its place: custom serializers, modules, or a feature without a property. For those,
Boot 4 has `JsonMapperBuilderCustomizer` in `org.springframework.boot.jackson.autoconfigure`, which
works on the Jackson 3 builder. To replace the mapper entirely, "Define a JsonMapper or XmlMapper bean
instead" of an `ObjectMapper`. A sketch of the shape:

```java
import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;

@Bean
JsonMapperBuilderCustomizer jsonCustomizer() {
    return builder -> {
        // Jackson 3 JsonMapper.Builder calls go here
    };
}
```

> Verify: the exact Jackson 3 builder methods in the `tools.jackson.databind.json.JsonMapper.Builder`
> javadoc before you write such a customizer. This workshop doesn't use one.

The old customizer also switched off `WRITE_DATES_AS_TIMESTAMPS`. The stage-3 reference has no
property for that and relies on Spring Boot's default of writing `java.time` values as ISO-8601
strings.

Verified in the 2026-10-10 dry run (Corretto 25): on 4.1.1 `createdDate` is an ISO-8601 string such
as `2026-10-10T14:05:52.659057Z`. The smoke test in Exercise 4.3 checks it.

Docs: [Spec tasks](https://kiro.dev/docs/specs/) · [Hooks](https://kiro.dev/docs/hooks/)

</details>

**Steps**

1. Check that the tree is clean (`git status`).
2. Click task 1 in `.kiro/specs/stage-3-boot4/tasks.md`. Afterwards the verify hook builds and
   reports to the agent.
3. **Accept** the deletion of `JacksonConfig.java` and the two `spring.jackson.*` lines. **Reject**
   anything in `pom.xml` or other Java files.

**Verify**

```bash
ls src/main/java/com/example/usermanagement/config/
grep -n "spring.jackson" src/main/resources/application.properties
grep -rn "com.fasterxml.jackson.databind\|Jackson2ObjectMapperBuilderCustomizer" src
grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
```

Look for: only `SecurityConfig.java` in `config/`; the two `spring.jackson` lines; no output from the
third command; the parent still `3.5.16`; the hook reported `Tests run: 14` and `BUILD SUCCESS`.

**Checkpoint**

```bash
git add -A
git commit -m "Stage 3, task 1: Jackson settings as spring.jackson.* properties (Boot 3.5.16)"
```

### Exercise 3.4: Task 2, Spring Boot 4.1.1 with modular starters, and the Jackson 3 trap (10 minutes)

**Goal:** the 4.1.1 parent, the Boot 4 starters and the relocated `@WebMvcTest`, on JDK 21, with the
same test count. `spring-boot-starter-security-test` is what makes `@WithMockUser` work on Boot 4;
`SecurityConfig` needs no change. The new parent turns one test red: you read the cause and fix it.

<details><summary>Background: what task 2 changes, and why (verbatim from the 4.0 guide)</summary>

| Change | Why (verbatim from the [4.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide)) |
|---|---|
| `spring-boot-starter-web` → `spring-boot-starter-webmvc` | Deprecated-starter table: "spring-boot-starter-web \| spring-boot-starter-webmvc". "The older starters remain, but should be considered deprecated and will be removed in a future release." |
| `spring-boot-starter-test` → `spring-boot-starter-webmvc-test` | "Given that all test “starter” POMs bring spring-boot-starter-test transitively, you don’t need to define this starter anymore." |
| `spring-security-test` → `spring-boot-starter-security-test` | "@WithMockUser and @WithUserDetails from spring-security-test now requires spring-boot-starter-security-test to operate properly." |
| `@WebMvcTest` import → `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` | "The root package of each such module is org.springframework.boot.<technology>.test." The class is in the 4.1.1 source at that package. |
| `SecurityConfig`: no change | Spring Security 7 requires the lambda DSL, and `.and()` "will be removed in 7.0". Module 3 already wrote the lambda DSL. |

Two more Security 7 notes: "AntPathRequestMatcher and MvcRequestMatcher are no longer supported", and
"Spring Security 7 will use PathPatternRequestMatcher by default"
([Spring Security 6.5: web migrations](https://docs.spring.io/spring-security/reference/6.5/migration-7/web.html)).
`SecurityConfig` passes plain String patterns such as `"/api/**"` to `requestMatchers`, and never
constructs those matcher classes itself.

Things you don't need here, and when you would:

- **`@AutoConfigureMockMvc`.** "Using the @SpringBootTest annotation will no longer provide any MockMVC
  support". These tests use `@WebMvcTest`.
- **`spring-boot-starter-data-jpa-test`.** It exists, but no test uses a JPA slice.
- **`@EntityScan`'s new package.** It moved to
  `org.springframework.boot.persistence.autoconfigure.EntityScan`, but the app doesn't use it.

Verified in the 2026-10-10 dry run (Corretto 25): JUnit 6 keeps the `org.junit.jupiter.api` packages;
the stage-3 reference passes all 14 tests with unchanged test imports.

Docs: [Spec tasks](https://kiro.dev/docs/specs/) ·
[Autopilot vs Supervised](https://kiro.dev/docs/ide/chat/autopilot/) ·
[Checkpoints](https://kiro.dev/docs/checkpoints/)

</details>

**Steps**

1. Check that the tree is clean (`git status`), then click task 2 in `tasks.md`.
2. In `pom.xml` and `UserControllerTest.java`, **Accept** only: the four dependency changes, the parent
   version and its comment, the `@WebMvcTest` import, and `@MockitoBean` if you skipped Part 2.
   **Reject** changes to `SecurityConfig.java` or to assertions, and any new `<version>` tag.
3. **Expect one red test.** The hook reports `Tests run: 14, Failures: 1`:
   `UserControllerTest.validUserIsCreated`, `Status expected:<201> but was:<400>`. The agent quotes it
   and stops, as the spec asks. Any other failure: see Troubleshooting.
4. Read the cause, after the hook has finished:

   ```bash
   mvn -B clean verify | grep -m2 -E "FAIL_ON_NULL_FOR_PRIMITIVES|HttpMessageNotReadableException"
   grep -n "AllArgsConstructor" src/main/java/com/example/usermanagement/entity/User.java
   ```

   The first command should print Spring's log line for the 400. If it prints nothing, look at the
   MockMvc printout for `validUserIsCreated` above the test summary (`Resolved Exception`), or ask Kiro
   with `#terminal`.

   > Verify: the 2026-10-10 dry run captured this line in the running app's log; in the test output it
   > is expected but was not captured.

   ```text
   Resolved [org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Cannot map `null` into type `boolean` (set DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES …
   ```

   So Jackson 3 builds `User` through Lombok's `@AllArgsConstructor` (the parent compiles with
   `-parameters`) and fails on the missing primitive `active`. Nothing calls that constructor.
5. **Fix it** with the prompt below, in the same session. **Accept** only `User.java` (annotation and
   import removed, a one-line comment) and the note in `tasks.md`. **Reject** test changes,
   `Boolean active` or a `spring.jackson.deserialization.*` property.

**Ask Kiro**

```text
validUserIsCreated fails with 400 instead of 201: Jackson 3 binds the request body through Lombok's @AllArgsConstructor on User (the parent compiles with -parameters) and rejects the missing primitive "active" (FAIL_ON_NULL_FOR_PRIMITIVES is on by default). Nothing calls that constructor. In src/main/java/com/example/usermanagement/entity/User.java, remove @AllArgsConstructor and its import and add a one-line comment saying why; keep @Data, @NoArgsConstructor and active = true. Under task 2 in .kiro/specs/stage-3-boot4/tasks.md, add a sub-item recording this fix and its cause. Change nothing else (no test, no property) and do not run Maven.
```

<details><summary>Background: why a valid create fails on Boot 4, and why not the property</summary>

- **What changed.** On stage 2, Jackson 2 created `User` with the no-args constructor and setters. On
  Boot 4, Jackson 3 uses the Lombok all-args constructor instead; the Spring Boot parent compiles with
  `-parameters`, so the constructor's parameter names are in the class file. A missing `active`
  becomes `null` for a `boolean` parameter, and Jackson 3 switches
  `DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES` on by default. The result is an
  `HttpMessageNotReadableException` and a 400 for every POST whose body omits `active`, in the tests
  and in the running app.
- **Why only one test caught it.** The other four web tests never send a valid body.
  `invalidUserIsRejectedByBeanValidation` still gets its 400, but from the JSON parse error, not from
  Bean Validation: a passing test for the wrong reason. That's why the sample app has a fifth web
  test, `validUserIsCreated`, from stage 0 on. It creates a user from a body without `active` and
  expects 201.
- **Why remove the constructor.** Nothing calls it (`grep -rn "new User(" src` finds only
  `new User()`). Without it, Jackson uses the no-args constructor and setters, and a missing `active`
  keeps the field default `true`.
- **Why not `spring.jackson.deserialization.fail-on-null-for-primitives=false`.** The 400 goes away,
  but Jackson still binds through the constructor and passes `false` for the missing `active`. Every
  user created without `active` would be inactive instead of active: a loud failure becomes a silent
  behaviour change. The property also relaxes the check for every request body in the service.
- Verified in the 2026-10-10 dry run (Corretto 25): with `@AllArgsConstructor`, `Tests run: 14,
  Failures: 1` (`validUserIsCreated`, 400 instead of 201), and the running app answered a create with
  400; without it, all 14 tests pass and the app returns 201 with `"active":true`.

</details>

**Verify**

```bash
grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
grep -nE "<artifactId>spring-boot-starter|spring-security-test" pom.xml
grep -rnE "WebMvcTest;|MockitoBean;|^import lombok.AllArgsConstructor|^@AllArgsConstructor" src
git diff HEAD --stat
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
```

Look for: parent `4.1.1`; starters `webmvc`, `validation`, `data-jpa`, `security`, `webmvc-test` and
`security-test`, no `spring-security-test`; the new `WebMvcTest` and the `MockitoBean` imports, and no
`AllArgsConstructor` line; only `pom.xml`, `UserControllerTest.java`, `User.java` and `tasks.md`
changed; `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` and `BUILD SUCCESS`.

<details><summary>Optional (2 minutes): confirm what Maven resolved instead of trusting the agent</summary>

Run these after the hook has finished. Don't add `-q`, which hides the tree.

```bash
mvn -B dependency:tree -Dincludes=org.springframework:spring-core,org.springframework.security:spring-security-core,org.hibernate.orm:hibernate-core,tools.jackson.core:jackson-databind,org.junit.jupiter:junit-jupiter-api
mvn -B dependency:tree -Dincludes=com.fasterxml.jackson.core
git diff stage-2 -- src/main/java/com/example/usermanagement/config/SecurityConfig.java
```

Look for:

- `spring-core` 7.0.9, `spring-security-core` 7.1.1, `hibernate-core` 7.4.5.Final, `jackson-databind`
  3.1.5 under `tools.jackson.core`, and `junit-jupiter-api` 6.0.3. These are the versions in the
  4.1.1 BOM.
- From the second command, expect only `jackson-annotations`, the exception the guide names. A
  `com.fasterxml.jackson.core:jackson-databind` here would be a Jackson 2 leftover.
- No output from the third command: security is unchanged.

</details>

**Checkpoint**

```bash
git add -A
git commit -m "Stage 3, task 2: Spring Boot 4.1.1, modular starters, relocated @WebMvcTest, no @AllArgsConstructor (Jackson 3)"
```

---

## Part 4: Java 25, with Lombok as an annotation processor (25 minutes)

<details><summary>No JDK 25 on your laptop? Finish stage 3 on JDK 21</summary>

If your company hasn't approved JDK 25 yet, finish stage 3 on JDK 21: Spring Boot 4.1.1 runs on Java
17 or later.

- Skip Exercise 4.1.
- Before you run task 3, edit it in `tasks.md` to keep `java.version` 21 and to expect Java 21 from
  `mvn -v`, then choose **Sync Files**.
- Still add the Lombok declaration: it's harmless on JDK 21 and required from JDK 23.
- In Exercise 4.3, expect major version 65. Write "Java 21" in the `stage-3` tag message.
- Tell your instructor, and in Module 5 read "25" as "21".

Verified in the 2026-10-10 dry run (Corretto 21): the stage-3 reference passes all 14 tests on JDK 21
with `java.version` 21, and unedited with `mvn -B clean verify -Djava.version=21`.

</details>

### Exercise 4.1: Switch to JDK 25 and restart Kiro (5 minutes)

**Goal:** your terminal, the agent and the hook all use JDK 25. Change the default **and** restart
Kiro from a JDK 25 terminal, so the agent and hooks inherit it.

**Steps**

1. Check that task 2 is committed (`git status`).
2. Make JDK 25 the default for new terminals, as in Module 2
   ([setup](../docs/participant-setup.md#switch-the-jdk-per-terminal)):
   - **SDKMAN:** `sdk default java <25.x-identifier>-amzn`.
   - **macOS:** in `~/.zshrc`, `export JAVA_HOME=$(/usr/libexec/java_home -v 25)`.
   - **Linux:** in `~/.bashrc`, point `export JAVA_HOME=…` at your JDK 25.
3. In a new terminal **outside Kiro**, check that `java -version` reports 25.
4. Quit Kiro, then start it from that terminal: `cd <your-clone>/sample-app && kiro .`
5. In Kiro, open a new terminal and a new chat session (Default agent); send the prompt below.

**Ask Kiro**

```text
Run `mvn -v` in the workspace root and tell me the Java version it reports. Do not run anything else.
```

**Verify:** `mvn -v` in Kiro's terminal and the agent's answer both report Java 25.

<details><summary>Background: which JDK the hook uses</summary>

Maven uses `JAVA_HOME`, so `mvn -v` is the check that matters.

> Verify: the docs don't say which environment hook commands run in. Task 3's `mvn -v` and the hook's
> build are your evidence: a hook still on JDK 21 fails with `release version 25 not supported`.

</details>

**Checkpoint:** nothing to commit.

### Exercise 4.2: Task 3, `java.version` 25 and the Lombok processor (10 minutes)

**Goal:** the build compiles for Java 25, with Lombok still working.

**Why Lombok must be declared now.** Lombok is an **annotation processor**: javac runs it while
compiling to generate `User`'s getters, setters and constructors. Up to JDK 22, javac ran any
processor it found on the class path, so stages 0–2 never declared one. **Since JDK 23, javac no
longer runs annotation processors that are only on the class path.** Undeclared, Lombok never runs
and the build fails with `cannot find symbol` (for example `getEmail()`) before any test runs. Listing
it in `maven-compiler-plugin`'s `annotationProcessorPaths` is the explicit configuration javac needs;
`${lombok.version}` reuses the parent-managed 1.18.46, so it isn't a pin.

<details><summary>Background: Lombok and Byte Buddy on Java 25, and what the failure looks like</summary>

- **Lombok version.** Its changelog says "v1.18.40 (September 4th, 2025)", "PLATFORM: JDK25 support
  added" ([Lombok changelog](https://github.com/projectlombok/lombok/blob/master/doc/changelog.markdown)).
  Both 3.5.16 and 4.1.1 manage 1.18.46, so the Lombok pin you removed in Module 2 must stay removed. A
  supported Lombok version is necessary but not enough: on JDK 23 and later it also has to be declared
  as a processor.
- **Byte Buddy.** Mockito and Hibernate generate classes with it. Its release notes for 1.17.5
  (30 March 2025) say "Update ASM to version 9.8 to support Java 25 using ASM reader and writer"
  ([Byte Buddy release notes](https://github.com/raphw/byte-buddy/blob/master/release-notes.md)). 4.1.1
  manages 1.18.11. Stage 1 doesn't need a `byte-buddy.version` override (verified in the 2026-10-10
  dry run), and the stage-1 reference has none. If you added one anyway, it would pin an older Byte
  Buddy than the one 4.1.1 manages for Mockito 5.23 and Hibernate 7.4: remove it (`pom-rules`).
- **What the failure looks like.** If task 3 sets `java.version` 25 without the declaration, the hook
  reports `BUILD FAILURE` with `cannot find symbol` errors in `UserService`, `UserServiceTest` or
  `UserControllerTest`, all pointing at methods Lombok should have generated (`getEmail()`,
  `setName()`, `isActive()` and so on). Don't let the agent "fix" that by writing getters by hand or
  removing Lombok: add the declaration.
- **Why stages 0–2 never needed it.** JDK 21 still runs class-path processors. It prints a note about
  this during compilation, which is easy to overlook in a passing build.
- The stage-3 reference `pom.xml` (`solutions/stage-3-boot41-java25/pom.xml`) has the same block,
  with a comment explaining it. Verified in the 2026-10-10 dry run (Corretto 25): without the block,
  compilation fails with `cannot find symbol` for `method getEmail()` and `method getName()`.

Docs: [Spec tasks](https://kiro.dev/docs/specs/) · [Hooks](https://kiro.dev/docs/hooks/) ·
[First project: start Kiro from a terminal](https://kiro.dev/docs/getting-started/first-project/)

</details>

**Steps**

1. Check that no old pins survived. Expect no output:

   ```bash
   grep -nE "<byte-buddy.version>|<lombok.version>|<maven.compiler" pom.xml
   ```

2. Click task 3 in `tasks.md`. Its first step must report Java 25, otherwise it stops.
3. **Accept** only `java.version` 25, the description, and the `maven-compiler-plugin` block with Lombok
   in `annotationProcessorPaths`. **Reject** a `<version>` on the plugin, a literal Lombok version such
   as `1.18.46`, and hand-written getters or setters.

**Verify**

```bash
grep -n "<java.version>" pom.xml
grep -n -A8 "<artifactId>maven-compiler-plugin</artifactId>" pom.xml
git show stage-2 --no-patch
```

Look for: `<java.version>25</java.version>`; `lombok` with `<version>${lombok.version}</version>`
inside `<annotationProcessorPaths>`; the hook reported `Tests run: 14` and `BUILD SUCCESS`, matching
the `stage-2` tag message. A lower number: see Troubleshooting.

**Checkpoint**

```bash
git add -A
git commit -m "Stage 3, task 3: Java 25, Lombok declared as annotation processor"
```

### Exercise 4.3: Prove it's Java 25, then run the app (10 minutes)

**Goal:** evidence beyond "the tests passed". The tests never start JPA or the database (Mockito and a
web slice), so only a real start proves Hibernate 7 and the Jackson properties.

**Steps**

1. Recompile from scratch (without `clean`, JDK 21 class files can survive), then check the class
   file version (69 = Java 25) and the bytecode tools:

   ```bash
   mvn -B -q clean compile
   javap -v target/classes/com/example/usermanagement/UserManagementApplication.class | grep "major version"
   mvn -B dependency:tree -Dincludes=org.projectlombok,net.bytebuddy
   ```

   Look for: `major version: 69` (Java 21 classes show 65; both verified in the 2026-10-10 dry run),
   `lombok:jar:1.18.46` and `byte-buddy:jar:1.18.11`.

2. Start the app in one terminal, with your own local password (never commit it):

   ```bash
   export APP_ADMIN_PASSWORD='<choose-a-local-password>'
   mvn -B spring-boot:run
   ```

3. In a second terminal, export the same password and call the API:

   ```bash
   export APP_ADMIN_PASSWORD='<the-same-password>'
   curl -s -w '\n%{http_code}\n' -u admin:"$APP_ADMIN_PASSWORD" -H 'Content-Type: application/json' -d '{"name":"Jane Doe","email":"jane@example.com"}' http://localhost:8080/api/users
   curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/api/users
   curl -s -i -u admin:"$APP_ADMIN_PASSWORD" http://localhost:8080/api/users/1 | grep -iE "^HTTP|X-Request-Id"
   ```

4. Stop the app with **Ctrl+C** in the first terminal.

<details><summary>Example output (yours will differ), and why the properties are in alphabetical order</summary>

```text
{"active":true,"createdDate":"2026-10-10T14:05:52.659057Z","email":"jane@example.com","id":1,"lastModifiedDate":"2026-10-10T14:05:52.659057Z","name":"Jane Doe"}
201
401
HTTP/1.1 200
X-Request-Id: 6f1c…
```

**Jackson 3 writes JSON properties in alphabetical order** (`active` first). Stage 2 wrote the same
user in field order (`"id":1,"name":…` first). Verified in the 2026-10-10 dry run. Clients that parse
JSON don't notice; tests or clients that compare JSON as text do. If one needs a fixed order,
`@JsonPropertyOrder` (still in `com.fasterxml.jackson.annotation`) on the class sets it. A related
observation from the same run: the duplicate-e-mail error (a `ProblemDetail`) no longer contains
`"type":"about:blank"` on stage 3.

The `201` and `"active":true` are the Jackson 3 trap's fix at runtime: before it, this create
returned 400.

</details>

**Verify:** the startup log names Java 25; the create returns `201` with `"active":true`;
`createdDate` is an ISO-8601 **string** ending in `Z`; `401` without credentials; `200` and
`X-Request-Id` with credentials. A numeric `createdDate` or a 400 for the create: see Troubleshooting.

**Checkpoint:** nothing changed (`git status`).

---

## Part 5: Commit and tag `stage-3` (5 minutes)

**Goal:** a green, tagged stage 3 on `workshop` for Module 5, before any optional lab.

**Steps**

1. On `workshop`, on JDK 25, with a clean tree:

   ```bash
   git status
   mvn -v
   mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
   ```

2. Update the "current state" line in `.kiro/steering/tech.md` to stage 3 (Java 25, Spring Boot
   4.1.1). In `MIGRATION-NOTES.md`, mark the `Stage 2 → 3` deprecations done and add "JDK 23+: Lombok
   declared in `annotationProcessorPaths`" and "Jackson 3: `@AllArgsConstructor` removed from `User`".
3. In `tasks.md`, choose **Sync Files** so finished tasks are marked complete.
4. Commit and tag:

   ```bash
   git add -A
   git commit -m "Stage 3 complete: Spring Boot 4.1.1, Java 25"
   git tag -a stage-3 -m "Stage 3: Java 25, Spring Boot 4.1.1, Tests run: 14"
   git show stage-3 --no-patch
   ```

<details><summary>Optional: compare with the reference solution; docs</summary>

```bash
diff ../solutions/stage-3-boot41-java25/pom.xml pom.xml
diff -r ../solutions/stage-3-boot41-java25/src src
```

Expect only cosmetic differences: comments and layout. The reference `User.java` has no
`@AllArgsConstructor` either. A difference in a dependency, the `maven-compiler-plugin` block, an
import, a property, the security configuration or a Lombok annotation on `User` is worth a second
look. The reference passes all 14 tests on Corretto 25 (verified in the 2026-10-10 dry run).

Docs: [Specs best practices (Sync Files)](https://kiro.dev/docs/specs/best-practices/) ·
[Steering](https://kiro.dev/docs/steering/)

</details>

**Checkpoint:** tag `stage-3` with `Tests run: 14` in its message. Module 5 adds `stage-3-final`.

---

## Checklist

- [ ] The power is imported; you can say how it differs from a workspace skill.
- [ ] A Plan session listed the stage-3 changes, checked with `grep`; no plan was approved.
- [ ] `@MockitoBean` replaced `@MockBean` on 3.5.16.
- [ ] The Quick Spec `stage-3-boot4` is committed; `JacksonConfig.java` is replaced by two properties.
- [ ] Parent 4.1.1 with the `-webmvc`, `-webmvc-test` and `-security-test` starters, the relocated
      `@WebMvcTest`, and `SecurityConfig.java` unchanged.
- [ ] Task 2's red `validUserIsCreated` was read from the log (`FAIL_ON_NULL_FOR_PRIMITIVES`,
      constructor binding) and fixed by removing `@AllArgsConstructor` from `User`, not by a property
      or a test change.
- [ ] Java 25 in `java.version`, `mvn -v` and the agent; major version 69.
- [ ] Lombok is in `annotationProcessorPaths` with `${lombok.version}`, and you can say why JDK 23+
      needs it.
- [ ] Tests run is 14; the app returns 201 for a create, ISO-8601 dates, 401 and `X-Request-Id`.
- [ ] Tag `stage-3` records `Tests run: 14`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| After task 2: `validUserIsCreated` `Status expected:<201> but was:<400>`; the app answers every create with 400 | Jackson 3 binds the body through Lombok's `@AllArgsConstructor` (`-parameters`) and fails the missing primitive `active` (`FAIL_ON_NULL_FOR_PRIMITIVES`, on by default) | Remove `@AllArgsConstructor` from `User` (Exercise 3.4). Not a property, `Boolean active` or a changed test body. |
| On JDK 25: `cannot find symbol` for `User`'s getters, setters or constructors | Since JDK 23, javac no longer runs annotation processors found only on the class path, so Lombok never ran | Declare Lombok in `maven-compiler-plugin` `annotationProcessorPaths` with `${lombok.version}` (Exercise 4.2). Don't hand-write getters or remove Lombok. |
| `release version 25 not supported`, or the agent or hook reports Java 21 | Kiro was started before JDK 25 became the default | Change the default, quit Kiro, start it with `kiro .` from a JDK 25 terminal (Exercise 4.1). |
| Tests run is lower than 14 | A test was dropped, disabled, or lost its `@Test` | `git diff stage-2 -- src/test`. Restore the test; don't commit until the count matches. |
| The agent adds a `-classic` starter or `spring-boot-jackson2` | The model reaches for a bridge | **Reject** the hunk (Exercise 3.2). |

<details><summary>More troubleshooting</summary>

| Symptom | Cause | Fix |
|---|---|---|
| `@WithMockUser` tests fail with 401 on Boot 4 | `spring-boot-starter-security-test` is missing | Add it with test scope. Per the 4.0 guide, `@WithMockUser` "now requires spring-boot-starter-security-test". |
| **Add Custom Power** rejects the folder, or no power appears | You selected `powers/` or the repository root | Select `powers/java-modernization`, the folder that contains `plugin.json`, then click **Install**. |
| The Plan answer doesn't use the power | No keyword from `plugin.json` matched | Rephrase with "Spring Boot 4", "Java 25", "MockitoBean" or "Jackson 3", or ask which powers it used. |
| Plan mode started editing files | A plan was approved, and execution begins automatically | Stop the agent, use **Revert** or **Restore**, and `git restore` anything left. |
| The deprecation listing prints nothing | Incremental compile skipped the classes, or `-q` hid the warnings | Keep `clean`, and drop `-q` (Exercise 2.1). |
| `dependency:tree` prints nothing | `-q` hides INFO output | Run it without `-q`. |
| `package org.springframework.boot.test.mock.mockito does not exist` | `@MockBean` was removed in Boot 4 | Use `@MockitoBean` from `org.springframework.test.context.bean.override.mockito` (Exercise 2.2). |
| The `MockBean` grep in Exercise 2.2 shows a comment line | A plain `grep` also matches Javadoc comments | Use the anchored `grep -rnE` from Exercise 2.2, which matches only imports and annotations. |
| `package org.springframework.boot.test.autoconfigure.web.servlet does not exist` | `@WebMvcTest` moved to the modular test module | Import `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` and add `spring-boot-starter-webmvc-test`. |
| `invalidUserIsRejectedByBeanValidation` fails with `Status expected:<400> but was:<403>` | `@Import(SecurityConfig.class)` was removed from the test | Restore it (Module 3, Exercise 4.2). |
| `Jackson2ObjectMapperBuilderCustomizer` or `com.fasterxml.jackson.databind` can't be found | Jackson 3 is the default in Boot 4 | Delete `JacksonConfig` and use the two properties (Exercise 3.3). Don't add `spring-boot-jackson2`. |
| The agent edits `SecurityConfig.java` | A security skill matched the Boot 4 wording | `git restore` the file. The lambda DSL is already valid for Security 7. |
| Lombok fails with an internal compiler error such as `IllegalAccessError` | An old Lombok version is pinned again | Remove the `<lombok.version>` override or the `<version>` on the Lombok dependency. Boot manages 1.18.46. |
| A Mockito or Hibernate error that names Byte Buddy | A `byte-buddy.version` override (if you added one in stage 1) pins an older Byte Buddy than 4.1.1 manages | Remove it. 4.1.1 manages 1.18.11. |
| `javap` prints `major version: 65` after task 3 | Class files from the JDK 21 build were not recompiled | Run `mvn -B -q clean compile`, then `javap` again (Exercise 4.3). |
| Warnings that a Java agent was loaded dynamically, or that Mockito is self-attaching | Mockito 5's inline mock maker on JDK 21+ | Expected noise; not part of the migration. |
| Random build failures (missing classes, a corrupt jar) right after a task | Your own Maven build overlapped the hook's build in the shared `target/` | Wait for the hook to finish, then run `mvn -B clean verify` once. |
| `createdDate` is a number in the JSON | The ISO-8601 default doesn't apply in your setup | Find the matching `spring.jackson.*` key in the Spring Boot 4.1 reference and add it in a spec task. |
| The agent is unsure about a 4.x detail | Model knowledge is older than Boot 4.1 | Give it the source: `#url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide`. |
| Task 3 ran during Part 3 | **Run all Tasks** was used | Revert the task's changes (`git restore`, or **Restore**), then run tasks one at a time. |

</details>

## Kiro features used

Powers (Agent Plugins format, import from a folder), skills, Plan mode, Quick Spec, spec tasks and
Sync Files, the `PostTaskExec` verify hook, the Default agent, Supervised mode, checkpoints,
permissions and steering.

<details><summary>Feature-to-docs table</summary>

| Feature | Docs |
|---|---|
| Powers: Agent Plugins format, `plugin.json`, `keywords`, skills-only powers | <https://kiro.dev/docs/powers/> · <https://kiro.dev/docs/powers/create/> |
| Powers panel: Add Custom Power → Import power from a folder → Install / from GitHub, updates | <https://kiro.dev/docs/powers/installation/> |
| Skills (inside a power and in the workspace) | <https://kiro.dev/docs/skills/> |
| Plan mode (read-only) | <https://kiro.dev/docs/specs/plan/> |
| Quick Spec (and Feature spec as the gated alternative) | <https://kiro.dev/docs/specs/quick-spec/> · <https://kiro.dev/docs/specs/feature-specs/> |
| Spec tasks, Sync Files, `#spec` | <https://kiro.dev/docs/specs/> · <https://kiro.dev/docs/specs/best-practices/> |
| `PostTaskExec` verify hook | <https://kiro.dev/docs/hooks/> |
| Default agent, agent selector, context providers (`#terminal`, `#url`) | <https://kiro.dev/docs/ide/chat/> |
| Autopilot vs Supervised | <https://kiro.dev/docs/ide/chat/autopilot/> |
| Checkpoints and their limits | <https://kiro.dev/docs/checkpoints/> |
| Permissions (`mvn *`; per-command approval for `atx` in the appendix) | <https://kiro.dev/docs/permissions/> |
| Custom agents (`includePowers`) | <https://kiro.dev/docs/custom-agents/> |
| Steering (`tech.md`, `migration-standards`) | <https://kiro.dev/docs/steering/> |
| Starting Kiro from a terminal (`kiro .`) | <https://kiro.dev/docs/getting-started/first-project/> |
| Appendix only: Powers registry (AWS Transform power), MCP servers bundled in powers, user `mcp.json` | <https://kiro.dev/powers/> · <https://kiro.dev/docs/powers/installation/> · <https://kiro.dev/docs/mcp/configuration/> |

</details>

## Next

[Module 5: Quality gates](05-quality-gates.md): review the migration with the `migration-reviewer`
custom agent (no write tool; only Maven builds and read-only git run unprompted), add a guard hook,
fix a regression with a Bugfix spec, and tag `stage-3-final`.

---

## Appendix (optional, outside the 80 minutes): accelerators

Kiro has no built-in "upgrade Java" transformation; you just did the upgrade with a spec and the
agent. Deterministic tools can do the bulk mechanical part on large codebases. You still review
their output exactly as you reviewed the agent's. This appendix runs each tool on a **throwaway
branch** created from `stage-2`, and compares the result with your stage 3. Do it after the workshop
day, or in a follow-up session.

**Prerequisites for the appendix** (none of these are in the participant setup):

- Tag `stage-3` exists (Part 5), and the tree is clean on `workshop`.
- At least 30 minutes. A transformation run can take longer.
- For the AWS Transform power (Exercises A.1 and A.2):
  - An AWS **sandbox** account that your security team has approved, with the
    `AWSTransformCustomFullAccess` managed policy on your IAM user or role.
  - AWS CLI v2 with working credentials, and a supported region (Exercise A.1).
  - The `atx` CLI, Node.js 22+ and Git.
  - uv/uvx and Python 3.10+ for the power's MCP server.
  - macOS or Linux. (The power's steering asks Windows users for WSL, which this workshop hasn't
    tested.)
- For OpenRewrite (Exercise A.3): Code Genome Project credentials (a download token), and your legal
  team's view on the recipe licences.

> **Commit before running either tool.** Both tools change files through shell commands, and Kiro's
> checkpoints don't capture "file changes made by MCP tools or bash commands". Restore can't undo
> them, but git can.

```bash
git status
git log --oneline -1
```

Look for: a clean tree on `workshop`, with your stage-3 commit on top.

### Exercise A.1: Before you start, data handling and prerequisites

**Goal:** decide whether you may run AWS Transform at all, and with which account.

**What it can do.** The AWS Transform power wraps the AWS Transform custom CLI (`atx`). The CLI runs
AWS-managed transformation definitions on your local repository: `AWS/java-version-upgrade` and
`AWS/spring-boot-version-upgrade` (Spring Boot 3.x → 4.x, targeting 4.1.0).

<details><summary>Background: the two AWS-managed transformations (verbatim from the AWS catalog)</summary>

From [AWS-managed transformations](https://docs.aws.amazon.com/transform/latest/userguide/transform-aws-customs.html):

| Transformation | Status | Scope (verbatim) |
|---|---|---|
| `AWS/java-version-upgrade` | Generally available | "Upgrade Java applications using any build system from any source JDK version to any target JDK version, with dependency modernization including Jakarta EE migration, database drivers, ORM frameworks, and Spring ecosystem updates." |
| `AWS/spring-boot-version-upgrade` | Generally available | "Migrate Spring Boot 3.x projects to Spring Boot 4.x (targeting 4.1.0 GA)." It "Covers version upgrades, starter renames, Jackson 3 migration, Spring Security 7 DSL, @MockBean removal, property renames, package relocations, observability consolidation". |

</details>

**What it can't do:**

- The catalog has **no Spring Boot 2.x → 3.x transformation**.
  - `java-version-upgrade` mentions "Jakarta EE migration" and "Spring ecosystem updates". Whether it
    performs a full Boot 2 → 3 jump is untested.
  - That's one reason Modules 2 and 3 are Kiro-native.
- The Spring Boot transformation targets 4.1.0, so expect to bump to 4.1.1 yourself.
- Names change over time. The power's own reference says its table is "NOT a substitute for
  `atx custom def list --json`".

> **Data handling: read this before you install anything, especially in a regulated enterprise.**
>
> - **Your code goes to an AWS service.** "AWS Transform stores your questions, its responses, and
>   additional context, such as console metadata and code in your IDE, to generate responses to your
>   questions." ([Data protection](https://docs.aws.amazon.com/transform/latest/userguide/data-protection.html))
>   "Local mode" means the CLI runs on your machine. It still needs the
>   `transform-custom.<region>.api.aws` and `*.s3.amazonaws.com` endpoints.
> - **Content may be used for model training.** "AWS Transform may use this content, for example, to
>   provide better responses to common questions, fix AWS Transform operational issues, for
>   de-bugging, or for model training." This includes "the responses and code that AWS Transform
>   generates". The opt-out is organization-wide: "For AWS Transform configure an AI services opt-out
>   policy in AWS Organizations."
>   ([Service improvement](https://docs.aws.amazon.com/transform/latest/userguide/service-improvement.html))
>   If your organization has no such policy, assume the opt-out doesn't apply.
> - **Learning is on by default.** "By default, AWS Transform custom extracts lessons from every
>   transformation execution." The per-run opt-out is `-d` / `--do-not-learn`. The command the power
>   builds doesn't include it, so ask for it.
> - **Telemetry is on by default.** The power's steering says it "collects usage telemetry by default
>   during transformation execution". It always adds `--telemetry`. You can opt out by asking in chat,
>   but only for that session; "This preference is not persisted".
> - **`-t` bypasses guardrails.** The power runs `atx custom def exec … -x -t`. Per the docs, "The `-t`
>   or `--trust-all-tools` flag automatically approves all tool executions without prompting and
>   bypasses most security guardrails". They add: "Use with caution in production environments."
>   ([Custom workflows](https://docs.aws.amazon.com/transform/latest/userguide/custom-workflows.html))
> - **Where data is stored.** "your data is stored in the AWS Region where your AWS Transform profile
>   was created". With cross-region inference, requests "may be processed in a different Region within
>   the geography".
> - **Two services, two sets of terms.** Your prompts go to Kiro under Kiro's
>   [data-protection terms](https://kiro.dev/docs/privacy-and-security/data-protection/). Your code
>   goes to AWS Transform under your AWS account's terms.
>
> **Recommendation:**
> - Use a **sandbox AWS account** that your security team has approved, and only this sample app.
> - Never use a production account or your company's code in a workshop.
> - Work on a throwaway branch.

**Prerequisites** ([Getting started](https://docs.aws.amazon.com/transform/latest/userguide/custom-get-started.html)):

| Item | Requirement |
|---|---|
| AWS credentials | `aws sts get-caller-identity` succeeds. The AWS CLI v2 is installed. |
| IAM | "We recommend attaching the AWSTransformCustomFullAccess AWS managed policy to your IAM user or role." SSO users need an administrator to add it to their IAM Identity Center permission set. |
| Region | One of us-east-1, eu-central-1, eu-west-2, ca-central-1, ap-northeast-1, ap-northeast-2, ap-southeast-2, ap-south-1. Without configuration it falls back to us-east-1. |
| `atx` CLI | Install it with `curl -fsSL https://transform-cli.awsstatic.com/install.sh \| bash` (Windows PowerShell: `irm https://transform-cli.awsstatic.com/install.ps1 \| iex`). The power can also install or update it. |
| Node.js 22+ and Git | Required by the CLI. "the working directory needs to be a valid Git repo". |
| uv/uvx and Python 3.10+ | For the power's MCP server, which `mcp.json` starts with `uvx`. |
| OS | The docs support native Windows, but the power's steering asks Windows users for WSL. Use macOS, Linux or WSL. |
| Cost | Billed in Agent Minutes, which "reflect active agent work time, not wall clock time". `--limit` caps a session. Neither the power nor this workshop quotes prices; see [AWS Transform pricing](https://aws.amazon.com/transform/pricing/). |

**Verify**

```bash
aws --version
aws sts get-caller-identity
aws configure get region
atx --version
node --version
uv --version
python3 --version
```

Look for:

- Your sandbox account ID.
- A supported region.
- Node 22 or later and Python 3.10 or later.

If any check fails, do Exercise A.3 (or just read it) instead.

### Exercise A.2: Run the Spring Boot transformation on a throwaway branch

**Goal:** see what a deterministic transformation produces for the same hop, and compare it with your
stage 3.

**Steps**

1. Create the lab branch from `stage-2`. Keep the power's `.atx/` state folder out of git with a
   local-only ignore rule:

   ```bash
   git switch -c lab/aws-transform stage-2
   echo ".atx/" >> "$(git rev-parse --git-dir)/info/exclude"
   git status
   ```

2. Install the power. Per the AWS docs: "Open Kiro IDE and navigate to the Powers panel. Find **AWS
   Transform** in the list and install it. Open Kiro Chat, click on the Power, and select **Try
   power**." Alternatives:
   - **Add Custom Power** → **Import power from GitHub** with
     `https://github.com/kirodotdev/powers/tree/main/aws-transform`.
   - **Add to Kiro** on [kiro.dev/powers](https://kiro.dev/powers/).
3. Notice the format. This power uses the legacy `POWER.md` format with an `mcp.json`, so its MCP
   server is registered in your user MCP config:

   ```bash
   grep -n "aws-transform" ~/.kiro/settings/mcp.json
   ```

   For Java upgrades, the power drives the `atx` CLI through shell commands. The MCP server serves
   other AWS Transform workloads.
4. Send prompt A. The power checks prerequisites and runs `atx update` and `atx custom def list`. Each
   command asks for approval:
   - Choose **Allow** for each one.
   - **Don't** choose **Always allow** for `atx` commands. `atx custom def exec … -t` changes code with
     guardrails bypassed, and you want to see each run before it starts.
5. Send prompt B. The power shows a match report and the command, and asks for plan context. Per its
   steering, it doesn't start "without explicit user consent". Confirm only if the command matches
   what you asked for. If it asks about the JDK, JDK 21 and 25 are both installed. It asks before
   installing a runtime.
6. While it runs, the power commits each step. Watch Source Control or `git log`.

**Ask Kiro (prompt A)**

```text
Set up AWS Transform custom and show me the transformations available for this repository. Do not start any transformation.
```

**Ask Kiro (prompt B)**

```text
Upgrade this repository from Spring Boot 3.5 to Spring Boot 4.1 with the AWS/spring-boot-version-upgrade transformation, in local mode, on the current branch. Plan context: Target Spring Boot 4.1.1 and keep Java 21. Do not send telemetry in this session. Pass --do-not-learn and --limit <budget>. Show me the exact atx command and wait for my confirmation before you run it.
```

Replace `<budget>` with the number of Agent Minutes you are willing to spend. Avoid commas in the plan
context; the power's troubleshooting notes warn against them.

> Verify: whether the power passes `--do-not-learn` and `--limit` when asked. Check the command it
> shows you before you confirm. The docs document both flags for the CLI. They don't say whether the
> power honours the request.

**Verify**

```bash
git log --format='%h %an %s' stage-2..HEAD
grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
git diff --stat workshop -- pom.xml src
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
git status --short
```

Look for:

- Checkpoint commits by `ATX Bot`, the documented default author when the CLI's author variables
  aren't set.
- The parent version. 4.1.0 is what the catalog targets, so bump it if you compare with 4.1.1.
- The files that differ from your stage 3 on `workshop`.
- The test count (14). If `validUserIsCreated` fails with 400, the transformation kept
  `@AllArgsConstructor` on `User`: the Jackson 3 trap from Exercise 3.4.
- Any untracked files, for example a `.kiro/specs/aws-transform/` folder that the power's generic
  flow can create.

Then ask Kiro (Default agent) to compare. Run `git diff workshop -- pom.xml src` in the terminal first,
so the diff is in `#terminal`:

```text
#terminal This diff compares the AWS Transform result (working tree) with my stage 3 on the workshop branch. List, as a table, what the transformation did differently: dependencies, imports, Jackson configuration, security, tests. Mark each difference as "equivalent", "worse" or "better" and explain why. Do not change any files.
```

**Clean up**

```bash
git switch workshop
git branch -D lab/aws-transform
```

Keep the branch instead if you want to compare later.

**Checkpoint:** nothing from the lab lands on `workshop`.

Docs: [Powers registry](https://kiro.dev/powers/) · [Install powers](https://kiro.dev/docs/powers/installation/) ·
[MCP configuration](https://kiro.dev/docs/mcp/configuration/) · [Permissions](https://kiro.dev/docs/permissions/) ·
[AWS Transform developer tools](https://docs.aws.amazon.com/transform/latest/userguide/developer-tools.html)

### Exercise A.3: OpenRewrite as an alternative accelerator (read it; run it only with access)

**Goal:** know the recipes, how to run them, and the licensing and distribution terms that decide
whether you may.

**The recipes** (from the recipe pages on [docs.openrewrite.org](https://docs.openrewrite.org/), checked
2026-10-09)

| Recipe | What it does |
|---|---|
| `org.openrewrite.java.migrate.UpgradeToJava25` (artifact `org.openrewrite.recipe:rewrite-migrate-java`) | "This recipe will apply changes commonly needed when migrating to Java 25." It also replaces deprecated APIs and updates build files and plugins. Its list starts with "Migrate to Java 21" and includes "Remove Security SecurityManager". |
| `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5` | "Migrate to Spring Boot 3.5 (Community Edition)". It's the first recipe in the Boot 4.0 recipe's list. Use it on its own to bring an older service to 3.5 before the Boot 4 jump. |
| `org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0` (artifact `org.openrewrite.recipe:rewrite-spring`) | "Migrate to Spring Boot 4.0 (Community Edition)". Its list includes "Migrate to Spring Framework 7.0", "Migrate to Spring Security 7.0", "Replace @MockBean and @SpyBean", "Migrate to Spring Boot 4.0 modular starters (Community Edition)", a `spring-boot-starter-web` → `spring-boot-starter-webmvc` change, and "Migrate to Hibernate 7.1.x (Community Edition)". |

Things to notice:

- The Boot 4 recipe sets versions to `newVersion: 4.0.x`, not 4.1.x. After it runs, you still bump the
  parent to 4.1.1. 4.1.1 also manages a newer Hibernate (7.4.5) than the recipe's 7.1 migration.
- The Java 25 recipe's examples change `maven.compiler.release`.
- Two of the Java 25 recipe's examples come from a test named `EnableLombokAnnotationProcessorTest`,
  a hint that it may also declare Lombok as an annotation processor. Compare its `pom.xml` change with
  your task 3.

> Verify: whether `UpgradeToJava25` updates the Spring Boot `java.version` property and adds Lombok to
> `annotationProcessorPaths`. Also check which Spring Boot versions `UpgradeSpringBoot_3_5` starts from,
> on its recipe page.

> **Licensing and distribution:** check both before you run these recipes at work.
>
> - **Licence.** Both recipe pages say: "This recipe is available under the Moderne Source Available
>   License." Per [OpenRewrite licensing](https://docs.openrewrite.org/licensing/openrewrite-licensing):
>   - "if you work at a company and you want to run these recipes on your own code you are free to
>     do so".
>   - But "The software may not be commercialized or provided to others as a managed service", and
>     "you can't provide consulting/professional services where you charge people and run these
>     recipes."
>   - The core framework and the Maven and Gradle plugins are Apache-licensed.
>   - Recipes to "Upgrade to the latest Spring Boot, Spring Framework, and Hibernate releases" are also
>     offered to Moderne customers under the Moderne Proprietary License.
> - **Distribution is changing.** "Recipes are moving from Maven Central to the Code Genome Project."
>   The recipe pages add: "OpenRewrite artifacts, including the Maven and Gradle plugins themselves,
>   are distributed through the Code Genome Project repository
>   (https://artifacts.codegenomeproject.org/maven), which requires authentication." They also say:
>   "Moderne customers can download precompiled artifacts from The Code Genome Project. For
>   non-commercial use you can build the artifact from source locally."
>
> Verify with your legal or procurement team, and with the Code Genome Project quickstart, how your
> company may obtain the artifacts.

**Run it (only if you have Code Genome Project credentials)**

1. Put the credentials in your user Maven settings, `~/.m2/settings.xml`, never in the repository.
   This is the shape the recipe pages show for the command line, with `USERNAME` and `TOKEN` as
   placeholders:

   ```xml
   <settings>
     <servers>
       <server>
         <id>codegenome</id>
         <username>USERNAME</username>
         <password>TOKEN</password>
       </server>
     </servers>
     <profiles>
       <profile>
         <id>codegenome</id>
         <repositories>
           <repository>
             <id>codegenome</id>
             <url>https://artifacts.codegenomeproject.org/maven</url>
           </repository>
         </repositories>
         <pluginRepositories>
           <pluginRepository>
             <id>codegenome</id>
             <url>https://artifacts.codegenomeproject.org/maven</url>
           </pluginRepository>
         </pluginRepositories>
       </profile>
     </profiles>
     <activeProfiles>
       <activeProfile>codegenome</activeProfile>
     </activeProfiles>
   </settings>
   ```

2. Create the lab branch from `stage-2`, then run the recipes yourself in the terminal. Your `mvn *`
   rule would let the agent run them without asking, but you want to see the downloads and the
   diff. The plugin version below (`6.49.0`) is the one the recipe pages showed on 2026-10-09; use the
   version the page shows today:

   ```bash
   git switch -c lab/openrewrite stage-2
   mvn -U org.openrewrite.maven:rewrite-maven-plugin:6.49.0:run --define rewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE --define rewrite.activeRecipes=org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0 --define rewrite.exportDatatables=true
   git add -A
   git commit -m "lab: OpenRewrite UpgradeSpringBoot_4_0"
   mvn -U org.openrewrite.maven:rewrite-maven-plugin:6.49.0:run --define rewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-migrate-java:RELEASE --define rewrite.activeRecipes=org.openrewrite.java.migrate.UpgradeToJava25 --define rewrite.exportDatatables=true
   git add -A
   git commit -m "lab: OpenRewrite UpgradeToJava25"
   ```

3. Review and compare, the same way as Exercise A.2. Then clean up:

   ```bash
   git diff --stat workshop -- pom.xml src
   mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
   git switch workshop
   git branch -D lab/openrewrite
   ```

**Verify:** you can say what each recipe would have done for this app, and what it would have left for
you: the 4.0.x → 4.1.1 bump, the Jackson properties, and possibly the Lombok processor declaration and
the `@AllArgsConstructor` fix (the test count and `validUserIsCreated` tell you). You can also say
under which terms your company may run the recipes.

**A good combination for large codebases:**

1. Run a recipe for the bulk mechanical changes on a branch.
2. Commit the result.
3. Let a Kiro spec finish what the recipe didn't cover, with the verify hook and the test count as
   gates.

**Checkpoint:** nothing from the lab lands on `workshop`.

Docs: [Checkpoints (why you commit first)](https://kiro.dev/docs/checkpoints/) ·
[Permissions](https://kiro.dev/docs/permissions/)

### Appendix troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `atx custom def list` fails with an access error | IAM permissions are missing | Attach `AWSTransformCustomFullAccess`, or ask your administrator to add it to your SSO permission set. |
| The AWS Transform power stops on Windows | Its steering asks for WSL | Run Kiro and the lab from WSL, macOS or Linux. |
| OpenRewrite can't resolve the plugin or recipe (401 or "Could not find artifact") | Artifacts moved to the authenticated Code Genome Project repository | Configure `~/.m2/settings.xml` (Exercise A.3), or skip the run. |
| Restore didn't undo the AWS Transform or OpenRewrite changes | Checkpoints don't capture shell or MCP changes | Use git on the lab branch: `git restore .`, then `git clean -nd` to preview and `git clean -fd` to remove untracked files. Or switch away and delete the lab branch. |
