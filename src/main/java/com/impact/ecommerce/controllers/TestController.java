package com.impact.ecommerce.controllers;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

import org.springframework.web.bind.annotation.*;

@Tag(name = "Authorization")
@RestController
@RequestMapping("/api")
public class TestController {
    @Operation(summary = "Test JWT authentication")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponse(responseCode = "200", description = "Authenticated")
    @ApiResponse(responseCode = "401", description = "Missing or invalid token")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @GetMapping("/test/protected")
    public String protectedEndpoint() { return "You are authenticated"; }

    @Operation(summary = "Test ADMIN authorization")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponse(responseCode = "200", description = "Authorized as ADMIN")
    @ApiResponse(responseCode = "401", description = "Missing or invalid token")
    @ApiResponse(responseCode = "403", description = "ADMIN required")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @GetMapping("/admin/test")
    public String adminOnlyEndpoint() { return "You are an admin"; }
}
