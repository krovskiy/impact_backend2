package com.impact.ecommerce.dtos.product;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.math.BigDecimal;

public record ProductResponse(Long id, String name, String description, BigDecimal price,
                              Integer stock, Long categoryId, String categoryName) {
    // The existing frontend calls this field "category"; keep both names for the lesson DTO.
    @JsonProperty("category")
    public String category() { return categoryName; }
}
