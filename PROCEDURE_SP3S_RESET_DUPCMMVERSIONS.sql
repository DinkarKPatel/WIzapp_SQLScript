CREATE  PROCEDURE SP3S_RESET_DUPCMMVERSIONS
AS
BEGIN
	DECLARE @cErrmsg VARCHAR(MAX),@nUpdateMode INT,@bCancelled BIT,@CFILTERCONDITION VARCHAR(200),@cStep VARCHAR(5)

	
BEGIN TRY
	SET @cStep='10'
	
	begin tran

	exec SP3S_DELETE_DUPCMMVERSIONS

	SET @cStep='20'
	select *,cm_id old_cm_id into #tmpcmm from  cmm01106 (nolock) where cm_id<>org_memo_id AND ISNULL(org_memo_id,'')<>''
	
	IF NOT EXISTS (SELECT TOP 1 cm_id FROM #tmpcmm)
		GOTO END_PROC
	
	update #tmpcmm SET version_no=isnull(version_no,0)+1,cm_id=org_memo_id
		
	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='#tmpCmm',@CDESTDB=''
							,@CDESTTABLE='cmm01106',@CKEYFIELD1='cm_id',@CKEYFIELD2='',@CKEYFIELD3=''
							,@LINSERTONLY=1,@CFILTERCONDITION='',@BUPDATEXNS=1


	SET @cStep='30'
	UPDATE a WITH (ROWLOCK) SET memo_id=b.cm_id from  
	paymode_xn_det a JOIN #tmpcmm b ON a.memo_id=b.old_cm_id
	WHERE  xn_type='SLS'

	UPDATE a WITH (ROWLOCK) SET Cm_id=b.cm_id from  
	cmd_cons a JOIN #tmpcmm b ON a.Cm_id=b.old_cm_id

	
	SET @cStep='40'
	UPDATE a WITH (ROWLOCK) SET Cm_id=b.cm_id from  
	PACK_SLIP_REF a JOIN #tmpcmm b ON a.Cm_id=b.old_cm_id

	UPDATE a WITH (ROWLOCK) SET memo_id=b.cm_id from  
	IMAGE_XN_DET a JOIN #tmpcmm b ON a.memo_id=b.old_cm_id
	WHERE xn_type='SLS'

	SET @cStep='50'
	UPDATE a WITH (ROWLOCK) SET Cm_id=b.cm_id from  
	CMM_FLIGHT a JOIN #tmpcmm b ON a.Cm_id=b.old_cm_id

	UPDATE a WITH (ROWLOCK) SET Cm_id=b.cm_id from  
	COUPON_REDEMPTION_INFO a JOIN #tmpcmm b ON a.Cm_id=b.old_cm_id

	SET @cStep='60'
	UPDATE a WITH (ROWLOCK) SET redemption_cm_id=b.cm_id from  
	GV_MST_REDEMPTION a JOIN #tmpcmm b ON a.redemption_cm_id=b.old_cm_id

	UPDATE a WITH (ROWLOCK) SET MEMONO=b.cm_id from  
	DAILOGFILE a JOIN #tmpcmm b ON a.MEMONO=b.old_cm_id

	SET @cStep='70'
	UPDATE a WITH (ROWLOCK) SET Cm_id=b.cm_id from  
	cmd01106 a JOIN #tmpcmm b ON a.Cm_id=b.old_cm_id

	UPDATE a WITH (ROWLOCK) SET ref_cm_id=b.cm_id from  
	rps_mst a JOIN #tmpcmm b ON a.ref_cm_id=b.old_cm_id

	SET @cStep='80'
	UPDATE a WITH (ROWLOCK) SET xn_id=b.cm_id from  
	XN_AUDIT_TRIAL_DET a JOIN #tmpcmm b ON a.xn_id=b.old_cm_id

	UPDATE a WITH (ROWLOCK) SET Cm_id=b.cm_id from  
	cmm_credit_receipt a JOIN #tmpcmm b ON a.Cm_id=b.old_cm_id

	SET @cStep='90'
	DELETE a FROM cmm01106 a JOIN #tmpcmm b ON a.cm_id=b.old_cm_id

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrmsg='Error in Procedure SP3S_UPDATE_OLDCMMVERSIONS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

	if @@TRANCOUNT>0
	begin
		if ISNULL(@cErrmsg,'')=''
			commit
		else
			rollback
	end

	SELECT ISNULL(@cErrmsg,'') errmsg

END
