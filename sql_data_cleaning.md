# SQL DATA CLEANING

## I. Individual Table Data Cleaning

The following two sets of SQL queries are used to perform an **overview data quality check** on the tables in the **Olist e-commerce relational database**. These checks cover key aspects such as **data types**, **null values**, and **duplicates**, providing a foundational understanding of the data's reliability before analysis.

```sql
-- DATA TYPES AND NULL VALUES CHECK
DECLARE @table_name NVARCHAR(MAX) = 'orders';
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @column_name NVARCHAR(MAX);

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

SET @sql = LEFT(@sql, LEN(@sql) - 10);
EXEC sp_executesql @sql;

-- DUPLICATE_CHECK
DECLARE @table_name NVARCHAR(MAX) = 'orders';  -- Tên bảng của em
DECLARE @key_columns NVARCHAR(MAX) = 'order_id'; -- Cột hoặc tổ hợp cột dùng làm khóa chính

DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @cols_concat NVARCHAR(MAX) = '';

SELECT @cols_concat = STRING_AGG('ISNULL(CAST(' + LTRIM(RTRIM(value)) + ' AS NVARCHAR(MAX)), '''')', ' + ''|'' + ')
FROM STRING_SPLIT(@key_columns, ',');

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

EXEC sp_executesql @sql;
```

## 1. table: orders

**Table 1:** Data Type and Null Value Check: orders Table
|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|order_id|nvarchar|99441|99441|0|0.00|
|customer_id|nvarchar|99441|99441|0|0.00|
|order_status|nvarchar|99441|99441|0|0.00|
|order_purchase_timestamp|datetime2|99441|99441|0|0.00|
|order_approved_at|datetime2|99441|99281|160|0.16|
|order_delivered_carrier_date|datetime2|99441|97658|1783|1.79|
|order_delivered_customer_date|datetime2|99441|96476|2965|2.98|
|order_estimated_delivery_date|datetime2|99441|99441|0|0.00|

**Table 2:** Duplicates Check: orders Table
|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|99441|99441|UNIQUE|

The orders table has valid data types for all columns and no duplicated entries. However, **three columns contain NULL values**: **order_approved_at (0.16%)**, **order_delivered_carrier_date (1.79%)**, and **order_delivered_customer_date (2.98%)**. These missing values need to be addressed.

### 1.1. Addressing missing value: order_approved_at column
For the order_approved_at column, NULL values fall into **three statuses**:
- **Canceled (141 orders):** These orders were canceled, so it's reasonable that the approval timestamp is missing. (NULL is acceptable)
- **Created (5 orders):** These orders are still in progress and have not yet reached the approval stage. (NULL is acceptable)
- **Delivered (14 orders):** These orders were already delivered to customers, but the approval timestamp is still NULL — indicating a data inconsistency (NULL is **not acceptable** and needs to be addressed).

```sql
-- Create back-up orders table for addressing missing values
select *
Into orders_backup
From orders;
```

