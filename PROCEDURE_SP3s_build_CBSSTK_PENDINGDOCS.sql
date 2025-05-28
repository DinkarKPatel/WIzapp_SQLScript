CREATE PROCEDURE SP3s_build_CBSSTK_PENDINGDOCS--(LocId 3 digit change by Sanjay:06-11-2024)
@DFROMDT DATETIME,
@DTODT DATETIME,
@bCallledFromPlBs BIT=0,
@dLogDt DATETIME='',
@cXnType VARCHAR(10)='',
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
SET NOCOUNT ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @DMINXNDT DATETIME,@DMAXXNDT DATETIME,@DLASTXNDT DATETIME,@NCBSSTKVAL NUMERIC(10,2),@cHOLocId VARCHAR(4),
			@CCMD NVARCHAR(MAX),@CFINYEAR VARCHAR(10),@CRFDBNAME VARCHAR(500),@cLastPmtTable varchar(200),
			@cDtSuffix VARCHAR(10),@tSauAdjCbs varchar(200),@cPmtDbName varchar(200),@cLASTXNDT VARCHAR(20),
			@tWip VARCHAR(200),@tPendingApp VARCHAR(200),@tPendingJw VARCHAR(200),@tPendingGit VARCHAR(200),
			@tPendingWPS VARCHAR(200),@tPendingRPS VARCHAR(200),@tPendingDnPS VARCHAR(200),@tPendingCnPS VARCHAR(200),
			@tPendingWPSPrev VARCHAR(200),@tWipPrev VARCHAR(200),@tPendingRpsPrev VARCHAR(200),@tPendingDnpsPrev VARCHAR(200),
			@tPendingCnpsPrev varchar(200),@tPendingAppPrev VARCHAR(200),@tPendingJwPrev VARCHAR(200),@tPendingGitPrev VARCHAR(200),
			@cCmd1 NVARCHAR(MAX),@cCmd2 NVARCHAR(MAX),@NSPID VARCHAR(40),@dStarttime DATETIME,@bPickPrevGitLocs BIT
			
BEGIN TRY		
	DECLARE @cCurLocId VARCHAR(4),@cTableName VARCHAR(300),@cStep VARCHAR(10)
	
	SET @NSPID=CONVERT(VARCHAR(40),NEWID())
		
	SET @cStep='10'
	EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
			
	print 'step-2:SP3s_build_CBSSTK_PENDINGDOCS'
	SET @cErrormsg=''

	DECLARE @BPICKFREIGHT BIT,@BPICKOC BIT,@BPICKRO BIT,@CPICKFREIGHT VARCHAR(4),@CPICKOC VARCHAR(4),@CPICKRO VARCHAR(4),
	@NSTOCKADJVALUE NUMERIC(10,2)
	
	SELECT TOP 1 @cCurLocId=LTRIM(RTRIM(VALUE)) FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='LOCATION_ID'
	SELECT TOP 1 @cHOLocId=LTRIM(RTRIM(VALUE)) FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='HO_LOCATION_ID'
	
	--IF object_id('master.dbo.cloud_dbinfo','u') is not null -- This process should run for Non cloud clients only as per discussion Sir after Cantabil complaining 
	--														-- for not able to take Report thru Xtreme (Date:26-12-2023)
	--	GOTO END_PROC

	SET @cStep='20'
	EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1


