CREATE PROCEDURE SP3S_GSTR_RECON_2A        
(        
 @cGSTNO  VARCHAR(100),        
 @dtMonth INT,        
 @dtYear  INT        
)        
AS        
BEGIN        
 Declare @dtFromDate DATETIME,@dtToDate Datetime  ,@dtINVDt Datetime        
 Declare @cFromDate VARCHAR(20),@cToDate VARCHAR(20)        
 SET @cToDate=CONVERT(VARCHAR(10),@dtYear)+'-'+CONVERT(VARCHAR(10),@dtMonth)+'-01'        
 SET @dtToDate=CONVERT(DATETIME,@cToDate)        
 --SELECT @dtFromDate, @dtToDate        
 --SELECT DATEADD(DAY,-1,@dtToDate)        
 SET @dtFromDate=DATEADD(DAY,0,DATEADD(MONTH,0,@dtToDate))        
 SET @dtToDate=DATEADD(MONTH,1,@dtFromDate)-1        
 --SELECT @dtFromDate, @dtToDate        
  select @dtINVDt= MIN(CONVERT(DATETIME,fldtr1)) from GSTR2ARECON_TEMP      
    SELECT @dtFromDate=MIN(CONVERT(DATETIME,idt,105)),@dtToDate=MAX(CONVERT(DATETIME,idt,105))  from GSTR2ARECON_TEMP  WHERE idt IS NOT NULL    
 --SELECT @dtFromDate,@dtToDate    
 IF OBJECT_ID('TEMPDB..#MRRLIST','U') IS NOT NULL        
  DROP TABLE #MRRLIST        
        
 IF OBJECT_ID('TEMPDB..#FULL_RECON_1','U') IS NOT NULL        
  DROP TABLE #FULL_RECON_1        
        
 IF OBJECT_ID('TEMPDB..#FULL_RECON_2','U') IS NOT NULL        
  DROP TABLE #FULL_RECON_2        
        
 IF OBJECT_ID('TEMPDB..#MRR_NOT_RECON','U') IS NOT NULL        
  DROP TABLE #MRR_NOT_RECON        
        
        
 IF OBJECT_ID('TEMPDB..#GST2A_NOT_RECON','U') IS NOT NULL        
  DROP TABLE #GST2A_NOT_RECON        
        
        
        
        
;WITH PIM        
AS        
(        
SELECT c.dept_Id,c.dept_name,c.loc_gst_no,b.ac_name,b.Ac_gst_no, a.MRR_ID,a.mrr_no,inv_no,INV_DT,bill_dt,bill_no,a.receipt_dt,a.AC_CODE,TOTAL_AMOUNT   ,a.INV_MODE      
,ISNULL(a.freight,0) as freight ,ISNULL(a.FREIGHT_TAXABLE_VALUE,0) AS FREIGHT_TAXABLE_VALUE  ,ISNULL(a.freight_cgst_amount,0) AS freight_cgst_amount,
ISNULL(a.freight_sgst_amount,0) AS freight_sgst_amount,ISNULL(a.freight_igst_amount,0) AS freight_igst_amount  
,ISNULL(a.other_charges,0) as other_charges,ISNULL(a.OTHER_CHARGES_TAXABLE_VALUE,0) AS OTHER_CHARGES_TAXABLE_VALUE ,ISNULL(a.other_charges_cgst_amount,0) AS other_charges_cgst_amount,
ISNULL(a.other_charges_sgst_amount,0) AS other_charges_sgst_amount,ISNULL(a.other_charges_igst_amount,0) AS other_charges_igst_amount  
FROM pim01106 a        
JOIN LMV01106 b ON B.AC_CODE=a.ac_code        
JOIN LOCATION C ON C.dept_id=(CASE WHEN ISNULL(a.Pur_For_Dept_id,'') ='' THEN    a.location_Code ELSE      a.Pur_For_Dept_id END)  
WHERE A.CANCELLED=0  AND ISNULL(b.Ac_gst_no,'')<>'' AND a.bill_challan_mode<>1        
AND c.loc_gst_no=@cGSTNO        AND B.Ac_gst_no<> @cGSTNO          
/*  
AND (ISNULL(a.inv_dt,'') BETWEEN @dtFromDate AND @dtToDate)   
Raised by: Ved Pal  
Ticket ID: 0524-01881  
Subject: Gst 2B Recon.  
Remarks: Sir gst2b m 2B-Purchase Invoice(Third Tab) m jo 2B m h aur purchase m nahi unko Supplier name , Gst no,Bill date,Bill no and Invoice amt check karna h CDNR ki bhi reco. karni h  
Raised at: 2024-05-30T19:31:02.623000  
*/  
/*  
AND INV_MODE=1  
Raised by: Ved Pal  
Ticket ID: 0524-01254  
Subject: Gst2B Recon  
Remarks: Sir Group Purchase ko bhi consider karna n  
Raised at: 2024-05-20T18:34:05.960000  
*/  
--a.BILL_DT>='2017-07-01' --AND a.BILL_DT<='2022-05-31'        
--AND a.inv_dt>=@dtINVDt      
--AND  bill_no='SX/TI2425-000016'    
)        
,PID        
AS        
(        
 SELECT PID01106.mrr_id,gst_percentage,SUM(xn_value_with_gst) AS AMOUNT,SUM(xn_value_without_gst) AS TAXABLE_AMOUNT,          
 SUM(igst_amount)  AS igst_amount  
 ,SUM(cgst_amount) AS cgst_amount  
 ,SUM(sgst_amount) AS sgst_amount          
 FROM PID01106          
 JOIN PIM ON PIM.mrr_id=PID01106.mrr_id   
 WHERE PIM.INV_MODE=1  
 GROUP BY PID01106.MRR_ID,gst_percentage    
 UNION  
 SELECT P.mrr_id,gst_percentage,SUM(xn_value_with_gst) AS AMOUNT,SUM(xn_value_without_gst) AS TAXABLE_AMOUNT,          
  SUM(igst_amount) AS igst_amount  
 ,SUM(cgst_amount) AS cgst_amount  
 ,SUM(sgst_amount) AS sgst_amount               
 FROM IND01106  N        
 JOIN PIM01106 P ON P.inv_id=N.INV_ID    
 JOIN PIM ON  PIM.mrr_id=P.mrr_id    
 WHERE PIM.INV_MODE=2  
 GROUP BY p.MRR_ID,gst_percentage     
)        
SELECT a.* ,gst_percentage,AMOUNT+a.freight+a.other_charges+a.freight_igst_amount+a.other_charges_igst_amount+a.freight_cgst_amount+a.other_charges_cgst_amount+a.freight_sgst_amount+a.other_charges_sgst_amount as AMOUNT  
,TAXABLE_AMOUNT+a.FREIGHT_TAXABLE_VALUE+a.OTHER_CHARGES_TAXABLE_VALUE  AS TAXABLE_AMOUNT,  
igst_amount+a.freight_igst_amount+a.other_charges_igst_amount igst_amount,cgst_amount+a.freight_cgst_amount+a.other_charges_cgst_amount AS cgst_amount  
,sgst_amount      +a.freight_sgst_amount+a.other_charges_sgst_amount AS sgst_amount      
INTO #MRRLIST        
FROM PIM a        
JOIN PID b ON a.mrr_id=b.mrr_id        
ORDER BY A.MRR_ID        
        