**Table 3:** Missing value’s order_approved_at when order_status is 'delivered'
|order_id|customer_id|order_status|order_purchase_timestamp|order_approved_at|order_delivered_carrier_date|order_delivered_customer_date|order_estimated_delivery_date|
|---|---|---|---|---|---|---|---|
|e04abd8149ef81b95221e88f6ed9ab6a|2127dc6603ac33544953ef05ec155771|delivered|2017-02-18 14:40:00.0000000|NULL|2017-02-23 12:04:47.0000000|2017-03-01 13:25:33.0000000|2017-03-17 00:00:00.0000000|
|8a9adc69528e1001fc68dd0aaebbb54a|4c1ccc74e00993733742a3c786dc3c1f|delivered|2017-02-18 12:45:31.0000000|NULL|2017-02-23 09:01:52.0000000|2017-03-02 10:05:06.0000000|2017-03-21 00:00:00.0000000|
|7013bcfc1c97fe719a7b5e05e61c12db|2941af76d38100e0f8740a374f1a5dc3|delivered|2017-02-18 13:29:47.0000000|NULL|2017-02-22 16:25:25.0000000|2017-03-01 08:07:38.0000000|2017-03-17 00:00:00.0000000|
|5cf925b116421afa85ee25e99b4c34fb|29c35fc91fc13fb5073c8f30505d860d|delivered|2017-02-18 16:48:35.0000000|NULL|2017-02-22 11:23:10.0000000|2017-03-09 07:28:47.0000000|2017-03-31 00:00:00.0000000|
|12a95a3c06dbaec84bcfb0e2da5d228a|1e101e0daffaddce8159d25a8e53f2b2|delivered|2017-02-17 13:05:55.0000000|NULL|2017-02-22 11:23:11.0000000|2017-03-02 11:09:19.0000000|2017-03-20 00:00:00.0000000|
|c1d4211b3dae76144deccd6c74144a88|684cb238dc5b5d6366244e0e0776b450|delivered|2017-01-19 12:48:08.0000000|NULL|2017-01-25 14:56:50.0000000|2017-01-30 18:16:01.0000000|2017-03-01 00:00:00.0000000|
|d69e5d356402adc8cf17e08b5033acfb|68d081753ad4fe22fc4d410a9eb1ca01|delivered|2017-02-19 01:28:47.0000000|NULL|2017-02-23 03:11:48.0000000|2017-03-02 03:41:58.0000000|2017-03-27 00:00:00.0000000|
|d77031d6a3c8a52f019764e68f211c69|0bf35cac6cc7327065da879e2d90fae8|delivered|2017-02-18 11:04:19.0000000|NULL|2017-02-23 07:23:36.0000000|2017-03-02 16:15:23.0000000|2017-03-22 00:00:00.0000000|
|7002a78c79c519ac54022d4f8a65e6e8|d5de688c321096d15508faae67a27051|delivered|2017-01-19 22:26:59.0000000|NULL|2017-01-27 11:08:05.0000000|2017-02-06 14:22:19.0000000|2017-03-16 00:00:00.0000000|
|2eecb0d85f281280f79fa00f9cec1a95|a3d3c38e58b9d2dfb9207cab690b6310|delivered|2017-02-17 17:21:55.0000000|NULL|2017-02-22 11:42:51.0000000|2017-03-03 12:16:03.0000000|2017-03-20 00:00:00.0000000|
|51eb2eebd5d76a24625b31c33dd41449|07a2a7e0f63fd8cb757ed77d4245623c|delivered|2017-02-18 15:52:27.0000000|NULL|2017-02-23 03:09:14.0000000|2017-03-07 13:57:47.0000000|2017-03-29 00:00:00.0000000|
|88083e8f64d95b932164187484d90212|f67cd1a215aae2a1074638bbd35a223a|delivered|2017-02-18 22:49:19.0000000|NULL|2017-02-22 11:31:06.0000000|2017-03-02 12:06:06.0000000|2017-03-21 00:00:00.0000000|
|3c0b8706b065f9919d0505d3b3343881|d85919cb3c0529589c6fa617f5f43281|delivered|2017-02-17 15:53:27.0000000|NULL|2017-02-22 11:31:30.0000000|2017-03-03 11:47:47.0000000|2017-03-23 00:00:00.0000000|
|2babbb4b15e6d2dfe95e2de765c97bce|74bebaf46603f9340e3b50c6b086f992|delivered|2017-02-18 17:15:03.0000000|NULL|2017-02-22 11:23:11.0000000|2017-03-03 18:43:43.0000000|2017-03-31 00:00:00.0000000|

To handle these NULL values, I will estimate the missing order_approved_at timestamps by adding the average time difference between order_purchase_timestamp and order_approved_at (**avg_approve_hour**) during the corresponding month — January or February — to each missing value’s order_approved_at.

This approach is based on the following observations:
- The orders with missing approval timestamps were created only in January and February 2017 (see **Table 3**).
- The average time between order_purchase_timestamp and order_approved_at remains relatively stable across months, excluding some outliers (see ReadME.md and **Figure 1**).
- There is no significant difference in this time gap between orders delivered late and those delivered on time (see **Table 4**).

