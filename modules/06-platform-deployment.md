<!-- runbook max-lines=610 -->
# Module 6 (optional): Deploying outside the embedded server (60 minutes)

Optional module · [← Module 5](05-quality-gates.md) · [Module 7 (optional) →](07-scale-out-cli-web.md) ·
[Day sheet](../docs/quick-reference.md) · [Troubleshooting](../docs/troubleshooting.md) ·
[Why and background](why/06-platform-deployment.md)

At the end of Module 4 your app runs on Java 25 with Spring Boot 4.1 (Spring Framework 7, Jakarta EE 11,
Servlet 6.1) and starts with `java -jar`. In production, many enterprises deploy instead to a container
platform, a Jakarta EE application server, or a mainframe. This module takes the same app to several
**common enterprise deployment targets**: a container image, JBoss EAP / WildFly, Open Liberty /
WebSphere Liberty, and z/OS. The targets are generic examples. Pick the ones that match your
environment and skip the others.

The one rule for the whole module: **Spring Boot 4 needs a Servlet 6.1 (Jakarta EE 11) container.**
A server that implements an older level can't run the Boot 4 WAR, however the WAR is packaged. Check the
support matrix before you spend time on packaging.

## At a glance

| | |
|---|---|
| **Goal** | The stage-3 app on the targets you use: a container image (the default), a WAR on a Jakarta EE 11 server, and z/OS notes, each with its own steering file |
| **Time** | 60 minutes; pick the targets that match your environment and skip the others |
| **Start** | Branch `workshop` at or after tag `stage-3` (or `stage-3-final`), JDK 25, `Tests run: 14`; trusted workspace, `mvn *` on Always allow. Behind? `../scripts/reset-to-stage.sh 3-final` |
| **Hooks** | `verify-after-spec-task` **on**, `jakarta-import-guard` **on**, and `block-deploy-and-push` **on** if you built it in Module 5 (it blocks only Maven/Gradle deploy goals such as `mvn liberty:deploy` and `git push`, so `deploy/zos/` and the `deploy-*.md` steering files are fine; run deploy goals yourself) |
| **Optional tools** | For runtime checks only: Docker or a compatible engine ([install](https://docs.docker.com/get-started/get-docker/)), WildFly 40+ ([downloads](https://www.wildfly.org/downloads/)) or Open Liberty ([get started](https://openliberty.io/start/)), and `xmllint`. Without them, do every Kiro step and file change and skip only the runtime checks. |
| **End** | Container work on `workshop`; WAR work on branch `m6-war`; back on `workshop` with a clean tree (Exercise 6.11) |

## Before you start

`../scripts/verify-stage.sh 3`, then tag your starting point so every diff in this module has a fixed
base: `git status --short && git tag m6-start`\
**Expect:** `PASS: stage 3, …`; a clean tree.

## Exercises

| # | Exercise | Min |
|---|---|---|
| 6.1 | [Assess before you touch](#61-assess-before-you-touch) | 8 |
| 6.2 | [Steering for Dockerfiles](#62-steering-for-dockerfiles) | 4 |
| 6.3 | [Generate the Dockerfile](#63-generate-the-dockerfile) | 8 |
| 6.4 | [Quick Spec for WAR packaging](#64-quick-spec-for-war-packaging) | 11 |
| 6.5 | [Independent review](#65-independent-review) | 4 |
| 6.6 | [Steering for JBoss/WildFly descriptors](#66-steering-for-jbosswildfly-descriptors) | 4 |
| 6.7 | [Deploy the WAR to WildFly 41](#67-deploy-the-war-to-wildfly-41-optional-needs-a-server-or-image) (optional) | 6 |
| 6.8 | [Steering for Liberty `server.xml`](#68-steering-for-liberty-serverxml) | 4 |
| 6.9 | [Generate `server.xml` and run on Liberty](#69-generate-serverxml-and-run-on-liberty-run-step-optional) | 6 |
| 6.10 | [Steering and a z/OS launch-script draft](#610-steering-and-a-zos-launch-script-draft) | 5 |
| 6.11 | [Back to `workshop`](#611-back-to-workshop) | — |

---

## Why deploy outside the embedded server, and what to choose by default

**Default recommendation:** ship the **executable jar**, usually inside a **container image**.
- The app brings its own Servlet 6.1 container.
- The Jakarta EE level of the host doesn't matter.
- Every target that can run a Java 25 process can run the app.

Choose WAR deployment only when a target requires it, and only on a server that implements Jakarta EE 11.

**Why:** [why teams deploy outside java -jar](why/06-platform-deployment.md#why-deploy-outside-the-embedded-server-and-what-to-choose-by-default)

### Support matrix (built only from sources checked on 2026-10-09)

Spring Boot 4 "is based on Jakarta EE 11 and requires a Servlet 6.1 baseline"
([Boot 4.0 migration guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide)).
The app is compiled for Java 25, so the target JVM must also be Java 25 or later.

| Example target | Runs this Boot 4.1 app? | Why |
|---|---|---|
| Executable jar / container image | **Yes: default** | Boot brings its own Servlet 6.1 container |
| WildFly 40 / 41 (standard) | **Yes: verify** | Jakarta EE 11; certified on Java SE 17 and 21; on SE 25 recommended but not certified |
| WildFly "EE 10" variant | **No** | EE 10 (Servlet 6.0) |
| JBoss EAP 8.1 (latest documentation set) | **No** | Red Hat describes Jakarta EE 10 / Java SE 17; we found no JBoss EAP release with Jakarta EE 11 |
| Open Liberty | **Yes: verify** | `jakartaee-11.0` / `servlet-6.1`; Java 17, 21, 25, 27 |
| WebSphere Liberty | **Verify** | not checked |
| Traditional WebSphere 9.0.5 | **No** | Java EE 7 (`javax.*`), Java SE 8 |
| z/OS with Semeru for z/OS 25 | **Yes: verify** | executable jar on a Java 25 runtime |

**Why:** [full support matrix with sources, and how to read the "No" rows](why/06-platform-deployment.md#why-deploy-outside-the-embedded-server-and-what-to-choose-by-default)

---

## Deployment-readiness plan

### 6.1 Assess before you touch
**Goal:** get a read-only list of everything that changes when the app leaves the embedded server.

**Do**
1. Start a new chat session (the **+** in the chat panel, or Cmd/Ctrl+T).
2. On the "Let's build" screen, choose **Plan**. Plan mode is read-only: "Plan mode intentionally cannot
   modify your project."
3. Paste the prompt below.
4. Read the plan, and ask follow-up questions in the same session.

> **Don't approve the plan.** Approved plans hand off to execution automatically. The plan lives only in
> the conversation, so copy what you want to keep into your notes.

**Attach first:** `#codebase`, `#pom.xml`
**Prompt**
```prompt
This Spring Boot 4.1 / Java 25 app currently runs only with `java -jar`. I want to deploy it to:
(1) a container image, (2) a Jakarta EE 11 application server as a WAR (Servlet 6.1),
(3) an executable jar on a host where I only control the JVM.
Produce a deployment-readiness plan. For each target list:
- the build changes (packaging, dependency scopes, main class),
- runtime configuration that must come from the environment (ports, passwords, datasource),
- parts of this codebase that are sensitive to running inside an app server: servlet filters
  (RequestIdFilter), JPA/Hibernate, Bean Validation, Jackson, logging,
- how I will verify the deployment: endpoints to call and headers to check.
Do not invent server versions or descriptor syntax. Mark anything you are unsure of as "verify".
```

**Why:** [example plan (yours will differ)](why/06-platform-deployment.md#61-assess-before-you-touch)

**Check** Plan mode changed nothing.
```bash
git status --short
```
Expect no output.

**Commit:** nothing to commit. Keep this session open as a reference.

---

## Container image, the default path

### 6.2 Steering for Dockerfiles
**Goal:** container conventions load automatically whenever Kiro works on a `Dockerfile`.

**Do**
1. Create `.kiro/steering/deploy-container.md` with this content. The front matter must be the very
   first bytes of the file:

```markdown
---
inclusion: fileMatch
fileMatchPattern: ["**/Dockerfile", "**/Dockerfile.*", "**/.dockerignore"]
---

# Container image rules (loaded when a Dockerfile is in context)

- Runtime is Java 25. Use a Java 25 base image; never an older one (class file version 69 = Java 25).
- Build the jar with Maven on the host (`mvn -B clean verify`) and copy `target/*.jar`; do not run tests in the image.
- The .dockerignore must not exclude target/*.jar: the Dockerfile copies it from the build context.
- Use the Spring Boot layered layout: `java -Djarmode=tools -jar application.jar extract --layers --destination extracted`
  in a builder stage, then copy dependencies/, spring-boot-loader/, snapshot-dependencies/, application/.
- Run as a non-root user. Expose 8080.
- No secrets in the image or in build args. Passwords come from environment variables at run time
  (APP_ADMIN_PASSWORD, APP_USER_PASSWORD, DB_PASSWORD; see .env.example).
- Use the PostgreSQL profile (or a real datasource) outside local runs; H2 in-memory data is lost on restart.
- Mark any image tag you have not checked with a "# VERIFY:" comment.
```

### 6.3 Generate the Dockerfile
**Goal:** produce a layered, non-root Java 25 image of the app.

**Do**
1. Commit first. Checkpoints don't capture shell commands such as `docker build`.
2. Start a new session (Default agent) and send the prompt below.
3. Review the diff and accept it. Check that `.dockerignore` doesn't exclude `target/*.jar`.

> The `Dockerfile` doesn't exist yet, so the prompt names its steering with `#steering:` (as in Parts 3–5).

**Attach first:** `#pom.xml`, `#steering:deploy-container.md`, `#url:https://docs.spring.io/spring-boot/reference/packaging/container-images/dockerfiles.html`
**Prompt**
```prompt
Create a Dockerfile and a .dockerignore for this app.
- Follow the multi-stage "jarmode tools extract --layers" pattern from the Spring Boot docs page
  above.
- Base image: an Amazon Corretto 25 image instead of the Liberica image used in the docs.
  Put a "# VERIFY:" comment next to the tag.
- Follow the container rules in deploy-container.md. The .dockerignore must keep target/*.jar
  in the build context.
Then show me the exact commands to build the jar, build the image, and run it with
APP_ADMIN_PASSWORD
set from my shell.
```

**Why:** [example: reference Dockerfile and the optional AOT cache (yours will differ)](why/06-platform-deployment.md#63-generate-the-dockerfile)

**Check**
```bash
mvn -B clean verify
docker build -t user-management:m6 .
docker run --rm --entrypoint java user-management:m6 -version
printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD
docker run --rm -p 8080:8080 -e APP_ADMIN_PASSWORD user-management:m6
```
**Expect:**
- `mvn -B clean verify` reports `Tests run: 14`, the same total as at the end of Module 4. Read your own.
- `java -version` reports version 25.
- The app starts and logs the Spring Boot banner.

In a second terminal, set the same password with the `printf … read` line above, then:
```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:8080/api/users | head -n 20
```
Expect `HTTP/1.1 200` and an `X-Request-Id` response header. `../scripts/smoke.sh` runs all the
running-app checks against the container. Stop the container with Ctrl+C.

**Why:** [what the running stage-3 app answers](why/06-platform-deployment.md#63-generate-the-dockerfile)

**Why:** [health probes if you add Actuator later](why/06-platform-deployment.md#63-generate-the-dockerfile)

**Commit**
```bash
git add Dockerfile .dockerignore .kiro/steering/deploy-container.md
git commit -m "m6: layered Java 25 container image"
```

---

## WAR packaging for application servers

Do this on a branch. The container work (Exercises 6.2–6.3) stays on `workshop`.

```bash
git switch -c m6-war
```

### 6.4 Quick Spec for WAR packaging
**Goal:** produce a WAR that deploys to a Servlet 6.1 server and still starts with `java -jar`.

**Do**
1. Start a new session and choose **Quick Spec** on the "Let's build" screen.
2. Answer the clarifying questions, then review the three files under `.kiro/specs/`.
3. Run the tasks **one at a time** by clicking each task item in `tasks.md` (or first ask Kiro to make
   `tasks.md` a strict chain, then use **Run all Tasks**).
   - After every task the `verify-after-spec-task` hook runs `mvn -B clean verify` and reports the
     `Tests run` line to the agent. It passes even if fewer tests run, so check that the count is 14.
   - Don't start your own Maven build while the hook is running.

**Why:** [Quick Spec, Run all Tasks waves, and what the hook reports](why/06-platform-deployment.md#64-quick-spec-for-war-packaging)

**Attach first:** `#pom.xml`, `#UserManagementApplication.java`, `#url:https://docs.spring.io/spring-boot/how-to/deployment/traditional-deployment.html`, `#url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide`
**Prompt**
```prompt
Package this Spring Boot 4.1 app as a deployable WAR for a Jakarta EE 11 / Servlet 6.1 server.
Requirements:
1. `<packaging>war</packaging>`; build finalName `user-management` so the artifact is
   target/user-management.war.
2. The main class extends SpringBootServletInitializer and overrides configure(...) to add itself as
   a
   source; keep the main method so `java -jar target/user-management.war` still works.
3. The embedded servlet container must NOT be packaged in WEB-INF/lib. Use the how-to's Maven form:
   declare spring-boot-starter-tomcat with provided scope. (The Spring Boot 4.0 migration guide and
   the
   how-to's Gradle example use spring-boot-starter-tomcat-runtime instead.) Show me the evidence
   with
   mvn dependency:tree and with `jar tf` on the WAR.
4. Keep the existing build plugins unchanged, including the maven-compiler-plugin
   annotationProcessorPaths
   entry for Lombok (JDK 23+ needs it, or the getters and setters disappear).
5. RequestIdFilter must still be registered, and the X-Request-Id header must still be present.
6. The number of tests run must not go down (14 today).
Do not change application behaviour or security rules.
Do not run Maven yourself after a task; the verify hook runs `mvn -B clean verify` and reports the
Tests run line. Quote that line in your summary.
```

**Why:** [example: typical pom.xml and main-class change (yours will differ)](why/06-platform-deployment.md#64-quick-spec-for-war-packaging)

**Why:** [spring-boot-starter-tomcat or spring-boot-starter-tomcat-runtime?](why/06-platform-deployment.md#64-quick-spec-for-war-packaging)

**Check** (after the last task's hook run has finished)
```bash
mvn -B clean verify
mvn -B dependency:tree -Dincludes=org.apache.tomcat.embed
jar tf target/user-management.war | grep -c 'WEB-INF/lib-provided/tomcat-embed'
jar tf target/user-management.war | grep 'WEB-INF/lib/tomcat-embed' || echo "OK: no embedded Tomcat in WEB-INF/lib"
grep -c '<annotationProcessorPaths>' pom.xml
java -jar target/user-management.war
```
**Expect:**
- `Tests run: 14`, unchanged from Module 4.
- `dependency:tree` lists the `tomcat-embed-*` artifacts as `provided`. If one is `compile`, the tree
  shows the path that brings it in; ask Kiro to fix it.
- **The gate:** the `lib-provided` count is greater than 0, and the second `grep` prints the OK line.
- The `annotationProcessorPaths` count is 1.
- `java -jar` still starts the app (the `lib-provided` jars make the WAR executable). Stop it with Ctrl+C.

### 6.5 Independent review
**Goal:** get a second opinion from the `migration-reviewer` agent before you commit and deploy. It has
no `write` tool and is instructed not to modify files. Only its Maven build and read-only git commands
run without a prompt.

**Do**
1. Run `git status --short` and note the list (your uncommitted WAR change and the spec files).
2. In a new session, open the agent selector and choose `migration-reviewer`.
3. Send the prompt below. The reviewer runs `mvn -B verify` itself; don't start another build meanwhile.
4. Afterwards run `git status --short` again. Expect the same list as in step 1.

**Prompt**
```prompt
Review `git diff m6-start` (the committed container work plus my uncommitted WAR change). Focus on:
WAR packaging correctness for a Servlet 6.1 server, embedded container scope, the Lombok
annotationProcessorPaths entry, anything that changed application or security behaviour, and the
test count. Reply with your usual findings table and verdict.
```

**Commit**
```bash
git add -A
git commit -m "m6: deployable WAR (SpringBootServletInitializer, provided container)"
```

---

## JBoss EAP and WildFly

### Compatibility note (read this first)
- **WildFly 40+ (standard):** Jakarta EE 11. On Java 25, which this app needs, it is recommended but
  not certified ("We do not claim to be compatible with EE 11 on SE 25"). Your platform owners decide.
- **WildFly "EE 10" variant and JBoss EAP 8.1:** EE 10 (Servlet 6.0). We found no JBoss EAP release
  with Jakarta EE 11, so a Boot 4 WAR is **not expected to deploy** on JBoss EAP. Options: the jar or
  container (recommended), WildFly 40+, a time-boxed Boot 3.5 line, or wait for an EE 11 release.
  > Unconfirmed: Red Hat's JBoss EAP supported-configurations and life-cycle pages.

**Why:** [WildFly and JBoss EAP compatibility in detail, and the four EAP options](why/06-platform-deployment.md#jboss-eap-and-wildfly)

### 6.6 Steering for JBoss/WildFly descriptors
**Goal:** Kiro applies conservative rules whenever it touches a JBoss/WildFly descriptor.

**Do**
1. Create `.kiro/steering/deploy-wildfly.md`:

```markdown
---
inclusion: fileMatch
fileMatchPattern: ["**/jboss-deployment-structure.xml", "**/jboss-web.xml"]
---

# JBoss EAP / WildFly deployment rules (loaded when a JBoss descriptor is in context)

- Target: a Jakarta EE 11 (Servlet 6.1) server only. If the server is EE 10 (JBoss EAP 8.x as documented,
  or the WildFly EE 10 variant), say so and recommend the executable jar/container instead.
- The app is compiled for Java 25: the server JVM must be Java 25.
- Add jboss-deployment-structure.xml ONLY to fix an observed class-loading or subsystem conflict.
  Quote the server log line that justifies every exclusion.
- Never exclude a module "just in case". Prefer the app's own libraries (Spring, Hibernate, Jackson) by
  excluding the specific server module or subsystem that conflicts.
- Mark every element or attribute you have not checked against the WildFly/JBoss EAP class-loading docs
  with an XML comment <!-- VERIFY: ... -->.
```

### 6.7 Deploy the WAR to WildFly 41 (optional, needs a server or image)
**Goal:** see the WAR start inside an EE 11 server and call the API.

If you have WildFly 41 on Java 25 (a local install or the container image), open the block below.
Otherwise go straight to the checkpoint.

**Optional hands-on: steps, prompt and checks for a WildFly 41 deployment**

**Do**
1. Get WildFly 41 running on Java 25. Use either:
   - a local installation started with a Java 25 JVM, or
   - the WildFly container image. WildFly 41 introduced "a JDK 25 variant of our container image", and
     "the latest tag now points to the JDK 25 image".
   > Unconfirmed: the image name, tag and deployment directory on <https://www.wildfly.org/downloads/>
   > and in the WildFly docs.
2. Copy `target/user-management.war` into the server's deployment-scanner directory yourself. Pass
   `APP_ADMIN_PASSWORD` to the server's environment.
   > Unconfirmed: the directory is usually `standalone/deployments/` under the WildFly home. Check the
   > WildFly docs for your install.
3. Watch the server log for the Spring Boot banner and "Started UserManagementApplication".
4. Call the API. The context root defaults to the WAR name.
   > Unconfirmed: the context-root default in the WildFly docs.

```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:8080/user-management/api/users | head -n 20
```

**Attach first:** `#terminal`, `#steering:deploy-wildfly.md`
**Prompt** (only if the deployment fails)
```prompt
The WAR failed to deploy on WildFly 41 (Jakarta EE 11, Java 25). Here is the server log above.
Diagnose the root cause. If, and only if, the log shows a class-loading or subsystem conflict
between
the server and the libraries inside the WAR, propose a minimal
src/main/webapp/WEB-INF/jboss-deployment-structure.xml
and quote the log line that justifies each exclusion. Otherwise fix the real cause.
```
If the log isn't in the IDE terminal, paste it into the chat instead.

**Example only.** This is the shape such a descriptor takes. Don't add it unless you see a conflict:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- VERIFY: element names and namespace against the WildFly / JBoss EAP class-loading docs -->
<jboss-deployment-structure>
    <deployment>
        <exclude-subsystems>
            <!-- VERIFY: only if the server's JPA subsystem tries to manage this app's persistence -->
            <subsystem name="jpa"/>
        </exclude-subsystems>
    </deployment>
</jboss-deployment-structure>
```

**Check**
```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:8080/user-management/api/users | grep -iE '^HTTP|x-request-id'
curl -si http://localhost:8080/user-management/api/users | head -n 1
```
- The first command should show HTTP 200 and an `X-Request-Id` header. The filter is registered from the
  `Filter` bean inside the WAR.
- The second command should show 401, because unauthenticated requests are rejected.


**Commit**
```bash
git add -A
git commit -m "m6: WildFly deployment notes and steering"
```

---

## Open Liberty and WebSphere Liberty

### Compatibility note
- **Open Liberty** runs Jakarta EE 11 (`jakartaee-11.0`, `servlet-6.1`) on Java 17, 21, 25 and 27.
  Start with `servlet-6.1` only; the WAR brings its own Spring, Hibernate, validation and Jackson jars.
- **Traditional WebSphere 9.0.5** (Java EE 7 / Java SE 8) can't run this app. Move such workloads to
  Liberty or to the executable jar/container path.
- Unconfirmed: the first Open Liberty release with `jakartaee-11.0`, and WebSphere Liberty feature parity.

**Why:** [Liberty features in detail and container security constraints](why/06-platform-deployment.md#open-liberty-and-websphere-liberty)

### 6.8 Steering for Liberty `server.xml`
**Do**
1. Create `.kiro/steering/deploy-liberty.md`:

```markdown
---
inclusion: fileMatch
fileMatchPattern: ["**/liberty/config/server.xml", "**/server.xml"]
---

# Liberty server.xml rules (loaded when a Liberty server.xml is in context)

- Target Jakarta EE 11 features only (servlet-6.1, webProfile-11.0, jakartaee-11.0). Never mix in
  EE 10 or older feature versions.
- Start minimal: <feature>servlet-6.1</feature>. Add a feature only with a one-line reason in an XML comment.
- The JVM must be Java 25 (the app is compiled for 25).
- No passwords in server.xml; use environment variables.
- Mark any attribute you have not checked against openliberty.io docs with <!-- VERIFY: ... -->.
```

### 6.9 Generate `server.xml` and run on Liberty (run step optional)
**Goal:** produce a minimal Liberty configuration for the WAR, and deploy it if you have Liberty.

**Do**
1. Send the prompt below in a new session.
2. If you have Open Liberty on Java 25, run the WAR on it with the optional block after the example.

**Attach first:** `#pom.xml`, `#steering:deploy-liberty.md`, `#url:https://openliberty.io/docs/latest/reference/feature/servlet-6.1.html`
**Prompt**
```prompt
Create src/main/liberty/config/server.xml for deploying target/user-management.war to Open Liberty
with the smallest Jakarta EE 11 feature set (servlet-6.1). Configure the HTTP endpoint and the web
application with context root "/user-management". Only use configuration elements listed on the
feature page above, and mark every attribute name you are not sure of with <!-- VERIFY -->.
Then tell me how to run it locally and which log line shows the app started.
```

**Why:** [example server.xml (yours will differ)](why/06-platform-deployment.md#69-generate-serverxml-and-run-on-liberty-run-step-optional)

**Optional hands-on: run the WAR on Open Liberty and call the API**

> Unconfirmed: `src/main/liberty/config/` is the Liberty Maven plugin's default configuration folder. If
> you don't use the plugin, put the file wherever your Liberty server reads its `server.xml`.

If you have Open Liberty on Java 25, either:
- copy `server.xml` into your server's config directory and the WAR into its apps location, or
- use the Liberty Maven plugin. Run any deploy goal yourself; `block-deploy-and-push` stops the agent
  from running one.

> Unconfirmed: directory names, the plugin coordinates and the run goal on openliberty.io.

Then call the API:
```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:9080/user-management/api/users | grep -iE '^HTTP|x-request-id'
```
Expect HTTP 200 and an `X-Request-Id` header.


**Check** whether or not you deployed, check that the file is valid XML and lists only EE 11 features:
```bash
xmllint --noout src/main/liberty/config/server.xml && grep -o '<feature>[^<]*</feature>' src/main/liberty/config/server.xml
```

**Commit**
```bash
git add -A
git commit -m "m6: Open Liberty server.xml (servlet-6.1) and steering"
```

---

## z/OS considerations

This Part stays generic, because z/OS standards differ a lot between installations. Treat everything
Kiro drafts here as input for your z/OS platform team, not as a finished job.

**What we know**
- IBM Semeru Runtime Certified Edition for z/OS is available in **Version 25.0**, as well as 21.0, 17.0
  and 11.0 ([Java SDK products on z/OS](https://www.ibm.com/support/pages/java-sdk-products-zos)).
- A Java 25 runtime exists, so the simplest path is the **executable jar** (from `workshop` or the
  `m6-war` branch). It brings its own Servlet 6.1 container, so no application server is needed.

**Why:** [what to settle with the z/OS platform team (launch method, heap and GC, encoding, TLS, accounting)](why/06-platform-deployment.md#zos-considerations)

### 6.10 Steering and a z/OS launch-script draft
**Goal:** a reviewed draft of the z/OS launch artifacts, with every site-specific value clearly marked.

**Do**
1. Create `.kiro/steering/deploy-zos.md`:

```markdown
---
inclusion: fileMatch
fileMatchPattern: ["deploy/zos/**"]
---

# z/OS deployment rules (loaded when files under deploy/zos/ are in context)

- Runtime: IBM Semeru Runtime Certified Edition for z/OS, Version 25. Run the executable jar; no app server.
- Every site-specific value (paths, dataset names, job card, region/memory limits, ports, keyrings,
  encoding options) is a placeholder written as <<SITE_VALUE>> with a "VERIFY" comment.
- Never invent dataset names, HLQs, user IDs or JCL parameters; leave placeholders.
- Passwords come from the environment or a site-approved secret store, never from the script or JCL.
- Keep scripts POSIX sh compatible.
```

2. Send the prompt below in a new session.

**Attach first:** `#pom.xml`, `#steering:deploy-zos.md`
**Prompt**
```prompt
Create deploy/zos/start-user-management.sh: a POSIX sh script that starts the executable jar
(target/user-management-service-1.0.0-SNAPSHOT.jar on the workshop branch, or user-management.war on
the
m6-war branch) with a JAVA_HOME that points to IBM Semeru Runtime Certified Edition for z/OS 25,
explicit -Xms/-Xmx, and environment-provided passwords. Also create
deploy/zos/README-platform-questions.md
listing the open questions for the z/OS platform team (launch method: USS vs JZOS batch launcher,
heap/GC, encoding, TLS keyring, ports). Do not write JCL; do not invent any site values.
```

**Check**
```bash
sh -n deploy/zos/start-user-management.sh && echo "syntax OK"
grep -c 'VERIFY' deploy/zos/start-user-management.sh
grep -nE 'PASSWORD=[^$<]' deploy/zos/start-user-management.sh || echo "OK: no literal passwords"
```
Expect "syntax OK", a VERIFY count above 0, and the "no literal passwords" line.

**Commit**
```bash
git add -A
git commit -m "m6: z/OS launch-script draft and steering"
```

---

## Back to `workshop`

### 6.11 Back to `workshop`
**Do:** `git status --short` (commit or discard anything left), then `git switch workshop` and
`git log --oneline -3`.\
**Expect:** a clean tree on `workshop`, with the container commit. The WAR work stays on `m6-war`; merge
it only if your target needs a WAR.

## Check yourself
- [ ] Support matrix checked for every target you care about; you know which vendor page each "verify"
      row needs.
- [ ] Plan session done; `git status` was clean afterwards.
- [ ] Container image built on Java 25. `java -version` inside the image reports 25. `/api/users` returns
      200 with `X-Request-Id`.
- [ ] WAR branch: `SpringBootServletInitializer` in place; Tomcat only in `WEB-INF/lib-provided`
      (`jar tf`); Lombok still in `annotationProcessorPaths`; `java -jar` works; `Tests run: 14`.
- [ ] `migration-reviewer` verdict recorded for the WAR change, and `git status` unchanged by the review.
- [ ] Optional WildFly 40+ / Open Liberty deployment answered 200 (authenticated) and 401
      (unauthenticated).
- [ ] An honest note exists for each EE 10 / Java EE 7 target (JBoss EAP 8.x as documented, traditional
      WebSphere 9.0.5): executable jar/container instead, or a time-boxed Boot 3.5 fallback.
- [ ] Steering files `deploy-container.md`, `deploy-wildfly.md`, `deploy-liberty.md`, `deploy-zos.md`
      committed, with their front matter as the first bytes.

**Something went wrong?** [Deployment (T-D01 to T-D10)](../docs/troubleshooting.md#d-deployment-module-6) ·
blocked deploy goal → [T-K45](../docs/troubleshooting.md#t-k45-an-agent-command-stopped-with-blocked-by-workspace-policy) ·
`docker`/`curl` prompts → [T-K05](../docs/troubleshooting.md#t-k05-kiro-asks-before-every-docker-or-curl-command) ·
Plan started editing → [T-K10](../docs/troubleshooting.md#t-k10-plan-started-editing-files) ·
random build errors → [T-B04](../docs/troubleshooting.md#t-b04-random-compile-or-surefire-errors-that-go-away-on-a-rerun-or-a-corrupt-jar) ·
missing getters → [T-B11](../docs/troubleshooting.md#t-b11-cannot-find-symbol-for-getters-setters-or-constructors-on-jdk-25) ·
trailing-slash 404 → [T-R06](../docs/troubleshooting.md#t-r06-curl-apiusers-trailing-slash-returns-404)

## Next
- [**Module 7 (optional) →**](07-scale-out-cli-web.md): scale the same approach out. Package these steering files and rules as a
  Power, run checks headless with `kiro-cli` in CI, and hand larger batches to Kiro Web.
- Before you leave this module, decide your default for each target you deploy to, using the support
  matrix: container, EE 11 WAR, or executable jar. Note which "verify" items you still owe.