--SELECT * FROM #MRRLIST        
        
--DROP TABLE #FULL_RECON        
SELECT a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,A.MRR_ID,MRR_NO,INV_NO,INV_DT,BILL_DT,BILL_NO, GST_PERCENTAGE,AMOUNT,TAXABLE_AMOUNT,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,        
CAST(B.inum AS VARCHAR(100)) INUM,CAST(B.VAL AS VARCHAR(100)) VAL,CAST(B.RT AS VARCHAR(100)) RT,CAST(B.txval AS VARCHAR(100)) TXVAL,        
CAST(B.IAMT AS VARCHAR(100)) IAMT,CAST(B.samt AS VARCHAR(100)) SAMT,CAST(B.camt AS VARCHAR(100))  CAMT,CAST(B.IDT AS varchar(100)) IDT,cast(1 as int) recon        
,b.ctin        
INTO #FULL_RECON_1        
FROM #MRRLIST a        
LEFT OUTER JOIN GSTR2ARECON_TEMP b ON b.ctin=a.Ac_gst_no       and a.gst_percentage=b.rt    
WHERE a.total_amount =b.val  AND a.inv_dt=CONVERT(DATETIME,b.idt,105)     
--AND 1=2        
        
select * from GSTR2ARECON_TEMP        
        
SELECT  a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,a.mrr_id,a.mrr_no ,a.inv_no,a.INV_DT,a.bill_dt,a.bill_no, a.gst_percentage,a.AMOUNT,a.TAXABLE_AMOUNT,a.igst_amount,a.cgst_amount,a.sgst_amount,        
CAST(B.inum AS VARCHAR(100)) INUM,CAST(B.VAL AS VARCHAR(100)) VAL,CAST(B.RT AS VARCHAR(100)) RT,CAST(B.txval AS VARCHAR(100)) TXVAL,        
CAST(B.IAMT AS VARCHAR(100)) IAMT,CAST(B.samt AS VARCHAR(100)) SAMT,CAST(B.camt AS VARCHAR(100))  CAMT,CAST(B.IDT AS varchar(100)) IDT,cast(1 as int) recon        
,b.ctin        
INTO #FULL_RECON_2        
FROM #MRRLIST a        
LEFT OUTER JOIN #FULL_RECON_1 c ON C.mrr_id=a.mrr_id        
LEFT OUTER JOIN GSTR2ARECON_TEMP b ON b.ctin=a.Ac_gst_no       and a.gst_percentage=b.rt    
WHERE a.bill_no=CAST(b.inum AS VARCHAR(100)) AND c.mrr_id IS NULL          
    
--SELECT * from #FULL_RECON_1    
--select * from #FULL_RECON_2    
SELECT  a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,a.mrr_id,a.mrr_no ,a.inv_no,a.INV_DT,a.bill_dt,a.bill_no, a.gst_percentage,a.AMOUNT,a.TAXABLE_AMOUNT,a.igst_amount,a.cgst_amount,a.sgst_amount,        
CAST(NULL AS VARCHAR(100)) inum,CAST(NULL AS VARCHAR(100)) val,CAST(NULL AS VARCHAR(100)) rt,CAST(NULL AS VARCHAR(100)) txval,CAST(NULL AS VARCHAR(100)) iamt,CAST(NULL AS VARCHAR(100)) samt,        
CAST(NULL AS VARCHAR(100))camt,CAST(NULL AS varchar(100)) idt,cast(2 as int) recon        
,'' AS ctin        
INTO #MRR_NOT_RECON        
FROM #MRRLIST a        
LEFT OUTER JOIN #FULL_RECON_1 c ON C.mrr_id=a.mrr_id        
LEFT OUTER JOIN #FULL_RECON_2 b ON b.mrr_id=a.mrr_id        
WHERE c.mrr_id IS NULL AND b.mrr_id IS NULL        
        
