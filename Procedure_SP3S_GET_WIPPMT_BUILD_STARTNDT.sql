
CREATE PROCEDURE SP3S_GET_WIPPMT_BUILD_STARTNDT
@cDbName VARCHAR(300)='',
@dMInXndt DATETIME OUTPUT
AS
BEGIN

	DECLARE @dLastBuildLupd datetime,@cCmd NVARCHAR(MAX)

	IF @cDbName=''
		SET @cDbName=db_name()+'.dbo.'

	SELECT @dMinxnDt=''
	
	SET  @cCmd=N'SELECT @dLastBuildLupd=max(wippmt_starttime) FROM master..cloud_pmtbuild_log (NOLOCK) 
	WHERE dbname='''+REPLACE(@cDbName,'.dbo.','')+''' AND wippmt_endtime IS NOT NULL '
	EXEC SP_EXECUTESQL	@cCmd,N'@dLastBuildLupd datetime OUTPUT',@dLastBuildLupd OUTPUT

	SET @dLastBuildLupd=ISNULL(@dLastBuildLupd,'')

	
	IF @dLastBuildLupd=''
	BEGIN
	    -- set @dMInXndt='2021-03-31'
	     SET @dMInXndt=convert(varchar(10),getdate()-1,121)
		--SET @cCmd=N' SELECT @dMInXndt=MIN(memo_dt) from '+@cDbName+'ORD_PLAN_MST (NOLOCK) WHERE cancelled=0  and memo_dt<>'''' and memo_dt>=''2015-04-01'' '
		--print @cCmd
		--EXEC SP_EXECUTESQL	@cCmd,N'@dMInXndt datetime OUTPUT',@dMInXndt OUTPUT

	RETURN
	END	

			
	SET @cCmd=N'SELECT @dMInXndt=MIN(min_xndt)
	FROM 
	(
	
	SELECT MIN(memo_dt) as min_xndt from '+@cDbName+'ORD_PLAN_MST (NOLOCK) WHERE ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	UNION ALL
	SELECT MIN(issue_dt) from '+@cDbName+'JOBWORK_ISSUE_MST (NOLOCK) WHERE ISNULL(ISSUE_MODE,0)=1 AND  ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	UNION ALL
	SELECT MIN(receipt_dt) from '+@cDbName+'JOBWORK_RECEIPT_MST (NOLOCK) WHERE ISNULL(Receive_Mode,0)=1 AND  ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	UNION ALL
	SELECT MIN(memo_dt) from '+@cDbName+'TRANSFER_TO_TRADING_MST (NOLOCK) WHERE ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	--UNION ALL
	--SELECT MIN(ISSUE_dt) from '+@cDbName+'BOM_ISSUE_MST (NOLOCK) WHERE ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	) a where isnull(min_xndt,'''')<>'''''
	print @cCmd
	EXEC SP_EXECUTESQL	@cCmd,N'@dMInXndt datetime OUTPUT',@dMInXndt OUTPUT

	IF @dMInXndt IS NULL
		SET @dMinxnDt=CONVERT(DATE,@dLastBuildLupd)
	ELSE 
		SET @dMinXndt=CONVERT(DATE,@dMinXndt)

END



