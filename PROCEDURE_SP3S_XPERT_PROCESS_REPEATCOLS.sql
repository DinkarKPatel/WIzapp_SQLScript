CREATE PROCEDURE SP3S_XPERT_PROCESS_REPEATCOLS
@cRepType VARCHAR(20),
@cInputTable VARCHAR(300),
@cErrormsg varchar(max) output
AS
BEGIN
	DECLARE @cColName VARCHAR(200),@cColsList VARCHAR(2000),@cCmd NVARCHAR(MAX),@nLoop NUMERIC(3,0),
	@cOldColsList VARCHAR(2000),@cStep varchar(10)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''

	SELECT DISTINCT ISNULL(a.col_header,c.COL_HEADER) colname,a.col_order INTO #tmpRepeatCols FROM #rep_det  a
	LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.rep_type=@cRepType
	WHERE (c.col_expr IS NOT NULL OR Calculative_col=0) AND dimension=0
	and (c.rep_type<>'CAR' OR a.key_col<>'xn_type')

	SET @cStep='20'
	SELECT * INTO #tmpCols FROM #tmpRepeatCols

	SELECT @nLoop=COUNT(*) FROM #tmpRepeatCols

	WHILE @nLoop>1
	BEGIN
		SET @cStep='30'
		SELECT TOP 1 @cColName=colname FROM #tmpCols ORDER BY col_order 

		SET @cColsList=COALESCE(@cColsList+',','')+'['+@cColName+']'

		DELETE FROM #tmpCols WHERE colname=@cColName
		SET @nLoop=@nLoop-1
	END
	
	SET @cStep='40'
	SET @cOldColsList=@cColsList

	WHILE EXISTS (SELECT TOP 1 * FROM #tmpRepeatCols)
	BEGIN
		SET @cStep='50'
		SELECT TOP 1 @cColName=colname FROM #tmpRepeatCols ORDER BY col_order DESC
		
		IF CHARINDEX(@cColName,@cColsList)=0
			GOTO lblNext
		
		SET @cStep='60'
		SET @cCmd=N';WITH cte AS
		(
		  SELECT
			  ROW_NUMBER() OVER(PARTITION BY '+@cColsList+' order by total_mode,org_rowno) AS rno,'+@cColsList+
			  ' FROM '+ @cInputTable+'
		)
		UPDATE cte SET ['+@cColName+']=NULL WHERE rno>1'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='70'
		SET @cColsList=REPLACE(@cColsList,',['+@cColName+']','')
lblNext:
		DELETE FROM #tmpRepeatCols WHERE colname=@cColName
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_XPERT_PROCESS_REPEATCOLS at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
	SET @cCmd=N'SELECT * FROM '+@cInputTable
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'DROP TABLE '+@cInputTable
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END