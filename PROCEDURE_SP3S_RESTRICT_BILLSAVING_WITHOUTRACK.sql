CREATE PROCEDURE SP3S_RESTRICT_BILLSAVING_WITHOUTRACK
@NSPID VARCHAR(40),
@CUSERCODE CHAR(7),
@CRETVAL VARCHAR(1000) OUTPUT
AS
BEGIN
	DECLARE @cPackSlipNo VARCHAR(40)
	SET @CRETVAL=''

	IF NOT EXISTS (SELECT TOP 1 b.user_code from user_role_det A (NOLOCK) 	
				   JOIN users b (NOLOCK) ON  a.role_id=b.role_id
				   WHERE user_code=@CUSERCODE AND form_option='DN_SAVE_BILL_WO_RACK_ASSIGNMENT'	
				   AND value='1')
		RETURN	
	
	
	SELECT TOP 1 @cPackSlipNo=c.cm_no FROM sls_cmd01106_upload a (NOLOCK) 
	LEFT JOIN delivery_racks_issue_details b (NOLOCK) ON a.pack_slip_id=b.rps_id
	JOIN rps_mst c (NOLOCK) ON c.cm_id=a.pack_slip_id
	WHERE a.sp_id=@nSpId AND ISNULL(a.pack_slip_id,'')<>'' AND b.rps_id IS NULL

	IF ISNULL(@cPackSlipNo,'')<>''
	BEGIN
		SET @CRETVAL='Pack Slip no.: '+@cPackSlipNo+' has not been received at Delivery Rack...Cannot raise Bill'
		RETURN
	END
END