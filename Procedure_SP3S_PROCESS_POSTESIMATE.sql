create PROCEDURE SP3S_PROCESS_POSTESIMATE
(
  @DFMDT DATETIME='',
  @DTODATE DATETIME='',
  @CUSER_CODE VARCHAR(7)='',
  @CFINYEAR VARCHAR(5)='',
  @CLOCATIONID VARCHAR(5)=''
)
AS
BEGIN
     

 DECLARE @CERRORMSG VARCHAR(MAX),@NSTEP NUMERIC(5,0) ,@CCMD NVARCHAR(MAX),@CMEMONO VARCHAR(20),@CMEMONOVAL VARCHAR(50),
         @CKEYSTABLE VARCHAR(100),@CUSERALIAS VARCHAR(10),@CMEMONOPREFIX VARCHAR(25),@CMASTERTABLENAME VARCHAR(100),@NMEMONOLEN	NUMERIC(20,0),
		 @NSAVETRANLOOP	BIT,@CKEYFIELDVAL1	VARCHAR(50),@DCMDT DATETIME,@dlastdtmonth datetime

		 SELECT @dlastdtmonth=DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@DFMDT)+1,0))

		 if @DTODATE>@dlastdtmonth
		 set @dlastdtmonth=@DTODATE

		-- select @dlastdtmonth

 BEGIN TRY   
 BEGIN TRAN      


  IF ISNULL(@CLOCATIONID,'')=''  
		SELECT @CLOCATIONID =DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
  ELSE  
		SELECT @CLOCATIONID = @CLOCATIONID  

  IF ISNULL(@CLOCATIONID,'')=''
	 BEGIN
		SET @CERRORMSG ='1. LOCATION ID CAN NOT BE BLANK  '  
		GOTO END_PROC    
	 END
	   
	   	SET @CMASTERTABLENAME	= 'CMM01106'
		SET @CMEMONO			= 'CM_NO'
	    SET @NMEMONOLEN			= 12

	   SET @NSTEP=00

	   	IF @CUSER_CODE=''
		BEGIN
			 SET @CERRORMSG='USER CAN NOT BE BLANK '
			 GOTO END_PROC
		END
	   SET @NSTEP=10

		IF @CLOCATIONID=''
		BEGIN
			 SET @CERRORMSG='LOCATION CAN NOT BE BLANK '
			 GOTO END_PROC
		END

		SET @NSTEP=20

		--**1LIST OF CASH MEMO ERFLAG 2 ARCHIVE INTO NEW NEW MEMO ID

	  
		   
		 SELECT distinct  A.CM_ID AS OLD_CM_ID, b.CM_DT,CAST('' AS VARCHAR(50)) AS NEW_CM_ID,
		 CAST('' AS VARCHAR(50)) AS NEW_CM_NO,a.ROW_ID ,CAST('' AS VARCHAR(50)) AS NEW_Product_code,
		 a.mrp ,b.Party_Gst_No 
		 into #TMPCMM
		 FROM CMD01106 A JOIN CMM01106 B ON A.CM_ID=B.CM_ID
		 JOIN PID01106 C ON C.PRODUCT_CODE=A.PRODUCT_CODE
		 JOIN PIM01106 D ON D.MRR_ID=C.MRR_ID
		 WHERE B.CM_DT BETWEEN @DFMDT AND @DTODATE AND B.CANCELLED=0 AND B.MEMO_TYPE=1
		 AND D.MEMO_TYPE=2 and b.CANCELLED=0
		 and B.location_Code =@CLOCATIONID

         insert into #TMPCMM(OLD_CM_ID,cm_dt,NEW_CM_ID,NEW_CM_NO,ROW_ID,NEW_Product_code,mrp)
		  SELECT distinct  A.CM_ID AS OLD_CM_ID, b.CM_DT,CAST('' AS VARCHAR(50)) AS NEW_CM_ID,
		 CAST('' AS VARCHAR(50)) AS NEW_CM_NO,a.ROW_ID ,CAST('' AS VARCHAR(50)) AS NEW_Product_code,
		 a.MRP
		 FROM CMD01106 A JOIN CMM01106 B ON A.CM_ID=B.CM_ID
		 join sku (nolock) on a.PRODUCT_CODE =sku.product_code 
		 left join #TMPCMM tmp on tmp.ROW_ID =a.ROW_ID 
		 WHERE B.CM_DT BETWEEN @DFMDT AND @DTODATE AND B.CANCELLED=0 AND B.MEMO_TYPE=1
		 AND sku.er_flag =2 and tmp.ROW_ID is null
		 and B.location_Code =@CLOCATIONID

		

		 
		 --union all (pick sku)

	    
		IF NOT EXISTS(SELECT TOP 1 'U' FROM #TMPCMM)
		   GOTO END_PROC

         
		 -- credit bills mrp Range does not in article Matser which is not Processes

		 IF OBJECT_ID ('TEMPDB..#TMPCREDITBILLS','U') IS NOT NULL
		    DROP TABLE #TMPCREDITBILLS
         
		 SELECT A.MEMO_ID  
		 into #TMPCREDITBILLS
		 FROM PAYMODE_XN_DET A (NOLOCK)
		 JOIN 
		(
		 SELECT  OLD_CM_ID FROM  #TMPCMM 
		 GROUP BY OLD_CM_ID
		)B ON A.MEMO_ID =B.OLD_CM_ID	AND A.XN_TYPE='SLS' 
		AND PAYMODE_CODE <>'0000000'
		GROUP BY A.MEMO_ID 

		insert into #TMPCREDITBILLS(memo_id)
		SELECT OLD_CM_ID 
		FROM #TMPCMM A 
		left join #TMPCREDITBILLS b on a.OLD_CM_ID=b.memo_id 
		WHERE ISNULL(A.PARTY_GST_NO ,'')<>'' and b.memo_id is null



		IF OBJECT_ID ('TEMPDB..#TMPSTOCKNABARCODE','U') IS NOT NULL
		    DROP TABLE #TMPSTOCKNABARCODE

		SELECT A.PRODUCT_CODE ,
		        isnull(POST_ESTIMATE_MRP_FROM,0) as POST_ESTIMATE_MRP_FROM,
				isnull(POST_ESTIMATE_MRP_TO,0) as POST_ESTIMATE_MRP_TO,
				a.mrp 
		      into #TMPSTOCKNABARCODE
		FROM SKU A (NOLOCK)
		JOIN ARTICLE ART (NOLOCK) ON A.ARTICLE_CODE =ART.ARTICLE_CODE 
		JOIN SECTIOND SD (NOLOCK) ON SD.SUB_SECTION_CODE =ART.SUB_SECTION_CODE 
		JOIN SECTIONM SM (NOLOCK) ON SM.SECTION_CODE =SD.SECTION_CODE
		WHERE ISNULL(ART.CONSIDER_FOR_POST_ESTIMATE,0)=1
		AND ART.STOCK_NA =1 and a.product_code <>'' and a.mrp <>0
		AND ISNULL(SM.ITEM_TYPE,0) IN (0,1)  and isnull(a.er_flag,0) in(0,1) 

		if not exists (select top 1 'u' from #TMPSTOCKNABARCODE)
		begin
		       SET @CERRORMSG='Stock NA Barcode not available '
			   GOTO END_PROC
		end

		UPDATE A SET NEW_PRODUCT_CODE =TMP.PRODUCT_CODE  
		FROM #TMPCMM A
		JOIN #TMPCREDITBILLS B ON A.OLD_CM_ID =B.MEMO_ID
		JOIN #TMPSTOCKNABARCODE TMP ON A.MRP BETWEEN isnull(POST_ESTIMATE_MRP_FROM,0) AND isnull(POST_ESTIMATE_MRP_TO,0)
		
		
		DECLARE @CSTOCKNABARCODE VARCHAR(100),@nmrp numeric(10,2)

		SELECT TOP 1 @CSTOCKNABARCODE=PRODUCT_CODE,@nmrp=a.mrp FROM #TMPSTOCKNABARCODE  A
		ORDER BY a.MRP 

		update  A set NEW_PRODUCT_CODE=@CSTOCKNABARCODE FROM #TMPCMM A
		JOIN #TMPCREDITBILLS B ON A.OLD_CM_ID =B.MEMO_ID
		WHERE ISNULL(NEW_PRODUCT_CODE,'')=''




		SET @NSTEP=30
	   SELECT TOP 1 @CUSERALIAS=USER_ALIAS FROM USERS WHERE USER_CODE=@CUSER_CODE
	   SET @CUSERALIAS=ISNULL(@CUSERALIAS,'')
	
		SET @CKEYSTABLE='KEYS_CMM_'+LTRIM(RTRIM(@CUSERALIAS))
				
		SET @CMEMONOPREFIX=''
				SET @CMEMONOPREFIX=@CLOCATIONID+@CUSERALIAS+'-'
		SET @CMEMONOPREFIX= CAST(SUBSTRING(@CMEMONOPREFIX,1,LEN(@CMEMONOPREFIX)-1) AS VARCHAR(100))+'E'+'-'


	   --**2GENERATE NEW MEMO ID IN NEW ESTIMATE BILLS

		WHILE EXISTS (SELECT TOP 1 'U' FROM #TMPCMM WHERE NEW_CM_ID ='')
		BEGIN

			SELECT TOP 1 @DCMDT=CM_DT FROM #TMPCMM
			WHERE NEW_CM_NO=''
			ORDER BY CM_DT

				EXEC GETNEXTKEY_OPT @CMASTERTABLENAME, @CMEMONO, @NMEMONOLEN, @CMEMONOPREFIX, 1,
								@CFINYEAR,0, @CKEYSTABLE,@CMEMONOVAL OUTPUT   
								
				
				PRINT @CMEMONOVAL
				SET @CCMD=N'IF EXISTS ( SELECT '+@CMEMONO+' FROM ['+@CMASTERTABLENAME+']  (NOLOCK) 
										WHERE '+@CMEMONO+'='''+@CMEMONOVAL+''' 
										AND FIN_YEAR = '''+@CFINYEAR+''' )
								SET @NLOOPOUTPUT=0
							ELSE
								SET @NLOOPOUTPUT=1'
				PRINT @CCMD
				EXEC SP_EXECUTESQL @CCMD, N'@NLOOPOUTPUT BIT OUTPUT',@NLOOPOUTPUT=@NSAVETRANLOOP OUTPUT

        	IF @CMEMONOVAL IS NULL  OR @CMEMONOVAL LIKE '%LATER%'
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO NO....'	
				  GOTO END_PROC  		
			END

			SET @NSTEP=30		-- GENERATING NEW ID
		
			
             SET @CKEYFIELDVAL1 = @CLOCATIONID + @CFINYEAR+ REPLICATE('0', 17-len(@cLocationId)-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))

			-- GENERATING NEW JOB ORDER ID
			--SET @CKEYFIELDVAL1 = @CLOCATIONID + @CFINYEAR+ REPLICATE('0', 15-LEN(LTRIM(RTRIM(@CMEMONOVAL)))) + LTRIM(RTRIM(@CMEMONOVAL))
			
			IF @CKEYFIELDVAL1 IS NULL OR @CKEYFIELDVAL1 LIKE '%LATER%'
			BEGIN
				  SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' ERROR CREATING NEXT MEMO ID....'
				  GOTO END_PROC
			END


			UPDATE #TMPCMM SET NEW_CM_NO =@CMEMONOVAL,NEW_CM_ID=@CKEYFIELDVAL1 WHERE NEW_CM_ID='' AND CM_DT =@DCMDT 

		
		END

		
		SELECT * INTO #TMPCHECK FROM #TMPCMM

			
		 --**3 INSERTING NEW CASH MEMO MASTER
		SET @NSTEP=40
		INSERT CMM01106	( Location_code, AC_CODE, atd_charges, auto_posreco_last_update, autoentry, BIN_ID, calc_da1, calc_da2, campaign_gc_otp, CANCELLED, cash_tendered, CM_DT, cm_id, CM_MODE, CM_NO, cm_time, copies_ptd, ctrls_used, CUSTOMER_CODE,
		 DISCOUNT_AMOUNT, discount_changed, DISCOUNT_PERCENTAGE, discount_remarks, dp_changed, DT_CODE, ebills_tinyurl, ecoupon_id, EDIT_COUNT, EDIT_INFO, edt_user_code, exempted, fc_rate, fin_year, flight_no, gst_round_off, 
		 gv_amount, HO_SYNCH_LAST_UPDATE, INV_MODE, INV_TYPE, LAST_UPDATE, LOYALTY_OTP_CODE, MANUAL_BILL, MANUAL_BILL_FLAG, manual_discount, MANUAL_ROUNDOFF, memo_type, mrp_exchange_bill, mrp_wsp, NET_AMOUNT, OH_TAX_METHOD, 
		 other_charges_cgst_amount, other_charges_gst_percentage, other_charges_hsn_code, other_charges_igst_amount, other_charges_sgst_amount, OTHER_CHARGES_TAXABLE_VALUE, PAN_NO, Party_Gst_No, party_state_code, party_type, 
		 passport_no, patchup_run, pay_mode, payback, PAYMENT_MODE_MODIFIED, PostedInAc, reconciled, ref_cm_id, ref_no, ref_no_paytm, REMARKS, round_off, SALE_PERSON_MODIFIED, SalesSetupinEffect, sent_for_gr, sent_for_recon, 
		 sent_to_ho, shift_id, SMS_SENT, SUBTOTAL, subtotal_r, ticket_no, TOTAL_QUANTITY, TOTAL_QUANTITY_STR, USER_CODE, wizclip_bill_synch_last_update, xn_item_type )  
		
		SELECT @CLOCATIONID Location_code,	'0000000000'  AC_CODE,0 ATD_CHARGES,'' AUTO_POSRECO_LAST_UPDATE,0 AUTOENTRY,'000' BIN_ID,0 CALC_DA1,0 CALC_DA2,'' CAMPAIGN_GC_OTP,0 CANCELLED, 0 CASH_TENDERED, CM_DT,NEW_CM_ID CM_ID,1 CM_MODE, 
		NEW_CM_NO  CM_NO,CM_DT CM_TIME,0 COPIES_PTD, 
		0 CTRLS_USED,'000000000000' CUSTOMER_CODE,bill_discount_amount DISCOUNT_AMOUNT,0 DISCOUNT_CHANGED,0 DISCOUNT_PERCENTAGE,'' DISCOUNT_REMARKS,0 DP_CHANGED,'0000000' DT_CODE,'' EBILLS_TINYURL,'' ECOUPON_ID,0 EDIT_COUNT, 
		'' EDIT_INFO,'0000000' EDT_USER_CODE,0 EXEMPTED, 
		0 FC_RATE,@CFINYEAR FIN_YEAR,'' FLIGHT_NO,0 GST_ROUND_OFF,0 GV_AMOUNT,'' HO_SYNCH_LAST_UPDATE,0 INV_MODE,0 INV_TYPE,GETDATE() LAST_UPDATE,'' LOYALTY_OTP_CODE,
		0 MANUAL_BILL,0 MANUAL_BILL_FLAG,0 MANUAL_DISCOUNT,0 MANUAL_ROUNDOFF, 
		2 MEMO_TYPE,0 MRP_EXCHANGE_BILL,0 MRP_WSP,NET NET_AMOUNT,0 OH_TAX_METHOD,0 OTHER_CHARGES_CGST_AMOUNT,0 OTHER_CHARGES_GST_PERCENTAGE,'0000000000' OTHER_CHARGES_HSN_CODE,0 OTHER_CHARGES_IGST_AMOUNT, 
		0 OTHER_CHARGES_SGST_AMOUNT,0  OTHER_CHARGES_TAXABLE_VALUE,'' PAN_NO,'' PARTY_GST_NO,'00' PARTY_STATE_CODE,0 PARTY_TYPE,'' PASSPORT_NO,0 PATCHUP_RUN,0 PAY_MODE,0 PAYBACK,0 PAYMENT_MODE_MODIFIED, 
		0 POSTEDINAC,0 RECONCILED,'' REF_CM_ID,'' REF_NO,'' REF_NO_PAYTM,'' REMARKS,0 ROUND_OFF,0 SALE_PERSON_MODIFIED,0 SALESSETUPINEFFECT,0 SENT_FOR_GR,0 SENT_FOR_RECON,0 SENT_TO_HO,NULL SHIFT_ID,1 SMS_SENT, 
		CASE WHEN NET>0 THEN NET ELSE 0 END AS SUBTOTAL, 
		CASE WHEN NET<0 THEN NET ELSE 0 END SUBTOTAL_R,'' TICKET_NO,total_qty TOTAL_QUANTITY,
		'' TOTAL_QUANTITY_STR,@CUSER_CODE USER_CODE,'' WIZCLIP_BILL_SYNCH_LAST_UPDATE,1 XN_ITEM_TYPE 
		FROM
		(
		  SELECT B.CM_DT, B.NEW_CM_NO , B.NEW_CM_ID,
		         SUM(NET) AS NET,
				 SUM(QUANTITY) as total_qty,
				 sum(cmm_discount_amount) as bill_discount_amount
		  FROM CMD01106 A
		  JOIN #TMPCMM B ON A.ROW_ID  =B.ROW_ID
		  GROUP BY B.CM_DT, B.NEW_CM_NO , B.NEW_CM_ID
		) A

		SET @NSTEP=50
		UPDATE A SET   DISCOUNT_PERCENTAGE=case when SUBTOTAL +subtotal_r=0 then 0 
		               else  abs(round(A.DISCOUNT_AMOUNT*100/(SUBTOTAL +SUBTOTAL_R),2)) end	
		FROM  CMM01106 A
		JOIN
			(
				SELECT NEW_CM_ID 
				FROM #TMPCMM A
				GROUP BY NEW_CM_ID
		   ) B ON A.CM_ID =B.NEW_CM_ID
		WHERE  A.DISCOUNT_AMOUNT <>0


		--**4 INSERTING NEW CASH MEMO DETAILS

		 INSERT CMD01106	( ALT_charges_applicable, ALT_DELIVERY_DAYS, ALT_JOB_CODE, ALT_JOB_RATE, ALT_VENDOR_JOB_RATE, authorized_brand_disc_pct, basic_discount_amount, basic_discount_percentage, BIN_ID, calc_da1, calc_da2, card_discount, card_discount_amount, card_discount_percentage, CESS_AMOUNT, cgst_amount, cm_id, cmm_discount_amount, COMMISSION_AMOUNT, dept_id, discount_amount, discount_percentage, Discount_Sharing_With_Supplier, EAN, emp_code, emp_code1, emp_code2, FIX_MRP, FOC_QUANTITY, FORM_ID, gst_percentage, Hold_for_Alter, hsn_code, igst_amount, item_desc, item_round_off, LAST_UPDATE, manual_discount, Manual_DP, manual_mrp, manual_tax_method, MRP, NET, net_payable, nrm_id, old_mrp, OLD_NET, 
		 pack_slip_id, pack_slip_row_id, PRODUCT_CODE, QUANTITY, Realize_sale, REF_ORDER_ID, ref_sls_memo_dt, ref_sls_memo_id, ref_sls_memo_no, repeat_pur_order, rfnet, ROW_ID, scheme_discount, scheme_name, 
		 selling_days, sgst_amount, slsdet_row_id, sor_terms_code, SR_NO, tax_amount, tax_method, tax_percentage, tax_round_off, tax_type, weighted_avg_disc_amt, weighted_avg_disc_pct, WeightedNRVBillCount, WeightedQtyBillCount, XN_TYPE, xn_value_with_gst, xn_value_without_gst )  
		 
		 SELECT 	  ALT_charges_applicable, ALT_DELIVERY_DAYS, ALT_JOB_CODE, ALT_JOB_RATE, ALT_VENDOR_JOB_RATE, authorized_brand_disc_pct, basic_discount_amount, basic_discount_percentage, 
		 BIN_ID, calc_da1, calc_da2, card_discount, card_discount_amount, card_discount_percentage, CESS_AMOUNT, cgst_amount, B.NEW_CM_ID cm_id, cmm_discount_amount, COMMISSION_AMOUNT, dept_id, 
		 discount_amount, discount_percentage, Discount_Sharing_With_Supplier, EAN, emp_code, emp_code1, emp_code2, FIX_MRP, FOC_QUANTITY, FORM_ID, gst_percentage, Hold_for_Alter, hsn_code, igst_amount, 
		 item_desc, item_round_off, LAST_UPDATE, manual_discount, Manual_DP, manual_mrp, manual_tax_method, a.MRP, NET, net_payable, nrm_id, old_mrp, OLD_NET, pack_slip_id, pack_slip_row_id, PRODUCT_CODE, 
		 QUANTITY, isnull(Realize_sale,0) as Realize_sale, REF_ORDER_ID, ref_sls_memo_dt, ref_sls_memo_id, ref_sls_memo_no, repeat_pur_order, xn_value_with_gst  rfnet,NEWID() ROW_ID, scheme_discount, scheme_name, selling_days, sgst_amount,
		  slsdet_row_id, 
		 sor_terms_code, SR_NO, tax_amount, tax_method, tax_percentage, tax_round_off, tax_type, weighted_avg_disc_amt, weighted_avg_disc_pct, WeightedNRVBillCount, WeightedQtyBillCount, XN_TYPE, xn_value_with_gst,
		 xn_value_without_gst 
		 FROM  CMD01106 A
		 JOIN #TMPCMM B ON A.ROW_ID  =B.ROW_ID

		 SET @NSTEP=50
		DECLARE @CROUNDBILLLEVEL VARCHAR(2),@NEXCLTAX NUMERIC(10,2)

	   --**5 set net Amount in new estimate bill
	

		UPDATE A SET  NET_AMOUNT=SUBTOTAL+SUBTOTAL_R+ATD_CHARGES+ISNULL(EXCLTAX,0)-DISCOUNT_AMOUNT +
		 +(CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0) end )
		FROM CMM01106 A (NOLOCK)
		JOIN
		(
		SELECT NEW_CM_ID ,
		       SUM(CASE WHEN TAX_METHOD=2 THEN ISNULL(TAX_AMOUNT,0)+ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0) ELSE 0 END 
			   ) AS EXCLTAX
		FROM CMD01106 A
		JOIN #TMPCMM B ON A.ROW_ID  =B.ROW_ID
		GROUP BY NEW_CM_ID
		) B ON A.CM_ID =B.NEW_CM_ID

		--**5 set Round off in new estimate bill

		SET @NSTEP=50			
		SELECT TOP 1 @CROUNDBILLLEVEL=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='SLS_ROUND_BILL_LEVEL' 

		

		UPDATE A SET ROUND_OFF= (CASE WHEN ISNULL(@CROUNDBILLLEVEL,'')='2' THEN ROUND(NET_AMOUNT/5,0)*5-NET_AMOUNT
		WHEN ISNULL(@CROUNDBILLLEVEL,'')='3' THEN CEILING(NET_AMOUNT/5)*5-NET_AMOUNT  ELSE ROUND(NET_AMOUNT,0)-NET_AMOUNT  END)
		FROM CMM01106 A (NOLOCK) 
		JOIN 
		(
		 SELECT  NEW_CM_ID FROM  #TMPCMM 
		 GROUP BY NEW_CM_ID
		)B ON A.CM_ID =B.NEW_CM_ID

		--**6 set Round off in new estimate bill
	
		SET @NSTEP=60			
		UPDATE a SET NET_AMOUNT=NET_AMOUNT+ROUND_OFF 	
		FROM CMM01106 A (NOLOCK) 
		JOIN 
		(
		 SELECT  NEW_CM_ID FROM  #TMPCMM 
		 GROUP BY NEW_CM_ID
		)B ON A.CM_ID =B.NEW_CM_ID	



		 INSERT paymode_xn_det	( adj_memo_id, amount, cc_name, currency_conversion_rate, gv_scratch_no, gv_srno, last_update, memo_id, paymode_code, ref_no, REMARKS, row_id, Wallet_MOBILE, xn_type )  
		 SELECT 	''  adj_memo_id,a.NET_AMOUNT  amount,'' cc_name,1 currency_conversion_rate,'' gv_scratch_no,0 gv_srno, last_update,cm_id  memo_id,'0000000' paymode_code,'' ref_no, REMARKS,newid() row_id,
		 '' Wallet_MOBILE,'SLS' xn_type
		FROM CMM01106 A (NOLOCK) 
		JOIN 
		(
		 SELECT  NEW_CM_ID FROM  #TMPCMM 
		 GROUP BY NEW_CM_ID
		)B ON A.CM_ID =B.NEW_CM_ID	

	
		--******* ----NOW WE PROCESS OF OLD CASH MEMO *** ---
		SET @NSTEP=70	
	

		SET @NSTEP=75
		UPDATE A SET PRODUCT_CODE =c.NEW_Product_code  
		FROM CMD01106 A
		JOIN #TMPCREDITBILLS B ON A.CM_ID =B.MEMO_ID 
		JOIN #TMPCMM C ON A.ROW_ID =C.ROW_ID 



		SET @NSTEP=80
		UPDATE a SET last_update=getdate() FROM cmm01106 a 
		JOIN #TMPCREDITBILLS B ON A.CM_ID =B.MEMO_ID 


		DELETE A FROM #TMPCMM A
		JOIN #TMPCREDITBILLS B ON A.OLD_CM_ID =B.memo_id 

			

		DELETE A FROM  SLR_RECON_DET A
		JOIN #TMPCMM B ON A.CMD_ROW_ID =B.ROW_ID

		DELETE A FROM CMD01106 A
		JOIN #TMPCMM B ON A.ROW_ID =B.ROW_ID 




		SELECT DISTINCT A.CM_ID,A.location_Code  INTO #TMPBLANKCMM  FROM CMM01106 A
		JOIN #TMPCMM B ON A.CM_ID =B.OLD_CM_ID  
		LEFT JOIN CMD01106 CMD (NOLOCK) ON A.CM_ID =CMD.CM_ID
		WHERE A.CANCELLED =0 AND CMD.CM_ID IS NULL


		select distinct OLD_CM_ID 
		into #TMPPAYMENTMODIFIED  
		from #TMPCMM

		--**** now calculate all cash memo of after remove estimate barcode 


		SET @NSTEP=90
		INSERT CMD01106	( ALT_charges_applicable, ALT_DELIVERY_DAYS, ALT_JOB_CODE, ALT_JOB_RATE, ALT_VENDOR_JOB_RATE, authorized_brand_disc_pct, basic_discount_amount, basic_discount_percentage, BIN_ID, calc_da1, calc_da2, card_discount, card_discount_amount, card_discount_percentage, CESS_AMOUNT, cgst_amount, cm_id, cmm_discount_amount, COMMISSION_AMOUNT, dept_id, discount_amount, discount_percentage, Discount_Sharing_With_Supplier, EAN, emp_code, emp_code1, emp_code2, FIX_MRP, FOC_QUANTITY, FORM_ID, gst_percentage, Hold_for_Alter, hsn_code, igst_amount, item_desc, item_round_off, LAST_UPDATE, manual_discount, Manual_DP, manual_mrp, manual_tax_method, MRP, NET, net_payable, nrm_id, old_mrp, OLD_NET, 
		 pack_slip_id, pack_slip_row_id, PRODUCT_CODE, QUANTITY, Realize_sale, REF_ORDER_ID, ref_sls_memo_dt, ref_sls_memo_id, ref_sls_memo_no, repeat_pur_order, rfnet, ROW_ID, scheme_discount, scheme_name, 
		 selling_days, sgst_amount, slsdet_row_id, sor_terms_code, SR_NO, tax_amount, tax_method, tax_percentage, tax_round_off, tax_type, weighted_avg_disc_amt, 
		 weighted_avg_disc_pct, WeightedNRVBillCount, WeightedQtyBillCount, XN_TYPE, xn_value_with_gst, xn_value_without_gst )  

		  SELECT null	  ALT_charges_applicable,null ALT_DELIVERY_DAYS,null ALT_JOB_CODE,null ALT_JOB_RATE,null ALT_VENDOR_JOB_RATE,0 authorized_brand_disc_pct,0 basic_discount_amount,0 basic_discount_percentage, 
		 '000' BIN_ID,0 calc_da1,0 calc_da2,0 card_discount,0 card_discount_amount,0 card_discount_percentage,0 CESS_AMOUNT,0 cgst_amount,cm_id,0 cmm_discount_amount,0 COMMISSION_AMOUNT,A.location_Code  dept_id, 
		 0 discount_amount,0 discount_percentage,null Discount_Sharing_With_Supplier,'' EAN,'0000000' emp_code,'0000000' emp_code1,'0000000' emp_code2,0 FIX_MRP,0 FOC_QUANTITY,'0000000' FORM_ID, 
		 0 as gst_percentage,0 Hold_for_Alter,'0000000000' hsn_code,0 igst_amount, 
		 '' item_desc,0 item_round_off,getdate() LAST_UPDATE,0 manual_discount,0 Manual_DP,0 manual_mrp,0 manual_tax_method,@nmrp MRP,@nmrp NET,0 net_payable,'0000000' nrm_id,0 old_mrp,0 OLD_NET,'' pack_slip_id,'' pack_slip_row_id, 
		 @CSTOCKNABARCODE PRODUCT_CODE,1 QUANTITY,0 Realize_sale,'' REF_ORDER_ID,'' ref_sls_memo_dt,'' ref_sls_memo_id,'' ref_sls_memo_no,0 repeat_pur_order,@nmrp   rfnet,NEWID() ROW_ID,0 scheme_discount,00 scheme_name,0 selling_days, 0 sgst_amount,
		 '' slsdet_row_id,'' sor_terms_code,1 SR_NO,0 tax_amount,1 tax_method,0 tax_percentage,0 tax_round_off,0 tax_type,0 weighted_avg_disc_amt,0 weighted_avg_disc_pct,0 WeightedNRVBillCount,0 WeightedQtyBillCount,'' XN_TYPE, 
		 0 xn_value_with_gst,
		 0  xn_value_without_gst 
		 FROM  #TMPBLANKCMM A

		 update a set DISCOUNT_PERCENTAGE =0,DISCOUNT_AMOUNT =0,atd_charges =0,OTHER_CHARGES_TAXABLE_VALUE =0,
		              other_charges_igst_amount =0,other_charges_cgst_amount =0,other_charges_sgst_amount =0,gst_round_off =0
		  from  cmm01106 a
		 join #TMPBLANKCMM b on a.cm_id =b.cm_id 


      
		         UPDATE A SET SUBTOTAL =CASE WHEN B.NET>0 THEN B.NET ELSE 0 END,
                               SUBTOTAL_R =CASE WHEN B.NET<0 THEN B.NET ELSE 0 END
		         FROM CMM01106 A (NOLOCK)
				JOIN
				(
				SELECT OLD_CM_ID ,
					   SUM(NET) AS NET
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.CM_ID   =B.OLD_CM_ID
				GROUP BY OLD_CM_ID
				) B ON A.CM_ID =B.OLD_CM_ID

				UPDATE A SET   DISCOUNT_PERCENTAGE=case when SUBTOTAL +subtotal_r=0 then 0 else  ABS(ROUND((DISCOUNT_AMOUNT/(SUBTOTAL +subtotal_r ))*100,2)) end	
				FROM  CMM01106 A
				JOIN
				(
				SELECT OLD_CM_ID 
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.CM_ID   =B.OLD_CM_ID
				GROUP BY OLD_CM_ID
				) B ON A.CM_ID =B.OLD_CM_ID
				WHERE ( A.SUBTOTAL +SUBTOTAL_R )>A.DISCOUNT_AMOUNT 
				and A.DISCOUNT_AMOUNT <>0

				
				UPDATE A SET  DISCOUNT_AMOUNT =ROUND(SUBTOTAL *DISCOUNT_PERCENTAGE /100,2)
				FROM  CMM01106 A
				JOIN
				(
				SELECT OLD_CM_ID 
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.CM_ID   =B.OLD_CM_ID
				GROUP BY OLD_CM_ID
				) B ON A.CM_ID =B.OLD_CM_ID
				WHERE ( A.SUBTOTAL +SUBTOTAL_R )<A.DISCOUNT_AMOUNT 
				and A.DISCOUNT_AMOUNT <>0

			    UPDATE A SET 
			    CMM_DISCOUNT_AMOUNT =ROUND((CASE WHEN CMM.SUBTOTAL=0 THEN 0 ELSE NET*cmm.DISCOUNT_AMOUNT/SUBTOTAL END),2)
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.CM_ID   =B.OLD_CM_ID
				JOIN CMM01106 CMM (NOLOCK) ON A.CM_ID =CMM.CM_ID 
				WHERE  net >0

				UPDATE A SET 
			    CMM_DISCOUNT_AMOUNT =ROUND((CASE WHEN CMM.subtotal_r=0 THEN 0 ELSE NET*cmm.DISCOUNT_AMOUNT/subtotal_r END),2)
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.CM_ID   =B.OLD_CM_ID
				JOIN CMM01106 CMM (NOLOCK) ON A.CM_ID =CMM.CM_ID 
				WHERE net <0



		

    
	declare @NSPID varchar(100)
	set @NSPID=@@SPID 
           
	DELETE A FROM GST_TAXINFO_CALC A (NOLOCK) WHERE SP_ID=@NSPID  

	SET @NSTEP=100

          	INSERT GST_TAXINFO_CALC	( PRODUCT_CODE, SP_ID ,NET_VALUE,TAX_METHOD,ROW_ID,QUANTITY,
					LOC_STATE_CODE ,LOC_GSTN_NO,LOCREGISTERED,PARTY_STATE_CODE ,PARTY_GSTN_NO,PARTYREGISTERED,LOCALBILL,MEMO_DT,MRP,SOURCE_DEPT_ID )  
					SELECT PRODUCT_CODE,@NSPID AS SP_ID,(NET-ISNULL(CMM_DISCOUNT_AMOUNT,0)) AS NET_VALUE,
					2  AS TAX_METHOD, ROW_ID,QUANTITY,SLOC.GST_STATE_CODE AS LOC_STATE_CODE,SLOC.LOC_GST_NO AS LOC_GSTN_NO,
					SLOC.REGISTERED_GST AS LOCREGISTERED,B.PARTY_STATE_CODE,
					(CASE WHEN ISNULL(B.AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.AC_GST_NO ELSE '' END) AS 	PARTY_GSTN_NO,
					(CASE WHEN ISNULL(B.AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.REGISTERED_GST_DEALER ELSE 0 END) AS PARTYREGISTERED,
					1 AS LOCALBILL ,
						  B.CM_DT,A.MRP,B.location_Code 
					FROM CMD01106 A  (nolock)
					JOIN CMM01106 B (nolock) ON A.CM_ID=B.CM_ID
					join #TMPPAYMENTMODIFIED tmp on a.cm_id =tmp.OLD_CM_ID  
					JOIN LOCATION SLOC (nolock) ON SLOC.DEPT_ID=B.location_Code
					JOIN CUSTDYM CUS (nolock) ON CUS.CUSTOMER_CODE=B.CUSTOMER_CODE
					LEFT OUTER JOIN LMP01106 LM (nolock) ON LM.AC_CODE=B.AC_CODE
					

               SET @NSTEP=110
					EXEC SP3S_GST_TAX_CAL_BATCH
					@CXN_TYPE='SLS',
					@NSPID=@NSPID,
					@CERRMSG=@CERRORMSG OUTPUT,
					@cLoginDeptId=@CLOCATIONID
					
					IF ISNULL(@CERRORMSG,'')<>''
						GOTO END_PROC
                 
				 SET @NSTEP=120
					
					UPDATE CMD01106 SET TAX_AMOUNT=0,TAX_PERCENTAGE=0,
					HSN_CODE=B.HSN_CODE,GST_PERCENTAGE=B.GST_PERCENTAGE,IGST_AMOUNT=B.IGST_AMOUNT,
					CGST_AMOUNT=B.CGST_AMOUNT,SGST_AMOUNT=B.SGST_AMOUNT,
					XN_VALUE_WITHOUT_GST=B.XN_VALUE_WITHOUT_GST,XN_VALUE_WITH_GST=B.XN_VALUE_WITH_GST,
					CESS_AMOUNT =ISNULL(b.CESS_AMOUNT,0)
					FROM GST_TAXINFO_CALC B WHERE B.ROW_ID=CMD01106.ROW_ID AND B.SP_ID=@NSPID

		


	             SET @NSTEP=130

				UPDATE A SET  NET_AMOUNT=SUBTOTAL+SUBTOTAL_R+ATD_CHARGES+ISNULL(EXCLTAX,0)-DISCOUNT_AMOUNT +
				 +(CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0) end )
				FROM CMM01106 A (NOLOCK)
				JOIN
				(
				SELECT old_CM_ID ,
					   SUM(CASE WHEN TAX_METHOD=2 THEN ISNULL(TAX_AMOUNT,0)+ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0) ELSE 0 END 
					   ) AS EXCLTAX
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.cm_id   =B.OLD_CM_ID
				GROUP BY old_CM_ID
				) B ON A.CM_ID =B.old_CM_ID

		

					
				SELECT TOP 1 @CROUNDBILLLEVEL=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='SLS_ROUND_BILL_LEVEL' 


				UPDATE A SET ROUND_OFF= (CASE WHEN ISNULL(@CROUNDBILLLEVEL,'')='2' THEN ROUND(NET_AMOUNT/5,0)*5-NET_AMOUNT
				WHEN ISNULL(@CROUNDBILLLEVEL,'')='3' THEN CEILING(NET_AMOUNT/5)*5-NET_AMOUNT  ELSE ROUND(NET_AMOUNT,0)-NET_AMOUNT  END)
				FROM CMM01106 A (NOLOCK) 
				JOIN 
				(
				 SELECT  old_CM_ID FROM  #TMPPAYMENTMODIFIED 
				 GROUP BY old_CM_ID
				)B ON A.CM_ID =B.old_CM_ID

			
	
				SET @NSTEP=150			
				UPDATE a SET NET_AMOUNT=NET_AMOUNT+ROUND_OFF 	
				FROM CMM01106 A (NOLOCK) 
				JOIN 
				(
				 SELECT  old_CM_ID FROM  #TMPPAYMENTMODIFIED 
				 GROUP BY old_CM_ID
				)B ON A.CM_ID =B.old_CM_ID	

				UPDATE A SET AMOUNT =CMM.NET_AMOUNT 
				FROM PAYMODE_XN_DET A (NOLOCK) 
				JOIN CMM01106 CMM (NOLOCK) ON A.MEMO_ID= CMM.CM_ID 
				JOIN 
				(
				 SELECT  OLD_CM_ID FROM  #TMPPAYMENTMODIFIED 
				 GROUP BY OLD_CM_ID
				)B ON A.MEMO_ID =B.OLD_CM_ID	
				WHERE A.XN_TYPE ='SLS'

				 INSERT PAYMODE_XN_DET	( adj_memo_id, amount, cc_name, currency_conversion_rate, gv_scratch_no, gv_srno, last_update, memo_id, paymode_code, ref_no, REMARKS, row_id, Wallet_MOBILE, xn_type )  

				 SELECT 	''  ADJ_MEMO_ID,A.NET_AMOUNT AMOUNT,'' CC_NAME,1 CURRENCY_CONVERSION_RATE,'' GV_SCRATCH_NO,'' GV_SRNO,GETDATE() LAST_UPDATE,CM_ID  MEMO_ID, 
				 '0000000' PAYMODE_CODE,'' REF_NO,'' REMARKS,NEWID() ROW_ID,'' WALLET_MOBILE,'SLS' XN_TYPE 
				  FROM CMM01106 A
				JOIN 
				(
				 SELECT  OLD_CM_ID FROM  #TMPPAYMENTMODIFIED 
				 GROUP BY OLD_CM_ID
				) cmm ON A.cm_id =cmm.OLD_CM_ID	
				LEFT JOIN PAYMODE_XN_DET B ON A.CM_ID=B.MEMO_ID AND XN_TYPE ='SLS'
				WHERE   B.MEMO_ID IS NULL and NET_AMOUNT <>0


			
			    UPDATE A SET TOTAL_QUANTITY =B.TOTAL_QTY ,LAST_UPDATE =getdate()
		        FROM CMM01106 A (NOLOCK)
				JOIN
				(
				SELECT OLD_CM_ID ,
					   SUM(QUANTITY) AS TOTAL_QTY
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.CM_ID   =B.OLD_CM_ID
				GROUP BY OLD_CM_ID
				) B ON A.CM_ID =B.OLD_CM_ID


				UPDATE A SET RFNET = NET-CMM_DISCOUNT_AMOUNT+(CASE WHEN TAX_METHOD=2 THEN TAX_AMOUNT+
	                ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(GST_CESS_AMOUNT,0) ELSE 0 END)
				FROM CMD01106 A
				JOIN #TMPPAYMENTMODIFIED B ON A.CM_ID   =B.OLD_CM_ID


				
 

		       
END TRY      
BEGIN CATCH      
     SET @CERRORMSG='ERROR IN SP3S_PROCESS_POSTESIMATE,STEP-'+LTRIM(STR(@NSTEP))+'SQL ERROR: #'+LTRIM(STR(ERROR_NUMBER())) + '  ' + ERROR_MESSAGE()      
END CATCH           
      
END_PROC:      
      
IF @@TRANCOUNT>0        
BEGIN      
      
           IF ISNULL(@CERRORMSG,'')=''     
		   begin
		      
              commit         

		   end
           ELSE      
             ROLLBACK      
                 
 END     
 
 SELECT  @CERRORMSG AS ERRMSG  

END

