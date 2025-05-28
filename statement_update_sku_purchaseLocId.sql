update sku set purchaseLocId=c.dept_id FROM sku JOIN pid01106 b on b.product_code=sku.product_code
JOIN pim01106 c on c.mrr_id=b.mrr_id
where c.INV_MODE=1 AND purchaseLocId IS NULL

update sku set purchaseLocId=c.purchaseLocId FROM sku JOIN ird01106 b on b.new_product_code=sku.product_code
JOIN sku c (NOLOCK) ON c.product_code=b.product_code
WHERE sku.purchaseLocId IS NULL
/*Rohit 01-11-2024
update sku set purchaseLocId=LEFT(c.memo_id,2) 
FROM sku 
JOIN snc_barcode_det b ON b.PRODUCT_CODE=sku.product_code
JOIN snc_det c on c.ROW_ID=b.REFROW_ID
WHERE sku.purchaseLocId IS NULL
*/
update sku set purchaseLocId=c1.location_Code
FROM sku 
JOIN snc_barcode_det b ON b.PRODUCT_CODE=sku.product_code
JOIN snc_det c on c.ROW_ID=b.REFROW_ID
JOIN snc_mst c1 on c.MEMO_ID=c1.MEMO_ID
WHERE sku.purchaseLocId IS NULL

update sku set purchaseLocId=b.value FROM sku JOIN CONFIG B ON 1=1
where b.config_option='ho_location_id' AND ISNULL(purchaseLocId,'')=''


update sku_names set purloc_pan_no=loc.pan_no FROM sku_names 
JOIN sku (NOLOCK) ON sku.product_code=sku_names.product_Code
JOIN location loc (NOLOCK) ON loc.dept_id=sku.purchaseLocId
WHERE purloc_pan_no IS NULL


