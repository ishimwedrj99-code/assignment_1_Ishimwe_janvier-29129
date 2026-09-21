# assignment_1_Ishimwe_janvier-29129
# Sunrise Supermarket SQL Assignment

**Name:** Ishimwe janvier
**Student ID:** 29129
**DBMS used:** PostgreSQL 

## Summary
This project builds a small relational database for Sunrise Supermarket with
four tables: `customers`, `products`, `orders` and `order_items`. I filled the
tables with sample data (6 customers, 8 products in 4 categories, 15 orders
and 25 order items spread over January to May 2026). I then wrote 3 JOIN
queries, 1 CTE query and 4 window-function queries to answer management's
questions about customers, purchases and sales trends.

## How to Run
1. Open a PostgreSQL environment (I used OneCompiler with PostgreSQL selected).
2. Run `commands.sql`. It creates the tables, inserts the sample data and
   contains all the queries below.
3. Run each query one at a time and compare with the screenshots in this repo.

## Business Scenario
Sunrise Supermarket sells products to customers who place orders containing
one or more items. Management wants to understand who their customers are,
what they buy, and how sales are trending over time.

---

## JOIN Queries

### JOIN 1: Orders with customer name, city and order date (INNER JOIN)
```sql
SELECT o.order_id, c.customer_name, c.city, o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;
```
**Explanation:** The INNER JOIN matches each order to its customer using `customer_id` and returns only orders that have a matching customer.
**Result:** 15 rows, one per order (screenshot: `join1.png`).
**Business interpretation:** Management can see who orders, from which city and when. Kigali customers (Aline and Patrick) place many of the orders.

### JOIN 2: Order items with product name, category, price and quantity
```sql
SELECT oi.order_id, p.product_name, p.category, p.price, oi.quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id;
```
**Explanation:** The query joins `order_items` to `products` so each purchased item shows the product's name, category and price next to the quantity bought.
**Result:** 25 rows, one per order item (screenshots: `join2_part1.png`, `join2_part2.png`, because the output is long).
**Business interpretation:** It shows what customers actually buy, for example large quantities of low-priced items such as bottled water (10 and 12 units in single orders), which helps with stock planning.

### JOIN 3: All customers, including those with no orders (LEFT JOIN)
```sql
SELECT c.customer_id, c.customer_name, o.order_id, o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id;
```
**Explanation:** The LEFT JOIN keeps every customer from the left table. Customers without orders still appear, with NULL in the order columns.
**Result:** 16 rows. Joseph Habimana appears with empty order_id and order_date (screenshot: `join3.png`).
**Business interpretation:** Joseph is registered but has never ordered, so he is a good target for a welcome offer or a first-purchase discount.

---

## CTE Query: Customers above average spend
```sql
WITH customer_totals AS (
  SELECT c.customer_id, c.customer_name,
         SUM(oi.quantity * p.price) AS total_spend
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY c.customer_id, c.customer_name
)
SELECT customer_name, total_spend
FROM customer_totals
WHERE total_spend > (SELECT AVG(total_spend) FROM customer_totals);
```
**Explanation:** The CTE first calculates each customer's total spend (quantity x price). The main query then keeps only customers whose total is above the average of all customers.
**Result:** The average spend is 35.72. Three customers are above it: Patrick Nkurunziza (38.60), Eric Mugisha (40.40) and Aline Uwase (44.30) (screenshot: `cte.png`).
**Business interpretation:** These are the high-value customers. The supermarket can reward them with loyalty points or coupons to keep them buying. Grace Ineza (35.00) is just below average and could be encouraged to spend a little more.

---

## Window-Function Queries

### Window 1: Rank customers by total spend
```sql
SELECT c.customer_name,
       SUM(oi.quantity * p.price) AS total_spend,
       RANK() OVER (ORDER BY SUM(oi.quantity * p.price) DESC) AS spend_rank
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY c.customer_name;
```
**Explanation:** `RANK() OVER (ORDER BY ... DESC)` ranks customers by total spend, highest first. Tied customers would share a rank.
**Result:** 1 Aline Uwase (44.30), 2 Eric Mugisha (40.40), 3 Patrick Nkurunziza (38.60), 4 Grace Ineza (35.00), 5 Diane Umutoni (20.30) (screenshot: `window1.png`).
**Business interpretation:** Aline is the top customer and Diane the lowest spender. The ranking shows who deserves VIP treatment and who could be encouraged to buy more.

### Window 2: Number each customer's orders in the order placed
```sql
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_number
FROM orders;
```
**Explanation:** `PARTITION BY customer_id` restarts the numbering for each customer, and `ORDER BY order_date` numbers their orders from first to latest.
**Result:** 15 rows. Aline has 4 orders, Eric, Grace and Patrick have 3 each, and Diane has 2 (screenshot: `window2.png`).
**Business interpretation:** It shows how many times each customer came back. Every customer with orders is a repeat buyer, and Aline is the most loyal.

### Window 3: Running total of revenue over time
```sql
SELECT order_date, daily_revenue,
       SUM(daily_revenue) OVER (ORDER BY order_date) AS running_revenue
FROM (
  SELECT o.order_date, SUM(oi.quantity * p.price) AS daily_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY o.order_date
) t
ORDER BY order_date;
```
**Explanation:** The subquery calculates revenue for each order date. `SUM() OVER (ORDER BY order_date)` then adds the daily amounts up cumulatively.
**Result:** Running revenue grows from 14.00 on 2026-01-05 to 178.60 on 2026-05-02. Daily revenue peaks at 21.60 on 2026-03-12, then falls to about 7.20 to 8.40 per order date from April (screenshot: `window3.png`).
**Business interpretation:** Total sales keep growing, but the daily amounts are smaller after March. Management should investigate why (fewer large baskets, seasonality) and consider promotions.
