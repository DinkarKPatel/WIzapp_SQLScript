CREATE PROCEDURE SPWOW_GET_XPERT_PERIODBASE
AS
BEGIN
	IF EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a
	JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
	WHERE col_modE=2 and LEFT(a.column_id,1)='C')
		 INSERT #tmpPeriodBase (base)
		 SELECT 'CURRENT'

	IF EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a
	JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
	WHERE col_modE=2 and LEFT(a.column_id,1)='Y')
		 INSERT #tmpPeriodBase (base)
		 SELECT 'YTD'

	IF EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a
	JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
	WHERE col_modE=2 and LEFT(a.column_id,1)='M')
		 INSERT #tmpPeriodBase (base)
		 SELECT 'MTD'

END