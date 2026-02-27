-- Begineer level 
-- Show first 10 customers.
select * 
from customers
limit 10;

-- Count total customers.
select count(*)as total_customers
from customers;


-- Count total orders.
select count(*)as total_orders
from orders


-- Show distinct order statuses.
select distinct order_status
from orders;

-- Find total revenue (from payments).
select sum(payment_value)as total_revenue
from order_payments;

-- Show top 5 states with most customers.
select customer_state,count(*)as total_customers
from customers
group by customer_state
order by total_customers desc
limit 5;

-- Count orders per status.
select order_status, count(*)as total_orders
from orders
group by order_status
order by total_orders desc;

-- Show products with weight > 1000g.
select product_category_name,product_weight_g
from products
where product_weight_g>1000;

-- Find total sellers.
select count(*)as total_sallers
from sellers;


-- Show orders placed in 2018.
select *
from orders
where extract(year from order_purchase_timestamp)=2018;


-- Find total number of reviews.
select count(*)as total_reviews
from order_reviews;

-- Show customers from state 'SP'.
select * 
from customers
where customer_state='SP';


-- Count how many products in each category.
select product_category_name,count(*)as count_of_products
from products
group by product_category_name
order by count_of_products desc;

-- Find average payment value.
select avg(payment_value)as avg_payment
from order_payments;

-- Show top 10 most expensive order items.
select order_id,product_id,price
from order_items
order by price desc
limit 10;


