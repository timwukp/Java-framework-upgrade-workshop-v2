---
inclusion: fileMatch
fileMatchPattern: ["src/test/**/*.java", "**/src/test/**/*.java"]
---

# Test rules (loaded when test files are in context)

- Keep every existing test scenario. A migration may rename or restructure a test, never drop it.
- Report the "Tests run / Failures / Errors / Skipped" line before and after a change.
- JUnit Jupiter is the target from stage 2: `@BeforeEach`/`@AfterEach`, `assertThrows`,
  `@ExtendWith(MockitoExtension.class)`; Spring test slices need no runner annotation.
- Do not use `@Disabled`, empty test bodies, or loosened assertions to get a green build.
- Web-layer tests must keep covering: unauthenticated requests are rejected, invalid input is rejected
  by Bean Validation, and the `X-Request-Id` header is present.
