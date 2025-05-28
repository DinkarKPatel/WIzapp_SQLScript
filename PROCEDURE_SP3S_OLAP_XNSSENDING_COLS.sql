create PROCEDURE SP3S_olap_xnssending_cols
AS
BEGIN
	

	SELECT * INTO #olap_xnssending_cols FROM olap_xnssending_cols WHERE 1=2

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'cmm01106',	'BIN_ID'	 UNION ALL
	SELECT 'cmm01106',	'user_code'	 UNION ALL
	SELECT 'cmm01106',	'CM_NO'	 UNION ALL
	SELECT 'cmm01106',	'CM_DT'	 UNION ALL
	SELECT 'cmm01106',	'SUBTOTAL'	 UNION ALL
	SELECT 'cmm01106',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'cmm01106',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'cmm01106',	'NET_AMOUNT'	 UNION ALL
	SELECT 'cmm01106',	'CUSTOMER_CODE'	 UNION ALL
	SELECT 'cmm01106',	'CANCELLED'	 UNION ALL
	SELECT 'cmm01106',	'LAST_UPDATE'	 UNION ALL
	SELECT 'cmm01106',	'cm_id'	 UNION ALL
	SELECT 'cmm01106',	'REF_NO'	 UNION ALL
	SELECT 'cmm01106',	'EINV_IRN_NO'	 UNION ALL
	SELECT 'cmm01106',	'ACH_DT'	 UNION ALL
	SELECT 'cmm01106',	'ACH_NO'	 UNION ALL
	SELECT 'cmm01106',	'passport_no' UNION ALL
	SELECT 'cmm01106',	'ticket_no' UNION ALL
	SELECT 'cmm01106',	'dt_code' UNION ALL
	SELECT 'cmm01106',	'atd_charges' UNION ALL
	SELECT 'cmm01106',	'payback' UNION ALL
	SELECT 'cmm01106',	'cash_tendered' UNION ALL
	SELECT 'cmm01106',	'ref_no_paytm' UNION ALL
	SELECT 'cmm01106',	'copies_ptd' UNION ALL
	SELECT 'cmm01106',	'Edit_Count' UNION ALL
	SELECT 'cmm01106',	'fin_year'	
	UNION ALL
	SELECT 'cmm01106',	'remarks'	
	UNION ALL
	SELECT 'cmm01106',	'ecoupon_id'	
	

	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'cmd01106',	'WeightedQtyBillCount'	 UNION ALL
	SELECT 'cmd01106',	'RFNET'	 UNION ALL
	SELECT 'cmd01106',	'gst_cess_amount'	 UNION ALL
	SELECT 'cmd01106',	'tax_mehtod'	 UNION ALL
	SELECT 'cmd01106',	'item_round_off'	 UNION ALL
	SELECT 'cmd01106',	'basic_discount_percentage'	 UNION ALL
	SELECT 'cmd01106',	'selling_days'	 UNION ALL
	SELECT 'cmd01106',	'cmm_discount_amount'	 UNION ALL
	SELECT 'cmd01106',	'sis_net'	 UNION ALL
	SELECT 'cmd01106',	'bin_id'	 UNION ALL
	SELECT 'cmd01106',	'emp_code'	 UNION ALL
	SELECT 'cmd01106',	'emp_code1'	 UNION ALL
	SELECT 'cmd01106',	'emp_code2'	 UNION ALL
	SELECT 'cmd01106',	'scheme_name'	 UNION ALL
	SELECT 'cmd01106',	'card_discount_percentage'	 UNION ALL
	SELECT 'cmd01106',	'basic_discount_amount'	 UNION ALL
	SELECT 'cmd01106',	'card_discount_amount'	 UNION ALL
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
	SELECT 'cmd01106',	'ROW_ID'	 UNION ALL
	SELECT 'cmd01106',	'LAST_UPDATE'	 UNION ALL
	SELECT 'cmd01106',	'rfnet'	 UNION ALL
	SELECT 'cmd01106',	'nrm_id'	 UNION ALL
	SELECT 'cmd01106',	'ref_sls_memo_no'	 UNION ALL
	SELECT 'cmd01106',	'ref_sls_memo_dt'	 UNION ALL
	SELECT 'cmd01106',	'cm_id'	 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'cmd_cons','cm_id'	 UNION ALL
	SELECT 'cmd_cons','product_code'	 UNION ALL
	SELECT 'cmd_cons','quantity'	 UNION ALL
	SELECT 'cmd_cons','row_id'	 UNION ALL
	SELECT 'cmd_cons','bin_id'
	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'PIM01106',	'ref_converted_mrntobill_mrrid'	 UNION ALL
	SELECT 'PIM01106',	'RECEIPT_DT'	 UNION ALL
	SELECT 'PIM01106',	'inv_dt'	 UNION ALL
	SELECT 'PIM01106',	'bill_dt'	 UNION ALL
	SELECT 'PIM01106',	'bill_no'	 UNION ALL
	SELECT 'PIM01106',	'inv_no'	 UNION ALL
	SELECT 'PIM01106',	'pim_mode'	 UNION ALL
	SELECT 'PIM01106',	'dept_id'	 UNION ALL
	SELECT 'PIM01106',	'round_off'	 

	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'PID01106',	'quantity'	 UNION ALL
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
	SELECT 'PID01106',	'tax_round_off'	 UNION ALL
	SELECT 'PID01106',	'discount_amount'	 UNION ALL
	SELECT 'PID01106',	'gross_purchase_price'	 UNION ALL
	SELECT 'PID01106',	'pimdiscountamount'	 UNION ALL
	SELECT 'PID01106',	'purchase_price'	 UNION ALL
	SELECT 'pid01106',	'rfnet'	 UNION ALL
	SELECT 'PID01106',	'Gst_Cess_Amount'	 
	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'INM01106',	'Tcs_BaseAmount'	 UNION ALL
	SELECT 'INM01106',	'Tcs_Percentage'	 UNION ALL
	SELECT 'INM01106',	'EINV_IRN_NO'	 UNION ALL
	SELECT 'INM01106',	'ACH_DT'	 UNION ALL
	SELECT 'INM01106',	'ACH_NO'	 UNION ALL
	SELECT 'INM01106',	'manual_inv_no'	 UNION ALL
	SELECT 'INM01106',	'buyer_order_no'	 UNION ALL
	SELECT 'INM01106',	'bin_id'	 UNION ALL
	SELECT 'INM01106',	'target_bin_id'	 UNION ALL
	SELECT 'INM01106',	'party_dept_id'	 UNION ALL
	SELECT 'INM01106',	'PENDING_GIT'	 UNION ALL
	SELECT 'INM01106',	'bin_transfer'	 UNION ALL
	SELECT 'INM01106',	'entry_mode'	 UNION ALL
	SELECT 'INM01106',	'Tcs_Amount'	
	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'IND01106',	'wsl_selling_days'	 UNION ALL
	SELECT 'IND01106',	'WSL_WeightedQtyBillCount'	 UNION ALL
	SELECT 'IND01106',	'tax_round_off'	 UNION ALL
	SELECT 'IND01106',	'INMDiscountAmount'	 UNION ALL
	SELECT 'IND01106',	'bin_id'	 UNION ALL
	SELECT 'IND01106',	'emp_code'	 UNION ALL
	SELECT 'IND01106',	'emp_code1'	 UNION ALL
	SELECT 'IND01106',	'emp_code2'	 UNION ALL
	SELECT 'ind01106',	'rfnet'	 UNION ALL
	SELECT 'ind01106',	'ps_id'	 UNION ALL
	SELECT 'IND01106',	'Gst_Cess_Amount'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'RMM01106',	'mode'	 UNION ALL
	SELECT 'RMM01106',	'dn_type' UNION ALL
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
	SELECT 'RMM01106',	'EINV_IRN_NO'	 UNION ALL
	SELECT 'RMM01106',	'ACH_DT'	 UNION ALL
	SELECT 'RMM01106',	'ACH_NO'	 UNION ALL
	SELECT 'RMM01106',	'bin_id'	 UNION ALL
	SELECT 'RMM01106',	'target_bin_id'	 UNION ALL
	SELECT 'RMM01106',	'XN_ITEM_TYPE'


	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'RMD01106',	'ps_id'	 UNION ALL
	SELECT 'RMD01106',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'RMD01106',	'DISCOUNT_amount'	 UNION ALL
	SELECT 'RMD01106',	'gross_purchase_price'	 UNION ALL
	SELECT 'RMD01106',	'Gst_Cess_Percentage'	 UNION ALL
	SELECT 'RMD01106',	'tax_round_off'	 UNION ALL
	SELECT 'RMD01106',	'RMMDiscountAmount'	 UNION ALL
	SELECT 'RMD01106',	'bin_id'	 UNION ALL
	SELECT 'rmd01106',	'rfnet'	 UNION ALL
	SELECT 'RMD01106',	'Gst_Cess_Amount'	
	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'CNM01106',	'manual_inv_no'	 UNION ALL
	SELECT 'CNM01106',	'EInv_IRN_NO'	 UNION ALL
	SELECT 'CNM01106',	'ACH_DT'	 UNION ALL
	SELECT 'CNM01106',	'ACH_NO'	 UNION ALL
	SELECT 'CNM01106',	'BIN_ID'	 UNION ALL
	SELECT 'CNM01106',	'BIN_TRANSFER'	 UNION ALL
	SELECT 'cnm01106',	'cn_type' UNION ALL
	SELECT 'CNM01106',	'receipt_dt'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'CND01106',	'Gst_Cess_amount'	 UNION ALL
	SELECT 'CND01106',	'tax_round_off'	 UNION ALL
	SELECT 'CND01106',	'CNMDiscountAmount'	 UNION ALL
	SELECT 'CND01106',	'bin_id'	 UNION ALL
	SELECT 'CND01106',	'emp_code'	 UNION ALL
	SELECT 'CND01106',	'emp_code1'	 UNION ALL
	SELECT 'cnd01106',	'rfnet'	 UNION ALL
	SELECT 'CND01106',	'emp_code2'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'APM01106',	'REF_NO'	 UNION ALL
	SELECT 'APM01106',	'customer_code'	 UNION ALL
	SELECT 'APM01106',	'total_quantity'


	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'APD01106',	'discount_percentage'	 UNION ALL
	SELECT 'APD01106',	'discount_amount'	 UNION ALL
	SELECT 'APD01106',	'memo_id'	 UNION ALL
	SELECT 'APD01106',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'APD01106',	'QUANTITY'	 UNION ALL
	SELECT 'APD01106',	'MRP'	 UNION ALL
	SELECT 'APD01106',	'NET'	 UNION ALL
	SELECT 'APD01106',	'bin_id'	 UNION ALL
	SELECT 'APD01106',	'emp_code'	 UNION ALL
	SELECT 'APD01106',	'emp_code1'	 UNION ALL
	SELECT 'APD01106',	'emp_code2'	 UNION ALL
	SELECT 'apd01106',	'rfnet'	 UNION ALL
	SELECT 'APD01106',	'ROW_ID'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'APPROVAL_RETURN_MST',	'memo_id'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'memo_no'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'memo_dt'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'last_update'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'cancelled'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'fin_year'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'customer_code'	 UNION ALL
	SELECT 'APPROVAL_RETURN_MST',	'total_quantity'

	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'APPROVAL_RETURN_DET',	'memo_id'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'QUANTITY'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'row_id'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'rfnet'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'mrp'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'discount_percentage'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'discount_amount'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'bin_id'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'emp_code'	 UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'apd_row_id' UNION ALL
	SELECT 'APPROVAL_RETURN_DET',	'APD_PRODUCT_CODE'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'ICM01106',	'cnc_memo_no'	 UNION ALL
	SELECT 'ICM01106',	'cnc_memo_dt'	 UNION ALL
	SELECT 'ICM01106',	'cancelled'	 UNION ALL
	SELECT 'ICM01106',	'cnc_type'	 UNION ALL
	SELECT 'ICM01106',	'total_amount'	 UNION ALL
	SELECT 'ICM01106',	'last_update'	 UNION ALL
	SELECT 'ICM01106',	'cnc_memo_id'	 UNION ALL
	SELECT 'ICM01106',	'fin_year'	 UNION ALL
	SELECT 'ICM01106',	'cnc_dt'	 UNION ALL
	SELECT 'ICM01106',	'stock_adj_note'	 UNION ALL
	SELECT 'ICM01106',	'total_quantity'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'ICD01106',	'product_code'	 UNION ALL
	SELECT 'ICD01106',	'quantity'	 UNION ALL
	SELECT 'ICD01106',	'rate'		UNION ALL
	SELECT 'ICD01106',	'row_id'	 UNION ALL
	SELECT 'ICD01106',	'bin_id'	 UNION ALL
	SELECT 'ICD01106',	'cnc_memo_id'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'GRN_PS_MST',	'MEMO_ID'	 UNION ALL
	SELECT 'GRN_PS_MST',	'MEMO_NO'	 UNION ALL
	SELECT 'GRN_PS_MST',	'MEMO_DT'	 UNION ALL
	SELECT 'GRN_PS_MST',	'CANCELLED'	 UNION ALL
	SELECT 'GRN_PS_MST',	'LAST_UPDATE'	 UNION ALL
	SELECT 'GRN_PS_MST',	'FIN_YEAR'	 UNION ALL
	SELECT 'GRN_PS_MST',	'ac_code'	 UNION ALL
	SELECT 'GRN_PS_MST',	'bin_id'	 UNION ALL
	SELECT 'GRN_PS_MST',	'TOTAL_QUANTITY'

	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'GRN_PS_DET',	'MEMO_ID'	 UNION ALL
	SELECT 'GRN_PS_DET',	'QUANTITY'	 UNION ALL
	SELECT 'GRN_PS_DET',	'ROW_ID'	 UNION ALL
	SELECT 'GRN_PS_DET',	'rfnet'	 UNION ALL
	SELECT 'GRN_PS_DET',	'PRODUCT_CODE'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'JOBWORK_ISSUE_MST',	'issue_type'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'issue_type'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'issue_mode'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'agency_code'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'wip'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_MST',	'total_quantity'	


	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'JOBWORK_ISSUE_DET',	'gst_cess_amount'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'job_rate'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'REF_NO'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'bin_id'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'rfnet'	 UNION ALL
	SELECT 'JOBWORK_ISSUE_DET',	'xn_value_with_gst'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'JOBWORK_RECEIPT_MST',	'last_update'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'receipt_id'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'fin_year'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'receipt_no'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'REF_NO'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'receipt_dt'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'cancelled'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'subtotal'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'tds'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'other_charges'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'net_amount'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'DISCOUNT_PERCENTAGE'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'DISCOUNT_AMOUNT'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'bin_id'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'Receive_Mode'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'wip'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_MST',	'total_quantity'	 
	
	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'JOBWORK_RECEIPT_DET',	'product_code'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'receipt_id'	 UNION ALL
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
	SELECT 'JOBWORK_RECEIPT_DET',	'job_rate'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'rfnet'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'ref_row_id'	 UNION ALL
	SELECT 'JOBWORK_RECEIPT_DET',	'Gst_Cess_Amount'	

	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'WPS_MST',	'ps_id'	 UNION ALL
	SELECT 'WPS_MST',	'ps_no'	 UNION ALL
	SELECT 'WPS_MST',	'ps_dt'	 UNION ALL
	SELECT 'WPS_MST',	'ac_code'	 UNION ALL
	SELECT 'WPS_MST',	'SUBTOTAL'	 UNION ALL
	SELECT 'WPS_MST',	'CANCELLED'	 UNION ALL
	SELECT 'WPS_MST',	'fin_year'	 UNION ALL
	SELECT 'WPS_MST',	'wsl_inv_id'	 UNION ALL
	SELECT 'WPS_MST',	'TOTAL_QUANTITY'
	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'WPS_DET',	'ps_id'	 UNION ALL
	SELECT 'WPS_DET',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'WPS_DET',	'QUANTITY'	 UNION ALL
	SELECT 'WPS_DET',	'RATE'	 UNION ALL
	SELECT 'WPS_DET',	'rfnet'	 UNION ALL
	SELECT 'WPS_DET',	'bin_id' UNION ALL
	SELECT 'WPS_DET',	'ROW_ID'	 


	INSERT INTO #olap_xnssending_cols (tablename,colname)
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
	SELECT 'RPS_MST',	'customer_code'	 UNION ALL
	SELECT 'RPS_MST',	'total_quantity'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'RPS_DET',	'cm_id'	 UNION ALL
	SELECT 'RPS_DET',	'PRODUCT_CODE'	 UNION ALL
	SELECT 'RPS_DET',	'QUANTITY'	 UNION ALL
	SELECT 'RPS_DET',	'MRP'	 UNION ALL
	SELECT 'RPS_DET',	'NET'	 UNION ALL
	SELECT 'RPS_DET',	'ROW_ID'	 UNION ALL
	SELECT 'RPS_DET',	'basic_discount_percentage'	 UNION ALL
	SELECT 'RPS_DET',	'card_discount_percentage'	 UNION ALL
	SELECT 'RPS_DET',	'basic_discount_amount'	 UNION ALL
	SELECT 'RPS_DET',	'discount_amount'	 UNION ALL
	SELECT 'RPS_DET',	'bin_id'	 UNION ALL
	SELECT 'RPS_DET',	'emp_code'	 UNION ALL
	SELECT 'RPS_DET',	'emp_code1'	 UNION ALL
	SELECT 'RPS_DET',	'emp_code2'	 UNION ALL
	SELECT 'RPS_DET',	'rfnet'	 UNION ALL
	SELECT 'RPS_DET',	'card_discount_amount'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'paymode_xn_det',	'paymode_code'	 UNION ALL
	SELECT 'paymode_xn_det',	'memo_id'	 UNION ALL
	SELECT 'paymode_xn_det',	'xn_type'	 UNION ALL
	SELECT 'paymode_xn_det',	'row_id'	 UNION ALL
	SELECT 'paymode_xn_det',	'amount'	
	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'paymode_mst',	'paymode_code'	 UNION ALL
	SELECT 'paymode_mst',	'paymode_grp_code'	 UNION ALL
	SELECT 'paymode_mst',	'paymode_name'	  

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'paymode_grp_mst',	'paymode_grp_name'	 UNION ALL
	SELECT 'paymode_grp_mst',	'paymode_grp_code'	 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'lm01106','ac_code' UNION ALL
	SELECT 'lm01106','ac_name' UNION ALL
	SELECT 'lm01106','alias' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'lmp01106','ac_code' UNION ALL
	SELECT 'lmp01106','ac_gst_no' UNION ALL
	SELECT 'lmp01106','pan_no' 	 UNION ALL
	SELECT 'lmp01106','mobile' 	 UNION ALL
	SELECT 'lmp01106','E_MAIL' 	 UNION ALL
	SELECT 'lmp01106','address1' UNION ALL
	SELECT 'lmp01106','area_code' UNION ALL
	SELECT 'lmp01106','address2' 	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'hd01106','head_code' UNION ALL
	SELECT 'hd01106','head_name' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'area','area_code' UNION ALL
	SELECT 'area','city_code' UNION ALL
	SELECT 'area','area_name'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'city','city_code' UNION ALL
	SELECT 'city','state_code' UNION ALL
	SELECT 'city','city'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'state','state_code' UNION ALL
	SELECT 'state','region_code' UNION ALL
	SELECT 'state','state'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'regionm','region_code' UNION ALL
	SELECT 'regionm','region_name'
	   	  
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'employee','emp_code' UNION ALL
	SELECT 'employee','emp_name' UNION ALL
	SELECT 'employee','emp_alias' 
	

	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'custdym','customer_code' UNION ALL
	SELECT 'custdym','user_customer_code' UNION ALL
	SELECT 'custdym','customer_fname' UNION ALL
	SELECT 'custdym','customer_lname' UNION ALL
	SELECT 'custdym','area_code' UNION ALL
	SELECT 'custdym','card_no' UNION ALL
	SELECT 'custdym','dt_card_expiry' UNION ALL
	SELECT 'custdym','cus_gst_no' UNION ALL
	SELECT 'custdym','mobile' UNION ALL
	SELECT 'custdym','Email' UNION ALL
	SELECT 'custdym','dt_birth' UNION ALL
	SELECT 'custdym','dt_anniversary' UNION ALL
	SELECT 'custdym','address2' UNION ALL
	SELECT 'custdym','privilege_customer' UNION ALL
	SELECT 'custdym','address1'  UNION ALL
	SELECT 'cust_attr','customer_code'  UNION ALL
	SELECT 'cust_attr','attribute_code'  UNION ALL
	SELECT 'cust_attr','key_code'  UNION ALL
	SELECT 'cust_attr','key_name'

	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'savetran_updcols_updatestr','sp_id' UNION ALL
	SELECT 'savetran_updcols_updatestr','tablename' UNION ALL
	SELECT 'savetran_updcols_updatestr','updatestr' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'xnsavelog',	'sp_id'	 UNION ALL
	SELECT 'xnsavelog',	'start_time'	 UNION ALL
	SELECT 'xnsavelog',	'step'	 UNION ALL
	SELECT 'xnsavelog',	'step_msg'	 UNION ALL
	SELECT 'xnsavelog',	'xn_type'	

	---Put this reference to get the full structure of Sku_names at OLAP Server
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'sku_names',	'*'	 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'nrm',	'*'	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'REP_MST','*' UNION ALL
	SELECT 'REP_DET','*' UNION ALL
	SELECT 'REP_FILTER','*' UNION ALL
	SELECT 'REP_FILTER_DET','*' UNION ALL
	SELECT 'rep_crm','*' UNION ALL
	SELECT 'rep_sch','*'  UNION ALL
	SELECT 'report_scheduler','*' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'pmt01106','product_code' UNION ALL
	SELECT 'pmt01106','dept_id' UNION ALL
	SELECT 'pmt01106','bin_id' UNION ALL
	SELECT 'pmt01106','quantity_in_stock'


	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'prd_agency_mst','agency_code' UNION ALL
	SELECT 'prd_agency_mst','ac_code' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'irm01106','IRM_MEMO_DT' UNION ALL
	SELECT 'irm01106','IRM_MEMO_NO' UNION ALL
	SELECT 'irm01106','IRM_MEMO_ID' UNION ALL
	SELECT 'irm01106','bin_id' UNION ALL
	SELECT 'ird01106','product_code' UNION ALL
	SELECT 'ird01106','IRM_MEMO_ID' UNION ALL
	SELECT 'ird01106','QUANTITY' UNION ALL
	SELECT 'ird01106','BIN_ID' UNION ALL
	SELECT 'ird01106','new_product_code' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'attrm','attribute_name' UNION ALL
	SELECT 'attrm','attribute_type' UNION ALL
	SELECT 'attrm','attribute_code'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'attr_key','attribute_code' UNION ALL
	SELECT 'attr_key','key_code' UNION ALL
	SELECT 'attr_key','key_name'


	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'floor_st_mst','*' UNION ALL
	SELECT 'floor_st_det','*'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'parcel_mst','parcel_memo_id' UNION ALL
	SELECT 'parcel_mst','xn_type' UNION ALL
	SELECT 'parcel_mst','angadia_code' UNION ALL
	SELECT 'parcel_mst','cancelled' UNION ALL
	SELECT 'parcel_det','parcel_memo_id' UNION ALL
	SELECT 'parcel_det','ref_memo_id' UNION ALL
	SELECT 'angm','Angadia_code' UNION ALL
	SELECT 'angm','Angadia_name'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'dnps_mst','ps_id' UNION ALL
	SELECT 'dnps_mst','cancelled' UNION ALL
	SELECT 'dnps_mst','ps_no' UNION ALL
	SELECT 'dnps_mst','ps_dt' UNION ALL
	SELECT 'dnps_det','ps_id' UNION ALL
	SELECT 'dnps_det','product_code' UNION ALL
	SELECT 'dnps_det','ac_code' UNION ALL
	SELECT 'dnps_det','quantity' UNION ALL
	SELECT 'dnps_det','bin_id' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'bom_issue_mst','issue_id' UNION ALL
	SELECT 'bom_issue_mst','issue_type' UNION ALL
	SELECT 'bom_issue_mst','issue_dt' UNION ALL
	SELECT 'bom_issue_mst','issue_no' UNION ALL
	SELECT 'bom_issue_mst','cancelled' UNION ALL
	SELECT 'bom_issue_det','product_code' UNION ALL
	SELECT 'bom_issue_mst','agency_code' UNION ALL
	SELECT 'bom_issue_det','issue_id' UNION ALL
	SELECT 'bom_issue_det','stock_qty' UNION ALL
	SELECT 'bom_issue_det','quantity' UNION ALL
	SELECT 'bom_issue_det','bin_id' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'transfer_to_trading_mst','memo_id' UNION ALL
	SELECT 'transfer_to_trading_mst','memo_no' UNION ALL
	SELECT 'transfer_to_trading_mst','memo_dt' UNION ALL
	SELECT 'transfer_to_trading_mst','cancelled' UNION ALL
	SELECT 'transfer_to_trading_det','memo_id' UNION ALL
	SELECT 'transfer_to_trading_det','product_code' UNION ALL
	SELECT 'transfer_to_trading_det','quantity' UNION ALL
	SELECT 'transfer_to_trading_det','AC_CODE' UNION ALL
	SELECT 'transfer_to_trading_det','bin_id'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'snc_mst','memo_id' UNION ALL
	SELECT 'snc_mst','MEMO_NO' UNION ALL
	SELECT 'snc_mst','RECEIPT_DT' UNION ALL
	SELECT 'snc_mst','wip' UNION ALL
	SELECT 'snc_mst','CANCELLED' UNION ALL
	SELECT 'snc_mst','wip' UNION ALL
	SELECT 'snc_det','memo_id' UNION ALL
	SELECT 'snc_det','row_id' UNION ALL
	SELECT 'snc_det','bin_id' UNION ALL
	SELECT 'snc_det','quantity' UNION ALL
	SELECT 'snc_det','ARTICLE_CODE' UNION ALL
	SELECT 'SNC_BARCODE_DET','REFROW_ID' UNION ALL
	SELECT 'SNC_BARCODE_DET','PRODUCT_CODE'

	-- CHANGES BY DINKAR
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'SNC_CONSUMABLE_DET','REF_ROW_ID' UNION ALL
	SELECT 'SNC_CONSUMABLE_DET','PRODUCT_CODE' UNION ALL
	SELECT 'SNC_CONSUMABLE_DET','MEMO_ID' UNION ALL
	SELECT 'SNC_CONSUMABLE_DET','WIP' UNION ALL
	SELECT 'SNC_CONSUMABLE_DET','bin_id' UNION ALL
	SELECT 'SNC_CONSUMABLE_DET','QUANTITY' 

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'SCM01106','memo_id' UNION ALL
	SELECT 'SCM01106','memo_no' UNION ALL
	SELECT 'SCM01106','memo_dt' UNION ALL
	SELECT 'SCM01106','cancelled' UNION ALL

	SELECT 'SCF01106','product_code' UNION ALL
	SELECT 'SCF01106','quantity' UNION ALL
	SELECT 'SCF01106','memo_id' UNION ALL
	

	SELECT 'SCC01106','product_code' UNION ALL
	SELECT 'SCC01106','quantity' UNION ALL
	SELECT 'SCC01106','memo_id' UNION ALL
	SELECT 'SCC01106','ADJ_QUANTITY' 


	--END CHANGES BY DINKAR

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'dtm','dt_code' UNION ALL
	SELECT 'dtm','dt_name' UNION ALL
	SELECT 'YEAR_WISE_CBSSTK_DEPCN_DET','*' UNION ALL
	SELECT 'YEAR_WISE_CBSSTK_DEPCN_MST','*'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'Rep_Adv_Filter','*' UNION ALL
	SELECT 'xpert_filter_mst','*' UNION ALL
	SELECT 'Xpert_Rep_Mst_Linked_Filter','*'  UNION ALL
	SELECT 'REP_DET_XNTYPES','*'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'GST_STATE_MST','gst_state_code' UNION ALL
	SELECT 'GST_STATE_MST','gst_state_name'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'sku','product_code' UNION ALL
	SELECT 'sku','article_code' UNION ALL
	SELECT 'sku','para1_code' UNION ALL
	SELECT 'sku','para2_code' UNION ALL
	SELECT 'sku','para3_code' UNION ALL
	SELECT 'sku','para4_code' UNION ALL
	SELECT 'sku','para5_code' UNION ALL
	SELECT 'sku','para6_code' UNION ALL
	SELECT 'sku','hsn_code' UNION ALL
	SELECT 'sku','vendor_ean_no' UNION ALL
	SELECT 'sku','BARCODE_CODING_SCHEME' UNION ALL
	SELECT 'sku','VENDOR_EAN_NO' UNION ALL
	SELECT 'sku','gst_percentage'
	
	
	

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'loc_names','*'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'scheme_Setup_mst','*' UNION ALL
	SELECT 'scheme_Setup_det','*' UNION ALL
	SELECT 'scheme_Setup_loc','*'

	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'scheme_Setup_slsbc','scheme_setup_det_row_id' UNION ALL
	SELECT 'scheme_Setup_slsbc','product_code' UNION ALL
	SELECT 'scheme_Setup_slsbc','discount_amount' UNION ALL
	SELECT 'scheme_Setup_slsbc','net_price' UNION ALL
	SELECT 'scheme_Setup_slsbc','discount_mode' 
	
	INSERT INTO #olap_xnssending_cols (tablename,colname)
	SELECT 'scheme_Setup_slsart','scheme_setup_det_row_id' UNION ALL
	SELECT 'scheme_Setup_slsart','article_code' UNION ALL
	SELECT 'scheme_Setup_slsart','discount_figure' UNION ALL
	SELECT 'scheme_Setup_slsart','discount_mode' 


	TRUNCATE TABLE olap_xnssending_cols

	INSERT INTO olap_xnssending_cols (tablename,colname)
	SELECT DISTINCT table_name,column_name FROM  #olap_xnssending_cols a
	JOIN INFORMATION_SCHEMA.COLUMNS B ON a.tablename=b.table_name AND a.colname=b.COLUMN_NAME
	UNION 
	SELECT DISTINCT table_name,column_name FROM  #olap_xnssending_cols a
	JOIN INFORMATION_SCHEMA.COLUMNS B ON a.tablename=b.table_name
	WHERE a.colname='*'
	UNION 
	SELECT DISTINCT table_name,b.column_name FROM  #olap_xnssending_cols a
	JOIN INFORMATION_SCHEMA.COLUMNS B ON a.tablename=b.table_name 
	WHERE b.COLUMN_NAME in('quantity_last_update','TOTAL_QUANTITY')
	

END


