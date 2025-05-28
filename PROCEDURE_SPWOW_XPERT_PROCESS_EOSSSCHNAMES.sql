CREATE PROCEDURE SPWOW_XPERT_PROCESS_EOSSSCHNAMES
@dFromDt DATETIME,
@dToDt DATETIME,
@cEossSchJoinStr VARCHAR(200) OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN

	DECLARE @nStkColsmode NUMERIC(1,0),@EossCFILTERCRITERIA VARCHAR(MAX),@cPcKeyField VARCHAR(100),@cLocIdKeyField VARCHAR(200)

	CREATE TABLE #tEossXpert (errmsg VARCHAR(MAX))
	IF EXISTS (SELECT TOP 1 COL_EXPR FROM #wow_xpert_rep_det WHERE col_expr LIKE '%pmt_OBS%')
		AND EXISTS (SELECT TOP 1 COL_EXPR FROM #wow_xpert_rep_det WHERE col_expr LIKE '%pmt_CBS%')
			SET @nStkColsmode=3
	ELSE
	IF EXISTS (SELECT TOP 1 COL_EXPR FROM #wow_xpert_rep_det WHERE  col_expr LIKE '%pmt_OBS%')
		SET @nStkColsmode=2
	ELSE
		SET @nStkColsmode=1
					

	EXEC SPWOW_XPERT_GETCBS_DETAILS  
	@DFROMDT=@dFromDt,
	@DTODT=@DTODT,  
	@CJOINSTR=' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code',
	@nStkColsmode=@nStkColsmode,
	@cErrormsg=@cErrormsg OUTPUT

	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC

	SET @cEossSchJoinStr=' LEFT JOIN ##tmpWowcbsstk eossSch ON eossSch.SLS_PRODUCT_CODE=pmt_cbs.product_code AND eossSch.dept_id=pmt_cbs.dept_id'

END_PROC:

END