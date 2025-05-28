CREATE PROCEDURE SP3S_UPDATESCHINFO_OPTIMIZED_DOCXNS
@cXnType varchar(20),
@cMemoId VARCHAR(40)
AS
BEGIN

BEGIN TRY
	DECLARE @cStep VARCHAR(5),@cErrormsg VARCHAR(MAX),@CENABLEOPTIMIZEDSCHEMES VARCHAR(2),@cTargetDeptId VARCHAR(4),
	@cSourceDeptId VARCHAR(4),@cHoLocId VARCHAR(4),@bSourceServerLoc BIT,@bTargetServerLoc BIT

	SET @CSTEP = '10'
	SET @cErrormsg=''

	SELECT TOP 1 @CENABLEOPTIMIZEDSCHEMES=VALUE FROM CONFIG WHERE CONFIG_OPTION='ENABLE_OPTIMIZED_EOSS_SCHEMES'		
				
	IF ISNULL(@CENABLEOPTIMIZEDSCHEMES,'')<>'1'
	BEGIN
		PRINT 'Optimized eoss not enabled '
		GOTO END_PROC
	END

	SELECT TOP 1 @cHoLocId=value FROM  config (NOLOCK) WHERE config_option='ho_location_id'

	SET @CSTEP = '15'
	IF @cXntype='WSL'
		SELECT TOP 1 @cTargetDeptId=party_dept_id,@cSourceDeptId=LEFT(inv_id,2) FROM inm01106 (NOLOCK) WHERE inv_id=@cMemoId
	ELSE
	IF @cXntype='WSR'
		SELECT TOP 1 @cTargetDeptId=LEFT(cn_id,2),@cSourceDeptId=LEFT(rm_id,2) FROM cnm01106 (NOLOCK) WHERE rm_id=@cMemoId
	ELSE
	IF @cXntype='DOCWSL'
		SELECT TOP 1 @cTargetDeptId=LEFT(mrr_id,2),@cSourceDeptId=LEFT(inv_id,2) FROM pim01106 (NOLOCK) WHERE mrr_id=@cMemoId
	ELSE
	IF @cXntype='PUR'
		SELECT TOP 1 @cTargetDeptId=LEFT(mrr_id,2),@cSourceDeptId=LEFT(inv_id,2) FROM pim01106 (NOLOCK) WHERE mrr_id=@cMemoId	

	SET @CSTEP = '20'
	SELECT @bSourceServerLoc=ISNULL(server_loc,0) FROM location (NOLOCK) WHERE dept_id=@cSourceDeptId
	SELECT @bTargetServerLoc=ISNULL(server_loc,0) FROM location (NOLOCK) WHERE dept_id=@cTargetDeptId

	---- No need to populate sku-active_titles if Challan is between 2 centralized Locations
	---- because this process is already run when this challan was dispatched
	IF (@bSourceServerLoc=1 OR @cHoLocId=@cSourceDeptId) AND @bTargetServerLoc=1 AND @cXntype='DOCWSL'
	BEGIN
		PRINT 'CENTRALIZED '
	   GOTO END_PROC
	END

	SELECT PRODUCT_CODE INTO #TMPCMD FROM sku (NOLOCK) WHERE 1=2

	SET @CSTEP = '25'
	IF @cXntype='WSL'
		INSERT #TMPCMD
		SELECT PRODUCT_CODE FROM IND01106 a (NOLOCK)
		WHERE inv_id=@CMEMOID
	ELSE
	IF @cXntype='WSR'
		INSERT #TMPCMD
		SELECT PRODUCT_CODE FROM CND01106 a (NOLOCK)
		JOIN  cnm01106 b (NOLOCK) ON a.cn_id=b.cn_id WHERE b.RM_ID=@CMEMOID
	ELSE
	IF @cXntype='DOCWSL'
		INSERT #TMPCMD
		SELECT PRODUCT_CODE FROM PID01106 a (NOLOCK)
		JOIN  PIm01106 b (NOLOCK) ON a.mrr_id=b.mrr_id WHERE b.mrr_ID=@CMEMOID
	ELSE
		INSERT #TMPCMD
		SELECT PRODUCT_CODE FROM PID01106 a (NOLOCK)
		WHERE a.mrr_ID=@CMEMOID
		
	--if @@spid=362
	--	select 'check tmpcmd', * from #tmpcmd

	SET @CSTEP = '30'
	SELECT ROW_ID INTO #TMPFILTERCHANGE FROM SCHEME_SETUP_DET (NOLOCK) WHERE 1=2
	
	SET @CSTEP = '40'

	EXEC SP3S_GETFILTERED_TITLES 
	@NMODE=1,
	@CXNTYPE=@cXnType,
	@CMEMOID=@CMEMOID,       
	@CERRORMSG=@CERRORMSG OUTPUT
	

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_UPDATESCHINFO_OPTIMIZED_DOCXNS at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:

	SELECT ISNULL(@cErrormsg,'') errmsg
END