print 'step-3:SP3s_build_CBSSTK_PENDINGDOCS'
	SET @cStep='30'
	SET @cPmtDbName=DB_NAME()+'_PMT.DBO.'

	IF @bCallledFromPlBs=0
	BEGIN
		CREATE TABLE #LocList (dept_id VARCHAR(4))

		INSERT INTO #LocList 
		SELECT dept_id FROM location ---WHERE (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1) 
	END

	print 'step-4:SP3s_build_CBSSTK_PENDINGDOCS'
	SET @cStep='35'
	EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		
	CREATE TABLE #tmpGitProcess (memo_id VARCHAR(50),quantity NUMERIC(10,2),memo_dt datetime,tat_days numeric(5,0))

	--THIS TABLE WOULD GET THE WIP STOCK 
	
	declare @cPmtTablename varchar(100),@dxndt datetime,@cDtFilter VARCHAR(100),@bFirstEntry BIT

	SET @bFirstEntry=1
	SET @cXnType='GIT' --- It will build only GIT tables as per instruction by Sir for Cantabil client to have GIT report thru Xtreme (Date:26-12-2023)

	SELECT @cCmd1='',@cCmd2='',@tWipPrev=''

	SET @cStep='35'
	EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

	if @dLogDt=''
		set @dLogDt=getdate()

	INSERT logdocs_build	( build_upto, ENDTIME, FROMDT, LOG_DT, STARTTIME, TODT )  
	SELECT 	''  build_upto, '' ENDTIME,@DFROMDT FROMDT,@dLogDt LOG_DT,getdate() STARTTIME,@DTODT TODT 

	SET @cCmd1='SELECT a.memo_id,a.xn_no,a.xn_dt,a.xn_party_code,a.DEPT_ID,a.BIN_ID,a.product_code,(a.quantity-isnull(x.adj_qty,0)) quantity FROM 
				(SELECT memo_id,xn_no,xn_dt,xn_party_code,a.DEPT_ID,a.BIN_ID,a.product_code,SUM(quantity) quantity from (' 
	SET @DLASTXNDT=@DFROMDT

	SET @bPickPrevGitLocs=0
	WHILE @DLASTXNDT<=@DToDt
	BEGIN
		
		SET @cStep='50'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		set @dxndt=@DLASTXNDT
		
		SELECT @cDtSuffix=convert(varchar,@DLASTXNDT,112),@cDtFilter=''

		SELECT @tWip=@cPmtDbName+'WIPSTOCK_'+@cDtSuffix,
		@tPendingApp=@cPmtDbName+'PENDING_APPROVALS_'+@cDtSuffix,
		@tPendingJw=@cPmtDbName+'PENDING_JOBWORK_TRADING_'+@cDtSuffix,
		@tPendingRPS=@cPmtDbName+'PENDING_RPS_'+@cDtSuffix,
		@tPendingWPS=@cPmtDbName+'PENDING_WPS_'+@cDtSuffix,
		@tPendingDnPS=@cPmtDbName+'PENDING_DNPS_'+@cDtSuffix,
		@tPendingCnPS=@cPmtDbName+'PENDING_CNPS_'+@cDtSuffix
		

		SET @cStep='60'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		EXEC SP3S_CREATE_PENDINGDOCSTABLE_PMTLOCS @cPmtDbName,@cDtSuffix




		SET @cLASTXNDT=CONVERT(VARCHAR,@DLASTXNDT,112)

		IF @cXnType NOT IN ('','GIT')
			GOTO lblApp
		
		SET @cStep='70'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

		EXEC SP3S_GET_PENDING_GITLOCS 
		@dXnDt=@dLastXnDt,
		@bPickPrevGitLocs=@bPickPrevGitLocs,
		@nSpId=@nSpId
		
lblApp:
		SET @cDtFilter=(CASE WHEN @bFirstEntry=1 THEN '<=' ELSE '=' END)+''''+@cLASTXNDT+''''


		IF @bFirstEntry=0
		BEGIN
			SET @cCmd2=' UNION 
						 SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,BIN_ID,product_code,quantity from '+@tPendingAppPrev+') a
						 GROUP BY memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,BIN_ID,product_code
						 HAVING sum(quantity)<>0'
		END
		ELSE
			SET @cCmd2=') a '
			
		IF @cXnType NOT IN ('','APP')
			GOTO lblWps

		SET @cStep='82'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		--GETTING LIST OF PENDING APPROVALS
		IF @bFirstEntry=1
			SET @cCmd=N'INSERT '+@tPendingApp+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT a.memo_id,xn_no,xn_dt,xn_party_code,a.dept_id,a.bin_id,a.product_code,(a.quantity-isnull(x.adj_qty,0))
			FROM 
			(
			SELECT b.memo_id,memo_no xn_no,memo_dt xn_dt,(CASE WHEN ISNULL(b.ac_code,'''') IN ('''',''0000000000'')
			THEN ''CUS''+customer_code ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM APD01106 A (NOLOCK)  
			JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
			JOIN sku_names sn (NOLOCK) ON A.PRODUCT_CODE = Sn.PRODUCT_CODE  
			JOIN #LocList ll ON ll.dept_id=b.location_code
			WHERE B.MEMO_DT '+@cDtFilter+' AND sn.STOCK_NA=0 AND B.CANCELLED = 0  
			AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.memo_id,memo_no,memo_dt,(CASE WHEN ISNULL(b.ac_code,'''') IN ('''',''0000000000'')
			THEN ''CUS''+customer_code ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE
			) A
			LEFT OUTER JOIN  
			 (  
				  SELECT  c.memo_id,b.location_code dept_id,a.bin_id,
				  c.product_code,SUM(a.QUANTITY) AS Adj_QTY  
				  FROM APPROVAL_RETURN_DET A (NOLOCK)  
				  JOIN APPROVAL_RETURN_MST B (NOLOCK) ON A.MEMO_ID=B.MEMO_ID
				  JOIN apd01106 c (NOLOCK) ON c.row_id=a.apd_row_id
				  WHERE b.MEMO_DT'+@cDtFilter+'  AND b.CANCELLED=0
				  GROUP BY c.memo_id,b.location_code,a.bin_id,c.product_code
			 )X ON a.memo_id=x.memo_id AND A.product_code = X.product_code and a.bin_id=x.bin_id and a.dept_id =x.dept_id
			where (A.QUANTITY-isnull(x.adj_qty,0))>0'
		ELSE
			SET @cCmd=N'INSERT '+@tPendingApp+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)'+
			@cCmd1+'
			SELECT b.memo_id,memo_no xn_no,memo_dt xn_dt,(CASE WHEN ISNULL(b.ac_code,'''') IN ('''',''0000000000'')
			THEN ''CUS''+customer_code ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM APD01106 A (NOLOCK)  
			JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
			JOIN sku_names sn (NOLOCK) ON A.PRODUCT_CODE = Sn.PRODUCT_CODE  
			JOIN #LocList ll ON ll.dept_id=b.location_code
			WHERE B.MEMO_DT '+@cDtFilter+' AND sn.STOCK_NA=0 AND B.CANCELLED = 0  
			AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.memo_id,memo_no,memo_dt,(CASE WHEN ISNULL(b.ac_code,'''') IN ('''',''0000000000'')
			THEN ''CUS''+customer_code ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE'+@cCmd2+') a
			LEFT OUTER JOIN  
			 (  
				  SELECT c.memo_id,b.location_code dept_id,a.bin_id,c.product_code,SUM(a.QUANTITY) AS Adj_QTY  
				  FROM APPROVAL_RETURN_DET A (NOLOCK)  
				  JOIN APPROVAL_RETURN_MST B (NOLOCK) ON A.MEMO_ID=B.MEMO_ID
				  JOIN apd01106 c (NOLOCK) ON c.row_id=a.apd_row_id
				  JOIN #LocList ll ON ll.dept_id=b.location_code
				  WHERE MEMO_DT'+@cDtFilter+'  AND CANCELLED=0
				  GROUP BY c.memo_id,b.location_code,a.bin_id,c.product_code
			 )X ON a.memo_id=x.memo_id AND A.product_code = X.product_code and a.bin_id=x.bin_id and a.dept_id =x.dept_id
		   WHERE (A.QUANTITY - ISNULL(X.adj_QTY,0))>0 '

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

lblWps:

		IF @cXnType NOT IN ('','WPS')
			GOTO lblRps

		SET @cStep='85'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

		IF @bFirstEntry=1
			SET @cCmd=N'INSERT '+@tPendingWps+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT b.ps_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM WPS_DET A (NOLOCK)   
			JOIN  WPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN inm01106 c (NOLOCK) ON c.inv_id=b.wsl_inv_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.ps_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.wsl_inv_id,'''')='''' OR c.inv_dt>'''+@cLastXnDt+''') 
			and sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE'
		ELSE		
			SET @cCmd=N'INSERT '+@tPendingWps+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,SUM(quantity) QUANTITY FROM
			(
			SELECT b.ps_id memo_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM WPS_DET A (NOLOCK)   
			JOIN  WPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN inm01106 c (NOLOCK) ON c.inv_id=b.wsl_inv_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.ps_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.wsl_inv_id,'''')='''' OR c.inv_dt>'''+@cLastXnDt+''') 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT b.ps_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,-SUM(A.QUANTITY) quantity  
			FROM WPS_DET A (NOLOCK)   
			JOIN  WPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			JOIN inm01106 c (NOLOCK) ON c.inv_id=b.wsl_inv_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE c.inv_dt '+@cDtFilter+' AND b.ps_dt<'''+convert(varchar,@DLASTXNDT,110)+''' AND B.CANCELLED = 0 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity  FROM '+@tPendingWpsPrev+') a
			GROUP BY memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code having sum(quantity)<>0'
	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd


lblRps:

		IF @cXnType NOT IN ('','RPS')
			GOTO lblDnps

		SET @cStep='90'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		IF @bFirstEntry=1
			SET @cCmd=N'INSERT '+@tPendingRps+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT b.cm_id memo_id,b.cm_no xn_no,b.cm_dt xn_dt,''CUS''+b.customer_code xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM RPS_DET A (NOLOCK)   
			JOIN  RPS_MST B (NOLOCK) ON a.cm_id=b.cm_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN cmm01106 c (NOLOCK) ON c.cm_id=b.ref_cm_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.cm_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.ref_cm_id,'''')='''' OR c.cm_dt>'''+@cLastXnDt+''') 
			and sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.cm_id,b.cm_no,b.cm_dt,b.customer_code,b.location_code,a.bin_id,a.PRODUCT_CODE'
		ELSE		
			SET @cCmd=N'INSERT '+@tPendingRps+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,SUM(quantity) QUANTITY FROM
			(
			SELECT b.cm_id memo_id,b.cm_no xn_no,b.cm_dt xn_dt,''CUS''+b.customer_code xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM RPS_DET A (NOLOCK)   
			JOIN  RPS_MST B (NOLOCK) ON a.cm_id=b.cm_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN cmm01106 c (NOLOCK) ON c.cm_id=b.ref_cm_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.cm_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.ref_cm_id,'''')='''' OR c.cm_dt>'''+@cLastXnDt+''') 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.cm_id,b.cm_no,b.cm_dt,b.customer_code,b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT b.cm_id memo_id,b.cm_no xn_no,b.cm_dt xn_dt,''CUS''+b.customer_code xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,-SUM(A.QUANTITY) quantity  
			FROM RPS_DET A (NOLOCK)   
			JOIN  RPS_MST B (NOLOCK) ON a.cm_id=b.cm_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			JOIN cmm01106 c (NOLOCK) ON c.cm_id=b.ref_cm_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE c.cm_dt '+@cDtFilter+' AND b.cm_dt<'''+convert(varchar,@DLASTXNDT,110)+''' AND B.CANCELLED = 0 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.cm_id,b.cm_no,b.cm_dt,b.customer_code,b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity  FROM '+@tPendingRpsPrev+') a
			GROUP BY memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code having sum(quantity)<>0'
	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd


lblDnpS:

		IF @cXnType NOT IN ('','DNPS')
			GOTO lblCnps

		SET @cStep='100'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		IF @bFirstEntry=1
			SET @cCmd=N'INSERT '+@tPendingDnps+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT b.ps_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM DNPS_DET A (NOLOCK)   
			JOIN  DNPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN rmm01106 c (NOLOCK) ON c.rm_id=b.prt_rm_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.ps_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.prt_rm_id,'''')='''' OR c.rm_dt>'''+@cLastXnDt+''') 
			and sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE'
		ELSE		
			SET @cCmd=N'INSERT '+@tPendingDnps+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,SUM(quantity) QUANTITY FROM
			(
			SELECT b.ps_id memo_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM DNPS_DET A (NOLOCK)   
			JOIN  DNPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN rmm01106 c (NOLOCK) ON c.rm_id=b.prt_rm_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.ps_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.prt_rm_id,'''')='''' OR c.rm_dt>'''+@cLastXnDt+''') 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT b.ps_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,-SUM(A.QUANTITY) quantity  
			FROM DNPS_DET A (NOLOCK)   
			JOIN  DNPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			JOIN rmm01106 c (NOLOCK) ON c.rm_id=b.prt_rm_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE c.rm_dt '+@cDtFilter+' AND b.ps_dt<'''+convert(varchar,@DLASTXNDT,110)+''' AND B.CANCELLED = 0 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity  FROM '+@tPendingDnpsPrev+') a
			GROUP BY memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code having sum(quantity)<>0'
	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

lblCnpS:

		IF @cXnType NOT IN ('','CNPS')
			GOTO lblJW

		SET @cStep='110'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		IF @bFirstEntry=1
			SET @cCmd=N'INSERT '+@tPendingCNPS+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT b.ps_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM CNPS_DET A (NOLOCK)   
			JOIN  CNPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN cnm01106 c (NOLOCK) ON c.cn_id=b.wsr_cn_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.ps_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.wsr_cn_id,'''')='''' OR c.cn_dt>'''+@cLastXnDt+''') 
			and sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE'
		ELSE		
			SET @cCmd=N'INSERT '+@tPendingCNPS+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,SUM(quantity) QUANTITY FROM
			(
			SELECT b.ps_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  
			FROM CNPS_DET A (NOLOCK)   
			JOIN  CNPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			LEFT OUTER JOIN cnm01106 c (NOLOCK) ON c.cn_id=b.wsr_cn_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE B.ps_dt '+@cDtFilter+' AND B.CANCELLED = 0 AND (isnull(b.wsr_cn_id,'''')='''' OR c.cn_dt>'''+@cLastXnDt+''') 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT b.ps_id,ps_no xn_no,ps_dt xn_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END) xn_party_code,b.location_code AS DEPT_ID,a.bin_id,a.product_code,-SUM(A.QUANTITY) quantity  
			FROM CNPS_DET A (NOLOCK)   
			JOIN  CNPS_MST B (NOLOCK) ON a.ps_id=b.ps_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			JOIN cnm01106 c (NOLOCK) ON c.cn_id=b.wsr_cn_id
			JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
			WHERE c.cn_dt '+@cDtFilter+' AND b.ps_dt<'''+convert(varchar,@DLASTXNDT,110)+''' AND B.CANCELLED = 0 
			AND sn.STOCK_NA=0 AND ISNULL(Sn.sku_item_type,0) IN(0,1)
			GROUP BY b.ps_id,ps_no,ps_dt,(CASE WHEN ps_mode=2 THEN ''LOC''+b.party_dept_id
			ELSE ''LM''+b.ac_code END),b.location_code,a.bin_id,a.PRODUCT_CODE
			
			UNION ALL
			SELECT memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity  FROM '+@tPendingCnpsPrev+') a
			GROUP BY memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code having sum(quantity)<>0'
	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

lblJW:

		IF @cXnType NOT IN ('','JW')
			GOTO lblWIP

		SET @cStep='120'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		--GETTING LIST OF PENDING JOBWORK FOR TRADING 
		IF @bFirstEntry=1
			SET @cCmd=N'INSERT '+@tPendingJW+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)
			SELECT b.ISSUE_ID,ISSUE_no xn_no,ISSUE_dt xn_dt,''PR''+a.agency_code xn_party_code,a.location_code AS DEPT_ID,b.bin_id,b.product_code,SUM(B.QUANTITY - ISNULL(X.adj_QTY,0)) quantity   
			FROM JOBWORK_ISSUE_MST A (NOLOCK)
			JOIN JOBWORK_ISSUE_DET B (NOLOCK) ON A.ISSUE_ID=B.ISSUE_ID 
			LEFT JOIN 
			(
				SELECT c.issue_id, a.location_code AS DEPT_ID,b.bin_id,c.product_code ,SUM(B.QUANTITY) AS adj_qty
				FROM JOBWORK_RECEIPT_MST A (NOLOCK)
				JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID=B.RECEIPT_ID
				JOIN jobwork_issue_det c (NOLOCK) ON c.row_id=b.ref_row_id
				JOIN #LocList ll ON ll.dept_id=a.location_code
				WHERE A.CANCELLED=0 AND A.RECEIPT_DT'+@cDtFilter+' AND A.WIP=0 
				AND A.MODE=1
				GROUP BY c.issue_id,c,b.bin_id,c.product_code
			)X ON a.issue_id=x.issue_id AND b.product_code = X.product_code and a.bin_id=x.bin_id and a.location_code =x.dept_id
			JOIN #LocList ll ON ll.dept_id=b.location_code
			JOIN SKU_names sn (NOLOCK) ON sn.PRODUCT_CODE=b.PRODUCT_CODE
			WHERE  A.ISSUE_DT'+@cDtFilter+' AND A.CANCELLED=0 AND A.WIP=0 AND A.ISSUE_TYPE=1 AND isnull(sn.STOCK_NA,0)=0
			AND ISNULL(Sn.sku_ITEM_TYPE,0) IN(0,1) AND ISNULL(non_receivable,0)=0
			GROUP BY b.ISSUE_ID,ISSUE_no,ISSUE_dt,a.agency_code,a.location_code,b.bin_id,b.product_code
			HAVING SUM(B.QUANTITY - ISNULL(X.adj_QTY,0))>0 '
		ELSE
			SET @cCmd=N'INSERT '+@tPendingJW+' (memo_id,xn_no,xn_dt,xn_party_code,DEPT_ID,bin_id,product_code,quantity)'+@cCmd1+'
			SELECT b.ISSUE_ID memo_id,ISSUE_no xn_no,ISSUE_dt xn_dt,''PR''+a.agency_code xn_party_code,a.location_code AS DEPT_ID,b.bin_id,b.product_code,SUM(B.QUANTITY) quantity   
			FROM JOBWORK_ISSUE_MST A (NOLOCK)
			JOIN JOBWORK_ISSUE_DET B (NOLOCK) ON A.ISSUE_ID=B.ISSUE_ID 
			JOIN #LocList ll ON ll.dept_id=a.location_code
			JOIN prd_agency_mst pr (NOLOCK) ON pr.agency_code=a.agency_code
			JOIN SKU_names sn (NOLOCK) ON sn.PRODUCT_CODE=b.PRODUCT_CODE
			WHERE  A.ISSUE_DT'+@cDtFilter+' AND A.CANCELLED=0 AND A.WIP=0 AND A.ISSUE_TYPE=1 AND isnull(sn.STOCK_NA,0)=0
			AND ISNULL(Sn.sku_ITEM_TYPE,0) IN(0,1) AND ISNULL(non_receivable,0)=0
			GROUP BY b.ISSUE_ID,ISSUE_no,ISSUE_dt,a.agency_code,a.location_code,b.bin_id,b.product_code'+@cCmd2+'
			) a
			LEFT JOIN 
			(
				SELECT c.issue_id,a.location_code dept_id,c.product_code,b.bin_id,SUM(B.QUANTITY) AS adj_qty
				FROM JOBWORK_RECEIPT_MST A (NOLOCK)
				JOIN JOBWORK_RECEIPT_DET B (NOLOCK) ON A.RECEIPT_ID=B.RECEIPT_ID
				JOIN jobwork_issue_det c (NOLOCK) ON c.row_id=b.ref_row_id
				WHERE A.CANCELLED=0 AND A.RECEIPT_DT'+@cDtFilter+' AND A.WIP=0 
				AND A.MODE=1
				GROUP BY c.issue_id,a.location_code,c.product_code,b.bin_id
			)X ON x.issue_id=a.memo_id AND A.product_code = X.product_code and a.bin_id=x.bin_id and a.dept_id =x.dept_id
			WHERE (A.QUANTITY - ISNULL(X.adj_QTY,0))>0 '

		PRINT @cCmd
		EXEC SP_EXECUTESQL @CCMD 
		
lblWip:
		IF @cXnType NOT IN ('','WIP')
			GOTO lblNext



			---Put this commented as it is taking time in database wizapp3sle and uncomment it
			---When Dinkar optimizes this procedure (Date : 21-03-2023 Sanjay)
		--SET @cStep='130'
		--EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		----GET THE WIP STOCK
		--EXEC SP_STOCKREPORT_WIP
		--@CTODATE=@DLASTXNDT,
		--@bCalledfromBuildPendingDocs=1,
		--@tTable=@tWip,
		--@tPrevdttable=@tWipPrev,
		--@bFirstDt=@bFirstEntry



		
		SET @cStep='140'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

lblNext:
		SET @cStep='145'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		UPDATE logdocs_build WITH (ROWLOCK) SET build_upto=@DLASTXNDT WHERE log_dt=@dLogDt
		SET @DLASTXNDT=@DLASTXNDT+1
		SET @bFirstEntry=0

		SELECT @tWipPrev=@cPmtDbName+'WIPSTOCK_'+@cDtSuffix,
		@tPendingAppPrev=@cPmtDbName+'PENDING_APPROVALS_'+@cDtSuffix,
		@tPendingJwPrev=@cPmtDbName+'PENDING_JOBWORK_TRADING_'+@cDtSuffix,
		@tPendingWpsPrev=@cPmtDbName+'PENDING_WPS_'+@cDtSuffix,
		@tPendingDnpsPrev=@cPmtDbName+'PENDING_DNPS_'+@cDtSuffix,
		@tPendingRpsPrev=@cPmtDbName+'PENDING_RPS_'+@cDtSuffix

		SET @bPickPrevGitLocs=1
	 END

	 SET @cStep='150'
	 EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
	 UPDATE logdocs_build SET endtime=getdate() WHERE log_dt=@dLogDt

	 GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3s_build_CBSSTK_PENDINGDOCS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
--END OF PROCEDURE - SP3s_build_CBSSTK_PENDINGDOCS
