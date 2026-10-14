-- Seller performance tiers for 2018 (Jan-Aug), one CASE rule instead of a manual sheet.
-- Rules are checked top to bottom; the first match wins.
--   Needs attention : 10+ orders AND (avg review < 3.5 OR 20%+ of orders late)
--   Gold            : revenue >= R$15,000 AND avg review >= 4.2 AND under 8% late
--   Silver          : revenue >= R$5,000  AND avg review >= 4.0
--   Standard        : everyone else
USE olist;

CREATE OR REPLACE VIEW vw_seller_tiers AS
WITH seller_orders AS (          -- one row per seller per order
    SELECT seller_id, order_id, SUM(price) AS revenue
    FROM sales_items
    WHERE order_year = 2018
    GROUP BY seller_id, order_id
),
seller_2018 AS (
    SELECT so.seller_id,
           COUNT(*)                                                      AS orders,
           SUM(so.revenue)                                               AS revenue,
           AVG(o.review_score)                                           AS avg_review,
           AVG(CASE WHEN o.delivery_status = 'Late' THEN 1 ELSE 0 END)   AS late_rate
    FROM seller_orders so
    JOIN sales_orders o ON o.order_id = so.order_id
    GROUP BY so.seller_id
)
SELECT seller_id, orders,
       ROUND(revenue, 2)        AS revenue,
       ROUND(avg_review, 2)     AS avg_review,
       ROUND(100 * late_rate, 1) AS late_pct,
       CASE
           WHEN orders >= 10 AND (avg_review < 3.5 OR late_rate >= 0.20)  THEN 'Needs attention'
           WHEN revenue >= 15000 AND avg_review >= 4.2 AND late_rate < 0.08 THEN 'Gold'
           WHEN revenue >= 5000  AND avg_review >= 4.0                      THEN 'Silver'
           ELSE 'Standard'
       END AS tier
FROM seller_2018;

-- Tier summary
SELECT tier,
       COUNT(*)                                                    AS sellers,
       ROUND(SUM(revenue))                                         AS revenue,
       ROUND(100 * SUM(revenue) / (SELECT SUM(revenue) FROM vw_seller_tiers), 1) AS revenue_share_pct,
       ROUND(AVG(avg_review), 2)                                   AS avg_review
FROM vw_seller_tiers
GROUP BY tier
ORDER BY revenue DESC;

-- Sellers that most need a call: biggest revenue among 'Needs attention'
SELECT seller_id, orders, revenue, avg_review, late_pct
FROM vw_seller_tiers
WHERE tier = 'Needs attention'
ORDER BY revenue DESC
LIMIT 10;
