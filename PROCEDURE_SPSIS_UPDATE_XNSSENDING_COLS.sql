create PROCEDURE SPSIS_UPDATE_XNSSENDING_COLS
AS
BEGIN
	TRUNCATE TABLE ebo_xnssending_cols

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'cmm01106',	'BIN_ID'	 UNION ALL
	SELECT 'cmm01106',	'CM_NO'	 UNION ALL
	SELECT 'cmm01106',	'CM_DT'	 UNION ALL
	SELECT 'cmm01106',	'CM_MODE'	 UNION ALL
	SELECT 'cmm01106',	'SUBTOTAL'	 UNION ALL
	SELECT 'cmm01106',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'cmm01106',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'cmm01106',	'NET_AMOUNT'	 UNION ALL
	SELECT 'cmm01106',	'CUSTOMER_CODE'	 UNION ALL
	SELECT 'cmm01106',	'CANCELLED'	 UNION ALL
	SELECT 'cmm01106',	'LAST_UPDATE'	 UNION ALL
	SELECT 'cmm01106',	'cm_id'	 UNION ALL
	SELECT 'cmm01106',	'location_code'	 UNION ALL
	SELECT 'cmm01106',	'fin_year'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'cmd01106',	'basic_discount_percentage'	 UNION ALL
	SELECT 'cmd01106',	'card_discount_percentage'	 UNION ALL
	SELECT 'cmd01106',	'basic_discount_amount'	 UNION ALL
	SELECT 'cmd01106',	'card_discount_amount'	 UNION ALL
	SELECT 'cmd01106',	'scheme_name'	 UNION ALL
	SELECT 'cmd01106',	'hsn_code'	 UNION ALL
	SELECT 'cmd01106',	'gst_percentage'	 UNION ALL
	SELECT 'cmd01106',	'igst_amount'	 UNION ALL
	SELECT 'cmd01106',	'cgst_amount'	 UNION ALL
	SELECT 'cmd01106',	'sgst_amount'	 UNION ALL
	SELECT 'cmd01106',	'xn_value_without_gst'	 UNION ALL
	SELECT 'cmd01106',	'xn_value_with_gst'	 UNION ALL
	SELECT 'cmd01106',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'cmd01106',	'QUANTITY'	 UNION ALL
	SELECT 'cmd01106',	'MRP'	 UNION ALL
	SELECT 'cmd01106',	'NET'	 UNION ALL
	SELECT 'cmd01106',	'discount_percentage'	 UNION ALL
	SELECT 'cmd01106',	'discount_amount'	 UNION ALL
	SELECT 'cmd01106',	'cmm_discount_amount'	 UNION ALL
	SELECT 'cmd01106',	'ROW_ID'	 UNION ALL
	SELECT 'cmd01106',	'LAST_UPDATE'	 UNION ALL
	SELECT 'cmd01106',	'cm_id'	 

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'PIM01106',	'memo_type'	 UNION ALL
	SELECT 'PIM01106',	'INV_MODE'	 UNION ALL
	SELECT 'PIM01106',	'BIN_ID'	 UNION ALL
	SELECT 'PIM01106',	'last_update'	 UNION ALL
	SELECT 'PIM01106',	'CANCELLED'	 UNION ALL
	SELECT 'PIM01106',	'DEPT_ID'	 UNION ALL
	SELECT 'PIM01106',	'inv_id'	 UNION ALL
	SELECT 'PIM01106',	'other_charges_gst_percentage'	 UNION ALL
	SELECT 'PIM01106',	'other_charges_hsn_code'	 UNION ALL
	SELECT 'PIM01106',	'other_charges_igst_amount'	 UNION ALL
	SELECT 'PIM01106',	'other_charges_cgst_amount'	 UNION ALL
	SELECT 'PIM01106',	'other_charges_sgst_amount'	 UNION ALL
	SELECT 'PIM01106',	'freight_gst_percentage'	 UNION ALL
	SELECT 'PIM01106',	'freight_hsn_code'	 UNION ALL
	SELECT 'PIM01106',	'freight_igst_amount'	 UNION ALL
	SELECT 'PIM01106',	'freight_cgst_amount'	 UNION ALL
	SELECT 'PIM01106',	'freight_sgst_amount'	 UNION ALL
	SELECT 'PIM01106',	'TOTAL_QUANTITY'	 UNION ALL
	SELECT 'PIM01106',	'OH_TAX_METHOD'	 UNION ALL
	SELECT 'PIM01106',	'FREIGHT_TAXABLE_VALUE'	 UNION ALL
	SELECT 'PIM01106',	'OTHER_CHARGES_TAXABLE_VALUE'	 UNION ALL
	SELECT 'PIM01106',	'MRR_DT'	 UNION ALL
	SELECT 'PIM01106',	'RECEIPT_DT'	 UNION ALL
	SELECT 'PIM01106',	'mrr_id'	 UNION ALL
	SELECT 'PIM01106',	'fin_year'	 UNION ALL
	SELECT 'PIM01106',	'mrr_no'	 UNION ALL
	SELECT 'PIM01106',	'ac_code'	 UNION ALL
	SELECT 'PIM01106',	'total_amount'	 UNION ALL
	SELECT 'PIM01106',	'subtotal'	 UNION ALL
	SELECT 'PIM01106',	'discount_percentage'	 UNION ALL
	SELECT 'PIM01106',	'discount_amount'	 UNION ALL
	SELECT 'PIM01106',	'other_charges'	 UNION ALL
	SELECT 'PIM01106',	'freight'	 UNION ALL
	SELECT 'PIM01106',	'location_code'	 UNION ALL
	SELECT 'PIM01106',	'round_off'	 


	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'PID01106',	'quantity'	 UNION ALL
	SELECT 'PID01106',	'purchase_price'	 UNION ALL
	SELECT 'PID01106',	'mrp'	 UNION ALL
	SELECT 'PID01106',	'wholesale_price'	 UNION ALL
	SELECT 'PID01106',	'gross_purchase_price'	 UNION ALL
	SELECT 'PID01106',	'discount_percentage'	 UNION ALL
	SELECT 'PID01106',	'discount_amount'	 UNION ALL
	SELECT 'PID01106',	'pimdiscountamount'	 UNION ALL

	SELECT 'PID01106',	'product_code'	 UNION ALL
	SELECT 'PID01106',	'row_id'	 UNION ALL
	SELECT 'PID01106',	'mrr_id'	 UNION ALL
	SELECT 'PID01106',	'invoice_quantity'	 UNION ALL
	SELECT 'PID01106',	'hsn_code'	 UNION ALL
	SELECT 'PID01106',	'gst_percentage'	 UNION ALL
	SELECT 'PID01106',	'igst_amount'	 UNION ALL
	SELECT 'PID01106',	'cgst_amount'	 UNION ALL
	SELECT 'PID01106',	'sgst_amount'	 UNION ALL
	SELECT 'PID01106',	'xn_value_without_gst'	 UNION ALL
	SELECT 'PID01106',	'xn_value_with_gst'	 UNION ALL
	SELECT 'PID01106',	'Gst_Cess_Percentage'	 UNION ALL
	SELECT 'PID01106',	'Gst_Cess_Amount'	 

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'INM01106',	'party_state_code'	 UNION ALL
	SELECT 'INM01106',	'other_charges_gst_percentage'	 UNION ALL
	SELECT 'INM01106',	'other_charges_hsn_code'	 UNION ALL
	SELECT 'INM01106',	'other_charges_igst_amount'	 UNION ALL
	SELECT 'INM01106',	'other_charges_cgst_amount'	 UNION ALL
	SELECT 'INM01106',	'other_charges_sgst_amount'	 UNION ALL
	SELECT 'INM01106',	'freight_gst_percentage'	 UNION ALL
	SELECT 'INM01106',	'freight_hsn_code'	 UNION ALL
	SELECT 'INM01106',	'freight_igst_amount'	 UNION ALL
	SELECT 'INM01106',	'freight_cgst_amount'	 UNION ALL
	SELECT 'INM01106',	'freight_sgst_amount'	 UNION ALL
	SELECT 'INM01106',	'insurance_gst_percentage'	 UNION ALL
	SELECT 'INM01106',	'insurance_hsn_code'	 UNION ALL
	SELECT 'INM01106',	'insurance_igst_amount'	 UNION ALL
	SELECT 'INM01106',	'insurance_cgst_amount'	 UNION ALL
	SELECT 'INM01106',	'insurance_sgst_amount'	 UNION ALL
	SELECT 'INM01106',	'packing_gst_percentage'	 UNION ALL
	SELECT 'INM01106',	'packing_hsn_code'	 UNION ALL
	SELECT 'INM01106',	'packing_igst_amount'	 UNION ALL
	SELECT 'INM01106',	'packing_cgst_amount'	 UNION ALL
	SELECT 'INM01106',	'packing_sgst_amount'	 UNION ALL
	SELECT 'INM01106',	'TOTAL_QUANTITY'	 UNION ALL
	SELECT 'INM01106',	'FREIGHT_TAXABLE_VALUE'	 UNION ALL
	SELECT 'INM01106',	'OTHER_CHARGES_TAXABLE_VALUE'	 UNION ALL
	SELECT 'INM01106',	'INSURANCE_TAXABLE_VALUE'	 UNION ALL
	SELECT 'INM01106',	'PACKING_TAXABLE_VALUE'	 UNION ALL
	SELECT 'INM01106',	'bill_level_tax_method'	 UNION ALL
	SELECT 'INM01106',	'INV_ID'	 UNION ALL
	SELECT 'INM01106',	'ac_code'	 UNION ALL
	SELECT 'INM01106',	'INV_NO'	 UNION ALL
	SELECT 'INM01106',	'INV_DT'	 UNION ALL
	SELECT 'INM01106',	'SUBTOTAL'	 UNION ALL
	SELECT 'INM01106',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'INM01106',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'INM01106',	'FREIGHT'	 UNION ALL
	SELECT 'INM01106',	'LAST_UPDATE'	 UNION ALL
	SELECT 'INM01106',	'PACKING'	 UNION ALL
	SELECT 'INM01106',	'OTHER_CHARGES'	 UNION ALL
	SELECT 'INM01106',	'NET_AMOUNT'	 UNION ALL
	SELECT 'INM01106',	'ROUND_OFF'	 UNION ALL
	SELECT 'INM01106',	'CANCELLED'	 UNION ALL
	SELECT 'INM01106',	'inv_mode'	 UNION ALL
	SELECT 'INM01106',	'party_dept_id'	 UNION ALL
	SELECT 'INM01106',	'Tcs_BaseAmount'	 UNION ALL
	SELECT 'INM01106',	'Tcs_Percentage'	 UNION ALL
	SELECT 'INM01106',	'location_code'	 UNION ALL
	SELECT 'INM01106',	'Tcs_Amount'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'IND01106',	'INV_ID'	 UNION ALL
	SELECT 'IND01106',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'IND01106',	'QUANTITY'	 UNION ALL
	SELECT 'IND01106',	'RATE'	 UNION ALL
	SELECT 'IND01106',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'IND01106',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'IND01106',	'ROW_ID'	 UNION ALL
	SELECT 'IND01106',	'net_rate'	 UNION ALL
	SELECT 'IND01106',	'gross_rate'	 UNION ALL
	SELECT 'IND01106',	'hsn_code'	 UNION ALL
	SELECT 'IND01106',	'gst_percentage'	 UNION ALL
	SELECT 'IND01106',	'igst_amount'	 UNION ALL
	SELECT 'IND01106',	'cgst_amount'	 UNION ALL
	SELECT 'IND01106',	'sgst_amount'	 UNION ALL
	SELECT 'IND01106',	'xn_value_without_gst'	 UNION ALL
	SELECT 'IND01106',	'xn_value_with_gst'	 UNION ALL
	SELECT 'IND01106',	'Gst_Cess_Percentage'	 UNION ALL
	SELECT 'IND01106',	'Gst_Cess_Amount'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'RMM01106',	'mode'	 UNION ALL
	SELECT 'RMM01106',	'party_dept_id'	 UNION ALL
	SELECT 'RMM01106',	'rm_no'	 UNION ALL
	SELECT 'RMM01106',	'rm_dt'	 UNION ALL
	SELECT 'RMM01106',	'ac_code'	 UNION ALL
	SELECT 'RMM01106',	'total_amount'	 UNION ALL
	SELECT 'RMM01106',	'subtotal'	 UNION ALL
	SELECT 'RMM01106',	'discount_percentage'	 UNION ALL
	SELECT 'RMM01106',	'discount_amount'	 UNION ALL
	SELECT 'RMM01106',	'other_charges'	 UNION ALL
	SELECT 'RMM01106',	'freight'	 UNION ALL
	SELECT 'RMM01106',	'last_update'	 UNION ALL
	SELECT 'RMM01106',	'CANCELLED'	 UNION ALL
	SELECT 'RMM01106',	'rm_id'	 UNION ALL
	SELECT 'RMM01106',	'fin_year'	 UNION ALL
	SELECT 'RMM01106',	'other_charges_gst_percentage'	 UNION ALL
	SELECT 'RMM01106',	'other_charges_hsn_code'	 UNION ALL
	SELECT 'RMM01106',	'other_charges_igst_amount'	 UNION ALL
	SELECT 'RMM01106',	'other_charges_cgst_amount'	 UNION ALL
	SELECT 'RMM01106',	'other_charges_sgst_amount'	 UNION ALL
	SELECT 'RMM01106',	'freight_gst_percentage'	 UNION ALL
	SELECT 'RMM01106',	'freight_hsn_code'	 UNION ALL
	SELECT 'RMM01106',	'freight_igst_amount'	 UNION ALL
	SELECT 'RMM01106',	'freight_cgst_amount'	 UNION ALL
	SELECT 'RMM01106',	'freight_sgst_amount'	 UNION ALL
	SELECT 'RMM01106',	'TOTAL_QUANTITY'	 UNION ALL
	SELECT 'RMM01106',	'FREIGHT_TAXABLE_VALUE'	 UNION ALL
	SELECT 'RMM01106',	'OTHER_CHARGES_TAXABLE_VALUE'	 UNION ALL
	SELECT 'RMM01106',	'location_code'	 UNION ALL
	SELECT 'RMM01106',	'XN_ITEM_TYPE'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'RMD01106',	'hsn_code'	 UNION ALL
	SELECT 'RMD01106',	'gst_percentage'	 UNION ALL
	SELECT 'RMD01106',	'igst_amount'	 UNION ALL
	SELECT 'RMD01106',	'cgst_amount'	 UNION ALL
	SELECT 'RMD01106',	'sgst_amount'	 UNION ALL
	SELECT 'RMD01106',	'xn_value_without_gst'	 UNION ALL
	SELECT 'RMD01106',	'xn_value_with_gst'	 UNION ALL
	SELECT 'RMD01106',	'product_code'	 UNION ALL
	SELECT 'RMD01106',	'quantity'	 UNION ALL
	SELECT 'RMD01106',	'purchase_price'	 UNION ALL
	SELECT 'RMD01106',	'row_id'	 UNION ALL
	SELECT 'RMD01106',	'rm_id'	 UNION ALL
	SELECT 'RMD01106',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'RMD01106',	'DISCOUNT_amount'	 UNION ALL
	SELECT 'RMD01106',	'gross_purchase_price'	 UNION ALL
	SELECT 'RMD01106',	'Gst_Cess_Percentage'	 UNION ALL
	SELECT 'RMD01106',	'Gst_Cess_Amount'	
	
	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'CNM01106',	'cn_no'	 UNION ALL
	SELECT 'CNM01106',	'cn_dt'	 UNION ALL
	SELECT 'CNM01106',	'ac_code'	 UNION ALL
	SELECT 'CNM01106',	'subtotal'	 UNION ALL
	SELECT 'CNM01106',	'discount_percentage'	 UNION ALL
	SELECT 'CNM01106',	'discount_amount'	 UNION ALL
	SELECT 'CNM01106',	'other_charges'	 UNION ALL
	SELECT 'CNM01106',	'freight'	 UNION ALL
	SELECT 'CNM01106',	'round_off'	 UNION ALL
	SELECT 'CNM01106',	'total_amount'	 UNION ALL
	SELECT 'CNM01106',	'cancelled'	 UNION ALL
	SELECT 'CNM01106',	'insurance'	 UNION ALL
	SELECT 'CNM01106',	'rm_id'	 UNION ALL
	SELECT 'CNM01106',	'party_state_code'	 UNION ALL
	SELECT 'CNM01106',	'other_charges_gst_percentage'	 UNION ALL
	SELECT 'CNM01106',	'other_charges_hsn_code'	 UNION ALL
	SELECT 'CNM01106',	'other_charges_igst_amount'	 UNION ALL
	SELECT 'CNM01106',	'other_charges_cgst_amount'	 UNION ALL
	SELECT 'CNM01106',	'other_charges_sgst_amount'	 UNION ALL
	SELECT 'CNM01106',	'freight_gst_percentage'	 UNION ALL
	SELECT 'CNM01106',	'freight_hsn_code'	 UNION ALL
	SELECT 'CNM01106',	'freight_igst_amount'	 UNION ALL
	SELECT 'CNM01106',	'freight_cgst_amount'	 UNION ALL
	SELECT 'CNM01106',	'freight_sgst_amount'	 UNION ALL
	SELECT 'CNM01106',	'insurance_gst_percentage'	 UNION ALL
	SELECT 'CNM01106',	'insurance_hsn_code'	 UNION ALL
	SELECT 'CNM01106',	'insurance_igst_amount'	 UNION ALL
	SELECT 'CNM01106',	'insurance_cgst_amount'	 UNION ALL
	SELECT 'CNM01106',	'insurance_sgst_amount'	 UNION ALL
	SELECT 'CNM01106',	'TOTAL_QUANTITY'	 UNION ALL
	SELECT 'CNM01106',	'FREIGHT_TAXABLE_VALUE'	 UNION ALL
	SELECT 'CNM01106',	'OTHER_CHARGES_TAXABLE_VALUE'	 UNION ALL
	SELECT 'CNM01106',	'INSURANCE_TAXABLE_VALUE'	 UNION ALL
	SELECT 'CNM01106',	'last_update'	 UNION ALL
	SELECT 'CNM01106',	'cn_id'	 UNION ALL
	SELECT 'CNM01106',	'fin_year'	 UNION ALL
	SELECT 'CNM01106',	'party_dept_id'	 UNION ALL
	SELECT 'CNM01106',	'mode'	 UNION ALL
	SELECT 'CNM01106',	'location_code'	 UNION ALL
	SELECT 'CNM01106',	'receipt_dt'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'CND01106',	'gross_rate'	 UNION ALL
	SELECT 'CND01106',	'RATE'	 UNION ALL
	SELECT 'CND01106',	'discount_percentage'	 UNION ALL
	SELECT 'CND01106',	'discount_amount'	 UNION ALL
	SELECT 'CND01106',	'net_rate'	 UNION ALL
	SELECT 'CND01106',	'product_code'	 UNION ALL
	SELECT 'CND01106',	'quantity'	 UNION ALL
	SELECT 'CND01106',	'row_id'	 UNION ALL
	SELECT 'CND01106',	'cn_id'	 UNION ALL
	SELECT 'CND01106',	'hsn_code'	 UNION ALL
	SELECT 'CND01106',	'gst_percentage'	 UNION ALL
	SELECT 'CND01106',	'igst_amount'	 UNION ALL
	SELECT 'CND01106',	'cgst_amount'	 UNION ALL
	SELECT 'CND01106',	'sgst_amount'	 UNION ALL
	SELECT 'CND01106',	'xn_value_without_gst'	 UNION ALL
	SELECT 'CND01106',	'xn_value_with_gst'	 UNION ALL
	SELECT 'CND01106',	'Gst_Cess_Percentage'	 UNION ALL
	SELECT 'CND01106',	'Gst_Cess_Amount'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'APM01106',	'DEPT_ID'	 UNION ALL
	SELECT 'APM01106',	'MEMO_NO'	 UNION ALL
	SELECT 'APM01106',	'MEMO_DT'	 UNION ALL
	SELECT 'APM01106',	'SUBTOTAL'	 UNION ALL
	SELECT 'APM01106',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'APM01106',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'APM01106',	'NET_AMOUNT'	 UNION ALL
	SELECT 'APM01106',	'CANCELLED'	 UNION ALL
	SELECT 'APM01106',	'LAST_UPDATE'	 UNION ALL
	SELECT 'APM01106',	'memo_id'	 UNION ALL
	SELECT 'APM01106',	'fin_year'	 UNION ALL
	SELECT 'APM01106',	'atd_charges'	 UNION ALL
	SELECT 'APM01106',	'location_code'	 UNION ALL
	SELECT 'APM01106',	'total_quantity'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'APD01106',	'discount_percentage'	 UNION ALL
	SELECT 'APD01106',	'discount_amount'	 UNION ALL
	SELECT 'APD01106',	'memo_id'	 UNION ALL
	SELECT 'APD01106',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'APD01106',	'QUANTITY'	 UNION ALL
	SELECT 'APD01106',	'MRP'	 UNION ALL
	SELECT 'APD01106',	'NET'	 UNION ALL
	SELECT 'APD01106',	'ROW_ID'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'APPROVAL_RETURN_MST',	'memo_id'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'memo_no'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'memo_dt'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'last_update'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'cancelled'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'fin_year'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'location_code'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'total_quantity'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'APPROVAL_RETURN_DET',	'memo_id'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'QUANTITY'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'row_id'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'APD_PRODUCT_CODE'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'ICM01106',	'cnc_memo_no'	 UNION ALL
	SELECT 'ICM01106',	'cnc_memo_dt'	 UNION ALL
	SELECT 'ICM01106',	'cancelled'	 UNION ALL
	SELECT 'ICM01106',	'cnc_type'	 UNION ALL
	SELECT 'ICM01106',	'total_amount'	 UNION ALL
	SELECT 'ICM01106',	'last_update'	 UNION ALL
	SELECT 'ICM01106',	'cnc_memo_id'	 UNION ALL
	SELECT 'ICM01106',	'fin_year'	 UNION ALL
	SELECT 'ICM01106',	'cnc_dt'	 UNION ALL
	SELECT 'ICM01106',	'location_code'	 UNION ALL
	SELECT 'ICM01106',	'total_quantity'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'ICD01106',	'product_code'	 UNION ALL
	SELECT 'ICD01106',	'quantity'	 UNION ALL
	SELECT 'ICD01106',	'row_id'	 UNION ALL
	SELECT 'ICD01106',	'cnc_memo_id'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'GRN_PS_MST',	'MEMO_ID'	 UNION ALL
	SELECT 'GRN_PS_MST',	'MEMO_NO'	 UNION ALL
	SELECT 'GRN_PS_MST',	'MEMO_DT'	 UNION ALL
	SELECT 'GRN_PS_MST',	'CANCELLED'	 UNION ALL
	SELECT 'GRN_PS_MST',	'LAST_UPDATE'	 UNION ALL
	SELECT 'GRN_PS_MST',	'FIN_YEAR'	 UNION ALL
	SELECT 'GRN_PS_MST',	'location_code'	 UNION ALL
	SELECT 'GRN_PS_MST',	'TOTAL_QUANTITY'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'GRN_PS_DET',	'MEMO_ID'	 UNION ALL
	SELECT 'GRN_PS_DET',	'QUANTITY'	 UNION ALL
	SELECT 'GRN_PS_DET',	'ROW_ID'	 UNION ALL
	SELECT 'GRN_PS_DET',	'PRODUCT_CODE'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'JOBWORK_ISSUE_MST',	'issue_no'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'issue_dt'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'cancelled'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'last_update'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'issue_id'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'fin_year'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'subtotal'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'discount_percentage'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'discount_amount'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'round_off'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'total_amount'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'location_code'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'total_quantity'	


	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'JOBWORK_ISSUE_DET',	'product_code'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'quantity'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'row_id'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'issue_id'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'hsn_code'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'gst_percentage'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'igst_amount'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'cgst_amount'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'sgst_amount'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'xn_value_without_gst'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'xn_value_with_gst'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'JOBWORK_RECEIPT_MST',	'last_update'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'receipt_id'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'fin_year'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'receipt_no'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'receipt_dt'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'cancelled'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'subtotal'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'tds'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'other_charges'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'net_amount'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'location_code'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'total_quantity'	 


	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'JOBWORK_RECEIPT_DET',	'product_code'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'quantity'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'row_id'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'hsn_code'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'gst_percentage'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'igst_amount'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'cgst_amount'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'sgst_amount'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'xn_value_without_gst'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'xn_value_with_gst'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'CESS_AMOUNT'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'Gst_Cess_Percentage'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'Gst_Cess_Amount'	

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'WPS_MST',	'ps_id'	 UNION ALL
	SELECT 'WPS_MST',	'ps_no'	 UNION ALL
	SELECT 'WPS_MST',	'ps_dt'	 UNION ALL
	SELECT 'WPS_MST',	'SUBTOTAL'	 UNION ALL
	SELECT 'WPS_MST',	'CANCELLED'	 UNION ALL
	SELECT 'WPS_MST',	'location_code'	 UNION ALL
	SELECT 'WPS_MST',	'TOTAL_QUANTITY'
	
	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'WPS_DET',	'ps_id'	 UNION ALL
	SELECT 'WPS_DET',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'WPS_DET',	'QUANTITY'	 UNION ALL
	SELECT 'WPS_DET',	'RATE'	 UNION ALL
	SELECT 'WPS_DET',	'ROW_ID'	 


	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'RPS_MST',	'CM_NO'	 UNION ALL
	SELECT 'RPS_MST',	'CM_DT'	 UNION ALL
	SELECT 'RPS_MST',	'SUBTOTAL'	 UNION ALL
	SELECT 'RPS_MST',	'NET_AMOUNT'	 UNION ALL
	SELECT 'RPS_MST',	'CANCELLED'	 UNION ALL
	SELECT 'RPS_MST',	'cm_id'	 UNION ALL
	SELECT 'RPS_MST',	'fin_year'	 UNION ALL
	SELECT 'RPS_MST',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'RPS_MST',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'RPS_MST',	'atd_charges'	 UNION ALL
	SELECT 'RPS_MST',	'location_code'	 UNION ALL
	SELECT 'RPS_MST',	'total_quantity'

	INSERT INTO ebo_xnssending_cols (tablename,colname)
	SELECT 'RPS_DET',	'cm_id'	 UNION ALL
	SELECT 'RPS_DET',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'RPS_DET',	'QUANTITY'	 UNION ALL
	SELECT 'RPS_DET',	'MRP'	 UNION ALL
	SELECT 'RPS_DET',	'NET'	 UNION ALL
	SELECT 'RPS_DET',	'ROW_ID'	 UNION ALL
	SELECT 'RPS_DET',	'basic_discount_percentage'	 UNION ALL
	SELECT 'RPS_DET',	'card_discount_percentage'	 UNION ALL
	SELECT 'RPS_DET',	'basic_discount_amount'	 UNION ALL
	SELECT 'RPS_DET',	'card_discount_amount'	

	INSERT EBO_XNSSENDING_COLS	(tablename, colname )  
	SELECT TABLENAME TABLENAME,'QUANTITY_LAST_UPDATE' AS COLNAME  
	FROM EBO_XNSSENDING_COLS A
	JOIN INFORMATION_SCHEMA .COLUMNS B  ON A.TABLENAME =B.TABLE_NAME 
	WHERE  B.COLUMN_NAME='QUANTITY_LAST_UPDATE'
	GROUP BY TABLENAME


END
