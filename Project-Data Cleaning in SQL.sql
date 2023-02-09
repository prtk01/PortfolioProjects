

-- Loading data into the table

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/All_Order_Report.txt"
into table project
ignore 1 lines;



-- Findind duplicate rows


select amazon_order_id,product_name,sku,quantity from project
group by amazon_order_id, product_name,sku,quantity
Having count(amazon_order_id)>1


-- deleting the duplicate rows using an intermediate table


 create table project_temp
 like project;
 SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
insert into project_temp
 select * from project  group by amazon_order_id, product_name,sku,quantity;
 

drop table project;

alter table project_temp
rename to project;
select* from project
delete from project where amazon_order_id like ""




-- Removing unwanted and null columns(having sum of column==0)


Select sum(item_tax), sum(shipping_tax), sum(gift_wrap_price), sum(gift_wrap_tax), 
sum(price_designation), sum(vat_exclusive_giftwrap_price) from project ;

Alter table project
 drop item_tax, drop shipping_tax, drop gift_wrap_tax, drop price_designation,
  drop merchant_order_id, drop last_updated_date, drop fulfillment_channel, drop sales_channel, 
  drop order_channel, drop url, drop asin, drop item_status, drop currency, drop ship_postal_code, drop ship_country,
   drop purchase_order_number, drop fulfilled_by, drop buyer_company_name, 
  drop buyer_cst_number, drop buyer_vat_number, drop buyer_tax_registration_id, 
  drop buyer_tax_registration_country, drop buyer_tax_registration_type, drop customized_url, 
  drop is_iba;
  Alter table project
  drop item_extensions_data, drop customized_page, drop original_order_id, drop is_amazon_invoiced;
  
  
  
  -- Removing brand name for any issues
  
  
  select product_name, substring_index(product_name," ",0-(length(product_name)-length(replace(product_name," ","")))) 
  from project
  
  
  
  -- another menthod, replacing brand name with null value
  
  
  select replace(product_name,"Brand","") from project
  
SET SQL_SAFE_UPDATES = 0;
update project 
set product_name = substring_index(product_name," ",0-(length(product_name)-length(replace(product_name," ",""))))

select * from project 




-- Updating data types


alter table project 
modify column purchase_date date;

alter table project
modify column quantity int;


