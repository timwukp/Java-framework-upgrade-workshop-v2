# Module 1: why and background

[← Back to the Module 1 runbook](../01-setup-and-assessment.md)

The runbook keeps only what you do and what you should see. This page holds the reasons, the
reference tables and the evidence behind each exercise. Headings match the runbook's exercises.

## 1.1 Open the chat and find the workflows

You can also open the chat from the Command Palette with **Kiro: Open Chat**.

| Built-in workflow | What it does | Where you use it |
|---|---|---|
| Spec | Requirements → design → tasks, with approval gates | Module 2 onwards |
| Quick Spec | Generates requirements, design and tasks in one pass, without approval gates | Module 3 |
| Bug Fix | Root cause → fix design → implementation (`bugfix.md`) | Module 5 |
| Plan | Read-only: explores the codebase and produces a plan without making changes | Exercises 1.11–1.14 of this module |

- The agent selector sits next to the model picker. **Built-in** lists Default, Spec, Quick Spec,
  Bug Fix and Plan.
- The IDE has **no `/spec` or `/plan` slash command** (those are CLI commands). Start Spec and Plan
  sessions from the Let's build screen or the agent selector. `/quick-spec` and `/bug-fix` do exist
  as IDE slash commands.

Docs: [Chat](https://kiro.dev/docs/ide/chat/) · [Setup](https://kiro.dev/docs/ide/setup/) ·
[Slash commands](https://kiro.dev/docs/ide/chat/slash-commands/)

## 1.2 Switch to Supervised mode

- **Autopilot** (the default): Kiro creates files, modifies code and runs commands without asking at
  each step.
- **Supervised**: Kiro yields for your approval after each turn that contains file edits. **Chat
  inline** is a conversation about that one hunk.

Why Supervised for this workshop:

- A migration edit can compile and still change behavior: a security matcher, a validation
  annotation, a test assertion. Reviewing hunks is where you catch that.
- You are here to learn what the agent does. In Supervised mode you see every change it makes.
- Rejecting one hunk now is cheaper than untangling a multi-file change later.

Autonomy is the coarse control. Permission rules (Exercises 1.6–1.7) are the fine control, and they apply in
both modes: in Autopilot, your `ask` and `deny` rules still gate commands.

Docs: [Autopilot](https://kiro.dev/docs/ide/chat/autopilot/)

## 1.3 Context providers and Cmd/Ctrl+L

| Provider | Adds | Used in this workshop for |
|---|---|---|
| `#codebase` | Relevant files found across the project | Inventories (Exercise 1.12) |
| `#file` | A specific file: type `#` and the file name, e.g. `#pom.xml` | Pinned versions (Exercise 1.12) |
| `#folder` | A folder and its contents, e.g. `#src/test/` | Test-only questions |
| `#git diff` | The current Git changes | Reviewing a stage before you commit |
| `#terminal` | Recent terminal output and command history | Feeding Maven errors to the agent |
| `#problems` | All problems in the current file | Compiler errors in the open file |
| `#url` | A web page, e.g. `#url:https://…` | Pointing at an official migration guide. If it fails or is slow (for example, web fetch is disabled on your network), paste the quoted section from the module instead. |
| `#code` | A code snippet you paste | Asking about a snippet outside the repo |
| `#repository` | A map of the repository structure | Orientation |
| `#current` | The file active in the editor | Questions about the open file |
| `#steering` | A specific steering file, e.g. `#steering:migration-standards.md` | Checking a rule |
| `#docs` | Documentation files, e.g. `#docs:<file>` | Your own docs |
| `#spec` | All files of a spec (requirements, design, tasks) | Modules 2 to 5 |
| `#mcp` | Tools, prompts and resources from an MCP server | Not used in the core labs (only Module 4's optional AWS Transform lab) |

You can combine providers in one message, for example `#codebase #pom.xml …`.

In the Exercise 1.3 check, "everything else" behind HTTP Basic includes `/api/users/**`. If the answer
claims something the code doesn't show, note it: agents can be confidently wrong.

**Cmd+Shift+L** / **Ctrl+Shift+L** starts a new session with the selection instead of adding it to
the current chat, and right-click → **Kiro > Ask Kiro** offers quick actions. The old inline
(in-editor) chat was retired in IDE 1.0.

Docs: [Chat: context providers](https://kiro.dev/docs/ide/chat/) ·
[Keyboard shortcuts](https://kiro.dev/docs/ide/editor/keyboard-shortcuts/) ·
[What's new in IDE 1.0](https://kiro.dev/docs/ide/whats-new-v1/)

## 1.4 Checkpoints and their limits

| Tool | Undoes | Does not undo |
|---|---|---|
| **Revert** (above the chat input) | The file changes of the agent's latest turn | Earlier turns, shell commands |
| **Restore** on a checkpoint marker | Agent file changes **and** Kiro's context back to that point, across several turns | Your manual edits, formatter runs, files changed by shell commands the agent ran (e.g. `mvn`), changes made by MCP tools |
| **git** (Exercise 1.8) | Anything you committed before | Nothing you didn't commit |

- If Kiro snapshotted a file and you then edit that file by hand (or run a formatter on it),
  restoring a checkpoint can lose your edits.
- Conversation "rewind" (forking the chat at an earlier turn) is a CLI feature, not an IDE one.

Docs: [Checkpoints and rewind](https://kiro.dev/docs/checkpoints/)

## 1.6 First shell command and "Always allow"

- Without any configuration, everything except workspace reads, read-only git and system-info
  commands prompts, including `mvn`.
- Skip the workflow picker in the new session; you want the Default agent.
- Kiro suggests a generalized pattern; edit it if it is narrower, such as `mvn -v`.
- If **Always allow** isn't offered, Kiro couldn't verify a working saved rule and hid the persistent
  options (see the troubleshooting details).

## 1.7 What never to pre-approve

- Permission rules live in your home directory: `~/.kiro/settings/permissions.yaml` (all workspaces)
  or `~/.kiro/workspace-roots/<hash>/permissions.yaml` (one workspace). Both are outside the repository.
- The docs are explicit: "A cloned repo cannot inject permission rules - trust is something you
  configure on your own machine." If a repository could pre-approve commands, cloning it would be
  enough to run them.
- A custom agent profile *can* carry its own rules (the reviewer agent does, see Exercise 1.15), but it only
  loads in a trusted workspace, and a `deny` in any scope always wins.
- `mvn *` also matches `mvn clean deploy`. The sample app has no deployment target; the deny rule makes
  the boundary explicit. When an unexpected command prompts, you can also choose **Always deny**.
- Compound commands (`cd x && mvn test`) are split and each part is approved separately. Ask the agent
  for single commands run from the workspace root.
- Headless runs (Module 7) treat every `ask` as `deny`, so they need explicit allow rules.

Docs: [Permissions](https://kiro.dev/docs/permissions/)

## 1.8 Git baseline: branch `workshop`, tag `stage-0`

Checkpoints don't capture files changed by shell commands or MCP tools, and Restore can't bring back
what it never captured. A commit can. After the agent's turn, `git diff` (or `#git diff` in chat)
shows exactly what changed, and `git restore <file>` undoes a file.

## Steering

| Inclusion | Loads | Reference by hand |
|---|---|---|
| `always` (the default) | In every interaction | Not needed |
| `fileMatch` + `fileMatchPattern` | When files matching the pattern are in context | Not needed |
| `manual` | Only when you reference it | `#<name>` or `/<name>` |
| `auto` + `name` + `description` | When your request matches the description | `/<name>` |

Docs: [Steering](https://kiro.dev/docs/steering/)

## 1.9 Inspect the shipped steering

| File | Inclusion | What it enforces |
|---|---|---|
| `migration-standards.md` | `always` | The four stages and their versions; one stage at a time; never invent versions; only Jakarta EE packages move to `jakarta.*`; a change is done only when `mvn -B clean verify` passes **and the test count did not go down**; no deleting or disabling tests; never two Maven builds at once |
| `pom-rules.md` | `fileMatch` on `**/pom.xml` | Bump the Boot parent first; remove `<version>` from managed dependencies; set `java.version`; confirm resolved versions with `dependency:tree` |
| `test-rules.md` | `fileMatch` on `src/test/**/*.java` | Keep every scenario; report Tests run before and after; JUnit Jupiter from stage 2; web tests keep covering auth, validation and `X-Request-Id`, and include a successful create (`validUserIsCreated`) |
| `migration-playbook.md` | `manual` | The stage-by-stage checklist, each trap with the symptom you'd see if you missed it |

These answers came from **your** steering, not from the model's own knowledge. That is the point of
steering, and also its risk: steering can be wrong too. Facts in it still need checking against the
official Spring migration guides. The `fileMatch` patterns are `**/pom.xml` (`pom-rules`) and
`src/test/**/*.java` (`test-rules`); the rule loads because the file is in context.

## 1.10 Generate foundation steering and review it critically

- Foundation files are included in every interaction by default, so a wrong line in them reaches every
  prompt for the rest of the day. Keep `tech.md` true as you go: when you commit a stage later,
  update its "current state" line.
- Kiro analyzes the repository and writes the three files to `.kiro/steering/`. Outside Supervised
  mode, open the three files to review them.
- **Versions.** `tech.md` must match `pom.xml`: Java `1.8`, Spring Boot `2.2.4.RELEASE` (which
  manages Spring Framework 5.2.3).
- **Legacy written as convention.** Generated docs describe the code as it is. If they say "use
  field injection", "write tests with JUnit 4 and `@RunWith`" or "configure security by extending
  `WebSecurityConfigurerAdapter`", they tell the agent to keep exactly what you're migrating away
  from. Reword these as "current state (stage 0)".
- **Invented facts.** Delete any CI pipeline, deployment target, team, SLA or database claim that no
  file in the repository supports.
- **Conflicts.** `migration-standards.md` owns the staged targets. Delete any other target version.
- **Secrets.** None belong in steering.
- **Length.** Shorter is better; these files are in every prompt's context.
- A file without front matter is included always.

Docs: [Steering: foundation files](https://kiro.dev/docs/steering/)

## 1.11 Start a Plan session

| Can | Can't |
|---|---|
| Read files, use code intelligence, search with grep and glob, search the web | Write files, run commands, use MCP tools |

- The agent name in the chat input shows **Plan**. The plan lives only in the conversation; nothing is
  saved to `.kiro/specs/`.
- You can answer clarifying questions in your own words too.
- After approval, Plan mode exits. Today you only assess; implementation starts in Module 2, with a
  spec.

Docs: [Plan mode](https://kiro.dev/docs/specs/plan/)

## 1.12 Inventory the migration surface

- Plan can't run commands, which is why you run every check yourself.
- Kiro's answer for prompt A should name the same files and packages; note every file it missed or
  invented.
- Modules 3 and 4 check the Spring Security "removed in" claims against the Spring Security
  migration guides.
- For prompt C, your playbook steering says the same thing about JUnit Vintage, so Kiro may be
  repeating it. The primary source is the Spring Boot 2.4 release notes. The per-file counts are 9 in
  `UserServiceTest` and 5 in `UserControllerTest`. The fifth web test, `validUserIsCreated`, posts a
  valid user whose JSON omits `active` and expects 201; it is the one that catches the Jackson 3 trap
  in Module 4.
- For prompt D, the key risk Kiro should name is that Lombok 1.18.10 can't run on JDK 16 or later.

### Running late: prompts C and D in one message

In the Plan session, **Attach first:** `#codebase` and `#pom.xml`. **Prompt**

```prompt
Which test frameworks, runners and test slices do the tests use? For each test class give its runner
annotation and the number of @Test methods. Which Spring Boot upgrade would make these tests stop
running without failing the build, and why?
Then list every explicit <version> and every property that pins a version in pom.xml. For each, say
whether the Spring Boot parent already manages that artifact, and what could break when the parent
is upgraded while the pin stays.
Mark anything you are not sure about as "unverified".
```

Run both checks (C and D) from the runbook's table afterwards.

## 1.13 Why not Java 21 right now?

- System Requirements:
  [2.2.4](https://docs.spring.io/spring-boot/docs/2.2.4.RELEASE/reference/html/getting-started.html) ·
  [2.2.13](https://docs.spring.io/spring-boot/docs/2.2.13.RELEASE/reference/html/getting-started.html) ·
  [2.7.18](https://docs.spring.io/spring-boot/docs/2.7.18/reference/html/getting-started.html).
- Java 21 is outside the 2.2 range either way.
- Verified in the 2026-10-10 dry run (Corretto 21): this baseline doesn't even compile on JDK 21. The
  Lombok 1.18.10 pin fails first, with `java.lang.IllegalAccessError: class
  lombok.javac.apt.LombokProcessor ... cannot access class
  com.sun.tools.javac.processing.JavacProcessingEnvironment`. The same pin on Boot 2.7 fails the same
  way, which is why Module 2 removes it.
- `migration-standards` tells the agent never to invent version numbers, and this is the kind of
  claim that rule exists for.

> Unconfirmed: for 2.2, the Java upper bound in the "System Requirements" section of the Spring Boot 2.2.x
> reference documentation changed across 2.2.x patch releases. Check the page for the patch version you
> care about.

## 1.14 Save the findings to `MIGRATION-NOTES.md`

Example output (yours will differ):

```text
## Baseline
- Java 1.8, Spring Boot 2.2.4.RELEASE (Spring Framework 5.2.3), Tests run: 14
## javax.* inventory
- javax.persistence: entity/User.java -> jakarta.persistence in Spring Boot 3
...
```

Supervised mode lets you check the result before it lands.

Docs: [Plan mode](https://kiro.dev/docs/specs/plan/) · [Chat: switching agents](https://kiro.dev/docs/ide/chat/)

## 1.15 The shipped hooks, reviewer and skills (look only)

### The hooks

- **Command, not agent, actions.** Command hooks run a shell command in the project root. They're
  deterministic and use no credits; agent-prompt hooks start a new agent loop and do use credits.
- **stdout on success, stderr on failure.** On a non-zero exit, Kiro sends the command's **stderr** to
  the agent; on success, stdout is added to its context. Maven prints its errors to stdout, so the hook
  captures the output, prints the `Tests run` / `BUILD` summary on stdout, and on failure copies the
  last 80 lines to stderr with `1>&2`. That is what lets a test failure reach the agent, and why the
  agent doesn't need to build again after a task.
- **`clean`.** Maven may not recompile after a JDK switch or a version bump, which would hide exactly
  the errors the later modules want you to see.
- **`timeout: 900`.** The default is 60 seconds, too short for a Maven build.
- **`PostTaskExec` only fires around spec tasks**, so it stays quiet during today's chats.
- **File hooks fire only on agent edits.** Your own saves never trigger `jakarta-import-guard`.
- **The guard is disabled** because in stages 0 and 1 `javax.*` imports are correct, so it would flag
  every file (`javax.persistence`, `javax.validation`, `javax.servlet` and similar). A `PostFileSave`
  hook can't block anything; it reports. Blocking uses exit code 2 on `PreToolUse`,
  `UserPromptSubmit` or `PreTaskExec`.
- You'll enable the guard in Module 3 with the eye icon in the Agent Hooks panel. Writes to
  `.kiro/hooks/` always ask for approval, even with allow rules.

> Unconfirmed: the docs don't say whether hook commands go through your permission rules. If they do, the
> verify hook's command (it starts with `out=$(mvn …`) may not match your `mvn *` rule from Exercise 1.6,
> and you'd see an approval prompt the first time it runs.

Docs: [Hooks](https://kiro.dev/docs/hooks/) · [Hook types](https://kiro.dev/docs/hooks/types/) ·
[Hook actions](https://kiro.dev/docs/hooks/actions/) · [Managing hooks](https://kiro.dev/docs/hooks/management/)

### The reviewer agent

- **Markdown agent.** The front matter is the configuration and the body is the system prompt. It
  appears in the agent selector under **Workspace** and as `/migration-reviewer`.
- **Permission rules.** Allowed without a prompt: `mvn -B verify`, `mvn -B -q verify`, `mvn verify`,
  `mvn -v`, `git diff`, `git status`, `git log`, `git show`. Denied: `mvn *:*` (plugin goals such as
  `versions:set`), `mvn *deploy*`, `git push`, `git commit`, `git reset`, `git checkout`,
  `git restore`, `git stash`, `rm`. Anything else prompts. A deny wins in every scope.
- **`resources`.** `file://.kiro/steering/**/*.md` and `skill://.kiro/skills/*/SKILL.md` hand it the
  steering and skills explicitly. Skills load their name and description up front and the full
  content on demand.
- **Trust.** Workspace agents load only in a trusted workspace. That's why you saw it in Exercise 1.5.
- **When you'll use it.** At the end of a stage, switch to it and ask it to review the stage's diff
  (for example `git diff stage-1..HEAD`). It should run `mvn -B verify` once and reply with a findings
  table and a "ready to commit" or "not ready" verdict. Module 5 uses it with sub-agents; when two
  reviewers run in parallel, only one of them runs Maven.

Docs: [Custom agents](https://kiro.dev/docs/custom-agents/) ·
[Creating custom agents](https://kiro.dev/docs/custom-agents/creating/) · [Skills](https://kiro.dev/docs/skills/)

## Evidence

- The 2026-10-10 dry run (Amazon Linux 2023, Corretto, Maven 3.9.11) built the baseline on Corretto 8
  with `Tests run: 14`, and showed that it doesn't compile on Corretto 21 (the Lombok 1.18.10 pin, see
  1.13). See the [verification log](../../docs/verification-log.md).
- Unconfirmed in a Kiro build: whether hook commands go through your permission rules (1.15); the exact
  control to open the parent folder's repository in Source Control (troubleshooting T-K06); the label
  of the user-level agent group (**User** or **Global**); where the Kiro output panel is.

## Docs

|---|---|
| Opening a project with `kiro .` | <https://kiro.dev/docs/getting-started/first-project/> |
| Let's build screen, built-in workflows, agent selector | <https://kiro.dev/docs/ide/setup/> · <https://kiro.dev/docs/ide/chat/> |
| Autopilot vs Supervised (`kiroAgent.agentAutonomy`) | <https://kiro.dev/docs/ide/chat/autopilot/> |
| Context providers (14) | <https://kiro.dev/docs/ide/chat/> |
| Cmd/Ctrl+L, Cmd/Ctrl+Shift+L, Cmd/Ctrl+T, Ctrl+Shift+G, Kiro > Ask Kiro | <https://kiro.dev/docs/ide/editor/keyboard-shortcuts/> · <https://kiro.dev/docs/ide/whats-new-v1/> |
| Checkpoints, Restore, Revert | <https://kiro.dev/docs/checkpoints/> |
| Workspace trust, permissions, Always allow, deny rules | <https://kiro.dev/docs/permissions/> |
| Steering (`always`, `fileMatch`, `manual`), Generate Steering Docs | <https://kiro.dev/docs/steering/> |
| Slash commands (manual steering, agents, skills) | <https://kiro.dev/docs/ide/chat/slash-commands/> |
| Plan mode | <https://kiro.dev/docs/specs/plan/> |
| Hooks (v1 JSON, `PostTaskExec`, `PostFileSave`, command actions) | <https://kiro.dev/docs/hooks/> · <https://kiro.dev/docs/hooks/types/> · <https://kiro.dev/docs/hooks/actions/> · <https://kiro.dev/docs/hooks/management/> |
| Custom agents (Markdown, tools, permissions, resources) | <https://kiro.dev/docs/custom-agents/> · <https://kiro.dev/docs/custom-agents/creating/> |
| Skills | <https://kiro.dev/docs/skills/> |
| Credits | <https://kiro.dev/pricing/> |

