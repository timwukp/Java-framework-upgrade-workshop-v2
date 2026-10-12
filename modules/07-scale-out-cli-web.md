<!-- runbook max-lines=720 -->
# Module 7 (optional): Scale out with powers, headless CLI, Kiro Web and Workflows (60 minutes)

Optional module · [← Module 6](06-platform-deployment.md) · [Day sheet](../docs/quick-reference.md) ·
[Troubleshooting](../docs/troubleshooting.md) · [Why and background](why/07-scale-out-cli-web.md)

So far everything happened in one IDE, on one repository. This module takes the same approach
further: a **power**, Kiro **headless in CI**, **Kiro Web**, background **Workflows**, and a rollout
checklist for many services.

## At a glance

| | |
|---|---|
| **Goal** | Take the approach beyond one IDE and one repository: a shared power, Workflows, a rollout checklist; and, with GitHub and a paid plan, headless CI and Kiro Web |
| **Time** | 25 minutes core (power 12, Workflows 6, rollout 7) + 35 minutes of Extras (headless CI 20, Kiro Web 15) |
| **Start** | Module 5 finished, tag `stage-3-final`; commands run from `sample-app/` unless a step says otherwise. Behind? `../scripts/reset-to-stage.sh 3-final` |
| **Hooks** | `verify-after-spec-task`, `jakarta-import-guard` and `block-deploy-and-push` **on** in `sample-app/`. Extra 7.A copies the reference `block-deploy-and-push` into a new service repository; Extra 7.B turns it off in that repository only |
| **Extras need** | A GitHub account where you can create a repository (GitLab also works for Extra 7.B); a paid Kiro plan (API keys and Kiro Web are not on the Free plan); on an administered subscription, the admin enables API key generation (7.A) and, for IAM Identity Center organizations, Cloud Sessions (7.B). Optional: the GitHub CLI (`gh`). No paid plan? Do the core and read the Extras. |
| **End** | Your own power in `~/work/kiro-powers`, a background investigation that changed nothing, a rollout checklist |

## Exercises

