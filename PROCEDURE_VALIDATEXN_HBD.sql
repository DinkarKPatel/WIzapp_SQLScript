CREATE PROCEDURE VALIDATEXN_HBD
(
		@CXNID VARCHAR(40),
		@NUPDATEMODE INT,
		@CCMD VARCHAR(1000) OUTPUT
		--*** PARAMETERS :
		--*** @CXNID - TRANSACTION ID ( MEMO ID OF MASTER TABLE )
)
--WITH ENCRYPTION
AS
BEGIN
	
	
	DECLARE @CERRORMSG VARCHAR(MAX),@CEXPRERRORMSG VARCHAR(MAX)
	
	IF EXISTS (SELECT TOP 1 'U' FROM HOLD_BACK_DELIVER_MST WHERE MEMO_ID=@CXNID and 
	CUSTOMER_CODE IN('','000000000000'))
	BEGIN
	    SET @CCMD=@CCMD++'BLANK CUSTOMER  NOT ALLOWED TO SAVE... '
		return
	END
	
	IF EXISTS (SELECT a.memo_ID FROM HOLD_BACK_DELIVER_DET a (NOLOCK) JOIN HOLD_BACK_DELIVER_MST b (NOLOCK) ON 
			   a.memo_id=b.memo_id WHERE a.memo_id=@CXNID AND 
			   ((mode=1 AND ISNULL(ref_cmd_row_id,'')='' AND ISNULL(SOLD_BILL_NO,'')='') OR (mode=2 AND ISNULL(a.product_code,'')='')))
		SET @CCMD=@CCMD+(CASE WHEN @CCMD<>'' THEN ',' ELSE '' END )+'Blank Barcode details not allowed to save... '
	
	--IF EXISTS (SELECT TOP 1 'U' FROM HOLD_BACK_DELIVER_DET A (NOLOCK)
	--JOIN HOLD_BACK_DELIVER_MST b  (NOLOCK) ON a.memo_id=b.memo_id
	--LEFT JOIN CMD01106 CMD  (NOLOCK) ON A.REF_CMD_ROW_ID =CMD.ROW_ID 
	--WHERE A.MEMO_ID=@CXNID AND B.MODE=1 AND CMD.ROW_ID IS NULL
	--)
	--BEGIN
	--    SET @CCMD=@CCMD+'BLANK CASH MEMO DETAILS CAN NOT BE SAVED ... '
	--	return
	--END
	
END_PROC:
END
--******************************************* END OF PROCEDURE VALIDATEXN_HBD