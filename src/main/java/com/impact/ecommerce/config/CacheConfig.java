package com.impact.ecommerce.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.impact.ecommerce.dtos.product.CategoryResponse;
import com.impact.ecommerce.dtos.product.ProductResponse;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import java.time.Duration;
import java.util.List;
import java.util.Map;

@Configuration
@EnableCaching
public class CacheConfig {
    // Typed JSON keeps cache payloads limited to public DTOs, not JPA entities or arbitrary classes.
    public static RedisCacheConfiguration configuration(ObjectMapper mapper, Class<?> dto) {
        var type = mapper.getTypeFactory().constructCollectionType(List.class, dto);
        var serializer = new Jackson2JsonRedisSerializer<List<?>>(mapper.copy()
                .disable(com.fasterxml.jackson.databind.DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES), type);
        return RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(Duration.ofSeconds(60))
                .disableCachingNullValues()
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(serializer));
    }

    @Bean
    @ConditionalOnProperty(name = "spring.cache.type", havingValue = "redis")
    public RedisCacheManager redisCacheManager(RedisConnectionFactory connection, ObjectMapper mapper) {
        return RedisCacheManager.builder(connection)
                .withInitialCacheConfigurations(Map.of(
                        "products", configuration(mapper, ProductResponse.class),
                        "categories", configuration(mapper, CategoryResponse.class)))
                .disableCreateOnMissingCache()
                .transactionAware() // Evict only after successful database commits.
                .build();
    }
}
