-- Olist Brazilian e-commerce data (Kaggle: olistbr/brazilian-ecommerce)
-- MySQL 8.0+

CREATE DATABASE IF NOT EXISTS olist;
USE olist;

DROP VIEW  IF EXISTS vw_order_items;
DROP TABLE IF EXISTS order_reviews, order_items, orders, products, category_translation,
                     sellers, customers, state_region;

CREATE TABLE customers (
    customer_id         CHAR(32) PRIMARY KEY,
    customer_unique_id  CHAR(32) NOT NULL,
    customer_city       VARCHAR(60),
    customer_state      CHAR(2)  NOT NULL
);

CREATE TABLE sellers (
    seller_id     CHAR(32) PRIMARY KEY,
    seller_city   VARCHAR(60),
    seller_state  CHAR(2) NOT NULL
);

CREATE TABLE category_translation (
    product_category_name          VARCHAR(60) PRIMARY KEY,
    product_category_name_english  VARCHAR(60) NOT NULL
);

CREATE TABLE products (
    product_id             CHAR(32) PRIMARY KEY,
    product_category_name  VARCHAR(60)
);

CREATE TABLE orders (
    order_id                       CHAR(32) PRIMARY KEY,
    customer_id                    CHAR(32) NOT NULL,
    order_status                   VARCHAR(15) NOT NULL,
    order_purchase_timestamp       DATETIME NOT NULL,
    order_approved_at              DATETIME NULL,
    order_delivered_carrier_date   DATETIME NULL,      -- seller handed the parcel to the carrier
    order_delivered_customer_date  DATETIME NULL,
    order_estimated_delivery_date  DATETIME NULL,
    INDEX idx_orders_purchase (order_purchase_timestamp)
);

CREATE TABLE order_items (
    order_id       CHAR(32) NOT NULL,
    order_item_id  INT      NOT NULL,
    product_id     CHAR(32) NOT NULL,
    seller_id      CHAR(32) NOT NULL,
    price          DECIMAL(10,2) NOT NULL,
    freight_value  DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id),
    INDEX idx_items_seller (seller_id)
);

CREATE TABLE order_reviews (
    review_id     CHAR(32) NOT NULL,
    order_id      CHAR(32) NOT NULL,
    review_score  TINYINT  NOT NULL,
    INDEX idx_reviews_order (order_id)
);

-- Brazil's 27 states grouped into its 5 official regions
CREATE TABLE state_region (
    state   CHAR(2) PRIMARY KEY,
    region  VARCHAR(12) NOT NULL
);
INSERT INTO state_region VALUES
('AC','North'),('AP','North'),('AM','North'),('PA','North'),('RO','North'),('RR','North'),('TO','North'),
('AL','Northeast'),('BA','Northeast'),('CE','Northeast'),('MA','Northeast'),('PB','Northeast'),
('PE','Northeast'),('PI','Northeast'),('RN','Northeast'),('SE','Northeast'),
('DF','Center-West'),('GO','Center-West'),('MT','Center-West'),('MS','Center-West'),
('ES','Southeast'),('MG','Southeast'),('RJ','Southeast'),('SP','Southeast'),
('PR','South'),('RS','South'),('SC','South');
