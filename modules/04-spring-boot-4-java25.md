<!-- runbook max-lines=600 -->
# Module 4: Spring Boot 4.1 and Java 25 (80 minutes)

Module 4 of 5 · [← Module 3](03-spring-boot-3.md) · [Module 5 →](05-quality-gates.md) ·
[Day sheet](../docs/quick-reference.md) · [Troubleshooting](../docs/troubleshooting.md) ·
[Why and background](why/04-spring-boot-4-java25.md)

Stage 2 (Spring Boot 3.5.16, Java 21) to stage 3, the target: Spring Boot 4.1.1 on Java 25. Java 17 is
the floor; Jakarta EE 11 and Spring Framework 7 are the baseline; starters are modular; Jackson 3
(`tools.jackson`) replaces Jackson 2; `@MockBean` is gone; 3.x deprecations are removed
([sources and managed versions](why/04-spring-boot-4-java25.md#what-spring-boot-4-changes)).

## At a glance

| | |
|---|---|
| **Goal** | Stage 3: Spring Boot 4.1.1 on Java 25, modular starters, Jackson 3, Lombok as an annotation processor, 14 tests |
| **Time** | 80 minutes |
| **Start** | Tag `stage-2`; JDK 21 the default; `MIGRATION-NOTES.md` has `Stage 2 → 3: deprecations to fix first` (Module 3, Finish); JDK 25 installed; trusted workspace, `mvn *` allowed, Supervised. Behind? `../scripts/reset-to-stage.sh 2` |
| **Hooks** | `verify-after-spec-task` **on**, `jakarta-import-guard` **on**, for the whole module |
| **JDK change** | 21 → 25 in Exercise 4.10, with a Kiro restart. No JDK 25? See [Variant](#variant-no-jdk-25) |
| **End** | Tag `stage-3`: `Stage 3: Java 25, Spring Boot 4.1.1, Tests run: 14` |
| **You produce** | The `java-modernization` power installed, a Plan, the Quick Spec `stage-3-boot4`, stage 3 |
| **Running late** | Skip Exercise 4.1 but still do 4.2 (the power is installed per user and the spec uses it); the instructor demos 4.3; in Exercise 4.12 skip the app start but keep step 1. Never skip the test-count checks or the `stage-3` tag. |

**The build stays green, with one planned exception:** the 4.1.1 parent exposes a Jackson 3 trap that
only `validUserIsCreated` catches (Exercise 4.9). **Any other red build means a change is incomplete.**
The framework moves first, then the JDK (Boot 4 runs on Java 17+): one variable at a time.

| After | Spring Boot | `java.version` | JDK | `mvn -B clean verify` | Tests run |
|---|---|---|---|---|---|
| Exercise 4.5 | 3.5.16 | 21 | 21 | passes | 14 |
| Task 1 (Jackson properties) | 3.5.16 | 21 | 21 | passes | 14 |
| Task 2 (Spring Boot 4.1.1) | 4.1.1 | 21 | 21 | **fails**: `validUserIsCreated` | 14, Failures: 1 |
| Task 2 fix (no `@AllArgsConstructor` on `User`) | 4.1.1 | 21 | 21 | passes | 14 |
| Task 3 (Java 25, Lombok processor) | 4.1.1 | 25 | 25 | passes | 14 |

After each spec task the verify hook runs **one** `mvn -B clean verify` and gives the agent the
`Tests run` line and `BUILD SUCCESS` (on failure, the last 80 lines). It passes **even if fewer tests
ran**: read the number. Run your own build only **after the hook has finished** (builds share `target/`).

## Before you start

`../scripts/verify-stage.sh 2` and `grep -n -A6 "deprecations to fix first" MIGRATION-NOTES.md`\
**Expect:** `PASS: stage 2, Java 21, Spring Boot 3.5.16, Tests run: 14, …` and your deprecation list.\
**If not:** reset with `../scripts/reset-to-stage.sh 2` (then add the deprecation section from Module 3's
Finish, step 2).

## Exercises

| # | Exercise | Min |
|---|---|---|
| 4.1 | [Read the power before you install it](#41-read-the-power-before-you-install-it) | 4 |
| 4.2 | [Import the power from a folder](#42-import-the-power-from-a-folder) | 3 |
| 4.3 | [Plan the upgrade with the power](#43-plan-the-upgrade-with-the-power) | 8 |
| 4.4 | [List the deprecations](#44-list-the-deprecations) | 4 |
| 4.5 | [`@MockBean` → `@MockitoBean`, still on 3.5.16](#45-mockbean--mockitobean-still-on-3516) | 6 |
| 4.6 | [Create the spec](#46-create-the-spec) | 6 |
| 4.7 | [Review the spec before any task runs](#47-review-the-spec-before-any-task-runs) | 4 |
| 4.8 | [Task 1: the Jackson settings as properties](#48-task-1-the-jackson-settings-as-properties) | 5 |
| 4.9 | [Task 2: Spring Boot 4.1.1, modular starters, and the Jackson 3 trap](#49-task-2-spring-boot-411-modular-starters-and-the-jackson-3-trap) | 10 |
| 4.10 | [Switch to JDK 25 and restart Kiro](#410-switch-to-jdk-25-and-restart-kiro) | 5 |
| 4.11 | [Task 3: `java.version` 25 and the Lombok processor](#411-task-3-javaversion-25-and-the-lombok-processor) | 10 |
| 4.12 | [Prove it's Java 25, then run the app](#412-prove-its-java-25-then-run-the-app) | 10 |
| | [Finish: tag `stage-3`](#finish-tag-stage-3) | 5 |

## The `java-modernization` power

### 4.1 Read the power before you install it
**Goal:** know what a power is and how it activates.

**Do:** look at the power (outside the workspace, so the agent can't see it until you install it):

```bash
find ../powers/java-modernization -type f | sort
cat ../powers/java-modernization/plugin.json
grep -m2 -E "^(name|description):" ../powers/java-modernization/skills/*/SKILL.md
```

**Expect:** a `keywords` array in `plugin.json`. **Keywords are the activation triggers**: when one
appears in your conversation, the power activates and its skills load as needed. Unlike a workspace
skill, a power is installed per user, so cloning the repository doesn't install it for a teammate.\
**Why:** [the power format, and powers vs workspace skills](why/04-spring-boot-4-java25.md#41-read-the-power-before-you-install-it)

### 4.2 Import the power from a folder
**Do**
1. Open the **Powers** panel (the ghost icon with the lightning bolt).
2. Choose **Add Custom Power** → **Import power from a folder**.
3. Select `powers/java-modernization`, the folder that contains `plugin.json` (not `powers/`, not the
   repository root), then click **Install**.

**Expect:** `java-modernization` is listed in the Powers panel; `git status --short` prints nothing
(installing a power is a per-user action).\
**If not:** [T-K34](../docs/troubleshooting.md#t-k34-add-custom-power-rejects-the-folder-or-no-power-appears)

### 4.3 Plan the upgrade with the power
**Goal:** a read-only plan for stage 3 that names every file to change.

**Do**
1. Click **+** in the chat panel and choose **Plan** on **Let's build**. Plan can't write files or run
   commands.
2. Send the prompt (its keywords "Spring Boot 4", "Java 25" activate the power). Answer clarifying
   questions briefly: "Plan only. Targets are in migration-standards."
3. Plan can't run commands, so your `grep` is the ground truth:

   ```bash
   grep -nE "<artifactId>spring-boot-starter|spring-security-test|<java.version>" pom.xml
   grep -rnE "^import .*(MockBean|WebMvcTest|jackson)" src
   ls src/main/java/com/example/usermanagement/config/
   grep -nE "and\(\)|antMatchers|authorizeRequests|WebSecurityConfigurerAdapter" src/main/java/com/example/usermanagement/config/SecurityConfig.java
   ```

**Watch out:** **don't approve the plan.** "Once you approve the plan, execution begins automatically."

**Prompt**

```prompt
Plan the Spring Boot 4.1 and Java 25 upgrade for this project: from stage 2 (Spring Boot 3.5.16,
Java 21) to stage 3 in migration-standards (Spring Boot 4.1.1, Java 25). List every file that must
change, what changes in it and why, in the order you would make the changes. Mark which changes can
be made now, while the project is still on Spring Boot 3.5.16. Say explicitly whether SecurityConfig
needs changes for Spring Security 7. At the end, name the powers, skills and steering files you
used. Mark anything you are not sure about as "unverified". This is a plan only; do not change any
files.
```

**Expect:** the starters and `java.version` 21; the `MockBean`, `WebMvcTest` and Jackson imports;
`JacksonConfig.java`; **no output** from the last command (lambda DSL already). The plan covers each
item, with `@MockBean` and Jackson doable on 3.5.16 ([an example plan](why/04-spring-boot-4-java25.md#43-plan-the-upgrade-with-the-power)).\
**If not:** the power wasn't used → [T-K35](../docs/troubleshooting.md#t-k35-the-power-is-never-used) ·
Plan started editing → [T-K10](../docs/troubleshooting.md#t-k10-plan-started-editing-files)

## Fix deprecations on 3.5 first

### 4.4 List the deprecations
**Goal:** see what Boot 4 will remove. `clean` forces a full recompile; `test-compile` includes the
tests, where `@MockBean` lives. Don't add `-q`: it hides warnings.

**Do:** `mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true -Dmaven.compiler.showWarnings=true | grep -iE "deprecat|removal"`

**Example answer:**

```text
[WARNING] /…/controller/UserControllerTest.java:[9,48] org.springframework.boot.test.mock.mockito.MockBean in org.springframework.boot.test.mock.mockito has been deprecated and marked for removal
```

**Expect:** at least the `MockBean` deprecation. Note other warnings in `MIGRATION-NOTES.md`; fix on 3.5
only those with a replacement there. Mockito's "self-attaching" warning is noise
([T-B17](../docs/troubleshooting.md#t-b17-mockito-is-currently-self-attaching-or-a-java-agent-was-loaded-dynamically)).\
**Commit:** if you added notes: `git add MIGRATION-NOTES.md && git commit -m "Notes: stage 2 deprecation listing"`

### 4.5 `@MockBean` → `@MockitoBean`, still on 3.5.16
**Goal:** one moving part fewer for the Boot 4 bump. `@MockitoBean` comes from Spring Framework 6.2,
which 3.5.16 already manages ([why it already works](why/04-spring-boot-4-java25.md#45-mockbean--mockitobean-still-on-3516)).

**Do**
1. Check that the tree is clean. New session (**+**), Default agent. Send the prompt.
2. **Accept** only the import and the annotation in `UserControllerTest.java`.
3. After the agent's build (the `grep` skips comments):

   ```bash
   git diff --stat
   grep -rnE '^import .*Mock(ito)?Bean;|^[[:space:]]*@Mock(ito)?Bean' src/test
   mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true -Dmaven.compiler.showWarnings=true | grep -iE "deprecat|removal"
   ```

**Prompt**

```prompt
We are still on Spring Boot 3.5.16 and Java 21 (stage 2). In
src/test/java/com/example/usermanagement/controller/UserControllerTest.java, replace Spring Boot's
deprecated @MockBean with Spring Framework's @MockitoBean from
org.springframework.test.context.bean.override.mockito. Change only that import and that annotation;
keep every test, every assertion, @WithMockUser and @Import(SecurityConfig.class). Do not touch
pom.xml or any other file. Then run `mvn -B clean verify` as a single command without pipes and
report the Tests run, Failures, Errors and Skipped totals.
```

**Expect:** only `UserControllerTest.java` changed; two `MockitoBean` lines (import and annotation); no
`MockBean` warning; the agent reported `Tests run: 14` with no failures.\
**Commit:** `git add -A && git commit -m "Stage 3 prep: @MockBean -> @MockitoBean on Spring Boot 3.5.16"`

## Quick Spec `stage-3-boot4`

The spec puts the changes in order, gates each one with the verify hook, and keeps a reviewable record
in `.kiro/specs/`. **Don't use Run all Tasks**: task 3 needs JDK 25. Click each task item in `tasks.md`.

### 4.6 Create the spec
**Goal:** `requirements.md`, `design.md` and `tasks.md`, with three tasks in two phases. Quick Spec
writes all three in one pass, without approval gates; you review them before any task runs
([Quick Spec vs a Feature Spec](why/04-spring-boot-4-java25.md#46-create-the-spec)).

**Do**
1. Check that the tree is clean. New session (**+**), choose **Quick Spec** (on **Let's build**, or in
   the agent selector).
2. Send the prompt. If your stage-2 count isn't 14, use your number. Answer clarifying questions in
   one line.

**Prompt**

```prompt
Create a spec named stage-3-boot4 for stage 3 in migration-standards: upgrade this service from
Spring Boot 3.5.16 on Java 21 to Spring Boot 4.1.1 on Java 25 (Spring Framework 7, Spring Security
7, Jackson 3, Hibernate 7, JUnit 6). Use the java-modernization power's skills and the official
Spring Boot 4.0 migration guide as the source of truth. Write the requirements in EARS notation.

Constraints:
- Two phases. Phase A runs on JDK 21 and keeps java.version 21. Phase B moves the build to Java 25;
  I switch the JDK myself before phase B.
- Baseline: the stage-2 tag records Tests run: 14. Do not run Maven yourself after a task; the
  verify hook runs `mvn -B clean verify` and reports the Tests run line. Quote that line in your
  summary. A task is done only if the build passes AND Tests run is at least 14.
- Create exactly three tasks, in this order:
  1. (Phase A, still Spring Boot 3.5.16) Delete config/JacksonConfig.java and configure the same
     behaviour in application.properties with spring.jackson.default-property-inclusion=non_null and
     spring.jackson.time-zone=UTC. Do not add a JsonMapperBuilderCustomizer, spring-boot-jackson2 or
     spring.jackson.use-jackson2-defaults. Drop comments in application.properties that only explain
     stage-2 changes.
  2. (Phase A) In one task: set the spring-boot-starter-parent version to 4.1.1 and remove the
     stage-2 comment above it; replace spring-boot-starter-web with spring-boot-starter-webmvc;
     replace spring-boot-starter-test with spring-boot-starter-webmvc-test (test scope); replace
     org.springframework.security:spring-security-test with
     org.springframework.boot:spring-boot-starter-security-test (test scope); change the @WebMvcTest
     import in UserControllerTest to org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest.
     If UserControllerTest still uses @MockBean, replace it with @MockitoBean. No classic starters,
     no other new dependencies, no version pins. Change only pom.xml and UserControllerTest in this
     task. If the verify hook then reports a failing test, do not fix it: change no test, add no
     property, quote the failing test and its assertion message, and stop. I diagnose it and tell
     you the fix.
  3. (Phase B) First run `mvn -v` and stop unless it reports Java 25. Then set java.version to 25
     and change the pom description to "Stage 3: Spring Boot 4.1 on Java 25 (Jakarta EE 11)".
     Declare Lombok as an annotation processor, because JDK 23+ no longer runs processors found only
     on the class path: add org.apache.maven.plugins:maven-compiler-plugin (no version; the parent
     manages it) with annotationProcessorPaths containing org.projectlombok:lombok at version
     ${lombok.version}, and a one-line XML comment saying why. ${lombok.version} is the
     parent-managed version, not a pin.
- Do not change SecurityConfig; it already uses a SecurityFilterChain bean with the lambda DSL. Keep
  @Import(SecurityConfig.class), @MockitoBean and @WithMockUser in UserControllerTest.
- Behaviour must not change: 401 for unauthenticated requests to /api/users, 201 for a valid POST
  /api/users, 400 for an invalid POST /api/users that never reaches UserService, 404 for unknown
  ids, an X-Request-Id header on every response, null fields left out of JSON, dates in UTC.
- Never delete, disable or weaken a test. Do not start the application or run git commands; I do
  both.
- Out of scope: Java language modernization, virtual threads, new features. Do not invent version
  numbers.
```

**Expect:** `ls .kiro/specs/stage-3-boot4/` shows the three files, and `git status --short` shows only
new files under `.kiro/specs/`. If Kiro chose another folder name, use it wherever this module says
`stage-3-boot4`.\
**Commit:** in Exercise 4.7, after the review.

### 4.7 Review the spec before any task runs
**Goal:** catch a wrong task before it costs credits and a revert.

**Do:** open the three files and check:
- [ ] **Three tasks, in order** (Jackson, Boot 4.1.1, Java 25), each quoting the hook's `Tests run` line
  instead of running Maven itself.
- [ ] **Task 2 stops on red:** it changes only `pom.xml` and `UserControllerTest.java`, and quotes a
  failing test instead of fixing it.
- [ ] **Phase B gate:** task 3 starts with `mvn -v` and stops unless it reports 25.
- [ ] **Lombok processor:** task 3 puts Lombok in `maven-compiler-plugin` `annotationProcessorPaths` at
  `${lombok.version}`; no `<version>` on the plugin.
- [ ] **No bridges** (the `-classic` starters, `spring-boot-jackson2` and `use-jackson2-defaults` that
  let big codebases move in steps; [why not](why/04-spring-boot-4-java25.md#47-review-the-spec-before-any-task-runs)),
  no pins, no `SecurityConfig.java` edits.
- [ ] **Requirements** state the test count and behaviours as `WHEN … THE SYSTEM SHALL …`.
- [ ] **Versions:** only 3.5.16, 4.1.1, 21, 25 and 14. Delete invented ones.

If something is off, edit `tasks.md` or `requirements.md` and choose **Sync Files**.\
**Commit:** `git add .kiro/specs && git commit -m "Module 4: stage 3 spec (Quick Spec)"`

### 4.8 Task 1: the Jackson settings as properties
**Goal:** remove the Jackson 2 code while still on 3.5.16, without changing the JSON. The two
`spring.jackson.*` properties work on both 3.5 and 4.1, so the Boot 4 bump won't touch the JSON setup
([why properties beat code here](why/04-spring-boot-4-java25.md#48-task-1-the-jackson-settings-as-properties)).

**Do**
1. Check that the tree is clean, then click task 1 in `.kiro/specs/stage-3-boot4/tasks.md`. Afterwards
   the verify hook builds and reports to the agent.
2. **Accept** the deletion of `JacksonConfig.java` and the two `spring.jackson.*` lines. **Reject**
   anything in `pom.xml` or other Java files.
3. Check:

   ```bash
   ls src/main/java/com/example/usermanagement/config/
   grep -n "spring.jackson" src/main/resources/application.properties
   grep -rn "com.fasterxml.jackson.databind\|Jackson2ObjectMapperBuilderCustomizer" src
   grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
   ```

**Expect:** only `SecurityConfig.java` in `config/`; the two `spring.jackson` lines; no output from the
third command; the parent still `3.5.16`; the hook reported `Tests run: 14` and `BUILD SUCCESS`.\
**Commit:** `git add -A && git commit -m "Stage 3, task 1: Jackson settings as spring.jackson.* properties (Boot 3.5.16)"`

### 4.9 Task 2: Spring Boot 4.1.1, modular starters, and the Jackson 3 trap
**Goal:** the 4.1.1 parent, the Boot 4 starters and the relocated `@WebMvcTest`, on JDK 21, with the
same test count. `spring-boot-starter-security-test` is what makes `@WithMockUser` work on Boot 4;
`SecurityConfig` needs no change. The new parent turns one test red: you read the cause and fix it
([what task 2 changes, and why](why/04-spring-boot-4-java25.md#49-task-2-spring-boot-411-modular-starters-and-the-jackson-3-trap)).

**Do**
1. Check that the tree is clean, then click task 2 in `tasks.md`.
2. In `pom.xml` and `UserControllerTest.java`, **Accept** only: the four dependency changes, the parent
   version and its comment, the `@WebMvcTest` import, and `@MockitoBean` if you skipped Exercise 4.5.
   **Reject** changes to `SecurityConfig.java` or to assertions, and any new `<version>` tag.
3. **Expect one red test.** The hook reports `Tests run: 14, Failures: 1`:
   `UserControllerTest.validUserIsCreated`, `Status expected:<201> but was:<400>`. The agent quotes it
   and stops, as the spec asks.
4. Read the cause, after the hook has finished:

   ```bash
   mvn -B clean verify | grep -m2 -E "FAIL_ON_NULL_FOR_PRIMITIVES|HttpMessageNotReadableException"
   grep -n "AllArgsConstructor" src/main/java/com/example/usermanagement/entity/User.java
   ```

   **Expected output** (Spring's log line for the 400):

   ```output
   Resolved [org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error: Cannot map `null` into type `boolean` (set DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES …
   ```

   If the first command prints nothing, look at the MockMvc printout for `validUserIsCreated` above the
   test summary (`Resolved Exception`), or ask Kiro with `#terminal`. So Jackson 3 builds `User` through
   Lombok's `@AllArgsConstructor` (the parent compiles with `-parameters`, which keeps constructor
   parameter names in the class file) and fails on the missing primitive `active`. Nothing calls that
   constructor.
5. **Fix it** with the prompt below, in the same session. **Accept** only `User.java` (annotation and
   import removed, a one-line comment) and the note in `tasks.md`. **Reject** test changes,
   `Boolean active` or a `spring.jackson.deserialization.*` property
   ([why not the property](why/04-spring-boot-4-java25.md#why-a-valid-create-fails-on-boot-4)).
6. Check:

   ```bash
   grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
   grep -nE "<artifactId>spring-boot-starter|spring-security-test" pom.xml
   grep -rnE "WebMvcTest;|MockitoBean;|^import lombok.AllArgsConstructor|^@AllArgsConstructor" src
   git diff HEAD --stat
   mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
   ```

**Prompt** (step 5)

```prompt
validUserIsCreated fails with 400 instead of 201: Jackson 3 binds the request body through Lombok's
@AllArgsConstructor on User (the parent compiles with -parameters) and rejects the missing primitive
"active" (FAIL_ON_NULL_FOR_PRIMITIVES is on by default). Nothing calls that constructor. In
src/main/java/com/example/usermanagement/entity/User.java, remove @AllArgsConstructor and its import
and add a one-line comment saying why; keep @Data, @NoArgsConstructor and active = true. Under task
2 in .kiro/specs/stage-3-boot4/tasks.md, add a sub-item recording this fix and its cause. Change
nothing else (no test, no property) and do not run Maven.
```

**Expect:** parent `4.1.1`; starters `webmvc`, `validation`, `data-jpa`, `security`, `webmvc-test` and
`security-test`, no `spring-security-test`; the new `WebMvcTest` and the `MockitoBean` imports, and no
`AllArgsConstructor` line; only `pom.xml`, `UserControllerTest.java`, `User.java` and `tasks.md`
changed; `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` and `BUILD SUCCESS`.\
**If not:** another failure → [T-B19](../docs/troubleshooting.md#t-b19-withmockuser-tests-fail-with-401-on-spring-boot-4) ·
[T-B20](../docs/troubleshooting.md#t-b20-package-orgspringframeworkboottestmockmockito-does-not-exist) ·
[T-B21](../docs/troubleshooting.md#t-b21-package-orgspringframeworkboottestautoconfigurewebservlet-does-not-exist) ·
[T-B22](../docs/troubleshooting.md#t-b22-jackson2objectmapperbuildercustomizer-or-comfasterxmljacksondatabind-cant-be-found) ·
[T-K27](../docs/troubleshooting.md#t-k27-the-agent-adds-a--classic-starter-or-spring-boot-jackson2) ·
[T-K20](../docs/troubleshooting.md#t-k20-tasks-ran-in-parallel-or-ahead-of-time)\
**Commit:** `git add -A && git commit -m "Stage 3, task 2: Spring Boot 4.1.1, modular starters, relocated @WebMvcTest, no @AllArgsConstructor (Jackson 3)"`.
Optional: [confirm what Maven resolved](why/04-spring-boot-4-java25.md#optional-confirm-what-maven-resolved).

## Java 25, with Lombok as an annotation processor

### 4.10 Switch to JDK 25 and restart Kiro
**Goal:** your terminal, the agent and the hook all use JDK 25.

**Do**
1. Check that task 2 is committed (`git status --short` prints nothing).
2. Make JDK 25 the **default** for new terminals
   ([Change the JDK for Kiro](../docs/participant-setup.md#change-the-jdk-for-kiro-modules-2-and-4-and-after-a-reset)).
3. In a new terminal **outside Kiro**, check that `java -version` reports 25.
4. Quit Kiro, then start it from that terminal: `cd <your-clone>/sample-app && kiro .`
5. In Kiro, open a new terminal and a new chat session (Default agent). **Prompt**

   ```prompt
   Run `mvn -v` in the workspace root and tell me the Java version it reports. Do not run anything
   else.
   ```

**Now:** JDK 25 · hooks unchanged.\
**Expect:** `mvn -v` in Kiro's terminal and the agent's answer both report Java 25.\
**If not:** [T-A02](../docs/troubleshooting.md#t-a02-the-agents-or-the-hooks-java-is-not-your-terminals)

### 4.11 Task 3: `java.version` 25 and the Lombok processor
**Goal:** the build compiles for Java 25, with Lombok still working. Lombok is an **annotation
processor**: javac runs it while compiling to generate `User`'s getters, setters and constructors.
**Since JDK 23, javac no longer runs annotation processors that are only on the class path.**
Undeclared, Lombok never runs and the build fails with `cannot find symbol` (for example `getEmail()`)
before any test runs. Listing it in `maven-compiler-plugin`'s `annotationProcessorPaths` (the
compiler's list of processors to run) is the explicit configuration javac needs; `${lombok.version}`
reuses the parent-managed 1.18.46, so it isn't a pin.

**Do**
1. Check that no old pins survived (expect no output):
   `grep -nE "<byte-buddy.version>|<lombok.version>|<maven.compiler" pom.xml`
2. Click task 3 in `tasks.md`. Its first step must report Java 25, otherwise it stops.
3. **Accept** only `java.version` 25, the description, and the `maven-compiler-plugin` block with Lombok
   in `annotationProcessorPaths`. **Reject** a `<version>` on the plugin, a literal Lombok version such
   as `1.18.46`, and hand-written getters or setters.
4. Check: `grep -n "<java.version>" pom.xml` and `grep -n -A8 "<artifactId>maven-compiler-plugin</artifactId>" pom.xml`

**Expect:** `<java.version>25</java.version>`; `lombok` with `<version>${lombok.version}</version>` inside
`<annotationProcessorPaths>`; the hook reported `Tests run: 14` and `BUILD SUCCESS`, matching the
`stage-2` tag message (`git show stage-2 --no-patch`).\
**If not:** [T-B11](../docs/troubleshooting.md#t-b11-cannot-find-symbol-for-getters-setters-or-constructors-on-jdk-25) ·
[T-B02](../docs/troubleshooting.md#t-b02-tests-run-is-lower-than-14) ·
[T-B06](../docs/troubleshooting.md#t-b06-lombok-illegalaccesserror-lombokprocessor-cannot-access-javacprocessingenvironment)\
**Why:** [Lombok and Byte Buddy on Java 25, and what the failure looks like](why/04-spring-boot-4-java25.md#411-task-3-javaversion-25-and-the-lombok-processor)\
**Commit:** `git add -A && git commit -m "Stage 3, task 3: Java 25, Lombok declared as annotation processor"`

### 4.12 Prove it's Java 25, then run the app
**Goal:** evidence beyond "the tests passed". The tests never start JPA or the database (Mockito and a
web slice), so only a real start proves Hibernate 7 and the Jackson properties.

**Do**
1. `../scripts/verify-stage.sh 3` (a clean build, so no JDK 21 class files survive), then
   `mvn -B dependency:tree -Dincludes=org.projectlombok,net.bytebuddy`
2. Choose a local admin password, then start the app:

   ```bash
   printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD
   mvn -B spring-boot:run
   ```

3. In a second terminal in `sample-app/`, set the same password (the `printf … read` line), then run
   `../scripts/smoke.sh`.
4. Stop the app with **Ctrl+C** in the first terminal.

**Expect:** `PASS: stage 3, Java 25, Spring Boot 4.1.1, …, class files major 69` (Java 21 classes show
65); `lombok:jar:1.18.46` and `byte-buddy:jar:1.18.11`; the startup log names Java 25; every smoke check
`PASS`, including the create (`201` with `"active":true`, the Jackson 3 fix at runtime) and an ISO-8601
`createdDate` **string** ending in `Z`. JSON properties now come in alphabetical order
([example, and why](why/04-spring-boot-4-java25.md#412-prove-its-java-25-then-run-the-app)).\
**If not:** a numeric `createdDate` → [T-R08](../docs/troubleshooting.md#t-r08-createddate-is-a-number-in-the-json) ·
a 400 for the create → [T-B12](../docs/troubleshooting.md#t-b12-validuseriscreated-status-expected201-but-was400-every-create-returns-400) ·
`major version: 65` → [T-B05](../docs/troubleshooting.md#t-b05-a-trap-doesnt-show-or-old-class-files-survive)

## Finish: tag `stage-3`

**Goal:** a green, tagged stage 3 on `workshop` for Module 5, before any optional lab.

1. On `workshop`, on JDK 25, with a clean tree: `../scripts/verify-stage.sh 3` → `PASS`.
2. Update the "current state" line in `.kiro/steering/tech.md` to stage 3 (Java 25, Spring Boot 4.1.1).
   In `MIGRATION-NOTES.md`, mark the `Stage 2 → 3` deprecations done and add "JDK 23+: Lombok declared
   in `annotationProcessorPaths`" and "Jackson 3: `@AllArgsConstructor` removed from `User`".
3. In `tasks.md`, choose **Sync Files** so finished tasks are marked complete.
4. Commit and tag:

   ```bash
   git add -A
   git commit -m "Stage 3 complete: Spring Boot 4.1.1, Java 25"
   git tag -a stage-3 -m "Stage 3: Java 25, Spring Boot 4.1.1, Tests run: 14"
   git show stage-3 --no-patch
   ```

5. Optional: `../scripts/compare-stage.sh 3`. Expect only cosmetic differences (comments and layout;
   the reference `User.java` has no `@AllArgsConstructor` either). A difference in a dependency, the
   `maven-compiler-plugin` block, an import, a property, the security configuration or a Lombok
   annotation on `User` is worth a second look.

**Expect:** tag `stage-3` with `Tests run: 14` in its message. Module 5 adds `stage-3-final`.

## Variant: no JDK 25

If your company hasn't approved JDK 25 yet, finish stage 3 on JDK 21: Spring Boot 4.1.1 runs on Java 17
or later.
- Skip Exercise 4.10.
- Before you run task 3, edit it in `tasks.md` to keep `java.version` 21 and to expect Java 21 from
  `mvn -v`, then choose **Sync Files**.
- Still add the Lombok declaration: it's harmless on JDK 21 and required from JDK 23.
- In Exercise 4.12 and Finish use `../scripts/verify-stage.sh 3 --jdk 21` (class files major 65). Write
  "Java 21" in the `stage-3` tag message.
- Tell your instructor, and in Module 5 read "25" as "21".

## Check yourself

- [ ] The power is imported; you can say how it differs from a workspace skill.
- [ ] A Plan session listed the stage-3 changes, checked with `grep`; no plan was approved.
- [ ] `@MockitoBean` replaced `@MockBean` on 3.5.16; `JacksonConfig.java` is replaced by two properties.
- [ ] Parent 4.1.1 with the `-webmvc`, `-webmvc-test` and `-security-test` starters, the relocated
  `@WebMvcTest`, and `SecurityConfig.java` unchanged.
- [ ] Task 2's red `validUserIsCreated` was read from the log and fixed by removing `@AllArgsConstructor`
  from `User`, not by a property or a test change.
- [ ] Java 25 in `java.version`, `mvn -v` and the agent; major version 69; Lombok in
  `annotationProcessorPaths` with `${lombok.version}`, and you can say why JDK 23+ needs it.
- [ ] Tag `stage-3` records `Tests run: 14`.

**Something else?** [Build and tests](../docs/troubleshooting.md#b-build-and-tests) · [Kiro](../docs/troubleshooting.md#k-kiro) · [Running app](../docs/troubleshooting.md#r-running-app)

## Next

[Module 5: Quality gates →](05-quality-gates.md): review the migration with the `migration-reviewer`
custom agent, add a guard hook, fix a regression with a Bugfix spec, and tag `stage-3-final`.

## Appendix (optional, outside the 80 minutes): accelerators

The AWS Transform power and OpenRewrite, with their own prerequisites, are in
[04-appendix-accelerators.md](04-appendix-accelerators.md). Do it after the workshop day.
