# Workshop scripts

Small helpers for the commands you would otherwise type many times a day. Run them from
**`sample-app/`** (your Kiro workspace) as `../scripts/<name>.sh`. They live outside the workspace,
like `solutions/`, so the Kiro agent doesn't pick them up.

Every script prints each command before it runs it, so you can see (and copy) what it does. They
never commit, tag, switch your JDK, restart Kiro or change hooks: those steps are part of the
workshop, so you type them yourself. None of them stores or prints a password.

| Script | Use it to | Example |
|---|---|---|
| `check-env.sh [--stage N]` | Check you are ready: OS, Git, Maven, Python, curl, the JDK of this terminal and of Maven, installed JDKs, the Maven cache, steering files, hook files. No build. | `../scripts/check-env.sh` |
| `verify-stage.sh N [--jdk 8\|21]` | Prove a stage is finished: right JDK and parent, one clean build, `Tests run: 14, Failures: 0, Errors: 0, Skipped: 0`, class files for the right Java version. A green build with fewer tests **fails**. | `../scripts/verify-stage.sh 1` |
| `compare-stage.sh N` | Compare your `pom.xml` and `src/` with the reference solution of stage 1, 2 or 3. Changes nothing. | `../scripts/compare-stage.sh 2` |
| `reset-to-stage.sh 0\|1\|2\|3\|3-final` | Catch up when you are behind: replace `pom.xml` and `src/` with a reference state, then print the steps for you to type. Refuses if you have uncommitted changes. | `../scripts/reset-to-stage.sh 2` |
| `smoke.sh [--stage N] [--base-url URL]` | Call the running app with the workshop's checks (401, 200, 400, 201, 404, duplicate e-mail, `X-Request-Id`, trailing slash). Reads the password from `APP_ADMIN_PASSWORD`. | `../scripts/smoke.sh` |

`verify-stage.sh` options: `--jdk 8` checks stage 1 before the JDK switch (Module 2, Phase A);
`--jdk 21` checks stage 3 without JDK 25 (Module 4's "No JDK 25" variant). It writes the full Maven
log to `verify-stage.log` (ignored by git). Run it only when no hook or agent build is running:
builds share `target/`.

For `smoke.sh`, set the password in the terminal that starts the app **and** in the one that runs
the script (choose any local value; it is never stored):

```bash
printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD
```

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Passed |
| 1 | A check failed (build red, wrong test count, wrong version, differences found) |
| 2 | Wrong arguments |
| 3 | Wrong environment: not in `sample-app/`, wrong JDK, a tool missing, the app not running, no password |
| 4 | Refused: uncommitted changes, or you didn't type `yes` |

## Requirements

macOS or Linux, POSIX `sh`, and the tools from the [participant setup](../docs/participant-setup.md).
Symptoms and fixes: [troubleshooting](../docs/troubleshooting.md).
