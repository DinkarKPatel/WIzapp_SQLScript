CREATE PROCEDURE SPACT_GETLOCWISE_GITVALUE
@dToDt DATETIME,
@bCalledForProfitCalculation BIT=0,
@bRetMemosonly BIT=0
AS
BEGIN
	declare @CsTEP varchar(5),@dCutOffdate DATETIME,@cCutOffDate VARCHAR(20)


	SET @dCutOffdate=''

	IF @bCalledForProfitCalculation=1
	BEGIN
		SELECT TOP 1 @cCutOffDate=value FROM config (NOLOCK) WHERE config_option='Pick_git_accounts_cutoffdate'
		IF ISNULL(@cCutoffDate,'')<>''
			SET @dCutOffdate=@cCutOffDate
	END


	INSERT #tmpPendingDocsMemos (memo_id,dept_id)
	SELECT 'WSL'+a.inv_id memo_id,a.party_dept_id
	FROM inm01106 a (NOLOCK) 
	JOIN #locList c ON c.dept_id=a.party_dept_id
	LEFT OUTER JOIN pim01106 b (NOLOCK) ON a.inv_id=b.inv_id  AND b.cancelled=0 AND b.receipt_dt<=@dToDt AND b.receipt_dt<>''
	WHERE a.cancelled=0 AND a.inv_dt BETWEEN @dCutOffdate AND @dToDt  AND a.inv_mode=2 AND (b.mrr_id IS NULL OR b.receipt_dt>@dToDt)

	
	SET @cStep='20'
	INSERT #tmpPendingDocsMemos (memo_id,dept_id)
	SELECT 'PRT'+a.rm_id,a.party_dept_id FROM rmm01106 a (NOLOCK) 
	JOIN #locList c ON c.dept_id=a.party_dept_id
	LEFT OUTER JOIN cnm01106 b (NOLOCK) ON a.rm_id=b.rm_id AND b.cancelled=0 AND b.receipt_dt<=@dToDt  AND b.receipt_dt<>''
	WHERE a.cancelled=0 AND a.rm_dt BETWEEN @dCutOffdate AND @dToDt  AND a.mode=2 AND (b.rm_id IS NULL OR b.receipt_dt>@dToDt)


	declare @cFinYear VARCHAR(10),@dFinyearToDt datetime

	SET @cFinyear='01'+dbo.fn_getfinyear(@dToDt)

	SELECT @dFinyearToDt = DBO.FN_GETFINYEARDATE(@cFinyear,2)

	SET @cStep='80'
	SELECT mrr_id INTO #tmpPurGit FROM pim01106 a (NOLOCK)
	JOIN #locList b ON a.dept_id=b.dept_id
	WHERE a.inv_dt BETWEEN @dCutOffdate AND @dToDt AND a.fin_year=@CFINYEAR AND receipt_dt>@dFinYearToDt
	AND a.cancelled=0 AND a.inv_mode=1 
	
	
	IF @bRetMemosonly=0
		SELECT a.party_dept_id dept_id,convert(numeric(10,2),0) quantity,CONVERT(NUMERIC(20,2),0) ppvalue,inv_no memo_no,inv_dt memo_dt,convert(varchar(10),'') xn_type into #tmpPendingDocsMemoValues
		FROM inm01106 a (NOLOCK)  where 1=2

	INSERT INTO #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,quantity, ppvalue)
	SELECT 'PURGIT' xn_type,m.mrr_no,m.inv_dt,M.location_Code   dept_id,sum(quantity) quantity,sum(quantity*pp) ppvalue 
	FROM pid01106 a (NOLOCK)
	JOIN #tmpPurGit b ON a.mrr_id=b.mrr_id
	JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
	JOIN pim01106 m(NOLOCK) ON m.mrr_id=a.mrr_id
	WHERE sku_item_type=1 AND isnull(sku_er_flag,0) IN  (0,1)
	GROUP BY m.location_Code  ,m.mrr_no,m.inv_dt

	--select 'check git challans', * from #tmpPendingDocsMemos where left(memo_id,3)='WSL'		

	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'GIT', 'WSL'+inv_no,inv_dt,b.dept_id,sum(quantity*pp) ppvalue,sum(quantity) quantity FROM ind01106 a (NOLOCK) 
	JOIN #tmpPendingDocsMemos b ON b.memo_id='WSL'+a.inv_ID
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	Join inm01106 c (NOLOCK) ON c.inv_id=a.inv_id
	WHERE  left(memo_id,3)='WSL'
	AND sku_item_type=1 AND isnull(sku_er_flag,0) IN  (0,1)
	GROUP BY inv_no,inv_dt,b.dept_id

	INSERT #tmpPendingDocsMemoValues (xn_type,memo_no,memo_dt,dept_id,ppvalue,quantity)
	SELECT 'GIT','PRT'+rm_no,rm_dt,b.dept_id,sum(quantity*pp) ppvalue,sum(quantity) quantity FROM rmd01106 a (NOLOCK) 
	JOIN #tmpPendingDocsMemos b ON b.memo_id='PRT'+a.rm_ID
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.PRODUCT_CODE
	Join rmm01106 c (NOLOCK) ON c.rm_id=a.rm_id
	WHERE  left(memo_id,3)='PRT'
	AND sku_item_type=1 AND isnull(sku_er_flag,0) IN  (0,1)
	GROUP BY rm_no,rm_dt,b.dept_id

	IF @bRetMemosonly=1
		RETURN

	INSERT INTO #tmpPendingDocsValues (xn_type,dept_id,ppvalue)
	SELECT xn_type,dept_id,sum(ppvalue) FROM #tmpPendingDocsMemoValues 
	GROUP BY xn_type,dept_id
	
END