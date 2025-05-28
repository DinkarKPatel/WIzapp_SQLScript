CREATE PROCEDURE SP3S_GENXPERT_REPDATA
@nMode NUMERIC(1,0)=1, --1.View Report , 2. Export Data
@cRepId CHAR(10),
@cFilter Varchar(max),
@dFromDt DATETIME,
@dToDt DATETIME,
@cFilterRepId CHAR(10)='',
@cAddnlFilter VARCHAR(MAX)=''
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cCalcCols VARCHAR(MAX),@cMstCols VARCHAR(MAX),@cXnType VARCHAR(100),
	@cRepTableName VARCHAR(100),@cStep VARCHAR(15),@cErrormsg VARCHAR(MAX),@cColNames VARCHAR(MAX),@bXnHistory BIT,
	@cBaseExpr VARCHAR(MAX),@cSubXntype VARCHAR(100),@cLayoutCols VARCHAR(MAX),@cGrpCols VARCHAR(MAX),@bObsCbsColstaken BIT,
	@cJoinStr VARCHAR(MAX),@cInsCols VARCHAR(MAX),@cOrderCols VARCHAR(MAX),@cOutputFilter VARCHAR(MAX),@cUpdPmodeCols VARCHAR(2000),
	@cRepType VARCHAR(20),@bPaymodeColsFound BIT,@cPaymodeExpr VARCHAR(MAX),@cPaymodeColsStru VARCHAR(2000),@dFromDtNew DATETIME,
	@cPaymodeColsExpr VARCHAR(2000),@cXpertRepCode VARCHAR(10),@cPaymodeJoinStr VARCHAR(MAX),@cGstCol VARCHAR(100),@nCrossTabtype INT,
	@bGstColFoundinSmryRep bit,@bImageColFound BIT,@bOhColFoundInDetailRep BIT,@cOhColsStru VARCHAR(2000),@bMtdXnType BIT,@bYtdXnType BIT,
	@cHoLocId VARCHAR(5),@cXrErrormsg VARCHAR(MAX),@cTempdb VARCHAR(200),@cOlapServerReporting VARCHAR(2),@cLoopXntype VARCHAR(200),
	@bCbsColInserted BIT,@cOldBaseExpr VARCHAR(MAX),@cAgeColnames VARCHAR(300),@bAgeColsFound BIT,@bYtdColFound BIT,@bMtdColFound BIT,
	@cEossSchemeNameCol VARCHAR(200),@bEossSchDataFetched BIT, @cEossSchJoinStr VARCHAR(MAX)

