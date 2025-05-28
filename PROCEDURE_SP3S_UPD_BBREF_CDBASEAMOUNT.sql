CREATE PROCEDURE SP3S_UPD_BBREF_CDBASEAMOUNT
AS
BEGIN
	DECLARE @cBlankCdRefNo VARCHAR(100)



	update a set pur_mrr_id=e.memo_id
	from bill_by_bill_ref a 
 	JOIN vd01106 c (NOLOCK) ON c.vd_id=a.vd_id 
	JOIN vm01106 d (NOLOCK) ON d.vm_id=c.vm_id
	JOIN POSTACT_VOUCHER_LINK e (NOLOCK) ON e.vm_id=d.vm_id
	WHERE e.xn_type='PUR' AND d.cancelled=0
	   
	SELECT TOP 1 @cBlankCdRefNo=a.ref_no FROM bill_by_bill_ref a (NOLOCK) 
	JOIN pim01106 b (NOLOCK) ON b.mrr_id=a.pur_mrr_id
	WHERE ISNULL(a.cd_base_amount,0)=0 and b.total_amount<>0 and b.cancelled=0

	IF @cBlankCdRefNo IS NULL
		RETURN

	SELECT DISTINCT terms INTO #tmpMrr FROM bill_by_bill_ref a (NOLOCK) 
	JOIN pim01106 b (NOLOCK) ON b.mrr_id=a.pur_mrr_id
	WHERE ISNULL(a.cd_base_amount,0)=0 AND ISNULL(b.terms,'')<>'' AND b.cancelled=0

	CREATE TABLE #ledger_terms (terms varchar(200),applycdontotal BIT,cd_pct NUMERIC(6,2))

	DECLARE @cTerms VARCHAR(200)

	WHILE EXISTS (SELECT TOP 1 * FROM #tmpMrr)
	BEGIN
		SELECT TOP 1 @cTerms=terms FROM #tmpMrr

		INSERT INTO #ledger_terms (TERMS,applycdontotal,cd_pct)
		SELECT @cterms,applycdontotal,cashdiscount FROM dbo.FN3SGETLEDGERTERMS(@cterms)

		DELETE FROM #tmpMrr WHERE  terms=@cTerms
	END

	----Start of Maintainance script to Update new Columns in bill by Bill Table
	

	
	update a set cd_base_amount=b.cd_base_amount,cd_percentage=b.cd_pct from bill_by_bill_ref a
		JOIN 
		(select a.pur_mrr_id,ISNULL(d.cd_pct,b.cr_discount_percentage) cd_pct,
		(CASE WHEN isnull(d.terms,'')<>'' and isnull(d.applycdontotal,1)=1   THEN b.total_amount
			  WHEN isnull(cd_calc_based_on,1)=2 THEN b.total_amount
				   ELSE SUM(c.xn_value_without_gst) END) cd_base_amount from bill_by_bill_ref a (nolock)
		 join pim01106 b (nolock) on b.mrr_id=a.pur_mrr_id
		 JOIN pid01106 c (NOLOCK) ON c.mrr_id=b.mrr_id
		 LEFT JOIN #ledger_terms d ON d.terms=b.terms  	
		 left join lmp01106 e on e.ac_code=b.ac_code 
		WHERE adj_remarks='PURCHASE' AND isnull(cd_base_amount,0)=0 AND b.cancelled=0
		group by a.pur_mrr_id,ISNULL(d.applycdontotal,1),b.total_amount,isnull(cd_calc_based_on,1),
		isnull(d.terms,''),ISNULL(d.cd_pct,b.cr_discount_percentage)) b on a.pur_mrr_id=b.pur_mrr_id
	----End of Maintainance script to Update new Columns in bill by Bill Table
END
