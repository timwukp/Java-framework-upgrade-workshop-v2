package com.example.usermanagement.controller;

import com.example.usermanagement.entity.User;
import com.example.usermanagement.service.UserService;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.junit4.SpringRunner;
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
 * Web-layer tests. Migration traps covered here:
 *  - Spring Boot 2.4+ drops the JUnit Vintage engine: JUnit 4 tests silently stop running (Module 2)
 *  - Spring Boot 2.3+ drops Hibernate Validator from starter-web: @Valid is silently ignored (Module 2)
 *  - JUnit 4 SpringRunner -> JUnit Jupiter (Module 3)
 *  - @MockBean removed in Spring Boot 4 -> @MockitoBean (Module 4)
 */
@RunWith(SpringRunner.class)
@WebMvcTest(UserController.class)
public class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Test
    public void unauthenticatedRequestIsRejected() throws Exception {
        mockMvc.perform(get("/api/users"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser
    public void getUserByIdReturnsUser() throws Exception {
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
    public void unknownUserReturns404() throws Exception {
        when(userService.findById(42L)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/users/42"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    public void invalidUserIsRejectedByBeanValidation() throws Exception {
        mockMvc.perform(post("/api/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"J\",\"email\":\"not-an-email\"}"))
                .andExpect(status().isBadRequest());

        verify(userService, never()).createUser(any(User.class));
    }

    /**
     * The body omits "active" on purpose, as a real client might. Jackson 3 (Spring Boot 4) fails on a
     * missing primitive when it binds through a constructor: this test catches that, the others don't.
     */
    @Test
    @WithMockUser
    public void validUserIsCreated() throws Exception {
        User saved = new User();
        saved.setId(7L);
        saved.setName("Jane Doe");
        saved.setEmail("jane@example.com");
        when(userService.createUser(any(User.class))).thenReturn(saved);

        mockMvc.perform(post("/api/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Jane Doe\",\"email\":\"jane@example.com\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(7));
    }
}
