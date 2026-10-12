<!-- runbook max-lines=600 -->
# Module 3: Spring Boot 3.5 and Jakarta EE (105 minutes)

Module 3 of 5 · [← Module 2](02-runway-boot27-java21.md) · [Module 4 →](04-spring-boot-4-java25.md) ·
[Day sheet](../docs/quick-reference.md) · [Troubleshooting](../docs/troubleshooting.md) ·
[Why and background](why/03-spring-boot-3.md)

Stage 1 (Spring Boot 2.7.18, Java 21, `javax.*`) to stage 2 (Spring Boot 3.5.16, Java 21, Jakarta EE
10). 3.5.16 is a waypoint that keeps the jump to 4.1 small. Kiro edits, skills guide it, a hook checks
its Java saves, and the test count tells you whether it worked.

## At a glance

| | |
|---|---|
| **Goal** | Stage 2: Spring Boot 3.5.16 on Java 21, `jakarta.*`, a `SecurityFilterChain`, JUnit Jupiter only, 14 tests |
| **Time** | 105 minutes |
| **Start** | Tag `stage-1` (`Tests run: 14`), JDK 21, trusted workspace, `mvn *` allowed, Supervised mode, `MIGRATION-NOTES.md` present. Behind? `../scripts/reset-to-stage.sh 1` |
| **Hooks** | Start: `verify-after-spec-task` **on**, `jakarta-import-guard` **off**. The table below shows when they change. |
| **End** | Tag `stage-2`: `Stage 2: Java 21, Spring Boot 3.5.16, Tests run: 14`; both hooks **on** |
| **You produce** | A Quick Spec, the Jakarta and security migration, your own `junit4-to-jupiter` skill |
| **Running late** | Skip the Extras; in Exercise 3.14 copy the reference skill (the fast path); skip the optional reference diff in Finish |

**The build is red on purpose for a while.** Boot 3 has no `javax.*` APIs and no
`WebSecurityConfigurerAdapter`; the paused hook doesn't feed those expected errors to the agent.

| After | `mvn -B -q clean compile` | Tests run | `verify-after-spec-task` | `jakarta-import-guard` |
|---|---|---|---|---|
| Start | passes | 14 | on | off |
| Exercise 3.3 | passes | 14 | on | **on** |
| Exercise 3.6 | **fails** in 4 files | — | **paused** (Exercise 3.4) | on |
| Exercise 3.8 | **fails** in `SecurityConfig.java` only | — | paused | on |
| Exercise 3.13 | passes | 14 (JUnit 4 on Vintage) | **on again** | on |
| Exercise 3.16 on | passes | 14 (JUnit Jupiter only) | on | on |

**Build rules.** Always `clean` (after a version bump Maven may skip recompiling and hide errors). One
build at a time: start yours only when the agent is idle and no hook run shows in the Kiro output
panel. The prompts tell the agent not to build.

## Before you start

