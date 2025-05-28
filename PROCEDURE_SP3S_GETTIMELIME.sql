CREATE PROCEDURE SP3S_GETTIMELIME
(
 @cStart varchar(10),
 @cEnd varchar(10),
 @cFrom varchar(10),
 @cToDt varchar(10)
)

AS
BEGIN


DECLARE @nHour int, @nMinute int, @cDayStart varchar(4), @cDayEnd varchar(40)
SET @nHour = 1
SET @nMinute = 0
SET @cDayStart = @cStart
SET @cDayEnd = @cEnd

DECLARE @dSDate datetime, @dEDate datetime, @dDateCtr datetime, @dSTime datetime   
SET @dSDate = @cFrom
SET @dDateCtr = @dSDate 
SET @dEDate = DATEADD(ss, -1, DATEADD(dd, 1, @dSDate ))

DECLARE @tblTime TABLE ( dStime datetime, dEtime datetime )  
SET @dSTime = @dSDate 
SET @dDateCtr = DATEADD(hh, CAST(LEFT(@cDayStart,2) AS int), @dSDate)
SET @dDateCtr = DATEADD(mi, CAST(SUBSTRING(@cDayStart,3,2) AS int), @dDateCtr)
INSERT @tblTime VALUES ( DATEADD(ss, 1, @dSTime), @dDateCtr )

WHILE @dDateCtr <= @dEDate
BEGIN
    SET @dSTime = @dDateCtr
    IF @nHour > 0 
       SET @dDateCtr = DATEADD(hh, @nHour, @dDateCtr)

    IF @nMinute > 0  
       SET @dDateCtr = DATEADD(mi, @nMinute, @dDateCtr)

    IF LEFT(dbo.FN_GetTime( @dDateCtr ),4) > @cDayEnd 
        BREAK
    Else
       INSERT @tblTime VALUES ( DATEADD(ss, 1, @dSTime), @dDateCtr )
End 
INSERT @tblTime VALUES ( DATEADD(ss, 1, @dSTime), @dEDate ) 

DECLARE @slsrf TABLE (Dept_name varchar(100),emp_name varchar(100), xn_dt datetime, xn_time datetime, xn_id varchar(40), xn_qty numeric(10,2), xn_net numeric(10,2) ) 

INSERT @slsrf (Dept_name,emp_name, xn_dt, xn_time, xn_id, xn_qty, xn_net ) 
select loc_view.dept_name,employee.emp_name,	cm_dt, cm_time, d.cm_id, 
         SUM(Quantity) AS xn_qty,  
         SUM(rfnet) AS xn_net
FROM cmd01106 A (NOLOCK)
JOin Cmm01106  d (NOLOCK) on A.cm_id = d.cm_id  LEFT OUTER JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE 
 LEFT OUTER JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE = ARTICLE.ARTICLE_CODE 

LEFT OUTER JOIN loc_view  (NOLOCK) ON d.location_Code  =  loc_view.DEPT_ID 
LEFT OUTER JOIN employee  (NOLOCK) ON a.emp_code =  employee.emp_code where d.cm_dt BETWEEN @cFrom AND @cToDt
GROUP BY loc_view.dept_name,emp_name,cm_dt, cm_time, d.cm_id

select dept_name,emp_name,xn_dt,datename(dw,xn_dt)as dt_name,  
       LEFT(dbo.FN_GetTime( dStime ),4) + '-' + LEFT(dbo.FN_GetTime( dEtime ),4)as TimeLine, 
       SUM(case when dbo.FN_GetTime( xn_time ) between dbo.FN_GetTime( dStime ) and dbo.FN_GetTime( dEtime ) then 1 else 0 end ) AS bill_count,
       SUM(case when dbo.FN_GetTime( xn_time ) between dbo.FN_GetTime( dStime ) and dbo.FN_GetTime( dEtime ) then xn_qty else 0 end ) AS bill_qty,
       SUM(case when dbo.FN_GetTime( xn_time ) between dbo.FN_GetTime( dStime ) and dbo.FN_GetTime( dEtime ) then xn_net else 0 end ) AS bill_amount
from @slsrf, @tblTime
group by dept_name,emp_name,xn_dt, dStime, dETime

select dept_name,emp_name,xn_dt,datename(dw,xn_dt)as dt_name,
       LEFT(dbo.FN_GetTime( dEtime ),4)as TimeLine,  
       SUM(case when dbo.FN_GetTime( xn_time ) <= dbo.FN_GetTime( dEtime ) then 1 else 0 end ) AS bill_count, 
       SUM(case when dbo.FN_GetTime( xn_time ) <= dbo.FN_GetTime( dEtime ) then xn_qty else 0 end ) AS bill_qty,
       SUM(case when dbo.FN_GetTime( xn_time ) <= dbo.FN_GetTime( dEtime ) then xn_net else 0 end ) AS bill_amount
from @slsrf, @tblTime
group by dept_name,emp_name,xn_dt, dStime, dETime 

 End