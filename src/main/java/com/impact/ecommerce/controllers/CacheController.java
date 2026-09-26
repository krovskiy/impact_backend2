package com.impact.ecommerce.controllers;

import com.impact.ecommerce.services.CatalogCacheService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/cache")
@Tag(name = "Cache", description = "Local classroom catalog cache")
public class CacheController {
    private final CatalogCacheService cache;
    public CacheController(CatalogCacheService cache) { this.cache = cache; }

    @Operation(summary = "Clear product and category caches",
            description = "Public local classroom action used by the supplied frontend. Does not modify the H2 database.")
    @ApiResponse(responseCode = "200", description = "Catalog cache clear requested (no-op when caching is disabled)")
    @ApiResponse(responseCode = "401", description = "An invalid or expired bearer token was supplied")
    @ApiResponse(responseCode = "503", description = "Redis is unavailable")
    @PostMapping("/clear")
    public Map<String, String> clear() {
        cache.clear();
        return Map.of("message", "Catalog cache cleared");
    }
}
