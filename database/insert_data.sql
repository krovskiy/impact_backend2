-- Classroom accounts only. BCrypt hashes: admin123 / user123.
-- Rerunning does not reset existing users' passwords, roles, or edited products.
INSERT INTO categories(name) VALUES ('Electronics'), ('Books'), ('Clothing')
ON CONFLICT (name) DO NOTHING;
INSERT INTO users(email, password_hash, role) VALUES
('admin@impact.md', '$2a$10$U2rlHqSx/Wzir50GGUa.z.lxjRrUM3Zr9N4jbPC4zA8L53SgF/E4O', 'ADMIN'),
('user@impact.md', '$2a$10$NkM5BIa5cK9RDUaJo.e8oOp3CfMNDze8HsLbkhMzC3AcM18h8SoYO', 'USER')
ON CONFLICT (email) DO NOTHING;
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
