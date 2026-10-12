# Module 2: why and background

[← Back to the Module 2 runbook](../02-runway-boot27-java21.md)

The runbook keeps only what you do and what you should see. This page holds the reasons, the sources,
the alternative paths and the evidence behind each exercise. Headings match the runbook's exercises.

## Why this stop

Spring Boot 2.2.x documents Java 8 up to 13–15, depending on the patch release, and never 21. Spring
Boot 2.7.18 supports Java 8 through 21, and the Spring Boot 3.0 Migration Guide asks for the latest
2.7.x first. So you change one variable at a time, framework then JDK, and always know which change
broke the build. Stage 1 stays on `javax.*`.

The sources behind this order:

- Spring Boot 2.2.4's system requirements document Java 8 up to Java 13. The last 2.2 patch, 2.2.13,
  raised the upper bound only to Java 15.
  ([2.2.4 System Requirements](https://docs.spring.io/spring-boot/docs/2.2.4.RELEASE/reference/html/getting-started.html),
  [2.2.13 System Requirements](https://docs.spring.io/spring-boot/docs/2.2.13.RELEASE/reference/html/getting-started.html))

> Unconfirmed: the two 2.2.x bounds are paraphrased from the linked pages; their exact wording isn't
> recorded in the workshop's research notes.

- "Spring Boot 2.7.18 requires Java 8 and is compatible up to and including Java 21. Spring Framework
  5.3.31 or above is also required."
  ([2.7.18 System Requirements](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/getting-started.html))
- The Spring Boot 3.0 Migration Guide says: "Before you start the upgrade, make sure to upgrade to the
  latest available 2.7.x version."
  ([Spring Boot 3.0 Migration Guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-3.0-Migration-Guide))
- Kiro has no "upgrade Java version" button. The upgrade is agent-driven: spec → tasks → agent edits →
  Maven verifies.

## 2.2 Create the spec

A Feature spec writes `requirements.md`, `design.md` and `tasks.md` under `.kiro/specs/<name>/`.
**Requirements-First** has you write and review the requirements before any design: here, what must
not change (the test count, the 400 response, 401, 404 and `X-Request-Id`).

> Unconfirmed: the docs don't say how Kiro names the spec folder.

## 2.3 Review the requirements

EARS pattern: `WHEN [condition/event] THE SYSTEM SHALL [expected behavior]`. Each criterion must be
checkable by a command or a test.

Example: good requirements for this stage (yours will differ):

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

Optional, if you have time: **Analyze Requirements** (in the chat options, or the **Continue**
dropdown in the editor) checks the requirement set for ambiguities and gaps. It takes minutes, not
seconds, so it doesn't fit this time box.

## 2.5 Review the tasks and commit the spec

Example task list (yours will differ):

```text
Phase A (JDK 8)
1. Change the spring-boot-starter-parent version to 2.7.18 (and its comment), nothing else
2. If Tests run dropped: restore JUnit 4 test execution (Boot 2.4 release notes)
3. If Bean Validation no longer rejects invalid input: restore it (Boot 2.3 release notes)
4. Remove the explicit javax.* API dependencies that the starters already provide
Phase B (JDK 21)
5. Run mvn -v and stop unless it reports Java 21; then set java.version to 21 and remove the Lombok version pin
```

## How the verify hook works

**The hook** runs `mvn -B clean verify` once after each task. On success the agent gets the
`Tests run` summary and `BUILD SUCCESS` and quotes them; on failure, the last 80 lines. It passes
**whenever the build passes, even when fewer tests ran**. Green isn't done: comparing the count with
14 is your job, and requirement 2's.

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

## 2.6 Bump the parent: green, but nothing ran

**Why:** Boot 2.4 removed the Vintage engine from `spring-boot-starter-test`. `junit:junit` is
declared, so the JUnit 4 tests compile, but nothing on the JUnit Platform runs them.

The version suffix: "you should update the Spring Boot version in your build.gradle/pom.xml files
from 2.3.5.RELEASE to 2.4.0."

> "If you upgrade to Spring Boot 2.4 and see test compilation errors for JUnit classes such as
> org.junit.Test, this may be because JUnit 5’s vintage engine has been removed from
> spring-boot-starter-test."
> ([Spring Boot 2.4 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.4-Release-Notes))

You get no compilation errors because this `pom.xml` declares `junit:junit` itself. The release
note's compile-error symptom is the *loud* version. Yours is the silent one. The Vintage engine is a
temporary fix: in Module 3 the tests move to JUnit Jupiter and the engine goes away.

The expected hunk for task 2 (test engine):

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

If the agent called task 1 a success: `#url` makes it read the release note rather than rely on
memory. If `#url` fails on your network, paste the quote above instead.

**Attach first:** `#spec` → `stage-1-runway`, and
`#url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.4-Release-Notes`. **Prompt**

```prompt
After task 1 the build is green but Tests run is 0; the stage-0 baseline is 14. By requirement 2
this
task failed. Explain the cause using the linked release notes, then continue with the test-engine
task. Do not change any test file.
```

## 2.7 `@Valid` is silently ignored

**Why:** since Boot 2.3 the web starter no longer brings Bean Validation. The pinned `validation-api`
jar keeps the imports compiling but holds only the API, so `@Valid` does nothing and the invalid user
gets 201. In Exercise 2.6 this test didn't even run: one silent trap hid the other.

> "As of #19550, Web and WebFlux starters do not depend on the validation starter by default anymore.
> If your application is using validation features, for example you find that javax.validation.*
> imports are not being resolved, you’ll need to add the starter yourself."
> ([Spring Boot 2.3 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.3-Release-Notes))

The `validation-api` jar holds only annotations and interfaces, not an implementation, so the invalid
user reaches the controller. In production that user would be saved. Without the test-count check you
would have shipped both problems.

The expected hunk for task 3:

```xml
<!-- Boot 2.3+: no longer included in the web starter; without it @Valid is silently ignored -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-validation</artifactId>
</dependency>
```

If the agent proposes a different fix (if `#url` fails, paste the quote above):

**Attach first:** `#spec` → `stage-1-runway`, and
`#url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.3-Release-Notes`. **Prompt**

```prompt
invalidUserIsRejectedByBeanValidation fails with 201 instead of 400. Using the linked release notes,
explain why, and fix it in pom.xml only. Do not change the test, the controller or the entity.
```

## 2.8 Remove the redundant `javax.*` pins

> Unconfirmed: the exact artifact names. On Boot 2.7 they should be `jakarta.persistence-api` and
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

## 2.10 Switch the JDK

The docs don't say which environment hooks get, so you restart Kiro from a JDK 21 terminal. Kiro's own
terminals start as new terminals and get the default JDK.

> Unconfirmed: which JDK the hook uses. If it still seems to be JDK 8, repeat steps 3 and 4.

## 2.11 See the Lombok failure, and diagnose it with `#terminal`

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

## 2.13 Check Byte Buddy, and a smoke test

Mockito and Hibernate generate classes at runtime with **Byte Buddy**; Boot 2.7.18 manages
**1.12.23**, released before Java 21. In the 2026-10-10 dry run (Corretto 21) all 14 tests and the
running app worked with it, so the reference adds **no override**. Override it only if an error names
Byte Buddy and Java 21.

- Spring Boot 2.7.18 manages Byte Buddy 1.12.23
  ([spring-boot-dependencies at v2.7.18](https://github.com/spring-projects/spring-boot/blob/v2.7.18/spring-boot-project/spring-boot-dependencies/build.gradle)).
  That version was released on "5. February 2023"
  ([Byte Buddy release notes](https://github.com/raphw/byte-buddy/blob/master/release-notes.md)),
  seven months before Java 21, and its release notes don't claim Java 21 support.
- When Byte Buddy reads a class file newer than it supports, it throws an error saying that the class
  file version is not supported by the current version of Byte Buddy, and suggests updating Byte
  Buddy or setting the `net.bytebuddy.experimental` VM property
  ([OpenedClassReader at byte-buddy-1.12.23](https://raw.githubusercontent.com/raphw/byte-buddy/byte-buddy-1.12.23/byte-buddy-dep/src/main/java/net/bytebuddy/utility/OpenedClassReader.java)).

> Unconfirmed: the error wording above is paraphrased from the linked source; it isn't recorded in the
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

### Only if an error names Byte Buddy: diagnose it, then override `byte-buddy.version`

Diagnosis first. **Attach first:** `#terminal`. **Prompt**

```prompt
The output above fails on JDK 21 with an error that mentions Byte Buddy. Which dependencies bring
Byte Buddy, which version does Spring Boot 2.7.18 manage, and what is the smallest pom.xml change
that
fixes it? Use mvn dependency:tree instead of guessing. Answer only; do not change any files.
```

Then add the override in plain chat (no hook runs; you build). **Attach first:** `#pom.xml`. **Prompt**

```prompt
Spring Boot 2.7.18 manages Byte Buddy 1.12.23, which was released before Java 21, and the build
fails
with the Byte Buddy error above. In <properties>, add
<byte-buddy.version>1.17.8</byte-buddy.version>
(the version Spring Boot 3.5.16 manages) with an XML comment that names the error it fixes and says
that stage 2 removes it. Change nothing else, and do not run Maven; I run the build myself.
```

**Accept** the hunk (one property and one comment inside `<properties>`), then build once:

```bash
mvn -B dependency:tree -Dincludes=net.bytebuddy | grep bytebuddy
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
```

Look for `byte-buddy` (and `byte-buddy-agent`) at `1.17.8`, `Tests run: 14` and `BUILD SUCCESS`. Your
`pom.xml` now differs from the reference by this one property; Module 3's task 1 removes it.

> Unconfirmed: Hibernate 5.6.15.Final with Byte Buddy 1.17.8 at runtime. The 2026-10-10 dry run built and
> tested an earlier stage-1 reference that had this override (Corretto 21, all tests green) but didn't
> start that app. If the override causes `net.bytebuddy` errors, remove it and tell the instructor (self-paced: open an issue).

```bash
git add -A
git commit -m "Stage 1 phase B: Byte Buddy override for Java 21"
```

### The smoke test

Hibernate and H2 2.x start only when the app runs: `UserServiceTest` is plain Mockito, and
`UserControllerTest` loads only the web slice (with the security configuration).

Without `APP_ADMIN_PASSWORD` and `APP_USER_PASSWORD`, the app logs two `Generated password for this
run` lines instead. The single call that proves `@Valid` works at runtime, with the generated `admin`
password from the log:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -u admin:<password> -H "Content-Type: application/json" -d '{"name":"J","email":"not-an-email"}' http://localhost:8080/api/users
```

Look for `400`. Then stop the app with **Ctrl+C**.

## Extra 2.A: light Java modernization

**Prompt**

```prompt
Modernize three classes for Java 21 without changing behaviour or any test. Make exactly these
changes and nothing else:
1. entity/User.java: replace java.util.Date with java.time.Instant for createdDate and
   lastModifiedDate. In onCreate, call Instant.now() once and assign it to both fields.
2. service/UserService.java: replace @Autowired field injection with a private final field and a
   constructor. In updateUser, use var for the local user variable.
3. controller/UserController.java: replace @Autowired field injection with a private final field and
   a constructor. Replace @RequestMapping(method = ...) on the methods with @PostMapping,
   @GetMapping, @PutMapping("/{id}") and @DeleteMapping("/{id}"), and keep the class-level
   @RequestMapping("/api/users"). createUser returns
   ResponseEntity.status(HttpStatus.CREATED).body(...). getAllUsers returns List<User> and
   updateUser returns User directly. getUserById and deleteUser keep their ResponseEntity return
   types.
Do not touch the tests, SecurityConfig, JacksonConfig, RequestIdFilter or ApiExceptionHandler. Do
not run Maven; I run the build myself.
```

Skip it if you're late; Finish doesn't depend on it. Skipped, `User`, `UserService` and
`UserController` differ from the reference solution here and in Module 3's diff checks, as expected.

The playbook also mentions records and switch expressions. This app has no DTO or `switch` that
benefits from them, so the reference solution leaves them out.

The constructor injection works with the existing `@InjectMocks` and `@MockBean` tests.

Verified in the 2026-10-10 dry run: `createdDate` and `lastModifiedDate` stay ISO-8601 but change
shape. Stage 0 (`java.util.Date`) returned `2026-10-10T14:05:14.831+0000`; the stage-1 reference
(`Instant`) returns `2026-10-10T14:05:26.019530732Z`, in UTC with up to nine fraction digits. Phase A
already changed date formatting once: "This release upgrades to Jackson 2.11 which includes a change
to the default formatting of java.util.Date and java.util.Calendar"
([Spring Boot 2.3 Release Notes](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-2.3-Release-Notes)).
No test covers it. If API clients parse these fields, check that they accept the new form.

## Evidence

What the 2026-10-10 dry run (Amazon Linux 2023, Corretto, Maven 3.9.11) showed for this module; see
the [verification log](../../docs/verification-log.md):

- After the bare parent bump (Corretto 8): `BUILD SUCCESS` with `Tests run: 0, Failures: 0, Errors: 0,
  Skipped: 0`.
- With the Vintage engine added: the hook fails with
  `invalidUserIsRejectedByBeanValidation … Status expected:<400> but was:<201>` and `Tests run: 14,
  Failures: 1`.
- On Corretto 21 with the Lombok pin: `java.lang.IllegalAccessError: class
  lombok.javac.apt.LombokProcessor … cannot access class
  com.sun.tools.javac.processing.JavacProcessingEnvironment`.
- The stage-1 reference: `Tests run: 14` on Corretto 21 with Boot's Byte Buddy 1.12.23 and no override;
  class files `major version: 65`.

**The verify hook's command.** Verified in the 2026-10-10 dry run (the command run as a plain shell
command on Linux, Corretto): green, it exits 0 and prints the `Tests run` line and `BUILD SUCCESS` on stdout; red, it exits 1 with
the summary on stdout and the last 80 lines, including the failing test, on stderr. That run didn't
cover how Kiro hands either stream to the agent.

In the 2026-10-10 dry run the stage-1 reference (Corretto 21) answered 401 without credentials, 200
for the list, 400 for the invalid request, 201 for a valid user and 404 for an unknown id, each with an
`X-Request-Id` header and ISO-8601 dates. `GET /api/users/` with a trailing slash still returned 200
on Boot 2.7; Module 3 shows why that changes.

Unconfirmed (nobody has checked these in a Kiro build yet): how Kiro names the spec folder; how Kiro
passes the hook's stdout and stderr to the agent; which JDK the hook uses after a restart; the exact
2.2.x bounds wording and the Byte Buddy error wording (paraphrased from the linked sources); the
`jakarta.*-api` artifact names on Boot 2.7; Hibernate 5.6.15 with Byte Buddy 1.17.8 at runtime.

## Docs

Feature spec (Requirements-First, EARS, Sync Files), Supervised mode, `PostTaskExec` hook, context
providers, manual and `fileMatch` steering, permissions, checkpoints, `kiro .`.

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