```sql
select format(order_purchase_timestamp, 'yyyy-MM') as year_month
    , avg(datediff(hour, order_purchase_timestamp, order_approved_at)) as avg_approve_hour
from orders2
where order_approved_at is not null
group by format(order_purchase_timestamp, 'yyyy-MM')
order by year_month;
-- code for Figure 1
```

<div align="center">

  ![image](https://github.com/user-attachments/assets/8401df14-219e-4a6c-8669-70f08ec822c5)
  
  **Figure 1:** Trend of Average Approval Time (in Hours) Over Time

</div>

```sql
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
-- code for table 4
```
**Table 4:** avg_approve_hour comparison between on-time-delivered orders and late-delivered orders
|delivery_status|avg_approve_hour|
|---|---|
|late|12|
|ontime|10|

### 1.2. Addressing missing value: order_delivered_carrier_date column

For the column order_delivered_carrier_date, NULL values fall into the following **statuses**:
- **Canceled, Unavailable (1,159 orders):** Orders were canceled by customers or due to stock unavailability, so the absence of delivery information is valid.
- **Created, Invoiced, Processing, Approved (622 orders):** Orders are still in the processing stage and have not yet reached the delivery stage, so NULL values are considered valid.
- **Delivered (2 orders):** These orders were marked as delivered, but their delivery-to-carrier dates are missing (see **Table 5**). These NULLs are considered invalid and need to be addressed.

Since only two orders are affected, they will be handled as follows:
- One of the orders is missing delivery information but marked as **"delivered"** from **as early as May 25, 2017**. Due to the inconsistency and outdated nature, **it will be reclassified as canceled**.
- The other order will be imputed by adding the average duration from **order_approved_at** to **order_delivered_carrier_date** (**avg_carrier_hour**) for September 2017, as the order was created during this period.

**Table 5:** Missing value’s order_delivered_carrier_date when order_status is 'delivered'
|order_id|customer_id|order_status|order_purchase_timestamp|order_approved_at|order_delivered_carrier_date|order_delivered_customer_date|order_estimated_delivery_date|
|---|---|---|---|---|---|---|---|
|2aa91108853cecb43c84a5dc5b277475|afeb16c7f46396c0ed54acb45ccaaa40|delivered|2017-09-29 08:52:58.0000000|2017-09-29 09:07:16.0000000|NULL|2017-11-20 19:44:47.0000000|2017-11-14 00:00:00.0000000|
|2d858f451373b04fb5c984a1cc2defaf|e08caf668d499a6d643dafd7c5cc498a|delivered|2017-05-25 23:22:43.0000000|2017-05-25 23:30:16.0000000|NULL|NULL|2017-06-23 00:00:00.0000000|

### 1.3. Addressing missing value: order_delivered_customer_date column

For the column order_delivered_carrier_date, **NULL values** are associated with the following order statuses: Approved, Canceled, Created, Invoiced, Processing, and Unavailable. These statuses represent orders that were either canceled, still in processing, or on the way to the carrier, so the absence of delivery-to-carrier information **is considered valid** in these cases.

## 2. table: order_items

The **order_items table** meets data quality standards in terms of **data types,** **non-null values**, and **uniqueness of records**.

**Table 6:** Data Type and Null Value Check: order_items Table
|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|order_id|nvarchar|112650|112650|0|0.00|
|order_item_id|tinyint|112650|112650|0|0.00|
|product_id|nvarchar|112650|112650|0|0.00|
|seller_id|nvarchar|112650|112650|0|0.00|
|shipping_limit_date|datetime2|112650|112650|0|0.00|
|price|float|112650|112650|0|0.00|
|freight_value|float|112650|112650|0|0.00|

**Table 7:** Duplicates Check: order_items Table
|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|112650|112650|UNIQUE|

## 1.3. table: order_payments

The **order_payments table** meets data quality standards in terms of **data types,** **non-null values**, and **uniqueness of records**.

**Table 8:** Data Type and Null Value Check: order_payments Table
|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|order_id|nvarchar|103886|103886|0|0.00|
|payment_sequential|tinyint|103886|103886|0|0.00|
|payment_type|nvarchar|103886|103886|0|0.00|
|payment_installments|tinyint|103886|103886|0|0.00|
|payment_value|float|103886|103886|0|0.00|

**Table 9:** Duplicates Check: order_payments Table
|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|103886|103886|UNIQUE|

## 1.4. table: order_reviews

**Table 10:** Data Type and Null Value Check: order_reviews Table
|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|review_id|nvarchar|99224|99224|0|0.00|
|order_id|nvarchar|99224|99224|0|0.00|
|review_score|tinyint|99224|99224|0|0.00|
|review_comment_title|nvarchar|99224|11566|87658|88.34|
|review_comment_message|nvarchar|99224|40968|58256|58.71|
|review_creation_date|datetime2|99224|99224|0|0.00|
|review_answer_timestamp|datetime2|99224|99224|0|0.00|

The **order_reviews table** contains valid data types across all columns. However, two columns, **review_comment_title** and **review_comment_message**, have a high percentage of missing values—approximately **88%** and **59%**, respectively—requiring further handling and consideration.

There are three scenarios identified regarding the missing values in the two columns review_comment_title and review_comment_message:
- (1) Both columns are NULL
- (2) Only review_comment_title is NULL
- (3) Only review_comment_message is NULL

Proposed Handling Strategy:
- For **case (1)**, where both fields are NULL, we will fill them with "only score" to indicate that the reviewer provided a rating without leaving any comment.
- For **case (2)**, where only review_comment_title is NULL, we will fill it with "non review title" to maintain consistency.
- For **case (3)**, where only review_comment_message is NULL, we will fill it with "non review message" accordingly.

```sql
-- Address Missing Values of review_comment_title column and review_comment_message column
UPDATE order_reviews_backup
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
                        end
```

**Table 11:** Duplicates Check: order_reviews Table
|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|99224|99224|UNIQUE|

For the **order_reviews** table, the composite key consisting of **order_id** and **review_id** ensures that there are **no duplicate records**.

**However**, based on the dataset context (see **ReadME.md**), it is stated that:

> “After a customer purchases the product from Olist Store, a seller gets notified to fulfill that order. Once the customer receives the product, or the estimated delivery date is due, the customer gets a satisfaction survey by email where they can rate their purchase experience and leave comments.”

This means that each order **should only be reviewed after the customer has received the product**.

Therefore, any reviews linked to orders that were cancelled, not yet delivered, or submitted before the product was delivered are considered invalid and will be removed from the dataset (see **table 12**).

```sql
-- code for table 12
with table_valid AS (
    SELECT orv.*
        , order_delivered_customer_date
        , case
            when review_creation_date > order_delivered_customer_date then 'valid'
            when review_creation_date < order_delivered_customer_date then 'before_completed'
            when order_delivered_customer_date is null then 'non_completed'
        end as review_validation
    FROM order_reviews_backup orv
    JOIN orders od on orv.order_id = od.order_id
)
SELECT review_validation
    , count(*) as n_reviews
FROM table_valid
GROUP BY review_validation;
```

**Table 12:** Validating review records from customers
|review_validation|n_reviews|
|---|---|
|non_completed|2865|
|valid|88039|
|before_completed|8320|

```sql
-- Address incompatible records
with table_valid AS (
    SELECT orv.*
        , order_delivered_customer_date
        , case
            when review_creation_date > order_delivered_customer_date then 'valid'
            when review_creation_date < order_delivered_customer_date then 'before_completed'
            when order_delivered_customer_date is null then 'non_completed'
        end as review_validation
    FROM order_reviews_backup orv
    JOIN orders od on orv.order_id = od.order_id
)
DELETE 
FROM order_reviews_backup
WHERE order_id IN (select order_id from table_valid where review_validation IN ('before_completed', 'non_completed'))
    and review_id IN (select review_id from table_valid where review_validation IN ('before_completed', 'non_completed'))
```

## 1.5. table: customers

The **customers table** meets data quality standards in terms of **data types,** **non-null values**, and **uniqueness of records**.

**Table 13:** Data Type and Null Value Check: customers Table
|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|customer_id|nvarchar|99441|99441|0|0.00|
|customer_unique_id|nvarchar|99441|99441|0|0.00|
|customer_zip_code_prefix|int|99441|99441|0|0.00|
|customer_city|nvarchar|99441|99441|0|0.00|
|customer_state|nvarchar|99441|99441|0|0.00|

**Table 14:** Duplicates Check: customers Table
|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|99441|99441|UNIQUE|

## 1.6. table: products

**Table 13:** Data Type and Null Value Check: products Table
|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|product_id|nvarchar|32951|32951|0|0.00|
|product_category_name|nvarchar|32951|32341|610|1.85|
|product_name_lenght|tinyint|32951|32341|610|1.85|
|product_description_lenght|smallint|32951|32341|610|1.85|
|product_photos_qty|tinyint|32951|32341|610|1.85|
|product_weight_g|int|32951|32949|2|0.01|
|product_length_cm|tinyint|32951|32949|2|0.01|
|product_height_cm|tinyint|32951|32949|2|0.01|
|product_width_cm|tinyint|32951|32949|2|0.01|

**Table 14:** Duplicates Check: products Table
|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|32951|32951|UNIQUE|

The products table has valid data types and contains no duplicate records. However, the table has a significant number of NULL values across many columns (with product_id as the primary key). Specifically:
- Four columns have identical NULL rates of 1.85%: product_category_name, product_name_length, product_description_length, and product_photos_qty.
- Another four columns have identical NULL rates of 0.01%: product_weight_g, product_length_cm, product_height_cm, and product_width_cm.

Among these, only the **product_category_name** column can be reasonably imputed with the value "**unknown**", indicating an unspecified product category.

The **remaining columns** are **numerical**, and replacing NULLs with "unknown" would be **incompatible** with their data type. Furthermore, there is no reliable reference to impute appropriate values. Therefore, these missing values will be ignored during the analysis. Given that the proportion of missing values is relatively low, their impact on the final analysis results is expected to be minimal.

```sql
-- create products_backup table
SELECT *
INTO products_backup
FROM products2;

-- address missing values in product_category_name column
Update products_backup
    SET product_category_name = 'unknown'
WHERE product_category_name is null
```

## 1.7. table: sellers

The **sellers table** meets data quality standards in terms of **data types,** **non-null values**, and **uniqueness of records**.

**Table 15:** Data Type and Null Value Check: products Table
|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|seller_id|nvarchar|3095|3095|0|0.00|
|seller_zip_code_prefix|int|3095|3095|0|0.00|
|seller_city|nvarchar|3095|3095|0|0.00|
|seller_state|nvarchar|3095|3095|0|0.00|

**Table 16:** Duplicates Check: products Table
|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|3095|3095|UNIQUE|

## 1.8. table: geolocation

The **geolocation table** meets data quality standards in terms of **data types,** **non-null values**, and ....

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|geolocation_zip_code_prefix|int|1000163|1000163|0|0.00|
|geolocation_lat|float|1000163|1000163|0|0.00|
|geolocation_lng|float|1000163|1000163|0|0.00|
|geolocation_city|nvarchar|1000163|1000163|0|0.00|
|geolocation_state|nvarchar|1000163|1000163|0|0.00|

## 1.9. table: product_category_name_translation

The **product_category_name_translation table** meets data quality standards in terms of **data types,** **non-null values**, and **uniqueness of records**.

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|product_category_name|nvarchar|71|71|0|0.00|
|product_category_name_english|nvarchar|71|71|0|0.00|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|71|71|UNIQUE|