SELECT CAST(NULL AS VARCHAR(100)) dept_Id,CAST(NULL AS VARCHAR(100)) dept_name,CAST(NULL AS VARCHAR(100)) loc_gst_no,CAST(NULL AS VARCHAR(100)) ac_name,
CAST(NULL AS VARCHAR(100))  AC_GST_NO,CAST(NULL AS VARCHAR(100))  mrr_id,CAST(NULL AS VARCHAR(100))  mrr_no ,CAST(NULL AS VARCHAR(100))  inv_no,CAST(NULL AS datetime)  INV_DT,        
CAST(NULL AS datetime) bill_dt,CAST(NULL AS VARCHAR(100))  bill_no, CAST(NULL AS NUMERIC(14,2))  gst_percentage,CAST(NULL AS NUMERIC(14,2))  AMOUNT,CAST(NULL AS NUMERIC(14,2))  TAXABLE_AMOUNT,        
CAST(NULL AS NUMERIC(14,2))  igst_amount,CAST(NULL AS NUMERIC(14,2))  cgst_amount,CAST(NULL AS NUMERIC(14,2))  sgst_amount,        
CAST(b.inum AS VARCHAR(100)) INUM,CAST(B.VAL AS VARCHAR(100)) VAL,CAST(B.RT AS VARCHAR(100)) RT,CAST(B.txval AS VARCHAR(100)) TXVAL,        
CAST(B.IAMT AS VARCHAR(100)) IAMT,CAST(B.samt AS VARCHAR(100)) SAMT,CAST(B.camt AS VARCHAR(100))  CAMT,CAST(B.IDT AS varchar(100)) IDT,cast(3 as int) recon        
,b.ctin        
INTO #GST2A_NOT_RECON        
FROM GSTR2ARECON_TEMP b        
LEFT OUTER JOIN #MRRLIST c ON b.ctin=c.Ac_gst_no AND c.total_amount=b.val AND c.inv_dt=CONVERT(DATETIME,b.idt,105)    and c.gst_percentage=b.rt       
LEFT OUTER JOIN #MRRLIST bb ON b.ctin=bb.Ac_gst_no AND bb.bill_no=CAST(b.inum AS VARCHAR(100))       and bb.gst_percentage=b.rt    
WHERE c.mrr_id IS NULL AND bb.mrr_id IS NULL        
        
select dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,        
inum,val,rt,txval,iamt,samt,camt,idt ,recon        
from #FULL_RECON_1        
UNION ALL        
select dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no, inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,        
inum,val,rt,txval,iamt,samt,camt,idt ,recon         
from #FULL_RECON_2        
--UNION ALL        
select dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no, inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,        
inum,val,rt,txval,iamt,samt,camt,idt ,recon        
from #MRR_NOT_RECON        
--UNION ALL        
select dept_Id,dept_name,loc_gst_no,LM.ac_name,LMP.AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,        
inum,val,rt,txval,iamt,samt,camt,idt ,recon        
from #GST2A_NOT_RECON A        
JOIN LMP01106 LMP ON LMP.Ac_gst_no=A.ctin        
JOIN LM01106 LM ON LM.AC_CODE=LMP.ac_code  
WHERE LM.inactive=0     
UNION ALL        
select dept_Id,dept_name,loc_gst_no,LMP.TCD_ac_name AS ac_name,LMP.TCD_Ac_gst_no AS AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,        
inum,val,rt,txval,iamt,samt,camt,idt ,recon        
from #GST2A_NOT_RECON A        
JOIN TAXPRO_CLIENT_DETAILS LMP ON LMP.TCD_Ac_gst_no =A.ctin    
LEFT OUTER JOIN LMP01106 LM ON LM.Ac_gst_no=LMP.TCD_Ac_gst_no       
WHERE LM.AC_CODE IS NULL  
        
