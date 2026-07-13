/*
============================================================================================================
Product Report

============================================================================================================

Purpose:
- This report consolidates key product metrics and behaviors. 

Highlights:
	1. Gathers essential fields susch as product name, category, subcategory, and cost.
	2. Segments products by revenue to identify High-performers, Mid-Range, or Low Performers.
	3. Aggregates product-level metrics:
		- total orders 
		- total sales
		- total quantity sold 
		- total customers (unique)
		- lifespan (in months)
	4. Calculates valuable KPIs:
		- recency(months since last sale)
		- average order revenue (AOR)
		- average monthly revenue

============================================================================================================
*/


/*
--------------------------------------------------------------------------------------------
1) Base Query: Retrives core columns from tables
--------------------------------------------------------------------------------------------
*/

--CREATE VIEW gold.report_products AS

WITH base_query AS (
	SELECT
	p.product_key,
	f.order_number,
	f.customer_key,
	f.order_date,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost,
	f.quantity,
	f.sales_amount

	--SELECT *
	FROM gold.fact_sales f
	LEFT JOIN gold.dim_products p
	ON f.product_key = p.product_key
	WHERE order_date IS NOT NULL -- Consider only valid date oreders
),

product_aggregation AS (
/*
--------------------------------------------------------------------------------------------
2) Products Aggregations: Summarizes key metrerics at the product level
--------------------------------------------------------------------------------------------
*/

	SELECT 
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	DATEDIFF(month, MIN(order_date),MAX(order_date)) AS lifespan,
	MAX(order_date) AS last_sale_date,
	COUNT(DISTINCT order_number) AS total_orders,
	COUNT(DISTINCT customer_key) AS total_customers,
	SUM(sales_amount) AS total_sales,
	SUM(quantity) AS total_qty,
	ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity,0)),1) AS  avg_selling_price

	FROM base_query
	GROUP BY 
	product_key,
	product_name,
	category,
	subcategory,
	cost
	)

/*
--------------------------------------------------------------------------------------------
3) products KPIs: Summarization KPIs
--------------------------------------------------------------------------------------------
*/

SELECT 
product_key,
product_name,
category,
subcategory,
cost,
lifespan,
last_sale_date,
DATEDIFF(MONTH, last_sale_date,GETDATE()) AS recency_in_months,
CASE 
	WHEN total_sales > 50000 THEN 'High-performer'
	WHEN total_sales >= 10000 THEN 'Mid-performer'
	ELSE 'Low-performer'
END AS product_segment,
total_orders,
total_customers,
total_sales,
total_qty,
avg_selling_price,

--average order revenue (AOR)
CASE 
	WHEN total_orders = 0 THEN 0
	ELSE total_sales / total_orders
END AS avg_order_revenue,

--Average Monthly Revenue

CASE 
	WHEN lifespan = 0 THEN total_sales
	ELSE total_sales / lifespan
END AS avg_monthly_revenue
FROM product_aggregation

