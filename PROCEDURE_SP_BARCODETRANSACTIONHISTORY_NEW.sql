CREATE PROCEDURE SP_BARCODETRANSACTIONHISTORY_NEW
(        
  @CPRODUCTCODE VARCHAR(100),        
  @CLOGINDEPTID VARCHAR(4)='',        
  @CDEPTID VARCHAR(4) = '',    
  @FROMDATE DATETIME = '',    
  @TODATE DATETIME = '',    
  @IMODE INT =1,
  @BRTN_CBS BIT =0,
  @BESTIMATE BIT =0,
  @CCANCELLED VARCHAR(10)=0
  /*@BRTN_CBS: WILL DUMP THE CLOSING STOCK OF THE GIVEN BARCODE AT DEPT_ID,BIN_ID LEVEL 
							INTO #BARCODE_CBS STOCK CREATED BY CALLING PROCEDURE.
								This works only with @IMODE = 1*/    
								
)      
--(dinkar) Replace  left(memoid,2) to Location_code 

--WITH ENCRYPTION
AS        
BEGIN  
SET NOCOUNT ON     

 PRINT 'STEP 0:'+convert(varchar,getdate(),113)
 DECLARE @CCURLOCID VARCHAR(4),@CHOLOCID VARCHAR(4),@cCMD NVARCHAR(MAX) ,@CCANCELLEDFILTER1 NVARCHAR(MAX) ,@dOrgFromDt DATETIME
 ,@CCANCELLEDFILTER2 NVARCHAR(MAX) ,@CCANCELLEDFILTER3 NVARCHAR(MAX),@cOptStock VARCHAR(2),@bPickOpsFromPmt BIT ,@cFinYear VARCHAR(10)     
        
 SET @CCURLOCID=@CLOGINDEPTID

 SELECT TOP 1 @CHOLOCID = [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'HO_LOCATION_ID'        
 SELECT TOP 1 @cOptStock = [VALUE] FROM CONFIG WHERE CONFIG_OPTION = 'OPT_STOCK'        
 
 IF @IMODE=4 -- This is done as this mode will be called from Wow Purchase analysis API for showing Xn history for a particular MRR
	SET @CCURLOCID=@CHOLOCID

 SET @bPickOpsFromPmt=0

 IF @CHOLOCID=@CCURLOCID or ISNULL(@cOptStock,'')='1'
	SET @bPickOpsFromPmt=1
 
 IF @IMODE=4
	SELECT @FROMDATE=receipt_dt FROM pim01106 (NOLOCK) WHERE mrr_id=@CPRODUCTCODE

 SET @dOrgFromDt=@FromDate

 IF @bPickOpsFromPmt=0
	SET @FROMDATE=''
	
 

 CREATE TABLE #outputC  ( DEPT_ID VARCHAR(4), XN_TYPE VARCHAR(30), XN_DT DATETIME,         
        XN_ID VARCHAR(40), XN_NO VARCHAR(40), PRODUCT_CODE VARCHAR(50),     
        ARTICLE_NO VARCHAR(500),para1_name VARCHAR(500),para2_name VARCHAR(500),PARA3_NAME VARCHAR(500),            
        XN_PARTY_NAME VARCHAR(500), XN_QTY NUMERIC(10,3),
        XN_EMP_NAME VARCHAR(500), XN_MODE NUMERIC(1,0 ),img_id VARCHAR(100),    
        mrp NUMERIC(10,2),WS_PRICE NUMERIC(10,2),XN_PRICE NUMERIC(10,2),MP_PERCENTAGE NUMERIC(10,2),BIN_ID VARCHAR(10),
        BIN_NAME VARCHAR(100),source_xn_type VARCHAR(20),CANCELLED bit,XN_TIME datetime,er_flag numeric(1,0),xn_da NUMERIC(10,3), xn_net NUMERIC(10,3)) 
        
PRINT 'STEP 0.2:'+convert(varchar,getdate(),113)
SELECT product_code,ws_price,mrp,product_code org_product_code,sn_barcode_coding_scheme barcode_coding_scheme,sku_er_flag er_flag,
       cast(0 as bit) stock_na  
INTO #tmpbarCode FROM sku_names  (NOLOCK) WHERE 1=2

SELECT dept_id INTO #xnLocs FROM location a (NOLOCK) WHERE (dept_id=@CDEPTID AND @CDEPTID<>'') or @CDEPTID=''

PRINT 'STEP 0.4:'+convert(varchar,getdate(),113)

IF @IMODE=4
BEGIN
	INSERT INTO #tmpbarCode (product_Code,mrp,ws_price,org_product_code,barcode_coding_scheme,er_flag) 
	select a.product_code,a.mrp,a.ws_price,a.product_Code,sn_barcode_coding_scheme,sku_er_flag er_flag FROM sku_names a (NOLOCK) 
	JOIN pid01106 b (NOLOCK) ON a.product_Code=b.product_code
	where b.mrr_id=@CPRODUCTCODE	
END
ELSE
IF @imode=1
BEGIN
	INSERT INTO #tmpbarCode (product_Code,mrp,ws_price,org_product_code,barcode_coding_scheme,er_flag) 
	select product_code,mrp,ws_price,@CPRODUCTCODE,sn_barcode_coding_scheme,sku_er_flag er_flag FROM sku_names a (NOLOCK) 
	where A.PRODUCT_CODE= @CPRODUCTCODE

	IF EXISTS (SELECT TOP 1 product_code FROM #tmpbarCode WHERE ISNULL(barcode_coding_scheme,0)=1 AND CHARINDEX('@',product_code)=0)	
		INSERT INTO #tmpbarCode (product_Code,mrp,ws_price,org_product_code,er_flag) 
		select product_code,mrp,ws_price,@CPRODUCTCODE,sku_er_flag er_flag FROM sku_names a (NOLOCK) 
		where LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))= @CPRODUCTCODE
		AND CHARINDEX('@',a.product_Code)>0

END
ELSE
IF @IMODE=2
	INSERT INTO #tmpbarCode (product_Code,mrp,ws_price,org_product_code,er_flag) 
	select product_code,mrp,ws_price,article_no,sku_er_flag er_flag FROM sku_names a (NOLOCK) 
	where article_no=@CPRODUCTCODE
ELSE
	INSERT INTO #tmpbarCode (product_Code,mrp,ws_price,org_product_code,er_flag)  
	select product_code,mrp,ws_price,para3_name ,sku_er_flag er_flag FROM sku_names a (NOLOCK) 
	where para3_name=@CPRODUCTCODE
	
