# Participant setup (before the workshop day: 60 to 120 minutes, mostly downloads)

Set up your machine before the day. Module 1 assumes you already have a green baseline build on JDK 8.
If you arrive without one, you lose most of Module 1.

> **Supported: macOS and Linux.** The workshop's hooks and the commands in every module are POSIX
> shell (`grep`, `sed`, `$(…)`, `1>&2`). On Windows, use a Linux VM or a cloud desktop. WSL2 is
> untested.

## What you'll do

0. One week before: sort out the things that take other people's time (plan, approvals, proxy).
1. Install three JDKs (8, 21, 25) and learn to switch between them.
2. Install Maven 3.9+, Git, Python 3, curl and (optionally) Docker.
3. Install Kiro IDE 1.x, sign in, put `kiro` on your PATH, and check your plan and credits.
4. Install the Java and Spring Boot extension packs from Open VSX.
5. Clone the repository.
6. Run the baseline build on JDK 8 and write down the test count.
7. Pre-download the dependencies and Maven plugins for every stage.
8. Open `sample-app/` in Kiro from a JDK 8 terminal, and trust it.
9. Check you are ready with one script.

## 0. One week before

These need someone else, so start them early:

- [ ] **A paid Kiro plan or an organization seat** for the full day: the Free plan's 50 credits run out
  well before the end (section 3, "Plans and credits").
- [ ] **On a managed corporate laptop:** ask your IT team about installer permissions, the network proxy
  and approval for JDK 21 and 25.
- [ ] **Network access** to download JDKs, Maven dependencies (Maven Central or your company mirror) and
  Kiro. Behind a proxy or mirror, prepare `~/.m2/settings.xml` (section 2).
- [ ] **macOS:** install the Xcode Command Line Tools (they bring `python3`; the install takes several
  minutes).
- [ ] **Optional labs only:** Module 4's appendix and Modules 6 and 7 list their own prerequisites at the
  top of each module. Module 7's Parts 2 and 3 need a GitHub account and a paid plan (API keys, Kiro
  Web), and, on an administered subscription, the admin to enable API keys and Cloud Sessions.

