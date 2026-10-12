# Module 6: why and background

[← Back to the Module 6 runbook](../06-platform-deployment.md)

The runbook keeps only what you do and what you should see. This page holds the full support matrix,
the reference files, the compatibility details and the docs. Headings match the runbook.

## Why deploy outside the embedded server, and what to choose by default

### why teams deploy outside java -jar

You usually deploy outside `java -jar` for one of these reasons:
- The operations team standardized on an application server.
- The platform requires a container image.
- The workload must run on z/OS next to its data.

Spring Boot's documentation supports traditional (WAR) deployment alongside more modern forms of
deployment ([Traditional deployment how-to](https://docs.spring.io/spring-boot/how-to/deployment/traditional-deployment.html)).

### full support matrix with sources, and how to read the "No" rows

| Example target | Jakarta EE level | Servlet | Java (as documented) | Runs this Boot 4.1 app? | Source |
|---|---|---|---|---|---|
| Executable jar / container image (embedded Tomcat) | Not applicable: Boot brings its own container | 6.1 (Boot 4 baseline) | 25 (Boot 4 needs 17+) | **Yes: default** | [Boot 4.0 migration guide](https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide) |
| WildFly 40 / 41 (standard) | EE 11 Platform, Web Profile, Core Profile | 6.1 (part of EE 11) | Certified on SE 17 and 21; the project *recommends* SE 25 but does not claim EE 11 compatibility on 25 | **Yes: verify** with a test deployment | [WildFly 41 announcement](https://www.wildfly.org/news/2026/07/16/WildFly-41-is-released/) |
| WildFly "EE 10" variant (40 / 41) | EE 10 | 6.0 | > Verify | **No** (variant ends with WildFly 42) | same |
| JBoss EAP 8.1 (the latest documentation set) | Jakarta EE 10, as described by Red Hat | 6.0 (EE 10 level) | Java SE 17 stated; > Verify: 21 and 25 | **No**, not as a Boot 4 WAR (see Exercises 6.6–6.7) | [Red Hat Developer: JBoss EAP](https://developers.redhat.com/products/eap/overview), [EAP docs](https://docs.redhat.com/en/documentation/red_hat_jboss_enterprise_application_platform/) |
| Open Liberty (docs version 26.0.0.10) | `jakartaee-11.0` / `webProfile-11.0` | `servlet-6.1` | 17, 21, 25, 27 | **Yes: verify** with a test deployment | [jakartaee-11.0](https://openliberty.io/docs/latest/reference/feature/jakartaee-11.0.html), [servlet-6.1](https://openliberty.io/docs/latest/reference/feature/servlet-6.1.html) |
| WebSphere Liberty | > Verify: same feature names in IBM's WebSphere Liberty docs | > Verify | > Verify | **Verify** | not checked |
| Traditional WebSphere Application Server 9.0.5 | Java EE 7 (`javax.*`) | `javax.servlet` (Java EE 7) | Java SE 8 | **No** (Boot 3+ needs Jakarta EE 10 and Java 17) | [tWAS 9.0.5 docs index](https://www.ibm.com/docs/en/was/9.0.5?topic=overview-specifications-api-documentation) |
| z/OS with IBM Semeru Runtime Certified Edition for z/OS 25 | None needed: executable jar | 6.1 via embedded Tomcat | 25 (also 21, 17, 11 available) | **Yes: verify** on your z/OS level | [Java SDK products on z/OS](https://www.ibm.com/support/pages/java-sdk-products-zos) |

How to read the "No" rows:
- **JBoss EAP:** the documentation lists 8.1 as the latest release, and Red Hat describes its standards
  support as "Jakarta EE 10 core profile, Java SE 17". We found no Red Hat statement that a JBoss EAP
  release supports Jakarta EE 11 or Servlet 6.1.
  > Unconfirmed: check Red Hat's current JBoss EAP supported-configurations page before you decide. A newer
  > release may have shipped after 2026-10-09.
- **Traditional WebSphere 9.0.5:** IBM's documentation describes it as "Java EE 7 in WebSphere
  Application Server traditional" with "Java SE 8". Spring Boot 3 already requires Java 17 and
  Jakarta EE 10, so neither Boot 3 nor Boot 4 can run there.

## 6.1 Assess before you touch


Kiro proposes a WAR change set:
- `<packaging>war</packaging>`
- a `SpringBootServletInitializer` subclass
- a `provided` embedded container

It also lists `curl -u admin:… /api/users` plus an `X-Request-Id` header check as the deployment test.

## 6.3 Generate the Dockerfile

### Example: reference Dockerfile and the optional AOT cache (yours will differ)

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

### what the running stage-3 app answers (dry-run reference)

Verified in the 2026-10-10 dry run (Corretto 25, the stage-3 reference started with `java -jar`, not
in a container; the deployments in this module were not run): 401 without credentials, 200 for the
list, 400 for invalid input, 201 for a valid create (`"active":true`), 404 for an unknown id, an
`X-Request-Id` header, and ISO-8601 dates. `GET /api/users/` with a trailing slash returns **404** from
stage 2 on (200 in stages 0–1). Jackson 3 writes the JSON properties in alphabetical order. Use the
same calls against the container or a server deployment; under a context root, prefix the path.

### health probes if you add Actuator later

> If you add `spring-boot-starter-actuator` later, note that in Boot 4 "the liveness and readiness probes
> are now enabled by default" (Boot 4.0 migration guide). These are the endpoints a container platform
> usually probes.

## 6.4 Quick Spec for WAR packaging

### Quick Spec, Run all Tasks waves, and what the hook reports

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

### Example: typical pom.xml and main-class change (yours will differ)

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

### spring-boot-starter-tomcat or spring-boot-starter-tomcat-runtime?

> The Boot 4.1 how-to's Maven example shows `spring-boot-starter-tomcat` with `provided` scope. The
> Boot 4.0 migration guide ("switch the dependency spring-boot-starter-tomcat to
> spring-boot-starter-tomcat-runtime") and the how-to's Gradle example use `-runtime`.
> `spring-boot-starter-webmvc` itself brings in `spring-boot-starter-tomcat`, which is why the example
> declares that same artifact as `provided`. Where the Tomcat jars finally land depends on how Maven
> resolves the dependency paths, so don't judge the result by the pom or the artifact name. Judge it
> with `jar tf`: Tomcat jars must end up in `WEB-INF/lib-provided`, never in `WEB-INF/lib`.
> The docs say a provided container "produces an executable war file with the provided dependencies
> packaged in a lib-provided directory", which is why `java -jar` on the WAR still works.

## JBoss EAP and WildFly


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
  > Unconfirmed: Red Hat's JBoss EAP supported-configurations and life-cycle pages.

The exercises below use WildFly 41. The descriptor and steering also apply to a JBoss EAP release that
supports Jakarta EE 11, if one becomes available to you.

The four options for an app that must deploy to JBoss EAP:

1. **Executable jar or container (recommended).** Run the Exercise 6.3 image or the jar on the same hosts
   or container platform instead of inside EAP.
2. **Keep that app on Spring Boot 3.5 (Jakarta EE 10) while it must deploy to EAP 8.x.**
   - Boot 3.5's open-source support ended on 2026-06-30, so this needs a support arrangement and an
     exit date.
   - It also means maintaining the Module 3 code line, without the Spring Framework 7 and Jackson 3
     changes from Module 4.
3. **WildFly 40+** if a community-supported EE 11 server is acceptable to you.
4. **Wait for a JBoss EAP release with Jakarta EE 11.**
   > Unconfirmed: Red Hat's JBoss EAP supported-configurations and life-cycle pages.

## Open Liberty and WebSphere Liberty


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

## 6.9 Generate `server.xml` and run on Liberty (run step optional)


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

## z/OS considerations


IBM says: "IBM Java Products are available at no charge in both SMP/E and non-SMP/E format."

Each item is a "> Verify" against IBM's Semeru for z/OS documentation and your site standards:
- **How the JVM is launched.** Choose between the z/OS UNIX System Services (USS) shell, with a start
  script, and a batch job or started task through the **JZOS batch launcher**.
  > Unconfirmed: the JZOS launcher's JCL, environment script and output handling in the Semeru for z/OS docs.
- **Heap and GC.** Size `-Xms` and `-Xmx` within your region and memory limits, and agree a GC policy.
  > Unconfirmed: Semeru runtimes use the Eclipse OpenJ9 JVM, so GC options follow OpenJ9 conventions. Check
  > the defaults and the recommended policy for your workload in the Semeru for z/OS docs.
- **Character encoding.** You need to decide how EBCDIC datasets and files relate to the UTF-8
  resources inside the jar. Check how log output and config files are tagged and read.
  > Unconfirmed: file tagging and `file.encoding` behaviour on Java 25 on z/OS.
- **Networking and TLS.** Ports, and whether certificates come from a SAF/RACF keyring or a keystore file.
- **Specialty engines and accounting.** Ask how Java work is placed and charged at your site.

## Docs


| Feature | Where | Docs |
|---|---|---|
| Plan workflow (read-only) | Exercise 6.1 | <https://kiro.dev/docs/specs/plan/> |
| Quick Spec | Exercise 6.4 | <https://kiro.dev/docs/specs/quick-spec/> |
| Specs: tasks one at a time (Run all Tasks only for a strict chain) | Exercise 6.4 | <https://kiro.dev/docs/specs/> |
| Steering with `fileMatch` | Parts 1, 3, 4, 5 | <https://kiro.dev/docs/steering/> |
| Context providers (`#codebase`, `#url`, `#terminal`, `#steering`, `#` + file name) | All Parts | <https://kiro.dev/docs/ide/chat/> |
| Hooks: `verify-after-spec-task` (`PostTaskExec`), `block-deploy-and-push` (`PreToolUse`, Module 5) | At a glance, Exercises 6.4 and 6.9 | <https://kiro.dev/docs/hooks/> |
| Custom agent `migration-reviewer` (agent selector) | Exercise 6.5 | <https://kiro.dev/docs/custom-agents/> |
| Checkpoints (commit before shell work) | Parts 0, 1 | <https://kiro.dev/docs/checkpoints/> |
| Permissions ("Always allow" patterns) | Troubleshooting | <https://kiro.dev/docs/permissions/> |

In the prompts, `#pom.xml` and `#UserManagementApplication.java` mean: type `#` followed by the file
name and pick the file. That uses the `#file` context provider.
