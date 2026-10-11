# Migration cheat sheet

What changes at each stage, and why. The day sheet is [quick-reference.md](quick-reference.md);
symptoms and fixes are in [troubleshooting.md](troubleshooting.md).

## Stage 1: Spring Boot 2.2.4 → 2.7.18, JDK 8 → 21
| Change | Why |
|---|---|
| Parent `2.7.18` | Last 2.x line; compatible up to Java 21 |
| Add `spring-boot-starter-validation` | Since Boot 2.3 it isn't in the web starter; `@Valid` is silently ignored without it |
| Add `junit-vintage-engine` (test) | Since Boot 2.4 it isn't in starter-test; JUnit 4 tests silently stop running |
| Remove the Lombok pin | 1.18.10 can't run on JDK 16+; Boot 2.7.18 manages 1.18.30 (first with JDK 21 support) |
| `java.version` 21 | — |
| No `byte-buddy.version` override | Not needed: stage 1 passes on Corretto 21 with Boot's Byte Buddy 1.12.23 (verified in the 2026-10-10 dry run). Troubleshooting only: if Mockito/Hibernate fails naming Byte Buddy and Java 21, override `byte-buddy.version` |

## Stage 2: Spring Boot 2.7.18 → 3.5.x (Java 21)
| Before | After |
|---|---|
| `javax.persistence/validation/servlet/inject/transaction.*` | `jakarta.*` (JDK `javax.sql`, `javax.crypto`, `javax.transaction.xa`… stay) |
| `extends WebSecurityConfigurerAdapter` | `@Bean SecurityFilterChain` + lambda DSL |
| `inMemoryAuthentication()` | `@Bean UserDetailsService` → `InMemoryUserDetailsManager` |
| `authorizeRequests` / `antMatchers` | `authorizeHttpRequests` / `requestMatchers` |
| `server.max-http-header-size` | `server.max-http-request-header-size` |
| `hibernate.dialect` property | Usually not needed with Hibernate 6 |
| JUnit 4 + Vintage | JUnit Jupiter only |
| (web tests) | `@Import(SecurityConfig.class)` if security no longer applies in `@WebMvcTest` |

## Stage 3: Spring Boot 3.5.x → 4.1.x, Java 21 → 25
| Before | After |
|---|---|
| `spring-boot-starter-web` | `spring-boot-starter-webmvc` |
| `spring-boot-starter-test` only | `spring-boot-starter-webmvc-test`, `spring-boot-starter-security-test` |
| `org.springframework.boot.test.mock.mockito.MockBean` | `org.springframework.test.context.bean.override.mockito.MockitoBean` |
| `org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest` | `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest` |
| `Jackson2ObjectMapperBuilderCustomizer` | `spring.jackson.*` properties, or `JsonMapperBuilderCustomizer` |
| `com.fasterxml.jackson.databind.*` | `tools.jackson.databind.*` (annotations unchanged) |
| `.and()` / non-lambda security DSL | Lambda DSL only (Spring Security 7) |
| `java.version` 21 | 25 (Lombok ≥ 1.18.40) |
| Lombok only as a `provided` dependency | Also in `maven-compiler-plugin` `annotationProcessorPaths` (`${lombok.version}`): since JDK 23, javac no longer runs annotation processors it finds only on the class path |
| Lombok `@AllArgsConstructor` on `User` | Remove it: with Jackson 3 it makes every POST return 400 (`active` missing from the JSON); `validUserIsCreated` catches it |
