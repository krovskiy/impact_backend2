package com.impact.ecommerce;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.impact.ecommerce.config.CacheConfig;
import com.impact.ecommerce.dtos.product.*;
import com.impact.ecommerce.entities.*;
import com.impact.ecommerce.repositories.*;
import com.impact.ecommerce.services.ProductService;
import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.cache.CacheManager;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "spring.cache.type=simple")
@ActiveProfiles("test")
@AutoConfigureMockMvc
class Lesson3Tests {
    @Autowired MockMvc mvc;
    @Autowired ProductService service;
    @Autowired CacheManager caches;
    @Autowired ObjectMapper mapper;
    @SpyBean ProductRepository products;
    @SpyBean CategoryRepository categories;
    private Long categoryId;
    private Long productId;

    @BeforeEach
    void prepare() {
        for (String name : caches.getCacheNames()) caches.getCache(name).clear();
        products.deleteAll();
        categories.deleteAll();
        Category category = new Category();
        category.setName("Lesson 3");
        categoryId = categories.saveAndFlush(category).getId();
        Product product = new Product();
        product.setName("Book");
        product.setPrice(new BigDecimal("10.00"));
        product.setStock(3);
        product.setCategory(category);
        productId = products.saveAndFlush(product).getId();
        clearInvocations(products, categories);
    }

    @Test
    void publicSwaggerAndEveryExistingRouteAreDocumented() throws Exception {
        mvc.perform(get("/swagger-ui/index.html")).andExpect(status().isOk());
        var result = mvc.perform(get("/v3/api-docs")).andExpect(status().isOk()).andReturn();
        var paths = mapper.readTree(result.getResponse().getContentAsString()).path("paths");
        for (String route : List.of("/api/products", "/api/categories", "/api/products/{id}",
                "/api/auth/login", "/api/auth/register", "/api/practice", "/api/test/protected",
                "/api/admin/test", "/api/cache/clear")) {
            assertTrue(paths.has(route), route);
            for (var operation : paths.path(route)) {
                assertTrue(operation.hasNonNull("summary"), route);
                assertFalse(operation.path("responses").isEmpty(), route);
            }
        }
        assertEquals("bearerAuth", paths.path("/api/admin/test").path("get")
                .path("security").get(0).fieldNames().next());
    }

    @Test
    void redisConfigurationHasSixtySecondTtlAndRoundTripsDtos() {
        var config = CacheConfig.configuration(mapper, ProductResponse.class);
        assertEquals(Duration.ofSeconds(60), config.getTtl());
        var original = List.of(new ProductResponse(1L, "Book", "Notes",
                new BigDecimal("10.00"), 3, 2L, "Books"));
        var pair = config.getValueSerializationPair();
        assertEquals(original, pair.read(pair.write(original)));
        var categoryConfig = CacheConfig.configuration(mapper, CategoryResponse.class);
        var categoryList = List.of(new CategoryResponse(2L, "Books"));
        var categoryPair = categoryConfig.getValueSerializationPair();
        assertEquals(categoryList, categoryPair.read(categoryPair.write(categoryList)));
    }

    @Test
    @Tag("lesson-complete")
    void productCacheHitsDoNotQueryDatabaseAndKeysAreSeparate() {
        assertEquals(service.list(null), service.list(null));
        assertEquals(service.list(categoryId), service.list(categoryId));
        assertTrue(service.list(999999L).isEmpty());
        verify(products, times(1)).findAll();
        verify(products, times(1)).findByCategoryId(categoryId);
        verify(products, times(1)).findByCategoryId(999999L);
    }

    @Test
    @Tag("lesson-complete")
    void categoryCacheHitsDoNotQueryDatabase() {
        assertEquals(service.categories(), service.categories());
        verify(categories, times(1)).findAll();
    }

    private CreateProductRequest request(String name) {
        return new CreateProductRequest(name, "Notes", new BigDecimal("12.00"), 4, categoryId);
    }

    private void assertCachesFilled() {
        service.list(null);
        service.list(categoryId);
        assertNotNull(caches.getCache("products").get("all"));
        assertNotNull(caches.getCache("products").get(categoryId));
    }

    private void assertProductsEvicted() {
        assertNull(caches.getCache("products").get("all"));
        assertNull(caches.getCache("products").get(categoryId));
    }

    @Test
    @Tag("lesson-complete")
    void everyProductWriteEvictsAllProductLists() {
        assertCachesFilled();
        var created = service.create(request("New book"));
        assertProductsEvicted();
        assertEquals(2, service.list(null).size());
        assertCachesFilled();
        service.update(productId, request("Updated book"));
        assertProductsEvicted();
        assertTrue(service.list(null).stream().anyMatch(p -> p.name().equals("Updated book")));
        assertCachesFilled();
        service.delete(created.id());
        assertProductsEvicted();
        assertEquals(1, service.list(null).size());
    }

    @Test
    @Tag("lesson-complete")
    void manualClearClearsBothCachesWithoutDeletingProducts() throws Exception {
        assertCachesFilled();
        service.categories();
        assertNotNull(caches.getCache("categories").get("all"));
        mvc.perform(post("/api/cache/clear")).andExpect(status().isOk());
        assertProductsEvicted();
        assertNull(caches.getCache("categories").get("all"));
        assertEquals(1, products.count());
    }

    @Test
    @Tag("lesson-complete")
    void swaggerHasBearerSchemeAndCompletedProductSummary() throws Exception {
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.type").value("http"))
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.scheme").value("bearer"))
                .andExpect(jsonPath("$.components.securitySchemes.bearerAuth.bearerFormat").value("JWT"))
                .andExpect(jsonPath("$.paths['/api/products'].get.summary")
                        .value("List products, optionally filtered by category"));
    }
}
