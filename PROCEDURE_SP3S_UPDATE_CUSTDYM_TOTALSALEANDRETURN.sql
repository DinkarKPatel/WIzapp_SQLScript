CREATE PROCEDURE SP3S_UPDATE_CUSTDYM_TOTALSALEANDRETURN
AS
BEGIN

DECLARE @dtSummary TABLE(mobile varchar(20),totalsale NUMERIC(14,2),totalreturn NUMERIC(14,2))

INSERT INTO @dtSummary (mobile,totalsale,totalreturn)
select mobile ,SUM(CASE WHEN QUANTITY>0 THEN QUANTITY ELSE 0 END) as totalsale  ,SUM(CASE WHEN QUANTITY<0 THEN QUANTITY ELSE 0 END) as totalreturn
from cmd01106 a (NOLOCK)
JOIN cmm01106 b  (NOLOCK) On b.cm_id=a.cm_id
join custdym c (NOLOCK) ON c.customer_code=b.CUSTOMER_CODE
where  b.CANCELLED=0 AND b.cm_dt>getdate()-365
and c.customer_code<>'000000000000'
AND ISNULL(MOBILE,'')<>''
GROUP BY MOBILE


UPDATE a SET a.totalsale= b.totalsale,a.totalreturn=b.totalreturn,a.returnpercentage=ABS(CASE WHEN ISNULL(b.totalsale,0)<>0 THEN CONVERT (NUMERIC(5,2),(ISNULL(b.totalreturn,0) *100)/ISNULL(b.totalsale,0)) ELSE 0 END)
--SELECT a.mobile, totalsale =ISNULL(b.totalsale,0), totalreturn=ISNULL(b.totalreturn,0),returnpercentage=ABS(CASE WHEN ISNULL(b.totalsale,0)<>0 THEN CONVERT (NUMERIC(5,2),(ISNULL(b.totalreturn,0) *100)/ISNULL(b.totalsale,0)) ELSE 0 END)
FROM custdym a (NOLOCK)
JOIN @dtSummary b on b.mobile=a.mobile

END