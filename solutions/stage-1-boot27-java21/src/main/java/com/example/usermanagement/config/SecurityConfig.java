package com.example.usermanagement.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configuration.WebSecurityConfigurerAdapter;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.UUID;

/**
 * Legacy Spring Security 5.2 configuration (WebSecurityConfigurerAdapter, antMatchers, and()).
 * Removed in Spring Security 6/7 - migrating this class is a core workshop exercise.
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig extends WebSecurityConfigurerAdapter {

    private static final Logger log = LoggerFactory.getLogger(SecurityConfig.class);

    @Value("${app.security.admin.username:admin}")
    private String adminUsername;

    @Value("${app.security.admin.password:}")
    private String adminPassword;

    @Value("${app.security.user.username:user}")
    private String userUsername;

    @Value("${app.security.user.password:}")
    private String userPassword;

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .csrf()
                .ignoringAntMatchers("/api/**")
            .and()
            .authorizeRequests()
                .antMatchers("/api/public/**").permitAll()
                .antMatchers("/api/users/**").authenticated()
                .anyRequest().authenticated()
            .and()
            .httpBasic();
    }

    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.inMemoryAuthentication()
            .withUser(adminUsername)
            .password(passwordEncoder().encode(passwordOrGenerated(adminUsername, adminPassword)))
            .roles("ADMIN")
            .and()
            .withUser(userUsername)
            .password(passwordEncoder().encode(passwordOrGenerated(userUsername, userPassword)))
            .roles("USER");
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /** No passwords are stored in the repo: use the configured one, or generate one for this run. */
    private static String passwordOrGenerated(String username, String configured) {
        if (configured != null && !configured.isEmpty()) {
            return configured;
        }
        String generated = UUID.randomUUID().toString();
        log.warn("No password configured for user '{}'. Generated password for this run: {}", username, generated);
        return generated;
    }
}
