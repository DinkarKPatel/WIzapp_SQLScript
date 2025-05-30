CREATE PROCEDURE VALIDATEXN_MIRROR_PO  
 @CLOCID VARCHAR(10),
 @CXNID VARCHAR(50),   
 @CMERGEDB VARCHAR(200),
 @CERRORMSG VARCHAR(MAX) OUTPUT  
-- WITH ENCRYPTION
AS  
BEGIN  
/* 
VALIDATEXN_MIRROR_PO_V208_01_FEB_14 : THIS PROCEDURE WILL VALIDATE ALL THE MIRROR TRANSFERRED DATA FOR
PURCHASE ORDER.
*/
DECLARE	@NCALCDISCOUNTAMT NUMERIC(14,2),@NDISCOUNTAMT NUMERIC(14,2),@DTSQL NVARCHAR(MAX),@NSUBTOTAL NUMERIC(14,2)
		,@NSUMINDNET NUMERIC(14,2),@CSTEP VARCHAR(5),@CCHK_TABLE VARCHAR(50),@NPAYMODECRAMT NUMERIC(10,2)
		,@NPAYMODETOTAMT NUMERIC(10,2),@NTOTAMOUNT NUMERIC(14,2)   
	 
	 SET @CSTEP=00
	 SET @CERRORMSG=''
	 
	 SET @CSTEP=10
	 IF OBJECT_ID('TEMPDB..#POMTABLE','U') IS NOT NULL 
		DROP TABLE #POMTABLE	 
	 
	 SET @CSTEP=20
	 IF OBJECT_ID('TEMPDB..#PODTABLE','U') IS NOT NULL 
		DROP TABLE #PODTABLE
	 
	 SET @CSTEP=40
	 CREATE TABLE #POMTABLE(PO_ID VARCHAR(50),MODE NUMERIC (5,0),DISCOUNT_PERCENTAGE NUMERIC (7,3),
			 DISCOUNT_AMOUNT NUMERIC (10,2),TOTAL_AMOUNT NUMERIC (10,2), ROUND_OFF NUMERIC (10,2), 
			 PO_NO VARCHAR(50),SUBTOTAL NUMERIC(18,4), FIN_YEAR VARCHAR(10),
			 PO_DT DATETIME,USER_CODE CHAR(7),AC_CODE CHAR(10),MANUAL_DISCOUNT BIT )  
			 
	 SET @CSTEP=50		 
	 CREATE TABLE #PODTABLE (PO_ID VARCHAR(50),PRODUCT_CODE VARCHAR(50),QUANTITY NUMERIC(10,3),INVOICE_QUANTITY NUMERIC(10,3)
			  ,GROSS_PURCHASE_PRICE NUMERIC (10,2),PURCHASE_PRICE NUMERIC (14,4),DISCOUNT_PERCENTAGE NUMERIC(6,2)
			  ,DISCOUNT_AMOUNT NUMERIC (14,4),TAX_PERCENTAGE NUMERIC(6,2),TAX_AMOUNT NUMERIC(12,4),MANUAL_DISCOUNT BIT )  
	 SET @CSTEP=60
	 
BEGIN TRY	 
	 SET @CSTEP=70	     
	 PRINT 'MASTER RECORDS...'
	 SET @DTSQL=N'SELECT PO_ID,MODE,DISCOUNT_PERCENTAGE,DISCOUNT_AMOUNT,TOTAL_AMOUNT,ROUND_OFF, 
				 PO_NO,SUBTOTAL,FIN_YEAR,PO_DT,USER_CODE,AC_CODE,MANUAL_DISCOUNT 
				 FROM  '+@CMERGEDB+'POM01106 (NOLOCK) WHERE PO_ID='''+@CXNID+'''' 
	 
	 SET @CSTEP=80	      
	 INSERT #POMTABLE
	 EXEC SP_EXECUTESQL @DTSQL 
	 SET @CSTEP=90
	 PRINT 'DETAIL RECORDS...'
	 SET @DTSQL=N'SELECT PO_ID ,PRODUCT_CODE ,QUANTITY ,INVOICE_QUANTITY,GROSS_PURCHASE_PRICE ,PURCHASE_PRICE 
				,DISCOUNT_PERCENTAGE ,DISCOUNT_AMOUNT,TAX_PERCENTAGE,TAX_AMOUNT, MANUAL_DISCOUNT 
				 FROM  '+@CMERGEDB+'POD01106 (NOLOCK) WHERE PO_ID='''+@CXNID+''''  
	 
	 SET @CSTEP=100
	 INSERT #PODTABLE
	 EXEC SP_EXECUTESQL @DTSQL 
	 
	 SET @CSTEP=130
	 IF ISNULL(@CERRORMSG,'')<>''
		RETURN
		
	 SET @CSTEP=140	
	 PRINT 'VALIDATING LEDGERS...'	
	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @CSTEP=150	
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 ''U'' FROM  '+@CMERGEDB+'POM01106 A
								LEFT OUTER JOIN  '+@CMERGEDB+'LM01106 B ON A.AC_CODE=B.AC_CODE
								WHERE A.PO_ID='''+@CXNID+''' AND B.AC_CODE IS NULL)
						SET @CERRORMSGOUT=''INVALID LEDGER DETAILS FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
		 IF ISNULL(@CERRORMSG,'')<>''
			RETURN
	 END
	 
	 SET @CSTEP=160
	 SELECT @NSUBTOTAL=SUBTOTAL FROM #POMTABLE  
	 
	 SET @CSTEP=170
	 SELECT @NSUMINDNET=SUM(PURCHASE_PRICE*INVOICE_QUANTITY) FROM #PODTABLE
	 
	 SET @CSTEP=180
	 IF ABS(ISNULL(@NSUMINDNET,0)-ISNULL(@NSUBTOTAL,0))>1
	 BEGIN
		SET @CERRORMSG = 'MISMATCH BETWEEN ITEM LEVEL TOTAL AMOUNT & BILL LEVEL SUBTOTAL.....' -- CANNOT SAVE '
		RETURN
	 END	 
END TRY	
BEGIN CATCH
		SET @CERRORMSG = 'P:VALIDATEXN_MIRROR_PO,STEP: '+@CSTEP+'MESSAGE: '+ERROR_MESSAGE()
		RETURN
END CATCH	
END_PROC:  
END  
--*************************************** END OF PROCEDURE VALIDATEXN_MIRROR_PO
