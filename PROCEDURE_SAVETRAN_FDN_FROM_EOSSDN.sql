create PROCEDURE SAVETRAN_FDN_FROM_EOSSDN
@cEossDnMemoId VARCHAR(40)=''
AS
BEGIN


	DECLARE @nSpId VARCHAR(50),@cStep VARCHAR(5),@cFinYear VARCHAR(5),@cCurDeptId CHAR(4),@dMemoDt DATETIME,
	@CERRORMSG VARCHAR(MAX),@bAgstSupplier bit,@nRateDiff  NUMERIC(10,2),@CSOURCETABLE VARCHAR(100),@CSOURCEDEtTABLE varchar(200),
	@CCURSTATE_CODE VARCHAR(10),@cTargetDetTableName varchar(200),
	@cEossDnMemoNos VARCHAR(500),@cXnItemType VARCHAR(2),@nXnItemtype NUMERIC(1,0),@CPARTYSTATE_CODE VARCHAR(10),
	@nFactor NUMERIC(2,0),@cSorMemono VARCHAR(20),@cSkipNegEntries VARCHAR(2),@bSkipNegEntries BIT,
	@cMinRateDiff VARCHAR(10),@nMinRateDiff NUMERIC(10,2),@nTotAmt NUMERIC(10,2),@bCalcGstonFdnFcn BIT

