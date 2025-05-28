CREATE PROCEDURE SP3S_VALIDATE_PRT_BILLCHALLANMODE
 @nBillChallanMode NUMERIC(1,0),
 @cSourceTable VARCHAR(200),
 @cSpid VARCHAR(40),
 @nPrtMode NUMERIC(1,0)=0,
 @cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cColumn VARCHAR(40),@cJoinstr VARCHAR(200)

	IF @nPrtMode<>2
		SET @cCmd=N'IF EXISTS (SELECT TOP 1 product_code FROM '+@cSourceTable+' a (NOLOCK) 
					WHERE a.sp_id='''+@cSpId+''' AND ISNULL(pur_bill_challan_mode,0)<>'+ltrim(rtrim(str(@nBillChallanMode)))+')
						SET @cErrormsg=''Mismatch in Bill Challan mode.....Please check''
					ELSE
						SET @cErrormsg=''''' 
	ELSE
		SET @cCmd=N'IF EXISTS (SELECT TOP 1 a.product_code FROM '+@cSourceTable+' a (NOLOCK) 
					JOIN pid01106 b (NOLOCK) ON b.product_code=a.product_code
					JOIN  pim01106 c (NOLOCK) ON c.mrr_id=b.mrr_id
					WHERE a.sp_id='''+@cSpId+''' AND c.bill_challan_mode=1)
						SET @cErrormsg=''Items related to Challan mode are not allowed in Multiple Debit Note.....Please check''
					ELSE
						SET @cErrormsg=''''' 

	PRINT isnull(@cCmd,'null bill challan mode validation')
	EXEC SP_EXECUTESQL @cCmd,N'@cErrormsg VARCHAR(MAX) OUTPUT',@cErrormsg OUTPUT
	

	IF @cSourceTable='prt_rmd01106_upload' AND ISNULL(@cErrormsg,'')<>''
	BEGIN
		IF @nPrtMode=2
			SELECT a.product_code,a.quantity,@cErrormsg errmsg FROM prt_rmd01106_upload a (NOLOCK)
			JOIN pid01106 b (NOLOCK) ON b.product_code=a.product_code
			JOIN  pim01106 c (NOLOCK) ON c.mrr_id=b.mrr_id
			WHERE a.sp_id=@cSpId AND c.bill_challan_mode=1
		ELSE
			SELECT product_code,quantity,@cErrormsg errmsg FROM prt_rmd01106_upload (NOLOCK) WHERE sp_id=@cSpId
			AND ISNULL(pur_bill_challan_mode,0)<>@nBillChallanmode
	END
	ELSE
	IF @cSourceTable='dnps_dnps_det_upload' AND ISNULL(@cErrormsg,'')<>''
	BEGIN
		SELECT product_code,quantity,@cErrormsg errmsg FROM dnps_dnps_det_upload (NOLOCK) WHERE sp_id=@cSpId
		AND ISNULL(pur_bill_challan_mode,0)<>@nBillChallanmode
	END
END
