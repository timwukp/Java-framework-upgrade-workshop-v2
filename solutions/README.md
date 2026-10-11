# Reference solutions and reset points

Each folder is the reference state of `sample-app/` at the end of a stage. They sit **outside** the
`sample-app/` workspace on purpose, so the Kiro agent cannot find and copy them while you work.

| Folder | End of | Java | Spring Boot | Key changes from the previous stage |
|---|---|---|---|---|
| `stage-1-boot27-java21/` | Module 2 | 21 | 2.7.18 | Parent bump; `spring-boot-starter-validation`; JUnit Vintage engine; Lombok pin removed; `javax.*` API pins removed; no Byte Buddy override (not needed on JDK 21); `java.time`, constructor injection, `@GetMapping` |
| `stage-2-boot35-java21/` | Module 3 | 21 | 3.5.16 | `jakarta.*`; `SecurityFilterChain` + lambda DSL; `InMemoryUserDetailsManager`; `ProblemDetail`; renamed `server.max-http-request-header-size`; no explicit Hibernate dialect; JUnit Jupiter; `@Import(SecurityConfig.class)` in the web test |
| `stage-3-boot41-java25/` | Module 4 | 25 | 4.1.1 | `spring-boot-starter-webmvc` and per-technology test starters; `@MockitoBean`; relocated `@WebMvcTest`; Jackson customizer replaced by `spring.jackson.*` properties; `@AllArgsConstructor` removed from `User` (with Jackson 3 it made every POST return 400); Lombok declared as an annotation processor (required on JDK 23+) |

`kiro-reference/` holds reference copies of the Kiro files you write yourself: the `junit4-to-jupiter`
skill (Module 3) and the `block-deploy-and-push` hook (Module 5). Compare with them, or copy them if you
run out of time.

Every stage has the same 14 tests (9 service + 5 web). The Kiro configuration (`.kiro/`) is not
duplicated here; you keep your own workspace's `.kiro/` folder and specs.

## Reset your workspace to a stage (the one procedure all modules use)

Use this when you are behind or stuck. Pick the row for the stage you want to **start from**. Run every
command from **`sample-app/`**. Your `.kiro/` folder, specs and git history stay.

| Reset to | To start | Source | JDK | Tag to create | Hooks after the reset |
|---|---|---|---|---|---|
| `stage-0` | Module 2 (again) | your `stage-0` tag, or `origin/main` | 8 | none if `stage-0` exists, else `stage-0` | `verify-after-spec-task` **on**, `jakarta-import-guard` off |
| `stage-1` | Module 3 | `stage-1-boot27-java21` | 21 | `stage-1` | `verify-after-spec-task` **on**, `jakarta-import-guard` off |
| `stage-2` | Module 4 | `stage-2-boot35-java21` | 21 | `stage-2` | `verify-after-spec-task` **on**, `jakarta-import-guard` **on** |
| `stage-3` | Module 5 | `stage-3-boot41-java25` | 25 | `stage-3` | `verify-after-spec-task` **on**, `jakarta-import-guard` **on** |
| `stage-3-final` | Module 6 or 7 | `stage-3-boot41-java25` plus `kiro-reference/hooks/block-deploy-and-push.json` | 25 | `stage-3-final` | both **on**, plus `block-deploy-and-push` |

1. Save your own work first, including `.kiro/` changes and specs:

   ```bash
   git add -A && git commit -m "WIP before reset" --allow-empty
   ```

2. Replace the build file and the sources with the reference state. Either let the script do it (it
   asks you to type `yes`, then prints steps 3 to 6 with your row's values):

   ```bash
   ../scripts/reset-to-stage.sh 2
   ```

   Or type your row's commands yourself:

   | Row | Commands |
   |---|---|
   | `stage-0` | `git restore --source=stage-0 --staged --worktree -- pom.xml src` (no `stage-0` tag: use `--source=origin/main`) |
   | `stage-1` | `cp ../solutions/stage-1-boot27-java21/pom.xml pom.xml && rm -r src && cp -R ../solutions/stage-1-boot27-java21/src src` |
   | `stage-2` | `cp ../solutions/stage-2-boot35-java21/pom.xml pom.xml && rm -r src && cp -R ../solutions/stage-2-boot35-java21/src src` |
   | `stage-3` | `cp ../solutions/stage-3-boot41-java25/pom.xml pom.xml && rm -r src && cp -R ../solutions/stage-3-boot41-java25/src src` |
   | `stage-3-final` | The `stage-3` commands, then `cp ../solutions/kiro-reference/hooks/block-deploy-and-push.json .kiro/hooks/` |

3. Make the row's JDK the default for new terminals (see
   [participant-setup.md](../docs/participant-setup.md#switch-the-jdk-per-terminal)). **Quit Kiro and
   start it again** from a new terminal in `sample-app/` with `kiro .`, so the agent and the hooks use
   the same JDK.

4. Check that the build passes and shows 14 tests (replace `2` with your row's stage number):

   ```bash
   ../scripts/verify-stage.sh 2
   ```

   Without the script: `mvn -B clean verify | tail -n 30`, and look for
   `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` and `BUILD SUCCESS`.

5. Commit and create the stage tag, which later modules use:

   | Row | Commands |
   |---|---|
   | `stage-0` | `git add -A && git commit -m "Reset to stage 0"`, then `git tag -a stage-0 -m "Stage 0 (reference reset): Java 8, Spring Boot 2.2.4, Tests run: 14"` only if you had no `stage-0` tag |
   | `stage-1` | `git add -A && git commit -m "Reset to reference stage 1" && git tag -f -a stage-1 -m "Stage 1 (reference reset): Java 21, Spring Boot 2.7.18, Tests run: 14"` |
   | `stage-2` | `git add -A && git commit -m "Reset to reference stage 2" && git tag -f -a stage-2 -m "Stage 2 (reference reset): Java 21, Spring Boot 3.5.16, Tests run: 14"` |
   | `stage-3` | `git add -A && git commit -m "Reset to reference stage 3" && git tag -f -a stage-3 -m "Stage 3 (reference reset): Java 25, Spring Boot 4.1.1, Tests run: 14"` |
   | `stage-3-final` | `git add -A && git commit -m "Reset to reference stage 3-final" && git tag -f -a stage-3-final -m "Stage 3 verified (reference reset): Java 25, Spring Boot 4.1.1, Tests run: 14"` |

6. In the Agent Hooks panel, set the hooks as shown in your row (the eye icon).

## Status of these solutions

These files were written against the official migration guides and the Spring Boot 2.7.18 / 3.5.16 /
4.1.1 sources. They are not built in this repository's CI, but all three passed with 14 tests in the
2026-10-10 dry run on Linux (stages 1 and 2 on Corretto 21, stage 3 on Corretto 25); see the
[verification log](../docs/verification-log.md). The participant setup builds all three on every
participant's machine
([section 7](../docs/participant-setup.md#7-pre-download-the-dependencies-for-every-stage)), and the
instructor dry run must do the same. Report any failure as an issue.
