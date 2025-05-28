CREATE PROCEDURE SPWOW_GETPMTBUILD_STARTNDT
@cDbName VARCHAR(300)='',
@dMInXndt DATETIME OUTPUT,
@cMinXnType VARCHAR(50) OUTPUT
AS
BEGIN
	DECLARE @dLastBuildLupd datetime,@cCmd NVARCHAR(MAX),@dlastDtChanged DATETIME,@cLastXntype VARCHAR(50)
	   
	IF @cDbName=''
		SET @cDbName=db_name()+'.dbo.'

	SELECT @dMinxnDt=''
	
	SELECT @dLastBuildLupd=max(build_starttime) FROM opt_pmtbuild_log (NOLOCK) 
	WHERE dbname=REPLACE(@cDbName,'.dbo.','') AND build_endtime IS NOT NULL 
	   	
	SET @dLastBuildLupd=ISNULL(@dLastBuildLupd,'')
	
	IF @dLastBuildLupd='' 
	BEGIN
		IF EXISTS (SELECT TOP 1 mrr_id FROM pim01106)
		BEGIN
			SET @dMinxnDt=DATEADD(DD,-365,GETDATE())
			RETURN
		END
		ELSE
		BEGIN
			SELECT @dMinxnDt=min(xn_dt) FROM ops01106 (NOLOCK) where xn_dt<>''
			IF ISNULL(@dMinXnDt,'')=''
				SET @dMInXndt=CONVERT(DATE,GETDATE())

			RETURN
		END
	END	
	
			
	SET @cCmd=N'SELECT TOP 1  @dMInXndt=min_xndt,@cMinXnType=ISNULL(b.xn_type,a.xn_type)
	FROM 
	(
	SELECT MIN(receipt_dt) min_xndt,''PUR'' xn_type FROM '+@cDbName+'pim01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	) AND (receipt_Dt<>'''' OR inv_mode=1)
	UNION ALL	
	SELECT MIN(memo_dt),''FCO'' xn_type  FROM '+@cDbName+'FLOOR_ST_MST (NOLOCK) WHERE  (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL		
	SELECT MIN(memo_dt),''grnps'' xn_type  from '+@cDbName+'GRN_PS_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(inv_dt),''WSL'' xn_type  from '+@cDbName+'INM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(rm_dt),''PRT'' xn_type  from '+@cDbName+'RMM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(receipt_dt),''GRP_WSR'' xn_type  from '+@cDbName+'CNM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	) AND mode=2 AND receipt_dt<>''''
	UNION ALL
	SELECT MIN(cn_dt),''WSR'' xn_type  from '+@cDbName+'CNM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	) AND mode=1
	UNION ALL
	SELECT MIN(cm_dt),''SLS'' xn_type  from '+@cDbName+'CMM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(cm_dt),''RPS'' xn_type  from '+@cDbName+'rps_mst (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(memo_dt),''APM'' xn_type  from '+@cDbName+'APM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(memo_dt),''APR'' xn_type  from '+@cDbName+'APPROVAL_RETURN_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(CNC_memo_dt),''CNC'' xn_type  from '+@cDbName+'ICM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	AND ISNULL(stock_adj_note,0)=0
	UNION ALL
	SELECT MIN(ps_dt),''WPS'' xn_type  from '+@cDbName+'WPS_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(memo_dt),''SNC'' xn_type  from '+@cDbName+'SCM01106 (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(issue_dt),''JWI'' xn_type  from '+@cDbName+'JOBWORK_ISSUE_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(receipt_dt),''JWR'' xn_type  from '+@cDbName+'JOBWORK_RECEIPT_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(receipt_dt),''SNC'' xn_type  from '+@cDbName+'snc_mst (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(memo_dt),''TTM'' xn_type  from '+@cDbName+'TRANSFER_TO_TRADING_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(PS_dt),''DNPS'' xn_type  from '+@cDbName+'DNPS_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	UNION ALL
	SELECT MIN(ISSUE_dt),''Bom'' xn_type  from '+@cDbName+'BOM_ISSUE_MST (NOLOCK) WHERE (ISNULL(quantity_last_update,'''')>'''+convert(varchar,@dLastBuildLupd,113)+'''
	)
	) a 
	LEFT JOIN wow_XPERT_XNTYPeS_alias b ON a.xn_type=b.xn_type_alias
	where isnull(min_xndt,'''')<>''''
	order by min_xndt '
	
	
	print @cCmd
	EXEC SP_EXECUTESQL	@cCmd,N'@dMInXndt datetime OUTPUT,@cMInXntype VARCHAR(50) OUTPUT',@dMInXndt OUTPUT,@cMInXntype OUTPUT

	IF @dMInXndt IS NOT NULL
	BEGIN
		SET @dMinXndt=CONVERT(DATE,@dMinXndt)
	END
	
	SET @cCmd=N'SELECT TOP 1 @dlastDtChanged=memo_dt,@cLastXntype=ISNULL(b.xn_type,a.xn_type) FROM '+@cDbName+'pmtbuild_mindate_xndtchanges a
	LEFT JOIN wow_XPERT_XNTYPeS_alias b ON a.xn_type=b.xn_type_alias'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd,N'@dlastDtChanged DATETIME OUTPUT,@cLastXntype VARCHAR(50) OUTPUT',@dlastDtChanged output,
	@cLastXntype output

	IF ISNULL(@dlastDtChanged,'')<>'' AND (@dlastDtChanged<ISNULL(@dMinXndt,'') OR ISNULL(@dMinXndt,'')='')
		SELECT @dMinXndt=@dlastDtChanged,@cMinXnType=@cLastXntype
	
	IF @dMInXndt<'2021-04-01'
		SET @dMinXndt='2021-04-01'
END
