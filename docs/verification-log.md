# Verification log

What has been checked by actually running it, what was found, and what is still unverified.

## 2026-10-10: build, trap and runtime dry run on EC2

**Scope.** This run covered everything that doesn't need Kiro:
- the reference builds for every stage;
- the migration traps the modules describe;
- the shipped hook commands, run as plain shell commands;
- the running application.

**Not covered:** anything inside Kiro (UI labels, specs, hooks firing in the IDE, agents, permissions, powers). Those still need an
instructor dry run in Kiro; see the [instructor guide](instructor-guide.md).

**Environment**

| Item | Value |
|---|---|
| Host | Amazon EC2, Amazon Linux 2023 (x86_64), t3.large |
| JDKs | Amazon Corretto 8, 21 and 25 (25.0.4.1) |
| Maven | 3.9.11 (SHA-512 checked) |
| Code | This repository at `c3ad861` (round 1), plus the fixes below (round 2) |

**How the host was set up.** The instance was temporary and locked down:
- no SSH, no key pair and no inbound rules; commands ran through AWS Systems Manager;
- outbound traffic limited to HTTPS;
- IMDSv2 required and an encrypted EBS volume;
- set to terminate itself after 3 hours.

It was terminated after the run, and its security group and IAM role were deleted.

### Round 1: the published version (29 checks)

