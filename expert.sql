-- 🟣 LEVEL 4 – EXPERT (15 Questions – Interview Killer)

-- Create a revenue KPI dashboard query.
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(p.payment_value) AS total_revenue,
    AVG(p.payment_value) AS avg_order_value,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
JOIN customers c ON o.customer_id = c.customer_id;

-- Build customer segmentation (High / Medium / Low value).

SELECT *,
CASE 
    WHEN revenue > 1000 THEN 'High'
    WHEN revenue BETWEEN 500 AND 1000 THEN 'Medium'
    ELSE 'Low'
END AS segment
FROM (
    SELECT 
        c.customer_unique_id,
        SUM(p.payment_value) AS revenue
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY c.customer_unique_id
) t;
-- Detect fraud pattern (multiple payments, same order).
SELECT order_id
FROM order_payments
GROUP BY order_id
HAVING COUNT(*) > 3;

-- Identify sellers with declining performance trend.
WITH seller_monthly_revenue AS (
    SELECT 
        oi.seller_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS monthly_revenue
    FROM order_items oi
    JOIN orders o 
        ON oi.order_id = o.order_id
    GROUP BY oi.seller_id, month
),

seller_trend AS (
    SELECT 
        seller_id,
        month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY seller_id
            ORDER BY month
        ) AS previous_month_revenue
    FROM seller_monthly_revenue
)

SELECT 
    seller_id,
    month,
    monthly_revenue,
    previous_month_revenue,
    (monthly_revenue - previous_month_revenue) AS revenue_change
FROM seller_trend
WHERE previous_month_revenue IS NOT NULL
  AND monthly_revenue < previous_month_revenue
ORDER BY seller_id, month;

-- Create rolling 3-month revenue average.
SELECT 
    month,
    AVG(monthly_revenue) OVER (
        ORDER BY month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_avg
FROM (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS monthly_revenue
    FROM orders o
    JOIN order_payments p ON o.order_id = p.order_id
    GROUP BY month
) t;

-- Market basket analysis (products bought together).
SELECT 
    a.product_id AS product_1,
    b.product_id AS product_2,
    COUNT(*) AS frequency
FROM order_items a
JOIN order_items b 
ON a.order_id = b.order_id
AND a.product_id < b.product_id
GROUP BY a.product_id, b.product_id
ORDER BY frequency DESC;

-- Find customer acquisition rate per month.
WITH first_purchase AS (
    SELECT 
        c.customer_unique_id,
        MIN(DATE_TRUNC('month', o.order_purchase_timestamp)) AS first_purchase_month
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
)

SELECT 
    first_purchase_month AS month,
    COUNT(customer_unique_id) AS new_customers
FROM first_purchase
GROUP BY first_purchase_month
ORDER BY first_purchase_month;

-- Calculate customer retention rate.
WITH customer_monthly_orders AS (
    SELECT 
        c.customer_unique_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month
    FROM customers c
    JOIN orders o 
        ON c.customer_id = o.customer_id
),

repeat_customers AS (
    SELECT 
        a.month AS current_month,
        COUNT(DISTINCT a.customer_unique_id) AS retained_customers
    FROM customer_monthly_orders a
    JOIN customer_monthly_orders b
        ON a.customer_unique_id = b.customer_unique_id
        AND a.month = b.month + INTERVAL '1 month'
    GROUP BY a.month
),

total_previous_month AS (
    SELECT 
        month + INTERVAL '1 month' AS current_month,
        COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM customer_monthly_orders
    GROUP BY month
)

SELECT 
    r.current_month,
    r.retained_customers,
    t.total_customers,
    ROUND(
        (r.retained_customers::numeric / t.total_customers) * 100, 
        2
    ) AS retention_rate_percentage
FROM repeat_customers r
JOIN total_previous_month t
    ON r.current_month = t.current_month
ORDER BY r.current_month;

-- Build RFM (Recency, Frequency, Monetary) analysis.
SELECT 
    c.customer_unique_id,
    MAX(order_purchase_timestamp) AS recency,
    COUNT(o.order_id) AS frequency,
    SUM(p.payment_value) AS monetary
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments p ON o.order_id = p.order_id
GROUP BY c.customer_unique_id;

-- Detect abnormal freight charges.
WITH category_freight AS (
    SELECT 
        p.product_category_name,
        AVG(oi.freight_value) AS avg_freight,
        STDDEV(oi.freight_value) AS std_freight
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_category_name
)

SELECT 
    oi.order_id,
    oi.product_id,
    p.product_category_name,
    oi.freight_value,
    cf.avg_freight
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category_freight cf 
    ON p.product_category_name = cf.product_category_name
WHERE oi.freight_value > cf.avg_freight + (2 * cf.std_freight)
ORDER BY oi.freight_value DESC;

-- Find seasonal sales patterns.
SELECT 
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
    SUM(oi.price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- Build seller performance scorecard.
WITH seller_metrics AS (
    SELECT 
        oi.seller_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.price) AS total_revenue,
        AVG(r.review_score) AS avg_rating,
        AVG(o.order_delivered_customer_date - 
            o.order_purchase_timestamp) AS avg_delivery_time
    FROM order_items oi
    JOIN orders o 
        ON oi.order_id = o.order_id
    LEFT JOIN order_reviews r 
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
)

SELECT *,
       DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM seller_metrics;

-- Identify products with high sales but low ratings.
WITH product_stats AS (
    SELECT 
        p.product_id,
        COUNT(oi.order_id) AS total_sales,
        AVG(r.review_score) AS avg_rating
    FROM products p
    JOIN order_items oi 
        ON p.product_id = oi.product_id
    LEFT JOIN orders o 
        ON oi.order_id = o.order_id
    LEFT JOIN order_reviews r   -- ✅ FIXED HERE
        ON o.order_id = r.order_id
    GROUP BY p.product_id
)

SELECT *
FROM product_stats
WHERE total_sales > 100
  AND avg_rating < 3
ORDER BY total_sales DESC;

-- Predict revenue using trend projection logic.
WITH monthly_revenue AS (
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY month
),

growth AS (
    SELECT 
        month,
        revenue,
        revenue - LAG(revenue) OVER (ORDER BY month) AS revenue_change
    FROM monthly_revenue
)

SELECT 
    month,
    revenue,
    revenue_change,
    revenue + COALESCE(revenue_change,0) AS next_month_projection
FROM growth;

-- Create a full business summary report using CTEs.
WITH revenue AS (
    SELECT SUM(oi.price) AS total_revenue
    FROM order_items oi
),

orders_count AS (
    SELECT COUNT(*) AS total_orders
    FROM orders
),

customers_count AS (
    SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
    FROM customers
),

avg_order_value AS (
    SELECT AVG(payment_value) AS avg_order_value
    FROM payments
)

SELECT 
    r.total_revenue,
    o.total_orders,
    c.total_customers,
    a.avg_order_value
FROM revenue r,
     orders_count o,
     customers_count c,
     avg_order_value a;
