
create  PROCEDURE SP3S_Import_customeBalance         
(          
 @NMODE INT =1,--1 FOR CREDIT ISSUE 2 FOR CREDIT NOT 3 FOR ADVANCES
 @CSP_ID VARCHAR(50)='100',
 @CFINYEAR VARCHAR(5)='01122',
 @CDEPT_ID varchar(5)='jm'

)          
AS          
BEGIN     
      
	  DECLARE @CCMD NVARCHAR (MAX),@NSTEP INT,@CTARGETDB VARCHAR(100),@CTABLENAME VARCHAR(100),
	          @CERRORMSG varchar(1000),@CMEMOPREFIX varchar(10),@NMEMONOLEN numeric(2,0),@CMEMONOVAL varchar(15),
			  @CKEYSTABLE varchar(10),@crowid varchar(50)
	 


BEGIN TRY
BEGIN TRAN
          set @CERRORMSG=''
		  SET @NMEMONOLEN=12
		  SET @CKEYSTABLE='KEYS_CMM'  
		  
		  if not exists (select top 1'u' from location where dept_id=@CDEPT_ID )
		  begin
		      
			  set @CERRORMSG=' Invalid Location Id'
			  goto End_proc
		  end

		  update a set customer_code=b.customer_code from   SLS_CUSTBAL_IMPORT a with (nolock)
		  join custdym b on a.mobile=b.mobile
		  where isnull(a.customer_code,'')='' and sp_id=@CSP_ID

		  update a set customer_code=b.mobile from   SLS_CUSTBAL_IMPORT a with (nolock)
		  join custdym b on a.mobile=b.User_customer_code 
		  where isnull(a.customer_code,'')='' and  sp_id=@CSP_ID

		   if  exists (select top 1'u' from SLS_CUSTBAL_IMPORT where  sp_id=@CSP_ID and isnull(customer_code,'')='')
		  begin
		      
			  set @CERRORMSG='New Customer found'
			  goto End_proc
		  end

		  WHILE EXISTS(SELECT TOP 1 'U' FROM SLS_CUSTBAL_IMPORT WHERE ISNULL(CM_NO,'')='' and sp_id=@CSP_ID)            
		  BEGIN          
		  
		     select top 1 @crowid=row_id from    SLS_CUSTBAL_IMPORT       WHERE ISNULL(CM_NO,'')='' and sp_id=@CSP_ID  
		             
		   SET @CMEMOPREFIX=LTRIM(RTRIM(@CDEPT_ID))+LTRIM(RTRIM(@CDEPT_ID))+'-'            
              
		  LBLGENKEY:             
               
		   SET @NSTEP=10            
		   EXEC GETNEXTKEY_OPT 'CMM01106', 'CM_NO', @NMEMONOLEN, @CMEMOPREFIX, 1,@CFINYEAR,0, @CKEYSTABLE,@CMEMONOVAL OUTPUT           
  
		   SET @NSTEP=20            
		   IF EXISTS(SELECT TOP 1 'U' FROM CMM01106 WHERE CM_NO=@CMEMONOVAL AND FIN_YEAR=@CFINYEAR)            
			GOTO LBLGENKEY            
               
		   SET @NSTEP=30            
		   IF ISNULL(@CMEMONOVAL,'')=''            
		   BEGIN            
			SET @CERRORMSG='ERROR GENERATING CM NO.'            
			GOTO END_PROC            
		   END            
               
		   SET @NSTEP=40 
		   
		   UPDATE  SLS_CUSTBAL_IMPORT SET CM_NO=@CMEMONOVAL WHERE ROW_ID=@CROWID

		  END            
		   UPDATE SLS_CUSTBAL_IMPORT SET CM_ID=LTRIM(RTRIM(@CDEPT_ID))+@CFINYEAR+REPLICATE('0',15-LEN(LTRIM(RTRIM(CM_NO))))+LTRIM(RTRIM(CM_NO))            

	
	

  

      SET @CERRORMSG=''
      SET @cTargetDb=db_name ()+'.DBO.' 

	  if @NMODE=1
     GOTO LBLCREDITISSUE

	  lblcreditissue:
	
		SET @NSTEP=150
		set @CTABLENAME='cmm01106'
		 SET @CCMD=N' INSERT '+@cTargetDb+@CTABLENAME+'	( manual_discount, MANUAL_ROUNDOFF, BIN_ID, patchup_run, subtotal_r, passport_no, ticket_no, flight_no, mrp_wsp, MANUAL_BILL, shift_id, fc_rate, PostedInAc, CM_NO, CM_DT, CM_MODE, SUBTOTAL, DT_CODE, DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, NET_AMOUNT, 
					  CUSTOMER_CODE, CANCELLED, USER_CODE, LAST_UPDATE, exempted, sent_to_ho, cm_time, cm_id, ref_cm_id, fin_year, atd_charges, copies_ptd, round_off, memo_type, pay_mode, SMS_SENT, autoentry, cash_tendered, payback, ecoupon_id, campaign_gc_otp, SalesSetupinEffect, edt_user_code, 
					  gv_amount, ref_no, sent_for_gr, discount_remarks, ctrls_used, INV_MODE, INV_TYPE, discount_changed, MANUAL_BILL_FLAG, calc_da1, calc_da2, dp_changed, TOTAL_QUANTITY, party_state_code, REMARKS, sent_for_recon, party_type, AC_CODE, other_charges_gst_percentage, other_charges_hsn_code, 
					  other_charges_igst_amount, other_charges_cgst_amount, other_charges_sgst_amount, LOYALTY_OTP_CODE, OH_TAX_METHOD ) 
	                  
		 SELECT manual_discount=0, MANUAL_ROUNDOFF=0,''000'' BIN_ID, 0patchup_run,0 subtotal_r,0 passport_no,'''' ticket_no,'''' flight_no, 
		 0 mrp_wsp,0  MANUAL_BILL,null shift_id,0 fc_rate,0 PostedInAc, CM_NO,ref_dt CM_DT,1 CM_MODE, SUBTOTAL=(a.pending_amount),''0000000'' DT_CODE,0 DISCOUNT_PERCENTAGE, 
		 0 DISCOUNT_AMOUNT, NET_AMOUNT=(a.pending_amount), CUSTOMER_CODE,0 CANCELLED,''0000000'' USER_CODE,getdate() LAST_UPDATE,0 exempted,0 sent_to_ho, 
		 ref_dt cm_time, a.cm_id,'''' ref_cm_id,'''+@CFINYEAR+''' fin_year,0 atd_charges,0 copies_ptd,0 round_off,0 memo_type,0 pay_mode,0 SMS_SENT,0 autoentry, 
		 0 cash_tendered,0 payback,'''' ecoupon_id,0 campaign_gc_otp,'''' SalesSetupinEffect,''0000000'' edt_user_code,0 gv_amount, ref_no, 
		 0 sent_for_gr,'''' discount_remarks,0 ctrls_used,1 INV_MODE,1 INV_TYPE,0 discount_changed,0 MANUAL_BILL_FLAG,0 calc_da1, 
		 0 calc_da2,0 dp_changed,0 TOTAL_QUANTITY,''00'' party_state_code,''Customer_balance'' REMARKS,0 sent_for_recon,1 party_type,''0000000000'' AC_CODE, 
		 other_charges_gst_percentage=0, other_charges_hsn_code=''0000000000'', other_charges_igst_amount=0, 
		 other_charges_cgst_amount=0, 
		 other_charges_sgst_amount=0,'''' LOYALTY_OTP_CODE, OH_TAX_METHOD=0
		 FROM SLS_CUSTBAL_IMPORT a
		 WHERE a.sp_id='''+@CSP_ID+''' '
		 PRINT @CCMD          
		 EXEC SP_EXECUTESQL @CCMD  
	    
	
		 SET @NSTEP=160
		 SET @CTABLENAME='PAYMODE_XN_DET'
	     
		 SET @CCMD=N' INSERT '+@cTargetDb+@CTABLENAME+'	( memo_id, xn_type, paymode_code, row_id, amount, last_update, ref_no, adj_memo_id, currency_conversion_rate, REMARKS, gv_srno, gv_scratch_no, Wallet_MOBILE, cc_name )  
		 SELECT 	  memo_id=cm_id, xn_type=''sls'', paymode_code=''0000004'', row_id=NEWID(), 
		 amount=(a.pending_amount), last_update=getdate(), ref_no='''', adj_memo_id='''', currency_conversion_rate=0, REMARKS='''', gv_srno='''', gv_scratch_no='''', Wallet_MOBILE='''', cc_name='''' 
		 from SLS_CUSTBAL_IMPORT a
		 WHERE pending_amount<>0  
		 and a.sp_id='''+@CSP_ID+''''
		 PRINT @CCMD          
		 EXEC SP_EXECUTESQL @CCMD  
	  
	
	  
	  goto END_PROC
	    
		SET @NSTEP=170
		 --2 PENDING CREDIT NOTE
		set @CTABLENAME='cmm01106'
		 SET @CCMD=N' INSERT '+@cTargetDb+@CTABLENAME+'	( manual_discount, MANUAL_ROUNDOFF, BIN_ID, patchup_run, subtotal_r, passport_no, ticket_no, flight_no, mrp_wsp, MANUAL_BILL, shift_id, fc_rate, PostedInAc, CM_NO, CM_DT, CM_MODE, SUBTOTAL, DT_CODE, DISCOUNT_PERCENTAGE, DISCOUNT_AMOUNT, NET_AMOUNT, 
					  CUSTOMER_CODE, CANCELLED, USER_CODE, LAST_UPDATE, exempted,  sent_to_ho, cm_time, cm_id, ref_cm_id, fin_year, atd_charges, copies_ptd, round_off, memo_type, pay_mode, SMS_SENT, autoentry, cash_tendered, payback, ecoupon_id, campaign_gc_otp, SalesSetupinEffect, edt_user_code, 
					  gv_amount, ref_no, sent_for_gr, discount_remarks, ctrls_used, INV_MODE, INV_TYPE, discount_changed, MANUAL_BILL_FLAG, calc_da1, calc_da2, dp_changed, TOTAL_QUANTITY, party_state_code, REMARKS, sent_for_recon, party_type, AC_CODE, other_charges_gst_percentage, other_charges_hsn_code, 
					  other_charges_igst_amount, other_charges_cgst_amount, other_charges_sgst_amount, LOYALTY_OTP_CODE, OH_TAX_METHOD ) 
	                  
		  SELECT manual_discount=0, MANUAL_ROUNDOFF=0, BIN_ID, patchup_run, subtotal_r=0, passport_no, ticket_no, flight_no, 
		 mrp_wsp, MANUAL_BILL, shift_id, fc_rate, PostedInAc, CM_NO, CM_DT, CM_MODE, SUBTOTAL=(a.pending_amount), DT_CODE, DISCOUNT_PERCENTAGE, 
		 DISCOUNT_AMOUNT, NET_AMOUNT=(a.pending_amount), CUSTOMER_CODE, CANCELLED, USER_CODE, LAST_UPDATE, exempted,  sent_to_ho, 
		 cm_time, b.cm_id, ref_cm_id, fin_year, atd_charges, copies_ptd, round_off, memo_type, pay_mode, SMS_SENT, autoentry, 
		 cash_tendered, payback, ecoupon_id, campaign_gc_otp, SalesSetupinEffect, edt_user_code, gv_amount, ref_no, 
		 sent_for_gr, discount_remarks, ctrls_used, INV_MODE, INV_TYPE, discount_changed, MANUAL_BILL_FLAG, calc_da1, 
		 calc_da2, dp_changed, TOTAL_QUANTITY, party_state_code, REMARKS, sent_for_recon, party_type, AC_CODE, 
		 other_charges_gst_percentage=0, other_charges_hsn_code=''0000000000'', other_charges_igst_amount=0, 
		 other_charges_cgst_amount=0, 
		 other_charges_sgst_amount=0, LOYALTY_OTP_CODE, OH_TAX_METHOD=0
	
		 FROM #tmpPendingCreditNotes a
		 join cmm01106 b on a.cm_id=b.cm_id
		 WHERE pending_amount<>0 '
		 PRINT @CCMD          
		 EXEC SP_EXECUTESQL @CCMD  
	     
		 SET @NSTEP=180
		 SET @CTABLENAME='PAYMODE_XN_DET'
	     
		 SET @CCMD=N' INSERT '+@cTargetDb+@CTABLENAME+'	( memo_id, xn_type, paymode_code, row_id, amount, last_update, ref_no, adj_memo_id, currency_conversion_rate, REMARKS, gv_srno, gv_scratch_no, Wallet_MOBILE, cc_name )  
		 SELECT 	  memo_id=cm_id, xn_type=''sls'', paymode_code=''0000004'', row_id=NEWID(), 
		 amount=(a.pending_amount), last_update=getdate(), ref_no='''', adj_memo_id='''', currency_conversion_rate=0, REMARKS='''', gv_srno='''', gv_scratch_no='''', Wallet_MOBILE='''', cc_name='''' 
		 from #tmpPendingCreditNotes a
		 WHERE pending_amount<>0  '
		 PRINT @CCMD          
		 EXEC SP_EXECUTESQL @CCMD  
	     

		  SET @NSTEP=210
		 SET @CTABLENAME='arc01106'
		--3 pending advances
		SET @CCMD=N'  INSERT '+@cTargetDb+@CTABLENAME+'	( ref_xn_type, PostedInAc, arc_type, adv_rec_no, adv_rec_dt, customer_code, cancelled, amount, discount_amount, net_amount, last_update, user_code, sent_to_ho, adv_rec_id, adj_bill_id, cm_id, fin_year, arct, emp_code, EDT_USER_CODE, against_bill, pay_mode, gift_card_no, REMARKS, party_type, ac_code, 
					  sent_for_recon, ref_no, SMS_SENT, BIN_ID, DISCOUNT_PERCENTAGE, MANUAL_DISCOUNT, shift_id, card_issue_type, card_issue_dt, card_no, party_state_code, gst_percentage, igst_amount, cgst_amount, sgst_amount, hsn_code, GOODS_DESCRIPTION, OH_TAX_METHOD )
 
	                  
		  SELECT 	  ref_xn_type, PostedInAc, arc_type, adv_rec_no, adv_rec_dt, customer_code, cancelled, 
		  a.PENDING_AMOUNT as amount, 0 as discount_amount,a.PENDING_AMOUNT as  net_amount, last_update, user_code, 
		  sent_to_ho, b.adv_rec_id, adj_bill_id, 
		  cm_id, fin_year, arct, emp_code, EDT_USER_CODE, against_bill, pay_mode, gift_card_no, REMARKS, party_type, 
		  ac_code, sent_for_recon, ref_no, SMS_SENT, BIN_ID, DISCOUNT_PERCENTAGE, MANUAL_DISCOUNT, 
		  shift_id, card_issue_type, card_issue_dt, card_no, party_state_code, gst_percentage, 
		  0 as igst_amount,0 as  cgst_amount, 
		  0 as sgst_amount,''0000000000'' hsn_code, GOODS_DESCRIPTION,0 as  OH_TAX_METHOD
		  from #tmpPendingAdvances a
		  join arc01106 b on a.adv_rec_id =b.adv_rec_id '
		  PRINT @CCMD          
		  EXEC SP_EXECUTESQL @CCMD  
	      
		 SET @NSTEP=220
		 SET @CTABLENAME='PAYMODE_XN_DET'
	     
	     
	    
		 SET @CCMD=N' INSERT '+@cTargetDb+@CTABLENAME+'(  memo_id, xn_type, paymode_code, row_id, amount, last_update, ref_no, adj_memo_id, currency_conversion_rate, REMARKS, gv_srno, gv_scratch_no, Wallet_MOBILE, cc_name )
		 SELECT 	  memo_id=adv_rec_id, xn_type=''arc'', paymode_code=''0000000'', row_id=NEWID(), 
		 amount=(a.pending_amount), last_update=getdate(), ref_no='''', adj_memo_id='''', currency_conversion_rate=0, REMARKS='''', gv_srno='''', gv_scratch_no='''', Wallet_MOBILE='''', cc_name='''' 
		 from #tmpPendingAdvances a
		 WHERE pending_amount>0  '
		 PRINT @CCMD          
		 EXEC SP_EXECUTESQL @CCMD 


		 select * from cmm01106 where cm_no in(select cm_no from SLS_CUSTBAL_IMPORT)
	    
	
	  END TRY          
	BEGIN CATCH          

		SET @CERRORMSG = 'Error in Procedure SP3S_ARCHIVEDATA at STEP#' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()            
		GOTO END_PROC          
	    
	END CATCH          
	              
	END_PROC:          

		 IF @@TRANCOUNT>0            
		 BEGIN            
      		 IF ISNULL(@CERRORMSG,'')=''          
				ROLLBACK TRANSACTION            
			 ELSE            
				ROLLBACK            
		 END 
		  select @CERRORMSG

END