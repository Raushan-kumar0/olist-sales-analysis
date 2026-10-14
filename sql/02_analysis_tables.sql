-- Builds two analysis tables from the raw tables (re-run after reloading data).
-- Real tables with indexes keep the analysis queries fast.
USE olist;

DROP TABLE IF EXISTS sales_orders, sales_items, order_review_avg;
DROP VIEW IF EXISTS vw_order_items, vw_orders, vw_seller_tiers;

-- Average review score per order (a few orders have more than one review)
CREATE TABLE order_review_avg (PRIMARY KEY (order_id)) AS
SELECT order_id, AVG(review_score) AS review_score
FROM order_reviews
GROUP BY order_id;

-- One row per item sold: delivered orders placed Jan 2017 - Aug 2018
-- (2016 has almost no orders and Sep-Oct 2018 are incomplete, so both are left out)
CREATE TABLE sales_items AS
SELECT
    o.order_id,
    DATE(o.order_purchase_timestamp)                         AS order_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')         AS order_month,
    YEAR(o.order_purchase_timestamp)                         AS order_year,
    c.customer_state,
    sr.region,
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'unknown')             AS category,
    i.seller_id,
    sl.seller_state,
    i.price,
    i.freight_value,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) AS delivery_days,
    -- split of delivery time: seller handling (approval -> carrier) and carrier transit (carrier -> customer)
    DATEDIFF(o.order_delivered_carrier_date, o.order_approved_at)         AS handling_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_delivered_carrier_date) AS transit_days,
    CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date)
         THEN 'Late' ELSE 'On time' END                      AS delivery_status,
    r.review_score
FROM orders o
JOIN order_items i               ON i.order_id = o.order_id
JOIN customers c                 ON c.customer_id = o.customer_id
JOIN state_region sr             ON sr.state = c.customer_state
JOIN products p                  ON p.product_id = i.product_id
JOIN sellers sl                  ON sl.seller_id = i.seller_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
LEFT JOIN order_review_avg r     ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

CREATE INDEX idx_si_order  ON sales_items (order_id);
CREATE INDEX idx_si_seller ON sales_items (seller_id);
CREATE INDEX idx_si_month  ON sales_items (order_month);

-- One row per order (delivery and review facts belong to the order, not the item)
CREATE TABLE sales_orders (PRIMARY KEY (order_id)) AS
SELECT order_id,
       MIN(order_month)     AS order_month,
       MIN(region)          AS region,
       MIN(delivery_status) AS delivery_status,
       MIN(delivery_days)   AS delivery_days,
       MIN(handling_days)   AS handling_days,
       MIN(transit_days)    AS transit_days,
       MIN(review_score)    AS review_score,
       SUM(price)           AS order_value
FROM sales_items
GROUP BY order_id;
