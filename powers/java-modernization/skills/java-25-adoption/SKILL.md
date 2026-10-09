---
name: java-25-adoption
description: Move a Maven/Spring Boot project from Java 21 to Java 25 LTS and check that the toolchain (JDK, Maven plugins, Lombok, Mockito/Byte Buddy) supports it. Use when changing java.version to 25 or when the build fails right after switching JDKs.
---

# Java 21 → 25

## 1. Toolchain first
- Install a JDK 25 (for example Amazon Corretto 25). Check that **both** `java -version` and `mvn -v`
  report 25. Maven uses `JAVA_HOME`, not necessarily the `java` on your `PATH`.
- Set `java.version` to 25 in `pom.xml`. With the Spring Boot parent this drives the compiler release.

## 2. Annotation processors (most common JDK 23+ break)
Since JDK 23, javac **no longer runs annotation processors found only on the class path**. Lombok,
MapStruct, Hibernate's metamodel generator and similar tools then silently do nothing. The build fails
with `cannot find symbol` for generated getters, setters or builders. Declare them explicitly:

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <configuration>
        <annotationProcessorPaths>
            <path>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>${lombok.version}</version>
            </path>
        </annotationProcessorPaths>
    </configuration>
</plugin>
```

## 3. Libraries that inspect bytecode
Tools that read or generate class files must know the new class file version:
- **Lombok:** JDK 25 support was added in 1.18.40. Remove version pins and let Spring Boot manage it
  (Boot 3.5.16 and 4.1.1 manage 1.18.46). It still needs the processor declaration from section 2.
- **Byte Buddy / Mockito:** older Byte Buddy versions reject newer JDKs at runtime, so mock-based tests
  fail even though compilation succeeds. Use the version your Spring Boot release manages. Only
  override it when the error message names Byte Buddy and the Java version.
- **Hibernate** also uses Byte Buddy. Startup errors that mention it point to the same cause.
- **Maven plugins:** use the versions managed by the Spring Boot parent. Explicitly pinned old plugins
  (compiler, surefire, jacoco) are the usual culprits.

## 4. Language and API changes worth a look
- The Security Manager has been permanently disabled since JDK 24 (JEP 486). Code that relies on
  `System.getSecurityManager()`, `AccessController` or `SecurityManager` no longer gets any
  protection from it. Remove it or replace it.
- Optional modernization, in small reviewed steps: records for DTOs, pattern matching for `switch`,
  sequenced collections (`getFirst()` / `getLast()`), virtual threads for blocking I/O. On Spring Boot,
  virtual threads are switched on with `spring.threads.virtual.enabled=true`; load-test before
  enabling them in production.

## 5. Verify
1. `mvn -B clean verify` on JDK 25 (`clean` matters: Maven may not recompile after a JDK switch). The test count is unchanged.
2. `mvn -B dependency:tree -Dincludes=net.bytebuddy,org.projectlombok` shows the resolved versions.
3. Run the app once and check the startup log for warnings about the JDK version.
