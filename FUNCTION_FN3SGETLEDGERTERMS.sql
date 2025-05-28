CREATE FUNCTION FN3SGETLEDGERTERMS (@cTerms VARCHAR(1000))
RETURNS @ledgerTerms TABLE ( terms VARCHAR(1000), GROSS_MARGIN numeric(10,2),CREDIT_DAYS numeric(5,0),prevatdiscount numeric(10,2),
REIMUBURSE_PURCHASE_TAX BIT,REIMUBURSE_FREIGHT BIT,REIMUBURSE_INSURANCE bit,REIMUBURSE_OUTPUT_VAT BIT,
CashDiscount NUMERIC(7,3),ApplyCDOnTotal BIT,EOSS_DISCOUNT_SHARE BIT,
EOSS_DISCOUNT_PER NUMERIC(10,2),FIX_MRP_MD_PERCENTAGE NUMERIC(6,2),REIMUBURSE_OUTPUT_GST BIT
)
AS
BEGIN
	INSERT INTO @ledgerTerms (terms, GROSS_MARGIN,CREDIT_DAYS,prevatdiscount,cashdiscount,REIMUBURSE_PURCHASE_TAX,
	REIMUBURSE_FREIGHT,REIMUBURSE_INSURANCE,REIMUBURSE_OUTPUT_VAT,ApplyCDOnTotal,
	EOSS_DISCOUNT_SHARE,EOSS_DISCOUNT_PER,FIX_MRP_MD_PERCENTAGE,REIMUBURSE_OUTPUT_GST)
	SELECT @cTerms as terms,substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,2)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,3)-dbo.CHARINDEX_NTH('-',@cTerms,1,2)-1) GROSS_MARGIN,
	substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,3)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,4)-dbo.CHARINDEX_NTH('-',@cTerms,1,3)-1) as credit_days,
	substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,4)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,5)-dbo.CHARINDEX_NTH('-',@cTerms,1,4)-1) as prevatdiscount,
	substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,5)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,6)-dbo.CHARINDEX_NTH('-',@cTerms,1,5)-1) as cashdiscount,
	(CASE WHEN isnull(substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,6)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,7)-dbo.CHARINDEX_NTH('-',@cTerms,1,6)-1),'')='Y' THEN 1 ELSE 0 END) as REIMUBURSE_PURCHASE_TAX,
	(CASE WHEN isnull(substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,7)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,8)-dbo.CHARINDEX_NTH('-',@cTerms,1,7)-1),'')='Y' THEN 1 ELSE 0 END)  as REIMUBURSE_FREIGHT,
	(CASE WHEN isnull(substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,8)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,9)-dbo.CHARINDEX_NTH('-',@cTerms,1,8)-1),'')='Y' THEN 1 ELSE 0 END) as REIMUBURSE_INSURANCE,
	(CASE WHEN isnull(substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,9)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,10)-dbo.CHARINDEX_NTH('-',@cTerms,1,9)-1),'')='Y' THEN 1 ELSE 0 END) as REIMUBURSE_OUTPUT_VAT,
	(CASE WHEN isnull(substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,10)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,11)-dbo.CHARINDEX_NTH('-',@cTerms,1,10)-1),'')='Y' THEN 1 ELSE 0 END) as APPLYCDONTOTAL,
	(CASE WHEN isnull(substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,11)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,12)-dbo.CHARINDEX_NTH('-',@cTerms,1,11)-1),'')='Y' THEN 1 ELSE 0 END) as EOSS_DISCOUNT_SHARE,
	substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,12)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,13)-dbo.CHARINDEX_NTH('-',@cTerms,1,12)-1) as EOSS_DISCOUNT_PER,
	substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,14)+1,
			dbo.CHARINDEX_NTH('-',@cTerms,1,15)-dbo.CHARINDEX_NTH('-',@cTerms,1,14)-1) as FIX_MRP_MD_PERCENTAGE,
	(CASE WHEN isnull(substring(@cTerms,dbo.CHARINDEX_NTH('-',@cTerms,1,15)+1,
			len(@cTerms)-dbo.CHARINDEX_NTH('-',@cTerms,1,15)),'')='Y' THEN 1 ELSE 0 END) as REIMUBURSE_OUTPUT_GST
	
	return

END