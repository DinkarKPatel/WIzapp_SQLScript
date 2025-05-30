CREATE PROCEDURE SP3S_FIX_ASSETS_REGISTER
@CFINYEAR VARCHAR(5),
@NMODE INT,
@CLOC VARCHAR(2)=''
AS
BEGIN
	DECLARE @CCMD NVARCHAR(MAX),@CRFDBNAME VARCHAR(500),@DFROMDT DATETIME,@DTODT DATETIME,
	@CERRORMSG VARCHAR(MAX),@CSTEP VARCHAR(5)

BEGIN TRY	
	SET @CSTEP='10'
	
	DECLARE @TFARCALC TABLE (ERRMSG VARCHAR(MAX))
	
	SET @CRFDBNAME=DB_NAME()+'_RFOPT.DBO.'
	
	SET @CSTEP='20'
	INSERT @TFARCALC
	EXEC SP3S_GET_FAR_DEP_VALUE
	
	
	SET @CSTEP='30'
	SELECT TOP 1 @CERRORMSG=ERRMSG FROM @TFARCALC
	
	IF ISNULL(@CERRORMSG,'')<>''
		GOTO END_PROC
	
	SET @CSTEP='40'	
	SELECT @DFROMDT=DBO.FN_GETFINYEARDATE(@CFINYEAR,1),@DTODT=DBO.FN_GETFINYEARDATE(@CFINYEAR,2)
	
	IF OBJECT_ID('TEMPDB..#FARSTOCK','U') IS NOT NULL
		DROP TABLE #FARSTOCK
	
	SET @CSTEP='50'
	SELECT PRODUCT_CODE,CBS,CBP AS BASE_VALUE,CBP AS OPENING_WDV,CBP AS DEPCN_VALUE,
	CBP AS CLOSING_WDV,CBS AS DEPCN_PCT  INTO #FARSTOCK FROM MONTH_WISE_CBS_DET WHERE 1=2
		
	SET @CCMD=N'SELECT A.PRODUCT_CODE,SUM((CASE WHEN XN_TYPE=''OPS'' 
													OR (XN_TYPE IN (''WPR'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR''))    
												THEN 1 
												
												WHEN XN_TYPE IN (''WPI'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
												THEN -1 
												ELSE 0.000 
										   END)* XN_QTY ) AS CBS,0 AS BASE_VALUE  
		FROM '+@CRFDBNAME+'RF_OPT A (NOLOCK)     
		JOIN SKU (NOLOCK) ON SKU.PRODUCT_CODE=A.PRODUCT_CODE
		JOIN ARTICLE D ON D.ARTICLE_CODE=SKU.ARTICLE_CODE
		JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=D.SUB_SECTION_CODE
		JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE
		JOIN LOCATION C (NOLOCK) ON C.DEPT_ID=A.DEPT_ID   
		WHERE ISNULL(SM.ITEM_TYPE,0)=3 
		AND XN_DT <= '''+CONVERT(VARCHAR,@DTODT,110)+''' 
		AND C.LOC_TYPE=1 AND ISNULL(D.STOCK_NA,0)=0
		AND XN_TYPE NOT IN (''SAC'',''SAU'')'
		+CASE @CLOC WHEN '' THEN '' ELSE ' AND A.DEPT_ID='''+@CLOC+'''' END+
		'GROUP BY A.PRODUCT_CODE
		HAVING SUM((CASE WHEN XN_TYPE=''OPS'' 
								OR (XN_TYPE IN (''WPR'',''SCF'',''OPS'',''PRD'', ''PUR'', ''CHI'', ''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'', ''PFG'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR''))    
						 THEN 1 
						 
						 WHEN XN_TYPE IN (''WPI'',''SCC'',''BOC'',''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'', ''CRM'', ''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
						 THEN -1 
						 ELSE 0.000 
					END)* XN_QTY )<>0'
	
	
	PRINT '60 '+@CCMD
	
	SET @CSTEP='60'
	INSERT #FARSTOCK (PRODUCT_CODE,CBS,BASE_VALUE)
	EXEC SP_EXECUTESQL @CCMD	
	
	
	SET @CSTEP='70'
	UPDATE A SET BASE_VALUE=(SELECT TOP 1 BASE_VALUE FROM FAR_DEPCN_VALUE B WHERE B.PRODUCT_CODE=A.PRODUCT_CODE
							 AND B.MODE=@NMODE ORDER BY XN_DT)*CBS
	FROM #FARSTOCK A
	
	UPDATE #FARSTOCK SET OPENING_WDV=BASE_VALUE
	
	SET @CSTEP='80'
	UPDATE A SET OPENING_WDV=BASE_VALUE-(ISNULL(B.DEPCN_VALUE,0)*CBS) 
	FROM  #FARSTOCK A
	JOIN (SELECT A.PRODUCT_CODE,SUM(A.DEPCN_VALUE) AS DEPCN_VALUE 
		  FROM FAR_DEPCN_VALUE A (NOLOCK)
	      JOIN #FARSTOCK B ON A.PRODUCT_CODE=B.PRODUCT_CODE
	      WHERE A.MODE=@NMODE AND A.XN_DT<@DFROMDT
	      GROUP BY A.PRODUCT_CODE
	      )B ON A.PRODUCT_CODE=B.PRODUCT_CODE
	
	SET @CSTEP='90'
	UPDATE #FARSTOCK SET DEPCN_VALUE=ISNULL(B.DEPCN_VALUE,0)*CBS FROM  #FARSTOCK A
	JOIN (SELECT A.PRODUCT_CODE,SUM(A.DEPCN_VALUE) AS DEPCN_VALUE 
		  FROM FAR_DEPCN_VALUE A (NOLOCK)
	      JOIN #FARSTOCK B ON A.PRODUCT_CODE=B.PRODUCT_CODE
	      WHERE A.MODE=@NMODE AND A.XN_DT=@DTODT
	      GROUP BY A.PRODUCT_CODE
	     ) B ON A.PRODUCT_CODE=B.PRODUCT_CODE    
	
	SET @CSTEP='100'
	UPDATE A SET DEPCN_PCT=B.DEPCN_PCT 
	FROM #FARSTOCK A
	JOIN FAR_DEPCN_VALUE B ON A.PRODUCT_CODE=B.PRODUCT_CODE 
	WHERE B.MODE=@NMODE AND B.XN_DT=@DTODT
	
	SET @CSTEP='110'
	UPDATE #FARSTOCK SET CLOSING_WDV=OPENING_WDV-DEPCN_VALUE
	
	SELECT SECTION_NAME,SUB_SECTION_NAME,ARTICLE_NO,A.PRODUCT_CODE,BASE_VALUE,RECEIPT_DT
	,OPENING_WDV,DEPCN_PCT AS DEPR_PCT,DEPCN_VALUE AS DEPR_AMT,CLOSING_WDV 
	FROM #FARSTOCK A
	JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE
	JOIN ARTICLE C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE
	JOIN SECTIOND D (NOLOCK) ON D.SUB_SECTION_CODE=C.SUB_SECTION_CODE
	JOIN SECTIONM E (NOLOCK) ON E.SECTION_CODE=D.SECTION_CODE

END TRY

BEGIN CATCH
	SET @CERRORMSG='ERROR IN PROCEDURE SP3S_FIX_ASSETS_REGISTER AT STEP #'+@CSTEP+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	IF ISNULL(@CERRORMSG,'')<>''
		SELECT @CERRORMSG AS ERRMSG	
END