| Check | Result |
|---|---|
| Baseline `sample-app/`, JDK 8 | ✅ BUILD SUCCESS, all tests |
| `solutions/stage-1-boot27-java21`, JDK 21 | ✅ BUILD SUCCESS, all tests |
| `solutions/stage-2-boot35-java21`, JDK 21 | ✅ BUILD SUCCESS, all tests |
| `solutions/stage-3-boot41-java25`, JDK 25 | ✅ BUILD SUCCESS, all tests |
| Module 2 trap: parent → 2.7.18 only (JDK 8) | ✅ BUILD SUCCESS with `Tests run: 0` (JUnit 4 tests silently stop running) |
| Module 2 trap: + `junit-vintage-engine` | ✅ `invalidUserIsRejectedByBeanValidation` fails: `Status expected:<400> but was:<201>` (`@Valid` ignored) |
| Module 2 trap: + `spring-boot-starter-validation` | ✅ all green |
| Baseline built on JDK 21 | Fails: Lombok 1.18.10 `IllegalAccessError` (`LombokProcessor` cannot access `JavacProcessingEnvironment`) |
| Stage 1 with Lombok pinned to 1.18.10, JDK 21 | ✅ fails with the same `IllegalAccessError` |
| Stage 1 **without** the Byte Buddy override, JDK 21 | Passes, so **the override is not needed** (see changes) |
| Stage 2 without `@Import(SecurityConfig.class)` in the web test | Fails: `Status expected:<400> but was:<403>` |
| Stage 3 without Lombok in `annotationProcessorPaths`, JDK 25 | ✅ compile fails: `cannot find symbol … method getEmail()` |
| Stage 3 with `java.version` 21 on JDK 21 / `-Djava.version=21` on JDK 21 | ✅ both pass (fallback when JDK 25 isn't available) |
| `javap` major version: stage 1 / stage 3 classes | ✅ 65 / 69 |
| Mockito on JDK 21+ | Prints "Mockito is currently self-attaching to enable the inline-mock-maker…" (expected noise) |
| Verify hook command, green build | ✅ exit 0; stdout = `Tests run: …` and `BUILD SUCCESS`; stderr empty |
| Verify hook command, red build | ✅ exit 1; stdout = summary; stderr = last 80 lines including the failing test |
| Jakarta guard command | ✅ exit 1 on a `javax.persistence` file, 0 on a `jakarta` file |
| Deploy/push block command (Module 5 reference) | ✅ exit 2 for `mvn clean deploy`, `mvn wildfly:deploy`, `git push`, `git -C … push`, `echo mvn deploy`; exit 0 for `mvn -B clean verify`, `mkdir -p deploy/zos`, `cat …/deploy-container.md` |
| Running app, stage 0 (JDK 8, generated passwords) | ✅ 401 / 200 / 400 / 201 / 404, `X-Request-Id`, ISO dates, password log lines |
| Running app, stage 3 (JDK 25) | ❌ **every POST returned 400**: the Jackson 3 trap below |
| Properties migrator (stage 2 with `server.max-http-header-size`) | ERROR report "configuration keys that are no longer supported… Replacement key 'server.max-http-request-header-size' uses an incompatible target type": reported, **not** mapped |
| Setup-guide pre-download (`dependency:tree`, `dependency:get` of the migrator) | ✅ both succeed; cache holds Boot 2.2.4.RELEASE, 2.7.18, 3.5.16, 4.1.1 |

### Finding: Jackson 3 rejects valid create requests (Spring Boot 4)

**What happened.** The stage-3 app answered `POST /api/users` with 400 for a perfectly valid user. The log said:

```text
Resolved [org.springframework.http.converter.HttpMessageNotReadableException: JSON parse error:
Cannot map `null` into type `boolean` (set DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES ...)
```

**Why.** Three changes combine:
- Spring Boot 4 uses Jackson 3, where `FAIL_ON_NULL_FOR_PRIMITIVES` is on by default.
- The Boot parent compiles with `-parameters`, so Jackson 3 binds the body through the Lombok-generated
  `@AllArgsConstructor` on `User`.
- The JSON leaves out `active`, a primitive `boolean`, so Jackson 3 fails the whole request.

**Why the tests didn't catch it.** The 13 original tests all stayed green. The only POST test expected a 400 and got one, but for the
wrong reason.

### Changes made after round 1

1. **A 14th test, `validUserIsCreated`**, at every stage (`sample-app/` and all three solutions). It posts a valid user whose
   JSON omits `active` and expects 201. Every stage now has **14 tests: 9 service + 5 web**. The build itself now catches the Jackson 3 trap.
2. **Stage 3 reference: `@AllArgsConstructor` removed from `User`.** Nothing used it, and setters keep the default `active = true`.
   The property `spring.jackson.deserialization.fail-on-null-for-primitives=false` would also stop the 400, but with constructor
   binding `active` would then become `false`. Module 4 teaches the trap at the Boot 4 parent bump.
3. **Stage 1 reference: the Byte Buddy override removed.** It was not needed on Corretto 21. The modules now treat it as a
   troubleshooting step only.
4. **Docs aligned with what was observed:**
   - the test count;
   - the migrator's real behaviour;
   - the `@Import` / 403 result;
   - the stage-3 fallback on JDK 21;
   - the trailing-slash behaviour.

### Round 2: with the changes (15 checks, all ✅)

| Check | Result |
|---|---|
| Patch applied on `c3ad861` | ✅ 6 files changed |
| Baseline JDK 8 · stage 1 JDK 21 (no override) · stage 2 JDK 21 · stage 3 JDK 25 | ✅ each `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` |
| Stage 3 with `@AllArgsConstructor` put back | ✅ fails as intended: `UserControllerTest.validUserIsCreated … Status expected:<201> but was:<400>` |
| Module 2 trap chain with 14 tests | ✅ `Tests run: 0` → `Tests run: 14, Failures: 1` (400 vs 201) → green |
| Verify hook command | ✅ exit 0, `Tests run: 14, Failures: 0` + `BUILD SUCCESS` |
| Running app, stages 0, 1, 2, 3 | ✅ 401 / 200 / 400 / 201 (`"active":true`, ISO dates) / 404 / duplicate e-mail 400 / `X-Request-Id` |
| Trailing slash `GET /api/users/` | ✅ 200 in stages 0–1, 404 in stages 2–3 |

Error bodies seen for a duplicate e-mail:
- stages 0–1: `{"error":"Email already exists","status":400}`;
- stage 2: `ProblemDetail` with `"type":"about:blank"`;
- stage 3: `ProblemDetail` without `type`. Jackson 3 also writes JSON properties in alphabetical order.

## Still unverified

- **Everything inside Kiro**, including:
  - the exact UI labels and the workspace-trust prompt;
  - whether and when hooks fire (before or after Accept in Supervised mode), which JDK they run with, and whether their commands raise approval prompts;
  - how the agent performs each spec;
  - skill and power activation, and per-module credit use.
- **Timing of each module** with real participants.
- **Module 6 platform deployments** (WAR on WildFly / Open Liberty, containers, z/OS) were not run.

Use the dry-run checklist in the [instructor guide](instructor-guide.md) for these.
