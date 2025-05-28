CREATE PROCEDURE SPWOW_XPERT_INSERT_MISSINGLOCSDATA
@cInputTable VARCHAR(300),
@cErrormsg varchar(max) output
AS
BEGIN
	DECLARE @cColName VARCHAR(200),@cColExpr VARCHAR(2000),@cCmd NVARCHAR(MAX),@nLoop NUMERIC(3,0),@cInsCols VARCHAR(1000),
	@cJoinCol VARCHAR(100),@cLocJoinCol VARCHAR(100),@cStep varchar(10),@cInsColsExpr VARCHAR(500),@cColHeader VARCHAR(200),
	@cKeyCol VARCHAR(100),@cXpertRepCode VARCHAR(5),@cLocIdColExpr VARCHAR(100)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''


	SELECT TOP 1 @cXpertRepCode=xpert_rep_code FROM #wow_xpert_rep_mst



	SET @cLocIdColExpr=(CASE WHEN @cXpertRepCode='R1' THEN 'SourceLocation.dept_id' ELSE 'LEFT(cmm01106.cm_id,2)' end)
	--if @@spid=1517
	--	select 'check cols',@cLocIdColExpr,* from #wow_xpert_rep_det

	--Transaction Location Id,Transaction Location Name,Transaction Location Alias
	SELECT @cInsCols=COALESCE(@cInsCols+',','')+'['+a.col_header+']' FROM 
	(SELECT DISTINCT a.col_header FROM  #wow_xpert_rep_det a
	WHERE a.xn_type IN ('SLS','STOCK') AND a.col_expr IN (@cLocIdColExpr,'SourceLocation.dept_name','SourceLocation.dept_alias',
	'loc_names.LOCattr8_key_name','loc_names.LOCattr2_key_name','loc_names.LOCattr14_key_name','loc_names.LOCattr17_key_name',
	'loc_names.LOCattr20_key_name')
	) a

	IF ISNULL(@cInsCols,'')=''
		GOTO END_PROC
	
	SELECT DISTINCT a.col_header,A.column_id,COL_EXPR INTO #tmpLocCols FROM  #wow_xpert_rep_det A
	WHERE a.xn_type IN ('SLS','STOCK') AND a.col_expr IN (@cLocIdColExpr,'SourceLocation.dept_name','SourceLocation.dept_alias',
	'loc_names.LOCattr8_key_name','loc_names.LOCattr2_key_name','loc_names.LOCattr14_key_name','loc_names.LOCattr17_key_name',
	'loc_names.LOCattr20_key_name')
	



	SET @cInsColsExpr=@cInsCols

	--IF @@SPID=1517
	--select 'check #tmpLocCols',@cInsColsExpr,@cInsCols,* from #tmpLocCols

	SET @cStep='20'
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpLocCols)
	BEGIN
		SET @cStep='22'
		SELECT TOP 1 @cColHeader=col_header,@cKeyCol=column_id,@cColExpr=col_expr FROM #tmpLocCols

		SET @cStep='24'
		IF @cColExpr=@cLocIdColExpr
			SET @cInsColsExpr=REPLACE(@cInsColsExpr,'['+@cColHeader+']','a.DEPT_ID')
		ELSE
		IF @cColExpr='SourceLocation.dept_name'
			SET @cInsColsExpr=REPLACE(@cInsColsExpr,'['+@cColHeader+']','a.dept_name')
		ELSE
		IF @cColExpr like '%LOCattr%'
			SET @cInsColsExpr=REPLACE(@cInsColsExpr,'['+@cColHeader+']',@cColExpr)
		ELSE			
			SET @cInsColsExpr=REPLACE(@cInsColsExpr,'['+@cColHeader+']','a.DEPT_ALIAS')
		

		
		SET @cStep='26'
		DELETE FROM #tmpLocCols WHERE column_id=@cKeyCol
	END

	SET @cStep='30'
	SELECT TOP 1 @cJoinCol=col_header,@cColExpr=col_expr FROM  #wow_xpert_rep_det a
	WHERE a.xn_type IN ('SLS','STOCK') AND a.col_expr IN (@cLocIdColExpr,'SourceLocation.dept_name','SourceLocation.dept_alias')

	SET @cStep='40'						  	
	SET @cLocJoinCol=(CASE WHEN @cColExpr=@cLocIdColExpr THEN 'dept_id' WHEN @cKeyCol='SourceLocation.dept_name.dept_name'
						   THEN 'dept_name' ELSE 'dept_alias' END)	
	
	--if @@spid=1517
	--	select 'check insert statement of insering missing locs data', @cInputTable,@cInsCols,@cInsColsExpr,@cLocJoinCol,@cJoinCol

	SET @cStep='50'
	SET @cCmd=N'INSERT INTO '+@cInputTable+'('+@cInsCols+',total_mode)
				SELECT '+@cInsColsExpr+',0 FROM location a 
				JOIN loc_names  (NOLOCK) ON loc_names.dept_id=a.dept_id
				LEFT JOIN '+@cInputTable+' b ON a.'+@cLocJoinCol+'=b.['+@cJoinCol+']'+
				' WHERE a.inactive=0 AND b.['+@cJoinCol+'] IS NULL ORDER BY '+@cInsColsExpr
	PRINT isnull(@cCmd,'null insert missing locs expr')
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_XPERT_INSERT_MISSINGLOCSDATA at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:

print 'Last step of insert missing loc data:'+@cStep
END
