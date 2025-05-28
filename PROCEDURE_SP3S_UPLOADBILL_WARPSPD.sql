CREATE PROCEDURE SP3S_UPLOADBILL_WARPSPD
(
	@cCM_ID		VARCHAR(50)
)
AS
BEGIN
	;WITH DET
	AS
	(
		SELECT CASE WHEN Quantity<0 THEN 'R' ELSE 'S' END AS [ItemType],
		A.QUANTITY AS [ItemQty],
		A.MRP AS [Unit],
		A.discount_amount+ISNULL(A.cmm_discount_amount,0) AS [ItemDiscount],
		A.igst_amount+A.cgst_amount+A.sgst_amount AS [ItemTax],
		A.MRP * A.QUANTITY AS [TotalPrice],
		A.rfnet AS [BilledPrice],
		B.article_no AS [Department],
		B.SECTION_NAME AS [Group],
		B.PRODUCT_CODE [ItemId],
		B.SUB_SECTION_NAME AS [Category]
		,A.CM_ID
		FROM CMD01106 A 
		JOIN SKU_NAMES B ON B.product_Code=A.PRODUCT_CODE 
		WHERE A.cm_id=@cCM_ID
	)
	SELECT LTRIM(RTRIM(a.cm_no)) +(CASE WHEN A.CANCELLED=1 THEN '_C' ELSE '' END) as [TransactionCode],a.NET_AMOUNT as [amount],
	CONVERT(VARCHAR(50),a.cm_dt,106) as [TransactionDate],a.cm_id,
	A2.mobile AS mobile,A2.email AS email,A2.customer_code  AS external_id,A2.customer_fname AS firstname,A2.customer_lname AS lastname,
	(CASE WHEN ISNULL(A2.gender,0)=2 THEN 'Female' ELSE 'Male' END) AS gender,GETDATE() AS registered_on,
	(CASE ISNULL(A2.dt_birth,'') WHEN '' THEN '' ELSE CONVERT(VARCHAR(50),A2.dt_birth,106) END )AS DOB, 
	(CASE ISNULL(A2.dt_anniversary,'') WHEN '' THEN '' ELSE CONVERT(VARCHAR(50),A2.dt_anniversary,106) END )AS DOA, 
	CAST('' AS VARCHAR(MAX)) AS ERR_MSG,C.username,LEFT(A.CM_ID,2) AS DEPT_ID
	,b.*
	FROM CMM01106 A (NOLOCK) 
	JOIN  DET b ON b.cm_id=a.cm_id
	JOIN CUSTDYM A2 (NOLOCK) ON A2.customer_code=A.customer_code
	JOIN users C ON c.user_code=A.USER_CODE
	WHERE  ISNULL(A2.MOBILE,'')<>'' AND LEN(A2.MOBILE)=10 AND a.cm_id=@cCM_ID
END