END        
/*  
CREATE PROCEDURE SP3S_GSTR_RECON_2A  
(  
 @cGSTNO  VARCHAR(100),  
 @dtMonth INT,  
 @dtYear  INT  
)  
AS  
BEGIN  
 Declare @dtFromDate DATETIME,@dtToDate Datetime  
 Declare @cFromDate VARCHAR(20),@cToDate VARCHAR(20)  
 SET @cToDate=CONVERT(VARCHAR(10),@dtYear)+'-'+CONVERT(VARCHAR(10),@dtMonth)+'-01'  
 SET @dtToDate=CONVERT(DATETIME,@cToDate)  
 --SELECT @dtFromDate, @dtToDate  
 --SELECT DATEADD(DAY,-1,@dtToDate)  
 SET @dtFromDate=DATEADD(DAY,0,DATEADD(MONTH,0,@dtToDate))  
 SET @dtToDate=DATEADD(MONTH,1,@dtFromDate)-1  
 --SELECT @dtFromDate, @dtToDate  
  
  
 IF OBJECT_ID('TEMPDB..#MRRLIST','U') IS NOT NULL  
  DROP TABLE #MRRLIST  
  
 IF OBJECT_ID('TEMPDB..#FULL_RECON_1','U') IS NOT NULL  
  DROP TABLE #FULL_RECON_1  
  
 IF OBJECT_ID('TEMPDB..#FULL_RECON_2','U') IS NOT NULL  
  DROP TABLE #FULL_RECON_2  
  
 IF OBJECT_ID('TEMPDB..#MRR_NOT_RECON','U') IS NOT NULL  
  DROP TABLE #MRR_NOT_RECON  
  
  
 IF OBJECT_ID('TEMPDB..#GST2A_NOT_RECON','U') IS NOT NULL  
  DROP TABLE #GST2A_NOT_RECON  
  
  
  
  
;WITH PIM  
AS  
(  
SELECT c.dept_Id,c.dept_name,c.loc_gst_no,b.ac_name,b.Ac_gst_no, a.MRR_ID,a.mrr_no,inv_no,INV_DT,bill_dt,bill_no,a.receipt_dt,a.AC_CODE,TOTAL_AMOUNT  
FROM pim01106 a  
JOIN LMV01106 b ON B.AC_CODE=a.ac_code  
JOIN LOCATION C ON C.dept_id=a.Pur_For_Dept_id  
WHERE A.CANCELLED=0 AND INV_MODE=1 AND ISNULL(b.Ac_gst_no,'')<>'' AND a.bill_challan_mode<>1  
AND c.loc_gst_no=@cGSTNO  
AND (a.BILL_DT BETWEEN @dtFromDate AND @dtToDate) --a.BILL_DT>='2017-07-01' --AND a.BILL_DT<='2022-05-31'  
)  
,PID  
AS  
(  
 SELECT PID01106.mrr_id,gst_percentage,SUM(xn_value_with_gst) AS AMOUNT,SUM(xn_value_without_gst) AS TAXABLE_AMOUNT,  
 SUM(igst_amount) igst_amount,SUM(cgst_amount) AS cgst_amount,SUM(sgst_amount) AS sgst_amount  
 FROM PID01106  
 JOIN PIM ON PIM.mrr_id=PID01106.mrr_id  
 GROUP BY PID01106.MRR_ID,gst_percentage  
)  
SELECT a.* ,gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount  
INTO #MRRLIST  
FROM PIM a  
JOIN PID b ON a.mrr_id=b.mrr_id  
ORDER BY A.MRR_ID  
  
--SELECT * FROM #MRRLIST  
  
--DROP TABLE #FULL_RECON  
SELECT a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,A.MRR_ID,MRR_NO,INV_NO,INV_DT,BILL_DT,BILL_NO, GST_PERCENTAGE,AMOUNT,TAXABLE_AMOUNT,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,  
CAST(B.inum AS VARCHAR(100)) INUM,CAST(B.VAL AS VARCHAR(100)) VAL,CAST(B.RT AS VARCHAR(100)) RT,CAST(B.txval AS VARCHAR(100)) TXVAL,  
CAST(B.IAMT AS VARCHAR(100)) IAMT,CAST(B.samt AS VARCHAR(100)) SAMT,CAST(B.camt AS VARCHAR(100))  CAMT,CAST(B.IDT AS varchar(100)) IDT,cast(1 as int) recon  
,b.ctin  
INTO #FULL_RECON_1  
FROM #MRRLIST a  
LEFT OUTER JOIN GSTR2ARECON_TEMP b ON b.ctin=a.Ac_gst_no  
WHERE a.total_amount =b.val  AND a.inv_dt=CONVERT(DATETIME,b.idt,105)  
--AND 1=2  
  
select * from GSTR2ARECON_TEMP  
  
SELECT  a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,a.mrr_id,a.mrr_no ,a.inv_no,a.INV_DT,a.bill_dt,a.bill_no, a.gst_percentage,a.AMOUNT,a.TAXABLE_AMOUNT,a.igst_amount,a.cgst_amount,a.sgst_amount,  
CAST(B.inum AS VARCHAR(100)) INUM,CAST(B.VAL AS VARCHAR(100)) VAL,CAST(B.RT AS VARCHAR(100)) RT,CAST(B.txval AS VARCHAR(100)) TXVAL,  
CAST(B.IAMT AS VARCHAR(100)) IAMT,CAST(B.samt AS VARCHAR(100)) SAMT,CAST(B.camt AS VARCHAR(100))  CAMT,CAST(B.IDT AS varchar(100)) IDT,cast(1 as int) recon  
,b.ctin  
INTO #FULL_RECON_2  
FROM #MRRLIST a  
LEFT OUTER JOIN #FULL_RECON_1 c ON C.mrr_id=a.mrr_id  
LEFT OUTER JOIN GSTR2ARECON_TEMP b ON b.ctin=a.Ac_gst_no  
WHERE a.bill_no=CAST(b.inum AS VARCHAR(100)) AND c.mrr_id IS NULL  
  
SELECT  a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,a.mrr_id,a.mrr_no ,a.inv_no,a.INV_DT,a.bill_dt,a.bill_no, a.gst_percentage,a.AMOUNT,a.TAXABLE_AMOUNT,a.igst_amount,a.cgst_amount,a.sgst_amount,  
CAST(NULL AS VARCHAR(100)) inum,CAST(NULL AS VARCHAR(100)) val,CAST(NULL AS VARCHAR(100)) rt,CAST(NULL AS VARCHAR(100)) txval,CAST(NULL AS VARCHAR(100)) iamt,CAST(NULL AS VARCHAR(100)) samt,  
CAST(NULL AS VARCHAR(100))camt,CAST(NULL AS varchar(100)) idt,cast(2 as int) recon  
,'' AS ctin  
INTO #MRR_NOT_RECON  
FROM #MRRLIST a  
LEFT OUTER JOIN #FULL_RECON_1 c ON C.mrr_id=a.mrr_id  
LEFT OUTER JOIN #FULL_RECON_2 b ON b.mrr_id=a.mrr_id  
WHERE c.mrr_id IS NULL AND b.mrr_id IS NULL  
  
SELECT CAST(NULL AS VARCHAR(100)) dept_Id,CAST(NULL AS VARCHAR(100)) dept_name,CAST(NULL AS VARCHAR(100)) loc_gst_no,CAST(NULL AS VARCHAR(100)) ac_name,CAST(NULL AS VARCHAR(100))  AC_GST_NO,CAST(NULL AS VARCHAR(100))  mrr_id,CAST(NULL AS VARCHAR(100))  mr
r_no ,CAST(NULL AS VARCHAR(100))  inv_no,CAST(NULL AS datetime)  INV_DT,  
CAST(NULL AS datetime) bill_dt,CAST(NULL AS VARCHAR(100))  bill_no, CAST(NULL AS NUMERIC(14,2))  gst_percentage,CAST(NULL AS NUMERIC(14,2))  AMOUNT,CAST(NULL AS NUMERIC(14,2))  TAXABLE_AMOUNT,  
CAST(NULL AS NUMERIC(14,2))  igst_amount,CAST(NULL AS NUMERIC(14,2))  cgst_amount,CAST(NULL AS NUMERIC(14,2))  sgst_amount,  
CAST(b.inum AS VARCHAR(100)) INUM,CAST(B.VAL AS VARCHAR(100)) VAL,CAST(B.RT AS VARCHAR(100)) RT,CAST(B.txval AS VARCHAR(100)) TXVAL,  
CAST(B.IAMT AS VARCHAR(100)) IAMT,CAST(B.samt AS VARCHAR(100)) SAMT,CAST(B.camt AS VARCHAR(100))  CAMT,CAST(B.IDT AS varchar(100)) IDT,cast(3 as int) recon  
,b.ctin  
INTO #GST2A_NOT_RECON  
FROM GSTR2ARECON_TEMP b  
LEFT OUTER JOIN #MRRLIST c ON b.ctin=c.Ac_gst_no AND c.total_amount=b.val AND c.inv_dt=CONVERT(DATETIME,b.idt,105)  
LEFT OUTER JOIN #MRRLIST bb ON b.ctin=bb.Ac_gst_no AND bb.bill_no=CAST(b.inum AS VARCHAR(100))  
WHERE c.mrr_id IS NULL AND bb.mrr_id IS NULL  
  
select dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,  
inum,val,rt,txval,iamt,samt,camt,idt ,recon  
from #FULL_RECON_1  
UNION ALL  
select dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no, inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,  
inum,val,rt,txval,iamt,samt,camt,idt ,recon   
from #FULL_RECON_2  
UNION ALL  
select dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no, inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,  
inum,val,rt,txval,iamt,samt,camt,idt ,recon  
from #MRR_NOT_RECON  
UNION ALL  
select dept_Id,dept_name,loc_gst_no,LM.ac_name,LMP.AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,  
inum,val,rt,txval,iamt,samt,camt,idt ,recon  
from #GST2A_NOT_RECON A  
JOIN LMP01106 LMP ON LMP.Ac_gst_no=A.ctin  
JOIN LM01106 LM ON LM.AC_CODE=LMP.ac_code  
UNION ALL  
select dept_Id,dept_name,loc_gst_no,LMP.TCD_ac_name AS ac_name,LMP.TCD_Ac_gst_no AS AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,  
inum,val,rt,txval,iamt,samt,camt,idt ,recon  
from #GST2A_NOT_RECON A  
JOIN TAXPRO_CLIENT_DETAILS LMP ON LMP.TCD_Ac_gst_no =A.ctin  
  
END  
*/  
--go  
--EXEC SP3S_GSTR_RECON_2A @cGSTNO='08AABCB0639G1ZZ', @dtMonth=5,@dtYear=2022
/*ALTER PROCEDURE SP3S_GSTR_RECON_2A      
(      
 @cGSTNO  VARCHAR(100),      
 @dtMonth VARCHAR(4),      
 @dtYear  VARCHAR(4),
 @dtCutOffDate DATETIME=''
)      
AS      
BEGIN      
 --Declare @dtFromDate DATETIME,@dtToDate Datetime  ,@dtINVDt Datetime      
 --Declare @cFromDate VARCHAR(20),@cToDate VARCHAR(20)      
 --SET @cToDate=CONVERT(VARCHAR(10),@dtYear)+'-'+CONVERT(VARCHAR(10),@dtMonth)+'-01'      
 --SET @dtToDate=CONVERT(DATETIME,@cToDate)      
 ----SELECT @dtFromDate, @dtToDate      
 ----SELECT DATEADD(DAY,-1,@dtToDate)      
 --SET @dtFromDate=DATEADD(DAY,0,DATEADD(MONTH,0,@dtToDate))      
 --SET @dtToDate=DATEADD(MONTH,1,@dtFromDate)-1      
 ----SELECT @dtFromDate, @dtToDate      
 -- select @dtINVDt= MIN(CONVERT(DATETIME,fldtr1)) from GSTR_DOWNLOADED_DATA    
 --   SELECT @dtFromDate=MIN(CONVERT(DATETIME,idt,105)),@dtToDate=MAX(CONVERT(DATETIME,idt,105))  from GSTR_DOWNLOADED_DATA  WHERE idt IS NOT NULL  
 ----SELECT @dtFromDate,@dtToDate  
 IF OBJECT_ID('TEMPDB..#MRRLIST','U') IS NOT NULL      
  DROP TABLE #MRRLIST      
      
 IF OBJECT_ID('TEMPDB..#FULL_RECON_1','U') IS NOT NULL      
  DROP TABLE #FULL_RECON_1      
      
 IF OBJECT_ID('TEMPDB..#FULL_RECON_2','U') IS NOT NULL      
  DROP TABLE #FULL_RECON_2      
      
 IF OBJECT_ID('TEMPDB..#MRR_NOT_RECON','U') IS NOT NULL      
  DROP TABLE #MRR_NOT_RECON      
      
      
 IF OBJECT_ID('TEMPDB..#GST2A_NOT_RECON','U') IS NOT NULL      
  DROP TABLE #GST2A_NOT_RECON      
      
      
      
      
;WITH PIM      
AS      
(      
SELECT c.dept_Id,c.dept_name,c.loc_gst_no,b.ac_name,b.Ac_gst_no, a.MRR_ID,a.mrr_no,inv_no,INV_DT,bill_dt,bill_no,a.receipt_dt,a.AC_CODE,TOTAL_AMOUNT   ,a.INV_MODE    
,ISNULL(a.freight,0) as freight ,ISNULL(a.FREIGHT_TAXABLE_VALUE,0) AS FREIGHT_TAXABLE_VALUE  ,ISNULL(a.freight_cgst_amount,0) AS freight_cgst_amount,ISNULL(a.freight_sgst_amount,0) AS freight_sgst_amount,ISNULL(a.freight_igst_amount,0) AS freight_igst_amount
,ISNULL(a.other_charges,0) as other_charges,ISNULL(a.OTHER_CHARGES_TAXABLE_VALUE,0) AS OTHER_CHARGES_TAXABLE_VALUE ,ISNULL(a.other_charges_cgst_amount,0) AS other_charges_cgst_amount,ISNULL(a.other_charges_sgst_amount,0) AS other_charges_sgst_amount,ISNULL(a.other_charges_igst_amount,0) AS other_charges_igst_amount
FROM pim01106 a      
JOIN LMV01106 b ON B.AC_CODE=a.ac_code      
JOIN LOCATION C ON C.dept_id=(CASE WHEN ISNULL(a.Pur_For_Dept_id,'') ='' THEN    LEFT(a.MRR_ID,2) ELSE      a.Pur_For_Dept_id END)
WHERE A.CANCELLED=0  AND ISNULL(b.Ac_gst_no,'')<>'' AND a.bill_challan_mode<>1      
AND c.loc_gst_no=@cGSTNO        AND B.Ac_gst_no<> @cGSTNO       
AND ISNULL(a.inv_dt,'')>@dtCutOffDate
/*
AND (ISNULL(a.inv_dt,'') BETWEEN @dtFromDate AND @dtToDate) 
Raised by: Ved Pal
Ticket ID: 0524-01881
Subject: Gst 2B Recon.
Remarks: Sir gst2b m 2B-Purchase Invoice(Third Tab) m jo 2B m h aur purchase m nahi unko Supplier name , Gst no,Bill date,Bill no and Invoice amt check karna h CDNR ki bhi reco. karni h
Raised at: 2024-05-30T19:31:02.623000
*/
/*
AND INV_MODE=1
Raised by: Ved Pal
Ticket ID: 0524-01254
Subject: Gst2B Recon
Remarks: Sir Group Purchase ko bhi consider karna n
Raised at: 2024-05-20T18:34:05.960000
*/
--a.BILL_DT>='2017-07-01' --AND a.BILL_DT<='2022-05-31'      
--AND a.inv_dt>=@dtINVDt    
--AND  bill_no='SX/TI2425-000016'  
)      
,PID      
AS      
(      
 SELECT PID01106.mrr_id,gst_percentage,SUM(xn_value_with_gst) AS AMOUNT,SUM(xn_value_without_gst) AS TAXABLE_AMOUNT,        
 SUM(igst_amount)  AS igst_amount
 ,SUM(cgst_amount) AS cgst_amount
 ,SUM(sgst_amount) AS sgst_amount        
 FROM PID01106        
 JOIN PIM ON PIM.mrr_id=PID01106.mrr_id 
 WHERE PIM.INV_MODE=1
 GROUP BY PID01106.MRR_ID,gst_percentage  
 UNION
 SELECT P.mrr_id,gst_percentage,SUM(xn_value_with_gst) AS AMOUNT,SUM(xn_value_without_gst) AS TAXABLE_AMOUNT,        
  SUM(igst_amount) AS igst_amount
 ,SUM(cgst_amount) AS cgst_amount
 ,SUM(sgst_amount) AS sgst_amount             
 FROM IND01106  N      
 JOIN PIM01106 P ON P.inv_id=N.INV_ID  
 JOIN PIM ON  PIM.mrr_id=P.mrr_id  
 WHERE PIM.INV_MODE=2
 GROUP BY p.MRR_ID,gst_percentage   
)      
SELECT a.* ,gst_percentage,AMOUNT+a.freight+a.other_charges+a.freight_igst_amount+a.other_charges_igst_amount+a.freight_cgst_amount+a.other_charges_cgst_amount+a.freight_sgst_amount+a.other_charges_sgst_amount as AMOUNT
,TAXABLE_AMOUNT+a.FREIGHT_TAXABLE_VALUE+a.OTHER_CHARGES_TAXABLE_VALUE  AS TAXABLE_AMOUNT,
igst_amount+a.freight_igst_amount+a.other_charges_igst_amount igst_amount,cgst_amount+a.freight_cgst_amount+a.other_charges_cgst_amount AS cgst_amount
,sgst_amount      +a.freight_sgst_amount+a.other_charges_sgst_amount AS sgst_amount    
INTO #MRRLIST      
FROM PIM a      
JOIN PID b ON a.mrr_id=b.mrr_id      
ORDER BY A.MRR_ID      
      
