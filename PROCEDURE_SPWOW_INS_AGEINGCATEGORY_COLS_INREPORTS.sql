CREATE PROCEDURE SPWOW_INS_AGEINGCATEGORY_COLS_INREPORTS
AS
BEGIN
	SELECT a.rep_id, newid() row_id,0 col_order,h.major_col_header col_header,
	1 Dimension, b.column_id, 0 Measurement_col,'Stock' xn_type,0 col_width into #tmpAgeingNewCols from wow_xpert_rep_mst a (NOLOCK)
	JOIN wow_xpert_report_cols_expressions b (NOLOCK) ON b.column_id='ageing_1'
	JOIN wow_xpert_report_cols_xntypewise c (NOLOCK) ON c.column_id=b.column_id and c.xn_type='STOCK'
	join wow_xpert_report_colheaders h (NOLOCK) ON h.major_column_id=c.major_column_id
	LEFT JOIN wow_xpert_rep_det d (NOLOCK) ON d.column_id=b.column_id and d.rep_id=a.rep_id
	where a.xpert_REP_CODE='R1' and a.show_pur_ageing_xtab_slabwise=1 and d.column_id is null

	union all
	SELECT a.rep_id, newid() row_id,0 col_order,h.major_col_header col_header,
	1 Dimension, b.column_id, 0 Measurement_col,'Stock' xn_type,0 col_width from wow_xpert_rep_mst a (NOLOCK)
	JOIN wow_xpert_report_cols_expressions b (NOLOCK) ON b.column_id ='ageing_2'
	JOIN wow_xpert_report_cols_xntypewise c (NOLOCK) ON c.column_id=b.column_id and c.xn_type='STOCK'
	join wow_xpert_report_colheaders h (NOLOCK) ON h.major_column_id=c.major_column_id
	LEFT JOIN wow_xpert_rep_det d (NOLOCK) ON d.column_id=b.column_id and d.rep_id=a.rep_id
	where a.xpert_REP_CODE='R1' and a.show_sale_ageing_xtab_slabwise=1 and d.column_id is null

	union all
	SELECT a.rep_id, newid() row_id,0 col_order,h.major_col_header col_header,
	1 Dimension, b.column_id, 0 Measurement_col,'Stock' xn_type,0 col_width from wow_xpert_rep_mst a (NOLOCK)
	JOIN wow_xpert_report_cols_expressions b (NOLOCK) ON b.column_id ='ageing_3'
	JOIN wow_xpert_report_cols_xntypewise c (NOLOCK) ON c.column_id=b.column_id and c.xn_type='STOCK'
	join wow_xpert_report_colheaders h (NOLOCK) ON h.major_column_id=c.major_column_id
	LEFT JOIN wow_xpert_rep_det d (NOLOCK) ON d.column_id=b.column_id and d.rep_id=a.rep_id
	where a.xpert_REP_CODE='R1' and a.show_shelf_ageing_xtab_slabwise=1 and d.column_id is null
	order by 1

	UPDATE a SET measurement_col=1 FROM wow_xpert_rep_det a JOIN (SELECT DISTINCT rep_id FROM  #tmpAgeingNewCols) b ON a.rep_id=b.rep_id
	LEFT JOIN wow_xpert_rep_det c ON c.rep_id=a.rep_id AND c.Measurement_col=1
	WHERE a.column_id='C0530' AND c.row_id IS NULL

	INSERT wow_xpert_rep_det	(rep_id,row_id,col_order, col_header, Dimension, column_id,Measurement_col,xn_type,col_width) 
	SELECT rep_id,row_id,col_order, col_header, Dimension, column_id,Measurement_col,xn_type,col_width FROM #tmpAgeingNewCols


END


