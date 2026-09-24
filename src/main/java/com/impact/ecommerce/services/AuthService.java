package com.impact.ecommerce.services;

import com.impact.ecommerce.dtos.auth.*;
import com.impact.ecommerce.entities.*;
import com.impact.ecommerce.exceptions.LessonTodo;
import com.impact.ecommerce.repositories.UserRepository;
import com.impact.ecommerce.security.JwtService;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

@Service
public class AuthService {
    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository users, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        if (users.existsByEmail(email))
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already exists");
        if (request.password().getBytes(StandardCharsets.UTF_8).length > 72)
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password must fit in 72 UTF-8 bytes");
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(hashPassword(request.password()));
        user.setRole(Role.USER); // Never accept a role from public registration.
        users.saveAndFlush(user);
        return response(user); // 201 plus a token: required by the existing frontend's register form.
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        User user = users.findByEmail(request.email().trim().toLowerCase(Locale.ROOT))
                .orElseThrow(this::badCredentials);
        if (!passwordMatches(request.password(), user.getPasswordHash())) throw badCredentials();
        return response(user);
    }

    private String hashPassword(String rawPassword) {
        // TODO Lesson 2 L2-3: return the BCrypt hash using passwordEncoder.
        // Never return rawPassword.
        throw LessonTodo.required("L2-3");
    }

    private boolean passwordMatches(String rawPassword, String storedHash) {
        // TODO Lesson 2 L2-4: compare rawPassword with storedHash using passwordEncoder.
        // Do not hash again and compare strings: BCrypt uses a random salt.
        return false;
    }

    private AuthResponse response(User user) {
        return new AuthResponse(jwtService.generateToken(user), user.getId(), user.getEmail(), user.getRole().name());
    }

    private ResponseStatusException badCredentials() {
        return new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid email or password");
    }
}
