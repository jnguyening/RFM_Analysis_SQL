-- Inspecting Data
SELECT * FROM dbo.sales_data_sample

-- Checking unique vlaues
SELECT DISTINCT STATUS FROM dbo.sales_data_sample -- nice to plot
SELECT DISTINCT YEAR_ID FROM dbo.sales_data_sample
SELECT DISTINCT PRODUCTLINE FROM dbo.sales_data_sample -- nice to plot
SELECT DISTINCT COUNTRY FROM dbo.sales_data_sample -- nice to plot
SELECT DISTINCT DEALSIZE FROM dbo.sales_data_sample -- nice to plot
SELECT DISTINCT TERRITORY FROM dbo.sales_data_sample -- nice to plot

SELECT DISTINCT MONTH_ID FROM dbo.sales_data_sample
WHERE YEAR_ID = 2003

-- ANALYSIS
---- Let's start by grouping sales by productline
SELECT PRODUCTLINE, SUM(SALES) Revenue
FROM dbo.sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY 2 DESC

SELECT YEAR_ID, SUM(SALES) Revenue
FROM dbo.sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

SELECT DEALSIZE, SUM(SALES) Revenue
FROM dbo.sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC


-- What was the best month for sales in a specific year? How much was earned that month?
SELECT MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM dbo.sales_data_sample
WHERE YEAR_ID = 2004 -- change year to see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC


-- November seems to be the month, what product do they sell in November? Classic Cars
SELECT MONTH_ID, PRODUCTLINE,SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
FROM dbo.sales_data_sample
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 -- change year to see the rest
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC


-- Who is our best customer (this could be best answered with RFM)

DROP TABLE IF EXISTS #rfm 
;WITH rfm as
(
	SELECT
		CUSTOMERNAME,
		SUM(SALES) MonetaryValue,
		AVG(SALES) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) LastOrderDate,
		(SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample) MaxOrderDate,
		DATEDIFF(DD, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM dbo.sales_data_sample)) Recency
	FROM dbo.sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_calc as (

SELECT r.*,
	NTILE(4) OVER(ORDER BY Recency DESC) rfm_recency,
	NTILE(4) OVER(ORDER BY Frequency) rfm_frequency,
	NTILE(4) OVER(ORDER BY MonetaryValue) rfm_monetary
FROM rfm r
)
SELECT 
	c.*, 
	rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) rfm_cell_string
INTO #rfm 
FROM rfm_calc c

SELECT CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary,
	CASE
		WHEN rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) THEN 'lost_customers' -- lost customers
		WHEN rfm_cell_string in (133,134,143,244,334,343,344, 144) THEN 'slipping away, cannot lose' -- big spenders who haven't purchased lately
		WHEN rfm_cell_string in (311,411,331) THEN 'new_customers'
		WHEN rfm_cell_string in (222,223,233,322) THEN 'potential churners'
		WHEN rfm_cell_string in (323,333,321,422,332,432) THEN 'active'
		WHEN rfm_cell_string in (433,434,443,444) THEN 'loyal'
	END rfm_segment
FROM #rfm 

-- What products are most often sold together?
-- SELECT * FROM dbo.sales_data_sample WHERE ORDERNUMBER = 10411

SELECT DISTINCT ORDERNUMBER, STUFF(

	(SELECT ',' + PRODUCTCODE
	FROM dbo.sales_data_sample p
	WHERE ORDERNUMBER in 
		(

			SELECT ORDERNUMBER
			FROM (
				SELECT ORDERNUMBER, COUNT(*) rn
				FROM dbo.sales_data_sample
				WHERE STATUS = 'Shipped'
				GROUP BY ORDERNUMBER
			) m
			WHERE rn = 3
		)
		AND p.ORDERNUMBER = s.ORDERNUMBER
		FOR xml path (''))

		, 1, 1, '') ProductCodes

FROM dbo.sales_data_sample s
ORDER BY 2 DESC

---EXTRAs----
--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [PortfolioDB].[dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc