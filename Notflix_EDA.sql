SELECT TOP 1 * FROM subscription_data
SELECT TOP 1 * FROM consumption_data
SELECT TOP 1 * FROM rating_data
SELECT TOP 1 * FROM catalogue_data

--EDA(Exploratory Data Analysis)
   -- Descriptive and Diagnostic Analysis

--Subscription data
/*
   Total Subscriptions
   Total Users
   Total Revenue
   AOV
   Avg Duration  -influenced by outliers

   New vs Existing Customers
   Repeated Users
   Distribution of Users/Revenue/Orders by Plan type
   MOM Revenue/Subscriptions/New Customers
   Understanding when users are purchasing
                      - Which day of the week
					  - What time of the day
   % OF Repeated Users
   New vs Existing Cutomerss
   New Cust --> Who is making a transaction for the first time with the org.
   Min tran/First tran at cust level

*/
--Total Subscriptions, Total Users, Total Revenue, AOV, Avg Duration of Subscription
SELECT COUNT(A.subscription_key) AS Total_Subs,
COUNT(DISTINCT A.user_id) AS Total_users,
round(SUM(A.amount_paid),2) AS Total_revenue,
round(AVG(A.amount_paid),2) AS AOV,
AVG(A.subscription_length) AS Avg_days
FROM subscription_data AS A


--Distribution of Users/Revenue/Orders/AOV by Plan type
SELECT A.plan_type,
CAST(ROUND((COUNT(DISTINCT A.user_id)*1.00/(SELECT COUNT(DISTINCT user_id) FROM subscription_data))*100,2) AS float) AS Cust_perc,
ROUND((SUM(A.amount_paid)/(SELECT SUM(amount_paid) FROM subscription_data))*100,2) AS Revenue_perc,
CAST(ROUND((COUNT(A.subscription_key)*1.00/(SELECT COUNT(subscription_key) FROM subscription_data))*100,2) AS float) AS Orders_perc,
ROUND(AVG(A.amount_paid),2) AS AOV
FROM subscription_data AS A
WHERE A.plan_type IS NOT NULL
GROUP BY A.plan_type

--MOM Revenue/Subscriptions/New Customers
--MoM Revenue
SELECT YEAR(subscription_created_date) AS yr, MONTH(subscription_created_date) AS mn, round(SUM(amount_paid),2) AS total_revenue FROM subscription_data
GROUP BY YEAR(subscription_created_date), MONTH(subscription_created_date)
ORDER BY yr, mn asc;

-- MoM Subscriptions
SELECT YEAR(subscription_created_date) AS yr,MONTH(subscription_created_date) AS mn,COUNT(subscription_key) AS total_subscriptions FROM subscription_data
GROUP BY YEAR(subscription_created_date), MONTH(subscription_created_date)
ORDER BY yr, mn asc;

-- MoM New Customers (first-time subscribers only)
---- Calculates true MoM new customers based on first subscription date
WITH first_subscription AS (
SELECT user_id,MIN(subscription_created_date) AS first_sub_date FROM subscription_data GROUP BY user_id)
SELECT YEAR(first_sub_date) AS yr, MONTH(first_sub_date) AS mn, COUNT(user_id) AS new_customers FROM first_subscription 
GROUP BY YEAR(first_sub_date),MONTH(first_sub_date)
ORDER BY yr, mn;


  --Understanding when users are purchasing
                      -- Which day of the week
					  -- What time of the day
SELECT DATENAME(WEEKDAY,A.subscription_created_date) AS Weekday_,
CAST(round(count(A.order_key)*1.00/(SELECT COUNT(*) FROM subscription_data)*100,2) AS float) AS Subs_perc
FROM subscription_data AS A
GROUP BY DATENAME(WEEKDAY,A.subscription_created_date)
ORDER BY Subs_perc DESC


SELECT 
CASE
     WHEN DATENAME(HOUR,A.subscription_created_time) < 4 THEN 'Early Morning'
	 WHEN DATENAME(HOUR,A.subscription_created_time) < 8 THEN 'Morning'
	 WHEN DATENAME(HOUR,A.subscription_created_time) < 12 THEN 'Late Morning'
	 WHEN DATENAME(HOUR,A.subscription_created_time) < 16 THEN 'Afternoon'
	 when DATENAME(HOUR,A.subscription_created_time) < 20 THEN 'Evening'
	 ELSE 'Night'
	 END AS Day_Seg,
	 CAST(round(count(A.order_key)*1.00/(SELECT COUNT(*) FROM subscription_data)*100,2) AS float) AS Subs_perc

	 FROM subscription_data AS A
	 GROUP BY CASE
     WHEN DATENAME(HOUR,A.subscription_created_time) < 4 THEN 'Early Morning'
	 WHEN DATENAME(HOUR,A.subscription_created_time) < 8 THEN 'Morning'
	 WHEN DATENAME(HOUR,A.subscription_created_time) < 12 THEN 'Late Morning'
	 WHEN DATENAME(HOUR,A.subscription_created_time) < 16 THEN 'Afternoon'
	 when DATENAME(HOUR,A.subscription_created_time) < 20 THEN 'Evening'
	 ELSE 'Night'
	 END
	ORDER BY Subs_perc DESC

-- % OF Repeated Users
SELECT 
CAST(Round((COUNT(*)*1.00/(SELECT COUNT(DISTINCT user_id) FROM subscription_data))*100,2) AS float) AS Repeated_Cust_perc
FROM(
	SELECT A.user_id,COUNT(*) AS Cust_cnt
	FROM subscription_data AS A
	GROUP BY A.user_id
	HAVING COUNT(*) > 1
	) AS T


--New vs Existing Cutomerss
--New Cust --> Who is making a transaction for the first time with the org.

-- New vs Existing Customers (Month-wise)
WITH first_subscription AS 
(SELECT user_id, MIN(subscription_created_date) AS first_sub_date FROM subscription_data 
 GROUP BY user_id),
monthly_activity AS (SELECT user_id, YEAR(subscription_created_date) AS yr, MONTH(subscription_created_date) AS mn FROM subscription_data
GROUP BY user_id, YEAR(subscription_created_date),MONTH(subscription_created_date))
SELECT  ma.yr, ma.mn,CASE WHEN YEAR(fs.first_sub_date) = ma.yr AND MONTH(fs.first_sub_date) = ma.mn 
THEN 'New' ELSE 'Existing' END AS customer_type, COUNT(DISTINCT ma.user_id) AS customer_count 
FROM monthly_activity ma
JOIN first_subscription fs
ON ma.user_id = fs.user_id
GROUP BY ma.yr,ma.mn,
CASE WHEN YEAR(fs.first_sub_date) = ma.yr AND MONTH(fs.first_sub_date) = ma.mn THEN 'New' ELSE 'Existing' END
ORDER BY ma.yr,ma.mn,customer_type;

--New Customer --Who is making a transaction for the first time with the org.
SELECT A.user_id,COUNT(*) AS Cust_cnt
	FROM subscription_data AS A
	GROUP BY A.user_id
	HAVING COUNT(*) =1


--Min tran/First tran at cust level
SELECT A.user_id,MIN(A.subscription_created_date) AS First_tran_date
FROM subscription_data AS A
GROUP BY A.user_id


--Consumption data
/*
Avg user duration
Which content is consumed the most
What time of the day content is consumed
Which platform is used mostly to consume the content
Which Content has brought the most number of users.

*/

--Avg user duration
SELECT round(AVG(A.user_duration),2) AS AVG_user_duration
FROM consumption_data AS A

--Which content is consumed the most
 -- Most consumed content (by total watch duration in seconds)
SELECT
    c.content_id,
    ROUND(SUM(c.user_duration), 0) AS total_watch_time
FROM consumption_data c
GROUP BY c.content_id
ORDER BY total_watch_time DESC;

--What time of the day content is consumed
SELECT
    CASE
        WHEN DATEPART(HOUR, consumption_date) < 4  THEN 'Early Morning'
        WHEN DATEPART(HOUR, consumption_date) < 8  THEN 'Morning'
        WHEN DATEPART(HOUR, consumption_date) < 12 THEN 'Late Morning'
        WHEN DATEPART(HOUR, consumption_date) < 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, consumption_date) < 20 THEN 'Evening'
        ELSE 'Night'
    END AS time_of_day,

    ROUND(SUM(user_duration) / 60.0, 2) AS total_watch_time_minutes
FROM consumption_data
WHERE consumption_date IS NOT NULL
GROUP BY
    CASE
        WHEN DATEPART(HOUR, consumption_date) < 4  THEN 'Early Morning'
        WHEN DATEPART(HOUR, consumption_date) < 8  THEN 'Morning'
        WHEN DATEPART(HOUR, consumption_date) < 12 THEN 'Late Morning'
        WHEN DATEPART(HOUR, consumption_date) < 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, consumption_date) < 20 THEN 'Evening'
        ELSE 'Night'
    END
ORDER BY total_watch_time_minutes DESC;

