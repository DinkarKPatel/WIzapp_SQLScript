CREATE PROCEDURE SAVETRAN_FCNDN_FROM_EOSSSOR
@cEossSorMemoId VARCHAR(40)='',
@cXnType VARCHAR(10)='SOR'
AS
BEGIN

	DECLARE @nSpId VARCHAR(50),@cStep VARCHAR(5),@cFinYear VARCHAR(5),@cCurDeptId VARCHAR(4),@dMemoDt DATETIME,
	@CERRORMSG VARCHAR(MAX),@bAgstSupplier bit,@nRateDiff  NUMERIC(10,2),@CSOURCETABLE VARCHAR(100),@CSOURCEDEtTABLE varchar(200),
	@CCURSTATE_CODE VARCHAR(10),@cTargetDetTableName varchar(200),@cSorSalePeriod VARCHAR(200),
	@cSorMemoNos VARCHAR(500),@cXnItemType VARCHAR(2),@nXnItemtype NUMERIC(1,0),@CPARTYSTATE_CODE VARCHAR(10),
	@nFactor NUMERIC(2,0),@cSorMemono VARCHAR(20),@cSkipNegEntries VARCHAR(2),@bSkipNegEntries BIT,@cGenbothFdnFcn VARCHAR(2),
	@cMinRateDiff VARCHAR(10),@nMinRateDiff NUMERIC(10,2),@nTotAmt NUMERIC(10,2),@bCalcGstonFdnFcn BIT,@nBaseRateDiff NUMERIC(10,2)

