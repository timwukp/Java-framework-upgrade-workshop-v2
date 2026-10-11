# Module 3: why and background

[← Back to the Module 3 runbook](../03-spring-boot-3.md)

The runbook keeps only what you do and what you should see. This page holds the reasons, the sources,
the alternatives and the evidence behind each exercise. Headings match the runbook's exercises.

## Why this stage, and why 3.5 is not the destination

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
these with Maven in Exercise 3.6): Spring Framework 6.2.19, Spring Security 6.5.11, Hibernate
6.6.53.Final (group `org.hibernate.orm`), Byte Buddy 1.17.8, Lombok 1.18.46, JUnit Jupiter 5.12.2,
Mockito 5.17.0.

## 3.2 Read the guard, and try its command

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

## 3.3 Enable the guard

When the agent writes into `.kiro/hooks/`, Kiro always asks for approval, even with allow rules.
That's why you toggle the hook yourself.

> Unconfirmed: if you used the eye icon and `git diff` shows nothing, your build stores the toggle outside
> the file. The panel state is what counts for today. To share the setting with your team, set it in
> the JSON file.

Docs: [Managing hooks](https://kiro.dev/docs/hooks/management/) ·
[Permissions](https://kiro.dev/docs/permissions/)

## 3.4 Pause the verify hook

The `PostTaskExec` hook would run Maven after the task, fail, and hand the compile errors to the agent
as something to fix: the jakarta and security work, out of order and without the skills. A guard
helps when the expected state is green.

If the toggle changed the JSON file, that's fine; it's back to enabled in Exercise 3.13.

## 3.5 Plan the stage with Quick Spec

Quick Spec "is a session mode that auto-generates requirements, design, and tasks in a single pass",
without approval gates. The docs add a caveat: "For features where requirements quality is critical -
compliance-sensitive domains, high-stakes systems, unfamiliar territory - a standard Feature Spec with
explicit review gates is usually the better fit." For a production service, prefer a Feature spec
(Requirements-First), as in Module 2. If you want the gates today, start a **Spec** session instead and
send the same prompt.

Docs: [Quick Spec](https://kiro.dev/docs/specs/quick-spec/) · [Specs](https://kiro.dev/docs/specs/) ·
[Feature specs](https://kiro.dev/docs/specs/feature-specs/) ·
[Specs best practices](https://kiro.dev/docs/specs/best-practices/)

## 3.6 Task 1: the 3.5.16 parent and the properties migrator

Expected shape of the new dependency:

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

Notes on the checks:

- Clicking the task item moves its status to in progress, then done.
- 1.17.8 is also the version Module 2's fallback override pins (only if an error named Byte Buddy);
  the parent now manages it, so such a pin has no reason left (`pom-rules.md`). The 2026-10-10 dry
  run needed no override at stage 1 (Corretto 21).
- `dependency:tree` doesn't need the code to compile. Don't add `-q` to it: the tree is printed at
  INFO level, which `-q` hides.
- The compile errors in `User.java`, `UserController.java` and `RequestIdFilter.java` come from
  `javax.*` imports; the one in `SecurityConfig.java` from `WebSecurityConfigurerAdapter`.


## How skills activate

Per the docs: "At startup, Kiro loads only the name and description of each skill". The full
instructions load when the skill activates, in one of two ways:

- **Automatically:** "Kiro matches your request against skill descriptions and loads the relevant
  skill".
- **As a slash command:** "Type / followed by the skill name to invoke it directly".

Docs: [Skills](https://kiro.dev/docs/skills/) ·
[Slash commands](https://kiro.dev/docs/ide/chat/slash-commands/)

Why Autopilot for Exercises 3.7–3.8 and Supervised from Exercise 3.10: match the autonomy to the risk.

## 3.7 Watch the guard catch a leftover

Example of the agent's reply (yours will differ):

```text
After the save, the jakarta-import-guard hook reported:
15:import javax.validation.constraints.Email;
16:import javax.validation.constraints.NotNull;
17:import javax.validation.constraints.Size;
Jakarta EE API still imported from javax.* - migrate it to jakarta.* (JDK packages such as javax.sql stay).
```

Some agents fix the three imports right away in response. That's the feedback loop working. Either
outcome is fine; Exercise 3.8 finishes the job. If nothing was reported, see troubleshooting T-K29.

Docs: [Hook types: file triggers](https://kiro.dev/docs/hooks/types/) ·
[Hook troubleshooting](https://kiro.dev/docs/hooks/troubleshooting/)

## 3.8 Task 2: migrate the namespace with the skill

- `pom.xml` may also show a changed comment.
- No `import javax.` lines at all: this app happens to use no JDK `javax` packages. In your own
  services, imports such as `javax.sql.DataSource` stay, and that is correct.
- `jakarta.persistence` 8, `jakarta.servlet` 4, `jakarta.validation` 4 are the same counts the `javax`
  imports had.
- Module 2 already removed the explicit `javax.servlet`, `javax.persistence` and `validation-api`
  dependencies; if your `pom.xml` still declares any of them, the skill removes them now.
- If the agent changed `SecurityConfig.java` anyway, restore it: Exercise 3.10 migrates it under review.

## 3.9 Back to Supervised

| Safety net | Caught | Can't catch |
|---|---|---|
| Compiler | Every `javax.*` import of an API no longer on the classpath | String literals (for example JPA hint names) and XML files such as `persistence.xml` |
| `jakarta-import-guard` | Leftover Jakarta EE imports in any Java file the agent saves | Your own edits, files the agent didn't save, non-Java files |
| The skill's own steps | Non-Java files, `pom.xml` pins, the final search | Whatever the agent skips; check its report |
| git | Anything, as long as you committed first | Nothing you didn't commit |
| Your prompt boundary | The security skill starting early | Nothing by itself; the agent has to respect it |

Docs: [Autopilot and Supervised mode](https://kiro.dev/docs/ide/chat/autopilot/) ·
[Checkpoints](https://kiro.dev/docs/checkpoints/)

## Spring Security 6: the sources

"The Lambda DSL is the preferred way to configure Spring Security, the prior configuration style will
not be valid in Spring Security 7 where the usage of the Lambda DSL will be required."
([Spring Security 6.5: Preparing for 7.0](https://docs.spring.io/spring-security/reference/6.5/migration-7/configuration.html))

Supervised mode, per the docs: "Kiro yields for your approval after each turn that contains file
edits", and each hunk has **Accept**, **Reject** and **Chat inline**.

## 3.10 Task 3: migrate `SecurityConfig`, one hunk at a time

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


With `-q`, a successful compile prints nothing. The guard hook stayed quiet because the file has no
`javax` imports.

## 3.11 The `@WebMvcTest` trap

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

## 3.12 Run the app: migrator report and smoke test

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

Without the script, with the generated `admin` password from the log
(`grep "Generated password for this run" target/run.log`), the four checks are:

```bash
PW=<admin password from the log>
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/users
curl -s -o /dev/null -w "%{http_code}\n" -u "admin:$PW" http://localhost:8080/api/users
curl -s -o /dev/null -w "%{http_code}\n" -u "admin:$PW" -H 'Content-Type: application/json' -d '{"name":"J","email":"not-an-email"}' http://localhost:8080/api/users
curl -s -o /dev/null -w "%{http_code}\n" -u "admin:$PW" http://localhost:8080/api/users/
```

Expect `401` (no credentials), `200` (admin: the BCrypt password fallback works), `400` (invalid
POST without a CSRF token: CSRF still ignored for `/api/**`), `404` (trailing slash; see 3.18). The
2026-10-10 dry run got exactly these on stage 2; the trailing slash still gave 200 on stage 1.

## 3.14 Write your own skill: JUnit 4 to Jupiter

Rules for the file: `.kiro/skills/<name>/SKILL.md`; `name` matches the folder; `description` up to
1,024 characters, saying what the skill does and when to use it. `$ARGUMENTS` placeholders are
substituted only in the CLI, so write the skill for "the test classes in this workspace", not for
parameters.

Front matter `name`, per the docs: "Must match folder name. Lowercase letters, numbers, and hyphens
only (max 64 chars)."

`test-rules.md` already says **what** the target is (JUnit Jupiter from stage 2). A skill says
**how**, step by step, including how to prove that no test got lost. And unlike an `always` steering
file, it costs almost no context until it's needed: only its name and description load up front.


The skill must cover:

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


The `@WebMvcTest` javadoc shows that the annotation is itself annotated with
`@ExtendWith(org.springframework.test.context.junit.jupiter.SpringExtension.class)`, and says: "When
using JUnit 4, this annotation should be used in combination with @RunWith(SpringRunner.class)."

Docs: [Skills](https://kiro.dev/docs/skills/)


> Unconfirmed: if the new skill isn't listed, check the folder name, the `name` value and that the front
> matter starts on line 1. The docs don't say whether a new skill appears without reopening the
> workspace; if it still doesn't show, reload the window.

## 3.16 Task 5: migrate both test classes with your skill

Example output, and a review note (yours will differ):

```text
src/test/java/com/example/usermanagement/controller/UserControllerTest.java:5
src/test/java/com/example/usermanagement/service/UserServiceTest.java:9
[INFO] Tests run: 14, Failures: 0, Errors: 0, Skipped: 0
```

The `@Test` counts are the same as at stage 1. In the hunk review, renaming `testCreateUser` to
`createUser` is fine, and so is deleting the `@After tearDown()` that only sets `testUser = null`.


## 3.17 Improve the skill

- **This repository:** `.kiro/skills/`, shared with your team through git.
- **All your projects:** `~/.kiro/skills/` (IDE and CLI). When names clash, "workspace skills take
  priority over global skills."
- **Other teams:** skills follow the open Agent Skills standard, and Kiro can import a skill from a
  GitHub subdirectory URL or a local folder. Module 4 packages skills into a power.

The reference also has an `@Rule ExpectedException` row worth borrowing.

Docs: [Skills](https://kiro.dev/docs/skills/) · [Powers](https://kiro.dev/docs/powers/)

## 3.18 Task 6: final cleanup

- **Hibernate dialects.** Boot 3.5.16 manages Hibernate 6.6. Hibernate 6 detects the dialect from the
  database connection, so `spring.jpa.properties.hibernate.dialect` (`H2Dialect`, and
  `PostgreSQL10Dialect` in the postgres profile) is usually unnecessary. The migrator only knows Spring
  Boot's own keys; this one is passed straight through to Hibernate, so the migrator doesn't mention
  it.

  > Unconfirmed: the Spring Boot 3.0 migration guide doesn't cover dialects. It only says "Spring Boot 3.0
  > uses Hibernate 6.1 by default. Please see the Hibernate 6.0 and 6.1 migration guides to learn how
  > this may affect your application." Check dialect detection and the version-specific PostgreSQL
  > dialects in the Hibernate ORM 6 migration guides, and watch the startup log for a Hibernate warning
  > about the dialect property. The postgres profile isn't covered by the tests; if you use it, start
  > the app with it once.

- **Trailing slashes.** "As of Spring Framework 6.0, the trailing slash matching configuration option
  has been deprecated and its default value set to false." So "\"GET /some/greeting/\" doesn't match
  anymore by default and will result in an HTTP 404 error" (3.0 guide). You saw this in Exercise 3.12.
  Verified in the 2026-10-10 dry run: `GET /api/users/` returns 200 on stages 0–1 and 404 on stages 2–3.
  The app needs no change; clients that call `/api/users/` must drop the slash. The guide shows a
  temporary `configurer.setUseTrailingSlashMatch(true)` in a `WebMvcConfigurer`, but the option itself
  is deprecated, so don't build on it.
- **`ProblemDetail`.** Spring Framework 6 can return RFC 9457 problem details instead of the
  hand-rolled `{status, error}` map in `ApiExceptionHandler`. Clients see a different error body, so
  treat it as an API change, not a refactoring.
- **The migrator.** "Once you're done with the migration, please make sure to remove this module from
  your project's dependencies." (3.0 guide)


## Finish: the `@MockBean` deprecation

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

## Extras

### Extra 3.A: predict the migrator's report (2 minutes)

**Goal:** know what the migrator does, when you'll see its report, and what it can't see.

The 3.0 guide: "Spring Boot provides a spring-boot-properties-migrator module." The 4.0 guide describes
the same module: "this will not only analyze your application's environment and print diagnostics at
startup, but also temporarily migrate properties at runtime for you." It reports **at startup**, so you
can't read its report until the application compiles and starts. You'll do that in Exercise 3.12.
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
  passed straight through to Hibernate, so the migrator won't mention it. Exercise 3.18 handles it.
- **Reported doesn't mean migrated.** Predict, too, whether the migrator will map this key to its
  replacement at runtime. Exercise 3.12 shows the answer.

**Checkpoint:** nothing changed.

Docs: [Chat: context providers (`#url`)](https://kiro.dev/docs/ide/chat/)

### Extra 3.B: how a skill gets picked (5 minutes)

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

> Unconfirmed: the docs describe how skills activate, not how the chat shows it. If the answer doesn't
> mention the skill, it may have answered from general knowledge. That's why Exercise 3.8 invokes the
> skill explicitly.

**Checkpoint:** nothing changed (`git status`).

### Extra 3.C: task 5 as a spec task, with the verify hook

Instead of the first prompt, click task 5 in `tasks.md`. Kiro can activate your skill automatically
when the task matches its description. The re-enabled `verify-after-spec-task` hook then runs
`mvn -B clean verify` and reports the `Tests run` line: read it in the Kiro output panel, or run the
build under **Verify** only after the hook has finished. Afterwards, ask "Which skills did you use for
task 5?" to find out whether your description did its job.

Docs: [Skills](https://kiro.dev/docs/skills/) · [Specs](https://kiro.dev/docs/specs/) ·
[Hooks](https://kiro.dev/docs/hooks/)

### Extra 3.D: a reviewer pass

If you have time left, switch to the `migration-reviewer` agent and ask it to review
`git diff stage-1..stage-2 -- pom.xml src`. It has no write tool and is instructed not to modify
files, but it can run shell commands; run `git status` after the review.

## Evidence

From the 2026-10-10 dry run (Amazon Linux 2023, Corretto 21, Maven 3.9.11); see the
[verification log](../../docs/verification-log.md):

- The guard's command exits 1 on a file with `javax.persistence` imports and 0 on the same file with
  `jakarta` ones (run as a plain shell command; whether and when Kiro fires the hook was not covered).
- Without `@Import(SecurityConfig.class)`: `invalidUserIsRejectedByBeanValidation … Status
  expected:<400> but was:<403>`. That run predates `validUserIsCreated`; its 403 line and the
  `Failures: 2` total are the expected result with 14 tests.
- On the running stage-2 app: 401, 200, 400 and a 404 for the trailing slash (200 on stage 1); the
  migrator reports `server.max-http-header-size` in its ERROR report and does not map it.
- Mockito 5's self-attaching warning on stages 2 and 3 is noise.

Unconfirmed in a Kiro build: whether the eye icon writes `"enabled"` to the hook file; whether a new
skill appears in `/` without reopening the workspace; how the chat shows that a skill was picked;
dialect detection details for your database (see 3.18).

## Docs

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
