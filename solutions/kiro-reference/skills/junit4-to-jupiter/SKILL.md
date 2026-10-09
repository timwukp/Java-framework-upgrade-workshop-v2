---
name: junit4-to-jupiter
description: Migrate JUnit 4 tests to JUnit Jupiter (JUnit 5) without losing a test - @Before/@After, @Test(expected), org.junit.Assert, @RunWith(MockitoJUnitRunner) and @RunWith(SpringRunner) - and then remove junit-vintage-engine and junit:junit from the build. Use when upgrading tests for Spring Boot 3 or 4, when removing the JUnit Vintage engine, or when org.junit.Test, @RunWith or org.junit.Assert still appear in test sources.
---

# JUnit 4 → JUnit Jupiter

Goal: the same test scenarios, running on JUnit Jupiter only, with the same "Tests run" total as
before the migration. A green build with fewer tests is a failed migration.

## 0. Record the baseline (before changing anything)
1. Run `mvn -B verify` and write down the summary line
   `Tests run: X, Failures: 0, Errors: 0, Skipped: 0`.
2. Count the test methods per file: `grep -rc "@Test" src/test/java`.
Keep both numbers. Report them before and after the migration.

## 1. Map annotations and APIs
| JUnit 4 | JUnit Jupiter |
|---|---|
| `import org.junit.Test` | `import org.junit.jupiter.api.Test` |
| `@Before` | `@BeforeEach` |
| `@After` | `@AfterEach` (see the note below) |
| `@BeforeClass` / `@AfterClass` (static methods) | `@BeforeAll` / `@AfterAll` (still static) |
| `@Test(expected = X.class)` | plain `@Test`, and wrap **only the call that should throw** in `assertThrows(X.class, () -> ...)` |
| `@Rule ExpectedException` with `expectMessage(...)` | `X ex = assertThrows(X.class, () -> ...)` followed by an assertion on `ex.getMessage()` |
| `@Test(timeout = 500)` | `@Timeout(value = 500, unit = TimeUnit.MILLISECONDS)` |
| `import static org.junit.Assert.*` | `import static org.junit.jupiter.api.Assertions.*` |
| `assertEquals("message", expected, actual)` | `assertEquals(expected, actual, "message")`: the message moves to the **last** parameter |
| `org.junit.Assert.assertThat` (Hamcrest) | `org.hamcrest.MatcherAssert.assertThat` |
| `org.junit.Assume.*` | `org.junit.jupiter.api.Assumptions.*` |
| `@Rule TemporaryFolder` | `@TempDir` |
| `@Category(...)` | `@Tag("...")` |
| `@Ignore` | `@Disabled`, only where the test was already ignored. Never add one. |
| `@RunWith(MockitoJUnitRunner.class)` | `@ExtendWith(MockitoExtension.class)` with `import org.mockito.junit.jupiter.MockitoExtension` |
| `@RunWith(SpringRunner.class)` on a class with `@SpringBootTest`, `@WebMvcTest` or `@DataJpaTest` | Remove it. These annotations already include `@ExtendWith(SpringExtension.class)`. |
| `@RunWith(SpringRunner.class)` without a Spring Boot test annotation | `@ExtendWith(SpringExtension.class)` |
| `@RunWith(Parameterized.class)` | `@ParameterizedTest` with a source such as `@MethodSource`; keep every parameter set |

Notes:
- **`public` is optional.** Jupiter test classes and methods can be package-private
  (`class UserServiceTest`, `void createUser()`). They must not be `private`.
- **Teardown that only resets fields.** Jupiter creates a new test instance for every test method by
  default, so an `@After` method that only sets fields to `null` can be deleted. Anything else
  (closing resources, clearing static state, deleting files) becomes `@AfterEach`.
- **Method names.** Dropping a `test` prefix (`testCreateUser` → `createUser`) is optional. Keep the
  meaning of every name.
- **Mockito strictness.** `MockitoExtension` uses strict stubs by default, so a migrated test may now
  report `UnnecessaryStubbingException` or `PotentialStubbingProblem`. Fix the stub that the test
  never used, or the stub set up with the wrong arguments. Do not make the whole class lenient.
- **Leave other migrations alone.** `@MockBean`, `@Import(...)`, Spring test slices and assertions
  libraries other than JUnit's own stay as they are. This skill changes the test engine only.

## 2. Apply, one class at a time
1. Migrate one test class: imports, annotations, assertions. Keep every `@Test` method, every
   assertion and every `verify(...)` call.
2. Run `mvn -B -q test-compile` and fix compile errors in that class only.
3. Run `mvn -B test -Dtest=<ClassName>` and check that its "Tests run" equals its `@Test` count.
4. Continue with the next class.

While `junit-vintage-engine` is still on the classpath, JUnit 4 and Jupiter tests both run, so the
total does not change yet. The real proof is step 3 below.

## 3. Remove JUnit 4 from the build (only after every class is migrated)
1. Remove `org.junit.vintage:junit-vintage-engine` and `junit:junit` from `pom.xml` (both test scope).
   `spring-boot-starter-test` already brings JUnit Jupiter and `mockito-junit-jupiter`.
2. Search for leftovers; both commands must print nothing:
   - `grep -rnE 'import (static )?org\.junit\.(Test|Before|After|BeforeClass|AfterClass|Ignore|Rule|ClassRule|Assert|Assume|runner|experimental)' src/test`
   - `grep -rnE '@RunWith|@Test\(' src/test`
3. Confirm the dependencies are gone: `mvn -B dependency:tree -Dincludes=junit:junit,org.junit.vintage`
   lists neither artifact.
4. Run `mvn -B verify`. The "Tests run" total must equal the baseline from step 0. A compile error
   such as "package org.junit does not exist" means a class still uses JUnit 4: go back to section 2.

## 4. Never
- Never delete, empty, comment out or `@Disabled` a test to get a green build.
- Never loosen an assertion, or replace `assertThrows` with a `try`/`catch` that swallows the exception.
- Never change production code as part of this skill.
- Never report success without the before/after "Tests run" numbers.
