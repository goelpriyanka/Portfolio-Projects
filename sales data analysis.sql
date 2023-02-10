-- Creating database--
create database DB_Sales_Analysis;

--------------------------------------------------------------------------------------------------------------------------------------------
-- using database--
use DB_Sales_Analysis
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- Looking at the data we are going to use---
select * from sales_data_sample
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- checking the dimension of the data ----

SELECT count(*) as Dims
FROM [INFORMATION_SCHEMA].[COLUMNS]
WHERE table_name = 'sales_data_sample'
union
select count(*) from sales_data_sample
;
--------------------------------------------------------------------------------------------------------------------------------------------
--- checking distinct values ----

select distinct status from sales_data_sample;		-- Resolved, On Hold, Cancelled, Shipped, Disputed, In Process
select distinct YEAR_ID from sales_data_sample;		-- 2003,2004, 2005
select distinct COUNTRY from sales_data_sample;
select distinct PRODUCTLINE from sales_data_sample;	-- Trains,Motorcycles,Ships,Trucks and Buses,Vintage Cars,Classic Cars,Planes
select distinct DEALSIZE from sales_data_sample;	-- Small, Medium, Large
select distinct TERRITORY from sales_data_sample;	-- EMEA,APAC, Japan, NA
--------------------------------------------------------------------------------------------------------------------------------------------
-- which product line has the highest sales--
select * from sales_data_sample
;
--------------------------------------------------------------------------------------------------------------------------------------------
select SUM(SALES) Revenue, PRODUCTLINE from sales_data_sample
group by PRODUCTLINE
order by 1 desc
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- which year has the highest sales--
select  YEAR_ID, SUM(SALES) Revenue from sales_data_sample
group by YEAR_ID
order by 2 desc
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- They have very less sales in 2005, lets findout why? Ans. They operated only for 5 months in 2005

select  distinct MONTH_ID from sales_data_sample
where YEAR_ID = 2005
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- which deal size has more sales--
select  DEALSIZE, SUM(SALES) Revenue from sales_data_sample
group by DEALSIZE
order by 2 desc
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- max sales in a specific year--
with sum_of_sales as
(select   MONTH_ID, SUM(SALES) Revenue,YEAR_ID from sales_data_sample
group by  MONTH_ID,YEAR_ID 
)

select MAX(Revenue), YEAR_ID from sum_of_sales
group by YEAR_ID
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- best month for sale in a specific year
select MONTH_ID, SUM(SALES)as Revenue, COUNT(ORDERNUMBER) as Frequency 
from sales_data_sample
where YEAR_ID = 2003
group by MONTH_ID
order by Revenue desc
;

--November seems to be the Best month for sales, now lets see which product is sold maximum 
	-- in 2003  and 2004 Calssic cars were sold more 

select MONTH_ID,  PRODUCTLINE,SUM(SALES)as Revenue, COUNT(ORDERNUMBER) as Frequency 
from sales_data_sample
where YEAR_ID = 2004 and MONTH_ID = 11
group by MONTH_ID, PRODUCTLINE
order by Revenue desc
;
--------------------------------------------------------------------------------------------------------------------------------------------
-- who is our best customer (RFM analysis)

drop table if exists #RFM_Analysis;
with RFM as 
(
	select CUSTOMERNAME, 
		SUM(SALES) as Sales, 
		AVG(SALES) as avg_Sales, 
		count(ORDERNUMBER) as Frequency,
		MAX(ORDERDATE) as last_order_date_BY_Customer, 
		(select MAX(ORDERDATE) from sales_data_sample) as Max_order_date_in_data,
		DATEDIFF(dd, MAX(ORDERDATE), (select MAX(ORDERDATE) from sales_data_sample)) as Recency
	from sales_data_sample
	group by CUSTOMERNAME
),
RFM_Calculation as 
(
	select R.*, 
		ntile(4) over(order by Recency desc) RFM_Recency,
		ntile(4) over(order by Frequency) RFM_Frequency,
		ntile(4) over(order by Sales) RFM_Monetary
	from RFM R 
)
select RC.*,
	(RFM_Recency+RFM_Frequency+RFM_Monetary) as RFM_Score,
	(cast(RFM_Recency as varchar)+cast(RFM_Frequency as varchar)+cast(RFM_Monetary as varchar)) as RFM_string_value
into #RFM_Analysis
from RFM_Calculation RC
;

select CUSTOMERNAME, Sales, RFM_Recency, RFM_Frequency, RFM_Monetary ,
	case 
		when RFM_string_value in (111,112,113,114,121,122,123,124, 131,132, 141,142, 221, 222) then 'Lost Customers'
		when RFM_string_value in (133, 134, 211, 212, 344, 244,144, 234, 233, 223, 232) then 'About to Loose Customers'
		when RFM_string_value in (411,412, 413, 414 ,311,312, 322,332) then 'New Customers'
		when RFM_string_value in (421,422,423,431,432,434,441,442,443,444, 433, 333,343) then 'Loyal Customers'
	end as customer_categ
from #RFM_Analysis
--------------------------------------------------------------------------------------------------------------------------------------------
