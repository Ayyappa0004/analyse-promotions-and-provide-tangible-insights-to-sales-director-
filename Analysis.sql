/*
1 Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free). This information will help 
us identify high-value products that are currently being heavily discounted, which can be useful for evaluating our pricing and promotion strategies
*/

select distinct(product_name),base_price from dim_products p
join fact_events e
using (product_code)
where base_price>500 and promo_type ="BOGOF";




/* 2. Generate a report that provides an overview of the number of stores in each city.
 The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence*/
 select city,count(*)as store_count 
 from dim_stores
 group by city
 order by store_count desc;
 
 
 /* 3) 
Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
The report includes three key fields: campaign_name, total_revenue(before_ _revenue(before_promotion), total_revenue(after_promotion). 
*/
WITH cte AS (
    SELECT
        c.campaign_name AS campaign_name,
        f.`quantity_sold(before_promo)` * f.base_price AS before_promo_revenue,
        f.`quantity_sold(after_promo)` * f.base_price as after_promo_revenue,
        f.promo_type as promo_type
    FROM
        dim_campaigns c
    JOIN
        fact_events f
    USING (campaign_id)
)

SELECT 
    campaign_name,
    CONCAT(FORMAT(SUM(before_promo_revenue) / 1000000, 2), ' Millions') AS Revenue_before_promo,
    CONCAT(FORMAT(SUM(
        CASE 
            WHEN promo_type = "25% OFF" THEN after_promo_revenue * (1 - 0.25) 
            WHEN promo_type = "50% OFF" THEN after_promo_revenue * (1 - 0.50)
            WHEN promo_type = "33% OFF" THEN after_promo_revenue * (1 - 0.33) 
            WHEN promo_type = "500 OFF" THEN after_promo_revenue - 500 
            ELSE after_promo_revenue
        END
    ) / 1000000, 2), ' Millions') AS Revenue_after_promo
FROM 
    cte
GROUP BY 
    campaign_name
ORDER BY 
    Revenue_before_promo DESC, 
    Revenue_after_promo DESC;


    
/* 4) 
Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.
 Additionally, provide rankings for the categories based on their ISU%. The report will include three key fields: category, isu%, and rank order
*/

with cte1 as(
select c.campaign_name as campaign_name,
p.category as category,
SUM(f.`quantity_sold(before_promo)`) AS Quantity_before_promo,
SUM(f.`quantity_sold(after_promo)`) AS Quantity_after_promo,
f.promo_type AS promo_type
from dim_products p
join fact_events f using(product_code)
join dim_campaigns c using(campaign_id)
 GROUP BY
        category, campaign_name, promo_type
),
cte2 AS (
    SELECT
        category,
        Quantity_before_promo,
        CASE WHEN promo_type = 'BOGOF' THEN Quantity_after_promo * 2 ELSE Quantity_after_promo END AS Quantity_after_promo
    FROM
        cte1
    WHERE
        campaign_name = 'Diwali'
)
SELECT
    category,
    Quantity_before_promo,
    Quantity_after_promo,
	CONCAT(ROUND((Quantity_after_promo - Quantity_before_promo) / Quantity_before_promo * 100, 2), '%') AS ISU_percentage,
    RANK() OVER (ORDER BY (Quantity_after_promo - Quantity_before_promo) / Quantity_before_promo * 100 DESC) AS rankings
FROM
    cte2;



/* 5) 
Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
The report will provide essential information including product name, category, and ir%. 
*/
WITH Revenue AS (
    SELECT 
        p.product_name AS Product_name,
        p.category AS category,
        SUM(f.`quantity_sold(before_promo)`) * f.base_price AS Revenue_before_promo,
        SUM(
            CASE 
                WHEN promo_type = '25% OFF' THEN f.`quantity_sold(after_promo)` * (1 - 0.25) * f.base_price
                WHEN promo_type = '50% OFF' THEN f.`quantity_sold(after_promo)` * (1 - 0.50) * f.base_price
                WHEN promo_type = '33% OFF' THEN f.`quantity_sold(after_promo)` * (1 - 0.33) * f.base_price
                WHEN promo_type = '500 OFF' THEN (f.`quantity_sold(after_promo)` - 500) * f.base_price
                WHEN promo_type = 'BOGOF' THEN f.`quantity_sold(after_promo)` * f.base_price
                ELSE f.`quantity_sold(after_promo)` * f.base_price
            END
        ) AS Revenue_after_promo
    FROM
        dim_products p
        JOIN
        fact_events f ON p.product_code = f.product_code
    GROUP BY Product_name, category, f.base_price
)

SELECT 
    Product_name,
    category,
    Revenue_before_promo,
    Revenue_after_promo,
    CONCAT(ROUND((Revenue_after_promo - Revenue_before_promo) / Revenue_before_promo * 100, 2), '%') as IR
FROM Revenue
ORDER BY IR DESC
LIMIT 5;





