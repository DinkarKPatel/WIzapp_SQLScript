CREATE TRIGGER [DBO].[TRG_UPD_LMP01106_LAST_MODIFIED_ON] ON [DBO].[LMP01106]
FOR UPDATE
AS
BEGIN
	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE LMP01106 SET LAST_MODIFIED_ON=CAST(GETDATE() AS DATE) 
	FROM DELETED B WHERE B.AC_CODE=LMP01106.AC_CODE
	AND (lmp01106.dpwef_dt<>b.dpwef_dt OR lmp01106.tin_no<>b.tin_no OR lmp01106.tin_dt<>b.tin_dt OR 
	lmp01106.pan_no<>b.pan_no OR lmp01106.area_code<>b.area_code OR lmp01106.inv_rate_type<>b.inv_rate_type 
	OR lmp01106.CUSTOMER_CODE<>b.CUSTOMER_CODE OR lmp01106.gln_no<>b.gln_no OR lmp01106.mp_percentage<>b.mp_percentage OR 
	lmp01106.mrp_calc_mode<>b.mrp_calc_mode OR lmp01106.PRINT_NAME<>b.PRINT_NAME OR lmp01106.ADDRESS0<>b.ADDRESS0 
	OR lmp01106.ADDRESS1<>b.ADDRESS1 OR lmp01106.sales_ac_code<>b.sales_ac_code OR 
	lmp01106.default_rate_type<>b.default_rate_type OR lmp01106.PUR_CAL_METHOD<>b.PUR_CAL_METHOD OR 
	lmp01106.RESTRICT_PUR_ENTRY<>b.RESTRICT_PUR_ENTRY OR lmp01106.WP_PERCENTAGE<>b.WP_PERCENTAGE OR 
	lmp01106.wsl_rate_calc_method<>b.wsl_rate_calc_method OR lmp01106.EOSS_DISCOUNT_SHARE<>b.EOSS_DISCOUNT_SHARE 
	OR lmp01106.EOSS_DISCOUNT_PER<>b.EOSS_DISCOUNT_PER OR lmp01106.Purchase_Against_terms<>b.Purchase_Against_terms
	OR lmp01106.shipping_address<>b.shipping_address OR lmp01106.shipping_address2<>b.shipping_address2 OR 
	lmp01106.shipping_address3<>b.shipping_address3 OR lmp01106.custom_rate_type<>b.custom_rate_type OR 
	lmp01106.DO_NOT_ALLOW_DIRECT_PUR<>b.DO_NOT_ALLOW_DIRECT_PUR OR lmp01106.Enable_Email<>b.Enable_Email 
	OR lmp01106.WhatsApp_no<>b.WhatsApp_no OR lmp01106.Ac_gst_no<>b.Ac_gst_no OR lmp01106.THRU_RTGS<>b.THRU_RTGS 
	OR lmp01106.party_erp_code<>b.party_erp_code OR lmp01106.Angadia_code<>b.Angadia_code OR 
	lmp01106.registered_gst_dealer<>b.registered_gst_dealer OR lmp01106.ac_gst_state_code<>b.ac_gst_state_code 
	OR lmp01106.PARTY_RATE_MEMO_ID<>b.PARTY_RATE_MEMO_ID OR lmp01106.PARTY_RATE_SUPP<>b.PARTY_RATE_SUPP OR 
	lmp01106.ADDRESS2<>b.ADDRESS2 OR lmp01106.CITY_CODE<>b.CITY_CODE OR lmp01106.CST_NO<>b.CST_NO OR 
	lmp01106.CST_DT<>b.CST_DT OR lmp01106.SST_NO<>b.SST_NO OR lmp01106.SST_DT<>b.SST_DT OR 
	lmp01106.PHONES_R<>b.PHONES_R OR lmp01106.PHONES_O<>b.PHONES_O OR lmp01106.PHONES_FAX<>b.PHONES_FAX 
	OR lmp01106.MOBILE<>b.MOBILE OR lmp01106.E_MAIL<>b.E_MAIL OR lmp01106.TAX_CODE<>b.TAX_CODE OR 
	lmp01106.CREDIT_DAYS<>b.CREDIT_DAYS OR lmp01106.DISCOUNT_PERCENTAGE<>b.DISCOUNT_PERCENTAGE OR 
	lmp01106.BILL_BY_BILL<>b.BILL_BY_BILL OR lmp01106.ON_HOLD<>b.ON_HOLD OR lmp01106.THROUGH_BROKER<>b.THROUGH_BROKER OR lmp01106.BROKER_AC_CODE<>b.BROKER_AC_CODE OR lmp01106.BROKER_COMM_PERCENT<>b.BROKER_COMM_PERCENT OR lmp01106.CREDIT_LIMIT<>b.CREDIT_LIMIT OR lmp01106.OUTSTATION_PARTY<>b.OUTSTATION_PARTY OR lmp01106.ALLOW_CREDITOR_DEBTOR<>b.ALLOW_CREDITOR_DEBTOR OR lmp01106.company_code<>b.company_code OR lmp01106.order_allocation_priority<>b.order_allocation_priority OR lmp01106.hold_for_payment<>b.hold_for_payment OR lmp01106.AR_ID<>b.AR_ID OR lmp01106.contact_person_name<>b.contact_person_name OR lmp01106.export_gst_percentage<>b.export_gst_percentage OR lmp01106.export_gst_mode<>b.export_gst_mode OR lmp01106.TRADE_DISCOUNT_PERCENTAGE<>b.TRADE_DISCOUNT_PERCENTAGE OR lmp01106.ROUND_OFF_GST_AMT<>b.ROUND_OFF_GST_AMT OR lmp01106.export_gst_percentage_Applicable<>b.export_gst_percentage_Applicable OR lmp01106.rcm_applicable<>b.rcm_applicable OR lmp01106.allow_allocation_wip_stk<>b.allow_allocation_wip_stk OR lmp01106.e_mail_cc<>b.e_mail_cc OR lmp01106.cd_calc_based_on<>b.cd_calc_based_on)
END
