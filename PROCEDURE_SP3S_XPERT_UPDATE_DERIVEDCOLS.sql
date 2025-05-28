CREATE PROCEDURE SP3S_XPERT_UPDATE_DERIVEDCOLS
@cRepType VARCHAR(20),
@cInputTable VARCHAR(300),
@cErrormsg varchar(max) output
AS
BEGIN
	DECLARE @cColName VARCHAR(200),@cColExpr VARCHAR(2000),@cCmd NVARCHAR(MAX),@nLoop NUMERIC(3,0),
	@cStep varchar(10),@cLinkedCol VARCHAR(200),@cColHeader VARCHAR(200),@cDerivedColHeader VARCHAR(200)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''

	SELECT DISTINCT a.col_header ,a.key_col colname, c.col_expr INTO #tmpDerivedCols FROM #rep_det  a
	JOIN transaction_analysis_calculative_COLS c on c.col_name=a.key_col and c.rep_type=@cRepType
	WHERE ISNULL(c.multi_column_based,0)=1

	IF NOT EXISTS (SELECT TOP 1 * FROM #tmpDerivedCols)
		GOTO END_PROC

	SELECT linked_col_name INTO #tmpLinkedCols FROM transaction_analysis_derived_COLS_link
	WHERE 1=2

	SET @cStep='20'
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpDerivedCols)
	BEGIN
		SET @cStep='30'
		SELECT TOP 1 @cColName=colname,@cColExpr=col_expr,@cDerivedColHeader=col_header FROM #tmpDerivedCols 
		
		DELETE FROM #tmpLinkedCols

		SET @cStep='40'
		INSERT INTO #tmpLinkedCols (linked_col_name)
		SELECT linked_col_name from transaction_analysis_derived_COLS_link (nolock)
		WHERE rep_type=@cRepType AND col_name=@cColName


		--select @cColName,@cRepType
		--select 'check #tmpLinkedCols', * from #tmpLinkedCols
		WHILE EXISTS (SELECT TOP 1 * from #tmpLinkedCols)
		BEGIN
			SET @cStep='45'
			SELECT TOP 1 @cLinkedCol=linked_col_name FROM #tmpLinkedCols

			SELECT @cColheader=col_header FROM #rep_det WHERE key_col=@cLinkedCol 

			SET @cStep='50'
			SET @cColExpr=REPLACE(@cColExpr,@cLinkedCol,'['+@cColHeader+']')

			DELETE FROM #tmpLinkedCols WHERE linked_col_name=@cLinkedCol

		END

		SET @cStep='60'
		SET @cCmd=N'UPDATE '+@cInputTable+' SET ['+@cDerivedColHeader+']='+@cColExpr
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

lblNext:
		DELETE FROM #tmpDerivedCols WHERE colname=@cColName
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_XPERT_UPDATE_DERIVEDCOLS at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:

END
