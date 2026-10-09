---
inclusion: always
---

# Migration standards (always on)

This workspace is a workshop exercise: a legacy Java 8 + Spring Boot 2.2.4 service that is migrated in
stages. Work on one stage at a time and never skip ahead.

| Stage | Java | Spring Boot | Spring Framework | Namespace |
|---|---|---|---|---|
| 0 (baseline) | 8 | 2.2.4 | 5.2.3 | `javax.*` |
| 1 | 21 | 2.7.18 | 5.3.x | `javax.*` |
| 2 | 21 | 3.5.x | 6.2.x | `jakarta.*` |
| 3 (target) | 25 | 4.1.x | 7.0.x | `jakarta.*` |

## Rules
- Ask which stage we are in if it is not obvious from `pom.xml`. Do not jump stages in one change.
- Prefer versions managed by the Spring Boot parent/BOM. Only pin a version when there is a written reason.
- Never invent version numbers, class names or property names. If unsure, say so and propose how to check
  (Maven output, the official migration guide, or `mvn dependency:tree`).
- Only the Jakarta EE packages move to `jakarta.*` (`javax.persistence`, `javax.validation`,
  `javax.servlet`, `javax.inject`, `javax.annotation.PostConstruct/PreDestroy`, `javax.transaction`, JAXB, …;
  see the jakarta-namespace-migration skill). JDK packages such as `javax.sql`, `javax.crypto`, `javax.net`,
  `javax.naming` and `javax.transaction.xa` stay as they are.
- A change is done only when `mvn -B clean verify` passes on the stage's JDK **and the number of tests run
  did not go down**. Report the "Tests run" numbers before and after.
- During spec tasks the `verify-after-spec-task` hook runs that build after every task and reports the
  "Tests run" line. Do not start your own Maven build for the same check, and never run two Maven builds
  at the same time in this project (they share `target/`).
- Never make tests pass by deleting them, adding `@Ignore`/`@Disabled`, or weakening assertions.
- Never commit secrets. Passwords come from environment variables; see `.env.example`.
- Keep changes small and reviewable; explain each non-obvious edit in one sentence.