--SELECT * FROM #MRRLIST      
      
--DROP TABLE #FULL_RECON      
SELECT a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,A.MRR_ID,MRR_NO,INV_NO,INV_DT,BILL_DT,BILL_NO, GST_PERCENTAGE,AMOUNT,TAXABLE_AMOUNT,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,      
B.GSTR_inum ,B.GSTR_VAL ,B.GSTR_RT,B.GSTR_txval ,B.GSTR_IAMT ,B.GSTR_samt ,B.GSTR_camt ,B.GSTR_IDT ,cast(1 as int) recon      
,b.GSTR_ctin      ,b.GSTR_chksum
INTO #FULL_RECON_1      
FROM #MRRLIST a      
LEFT OUTER JOIN GSTR_DOWNLOADED_DATA b ON b.GSTR_ctin=a.Ac_gst_no       and a.gst_percentage=b.GSTR_rt  AND B.GSTR_COMPANY_GST_NO=@cGSTNO AND B.GSTR_MonthValue=@dtMonth AND B.GSTR_YearValue=@dtYear
WHERE a.total_amount =b.GSTR_val  AND a.inv_dt=CONVERT(DATETIME,b.GSTR_idt,105)   
--AND 1=2      
      
select * from GSTR_DOWNLOADED_DATA        WHERE GSTR_COMPANY_GST_NO=@cGSTNO AND GSTR_MonthValue=@dtMonth AND GSTR_YearValue=@dtYear
      