`../scripts/verify-stage.sh 1` → **Expect:** `PASS: stage 1, Java 21, Spring Boot 2.7.18, Tests run:
14, …`. **If not:** wrong JDK → [T-A02](../docs/troubleshooting.md#t-a02-the-agents-or-the-hooks-java-is-not-your-terminals)
(make JDK 21 the default, quit Kiro, `kiro .`) · otherwise reset with `../scripts/reset-to-stage.sh 1`.

## Exercises

| # | Exercise | Min |
|---|---|---|
| 3.1 | [Confirm the starting point](#31-confirm-the-starting-point) | 3 |
| 3.2 | [Read the guard, and try its command](#32-read-the-guard-and-try-its-command) | 4 |
| 3.3 | [Enable the guard](#33-enable-the-guard) | 3 |
| 3.4 | [Pause the verify hook](#34-pause-the-verify-hook) | 1 |
| 3.5 | [Plan the stage with Quick Spec](#35-plan-the-stage-with-quick-spec) | 7 |
| 3.6 | [Task 1: the 3.5.16 parent and the properties migrator](#36-task-1-the-3516-parent-and-the-properties-migrator) | 5 |
| 3.7 | [Watch the guard catch a leftover](#37-watch-the-guard-catch-a-leftover) | 6 |
| 3.8 | [Task 2: migrate the namespace with the skill](#38-task-2-migrate-the-namespace-with-the-skill) | 13 |
| 3.9 | [Back to Supervised](#39-back-to-supervised) | 3 |
| 3.10 | [Task 3: migrate `SecurityConfig`, one hunk at a time](#310-task-3-migrate-securityconfig-one-hunk-at-a-time) | 10 |
| 3.11 | [The `@WebMvcTest` trap](#311-the-webmvctest-trap) | 8 |
| 3.12 | [Run the app: migrator report and smoke test](#312-run-the-app-migrator-report-and-smoke-test) | 7 |
| 3.13 | [Task 4: rename the key, and turn the verify hook back on](#313-task-4-rename-the-key-and-turn-the-verify-hook-back-on) | 3 |
| 3.14 | [Write your own skill: JUnit 4 to Jupiter](#314-write-your-own-skill-junit-4-to-jupiter) | 8 |
| 3.15 | [Have Kiro review your skill](#315-have-kiro-review-your-skill) | 3 |
| 3.16 | [Task 5: migrate both test classes with your skill](#316-task-5-migrate-both-test-classes-with-your-skill) | 8 |
| 3.17 | [Improve the skill](#317-improve-the-skill) | 3 |
| 3.18 | [Task 6: final cleanup](#318-task-6-final-cleanup) | 5 |
| | [Finish: record deprecations, tag `stage-2`](#finish-record-deprecations-tag-stage-2) | 5 |

## The import guard

### 3.1 Confirm the starting point
**Do:** `git status --short` and `git tag -l "stage-*"`.\
**Expect:** a clean tree, tags `stage-0` and `stage-1` (and the `PASS` from Before you start).

### 3.2 Read the guard, and try its command
**Goal:** know what the guard checks and how findings reach the agent. When the **agent** saves a
`.java` file, the `grep` prints Jakarta EE imports still on `javax.*` to stderr and exits 1, so the
agent gets them. It reports, never blocks; JDK packages such as `javax.sql` pass. It ships off: stages
0–1 use `javax.*`.

**Do**
1. Read the hook: `cat .kiro/hooks/jakarta-import-guard.json`
2. Try the command on `User.java`, and once on JDK-only imports:

   ```bash
   grep -nE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])' src/main/java/com/example/usermanagement/entity/User.java
   printf 'import javax.sql.DataSource;\nimport javax.crypto.Cipher;\nimport javax.transaction.xa.XAResource;\n' | grep -cE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])'
   ```

**Expect:** the first command lists 11 `javax.persistence` and `javax.validation` import lines; the
second prints `0`.\
**Why:** [the guard field by field, and why JDK packages are excluded](why/03-spring-boot-3.md#32-read-the-guard-and-try-its-command)

### 3.3 Enable the guard
**Goal:** from now on, every Java file the agent saves is checked.

**Do** (yourself: agent writes to `.kiro/hooks/` always ask): click the **eye icon** next to
`jakarta-import-guard` in **Agent Hooks**, or set `"enabled": true` in its JSON file.

**Expect:** the panel shows it enabled; `git diff .kiro/hooks/` shows `"enabled": true` if your build
writes the toggle to the file (the panel state counts either way).\
**Commit** (skip if `git status` is clean): `git add .kiro/hooks/jakarta-import-guard.json && git commit -m "Module 3: enable jakarta-import-guard"`

## Quick Spec and the parent bump

### 3.4 Pause the verify hook
**Goal:** stop `verify-after-spec-task` from reporting failures you expect: until Exercise 3.13 the code
can't compile, and the hook would hand those errors to the agent as work, out of order and skill-less.

**Do:** **Agent Hooks** → eye icon next to `verify-after-spec-task` (off). You turn it on again in
Exercise 3.13.\
**Now:** verify hook **paused** · guard **on**.

### 3.5 Plan the stage with Quick Spec
**Goal:** a reviewed `requirements.md`, `design.md` and `tasks.md`. Quick Spec writes all three in one
pass, without approval gates: fine here, because the playbook defines the stage and you review before
any task runs ([when to prefer a Feature spec](why/03-spring-boot-3.md#35-plan-the-stage-with-quick-spec)).

**Do**
1. With a clean `git status`, start a new session (**+** in the chat panel) and choose **Quick Spec** on
   **Let's build**, or type `/quick-spec`.
2. **Attach first:** `#migration-playbook`. Send the prompt. Answer clarifying questions in one line
   (for example `1=a, 2=b`).
3. Review the files; fix missing, merged or misordered tasks in `tasks.md`, then **Sync Files**.
4. Check: `ls .kiro/specs/spring-boot-3-upgrade/` and `git status --short`

**Prompt**

```prompt
Create a spec named spring-boot-3-upgrade for stage 2: Spring Boot 2.7.18 to 3.5.16 on Java 21
(Jakarta EE 10), following the playbook's stage 2 items and migration-standards. Write the
requirements in EARS form and include: mvn -B clean verify passes on JDK 21; Tests run stays 14; no
Jakarta EE API is imported from javax.*; security behaviour is unchanged (401 for unauthenticated
requests to /api/users, CSRF ignored only for /api/**, BCrypt passwords, no hard-coded passwords).
Create exactly these tasks, one concern each, in this order:
1. pom.xml only: set the spring-boot-starter-parent version to 3.5.16; if there is a
   byte-buddy.version override, remove it and its comment (3.5.16 manages Byte Buddy itself); add
   org.springframework.boot:spring-boot-properties-migrator with runtime scope and a comment saying
   it is temporary; update the parent comment and the description element for stage 2, and drop
   pom.xml comments that only explain stage-1 changes. The code is expected not to compile after
   this task (javax.* imports, WebSecurityConfigurerAdapter). Do not change any Java file in this
   task.
2. javax.* to jakarta.* using the jakarta-namespace-migration skill, without touching
   SecurityConfig.java.
3. SecurityConfig to a SecurityFilterChain bean with the lambda DSL using the
   spring-security-lambda-dsl skill; the web-layer tests keep their assertions.
4. Rename the configuration keys that spring-boot-properties-migrator reports at startup.
5. JUnit 4 to JUnit Jupiter for both test classes, then remove junit-vintage-engine and junit:junit.
6. Remove explicit hibernate.dialect properties, return ProblemDetail from ApiExceptionHandler,
   record remaining deprecation warnings in MIGRATION-NOTES.md, and remove
   spring-boot-properties-migrator.
Do not run Maven yourself after a task; the verify hook runs mvn -B clean verify and reports the
Tests run line. Quote that line in your summary. Do not invent version numbers.
```

**Expect:** three new files (other folder name? use it wherever this module says
`spring-boot-3-upgrade`); six tasks in your order; task 1 `pom.xml` only, red build expected; the
migrator temporary, removed last; EARS requirements with the count and the four security behaviours;
no versions except 3.5.16 and Java 21.\
**If not:** [T-K23](../docs/troubleshooting.md#t-k23-quick-spec-produced-different-or-merged-tasks)\
**Commit:** `git add .kiro/specs && git commit -m "Module 3: stage 2 spec (Quick Spec)"`

### 3.6 Task 1: the 3.5.16 parent and the properties migrator
**Goal:** a reviewed single-file parent bump, and a to-do list made by the compiler.

**Do**
1. In `tasks.md`, click the first task item (the paused hook runs no build afterwards).
2. **Accept** `pom.xml` hunks that match task 1 ([expected shape](why/03-spring-boot-3.md#36-task-1-the-3516-parent-and-the-properties-migrator));
   **Reject** any `.java` hunk.
3. Check:

   ```bash
   grep -nE "<version>3\.5\.16|byte-buddy|properties-migrator" pom.xml
   mvn -B dependency:tree -Dincludes=org.springframework:spring-core,org.springframework.security:spring-security-core,org.hibernate.orm:hibernate-core,net.bytebuddy:byte-buddy
   mvn -B -q clean compile | grep -oE "[A-Za-z]+\.java" | sort -u
   ```

**Expect:**
- Parent `3.5.16`, the migrator, no `byte-buddy` line.
- `spring-core` 6.2.19, `spring-security-core` 6.5.11, `hibernate-core` 6.6.53.Final (new group
  `org.hibernate.orm`), `byte-buddy` 1.17.8. (No `-q` on `dependency:tree`: it prints at INFO.)
- Errors in `User.java`, `UserController.java`, `RequestIdFilter.java`, `SecurityConfig.java`: your
  to-do list for the next exercises. Without `clean`, Maven may list none.

**If not:** [T-B05](../docs/troubleshooting.md#t-b05-a-trap-doesnt-show-or-old-class-files-survive) ·
[T-B14](../docs/troubleshooting.md#t-b14-dependencytree-or-the-deprecation-listing-prints-nothing)\
**Commit:** `git add -A && git commit -m "Stage 2, task 1: Spring Boot 3.5.16 parent and properties migrator (does not compile yet)"`
(a red commit on `workshop` is fine; the `stage-2` tag must be green).

## Jakarta namespace with a shipped skill

A skill loads only its name and description up front; the rest loads when a request matches the
description, or when you type `/` and its name. **Autonomy: Autopilot** for Exercises 3.7–3.8:
renaming imports is mechanical, and the compiler, the guard and git check it.

### 3.7 Watch the guard catch a leftover
**Goal:** see a `PostFileSave` hook feed a finding back to the agent.

**Do**
1. Switch to **Autopilot** (chat switch, or Settings → Agent → Agent Autonomy), with a clean
   `git status`.
2. Send this deliberately incomplete edit. **Prompt**

   ```prompt
   In src/main/java/com/example/usermanagement/entity/User.java, change only the javax.persistence
   imports to jakarta.persistence. Leave every other line unchanged, including the javax.validation
   imports. Then stop and tell me, word for word, whether a hook reported anything after you saved
   the file.
   ```

3. Check: `git diff --stat` and `grep -n "^import javax" src/main/java/com/example/usermanagement/entity/User.java`

**Expect:** only `User.java` changed, its three `javax.validation.constraints` imports left. The agent
quotes the guard's lines ([example](why/03-spring-boot-3.md#37-watch-the-guard-catch-a-leftover));
either way, read the guard's result in the hook log (Kiro output panel). If the agent then fixes them,
the loop works.\
**If not:** [T-K29](../docs/troubleshooting.md#t-k29-jakarta-import-guard-never-reports-anything)\
**Commit:** `git add -A && git commit -m "Module 3: guard hook demo (User.java persistence imports)"`

### 3.8 Task 2: migrate the namespace with the skill
**Goal:** Jakarta EE imports on `jakarta.*`, JDK packages untouched, `SecurityConfig.java` left for task
3. The prompt fences off `SecurityConfig.java`: the security skill's description matches your errors,
so the agent could start task 3 early.

**Do**
1. Stay in Autopilot. **Attach first:** type `/jakarta-namespace-migration` and select it, then
   `#spec` → `spring-boot-3-upgrade`. Type or paste the prompt in the same message.
2. When the agent is idle, run the checks:

   ```bash
   git diff --stat
   grep -rnE '^import (static )?javax\.' src
   grep -rhoE '^import jakarta\.[a-z]+' src | sort | uniq -c
   grep -n "javax" pom.xml
   mvn -B -q clean compile | grep -oE "[A-Za-z]+\.java" | sort -u
   ```

**Prompt**

```prompt
Implement task 2. Follow the skill step by step: main and test sources, non-Java files, and pom.xml.
Do not edit src/main/java/com/example/usermanagement/config/SecurityConfig.java; its
WebSecurityConfigurerAdapter errors are task 3. Finish with the skill's final search (section 3,
step 4). Do not run Maven; I compile the project myself, and it cannot pass until task 3 is done.
```

**Expect:** `User.java`, `UserController.java`, `RequestIdFilter.java` changed, `SecurityConfig.java`
not; no `import javax.` line; `jakarta.persistence` 8, `jakarta.servlet` 4, `jakarta.validation` 4; no
`javax` in `pom.xml` (delete any leftover comment about removed pins); compile errors only in
`SecurityConfig.java`.\
**If not:** errors in another file → **Attach first:** `#terminal`, then send
`Fix the remaining javax errors outside SecurityConfig.java with the skill. Do not run Maven.` and
compile again · the agent changed `SecurityConfig.java` →
`git restore src/main/java/com/example/usermanagement/config/SecurityConfig.java` ·
[T-K32](../docs/troubleshooting.md#t-k32-text-typed-after-skill-name-seems-ignored)\
**Commit:** `git add -A && git commit -m "Stage 2, task 2: javax to jakarta (SecurityConfig still pending)"`

### 3.9 Back to Supervised
**Do:** switch back to **Supervised**. Your safety nets were the compiler, the guard, the skill's
steps, git and your prompt boundary ([what each can't catch](why/03-spring-boot-3.md#39-back-to-supervised)).\
**Expect:** the Autopilot switch is off.

## Spring Security 6 in Supervised mode

`SecurityConfig` still extends `WebSecurityConfigurerAdapter`, removed in Spring Security 6. You move
it to a `SecurityFilterChain` bean with the lambda DSL, which Spring Security 7 requires. A security
change can compile and still change who gets in, so you review each hunk.

### 3.10 Task 3: migrate `SecurityConfig`, one hunk at a time
**Goal:** the same security rules, as beans and lambdas, reviewed line by line.

**Do**
1. In **Supervised** mode with a clean tree: **Attach first:** `/spring-security-lambda-dsl`, then
   `#spec` → `spring-boot-3-upgrade`. Send the prompt.
2. Review every hunk against the table; use **Chat inline** to ask before you decide
   ([two judgement calls, and the reference shape](why/03-spring-boot-3.md#310-task-3-migrate-securityconfig-one-hunk-at-a-time)).
3. Check: `git diff --stat`, then `mvn -B -q clean compile` and

   ```bash
   grep -nE "WebSecurityConfigurerAdapter|antMatchers|authorizeRequests|\.and\(\)|inMemoryAuthentication" src/main/java/com/example/usermanagement/config/SecurityConfig.java
   grep -nE "SecurityFilterChain|ignoringRequestMatchers|requestMatchers|InMemoryUserDetailsManager|BCryptPasswordEncoder|passwordOrGenerated" src/main/java/com/example/usermanagement/config/SecurityConfig.java
   ```

**Prompt**

```prompt
Implement task 3 for src/main/java/com/example/usermanagement/config/SecurityConfig.java only.
Replace WebSecurityConfigurerAdapter with a SecurityFilterChain bean using the lambda DSL, and the
in-memory users with an InMemoryUserDetailsManager bean. Keep every rule in its original order, keep
BCrypt and the generated-password fallback, and do not add permitAll rules or disable CSRF. Do not
change any test, and do not run Maven; I compile it myself.
```

| Accept if | Reject, or ask with Chat inline, if |
|---|---|
| No `extends` any more; `@Configuration` and `@EnableWebSecurity` kept | A rule missing, reordered or loosened |
| `@Bean SecurityFilterChain securityFilterChain(HttpSecurity http)` returns `http.build()` | A new `permitAll()`, or `csrf` disabled instead of ignored for `/api/**` |
| `csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))` | `antMatchers`, `authorizeRequests` or `.and()` left |
| `authorizeHttpRequests`: `/api/public/**` permitAll, `/api/users/**` authenticated, then `anyRequest().authenticated()` | A password literal anywhere |
| `httpBasic(Customizer.withDefaults())` | `NoOpPasswordEncoder` or `{noop}` |
| A `UserDetailsService` bean: `new InMemoryUserDetailsManager(...)`, BCrypt passwords from `passwordOrGenerated(...)` | Tests or other classes edited |

**Expect:** only `SecurityConfig.java` changed, no output from the first `grep`, the new APIs in the
second, a silent compile (`-q` prints nothing on success).\
**If not:** [T-K25](../docs/troubleshooting.md#t-k25-the-agent-edits-securityconfigjava-when-it-shouldnt) ·
[T-B15](../docs/troubleshooting.md#t-b15-compile-errors-in-files-other-than-securityconfigjava-after-module-3s-rename)\
**Commit:** `git add -A && git commit -m "Stage 2, task 3: SecurityFilterChain and lambda DSL"`

### 3.11 The `@WebMvcTest` trap
**Goal:** the web tests exercise **your** security configuration, not a default one.

**Do**
1. Run the tests (JUnit 4 still runs on Vintage until Exercise 3.16):
   `mvn -B clean verify | grep -E "Tests run:|expected" | tail -n 6`
2. Two tests fail. Ask Kiro for the root cause first. **Attach first:** `#terminal`. **Prompt**

   ```prompt
   The web-layer tests changed behaviour after the SecurityConfig migration. Explain the root cause
   before changing anything: which security configuration does @WebMvcTest(UserController.class)
   load now, and which did it load while SecurityConfig extended WebSecurityConfigurerAdapter? Then
   propose the smallest change to UserControllerTest that makes it exercise our SecurityConfig. Do
   not change assertions or production code, and wait for my go-ahead before editing.
   ```

3. If Kiro proposes `@Import(SecurityConfig.class)`, reply
   `Go ahead. Do not run Maven; I run the tests myself.` Accept only the import and the annotation.
4. Check: `grep -n "@Import" src/test/java/com/example/usermanagement/controller/UserControllerTest.java`,
   `git diff --stat`, then `mvn -B clean verify | grep "Tests run:" | tail -n 1`

**Expected output** (step 1, before the fix):

```output
[ERROR]   UserControllerTest.invalidUserIsRejectedByBeanValidation:... Status expected:<400> but was:<403>
[ERROR]   UserControllerTest.validUserIsCreated:... Status expected:<201> but was:<403>
[ERROR] Tests run: 14, Failures: 2, Errors: 0, Skipped: 0
```

**What's going on.** `@WebMvcTest` loads beans that *implement* `WebSecurityConfigurer` or
`SecurityFilterChain`. The old adapter class did; the new class only declares a bean, so the test gets
Boot's default security, which refuses token-less POSTs (403). Fix: `@Import(SecurityConfig.class)`.

**Expect** (after the fix): the `@Import`, only `UserControllerTest.java` changed (no assertion), and
`Tests run: 14, Failures: 0, Errors: 0, Skipped: 0`.\
**Why:** [the `@WebMvcTest` javadoc, verbatim](why/03-spring-boot-3.md#311-the-webmvctest-trap)\
**Commit:** `git add -A && git commit -m "Stage 2, task 3: web test imports SecurityConfig"`

### 3.12 Run the app: migrator report and smoke test
**Goal:** re-check security on a real server, and read the migrator's report.

**Do**
1. Choose a local admin password, then start the app and keep the log:

   ```bash
   printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD
   mvn -B spring-boot:run | tee target/run.log
   ```

2. After `Started UserManagementApplication`, in a **second** terminal in `sample-app/`, set the same
   password (the `printf … read` line), then:

   ```bash
   grep -n -B4 -A3 "max-http-header-size" target/run.log
   ../scripts/smoke.sh
   ```

3. Copy the migrator's lines for Exercise 3.13; note any `hibernate.dialect` warning. Keep the app
   running.

**Expect:** an **ERROR** from `PropertiesMigrationListener` about keys "no longer supported", with
`Key: server.max-http-header-size` and a `Reason` naming `server.max-http-request-header-size`. The app
still starts. Every smoke check `PASS`: 401 without credentials, 200 as admin (the BCrypt password
fallback works), 400 for an invalid POST without a CSRF token (CSRF still ignored for `/api/**`), and
the trailing slash now **404**.\
**If not:** [T-R03](../docs/troubleshooting.md#t-r03-an-error-from-propertiesmigrationlistener-at-startup-yet-the-app-runs) ·
[T-R04](../docs/troubleshooting.md#t-r04-no-migrator-report-in-targetrunlog) ·
[T-R05](../docs/troubleshooting.md#t-r05-the-invalid-post-returns-401-on-the-running-app) ·
[T-R06](../docs/troubleshooting.md#t-r06-curl-apiusers-trailing-slash-returns-404)\
**Why:** [the dispatch-type rule, and why the migrator doesn't map this key](why/03-spring-boot-3.md#312-run-the-app-migrator-report-and-smoke-test)

### 3.13 Task 4: rename the key, and turn the verify hook back on
**Do**
1. Stop the app with **Ctrl+C**. **Attach first:** `#spec` → `spring-boot-3-upgrade`. Send the prompt
   with your copied lines in place of `<paste>`:

   ```prompt
   Implement task 4. Here is the spring-boot-properties-migrator report from startup: <paste>.
   Rename each reported key in src/main/resources/application*.properties to the replacement key
   named in its Reason line, keep the values, and update the comment above each key. Change nothing
   else, and do not run Maven.
   ```

2. Accept the hunk if it changes only that key and its comment.
3. Turn `verify-after-spec-task` back **on** with the eye icon. It stays on to the end of the module.
4. Check: `grep -rn "^server.max-http" src/main/resources` and `git status --short`

**Now:** both hooks **on**.\
**Expect:** only `server.max-http-request-header-size=16KB` as a key (comments may still mention the
old name); `application.properties` changed (plus the hook file, if the eye icon writes to it).\
**Commit:** `git add -A && git commit -m "Stage 2, task 4: renamed header-size property"`

## Write your own skill: JUnit 4 to Jupiter

You'll migrate JUnit 4 tests in every service, so write the "how" once, as a skill. Its `description`
says what it does **and when to use it**; that drives activation. **The count is the proof:** with
`junit-vintage-engine` present, JUnit 4 and Jupiter tests both run; only after you remove it and
`junit:junit` does a missed class fail to compile, and the total must still be 14.

### 3.14 Write your own skill: JUnit 4 to Jupiter
**Goal:** a skill any agent session can follow to migrate JUnit 4 tests safely.

**Do:** pick one path.
- **Fast path** (running late, or new to skills): copy the reference skill and read it:
  `mkdir -p .kiro/skills/junit4-to-jupiter && cp ../solutions/kiro-reference/skills/junit4-to-jupiter/SKILL.md .kiro/skills/junit4-to-jupiter/SKILL.md`
- **Write it:** create `.kiro/skills/junit4-to-jupiter/SKILL.md` from this skeleton (front matter on
  line 1), then complete sections 0, 2, 3 and 4 and the rest of the mapping
  ([what it must cover](why/03-spring-boot-3.md#314-write-your-own-skill-junit-4-to-jupiter)):

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
  | `@Test(expected = X.class)` | `@Test` + `assertThrows(X.class, () -> ...)` around the throwing call only |
  | `@RunWith(MockitoJUnitRunner.class)` | `@ExtendWith(MockitoExtension.class)` |
  ## 2. Apply, one class at a time
  ## 3. Remove JUnit 4 from the build
  ## 4. Never
  ```

Check: `head -n 4 .kiro/skills/junit4-to-jupiter/SKILL.md` and `ls .kiro/skills/`

**Expect:** `---` on line 1, `name: junit4-to-jupiter`, a `description` line, three skill folders, and
`junit4-to-jupiter` in the `/` menu.\
**If not:** [T-K33](../docs/troubleshooting.md#t-k33-a-skill-isnt-in-the--menu-or-is-ignored)\
**Commit:** in Exercise 3.15.

### 3.15 Have Kiro review your skill
**Do:** **Attach first:** `#src/test/java`. Send the prompt, then fix the gaps by hand: you're the
author; the agent is the reviewer.

```prompt
Review .kiro/skills/junit4-to-jupiter/SKILL.md as a Kiro skill author. Is the front matter valid
(name equals the folder name; the description says what the skill does and when to use it)? Does the
body cover @Before/@After, @Test(expected) with assertThrows, Assert to Assertions including the
message parameter order, MockitoJUnitRunner to MockitoExtension, removing SpringRunner, optional
public modifiers, and verification by test count before and after removing junit-vintage-engine and
junit:junit? Name anything in these two test classes that the skill does not cover. Answer only; do
not change any files.
```

**Expect:** your section 3 ends with a test count compared to the baseline, not "the build passes"
(Module 2's Vintage trap).\
**Commit:** `git add .kiro/skills/junit4-to-jupiter && git commit -m "Module 3: add junit4-to-jupiter skill"`

### 3.16 Task 5: migrate both test classes with your skill
**Goal:** JUnit Jupiter only, JUnit 4 gone from the build, `Tests run: 14`.

**Do**
1. Stay in **Supervised**. **Attach first:** `/junit4-to-jupiter`, then `#spec` →
   `spring-boot-3-upgrade`. Send prompt 1.
2. Review the hunks: every `@Test` kept (renames are fine); `assertThrows` wraps only the service call,
   not the `when(...)`; no assertion, `verify(...)` or `@Disabled` change; the null-only `tearDown()`
   may go; `@MockBean`, `@WithMockUser` and `@Import` untouched.
3. Send prompt 2 and accept the `pom.xml` hunks. Wait until the agent is idle, then check:

   ```bash
   grep -rnE 'import (static )?org\.junit\.(Test|Before|After|BeforeClass|AfterClass|Ignore|Rule|Assert|Assume|runner)' src/test
   grep -rnE '@RunWith|@Test\(' src/test
   grep -nE 'junit-vintage-engine|<artifactId>junit</artifactId>' pom.xml
   grep -rc "@Test" src/test/java
   ../scripts/verify-stage.sh 2
   ```

**Prompt 1**

```prompt
Implement the first half of task 5: migrate both test classes in src/test/java to JUnit Jupiter,
following the skill one class at a time. The baseline is Tests run: 14 (tag stage-1); use it instead
of building it again, and report each class's test count from the skill's per-class runs. Keep every
test scenario and assertion. Keep @MockBean, @WithMockUser and @Import(SecurityConfig.class) exactly
as they are. Do not edit pom.xml or production code yet.
```

**Prompt 2**

```prompt
Now finish task 5: remove org.junit.vintage:junit-vintage-engine and junit:junit from pom.xml as
described in section 3 of the junit4-to-jupiter skill, and replace the Vintage comment with one line
saying the tests use JUnit Jupiter only. Run the skill's leftover searches, but do not run Maven; I
run the final build myself.
```

**Expect:** no output from the first three commands, `@Test` counts 5 and 9, and `PASS: stage 2, …,
Tests run: 14, Failures: 0, Errors: 0, Skipped: 0, …`.\
**If not:** lower count → don't commit; find the missing test with `git diff stage-1 -- src/test`
([T-B02](../docs/troubleshooting.md#t-b02-tests-run-is-lower-than-14)) ·
[T-B16](../docs/troubleshooting.md#t-b16-package-orgjunit-does-not-exist-after-removing-junit-4) ·
[T-B18](../docs/troubleshooting.md#t-b18-unnecessarystubbingexception-after-the-migration)\
**Commit:** `git add -A && git commit -m "Stage 2, task 5: JUnit Jupiter only (Tests run: 14)"`

### 3.17 Improve the skill
**Do**
1. For each hunk you rejected or questioned in Exercise 3.16, add a line to "Never" or the mapping.
2. Borrow what you missed from the reference (for example the strict-stubs note and the
   `@Rule ExpectedException` row):
   `diff .kiro/skills/junit4-to-jupiter/SKILL.md ../solutions/kiro-reference/skills/junit4-to-jupiter/SKILL.md`

**Expect:** `git diff` shows only your skill file changed. **Why:** [where else a skill can live](why/03-spring-boot-3.md#317-improve-the-skill)\
**Commit:** `git add .kiro/skills/junit4-to-jupiter && git commit -m "Module 3: refine junit4-to-jupiter skill"`

## Clean up and tag

### 3.18 Task 6: final cleanup
**Goal:** no explicit Hibernate dialects, `ProblemDetail` error bodies, and no migrator. Hibernate 6
detects the dialect itself; `ProblemDetail` (RFC 9457) replaces the hand-rolled error map, as in the
stage-2 reference (in your own services, agree a new error body with clients first).

**Do:** with a clean tree, **Attach first:** `#spec` → `spring-boot-3-upgrade`, send the prompt and
review the hunks. Then check:

```bash
grep -rn "^spring.jpa.properties.hibernate.dialect" src/main/resources
grep -n "properties-migrator" pom.xml
grep -n "ProblemDetail" src/main/java/com/example/usermanagement/controller/ApiExceptionHandler.java
```

```prompt
Implement the code part of task 6. 1) Remove spring.jpa.properties.hibernate.dialect from
application.properties and application-postgres.properties, and update the JPA comment. 2) In
ApiExceptionHandler, return ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST,
ex.getMessage()) instead of the hand-rolled map. 3) Remove spring-boot-properties-migrator from
pom.xml. Change nothing else, and do not run Maven; I run the build myself.
```

**Expect:** no output from the first two commands, `ProblemDetail` in the handler. **Commit:** with
Finish. **Why:** [dialects, trailing slashes and `ProblemDetail`](why/03-spring-boot-3.md#318-task-6-final-cleanup)

## Finish: record deprecations, tag `stage-2`

1. List the deprecation warnings (`clean` recompiles everything, so all show):
   `mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true | grep -iE "deprecat|removal"`.
   Expect `MockBean` in `UserControllerTest` (deprecated since Boot 3.4, removed in Boot 4).
2. Add `Stage 2 → 3: deprecations to fix first` to `MIGRATION-NOTES.md`: one line per warning (file,
   API, replacement if known, else "unverified").
3. In `tasks.md`, choose **Sync Files**. Set the "current state" line in `.kiro/steering/tech.md` to
   Java 21, Spring Boot 3.5.16.
4. In **Agent Hooks**, check both hooks are enabled ([T-K31](../docs/troubleshooting.md#t-k31-a-hook-is-in-the-wrong-state-at-the-start-of-a-module)).
5. `../scripts/verify-stage.sh 2` → `PASS`. Then commit and tag:

   ```bash
   git add -A
   git commit -m "Stage 2 complete: Spring Boot 3.5.16, Jakarta EE 10, JUnit Jupiter"
   git tag -a stage-2 -m "Stage 2: Java 21, Spring Boot 3.5.16, Tests run: 14"
   git show stage-2 --no-patch
   ```

6. Optional: `../scripts/compare-stage.sh 2`. Expect only cosmetic differences (comments, test method
   names, layout; `User`, `UserService` and `UserController` if you skipped Module 2's Extra 2.A). Any
   other difference in a dependency, an import, a security rule or a property is worth a second look.

**Expect:** tag `stage-2` exists; both hooks on. Module 4 starts from this state.

## Extras (optional, outside the core time)

- **Extra 3.A: predict the migrator's report** before Exercise 3.12, from the migration guide. ·
  **Extra 3.B: how a skill gets picked:** describe the jakarta task without naming the skill. ·
  **Extra 3.C: task 5 as a spec task**, with the verify hook. · **Extra 3.D: a reviewer pass** on
  `git diff stage-1..stage-2 -- pom.xml src`. All four are on the
  [why page](why/03-spring-boot-3.md#extras).

## Check yourself

- [ ] `jakarta-import-guard` is enabled, and you can explain `PostFileSave`, `{{filePath}}`, why stderr
  reaches the agent, and why JDK `javax.*` packages are excluded.
- [ ] Parent `3.5.16`, no `byte-buddy.version` and no `spring-boot-properties-migrator`; no Jakarta EE
  `javax.*` import in `src/`, and no JDK package renamed.
- [ ] `SecurityConfig` has a `SecurityFilterChain` bean (lambda DSL) and an `InMemoryUserDetailsManager`;
  `UserControllerTest` has `@Import(SecurityConfig.class)`, and you can explain why.
- [ ] `server.max-http-request-header-size` replaces the old key (the migrator reported it, you renamed it).
- [ ] Your `junit4-to-jupiter` skill is listed under `/`; JUnit Jupiter only; Tests run is still 14.
- [ ] Both hooks are enabled; tag `stage-2` records `Tests run: 14`.

**Something else?** [Build and tests](../docs/troubleshooting.md#b-build-and-tests) · [Kiro](../docs/troubleshooting.md#k-kiro) · [Running app](../docs/troubleshooting.md#r-running-app)

## Next

[Module 4: Spring Boot 4.1 and Java 25 →](04-spring-boot-4-java25.md): your recorded deprecations first,
then Spring Boot 4.1.1, Jackson 3, the modular starters, Java 25 and a power.
