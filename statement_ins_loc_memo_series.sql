DECLARE @CCURDEPTID VARCHAR(5)/*Rohit 01-11-2024*/,@CHODEPTID VARCHAR(5)/*Rohit 01-11-2024*/

SELECT TOP 1 @CCURDEPTID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
SELECT TOP 1 @CHODEPTID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'

IF @CCURDEPTID<>@CHODEPTID
	RETURN

truncate table loc_memo_series

INSERT loc_memo_series	( fin_year, prefix , xn_type, dept_id, min_cm_no ,max_cm_no)
select fin_year,left(cm_no,5) as prefix,'SLS' AS xn_type,left(cm_id,2) as dept_id,min(cm_no),max(cm_no)
from cmm01106 (nolock) where charindex('-',cm_no)=5 AND len(cm_no)=12 
group by left(cm_no,5),left(cm_id,2),fin_year

INSERT loc_memo_series	( fin_year, prefix , xn_type, dept_id, min_cm_no ,max_cm_no)
SELECT a.fin_year, a.prefix , a.xn_type, a.dept_id, a.min_cm_no ,a.max_cm_no FROM 
(select fin_year,left(cm_no,5) as prefix,'SLS' AS xn_type,left(cm_id,2) as dept_id,
min(cm_no) min_cm_no,max(cm_no) max_cm_no
from cmm01106 (nolock) where charindex('-',cm_no)=5 AND len(cm_no)=10
group by left(cm_no,5),left(cm_id,2),fin_year
) a
LEFT OUTER JOIN loc_memo_series b (NOLOCK) ON a.dept_id=b.dept_id AND a.prefix=b.prefix
WHERE b.dept_id IS NULL

INSERT loc_memo_series	( fin_year, prefix , xn_type, dept_id, min_cm_no ,max_cm_no)
select fin_year,left(cm_no,6) as prefix,'SLS' AS xn_type,left(cm_id,2) as dept_id,
min(cm_no) min_cm_no,max(cm_no) max_cm_no
from cmm01106 (nolock) where charindex('-',cm_no)=6 AND len(cm_no)=12
group by left(cm_no,6),left(cm_id,2),fin_year

INSERT loc_memo_series	( fin_year, prefix , xn_type, dept_id, min_cm_no ,max_cm_no)
SELECT a.fin_year, a.prefix , a.xn_type, a.dept_id, a.min_cm_no ,a.max_cm_no FROM 
(select fin_year,left(cm_no,6) as prefix,'SLS' AS xn_type,left(cm_id,2) as dept_id,
min(cm_no) min_cm_no,max(cm_no) max_cm_no
from cmm01106 (nolock) where charindex('-',cm_no)=6 AND len(cm_no)=12
group by left(cm_no,6),left(cm_id,2),fin_year
) a 
LEFT OUTER JOIN loc_memo_series b (NOLOCK) ON a.dept_id=b.dept_id AND a.prefix=b.prefix
WHERE b.dept_id IS NULL