--Which platform is used mostly to consume the content
SELECT A.platform,CAST(ROUND((COUNT(*)*1.00 /(SELECT COUNT(*) FROM consumption_data))*100,2) AS FLOAT) AS Sessions_perc
FROM consumption_data AS A
GROUP BY A.platform

--Which Content has brought the most number of users.
SELECT A.content_id,COUNT(DISTINCT A.userid)  AS Cnt_User
FROM consumption_data AS A
INNER JOIN subscription_data AS B
ON A.userid = B.user_id 
   AND CAST(A.consumption_date AS DATE) <= DATEADD(DAY,2,B.subscription_created_date)
GROUP BY A.content_id
ORDER BY Cnt_User DESC

--Which content got the highest views within 1 week of adding it to the platform
SELECT c.content_id, COUNT(*) AS views_first_7_days FROM consumption_data cd
INNER JOIN catalogue_data c
ON cd.content_id = c.content_id
WHERE cd.consumption_date >= c.date_added AND cd.consumption_date < DATEADD(DAY, 7, c.date_added)
GROUP BY c.content_id
ORDER BY views_first_7_days DESC;



--Catalogue data
/*
Total Content duration
Avg Content duration
Indian vs Foreign Content(%)
Live vs Relegated Content(%)
Access Level of Content(%)

MOM Content added vs relegated on the platform 

Which content got highest views on the same day added to the platform
Which content got highest views within 1 week of adding it to the platform


*/

--Total Content duration
--Avg Content duration
-- Total & Average Content duration (rounded)
SELECT ROUND(SUM(CAST(REPLACE(a.duration, 'min', '') AS FLOAT)) / 60.0,2) AS Total_Content_duration_hrs,
ROUND(AVG(CAST(REPLACE(a.duration, 'min', '') AS FLOAT)),2) AS Avg_Content_duration_mins
FROM catalogue_data AS A
WHERE A.status = 'LIVE';

--Indian vs Foreign Content(%)
SELECT
    CASE WHEN country LIKE '%India%' THEN 'Indian' ELSE 'Foreign' END AS content_origin,COUNT(*) AS content_count,
    CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),2) AS DECIMAL(5,2)) AS content_percentage
FROM catalogue_data
WHERE status = 'LIVE'
GROUP BY
    CASE WHEN country LIKE '%India%' THEN 'Indian' ELSE 'Foreign' END
ORDER BY content_percentage DESC;

--Live vs Relegated Content(%)
SELECT
    CASE WHEN status = 'LIVE' THEN 'Live' ELSE 'Relegated' END AS content_status,COUNT(*) AS content_count, 
    CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),2) AS DECIMAL(5,2)) AS content_percentage
FROM catalogue_data
GROUP BY
    CASE WHEN status = 'LIVE' THEN 'Live' ELSE 'Relegated' END
ORDER BY content_percentage DESC;

-- Access Level of Content (%)
SELECT accesslevel AS access_level,COUNT(*) AS content_count,
    CAST(ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),2) AS DECIMAL(5,2)) AS content_percentage
FROM catalogue_data
WHERE status = 'LIVE'
GROUP BY accesslevel
ORDER BY content_percentage DESC;

--MOM Content added vs relegated on the platform 
SELECT
    YEAR(date_added) AS yr,
    MONTH(date_added) AS mn,
    SUM(CASE WHEN status = 'LIVE' THEN 1 ELSE 0 END) AS content_added,
    SUM(CASE WHEN status = 'RELEGATED' THEN 1 ELSE 0 END) AS content_relegated
FROM catalogue_data
WHERE date_added IS NOT NULL
GROUP BY YEAR(date_added), MONTH(date_added)
ORDER BY yr, mn;

--Which content got highest views on the same day added to the platform
SELECT c.content_id,COUNT(*) AS same_day_views FROM consumption_data c
INNER JOIN catalogue_data cat
ON c.content_id = cat.content_id
WHERE CAST(c.consumption_date AS DATE) = CAST(cat.date_added AS DATE)
GROUP BY c.content_id
ORDER BY same_day_views DESC;

--Which content got highest views within 1 week of adding it to the platform
SELECT c.content_id,COUNT(*) AS views_within_7_days FROM consumption_data c
INNER JOIN catalogue_data cat
ON c.content_id = cat.content_id
WHERE
    CAST(c.consumption_date AS DATE)BETWEEN CAST(cat.date_added AS DATE) AND DATEADD(DAY, 7, CAST(cat.date_added AS DATE))
GROUP BY c.content_id
ORDER BY views_within_7_days DESC;

