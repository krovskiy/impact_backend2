package com.impact.ecommerce.controllers;

import com.impact.ecommerce.dtos.product.*;
import com.impact.ecommerce.services.ProductService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import org.springframework.http.*;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api")
@Validated
public class CatalogController {
    private final ProductService products;
    public CatalogController(ProductService products) { this.products = products; }

    @GetMapping("/categories")
    public List<CategoryResponse> categories() { return products.categories(); }

    @GetMapping("/products")
    public List<ProductResponse> products(@RequestParam(required = false) @Positive Long category) {
        return products.list(category);
    }

    @PostMapping("/products")
    public ResponseEntity<ProductResponse> create(@Valid @RequestBody CreateProductRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(products.create(request));
    }

    @PutMapping("/products/{id}")
    public ProductResponse update(@PathVariable @Positive Long id, @Valid @RequestBody CreateProductRequest request) {
        return products.update(id, request);
    }

    @DeleteMapping("/products/{id}")
    public ResponseEntity<Void> delete(@PathVariable @Positive Long id) {
        products.delete(id);
        return ResponseEntity.noContent().build();
    }
}
