--Cleaning Data

--Total Records = 541922
--Total Records without customerId = 135093
--Total Records with customerId = 406829

;With online_retail as
(
	SELECT [InvoiceNo]
		  ,[StockCode]
		  ,[Description]
		  ,[Quantity]
		  ,[InvoiceDate]
		  ,[UnitPrice]
		  ,[CustomerID]
		  ,[Country]
	  FROM [Cohort].[dbo].[CohortAnalysis]
	  WHERE CustomerID != 0
 )
 , quantity_unit_price as
 (

	 -- Total Records with quantity and unit price details  = 397882
	select *
	from online_retail
	where Quantity >0 and UnitPrice > 0
)
, duplicate_check as
(   --Duplicate Records Check
	select * , ROW_NUMBER() over(partition by InvoiceNo, StockCode, Quantity Order by InvoiceDate ) dup_flag
	from quantity_unit_price
)

--Cleaned Unique records = 392668
--Duplicate records = 5214
select *
into #online_retail_main
from duplicate_check
where dup_flag =1

--Data Cleaned and Starting Cohort Analysis
select * from #online_retail_main

--Unique Identifier (customerId)
--Intital start date (First Invoice Date)
--Revenue Data

select
  CustomerID,
  MIN(InvoiceDate)	First_Purchase_Date,
  DATEFROMPARTS(year(MIN(InvoiceDate)),MONTH(MIN(InvoiceDate)), 1) Cohort_Date
into #cohort
from #online_retail_main
group by CustomerID

select *
from #cohort

-- create cohort index
select
	mmm.*,
	cohort_index = year_diff * 12 + month_diff +1
into #cohort_retention
from
	(		
		select
			mm.*,
			year_diff  = invoice_year - cohort_year,
			month_diff = invoice_month - cohort_month
		from(
			select
			   m.*,
			   c.Cohort_Date,
			   year(m.InvoiceDate) invoice_year,
			   MONTH(m.InvoiceDate) invoice_month,
			   year(c.Cohort_Date) cohort_year,
			   month(c.Cohort_Date) cohort_month
			from #online_retail_main m
			left join #cohort c
			on m.CustomerID = c.CustomerID
		) mm
	)mmm

---Pivot Data to see the cohort table

select 	*
into #cohort_pivot
from(
	select distinct 
		CustomerID,
		Cohort_Date,
		cohort_index
	from #cohort_retention
)tbl
pivot(
	Count(CustomerID)
	for Cohort_Index In 
		(
		[1], 
        [2], 
        [3], 
        [4], 
        [5], 
        [6], 
        [7],
		[8], 
        [9], 
        [10], 
        [11], 
        [12],
		[13])

)as pivot_table

select *
from #cohort_pivot
order by Cohort_Date

select Cohort_Date ,
	(1.0 * [1]/[1] * 100) as [1], 
    1.0 * [2]/[1] * 100 as [2], 
    1.0 * [3]/[1] * 100 as [3],  
    1.0 * [4]/[1] * 100 as [4],  
    1.0 * [5]/[1] * 100 as [5], 
    1.0 * [6]/[1] * 100 as [6], 
    1.0 * [7]/[1] * 100 as [7], 
	1.0 * [8]/[1] * 100 as [8], 
    1.0 * [9]/[1] * 100 as [9], 
    1.0 * [10]/[1] * 100 as [10],   
    1.0 * [11]/[1] * 100 as [11],  
    1.0 * [12]/[1] * 100 as [12],  
	1.0 * [13]/[1] * 100 as [13]
from #cohort_pivot
order by Cohort_Date