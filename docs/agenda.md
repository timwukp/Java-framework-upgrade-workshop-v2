# Workshop agenda

**Format:** one day, hands-on, 8 hours core (09:00–17:00) plus two optional modules.
**Goal:** migrate a legacy Java 8 + Spring Boot 2.2 service to **Java 25 + Spring Boot 4.1 (Spring
Framework 7)** in safe, verifiable stages, using Kiro's specs, steering, hooks, skills, custom agents and
powers.
**Platform:** macOS or Linux (on Windows, a Linux VM or cloud desktop; WSL2 is untested).

## Before the day

Every participant completes [participant-setup.md](participant-setup.md):

- the baseline build on JDK 8 (`mvn -B clean verify`, expected `Tests run: 13`), with Kiro started from
  that JDK 8 terminal with `kiro .`;
- section 7, the pre-download for every stage. Check it with
  `ls ~/.m2/repository/org/springframework/boot/spring-boot/`, which must list `2.2.4.RELEASE`,
  `2.7.18`, `3.5.16` and `4.1.1`.

A participant who arrives without a green baseline loses most of Module 1. One who skipped the
pre-download falls behind at the first build of each new Spring Boot line.

## Core day

| Time | Session | Stage reached | Kiro features introduced |
|---|---|---|---|
| 09:00–09:15 | Welcome and pre-flight check ([instructor guide](instructor-guide.md#5-room-control)): why staged migrations, what Kiro does and does not do | — | — |
| 09:15–10:15 | [Module 1 — Setup and assessment](../modules/01-setup-and-assessment.md) (60 min) | 0 (baseline, tagged) | Workflows (Plan), context providers, Supervised mode, permissions, steering, checkpoints |
| 10:15–10:30 | Break | | |
| 10:30–12:00 | [Module 2 — Runway: Spring Boot 2.7 + Java 21](../modules/02-runway-boot27-java21.md) (90 min) | 1 | Feature spec (requirements → design → tasks), Run all Tasks, PostTaskExec hook |
| 12:00–13:00 | Lunch | | |
| 13:00–14:45 | [Module 3 — Spring Boot 3.5 and Jakarta EE](../modules/03-spring-boot-3.md) (105 min) | 2 | Skills (use one, write one), PostFileSave guard hook, Quick Spec |
| 14:45–15:00 | Break | | |
| 15:00–16:20 | [Module 4 — Spring Boot 4.1 and Java 25](../modules/04-spring-boot-4-java25.md) (80 min) | 3 (target) | Powers (Agent Plugins format), Plan with a power |
| 16:20–16:50 | [Module 5 — Quality gates](../modules/05-quality-gates.md) (30 min: 8 / 7 / 5 / 10) | 3 (verified) | Custom agent and sub-agent (8), natural-language PreToolUse hook (7), Bugfix spec as an instructor demo (5), final verification and tag (10) |
| 16:50–17:00 | Wrap-up: lessons learned, how to apply this to your own services | | |

Instructor demos are **inside** these time boxes and take at most 5 minutes each. Module 4's appendix
(AWS Transform power with MCP, OpenRewrite) is optional and outside its 80 minutes.

## Optional extended sessions

| Duration | Session | Notes |
|---|---|---|
| 60 min | [Module 6 — Platform deployment](../modules/06-platform-deployment.md) | Containers, WAR deployment to JBoss EAP / WildFly and WebSphere / Open Liberty, z/OS considerations |
| 60 min | [Module 7 — Scale out: Powers, CLI and Kiro Web](../modules/07-scale-out-cli-web.md) | Sharing a Power, headless `kiro-cli` in CI, Kiro Web pull requests, Workflows |
| Self-paced | [Module 4 appendix](../modules/04-spring-boot-4-java25.md#appendix-optional-outside-the-80-minutes-accelerators) | AWS Transform power and OpenRewrite; needs its own prerequisites (listed there) |

## Reset points

A participant who falls behind continues from the reference state of the previous stage with the one
procedure in [solutions/README.md](../solutions/README.md) ("Reset your workspace to a stage"), run
from `sample-app/`. Its rows set the JDK, the tag and the hook states for the module you start. The
[instructor guide](instructor-guide.md#5-room-control) says when to use it.

## If you run late

Each module's own "If you run late" note wins; in short:

- **Module 1:** in Part 1 skip the Exercise 1.3 prompt. In Part 5, combine prompts C and D into one
  message. Fix `tech.md` (Exercise 4.2, step 4) during the break.
- **Module 2:** skip Part 4 and the optional `curl` check in Part 3. More than 15 minutes behind at the
  start of Part 3: reset to stage 1 (row "Module 3"), then do only step 2 of Exercise 5.1.
- **Module 3:** skip the optional Exercises 2.4 and 3.1. In Part 5, copy the reference skill instead of
  writing it (the Exercise 5.1 fallback) and write your own after the workshop. In Part 6, skip the
  reference diff.
- **Module 4:** the instructor demos the power import (Exercise 1.2, at most 5 minutes). Skip the app
  start in Exercise 4.3 but keep its class-file and dependency checks. Never skip the test-count checks
  or the `stage-3` tag.
- **Module 5:** Part 1 and Part 4 only. Do Part 2 and the optional Bugfix lab afterwards.
