# Module 2: Runway, Spring Boot 2.7 and Java 21 (90 minutes)

You take the app from stage 0 to stage 1 in two steps: Spring Boot 2.2.4 → 2.7.18 on JDK 8, then
JDK 8 → 21. A Feature spec plans the work, the agent runs the tasks, and a hook builds and reports the
test count after each task. You review every step and check what a green build can't prove: that all
the tests still ran.

## What you'll do

- Write a Requirements-First **Feature spec** `stage-1-runway` with EARS requirements for the test
  count and for `@Valid`, and review its design and tasks **before** any code changes.
- Run the tasks in **Supervised** mode with the `verify-after-spec-task` hook (`PostTaskExec`).
- Catch the traps: JUnit 4 tests that silently stop running (Boot 2.4), `@Valid` silently ignored
  (Boot 2.3), redundant `javax.*` pins and the Lombok pin on JDK 21. Byte Buddy needs no override.
- Diagnose a failure with `#terminal`, then tag `stage-1`.

## Why this stop

Spring Boot 2.2.x documents Java 8 up to 13–15, depending on the patch release, and never 21. Spring
Boot 2.7.18 supports Java 8 through 21, and the Spring Boot 3.0 Migration Guide asks for the latest
2.7.x first. So you change one variable at a time, framework then JDK, and always know which change
broke the build. Stage 1 stays on `javax.*`.

<details><summary>Background: the sources behind this order</summary>

