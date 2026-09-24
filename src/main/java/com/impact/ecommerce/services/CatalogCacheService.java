package com.impact.ecommerce.services;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;

@Service
public class CatalogCacheService {
    // Answer Lesson 3 L3-4: clear both catalog caches.
    // Clear only these application caches; never use Redis FLUSHALL.
    @CacheEvict(cacheNames = {"products", "categories"}, allEntries = true)
    public void clear() {
    }
}
