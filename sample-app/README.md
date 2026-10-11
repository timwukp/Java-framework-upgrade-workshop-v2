# Sample App: User Management Service (legacy starting point)

A small REST service that is **deliberately old**: Java 8, Spring Boot 2.2.4 (Spring Framework 5.2.3),
Spring Security 5.2, `javax.*` APIs, Lombok 1.18.10 and JUnit 4. Workshop participants migrate it in
stages to **Java 25 + Spring Boot 4.1 (Spring Framework 7)** using Kiro:

| Stage | Module | Java | Spring Boot |
|---|---|---|---|
| 0 (this folder) | 1 | 8 | 2.2.4 |
| 1 | 2 | 21 | 2.7.18 |
| 2 | 3 | 21 | 3.5.x |
| 3 | 4 | 25 | 4.1.x |

**Open this `sample-app/` folder (not the repository root) as your Kiro workspace.** It contains the
`.kiro/` configuration used in the workshop.

> Do not "fix" anything in this folder before the workshop starts. Every outdated pattern is an exercise.

## Run it (baseline, JDK 8)

```bash
# Requires JDK 8 on PATH (for example Amazon Corretto 8) and Maven 3.9+
mvn clean verify
mvn spring-boot:run
```

The app uses an in-memory **H2** database by default, so nothing else needs to be installed.

On startup, look for these log lines. They hold the generated passwords for the two in-memory users
(`admin`, `user`), because no passwords are stored in this repository:

```text
WARN ... No password configured for user 'admin'. Generated password for this run: <uuid>
WARN ... No password configured for user 'user'. Generated password for this run: <uuid>
```

To choose your own, export `APP_ADMIN_PASSWORD` / `APP_USER_PASSWORD` (see [`.env.example`](.env.example)).

```bash
curl -u admin:<password> http://localhost:8080/api/users
curl -u admin:<password> -H 'Content-Type: application/json' \
     -d '{"name":"Jane Doe","email":"jane@example.com"}' http://localhost:8080/api/users
```

### Optional: PostgreSQL

```bash
export POSTGRES_PASSWORD=<choose-a-local-password>
docker compose up -d
DB_PASSWORD=$POSTGRES_PASSWORD SPRING_PROFILES_ACTIVE=postgres mvn spring-boot:run
```

## API

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/users` | Basic | List users |
| GET | `/api/users/{id}` | Basic | Get one user (404 if missing) |
| POST | `/api/users` | Basic | Create a user (Bean Validation on name/email) |
| PUT | `/api/users/{id}` | Basic | Update a user |
| DELETE | `/api/users/{id}` | Basic | Delete a user |

## What is outdated on purpose

| Area | Legacy pattern in this app | Where it is fixed |
|---|---|---|
| Build | `java.version` 1.8, Spring Boot 2.2.4 parent (documented as compatible up to Java 13) | Modules 2-4 |
| Lombok | Pinned to 1.18.10 (fails on JDK 16+; on JDK 21 the build stops with an `IllegalAccessError`) | Module 2 |
| Java language | `java.util.Date`, field injection, `@RequestMapping(method = ...)` | Module 2 |
| Bean Validation | Relies on Boot 2.2's `spring-boot-starter-web` bringing Hibernate Validator; Boot 2.3+ does not, so `@Valid` silently stops working | Module 2 |
| Test engine | JUnit 4 tests run on the Vintage engine bundled with Boot 2.2; Boot 2.4+ no longer bundles it, so the tests silently stop running | Module 2 |
| Jakarta EE | `javax.persistence`, `javax.validation`, `javax.servlet` (`RequestIdFilter`) | Module 3 |
| Spring Security | `WebSecurityConfigurerAdapter`, `antMatchers`, `authorizeRequests`, `ignoringAntMatchers`, `and()` chaining | Modules 3-4 |
| Spring MVC | Hand-rolled error map instead of `ProblemDetail` (RFC 9457) | Module 3 |
| Configuration | `server.max-http-header-size` (renamed in Boot 3), explicit Hibernate dialects | Module 3 |
| Jackson | `Jackson2ObjectMapperBuilderCustomizer` (Jackson 2); Boot 4 defaults to Jackson 3 | Module 4 |
| Jackson binding | Lombok `@AllArgsConstructor` on `User`: harmless with Jackson 2, but with Jackson 3 every POST that omits `active` gets 400 (the `validUserIsCreated` test catches it) | Module 4 |
| Tests | JUnit 4, `MockitoJUnitRunner`, `SpringRunner` (Module 3); `@MockBean`, removed in Boot 4 (Module 4) | Modules 3-4 |

## Project layout

```text
sample-app/
├── pom.xml
├── docker-compose.yml               # optional PostgreSQL
├── .env.example                     # optional overrides, no secrets
└── src/
    ├── main/java/com/example/usermanagement/
    │   ├── UserManagementApplication.java
    │   ├── config/      SecurityConfig.java, JacksonConfig.java
    │   ├── controller/  UserController.java, ApiExceptionHandler.java
    │   ├── entity/      User.java
    │   ├── repository/  UserRepository.java
    │   ├── service/     UserService.java
    │   └── web/         RequestIdFilter.java
    ├── main/resources/  application.properties, application-postgres.properties
    └── test/java/com/example/usermanagement/
        ├── controller/  UserControllerTest.java   # @WebMvcTest + @MockBean
        └── service/     UserServiceTest.java      # JUnit 4 + Mockito
```
