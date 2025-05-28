CREATE PROCEDURE SP3S_DELETE_DUMMYENTRIES
AS
BEGIN
	DELETE from cmd_cons with (rowlock) where cm_id='XXXXXXXXXX'
	DELETE from PACK_SLIP_REF with (rowlock) where cm_id='XXXXXXXXXX'
	DELETE from IMAGE_XN_DET with (rowlock) where memo_id='XXXXXXXXXX' and xn_type='SLS'
	DELETE from CMM_FLIGHT with (rowlock) where cm_id='XXXXXXXXXX'
	DELETE from COUPON_REDEMPTION_INFO with (rowlock) where cm_id='XXXXXXXXXX'
	DELETE from GV_MST_REDEMPTION with (rowlock) where redemption_cm_id='XXXXXXXXXX'
	DELETE from DAILOGFILE with (rowlock) where MEMONO='XXXXXXXXXX' 
	DELETE a FROM cmd_manualbill_errors a with (ROWLOCK) JOIN cmd01106 b (NOLOCK) ON a.cmd_row_id=b.ROW_ID
	where cm_id='XXXXXXXXXX'
	DELETE FROM cmd01106 with (ROWLOCK) where cm_id='XXXXXXXXXX'
	DELETE FROM rps_mst with (ROWLOCK) WHERE ref_cm_id='XXXXXXXXXX'
	DELETE  FROM XN_AUDIT_TRIAL_DET WITH (ROWLOCK)   WHERE xn_id='XXXXXXXXXX' AND XN_TYPE='SLS'
	DELETE FROM cmm_credit_receipt with (ROWLOCK) where cm_id='XXXXXXXXXX'
	DELETE FROM POSGRRecos with (ROWLOCK) where cm_id='XXXXXXXXXX'

	DELETE FROM RPS_DET WITH (ROWLOCK)  where cm_id='XXXXXXXXXX'
	DELETE FROM WPS_DET WITH (ROWLOCK)  where ps_id='XXXXXXXXXX'
	DELETE From GRN_PS_DET WITH (ROWLOCK)  where MEMO_ID='XXXXXXXXXX'
	DELETE From pid01106 WITH (ROWLOCK)  where mrr_id='XXXXXXXXXX'
	DELETE From rmd01106 WITH (ROWLOCK)  where rm_id='XXXXXXXXXX'
	DELETE From ind01106 WITH (ROWLOCK)  where inv_id='XXXXXXXXXX'
	DELETE From cnd01106 WITH (ROWLOCK)  where cn_id='XXXXXXXXXX'

END