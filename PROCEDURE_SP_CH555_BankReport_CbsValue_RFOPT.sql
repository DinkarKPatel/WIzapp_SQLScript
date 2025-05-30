
-- PROCEDURE TO GET CLOSING STOCK VALUE FROM RF_OPT TABLES
-- USED IN PROCEDURE CLOSINGSTOCKINVENTORY
CREATE PROCEDURE SP_CH555_BANKREPORT_CBSVALUE_RFOPT
(
	@CDEPTID VARCHAR(4),
	@DTODT DATETIME
)
--WITH ENCRYPTION
AS
BEGIN	
	--SET @CDEPTID = ''
	--SET @DTODT = '2010-03-31'
--(dinkar) Replace  left(memoid,2) to Location_code 
	DECLARE @CCMD NVARCHAR(MAX),
			@CRFDBNAME VARCHAR(200),
			@CFINYEARSUFFIX VARCHAR(10)

	SELECT @CRFDBNAME = VALUE FROM CONFIG WHERE CONFIG_OPTION ='RFDB_NAME'

	IF @CRFDBNAME IS NULL
		SET @CRFDBNAME = ''
	
	IF @CRFDBNAME = ''
		SET @CRFDBNAME = DB_NAME()

	IF @CRFDBNAME <> '' 
		SET @CRFDBNAME = '[' + @CRFDBNAME + '].[DBO].'

	SET @CFINYEARSUFFIX = '_01'+DBO.FN_GETFINYEAR(@DTODT)
	
	SET @CCMD = N'
				IF NOT EXISTS ( SELECT NAME FROM ' + @CRFDBNAME + 'SYSOBJECTS 
							WHERE NAME = ''RF_OPT' + @CFINYEARSUFFIX + ''' )
					SET @CFINYEARSUFFIX = '''''
	EXEC SP_EXECUTESQL @CCMD, N'@CFINYEARSUFFIX VARCHAR(10) OUTPUT', @CFINYEARSUFFIX OUTPUT


	SET @CCMD = N'

	DECLARE @LOCLISTC TABLE ( DEPT_ID CHAR(4) )
	
	IF @CDEPTID <> ''''
		INSERT @LOCLISTC VALUES ( @CDEPTID )
	ELSE
	BEGIN
		IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @@SPID )
			INSERT @LOCLISTC
			SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @@SPID
		ELSE
			INSERT @LOCLISTC
			SELECT DEPT_ID FROM LOCATION WHERE LOC_TYPE=1 AND INACTIVE=0 AND DEPT_ID=MAJOR_DEPT_ID
	END
	
	DECLARE @CNCRATE TABLE ( DEPT_ID VARCHAR(4), PRODUCT_CODE VARCHAR(50), D_RATE NUMERIC(12,2) )
	
	INSERT @CNCRATE
	SELECT	A.DEPT_ID, A.PRODUCT_CODE,
			SUM(CASE WHEN B.CNC_TYPE = 1 THEN (A.RATE * A.QUANTITY ) *-1 ELSE (A.RATE * A.QUANTITY ) END ) AS D_RATE
	FROM ICD01106 A
	JOIN ICM01106 B ON A.CNC_MEMO_ID = B.CNC_MEMO_ID
	WHERE B.CANCELLED = 0
	AND   B.STOCK_ADJ_NOTE = 1
	AND   B.CNC_MEMO_DT <= @DTODT
	GROUP BY A.DEPT_ID, A.PRODUCT_CODE
	
	SELECT	X.MAJOR_DEPT_ID, X.MAJOR_DEPT_ID + '' '' + Y.DEPT_NAME AS DEPT_NAME, 
			X.SECTION_NAME, SUM(ISNULL(X.CBP , 0)) AS CBP
	FROM 
	(
        SELECT LOC_VIEW.MAJOR_DEPT_ID, SM.SECTION_NAME
              ,CAST(SUM(([OPS_QTY] + (CASE WHEN  XN_DT <= @DTODT THEN (PFI_QTY+PUR_QTY+CHI_QTY+SLR_QTY+UNC_QTY+APR_QTY+WSR_QTY+PFG_QTY+DCI_QTY+JWR_QTY  -PRT_QTY-CHO_QTY-SLS_QTY-CNC_QTY-APP_QTY-WSL_QTY-DCO_QTY-JWI_QTY-DLM_QTY-CIP_QTY) ELSE 0 END))* (B.BASIC_COST+ISNULL(T.D_RATE,0))) AS NUMERIC(14,2)) AS CBP
		FROM ' + @CRFDBNAME + 'RF_OPT' + @CFINYEARSUFFIX + ' A  (NOLOCK) 
		JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE
		JOIN ARTICLE ART (NOLOCK) ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE
		JOIN SECTIOND SD (NOLOCK) ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE
		JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE
		JOIN LOC_VIEW  (NOLOCK) ON A.DEPT_ID = LOC_VIEW.DEPT_ID
		JOIN @LOCLISTC  LOCLIST ON LOC_VIEW.MAJOR_DEPT_ID = LOCLIST.DEPT_ID
		LEFT OUTER JOIN VW_STOCKVALUE  B ON A.PRODUCT_CODE = B.PRODUCT_CODE 
		LEFT OUTER JOIN @CNCRATE T ON A.PRODUCT_CODE = T.PRODUCT_CODE AND A.DEPT_ID = T.DEPT_ID 
        GROUP BY LOC_VIEW.MAJOR_DEPT_ID, SM.SECTION_NAME

        UNION ALL 

        SELECT LOC_VIEW.MAJOR_DEPT_ID, SM.SECTION_NAME
              ,CAST(SUM(([OPS_QTY] + (CASE WHEN  XN_DT <= @DTODT THEN (PFI_QTY+PUR_QTY+CHI_QTY+SLR_QTY+UNC_QTY+APR_QTY+WSR_QTY+PFG_QTY+DCI_QTY+JWR_QTY  -PRT_QTY-CHO_QTY-SLS_QTY-CNC_QTY-APP_QTY-WSL_QTY-DCO_QTY-JWI_QTY-DLM_QTY-CIP_QTY) ELSE 0 END))* (B.BASIC_COST+ISNULL(T.D_RATE,0))) AS NUMERIC(14,2)) AS CBP
		FROM ' + @CRFDBNAME + 'RF_OPT_WH' + @CFINYEARSUFFIX + ' A  (NOLOCK) 
		JOIN SKU (NOLOCK) ON A.PRODUCT_CODE = SKU.PRODUCT_CODE
		JOIN ARTICLE ART (NOLOCK) ON SKU.ARTICLE_CODE = ART.ARTICLE_CODE
		JOIN SECTIOND SD (NOLOCK) ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE
		JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE
		JOIN LOC_VIEW  (NOLOCK) ON A.DEPT_ID = LOC_VIEW.DEPT_ID
		JOIN @LOCLISTC  LOCLIST ON LOC_VIEW.MAJOR_DEPT_ID = LOCLIST.DEPT_ID
		LEFT OUTER JOIN VW_STOCKVALUE  B ON A.PRODUCT_CODE = B.PRODUCT_CODE 
		LEFT OUTER JOIN @CNCRATE T ON A.PRODUCT_CODE = T.PRODUCT_CODE AND A.DEPT_ID = T.DEPT_ID 
        GROUP BY LOC_VIEW.MAJOR_DEPT_ID, SM.SECTION_NAME
	) X
	JOIN LOCATION Y ON X.MAJOR_DEPT_ID = Y.DEPT_ID
	GROUP BY X.MAJOR_DEPT_ID, Y.DEPT_NAME, X.SECTION_NAME
	ORDER BY X.MAJOR_DEPT_ID, X.SECTION_NAME'

	PRINT @CCMD
	EXEC SP_EXECUTESQL @CCMD, 
		N'@DTODT DATETIME, @CDEPTID VARCHAR(4)', 
		@DTODT, @CDEPTID
END
--*********************************************** END OF PROCEDURE SP_CH555_BANKREPORT_CBSVALUE_RFOPT
