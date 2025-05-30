CREATE PROC SP3S_EXPORTDAILYSALE_GRON(@SALE_DATE DATE)--(LocId 3 digit change by Sanjay:05-11-2024)            
AS              
BEGIN              
--GRON MALL MANAGEMENT            
SET NOCOUNT ON              
DECLARE @ERR VARCHAR(1000)          
,@LOC VARCHAR(10),@POS VARCHAR(10)='',@APP_FOLDER VARCHAR(200)          
,@SALETIME VARCHAR(100),@REC INT,@CATG VARCHAR(100),@DEPT VARCHAR(100),@PAY_TYPE VARCHAR(100)    
SELECT TOP 1 @LOC=VALUE FROM CONFIG WHERE CONFIG_OPTION LIKE 'LOCATION_ID' 
SELECT TOP 1 @APP_FOLDER=VALUE FROM CONFIG WHERE CONFIG_OPTION LIKE 'MALL_MNGNT_RPT_PATH'
    
      
SET @POS=@LOC      
      
--BEGIN TRY             
EXEC SP_CONFIGURE 'SHOW ADVANCED OPTIONS', 1;            
RECONFIGURE;            
EXEC SP_CONFIGURE 'XP_CMDSHELL', 1;            
RECONFIGURE;            
            
DECLARE @IN_PATH VARCHAR(1000),@OUT_PATH VARCHAR(1000),@ID INT              
DECLARE @MYFILE VARCHAR(MAX),@LINE_ITEMS VARCHAR(MAX),@ID_VALUE INT            
SET @ID_VALUE=0            
          
SET @OUT_PATH=@APP_FOLDER          
          
IF RIGHT(RTRIM(@OUT_PATH),1)='\'            
   SET @OUT_PATH=LEFT(LTRIM(RTRIM(@OUT_PATH)),LEN(LTRIM(RTRIM(@OUT_PATH)))-1)            
          
DECLARE @FIN VARCHAR(100),@IDOC_NO VARCHAR(100),@SEP VARCHAR(5) ,@LEASEID VARCHAR(100)           
SELECT TOP 1 @FIN=FIN_YEAR FROM CMM01106(NOLOCK) WHERE location_Code=@LOC AND CM_DT=@SALE_DATE          
SET @SEP='^|'          
SET @IDOC_NO=''          
SET @LINE_ITEMS=''          
SET @LEASEID='T019340000695'          
          
IF EXISTS(SELECT * FROM IDOC_GEN (NOLOCK) WHERE DEPT_ID=@LOC AND POS_NMBR=@POS)          
   SELECT @ID_VALUE=MAX(CAST(SNO AS INT)) FROM IDOC_GEN (NOLOCK) WHERE DEPT_ID=@LOC AND POS_NMBR=@POS          
ELSE          
   SET @ID_VALUE=0          
IF @ID_VALUE=9999          
   SET @ID_VALUE=0          
IF @ID_VALUE=0               
   SELECT @IDOC_NO='T'+@LEASEID+'_'+@POS+'_'+'001'+'_'        
   +SUBSTRING(CONVERT(VARCHAR,GETDATE(),112),3,10)+LEFT(REPLACE(CONVERT(VARCHAR,GETDATE(),108),':',''),4)+'.TXT'           
ELSE          
   SELECT @IDOC_NO='T'+@LEASEID+'_'+@POS+'_'        
   +RIGHT('000'+CAST(MAX(CAST(@ID_VALUE+1 AS INT)) AS VARCHAR),3)+'_'        
   +SUBSTRING(CONVERT(VARCHAR,GETDATE(),112),3,10)+LEFT(REPLACE(CONVERT(VARCHAR,GETDATE(),108),':',''),4)+'.TXT'           
   FROM IDOC_GEN (NOLOCK) WHERE DEPT_ID=@LOC AND POS_NMBR=@POS          
         
DECLARE @SHOP_NMBR VARCHAR(14),@POS_NMBR VARCHAR(10),@RECEIPT_NMBR VARCHAR(10),@TRAN_FILE_NMBR INT          
,@DATE CHAR(8),@TIME CHAR(8),@USER_ID VARCHAR(10),@SHIFT_NMBR INT,@TRAN_TYPE VARCHAR(10),@SALEDATE DATE,@CMID VARCHAR(100)          
,@DISC_AMT FLOAT,@ITEM_NSALE FLOAT,@ITEM_STAX FLOAT,@TAX FLOAT          
,@TENDER_TYPE CHAR(1),@TENDER_AMOUNT FLOAT,@TENDER_AMOUNT_CONV FLOAT,@TAX_TYPE VARCHAR(1),@REF_RECPT VARCHAR(100)          
          
