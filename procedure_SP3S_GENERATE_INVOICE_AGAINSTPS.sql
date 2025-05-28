CREATE PROCEDURE SP3S_GENERATE_INVOICE_AGAINSTPS--(LocId 3 digit change by Sanjay:05-11-2024)
(
 @NSPID varchar(50)='',--savetran use @NSPID
 @cLOCID varchar(5)='',
 @CMEMONOPREFIX varchar(100)='',
 @NPARTY_AMOUNT_FORTCS numeric(18,2)=0,
 @cLoginBinId varchar(10)='',
 @CUSERCODE varchar(10)='',
 @NLEDGER_BALANCE numeric (14,2)=0,
 @bcheckcreditlimit bit=0,
 @NloginSPID int=0 ,--getwsl item details use @NloginSPID,
 @NUPDATEMODE INT=1,
 @cMemoID varchar(50)='',
 @bRepickRates bit=0,
 @cSP1	VARCHAR(20)='',
 @cSP2	VARCHAR(20)='',
 @cSP3	VARCHAR(20)='',
 @CurrentStockAtRsp  NUMERIC(14,2)=0,
 @MaxStockAtRsp      NUMERIC(14,2)=0,
 @BFLAG              BIT=0

)
AS
BEGIN

           DECLARE @CQRY1 NVARCHAR(MAX),@CAPPLYWSPRATE VARCHAR(4) ,@cFinYear VARCHAR(5)
           SELECT TOP 1 @CAPPLYWSPRATE=VALUE FROM CONFIG WHERE  CONFIG_OPTION='APPLY_WSP_RATE'
           
	        declare @cPartyAcCode varchar(10),@nInvMode int,@cTargetLocId varchar(4),@nItemType int,
			@CERRMSG VARCHAR(MAX),@CSTEP varchar(50),@cTermsCode varchar(1),@nBillLevelTaxMethod int,
			@nMemoType int,@nInvType int,@dInvDt datetime,@nLotPrice NUMERIC(10,2)
			
        	DECLARE @OUTPUT TABLE (errmsg VARCHAR(MAX))


			 BEGIN TRY

			 IF @NUPDATEMODE=3
			    GOTO LBLSAVETRAN

				   DELETE A FROM WSL_PSID A (nolock)
				   JOIN IND01106 B (NOLOCK)  ON A.PS_ID=B.PS_ID 
				   WHERE INV_ID =@CMEMOID  AND A.SP_ID=@NLOGINSPID 

			 set @CSTEP=00
			 DELETE A FROM WSL_ITEM_DETAILS A (nolock) WHERE SP_ID =RTRIM(LTRIM(STR(@NloginSPID) ))

			
			SET @CQRY1=N'INSERT WSL_ITEM_DETAILS	(ROW_ID,BOX_NO, BOX_DT,PRODUCT_CODE,INVOICE_QUANTITY, ITEM_FORM_ID, SP_ID,PS_ID,
			AUTO_SRNO,RATE,MANUAL_RATE,BIN_ID,QUANTITY,mrp,remarks,ws_price )
			SELECT (''LATER''+LEFT(CONVERT(VARCHAR(38),NEWID()),35)) AS ROW_ID,BOX_NO,'''' AS BOX_DT,PRODUCT_CODE,
			QUANTITY AS INVOICE_QUANTITY,''0000000'' AS ITEM_FORM_ID,'''+RTRIM(LTRIM(STR(@NloginSPID) ))+''' AS SP_ID,
			A.PS_ID,0 AS AUTO_SRNO,RATE,'+(CASE WHEN ISNULL(@CAPPLYWSPRATE,'')='1' THEN '1' ELSE '0' END)+' AS MANUAL_RATE,
			BIN_ID,QUANTITY ,a.mrp,A.remarks,a.ws_price
			FROM WPS_DET  A (NOLOCK)
			JOIN    WSL_PSID B (nolock) ON A.PS_ID=B.PS_ID 
			WHERE B.SP_ID='''+RTRIM(LTRIM(STR(@NloginSPID) ))+'''
			 '
			PRINT @CQRY1
			EXEC SP_EXECUTESQL @CQRY1
			set @CSTEP=10

			IF @NUPDATEMODE=2 and  isnull(@bRepickRates,0)=1
		    BEGIN
		       INSERT WSL_ITEM_DETAILS	(ROW_ID,BOX_NO, BOX_DT,PRODUCT_CODE,INVOICE_QUANTITY, ITEM_FORM_ID, SP_ID,PS_ID,AUTO_SRNO,RATE,MANUAL_RATE,BIN_ID,QUANTITY )  
			   SELECT 	ROW_ID,BOX_NO, BOX_DT,PRODUCT_CODE,INVOICE_QUANTITY, ITEM_FORM_ID,RTRIM(LTRIM(STR(@NloginSPID) )) SP_ID,PS_ID,AUTO_SRNO,RATE,MANUAL_RATE,BIN_ID,QUANTITY
	           FROM IND01106  (NOLOCK) WHERE INV_ID =@CMEMOID 
 
             END


		
			 
			SELECT TOP 1  @CPARTYACCODE=A.AC_CODE ,@nInvMode=inv_mode ,@cTargetLocId=party_dept_id  ,@nItemType=XN_ITEM_TYPE ,
			              @nBillLevelTaxMethod=bill_level_tax_method ,@nMemoType=memo_type ,@nInvType=inv_type ,@dInvDt =INV_DT,
						  @nLotPrice=ISNULL(a.lotprice,0)
						
			FROM WSL_INM01106_UPLOAD A (NOLOCK) 
			WHERE a.sp_id =RTRIM(LTRIM((@NSPID) )) --@spid use in savetran

             IF NOT EXISTS (SELECT TOP 1'U' FROM WSL_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(STR(@NloginSPID) ))) and isnull(@CPARTYACCODE,'')=''
		     BEGIN
			     SET @CERRMSG='RECORD NOT FOUND'
				 GOTO END_PROC
			 END


			SELECT top 1 @cTermsCode=a.TERMS_CODE  FROM LEDGER_TERMS a (NOLOCK)
            JOIN LM_TERMS b (NOLOCK) ON b.terms_code=a.terms_code 
            WHERE a.inactive=0 and a.TERMS <>''and b.approved=1 AND b.AC_CODE=@CPARTYACCODE

			
			if @nInvMode=1
			set @cTargetLocId=''
			set @nItemType=isnull(@nItemType,0)

		     SET @cFinYear='01'+DBO.FN_GETFINYEAR (@dInvDt)

		 DELETE A FROM wsl_inv_settings A (nolock) WHERE SP_ID =@NloginSPID

		  set @CSTEP=50

		insert into @OUTPUT
			Exec SP3S_POPULATE_WSLINV_SETTINGS  
			@nSpId =@NloginSPID, 
			@cCurLocId=@cLOCID, 
			@cTargetLocId= @cTargetLocId, 
			@cPartyAcCode= @CPARTYACCODE, 
			@dInvDt= @dInvDt, 
			@cTermsCode= @cTermsCode, 
			@nBillDiscountPct= 0, 
			@nLotprice= @nLotPrice, 
			@nBillLevelTaxMethod= @nBillLevelTaxMethod, 
			@nInvMode=@nInvMode, 
			@nInvType=@nInvType, 
			@bDonotcalexcise=0, 
			@nXferType=1, 
			@nItemType=@nItemType, 
			@nMrpWspmode=0, 
			@cLoginBinId=@cLoginBinId, 
			@CUSERCODE=@CUSERCODE, 
			@nMemoType=@nMemoType 
			

			SELECT TOP 1 @CERRMSG= ERRMSG  FROM @OUTPUT
			IF ISNULL(@CERRMSG,'')<>''
			GOTO END_PROC

			set @CSTEP=110


			
			--EXEC SP3S_GETWSL_DATA_AGAINSTPS 
			--@NSPID=@NloginSPID,
			--@NMODE=1,
			--@cLOCID=@cLOCID,
			--@CXNTYPE='WSL'

		


		IF EXISTS (SELECT TOP 1 'U' FROM WSL_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(STR(@NloginSPID) )) AND ISNULL(ERRMSG,'')<>'' )
		BEGIN

			SELECT PRODUCT_CODE ,ARTICLE_NO,ERRMSG 
			FROM WSL_ITEM_DETAILS WHERE SP_ID=@NloginSPID AND ISNULL(ERRMSG,'')<>'' 
			return

		END
	
		delete from  WSL_INd01106_UPLOAD where sp_id=@NSPID

		IF @NUPDATEMODE=2 and  isnull(@bRepickRates,0)=0
		BEGIN
		     INSERT WSL_IND01106_UPLOAD	( AUTO_SRNO, BIN_ID, BO_DET_ROW_ID, BOX_DT, BOX_ID, BOX_NO, CESS_AMOUNT, CGST_AMOUNT, COMPANY_CODE, CUSTOM_DUTY_AMT, CUSTOM_DUTY_PER, CVD_AMT, CVD_PER, DEPT_ID, DISCOUNT_AMOUNT, 
			 DISCOUNT_PERCENTAGE, EMP_CODE, EMP_CODE1, EMP_CODE2, GROSS_RATE, GST_PERCENTAGE, HSN_CODE, IGST_AMOUNT, INMDISCOUNTAMOUNT, INV_ID, INVOICE_QUANTITY, ITEM_EXCISE_ACCESSIBLE_AMOUNT, 
			 ITEM_EXCISE_ACCESSIBLE_PERCENTAGE, ITEM_EXCISE_DUTY_AMOUNT, ITEM_EXCISE_DUTY_PERCENTAGE, ITEM_EXCISE_EDU_CESS_AMOUNT, ITEM_EXCISE_EDU_CESS_PERCENTAGE, ITEM_EXCISE_HEDU_CESS_AMOUNT, 
			 ITEM_EXCISE_HEDU_CESS_PERCENTAGE, ITEM_EXCISE_MRP, ITEM_FORM_ID, ITEM_ROUND_OFF, ITEM_TAX_AMOUNT, ITEM_TAX_PERCENTAGE, LAST_UPDATE, MANUAL_DISCOUNT, MANUAL_NET_RATE, MANUAL_RATE, MARGIN_AMOUNT, 
			 MARGIN_PERCENTAGE, MRP, NET_RATE, ONLINE_BILL_REF_NO, ONLINE_PRODUCT_CODE, ORDER_ID, ORDER_NO, PARTY_MRP, PICK_LIST_ID, PICK_LIST_ROW_ID, PICKLIST_ARTICLE_CODE, PICKLIST_PARA1_CODE, PICKLIST_PARA2_CODE,
			  PRINT_LABEL, PRODUCT_CODE, PS_ID, QUANTITY, RATE, REF_WPS_DET_ROWID, REMARKS, 
			  RFNET, RFNET_WOTAX, ROW_ID, SCHEME_QUANTITY, SGST_AMOUNT, SP_ID, TAX_ROUND_OFF, TOTAL_CUSTOM_DUTY_AMT, W8_CHALLAN_ID, WS_PRICE, XN_VALUE_WITH_GST, XN_VALUE_WITHOUT_GST )  

			   SELECT 	  AUTO_SRNO, BIN_ID, BO_DET_ROW_ID,BOX_DT AS BOX_DT, BOX_ID,BOX_NO BOX_NO,0 CESS_AMOUNT, CGST_AMOUNT, COMPANY_CODE,0 CUSTOM_DUTY_AMT,0 CUSTOM_DUTY_PER,0 CVD_AMT,0 CVD_PER,@CLOCID DEPT_ID, 
				 DISCOUNT_AMOUNT, DISCOUNT_PERCENTAGE, EMP_CODE,EMP_CODE1, EMP_CODE2, GROSS_RATE, GST_PERCENTAGE, HSN_CODE, IGST_AMOUNT,0 INMDISCOUNTAMOUNT,INV_ID INV_ID,INVOICE_QUANTITY INVOICE_QUANTITY, 
				 ITEM_EXCISE_ACCESSIBLE_AMOUNT, ITEM_EXCISE_ACCESSIBLE_PERCENTAGE, ITEM_EXCISE_DUTY_AMOUNT, ITEM_EXCISE_DUTY_PERCENTAGE, ITEM_EXCISE_EDU_CESS_AMOUNT, ITEM_EXCISE_EDU_CESS_PERCENTAGE, ITEM_EXCISE_HEDU_CESS_AMOUNT, ITEM_EXCISE_HEDU_CESS_PERCENTAGE, ITEM_EXCISE_MRP, 
				  ITEM_FORM_ID, ITEM_ROUND_OFF,0 ITEM_TAX_AMOUNT, ITEM_TAX_PERCENTAGE, 
				 GETDATE() LAST_UPDATE, MANUAL_DISCOUNT, MANUAL_NET_RATE, MANUAL_RATE, MARGIN_AMOUNT, MARGIN_PERCENTAGE, MRP, NET_RATE, ONLINE_BILL_REF_NO, 
				 '' ONLINE_PRODUCT_CODE, ORDER_ID, ORDER_NO, 0  PARTY_MRP,'' PICK_LIST_ID,'' PICK_LIST_ROW_ID,'' PICKLIST_ARTICLE_CODE,'' PICKLIST_PARA1_CODE, PICKLIST_PARA2_CODE,0 PRINT_LABEL, PRODUCT_CODE, 
				 PS_ID, INVOICE_QUANTITY  QUANTITY, RATE, 
				 '' REF_WPS_DET_ROWID, REMARKS,0 RFNET,0 RFNET_WOTAX,ROW_ID, SCHEME_QUANTITY, SGST_AMOUNT,@NSPID SP_ID,0 TAX_ROUND_OFF,0 TOTAL_CUSTOM_DUTY_AMT, W8_CHALLAN_ID, WS_PRICE, XN_VALUE_WITH_GST, XN_VALUE_WITHOUT_GST 
	              FROM IND01106  (NOLOCK) WHERE INV_ID =@CMEMOID 
 

		END

	
		 INSERT wsl_ind01106_upload	( AUTO_SRNO, BIN_ID, BO_DET_ROW_ID, box_dt, BOX_ID, box_no, CESS_AMOUNT, cgst_amount, COMPANY_CODE, custom_duty_amt, custom_duty_per, cvd_amt, cvd_per, DEPT_ID, DISCOUNT_AMOUNT, 
		 DISCOUNT_PERCENTAGE, emp_code, emp_code1, emp_code2, gross_rate, gst_percentage, hsn_code, igst_amount, INMDISCOUNTAMOUNT, INV_ID, invoice_quantity, item_excise_accessible_amount, 
		 item_excise_accessible_percentage, item_excise_duty_amount, item_excise_duty_percentage, item_excise_edu_cess_amount, item_excise_edu_cess_percentage, item_excise_hedu_cess_amount, 
		 item_excise_hedu_cess_percentage, item_excise_mrp, item_form_id, item_round_off, item_tax_amount, item_tax_percentage, LAST_UPDATE, manual_discount, manual_net_rate, manual_rate, margin_amount, 
		 margin_percentage, mrp, net_rate, ONLINE_BILL_REF_NO, ONLINE_PRODUCT_CODE, ORDER_ID, ORDER_NO, party_mrp, pick_list_id, PICK_LIST_ROW_ID, picklist_article_code, picklist_para1_code, picklist_para2_code,
		  print_label, PRODUCT_CODE, ps_id, QUANTITY, RATE, ref_wps_det_rowid, remarks, 
		  rfnet, rfnet_wotax, ROW_ID, scheme_quantity, sgst_amount, SP_ID, tax_round_off, total_custom_duty_amt, w8_challan_id, ws_price, xn_value_with_gst, xn_value_without_gst )  

		 SELECT 	  AUTO_SRNO, BIN_ID, BO_DET_ROW_ID,box_dt as box_dt, BOX_ID,box_no BOX_NO,0 CESS_AMOUNT, cgst_amount,'01' COMPANY_CODE,0 custom_duty_amt,0 custom_duty_per,0 cvd_amt,0 cvd_per,@cLOCID DEPT_ID, 
		 DISCOUNT_AMOUNT, DISCOUNT_PERCENTAGE,'0000000' emp_code,'0000000' emp_code1,'0000000' emp_code2, gross_rate, gst_percentage, hsn_code, igst_amount,0 INMDISCOUNTAMOUNT,'later' INV_ID,invoice_quantity invoice_quantity, 
		 item_excise_accessible_amount, item_excise_accessible_percentage, item_excise_duty_amount, item_excise_duty_percentage, item_excise_edu_cess_amount, item_excise_edu_cess_percentage, item_excise_hedu_cess_amount, item_excise_hedu_cess_percentage, item_excise_mrp, 
		 '0000000' AS item_form_id, item_round_off,0 item_tax_amount, item_tax_percentage, 
		 getdate() LAST_UPDATE, manual_discount, manual_net_rate, manual_rate, margin_amount, margin_percentage, mrp, net_rate, ONLINE_BILL_REF_NO, 
		 '' ONLINE_PRODUCT_CODE, ORDER_ID, ORDER_NO, 0  party_mrp,'' pick_list_id,'' PICK_LIST_ROW_ID,'' picklist_article_code,'' picklist_para1_code,'' picklist_para2_code,0 print_label, PRODUCT_CODE, 
		 ps_id, invoice_quantity  QUANTITY, RATE, 
		 '' ref_wps_det_rowid, remarks,0 rfnet,0 rfnet_wotax,ROW_ID, scheme_quantity, sgst_amount,@NSPID SP_ID,0 tax_round_off,0 total_custom_duty_amt,'' w8_challan_id, ws_price, xn_value_with_gst, xn_value_without_gst 
		  FROM wsl_item_details (nolock) where sp_id=@NloginSPID 

	  IF (SELECT VALUE FROM CONFIG WHERE CONFIG_OPTION='WSL_SALES_PERSON_AT_ITEM_LEVEL')<>1
	  BEGIN
		UPDATE wsl_ind01106_upload SET emp_code=@cSP1,emp_code1=@cSP2,emp_code2=@cSP3 WHERE SP_ID=@NSPID
	  END
	  

	  LBLSAVETRAN:

	set @CSTEP=150
	
	
	  EXEC SaveTran_WSL 
		@nUpdateMode		= @NUPDATEMODE, 
		@nSpId				= @NSPID, 
		@cMemoNoPrefix		= @cMemoNoPrefix, 
		@cFinYear			= @cFinYear, 
		@cMachineName		= '', 
		@cWindowUserName	= '', 
		@cWizAppUserCode	= @CUSERCODE,
		@cMemoID       	= @cMemoID,
		@nBoxno         	= 0,
		@EDIT_CLICKED         	= 0,
		@cProductCode      = '',
		@nApproveMode      = 0, 
		@bcallfrompackslip      = 1, 
		@cComputerIP    = '', 
		@CurrentStockAtRsp = @CurrentStockAtRsp,
		@MaxStockAtRsp 	= @MaxStockAtRsp,
		@BFLAG  = @BFLAG,
		@NPARTY_AMOUNT_FORTCS = @NPARTY_AMOUNT_FORTCS,
		@bCalledFromExcelImport = 0,
		@NLEDGER_BALANCE=@NLEDGER_BALANCE,
		@bcheckcreditlimit = @bcheckcreditlimit,
		@NLOGINSPID=@NLOGINSPID


     END TRY
	  
	  BEGIN CATCH
			PRINT 'ENTER CATCH BLOCK'
			SET @CERRMSG='ERROR IN PROCEDURE SP3S_GENERATE_INVOICE_AGAINSTPS : STEP #'+@CSTEP+' '+ERROR_MESSAGE()
			GOTO END_PROC 


	  END CATCH
   END_PROC:


   IF ISNULL(@CERRMSG,'')<>''
         SELECT @CERRMSG AS ERRMSG,'' AS memo_id
	
	   DELETE FROM WSL_ITEM_DETAILS WHERE SP_ID=RTRIM(LTRIM(STR(@NLOGINSPID) )) 


END