-- customer_shopping_analysis.sql
-- Converted from the provided document into a single .sql file.
-- Database/Table assumed: customer_shopping

/* Q1. What is the revenue contribution of each age group? */
SELECT
    age_group,
    ROUND(SUM(purchase_amount), 2) AS total_revenue
FROM customer_shopping
GROUP BY age_group
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------------------------

/* Q2. Which customers used a discount but still spent more than the average purchase amount in each category? */
SELECT
    customer_id,
    category,
    avg_cat_purchase,
    purchase_amount
FROM (
    SELECT
        *,
        AVG(purchase_amount) OVER (PARTITION BY category) AS avg_cat_purchase
    FROM customer_shopping
) t
WHERE discount_applied = 'Yes'
  AND purchase_amount > avg_cat_purchase;

-- ------------------------------------------------------------------------------------------------

/* Q3. Which are the top 5 products with the highest average review rating? */
WITH ProductRatings AS (
    SELECT
        item_purchased,
        AVG(review_rating) AS avg_prod_rating,
        RANK() OVER (ORDER BY AVG(review_rating) DESC) AS rnk
    FROM customer_shopping
    GROUP BY item_purchased
)
SELECT
    item_purchased,
    ROUND(avg_prod_rating, 3) AS avg_prod_rating
FROM ProductRatings
WHERE rnk <= 5;

-- ------------------------------------------------------------------------------------------------

/* Q4. Compare the average purchase amounts between Standard and Express Shipping. */
SELECT
    shipping_type,
    ROUND(AVG(purchase_amount), 2) AS average_purchase_amount
FROM customer_shopping
WHERE shipping_type IN ('Standard', 'Express')
GROUP BY shipping_type;

-- ------------------------------------------------------------------------------------------------

/* Q5. Do subscribed customers spend more? Compare average spend and total revenue between subscribers and non-subscribers. */
SELECT
    subscription_status,
    COUNT(customer_id) AS total_customers,
    ROUND(AVG(purchase_amount), 2) AS avg_spend,
    ROUND(SUM(purchase_amount), 2) AS total_revenue
FROM customer_shopping
GROUP BY subscription_status
ORDER BY total_revenue DESC;

-- ------------------------------------------------------------------------------------------------

/* Q6. Which 5 products have the highest percentage of purchases with discounts applied? */
WITH ProductDiscountStats AS (
    SELECT
        item_purchased,
        COUNT(*) AS total_orders,
        ROUND(100.0 * SUM(discount_applied = 'Yes') / COUNT(*), 2) AS discount_percentage,
        ROUND(SUM(purchase_amount), 2) AS total_revenue
    FROM customer_shopping
    GROUP BY item_purchased
),
RankedProducts AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY discount_percentage DESC) AS discount_rank
    FROM ProductDiscountStats
)
SELECT
    item_purchased,
    total_orders,
    discount_percentage,
    total_revenue
FROM RankedProducts
WHERE discount_rank <= 5
ORDER BY discount_rank ASC;

-- ------------------------------------------------------------------------------------------------

/* Q7. Segment customers into New, Returning, and Loyal based on their total number of previous purchases, and show the count of each segment. */
WITH customer_type AS (
    SELECT
        customer_id,
        previous_purchases,
        CASE
            WHEN previous_purchases = 1 THEN 'New'
            WHEN previous_purchases BETWEEN 2 AND 10 THEN 'Returning'
            ELSE 'Loyal'
        END AS customer_segment
    FROM customer_shopping
)
SELECT
    customer_segment,
    COUNT(*) AS number_of_customers
FROM customer_type
GROUP BY customer_segment;

-- ------------------------------------------------------------------------------------------------

/* Q8. What are the top 3 most purchased products within each category? */
WITH item_counts AS (
    SELECT
        category,
        item_purchased,
        COUNT(customer_id) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY category ORDER BY COUNT(customer_id) DESC) AS item_rank
    FROM customer_shopping
    GROUP BY category, item_purchased
)
SELECT
    item_rank,
    category,
    item_purchased,
    total_orders
FROM item_counts
WHERE item_rank <= 3;

-- ------------------------------------------------------------------------------------------------

/* Q9. Are customers who are repeat buyers (more than 5 previous purchases) also likely to subscribe? */
SELECT
    subscription_status,
    COUNT(customer_id) AS repeat_buyers
FROM customer_shopping
WHERE previous_purchases > 5
GROUP BY subscription_status;

-- ------------------------------------------------------------------------------------------------

/* Q10. List Top 10 products frequently bought by repeat customers. */
WITH repeat_customers AS (
    SELECT customer_id
    FROM customer_shopping
    GROUP BY customer_id
    HAVING COUNT(*) >= 2
),
product_stats AS (
    SELECT
        item_purchased,
        COUNT(*) AS total_purchases,
        SUM(customer_id IN (SELECT customer_id FROM repeat_customers)) AS repeat_purchases
    FROM customer_shopping
    GROUP BY item_purchased
)
SELECT
    item_purchased,
    total_purchases,
    repeat_purchases,
    ROUND(100.0 * repeat_purchases / total_purchases, 2) AS repeat_purchase_pct
FROM product_stats
ORDER BY repeat_purchase_pct DESC, total_purchases DESC
LIMIT 10;