BEGIN TRY
	
	SET @cStep='5'
	SET @CERRORMSG=''

	DECLARE @tSorMemos TABLE (memo_id VARCHAR(50),memo_no VARCHAR(20),refFdnMemoId VARCHAR(50),refFcnMemoId VARCHAR(50))

	IF @cEossSorMemoId<>''
		INSERT @tSorMemos (memo_id,memo_no) 
		SELECT @cEossSorMemoId,memo_no from eosssorm (NOLOCK) WHERE memo_id=@cEossSorMemoId
	ELSE
		INSERT @tSorMemos (memo_id,memo_no) 
		SELECT a.memo_id,memo_no FROM #tmpSorMemos a JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
		WHERE a.memo_id=@cEossSorMemoId

	select TOP 1 @cCurDeptId=b.location_Code ,@CFINYEAR='01'+dbo.fn_getfinyear(memo_dt),
	@bAgstSupplier=ISNULL(AgnstSupplier,0),@bCalcGstonFdnFcn=ISNULL(c.calc_gst_rate_diff_fcndn,0),
	@cSorSalePeriod=' Agst. Sale Period :'+CONVERT(VARCHAR,b.PERIOD_FROM,105)+' to '+CONVERT(VARCHAR,b.PERIOD_TO,105)
	from @tSorMemos a JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	JOIN tbl_eoss_disc_share_mst c (NOLOCK) ON c.id=b.id

	IF @bAgstSupplier=1
	BEGIN
		DECLARE @DONOT_CALCULATE_GST_FDN VARCHAR(10)
		SELECT TOP 1 @DONOT_CALCULATE_GST_FDN=VALUE  FROM CONFIG WHERE CONFIG_OPTION='DONOT_CALCULATE_GST_FDN' 	
		SET @DONOT_CALCULATE_GST_FDN=ISNULL(@DONOT_CALCULATE_GST_FDN,'')
		SET @bCalcGstonFdnFcn=(CASE WHEN @DONOT_CALCULATE_GST_FDN='1' then 0 ELSE 1 END)
	END
	
		
	SET @nSpid=NEWID();
	
	SET @cStep='10'
	
	DECLARE @cTargetTableName VARCHAR(50),@cColname VARCHAR(100),@bGenCn BIT,@bGenDn BIT,@nRateDiffPositive NUMERIC(10,2),@nRateDiffNegative NUMERIC(10,2)
	SELECT TOP 1 @cGenbothFdnFcn=value FROM config (NOLOCK) WHERE config_option='generate_both_fdnfcn_sor'
	SET @cGenbothFdnFcn=ISNULL(@cGenbothFdnFcn,'')

	SELECT @nRateDiffPositive=sum(rate_diff) FROM eosssord a (NOLOCK)
	JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id WHERE ISNULL(rate_diff,0)<>0 and rate_diff>0

	SELECT @nRateDiffNegative=sum(rate_diff) FROM eosssord a (NOLOCK)
	JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id WHERE ISNULL(rate_diff,0)<>0 and rate_diff<0


	SET @nRateDiff=ISNULL(@nRateDiffPositive,0)+ISNULL(@nRateDiffNegative,0)

	IF (ISNULL(@nRateDiff,0)=0 AND @cGenbothFdnFcn<>'1') OR (ISNULL(@nRateDiffPositive,0)=0 AND ISNULL(@nRateDiffNegative,0)=0)
	BEGIN
		SET @cErrormsg='No FDN/FCN is applicable to be generated against the Memo(s)....Please check'
		GOTO END_PROC
	END

	SET @cStep='12'
	IF @cGenbothFdnFcn<>'1'
		SET @bGenCn=(CASE WHEN (@nRateDiff<0 AND @bAgstSupplier=1) OR (@nRateDiff>0 AND @bAgstSupplier=0) THEN 1 ELSE 0 END)
	ELSE
		SELECT @bGenCn=(CASE WHEN (@nRateDiffNegative<>0 AND @bAgstSupplier=1) OR (@nRateDiffPositive<>0 AND @bAgstSupplier=0) THEN 1 ELSE 0 END),
		@bGenDn=(CASE WHEN (@nRateDiffNegative<>0 AND @bAgstSupplier=0) OR (@nRateDiffPositive<>0 AND @bAgstSupplier=1) THEN 1 ELSE 0 END)

	SET @nFactor = (CASE WHEN (@nRateDiff<0 AND @bAgstSupplier=1) AND @bGenCn=1 THEN -1
					WHEN (@nRateDiff<0 AND @bAgstSupplier=0) AND @bGenCn=0 THEN -1 ELSE 1 END)


	SELECT TOP 1 @cSkipNegEntries=value FROM config (NOLOCK) WHERE config_option='skip_negentries_sor_fdncn'
	SELECT TOP 1 @cMinRateDiff=value FROM config (NOLOCK) WHERE config_option='min_ratediff_sor_fdncn_gen'

	IF ISNULL(@cSkipNegEntries,'')='1' AND ISNULL(@cGenbothFdnFcn,'')='1'
		SET @cSkipNegEntries=''
		

	SELECT @bSkipNegEntries=0,@nMinRateDiff=0

	SET @cStep='12.5'
	IF ISNULL(@cSkipNegEntries,'')='1'
		SET  @bSkipNegEntries=1

	IF ISNULL(@cMinRateDiff,'')<>''
		SET  @nMinRateDiff=@cMinRateDiff
	
	IF @nMinRateDiff<>0
	BEGIN
		SELECT @nTotAmt=SUM(rate_diff)*@nFactor FROM eosssord a (NOLOCK) 
		JOIN @tSorMemos b ON a.memo_id=b.memo_id 
		WHERE (rate_diff*@nFactor>0 AND @bSkipNegEntries=1) OR rate_diff<>0

		IF ABS(@nTotAmt)<@nMinRateDiff
		BEGIN
			SET @CERRORMSG='Minimum FDN/FCN amount should be :'+ltrim(rtrim(str(@nTotAmt)))+'....Cannot Save'
			GOTO END_PROC
		END
	END

	SET @cStep='14'
	IF EXISTS (SELECT top 1 rm_id from rmm01106  a (NOLOCK) JOIN SOR_FDNFCN_LINK b (NOLOCK) ON a.rm_id=b.refFdnMemoId
			   JOIN @tSorMemos c ON c.memo_id=b.sorMemoId WHERE a.cancelled=0)
		or exists (SELECT top 1 cn_id from cnm01106  a (NOLOCK) JOIN SOR_FDNFCN_LINK b (NOLOCK) ON a.cn_id=b.refFcnMemoId
			   JOIN @tSorMemos c ON c.memo_id=b.sorMemoId  WHERE a.cancelled=0)
	BEGIN
		SET @cStep='17'
		SELECT TOP 1 @cSorMemono=c.memo_no,@cErrormsg='FDN no.:'+rm_no from rmm01106  a (NOLOCK) JOIN SOR_FDNFCN_LINK b (NOLOCK) ON a.rm_id=b.refFdnMemoId
			   JOIN @tSorMemos c ON c.memo_id=b.sorMemoId WHERE a.cancelled=0

		IF ISNULL(@cErrormsg,'')=''
			select top 1 @cSorMemono=c.memo_no, @cErrormsg='FCN no.:'+cn_no from cnm01106  a (NOLOCK) JOIN SOR_FDNFCN_LINK b (NOLOCK) ON a.cn_id=b.refFcnMemoId
			   JOIN @tSorMemos c ON c.memo_id=b.sorMemoId WHERE a.cancelled=0
		

		SET @cErrormsg=@cErrormsg+' already created against SOR Memo no.'+@cSorMemono+' ...Please check'
		GOTO END_PROC
	END

	
	BEGIN TRAN	
	
	SELECT @cXnItemType=value FROM config (NOLOCK) WHERE config_option='DEFAULT_SOR_FDNFCN_XNITEMTYPE'

	IF ISNULL(@cXnItemType,'')<>''
		SET @nXnItemtype=@cXnItemType
	ELSE
		SET @nXnItemtype=1

	SELECT @CPARTYSTATE_CODE=(CASE WHEN @bAgstSupplier=0 THEN ISNULL(L.GST_STATE_CODE,'''') ELSE  ISNULL(B.AC_GST_STATE_CODE,'''') END),
	@CCURSTATE_CODE=ISNULL(c.GST_STATE_CODE,'')
	FROM eosssorm a 
	LEFT JOIN lmp01106 b ON b.ac_code=a.ac_code
	LEFT JOIN location l ON l.dept_id=a.party_dept_id
	JOIN location c ON c.dept_id=a.location_Code 
	WHERE a.memo_id=@cEosssorMemoId

	SELECT @cSorMemoNos=COALESCE(@cSorMemoNos+',',memo_no) FROM  @tSorMemos

	declare @CMEMONOPREFIX VARCHAR(10),@cMemoNo VARCHAR(20),@cMemoId VARCHAR(50)
	SET @CMEMONOPREFIX=@cCurDeptId+'F-'
	
	DECLARE @NMEMONOLEN NUMERIC(10,0),@CWHERECLAUSE VARCHAR(400)
	SET @NMEMONOLEN=LEN(LTRIM(RTRIM(@CMEMONOPREFIX)))+6
	
	SET @CWHERECLAUSE=' sp_id='''+@nSPId+'''' 

	IF @bGenCn=1
	BEGIN  
		SET @cStep='20'

		SELECT @cTargetTableName='cnm01106',@cColname='cn_no',@CSOURCETABLE='wsr_cnm01106_upload',
		@CSOURCEDEtTABLE='wsr_cnd01106_upload',@cTargetDetTableName='cnd01106'

		IF EXISTS (SELECT TOP 1 cn_id FROM WSR_cnm01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId)			
			DELETE FROM wsr_cnm01106_upload WITH (ROWLOCK) WHERE sp_id=@nSpid
	
		SET @nBaseRateDiff = (CASE WHEN @cGenbothFdnFcn<>'1' THEN @nRateDiff WHEN @bAgstSupplier=1 THEN @nRateDiffPositive ELSE @nRateDiffNegative END)

		IF @cGenbothFdnFcn='1'
			set @nFactor=(case when @bAgstSupplier=1 then -1 else 1 end)

		SET @cStep='25'		
		INSERT wsr_cnm01106_upload (fin_year,last_update,sp_id,ac_code,entry_mode,rm_id,PARTY_DEPT_ID,cn_id,cn_dt,cn_no,bin_id,CHECKED_BY,company_code,cn_type,dt_code,BILLED_FROM_DEPT_ID,CN_TIME,
		manual_inv_no,manual_dn_no,manual_dn_dt,receipt_dt,memo_type,PARTY_STATE_CODE,freight_hsn_code,
		other_charges_hsn_code,subtotal,total_amount,remarks,mode,xn_item_type,location_Code)
		SELECT TOP 1 @cFinYear, getdate() as lasst_update,@nSpid as sp_id,ac_code,1 as entry_mode,null as rm_id,NULL as party_dept_id,'LATER' AS CN_ID,memo_dt as cn_dt,
		'LATER' as cn_no,'000' as bin_id,'' as checked_by,
		'01' company_code,2 as cn_type,'0000000' dt_code,@cCurDeptId BILLED_FROM_DEPT_ID,getdate() cn_time,
		A.memo_NO AS MANUAL_INV_NO,A.memo_NO AS MANUAL_DN_NO,
		A.memo_DT AS MANUAL_DN_DT, memo_dt as receipt_dt,1 as memo_type,@CPARTYSTATE_CODE PARTY_STATE_CODE,
		null as freight_hsn_code,null as other_charges_hsn_code,ABS(@nBaseRateDiff) subtotal,0 total_amount,
		'Auto Generated from SOR Payment Advice Memo(s)#'+@cSorMemoNos+@cSorSalePeriod as remarks,1 mode,@nXnItemtype xn_item_type,
		@cCurDeptId
		FROM eosssorm A (NOLOCK) 
		JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id
		
		
		INSERT wsr_cnd01106_upload	( AUTO_SRNO, bill_level_tax_method, BIN_ID, BOX_ID, CESS_AMOUNT, cgst_amount, 
		challan_id, cn_id, cn_tax_method, CNMDISCOUNTAMOUNT, custom_duty_amt, custom_duty_per, cvd_amt, cvd_per, 
		dept_id, discount_amount, discount_percentage, Edu_cess_custom, Edu_cess_cvd, emp_code, emp_code1, 
		emp_code2, excise_mrp, gross_rate, Gst_Cess_Amount, Gst_Cess_Percentage, gst_percentage, H_Edu_cess_custom, 
		H_Edu_cess_cvd, hsn_code, igst_amount, IND_DISCOUNT_AMOUNT, IND_DISCOUNT_PERCENTAGE, ind_rate, 
		inm_discount_amount, inm_discount_percentage, inv_dt, inv_net_rate, inv_no, invoice_quantity, item_form_id, 
		item_tax_amount, item_tax_percentage, last_update, LOCAL_TAX_STATUS, manual_discount, manual_Rate, 
		net_rate, ONLINE_BILL_REF_NO, ORDER_NO, print_label, product_code, ps_id, quantity, RATE, rate_per_conv_uom,
		ref_inv_id, rfnet, rfnet_wotax, row_id, scheme_quantity, sgst_amount, SP_ID, tax_round_off, 
		total_custom_duty_amt, xn_value_with_gst, xn_value_without_gst )  
		SELECT   1 as AUTO_SRNO,1 bill_level_tax_method,'000' BIN_ID,0 BOX_ID,0 CESS_AMOUNT,0 cgst_amount, 
		'' challan_id,'LATER' cn_id,0 cn_tax_method,0 CNMDISCOUNTAMOUNT,0 custom_duty_amt,0 custom_duty_per,
		0 cvd_amt,0  cvd_per,@cCurDeptId dept_id,0  discount_amount,0  discount_percentage,0  Edu_cess_custom,0  Edu_cess_cvd,
		'0000000'  emp_code,'0000000' emp_code1,'0000000' emp_code2,0  excise_mrp,0  gross_rate,0  Gst_Cess_Amount,0  Gst_Cess_Percentage,
		rate_diff_gst_percentage gst_percentage,0  H_Edu_cess_custom, 
		0 H_Edu_cess_cvd,hsn_code,0  igst_amount,0  IND_DISCOUNT_AMOUNT,0  IND_DISCOUNT_PERCENTAGE,0  ind_rate, 
		0 inm_discount_amount,0  inm_discount_percentage,'' inv_dt,0  inv_net_rate,'' inv_no,1*(case when rate_diff*@nFactor<0 THEN -1 ELSE 1 END)  invoice_quantity,'' item_form_id, 
		0 item_tax_amount,0 item_tax_percentage,getdate() last_update,'' LOCAL_TAX_STATUS,0  manual_discount,0  manual_Rate, 
		abs(rate_diff) net_rate,'' ONLINE_BILL_REF_NO,'' ORDER_NO,0  print_label,a.product_code,'' ps_id,1*(case when rate_diff*@nFactor<0 THEN -1 ELSE 1 END)  quantity,
		abs(rate_diff) as RATE,1 rate_per_conv_uom,'' ref_inv_id,0  rfnet,rate_diff*@nFactor  rfnet_wotax,newid() row_id,0  scheme_quantity,0  sgst_amount,@nSpId SP_ID,
		0  tax_round_off, 0 total_custom_duty_amt,0  xn_value_with_gst,rate_diff*@nFactor as xn_value_without_gst
		FROM eosssord a (NOLOCK) JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id
		WHERE (rate_diff*@nFactor>0 AND @bSkipNegEntries=1 AND @cGenbothFdnFcn<>'1') OR (rate_diff<>0 AND @bSkipNegEntries=0 AND @cGenbothFdnFcn<>'1') OR
		      (rate_diff<0 AND @cGenbothFdnFcn='1' AND @bAgstSupplier=1) OR (rate_diff>0 AND @cGenbothFdnFcn='1' AND @bAgstSupplier=0)


		SET @cStep='27'	
		IF @bCalcGstonFdnFcn=1
		BEGIN
			IF @CPARTYSTATE_CODE=@CCURSTATE_CODE
				UPDATE wsr_cnd01106_upload SET cgst_amount=ROUND((net_rate*gst_percentage*quantity/100)/2,2),
				sgst_amount=ROUND((net_rate*gst_percentage*quantity/100)/2,2)
				WHERE sp_id=@nSpId
			ELSE
				UPDATE wsr_cnd01106_upload SET igst_amount=ROUND(net_rate*gst_percentage*quantity/100,2)
				WHERE sp_id=@nSpId
		END
		ELSE
			UPDATE wsr_cnd01106_upload SET gst_percentage=0,igst_amount=0,cgst_amount=0,sgst_amount=0
			WHERE sp_id=@nSpId

		SET @cStep='29'	
		UPDATE wsr_cnd01106_upload SET rfnet=xn_value_without_gst+igst_amount+cgst_amount+sgst_amount
		WHERE sp_id=@nSpId
			
		UPDATE a set subtotal=b.subtotal, total_amount=b.subtotal+b.gst,Total_Gst_Amount=b.gst from wsr_cnm01106_upload a
		JOIN 
		(select sp_id,sum(cgst_amount+sgst_amount+igst_amount) gst,SUM(net_rate*quantity) subtotal from  WSR_CND01106_UPLOAD (NOLOCK) 
		 WHERE sp_id=@nSpId GROUP BY sp_id) b on a.sp_id=b.sp_id


REGENRATEFCN:    
		
		SET @cStep='31'
			
		--select @CFINYEAR	,@cTargetTableName,@cColName
		EXEC GETNEXTKEY @cTargetTableName, @cColName, @NMEMONOLEN, @CMEMONOPREFIX, 1,@CFINYEAR,0, @cMemoNo  OUTPUT      
		   
		IF @cMemoNo IS NULL          
		BEGIN      
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@CSTEP)) + ' ERROR CREATING NEXT Memo no. ....'           
			GOTO END_PROC              
		END
	
		SET @cStep='34'
	
	
		IF @bGenCn=1 AND EXISTS (SELECT TOP 1 * FROM CNM01106 WHERE CN_NO = @cMemoNo AND FIN_YEAR = @CFINYEAR )
			GOTO REGENRATEFCN 

		SET @cMemoId = @CCURDEPTID + @CFINYEAR+ ISNULL(REPLICATE('0', 15-LEN(LTRIM(RTRIM(@cMemoNo)))),'') + LTRIM(RTRIM(@cMemoNo)) 
		      
		IF @cMemoId  IS NULL            
		BEGIN          
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@CSTEP)) + ' ERROR CREATING NEXT CN_ID.'          
			GOTO end_proc          
		END 
	
		UPDATE wsr_cnm01106_upload SET cn_no=@cMemoNo,cn_id=@cMemoId WHERE sp_id=@nSpId
		UPDATE wsr_cnd01106_upload SET cn_id=@cMemoId WHERE sp_id=@nSpId

		UPDATE @tSorMemos SET refFcnMemoId=@cMemoId


		SET @cStep='37'	
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

		SET @cStep='40'
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



	END
	
	IF (@bGenCn=0 AND @cGenbothFdnFcn<>'1') OR (@bGenDn=1 AND @cGenbothFdnFcn='1')
	BEGIN
		
		SET @cStep='42'	
		IF @cGenbothFdnFcn='1'
			SET @nFactor = (CASE WHEN @nRateDiffNegative<>0 AND @bAgstSupplier=0 THEN -1 ELSE 1 END)


		IF EXISTS (SELECT TOP 1 rm_id FROM PRT_rmm01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId)			
			DELETE FROM prt_rmm01106_upload WITH (ROWLOCK) WHERE sp_id=@nSpid
		
		SELECT @cTargetTableName='rmm01106',@cColname='rm_no',@bGenCn=0,@CSOURCETABLE='prt_rmm01106_upload',
		@CSOURCEDEtTABLE='prt_rmd01106_upload',@cTargetDetTableName='rmd01106'

		SET @cStep='44'
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
		user_code, Way_bill, xfer_type, XN_ITEM_TYPE,location_Code)  
		SELECT TOP 1 ac_code,@cCurDeptId as  ACCOUNTS_DEPT_ID,''  ANGADIA_DETAIL,0 approved, 0 ApprovedLevelNo, 
		0 bandals,'' batch_no,'000' BIN_ID,'0000000000' BROKER_AC_CODE,0 broker_comm_amount,0 broker_comm_percentage,0 CANCELLED, 
		0 CN_AMOUNT,'' CN_NO,1 completed,0 CR_RECEIVED,0 CREDIT_DAYS,0 diffAmount,0 discount_amount,0 discount_percentage, 
		2 DN_TYPE,0 DO_NOT_CALC_GST_OH,0 EDIT_COUNT,'0000000' edt_user_code,'0000000' emp_code,1 Entry_Mode, 0 ewaydistance, 
		0 excise_duty_amount,0  exported, fin_year,0  freight,0  freight_cgst_amount,0  freight_gst_percentage, 
		'0000000000' freight_hsn_code,0 freight_igst_amount,0  freight_sgst_amount,0   FREIGHT_TAXABLE_VALUE, 0 generated_by_chrecon, 
		'' grlr_date,'' grlr_no,0 gst_round_off,getdate() as last_update,0 lot_no,0 manual_broker_comm,0 manual_discount,
		0 manual_roundoff,'' memo_prefix,1 memo_type,1 mode,1 OH_TAX_METHOD,0 other_charges,0 other_charges_cgst_amount, 
		0 other_charges_gst_percentage,'0000000000' other_charges_hsn_code,0  other_charges_igst_amount,0  other_charges_sgst_amount,
		0 OTHER_CHARGES_TAXABLE_VALUE,null party_dept_id,@CPARTYSTATE_CODE party_state_code,0  PostedInAc,0  PRTSource,
		abs(@nRateDiff) rate_diff,0  reconciled,'Auto Generated from SOR Payment Advice Memo(s)#'+@cSorMemoNos+@cSorSalePeriod REMARKS,
		memo_dt rm_dt,'LATER' rm_id,'LATER'  rm_no,'' rm_time,0 round_off,'' route_form1,'' route_form2, 
		0 sent_for_recon,0  sent_to_ho,ac_Code SHIPPING_AC_CODE,'' shipping_address,'' shipping_address2,'' shipping_address3, 
		'' shipping_area_code,''  shipping_area_name,'' shipping_city_name,'' shipping_pin,0 shipping_same_as_billing_Add, 
		'' shipping_state_name,0 sms_sent,@nSpId SP_ID,ABS(@nRateDiff)  subtotal,'000' TARGET_BIN_ID,0 tax_picking_mode,
		0 taxform_storage_mode,0 total_amount,0 TOTAL_BOX_NO,0 Total_Gst_Amount,0 TOTAL_QUANTITY,
		'' TOTAL_QUANTITY_STR,0 uploaded_to_activstream, 
		user_code,0 Way_bill,0 xfer_type,@nXnItemtype XN_ITEM_TYPE,@cCurDeptId location_Code 
		FROM eosssorm a (NOLOCK) JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id

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

		SELECT rate_diff amount,0  AUTO_SRNO,'' bill_dt,1  bill_level_tax_method,''  bill_no,'000' BIN_ID,'' box_dt, 
		'' BOX_ID,0  box_no,0  CashDiscountAmount,0  CashDiscountRate,0  CESS_AMOUNT,0  cgst_amount,@cCurDeptId DEPT_ID,0  DISCOUNT_amount, 
		0 DISCOUNT_PERCENTAGE,0  dn_discount_amount,0  dn_discount_percentage,0  excise_duty_amount,0  FDN_Rate, 
		abs(rate_diff) gross_purchase_price,0  Gst_Cess_Amount,0  Gst_Cess_Percentage,rate_diff_gst_percentage  gst_percentage,
		hsn_code,0  igst_amount,0  inv_Rate,
		1*(case when rate_diff*@nFactor<0 THEN -1 ELSE 1 END) invoice_quantity,0  ITEM_EXCISE_DUTY_PERCENTAGE,0  item_form_id,0  item_tax_amount,0  item_tax_percentage, 
		getdate() last_update,0  LOT_NO,0  manual_discount,0  manual_Rate,0  MRP_BATCH,''  mrr_id,''  mrr_no,0  Party_Pur_Excise_Rate, 
		'' PID_ROW_ID, product_code,0  PRTAmount,''  PS_ID,0 pur_bill_challan_mode,0  pur_cd_percentage,0  PUR_DISCOUNT_AMOUNT, 
		0 PUR_DISCOUNT_PERCENTAGE,0  pur_excise_duty_amount,0 pur_excise_duty_rate,''  pur_form_id,0  pur_gross_purchase_price,
		0 PUR_PURCHASE_PRICE,0  pur_tax_amount,0  pur_tax_percentage,0  pur_taxable_value,abs(rate_diff) purchase_price, 
		1*(case when rate_diff*@nFactor<0 THEN -1 ELSE 1 END) quantity,0  Rate, '' REMARKS,rate_diff*@nFactor  RFNET,0  RFNET_WOTAX,'LATER' rm_id,0  RMMDISCOUNTAMOUNT,newid() row_id,0  scheme_quantity,0  sgst_amount,@nSpId SP_ID,0  SRNO, 
		0 tax_round_off,''  terms,'000' uom_code,''  w8_challan_id,0  xn_value_with_gst,rate_diff*@nFactor as  xn_value_without_gst 
		FROM eosssord  a (NOLOCK) JOIN @tSorMemos b ON a.MEMO_ID=b.memo_id
		WHERE (@cGenbothFdnFcn<>'1' AND (rate_diff*@nFactor)>0 AND @bSkipNegEntries=1) OR (rate_diff<>0 AND @bSkipNegEntries=0 AND @cGenbothFdnFcn<>'1') OR
		      (rate_diff>0 AND @cGenbothFdnFcn='1' AND @bAgstSupplier=1) OR (rate_diff<0 AND @cGenbothFdnFcn='1' AND @bAgstSupplier=0)

		SET @cStep='47'	
		IF @bCalcGstonFdnFcn=1
		BEGIN
			IF @CPARTYSTATE_CODE=@CCURSTATE_CODE
				UPDATE prt_rmd01106_upload SET cgst_amount=ROUND((purchase_price*gst_percentage*quantity/100)/2,2),
				sgst_amount=ROUND((purchase_price*gst_percentage*quantity/100)/2,2)
				WHERE sp_id=@nSpId
			ELSE
				UPDATE prt_rmd01106_upload SET igst_amount=ROUND(purchase_price*gst_percentage*quantity/100,2)
				WHERE sp_id=@nSpId
		END
		ELSE
			UPDATE prt_rmd01106_upload SET gst_percentage=0, igst_amount=0,cgst_amount=0,sgst_amount=0
			WHERE sp_id=@nSpId

		SET @cStep='50'	
		UPDATE prt_rmd01106_upload SET rfnet=xn_value_without_gst+igst_amount+cgst_amount+sgst_amount
		WHERE sp_id=@nSpId

		UPDATE a set subtotal=b.subtotal,total_amount=b.subtotal+b.gst,Total_Gst_Amount=b.gst from prt_rmm01106_upload a
		JOIN 
		(select sp_id,sum(cgst_amount+sgst_amount+igst_amount) gst,SUM(purchase_price*quantity) subtotal from  prt_rmd01106_UPLOAD (NOLOCK) 
		 WHERE sp_id=@nSpId GROUP BY sp_id) b on a.sp_id=b.sp_id


REGENRATEFDN:    
		
		SET @cStep='52'
			
		--select @CFINYEAR	,@cTargetTableName,@cColName
		EXEC GETNEXTKEY @cTargetTableName, @cColName, @NMEMONOLEN, @CMEMONOPREFIX, 1,@CFINYEAR,0, @cMemoNo  OUTPUT      
		   
		IF @cMemoNo IS NULL          
		BEGIN      
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@CSTEP)) + ' ERROR CREATING NEXT Memo no. ....'           
			GOTO END_PROC              
		END
	
		SET @cStep='55'
	
	
		IF EXISTS (SELECT TOP 1 * FROM RMM01106 WHERE RM_NO = @cMemoNo AND FIN_YEAR = @CFINYEAR )
			GOTO REGENRATEFDN 

		SET @cMemoId = @CCURDEPTID + @CFINYEAR+ ISNULL(REPLICATE('0', 15-LEN(LTRIM(RTRIM(@cMemoNo)))),'') + LTRIM(RTRIM(@cMemoNo)) 
		      
		IF @cMemoId  IS NULL            
		BEGIN          
			SET @CERRORMSG = 'STEP- ' + LTRIM(STR(@CSTEP)) + ' ERROR CREATING NEXT CN_ID.'          
			GOTO end_proc          
		END 

		SET @cStep='57'	

		UPDATE prt_rmm01106_upload SET rm_no=@cMemoNo,rm_id=@cMemoId WHERE sp_id=@nSpId
		UPDATE prt_rmd01106_upload SET rm_id=@cMemoId WHERE sp_id=@nSpId

		UPDATE @tSorMemos SET refFdnMemoId=@cMemoId


		SET @cStep='60'	
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

		SET @cStep='63'
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


	END

	SET @cStep='65'	
	INSERT SOR_FDNFCN_LINK	( refFcnMemoId, refFdnMemoId, sorMemoId )  
	SELECT refFcnMemoId, refFdnMemoId, memo_id FROM @tSorMemos


	GOTO END_PROC

END TRY
begin catch
	SET @CERRORMSG='Error in Procedure SAVETRAN_FCN_FROM_EOSSSOR AT Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
end catch

END_PROC:
	--select sum(purchase_price*quantity),sum(cgst_amount+sgst_amount+igst_amount) from  rmd01106 where rm_id=@cMemoid

	--select subtotal,total_amount,discount_amount,@bSkipNegEntries SkipNegEntries from  rmm01106 where rm_id=@cMemoid
	

	--SELECT 'CHECK SOR_FDNFCN_LINK',@cMemoId,* FROM SOR_FDNFCN_LINK
	--select total_amount,* from rmm01106 A JOIN SOR_FDNFCN_LINK B ON A.rm_ID=B.refFdnMemoId WHERE B.sorMemoId=@cEossSorMemoId
	--select total_amount,* from CNm01106 A JOIN SOR_FDNFCN_LINK B ON A.CN_ID=B.refFCnMemoId WHERE B.sorMemoId=@cEossSorMemoId

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