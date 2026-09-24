package com.impact.ecommerce.dtos.auth;

public record AuthResponse(String token, Long userId, String email, String role) { }