- Spring Boot 2.2.4's system requirements document Java 8 up to Java 13. The last 2.2 patch, 2.2.13,
  raised the upper bound only to Java 15.
  ([2.2.4 System Requirements](https://docs.spring.io/spring-boot/docs/2.2.4.RELEASE/reference/html/getting-started.html),
  [2.2.13 System Requirements](https://docs.spring.io/spring-boot/docs/2.2.13.RELEASE/reference/html/getting-started.html))

> Verify: the two 2.2.x bounds are paraphrased from the linked pages; their exact wording isn't
> recorded in the workshop's research notes.

- "Spring Boot 2.7.18 requires Java 8 and is compatible up to and including Java 21. Spring Framework
  5.3.31 or above is also required."
  ([2.7.18 System Requirements](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/getting-started.html))
- The Spring Boot 3.0 Migration Guide says: "Before you start the upgrade, make sure to upgrade to the
  latest available 2.7.x version."
  ([Spring Boot 3.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide))
- Kiro has no "upgrade Java version" button. The upgrade is agent-driven: spec → tasks → agent edits →
  Maven verifies.

</details>

## Prerequisites

- Module 1 is complete: branch `workshop`, tag `stage-0` recording `Tests run: 14`, **Supervised**
  autonomy, `mvn *` on **Always allow**, steering and `MIGRATION-NOTES.md` committed.
- JDK 8 is the default for new terminals and Kiro was started from one (`kiro .`). JDK 21 is installed
  ([setup, section 1](../docs/participant-setup.md#1-jdks-8-21-and-25)) and the dependencies are
  pre-downloaded ([section 7](../docs/participant-setup.md#7-pre-download-the-dependencies-for-every-stage)).
- The `sample-app/` workspace is trusted.
- **Hooks for this whole module** (Agent Hooks panel): `verify-after-spec-task` **on**,
  `jakarta-import-guard` **off**.

Run all commands from `sample-app/` in Kiro's terminal (``Ctrl+` ``), on macOS or Linux:

```bash
git status --short
git tag -n1 -l "stage-*"
mvn -v
grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
```

Expect a clean tree, `stage-0` with `Tests run: 14`, `Java version: 1.8.0_…`, and
`<version>2.2.4.RELEASE</version>` two lines below the parent's `artifactId` (after a comment). The
total is 14 at every stage (5 web + 9 service tests); if yours differs, ask the instructor.

## Time box

| Part | Topic | Minutes |
|---|---|---|
| 1 | Feature spec (includes the instructor's demo, ≤ 5 min) | 25 |
| 2 | Phase A: Spring Boot 2.7.18 on JDK 8 | 30 |
| 3 | Phase B: JDK 8 → 21 | 20 |
| 4 | Java modernization (optional) | 10 |
| 5 | Checkpoint: tag `stage-1` | 5 |
| | **Total** | **90** |

**If you run late:** skip Part 4 and the `curl` check. More than 15 minutes behind at the start of
Part 3? Reset to stage 1 with
[the reset procedure](../solutions/README.md#reset-your-workspace-to-a-stage-the-one-procedure-all-modules-use)
(row "Module 3") and do only step 2 of Exercise 5.1.

---

## Part 1: Feature spec `stage-1-runway` (25 minutes)

A Feature spec writes `requirements.md`, `design.md` and `tasks.md` under `.kiro/specs/<name>/`.
**Requirements-First** puts *what must not change* first.

### Exercise 1.1: Get ready (2 minutes)

**Goal:** a clean tree, Supervised mode, and the hooks set.

**Steps**

1. Note your baseline (expected: 14):

   ```bash
   git status
   git tag -n1 -l stage-0
   ```

2. Settings → "Agent Autonomy" (`kiroAgent.agentAutonomy`) → **Supervised**. Spec sessions then show
   each turn's edits as hunks to **Accept** or **Reject**.
3. Agent Hooks panel: `verify-after-spec-task` on, `jakarta-import-guard` off.

**Verify:** all three hold.

**Checkpoint:** nothing to commit.

### Exercise 1.2: Create the spec (6 minutes)

**Goal:** a spec with the constraints written in from the start.

**Steps**

1. Click **+** under **Specs** in the Kiro panel (or **Spec** on a new chat's **Let's build**
   screen), then **Feature**.
2. Paste the prompt below (use your own number if it isn't 14).
3. Choose **Requirements-First** when asked; it can't be changed later.
4. Wait for `requirements.md`. Don't confirm it yet.

**Ask Kiro**

```text
Create a Feature spec named stage-1-runway for stage 1 in migration-standards: upgrade this service from Spring Boot 2.2.4 on Java 8 to Spring Boot 2.7.18 on Java 21, still on javax.*.

Constraints:
- Phase A: Spring Boot 2.7.18 while the build stays on JDK 8 (java.version 1.8). Phase B, only after phase A is green: JDK 21. I switch the JDK myself; the phase B task first runs `mvn -v` and stops unless it reports Java 21.
- Do not run Maven yourself after a task; the verify hook runs `mvn -B clean verify` and reports the Tests run line. Quote that line in your summary. The stage-0 baseline is Tests run: 14. A task is done only if the build passes AND Tests run is at least 14; a green build with fewer tests is a failed task. No separate baseline or gate tasks.
- The first phase A task changes only the spring-boot-starter-parent version and its comment. Fix each problem it reveals in a later task: one problem per task, naming the Spring Boot release note that explains it.
- Behaviour must not change: invalid input to POST /api/users gets 400 from Bean Validation (@Valid) and never reaches UserService; unauthenticated requests get 401; unknown user ids get 404; every response has an X-Request-Id header.
- Prefer versions the Spring Boot parent manages. Remove explicit javax.* API dependencies that a starter already provides. Add no version override (for example byte-buddy.version) unless a build fails without it. Any remaining pin needs an XML comment explaining why.
- Never delete, disable or weaken a test; keep JUnit 4 (JUnit 5 is stage 2).
- Do not start the application or run git commands; I do both.
- Out of scope: jakarta.*, Spring Security changes, JUnit 5, Java language modernization.

Write the requirements in EARS notation.
```

**Verify:** `ls .kiro/specs/` shows a folder (ideally `stage-1-runway`) with `requirements.md`. If
Kiro chose another name, use it wherever this module says `stage-1-runway`.

> Verify: the docs don't say how Kiro names the spec folder.

**Checkpoint:** commit at the end of Exercise 1.5.

### Exercise 1.3: Review the requirements (7 minutes)

**Goal:** testable requirements covering both silent traps.

EARS pattern: `WHEN [condition/event] THE SYSTEM SHALL [expected behavior]`. Each criterion must be
checkable by a command or a test.

<details><summary>Example: good requirements for this stage (yours will differ)</summary>

```markdown
### Requirement 1: Spring Boot 2.7.18 on JDK 8 first (phase A)
**User story:** As the maintainer, I want the framework upgraded before the JDK, so that every
failure has a single cause.
#### Acceptance criteria
1. THE SYSTEM SHALL use spring-boot-starter-parent version 2.7.18.
2. WHILE phase A is in progress THE SYSTEM SHALL build with java.version 1.8 on JDK 8.
3. WHEN phase A is complete THE SYSTEM SHALL pass `mvn -B clean verify` on JDK 8.

### Requirement 2: The test count never goes down
**User story:** As the maintainer, I want every task to prove that all existing tests still ran,
so that a green build cannot hide tests that silently stopped running.
#### Acceptance criteria
1. WHEN a task finishes THE SYSTEM SHALL report the Tests run, Failures, Errors and Skipped totals
   from the verify hook's `mvn -B clean verify`.
2. WHEN a task finishes THE SYSTEM SHALL report a Tests run total of at least 14 (the stage-0 baseline).
3. IF the Tests run total is lower than 14 THEN THE SYSTEM SHALL treat the task as failed, even when
   the build succeeds.
4. THE SYSTEM SHALL NOT delete, disable or weaken any existing test.

### Requirement 3: Bean Validation keeps rejecting invalid input
**User story:** As an API client, I want invalid users rejected, so that bad data never reaches
the database.
#### Acceptance criteria
1. WHEN a client sends POST /api/users with a name shorter than 2 characters or an invalid email
   THE SYSTEM SHALL respond with 400 Bad Request.
2. WHEN such a request is rejected THE SYSTEM SHALL NOT call UserService.createUser.
3. THE SYSTEM SHALL keep UserControllerTest.invalidUserIsRejectedByBeanValidation passing, unchanged.

### Requirement 4: Unchanged behaviour
#### Acceptance criteria
1. WHEN an unauthenticated client calls /api/users THE SYSTEM SHALL CONTINUE TO respond with 401.
2. WHEN a client requests a user id that does not exist THE SYSTEM SHALL CONTINUE TO respond with 404.
3. WHEN the service answers a request THE SYSTEM SHALL CONTINUE TO include an X-Request-Id header.

### Requirement 5: Dependencies managed by the parent
#### Acceptance criteria
1. THE SYSTEM SHALL NOT declare javax.servlet-api, javax.persistence-api or validation-api
   explicitly when a starter already provides them.
2. THE SYSTEM SHALL NOT pin the version of an artifact the Spring Boot parent manages, unless an
   XML comment next to the pin explains why.

### Requirement 6: Java 21 (phase B)
#### Acceptance criteria
1. WHEN phase B starts THE SYSTEM SHALL confirm that `mvn -v` reports Java 21, and stop otherwise.
2. THE SYSTEM SHALL set java.version to 21.
3. WHEN phase B is complete THE SYSTEM SHALL pass `mvn -B clean verify` on JDK 21 with a Tests run
   total of at least 14.

### Out of scope
- jakarta.*, Spring Security configuration changes, JUnit 5 (stage 2).
- Java language modernization (done separately in chat).
```

</details>

**Steps**

1. Check `requirements.md`:
   - [ ] Two phases, JDK 8 first, and a JDK check at the start of phase B.
   - [ ] A test count with your number that calls a green build with fewer tests a **failure**.
   - [ ] Bean Validation: the 400 response and the `invalidUserIsRejectedByBeanValidation` test.
   - [ ] Unchanged behaviour: 401, 404 and `X-Request-Id`.
   - [ ] Nothing untestable ("SHALL be robust") or invented (CI, performance targets, other versions).
   - [ ] jakarta, Spring Security, JUnit 5 and modernization are out of scope.
2. Fix gaps in the spec chat (prompt below) or in the file, then confirm. Kiro generates `design.md`.

<details><summary>Ask Kiro (only if the count criterion is missing or vague), and an optional check</summary>

```text
#spec:stage-1-runway In the test-count requirement, add this acceptance criterion: IF the Tests run total is lower than 14 THEN the task is failed, even when the build succeeds. Change nothing else.
```

Optional, if you have time: **Analyze Requirements** (in the chat options, or the **Continue**
dropdown in the editor) checks the requirement set for ambiguities and gaps. It takes minutes, not
seconds, so it doesn't fit this time box.

</details>

**Verify**

```bash
grep -nE "SHALL" .kiro/specs/stage-1-runway/requirements.md | head -n 30
grep -nE "Tests run|400|@Valid|Bean Validation" .kiro/specs/stage-1-runway/requirements.md
```

Look for: EARS lines, your baseline number, and the 400 criterion.

**Checkpoint:** not yet.

### Exercise 1.4: Review the design (5 minutes)

**Goal:** a safe order, named risks, and no uncheckable claims.

**Steps**

1. In `design.md`, check:
   - [ ] **Order:** the parent bump first and alone, on JDK 8; then the fixes; then the JDK switch.
   - [ ] **Verification:** it counts tests against the baseline. A passing build alone isn't enough.
   - [ ] **Risks:** at least Bean Validation (Boot 2.3), the Vintage engine (Boot 2.4) and the Lombok
         pin on JDK 21. Bonus: circular references (2.6), the dropped `.RELEASE` (2.4), Byte Buddy (watch
         only, no planned override), H2 2.x.
   - [ ] **No invented pins:** pinning anything the parent manages needs a written reason (`pom-rules`).
2. Let the playbook (manual steering) check the design:

**Ask Kiro**

```text
#spec:stage-1-runway #migration-playbook Compare design.md with the "Stage 1" section of the playbook. List every playbook item the design does not cover, and every claim in the design that neither the playbook nor an official Spring Boot release note supports. Answer only; do not change any files.
```

**Verify:** compare the answer with the playbook:

```bash
sed -n '/## Stage 1/,/## Stage 2/p' .kiro/steering/migration-playbook.md
```

Have Kiro add missing items as risks, **Reject** hunks outside `design.md`, then confirm the design.

**Checkpoint:** not yet.

### Exercise 1.5: Review the tasks and commit the spec (5 minutes)

**Goal:** small, ordered tasks, so you see each trap appear. Example (yours will differ):

```text
Phase A (JDK 8)
1. Change the spring-boot-starter-parent version to 2.7.18 (and its comment), nothing else
2. If Tests run dropped: restore JUnit 4 test execution (Boot 2.4 release notes)
3. If Bean Validation no longer rejects invalid input: restore it (Boot 2.3 release notes)
4. Remove the explicit javax.* API dependencies that the starters already provide
Phase B (JDK 21)
5. Run mvn -v and stop unless it reports Java 21; then set java.version to 21 and remove the Lombok version pin
```

**Steps**

1. Check `tasks.md`:
   - [ ] Task 1 changes **only** the parent version (and its comment).
   - [ ] One task per fix, **test engine first** (Part 2 shows why), pin removal after Bean Validation.
   - [ ] The phase B task opens with the `mvn -v` check.
   - [ ] No baseline, gate or Byte Buddy override task; no task builds, edits `src/test/`, starts the
         app or runs `git`.
   - [ ] A strict chain, all required. **Run all Tasks** runs independent tasks concurrently in waves
         (parallel `pom.xml` edits and builds collide) and skips optional tasks.
2. If you edited `requirements.md` or `design.md`, choose **Sync Files** in `tasks.md`.
3. Commit the spec: your rollback point for Part 2.

<details><summary>Ask Kiro (only if the order or dependencies are wrong)</summary>

```text
#spec:stage-1-runway Reorder tasks.md so that every task depends on the previous one: parent bump only, test-engine fix, Bean Validation fix, javax.* pin removal, then the phase B task. Remove any baseline, gate or Byte Buddy override task. Keep one problem per task. Do not change requirements.md or design.md.
```

</details>

**Verify:** `git status --short` shows only the three files under `.kiro/specs/stage-1-runway/`.

**Checkpoint**

```bash
git add .kiro/specs
git commit -m "Module 2: stage-1-runway spec (requirements, design, tasks)"
```

---

## Part 2: Phase A: Spring Boot 2.7.18 on JDK 8 (30 minutes)

Run the phase A tasks **one at a time** (click each task item in `tasks.md`), not with **Run all
Tasks**, so you see each trap. Task numbers follow Exercise 1.5.

**The hook** runs `mvn -B clean verify` once after each task. On success the agent gets the
`Tests run` summary and `BUILD SUCCESS` and quotes them; on failure, the last 80 lines. It passes
**whenever the build passes, even when fewer tests ran**. Green isn't done: comparing the count with
14 is your job, and requirement 2's.

**Your check:** read the `Tests run` line the agent quotes, and the hook's run in the **Kiro output
panel**. To build yourself (no credits), first wait until the hook has finished:

```bash
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
```

Expect `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` and `BUILD SUCCESS`. **Never run two Maven
builds at once**: they share `target/`.

<details><summary>Background: how the hook works</summary>

```bash
cat .kiro/hooks/verify-after-spec-task.json
```

| Field | Value | What it means |
|---|---|---|
| `trigger` | `PostTaskExec` | Fires after a spec task completes |
| `action` | `command`: `mvn -B clean verify`, then print the last `Tests run:` and `BUILD` lines | One full rebuild per task, so incremental compilation can't hide a JDK or version change |
| `timeout` | `900` | 15 minutes; the default of 60 s is too short for Maven |

- **Success (exit 0):** Kiro adds the command's stdout to the agent's context. Here that is the
  `Tests run` summary and `BUILD SUCCESS`, so the agent doesn't need to build again.
- **Failure (non-zero exit):** Kiro sends the command's stderr to the agent. The hook prints the last
  80 lines of the build there.
- Hook execution logs appear in the Kiro output panel.

Verified in the 2026-10-10 dry run (the command run as a plain shell command on Linux, Corretto):
green, it exits 0 and prints the `Tests run` line and `BUILD SUCCESS` on stdout; red, it exits 1 with
the summary on stdout and the last 80 lines, including the failing test, on stderr. That run didn't
cover how Kiro hands either stream to the agent.

</details>

### Exercise 2.1: Bump the parent: green, but nothing ran (12 minutes)

**Goal:** a full task → hook cycle, and Boot 2.4's silent trap.

**Steps**

1. In `tasks.md`, click task 1 (parent bump).
2. **Accept** the hunk only if it sets the parent to `2.7.18` (no `.RELEASE`: dropped in Boot 2.4) and
   changes at most the comment next to it.
3. When the task is Done, find the hook's run in the output panel and read the result the agent
   quotes. If the agent called the task a success, use the prompt in the block below.

**What to expect:** `BUILD SUCCESS` with `Tests run: 0, Failures: 0, Errors: 0, Skipped: 0`
(verified in the 2026-10-10 dry run, Corretto 8), against 14 in `git tag -n1 -l stage-0`. The hook
passed.

**Why:** Boot 2.4 removed the Vintage engine from `spring-boot-starter-test`. `junit:junit` is
declared, so the JUnit 4 tests compile, but nothing on the JUnit Platform runs them.

<details><summary>Background: the Spring Boot 2.4 release notes, and a prompt if the agent missed it</summary>

The version suffix: "you should update the Spring Boot version in your build.gradle/pom.xml files
from 2.3.5.RELEASE to 2.4.0."

> "If you upgrade to Spring Boot 2.4 and see test compilation errors for JUnit classes such as
> org.junit.Test, this may be because JUnit 5’s vintage engine has been removed from
> spring-boot-starter-test."
> ([Spring Boot 2.4 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.4-Release-Notes))

You get no compilation errors because this `pom.xml` declares `junit:junit` itself. The release
note's compile-error symptom is the *loud* version. Yours is the silent one. The Vintage engine is a
temporary fix: in Module 3 the tests move to JUnit Jupiter and the engine goes away.

**Ask Kiro** (only if the agent called task 1 a success). `#url` makes it read the release note
rather than rely on memory. If `#url` fails on your network, paste the quote above instead.

```text
#spec:stage-1-runway #url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.4-Release-Notes After task 1 the build is green but Tests run is 0; the stage-0 baseline is 14. By requirement 2 this task failed. Explain the cause using the linked release notes, then continue with the test-engine task. Do not change any test file.
```

</details>

4. Run task 2 (test engine). It should add the Vintage engine in test scope, without a version:

```xml
<!-- Boot 2.4+ removed the Vintage engine from starter-test; keeps the JUnit 4 tests running until stage 2 -->
<dependency>
    <groupId>org.junit.vintage</groupId>
    <artifactId>junit-vintage-engine</artifactId>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <groupId>org.hamcrest</groupId>
            <artifactId>hamcrest-core</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

   **Accept** it if no test file changed. **Reject** rewrites to JUnit 5 (Module 3).
5. The hook **fails** now (as in the 2026-10-10 dry run). That's expected: go to Exercise 2.2.

**Verify** (after the hook has finished)

```bash
mvn -B clean verify | grep -E "Tests run:.* in com\.example"
```

Look for two per-class lines again (5 and 9 tests) and one failure in `UserControllerTest`.
**Lesson:** a green build isn't a passing test suite.

**Checkpoint:** commit at the end of Exercise 2.2.

### Exercise 2.2: `@Valid` is silently ignored (9 minutes)

**Goal:** Boot 2.3's silent trap, hidden until now by the first one.

**What to expect:** with the JUnit 4 tests running again, one fails, and the hook's stderr reaches
the agent. From the 2026-10-10 dry run (Corretto 8; line numbers may differ):

```text
[ERROR] Failures:
[ERROR]   UserControllerTest.invalidUserIsRejectedByBeanValidation:... Status expected:<400> but was:<201>
[ERROR] Tests run: 14, Failures: 1, Errors: 0, Skipped: 0
```

**Why:** since Boot 2.3 the web starter no longer brings Bean Validation. The pinned `validation-api`
jar keeps the imports compiling but holds only the API, so `@Valid` does nothing and the invalid user
gets 201. In Exercise 2.1 this test didn't even run: one silent trap hid the other.

<details><summary>Background: the Spring Boot 2.3 release notes, and a prompt if the agent proposes another fix</summary>

> "As of #19550, Web and WebFlux starters do not depend on the validation starter by default anymore.
> If your application is using validation features, for example you find that javax.validation.*
> imports are not being resolved, you’ll need to add the starter yourself."
> ([Spring Boot 2.3 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.3-Release-Notes))

The `validation-api` jar holds only annotations and interfaces, not an implementation, so the invalid
user reaches the controller. In production that user would be saved. Without the test-count check you
would have shipped both problems.

**Ask Kiro** (only if the agent proposes a different fix; if `#url` fails, paste the quote above):

```text
#spec:stage-1-runway #url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.3-Release-Notes invalidUserIsRejectedByBeanValidation fails with 201 instead of 400. Using the linked release notes, explain why, and fix it in pom.xml only. Do not change the test, the controller or the entity.
```

</details>

**Steps**

1. Let the agent fix it, right after the hook failure or as task 3. The fix is the starter, without a
   version:

```xml
<!-- Boot 2.3+: no longer included in the web starter; without it @Valid is silently ignored -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

2. **Accept** only that change. **Reject** hunks in `UserControllerTest`, `UserController` or `User`:
   the test is right, the classpath is wrong.
3. If the fix happened outside task 3, choose **Sync Files** in `tasks.md` (it marks implemented tasks
   completed).

**Verify:** the latest hook result shows `Tests run: 14, Failures: 0` and `BUILD SUCCESS` (if no hook
ran after the fix, run the count check yourself). Then:

```bash
mvn -B dependency:tree -Dincludes=org.hibernate.validator | grep hibernate-validator
```

Look for `hibernate-validator` under `spring-boot-starter-validation`.

**Checkpoint**

```bash
git add -A
git commit -m "Stage 1 phase A: Boot 2.7.18 parent, Vintage engine, validation starter"
```

### Exercise 2.3: Remove the redundant `javax.*` pins (5 minutes)

**Goal:** one source per API. The starters already bring the pinned `javax.servlet-api`,
`javax.persistence-api` 2.2 and `validation-api` 2.0.1.Final (still `javax.*`), so Module 3 can then
move to `jakarta.*` through the starters alone.

**Steps**

1. Run task 4.
2. **Accept** the removal of the three `javax` blocks. **Reject** changes to Java files: the imports
   stay `javax.*` in stage 1.

**Verify:** the hook reports `Tests run: 14` and `BUILD SUCCESS`. Then:

```bash
grep -n "<groupId>javax" pom.xml
mvn -B dependency:tree | grep -E "persistence-api|validation-api|tomcat-embed-core"
```

Look for no output from `grep`, and the APIs arriving through the JPA and validation starters and
`tomcat-embed-core`.

<details><summary>Background: artifact names, the other order, and circular references (Boot 2.6)</summary>

> Verify: the exact artifact names. On Boot 2.7 they should be `jakarta.persistence-api` and
> `jakarta.validation-api` in 2.x versions, whose classes are still in `javax.*` packages.

**If you did it in the other order:** removing the pins *before* adding the validation starter breaks
compilation with errors such as `package javax.validation.constraints does not exist`. That is the
loud symptom in the 2.3 release note ("javax.validation.* imports are not being resolved"). The fix is
the same: add `spring-boot-starter-validation`.

**Only if it appears: circular references (Boot 2.6).** The Spring Boot 2.6 Release Notes say:
"Circular references between beans are now prohibited by default. If your application fails to
start due to a BeanCurrentlyInCreationException you are strongly encouraged to update your
configuration to break the dependency cycle." As a temporary escape hatch, "circular references can
be allowed again by setting spring.main.allow-circular-references to true"
([Spring Boot 2.6 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.6-Release-Notes)).
The sample app isn't expected to have a cycle. If you see this exception, ask Kiro to find and break
the cycle, and reject a hunk that only sets the property.

</details>

**Checkpoint**

```bash
git add -A
git commit -m "Stage 1 phase A: remove javax.* API pins provided by the starters"
```

### Exercise 2.4: Phase A gate (4 minutes)

**Goal:** prove phase A on JDK 8 yourself. There is no gate task.

**Steps**

1. With no hook run in progress:

```bash
mvn -v
grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
```

**Verify:** `1.8.0_…`, `2.7.18`, `Tests run: 14`, `BUILD SUCCESS`. A deprecation note about
`WebSecurityConfigurerAdapter` (Spring Security 5.7) is fine; Module 3 replaces it.

**Checkpoint:** nothing to commit; `git status --short` prints nothing.

---

## Part 3: Phase B: JDK 8 → 21 (20 minutes)

### Exercise 3.1: Switch the JDK (4 minutes)

**Goal:** your terminal, the agent and the hook all on JDK 21. The docs don't say which environment
hooks get, so you restart Kiro from a JDK 21 terminal.

**Steps**

1. `git status`: phase A is committed.
2. Make JDK 21 the default for new terminals
   ([setup, section 1](../docs/participant-setup.md#1-jdks-8-21-and-25)): SDKMAN
   `sdk default java <21.x-identifier>-amzn`, or edit the `export JAVA_HOME=…` line in `~/.zshrc` or
   `~/.bashrc` (macOS: `$(/usr/libexec/java_home -v 21)`; Linux: your JDK 21 path).
3. In a new terminal window outside Kiro, go to `sample-app/` and check that `mvn -v` reports 21.
4. **Quit Kiro** (the application, not just the window) and start it from that terminal:

   ```bash
   kiro .
   ```

5. In Kiro, start a new chat session (Default agent):

**Ask Kiro**

```text
Run `mvn -v` in the workspace root and tell me the Java version it reports. Do not run anything else.
```

**Verify:** `java -version` and `mvn -v` in Kiro's terminal, and the agent's answer, all report 21.

> Verify: which JDK the hook uses. If it still seems to be JDK 8, repeat steps 3 and 4.

**Checkpoint:** nothing to commit.

### Exercise 3.2: See the Lombok failure, and diagnose it with `#terminal` (5 minutes)

**Goal:** see why the Lombok pin (still 1.18.10, with `java.version` 1.8) blocks JDK 21, and hand
build output to the agent.

**Steps**

1. On JDK 21:

   ```bash
   mvn -B -q clean compile
   ```

   It fails with `java.lang.IllegalAccessError: class lombok.javac.apt.LombokProcessor … cannot
   access class com.sun.tools.javac.processing.JavacProcessingEnvironment` (verified in the
   2026-10-10 dry run, Corretto 21). Without `clean`, Maven may skip recompiling and hide the failure.
2. Start a new chat session (Default agent). `#terminal` attaches recent terminal output.

**Ask Kiro**

```text
#terminal The compile just failed on JDK 21. From that output, explain the root cause, name the dependency and version that causes it, and say whether Spring Boot 2.7.18 manages a version that supports JDK 21. Check the managed version with a Maven command instead of guessing. Answer only; do not change any files.
```

3. **Reject** any hunks: the fix belongs to the spec task.

**Verify:** the answer names Lombok 1.18.10 and says Boot 2.7.18 manages **Lombok 1.18.30**, the first
release with JDK 21 support. If it quotes another version without running Maven, ask for the command.

<details><summary>Background: sources, and <code>#terminal</code> vs <code>#problems</code></summary>

- Boot 2.7.18 manages Lombok 1.18.30
  ([spring-boot-dependencies at v2.7.18](https://github.com/spring-projects/spring-boot/blob/v2.7.18/spring-boot-project/spring-boot-dependencies/build.gradle)).
- The Lombok changelog says: "v1.18.30 (September 20th, 2023)" — "PLATFORM: Initial JDK21 support
  added." ([Lombok changelog](https://github.com/projectlombok/lombok/blob/master/doc/changelog.markdown))

| Use | When | Note |
|---|---|---|
| `#terminal` | A Maven build failed in the terminal | Includes the output you just saw |
| `#problems` | The editor marks problems in the file that is open | Covers the current file only |
| `#url:<link>` | You want the answer grounded in a specific release note or guide | The agent reads the page |

Maven's output is the authority. Use `#problems` as a quick follow-up on the file you are editing,
for example `#problems why is this line flagged?` with `User.java` open.

</details>

**Checkpoint:** nothing changed (`git status --short`).

### Exercise 3.3: Run the phase B task (5 minutes)

**Goal:** `java.version` 21, Lombok managed by the parent, green on JDK 21.

**Steps**

1. Click task 5. It first runs `mvn -v`; if that doesn't report 21, it stops (back to Exercise 3.1).
2. **Accept** the hunks only if they set `<java.version>21</java.version>`, remove the Lombok
   `<version>1.18.10</version>` line (keep `provided`), and change nothing else. The parent maps
   `java.version` to the compiler (`pom-rules`).
3. Read the hook's result: `Tests run: 14` and `BUILD SUCCESS`. A Byte Buddy error? See Exercise 3.4.

**Verify** (after the hook has finished)

```bash
grep -n "<java.version>" pom.xml
mvn -B dependency:tree -Dincludes=org.projectlombok | grep lombok
javap -v target/classes/com/example/usermanagement/UserManagementApplication.class | grep "major version"
```

Look for `21`, `lombok:jar:1.18.30:provided`, and `major version: 65` (Java 21 class files, as in
the 2026-10-10 dry run).

**Checkpoint**

```bash
git add -A
git commit -m "Stage 1 phase B: Java 21, Lombok managed by Spring Boot 2.7.18"
```

### Exercise 3.4: Check Byte Buddy, and a smoke run (6 minutes)

**Goal:** confirm that the Byte Buddy version the parent manages works on JDK 21, then one app start.

Mockito and Hibernate generate classes at runtime with **Byte Buddy**; Boot 2.7.18 manages
**1.12.23**, released before Java 21. In the 2026-10-10 dry run (Corretto 21) all 14 tests and the
running app worked with it, so the reference adds **no override**. Override it only if an error names
Byte Buddy and Java 21.

<details><summary>Background: Byte Buddy 1.12.23 on Java 21, and what the dry run showed</summary>

- Spring Boot 2.7.18 manages Byte Buddy 1.12.23
  ([spring-boot-dependencies at v2.7.18](https://github.com/spring-projects/spring-boot/blob/v2.7.18/spring-boot-project/spring-boot-dependencies/build.gradle)).
  That version was released on "5. February 2023"
  ([Byte Buddy release notes](https://github.com/raphw/byte-buddy/blob/master/release-notes.md)),
  seven months before Java 21, and its release notes don't claim Java 21 support.
- When Byte Buddy reads a class file newer than it supports, it throws an error saying that the class
  file version is not supported by the current version of Byte Buddy, and suggests updating Byte
  Buddy or setting the `net.bytebuddy.experimental` VM property
  ([OpenedClassReader at byte-buddy-1.12.23](https://raw.githubusercontent.com/raphw/byte-buddy/byte-buddy-1.12.23/byte-buddy-dep/src/main/java/net/bytebuddy/utility/OpenedClassReader.java)).

> Verify: the error wording above is paraphrased from the linked source; it isn't recorded in the
> workshop's research notes.

Verified in the 2026-10-10 dry run (Corretto 21): the stage-1 reference without an override passes all
14 tests, and the running app, where Hibernate uses Byte Buddy too, answered every smoke-test request.
This app's code paths don't hit that error; your own services may take others, hence the fallback below.

- Byte Buddy 1.17.8 is the version Spring Boot 3.5.16 manages
  ([spring-boot-dependencies at v3.5.16](https://github.com/spring-projects/spring-boot/blob/v3.5.16/spring-boot-project/spring-boot-dependencies/build.gradle)),
  which makes it the natural override; Module 3 removes any override at the 3.5.16 parent bump.

Optional: search a full build for Byte Buddy messages (expect no output):

```bash
mvn -B clean verify | grep -n -i -E "byte ?buddy|is not supported by the current version"
```

</details>

**Steps**

1. Check the managed version (expect `1.12.23`):

   ```bash
   mvn -B dependency:tree -Dincludes=net.bytebuddy | grep bytebuddy
   ```

2. Did the hook or a build show an error that names Byte Buddy? Only then use the block below.
   Otherwise change nothing: the reference keeps the managed version.

<details><summary>Only if an error names Byte Buddy: diagnose it, then override <code>byte-buddy.version</code></summary>

**Ask Kiro** (diagnosis first):

```text
#terminal The output above fails on JDK 21 with an error that mentions Byte Buddy. Which dependencies bring Byte Buddy, which version does Spring Boot 2.7.18 manage, and what is the smallest pom.xml change that fixes it? Use mvn dependency:tree instead of guessing. Answer only; do not change any files.
```

Then add the override in plain chat (no hook runs; you build):

**Ask Kiro**

```text
#pom.xml Spring Boot 2.7.18 manages Byte Buddy 1.12.23, which was released before Java 21, and the build fails with the Byte Buddy error above. In <properties>, add <byte-buddy.version>1.17.8</byte-buddy.version> (the version Spring Boot 3.5.16 manages) with an XML comment that names the error it fixes and says that stage 2 removes it. Change nothing else, and do not run Maven; I run the build myself.
```

**Accept** the hunk (one property and one comment inside `<properties>`), then build once:

```bash
mvn -B dependency:tree -Dincludes=net.bytebuddy | grep bytebuddy
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
```

Look for `byte-buddy` (and `byte-buddy-agent`) at `1.17.8`, `Tests run: 14` and `BUILD SUCCESS`. Your
`pom.xml` now differs from the reference by this one property; Module 3's task 1 removes it.

> Verify: Hibernate 5.6.15.Final with Byte Buddy 1.17.8 at runtime. The 2026-10-10 dry run built and
> tested an earlier stage-1 reference that had this override (Corretto 21, all tests green) but didn't
> start that app. If the override causes `net.bytebuddy` errors, remove it and tell the instructor.

```bash
git add -A
git commit -m "Stage 1 phase B: Byte Buddy override for Java 21"
```

</details>

3. Smoke-run the app. Hibernate and H2 2.x start only here: `UserServiceTest` is plain Mockito, and
   `UserControllerTest` loads only the web slice (with the security configuration).

   ```bash
   mvn spring-boot:run
   ```

   Look for `Started UserManagementApplication` and two `Generated password for this run` lines
   (unless you exported `APP_ADMIN_PASSWORD` and `APP_USER_PASSWORD`). Stop it with **Ctrl+C**, or keep
   it for the optional check below.

<details><summary>Optional (skip if late): prove that <code>@Valid</code> works at runtime</summary>

In a second terminal, use the generated `admin` password from the log:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -u admin:<password> -H "Content-Type: application/json" -d '{"name":"J","email":"not-an-email"}' http://localhost:8080/api/users
```

Look for `400`. Then stop the app with **Ctrl+C**.

In the 2026-10-10 dry run the stage-1 reference (Corretto 21) answered 401 without credentials, 200
for the list, 400 for this request, 201 for a valid user and 404 for an unknown id, each with an
`X-Request-Id` header and ISO-8601 dates. `GET /api/users/` with a trailing slash still returned 200
on Boot 2.7; Module 3 shows why that changes.

</details>

**Verify:** `byte-buddy` (and `byte-buddy-agent`) at `1.12.23` (`1.17.8` only if you added the
override), `Tests run: 14`, `BUILD SUCCESS`, and an app start with no Byte Buddy error.

**Checkpoint:** nothing to commit unless you added the override (committed in the block above);
`git status --short` prints nothing.

---

## Part 4: Light Java modernization (10 minutes, optional)

**Skip it if you're late**; Part 5 doesn't depend on it. Skipped, `User`, `UserService` and
`UserController` differ from the reference solution here and in Module 3's diff checks, as expected.

### Exercise 4.1: Modernize three classes with chat

<details><summary>Open the exercise (Goal, Ask Kiro, Verify, Checkpoint)</summary>

**Goal:** the small, behaviour-preserving changes that Java 21 and Spring 5.3 make easy, matching
the reference solution.

This is plain chat, not a spec task, so the hook doesn't run. You run the build yourself.

**Steps**

1. Check that the tree is clean (you committed at the end of Exercise 3.3, or 3.4 if you added an
   override), then start a new chat session (Default agent):

   ```bash
   git status --short
   ```

2. Send the prompt below. Review every hunk in Supervised mode.

**Ask Kiro**

```text
Modernize three classes for Java 21 without changing behaviour or any test. Make exactly these changes and nothing else:
1. entity/User.java: replace java.util.Date with java.time.Instant for createdDate and lastModifiedDate. In onCreate, call Instant.now() once and assign it to both fields.
2. service/UserService.java: replace @Autowired field injection with a private final field and a constructor. In updateUser, use var for the local user variable.
3. controller/UserController.java: replace @Autowired field injection with a private final field and a constructor. Replace @RequestMapping(method = ...) on the methods with @PostMapping, @GetMapping, @PutMapping("/{id}") and @DeleteMapping("/{id}"), and keep the class-level @RequestMapping("/api/users"). createUser returns ResponseEntity.status(HttpStatus.CREATED).body(...). getAllUsers returns List<User> and updateUser returns User directly. getUserById and deleteUser keep their ResponseEntity return types.
Do not touch the tests, SecurityConfig, JacksonConfig, RequestIdFilter or ApiExceptionHandler. Do not run Maven; I run the build myself.
```

3. **Reject** any hunk in another file, and any records or other "improvements" you didn't ask for.
   The playbook also mentions records and switch expressions. This app has no DTO or `switch` that
   benefits from them, so the reference solution leaves them out.

**Verify**

```bash
grep -rnE "@Autowired|java\.util\.Date|RequestMethod" src/main/java
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
diff -ru ../solutions/stage-1-boot27-java21/src/main src/main
```

Look for:

- No output from `grep`.
- `Tests run: 14` and `BUILD SUCCESS`. The constructor injection works with the existing
  `@InjectMocks` and `@MockBean` tests.
- Small or no differences from the reference solution. Formatting and comments may differ;
  annotations, types and return types shouldn't.

Verified in the 2026-10-10 dry run: `createdDate` and `lastModifiedDate` stay ISO-8601 but change
shape. Stage 0 (`java.util.Date`) returned `2026-10-10T14:05:14.831+0000`; the stage-1 reference
(`Instant`) returns `2026-10-10T14:05:26.019530732Z`, in UTC with up to nine fraction digits. Phase A
already changed date formatting once: "This release upgrades to Jackson 2.11 which includes a change
to the default formatting of java.util.Date and java.util.Calendar"
([Spring Boot 2.3 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.3-Release-Notes)).
No test covers it. If API clients parse these fields, check that they accept the new form.

**Checkpoint**

```bash
git add -A
git commit -m "Stage 1: java.time, constructor injection, @GetMapping and friends"
```

</details>

---

## Part 5: Checkpoint (5 minutes)

### Exercise 5.1: Commit, tag `stage-1`, record the test count

**Goal:** a known-good stage 1 that Module 3 starts from.

**Steps**

1. Final check on JDK 21 (no other build running):

   ```bash
   mvn -v
   mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
   ```

2. In `.kiro/steering/tech.md`, set the "current state" line to stage 1: Java 21, Spring Boot 2.7.18
   (Spring Framework 5.3.x), still `javax.*`, JUnit 4 on the Vintage engine.
3. `diff ../solutions/stage-1-boot27-java21/pom.xml pom.xml`. Comments, description and order may
   differ; these must match: parent `2.7.18`, `java.version` 21, no `byte-buddy.version` (unless
   Exercise 3.4 needed it), `spring-boot-starter-validation`, `junit-vintage-engine` (test,
   `hamcrest-core` excluded), Lombok without a version, no `javax` dependencies.
4. If step 1 printed `Tests run: 14` (as in your `stage-0` tag), commit and tag:

   ```bash
   git add -A
   git commit -m "Stage 1 complete: Spring Boot 2.7.18 on Java 21"
   git tag -a stage-1 -m "Stage 1: Java 21, Spring Boot 2.7.18, Tests run: 14"
   ```

**Verify**

```bash
git status --short
git tag -n1 -l "stage-*"
git log --oneline stage-0..stage-1
```

Look for a clean tree, `stage-0` and `stage-1` with the **same** `Tests run`, and the Module 1, spec,
phase A and phase B commits.

<details><summary>Optional, if time is left: ask the reviewer agent</summary>

Switch to the `migration-reviewer` agent and ask it to review `git diff stage-0..stage-1`. It usually
runs `mvn -B verify` and replies with a findings table. Don't build yourself while it runs, and run
`git status` afterwards. Module 5 covers the reviewer in depth.

</details>

### Behind or stuck?

Use [the one reset procedure](../solutions/README.md#reset-your-workspace-to-a-stage-the-one-procedure-all-modules-use)
in `solutions/README.md`, row **Module 3** (it copies `solutions/stage-1-boot27-java21/`, switches to
JDK 21 and tags `stage-1`). Then do step 2 of Exercise 5.1 and commit.

---

## Checklist

- [ ] Spec `stage-1-runway` committed, with EARS criteria for "Tests run ≥ 14" and "invalid input →
      400"; design and task order reviewed before any task ran.
- [ ] You can explain why the hook passes even when fewer tests ran.
- [ ] `Tests run: 0` after the bare bump, fixed with `junit-vintage-engine`; the 201 failure fixed
      with `spring-boot-starter-validation`, not by changing the test.
- [ ] No `javax` dependencies and no Lombok version in `pom.xml`; Byte Buddy managed by the parent
      (1.12.23), with no override unless an error named Byte Buddy.
- [ ] JDK 21 is the default, Kiro restarted with `kiro .`, `#terminal` used, and the app starts.
- [ ] Optional: `java.time.Instant`, constructor injection, `@GetMapping`-style annotations.
- [ ] Tag `stage-1` records the same `Tests run` as `stage-0` (14).

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `BUILD SUCCESS` but `Tests run: 0`, or no Tests run line | Boot 2.4+ removed the Vintage engine from `spring-boot-starter-test` | Add `junit-vintage-engine` (Exercise 2.1). |
| `invalidUserIsRejectedByBeanValidation`: `expected:<400> but was:<201>` | The Boot 2.3+ web starter no longer brings Bean Validation | Add `spring-boot-starter-validation`. Never change the test. |
| Random compile or Surefire errors that go away on a rerun | Two Maven builds overlapped in `target/` | Wait for the hook, then run `mvn -B clean verify` once. Run tasks one at a time. |
| `mvn -v` (yours or the agent's) still reports 1.8 | Default JDK not changed, or Kiro not restarted from a JDK 21 terminal | Exercise 3.1: change the default, quit Kiro, start it with `kiro .`. |

<details><summary>More symptoms</summary>

| Symptom | Cause | Fix |
|---|---|---|
| `IllegalAccessError`: `lombok.javac.apt.LombokProcessor` cannot access `com.sun.tools.javac.processing.JavacProcessingEnvironment` | Lombok pinned to 1.18.10, which can't run on JDK 16+ | Remove the Lombok `<version>`; Boot 2.7.18 manages 1.18.30. |
| Maven can't resolve parent `2.7.18.RELEASE` | Spring Boot dropped the `.RELEASE` suffix in 2.4 | Use `<version>2.7.18</version>`. |
| `package javax.validation.constraints does not exist` | The `validation-api` pin was removed before the validation starter was added | Add `spring-boot-starter-validation`. |
| `BeanCurrentlyInCreationException` at startup or in a test | Boot 2.6+ prohibits circular references | Break the cycle. Use `spring.main.allow-circular-references=true` only as a temporary measure. |
| The agent says a task succeeded, but the count is below 14 | The hook exits 0 whenever the build passes; a drop shows only in the `Tests run` line it reports | Requirement 2 makes this a failure. Tell the agent with `#spec:stage-1-runway` and the numbers. |
| The agent runs `mvn` itself after a task | The spec constraint is missing | Add "Do not run Maven yourself after a task; the verify hook runs it" to the spec, and wait for the hook. |
| The hook never runs | Hook disabled, or the work wasn't a spec task (plain chat doesn't fire `PostTaskExec`) | Check the eye icon in the Agent Hooks panel and the Kiro output panel. Run spec tasks from `tasks.md`. |
| Hook times out | First build after the bump downloads many artifacts | With no hook running, run `mvn -B clean verify` once yourself to fill the local repository, then rerun the task. |
| The hook's build doesn't seem to include the hunks you just accepted | > Verify: in Supervised mode, when the hook runs relative to your Accept | After accepting, wait for the hook, then run the count check yourself. |
| Run all Tasks edits `pom.xml` in parallel tasks | Independent tasks run concurrently in waves | Make the tasks a chain (Exercise 1.5), or run them one by one. |
| `#spec:stage-1-runway` finds nothing | Kiro named the spec folder differently | Run `ls .kiro/specs/` and use that name. |
| `#url` fails or is very slow | Web fetch blocked or slow on your network | Paste the quote from the module's Background block instead. |
| The agent rewrites tests to JUnit 5, or adds `@Ignore` | Out of scope for stage 1; against `migration-standards` | **Reject** the hunks; add `#steering:migration-standards.md` to your next prompt. |
| No Lombok error on JDK 21 in Exercise 3.2, or `javap` shows major version 52 | Incremental compilation skipped the classes | Keep `clean` in every build command. |
| A Mockito or Hibernate error that names Byte Buddy and Java 21 (class file version not supported by the current version of Byte Buddy) | Managed Byte Buddy 1.12.23 predates Java 21; this app didn't hit it in the 2026-10-10 dry run | Only then override: `<byte-buddy.version>1.17.8</byte-buddy.version>` (Exercise 3.4). |
| Errors from `net.bytebuddy` classes after adding the override | > Verify: 1.17.8 with Hibernate 5.6.15 at runtime (the tests passed with it in the 2026-10-10 dry run) | Remove the override and tell the instructor (dry-run notes). |
| `mvn spring-boot:run`: port 8080 already in use | Another process uses the port | Stop it, or run `SERVER_PORT=8081 mvn spring-boot:run`. |
| An agent turn went wrong | Unwanted edits | **Revert** (last turn) or **Restore** (checkpoint), then `git status` and `git restore <file>`. Checkpoints don't capture what `mvn` changed on disk; your commits do. |

</details>

## Kiro features used

Feature spec (Requirements-First, EARS, Sync Files), Supervised mode, `PostTaskExec` hook, context
providers, manual and `fileMatch` steering, permissions, checkpoints, `kiro .`.

<details><summary>Docs for each feature</summary>

| Feature | Docs |
|---|---|
| Feature spec, Requirements-First, EARS | <https://kiro.dev/docs/specs/feature-specs/> · <https://kiro.dev/docs/specs/feature-specs/requirements-first/> |
| Running tasks one by one, Run all Tasks (waves), task status | <https://kiro.dev/docs/specs/> |
| Sync Files, `#spec:<name>`, Analyze Requirements | <https://kiro.dev/docs/specs/best-practices/> · <https://kiro.dev/docs/specs/feature-specs/> |
| Supervised mode (Accept / Reject per hunk) | <https://kiro.dev/docs/ide/chat/autopilot/> |
| `PostTaskExec` command hook, stdout/stderr to the agent, timeout | <https://kiro.dev/docs/hooks/> · <https://kiro.dev/docs/hooks/types/> · <https://kiro.dev/docs/hooks/actions/> |
| Hook logs in the Kiro output panel | <https://kiro.dev/docs/hooks/troubleshooting/> |
| Context providers `#terminal`, `#problems`, `#url`, `#spec`, `#steering`, files | <https://kiro.dev/docs/ide/chat/> |
| Manual steering (`#migration-playbook`), `fileMatch` steering (`pom-rules`) | <https://kiro.dev/docs/steering/> |
| Permissions (`mvn *` always allowed) | <https://kiro.dev/docs/permissions/> |
| Checkpoints, Revert, Restore | <https://kiro.dev/docs/checkpoints/> |
| Opening the workspace from a terminal with `kiro .` | <https://kiro.dev/docs/getting-started/first-project/> |
| Custom agent `migration-reviewer` (optional) | <https://kiro.dev/docs/custom-agents/> |

</details>

## Next

[Module 3: Spring Boot 3.5 and Jakarta EE](03-spring-boot-3.md): `javax.*` → `jakarta.*` with the
`jakarta-import-guard` hook on, a `SecurityFilterChain` bean, and JUnit Jupiter, after which the
Vintage engine (and a Byte Buddy override, if you added one) goes away.
