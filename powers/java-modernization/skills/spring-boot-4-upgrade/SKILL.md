---
name: spring-boot-4-upgrade
description: Upgrade a Spring Boot 3.5.x application to Spring Boot 4.x (Spring Framework 7, Jakarta EE 11, Jackson 3, Spring Security 7, modular starters, @MockitoBean). Use when bumping the Boot parent to 4.x or when tests fail after it with missing @MockBean, @WebMvcTest or Jackson 2 classes.
---

# Spring Boot 3.5 → 4.x

Source of truth: the official "Spring Boot 4.0 Migration Guide" and the 4.0 / 4.1 release notes on the
spring-boot GitHub wiki. When something here disagrees with them, they win.

## 0. Preconditions
- Start from the **latest 3.5.x** with a green build ("make sure to upgrade to the latest available 3.5.x
  version").
- Fix deprecation warnings first: classes, methods and properties deprecated in 3.x are removed in 4.0.
  `mvn -B clean test-compile -Dmaven.compiler.showDeprecation=true` lists them for main **and** test
  sources (`@MockBean` lives in tests). Use `clean` so every file is recompiled, and don't use `-q`, which
  hides warnings.
- Java 17 is the minimum; this workshop targets Java 25.

## 1. Build file
1. Change one variable at a time. First set the `spring-boot-starter-parent` version to 4.1.x and stay
   on the current JDK (Boot 4 runs on Java 17+). Get to green, then switch the JDK and `java.version` to 25.
   The parent bump is where the Jackson 3 binding trap (section 3) shows up, not the JDK switch.
2. Rename starters to the modular ones. Example: `spring-boot-starter-web` → `spring-boot-starter-webmvc`.
   The old names still resolve but are deprecated.
3. Use per-technology test starters instead of only `spring-boot-starter-test`, for example
   `spring-boot-starter-webmvc-test` and `spring-boot-starter-security-test`. Each brings
   `spring-boot-starter-test` transitively. `@WithMockUser` needs `spring-boot-starter-security-test`.
4. If the upgrade is too big for one step, the `spring-boot-starter-classic` /
   `spring-boot-starter-test-classic` starters are a temporary bridge. Plan to remove them.
5. Optional: add `spring-boot-properties-migrator` (runtime) for one run to find renamed properties.

## 2. Tests
| Before (3.x) | After (4.x) |
|---|---|
| `org.springframework.boot.test.mock.mockito.MockBean` | `org.springframework.test.context.bean.override.mockito.MockitoBean` |
| `@SpyBean` | `@MockitoSpyBean` (same package as `@MockitoBean`) |
| `org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest` | `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` |
| `@SpringBootTest` gives MockMvc | add `@AutoConfigureMockMvc` explicitly |

`@MockitoBean` fields are allowed in test classes but not in `@Configuration` classes.

## 3. Jackson 3
- Jackson 3 is the default. Packages move from `com.fasterxml.jackson` to `tools.jackson`, **except**
  annotations, which stay in `com.fasterxml.jackson.annotation`.
- `Jackson2ObjectMapperBuilderCustomizer` → `JsonMapperBuilderCustomizer`
  (`org.springframework.boot.jackson.autoconfigure`). To replace the mapper, define a `JsonMapper` bean,
  not an `ObjectMapper`.
- Prefer configuration properties where they exist. `spring.jackson.default-property-inclusion` and
  `spring.jackson.time-zone` work on both 3.5 and 4.x.
- Short-term fallbacks: `spring.jackson.use-jackson2-defaults=true`, or the deprecated
  `spring-boot-jackson2` module.
- **Trap: stricter defaults break request binding at runtime, not at compile time.** Jackson 3 turns
  `DeserializationFeature.FAIL_ON_NULL_FOR_PRIMITIVES` on by default. The Spring Boot parent compiles
  with `-parameters`, so Jackson 3 can bind a request body through an all-args constructor (for
  example Lombok `@AllArgsConstructor` on an entity or DTO) where Jackson 2 used the no-args
  constructor and setters. A body that omits a primitive field then fails with
  `HttpMessageNotReadableException` (`` JSON parse error: Cannot map `null` into type `boolean` ``),
  and every such POST returns 400. Tests that only check error cases stay green: a 400 test can pass for
  the wrong reason. Seen in the workshop's 2026-10-10 dry run (Spring Boot 4.1.1, `boolean active`
  missing from the JSON).
  - Fix: remove the all-args constructor if nothing calls it (`grep -rn "new <Type>(" src`). Jackson
    then uses the no-args constructor and setters, and field defaults (`active = true`) stay.
  - Don't fix it with `spring.jackson.deserialization.fail-on-null-for-primitives=false`: binding
    still goes through the constructor, which then gets `false`/`0` instead of the field default, a
    silent behaviour change for every request body.
- **Property order:** Jackson 3 writes JSON properties in alphabetical order (Jackson 2 used field
  order), seen in the same dry run. Clients or tests that compare JSON as text notice;
  `@JsonPropertyOrder` pins an order where it matters.

## 4. Spring Security 7
- Only the lambda DSL is valid, and `.and()` is gone. If stage 2 already uses a `SecurityFilterChain`
  with lambdas, nothing changes.
- `AntPathRequestMatcher` and `MvcRequestMatcher` are no longer supported; String patterns use
  `PathPatternRequestMatcher`.

## 5. Other notable changes
- Undertow support was dropped.
- Hibernate 7.x and Jakarta Persistence 3.2.
- `@EntityScan` moved to `org.springframework.boot.persistence.autoconfigure.EntityScan`.
- The H2 console is a separate module (`spring-boot-h2console`).
- Liveness and readiness probes are enabled by default.

## 6. Verify
1. `mvn -B clean verify` after the parent bump (still on the old JDK), then again on JDK 25. The "Tests
   run" total must equal stage 2's. On JDK 23+, Lombok must be declared in `annotationProcessorPaths`
   (see the java-25-adoption skill).
2. **Test a create request whose body omits optional and primitive fields** (for example a POST without
   `active`) and expect 201 with the field defaults. If the web tests only cover error cases, add one
   such success test before the parent bump: error-case tests don't catch the Jackson 3 trap above.
3. Start the app and call one endpoint with credentials. Check the JSON shape (null fields omitted,
   ISO-8601 dates, properties now in alphabetical order).
4. Search for leftovers: `import org.springframework.boot.test.mock.mockito`, `com.fasterxml.jackson.databind`,
   `spring-boot-starter-web</artifactId>`.
