package com.impact.ecommerce.controllers;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

import com.impact.ecommerce.dtos.auth.*;
import com.impact.ecommerce.services.AuthService;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Authentication")
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final AuthService auth;
    public AuthController(AuthService auth) { this.auth = auth; }

    // Lesson 4 L4-1: SRP - delegate account lookup and DTO construction to AuthService.
    @Operation(summary = "Get the authenticated account")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponse(responseCode = "200", description = "Email and role of the current account")
    @ApiResponse(responseCode = "401", description = "Authentication required or account no longer exists")
    @GetMapping("/me")
    public MeResponse me(org.springframework.security.core.Authentication authentication) {
        return auth.me(authentication.getName());
    }

    @Operation(summary = "Register a USER account")
    @ApiResponse(responseCode = "201", description = "User and token created")
    @ApiResponse(responseCode = "400", description = "Invalid email or password")
    @ApiResponse(responseCode = "409", description = "Email already exists")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(auth.register(request));
    }

    @Operation(summary = "Log in and receive a JWT")
    @ApiResponse(responseCode = "200", description = "Token returned")
    @ApiResponse(responseCode = "400", description = "Invalid request")
    @ApiResponse(responseCode = "401", description = "Invalid credentials")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @PostMapping("/login")
    public AuthResponse login(@Valid @RequestBody LoginRequest request) { return auth.login(request); }
}
