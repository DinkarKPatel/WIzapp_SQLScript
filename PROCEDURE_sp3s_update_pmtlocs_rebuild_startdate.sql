CREATE PROCEDURE SP3S_UPDATE_PMTLOCS_REBUILD_STARTDATE
@cXnType VARCHAR(10),
@cMemoId VARCHAR(40)
AS
BEGIN
	DECLARE @cPmtLocsRebuildStartDt VARCHAR(10),@dMinXNDt DATETIME,@dMInXndtNew DATETIME,@cCurLocId VARCHAR(5),
	@cHoLocId VARCHAR(10),@cPmtLocsRebuildEndDt VARCHAR(10)
	
	SELECT @cCurLocId	= [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	SELECT @cHoLocId=[VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'
		
	IF @cCurLocId=@cHoLocId
		RETURN
	
	SELECT TOP 1 @cPmtLocsRebuildEndDt=value FROM config (NOLOCK) 
	WHERE config_option='pmtlocs_rebuild_end_date'
		
	SELECT TOP 1 @cPmtLocsRebuildStartDt=value FROM config (NOLOCK) 
	WHERE config_option='pmtlocs_rebuild_start_date'
	
	IF ISNULL(@cPmtLocsRebuildStartDt,'')='' AND ISNULL(@cPmtLocsRebuildEndDt,'')=''
		RETURN
	
	IF ISNULL(@cPmtLocsRebuildStartDt,'')<>''
		SET @dMinXNDt=CONVERT(DATE,@cPmtLocsRebuildStartDt)
	ELSE
		SET @dMinXNDt=CONVERT(DATE,@cPmtLocsRebuildEndDt)
			
		
	IF @cXnType='PUR'
		SELECT @dMInXndtNew=receipt_dt FROM pim01106 (NOLOCK) WHERE mrr_id=@cMemoId AND receipt_Dt<>''
		AND receipt_dt<@dMinXndt
	ELSE
	IF @cXnType='DCO'
		SELECT @dMInXndtNew=memo_dt FROM FLOOR_ST_MST (NOLOCK) WHERE memo_id=@cMemoId
		AND memo_dt<@dMinXnDt
	ELSE
	IF @cXnType='GRNPS'
		SELECT @dMInXndtNew=memo_dt FROM GRN_PS_MST (NOLOCK) WHERE memo_id=@cMemoId
		AND memo_dt<@dMinXnDt
	ELSE
	IF @cXnType='WSL'	
		SELECT @dMInXndtNew=inv_dt FROM INM01106 (NOLOCK) WHERE inv_id=@cMemoId
		AND inv_dt<@dMinXnDt
	ELSE
	IF @cXnType='PRT'
		SELECT @dMInXndtNew=rm_dt FROM RMM01106 (NOLOCK) WHERE rm_id=@cMemoId
		AND rm_dt<@dMinXnDt
	ELSE
	IF @cXnType='WSR_CHI'
		SELECT @dMInXndtNew=receipt_dt FROM CNM01106 (NOLOCK) WHERE cn_id=@cMemoId AND mode=2 AND receipt_dt<>''
		AND receipt_dt<@dMinXnDt
	ELSE
	IF @cXnType='WSR'
		SELECT @dMInXndtNew=cn_dt FROM CNM01106 (NOLOCK) WHERE cn_id=@cMemoId AND mode=1
		AND cn_dt<@dMinXnDt
	ELSE
	IF @cXnType='SLS'
		SELECT @dMInXndtNew=cm_dt FROM CMM01106 (NOLOCK) WHERE cm_id=@cMemoId
		AND cm_dt<@dMinXnDt
	ELSE
	IF @cXnType='APP'
		SELECT @dMInXndtNew=memo_dt FROM APM01106 (NOLOCK) WHERE memo_id=@cMemoId
		AND memo_dt<@dMinXnDt
	ELSE
	IF @cXnType='APR'
		SELECT @dMInXndtNew=memo_dt FROM APPROVAL_RETURN_MST (NOLOCK) WHERE memo_id=@cMemoId
		AND memo_dt<@dMinXnDt
	ELSE
	IF @cXnType='CNC'
		SELECT @dMInXndtNew=CNC_memo_dt FROM ICM01106 (NOLOCK) WHERE cnc_memo_id=@cMemoId
		AND cnc_memo_dt<@dMinXnDt AND ISNULL(stock_adj_note,0)=0
	ELSE
	IF @cXnType='WPS'
		SELECT @dMInXndtNew=ps_dt FROM WPS_MST (NOLOCK) WHERE ps_id=@cMemoId
		AND ps_dt<@dMinXnDt
	ELSE
	IF @cXnType='SCM'
		SELECT @dMInXndtNew=memo_dt FROM SCM01106 (NOLOCK) WHERE memo_id=@cMemoId
		AND memo_dt<@dMinXnDt
	ELSE
	IF @cXnType='JWI'
		SELECT @dMInXndtNew=issue_dt FROM JOBWORK_ISSUE_MST (NOLOCK) WHERE issue_id=@cMemoId
		AND issue_dt<@dMinXnDt
	ELSE
	IF @cXnType='JWR'
		SELECT @dMInXndtNew=receipt_dt FROM JOBWORK_RECEIPT_MST (NOLOCK) WHERE receipt_id=@cMemoId
		AND receipt_dt<@dMinXnDt
	ELSE
	IF @cXnType='SNC'
		SELECT @dMInXndtNew=receipt_dt FROM snc_mst (NOLOCK) WHERE memo_id=@cMemoId
		AND receipt_dt<@dMinXnDt
	ELSE
	IF @cXnType='TTM'	
		SELECT @dMInXndtNew=memo_dt FROM TRANSFER_TO_TRADING_MST (NOLOCK) WHERE memo_id=@cMemoId
		AND memo_dt<@dMinXnDt
	ELSE
	IF @cXnType='DNPS'	
		SELECT @dMInXndtNew=PS_dt FROM DNPS_MST (NOLOCK) WHERE ps_id=@cMemoId
		AND ps_dt<@dMinXnDt
	ELSE
	IF @cXnType='BOM'
		SELECT @dMInXndtNew=ISSUE_dt FROM BOM_ISSUE_MST (NOLOCK) WHERE issue_id=@cMemoId
		AND issue_dt<@dMinXnDt
	
	IF ISNULL(@dMInXndtNew,'')<@dMinXNDt AND ISNULL(@dMInXndtNew,'')<>''		
		SET @cPmtLocsRebuildStartDt=CONVERT(VARCHAR(10),@dMInXndtNew,120)
	ELSE
		SET @cPmtLocsRebuildStartDt=CONVERT(VARCHAR(10),@dMinXNDt,120)
	
	IF NOT EXISTS (SELECT TOP 1 value FROM config WHERE config_option='pmtlocs_rebuild_start_date')			
		INSERT config	(  config_option, value, last_update, row_id )  
		SELECT 	'pmtlocs_rebuild_start_date' AS config_option,
		@cPmtLocsRebuildStartDt AS value,GETDATE() AS last_update,'' AS row_id 
	ELSE
		UPDATE config SET value=@cPmtLocsRebuildStartDt WHERE config_option='pmtlocs_rebuild_start_date'
END