# Module 4 appendix (optional, outside the 80 minutes): accelerators

[← Module 4](04-spring-boot-4-java25.md) · [Day sheet](../docs/quick-reference.md) · [Troubleshooting](../docs/troubleshooting.md)

Kiro has no built-in "upgrade Java" transformation; you just did the upgrade with a spec and the
agent. Deterministic tools can do the bulk mechanical part on large codebases. You still review
their output exactly as you reviewed the agent's. This appendix runs each tool on a **throwaway
branch** created from `stage-2`, and compares the result with your stage 3. Do it after the workshop
day, or in a follow-up session.

**Prerequisites for the appendix** (none of these are in the participant setup):

- Tag `stage-3` exists (Module 4, Finish), and the tree is clean on `workshop`.
- At least 30 minutes. A transformation run can take longer.
- For the AWS Transform power (Exercises A.1 and A.2):
  - An AWS **sandbox** account that your security team has approved, with the
    `AWSTransformCustomFullAccess` managed policy on your IAM user or role.
  - AWS CLI v2 with working credentials, and a supported region (Exercise A.1).
  - The `atx` CLI, Node.js 22+ and Git.
  - uv/uvx and Python 3.10+ for the power's MCP server.
  - macOS or Linux. (The power's steering asks Windows users for WSL, which this workshop hasn't
    tested.)
- For OpenRewrite (Exercise A.3): Code Genome Project credentials (a download token), and your legal
  team's view on the recipe licences.

> **Commit before running either tool.** Both tools change files through shell commands, and Kiro's
> checkpoints don't capture "file changes made by MCP tools or bash commands". Restore can't undo
> them, but git can.

```bash
git status
git log --oneline -1
```

Look for: a clean tree on `workshop`, with your stage-3 commit on top.

## Exercise A.1: Before you start, data handling and prerequisites

**Goal:** decide whether you may run AWS Transform at all, and with which account.

**What it can do.** The AWS Transform power wraps the AWS Transform custom CLI (`atx`). The CLI runs
AWS-managed transformation definitions on your local repository: `AWS/java-version-upgrade` and
`AWS/spring-boot-version-upgrade` (Spring Boot 3.x → 4.x, targeting 4.1.0).

<details><summary>Background: the two AWS-managed transformations (verbatim from the AWS catalog)</summary>

