package com.impact.ecommerce.dtos.auth;

import jakarta.validation.constraints.*;

public record RegisterRequest(@NotBlank @Email @Size(max = 255) String email,
                              @NotBlank @Size(min = 6, max = 72) String password) { }
