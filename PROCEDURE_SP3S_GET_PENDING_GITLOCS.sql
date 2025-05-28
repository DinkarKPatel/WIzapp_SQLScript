CREATE PROCEDURE SP3S_GET_PENDING_GITLOCS
@dXnDt DATETIME='',
@bCalledFromDb BIT=0,
@bCalledFromARO BIT=0,
@bBuildCurDate BIT=0,
@bPickPrevGitLocs BIT=0,
@nSpId VARCHAR(40)=''
AS
BEGIN
		DECLARE @cCmd nvarchar(max),@cTableName VARCHAR(200),@dFromDt DATETIME,@cPrevTableName VARCHAR(200),@cStep VARCHAR(10)

		SET @cStep='70.2'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1
		
		IF @bCalledFromARO=0
			SET @cTableName=DB_NAME()+'_PMT.DBO.GITLOCS_'+CONVERT(VARCHAR,@dXnDt,112)
		ELSE
			SET @cTableName='#tmpGitDetails'

		SET @cCmd=N'Truncate Table '+@cTableName+' '  
		EXEC SP_EXECUTESQL @cCmd  

		SET @dFromDt=(CASE WHEN @bBuildCurDate=0 THEN '1900-01-01' ELSE CONVERT(DATE,GETDATE()) END)
		SET @dXnDt=(CASE WHEN @bBuildCurDate=0 THEN @dXnDt ELSE @dFromDt END)

		INSERT #tmpGitProcess (memo_id,quantity,memo_dt,tat_days)
		SELECT 'WSL'+a.inv_id,a.TOTAL_QUANTITY,a.inv_dt,ISNULL(c.lead_days,7) as tat_days  FROM inm01106 a (NOLOCK) 
		LEFT OUTER JOIN pim01106 b (NOLOCK) ON a.inv_id=b.inv_id  AND b.cancelled=0 AND b.receipt_dt<=@dXnDt AND b.receipt_dt<>''
		JOIN location c (NOLOCK) ON c.dept_id=a.party_dept_id
		WHERE a.cancelled=0 AND a.inv_dt BETWEEN @dFromDt AND @dXnDt  AND a.inv_mode=2 AND b.mrr_id IS NULL

		SET @cStep='70.4'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

		INSERT #tmpGitProcess (memo_id,quantity,memo_dt,tat_days)
		SELECT 'PRT'+a.rm_id,a.TOTAL_QUANTITY,rm_dt,ISNULL(c.lead_days,7) as tat_days FROM rmm01106 a (NOLOCK) 
		LEFT OUTER JOIN cnm01106 b (NOLOCK) ON a.rm_id=b.rm_id AND b.cancelled=0 AND b.receipt_dt<=@dXnDt  AND b.receipt_dt<>''
		JOIN location c (NOLOCK) ON c.dept_id=a.party_dept_id
		WHERE a.cancelled=0 AND a.rm_dt BETWEEN @dFromDt AND @dXnDt  AND a.mode=2 AND b.rm_id IS NULL
		

		IF @bBuildCurDate=1
		BEGIN
			SET @cStep='70.6'
			EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

			SET @cCmd=N'DELETE a FROM '+@cTableName+' a JOIN #tmpGitProcess b ON a.memo_id=b.memo_id'
			EXEC SP_EXECUTESQL @cCmd
   		END

		IF @bCalledFromDb=1 
			RETURN
		
		SET @cStep='70.8'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

		SET @cCmd=N'INSERT '+@cTableName+' (memo_id,product_code,dept_id,bin_id,git_qty,xn_party_code,xn_no,xn_dt)
		SELECT ''WSL''+c.inv_id,a.product_code,party_dept_id,target_bin_id,SUM(a.quantity) AS GIT_QTY,
		''LOC''+c.location_code as xn_party_code,c.inv_no as xn_no,c.inv_dt as xn_dt
		from IND01106 A (NOLOCK) 
		JOIN Inm01106 c (NOLOCK) ON c.inv_id=a.inv_id
		JOIN #tmpGitProcess b ON A.INV_ID=SUBSTRING(b.memo_id,4,len(memo_id))
		 where '+(CASE WHEN @bPickPrevGitLocs=1 THEN ' inv_dt='''+CONVERT(VARCHAR,@dXnDt,110)+''' AND ' ELSE '' END)+' left(memo_id,3)=''WSL''
		GROUP BY c.inv_id,LEFT(c.inv_ID,2),a.product_code,party_dept_id,target_bin_id,c.inv_no,c.inv_dt'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		
		SET @cStep='70.10'
		EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

		SET @cCmd=N'INSERT  '+@cTableName+' (memo_id,product_code,dept_id,bin_id,git_qty,xn_party_code,xn_no,xn_dt)
		SELECT ''PRT''+c.rm_id,a.product_code,party_dept_id,target_bin_id,SUM(a.quantity) AS GIT_QTY,
		''LOC''+c.location_code as xn_party_code,c.rm_no as xn_no,c.rm_dt as xn_dt 
		from rmD01106 A (NOLOCK) 
		JOIN rmm01106 c (NOLOCK) ON c.rm_id=a.rm_id 
		JOIN #tmpGitProcess b ON A.rm_id=SUBSTRING(b.memo_id,4,len(memo_id))
		where '+(CASE WHEN @bPickPrevGitLocs=1 THEN ' rm_dt='''+CONVERT(VARCHAR,@dXnDt,110)+''' AND ' ELSE '' END)+ ' left(memo_id,3)=''PRT''
		GROUP BY c.rm_id,LEFT(c.rm_ID,2),a.product_code,party_dept_id,target_bin_id,c.rm_no,c.rm_dt'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		IF @bPickPrevGitLocs=1
		BEGIN
			SET @cStep='70.12'
			EXEC SP_CHKXNSAVELOG 'DOCBLD',@cStep,0,@NSPID,1

			SET @cPrevTableName=DB_NAME()+'_PMT.DBO.GITLOCS_'+CONVERT(VARCHAR,@dXnDt-1,112)

			SET @cCmd=N'INSERT '+@cTableName+' (memo_id,product_code,dept_id,bin_id,git_qty,xn_party_code,xn_no,xn_dt)
			SELECT a.memo_id,product_code,dept_id,bin_id,git_qty,xn_party_code,xn_no,xn_dt
			from '+@cPrevTableName+' A (NOLOCK) 
			JOIN #tmpGitProcess b ON A.memo_id=b.memo_id'

			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END

END