SELECT  a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,a.mrr_id,a.mrr_no ,a.inv_no,a.INV_DT,a.bill_dt,a.bill_no, a.gst_percentage,a.AMOUNT,a.TAXABLE_AMOUNT,a.igst_amount,a.cgst_amount,a.sgst_amount,      
B.GSTR_inum ,B.GSTR_VAL ,B.GSTR_RT,B.GSTR_txval ,B.GSTR_IAMT ,B.GSTR_samt ,B.GSTR_camt ,B.GSTR_IDT     
,b.GSTR_ctin      ,b.GSTR_chksum,cast(1 as int) recon  
INTO #FULL_RECON_2      
FROM #MRRLIST a      
LEFT OUTER JOIN #FULL_RECON_1 c ON C.mrr_id=a.mrr_id      
LEFT OUTER JOIN GSTR_DOWNLOADED_DATA b ON b.GSTR_ctin=a.Ac_gst_no       and a.gst_percentage=b.GSTR_rt    AND B.GSTR_COMPANY_GST_NO=@cGSTNO AND  B.GSTR_MonthValue=@dtMonth AND B.GSTR_YearValue=@dtYear
WHERE a.bill_no=CAST(b.GSTR_inum AS VARCHAR(100)) AND c.mrr_id IS NULL        
  
