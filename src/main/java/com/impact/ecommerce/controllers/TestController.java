package com.impact.ecommerce.controllers;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
public class TestController {
    @GetMapping("/test/protected")
    public String protectedEndpoint() { return "You are authenticated"; }

    @GetMapping("/admin/test")
    public String adminOnlyEndpoint() { return "You are an admin"; }
}
