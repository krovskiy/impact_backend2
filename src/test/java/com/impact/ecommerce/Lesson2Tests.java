package com.impact.ecommerce;

import com.impact.ecommerce.entities.*;
import com.impact.ecommerce.repositories.*;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import com.fasterxml.jackson.databind.ObjectMapper;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class Lesson2Tests {
    @Autowired MockMvc mvc;
    @Autowired UserRepository users;
    @Autowired ProductRepository products;
    @Autowired CategoryRepository categories;
    @Autowired PasswordEncoder encoder;
    @Autowired ObjectMapper json;
    private Long categoryId;

    @BeforeEach
    void seedIsolatedTestDatabase() {
        products.deleteAll();
        categories.deleteAll();
        users.deleteAll();
        Category books = new Category();
        books.setName("Books");
        categories.saveAndFlush(books);
        categoryId = books.getId();
        Product book = new Product();
        book.setName("Java Basics");
        book.setDescription("Classroom book");
        book.setPrice(new BigDecimal("19.50"));
        book.setStock(30);
        book.setCategory(books);
        products.saveAndFlush(book);
        seedUser("user@impact.md", "user123", Role.USER);
        seedUser("admin@impact.md", "admin123", Role.ADMIN);
    }

    private void seedUser(String email, String password, Role role) {
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(encoder.encode(password));
        user.setRole(role);
        users.saveAndFlush(user);
    }

    @Test
    void catalogReadsFromRepositoriesWithoutExposingEntities() throws Exception {
        mvc.perform(get("/api/products")).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("Java Basics"))
                .andExpect(jsonPath("$[0].price").value(19.50))
                .andExpect(jsonPath("$[0].categoryId").value(categoryId))
                .andExpect(jsonPath("$[0].createdAt").doesNotExist());
        mvc.perform(get("/api/categories")).andExpect(status().isOk())
                .andExpect(jsonPath("$[0].name").value("Books"));
    }

    @Test
    void unauthenticatedRequestsAndInvalidTokensAreRejected() throws Exception {
        mvc.perform(get("/api/test/protected")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/test")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/test/protected").header("Authorization", "Bearer not-a-jwt"))
                .andExpect(status().isUnauthorized());
        String expired = Jwts.builder().subject("user@impact.md")
                .expiration(new Date(System.currentTimeMillis() - 60000))
                .signWith(Keys.hmacShaKeyFor("classroom-test-key-only-at-least-32-bytes".getBytes(StandardCharsets.UTF_8)))
                .compact();
        mvc.perform(get("/api/test/protected").header("Authorization", "Bearer " + expired))
                .andExpect(status().isUnauthorized());
        String forged = Jwts.builder().subject("user@impact.md").claim("role", "ADMIN")
                .expiration(new Date(System.currentTimeMillis() + 60000))
                .signWith(Jwts.SIG.HS256.key().build()).compact();
        mvc.perform(get("/api/admin/test").header("Authorization", "Bearer " + forged))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "USER")
    void userCannotUseAdminOrProductWrites() throws Exception {
        mvc.perform(get("/api/admin/test")).andExpect(status().isForbidden());
        mvc.perform(delete("/api/products/1")).andExpect(status().isForbidden());
        mvc.perform(get("/api/test/protected")).andExpect(status().isOk());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminAuthorizationAndProductValidationArePrepared() throws Exception {
        mvc.perform(get("/api/admin/test")).andExpect(status().isOk())
                .andExpect(content().string("You are an admin"));
        mvc.perform(post("/api/products").contentType("application/json")
                .content("{\"name\":\"\",\"price\":-2,\"stock\":-1}")).andExpect(status().isBadRequest());
    }

    @Test
    void registrationValidationAndDuplicateChecksArePrepared() throws Exception {
        mvc.perform(post("/api/auth/register").contentType("application/json")
                .content("{\"email\":\"not-an-email\",\"password\":\"a\"}")).andExpect(status().isBadRequest());
        mvc.perform(post("/api/auth/register").contentType("application/json")
                .content("{\"email\":\"USER@impact.md\",\"password\":\"password123\"}"))
                .andExpect(status().isConflict());
        mvc.perform(post("/api/auth/login").contentType("application/json")
                .content("{\"email\":\"user@impact.md\",\"password\":\"wrong\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void suppliedSeedHashesMatchTheDocumentedAccounts() throws Exception {
        String sql = java.nio.file.Files.readString(java.nio.file.Path.of("database/insert_data.sql"));
        var hashes = java.util.regex.Pattern.compile("\\$2a\\$10\\$[./A-Za-z0-9]{53}").matcher(sql);
        assertTrue(hashes.find());
        assertTrue(encoder.matches("admin123", hashes.group()));
        assertTrue(hashes.find());
        assertTrue(encoder.matches("user123", hashes.group()));
    }

    // Opt-in completion checks. These are supposed to fail until students finish all six TODOs.
    @Test
    @Tag("lesson2-complete")
    void checkpointFilteringAndDtoMapping() throws Exception {
        mvc.perform(get("/api/products").param("category", categoryId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].categoryName").value("Books"))
                .andExpect(jsonPath("$[0].category").value("Books"));
        mvc.perform(get("/api/products").param("category", "999999"))
                .andExpect(status().isOk()).andExpect(content().json("[]"));
    }

    @Test
    @Tag("lesson2-complete")
    void checkpointRegistrationHashesPasswordsAndCannotGrantAdmin() throws Exception {
        mvc.perform(post("/api/auth/register").contentType("application/json")
                .content("{\"email\":\"Student@example.com\",\"password\":\"password123\",\"role\":\"ADMIN\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.role").value("USER"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
        User saved = users.findByEmail("student@example.com").orElseThrow();
        assertNotEquals("password123", saved.getPasswordHash());
        assertTrue(encoder.matches("password123", saved.getPasswordHash()));
        assertEquals(Role.USER, saved.getRole());
    }

    @Test
    @Tag("lesson2-complete")
    void checkpointJwtLoginAndRoleBoundaries() throws Exception {
        String token = login("user@impact.md", "user123");
        mvc.perform(get("/api/test/protected").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andExpect(content().string("You are authenticated"));
        mvc.perform(get("/api/admin/test").header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
        String adminToken = login("admin@impact.md", "admin123");
        mvc.perform(get("/api/admin/test").header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk()).andExpect(content().string("You are an admin"));
        var claims = Jwts.parser()
                .verifyWith(Keys.hmacShaKeyFor("classroom-test-key-only-at-least-32-bytes".getBytes(StandardCharsets.UTF_8)))
                .build().parseSignedClaims(token).getPayload();
        assertEquals("user@impact.md", claims.getSubject());
        assertEquals("USER", claims.get("role"));
        assertNotNull(claims.get("id"));
        assertNotNull(claims.getIssuedAt());
        assertNotNull(claims.getExpiration());
        assertFalse(claims.containsKey("password"));
        assertFalse(claims.containsKey("passwordHash"));
    }

    private String login(String email, String password) throws Exception {
        var response = mvc.perform(post("/api/auth/login").contentType("application/json")
                .content(json.writeValueAsString(java.util.Map.of("email", email, "password", password))))
                .andExpect(status().isOk()).andReturn();
        return json.readTree(response.getResponse().getContentAsString()).get("token").asText();
    }
}
