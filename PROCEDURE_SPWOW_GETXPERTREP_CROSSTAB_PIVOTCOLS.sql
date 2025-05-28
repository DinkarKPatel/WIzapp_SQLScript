CREATE PROCEDURE SPWOW_GETXPERTREP_CROSSTAB_PIVOTCOLS
@cRepTempTable VARCHAR(200),
@cRetPivotExpr VARCHAR(MAX) OUTPUT,
@cRetUnPivotExpr VARCHAR(MAX) OUTPUT,
@cRetInnerCalculativeCols VARCHAR(MAX) OUTPUT,
@cRetOuterCalculativeCols VARCHAR(MAX) OUTPUT,
@cRetGroupingSets VARCHAR(MAX) output,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	print 'Enter SPWOW_GETXPERTREP_CROSSTAB_PIVOTCOLS'
	DECLARE @cCrossPara VARCHAR(200),@cCmd NVARCHAR(MAX),@cStep VARCHAR(5),@cPivotCols VARCHAR(MAX),
	@cUnPivotCols VARCHAR(MAX),@cXntype VARCHAR(200),@cXtabColsList NVARCHAR(MAX),@cOrderbyColumn VARCHAR(200)

BEGIN TRY

	SET @cStep='10'
		
	SELECT TOP 1 @cCrossPara='['+a.col_header+']',@cOrderbyColumn=b.col_header FROM #wow_xpert_rep_det a
	LEFT JOIN #wow_xpert_rep_det b ON a.order_by_column_id=b.column_id
	WHERE a.DIMENSION=1

	IF ISNULL(@cOrderbyColumn,'')=''
		SET @cOrderbyColumn=@cCrossPara

	SET @cStep='15'
	UPDATE #wow_xpert_rep_det SET measurement_col=1,unpivot_xtab_col_header=replicate('0',2-len(ltrim(rtrim(str(col_order)))))+ltrim(rtrim(str(col_order)))+
	col_header WHERE 	Calculative_col=1

	SET @cStep='20'
	CREATE TABLE #tmpPivotCols (xtabcol_val VARCHAR(300),order_by_column VARCHAR(200))

	SET @cOrderbyColumn=(CASE WHEN LEFT(@cOrderbyColumn,1)<>'[' THEN '['+@cOrderbyColumn+']' ELSE @cOrderbyColumn END)

	SET @cCmd=N'SELECT DISTINCT ISNULL(A.' + @CCROSSPARA + ','''') AS xtabcol_val,'+@cOrderbyColumn+' xtabcol_order
				FROM ' + @cRepTempTable + ' A  WHERE ISNULL(A.' + @CCROSSPARA + ','''')<>'''' ORDER BY '+@cOrderbyColumn
	
	PRINT @cCmd
	INSERT INTO #tmpPivotCols (xtabcol_val,order_by_column)
	EXEC SP_EXECUTESQL @cCmd

	;WITH cteDup as
	(SELECT xtabcol_val,ROW_NUMBER() OVER (PARTITION BY xtabcol_val order by xtabcol_val) rno from #tmpPivotCols)

	DELETE FROM cteDup WHERE rno>1
	 
	SET @cStep='30'
	SELECT @cPivotCols=COALESCE(@cPivotCols+',','')+quotename(xtabcol_val) FROM #tmpPivotCols
	SET @cRetPivotExpr=' pivot (sum(total_value) for '+@cCrossPara+' IN ('+@cPivotCols+')) p'
	
	SELECT @cRetOuterCalculativeCols=COALESCE(@cRetOuterCalculativeCols+',','')+'SUM('+quotename(xtabcol_val)+') AS '+quotename(xtabcol_val) 
	FROM #tmpPivotCols


	--if @@spid=234
	--	select 'check measure columns for vertical xtab',* from #wow_xpert_rep_det

    --- Needed to put the condition of col_width>0 because Sls and Slr qty column values coming unnecessarily if user selects the Net sls qty
	SELECT DISTINCT col_header,col_order,unpivot_xtab_col_header into #tMeasureCols FROM #wow_xpert_rep_det WHERE measurement_col=1 AND col_width>0 
	ORDER BY col_order

	SELECT @cRetInnerCalculativeCols=COALESCE(@cRetInnerCalculativeCols+',','')+'SUM('+quotename(col_header)+') AS '+
	quotename(unpivot_xtab_col_header) 
	FROM #tMeasureCols


	SELECT @cUnPivotCols=COALESCE(@cUnPivotCols+',','')+quotename(unpivot_xtab_col_header) 
	FROM #tMeasureCols

	SET @cRetUnPivotExpr=' UNPIVOT ( total_value FOR xtab_col_name  IN ('+@cUnPivotCols+')) u ) b '
	
	SELECT @cRetGroupingSets=COALESCE(@cRetGroupingSets+',','') +'['+a.col_header+']' 
	FROM 
	(SELECT DISTINCT col_header FROM #wow_xpert_rep_det a
	 WHERE Calculative_col=0 AND  Dimension=0 AND order_column=0) a


	 SET @cXtabColsList='Details,'+Replace(@cPivotCols,'[ZZZTotal]','[ZZZTotal] as Total')

	 UPDATE #wow_xpert_rep_mst SET xtab_cols_list=@cXtabColsList

END TRY
BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_GETXPERTREP_CROSSTAB_PIVOTCOLS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	 --SELECT 'check final pivot columns', @cRetPivotExpr ,@cRetUnPivotExpr,@cRetOuterCalculativeCols,@cRetGroupingSets,
	 --@cXtabColsList
END
