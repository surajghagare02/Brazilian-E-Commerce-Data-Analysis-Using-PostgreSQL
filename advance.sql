-- 🔴 LEVEL 3 – ADVANCED 
-- Running total revenue by month.
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    SUM(p.payment_value) AS monthly_revenue,
    SUM(SUM(p.payment_value)) OVER (
        ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp)
    ) AS running_total
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY month
ORDER BY month;

-- Rank top 3 products per category.
SELECT *
FROM (
    SELECT 
        p.product_category_name,
        oi.product_id,
        SUM(oi.price) AS total_sales,
        RANK() OVER (
            PARTITION BY p.product_category_name
            ORDER BY SUM(oi.price) DESC
        ) AS rnk
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_category_name, oi.product_id
) t
WHERE rnk <= 3;


-- Rank sellers by revenue (dense_rank).
SELECT 
    seller_id,
    SUM(price) AS revenue,
    DENSE_RANK() OVER (ORDER BY SUM(price) DESC) AS seller_rank
FROM order_items
GROUP BY seller_id;


-- Customer Lifetime Value (CLV).
SELECT 
    c.customer_unique_id,
    SUM(p.payment_value) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id
ORDER BY lifetime_value DESC;


-- Find repeat customers (more than 1 purchase).
SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1;

-- Cohort analysis by first purchase month.
SELECT 
    customer_unique_id,
    DATE_TRUNC('month', MIN(order_purchase_timestamp)) AS cohort_month
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_unique_id;

-- Revenue contribution percentage per category.
SELECT 
    p.product_category_name,
    SUM(oi.price) AS revenue,
    ROUND(
        100.0 * SUM(oi.price) / SUM(SUM(oi.price)) OVER (), 
        2
    ) AS revenue_percentage
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC;

-- Detect customers who churned (no purchase after 6 months).
SELECT 
    customer_unique_id,
    MAX(order_purchase_timestamp) AS last_purchase
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY customer_unique_id
HAVING MAX(order_purchase_timestamp) < 
       (SELECT MAX(order_purchase_timestamp) FROM orders) - INTERVAL '6 months';

-- Find top 10% customers by revenue.
SELECT *
FROM (
    SELECT 
        c.customer_unique_id,
        SUM(p.payment_value) AS revenue,
        NTILE(10) OVER (ORDER BY SUM(p.payment_value) DESC) AS percentile
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
) t
WHERE percentile = 1;

-- Analyze review score impact on revenue.
SELECT 
    r.review_score,
    AVG(p.payment_value) AS avg_order_value
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY r.review_score
ORDER BY r.review_score;

-- Find fastest and slowest delivery states.
SELECT 
    c.customer_state,
    AVG(order_delivered_customer_date - order_purchase_timestamp) AS avg_delivery_time
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_time;

-- Calculate cancellation rate.
SELECT 
    COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) * 100.0
    / COUNT(*) AS cancellation_rate
FROM orders;

-- Find peak sales hour of the day.
SELECT 
    EXTRACT(HOUR FROM order_purchase_timestamp) AS hour,
    COUNT(*) AS total_orders
FROM orders
GROUP BY hour
ORDER BY total_orders DESC;

-- Calculate revenue growth rate month over month.
SELECT 
    month,
    monthly_revenue,
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
        / LAG(monthly_revenue) OVER (ORDER BY month),
        2
    ) AS growth_percentage
FROM (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS monthly_revenue
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY month
) t;

-- Identify high-value but low-review customers.
SELECT 
    c.customer_unique_id,
    SUM(p.payment_value) AS revenue,
    AVG(r.review_score) AS avg_score
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id = p.order_id
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY c.customer_unique_id
HAVING SUM(p.payment_value) > 1000
   AND AVG(r.review_score) < 3;

