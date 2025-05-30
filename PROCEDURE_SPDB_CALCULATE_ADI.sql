CREATE PROCEDURE SPDB_CALCULATE_ADI
(
	 @DFROMDT DATETIME=''
	,@DTODT DATETIME
	,@CFILTERCOLS VARCHAR(MAX)=''
	,@CMODE CHAR(1)=0
	,@CLAYOUTCOLS VARCHAR(1000)=''
	,@CSETUPCODE CHAR(5)
)
--WITH ENCRYPTION
/**********
*******THIS PROCEDURE CALCULATES ADI - CONSIDERING STOCK AT DATES BETWEEN PASSED DATE RANGE
***********/
AS
BEGIN
SET NOCOUNT ON
	DECLARE @DLOOPDT DATETIME,@CPARA_NAME VARCHAR(500),@NINQTY NUMERIC(10,2),@NOUTQTY NUMERIC(10,2),
			@NINVAL NUMERIC(15,2),@NOUTVAL NUMERIC(15,2),@NCBSQTY NUMERIC(10,2),@NCBSVAL NUMERIC(15,2),
			@NOBSQTY NUMERIC(10,2),@NOBSVAL NUMERIC(15,2),@COLDDEPTID CHAR(2),@CCURDB VARCHAR(100),@CRFDB VARCHAR(100),
			@CCMD NVARCHAR(MAX),@CWHERECLAUSE VARCHAR(MAX),@CERRMSG VARCHAR(500),@CSTEP VARCHAR(5),
			@CDFROMDT VARCHAR(20),@CDTODT VARCHAR(20),@NLOOPCNT INT,@CDEPTID CHAR(2);	
	BEGIN TRY
	
	SET @NLOOPCNT=1
	
	SET @CSTEP=10
	IF ISNULL(@DTODT,'')=''
	BEGIN
		SET @CERRMSG='P:SPDB_CALCULATE_ADI,'+CHAR(13)+'STEP:'+@CSTEP+','+CHAR(13)+'MESSAGE:NO PROCESS DATE DEFINED FOR PROCESSING.....'
		GOTO EXIT_PROC		
	END	
	SET @CSTEP=20
	IF ISNULL(@DFROMDT,'')=''
		SELECT @DFROMDT=DBO.FN_GETFINYEARDATE('01'+DBO.FN_GETFINYEAR(@DTODT),1)
	
	SET @CSTEP=30
	IF ISNULL(@DFROMDT,'')=''
	BEGIN
		SET @CERRMSG='P:SPDB_CALCULATE_ADI,'+CHAR(13)+'STEP:'+@CSTEP+','+CHAR(13)+'MESSAGE:NO PROCESS DATE DEFINED FOR PROCESSING.....'
		GOTO EXIT_PROC		
	END	
	SET @CDFROMDT=CONVERT(VARCHAR,@DFROMDT,111)
	SET @CDTODT=CONVERT(VARCHAR,@DTODT,111)
	
	SET @CSTEP=40
	DECLARE @TDAYS TABLE (XN_DT DATETIME);
	
	SET @CSTEP=50
	SET @CCURDB=DB_NAME();
	--SET @CRFDB=@CCURDB+'_RFOPT..RF_OPT';
	SET @CRFDB=@CCURDB+'..VW_XNSREPS';
	SET @CWHERECLAUSE=''
	
	PRINT 'ADI-1'+CONVERT(VARCHAR,GETDATE(),113)
	SET @CSTEP=60	

	IF OBJECT_ID('TEMPDB..#TMPADI1','U') IS NOT NULL
		DROP TABLE #TMPADI1
		

	IF OBJECT_ID('TEMPDB..#TMPADI2','U') IS NOT NULL
		DROP TABLE #TMPADI2	


	IF OBJECT_ID('TEMPDB..#TMPADI3','U') IS NOT NULL
		DROP TABLE #TMPADI3
		
	PRINT 'ADI-2'+CONVERT(VARCHAR,GETDATE(),113)
	
	SET @CSTEP=70
	IF OBJECT_ID('TEMPDB..#TMPADIOB','U') IS NOT NULL
		DROP TABLE #TMPADIOB
	
	SET @CSTEP=80
	CREATE TABLE #TMPADIOB(DEPT_ID CHAR(2),PARA_NAME VARCHAR(500),CBS_VAL NUMERIC(18,2))

	SET @CSTEP=85
	CREATE TABLE #TMPADI1(DEPT_ID CHAR(2),PARA_NAME VARCHAR(500),XN_DT DATETIME,IN_VAL NUMERIC(18,2),OUT_VAL NUMERIC(18,2)
						  ,CBS_VAL NUMERIC(18,2))

	
	SELECT DEPT_ID,PARA_NAME,XN_DT,IN_VAL,OUT_VAL,CBS_VAL
	INTO #TMPADI2 FROM #TMPADI1
		
	SELECT DEPT_ID,PARA_NAME,ROUND(AVG(CBS_VAL),2) AS ADI
	INTO #TMPADI3 FROM #TMPADI2 GROUP BY DEPT_ID,PARA_NAME
	ORDER BY PARA_NAME

