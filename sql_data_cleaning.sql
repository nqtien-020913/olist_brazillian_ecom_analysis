-- DATA CLEANING

-- DATA TYPES AND DUPLICATES CHECK
DECLARE @table_name NVARCHAR(MAX) = 'orders'; -- khai báo bảng
DECLARE @sql NVARCHAR(MAX) = ''; -- khai báo lệnh
DECLARE @column_name NVARCHAR(MAX); -- khai báo cột
-- Tạo câu lệnh cho từng cột
SELECT @sql = @sql + '
SELECT 
    ''' + COLUMN_NAME + ''' AS Column_Name,
    ''' + DATA_TYPE + ''' AS Data_Type,
    COUNT(*) AS Total_Rows,
    COUNT([' + COLUMN_NAME + ']) AS Non_NULLs,
    COUNT(*) - COUNT([' + COLUMN_NAME + ']) AS NULLs,
    CAST(100.0 * (COUNT(*) - COUNT([' + COLUMN_NAME + '])) / COUNT(*) AS DECIMAL(5,2)) AS NULL_Percent
FROM ' + QUOTENAME(@table_name) + '
UNION ALL
'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @table_name;
SET @sql = LEFT(@sql, LEN(@sql) - 10); -- Xóa UNION ALL cuối cùng
EXEC sp_executesql @sql; -- Thực thi lệnh động

