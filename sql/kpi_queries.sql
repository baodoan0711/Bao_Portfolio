USE ecommerce_2019;
-- 1. Revenue KPIs
-- 1.1 Tổng quan doanh thu
SELECT
	ROUND(SUM(invoice_value),2) AS 'Total Revenue'
    ,COUNT(DISTINCT Transaction_ID) AS 'Total Order'
    ,COUNT(DISTINCT CustomerID) AS 'Total Customer'
    ,ROUND(SUM(invoice_value) / COUNT(DISTINCT Transaction_ID),2) AS 'AOV'
FROM fact_sales;

-- 1.2 Doanh thu theo tháng
SELECT
	Month
    ,ROUND(SUM(invoice_value),2) AS 'Revenue'
    ,COUNT(DISTINCT Transaction_ID) AS 'Order'
    ,ROUND(SUM(invoice_value) / COUNT(DISTINCT Transaction_ID),2) AS 'AOV'
FROM fact_sales
GROUP BY
	Month
ORDER BY CASE Month
	WHEN 'Jan' THEN 1 WHEN 'Feb' THEN 2 WHEN 'Mar' THEN 3
    WHEN 'Apr' THEN 4 WHEN 'May' THEN 5 WHEN 'Jun' THEN 6
    WHEN 'Jul' THEN 7 WHEN 'Aug' THEN 8 WHEN 'Sep' THEN 9
    WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 WHEN 'Dec' THEN 12
    END;
    
-- 1.3 Doanh thu theo quý
SELECT
	CONCAT('Q',Quarter) AS 'Quarter'
    ,ROUND(SUM(invoice_value),2) AS 'Revenue'
    ,COUNT(DISTINCT Transaction_ID) AS 'Order'
    ,ROUND(SUM(invoice_value) / (SELECT SUM(invoice_value) FROM fact_sales) * 100) AS 'Revenue pct'
FROM fact_sales
GROUP BY
	Quarter;
    
-- 1.4 Doanh thu theo ngày trong tuần
SELECT
	DayOfWeek
    ,ROUND(SUM(invoice_value),2) AS 'Revenue'
    ,COUNT(DISTINCT Transaction_ID) AS 'Order'
    ,ROUND(SUM(invoice_value) / COUNT(DISTINCT Transaction_ID),2) AS 'AOV'
FROM fact_sales
GROUP BY
	DayOfWeek
ORDER BY CASE DayOfWeek
	WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
    WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6
    WHEN 'Sunday' THEN 7
    END;
    
-- 1.5 Doanh thu theo doanh mục sản phẩm
SELECT
	Product_Category
	,ROUND(SUM(invoice_value),2) AS 'Revenue'
    ,COUNT(DISTINCT Transaction_ID) AS 'Order'
    ,ROUND(SUM(invoice_value) / COUNT(DISTINCT Transaction_ID),2) AS 'AOV'
	,ROUND(SUM(invoice_value) / (SELECT SUM(invoice_value) FROM fact_sales) * 100,2) AS 'Revenue pct'
FROM fact_sales f
	JOIN dim_product p ON f.Product_SKU = p.Product_SKU
GROUP BY
	Product_Category
ORDER BY
	Revenue DESC;
    
-- 1.6 Tác động của Discount lên doanh thu
SELECT 
    Coupon_Status
    ,COUNT(*) AS 'Transactions'
    ,ROUND(SUM(Invoice_Value), 2) AS 'Revenue'
    ,ROUND(AVG(Invoice_Value), 2) AS 'Avg_Invoice'
    ,ROUND(AVG(Discount_pct)*100, 2) AS 'Avg_Discount_Pct'
FROM fact_sales
GROUP BY
	Coupon_Status
ORDER BY
	Transactions DESC;
    
-- 2. Customer KPIs
-- 2.1 Phân bổ khách hàng theo Tenure
SELECT
    CASE
        WHEN Tenure_Months <= 12 THEN '0-12 months'
        WHEN Tenure_Months <= 24 THEN '13-24 months'
        WHEN Tenure_Months <= 36 THEN '25-36 months'
        ELSE '37+ months'
    END AS 'Tenure_Group'
    ,COUNT(DISTINCT f.CustomerID) AS 'Customers'
    ,ROUND(SUM(Invoice_value),2) AS 'Revenue'
FROM fact_sales f
    LEFT JOIN dim_customer c ON f.CustomerID = c.CustomerID
GROUP BY
	Tenure_Group
ORDER BY MIN(Tenure_Months);

