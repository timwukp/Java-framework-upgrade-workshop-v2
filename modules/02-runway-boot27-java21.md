<!-- runbook max-lines=450 -->
# Module 2: Runway, Spring Boot 2.7 and Java 21 (90 minutes)

Module 2 of 5 · [← Module 1](01-setup-and-assessment.md) · [Module 3 →](03-spring-boot-3.md) ·
[Day sheet](../docs/quick-reference.md) · [Troubleshooting](../docs/troubleshooting.md) ·
[Why and background](why/02-runway-boot27-java21.md)

Two steps: Spring Boot 2.2.4 → 2.7.18 on JDK 8, then JDK 8 → 21. A Feature spec plans the work, the
agent runs the tasks, a hook builds after each one, and you check what a green build can't prove:
that all the tests still ran.

## At a glance

| | |
|---|---|
| **Goal** | Stage 1: Spring Boot 2.7.18 on Java 21, still `javax.*`, with the same 14 tests |
| **Time** | 90 minutes: 80 core, 10 for Extra 2.A |
| **Start** | Module 1 done: tag `stage-0` (`Tests run: 14`) on branch `workshop`, steering and `MIGRATION-NOTES.md` committed; JDK 8 is the default and Kiro was started from a JDK 8 terminal with `kiro .`; workspace trusted; Supervised mode; `mvn *` on **Always allow** |
| **Hooks** | `verify-after-spec-task` **on**, `jakarta-import-guard` **off**, for the whole module |
| **JDK change** | 8 → 21 in Exercise 2.10, with a Kiro restart |
| **End** | Tag `stage-1`: `Stage 1: Java 21, Spring Boot 2.7.18, Tests run: 14` |
| **You produce** | The spec `stage-1-runway`, one commit per phase step, the tag `stage-1` |
| **Running late** | Skip Extra 2.A and the smoke test in Exercise 2.13. More than 15 minutes behind at the start of Exercise 2.10: see below. |

