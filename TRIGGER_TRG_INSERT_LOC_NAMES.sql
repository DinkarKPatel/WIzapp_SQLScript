CREATE TRIGGER [DBO].[TRG_INSERT_LOC_NAMES] ON [DBO].[LOCATION]  
FOR INSERT
AS  
   
   DECLARE @CDEPT_ID VARCHAR(5)/*Rohit 01-11-2024*/
   SELECT @CDEPT_ID=DEPT_ID  FROM INSERTED
   if isnull(@CDEPT_ID,'')<>''
   BEGIN
		EXEC SP20_DEFAULT_SERIESSETUP @CDEPT_ID
		
		INSERT INTO LOCREPUSER   (dept_id,user_code,last_update)
		SELECT @CDEPT_ID as dept_id,A.user_code,getdate() as last_update
		FROM USERS A
		LEFT OUTER JOIN LOCREPUSER B ON B.dept_id=@CDEPT_ID and B.user_code=A.user_code
		WHERE ISNULL(viewreportsLocationMode,0)=1 AND B.dept_id IS NULL
   

		INSERT LOC_NAMES	(Dept_ID,AREA_NAME,PINCODE,CITY,STATE,OCTROI_PERCENTAGE,REGION_NAME,dept_name,major_dept_id,ro_dept_id,group_id,pc_ho_loc_id,loc_type,loc_discount_percentage,
                        xfer_act,tan_no,area_covered,max_cm_dt,min_cm_dt,generate_auto_series,fc_code,enforce_billing_rules,ENABLE_BIN,PAN_NO,party_code,Allow_Monthly_budget_PC,AUTO_DAY_CLOSE,
                        get_challan_thru_mirror,BUDGET_AT_EXPENSE_HEADS,exclusive_vat,exclusive_vat_to_disc,sor_loc,till_enabled,donot_post_stkxfer_entries,SLR_recon_reqd,slr_recon_cutoff_date,
                        donot_send_challan_thru_mirror,DATE_OF_OPENING,report_blocked,inactive,accounts_posting_dept_id,control_ac_code,upd_purinfo,sspl_reg_key,wizcom_enabled,Excisable,
                        tin_no,fr_type,primary_email_port,primary_email,Primary_Email_SMTP,primary_Email_pwd,primary_email_SSL,sspl_grp_code,pur_loc,address1,address2,dept_ac_code,cst_no,cst_dt,
                        lst_no,lst_dt,dept_alias,phone,last_update,lead_days,mrr_series,allow_createac,data_polling,STN_APPROVAL,po_approval,server_loc,day_close_dt,donot_dayclose_if_till_open,SIS_LOC,
                        RECEIVE_CCPYMT_ONLINE,Auto_send_stn,Auto_send_stn_interval,allow_purchase_at_ho,SSPL_REG_KEY_DET,REG_USERS,mbosls_import_mode,monthlyreco_cutoff_days,monthlyreco_cutoffdays_setup_date,build_rfopt,
                        loc_gst_no,std_code,loc_id_as_barcode_prefix,Account_posting_at_ho,loc_gst_dt,registered_gst,gst_state_code,Registered_Add,DoNotSendChallanWithoutDispatch,EnableGSTReportConfig,
                        donot_update_rfopt_xnentry,PREFIX_HO_ID_IN_WIZCLIP_DATA,enforce_customerwalkin_entry_dayclose,wizclip_dept_id,GROWTH_FACTOR,SAFETY_FACTOR,enforce_backup,APPLY_ONLINE_EOSS_FROM_HO,ENFORCE_OTP_BASED_GR,
                        maintain_series_setup_at_ho,DONOT_MERGE_PARTYRATE,RestrictMaxStockAtRsp,MaxStockAtRsp,CurrentStockAtRsp,enable_accounting_at_loc,ask_for_consumables_billsaving,donot_merge_eoss,
                        CONTACT_NO,Check_MonitorStatus_on_add_memo,timezonediff,eway_username,eway_pwd,WizClip,bill_count_restriction,DISCOUNT_PICKMODE_SLR,otp_based_cust_enroll,CESS_APPLICABLE,
                        AUTO_CALCULATION_OF_ALTERATION_CHARGES,flow_config_Msg,invoice_control_ac_code,enforce_day_close_through_web,CHKPURDETAILS_IN_DN,primary_source_for_aro,enable_epaper_billing,
                        Enable_Tcs,Tcs_Calculation_Locally,E_Token,E_owerid,Enable_EInvoice,Dept_Print_Name,Enable_EwayBill,Synch_sku,ENABLE_RACK_MANAGEMENT,EWAYBILLSUMMARYDETAIL,Taxable_Entry_ID,Branch_ID,
                        Enable_Qr_Code_sale,Qr_Code_Paymode,CategoryCode,UPIID,BANK_ACCOUNT_NO,IFSC,UPIID_NAME,PICK_CUSTOMER_GST_STATE_IN_RETAIL_SALE,LOC_TYPE_NAME,FR_TYPE_NAME,LOC_GROUP,COUNTRY_NAME,
                        Locattr1_key_name,Locattr2_key_name,Locattr3_key_name,Locattr4_key_name,Locattr5_key_name,Locattr6_key_name,Locattr7_key_name,Locattr8_key_name,Locattr9_key_name,Locattr10_key_name,
						Locattr11_key_name,Locattr12_key_name,Locattr13_key_name,Locattr14_key_name,Locattr15_key_name,Locattr16_key_name,Locattr17_key_name,Locattr18_key_name,Locattr19_key_name,
						Locattr20_key_name,Locattr21_key_name,Locattr22_key_name,Locattr23_key_name,Locattr24_key_name,Locattr25_key_name) 
	 
	 
	  	   SELECT       a.Dept_ID,B.AREA_NAME,B.PINCODE,C.CITY,D.STATE,OCTROI_PERCENTAGE,E.REGION_NAME,A.dept_name,A.major_dept_id,A.ro_dept_id,A.group_id,A.pc_ho_loc_id,A.loc_type,A.loc_discount_percentage,
                        A.xfer_act,A.tan_no,A.area_covered,A.max_cm_dt,A.min_cm_dt,A.generate_auto_series,A.fc_code,A.enforce_billing_rules,A.ENABLE_BIN,A.PAN_NO,A.party_code,A.Allow_Monthly_budget_PC,A.AUTO_DAY_CLOSE,
						A.get_challan_thru_mirror,A.BUDGET_AT_EXPENSE_HEADS,A.exclusive_vat,A.exclusive_vat_to_disc,A.sor_loc,A.till_enabled,A.donot_post_stkxfer_entries,A.SLR_recon_reqd,A.slr_recon_cutoff_date,
						A.donot_send_challan_thru_mirror,A.DATE_OF_OPENING,A.report_blocked,A.inactive,A.accounts_posting_dept_id,A.control_ac_code,A.upd_purinfo,A.sspl_reg_key,A.wizcom_enabled,A.Excisable,
						A.tin_no,A.fr_type,A.primary_email_port,A.primary_email,A.Primary_Email_SMTP,A.primary_Email_pwd,A.primary_email_SSL,A.sspl_grp_code,A.pur_loc,A.address1,A.address2,A.dept_ac_code,A.cst_no,A.cst_dt,
						A.lst_no,A.lst_dt,A.dept_alias,A.phone,A.last_update,A.lead_days,A.mrr_series,A.allow_createac,A.data_polling,A.STN_APPROVAL,A.po_approval,A.server_loc,A.day_close_dt,A.donot_dayclose_if_till_open,A.SIS_LOC,
						A.RECEIVE_CCPYMT_ONLINE,A.Auto_send_stn,A.Auto_send_stn_interval,A.allow_purchase_at_ho,A.SSPL_REG_KEY_DET,A.REG_USERS,A.mbosls_import_mode,A.monthlyreco_cutoff_days,A.monthlyreco_cutoffdays_setup_date,A.build_rfopt,
						A.loc_gst_no,A.std_code,A.loc_id_as_barcode_prefix,A.Account_posting_at_ho,A.loc_gst_dt,A.registered_gst,A.gst_state_code,A.Registered_Add,A.DoNotSendChallanWithoutDispatch,A.EnableGSTReportConfig,
						A.donot_update_rfopt_xnentry,A.PREFIX_HO_ID_IN_WIZCLIP_DATA,A.enforce_customerwalkin_entry_dayclose,A.wizclip_dept_id,A.GROWTH_FACTOR,A.SAFETY_FACTOR,A.enforce_backup,A.APPLY_ONLINE_EOSS_FROM_HO,A.ENFORCE_OTP_BASED_GR,
						A.maintain_series_setup_at_ho,A.DONOT_MERGE_PARTYRATE,A.RestrictMaxStockAtRsp,A.MaxStockAtRsp,A.CurrentStockAtRsp,A.enable_accounting_at_loc,A.ask_for_consumables_billsaving,A.donot_merge_eoss,
						A.CONTACT_NO,A.Check_MonitorStatus_on_add_memo,A.timezonediff,A.eway_username,A.eway_pwd,A.WizClip,A.bill_count_restriction,A.DISCOUNT_PICKMODE_SLR,A.otp_based_cust_enroll,A.CESS_APPLICABLE,
						A.AUTO_CALCULATION_OF_ALTERATION_CHARGES,A.flow_config_Msg,A.invoice_control_ac_code,A.enforce_day_close_through_web,A.CHKPURDETAILS_IN_DN,A.primary_source_for_aro,A.enable_epaper_billing,
						A.Enable_Tcs,A.Tcs_Calculation_Locally,A.E_Token,A.E_owerid,A.Enable_EInvoice,A.Dept_Print_Name,A.Enable_EwayBill,A.Synch_sku,A.ENABLE_RACK_MANAGEMENT,A.EWAYBILLSUMMARYDETAIL,A.Taxable_Entry_ID,A.Branch_ID,
						A.Enable_Qr_Code_sale,A.Qr_Code_Paymode,A.CategoryCode,A.UPIID,A.BANK_ACCOUNT_NO,A.IFSC,A.UPIID_NAME,A.PICK_CUSTOMER_GST_STATE_IN_RETAIL_SALE,(CASE WHEN A.LOC_TYPE =1 THEN 'COMPANY OWNED' ELSE 'FRANCHISE OWNED' END) LOC_TYPE_NAME,
						 (CASE WHEN A.FR_TYPE =1 THEN 'CONSIGNMENT' ELSE 'OUTRIGHT' END) FR_TYPE_NAME, (CASE WHEN SIS_LOC= 1 THEN 'SIS' ELSE 'EBO' END ) LOC_GROUP,COUNTRY_NAME,
                        A1.attr1_key_name, a2.attr2_key_name, a3.attr3_key_name, a4.attr4_key_name, a5.attr5_key_name, a6.attr6_key_name, a7.attr7_key_name, a8.attr8_key_name, a9.attr9_key_name, a10.attr10_key_name,
						attr11_key_name,attr12_key_name,attr13_key_name,attr14_key_name,attr15_key_name,attr16_key_name,attr17_key_name,attr18_key_name,attr19_key_name,attr20_key_name,
						attr21_key_name,attr22_key_name,attr23_key_name,attr24_key_name,attr25_key_name

		FROM INSERTED A (NOLOCK)
		JOIN AREA B (NOLOCK) ON A.AREA_CODE = B.AREA_CODE  
		JOIN CITY C (NOLOCK) ON B.CITY_CODE = C.CITY_CODE  
		JOIN [STATE] D (NOLOCK) ON C.STATE_CODE = D.STATE_CODE  
		JOIN REGIONM E (NOLOCK) ON D.REGION_CODE = E.REGION_CODE
		LEFT JOIN COUNTRY CON (NOLOCK)  ON CON.COUNTRY_CODE =E.COUNTRY_CODE 
		LEFT JOIN LOC_FIX_ATTR af (NOLOCK) ON af.DEPT_ID =A.DEPT_ID 
		LEFT JOIN LocATTR1_MST A1 (NOLOCK) ON A1.ATTR1_KEY_CODE=af.attr1_KEY_CODE      
		LEFT JOIN LocATTR2_MST A2 (NOLOCK) ON A2.ATTR2_KEY_CODE=af.attr2_KEY_CODE      
		LEFT JOIN LocATTR3_MST A3 (NOLOCK) ON A3.ATTR3_KEY_CODE=af.attr3_KEY_CODE      
		LEFT JOIN LocATTR4_MST A4 (NOLOCK) ON A4.ATTR4_KEY_CODE=af.attr4_KEY_CODE      
		LEFT JOIN LocATTR5_MST A5 (NOLOCK) ON A5.ATTR5_KEY_CODE=af.attr5_KEY_CODE      
		LEFT JOIN LocATTR6_MST A6 (NOLOCK) ON A6.ATTR6_KEY_CODE=af.attr6_KEY_CODE      
		LEFT JOIN LocATTR7_MST A7 (NOLOCK) ON A7.ATTR7_KEY_CODE=af.attr7_KEY_CODE      
		LEFT JOIN LocATTR8_MST A8 (NOLOCK) ON A8.ATTR8_KEY_CODE=af.attr8_KEY_CODE      
		LEFT JOIN LocATTR9_MST A9 (NOLOCK) ON A9.ATTR9_KEY_CODE=af.attr9_KEY_CODE      
		LEFT JOIN LocATTR10_MST A10 (NOLOCK) ON A10.ATTR10_KEY_CODE=af.attr10_KEY_CODE
		LEFT JOIN LocATTR11_MST A11 (NOLOCK) ON A11.ATTR11_KEY_CODE=af.attr11_KEY_CODE
		LEFT JOIN LocATTR12_MST A12 (NOLOCK) ON A12.ATTR12_KEY_CODE=af.attr12_KEY_CODE
		LEFT JOIN LocATTR13_MST A13 (NOLOCK) ON A13.ATTR13_KEY_CODE=af.attr13_KEY_CODE
		LEFT JOIN LocATTR14_MST A14 (NOLOCK) ON A14.ATTR14_KEY_CODE=af.ATTR14_KEY_CODE
		LEFT JOIN LocATTR15_MST A15 (NOLOCK) ON A15.ATTR15_KEY_CODE=af.ATTR15_KEY_CODE
		LEFT JOIN LocATTR16_MST A16 (NOLOCK) ON A16.ATTR16_KEY_CODE=af.ATTR16_KEY_CODE
		LEFT JOIN LocATTR17_MST A17 (NOLOCK) ON A17.ATTR17_KEY_CODE=af.ATTR17_KEY_CODE
		LEFT JOIN LocATTR18_MST A18 (NOLOCK) ON A18.ATTR18_KEY_CODE=af.ATTR18_KEY_CODE
		LEFT JOIN LocATTR19_MST A19 (NOLOCK) ON A19.ATTR19_KEY_CODE=af.ATTR19_KEY_CODE
		LEFT JOIN LocATTR20_MST A20 (NOLOCK) ON A20.ATTR20_KEY_CODE=af.ATTR20_KEY_CODE
		LEFT JOIN LocATTR21_MST A21 (NOLOCK) ON A21.ATTR21_KEY_CODE=af.ATTR21_KEY_CODE
		LEFT JOIN LocATTR22_MST A22 (NOLOCK) ON A22.ATTR22_KEY_CODE=af.ATTR22_KEY_CODE
		LEFT JOIN LocATTR23_MST A23 (NOLOCK) ON a23.ATTR23_KEY_CODE=af.ATTR23_KEY_CODE
		LEFT JOIN LocATTR24_MST A24 (NOLOCK) ON a24.ATTR24_KEY_CODE=af.ATTR24_KEY_CODE
		LEFT JOIN LocATTR25_MST A25 (NOLOCK) ON a25.ATTR25_KEY_CODE=af.ATTR25_KEY_CODE;   
	END

		