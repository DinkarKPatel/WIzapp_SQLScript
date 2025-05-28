
CREATE PROC SP3S_CHECKPMTVIEWMISMATCH
(
 @cDt varchar(10)='',
 @cPmtTable varchar(100)=''
)
As
Begin


Declare @CCMD NVARCHAR(4000)

SET @CPMTTABLE='PMT01106'

IF OBJECT_ID ('TEMDB..#ReportStock','U') IS NOT NULL
DROP TABLE  #ReportStock

IF OBJECT_ID ('TEMDB..#PMTStock','U') IS NOT NULL
DROP TABLE  #PMTStock


select dept_id,BIN_ID , product_code, sum(case when xn_type in ('PFI', 'WSR', 'APR', 'CHI', 'WPR', 'OPS', 'DCI', 'SCF', 'PUR', 'UNC', 'SLR',
'JWR','DNPR','TTM','API','PRD', 'PFG', 'BCG','MRP','PSB','JWR','MIR','GRNPSIN') 
then 1 else -1 end * xn_qty) CBSQty
into #ReportStock
from VW_XNSREPS (nolock)
where  xn_type not in ('TRI', 'TRO') --xn_dt <= @cDt and
AND BIN_ID <>'999'
group by dept_id, product_code,BIN_ID
having sum(case when xn_type in ('PFI', 'WSR', 'APR', 'CHI', 'WPR', 'OPS', 'DCI', 'SCF', 'PUR', 'UNC', 'SLR',
'JWR','DNPR','TTM','API','PRD', 'PFG', 'BCG','MRP','PSB','JWR','MIR','GRNPSIN') 
then 1 else -1 end * xn_qty)<>0

select dept_id,BIN_ID, product_code, quantity_in_stock CBSQty
into #PMTStock from  pmt01106 (nolock) where 1=2

SET @CCMD = N'select dept_id,BIN_ID, product_code, sum(quantity_in_stock) CBSQty
from '+@cPmtTable + ' (nolock)
where BIN_ID <>''999''
group by dept_id, product_code,BIN_ID
having sum(quantity_in_stock)<>0'

INSERT #PMTStock (dept_id,BIN_ID, product_code, CBSQty)
EXEC SP_EXECUTESQL @CCMD

--select a.PRODUCT_CODE ,b.product_code ,a.CBSQty as rstock ,b.CBSQty as pmt
--from #ReportStock a full join #PMTStock b on a.DEPT_ID = b.dept_id and a.PRODUCT_CODE = b.product_code
--where a.DEPT_ID is null or b.dept_id is null or isnull(a.cbsqty, 0) <> isnull(b.cbsqty, 0)


IF  OBJECT_ID('PMTDIFF','U') IS NOT NULl
DROP TABLE PMTDIFF

select a.dept_id,a.PRODUCT_CODE AS VIEW_PRODUCT_CODE ,b.product_code as pmt_PRODUCT_CODE,b.dept_id as pmt_dept_id,
A.BIN_ID AS VIEW_BIN_ID ,B.BIN_ID AS PMT_BIN_ID ,a.CBSQty as VIEW_STOCK ,b.CBSQty as PMT_STOCK INTO PMTDIFF
from #ReportStock a full join #PMTStock b on a.DEPT_ID = b.dept_id and a.PRODUCT_CODE = b.product_code AND A.BIN_ID =B.BIN_ID 
join sku s (nolock) on s.product_code =case when isnull(a.product_code,'')<>'' then a.PRODUCT_CODE else b.product_code end
join  article art (nolock) on art.article_code=s.article_code 
where (a.DEPT_ID is null or b.dept_id is null or isnull(a.cbsqty, 0) <> isnull(b.cbsqty, 0))
and  isnull(art.stock_na ,0)=0



UPDATE a set report_blocked=0 from location a with (rowlock)
UPDATE a set report_blocked=1 
from location a (nolock)
join PMTDIFF b on a.dept_id = ISNULL(b.dept_id,B.pmt_dept_id )


END




