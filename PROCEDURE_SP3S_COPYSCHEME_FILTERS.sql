CREATE PROCEDURE SP3S_COPYSCHEME_FILTERS
@cCurLocId VARCHAR(5),
@nSpId VARCHAR(50),
@cErrormsg VARCHAR(1000) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@bLoop BIT,@CNEWKEYVAL VARCHAR(20),@cOldRepId VARCHAR(40),@cStep VARCHAR(5)

BEGIN TRY	
	SET @cStep='5'
	SET @cErrormsg=''

	Set @cCurLocId= @cCurLocId + 'ES'

	CREATE TABLE #tmpSchTable (old_repid VARCHAR(40),new_repid varchar(40))


	INSERT #tmpSchTable (old_repid)
	SELECT REPID FROM SCHNEW_SCHEME_SETUP_DET_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
	AND ISNULL(repid,'')<>''

	SET @cStep='10'
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpSchTable WHERE new_repid IS NULL)
	BEGIN

		SELECT TOP 1 @cOldRepId=old_repid FROM #tmpSchTable WHERE new_repid IS NULL
		print 'Create Filter copy of RepId:'+@cOldRepId

		SET @cStep='15'
		EXEC GETNEXTKEY
		@CTABLENAME='REP_MST',
		@CCOLNAME='REP_ID',
		@NWIDTH=10,
		@CPREFIX=@cCurLocId,
		@NLZEROS=1,
		@CFINYEAR='',
		@NROWCOUNT=1,
		@CNEWKEYVAL=@CNEWKEYVAL OUTPUT

		SET @cStep='20'
		UPDATE #tmpSchTable SET new_repid=@CNEWKEYVAL WHERE old_repid=@cOldRepId 
	END
	print 'came out after Creating Filter copy'

	--if @@spid=100
		--select 'check #tmpSchTable',* from #tmpSchTable
	
	print 'Make new entry in rep_mst after Creating Filter copy'
	SET @cStep='25'
	INSERT rep_mst (CrossTab_Type,rep_id,rep_name,rep_operator,company,user_code,Address,City,Phone,Pin,CrossTab_Rep,RTitle1,RTitle2,RTitle3,
					ref_rep_id,rep_code,SMS,InActive,user_rep_type,contr_per,For_Mgmt,For_wizapplive,For_MWizApp,multi_page,report_item_type,sold_item,EDT_USER_CODE)
	SELECT  	CrossTab_Type,b.new_repid as rep_id,rep_name,rep_operator,company,user_code,Address,City,Phone,Pin,CrossTab_Rep,RTitle1,RTitle2,RTitle3,
				ref_rep_id,rep_code,SMS,InActive,user_rep_type,contr_per,For_Mgmt,For_wizapplive,For_MWizApp,multi_page,report_item_type,sold_item,EDT_USER_CODE
	FROM rep_mst a JOIN #tmpSchTable b ON a.rep_id=b.old_repid

	SET @cStep='30'
	INSERT rep_det	( BASIC_COL, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, col_width, 
	cum_sum, Decimal_place, Dimension, Filter_col, grp_total, key_col, Mesurement_col, order_by, order_on, rep_code, rep_id, row_id, 
	table_name, total )  
	SELECT 	  BASIC_COL, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, col_width, cum_sum, 
	Decimal_place, Dimension, Filter_col, grp_total, key_col, Mesurement_col, order_by, order_on, rep_code, b.new_repid as rep_id, newid() as row_id, table_name, total
	FROM rep_det a (NOLOCK) JOIN #tmpSchTable b ON a.rep_id=b.old_repid

	SET @cStep='35'
	INSERT rep_filter	( cattr, cContaining, cFC, cFD, cINLIST, cnot, filter_lbl, rep_id, row_id )  
	SELECT 	  cattr, cContaining, cFC, cFD, cINLIST, cnot, filter_lbl, b.new_repid as rep_id,newid() as  row_id 
	FROM rep_filter a (NOLOCK) JOIN #tmpSchTable b ON a.rep_id=b.old_repid

	SET @cStep='40'
	INSERT rep_filter_Det	( attr_value, cattr, filter_lbl, rep_id, row_id )  
	SELECT 	  attr_value, cattr, filter_lbl, b.new_repid as rep_id, newid() as row_id 
	FROM rep_filter_Det a (NOLOCK) JOIN #tmpSchTable b ON a.rep_id=b.old_repid

	SET @cStep='45'
	UPDATE a WITH (ROWLOCK) SET repid=b.new_repid from 
	SCHNEW_SCHEME_SETUP_DET_UPLOAD a 
	JOIN #tmpSchTable b ON a.repid=b.old_repid
	WHERE a.sp_id=@nSpId

	GOTO END_PROC
END TRY

BEGIN CATCH
	print 'Enter catch of SP3S_COPYSCHEME_FILTERS'
	SET @cErrormsg='Error in Procedure SP3S_COPYSCHEME_FILTERS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
