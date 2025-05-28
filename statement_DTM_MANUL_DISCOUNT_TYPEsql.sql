IF NOT EXISTS(SELECT DT_CODE FROM DTM WHERE DT_CODE='DTM0001')
BEGIN
	INSERT DTM	( ac_code, apply_exclusive_vat, discount_percentage, dt_code, DT_DISCOUNT_AMOUNT, DT_MODE, dt_name, dtm_method, DTM_TYPE, FIXED, HO_SYNCH_LAST_UPDATE, 
	INACTIVE, last_update, update_ac, wizclip_discount )  
	SELECT 	'0000000000'  ac_code, 0 apply_exclusive_vat, 0 discount_percentage,'DTM0001' dt_code,0 DT_DISCOUNT_AMOUNT, 0 DT_MODE,'Manual Discount - Additional' dt_name,1 dtm_method,1 DTM_TYPE,1 FIXED,GETDATE() HO_SYNCH_LAST_UPDATE, 
	0 INACTIVE, GETDATE() last_update, 0 update_ac, 0 wizclip_discount 
END

IF NOT EXISTS(SELECT DT_CODE FROM DTM WHERE DT_CODE='DTM0002')
BEGIN
	INSERT DTM	( ac_code, apply_exclusive_vat, discount_percentage, dt_code, DT_DISCOUNT_AMOUNT, DT_MODE, dt_name, dtm_method, DTM_TYPE, FIXED, HO_SYNCH_LAST_UPDATE, 
	INACTIVE, last_update, update_ac, wizclip_discount )  
	SELECT 	'0000000000'  ac_code, 0 apply_exclusive_vat, 0 discount_percentage,'DTM0002' dt_code,0 DT_DISCOUNT_AMOUNT, 0 DT_MODE,'Manual Discount - Flat' dt_name,2 dtm_method,1 DTM_TYPE,1 FIXED,GETDATE() HO_SYNCH_LAST_UPDATE, 
	0 INACTIVE, GETDATE() last_update, 0 update_ac, 0 wizclip_discount 
END