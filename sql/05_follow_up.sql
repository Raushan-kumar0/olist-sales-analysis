-- Follow-up to 03_analysis.sql: two questions the first round left open.
USE olist;

-- A. Why are North/Northeast deliveries so slow - the sellers or the carriers?
--    handling = order approved -> seller hands parcel to carrier
--    transit  = carrier picks up -> customer receives it
SELECT region,
       COUNT(*)                     AS orders,
       ROUND(AVG(delivery_days), 1) AS total_days,
       ROUND(AVG(handling_days), 1) AS seller_handling_days,
       ROUND(AVG(transit_days), 1)  AS carrier_transit_days
FROM sales_orders
GROUP BY region
ORDER BY total_days DESC;

-- Where do the products come from? (share of items shipped by sellers in Sao Paulo state)
SELECT o.region,
       ROUND(100 * AVG(CASE WHEN i.seller_state = 'SP' THEN 1 ELSE 0 END), 1) AS pct_items_from_sp_sellers
FROM sales_items i
JOIN sales_orders o ON o.order_id = i.order_id
GROUP BY o.region
ORDER BY o.region;

-- B. The two categories that shrank most in 2018: did they lose sellers, or buyers?
SELECT category,
       CASE WHEN order_month <= '2018-04' THEN 'Jan-Apr' ELSE 'May-Aug' END AS period,
       COUNT(DISTINCT seller_id) AS active_sellers,
       COUNT(DISTINCT order_id)  AS orders,
       ROUND(SUM(price))         AS revenue,
       ROUND(AVG(price))         AS avg_item_price
FROM sales_items
WHERE order_year = 2018
  AND category IN ('computers_accessories', 'sports_leisure')
GROUP BY category, period
ORDER BY category, period;
