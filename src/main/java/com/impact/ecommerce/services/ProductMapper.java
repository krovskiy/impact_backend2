package com.impact.ecommerce.services;

import com.impact.ecommerce.dtos.product.ProductResponse;
import com.impact.ecommerce.entities.Category;
import com.impact.ecommerce.entities.Product;
import org.springframework.stereotype.Component;

// Lesson 4 homework: Extract Class / SRP. This class only maps an entity to a public DTO.
@Component
public class ProductMapper {
    public ProductResponse toResponse(Product product) {
        Category category = product.getCategory();
        // Lesson 2 L2-2 solution: keep nullable categories and every original response field.
        return new ProductResponse(product.getId(), product.getName(), product.getDescription(),
                product.getPrice(), product.getStock(), category == null ? null : category.getId(),
                category == null ? null : category.getName());
    }
}
