# Java Modernization Workshop with Kiro

A one-day, hands-on workshop: take a legacy **Java 8 + Spring Boot 2.2** service to
**Java 25 + Spring Boot 4.1 (Spring Framework 7)** in safe, verifiable stages, using
[Kiro](https://kiro.dev) specs, steering, hooks, skills, custom agents and powers.

> Material checked against the official Kiro documentation and Spring/Java support data on
> **2026-10-09**. Kiro ships frequently; where the UI differs from these instructions, the
> [Kiro docs](https://kiro.dev/docs/) win.

## What you will learn

- Plan a framework migration with a **Plan** session and a **Feature spec** (requirements → design → tasks).
- Encode team standards as **steering** (`always`, `fileMatch`, `manual`) so the agent follows them.
- Let **hooks** run one `mvn -B clean verify` after every spec task (and report the test count), and
  catch `javax.*` imports the agent leaves behind.
- Package repeatable know-how as **skills** and a **power**, and use a **custom agent** as a reviewer.
  It has no `write` tool and is instructed not to modify files; you still check `git status` after a review.
- Spot the migration traps that don't break the build and only show up later: validation that
  silently stops, tests that silently stop running, security rules that change meaning, and a
  Jackson 3 change that rejects valid create requests.

## The staged path

| Stage | Module | Java | Spring Boot | Spring Framework | Why this stop |
|---|---|---|---|---|---|
| 0 | 1 | 8 | 2.2.4 | 5.2.3 | Baseline. Boot 2.2.4 is documented as compatible up to Java 13 (the last 2.2 patch, 2.2.13, up to Java 15); never Java 21: on JDK 21 the build fails with Lombok 1.18.10's `IllegalAccessError`. |
| 1 | 2 | 21 | 2.7.18 | 5.3.x | Last 2.x line; still `javax.*`; runs on Java 21. |
| 2 | 3 | 21 | 3.5.x | 6.2.x | Jakarta EE namespace, Spring Security 6. A waypoint: OSS support ended 2026-06-30. |
| 3 | 4 | 25 | 4.1.x | 7.0.x | Target. Jakarta EE 11, Jackson 3, Spring Security 7, Java 25 LTS. |

Support dates: [endoflife.date: Spring Boot](https://endoflife.date/spring-boot),
[Spring Framework](https://endoflife.date/spring-framework), [Java](https://endoflife.date/oracle-jdk).

## What Kiro does here, and what it doesn't

Kiro has **no one-click "upgrade Java" transformation**. In this workshop the agent does the
migration under your direction:

1. A spec turns "upgrade to Boot 3.5" into reviewed requirements, a design, and a task list.
2. The agent executes the tasks. Steering and skills tell it how; Supervised mode lets you review every hunk.
3. A hook runs one clean Maven build after each task and reports the test count, or the failure, back
   to the agent.
4. You commit each stage, so you can always return to a known-good state.

Deterministic tools such as OpenRewrite recipes or the AWS Transform power can do the bulk mechanical
changes. Module 4's optional appendix (outside the core time box) covers them, including their
prerequisites and licensing notes.

## Quick start

On macOS or Linux, in a terminal where JDK 8 is active (see [participant-setup.md](docs/participant-setup.md)):

```bash
git clone <this-repository-url>
cd <repository>/sample-app
mvn -B clean verify    # expect Tests run: 14 and BUILD SUCCESS
kiro .                 # opens sample-app/ as the Kiro workspace, with this terminal's JDK
```

The workspace is the **`sample-app/` folder**, not the repository root. Trust it, then start
[Module 1](modules/01-setup-and-assessment.md). Whenever you change the active JDK, quit Kiro and start
it again from that terminal with `kiro .`.

## Repository layout

```text
README.md
docs/
  agenda.md                  Timetable, what to skip if running late
  participant-setup.md       Install JDK 8/21/25, Maven, Kiro; baseline build
  instructor-guide.md        Dry run, run of show, room control, troubleshooting
  quick-reference.md         Kiro and migration cheat sheet
  kiro-feature-reference.md  Every Kiro feature used, with its docs link
  verification-log.md        What the dry runs verified, and what is still unverified
modules/
  01-setup-and-assessment.md
  02-runway-boot27-java21.md
  03-spring-boot-3.md
  04-spring-boot-4-java25.md
  05-quality-gates.md
  06-platform-deployment.md   (optional)
  07-scale-out-cli-web.md     (optional)
sample-app/                  Open this folder in Kiro. The legacy starting point (stage 0).
  .kiro/steering/            migration-standards, migration-playbook, pom-rules, test-rules
  .kiro/hooks/               verify-after-spec-task, jakarta-import-guard
  .kiro/agents/              migration-reviewer
  .kiro/skills/              jakarta-namespace-migration, spring-security-lambda-dsl
powers/java-modernization/   A Kiro power (Agent Plugins format) imported in Module 4
solutions/                   Reference state after stages 1, 2 and 3, and the one reset procedure
                             (outside the workspace on purpose)
```

## Prerequisites

- **macOS or Linux.** The hooks and the commands in the modules are POSIX shell. On Windows, use a
  Linux VM or a cloud desktop (WSL2 is untested).
- JDK 8, 21 and 25 (for example [Amazon Corretto](https://aws.amazon.com/corretto/)), Maven 3.9+, Git,
  `python3` and `curl`
- [Kiro IDE](https://kiro.dev/docs/getting-started/installation/) 1.x and an account. A full day
  uses more than the Free plan's monthly credits; see [participant-setup.md](docs/participant-setup.md).
- Comfortable reading Java and Spring code. No prior Kiro experience needed.

## Security notes

- No passwords are stored in this repository. The sample app generates in-memory user passwords at
  startup unless you set `APP_ADMIN_PASSWORD` / `APP_USER_PASSWORD`.
- Kiro permission rules are per user. Pre-approve `mvn *` for this workspace when prompted, and never
  pre-approve deploy or push commands.

## License

[MIT](LICENSE)