From [AWS-managed transformations](https://docs.aws.amazon.com/transform/latest/userguide/transform-aws-customs.html):

| Transformation | Status | Scope (verbatim) |
|---|---|---|
| `AWS/java-version-upgrade` | Generally available | "Upgrade Java applications using any build system from any source JDK version to any target JDK version, with dependency modernization including Jakarta EE migration, database drivers, ORM frameworks, and Spring ecosystem updates." |
| `AWS/spring-boot-version-upgrade` | Generally available | "Migrate Spring Boot 3.x projects to Spring Boot 4.x (targeting 4.1.0 GA)." It "Covers version upgrades, starter renames, Jackson 3 migration, Spring Security 7 DSL, @MockBean removal, property renames, package relocations, observability consolidation". |

</details>

**What it can't do:**

- The catalog has **no Spring Boot 2.x → 3.x transformation**.
  - `java-version-upgrade` mentions "Jakarta EE migration" and "Spring ecosystem updates". Whether it
    performs a full Boot 2 → 3 jump is untested.
  - That's one reason Modules 2 and 3 are Kiro-native.
- The Spring Boot transformation targets 4.1.0, so expect to bump to 4.1.1 yourself.
- Names change over time. The power's own reference says its table is "NOT a substitute for
  `atx custom def list --json`".

> **Data handling: read this before you install anything, especially in a regulated enterprise.**
>
> - **Your code goes to an AWS service.** "AWS Transform stores your questions, its responses, and
>   additional context, such as console metadata and code in your IDE, to generate responses to your
>   questions." ([Data protection](https://docs.aws.amazon.com/transform/latest/userguide/data-protection.html))
>   "Local mode" means the CLI runs on your machine. It still needs the
>   `transform-custom.<region>.api.aws` and `*.s3.amazonaws.com` endpoints.
> - **Content may be used for model training.** "AWS Transform may use this content, for example, to
>   provide better responses to common questions, fix AWS Transform operational issues, for
>   de-bugging, or for model training." This includes "the responses and code that AWS Transform
>   generates". The opt-out is organization-wide: "For AWS Transform configure an AI services opt-out
>   policy in AWS Organizations."
>   ([Service improvement](https://docs.aws.amazon.com/transform/latest/userguide/service-improvement.html))
>   If your organization has no such policy, assume the opt-out doesn't apply.
> - **Learning is on by default.** "By default, AWS Transform custom extracts lessons from every
>   transformation execution." The per-run opt-out is `-d` / `--do-not-learn`. The command the power
>   builds doesn't include it, so ask for it.
> - **Telemetry is on by default.** The power's steering says it "collects usage telemetry by default
>   during transformation execution". It always adds `--telemetry`. You can opt out by asking in chat,
>   but only for that session; "This preference is not persisted".
> - **`-t` bypasses guardrails.** The power runs `atx custom def exec … -x -t`. Per the docs, "The `-t`
>   or `--trust-all-tools` flag automatically approves all tool executions without prompting and
>   bypasses most security guardrails". They add: "Use with caution in production environments."
>   ([Custom workflows](https://docs.aws.amazon.com/transform/latest/userguide/custom-workflows.html))
> - **Where data is stored.** "your data is stored in the AWS Region where your AWS Transform profile
>   was created". With cross-region inference, requests "may be processed in a different Region within
>   the geography".
> - **Two services, two sets of terms.** Your prompts go to Kiro under Kiro's
>   [data-protection terms](https://kiro.dev/docs/privacy-and-security/data-protection/). Your code
>   goes to AWS Transform under your AWS account's terms.
>
> **Recommendation:**
> - Use a **sandbox AWS account** that your security team has approved, and only this sample app.
> - Never use a production account or your company's code in a workshop.
> - Work on a throwaway branch.

**Prerequisites** ([Getting started](https://docs.aws.amazon.com/transform/latest/userguide/custom-get-started.html)):

| Item | Requirement |
|---|---|
| AWS credentials | `aws sts get-caller-identity` succeeds. The AWS CLI v2 is installed. |
| IAM | "We recommend attaching the AWSTransformCustomFullAccess AWS managed policy to your IAM user or role." SSO users need an administrator to add it to their IAM Identity Center permission set. |
| Region | One of us-east-1, eu-central-1, eu-west-2, ca-central-1, ap-northeast-1, ap-northeast-2, ap-southeast-2, ap-south-1. Without configuration it falls back to us-east-1. |
| `atx` CLI | Install it with `curl -fsSL https://transform-cli.awsstatic.com/install.sh \| bash` (Windows PowerShell: `irm https://transform-cli.awsstatic.com/install.ps1 \| iex`). The power can also install or update it. |
| Node.js 22+ and Git | Required by the CLI. "the working directory needs to be a valid Git repo". |
| uv/uvx and Python 3.10+ | For the power's MCP server, which `mcp.json` starts with `uvx`. |
| OS | The docs support native Windows, but the power's steering asks Windows users for WSL. Use macOS, Linux or WSL. |
| Cost | Billed in Agent Minutes, which "reflect active agent work time, not wall clock time". `--limit` caps a session. Neither the power nor this workshop quotes prices; see [AWS Transform pricing](https://aws.amazon.com/transform/pricing/). |

**Verify**

```bash
aws --version
aws sts get-caller-identity
aws configure get region
atx --version
node --version
uv --version
python3 --version
```

Look for:

- Your sandbox account ID.
- A supported region.
- Node 22 or later and Python 3.10 or later.

If any check fails, do Exercise A.3 (or just read it) instead.

## Exercise A.2: Run the Spring Boot transformation on a throwaway branch

**Goal:** see what a deterministic transformation produces for the same hop, and compare it with your
stage 3.

**Steps**

1. Create the lab branch from `stage-2`. Keep the power's `.atx/` state folder out of git with a
   local-only ignore rule:

   ```bash
   git switch -c lab/aws-transform stage-2
   echo ".atx/" >> "$(git rev-parse --git-dir)/info/exclude"
   git status
   ```

2. Install the power. Per the AWS docs: "Open Kiro IDE and navigate to the Powers panel. Find **AWS
   Transform** in the list and install it. Open Kiro Chat, click on the Power, and select **Try
   power**." Alternatives:
   - **Add Custom Power** → **Import power from GitHub** with
     `https://github.com/kirodotdev/powers/tree/main/aws-transform`.
   - **Add to Kiro** on [kiro.dev/powers](https://kiro.dev/powers/).
3. Notice the format. This power uses the legacy `POWER.md` format with an `mcp.json`, so its MCP
   server is registered in your user MCP config:

   ```bash
   grep -n "aws-transform" ~/.kiro/settings/mcp.json
   ```

   For Java upgrades, the power drives the `atx` CLI through shell commands. The MCP server serves
   other AWS Transform workloads.
4. Send prompt A. The power checks prerequisites and runs `atx update` and `atx custom def list`. Each
   command asks for approval:
   - Choose **Allow** for each one.
   - **Don't** choose **Always allow** for `atx` commands. `atx custom def exec … -t` changes code with
     guardrails bypassed, and you want to see each run before it starts.
5. Send prompt B. The power shows a match report and the command, and asks for plan context. Per its
   steering, it doesn't start "without explicit user consent". Confirm only if the command matches
   what you asked for. If it asks about the JDK, JDK 21 and 25 are both installed. It asks before
   installing a runtime.
6. While it runs, the power commits each step. Watch Source Control or `git log`.

**Ask Kiro (prompt A)**

```text
Set up AWS Transform custom and show me the transformations available for this repository. Do not start any transformation.
```

**Ask Kiro (prompt B)**

```text
Upgrade this repository from Spring Boot 3.5 to Spring Boot 4.1 with the AWS/spring-boot-version-upgrade transformation, in local mode, on the current branch. Plan context: Target Spring Boot 4.1.1 and keep Java 21. Do not send telemetry in this session. Pass --do-not-learn and --limit <budget>. Show me the exact atx command and wait for my confirmation before you run it.
```

Replace `<budget>` with the number of Agent Minutes you are willing to spend. Avoid commas in the plan
context; the power's troubleshooting notes warn against them.

> Verify: whether the power passes `--do-not-learn` and `--limit` when asked. Check the command it
> shows you before you confirm. The docs document both flags for the CLI. They don't say whether the
> power honours the request.

**Verify**

```bash
git log --format='%h %an %s' stage-2..HEAD
grep -n -A2 "<artifactId>spring-boot-starter-parent</artifactId>" pom.xml
git diff --stat workshop -- pom.xml src
mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
git status --short
```

Look for:

- Checkpoint commits by `ATX Bot`, the documented default author when the CLI's author variables
  aren't set.
- The parent version. 4.1.0 is what the catalog targets, so bump it if you compare with 4.1.1.
- The files that differ from your stage 3 on `workshop`.
- The test count (14). If `validUserIsCreated` fails with 400, the transformation kept
  `@AllArgsConstructor` on `User`: the Jackson 3 trap from Module 4, Exercise 4.9.
- Any untracked files, for example a `.kiro/specs/aws-transform/` folder that the power's generic
  flow can create.

Then ask Kiro (Default agent) to compare. Run `git diff workshop -- pom.xml src` in the terminal first,
so the diff is in `#terminal`:

```text
#terminal This diff compares the AWS Transform result (working tree) with my stage 3 on the workshop branch. List, as a table, what the transformation did differently: dependencies, imports, Jackson configuration, security, tests. Mark each difference as "equivalent", "worse" or "better" and explain why. Do not change any files.
```

**Clean up**

```bash
git switch workshop
git branch -D lab/aws-transform
```

Keep the branch instead if you want to compare later.

**Checkpoint:** nothing from the lab lands on `workshop`.

Docs: [Powers registry](https://kiro.dev/powers/) · [Install powers](https://kiro.dev/docs/powers/installation/) ·
[MCP configuration](https://kiro.dev/docs/mcp/configuration/) · [Permissions](https://kiro.dev/docs/permissions/) ·
[AWS Transform developer tools](https://docs.aws.amazon.com/transform/latest/userguide/developer-tools.html)

## Exercise A.3: OpenRewrite as an alternative accelerator (read it; run it only with access)

**Goal:** know the recipes, how to run them, and the licensing and distribution terms that decide
whether you may.

**The recipes** (from the recipe pages on [docs.openrewrite.org](https://docs.openrewrite.org/), checked
2026-10-09)

| Recipe | What it does |
|---|---|
| `org.openrewrite.java.migrate.UpgradeToJava25` (artifact `org.openrewrite.recipe:rewrite-migrate-java`) | "This recipe will apply changes commonly needed when migrating to Java 25." It also replaces deprecated APIs and updates build files and plugins. Its list starts with "Migrate to Java 21" and includes "Remove Security SecurityManager". |
| `org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_5` | "Migrate to Spring Boot 3.5 (Community Edition)". It's the first recipe in the Boot 4.0 recipe's list. Use it on its own to bring an older service to 3.5 before the Boot 4 jump. |
| `org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0` (artifact `org.openrewrite.recipe:rewrite-spring`) | "Migrate to Spring Boot 4.0 (Community Edition)". Its list includes "Migrate to Spring Framework 7.0", "Migrate to Spring Security 7.0", "Replace @MockBean and @SpyBean", "Migrate to Spring Boot 4.0 modular starters (Community Edition)", a `spring-boot-starter-web` → `spring-boot-starter-webmvc` change, and "Migrate to Hibernate 7.1.x (Community Edition)". |

Things to notice:

- The Boot 4 recipe sets versions to `newVersion: 4.0.x`, not 4.1.x. After it runs, you still bump the
  parent to 4.1.1. 4.1.1 also manages a newer Hibernate (7.4.5) than the recipe's 7.1 migration.
- The Java 25 recipe's examples change `maven.compiler.release`.
- Two of the Java 25 recipe's examples come from a test named `EnableLombokAnnotationProcessorTest`,
  a hint that it may also declare Lombok as an annotation processor. Compare its `pom.xml` change with
  your task 3.

> Verify: whether `UpgradeToJava25` updates the Spring Boot `java.version` property and adds Lombok to
> `annotationProcessorPaths`. Also check which Spring Boot versions `UpgradeSpringBoot_3_5` starts from,
> on its recipe page.

> **Licensing and distribution:** check both before you run these recipes at work.
>
> - **Licence.** Both recipe pages say: "This recipe is available under the Moderne Source Available
>   License." Per [OpenRewrite licensing](https://docs.openrewrite.org/licensing/openrewrite-licensing):
>   - "if you work at a company and you want to run these recipes on your own code you are free to
>     do so".
>   - But "The software may not be commercialized or provided to others as a managed service", and
>     "you can't provide consulting/professional services where you charge people and run these
>     recipes."
>   - The core framework and the Maven and Gradle plugins are Apache-licensed.
>   - Recipes to "Upgrade to the latest Spring Boot, Spring Framework, and Hibernate releases" are also
>     offered to Moderne customers under the Moderne Proprietary License.
> - **Distribution is changing.** "Recipes are moving from Maven Central to the Code Genome Project."
>   The recipe pages add: "OpenRewrite artifacts, including the Maven and Gradle plugins themselves,
>   are distributed through the Code Genome Project repository
>   (https://artifacts.codegenomeproject.org/maven), which requires authentication." They also say:
>   "Moderne customers can download precompiled artifacts from The Code Genome Project. For
>   non-commercial use you can build the artifact from source locally."
>
> Verify with your legal or procurement team, and with the Code Genome Project quickstart, how your
> company may obtain the artifacts.

**Run it (only if you have Code Genome Project credentials)**

1. Put the credentials in your user Maven settings, `~/.m2/settings.xml`, never in the repository.
   This is the shape the recipe pages show for the command line, with `USERNAME` and `TOKEN` as
   placeholders:

   ```xml
   <settings>
     <servers>
       <server>
         <id>codegenome</id>
         <username>USERNAME</username>
         <password>TOKEN</password>
       </server>
     </servers>
     <profiles>
       <profile>
         <id>codegenome</id>
         <repositories>
           <repository>
             <id>codegenome</id>
             <url>https://artifacts.codegenomeproject.org/maven</url>
           </repository>
         </repositories>
         <pluginRepositories>
           <pluginRepository>
             <id>codegenome</id>
             <url>https://artifacts.codegenomeproject.org/maven</url>
           </pluginRepository>
         </pluginRepositories>
       </profile>
     </profiles>
     <activeProfiles>
       <activeProfile>codegenome</activeProfile>
     </activeProfiles>
   </settings>
   ```

2. Create the lab branch from `stage-2`, then run the recipes yourself in the terminal. Your `mvn *`
   rule would let the agent run them without asking, but you want to see the downloads and the
   diff. The plugin version below (`6.49.0`) is the one the recipe pages showed on 2026-10-09; use the
   version the page shows today:

   ```bash
   git switch -c lab/openrewrite stage-2
   mvn -U org.openrewrite.maven:rewrite-maven-plugin:6.49.0:run --define rewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:RELEASE --define rewrite.activeRecipes=org.openrewrite.java.spring.boot4.UpgradeSpringBoot_4_0 --define rewrite.exportDatatables=true
   git add -A
   git commit -m "lab: OpenRewrite UpgradeSpringBoot_4_0"
   mvn -U org.openrewrite.maven:rewrite-maven-plugin:6.49.0:run --define rewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-migrate-java:RELEASE --define rewrite.activeRecipes=org.openrewrite.java.migrate.UpgradeToJava25 --define rewrite.exportDatatables=true
   git add -A
   git commit -m "lab: OpenRewrite UpgradeToJava25"
   ```

3. Review and compare, the same way as Exercise A.2. Then clean up:

   ```bash
   git diff --stat workshop -- pom.xml src
   mvn -B clean verify | grep -E "Tests run:|BUILD" | tail -n 2
   git switch workshop
   git branch -D lab/openrewrite
   ```

**Verify:** you can say what each recipe would have done for this app, and what it would have left for
you: the 4.0.x → 4.1.1 bump, the Jackson properties, and possibly the Lombok processor declaration and
the `@AllArgsConstructor` fix (the test count and `validUserIsCreated` tell you). You can also say
under which terms your company may run the recipes.

**A good combination for large codebases:**

1. Run a recipe for the bulk mechanical changes on a branch.
2. Commit the result.
3. Let a Kiro spec finish what the recipe didn't cover, with the verify hook and the test count as
   gates.

**Checkpoint:** nothing from the lab lands on `workshop`.

Docs: [Checkpoints (why you commit first)](https://kiro.dev/docs/checkpoints/) ·
[Permissions](https://kiro.dev/docs/permissions/)

## Appendix troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `atx custom def list` fails with an access error | IAM permissions are missing | Attach `AWSTransformCustomFullAccess`, or ask your administrator to add it to your SSO permission set. |
| The AWS Transform power stops on Windows | Its steering asks for WSL | Run Kiro and the lab from WSL, macOS or Linux. |
| OpenRewrite can't resolve the plugin or recipe (401 or "Could not find artifact") | Artifacts moved to the authenticated Code Genome Project repository | Configure `~/.m2/settings.xml` (Exercise A.3), or skip the run. |
| Restore didn't undo the AWS Transform or OpenRewrite changes | Checkpoints don't capture shell or MCP changes | Use git on the lab branch: `git restore .`, then `git clean -nd` to preview and `git clean -fd` to remove untracked files. Or switch away and delete the lab branch. |
