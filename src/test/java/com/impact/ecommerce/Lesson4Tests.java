package com.impact.ecommerce;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.impact.ecommerce.entities.Product;
import com.impact.ecommerce.repositories.UserRepository;
import com.impact.ecommerce.services.ProductMapper;
import java.math.BigDecimal;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cache.CacheManager;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.web.servlet.MockMvc;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

// Lesson 4: exercise real default startup, H2 seed SQL and JWTs, without a test profile.
@SpringBootTest
@AutoConfigureMockMvc
class Lesson4Tests {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired DataSource dataSource;
    @Autowired CacheManager cacheManager;
    @Autowired ProductMapper mapper;
    @Autowired UserRepository users;

    @Test
    void defaultStartupUsesH2AndLocalCacheAndRepeatableSeeds() throws Exception {
        try (var connection = dataSource.getConnection()) {
            assertEquals("H2", connection.getMetaData().getDatabaseProductName());
        }
        assertInstanceOf(ConcurrentMapCacheManager.class, cacheManager);
        new ResourceDatabasePopulator(new ClassPathResource("database/insert_data.sql")).execute(dataSource);
        mvc.perform(get("/api/products")).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(6));
        mvc.perform(get("/api/categories")).andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3));
    }

    @Test
    void meReturnsOnlyEmailAndRoleForBothDemoAccounts() throws Exception {
        for (String role : new String[]{"user", "admin"}) {
            String token = login(role + "@impact.md", role + "123");
            var result = mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.email").value(role + "@impact.md"))
                    .andExpect(jsonPath("$.role").value(role.toUpperCase(java.util.Locale.ROOT)))
                    .andReturn();
            assertEquals(2, json.readTree(result.getResponse().getContentAsString()).size());
        }
    }

    @Test
    void meRejectsMissingInvalidAndDeletedIdentities() throws Exception {
        mvc.perform(get("/api/auth/me")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer broken"))
                .andExpect(status().isUnauthorized());
        var registration = mvc.perform(post("/api/auth/register").contentType("application/json")
                .content("{\"email\":\"deleted@example.com\",\"password\":\"password123\"}"))
                .andExpect(status().isCreated()).andReturn();
        String token = json.readTree(registration.getResponse().getContentAsString()).path("token").asText();
        users.delete(users.findByEmail("deleted@example.com").orElseThrow());
        mvc.perform(get("/api/auth/me").header("Authorization", "Bearer " + token))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void homeworkKeepsUncategorizedProductsAndLegacyCategoryAlias() throws Exception {
        Product product = new Product();
        product.setName("No category");
        product.setDescription("Notes");
        product.setPrice(new BigDecimal("9.99"));
        product.setStock(4);
        var response = mapper.toResponse(product);
        assertEquals("No category", response.name());
        assertEquals(new BigDecimal("9.99"), response.price());
        assertEquals(4, response.stock());
        assertNull(response.categoryId());
        assertNull(response.categoryName());
        var body = json.valueToTree(response);
        assertTrue(body.has("category"));
        assertTrue(body.get("category").isNull());
        assertTrue(body.get("categoryName").isNull());
    }

    @Test
    void swaggerDocumentsAuthenticatedMeResponse() throws Exception {
        mvc.perform(get("/v3/api-docs")).andExpect(status().isOk())
                .andExpect(jsonPath("$.paths['/api/auth/me'].get.security[0].bearerAuth").isArray())
                .andExpect(jsonPath("$.components.schemas.MeResponse.properties.email").exists())
                .andExpect(jsonPath("$.components.schemas.MeResponse.properties.role").exists());
    }

    private String login(String email, String password) throws Exception {
        var response = mvc.perform(post("/api/auth/login").contentType("application/json")
                .content(json.writeValueAsString(java.util.Map.of("email", email, "password", password))))
                .andExpect(status().isOk()).andReturn();
        return json.readTree(response.getResponse().getContentAsString()).path("token").asText();
    }
}