--HEADER:CMD_CODE=1          
SELECT @SHOP_NMBR=@LEASEID,@POS_NMBR=@POS,@TRAN_FILE_NMBR=@ID_VALUE+1          
SELECT @DATE=CONVERT(VARCHAR,GETDATE(),112),@TIME=CONVERT(VARCHAR,GETDATE(),108)          
SELECT @RECEIPT_NMBR=MIN(CM_NO) FROM CMM01106 WHERE location_Code=@LOC AND CM_DT=@SALE_DATE AND CM_NO NOT LIKE '%R%' AND CM_NO NOT LIKE '%N%'          
          
SET @LINE_ITEMS='1^|OPENED^|'+ISNULL(@SHOP_NMBR,'')+'^|'+ISNULL(@POS_NMBR,'')+'^|'          
+ISNULL(@RECEIPT_NMBR,'')+'^|'          
+CAST(ISNULL(@TRAN_FILE_NMBR,0) AS VARCHAR)+'^|'          
+@DATE+'^|'+@TIME+'^|'+'MANAGER'+'^|'+CONVERT(VARCHAR,@SALE_DATE,112)          
SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' > '+@OUT_PATH+'\'+@IDOC_NO          
SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
IF ISNULL(@RECEIPT_NMBR,'')<>''          
   EXEC (@LINE_ITEMS)           
             
SELECT @RECEIPT_NMBR=MIN(CM_NO) FROM CMM01106 WHERE location_Code=@LOC AND CM_DT=@SALE_DATE AND CM_NO LIKE '%R%'          
SET @LINE_ITEMS='1^|OPENED^|'+ISNULL(@SHOP_NMBR,'')+'^|'+ISNULL(@POS_NMBR,'')+'^|'          
+ISNULL(@RECEIPT_NMBR,'')+'^|'          
+CAST(ISNULL(@TRAN_FILE_NMBR,0) AS VARCHAR)+'^|'          
+@DATE+'^|'+@TIME+'^|'+ISNULL(@USER_ID,'')+'^|'+CONVERT(VARCHAR,@SALE_DATE,112)          
SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' > '+@OUT_PATH+'\'+@IDOC_NO          
SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
IF ISNULL(@RECEIPT_NMBR,'')<>''          
   EXEC (@LINE_ITEMS)               
          
SELECT @RECEIPT_NMBR=MIN(CM_NO) FROM CMM01106 WHERE location_code=@LOC AND CM_DT=@SALE_DATE AND CM_NO LIKE '%N%'          
SET @LINE_ITEMS='1^|OPENED^|'+ISNULL(@SHOP_NMBR,'')+'^|'+ISNULL(@POS_NMBR,'')+'^|'          
+ISNULL(@RECEIPT_NMBR,'')+'^|'          
+CAST(ISNULL(@TRAN_FILE_NMBR,0) AS VARCHAR)+'^|'          
+@DATE+'^|'+@TIME+'^|'+ISNULL(@USER_ID,'')+'^|'+CONVERT(VARCHAR,@SALE_DATE,112)          
SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' > '+@OUT_PATH+'\'+@IDOC_NO          
SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
IF ISNULL(@RECEIPT_NMBR,'')<>''          
   EXEC (@LINE_ITEMS)               
--DETAIL           
DECLARE TR CURSOR FOR          
--SALE          
SELECT CM_ID,CM_NO RECEIPT_NUMBER,CM_DT [SALEDATE],CONVERT(VARCHAR,CM_TIME,108)SALETIME,'SALE'TRANSTAT,REF_CM_ID          
FROM CMM01106 (NOLOCK) WHERE location_code=@LOC AND CM_DT=@SALE_DATE AND SUBSTRING(CM_NO,len(location_code)+3,1) NOT IN ('R','N') AND CANCELLED=0          
UNION          
--CASH REFUND          
SELECT CM_ID,CM_NO RECEIPT_NUMBER,CM_DT [SALEDATE],CONVERT(VARCHAR,CM_TIME,108),'SALE'TRANSTAT,REF_CM_ID          
FROM CMM01106 (NOLOCK) WHERE location_code=@LOC AND CM_DT=@SALE_DATE AND SUBSTRING(CM_NO,len(location_code)+3,1) LIKE 'R' AND CANCELLED=0          
UNION          
--CREDIT_NOTE REFUND          
SELECT CM_ID,CM_NO RECEIPT_NUMBER,CM_DT [SALEDATE],CONVERT(VARCHAR,CM_TIME,108),'SALE'TRANSTAT,REF_CM_ID          
FROM CMM01106 (NOLOCK) WHERE location_code=@LOC AND CM_DT=@SALE_DATE AND SUBSTRING(CM_NO,len(location_code)+3,1) LIKE 'N' AND CANCELLED=0          
ORDER BY 4 DESC,1          
          
