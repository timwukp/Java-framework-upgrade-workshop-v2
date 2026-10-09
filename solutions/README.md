# Reference solutions and reset points

Each folder is the reference state of `sample-app/` at the end of a stage. They sit **outside** the
`sample-app/` workspace on purpose, so the Kiro agent cannot find and copy them while you work.

| Folder | End of | Java | Spring Boot | Key changes from the previous stage |
|---|---|---|---|---|
| `stage-1-boot27-java21/` | Module 2 | 21 | 2.7.18 | Parent bump; `spring-boot-starter-validation`; JUnit Vintage engine; Lombok pin removed; `javax.*` API pins removed; Byte Buddy override for JDK 21; `java.time`, constructor injection, `@GetMapping` |
| `stage-2-boot35-java21/` | Module 3 | 21 | 3.5.16 | `jakarta.*`; `SecurityFilterChain` + lambda DSL; `InMemoryUserDetailsManager`; `ProblemDetail`; renamed `server.max-http-request-header-size`; no explicit Hibernate dialect; JUnit Jupiter; `@Import(SecurityConfig.class)` in the web test |
| `stage-3-boot41-java25/` | Module 4 | 25 | 4.1.1 | `spring-boot-starter-webmvc` and per-technology test starters; `@MockitoBean`; relocated `@WebMvcTest`; Jackson customizer replaced by `spring.jackson.*` properties; Lombok declared as an annotation processor (required on JDK 23+) |

Every stage has the same 13 tests (9 service + 4 web). The Kiro configuration (`.kiro/`) is not
duplicated here; you keep your own workspace's `.kiro/` folder and specs.

## Reset your workspace to a stage (the one procedure all modules use)

Use this when you are behind or stuck. Pick the row for the stage you want to **start from**:

| To start | Copy from | JDK | Tag to create | Hooks after the reset |
|---|---|---|---|---|
| Module 3 | `stage-1-boot27-java21` | 21 | `stage-1` | `verify-after-spec-task` **on**, `jakarta-import-guard` off |
| Module 4 | `stage-2-boot35-java21` | 21 | `stage-2` | `verify-after-spec-task` **on**, `jakarta-import-guard` **on** |
| Module 5 | `stage-3-boot41-java25` | 25 | `stage-3` | `verify-after-spec-task` **on**, `jakarta-import-guard` **on** |

Run every command from **`sample-app/`**. The example uses the stage-1 row; substitute the folder,
JDK and tag from your row.

1. Save your own work first, including `.kiro/` changes and specs:

   ```bash
   git add -A && git commit -m "WIP before reset" --allow-empty
   ```

2. Replace the build file and the sources with the reference state:

   ```bash
   cp ../solutions/stage-1-boot27-java21/pom.xml pom.xml
   ```

   ```bash
   rm -r src && cp -R ../solutions/stage-1-boot27-java21/src src
   ```

3. Make the row's JDK active in a terminal (see
   [participant-setup.md](../docs/participant-setup.md#switch-the-jdk-per-terminal)). **Quit Kiro and
   start it again from that terminal** with `kiro .`, so the agent and the hooks use the same JDK.

4. Check that the build passes and shows 13 tests:

   ```bash
   mvn -B clean verify | tail -n 30
   ```

5. Commit and create the stage tag, which later modules use:

   ```bash
   git add -A && git commit -m "Reset to reference stage 1"
   ```

   ```bash
   git tag -f -a stage-1 -m "Stage 1 (reference reset). Tests run: 13"
   ```

6. In the Agent Hooks panel, set the hooks as shown in your row.

## Status of these solutions

These files were written against the official migration guides and the Spring Boot 2.7.18 / 3.5.16 /
4.1.1 sources, and syntax-checked with `javac`, but **they have not been built in this repository's
CI**. The participant setup builds all three on every participant's machine
([section 7](../docs/participant-setup.md#7-pre-download-the-dependencies-for-every-stage)), and the
instructor dry run must do the same. Report any failure as an issue.
