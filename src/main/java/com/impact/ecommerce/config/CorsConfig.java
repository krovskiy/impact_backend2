package com.impact.ecommerce.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Lesson 1 catch-up scaffold.
 *
 * The class already compiles and the application starts.
 * Students should finish the CORS rule below so the local frontend can call the backend.
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                // TODO Lesson 1: allow browser origins, including a locally opened index.html.
                // Hint from the lesson: allowedOriginPatterns("*")
                .allowedOriginPatterns("null", "*")
                // TODO Lesson 1: verify that ALL required HTTP verbs are allowed.
                .allowedMethods("GET", "POST")
                .allowedHeaders("*");
    }
}
