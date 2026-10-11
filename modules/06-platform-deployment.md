# Module 6 (optional): Deploying outside the embedded server (60 minutes)

At the end of Module 4 your app runs on Java 25 with Spring Boot 4.1 (Spring Framework 7, Jakarta EE 11,
Servlet 6.1) and starts with `java -jar`. In production, many enterprises deploy instead to a container
platform, a Jakarta EE application server, or a mainframe. This module takes the same app to several
**common enterprise deployment targets**: a container image, JBoss EAP / WildFly, Open Liberty /
WebSphere Liberty, and z/OS. The targets are generic examples. Pick the ones that match your
environment and skip the others.

The one rule for the whole module: **Spring Boot 4 needs a Servlet 6.1 (Jakarta EE 11) container.**
A server that implements an older level can't run the Boot 4 WAR, however the WAR is packaged. Check the
support matrix before you spend time on packaging.

## What you'll do
- Use a **Plan** session (read-only) to assess the app's deployment readiness before you change anything.
- Build a container image on a Java 25 base image. This is the default recommendation.
- Package the app as a deployable WAR with a **Quick Spec**, and keep `java -jar` working.
- Write a target-specific **steering** file for each descriptor you touch: `Dockerfile`,
  `jboss-deployment-structure.xml`, Liberty `server.xml`, z/OS launch scripts.
- Deploy to WildFly and Open Liberty, if you have them, and record honest compatibility notes for
  JBoss EAP, traditional WebSphere and z/OS.