-- DUPLICATE_CHECK
-- Bước 1: khai báo biến
DECLARE @table_name NVARCHAR(MAX) = 'geolocation';  -- Tên bảng của em
DECLARE @key_columns NVARCHAR(MAX) = 'geolocation_zip_code_prefix, geolocation_city, geolocation_state'; -- Cột hoặc tổ hợp cột dùng làm khóa chính
-- Bước 2: tạo chuỗi Concat cho các cột (Nếu Primary Key nhiều hơn 1)
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @cols_concat NVARCHAR(MAX) = '';
-- Tạo phần CONCAT nếu là nhiều cột
SELECT @cols_concat = STRING_AGG('ISNULL(CAST(' + LTRIM(RTRIM(value)) + ' AS NVARCHAR(MAX)), '''')', ' + ''|'' + ')
FROM STRING_SPLIT(@key_columns, ',');
-- Bước 3: Tạo lệnh động
SET @sql = '
SELECT 
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT ' + @cols_concat + ') AS Unique_Key_Combinations,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT ' + @cols_concat + ')
        THEN ''UNIQUE''
        ELSE ''DUPLICATE EXISTS''
    END AS Key_Uniqueness_Status
FROM ' + QUOTENAME(@table_name) + ';';
-- Bước 4: chạy lệnh động
EXEC sp_executesql @sql;

-- II/. Xử lý NULL

-- 1/. Bảng orders

-- Xem trạng thái NULL của order_approved_at

select order_status
from orders
where order_approved_at is null
group by order_status;

select * -- xem xét delivered sâu hơn
from orders
where order_approved_at is null
    and order_status = 'delivered';


select format(order_purchase_timestamp, 'yyyy-MM') as year_month
    , avg(datediff(hour, order_purchase_timestamp, order_approved_at)) as avg_approve_hour
from orders
where order_approved_at is not null
group by format(order_purchase_timestamp, 'yyyy-MM')
order by year_month;


with table_status AS (
    select *
        , format(order_purchase_timestamp, 'yyyy-MM') as year_month
        , case 
            when order_delivered_customer_date < order_estimated_delivery_date then 'ontime'
            else 'late'
        end as delivery_status
    from orders
    where order_delivered_customer_date is not null
)
select delivery_status
    , avg(datediff(hour, order_purchase_timestamp, order_approved_at)) as avg_approve_hour
from table_status
group by delivery_status;


-- Xử lý dòng NULL

select *
Into orders_backup -- Tạo bảng back-up
From orders;

with table_relace AS (
    select format(order_purchase_timestamp, 'yyyy-MM') as year_month
        , avg(datediff(hour, order_purchase_timestamp, order_approved_at)) as avg_approve_hour
    from orders
    where order_approved_at is not null
    group by format(order_purchase_timestamp, 'yyyy-MM')
)
UPDATE orders
SET 
    order_approved_at = case 
                            when format(order_purchase_timestamp, 'yyyy-MM') = '2017-01' 
                                then dateadd(hour,(select avg_approve_hour from table_relace where year_month = '2017-01'),order_purchase_timestamp)
                            when format(order_purchase_timestamp, 'yyyy-MM') = '2017-02' 
                                then dateadd(hour,(select avg_approve_hour from table_relace where year_month = '2017-02'),order_purchase_timestamp)
                            end
WHERE order_approved_at is null
    and order_status = 'delivered';

-- Xem trạng thái NULL của order_delivered_carrier_date:
select orders
    , count(*) n_orders
from orders_backup
where order_delivered_carrier_date is null
group by order_status;

select *
from orders
where order_delivered_carrier_date is null
    and order_id = 'delivered';

-- Xử lý dòng NULL
update orders
Set order_status = 'canceled'
where order_delivered_carrier_date is null
    and order_status = 'delivered'
    and order_delivered_customer_date is null;


with table_relace AS (
    select format(order_purchase_timestamp, 'yyyy-MM-dd') as purchase_date
        , avg(datediff(hour, order_approved_at, order_delivered_carrier_date)) as avg_carrier_hour
    from orders
    where order_delivered_carrier_date is not null
    group by format(order_purchase_timestamp, 'yyyy-MM-dd')
)
UPDATE orders
SET 
    order_delivered_carrier_date = dateadd(hour,(select avg_carrier_hour from table_relace where purchase_date = '2017-09-29'), order_approved_at)
WHERE order_delivered_carrier_date is null
    and order_status = 'delivered';


-- Xem trạng thái NULL của order_delivered_carrier_date:
select order_status
    , count(*) n_orders
from orders
where order_delivered_carrier_date is null
group by order_status;

-- 2/. Bảng order_reviews
select *
from order_reviews;

-- creating order_reviews_backup
Select *
INTO order_reviews_backup
from order_reviews;

UPDATE order_reviews
SET
    review_comment_title = case
                            when (review_comment_title is null) and (review_comment_message is null) then 'just score'
                            when (review_comment_title is null) and (review_comment_message is not null) then 'non review title'
                            else review_comment_title
                        end,
    review_comment_message = case
                            when (review_comment_title is null) and (review_comment_message is null) then 'just score'
                            when (review_comment_title is not null) and (review_comment_message is null) then 'non review message'
                            else review_comment_message
                        end;

with table_valid AS (
    SELECT orv.*
        , order_delivered_customer_date
        , case
            when review_creation_date > order_delivered_customer_date then 'valid'
            when review_creation_date < order_delivered_customer_date then 'before_completed'
            when order_delivered_customer_date is null then 'non_completed'
        end as review_validation
    FROM order_reviews orv
    JOIN orders od on orv.order_id = od.order_id
)
SELECT review_validation
    , count(*) as n_reviews
FROM table_valid
GROUP BY review_validation;

with table_valid AS (
    SELECT orv.*
        , order_delivered_customer_date
        , case
            when review_creation_date > order_delivered_customer_date then 'valid'
            when review_creation_date < order_delivered_customer_date then 'before_completed'
            when order_delivered_customer_date is null then 'non_completed'
        end as review_validation
    FROM order_reviews orv
    JOIN orders od on orv.order_id = od.order_id
)
DELETE 
FROM order_reviews
WHERE order_id IN (select order_id from table_valid where review_validation IN ('before_completed', 'non_completed'))
    and review_id IN (select review_id from table_valid where review_validation IN ('before_completed', 'non_completed'))

-- 3/. Bảng products

-- create products_backup table
SELECT *
INTO products_backup
FROM products;

-- address missing values in product_category_name column
Update products
    SET product_category_name = 'unknown'
WHERE product_category_name is null

-- 4/. Bảng geolocation

-- create products_backup table
SELECT *
INTO geolocation_backup
FROM geolocation;


-- addressing duplicate records
WITH CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER(PARTITION BY geolocation_zip_code_prefix 
                                            , geolocation_city
                                            , geolocation_state 
                            ORDER BY (SELECT NULL)) AS rn
    FROM geolocation
)
DELETE FROM CTE WHERE rn > 1;


-- II. EXPORT DATASET TO ANALYZING

SELECT *
FROM orders;

SELECT *
FROM order_items;

SELECT *
FROM order_reviews;

SELECT *
FROM order_payments;

SELECT *
FROM products;

SELECT *
FROM customers;

SELECT *
FROM sellers;

SELECT *
FROM product_category_name_translation;

SELECT *
FROM geolocation;


