# Quick reference

Full details and docs links: [kiro-feature-reference.md](kiro-feature-reference.md).

## Kiro

### Start the right kind of session
| You want to… | Use |
|---|---|
| Understand the code without changing anything | **Plan** workflow (read-only) |
| A reviewed, multi-step change | **Spec** (requirements → design → tasks) |
| A change whose scope is already defined (Modules 3 and 4: a whole stage from the playbook), in one pass without approval gates | **Quick Spec**, then review the files before any task runs |
| Fix a regression, with guards against breaking more | **Bug Fix** (`bugfix.md`) |
| Ask questions, iterate freely | Default agent |
| A specialist | Agent selector → `migration-reviewer` |

### Context in chat
`#codebase` · `#file` (type `#` plus a file name) · `#folder` · `#git diff` · `#terminal` · `#problems` ·
`#spec` · `#steering` · `#docs` · `#url` · `#code` · `#current` · `#repository` · `#mcp`.
Select code and press **Cmd/Ctrl+L** to add it to the chat.

### Safety habits
- **Supervised** mode (`kiroAgent.agentAutonomy`) lets you review each hunk before it is applied.
- **Commit before every agent run.** Checkpoints don't capture shell commands (Maven, OpenRewrite) or
  manual edits.
- **Trust** the workspace, or repo steering, agents and skills won't load.
- Approve `mvn *` once with **Always allow** for this workspace. Never pre-approve deploy or push.
- **One build at a time.** After a spec task, read the hook's result in the Kiro output, or run Maven
  yourself only after the hook has finished (builds share `target/`).
- **After a JDK switch**, quit Kiro and start it from that terminal with `kiro .`.
- **Always `clean`** (`mvn -B clean verify`): otherwise Maven may skip the recompile after a JDK or
  version change and hide a trap.
- After a review by `migration-reviewer`, run `git status`: it has no `write` tool, but it has `shell`.

### File formats
`.kiro/steering/<name>.md`. The front matter must be the very first lines:

```yaml
---
inclusion: fileMatch          # always | fileMatch | manual | auto
fileMatchPattern: "**/pom.xml"
---
```

`.kiro/hooks/<name>.json`:

```json
{ "version": "v1", "hooks": [ { "name": "verify", "trigger": "PostTaskExec",
  "action": { "type": "command", "command": "mvn -q -B clean verify 1>&2" }, "timeout": 900 } ] }
```
The shipped `verify-after-spec-task.json` does more: one `mvn -B clean verify`, the `Tests run` line
and `BUILD SUCCESS` to the agent on success, the last 80 lines on stderr on failure.
Triggers: `SessionStart` `Stop` `UserPromptSubmit` `PreTaskExec` `PostTaskExec` `PreToolUse`
`PostToolUse` `PostFileCreate` `PostFileSave` `PostFileDelete`. A command action that exits with `2`
blocks `PreToolUse`, `UserPromptSubmit` and `PreTaskExec`. On failure, **stderr** goes to the agent.

`.kiro/skills/<name>/SKILL.md`. `name` must equal the folder name:

```markdown
---
name: junit4-to-jupiter
description: What it does and when to use it (this text drives automatic activation).
---
```

`.kiro/agents/<name>.md`. The front matter is the config and the body is the system prompt:

```markdown
---
name: migration-reviewer
description: Reviewer. No write tool; instructed not to modify files
tools: ["read", "shell"]
resources:
  - "file://.kiro/steering/**/*.md"
---
```

`powers/<name>/plugin.json`, plus `skills/` and an optional `mcp.json`:

```json
{ "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "java-modernization", "version": "1.0.0", "description": "…",
  "author": { "name": "…" }, "keywords": ["spring boot 4", "java 25"] }
```

## Migration cheat sheet

### Stage 1: Spring Boot 2.2.4 → 2.7.18, JDK 8 → 21
| Change | Why |
|---|---|
| Parent `2.7.18` | Last 2.x line; compatible up to Java 21 |
| Add `spring-boot-starter-validation` | Since Boot 2.3 it isn't in the web starter; `@Valid` is silently ignored without it |
| Add `junit-vintage-engine` (test) | Since Boot 2.4 it isn't in starter-test; JUnit 4 tests silently stop running |
| Remove the Lombok pin | 1.18.10 can't run on JDK 16+; Boot 2.7.18 manages 1.18.30 (first with JDK 21 support) |
| `java.version` 21 | — |
| `byte-buddy.version` 1.17.8 override | Boot 2.7.18 manages Byte Buddy 1.12.23, older than Java 21 (the reference keeps the override) |

### Stage 2: Spring Boot 2.7.18 → 3.5.x (Java 21)
| Before | After |
|---|---|
| `javax.persistence/validation/servlet/inject/transaction.*` | `jakarta.*` (JDK `javax.sql`, `javax.crypto`, `javax.transaction.xa`… stay) |
| `extends WebSecurityConfigurerAdapter` | `@Bean SecurityFilterChain` + lambda DSL |
| `inMemoryAuthentication()` | `@Bean UserDetailsService` → `InMemoryUserDetailsManager` |
| `authorizeRequests` / `antMatchers` | `authorizeHttpRequests` / `requestMatchers` |
| `server.max-http-header-size` | `server.max-http-request-header-size` |
| `hibernate.dialect` property | Usually not needed with Hibernate 6 |
| JUnit 4 + Vintage | JUnit Jupiter only |
| (web tests) | `@Import(SecurityConfig.class)` if security no longer applies in `@WebMvcTest` |

### Stage 3: Spring Boot 3.5.x → 4.1.x, Java 21 → 25
| Before | After |
|---|---|
| `spring-boot-starter-web` | `spring-boot-starter-webmvc` |
| `spring-boot-starter-test` only | `spring-boot-starter-webmvc-test`, `spring-boot-starter-security-test` |
| `org.springframework.boot.test.mock.mockito.MockBean` | `org.springframework.test.context.bean.override.mockito.MockitoBean` |
| `org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest` | `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` |
| `Jackson2ObjectMapperBuilderCustomizer` | `spring.jackson.*` properties, or `JsonMapperBuilderCustomizer` |
| `com.fasterxml.jackson.databind.*` | `tools.jackson.databind.*` (annotations unchanged) |
| `.and()` / non-lambda security DSL | Lambda DSL only (Spring Security 7) |
| `java.version` 21 | 25 (Lombok ≥ 1.18.40) |
| Lombok only as a `provided` dependency | Also in `maven-compiler-plugin` `annotationProcessorPaths` (`${lombok.version}`): since JDK 23, javac no longer runs annotation processors it finds only on the class path |

## Commands
Expected test count at every stage: `Tests run: 13` (9 service + 4 web). Read your own number anyway.

```bash
mvn -B clean verify
```
```bash
mvn -B dependency:tree -Dincludes=org.projectlombok,net.bytebuddy
```
```bash
mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true -Dmaven.compiler.showWarnings=true | grep -iE "deprecat|removal"
```
```bash
grep -rnE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])' src
```

Annotated stage tags carry the test count (`stage-0`, `stage-1`, `stage-2`, `stage-3`, then
`stage-3-final` in Module 5):

```bash
git tag -a stage-1 -m "Stage 1: Java 21, Spring Boot 2.7.18, Tests run: 13" && git tag -n1 -l "stage-*"
```

Behind? Use the one reset procedure in [solutions/README.md](../solutions/README.md), run from
`sample-app/`.
