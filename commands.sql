CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  customer_name VARCHAR(100),
  email VARCHAR(100),
  city VARCHAR(50)
);
CREATE TABLE products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(100),
  category VARCHAR(50),
  price NUMERIC(10,2)
);
CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id),
  order_date DATE
);
CREATE TABLE order_items (
  order_item_id INT PRIMARY KEY,
  order_id INT REFERENCES orders(order_id),
  product_id INT REFERENCES products(product_id),
  quantity INT
);
INSERT INTO customers VALUES
(1,'Aline Uwase','aline@mail.com','Kigali'),
(2,'Eric Mugisha','eric@mail.com','Huye'),
(3,'Grace Ineza','grace@mail.com','Musanze'),
(4,'Patrick Nkurunziza','patrick@mail.com','Kigali'),
(5,'Diane Umutoni','diane@mail.com','Rubavu'),
(6,'Joseph Habimana','joseph@mail.com','Kigali');
INSERT INTO products VALUES
(1,'Milk 1L','Dairy',1.50),
(2,'Yogurt','Dairy',1.20),
(3,'Rice 5kg','Grains',8.00),
(4,'Maize Flour 2kg','Grains',3.50),
(5,'Orange Juice','Beverages',2.80),
(6,'Bottled Water','Beverages',0.80),
(7,'Cooking Oil 1L','Pantry',4.00),
(8,'Sugar 1kg','Pantry',1.90);
INSERT INTO orders VALUES
(1,1,'2026-01-05'),(2,2,'2026-01-08'),(3,1,'2026-01-15'),
(4,3,'2026-01-20'),(5,4,'2026-02-02'),(6,2,'2026-02-10'),
(7,5,'2026-02-14'),(8,1,'2026-02-25'),(9,3,'2026-03-03'),
(10,4,'2026-03-12'),(11,1,'2026-03-20'),(12,2,'2026-04-01'),
(13,5,'2026-04-09'),(14,3,'2026-04-18'),(15,4,'2026-05-02');
INSERT INTO order_items VALUES
(1,1,1,4),(2,1,3,1),(3,2,5,3),(4,2,6,6),(5,3,2,5),
(6,3,7,2),(7,4,4,2),(8,4,8,3),(9,5,1,2),(10,5,5,2),
(11,6,3,2),(12,6,7,1),(13,7,6,10),(14,7,2,4),(15,8,8,2),
(16,8,1,3),(17,9,5,4),(18,9,4,1),(19,10,7,3),(20,10,6,12),
(21,11,3,1),(22,12,2,6),(23,13,1,5),(24,14,8,4),(25,15,5,3);
SELECT o.order_id, c.customer_name, c.city, o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;
SELECT oi.order_id, p.product_name, p.category, p.price, oi.quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id;
SELECT c.customer_id, c.customer_name, o.order_id, o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id;
-- CTE
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
SELECT c.customer_name,
       SUM(oi.quantity * p.price) AS total_spend,
       RANK() OVER (ORDER BY SUM(oi.quantity * p.price) DESC) AS spend_rank
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY c.customer_name;
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_number
FROM orders;
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
SELECT customer_id, order_id, order_date, prev_date,
       order_date - prev_date AS days_between
FROM (
  SELECT customer_id, order_id, order_date,
         LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS prev_date,
         COUNT(*) OVER (PARTITION BY customer_id) AS order_count
  FROM orders
) t
WHERE order_count > 1 AND prev_date IS NOT NULL;