OPEN TR          
FETCH NEXT FROM TR INTO @CMID,@RECEIPT_NMBR,@SALEDATE,@SALETIME,@TRAN_TYPE,@REF_RECPT          
WHILE @@FETCH_STATUS=0          
  BEGIN          
    --CMD_CODE=101           
    SET @LINE_ITEMS='101^|'+@RECEIPT_NMBR+'^|'          
    +'01'+'^|'--SHIFT NUMBER          
    +CONVERT(VARCHAR,@SALEDATE,112)+'^|'          
    +@SALETIME+'^|'--TIME          
    +'MANAGER'+'^|'--USER ID          
    +''+'^|'--MANUAL RECEIPT          
	+CASE @TRAN_TYPE WHEN 'SALE' THEN '' ELSE 'R' END+'^|'--REFUND          
	+''+'^|'--REASON CODE          
	+''+'^|'--SALESMAN CODE          
	+''+'^|'--TABLE NMBR          
	+''+'^|'--CUST COUNT          
	+'N'+'^|'--TRAINING          
	+ISNULL(@TRAN_TYPE,'')          
    SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' >> '+@OUT_PATH+'\'+@IDOC_NO          
    SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
    EXEC (@LINE_ITEMS)           
              
    --CMD_CODE=111          
    DECLARE @PROD VARCHAR(100),@QTY FLOAT,@PRICE FLOAT,@ITM_FLAG VARCHAR(10)          
    DECLARE ITM CURSOR FOR          
    SELECT  C.PRODUCT_CODE,C.QUANTITY,C.MRP,''FLAG,C.DISCOUNT_AMOUNT          
    ,(C.QUANTITY*C.MRP)-C.DISCOUNT_AMOUNT-(IGST_AMOUNT+CGST_AMOUNT+SGST_AMOUNT)-CMM_DISCOUNT_AMOUNT AS ITEM_NSALE          
    ,IGST_AMOUNT+CGST_AMOUNT+SGST_AMOUNT AS ITEM_STAX          
    ,SD.SUB_SECTION_NAME,SM.SECTION_NAME    
    FROM CMD01106 C(NOLOCK)    
    JOIN SKU S(NOLOCK) ON C.PRODUCT_CODE=S.PRODUCT_CODE    
    JOIN ARTICLE A(NOLOCK) ON A.ARTICLE_CODE=S.ARTICLE_CODE    
    JOIN SECTIOND SD(NOLOCK) ON SD.SUB_SECTION_CODE=A.SUB_SECTION_CODE    
    JOIN SECTIONM SM(NOLOCK) ON SD.SECTION_CODE=SM.SECTION_CODE    
    WHERE CM_ID=@CMID          
    OPEN ITM          
    FETCH NEXT FROM ITM INTO @PROD,@QTY,@PRICE,@ITM_FLAG,@DISC_AMT,@ITEM_NSALE,@ITEM_STAX,@CATG,@DEPT    
    WHILE @@FETCH_STATUS=0          
      BEGIN          
        SET @LINE_ITEMS='111^|'          
        +ISNULL(@PROD,'')+'^|'          
        +CAST(ISNULL(@QTY,0) AS VARCHAR)+'^|'          
        +CAST(ISNULL(@PRICE,0) AS VARCHAR)+'^|'      
        +CAST(ISNULL(@PRICE,0) AS VARCHAR)+'^|'          
        +ISNULL(@ITM_FLAG,'')+'^|'          
        +'GST'+'^|'--TAXCODE          
        +''+'^|'--DISC CODE          
        +CAST(ISNULL(@DISC_AMT,0) AS VARCHAR)+'^|'          
        +ISNULL(@DEPT,'')+'^|'--ITEM DEPT          
        +ISNULL(@CATG,'')+'^|'--ITEM CATG          
        +''+'^|'--LABEL KEYS          
        +''+'^|'--ITEM COMM          
        +CAST(ISNULL(@ITEM_NSALE,0) AS VARCHAR)+'^|'          
        +CAST(ISNULL(@DISC_AMT,0) AS VARCHAR)+'^|'          
        +'%'+'^|'--DISC SIGN          
        +CAST(ISNULL(@ITEM_STAX,0) AS VARCHAR)+'^|'          
        +''--PLU CODE          
     SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' >> '+@OUT_PATH+'\'+@IDOC_NO          
  SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
  EXEC (@LINE_ITEMS)           
  --          
  FETCH NEXT FROM ITM INTO @PROD,@QTY,@PRICE,@ITM_FLAG,@DISC_AMT,@ITEM_NSALE,@ITEM_STAX ,@CATG,@DEPT         
      END          
    CLOSE ITM          
    DEALLOCATE ITM          
              
    --CMD_CODE=121 FOOTER OF TXN; TAXES, DISCOUNT ETC          
    SELECT @ITEM_NSALE=SUM(QUANTITY*MRP)          
    ,@DISC_AMT=SUM(ISNULL(CMM_DISCOUNT_AMOUNT,0)+ISNULL(BASIC_DISCOUNT_AMOUNT,0)+ISNULL(DISCOUNT_AMOUNT,0))          
    ,@TAX=SUM(ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0))          
    ,@TAX_TYPE=CASE TAX_METHOD WHEN 2 THEN 'E' ELSE 'I' END          
    FROM CMD01106(NOLOCK) WHERE CM_ID=@CMID          
    GROUP BY TAX_METHOD          
    SET @LINE_ITEMS='121^|'          
        +CAST(@ITEM_NSALE AS VARCHAR)+'^|'          
        +CAST(@DISC_AMT AS VARCHAR)+'^|'          
        +''+'^|'--CESS          
        +''+'^|'--CHARGES          
        +CAST(@TAX AS VARCHAR)+'^|'          
        +ISNULL(@TAX_TYPE,'') +'^|'--TAX_TYPE=I/E          
        +'Y'+'^|'--EXECPT GST          
        +''+'^|'--DISCOUNT CODE          
        +''+'^|'--OTHER CHARGES          
        +''+'^|'--DISCOUNT PER          
    SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' >> '+@OUT_PATH+'\'+@IDOC_NO          
    SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
	EXEC (@LINE_ITEMS)               
           
    --CMD_CODE=131 FOOTER OF TXN; PAYMODE MODE ETC          
    SET @REC=-1    
    SELECT 'C' A,AMOUNT,AMOUNT*XD.CURRENCY_CONVERSION_RATE B          
    INTO #C    
    FROM PAYMODE_XN_DET XD(NOLOCK) JOIN PAYMODE_MST PM (NOLOCK) ON PM.PAYMODE_CODE=XD.PAYMODE_CODE          
    WHERE MEMO_ID=@CMID AND PAYMODE_NAME='CREDIT ISSUED' AND XN_TYPE='SLS'          
    UNION          
    SELECT 'T',AMOUNT,AMOUNT*XD.CURRENCY_CONVERSION_RATE          
    FROM PAYMODE_XN_DET XD(NOLOCK) JOIN PAYMODE_MST PM (NOLOCK) ON PM.PAYMODE_CODE=XD.PAYMODE_CODE          
    WHERE MEMO_ID=@CMID AND PAYMODE_NAME!='CREDIT ISSUED' AND XN_TYPE='SLS'          
    SELECT @REC=COUNT(*) FROM #C    
    DROP TABLE #C    
        
    IF @REC=0    
	   BEGIN    
		  SET @LINE_ITEMS='131^|'          
		  +'C'+'^|'          
		  +''+'^|'--PAYMENT NAME          
		  +''+'^|'--CURR CODE          
		  +''+'^|'--BUY RATE          
		  +'0'+'^|'          
		  +''+'^|'--REMARKS1          
		  +''+'^|'--REMARKS2          
		  +''+'^|'--REMARKS3          
		  +'0'          
		  SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' >> '+@OUT_PATH+'\'+@IDOC_NO          
		  SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
		  EXEC (@LINE_ITEMS)      
		END    
        
    DECLARE TENDER CURSOR FOR          
    SELECT 'C',AMOUNT,AMOUNT*XD.CURRENCY_CONVERSION_RATE,''PAY_TYPE          
    FROM PAYMODE_XN_DET XD(NOLOCK) JOIN PAYMODE_MST PM (NOLOCK) ON PM.PAYMODE_CODE=XD.PAYMODE_CODE          
    WHERE MEMO_ID=@CMID AND PAYMODE_NAME='CREDIT ISSUED' AND XN_TYPE='SLS'          
    UNION          
    SELECT 'T',AMOUNT,AMOUNT*XD.CURRENCY_CONVERSION_RATE,CASE PAYMODE_GRP_CODE WHEN '0000002'  THEN 'CARD' ELSE 'CASH' END        
    FROM PAYMODE_XN_DET XD(NOLOCK) JOIN PAYMODE_MST PM (NOLOCK) ON PM.PAYMODE_CODE=XD.PAYMODE_CODE      
    WHERE MEMO_ID=@CMID AND PAYMODE_NAME!='CREDIT ISSUED' AND XN_TYPE='SLS'          
      
      
    OPEN TENDER          
    FETCH NEXT FROM TENDER INTO @TENDER_TYPE,@TENDER_AMOUNT,@TENDER_AMOUNT_CONV,@PAY_TYPE          
    WHILE @@FETCH_STATUS=0  AND @REC>0        
      BEGIN          
		SET @LINE_ITEMS='131^|'          
			+ISNULL(@TENDER_TYPE,'')+'^|'          
			+@PAY_TYPE+'^|'--PAYMENT NAME          
			+'INR'+'^|'--CURR CODE          
			+''+'^|'--BUY RATE          
			+CAST(ISNULL(@TENDER_AMOUNT,0) AS VARCHAR)+'^|'          
			+''+'^|'--REMARKS1          
			+''+'^|'--REMARKS2          
			+''+'^|'--REMARKS3          
			+CAST(ISNULL(@TENDER_AMOUNT_CONV,0) AS VARCHAR)          
		SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' >> '+@OUT_PATH+'\'+@IDOC_NO          
		SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
		EXEC (@LINE_ITEMS)               
        --NEXT TENDER          
        FETCH NEXT FROM TENDER INTO @TENDER_TYPE,@TENDER_AMOUNT,@TENDER_AMOUNT_CONV,@PAY_TYPE          
      END          
    CLOSE TENDER          
    DEALLOCATE TENDER          
 --NEXT BILL/REFUND            
    FETCH NEXT FROM TR INTO @CMID,@RECEIPT_NMBR,@SALEDATE,@SALETIME,@TRAN_TYPE,@REF_RECPT          
  END          
  CLOSE TR          
  DEALLOCATE TR          
            