-- 2.2 Tỉ lệ khách hàng mua lại (>1) và chỉ mua 1 lần
SELECT
    COUNT(DISTINCT CustomerID) AS Total_Customers
    ,COUNT(DISTINCT CASE WHEN order_count > 1 THEN CustomerID END) AS Repeat_Customers
    ,COUNT(DISTINCT CASE WHEN order_count = 1 THEN CustomerID END) AS OneTime_Customers
    ,ROUND(COUNT(DISTINCT CASE WHEN order_count > 1 THEN CustomerID END)
          / COUNT(DISTINCT CustomerID) * 100, 1) AS Repeat_Rate_Pct
    ,ROUND(COUNT(DISTINCT CASE WHEN order_count = 1 THEN CustomerID END)
          / COUNT(DISTINCT CustomerID) * 100, 1) AS OneTime_Rate_Pct
FROM (
    SELECT CustomerID, COUNT(DISTINCT Transaction_ID) AS order_count
    FROM fact_sales
    GROUP BY CustomerID) t;
    
-- 2.3 Doanh thu theo giới tính
SELECT
	Gender
	,COUNT(DISTINCT f.CustomerID) AS 'Customers'
	,ROUND(SUM(invoice_value),2) AS 'Revenue'
    ,COUNT(DISTINCT Transaction_ID) AS 'Order'
    ,ROUND(SUM(invoice_value) / COUNT(DISTINCT Transaction_ID),2) AS 'AOV'
    ,ROUND(SUM(invoice_value) / (SELECT SUM(invoice_value) FROM fact_sales) * 100,2) AS 'Revenue pct'
FROM fact_sales f
	LEFT JOIN dim_customer c ON f.CustomerID = c.CustomerID
GROUP BY
	Gender;

-- 2.4 Doanh thu theo khu vực
SELECT
	Location
	,COUNT(DISTINCT f.CustomerID) AS 'Customers'
	,ROUND(SUM(invoice_value),2) AS 'Revenue'
    ,COUNT(DISTINCT Transaction_ID) AS 'Order'
    ,ROUND(SUM(invoice_value) / COUNT(DISTINCT Transaction_ID),2) AS 'AOV'
    ,ROUND(SUM(invoice_value) / (SELECT SUM(invoice_value) FROM fact_sales) * 100,2) AS 'Revenue pct'
FROM fact_sales f
	LEFT JOIN dim_customer c ON f.CustomerID = c.CustomerID
GROUP BY
	Location;

-- 3. Marketing KPIs
-- 3.1 Tổng quan chi phí Marketing
SELECT
    ROUND(SUM(Offline_Spend), 2) AS Total_Offline
    ,ROUND(SUM(Online_Spend), 2) AS Total_Online
    ,ROUND(SUM(Total_Spend), 2) AS Total_Spend
    ,ROUND(SUM(Online_Spend) / SUM(Total_Spend) * 100, 1) AS Online_Pct
    ,ROUND(SUM(Offline_Spend) / SUM(Total_Spend) * 100, 1) AS Offline_Pct
    ,ROUND((SELECT SUM(Invoice_Value) FROM fact_sales) / SUM(Total_Spend), 2) AS ROAS
FROM dim_marketing;

-- 3.2 Marketing Spend và ROAS theo tháng
SELECT
    m.Month
    ,ROUND(m.Offline_Spend, 2) AS Offline_Spend
    ,ROUND(m.Online_Spend, 2) AS Online_Spend
    ,ROUND(m.Total_Spend, 2) AS Total_Spend
    ,ROUND(f.Revenue, 2) AS Revenue
    ,ROUND(f.Revenue / m.Total_Spend, 2) AS ROAS
    ,ROUND(m.Total_Spend / f.Revenue * 100, 1) AS Mkt_Pct_of_Rev
FROM (
    SELECT
        DATE_FORMAT(Date, '%b') AS Month
        ,SUM(Offline_Spend) AS Offline_Spend
        ,SUM(Online_Spend) AS Online_Spend
        ,SUM(Total_Spend) AS Total_Spend
    FROM dim_marketing
    GROUP BY DATE_FORMAT(Date, '%b')
) m
JOIN (
    SELECT Month, SUM(Invoice_Value) AS Revenue
    FROM fact_sales
    GROUP BY Month) f
    ON m.Month = f.Month
ORDER BY CASE m.Month
    WHEN 'Jan' THEN 1  WHEN 'Feb' THEN 2  WHEN 'Mar' THEN 3
    WHEN 'Apr' THEN 4  WHEN 'May' THEN 5  WHEN 'Jun' THEN 6
    WHEN 'Jul' THEN 7  WHEN 'Aug' THEN 8  WHEN 'Sep' THEN 9
    WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 WHEN 'Dec' THEN 12 END;
    