--SELECT * from #FULL_RECON_1  
--select * from #FULL_RECON_2  
SELECT  a.dept_Id,a.dept_name,a.loc_gst_no,a.ac_name,A.AC_GST_NO,a.mrr_id,a.mrr_no ,a.inv_no,a.INV_DT,a.bill_dt,a.bill_no, a.gst_percentage,a.AMOUNT,a.TAXABLE_AMOUNT,a.igst_amount,a.cgst_amount,a.sgst_amount,      
B.GSTR_inum ,B.GSTR_VAL ,B.GSTR_RT,B.GSTR_txval ,B.GSTR_IAMT ,B.GSTR_samt ,B.GSTR_camt ,B.GSTR_IDT     
,b.GSTR_ctin      ,b.GSTR_chksum,cast(2 as int) recon     
INTO #MRR_NOT_RECON      
FROM #MRRLIST a      
LEFT OUTER JOIN #FULL_RECON_1 c ON C.mrr_id=a.mrr_id      
LEFT OUTER JOIN #FULL_RECON_2 b ON b.mrr_id=a.mrr_id      
WHERE c.mrr_id IS NULL AND b.mrr_id IS NULL      
      
SELECT CAST(NULL AS VARCHAR(100)) dept_Id,CAST(NULL AS VARCHAR(100)) dept_name,CAST(NULL AS VARCHAR(100)) loc_gst_no,CAST(NULL AS VARCHAR(100)) ac_name,CAST(NULL AS VARCHAR(100))  AC_GST_NO,CAST(NULL AS VARCHAR(100))  mrr_id,CAST(NULL AS VARCHAR(100))  mrr_no ,CAST(NULL AS VARCHAR(100))  inv_no,CAST(NULL AS datetime)  INV_DT,      
CAST(NULL AS datetime) bill_dt,CAST(NULL AS VARCHAR(100))  bill_no, CAST(NULL AS NUMERIC(14,2))  gst_percentage,CAST(NULL AS NUMERIC(14,2))  AMOUNT,CAST(NULL AS NUMERIC(14,2))  TAXABLE_AMOUNT,      
CAST(NULL AS NUMERIC(14,2))  igst_amount,CAST(NULL AS NUMERIC(14,2))  cgst_amount,CAST(NULL AS NUMERIC(14,2))  sgst_amount,      
B.GSTR_inum ,B.GSTR_VAL ,B.GSTR_RT,B.GSTR_txval ,B.GSTR_IAMT ,B.GSTR_samt ,B.GSTR_camt ,B.GSTR_IDT     
,b.GSTR_ctin      ,b.GSTR_chksum,cast(3 as int) recon   
INTO #GST2A_NOT_RECON      
FROM GSTR_DOWNLOADED_DATA b      
LEFT OUTER JOIN #MRRLIST c ON b.GSTR_ctin=c.Ac_gst_no AND c.total_amount=b.GSTR_val AND c.inv_dt=CONVERT(DATETIME,b.GSTR_idt,105)    and c.gst_percentage=b.GSTR_rt     
LEFT OUTER JOIN #MRRLIST bb ON b.GSTR_ctin=bb.Ac_gst_no AND bb.bill_no=CAST(b.GSTR_inum AS VARCHAR(100))       and bb.gst_percentage=b.GSTR_rt  
WHERE c.mrr_id IS NULL AND bb.mrr_id IS NULL     
  AND B.GSTR_COMPANY_GST_NO=@cGSTNO AND B.GSTR_MonthValue=@dtMonth AND B.GSTR_YearValue=@dtYear
      
