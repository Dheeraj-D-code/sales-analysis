use dbase;

select * from df_orders;
 
-- 1. Sales and Profit Analysis

-- 1.1 find the top 5 cities by total sales.
select 
	city,
    sum(quantity) as total_sales
from df_orders
group by city
order by total_Sales desc
limit 5;


-- 1.2 What is the most profitable region?
select 
	region,
    sum(profit) as total_profit
from df_orders
group by region
order by total_profit desc
limit 1;


-- 1.3 find top 10 highest reveue generating products 
select product_id, sum(sale_price) as sales
from df_orders
group by product_id
order by sales desc
limit 10;


-- 1.4 find top 5 highest selling products in each region
WITH cte AS (
    SELECT 
        region, 
        product_id,
        SUM(sale_price) AS sales,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY SUM(sale_price) DESC) AS rn
    FROM df_orders
    GROUP BY region, product_id
)
SELECT 
    region, 
    product_id,
    sales
FROM cte
WHERE rn <= 5;


-- 1.5 Which product has the highest profit margin? (Profit Margin = Profit / Sale Price)
select 
	product_id,
    profit,
    sale_price,
    sum(profit)/sum(sale_price) as profit_margin
from df_orders
group by product_id, 
	profit,
	sale_price
order by profit_margin desc
limit 1;


-- 1.6 What is the total sales and profit for each category and sub-category?
select 
	category,
    sub_category,
    sum(sale_price) as total_sales,
    sum(profit) as total_profit
from df_orders
group by category, 
	sub_category
order by category, total_sales desc;


-- 1.7 Which products were sold at the highest quantity, and in which regions?
select 
	product_id,
	region,
	sum(quantity) as order_quantity
from df_orders
group by product_id, region
order by order_quantity desc
limit 10;		
  
  

-- 2. Trend Analysis

-- 2.1 What is the monthly sales trend for the past two years? (Group by YEAR(order_date) and MONTH(order_date)).
select 
    month(order_date) as order_month,
    year(order_date) as order_year,
    sum(sale_price) as total_sales
from df_orders
group by order_year, order_month
order by  order_year;


-- 2.2 	Which quarter has the highest sales in each year?
select 
	year(order_date) as order_year,
	quarter(order_date) as order_quarters,
    sum(sale_price) as total_sales
from df_orders
group by order_year,order_quarters
order by order_year,total_sales desc
limit 1;


-- 2.3 for each category which month had highest sales
with cte as (
	select category,
		date_format(order_date,'%Y-%M') as order_year_month, 
		sum(sale_price) as sales 
	from df_orders
	group by category,order_year_month
	order by category,order_year_month
)
	select * from(
	select *,
	row_number() over(partition by category order by sales desc) as rn
	from cte
) subquery	
where rn=1;


-- 3. Shipping and Delivery Patterns:

-- 3.1 What is the most frequently used shipping mode for high-profit orders?(let high-profit be 200)
select 
	ship_mode,
	count(*) as usage_count
from df_orders
where profit >= 200
group by ship_mode
order by usage_count desc;


-- 3.2 Find the average order quantity for each shipping mode
select 
	COALESCE(ship_mode, 'Unknown') AS ship_mode,
    avg(quantity) as average_order_quantity
from df_orders
group by ship_mode
order by average_order_quantity;



-- 4. Year-over-Year Growth:

-- 4.1 find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
SELECT 
    MONTH(order_date) AS order_month,
    SUM(CASE WHEN YEAR(order_date) = 2022 THEN sale_price ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN YEAR(order_date) = 2023 THEN sale_price ELSE 0 END) AS sales_2023
FROM df_orders
GROUP BY order_month
ORDER BY order_month;


-- 4.2 Compare the total sales and profit for each category between 2022 and 2023.
with cte as ( 
	select
		category,
        year(order_date) as order_year,
		count(*) as total_sales,
        sum(profit) as total_profit
	from df_orders
    group by category, order_year
),
cte2 as (
	select
		category,
        sum(case when order_year = 2022 then total_sales else 0 end) as total_sales_2022,
        sum(case when order_year = 2023 then total_sales else 0 end) as total_sales_2023,
        sum(case when order_year = 2022 then total_profit else 0 end) as total_profit_2022,
        sum(case when order_year = 2023 then total_profit else 0 end) as total_profit_2023
	from cte
    group by category
)
select 
	category,
    total_sales_2022,
    total_sales_2023,
    total_profit_2022,
    total_profit_2023
from cte2
order by category;
    
    
-- 4.3 Which region has shown the highest growth in profit from 2022 to 2023?
with cte as(
	select
		region,
		year(order_date) as order_year,
		sum(profit) as total_profit
	from df_orders
	group by region, order_year
),
cte2 as(
	select 
		region,
		sum(case when order_year = 2022 then total_profit else 0 end) as profit_2022,
		sum(case when order_year = 2023 then total_profit else 0 end) as profit_2023
	from cte
    group by region
)
select 
	region,
    profit_2022,
    profit_2023,
case
	when profit_2022 > 0 then (profit_2023 - profit_2022)*100 / profit_2022
    else null
    end as profit_growth
from cte2
order by profit_growth desc
limit 5;