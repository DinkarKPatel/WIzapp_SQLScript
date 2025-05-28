CREATE PROCEDURE SP3S_UPDATE_XPERTREP_OHColsData
@cRepId VARCHAR(50),
@cRepType VARCHAR(200),
@cXntype VARCHAR(200),
@cTempDb VARCHAR(200),
@cRepTableName VARCHAR(300),
@dFromDt datetime,
@dToDt DATETIME,
@cXpertRepCode VARCHAR(5),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN	
	DECLARE @cOhXntype VARCHAR(200),@cBaseExpr VARCHAR(MAX),@cOhColName VARCHAR(200),
	@cStep VARCHAR(5),@cCmd NVARCHAR(MAX),@cOutputFilter VARCHAR(2000),@cInsCols VARCHAR(max),
	@cLayoutCols VARCHAR(2000),@cGrpCols varchar(2000),@cJoinStr VARCHAR(2000),@nMaxMstColOrd NUMERIC(2,0),
	@nMaxCalColOrd NUMERIC(2,0),@cOhColNameSuffix varchar(200)


BEGIN TRY

	SET @cStep='10'
	SET @cErrormsg=''

	SELECT top 1 @cOhXntype=xn_type FROM  transaction_analysis_expr b (NOLOCK)
	WHERE b.oh_parent_xn_type=@cXntype

	DECLARE @tOhColNames TABLE (colname VARCHAR(100))

	SET @cStep='20'
	IF @cXntype IN ('WHOLESALE','DEBIT NOTE','CREDIT NOTE','PURCHASE')
		INSERT INTO @tOhColNames
		SELECT 'FREIGHT'

	IF @cXntype IN ('WHOLESALE','DEBIT NOTE','CREDIT NOTE','PURCHASE','Retail Sale','Retail Sale Return')
		INSERT INTO @tOhColNames
		SELECT 'OTHER_CHARGES'

	IF @cXntype IN ('WHOLESALE','CREDIT NOTE')
		INSERT INTO @tOhColNames
		SELECT 'INSURANCE'

	SELECT * INTO #rep_det_OH FROM #rep_det WHERE 1=2

	
	
	SET @cStep='30'
	WHILE EXISTS (SELECT TOP 1 * FROM @tOhColNames)
	BEGIN
		SELECT @cBaseExpr=base_expr FROM transaction_analysis_expr (NOLOCK)
		WHERE xn_type=@cOhXntype

		SET @cStep='35'
		SELECT TOP 1 @cOhColName=colname FROM @tOhColNames

		DELETE a FROM #rep_det a JOIN #rep_det_oh b ON a.row_id=b.row_id
		
		DELETE FROM #rep_det_oh

		--IF @@spid=270
		--	select 'check oh cols b4 gen inscols', @cOhXntype,@cXntype,@cRepType,@cXpertrepCode
			
		print 'Running OH Step#'+@cStep
		EXEC SP3S_XPERTREPORT_GETCOLSEXPR
		@cRepId=@cRepId,
		@cXnType=@cOhXntype,
		@cRepType=@cRepType,
		@cInputFilter='',
		@cFilterRepId='',
		@cXpertrepCode=@cXpertrepCode,
		@cInsCols=@cInsCols OUTPUT,
		@cLayoutCols=@cLayoutCols output,
		@cGrpCols=@cGrpCols output,
		@cJoinStr=@cJoinStr OUTPUT,
		@cOutputFilter=@cOutputFilter OUTPUT,
		@cErrormsg=@cErrormsg OUTPUT
			
		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
		
		--IF @@spid=72
		--	select 'check oh layout cols-0', @cInsCols inscols,@cLayoutCols layoutcols,@cGrpcols grpcols,@cOhColName OhColName,@cOhXntype ohxntype
			
		SET @cOhColNameSuffix=(CASE WHEN @cGrpCols='' THEN '(b.' ELSE 'SUM(b.' END)+@cOhColName	

		IF @cGrpCols<>''
		BEGIN
			IF CHARINDEX('hsn_code',@cGrpCols)=0
				SET @cGrpCols=@cGrpCols+',b.'+@cOhColName+'_hsn_code'
			ELSE
				SET @cGrpCols=REPLACE(@cGrpCols,'a.hsn_code','b.'+@cOhColName+'_hsn_code')

			IF CHARINDEX('GST_PERCENTAGE',@cGrpCols)=0
				SET @cGrpCols=@cGrpCols+',b.'+@cOhColName+'_GST_PERCENTAGE'
			ELSE
				SET @cGrpCols=REPLACE(@cGrpCols,'a.GST_PERCENTAGE','b.'+@cOhColName+'_GST_PERCENTAGE')			
		END

		SET @cStep='40'

		--if @@spid=72
		--	select 'check LAYOUT before oh ',@cOhXntype xn_type,@cLayOutCols
		
		DECLARE @bHsn BIT,@bGstpct BIT,@bTv BIT,@bIgst BIT,@bCgst BIT,@bSgst BIT

		SELECT @cLayOutCols=@cLayOutCols+','''+@cOhColName+'''',@cInsCols=@cInsCols+',oh_name'

		IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col IN ('HSNSAC_CODE','OH_GST'))  AND CHARINDEX('HSN_CODE',@cLayOutCols)=0
			SELECT @cLayOutCols=@cLayOutCols+',a.HSN_CODE',@cInsCols=@cInsCols+',hsn_code',@bHsn=1

		IF  EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col IN('GST_PCT','OH_GST')) AND CHARINDEX('GST_PERCENTAGE',@cLayOutCols)=0
			SELECT @cLayOutCols=@cLayOutCols+',a.GST_PERCENTAGE',@cInsCols=@cInsCols+',[GST%]',@bGstPct=1

		IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col IN('Taxable_Value','OH_GST'))
			SELECT @cLayOutCols=@cLayOutCols+',[Taxable Value]',@cInsCols=@cInsCols+',[Taxable Value]',@bTV=1

		IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col IN('IGST_AMOUNT','OH_GST'))
			SELECT @cLayOutCols=@cLayOutCols+',[igst amount]',@cInsCols=@cInsCols+',[igst amount]',@bIgst=1

		IF EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col IN('CGST_AMOUNT','OH_GST'))
			SELECT @cLayOutCols=@cLayOutCols+',[cgst amount]',@cInsCols=@cInsCols+',[cgst amount]',@bCgst=1

		IF  EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col IN('SGST_AMOUNT','OH_GST'))
			SELECT @cLayOutCols=@cLayOutCols+',[sgst amount]',@cInsCols=@cInsCols+',[sgst amount]',@bSgst=1
		
		IF  EXISTS (SELECT TOP 1 key_col FROM #rep_det WHERE key_col IN('OH_AMOUNT'))
			SELECT @cLayOutCols=@cLayOutCols+',[OH Amount]',@cInsCols=@cInsCols+',[oh amount]'

		SELECT @nMaxMstColOrd=MAX(col_order) FROM #rep_det WHERE calculative_col=0
		SELECT @nMaxCalColOrd=MAX(col_order) FROM #rep_det WHERE calculative_col=0

		INSERT #rep_det_OH	(row_id,col_order, rep_id,Calculative_col, col_expr, col_header, Dimension, key_col, 
		Mesurement_col,filter_col,grp_total) 
		SELECT newid() row_id,a.col_order, a.rep_id,a.Calculative_col,a.col_expr,a.col_header,a.Dimension,a.key_col, a.Mesurement_col,
		0 filter_col,0 grp_total
		FROM 
		(
		SELECT @cRepId rep_id,0 Calculative_col,'OH_Name' col_expr,'OH Name' col_header,
		0 Dimension,'oh_name' key_col,0 Mesurement_col,@nMaxMstColOrd+1 col_order
		UNION ALL
		SELECT @cRepId rep_id,0 Calculative_col,'hsn_code' col_expr,'HSN/SAC Code' col_header,
		0 Dimension,'hsn_code' key_col,1 Mesurement_col,@nMaxMstColOrd+2 col_order WHERE @bHsn=1
		UNION ALL
		SELECT @cRepId rep_id,0 Calculative_col,'GST%' col_expr,'GST%' col_header,
		0 Dimension,'gst_percentage' key_col,0 Mesurement_col,@nMaxMstColOrd+3 col_order WHERE @bGstPct=1
		UNION ALL
		SELECT @cRepId rep_id,1 Calculative_col,'Taxable Value' col_expr,'Taxable Value' col_header,
		0 Dimension,'taxable_value' key_col,0 Mesurement_col,@nMaxCalColOrd+1 col_order WHERE @bTv=1
		UNION ALL
		SELECT @cRepId rep_id,1 Calculative_col,'IGST Amount' col_expr,'IGST Amount' col_header,
		0 Dimension,'igst_amount' key_col,0 Mesurement_col,@nMaxCalColOrd+2 col_order WHERE @bIgst=1
		UNION ALL
		SELECT @cRepId rep_id,1 Calculative_col,'CGST Amount' col_expr,'CGST Amount' col_header,
		0 Dimension,'cgst_amount' key_col,0 Mesurement_col,@nMaxCalColOrd+3 col_order WHERE @bCgst=1
		UNION ALL
		SELECT @cRepId rep_id,1 Calculative_col,'SGST Amount' col_expr,'SGST Amount' col_header,
		0 Dimension,'sgst_amount' key_col,0 Mesurement_col,@nMaxCalColOrd+4 col_order WHERE @bCgst=1


		) a
		LEFT JOIN #rep_det b ON a.rep_id=b.rep_id AND a.key_col=b.key_col
		WHERE b.rep_id IS NULL		
		
		INSERT #rep_det	(row_id,col_order, rep_id,Calculative_col, col_expr, col_header, Dimension, key_col, Mesurement_col,
		filter_col,grp_total) 
		SELECT row_id,col_order, rep_id,Calculative_col, col_expr, col_header, Dimension, key_col, Mesurement_col ,
		0 filter_col,0 grp_total
		FROM #rep_det_OH

		SET @cStep='50'

		--IF @@spid=72
			--select 'check oh layout cols-1',@nMaxCalColOrd,@nMaxmSTColOrd, @cLayoutCols
	
		SET @cLayOutCols=REPLACE(@cLayOutCols,'[Taxable Value]',@cOhColNameSuffix+'_Taxable_Value)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'SUM(a.xn_value_without_gst)',@cOhColNameSuffix+'_Taxable_Value)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'a.xn_value_without_gst',@cOhColNameSuffix+'_Taxable_Value)')

		SET @cLayOutCols=REPLACE(@cLayOutCols,'[IGST Amount]',@cOhColNameSuffix+'_IGST_AMOUNT)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'a.IGST_Amount',@cOhColNameSuffix+'_IGST_AMOUNT)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'[SGST Amount]',@cOhColNameSuffix+'_SGST_AMOUNT)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'a.SGST_Amount',@cOhColNameSuffix+'_SGST_AMOUNT)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'[CGST Amount]',@cOhColNameSuffix+'_CGST_AMOUNT)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'a.CGST_Amount',@cOhColNameSuffix+'_CGST_AMOUNT)')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'a.HSN_CODE','b.'+@cOhColName+'_hsn_code')

		SET @cLayOutCols=REPLACE(@cLayOutCols,'a.GST_PERCENTAGE','b.'+@cOhColName+'_GST_PERCENTAGE')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'[OH AMOUNT]',(CASE WHEN LEFT(@cXntype,11)<>'Retail Sale' THEN @cOhColNameSuffix+')' 
		ELSE ' sum(atd_charges) ' END))
		SET @cInsCols=REPLACE(@cInsCols,',[OH GST]','')
		SET @cLayOutCols=REPLACE(@cLayOutCols,',OH GST','')
		SET @cLayOutCols=REPLACE(@cLayOutCols,'(OH)','')

		--IF @@spid=72
		--	select 'check oh layout cols-2',@cXntype xn_type,@cInsCols inscols, @cLayoutCols layoutcols

		SET @cStep='60'
		SET @cBaseExpr=REPLACE(@cBaseExpr,'[LAYOUT_COLS]',@cLayoutCols)
		SET @cBaseExpr=REPLACE(@cBaseExpr,'[JOIN]',@cJoinStr)
		SET @cBaseExpr=REPLACE(@cBaseExpr,'[where]',(CASE WHEN  LEFT(@cXntype,11)<>'Retail Sale' THEN  'ISNULL(b.'+@cOhColName+',0)<>0' ELSE ' 1=1 ' END))
		SET @cBaseExpr=REPLACE(@cBaseExpr,'[GROUPBY]',@cGrpCols)

		IF @cGrpCols=''
			SET @cBaseExpr=REPLACE(@cBaseExpr,'GROUP BY','')

		SET @cBaseExpr=REPLACE(@cBaseExpr,'[DFROMDT]',''''+CONVERT(VARCHAR,@dFromDt,110)+'''')
		SET @cBaseExpr=REPLACE(@cBaseExpr,'[DTODT]',''''+CONVERT(VARCHAR,@dToDt,110)+'''')
		SET @cBaseExpr=REPLACE(@cBaseExpr,'[DATABASE].','')


		--if @@spid=72
		--	select 'check before insertion of oh ',@cLayOutCols,@cGrpCols,@cInsCols,@cBaseExpr

		SET @cStep='70'
		print 'Running Oh insertion for :'+@cOhXntype+' agst Step#'+@cStep
		SET @cCmd=N'INSERT INTO '+@cTempDb+'['+@cRepTableName+'] ('+@cInsCols+')
					SELECT '+@cBaseExpr
		PRINT isnull(@cCmd,'null oh cmd')
		EXEC SP_EXECUTESQL @cCmd
		

		DELETE FROM @tOhColNames WHERE colname=@cOhColName
	END		
	
	DELETE FROM  #rep_det WHERE key_col IN  ('OH_GST')

	--select 'check last rep_det',* from #rep_det

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_UPDATE_XPERTREP_OHColsData at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
