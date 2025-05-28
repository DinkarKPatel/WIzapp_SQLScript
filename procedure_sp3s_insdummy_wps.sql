CREATE procedure sp3s_insdummy_wps
as
begin
	if exists (select top 1 ps_id from wps_mst (nolock) where ps_id='XXXXXXXXXX')
		return

	 INSERT wps_mst	( ac_code, Angadia_code, ApprovedLevelNo, auto_posreco_last_update, BIN_ID, BROKER_AC_CODE, CANCELLED, CHECKED_BY, COPIES_PTD, CREDIT_DAYS, 
	 EDIT_INFO, edt_user_code, entry_mode, FIN_YEAR, HEAD_COUNT, HO_SYNCH_LAST_UPDATE, LAST_UPDATE, LotType, MEMO_TYPE, NO_OF_BOXES, OLAP_SYNCH_LAST_UPDATE, 
	 party_dept_id, pay_type, ps_created_time, ps_dt, ps_id, ps_mode, ps_no, PUMA_HO_SYNCH_LAST_UPDATE, quantity_last_update, reconciled, REMARKS, SCANNED_QTY, 
	 sent_for_recon, shipping_Address, shipping_address2, shipping_address3, shipping_area_code, shipping_area_name, shipping_city_name, shipping_pin, 
	 shipping_state_name, SUBTOTAL, TARGET_BIN_ID, tat_days, taxform_storage_mode, TOTAL_QUANTITY, TOTAL_QUANTITY_STR, USER_CODE, Way_bill, wsl_inv_id, XN_ITEM_TYPE )  
	 SELECT '0000000000' ac_code, null Angadia_code,0 ApprovedLevelNo,'' auto_posreco_last_update,'000' BIN_ID,'0000000000' BROKER_AC_CODE,1 CANCELLED, '' CHECKED_BY, 
	 0 COPIES_PTD,0 CREDIT_DAYS,'' EDIT_INFO, '0000000' edt_user_code,1 entry_mode,'' FIN_YEAR,0 HEAD_COUNT,'' HO_SYNCH_LAST_UPDATE,getdate() LAST_UPDATE,1 LotType,1 MEMO_TYPE,
	 1 NO_OF_BOXES,'' OLAP_SYNCH_LAST_UPDATE,null party_dept_id,1 pay_type,'' ps_created_time,'' ps_dt,'XXXXXXXXXX' ps_id,1 ps_mode,'XXXXXXXXXX' ps_no,'' PUMA_HO_SYNCH_LAST_UPDATE,
	 '' quantity_last_update,0 reconciled,'' REMARKS,0 SCANNED_QTY,0 sent_for_recon,'' shipping_Address,'' shipping_address2,'' shipping_address3,'' shipping_area_code, 
	 '' shipping_area_name,''  shipping_city_name,'' shipping_pin,'' shipping_state_name,0 SUBTOTAL,'000' TARGET_BIN_ID,0 tat_days,0 taxform_storage_mode, 
	 0 TOTAL_QUANTITY,'' TOTAL_QUANTITY_STR,'0000000' USER_CODE,0 Way_bill,'' wsl_inv_id,1 XN_ITEM_TYPE 



end
