CREATE PROCEDURE SP3S_GET_LINKBARCODES
@cProductCode VARCHAR(50)
AS
BEGIN
	select product_code,new_product_code from ird01106 (nolock) where new_product_code = @cProductCode OR 
	product_code = @cProductCode
	UNION 
	select c.product_code ,a.PRODUCT_CODE  as new_product_code  from snc_barcode_det a (nolock)  
	join SNC_DET b  (nolock) on a.REFROW_ID = b.ROW_ID   
	join SNC_CONSUMABLE_DET c (nolock) on b.MEMO_ID = c.MEMO_ID     
	where a.PRODUCT_CODE=@cProductCode
	UNION 
	select c.product_code ,a.PRODUCT_CODE  as new_product_code  from snc_barcode_det a (nolock)  
	join SNC_DET b  (nolock) on a.REFROW_ID = b.ROW_ID   
	join SNC_CONSUMABLE_DET c (nolock) on b.MEMO_ID = c.MEMO_ID     
	where c.PRODUCT_CODE=@cProductCode
END

