# Instructor guide

## 1. What participants should leave with

- A service migrated from Java 8 / Spring Boot 2.2 to Java 25 / Spring Boot 4.1, committed stage by stage.
- The habit of **verifying** each agent change: build, test count, behavior. Not just "it compiles".
- Reusable assets: steering, hooks, skills, a reviewer agent and a power that they can take to their own
  repositories.

## 2. Dry run (do this a few days before, on the same network participants will use)

The migration content was written against official sources, but parts of it can only be confirmed by
running it. Work through this list on **macOS and on Linux** (the two supported platforms), and fix the
material where reality differs. The build and test items marked done were covered on Linux by the
2026-10-10 EC2 dry run (Amazon Linux 2023, Corretto 8 / 21 / 25, Maven 3.9.11); details in the
[verification log](verification-log.md). Nothing inside Kiro was covered.

**Builds** (always `clean`; Maven may skip the recompile after a JDK or version change)
- [x] `sample-app/` on **JDK 8**: `mvn -B clean verify` ends with `Tests run: 14` and `BUILD SUCCESS`.
  Covered: [2026-10-10 EC2 dry run](verification-log.md).
- [x] `solutions/stage-1-boot27-java21/` passes on **JDK 21** without a `byte-buddy.version` override,
  so Module 2 teaches the override as troubleshooting only. Covered: [2026-10-10 EC2 dry run](verification-log.md).
- [x] `solutions/stage-2-boot35-java21/` passes on **JDK 21**; without `@Import(SecurityConfig.class)`
  in `UserControllerTest`, the invalid-input test gets 403 instead of 400. Covered:
  [2026-10-10 EC2 dry run](verification-log.md).
- [x] `solutions/stage-3-boot41-java25/` passes on **JDK 25**; without the Lombok
  `annotationProcessorPaths` entry it fails with the `cannot find symbol` error Module 4 teaches
  (since JDK 23, javac no longer runs class-path annotation processors). Covered:
  [2026-10-10 EC2 dry run](verification-log.md).
- [x] The JDK 25 fallback: stage 3 also passes on **JDK 21** with `-Djava.version=21`. Covered:
  [2026-10-10 EC2 dry run](verification-log.md).
- [x] Every stage reports the same total: 14 tests (9 service + 5 web). Covered:
  [2026-10-10 EC2 dry run](verification-log.md).
- [x] The traps reproduce as the modules describe them: the Module 2 chain (`Tests run: 0`, then
  400 vs 201), the properties-migrator ERROR report, and the Jackson 3 400 (`validUserIsCreated` fails
  when `@AllArgsConstructor` is back on `User`). Covered: [2026-10-10 EC2 dry run](verification-log.md).
- [x] The running app at every stage: 401 / 200 / 400 / 201 / 404, `X-Request-Id`, ISO-8601 dates;
  `GET /api/users/` (trailing slash) 200 in stages 0–1, 404 from stage 2. Covered:
  [2026-10-10 EC2 dry run](verification-log.md).
