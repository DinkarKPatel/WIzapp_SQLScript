CREATE PROCEDURE SP3S_CLOSE_FINYEAR--(LocId 3 digit change by Sanjay:04-11-2024)
@cFinYear VARCHAR(5),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cInvBkpTempTable VARCHAR(100),@cActBkpTempTable VARCHAR(100),
	@cInvBkpTable VARCHAR(100),@cActBkpTable VARCHAR(100),@dFromDt DATETIME,@dToDt DATETIME,@cStep VARCHAR(4),
	@tPendingApp VARCHAR(200),@tPendingJw VARCHAR(200),@tPendingGit VARCHAR(200),@cDtSuffix VARCHAR(10),
	@tPendingWPS VARCHAR(200),@tPendingRPS VARCHAR(200),@tPendingDnPS VARCHAR(200),@tPendingCnPS VARCHAR(200),
	@tPendingAppBkp VARCHAR(200),@tPendingJwBkp VARCHAR(200),@tPendingGitBkp VARCHAR(200),
	@tPendingWPSBkp VARCHAR(200),@tPendingRPSBkp VARCHAR(200),@tPendingDnPSBkp VARCHAR(200),
	@tPendingCnPSBkp VARCHAR(200),@cPmtDbName VARCHAR(200)

BEGIN TRY
	SET @cStep='5'
	SET @cErrormsg=''

	SELECT @dToDt = dbo.FN_GETFINYEARDATE(@cFinYear,2),
		   @dFromDt = dbo.FN_GETFINYEARDATE(@cFinYear,1)

	SELECT @cInvBkpTable='inventory_xns_bkp_'+@cFinYear,
		   @cActBkpTable='accounts_xns_bkp_'+@cFinYear,
		   @cInvBkpTempTable='temp_inventory_xns_bkp_'+@cFinYear,
		   @cActBkpTempTable='temp_accounts_xns_bkp_'+@cFinYear

	SET @cStep='7'
	IF OBJECT_ID(@cInvBkpTempTable,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@cInvBkpTempTable
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	CREATE TABLE #tmpOps_Inv (product_code VARCHAR(50),dept_id VARCHAR(4),bin_id VARCHAR(10),ops_qty NUMERIC(10,2),ops_pp NUMERIC(10,2),ops_mrp NUMERIC(10,2))

	CREATE TABLE #tmpOps_Act (ac_code CHAR(10),cost_center_dept_id VARCHAR(4),opening_balance NUMERIC(14,2))

	SET @cStep='10'
	SET @cCmd=N'SELECT a.product_code,dept_id,bin_id,
	SUM(CASE WHEN xn_type IN  (''APP'',''CHO'',''CIP'',''CNC'',''DCO'',''DNPI'',''GRNPSOUT'',''JWI'',''MIS'',''PRT'',''SCC'',''SLS'',''WPI'',''WSL'')
	THEN -xn_qty ELSE xn_qty END) AS ops_qty
	from VW_XNSREPS A 
	WHERE xn_dt<'''+CONVERT(VARCHAR,@dFromDt,110)+''' AND xn_type NOT IN(''TRI'',''TRO'')
	GROUP BY a.product_code,dept_id,bin_id
	HAVING SUM(CASE WHEN xn_type IN  (''APP'',''CHO'',''CIP'',''CNC'',''DCO'',''DNPI'',''GRNPSOUT'',''JWI'',''MIS'',''PRT'',''SCC'',''SLS'',''WPI'',''WSL'')
	THEN -xn_qty ELSE xn_qty END)<>0 '
	
	INSERT INTO #tmpOps_Inv (product_code,dept_id,bin_id,ops_qty)
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='15'
	SET @cCmd=N'select a.product_code,dept_id,bin_id,xn_type,xn_party_code,xn_no,xn_dt,xn_id,xn_qty,(xn_qty*sn.pp) as xnppval,
				(xn_qty*sn.mrp) as xnmrpval,xn_net INTO '+@cInvBkpTempTable+' FROM vw_xnsreps a
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
				WHERE  xn_dt between '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+CONVERT(VARCHAR,@dToDt,110)+'''
				AND xn_type NOT IN (''TRI'',''TRO'')
				union all
				select a.product_code,dept_id,bin_id,''OPS'' xn_type,''LM''+ac_code xn_party_code,'''' xn_no,'''++CONVERT(VARCHAR,@dFromDt,110)+''' xn_dt,
				''OPS'' xn_id,ops_qty xn_qty,(ops_qty*sn.pp) as xnppval,(ops_qty*sn.mrp) as xnmrpval,
				0 xn_net FROM #tmpOps_Inv a
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code'
				

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd


	SET @cStep='20'
	IF OBJECT_ID(@cActBkpTempTable,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@cActBkpTempTable
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END	

	DECLARE @CDONOTPICKOBHEADS VARCHAR(MAX)

	SELECT @CDONOTPICKOBHEADS=DBO.FN_ACT_TRAVTREE('0000000010')      
	SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS+DBO.FN_ACT_TRAVTREE( '0000000017' )      
    SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')    

	SET @cStep='25'
	insert #tmpOps_Act (ac_code,cost_center_dept_id,opening_balance)
	SELECT a.ac_code,cost_center_dept_id,SUM(debit_amount-credit_amount) opening_balance 
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	WHERE voucher_dt<@dFromDt AND cancelled=0 AND charindex(head_code,@CDONOTPICKOBHEADS)=0
	GROUP BY a.ac_code,cost_center_dept_id
	HAVING SUM(debit_amount-credit_amount)<>0

	SET @cStep='30'
	--Voucher no, voucher date, ac_code ,recon_dt, debit Amount credit amount , ref no
	SET @cCmd=N'select a.vm_id,cost_center_dept_id,Voucher_no, voucher_dt, ac_code ,recon_dt,debit_Amount,credit_amount,ref_no
				INTO '+@cActBkpTempTable+' FROM vd01106 a (NOLOCK)
				JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
				WHERE voucher_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+''' and '''+CONVERT(VARCHAR,@dToDt,110)+''' AND cancelled=0
				
				UNION ALL
				select ''OPS'' vm_id,cost_center_dept_id,'''' Voucher_no, '''+CONVERT(VARCHAR,@dFromDt,110)+''' voucher_dt, 
				ac_code ,'''' recon_dt,(CASE WHEN opening_balance>0 THEN opening_balance ELSE 0 END) debit_Amount,
				(CASE WHEN opening_balance<0 THEN ABS(opening_balance) ELSE 0 END) credit_amount,'''' ref_no
				FROM #tmpOps_Act'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='35'
	EXEC SP3s_build_CBSSTK_PENDINGDOCS
	@DFROMDT=@dToDt,
	@DTODT=@dToDt,
	@cErrormsg=@cErrormsg OUTPUT

	IF @cErrormsg<>''
		GOTO END_PROC

	SET @cStep='37'
	SET @cDtSuffix=CONVERT(VARCHAR,@dToDt,112)
	SET @cPmtDbName=DB_NAME()+'_PMT.DBO.'

	SELECT @tPendingApp=@cPmtDbName+'PENDING_APPROVALS_'+@cDtSuffix,
		@tPendingJw=@cPmtDbName+'PENDING_JOBWORK_TRADING_'+@cDtSuffix,
		@tPendingRPS=@cPmtDbName+'PENDING_RPS_'+@cDtSuffix,
		@tPendingWPS=@cPmtDbName+'PENDING_WPS_'+@cDtSuffix,
		@tPendingDnPS=@cPmtDbName+'PENDING_DNPS_'+@cDtSuffix,
		@tPendingCnPS=@cPmtDbName+'PENDING_CNPS_'+@cDtSuffix

	SELECT @tPendingAppBkp='PENDING_APPROVALS_BKP_'+@cDtSuffix,
		@tPendingJwBkp='PENDING_JOBWORK_TRADING_BKP_'+@cDtSuffix,
		@tPendingRPSBkp='PENDING_RPS_BKP_'+@cDtSuffix,
		@tPendingWPSBkp='PENDING_WPS_BKP_'+@cDtSuffix,
		@tPendingDnPSBkp='PENDING_DNPS_BKP_'+@cDtSuffix,
		@tPendingCnPSBkp='PENDING_CNPS_BKP_'+@cDtSuffix
	
	SET @cStep='40'
	IF OBJECT_ID(@tPendingAppBkp,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@tPendingAppBkp
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCmd=N'SELECT * INTO '+@tPendingAppBkp+' FROM '+@tPendingApp
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF OBJECT_ID(@tPendingJwBkp,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@tPendingJwBkp
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='45'
	SET @cCmd=N'SELECT * INTO '+@tPendingJwBkp+' FROM '+@tPendingJw
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF OBJECT_ID(@tPendingRPSBkp,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@tPendingRPSBkp
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='50'
	SET @cCmd=N'SELECT * INTO '+@tPendingRPSBkp+' FROM '+@tPendingRPS
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF OBJECT_ID(@tPendingWPSBkp,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@tPendingWPSBkp
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='55'
	SET @cCmd=N'SELECT * INTO '+@tPendingWPSBkp+' FROM '+@tPendingWPS
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	IF OBJECT_ID(@tPendingDnPSBkp,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@tPendingDnPSBkp
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='60'
	SET @cCmd=N'SELECT * INTO '+@tPendingDnPSBkp+' FROM '+@tPendingDnPS
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF OBJECT_ID(@tPendingCnPSBkp,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@tPendingCnPSBkp
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='65'
	SET @cCmd=N'SELECT * INTO '+@tPendingCnPSBkp+' FROM '+@tPendingCnPS
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF OBJECT_ID(@cInvBkpTable,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@cInvBkpTable
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='70'
	IF OBJECT_ID(@cInvBkpTable,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@cInvBkpTable
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END
		
	IF OBJECT_ID(@cInvBkpTable,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@cInvBkpTable
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='75'
	IF OBJECT_ID(@cActBkpTable,'u') IS NOT NULL
	BEGIN
		SET @cCmd='DROP TABLE '+@cActBkpTable
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END	


	SET @cStep='80'
	SET @cCmd=N'EXEC SP_RENAME '''+@cActBkpTempTable+''','''+@cActBkpTable+''''
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='85'
	SET @cCmd=N'EXEC SP_RENAME '''+@cInvBkpTempTable+''','''+@cInvBkpTable+''''
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='90'
	
	IF NOT EXISTS (SELECT TOP 1 FixedDate FROM FIXEDFREEZE (NOLOCK) WHERE xn_type='all_xns')
		INSERT FIXEDFREEZE	( FixedDate, IsEnabled, User_Code, XN_TYPE ) 
		SELECT @dToDt as FixedDate,1 IsEnabled,'0000000' User_Code,'ALL_XNS' XN_TYPE
	ELSE
		UPDATE FIXEDFREEZE WITH (ROWLOCK) SET FixedDate=@dToDt WHERE xn_type='ALL_XNS'
		
	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_CLOSE_FINYEAR at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
