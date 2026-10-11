# Module 4: why and background

[← Back to the Module 4 runbook](../04-spring-boot-4-java25.md)

The runbook keeps only what you do and what you should see. This page holds the reasons, the sources,
the alternatives and the evidence behind each exercise. Headings match the runbook's exercises.

## What Spring Boot 4 changes

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
  Exercise 4.9), and JSON properties are written in alphabetical order (Exercise 4.12).

What the 4.1.1 parent manages, from the Spring Boot BOM at tag `v4.1.1`
([`platform/spring-boot-dependencies/build.gradle`](https://github.com/spring-projects/spring-boot/blob/v4.1.1/platform/spring-boot-dependencies/build.gradle)
and [`gradle.properties`](https://github.com/spring-projects/spring-boot/blob/v4.1.1/gradle.properties)).
You can confirm some of these with Maven in Exercise 4.9.

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


## 4.1 Read the power before you install it

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

## 4.2 Import the power from a folder

A power needs "a valid plugin.json or POWER.md file at its package root".

> Unconfirmed: how your Kiro build shows an installed custom power; the docs describe only the import steps.

Custom agents have their own `includePowers` setting; the docs example sets it to `false`. Check
the [custom agents docs](https://kiro.dev/docs/custom-agents/) for its default before you expect
`migration-reviewer` to use this power in Module 5.

Docs: [Install powers](https://kiro.dev/docs/powers/installation/) ·
[Create powers: test locally](https://kiro.dev/docs/powers/create/)


## 4.3 Plan the upgrade with the power

Example plan (yours will differ):

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
that in task 3. It may also miss the Jackson 3 trap that task 2 exposes (Exercise 4.9).

To see which knowledge was used, ask:

```text
Which powers or skills did you load for this plan, and which statements came from them?
```

Expect the power or its `spring-boot-4-upgrade` skill to be named. The workspace skill
`spring-security-lambda-dsl` may appear too, because its description mentions Spring Boot 4. If the
power wasn't used, rephrase with a keyword from `plugin.json`, for example "MockitoBean" or
"Jackson 3".

> Unconfirmed: how your Kiro build shows that a power or skill was activated (for example, a marker in the
> chat). The docs describe activation by keywords and descriptions, not the indicator. The agent's
> own answer is the fallback evidence.

Docs: [Plan mode](https://kiro.dev/docs/specs/plan/) · [Powers](https://kiro.dev/docs/powers/) ·
[Chat](https://kiro.dev/docs/ide/chat/)

## 4.5 `@MockBean` → `@MockitoBean`, still on 3.5.16

- The 4.0 guide names the replacement: `@MockBean` support is removed "in favor of @MockitoBean and
  @MockitoSpyBean support".
- `@MockitoBean` is a Spring Framework annotation (`org.springframework.test.context.bean.override.mockito`),
  not a Spring Boot one. 3.5.16 manages Spring Framework 6.2.19, so the annotation should already be
  on your classpath. The build in this exercise proves it.
- One rule from the 4.0 guide: "The new annotations are allowed to be used as fields in test classes,
  but not in @Configuration classes." Your mock is a field in a test class.

Docs: [Chat: Default agent](https://kiro.dev/docs/ide/chat/) ·
[Autopilot vs Supervised](https://kiro.dev/docs/ide/chat/autopilot/)

## 4.6 Create the spec

Quick Spec "is a session mode that auto-generates requirements, design, and tasks in a single pass",
without approval gates. You review the files before any task runs. The docs advise a Feature Spec with
review gates "for features where requirements quality is critical". For a production service, prefer
that. To use it today, start a **Spec** session, choose **Feature** and **Requirements-First**, and send
the same prompt.

Docs: [Quick Spec](https://kiro.dev/docs/specs/quick-spec/) · [Feature specs](https://kiro.dev/docs/specs/feature-specs/) ·
[Specs](https://kiro.dev/docs/specs/)

## 4.7 Review the spec before any task runs

The classic starters and `spring-boot-jackson2` exist for big codebases that can't move in one step.
The 4.0 guide recommends moving away from the classic starters "eventually", and calls
`spring-boot-jackson2` deprecated: it "will be removed in a future release".

Docs: [Specs best practices (Sync Files)](https://kiro.dev/docs/specs/best-practices/)

## 4.8 Task 1: the Jackson settings as properties

`JacksonConfig` uses `Jackson2ObjectMapperBuilderCustomizer` with `com.fasterxml.jackson.databind`
types. Boot 4 replaces both. The 4.0 guide lists "Jackson2ObjectMapperBuilderCustomizer to
JsonMapperBuilderCustomizer", and Jackson 3 moves `com.fasterxml.jackson` to `tools.jackson`. You could
port the class. For these two settings, properties are better:

1. **They survive the upgrade unchanged.** `spring.jackson.default-property-inclusion` and
   `spring.jackson.time-zone` work on both 3.5 and 4.1. Code you don't have needs no migration.
2. **They split the risk.** You change the JSON setup on 3.5, where it's proven by the tests. The
   Boot 4 bump in task 2 then doesn't touch it at all. (Jackson 3's own new defaults still change
   behaviour; Exercise 4.9 shows one.)
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

> Unconfirmed: the exact Jackson 3 builder methods in the `tools.jackson.databind.json.JsonMapper.Builder`
> javadoc before you write such a customizer. This workshop doesn't use one.

The old customizer also switched off `WRITE_DATES_AS_TIMESTAMPS`. The stage-3 reference has no
property for that and relies on Spring Boot's default of writing `java.time` values as ISO-8601
strings.

Verified in the 2026-10-10 dry run (Corretto 25): on 4.1.1 `createdDate` is an ISO-8601 string such
as `2026-10-10T14:05:52.659057Z`. The smoke test in Exercise 4.12 checks it.

Docs: [Spec tasks](https://kiro.dev/docs/specs/) · [Hooks](https://kiro.dev/docs/hooks/)

## 4.9 Task 2: Spring Boot 4.1.1, modular starters, and the Jackson 3 trap

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

### Why a valid create fails on Boot 4

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

### Optional: confirm what Maven resolved

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


## 4.10 Switch to JDK 25 and restart Kiro

Maven uses `JAVA_HOME`, so `mvn -v` is the check that matters.

> Unconfirmed: the docs don't say which environment hook commands run in. Task 3's `mvn -v` and the hook's
> build are your evidence: a hook still on JDK 21 fails with `release version 25 not supported`.

## 4.11 Task 3: `java.version` 25 and the Lombok processor

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

## 4.12 Prove it's Java 25, then run the app

Example output (yours will differ), and why the properties are in alphabetical order:

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


Without the script, the same checks with `curl` (in the second terminal, with `APP_ADMIN_PASSWORD`
set):

export APP_ADMIN_PASSWORD='<the-same-password>'
curl -s -w '\n%{http_code}\n' -u admin:"$APP_ADMIN_PASSWORD" -H 'Content-Type: application/json' -d '{"name":"Jane Doe","email":"jane@example.com"}' http://localhost:8080/api/users
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/api/users
curl -s -i -u admin:"$APP_ADMIN_PASSWORD" http://localhost:8080/api/users/1 | grep -iE "^HTTP|X-Request-Id"
```

## Finish: compare with the reference

Expect only cosmetic differences: comments and layout. The reference `User.java` has no
`@AllArgsConstructor` either. A difference in a dependency, the `maven-compiler-plugin` block, an
import, a property, the security configuration or a Lombok annotation on `User` is worth a second
look. The reference passes all 14 tests on Corretto 25 (verified in the 2026-10-10 dry run).

Docs: [Specs best practices (Sync Files)](https://kiro.dev/docs/specs/best-practices/) ·
[Steering](https://kiro.dev/docs/steering/)

## Evidence

From the 2026-10-10 dry run (Amazon Linux 2023, Corretto 21 and 25, Maven 3.9.11); see the
[verification log](../../docs/verification-log.md):

- With `@AllArgsConstructor` on `User`, `Tests run: 14, Failures: 1` (`validUserIsCreated`, 400 instead
  of 201), and the running app answered a create with 400; without it, all 14 tests pass and the app
  returns 201 with `"active":true`.
- Without the Lombok `annotationProcessorPaths` block on Corretto 25, compilation fails with `cannot
  find symbol` for `method getEmail()` and `method getName()`.
- Class files show `major version: 69` on Java 25 and 65 on Java 21.
- Jackson 3 writes JSON properties in alphabetical order; `createdDate` is an ISO-8601 string such as
  `2026-10-10T14:05:52.659057Z`; the duplicate-e-mail `ProblemDetail` no longer contains
  `"type":"about:blank"`.
- The No-JDK-25 variant:

Verified in the 2026-10-10 dry run (Corretto 21): the stage-3 reference passes all 14 tests on JDK 21
with `java.version` 21, and unedited with `mvn -B clean verify -Djava.version=21`.

- The `HttpMessageNotReadableException` line was captured in the running app's log; in the test output
  it is expected but was not captured.

Unconfirmed in a Kiro build: how an installed custom power is shown; how the chat shows that a power or
skill was activated; which environment hook commands run in; the exact Jackson 3 builder methods (see
4.8); the `includePowers` default for custom agents.

## Docs

Powers (Agent Plugins format, import from a folder), skills, Plan mode, Quick Spec, spec tasks and
Sync Files, the `PostTaskExec` verify hook, the Default agent, Supervised mode, checkpoints,
permissions and steering.

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
