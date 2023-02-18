/*
Amazon Orders Data and Settlement Report Exploration 
Skills used: Joins, CTE's, Windows Functions, Aggregate Functions, Case, Converting Data Types
*/


select* from orders;

-- Total orders, Total orders value

select count(distinct(amazon_order_id)), sum(item_price) from orders

-- Location based total orders and total order value

select ship_state,ship_city, count(amazon_order_id) as total_orders, sum(item_price) as total_value from orders
group by ship_state,ship_city
 order by total_orders desc

-- creating a cte to get ranks for each state and city based on total orders

with cte as (
select ship_state,ship_city, count(amazon_order_id) as total_orders, 
row_number() over (order by count(amazon_order_id) desc) as row_num 
from orders
group by ship_state,ship_city
)
 select ship_state, ship_city, row_num from cte
 where row_num between 1 and 10

-- creating a cte to get ranks for each city in state based on total order value

with cte_city as (
select ship_state,ship_city,
 sum(item_price) as total_value,
row_number() over (partition by ship_state order by sum(item_price) desc) as row_num 
from orders
group by ship_state,ship_city
)
 select ship_state, ship_city, row_num from cte_city
 where row_num between 1 and 10 and ship_state ='MAHARASHTRA'

 
-- Percentage of total orders shipped vs cancelled

select order_status, 
count(order_status) as total_orders,
 (count(order_status)/(select count(amazon_order_id) from orders)*100) as Percent 
 from orders
group by order_status


-- Percentage of shipped order choosing expedited ship service

select ship_service_level, count(ship_service_level),
 (count(ship_service_level)/(select count(amazon_order_id) from orders)*100) as Percent
 from orders
 where ship_service_level like 'exp%'
group by ship_service_level


-- checking if there is any data for cancelled orders


SELECT order_status,sku, item_price,vat_exclusive_item_price,
 vat_exclusive_shipping_price from orders
where item_price!="" and 
item_price!=vat_exclusive_item_price and
 order_status="Cancelled"

-- checking data in Mapper table
select sku, category,  mrp, cogs, Tax_Rate from Mapper


-- Total Orders and value based on product name and product category

select o.product_name, m.category,
 count(o.amazon_order_id) as total_orders ,
 sum(item_price) as total_value
 from orders as o
join mapper as m on o.sku=m.sku
group by o.product_name, m.category
order by total_orders desc

-- By Category and sku, group by location

select o.ship_state,o.sku, m.category,
count(o.amazon_order_id) as total_orders ,
 sum(item_price) as total_value
 from orders as o
join mapper as m on o.sku=m.sku
group by o.ship_state,o.sku, m.category
order by total_value desc

-- Different amount categories data in settlement report

select price_type, sum(price_amount) from settlement  -- sho
where price_type!=""
group by price_type -- showing principal amt., tax, TCS, shipping, shipping tax, goodwill


select item_related_fee_type, sum(item_related_fee_amount) from settlement 
where item_related_fee_type!=""
group by 1  -- showing hangling fee, tech fee, commission, closing gee, packing fee, gift wrap fee


select promotion_type, sum(promotion_amount) from settlement 
where promotion_type!=""
group by 1  -- showing promo rebates, tax discount, shipping discount, shipping tax discount


-- Calculating total settlement value  from settlement report


select order_id, sku, 
total_price, total_fee, total_discount, total_misc,
(total_price+total_fee+total_discount+total_misc) as net_amt 
from
(
select order_id,sku, sum(price_amount) as total_price, 
sum(item_related_fee_amount) as total_fee,
sum(promotion_amount) as total_discount, 
sum(other_amount) as total_misc
  from settlement
group by 1,2
)
as subquery -- net_amt is total value after summation of prices, taxes and discounts. Data like tax was already a negative number

-- creating a table from above query to be used in calculations further

Create table settle
( order_id nvarchar(255),
sku nvarchar(255),
total_price double,
total_fee double,
total_discount double,
total_misc double,
net_amt double
)

insert into settle
select order_id, sku, 
total_price, total_fee, total_discount, total_misc,
(total_price+total_fee+total_discount+total_misc) as net_amt 
from
(
select order_id,sku, sum(price_amount) as total_price, 
sum(item_related_fee_amount) as total_fee,
sum(promotion_amount) as total_discount, 
sum(other_amount) as total_misc
  from settlement
group by 1,2
)
as subquery

select * from settle



-- joining the 3 tables to calculate net sales and profit for a order and different products, sku and category


Select orders.amazon_order_id, orders.sku,orders.quantity,Round(orders.item_price,2),
 orders.item_promotion_discount, orders.shipping_price,
settle.total_price, settle.total_discount, Round(settle.net_amt,2),
mapper.category, mapper.mrp,mapper.cogs, mapper.tax_rate,
Case 
	when item_price > net_amt then "Loss"
    else "Profit"
 End   as Profit_Loss
from orders
join settle on orders.amazon_order_id=settle.order_id
join mapper on orders.sku=mapper.sku 




