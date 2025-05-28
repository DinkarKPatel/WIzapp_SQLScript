CREATE PROCEDURE SP3S_PROCESS_EOSSSCHNAMES_XPERT
@cXnType VARCHAR(50),
@dFromDt DATETIME,
@dToDt DATETIME,
@bEossSchDataFetched BIT,
@cEossSchJoinStr VARCHAR(200) OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN

	DECLARE @nStkColsmode NUMERIC(1,0),@EossCFILTERCRITERIA VARCHAR(MAX),@cPcKeyField VARCHAR(100),@cLocIdKeyField VARCHAR(200)

	CREATE TABLE #tEossXpert (errmsg VARCHAR(MAX))

	IF @bEossSchDataFetched=0
	BEGIN
		IF EXISTS (SELECT TOP 1 COL_EXPR FROM #rep_det WHERE key_col='OBS')
		AND EXISTS (SELECT TOP 1 COL_EXPR FROM #rep_det WHERE key_col='CBS')
			SET @nStkColsmode=3
		ELSE
		IF EXISTS (SELECT TOP 1 COL_EXPR FROM #rep_det WHERE key_col='OBS')
			SET @nStkColsmode=2
		ELSE
			SET @nStkColsmode=1
					

		EXEC SP_GETCBS_DETAILS  
		@DFROMDT=@dFromDt,
		@DTODT=@DTODT,  
		@CJOINSTR=' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code ',
		@nStkColsmode=@nStkColsmode,
		@bCalledFromXpert=1

		IF EXISTS (SELECT TOP 1 * FROM #tEossXpert WHERE errmsg<>'')
		BEGIN
			SELECT TOP 1 @cErrormsg=ERRMSG FROM #tEossXpert 
			GOTO END_PROC
		END
	END

	SELECT TOP 1 @cLocIdKeyField=col_expr FROM transaction_analysis_master_COLS a (NOLOCK)
	WHERE a.xn_type=@cXnType  AND  a.col_header='Location Id' and a.rep_type='Stock'

	SELECT TOP 1 @cPcKeyField=col_expr FROM transaction_analysis_master_COLS a (NOLOCK)
	WHERE a.xn_type=@cXnType  AND  a.col_header='Item Code' and a.rep_type='Stock'

	IF ISNULL(@cPcKeyField,'')=''
		SET @cPcKeyField='a.product_code'

	SET @cEossSchJoinStr=' LEFT JOIN ##tmpcbsstk tc ON tc.SLS_PRODUCT_CODE='+@cPcKeyField+' AND tc.dept_id='+@cLocIdKeyField

END_PROC:

END
