---
inclusion: fileMatch
fileMatchPattern: "**/pom.xml"
---

# pom.xml rules (loaded when a pom.xml is in context)

- Change the `spring-boot-starter-parent` version first; it manages Spring Framework, Hibernate, Jackson,
  Lombok, H2, the PostgreSQL driver, JUnit and Mockito.
- Remove `<version>` tags from dependencies the parent manages. Keep a pin only with an XML comment
  explaining why.
- Set the Java level with the `java.version` property (the Boot parent maps it to the compiler).
- Do not add repositories, plugins or dependencies that are not needed for the current stage.
- After editing, run `mvn -B dependency:tree -Dincludes=<groupId>` to confirm the resolved version
  instead of guessing it.
