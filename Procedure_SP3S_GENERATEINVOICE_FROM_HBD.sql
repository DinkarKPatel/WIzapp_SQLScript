CREATE PROCEDURE SP3S_GENERATEINVOICE_FROM_HBD--(LocId 3 digit change by Sanjay:06-11-2024)
(  
@CDEPT_ID VARCHAR(4)=''
)
AS
BEGIN
   
   
	   DECLARE @CSPID VARCHAR(50)
	   DECLARE @CERRMSG VARCHAR(1000),@CHODEPTID varchar(4),@DOCXN_TYPE VARCHAR(10),@CFIN_YEAR VARCHAR(5)

		SET @CFIN_YEAR='01'+DBO.FN_GETFINYEAR (GETDATE())


	   SET @DOCXN_TYPE='DOCWSL'
	   SET @CSPID=@@SPID

	   select @CHODEPTID=value  from config where config_option ='ho_location_id'

	   IF @CDEPT_ID<>@CHODEPTID
	   BEGIN
			SET @CERRMSG= '2.INVOICE GENERATE ONLY HO LOCATION' 
			GOTO END_PROC
	   END
 
	 IF OBJECT_ID('TEMPDB..#TMPMEMO_REPAIR','U') IS NOT NULL
		  DROP TABLE #TMPMEMO_REPAIR

		  CREATE TABLE #TMPMEMO_REPAIR
		  (
		   MEMO_ID VARCHAR(50),
		   ERRMSG VARCHAR(1000)
		  )
	



	 IF OBJECT_ID('TEMPDB..#ISSUEDFROMAPPROVED','U') IS  NULL
	 BEGIN
		SET @CERRMSG= '1.RECORD NOT FOUND FOR GROUP TRANSFER' 
		 GOTO END_PROC
	 END
    

	 DELETE FROM WSL_ITEM_DETAILS WHERE SP_ID=@CSPID

	 INSERT WSL_ITEM_DETAILS	( SP_ID,BIN_ID,PRODUCT_CODE,ROW_ID,DEPT_ID )
	 SELECT @CSPID as SP_ID,'999' BIN_ID,b.PRODUCT_CODE,b.ROW_ID,C.location_Code 
	 FROM #ISSUEDFROMAPPROVED A
	 JOIN HOLD_BACK_DELIVER_DET B ON A.ROW_ID=B.ROW_ID 
	 JOIN hold_back_deliver_mst C (NOLOCK) ON C.memo_id=B.memo_id
	 where C.location_Code<>@CDEPT_ID

	  IF NOT EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS WHERE SP_ID =@CSPID )
	   BEGIN
     
		 SET @CERRMSG= '2.RECORD NOT FOUND FOR GROUP TRANSFER' 
		 GOTO END_PROC

	   END


		UPDATE A SET QUANTITY_IN_STOCK=B.QUANTITY_IN_STOCK
		FROM WSL_ITEM_DETAILS A 
		JOIN PMT01106 B ON A.PRODUCT_CODE=B.PRODUCT_CODE
		WHERE A.SP_ID=@CSPID AND B.QUANTITY_IN_STOCK >0  AND B.DEPT_ID= @CDEPT_ID	
	   AND  A.BIN_ID=B.BIN_ID AND B.BIN_ID='999'

	   IF EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS WHERE SP_ID =@CSPID AND isnull(QUANTITY_IN_STOCK,0)<=0)
	   BEGIN
     
		 SET @CERRMSG= 'QUANTITY NOT IN STOCK' 
		 GOTO END_PROC

	   END

	 IF OBJECT_ID ('TEMPDB..#TMPLOC','U') IS NOT NULL
		DROP TABLE #TMPLOC

		SELECT DISTINCT A.DEPT_ID,DEPT_AC_CODE INTO #TMPLOC FROM  WSL_ITEM_DETAILS A (NOLOCK)
		JOIN LOCATION L (NOLOCK) ON  A.DEPT_ID =L.DEPT_ID 
		 WHERE SP_ID=@CSPID and isnull(quantity_in_stock,0)>0


		DECLARE @CPARTY_DEPT_ID VARCHAR(4),@CAC_CODE VARCHAR(10),@cpartystate_code VARCHAR(4)


	WHILE EXISTS (SELECT TOP 1 'U' FROM #TMPLOC)
	BEGIN

	   SELECT @CPARTY_DEPT_ID=DEPT_ID,@CAC_CODE=dept_ac_code  FROM  #TMPLOC

	   select @cpartystate_code=gst_state_code  from location where dept_id=@CPARTY_DEPT_ID

	   delete from WSL_INM01106_UPLOAD where sp_id=@CSPID
	   delete from WSL_IND01106_UPLOAD where sp_id=@CSPID


	   INSERT WSL_INM01106_UPLOAD	( ac_code, Approved, ApprovedLevelNo, BANDALS, Bill_LEVEL_DISC_METHOD, bill_level_tax_method, BIN_ID, BIN_TRANSFER, BROKER_AC_CODE, broker_comm_amount, broker_comm_percentage, BUYER_ORDER_NO, CANCELLED, CHECKED_BY, COMPANY_CODE, completed, copies_ptd, CREDIT_DAYS, custom_duty_mark_down_pct, dept_id, DISCOUNT_AMOUNT, DISCOUNT_PERCENT_MRP, DISCOUNT_PERCENTAGE, DISCOUNT_PERCENTAGE_1, DISCOUNT_PERCENTAGE_2, DO_NOT_CAL_EXCISE, DO_NOT_CALC_GST_OH, dt_code, EDIT_COUNT, edt_user_code, emp_code, entry_mode, ewaydistance, excise_accessible_amount, excise_accessible_percentage, excise_duty_amount, excise_duty_percentage, excise_edu_cess_amount, excise_edu_cess_percentage, excise_hedu_cess_amount, excise_hedu_cess_percentage, excise_invoice, exported, exported_time, FIN_YEAR, form_no, FREIGHT, freight_cgst_amount, freight_gst_percentage, freight_hsn_code, freight_igst_amount, freight_sgst_amount, FREIGHT_TAXABLE_VALUE, gate_pass, generated_by_chrecon, GRLR_DATE, GRLR_NO, gst_round_off, hold_party_check_bypassed_by_user_code, insurance, insurance_cgst_amount, insurance_gst_percentage, insurance_hsn_code, insurance_igst_amount, insurance_percentage, insurance_sgst_amount, INSURANCE_TAXABLE_VALUE, INV_DT, INV_ID, inv_mode, INV_NO, inv_time, inv_type, LAST_UPDATE, lotprice, LotType, manual_broker_comm, manual_discount, manual_insurance, manual_inv_no, manual_octroi, manual_roundoff, memo_prefix, memo_type, NET_AMOUNT, octroi_amount, octroi_percentage, OH_TAX_METHOD, OTHER_CHARGES, other_charges_cgst_amount, other_charges_gst_percentage, other_charges_hsn_code, other_charges_igst_amount, other_charges_sgst_amount, OTHER_CHARGES_TAXABLE_VALUE, PACKING, packing_cgst_amount, packing_gst_percentage, packing_hsn_code, packing_igst_amount, packing_sgst_amount, PACKING_TAXABLE_VALUE, party_da_no, party_dept_id, party_po_no, party_state_code, pay_mode, PENDING_GIT, PostedInAc, receiving_ac_code, Receiving_Party_Address, Receiving_Party_Name, reconciled, REF_INV_ID, REMARKS, ROUND_OFF, route_form1, route_form2, SENT_BY, sent_for_recon, sent_to_ho, SHIPPING_AC_CODE, shipping_address, shipping_address2, shipping_address3, shipping_area_code, shipping_area_name, shipping_city_name, shipping_pin, shipping_same_as_billing_Add, shipping_state_name, sms_sent, SP_ID, SUBTOTAL, SUBTOTAL_MRP, TARGET_BIN_ID, TAX_INVOICE, taxform_storage_mode, terms_code, THROUGH, TOTAL_BOX_NO, Total_Gst_Amount, TOTAL_PACKSLIP_NO, TOTAL_QUANTITY, TOTAL_QUANTITY_STR, uploaded_to_activstream, USER_CODE, Way_bill, xfer_type, XN_ITEM_TYPE ) 
	    SELECT @CAC_CODE	  ac_code,2 Approved,0 ApprovedLevelNo,0 BANDALS,0 Bill_LEVEL_DISC_METHOD,1 bill_level_tax_method,'999' BIN_ID,0 BIN_TRANSFER,'0000000000' BROKER_AC_CODE, 
		0 AS broker_comm_amount,0 broker_comm_percentage, 
		'' BUYER_ORDER_NO,0 CANCELLED,'' CHECKED_BY,'01' COMPANY_CODE,1 completed,0 copies_ptd,0 CREDIT_DAYS,0 custom_duty_mark_down_pct,@CDEPT_ID dept_id,0 DISCOUNT_AMOUNT,0 DISCOUNT_PERCENT_MRP,0 DISCOUNT_PERCENTAGE, 
		0 DISCOUNT_PERCENTAGE_1,0 DISCOUNT_PERCENTAGE_2,0 DO_NOT_CAL_EXCISE,0 DO_NOT_CALC_GST_OH,'' dt_code,0 EDIT_COUNT,'0000000' edt_user_code,'0000000' emp_code,1 entry_mode,NULL ewaydistance, 
		0 excise_accessible_amount, 0 excise_accessible_percentage,0 excise_duty_amount,0 excise_duty_percentage,0 excise_edu_cess_amount,0 excise_edu_cess_percentage,0 excise_hedu_cess_amount,
		0 excise_hedu_cess_percentage, 
		0 excise_invoice,1 exported,'' exported_time,@CFIN_YEAR as  FIN_YEAR,'' form_no,0 FREIGHT,0 freight_cgst_amount,0 freight_gst_percentage,'0000000000' freight_hsn_code,0 freight_igst_amount,0 freight_sgst_amount,
		0 FREIGHT_TAXABLE_VALUE,0 gate_pass,0 generated_by_chrecon,'' GRLR_DATE,'' GRLR_NO,0 gst_round_off,'' hold_party_check_bypassed_by_user_code,0 insurance,0 insurance_cgst_amount, 
		0 insurance_gst_percentage,'0000000000' insurance_hsn_code,0 insurance_igst_amount,0 insurance_percentage,0 insurance_sgst_amount,0 INSURANCE_TAXABLE_VALUE, convert(varchar(10),getdate(),121) as  INV_DT,'LATER' INV_ID,2 inv_mode, 
		'LATER' INV_NO,getdate() inv_time,1 inv_type,getdate() LAST_UPDATE,0 lotprice,1 LotType,0 manual_broker_comm,0 manual_discount,0 manual_insurance,'' manual_inv_no,0 manual_octroi,
		0 manual_roundoff, @CPARTY_DEPT_ID memo_prefix,1 memo_type,0 NET_AMOUNT,0 octroi_amount,0 octroi_percentage,1 OH_TAX_METHOD,0 OTHER_CHARGES,0 other_charges_cgst_amount,0 other_charges_gst_percentage, 
		'0000000000' as other_charges_hsn_code,0 other_charges_igst_amount,0 other_charges_sgst_amount,0 OTHER_CHARGES_TAXABLE_VALUE,0 PACKING,0 packing_cgst_amount,0 packing_gst_percentage, 
		'0000000000' as packing_hsn_code,0 packing_igst_amount,0 packing_sgst_amount,0 PACKING_TAXABLE_VALUE,'' party_da_no,@CPARTY_DEPT_ID party_dept_id,'' party_po_no,@cpartystate_code party_state_code,4 pay_mode,null PENDING_GIT, 
		0 PostedInAc,'0000000000' receiving_ac_code,'' Receiving_Party_Address,'' Receiving_Party_Name,0 reconciled,'' REF_INV_ID,'' REMARKS,0 ROUND_OFF,'' route_form1,'' route_form2,0 SENT_BY,0 sent_for_recon, 
		0 sent_to_ho,'0000000000' SHIPPING_AC_CODE,'' shipping_address,'' shipping_address2,'' shipping_address3,'' shipping_area_code,'' shipping_area_name,'' shipping_city_name,'' shipping_pin,'' shipping_same_as_billing_Add, 
		'' shipping_state_name,0 sms_sent,@CSPID SP_ID,0 SUBTOTAL,0 SUBTOTAL_MRP,'999' TARGET_BIN_ID,1 TAX_INVOICE,1 taxform_storage_mode,'' terms_code, ''THROUGH,0 TOTAL_BOX_NO,0 Total_Gst_Amount,0 TOTAL_PACKSLIP_NO,
		0 TOTAL_QUANTITY,'' TOTAL_QUANTITY_STR,0 uploaded_to_activstream,'0000000' USER_CODE,0 Way_bill,0 xfer_type,5 XN_ITEM_TYPE 
		 

	
     INSERT wsl_ind01106_upload	( AUTO_SRNO, BIN_ID, BO_DET_ROW_ID, box_dt, BOX_ID, box_no, CESS_AMOUNT, cgst_amount, COMPANY_CODE, custom_duty_amt, custom_duty_per, cvd_amt, cvd_per, DEPT_ID, DISCOUNT_AMOUNT, 
	 DISCOUNT_PERCENTAGE, emp_code, emp_code1, emp_code2, gross_rate, gst_percentage, hsn_code, igst_amount, INMDISCOUNTAMOUNT, INV_ID, invoice_quantity, item_excise_accessible_amount, 
	 item_excise_accessible_percentage, item_excise_duty_amount, item_excise_duty_percentage, item_excise_edu_cess_amount, item_excise_edu_cess_percentage, item_excise_hedu_cess_amount, 
	 item_excise_hedu_cess_percentage, item_excise_mrp, item_form_id, item_round_off, item_tax_amount, item_tax_percentage, LAST_UPDATE, manual_discount, manual_net_rate, manual_rate, margin_amount, 
	 margin_percentage, mrp, net_rate, ONLINE_BILL_REF_NO, ONLINE_PRODUCT_CODE, ORDER_ID, ORDER_NO, party_mrp, pick_list_id, PICK_LIST_ROW_ID, picklist_article_code, picklist_para1_code, picklist_para2_code,
	  print_label, PRODUCT_CODE, ps_id, QUANTITY, RATE, ref_wps_det_rowid, remarks, 
	  rfnet, rfnet_wotax, ROW_ID, scheme_quantity, sgst_amount, SP_ID, tax_round_off, total_custom_duty_amt, w8_challan_id, ws_price, xn_value_with_gst, xn_value_without_gst )  

	 SELECT 	  AUTO_SRNO, BIN_ID, BO_DET_ROW_ID,convert(varchar(10),getdate(),121) as box_dt, BOX_ID,1 BOX_NO,0 CESS_AMOUNT, cgst_amount,'01' COMPANY_CODE,0 custom_duty_amt,0 custom_duty_per,0 cvd_amt,0 cvd_per,@CDEPT_ID DEPT_ID, 
	 DISCOUNT_AMOUNT, DISCOUNT_PERCENTAGE,'0000000' emp_code,'0000000' emp_code1,'0000000' emp_code2, gross_rate, gst_percentage, hsn_code, igst_amount,0 INMDISCOUNTAMOUNT,'later' INV_ID,1 invoice_quantity, 
	 item_excise_accessible_amount, item_excise_accessible_percentage, item_excise_duty_amount, item_excise_duty_percentage, item_excise_edu_cess_amount, item_excise_edu_cess_percentage, item_excise_hedu_cess_amount, item_excise_hedu_cess_percentage, item_excise_mrp, 
	 '0000000' AS item_form_id, item_round_off, item_tax_amount, item_tax_percentage, 
	 getdate() LAST_UPDATE, manual_discount, manual_net_rate, manual_rate, margin_amount, margin_percentage, mrp, net_rate, ONLINE_BILL_REF_NO, 
	 '' ONLINE_PRODUCT_CODE, ORDER_ID, ORDER_NO, 0  party_mrp,'' pick_list_id,'' PICK_LIST_ROW_ID,'' picklist_article_code,'' picklist_para1_code,'' picklist_para2_code,0 print_label, PRODUCT_CODE, 
	 ps_id, 1 QUANTITY, RATE, 
	 '' ref_wps_det_rowid, remarks,0 rfnet,0 rfnet_wotax,'LATER' ROW_ID, scheme_quantity, sgst_amount, SP_ID,0 tax_round_off,0 total_custom_duty_amt,'' w8_challan_id, ws_price, xn_value_with_gst, xn_value_without_gst 
	  FROM wsl_item_details where sp_id=@CSPID AND DEPT_ID =@CPARTY_DEPT_ID 

	DECLARE @OUTPUT TABLE (errmsg VARCHAR(MAX),memo_id VARCHAR(40))

		
	  EXEC SAVETRAN_WSL 
	        @NUPDATEMODE=1,
            @NSPID=@CSPID,
            @CMEMONOPREFIX=@CDEPT_ID,
            @CFINYEAR=@CFIN_YEAR,
            @CMEMOID='',
            @NBOXNO=1,
			@CLOCID=@CDEPT_ID,
			@EDIT_CLICKED=0

	  
  DELETE FROM #TMPLOC WHERE DEPT_ID=@CPARTY_DEPT_ID

END


 --GENERATING PARCEL ENTRY FOR ALL MEMOES

 LBLPARCLE:

--INSERT INTO #TMPMEMO_REPAIR(MEMO_ID,ERRMSG)
-- SELECT INV_ID AS MEMO_ID,'' AS ERRMSG 
-- FROM INM01106 WHERE INV_ID='H101121H102/SU/20-21/ISR-000008'

 IF OBJECT_ID ('TEMPDB..#TMPMEMO_PARCEL','U') IS NOT NULL
    DROP TABLE #TMPMEMO_PARCEL

	SELECT a.* INTO #TMPMEMO_PARCEL FROM  #TMPMEMO_REPAIR a
	join inm01106 b on a.memo_id=b.inv_id   WHERE ERRMSG=''
	



	DECLARE @CANGADIA_CODE VARCHAR(10),@CERRORMSG VARCHAR(10),@NSTEP INT,
	@CTEMPMASTERTABLENAME varchar(100),@CTEMPDETAILTABLENAME1 varchar(100)
	SET @NSTEP=0
	SELECT TOP 1 @CANGADIA_CODE=ANGADIA_CODE FROM ANGM 




	 DECLARE @INV_ID VARCHAR(50),@NSAVETRANLOOP	BIT,@CMASTERTABLENAME varchar(100),
	         @CMEMONO varchar(20),@NMEMONOLEN numeric(20,0),@CMEMONOVAL	VARCHAR(50),
			 @CMEMONOPREFIX varchar(10),@CCMD nvarchar(max),@CKEYFIELDVAL1 varchar(50),@CPRCLERRMSG varchar(1000)

	
	SET @CMEMONO			= 'PARCEL_MEMO_NO'
	SET @NMEMONOLEN			= 10
	set @CMASTERTABLENAME='parcel_mst'

	 set @CMEMONOPREFIX=@CDEPT_ID
	 SET @CPRCLERRMSG=''
	
	 DECLARE @MAINTAIN_IN_OUT_SEREIES_IN_PARCEL VARCHAR(10)
	  SELECT TOP 1 @MAINTAIN_IN_OUT_SEREIES_IN_PARCEL=value FROM config WHERE config_option ='MAINTAIN_IN_OUT_SEREIES_IN_PARCEL'
		 IF ISNULL(@MAINTAIN_IN_OUT_SEREIES_IN_PARCEL,'')='1'
		   SET @CMEMONOPREFIX=@CMEMONOPREFIX+'O'


  BEGIN TRY
   BEGIN TRANSACTION

		 
     WHILE EXISTS (SELECT TOP 1 'U' FROM #TMPMEMO_PARCEL)
	 BEGIN

		 SELECT TOP 1 @INV_ID=MEMO_ID FROM #TMPMEMO_PARCEL WHERE MEMO_ID<>''


				SET @NSAVETRANLOOP=0
				WHILE @NSAVETRANLOOP=0
				BEGIN
					EXEC GETNEXTKEY @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1,
									@CFIN_YEAR,0, @CMEMONOVAL OUTPUT   


					
					SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM '+@CMASTERTABLENAME+' 
											WHERE '+@CMEMONO+'='''+@CMEMONOVAL+''' 
											AND FIN_YEAR = '''+@CFIN_YEAR+''' )
									SET @NLOOPOUTPUT=0
								ELSE
									SET @NLOOPOUTPUT=1'
					PRINT @CCMD
					EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT

				
				END

				IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO NO....'	
					  GOTO EXIT_PROC  		
				END

				SET @NSTEP = 30		-- GENERATING NEW ID

				-- GENERATING NEW PO ID
				SET @CKEYFIELDVAL1 = @CDEPT_ID  + @CFIN_YEAR+ REPLICATE('0', 15-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))
				IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'  
				BEGIN
					  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
					  GOTO EXIT_PROC
				END
				



					  INSERT parcel_mst	( ang_type, angadia_code, bilty_no, cancelled, cash_receipt_no, company_code, dept_id, dr_to_party, Driver_name, edt_user_code, fin_year, gate_entry_no, handled_by, 
					  last_update, mode, PARCEL_AMOUNT_ENTRY_MODE, parcel_memo_dt, parcel_memo_id, parcel_memo_no, parcel_type, PAY_MODE, pay_type, receipt_dt, REMARKS, SHIPPING_CODE, TAT_DAYS, TOT_BOXES, 
					  TOT_QTY, TOT_QUANTITY, total_amount, user_code, vehicle_no, xn_type ) 

					 SELECT 	 1 ANG_TYPE, @CANGADIA_CODE ANGADIA_CODE,'' BILTY_NO,0 CANCELLED,'' CASH_RECEIPT_NO,'01' COMPANY_CODE,@CDEPT_ID DEPT_ID,1 DR_TO_PARTY,'' DRIVER_NAME,'0000000' EDT_USER_CODE,@CFIN_YEAR FIN_YEAR, 
					 '' GATE_ENTRY_NO,''  HANDLED_BY, 
					 getdate() as LAST_UPDATE,1 MODE,1 PARCEL_AMOUNT_ENTRY_MODE,CONVERT(VARCHAR(10),GETDATE(),121) PARCEL_MEMO_DT, 
					 @CKEYFIELDVAL1 PARCEL_MEMO_ID,@CMEMONOVAL  PARCEL_MEMO_NO,1 PARCEL_TYPE,1 PAY_MODE,1 PAY_TYPE,CONVERT(VARCHAR(10),GETDATE(),121) RECEIPT_DT,'' REMARKS, 
					'' SHIPPING_CODE,0 TAT_DAYS,1 TOT_BOXES,0 TOT_QTY,SUM(QUANTITY) TOT_QUANTITY,0 TOTAL_AMOUNT,'0000000' USER_CODE,'' VEHICLE_NO,'WSL' XN_TYPE 
					 FROM IND01106 WHERE INV_ID=@INV_ID
	 

	               INSERT parcel_det	( AC_CODE, amount, BOX_NO, closed, company_code, fin_year, goods_desc, last_update, parcel_memo_id, PARTY_INV_AMT, PARTY_INV_DT, PARTY_INV_NO, qty, quantity, REF_GRN_MODE, 
				   REF_MEMO_ID, REF_MEMO_NO, REMARKS, row_id, uom_code )  

				     SELECT top 1	  AC_CODE, AMOUNT, BOX_NO, CLOSED, COMPANY_CODE, FIN_YEAR, GOODS_DESC, LAST_UPDATE, PARCEL_MEMO_ID, PARTY_INV_AMT, PARTY_INV_DT, PARTY_INV_NO, QTY, QUANTITY, 
				              REF_GRN_MODE, REF_MEMO_ID, REF_MEMO_NO, REMARKS, ROW_ID, UOM_CODE 
				         FROM 
				         (
							SELECT AC_NAME,newid() AS  ROW_ID,'01' AS COMPANY_CODE,GETDATE() AS LAST_UPDATE,@CKEYFIELDVAL1 AS PARCEL_MEMO_ID,
							  B.FIN_YEAR,0 AS QTY,'0000001' AS UOM_CODE,'' AS GOODS_DESC,'' AS REMARKS,
							  SUM(A.QUANTITY) AS QUANTITY,NET_AMOUNT AS AMOUNT,1 AS BOX_NO,@INV_ID AS REF_MEMO_ID,B.AC_CODE,INV_NO AS REF_MEMO_NO,
							  INV_NO AS PARTY_INV_NO,NET_AMOUNT AS PARTY_INV_AMT,INV_DT AS PARTY_INV_DT,0 AS REF_GRN_MODE,1 AS CLOSED,
							  '' AS UOM_NAME,'WSL' AS REF_TYPE
   							  FROM IND01106 A (NOLOCK) JOIN INM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID
   							  JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=B.AC_CODE
   							  WHERE B.INV_ID=@INV_ID
   							  GROUP BY INV_NO,A.INV_ID,FIN_YEAR,NET_AMOUNT,B.AC_CODE,INV_DT,AC_NAME

					     ) A


	 DELETE FROM #TMPMEMO_PARCEL WHERE MEMO_ID= @INV_ID




