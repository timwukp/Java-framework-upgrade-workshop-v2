# Module 7 — Scale out: Powers, headless CLI, Kiro Web and Workflows (optional, 60 minutes)

So far everything happened in one IDE, on one repository. This module takes the same approach
further: a **power**, Kiro **headless in CI**, **Kiro Web**, background **Workflows**, and a rollout
checklist for many services.

## What you'll do

| Part | Topic: what you'll do | Time |
|---|---|---|
| 1 | **A power for the migration knowledge:** package and test it in the Agent Plugins format, and learn how to share it through GitHub | 12 min |
| 2 | **Headless `kiro-cli` in CI:** run it with `--no-interactive`, and add a GitHub Actions job that posts a migration-readiness report for every pull request | 20 min |
| 3 | **Kiro Web:** connect a repository, dry-run the sandbox, run a migration task, use autonomous mode, and drive fixes from pull request comments with `/kiro fix` | 15 min |
| 4 | **Workflows:** run a bundled recipe in the background | 6 min |
| 5 | **Rolling out to many services:** build a rollout checklist | 7 min |

## Prerequisites

- Module 5 is finished and the `stage-3-final` tag exists.
- For Parts 2 and 3:
  - A GitHub account where you can create a repository. GitLab also works for Part 3.
  - A paid Kiro plan (Pro, Pro+, Pro Max or Power). API keys and Kiro Web are not available on the
    Free plan.
  - If your subscription is managed by an administrator: the admin must enable API key generation
    (Part 2) and, for IAM Identity Center organizations, Cloud Sessions (Part 3) first.
- Optional: the GitHub CLI (`gh`).

No paid plan? Do Parts 1, 4 and 5 hands-on and read Parts 2 and 3.

**Hooks at the start:** `verify-after-spec-task`, `jakarta-import-guard` and `block-deploy-and-push`
are on in `sample-app/`, as at the end of Module 5. Part 2 copies the reference `block-deploy-and-push`
into a new service repository; Part 3 turns it off in that repository only.

Commands run from `sample-app/` unless a step says otherwise.

---

## Part 1 — A power for the migration knowledge (12 min)

Each repository's `.kiro/` folder travels with that repository. A **power** is installed per user and
works in every workspace. It's the right home for knowledge that is the same everywhere, such as how
to move `javax.*` to `jakarta.*`. Powers follow the Agent Plugins format:

```text
java-modernization/
├── plugin.json        # required manifest
├── skills/            # Agent Skills, one folder per skill
│   └── <skill-name>/
│       └── SKILL.md
└── mcp.json           # optional MCP servers
```

Steering, hooks and custom agents don't go in a power; they stay in each repository's `.kiro/`
(see Part 5).

<details><summary>Background: the Agent Plugins format, field by field</summary>

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
and custom agents stay in each repository's `.kiro/` (see Part 5).

