package com.impact.ecommerce.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI api() {
        Components components = new Components();
        // TODO Lesson 3 L3-5: add the HTTP bearer scheme named "bearerAuth" to components.
        // Use SecurityScheme.Type.HTTP, scheme("bearer"), bearerFormat("JWT").
        return new OpenAPI().info(new Info().title("Impact Backend Year 2").version("1"))
                .components(components);
    }
}
