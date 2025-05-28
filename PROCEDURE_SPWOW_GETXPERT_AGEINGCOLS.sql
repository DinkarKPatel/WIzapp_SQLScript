CREATE PROCEDURE SPWOW_GETXPERT_AGEINGCOLS	
@cRepId VARCHAR(40),
@cXpertRepCode VARCHAR(5),
@cErrormsg VARCHAR(MAX) output,
@cAgeColNames VARCHAR(300) OUTPUT
AS
BEGIN
	DECLARE @cXntype VARCHAR(10),@nStep VARCHAR(5)

	SET @cErrormsg=''
BEGIN TRY
	SET @nStep='10'
	SET @cXntype=(CASE WHEN @cXpertRepCode='R1' THEN 'Stock' ELSE 'SLS' END)



	SELECT * INTO #wow_xpert_rep_det_old FROM #wow_xpert_rep_det 

	--if @@spid=60
	--	select 'check #wow_xpert_rep_det before inserting ageing',* from #wow_xpert_rep_det

	SET @nStep='15'
	INSERT #wow_xpert_rep_det	(rep_id,row_id,col_order, Calculative_col, col_expr, col_header, Dimension, column_id, 
	Measurement_col,xn_type,col_width ) 
	SELECT @cRepId rep_id, newid() row_id,a.col_order, a.Calculative_col,a.col_expr,a.col_header,a.Dimension,a.column_id, 
	a.Measurement_col,@cXntype xn_type,0 col_width
	FROM 
	(							
	SELECT TOP 1 1 Calculative_col, col_expr,d.major_col_header col_header,0 Dimension,a.column_id,0 Measurement_col,1 col_order
	FROM WOW_xpert_report_cols_xntypewise a
	JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
	JOIN wow_xpert_report_colheaders d on d.major_column_id=a.major_column_id
	JOIN #wow_xpert_rep_mst c ON 1=1
	WHERE b.column_id='C1164' AND ISNULL(c.show_pur_ageing_xtab_slabwise,0)=1
	UNION ALL
	SELECT TOP 1  1 Calculative_col,'ageing_1' col_expr,'ageing_1' col_header,0 Dimension,'ageing_1' column_id,0 Measurement_col,1 col_order
	FROM #wow_xpert_rep_mst c 
	WHERE ISNULL(show_pur_ageing_xtab_slabwise,0)=1
	UNION ALL
	SELECT TOP 1 1 Calculative_col,col_expr,d.major_col_header col_header,0 Dimension,a.column_id,0 Measurement_col,1 col_order
	FROM WOW_xpert_report_cols_xntypewise a
	JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
	JOIN wow_xpert_report_colheaders d on d.major_column_id=a.major_column_id
	JOIN #wow_xpert_rep_mst c ON 1=1
	WHERE b.column_id='C1165' AND ISNULL(c.show_shelf_ageing_xtab_slabwise,0)=1
	UNION ALL
	SELECT TOP 1  1 Calculative_col,'ageing_3' col_expr,'ageing_3' col_header,0 Dimension,'ageing_3' column_id,0 Measurement_col,1 col_order
	FROM #wow_xpert_rep_mst c 
	WHERE ISNULL(show_shelf_ageing_xtab_slabwise,0)=1
	UNION ALL
	SELECT TOP 1 1 Calculative_col,col_expr,d.major_col_header col_header,0 Dimension,a.column_id,0 Measurement_col,1 col_order
	FROM WOW_xpert_report_cols_xntypewise a
	JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
	JOIN wow_xpert_report_colheaders d on d.major_column_id=a.major_column_id
	JOIN #wow_xpert_rep_mst c ON 1=1
	WHERE b.col_expr='avg(cmd01106.selling_days)' AND ISNULL(c.show_sale_ageing_xtab_slabwise,0)=1
	UNION ALL
	SELECT TOP 1  1 Calculative_col,'ageing_2' col_expr,'ageing_2' col_header,0 Dimension,'ageing_2' column_id,0 Measurement_col,1 col_order
	FROM #wow_xpert_rep_mst c 
	WHERE ISNULL(show_sale_ageing_xtab_slabwise,0)=1
	) a
	LEFT JOIN #wow_xpert_rep_det b ON  a.column_id=b.column_id
	WHERE b.rep_id IS NULL

	SET @cAgeColNames=''
	IF EXISTS (SELECT TOP 1 rep_id FROM  #wow_xpert_rep_mst WHERE ISNULL(show_pur_ageing_xtab_slabwise,0)=1)
	BEGIN
		SET @nStep='20'
		SET @cAgeColNames=@cAgeColNames+',CONVERT(VARCHAR(100),'''') ageing_1'
		IF NOT EXISTS (SELECT TOP 1 col_expr FROM  #wow_xpert_rep_det_old WHERE column_id='C1164')
			SET @cAgeColNames=@cAgeColNames+',CONVERT(NUMERIC(10,0),0) AS [purchase ageing days]'

		UPDATE #wow_xpert_rep_det SET col_expr=replace(col_expr,'avg(','(') where column_id='C1164'
	END
	
	SET @nStep='30'
	IF EXISTS (SELECT TOP 1 rep_id FROM  #wow_xpert_rep_mst WHERE ISNULL(show_shelf_ageing_xtab_slabwise,0)=1)
	BEGIN
		SET @nStep='35'
		SET @cAgeColNames=@cAgeColNames+',CONVERT(VARCHAR(100),'''') ageing_3'
		IF NOT EXISTS (SELECT TOP 1 col_expr FROM  #wow_xpert_rep_det_old WHERE column_id='C1165')
			SET @cAgeColNames=@cAgeColNames+',CONVERT(NUMERIC(10,0),0) AS [shelf ageing Days]'

		UPDATE #wow_xpert_rep_det SET col_expr=replace(col_expr,'avg(','(') where column_id='C1165'
	END

	SET @nStep='40'
	IF EXISTS (SELECT TOP 1 rep_id FROM  #wow_xpert_rep_mst WHERE ISNULL(show_sale_ageing_xtab_slabwise,0)=1)
	BEGIN
		SET @nStep='45'
		SET @cAgeColNames=@cAgeColNames+',CONVERT(VARCHAR(100),'''') ageing_2'
		IF NOT EXISTS (SELECT TOP 1 col_expr FROM  #wow_xpert_rep_det_old WHERE col_expr='avg(cmd01106.selling_days)')
			SET @cAgeColNames=@cAgeColNames+',CONVERT(NUMERIC(10,0),0) AS [Sale ageing days]'

		UPDATE #wow_xpert_rep_det SET col_expr='cmd01106.selling_days' where col_expr='avg(cmd01106.selling_days)'
	END

	SET @nStep='60'
	print 'Mark dimension column'

	UPDATE a SET dimension=1 FROM #wow_xpert_rep_det a
	JOIN #wow_xpert_rep_det b ON a.rep_id=b.rep_id
	WHERE a.col_expr IN ('ageing_1','ageing_2','ageing_3')

	SET @nStep='70'
	print 'Mark Measure column'
	UPDATE a SET Measurement_col=1 FROM #wow_xpert_rep_det a
	JOIN #wow_xpert_rep_det b ON a.rep_id=b.rep_id
	WHERE (b.col_expr='ageing_1' AND (a.col_expr in ('sum(pmt_cbs.cbs_qty)') OR a.column_id='C1164')) OR 
	(b.col_expr='ageing_3' AND (a.col_expr in ('sum(pmt_cbs.cbs_qty)') or a.column_id='C1165'))  OR 
	(b.col_expr='ageing_2' AND a.col_expr in ('cmd01106.selling_days','sum(cmd01106.quantity)'))

	--if @@spid=178
	--	select 'check #wow_xpert_rep_det after dimention and measure mark for ageing',* from #wow_xpert_rep_det

	UPDATE #wow_xpert_rep_mst set CrossTab_Type=1
	
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_GETXPERT_AGEINGCOLS at Step#'+@nStep+' '+ERROR_MESSAGE()

END CATCH

END