| # | Exercise | Min |
|---|---|---|
| 7.1 | [Inspect the workshop power](#71-inspect-the-workshop-power) | 3 |
| 7.2 | [Import the power from a folder and test keyword activation](#72-import-the-power-from-a-folder-and-test-keyword-activation) | 4 |
| 7.3 | [Extend the power and share it](#73-extend-the-power-and-share-it) | 5 |
| 7.4 | [A read-only investigation in the background](#74-a-read-only-investigation-in-the-background) | 6 |
| 7.5 | [Draft your rollout checklist](#75-draft-your-rollout-checklist) | 7 |
| 7.A1–7.A4 | [Extra 7.A: headless `kiro-cli` in CI](#extra-7a-headless-kiro-cli-in-ci-20-minutes-github-and-a-paid-plan) | 20 |
| 7.B1–7.B3 | [Extra 7.B: Kiro Web](#extra-7b-kiro-web-15-minutes-github-or-gitlab-and-a-paid-plan) | 15 |

## A power for the migration knowledge

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
(see Exercise 7.5).

**Why:** [the Agent Plugins format, field by field](why/07-scale-out-cli-web.md#a-power-for-the-migration-knowledge)

### 7.1 Inspect the workshop power

**Goal:** check that `powers/java-modernization/` follows the documented format before you install or
share it.

**Do**
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

**Prompt** (optional, Default agent)

**Optional prompt: ask Kiro to check the power against the format**

```text
Read ../powers/java-modernization/plugin.json and every SKILL.md under ../powers/java-modernization/skills/.
Check them against the Agent Plugins power format: required plugin.json fields, skill name equals folder name,
a description that says when to use the skill. Suggest keywords a developer would actually type when
starting a Spring Boot or Java upgrade. Do not edit any files.
```

The power folder is outside the workspace, and without extra rules Kiro reads only workspace files
silently. Expect an approval prompt for these reads.


**Check:** the first command prints `missing: []` and the keyword list. Each skill line shows the
folder name and the same `name:` value.

**Commit:** nothing to commit yet.

### 7.2 Import the power from a folder and test keyword activation

**Goal:** install the power and prove that it activates outside this repository.

**Do**
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

**Prompt**

```text
I am moving a Spring Boot 3.5 service to Spring Boot 4 and Java 25. My tests use @MockBean and I have a
Jackson2ObjectMapperBuilderCustomizer. What do I change, and how do I verify the upgrade?
```

**Check:** ask a follow-up:

```text
Which powers or skills did you use for that answer?
```

The answer usually names the power or its `spring-boot-4-upgrade` skill (how the model reports this
varies), and its content matches the skill (details below). If the power doesn't activate, rephrase
using a word from `keywords`.

**Why:** [what a correct answer contains](why/07-scale-out-cli-web.md#72-import-the-power-from-a-folder-and-test-keyword-activation)

**Commit:** nothing to commit.

### 7.3 Extend the power and share it

**Goal:** make the power cover the earlier stages too (today it knows stage 3 only), then publish it
so other people can install it.

**Why:** [why extend it](why/07-scale-out-cli-web.md#73-extend-the-power-and-share-it)

**Do** (from `sample-app/`; you edit a copy outside the repository, so the workshop's `powers/` stays
as shipped)
1. Make your own copy of the power, and copy the workspace's `jakarta-namespace-migration` skill plus
   the skill you wrote in Module 3 into it (skip the last line if you didn't write one):

   ```bash
   mkdir -p ~/work/kiro-powers
   cp -R ../powers/java-modernization ~/work/kiro-powers/
   cp -R .kiro/skills/jakarta-namespace-migration ~/work/kiro-powers/java-modernization/skills/
   cp -R .kiro/skills/<your-module-3-skill> ~/work/kiro-powers/java-modernization/skills/
   ```

2. Edit `~/work/kiro-powers/java-modernization/plugin.json`: `version` `1.0.0` → `1.1.0`; keywords for
   the new skills (for example `"jakarta"`, `"javax to jakarta"`, `"spring boot 3"`, `"junit 5"`); a
   `description` that no longer says stage 3 only. Then run the Exercise 7.1 checks again, with
   `../powers` replaced by `~/work/kiro-powers`.
3. Install your copy: Powers panel → **Add Custom Power** → **Import power from a folder** → select
   `~/work/kiro-powers/java-modernization` → **Install**.

   > Unconfirmed: how Kiro handles a second folder import of a power with the same `name`, and how a
   > folder-imported power picks up later edits. If the new skills don't appear, remove the power you
   > installed in Exercise 7.2 from the Powers panel and import your copy again.

4. Share it through a **public** GitHub repository, from `~/work/kiro-powers` (a new repository, so its
   default branch is `main`). Publish only content you are allowed to share; this power contains
   generic migration guidance only. Others install it with **Add Custom Power** → **Import power from
   GitHub** and the repository URL.

   ```bash
   cd ~/work/kiro-powers
   git init -b main
   git add .
   git commit -m "Add java-modernization power"
   git remote add origin https://github.com/<you>/kiro-powers.git
   git push -u origin main
   ```

   - Each power needs its `plugin.json` (or `POWER.md`) at its package root; one repository can hold
     several powers, each in its own directory.
   - For **private** repositories, the docs say to clone the repository locally and use **Import power
     from a folder**.

   > Unconfirmed: when the power sits in a subfolder, AWS documents a GitHub *tree* URL for its own power
   > (`https://github.com/kirodotdev/powers/tree/main/aws-transform`). The equivalent here would be
   > `https://github.com/<you>/kiro-powers/tree/main/java-modernization`. Test the import before you
   > tell your team to use it.

**Expect:**
- In the Exercise 7.2 scratch folder, "Which javax packages move to jakarta in Spring Boot 3, and
  which stay?" now gets an answer from the power (for example, that `javax.sql` stays).
- A teammate, or a second Kiro profile, can install the power from your URL.
- `git status --short` in the workshop repository prints nothing: the shared `powers/` folder is
  unchanged.

**Commit:** nothing in the workshop repository; your power lives in `~/work/kiro-powers`.

**Why:** [registry powers worth knowing](why/07-scale-out-cli-web.md#73-extend-the-power-and-share-it)

## Workflows

**Workflows** are background, multi-step graphs of agent steps (sequences, loops, parallel branches).
They are opt-in in every client:

- **IDE:** **Workspace Configuration → Workflows** (in Agent Focus), or set
  `kiroAgent.workflows.enabled` in Settings; **then start a new chat session**. If Workflows is absent,
  it isn't available for your account yet.
- **CLI:** `/settings` → **Features**, then restart Kiro CLI.

**Stop doesn't undo file changes**, so run workflows on a branch.

**Why:** [how Workflows work, recipes, controls and limits](why/07-scale-out-cli-web.md#workflows)

### 7.4 A read-only investigation in the background

**Goal:** run a bundled recipe while you keep working in the main chat.

**Steps.** Back in the workshop's `sample-app/` workspace, enable Workflows and start a new chat
session (see above), then branch first:

```bash
git switch -c m7-workflow-lab
```

**Prompt** (Default agent)

```text
Run the investigate workflow. It must be read-only.
Find every place in this codebase whose behaviour depends on something that changed between Spring Boot 2.2
and 4.1: security defaults and CSRF rules, Bean Validation, Jackson configuration, trailing-slash matching,
test slices and mocking annotations. Report file:line evidence and a severity for each finding.
```

**Optional while it runs: the background single-agent variant**

While it runs, try the background single-agent variant in the main chat:

```text
Run the migration-reviewer agent in the background as a workflow on git diff stage-0..HEAD.
```

The docs describe this as the main agent launching `run_workflow(agent://<name>)`.


**Check**

```bash
git status --short
```

Expect no output (the runs are read-only). The runs appear above the parent chat; selecting a step
opens its own tab.

**Commit:** nothing to commit. Switch back with `git switch -`.

**Optional stretch: draft a recipe for your stage loop**

Ask Kiro to draft a recipe in `.kiro/workflows/` for your stage loop (investigate → plan → implement
→ review, repeated until `mvn -B verify` passes, with a `maxIterations` cap). Writes to
`.kiro/workflows/` always ask for approval. Recipes allow at most 8 nesting levels and 50 static step
nodes. Review the generated JSON like code before you run it.


## Rolling out to many services

Use this generic checklist to turn one successful migration into a repeatable program. Discuss it with
your table and adapt it.

### 7.5 Draft your rollout checklist

**Goal:** leave with a written plan you can take to your team.

**Steps.** Write down, for each item, an owner and a "done" signal:

1. **Inventory** every service (versions, `javax.*` imports, tests, packaging, CI, owner).
2. **Start with one representative service** with a usable test suite and an owner who reviews the
   pull requests; measure it (item 7).
3. **Stages per service:** latest line of the current major first, then one major at a time.
4. **Ship `.kiro/` in every repository**, with the reference deploy/push guard; decide per repository
   whether it stays on where Kiro Web delivers pull requests.
5. **Shared knowledge as a versioned power** (Exercise 7.3).
6. **Global steering** for individuals; Kiro Web doesn't read it.
7. **Metrics** per stage; "Tests run" must never drop.
8. **Guardrails outside git:** permission rules are per developer; never pre-approve deploy or push.
9. **CI everywhere:** Maven gates, Kiro explains.
10. **Plans and data:** confirm with your Kiro subscription owner.

**Why:** [the full checklist, with the inventory probe](why/07-scale-out-cli-web.md#75-draft-your-rollout-checklist)

**Check:** your checklist names an owner and a "done" signal for every item. The done signals should
be things you can check (a green build, a test count, a merged pull request), not opinions.

**Commit:** save the checklist wherever your team plans work.

## Extras (optional, outside the core time)

## Extra 7.A: headless `kiro-cli` in CI (20 minutes; GitHub and a paid plan)

### 7.A1 Give the service its own repository

**Goal:** create a repository whose root is the stage-3 service, with `.kiro/` at the top level.

**Why:** [why a separate repository](why/07-scale-out-cli-web.md#7a1-give-the-service-its-own-repository)

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

**Check**

```bash
ls -a ~/work/user-management-service
ls ~/work/user-management-service/.kiro ~/work/user-management-service/.kiro/hooks
```

Expect `pom.xml`, `src/` and `.kiro/` at the top level; `agents`, `hooks`, `skills` and `steering`
under `.kiro/`; and three hook files, including `block-deploy-and-push.json`, under `.kiro/hooks/`.

**Commit:** the push succeeded.

### 7.A2 Install the CLI and run it headless locally

**Goal:** run Kiro without an interactive session, with read-only tools, and read its exit code.

**Do**
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

**Copy: the readiness prompt**

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


3. Build, then pipe the prompt plus the Maven summary into Kiro on stdin (a documented pattern; Kiro
   doesn't need to read the git-ignored log file itself).

   ```bash
   mvn -B clean verify > build.log 2>&1
   { cat .github/kiro/readiness-prompt.txt; echo "## Maven summary"; grep -E 'Tests run:|\[ERROR\]|BUILD' build.log | tail -n 200; } | kiro-cli chat --v3 --no-interactive --trust-tools=read,grep > target/kiro-readiness-report.md
   echo "kiro-cli exit code: $?"
   ```

`--trust-tools=read,grep` keeps the run read-only: in headless runs, "ask" means deny.

**Why:** [what the flags and exit codes mean](why/07-scale-out-cli-web.md#7a2-install-the-cli-and-run-it-headless-locally)

**Check**

```bash
head -n 30 target/kiro-readiness-report.md
```

Expect a Markdown report with the five sections and exit code 0.

**Why:** [example report (yours will differ)](why/07-scale-out-cli-web.md#7a2-install-the-cli-and-run-it-headless-locally)

If authentication fails, export `KIRO_API_KEY` (next exercise) and run it again.

**Commit**

```bash
git add .github/kiro/readiness-prompt.txt
git commit -m "Add Kiro migration-readiness prompt"
```

### 7.A3 Create an API key and store it as a CI secret

**Goal:** authenticate CI without a browser.

**Do**
1. Sign in to [app.kiro.dev](https://app.kiro.dev) with your Pro, Pro+, Pro Max or Power account, open
   the **API Keys** section, create a key with a meaningful name, and copy it. The full value is shown
   only once.
2. Store it as the GitHub Actions secret `KIRO_API_KEY`: in the repository, open **Settings → Secrets
   and variables → Actions**, or run:

   ```bash
   gh secret set KIRO_API_KEY
   ```

**Why:** [things to know before you rely on an API key](why/07-scale-out-cli-web.md#7a3-create-an-api-key-and-store-it-as-a-ci-secret)

**Check:** `gh secret list` (or the Secrets page) shows `KIRO_API_KEY`.

**Commit:** nothing to commit. A secret never goes into git.

### 7.A4 A GitHub Actions job for a migration-readiness report

**Goal:** on every pull request, Maven decides pass/fail and Kiro explains the result in a readiness
report.

**Steps.** Create `.github/workflows/kiro-migration-readiness.yml` with the content below. This is an
example to adapt. The Kiro commands and flags come from the headless docs; check them against your
CLI version.

**Copy: the workflow file**

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


**Maven is the gate, Kiro is the explainer.** Treat pull request content as untrusted input: keep
`--trust-tools=read,grep` and `contents: read`.

**Why:** [design choices, variants, and a pre-workshop check for this job](why/07-scale-out-cli-web.md#7a4-a-github-actions-job-for-a-migration-readiness-report)

Then open a pull request:

```bash
git switch -c ci/kiro-readiness
git add .github/workflows/kiro-migration-readiness.yml
git commit -m "CI: Kiro migration-readiness report"
git push -u origin ci/kiro-readiness
gh pr create --fill
```

**Check:** in the pull request's **Checks** tab, the job runs. Its summary page shows the readiness
report, and the `kiro-readiness` artifact contains the report and `build.log`. A failed Kiro step logs
which exit-code branch fired (for example "Requested agent not found (exit 4)").

**Commit:** merge the pull request yourself once the job is green. Kiro never needs merge rights
for this.

## Extra 7.B: Kiro Web (15 minutes; GitHub or GitLab and a paid plan)

Kiro Web is a browser agent at [app.kiro.dev](https://app.kiro.dev). It clones your repository into
an isolated cloud sandbox, works there, and delivers the result as a pull request or merge request.
Kiro never merges automatically. A cloud session has no Supervised mode, checkpoints or revert, so
make every step end in a commit or pull request.

**Why:** [plans, region, what the sandbox reads, and limits](why/07-scale-out-cli-web.md#extra-7b-kiro-web-15-minutes-github-or-gitlab-and-a-paid-plan)

### Before the first Kiro Web task: turn off `block-deploy-and-push` in this repository

**Recommendation: disable the hook for the Kiro Web exercises.** Kiro Web applies the repository's
`.kiro/` hooks, and this hook blocks any agent shell call that runs `git push`. Kiro Web delivers its
pull requests itself and never merges, so you still review everything. Turn it off in
`user-management-service` only; `sample-app/` keeps it on.

> Unconfirmed: whether a workspace `PreToolUse` hook interferes with Kiro Web's pull request delivery is
> undocumented. If you test with the hook on, a delivery that fails with "Blocked by workspace policy"
> is the hook; if delivery works, record that and turn the hook back on. The command itself does exit 2
> on `git push` (checked as a plain shell command on Linux, outside Kiro; see the why page).

After merging the Exercise 7.A4 pull request:

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

### 7.B1 Connect the repository and trial-run the sandbox

**Goal:** before you trust Kiro Web with a migration task, find out what the sandbox can actually build.

**Do**
1. In app.kiro.dev, open **Settings** → **Agent** tab → **GitHub** → **Connect GitHub**. Authorize the
   **Kiro Agent** GitHub app and select `user-management-service`. You need write permission on the
   repository for Kiro to create branches and pull requests. GitLab is also supported.
2. Start a session on that repository and do a trial run. **The docs don't document a JDK or Maven
   runtime selector**, so check before you start real work.

**Why:** [how the sandbox configures itself](why/07-scale-out-cli-web.md#7b1-connect-the-repository-and-trial-run-the-sandbox)

**Prompt**

```text
Do not change any files and do not open a pull request.
Run java -version and mvn -v in the sandbox and show me the exact output.
Then run mvn -B verify and report the final Tests run / Failures / Errors / Skipped line.
List the steering files, custom agents and hooks you loaded from .kiro/.
```

**Check:** the output shows a Java 25 runtime, Maven, and a green build with the same test count as
your local run (14). The list usually names `migration-standards` and `migration-reviewer` (the
wording is model-dependent); the disabled `block-deploy-and-push` may be missing or marked disabled.

- If Java 25 or Maven is missing, or dependencies don't download, stop: review the sandbox's
  environment configuration and internet access (Maven must reach your Maven repository), then retry.
  Don't run migration work on a sandbox that can't build.

**Commit:** note the sandbox's Java and Maven versions in the repository README or your notes.

### 7.B2 A migration task in the sandbox

**Goal:** hand Kiro Web a well-scoped follow-up and get a pull request back.

**Steps.** Pick a **should-fix** or **nit** from your Module 5 review, or use the example below if your
app still has its hand-rolled error map.

**Prompt**

```text
Follow the steering in .kiro/steering. In ApiExceptionHandler, replace the hand-rolled error map with
Spring's ProblemDetail for 404 and validation errors. Keep every existing test and the X-Request-Id header.
Before you finish, use the migration-reviewer agent to review your diff, run mvn -B verify, and open a
pull request whose description lists the Tests run totals before and after.
```

Custom agents run only as sub-agents on Web, hence "use the migration-reviewer agent".

**Why:** [modes and custom agents on Kiro Web](why/07-scale-out-cli-web.md#7b2-a-migration-task-in-the-sandbox)

**Check**

- The pull request exists and the readiness job from Extra 7.A runs on it.
- Locally:

  ```bash
  git fetch origin
  git switch <kiro-branch>
  mvn -B clean verify
  ```

  The build is green and the test count is not lower.

**Commit:** review and merge the pull request yourself, or close it.

### 7.B3 Autonomous mode and `/kiro fix`

**Goal:** delegate an outcome end to end, then steer it from pull request review comments.

**Do**
1. Start a new session and toggle **Autonomous** in the chat input bar. It is off by default; you can
   switch it on before the first message or later.
2. Send the task below. If the agent needs an answer from you, the task moves to **Needs attention**.

**Why:** [what autonomous mode does](why/07-scale-out-cli-web.md#7b3-autonomous-mode-and-kiro-fix)

**Prompt**

```text
Add web-layer tests that pin the current security behaviour of this service: unauthenticated requests get 401,
authenticated GET /api/users works, authenticated POST /api/users with invalid input gets 400, and every
response carries X-Request-Id. Do not change production code. Run mvn -B verify and open a pull request.
```

3. On the pull request Kiro opened, leave a review comment on one of the new tests, for example "Use a
   descriptive @DisplayName". Then reply in that thread with `/kiro fix`; it addresses all comments in
   that conversation thread.

**Check:** a new commit addressing your comment appears on the pull request, and the readiness job runs
again.

**Commit:** you review and merge. Kiro never merges.

**Why:** [/kiro all, docs, and following a session from the terminal](why/07-scale-out-cli-web.md#7b3-autonomous-mode-and-kiro-fix)

## Check yourself

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
- [ ] A Kiro Web trial run confirmed the sandbox's Java and Maven before any real task.
- [ ] Kiro Web opened a pull request; you used autonomous mode and `/kiro fix` on a review thread.
- [ ] A bundled Workflow ran in the background and left the working tree unchanged.
- [ ] Your rollout checklist has owners and measurable done signals.

**Something went wrong?** [Scale-out (T-S01 to T-S13)](../docs/troubleshooting.md#s-scale-out-module-7) ·
power import → [T-K34](../docs/troubleshooting.md#t-k34-add-custom-power-rejects-the-folder-or-no-power-appears) ·
power never used → [T-K35](../docs/troubleshooting.md#t-k35-the-power-is-never-used) ·
skill ignored → [T-K33](../docs/troubleshooting.md#t-k33-a-skill-isnt-in-the--menu-or-is-ignored) ·
half-finished workflow edits → [T-X02](../docs/troubleshooting.md#t-x02-a-stopped-workflow-left-half-finished-edits)

## Next

- Keep [docs/quick-reference.md](../docs/quick-reference.md) and
  [docs/kiro-feature-reference.md](../docs/kiro-feature-reference.md) at hand when you apply this to a
  real service.
- Start your first service with Module 1's assessment steps: a Plan session first, then one Feature
  spec per stage.
