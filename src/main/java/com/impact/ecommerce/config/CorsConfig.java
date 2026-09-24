package com.impact.ecommerce.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Lesson 1 solution.
 *
 * Completed CORS rules for the lesson frontend.
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                // Answer Lesson 1: allow browser origins, including a locally opened index.html.
                // Hint from the lesson: allowedOriginPatterns("*")
                .allowedOriginPatterns("*")
                // Answer Lesson 1: verify that ALL required HTTP verbs are allowed.
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}
