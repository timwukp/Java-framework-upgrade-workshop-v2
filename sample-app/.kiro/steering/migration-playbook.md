---
inclusion: manual
---

# Migration playbook (manual: reference it with #migration-playbook or /migration-playbook)

Use this checklist when planning or reviewing a stage. Each item names the symptom you would see if it
were missed.

## Stage 1: Spring Boot 2.2.4 → 2.7.18, then JDK 8 → 21
1. Bump the parent to 2.7.18 while still on JDK 8. Build and run the tests before touching the JDK.
2. **Bean Validation:** since Boot 2.3, `spring-boot-starter-web` no longer includes Hibernate Validator.
   Symptom: `@Valid` is silently ignored and invalid input returns 201. Fix: add
   `spring-boot-starter-validation`.
3. **JUnit 4 tests:** since Boot 2.4, `spring-boot-starter-test` no longer includes the Vintage engine.
   Symptom: the build is green but fewer tests (or zero) ran. Temporary fix: add
   `org.junit.vintage:junit-vintage-engine` (test scope). Real fix: migrate to JUnit Jupiter in stage 2.
4. Boot 2.6+ forbids circular bean references by default; fix the cycle rather than re-enabling them.
   Remove the explicit `javax.servlet` / `javax.persistence` / `javax.validation` API pins: the 2.7
   starters already bring these APIs (still `javax.*`).
5. Switch to JDK 21: set `java.version` to 21 and remove the Lombok version pin (1.18.10 cannot run on
   JDK 16+); let Boot manage Lombok.
6. Modernize Java code where it helps readability: `java.time` instead of `java.util.Date`, constructor
   injection, `@GetMapping`/`@PostMapping`, records for DTOs, switch expressions.

## Stage 2: Spring Boot 2.7.18 → 3.5.x (Java 21)
1. Bump the parent to 3.5.x. Add `spring-boot-properties-migrator` (runtime) temporarily and read its
   startup report (WARN and ERROR entries); remove it before finishing the stage.
2. `javax.*` → `jakarta.*` for Jakarta EE packages only (see migration-standards). If explicit `javax.*`
   API dependencies are still in `pom.xml`, remove them.
3. Spring Security 6: replace `WebSecurityConfigurerAdapter` with a `SecurityFilterChain` bean using the
   lambda DSL; `antMatchers` → `requestMatchers`; `authorizeRequests` → `authorizeHttpRequests`;
   in-memory users via an `InMemoryUserDetailsManager` bean.
4. Hibernate 6: remove explicit `hibernate.dialect` properties unless needed.
5. Renamed property: `server.max-http-header-size` → `server.max-http-request-header-size`. Rename it
   yourself: the migrator reports it as an ERROR ("incompatible target type") and does not map it.
6. Tests: migrate JUnit 4 → JUnit Jupiter, then remove the Vintage engine and `junit:junit`.
7. Spring MVC no longer matches trailing slashes by default: `GET /api/users/` returns 404 from stage 2
   on (200 before); check clients that call it.

## Stage 3: Spring Boot 3.5.x → 4.1.x, JDK 21 → 25
1. Fix every deprecation warning from stage 2 first; Boot 4 removes many of them.
2. Bump the parent to 4.1.x on JDK 21 and get to green; then set `java.version` to 25 on JDK 25.
3. Spring Security 7: only the lambda DSL remains (no `and()`).
4. Jackson 3 is the default (`tools.jackson.*` packages; annotations stay in
   `com.fasterxml.jackson.annotation`). Replace Jackson 2 customizers.
5. **Jackson 3 binding trap (appears at the parent bump):** with Lombok `@AllArgsConstructor` on `User`
   and the parent's `-parameters`, Jackson 3 binds request bodies through that constructor and, with
   `FAIL_ON_NULL_FOR_PRIMITIVES` now on by default, rejects a body that omits the primitive `active`.
   Symptom: `validUserIsCreated` fails with `Status expected:<201> but was:<400>` and every create
   returns 400 (the error-case tests stay green). Fix: remove `@AllArgsConstructor` from `User`;
   nothing calls it, and setters keep the default `active = true`. Not
   `spring.jackson.deserialization.fail-on-null-for-primitives=false`: constructor binding would then
   set `active` to `false`. Also expected: JSON properties are written in alphabetical order.
6. Tests: `@MockBean` is gone; use `@MockitoBean`. Test slices such as `@WebMvcTest` need the matching
   modular test starter and moved packages.
7. JDK 23+ runs no annotation processor found only on the class path: declare Lombok in
   `maven-compiler-plugin` `annotationProcessorPaths` at `${lombok.version}`. Symptom: `cannot find
   symbol` for `getEmail()` / `getName()`.
8. Verify every 4.x detail against the official Spring Boot 4.0 and 4.1 migration guides / release notes.
