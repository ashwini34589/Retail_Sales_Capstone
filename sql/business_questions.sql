create database RetailAnalysis;
/* Customers-sales */
alter table sales_cleaned
add constraint fk_sales_customerss
foreign key (customer_id)
references customers_cleaned(customer_id);

/* product-sales */

alter table sales_cleaned
add constraint fk_sales_productss
foreign key (product_id)
references products_cleaned(product_id);

/* stores-sales */

alter table sales_cleaned
add constraint fk_sales_storess
foreign key (store_id)
references stores_cleaned(store_id);
 
 insert into stores_cleaned values('-','online_store','online','-','-',0);

/* return-sales */

alter table returns_cleaned
add constraint fk_returns_salesss
foreign key (order_id)
references sales_cleaned(order_id)

/*create indexes*/
create index idx_sales_customerssss
on dbo.sales_cleaned(customer_id);

create index idx_sales_productsssss
on dbo.sales_cleaned(product_id);

create index idx_sales_storessss
on dbo.sales_cleaned(store_id);

create index idx_sales_returnsss
on dbo.sales_cleaned(order_id);


/*Write SQL to calculate derived metrics (profit, discount % */

/*Total  Profit */
select Round(sum(profit),2) AS Total_Profit from sales_cleaned

/*Return Percentage*/
Select Round(Cast(Count(r.return_id)*100.0 /Count(sd.order_id) AS float),2) AS 'Total Return %' From sales_cleaned sd
left join returns_cleaned r
on sd.order_id = r.order_id

/*Discount Percentage*/
Select Round(sum(discount_pct * total_amount)/ Nullif(sum(total_amount), 0)* 100,2) AS "Total Discount %"
from sales_cleaned;
/*Business Questions */
--1. What is the total revenue generated in the last 12 months?
SELECT 
    SUM(quantity * unit_price) AS total_revenue_last_12_months
FROM sales_cleaned
WHERE order_date >= DATEADD(MONTH, -12, GETDATE());

--2Which are the top 5 best-selling products by quantity?
SELECT TOP 5
    p.product_id,
    p.product_name,
    SUM(s.quantity) AS total_quantity_sold
FROM sales_cleaned s
JOIN products_cleaned p
    ON s.product_id = p.product_id
GROUP BY 
    p.product_id,
    p.product_name
ORDER BY 
    total_quantity_sold DESC;
--3. How many customers are from each region?
SELECT 
    region,
    COUNT(customer_id) AS total_customers
FROM customers_cleaned
GROUP BY region
ORDER BY total_customers DESC;
--4.Which store has the highest profit in the past year?
SELECT TOP 1 s.store_name AS Store_Name ,ROUND(SUM(sd.profit),2) AS Profit FROM stores_cleaned s
JOIN sales_cleaned sd
ON s.store_id=sd.store_id
WHERE YEAR(sd.order_date) = (SELECT YEAR(MAX(order_date)) - 1 FROM sales_cleaned) AND s.store_id<>'-'
GROUP BY s.store_name  
ORDER BY Profit DESC	

   
--5. What is the return rate by product category?
SELECT p.category as Category,CAST(ROUND(CAST(COUNT(r.order_id) * 100.0 / NULLIF(COUNT(sd.order_id), 0) AS FLOAT),2) AS VARCHAR(50))+' %' AS Return_Rate FROM products_cleaned p
JOIN sales_cleaned sd
ON sd.product_id = p.product_id
LEFT JOIN returns_cleaned r
ON sd.order_id = r.order_id
GROUP BY p.category


--6. What is the average revenue per customer by age group? 

SELECT c.age_group AS Age_Group , ROUND(AVG(sd.total_amount),2) AS Avg_Revenue FROM sales_cleaned sd
JOIN customers_cleaned c
on c.customer_id=sd.customer_id
GROUP BY Age_Group



--7 Which sales channel (Online vs In-Store) is more profitable on average?*/
select sales_channel,
avg(profit) as avg_profit_per_order
from sales_cleaned
group by sales_channel
order by avg_profit_per_order desc;

--8.How has monthly profit changed over the last 2 years by region? 
SELECT s.region AS Region,YEAR(sd.order_date) AS Sales_Year,MONTH(sd.order_date) AS Sales_Month,ROUND(SUM(sd.profit),2) AS Monthly_Profit
FROM sales_cleaned sd
JOIN stores_cleaned s
ON sd.store_id = s.store_id
WHERE sd.order_date >= DATEADD(YEAR,-2,(SELECT MAX(order_date) FROM sales_cleaned)) AND s.region<>'-'
GROUP BY s.region,YEAR(sd.order_date),MONTH(sd.order_date)
ORDER BY Region,Sales_Year,Sales_Month;

--9. Identify the top 3 products with the highest return rate in each category. 
SELECT Category , Product_Name, Return_Rate FROM( 
SELECT  p.category AS Category, p.product_name AS Product_Name, 
CONCAT(ROUND(CAST(COUNT(r.order_id)*100.0/NULLIF(COUNT(sd.order_id),0) AS FLOAT),2),'%') AS Return_Rate ,
ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY COUNT(r.order_id)*100.0/NULLIF(COUNT(sd.order_id),0) DESC) AS RANK FROM products_cleaned p
JOIN sales_cleaned sd
ON sd.product_id=p.product_id
LEFT JOIN returns_cleaned r
ON r.order_id=sd.order_id
GROUP BY p.category , p.product_name
)t
WHERE RANK<=3


--10.. Which 5 customers have contributed the most to total profit, and what is their tenure with the company? 
SELECT TOP 5 CONCAT(c.first_name,' ',C.last_name) AS Customer_Name, ROUND(SUM(sd.profit),2) AS Profit ,
CAST(DATEDIFF(MONTH , c.signup_date , GETDATE()) AS VARCHAR(255))+' Months' AS "Tenure (in months)" FROM customers_cleaned c
JOIN sales_cleaned sd
ON sd.customer_id= c.customer_id
GROUP BY CONCAT(c.first_name,' ',C.last_name), c.customer_id, CAST(DATEDIFF(MONTH , c.signup_date , GETDATE()) AS VARCHAR(255))
ORDER BY Profit DESC
