
UPDATE KEYS_PMT SET TABLENAME ='SKU' WHERE TABLENAME ='SKU_REPAIR'


IF NOT EXISTS (SELECT TOP 1 'u' from  PMT01106 WHERE BIN_ID='999')
begin
IF OBJECT_ID('TEMPDB..#TMPSTOCK','U') IS NOT NULL
   DROP TABLE #TMPSTOCK

		SELECT A.DEPT_ID ,A.PRODUCT_CODE ,SUM(A.QUANTITY) AS QTY,A.BIN_ID  INTO #TMPSTOCK
		FROM
		(

		SELECT b.location_code DEPT_ID ,A.PRODUCT_CODE ,A.QUANTITY ,'999' AS BIN_ID 
		 FROM HOLD_BACK_DELIVER_DET A
		JOIN HOLD_BACK_DELIVER_MST B ON A.MEMO_ID=B.MEMO_ID 
		WHERE B.CANCELLED=0 and a.delivered=0 
		--and fin_year >='01121'
		UNION ALL
		SELECT b.location_code AS DEPT_ID ,A.PRODUCT_CODE ,-1*A.QUANTITY ,'999' AS BIN_ID 
		 FROM POST_SALES_JOBWORK_ISSUE_DET A
		JOIN POST_SALES_JOBWORK_ISSUE_MST B ON A.ISSUE_ID=B.ISSUE_ID
		WHERE B.CANCELLED=0 --and fin_year >='01121'
		UNION ALL
		SELECT B.location_code AS DEPT_ID ,A.PRODUCT_CODE ,A.QUANTITY ,'999' AS BIN_ID 
		FROM POST_SALES_JOBWORK_RECEIPT_DET A
		JOIN POST_SALES_JOBWORK_RECEIPT_MST B ON A.RECEIPT_ID=B.RECEIPT_ID
		WHERE B.CANCELLED=0 
		--and fin_year >='01121'
		UNION ALL
		SELECT B.location_code AS DEPT_ID ,A.PRODUCT_CODE ,-1*A.QUANTITY ,'999' AS BIN_ID  
		FROM SLS_DELIVERY_DET A
		JOIN SLS_DELIVERY_MST B ON A.MEMO_ID =B.MEMO_ID 
		WHERE B.CANCELLED=0 
		--and fin_year ='01121'
		) A
		GROUP BY A.DEPT_ID ,A.PRODUCT_CODE ,A.BIN_ID 
		--HAVING SUM(A.QUANTITY)<>0


	 INSERT sku	( ac_code, article_code, barcode_coding_scheme, basic_purchase_price, BATCH_NO, challan_no, CHALLAN_RECEIPT_DT, dt_created, emp_code, er_flag, EXPIRY_DT, FIX_MRP, form_id, gst_percentage, hsn_code, image_name, inv_dt, inv_no, LAST_MODIFIED_ON, last_update, mrp, OEM_AC_CODE, ONLINE_PRODUCT_CODE, para1_code, para2_code, para3_code, para4_code, para5_code, para6_code, product_code, product_name, purchase_price, receipt_dt, tax_amount, uploaded_to_activstream, VENDOR_EAN_NO, ws_price, XFER_PRICE ) 
	  SELECT  distinct 	'0000000000'  ac_code, isnull(b.article_code,'00000000 ') as article_code , 3 barcode_coding_scheme,0 basic_purchase_price,'' BATCH_NO,'' challan_no, '' CHALLAN_RECEIPT_DT,
	  '' dt_created,'0000000' emp_code,1 er_flag,'' EXPIRY_DT,0 FIX_MRP,'0000000' form_id,0 gst_percentage,'0000000000' hsn_code,'' image_name,'' inv_dt,'' inv_no,'' LAST_MODIFIED_ON,
	  getdate()  last_update,0 mrp,'0000000000' OEM_AC_CODE,'' ONLINE_PRODUCT_CODE,
	  '0000000' para1_code,'0000000' para2_code,'0000000' para3_code,'0000000' para4_code,'0000000' para5_code,'0000000' para6_code, 
	   a.product_code,'' product_name,0 purchase_price,'' receipt_dt,0 tax_amount,0 uploaded_to_activstream,'' VENDOR_EAN_NO,0 ws_price,
	   0 XFER_PRICE 
	   from #TMPSTOCK a
	   left join sku_repair b on a.product_code=b.product_code
	   left join sku sku on a.product_code =sku.product_code 
	   where sku.product_code is null

	 
	
	 INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK ) 
  
  
	  SELECT 	  a.BIN_ID, a.DEPT_ID,'' DEPT_ID_NOT_STUFFED,GETDATE () last_update,a. product_code,QTY quantity_in_stock, '' rep_id,0 STOCK_RECO_QUANTITY_IN_STOCK 
	  FROM #TMPSTOCK a
	  left join pmt01106 b on a.product_code =b.product_code and a.DEPT_ID =b.DEPT_ID and a.BIN_ID =b.BIN_ID 
	  where b.product_code is null
	  and a.QTY>0 
	

end












