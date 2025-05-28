CREATE PROCEDURE SP3S_FETCH_PENDINGDOCS--(LocId 3 digit change by Sanjay:05-11-2024)
@dToDt DATETIME,
@bRetMemosonly BIT=0,
@nSPid varchar(100)='',
@cErrormsg varchar(max) output
AS
BEGIN
	
	SET @cErrormsg=''
	DECLARE @cStep VARCHAR(10)

BEGIN TRY
	

	IF @bRetMemosonly=1
	BEGIN
		CREATE TABLE #LocList (dept_id VARCHAR(4),pan_no varchar(50))

		IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
		BEGIN    
				INSERT #LocList  (dept_id,pan_no)  
				SELECT a.DEPT_ID,b.PAN_NO FROM ACT_FILTER_LOC a JOIN location b (NOLOCK) ON b.dept_id=a.dept_id
				WHERE SP_ID = @nSpId    
		END     
		ELSE    
				INSERT #LocList  (dept_id,pan_no)      
				SELECT DEPT_ID,pan_no FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)

	END

	SET @cStep='10'
	SELECT 'WSL'+a.inv_id memo_id,a.party_dept_id dept_id into #tmpPendingDocsMemos
	FROM inm01106 a (NOLOCK)  where 1=2

	SELECT a.party_dept_id dept_id,CONVERT(NUMERIC(10,2),0) quantity ,CONVERT(NUMERIC(20,2),0) ppvalue,inv_no memo_no,inv_dt memo_dt,convert(varchar(10),'') xn_type 
	into #tmpPendingDocsMemoValues
	FROM inm01106 a (NOLOCK)  where 1=2

	
	INSERT #tmpPendingDocsMemos (memo_id,dept_id)
	SELECT 'WPS'+a.ps_id,a.location_Code FROM wps_mst a (NOLOCK)
	JOIN #locList c ON c.dept_id=a.location_Code
	LEFT OUTER JOIN inm01106 b (NOLOCK) ON b.inv_id=a.wsl_inv_id
	WHERE a.ps_dt<=@dToDt AND a.CANCELLED = 0 AND (isnull(a.wsl_inv_id,'')='' OR b.inv_dt>@dToDt) 

	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'WPS', ps_no,ps_dt,b.dept_id,sum(quantity*pp) ppvalue,sum(quantity) quantity FROM wps_det a (NOLOCK) 
	JOIN #tmpPendingDocsMemos b ON b.memo_id='WPS'+a.PS_ID
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	Join wps_mst c (NOLOCK) ON c.ps_id=a.ps_id
	WHERE  left(memo_id,3)='WPS'
	GROUP BY ps_no,ps_dt,b.dept_id

	SET @cStep='30'
	INSERT #tmpPendingDocsMemos (memo_id,dept_id)
	SELECT 'RPS'+a.cm_id,a.location_Code FROM rps_mst a (NOLOCK)
	JOIN #locList c ON c.dept_id=a.location_Code
	LEFT OUTER JOIN cmm01106 b (NOLOCK) ON b.cm_id=a.ref_cm_id
	WHERE a.cm_dt<=@dToDt AND a.CANCELLED = 0 AND (isnull(a.ref_cm_id,'')='' OR b.cm_dt>@dToDt) 

	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'RPS',cm_no,cm_dt,b.dept_id,sum(quantity*pp) ppvalue,sum(quantity) quantity FROM rps_det a (NOLOCK) 
	JOIN #tmpPendingDocsMemos b ON b.memo_id='RPS'+a.cm_ID
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	Join rps_mst c (NOLOCK) ON c.cm_id=a.cm_id
	WHERE  left(memo_id,3)='RPS'
	GROUP BY cm_no,cm_dt,b.dept_id

	INSERT #tmpPendingDocsMemos (memo_id,dept_id)
	SELECT 'DNPS'+a.ps_id,a.location_Code FROM dnps_mst a (NOLOCK)
	JOIN #locList c ON c.dept_id=a.location_Code
	LEFT OUTER JOIN rmm01106 b (NOLOCK) ON b.rm_id=a.prt_rm_id
	WHERE a.ps_dt<=@dToDt AND a.CANCELLED = 0 AND (isnull(a.prt_rm_id,'')='' OR b.rm_dt>@dToDt) 

	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'dnps',ps_no,ps_dt,b.dept_id,sum(quantity*pp) ppvalue,sum(quantity) quantity FROM dnps_det a (NOLOCK) 
	JOIN #tmpPendingDocsMemos b ON b.memo_id='dnps'+a.ps_ID
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	Join dnps_mst c (NOLOCK) ON c.ps_id=a.ps_id
	WHERE  left(memo_id,4)='DNPS'
	GROUP BY ps_no,ps_dt,b.dept_id


	SET @cStep='40'
	INSERT #tmpPendingDocsMemos (memo_id,dept_id)
	SELECT 'CNPS'+a.ps_id,a.location_Code FROM cnps_mst a (NOLOCK)
	JOIN #locList c ON c.dept_id=a.location_Code
	LEFT OUTER JOIN cnm01106 b (NOLOCK) ON b.cn_id=a.wsr_cn_id
	WHERE a.ps_dt<=@dToDt AND a.CANCELLED = 0 AND (isnull(a.wsr_cn_id,'')='' OR b.cn_dt>@dToDt) 

	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'CNPS', ps_no,ps_dt,b.dept_id,sum(quantity*pp) ppvalue,sum(quantity) quantity FROM cnps_det a (NOLOCK) 
	JOIN #tmpPendingDocsMemos b ON b.memo_id='CNPS'+a.ps_ID
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	Join cnps_mst c (NOLOCK) ON c.ps_id=a.ps_id
	WHERE  left(memo_id,4)='CNPS'
	GROUP BY ps_no,ps_dt,b.dept_id

	
	DECLARE @dFinyearToDt DATETIME,@cFinYear VARCHAR(10)

	SET @cFinyear='01'+dbo.fn_getfinyear(@dToDt)

	SELECT @dFinyearToDt = DBO.FN_GETFINYEARDATE(@cFinyear,2)



	SET @cStep='90'
	DECLARE @cDtFilter VARCHAR(50)
	SET @cDtFilter='<='''+CONVERT(VARCHAR,@dToDt,112)+''''

	SELECT A.ISSUE_ID  MEMO_ID, CAST('' AS VARCHAR(100)) XN_NO,CAST('' AS DATETIME ) XN_DT,
		   CAST('' AS VARCHAR(100)) AS XN_PARTY_CODE,DEPT_ID,CAST('' AS VARCHAR(7)) AS BIN_ID,PRODUCT_CODE,QUANTITY 
		   INTO #TMP_JOBWORK_FOR_TRADING 
	FROM JOBWORK_ISSUE_DET A (NOLOCK)
	JOIN JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID =B.ISSUE_ID 
	WHERE 1=2
	

	SET @cStep='100'
	EXEC SP3S_PENDING_JOBWORK_FOR_TRADING @cDtFilter

	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'JWI',xn_no,xn_dt,dept_id,sum(quantity*pp) ppvalue,sum(quantity) quantity FROM #TMP_JOBWORK_FOR_TRADING a (NOLOCK) 
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	GROUP BY Xn_no,xn_dt,dept_id
	HAVING sum(quantity)>0

	SET @cStep='110'
	SELECT sm.location_Code as dept_id,wp.bin_id,'WIP' AS XN_TYPE,SCI.PRODUCT_CODE,wp.quantity_in_stock AS QUANTITY,
			wp.BASE_PRICE RATE,WP.WIP_UID
	INTO #CBSWIP	  
	FROM SNC_MST SM(NOLOCK)
	JOIN SNC_DET SD(NOLOCK) ON SM.MEMO_ID=SD.MEMO_ID
	JOIN snc_barcode_det sci (NOLOCK) ON SCI.REFROW_ID=SD.ROW_ID
	JOIN WIP_PMT WP(NOLOCK) ON SD.ROW_ID=WP.XN_ROW_ID
	WHERE 1=2

	SET @cStep='115'
	EXEC SP_STOCKREPORT_WIP_NEW
	@cToDate=@dToDt,
	@bFirstDt=1

	SET @cStep='120'
	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'WIP', dept_id,@dToDt xn_dt,dept_id,sum(quantity*rate) ppvalue,sum(quantity) quantity FROM #CBSWIP a (NOLOCK) 
	GROUP BY dept_id

	SET @cStep='125'
	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'APP',memo_no,memo_dt, location_code dept_id,SUM((penAPp.quantity-isnull(penAPp.adj_qty,0))*sn.pp) ppvalue,sum(penAPp.quantity-isnull(penAPp.adj_qty,0)) quantity
	FROM 
	(SELECT A.*,X.Adj_QTY FROM
	(
	SELECT b.MEMO_NO,b.MEMO_DT, b.memo_id,a.bin_id,a.product_code,SUM(A.QUANTITY) quantity  ,b.location_Code
	FROM APD01106 A (NOLOCK)  
	JOIN APM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID  
	JOIN sku_names sn (NOLOCK) ON A.PRODUCT_CODE = Sn.PRODUCT_CODE  
	JOIN #LocList ll ON ll.dept_id=b.location_Code
	WHERE B.MEMO_DT<=@dtoDt AND sn.STOCK_NA=0 AND B.CANCELLED = 0  
	AND ISNULL(Sn.sku_item_type,0) IN(0,1)
	GROUP BY  b.MEMO_NO,b.MEMO_DT,b.memo_id,a.bin_id,a.PRODUCT_CODE,b.location_Code
	) A
	LEFT OUTER JOIN  
		(  
			SELECT  c.memo_id,a.bin_id,c.product_code,SUM(a.QUANTITY) AS Adj_QTY  
			FROM APPROVAL_RETURN_DET A (NOLOCK)  
			JOIN APPROVAL_RETURN_MST B (NOLOCK) ON A.MEMO_ID=B.MEMO_ID
			JOIN apd01106 c (NOLOCK) ON c.row_id=a.apd_row_id
			WHERE b.MEMO_DT<=@dToDt AND b.CANCELLED=0
			GROUP BY c.memo_id,a.bin_id,c.product_code
		)X ON a.memo_id=x.memo_id AND A.product_code = X.product_code and a.bin_id=x.bin_id
		where (A.QUANTITY-isnull(x.adj_qty,0))>0
	
	) penAPp JOIN sku_names sn (NOLOCK) ON sn.product_Code=penApp.product_code
	GROUP BY memo_no,memo_dt, location_code 

	
	SET @cStep='130'
	EXEC spact_Getlocwise_gitValue 
	@DtOdT=@DtOdT,
	@bRetMemosonly=1


	IF @bRetMemosonly=1
	BEGIN
		SELECT * FROM #tmpPendingDocsMemoValues
		GOTO END_PROC
	END

	SET @cStep='135'
	INSERT INTO #tmpPendingDocsValues (xn_type,dept_id,ppvalue)
	SELECT  xn_type,dept_id,SUM(ppvalue) FROM #tmpPendingDocsMemoValues
	GROUP BY xn_type,dept_id

	--if @@spid=108
	--	select 'check docs values',* from #tmpPendingDocsValues

	GOTO END_PROC

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_FETCH_PENDINGDOCS at Step#'+@cStep+ ' '+ERROR_MESSAGE()
	print 'Enter catch of fetch pending docs'+@cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:

END