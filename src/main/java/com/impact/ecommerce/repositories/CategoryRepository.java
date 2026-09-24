package com.impact.ecommerce.repositories;

import com.impact.ecommerce.entities.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {
}
