update GRN_PS_MST set location_code=left(memo_id,2) where isnull(location_code,'')=''  AND MEMO_ID<>'XXXXXXXXXX'
update cnps_mst set location_code=left(ps_id,2) where isnull(location_code,'')='' AND PS_ID<>'XXXXXXXXXX'
update dnps_mst set location_code=left(ps_id,2) where isnull(location_code,'')='' AND PS_ID<>'XXXXXXXXXX'
update rps_mst set location_code=left(cm_id,2) where isnull(location_code,'')='' AND cm_ID<>'XXXXXXXXXX'
update cmm01106 set location_code=left(cm_id,2) where isnull(location_code,'')='' AND cm_ID<>'XXXXXXXXXX'
update rmm01106 set location_code=left(rm_id,2) where isnull(location_code,'')='' AND rm_ID<>'XXXXXXXXXX'
update DOCPRT_rmm01106_MIRROR set location_code=left(rm_id,2) where isnull(location_code,'')=''
update wps_mst set location_code=left(ps_id,2) where isnull(location_code,'')='' AND ps_ID<>'XXXXXXXXXX'
update inm01106 set location_code=left(inv_id,2) where isnull(location_code,'')='' AND inv_ID<>'XXXXXXXXXX'
update docwsl_inm01106_mirror set location_code=left(inv_id,2) where isnull(location_code,'')=''
update pim01106 set location_code=dept_id where isnull(location_code,'')='' AND Mrr_ID<>'XXXXXXXXXX'
update cnm01106 set location_code=left(cn_id,2) where isnull(location_code,'')='' AND cn_ID<>'XXXXXXXXXX'
update snc_mst set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update irm01106 set location_code=left(irm_memo_id,2) where isnull(location_code,'')='' AND irm_MEMO_ID<>'XXXXXXXXXX'
update scm01106 set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update jobwork_issue_mst set location_code=left(issue_id,2) where isnull(location_code,'')='' AND issue_ID<>'XXXXXXXXXX'
update jobwork_receipt_mst set location_code=left(receipt_id,2) where isnull(location_code,'')='' AND receipt_ID<>'XXXXXXXXXX'
update pom01106 set location_code=left(po_id,2) where isnull(location_code,'')='' AND po_ID<>'XXXXXXXXXX'
update buyer_order_mst set location_code=left(order_id,2) where isnull(location_code,'')='' AND order_ID<>'XXXXXXXXXX'
update wsl_order_mst set location_code=left(order_id,2) where isnull(location_code,'')='' AND left(order_ID,5)<>'XXXXX'
update arc01106 set location_code=left(adv_rec_id,2) where isnull(location_code,'')='' AND adv_rec_ID<>'XXXXXXXXXX'
update apm01106 set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update approval_return_mst set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update floor_st_mst set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update BOM_ISSUE_MST set location_code=left(issue_id,2) where isnull(location_code,'')='' AND ISSUE_ID<>'XXXXXXXXXX'
update PRD_TRANSFER_MAIN_MST set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update icm01106 set location_code=left(cnc_memo_id,2) where isnull(location_code,'')='' AND CNC_MEMO_ID<>'XXXXXXXXXX'
update slr_recon_mst set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update vm01106 set location_code=left(vm_id,2) where isnull(location_code,'')='' AND VM_ID<>'XXXXXXXXXX'
update BOMDQRQMST set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update sls_delivery_mst set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update ORD_PLAN_MST set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update TRANSFER_TO_TRADING_MST set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update pco_mst SET location_Code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update pco_mst SET target_location_Code=substring(memo_no,3,2) where isnull(target_location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update pem01106 SET location_Code=left(pem_memo_id,2) where isnull(location_code,'')='' AND PEM_MEMO_ID<>'XXXXXXXXXX'
update GV_STKXFER_MST SET location_Code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update SLS_STOCK_NA_REP_MST  SET location_Code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update stmh01106  SET location_Code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update HOLD_BACK_DELIVER_MST set location_code=left(memo_id,2) where isnull(location_code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update POST_SALES_JOBWORK_ISSUE_MST set location_code=left(issue_id,2) where isnull(location_code,'')='' AND ISSUE_ID<>'XXXXXXXXXX'
update POST_SALES_JOBWORK_receipt_MST set location_code=left(receipt_id,2) where isnull(location_code,'')='' AND RECEIPT_ID<>'XXXXXXXXXX'
Update a set location_code =left(a.xn_id,2) from  XN_AUDIT_TRIAL_DET   A (nolock) join location b (nolock) on  left(a.xn_id,2)=b.dept_id 
where isnull(location_code,'')='' AND  XN_ID<>'XXXXXXXXXX'
update pci_mst SET source_location_Code=substring(memo_no,1,2) where isnull(source_location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update pci_mst SET location_Code=substring(memo_no,3,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update parcel_mst SET location_Code=left(parcel_memo_id,2) where isnull(location_Code,'')='' AND PARCEL_MEMO_ID<>'XXXXXXXXXX'
update pim01106 set challan_source_location_code=left(inv_id,2) where isnull(challan_source_location_code,'')='' and inv_mode=2 AND MRR_ID<>'XXXXXXXXXX'
update cnm01106 set challan_source_location_code=left(rm_id,2) where isnull(challan_source_location_code,'')='' and mode=2 AND CN_ID<>'XXXXXXXXXX'
update sku_xfp set challan_source_location_code=left(group_inv_no,2) where isnull(challan_source_location_code,'')='' and isnull(group_inv_no,'')<>''
update gv_gen_mst set location_Code=left(memo_id,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update XNRECON_HIST_MST set location_Code=left(RECON_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update till_shift_mst set location_Code=left(shift_id,2) where isnull(location_Code,'')='' AND TILL_ID<>'XXXXXXXXXX'
update TILL_LIFTS set location_Code=left(memo_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update TILL_EXPENSE_MST set location_Code=left(memo_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update TILL_BANK_TRANSFER set location_Code=left(memo_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update EMP_WPAYATT  set location_Code=left(row_ID,2) where isnull(location_Code,'')='' AND ROW_ID<>'XXXXXXXXXX'
update PO_ADJ_MST  set location_Code=left(memo_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update MANUAL_STOCK_COUNT_XN_mst  set location_Code=left(memo_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update wow_xpert_rep_mst set location_Code=left(rep_ID,2) where isnull(location_Code,'')='' AND REP_ID<>'XXXXXXXXXX'
update plm01106 set location_Code=left(memo_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update STOCK_COUNT_SETUP_MST  set location_Code=left(STK_COUNT_SETUP_ID,2) where isnull(location_Code,'')='' 
update PPC_FG_BARCODE_NA_MST  set location_Code=left(MEMO_ID,2) where isnull(location_Code,'')='' AND MEMO_ID<>'XXXXXXXXXX'
update cmm_hold   set hbd_location_Code=left(hold_id,2) where isnull(hbd_location_Code,'')='' AND CM_ID<>'XXXXXXXXXX'
declare @hodeptid varchar(4)
select @hodeptid=value from config where config_option='Ho_Location_id'
update dtm set location_Code=@hodeptid where isnull(location_Code,'')='' 
