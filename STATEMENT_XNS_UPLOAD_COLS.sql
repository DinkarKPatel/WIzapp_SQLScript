IF EXISTS (SELECT TOP 1 'U' FROM XNS_UPLOAD_COLS)
BEGIN
	TRUNCATE TABLE XNS_UPLOAD_COLS

	INSERT XNS_UPLOAD_COLS	( tablename ,columnname)  
	SELECT 	  'cmm01106' tablename, 'bill_level_dtm_method,SUPPLY_TYPE_CODE,party_state_code,ref_no,DELIVERY_MODE,cm_id,last_update,sp_id,memo_type,manual_discount,MANUAL_ROUNDOFF,  BIN_ID,  MANUAL_BILL,  shift_id,  CM_NO,  CM_DT,  CM_MODE,  DT_CODE,  DISCOUNT_PERCENTAGE,  DISCOUNT_AMOUNT,  CUSTOMER_CODE,  CANCELLED,  USER_CODE,  cm_time,    fin_year,  atd_charges,  pay_mode,  cash_tendered,  ecoupon_id,  SalesSetupinEffect,  ctrls_used,  discount_changed,  dp_changed,  OH_TAX_METHOD,  REMARKS,  AC_CODE,  xn_item_type,subtotal,subtotal_r,mrp_exchange_bill,total_quantity,total_quantity_str' columnname
	UNION ALL
	SELECT 	  'cmd01106' tablename ,'sp_id,rps_last_update,card_discount,  manual_tax_method, ref_order_id, pack_slip_row_id,  basic_discount_percentage,  card_discount_percentage,  basic_discount_amount,  card_discount_amount,  manual_mrp,  Manual_DP,  PRODUCT_CODE,  QUANTITY,  MRP,  NET,  discount_percentage,  discount_amount,  emp_code,  dept_id,  cm_id,  row_id,  emp_code1,  emp_code2,  manual_discount,  pack_slip_id,  BIN_ID,LAST_SLS_DISCOUNT_PERCENTAGE,ref_sls_memo_no,ref_sls_memo_dt' columnname
END


