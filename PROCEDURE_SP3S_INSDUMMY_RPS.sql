create procedure SP3S_INSDUMMY_RPS
as
begin
    if exists (select top 1 cm_id from RPS_MST (nolock) where cm_id='XXXXXXXXXX' and CANCELLED =0)
       Update a set CANCELLED =1 from RPS_MST A (nolock) where cm_id='XXXXXXXXXX'
    
	if exists (select top 1 cm_id from RPS_MST (nolock) where cm_id='XXXXXXXXXX')
		return

	INSERT RPS_MST	( atd_charges,mrp_wsp,CUSTOMER_CODE,copies_ptd,CM_NO,CM_DT,CM_MODE,SUBTOTAL,NET_AMOUNT,CANCELLED,USER_CODE,LAST_UPDATE,computer_name,sent_to_ho,cm_time,cm_id,ref_cm_id,
	fin_year,DISCOUNT_PERCENTAGE,DISCOUNT_AMOUNT,REMARKS,sent_for_recon,Manual_discount,BIN_ID,tat_days,total_quantity,auto_posreco_last_update,EDIT_INFO,OLAP_SYNCH_LAST_UPDATE,
	quantity_last_update,mrp_exchange_bill,ROUND_OFF)  
	SELECT 0	atd_charges,0 mrp_wsp,NULL CUSTOMER_CODE,0 copies_ptd,'' CM_NO,'' CM_DT,1 CM_MODE,0 SUBTOTAL,0 NET_AMOUNT,1 CANCELLED,'0000000' USER_CODE,GETDATE() LAST_UPDATE,'' computer_name,0 sent_to_ho,GETDATE() cm_time,'XXXXXXXXXX' cm_id,'' ref_cm_id,
	'' fin_year,0 DISCOUNT_PERCENTAGE,0 DISCOUNT_AMOUNT,'Cancelled entry for handling Sale merging' REMARKS,0 sent_for_recon,0 Manual_discount,'000' BIN_ID,0 tat_days,0 total_quantity,'' auto_posreco_last_update,'' EDIT_INFO,'' OLAP_SYNCH_LAST_UPDATE,
	'' quantity_last_update,0 mrp_exchange_bill,0 ROUND_OFF

end
