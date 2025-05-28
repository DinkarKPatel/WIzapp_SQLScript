CREATE PROCEDURE SP3S_INSDUMMY_B2BENTRIES
AS
BEGIN
	
	PRINT 'Insert dummy entries'
	IF NOT EXISTS (SELECT TOP 1 mrr_id FROM pim01106 (NOLOCK) WHERE mrr_id='XXXXXXXXXX')
		INSERT pim01106	(memo_type,cancelled,excise_duty_amount,pim_mode,taxform_storage_mode,bill_level_tax_method,REMARKS,manual_discount,
		manual_roundoff,bill_challan_mode,INV_MODE,PUR_CAL_METHOD,party_inv_amount,BIN_ID,last_update,PostTaxDiscountAmount,
		ApprovedLevelNo,MRR_CREATION_DEPT_ID,party_state_code,TOTAL_QUANTITY,OH_TAX_METHOD,mrr_id,fin_year,EDT_USER_CODE,credit_days,
		cr_discount_percentage,mrr_no,inv_no,inv_dt,bill_no,receipt_dt,ac_code,total_amount,subtotal,discount_percentage)  
		SELECT top 1 1 memo_type,1 cancelled,0 excise_duty_amount,0 pim_mode,0 taxform_storage_mode,0 bill_level_tax_method,'' REMARKS,0 manual_discount,
		0 manual_roundoff,0 bill_challan_mode,0 INV_MODE,0 PUR_CAL_METHOD,0 party_inv_amount,'000' BIN_ID,getdate() last_update,
		0 PostTaxDiscountAmount,0 ApprovedLevelNo,dept_id MRR_CREATION_DEPT_ID,'00' party_state_code,0 TOTAL_QUANTITY,0 OH_TAX_METHOD,
		'XXXXXXXXXX' mrr_id,'' fin_year,'0000000' EDT_USER_CODE,0 credit_days,0 cr_discount_percentage,'XXXXXXXXXX' mrr_no,
		'' inv_no,'' inv_dt,'' bill_no,'' receipt_dt,'0000000000' ac_code,0 total_amount,0 subtotal,0 discount_percentage
		from location
		
	IF NOT EXISTS (SELECT TOP 1 rm_id FROM rmm01106 (NOLOCK) WHERE rm_id='XXXXXXXXXX')
		insert rmm01106 (rm_time,rm_no,excise_duty_amount,memo_type,mode,exported,uploaded_to_activstream,taxform_storage_mode,rm_dt,ac_code,
		total_amount,subtotal,last_update,CANCELLED,user_code,approved,rm_id,fin_year,ANGADIA_DETAIL,grlr_no,grlr_date,bandals,DN_TYPE,
		rate_diff,batch_no,edt_user_code,Entry_Mode,REMARKS,manual_discount,manual_roundoff,CR_RECEIVED,BIN_ID,TARGET_BIN_ID,completed,
		ApprovedLevelNo,xfer_type,party_state_code,OH_TAX_METHOD)
		select '' rm_time,'XXXXXXXXXX' rm_no, 0 excise_duty_amount,1 memo_type,0 mode,0 exported,0 uploaded_to_activstream,0 taxform_storage_mode,'' rm_dt,
		'0000000000' ac_code,0 total_amount,0 subtotal,getdate() last_update,1 CANCELLED,'0000000' user_code,0 approved,'XXXXXXXXXX' rm_id,
		'' fin_year,'' ANGADIA_DETAIL,'' grlr_no,'' grlr_date,0 bandals,1 DN_TYPE,0 rate_diff,'' batch_no,'0000000' edt_user_code,
		0 Entry_Mode,'' REMARKS,0 manual_discount,0 manual_roundoff,0 CR_RECEIVED,'000' BIN_ID,'000' TARGET_BIN_ID,0 completed,
		0 ApprovedLevelNo,0 xfer_type,'00' party_state_code,0 OH_TAX_METHOD

	IF NOT EXISTS (SELECT TOP 1 inv_id FROM inm01106 (NOLOCK) WHERE inv_id='XXXXXXXXXX')
		insert inm01106 (uploaded_to_activstream,BROKER_AC_CODE,broker_comm_percentage,broker_comm_amount,route_form1,route_form2,
		party_da_no,party_po_no,insurance,emp_code,dt_code,party_state_code,OH_TAX_METHOD,bill_level_tax_method,INV_ID,ac_code,INV_NO,
		INV_DT,SUBTOTAL,DISCOUNT_AMOUNT,FREIGHT,completed,entry_mode,taxform_storage_mode,SENT_BY,COMPANY_CODE,USER_CODE,LAST_UPDATE,
		GRLR_NO,GRLR_DATE,PACKING,OTHER_CHARGES,NET_AMOUNT,ROUND_OFF,CANCELLED,CHECKED_BY,pay_mode,memo_type,REMARKS,manual_discount,
		manual_roundoff,manual_octroi,inv_type,xfer_type,BIN_ID,TARGET_BIN_ID,FIN_YEAR,BANDALS,THROUGH,form_no,edt_user_code,inv_time,
		manual_inv_no,octroi_percentage,octroi_amount,inv_mode,exported,excise_accessible_percentage,excise_accessible_amount,
		excise_duty_percentage,excise_duty_amount,excise_edu_cess_percentage,excise_edu_cess_amount,excise_hedu_cess_percentage,
		excise_hedu_cess_amount,dept_id,excise_invoice,Approved,exported_time,DOMESTIC_FOR_EXPORT)
		select top 1 0 uploaded_to_activstream,'' BROKER_AC_CODE,0 broker_comm_percentage,0 broker_comm_amount,'' route_form1,'' route_form2,
		'' party_da_no,'' party_po_no,0 insurance,'' emp_code,'' dt_code,'00' party_state_code,0 OH_TAX_METHOD,0 bill_level_tax_method,
		'XXXXXXXXXX' INV_ID,'0000000000' ac_code,'XXXXXXXXXX' INV_NO,'' INV_DT,0 SUBTOTAL,0 DISCOUNT_AMOUNT,0 FREIGHT,0 completed,1 entry_mode,
		0 taxform_storage_mode,'' SENT_BY,'01' COMPANY_CODE,'0000000' USER_CODE,getdate() LAST_UPDATE,'' GRLR_NO,'' GRLR_DATE,0 PACKING,
		0 OTHER_CHARGES,0 NET_AMOUNT,0 ROUND_OFF,1 CANCELLED,'' CHECKED_BY,0 pay_mode,1 memo_type,'' REMARKS,0 manual_discount,
		0 manual_roundoff,0 manual_octroi,0 inv_type,0 xfer_type,'000' BIN_ID,'000' TARGET_BIN_ID,'' FIN_YEAR,0 BANDALS,'' THROUGH,
		'' form_no,'0000000' edt_user_code,'' inv_time,'' manual_inv_no,0 octroi_percentage,0 octroi_amount,0 inv_mode,0 exported,
		0 excise_accessible_percentage,0 excise_accessible_amount,0 excise_duty_percentage,0 excise_duty_amount,0 excise_edu_cess_percentage,
		0 excise_edu_cess_amount,0 excise_hedu_cess_percentage,0 excise_hedu_cess_amount, dept_id,0 excise_invoice,0 Approved,
		'' exported_time,0 DOMESTIC_FOR_EXPORT from location

	IF NOT EXISTS (SELECT TOP 1 cn_id FROM cnm01106 (NOLOCK) WHERE cn_id='XXXXXXXXXX')
		insert cnm01106 (taxform_storage_mode,memo_type,REMARKS,manual_discount,manual_roundoff,BIN_ID,cn_no,cn_dt,ac_code,subtotal,
		discount_percentage,discount_amount,other_charges,freight,round_off,total_amount,cancelled,checked_by,company_code,insurance,
		xfer_type,party_state_code,OH_TAX_METHOD,user_code,last_update,cn_id,fin_year,through,grlr_date,grlr_no,bandals,CN_TYPE,
		party_dept_id,broker_ac_code,broker_comm_percentage,broker_comm_amount,dt_code,billed_from_dept_id,edt_user_code,
		cn_time,manual_inv_no,cnc_dt,rfopt_updated,mode,receipt_dt)
		select top 1 0 taxform_storage_mode,1 memo_type,'' REMARKS,0 manual_discount,0 manual_roundoff,'000' BIN_ID,'XXXXXXXXXX' cn_no,'' cn_dt,
		'0000000000' ac_code,0 subtotal,0 discount_percentage,0 discount_amount,0 other_charges,0 freight,0 round_off,0 total_amount,
		1 cancelled,'' checked_by,'01' company_code,0 insurance,0 xfer_type,'00' party_state_code,0 OH_TAX_METHOD,'0000000' user_code,
		getdate() last_update,'XXXXXXXXXX' cn_id,'' fin_year,'' through,'' grlr_date,'' grlr_no,0 bandals,0 CN_TYPE,
		'' party_dept_id,'' broker_ac_code,0 broker_comm_percentage,0 broker_comm_amount,'' dt_code,dept_id billed_from_dept_id,'0000000' edt_user_code,
		'' cn_time,'' manual_inv_no,'' cnc_dt,0 rfopt_updated,1 mode,'' receipt_dt from location
	
	PRINT 'Update dummy entries'
	update pim01106 with (rowlock) SET HO_SYNCH_LAST_UPDATE=last_update WHERE mrr_id='XXXXXXXXXX'
	update rmm01106 with (rowlock) SET HO_SYNCH_LAST_UPDATE=last_update WHERE rm_id='XXXXXXXXXX'
	update inm01106 with (rowlock) SET HO_SYNCH_LAST_UPDATE=last_update WHERE inv_id='XXXXXXXXXX'
	update cnm01106 with (rowlock) SET HO_SYNCH_LAST_UPDATE=last_update WHERE cn_id='XXXXXXXXXX'

END