BEGIN TRY
	
	SET @cStep='5'
	SET @CERRORMSG=''

	DECLARE @tSorMemos TABLE (memo_id VARCHAR(50))

	IF @cEossDnMemoId<>''
		INSERT @tSorMemos (memo_id) 
		SELECT @cEossDnMemoId

	select TOP 1 @cCurDeptId=b.location_code,@CFINYEAR='01'+dbo.fn_getfinyear(memo_dt)
	from @tSorMemos a JOIN eossdnm b (NOLOCK) ON a.memo_id=b.memo_id

	IF @bAgstSupplier=1
	BEGIN
		DECLARE @DONOT_CALCULATE_GST_FDN VARCHAR(10)
		SELECT TOP 1 @DONOT_CALCULATE_GST_FDN=VALUE  FROM CONFIG WHERE CONFIG_OPTION='DONOT_CALCULATE_GST_FDN' 	
		SET @DONOT_CALCULATE_GST_FDN=ISNULL(@DONOT_CALCULATE_GST_FDN,'')
		SET @bCalcGstonFdnFcn=(CASE WHEN @DONOT_CALCULATE_GST_FDN='1' then 0 ELSE 1 END)
	END
	

	
		
	SET @nSpid=NEWID();
	
	SET @cStep='10'
	
	DECLARE @cTargetTableName VARCHAR(50),@cColname VARCHAR(100),@bGenCn BIT

	SELECT @nRateDiff=sum(discount_sharing_amount) FROM eossdnd a (NOLOCK)
	JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id 

	IF ISNULL(@nRateDiff,0)=0
	BEGIN
		SET @cErrormsg='No FDN is applicable to be generated against the Memo(s)....Please check'
		GOTO END_PROC
	END

	SET @cStep='12'
	SET @bGenCn=0 --
	SET @nFactor = (CASE WHEN (@nRateDiff<0 AND @bAgstSupplier=1) AND @bGenCn=1 THEN -1
					WHEN (@nRateDiff<0 AND @bAgstSupplier=0) AND @bGenCn=0 THEN -1 ELSE 1 END)

	--SELECT TOP 1 @cSkipNegEntries=value FROM config (NOLOCK) WHERE config_option='skip_negentries_sor_fdncn'
	--SELECT TOP 1 @cMinRateDiff=value FROM config (NOLOCK) WHERE config_option='min_ratediff_sor_fdncn_gen'

	SELECT @bSkipNegEntries=0,@nMinRateDiff=0

	SET @cStep='12.5'
	IF ISNULL(@cSkipNegEntries,'')='1'
		SET  @bSkipNegEntries=1

	--IF ISNULL(@cMinRateDiff,'')<>''
	--	SET  @nMinRateDiff=@cMinRateDiff
	

	SET @cStep='14'
	IF EXISTS (SELECT top 1 rm_id from rmm01106  a (NOLOCK) JOIN eossdnm b (NOLOCK) ON 'FDN'+a.rm_id=b.ref_fdn_memoid
			   JOIN @tSorMemos c ON c.memo_id=b.MEMO_ID WHERE a.cancelled=0)
	BEGIN
		SET @cStep='17'
		SELECT TOP 1 @cSorMemono=b.memo_no,@cErrormsg='FDN no.:'+rm_no from rmm01106  a (NOLOCK) JOIN eossdnm b (NOLOCK) ON 'FDN'+a.rm_id=b.ref_fdn_memoid
		JOIN @tSorMemos c ON c.memo_id=b.MEMO_ID  WHERE a.cancelled=0

		IF ISNULL(@cErrormsg,'')=''
			select top 1 @cSorMemono=b.memo_no, @cErrormsg='FCN no.:'+cn_no from cnm01106  a (NOLOCK) JOIN eossdnm b (NOLOCK) ON 'FCN'+a.cn_id=b.ref_fdn_memoid
			JOIN @tSorMemos c ON c.memo_id=b.MEMO_ID WHERE a.cancelled=0
		

		SET @cErrormsg=@cErrormsg+' already created against this Memo ...Please check'
		GOTO END_PROC
	END

	
	BEGIN TRAN	
	
	SELECT @cXnItemType=value FROM config (NOLOCK) WHERE config_option='DEFAULT_EOSSDN_XNITEMTYPE'

	IF ISNULL(@cXnItemType,'')<>''
		SET @nXnItemtype=@cXnItemType
	ELSE
		SET @nXnItemtype=1

	SELECT @CPARTYSTATE_CODE=ISNULL(B.AC_GST_STATE_CODE,''),@CCURSTATE_CODE=ISNULL(c.GST_STATE_CODE,'')
	FROM eossdnm a 
	LEFT JOIN lmp01106 b ON b.ac_code=a.ac_code
	JOIN location c ON c.dept_id=a.location_code 
	WHERE a.memo_id=@ceossdnmemoId

	SELECT @cEossDnMemoNos=COALESCE(@cEossDnMemoNos+',',memo_no) FROM  eossdnm a (NOLOCK)
	JOIN @tSorMemos b ON a.memo_id=b.memo_id
	SET @cStep='28'


	IF EXISTS (SELECT TOP 1 rm_id FROM PRT_rmm01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId)			
		DELETE FROM prt_rmm01106_upload WITH (ROWLOCK) WHERE sp_id=@nSpid
		
	SELECT @cTargetTableName='rmm01106',@cColname='rm_no',@bGenCn=0,@CSOURCETABLE='prt_rmm01106_upload',
	@CSOURCEDEtTABLE='prt_rmd01106_upload',@cTargetDetTableName='rmd01106'

	SET @cStep='32'
	INSERT prt_rmm01106_upload	( ac_code, ACCOUNTS_DEPT_ID, ANGADIA_DETAIL, approved, ApprovedLevelNo, 
	bandals, batch_no, BIN_ID, BROKER_AC_CODE, broker_comm_amount, broker_comm_percentage, CANCELLED, 
	CN_AMOUNT, CN_NO, completed, CR_RECEIVED, CREDIT_DAYS, diffAmount, discount_amount, discount_percentage, 
	DN_TYPE, DO_NOT_CALC_GST_OH, EDIT_COUNT, edt_user_code, emp_code, Entry_Mode, ewaydistance, 
	excise_duty_amount, exported, fin_year, freight, freight_cgst_amount, freight_gst_percentage, 
	freight_hsn_code, freight_igst_amount, freight_sgst_amount, FREIGHT_TAXABLE_VALUE, generated_by_chrecon, 
	grlr_date, grlr_no, gst_round_off, last_update, lot_no, manual_broker_comm, manual_discount,
	manual_roundoff, memo_prefix, memo_type, mode, OH_TAX_METHOD, other_charges, other_charges_cgst_amount, 
	other_charges_gst_percentage, other_charges_hsn_code, other_charges_igst_amount, other_charges_sgst_amount,
	OTHER_CHARGES_TAXABLE_VALUE, party_dept_id, party_state_code, PostedInAc, PRTSource, rate_diff, reconciled, 
	REMARKS, rm_dt, rm_id, rm_no, rm_time, round_off, route_form1, route_form2, 
	sent_for_recon, sent_to_ho, SHIPPING_AC_CODE, shipping_address, shipping_address2, shipping_address3, 
	shipping_area_code, shipping_area_name, shipping_city_name, shipping_pin, shipping_same_as_billing_Add, 
	shipping_state_name, sms_sent, SP_ID, subtotal, TARGET_BIN_ID, tax_picking_mode, taxform_storage_mode, 
	total_amount, TOTAL_BOX_NO, Total_Gst_Amount, TOTAL_QUANTITY, TOTAL_QUANTITY_STR, uploaded_to_activstream, 
	user_code, Way_bill, xfer_type, XN_ITEM_TYPE )  
	SELECT TOP 1 ac_code,@cCurDeptId as  ACCOUNTS_DEPT_ID,''  ANGADIA_DETAIL,0 approved, 0 ApprovedLevelNo, 
	0 bandals,'' batch_no,'000' BIN_ID,'0000000000' BROKER_AC_CODE,0 broker_comm_amount,0 broker_comm_percentage,0 CANCELLED, 
	0 CN_AMOUNT,'' CN_NO,1 completed,0 CR_RECEIVED,0 CREDIT_DAYS,0 diffAmount,0 discount_amount,0 discount_percentage, 
	2 DN_TYPE,0 DO_NOT_CALC_GST_OH,0 EDIT_COUNT,'0000000' edt_user_code,'0000000' emp_code,1 Entry_Mode, 0 ewaydistance, 
	0 excise_duty_amount,0  exported, fin_year,0  freight,0  freight_cgst_amount,0  freight_gst_percentage, 
	'0000000000' freight_hsn_code,0 freight_igst_amount,0  freight_sgst_amount,0   FREIGHT_TAXABLE_VALUE, 0 generated_by_chrecon, 
	'' grlr_date,'' grlr_no,0 gst_round_off,getdate() as last_update,0 lot_no,0 manual_broker_comm,0 manual_discount,
	0 manual_roundoff,'' memo_prefix,1 memo_type,1 mode,1 OH_TAX_METHOD,0 other_charges,0 other_charges_cgst_amount, 
	0 other_charges_gst_percentage,'0000000000' other_charges_hsn_code,0  other_charges_igst_amount,0  other_charges_sgst_amount,
	0 OTHER_CHARGES_TAXABLE_VALUE,null party_dept_id,'00' party_state_code,0  PostedInAc,0  PRTSource,
	abs(@nRateDiff) rate_diff,0  reconciled,'Auto Generated from Eoss Debit Note Memo(s)#'+@cEossDnMemoNos REMARKS,
	memo_dt rm_dt,'LATER' rm_id,'LATER'  rm_no,'' rm_time,0 round_off,'' route_form1,'' route_form2, 
	0 sent_for_recon,0  sent_to_ho,'' SHIPPING_AC_CODE,'' shipping_address,'' shipping_address2,'' shipping_address3, 
	'' shipping_area_code,''  shipping_area_name,'' shipping_city_name,'' shipping_pin,0 shipping_same_as_billing_Add, 
	'' shipping_state_name,0 sms_sent,@nSpId SP_ID,ABS(@nRateDiff)  subtotal,'000' TARGET_BIN_ID,0 tax_picking_mode,
	0 taxform_storage_mode,0 total_amount,0 TOTAL_BOX_NO,0 Total_Gst_Amount,0 TOTAL_QUANTITY,
	'' TOTAL_QUANTITY_STR,0 uploaded_to_activstream, 
	user_code,0 Way_bill,0 xfer_type,@nXnItemtype XN_ITEM_TYPE 
	FROM eossdnm a (NOLOCK) JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id

	INSERT prt_rmd01106_upload	( amount, AUTO_SRNO, bill_dt, bill_level_tax_method, bill_no, BIN_ID, box_dt, 
	BOX_ID, box_no, CashDiscountAmount, CashDiscountRate, CESS_AMOUNT, cgst_amount, DEPT_ID, DISCOUNT_amount, 
	DISCOUNT_PERCENTAGE, dn_discount_amount, dn_discount_percentage, excise_duty_amount, FDN_Rate, 
	gross_purchase_price, Gst_Cess_Amount, Gst_Cess_Percentage, gst_percentage, hsn_code, igst_amount, inv_Rate,
	invoice_quantity, ITEM_EXCISE_DUTY_PERCENTAGE, item_form_id, item_tax_amount, item_tax_percentage, 
	last_update, LOT_NO, manual_discount, manual_Rate, MRP_BATCH, mrr_id, mrr_no, Party_Pur_Excise_Rate, 
	PID_ROW_ID, product_code, PRTAmount, PS_ID, pur_bill_challan_mode, pur_cd_percentage, PUR_DISCOUNT_AMOUNT, 
	PUR_DISCOUNT_PERCENTAGE, pur_excise_duty_amount, pur_excise_duty_rate, pur_form_id, pur_gross_purchase_price,
	PUR_PURCHASE_PRICE, pur_tax_amount, pur_tax_percentage, pur_taxable_value, purchase_price, quantity, Rate, 
	REMARKS, RFNET, RFNET_WOTAX, rm_id, RMMDISCOUNTAMOUNT, row_id, scheme_quantity, sgst_amount, SP_ID, SRNO, 
	tax_round_off, terms, uom_code, w8_challan_id, xn_value_with_gst, xn_value_without_gst ) 

	SELECT rate_diff*@nFactor amount,0  AUTO_SRNO,'' bill_dt,1  bill_level_tax_method,''  bill_no,'000' BIN_ID,'' box_dt, 
	'' BOX_ID,0  box_no,0  CashDiscountAmount,0  CashDiscountRate,0  CESS_AMOUNT,0  cgst_amount,@cCurDeptId DEPT_ID,0  DISCOUNT_amount, 
	0 DISCOUNT_PERCENTAGE,0  dn_discount_amount,0  dn_discount_percentage,0  excise_duty_amount,0  FDN_Rate, 
	rate_diff*@nFactor gross_purchase_price,0  Gst_Cess_Amount,0  Gst_Cess_Percentage,rate_diff_gst_percentage  gst_percentage,
	hsn_code,0  igst_amount,0  inv_Rate,
	1 invoice_quantity,0  ITEM_EXCISE_DUTY_PERCENTAGE,0  item_form_id,0  item_tax_amount,0  item_tax_percentage, 
	getdate() last_update,0  LOT_NO,0  manual_discount,0  manual_Rate,0  MRP_BATCH,''  mrr_id,''  mrr_no,0  Party_Pur_Excise_Rate, 
	'' PID_ROW_ID, product_code,0  PRTAmount,''  PS_ID,0 pur_bill_challan_mode,0  pur_cd_percentage,0  PUR_DISCOUNT_AMOUNT, 
	0 PUR_DISCOUNT_PERCENTAGE,0  pur_excise_duty_amount,0 pur_excise_duty_rate,''  pur_form_id,0  pur_gross_purchase_price,
	0 PUR_PURCHASE_PRICE,0  pur_tax_amount,0  pur_tax_percentage,0  pur_taxable_value,rate_diff*@nFactor purchase_price, 
	1 quantity,0  Rate, '' REMARKS,rate_diff*@nFactor  RFNET,0  RFNET_WOTAX,'LATER' rm_id,0  RMMDISCOUNTAMOUNT,newid() row_id,0  scheme_quantity,0  sgst_amount,@nSpId SP_ID,0  SRNO, 
	0 tax_round_off,''  terms,'000' uom_code,''  w8_challan_id,0  xn_value_with_gst,rate_diff*@nFactor as  xn_value_without_gst 
	FROM eosssord  a (NOLOCK) JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id
	WHERE (rate_diff*@nFactor>0 AND @bSkipNegEntries=1) OR (rate_diff<>0 AND @bSkipNegEntries=0)

	IF @bCalcGstonFdnFcn=1
	BEGIN
		IF @CPARTYSTATE_CODE=@CCURSTATE_CODE
			UPDATE prt_rmd01106_upload SET cgst_amount=ROUND((purchase_price*gst_percentage/100)/2,2),
			sgst_amount=ROUND((purchase_price*gst_percentage/100)/2,2)
			WHERE sp_id=@nSpId
		ELSE
			UPDATE prt_rmd01106_upload SET igst_amount=ROUND(purchase_price*gst_percentage/100,2)
			WHERE sp_id=@nSpId
	END
	ELSE
		UPDATE prt_rmd01106_upload SET gst_percentage=0, igst_amount=0,cgst_amount=0,sgst_amount=0,xn_value_without_gst=0
		WHERE sp_id=@nSpId

	UPDATE prt_rmd01106_upload SET rfnet=xn_value_without_gst+igst_amount+cgst_amount+sgst_amount
	WHERE sp_id=@nSpId

	UPDATE a set subtotal=b.subtotal,total_amount=b.subtotal+b.gst,Total_Gst_Amount=b.gst from prt_rmm01106_upload a
	JOIN 
	(select sp_id,sum(cgst_amount+sgst_amount+igst_amount) gst,SUM(purchase_price*quantity) subtotal from  prt_rmd01106_UPLOAD (NOLOCK) 
		WHERE sp_id=@nSpId GROUP BY sp_id) b on a.sp_id=b.sp_id

	SET @cStep='35'

	declare @CMEMONOPREFIX VARCHAR(10),@cMemoNo VARCHAR(20),@cMemoId VARCHAR(50)
	SET @CMEMONOPREFIX=@cCurDeptId+'F-'

