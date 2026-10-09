---
name: spring-security-lambda-dsl
description: Migrate Spring Security configuration from WebSecurityConfigurerAdapter and chained and() calls to a SecurityFilterChain bean with the lambda DSL (Spring Security 6 and 7). Use when upgrading to Spring Boot 3 or 4, or when WebSecurityConfigurerAdapter, antMatchers, authorizeRequests or and() fail to compile.
---

# Spring Security: adapter → SecurityFilterChain + lambda DSL

Spring Security 6.0 removed `WebSecurityConfigurerAdapter`. Spring Security 7 requires the lambda DSL:
"the prior configuration style will not be valid in Spring Security 7", and `.and()` is removed.
Writing the lambda DSL already in stage 2 (Security 6) means stage 3 needs no further changes here.

## 1. Replace the adapter with beans
| Before (5.x) | After (6.x / 7.x) |
|---|---|
| `class X extends WebSecurityConfigurerAdapter` | plain `@Configuration` class |
| `protected void configure(HttpSecurity http)` | `@Bean SecurityFilterChain securityFilterChain(HttpSecurity http)` returning `http.build()` |
| `configure(AuthenticationManagerBuilder auth)` with `inMemoryAuthentication()` | `@Bean UserDetailsService` returning `new InMemoryUserDetailsManager(User.withUsername(..)…build(), …)` |
| `.authorizeRequests()` | `.authorizeHttpRequests(auth -> auth …)` |
| `.antMatchers("/x/**")` | `.requestMatchers("/x/**")` |
| `.csrf().ignoringAntMatchers("/api/**")` | `.csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))` |
| `.httpBasic()` | `.httpBasic(Customizer.withDefaults())` |
| `.and()` | remove; each section is its own lambda |

## 2. Shape of the result
```java
@Bean
SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf.ignoringRequestMatchers("/api/**"))
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/public/**").permitAll()
            .requestMatchers("/api/users/**").authenticated()
            .anyRequest().authenticated())
        .httpBasic(Customizer.withDefaults());
    return http.build();
}
```
Keep the original rules **in the same order**. Authorization rules are evaluated top to bottom.

## 3. Behaviour to re-check (security must not change silently)
- Unauthenticated requests to `/api/users/**` still get 401.
- CSRF is still ignored only for `/api/**`.
- Passwords are still BCrypt-encoded and still never hard-coded (keep the generated-password fallback).
- Spring Security 6 applies authorization to every dispatch type (including error dispatches). If error
  responses change from 4xx to 401/403, review the rules rather than opening everything up.

## 4. Tests
- A `SecurityFilterChain` bean in a plain `@Configuration` class may not be picked up by `@WebMvcTest`,
  which only scans web-layer components. If security tests suddenly return 403 or behave as if default
  security were active, add `@Import(SecurityConfig.class)` to the test class.
- Spring Boot 4: `@WithMockUser` needs `spring-boot-starter-security-test`.
- Run `mvn -B verify`; the web-layer tests must keep passing without being weakened.
