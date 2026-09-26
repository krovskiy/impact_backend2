-- Lesson 2: demo data, compatible with embedded H2. Safe to run again.
-- Classroom accounts only. BCrypt hashes: admin123 / user123.
INSERT INTO categories(name) SELECT 'Electronics' WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='Electronics');
INSERT INTO categories(name) SELECT 'Books' WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='Books');
INSERT INTO categories(name) SELECT 'Clothing' WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name='Clothing');
INSERT INTO users(email, password_hash, role)
SELECT 'admin@impact.md', '$2a$10$U2rlHqSx/Wzir50GGUa.z.lxjRrUM3Zr9N4jbPC4zA8L53SgF/E4O', 'ADMIN'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email='admin@impact.md');
INSERT INTO users(email, password_hash, role)
SELECT 'user@impact.md', '$2a$10$NkM5BIa5cK9RDUaJo.e8oOp3CfMNDze8HsLbkhMzC3AcM18h8SoYO', 'USER'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email='user@impact.md');
INSERT INTO products(name, description, price, stock, category_id)
SELECT seed.name, seed.description, seed.price, seed.stock, c.id
FROM (VALUES
    ('Headphones', 'Wired headphones', 49.90, 12, 'Electronics'),
    ('Keyboard', 'USB keyboard', 29.90, 25, 'Electronics'),
    ('Java Basics', 'Your first Java book', 19.50, 30, 'Books'),
    ('Notebook', 'Class notes', 4.50, 50, 'Books'),
    ('T-shirt', 'Cotton shirt', 14.90, 20, 'Clothing'),
    ('Hoodie', 'Warm hoodie', 34.90, 10, 'Clothing')
) AS seed(name, description, price, stock, category)
JOIN categories c ON c.name = seed.category
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.name = seed.name AND p.category_id = c.id);
