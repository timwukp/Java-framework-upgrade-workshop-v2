package com.example.usermanagement.controller;

import com.example.usermanagement.config.SecurityConfig;
import com.example.usermanagement.entity.User;
import com.example.usermanagement.service.UserService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Stage 3 (Spring Boot 4.1):
 *  - @WebMvcTest moved to org.springframework.boot.webmvc.test.autoconfigure (spring-boot-starter-webmvc-test)
 *  - @MockBean was removed; @MockitoBean comes from Spring Framework's test context
 *  - @WithMockUser needs spring-boot-starter-security-test
 */
@WebMvcTest(UserController.class)
@Import(SecurityConfig.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @Test
    void unauthenticatedRequestIsRejected() throws Exception {
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser
    void getUserByIdReturnsUser() throws Exception {
        User user = new User();
        user.setId(1L);
        user.setName("Jane Doe");
        user.setEmail("jane@example.com");
        when(userService.findById(1L)).thenReturn(Optional.of(user));

        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Jane Doe"))
                .andExpect(header().exists("X-Request-Id"));
    }

    @Test
    @WithMockUser
    void unknownUserReturns404() throws Exception {
        when(userService.findById(42L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/users/42"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void invalidUserIsRejectedByBeanValidation() throws Exception {
        mockMvc.perform(post("/api/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"J\",\"email\":\"not-an-email\"}"))
                .andExpect(status().isBadRequest());

        verify(userService, never()).createUser(any(User.class));
    }
}
