INSERT sku	( ac_code, article_code, barcode_coding_scheme, basic_purchase_price, BATCH_NO, challan_no, CHALLAN_RECEIPT_DT, dt_created,
 emp_code, er_flag, EXPIRY_DT, FIX_MRP, form_id, gst_percentage, hsn_code, image_name, inv_dt, inv_no, LAST_MODIFIED_ON, last_update, mrp, 
OEM_AC_CODE, ONLINE_PRODUCT_CODE, para1_code, para2_code, para3_code, para4_code, para5_code, para6_code, product_code, product_name, 
purchase_price, receipt_dt, tax_amount, uploaded_to_activstream, VENDOR_EAN_NO, ws_price, XFER_PRICE )  
SELECT distinct '0000000000' ac_code, '00000000' article_code, 1  barcode_coding_scheme, 
0   basic_purchase_price, '' BATCH_NO, '' inv_no,'' CHALLAN_RECEIPT_DT, '' dt_created, '0000000' emp_code, 
1 er_flag, '' as  EXPIRY_DT,0 FIX_MRP, 
'0000000' form_id, 0 gst_percentage,'0000000000' hsn_code, '' image_name,'' inv_dt, '' inv_no, 
 '' LAST_MODIFIED_ON, '' last_update,0  mrp, '' OEM_AC_CODE, '' ONLINE_PRODUCT_CODE, 
 '0000000' para1_code, '0000000'  para2_code, '0000000'  para3_code, '0000000'  para4_code, '0000000' para5_code,
 '0000000'  para6_code, a. product_code, '' product_name, 0 purchase_price,'' receipt_dt, 
 0 tax_amount,0 uploaded_to_activstream, '' VENDOR_EAN_NO, 0  ws_price, 0 XFER_PRICE 
 FROM pid01106 a (NOLOCK) 
 JOIN pim01106 b (NOLOCK) ON a.mrr_id=b.mrr_id
 JOIN article c (NOLOCK) ON c.article_code=a.article_code
 LEFT OUTER JOIN sku (NOLOCK) ON sku.product_code=a.product_code
where sku.product_code is null and a.product_code<>''


