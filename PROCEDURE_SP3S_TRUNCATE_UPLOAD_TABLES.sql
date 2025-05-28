create PROCEDURE SP3S_TRUNCATE_UPLOAD_TABLES
AS
BEGIN
	
	TRUNCATE TABLE xns_merge_checksum    
	truncate table gst_xns_hsn
	truncate table sls_gst_xns_hsn
	truncate table import_info
	truncate table xnsavelog
	truncate table genbarcode_rows
	TRUNCATE TABLE LOGPMT_COMP
	
	truncate table BATCHWISE_FIXCODE_UPLOAD
	truncate table GST_TAXINFO_CALC
	truncate table sls_gst_taxinfo_calc
	truncate table GST_TAXINFO_CALC_oh
	TRUNCATE TABLE JWR_barcode
	TRUNCATE TABLE JWI_barcode
	TRUNCATE TABLE ttm_barcode
	TRUNCATE TABLE PIM_POID_UPLOAD
	truncate table WSLORD_BUYER_ORDER_MST_UPLOAD
	truncate table WSLORD_BUYER_ORDER_det_UPLOAD


	truncate table WSL_ITEM_DETAILS


	TRUNCATE TABLE  SLS_PACK_SLIP_REF_UPLOAD

	TRUNCATE TABLE  SLS_PAYMODE_XN_DET_UPLOAD
		
	TRUNCATE TABLE SLS_COUPON_REDEMPTION_INFO_UPLOAD
				
	TRUNCATE TABLE SLS_DAILOGFILE_UPLOAD
		
	TRUNCATE TABLE SLS_CMD_MANUALBILL_ERRORS_UPLOAD				
		
	TRUNCATE TABLE SLS_CUSTDYM_UPLOAD

	TRUNCATE TABLE SLS_CMD01106_UPLOAD

	TRUNCATE TABLE SLS_PMT01106_UPLOAD

	TRUNCATE TABLE SLS_CMM01106_UPLOAD
	TRUNCATE TABLE SLS_CMD_CONS_UPLOAD

	truncate table cus_custdym_upload
	truncate table CUS_AREA_UPLOAD
	truncate table CUS_CITY_UPLOAD
	truncate table CUS_STATE_UPLOAD
	truncate table CUS_REGIONM_UPLOAD
	
	truncate table dnps_PMT01106_UPLOAD

	truncate table WSL_angm_UPLOAD
	truncate table WSL_IND01106_UPLOAD
	truncate table WSL_INM01106_UPLOAD
	truncate table WSL_INV_ATTR_MST_UPLOAD
	truncate table WSL_MBO_WSR_WSL_LINK_UPLOAD
	truncate table WSL_PARCEL_BILLS_UPLOAD
	truncate table WSL_parcel_det_UPLOAD
	truncate table WSL_parcel_mst_UPLOAD
	truncate table WSL_paymode_xn_det_UPLOAD
	truncate table WSL_PMT01106_UPLOAD

	TRUNCATE  table wps_wps_mst_upload
	TRUNCATE  table wps_wps_det_upload
	truncate table wps_PMT01106_UPLOAD

	TRUNCATE  table rps_rps_mst_upload
	TRUNCATE  table rps_rps_det_upload
	truncate table rps_PMT01106_UPLOAD

	TRUNCATE  table PRT_RMM01106_upload
	TRUNCATE  table PRT_RMD01106_upload
	truncate table PRT_PMT01106_UPLOAD
	truncate table PRT_PARCEL_MST_UPLOAD
	truncate table PRT_PARCEL_DET_UPLOAD

	TRUNCATE  table WSR_CNM01106_upload
	TRUNCATE  table WSR_CND01106_upload
	truncate table WSR_PMT01106_UPLOAD

    TRUNCATE TABLE VCH_VM01106_UPLOAD
    TRUNCATE TABLE VCH_VD01106_UPLOAD
	TRUNCATE TABLE VCH_VDT01106_UPLOAD
	TRUNCATE TABLE VCH_bill_by_bill_ref_UPLOAD
	TRUNCATE TABLE VCH_VD_chqbook_UPLOAD
	TRUNCATE TABLE VCH_postact_voucher_link_UPLOAD

    TRUNCATE TABLE ACT_VM01106_UPLOAD
    TRUNCATE TABLE ACT_VD01106_UPLOAD
	TRUNCATE TABLE ACT_bill_by_bill_ref_UPLOAD
	TRUNCATE TABLE ACT_postact_voucher_link_UPLOAD

	truncate table PUR_Art_attr_UPLOAD
	truncate table PUR_article_UPLOAD
	truncate table PUR_Attr_key_UPLOAD
	truncate table PUR_attrM_UPLOAD
	truncate table PUR_DailogFile_UPLOAD
	truncate table PUR_para1_UPLOAD
	truncate table PUR_para2_UPLOAD
	truncate table PUR_para3_UPLOAD
	truncate table PUR_para4_UPLOAD
	truncate table PUR_para5_UPLOAD
	truncate table PUR_para6_UPLOAD
	truncate table PUR_PARCEL_BILLS_UPLOAD
	truncate table PUR_parcel_det_upload
	truncate table PUR_pid01106_UPLOAD
	truncate table PUR_PIM_XN_APPROVAL_UPLOAD
	truncate table PUR_pim01106_UPLOAD
	truncate table PUR_PPC_PID01106_BARCODE_UPLOAD
	truncate table PUR_PPC_pid01106_UPLOAD
	truncate table PUR_PPC_PIM01106_UPLOAD
	truncate table PUR_ppc_PO_PUR_UPLOAD
	truncate table PUR_sectionD_UPLOAD
	truncate table PUR_sectionM_UPLOAD
	truncate table PUR_sku_oh_UPLOAD
	truncate table PUR_SKU_UPLOAD
	truncate table PUR_PMT01106_UPLOAD

	truncate table savetran_barcode_netqty
	truncate table savetran_updcols_updatestr

	truncate table MSTUSRROLE_BIN_MIRROR
	truncate table MSTUSRROLE_BIN_UPLOAD
	truncate table MSTUSRROLE_BINUSERS_MIRROR
	truncate table MSTUSRROLE_BINUSERS_UPLOAD
	truncate table MSTUSRROLE_config_MIRROR
	truncate table MSTUSRROLE_config_UPLOAD
	truncate table MSTUSRROLE_EMP_GRP_LINK_MIRROR
	truncate table MSTUSRROLE_EMP_GRP_LINK_UPLOAD
	truncate table MSTUSRROLE_EMPCATEGORY_MIRROR
	truncate table MSTUSRROLE_EMPCATEGORY_UPLOAD
	truncate table MSTUSRROLE_EMPLOYEE_GRP_MIRROR
	truncate table MSTUSRROLE_EMPLOYEE_GRP_UPLOAD
	truncate table MSTUSRROLE_employee_MIRROR
	truncate table MSTUSRROLE_employee_UPLOAD
	truncate table MSTUSRROLE_FixedFreeze_MIRROR
	truncate table MSTUSRROLE_FixedFreeze_UPLOAD
	truncate table MSTUSRROLE_locusers_MIRROR
	truncate table MSTUSRROLE_locusers_UPLOAD
	truncate table mstusrrole_rep_det_mirror
	truncate table mstusrrole_rep_det_upload
	truncate table mstusrrole_rep_filter_det_mirror
	truncate table mstusrrole_rep_filter_det_upload
	truncate table mstusrrole_rep_filter_mirror
	truncate table mstusrrole_rep_filter_upload
	truncate table mstusrrole_rep_mst_mirror
	truncate table mstusrrole_rep_mst_upload
	truncate table mstusrrole_replocs_mirror
	truncate table mstusrrole_replocs_upload
	truncate table MSTUSRROLE_RollingFreeze_MIRROR
	truncate table MSTUSRROLE_RollingFreeze_UPLOAD
	truncate table MSTUSRROLE_USER_ROLE_DET_MIRROR
	truncate table MSTUSRROLE_USER_ROLE_DET_UPLOAD
	truncate table MSTUSRROLE_USER_ROLE_MST_MIRROR
	truncate table MSTUSRROLE_USER_ROLE_MST_UPLOAD
	truncate table MSTUSRROLE_USER_XTREAM_LAYOUT_SETUP_MIRROR
	truncate table MSTUSRROLE_USER_XTREAM_LAYOUT_SETUP_UPLOAD
	truncate table MSTUSRROLE_users_MIRROR
	truncate table MSTUSRROLE_users_UPLOAD

	truncate table MSTLOC_till_sms_rec_MIRROR
	truncate table MSTLOC_till_sms_rec_UPLOAD
	truncate table MSTLOC_area_UPLOAD
	truncate table MSTLOC_till_sms_tmplt_MIRROR
	truncate table MSTLOC_till_sms_tmplt_UPLOAD
	truncate table MSTLOC_BIN_LOC_UPLOAD
	truncate table MSTLOC_till_sms_var_MIRROR
	truncate table MSTLOC_till_sms_var_UPLOAD
	truncate table MSTLOC_BIN_UPLOAD
	truncate table MSTLOC_till_users_MIRROR
	truncate table MSTLOC_BWD_DET_MIRROR
	truncate table MSTLOC_till_users_UPLOAD
	truncate table MSTLOC_BWD_DET_UPLOAD
	truncate table MSTLOC_XN_approval_checklist_level_details_MIRROR
	truncate table MSTLOC_BWD_MST_MIRROR
	truncate table MSTLOC_XN_approval_checklist_level_details_UPLOAD
	truncate table MSTLOC_BWD_MST_UPLOAD
	truncate table MSTLOC_XN_approval_checklist_level_users_MIRROR
	truncate table MSTLOC_catgrpdet_MIRROR
	truncate table MSTLOC_XN_approval_checklist_level_users_UPLOAD
	truncate table MSTLOC_catgrpdet_UPLOAD
	truncate table MSTLOC_SECTIOND_MIRROR
	truncate table MSTLOC_XN_approval_checklist_levels_MIRROR
	truncate table MSTLOC_catgrpmst_MIRROR
	truncate table MSTLOC_SECTIONM_MIRROR
	truncate table MSTLOC_XN_approval_checklist_levels_UPLOAD
	truncate table MSTLOC_catgrpmst_UPLOAD
	truncate table MSTLOC_XN_approval_checklist_mst_MIRROR
	truncate table MSTLOC_XN_approval_checklist_mst_UPLOAD
	truncate table MSTLOC_CITY_UPLOAD
	truncate table MSTLOC_config_UPLOAD
	truncate table MSTLOC_dtm_MIRROR
	truncate table MSTLOC_dtm_UPLOAD
	truncate table MSTLOC_gv_scheme_1_MIRROR
	truncate table MSTLOC_gv_scheme_1_UPLOAD
	truncate table MSTLOC_gv_scheme_locs_MIRROR
	truncate table MSTLOC_gv_scheme_locs_UPLOAD
	truncate table MSTLOC_gv_scheme_mst_MIRROR
	truncate table MSTLOC_gv_scheme_mst_UPLOAD
	truncate table MSTLOC_HD01106_UPLOAD
	truncate table MSTLOC_ITEMSEARCH_COL_DET_MIRROR
	truncate table MSTLOC_ITEMSEARCH_COL_DET_UPLOAD
	truncate table MSTLOC_jobs_MIRROR
	truncate table MSTLOC_jobs_UPLOAD
	truncate table MSTLOC_LICENSE_INFO_HO_MIRROR
	truncate table MSTLOC_LICENSE_INFO_HO_UPLOAD
	truncate table MSTLOC_LM01106_UPLOAD
	truncate table MSTLOC_LMP01106_UPLOAD
	truncate table MSTLOC_loc_billing_rules_form_MIRROR
	truncate table MSTLOC_loc_billing_rules_form_UPLOAD
	truncate table MSTLOC_loc_billing_rules_MIRROR
	truncate table MSTLOC_LOC_BILLING_RULES_ALLLOC_MIRROR
	truncate table MSTLOC_loc_billing_rules_SERIES_MIRROR
	truncate table MSTLOC_loc_billing_rules_SERIES_UPLOAD
	truncate table MSTLOC_FRANCHISE_LOC_LEDGER_SETUP_MIRROR
	truncate table MSTLOC_loc_billing_rules_UPLOAD
	truncate table MSTLOC_PREFIX_MIRROR
	truncate table MSTLOC_loc_req_MIRROR
	truncate table MSTLOC_loc_req_UPLOAD
	truncate table MSTLOC_loc_sale_target_MIRROR
	truncate table MSTLOC_loc_sale_target_UPLOAD
	truncate table MSTLOC_LOC_SPACE_DET_MIRROR
	truncate table MSTLOC_LOC_SPACE_DET_UPLOAD
	truncate table MSTLOC_LOC_SPACE_MST_MIRROR
	truncate table MSTLOC_LOC_SPACE_MST_UPLOAD
	truncate table MSTLOC_LOC_STOCK_LEVEL_DET_MIRROR
	truncate table MSTLOC_LOC_STOCK_LEVEL_DET_UPLOAD
	truncate table MSTLOC_LOC_STOCK_LEVEL_MST_MIRROR
	truncate table MSTLOC_LOC_STOCK_LEVEL_MST_UPLOAD
	truncate table MSTLOC_loc_xnsapproval_MIRROR
	truncate table MSTLOC_loc_xnsapproval_UPLOAD
	truncate table MSTLOC_location_UPLOAD
	truncate table MSTLOC_locsst_MIRROR
	truncate table MSTLOC_locsst_mst_MIRROR
	truncate table MSTLOC_locsst_mst_UPLOAD
	truncate table MSTLOC_locsst_UPLOAD
	truncate table MSTLOC_locsstAdd_MIRROR
	truncate table MSTLOC_locsstAdd_UPLOAD
	truncate table MSTLOC_MONTHLYBUDGET_HEAD_MIRROR
	truncate table MSTLOC_MONTHLYBUDGET_HEAD_UPLOAD
	truncate table MSTLOC_MonthlyBudget_MIRROR
	truncate table MSTLOC_MonthlyBudget_UPLOAD
	truncate table MSTLOC_PATCH_MRP_SETUP_MIRROR
	truncate table MSTLOC_PATCH_MRP_SETUP_UPLOAD
	truncate table MSTLOC_paymode_grp_mst_MIRROR
	truncate table MSTLOC_paymode_grp_mst_UPLOAD
	truncate table MSTLOC_paymode_mst_MIRROR
	truncate table MSTLOC_paymode_mst_UPLOAD
	truncate table MSTLOC_PETTY_CASH_AC_MIRROR
	truncate table MSTLOC_PETTY_CASH_AC_UPLOAD
	truncate table MSTLOC_prd_agency_mst_MIRROR
	truncate table MSTLOC_prd_agency_mst_UPLOAD
	truncate table MSTLOC_PrintDescription_MIRROR
	truncate table MSTLOC_PrintDescription_UPLOAD
	truncate table MSTLOC_PrintDetail_MIRROR
	truncate table MSTLOC_PrintDetail_UPLOAD
	truncate table MSTLOC_PrintHeader_MIRROR
	truncate table MSTLOC_PrintHeader_UPLOAD
	truncate table MSTLOC_PrintLocation_MIRROR
	truncate table MSTLOC_PrintLocation_UPLOAD
	truncate table MSTLOC_PrintMaster_MIRROR
	truncate table MSTLOC_PrintMaster_UPLOAD
	truncate table MSTLOC_PYMTG_DET_MIRROR
	truncate table MSTLOC_PYMTG_DET_UPLOAD
	truncate table MSTLOC_PYMTG_MST_MIRROR
	truncate table MSTLOC_PYMTG_MST_UPLOAD
	truncate table MSTLOC_Ref_Rep_mst_MIRROR
	truncate table MSTLOC_Ref_Rep_mst_UPLOAD
	truncate table MSTLOC_REG_HAND_SHAKE_MIRROR
	truncate table MSTLOC_REG_HAND_SHAKE_UPLOAD
	truncate table MSTLOC_regionM_UPLOAD
	truncate table MSTLOC_Rep_Adv_Filter_MIRROR
	truncate table MSTLOC_Rep_Adv_Filter_UPLOAD
	truncate table MSTLOC_rep_det_MIRROR
	truncate table MSTLOC_rep_det_UPLOAD
	truncate table MSTLOC_rep_filter_det_MIRROR
	truncate table MSTLOC_rep_filter_det_UPLOAD
	truncate table MSTLOC_rep_filter_MIRROR
	truncate table MSTLOC_rep_filter_UPLOAD
	truncate table MSTLOC_LOCATION_MIRROR
	truncate table MSTLOC_rep_mst_MIRROR
	truncate table MSTLOC_CONFIG_ATTR_MIRROR
	truncate table MSTLOC_rep_mst_UPLOAD
	truncate table MSTLOC_CONFIG_MIRROR
	truncate table MSTLOC_replocs_MIRROR
	truncate table MSTLOC_LM01106_MIRROR
	truncate table MSTLOC_replocs_UPLOAD
	truncate table MSTLOC_LMP01106_MIRROR
	truncate table MSTLOC_ALTERATIONSETUP_MIRROR
	truncate table MSTLOC_reports_MIRROR
	truncate table MSTLOC_HD01106_MIRROR
	truncate table MSTLOC_reports_UPLOAD
	truncate table MSTLOC_BIN_MIRROR
	truncate table MSTLOC_SaleContributionData_MIRROR
	truncate table MSTLOC_BIN_LOC_MIRROR
	truncate table MSTLOC_SaleContributionData_UPLOAD
	truncate table MSTLOC_AREA_MIRROR
	truncate table MSTLOC_SALEPERSON_TARGET_DET_MIRROR
	truncate table MSTLOC_CITY_MIRROR
	truncate table MSTLOC_SALEPERSON_TARGET_DET_UPLOAD
	truncate table MSTLOC_STATE_MIRROR
	truncate table MSTLOC_SALEPERSON_TARGET_MST_MIRROR
	truncate table MSTLOC_REGIONM_MIRROR
	truncate table MSTLOC_MEASUREMENT_MST_MIRROR
	truncate table MSTLOC_SALEPERSON_TARGET_MST_UPLOAD
	truncate table MSTLOC_GST_COMPANY_CONFIG_MIRROR
	truncate table MSTLOC_SALEPERSON_TARGET_SUBDET_MIRROR
	truncate table MSTLOC_GST_REPORT_CONFIG_MIRROR
	truncate table MSTLOC_SALEPERSON_TARGET_SUBDET_UPLOAD
	truncate table MSTLOC_GST_QUOTATION_MST_MIRROR
	truncate table MSTLOC_SEASON_MST_MIRROR
	truncate table MSTLOC_GST_TNC_MIRROR
	truncate table MSTLOC_SEASON_MST_UPLOAD
	truncate table MSTLOC_GST_XN_FORMAT_MIRROR
	truncate table MSTLOC_GST_XN_DETAIL_MIRROR
	truncate table MSTLOC_state_UPLOAD
	truncate table MSTLOC_GST_SLS_CUSTOMER_CONFIG_MIRROR
	truncate table MSTLOC_till_deno_mst_MIRROR
	truncate table MSTLOC_LUCKY_DRAW_LOC_MIRROR
	truncate table MSTLOC_till_deno_mst_UPLOAD
	truncate table MSTLOC_LUCKY_DRAW_SETUP_MIRROR
	truncate table MSTLOC_till_locs_MIRROR
	truncate table MSTLOC_SERIES_SETUP_MST_MIRROR
	truncate table MSTLOC_till_locs_UPLOAD
	truncate table MSTLOC_SERIES_SETUP_MANUAL_DET_MIRROR
	truncate table MSTLOC_till_mst_MIRROR
	truncate table MSTLOC_agency_jobs_MIRROR
	truncate table MSTLOC_till_mst_UPLOAD
	truncate table MSTLOC_agency_jobs_UPLOAD
	truncate table MSTLOC_till_sms_rec_loc_MIRROR
	truncate table MSTLOC_angm_MIRROR
	truncate table MSTLOC_till_sms_rec_loc_UPLOAD
	truncate table MSTLOC_angm_UPLOAD

	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_MST_UPLOAD      
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_DET_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_HAPPYHOURS_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_LOC_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SLSBC_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SLSART_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SCH0002_1_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SCH0007_1_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SCH0012_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SCH0006_1_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SCHB001_1_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SCHB002_1_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SLSBC_GET_UPLOAD 		
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SLSART_GET_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SLSEAN_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_SLSEAN_GET_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_ALLMASTERS_UPLOAD 
	TRUNCATE TABLE SCHNEW_SCHEME_SETUP_ALLMASTERS_CONFIG_UPLOAD 
	TRUNCATE TABLE SCHNEW_schemecopytitle_UPLOAD 
	
	TRUNCATE TABLE sls_xnsavelog_summary_upload
	
	TRUNCATE TABLE sor_pay_upload
	
	truncate table DOCPUR_PIM01106_UPLOAD 
	truncate table DOCPUR_PID01106_UPLOAD 
	truncate table DOCPUR_LM01106_UPLOAD 
	truncate table DOCPUR_LMP01106_UPLOAD
	truncate table DOCPUR_SECTIONM_UPLOAD
	truncate table DOCPUR_SECTIOND_UPLOAD
	truncate table DOCPUR_ARTICLE_UPLOAD
	truncate table DOCPUR_PARA1_UPLOAD
	truncate table DOCPUR_PARA2_UPLOAD
	truncate table DOCPUR_PARA3_UPLOAD
	truncate table DOCPUR_PARA4_UPLOAD
	truncate table DOCPUR_PARA5_UPLOAD
	truncate table DOCPUR_PARA6_UPLOAD
	truncate table DOCPUR_sku_UPLOAD
	truncate table DOCPUR_sku_oh_UPLOAD
	truncate table DOCPUR_config_UPLOAD
	truncate table DOCPUR_UOM_UPLOAD
	
	truncate table DOCPUR_ARTICLE_FIX_ATTR_Upload
	truncate table DOCPUR_SD_ATTR_AVATAR_Upload
	truncate table DOCPUR_ATTR1_MST_Upload
	truncate table DOCPUR_ATTR2_MST_Upload
	truncate table DOCPUR_ATTR3_MST_Upload
	truncate table DOCPUR_ATTR4_MST_Upload
	truncate table DOCPUR_ATTR5_MST_Upload
	truncate table DOCPUR_ATTR6_MST_Upload
	truncate table DOCPUR_ATTR7_MST_Upload
	truncate table DOCPUR_ATTR8_MST_Upload
	truncate table DOCPUR_ATTR9_MST_Upload
	truncate table DOCPUR_ATTR10_MST_Upload
	truncate table DOCPUR_ATTR11_MST_Upload
	truncate table DOCPUR_ATTR12_MST_Upload
	truncate table DOCPUR_ATTR13_MST_Upload
	truncate table DOCPUR_ATTR14_MST_Upload
	truncate table DOCPUR_ATTR15_MST_Upload
	truncate table DOCPUR_ATTR16_MST_Upload
	truncate table DOCPUR_ATTR17_MST_Upload
	truncate table DOCPUR_ATTR18_MST_Upload
	truncate table DOCPUR_ATTR19_MST_Upload
	truncate table DOCPUR_ATTR20_MST_Upload
	truncate table DOCPUR_ATTR21_MST_Upload
	truncate table DOCPUR_ATTR22_MST_Upload
	truncate table DOCPUR_ATTR23_MST_Upload
	truncate table DOCPUR_ATTR24_MST_Upload
	truncate table DOCPUR_ATTR25_MST_Upload


	truncate table PSJWI_POST_SALES_JOBWORK_ISSUE_MST_UPLOAD
	truncate table PSJWI_POST_SALES_JOBWORK_ISSUE_DET_UPLOAD
	truncate table PSJWR_POST_SALES_JOBWORK_RECEIPT_MST_UPLOAD
	truncate table PSJWR_POST_SALES_JOBWORK_RECEIPT_DET_UPLOAD
	truncate table PSHBD_HOLD_BACK_DELIVER_MST_UPLOAD
	truncate table PSHBD_SKU_UPLOAD
	truncate table PSHBD_HOLD_BACK_DELIVER_DET_UPLOAD

	TRUNCATE TABLE sku_diff
	truncate table BCO_FLOOR_ST_MST_UPLOAD
	truncate table BCO_FLOOR_ST_DET_UPLOAD
	truncate table BCO_sku_UPLOAD
	truncate table BCO_PMT01106_UPLOAD
	truncate table snc_snc_mst_upload
	truncate table snc_snc_det_upload
	truncate table snc_snc_consumable_det_upload

	TRUNCATE TABLE APP_APD01106_UPLOAD
	TRUNCATE TABLE APP_APM01106_UPLOAD 
	TRUNCATE TABLE APP_AREA_UPLOAD 
	TRUNCATE TABLE APP_city_UPLOAD 
	TRUNCATE TABLE APP_CUSTDYM_UPLOAD 
	TRUNCATE TABLE APP_pmt01106_UPLOAD 
	TRUNCATE TABLE APP_state_UPLOAD 
	
	TRUNCATE TABLE APR_APPROVAL_RETURN_MST_UPLOAD
	TRUNCATE TABLE APR_APPROVAL_RETURN_DET_UPLOAD
	TRUNCATE TABLE APR_pmt01106_UPLOAD
	
	TRUNCATE TABLE PRCL_PARCEL_MST_UPLOAD
	TRUNCATE TABLE PRCL_PARCEL_DET_UPLOAD
	TRUNCATE TABLE PRCL_ANGM_UPLOAD
	
	TRUNCATE TABLE DNPS_DNPS_MST_UPLOAD
	TRUNCATE TABLE DNPS_DNPS_DET_UPLOAD
	TRUNCATE TABLE DNPS_PMT01106_UPLOAD

	TRUNCATE TABLE XNR_XNRECONP_UPLOAD
	TRUNCATE TABLE XNR_XNRECONC_UPLOAD

	truncate table mstsync_hsn_mst_upload
	 truncate table mstsync_hsn_det_upload
	 truncate table mstsync_uom_upload
	 truncate table mstsync_art_para1_upload
	 truncate table MSTSYNC_art_det_UPLOAD
	 truncate table MSTSYNC_lm01106_UPLOAD
	 truncate table MSTSYNC_lmp01106_UPLOAD
	 truncate table MSTSYNC_SKU_OH_UPLOAD
	 truncate table MSTSYNC_SKU_UPLOAD
	 truncate table MSTSYNC_article_UPLOAD
	 truncate table MSTSYNC_Sectiond_UPLOAD
	 truncate table MSTSYNC_Sectionm_UPLOAD
	 TRUNCATE TABLE MSTSYNC_article_fix_attr_upload
	 TRUNCATE TABLE MSTSYNC_sd_attr_avatar_upload

END 




--select 'truncate table '+table_name from INFORMATION_SCHEMA.tables where left(TABLE_NAME,6)='mstloc'

