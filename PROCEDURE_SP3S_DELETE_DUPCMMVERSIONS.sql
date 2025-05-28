CREATE PROCEDURE SP3S_DELETE_DUPCMMVERSIONS
@bDeleteDummyEntries BIT=0
AS
BEGIN
	select cm_id into #tmpdupCmIds from cmm01106 a (NOLOCK) WHERE 1=2

	IF @bDeleteDummyEntries=0
	BEGIN
		select cm_no,fin_year,max(isnull(version_no,0)) version_no,count(cm_id) cnt into #tmpdupcmm
		from cmm01106
		group by cm_no,fin_year
		having count(cm_id)>1

		INSERT #tmpdupCmIds
		select cm_id  from cmm01106 a
		JOIN #tmpdupcmm b ON b.CM_NO=a.CM_NO AND b.fin_year=a.fin_year
		where ISNULL(a.version_no,0)<b.version_no
	END
	ELSE
	BEGIN
		INSERT #tmpdupCmIds
		select 'XXXXXXXXXX' cm_id
	END

	IF NOT EXISTS (SELECT TOP 1 cm_id from #tmpdupCmIds)
		RETURN
	
	delete a from paymode_xn_det a (NOLOCK) JOIN #tmpdupCmIds b ON a.memo_id=b.cm_id
	WHERE a.xn_type='SLS'

	DELETE a FROM cmd_cons a (NOLOCK) JOIN #tmpdupCmIds b ON a.cm_id=b.cm_id
	
	DELETE a FROM PACK_SLIP_REF a (NOLOCK) JOIN #tmpdupCmIds b ON a.cm_id=b.cm_id
	
	DELETE a FROM IMAGE_XN_DET a (NOLOCK) JOIN #tmpdupCmIds b ON a.memo_id=b.cm_id
	WHERE a.xn_type='SLS'

	DELETE a FROM CMM_FLIGHT a (NOLOCK) JOIN #tmpdupCmIds b ON a.cm_id=b.cm_id

	DELETE a FROM COUPON_REDEMPTION_INFO a (NOLOCK) JOIN #tmpdupCmIds b ON a.cm_id=b.cm_id

	DELETE a FROM GV_MST_REDEMPTION a (NOLOCK) JOIN #tmpdupCmIds b ON a.redemption_cm_id=b.cm_id
	
	DELETE a FROM DAILOGFILE a (NOLOCK) JOIN #tmpdupCmIds b ON a.MEMONO=b.cm_id

	DELETE a FROM CMD_MANUALBILL_ERRORS a (NOLOCK) JOIN cmd01106 b (NOLOCK) ON a.cmd_row_id=b.ROW_ID
	JOIN #tmpdupCmIds c ON c.cm_id=b.cm_id
	
	delete a from cmd01106 a (NOLOCK) JOIN #tmpdupCmIds b ON a.cm_id=b.cm_id
	
	DELETE a FROM RPS_DET a WITH (ROWLOCK) JOIN rps_mst b (NOLOCK) ON a.cm_id=b.cm_id
	JOIN #tmpdupCmIds c ON c.cm_id=b.ref_cm_id

	DELETE a FROM RPS_MST a WITH (ROWLOCK) 
	JOIN #tmpdupCmIds c ON c.cm_id=a.ref_cm_id

	DELETE a FROM XN_AUDIT_TRIAL_DET a WITH (ROWLOCK)
	JOIN #tmpdupCmIds b ON a.xn_id=b.cm_id
	WHERE a.XN_TYPE='SLS'

	delete a from cmm_credit_receipt a (NOLOCK) JOIN #tmpdupCmIds b ON a.cm_id=b.cm_id
	
	IF @bDeleteDummyEntries=0
		DELETE a FROM cmm01106 a WITH (ROWLOCK) JOIN #tmpdupCmIds b ON a.cm_id=b.cm_id 
END

