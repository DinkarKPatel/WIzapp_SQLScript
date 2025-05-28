CREATE PROCEDURE SP3S_POPULATE_SKUACTIVETITLES
@cSchRowId VARCHAR(100)='',
@cXnType VARCHAR(20)='',
@cXnId VARCHAR(40)='',
@CERRORMSG VARCHAR(MAX) OUTPUT
AS
BEGIN
	SET @CERRORMSG=''
	DECLARE @CENABLEOPTIMIZEDSCHEMES VARCHAR(2),@cMemoId VARCHAR(40),@dStarttime datetime,@cBatchId VARCHAR(20),
	@dProcessdate datetime

	SET @dProcessDate=CONVERT(DATE,GETDATE())

	SELECT TOP 1 @CENABLEOPTIMIZEDSCHEMES=VALUE FROM CONFIG WHERE CONFIG_OPTION='ENABLE_OPTIMIZED_EOSS_SCHEMES'		
				
	IF ISNULL(@CENABLEOPTIMIZEDSCHEMES,'')<>'1' 
		RETURN
	
	SET @dStarttime=getdate()
	
	SET @cBatchId=''
	SET @CERRORMSG=''
	
	IF @cXntype<>''
	BEGIN
		SET @cMemoId=@cXnId
	END	

	SELECT a.row_id into #tmpFilterChange FROM scheme_setup_det a WHERE 1=2
	SELECT PRODUCT_CODE INTO #TMPCMD FROM DOCPRT_RMD01106_MIRROR (NOLOCK) WHERE 1=2

	IF @cSchRowId<>''
		INSERT #tmpFilterChange	
		SELECT a.row_id FROM scheme_setup_det a WHERE row_id=@cSchRowId
	ELSE
	IF @cXnType='' AND @cXnId=''
	BEGIN
		INSERT #tmpFilterChange	
		SELECT a.row_id FROM scheme_setup_det a (NOLOCK)
		JOIN scheme_Setup_mst c (NOLOCK) ON c.memo_no=a.memo_no
		WHERE @dProcessDate BETWEEN applicable_from_dt AND applicable_to_dt

		SET @cBatchId='BATCH'
	END
	ELSE
	IF @cXnType IN ('WSL','WSL_PARCEL')
	begin
		INSERT INTO #tmpCmd
		SELECT a.PRODUCT_CODE FROM  IND01106 a (NOLOCK) 
		LEFT JOIN sku_active_titles b (NOLOCK)	ON a.PRODUCT_CODE=b.product_Code
		LEFT JOIN sku_active_titles_get c (NOLOCK)	ON a.PRODUCT_CODE=c.product_Code
		WHERE INV_ID=@cXnId AND b.product_Code IS NULL AND c.product_Code IS NULL
	END
	ELSE
	IF @cXnType='WSR_CHI'
		INSERT INTO #tmpCmd
		SELECT PRODUCT_CODE FROM DOCPRT_RMD01106_MIRROR (NOLOCK) WHERE RM_ID=@cXnId
	ELSE
	IF @cXnType='PUR_CHI'
		INSERT INTO #tmpCmd
		SELECT PRODUCT_CODE FROM DOCWSL_IND01106_MIRROR (NOLOCK) WHERE INV_ID=@cXnId			
	ELSE
	IF @cXnType='UNC'
		INSERT INTO #tmpCmd
		SELECT PRODUCT_CODE FROM ICD01106 a (NOLOCK) JOIN icm01106 b (NOLOCK) ON a.cnc_memo_id=b.cnc_memo_id
		WHERE a.cnc_memo_id=@cXnId AND b.cnc_type=2
	ELSE
	IF @cXnType='SNC'
		INSERT INTO #tmpCmd
		SELECT b.PRODUCT_CODE FROM snc_det a (NOLOCK) JOIN snc_barcode_det b (NOLOCK) ON b.REFROW_ID=a.ROW_ID
		WHERE a.memo_id=@cXnId
	ELSE
	IF @cXnType='SLR'
		INSERT INTO #tmpCmd
		SELECT PRODUCT_CODE FROM CMD01106 (NOLOCK) WHERE cm_id=@cXnId AND quantity<0
	ELSE
	IF @cXnType='APR'
		INSERT INTO #tmpCmd
		SELECT apd_PRODUCT_CODE FROM approval_return_det a (NOLOCK)
		WHERE memo_id=@cXnId




	IF EXISTS (SELECT TOP 1 scheme_setup_det_row_id FROM sku_active_titles a (NOLOCK)
			   join #tmpFilterChange b on a.scheme_setup_det_row_id=b.row_id
			   UNION 
			   SELECT TOP 1 scheme_setup_det_row_id FROM sku_active_titles_get a (NOLOCK)
			   join #tmpFilterChange b on a.scheme_setup_det_row_id=b.row_id)   AND @cSchRowId<>''
	BEGIN	
		delete a from sku_active_titles a join #tmpFilterChange b on a.scheme_setup_det_row_id=b.row_id
		delete a from sku_active_titles_get a join #tmpFilterChange b on a.scheme_setup_det_row_id=b.row_id
	END

	IF @cXnType<>'' AND NOT EXISTS (SELECT TOP 1 product_code FROM #tmpcmd)
		GOTO END_PROC

	IF @cXnType<>''
		EXEC SP3S_GETFILTERED_TITLES 
		@NMODE=1,
		@CXNTYPE=@cXnType,
		@CMEMOID=@cMemoId,       
		@CERRORMSG=@CERRORMSG OUTPUT
	ELSE
	BEGIN
		exec SP3S_GETFILTERED_TITLES
		@nMode=3,
		@cBatchId=@cBatchId,
		@CERRORMSG=@CERRORMSG OUTPUT

		IF ISNULL(@CERRORMSG,'')=''
			UPDATE a SET scheme_built_last_update=last_update from scheme_setup_det a
			JOIN #tmpFilterChange b ON a.row_id=b.row_id
	END

END_PROC:
	 INSERT skutitles_build_log	( CERRORMSG, cSchRowId, cXnId, cXnType,start_time,end_time ) 
	 SELECT isnull(@CERRORMSG,'') CERRORMSG,@cSchRowId cSchRowId,@cXnId  cXnId,
	 @cXnType cXnType ,@dStarttime start_time,getdate() end_time
END