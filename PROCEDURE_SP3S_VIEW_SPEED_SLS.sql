CREATE PROCEDURE SP3S_VIEW_SPEED_SLS
(
 @dFromDate datetime, 
 @dToDate datetime,
 @cLocID VARCHAR(5)=''
)
AS
BEGIN
-- Summary
if object_id('tempdb..#temp', 'u') is not null DROP TABLE #TEMP
--GO
if object_id('tempdb..#temp1', 'u') is not null DROP TABLE #TEMP1
--GO
if object_id('tempdb..#temp2', 'u') is not null drop table #temp2
--GO
--declare @dFromDate datetime, @dToDate datetime
--set @dFromDate = convert(date, getdate())
--set @dToDate = convert(date, getdate())
--select datename(dw, @dFromDate), sum(net_amount) TotalSale, count(*) BillCount from cmm01106 (nolock) where CONVERT(DATE, cm_dt) between @dFromDate and @dToDate 
select location_Code LocId, sum(net_amount) TotalSale, count(*) BillCount 
into #temp2
from cmm01106 (nolock) 
where CONVERT(DATE, cm_dt) between @dFromDate and @dToDate --and cm_time > '2020-12-12 17:35:00'
AND location_Code =(CASE WHEN ISNULL(@cLocID,'')='' THEN location_Code ELSE @cLocID END)
group by location_Code
--select top 10 cm_dt, cm_time from cmm01106 (nolock) where convert(date, cm_dt) = convert(date, getdate())
SELECT a.cm_id,
datepart(SS, UPLOAD_END_TIME-UPLOAD_START_TIME) UPLOADTIME,
datepart(SS, BEFORESAVE_END_TIME-BEFORESAVE_START_TIME) BEFORESAVETIME,
datepart(SS, AFTERSAVE_END_TIME-AFTERSAVE_START_TIME) AFTERSAVETIME
INTO #TEMP
FROM sls_xnsavelog_summary (NOLOCK) a join cmm01106 (nolock) b on a.cm_id = b.cm_id
WHERE (CONVERT(DATE, UPLOAD_START_TIME) between @dFromDate and @dToDate AND a.CM_ID IS NOT NULL)
AND location_Code=(CASE WHEN ISNULL(@cLocID,'')='' THEN location_Code ELSE @cLocID END)
--and cm_time > '2020-12-12 17:35:00'
--GO
SELECT 
LEFT(CM_ID, 2) LOCATIONID,
SUM(1) TOTALBILLS, 
AVG(BEFORESAVETIME + AFTERSAVETIME) AVGTIMEPERBILL,
AVG(UPLOADTIME) Uploadtime, AVG(BEFORESAVETIME) BeforeSave, AVG(AFTERSAVETIME) AfterSave,
SUM(CASE WHEN BEFORESAVETIME + AFTERSAVETIME <= 5 THEN 1 ELSE 0 END) UpTo5Seconds, 
SUM(CASE WHEN BEFORESAVETIME + AFTERSAVETIME between 6 AND 10 THEN 1 ELSE 0 END) [6-10Seconds], 
SUM(CASE WHEN BEFORESAVETIME + AFTERSAVETIME between 11 AND 15 THEN 1 ELSE 0 END) [11-15Seconds], 
SUM(CASE WHEN BEFORESAVETIME + AFTERSAVETIME between 16 AND 20 THEN 1 ELSE 0 END) [16-20Seconds], 
SUM(CASE WHEN BEFORESAVETIME + AFTERSAVETIME >20 THEN 1 ELSE 0 END) [MoreThan20Seconds]
INTO #TEMP1
FROM #TEMP
GROUP BY LEFT(CM_ID, 2)
ORDER BY 1

SELECT LOCATIONID, BillCount, 
TotalSale, 
--TOTALBILLS, 
AVGTIMEPERBILL, --Uploadtime, BeforeSave, AfterSave,
UpTo5Seconds,CONVERT(VARCHAR, CONVERT(NUMERIC(10, 0), CONVERT(NUMERIC(10, 0), UpTo5Seconds)/CONVERT(NUMERIC(10, 0), TOTALBILLS)*100))+'%' [UpTo5Seconds%], 
[6-10Seconds], CONVERT(VARCHAR, CONVERT(NUMERIC(10, 0), CONVERT(NUMERIC, [6-10Seconds])/CONVERT(NUMERIC, TOTALBILLS)*100))+'%' [6-10Seconds%], 
[11-15Seconds], CONVERT(VARCHAR, CONVERT(NUMERIC(10, 0), CONVERT(NUMERIC, [11-15Seconds])/CONVERT(NUMERIC, TOTALBILLS)*100))+'%' [11-15Seconds%], 
[16-20Seconds], CONVERT(VARCHAR, CONVERT(NUMERIC(10, 0), CONVERT(NUMERIC, [16-20Seconds])/CONVERT(NUMERIC, TOTALBILLS)*100))+'%' [16-20Seconds%], 
[MoreThan20Seconds], CONVERT(VARCHAR, CONVERT(NUMERIC(10, 0), CONVERT(NUMERIC, [MoreThan20Seconds])/CONVERT(NUMERIC, TOTALBILLS)*100))+'%' [MoreThan20Seconds%]
FROM #TEMP1 a left join #temp2 b on a.LOCATIONID = b.LocId
order by LOCATIONID

--Detailed

SELECT top 500 b.cm_no, last_update,
datediff(SS, UPLOAD_START_TIME, UPLOAD_END_TIME) UPLOADTIME,
datediff(SS, BEFORESAVE_START_TIME, BEFORESAVE_END_TIME) BEFORESAVETIME,
datediff(SS, AFTERSAVE_START_TIME, AFTERSAVE_END_TIME) AFTERSAVETIME, 
datediff(SS, BEFORESAVE_START_TIME, BEFORESAVE_END_TIME) + datediff(SS, AFTERSAVE_START_TIME, AFTERSAVE_END_TIME) TOTAL
FROM sls_xnsavelog_summary (NOLOCK) a join cmm01106 (nolock) b on a.cm_id = b.cm_id
WHERE (CONVERT(DATE, UPLOAD_START_TIME) =convert(date, getdate()) AND a.CM_ID IS NOT NULL)
AND location_Code=(CASE WHEN ISNULL(@cLocID,'')='' THEN location_Code ELSE @cLocID END)
--and left(cm_no, 2) = '07'
order by last_update desc
END