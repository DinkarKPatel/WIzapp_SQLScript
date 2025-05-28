CREATE TRIGGER [DBO].[TRG_UPD_SKU_OH_LAST_MODIFIED_ON] ON [DBO].[SKU_OH]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.product_code,'sku' FROM DELETED a
	JOIN INSERTED b ON b.product_code=a.product_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.product_code=df.master_code AND df.master_tablename='sku'	
	WHERE (a.discount_amount <> B.discount_amount OR a.tax_amount <> B.tax_amount OR
	a.freight <> B.freight OR a.other_charges <> B.other_charges OR a.round_off <> B.round_off OR
	a.value_add <> B.value_add OR a.excise_duty_amount <> B.excise_duty_amount OR 
	a.depreciation <> B.depreciation OR a.Gst_Cess_Amount<>B.Gst_Cess_Amount)
	AND df.master_code IS NULL

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
			
	UPDATE SKU_OH SET LAST_MODIFIED_ON=CAST(GETDATE() AS DATE) 
	FROM DELETED B WHERE B.PRODUCT_CODE=sku_oh.PRODUCT_CODE
	AND (sku_oh.discount_amount <> B.discount_amount OR sku_oh.tax_amount <> B.tax_amount OR
	sku_oh.freight <> B.freight OR sku_oh.other_charges <> B.other_charges OR sku_oh.round_off <> B.round_off OR
	sku_oh.value_add <> B.value_add OR sku_oh.excise_duty_amount <> B.excise_duty_amount OR 
	sku_oh.depreciation <> B.depreciation OR sku_oh.Gst_Cess_Amount<>B.Gst_Cess_Amount)
END
