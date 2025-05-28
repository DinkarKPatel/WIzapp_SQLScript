CREATE PROCEDURE SP3SBUILDWSL
(
	 @CXNID			VARCHAR(50)
	,@NUPDATEMODE	NUMERIC(2)
    ,@CINSJOINSTR   VARCHAR(1000)=''
	,@CWHERECLAUSE	VARCHAR(1000)=''
	,@cRfTableName  varchar(500)=''
	,@cBuildXnType VARCHAR(10)=''
	,@CERRMSG		VARCHAR(MAX) OUTPUT
)
AS
BEGIN
/*
XNTYPE FILTER IS REQUIRED DURING DELETION FROM RFOPT TABLE BECAUSE IN SOME CASES LIKE TRO FROM PIM01106
,THE INSERTED XN_ID IS THAT OF WHOLESALE INVOICE.
*/
	DECLARE @CCMD NVARCHAR(MAX),@CSTEP VARCHAR(10),@CFILTER VARCHAR(500),
			@CCURLOCID VARCHAR(5),@CHOLOCID VARCHAR(5),@CCHIFILTER VARCHAR(500),@CDELSTR VARCHAR(1000),@CDELJOINSTR VARCHAR(500)
	
BEGIN TRY


	DECLARE @BBUILDRFOPT BIT
	
	EXEC SP3S_CHKRFOPT_BUILD @BBUILDRFOPT OUTPUT
	
	IF @BBUILDRFOPT=0
		RETURN
		
	IF @cRfTableName=''
		EXEC SP3S_RFDBTABLE 'WSL',@cXnID,@cRFTABLENAME OUTPUT 		
			
	SELECT TOP 1 @CCURLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	SELECT TOP 1 @CHOLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID' 

	SET @CFILTER=(CASE WHEN @NUPDATEMODE IN (0,4) THEN '1=1' ELSE 'A.INV_ID='''+@CXNID+'''' END)+@CWHERECLAUSE
		
	--START OF BUILD PROCESS FOR WHOLESALE TRANSACTION
	
	 IF @NUPDATEMODE IN (3)			
	 BEGIN
	   
	   IF @CCURLOCID=@CHOLOCID
	   BEGIN	
		   SET @CSTEP = 95
		   SET @CCMD=N'UPDATE A  SET GIT_QTY=A.GIT_QTY-ISNULL(B.GIT_QTY,0)
					 FROM
					 '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' a
					 JOIN 
					 (
					  SELECT B.PARTY_DEPT_ID AS DEPT_ID,  
					  B.INV_DT  AS XN_DT,   
					  A.PRODUCT_CODE,  
					  SUM( A.QUANTITY ) as GIT_QTY,B.TARGET_BIN_ID AS [BIN_ID] 
					 FROM IND01106 A
					 JOIN INM01106 B ON A.INV_ID = B.INV_ID  
					 JOIN LOCATION D(NOLOCK) ON B.PARTY_DEPT_ID=D.DEPT_ID'+@CINSJOINSTR+' 
					 WHERE '+@CFILTER+' AND B.CANCELLED = 0 AND B.INV_MODE=2 AND ISNULL(D.SOR_LOC,0)=0
					 AND ISNULL(D.SIS_LOC,0)=0
					 AND ISNULL(b.xn_item_type,0) IN (0,1) AND ISNULL(B.xn_item_type,0) in (0,1)
					 GROUP BY B.PARTY_DEPT_ID,B.INV_DT,A.PRODUCT_CODE,B.TARGET_BIN_ID
					 ) B ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
				 
		   PRINT ISNULL(@CCMD,'NULL TRI EXPR FOR WSL')
		   EXEC SP_EXECUTESQL @CCMD
	   END
	   	
	   SET @CSTEP = 100
       SET @CCMD=N'UPDATE A  SET apo_QTY=A.apo_QTY-ISNULL(B.apo_QTY,0),
					 CHO_QTY=A.CHO_QTY-ISNULL(B.CHO_QTY,0),
                     CHO_TAXABLE_VALUE=a.CHO_TAXABLE_VALUE-ISNULL(b.CHO_TAXABLE_VALUE,0),
                     CHO_TAX_AMOUNT=a.CHO_TAX_AMOUNT-ISNULL(b.CHO_TAX_AMOUNT,0),       
                     WSL_QTY=A.WSL_QTY-ISNULL(B.WSL_QTY,0),
                     WSL_TAXABLE_VALUE=a.WSL_TAXABLE_VALUE-ISNULL(b.WSL_TAXABLE_VALUE,0),
                     WSL_TAX_AMOUNT=a.WSL_TAX_AMOUNT-ISNULL(b.WSL_TAX_AMOUNT,0)
                 FROM
                 '+@cRFTABLEName+' a
                 JOIN 
                 (
				  SELECT LEFT(B.INV_ID,2) as dept_id,  
				  B.INV_DT  AS XN_DT,   
				  A.PRODUCT_CODE,  
				  SUM(CASE WHEN bin_transfer=1 THEN A.QUANTITY ELSE 0 END) as APO_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.QUANTITY ELSE 0 END) AS WSL_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS WSL_TAXABLE_VALUE,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS WSL_TAX_AMOUNT,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.QUANTITY ELSE 0 END) AS CHO_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS CHO_TAXABLE_VALUE,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS CHO_TAX_AMOUNT,				  				  
				 A.BIN_ID AS [BIN_ID] 
				 FROM IND01106 A
				 JOIN INM01106 B ON A.INV_ID = B.INV_ID 
				 LEFT OUTER JOIN location loc (NOLOCK) ON loc.dept_id=b.party_dept_id'+@CINSJOINSTR+'
				 WHERE '+@CFILTER+' AND B.CANCELLED = 0
				 AND ISNULL(b.xn_item_type,0) IN (0,1)  AND ISNULL(loc.sor_loc,0)=0
				 GROUP BY  LEFT(B.INV_ID,2),B.INV_DT,A.PRODUCT_CODE,A.BIN_ID
				 ) B ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
			 
	   PRINT ISNULL(@CCMD,'NULL TRI EXPR FOR WSL')
	   EXEC SP_EXECUTESQL @CCMD
	   	    
	   SET @CSTEP = 110
       SET @CCMD=N'UPDATE A SET WPR_QTY=A.WPR_QTY-ISNULL(B.WPR_QTY,0)
                 FROM '+@cRFTABLEName+' a
                 JOIN 
                 (
				  SELECT LEFT(B.INV_ID,2) AS DEPT_ID,  
				  B.INV_DT  AS XN_DT,   
				  A.PRODUCT_CODE,  
				  SUM(A.QUANTITY) AS WPR_QTY,
				  A.BIN_ID 
				 FROM IND01106 A
				 JOIN INM01106 B ON A.INV_ID = B.INV_ID '+@CINSJOINSTR+'
				 JOIN 
				 (SELECT DET.PS_ID, DET.BIN_ID,C.PS_NO,DET.PRODUCT_CODE FROM  
					  WPS_DET DET 
					 JOIN WPS_MST C ON DET.PS_ID =C.PS_ID    
					 JOIN inm01106 a (NOLOCK) ON a.inv_id=c.wsl_inv_id'+@CINSJOINSTR+'
					 WHERE '+@CFILTER+' AND C.CANCELLED = 0 AND ISNULL(DET.PS_ID,'''')<>'''' 
					 GROUP BY DET.PS_ID, DET.BIN_ID,C.PS_NO,DET.PRODUCT_CODE
				 ) DET ON A.PRODUCT_CODE=DET.PRODUCT_CODE AND A.PS_ID=DET.PS_ID AND A.BIN_ID=DET.BIN_ID

				 WHERE '+@CFILTER+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0 
				 GROUP BY LEFT(B.INV_ID,2) ,B.INV_DT,A.PRODUCT_CODE,A.BIN_ID
				 ) B ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
			 
	   PRINT ISNULL(@CCMD,'NULL TRI EXPR FOR WSL')
	   EXEC SP_EXECUTESQL @CCMD
	  -- ADD NEW WSL PACK SLIP RETURN 
	   	
	   SET @CSTEP = 120
	   SET @CCMD=N'UPDATE A SET api_QTY=A.api_QTY-ISNULL(B.api_QTY,0),chi_QTY=A.chi_QTY-ISNULL(B.chi_QTY,0)
                 FROM '+@cRFTABLEName+' a
                 JOIN 
                 (
			  SELECT (CASE WHEN B.BIN_TRANSFER=1 THEN LEFT(B.INV_ID,2) ELSE B.PARTY_DEPT_ID END) AS DEPT_ID,  
			    B.INV_DT AS XN_DT,  
			   A.PRODUCT_CODE,  
			   SUM(CASE WHEN B.BIN_TRANSFER=1 THEN A.QUANTITY ELSE 0 END) AS api_QTY,  
			   SUM(CASE WHEN B.BIN_TRANSFER<>1 THEN A.QUANTITY ELSE 0 END) AS chi_QTY,  
			   B.TARGET_BIN_ID  AS [BIN_ID]  
			 FROM IND01106 A 
			 JOIN INM01106 B  ON A.INV_ID = B.INV_ID 
			 LEFT JOIN LOCATION LOC ON LOC.DEPT_ID=B.PARTY_DEPT_ID'+@CINSJOINSTR+'
			 WHERE '+@CFILTER+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0 
			 AND (B.BIN_TRANSFER=1 OR ((ISNULL(LOC.SOR_LOC,0)=1 AND B.INV_MODE=2)))
			 GROUP BY (CASE WHEN B.BIN_TRANSFER=1 THEN LEFT(B.INV_ID,2) ELSE B.PARTY_DEPT_ID END) ,
			 B.INV_DT,A.PRODUCT_CODE,B.TARGET_BIN_ID
			 )b ON  a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				 
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	  
	END	
	
	IF @NUPDATEMODE<>3
	BEGIN
	   
	   IF @cCurLocId=@cHoLocId AND @cBuildXnType IN ('GIT','')
	   BEGIN	
		   SET @CSTEP = 140
		   SET @CCMD=N'UPDATE A  SET GIT_QTY=A.GIT_QTY+ISNULL(B.GIT_QTY,0)
					 FROM
					 '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' a
					 JOIN 
					 (
					  SELECT B.PARTY_DEPT_ID AS DEPT_ID,  
					  B.INV_DT  AS XN_DT,   
					  A.PRODUCT_CODE,  
					  SUM( A.QUANTITY ) as GIT_QTY,B.TARGET_BIN_ID AS [BIN_ID] 
					 FROM IND01106 A
					 JOIN INM01106 B ON A.INV_ID = B.INV_ID  
					 JOIN LOCATION D(NOLOCK) ON B.PARTY_DEPT_ID=D.DEPT_ID'+@CINSJOINSTR+' 
					 WHERE '+@CFILTER+' AND B.CANCELLED = 0 AND B.INV_MODE=2 AND ISNULL(D.SOR_LOC,0)=0
					 AND ISNULL(D.SIS_LOC,0)=0
					 AND ISNULL(B.xn_item_type,0) in (0,1)
					 GROUP BY B.PARTY_DEPT_ID,B.INV_DT,A.PRODUCT_CODE,B.TARGET_BIN_ID
					 ) B ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
				 
		   PRINT ISNULL(@CCMD,'NULL TRI EXPR FOR WSL')
		   EXEC SP_EXECUTESQL @CCMD

		   SET @cStep=145	   
		   SET @CCMD=N'INSERT '+REPLACE(@cRFTABLEName,'rf_opt','rf_opt_git')+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,git_qty,BIN_ID)
					   SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.git_qty,xn.bin_id FROM 
					  (			
					  SELECT B.PARTY_DEPT_ID AS DEPT_ID,  
					  B.INV_DT  AS XN_DT,   
					  A.PRODUCT_CODE,  
					  SUM( A.QUANTITY ) as GIT_QTY,B.TARGET_BIN_ID AS [BIN_ID] 
					 FROM IND01106 A
					 JOIN INM01106 B ON A.INV_ID = B.INV_ID  
					 JOIN LOCATION D(NOLOCK) ON B.PARTY_DEPT_ID=D.DEPT_ID'+@CINSJOINSTR+' 
					 WHERE '+@CFILTER+' AND B.CANCELLED = 0 AND B.INV_MODE=2 AND ISNULL(D.SOR_LOC,0)=0
					 AND ISNULL(D.SIS_LOC,0)=0
					 AND ISNULL(B.xn_item_type,0) in (0,1)
					 GROUP BY B.PARTY_DEPT_ID,B.INV_DT,A.PRODUCT_CODE,B.TARGET_BIN_ID
					 ) xn  
					 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					 AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					 WHERE b.product_code IS NULL'
					 
		   PRINT @CCMD
		   EXEC SP_EXECUTESQL @CCMD
	   END
	   
	    
	   SET @CSTEP = 150
       SET @CCMD=N'UPDATE A  SET apo_QTY=A.apo_QTY+(CASE WHEN '''+@cBuildXnType+''' IN (''APO'','''') THEN ISNULL(B.apo_QTY,0) ELSE 0 END),
                     WSL_QTY=A.WSL_QTY+(CASE WHEN '''+@cBuildXnType+''' IN (''WSL'','''') THEN ISNULL(B.WSL_QTY,0) ELSE 0 END),
                     WSL_TAXABLE_VALUE=a.WSL_TAXABLE_VALUE+(CASE WHEN '''+@cBuildXnType+''' IN (''WSL'','''') THEN ISNULL(b.WSL_TAXABLE_VALUE,0) ELSE 0 END),
                     WSL_TAX_AMOUNT=a.WSL_TAX_AMOUNT+(CASE WHEN '''+@cBuildXnType+''' IN (''WSL'','''') THEN ISNULL(b.WSL_TAX_AMOUNT,0) ELSE 0 END),
					 CHO_QTY=A.CHO_QTY+(CASE WHEN '''+@cBuildXnType+''' IN (''CHO'','''') THEN ISNULL(B.CHO_QTY,0) ELSE 0 END),
                     CHO_TAXABLE_VALUE=a.CHO_TAXABLE_VALUE+(CASE WHEN '''+@cBuildXnType+''' IN (''CHO'','''') THEN ISNULL(b.CHO_TAXABLE_VALUE,0) ELSE 0 END),
                     CHO_TAX_AMOUNT=a.CHO_TAX_AMOUNT+(CASE WHEN '''+@cBuildXnType+''' IN (''CHO'','''') THEN ISNULL(b.CHO_TAX_AMOUNT,0) ELSE 0 END)                     
                 FROM
                 '+@cRFTABLEName+' a
                 JOIN
                 (
				  SELECT LEFT(B.INV_ID,2) AS dept_id,  
				  B.INV_DT  AS XN_DT,   
				  A.PRODUCT_CODE,  
				  SUM(CASE WHEN bin_transfer=1 THEN A.QUANTITY ELSE 0 END) as APO_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.QUANTITY ELSE 0 END) AS WSL_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS WSL_TAXABLE_VALUE,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS WSL_TAX_AMOUNT,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.QUANTITY ELSE 0 END) AS CHO_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS CHO_TAXABLE_VALUE,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS CHO_TAX_AMOUNT,				  				  
				  A.BIN_ID AS [BIN_ID] 
				 FROM IND01106 A
				 JOIN INM01106 B ON A.INV_ID = B.INV_ID
				 LEFT OUTER JOIN location loc (NOLOCK) ON loc.dept_id=b.party_dept_id '+@CINSJOINSTR+'
				 WHERE '+@CFILTER+' AND B.CANCELLED = 0 AND ISNULL(b.xn_item_type,0) IN (0,1) 
				 AND ISNULL(loc.sor_loc,0)=0
				 GROUP BY  LEFT(B.INV_ID,2),B.INV_DT,A.PRODUCT_CODE,A.BIN_ID
				 ) B ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
			 
	   PRINT ISNULL(@CCMD,'NULL TRI EXPR FOR WSL')
	   EXEC SP_EXECUTESQL @CCMD

	   SET @cStep=160	   
	   SET @CCMD=N'INSERT '+@cRFTABLEName+' 
					(DEPT_ID,XN_DT,PRODUCT_CODE,apo_qty,cho_qty,cho_TAXABLE_VALUE,cho_TAX_AMOUNT,wsl_qty,WSL_TAXABLE_VALUE,WSL_TAX_AMOUNT,BIN_ID)
				   SELECT xn.dept_id,xn.xn_dt,xn.product_code,
				   (CASE WHEN '''+@cBuildXnType+''' IN (''APO'','''') THEN xn.apo_qty ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''CHO'','''') THEN xn.cho_qty ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''CHO'','''') THEN xn.cho_TAXABLE_VALUE ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''CHO'','''') THEN xn.cho_TAX_AMOUNT ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''WSL'','''') THEN xn.wsl_qty ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''WSL'','''') THEN xn.WSL_TAXABLE_VALUE ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''WSL'','''') THEN xn.WSL_TAX_AMOUNT ELSE 0 END),
				   xn.bin_id FROM 
				  (			
				  SELECT  LEFT(b.inv_id,2) as DEPT_ID,  
				   B.INV_DT AS XN_DT,  
				   A.PRODUCT_CODE,   
				  SUM(CASE WHEN bin_transfer=1 THEN A.QUANTITY ELSE 0 END) as APO_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.QUANTITY ELSE 0 END) AS WSL_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS WSL_TAXABLE_VALUE,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=1 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS WSL_TAX_AMOUNT,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.QUANTITY ELSE 0 END) AS CHO_QTY,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS CHO_TAXABLE_VALUE,
				  SUM(CASE WHEN ISNULL(bin_transfer,0)<>1 AND inv_mode=2 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS CHO_TAX_AMOUNT,				  
				  A.BIN_ID  AS [BIN_ID] 
				 FROM IND01106 A 
				 JOIN INM01106 B ON A.INV_ID = B.INV_ID
				 LEFT OUTER JOIN location loc (NOLOCK) ON loc.dept_id=b.party_dept_id '+@CINSJOINSTR+'
				 WHERE '+@CFILTER+' AND B.CANCELLED = 0 AND ISNULL(b.xn_item_type,0) IN (0,1)
				 AND ISNULL(loc.sor_loc,0)=0
				 GROUP BY  LEFT(B.INV_ID,2),B.INV_DT,A.PRODUCT_CODE,A.BIN_ID
			     ) xn  
				 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
				 AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
				 WHERE b.product_code IS NULL'
				 
	   PRINT @CCMD
	   EXEC SP_EXECUTESQL @CCMD

	  
	  -- ADD NEW WSL PACK SLIP RETURN 
	   
	   SET @CSTEP=170
 	   SET @CCMD=N'UPDATE A SET api_QTY=A.api_QTY+(CASE WHEN '''+@cBuildXnType+''' IN (''API'','''') THEN ISNULL(B.api_QTY,0) ELSE 0 END),
 				   chi_QTY=A.chi_QTY+(CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN ISNULL(B.chi_QTY,0) ELSE 0 END),
 					 CHI_TAXABLE_VALUE=a.CHI_TAXABLE_VALUE+(CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN ISNULL(b.CHI_TAXABLE_VALUE,0) ELSE 0 END),
                     CHI_TAX_AMOUNT=a.CHI_TAX_AMOUNT+(CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN ISNULL(b.CHI_TAX_AMOUNT,0) ELSE 0 END)
                 FROM '+@cRFTABLEName+' a
                 JOIN
                 (
			  SELECT (CASE WHEN B.BIN_TRANSFER=1 THEN LEFT(B.INV_ID,2) ELSE B.PARTY_DEPT_ID END) AS DEPT_ID,  
			   B.INV_DT AS XN_DT,A.PRODUCT_CODE,  
			   SUM(CASE WHEN B.BIN_TRANSFER=1 THEN A.QUANTITY ELSE 0 END) AS api_QTY,  
			   SUM(CASE WHEN B.BIN_TRANSFER<>1 THEN A.QUANTITY ELSE 0 END) AS chi_QTY,  
			   SUM(CASE WHEN B.BIN_TRANSFER<>1 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS CHI_TAXABLE_VALUE,
			   SUM(CASE WHEN B.BIN_TRANSFER<>1 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS CHI_TAX_AMOUNT,
		   	   B.TARGET_BIN_ID  AS [BIN_ID]  
			 FROM IND01106 A 
			 JOIN INM01106 B  ON A.INV_ID = B.INV_ID 
			 LEFT JOIN LOCATION LOC ON LOC.DEPT_ID=B.PARTY_DEPT_ID'+@CINSJOINSTR+'
			 WHERE '+@CFILTER+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0 
			 AND (B.BIN_TRANSFER=1 OR ((ISNULL(LOC.SOR_LOC,0)=1 AND B.INV_MODE=2)))
			 GROUP BY (CASE WHEN B.BIN_TRANSFER=1 THEN LEFT(B.INV_ID,2) ELSE B.PARTY_DEPT_ID END),B.INV_DT,A.PRODUCT_CODE,B.TARGET_BIN_ID
			 )b ON  a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id'
				 
		PRINT @CCMD
		EXEC SP_EXECUTESQL @CCMD
	   
	    
	    SET @cStep=180
	    SET @CCMD=N'INSERT '+@cRFTABLEName+' 
					(DEPT_ID,XN_DT,PRODUCT_CODE,api_QTY,chi_QTY,CHI_TAXABLE_VALUE,CHI_TAX_AMOUNT,BIN_ID)
				   SELECT xn.dept_id,xn.xn_dt,xn.product_code,
				   (CASE WHEN '''+@cBuildXnType+''' IN (''API'','''') THEN xn.api_QTY ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN xn.chi_QTY ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN xn.CHI_TAXABLE_VALUE ELSE 0 END),
				   (CASE WHEN '''+@cBuildXnType+''' IN (''CHI'','''') THEN xn.CHI_TAX_AMOUNT ELSE 0 END),xn.bin_id FROM 
				  (			
				  SELECT  LEFT(b.inv_id,2) AS DEPT_ID,  
				   B.INV_DT AS XN_DT,  
				   A.PRODUCT_CODE, 
				   SUM(CASE WHEN B.BIN_TRANSFER=1 THEN A.QUANTITY ELSE 0 END) AS api_QTY,  
			       SUM(CASE WHEN B.BIN_TRANSFER<>1 THEN A.QUANTITY ELSE 0 END) AS chi_QTY,  
				   SUM(CASE WHEN B.BIN_TRANSFER<>1 THEN A.XN_VALUE_WITHOUT_GST ELSE 0 END) AS CHI_TAXABLE_VALUE,
				   SUM(CASE WHEN B.BIN_TRANSFER<>1 THEN A.igst_amount+a.sgst_amount+a.cgst_amount ELSE 0 END) AS CHI_TAX_AMOUNT,			       
				   a.BIN_ID  AS [BIN_ID] 
				 FROM IND01106 A 
				 JOIN INM01106 B ON A.INV_ID = B.INV_ID 
				 '+@CINSJOINSTR+' 
				 WHERE '+@CFILTER+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0 
				 GROUP BY  LEFT(B.INV_ID,2),B.INV_DT,A.PRODUCT_CODE,A.BIN_ID
				 ) xn  
				 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
				 AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
				 WHERE b.product_code IS NULL'
	   PRINT @CCMD
	   EXEC SP_EXECUTESQL @CCMD


	   SET @CSTEP=190		   
	   
	   IF @cBuildXnType IN ('WPR','')
	   BEGIN
		   SET @CCMD=N'UPDATE A SET WPR_QTY=A.WPR_QTY+ISNULL(B.WPR_QTY,0)
					 FROM '+@cRFTABLEName+' a
					 JOIN 
					 (
					  SELECT LEFT(B.INV_ID,2) AS DEPT_ID,  
					  B.INV_DT  AS XN_DT,   
					  A.PRODUCT_CODE,  
					  SUM(A.QUANTITY) AS WPR_QTY,
					  A.BIN_ID 
					 FROM IND01106 A
					 JOIN INM01106 B ON A.INV_ID = B.INV_ID '+@CINSJOINSTR+'
					 JOIN 
					 (SELECT DET.PS_ID, DET.BIN_ID,DET.PRODUCT_CODE FROM  
						  WPS_DET DET 
						 JOIN WPS_MST C ON DET.PS_ID =C.PS_ID    
						 JOIN inm01106 a (NOLOCK) ON a.inv_id=c.wsl_inv_id'+@CINSJOINSTR+'
						 WHERE '+@CFILTER+' AND C.CANCELLED = 0 AND ISNULL(DET.PS_ID,'''')<>'''' 
						 GROUP BY DET.PS_ID, DET.BIN_ID,DET.PRODUCT_CODE
					 ) DET ON A.PRODUCT_CODE=DET.PRODUCT_CODE AND A.PS_ID=DET.PS_ID AND A.BIN_ID=DET.BIN_ID

					 WHERE '+@CFILTER+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0
					 GROUP BY LEFT(B.INV_ID,2) ,B.INV_DT,A.PRODUCT_CODE,A.BIN_ID
					 ) B ON a.product_code=b.product_code AND a.xn_dt=b.xn_dt AND a.dept_id=b.dept_id AND a.bin_id=b.bin_id '
			
			PRINT @CCMD
			EXEC SP_EXECUTESQL @CCMD	 
		    
			SET @CSTEP=200		   	
		    
			SET @CCMD=N'INSERT '+@cRFTABLEName+' 
						(DEPT_ID,XN_DT,PRODUCT_CODE,wpr_QTY,BIN_ID)
					   SELECT xn.dept_id,xn.xn_dt,xn.product_code,xn.wpr_QTY,xn.bin_id FROM 
					  (	
					  SELECT LEFT(B.INV_ID,2) AS DEPT_ID,  
					   B.INV_DT AS XN_DT,  
					   A.PRODUCT_CODE, 
					   SUM(A.QUANTITY) AS wpr_QTY,  
					   a.BIN_ID  AS [BIN_ID] 
					 FROM IND01106 A 
					 JOIN INM01106 B ON A.INV_ID = B.INV_ID 
					 JOIN 
					 (SELECT DET.PS_ID, DET.BIN_ID,C.PS_NO,DET.PRODUCT_CODE FROM  
						  WPS_DET DET 
						 JOIN WPS_MST C ON DET.PS_ID =C.PS_ID    
						 JOIN inm01106 a (NOLOCK) ON a.inv_id=c.wsl_inv_id'+@CINSJOINSTR+'
						 WHERE '+@CFILTER+' AND C.CANCELLED = 0 AND ISNULL(DET.PS_ID,'''')<>'''' 
						 GROUP BY DET.PS_ID, DET.BIN_ID,C.PS_NO,DET.PRODUCT_CODE
					 ) DET ON A.PRODUCT_CODE=DET.PRODUCT_CODE AND A.PS_ID=DET.PS_ID AND A.BIN_ID=DET.BIN_ID

					 WHERE '+@CFILTER+' AND ISNULL(B.xn_item_type,0) in (0,1)  AND B.CANCELLED = 0 
					 GROUP BY LEFT(B.INV_ID,2) ,B.INV_DT,A.PRODUCT_CODE,A.BIN_ID 
					 ) xn
 					 LEFT OUTER JOIN '+@cRFTABLEName+' b ON xn.dept_id=b.dept_id AND xn.xn_dt=b.xn_dt 
					 AND xn.product_code=b.product_code AND xn.bin_id=b.bin_id
					 WHERE b.product_code IS NULL'			     
		   PRINT @CCMD
		   EXEC SP_EXECUTESQL @CCMD
	  END

	  
	  
	END
	
	--END OF BUILD PROCESS FOR WHOLESALE TRANSACTION
END TRY
BEGIN CATCH
	SET @CERRMSG='SP3SBUILDWSL: STEP :'+@CSTEP+',ERROR :'+ERROR_MESSAGE()
END CATCH	
	
ENDPROC:

END
--End of procedure - SP3SBuildWSL
/*
select * from jmloc3_rfopt..rf_opt_new

select * from wps_mst where wsl_inv_id<>''

update jmloc3_rfopt..rf_opt set wsl_qty=0,wpr_qty=0,wpi_qty=0

select * from jmloc3_rfopt..rf_opt_ops_01118

select top 100 entry_mode,inv_id,last_update as lupd,* from inm01106 order by last_update desc
declare @CERRMSG VARCHAR(MAX)
exec SP3SBUILDWSL
	 @CXNID='JM01119JM/11-12/-000064'
	,@NUPDATEMODE=1
	,@cRfTableName ='jmho_rfopt..rf_opt'
	,@CERRMSG=@CERRMSG OUTPUT
select @CERRMSG	


*/
