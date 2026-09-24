package com.impact.ecommerce.services;

import com.impact.ecommerce.dtos.product.*;
import com.impact.ecommerce.entities.*;
import com.impact.ecommerce.exceptions.LessonTodo;
import com.impact.ecommerce.repositories.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class ProductService {
    private final ProductRepository products;
    private final CategoryRepository categories;

    public ProductService(ProductRepository products, CategoryRepository categories) {
        this.products = products;
        this.categories = categories;
    }

    public List<ProductResponse> list(Long categoryId) {
        return selectProducts(categoryId).stream().map(this::toResponse).toList();
    }

    private List<Product> selectProducts(Long categoryId) {
        if (categoryId == null) return products.findAll(); // Working example.
        // TODO Lesson 2 L2-1: return products filtered by categoryId.
        // Hint: ProductRepository already has the required derived query.
        throw LessonTodo.required("L2-1");
    }

    public ProductResponse toResponse(Product product) {
        Category category = product.getCategory();
        // TODO Lesson 2 L2-2: return the category name, or null if there is no category.
        String categoryName = null;
        return new ProductResponse(product.getId(), product.getName(), product.getDescription(),
                product.getPrice(), product.getStock(), category == null ? null : category.getId(), categoryName);
    }

    public List<CategoryResponse> categories() {
        return categories.findAll().stream().map(c -> new CategoryResponse(c.getId(), c.getName())).toList();
    }

    @Transactional
    public ProductResponse create(CreateProductRequest request) {
        return toResponse(products.save(apply(new Product(), request)));
    }

    @Transactional
    public ProductResponse update(Long id, CreateProductRequest request) {
        return toResponse(products.save(apply(find(id), request)));
    }

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
