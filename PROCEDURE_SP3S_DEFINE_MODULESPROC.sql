create PROCEDURE SP3S_DEFINE_MODULESPROC
AS
BEGIN

	delete from  modules_proc

	insert into modules_proc (module_name,proc_name)
	select 'sls','Savetran_sls_beforesave' union all
	select 'sls','Savetran_sls_aftersave' union all
	select 'sls','SP3S_upd_qty_lastupdate' union all
	select 'sls','SP3S_DELETEUPLOADTABLES_SLS' union all
	select 'sls','SP3S_UPDATESHIFT_AMOUNT' union all
	select 'sls','SAVETRAN_DELETE_MISSINGROWS' union all
	select 'sls','SP3S_UPDATE_PMTSTOCK_SLS' union all
	select 'sls','SP3S_VALIDATE_GST_PERCENTAGE' union all
	select 'sls','SP_VALIDATE_MEMODATE_SLS' union all
	select 'sls','SP_VALIDATE_MEMODATE_OPT' union all
	select 'sls','VALIDATEXN_SLS_AFTERSAVE' union all
	select 'sls','SP3S_GENAPR_DATA' union all
	select 'sls','SP3S_CAPTURE_AUDIT_TRAIL' union all
	select 'sls','SP3S_EOSS_APPLY_SLSDISCTAX' union all
	select 'sls','SP3S_UPDATE_CMM_LASTDTCODE' union all
	select 'sls','SP3S_EOSS_GETDISCOUNTS' union all
	select 'sls','SP_RECAL_CMMDISC_CMD' union all
	select 'sls','SP3S_CALTOTALS_SLS' union all
	select 'sls','SP_VALIDATEXN_BEFORESAVE_SLS_OPTIMIZED' union all
	select 'sls','SP3S_RESTRICT_BILLSAVING_WITHOUTRACK' union all
	select 'sls','SP3S_NORMALIZE_FIX_PRODUCT_CODE' union all
	select 'sls','SP3S_FETCH_BATCHWISEBC' union all
	select 'sls','SP3S_NORMALIZE_for_eoss' union all
	select 'sls','SP_GETCARD_DISCOUNT_PERCETAGE' union all
	select 'sls','SP3S_EOSS_APPLY_ALLMASTERS_FLAT_DISCOUNT' union all
	select 'sls','SP3S_EOSS_GETSCHEMES_PARA_COMBINATION' union all
	select 'sls','SP3S_EOSS_UPDATESCHEME_WTDDISC' union all
	select 'sls','SP3S_EOSS_UPDATE_ADDITIONAL_DISCOUNT_FLATSCHEME' union all
	select 'sls','SP3S_CMD_ZERO_GST_CAL' union all
	select 'sls','SP3S_GST_TAX_CAL_SLS' UNION ALL
	select 'sls','SP3S_GST_TAX_CAL_OH_SLS' UNION ALL
	select 'sls','SP3S_IMPORT_SLS_DATA_UPLOAD' UNION ALL
	select 'sls','SP3S_UPDATE_SISLOC_SALEVAL_DIFFERENCES' UNION ALL
	select 'sls','SP3S_UPD_SKUXFPNEW' UNION ALL
	SELECT 'SLS','SP3S_RECALSLS_CMDNET_SLSSETUPDISABLED' union all
	select 'sls',sp_name from  promotional_schemes_mst union all
	select 'rps','SP_APPLY_SLSDISCTAX' UNION ALL
	select 'rps','SP3S_EOSS_APPLY_SLSDISCTAX' union all
	select 'rps','SP_RECAL_CMMDISC_CMD' union all
	select 'rps','SP3S_EOSS_GETDISCOUNTS' union all
	select 'rps','savetran_rps' union all
	select 'rps','SP3S_NORMALIZE_FIX_PRODUCT_CODE' union all
	select 'rps','SP3S_UPDATE_PMTSTOCK_RPS' union all
	select 'rps','SP3S_FETCH_BATCHWISEBC' union all
	select 'rps','SP3S_VALIDATE_EOSSDATA' union all
	select 'rps','SP3S_GENAPR_DATA' union all
	select 'sls','SP3S_VALIDATE_EOSSDATA' union all
	select 'rps',sp_name from  promotional_schemes_mst 

	
	insert into modules_proc (module_name,proc_name,SUB_PROC_NAME)
	select 'sls','Savetran_sls_beforesave','SP3S_EOSS_APPLY_SLSDISCTAX' UNION ALL
	select 'sls','Savetran_sls_beforesave','SP_RECAL_CMMDISC_CMD' UNION ALL
	select 'sls','Savetran_sls_beforesave','SP3S_CALTOTALS_SLS' union all
	select 'sls','Savetran_sls_beforesave','SP_VALIDATEXN_BEFORESAVE_SLS_OPTIMIZED' union all
	select 'sls','Savetran_sls_beforesave','SP3S_UPDATE_SISLOC_SALEVAL_DIFFERENCES' UNION ALL
	select 'sls','Savetran_sls_beforesave','SP3S_APPLY_BILLLEVEL_SCHEME' UNION ALL
	select 'sls','SP3S_RECALSLS_CMDNET_SLSSETUPDISABLED','SP_GETCARD_DISCOUNT_PERCETAGE' union all
	select 'sls','Savetran_sls_beforesave','SP3S_RECALSLS_CMDNET_SLSSETUPDISABLED' UNION ALL
	select 'sls','SP3S_APPLY_BILLLEVEL_SCHEME','SP3S_EOSS_SCHEMES_BILLMST_2' UNION ALL
	select 'sls','Savetran_sls_beforesave','SP3S_UPDATE_CMM_LASTDTCODE' UNION ALL
	select 'sls','SP3S_APPLY_BILLLEVEL_SCHEME','SP3S_EOSS_SCHEMES_BILLMST_1' UNION ALL
	select 'sls','SP3S_EOSS_APPLY_SLSDISCTAX','SP3S_FETCH_BATCHWISEBC' UNION ALL
	select 'sls','SP3S_EOSS_APPLY_SLSDISCTAX','SP3S_NORMALIZE_for_eoss' union all
	select 'sls','SP3S_EOSS_APPLY_SLSDISCTAX','SP_GETCARD_DISCOUNT_PERCETAGE' union all
	select 'sls','SP3S_EOSS_APPLY_SLSDISCTAX','SP_WL_PICKLASTDISCOUNT' union all
	select 'sls','SP3S_EOSS_APPLY_SLSDISCTAX','SP3S_EOSS_GETDISCOUNTS' union all
	select 'sls','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_APPLY_ALLMASTERS_FLAT_DISCOUNT' union all
	select 'sls','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_GETSCHEMES_PARA_COMBINATION' union all
	select 'sls','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_UPDATESCHEME_WTDDISC' union all
	select 'sls','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_UPDATE_ADDITIONAL_DISCOUNT_FLATSCHEME' union all
	select 'sls','SP_VALIDATEXN_BEFORESAVE_SLS_OPTIMIZED','SP3S_RESTRICT_BILLSAVING_WITHOUTRACK' UNION ALL
	select 'sls','SP3S_NORMALIZE_FIX_PRODUCT_CODE','SP3S_REPROCESS_FIXPRODUCT_DISCOUNT' UNION ALL
	select 'sls','Savetran_sls_aftersave','SP3S_upd_qty_lastupdate' union all
	select 'sls','Savetran_sls_aftersave','SP3S_UPDATESHIFT_AMOUNT' union all
	select 'sls','Savetran_sls_aftersave','SAVETRAN_DELETE_MISSINGROWS' union all
	select 'sls','Savetran_sls_aftersave','SP3S_UPDATE_PMTSTOCK_SLS' union all
	select 'sls','Savetran_sls_aftersave','SP3S_VALIDATE_GST_PERCENTAGE' union all
	select 'sls','Savetran_sls_aftersave','SP_VALIDATE_MEMODATE_SLS' union all
	select 'sls','Savetran_sls_aftersave','SP3S_GENAPR_DATA' union all
	select 'sls','Savetran_sls_aftersave','SP3S_CAPTURE_AUDIT_TRAIL' union all
	select 'sls','Savetran_sls_aftersave','SP_VALIDATE_MEMODATE_OPT' union all
	select 'sls','Savetran_sls_aftersave','VALIDATEXN_SLS_AFTERSAVE' union all
	select 'sls','Savetran_sls_aftersave','SP3S_DELETEUPLOADTABLES_SLS'  union all
	select 'sls','Savetran_sls_aftersave','SP3S_UPD_SKUXFPNEW'  union all
	select 'sls','Savetran_sls_beforesave','SP3S_NORMALIZE_FIX_PRODUCT_CODE' union all
	select 'sls','validatexn_sls_aftersave','SP3S_CMD_ZERO_GST_CAL' union all
	select 'sls','SP3S_CALTOTALS_SLS','SP3S_GST_TAX_CAL_SLS' UNION ALL
	select 'sls','SP3S_CALTOTALS_SLS','SP3S_REPROCESS_GST_CALCULATION' union all
	select 'sls','SP3S_GST_TAX_CAL_SLS','SP3S_GST_TAX_CAL_OH_SLS' UNION ALL
	select 'sls','SP3S_FETCH_BATCHWISEBC','SP3S_NORMALIZE_FIX_PRODUCT_CODE' UNION ALL
	select 'rps','SP_APPLY_SLSDISCTAX','SP3S_EOSS_APPLY_SLSDISCTAX' union all
	select 'rps','SP3S_EOSS_APPLY_SLSDISCTAX','SP_RECAL_CMMDISC_CMD' UNION ALL
	select 'rps','SP3S_EOSS_APPLY_SLSDISCTAX','SP3S_EOSS_GETDISCOUNTS' union all
	select 'rps','SP3S_EOSS_APPLY_SLSDISCTAX','SP3S_FETCH_BATCHWISEBC' UNION ALL
	select 'rps','SP3S_EOSS_APPLY_SLSDISCTAX','SP3S_NORMALIZE_for_eoss' union all
	select 'rps','SP3S_EOSS_APPLY_SLSDISCTAX','SP_GETCARD_DISCOUNT_PERCETAGE' union all
	select 'rps','SP3S_EOSS_APPLY_SLSDISCTAX','SP_WL_PICKLASTDISCOUNT' union all
	select 'rps','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_APPLY_ALLMASTERS_FLAT_DISCOUNT' union all
	select 'rps','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_GETSCHEMES_PARA_COMBINATION' union all
	select 'rps','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_UPDATESCHEME_WTDDISC' union all
	select 'rps','SP3S_EOSS_GETDISCOUNTS','SP3S_EOSS_UPDATE_ADDITIONAL_DISCOUNT_FLATSCHEME' union all
	select 'rps','SP3S_FETCH_BATCHWISEBC','SP3S_NORMALIZE_FIX_PRODUCT_CODE' UNION ALL

	select 'rps','savetran_rps','SP3S_NORMALIZE_FIX_PRODUCT_CODE' union all
	select 'rps','savetran_rps','SP3S_UPDATE_PMTSTOCK_RPS' union all
	select 'rps','SP3S_NORMALIZE_FIX_PRODUCT_CODE','SP3S_REPROCESS_FIXPRODUCT_DISCOUNT' UNION ALL
	SELECT 'SLS','sp3s_eoss_schemes_15','SP3S_VALIDATE_EOSSDATA' UNION ALL
	SELECT 'RPS','sp3s_eoss_schemes_15','SP3S_VALIDATE_EOSSDATA' UNION ALL
	SELECT 'SLS','sp3s_eoss_schemes_2','SP3S_VALIDATE_EOSSDATA' UNION ALL
	SELECT 'RPS','sp3s_eoss_schemes_2','SP3S_VALIDATE_EOSSDATA' UNION ALL
	select 'RPS','Savetran_rps','SP3S_GENAPR_DATA' union all
	select 'sls','SP3S_EOSS_GETDISCOUNTS',sp_name from  promotional_schemes_mst union all
	select 'rps','SP3S_EOSS_GETDISCOUNTS',sp_name from  promotional_schemes_mst


	--Purchase entry of Modules Proc
	  
	  insert into modules_proc (module_name,proc_name)
	select 'PUR','Savetran_PUR' union all
	select 'PUR','SP3S_DELETEUPLOADTABLES_PUR' union all
	select 'PUR','SP3S_UPDATE_PMTSTOCK_PUR' union all
	select 'PUR','SP3S_CAPTURE_AUDIT_TRAIL' union all
	select 'PUR','SP3S_upd_qty_lastupdate' union all
	select 'PUR','SP3S_VALIDATEXN_ITEMTYPE' union all
	select 'PUR','SAVETRAN_GENPERISHABLE_BARCODE' union all
	select 'PUR','SAVETRAN_GENBARCODES_PUR' union all
	select 'PUR','SP3S_INSERT_PARA7' union all
	select 'PUR','SP3S_BUILD_PO_VS_PI' union all
	select 'PUR','SP3S_CALTOTALS_PUR' union all
	select 'PUR','SAVETRAN_PUR_UPDSKU' union all
	select 'PUR','SP3S_VERIFY_PURDATA_CHANGES' union all  --pending
	select 'PUR','SAVETRAN_GENBARCODES_COMMONSTEPS' union all
	select 'PUR','SP3S_GST_TAX_CAL' union all
	select 'PUR','SP3S_PUR_CONVERT_FOREX_INR' union all
	select 'PUR','SAVETRAN_GENVENDOR_EANCODES' union all
	select 'PUR','SP3S_GST_TAX_CAL_OH' union all
	select 'PUR','SAVETRAN_GENONLINE_SKU' union all
	select 'PUR','SAVETRAN_GETMEMOPREFIX' union all
	select 'PUR','SP3S_UPDATE_SKUNAMES'

	insert into modules_proc (module_name,proc_name,SUB_PROC_NAME)
	select 'PUR','Savetran_PUR','SP3S_UPDATE_PMTSTOCK_PUR' union all
	select 'PUR','Savetran_PUR','SP3S_DELETEUPLOADTABLES_PUR'  union all
	select 'PUR','Savetran_PUR','SP3S_CAPTURE_AUDIT_TRAIL' union all
	select 'PUR','Savetran_PUR','SP3S_upd_qty_lastupdate' union all
	select 'PUR','Savetran_PUR','SP3S_VALIDATEXN_ITEMTYPE' union all
	select 'PUR','Savetran_PUR','SAVETRAN_GENPERISHABLE_BARCODE' union all
	select 'PUR','Savetran_PUR','SAVETRAN_GENBARCODES_PUR' union all
	select 'PUR','Savetran_PUR','SP3S_BUILD_PO_VS_PI' union all
	select 'PUR','Savetran_PUR','SP3S_CALTOTALS_PUR' union all
	select 'PUR','Savetran_PUR','SAVETRAN_PUR_UPDSKU' union all
	select 'PUR','Savetran_PUR','SP3S_VERIFY_PURDATA_CHANGES' Union all
	select 'PUR','Savetran_PUR','SAVETRAN_GETMEMOPREFIX' Union all
	select 'PUR','Savetran_PUR','SP3S_UPDATE_SKUNAMES' Union all

	select 'PUR','SAVETRAN_GENBARCODES_PUR','SAVETRAN_GENBARCODES_COMMONSTEPS' union all
	select 'PUR','SAVETRAN_GENBARCODES_PUR','SP3S_INSERT_PARA7' union all
	select 'PUR','SP3S_CALTOTALS_PUR','SP3S_GST_TAX_CAL' union all
	select 'PUR','SP3S_CALTOTALS_PUR','SP3S_PUR_CONVERT_FOREX_INR' union all

	select 'PUR','SAVETRAN_GENBARCODES_COMMONSTEPS','SAVETRAN_GENPERISHABLE_BARCODE' union all
	select 'PUR','SAVETRAN_GENBARCODES_COMMONSTEPS','SAVETRAN_GENVENDOR_EANCODES' union all
	select 'PUR','SP3S_GST_TAX_CAL','SP3S_GST_TAX_CAL_OH' union all

	select 'PUR','SAVETRAN_GENVENDOR_EANCODES','SAVETRAN_GENONLINE_SKU' 

	insert into modules_proc (module_name,proc_name)
	select 'PUR','SAVETRAN_CONVERT_MRN_TO_BILL' 

	insert into modules_proc (module_name,proc_name,SUB_PROC_NAME)
	select 'PUR','SAVETRAN_CONVERT_MRN_TO_BILL','SAVETRAN_GETMEMOPREFIX' Union all
	select 'PUR','SAVETRAN_CONVERT_MRN_TO_BILL','SP3S_CALTOTALS_PUR' Union all
	select 'PUR','SAVETRAN_CONVERT_MRN_TO_BILL','SAVETRAN_PUR_UPDSKU' 
	


	--End of Purchase entry of Modules Proc


	insert into modules_proc (module_name,proc_name)
	select a.module_name,a.sub_proc_name proc_name from modules_proc a left join modules_proc b on a.module_name=b.module_name
	and a.sub_proc_name=b.proc_name
	where b.proc_name is null and a.sub_proc_name is not null

	delete from  modules_tables

	INSERT INTO modules_tables (module_name,table_name)
	SELECT 'sls','sls_gst_xns_hsn' UNION ALL
	SELECT 'sls','SLS_GST_TAXINFO_CALC' UNION ALL
	SELECT 'sls','SLS_GST_TAXINFO_CALC_OH' UNION ALL
	SELECT 'sls','SLS_CMM01106_UPLOAD' UNION ALL
	SELECT 'sls','SLS_CMD01106_UPLOAD' UNION ALL
	SELECT 'sls','SLS_PAYMODE_XN_DET_UPLOAD' UNION ALL
	SELECT 'sls','SLS_PACK_SLIP_REF_UPLOAD' UNION ALL
	SELECT 'sls','SLS_CMM_FLIGHT_UPLOAD' UNION ALL
	SELECT 'sls','SLS_COUPON_REDEMPTION_INFO_UPLOAD' UNION ALL
	SELECT 'sls','SLS_GV_MST_REDEMPTION_UPLOAD' UNION ALL
	SELECT 'sls','SLS_cmd_cons_UPLOAD' UNION ALL
	SELECT 'sls','sls_xnsavelog_summary_UPLOAD' UNION ALL
	SELECT 'sls','SLS_APM01106_REF_UPLOAD' UNION ALL
	SELECT 'sls','BATCHWISE_FIXCODE_UPLOAD' UNION ALL
	SELECT 'rps','RPS_RPS_MST_UPLOAD' UNION ALL
	SELECT 'rps','RPS_RPS_DET_UPLOAD' UNION ALL
	SELECT 'rps','BATCHWISE_FIXCODE_UPLOAD' UNION ALL
	SELECT 'rps','RPS_APM01106_REF_UPLOAD' 
    --Purchase entry of modules_tables

	INSERT INTO modules_tables (module_name,table_name)
	SELECT 'PUR','pur_pim01106_upload' UNION ALL
	SELECT 'PUR','pur_pid01106_upload' UNION ALL
	SELECT 'PUR','PIM_POID_UPLOAD' UNION ALL
	SELECT 'PUR','PUR_PARCEL_DET_UPLOAD' UNION ALL
	SELECT 'PUR','keys_perishable' UNION ALL
	SELECT 'PUR','GST_TAXINFO_CALC' UNION ALL
	SELECT 'PUR','GST_TAXINFO_TAXFREE' UNION ALL
	SELECT 'PUR','gst_xns_hsn' UNION ALL
	SELECT 'PUR','GENBARCODE_ROWS' UNION ALL
	SELECT 'PUR','GST_TAXINFO_CALC_OH' 
	UNION ALL
	SELECT 'PUR','PUR_PARCEL_BILLS_UPLOAD' 

	--End of Purchase entry of modules_tables


END
