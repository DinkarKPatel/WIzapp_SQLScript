CREATE PROCEDURE SP3S_VALIDATEXN_RPSMERGE
@cSpId VARCHAR(50),
@cMemoId VARCHAR(40),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @NNETAMOUNT NUMERIC(10,2),@NCMMSUBTOTAL NUMERIC(10,2),@NPAYMODETOTAMT NUMERIC(10,2),
	@nTotRpmQty NUMERIC(10,2),@nTotRpdQty NUMERIC(10,2),@cStep VARCHAR(4),@nPaymode NUMERIC(1,0)

	
	SET @CSTEP=10.8
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CSPID,'',1


	SELECT @nTotRpmQty=total_quantity FROM rps_mst (NOLOCK) WHERE cm_id=@cMemoId

	SET @CSTEP=11.2
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CSPID,'',1
		
	SELECT @nTotRpdQty = SUM(quantity) FROM rps_det (NOLOCK) WHERE cm_id=@cMemoId 

	SET @CSTEP=11.4
	EXEC SP_CHKXNSAVELOG 'WPSMERGE',@CSTEP,0,@CSPID,'',1		  
	SELECT @nTotRpmQty=ISNULL(@nTotRpmQty,0),@nTotRpdQty = ISNULL(@nTotRpdQty,0)  
	
	IF @nTotRpmQty<>@nTotRpdQty
	BEGIN  
		PRINT 'SP3S_VALIDATEXN_RPSMERGE Quantity match FAILED'
		SET @CERRORMSG='Bill level Total quantity '+STR(@nTotRpmQty,14,2)+' SHOULD BE EQUAL TO THE SUM OF Item level quantity '+STR(@nTotRpdQty,10,2)+'...PLEASE CHECK'  
		GOTO END_PROC
	END

END_PROC:
	
END