END


	END TRY
	BEGIN CATCH
		SET @CPRCLERRMSG='P:GENERATE PARCEL MEMO, MEMO ID , MESSAGE:'+ERROR_MESSAGE()
		GOTO EXIT_PROC
	END CATCH

	EXIT_PROC:

		IF @@TRANCOUNT>0
		BEGIN
			IF ISNULL(@CPRCLERRMSG,'')='' 
				commit
			ELSE
				ROLLBACK
		END


		IF ISNULL(@CPRCLERRMSG,'')='' 
		begin

			 IF EXISTS(SELECT TOP 1 'U' FROM LOCATION(NOLOCK) WHERE DEPT_ID=@CDEPT_ID AND SERVER_LOC=1)
				 AND EXISTS(SELECT TOP 1 'U' FROM LOCATION A(NOLOCK) JOIN INM01106 B(NOLOCK) ON A.DEPT_ID=B.PARTY_DEPT_ID
							WHERE SERVER_LOC=1 AND INV_ID=@INV_ID)
					 EXEC SP3S_INS_DOC_MIRROR_TABLES  1, @INV_ID         
		
		END 


					
	
 END_PROC:
 
   IF @CERRMSG<>''
       SELECT @CERRMSG AS ERRMSG, '' AS MEMO_ID
   ELSE 
	   SELECT A.*,B.INV_NO  FROM #TMPMEMO_REPAIR A
	   LEFT JOIN INM01106 B ON A.MEMO_ID =B.INV_ID 


END 