## Prerequisites
- Module 4 finished: you are on the `workshop` branch at or after tag `stage-3`, on JDK 25, and
  `mvn -B clean verify` passes with `Tests run: 14`. If you are behind, reset to stage 3 with the one
  reset procedure in [solutions/README.md](../solutions/README.md#reset-your-workspace-to-a-stage-the-one-procedure-all-modules-use).
- The `sample-app/` workspace is open and trusted in Kiro, and `mvn *` is set to "Always allow" (Module 1).
- **Hooks at the start of this module:** `verify-after-spec-task` **on**, `jakarta-import-guard` **on**,
  and `block-deploy-and-push` **on** if you built it in Module 5. That hook blocks only Maven/Gradle
  deploy goals (such as `mvn liberty:deploy`) and `git push`, so the `deploy/zos/` folder and the
  `deploy-*.md` steering files in this module are fine. Run deploy goals yourself.
- Optional, for runtime checks: Docker or a compatible engine (Part 1, and container-based runs in
  Parts 3 and 4), and a WildFly 40+ or Open Liberty installation or image (Parts 3 and 4). Without them,
  do every Kiro step and file change and skip only the runtime checks.
- Tag your starting point so every diff in this module has a fixed base:

```bash
git status --short
git tag m6-start
```

<details><summary>Background: instructor note</summary>

> **Instructor note:** Parts 3–5 also work as readiness exercises without servers. Tell participants
> which targets your environment actually uses, so they can pick two Parts and go deeper.

</details>

---

## Why deploy outside the embedded server, and what to choose by default

**Default recommendation:** ship the **executable jar**, usually inside a **container image**.
- The app brings its own Servlet 6.1 container.
- The Jakarta EE level of the host doesn't matter.
- Every target that can run a Java 25 process can run the app.

Choose WAR deployment only when a target requires it, and only on a server that implements Jakarta EE 11.

<details><summary>Background: why teams deploy outside java -jar</summary>

You usually deploy outside `java -jar` for one of these reasons:
- The operations team standardized on an application server.
- The platform requires a container image.
- The workload must run on z/OS next to its data.

Spring Boot's documentation supports traditional (WAR) deployment alongside more modern forms of
deployment ([Traditional deployment how-to](https://docs.spring.io/spring-boot/how-to/deployment/traditional-deployment.html)).

</details>

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

<details><summary>Background: full support matrix with sources, and how to read the "No" rows</summary>

| Example target | Jakarta EE level | Servlet | Java (as documented) | Runs this Boot 4.1 app? | Source |
|---|---|---|---|---|---|
| Executable jar / container image (embedded Tomcat) | Not applicable: Boot brings its own container | 6.1 (Boot 4 baseline) | 25 (Boot 4 needs 17+) | **Yes: default** | [Boot 4.0 migration guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide) |
| WildFly 40 / 41 (standard) | EE 11 Platform, Web Profile, Core Profile | 6.1 (part of EE 11) | Certified on SE 17 and 21; the project *recommends* SE 25 but does not claim EE 11 compatibility on 25 | **Yes: verify** with a test deployment | [WildFly 41 announcement](https://www.wildfly.org/news/2026/07/16/WildFly-41-is-released/) |
| WildFly "EE 10" variant (40 / 41) | EE 10 | 6.0 | > Verify | **No** (variant ends with WildFly 42) | same |
| JBoss EAP 8.1 (the latest documentation set) | Jakarta EE 10, as described by Red Hat | 6.0 (EE 10 level) | Java SE 17 stated; > Verify: 21 and 25 | **No**, not as a Boot 4 WAR (see Part 3) | [Red Hat Developer: JBoss EAP](https://developers.redhat.com/products/eap/overview), [EAP docs](https://docs.redhat.com/en/documentation/red_hat_jboss_enterprise_application_platform/) |
| Open Liberty (docs version 26.0.0.10) | `jakartaee-11.0` / `webProfile-11.0` | `servlet-6.1` | 17, 21, 25, 27 | **Yes: verify** with a test deployment | [jakartaee-11.0](https://openliberty.io/docs/latest/reference/feature/jakartaee-11.0.html), [servlet-6.1](https://openliberty.io/docs/latest/reference/feature/servlet-6.1.html) |
| WebSphere Liberty | > Verify: same feature names in IBM's WebSphere Liberty docs | > Verify | > Verify | **Verify** | not checked |
| Traditional WebSphere Application Server 9.0.5 | Java EE 7 (`javax.*`) | `javax.servlet` (Java EE 7) | Java SE 8 | **No** (Boot 3+ needs Jakarta EE 10 and Java 17) | [tWAS 9.0.5 docs index](https://www.ibm.com/docs/en/was/9.0.5?topic=overview-specifications-api-documentation) |
| z/OS with IBM Semeru Runtime Certified Edition for z/OS 25 | None needed: executable jar | 6.1 via embedded Tomcat | 25 (also 21, 17, 11 available) | **Yes: verify** on your z/OS level | [Java SDK products on z/OS](https://www.ibm.com/support/pages/java-sdk-products-zos) |

How to read the "No" rows:
- **JBoss EAP:** the documentation lists 8.1 as the latest release, and Red Hat describes its standards
  support as "Jakarta EE 10 core profile, Java SE 17". We found no Red Hat statement that a JBoss EAP
  release supports Jakarta EE 11 or Servlet 6.1.
  > Verify: check Red Hat's current JBoss EAP supported-configurations page before you decide. A newer
  > release may have shipped after 2026-10-09.
- **Traditional WebSphere 9.0.5:** IBM's documentation describes it as "Java EE 7 in WebSphere
  Application Server traditional" with "Java SE 8". Spring Boot 3 already requires Java 17 and
  Jakarta EE 10, so neither Boot 3 nor Boot 4 can run there.

</details>

---

## Part 0: Deployment-readiness plan (8 minutes)

### Exercise 0.1: Assess before you touch
**Goal:** get a read-only list of everything that changes when the app leaves the embedded server.

**Steps**
1. Start a new chat session (the **+** in the chat panel, or Cmd/Ctrl+T).
2. On the "Let's build" screen, choose **Plan**. Plan mode is read-only: "Plan mode intentionally cannot
   modify your project."
3. Paste the prompt below.
4. Read the plan, and ask follow-up questions in the same session.

> **Don't approve the plan.** Approved plans hand off to execution automatically. The plan lives only in
> the conversation, so copy what you want to keep into your notes.

Docs: <https://kiro.dev/docs/specs/plan/>

**Ask Kiro**
```text
#codebase #pom.xml
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

<details><summary>Example plan (yours will differ)</summary>

Kiro proposes a WAR change set:
- `<packaging>war</packaging>`
- a `SpringBootServletInitializer` subclass
- a `provided` embedded container

It also lists `curl -u admin:… /api/users` plus an `X-Request-Id` header check as the deployment test.

</details>

**Verify**: Plan mode changed nothing.
```bash
git status --short
```
Expect no output.

**Checkpoint:** nothing to commit. Keep this session open as a reference.

---

## Part 1: Container image, the default path (12 minutes)

### Exercise 1.1: Steering for Dockerfiles
**Goal:** container conventions load automatically whenever Kiro works on a `Dockerfile`.

**Steps**
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

Docs: <https://kiro.dev/docs/steering/>

### Exercise 1.2: Generate the Dockerfile
**Goal:** produce a layered, non-root Java 25 image of the app.

**Steps**
1. Commit first. Checkpoints don't capture shell commands such as `docker build`.
2. Start a new session (Default agent) and send the prompt below.
3. Review the diff and accept it. Check that `.dockerignore` doesn't exclude `target/*.jar`.

> The `Dockerfile` doesn't exist yet, so the prompt names its steering with `#steering:` (as in Parts 3–5).

Docs: <https://kiro.dev/docs/ide/chat/> · <https://kiro.dev/docs/checkpoints/>

**Ask Kiro**
```text
#pom.xml #steering:deploy-container.md
#url:https://docs.spring.io/spring-boot/reference/packaging/container-images/dockerfiles.html
Create a Dockerfile and a .dockerignore for this app.
- Follow the multi-stage "jarmode tools extract --layers" pattern from the Spring Boot docs page above.
- Base image: an Amazon Corretto 25 image instead of the Liberica image used in the docs.
  Put a "# VERIFY:" comment next to the tag.
- Follow the container rules in deploy-container.md. The .dockerignore must keep target/*.jar
  in the build context.
Then show me the exact commands to build the jar, build the image, and run it with APP_ADMIN_PASSWORD
set from my shell.
```

<details><summary>Example: reference Dockerfile and the optional AOT cache (yours will differ)</summary>

Reference Dockerfile, based on the Spring Boot 4.1 docs example with the base image swapped:

```dockerfile
# VERIFY: Corretto 25 tag and variant (for example a smaller/headless variant) on the
# official amazoncorretto image page before you rely on it.
FROM amazoncorretto:25 AS builder
WORKDIR /builder
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted

FROM amazoncorretto:25
WORKDIR /application
COPY --from=builder /builder/extracted/dependencies/ ./
COPY --from=builder /builder/extracted/spring-boot-loader/ ./
COPY --from=builder /builder/extracted/snapshot-dependencies/ ./
COPY --from=builder /builder/extracted/application/ ./
# Run as a non-root numeric user; the app writes no files (H2 is in-memory).
USER 1000:1000
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "application.jar"]
```

> Optional: on Java 25 the Spring Boot docs also show an AOT cache training run.
> `RUN java -XX:AOTCacheOutput=app.aot -Dspring.context.exit=onRefresh -jar application.jar` in the
> runtime stage, then `ENTRYPOINT ["java", "-XX:AOTCache=app.aot", "-jar", "application.jar"]`. The docs
> say: "If you're using Java 24 or later, please use AOT cache instead of CDS."

</details>

**Verify**
```bash
mvn -B clean verify
docker build -t user-management:m6 .
docker run --rm --entrypoint java user-management:m6 -version
printf 'Local admin password: '; read -rs APP_ADMIN_PASSWORD; echo; export APP_ADMIN_PASSWORD
docker run --rm -p 8080:8080 -e APP_ADMIN_PASSWORD user-management:m6
```
What to look for:
- `mvn -B clean verify` reports `Tests run: 14`, the same total as at the end of Module 4. Read your own.
- `java -version` reports version 25.
- The app starts and logs the Spring Boot banner.

In a second terminal, set the same password with the `printf … read` line above, then:
```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:8080/api/users | head -n 20
```
Expect `HTTP/1.1 200` and an `X-Request-Id` response header. `../scripts/smoke.sh` runs all the
running-app checks against the container. Stop the container with Ctrl+C.

<details><summary>Background: what the running stage-3 app answers (dry-run reference)</summary>

Verified in the 2026-10-10 dry run (Corretto 25, the stage-3 reference started with `java -jar`, not
in a container; the deployments in this module were not run): 401 without credentials, 200 for the
list, 400 for invalid input, 201 for a valid create (`"active":true`), 404 for an unknown id, an
`X-Request-Id` header, and ISO-8601 dates. `GET /api/users/` with a trailing slash returns **404** from
stage 2 on (200 in stages 0–1). Jackson 3 writes the JSON properties in alphabetical order. Use the
same calls against the container or a server deployment; under a context root, prefix the path.

</details>

<details><summary>Background: health probes if you add Actuator later</summary>

> If you add `spring-boot-starter-actuator` later, note that in Boot 4 "the liveness and readiness probes
> are now enabled by default" (Boot 4.0 migration guide). These are the endpoints a container platform
> usually probes.

</details>

**Checkpoint**
```bash
git add Dockerfile .dockerignore .kiro/steering/deploy-container.md
git commit -m "m6: layered Java 25 container image"
```

---

## Part 2: WAR packaging for application servers (15 minutes)

Do this on a branch. The container path from Part 1 stays on `workshop`.

```bash
git switch -c m6-war
```

### Exercise 2.1: Quick Spec for WAR packaging
**Goal:** produce a WAR that deploys to a Servlet 6.1 server and still starts with `java -jar`.

**Steps**
1. Start a new session and choose **Quick Spec** on the "Let's build" screen.
2. Answer the clarifying questions, then review the three files under `.kiro/specs/`.
3. Run the tasks **one at a time** by clicking each task item in `tasks.md` (or first ask Kiro to make
   `tasks.md` a strict chain, then use **Run all Tasks**).
   - After every task the `verify-after-spec-task` hook runs `mvn -B clean verify` and reports the
     `Tests run` line to the agent. It passes even if fewer tests run, so check that the count is 14.
   - Don't start your own Maven build while the hook is running.

Docs: <https://kiro.dev/docs/specs/quick-spec/> · <https://kiro.dev/docs/specs/> · <https://kiro.dev/docs/hooks/>

<details><summary>Background: Quick Spec, Run all Tasks waves, and what the hook reports</summary>

Quick Spec asks its clarifying questions first, then generates `requirements.md`, `design.md` and
`tasks.md` in one pass under `.kiro/specs/`. The change is small and easy to review, which suits Quick
Spec. For high-stakes work the docs recommend a standard Feature Spec with review gates.

- **Run all Tasks** groups independent tasks into waves, and tasks in the same wave run concurrently.
  Each finished task starts its own hook build in the same `target/`, and two overlapping builds give
  spurious failures that are fed back to the agent.
- The workspace hook `verify-after-spec-task` (`PostTaskExec`) runs `mvn -B clean verify` after every
  task. On success it gives the agent the `Tests run` line and `BUILD SUCCESS`; on failure, the last 80
  lines of output. The hook passes (exit 0) even when fewer tests run; only the reported count shows a
  drop. Green is not the same as done.

</details>

**Ask Kiro**
```text
#pom.xml #UserManagementApplication.java
#url:https://docs.spring.io/spring-boot/how-to/deployment/traditional-deployment.html
#url:https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide
Package this Spring Boot 4.1 app as a deployable WAR for a Jakarta EE 11 / Servlet 6.1 server.
Requirements:
1. `<packaging>war</packaging>`; build finalName `user-management` so the artifact is target/user-management.war.
2. The main class extends SpringBootServletInitializer and overrides configure(...) to add itself as a
   source; keep the main method so `java -jar target/user-management.war` still works.
3. The embedded servlet container must NOT be packaged in WEB-INF/lib. Use the how-to's Maven form:
   declare spring-boot-starter-tomcat with provided scope. (The Spring Boot 4.0 migration guide and the
   how-to's Gradle example use spring-boot-starter-tomcat-runtime instead.) Show me the evidence with
   mvn dependency:tree and with `jar tf` on the WAR.
4. Keep the existing build plugins unchanged, including the maven-compiler-plugin annotationProcessorPaths
   entry for Lombok (JDK 23+ needs it, or the getters and setters disappear).
5. RequestIdFilter must still be registered, and the X-Request-Id header must still be present.
6. The number of tests run must not go down (14 today).
Do not change application behaviour or security rules.
Do not run Maven yourself after a task; the verify hook runs `mvn -B clean verify` and reports the
Tests run line. Quote that line in your summary.
```

<details><summary>Example: typical pom.xml and main-class change (yours will differ)</summary>

The tasks typically edit `pom.xml` and the main class:

```xml
<packaging>war</packaging>
<!-- ... -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-tomcat</artifactId>
    <scope>provided</scope>
</dependency>
<!-- ... -->
<build>
    <finalName>user-management</finalName>
    <plugins>
        <!-- unchanged from stage 3: maven-compiler-plugin with Lombok in annotationProcessorPaths -->
        <!-- unchanged: spring-boot-maven-plugin -->
    </plugins>
</build>
```

```java
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

@SpringBootApplication
public class UserManagementApplication extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(UserManagementApplication.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(UserManagementApplication.class, args);
    }
}
```

</details>

<details><summary>Background: spring-boot-starter-tomcat or spring-boot-starter-tomcat-runtime?</summary>

> The Boot 4.1 how-to's Maven example shows `spring-boot-starter-tomcat` with `provided` scope. The
> Boot 4.0 migration guide ("switch the dependency spring-boot-starter-tomcat to
> spring-boot-starter-tomcat-runtime") and the how-to's Gradle example use `-runtime`.
> `spring-boot-starter-webmvc` itself brings in `spring-boot-starter-tomcat`, which is why the example
> declares that same artifact as `provided`. Where the Tomcat jars finally land depends on how Maven
> resolves the dependency paths, so don't judge the result by the pom or the artifact name. Judge it
> with `jar tf`: Tomcat jars must end up in `WEB-INF/lib-provided`, never in `WEB-INF/lib`.
> The docs say a provided container "produces an executable war file with the provided dependencies
> packaged in a lib-provided directory", which is why `java -jar` on the WAR still works.

</details>

**Verify** (after the last task's hook run has finished)
```bash
mvn -B clean verify
mvn -B dependency:tree -Dincludes=org.apache.tomcat.embed
jar tf target/user-management.war | grep -c 'WEB-INF/lib-provided/tomcat-embed'
jar tf target/user-management.war | grep 'WEB-INF/lib/tomcat-embed' || echo "OK: no embedded Tomcat in WEB-INF/lib"
grep -c '<annotationProcessorPaths>' pom.xml
java -jar target/user-management.war
```
What to look for:
- `Tests run: 14`, unchanged from Module 4.
- `dependency:tree` lists the `tomcat-embed-*` artifacts as `provided`. If one is `compile`, the tree
  shows the path that brings it in; ask Kiro to fix it.
- **The gate:** the `lib-provided` count is greater than 0, and the second `grep` prints the OK line.
- The `annotationProcessorPaths` count is 1.
- `java -jar` still starts the app (the `lib-provided` jars make the WAR executable). Stop it with Ctrl+C.

### Exercise 2.2: Independent review
**Goal:** get a second opinion from the `migration-reviewer` agent before you commit and deploy. It has
no `write` tool and is instructed not to modify files. Only its Maven build and read-only git commands
run without a prompt.

**Steps**
1. Run `git status --short` and note the list (your uncommitted WAR change and the spec files).
2. In a new session, open the agent selector and choose `migration-reviewer`.
3. Send the prompt below. The reviewer runs `mvn -B verify` itself; don't start another build meanwhile.
4. Afterwards run `git status --short` again. Expect the same list as in step 1.

Docs: <https://kiro.dev/docs/custom-agents/>

**Ask Kiro**
```text
Review `git diff m6-start` (the committed container work plus my uncommitted WAR change). Focus on:
WAR packaging correctness for a Servlet 6.1 server, embedded container scope, the Lombok
annotationProcessorPaths entry, anything that changed application or security behaviour, and the
test count. Reply with your usual findings table and verdict.
```

**Checkpoint**
```bash
git add -A
git commit -m "m6: deployable WAR (SpringBootServletInitializer, provided container)"
```

---

## Part 3: JBoss EAP and WildFly (10 minutes)

### Compatibility note (read this first)
- **WildFly 40+ (standard):** Jakarta EE 11. On Java 25, which this app needs, it is recommended but
  not certified ("We do not claim to be compatible with EE 11 on SE 25"). Your platform owners decide.
- **WildFly "EE 10" variant and JBoss EAP 8.1:** EE 10 (Servlet 6.0). We found no JBoss EAP release
  with Jakarta EE 11, so a Boot 4 WAR is **not expected to deploy** on JBoss EAP. Options: the jar or
  container (recommended), WildFly 40+, a time-boxed Boot 3.5 line, or wait for an EE 11 release.
  > Verify: Red Hat's JBoss EAP supported-configurations and life-cycle pages.

<details><summary>Background: WildFly and JBoss EAP compatibility in detail, and the four EAP options</summary>

- **WildFly 40 and later (standard distribution)** implement Jakarta EE 11. WildFly 41 is "EE 11
  Platform, Web Profile and Core Profile compatible when running on Java SE 17 and Java SE 21". The
  project recommends Java SE 25, but notes: "We do not claim to be compatible with EE 11 on SE 25."
  Your app needs Java 25, so that combination is recommended but not certified. Whether it's acceptable
  is a decision for your platform owners.
  Source: [WildFly 41 announcement](https://www.wildfly.org/news/2026/07/16/WildFly-41-is-released/).
- **The "WildFly EE 10" variant** still implements EE 10 (Servlet 6.0), so it can't run a Boot 4 WAR.
  It ends with WildFly 42.
- **JBoss EAP:** the latest documentation set is **8.1**, and Red Hat describes JBoss EAP's support as
  "Jakarta EE 10 core profile, Java SE 17". That is Servlet 6.0. We found no JBoss EAP release with
  Jakarta EE 11, so a Boot 4 / Spring Framework 7 WAR is **not expected to deploy** on it. Your options:
  the executable jar or container (recommended), WildFly 40+, a time-boxed Spring Boot 3.5 line, or
  waiting for a JBoss EAP release with Jakarta EE 11.
  > Verify: Red Hat's JBoss EAP supported-configurations and life-cycle pages.

The exercises below use WildFly 41. The descriptor and steering also apply to a JBoss EAP release that
supports Jakarta EE 11, if one becomes available to you.

The four options for an app that must deploy to JBoss EAP:

1. **Executable jar or container (recommended).** Run the Part 1 image or the jar on the same hosts
   or container platform instead of inside EAP.
2. **Keep that app on Spring Boot 3.5 (Jakarta EE 10) while it must deploy to EAP 8.x.**
   - Boot 3.5's open-source support ended on 2026-06-30, so this needs a support arrangement and an
     exit date.
   - It also means maintaining the Module 3 code line, without the Spring Framework 7 and Jackson 3
     changes from Module 4.
3. **WildFly 40+** if a community-supported EE 11 server is acceptable to you.
4. **Wait for a JBoss EAP release with Jakarta EE 11.**
   > Verify: Red Hat's JBoss EAP supported-configurations and life-cycle pages.

</details>

### Exercise 3.1: Steering for JBoss/WildFly descriptors
**Goal:** Kiro applies conservative rules whenever it touches a JBoss/WildFly descriptor.

**Steps**
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

Docs: <https://kiro.dev/docs/steering/>

### Exercise 3.2: Deploy the WAR to WildFly 41 (optional, needs a server or image)
**Goal:** see the WAR start inside an EE 11 server and call the API.

If you have WildFly 41 on Java 25 (a local install or the container image), open the block below.
Otherwise go straight to the checkpoint.

<details><summary>Optional hands-on: steps, prompt and checks for a WildFly 41 deployment</summary>

**Steps**
1. Get WildFly 41 running on Java 25. Use either:
   - a local installation started with a Java 25 JVM, or
   - the WildFly container image. WildFly 41 introduced "a JDK 25 variant of our container image", and
     "the latest tag now points to the JDK 25 image".
   > Verify: the image name, tag and deployment directory on <https://www.wildfly.org/downloads/>
   > and in the WildFly docs.
2. Copy `target/user-management.war` into the server's deployment-scanner directory yourself. Pass
   `APP_ADMIN_PASSWORD` to the server's environment.
   > Verify: the directory is usually `standalone/deployments/` under the WildFly home. Check the
   > WildFly docs for your install.
3. Watch the server log for the Spring Boot banner and "Started UserManagementApplication".
4. Call the API. The context root defaults to the WAR name.
   > Verify: the context-root default in the WildFly docs.

```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:8080/user-management/api/users | head -n 20
```

**Ask Kiro** (only if the deployment fails)
```text
#terminal #steering:deploy-wildfly.md
The WAR failed to deploy on WildFly 41 (Jakarta EE 11, Java 25). Here is the server log above.
Diagnose the root cause. If, and only if, the log shows a class-loading or subsystem conflict between
the server and the libraries inside the WAR, propose a minimal src/main/webapp/WEB-INF/jboss-deployment-structure.xml
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

**Verify**
```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:8080/user-management/api/users | grep -iE '^HTTP|x-request-id'
curl -si http://localhost:8080/user-management/api/users | head -n 1
```
- The first command should show HTTP 200 and an `X-Request-Id` header. The filter is registered from the
  `Filter` bean inside the WAR.
- The second command should show 401, because unauthenticated requests are rejected.

</details>

**Checkpoint**
```bash
git add -A
git commit -m "m6: WildFly deployment notes and steering"
```

---

## Part 4: Open Liberty and WebSphere Liberty (10 minutes)

### Compatibility note
- **Open Liberty** runs Jakarta EE 11 (`jakartaee-11.0`, `servlet-6.1`) on Java 17, 21, 25 and 27.
  Start with `servlet-6.1` only; the WAR brings its own Spring, Hibernate, validation and Jackson jars.
- **Traditional WebSphere 9.0.5** (Java EE 7 / Java SE 8) can't run this app. Move such workloads to
  Liberty or to the executable jar/container path.
- > Verify: the first Open Liberty release with `jakartaee-11.0`, and WebSphere Liberty feature parity.

<details><summary>Background: Liberty features in detail and container security constraints</summary>

- Open Liberty implements Jakarta EE 11: the platform feature `jakartaee-11.0` (which enables
  `webProfile-11.0`) and the servlet feature `servlet-6.1` both list Java 17, 21, 25 and 27 as supported.
  Sources: [jakartaee-11.0](https://openliberty.io/docs/latest/reference/feature/jakartaee-11.0.html) ·
  [servlet-6.1](https://openliberty.io/docs/latest/reference/feature/servlet-6.1.html).
- > Verify: the first Open Liberty release that ships `jakartaee-11.0`, and that your WebSphere Liberty
  > edition offers the same features (IBM WebSphere Liberty docs).
- Traditional WebSphere 9.0.5 is a Java EE 7 / Java SE 8 server and can't run this app. Move such
  workloads to Liberty or to the executable jar/container path.
- **Start with the smallest feature set:** `servlet-6.1`. The WAR brings its own Spring, Hibernate,
  validation and Jackson jars.
- The `servlet-6.1` feature is listed under platform `jakartaee-11.0`.
- `servlet-6.1` provides the `jakarta.servlet` API that the WAR needs. Add server features only when you
  deliberately use a server-provided service.

The `servlet-6.1` page says: "Without a security feature, any security constraints for the application
are ignored". That applies to *container* security constraints. Spring Security runs as a servlet filter
inside your WAR, so it doesn't depend on an `appSecurity` feature.

</details>

### Exercise 4.1: Steering for Liberty `server.xml`
**Steps**
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

Docs: <https://kiro.dev/docs/steering/>

### Exercise 4.2: Generate `server.xml` and run on Liberty (run step optional)
**Goal:** produce a minimal Liberty configuration for the WAR, and deploy it if you have Liberty.

**Steps**
1. Send the prompt below in a new session.
2. If you have Open Liberty on Java 25, run the WAR on it with the optional block after the example.

**Ask Kiro**
```text
#pom.xml #steering:deploy-liberty.md
#url:https://openliberty.io/docs/latest/reference/feature/servlet-6.1.html
Create src/main/liberty/config/server.xml for deploying target/user-management.war to Open Liberty
with the smallest Jakarta EE 11 feature set (servlet-6.1). Configure the HTTP endpoint and the web
application with context root "/user-management". Only use configuration elements listed on the
feature page above, and mark every attribute name you are not sure of with <!-- VERIFY -->.
Then tell me how to run it locally and which log line shows the app started.
```

<details><summary>Example server.xml (yours will differ)</summary>

```xml
<?xml version="1.0" encoding="UTF-8"?>
<server description="user-management">
    <featureManager>
        <!-- Servlet 6.1 = Jakarta EE 11; the WAR brings Spring, Hibernate and validation itself -->
        <feature>servlet-6.1</feature>
    </featureManager>
    <!-- VERIFY: attribute names and default ports in the Open Liberty httpEndpoint docs -->
    <httpEndpoint id="defaultHttpEndpoint" host="*" httpPort="9080" httpsPort="9443"/>
    <!-- VERIFY: attribute names in the Open Liberty webApplication docs -->
    <webApplication location="user-management.war" contextRoot="/user-management"/>
</server>
```

</details>

<details><summary>Optional hands-on: run the WAR on Open Liberty and call the API</summary>

> Verify: `src/main/liberty/config/` is the Liberty Maven plugin's default configuration folder. If
> you don't use the plugin, put the file wherever your Liberty server reads its `server.xml`.

If you have Open Liberty on Java 25, either:
- copy `server.xml` into your server's config directory and the WAR into its apps location, or
- use the Liberty Maven plugin. Run any deploy goal yourself; `block-deploy-and-push` stops the agent
  from running one.

> Verify: directory names, the plugin coordinates and the run goal on openliberty.io.

Then call the API:
```bash
curl -si -u "admin:$APP_ADMIN_PASSWORD" http://localhost:9080/user-management/api/users | grep -iE '^HTTP|x-request-id'
```
Expect HTTP 200 and an `X-Request-Id` header.

</details>

**Verify**: whether or not you deployed, check that the file is valid XML and lists only EE 11 features:
```bash
xmllint --noout src/main/liberty/config/server.xml && grep -o '<feature>[^<]*</feature>' src/main/liberty/config/server.xml
```

**Checkpoint**
```bash
git add -A
git commit -m "m6: Open Liberty server.xml (servlet-6.1) and steering"
```

---

## Part 5: z/OS considerations (5 minutes)

This Part stays generic, because z/OS standards differ a lot between installations. Treat everything
Kiro drafts here as input for your z/OS platform team, not as a finished job.

**What we know**
- IBM Semeru Runtime Certified Edition for z/OS is available in **Version 25.0**, as well as 21.0, 17.0
  and 11.0 ([Java SDK products on z/OS](https://www.ibm.com/support/pages/java-sdk-products-zos)).
- A Java 25 runtime exists, so the simplest path is the **executable jar** (from `workshop` or the
  `m6-war` branch). It brings its own Servlet 6.1 container, so no application server is needed.

<details><summary>Background: what to settle with the z/OS platform team (launch method, heap and GC, encoding, TLS, accounting)</summary>

IBM says: "IBM Java Products are available at no charge in both SMP/E and non-SMP/E format."

Each item is a "> Verify" against IBM's Semeru for z/OS documentation and your site standards:
- **How the JVM is launched.** Choose between the z/OS UNIX System Services (USS) shell, with a start
  script, and a batch job or started task through the **JZOS batch launcher**.
  > Verify: the JZOS launcher's JCL, environment script and output handling in the Semeru for z/OS docs.
- **Heap and GC.** Size `-Xms` and `-Xmx` within your region and memory limits, and agree a GC policy.
  > Verify: Semeru runtimes use the Eclipse OpenJ9 JVM, so GC options follow OpenJ9 conventions. Check
  > the defaults and the recommended policy for your workload in the Semeru for z/OS docs.
- **Character encoding.** You need to decide how EBCDIC datasets and files relate to the UTF-8
  resources inside the jar. Check how log output and config files are tagged and read.
  > Verify: file tagging and `file.encoding` behaviour on Java 25 on z/OS.
- **Networking and TLS.** Ports, and whether certificates come from a SAF/RACF keyring or a keystore file.
- **Specialty engines and accounting.** Ask how Java work is placed and charged at your site.

</details>

### Exercise 5.1: Steering and a launch-script draft
**Goal:** a reviewed draft of the z/OS launch artifacts, with every site-specific value clearly marked.

**Steps**
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

**Ask Kiro**
```text
#pom.xml #steering:deploy-zos.md
Create deploy/zos/start-user-management.sh: a POSIX sh script that starts the executable jar
(target/user-management-service-1.0.0-SNAPSHOT.jar on the workshop branch, or user-management.war on the
m6-war branch) with a JAVA_HOME that points to IBM Semeru Runtime Certified Edition for z/OS 25,
explicit -Xms/-Xmx, and environment-provided passwords. Also create deploy/zos/README-platform-questions.md
listing the open questions for the z/OS platform team (launch method: USS vs JZOS batch launcher,
heap/GC, encoding, TLS keyring, ports). Do not write JCL; do not invent any site values.
```

**Verify**
```bash
sh -n deploy/zos/start-user-management.sh && echo "syntax OK"
grep -c 'VERIFY' deploy/zos/start-user-management.sh
grep -nE 'PASSWORD=[^$<]' deploy/zos/start-user-management.sh || echo "OK: no literal passwords"
```
Expect "syntax OK", a VERIFY count above 0, and the "no literal passwords" line.

**Checkpoint**
```bash
git add -A
git commit -m "m6: z/OS launch-script draft and steering"
```

---

## Checklist
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

## Troubleshooting

<details><summary>Troubleshooting table (open it when a step fails)</summary>

| Symptom | Cause | Fix |
|---|---|---|
| Container exits with `UnsupportedClassVersionError ... class file version 69.0` | Base image is older than Java 25 | Use a Java 25 base image tag; re-check the `# VERIFY` tag |
| `docker build` fails at `COPY ${JAR_FILE}` | Jar not built yet, the glob doesn't match, or `.dockerignore` excludes `target/*.jar` | Run `mvn -B clean verify` first; check `ls target/*.jar`; keep `target/*.jar` out of `.dockerignore` |
| `cannot find symbol` for getters/setters after the WAR change | The Lombok `annotationProcessorPaths` entry was removed; JDK 23+ no longer runs class-path annotation processors | Restore the `maven-compiler-plugin` block from stage 3 (Module 4) |
| Random compile or Surefire errors right after a task | Two Maven builds overlapped in `target/` (parallel tasks, or your build during the hook's) | Run tasks one at a time; wait for the hook, then rerun `mvn -B clean verify` |
| WAR deploys, but the app never starts (no Spring banner in the server log) | Main class doesn't extend `SpringBootServletInitializer` | Add the subclass and the `configure` override (Part 2) |
| Server log shows a second Tomcat starting, or port clashes | Embedded container packaged in `WEB-INF/lib` | Make the embedded container dependency `provided`; check with `jar tf` |
| `java -jar target/user-management.war` fails with no web server | Container dependency removed instead of set to `provided` | Restore it with `provided` scope; Boot then packages it in `lib-provided` |
| `NoSuchMethodError` / `ClassNotFoundException` in `jakarta.servlet` during deployment | Server implements Servlet 6.0 (EE 10), for example JBoss EAP 8.x or WildFly EE 10 | Use an EE 11 server (WildFly 40+, Open Liberty `servlet-6.1`) or the executable jar/container |
| 404 on `/api/users` after deployment | App runs under a context root (the WAR name by default on many servers) | Call `/user-management/api/users` or set the context root (> Verify for your server) |
| 404 on `/api/users/` (trailing slash), 200 without it | Since Spring Framework 6 (stage 2), a trailing slash no longer matches; verified in the 2026-10-10 dry run | Expected: call the path without the trailing slash |
| Liberty refuses to start the feature set (feature conflict in the log) | EE 10 and EE 11 feature versions mixed in `server.xml` | Use only EE 11 features; start with `servlet-6.1` (> Verify the exact message in the Liberty log docs) |
| Agent command stopped with "Blocked by workspace policy" | The Module 5 `block-deploy-and-push` hook matched a Maven/Gradle deploy goal or `git push` | Working as intended: run that command yourself |
| Garbled characters in logs or config on z/OS | Encoding mismatch between EBCDIC files and UTF-8 resources | Agree the encoding and file-tagging approach with the platform team (> Verify in Semeru for z/OS docs) |
| Kiro started editing files during Part 0 | You approved the plan, and Plan hands off to execution | Revert the turn (checkpoint) or `git restore .`; keep Plan sessions unapproved |
| A `deploy-*.md` steering file is not applied | Front matter isn't the first bytes, or `fileMatchPattern` doesn't match the path | Remove leading blank lines; check the glob against the real path |
| Kiro asks before every `docker`/`curl` command | Only `mvn *` is pre-approved | Choose "Always allow" with a narrow pattern, for example `docker build *`, for this workspace |

</details>

## Kiro features used

<details><summary>Reference: features and docs links used in this module</summary>

| Feature | Where | Docs |
|---|---|---|
| Plan workflow (read-only) | Part 0 | <https://kiro.dev/docs/specs/plan/> |
| Quick Spec | Part 2 | <https://kiro.dev/docs/specs/quick-spec/> |
| Specs: tasks one at a time (Run all Tasks only for a strict chain) | Part 2 | <https://kiro.dev/docs/specs/> |
| Steering with `fileMatch` | Parts 1, 3, 4, 5 | <https://kiro.dev/docs/steering/> |
| Context providers (`#codebase`, `#url`, `#terminal`, `#steering`, `#` + file name) | All Parts | <https://kiro.dev/docs/ide/chat/> |
| Hooks: `verify-after-spec-task` (`PostTaskExec`), `block-deploy-and-push` (`PreToolUse`, Module 5) | Prerequisites, Part 2, Part 4 | <https://kiro.dev/docs/hooks/> |
| Custom agent `migration-reviewer` (agent selector) | Part 2 | <https://kiro.dev/docs/custom-agents/> |
| Checkpoints (commit before shell work) | Parts 0, 1 | <https://kiro.dev/docs/checkpoints/> |
| Permissions ("Always allow" patterns) | Troubleshooting | <https://kiro.dev/docs/permissions/> |

In the prompts, `#pom.xml` and `#UserManagementApplication.java` mean: type `#` followed by the file
name and pick the file. That uses the `#file` context provider.

</details>

## Next
- **Module 7 (optional):** scale the same approach out. Package these steering files and rules as a
  Power, run checks headless with `kiro-cli` in CI, and hand larger batches to Kiro Web.
- Before you leave this module, decide your default for each target you deploy to, using the support
  matrix: container, EE 11 WAR, or executable jar. Note which "verify" items you still owe.
