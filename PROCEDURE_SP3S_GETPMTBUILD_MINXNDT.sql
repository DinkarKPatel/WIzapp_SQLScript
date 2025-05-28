CREATE PROCEDURE SP3S_GETPMTBUILD_MINXNDT
@nBuildType NUMERIC(1,0)=1,
@dMInXndt DATETIME OUTPUT
AS
BEGIN
	DECLARE @cLastBuildLupd VARCHAR(40),@dMinxnDtNew DATETIME,@cMinDtTrn varchar(50),@dLastBuildLupd datetime,
	@dOldMinXnDt DATETIME,@dCutoffDate DATETIME
	
	SELECT @dMinxnDt='',@dOldMinXnDt=''
	
	SET @dCutoffDate = DATEADD(DD,-365,CONVERT(DATE,GETDATE()))
	
	IF @nBuildType=1
		SELECT TOP 1 @cLastBuildLupd=VALUE FROM config where config_option='cutoff_date_pmtlocs_rebuild'
	ELSE
		SELECT TOP 1 @cLastBuildLupd=VALUE FROM config where config_option='cutoff_date_dashboard_rebuild'	
	
	SET @cLastBuildLupd=ISNULL(@cLastBuildLupd,'')
	
	IF @cLastBuildLupd=''
	BEGIN
		SET @dMinxnDt=DATEADD(DD,-365,GETDATE())
		RETURN
	END	
	else
		set @dLastBuildLupd=CONVERT(DATE,@cLastBuildLupd)
	
	SET @dOldMinXnDt=@dLastBuildLupd
		
	SELECT @dMInXndtNew=MIN(receipt_dt) FROM pim01106 (NOLOCK) WHERE last_update>@dLastBuildLupd AND receipt_Dt<>''
	AND receipt_dt>=@dCutoffDate
	
	SET @dMinxnDt=isnull(@dMInXndtNew,'')

	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='pur'

	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(XN_DT) FROM OPS01106 (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND xn_dt>=@dCutoffDate
		
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)	
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='OPS'

	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(memo_dt) FROM FLOOR_ST_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND memo_dt>=@dCutoffDate
		
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)	
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='flr'
	
	--SELECT @dMinxnDt,@cMinDtTrn
	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(memo_dt) FROM GRN_PS_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND memo_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)		

	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='grn'
	
	--SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(inv_dt) FROM INM01106 (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND inv_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)		
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='wsl'
	
	--SELECT @dMinxnDt,@cMinDtTrn	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(rm_dt) FROM RMM01106 (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND rm_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)		
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='prt'
	
	--SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(receipt_dt) FROM CNM01106 (NOLOCK) WHERE last_update>@dLastBuildLupd AND mode=2 AND receipt_dt<>''
	AND receipt_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)		
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='grp_wsr'
	
	--SELECT @dMinxnDt,@cMinDtTrn	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(cn_dt) FROM CNM01106 (NOLOCK) WHERE last_update>@dLastBuildLupd AND mode=1
	AND cn_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)		
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='wsr'
	
	--SELECT @dMinxnDt,@cMinDtTrn
			
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(cm_dt) FROM CMM01106 (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND cm_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)		
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='sls'
	
	--SELECT @dMinxnDt,@cMinDtTrn
	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(memo_dt) FROM APM01106 (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND memo_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)			
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='app'
	
	--SELECT @dMinxnDt,@cMinDtTrn
	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(memo_dt) FROM APPROVAL_RETURN_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND memo_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)			
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='apr'
	
	--SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(CNC_memo_dt) FROM ICM01106 (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND cnc_memo_dt>=@dCutoffDate AND ISNULL(stock_adj_note,0)=0
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)			

	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='cnc'
	
	--SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(ps_dt) FROM WPS_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND ps_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				
	
	IF @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='wps'
	
	--SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(memo_dt) FROM SCM01106 (NOLOCK) WHERE last_update>=@dLastBuildLupd
	AND memo_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='scm'
	
	--SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(issue_dt) FROM JOBWORK_ISSUE_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND issue_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='jwi'
	
	--SELECT @dMinxnDt,@cMinDtTrn	
	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(receipt_dt) FROM JOBWORK_RECEIPT_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND receipt_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='jwr'
	
	--SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(receipt_dt) FROM snc_mst (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND receipt_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='snc'

	--SELECT @dMinxnDt,@cMinDtTrn
	
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(memo_dt) FROM TRANSFER_TO_TRADING_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND memo_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='ttm'
	
	----SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(PS_dt) FROM DNPS_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND ps_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				
	
	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='dnps'
	
	----SELECT @dMinxnDt,@cMinDtTrn
		
	SELECT @dMInXndtNew='',@dOldMinXnDt=@dMinXnDt
	SELECT @dMInXndtNew=MIN(ISSUE_dt) FROM BOM_ISSUE_MST (NOLOCK) WHERE last_update>@dLastBuildLupd
	AND issue_dt>=@dCutoffDate
	
	SET @dMinxnDt=(CASE WHEN @dMinXnDt='' OR (@dMinxnDt>ISNULL(@dMInXndtNew,'') AND ISNULL(@dMInXndtNew,'')<>'') THEN ISNULL(@dMInXndtNew,'') ELSE @dMInXndt END)				

	if @dMinxnDt<>@dOldMinXnDt
		set @cMinDtTrn='bom'
	
	----SELECT @dMinxnDt,@cMinDtTrn
	
	--select @cMinDtTrn,@dLastBuildLupd
END
/*
declare @dMinxndt datetime
exec SP3S_GETPMTBUILD_MINXNDT @dMInXndt output
select @dMinXndt

--select VALUE FROM config where config_option='cutoff_date_pmtlocs_rebuild'
--select min(ps_dt) from wps_mst (nolock) where last_update>'2019-05-10'

--select ps_dt,LAST_UPDATE, * from wps_mst (nolock) where last_update>'2019-05-10'


SELECT * FROM EXE_TIME

declare @cErrormsg varchar(max)
exec SP3sBuildLocWisePmtXns '2019-06-21',@cErrormsg
select @cErrormsg


exec SP3sBuildLocWisePmtXns '2019-03-31',''
exec sp3s_process_locwisepmt '2019-06-21'

UPDATE OPS01106 SET last_update=GETDATE() 

select SUM(quantity_OB) FROM OPS01106 where dept_id='03'
select SUM(cbs_qty) from WIZAPP3SHO_NEW_pmt..pmtlocs_20190621 where dept_id='03'
SELECT VALUE FROM config where config_option='cutoff_date_pmtlocs_rebuild'

update cmm01106 set last_update=GETDATE() where cm_dt='2019-04-29'
*/