CREATE PROCEDURE SP3S_GET_PENDING_CONVERT_TRANSPORTER_CHALLANS
@nQueryId NUMERIC(2,0),
@CWhere VARCHAR(100),
@cMRRID VARCHAR(100)=''
AS
BEGIN
	DECLARE @cProductCode VARCHAR(100),@cErrormsg VARCHAR(500),@cCutOffdate VARCHAR(10)

	IF @nQueryId=1
	BEGIN

		SELECT TOP 1 @cProductCode=value FROM config (NOLOCK)
		WHERE config_option='SERVICE_PC_PARCELCHALLANS'

		IF ISNULL(@cProductCode,'')=''
		BEGIN
			SET @cErrormsg='Service Barcode not found for Converting Parcel Challans into Bill..'
			GOTO END_PROC
		END

		IF NOT EXISTS (SELECT TOP 1 product_code FROM sku (NOLOCK) WHERE product_code=@cProductCode)
		BEGIN
			SET @cErrormsg='Invalid Service Barcode defined for Converting Parcel Challans into Bill..'
			GOTO END_PROC			
		END

		SELECT TOP 1 @cCutOffdate=value FROM  config (NOLOCK) WHERE config_option='parcel_convert_tobill_cutoffdate'

		SET @cCutOffdate=ISNULL(@cCutOffdate,'')

		SELECT CONVERT(BIT,0) chk,a.parcel_memo_id,CONVERT(VARCHAR(1000),null) srv_narration,ISNULL(ref_converted_transport_bill_memoid,'') ref_converted_transport_bill_memoid
		INTO #tmpPending 
		FROM parcel_mst a (NOLOCK) 
		JOIN angm b (NOLOCK) ON a.angadia_code=b.Angadia_code
		WHERE ISNULL(ref_converted_transport_bill_memoid,'')=''	AND b.ac_code=@CWhere
		AND a.total_amount<>0 AND a.pay_type=1
		AND parcel_memo_dt>=@cCutOffdate

		INSERT INTO #tmpPending(chk,parcel_memo_id,srv_narration,ref_converted_transport_bill_memoid)
		SELECT CONVERT(BIT,1) chk,a.parcel_memo_id,CONVERT(VARCHAR(1000),null) srv_narration,ref_converted_transport_bill_memoid
		FROM parcel_mst a (NOLOCK)
		WHERE ISNULL(ref_converted_transport_bill_memoid,'')<>''	AND ref_converted_transport_bill_memoid=@cMRRID 

		update a SET srv_narration=coalesce(srv_narration+',','')+'Party Inv#'+b.PARTY_INV_NO+' Inv Dt:'+convert(varchar,b.party_inv_dt,105)+
		' Amount :'+ltrim(rtrim(str(b.party_inv_amt,10,2))) 
		FROM #tmpPending a 
		JOIN parcel_det b ON a.parcel_memo_id=b.parcel_memo_id

		SELECT CAST(0 AS NUMERIC(5)) srno,angadia_name,a.Total_amount,c.chk,
		a.parcel_memo_id, a.parcel_memo_no,a.parcel_memo_dt,'' errmsg,
		a.bilty_no,a.receipt_dt,gate_entry_no,cash_receipt_no,lm.ac_name
		FROM parcel_mst a (NOLOCK) 
		JOIN angm b (NOLOCK) ON a.angadia_code=b.Angadia_code
		JOIN #tmpPending c ON c.parcel_memo_id=a.parcel_memo_id
		JOIN lm01106 lm (NOLOCK) ON lm.AC_CODE=a.PARCEL_AC_CODE
		ORDER BY c.chk desc

		SELECT @cProductCode as product_code,a.total_amount as gross_purchase_price,1 as quantity,a.total_amount as purchase_price,
		article_no, c.article_code,c.para1_code,c.para2_code,c.para3_code,c.para4_code,c.para5_code,c.para6_code,
		a.parcel_memo_id ,a.parcel_memo_id as PO_ID,((CASE WHEN ISNULL(a.bilty_no,'')<>'' THEN 
		'Bilty no.:'+a.bilty_no ELSE '' END)+b.srv_narration) srv_narration,1 invoice_quantity,1 quantity
		 FROM parcel_mst a (NOLOCK) 
		JOIN  #tmpPending b ON a.parcel_memo_id=b.parcel_memo_id
		JOIN sku c (NOLOCK) ON c.product_code=@cProductCode
		JOIN article d (NOLOCK) ON d.article_code=c.article_code
	END

	ELSE 
	IF @nQueryId=2
	BEGIN
		--SELECT parcel_memo_no,parcel_memo_dt,RECEIPT_DT,TOTAL_AMOUNT,Parcel_memo_ID 
		--FROM Parcel_mst (NOLOCK)
		--WHERE ref_converted_transport_bill_memoid=@CWhere
		SELECT CAST(0 AS NUMERIC(5)) srno,angadia_name,a.Total_amount,CONVERT(BIT,1)  chk,
		a.parcel_memo_id, a.parcel_memo_no,a.parcel_memo_dt,'' errmsg,
		a.bilty_no,a.receipt_dt,gate_entry_no,cash_receipt_no,lm.ac_name
		FROM parcel_mst a (NOLOCK) 
		JOIN angm b (NOLOCK) ON a.angadia_code=b.Angadia_code
		JOIN lm01106 lm (NOLOCK) ON lm.AC_CODE=a.PARCEL_AC_CODE
		WHERE ref_converted_transport_bill_memoid=@CWhere
	END

END_PROC:
	IF ISNULL(@cErrormsg,'')<>''
		SELECT @cErrormsg as errmsg
END