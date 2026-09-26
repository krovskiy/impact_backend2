package com.impact.ecommerce.services;

import com.impact.ecommerce.dtos.product.*;
import com.impact.ecommerce.entities.*;
import com.impact.ecommerce.repositories.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;

@Service
@Transactional(readOnly = true)
public class ProductService {
    private final ProductRepository products;
    private final CategoryRepository categories;

    private final ProductMapper mapper;

    public ProductService(ProductRepository products, CategoryRepository categories, ProductMapper mapper) {
        this.products = products;
        this.categories = categories;
        this.mapper = mapper;
    }

    // Answer Lesson 3 L3-1: cache with a separate key for each category.
    @Cacheable(cacheNames = "products", key = "#categoryId != null ? #categoryId : 'all'")
    public List<ProductResponse> list(Long categoryId) {
        return selectProducts(categoryId).stream().map(this::toResponse).toList();
    }

    private List<Product> selectProducts(Long categoryId) {
        if (categoryId == null) return products.findAll(); // Working example.
        // Answer Lesson 2 L2-1: return products filtered by categoryId.
        // Hint: ProductRepository already has the required derived query.
        return products.findByCategoryId(categoryId);
    }

    // Lesson 4 homework: mapping has its own class; keep this method for existing callers.
    public ProductResponse toResponse(Product product) {
        return mapper.toResponse(product);
    }

    // Answer Lesson 3 L3-2: cache the category DTO list.
    @Cacheable(cacheNames = "categories", key = "'all'")
    public List<CategoryResponse> categories() {
        return categories.findAll().stream().map(c -> new CategoryResponse(c.getId(), c.getName())).toList();
    }

    // Answer Lesson 3 L3-3: all three writes invalidate every filtered list.
    @CacheEvict(cacheNames = "products", allEntries = true)
    @Transactional
    public ProductResponse create(CreateProductRequest request) {
        return toResponse(products.save(apply(new Product(), request)));
    }

    // Answer Lesson 3 L3-3: all three writes invalidate every filtered list.
    @CacheEvict(cacheNames = "products", allEntries = true)
    @Transactional
    public ProductResponse update(Long id, CreateProductRequest request) {
        return toResponse(products.save(apply(find(id), request)));
    }

    // Answer Lesson 3 L3-3: all three writes invalidate every filtered list.
    @CacheEvict(cacheNames = "products", allEntries = true)
    @Transactional
    public void delete(Long id) { products.delete(find(id)); }

    private Product find(Long id) {
        return products.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));
    }

    private Product apply(Product product, CreateProductRequest request) {
        product.setName(request.name().trim());
        product.setDescription(request.description());
        product.setPrice(request.price());
        product.setStock(request.stock());
        product.setCategory(request.categoryId() == null ? null : categories.findById(request.categoryId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found")));
        return product;
    }
}