LBLSTART:
	
	TRUNCATE TABLE #TMPADI1
	TRUNCATE TABLE #TMPADI2
	TRUNCATE TABLE #TMPADI3
	TRUNCATE TABLE #TMPADIOB
	
	SET @CSTEP=90
	SET @CWHERECLAUSE=' WHERE XN_DT <'''+@CDFROMDT+''' AND ARTICLE.STOCK_NA=0 AND LOCATION.INACTIVE=0 '+(CASE WHEN ISNULL(@CFILTERCOLS,'')='' THEN '' ELSE ' AND ' END)
					 +@CFILTERCOLS
	SET @CSTEP=95
	SET @CCMD=N'SELECT '+(CASE WHEN @NLOOPCNT=1 THEN 'LOCATION.MAJOR_DEPT_ID AS DEPT_ID,' ELSE ''''' AS DEPT_ID,' END)
				+@CLAYOUTCOLS+'
				,SUM(CASE WHEN XN_TYPE IN (''OPS'', ''PUR'',''CHI'',''SLR'',''UNC'',''APR'', ''WSR'', ''PFI'', ''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') 
				THEN XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN POST_TAX_SEPARATELY=1 THEN 0
					 ELSE ISNULL(SKU_OH.TAX_AMOUNT,0) END)) 
				WHEN XN_TYPE IN (''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
				THEN -XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN POST_TAX_SEPARATELY=1 THEN 0
				ELSE  ISNULL(SKU_OH.TAX_AMOUNT,0) END)) ELSE 0 END) AS CBS_VAL 
				FROM '+@CRFDB+' A (NOLOCK)
				JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE
				JOIN LOCATION (NOLOCK) ON A.DEPT_ID=LOCATION.DEPT_ID
				LEFT JOIN SKU_OH (NOLOCK) ON SKU_OH.PRODUCT_CODE=SKU.PRODUCT_CODE
				JOIN FORM (NOLOCK) ON FORM.FORM_ID=SKU.FORM_ID
				JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE=ARTICLE.ARTICLE_CODE
				JOIN PARA1 (NOLOCK) ON SKU.PARA1_CODE=PARA1.PARA1_CODE
				JOIN PARA2 (NOLOCK) ON SKU.PARA2_CODE=PARA2.PARA2_CODE
				JOIN PARA3 (NOLOCK) ON SKU.PARA3_CODE=PARA3.PARA3_CODE
				JOIN PARA4 (NOLOCK) ON SKU.PARA4_CODE=PARA4.PARA4_CODE
				JOIN PARA5 (NOLOCK) ON SKU.PARA5_CODE=PARA5.PARA5_CODE
				JOIN PARA6 (NOLOCK) ON SKU.PARA6_CODE=PARA6.PARA6_CODE
				LEFT OUTER JOIN ARTICLE_FIX_ATTR ATTR  (NOLOCK) ON ARTICLE.ARTICLE_CODE = ATTR.ARTICLE_CODE 
				LEFT OUTER JOIN ATTR1_MST AT1 (NOLOCK) ON AT1.ATTR1_KEY_CODE=ATTR.ATTR1_KEY_CODE
				LEFT OUTER JOIN ATTR2_MST AT2 (NOLOCK) ON AT2.ATTR2_KEY_CODE=ATTR.ATTR2_KEY_CODE
				LEFT OUTER JOIN ATTR3_MST AT3 (NOLOCK) ON AT3.ATTR3_KEY_CODE=ATTR.ATTR3_KEY_CODE
				LEFT OUTER JOIN ATTR4_MST AT4 (NOLOCK) ON AT4.ATTR4_KEY_CODE=ATTR.ATTR4_KEY_CODE
				LEFT OUTER JOIN ATTR5_MST AT5 (NOLOCK) ON AT5.ATTR5_KEY_CODE=ATTR.ATTR5_KEY_CODE
				LEFT OUTER JOIN ATTR6_MST AT6 (NOLOCK) ON AT6.ATTR6_KEY_CODE=ATTR.ATTR6_KEY_CODE
				LEFT OUTER JOIN ATTR7_MST AT7 (NOLOCK) ON AT7.ATTR7_KEY_CODE=ATTR.ATTR7_KEY_CODE
				LEFT OUTER JOIN ATTR8_MST AT8 (NOLOCK) ON AT8.ATTR8_KEY_CODE=ATTR.ATTR8_KEY_CODE
				LEFT OUTER JOIN ATTR9_MST AT9 (NOLOCK) ON AT9.ATTR9_KEY_CODE=ATTR.ATTR9_KEY_CODE
				LEFT OUTER JOIN ATTR10_MST AT10 (NOLOCK) ON AT10.ATTR10_KEY_CODE=ATTR.ATTR10_KEY_CODE
				LEFT OUTER JOIN ATTR11_MST AT11 (NOLOCK) ON AT11.ATTR11_KEY_CODE=ATTR.ATTR11_KEY_CODE
				LEFT OUTER JOIN ATTR12_MST AT12 (NOLOCK) ON AT12.ATTR12_KEY_CODE=ATTR.ATTR12_KEY_CODE
				LEFT OUTER JOIN ATTR13_MST AT13 (NOLOCK) ON AT13.ATTR13_KEY_CODE=ATTR.ATTR13_KEY_CODE
				LEFT OUTER JOIN ATTR14_MST AT14 (NOLOCK) ON AT14.ATTR14_KEY_CODE=ATTR.ATTR14_KEY_CODE
				LEFT OUTER JOIN ATTR15_MST AT15 (NOLOCK) ON AT15.ATTR15_KEY_CODE=ATTR.ATTR15_KEY_CODE
				LEFT OUTER JOIN ATTR16_MST AT16 (NOLOCK) ON AT16.ATTR16_KEY_CODE=ATTR.ATTR16_KEY_CODE
				LEFT OUTER JOIN ATTR17_MST AT17 (NOLOCK) ON AT17.ATTR17_KEY_CODE=ATTR.ATTR17_KEY_CODE
				LEFT OUTER JOIN ATTR18_MST AT18 (NOLOCK) ON AT18.ATTR18_KEY_CODE=ATTR.ATTR18_KEY_CODE
				LEFT OUTER JOIN ATTR19_MST AT19 (NOLOCK) ON AT19.ATTR19_KEY_CODE=ATTR.ATTR19_KEY_CODE
				LEFT OUTER JOIN ATTR20_MST AT20 (NOLOCK) ON AT20.ATTR20_KEY_CODE=ATTR.ATTR20_KEY_CODE
				LEFT OUTER JOIN ATTR21_MST AT21 (NOLOCK) ON AT21.ATTR21_KEY_CODE=ATTR.ATTR21_KEY_CODE
				LEFT OUTER JOIN ATTR22_MST AT22 (NOLOCK) ON AT22.ATTR22_KEY_CODE=ATTR.ATTR22_KEY_CODE
				LEFT OUTER JOIN ATTR23_MST AT23 (NOLOCK) ON AT23.ATTR23_KEY_CODE=ATTR.ATTR23_KEY_CODE
				LEFT OUTER JOIN ATTR24_MST AT24 (NOLOCK) ON AT24.ATTR24_KEY_CODE=ATTR.ATTR24_KEY_CODE
				LEFT OUTER JOIN ATTR25_MST AT25(NOLOCK) ON AT25.ATTR25_KEY_CODE=ATTR.ATTR25_KEY_CODE
				JOIN SECTIOND (NOLOCK) ON ARTICLE.SUB_SECTION_CODE=SECTIOND.SUB_SECTION_CODE
				JOIN SECTIONM (NOLOCK) ON SECTIOND.SECTION_CODE=SECTIONM.SECTION_CODE
				JOIN LMV01106 (NOLOCK) ON SKU.AC_CODE=LMV01106.AC_CODE
				--JOIN LOC_VIEW (NOLOCK) ON A.DEPT_ID=LOC_VIEW.DEPT_ID
				JOIN BIN (NOLOCK) ON A.BIN_ID=BIN.BIN_ID
				'+@CWHERECLAUSE+'
				GROUP BY '+(CASE WHEN @NLOOPCNT=1 THEN 'LOCATION.MAJOR_DEPT_ID,' ELSE '' END)
							+@CLAYOUTCOLS
	PRINT ISNULL(@CCMD,'NULL CCMD')
	INSERT #TMPADIOB(DEPT_ID,PARA_NAME,CBS_VAL)
	EXEC SP_EXECUTESQL @CCMD
	
	
	PRINT 'ADI-3'+CONVERT(VARCHAR,GETDATE(),113)
	SET @CSTEP=130
	SET @CWHERECLAUSE=' WHERE XN_DT BETWEEN '''+@CDFROMDT+''' AND '''+@CDTODT+''' AND ARTICLE.STOCK_NA=0 AND LOCATION.INACTIVE=0 '
					  +(CASE WHEN ISNULL(@CFILTERCOLS,'')='' THEN '' ELSE ' AND ' END)
						+@CFILTERCOLS	
	SET @CSTEP=140
	SET @CCMD=N'SELECT '+(CASE WHEN @NLOOPCNT=1 THEN 'LOCATION.MAJOR_DEPT_ID AS DEPT_ID,' ELSE ''''' AS DEPT_ID,' END)
				+@CLAYOUTCOLS+'
				,A.XN_DT
				,SUM(( CASE WHEN A.XN_TYPE IN (''OPS'',''PUR'',''CHI'',''SLR'',''UNC'',''APR'',''WSR'',''PFI'',''BCG'',''MRP'',''DCI'',''PSB'',''JWR'') 
				 THEN (A.XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN FORM.POST_TAX_SEPARATELY=1 THEN 0
				 ELSE  ISNULL(SKU_OH.TAX_AMOUNT,0) END))) ELSE 0 END )) AS IN_VAL
				,SUM((CASE WHEN A.XN_TYPE IN (''PRT'',''CHO'',''SLS'',''CNC'',''APP'',''WSL'',''CIP'',''DCO'',''MIP'',''CSB'',''JWI'',''DLM'') 
				 THEN (A.XN_QTY*(SKU.PURCHASE_PRICE-ISNULL(SKU_OH.DISCOUNT_AMOUNT,0)+(CASE WHEN FORM.POST_TAX_SEPARATELY=1 THEN 0
				 ELSE  ISNULL(SKU_OH.TAX_AMOUNT,0) END))) ELSE 0 END)) AS OUT_VAL 
			,CONVERT(NUMERIC(15,2),0) AS CBS_VAL
	FROM '+@CRFDB+' A (NOLOCK)
	JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE
	JOIN LOCATION (NOLOCK) ON A.DEPT_ID=LOCATION.DEPT_ID
	LEFT JOIN SKU_OH (NOLOCK) ON SKU_OH.PRODUCT_CODE=SKU.PRODUCT_CODE
	JOIN FORM (NOLOCK) ON FORM.FORM_ID=SKU.FORM_ID
	JOIN ARTICLE (NOLOCK) ON SKU.ARTICLE_CODE=ARTICLE.ARTICLE_CODE
	JOIN PARA1 (NOLOCK) ON SKU.PARA1_CODE=PARA1.PARA1_CODE
	JOIN PARA2 (NOLOCK) ON SKU.PARA2_CODE=PARA2.PARA2_CODE
	JOIN PARA3 (NOLOCK) ON SKU.PARA3_CODE=PARA3.PARA3_CODE
	JOIN PARA4 (NOLOCK) ON SKU.PARA4_CODE=PARA4.PARA4_CODE
	JOIN PARA5 (NOLOCK) ON SKU.PARA5_CODE=PARA5.PARA5_CODE
	JOIN PARA6 (NOLOCK) ON SKU.PARA6_CODE=PARA6.PARA6_CODE
	LEFT OUTER JOIN ARTICLE_FIX_ATTR ATTR  (NOLOCK) ON ARTICLE.ARTICLE_CODE = ATTR.ARTICLE_CODE 
	LEFT OUTER JOIN ATTR1_MST AT1 (NOLOCK) ON AT1.ATTR1_KEY_CODE=ATTR.ATTR1_KEY_CODE
	LEFT OUTER JOIN ATTR2_MST AT2 (NOLOCK) ON AT2.ATTR2_KEY_CODE=ATTR.ATTR2_KEY_CODE
	LEFT OUTER JOIN ATTR3_MST AT3 (NOLOCK) ON AT3.ATTR3_KEY_CODE=ATTR.ATTR3_KEY_CODE
	LEFT OUTER JOIN ATTR4_MST AT4 (NOLOCK) ON AT4.ATTR4_KEY_CODE=ATTR.ATTR4_KEY_CODE
	LEFT OUTER JOIN ATTR5_MST AT5 (NOLOCK) ON AT5.ATTR5_KEY_CODE=ATTR.ATTR5_KEY_CODE
	LEFT OUTER JOIN ATTR6_MST AT6 (NOLOCK) ON AT6.ATTR6_KEY_CODE=ATTR.ATTR6_KEY_CODE
	LEFT OUTER JOIN ATTR7_MST AT7 (NOLOCK) ON AT7.ATTR7_KEY_CODE=ATTR.ATTR7_KEY_CODE
	LEFT OUTER JOIN ATTR8_MST AT8 (NOLOCK) ON AT8.ATTR8_KEY_CODE=ATTR.ATTR8_KEY_CODE
	LEFT OUTER JOIN ATTR9_MST AT9 (NOLOCK) ON AT9.ATTR9_KEY_CODE=ATTR.ATTR9_KEY_CODE
	LEFT OUTER JOIN ATTR10_MST AT10 (NOLOCK) ON AT10.ATTR10_KEY_CODE=ATTR.ATTR10_KEY_CODE
	LEFT OUTER JOIN ATTR11_MST AT11 (NOLOCK) ON AT11.ATTR11_KEY_CODE=ATTR.ATTR11_KEY_CODE
	LEFT OUTER JOIN ATTR12_MST AT12 (NOLOCK) ON AT12.ATTR12_KEY_CODE=ATTR.ATTR12_KEY_CODE
	LEFT OUTER JOIN ATTR13_MST AT13 (NOLOCK) ON AT13.ATTR13_KEY_CODE=ATTR.ATTR13_KEY_CODE
	LEFT OUTER JOIN ATTR14_MST AT14 (NOLOCK) ON AT14.ATTR14_KEY_CODE=ATTR.ATTR14_KEY_CODE
	LEFT OUTER JOIN ATTR15_MST AT15 (NOLOCK) ON AT15.ATTR15_KEY_CODE=ATTR.ATTR15_KEY_CODE
	LEFT OUTER JOIN ATTR16_MST AT16 (NOLOCK) ON AT16.ATTR16_KEY_CODE=ATTR.ATTR16_KEY_CODE
	LEFT OUTER JOIN ATTR17_MST AT17 (NOLOCK) ON AT17.ATTR17_KEY_CODE=ATTR.ATTR17_KEY_CODE
	LEFT OUTER JOIN ATTR18_MST AT18 (NOLOCK) ON AT18.ATTR18_KEY_CODE=ATTR.ATTR18_KEY_CODE
	LEFT OUTER JOIN ATTR19_MST AT19 (NOLOCK) ON AT19.ATTR19_KEY_CODE=ATTR.ATTR19_KEY_CODE
	LEFT OUTER JOIN ATTR20_MST AT20 (NOLOCK) ON AT20.ATTR20_KEY_CODE=ATTR.ATTR20_KEY_CODE
	LEFT OUTER JOIN ATTR21_MST AT21 (NOLOCK) ON AT21.ATTR21_KEY_CODE=ATTR.ATTR21_KEY_CODE
	LEFT OUTER JOIN ATTR22_MST AT22 (NOLOCK) ON AT22.ATTR22_KEY_CODE=ATTR.ATTR22_KEY_CODE
	LEFT OUTER JOIN ATTR23_MST AT23 (NOLOCK) ON AT23.ATTR23_KEY_CODE=ATTR.ATTR23_KEY_CODE
	LEFT OUTER JOIN ATTR24_MST AT24 (NOLOCK) ON AT24.ATTR24_KEY_CODE=ATTR.ATTR24_KEY_CODE
	LEFT OUTER JOIN ATTR25_MST AT25(NOLOCK) ON AT25.ATTR25_KEY_CODE=ATTR.ATTR25_KEY_CODE
	JOIN SECTIOND (NOLOCK) ON ARTICLE.SUB_SECTION_CODE=SECTIOND.SUB_SECTION_CODE
	JOIN SECTIONM (NOLOCK) ON SECTIOND.SECTION_CODE=SECTIONM.SECTION_CODE
	JOIN LMV01106 (NOLOCK) ON SKU.AC_CODE=LMV01106.AC_CODE
	--JOIN LOC_VIEW (NOLOCK) ON A.DEPT_ID=LOC_VIEW.DEPT_ID
	JOIN BIN (NOLOCK) ON A.BIN_ID=BIN.BIN_ID
	'+@CWHERECLAUSE+'
	GROUP BY '+(CASE WHEN @NLOOPCNT=1 THEN 'LOCATION.MAJOR_DEPT_ID,' ELSE '' END)
				+@CLAYOUTCOLS+',XN_DT'	

	PRINT ISNULL(@CCMD,'NULL COMMAND')
	SET @CSTEP=150
	INSERT #TMPADI1(DEPT_ID,PARA_NAME,XN_DT,IN_VAL,OUT_VAL,CBS_VAL)
	EXEC SP_EXECUTESQL @CCMD

	SET @CSTEP=160
	EXEC FILL_DT @CDFROMDT,@CDTODT

	PRINT 'ADI-4'+CONVERT(VARCHAR,GETDATE(),113)
	
	SET @CSTEP=170
	INSERT #TMPADI1 (DEPT_ID,PARA_NAME,XN_DT,IN_VAL,OUT_VAL,CBS_VAL)
	SELECT B.DEPT_ID,B.PARA_NAME,DT, 0 AS IN_VAL, 0 AS OUT_VAL,0 AS CBS_VAL
	FROM TIME_LINE,( SELECT DISTINCT A.DEPT_ID,A.PARA_NAME FROM #TMPADI1 A ) B
	WHERE TIME_LINE.DT  BETWEEN @DFROMDT AND @DTODT
	AND CONVERT(VARCHAR,DT,110)+B.DEPT_ID+B.PARA_NAME
	NOT IN (SELECT CONVERT(VARCHAR,XN_DT,110)+DEPT_ID+PARA_NAME FROM #TMPADI1)
	
	SET @CSTEP=180
	PRINT 'ADI-5'+CONVERT(VARCHAR,GETDATE(),113)
	
	SET @CSTEP=190
	IF CURSOR_STATUS('GLOBAL','ADICBSCUR') IN (0,1)
	BEGIN
		CLOSE ADICBSCUR
		DEALLOCATE ADICBSCUR
	END
	
	SET @CSTEP=200
	INSERT #TMPADIOB 
	SELECT DISTINCT A.DEPT_ID,A.PARA_NAME,0 AS CBS_VAL FROM #TMPADI1 A
	LEFT OUTER JOIN #TMPADIOB B ON A.DEPT_ID=B.DEPT_ID AND A.PARA_NAME=B.PARA_NAME
	WHERE B.PARA_NAME IS NULL
	
	INSERT #TMPADI2 (DEPT_ID,PARA_NAME,XN_DT,IN_VAL,OUT_VAL,CBS_VAL)
	SELECT DEPT_ID,PARA_NAME,XN_DT,IN_VAL,OUT_VAL,CBS_VAL FROM #TMPADI1
	ORDER BY DEPT_ID,PARA_NAME,XN_DT
	
	SET @CSTEP=210
	DECLARE ADICBSCUR CURSOR FOR SELECT DEPT_ID,PARA_NAME,CBS_VAL FROM #TMPADIOB
	SET @CSTEP=220
	PRINT 'ADI-6'+CONVERT(VARCHAR,GETDATE(),113)
	OPEN ADICBSCUR
	FETCH NEXT FROM ADICBSCUR INTO @CDEPTID,@CPARA_NAME,@NCBSVAL
	SET @CSTEP=230
	WHILE @@FETCH_STATUS=0
	BEGIN
		SET @CSTEP=240
		UPDATE #TMPADI2 SET CBS_VAL=@NCBSVAL,
						    @NCBSVAL=@NCBSVAL+IN_VAL-OUT_VAL
		WHERE DEPT_ID=@CDEPTID AND PARA_NAME=@CPARA_NAME
		
		FETCH NEXT FROM ADICBSCUR INTO @CDEPTID,@CPARA_NAME,@NCBSVAL
	END

	CLOSE ADICBSCUR
	DEALLOCATE ADICBSCUR	
	
	INSERT #TMPADI3(DEPT_ID,PARA_NAME,ADI)
	SELECT DEPT_ID,PARA_NAME,ROUND(AVG(CBS_VAL),2) AS ADI
	FROM #TMPADI2 GROUP BY DEPT_ID,PARA_NAME
	ORDER BY PARA_NAME
	
	SET @NLOOPCNT=@NLOOPCNT+1

	UPDATE DB_GMROI_SUMMARY SET ADI=B.ADI FROM #TMPADI3 B
	WHERE B.DEPT_ID=DB_GMROI_SUMMARY.DEPT_ID AND B.PARA_NAME=DB_GMROI_SUMMARY.PARA_VAL
	AND SETUP_CODE=@CSETUPCODE
	
	SELECT * FROM #TMPADI1
	SELECT * FROM #TMPADI2
	SELECT * FROM #TMPADI3
	
	IF @NLOOPCNT<=2
		GOTO LBLSTART

END TRY

BEGIN CATCH
	SET @CERRMSG='P:SPDB_CALCULATE_ADI,'+CHAR(13)+'STEP:'+@CSTEP+','+CHAR(13)+'MESSAGE:'+ERROR_MESSAGE()
	GOTO EXIT_PROC
END CATCH

EXIT_PROC:
	IF ISNULL(@CERRMSG,'')<>''
		SELECT @CERRMSG AS ERRMSG
END
--END OF PROCEDURE - SPDB_CALCULATE_ADI
