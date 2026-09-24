package com.impact.ecommerce.controllers;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

import com.impact.ecommerce.dtos.product.*;
import com.impact.ecommerce.services.ProductService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.*;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Tag(name = "Catalog")
@RestController
@RequestMapping("/api")
@Validated
public class CatalogController {
    private final ProductService products;
    public CatalogController(ProductService products) { this.products = products; }

    @Operation(summary = "List categories")
    @ApiResponse(responseCode = "200", description = "Category DTOs")
    @ApiResponse(responseCode = "503", description = "Redis unavailable")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @GetMapping("/categories")
    public List<CategoryResponse> categories() { return products.categories(); }

    // TODO Lesson 3 L3-6: replace the summary with "List products, optionally filtered by category".
    @Operation(summary = "TODO: describe the product list")
    @ApiResponse(responseCode = "200", description = "Product DTOs (empty list when no matches)")
    @ApiResponse(responseCode = "400", description = "Invalid category ID")
    @ApiResponse(responseCode = "501", description = "Category filter exercise unfinished")
    @ApiResponse(responseCode = "503", description = "Redis unavailable")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @ApiResponse(responseCode = "401", description = "Missing/invalid bearer token, or invalid token supplied to a public route")
    @GetMapping("/products")
    public List<ProductResponse> products(@RequestParam(required = false) @Positive Long category) {
        return products.list(category);
    }

    @Operation(summary = "Create a product")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponse(responseCode = "201", description = "Product created")
    @ApiResponse(responseCode = "400", description = "Invalid product")
    @ApiResponse(responseCode = "401", description = "Authentication required")
    @ApiResponse(responseCode = "403", description = "ADMIN required")
    @ApiResponse(responseCode = "404", description = "Category not found")
    @ApiResponse(responseCode = "409", description = "Database constraint violation")
    @ApiResponse(responseCode = "503", description = "Redis unavailable")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @PostMapping("/products")
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody CreateProductRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(products.create(request));
    }

    @Operation(summary = "Update a product")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponse(responseCode = "200", description = "Product updated")
    @ApiResponse(responseCode = "400", description = "Invalid ID or product")
    @ApiResponse(responseCode = "401", description = "Authentication required")
    @ApiResponse(responseCode = "403", description = "ADMIN required")
    @ApiResponse(responseCode = "404", description = "Product or category not found")
    @ApiResponse(responseCode = "409", description = "Database constraint violation")
    @ApiResponse(responseCode = "503", description = "Redis unavailable")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @PutMapping("/products/{id}")
    public ProductResponse update(@PathVariable @Positive Long id, @Valid @RequestBody CreateProductRequest request) {
        return products.update(id, request);
    }

    @Operation(summary = "Delete a product")
    @SecurityRequirement(name = "bearerAuth")
    @ApiResponse(responseCode = "204", description = "Product deleted")
    @ApiResponse(responseCode = "400", description = "Invalid ID")
    @ApiResponse(responseCode = "401", description = "Authentication required")
    @ApiResponse(responseCode = "403", description = "ADMIN required")
    @ApiResponse(responseCode = "404", description = "Product not found")
    @ApiResponse(responseCode = "409", description = "Database constraint violation")
    @ApiResponse(responseCode = "503", description = "Redis unavailable")
    @ApiResponse(responseCode = "500", description = "Unexpected server error")
    @DeleteMapping("/products/{id}")
    public ResponseEntity<Void> delete(@PathVariable @Positive Long id) {
        products.delete(id);
        return ResponseEntity.noContent().build();
    }
}
