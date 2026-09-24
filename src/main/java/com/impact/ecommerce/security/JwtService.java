package com.impact.ecommerce.security;

import com.impact.ecommerce.entities.User;
import com.impact.ecommerce.exceptions.LessonTodo;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {
    private final SecretKey signingKey;
    private final long expirationMs;

    public JwtService(@Value("${jwt.secret:}") String secret,
                      @Value("${jwt.expiration-ms:3600000}") long expirationMs) {
        // No committed signing secret: a fresh classroom key is generated on each restart.
        signingKey = secret.isBlank() ? Jwts.SIG.HS256.key().build()
                : Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        if (expirationMs <= 0) throw new IllegalArgumentException("JWT expiration must be positive");
        this.expirationMs = expirationMs;
    }

    public String generateToken(User user) {
        Date now = new Date();
        Date expiration = new Date(now.getTime() + expirationMs);
        // TODO Lesson 2 L2-5: build and sign a JWT with email as subject,
        // id + role claims, issuedAt(now), expiration(expiration), and signingKey.
        // Use Jwts.builder() ... signWith(signingKey, Jwts.SIG.HS256).compact().
        // Never include passwordHash.
        throw LessonTodo.required("L2-5");
    }

    public Claims readClaims(String token) {
        // Verification (including expiration) is already implemented; do not replace it with decoding.
        return Jwts.parser().verifyWith(signingKey).build().parseSignedClaims(token).getPayload();
    }
}
