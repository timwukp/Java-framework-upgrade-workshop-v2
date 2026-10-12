# Module 7: why and background

[← Back to the Module 7 runbook](../07-scale-out-cli-web.md)

The runbook keeps only what you do and what you should see. This page holds the background, the
examples and the docs. Headings match the runbook.

## A power for the migration knowledge


- **`plugin.json`** has the required fields `$schema`, `name`, `version`, `description`, `author` and
  `keywords`. Optional fields include `homepage`, `repository` and `license`.
- **`keywords`** decide when the power activates. Kiro loads a power dynamically when the keywords show
  up in your conversation, instead of loading every tool up front.
- **`skills/<name>/SKILL.md`** needs the front-matter `name` (equal to the folder name) and a
  `description`.
- **`mcp.json`** is optional, and a skills-only power is a valid shape. If a power does ship MCP
  servers, Kiro namespaces their names on install and manages them itself.
- The older `POWER.md` format still works, but new powers should use `plugin.json`.

**What doesn't go in a power.** The documented layout has no steering or hook folders. Steering, hooks
and custom agents stay in each repository's `.kiro/` (see Exercise 7.5).

Docs: [Powers](https://kiro.dev/docs/powers/) · [Create powers](https://kiro.dev/docs/powers/create/) ·
[Install powers](https://kiro.dev/docs/powers/installation/) · [Skills](https://kiro.dev/docs/skills/)

## 7.2 Import the power from a folder and test keyword activation


The content should match the skill: `@MockitoBean` from
`org.springframework.test.context.bean.override.mockito`, `JsonMapperBuilderCustomizer` for Jackson 3,
and `mvn -B verify` on JDK 25 with an unchanged "Tests run" total.

## 7.3 Extend the power and share it

### why extend it

Today the power knows stage 3 only. The stage-2 knowledge (`javax` → `jakarta`, JUnit 4 → Jupiter)
lives in this workspace's `.kiro/skills/`, so another repository can't use it yet.

### registry powers worth knowing

The [kiro.dev/powers](https://kiro.dev/powers/) registry lists two AWS-authored powers, **AWS
Transform** and **AWS Transform Agent Toolkit**.

- **AWS Transform** describes itself as covering, among other workloads, Java version upgrades. It
  drives the AWS Transform service, which needs an AWS account and IAM permissions. See the optional
  lab in [Module 4](04-spring-boot-4-java25.md) for its prerequisites and caveats.
- **AWS Transform Agent Toolkit** is for *building* agents that run in AWS Transform, not for running
  upgrades.

Install registry powers from kiro.dev/powers (**Add to Kiro**) or from the Powers panel (**+ Install**).
The docs warn that powers are third-party tools: install only from sources you trust.

## 7.A1 Give the service its own repository


CI workflows live at the repository root, and the docs describe project configuration as the `.kiro/`
folder in your repository. A root-level `.kiro/` avoids depending on undocumented subfolder behavior.

## 7.A2 Install the CLI and run it headless locally

### what the flags and exit codes mean

- `--no-interactive` takes the instruction as an argument or from piped stdin. No mid-session input
  is possible.
- `--trust-tools=read,grep` pre-approves only reading and searching, which is least privilege. In
  headless runs every action that would "ask" is denied. Kiro can't write files or run build commands
  here; only the defaults, such as workspace reads and read-only git, still work. Use
  `--trust-all-tools` only when you really want Kiro to act.
- `--v3` pins the agent harness. From Kiro CLI 2.27.1, V3 non-interactive runs also load the
  workspace's hooks. The `block-deploy-and-push` hook uses the category matcher `shell`, and V3 hooks
  match by tool category only from **Kiro CLI 2.28.0**, so the hook applies here on 2.28.0 or later
  (check with `kiro-cli --version`). It matters little in this run, because `--trust-tools=read,grep`
  already denies shell commands. A blocking hook is final.
- The hook commands themselves were verified in the 2026-10-10 dry run as plain shell commands on
  Linux, outside Kiro: the verify hook exits 0 with `Tests run: …` and `BUILD SUCCESS` on stdout, or 1
  with the last 80 lines on stderr; `block-deploy-and-push` exits 2 for deploy goals and `git push`
  and 0 otherwise. Whether `kiro-cli` runs them the same way is still unverified.
- For clean CI logs, set `KIRO_LOG_NO_COLOR=1`.

> Unconfirmed: the authentication page says an active `kiro-cli login` session takes precedence over
> `KIRO_API_KEY`, while the headless page says headless mode requires an API key. If the local run
> fails to authenticate, export `KIRO_API_KEY` (next exercise) and run it again.

**Exit codes**

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | General failure (auth error, invalid arguments, operation failed) |
| 3 | A server required by `--require-mcp-startup` did not start |
| 4 | The agent named by `--agent` (or the configured default agent) is not available |

Docs: [CLI](https://kiro.dev/docs/cli/) · [Headless mode](https://kiro.dev/docs/cli/headless/) ·
[Exit codes](https://kiro.dev/docs/reference/exit-codes/) ·
[CLI commands](https://kiro.dev/docs/reference/cli-commands/) ·
[Permissions (headless: ask = deny)](https://kiro.dev/docs/permissions/)

### Example report (yours will differ)

```markdown
# Migration readiness
1. Build: BUILD SUCCESS — Tests run: 14, Failures: 0, Errors: 0, Skipped: 0
2. Versions: Java 25, Spring Boot 4.1.x
3. Namespace: no Jakarta EE APIs imported from javax.*
4. Risky changes: none found
5. Verdict: ready — the build is green and no test count regression is visible.
```

## 7.A3 Create an API key and store it as a CI secret


- API keys belong to your user account. Credits used through the key come out of your subscription.
- Your administrator's governance rules (MCP restrictions, model access, web fetch) apply to headless
  sessions too.
- Managed subscriptions need an admin to enable API key generation first.
- Never commit the key. Rotate keys regularly and revoke unused ones in the Kiro web console.

Docs: [Authentication — API keys](https://kiro.dev/docs/getting-started/authentication/)

## 7.A4 A GitHub Actions job for a migration-readiness report


> Unconfirmed: check that `actions/setup-java` offers the `corretto` distribution with Java 25 on your
> runner before the workshop.

- **Maven is the gate, Kiro is the explainer.** If `mvn -B verify` fails, the job fails no matter
  what the report says.
- **Treat pull request content as untrusted input to the agent.** Keep `--trust-tools=read,grep` and
  `contents: read`, and give the job no write tokens.
- **Variant: reuse your reviewer.** Add `--agent migration-reviewer` to the `kiro-cli` command. Exit
  code 4 then tells you the agent wasn't found.

  > Unconfirmed: workspace agents load only in trusted workspaces, and the docs don't describe how trust
  > applies to a non-interactive CI run. Test the variant before relying on it.
- **Optional: post the report as a pull request comment** with
  `gh pr comment <number> --body-file target/kiro-readiness-report.md`. That needs
  `pull-requests: write` and `GH_TOKEN`, which widens the job's permissions; decide deliberately.

## Extra 7.B: Kiro Web (15 minutes; GitHub or GitLab and a paid plan)


- **Plans and region:** Pro, Pro+, Pro Max and Power plans; **us-east-1 only**.
- **Identity Center organizations:** an administrator must turn on **Cloud Sessions** in **Settings >
  Kiro Settings** in the AWS account where Kiro is configured.
- **Never merges:** Kiro never merges automatically; you review before anything reaches the default
  branch.
- **What it reads:** the sandbox applies the repository's `.kiro/` (steering, specs, custom agents,
  hooks, MCP servers). Your local `~/.kiro/` is not applied; supported personal configuration can be
  uploaded through **Settings > Sync**. `permissions.yaml` and interactive approvals don't apply,
  because the sandbox is the boundary.
- **Cloud session limits:** no Supervised mode, and no checkpoints or revert, so make every step end in
  a commit or pull request. You can run up to 10 cloud sessions at a time, with no separate charge for
  cloud compute.

Docs: [Kiro Web](https://kiro.dev/docs/web/) · [Cloud sessions](https://kiro.dev/docs/cloud-sessions/) ·
[Sandbox](https://kiro.dev/docs/web/sandbox/) ·
[Environment configuration](https://kiro.dev/docs/web/sandbox/environment-configuration/)

## 7.B1 Connect the repository and trial-run the sandbox


The sandbox configures itself from the build files it detects, and the manual settings cover
environment variables, internet access, Powers/MCP and AWS credentials.

## 7.B2 A migration task in the sandbox


This uses the default (interactive) mode. Kiro Web also offers Spec mode and autonomous mode (next
exercise). Custom agents can't be the *primary* agent on Web, but Kiro Web loads `.kiro/agents/` and can delegate
to them as sub-agents. That is why the prompt says "use the migration-reviewer agent".

## 7.B3 Autonomous mode and `/kiro fix`

### what autonomous mode does

   In autonomous mode the agent:
   - builds a plan with requirements and acceptance criteria;
   - delegates the work to sub-agents;
   - opens a pull request when it is done;
   - chooses the model itself;
   - moves the task to **Needs attention** if it needs an answer from you.

   It doesn't always open a pull request; some tasks end with an answer in chat.

### /kiro all, docs, and following a session from the terminal

`/kiro all` addresses every comment from every reviewer on the pull request.

Docs: [Autonomous mode](https://kiro.dev/docs/web/autonomous-mode/)

To follow a cloud session from your terminal: `kiro-cli --resume-id <session-id>`.

## Workflows


- **Fresh context per step:** each step runs in its own session and receives earlier results only
  through explicit handoffs.
- **Bundled recipes:** `investigate` (read-only investigation), `feature-pipeline` (staged feature
  delivery) and `publish-pr` (open a pull request and handle review feedback). They are examples and
  may differ between client versions, so read a recipe before running it.
- **Project recipes** live in `.kiro/workflows/`. Kiro writes them in JSON; YAML also works.
- **Starting and controlling runs:** in the IDE, ask Kiro in the parent chat; in the CLI, use
  `/workflow run`. Runs offer Pause, Resume and Stop. The CLI can also retry failed or aborted steps
  with `/workflow retry <workflowId>`.
- **Limits:**
  - Workflows don't create branches or worktrees.
  - **Stop doesn't undo file changes.**
  - A workflow uses more tokens than a single session.

Docs: [Workflows](https://kiro.dev/docs/workflows/) · [Manage workflows](https://kiro.dev/docs/workflows/manage/)

## 7.5 Draft your rollout checklist


1. **Inventory.** For each service, record:
   - build tool and Java level;
   - Spring Boot / Spring Framework version;
   - remaining Jakarta EE APIs imported from `javax.*`;
   - test framework (JUnit 4 or Jupiter) and test count;
   - packaging (JAR or WAR) and runtime (container or application server);
   - CI system and owning team.

   A deterministic per-repository probe is a good start. This example assumes Maven with the Spring
   Boot parent:

   ```bash
   mvn -q -B help:evaluate -Dexpression=project.parent.version -DforceStdout
   mvn -q -B help:evaluate -Dexpression=java.version -DforceStdout
   git grep -l -E '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])' -- '*.java' | wc -l
   ```

   You can run the Extra 7.A readiness prompt headless against each repository to collect the rest.

2. **Start with one representative service.** Choose a first service that is representative of your
   common patterns, has a usable test suite, and has an owner who can review the pull requests. Run
   the staged path on it and measure (step 7).
3. **Stages per service.** Derive each service's stops from its starting version using the same rule
   as this workshop:
   - first reach the last release line of the current major version (as 2.2 → 2.7 did here);
   - then move one major version at a time, to the latest line of the next major;
   - change the JDK only where the framework line supports it.
4. **Ship the configuration in every repository's `.kiro/`:**
   - steering (standards, playbook, pom and test rules);
   - hooks (verify after each spec task, the `javax` guard, the deploy/push guard; use the narrowed
     pattern from `solutions/kiro-reference/hooks/block-deploy-and-push.json`, which matches only
     Maven/Gradle deploy goals and `git push`);
   - the reviewer agent and the skills.

   Keep them in a template repository, copy them into each service, and review changes to them like
   code. This is what IDE, CLI and Web sessions all read. Where Kiro Web delivers pull requests,
   decide per repository whether the deploy/push guard stays on, and record the decision (Extra 7.B).
5. **Shared knowledge as a power.** Put skills that are identical everywhere into the power from
   Exercise 7.3 and version it. Install from GitHub (public) or from a cloned folder (private).
6. **Global steering for individuals.** `~/.kiro/steering/` applies to every workspace on a developer's
   machine, and workspace steering wins when the two conflict. The docs mention distributing team
   steering files to machines through MDM or Group Policy. Kiro Web doesn't read `~/.kiro/`.
7. **Metrics.** Per service and stage, track:
   - build green on the target JDK;
   - "Tests run" before and after (it must never drop);
   - reviewer blockers found;
   - regressions found after merge;
   - elapsed time per stage;
   - how many changes needed human rework;
   - Kiro credits used.

   Feed every new trap back into the steering, skills and power.
8. **Guardrails that can't travel in git.** Permission rules are per developer
   (`~/.kiro/settings/permissions.yaml` or the per-workspace file outside the repo). Document the
   "Always allow `mvn *`" step, and never pre-approve deploy or push commands.
9. **CI everywhere.** Add the Extra 7.A job, or your own equivalent: Maven as the gate, Kiro as the
   explainer, read-only tools, API keys under your admin's governance.
10. **Plans and data.**
    - Enterprise content is not used for service improvement.
    - Free-tier and individual-subscriber content may be used unless the user opts out.
    - Kiro Web runs in us-east-1.
    - API keys and Cloud Sessions may need admin enablement.

    Confirm these with whoever owns your Kiro subscription.

Docs: [Steering (global steering)](https://kiro.dev/docs/steering/) ·
[Permissions](https://kiro.dev/docs/permissions/) ·
[Data protection](https://kiro.dev/docs/privacy-and-security/data-protection/) ·
[Pricing](https://kiro.dev/pricing/)


## Docs


| Feature | Docs |
|---|---|
| Powers (Agent Plugins format, keywords, MCP namespacing) | https://kiro.dev/docs/powers/ · https://kiro.dev/docs/powers/create/ |
| Install powers (folder, GitHub, updates) | https://kiro.dev/docs/powers/installation/ |
| Powers registry | https://kiro.dev/powers/ |
| Skills | https://kiro.dev/docs/skills/ |
| Kiro CLI install and commands | https://kiro.dev/docs/cli/ · https://kiro.dev/docs/reference/cli-commands/ |
| Headless mode (`--no-interactive`, `--trust-tools`, `--v3`, hooks in V3 runs) | https://kiro.dev/docs/cli/headless/ |
| API key authentication | https://kiro.dev/docs/getting-started/authentication/ |
| Exit codes | https://kiro.dev/docs/reference/exit-codes/ |
| Permissions (headless ask = deny, per-user rules, workspace trust) | https://kiro.dev/docs/permissions/ |
| Hooks on CLI and Web surfaces | https://kiro.dev/docs/hooks/types/ |
| Kiro Web (GitHub/GitLab, us-east-1, never merges) | https://kiro.dev/docs/web/ |
| Cloud sessions (`.kiro/` applies, `~/.kiro/` doesn't, limits) | https://kiro.dev/docs/cloud-sessions/ |
| Sandbox and environment configuration | https://kiro.dev/docs/web/sandbox/ · https://kiro.dev/docs/web/sandbox/environment-configuration/ |
| Autonomous mode, `/kiro fix`, `/kiro all` | https://kiro.dev/docs/web/autonomous-mode/ |
| Custom agents as sub-agents on Web | https://kiro.dev/docs/custom-agents/ |
| Workflows (opt-in, bundled recipes, controls, limits) | https://kiro.dev/docs/workflows/ · https://kiro.dev/docs/workflows/manage/ |
| Global steering | https://kiro.dev/docs/steering/ |
| Data protection | https://kiro.dev/docs/privacy-and-security/data-protection/ |
| Plans | https://kiro.dev/pricing/ |