REGENRATE:    
		
	DECLARE @NMEMONOLEN NUMERIC(10,0)
	SET @NMEMONOLEN=LEN(LTRIM(RTRIM(@CMEMONOPREFIX)))+6
	
	SET @cStep='40'
			
	--select @CFINYEAR	,@cTargetTableName,@cColName
	EXEC GETNEXTKEY @cTargetTableName, @cColName, @NMEMONOLEN, @CMEMONOPREFIX, 1,@CFINYEAR,0, @cMemoNo  OUTPUT      
		   
	IF @cMemoNo IS NULL          
	BEGIN      
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@CSTEP)) + ' ERROR CREATING NEXT Memo no. ....'           
		GOTO END_PROC              
	END
	
	SET @cStep='50'
	
	
	IF @bGenCn=1 AND EXISTS (SELECT TOP 1 * FROM CNM01106 WHERE CN_NO = @cMemoNo AND FIN_YEAR = @CFINYEAR )
		GOTO REGENRATE 
	ELSE
	IF @bGenCn=0 AND EXISTS (SELECT TOP 1 * FROM RMM01106 WHERE RM_NO = @cMemoNo AND FIN_YEAR = @CFINYEAR )
		GOTO REGENRATE 
					
	SET @cMemoId = @CCURDEPTID + @CFINYEAR+ ISNULL(REPLICATE('0', 15-LEN(LTRIM(RTRIM(@cMemoNo)))),'') + LTRIM(RTRIM(@cMemoNo)) 
		      
	IF @cMemoId  IS NULL            
	BEGIN          
		SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@CSTEP)) + ' ERROR CREATING NEXT CN_ID.'          
		GOTO end_proc          
	END 

	SET @cStep='60'

	DECLARE @CWHERECLAUSE VARCHAR(400)
	UPDATE prt_rmm01106_upload SET rm_no=@cMemoNo,rm_id=@cMemoId WHERE sp_id=@nSpId
	UPDATE prt_rmd01106_upload SET rm_id=@cMemoId WHERE sp_id=@nSpId

	UPDATE a SET ref_fdn_memoid='FDN'+@cMemoId FROM eossdnm a WITH (ROWLOCK)
	JOIN @tSorMemos b ON a.MEMO_Id=b.memo_id

	SET @CWHERECLAUSE=' sp_id='''+@nSPId+'''' 

	SET @cStep='70'

	--select cn_no,cn_id from WSR_cnm01106_UPLOAD where sp_id=@nSpid

	EXEC UPDATEMASTERXN_OPT
		  @CSOURCEDB	= ''
		, @CSOURCETABLE = @CSOURCETABLE
		, @CDESTDB		= ''
		, @CDESTTABLE	= @cTargetTableName
		, @CKEYFIELD1	= @cColName
		, @BALWAYSUPDATE = 1
		, @CFILTERCONDITION=@cWhereClause
		, @LINSERTONLY =  1
		, @LUPDATEXNS =  1

	SET @cStep='75'
	EXEC UPDATEMASTERXN_OPT
		  @CSOURCEDB	= ''
		, @CSOURCETABLE = @CSOURCEDetTABLE
		, @CDESTDB		= ''
		, @CDESTTABLE	= @cTargetDetTableName
		, @CKEYFIELD1	= @cColName
		, @BALWAYSUPDATE = 1
		, @CFILTERCONDITION=@cWhereClause
		, @LINSERTONLY =  1
		, @LUPDATEXNS =  1

	GOTO END_PROC

END TRY
begin catch
	SET @CERRORMSG='Error in Procedure SAVETRAN_FCN_FROM_EOSSSOR AT Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
end catch

END_PROC:
	--select sum(purchase_price*quantity),sum(cgst_amount+sgst_amount+igst_amount) from  rmd01106 where rm_id=@cMemoid

	--select subtotal,total_amount,discount_amount,@bSkipNegEntries SkipNegEntries from  rmm01106 where rm_id=@cMemoid
	
	IF @@TRANCOUNT>0
	BEGIN
		if ISNULL(@CERRORMSG,'')=''
			COMMIT
		ELSE
			ROLLBACK
	END

	print 'Last step:'+@cStep
	SELECT isnull(@cMemoId,'') as memo_id, ISNULL(@CERRORMSG,'') AS errmsg,(CASE WHEN @bGenCn=1 THEN 'FCN' ELSE 'FDN' END) as memo_type
	
END