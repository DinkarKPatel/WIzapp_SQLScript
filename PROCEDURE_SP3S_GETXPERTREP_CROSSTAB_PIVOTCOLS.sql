CREATE PROCEDURE SP3S_GETXPERTREP_CROSSTAB_PIVOTCOLS
@cTempDb VARCHAR(200),
@CTABLENAME VARCHAR(200),
@cRepType VARCHAR(20),
@cXpertRepCode VARCHAR(10),
@cRetPivotExpr VARCHAR(MAX) OUTPUT,
@cRetUnPivotExpr VARCHAR(MAX) OUTPUT,
@cRetCalculativeCols VARCHAR(MAX) OUTPUT,
@cRetGroupingSets VARCHAR(MAX) output,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCrossPara VARCHAR(200),@bSizeXtab BIT,@cCmd NVARCHAR(MAX),@cStep VARCHAR(5),@cPivotCols VARCHAR(MAX),
	@cUnPivotCols VARCHAR(MAX),@cXntype VARCHAR(200)

	SET @cStep='10'
	SET @bSizeXtab=0
	
	
	SELECT TOP 1 @cXntype=xn_type FROM REP_DET_XNTYPES a (NOLOCK)
	JOIN #rep_det b ON a.rep_id=b.rep_id

	IF @cXpertRepCode='R1'
		SELECT TOP 1 @cCrossPara='['+ISNULL(b.col_header,a.col_header)+']' FROM #rep_det a
		LEFT JOIN transaction_analysis_MASTER_COLS b ON a.key_col=b.col_name and b.rep_type=@cRepType
		WHERE DIMENSION=1
	ELSE
		SELECT TOP 1 @cCrossPara='['+ISNULL(b.col_header,a.col_header)+']' FROM #rep_det a
		LEFT JOIN transaction_analysis_MASTER_COLS b ON a.key_col=b.col_name and b.xn_type IN (@cXnType,'COMMON') AND b.rep_type=@cRepType
		WHERE DIMENSION=1

	SET @cStep='15'
	IF CHARINDEX('para2',@cCrossPara)>0
		SET @bSizeXtab=1

	IF @cXpertRepCode='R1'
		select @cRetCalculativeCols=COALESCE(@cRetCalculativeCols+',','') +'SUM(['+COALESCE(b.col_header,a.col_header)+
		']) AS ['+COALESCE(b.col_header,a.col_header)+']' 
		FROM #rep_det a
		LEFT JOIN 
		(SELECT DISTINCT col_header,col_name FROM transaction_analysis_calculative_COLS b (NOLOCK)
		 WHERE b.rep_type=@cRepType) b on b.col_name=a.key_col  
		WHERE Calculative_col=1 AND Mesurement_col=0
	ELSE
		select @cRetCalculativeCols=COALESCE(@cRetCalculativeCols+',','') +'SUM(['+COALESCE(b.col_header,a.key_col)+']) 
		AS ['+COALESCE(b.col_header,a.col_header)+']' 
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.xn_type IN (@cXnType,'COMMON') AND b.rep_type=@cRepType
		WHERE Calculative_col=1 AND Mesurement_col=0
	
	SET @cStep='20'
	CREATE TABLE #tmpPivotCols (xtabcol_val VARCHAR(300),xtabcol_order NUMERIC(10,2))

	SET @cCmd=N'SELECT DISTINCT ISNULL(A.' + @CCROSSPARA + ','''') AS xtabcol_val,'+
					  (CASE WHEN @bSizeXtab=1 THEN 'isnull(b.para2_order,0) AS xtabcol_order' ELSE '0 as xtabcol_order' END)+'
				FROM '+@cTempDb+'[' + @CTABLENAME + '] A '+(CASE WHEN @bSizeXtab=1 THEN  'LEFT JOIN para2 b ON b.para2_name=a.'+@cCrossPara ELSE '' END)+'
				WHERE ISNULL(A.' + @CCROSSPARA + ','''')<>'''''
	
	INSERT INTO #tmpPivotCols (xtabcol_val,xtabcol_order)
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='30'
	SELECT @cPivotCols=COALESCE(@cPivotCols+',','')+quotename(xtabcol_val) FROM #tmpPivotCols
	SET @cRetPivotExpr=' pivot (sum(total_value) for '+@cCrossPara+' IN ('+@cPivotCols+')) p'

	SELECT @cRetCalculativeCols=@cRetCalculativeCols+',SUM('+quotename(xtabcol_val)+') AS '+quotename(xtabcol_val) FROM #tmpPivotCols

	SELECT @cUnPivotCols=COALESCE(@cUnPivotCols+',','')+quotename(col_header) FROM #rep_det WHERE Mesurement_col=1
	SET @cRetUnPivotExpr=' UNPIVOT ( total_value FOR xtab_col_name  IN ('+@cUnPivotCols+')) u ) b '
	
	IF @cXpertRepCode='R1'
		SELECT @cRetGroupingSets=COALESCE(@cRetGroupingSets+',','') +'['+COALESCE(b.col_header,c.col_header,a.COL_EXPR)+']' 
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.rep_type=@cRepType
		LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.rep_type=@cRepType
		WHERE Calculative_col=0 AND filter_col=0 AND Dimension=0
	ELSE
		SELECT @cRetGroupingSets=COALESCE(@cRetGroupingSets+',','') +'['+COALESCE(b.col_header,c.col_header,a.COL_EXPR)+']' 
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.xn_type IN (@cXnType,'COMMON') and b.rep_type=@cRepType
		LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.xn_type IN (@cXnType,'COMMON') and b.rep_type=@cRepType
		WHERE Calculative_col=0 AND filter_col=0 AND Dimension=0
END