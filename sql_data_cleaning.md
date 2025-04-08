# SQL DATA CLEANING

## 1. 

## 1.1. table: orders

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|order_id|nvarchar|99441|99441|0|0.00|
|customer_id|nvarchar|99441|99441|0|0.00|
|order_status|nvarchar|99441|99441|0|0.00|
|order_purchase_timestamp|datetime2|99441|99441|0|0.00|
|order_approved_at|datetime2|99441|99295|146|0.15|
|order_delivered_carrier_date|datetime2|99441|97659|1782|1.79|
|order_delivered_customer_date|datetime2|99441|96476|2965|2.98|
|order_estimated_delivery_date|datetime2|99441|99441|0|0.00|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|99441|99441|UNIQUE|

## 1.2. table: order_items

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|order_id|nvarchar|112650|112650|0|0.00|
|order_item_id|tinyint|112650|112650|0|0.00|
|product_id|nvarchar|112650|112650|0|0.00|
|seller_id|nvarchar|112650|112650|0|0.00|
|shipping_limit_date|datetime2|112650|112650|0|0.00|
|price|float|112650|112650|0|0.00|
|freight_value|float|112650|112650|0|0.00|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|112650|112650|UNIQUE|

## 1.3. table: order_payments

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|order_id|nvarchar|103886|103886|0|0.00|
|payment_sequential|tinyint|103886|103886|0|0.00|
|payment_type|nvarchar|103886|103886|0|0.00|
|payment_installments|tinyint|103886|103886|0|0.00|
|payment_value|float|103886|103886|0|0.00|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|103886|103886|UNIQUE|

## 1.4. table: order_reviews

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|review_id|nvarchar|99224|99224|0|0.00|
|order_id|nvarchar|99224|99224|0|0.00|
|review_score|tinyint|99224|99224|0|0.00|
|review_comment_title|nvarchar|99224|99224|0|0.00|
|review_comment_message|nvarchar|99224|99224|0|0.00|
|review_creation_date|datetime2|99224|99224|0|0.00|
|review_answer_timestamp|datetime2|99224|99224|0|0.00|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|99224|98673|DUPLICATE EXISTS|

## 1.5. table: customers

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|customer_id|nvarchar|99441|99441|0|0.00|
|customer_unique_id|nvarchar|99441|99441|0|0.00|
|customer_zip_code_prefix|int|99441|99441|0|0.00|
|customer_city|nvarchar|99441|99441|0|0.00|
|customer_state|nvarchar|99441|99441|0|0.00|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|99441|99441|UNIQUE|

## 1.6. table: products

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|product_id|nvarchar|32951|32951|0|0.00|
|product_category_name|nvarchar|32951|32951|0|0.00|
|product_name_lenght|tinyint|32951|32341|610|1.85|
|product_description_lenght|smallint|32951|32341|610|1.85|
|product_photos_qty|tinyint|32951|32341|610|1.85|
|product_weight_g|int|32951|32949|2|0.01|
|product_length_cm|tinyint|32951|32949|2|0.01|
|product_height_cm|tinyint|32951|32949|2|0.01|
|product_width_cm|tinyint|32951|32949|2|0.01|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|32951|32951|UNIQUE|

## 1.7. table: sellers

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|seller_id|nvarchar|3095|3095|0|0.00|
|seller_zip_code_prefix|int|3095|3095|0|0.00|
|seller_city|nvarchar|3095|3095|0|0.00|
|seller_state|nvarchar|3095|3095|0|0.00|

|Total_Rows|Unique_Key_Combinations|Key_Uniqueness_Status|
|---|---|---|
|3095|3095|UNIQUE|

## 1.8. table: geolocation

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|geolocation_zip_code_prefix|int|1000163|1000163|0|0.00|
|geolocation_lat|float|1000163|1000163|0|0.00|
|geolocation_lng|float|1000163|1000163|0|0.00|
|geolocation_city|nvarchar|1000163|1000163|0|0.00|
|geolocation_state|nvarchar|1000163|1000163|0|0.00|


## 1.9. table: product_category_name_translation

|Column_Name|Data_Type|Total_Rows|Non_NULLs|NULLs|NULL_Percent|
|---|---|---|---|---|---|
|product_category_name|nvarchar|71|71|0|0.00|
|product_category_name_english|nvarchar|71|71|0|0.00|


