# Troubleshooting

Find your symptom with your browser's search (Cmd/Ctrl+F) or the outline button at the top of this
page. Each entry has a stable ID (for example **T-B01**) that the modules link to.

| Group | Covers |
|---|---|
| [A: Setup and JDK](#a-setup-and-jdk) | Installing, JDK switching, starting Kiro, credits |
| [K: Kiro](#k-kiro) | Trust, permissions, steering, specs, hooks, skills, powers, agents |
| [B: Build and tests](#b-build-and-tests) | Maven, test counts, migration compile and test errors |
| [R: Running app](#r-running-app) | `mvn spring-boot:run`, `curl` and `smoke.sh` results |
| [D: Deployment (Module 6)](#d-deployment-module-6) | Containers, WAR, application servers, z/OS |
| [S: Scale-out (Module 7)](#s-scale-out-module-7) | Sharing powers, `kiro-cli` in CI, Kiro Web, Workflows |
| [X: Recovery](#x-recovery) | Undoing agent work, missing tags, catching up |

Before anything else, two checks fix most problems: `../scripts/check-env.sh --stage N` (your JDK,
tools and workspace) and `../scripts/verify-stage.sh N` (one clean build with the test count), both
run from `sample-app/`. See [scripts/README.md](../scripts/README.md).

"Unconfirmed" marks a detail nobody has yet checked in a Kiro build; see the
[verification log](verification-log.md).

---

## A: Setup and JDK

### T-A01 `mvn -v` shows the wrong Java in your terminal
**Cause:** `JAVA_HOME` points to another JDK (on Linux, `update-alternatives` changes only `java`).
**Fix:** switch the JDK per terminal ([participant setup](participant-setup.md#switch-the-jdk-per-terminal)).
`mvn -v` must show the stage's JDK (`1.8.0_…` for JDK 8). `../scripts/check-env.sh --stage N` checks
`java` and Maven together.

### T-A02 The agent's or the hook's Java is not your terminal's
**Symptoms:** the agent's `mvn -v` reports Java 21 or 25 in Module 1; it still reports 1.8 after the
switch to JDK 21; `release version 25 not supported`, or the agent or hook reports Java 21, after the
switch to JDK 25.
**Cause:** the agent's shell and the hooks use the environment Kiro was started with. Kiro was started
from the Dock or a launcher, or before you changed the default JDK.
**Fix:** make the JDK the default for new terminals, quit Kiro completely, open a new terminal and start
Kiro from `sample-app/` with `kiro .`. Ask the agent for `mvn -v` again.

### T-A03 `kiro: command not found`
**Cause:** the `kiro` command isn't on your PATH.
**Fix:** on macOS, Code OSS-based editors offer a Command Palette action such as **Shell Command:
Install 'kiro' command in PATH** (unconfirmed: check the name in your build). Linux packages usually
install the command. Until then, open `sample-app/` with **File > Open Folder**; Kiro then may not use
your terminal's JDK (T-A02).

### T-A04 `/usr/libexec/java_home -v 1.8` can't find a matching JVM
**Cause:** JDK 8 isn't installed, or was installed by unpacking an archive.
**Fix:** install the Corretto 8 `.pkg`, or use SDKMAN.

### T-A05 `python3` opens an "install command line developer tools" dialog (macOS)
**Cause:** the Xcode Command Line Tools aren't installed.
**Fix:** accept the install before the day; it takes several minutes.

### T-A06 Dependency downloads fail or time out
**Cause:** a proxy, or Maven Central is blocked.
**Fix:** configure a proxy or your company mirror in `~/.m2/settings.xml`. Run the pre-download
([participant setup, section 7](participant-setup.md#7-pre-download-the-dependencies-for-every-stage))
before the day.

### T-A07 macOS says Kiro "is damaged" or can't be opened
**Cause:** the download quarantine flag.
**Fix:** per the Kiro troubleshooting page: `sudo xattr -d com.apple.quarantine /Applications/Kiro.app`.

### T-A08 The sign-in page doesn't load behind a proxy
**Cause:** browser sign-in uses the OS network stack, not Kiro's proxy settings.
**Fix:** fix the OS or browser proxy. The
[installation page](https://kiro.dev/docs/getting-started/installation/) links to the full proxy and
allowlist reference.

### T-A09 The agent can't run commands, or `#terminal` is empty
**Cause:** shell integration isn't active.
**Fix:** Command Palette → **Kiro: Enable Shell Integration**. For zsh, add
`[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"` to `~/.zshrc`
(bash: the same line with `bash`). Powerlevel10k users also add
`typeset -g POWERLEVEL9K_TERM_SHELL_INTEGRATION=true`.

### T-A10 The editor shows Java errors, but `mvn -B clean verify` succeeds
**Cause:** the editor's Java tooling uses its own JDK and project import.
**Fix:** trust Maven. Unconfirmed: the Java extension's README says how to point its language server at
a JDK (it may need a newer JDK than the project's JDK 8).

### T-A11 You run out of credits during the day
**Cause:** the Free plan (50 credits) doesn't cover a full day.
**Fix:** use a paid plan or an organization seat; check usage in Kiro's subscription dashboard. On the
day, pair with a neighbour (one drives, both review the hunks) until it's sorted. If your plan allows
it, a model with a lower multiplier than Auto (1.0x) stretches what's left.

### T-A12 `docker compose up` fails
**Cause:** Docker isn't installed, or `POSTGRES_PASSWORD` isn't set.
**Fix:** Docker is optional. If you use it, export `POSTGRES_PASSWORD` first (see
[`sample-app/README.md`](../sample-app/README.md)).

### T-A13 `git switch` is not a git command
**Cause:** Git older than 2.23.
**Fix:** use `git checkout -b workshop`, and upgrade Git before Module 2.

### T-A14 The baseline test count isn't 14
**Cause:** local edits, the wrong JDK, or a changed environment.
**Fix:** from `sample-app/`:
1. `git status --short` must print nothing. `git restore .` discards edits to tracked files.
2. `mvn -v` must show `Java version: 1.8.0_…` (T-A01).
3. `../scripts/verify-stage.sh 0` prints the summary line and keeps the full log in `verify-stage.log`.

If the tree is clean, the JDK is 8 and the count is still not 14, don't continue: tell the instructor,
or open an issue on the repository with the summary line and the first `[ERROR]` lines.

---

## K: Kiro

### T-K01 Steering files, custom agents or skills don't appear
**Cause:** the workspace isn't trusted, the repository root is open instead of `sample-app/`, or (for
`migration-reviewer`) its front matter is invalid.
**Fix:** open `sample-app/` (`kiro .` from that folder) and trust it. Check the agent's YAML, then start
a new session.

### T-K02 Kiro asks before every `mvn` command
**Cause:** no allow rule yet; the workspace is untrusted (Kiro then asks before every shell command); or
the saved pattern is too narrow (for example `mvn -v`).
**Fix:** trust the workspace. Choose **Always allow** with the pattern `mvn *` for this workspace, or
change the rule's pattern to `mvn *`. Never allow deploy or push.

### T-K03 No **Always allow** in the approval prompt
**Cause:** Kiro hides it when it can't verify a working saved rule.
**Fix:** choose **Allow** for now. Add `- capability: shell` / `match: ["mvn *"]` / `effect: allow` to
`~/.kiro/settings/permissions.yaml` yourself (this applies to all workspaces).

### T-K04 One command produces two approval prompts
**Cause:** compound commands (`&&`, `;`, `|`) are split and approved per part.
**Fix:** ask for single commands run from the workspace root.

### T-K05 Kiro asks before every `docker` or `curl` command
**Cause:** only `mvn *` is pre-approved.
**Fix:** choose **Always allow** with a narrow pattern, for example `docker build *`, for this workspace.

### T-K06 `#git diff` is empty, or Source Control shows no repository
**Cause:** the workspace (`sample-app/`) is a subfolder of the git repository. Kiro, like VS Code, may
offer to open the repository found in a parent folder, and the offer was dismissed.
**Fix:** accept the offer. If you dismissed it: Command Palette → **Git: Open Repository** → the
repository root, or set `git.openRepositoryInParentFolders` to `always`, then reload the window
(unconfirmed: the exact control in your build). The terminal `git` commands work either way.

### T-K07 The `pom.xml` question doesn't mention `pom-rules`
**Cause:** `pom.xml` wasn't in context, or the front matter isn't on line 1.
**Fix:** open `pom.xml` and use `#current` or `#pom.xml`; check that the file's first line is `---`.

### T-K08 No **Generate Steering Docs** button
**Cause:** a different panel state in your build.
**Fix:** click **+** in the Steering section and choose **Foundation steering files**.

### T-K09 Generated `tech.md` presents legacy patterns as conventions
**Cause:** foundation docs describe the code as it is.
**Fix:** reword them as "current state (stage 0)" (Module 1).

### T-K10 Plan started editing files
**Cause:** a plan was approved, and execution begins automatically (Plan hands off to execution).
**Fix:** stop the agent, use **Revert** or **Restore**, then check `git status` and `git restore <file>`
anything left. Keep Plan sessions unapproved.

### T-K11 Plan says it can't create `MIGRATION-NOTES.md`
**Cause:** Plan is read-only.
**Fix:** switch the session to **Default** with the agent selector (Module 1).

### T-K12 The agent selector is greyed out
**Cause:** the agent is executing a multi-step workflow.
**Fix:** wait until it's idle.

### T-K13 Kiro's inventory disagrees with your `grep`
**Cause:** the model missed or invented something.
**Fix:** trust `grep`. Correct the notes and mark the claim "unverified".

### T-K14 Hunks were applied without review
**Cause:** Autopilot is still on.
**Fix:** switch to Supervised (Module 1).

### T-K15 The verify hook never runs
**Cause:** the hook is disabled, or the work wasn't a spec task (plain chat doesn't fire `PostTaskExec`).
**Fix:** check the eye icon in the Agent Hooks panel and the Kiro output panel. Run spec tasks from
`tasks.md`.

### T-K16 The verify hook times out
**Cause:** the first build after a parent bump downloads many artifacts.
**Fix:** with no hook running, run `mvn -B clean verify` once yourself to fill the local repository,
then rerun the task.

### T-K17 The hook's build doesn't seem to include the hunks you just accepted
**Cause:** unconfirmed: in Supervised mode, when the hook runs relative to your Accept.
**Fix:** after accepting, wait for the hook, then run the count check yourself.

### T-K18 The hook ran, but the agent "didn't see" the failure
**Cause:** the hook command was edited: on failure only stderr reaches the agent.
**Fix:** the shipped hook sends the last 80 lines to stderr; restore it with
`git restore .kiro/hooks/verify-after-spec-task.json`.

### T-K19 The agent runs `mvn` itself after a task
**Cause:** the spec constraint is missing.
**Fix:** add "Do not run Maven yourself after a task; the verify hook runs it" to the spec, and wait
for the hook.

### T-K20 Tasks ran in parallel, or ahead of time
**Symptoms:** **Run all Tasks** edits `pom.xml` in parallel tasks; Module 4's task 3 ran during Part 3.
**Cause:** **Run all Tasks** runs independent tasks concurrently, in waves.
**Fix:** make the tasks a chain, or run them one at a time from `tasks.md`. Revert work that ran too
early (`git restore`, or **Restore**).

### T-K21 `#spec:<name>` finds nothing
**Cause:** Kiro named the spec folder differently.
**Fix:** run `ls .kiro/specs/` and use that name, or type `#spec`, press Enter and pick your spec.

### T-K22 `#url` fails or is very slow
**Cause:** web fetch is blocked or slow on your network.
**Fix:** paste the quote from the module's background section instead.

### T-K23 Quick Spec produced different or merged tasks
**Cause:** the model reorganized the plan.
**Fix:** edit `tasks.md` to match the module's tasks, then choose **Sync Files**.

### T-K24 The agent rewrites tests to JUnit 5, or adds `@Ignore`, in stage 1
**Cause:** out of scope for stage 1, and against `migration-standards`.
**Fix:** **Reject** the hunks; add `#steering:migration-standards.md` to your next prompt.

### T-K25 The agent edits `SecurityConfig.java` when it shouldn't
**Symptoms:** in Module 3's Jakarta rename; in Module 4.
**Cause:** a security skill's description matched the compile errors or the Boot 4 wording.
**Fix:** `git restore` the file. In Module 3, repeat with the boundary from the prompt. In Module 4 the
lambda DSL is already valid for Security 7.

### T-K26 After Module 3's task 1 the agent starts fixing compile errors
**Cause:** `verify-after-spec-task` was still enabled, or the agent went beyond the task.
**Fix:** reject the Java hunks, `git restore` the files, and disable the verify hook (Module 3).

### T-K27 The agent adds a `-classic` starter or `spring-boot-jackson2`
**Cause:** the model reaches for a bridge.
**Fix:** **Reject** the hunk (Module 4).

### T-K28 The agent is unsure about a Spring Boot 4.x detail
**Cause:** model knowledge is older than Boot 4.1.
**Fix:** give it the source:
`#url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide`.

### T-K29 `jakarta-import-guard` never reports anything
**Cause:** the hook is disabled; you edited the file yourself (file hooks fire only on agent edits); or
the file isn't `.java`.
**Fix:** check the eye icon in the Agent Hooks panel, let the agent make the edit, and read the hook log
in the Kiro output panel.

### T-K30 The guard flags a file that only uses JDK packages
**Cause:** a JDK or third-party `javax.*` package that the list doesn't account for.
**Fix:** adjust the regex in `jakarta-import-guard.json` and the skill together; never rename JDK
packages to `jakarta`.

### T-K31 A hook is in the wrong state at the start of a module
**Symptoms:** Module 4 starts with the verify hook off; someone who reset mid-module has a hook paused.
**Cause:** the step that turns it back on was skipped.
**Fix:** set both hooks as the module's "At a glance" says, with the eye icon in the Agent Hooks panel.
`../scripts/check-env.sh --stage N` shows the state stored in the hook files (the panel is
authoritative).

### T-K32 Text typed after `/skill-name` seems ignored
**Cause:** your build handles a skill slash command on its own.
**Fix:** send `/skill-name` alone first, then the prompt as the next message.

### T-K33 A skill isn't in the `/` menu, or is ignored
**Cause:** the folder name and `name` differ, the front matter isn't on line 1, or the name has invalid
characters (allowed: lowercase, digits, hyphens). This also applies to a skill inside a power.
**Fix:** fix the front matter; reload the window if it still doesn't appear.

### T-K34 **Add Custom Power** rejects the folder, or no power appears
**Cause:** you selected `powers/` or the repository root, or `plugin.json` is invalid.
**Fix:** select `powers/java-modernization`, the folder that contains `plugin.json`, then click
**Install**. Validate `plugin.json` with Module 7's check.

### T-K35 The power is never used
**Cause:** no keyword from `plugin.json` matched your wording, or the folder isn't trusted and you
dismissed the prompt.
**Fix:** rephrase with "Spring Boot 4", "Java 25", "MockitoBean" or "Jackson 3", or ask which powers it
used. Add the words developers actually use to `keywords`; trust the folder.

### T-K36 `git status` shows changes after a review
**Cause:** a shell command you approved changed a file.
**Fix:** `git diff` to inspect, `git restore <file>` to undo.

### T-K37 The reviewer ignores the migration standards
**Cause:** the `resources` lines were changed or removed.
**Fix:** restore `file://.kiro/steering/**/*.md` and `skill://.kiro/skills/*/SKILL.md`.

### T-K38 The reviewer asks before `git grep` or `mvn -B clean verify`
**Cause:** only the commands in its allow list run without a prompt.
**Fix:** approve once, or ask it to use `git show` / `git diff` and `mvn -B verify`.

### T-K39 "Use the migration-reviewer agent" fails
**Cause:** the agent name is misspelled; an unknown agent name fails rather than falling back.
**Fix:** use the exact file name without `.md`, or `/migration-reviewer`.

### T-K40 Delegation runs in the background
**Cause:** Workflows are enabled, so custom-agent delegation becomes a workflow run.
**Fix:** expected; follow it in the workflow view, or disable Workflows.

### T-K41 The Module 5 hook never fires
**Cause:** the hook is disabled (eye icon), the JSON is invalid, or the matcher doesn't match shell
tools.
**Fix:** check the Agent Hooks panel and the Kiro output panel; set `"matcher": "shell"`.

### T-K42 The Module 5 hook doesn't block, or blocks too much
**Causes:** exit 1 instead of 2, a crash, or a broader pattern. A pattern that matches something in
every payload (for example a working-directory path containing "deploy") blocks every shell command.
**Fix:** copy the reference file (`solutions/kiro-reference/hooks/block-deploy-and-push.json`), which
matches only deploy goals and `git push`, and rerun the terminal test.

### T-K43 Kiro asks before writing the hook file
**Cause:** writes to `.kiro/hooks/` always ask.
**Fix:** expected; approve it.

### T-K44 Kiro asks you to approve `echo mvn deploy`
**Cause:** `echo` is not in the default allow list.
**Fix:** choose **Allow** (not Always allow); the hook should then block it.

### T-K45 An agent command stopped with "Blocked by workspace policy"
**Cause:** the Module 5 `block-deploy-and-push` hook matched a Maven/Gradle deploy goal or `git push`.
**Fix:** working as intended: run that command yourself. For Kiro Web pull requests, see T-S01.

---

## B: Build and tests

### T-B01 `BUILD SUCCESS`, but `Tests run: 0` or no Tests run line
**Cause:** Spring Boot 2.4+ removed the JUnit Vintage engine from `spring-boot-starter-test`, so the
JUnit 4 tests silently stop running. The verify hook still passes; only the count shows it.
**Fix:** add `junit-vintage-engine` with test scope (Module 2). `../scripts/verify-stage.sh` fails this
state.

### T-B02 Tests run is lower than 14
**Cause:** a test was dropped, disabled or lost its `@Test`, or a JUnit 4 class has no engine. The verify
hook still passes in this case; only the count shows it.
**Fix:** `git diff stage-N -- src/test` against the previous stage's tag, restore the test (or migrate
it to JUnit Jupiter), and don't commit until the count matches. If the agent called the task a
success, tell it with `#spec:<your spec>` and the numbers: requirement 2 of the stage-1 spec makes a
lower count a failure.

### T-B03 `invalidUserIsRejectedByBeanValidation`: `expected:<400> but was:<201>`
**Also:** `@Valid` accepts invalid input.
**Cause:** since Spring Boot 2.3 the web starter no longer brings Bean Validation.
**Fix:** add `spring-boot-starter-validation`. Never change the test.

### T-B04 Random compile or Surefire errors that go away on a rerun, or a corrupt jar
**Cause:** two Maven builds overlapped in the shared `target/` (the hook and you, two parallel tasks, or
two reviewers).
**Fix:** wait until the agent is idle and the hook run has finished, then run `mvn -B clean verify`
once. Run tasks one at a time.

### T-B05 A trap doesn't show, or old class files survive
**Symptoms:** no Lombok error after the JDK switch; no compile errors right after a parent bump (Maven
found "nothing to compile"); no deprecation warnings; `javap` shows major version 52 on JDK 21, or 65
after the switch to Java 25.
**Cause:** incremental compilation skipped the classes.
**Fix:** keep `clean` in every build command (`mvn -B clean verify`, `mvn -B -q clean compile`), then
run `javap` again.

### T-B06 Lombok `IllegalAccessError` (`LombokProcessor` cannot access `JavacProcessingEnvironment`)
**Cause:** Lombok is pinned to 1.18.10, which can't run on JDK 16+.
**Fix:** at the baseline, build on JDK 8 and don't upgrade Lombok yourself (that is a Module 2
exercise). In Module 2, remove the Lombok `<version>`; Boot 2.7.18 manages 1.18.30. Later, remove any
`<lombok.version>` override; Boot 3.5.16 and 4.1.1 manage 1.18.46.

### T-B07 Maven can't resolve parent `2.7.18.RELEASE`
**Cause:** Spring Boot dropped the `.RELEASE` suffix in 2.4.
**Fix:** use `<version>2.7.18</version>`.

### T-B08 `package javax.validation.constraints does not exist`
**Cause:** the `validation-api` pin was removed before the validation starter was added.
**Fix:** add `spring-boot-starter-validation`.

### T-B09 `BeanCurrentlyInCreationException` at startup or in a test
**Cause:** Spring Boot 2.6+ prohibits circular references.
**Fix:** break the cycle. Use `spring.main.allow-circular-references=true` only as a temporary measure.

### T-B10 A Mockito or Hibernate error that names Byte Buddy
**Cause:** a Byte Buddy older than the JDK. Not seen with this app: stage 1 passes on Corretto 21 with
Boot 2.7.18's managed Byte Buddy 1.12.23 (2026-10-10 dry run). Later, a `byte-buddy.version` override
left over from stage 1 pins an older Byte Buddy than Spring Boot manages.
**Fix:** only on Boot 2.7, and only when the error names Byte Buddy and Java 21 ("class file version not
supported by the current version of Byte Buddy"): override `<byte-buddy.version>1.17.8</byte-buddy.version>`
(the version Boot 3.5.16 manages). Unconfirmed: 1.17.8 with Hibernate 5.6.15 at runtime; the tests
passed with it in the dry run. If `net.bytebuddy` errors follow the override, remove it and report it.
From stage 2 on, remove any override: Boot 4.1.1 manages 1.18.11.

### T-B11 `cannot find symbol` for getters, setters or constructors on JDK 25
**Cause:** since JDK 23, javac no longer runs annotation processors found only on the class path, so
Lombok never ran.
**Fix:** declare Lombok in `maven-compiler-plugin` `annotationProcessorPaths` with `${lombok.version}`
(Module 4; restore that block if a later change removed it). Don't hand-write getters or remove Lombok.

### T-B12 `validUserIsCreated`: `Status expected:<201> but was:<400>`; every create returns 400
**Cause:** after the Spring Boot 4 parent bump, Jackson 3 binds the request body through Lombok's
`@AllArgsConstructor` (the Boot parent compiles with `-parameters`) and rejects the missing primitive
`active` (`FAIL_ON_NULL_FOR_PRIMITIVES`, on by default).
**Fix:** remove `@AllArgsConstructor` from `User` (Module 4). Not a property, `Boolean active` or a
changed test body.

### T-B13 A web test gets 403 instead of 400 (or 201)
**Cause:** `@WebMvcTest` doesn't scan the plain `@Configuration` class, so default security (CSRF on)
applies; or `@Import(SecurityConfig.class)` was removed from the test.
**Fix:** add (or restore) `@Import(SecurityConfig.class)` on `UserControllerTest` (Module 3). If all web
tests pass without it, add it anyway: they also pass against Spring Boot's default security, so only
the import makes them exercise your rules.

### T-B14 `dependency:tree` or the deprecation listing prints nothing
**Cause:** `-q` hides INFO output and warnings, or incremental compilation skipped the classes.
**Fix:** run without `-q`, and keep `clean`.

### T-B15 Compile errors in files other than `SecurityConfig.java` after Module 3's rename
**Cause:** a missed import, or a JDK package renamed (for example `jakarta.sql`).
**Fix:** rerun the skill's search step; JDK packages go back to `javax`.

### T-B16 "package org.junit does not exist" after removing JUnit 4
**Cause:** a class still uses JUnit 4.
**Fix:** rerun the skill on that class.

### T-B17 Mockito "is currently self-attaching", or a Java agent was loaded dynamically
**Cause:** Mockito 5's inline mock maker attaches itself at runtime on JDK 21+.
**Fix:** expected noise, not a failure (seen in the 2026-10-10 dry run on stages 2 and 3).

### T-B18 `UnnecessaryStubbingException` after the migration
**Cause:** `MockitoExtension` uses strict stubs.
**Fix:** remove or correct the unused stub; don't make the class lenient.

### T-B19 `@WithMockUser` tests fail with 401 on Spring Boot 4
**Cause:** `spring-boot-starter-security-test` is missing.
**Fix:** add it with test scope. Per the 4.0 guide, `@WithMockUser` "now requires
spring-boot-starter-security-test".

### T-B20 `package org.springframework.boot.test.mock.mockito does not exist`
**Cause:** `@MockBean` was removed in Spring Boot 4.
**Fix:** use `@MockitoBean` from `org.springframework.test.context.bean.override.mockito` (Module 4).
A plain `grep` for `MockBean` also matches comments; use Module 4's anchored `grep -rnE`.

### T-B21 `package org.springframework.boot.test.autoconfigure.web.servlet does not exist`
**Cause:** `@WebMvcTest` moved to the modular test module.
**Fix:** import `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` and add
`spring-boot-starter-webmvc-test`.

### T-B22 `Jackson2ObjectMapperBuilderCustomizer` or `com.fasterxml.jackson.databind` can't be found
**Cause:** Jackson 3 is the default in Spring Boot 4.
**Fix:** delete `JacksonConfig` and use the two `spring.jackson.*` properties (Module 4). Don't add
`spring-boot-jackson2`.

### T-B23 The secret scan finds a literal password
**Cause:** a value was hard-coded during the migration.
**Fix:** replace it with `${ENV_VAR:}`; if it was ever real, rotate it.

---

## R: Running app

### T-R01 Port 8080 is already in use
**Cause:** another app, or an earlier run, is still running.
**Fix:** stop it (Ctrl+C in its terminal), or run `SERVER_PORT=8081 mvn spring-boot:run` (then use
`../scripts/smoke.sh --base-url http://localhost:8081`).

### T-R02 `smoke.sh` says `APP_ADMIN_PASSWORD` is not set, or the app is not reachable
**Cause:** the script reads the admin password only from the environment, and calls
`http://localhost:8080` unless you pass `--base-url`.
**Fix:** in both terminals (the one that starts the app and the one that runs the script):
`printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD`.
Then start the app and run the script again. Without the variable, the app generates a password and
logs it at startup instead.

### T-R03 An ERROR from `PropertiesMigrationListener` at startup, yet the app runs
**Cause:** expected: it lists keys that are no longer supported, such as `server.max-http-header-size`,
and doesn't map them.
**Fix:** rename the key yourself (Module 3).

### T-R04 No migrator report in `target/run.log`
**Cause:** the dependency is missing or not `runtime` scope, or you renamed the key already.
**Fix:** check `pom.xml`; the report appears only while an old key is present.

### T-R05 The invalid `POST` returns 401 on the running app
**Cause:** the error dispatch is denied (Spring Security 6 authorizes every dispatch type).
**Fix:** review the rules with the security skill's section 3; don't open `/error` to everyone without
understanding why.

### T-R06 `curl …/api/users/` (trailing slash) returns 404
**Cause:** trailing-slash matching is off by default since Spring Framework 6.0 (stage 2 on; 200 in
stages 0–1).
**Fix:** expected. Fix the client, not the server: call the path without the trailing slash.

### T-R07 Every `POST /api/users` returns 400 on stage 3
See T-B12.

### T-R08 `createdDate` is a number in the JSON
**Cause:** the ISO-8601 default doesn't apply in your setup.
**Fix:** find the matching `spring.jackson.*` key in the Spring Boot 4.1 reference and add it in a spec
task.

---

## D: Deployment (Module 6)

### T-D01 The container exits with `UnsupportedClassVersionError ... class file version 69.0`
**Cause:** the base image is older than Java 25.
**Fix:** use a Java 25 base image tag; re-check the `# VERIFY` tag.

### T-D02 `docker build` fails at `COPY ${JAR_FILE}`
**Cause:** the jar isn't built yet, the glob doesn't match, or `.dockerignore` excludes `target/*.jar`.
**Fix:** run `mvn -B clean verify` first; check `ls target/*.jar`; keep `target/*.jar` out of
`.dockerignore`.

### T-D03 The WAR deploys, but the app never starts (no Spring banner in the server log)
**Cause:** the main class doesn't extend `SpringBootServletInitializer`.
**Fix:** add the subclass and the `configure` override (Module 6).

### T-D04 The server log shows a second Tomcat starting, or port clashes
**Cause:** the embedded container is packaged in `WEB-INF/lib`.
**Fix:** make the embedded container dependency `provided`; check with `jar tf`.

### T-D05 `java -jar target/user-management.war` fails with no web server
**Cause:** the container dependency was removed instead of set to `provided`.
**Fix:** restore it with `provided` scope; Boot then packages it in `lib-provided`.

### T-D06 `NoSuchMethodError` / `ClassNotFoundException` in `jakarta.servlet` during deployment
**Cause:** the server implements Servlet 6.0 (EE 10), for example JBoss EAP 8.x or WildFly EE 10.
**Fix:** use an EE 11 server (WildFly 40+, Open Liberty `servlet-6.1`) or the executable jar or
container.

### T-D07 404 on `/api/users` after deployment
**Cause:** the app runs under a context root (the WAR name by default on many servers).
**Fix:** call `/user-management/api/users` (`../scripts/smoke.sh --base-url
http://localhost:8080/user-management`) or set the context root (unconfirmed for your server).

### T-D08 Liberty refuses to start the feature set (feature conflict in the log)
**Cause:** EE 10 and EE 11 feature versions are mixed in `server.xml`.
**Fix:** use only EE 11 features; start with `servlet-6.1` (unconfirmed: the exact message in the Liberty
log docs).

### T-D09 Garbled characters in logs or config on z/OS
**Cause:** an encoding mismatch between EBCDIC files and UTF-8 resources.
**Fix:** agree the encoding and file-tagging approach with the platform team (unconfirmed in the Semeru
for z/OS docs).

### T-D10 A `deploy-*.md` steering file is not applied
**Cause:** the front matter isn't the first bytes, or `fileMatchPattern` doesn't match the path.
**Fix:** remove leading blank lines; check the glob against the real path.

---

## S: Scale-out (Module 7)

### T-S01 Kiro Web's pull request delivery is blocked ("Blocked by workspace policy")
**Cause:** `block-deploy-and-push` is still enabled in the pushed `.kiro/` and matched a `git push`.
**Fix:** disable it as in Module 7's "Before the first Kiro Web task", push, and start a new Web
session.

### T-S02 No Workflows option
**Cause:** not enabled, no new chat session yet, or not available for your account yet.
**Fix:** IDE: Workspace Configuration → Workflows or `kiroAgent.workflows.enabled`, then a new chat
session. CLI: `/settings` → Features, then restart.

### T-S03 The sandbox lacks Java 25 or Maven, or can't download dependencies
**Cause:** runtime selection isn't documented; internet access is restricted.
**Fix:** stop. Review the environment configuration and internet access, then repeat the dry run.

### T-S04 **Import power from GitHub** fails
**Cause:** a private repository, or the URL doesn't point at the power's package root.
**Fix:** clone and import from a folder, or point the URL at the folder that contains `plugin.json`.

### T-S05 `kiro-cli: command not found`
**Cause:** after installing, the shell hasn't picked up the new `PATH`; in a later CI step, the
installer's directory isn't on `PATH` for later steps on your runner.
**Fix:** open a new terminal, then run `kiro-cli doctor`. In CI, add the directory the installer reports
to `$GITHUB_PATH` in the install step.

### T-S06 The CI step exits 1 with an authentication error
**Cause:** a missing secret, a pull request from a fork (forks don't receive repository secrets), a plan
without API keys, or API keys not enabled by the admin.
**Fix:** check the secret name, run from a branch in the same repository, and check the plan and admin
settings.

### T-S07 `kiro-cli` exit code 4
**Cause:** `--agent` names an agent that isn't available, or the configured default agent is missing.
**Fix:** check the name with `kiro-cli agent list`; drop `--agent`.

### T-S08 `kiro-cli` exit code 3
**Cause:** `--require-mcp-startup` was used and an MCP server failed.
**Fix:** fix the MCP configuration, or drop the flag if the run doesn't need MCP.

### T-S09 The report says Kiro couldn't read files or run tools
**Cause:** the tools aren't pre-approved; in headless runs every "ask" becomes "deny".
**Fix:** add the needed tools to `--trust-tools`; keep them read-only for reports.

### T-S10 The report is empty, but the exit code is 0
**Cause:** the prompt or stdin was empty.
**Fix:** run the `{ … }` block without the pipe to check what Kiro received.

### T-S11 Kiro Web isn't available
**Cause:** the Free plan, Cloud Sessions not enabled for an Identity Center organization, or the region.
**Fix:** use a paid plan; ask the admin to enable Cloud Sessions; Web runs in us-east-1.

### T-S12 The repository doesn't appear in Kiro Web
**Cause:** the Kiro Agent GitHub app isn't authorized for it, or you lack write permission.
**Fix:** update the app's repository access in GitHub; check your role.

### T-S13 `/kiro fix` does nothing
**Cause:** the comment was posted outside a review thread, or on a pull request Kiro didn't open.
**Fix:** reply inside the review thread on Kiro's pull request, or use `/kiro all`.

---

## X: Recovery

### T-X01 An agent turn went wrong
**Fix:** **Revert** (last turn) or **Restore** (checkpoint), then `git status` and `git restore <file>`.
Kiro checkpoints don't capture what shell commands such as `mvn` changed on disk, or manual edits; your
commits do (`git restore`, `git stash`).

### T-X02 A stopped workflow left half-finished edits
**Cause:** Stop doesn't undo file changes.
**Fix:** `git restore .` on the lab branch, or `git switch -` and delete the branch.

### T-X03 `git grep … stage-0` (or another tag) says "bad revision"
**Cause:** the tag is missing.
**Fix:** find the commit with `git log --oneline` and create the tag: `git tag stage-0 <commit>`.

### T-X04 You are behind, or your workspace is broken
**Fix:** reset to the reference state of the previous stage with the one procedure in
[solutions/README.md](../solutions/README.md#reset-your-workspace-to-a-stage-the-one-procedure-all-modules-use),
or `../scripts/reset-to-stage.sh N` from `sample-app/`. Your `.kiro/` folder, specs and history stay.

More: [Kiro IDE troubleshooting](https://kiro.dev/docs/ide/troubleshooting/) ·
[Kiro hooks troubleshooting](https://kiro.dev/docs/hooks/troubleshooting/)
