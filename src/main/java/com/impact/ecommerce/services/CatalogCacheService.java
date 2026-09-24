package com.impact.ecommerce.services;

import com.impact.ecommerce.exceptions.LessonTodo;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.stereotype.Service;

@Service
public class CatalogCacheService {
    // TODO Lesson 3 L3-4: uncomment the annotation and remove the throw.
    // Clear only these application caches; never use Redis FLUSHALL.
    // @CacheEvict(cacheNames = {"products", "categories"}, allEntries = true)
    public void clear() {
        throw LessonTodo.required("L3-4");
    }
}