Docs: [Powers](https://kiro.dev/docs/powers/) · [Create powers](https://kiro.dev/docs/powers/create/) ·
[Install powers](https://kiro.dev/docs/powers/installation/) · [Skills](https://kiro.dev/docs/skills/)

</details>

### Exercise 7.1 — Inspect the workshop power

**Goal:** check that `powers/java-modernization/` follows the documented format before you install or
share it.

**Steps**

1. List the power and read its manifest. The power lives next to `sample-app/`, outside the workspace.

   ```bash
   find ../powers/java-modernization -type f | sort
   cat ../powers/java-modernization/plugin.json
   ```

2. Check the required manifest fields and the skill names.

   ```bash
   python3 -c "import json; d=json.load(open('../powers/java-modernization/plugin.json')); print('missing:', [k for k in ['\$schema','name','version','description','author','keywords'] if k not in d]); print('keywords:', d.get('keywords'))"
   for f in ../powers/java-modernization/skills/*/SKILL.md; do echo "$(basename "$(dirname "$f")") -> $(grep -m1 '^name:' "$f")"; done
   ```

**Ask Kiro** (optional, Default agent)

<details><summary>Optional prompt: ask Kiro to check the power against the format</summary>

```text
Read ../powers/java-modernization/plugin.json and every SKILL.md under ../powers/java-modernization/skills/.
Check them against the Agent Plugins power format: required plugin.json fields, skill name equals folder name,
a description that says when to use the skill. Suggest keywords a developer would actually type when
starting a Spring Boot or Java upgrade. Do not edit any files.
```

The power folder is outside the workspace, and without extra rules Kiro reads only workspace files
silently. Expect an approval prompt for these reads.

</details>

**Verify:** the first command prints `missing: []` and the keyword list. Each skill line shows the
folder name and the same `name:` value.

**Checkpoint:** nothing to commit yet.

### Exercise 7.2 — Import the power from a folder and test keyword activation

**Goal:** install the power and prove that it activates outside this repository.

**Steps**

1. If you already imported the power in Module 4, skip to step 3.
2. Open the Powers panel (the Ghosty icon with the lightning bolt) and choose **Add Custom Power** →
   **Import power from a folder**. Select the `powers/java-modernization` folder, the one that contains
   `plugin.json`, and click **Install**.
3. Open a different folder, so the workspace skills in `sample-app/.kiro/skills/` can't answer for the
   power. An empty scratch folder works:

   ```bash
   mkdir -p ~/work/power-test
   cd ~/work/power-test
   kiro .
   ```

   Kiro treats this new folder as **untrusted** and asks before every power activation until you trust
   it. Trust it when asked (as for `sample-app/` in setup), or expect an approval prompt.

4. In the new window, ask a question that uses the power's keywords. The workshop power ships the
   stage-3 skills (`spring-boot-4-upgrade`, `java-25-adoption`), and its keywords include
   "spring boot 4", "jackson 3" and "java 25".

**Ask Kiro**

```text
I am moving a Spring Boot 3.5 service to Spring Boot 4 and Java 25. My tests use @MockBean and I have a
Jackson2ObjectMapperBuilderCustomizer. What do I change, and how do I verify the upgrade?
```

**Verify:** ask a follow-up:

```text
Which powers or skills did you use for that answer?
```

The answer usually names the power or its `spring-boot-4-upgrade` skill (how the model reports this
varies), and its content matches the skill (details below). If the power doesn't activate, rephrase
using a word from `keywords`.

<details><summary>What a correct answer contains</summary>

The content should match the skill: `@MockitoBean` from
`org.springframework.test.context.bean.override.mockito`, `JsonMapperBuilderCustomizer` for Jackson 3,
and `mvn -B verify` on JDK 25 with an unchanged "Tests run" total.

</details>

**Checkpoint:** nothing to commit.

### Exercise 7.3 — Extend the power and share it

**Goal:** make the power cover the earlier stages too (today it knows stage 3 only), then publish it
so other people can install it.

<details><summary>Background: why extend it</summary>

Today the power knows stage 3 only. The stage-2 knowledge (`javax` → `jakarta`, JUnit 4 → Jupiter)
lives in this workspace's `.kiro/skills/`, so another repository can't use it yet.

</details>

**Steps**

1. Copy the workspace's `jakarta-namespace-migration` skill into the power, plus the skill you wrote
   in Module 3 (for example your JUnit 4 → Jupiter skill). Back in `sample-app/`:

   ```bash
   ls .kiro/skills/
   cp -R .kiro/skills/jakarta-namespace-migration ../powers/java-modernization/skills/
   cp -R .kiro/skills/<your-module-3-skill> ../powers/java-modernization/skills/
   ```

   Skip the second `cp` if you didn't write a skill in Module 3.

2. Edit `../powers/java-modernization/plugin.json`: `version` `1.0.0` → `1.1.0`; keywords for the new
   skills (for example `"jakarta"`, `"javax to jakarta"`, `"spring boot 3"`, `"junit 5"`); a
   `description` that no longer says stage 3 only. Then run the Exercise 7.1 checks again.
3. Refresh the installed copy. For powers installed from a repository, the docs describe Powers panel
   → the power → **Check for updates** → **Install updates**.

   > Verify: how a folder-imported power picks up local edits is not documented. If the new skill
   > doesn't appear, import the folder again.

4. Share it through a **public** GitHub repository (commands below). Others install it with **Add
   Custom Power** → **Import power from GitHub** and the repository URL. Publish only content you are
   allowed to share; this power contains generic migration guidance only.

<details><summary>Commands and rules: publish the power on GitHub</summary>

Run these from your home directory. This is a new repository, so its default branch is `main`; your
workshop line stays on `workshop`.

```bash
mkdir -p ~/work/kiro-powers
cp -R <path-to-workshop>/powers/java-modernization ~/work/kiro-powers/
cd ~/work/kiro-powers
git init -b main
git add .
git commit -m "Add java-modernization power"
git remote add origin https://github.com/<you>/kiro-powers.git
git push -u origin main
```

- Each power needs its `plugin.json` (or `POWER.md`) at its package root.
- One repository can hold several powers, each in its own directory.
- For **private** repositories, the docs say to clone the repository locally and use
  **Import power from a folder**.

> Verify: when the power sits in a subfolder, AWS documents a GitHub *tree* URL for its own power
> (`https://github.com/kirodotdev/powers/tree/main/aws-transform`). The equivalent here would be
> `https://github.com/<you>/kiro-powers/tree/main/java-modernization`. Test the import before you
> tell your team to use it.

</details>

**Verify:**

- In the Exercise 7.2 scratch folder, "Which javax packages move to jakarta in Spring Boot 3, and
  which stay?" now gets an answer from the power (for example, that `javax.sql` stays).
- A teammate, or a second Kiro profile, can install the power from your URL.

**Checkpoint** (in `sample-app/`; the power folder is part of the workshop repository):

```bash
git add ../powers/java-modernization
git commit -m "Module 7: extend java-modernization power"
```

<details><summary>Background: registry powers worth knowing</summary>

The [kiro.dev/powers](https://kiro.dev/powers/) registry lists two AWS-authored powers, **AWS
Transform** and **AWS Transform Agent Toolkit**.

- **AWS Transform** describes itself as covering, among other workloads, Java version upgrades. It
  drives the AWS Transform service, which needs an AWS account and IAM permissions. See the optional
  lab in [Module 4](04-spring-boot-4-java25.md) for its prerequisites and caveats.
- **AWS Transform Agent Toolkit** is for *building* agents that run in AWS Transform, not for running
  upgrades.

Install registry powers from kiro.dev/powers (**Add to Kiro**) or from the Powers panel (**+ Install**).
The docs warn that powers are third-party tools: install only from sources you trust.

</details>

---

## Part 2 — Headless `kiro-cli` in CI (20 min)

### Exercise 7.4 — Give the service its own repository

**Goal:** create a repository whose root is the stage-3 service, with `.kiro/` at the top level.

<details><summary>Background: why a separate repository</summary>

CI workflows live at the repository root, and the docs describe project configuration as the `.kiro/`
folder in your repository. A root-level `.kiro/` avoids depending on undocumented subfolder behavior.

</details>

**Steps.** Run these from the workshop repository root (the folder above `sample-app/`). The `cp` line
replaces your Module 5 `block-deploy-and-push` with the reference version, which matches only
Maven/Gradle deploy goals and `git push`:

```bash
mkdir -p ~/work/user-management-service
git archive --format=tar stage-3-final:sample-app | tar -x -C ~/work/user-management-service
git show stage-3-final:.gitignore > ~/work/user-management-service/.gitignore
cp solutions/kiro-reference/hooks/block-deploy-and-push.json ~/work/user-management-service/.kiro/hooks/
cd ~/work/user-management-service
git init -b main
git add .
git commit -m "User management service at stage 3 (Java 25, Spring Boot 4.1)"
```

Create an empty **private** GitHub repository and push yourself (the hook only stops the agent). As
a new repository, its default branch is `main`.

```bash
git remote add origin https://github.com/<you>/user-management-service.git
git push -u origin main
```

**Verify**

```bash
ls -a ~/work/user-management-service
ls ~/work/user-management-service/.kiro ~/work/user-management-service/.kiro/hooks
```

Expect `pom.xml`, `src/` and `.kiro/` at the top level; `agents`, `hooks`, `skills` and `steering`
under `.kiro/`; and three hook files, including `block-deploy-and-push.json`, under `.kiro/hooks/`.

**Checkpoint:** the push succeeded.

### Exercise 7.5 — Install the CLI and run it headless locally

**Goal:** run Kiro without an interactive session, with read-only tools, and read its exit code.

**Steps**

1. Install the CLI (macOS/Linux), sign in and run the built-in diagnostics:

   ```bash
   curl -fsSL https://cli.kiro.dev/install | bash
   kiro-cli login
   kiro-cli whoami
   kiro-cli doctor
   ```

   On a remote machine without a browser, use `kiro-cli login --use-device-flow`.

2. In `~/work/user-management-service`, save the report prompt (expand below) as
   `.github/kiro/readiness-prompt.txt`. Keeping it in a file makes the prompt reviewable like code.

   ```bash
   cd ~/work/user-management-service
   mkdir -p .github/kiro
   ```

   <details><summary>Copy: the readiness prompt</summary>

   ```text
   You are reviewing a pull request in a staged Java and Spring Boot migration repository.
   Use only the information below and read-only access to the repository files. Do not modify files.
   Write a Markdown report titled "Migration readiness" with these sections:
   1. Build: BUILD SUCCESS or FAILURE, and the final "Tests run / Failures / Errors / Skipped" line.
   2. Versions: the Java release and the Spring Boot parent version from pom.xml.
   3. Namespace: remaining Jakarta EE imports from javax.* (persistence, validation, servlet, inject,
      transaction, JAXB, ...). JDK packages such as javax.sql or javax.transaction.xa are fine.
   4. Risky changes: security configuration, validation, deleted or disabled tests, pinned versions, secrets.
   5. Verdict: "ready" or "not ready", with one sentence of reasoning.
   Apply the rules in .kiro/steering/migration-standards.md.
   ```

   </details>

3. Build, then pipe the prompt plus the Maven summary into Kiro on stdin (a documented pattern; Kiro
   doesn't need to read the git-ignored log file itself).

   ```bash
   mvn -B clean verify > build.log 2>&1
   { cat .github/kiro/readiness-prompt.txt; echo "## Maven summary"; grep -E 'Tests run:|\[ERROR\]|BUILD' build.log | tail -n 200; } | kiro-cli chat --v3 --no-interactive --trust-tools=read,grep > target/kiro-readiness-report.md
   echo "kiro-cli exit code: $?"
   ```

`--trust-tools=read,grep` keeps the run read-only: in headless runs, "ask" means deny.

<details><summary>Background: what the flags and exit codes mean</summary>

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

> Verify: the authentication page says an active `kiro-cli login` session takes precedence over
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

</details>

**Verify**

```bash
head -n 30 target/kiro-readiness-report.md
```

Expect a Markdown report with the five sections and exit code 0.

<details><summary>Example report (yours will differ)</summary>

```markdown
# Migration readiness
1. Build: BUILD SUCCESS — Tests run: 14, Failures: 0, Errors: 0, Skipped: 0
2. Versions: Java 25, Spring Boot 4.1.x
3. Namespace: no Jakarta EE APIs imported from javax.*
4. Risky changes: none found
5. Verdict: ready — the build is green and no test count regression is visible.
```

</details>

If authentication fails, export `KIRO_API_KEY` (next exercise) and run it again.

**Checkpoint**

```bash
git add .github/kiro/readiness-prompt.txt
git commit -m "Add Kiro migration-readiness prompt"
```

### Exercise 7.6 — Create an API key and store it as a CI secret

**Goal:** authenticate CI without a browser.

**Steps**

1. Sign in to [app.kiro.dev](https://app.kiro.dev) with your Pro, Pro+, Pro Max or Power account, open
   the **API Keys** section, create a key with a meaningful name, and copy it. The full value is shown
   only once.
2. Store it as the GitHub Actions secret `KIRO_API_KEY`: in the repository, open **Settings → Secrets
   and variables → Actions**, or run:

   ```bash
   gh secret set KIRO_API_KEY
   ```

<details><summary>Background: things to know before you rely on an API key</summary>

- API keys belong to your user account. Credits used through the key come out of your subscription.
- Your administrator's governance rules (MCP restrictions, model access, web fetch) apply to headless
  sessions too.
- Managed subscriptions need an admin to enable API key generation first.
- Never commit the key. Rotate keys regularly and revoke unused ones in the Kiro web console.

Docs: [Authentication — API keys](https://kiro.dev/docs/getting-started/authentication/)

</details>

**Verify:** `gh secret list` (or the Secrets page) shows `KIRO_API_KEY`.

**Checkpoint:** nothing to commit. A secret never goes into git.

### Exercise 7.7 — A GitHub Actions job for a migration-readiness report

**Goal:** on every pull request, Maven decides pass/fail and Kiro explains the result in a readiness
report.

**Steps.** Create `.github/workflows/kiro-migration-readiness.yml` with the content below. This is an
example to adapt. The Kiro commands and flags come from the headless docs; check them against your
CLI version.

<details><summary>Copy: the workflow file</summary>

```yaml
# Example to adapt. Kiro flags: https://kiro.dev/docs/cli/headless/
name: Kiro migration readiness

on:
  pull_request:

permissions:
  contents: read

jobs:
  readiness:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK 25
        uses: actions/setup-java@v4
        with:
          distribution: corretto
          java-version: "25"
          cache: maven

      - name: Build and test (the deterministic gate)
        run: |
          set -o pipefail
          mvn -B clean verify 2>&1 | tee build.log

      - name: Install Kiro CLI
        if: always()
        run: curl -fsSL https://cli.kiro.dev/install | bash

      - name: Ask Kiro for a migration-readiness report
        if: always()
        env:
          KIRO_API_KEY: ${{ secrets.KIRO_API_KEY }}
          KIRO_LOG_NO_COLOR: "1"
          BASE_REF: ${{ github.base_ref }}
        run: |
          mkdir -p target
          code=0
          {
            cat .github/kiro/readiness-prompt.txt
            echo "## Files changed in this pull request"
            git diff --stat "origin/${BASE_REF}...HEAD" || true
            echo "## Maven summary"
            grep -E 'Tests run:|\[ERROR\]|BUILD' build.log | tail -n 200 || true
          } | kiro-cli chat --v3 --no-interactive --trust-tools=read,grep > target/kiro-readiness-report.md || code=$?
          case "$code" in
            0) cat target/kiro-readiness-report.md >> "$GITHUB_STEP_SUMMARY" ;;
            3) echo "::error::A required MCP server did not start (exit 3)"; exit 1 ;;
            4) echo "::error::Requested agent not found (exit 4)"; exit 1 ;;
            *) echo "::error::kiro-cli failed with exit code $code"; exit "$code" ;;
          esac

      - name: Keep the report and the build log
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: kiro-readiness
          path: |
            target/kiro-readiness-report.md
            build.log
```

</details>

**Maven is the gate, Kiro is the explainer.** Treat pull request content as untrusted input: keep
`--trust-tools=read,grep` and `contents: read`.

<details><summary>Background: design choices, variants, and a pre-workshop check for this job</summary>

> Verify: check that `actions/setup-java` offers the `corretto` distribution with Java 25 on your
> runner before the workshop.

- **Maven is the gate, Kiro is the explainer.** If `mvn -B verify` fails, the job fails no matter
  what the report says.
- **Treat pull request content as untrusted input to the agent.** Keep `--trust-tools=read,grep` and
  `contents: read`, and give the job no write tokens.
- **Variant: reuse your reviewer.** Add `--agent migration-reviewer` to the `kiro-cli` command. Exit
  code 4 then tells you the agent wasn't found.

  > Verify: workspace agents load only in trusted workspaces, and the docs don't describe how trust
  > applies to a non-interactive CI run. Test the variant before relying on it.
- **Optional: post the report as a pull request comment** with
  `gh pr comment <number> --body-file target/kiro-readiness-report.md`. That needs
  `pull-requests: write` and `GH_TOKEN`, which widens the job's permissions; decide deliberately.

</details>

Then open a pull request:

```bash
git switch -c ci/kiro-readiness
git add .github/workflows/kiro-migration-readiness.yml
git commit -m "CI: Kiro migration-readiness report"
git push -u origin ci/kiro-readiness
gh pr create --fill
```

**Verify:** in the pull request's **Checks** tab, the job runs. Its summary page shows the readiness
report, and the `kiro-readiness` artifact contains the report and `build.log`. A failed Kiro step logs
which exit-code branch fired (for example "Requested agent not found (exit 4)").

**Checkpoint:** merge the pull request yourself once the job is green. Kiro never needs merge rights
for this.

---

## Part 3 — Kiro Web (15 min)

Kiro Web is a browser agent at [app.kiro.dev](https://app.kiro.dev). It clones your repository into
an isolated cloud sandbox, works there, and delivers the result as a pull request or merge request.
Kiro never merges automatically. A cloud session has no Supervised mode, checkpoints or revert, so
make every step end in a commit or pull request.

<details><summary>Background: plans, region, what the sandbox reads, and limits</summary>

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

</details>

### Before the first Kiro Web task: turn off `block-deploy-and-push` in this repository

**Recommendation: disable the hook for the Kiro Web exercises.** Kiro Web applies the repository's
`.kiro/` hooks, and this hook blocks any agent shell call that runs `git push`. Kiro Web delivers its
pull requests itself and never merges, so you still review everything. Turn it off in
`user-management-service` only; `sample-app/` keeps it on.

> Verify: whether a workspace `PreToolUse` hook interferes with Kiro Web's pull request delivery is
> undocumented. If you test with the hook on, a delivery that fails with "Blocked by workspace policy"
> is the hook; if delivery works, record that and turn the hook back on. The command itself does exit 2
> on `git push` (verified on Linux in the 2026-10-10 dry run, outside Kiro).

After merging the Exercise 7.7 pull request:

```bash
cd ~/work/user-management-service
git switch main
git pull
python3 -c "import json; p='.kiro/hooks/block-deploy-and-push.json'; d=json.load(open(p)); d['hooks'][0]['enabled']=False; json.dump(d, open(p, 'w'), indent=2); print('enabled:', d['hooks'][0]['enabled'])"
git add .kiro/hooks/block-deploy-and-push.json
git commit -m "Disable block-deploy-and-push for Kiro Web pull request delivery"
git push
```

Expect `enabled: False`. Kiro Web reads the pushed `.kiro/`, so start Web sessions after this push.
Record the decision, for example in the README.

### Exercise 7.8 — Connect the repository and dry-run the sandbox

**Goal:** before you trust Kiro Web with a migration task, find out what the sandbox can actually build.

**Steps**

1. In app.kiro.dev, open **Settings** → **Agent** tab → **GitHub** → **Connect GitHub**. Authorize the
   **Kiro Agent** GitHub app and select `user-management-service`. You need write permission on the
   repository for Kiro to create branches and pull requests. GitLab is also supported.
2. Start a session on that repository and run a dry run. **The docs don't document a JDK or Maven
   runtime selector**, so check before you start real work.

<details><summary>Background: how the sandbox configures itself</summary>

The sandbox configures itself from the build files it detects, and the manual settings cover
environment variables, internet access, Powers/MCP and AWS credentials.

</details>

**Ask Kiro**

```text
Do not change any files and do not open a pull request.
Run java -version and mvn -v in the sandbox and show me the exact output.
Then run mvn -B verify and report the final Tests run / Failures / Errors / Skipped line.
List the steering files, custom agents and hooks you loaded from .kiro/.
```

**Verify:** the output shows a Java 25 runtime, Maven, and a green build with the same test count as
your local run (14). The list usually names `migration-standards` and `migration-reviewer` (the
wording is model-dependent); the disabled `block-deploy-and-push` may be missing or marked disabled.

- If Java 25 or Maven is missing, or dependencies don't download, stop: review the sandbox's
  environment configuration and internet access (Maven must reach your Maven repository), then retry.
  Don't run migration work on a sandbox that can't build.

**Checkpoint:** note the sandbox's Java and Maven versions in the repository README or your notes.

### Exercise 7.9 — A migration task in the sandbox

**Goal:** hand Kiro Web a well-scoped follow-up and get a pull request back.

**Steps.** Pick a **should-fix** or **nit** from your Module 5 review, or use the example below if your
app still has its hand-rolled error map.

**Ask Kiro**

```text
Follow the steering in .kiro/steering. In ApiExceptionHandler, replace the hand-rolled error map with
Spring's ProblemDetail for 404 and validation errors. Keep every existing test and the X-Request-Id header.
Before you finish, use the migration-reviewer agent to review your diff, run mvn -B verify, and open a
pull request whose description lists the Tests run totals before and after.
```

Custom agents run only as sub-agents on Web, hence "use the migration-reviewer agent".

<details><summary>Background: modes and custom agents on Kiro Web</summary>

This uses the default (interactive) mode. Kiro Web also offers Spec mode and autonomous mode (next
exercise). Custom agents can't be the *primary* agent on Web, but Kiro Web loads `.kiro/agents/` and can delegate
to them as sub-agents. That is why the prompt says "use the migration-reviewer agent".

</details>

**Verify**

- The pull request exists and the readiness job from Part 2 runs on it.
- Locally:

  ```bash
  git fetch origin
  git switch <kiro-branch>
  mvn -B clean verify
  ```

  The build is green and the test count is not lower.

**Checkpoint:** review and merge the pull request yourself, or close it.

### Exercise 7.10 — Autonomous mode and `/kiro fix`

**Goal:** delegate an outcome end to end, then steer it from pull request review comments.

**Steps**

1. Start a new session and toggle **Autonomous** in the chat input bar. It is off by default; you can
   switch it on before the first message or later.
2. Send the task below. If the agent needs an answer from you, the task moves to **Needs attention**.

   <details><summary>Background: what autonomous mode does</summary>

   In autonomous mode the agent:
   - builds a plan with requirements and acceptance criteria;
   - delegates the work to sub-agents;
   - opens a pull request when it is done;
   - chooses the model itself;
   - moves the task to **Needs attention** if it needs an answer from you.

   It doesn't always open a pull request; some tasks end with an answer in chat.

   </details>

**Ask Kiro**

```text
Add web-layer tests that pin the current security behaviour of this service: unauthenticated requests get 401,
authenticated GET /api/users works, authenticated POST /api/users with invalid input gets 400, and every
response carries X-Request-Id. Do not change production code. Run mvn -B verify and open a pull request.
```

3. On the pull request Kiro opened, leave a review comment on one of the new tests, for example "Use a
   descriptive @DisplayName". Then reply in that thread with `/kiro fix`; it addresses all comments in
   that conversation thread.

**Verify:** a new commit addressing your comment appears on the pull request, and the readiness job runs
again.

**Checkpoint:** you review and merge. Kiro never merges.

<details><summary>Background: <code>/kiro all</code>, docs, and following a session from the terminal</summary>

`/kiro all` addresses every comment from every reviewer on the pull request.

Docs: [Autonomous mode](https://kiro.dev/docs/web/autonomous-mode/)

To follow a cloud session from your terminal: `kiro-cli --resume-id <session-id>`.

</details>

---

## Part 4 — Workflows (6 min)

**Workflows** are background, multi-step graphs of agent steps (sequences, loops, parallel branches).
They are opt-in in every client:

- **IDE:** **Workspace Configuration → Workflows** (in Agent Focus), or set
  `kiroAgent.workflows.enabled` in Settings; **then start a new chat session**. If Workflows is absent,
  it isn't available for your account yet.
- **CLI:** `/settings` → **Features**, then restart Kiro CLI.

**Stop doesn't undo file changes**, so run workflows on a branch.

<details><summary>Background: how Workflows work, recipes, controls and limits</summary>

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

</details>

### Exercise 7.11 — A read-only investigation in the background

**Goal:** run a bundled recipe while you keep working in the main chat.

**Steps.** Back in the workshop's `sample-app/` workspace, enable Workflows and start a new chat
session (see above), then branch first:

```bash
git switch -c m7-workflow-lab
```

**Ask Kiro** (Default agent)

```text
Run the investigate workflow. It must be read-only.
Find every place in this codebase whose behaviour depends on something that changed between Spring Boot 2.2
and 4.1: security defaults and CSRF rules, Bean Validation, Jackson configuration, trailing-slash matching,
test slices and mocking annotations. Report file:line evidence and a severity for each finding.
```

<details><summary>Optional while it runs: the background single-agent variant</summary>

While it runs, try the background single-agent variant in the main chat:

```text
Run the migration-reviewer agent in the background as a workflow on git diff stage-0..HEAD.
```

The docs describe this as the main agent launching `run_workflow(agent://<name>)`.

</details>

**Verify**

```bash
git status --short
```

Expect no output (the runs are read-only). The runs appear above the parent chat; selecting a step
opens its own tab.

**Checkpoint:** nothing to commit. Switch back with `git switch -`.

<details><summary>Optional stretch: draft a recipe for your stage loop</summary>

Ask Kiro to draft a recipe in `.kiro/workflows/` for your stage loop (investigate → plan → implement
→ review, repeated until `mvn -B verify` passes, with a `maxIterations` cap). Writes to
`.kiro/workflows/` always ask for approval. Recipes allow at most 8 nesting levels and 50 static step
nodes. Review the generated JSON like code before you run it.

</details>

---

## Part 5 — Rolling out to many services (7 min)

Use this generic checklist to turn one successful migration into a repeatable program. Discuss it with
your table and adapt it.

### Exercise 7.12 — Draft your rollout checklist

**Goal:** leave with a written plan you can take to your team.

**Steps.** Write down, for each item, an owner and a "done" signal:

1. **Inventory** every service (versions, `javax.*` imports, tests, packaging, CI, owner).
2. **Start with one representative service** with a usable test suite and an owner who reviews the
   pull requests; measure it (item 7).
3. **Stages per service:** latest line of the current major first, then one major at a time.
4. **Ship `.kiro/` in every repository**, with the reference deploy/push guard; decide per repository
   whether it stays on where Kiro Web delivers pull requests.
5. **Shared knowledge as a versioned power** (Part 1).
6. **Global steering** for individuals; Kiro Web doesn't read it.
7. **Metrics** per stage; "Tests run" must never drop.
8. **Guardrails outside git:** permission rules are per developer; never pre-approve deploy or push.
9. **CI everywhere:** Maven gates, Kiro explains.
10. **Plans and data:** confirm with your Kiro subscription owner.

<details><summary>Background: the full checklist, with the inventory probe</summary>

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

   You can run the Part 2 readiness prompt headless against each repository to collect the rest.

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
   decide per repository whether the deploy/push guard stays on, and record the decision (Part 3).
5. **Shared knowledge as a power.** Put skills that are identical everywhere into the power from
   Part 1 and version it. Install from GitHub (public) or from a cloned folder (private).
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
9. **CI everywhere.** Add the Part 2 job, or your own equivalent: Maven as the gate, Kiro as the
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

</details>

**Verify:** your checklist names an owner and a "done" signal for every item. The done signals should
be things you can check (a green build, a test count, a merged pull request), not opinions.

**Checkpoint:** save the checklist wherever your team plans work.

---

## Checklist

- [ ] The power's `plugin.json` has all required fields, and each skill's `name` equals its folder.
- [ ] The power, imported from a folder, activated by keyword in another workspace.
- [ ] You can share a power: public repository → **Import power from GitHub**; private → local clone →
      **Import power from a folder**.
- [ ] `kiro-cli whoami` works; a `--no-interactive` run with `--trust-tools=read,grep` gave a report
      and exit code 0.
- [ ] `KIRO_API_KEY` is a CI secret, not in git.
- [ ] The Actions job runs on a pull request, Maven gates it, and the report is in the job summary and
      the artifact.
- [ ] The service repository has the reference `block-deploy-and-push`, disabled there for Kiro Web,
      with the decision recorded.
- [ ] A Kiro Web dry run confirmed the sandbox's Java and Maven before any real task.
- [ ] Kiro Web opened a pull request; you used autonomous mode and `/kiro fix` on a review thread.
- [ ] A bundled Workflow ran in the background and left the working tree unchanged.
- [ ] Your rollout checklist has owners and measurable done signals.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Kiro Web's pull request delivery is blocked ("Blocked by workspace policy") | `block-deploy-and-push` is still enabled in the pushed `.kiro/` and matched a `git push` | Disable it as in "Before the first Kiro Web task", push, and start a new Web session |
| No Workflows option | Not enabled, no new chat session yet, or not available for your account yet | IDE: Workspace Configuration → Workflows or `kiroAgent.workflows.enabled`, then a new chat session; CLI: `/settings` → Features, then restart |

<details><summary>More troubleshooting rows</summary>

| Symptom | Likely cause | Fix |
|---|---|---|
| The sandbox lacks Java 25 or Maven, or can't download dependencies | Runtime selection isn't documented; internet access is restricted | Stop. Review environment configuration and internet access, then repeat the dry run |
| **Import power from a folder** fails | Wrong folder selected, or invalid `plugin.json` | Select the folder that contains `plugin.json`; validate it with the Exercise 7.1 check |
| The power never activates | Your wording doesn't match its `keywords`, or the folder isn't trusted and you dismissed the prompt | Use a keyword from `plugin.json`, or add the words developers actually use; trust the folder |
| `kiro-cli: command not found` after installing | The shell hasn't picked up the new `PATH` | Open a new terminal, then run `kiro-cli doctor` |
| CI step exits 1 with an authentication error | Missing secret, pull request from a fork (forks don't receive repository secrets), plan without API keys, or API keys not enabled by the admin | Check the secret name, run from a branch in the same repository, check plan and admin settings |
| Kiro Web isn't available | Free plan, Cloud Sessions not enabled for an Identity Center organization, or region | Use a paid plan; ask the admin to enable Cloud Sessions; Web runs in us-east-1 |
| A skill inside the power is ignored | `name` in `SKILL.md` differs from its folder name | Make them identical (lowercase, digits, hyphens) |
| **Import power from GitHub** fails | Private repository, or the URL doesn't point at the power's package root | Clone and import from a folder, or point the URL at the folder that contains `plugin.json` |
| `kiro-cli: command not found` in a later CI step | The installer's directory isn't on `PATH` for later steps on your runner | Add the directory the installer reports to `$GITHUB_PATH` in the install step |
| Exit code 4 | `--agent` names an agent that isn't available, or the configured default agent is missing | Check the name with `kiro-cli agent list`; drop `--agent` |
| Exit code 3 | `--require-mcp-startup` was used and an MCP server failed | Fix the MCP configuration or drop the flag if the run doesn't need MCP |
| Report says Kiro couldn't read files or run tools | Tools not pre-approved; in headless runs every "ask" becomes "deny" | Add the needed tools to `--trust-tools`; keep them read-only for reports |
| The report is empty but the exit code is 0 | The prompt or stdin was empty | Run the `{ … }` block without the pipe to check what Kiro received |
| The repository doesn't appear in Kiro Web | The Kiro Agent GitHub app isn't authorized for it, or you lack write permission | Update the app's repository access in GitHub; check your role |
| `/kiro fix` does nothing | Comment posted outside a review thread, or on a pull request Kiro didn't open | Reply inside the review thread on Kiro's pull request, or use `/kiro all` |
| A stopped workflow left half-finished edits | Stop doesn't undo file changes | `git restore .` on the lab branch, or `git switch -` and delete the branch |

</details>

## Kiro features used

Powers, headless `kiro-cli`, Kiro Web, Workflows and global steering (docs below).

<details><summary>Docs for every feature used</summary>

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

</details>

## Next

- Keep [docs/quick-reference.md](../docs/quick-reference.md) and
  [docs/kiro-feature-reference.md](../docs/kiro-feature-reference.md) at hand when you apply this to a
  real service.
- Start your first service with Module 1's assessment steps: a Plan session first, then one Feature
  spec per stage.
