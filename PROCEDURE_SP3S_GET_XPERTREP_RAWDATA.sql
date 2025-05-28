CREATE PROCEDURE SP3S_GET_XPERTREP_RAWDATA
@cTempDb VARCHAR(200),
@cRepTableName VARCHAR(200),
@bXnHistory BIT,
@cXpertRepCode VARCHAR(10),
@cRepType VARCHAR(200),
@cAddnlFilter VARCHAR(MAX),
@cErrormsg VARCHAR(500) OUTPUT
AS
BEGIN
	DECLARE @cJoinstr VARCHAR(MAX),@cStep VARCHAR(4),@cMstCols VARCHAR(MAX),@cCalcCols VARCHAR(MAX),@cXntype VARCHAR(300),@cOrderCols VARCHAR(MAX),
	@cColNames VARCHAR(MAX),@cCmd NVARCHAR(MAX)
	
BEGIN TRY
	print 'Enter Raw data procedure'

	SELECT @cJoinStr='',@cErrormsg=''

	SET @cStep='135'
	print 'Running Step#'+@cStep

	IF @cXpertRepCode<>'R1'
		SELECT @cMstCols='[TRANSACTION TYPE] as xn_type'
	ELSE
		SET @cMstCols=NULL

	SET @cCalcCols=NULL
	SELECT TOP 1 @cXntype=xn_type FROM #REP_DET_XNTYPES 
	
	IF @bXnHistory=1
	BEGIN
		select @cOrderCols='[Transaction Location Id],[Transaction Date],[Transaction No.],[Transaction Location Bin]'
	END
	ELSE
	BEGIN
		
		IF @cXpertRepCode<>'R1'
			select @cOrderCols='[TRANSACTION TYPE]'
		ELSE
			SET @cXntype='Stock'
		
		SELECT @cOrderCols=COALESCE(@cOrderCols+',','')+'['+a.col_header+']' FROM transaction_analysis_MASTER_COLS a
		JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
		WHERE  a.xn_type=@cXnType and a.col_name<>'xn_type' AND a.rep_type=@cRepType
		ORDER BY b.col_order		

		SELECT @cOrderCols=COALESCE(@cOrderCols+',','')+'['+a.col_header+']' FROM transaction_analysis_MASTER_COLS a
		JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
		WHERE  a.xn_type='Common' and a.col_name<>'xn_type' AND a.rep_type=@cRepType
		AND CHARINDEX(a.col_header,ISNULL(@cOrderCols,''))=0
		ORDER BY b.col_order
	END

	SET @cStep='140'
	
	SELECT b.col_order,CONVERT(BIT,0) calc_col,a.datecol,a.col_header exp_col_header,b.col_header user_col_header,b.key_col
	INTO #cols_list FROM transaction_analysis_MASTER_COLS a
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	WHERE  a.xn_type=@cXnType  AND a.rep_type=@cRepType

	SET @cStep='142'
	INSERT INTO #cols_list (col_order,calc_col,datecol,exp_col_header,user_col_header,key_col)
	SELECT b.col_order,0 calc_col,a.datecol,a.col_header exp_col_header,b.col_header user_col_header,b.key_col
	FROM transaction_analysis_MASTER_COLS a (NOLOCK)
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	LEFT JOIN #cols_list c on c.user_col_header=b.col_header
	WHERE  a.xn_type='Common' and a.col_name<>'xn_type' AND a.rep_type=@cRepType
	AND c.user_col_header IS NULL

	SET @cStep='145'
	print 'Running Step#'+@cStep
	INSERT INTO #cols_list (col_order,calc_col,datecol,exp_col_header,user_col_header,key_col)
	SELECT b.col_order,1 calc_col,0 datecol,a.col_header exp_col_header,b.col_header user_col_header ,b.key_col FROM transaction_analysis_calculative_COLS a
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	WHERE a.xn_type=@cXnType AND a.rep_type=@cRepType
	
	--if @@spid=113
	--	select 'check colslist',@cXnType xn_type,* from #cols_list

	SET @cStep='147'
	INSERT INTO #cols_list (col_order,calc_col,datecol,exp_col_header,user_col_header,key_col)
	SELECT b.col_order,1 calc_col,0 datecol,a.col_header exp_col_header,b.col_header user_col_header ,b.key_col
	FROM transaction_analysis_calculative_COLS a
	JOIN #rep_det b (NOLOCK) ON a.col_name=b.key_col
	left join  transaction_analysis_calculative_COLS c (NOLOCK) ON c.col_name=b.key_col AND c.xn_type=@cXnType AND c.rep_type=@cRepType
	LEFT JOIN #cols_list d on d.user_col_header=b.col_header
	WHERE a.xn_type='Common' AND  a.rep_type=@cRepType
	AND a.col_expr NOT IN ('Payment_Groups','Payment_Modes')
	AND c.col_name IS NULL AND d.user_col_header IS NULL


	IF  @cXpertRepCode<>'R1'
		SET @cColNames='[Transaction type]'

		
	IF @bXnHistory=1
	BEGIN
		SELECT * INTO #final_cols_list_1 FROM #cols_list ORDER BY col_order

		SELECT @cColNames=COALESCE(@cColNames+',','')+(CASE WHEN datecol=1 THEN 'CONVERT(VARCHAR,' ELSE  '' END)+
		'['+a.exp_col_header+']'+(CASE WHEN datecol=1 THEN ',105)' else '' end)+' as ['+
		(CASE WHEN datecol=1 THEN REPLACE(a.user_col_header,' ','_') ELSE a.user_col_header END)+']'
		FROM #final_cols_list_1 a


		SET @cColNames=@cColNames+',xn_mode,xn_id'
	END
	ELSE
	BEGIN
		SELECT * INTO #final_cols_list_2 FROM #cols_list ORDER BY calc_col,col_order

		print 'Enter export to excel report rawdata'
		SELECT @cColNames=COALESCE(@cColNames+',','')+(CASE WHEN datecol=1 THEN 'CONVERT(VARCHAR,' ELSE  '' END)+
		'['+a.exp_col_header+']'+(CASE WHEN datecol=1 THEN ',105)' else '' end)+' as ['+
		(CASE WHEN datecol=1 THEN REPLACE(a.key_col,' ','_') ELSE a.key_col END)+']'
		FROM #final_cols_list_2 a
	END

	IF EXISTS (SELECT TOP 1 * FROM #rep_det WHERE key_col like '%para2%' and dimension=1)
		SELECT @cOrderCols=replace(@cOrderCols,'[Para2 name]','Para2_Order'),
		@cJoinStr= ' LEFT JOIN para2 b ON b.para2_name=a.[Para2 name]',
		@cMstCols=@cMstCols+',para2_order'

	--if @@spid=66
	--select @cMstCols,@cCalcCols,@cRepType,@cXnType


	IF charindex('image',@cColNames)>0
		SET @cColNames=@cColNames+',img_id'

	SET @cStep='150'
	print 'Running Step#'+@cStep
	SET @cCmd=N'SELECT '+@cColNames+' FROM '+@cTempDb+'['+@cRepTableName+'] a '+@cJoinStr+
	(CASE WHEN @cAddnlFilter<>'' THEN ' WHERE '+@cAddnlFilter ELSE '' END)+' ORDER BY '+@cOrderCols
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GET_XPERTREP_RAWDATA at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:

END