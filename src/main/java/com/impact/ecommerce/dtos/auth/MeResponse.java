package com.impact.ecommerce.dtos.auth;

// Lesson 4 (slides 16-17): a typed response exposes only the current user's public details.
public record MeResponse(String email, String role) { }