PRINT 'STEP 0.6:'+convert(varchar,getdate(),113)
-- OPS
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag,XN_PARTY_NAME)
	SELECT A.DEPT_ID,            
		'OPS' AS XN_TYPE,        
		'' XN_DT,        
		'OPS' AS XN_ID,        
		'OPS' AS XN_NO,        
		b.org_PRODUCT_CODE,     
      	SUM(A.QUANTITY_OB) AS XN_QTY,        
		'' AS XN_EMP_NAME ,        
		1 AS XN_MODE ,b.WS_PRICE,b.mrp,      
		CONVERT(NUMERIC(10,2) ,0) AS XN_PRICE ,    
		CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
		,B1.BIN_ID,B1.BIN_NAME,'''' AS source_xn_type
		,'' AS xn_time,b.er_flag,'' xn_party_name
	  FROM OPS01106 A (NOLOCK)        
	  JOIN #tmpBarcode b ON a.product_code=b.product_code
	  JOIN #xnLocs xnlocs ON xnlocs.dept_id=a.dept_id
	  JOIN LOCATION L (NOLOCK) ON A.DEPT_ID  = L.DEPT_ID        
	  JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=ISNULL(A.BIN_ID,'000')
	  GROUP BY b.org_product_code,a.dept_id,xn_dt,l.dept_name,b1.bin_id,b1.bin_name ,b.mrp,b.WS_PRICE,b.er_flag
	
	PRINT 'STEP 1:'+convert(varchar,getdate(),113)        
         
 	PRINT 'STEP 2:'+convert(varchar,getdate(),113)               
	 -- DCO      
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code ,            
    'DCO' AS XN_TYPE,        
    B.MEMO_DT AS XN_DT,        
    B.MEMO_ID AS XN_ID,        
    B.MEMO_NO  AS XN_NO,        
    bc.org_PRODUCT_CODE,     
    L.DEPT_NAME AS XN_PARTY_NAME,         
    SUM(A.QUANTITY) AS XN_QTY,        
    '' AS XN_EMP_NAME ,        
    2 AS XN_MODE ,bc.ws_price,bc.mrp,      
    CONVERT(NUMERIC(10,2) ,0) AS XN_PRICE ,    
    CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
    ,B1.BIN_ID,B1.bin_name,'''' AS source_xn_type 
    ,'' AS xn_time,bc.er_flag                          
  FROM FLOOR_ST_DET A (NOLOCK)        
  JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID
   JOIN #tmpBarcode bc ON a.product_code=bc.product_code
  JOIN LOCATION L (NOLOCK) ON b.location_code   = L.DEPT_ID        
  JOIN #xnLocs xnlocs ON xnlocs.dept_id=l.dept_id
  JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=a.source_BIN_ID     
  WHERE b.MEMO_DT BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0
  GROUP BY b.location_code ,memo_dt,B.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,l.dept_name,bc.ws_price,bc.mrp,bc.er_flag

	 PRINT 'STEP 3:'+convert(varchar,getdate(),113)             
		   
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

    SELECT b.location_code ,            
   'DCI' AS XN_TYPE,        
   B.MEMO_DT AS XN_DT,        
   B.MEMO_ID AS XN_ID,        
   B.MEMO_NO  AS XN_NO,        
   bc.org_PRODUCT_CODE,
   L.DEPT_NAME AS XN_PARTY_NAME,         
   sum(A.QUANTITY) AS XN_QTY,        
   '''' AS XN_EMP_NAME ,        
   1 AS XN_MODE ,bc.ws_price,bc.mrp,      
   CONVERT(NUMERIC(10,2) ,0) AS XN_PRICE ,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type
    ,'' AS xn_time,bc.er_flag               
 FROM FLOOR_ST_DET A (NOLOCK)        
 JOIN FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 JOIN LOCATION L (NOLOCK) ON b.location_code  = L.DEPT_ID        
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.ITEM_TARGET_BIN_ID     
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=l.dept_id
 WHERE b.receipt_dt BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0 AND b.receipt_dt<>''
   GROUP BY b.location_code ,memo_dt,B.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,l.dept_name,bc.ws_price,bc.mrp,bc.er_flag

 PRINT 'STEP 4:'+convert(varchar,getdate(),113)              
 -- PURCHASE INVOICE        

   SET @cCmd=N'SELECT b.DEPT_ID,        
   (CASE WHEN b.inv_mode=1 THEN ''PUR'' ELSE ''CHI'' END)AS XN_TYPE,         
   B.RECEIPT_DT AS XN_DT,        
   B.MRR_ID AS XN_ID,         
   B.MRR_NO AS XN_NO,         

   bc.org_PRODUCT_CODE,
   LM.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '''' AS XN_EMP_NAME ,        
   1 AS XN_MODE   ,      
   CONVERT(NUMERIC(10,2),ISNULL(A.WHOLESALE_PRICE,0)) AS WS_PRICE,bc.mrp,      
   A.PURCHASE_PRICE AS XN_PRICE       
   ,A.MP_PERCENTAGE    
   ,B1.BIN_ID,B1.bin_name,''PUR'' AS source_xn_type 
   ,B.MEMO_TIME AS xn_time,bc.er_flag   
	 FROM PID01106 A (NOLOCK)        
	 JOIN PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID        
	JOIN #tmpBarcode bc ON a.product_code=bc.product_code
	 JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=B.AC_CODE        
	 JOIN (SELECT TOP 1 VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION=''HO_LOCATION_ID'') CNF1 ON 1=1      
	 JOIN (SELECT TOP 1 VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION=''LOCATION_ID'') CNF2 ON 1=1    
	 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID      
	 LEFT OUTER JOIN pim01106 pim_ref (NOLOCK) ON pim_ref.ref_converted_mrntobill_mrrid=b.mrr_id
	 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.dept_id
	 WHERE b.receipt_dt BETWEEN '''+convert(varchar,@FROMDATE,110)+''' AND '''+CONVERT(VARCHAR,@TODATE,110)+''' AND   B.CANCELLED=0
	 AND (B.INV_MODE<>2 OR (B.RECEIPT_DT<>'''' AND CNF1.VALUE<>CNF2.VALUE))
	 AND pim_ref.mrr_id IS NULL   '+  
	(CASE WHEN @cCurLocId <> @cHoLocId THEN ' AND (b.mrr_Creation_Dept_id='''+@cCurLocId+''' OR b.location_code='''+@cCurLocId+''' OR B.DEPT_ID= '''+@cCurLocId+''')' ELSE ' ' END)+
	'GROUP BY b.inv_mode,B.RECEIPT_DT , B.MRR_ID,B.MRR_NO,b.dept_id,bc.org_product_code,lm.ac_name,b1.bin_id,b1.bin_name,
	 a.purchase_price,a.mp_percentage,b.inv_mode,b.memo_time,a.wholesale_price,bc.mrp,bc.er_flag'


	 PRINT @cCmd
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
    
	EXEC SP_EXECUTESQL @cCmd

	

	PRINT 'STEP 4.1:'+convert(varchar,getdate(),113)   
	--FOR NEW METHOD OF GROUP INVOICE

	SET @ccmd=N'SELECT b.DEPT_ID,        
	   (CASE WHEN b.inv_mode=1 THEN ''PUR'' ELSE ''CHI'' END)AS XN_TYPE,         
	   B.RECEIPT_DT AS XN_DT,        
	   B.MRR_ID AS XN_ID,         
	   B.MRR_NO AS XN_NO,         
	   bc.org_PRODUCT_CODE,     
	   LM.AC_NAME AS XN_PARTY_NAME,         
	   sum(IND.QUANTITY) AS XN_QTY,        
	   '''' AS XN_EMP_NAME ,        
	   1 AS XN_MODE   ,      
	   CONVERT(NUMERIC(10,2),ISNULL(IND.WS_PRICE,0)) AS WS_PRICE, bc.mrp  ,   
	   IND.NET_RATE AS XN_PRICE       
	   ,IND.margin_percentage AS MP_PERCENTAGE    
	   ,B1.BIN_ID,B1.bin_name,''PUR'' AS source_xn_type 
	   ,B.MEMO_TIME AS xn_time,bc.er_flag   
	 FROM IND01106 IND (NOLOCK)
	 JOIN INM01106 INM (NOLOCK) ON IND.INV_ID =INM.INV_ID    
	 JOIN PIM01106 B (NOLOCK) ON INM.INV_ID = B.INV_ID   
	 JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=B.AC_CODE        
	 JOIN #tmpBarcode bc ON ind.product_code=bc.product_code
	 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.dept_id
	 JOIN (SELECT TOP 1 VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION=''HO_LOCATION_ID'') CNF1 ON 1=1      
	 JOIN (SELECT TOP 1 VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION=''LOCATION_ID'') CNF2 ON 1=1    
	 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID      
	 WHERE b.receipt_dt BETWEEN '''+convert(varchar,@FROMDATE,110)+''' AND '''+CONVERT(VARCHAR,@TODATE,110)+''' AND   B.CANCELLED=0 AND INM.CANCELLED=0
	 AND (B.INV_MODE=2 AND B.RECEIPT_DT<>'''' AND  CNF1.VALUE=CNF2.VALUE ) '+
	(CASE WHEN @cCurLocId <> @cHoLocId THEN ' AND (b.mrr_Creation_Dept_id='''+@cCurLocId+''' OR B.DEPT_ID= '''+@cCurLocId+''')' ELSE ' ' END)+
	'GROUP BY b.dept_id,b.inv_mode,B.RECEIPT_DT ,margin_percentage,ind.ws_price,net_rate, B.MRR_ID,B.MRR_NO, bc.org_product_code,lm.ac_name,b1.bin_id,b1.bin_name,memo_time,bc.mrp,bc.er_flag'

	print @cCMD

   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	EXEC SP_EXECUTESQL @cCMD
 
   PRINT 'STEP 5:'+convert(varchar,getdate(),113) 
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
   SELECT b.location_code  AS DEPT_ID,  
   (CASE WHEN B.DN_TYPE =2 THEN 'FPRT' ELSE 
   (CASE WHEN MODE=2 THEN 'CHO' ELSE 'PRT' END) END)  AS XN_TYPE,         
   B.RM_DT AS XN_DT,        
   B.RM_ID AS XN_ID,        
   B.RM_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,      
   LM.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   2 AS XN_MODE  ,      
   bc.ws_price,bc.mrp,       
   A.PURCHASE_PRICE AS XN_PRICE,      
   CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE      
   ,B1.BIN_ID,B1.bin_name,'PRT' AS source_xn_type 
    ,B.rm_TIME AS xn_time,bc.er_flag
	 FROM RMD01106 A (NOLOCK)        
	 JOIN RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID        
     JOIN #tmpBarcode bc ON a.product_code=bc.product_code
	 JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=B.AC_CODE    
	 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=a.BIN_ID        
	 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
	 WHERE b.rm_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0
	 GROUP BY b.location_code,B.rm_DT,dn_type,mode, B.RM_ID,B.RM_NO,a.purchase_price,rm_time, bc.org_product_code,lm.ac_name,b1.bin_id,b1.bin_name,
	 bc.ws_price,bc.mrp,bc.er_flag

-- RETAIL SALE       
   PRINT 'STEP 6:'+convert(varchar,getdate(),113) 
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag,xn_da,xn_net)

	SELECT b.location_code  AS DEPT_ID,        
    (CASE WHEN (A.QUANTITY) > 0 THEN 'SLS' ELSE 'SLR' END) AS XN_TYPE,         
     B.CM_DT AS XN_DT,        
     B.CM_ID AS XN_ID,         
    B.CM_NO AS XN_NO,        
    bc.org_PRODUCT_CODE,    
     LTRIM(RTRIM(ISNULL(C.CUSTOMER_TITLE,'')+' '+ISNULL(C.CUSTOMER_FNAME,'')+' '+ISNULL(C.CUSTOMER_LNAME,''))) AS XN_PARTY_NAME,         
     SUM(ABS(A.QUANTITY)) AS XN_QTY,        
     E.EMP_NAME AS XN_EMP_NAME ,        
    ( CASE WHEN (A.QUANTITY) > 0 THEN 2 ELSE 1 END) AS XN_MODE,      
     bc.ws_price,bc.mrp,    
  A.MRP AS XN_PRICE,
  sum(a.quantity*a.mrp) AS MP_PERCENTAGE
 ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type
  ,B.cm_TIME AS xn_time,bc.er_flag,sum(a.discount_amount+isnull(a.cmm_discount_amount,0)) xn_da, sum(a.rfnet) xn_net         
 FROM CMD01106 A (NOLOCK)        
 JOIN CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID        
 JOIN CUSTDYM C (NOLOCK) ON C.CUSTOMER_CODE=B.CUSTOMER_CODE        
 LEFT JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE=A.EMP_CODE    
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID                
 WHERE b.cm_dt BETWEEN @FROMDATE AND @TODATE AND  isnull(b.patchup_run,0)=0 and   B.CANCELLED=0
 GROUP BY b.location_code,B.cm_DT, B.cM_ID,B.cM_NO,a.mrp,cm_time,bc.org_product_code,b1.bin_id,LTRIM(RTRIM(ISNULL(C.CUSTOMER_TITLE,'')+' '+ISNULL(C.CUSTOMER_FNAME,'')+
 ' '+ISNULL(C.CUSTOMER_LNAME,''))), b1.bin_name,e.emp_name,bc.ws_price,bc.mrp,bc.er_flag,
  (CASE WHEN (A.QUANTITY) > 0 THEN 'SLS' ELSE 'SLR' END) , ( CASE WHEN (A.QUANTITY) > 0 THEN 2 ELSE 1 END)

    PRINT 'STEP 6.5:'+convert(varchar,getdate(),113) 
-- RETAIL SALE       
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag,xn_da,xn_net)

	SELECT b.location_code  AS DEPT_ID,        
    (CASE WHEN (A.QUANTITY) > 0 THEN 'SLS' ELSE 'SLR' END) AS XN_TYPE,         
     B.CM_DT AS XN_DT,        
     B.CM_ID AS XN_ID,         
    B.CM_NO AS XN_NO,        
    bc.org_PRODUCT_CODE,    
     LTRIM(RTRIM(ISNULL(C.CUSTOMER_TITLE,'')+' '+ISNULL(C.CUSTOMER_FNAME,'')+' '+ISNULL(C.CUSTOMER_LNAME,''))) AS XN_PARTY_NAME,                  
     sum(ABS(A.QUANTITY)) AS XN_QTY,        
     E.EMP_NAME AS XN_EMP_NAME ,        
    ( CASE WHEN (A.QUANTITY) > 0 THEN 2 ELSE 1 END) AS XN_MODE,      
     bc.ws_price,bc.mrp,      
  A.old_MRP AS XN_PRICE,
  SUM(a.quantity*a.old_mrp) AS MP_PERCENTAGE

  ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type
   ,B.cm_TIME AS xn_time,bc.er_flag ,sum(a.discount_amount+isnull(a.cmm_discount_amount,0)) xn_da, sum(a.rfnet) xn_net          
 FROM CMD01106 A (NOLOCK)        
 JOIN CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID        
 JOIN CUSTDYM C (NOLOCK) ON C.CUSTOMER_CODE=B.CUSTOMER_CODE        
 LEFT JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE=A.EMP_CODE    
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID    
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 WHERE b.cm_dt BETWEEN @FROMDATE AND @TODATE AND  isnull(b.patchup_run,0)=1 and B.CANCELLED=0
 GROUP BY b.location_code,B.cm_DT, B.cM_ID,B.cM_NO,a.old_mrp,cm_time,bc.org_product_code,b1.bin_id,LTRIM(RTRIM(ISNULL(C.CUSTOMER_TITLE,'')+' '+ISNULL(C.CUSTOMER_FNAME,'')+' '+ISNULL(C.CUSTOMER_LNAME,''))),
 b1.bin_name,e.emp_name,bc.ws_price,bc.mrp,bc.er_flag, (CASE WHEN (A.QUANTITY) > 0 THEN 'SLS' ELSE 'SLR' END),
 ( CASE WHEN (A.QUANTITY) > 0 THEN 2 ELSE 1 END)
 


	PRINT 'STEP 7.1:'+convert(varchar,getdate(),113) 
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  AS DEPT_ID,        
    (CASE WHEN (A.QUANTITY) > 0 THEN 'SLS' ELSE 'SLR' END) AS XN_TYPE,         
     B.CM_DT AS XN_DT,        
     B.CM_ID AS XN_ID,         
     B.CM_NO AS XN_NO,        
    bc.org_PRODUCT_CODE,     
    ''  AS XN_PARTY_NAME,
     SUM(ABS(A.QUANTITY)) AS XN_QTY,        
     E.EMP_NAME AS XN_EMP_NAME ,        
    ( CASE WHEN (A.QUANTITY) > 0 THEN 2 ELSE 1 END) AS XN_MODE,      
     bc.ws_price,bc.mrp,      
  A.MRP AS XN_PRICE,
  CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE  
  ,B1.BIN_ID,B1.bin_name,'RPS' AS source_xn_type 
   ,B.cm_TIME AS xn_time,bc.er_flag          
 FROM RPS_DET A (NOLOCK)        
 JOIN RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID       
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE=A.EMP_CODE    
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID    
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.cm_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0
 AND ISNULL(B.REF_CM_ID,'')=''
 GROUP BY b.location_code,B.cm_DT, B.cM_ID,B.cM_NO,a.mrp,cm_time,bc.org_product_code,b1.bin_id,b1.bin_name,e.emp_name,a.mrp,bc.ws_price,bc.mrp,bc.er_flag,
 (CASE WHEN (A.QUANTITY) > 0 THEN 'SLS' ELSE 'SLR' END),( CASE WHEN (A.QUANTITY) > 0 THEN 2 ELSE 1 END)
    
	PRINT 'STEP 8:'+convert(varchar,getdate(),113)                   
   	   
 -- APPROVAL ISSUE      
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
    
	SELECT b.location_code  AS DEPT_ID,        
   'APP' AS XN_TYPE,         
   B.MEMO_DT AS XN_DT,        
   B.MEMO_ID AS XN_ID,         
   B.MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,    
   (CASE WHEN B.MEMO_TYPE=1 THEN LTRIM(RTRIM(ISNULL(C.CUSTOMER_TITLE,'')+' '+ISNULL(C.CUSTOMER_FNAME,'')+' '+      
   ISNULL(C.CUSTOMER_LNAME,''))) ELSE D.AC_NAME END) AS XN_PARTY_NAME,         
   SUM(ABS(A.QUANTITY)) AS XN_QTY,        
   E.EMP_NAME AS XN_EMP_NAME ,        
   2 AS XN_MODE   ,bc.ws_price,bc.mrp,      
   A.MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE                
   ,B1.BIN_ID,B1.bin_name,'APP' AS source_xn_type  
    ,B.MEMO_TIME AS xn_time,bc.er_flag
 FROM APD01106 A (NOLOCK)        
 JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID        
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 JOIN CUSTDYM C (NOLOCK) ON C.CUSTOMER_CODE=B.CUSTOMER_CODE        
 JOIN LM01106 D (NOLOCK) ON D.AC_CODE=B.AC_CODE       
 JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE=A.EMP_CODE     
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID    
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.memo_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0
 GROUP BY b.location_code,memo_type, B.memo_DT, B.memo_ID,B.memo_NO,a.mrp,memo_time,bc.org_product_code,b1.bin_id,
 (CASE WHEN B.MEMO_TYPE=1 THEN LTRIM(RTRIM(ISNULL(C.CUSTOMER_TITLE,'')+' '+ISNULL(C.CUSTOMER_FNAME,'')+' '+      
   ISNULL(C.CUSTOMER_LNAME,''))) ELSE D.AC_NAME END), b1.bin_name,e.emp_name,bc.ws_price,bc.mrp,bc.er_flag

         
  PRINT 'STEP 9:'+convert(varchar,getdate(),113)             
-- APPROVAL RETURN        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT mst.location_code  AS DEPT_ID,      
   'APR' AS XN_TYPE,      
   MST.MEMO_DT AS XN_DT,      
   MST.MEMO_ID AS XN_ID,       
   MST.MEMO_NO AS XN_NO,      
   bc.org_product_code,
   LTRIM(RTRIM(ISNULL(d.CUSTOMER_TITLE,'')+' '+ISNULL(d.CUSTOMER_FNAME,'')+' '+      
   ISNULL(d.CUSTOMER_LNAME,''))) AS XN_PARTY_NAME,         
   SUM(ABS(A.QUANTITY)) AS XN_QTY,      
   F.EMP_NAME AS XN_EMP_NAME,      
   1 AS XN_MODE ,bc.ws_price,bc.mrp,    
   bc.mrp AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE                
   ,B1.BIN_ID,B1.bin_name,'APR' AS source_xn_type 
    ,MST.memo_time AS xn_time,bc.er_flag 
 FROM APPROVAL_RETURN_DET A (NOLOCK)      
 JOIN APPROVAL_RETURN_MST MST (NOLOCK)ON  MST.MEMO_ID = A.MEMO_ID    
  JOIN #tmpBarcode bc ON a.apd_product_code=bc.product_code
 JOIN CUSTDYM D (NOLOCK) ON D.CUSTOMER_CODE=MST.CUSTOMER_CODE      
 JOIN LM01106 E (NOLOCK) ON E.AC_CODE=MST.AC_CODE      
 JOIN EMPLOYEE F (NOLOCK) ON F.EMP_CODE=a.EMP_CODE     
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID       
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=mst.location_code 
 WHERE mst.memo_dt BETWEEN @FROMDATE AND @TODATE AND  MST.cancelled=0
 GROUP BY mst.location_Code, memo_DT, mst.memo_ID,memo_NO,bc.mrp,memo_time,bc.org_product_code,b1.bin_id,LTRIM(RTRIM(ISNULL(d.CUSTOMER_TITLE,'')+' '+ISNULL(d.CUSTOMER_FNAME,'')+' '+ISNULL(d.CUSTOMER_LNAME,''))),
 b1.bin_name,f.emp_name,mst.memo_time,bc.ws_price,bc.mrp,bc.er_flag
     
 PRINT 'STEP 10:'+convert(varchar,getdate(),113)            
     
-- CANCELLATION AND STOCK ADJUSTMENT        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  AS DEPT_ID,        
   (CASE WHEN B.CNC_TYPE=1 THEN 'CNC' ELSE 'UNC' END) AS XN_TYPE,         
   B.CNC_MEMO_DT AS XN_DT,        
   B.CNC_MEMO_ID AS XN_ID,        
   B.CNC_MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   '' AS XN_PARTY_NAME,         
   sum(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   (CASE WHEN B.CNC_TYPE =1 THEN 2 ELSE 1 END) AS XN_MODE   ,      
   bc.ws_price,bc.mrp,      
   A.RATE AS XN_PRICE,      
   CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'CNC' AS source_xn_type
   ,B.CNC_TIME AS xn_time,bc.er_flag                
	 FROM ICD01106 A (NOLOCK)        
	 JOIN ICM01106 B (NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID
	  JOIN #tmpBarcode bc ON a.product_code=bc.product_code
	 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID     
	JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
	WHERE b.cnc_memo_dt BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0
	AND B.STOCK_ADJ_NOTE = 0 
	 GROUP BY  b.location_code,CNC_TYPE,B.cnc_memo_DT, B.cnc_memo_ID,B.cnc_memo_NO,a.rate,cnc_time,bc.org_product_code,b1.bin_id,b1.bin_name,cnc_time,bc.ws_price,bc.mrp,bc.er_flag

	 PRINT 'STEP 11:'+convert(varchar,getdate(),113)              
 --WHOLESALE INVOICE        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag,xn_da,xn_net)

   SELECT b.location_Code,
   (CASE WHEN B.INV_MODE=2 THEN 'CHO' ELSE 
   (CASE WHEN B.BIN_TRANSFER=1 THEN 'APO' ELSE 'WSL' END) 
    END) AS XN_TYPE,        
   B.INV_DT AS XN_DT,        
   B.INV_ID AS XN_ID,        
   B.INV_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,      
   C.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   E.EMP_NAME AS XN_EMP_NAME ,        
   2 AS XN_MODE ,      
   bc.WS_PRICE , bc.mrp,     
   A.RATE AS XN_PRICE,      
   CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'WSL' AS source_xn_type
     ,B.INV_TIME AS xn_time,bc.er_flag ,sum(a.discount_amount+isnull(a.inmdiscountamount,0)) xn_da, sum(a.rfnet) xn_net                              
 FROM IND01106 A (NOLOCK)        
 JOIN INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID        
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE        
 LEFT OUTER JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE = B.EMP_CODE     
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID       
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.inv_dt BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0
 AND ISNULL(B.PENDING_GIT,0)=0
 GROUP BY  INV_MODE,BIN_TRANSFER,b.location_Code, B.inv_DT, B.inv_ID,B.inv_NO,inv_time,bc.org_product_code,b1.bin_id,b1.bin_name,inv_time,a.rate,C.AC_NAME,emp_name,
 bc.ws_price,bc.mrp,bc.er_flag

	PRINT 'STEP 11.1:'+convert(varchar,getdate(),113)              
 --WHOLESALE INVOICE        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

    SELECT (CASE WHEN bin_transfer=1 THEN B.DEPT_ID ELSE b.party_dept_id END) as dept_id,        
		  'API' as xn_type,
		   B.INV_DT AS XN_DT,        
		   B.INV_ID AS XN_ID,        
		   B.INV_NO AS XN_NO,        
		   bc.org_PRODUCT_CODE,      
		   C.AC_NAME AS XN_PARTY_NAME,         
		   SUM(A.QUANTITY) AS XN_QTY,        
		   E.EMP_NAME AS XN_EMP_NAME ,        
		   2 AS XN_MODE ,      
		   bc.ws_price,bc.mrp,      
		   A.RATE AS XN_PRICE,      
		   CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
		   ,B1.BIN_ID,B1.bin_name,'WSL' AS source_xn_type 
		   ,B.INV_TIME AS xn_time,bc.er_flag                              
		 FROM IND01106 A (NOLOCK)        
		 JOIN INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID
		 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
		 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE        
		 LEFT OUTER JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE = B.EMP_CODE     
		 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.TARGET_BIN_ID       
		 JOIN Location loc (NOLOCK) ON loc.dept_id=b.party_dept_id
		 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
		 WHERE b.inv_dt BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0 AND B.BIN_TRANSFER=1
	GROUP BY (CASE WHEN bin_transfer=1 THEN B.DEPT_ID ELSE b.party_dept_id END),B.inv_DT, B.inv_ID,B.inv_NO,inv_time,bc.org_product_code,b1.bin_id,b1.bin_name,inv_time,
	e.emp_name,a.rate,C.AC_NAME,bc.ws_price,bc.mrp,bc.er_flag

	PRINT 'STEP 12:'+convert(varchar,getdate(),113)               
 --WHOLESALE PACKSLIP        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  as dept_id,        
   'WPI'   AS XN_TYPE,     
    B.PS_DT AS XN_DT,          
   B.PS_ID AS XN_ID,          
   B.PS_NO AS XN_NO,          
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,           
   SUM(A.QUANTITY) AS XN_QTY,          
   '' AS XN_EMP_NAME ,          
   2 AS XN_MODE ,bc.ws_price,bc.mrp,        
   A.RATE AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'WPS' AS source_xn_type 
   ,B.ps_created_time AS xn_time,bc.er_flag                                     
 FROM WPS_DET A (NOLOCK)          
 JOIN WPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID        
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE    
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID      
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.ps_dt BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0
 GROUP BY b.location_code, B.ps_DT, B.ps_ID,B.ps_NO,ps_created_time,bc.org_product_code,b1.bin_id,b1.bin_name,ps_created_time,a.rate,C.AC_NAME,bc.ws_price,bc.mrp,bc.er_flag

	PRINT 'STEP 12.3:'+convert(varchar,getdate(),113)              
 --WHOLESALE INVOICE        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

   SELECT b.location_code ,        
   'WPR' AS XN_TYPE,        
   B.INV_DT AS XN_DT,        
   B.INV_ID AS XN_ID,        
   B.INV_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,
   C.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   E.EMP_NAME AS XN_EMP_NAME ,        
   1 AS XN_MODE ,      
   bc.ws_price,bc.mrp,      
   A.RATE AS XN_PRICE,      
   CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'WSL' AS source_xn_type 
   ,B.INV_time AS xn_time,bc.er_flag                              
 FROM wps_det A (NOLOCK)        
 JOIN wps_mst wm (NOLOCK) ON wm.ps_id=a.ps_id
 JOIN INM01106 B (NOLOCK) ON wm.wsl_inv_id = B.INV_ID  
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE     
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 LEFT OUTER JOIN EMPLOYEE E (NOLOCK) ON E.EMP_CODE = B.EMP_CODE     
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID     
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.inv_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0 and wm.cancelled=0
 GROUP BY b.location_code ,B.inv_DT, B.inv_ID,B.inv_NO,INV_time,bc.org_product_code,b1.bin_id,b1.bin_name,INV_time,a.rate,C.AC_NAME,emp_name,
 bc.ws_price,bc.mrp,bc.er_flag




	PRINT 'STEP 12.6:'+convert(varchar,getdate(),113)
--Debit Note PACKSLIP        
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
      
	SELECT b.location_code  as dept_id,        
   'DNPI' AS  XN_TYPE,       
   B.PS_DT AS XN_DT,          
   B.PS_ID AS XN_ID,          
   B.PS_NO AS XN_NO,          
   bc.org_PRODUCT_CODE,
   C.AC_NAME AS XN_PARTY_NAME,           
   SUM(A.QUANTITY) AS XN_QTY,          
   '' AS XN_EMP_NAME ,          
   2 AS XN_MODE ,bc.ws_price,bc.mrp,        
   CONVERT(NUMERIC(10,2) ,0) AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'DNPS' AS source_xn_type 
   ,B.ps_created_time AS xn_time,bc.er_flag                                       
 FROM DNPS_DET A (NOLOCK)          
 JOIN DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID        
  JOIN #tmpBarcode bc ON a.product_code=bc.product_code
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE    
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID    
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.ps_dt BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0
 GROUP BY b.location_code, B.ps_DT, B.ps_ID,B.ps_NO,ps_created_time, bc.org_product_code,b1.bin_id,b1.bin_name,ps_created_time,C.AC_NAME,bc.ws_price,bc.mrp,bc.er_flag

	PRINT 'STEP 12.8:'+convert(varchar,getdate(),113)
--Debit Note PACKSLIP        
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
      
	SELECT b.location_code  as dept_id,        
   'CNPI' AS  XN_TYPE,       
   B.PS_DT AS XN_DT,          
   B.PS_ID AS XN_ID,          
   B.PS_NO AS XN_NO,          
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,           
   SUM(A.QUANTITY) AS XN_QTY,          
   '' AS XN_EMP_NAME ,          
   1 AS XN_MODE ,bc.ws_price,bc.mrp,        
   CONVERT(NUMERIC(10,2) ,0) AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'CNPS' AS source_xn_type 
   ,B.ps_created_time AS xn_time,bc.er_flag                                       
	 FROM CNPS_DET A (NOLOCK)          
	 JOIN CNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID     
	JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
	 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE    
	 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=a.BIN_ID 
	JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
	 WHERE b.ps_dt BETWEEN @FROMDATE AND @TODATE AND  B.CANCELLED=0
   GROUP BY b.location_Code, B.ps_DT, B.ps_ID,B.ps_NO,ps_created_time,bc.org_product_code,b1.bin_id,b1.bin_name,ps_created_time,C.AC_NAME,bc.ws_price,bc.mrp,bc.er_flag
       
	 PRINT 'STEP 13:'+convert(varchar,getdate(),113)              
 --WHOLESALE CREDIT NOTE        

   SET @cCmd=N'SELECT b.location_code AS DEPT_ID,        
  (CASE WHEN MODE=2 THEN ''CHI'' 
   ELSE 
   (CASE WHEN (isnull(B.BIN_TRANSFER,0)=1 OR B.MODE=3) THEN ''API'' ELSE ''WSR'' END)
   END) AS XN_TYPE,        
  (CASE WHEN MODE=2 THEN B.RECEIPT_DT ELSE B.CN_DT END) AS XN_DT,        
   B.CN_ID AS XN_ID,        
   B.CN_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,         
   sum(A.QUANTITY) AS XN_QTY,        
   '''' AS XN_EMP_NAME ,        
   1 AS XN_MODE   ,bc.ws_price,bc.mrp,      
   A.RATE AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE  
   ,B1.BIN_ID,B1.bin_name,''WSR'' AS source_xn_type  
   ,B.MEMO_TIME AS xn_time,bc.er_flag,sum(a.discount_amount+isnull(a.cnmdiscountamount,0)) xn_da, sum(a.rfnet) xn_net                                  
 FROM CND01106 A (NOLOCK)        
 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID        
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE     
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID  
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.RECEIPT_DT BETWEEN '''+convert(varchar,@FROMDATE,110)+''' AND '''+convert(varchar,@TODATE,110)+''' AND  B.CANCELLED=0 AND B.CN_TYPE<>2 AND (B.MODE<>2 OR B.RECEIPT_DT<>'''')  '
 +(CASE WHEN @cCurLocId <> @cHoLocId THEN ' AND b.location_code ='''+@cCurLocId+'''' ELSE '  ' END)+
 'GROUP BY b.location_code,B.MODE,bin_transfer,(CASE WHEN MODE=2 THEN B.RECEIPT_DT ELSE B.CN_DT END), B.cn_ID,B.cn_NO,memo_time,bc.org_product_code,b1.bin_id,
  b1.bin_name,C.AC_NAME,a.rate,bc.ws_price,bc.mrp,bc.er_flag'
 
 --PRINT @ccmd
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag,xn_da,xn_net)

	EXEC SP_EXECUTESQL @cCMD

	PRINT 'STEP 13.1:'+convert(varchar,getdate(),113)              
 --PURCHASE RETURN OF MBO LOCATION FROM WHOLESALE CREDIT NOTE        
 	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

  SELECT b.location_code  AS DEPT_ID,        
  'APO' AS XN_TYPE,        
   B.CN_DT AS XN_DT,        
   B.CN_ID AS XN_ID,        
   B.CN_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,         
  SUM( A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   1 AS XN_MODE   ,bc.ws_price,bc.mrp,      
   A.RATE AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE  
   ,B1.BIN_ID,B1.bin_name,'WSR' AS source_xn_type  
   ,B.MEMO_TIME AS xn_time,bc.er_flag                                  
 FROM CND01106 A (NOLOCK)        
 JOIN CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID        
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE     
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.SOURCE_BIN_ID           
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.cn_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0
 AND B.CN_TYPE<>2 
 AND B.BIN_TRANSFER=1
 GROUP BY b.location_code,B.CN_DT , B.cn_ID,B.cn_NO,memo_time,bc.org_product_code,b1.bin_id,b1.bin_name,memo_time,C.AC_NAME,a.rate,bc.ws_price,bc.mrp,bc.er_flag

    
	 PRINT 'STEP 14:'+convert(varchar,getdate(),113)             
 -- RATE REVISION - PFI        
  	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

   SELECT c.location_code  AS DEPT_ID,        
   'PFI' AS XN_TYPE,         
   C.IRM_MEMO_DT AS XN_DT,         
   C.IRM_MEMO_ID AS XN_ID,         
   C.IRM_MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,    
   '' AS XN_PARTY_NAME,         
   sum(B.QUANTITY) AS XN_QTY,'' AS XN_EMP_NAME,      
   1 AS XN_MODE        ,bc.ws_price,bc.mrp,      
   B.NEW_MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE  
   ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type
  ,C.memo_time AS xn_time,bc.er_flag                          
 FROM ird01106 b (NOLOCK)        
 JOIN IRM01106 C (NOLOCK) ON B.IRM_MEMO_ID = C.IRM_MEMO_ID     
  JOIN #tmpBarcode bc ON b.new_product_code=bc.product_code	 
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID     
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=c.location_code 
 WHERE c.irm_memo_dt BETWEEN @FROMDATE AND @TODATE AND   B.NEW_PRODUCT_CODE <> ''
 GROUP BY c.location_Code, c.IRM_MEMO_DT , c.IRM_MEMO_ID,c.IRM_MEMO_NO,memo_time,IRM_MEMO_DT,b.IRM_MEMO_id,IRM_MEMO_no,bc.org_product_code,b1.bin_id,b1.bin_name,
 memo_time,new_mrp,bc.ws_price,bc.mrp,bc.er_flag
        
  PRINT 'STEP 15:'+convert(varchar,getdate(),113)             
 -- SPLIT/COMBINE - PFI        
  	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  AS DEPT_ID,        
   'PFI' AS XN_TYPE,         
   B.MEMO_DT AS XN_DT,         
   B.MEMO_ID AS XN_ID,         
   B.MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   '' AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,'' AS XN_EMP_NAME,      
   1 AS XN_MODE        
    ,bc.ws_price,bc.mrp,      
    A.PURCHASE_PRICE AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE  
    ,'' AS BIN_ID,'' AS bin_name,'' AS source_xn_type  
   ,B.memo_time AS xn_time,bc.er_flag         
 FROM SCF01106 A  (NOLOCK)       
 JOIN SCM01106 B (NOLOCK) ON B.MEMO_ID = A.MEMO_ID    
  JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
  JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.memo_dt BETWEEN @FROMDATE AND @TODATE AND    B.CANCELLED=0
 GROUP BY b.location_code,MEMO_DT,b.MEMO_id,MEMO_no,bc.org_product_code,memo_time,a.purchase_Price,bc.ws_price,bc.mrp,bc.er_flag

  PRINT 'STEP 16:'+convert(varchar,getdate(),113)             
 -- RATE REVISION - CIP        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

    SELECT c.location_code  AS DEPT_ID,         
   'CIP' AS XN_TYPE,         
   C.IRM_MEMO_DT AS XN_DT,         
   C.IRM_MEMO_ID AS XN_ID,         
   C.IRM_MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   '' AS XN_PARTY_NAME,         
   SUM(B.QUANTITY )AS XN_QTY,'' AS XN_EMP_NAME,      
   2 AS XN_MODE  ,CONVERT(NUMERIC(10,2) ,ISNULL(bc.WS_PRICE,0)) AS WS_PRICE ,bc.mrp,      
   B.OLD_MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type    
   ,C.memo_time AS xn_time,bc.er_flag                   
 FROM ird01106 b  (NOLOCK)       
 JOIN IRM01106 C (NOLOCK) ON B.IRM_MEMO_ID = C.IRM_MEMO_ID    
 JOIN #tmpBarcode bc ON b.product_code=bc.product_code	 
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID        
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=c.location_code 
 WHERE c.irm_memo_dt BETWEEN @FROMDATE AND @TODATE AND   B.NEW_PRODUCT_CODE<>''
 GROUP BY c.location_Code, IRM_MEMO_DT,c.IRM_MEMO_id,IRM_MEMO_no,bc.org_product_code,b1.bin_id,b1.bin_name,memo_time,bc.ws_price,b.old_mrp,bc.ws_price,bc.mrp,bc.er_flag

  PRINT 'STEP 17:'+convert(varchar,getdate(),113)             
 -- SPLIT/COMBINE - CIP      
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

   SELECT b.location_code  as dept_id,        
   'CIP' AS XN_TYPE,         
   B.MEMO_DT AS XN_DT,         
   B.MEMO_ID AS XN_ID,         
   B.MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   '' AS XN_PARTY_NAME,         
   SUM(A.QUANTITY+isnull(a.ADJ_QUANTITY,0)) AS XN_QTY,'' AS XN_EMP_NAME,      
   1 AS XN_MODE        
    ,bc.ws_price,bc.mrp,      
   CONVERT(NUMERIC(10,2) ,0)  AS PURCHASE_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE  
   ,'' AS BIN_ID,'' bin_name,'' AS source_xn_type 
   ,B.memo_time AS xn_time,bc.er_flag  
 FROM SCC01106 A (NOLOCK)        
 JOIN SCM01106 B (NOLOCK) ON B.MEMO_ID = A.MEMO_ID    
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.memo_dt BETWEEN @FROMDATE AND @TODATE AND    B.CANCELLED=0
 GROUP BY b.location_code,MEMO_DT,b.MEMO_id,b.MEMO_no,bc.org_product_code,memo_time,bc.ws_price,bc.mrp,bc.er_flag

	PRINT 'STEP 18:'+convert(varchar,getdate(),113)             
 --JWI       
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  as dept_id,            
   'JWI' AS XN_TYPE,        
   B.ISSUE_DT AS XN_DT,        
   B.ISSUE_ID AS XN_ID,        
   B.ISSUE_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,         
   sum(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   2 AS XN_MODE ,bc.ws_price,bc.mrp,      
  A.JOB_RATE AS XN_PRICE ,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE     
  ,BIN.BIN_ID AS BIN_ID,BIN.BIN_NAME AS bin_name,'' AS source_xn_type  
  ,B.issue_time AS xn_time,bc.er_flag         
 FROM JOBWORK_ISSUE_DET A (NOLOCK)        
 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID      
 LEFT OUTER JOIN PRD_AGENCY_MST AGC (NOLOCK) ON B.AGENCY_CODE = AGC.AGENCY_CODE      
 LEFT OUTER JOIN LM01106 C (NOLOCK) ON AGC.AC_CODE = C.AC_CODE     
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
 JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID     
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.issue_dt BETWEEN @FROMDATE AND @TODATE AND   ((ISNULL(B.issue_mode,0)=0 AND B.WIP=0) OR B.issue_mode=1) AND B.CANCELLED=0
 GROUP BY b.location_code,Issue_DT,b.Issue_id,Issue_no,bc.org_product_code,bin.bin_id,bin.bin_name,issue_time,c.ac_name,a.job_rate,bc.ws_price,bc.mrp,bc.er_flag
 
	PRINT 'STEP 19:'+convert(varchar,getdate(),113)            
 --JWR      
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  as dept_id,           
   'JWR' AS XN_TYPE,        
   B.RECEIPT_DT AS XN_DT,        
   B.RECEIPT_ID AS XN_ID,       
   B.RECEIPT_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   1 AS XN_MODE ,bc.ws_price,bc.mrp,      
  A.JOB_RATE AS XN_PRICE ,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
  ,BIN.BIN_ID AS BIN_ID,BIN.BIN_NAME AS bin_name,'' AS source_xn_type
   ,B.rct_time AS xn_time,bc.er_flag                 
 FROM JOBWORK_RECEIPT_DET A (NOLOCK)        
 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID   
  JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
 LEFT OUTER JOIN PRD_AGENCY_MST AGC (NOLOCK) ON B.AGENCY_CODE = AGC.AGENCY_CODE      
 LEFT OUTER JOIN LM01106 C (NOLOCK) ON AGC.AC_CODE = C.AC_CODE        
 JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID       
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   ((ISNULL(B.receive_mode,0)=0 AND B.WIP=0) OR B.receive_mode=1) AND B.CANCELLED=0
 GROUP BY b.location_code,receipt_DT,b.receipt_id,receipt_no,bc.org_product_code,bin.bin_id,bin.bin_name,rct_time,c.ac_name,A.JOB_RATE,bc.ws_price,bc.mrp,bc.er_flag


	PRINT 'STEP 18.1:'+convert(varchar,getdate(),113)             
 --JWI       
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  as dept_id,           
   'WIP-JWI' AS XN_TYPE,        
   B.ISSUE_DT AS XN_DT,        
   B.ISSUE_ID AS XN_ID,        
   B.ISSUE_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,         
   sum(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   2 AS XN_MODE ,bc.ws_price,bc.mrp,      
  A.JOB_RATE AS XN_PRICE ,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE     
  ,BIN.BIN_ID AS BIN_ID,BIN.BIN_NAME AS bin_name,'''' AS source_xn_type 
  ,B.ISSUE_TIME AS xn_time,bc.er_flag          
 FROM JOBWORK_ISSUE_DET A (NOLOCK)        
 JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID      
 LEFT OUTER JOIN PRD_AGENCY_MST AGC (NOLOCK) ON B.AGENCY_CODE = AGC.AGENCY_CODE      
 LEFT OUTER JOIN LM01106 C (NOLOCK) ON AGC.AC_CODE = C.AC_CODE     
 JOIN WIP_PMT SKU (NOLOCK) ON A.PRODUCT_CODE=SKU.PRODUCT_CODE         
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
 JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID         
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.issue_dt BETWEEN @FROMDATE AND @TODATE AND   (ISNULL(B.issue_mode,0)=0 AND B.WIP=1) AND B.CANCELLED=0
 GROUP BY b.location_code,Issue_DT,b.Issue_id,Issue_no,bc.org_product_code,bin.bin_id,bin.bin_name,issue_time,c.ac_name,A.JOB_RATE,bc.ws_price,bc.mrp,bc.er_flag
 
	  PRINT 'STEP 19.1:'+convert(varchar,getdate(),113)            
 --JWR      
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.location_code  as dept_id,           
   'WIP-JWR' AS XN_TYPE,        
   B.RECEIPT_DT AS XN_DT,        
   B.RECEIPT_ID AS XN_ID,       
   B.RECEIPT_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   C.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   1 AS XN_MODE ,bc.ws_price,bc.mrp,      
  A.JOB_RATE AS XN_PRICE ,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
  ,BIN.BIN_ID AS BIN_ID,BIN.BIN_NAME AS bin_name,'' AS source_xn_type
  ,B.rct_time AS xn_time,bc.er_flag                  
 FROM JOBWORK_RECEIPT_DET A (NOLOCK)        
 JOIN JOBWORK_RECEIPT_MST B (NOLOCK) ON A.RECEIPT_ID = B.RECEIPT_ID      
 LEFT OUTER JOIN PRD_AGENCY_MST AGC (NOLOCK) ON B.AGENCY_CODE = AGC.AGENCY_CODE      
 LEFT OUTER JOIN LM01106 C (NOLOCK) ON AGC.AC_CODE = C.AC_CODE        
 JOIN WIP_PMT  SKU (NOLOCK) ON A.PRODUCT_CODE=SKU.PRODUCT_CODE         
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	 
 JOIN BIN (NOLOCK) ON BIN.BIN_ID=A.BIN_ID          
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code 
 WHERE b.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   (ISNULL(B.receive_mode,0)=0 AND B.WIP=1) AND B.CANCELLED=0
 GROUP BY b.location_code,receipt_DT,b.receipt_id,receipt_no,bc.org_product_code,bin.bin_id,bin.bin_name,rct_time,c.ac_name,A.JOB_RATE,bc.ws_price,bc.mrp,bc.er_flag
     
	PRINT 'STEP 20:'+convert(varchar,getdate(),113)         
     
 --BOC    
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
	SELECT d.location_code  as dept_id,           
	'BOC' AS XN_TYPE,        
	D.ORDER_DT AS XN_DT,        
	D.ORDER_ID AS XN_ID,       
	D.ORDER_NO AS XN_NO,        
	bc.org_PRODUCT_CODE,    
	LM.AC_NAME AS XN_PARTY_NAME,         
	sum(E.CONS_QTY_PER_PICE*P.QUANTITY) AS XN_QTY,        
	'' AS XN_EMP_NAME ,        
	2 AS XN_MODE       
	,BC.WS_PRICE ,bc.mrp     
	,bc.MRP AS XN_PRICE       
	,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE                 
	,'' AS BIN_ID,'' AS bin_name,'' AS source_xn_type 
	,PM.po_time,bc.er_flag    
	FROM WSL_ORDER_BOM E(NOLOCK)       
	LEFT OUTER JOIN WSL_ORDER_DET C (NOLOCK) ON E.REF_ROW_ID=C.ROW_ID      
	LEFT OUTER JOIN WSL_ORDER_MST D (NOLOCK) ON C.ORDER_ID=D.ORDER_ID      
	JOIN POD01106 P ON C.ROW_ID = P.WOD_ROW_ID       
	JOIN POM01106 PM ON P.PO_ID = PM.PO_ID        
	JOIN #tmpBarcode bc ON E.product_code=bc.product_code
	JOIN #xnLocs xnlocs ON xnlocs.dept_id=pm.location_code 
	LEFT OUTER JOIN LM01106 LM (NOLOCK) ON D.AC_CODE = LM.AC_CODE      
	 WHERE pm.po_dt BETWEEN @FROMDATE AND @TODATE AND    PM.CANCELLED=0
    GROUP BY d.location_Code, order_DT,d.order_id,order_no,bc.org_product_code,po_time,lm.ac_name,bc.ws_price,BC.mrp,bc.ws_price,bc.er_flag

	PRINT 'STEP 21:'+convert(varchar,getdate(),113)             
 -- RATE REVISION - CIP        
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
	SELECT c.location_code  AS DEPT_ID,         
   'SCF' AS XN_TYPE,         
   C.RECEIPT_DT AS XN_DT,         
   C.MEMO_ID AS XN_ID,         
   C.MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   LM.AC_NAME AS XN_PARTY_NAME,         
   sum(CASE WHEN sn.sn_barcode_coding_scheme=3 THEN 1 ELSE B.QUANTITY END) AS XN_QTY,'' AS XN_EMP_NAME,      
   1 AS XN_MODE  ,CONVERT(NUMERIC(10,2) ,ISNULL(bc.WS_PRICE,0)) AS WS_PRICE , bc.mrp,     
   bc.MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'''' AS source_xn_type 
   ,'' AS xn_time,bc.er_flag                      
 FROM snc_det b (NOLOCK)       
 JOIN snc_barcode_det sb (NOLOCK) ON sb.refrow_id=b.row_id
 JOIN SNC_MST C (NOLOCK) ON B.MEMO_ID = C.MEMO_ID   
 JOIN #tmpBarcode bc ON sb.product_code=bc.product_code	 
 JOIN LM01106 LM (NOLOCK) ON LM.ac_code=C.ac_code   
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=C.BIN_ID        
 JOIN SKU_NAMES sn (NOLOCK) ON sn.product_Code=sb.PRODUCT_CODE
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=c.location_code 
 WHERE c.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   C.CANCELLED=0 AND C.WIP=0
 GROUP BY c.location_code, receipt_DT,c.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,lm.ac_name,bc.mrp,bc.ws_price,bc.er_flag
 
  PRINT 'STEP 22:'+convert(varchar,getdate(),113)             
 -- SPLIT/COMBINE - CIP      
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

   SELECT c.location_code  AS DEPT_ID,         
   'SCC' AS XN_TYPE,         
   C.RECEIPT_DT AS XN_DT,         
   C.MEMO_ID AS XN_ID,         
   C.MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,    
   LM.AC_NAME AS XN_PARTY_NAME,         
   sum(B.QUANTITY) AS XN_QTY,'''' AS XN_EMP_NAME,      
   2 AS XN_MODE  ,CONVERT(NUMERIC(10,2) ,ISNULL(bc.WS_PRICE,0)) AS WS_PRICE ,  bc.mrp,    
   bc.MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type
   ,'' AS xn_time,bc.er_flag                                         
 FROM SNC_CONSUMABLE_DET b  (NOLOCK)       
 JOIN SNC_MST C (NOLOCK) ON B.MEMO_ID = C.MEMO_ID    
 JOIN #tmpBarcode bc ON b.product_code=bc.product_code	 
 JOIN LM01106 LM (NOLOCK) ON LM.ac_code=C.ac_code  
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID       
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=c.location_code 
 WHERE c.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   C.CANCELLED=0 AND isnull(b.WIP,0)=0 AND B.PRODUCT_CODE<>''
 GROUP BY c.location_code, receipt_DT,c.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,lm.ac_name,bc.mrp,bc.ws_price,bc.er_flag

--PRD 
--PRINT @ccmd
--INSERT #outputC  
--EXEC SP_EXECUTESQL @cCMD
          
  PRINT 'STEP 24:'+convert(varchar,getdate(),113)             
 -- SPLIT/COMBINE - CIP      
   	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

  SELECT c.location_code  AS DEPT_ID,         
   'PRD_SCC' AS XN_TYPE,         
   C.RECEIPT_DT AS XN_DT,         
   C.MEMO_ID AS XN_ID,         
   C.MEMO_NO AS XN_NO,        
  bc.org_PRODUCT_CODE,     
   LM.AC_NAME AS XN_PARTY_NAME,         
   sum(B.QUANTITY) AS XN_QTY,'' AS XN_EMP_NAME,      
   2 AS XN_MODE  ,CONVERT(NUMERIC(10,2) ,ISNULL(bc.WS_PRICE,0)) AS WS_PRICE ,bc.mrp,      
   bc.MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type
    ,'' AS xn_time,bc.er_flag                    
 FROM PRD_SNC_CONSUMABLE_DET b  (NOLOCK)       
 JOIN PRD_SNC_MST C (NOLOCK) ON B.MEMO_ID = C.MEMO_ID    
 JOIN #tmpBarcode bc ON b.product_code=bc.product_code	 
 JOIN LM01106 LM (NOLOCK) ON LM.ac_code=C.ac_code  
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID       
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=c.location_code
 WHERE c.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   C.CANCELLED=0 AND ISNULL(c.WIP,0)=0 AND B.PRODUCT_CODE<>''
 GROUP BY c.Location_code, receipt_DT,c.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,lm.ac_name,bc.mrp,bc.ws_price,bc.er_flag

--

PRINT 'STEP 25:'+convert(varchar,getdate(),113)             
 -- SPLIT/COMBINE - CIP      
  	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT c.location_code AS DEPT_ID,         
   'WIP-SCC' AS XN_TYPE,         
   C.RECEIPT_DT AS XN_DT,         
   C.MEMO_ID AS XN_ID,         
   C.MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,    
   LM.AC_NAME AS XN_PARTY_NAME,         
   sum(B.QUANTITY) AS XN_QTY,'''' AS XN_EMP_NAME,      
   2 AS XN_MODE  ,CONVERT(NUMERIC(10,2) ,ISNULL(bc.WS_PRICE,0)) AS WS_PRICE ,bc.mrp,      
   bc.MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'''' AS source_xn_type
  ,'' AS xn_time,bc.er_flag                      
 FROM wip_pmt  A  (NOLOCK)       
 JOIN SNC_CONSUMABLE_DET B (NOLOCK) ON B.PRODUCT_CODE = A.PRODUCT_CODE     
 JOIN SNC_MST C (NOLOCK) ON B.MEMO_ID = C.MEMO_ID    
 JOIN #tmpBarcode bc ON b.product_code=bc.product_code	 
 JOIN LM01106 LM (NOLOCK) ON LM.ac_code=C.ac_code  
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID       
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=c.location_code
 WHERE c.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   C.CANCELLED=0 AND c.WIP=1 AND B.PRODUCT_CODE<>''
 GROUP BY c.location_Code, receipt_DT,c.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,lm.ac_name,bc.mrp,bc.ws_price,bc.er_flag

	PRINT 'STEP 26:'+convert(varchar,getdate(),113)             
 -- SPLIT/COMBINE - CIP      
  	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
	SELECT c.location_code AS DEPT_ID,         
   'WIP-SCF' AS XN_TYPE,         
   C.RECEIPT_DT AS XN_DT,         
   C.MEMO_ID AS XN_ID,         
   C.MEMO_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,     
   LM.AC_NAME AS XN_PARTY_NAME,         
   SUM(B.QUANTITY) AS XN_QTY,''AS XN_EMP_NAME,      
   2 AS XN_MODE  ,CONVERT(NUMERIC(10,2) ,ISNULL(bc.WS_PRICE,0)) AS WS_PRICE ,bc.mrp,      
   bc.MRP AS XN_PRICE,CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'' AS source_xn_type
   ,'' AS xn_time,bc.er_flag                      
 FROM WIP_pmt A  (NOLOCK)       
 JOIN SNC_BARCODE_DET B2 (NOLOCK) ON B2.PRODUCT_CODE = A.PRODUCT_CODE     
 JOIN SNC_DET B (NOLOCK) ON B.row_id= b2.refrow_id
 JOIN #tmpBarcode bc ON b2.product_code=bc.product_code	
 JOIN SNC_MST C (NOLOCK) ON B.MEMO_ID = C.MEMO_ID    
 JOIN LM01106 LM (NOLOCK) ON LM.ac_code=C.ac_code  
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=C.BIN_ID       
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=c.location_code
 WHERE c.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   C.CANCELLED=0 AND c.WIP=1 AND B2.PRODUCT_CODE<>''
 GROUP BY c.location_code, receipt_DT,c.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,lm.ac_name,bc.mrp,bc.ws_price,bc.er_flag

	PRINT 'STEP 27:'+convert(varchar,getdate(),113)
  	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
	SELECT b.location_code AS DEPT_ID,        
   'DNPR' AS XN_TYPE,        
   rmm.RM_DT AS XN_DT,        
   rmm.RM_ID AS XN_ID,        
   b.ps_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,      
   C.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   1 AS XN_MODE ,      
   bc.ws_price,bc.mrp,      
   bc.MRP AS XN_PRICE,      
   CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'PRT' AS source_xn_type 
   ,rmm.rm_time AS xn_time,bc.er_flag                               
 FROM dnps_det A (NOLOCK)        
 JOIN dnps_mst B (NOLOCK) ON A.PS_ID = B.PS_ID  
 JOIN rmm01106 rmm (NOLOCK) ON rmm.rm_id=b.prt_rm_id
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE        
 JOIN BIN B1     (NOLOCK) ON B1.BIN_ID=A.BIN_ID   
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code
 WHERE rmm.rm_dt BETWEEN @FROMDATE AND @TODATE AND    rmm.CANCELLED=0
 GROUP BY b.location_code, rm_DT,rmm.rm_id,ps_no,bc.org_product_code,b1.bin_id,b1.bin_name,c.ac_name,bc.mrp,rm_time,bc.ws_price,bc.er_flag

	PRINT 'STEP 27.5:'+convert(varchar,getdate(),113)
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
	
	SELECT b.location_code AS DEPT_ID,        
   'CNPR' AS XN_TYPE,        
   cnm.CN_DT AS XN_DT,        
   cnm.CN_ID AS XN_ID,        
   b.ps_NO AS XN_NO,        
   bc.org_PRODUCT_CODE,      
   C.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   2 AS XN_MODE ,      
   bc.ws_price,bc.mrp,      
   bc.MRP AS XN_PRICE,      
   CONVERT(NUMERIC(10,2) ,0) AS MP_PERCENTAGE   
   ,B1.BIN_ID,B1.bin_name,'WSR' AS source_xn_type 
   ,cnm.cn_time AS xn_time,bc.er_flag                               
 FROM CNPS_dET A (NOLOCK)        
 JOIN cnps_mst B (NOLOCK) ON A.PS_ID = B.PS_ID  
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	
 JOIN cnm01106 cnm (NOLOCK) ON b.wsr_cn_id=cnm.cn_id
 JOIN LM01106 C (NOLOCK) ON B.AC_CODE = C.AC_CODE        
 JOIN BIN B1     (NOLOCK) ON B1.BIN_ID=A.BIN_ID 
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code
 WHERE cnm.cn_dt BETWEEN @FROMDATE AND @TODATE AND    cnm.CANCELLED=0
 GROUP BY b.location_code, cn_DT,cnm.cn_id,b.ps_no,bc.org_product_code,b1.bin_id,b1.bin_name,C.ac_name,bc.mrp,cn_time,bc.ws_price,bc.er_flag

	 PRINT 'STEP 28::'+convert(varchar,getdate(),113) 
 --TRANSFER TO MAIN FOR PRODUCTION BEGIN
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
	SELECT b.location_code AS DEPT_ID,
		'TTM' AS XN_TYPE,
		B.MEMO_DT AS XN_DT,
		B.MEMO_ID AS XN_ID,
		B.MEMO_NO AS XN_NO,
		bc.org_PRODUCT_CODE, 
		'' AS XN_PARTY_NAME, 
		sum(A.QUANTITY) AS XN_QTY,
		'' AS XN_EMP_NAME,
		1 AS XN_MODE,  
		CONVERT(NUMERIC(10,2),ISNULL(A.WS_PRICE,0)) AS WS_PRICE,bc.mrp,
		A.PURCHASE_PRICE AS XN_PRICE,
		0 AS MP_PERCENTAGE
		,B1.BIN_ID,B1.bin_name,
		'TTM' AS source_xn_type
		,'' AS xn_time,bc.er_flag 
	FROM TRANSFER_TO_TRADING_DET A (NOLOCK)
	JOIN TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID
	JOIN #tmpBarcode bc ON a.product_code=bc.product_code	
	JOIN BIN B1 (NOLOCK) ON B1.BIN_ID = A.BIN_ID
	JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code
    WHERE b.memo_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0
	GROUP BY b.location_code, MEMO_DT,B.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,A.PURCHASE_PRICE,a.ws_price,bc.ws_price,bc.mrp,bc.er_flag

	PRINT 'STEP 30:'+convert(varchar,getdate(),113)              
 -- PURCHASE INVOICE  AGAINST GRNPS       
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)
	SELECT b.location_code DEPT_ID,        
   'GRNPSIN' AS XN_TYPE,         
   B.MEMO_DT AS XN_DT,        
   B.MEMO_ID AS XN_ID,         
   B.MEMO_NO AS XN_NO,         
   bc.org_PRODUCT_CODE,   
   LM.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   1 AS XN_MODE   ,      
   bc.ws_price,bc.mrp,      
   bc.ws_PRICE AS XN_PRICE       
   ,0 AS MP_PERCENTAGE    
   ,B1.BIN_ID,B1.bin_name,'GRNPS' AS source_xn_type 
   ,'' AS xn_time,bc.er_flag    
 FROM GRN_PS_DET A (NOLOCK)        
 JOIN GRN_PS_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	
 JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=B.AC_CODE          
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID      
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code
 WHERE b.memo_dt BETWEEN @FROMDATE AND @TODATE AND    B.CANCELLED=0
 GROUP BY b.location_code,MEMO_DT,B.memo_id,memo_no,bc.org_product_code,b1.bin_id,b1.bin_name,bc.ws_price,lm.AC_NAME,bc.mrp,bc.er_flag

	 PRINT 'STEP 32:'+convert(varchar,getdate(),113)              
 -- PURCHASE INVOICE  AGAINST GRNPS       
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.DEPT_ID,        
   'GRNPSOUT' AS XN_TYPE,         
   B.RECEIPT_DT AS XN_DT,        
   B.MRR_ID AS XN_ID,         
   B.MRR_NO AS XN_NO,         
   bc.org_PRODUCT_CODE,     
   LM.AC_NAME AS XN_PARTY_NAME,         
   SUM(A.QUANTITY) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
   1 AS XN_MODE   ,      
   CONVERT(NUMERIC(10,2),ISNULL(A.WHOLESALE_PRICE,0)) AS WS_PRICE,bc.mrp,      
   A.PURCHASE_PRICE AS XN_PRICE       
   ,A.MP_PERCENTAGE    
   ,B1.BIN_ID,B1.bin_name,'PUR' AS source_xn_type 
   ,B.MEMO_TIME AS xn_time,bc.er_flag    
 FROM PID01106 A (NOLOCK)        
 JOIN PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID        
 JOIN #tmpBarcode bc ON a.product_code=bc.product_code	      
 JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=B.AC_CODE          
 JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID      
 JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code
 WHERE b.receipt_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0  AND B.RECEIPT_DT<>'' AND B.PIM_MODE=6
 GROUP BY B.DEPT_ID,receipt_DT,B.mrr_id,mrr_no,bc.org_product_code,b1.bin_id,b1.bin_name,a.purchase_price,a.mp_percentage,lm.AC_NAME,A.WHOLESALE_PRICE,
 memo_time,bc.mrp,bc.ws_price,bc.er_flag


	 PRINT 'STEP 32.5:'+convert(varchar,getdate(),113)              
 -- PURCHASE INVOICE  AGAINST GRNPS       
	INSERT #outputC  (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,WS_PRICE,mrp,XN_PRICE,MP_PERCENTAGE,
	BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag)

	SELECT b.DEPT_ID,        
   CASE WHEN ISNULL(B.ISSUE_TYPE,0)=0 THEN 'MIS' ELSE 'MIR' END AS XN_TYPE ,         
   B.issue_dt AS XN_DT,        
   B.ISSUE_ID AS XN_ID,         
   B.ISSUE_NO AS XN_NO,         
   bc.org_PRODUCT_CODE,     
   D.AGENCY_NAME AS XN_PARTY_NAME,         
   SUM(ISNULL(A.STOCK_QTY,A.QUANTITY)) AS XN_QTY,        
   '' AS XN_EMP_NAME ,        
  ( CASE WHEN ISNULL(B.ISSUE_TYPE,0) = 0 THEN 2 ELSE 1 END)  AS XN_MODE   ,      
   CONVERT(NUMERIC(10,2),ISNULL(bc.ws_price,0)) AS WS_PRICE, bc.mrp,     
   bc.mrp AS XN_PRICE       
   ,0 AS MP_PERCENTAGE    
   ,B1.BIN_ID,B1.bin_name,'MIS' AS source_xn_type 
   ,B.issue_time AS xn_time,bc.er_flag
    FROM BOM_ISSUE_DET A (NOLOCK)  
	JOIN BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	JOIN PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE 
	JOIN #tmpBarcode bc ON a.product_code=bc.product_code	      
    JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=B.BIN_ID   
	JOIN #xnLocs xnlocs ON xnlocs.dept_id=b.location_code
	WHERE b.issue_dt BETWEEN @FROMDATE AND @TODATE AND   B.CANCELLED=0
	GROUP BY b.issue_type,b.dept_id,issue_DT,B.issue_id,issue_no,bc.org_product_code,b1.bin_id,b1.bin_name,bc.ws_price,bc.mrp,d.agency_name,ISSUE_TIME,
	bc.ws_price,bc.mrp,bc.er_flag

	UPDATE #outputC SET source_xn_type=XN_TYPE WHERE source_xn_type=''
    
	
	DECLARE @cPmtTable VARCHAR(200),@cBaseColumn VARCHAR(200),@CPMT_BUILD_DATEWISE VARCHAR(10),@CPMTTABLENAME VARCHAR(100),
	        @DCBSPMTDATE DATETIME,@DOBSPMTTRANDATE DATETIME

	
	SET @DOBSPMTTRANDATE=''
	SELECT @CPMT_BUILD_DATEWISE=value  FROM CONFIG WHERE CONFIG_OPTION='PMT_BUILD_DATEWISE'
	
	select product_code,bin_id,dept_id,convert(numeric(20,2),0) cbs_qty into #pmtops from pmt01106 where 1=2
    select product_code,bin_id,dept_id,convert(numeric(20,2),0) cbs_qty into #pmtcbs from pmt01106 where 1=2

	
	IF (DATENAME (DD,@FROMDATE)=1 OR ISNULL(@CPMT_BUILD_DATEWISE,'')='1')
	BEGIN
	    
	    SET @CPMTTABLE=DB_NAME ()+'_PMT.DBO.PMTLOCS_'+CONVERT (VARCHAR(10),@FROMDATE-1,112)
	END
    ELSE 
    BEGIN
	--where LEFT(A.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX ('@',A.PRODUCT_CODE)-1,-1),LEN(A.PRODUCT_CODE )))= @CPRODUCTCODE
	DECLARE @CFILTER VARCHAR(1000),@CERRORMSG VARCHAR(100) 
	IF @IMODE=1
	BEGIN
	    
	   IF EXISTS (SELECT TOP 1 'U' FROM  #tmpbarCode WHERE product_Code LIKE '%@%') AND @CPRODUCTCODE NOT LIKE '%@%'
         SET @CFILTER ='LEFT(SKU_NAMES.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',SKU_NAMES.PRODUCT_CODE)-1,-1),LEN(SKU_NAMES.PRODUCT_CODE )))='''+@CPRODUCTCODE+''' '
        ELSE
	     SET @CFILTER ='SKU_NAMES.PRODUCT_CODE='''+@CPRODUCTCODE+''' '
	 
	 
	 END
	ELSE IF @IMODE=2
      SET @CFILTER ='SKU_NAMES.ARTICLE_NO='''+@CPRODUCTCODE+''' '
    else 
     SET @CFILTER ='SKU_NAMES.para3_name='''+@CPRODUCTCODE+''' '
      
      
	exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY
				@dFromDt=@FROMDATE,
				@dToDt=@TODATE,
				@cFilterPara=@cFilter,
				@bUpdateOpsOnly=1,
				@cErrormsg=@cErrormsg OUTPUT
				
	
	IF ISNULL(@CERRORMSG,'')<>''
	BEGIN
	   SELECT @CERRORMSG AS ERRMSG
	   RETURN
	
	END
	SET @CPMTTABLE='#PMTOPS'
	
	END 
	
	   	  	
	IF @bPickOpsFromPmt=0
	BEGIN
		PRINT 'STEP 35:'+convert(varchar,getdate(),113) 
		INSERT #outputC    (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,BIN_ID,bin_name,source_xn_type,XN_TIME,er_flag,
		 xn_price,mrp,ws_price )
		SELECT  A.DEPT_ID,'OPS' AS XN_TYPE,     
			@dOrgFromDt AS XN_DT,'OPS' AS XN_ID,           
			'OPS' AS XN_NO,A.PRODUCT_CODE, '' AS XN_PARTY_NAME,    
			SUM( (CASE WHEN A.XN_TYPE='OPS' OR (A.XN_TYPE IN ('OPS','PRD','CNPI', 'PUR','MIR','TTM','WPR','GRNPSIN','DNPR', 'FIN-PRD', 'CHI', 'SLR','UNC','APR', 'WSR', 'PFI', 'PFG', 'BCG','MRP','DCI','PSB','JWR','WIP-JWR','SCF','WIP-SCF','OLOAQ')     
			AND (XN_DT  < @dOrgFromDt) ) THEN 1     
			WHEN A.XN_TYPE IN ('PRT','CHO','SLS','CNC','APP','WSL','MIS','WPI','CNPR','GRNPSOUT','DNPI','CIP', 'CRM', 'DCO','MIP','CSB','JWI','DLM','WIP-JWI','SCC','PRD_SCC','WIP-SCC','BOC','OLODQ')     
			AND (XN_DT < @dOrgFromDt)  THEN -1 ELSE 0 END) * (XN_QTY)) AS XN_QTY,    
			'' AS XN_EMP_NAME ,          
			1 AS XN_MODE,B1.BIN_ID,B1.BIN_NAME,'' AS source_xn_type,@dOrgFromDt AS xn_time,a.er_flag,
			0 xn_price,a.mrp,a.ws_price	
		FROM #outputC A 
		JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=A.BIN_ID 
		WHERE XN_DT<@dOrgFromDt  
		AND ( @BESTIMATE= 1 OR ER_FLAG in (0,1))
		GROUP BY A.DEPT_ID,A.PRODUCT_CODE,B1.BIN_ID,B1.BIN_NAME,a.er_flag,a.mrp,a.ws_price
		HAVING SUM( (CASE WHEN A.XN_TYPE='OPS' OR (A.XN_TYPE IN ('OPS','PRD','cnpi', 'PUR','MIR','TTM','WPR','GRNPSIN','DNPR', 'FIN-PRD', 'CHI', 'SLR','UNC','APR', 'WSR', 'PFI', 'PFG', 'BCG','MRP','DCI','PSB','JWR','WIP-JWR','SCF','WIP-SCF','OLOAQ')     
				AND (XN_DT  < @dOrgFromDt)  ) THEN 1     
				WHEN A.XN_TYPE IN ('PRT','CHO','SLS','CNC','APP','WSL','MIS','cnpr','WPI','GRNPSOUT','DNPI','CIP', 'CRM', 'DCO','MIP','CSB','JWI','DLM','WIP-JWI','SCC','PRD_SCC','WIP-SCC','BOC','OLODQ')
				AND (XN_DT <@dOrgFromDt)  THEN -1 ELSE 0 END) * (XN_QTY)) >0 
	END
	ELSE
	BEGIN
		DECLARE @dPmtCutoffDate DATETIME
		SET @cFinYear='01'+dbo.FN_GETFINYEAR(convert(date,dateadd(yy,-1,getdate())))
		SET @dPmtCutoffDate=dbo.FN_GETFINYEARDATE(@cFinYear,1)

		---No need to show the Opening stock from pmt for the transaction from Date beyond First Date of Previous Fin year (Discussed with Sir : Sanjay Bhatia(22-11-2023)
		IF ISNULL(@dPmtCutoffDate,'')<>''
		BEGIN
			PRINT 'STEP 37:'+convert(varchar,getdate(),113) 
			IF @iMode IN (1,4)
				SET @cCmd=N'SELECT  pmt.DEPT_ID,''OPS'' AS XN_TYPE,     
				'''+CONVERT(VARCHAR,@dOrgFromDt,112)+''' AS XN_DT,''OPS'' AS XN_ID,           
				''OPS'' AS XN_NO,pmt.PRODUCT_CODE,  '''' AS XN_PARTY_NAME,    
				SUM(cbs_qty) AS XN_QTY,  '''' AS XN_EMP_NAME ,          
				1 AS XN_MODE,B1.BIN_ID,B1.BIN_NAME,'''' AS source_xn_type,
				'''' AS xn_time,sn.sku_er_flag,0 xn_price,sn.mrp,sn.ws_price 
				FROM '+@cPmtTable+' pmt (NOLOCK) JOIN #tmpBarcode b ON pmt.product_code=b.product_code
				JOIN #xnLocs xnlocs ON xnlocs.dept_id=pmt.dept_id 
				JOIN sku_names sn (NOLOCK) ON sn.product_code=pmt.product_code
				JOIN BIN B1 (NOLOCK) ON B1.BIN_ID=pmt.BIN_ID    
				WHERE   '+(CASE WHEN @BESTIMATE= 1 THEN ' 1=1 ' ELSE 'sku_ER_FLAG in (0,1)' END)+
				' GROUP BY pmt.DEPT_ID,pmt.PRODUCT_CODE,B1.BIN_ID,B1.BIN_NAME,sn.sku_er_flag,sn.mrp,sn.ws_price 
				HAVING SUM(cbs_qty)<>0 '
			ELSE
			BEGIN
				SET @cBaseColumn = (CASE WHEN @IMODE=2 THEN ' b.article_no' ELSE 'b.para3_name' END)
				SET @cCmd=N'SELECT  DEPT_ID,  ''OPS'' AS XN_TYPE,     
					'''+CONVERT(VARCHAR,@dOrgFromDt,112)+''' AS XN_DT,''OPS'' AS XN_ID,           
					''OPS'' AS XN_NO,'''+@CPRODUCTCODE+''' PRODUCT_CODE,
					'''' AS XN_PARTY_NAME,    
					SUM(cbs_qty) AS XN_QTY,    
					'''' AS XN_EMP_NAME ,          
					1 AS XN_MODE,pmt.BIN_ID,BIN_NAME,'''' AS source_xn_type,'''' XN_TIME,b.sku_er_flag,0 xn_price,b.mrp,b.ws_price     
				FROM '+@cPmtTable+' pmt (NOLOCK)  JOIN sku_names b (NOLOCK) ON pmt.product_code=b.product_Code
				JOIN bin c (NOLOCK) ON c.bin_id=pmt.bin_id
				WHERE '+@cBaseColumn +'='''+@CPRODUCTCODE+''' AND  '+(CASE WHEN @BESTIMATE= 1 THEN ' 1=1 ' ELSE 'sku_ER_FLAG in (0,1)' END)+
				' GROUP BY dept_id,pmt.bin_id,bin_name,b.sku_er_flag,b.mrp,b.ws_price 
				HAVING SUM(cbs_qty)<>0 '
		
			END

			PRINT @cCmd
			INSERT INTO #outputC (dept_id,xn_type,xn_dt,xn_id,xn_no,PRODUCT_CODE,XN_PARTY_NAME,xn_qty,XN_EMP_NAME,xn_mode,BIN_ID,bin_name,
			source_xn_type,XN_TIME,er_flag,xn_price,mrp,ws_price )
			EXEC SP_EXECUTESQL @cCmd
			
			
		END
	END	
	
	IF @IMODE=4
		UPDATE  a SET article_no=b.article_no,para1_name=b.para1_name,para2_name=b.para2_name,para3_name=b.para3_name,
		img_id=B.barcode_img_id
		FROM #outputC a JOIN sku_names b (NOLOCK) ON b.product_Code=a.PRODUCT_CODE

    --- Make sure that output columns should be purely capitals as this is used in Wow Purchase analysis Xn History
	--- where Frontend app is Case sensitive (Sanjay : 22-08-2024)
	PRINT 'STEP 40:'+convert(varchar,getdate(),113) 
	SELECT PRODUCT_CODE,DEPT_NAME,AC_NAME, ALIAS,
	SUM(CASE WHEN  XN_MODE=1 THEN XN_QTY ELSE 0 END) AS XN_IN_QTY, 
	SUM(CASE WHEN  XN_MODE=2 THEN XN_QTY ELSE 0 END) AS XN_OUT_QTY,   
	SUM(A.XN_QTY) AS XN_QTY,XN_PRICE,MRP,WS_PRICE,
	A.XN_TYPE,XNT.XN_TYPE DISPLAY_XN_TYPE,XN_MODE, XN_NO, XN_DT, XN_DP,        
	 SUM(XN_DA) XN_DA,SUM(XN_NET) XN_NET, A.DEPT_ID, A.XN_PARTY_NAME, A.XN_EMP_NAME ,        
	A.DISCOUNT_PERCENTAGE,A.BIN_ID,A.BIN_NAME,LM_ALIAS,A.XN_ID,A.SOURCE_XN_TYPE,A.XN_TIME,A.ARTICLE_NO,A.PARA1_NAME,A.PARA2_NAME,A.PARA3_NAME,A.IMG_ID
	FROM 
	(
	SELECT (CASE WHEN @iMode=4 THEN product_code ELSE @cProductCode END) PRODUCT_CODE,         
	isnull(G.DEPT_NAME,'') dept_name, '' AC_NAME,dept_alias ALIAS,
	xn_mode,xn_qty,isnull(a.xn_price,0) xn_price,a.mrp,a.ws_price,
	ltrim(rtrim(a.xn_type)) xn_type, A.XN_NO, A.XN_DT,(CASE WHEN xn_price>0 THEN convert(numeric(6,2),(xn_da/(xn_price*xn_qty))*100) else 0 end) AS XN_DP,        
	isnull(xn_da,0) AS XN_DA, isnull(xn_net,0)  XN_NET, A.DEPT_ID, isnull(A.XN_PARTY_NAME,'') XN_PARTY_NAME, isnull(A.XN_EMP_NAME,'') XN_EMP_NAME,        
	isnull(A.MP_PERCENTAGE,0) AS DISCOUNT_PERCENTAGE 
	,A.BIN_ID,A.BIN_NAME,'' AS [LM_ALIAS],A.XN_ID,a.source_xn_type,a.XN_TIME,a.ARTICLE_NO,a.para1_name,a.para2_name,a.PARA3_NAME,a.img_id
	FROM #outputC A         
	JOIN location g (NOLOCK) ON g.dept_id=a.dept_id
	WHERE LTRIM(RTRIM(ISNULL(A.PRODUCT_CODE,'')))<> ''     
	AND (XN_DT  BETWEEN @dOrgFromDt AND @TODATE) AND ( @BESTIMATE= 1 OR isnull(ER_FLAG,0) in (0,1))  
	) A
	LEFT JOIN wow_XPERT_XNTYPeS_alias xnt (NOLOCK) ON xnt.XN_TYPE_alias=a.xn_type
	GROUP BY PRODUCT_CODE,DEPT_NAME,AC_NAME, ALIAS,xn_price,mrp,ws_price,a.ARTICLE_NO,a.para1_name,a.para2_name,a.PARA3_NAME,a.img_id,
	a.xn_type,xnt.xn_type,xn_mode, XN_NO, XN_DT, XN_DP,A.DEPT_ID, A.XN_PARTY_NAME, A.XN_EMP_NAME ,        
	a.DISCOUNT_PERCENTAGE,a.xn_dp,A.BIN_ID,A.BIN_NAME,LM_ALIAS,A.XN_ID,a.source_xn_type,a.XN_TIME
	ORDER BY product_code, (CASE WHEN a.xn_type='ops' then 1 else 2 end),XN_DT ,A.XN_TIME       
    
	PRINT 'STEP 38:'+convert(varchar,getdate(),113)    
END      
--********************************************** END OF PROCEDURE SP_BARCODETRANSACTIONHISTORY_NEW      