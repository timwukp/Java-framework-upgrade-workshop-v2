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

- **Everything inside Kiro** (list below).
- **Timing of each module** with real participants, including the new runbook layout (2026-10-11):
  the minutes per exercise are carried over from the previous layout, and Module 3's split of the
  run-the-app exercise (3.12 and 3.13) and its skill skeleton (3.14) are estimates.
- **Module 6 platform deployments** (WAR on WildFly / Open Liberty, containers, z/OS) were not run.
- **The learner scripts** (`scripts/`, added 2026-10-11): argument handling, refusals, resets and the
  password handling pass `tools/test-scripts.sh` (quick mode); the real builds and smoke tests at every
  stage (`--full`) are the next EC2 run.

### Unconfirmed in a Kiro build

Each item names where the material depends on it. The instructor's dry run
([instructor guide, section 2](instructor-guide.md#2-dry-run-do-this-a-few-days-before-on-the-same-network-participants-will-use))
is where they get confirmed or corrected.

| ID | What is unconfirmed | Where it matters |
|---|---|---|
| U-01 | Exact UI labels and positions: the workspace-trust prompt, the confirm control in a spec session, the agent selector groups (**User** or **Global**), where the Kiro output panel is | Setup section 8; Modules 1–2 |
| U-02 | Whether and when `PostTaskExec` fires in Supervised mode (before or after **Accept**) | Module 2, Exercises 2.6–2.7 |
| U-03 | Which JDK hook commands run with after a JDK switch and a `kiro .` restart | Modules 2 and 4 (JDK switches) |
| U-04 | Whether hook commands raise approval prompts under your permission rules | Modules 1, 3 and 5 |
| U-05 | How Kiro passes a hook's stdout and stderr to the agent | Modules 2–5 (the verify hook) |
| U-06 | Whether the eye icon writes `"enabled"` to the hook file (`check-env.sh` reports the file state) | Module 3, Exercises 3.3, 3.4 and 3.13 |
| U-07 | Typing `#`/`/` and choosing from the menu (the runbooks' **Attach first**) versus pasting the token text | Every module |
| U-08 | How Kiro names a spec folder | Modules 2–4 |
| U-09 | Whether a new skill appears in `/` without reopening the workspace; how the chat shows that a skill or power was used | Modules 3, 4 and 7 |
| U-10 | How an installed custom power is shown; a second folder import of a power with the same `name`; how a folder-imported power picks up edits | Modules 4 and 7 |
| U-11 | The `kiro` command on PATH on macOS (the Command Palette action's name) | Setup section 3 |
| U-12 | Opening the parent folder's git repository from Source Control after dismissing the prompt | Module 1 (T-K06) |
| U-13 | Which shell Kiro uses for hook commands, and the shell tool's `PreToolUse` payload fields | Module 5, Exercise 5.3 |

Details for each are in the **Evidence** section of the module's why page, for example
[Module 2](../modules/why/02-runway-boot27-java21.md#evidence).

Use the dry-run checklist in the [instructor guide](instructor-guide.md) for these.
