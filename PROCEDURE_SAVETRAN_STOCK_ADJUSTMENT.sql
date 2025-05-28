create PROCEDURE SAVETRAN_STOCK_ADJUSTMENT
@nUpdatemode INT,
@nSpId NUMERIC(5,0)
AS
BEGIN
	DECLARE @cFinYear VARCHAR(10),@cStep VARCHAR(5),@cErrormsg VARCHAR(MAX),@cWhereClause VARCHAR(200)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''

	SELECT @cFinYear=fin_year FROM stkadj_year_wise_cbsstk_depcn_mst_upload (NOLOCK) 
	WHERE sp_id=@nSpId
	
	if exists (select top 1 'U' from stkadj_year_wise_cbsstk_depcn_det_upload A (nolock) 
	           left join sku b (nolock) on a.product_code =b.product_code 
	           where b.product_code is null and sp_id=@nSpId)
	 begin
	       
	       SELECT A.PRODUCT_CODE ,'INVALID ITEM CODE ' AS ERRMSG
	       FROM STKADJ_YEAR_WISE_CBSSTK_DEPCN_DET_UPLOAD A (NOLOCK) 
	       LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE 
	       WHERE B.PRODUCT_CODE IS NULL AND SP_ID=@NSPID
	 
	 end


	SET @cStep='20'
	UPDATE a SET prev_depcn_value=(SELECT SUM(depcn_value) FROM year_wise_cbsstk_depcn_det b
	WHERE b.fin_year<a.fin_year AND b.product_code=a.product_code AND b.dept_id=a.dept_id)  FROM stkadj_year_wise_cbsstk_depcn_det_upload a
	WHERE sp_id=@nSpId

	SET @cStep='40'
	SET @cWhereClause=' sp_id='+ltrim(rtrim(str(@nSpId)))
	
	EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN 
		@CSOURCEDB	= ''
		, @CSOURCETABLE = 'stkadj_year_wise_cbsstk_depcn_mst_upload'
		, @CDESTDB		= ''
		, @CDESTTABLE	= 'year_wise_cbsstk_depcn_mst'
		, @CKEYFIELD1	= 'fin_year'
		, @BALWAYSUPDATE = 1
		, @CFILTERCONDITION=@cWhereClause
		, @LINSERTONLY =  1


	SET @cStep='50'
	EXEC UPDATEMASTERXN_OPT--UPDATEMASTERXN 
		@CSOURCEDB	= ''
		, @CSOURCETABLE = 'stkadj_year_wise_cbsstk_depcn_det_upload'
		, @CDESTDB		= ''
		, @CDESTTABLE	= 'year_wise_cbsstk_depcn_det'
		, @CKEYFIELD1	= 'fin_year'
		, @CKEYFIELD2	= 'product_code'
		, @CKEYFIELD3	= 'dept_id'
		, @BALWAYSUPDATE = 1
		, @CFILTERCONDITION=@cWhereClause
		, @LINSERTONLY =  0
		, @LUPDATEXNS =  1

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SAVETRAN_STOCK_ADJUSTMENT at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT @cErrormsg errmsg
END
