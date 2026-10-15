-- =============================================================================
--  database/init.sql - Khởi tạo dữ liệu cho đề 002: Quản lý sản phẩm
--  MySQL tự chạy file này ở LẦN KHỞI ĐỘNG ĐẦU TIÊN khi được mount vào
--  /docker-entrypoint-initdb.d/  (database và user do biến MYSQL_* tạo sẵn)
-- =============================================================================
SET NAMES utf8mb4;

USE ptit_shop_db;

CREATE TABLE IF NOT EXISTS products (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_name    VARCHAR(150) NOT NULL,
    category        VARCHAR(50) NOT NULL,
    brand           VARCHAR(50) NOT NULL,
    price           DECIMAL(12,2) NOT NULL,
    stock           INT NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO products (product_name, category, brand, price, stock) VALUES
    ('Bàn phím cơ K8 Pro', 'Phụ kiện', 'Keychron', 2150000, 34),
    ('Chuột không dây MX Master 3S', 'Phụ kiện', 'Logitech', 2390000, 21),
    ('Màn hình 27 inch 2K', 'Màn hình', 'Dell', 6490000, 12),
    ('Laptop ThinkPad E14', 'Laptop', 'Lenovo', 18990000, 8),
    ('Tai nghe WH-1000XM5', 'Âm thanh', 'Sony', 7490000, 15),
    ('SSD NVMe 1TB 990 Pro', 'Linh kiện', 'Samsung', 2890000, 40),
    ('Router Wi-Fi 6 AX55', 'Mạng', 'TP-Link', 1590000, 27),
    ('Webcam C920', 'Phụ kiện', 'Logitech', 1450000, 19);
