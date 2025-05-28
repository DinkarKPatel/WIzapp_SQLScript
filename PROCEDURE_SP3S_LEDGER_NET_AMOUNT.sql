CREATE PROCEDURE SP3S_LEDGER_NET_AMOUNT----- Data updated by this procedure is used in Transaction approval to 
									  ----- show Ledger net amount column against Actual Purchase value
AS
BEGIN 		

		declare @DSTARTINGFROM datetime
		SELECT TOP 1  @DSTARTINGFROM=ISNULL(CUTOFFDATE,'')
		FROM LOC_XNSAPPROVAL
		WHERE XN_TYPE='PUR'
	
		select mrr_id into #tmpMrr from pim01106 (nolock) where approvedlevelno<>99 and inv_mode=1
		AND  ISNULL(BILL_CHALLAN_MODE,0)<>1 AND pim_mode<>5
		AND cancelled=0 and isnull(mrr_dt,receipt_dt)>=@DSTARTINGFROM 
		AND ISNULL(terms,'')<>''
		
		UNION ALL
		select b.mrr_id from pim01106 a (nolock)
		JOIN pim01106 b (NOLOCK) ON b.ref_converted_mrntobill_mrrid=a.mrr_id
		where a.approvedlevelno<>99 and a.inv_mode=1
		AND  a.pim_mode=5
		AND a.cancelled=0 and isnull(a.mrr_dt,a.receipt_dt)>=@DSTARTINGFROM 
		AND ISNULL(b.terms,'')<>''

	TRUNCATE TABLE pending_purapp_ledgernet
	
	EXEC SP3S_GET_PURVALUE_AGST_TERMS
	@nMode=4


END 	

