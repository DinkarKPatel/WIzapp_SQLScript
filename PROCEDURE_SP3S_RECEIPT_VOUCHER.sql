CREATE PROCEDURE SP3S_RECEIPT_VOUCHER
(
	@NQUERYID NUMERIC (3,0) ,  
	@CWHERE NVARCHAR(MAX) = '',  
	@CWHERE1 NVARCHAR(MAX) = ''  
)
AS
BEGIN
--IMPORT_ACT_RECEIPT
IF @NQUERYID=1
BEGIN

	DECLARE @cDebtorHEads VARCHAR(MAX),@cDebtorHEads1 VARCHAR(MAX)
	SELECT @cDebtorHEads=dbo.FN_ACT_TRAVTREE('0000000013')	
	SELECT @cDebtorHEads1=dbo.FN_ACT_TRAVTREE('0000000014')	
	SELECT CAST('' AS VARCHAR(40)) AS AC_CODE,CAST('---SELECT ACCOUNT---' AS VARCHAR(MAX)) AS AC_NAME
	UNION
	SELECT DISTINCT ac_code ,AC_NAME
	FROM lm01106 (NOLOCK) 
	WHERE (CHARINDEX(head_code,@cDebtorHEads)>0 OR CHARINDEX(head_code,@cDebtorHEads1)>0)
	ORDER BY AC_NAME
END
IF @NQUERYID=2
BEGIN
	SELECT a.vd_id, a.vm_id, d.voucher_dt, a.ac_code, a.narration, 
	a.credit_amount, 
	a.DEBIT_AMOUNT, 
	a.X_type, a.vs_ac_code, a.chk_recon, a.recon_dt, a.last_update, a.company_code, d.fin_year, a.autoentry, b.ac_name,isnull(b.print_name,'')as print_name, 
	b.BILL_BY_BILL, b.head_code,a.Cost_center_dept_id,isnull(a.Cost_center_dept_id,'') AS Cost_center_code,
	a.control_ac,ISNULL(b.Credit_days,0) as CR_DAYS,ISNULL(b.discount_percentage,0.00) as discount_percentage,a.cost_center_ac_code 
	,ISNULL(a.online_chq_ref_no,'') AS online_chq_ref_no,ISNULL(a.chq_pay_mode,1) as chq_pay_mode,ISNULL(open_cheque_no,'') AS open_cheque_no,ISNULL(open_cheque_dt,'') AS open_cheque_dt,l.dept_name as cost_center_dept_name 
	,CAST('' AS VARCHAR(MAX)) AS REFNO,CAST('' AS DATETIME) AS VOUCHERDATE,CAST('' AS VARCHAR(MAX)) AS VOUCHERTYPE,CAST('' AS VARCHAR(MAX)) AS XNTYPE
	,CAST('' AS VARCHAR(MAX)) AS ACCOUNTNAME,CAST(0 AS NUMERIC(14,2)) AS AMOUNT,CAST('' AS VARCHAR(MAX)) AS NARRATION,CAST('' AS VARCHAR(MAX)) AS COSTCENTER
	,d.REF_NO,d.VOUCHER_CODE,v.VOUCHER_TYPE,Bill.REF_NO AS BILL_NO,BILL.CR_DAYS,CAST(0 AS NUMERIC(14,2)) AS PAYMENT_AMOUNT,CAST(0 AS NUMERIC(14,2)) AS RECEIPT_AMOUNT
	,CAST('' AS VARCHAR(MAX)) AS ERR_MSG
	FROM vd01106 a (NOLOCK) 
	JOIN vm01106 d (NOLOCK) ON a.vm_id = d.vm_id 
	JOIN vchtype v (NOLOCK) ON v.VOUCHER_CODE=d.VOUCHER_CODE
	JOIN BILL_BY_BILL_REF BILL (NOLOCK) ON BILL.VD_ID=a.VD_ID
	JOIN lmv01106 b (NOLOCK) ON a.ac_code = b.ac_code 
	Left outer join location l (nolock) on a.cost_center_dept_id= l.dept_id
	WHERE   1=2 

END
END