**More than 15 minutes behind at Exercise 2.10:** run `../scripts/reset-to-stage.sh 1` and type the
steps it prints (JDK 21 as default, restart Kiro, verify, commit, tag). Then do only step 2 of
[Finish](#finish-tag-stage-1) (`tech.md`) and commit.

## Before you start

From `sample-app/` in Kiro's terminal (``Ctrl+` ``); the build takes about a minute:

```bash
../scripts/verify-stage.sh 0
git tag -n1 -l "stage-*" && git status --short
```

**Expect:** `PASS: stage 0, …, Tests run: 14, …`, the `stage-0` tag with `Tests run: 14`, a clean tree.\
**If not:** count isn't 14 → [T-A14](../docs/troubleshooting.md#t-a14-the-baseline-test-count-isnt-14) ·
no `stage-0` → [T-X03](../docs/troubleshooting.md#t-x03-git-grep--stage-0-or-another-tag-says-bad-revision) ·
wrong JDK → [T-A01](../docs/troubleshooting.md#t-a01-mvn--v-shows-the-wrong-java-in-your-terminal)

## Exercises

| # | Exercise | Min |
|---|---|---|
| 2.1 | [Get ready](#21-get-ready) | 2 |
| 2.2 | [Create the spec](#22-create-the-spec) | 6 |
| 2.3 | [Review the requirements](#23-review-the-requirements) | 7 |
| 2.4 | [Review the design](#24-review-the-design) | 5 |
| 2.5 | [Review the tasks and commit the spec](#25-review-the-tasks-and-commit-the-spec) | 5 |
| 2.6 | [Bump the parent: green, but nothing ran](#26-bump-the-parent-green-but-nothing-ran) | 12 |
| 2.7 | [`@Valid` is silently ignored](#27-valid-is-silently-ignored) | 9 |
| 2.8 | [Remove the redundant `javax.*` pins](#28-remove-the-redundant-javax-pins) | 5 |
| 2.9 | [Phase A gate](#29-phase-a-gate) | 4 |
| 2.10 | [Switch the JDK](#210-switch-the-jdk) | 4 |
| 2.11 | [See the Lombok failure, and diagnose it with `#terminal`](#211-see-the-lombok-failure-and-diagnose-it-with-terminal) | 5 |
| 2.12 | [Run the phase B task](#212-run-the-phase-b-task) | 5 |
| 2.13 | [Check Byte Buddy, and a smoke test](#213-check-byte-buddy-and-a-smoke-test) | 6 |
| | [Finish: tag `stage-1`](#finish-tag-stage-1) | 5 |
| | [Extra 2.A: light Java modernization](#extra-2a-light-java-modernization) (optional) | 10 |

## Plan: the Feature spec

### 2.1 Get ready
**Goal:** a clean tree, Supervised mode, and the hooks set.

**Do**
1. Settings → "Agent Autonomy" (`kiroAgent.agentAutonomy`) → **Supervised**. Spec sessions then show
   each turn's edits as hunks to **Accept** or **Reject**.
2. Agent Hooks panel: `verify-after-spec-task` on, `jakarta-import-guard` off.

**Expect:** both hold, and `git status --short` prints nothing. **Commit:** nothing to commit.

### 2.2 Create the spec
**Goal:** a spec with the constraints written in from the start.

**Do**
1. Click **+** under **Specs** in the Kiro panel (or **Spec** on a new chat's **Let's build** screen),
   then **Feature**.
2. Paste the prompt below (use your own number if it isn't 14).
3. Choose **Requirements-First** when asked; it can't be changed later.
4. Wait for `requirements.md`. Don't confirm it yet.

**Prompt**

```prompt
Create a Feature spec named stage-1-runway for stage 1 in migration-standards: upgrade this service
from Spring Boot 2.2.4 on Java 8 to Spring Boot 2.7.18 on Java 21, still on javax.*.

Constraints:
- Phase A: Spring Boot 2.7.18 while the build stays on JDK 8 (java.version 1.8). Phase B, only after
  phase A is green: JDK 21. I switch the JDK myself; the phase B task first runs `mvn -v` and stops
  unless it reports Java 21.
- Do not run Maven yourself after a task; the verify hook runs `mvn -B clean verify` and reports the
  Tests run line. Quote that line in your summary. The stage-0 baseline is Tests run: 14. A task is
  done only if the build passes AND Tests run is at least 14; a green build with fewer tests is a
  failed task. No separate baseline or gate tasks.
- The first phase A task changes only the spring-boot-starter-parent version and its comment. Fix
  each problem it reveals in a later task: one problem per task, naming the Spring Boot release note
  that explains it.
- Behaviour must not change: invalid input to POST /api/users gets 400 from Bean Validation (@Valid)
  and never reaches UserService; unauthenticated requests get 401; unknown user ids get 404; every
  response has an X-Request-Id header.
- Prefer versions the Spring Boot parent manages. Remove explicit javax.* API dependencies that a
  starter already provides. Add no version override (for example byte-buddy.version) unless a build
  fails without it. Any remaining pin needs an XML comment explaining why.
- Never delete, disable or weaken a test; keep JUnit 4 (JUnit 5 is stage 2).
- Do not start the application or run git commands; I do both.
- Out of scope: jakarta.*, Spring Security changes, JUnit 5, Java language modernization.

Write the requirements in EARS notation.
```

**Expect:** `ls .kiro/specs/` shows a folder (ideally `stage-1-runway`) with `requirements.md`. If Kiro
chose another name, use it wherever this module says `stage-1-runway`.\
**Commit:** at the end of Exercise 2.5. **Why:** [Requirements-First](why/02-runway-boot27-java21.md#22-create-the-spec)

### 2.3 Review the requirements
**Goal:** testable requirements covering both silent traps. Each criterion follows EARS
(`WHEN [condition/event] THE SYSTEM SHALL [expected behavior]`) and is checkable by a command or a test.

**Do**
1. Check `requirements.md` ([an example of good requirements](why/02-runway-boot27-java21.md#23-review-the-requirements)):
   - [ ] Two phases, JDK 8 first, and a JDK check at the start of phase B.
   - [ ] A test count with your number that calls a green build with fewer tests a **failure**.
   - [ ] Bean Validation: the 400 response and the `invalidUserIsRejectedByBeanValidation` test.
   - [ ] Unchanged behaviour: 401, 404 and `X-Request-Id`.
   - [ ] Nothing untestable ("SHALL be robust") or invented (CI, performance targets, other versions).
   - [ ] jakarta, Spring Security, JUnit 5 and modernization are out of scope.
2. Fix gaps in the spec chat or in the file, then confirm the requirements (the confirm option in the
   spec session). Kiro generates `design.md`. Only if the count criterion is missing or vague:

   **Attach first:** type `#spec` and choose `stage-1-runway`. **Prompt**

   ```prompt
   In the test-count requirement, add this acceptance criterion: IF the Tests run total is lower
   than
   14 THEN the task is failed, even when the build succeeds. Change nothing else.
   ```

3. Check:

   ```bash
   grep -nE "SHALL" .kiro/specs/stage-1-runway/requirements.md | head -n 30
   grep -nE "Tests run|400|@Valid|Bean Validation" .kiro/specs/stage-1-runway/requirements.md
   ```

**Expect:** EARS lines, your baseline number, and the 400 criterion. **Commit:** not yet.

### 2.4 Review the design
**Goal:** a safe order, named risks, and no uncheckable claims.

**Do**
1. In `design.md`, check:
   - [ ] **Order:** the parent bump first and alone, on JDK 8; then the fixes; then the JDK switch.
   - [ ] **Verification:** it counts tests against the baseline. A passing build alone isn't enough.
   - [ ] **Risks:** at least Bean Validation (Boot 2.3), the Vintage engine (Boot 2.4) and the Lombok
     pin on JDK 21. Bonus: circular references (2.6), the dropped `.RELEASE` (2.4), Byte Buddy (watch
     only, no planned override), H2 2.x.
   - [ ] **No invented pins:** pinning anything the parent manages needs a written reason (`pom-rules`).
2. Let the playbook (manual steering) check the design.
   **Attach first:** `#spec` → `stage-1-runway`, then `#migration-playbook`. **Prompt**

   ```prompt
   Compare design.md with the "Stage 1" section of the playbook. List every playbook item the design
   does not cover, and every claim in the design that neither the playbook nor an official Spring
   Boot
   release note supports. Answer only; do not change any files.
   ```

3. Compare the answer with the playbook: `sed -n '/## Stage 1/,/## Stage 2/p' .kiro/steering/migration-playbook.md`.
   Ask Kiro to add missing items as risks, **Reject** hunks outside `design.md`, then confirm the design.

**Expect:** the design names the three risks and the safe order. **Commit:** not yet.

### 2.5 Review the tasks and commit the spec
**Goal:** small, ordered tasks, so you see each trap appear ([example](why/02-runway-boot27-java21.md#25-review-the-tasks-and-commit-the-spec)).

**Do**
1. Check `tasks.md`:
   - [ ] Task 1 changes **only** the parent version (and its comment).
   - [ ] One task per fix, **test engine first** (Exercise 2.6 shows why), pin removal after Bean Validation.
   - [ ] The phase B task opens with the `mvn -v` check.
   - [ ] No baseline, gate or Byte Buddy override task; no task builds, edits `src/test/`, starts the
     app or runs `git`.
   - [ ] A strict chain, all required: **Run all Tasks** runs independent tasks concurrently and skips
     optional ones ([T-K20](../docs/troubleshooting.md#t-k20-tasks-ran-in-parallel-or-ahead-of-time)).
2. Only if the order or dependencies are wrong: **Attach first:** `#spec` → `stage-1-runway`. **Prompt**

   ```prompt
   Reorder tasks.md so that every task depends on the previous one: parent bump only, test-engine
   fix,
   Bean Validation fix, javax.* pin removal, then the phase B task. Remove any baseline, gate or
   Byte
   Buddy override task. Keep one problem per task. Do not change requirements.md or design.md.
   ```

3. If you edited `requirements.md` or `design.md`, choose **Sync Files** in `tasks.md`.

**Expect:** `git status --short` shows only the three files under `.kiro/specs/stage-1-runway/`.\
**Commit:** `git add .kiro/specs && git commit -m "Module 2: stage-1-runway spec (requirements, design, tasks)"`

## Phase A: Spring Boot 2.7.18 on JDK 8

Run the phase A tasks **one at a time** (click each task item in `tasks.md`), not with **Run all
Tasks**, so you see each trap. After each task the hook runs `mvn -B clean verify` once and the agent
quotes the `Tests run` line. The hook passes **whenever the build passes, even when fewer tests ran**:
comparing the count with 14 is your job. Read the line the agent quotes and the hook's run in the
**Kiro output panel**. To build yourself (no credits), wait until the hook has finished: **never run two Maven
builds at once** (they share `target/`). [How the hook works](why/02-runway-boot27-java21.md#how-the-verify-hook-works)

### 2.6 Bump the parent: green, but nothing ran
**Goal:** one task → hook cycle, and Boot 2.4's silent trap.

**Do**
1. In `tasks.md`, click task 1 (parent bump).
2. **Accept** the hunk only if it sets the parent to `2.7.18` (no `.RELEASE`: dropped in Boot 2.4) and
   changes at most the comment next to it.
3. When the task is Done, read the result the agent quotes and the hook's run in the output panel.

**Expect:** `BUILD SUCCESS` with `Tests run: 0, Failures: 0, Errors: 0, Skipped: 0`, against 14 in
`git tag -n1 -l stage-0`. The hook passed; by requirement 2 the task failed.\
**If not:** the agent called it a success → [the follow-up prompt](why/02-runway-boot27-java21.md#26-bump-the-parent-green-but-nothing-ran) ·
no hook run → [T-K15](../docs/troubleshooting.md#t-k15-the-verify-hook-never-runs)

4. Run task 2 (test engine). **Accept** it if it adds `junit-vintage-engine` in test scope, without a
   version and excluding `hamcrest-core` ([expected hunk](why/02-runway-boot27-java21.md#26-bump-the-parent-green-but-nothing-ran)),
   and no test file changed. **Reject** rewrites to JUnit 5 (Module 3).
5. The hook **fails** now. That's expected; Exercise 2.7 fixes it. After the hook has finished,
   check: `mvn -B clean verify | grep -E "Tests run:.* in com\.example"`.

**Expect:** two per-class lines again (5 and 9 tests) and one failure in `UserControllerTest`. A green
build isn't a passing test suite. **Commit:** at the end of Exercise 2.7.\
**Why:** [Boot 2.4 removed the Vintage engine](why/02-runway-boot27-java21.md#26-bump-the-parent-green-but-nothing-ran)

### 2.7 `@Valid` is silently ignored
**Goal:** Boot 2.3's silent trap, hidden until now by the first one.

**Expected output** (the hook's stderr reaches the agent; line numbers may differ):

```output
[ERROR] Failures:
[ERROR]   UserControllerTest.invalidUserIsRejectedByBeanValidation:... Status expected:<400> but was:<201>
[ERROR] Tests run: 14, Failures: 1, Errors: 0, Skipped: 0
```

**Do**
1. Run task 3 (Bean Validation). The fix is `spring-boot-starter-validation`, without a version
   ([expected hunk](why/02-runway-boot27-java21.md#27-valid-is-silently-ignored)).
2. **Accept** only that change. **Reject** hunks in `UserControllerTest`, `UserController` or `User`:
   the test is right, the classpath is wrong.
3. If the agent already fixed it inside task 2, accept only the starter hunk and choose **Sync Files**
   in `tasks.md` (it marks implemented tasks completed).
4. Check: `mvn -B dependency:tree -Dincludes=org.hibernate.validator | grep hibernate-validator`

**Expect:** the latest hook result shows `Tests run: 14, Failures: 0` and `BUILD SUCCESS` (if no hook ran
after the fix, run the count check yourself), and `hibernate-validator` under
`spring-boot-starter-validation`.\
**If not:** the agent proposes another fix → [the follow-up prompt](why/02-runway-boot27-java21.md#27-valid-is-silently-ignored)\
**Why:** [Boot 2.3 moved Bean Validation out](why/02-runway-boot27-java21.md#27-valid-is-silently-ignored)\
**Commit:** `git add -A && git commit -m "Stage 1 phase A: Boot 2.7.18 parent, Vintage engine, validation starter"`

### 2.8 Remove the redundant `javax.*` pins
**Goal:** one source per API. The starters already bring the pinned `javax.servlet-api`,
`javax.persistence-api` 2.2 and `validation-api` 2.0.1.Final (still `javax.*`), so Module 3 can then
move to `jakarta.*` through the starters alone.

**Do**
1. Run task 4.
2. **Accept** the removal of the three `javax` blocks. **Reject** changes to Java files: the imports
   stay `javax.*` in stage 1.
3. Check:

   ```bash
   grep -n "<groupId>javax" pom.xml
   mvn -B dependency:tree | grep -E "persistence-api|validation-api|tomcat-embed-core"
   ```

**Expect:** the hook reports `Tests run: 14` and `BUILD SUCCESS`; no output from the first `grep`; the
APIs arrive through the JPA and validation starters and `tomcat-embed-core`.\
**If not:** [T-B08](../docs/troubleshooting.md#t-b08-package-javaxvalidationconstraints-does-not-exist) ·
[T-B09](../docs/troubleshooting.md#t-b09-beancurrentlyincreationexception-at-startup-or-in-a-test)\
**Commit:** `git add -A && git commit -m "Stage 1 phase A: remove javax.* API pins provided by the starters"`

### 2.9 Phase A gate
**Goal:** prove phase A on JDK 8 yourself. There is no gate task.

**Do:** with no hook run in progress: `../scripts/verify-stage.sh 1 --jdk 8`

**Expect:** `PASS: stage 1, Java 8, Spring Boot 2.7.18, Tests run: 14, …`. A deprecation note about
`WebSecurityConfigurerAdapter` (Spring Security 5.7) is fine; Module 3 replaces it.\
**Commit:** nothing to commit; `git status --short` prints nothing.

## Phase B: JDK 8 → 21

### 2.10 Switch the JDK
**Goal:** your terminal, the agent and the hook all on JDK 21.

**Do**
1. `git status --short` prints nothing: phase A is committed.
2. Make JDK 21 the **default** for new terminals
   ([Change the JDK for Kiro](../docs/participant-setup.md#change-the-jdk-for-kiro-modules-2-and-4-and-after-a-reset)).
3. In a new terminal outside Kiro, go to `sample-app/` and check that `mvn -v` reports 21.
4. **Quit Kiro** (the application, not just the window) and start it from that terminal: `kiro .`
5. In Kiro, start a new chat session (Default agent). **Prompt**

   ```prompt
   Run `mvn -v` in the workspace root and tell me the Java version it reports. Do not run anything
   else.
   ```

**Now:** JDK 21 · hooks unchanged.\
**Expect:** `java -version` and `mvn -v` in Kiro's terminal, and the agent's answer, all report 21.\
**If not:** [T-A02](../docs/troubleshooting.md#t-a02-the-agents-or-the-hooks-java-is-not-your-terminals)\
**Commit:** nothing to commit.

### 2.11 See the Lombok failure, and diagnose it with `#terminal`
**Goal:** see why the Lombok pin (still 1.18.10, with `java.version` 1.8) blocks JDK 21, and hand build
output to the agent.

**Do**
1. On JDK 21: `mvn -B -q clean compile` (keep `clean`, or Maven may skip recompiling and hide it).
2. Start a new chat session (Default agent). **Attach first:** `#terminal` (recent terminal output).
   **Prompt**

   ```prompt
   The compile just failed on JDK 21. From that output, explain the root cause, name the dependency
   and version that causes it, and say whether Spring Boot 2.7.18 manages a version that supports
   JDK 21. Check the managed version with a Maven command instead of guessing. Answer only; do not
   change any files.
   ```

3. **Reject** any hunks: the fix belongs to the spec task.

**Expect:** the compile fails with `java.lang.IllegalAccessError: class lombok.javac.apt.LombokProcessor
… cannot access class com.sun.tools.javac.processing.JavacProcessingEnvironment`. The answer names
Lombok 1.18.10 and says Boot 2.7.18 manages **Lombok 1.18.30**, the first release with JDK 21 support.
If it quotes another version without running Maven, ask for the command.\
**Why:** [sources, and `#terminal` vs `#problems`](why/02-runway-boot27-java21.md#211-see-the-lombok-failure-and-diagnose-it-with-terminal)\
**Commit:** nothing changed (`git status --short`).

### 2.12 Run the phase B task
**Goal:** `java.version` 21, Lombok managed by the parent, green on JDK 21.

**Do**
1. Click task 5. It first runs `mvn -v`; if that doesn't report 21, it stops (back to Exercise 2.10).
2. **Accept** the hunks only if they set `<java.version>21</java.version>`, remove the Lombok
   `<version>1.18.10</version>` line (keep `provided`), and change nothing else. The parent maps
   `java.version` to the compiler (`pom-rules`).
3. After the hook has finished: `../scripts/verify-stage.sh 1` and
   `mvn -B dependency:tree -Dincludes=org.projectlombok | grep lombok`

**Expect:** the hook reports `Tests run: 14` and `BUILD SUCCESS`; the script prints `PASS: stage 1,
Java 21, Spring Boot 2.7.18, …, class files major 65`; `lombok:jar:1.18.30:provided`.\
**If not:** [T-B06](../docs/troubleshooting.md#t-b06-lombok-illegalaccesserror-lombokprocessor-cannot-access-javacprocessingenvironment) ·
an error names Byte Buddy → [T-B10](../docs/troubleshooting.md#t-b10-a-mockito-or-hibernate-error-that-names-byte-buddy)\
**Commit:** `git add -A && git commit -m "Stage 1 phase B: Java 21, Lombok managed by Spring Boot 2.7.18"`

### 2.13 Check Byte Buddy, and a smoke test
**Goal:** the Byte Buddy version the parent manages works on JDK 21, and the app starts.

**Do**
1. `mvn -B dependency:tree -Dincludes=net.bytebuddy | grep bytebuddy` (expect `1.12.23`). Change
   nothing unless an error names Byte Buddy ([T-B10](../docs/troubleshooting.md#t-b10-a-mockito-or-hibernate-error-that-names-byte-buddy)).
2. Choose a local admin password for this run, then start the app. Hibernate and H2 2.x start only
   here (the tests don't load them):

   ```bash
   printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD
   mvn spring-boot:run
   ```

3. Optional (skip if late): in a second terminal in `sample-app/`, set the same password with the
   `printf … read` line, then run `../scripts/smoke.sh`.
4. Stop the app with **Ctrl+C**.

**Expect:** `byte-buddy` (and `byte-buddy-agent`) at `1.12.23`; `Started UserManagementApplication` with
no Byte Buddy error; every smoke check `PASS` (at stage 1 the trailing slash still returns 200).\
**If not:** [T-R01](../docs/troubleshooting.md#t-r01-port-8080-is-already-in-use) ·
[T-R02](../docs/troubleshooting.md#t-r02-smokesh-says-app_admin_password-is-not-set-or-the-app-is-not-reachable)\
**Why:** [Byte Buddy 1.12.23 on Java 21](why/02-runway-boot27-java21.md#213-check-byte-buddy-and-a-smoke-test)\
**Commit:** nothing to commit; `git status --short` prints nothing.

## Finish: tag `stage-1`

**Goal:** a known-good stage 1 that Module 3 starts from.

1. With no other build running: `../scripts/verify-stage.sh 1` → `PASS: stage 1, Java 21, …`.
2. In `.kiro/steering/tech.md`, set the "current state" line to stage 1: Java 21, Spring Boot 2.7.18
   (Spring Framework 5.3.x), still `javax.*`, JUnit 4 on the Vintage engine.
3. `../scripts/compare-stage.sh 1`. Comments, description, order and formatting may differ. These must
   match: parent `2.7.18`, `java.version` 21, no `byte-buddy.version`, `spring-boot-starter-validation`,
   `junit-vintage-engine` (test, `hamcrest-core` excluded), Lombok without a version, no `javax`
   dependencies. Without Extra 2.A, `User`, `UserService` and `UserController` differ, as expected.
4. If step 1 passed with `Tests run: 14` (as in your `stage-0` tag), commit and tag:

   ```bash
   git add -A
   git commit -m "Stage 1 complete: Spring Boot 2.7.18 on Java 21"
   git tag -a stage-1 -m "Stage 1: Java 21, Spring Boot 2.7.18, Tests run: 14"
   ```

5. Check: `git status --short` (nothing), `git tag -n1 -l "stage-*"` (`stage-0` and `stage-1` with the
   **same** `Tests run`), and `git log --oneline stage-0..stage-1` (the spec, phase A and phase B commits).

## Extras (optional, outside the core time)

### Extra 2.A: light Java modernization
**Goal:** the small, behaviour-preserving changes that Java 21 and Spring 5.3 make easy, matching the
reference solution. Plain chat, not a spec task: the hook doesn't run, you build.

**Do**
1. `git status --short` prints nothing, then start a new chat session (Default agent) and send the
   prompt from the [why page](why/02-runway-boot27-java21.md#extra-2a-light-java-modernization).

2. Review every hunk in Supervised mode. **Reject** any hunk in another file, and records or other
   "improvements" you didn't ask for.
3. Check: `grep -rnE "@Autowired|java\.util\.Date|RequestMethod" src/main/java`, then
   `../scripts/verify-stage.sh 1` and `../scripts/compare-stage.sh 1`.

**Expect:** no output from `grep`; `PASS`; small or no differences from the reference in `src/main`
(annotations, types and return types match). The dates stay ISO-8601 but change shape
([details](why/02-runway-boot27-java21.md#extra-2a-light-java-modernization)).\
**Commit:** `git add -A && git commit -m "Stage 1: java.time, constructor injection, @GetMapping and friends"`

### Extra 2.B: ask the reviewer
Switch to the `migration-reviewer` agent and ask it to review `git diff stage-0..stage-1`. It usually
runs `mvn -B verify` and replies with a findings table. Don't build yourself while it runs, and run
`git status` afterwards. Module 5 covers the reviewer in depth.

## Check yourself

- [ ] Spec `stage-1-runway` committed, with EARS criteria for "Tests run ≥ 14" and "invalid input →
  400"; design and task order reviewed before any task ran.
- [ ] You can explain why the hook passes even when fewer tests ran.
- [ ] `Tests run: 0` after the bare bump, fixed with `junit-vintage-engine`; the 201 failure fixed with
  `spring-boot-starter-validation`, not by changing the test.
- [ ] No `javax` dependencies and no Lombok version in `pom.xml`; Byte Buddy managed by the parent.
- [ ] JDK 21 is the default, Kiro restarted with `kiro .`, `#terminal` used, and the app starts.
- [ ] Tag `stage-1` records the same `Tests run` as `stage-0` (14).

**Something else?** [Build and tests](../docs/troubleshooting.md#b-build-and-tests) · [Kiro](../docs/troubleshooting.md#k-kiro) · [Recovery](../docs/troubleshooting.md#x-recovery)

## Next

[Module 3: Spring Boot 3.5 and Jakarta EE →](03-spring-boot-3.md): `javax.*` → `jakarta.*` with the
`jakarta-import-guard` hook on, a `SecurityFilterChain` bean, and JUnit Jupiter, after which the
Vintage engine goes away.
