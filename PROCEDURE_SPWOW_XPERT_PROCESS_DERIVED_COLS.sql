CREATE PROCEDURE SPWOW_XPERT_PROCESS_DERIVED_COLS
@nMode NUMERIC(1,0),
@cRepTempTable VARCHAR(400)='',
@cErrormsg VARCHAR(MAX) output
AS
BEGIN
	DECLARE @cColHeader VARCHAR(500),@cColExpr varchar(500),@cCmd NVARCHAR(MAX),@cDerivedColumnId VARCHAR(10),
	@cRefColumnId VARCHAR(10),@cReplColHeader VARCHAR(200),@cStoredColHeader VARCHAR(200),@cStep VARCHAR(10),@cXpertRepCode VARCHAR(5)

BEGIN TRY
	SELECT TOP 1 @cXpertRepCode=xpert_rep_code FROM #wow_xpert_rep_mst

	IF @nMode=1
	BEGIN
		set @cStep='10'
		--select 'check derived columns'

		IF EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a 
				    WHERE ISNULL(a.order_by_column_id,'')<>a.column_id AND ISNULL(a.order_by_column_id,'')<>'')
		BEGIN
			set @cStep='14'

			INSERT INTO #wow_xpert_rep_det (rep_id,column_id,col_header,col_expr,xn_type,col_width,dimension,Measurement_col,col_order,calculative_col,order_column)
			SELECT DISTINCT a.rep_id,b.column_id,e.major_col_header col_header,b.col_expr,a.xn_type,0 col_width,0 dimension,0 Measurement_col,0 col_order,0 calculative_col,
			1 order_column
			FROM #wow_xpert_rep_det a 
			JOIN wow_xpert_report_cols_expressions b ON b.column_id=a.order_by_column_id
			JOIN wow_xpert_report_cols_xntypewise d ON d.column_id=b.column_id
			JOIN wow_xpert_report_colheaders e ON e.major_column_id=d.major_column_id
			LEFT JOIN #wow_xpert_rep_det c ON c.column_id=b.column_id AND c.xn_type=a.xn_type
			WHERE ISNULL(a.order_by_column_id,'')<>a.column_id AND ISNULL(a.order_by_column_id,'')<>'' AND c.column_id IS NULL

			--select 'check #wow_xpert_rep_det after order by ',* from #wow_xpert_rep_det
		END
				   
		
		set @cStep='17'
		IF NOT EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a JOIN wow_xpert_report_cols_xntypewise b ON a.xn_type=b.xn_type 
				   AND a.column_id=b.column_id
				   JOIN wow_xpert_report_cols_xntypewise c ON c.ref_column_id=b.column_id)
			AND NOT EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_derivedcols_link b ON b.ref_column_id=a.column_id AND b.xn_type=a.xn_type)
			GOTO END_PROC
		
		--if @@spid=181
		--	SELECT 'CHECK #wow_xpert_rep_det B4 MISSING COLS',* FROM #wow_xpert_rep_det

		set @cStep='20'
		PRINT 'Insert derived columns list-1'

		DECLARE @bLoop BIT 
		
		set @bLoop=0

		WHILE @bLoop=0
		BEGIN
			IF @cXpertRepCode='R1'
			BEGIN
				INSERT INTO #wow_xpert_rep_det (rep_id,column_id,col_header,col_expr,xn_type,col_width,dimension,Measurement_col,col_order,calculative_col)
				SELECT distinct a.rep_id,c.column_id,f.major_col_header col_header,e.col_expr,a.xn_type,0 col_width,0 dimension,0 Measurement_col,0 col_order,1 calculative_col
				FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_report_cols_xntypewise b ON a.xn_type=b.xn_type AND a.column_id=b.column_id
				JOIN wow_xpert_report_cols_xntypewise c ON c.ref_column_id=b.column_id
				JOIN wow_xpert_report_cols_expressions e ON e.column_id=c.column_id
				JOIN wow_xpert_report_colheaders f ON f.major_column_id=c.major_column_id
				LEFT JOIN #wow_xpert_rep_det d ON d.column_id=c.column_id AND d.xn_type=a.xn_type
				WHERE d.column_id IS NULL

				INSERT INTO #wow_xpert_rep_det (rep_id,column_id,col_header,col_expr,xn_type,col_width,dimension,Measurement_col,col_order,calculative_col)
				SELECT distinct a.rep_id,c.column_id,f.major_col_header col_header,e.col_expr,a.xn_type,0 col_width,0 dimension,0 Measurement_col,0 col_order,1 calculative_col
				FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_derivedcols_link b ON b.ref_column_id=a.column_id AND b.xn_type=a.xn_type
				JOIN wow_xpert_report_cols_xntypewise c ON c.xn_type=b.xn_type AND c.column_id=b.column_id
				JOIN wow_xpert_report_cols_expressions e ON e.column_id=c.column_id
				JOIN wow_xpert_report_colheaders f ON f.major_column_id=c.major_column_id
				LEFT JOIN #wow_xpert_rep_det d ON d.column_id=c.column_id AND d.xn_type=a.xn_type
				WHERE d.column_id IS NULL

				IF NOT EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_report_cols_xntypewise b ON a.xn_type=b.xn_type AND a.column_id=b.column_id
				JOIN wow_xpert_report_cols_xntypewise c ON c.ref_column_id=b.column_id
				LEFT JOIN #wow_xpert_rep_det d ON d.column_id=c.column_id AND d.xn_type=a.xn_type
				WHERE d.column_id IS NULL) and 
				NOT EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_derivedcols_link b ON b.ref_column_id=a.column_id AND b.xn_type=a.xn_type
				JOIN wow_xpert_report_cols_xntypewise c ON c.xn_type=b.xn_type AND c.column_id=b.column_id
				JOIN wow_xpert_report_cols_expressions e ON e.column_id=c.column_id
				JOIN wow_xpert_report_colheaders f ON f.major_column_id=c.major_column_id
				LEFT JOIN #wow_xpert_rep_det d ON d.column_id=c.column_id AND d.xn_type=a.xn_type
				WHERE d.column_id IS NULL)
					BREAK
			END
			ELSE
			BEGIN
				INSERT INTO #wow_xpert_rep_det (rep_id,column_id,col_header,col_expr,xn_type,col_width,dimension,Measurement_col,col_order,calculative_col)
				SELECT distinct a.rep_id,isnull(c.column_id,g.column_id),f.major_col_header col_header,e.col_expr,isnull(c.xn_type,g.xn_type) xn_type,0 col_width,0 dimension,0 Measurement_col,0 col_order,1 calculative_col
				FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_report_cols_xntypewise b ON a.xn_type=b.xn_type AND a.column_id=b.column_id
				JOIN wow_xpert_report_cols_xntypewise x ON x.ref_column_id=b.column_id
				left JOIN wow_xpert_report_cols_xntypewise c ON c.ref_column_id=b.column_id and c.xn_type=a.xn_type
				left JOIN wow_xpert_report_cols_xntypewise g ON g.ref_column_id=b.column_id AND g.xn_type<>'STOCK'
				JOIN wow_xpert_report_cols_expressions e ON e.column_id=isnull(c.column_id,g.column_id)
				JOIN wow_xpert_report_colheaders f ON f.major_column_id=isnull(c.major_column_id,g.major_column_id)
				LEFT JOIN #wow_xpert_rep_det d ON d.column_id=isnull(c.column_id,g.column_id) AND d.xn_type=isnull(c.xn_type,g.xn_type)
				WHERE d.column_id IS NULL


				IF NOT EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_report_cols_xntypewise b ON a.xn_type=b.xn_type AND a.column_id=b.column_id
				JOIN wow_xpert_report_cols_xntypewise x ON x.ref_column_id=b.column_id
				left JOIN wow_xpert_report_cols_xntypewise c ON c.ref_column_id=b.column_id and c.xn_type=a.xn_type
				left JOIN wow_xpert_report_cols_xntypewise g ON g.ref_column_id=b.column_id AND g.xn_type<>'STOCK'
				LEFT JOIN #wow_xpert_rep_det d ON d.column_id=isnull(c.column_id,g.column_id) AND d.xn_type=isnull(c.xn_type,g.xn_type)
				WHERE d.column_id IS NULL)
					BREAK

			END

		END

		--if @@spid=96
		--	SELECT 'CHECK #wow_xpert_rep_det after inserting MISSING COLS',* FROM #wow_xpert_rep_det

		set @cStep='30'
		PRINT 'Insert derived columns list-2'
		UPDATE a SET col_expr=replace(a.col_expr,f.major_col_header,c.col_header) FROM #wow_xpert_rep_det a
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id AND a.xn_type=b.xn_type
		JOIN wow_xpert_report_colheaders f ON f.major_column_id=b.major_column_id
		JOIN #wow_xpert_rep_det c ON c.column_id=b.ref_column_id

		--if @@spid=80
		--	SELECT 'CHECK #wow_xpert_rep_det AFTER MISSING COLS',* FROM #wow_xpert_rep_det

		PRINT 'End of Insert derived columns list-1'
	END
	ELSE
	IF @nMode=2
	BEGIN
		--SELECT 'Update #wow_xpert_rep_det from derived cols-1',* from #wow_xpert_rep_det
		set @cStep='40'
		SELECT DISTINCT a.col_header,f.major_col_header col_header_expr,a.column_id,c.column_id ref_column_id INTO #tmpRefColumns
		FROM #wow_xpert_rep_det a
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id AND a.xn_type=b.xn_type
		JOIN wow_xpert_report_colheaders f ON f.major_column_id=b.major_column_id
		JOIN #wow_xpert_rep_det c ON c.column_id=b.ref_column_id

		INSERT INTO #tmpRefColumns (col_header,col_header_expr,column_id,ref_column_id)
		SELECT DISTINCT a.col_header ,f.major_col_header col_header_expr,a.column_id,c.column_id ref_column_id 
		FROM #wow_xpert_rep_det a JOIN wow_xpert_derivedcols_link l (NOLOCK) ON a.column_id=l.column_id
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id AND a.xn_type=b.xn_type
		JOIN wow_xpert_report_colheaders f ON f.major_column_id=b.major_column_id
		JOIN #wow_xpert_rep_det c ON c.column_id=l.ref_column_id	

		--if @@spid=96
		--	select 'check #tmpRefColumns'

		IF NOT EXISTS (SELECT TOP 1 column_id FROM #tmpRefColumns)
			GOTO END_PROC

		--if @@spid=96
		--	select 'check #tmpRefColumns',* from #tmpRefColumns

		set @cStep='50'
		SELECT DISTINCT c.col_expr,c.col_header,c.column_id,convert(numeric(2,0),0) processing_order,convert(bit,0) ordering_marked
		INTO #tmpDerivedCols
		FROM #wow_xpert_rep_det a
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id AND a.xn_type=b.xn_type
		JOIN #wow_xpert_rep_det c ON c.column_id=b.ref_column_id
		UNION
		SELECT DISTINCT c.col_expr,c.col_header,c.column_id,convert(numeric(2,0),0) processing_order,convert(bit,0) ordering_marked
		FROM #wow_xpert_rep_det a
		JOIN wow_xpert_derivedcols_link l (NOLOCK) ON l.column_id=a.column_id and l.xn_type=a.xn_type
		JOIN #wow_xpert_rep_det c ON c.column_id=l.ref_column_id

		--if @@spid=96
		--	select 'check derived cols',* from #tmpDerivedCols
		
		DECLARE @nDerivedCnt INT,@cDerivedColId VARCHAR(10),@nOrderCnt INT
		SELECT @nDerivedCnt=count(*) FROM #tmpDerivedCols

		IF @nDerivedCnt>1
		BEGIN
			SET @nOrderCnt=1
			WHILE EXISTS (SELECT TOP 1 * FROM #tmpDerivedCols where ordering_marked=0)
			BEGIN
				SET @nOrderCnt=@nOrderCnt+1
				SELECT TOP 1  @cDerivedColId=column_id from  #tmpDerivedCols where ordering_marked=0

				UPDATE #tmpDerivedCols SET processing_order=@nOrderCnt where column_id=@cDerivedColId

				SET @cRefColumnId=''
				SELECT TOP 1 @cRefColumnId=ref_column_id from #tmpRefColumns where column_id=@cDerivedColId

				IF @cRefColumnId<>''
				BEGIN
					SET @nOrderCnt=@nOrderCnt+1
					UPDATE #tmpDerivedCols SET processing_order=@nOrderCnt+1 where column_id=@cRefColumnId
				END

				UPDATE #tmpDerivedCols SET ordering_marked=1 where column_id=@cDerivedColId
			END
		END

	--if @@spid=173
	--	begin
	--		select 'check #tmpDerivedCols after reordering',* from  #tmpDerivedCols
	--	end
	

		SET @cRefColumnId=''
		WHILE EXISTS (SELECT TOP 1 * FROM #tmpDerivedCols)
		BEGIN
			set @cStep='60'
			SELECT TOP 1 @cColHeader=col_header,@cDerivedColumnId=column_id FROM #tmpDerivedCols
			ORDER BY processing_order

			WHILE EXISTS (SELECT TOP 1 * FROM #tmpRefColumns where ref_column_id=@cDerivedColumnId)
			BEGIN
				set @cStep='70'
				SELECT TOP 1 @cRefColumnId=column_id,@cReplColHeader=col_header,@cStoredColHeader=col_header_Expr
				FROM #tmpRefColumns where ref_column_id=@cDerivedColumnId

				--if @cDerivedColId='C0673' and @@spid=96
				--	select 'check searched expression for ref column', @cRefColumnId,@cReplColHeader,@cStoredColHeader
				set @cStep='80'
				UPDATE #tmpDerivedCols SET col_expr=REPLACE(col_expr,@cStoredColHeader,'ISNULL(['+@cReplColHeader+'],0)') 
				WHERE column_id=@cDerivedColumnId  

				DELETE FROM #tmpRefColumns WHERE column_id=@cRefColumnId and ref_column_id=@cDerivedColumnId
			END

			SELECT @cColExpr=col_expr FROM #tmpDerivedCols WHERE column_id=@cDerivedColumnId

			set @cStep='90'
			SET @cCmd=N'UPDATE '+@cRepTempTable+' SET ['+@cColHeader+']='+@cColExpr
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd

			DELETE FROM #tmpDerivedCols WHERE col_header=@cColHeader

		END
		--set @cCmd=N'SELECT ''after replacing'',* FROM '+@cRepTempTable+' WHERE [Gross Purchase Quantity]<>0 OR [Gross sALE Quantity]<>0'
		--exec sp_executesql @cCmd

		--if @@spid=93
		--	select 'check #tmpDerivedCols',* from #tmpDerivedCols
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_XPERT_PROCESS_DERIVED_COLS ('+str(@nMode)+') at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH


END_PROC:

END