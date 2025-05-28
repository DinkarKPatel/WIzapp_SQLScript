CREATE TRIGGER [DBO].[TRG_UPD_SKU_LAST_MODIFIED_ON] ON [DBO].[SKU]  --- Do not verwrite in May2022 Release Folder	
	FOR UPDATE
	AS
begin
		INSERT INTO opt_sku_diff (master_code,master_tablename)
		SELECT a.product_code,'sku' master_tablename FROM DELETED a
		LEFT JOIN  opt_sku_diff b (NOLOCK) ON a.product_code=b.master_code AND b.master_tablename='sku'
		WHERE b.master_code IS NULL

		IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
			RETURN
					
		UPDATE SKU SET LAST_MODIFIED_ON=GETDATE() 
		FROM DELETED B WHERE B.PRODUCT_CODE=SKU.PRODUCT_CODE
		AND (SKU.purchase_price<>b.purchase_price OR SKU.inv_dt<>b.inv_dt 
		OR SKU.inv_no<>b.inv_no OR SKU.ac_code<>b.ac_code OR SKU.receipt_dt<>b.receipt_dt 
		OR SKU.mrp<>b.mrp OR SKU.ws_price<>b.ws_price 
		OR SKU.challan_no<>b.challan_no OR SKU.FIX_MRP<>b.FIX_MRP OR SKU.product_name<>b.product_name 
		OR SKU.er_flag<>b.er_flag OR SKU.barcode_coding_scheme<>b.barcode_coding_scheme OR ISNULL(SKU.VENDOR_EAN_NO,'')<>isnull(b.VENDOR_EAN_NO,'')
		OR SKU.basic_purchase_price<>b.basic_purchase_price OR SKU.hsn_code<>b.hsn_code OR SKU.gst_percentage<>b.gst_percentage 
		OR ISNULL(SKU.BATCH_NO,'')<>ISNULL(b.BATCH_NO,'') OR SKU.EXPIRY_DT<>b.EXPIRY_DT OR ISNULL(SKU.SHIPPING_FROM_AC_CODE,'')<>ISNULL(b.SHIPPING_FROM_AC_CODE,''))
end