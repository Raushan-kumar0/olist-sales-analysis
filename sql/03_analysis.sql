-- Question from management: "Sales grew fast all of 2017, but 2018 has gone flat. What's going on?"
-- Revenue below = item price (excludes freight), delivered orders only.
USE olist;

-- 1. Monthly trend: when did growth stop?
WITH monthly AS (
    SELECT order_month, SUM(price) AS revenue, COUNT(DISTINCT order_id) AS orders
    FROM sales_items
    GROUP BY order_month
)
SELECT order_month,
       ROUND(revenue)                                                   AS revenue,
       orders,
       ROUND(revenue / orders, 1)                                       AS avg_order_value,
       ROUND(100 * (revenue / LAG(revenue) OVER (ORDER BY order_month) - 1), 1) AS mom_growth_pct
FROM monthly
ORDER BY order_month;

-- 2. Region: first four months of 2018 vs the next four
SELECT region,
       ROUND(SUM(CASE WHEN order_month BETWEEN '2018-01' AND '2018-04' THEN price END)) AS jan_apr_2018,
       ROUND(SUM(CASE WHEN order_month BETWEEN '2018-05' AND '2018-08' THEN price END)) AS may_aug_2018,
       ROUND(100 * (SUM(CASE WHEN order_month BETWEEN '2018-05' AND '2018-08' THEN price END)
                  / SUM(CASE WHEN order_month BETWEEN '2018-01' AND '2018-04' THEN price END) - 1), 1) AS change_pct
FROM sales_items
GROUP BY region
ORDER BY change_pct;

-- 3. Category: which product lines are shrinking (and which are growing)?
WITH cat AS (
    SELECT category,
           SUM(CASE WHEN order_month BETWEEN '2018-01' AND '2018-04' THEN price ELSE 0 END) AS jan_apr,
           SUM(CASE WHEN order_month BETWEEN '2018-05' AND '2018-08' THEN price ELSE 0 END) AS may_aug
    FROM sales_items
    GROUP BY category
)
SELECT category, ROUND(jan_apr) AS jan_apr_2018, ROUND(may_aug) AS may_aug_2018,
       ROUND(may_aug - jan_apr) AS change_value
FROM cat
WHERE jan_apr > 50000
ORDER BY change_value
LIMIT 6;

-- 4. Do late deliveries hurt customer reviews?
SELECT delivery_status,
       COUNT(*)                                                    AS orders,
       ROUND(AVG(review_score), 2)                                 AS avg_review,
       ROUND(100 * AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END), 1) AS pct_1_or_2_star
FROM sales_orders
GROUP BY delivery_status;

-- 5. Late deliveries by quarter
SELECT CONCAT(LEFT(order_month, 4), '-Q', QUARTER(STR_TO_DATE(CONCAT(order_month, '-01'), '%Y-%m-%d'))) AS quarter,
       COUNT(*)                                                          AS orders,
       ROUND(100 * AVG(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END), 1) AS late_pct,
       ROUND(AVG(review_score), 2)                                       AS avg_review
FROM sales_orders
GROUP BY quarter
ORDER BY quarter;

-- 6. Delivery performance by region
SELECT region,
       COUNT(*)                                                          AS orders,
       ROUND(AVG(delivery_days), 1)                                      AS avg_delivery_days,
       ROUND(100 * AVG(CASE WHEN delivery_status = 'Late' THEN 1 ELSE 0 END), 1) AS late_pct,
       ROUND(AVG(review_score), 2)                                       AS avg_review
FROM sales_orders
GROUP BY region
ORDER BY late_pct DESC;

-- 7. How concentrated is revenue among sellers?
WITH seller_rev AS (
    SELECT seller_id, SUM(price) AS revenue
    FROM sales_items
    GROUP BY seller_id
),
ranked AS (
    SELECT revenue, NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM seller_rev
)
SELECT decile,
       COUNT(*)                                                    AS sellers,
       ROUND(100 * SUM(revenue) / (SELECT SUM(revenue) FROM seller_rev), 1) AS revenue_share_pct
FROM ranked
GROUP BY decile
ORDER BY decile
LIMIT 3;
