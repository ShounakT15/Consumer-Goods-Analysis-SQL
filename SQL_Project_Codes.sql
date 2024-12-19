#1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 
SELECT 
	market
FROM dim_customer
WHERE customer = "Atliq Exclusive"
AND region IN ('APAC')
;
  
  
#2. What is the percentage of unique product increase in 2021 vs. 2020? 
#   The final output contains these fields: unique_products_2020, unique_products_2021, percentage_chg
WITH cte1 AS (
	SELECT
		count(distinct product_code) as unique_products_2020
	FROM gdb0041.fact_sales_monthly
	WHERE fiscal_year = 2020
),
 cte2 AS ( 
	SELECT
		count(distinct product_code) as unique_products_2021
	FROM gdb0041.fact_sales_monthly
	WHERE fiscal_year = 2021
)
SELECT 
	c1.unique_products_2020, c2.unique_products_2021,
    ROUND((c2.unique_products_2021 - c1.unique_products_2020)/c1.unique_products_2020 * 100,2) as percentage_chg
FROM cte1 c1
JOIN cte2  c2
;

#3. Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts. 
#   The final output contains 2 fields-  segment, product_count
SELECT 
	segment, COUNT(DISTINCT product_code) AS product_count
FROM gdb0041.dim_product
GROUP BY segment
ORDER BY product_count DESC
;

#4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
#   The final output contains these fields -  segment, product_count_2020, product_count_2021, difference 
WITH cte1 AS (
	SELECT 
		p.segment, COUNT(DISTINCT p.product_code) AS product_count, s.fiscal_year
	FROM dim_product p
    JOIN fact_sales_monthly s 
    ON p.product_code = s.product_code
	GROUP BY p.segment, s.fiscal_year
)
SELECT 
	c20.segment, c20.product_count AS product_count_2020, c21.product_count AS product_count_2021,
    c21.product_count - c20.product_count AS difference
FROM cte1 as c20
JOIN cte1 as c21 
ON c20.segment = c21.segment
AND c20.fiscal_year = 2020
AND c21.fiscal_year = 2021
ORDER BY difference DESC
;

#5.  Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields- 
#    product_code, product, manufacturing_cost
SELECT 
	p.product_code, p.product, m.manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p
ON m.product_code = p.product_code
WHERE
	m.manufacturing_cost IN (
							SELECT MAX(manufacturing_cost) from fact_manufacturing_cost 
							UNION 
                            SELECT MIN(manufacturing_cost) from fact_manufacturing_cost
                            )
ORDER BY m.manufacturing_cost DESC
;

#6.  Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  
#	 for the  fiscal  year 2021  and in the Indian  market. The final output contains these fields- 
#    customer_code, customer, average_discount_percentage 
SELECT
	pre.customer_code, c.customer, 
    ROUND(AVG(pre.pre_invoice_discount_pct),2) as average_discount_percentage
FROM fact_pre_invoice_deductions pre
JOIN dim_customer c
ON pre.customer_code = c.customer_code
WHERE pre.fiscal_year = 2021
AND market IN ('India')
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5
;

#7.  Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month  .
#    This analysis helps to  get an idea of low and high-performing months and take strategic decisions. 
#    The final report contains these columns: Month, Year, Gross sales Amount 
SELECT 
		YEAR(date) as Year, MONTH(date) as month,
		ROUND(sum(sold_quantity * gross_price),2) AS gross_sales_amount
FROM fact_sales_monthly as fs
JOIN fact_gross_price as fp
ON fs.product_code = fp.product_code and fs.fiscal_year = fp.fiscal_year
INNER JOIN dim_customer as dc
ON fs.customer_code = dc.customer_code
WHERE customer = "Atliq Exclusive"
GROUP BY month, YEAR(date)
ORDER BY Year, month
;

#8.  In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity:
#    Quarter,  total_sold_quantity
SELECT 
	CASE
		WHEN MONTH(date) BETWEEN 9 AND 11 THEN 'Q1'
        WHEN MONTH(date) BETWEEN 12 AND 2 THEN 'Q2'
        WHEN MONTH(date) BETWEEN 3 AND 5 THEN 'Q3'
        WHEN MONTH(date) BETWEEN 6 AND 8 THEN 'Q4'
	END AS Quarter ,
	SUM(sold_quantity) as total_sold_quantity 
FROM fact_sales_monthly 
WHERE fiscal_year = 2020
GROUP BY QUARTER
ORDER BY total_sold_quantity DESC
;

#9.  Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?  
#    The final output  contains these fields: channel, gross_sales_mln, percentage
WITH cte1 as( 
	SELECT
		c.channel,
		ROUND(SUM(s.sold_quantity * g.gross_price)/1000000,2) AS gross_sales_mln
	FROM dim_customer c
	JOIN fact_sales_monthly s
	ON c.customer_code = s.customer_code
	JOIN fact_gross_price g
	ON s.product_code = g.product_code
	where s.fiscal_year = 2021
	GROUP BY c.channel
	ORDER BY gross_sales_mln DESC
)
SELECT 
	* ,
    ROUND(gross_sales_mln*100/(SELECT SUM(gross_sales_mln) FROM cte1),2) AS percentage
FROM cte1
;

#10.  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
#     The final output contains these fields: division, product_code
WITH cte1 AS (
    SELECT
		p.division, s.product_code, SUM(s.sold_quantity) AS total_sold_quantity,
		rank() OVER (partition by p.division order by sum(s.sold_quantity) DESC) AS rnk
 FROM fact_sales_monthly s
 JOIN dim_product p
 ON s.product_code = p.product_code
 WHERE s.fiscal_year = 2021
 GROUP BY product_code
)
SELECT 
	division, product_code, rnk
FROM cte1
WHERE rnk IN (1,2,3)
;