BEGIN TRY	
	SET @cStep='10'
	print 'Running Step#'+@cStep
	SET @cErrormsg=''
	SELECT @bAgeColsFound=0,@bObsCbsColstaken=0,@bEossSchDataFetched=0

	SELECT TOP 1 @cOlapServerReporting=value FROM config (NOLOCK) WHERE config_option='OLAP_SERVER_REPORTING'

	SET @cTempdb=DB_NAME()+(CASE WHEN ISNULL(@cOlapServerReporting,'')<>'1' THEN '_IMAGE' ELSE '_OLAP' END)+'.DBO.'

	SET @cRepTableName='rep_det_'+left(convert(varchar(38),newid()),10)
	
	
	
	SELECT TOP 1 @cXpertRepCode=xpert_rep_code, @cRepType=(CASE WHEN XPERT_REP_CODE='R1' THEN 'STOCK'
	WHEN xpert_rep_code='R2' THEN 'DETAIL' 	WHEN XPERT_REP_CODE='R3' THEN 'SMRY' 
	WHEN XPERT_REP_CODE='R4' THEN 'POPEND' WHEN XPERT_REP_CODE='R5' THEN 'CAR'
	ELSE '' END),@nCrossTabType=crosstab_type,
	@bXnHistory=isnull(xn_history,0) FROM  #rep_mst (NOLOCK) 
	
	WHERE rep_id=@cRepId

	--if @@spid=94
	--	select 'check xpert_rep_code',@cRepId as repid, XPERT_REP_CODE,* from #rep_mst

	IF EXISTS (SELECT TOP 1 * FROM #rep_det WHERE dimension=1) AND ISNULL(@nCrossTabtype,0)=0
		UPDATE #rep_mst SET crosstab_type=1

	SELECT @bYtdColFound=0,@bMtdColFound=0

	IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE RIGHT(key_col,3) IN ('YTD'))
		SET @bYtdColFound=1

	IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE RIGHT(key_col,3) IN ('MTD'))
		SET @bMtdColFound=1
	

	IF @cXpertRepCode='R3'
		DELETE FROM #rep_det WHERE key_col IN ('IGST_Amount','LGST_Amount','Taxable_Value','gst_cess_amount')
	
	SET @cStep='12'
	SELECT (CASE WHEN  mode=1 THEN 'purchase ageing' WHEN mode=2 THEN 'Sale ageing' ELSE 'Shelf ageing' END) as ageing_col,
	'XXXXXXXXX' as rep_ageing_col,convert(numeric(5,0),ageing_days) as ageing_days,
	convert(varchar(100),'') rep_col,CONVERT(BIT,0) processed
	INTO #tmpAgeCols FROM XTREME_AGEINGDAYS a(NOLOCK)
	JOIN #rep_det b ON b.col_expr='ageing_'+ltrim(rtrim(str(mode)))


	IF @bXnHistory=1
	BEGIN
		SET @cStep='14'
		DELETE FROM #REP_DET_XNTYPES

		INSERT INTO #REP_DET_XNTYPES (rep_id,xn_type) 
		SELECT DISTINCT @cRepId, a.XN_TYPE FROM  transaction_analysis_expr a (NOLOCK)
		JOIN transaction_analysis_MASTER_COLS b (NOLOCK) ON a.xn_type=b.xn_type
		where a.xn_type not in ('Common','Customer Analysis','Buyer Order') AND right(A.xn_type,3) NOT IN ('MTD','YTD')
		AND RIGHT (a.xn_type,4)<>'(OH)' AND rep_type='DETAIL'

		SET @nMode=2
	END
	ELSE
	IF @cXpertRepCode='R1'
	BEGIN
		SET @cStep='14.4'
		INSERT INTO #REP_DET_XNTYPES (rep_id,xn_type)
		SELECT DISTINCT @cRepId rep_id,xn_type FROM  transaction_analysis_calculative_COLS a (NOLOCK)
		JOIN #rep_det b ON a.col_name=b.key_col
		WHERE a.rep_type=@cRepType 

	END


	IF @bXnHistory=0 and (@bYtdColFound=1 OR @bMtdColFound=1)
	BEGIN
		SET @cStep='14.6'
		INSERT INTO #REP_DET_XNTYPES (rep_id,xn_type)
		SELECT @cRepId, xn_type+'_YTD' FROM #rep_det_xntypes
		WHERE @bYtdColFound=1
		UNION ALL
		SELECT @cRepId, xn_type+'_MTD' FROM #rep_det_xntypes
		WHERE @bMtdColFound=1
	END
	
	SET @cStep='16'
	SELECT xn_type as sub_xn_type INTO #repSubXntypes FROM REP_DET_XNTYPES (NOLOCK) WHERE 1=2

	SET @cStep='16.3'
	-- Has to run this Step because APplication is making User to select this Transaction type also which is not required
	DELETE FROM #REP_DET_XNTYPES WHERE  RIGHT (xn_type,4)='(OH)'

	SELECT TOP 1 @cXnType=xn_type FROM #REP_DET_XNTYPES WHERE RIGHT(xn_type,4) not in ('_mtd','_ytd')

	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'
	
	
	--if @@spid=98
	--	select 'check xntypes', * from #REP_DET_XNTYPES

	SELECT * INTO #loc_view from loc_view
	SET @cStep='20'
	print 'Running Step#'+@cStep

	IF @cXpertRepCode<>'R1'
		SET @cMstCols='convert(varchar(100),'''') as xn_type'

	IF @cXpertRepCode<>'R1' AND NOT EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='xn_type')
	BEGIN
			INSERT #rep_det	(row_id,col_order, rep_id,Calculative_col, col_expr, col_header, Dimension, key_col, Mesurement_col ) 
			SELECT newid() row_id,1 col_order,@cRepId rep_id,0 Calculative_col,'xn_type' col_expr,'Transaction type' col_header,
			0 Dimension,'xn_type' key_col,0 Mesurement_col
	END

	SELECT @cMstCols=COALESCE(@cMstCols+',','')+(CASE WHEN datecol=1 THEN 'CONVERT(DATE,'''')' ELSE  
	'CONVERT(VARCHAR(2000),'''')' END)+' as ['+a.col_header+']' FROM 
	(SELECT DISTINCT b.col_header,datecol FROM  transaction_analysis_MASTER_COLS a
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	WHERE (a.xn_type=@cXnType OR @cXpertRepCode='R1') and a.rep_type=@cRepType
	) a

	--if @@spid=1046
	--	select @cXpertRepCode,@cMstCols mstcols_1

	IF @cXpertRepCode<>'R1'
		SELECT @cMstCols=COALESCE(@cMstCols+',','')+(CASE WHEN datecol=1 THEN 'CONVERT(DATE,'''')' ELSE  
		'CONVERT(VARCHAR(2000),'''')' END)+' as ['+b.col_header+']' FROM transaction_analysis_MASTER_COLS a
		JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
		WHERE  a.xn_type='Common' AND CHARINDEX('['+b.col_header+']',ISNULL(@cMstCols,''))=0 and a.rep_type=@cRepType

	--if @@spid=1046
	--	select @cXpertRepCode,@cMstCols mstcols_2

		
	SET @bImageColFound=0
	IF charindex('image',@cMstCols)>0
	BEGIN
		SET @cMstCols=@cMstCols+',CONVERT(VARCHAR(100),'''') AS IMG_ID'
		SET @bImageColFound=1
	END

	
	SELECT @bGstColFoundinSmryRep=0

	SET @cStep='25'
	IF @cXpertRepCode='R3'
	BEGIN
		SELECT TOP 1 @cGstCol=key_col FROM #rep_det WHERE key_col='gst_pct'
		IF ISNULL(@cGstCol,'')<>''
		BEGIN
			SELECT @bGstColFoundinSmryRep=1

			
			INSERT #rep_det	(row_id,col_order, rep_id,Calculative_col, col_expr, col_header, Dimension, key_col, Mesurement_col ) 
			SELECT newid() row_id,a.col_order, a.rep_id,a.Calculative_col,a.col_expr,a.col_header,a.Dimension,a.key_col, a.Mesurement_col
			FROM 
			(
			SELECT @cRepId rep_id,1 Calculative_col,'SUM(ISNULL(a.xn_value_without_gst,0))' col_expr,'Taxable Value' col_header,
			0 Dimension,'taxable_value' key_col,1 Mesurement_col,1 col_order
			UNION ALL
			SELECT @cRepId rep_id,1 Calculative_col,'SUM(a.igst_amount)' col_expr,'IGST Amount' col_header,
			0 Dimension,'igst_amount' key_col,1 Mesurement_col,3 col_order
			UNION ALL
			SELECT @cRepId rep_id,1 Calculative_col,'SUM(a.cgst_amount+a.sgst_amount)' col_expr,'LGST Amount' col_header,
			0 Dimension,'lgst_amount' key_col,1 Mesurement_col,2 col_order
			UNION ALL
			SELECT @cRepId rep_id,1 Calculative_col,'SUM(ISNULL(a.gst_cess_amount,0))' col_expr,'GST Cess Amount' col_header,
			0 Dimension,'gst_cess_amount' key_col,1 Mesurement_col,4 col_order

			) a
			LEFT JOIN #rep_det b ON a.rep_id=b.rep_id AND a.key_col=b.key_col
			WHERE b.rep_id IS NULL

		END
	END

	SET @cStep='30'
	print 'Running Step#'+@cStep
	SELECT @cCalcCols=COALESCE(@cCalcCols+',','')+'CONVERT(NUMERIC(20,2),0) as ['+a.col_header+']' 
	FROM 
	(SELECT DISTINCT b.COL_HEADER FROM transaction_analysis_calculative_COLS a (NOLOCK)
	 JOIN #rep_det b ON a.col_name=b.key_col
	 WHERE (a.xn_type=@cXnType OR @cXpertRepCode='R1')  and a.rep_type=@cRepType) a
	


	SELECT @cCalcCols=COALESCE(@cCalcCols+',','')+'CONVERT(NUMERIC(20,2),0) as ['+b.col_header+']' FROM transaction_analysis_calculative_COLS a
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	left join  transaction_analysis_calculative_COLS c (NOLOCK) ON c.col_name=b.key_col AND c.xn_type=@cXnType AND c.rep_type=@cRepType
	WHERE a.xn_type='Common' AND  a.rep_type=@cRepType
	AND a.col_expr NOT IN ('Payment_Groups','Payment_Modes')
	AND c.col_name IS NULL

	SET @cColNames=@cMstCols+(CASE WHEN @cCalcCols IS NOT NULL THEN  ','+@cCalcCols ELSE '' END)

	--if @@spid=1205
	--	select 'check mstcols',@cXnType xn_type, @cRepType cRepType,@cmStcols mstcols,@cCalcCols calccols,@cXnType xntype,
	--	@cRepType reptype,@bGstColFoundinSmryRep GstColFoundinSmryRep

	SET @cStep='40'
	print 'Running Step#'+@cStep
	SELECT xn_type,CONVERT(VARCHAR(MAX),'') paymode_expr,CONVERT(VARCHAR(2000),'') paymode_updcols,CONVERT(BIT,0) payment_grp_reqd,CONVERT(BIT,0) payment_mode_reqd ,
	CONVERT(BIT,0) data_processed
	INTO #rep_det_paymodes
	FROM REP_DET_XNTYPES (NOLOCK) WHERE rep_id=@cRepId



	IF EXISTS (SELECT TOP 1 * FROM #rep_det WHERE key_col IN  ('Payment_Groups','Payment_Modes'))
	BEGIN

		SET @cStep='45'
		print 'Running Step#'+@cStep

		EXEC SP3S_GET_XPERTREP_PAYMODEEXPR
		@dFromDt=@dFromDt,
		@dToDt=@dToDt,
		@cPaymodeColsStru=@cPaymodeColsStru OUTPUT,
		@cPaymodeColsExpr=@cPaymodeColsExpr OUTPUT

		SET @cColNames=@cColNames+(CASE WHEN @cPaymodeColsStru<>'' THEN  ',CONVERT(VARCHAR(50),'''') memo_id,'+@cPaymodeColsStru ELSE '' END)

	END
	
	IF EXISTS (SELECT TOP 1 * FROM #rep_det WHERE key_col IN  ('OH_Amount','OH_GST'))
		SET @bOhColFoundInDetailRep=1

	IF @bOhColFoundInDetailRep=1
	BEGIN

		SET @cStep='47.6'
		print 'Running Step#'+@cStep+' for getting oh columns'

		EXEC SP3S_GET_XPERTREP_OHColsInfo
		@cRepId=@cRepId,
		@cOhColsStru=@cOhColsStru OUTPUT

		--if @@spid=72
		--	select @cOhColsStru OhColsStru

		SET @cColNames=@cColNames+(CASE WHEN @cOhColsStru<>'' THEN  ','+@cOhColsStru ELSE '' END)

	END

	
	IF @cXpertRepCode='R5' AND CHARINDEX('transaction type',@cColNames)=0
		SET @cColNames=@cColNames+',CONVERT(VARCHAR(200),'''') AS [transaction type]'
	
	IF EXISTS (SELECT TOP 1 col_expr FROM  #rep_det WHERE col_expr IN('ageing_1','ageing_3','ageing_2'))
	BEGIN
		SET @bAgeColsFound=1

		SET @cStep='47.5'
		EXEC SP3S_GETXPERT_AGEINGCOLS 
		@cRepId=@cRepId,
		@cAgeColnames=@cAgeColnames OUTPUT		

		 SET @cColNames=@cColNames+@cAgeColnames
	END

		--if @@spid=94
		--select @cMstCols mstcols,@cCalcCols calccols,@cRepType rep_type,@cXnType xn_type
 

	SET @cColNames=@cColNames+(CASE WHEN @bXnHistory=1 THEN ',CONVERT(NUMERIC(1,0),0) AS xn_mode,CONVERT(VARCHAR(70),'''') AS xn_id' ELSE '' END)
	SET @cStep='50'
	IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col='Transaction_Month_Name')
		SET @cCOlNames=@cCOlNames+',convert(varchar(10),'''') as xn_month_id'

	print 'Running Step#'+@cStep
	SET @cCmd=N'SELECT '+@cColNames+' INTO '+@cTempdb+'['+@cRepTableName+'] WHERE 1=2'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	   
	
	--if @@spid=61
	--	select 'check xntype', XN_TYPE FROM  #REP_DET_XNTYPES

	SELECT * INTO #LoopXntypes FROM  #REP_DET_XNTYPES


	IF @bXnHistory=1
		INSERT INTO #LoopXntypes (rep_id,xn_type)
		SELECT @cRepId rep_id,'Opening Stock'

		--if @@spid=107
		--	select 'pending xntypes',* from #LoopXntypes

	SELECT TOP 1 @cEossSchemeNameCol = col_expr FROM #rep_det WHERE col_expr like '%eoss%'

	WHILE EXISTS (SELECT TOP 1 XN_TYPE FROM  #LoopXntypes)
	BEGIN
		SET @cStep='70'

		--if @@spid=127
		--	select 'pending xntypes',* from #LoopXntypes

		print 'Running Step#'+@cStep
		SELECT TOP 1 @cLoopXntype=xn_type FROM #LoopXntypes

		SELECT @bYtdXntype=0,@bMtdXntype=0,@cXnType=@cLoopXntype
		
		IF RIGHT(@cXntype,4)='_MTD'
			SELECT @bMtdXntype=1,@cXntype=REPLACE(@cLoopXntype,'_MTD','')
		ELSE
		IF RIGHT(@cXntype,4)='_YTD'
			SELECT @bYtdXntype=1,@cXntype=REPLACE(@cLoopXntype,'_YTD','')			
		

		PRINT 'GENERATING DATA FOR Xn type:'+@cXnType		
		DELETE FROM #repSubXntypes

		SET @cStep='80'
		print 'Running Step#'+@cStep

		IF @cXpertRepCode IN ('R1')
			INSERT INTO #repSubXntypes (sub_xn_type)
			SELECT @cXnType
		ELSE
		IF @cXpertRepCode IN ('R2','R5')
			INSERT INTO #repSubXntypes (sub_xn_type)
			SELECT xn_type FROM transaction_analysis_expr (NOLOCK) WHERE group_xn_type=@cXnType
		ELSE
		IF @cXpertRepCode='R3'
			INSERT INTO #repSubXntypes (sub_xn_type)
			SELECT xn_type FROM transaction_summary_expr (NOLOCK) WHERE group_xn_type=@cXnType
		ELSE
		IF @cXpertRepCode='R4'
			INSERT INTO #repSubXntypes (sub_xn_type)
			SELECT xn_type FROM transaction_pending_expr (NOLOCK) WHERE group_xn_type=@cXnType

	

		WHILE EXISTS (SELECT TOP 1 sub_xn_type FROM #repSubXntypes)
		BEGIN
			SET @cStep='90'
			print 'Running Step#'+@cStep
			SELECT TOP 1 @cSubXntype=sub_xn_type FROM #repSubXntypes

			IF @cXpertRepCode IN ('R2','R5')
				SELECT @cBaseExpr=base_expr FROM transaction_analysis_expr (NOLOCK)
				WHERE xn_type=@cSubXntype
			ELSE
			IF @cXpertRepCode IN ('R1')
				SELECT @cBaseExpr=base_expr FROM transaction_analysis_stock_expr (NOLOCK)
				WHERE xn_type=@cSubXntype
			ELSE
			IF @cXpertRepCode='R3'
				SELECT @cBaseExpr=base_expr FROM transaction_summary_expr (NOLOCK)
				WHERE xn_type=@cSubXntype
			ELSE
			IF @cXpertRepCode='R4'
				SELECT @cBaseExpr=base_expr FROM transaction_pending_expr (NOLOCK)
				WHERE xn_type=@cSubXntype
			

			SET @cStep='95'
			print 'Running Step#'+@cStep
			EXEC SP3S_XPERTREPORT_GETCOLSEXPR
			@cRepId=@cRepId,
			@cXnType=@cSubXntype,
			@cRepType=@cRepType,
			@cXpertRepCode=@cXpertRepCode,
			@cInputFilter=@cFilter,
			@cFilterRepId=@cFilterRepId,
			@bMtdXntype=@bMtdXntype,
			@bYtdXntype=@bYtdXntype,
			@cInsCols=@cInsCols OUTPUT,
			@cLayoutCols=@cLayoutCols output,
			@cGrpCols=@cGrpCols output,
			@cJoinStr=@cJoinStr OUTPUT,
			@cOutputFilter=@cOutputFilter OUTPUT,
			@cErrormsg=@cErrormsg OUTPUT
			
			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
			
			--if @@spid=116 and @cSubXntype='Stock Cancellation'
			--	select @cSubXntype sub_xn_type,@cXntype xn_type, @cInsCols,@cLayoutCols,@cGrpCols,@cJoinStr,@cOutputFilter

			SET @cStep='110'

			print 'Running Step#'+@cStep
			SET @cOutputFilter=(CASE WHEN @cOutputFilter='' then '1=1' ELSE @cOutputFilter END)
			
			IF CHARINDEX('bin_id',@cOutputFilter)>0 AND CHARINDEX('a.bin_id',@cOutputFilter)=0
				SET @cOutputFilter=REPLACE(@cOutputFilter,'bin_id','a.bin_id')

			IF CHARINDEX('xn_type',@cOutputFilter)>0
				SET @cJoinStr=@cJoinStr+' JOIN xpert_xntypes (NOLOCK) ON xpert_xntypes.xn_type='''+@cSubXnType+''''

			SET @cPaymodeExpr=''
			SELECT @cPaymodeExpr=paymode_expr,@cUpdPmodeCols=paymode_updcols FROM #rep_det_paymodes 
			WHERE xn_type=@cXnType

			IF CHARINDEX('[opsdt]',@cGrpCols)>0
			BEGIN
				select @cGrpCols=REPLACE(@cGrpCols,'[OPSDT],','')
				select @cGrpCols=REPLACE(@cGrpCols,',[OPSDT]','')
			END

			

			IF ISNULL(@cPaymodeExpr,'')<>''
				SELECT @cInsCols='memo_id,'+@cInsCols,
				@cLayoutCols=(CASE WHEN @cSubXntype='Retail Sale' THEN 'b.cm_id as memo_id,' ELSE 'b.inv_id as memo_id,' END)+@cLayoutCols,
				@cGrpCols=(CASE WHEN @cSubXntype='Retail Sale' THEN 'b.cm_id,' ELSE 'b.inv_id,' END)+@cGrpCols
			
			
			IF @bMtdXnType=1
				SET @dFromDtNew=LTRIM(RTRIM(STR(YEAR(@dToDt))))+'-'+LTRIM(RTRIM(STR(MONTH(@dToDt))))+'-01'		
			ELSE
			IF @bYtdXnType=1
				SET @dFromDtNew=dbo.FN_GETFINYEARDATE('01'+ltrim(rtrim(str(dbo.fn_getfinyear(@dToDt)))),1)
			ELSE
				SET @dFromDtNew=@dFromDt

			IF EXISTS (SELECT TOP 1 COL_EXPR FROM #rep_det WHERE key_col='CBS')
			and EXISTS (SELECT TOP 1 COL_EXPR FROM #rep_det WHERE key_col='OBS')
				SET @bObsCbsColstaken=1


			IF ISNULL(@cEossSchemeNameCol,'')<>'' AND @cXpertRepCode='R1' 
			BEGIN

				EXEC SP3S_PROCESS_EOSSSCHNAMES_XPERT
				@cXnType=@cSubXntype ,	
				@dFromDt=@dFromDt,
				@dToDt=@dToDt,
				@bEossSchDataFetched=@bEossSchDataFetched,
				@cEossSchJoinStr=@cEossSchJoinStr OUTPUT,
				@cErrormsg=@cErrormsg OUTPUT


				IF ISNULL(@cErrormsg,'')<>''
					GOTO END_PROC

				SET @bEossSchDataFetched=1

				SET @cJoinStr=@cJoinStr+' '+@cEossSchJoinStr
							
			END

			IF (@cXpertRepCode='R1' AND @cXntype='STOCK') AND CONVERT(DATE,@dToDt)=CONVERT(DATE,GETDATE()) 
			AND CHARINDEX('cbs_qty',@cLayoutCols)>0 AND @bObsCbsColstaken=0
				SET @cGrpCols=@cGrpCols+' HAVING SUM(quantity_in_stock)<>0'

			SET @cBaseExpr=REPLACE(@cBaseExpr,'[LAYOUT_COLS]',@cLayoutCols)
			SET @cBaseExpr=REPLACE(@cBaseExpr,'[JOIN]',@cJoinStr)
			
			IF @cGrpCols<>''
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[GROUPBY]',@cGrpCols)
			ELSE
				SET @cBaseExpr=REPLACE(@cBaseExpr,'GROUP BY [GROUPBY]','')

			SET @cBaseExpr=REPLACE(@cBaseExpr,'[WHERE]',@cOutputFilter)
			SET @cBaseExpr=REPLACE(@cBaseExpr,'[DFROMDT]',''''+CONVERT(VARCHAR,@dFromDtNew,110)+'''')
			SET @cBaseExpr=REPLACE(@cBaseExpr,'[DTODT]',''''+CONVERT(VARCHAR,@dToDt,110)+'''')
			SET @cBaseExpr=REPLACE(@cBaseExpr,'[DATABASE].','')
			SET @cBaseExpr=REPLACE(@cBaseExpr,'[GHOLOCATION]',''''+@cHoLocId+'''')

			IF @cXpertRepCode='R4' 
			BEGIN
				DECLARE @cDocTableName VARCHAR(100),@cDocTable VARCHAR(100),@cDocExprTable VARCHAR(100)
				SELECT @cDocExprTable = (CASE WHEN CHARINDEX('[GITTABLE]',@cBaseExpr)>0 THEN '[GITTABLE]'
				WHEN CHARINDEX('[WPSTABLE]',@cBaseExpr)>0 THEN '[WPSTABLE]'
				WHEN CHARINDEX('[APPTABLE]',@cBaseExpr)>0 THEN '[APPTABLE]'
				WHEN CHARINDEX('[CNPSTABLE]',@cBaseExpr)>0 THEN '[CNPSTABLE]'
				WHEN CHARINDEX('[DNPSTABLE]',@cBaseExpr)>0 THEN '[DNPSTABLE]'
				WHEN CHARINDEX('[RPSTABLE]',@cBaseExpr)>0 THEN '[RPSTABLE]'
				ELSE '' END),
				@cDocTableName=(CASE WHEN CHARINDEX('[GITTABLE]',@cBaseExpr)>0 THEN 'GITLOCS'
				WHEN CHARINDEX('[WPSTABLE]',@cBaseExpr)>0 THEN 'PENDING_WPS'
				WHEN CHARINDEX('[CNPSTABLE]',@cBaseExpr)>0 THEN 'PENDING_CNPS'
				WHEN CHARINDEX('[DNPSTABLE]',@cBaseExpr)>0 THEN 'PENDING_DNPS'
				WHEN CHARINDEX('[RPSTABLE]',@cBaseExpr)>0 THEN 'PENDING_rps'
				WHEN CHARINDEX('[APPTABLE]',@cBaseExpr)>0 THEN 'PENDING_APPROVALS'ELSE '' END)
								
				SET @cDocTable=DB_NAME()+'_PMT.DBO.'+@cDocTableName+'_'+CONVERT(VARCHAR,@dToDt,112)
				
				IF @cDocExprTable<>''
					SET @cBaseExpr=REPLACE(@cBaseExpr,'dbo.'+@cDocExprTable,@cDocTable)
			END
			ELSE
			IF @cXpertRepCode='R5'
				SET @cBaseExpr=REPLACE(@cBaseExpr,'dbo.[CRM]',DB_NAME()+'_PMT.DBO.customer_crm')

			ELSE
			IF (@cXpertRepCode='R1' AND @cXntype IN ('STOCK','GIT')) OR (@cXpertRepCode='R2' AND @cXntype='Opening Stock')
			BEGIN

				IF EXISTS (SELECT TOP 1 * from #rep_det WHERE key_col='cbs')
					SET @bCbsColInserted=1
				ELSE
					SET @bCbsColInserted=0


				IF EXISTS (SELECT TOP 1 COL_EXPR FROM #rep_det WHERE key_col in ('CBS','OBS'))
				OR (@cXpertRepCode='R2' AND @cXntype='Opening Stock') OR (@cXpertRepCode='R1' AND @cXntype='GIT')
				BEGIN

					IF CONVERT(DATE,@dToDt)=CONVERT(DATE,GETDATE()) AND @bCbsColInserted=1 AND @bObsCbsColstaken=0 AND @cXntype<>'GIT'
						SELECT @cDocTable='pmt01106',@cBaseExpr=REPLACE(@cBaseExpr,'cbs_qty','quantity_in_stock')
					ELSE
						SET @cDocTable=DB_NAME()+'_PMT.DBO.'+(CASE WHEN @cXntype='GIT' THEN 'gitlocs_' ELSE 'pmtlocs_' END)+
						(CASE WHEN @bCbsColInserted=1 AND @bObsCbsColstaken=0 THEN CONVERT(VARCHAR,@dToDt,112)
							  ELSE CONVERT(VARCHAR,@dFromDt-1,112) END)	
					
					SET @cOldBaseExpr=@cBaseExpr

					IF NOT (@cXpertRepCode='R2' AND @cXntype='Opening Stock')
						SET @cBaseExpr=REPLACE(@cBaseExpr,(CASE WHEN  @bCbsColInserted=1 AND @bObsCbsColstaken=1  THEN 'sum(a.cbs_qty) as cbs' 
						ELSE 'sum(a.cbs_qty) as obs'  END),'0')
					ELSE
					BEGIN
						SET @cBaseExpr=REPLACE(@cBaseExpr,'sum(a.quantity)','sum(a.cbs_qty)') 
						SET @cBaseExpr=REPLACE(@cBaseExpr,'[OPSDT]',''''+CONVERT(VARCHAR,@dFromDt,112)+'''') 
					END

					SET @cBaseExpr=REPLACE(@cBaseExpr,'[TABLENAME]',@cDocTable)

				END
			END
				


			SET @cStep='121.2'
			print 'Running Step#'+@cStep
			SET @cCmd=N'INSERT INTO '+@cTempdb+'['+@cRepTableName+'] ('+@cInsCols+')
						SELECT '+@cBaseExpr
			
			--if @@spid=375
			--	select 'check Final Insert statement',@cXpertRepCode cXpertRepCode,@cLoopXnType xn_type, @cInscols inscols,
			--	@cSubXntype subxntype,@cBaseExpr baseexpr,@cLayoutCols layoutcols,
			--	@cJoinStr joinstr,@cGrpCols grpcols,@cCmd cmd
			
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd


			--if @@spid=98
			--SELECT @bCbsColInserted CbsColInserted,@cInsCols
			IF @cXpertRepCode='R1' AND @cXntype='STOCK'
			BEGIN
				SET @cStep='120.5'
				IF @bObsCbsColstaken=1
				BEGIN
					IF CONVERT(DATE,@dToDt)=CONVERT(DATE,GETDATE())
						SELECT @cDocTable='pmt01106'
					ELSE
						SET @cDocTable=DB_NAME()+'_PMT.DBO.pmtlocs_'+CONVERT(VARCHAR,@dToDt,112)

					SET @cBaseExpr=REPLACE(@cOldBaseExpr,'[TABLENAME]',@cDocTable)
					SET @cBaseExpr=REPLACE(@cBaseExpr,'sum(a.cbs_qty) as obs','0')
					

					IF CONVERT(DATE,@dToDt)=CONVERT(DATE,GETDATE())
					BEGIN
						SET @cBaseExpr=@cBaseExpr+' HAVING SUM(quantity_in_stock)<>0'
						SET @cBaseExpr=REPLACE(@cBaseExpr,'cbs_qty','quantity_in_stock')
					END

					SET @cStep='120.71'
					print 'Running Step#'+@cStep
					SET @cCmd=N'INSERT INTO '+@cTempdb+'['+@cRepTableName+'] ('+@cInsCols+')
								SELECT '+@cBaseExpr
					PRINT @cCmd
					EXEC SP_EXECUTESQL @cCmd
				END
			END

			IF ISNULL(@cPaymodeExpr,'')<>''
			begin

				set @cStep='122.5'
				

				SELECT @cBaseExpr=base_expr FROM transaction_summary_expr (NOLOCK)
				WHERE xn_type=@cSubXntype+'_Pay'
						
				print 'Running Step#'+@cStep
				SELECT @cLayoutCols=(CASE WHEN @cSubXntype='Retail Sale' THEN 'b.cm_id as memo_id' ELSE 'b.inv_id as memo_id' END)+','+@cPaymodeExpr,
				@cJOinstr=' JOIN paymode_xn_det px (NOLOCK) ON px.memo_id='+(CASE WHEN @cSubXntype='Retail Sale'
				THEN 'b.cm_id' ELSE 'b.inv_id' END)+' JOIN paymode_mst pm (NOLOCK) ON pm.paymode_code=px.paymode_code',
				@cGrpCols=(CASE WHEN @cSubXntype='Retail Sale'	THEN 'b.cm_id' ELSE 'b.inv_id' END),
				@cOutputFilter= ' px.xn_type='''+(CASE WHEN @cSubXntype='Retail Sale' THEN 'SLS' ELSE 'WSL' END)+''''

				set @cStep='123.2'
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[LAYOUT_COLS]',@cLayoutCols)
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[JOIN]',@cJoinStr)
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[GROUPBY]',@cGrpCols)
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[WHERE]',@cOutputFilter)
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[DFROMDT]',''''+CONVERT(VARCHAR,@dFromDtNew,110)+'''')
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[DTODT]',''''+CONVERT(VARCHAR,@dToDt,110)+'''')
				SET @cBaseExpr=REPLACE(@cBaseExpr,'[DATABASE].','')

			
				set @cStep='123.7'
				SET @cCmd=N'UPDATE a SET '+@cUpdPmodeCols+' FROM '+@cTempdb+'['+@cRepTableName+'] a
							JOIN (SELECT '+@cBaseExpr+') b ON a.memo_id=b.memo_id'
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCmd
			end

			DELETE FROM #repSubXntypes WHERE sub_xn_type=@cSubXntype
		END

		IF @bOhColFoundInDetailRep=1 AND @bXnHistory=0
		BEGIN
			set @cStep='125'
			print 'Running Step#'+@cStep+' for inserting oh data'
			EXEC SP3S_UPDATE_XPERTREP_OHColsData
			@cXntype=@cXnType,
			@cRepId=@cRepid,
			@cRepType=@cRepType,
			@cRepTableName=@cRepTableName,
			@dFromDt=@dFromDt,
			@cTempDb=@cTempDb,
			@dToDt=@dToDt,
			@cXpertRepCode=@cXpertRepCode,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
		END

		DELETE FROM #LoopXntypes WHERE xn_type=@cLoopXntype
	END


	IF @bImageColFound=1
	BEGIN
		set @cStep='127'
		EXEC SP3S_UPDATE_IMAGEINFO_XPERTREP
		@cTempDb=@cTempDb,
		@cTableName=@cRepTableName
	END

	IF @nMode=1
	BEGIN
		
		IF @bAgeColsFound=1
		BEGIN
			SET @cStep='127.6'
			EXEC SP3S_UPDATE_XPERT_AGEINGCOLS 
			@cTempDb=@cTempDb,
			@cRepTableName=@cRepTableName,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
		END

		

		SET @cStep='130'
		print 'Running Step#'+@cStep
		EXEC SP3S_XTREME_REPORTTOTALS
		@cRepId=@cRepId,
		@cReptype=@cRepType,
		@cTempDb=@cTempDb,
		@cTempTable=@cRepTableName,
		@cPaymodeCols=@cPaymodeColsExpr,
		@bCalledFromXPert=1,
		@cAddnlFilter=@cAddnlFilter,
		@cErrormsg=@cXrErrormsg OUTPUT

		IF ISNULL(@cXrErrormsg,'')<>''
			GOTO END_PROC
	END
	ELSE
	BEGIN 
		SET @cStep='140'
		EXEC SP3S_GET_XPERTREP_RAWDATA
		@cTempDb=@cTempDb,
		@cRepTableName=@cRepTableName,
		@bXnHistory=@bXnHistory,
		@cXpertRepCode=@cXpertRepCode,
		@cRepType=@cRepType,
		@cAddnlFilter=@cAddnlFilter,
		@cErrormsg=@cErrormsg OUTPUT
	END
	
	SET @cStep='150'
	SET @cCmd=N'DROP TABLE '+@cTempDb+'['+@cRepTableName+']'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procoedure SP3S_GENXPERT_REPDATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

IF ISNULL(@cXrErrormsg,'')<>''	
	SET @cErrormsg=@cXrErrormsg

IF @cErrormsg<>''
	SELECT @cErrormsg errmsg

END							
