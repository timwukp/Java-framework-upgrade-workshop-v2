---
name: jakarta-namespace-migration
description: Migrate Java EE javax.* imports, annotations and dependencies to Jakarta EE jakarta.* for Spring Boot 3 / Spring Framework 6. Use when upgrading from Spring Boot 2.x to 3.x, or when a build fails with missing javax.persistence, javax.validation or javax.servlet classes.
---

# Jakarta namespace migration

## 1. Find what must move
Search the codebase (main and test sources) for these import prefixes. Only these move:

| From | To |
|---|---|
| `javax.persistence.` | `jakarta.persistence.` |
| `javax.validation.` | `jakarta.validation.` |
| `javax.servlet.` | `jakarta.servlet.` |
| `javax.transaction.` (e.g. `Transactional`, `UserTransaction`) | `jakarta.transaction.` |
| `javax.annotation.PostConstruct`, `PreDestroy`, `Resource`, `javax.annotation.security.*` | `jakarta.annotation.*` |
| `javax.inject.` (Spring 6 no longer supports `javax.inject`) | `jakarta.inject.` |
| `javax.xml.bind.` (JAXB), `javax.xml.ws.` (JAX-WS), `javax.ws.rs.` (JAX-RS) | `jakarta.xml.bind.`, `jakarta.xml.ws.`, `jakarta.ws.rs.` |
| `javax.jms.`, `javax.mail.`, `javax.websocket.`, `javax.ejb.`, `javax.faces.`, `javax.el.` | the matching `jakarta.*` package |

**Do not touch** JDK packages: `javax.sql`, `javax.crypto`, `javax.net`, `javax.naming`, `javax.security.auth`,
`javax.management`, `javax.transaction.xa`, `javax.annotation.processing`, and the JAXP part of `javax.xml`
(`javax.xml.parsers`, `javax.xml.transform`, `javax.xml.stream`, …). Renaming them breaks the build.
Also leave non-Java-EE annotations such as `javax.annotation.Nonnull` (JSR-305) alone.

Also check non-Java files: `META-INF/persistence.xml`, `orm.xml`, `web.xml`, string literals such as
`"javax.persistence.*"` hint names, and test resources.

## 2. Fix the build file
- Remove explicit `javax.servlet:javax.servlet-api`, `javax.persistence:javax.persistence-api` and
  `javax.validation:validation-api` dependencies. The Spring Boot 3 starters bring the Jakarta APIs.
- Make sure `spring-boot-starter-validation` is present when the code uses `@Valid` or constraint
  annotations; without a provider, validation is silently skipped.

## 3. Apply and verify
1. Change imports file by file; keep the rest of each file unchanged.
2. Run `mvn -B -q compile` and fix remaining `javax` references reported by the compiler.
3. Run `mvn -B verify` and compare the "Tests run" total with the previous stage.
4. Search again; this must print nothing:
   `grep -rnE '^import (static )?javax\.((persistence|validation|servlet|inject|jms|mail|websocket|ejb|faces|el|xml\.bind|xml\.ws|ws\.rs)\.|annotation\.(PostConstruct|PreDestroy|Resource|security\.)|transaction\.[A-Z*])' src`

## Notes
- Third-party libraries compiled against `javax.*` (old Hibernate Validator, old Jersey, etc.) must be
  upgraded to their Jakarta versions; mixing both namespaces fails at runtime.
- The `jakarta-import-guard` hook in this workspace re-checks every Java file the agent saves.