- [x] [Participant setup, section 7](participant-setup.md#7-pre-download-the-dependencies-for-every-stage):
  every command succeeds and the cache check lists the four Spring Boot versions. Covered:
  [2026-10-10 EC2 dry run](verification-log.md).
- [ ] Repeat the build items once on **macOS**; the dry run was Linux only.
- [ ] Time section 7 on an empty `~/.m2` on the training network.
- [ ] Maven Central (or your internal mirror) is reachable from the training network. Corporate proxies are the most common blocker.

**Kiro** (all open; the dry run ran the hook commands only as plain shell commands, outside Kiro)
- [ ] Kiro IDE version: note it in the agenda. UI labels in the modules come from the docs as of
  2026-10-09; screenshot any that differ.
- [ ] Start Kiro with `kiro .` from a JDK 8 terminal in `sample-app/`, trust the workspace, and confirm
  the four steering files, two hooks (`verify-after-spec-task` on, `jakarta-import-guard` off), the
  `migration-reviewer` agent and both skills are listed. Record how participants put the `kiro`
  command on their PATH on macOS and Linux (setup marks it "Verify").
- [ ] `sample-app/` is a subfolder of the git repository. Check that Source Control and `#git diff`
  find the repository, and how to recover if the "open the parent repository" prompt was dismissed
  (Source Control view or a Command Palette action). Record the exact steps for Module 1.
- [ ] Agent JDK: the agent's `mvn -v` after starting with `kiro .`, and after a JDK switch plus
  restart. Also once after starting Kiro from the Dock or a launcher, so you recognise the symptom.
- [ ] **Hook JDK probe.** Temporarily set the `verify-after-spec-task` command to
  `java -version 1>&2; mvn -v 1>&2; exit 1`, run one spec task, and read the versions the agent
  receives (stop the agent if it starts "fixing" the failure). Repeat after a JDK switch and a
  `kiro .` restart. Restore the file with
  `git restore .kiro/hooks/verify-after-spec-task.json`. Result: ______
- [ ] **Hook timing in Supervised mode.** Does `PostTaskExec` run before or after you accept the
  task's hunks? Run a task, wait a minute before **Accept**, and watch the Kiro output panel. Module 2's
  key moment (the hook catching the `@Valid` failure) depends on it. Result: ______
- [ ] **Do hook commands go through permission prompts?** In Autopilot with the guard enabled, let the
  agent save a Java file; with the Module 5 hook installed, let the agent run a shell command. If either
  raises an approval, add "Always allow" steps for the exact hook commands to Module 3 Exercise 1.3 and
  Module 5 Exercise 5.3. Result: ______
- [ ] Run one spec task: the hook runs one `mvn -B clean verify`; on success the agent quotes the
  `Tests run` line, on failure it gets the last 80 lines. Note how the output panel shows that the hook
  has finished; participants wait for that before they run Maven themselves.
- [ ] Enable `jakarta-import-guard` and save a file with a `javax.persistence` import through the agent;
  confirm the agent is told about it.
- [ ] Module 5 hook (`solutions/kiro-reference/hooks/block-deploy-and-push.json`): `echo mvn deploy`
  is blocked (possibly after an approval prompt for `echo`), and `mvn -B verify` is not.
- [ ] One `migration-reviewer` review, then `git status` is clean. Rehearse the Module 5 Bugfix demo
  (CSRF regression, verify hook paused, then re-enabled) in 5 minutes.
- [ ] Import `powers/java-modernization/` via **Add Custom Power → Import power from a folder →
  Install**.
- [ ] Run the [reset procedure](../solutions/README.md) for each row, including the JDK switch, the
  Kiro restart and the hook states, and check `git tag -n1 -l "stage-*"`.
- [ ] Check where the workspace trust prompt appears, and how to trust a workspace after dismissing it.
- [ ] **Time every module with a fresh account**, demos included, and write the times next to the
  pacing checkpoints in section 5.
- [ ] Credits: note the credits each module used (section 3).
- [ ] Optional labs: Module 4 appendix (AWS sandbox account), Kiro CLI headless (an API key on a paid plan), Kiro Web (a GitHub/GitLab repository and the cloud sandbox).

## 3. Accounts and plans

- The Free plan includes 50 credits per month, which is not enough for a full hands-on day. Plan for
  paid individual plans, or enterprise seats through IAM Identity Center / an external identity provider.
  See [Pricing](https://kiro.dev/pricing/) and the *Enterprise* section of the [Kiro docs](https://kiro.dev/docs/).
- Kiro publishes no per-module figure. Fill in your own from the dry run and share it at 09:00, saying
  it's your measurement:

  | Module | 1 | 2 | 3 | 4 | 5 | Day |
  |---|---|---|---|---|---|---|
  | Credits in the dry run (model: ____) | | | | | | |

- Regulated organizations: review [Data protection](https://kiro.dev/docs/privacy-and-security/data-protection/)
  with the participants' security team before the day. The rules differ between enterprise and
  individual tiers.
- Recommend one model for everyone (for example Auto) so credit usage and behavior are comparable.

## 4. Run of show

Every demo is **inside** the module's time box and takes at most 5 minutes.

| Time | What you do | What participants do |
|---|---|---|
| 09:00 | Frame the day: staged migration, why Kiro has no magic upgrade button, how verification works. Run the pre-flight check (section 5) | Pre-flight check |
| 09:15 | Module 1, Exercises 1.1–1.4 demo: Plan workflow with `#codebase`; Supervised mode; checkpoint vs git | Module 1 |
| 10:30 | Module 2, Exercises 2.2–2.3 demo: create the stage-1 spec and review the requirements together before any task runs | Module 2 |
| 13:00 | Module 3 demo: the guard hook catching a `javax` import; skill activation | Module 3 |
| 15:00 | Module 4, Part 1 demo: import the power (this is also Exercise 1.2's fallback); a Plan session for Boot 4 | Module 4 |
| 16:35 | Module 5, Part 3 demo: Bugfix spec on the CSRF regression, with `verify-after-spec-task` paused and then re-enabled | Module 5 |
| 16:50 | Retrospective: which traps did the build catch, which did only the test count catch? | — |

Facilitation tips:
- Ask participants to keep **Supervised** mode on and to reject at least one hunk per module. The point
  is reviewing agent output, not watching it. The one deliberate exception is Module 3, Part 3: the
  mechanical `javax` → `jakarta` rename runs in Autopilot, with the compiler, the guard hook and git as
  the safety net. Switch back to Supervised for the security and test changes.
- Every time a module says "record the test count", check a few screens. The expected number is 14,
  but participants read their own. The silent traps (validation, Vintage engine) are only visible this
  way.
- Agents vary. Two participants with the same prompt will get different diffs; compare a few in the
  room. Agent wording is model-dependent; if the agent doesn't quote a hook's output, read the Kiro
  output panel.

## 5. Room control

### Pre-flight check (09:00, during the welcome)

Everyone runs this from `sample-app/` in Kiro's terminal and raises a hand if anything differs:

```bash
../scripts/check-env.sh
../scripts/verify-stage.sh 0
```

`check-env.sh` covers the tools, the JDK of the terminal and of Maven, the Maven cache and the
workspace files; `verify-stage.sh 0` builds once and passes only with `Tests run: 14`. Without the
scripts: `mvn -v`, `mvn -B clean verify | tail -n 15`,
`ls ~/.m2/repository/org/springframework/boot/spring-boot/` and
`python3 --version && curl --version | head -n 1`.

- [ ] `mvn -v`: Maven 3.9+ and `Java version: 1.8.0_…`.
- [ ] `Tests run: 14` and `BUILD SUCCESS`.
- [ ] The cache lists `2.2.4.RELEASE`, `2.7.18`, `3.5.16` and `4.1.1`.
- [ ] Kiro is signed in and was started from that JDK 8 terminal with `kiro .`. The workspace is
  `sample-app/` (not the repository root) and trusted. The Kiro panel shows four steering files and two
  hooks (`verify-after-spec-task` on, `jakarta-import-guard` off); `/` lists `migration-reviewer` and
  both skills.
- [ ] A paid plan or an organization seat; the subscription dashboard shows credits remaining.

A helper fixes failures during Module 1, Exercises 1.1–1.4. Someone with an empty cache starts the
[section 7](participant-setup.md#7-pre-download-the-dependencies-for-every-stage) commands now; they
build in the `solutions/` folders, not in `sample-app/target/`.

### Pacing checkpoints

Move the times if your dry run says so. At the start of every module, anyone without the previous
stage's tag resets before the first exercise.

| Module | By then, be at | If not |
|---|---|---|
| 1 (09:15–10:15) | **09:40:** Exercise 1.9, with branch `workshop` and tag `stage-0` | Module 1 changes no code, so nothing to reset: do Exercise 1.8 now, then apply the module's cuts. Nobody leaves Module 1 without `stage-0`. |
| 2 (10:30–12:00) | **11:25:** Exercise 2.10 (Switch the JDK) | Still in Exercise 2.7 (`@Valid`) or earlier: reset to stage 1 (row "Module 3"), then do only step 2 of Finish. |
| 3 (13:00–14:45) | **14:10:** Exercise 5.1 (Write the skill), compiling, 14 tests on the Vintage engine | Still in Part 4: copy the reference skill (the Exercise 5.1 fallback). Not green with 14 tests by 14:35: reset to stage 2 (row "Module 4") in the break. |
| 4 (15:00–16:20) | **15:50:** Exercise 4.1 (Switch to JDK 25 and restart Kiro) | Exercise 3.4 not green with 14 tests by 16:00: reset to stage 3 (row "Module 5") instead of finishing Part 4. |
| 5 (16:20–16:50) | **16:40:** everyone starts Exercise 5.4 (final verification), wherever they are | `mvn -B clean verify` not green: reset to stage 3 first. Part 2 and the Bugfix lab wait until after the day. |

### Announcements: hooks, JDK switches, Kiro restarts

| When | Say to the room |
|---|---|
| 09:00 | Hooks: `verify-after-spec-task` on, `jakarta-import-guard` off. Leave them until a module says otherwise. |
| ~10:55, Module 2 Exercise 2.6 (first spec task) | One build at a time. After a task, read the hook's result in the Kiro output, or run Maven yourself only after the hook has finished (builds share `target/`). |
| ~11:25, Module 2 Exercise 2.10 | JDK 21: make it the default, **quit Kiro**, start it from a new terminal with `kiro .`, check the agent's `mvn -v`. |
| ~13:07, Module 3 Exercise 1.3 | Enable `jakarta-import-guard`. It stays on for the rest of the day. |
| ~13:10, Module 3 Exercise 2.1 | Pause `verify-after-spec-task`: the build is red on purpose until Exercise 4.3. |
| ~13:23, Module 3 Part 3 | Autopilot only for the mechanical rename (Exercises 3.2–3.3); back to Supervised in Exercise 3.4. |
| ~14:05, Module 3 Exercise 4.3 | Re-enable `verify-after-spec-task`. Check a few Agent Hooks panels. |
| 15:00, Module 4 start | Both hooks on? Anyone who reset in the middle of Module 3 may still have the verify hook paused. |
| ~15:50, Module 4 Exercise 4.1 | JDK 25: make it the default, **quit Kiro**, `kiro .`, check the agent's `mvn -v`. |
| ~16:28, Module 5 Exercise 5.3 | If Kiro asks to approve `echo mvn deploy`, choose **Allow**, not Always allow. |
| 16:35, Module 5 Part 3 (you) | Pause `verify-after-spec-task` before the Bugfix demo and re-enable it after. Anyone doing the lab later does the same. |
| After any reset | The row's JDK, a Kiro restart with `kiro .`, and the row's hook states. |

### When credits or a seat run out

- Pair the participant with a neighbour: one drives, both review the hunks.
- Or they follow your screen for the rest of the module and reset to the next stage at the start of the
  next module, on a working seat.
- If their plan allows it, a model with a lower multiplier than Auto (1.0x) stretches what's left.
- Keep one or two spare seats if the organization can provide them. Don't debug billing during a
  module; sort it out in the break.

## 6. Reset points

Use only the procedure in [solutions/README.md](../solutions/README.md) ("Reset your workspace to a
stage"), run from `sample-app/`. It commits the participant's work, copies the reference `pom.xml` and
`src/`, switches the JDK and restarts Kiro, builds, tags the stage, and sets the hook states. Their
`.kiro/` folder and specs stay in place.

## 7. Troubleshooting

The complete list, by symptom, is [troubleshooting.md](troubleshooting.md). The most common in the room:

| Symptom | Likely cause | Fix |
|---|---|---|
| Steering, agents or skills don't appear | Workspace not trusted, or the repository root was opened instead of `sample-app/` | Open `sample-app/` and trust it |
| Every `mvn` command asks for approval | No allow rule yet | Choose "Always allow" with pattern `mvn *` for this workspace. Never allow deploy or push |
| The agent's or the hook's Java version is wrong | Kiro was started before the JDK changed, or from the Dock | Quit Kiro and start it from a terminal with the right JDK with `kiro .` |
| Hook ran but the agent "didn't see" the failure | The command was edited: only stderr reaches the agent on failure | The shipped hook sends the last 80 lines to stderr; restore it with `git restore .kiro/hooks/verify-after-spec-task.json` |
| Random compile or Surefire errors, a corrupt jar | Two Maven builds at once in `target/` (the hook and the participant, two parallel tasks, or two reviewers) | Wait for the hook to finish, then run `mvn -B clean verify` once |
| A trap doesn't show (no Lombok error after the JDK switch, no compile errors after a bump) | Incremental compile skipped the classes | Use `clean` (`mvn -B clean compile` / `clean verify`) |
| Build green, fewer tests ran | JUnit Vintage engine missing (Boot 2.4+). The hook still passes; only the count shows it | See Module 2 |
| `@Valid` accepts invalid input | `spring-boot-starter-validation` missing (Boot 2.3+) | See Module 2 |
| Mockito or Hibernate errors that name Byte Buddy and Java 21 | Byte Buddy older than the JDK. Not seen with this app: stage 1 passes on Corretto 21 without an override (2026-10-10 dry run) | Troubleshooting only, on Boot 2.7: override `byte-buddy.version` (for example 1.17.8, the version Boot 3.5.16 manages). Later stages use the Boot-managed version |
| Missing getters (`cannot find symbol`) on JDK 25 | Since JDK 23, javac no longer runs annotation processors found only on the class path | Declare Lombok in `maven-compiler-plugin` `annotationProcessorPaths` (Module 4, Part 4) |
| Every POST returns 400 after the Boot 4 parent bump; `validUserIsCreated` fails with 400 instead of 201 | Jackson 3 binds the body through Lombok's `@AllArgsConstructor` and rejects the missing primitive `active` | Remove `@AllArgsConstructor` from `User` (Module 4) |
| Web test returns 403 after the security migration | `@WebMvcTest` didn't load the `SecurityFilterChain` configuration | `@Import(SecurityConfig.class)` |
| `mvn -v` shows the wrong Java | `JAVA_HOME` not switched | See [participant-setup.md](participant-setup.md#switch-the-jdk-per-terminal) |
| Agent restored a checkpoint but Maven-generated changes remain | Checkpoints don't capture shell commands | Use `git restore` / `git stash` |
| Credits run out mid-day | Plan too small | See "When credits or a seat run out" (section 5) |

## 8. Confidentiality when adapting this workshop

When you tailor the material for a specific organization, keep that organization's details out of
anything that might be published: system names, platform codenames, application counts, rollout plans,
dates, internal hostnames and people's names. Put them in a private fork or in speaker notes.
