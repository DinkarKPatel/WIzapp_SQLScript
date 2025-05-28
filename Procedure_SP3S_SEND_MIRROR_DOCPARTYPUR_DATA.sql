create  PROCEDURE SP3S_SEND_MIRROR_DOCPARTYPUR_DATA
(
 @CInvId varchar(50)='',
 @CERRMSG VARCHAR(1000) OUTPUT  
)
as
begin
			Declare @cspid varchar(50)
			set @CERRMSG=''

BEGIN TRY
			SELECT 	''  AC_CODE,'' ACCOUNTS_DEPT_ID,0 ALLOW_EDIT_AT, APPROVEDLEVELNO, AUTO_POSRECO_LAST_UPDATE, AUTO_PREFIX,'' BARCODE_PREFIX,0 BILL_CHALLAN_MODE,INV_DT BILL_DT, BILL_LEVEL_TAX_METHOD,INV_NO BILL_NO, BIN_ID, 
				              BROKER_AC_CODE, BROKER_COMM_AMOUNT, BROKER_COMM_PERCENTAGE, BROKER_TDS_AMOUNT, BROKER_TDS_CODE, BROKER_TDS_PERCENTAGE, CANCELLED, CHECKED_BY,'' CHI_ENTRY_REF_NO,0 CR_DISCOUNT_PERCENTAGE, CREDIT_DAYS, DEPT_ID, DISCOUNT_AMOUNT, 
							  DISCOUNT_PERCENTAGE, DO_NOT_CALC_GST_OH,0 DO_NOT_CREATE_FDN, DOC_SYNCH_LAST_UPDATE,0 DOCATTACH, EDIT_COUNT, EDIT_INFO, EDT_USER_CODE, EMP_CODE, EWAYDISTANCE,'' EXCEL_FILE_PATH, EXCISE_DUTY_AMOUNT, FC_RATE, FIN_YEAR, 
							  0 FOREX_DISCOUNT_AMOUNT,0 FOREX_FREIGHT,0 FOREX_FREIGHT_IGST_AMOUNT,0 FOREX_FREIGHT_TAXABLE_VALUE,0 FOREX_OTHER_CHARGES,0 FOREX_OTHER_CHARGES_IGST_AMOUNT,0 FOREX_OTHER_CHARGES_TAXABLE_VALUE,0 FOREX_SUBTOTAL,0 FOREX_TOTAL_AMOUNT, 
							  0 FREIGHT, FREIGHT_CGST_AMOUNT, FREIGHT_GST_PERCENTAGE, FREIGHT_HSN_CODE, FREIGHT_IGST_AMOUNT, FREIGHT_SGST_AMOUNT, FREIGHT_TAXABLE_VALUE,0 FRIGHT_PAY_MODE,0 FROM_EXCEL, GENERATED_BY_CHRECON,0 GOODS_TDS_AMOUNT,0 GOODS_TDS_BASEAMOUNT,
							  0 GOODS_TDS_PERCENTAGE, GST_ROUND_OFF, HO_SYNCH_LAST_UPDATE,0 INPUT_GST_ROUND_OFF, INV_DT, INV_ID, INV_MODE, INV_NO, LAST_UPDATE,0 LEDGER_NET_AMOUNT, MANUAL_BROKER_COMM, MANUAL_DISCOUNT, MANUAL_ROUNDOFF, MEMO_PREFIX,INV_TIME MEMO_TIME, MEMO_TYPE, 
							  '' MRR_CREATION_DEPT_ID,inv_dt MRR_DT,'LATER' MRR_ID,'' MRR_NO,'' OEM_AC_CODE, OH_TAX_METHOD, OLAP_SYNCH_LAST_UPDATE, OTHER_CHARGES, OTHER_CHARGES_CGST_AMOUNT, OTHER_CHARGES_GST_PERCENTAGE, OTHER_CHARGES_HSN_CODE, OTHER_CHARGES_IGST_AMOUNT, OTHER_CHARGES_SGST_AMOUNT,
							  OTHER_CHARGES_TAXABLE_VALUE,1 PARCEL_LINKED,0 PARTY_INV_AMOUNT, PARTY_STATE_CODE,0 PIM_MODE, POSTEDINAC,0 POSTTAXDISCOUNTAMOUNT, PUMA_HO_SYNCH_LAST_UPDATE,0 PUR_CAL_METHOD,'' PUR_FOR_DEPT_ID,'' PUR_TERMS_NAME,'' PUR_TERMS_REMARKS, QUANTITY_LAST_UPDATE,0 RCM_APPLICABLE,'' RCM_MEMO_NO, 
							 inv_dt  RECEIPT_DT,'' RECEIVED_BY, RECONCILED,'' REF_CONVERTED_MRNTOBILL_MRRID, REMARKS, ROUND_OFF, ROUTE_FORM1, ROUTE_FORM2,0 SEND_TO_LOC, SENT_FOR_RECON, SENT_TO_HO,'0000000000' SHIPPING_FROM_AC_CODE, SUBTOTAL,0 TAT_DAYS,0 TAX_AMOUNT,0 TAX_PERCENTAGE, TAXFORM_STORAGE_MODE, TCS_AMOUNT,0 TDS_AMOUNT, 
							 '' TDS_CODE,0 TDS_PERCENTAGE,'' TERMS, THROUGH,NET_AMOUNT  TOTAL_AMOUNT, TOTAL_BOX_NO,0 TOTAL_CASHDISCOUNTAMOUNT, TOTAL_GST_AMOUNT, TOTAL_GST_CESS_AMOUNT, TOTAL_QUANTITY, 
							  TOTAL_QUANTITY_STR, USER_CODE, XN_FC_CODE, XN_ITEM_TYPE ,'PUR_pim01106_UPLOAD' AS TARGET_TABLE_NAME,@cspid as sp_id,
							  cast( null as timestamp) as ts
				 FROM INM01106 A(NOLOCK) 
				 WHERE A.inv_id=@CInvId

			
				SELECT 	NULL alt_uom_conversion_factor,NULL alternate_uom_code,NULL alternate_uom_quantity,0 area_length,0 area_rate_pp,0 area_sqare,NULL area_uom_code,0 area_width,'' article_code, AUTO_SRNO,'' BATCH_NO, BIN_ID, BOX_ID, box_no, 
				            0 CashDiscountAmount, CESS_AMOUNT, cgst_amount, discount_amount, discount_percentage,cast('' as dateTime) expiry_dt,0 Fc_NET,0 Fix_mrp,0 Forex_Accessiblevalue,0 Forex_CustomdutyAmt, 
							0 Forex_discount_amount,0 Forex_gross_purchase_price,0 Forex_igst_amount,0 Forex_PIMDiscountAmount,0 Forex_purchase_price,0 Forex_rfnet,0 Forex_xn_value_without_gst, 
							'' FORM_ID,0 GRN_QTY,Rate gross_purchase_price, Gst_Cess_Amount, Gst_Cess_Percentage, gst_percentage, hsn_code, igst_amount, invoice_quantity, item_excise_duty_amount, 
							item_excise_duty_percentage,0 LABEL_COPIES, last_update, manual_discount,0 manual_dpp,0 manual_fix_mrp,0 manual_gpp,0 manual_mdp,0 MANUAL_MP_PER_FIX_MRP,0 manual_mpp,
							0 manual_mpp_wsp,0 manual_mrp,0 manual_wsp,0 manual_wspp,0 material_cost,0 MD_PERCENTAGE,0 MP_PER_FIX_MRP,0 MP_PER_WSP,0 mp_percentage, mrp,'LATER' mrr_id, 
							online_product_code, Order_id,'0000000' para1_code,'0000000' para2_code,'0000000' para3_code,'0000000' para4_code,'0000000' para5_code,'0000000' para6_code,0 PIMDiscountAmount,0 PIMExciseDutyAmount, 
							0 PIMPostTaxDiscountAmount,'' po_id, ''po_row_id, print_label, product_code,0 PRTAmount,0 prtamount_credited,net_rate  purchase_price, quantity,0 RATE_AREA_SQUARE, 
							0 rcm_cgst_amount,0 rcm_gst_percentage,0 rcm_igst_amount,0 rcm_sgst_amount,0 rcm_taxable_value,'' ref_mrr_id, rfnet, rfnet_wotax, row_id, scheme_quantity, 
							sgst_amount,'' SIZE_SET_NAME,AUTO_SRNO SRNO,'' srv_narration,0 TAX_AMOUNT,0 TAX_PERCENTAGE,0 tax_round_off,0 USER_SRNO,0 VENDOR_EAN_NO, w8_challan_id,0 WD_PERCENTAGE, 
						    ws_price wholesale_price,0 wsp_percentage, xn_value_with_gst, xn_value_without_gst ,'PUR_pid01106_UPLOAD' AS TARGET_TABLE_NAME,@cspid as sp_id,
							  cast( null as timestamp) as ts
				 FROM IND01106 
				 WHERE INV_ID =@CInvId


			select 	 section_name,sub_section_name,article_no,sn.sn_article_desc ARTICLE_DESC,para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,a.net_rate  purchase_price,
					 a.mrp 	mrp,a.ws_price ws_price,'' form_name,0 PERISHABLE,sn.sn_barcode_coding_scheme  coding_scheme,a. product_code,sn.uom  uom_name,ac_name,row_id,stock_na,fix_mrp,'' product_name,0 gen_ean_codes,
						BIN_ID,article_name,ARTICLE_ALIAS,hsn_code,section_alias,sub_section_alias,BATCH_NO,EXPIRY_DT,cast(0 as bit) Para1_set,cast(0 as bit)  para2_set,cast(0 as bit) P1_SET,cast(0 as bit) P2_SET,
						VENDOR_EAN_NO,ATTR1_KEY_NAME,ATTR2_KEY_NAME,ATTR3_KEY_NAME,ATTR4_KEY_NAME,ATTR5_KEY_NAME,ATTR6_KEY_NAME,ATTR7_KEY_NAME,ATTR8_KEY_NAME,
						ATTR9_KEY_NAME,ATTR10_KEY_NAME,ATTR11_KEY_NAME,ATTR12_KEY_NAME,ATTR13_KEY_NAME,ATTR14_KEY_NAME,ATTR15_KEY_NAME,ATTR16_KEY_NAME,ATTR17_KEY_NAME,
						ATTR18_KEY_NAME,ATTR19_KEY_NAME,ATTR20_KEY_NAME,ATTR21_KEY_NAME,ATTR22_KEY_NAME,ATTR23_KEY_NAME,ATTR24_KEY_NAME,ATTR25_KEY_NAME,
						PARA1_ALIAS,PARA2_ALIAS,PARA3_ALIAS,PARA4_ALIAS,PARA5_ALIAS,PARA6_ALIAS,'#TMPMASTERSENC' AS TARGET_TABLE_NAME,@cspid as sp_id
		      from IND01106 a (nolock)
			  join sku_names sn (nolock) on a.PRODUCT_CODE =sn.product_Code 
			  where a.inv_id=@CInvId
			
   END TRY  
	BEGIN CATCH  
	 SET @CERRMSG='P: SP3S_SEND_MIRROR_DOCPARTYPUR_DATA, STEP MESSAGE:'+ERROR_MESSAGE()  
	 GOTO END_PROC  
	END CATCH  
	

	end_proc:

END