create PROCEDURE SP3S_INS_skuactivetitles_IRR
@cMemoId VARCHAR(50),
@cErrormsg VARCHAR(MAX) OUTPUT
as
begin
	declare @nTrgMode NUMERIC(1,0),@cStep VARCHAR(5),@cEnableOptSchemes VARCHAR(2)
	
BEGIN TRY
	
	SET @cStep='10'
	SET @CERRORMSG=''
	SELECT TOP 1 @cEnableOptSchemes=value FROM config (NOLOCK) WHERE config_option='enable_optimized_eoss_schemes'

	IF ISNULL(@cEnableOptSchemes,'')<>'1'
		RETURN
	
	SET @cStep='20'
	SELECT (CASE WHEN ISNULL(a.new_product_code,'')<>'' THEN a.new_product_code ELSE a.product_code END) product_code
	INTO #tmpcmd FROM ird01106 A (NOLOCK)
	JOIN IRM01106 B (NOLOCK) ON a.irm_memo_id=b.irm_memo_id
	WHERE a.irm_memo_id=@cMemoId AND TYPE<>2
	

	IF EXISTS (SELECT TOP 1 * FROM #tmpcmd)
	BEGIN
		
		SET @cStep='40'
		EXEC SP3S_GETFILTERED_TITLES
		@NMODE=4,  
		@CMEMOID=@cMemoId,
		@CERRORMSG=@CERRORMSG OUTPUT 	
	END

	--if @@spid=55
	--	select 'check sact',* from sku_active_titles where product_code='H11013232'

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @CERRORMSG='Error in Procedure SP3S_INS_skuactivetitles_IRR at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
END