select CAST(0 AS BIT) AS MANUAL_RECON, dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,      
GSTR_inum,GSTR_val,GSTR_rt,GSTR_txval,GSTR_iamt,GSTR_samt,GSTR_camt,GSTR_idt       ,GSTR_chksum,GSTR_ctin,recon
from #FULL_RECON_1      
UNION ALL      
select CAST(0 AS BIT) AS MANUAL_RECON,dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no, inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,      
GSTR_inum,GSTR_val,GSTR_rt,GSTR_txval,GSTR_iamt,GSTR_samt,GSTR_camt,GSTR_idt       ,GSTR_chksum,GSTR_ctin,recon
from #FULL_RECON_2      
--UNION ALL      
select CAST(0 AS BIT) AS MANUAL_RECON,dept_Id,dept_name,loc_gst_no,ac_name,AC_GST_NO,mrr_id,mrr_no, inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,      
GSTR_inum,GSTR_val,GSTR_rt,GSTR_txval,GSTR_iamt,GSTR_samt,GSTR_camt,GSTR_idt       ,GSTR_chksum,GSTR_ctin,recon
from #MRR_NOT_RECON      
--UNION ALL      
select CAST(0 AS BIT) AS MANUAL_RECON,dept_Id,dept_name,loc_gst_no,LM.ac_name,LMP.AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,      
GSTR_inum,GSTR_val,GSTR_rt,GSTR_txval,GSTR_iamt,GSTR_samt,GSTR_camt,GSTR_idt       ,GSTR_chksum,GSTR_ctin,recon
from #GST2A_NOT_RECON A      
JOIN LMP01106 LMP ON LMP.Ac_gst_no=A.GSTR_ctin      
JOIN LM01106 LM ON LM.AC_CODE=LMP.ac_code
WHERE LM.inactive=0   
UNION ALL      
select CAST(0 AS BIT) AS MANUAL_RECON,dept_Id,dept_name,loc_gst_no,LMP.TCD_ac_name AS ac_name,LMP.TCD_Ac_gst_no AS AC_GST_NO,mrr_id,mrr_no ,inv_no,INV_DT,bill_dt,bill_no, gst_percentage,AMOUNT,TAXABLE_AMOUNT,igst_amount,cgst_amount,sgst_amount,      
GSTR_inum,GSTR_val,GSTR_rt,GSTR_txval,GSTR_iamt,GSTR_samt,GSTR_camt,GSTR_idt       ,GSTR_chksum,GSTR_ctin,recon
from #GST2A_NOT_RECON A      
JOIN TAXPRO_CLIENT_DETAILS LMP ON LMP.TCD_Ac_gst_no =A.GSTR_ctin  
LEFT OUTER JOIN LMP01106 LM ON LM.Ac_gst_no=LMP.TCD_Ac_gst_no     
WHERE LM.AC_CODE IS NULL
      
END      
*/