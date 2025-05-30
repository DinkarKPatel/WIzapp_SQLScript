CREATE PROCEDURE VALIDATEXN_MIRROR_WPS  
 @CLOCID VARCHAR(10),
 @CXNID VARCHAR(50),
 @CMERGEDB VARCHAR(200),   
 @CERRORMSG VARCHAR(MAX) OUTPUT  
-- WITH ENCRYPTION
AS  
BEGIN  
/* 
VALIDATEXN_MIRROR_WPS_V208_29_JAN_14 : THIS PROCEDURE WILL VALIDATE ALL THE MIRROR TRANSFERRED DATA FOR
WHOLESALE DATA.
*/
DECLARE	@NCALCDISCOUNTAMT NUMERIC(14,2),@NDISCOUNTAMT NUMERIC(14,2),@DTSQL NVARCHAR(MAX),@NSUBTOTAL NUMERIC(14,2)
		,@NSUMINDNET NUMERIC(14,2),@CSTEP VARCHAR(5),@CCHK_TABLE VARCHAR(50),@NPAYMODECRAMT NUMERIC(10,2)
		,@NPAYMODETOTAMT NUMERIC(10,2),@NTOTAMOUNT NUMERIC(14,2)   
	 SET @CSTEP=00	
	 SET @CERRORMSG=''
	 SET @CSTEP=10

	 IF OBJECT_ID('TEMPDB..#WPSMSTTABLE','U') IS NOT NULL 
		DROP TABLE #WPSMSTTABLE	 
	 SET @CSTEP=20
	 IF OBJECT_ID('TEMPDB..#WPSDETTABLE','U') IS NOT NULL 
		DROP TABLE #WPSDETTABLE
	 SET @CSTEP=30	

	 SET @CSTEP=40	 
	 CREATE TABLE #WPSMSTTABLE(PS_ID VARCHAR(22),PS_MODE NUMERIC (5,0),NET_AMOUNT NUMERIC (10,2), 
			 INV_NO CHAR(15),SUBTOTAL NUMERIC(18,4), FIN_YEAR VARCHAR(10),
			 INV_DT DATETIME,USER_CODE CHAR(7),AC_CODE CHAR(10) )  

	 SET @CSTEP=50	 		 
	 CREATE TABLE #WPSDETTABLE (PS_ID VARCHAR(22),PRODUCT_CODE VARCHAR(50),QUANTITY NUMERIC(10,3),INVOICE_QUANTITY NUMERIC(10,3)
			  ,MRP NUMERIC (10,2),NET_RATE NUMERIC (14,4),ITEM_TAX_PERCENTAGE NUMERIC(6,2),ITEM_TAX_AMOUNT NUMERIC(12,4))  

BEGIN TRY	 
	 SET @CSTEP=70	     
	 PRINT 'MASTER RECORDS...'
	 SET @DTSQL=N'SELECT PS_ID,PS_MODE,SUBTOTAL,PS_NO,SUBTOTAL,FIN_YEAR,PS_DT,USER_CODE,AC_CODE 
				  FROM '+@CMERGEDB+'WPS_MST (NOLOCK) WHERE PS_ID='''+@CXNID+'''' 

	 SET @CSTEP=80
	 INSERT #WPSMSTTABLE
	 EXEC SP_EXECUTESQL @DTSQL 

	 SET @CSTEP=90
	 PRINT 'DETAIL RECORDS...'
	 SET @DTSQL=N'SELECT PS_ID ,PRODUCT_CODE ,QUANTITY ,QUANTITY,MRP ,RATE , 
						TAX_PERCENTAGE,TAX_AMOUNT
				 FROM  '+@CMERGEDB+'WPS_DET (NOLOCK) WHERE PS_ID='''+@CXNID+''''  

	 SET @CSTEP=100
	 INSERT #WPSDETTABLE
	 EXEC SP_EXECUTESQL @DTSQL 

	 SET @CSTEP=130
	 IF ISNULL(@CERRORMSG,'')<>''
		RETURN

	 SET @CSTEP=140	
	 PRINT 'VALIDATING LEDGERS...'	
	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @CSTEP=150	
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 ''U'' FROM  '+@CMERGEDB+'WPS_MST A
								LEFT OUTER JOIN  '+@CMERGEDB+'LM01106 B ON A.AC_CODE=B.AC_CODE
								WHERE A.PS_ID='''+@CXNID+''' AND B.AC_CODE IS NULL)
						SET @CERRORMSGOUT=''INVALID LEDGER DETAILS FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
		 
		IF ISNULL(@CERRORMSG,'')<>''
			RETURN
	 END
	
	 PRINT 'VALIDATING SALES PERSON'	
	 IF ISNULL(@CERRORMSG,'')=''
	 BEGIN
		 SET @CSTEP=180	
		 SET @DTSQL=N'IF EXISTS (SELECT TOP 1 PS_ID FROM  '+@CMERGEDB+'WPS_DET A
								LEFT OUTER JOIN  '+@CMERGEDB+'EMPLOYEE B ON A.EMP_CODE=B.EMP_CODE
								LEFT OUTER JOIN  '+@CMERGEDB+'EMPLOYEE C ON A.EMP_CODE1=C.EMP_CODE
								LEFT OUTER JOIN  '+@CMERGEDB+'EMPLOYEE D ON A.EMP_CODE2=D.EMP_CODE
								WHERE A.PS_ID='''+@CXNID+''' AND ((A.EMP_CODE IS NOT NULL AND B.EMP_CODE IS NULL) 
								OR (A.EMP_CODE1 IS NOT NULL AND C.EMP_CODE IS NULL) OR (A.EMP_CODE2 IS NOT NULL AND D.EMP_CODE IS NULL))) 
						SET @CERRORMSGOUT=''INVALID SALES PERSON DETAILS FOUND''
					 ELSE
						SET @CERRORMSGOUT='''''	
		 PRINT @DTSQL						
		 EXEC SP_EXECUTESQL @DTSQL,N'@CERRORMSGOUT VARCHAR(200) OUTPUT',@CERRORMSGOUT=@CERRORMSG OUTPUT
		 IF ISNULL(@CERRORMSG,'')<>''
			RETURN
	 END
	 
	 SET @CSTEP=190
	 SELECT @NSUBTOTAL=SUBTOTAL FROM #WPSMSTTABLE  
	 SET @CSTEP=200
	 SELECT @NSUMINDNET=SUM(NET_RATE*INVOICE_QUANTITY) FROM #WPSDETTABLE
	 SET @CSTEP=210
	 IF ABS(ISNULL(@NSUMINDNET,0)-ISNULL(@NSUBTOTAL,0))>1
	 BEGIN
		SET @CERRORMSG = 'MISMATCH BETWEEN ITEM LEVEL TOTAL AMOUNT & BILL LEVEL SUBTOTAL.....' -- CANNOT SAVE '
		RETURN
	 END	 
	 
END TRY	
BEGIN CATCH
		SET @CERRORMSG = 'P:VALIDATEXN_MIRROR_WPS,STEP: '+@CSTEP+'MESSAGE: '+ERROR_MESSAGE()
		RETURN
END CATCH	
END_PROC:  
END  
--*************************************** END OF PROCEDURE VALIDATEXN_MIRROR_WPS
