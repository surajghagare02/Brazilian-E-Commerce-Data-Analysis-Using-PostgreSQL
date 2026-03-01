-- LEVEL 2 – INTERMEDIATE (15 Questions)

-- Monthly revenue trend.
SELECT 
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY 1
ORDER BY 1;

-- Revenue per state.
SELECT 
    c.customer_state,
    SUM(oi.price + oi.freight_value) AS revenue
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC;


-- Top 5 sellers by revenue.
SELECT 
    s.seller_id,
    SUM(oi.price + oi.freight_value) AS revenue
FROM order_items oi
JOIN sellers s 
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_id
ORDER BY revenue DESC
LIMIT 5;


-- Top 10 product categories by revenue.
SELECT 
    p.product_category,
    SUM(oi.price + oi.freight_value) AS revenue
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_category
ORDER BY revenue DESC
LIMIT 10;


-- Average delivery time (in days).
SELECT 
    AVG(DATE_PART('day', 
        o.order_delivered_customer_date - o.order_purchase_timestamp
    )) AS avg_delivery_days
FROM orders o
WHERE o.order_delivered_customer_date IS NOT NULL;

-- Count delayed vs on-time deliveries.
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 'On Time'
        ELSE 'Delayed'
    END AS delivery_status,
    COUNT(*) AS total_orders
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;


-- Payment method distribution (count + revenue).
SELECT 
    payment_type,
    COUNT(*) AS total_transactions,
    SUM(payment_value) AS total_revenue
FROM payments
GROUP BY payment_type
ORDER BY total_revenue DESC;


-- Average order value per customer.
SELECT 
    o.customer_id,
    AVG(oi.price + oi.freight_value) AS avg_order_value
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY o.customer_id;


-- Find customers with more than 5 orders.
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
HAVING COUNT(order_id) > 5
ORDER BY total_orders DESC;

-- Top 5 cities by total revenue.
SELECT 
    c.customer_city,
    SUM(oi.price + oi.freight_value) AS revenue
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id
JOIN order_items oi 
    ON o.order_id = oi.order_id
GROUP BY c.customer_city
ORDER BY revenue DESC
LIMIT 5;

-- Revenue generated in 2017 vs 2018.
SELECT 
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    SUM(oi.price + oi.freight_value) AS revenue
FROM orders o
JOIN order_items oi 
    ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
GROUP BY year
ORDER BY year;

-- Find products that were never sold.
SELECT 
    p.product_id
FROM products p
LEFT JOIN order_items oi 
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- Sellers who made more than 100 sales.
SELECT 
    seller_id,
    COUNT(order_id) AS total_sales
FROM order_items
GROUP BY seller_id
HAVING COUNT(order_id) > 100
ORDER BY total_sales DESC;

-- Average review score per state.
SELECT 
    c.customer_state,
    AVG(r.review_score) AS avg_review_score
FROM reviews r
JOIN orders o 
    ON r.order_id = o.order_id
JOIN customers c 
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_review_score DESC;

-- Orders with multiple payment types.
SELECT 
    order_id,
    COUNT(DISTINCT payment_type) AS payment_type_count
FROM payments
GROUP BY order_id
HAVING COUNT(DISTINCT payment_type) > 1;