--FOOTER:CMD_CODE=1          
SELECT @SHOP_NMBR=@LEASEID,@POS_NMBR=@POS,@TRAN_FILE_NMBR=@ID_VALUE+1,@USER_ID=''          
SELECT @DATE=CONVERT(VARCHAR,GETDATE(),112),@TIME=CONVERT(VARCHAR,GETDATE(),108)          
          
SELECT @RECEIPT_NMBR=MAX(CM_NO) FROM CMM01106 WHERE location_code=@LOC AND CM_DT=@SALE_DATE AND SUBSTRING(CM_NO,len(location_code)+3,1) NOT IN ('R','N')          
SET @LINE_ITEMS='1^|CLOSED^|'          
+ISNULL(@SHOP_NMBR,'')+'^|'          
+ISNULL(@POS_NMBR,'')+'^|'          
+ISNULL(@RECEIPT_NMBR,'')+'^|'          
+CAST(ISNULL(@TRAN_FILE_NMBR,0) AS VARCHAR)+'^|'          
+@DATE+'^|'          
+@TIME+'^|'          
+'MANAGER'+'^|'          
+CONVERT(VARCHAR,@SALE_DATE,112)          
SELECT @LINE_ITEMS='ECHO '+@LINE_ITEMS+' >> '+@OUT_PATH+'\'+@IDOC_NO          
SET @LINE_ITEMS='EXEC MASTER..XP_CMDSHELL '''+@LINE_ITEMS+''''            
IF ISNULL(@RECEIPT_NMBR,'')<>''          
   EXEC (@LINE_ITEMS)           
IF NOT EXISTS(SELECT * FROM IDOC_GEN WHERE DEPT_ID=@LOC AND POS_NMBR=@POS)          
   INSERT IDOC_GEN SELECT @LOC,@LEASEID,@POS,@ID_VALUE+1          
ELSE              
   UPDATE IDOC_GEN SET SNO=@ID_VALUE+1 WHERE DEPT_ID=@LOC AND POS_NMBR=@POS          
END
