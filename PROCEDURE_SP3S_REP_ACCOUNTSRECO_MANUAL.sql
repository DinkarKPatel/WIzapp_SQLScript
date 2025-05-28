CREATE PROCEDURE SP3S_REP_ACCOUNTSRECO_MANUAL
@nQueryID	INT=0,
@dFromDt DATETIME='',
@dToDt DATETIME='',
@cXnType VARCHAR(20)='',
@nMode NUMERIC(1,0)=1
AS

BEGIN
	IF @nQueryID=1
	BEGIN
		SELECT DISTINCT XN_TYPE, REPLACE(DISPLAY_XN_TYPE,'PARTY ','') AS [XN_DESC],SNO
		FROM GST_ACCOUNTS_CONFIG_MST
		WHERE ISNULL(ENABLEPOSTING,0)=1 AND XN_TYPE IN ('PUR','PRT','WSR','WSL','JWR','SLS')
		ORDER BY SNO
		RETURN
	END

	DECLARE @dPurCutoffDate DATETIME,@dSlsCutoffDate DATETIME,@dWslCutoffDate DATETIME,@dPrtCutoffDate DATETIME,@dWsrCutoffDate DATETIME,
			@cStr VARCHAR(MAX),@cCmd NVARCHAR(MAX),@cStrCols VARCHAR(MAX),@cCreditorHeads VARCHAR(MAX),
			@cDebitorHeads VARCHAR(MAX),@cWhereStatus VARCHAR(200),@dJwrCutoffDate DATETIME
	
	
	SELECT TOP 1 @dPurCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='PUR'
	SELECT TOP 1 @dWslCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='WSL'
	SELECT TOP 1 @dPrtCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='PRT'
	SELECT TOP 1 @dWsrCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='WSR'
	SELECT TOP 1 @dSlsCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='SLS'
	SELECT TOP 1 @dJwrCutoffDate=cutoffdate FROM gst_accounts_config_mst (NOLOCK) WHERE xn_type='JWR'

	
	SELECT @dPurCutoffDate=(CASE WHEN @dPurCutoffDate<@dFromDt THEN @dFromDt ELSE @dPurCutoffDate+1 END),
			@dWslCutoffDate=(CASE WHEN @dWslCutoffDate<@dFromDt THEN @dFromDt ELSE @dWslCutoffDate+1 END),
			@dPrtCutoffDate=(CASE WHEN @dPrtCutoffDate<@dFromDt THEN @dFromDt ELSE @dPrtCutoffDate+1 END),
			@dWsrCutoffDate=(CASE WHEN @dWsrCutoffDate<@dFromDt THEN @dFromDt ELSE @dWsrCutoffDate+1 END),
			@dSlsCutoffDate=(CASE WHEN @dSlsCutoffDate<@dFromDt THEN @dFromDt ELSE @dSlsCutoffDate+1 END),
			@dJwrCutoffDate=(CASE WHEN @dJwrCutoffDate<@dFromDt THEN @dFromDt ELSE @dJwrCutoffDate+1 END)
	  	
	
	CREATE TABLE #tmpMemoData (memo_id varchar(50),party_name VARCHAR(500),memo_no varchar(50),xn_dt datetime,display_memo_dt varchar(10),
							   memo_amount numeric(20,2),memo_cancelled bit,cd_amount NUMERIC(10,2),
							   posted_amount NUMERIC(14,2),posting_status VARCHAR(50),approvedlevelno NUMERIC(4,0),grand_total bit,location_code varchar(4))

	SET @cWhereStatus=(CASE WHEN @nMode=1 THEN ' WHERE ISNULL(posting_status,'''')<>''posted'''
							ELSE '' END)
	CREATE TABLE #tmpVchData (memo_id varchar(50),head_code char(10),voucher_no varchar(20),voucher_Dt datetime,
							  party_amount NUMERIC(10,2),
							  vch_cancelled bit,vch_amount NUMERIC(14,2),ac_name VARCHAR(500),ac_amount NUMERIC(20,2),grand_total bit)
	
	SELECT @cCreditorHeads=dbo.FN_ACT_TRAVTREE('0000000021'),
		   @cDebitorHeads=dbo.FN_ACT_TRAVTREE('0000000018')
	
	
	SELECT DISTINCT DEPT_ID,a.xn_type ,max(level_no) as level_no
	INTO #APPROVALLOCATION
	FROM LOC_XNSAPPROVAL a
	JOIN XN_APPROVAL_CHECKLIST_LEVELS b ON a.xn_type=b.xn_type
	GROUP BY DEPT_ID,A.XN_TYPE

						   
	IF @cXnType in ('','PUR')
	BEGIN
		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,cd_amount,approvedlevelno,party_name,display_memo_dt,location_code )
		SELECT a.mrr_ID,bill_no AS memo_no,bill_dt AS xn_dt,a.cancelled, a.total_amount as memo_amount,
		a.Total_CashDiscountAmount,approvedlevelno,ac_name party_name,CONVERT(VARCHAR,bill_dt,105) display_memo_dt,a.location_Code
		from pim01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE bill_dt BETWEEN @dPurCutoffDate AND @dToDt
		AND (bill_challan_mode=0 OR inv_mode=2) AND cancelled=0 
				
		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount,head_code)
		SELECT a.memo_id,voucher_no,voucher_Dt,b.cancelled,
		(CASE WHEN c.ac_code=e.ac_code THEN 'Supplier Debited' ELSE ac_name END) ac_name,SUM(debit_amount-credit_amount) AS ac_amount,head_code
		FROM postact_voucher_link a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
		JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
		JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
		JOIN pim01106 e (NOLOCK) ON e.mrr_id=a.memo_id
		WHERE LEFT(xn_type,3)='PUR' AND voucher_dt  BETWEEN @dPurCutoffDate AND @dToDt  AND (c.ac_code<>e.ac_code or debit_amount<>0)
		AND ac_name<>'' AND e.cancelled=0 AND b.cancelled=0
		GROUP BY a.memo_id,voucher_no,voucher_Dt,b.cancelled,(CASE WHEN c.ac_code=e.ac_code THEN 'Supplier Debited' ELSE ac_name END),head_code


		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpMemoData)
		BEGIN
			INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,cd_amount)
			SELECT 'No Data' memo_id,'' memo_no,'' xn_dt,0 memo_cancelled,0 memo_amount,0 cd_amount
		END

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpVchData)
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
			SELECT 'No Data' memo_id,'' voucher_no,'' voucher_Dt,0 vch_cancelled,'NoData' ac_name,0 memo_amount
		END
		
		--select 'check pur', * from #tmpVchData where memo_id='010112000000001-000005'
		--select 'check memo',* from  #tmpMemoData

		--if @@spid=289
		--	SELECT CHARINDEX(head_code,@cCreditorHeads),'check pur vch',* from #tmpvchdata where memo_id='HO011210000HOSR-000024'
		--	--and CHARINDEX(head_code,@cCreditorHeads)>0 

		UPDATE a SET POSTED_amount=ISNULL(b.ac_amount,0),
		posting_status=(CASE WHEN b.memo_id IS NULL AND c.DEPT_ID IS NOT NULL AND ISNULL(approvedlevelno,0)<isnull(c.level_no,0) THEN 'Pending for Approval'
							 WHEN b.memo_id IS NULL THEN 'Pending for Posting'
							 WHEN (abs(a.memo_amount-ISNULL(b.ac_amount,0))>1)
							 THEN 'Difference' ELSE 'POSTED' END) FROM #tmpMemoData a 
		left outer join		
		(SELECT memo_id,sum(ac_amount) as ac_amount from #tmpVchData
		 GROUP BY memo_id) b ON a.memo_id=b.memo_id
		LEFT OUTER JOIN #APPROVALLOCATION c ON c.DEPT_ID=a.location_code  AND c.xn_type='PUR'

		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,cd_amount,posted_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' memo_no,'' xn_dt,0 memo_cancelled,SUM(memo_amount),
		SUM(cd_amount),SUM(posted_amount) posted_amount,1 grand_total
		FROM #tmpMemoData
		
		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' voucher_no,'' voucher_Dt,0 vch_cancelled,ac_name,
		SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name

		SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData WHERE memo_id<>'No Data') a

		SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
		
		SET @cCmd=N'
					;WITH cteVch as
					(
					SELECT vch_memo_id,voucher_no,voucher_dt,vch_cancelled,'+@cStrCols+' FROM 
					(SELECT memo_id as vch_memo_id,voucher_no,voucher_dt,vch_cancelled,ac_name,ac_amount 
					 FROM #tmpVchData WHERE memo_id<>''No Data'') A
					pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
					) 
										
					SELECT ''PURCHASE'' AS xn_type,Party_name,(CASE WHEN posting_status=''POSTED'' THEN 0 ELSE 1 END) mismatch,
					a.memo_id,a.memo_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else display_memo_dt end) memo_dt,a.memo_amount,
					a.cd_amount,a.posted_amount,a.posting_status,a.approvedlevelno,a.grand_total,a.memo_cancelled,
					vch_memo_id,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end)  voucher_dt,vch_cancelled,'+@cStrCols+'
					FROM  #tmpMemoData a full outer join ctevch b ON a.memo_id=b.vch_memo_id
					'+@cWhereStatus+'
					order by isnull(grand_total,0),ISNULL(xn_dt,voucher_dt),memo_no
					'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		TRUNCATE TABLE #tmpVchData
		
		SELECT @cStr='',@cStrCols=''
		
		IF @nMode=4
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,ac_name,ac_amount)
			SELECT 'PURCHASE-Journal' AS xn_type,voucher_no,voucher_Dt,'Party' ac_name,
			SUM(credit_amount-debit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000006' AND b.cancelled=0  AND voucher_dt BETWEEN @dPurCutoffDate AND @dToDt
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)>0
			GROUP BY voucher_no,voucher_Dt,ac_name
			UNION 
			SELECT 'PURCHASE-Journal' AS xn_type,voucher_no,voucher_Dt,ac_name,SUM(debit_amount-credit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000006' AND b.cancelled=0  AND voucher_dt BETWEEN @dPurCutoffDate AND @dToDt 
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)=0
			GROUP BY voucher_no,voucher_Dt,ac_name


			INSERT #tmpVchData  (voucher_no,voucher_Dt,ac_name,ac_amount,grand_total)
			SELECT 'Grand Total:'  voucher_no,'' voucher_Dt,ac_name,
			SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
		
			IF EXISTS (SELECT TOP 1 * FROM #tmpVchData)
			BEGIN	
				SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
		
				SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
		
				--select @cStrCols as pur_journals_strcols
				SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
		
				SET @cCmd=N'
							;WITH cteVch as
							(
							SELECT memo_id,voucher_no,voucher_dt,grand_total,'+@cStrCols+' FROM #tmpVchData
							pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
							) 

							SELECT memo_id AS xn_type,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end) voucher_dt,'+@cStrCols+'
							FROM  ctevch b
							order by isnull(grand_total,0),voucher_dt,voucher_no

							'
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END						
		END

	END

	DECLARE @cWslheads VARCHAR(MAX)
	SELECT @cWslheads=dbo.fn_act_travtree('0000000030')
	select @cWslheads=@cWslheads+','+dbo.fn_act_travtree('0000000019')

	IF @cXnType in ('','WSL')
	BEGIN
		TRUNCATE TABLE #tmpMemoData
		TRUNCATE TABLE #tmpVchData

		SELECT @cStr='',@cStrCols=''

		INSERT #tmpMemoData (memo_id,party_name,memo_no,xn_dt,memo_cancelled,memo_amount,approvedlevelno,display_memo_dt)
		SELECT a.inv_ID,ac_name party_name,inv_no AS memo_no,inv_dt AS xn_dt,a.cancelled, a.net_amount as memo_amount,approvedlevelno,convert(varchar,inv_dt,105) display_memo_dt
		from inm01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE inv_dt BETWEEN @dWslCutoffDate AND @dToDt 
		AND cancelled=0

		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
		SELECT a.memo_id,voucher_no,voucher_Dt,b.cancelled,ac_name,SUM(credit_amount-debit_amount) AS ac_amount
		FROM postact_voucher_link a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
		JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
		JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
		JOIN inm01106 e (NOLOCK) ON e.inv_id=a.memo_id
		WHERE LEFT(xn_type,3)='WSL'  AND e.cancelled=0 AND b.cancelled=0 AND voucher_dt BETWEEN @dWslCutoffDate AND @dToDt AND c.ac_code<>e.ac_code
		AND ac_name<>''
		GROUP BY a.memo_id,voucher_no,voucher_Dt,b.cancelled,ac_name

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpMemoData)
		BEGIN
			INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount)
			SELECT 'No Data' memo_id,'' memo_no,'' xn_dt,0 memo_cancelled,0 memo_amount
		END
					

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpVchData)
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
			SELECT 'No Data' memo_id,'' voucher_no,'' voucher_Dt,0 vch_cancelled,'NoData' ac_name,0 memo_amount
		END

		UPDATE a SET
		posting_status=(CASE WHEN b.memo_id IS NULL AND c.DEPT_ID IS NOT NULL AND ISNULL(approvedlevelno,0)<isnull(c.level_no,0) THEN 'Pending for Approval'
							 WHEN b.memo_id IS NULL THEN 'Pending for Posting'
							 WHEN (abs(a.memo_amount-ISNULL(b.ac_amount,0))>1)
							 THEN 'Difference' ELSE 'POSTED' END),
		POSTED_amount=ISNULL(b.ac_amount,0) FROM #tmpMemoData a 
		left outer join 
		(SELECT memo_id,sum(ac_amount) as ac_amount from #tmpVchData GROUP BY memo_id) b ON a.memo_id=b.memo_id
		LEFT OUTER JOIN #APPROVALLOCATION c ON c.DEPT_ID=a.location_code AND c.xn_type='WSL'


		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,cd_amount,posted_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' memo_no,'' xn_dt,0 memo_cancelled,SUM(memo_amount),
		SUM(cd_amount),SUM(posted_amount) posted_amount,1 grand_total
		FROM #tmpMemoData
			
		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' voucher_no,'' voucher_Dt,0 vch_cancelled,ac_name,
		SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name

		SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a

		SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
		
		SET @cCmd=N'
					;WITH cteVch as
					(
					SELECT vch_memo_id,voucher_no,voucher_dt,vch_cancelled,'+@cStrCols+' FROM 
					(SELECT memo_id as vch_memo_id,voucher_no,voucher_dt,vch_cancelled,ac_name,ac_amount 
					 FROM #tmpVchData WHERE memo_id<>''No Data'') A
					pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
					) 

					SELECT ''WHOLESALE'' as xN_type,Party_name,(CASE WHEN posting_status=''POSTED'' THEN 0 ELSE 1 END) mismatch,
					a.memo_id,a.memo_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else display_memo_dt end)  memo_dt,a.memo_amount,
					a.posted_amount,a.posting_status,a.approvedlevelno,a.grand_total,a.memo_cancelled,
					vch_memo_id,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end)  voucher_dt,vch_cancelled,'+@cStrCols+'
					FROM  #tmpMemoData a full outer join ctevch b ON a.memo_id=b.vch_memo_id
					'+@cWhereStatus+'
					order by isnull(grand_total,0),xn_dt,memo_no
					'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		TRUNCATE TABLE #tmpVchData
		
		
		
		SELECT @cStr='',@cStrCols=''
		
		IF @nMode=4
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,ac_name,ac_amount)
			SELECT 'WHOLESALE-Journal' AS xn_type,voucher_no,voucher_Dt,'Party' ac_name,
			SUM(credit_amount-debit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000007' AND b.cancelled=0  AND voucher_dt BETWEEN @dWslCutoffDate AND @dToDt
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)>0
			GROUP BY voucher_no,voucher_Dt,ac_name
			UNION 
			SELECT 'WHOLESALE-Journal' AS xn_type,voucher_no,voucher_Dt,ac_name,SUM(debit_amount-credit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000007' AND b.cancelled=0  AND voucher_dt BETWEEN @dWslCutoffDate AND @dToDt
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)=0
			GROUP BY voucher_no,voucher_Dt,ac_name
		
			IF EXISTS (SELECT TOP 1 * FROM #tmpVchData)
			BEGIN
				INSERT #tmpVchData  (voucher_no,voucher_Dt,ac_name,ac_amount,grand_total)
				SELECT 'Grand Total:'  voucher_no,'' voucher_Dt,ac_name,
				SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
				
				SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
			
				SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
			
			
				SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
			
				SET @cCmd=N'
							;WITH cteVch as
							(
							SELECT memo_id,voucher_no,voucher_dt,grand_total,'+@cStrCols+' FROM #tmpVchData
							pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
							) 

							SELECT memo_id as xn_type,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end) voucher_dt,'+@cStrCols+'
							FROM  ctevch b
							order by isnull(grand_total,0),voucher_dt,voucher_no

							'
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END	
		END
	END

	IF @cXnType in ('','PRT')
	BEGIN
		TRUNCATE TABLE #tmpMemoData
		TRUNCATE TABLE #tmpVchData

		SELECT @cStr='',@cStrCols=''

		INSERT #tmpMemoData (memo_id,party_name,memo_no,xn_dt,memo_cancelled,memo_amount,approvedlevelno,display_memo_dt)
		SELECT a.rm_ID,ac_name party_name,rm_no AS memo_no,rm_dt AS xn_dt,a.cancelled, a.total_amount as memo_amount,approvedlevelno,convert(varchar,rm_dt,105) display_memo_dt
		from rmm01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE rm_dt BETWEEN @dPrtCutoffDate AND @dToDt AND cancelled=0

		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
		SELECT a.memo_id,voucher_no,voucher_Dt,b.cancelled,ac_name,SUM(credit_amount-debit_amount) AS ac_amount
		FROM postact_voucher_link a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
		JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
		JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
		JOIN rmm01106 e (NOLOCK) ON e.rm_id=a.memo_id
		WHERE LEFT(xn_type,3)='PRT' AND e.cancelled=0 AND b.cancelled=0 AND voucher_dt BETWEEN @dPrtCutoffDate AND @dToDt AND c.ac_code<>e.ac_code
		AND ac_name<>''
		GROUP BY a.memo_id,voucher_no,voucher_Dt,b.cancelled,ac_name

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpMemoData)
		BEGIN
			INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount)
			SELECT 'No Data' memo_id,'' memo_no,'' xn_dt,0 memo_cancelled,0 memo_amount
		END
	
		
		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpVchData)
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
			SELECT 'No Data' memo_id,'' voucher_no,'' voucher_Dt,0 vch_cancelled,'NoData' ac_name,0 memo_amount
		END

		UPDATE a SET 
		posting_status=(CASE WHEN b.memo_id IS NULL AND c.DEPT_ID IS NOT NULL AND ISNULL(approvedlevelno,0)<isnull(c.level_no,0) THEN 'Pending for Approval'
							 WHEN b.memo_id IS NULL THEN 'Pending for Posting'
							 WHEN (abs(a.memo_amount-isnull(cd_amount,0) -ISNULL(b.ac_amount,0))>1)
							 THEN 'Difference' ELSE 'POSTED' END),
		POSTED_amount=ISNULL(b.ac_amount,0) FROM #tmpMemoData a 
		left outer join 
		(SELECT memo_id,sum(ac_amount) as ac_amount from #tmpVchData GROUP BY memo_id) b ON a.memo_id=b.memo_id
		LEFT OUTER JOIN #APPROVALLOCATION c ON c.DEPT_ID=a.location_code AND c.xn_type='PRT'

		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,cd_amount,posted_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' memo_no,'' xn_dt,0 memo_cancelled,SUM(memo_amount),
		SUM(cd_amount),SUM(posted_amount) posted_amount,1 grand_total
		FROM #tmpMemoData
							
		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' voucher_no,'' voucher_Dt,0 vch_cancelled,ac_name,
		SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
		
		SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a

		SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
		
		SET @cCmd=N'
					;WITH cteVch as
					(
					SELECT vch_memo_id,voucher_no,voucher_dt,vch_cancelled,'+@cStrCols+' FROM 
					(SELECT memo_id as vch_memo_id,voucher_no,voucher_dt,vch_cancelled,ac_name,ac_amount 
					 FROM #tmpVchData WHERE memo_id<>''No Data'') A
					pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
					) 

					SELECT ''Debit Note'' as xN_type,Party_name,(CASE WHEN posting_status=''POSTED'' THEN 0 ELSE 1 END) mismatch,
					a.memo_id,a.memo_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else display_memo_dt end)  memo_dt,a.memo_amount,
					a.posted_amount,a.posting_status,a.approvedlevelno,a.grand_total,a.memo_cancelled,
					vch_memo_id,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end) voucher_dt,vch_cancelled,'+@cStrCols+'
					FROM  #tmpMemoData a full outer join ctevch b ON a.memo_id=b.vch_memo_id
					 '+@cWhereStatus+'
					order by isnull(grand_total,0),xn_dt,memo_no
					'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		
		TRUNCATE TABLE #tmpVchData
		
		SELECT @cStr='',@cStrCols=''
		
		IF @nMode=4
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,ac_name,ac_amount)
			SELECT 'Debit Note-Journal' AS xn_type,voucher_no,voucher_Dt,'Party' ac_name,
			SUM(credit_amount-debit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000005' AND b.cancelled=0  AND voucher_dt BETWEEN @dPrtCutoffDate AND @dToDt 
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)>0
			GROUP BY voucher_no,voucher_Dt,ac_name
			UNION 
			SELECT 'Debit Note-Journal' AS xn_type,voucher_no,voucher_Dt,ac_name,SUM(debit_amount-credit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000005' AND b.cancelled=0  AND voucher_dt  BETWEEN @dPrtCutoffDate AND @dToDt 
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)=0
			GROUP BY voucher_no,voucher_Dt,ac_name

			IF EXISTS (SELECT TOP 1 * FROM #tmpVchData)
			BEGIN
				INSERT #tmpVchData  (voucher_no,voucher_Dt,ac_name,ac_amount,grand_total)
				SELECT 'Grand Total:'  voucher_no,'' voucher_Dt,ac_name,
				SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
				
				SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
			
				SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
			
			
				SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
			
				SET @cCmd=N'
							;WITH cteVch as
							(
							SELECT memo_id,voucher_no,voucher_dt,grand_total,'+@cStrCols+' FROM #tmpVchData
							pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
							) 

							SELECT memo_id as xn_type,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end) voucher_dt,'+@cStrCols+'
							FROM  ctevch b
							order by isnull(grand_total,0),voucher_dt,voucher_no

							'
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd
			END
		END		
	END
	
	IF @cXnType in ('','WSR')
	BEGIN
		TRUNCATE TABLE #tmpMemoData
		TRUNCATE TABLE #tmpVchData

		SELECT @cStr='',@cStrCols=''

		INSERT #tmpMemoData (memo_id,party_name,memo_no,xn_dt,memo_cancelled,memo_amount,approvedlevelno,display_memo_dt)
		SELECT a.cn_ID,ac_name party_name, cn_no AS memo_no,cn_dt AS xn_dt,a.cancelled, a.total_amount as memo_amount,approvedlevelno,
		(CASE WHEN mode=2 THEN convert(varchar,receipt_dt,105) ELSE CONVERT(VARCHAR,cn_dt,105) END) display_memo_dt
		from cnm01106 a JOIN lm01106 b ON a.ac_code=b.AC_CODE WHERE cn_dt BETWEEN @dWsrCutoffDate AND @dToDt
		AND cancelled=0

		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
		SELECT a.memo_id,voucher_no,voucher_Dt,b.cancelled,ac_name,SUM(debit_amount-credit_amount) AS ac_amount
		FROM postact_voucher_link a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
		JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
		JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
		JOIN cnm01106 e (NOLOCK) ON e.cn_id=a.memo_id
		WHERE LEFT(xn_type,3)='WSR' AND e.cancelled=0 AND b.cancelled=0 AND voucher_dt BETWEEN @dWsrCutoffDate AND @dToDt  AND c.ac_code<>e.ac_code
		AND ac_name<>''
		GROUP BY a.memo_id,voucher_no,voucher_Dt,b.cancelled,ac_name

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpMemoData)
		BEGIN
			INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount)
			SELECT 'No Data' memo_id,'' memo_no,'' xn_dt,0 memo_cancelled,0 memo_amount
		END
		
		UPDATE a SET 
		posting_status=(CASE WHEN b.memo_id IS NULL AND c.DEPT_ID IS NOT NULL AND ISNULL(approvedlevelno,0)<isnull(c.level_no,0) THEN 'Pending for Approval'
							 WHEN b.memo_id IS NULL THEN 'Pending for Posting'
							 WHEN (abs(a.memo_amount-ISNULL(b.ac_amount,0))>1)
							 THEN 'Difference' ELSE 'POSTED' END),
		POSTED_amount=ISNULL(b.ac_amount,0) FROM #tmpMemoData a 
		left outer join 
		(SELECT memo_id,sum(ac_amount) as ac_amount from #tmpVchData GROUP BY memo_id) b ON a.memo_id=b.memo_id
		LEFT OUTER JOIN #APPROVALLOCATION c ON c.DEPT_ID=a.location_code AND c.xn_type='WSR'

		
		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpVchData)
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
			SELECT 'No Data' memo_id,'' voucher_no,'' voucher_Dt,0 vch_cancelled,'NoData' ac_name,0 memo_amount
		END
		
		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,cd_amount,posted_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' memo_no,'' xn_dt,0 memo_cancelled,SUM(memo_amount),
		SUM(cd_amount),SUM(posted_amount) posted_amount,1 grand_total
		FROM #tmpMemoData
							
		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' voucher_no,'' voucher_Dt,0 vch_cancelled,ac_name,
		SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
		
		SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
		
		SET @cCmd=N'
					;WITH cteVch as
					(
					SELECT vch_memo_id,voucher_no,voucher_dt,vch_cancelled,'+@cStrCols+' FROM 
					(SELECT memo_id as vch_memo_id,voucher_no,voucher_dt,vch_cancelled,ac_name,ac_amount 
					 FROM #tmpVchData WHERE memo_id<>''No Data'') A
					pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
					) 

					SELECT ''Credit Note'' as xN_type,Party_name,(CASE WHEN posting_status=''POSTED'' THEN 0 ELSE 1 END) mismatch,
					a.memo_id,a.memo_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else display_memo_dt end)  memo_dt,a.memo_amount,
					a.posted_amount,a.posting_status,a.approvedlevelno,a.grand_total,a.memo_cancelled,
					vch_memo_id,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end)  voucher_dt,vch_cancelled,'+@cStrCols+'
					FROM  #tmpMemoData a full outer join ctevch b ON a.memo_id=b.vch_memo_id
					'+@cWhereStatus+'
					order by isnull(grand_total,0),xn_dt,memo_no
					'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd


		TRUNCATE TABLE #tmpVchData
		
		SELECT @cStr='',@cStrCols=''
		
		IF @nMode=4
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,ac_name,ac_amount)
			SELECT 'Credit Note-Journal' AS xn_type,voucher_no,voucher_Dt,'Party' ac_name,
			SUM(credit_amount-debit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000004' AND b.cancelled=0  AND voucher_dt BETWEEN @dWsrCutoffDate AND @dToDt 
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)>0
			GROUP BY voucher_no,voucher_Dt,ac_name
			UNION 
			SELECT 'Credit Note-Journal' AS xn_type,voucher_no,voucher_Dt,ac_name,SUM(debit_amount-credit_amount) AS ac_amount
			FROM vm01106 b (NOLOCK) 
			JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
			JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
			JOIN vchtype vch (NOLOCK) ON vch.VOUCHER_CODE=b.VOUCHER_CODE
			LEFT OUTER JOIN postact_voucher_link a (NOLOCK) ON a.VM_ID=b.VM_ID
			WHERE vch.VOUCHER_CODE='0000000004' AND b.cancelled=0  AND voucher_dt BETWEEN @dWsrCutoffDate AND @dToDt 
			AND ac_name<>'' AND a.vm_id IS NULL
			AND CHARINDEX(head_code,@cCreditorHeads)=0
			GROUP BY voucher_no,voucher_Dt,ac_name

			IF EXISTS (SELECT TOP 1 * FROM #tmpVchData)
			BEGIN
				INSERT #tmpVchData  (voucher_no,voucher_Dt,ac_name,ac_amount,grand_total)
				SELECT 'Grand Total:'  voucher_no,'' voucher_Dt,ac_name,
				SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
				
				SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
			
				SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
				(SELECT distinct ltrim(rtrim(ac_name)) as ac_name FROM #tmpVchData) a
			
			
				SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
			
				SET @cCmd=N'
							;WITH cteVch as
							(
							SELECT memo_id,voucher_no,voucher_dt,grand_total,'+@cStrCols+' FROM #tmpVchData
							pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
							) 

							SELECT memo_id AS xn_type,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end) voucher_dt,'+@cStrCols+'
							FROM  ctevch b
							order by isnull(grand_total,0),voucher_dt,voucher_no

							'
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd	
			END	
		END

	END

	IF @cXnType IN ('','SLS')
	BEGIN
		TRUNCATE TABLE #tmpMemoData
		TRUNCATE TABLE #tmpVchData

		DECLARE @cSalesheads VARCHAR(MAX)
		SELECT @cSalesheads=dbo.fn_act_travtree('0000000030')
		select @cSalesheads=@cSalesheads+','+dbo.fn_act_travtree('0000000019')

		SELECT @cStr='',@cStrCols=''

		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount)
		SELECT a.location_Code +convert(varchar,cm_dt,112) as memo_id,a.location_Code +convert(varchar,cm_dt,112) as memo_no,
		cm_dt AS xn_dt,0 as cancelled,SUM(net_amount-isnull(other_charges_taxable_value,0)-
		 round_off-gst_round_off) as memo_amount
		from cmm01106 a  WHERE cm_dt  BETWEEN @dSlsCutoffDate AND @dToDt  AND cancelled=0
		GROUP BY a.location_code,cm_dt

		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,ac_name,ac_amount)
		SELECT a.memo_id,voucher_no,voucher_Dt,ac_name,SUM(credit_amount-debit_amount) AS ac_amount
		FROM postact_voucher_link a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
		JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
		JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
		WHERE xn_type='SLS' AND b.cancelled=0 AND voucher_dt BETWEEN @dSlsCutoffDate AND @dToDt 
		AND CHARINDEX(d.head_code,@cSalesheads)>0
		GROUP BY a.memo_id,voucher_no,voucher_Dt,ac_name

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpMemoData)
		BEGIN
			INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount)
			SELECT 'No Data' memo_id,'' memo_no,'' xn_dt,0 memo_cancelled,0 memo_amount
		END
		
		
		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpVchData)
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,ac_name,ac_amount)
			SELECT 'No Data' memo_id,'' voucher_no,'' voucher_Dt,'NoData' ac_name,0 memo_amount
		END
	
		UPDATE a SET 
		posting_status=(CASE WHEN b.memo_id IS NULL THEN 'Pending for Posting'
							 WHEN (abs(a.memo_amount-ISNULL(b.ac_amount,0))>1)
							 THEN 'Difference' ELSE 'POSTED' END),
		POSTED_amount=ISNULL(b.ac_amount,0) FROM #tmpMemoData a 
		left outer join 
		(SELECT memo_id,sum(ac_amount) as ac_amount from #tmpVchData GROUP BY memo_id) b ON a.memo_id=b.memo_id

		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,cd_amount,posted_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' memo_no,'' xn_dt,0 memo_cancelled,SUM(memo_amount),
		SUM(cd_amount),SUM(posted_amount) posted_amount,1 grand_total
		FROM #tmpMemoData
							
		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' voucher_no,'' voucher_Dt,0 vch_cancelled,ac_name,
		SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
		
		SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
		
		SET @cCmd=N'
					;WITH cteVch as
					(
					SELECT vch_memo_id,voucher_no,voucher_dt,'+@cStrCols+' FROM 
					(SELECT memo_id as vch_memo_id,voucher_no,voucher_dt,ac_name,ac_amount 
					 FROM #tmpVchData WHERE memo_id<>''No Data'') A
					pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
					) 

					SELECT ''Retail Sales'' as xN_type,(CASE WHEN posting_status=''POSTED'' THEN 0 ELSE 1 END) mismatch,a.*,
					vch_memo_id,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end) voucher_dt,'+@cStrCols+'
					FROM  #tmpMemoData a full outer join ctevch b ON a.memo_id=b.vch_memo_id
					'+@cWhereStatus+'
					order by isnull(grand_total,0),xn_dt,memo_no
					'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	END

	IF @cXnType in ('','JWR')
	BEGIN
		TRUNCATE TABLE #tmpMemoData
		TRUNCATE TABLE #tmpVchData

		SELECT @cStr='',@cStrCols=''

		INSERT #tmpMemoData (memo_id,party_name,memo_no,xn_dt,memo_cancelled,memo_amount,approvedlevelno,display_memo_dt)
		SELECT a.receipt_ID,ac_name party_name,receipt_no AS memo_no,receipt_dt AS xn_dt,a.cancelled, 
		a.net_amount as memo_amount,approvedlevelno,convert(varchar,receipt_dt,105) display_memo_dt
		from jobwork_receipt_mst a (NOLOCK) JOIN prd_agency_mst b on a.agency_code=b.agency_code
		JOIN lm01106 c (NOLOCK) ON c.ac_code=b.AC_CODE 
		WHERE receipt_dt BETWEEN @dJwrCutoffDate AND @dTodt AND  cancelled=0

		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
		SELECT a.memo_id,voucher_no,voucher_Dt,b.cancelled,
		(CASE WHEN c.ac_code=e.ac_code THEN 'Party Debited' ELSE ac_name END),SUM(debit_amount-credit_amount) AS ac_amount
		FROM postact_voucher_link a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
		JOIN vd01106 c (NOLOCK) ON c.vm_id=b.vm_id
		JOIN lm01106 d (NOLOCK) ON d.ac_code=c.ac_code
		JOIN jobwork_receipt_mst e (NOLOCK) ON e.receipt_id=a.memo_id
		JOIN prd_agency_mst f (NOLOCK) ON f.agency_code=e.agency_code
		WHERE xn_type='JWR' AND e.cancelled=0 AND b.cancelled=0 AND voucher_dt BETWEEN @dJwrCutoffDate AND @dToDt AND (c.ac_code<>f.ac_code OR debit_amount<>0)
		AND ac_name<>''
		GROUP BY a.memo_id,voucher_no,voucher_Dt,b.cancelled,
		(CASE WHEN c.ac_code=e.ac_code THEN 'Party Debited' ELSE ac_name END)

		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpMemoData)
		BEGIN
			INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount)
			SELECT 'No Data' memo_id,'' memo_no,'' xn_dt,0 memo_cancelled,0 memo_amount
		END
	
		
		IF NOT EXISTS (SELECT TOP 1 * FROM #tmpVchData)
		BEGIN
			INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount)
			SELECT 'No Data' memo_id,'' voucher_no,'' voucher_Dt,0 vch_cancelled,'NoData' ac_name,0 memo_amount
		END

		UPDATE a SET 
		posting_status=(CASE WHEN b.memo_id IS NULL AND c.DEPT_ID IS NOT NULL AND ISNULL(approvedlevelno,0)<isnull(c.level_no,0) THEN 'Pending for Approval'
							 WHEN b.memo_id IS NULL THEN 'Pending for Posting'
							 WHEN (abs(a.memo_amount-ISNULL(b.ac_amount,0))>1)
							 THEN 'Difference' ELSE 'POSTED' END),
		POSTED_amount=ISNULL(b.ac_amount,0) FROM #tmpMemoData a 
		left outer join 
		(SELECT memo_id,sum(ac_amount) as ac_amount from #tmpVchData GROUP BY memo_id) b ON a.memo_id=b.memo_id
		LEFT OUTER JOIN #APPROVALLOCATION c ON c.DEPT_ID=a.location_code AND c.xn_type='JWR'

		INSERT #tmpMemoData (memo_id,memo_no,xn_dt,memo_cancelled,memo_amount,posted_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' memo_no,'' xn_dt,0 memo_cancelled,SUM(memo_amount),
		SUM(posted_amount) posted_amount,1 grand_total
		FROM #tmpMemoData
							
		INSERT #tmpVchData  (memo_id,voucher_no,voucher_Dt,vch_cancelled,ac_name,ac_amount,grand_total)
		SELECT '' as memo_id,'Grand Total:' voucher_no,'' voucher_Dt,0 vch_cancelled,ac_name,
		SUM(ac_amount) as ac_amount,1 grand_total FROM #tmpVchData GROUP BY ac_name
		
		SELECT @cStrCols=COALESCE(@cStrCols,'')+'ISNULL(['+ac_name+'],0) as ['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a
		
		SELECT @cStr=COALESCE(@cStr,'')+'['+ac_name+'],' FROM 
		(SELECT distinct ac_name FROM #tmpVchData) a

		SELECT @cStr=LEFT(@cStr,LEN(@cStr)-1),@cStrCols=LEFT(@cStrCols,LEN(@cStrCols)-1)
		
		SET @cCmd=N'
					;WITH cteVch as
					(
					SELECT vch_memo_id,voucher_no,voucher_dt,vch_cancelled,'+@cStrCols+' FROM 
					(SELECT memo_id as vch_memo_id,voucher_no,voucher_dt,vch_cancelled,ac_name,ac_amount 
					 FROM #tmpVchData WHERE memo_id<>''No Data'') A
					pivot (max(ac_amount) for ac_name in ('+@cStr+')) pvt
					) 

					SELECT ''Jobwork Receipt'' as xN_type,Party_name,(CASE WHEN posting_status=''POSTED'' THEN 0 ELSE 1 END) mismatch,
					a.memo_id,a.memo_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else display_memo_dt end)  memo_dt,a.memo_amount,
					a.posted_amount,a.posting_status,a.approvedlevelno,a.grand_total,a.memo_cancelled,
					vch_memo_id,voucher_no,(CASE WHEN isnull(grand_total,0)=1 then '''' else convert(varchar,voucher_dt,105) end) voucher_dt,vch_cancelled,'+@cStrCols+'
					FROM  #tmpMemoData a full outer join ctevch b ON a.memo_id=b.vch_memo_id
					 '+@cWhereStatus+'
					order by isnull(grand_total,0),xn_dt,memo_no
					'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		
	END

END