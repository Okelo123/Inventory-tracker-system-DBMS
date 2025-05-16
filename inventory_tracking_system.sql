
-- Inventory Tracking System SQL Schema with Sample Data

-- Drop tables if they exist (for repeatability)
DROP TABLE IF EXISTS inventory_transactions;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS users;

-- 1. Categories
CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

-- 2. Suppliers
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100),
    phone VARCHAR(20)
);

-- 3. Products
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    supplier_id INT,
    quantity_in_stock INT DEFAULT 0,
    price DECIMAL(10, 2) NOT NULL,
    UNIQUE (product_name),
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

-- 4. Users
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'staff') NOT NULL DEFAULT 'staff'
);

-- 5. Inventory Transactions
CREATE TABLE inventory_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    transaction_type ENUM('purchase', 'sale') NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_id INT,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Sample Data Insertion

-- Categories
INSERT INTO categories (category_name) VALUES ('Electronics'), ('Furniture'), ('Stationery');

-- Suppliers
INSERT INTO suppliers (supplier_name, contact_email, phone) VALUES 
('Tech Supplies Co.', 'contact@techsupplies.com', '123-456-7890'),
('Office World', 'sales@officeworld.com', '234-567-8901');

-- Users
INSERT INTO users (username, password_hash, role) VALUES 
('admin_user', 'hashed_password_123', 'admin'),
('staff_user', 'hashed_password_456', 'staff');

-- Products
INSERT INTO products (product_name, category_id, supplier_id, quantity_in_stock, price) VALUES
('Laptop', 1, 1, 10, 1200.00),
('Desk', 2, 2, 5, 300.00),
('Notebook', 3, 2, 100, 2.50);

-- Inventory Transactions
INSERT INTO inventory_transactions (product_id, transaction_type, quantity, user_id) VALUES
(1, 'purchase', 10, 1),
(2, 'purchase', 5, 2),
(3, 'purchase', 100, 2),
(3, 'sale', 20, 2),
(1, 'sale', 2, 1);

-- Test Queries

-- 1. Transaction Summary
-- Total quantity of products purchased and sold
-- Grouped by product and transaction type
-- Shows net stock movement per product
-- Note: Use this to verify logic and summarize movement
SELECT 
    p.product_name,
    it.transaction_type,
    SUM(it.quantity) AS total_quantity
FROM inventory_transactions it
JOIN products p ON it.product_id = p.product_id
GROUP BY p.product_name, it.transaction_type;

-- 2. Stock Summary
-- Current quantity in stock from product table
SELECT 
    product_name,
    quantity_in_stock,
    price,
    (quantity_in_stock * price) AS total_value
FROM products;



-- VIEW: Product Stock Summary
CREATE OR REPLACE VIEW product_stock_summary AS
SELECT 
    p.product_id,
    p.product_name,
    p.price,
    COALESCE(SUM(CASE WHEN it.transaction_type = 'purchase' THEN it.quantity ELSE 0 END), 0) -
    COALESCE(SUM(CASE WHEN it.transaction_type = 'sale' THEN it.quantity ELSE 0 END), 0) AS current_stock,
    (COALESCE(SUM(CASE WHEN it.transaction_type = 'purchase' THEN it.quantity ELSE 0 END), 0) -
     COALESCE(SUM(CASE WHEN it.transaction_type = 'sale' THEN it.quantity ELSE 0 END), 0)) * p.price AS total_value
FROM products p
LEFT JOIN inventory_transactions it ON p.product_id = it.product_id
GROUP BY p.product_id;

-- TRIGGER: Auto-update product price after a new purchase
DELIMITER //
CREATE TRIGGER update_price_after_purchase
AFTER INSERT ON inventory_transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'purchase' THEN
        UPDATE products
        SET price = NEW.unit_price
        WHERE product_id = NEW.product_id;
    END IF;
END;
//
DELIMITER ;

-- STORED PROCEDURE: Get transactions for a product
DELIMITER //
CREATE PROCEDURE get_product_transactions(IN pid INT)
BEGIN
    SELECT * FROM inventory_transactions
    WHERE product_id = pid
    ORDER BY transaction_date DESC;
END;
//
DELIMITER ;
