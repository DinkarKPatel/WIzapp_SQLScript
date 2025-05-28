CREATE PROCEDURE VALIDATEXN_SDL
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
	
	IF EXISTS (SELECT TOP 1 'U' FROM SLS_DELIVERY_MST WHERE MEMO_ID=@CXNID AND delivery_mode=1 and CUSTOMER_CODE IN('','000000000000'))
	BEGIN
	    SET @CCMD=@CCMD++'BLANK CUSTOMER  NOT ALLOWED TO SAVE... '
		return
	END

	;WITH HBD_ID
	AS
	(
		SELECT DISTINCT A.MEMO_ID 
		FROM hold_back_deliver_det a (NOLOCK)
		JOIN sls_delivery_det b (NOLOCK) ON b.ref_hbd_row_id=a.row_id
		WHERE a.HBD_STATUS IN (1,3) AND b.memo_id=@CXNID
	)
	,HBD_TOTAL
	AS
	(
		SELECT a.memo_id,SUM(JOB_RATE) AS TOTAL_JOB_RATE 
		FROM hold_back_deliver_det a
		JOIN HBD_ID ON HBD_ID.memo_id=a.memo_id
		WHERE a.HBD_STATUS IN (1,3) 
		GROUP BY a.memo_id
	)
	,ARC_TOTAL
	AS
	(
		SELECT HBD_ID.memo_id,ADV_AMOUNT=SUM(A.amount) 
		FROM ARC01106 A
		JOIN HBD_RECEIPT B ON A.adv_rec_id=B.ADV_REC_ID
		JOIN HBD_ID ON HBD_ID.memo_id=B.MEMO_ID
		GROUP BY HBD_ID.memo_id
	)
	SELECT @CCMD=@CCMD+(CASE WHEN @CCMD<>'' THEN ',' ELSE '' END )+'Advance/Other Chareges not paid by customer...not allowed to save... ' 
	FROM HBD_TOTAL A 
	LEFT OUTER JOIN ARC_TOTAL B ON B.memo_id=A.memo_id
	WHERE ISNULL( A.TOTAL_JOB_RATE,0)>ISNULL(B.ADV_AMOUNT,0)


	

	--IF EXISTS (SELECT a.memo_ID FROM HOLD_BACK_DELIVER_DET a (NOLOCK) 
	--			JOIN HOLD_BACK_DELIVER_MST b (NOLOCK) ON 
	--		   a.memo_id=b.memo_id WHERE a.memo_id=@CXNID AND 
	--		   ((mode=1 AND ISNULL(ref_cmd_row_id,'')='') OR (mode=2 AND ISNULL(a.product_code,'')='')))
	--	SET @CCMD=@CCMD+(CASE WHEN @CCMD<>'' THEN ',' ELSE '' END )+'Blank Barcode details not allowed to save... '
	
	----IF EXISTS (SELECT TOP 1 'U' FROM HOLD_BACK_DELIVER_DET A (NOLOCK)
	----JOIN HOLD_BACK_DELIVER_MST b  (NOLOCK) ON a.memo_id=b.memo_id
	----LEFT JOIN CMD01106 CMD  (NOLOCK) ON A.REF_CMD_ROW_ID =CMD.ROW_ID 
	----WHERE A.MEMO_ID=@CXNID AND B.MODE=1 AND CMD.ROW_ID IS NULL
	----)
	----BEGIN
	----    SET @CCMD=@CCMD+'BLANK CASH MEMO DETAILS CAN NOT BE SAVED ... '
	----	return
	----END
	
END_PROC:
END
--******************************************* END OF PROCEDURE VALIDATEXN_HBD