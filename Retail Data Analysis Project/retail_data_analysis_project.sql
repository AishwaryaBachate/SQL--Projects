use retail_data_analysis;

--DATA PREPARATION AND UNDERSTANDING 

-- 1. What is the total number of rows in each of the 3 tables in the database?
select 'customers' as tablename,count(*) as count_of_rows from customers union 
select 'transactions',count(*) from transactions union 
select 'prod_cat_info', count(*) from prod_cat_info;

-- 2. What is the total number of transactions that have a return? 
select count(distinct(transaction_id)) as total_transactions 
from transactions 
where Qty < 0;

/* 3. As you would have noticed, the dates provided across the datasets are not in a 
correct format. As first steps, pls convert the date variables into valid date formats 
before proceeding ahead. */
select convert(date,tran_date,105) as transaction_dates 
from transactions;

/* 4. What is the time range of the transaction data available for analysis? Show the 
output in number of days, months and years simultaneously in different columns*/
select 
datediff(day, min(convert(date,tran_date,105)), max(convert(date,tran_date,105))) as numberofdays,
datediff(month, min(convert(date,tran_date,105)), max(convert(date,tran_date,105))) as numberofmonths,
datediff(year, min(convert(date,tran_date,105)), max(convert(date,tran_date,105))) as numberofyears
from transactions;


-- 5. Which product category does the sub-category �DIY� belong to?
select prod_cat
from prod_cat_info
where prod_subcat = 'DIY';


--DATA ANALYSIS

--1. Which channel is most frequently used for transactions? 
select top 1 store_type, count(*) as frequency
from transactions
group by store_type
order by frequency desc;

--2. What is the count of Male and Female customers in the database? 
select Gender, count(*) as count
from customers
where Gender in ('M', 'F')
group by Gender;

--3. From which city do we have the maximum number of customers and how many? 
select top 1 city_code, count(*) as num_of_customers
from customers
group by city_code
order by num_of_customers desc;


--4. How many sub-categories are there under the Books category? 
select count(distinct prod_subcat) as count
from prod_cat_info
where prod_cat = 'Books';


--5. What is the maximum quantity of products ever ordered? 
select max(qty) as max_quantity
from transactions;

--6. What is the net total revenue generated in categories Electronics and Books? 
select sum(total_amt) as total_revenue
from transactions where prod_cat_code in 
(select distinct(prod_cat_code)from prod_cat_info
where prod_cat in ('Electronics', 'Books'));


--7. How many customers have >10 transactions with us, excluding returns?
select count(*) as customer_count
from (select cust_id
from transactions
where Qty > 0
group by cust_id
having count(*) > 10
) as subquery;



--8. What is the combined revenue earned from the �Electronics� & �Clothing� categories, from �Flagship stores�? 
select sum(total_amt) as total_revenue
from transactions 
where prod_cat_code in 
(select distinct(prod_cat_code)
from prod_cat_info
where prod_cat in ('Electronics', 'Clothing'))
and Store_type= 'Flagship store';



/* 9. What is the total revenue generated from �Male� customers in �Electronics� 
      category? Output should display total revenue by prod sub-cat. */
select pci.prod_subcat, sum(t.total_amt) as total_revenue
from transactions as t 
join prod_cat_info as pci on pci.prod_cat_code = t.prod_cat_code and pci.prod_sub_cat_code = t.prod_subcat_code
join customers as c on c.customer_Id = t.cust_id
where c.Gender = 'M' and pci.prod_cat = 'Electronics'
group by prod_subcat;


/* 10.What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales? */
select tb1.prod_subcat, percentage_sales, percentage_returns 
from 
(
    select TOP 5 prod_subcat, 
    (sum(cast(total_amt as float))/
    (select sum(cast(total_amt as float)) as tot_sales from transactions where qty > 0)) as percentage_sales
    from prod_cat_info as pci
    join transactions as t
    ON pci.prod_cat_code = t.prod_cat_code and pci.prod_sub_cat_code = t.prod_subcat_code
    where qty > 0
    group by prod_subcat
    order by percentage_sales desc
) as tb1
join
(
    select prod_subcat, 
    (sum(cast(total_amt as float))/
    (select sum(cast(total_amt as float)) as tot_sales from transactions where qty < 0)) as percentage_returns
    from prod_cat_info as pci
    join transactions as t
    ON pci.prod_cat_code = t.prod_cat_code and pci.prod_sub_cat_code = t.prod_subcat_code
    where qty < 0
    group by prod_subcat
) as tb2
ON tb1.prod_subcat = tb2.prod_subcat;




/* 11. For all customers aged between 25 to 35 years find what is the net total revenue 
generated by these consumers in last 30 days of transactions from max transaction 
date available in the data? */
select tb3.cust_id,age,revenue,tran_date from 
(
    select * from 
    (
        select cust_id, datediff(year, dob, max_date) as age, revenue from
        (
            select cust_id, dob, max(convert(date, tran_date, 105)) as max_date, sum(cast(total_amt as float)) as revenue 
			from customers as t1
            join transactions as t2 on t1.customer_id = t2.cust_id
            where Qty > 0
            group by cust_id, DOB
        ) as tb1
    ) as tb2
    where age between 25 and 35
) as tb3
join
(
    select cust_id, convert(date, tran_date, 105) as tran_date
    from transactions
    group by cust_id, convert(date, tran_date, 105)
    having 
    convert(date, tran_date, 105) >= (select dateadd(day, -30, max(convert(date, tran_date, 105))) as cutoff_date from transactions)
) as tb4
on tb3.cust_id = tb4.cust_id;



--12.Which product category has seen the max value of returns in the last 3 months of transactions? 
select top 1 prod_cat_code, sum(returns) as total_returns 
from 
(
    select prod_cat_code, convert(date, tran_date, 105) as tran_date, sum(Qty) as returns
    from transactions
    where Qty < 0
    group by prod_cat_code, convert(date, tran_date, 105)
    having convert(date, tran_date, 105) >= 
    (select dateadd(MONTH, -3, max(convert(date, tran_date, 105))) as cutoff_date from transactions)
) as A
group by prod_cat_code
order by total_returns;


--13.Which store-type sells the maximum products; by value of sales amount and by quantity sold?
select store_type, sum(cast(total_amt as float)) as revenue, sum(Qty) as total_quantity
from transactions
where Qty > 0
group by store_type
order by revenue desc, total_quantity desc;



--14.What are the categories for which average revenue is above the overall average.
select prod_cat_code, avg(cast(total_amt as float)) as avg_revenue 
from transactions
where Qty > 0 
group by prod_cat_code
having 
avg(cast(total_amt as float)) >= (select avg(cast(total_amt as float)) from transactions where Qty > 0);



/* 15. Find the average and total revenue by each subcategory for the categories which 
are among top 5 categories in terms of quantity sold.*/
select prod_subcat_code, sum(cast(total_amt as float)) as revenue, avg(cast(total_amt as float)) as avg_revenue
from transactions
where Qty > 0 and prod_cat_code in (
    select top 5 prod_cat_code 
    from transactions
    where Qty > 0
    group by prod_cat_code
    order by sum(Qty) desc
)
group by prod_subcat_code;