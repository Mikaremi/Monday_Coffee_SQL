-- monday coffee data analysis
select * from city;
select * from products;
select * from customers;
select * from sales;

-- reports and data analysis
-- q1 coffee consumers count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select 
	city_name,
	population * 0.25 as coffee_cosumers,
	city_rank
from city
order by  population desc;


-- q2 Total revenue from coffee sales
-- What is the total revenue generated from coffee sales accross all cities in the last quarter of 2023?

select
	ci.city_name,
	sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id 
join city as ci 
on ci.city_id  = c.city_id 
where 
	year(s.sale_date) = 2023
	and 
	quarter(s.sale_date) = 4 
group by ci.city_name 
order by total_revenue desc;

-- q.3 Sales count for each product
-- How many unit of each coffee product have been sold?

select 
	p.product_name,
	count(s.sale_id) as total_orders
from products as p
left join
sales as s 
on s.product_id = p.product_id
group by p.product_name
order by total_orders desc;

-- q.4 Average sales amount per city
-- what is the average sales amount per customer in each city
-- city and total sales
-- number of customers in each of the cities

select
	ci.city_name,
	sum(s.total) as total_revenue,
	count(distinct s.customer_id) as total_customers,
	round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_customer
from sales as s
join customers as c
on s.customer_id = c.customer_id 
join city as ci 
on ci.city_id  = c.city_id 
group by ci.city_name 
order by total_revenue desc;

-- q.5 City population and the coffee consumers
-- provide a list of cities along with their population and estimated coffee consumers
-- return city_name, total current consumers, estimated coffee consumers (25%)

WITH city_table AS (
    SELECT 
        city_name,
        ROUND((population * 0.25), 2) AS coffee_consumers
    FROM city
),
customers_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales AS s
    JOIN customers AS c ON c.customer_id = s.customer_id
    JOIN city AS ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
-- Now you can select from both subqueries:
SELECT 
    ct.city_name,
    ct.coffee_consumers,
    cust.unique_customers
FROM city_table AS ct
JOIN customers_table AS cust
ON ct.city_name = cust.city_name;

-- q.6 Top selling product by city
-- what  are the top 3 selling product in each city based in the sales volume?
SELECT * 
FROM 
(
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) AS `rank`
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) AS t1
WHERE `rank` <= 3;


-- customer segmentation by city
-- how many unique customers are there in each city who have purchased coffee products?

-- select * from products

select 
	ci.city_name,
	count(distinct c.customer_id) as unique_customers
from city as ci
left join
customers as c
on c.city_id  = ci.city_id 
join sales as s
on s.customer_id = c.customer_id
where 
	s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ci.city_name; 


-- q.8 Average sale vs rent
-- find each city and their average sale per customer and average rent per customer
-- conclusions

with city_table
as 
(select
	ci.city_name,
	count(distinct s.customer_id) as total_customers,
	round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_customer
from sales as s
join customers as c
on s.customer_id = c.customer_id 
join city as ci 
on ci.city_id  = c.city_id 
group by ci.city_name 
order by total_customers desc
),
city_rent
as
(select city_name, estimated_rent
from city
)
select 
	cr.city_name,
	cr.estimated_rent,
	ct.total_customers,
	ct.avg_sale_per_customer,
	round(cr.estimated_rent/ct.total_customers, 2) as avg_rent
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by avg_rent desc;

-- q.9 Monthly sales growth
-- sales growth rate: calculate the percentage growth(or decline) in sales over different time periods (monthly)
-- by each city
WITH monthly_sales AS (
    SELECT
        ci.city_name,
        MONTH(s.sale_date) AS Month,
        YEAR(s.sale_date) AS year,
        SUM(s.total) AS total_sales
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, Month, year
    ORDER BY ci.city_name, year, Month
),
growth_ratio
as
(SELECT 
    city_name,
    Month,
    year,
    total_sales AS cr_month_sale,
    lag (total_sales, 1) over(partition by city_name order by year, month) as last_month_sale
FROM monthly_sales
)
select 
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	round((cr_month_sale-last_month_sale)/last_month_sale*100,2) as growth_ratio
from growth_ratio
where last_month_sale is not null 


-- q.10. Market potential analysis
-- identify the top 3 city based on highest sales, return city name, total sale, total rent, total customers, etimated coffee consumers

with city_table
as 
(select
	ci.city_name,
	sum(s.total) as total_revenue,
	count(distinct s.customer_id) as total_customers,
	round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_customer
from sales as s
join customers as c
on s.customer_id = c.customer_id 
join city as ci 
on ci.city_id  = c.city_id 
group by ci.city_name 
order by total_revenue desc
),
city_rent
as
(select 
	city_name, 
	estimated_rent,
	population * 0.25 as estimated_coffee_consumers
from city
)
select 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customers,
	estimated_coffee_consumers,
	ct.avg_sale_per_customer,
	round(cr.estimated_rent/ct.total_customers, 2) as avg_rent
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by total_revenue desc;
 
/*

-- Recomendations.
-- City 1: Pune
1. Average rent per customer is very less 
2. highest total reveune 
3. average sale per customer is also high

-- City 2: Delhi
1. highest estimated coffee consumers which is 7,750,000
2. highest total customers is 68 customers
3. average rent  per customer is 330 that is still less that 500

-- City 3: Jaipur
1. Highest number of customers i.e, 69
2. average rent per customer is very less that 156
3. average sale per customer is better which is at 11.6k















