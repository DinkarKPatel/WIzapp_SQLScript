create procedure SP3S_INSDUMMY_CMM
as
begin
	if exists (select top 1 cm_id from cmm01106 (nolock) where cm_id='XXXXXXXXXX')
		return

	INSERT cmm01106	( AC_CODE, ACH_DT, ACH_NO, atd_charges, auto_posreco_cons_last_update, auto_posreco_last_update, autoentry, 
	  bill_level_eoss_scheme_discount, BIN_ID, BOM_ORDER_ID, calc_da1, calc_da2, campaign_gc_otp, CANCELLED, cash_tendered, CM_DT, cm_id, CM_MODE, CM_NO, cm_time, copies_ptd, ctrls_used, CUSTOMER_CODE, DELIVERY_MODE, DISCOUNT_AMOUNT, discount_changed, DISCOUNT_PERCENTAGE, discount_remarks, dp_changed, DT_CODE, duplicate_version, ebills_tinyurl, ecoupon_id, EDIT_COUNT, EDIT_INFO, edt_user_code, EINV_IRN_NO, exchange_tolerance_discount_check_bypassed, exempted, fc_rate, fin_year, flight_no, gst_round_off, gv_amount, HO_SYNCH_LAST_UPDATE, INV_MODE, INV_TYPE, IRN_QR_CODE, LAST_UPDATE, LOYALTY_OTP_CODE, MANUAL_BILL, MANUAL_BILL_FLAG, manual_discount, Manual_Party_State_code, MANUAL_ROUNDOFF, memo_prefix, memo_type, mrp_exchange_bill, mrp_wsp, NET_AMOUNT, OH_TAX_METHOD, OLAP_SYNCH_LAST_UPDATE, Old_DISCOUNT_AMOUNT, Old_DISCOUNT_PERCENTAGE, Old_NET_AMOUNT, Old_round_off, Old_subtotal, Old_subtotal_r, org_memo_id, other_charges_cgst_amount, other_charges_gst_percentage, other_charges_hsn_code, other_charges_igst_amount, other_charges_sgst_amount, OTHER_CHARGES_TAXABLE_VALUE, PAN_NO, Party_Gst_No, party_state_code, party_type, passport_no, patchup_run, pay_mode, payback, PAYMENT_MODE_MODIFIED, PostedInAc, PUMA_HO_SYNCH_LAST_UPDATE, quantity_last_update, reconciled, ref_cm_id, ref_no, ref_no_paytm, REMARKS, round_off, SALE_PERSON_MODIFIED, SalesSetupinEffect, sent_for_gr, sent_for_recon, sent_to_ho, shift_id, 
	   SMS_SENT, SUBTOTAL, subtotal_r, SUPPLY_TYPE_CODE, 
	 third_party_loyalty_applied, ticket_no,  TOTAL_QUANTITY, TOTAL_QUANTITY_STR, USER_CODE, validation_bypassed_user_code, version_no, whatsapp_sent, wizclip_bill_synch_last_update, xn_item_type )  
	SELECT 	'0000000000'  AC_CODE,'' ACH_DT,'' ACH_NO,0 atd_charges,''  auto_posreco_cons_last_update,''  auto_posreco_last_update, 
	0 autoentry,0 bill_level_eoss_scheme_discount,'000' BIN_ID,null BOM_ORDER_ID,
	0 calc_da1,0  calc_da2,''  campaign_gc_otp,1 CANCELLED,0 cash_tendered,'' CM_DT,'XXXXXXXXXX' cm_id, 
	1 CM_MODE,'XXXXXXXXXX' CM_NO,''  cm_time,0 copies_ptd,0 ctrls_used,'000000000000' CUSTOMER_CODE,0 DELIVERY_MODE, 
	0 DISCOUNT_AMOUNT,0 discount_changed,0 DISCOUNT_PERCENTAGE,''  discount_remarks,0 dp_changed,
	'0000000' DT_CODE,0 duplicate_version,'' ebills_tinyurl,''  ecoupon_id,0 EDIT_COUNT,''  EDIT_INFO,
	'' edt_user_code,''  EINV_IRN_NO,0 exchange_tolerance_discount_check_bypassed,0 exempted,0 fc_rate, 
	'01124' fin_year,'' flight_no,0 gst_round_off,0 gv_amount,getdate()  HO_SYNCH_LAST_UPDATE,0 INV_MODE,0 INV_TYPE,
	'' IRN_QR_CODE,getdate() LAST_UPDATE,'' LOYALTY_OTP_CODE,0 MANUAL_BILL,0 MANUAL_BILL_FLAG,0 manual_discount, 
	'' Manual_Party_State_code,0 MANUAL_ROUNDOFF,''  memo_prefix,1 memo_type,0 mrp_exchange_bill,0 mrp_wsp, 
	0 NET_AMOUNT,0 OH_TAX_METHOD,''  OLAP_SYNCH_LAST_UPDATE,0 Old_DISCOUNT_AMOUNT,0 Old_DISCOUNT_PERCENTAGE, 
	0 Old_NET_AMOUNT,0  Old_round_off,0  Old_subtotal,0  Old_subtotal_r,'' org_memo_id,0  other_charges_cgst_amount, 
	0 other_charges_gst_percentage,'0000000000' other_charges_hsn_code,0  other_charges_igst_amount,0  other_charges_sgst_amount, 
	0 OTHER_CHARGES_TAXABLE_VALUE,'' PAN_NO,'' Party_Gst_No,'00' party_state_code,0 party_type,'' passport_no, 
	0 patchup_run,0 pay_mode,0 payback,0 PAYMENT_MODE_MODIFIED,0 PostedInAc,''  PUMA_HO_SYNCH_LAST_UPDATE, 
	'' quantity_last_update,0 reconciled,''  ref_cm_id,''  ref_no,''  ref_no_paytm,'Cancelled entry for handling Sale merging' REMARKS,
	0 round_off,0 SALE_PERSON_MODIFIED,0 SalesSetupinEffect,0 sent_for_gr,0 sent_for_recon,0 sent_to_ho,null  shift_id, 
	 0 SMS_SENT,0 SUBTOTAL,0  subtotal_r,'' SUPPLY_TYPE_CODE,0  third_party_loyalty_applied, 
	'' ticket_no, 0 TOTAL_QUANTITY, 
	'' TOTAL_QUANTITY_STR,'0000000' USER_CODE,''  validation_bypassed_user_code,0  version_no, 0 whatsapp_sent, 
	'' wizclip_bill_synch_last_update,1 xn_item_type

end