> Material checked against the Kiro docs on 2026-10-09. Kiro ships often. Where the UI differs from
> this page, the [Kiro docs](https://kiro.dev/docs/) win.

---

## 1. JDKs 8, 21 and 25

You need all three because the workshop moves the sample app in stages:

| JDK | Used in | Why |
|---|---|---|
| 8 | Module 1 (and the start of Module 2) | The baseline is Java 8 + Spring Boot 2.2.4. It must build on JDK 8. |
| 21 | Modules 2 and 3 (and the start of Module 4) | Spring Boot 2.7.18 and 3.5.x run on Java 21. |
| 25 | Modules 4 and 5 | Final target: Java 25 + Spring Boot 4.1. |

**Recommended distribution: Amazon Corretto.** Kiro's Java guide recommends "Amazon Corretto for a free,
production-ready distribution of OpenJDK". Any OpenJDK build of the same versions works. The guide
recommends JDK 17 or newer for everyday work; this workshop also needs JDK 8 because the starting point
is a Java 8 application.

- Downloads: <https://aws.amazon.com/corretto/>
- Docs: [Kiro Java guide](https://kiro.dev/docs/guides/languages-and-frameworks/java-guide/)

> **No JDK 25 approved yet?** Spring Boot 4.1 runs on Java 17 or later, so you can finish stage 3 on
> JDK 21 with `java.version` 21. You skip only the JDK switch (Module 4, Exercise 4.10; see its "No JDK 25" variant). Tell the instructor
> before the day (self-paced: use Module 4's "No JDK 25" variant).

Install the three JDKs with **one** of the options below.

### Option A: SDKMAN (macOS, Linux)

SDKMAN installs several JDKs side by side and switches them per terminal.

```bash
curl -s "https://get.sdkman.io" | bash
```

Open a new terminal, then list the Corretto builds (identifiers end in `-amzn`) and install the newest
8, 21 and 25 builds:

```bash
sdk list java | grep amzn
sdk install java <8.x-identifier>-amzn
sdk install java <21.x-identifier>-amzn
sdk install java <25.x-identifier>-amzn
```

Replace each `<…-identifier>` with the exact value shown by `sdk list java`.

### Option B: installers (macOS, Linux)

Download the Corretto 8, 21 and 25 packages for your OS and CPU from <https://aws.amazon.com/corretto/>.
On macOS use the `.pkg` files. On Linux use the `.deb` or `.rpm` packages; they usually install under
`/usr/lib/jvm/` (check with `ls /usr/lib/jvm`).

### Switch the JDK per terminal

Maven uses the JDK that `JAVA_HOME` points to. Switching per terminal lets you keep, for example, a
JDK 8 terminal and a JDK 21 terminal open at the same time.

**SDKMAN:**

```bash
sdk use java <8.x-identifier>-amzn
```

`sdk use` changes the current terminal only. `sdk default java <identifier>` changes the default for
new terminals.

**macOS without SDKMAN:** `/usr/libexec/java_home` finds installed JDKs by version.

```bash
/usr/libexec/java_home -V
export JAVA_HOME=$(/usr/libexec/java_home -v 1.8)
export PATH="$JAVA_HOME/bin:$PATH"
```

Java 8 registers as version `1.8`; later JDKs use their major number, for example
`/usr/libexec/java_home -v 21` or `-v 25`. A small helper in `~/.zshrc` saves typing:

```bash
jdk() { export JAVA_HOME=$(/usr/libexec/java_home -v "$1"); export PATH="$JAVA_HOME/bin:$PATH"; java -version; }
```

Then run `jdk 1.8`, `jdk 21` or `jdk 25` in any terminal.

**Linux without SDKMAN:** point `JAVA_HOME` at the JDK folder.

```bash
ls /usr/lib/jvm
export JAVA_HOME=/usr/lib/jvm/<jdk-folder>
export PATH="$JAVA_HOME/bin:$PATH"
```

A helper in `~/.bashrc` (or `~/.zshrc`): `jdk() { export JAVA_HOME="/usr/lib/jvm/$1"; export PATH="$JAVA_HOME/bin:$PATH"; java -version; }`,
then `jdk <jdk-folder>`. `update-alternatives --config java` changes only the system-wide `java`
command; Maven prefers `JAVA_HOME` when it is set, so set `JAVA_HOME`.

### Change the JDK for Kiro (Modules 2 and 4, and after a reset)

Two words matter here:

- **Active**: the JDK of *this* terminal (`sdk use …`, or `export JAVA_HOME=…` typed in the terminal).
- **Default**: the JDK every *new* terminal gets (`sdk default java …`, or the `export JAVA_HOME=…` line
  in `~/.zshrc` or `~/.bashrc`).

The Kiro agent and the hooks run commands with the environment Kiro was started with, and Kiro's own
terminals start as new terminals. So whenever the workshop changes the JDK (in Module 2, in Module 4,
and after a reset):

1. Make the new JDK the **default**.
2. Quit Kiro completely.
3. Open a new terminal in `sample-app/`, check `mvn -v`, and start Kiro with `kiro .`.
4. Ask the agent to run `mvn -v`: it must show the same Java version.

`../scripts/check-env.sh --stage N` (from `sample-app/`) checks that `java` and Maven agree. After the
workshop, set your usual default JDK again.

### Verify

```bash
java -version
```

Look for `1.8.0_…` in a JDK 8 terminal. Switch to 21 and 25 and confirm each reports its version.

---

## 2. Maven 3.9+, Git, Python 3, curl, optional Docker

| Tool | Version | Install | Check |
|---|---|---|---|
| Maven | 3.9 or later | <https://maven.apache.org/download.cgi>, SDKMAN (`sdk install maven`), or your package manager | `mvn -v` |
| Git | 2.23 or later (for `git switch`) | <https://git-scm.com/downloads> or your package manager | `git --version` |
| Python 3 | any 3.x | macOS: comes with the Xcode Command Line Tools (the first `python3` offers to install them; do it before the day). Linux: your package manager | `python3 --version` |
| curl | any | Preinstalled on macOS; Linux: your package manager | `curl --version` |
| Docker | any current version, **optional** | Docker Desktop or another container runtime | `docker compose version` |

Modules 5 and 7 use `python3` for small JSON checks, and Modules 2–4 use `curl` to call the running
app. Docker is only needed if you want to run the sample app against PostgreSQL
(`docker-compose.yml`). The default database is in-memory H2, so the workshop works without Docker.

### Verify

```bash
mvn -v
git --version
python3 --version
curl --version
```

`mvn -v` prints the Maven version **and** the Java version Maven runs on. In a JDK 8 terminal, look for
`Apache Maven 3.9.…` and `Java version: 1.8.0_…`.

**Behind a corporate proxy or mirror?** Configure `~/.m2/settings.xml` (proxy or mirror) before the
day. The first build downloads many dependencies.

---

## 3. Kiro IDE 1.x

### Install

Follow the official installation page: <https://kiro.dev/docs/getting-started/installation/>.

- Kiro IDE runs on macOS (Intel and Apple Silicon) and Linux (Ubuntu 24+, Debian 13+, Fedora 40+,
  Arch, Mint 22+) on x86_64 or ARM64. It also runs on Windows 10/11, but this workshop doesn't support
  Windows (see the note at the top).
- Download the installer from kiro.dev and run it.
- Use the current **1.x** release. Kiro updates itself in the background. To check manually, open the
  Kiro menu → **Check for Updates…** (macOS), or run **Kiro: Check for Updates** from the Command
  Palette (Linux).
- Behind a proxy: Kiro respects `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY`, and has **Settings > Proxy**.
  Browser-based sign-in uses your operating system's network stack, not the IDE proxy settings.

Docs: [Installation](https://kiro.dev/docs/getting-started/installation/) ·
[Setup & First Run](https://kiro.dev/docs/ide/setup/)

### First launch and sign-in

On first launch Kiro walks you through:

1. **Sign in** with Google, GitHub, AWS Builder ID, or your organization's identity provider. If your
   company provides Kiro seats, use the organization sign-in your admin gave you.
2. **Import settings** (optional) from VS Code.
3. **Choose a theme.**
4. **Shell integration**: allow it. The agent needs it to run commands such as `mvn` for you.

Docs: [Authentication](https://kiro.dev/docs/getting-started/authentication/)

### Put the `kiro` command on your PATH

You start Kiro from a terminal with `kiro .`, so the `kiro` command must be on your PATH. Linux packages
usually install it. On macOS, Code OSS-based editors offer a Command Palette action such as **Shell
Command: Install 'kiro' command in PATH**.

> Unconfirmed: the exact name of that action in your Kiro build.

Check it in a new terminal: `command -v kiro` prints a path.

### Plans and credits

Agent work in Kiro is metered in **credits**. Read this before the day so you don't run out at lunch.

| Plan | Price (per user / month) | Credits | Notes |
|---|---|---|---|
| Free | $0 | 50 | Open-weight models and Claude Sonnet 4.5, subject to rate limits |
| Pro | $20 | 1,000 | Premium models; add-on credits at $0.04 each |
| Pro+ | $40 | 2,000 | As Pro |
| Pro Max | $100 | 5,000 | As Pro |
| Power | $200 | 10,000 | As Pro |

Source: [kiro.dev/pricing](https://kiro.dev/pricing/), checked 2026-10-09. Prices change; the pricing page wins.

What this means for a full workshop day:

- Per the pricing page, "simple prompts can consume less than 1 credit. More complex prompts, such as
  executing a spec task, typically cost more than 1 credit." Prompts, spec refinement, task execution
  and agent-prompt hooks all use credits. Shell-command hooks (the kind this workshop ships) do not.
- Kiro does not publish a per-module figure. Your instructor may share the figure from their own test run.
  Modules 2 to 5 generate and run several specs with many tasks each. **Expect 50 credits to run out
  well before the end of the day.** Use a paid plan (Pro or higher) or a seat from your organization
  for the full day.
- Monthly plan credits reset at the start of each billing month and do not roll over. Add-on credits
  are available on paid plans only.
- The model you pick changes the cost. Credit multipliers are relative to **Auto** (1.0x). For example,
  per the models page, Claude Opus 5.5 is 2.0x and Claude Haiku 4.5 is 0.4x. Multipliers change often;
  check [the models page](https://kiro.dev/docs/models/) on the day.
- You can see your plan's monthly limit, credits used and credits remaining in the subscription
  dashboard inside Kiro. The pricing page says usage updates at least every 5 minutes.
- The Free tier is not available for Kiro Enterprise (organization sign-in) or AWS GovCloud (US).
  Those require a paid plan.

Docs: [Pricing](https://kiro.dev/pricing/) · [Models](https://kiro.dev/docs/models/)

### Data handling: which account to use

Per Kiro's data-protection page, content from **Kiro enterprise users is not used for service
improvement**. Content from **Free Tier users and individual subscribers** (including paid plans with
GitHub, Google or Builder ID sign-in) may be used, for example for model training, unless you opt out.

The sample app contains no proprietary code, so a personal account is fine for the workshop. Do
**not** paste your company's code into a personal account. See the page below for how to opt out.

Docs: [Data protection](https://kiro.dev/docs/privacy-and-security/data-protection/)

---

## 4. Java extensions from Open VSX

Kiro is built on a VS Code foundation and uses the Open VSX extension registry by default. Kiro's Java
guide recommends these extensions:

1. Open the **Extensions** view.
2. Search for and install **Extension Pack for Java**.
3. Search for and install **Spring Boot Extension Pack**.

These give you Java language support, Maven integration and Spring Boot tooling in the editor. They are
optional for the agent, which works through files and Maven, but they make reviewing its changes easier.

The terminal build (`mvn -B clean verify`) is the source of truth in this workshop. If the editor shows
red squiggles while Maven reports `BUILD SUCCESS`, trust Maven.

Docs: [Extension registry](https://kiro.dev/docs/ide/editor/extension-registry/) ·
[Java guide](https://kiro.dev/docs/guides/languages-and-frameworks/java-guide/)

---

## 5. Clone the repository

In any terminal:

```bash
git clone https://github.com/timwukp/Java-framework-upgrade-workshop-v2.git
cd Java-framework-upgrade-workshop-v2
```

If your instructor sends you a different URL (for example your organization's fork), use that.
Don't change anything in `sample-app/`: every outdated pattern in it is an exercise.

---

## 6. Baseline build on JDK 8

In a terminal where JDK 8 is active (section 1), from the repository folder:

```bash
cd sample-app
java -version
mvn -v
mvn -B clean verify
```

What to look for:

1. `java -version` and the `Java version:` line of `mvn -v` both show **1.8.0_…**.
2. Near the end of the `mvn -B clean verify` output, the test summary under `Results:` reads
   `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0` (9 tests in `UserServiceTest`, 5 in
   `UserControllerTest`).
3. The last lines show **`BUILD SUCCESS`**.

**Write down the "Tests run" total you see.** The expected number is 14 at every stage, but you read
your own number at every check. If yours isn't 14, see
[T-A14](troubleshooting.md#t-a14-the-baseline-test-count-isnt-14). From Module 2 on, a migration
step is done only if the build passes **and** the test count did not go down. Some upgrades make tests
silently stop running while the build stays green.

To see only the end of the output:

```bash
mvn -B clean verify | tail -n 30
```

The same check as one command, which also fails if fewer than 14 tests ran (used from Module 1 on):

```bash
../scripts/verify-stage.sh 0
```

Optional: start the app and call the API as described in [`sample-app/README.md`](../sample-app/README.md).

---

## 7. Pre-download the dependencies for every stage

Each stage uses a new Spring Boot line. Each one needs a fresh set of dependencies and Maven plugins,
often hundreds of megabytes. Downloading them during the workshop, on a shared network, is the most
common reason participants fall behind. Run the commands below once, at home or on the office network.
They fill your local Maven cache (`~/.m2/repository`) and confirm that your machine can build every
stage. They don't change your `sample-app/` workspace.

Run them from the repository root, with the JDK shown above each group active in that terminal.

**JDK 21:**

```bash
mvn -B -f solutions/stage-1-boot27-java21/pom.xml clean verify dependency:tree
```

```bash
mvn -B -f solutions/stage-2-boot35-java21/pom.xml clean verify dependency:tree
```

```bash
mvn -B dependency:get -Dartifact=org.springframework.boot:spring-boot-properties-migrator:3.5.16
```

**JDK 25:**

```bash
mvn -B -f solutions/stage-3-boot41-java25/pom.xml clean verify dependency:tree
```

No JDK 25? Run the same command in the JDK 21 terminal with `-Djava.version=21` added. Verified in
the 2026-10-10 dry run (Corretto 21): this passes, and so does `java.version` 21 set in that `pom.xml`.

**JDK 8** (the dependency plugin the sample app uses from Module 1 on):

```bash
mvn -B -f sample-app/pom.xml dependency:tree
```

Every command should end with `BUILD SUCCESS`. Then check the cache:

```bash
ls ~/.m2/repository/org/springframework/boot/spring-boot/
```

Look for `2.2.4.RELEASE`, `2.7.18`, `3.5.16` and `4.1.1` (more versions are fine). Verified in the
2026-10-10 dry run (Linux, Corretto, Maven 3.9.11): the `dependency:tree` and `dependency:get` commands
succeed and the cache then lists these four versions.

If one fails, tell the instructor before the day (self-paced: open an issue on the repository) and
include the last 30 lines of output. It usually means a proxy or mirror problem, or the wrong JDK.
Occasionally it is a problem in the reference solution itself, which the instructor needs to know
about.

---

## 8. Open `sample-app/` in Kiro and trust it

### Start Kiro from a JDK 8 terminal

Make **JDK 8 the default** for new terminals (section 1), then quit Kiro if it is running, open a new
terminal and start Kiro from `sample-app/`:

```bash
cd Java-framework-upgrade-workshop-v2/sample-app    # from the folder you cloned into
mvn -v
kiro .
```

`mvn -v` must show `Java version: 1.8.0_…`. In Module 1 you ask the agent to run `mvn -v` to confirm it
sees JDK 8 too. Docs: [Your first project](https://kiro.dev/docs/getting-started/first-project/)

### Open `sample-app/`, not the repository root

`kiro .` from inside `sample-app/` opens the right folder with your terminal's JDK. **File > Open
Folder** → `sample-app` also opens it, but Kiro then may not use your terminal's JDK (section 1).

Why this folder:

- `sample-app/.kiro/` holds the workshop's steering files, hooks, custom agent and two skills
  (`jakarta-namespace-migration`, `spring-security-lambda-dsl`). Kiro loads workspace configuration
  from the `.kiro/` folder of the workspace you open.
- The reference solutions live in `solutions/` at the repository root, **outside** the workspace, so
  the agent doesn't read or copy them when it searches your codebase.

### Trust the workspace

Kiro treats every workspace as **untrusted** until you trust it. When Kiro asks whether you trust
`sample-app`, choose to trust it.

Why it matters. Until a workspace is trusted, Kiro:

- does **not** load the workspace's custom agents, steering files, MCP server configuration or skills
  (and not its workflow files);
- asks before **every** shell command, even when a saved rule allows it;
- asks before writing to `.kiro/steering` or `.kiro/skills`.

This protects you from a cloned repository that tries to change how the agent behaves. Your trust
decision is stored outside the workspace, so a repository can't trust itself. You trust this one
because the workshop's `.kiro/` content is what you are here to learn.

> Unconfirmed: the exact wording and position of the trust prompt in your Kiro build. The docs describe
> what trust does, not the button. If you dismissed the prompt, check the
> [Workspace trust](https://kiro.dev/docs/permissions/) section of the docs.

Docs: [Permissions: workspace trust](https://kiro.dev/docs/permissions/)

### Verify

1. Click the **Kiro ghost icon** in the activity bar to open the Kiro panel. It has sections for Specs,
   Agent Hooks, Steering and MCP Servers.
2. Under **Steering** you should see `migration-standards`, `migration-playbook`, `pom-rules` and
   `test-rules`.
3. Under **Agent Hooks** you should see `verify-after-spec-task` (enabled) and `jakarta-import-guard`
   (disabled). Leave both as they are; the modules tell you when to change them.
4. Open the chat (Cmd+L on macOS, Ctrl+L on Linux) and type `/`. The menu should list
   `migration-playbook` among the slash commands.

If the steering files are missing, the workspace is not trusted, or you opened the repository root
instead of `sample-app/`.

---

---

## 9. Am I ready?

From `sample-app/`, in a JDK 8 terminal:

```bash
../scripts/check-env.sh
```

Every line should say `PASS`. A `WARN` for JDK 25 is fine if you will use Module 4's "No JDK 25"
variant; any other `WARN` or `FAIL` names what to fix. Then tick off what a script can't see:

- [ ] Kiro IDE 1.x is installed, you are signed in, and shell integration is enabled.
- [ ] You have a paid plan or an organization seat for the full day, and know your credit allowance.
- [ ] Extension Pack for Java and Spring Boot Extension Pack are installed.
- [ ] Kiro was started from a JDK 8 terminal with `kiro .`; `sample-app/` is open and trusted; the four
  steering files and both hooks appear in the Kiro panel.
- [ ] `mvn -B clean verify` on JDK 8 ended with `BUILD SUCCESS`, and you wrote down the "Tests run"
  total (expected: 14).
- [ ] The section 7 commands succeeded.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `mvn -v` shows Java 21 or 25 in your "JDK 8" terminal | [T-A01](troubleshooting.md#t-a01-mvn--v-shows-the-wrong-java-in-your-terminal) |
| The agent's `mvn -v` shows another JDK than your terminal | [T-A02](troubleshooting.md#t-a02-the-agents-or-the-hooks-java-is-not-your-terminals) |
| `kiro: command not found` | [T-A03](troubleshooting.md#t-a03-kiro-command-not-found) |
| The baseline fails on a newer JDK with a Lombok `IllegalAccessError` | [T-B06](troubleshooting.md#t-b06-lombok-illegalaccesserror-lombokprocessor-cannot-access-javacprocessingenvironment) |
| `/usr/libexec/java_home -v 1.8` finds no JVM | [T-A04](troubleshooting.md#t-a04-usrlibexecjava_home--v-18-cant-find-a-matching-jvm) |
| `python3` opens an "install developer tools" dialog | [T-A05](troubleshooting.md#t-a05-python3-opens-an-install-command-line-developer-tools-dialog-macos) |
| Dependency downloads fail or time out | [T-A06](troubleshooting.md#t-a06-dependency-downloads-fail-or-time-out) |
| macOS says Kiro "is damaged" | [T-A07](troubleshooting.md#t-a07-macos-says-kiro-is-damaged-or-cant-be-opened) |
| The sign-in page doesn't load behind a proxy | [T-A08](troubleshooting.md#t-a08-the-sign-in-page-doesnt-load-behind-a-proxy) |
| The agent can't run commands, or `#terminal` is empty | [T-A09](troubleshooting.md#t-a09-the-agent-cant-run-commands-or-terminal-is-empty) |
| Steering files don't appear in the Kiro panel | [T-K01](troubleshooting.md#t-k01-steering-files-custom-agents-or-skills-dont-appear) |
| The editor shows Java errors, but Maven succeeds | [T-A10](troubleshooting.md#t-a10-the-editor-shows-java-errors-but-mvn--b-clean-verify-succeeds) |
| You run out of credits | [T-A11](troubleshooting.md#t-a11-you-run-out-of-credits-during-the-day) |
| `docker compose up` fails | [T-A12](troubleshooting.md#t-a12-docker-compose-up-fails) |

More: [all workshop symptoms and fixes](troubleshooting.md) · [Kiro IDE troubleshooting](https://kiro.dev/docs/ide/troubleshooting/)

## Next

Bring your laptop, charger and your "Tests run" number. The day starts with
[Module 1: Setup and assessment](../modules/01-setup-and-assessment.md).
