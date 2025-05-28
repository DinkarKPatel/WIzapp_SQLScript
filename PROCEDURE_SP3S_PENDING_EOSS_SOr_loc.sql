CREATE PROCEDURE SP3S_PENDING_EOSS_SOr_loc
(
	 @DFROMDT DATETIME=''
	,@DTODT DATETIME=''
	,@CAC_CODE VARCHAR(10)=''
	,@CEOSSTERMSID VARCHAR(10)=''
	,@cLocId VARCHAR(5)=''
	,@bGetSchemesData BIT=0
	,@bUpdateSchemesData BIT=0
	,@cLoginDeptId VARCHAR(5)
	,@bCalledFromMulti BIT=0
	,@nSpId VARCHAR(40)=''
	,@cCurMemoId VARCHAR(40)=''
)	
AS
BEGIN
/*
	EXEC SP3S_PENDING_EOSS_SOR '2015-01-01','2015-09-08','0011500006','ARTICLE.ARTICLE_NO IN (''MENS - COAT SUIT'',''MENS - JACKET'',''MENS - TROUSER'')'
	EXEC SP3S_PENDING_EOSS_SOR '2015-01-01','2015-09-08','0000000009','ARTICLE.ARTICLE_NO IN (''MENS - COAT SUIT'',''MENS - JACKET'',''MENS - TROUSER'')'
*/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @CCMD NVARCHAR(MAX),@CCMD1 NVARCHAR(MAX),@CCMD2 NVARCHAR(MAX),@CEOSS_TERMID VARCHAR(1000),@CFRESH_TERMID VARCHAR(1000)
		   ,@CEOSSREIMBURSEVAT CHAR(1),@CFILTER VARCHAR(MAX),@cEossTemrsIdPara VARCHAR(20),@cJoinStr VARCHAR(500)
		   ,@CFRESHREIMBURSEVAT CHAR(1),@CTABLENAME VARCHAR(300),@cErrormsg VARCHAR(MAX),@bCalledFromDashBoard BIT,@cStep VARCHAR(5)
		   ,@cInsCols VARCHAR(MAX),@cCols NVARCHAR(MAX),@cColsGrp VARCHAR(1000),@bConsiderPPMDFromMrp bit,@nMarkDownPct NUMERIC(6,2)
		   ,@nInputGstCalMethod NUMERIC(1,0),@cAddInputGstRateDiff VARCHAR(2),@bSisLoc BIT,@cPickMinDiscforSisLoc VARCHAR(5)
		   ,@cDonotConsiderGstDiffNpCalc VARCHAR(2),@cRetainExcelNrv VARCHAR(2)


BEGIN TRY
	SET @cEossTemrsIdPara=@CEOSSTERMSID
	
	-- Add Input Gst in Rate difference calculation of SOR Payment Advice

	SELECT TOP 1 @cAddInputGstRateDiff=value FROM config (NOLOCK) WHERE 
	config_option='AddInputGstRateDiff'

	SELECT TOP 1 @cDonotConsiderGstDiffNpCalc=value FROM config (NOLOCK) WHERE 
	config_option='DonotConsiderGstDiffNpCalc_SOR'

	SELECT TOP 1 @cRetainExcelNrv=value FROM config (NOLOCK) WHERE 
	config_option='Retain_Excel_nrv_sisloc_SaleImp'

	SELECT @cAddInputGstRateDiff=ISNULL(@cAddInputGstRateDiff,''),
	@cDonotConsiderGstDiffNpCalc=ISNULL(@cDonotConsiderGstDiffNpCalc,'')

	SET @cErrormsg=''
	SET @cStep='10'
	SET @bCalledFromDashBoard=0
	
	
	SET @cJoinStr=''

	IF @nSpId=''
		SET @nSpId=CONVERT(VARCHAR(40),NEWID())

	IF @cCurMemoId<>'LATER'
		SELECT @bGetSchemesData=0,@DFROMDT=PERIOD_FROM,@dToDt=PERIOD_to,@CEOSSTERMSID=id,@cLocId=party_dept_id 
		FROM eosssorm (NOLOCK) WHERE memo_id=@cCurMemoId

	SELECT @bSisLoc=ISNULL(sis_loc,0) FROM location (NOLOCK) WHERE dept_id=@cLocId

	IF @bSisLoc=1
		SELECT TOP 1 @cPickMinDiscforSisLoc=value FROM config (NOLOCK) WHERE config_option='PICK_MINDISCOUNT_SOR_SISLOC'
	
	SET @cPickMinDiscforSisLoc=ISNULL(@cPickMinDiscforSisLoc,'')

	IF @CEOSSTERMSID<>''
	BEGIN		
		
		SELECT TOP 1 @CFILTER=ISNULL(A_FILTER,''),@bConsiderPPMDFromMrp=ISNULL(consider_pp_as_markdown_from_mrp,0),
		@nMarkDownPct=ISNULL(mark_down_pct_for_pp,0),@nInputGstCalMethod=ISNULL(input_gst_cal_method,0)
		FROM TBL_EOSS_DISC_SHARE_MST (NOLOCK) WHERE ID=@CEOSSTERMSID
	
		SET @cStep='20'
		set @CFILTER = (CASE WHEN  ISNULL(@CFILTER,'')='' THEN ' 1=1 ' ELSE @CFILTER END)

		SET @CFILTER=@CFILTER+' AND Cmm.location_code ='''+@cLocId+''''
	END
	ELSE
	IF @bCalledFromMulti=1
	BEGIN
		--if @@spid=514
			--select * into tsorlm from #tSorLm
		SET @cFilter = ' 1=1 '
		SET @cJoinStr=' JOIN #tSorLm sorlm ON sorlm.ac_code=sku.ac_code '
	END
	ELSE
		SET @cFilter = ' 1=1 '


	IF @CEOSSTERMSID='' AND @bGetSchemesData=0 AND @bUpdateSchemesData=0 AND @bCalledFromMulti=0
	BEGIN
		SELECT @bCalledFromDashBoard=1,@CFILTER=' 1=1 '
	END

	

	SET @CCMD=N''
	SET @CCMD1=N''
	SET @CCMD2=N''
	/*GM_TYPE: 1 FOR EOSS AND 2 FOR FRESH*/
	SET @cStep='25'
	
	IF @bUpdateSchemesData=1 AND @cLocId<>''
	BEGIN
		PRINT 'Updating Sor terms code in cmd table from User defined'
		UPDATE a set sor_terms_code=b.sor_terms_code FROM cmd01106 a (NOLOCK) JOIN sor_pay_upload b (NOLOCK) ON a.scheme_name=b.scheme_name
		JOIN cmm01106 c (NOLOCK) ON c.cm_id=a.cm_id
		WHERE b.sp_id=@nSpId AND c.cm_dt BETWEEN @dFromdt AND @dToDt AND c.location_Code =@cLocId
		AND ISNULL(a.sor_terms_code,'')<>ISNULL(b.sor_terms_code,'')

		PRINT 'Updating finished Sor terms code in cmd table from User defined'
		GOTO END_PROC
	END

	SET @cStep='32.4'

	IF EXISTS (SELECT TOP 1 row_id FROM  sor_pay_upload (NOLOCK) WHERE sp_id=@nSpId)
	BEGIN
		SET @cStep='32.6'

		DELETE FROM sor_pay_upload WITH (ROWLOCK) WHERE sp_id=@nSpId
	END	
	
	SET @cStep='32.8'

	IF @bGetSchemesData=1
	BEGIN
		SELECT @cInsCols='SP_ID,slsdet_row_id,scheme_name,sor_terms_code,SOR_TERMS_DESC',
			   @cCols=N''''+@NsPiD+''' sp_id,slsdet_row_id,scheme_name,
				    (CASE WHEN ISNULL(CMD.sor_terms_code,'''')='''' THEN ''000'' ELSE cmd.sor_terms_code END) as  sor_terms_code,
					(CASE WHEN ISNULL(CMD.sor_terms_code,'''')='''' THEN '''' ELSE st.sor_terms_name END) AS sor_terms_DESC' 
		SET @CFILTER=@CFILTER+(CASE WHEN @CFILTER<>'' THEN ' AND ' ELSE '' END)+ ' isnull(cmd.scheme_name,'''')<>'''' AND isnull(slsdet_row_id,'''')<>'''''
	END
	ELSE
	BEGIN


		SELECT @cInsCols='sp_id,product_code,hsn_code,SRNO,memo_id
					  ,subtotal	
					  ,ROW_ID
					  ,final_margin_pct
					  ,grandtotal
					  ,CM_NO 
					  ,sor_terms_code
					  ,cmd_row_id
					  ,CM_DT
					  ,QUANTITY
					  ,cmm_discount_amount
					  ,MRP_VALUE
					  ,taxable_value
					  ,output_gst
					  ,DISCOUNT_AMOUNT,bill_discount_amount
					  ,skip_bill_discount_amount
					  ,card_discount_amount
					  ,EOSS_SHARING_DISCOUNT_AMOUNT
					  ,weighted_avg_disc_amt
					  ,weighted_discount_percentage
					  ,ITEM_NET,BASIC_DISCOUNT_AMOUNT
					  ,sor_terms_DESC
					  ,gm_per
					  ,NET_PAYABLE
					  ,PUR_VALUE
					  ,input_gst
					  ,discount_percentage
					  ,eoss_scheme_name
					  ,claimed_base_value
					  ,claimed_base_gm_value
					  ,gst_diff
					  ,tax_method,supplier_ac_code,party_ac_code
					  ,party_state_code,customer_Code
					  ,scheme_discount',
				 @cCols=N''''+@NsPiD+''' sp_id,cmd.product_code,cmd.hsn_code,0 AS SRNO,
					  '+(CASE WHEN @cCurMemoId='' THEN '''later''' ELSE ''''+@cCurMemoId+'''' END)+' memo_id
					  ,0 as subtotal	
					  ,''LATER'' AS ROW_ID
					  ,0 final_margin_pct
					  ,0 grandtotal
					  ,CMM.CM_NO 
					  ,cmd.sor_terms_code
					  ,cmd.row_id as cmd_row_id
					  ,CM_DT
					  ,CMD.QUANTITY
					  ,cmm_discount_amount
					  ,(CMD.MRP*CMD.QUANTITY) AS MRP_VALUE
					  ,xn_value_without_gst as taxable_value
					  ,(cgst_amount+sgst_amount+igst_amount) as output_gst
					  ,(CMD.BASIC_DISCOUNT_AMOUNT+ISNULL(cmm_discount_amount,0)) 
					    AS DISCOUNT_AMOUNT,
						ISNULL(cmm_discount_amount,0) as bill_discount_amount,
						0 as skip_bill_discount_amount,
						cmd.card_discount_amount
						---dtm_type : 1. Do not consider 2. Consider for Sharing
					  ,(CMD.BASIC_DISCOUNT_AMOUNT+ISNULL(cmm_discount_amount,0))
					    AS EOSS_SHARING_DISCOUNT_AMOUNT
					  ,weighted_avg_disc_amt
					  ,weighted_avg_disc_pct
					  ,cmd.rfnet AS ITEM_NET,CMD.BASIC_DISCOUNT_AMOUNT
					  ,(CASE WHEN ISNULL(st.sor_terms_code,'''')='''' THEN ''NRV'' ELSE st.sor_terms_name END) AS sor_terms_DESC
					  ,0 as gm_per
					  ,0 AS NET_PAYABLE
					  ,(Sn.lc*cmd.quantity) AS PUR_VALUE
					  ,0 AS input_gst
					  ,cmd.discount_percentage
					  ,cmd.scheme_name as eoss_scheme_name
					  ,0 AS claimed_base_value
					  ,0 AS claimed_base_gm_value
					  ,0 AS gst_diff
					  ,tax_method,sn.ac_code AS supplier_ac_code,cmm.ac_code as party_ac_code
					  ,party_state_code,customer_Code
					  ,scheme_discount'
	END	

	SET @cStep='35.4'

	DECLARE @cSpIdStr varchar(100)
	set @cSpIdStr=''''+@NsPiD+''' sp_id,'

	SET @cColsGrp=REPLACE(@cCols,'as  sor_terms_code','')
	SET @cColsGrp=REPLACE(@cColsGrp,'AS sor_terms_DESC','')
	SET @cColsGrp=REPLACE(@cColsGrp,'AS scheme_name','')
	SET @cColsGrp=REPLACE(@cColsGrp,@cSpIdstr,'')

	--set @CFILTER=' cmm.cm_no=''0202-0010020'' and sn.product_code=''2003277409@HO595753'''

	SET @cStep='37.2'
	SET @CCMD=N'INSERT sor_pay_upload ('+@cInsCols+')
				select '+@cCOls+' FROM CMD01106 CMD (NOLOCK)
				JOIN CMM01106 CMM (NOLOCK) ON CMD.CM_ID=CMM.CM_ID
				JOIN SKU_names sn (NOLOCK)  ON CMD.PRODUCT_CODE=Sn.PRODUCT_CODE
				JOIN SKU (NOLOCK)  ON CMD.PRODUCT_CODE=Sku.PRODUCT_CODE
				JOIN dtm (NOLOCK) ON dtm.dt_code=cmm.dt_code
				LEFT JOIN sor_terms_mst st (NOLOCK) ON st.sor_terms_code=cmd.sor_terms_code
				LEFT JOIN 
				(
				SELECT DISTINCT D.CM_NO eoss_cm_no,D.CM_DT eoss_cm_dt ,product_code
				FROM EOSSSORD D (NOLOCK)
				JOIN EOSSSORM M (NOLOCK) ON D.MEMO_ID=M.MEMO_ID 
				JOIN cmm01106 c (NOLOCK) on c.CM_NO=d.CM_NO and c.CM_DT=d.CM_DT
				WHERE c.CM_DT BETWEEN '''+CONVERT(VARCHAR,@DFROMDT,110)+''' AND '''+CONVERT(VARCHAR,@DTODT,110)+'''
				AND M.CANCELLED=0 AND m.memo_id<>'''+@cCurMemoId+'''
				)EOSS ON CMM.cm_no=EOSS.eoss_CM_no and cmm.cm_dt=eoss.eoss_cm_dt AND eoss.PRODUCT_CODE=cmd.PRODUCT_CODE
				'+@cJoinStr+' 					
				WHERE CMM.CANCELLED=0 AND EOSS.eoss_CM_no IS NULL 
				AND  CMM.CM_DT BETWEEN '''+CONVERT(VARCHAR,@DFROMDT,110)+''' AND '''+CONVERT(VARCHAR,@DTODT,110)+''''
				+(CASE WHEN ISNULL(@CFILTER,'')='' THEN '' ELSE ' AND '+@CFILTER END)
				+(CASE WHEN @bGetSchemesData=1 THEN ' GROUP BY '+@cColsGrp ELSE '' END)

	PRINT @CCMD
	 
	EXEC SP_EXECUTESQL @CCMD
	


	IF @bGetSchemesData=1
	BEGIN
		SET @cStep='42'
		DELETE a FROM sor_pay_upload a WITH (ROWLOCK) WHERE a.sp_id=@nSpId AND sor_terms_code<>
		(SELECT TOP 1 sor_terms_code from sor_pay_upload b (NOLOCK)
		 WHERE b.sp_id=a.sp_id AND b.slsdet_row_id=a.slsdet_row_id AND ISNULL(b.sor_terms_code,'')<>'')
		
		SET @cStep='45'			
		SELECT *,'' as errmsg FROM sor_pay_upload (NOLOCK) where sp_id=@nSpId ORDER BY scheme_name
		RETURN
	END
	
	
	SET @cStep='50'
	IF @cPickMinDiscforSisLoc<>'1'
	BEGIN
		UPDATE sor_pay_upload WITH (ROWLOCK) SET Gm_per=0,discount_percentage=round((EOSS_SHARING_DISCOUNT_AMOUNT/mrp_value)*100,2)
		WHERE sp_id=@nSpId
	END
	ELSE
	BEGIN
		
		UPDATE a WITH (ROWLOCK) SET Gm_per=0,discount_percentage=(CASE WHEN isnull(b.Excel_Import_weighted_avg_disc_pct,0)<=b.weighted_avg_disc_pct 
		THEN  b.Excel_Import_weighted_avg_disc_pct ELSE b.weighted_avg_disc_pct END)  ,
		mrp_value=(CASE WHEN isnull(b.Excel_Import_weighted_avg_disc_pct,0)<=b.weighted_avg_disc_pct THEN mrp_value ELSE b.sisloc_mrp*b.QUANTITY END),
		basic_discount_amount=(CASE WHEN isnull(b.Excel_Import_weighted_avg_disc_pct,0)<=b.weighted_avg_disc_pct THEN isnull(b.Excel_Import_weighted_avg_disc_amt,0)
									ELSE b.weighted_avg_disc_amt END),
		taxable_value=(CASE WHEN isnull(b.Excel_Import_weighted_avg_disc_pct,0)<=b.weighted_avg_disc_pct THEN taxable_value ELSE b.sisloc_taxable_value END),
		DISCOUNT_AMOUNT=(CASE WHEN isnull(b.Excel_Import_weighted_avg_disc_pct,0)<=b.weighted_avg_disc_pct THEN isnull(b.Excel_Import_weighted_avg_disc_amt,0)
									ELSE b.weighted_avg_disc_amt END)
		FROM sor_pay_upload a JOIN cmd01106 b ON a.cmd_row_id=b.ROW_ID
		WHERE sp_id=@nSpId


	END

	DECLARE @tTerms TABLE  (ac_code char(10),eoss_term_id varchar(20),filter_criteria VARCHAR(MAX),calc_gst_rate_diff_fcndn BIT)
	
	
	DECLARE @cTermsId VARCHAR(20),@cAcCode CHAR(10),@cPartyFilter VARCHAR(50)
	SET @cStep='55'
	set @cJoinStr=''

	IF @CEOSSTERMSID=''
	BEGIN

		INSERT @tTerms (eoss_term_id,ac_code,filter_criteria,calc_gst_rate_diff_fcndn)
		SELECT  ID,a.ac_code,a_filter,calc_gst_rate_diff_fcndn from TBL_EOSS_DISC_SHARE_MST a (NOLOCK)
		WHERE a.ac_code IN (SELECT DISTINCT supplier_ac_code FROM sor_pay_upload (NOLOCK) 
						    WHERE sp_id=@nSpId)
		union
		SELECT  DISTINCT '' as ID,a.supplier_ac_code,'' as a_filter,0 calc_gst_rate_diff_fcndn from sor_pay_upload a (NOLOCK)
		left outer join TBL_EOSS_DISC_SHARE_MST	b (NOLOCK) ON a.supplier_ac_code=b.ac_code
		where a.sp_id=@nSpId AND b.ac_code is null
	
		SET @cJoinStr=' JOIN sku_names sn(nolock) ON sn.product_code=a.product_code'	
	END
	ELSE
		INSERT @tTerms (ac_code,eoss_term_id,filter_criteria,calc_gst_rate_diff_fcndn)
		SELECT @CAC_CODE,@CEOSSTERMSID,@CFILTER,calc_gst_rate_diff_fcndn
		FROM TBL_EOSS_DISC_SHARE_MST (NOLOCK) WHERE id=@CEOSSTERMSID


	IF @cCurMemoId NOT IN ('','LATER')
	BEGIN
		SET @cStep='55.7'
		UPDATE a WITH (ROWLOCK) SET 
		sor_terms_code=b.sor_terms_code FROM sor_pay_upload a
		JOIN eosssord b (NOLOCK) ON a.cmd_row_id=b.cmd_row_id
		WHERE b.memo_id=@cCurMemoId AND a.sp_id=@nSpId AND ISNULL(a.sor_terms_code,'') IN ('','000')
	END
	ELSE
	BEGIN
		SET @cStep='55.9'
		UPDATE a SET sor_terms_code=b.fresh_sale_sor_terms_code,sor_terms_DESC=c.sor_terms_name from sor_pay_upload a 
		JOIN TBL_EOSS_DISC_SHARE_MST B ON 1=1
		JOIN sor_terms_mst c ON c.sor_terms_code=b.fresh_sale_sor_terms_code
		where a.sp_id=@nSpId AND b.id=@CEOSSTERMSID AND ISNULL(a.eoss_scheme_name,'')=''
	END

 	WHILE EXISTS (SELECT top 1 * from @tTerms)
	BEGIN
		SET @cStep='57'
		IF @CEOSSTERMSID=''
		BEGIN
			SELECT TOP 1 @cTermsId=ltrim(rtrim(eoss_term_id)),@cAcCode=ac_code,@cFilter=filter_criteria
			FROM @tTerms ORDER BY eoss_term_id

			SET @cFilter = @cFilter+ (CASE WHEN @CFILTER<>'' THEN  ' AND ' ELSE '' END)+'  a.ac_code='''+ltrim(rtrim(@cAcCode))+''''

		END
		ELSE
			SELECT @cFilter=' 1=1 ', @cTermsId=ltrim(rtrim(@CEOSSTERMSID)),@cAcCode=''
			FROM  @tTerms

--		taxable:	taxable value+card discount+cmm discount if not consider
--nrv:	nrv+card discount+cmm discount if not consider
--mrp:	mrp
	   SET @cStep='57.5'
	   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET 
	    calc_gst_rate_diff_fcndn=ISNULL(b.calc_gst_rate_diff_fcndn,0) FROM sor_pay_upload a
	   JOIN
		(SELECT calc_gst_rate_diff_fcndn FROM TBL_EOSS_DISC_SHARE_MST (NOLOCK)
		 WHERE ID='''+@CTERMSID+''') b ON 1=1 
		 WHERE sp_id='''+@nSpId+''' AND '+@cFilter
	   PRINT @cCmd	
	   EXEC SP_EXECUTESQL @cCmd


	   SET @cStep='57.9'	
	   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET 
	   gm_per=ISNULL(EOSS_TERMS.gm_per,0) FROM sor_pay_upload a
	   LEFT OUTER JOIN 
		(SELECT base,DISCFROM,DISCTO,SUPP_SHARE_PER as gm_per FROM TBL_EOSS_DISC_SHARE_DET (NOLOCK)
		 WHERE ID='''+@CTERMSID+''') EOSS_TERMS ON 1=1 
		WHERE sp_id='''+@nSpId+''' AND '+@cFilter+' AND  
		((sor_terms_code IN (''NRV'',''TAX'') AND ISNULL(weighted_discount_percentage,0) BETWEEN isnull(EOSS_TERMS.DISCFROM,0)
		  AND isnull(EOSS_TERMS.DISCTO,100)) OR
		(sor_terms_code NOT IN (''NRV'',''TAX'') AND isnull(EOSS_TERMS.DISCFROM,0)=0 AND isnull(EOSS_TERMS.DISCTO,100)=0)
		)'	 
	   PRINT @cCmd	
	   EXEC SP_EXECUTESQL @cCmd


		DELETE FROM @tTerms WHERE eoss_term_id=@cTermsId
	END

	SET @cStep='59'	
	IF @cRetainExcelNrv<>'1'
		UPDATE sor_pay_upload WITH (ROWLOCK) SET item_net=mrp_value-(CASE WHEN ISNULL(weighted_avg_disc_amt,0)=0 THEN basic_discount_amount ELSE weighted_avg_disc_amt END)-bill_discount_amount
		WHERE sp_id=@nSpId
	ELSE --- Done for Cantabil (Date:19-12-2024 Taigat task#1006)
		UPDATE a WITH (ROWLOCK) SET item_net=mrp_value-(CASE WHEN ISNULL(b.Excel_Import_weighted_avg_disc_amt ,0)=0 THEN a.basic_discount_amount 
		ELSE Excel_Import_weighted_avg_disc_amt END) FROM sor_pay_upload a 
		JOIN cmd01106 b (NOLOCK) ON b.ROW_ID=a.ROW_ID
		WHERE sp_id=@nSpId
  
	
    --select 'check taxable value',xn_value_without_gst,sor_terms_code,basic_discount_amount,scheme_discount,weighted_avg_disc_amt,taxable_value,* from  sor_pay_164

	SET @cStep='60.2'

	IF EXISTS (SELECT TOP 1 hsn_code FROM gst_taxinfo_calc (NOLOCK) WHERE sp_id=@NSPID)
		DELETE FROM gst_taxinfo_calc WITH (ROWLOCK) where sp_id=@nSpid

		
	SET @cStep='64.5'
	UPDATE sor_pay_upload WITH (ROWLOCK) SET 
	claimed_base_value=(case when sor_terms_code IN ('TAX') THEN taxable_value 
						     WHEN sor_terms_code IN ('NRV') THEN item_net
							 ELSE mrp_value END)
	WHERE sp_id=@nSpId	
	
	SET @cStep='70'
	
	---- Restored code for recalculation of Gst after ZOOM meeting of Sir,Pankaj with Suvidha for SOR on 04-08-2020 
  
	INSERT GST_TAXINFO_CALC	( PRODUCT_CODE, SP_ID ,NET_VALUE,TAX_METHOD,ROW_ID,QUANTITY,
	LOC_STATE_CODE ,LOC_GSTN_NO,LOCREGISTERED,PARTY_STATE_CODE ,PARTY_GSTN_NO,PARTYREGISTERED,LOCALBILL,MEMO_DT,MRP,SOURCE_DEPT_ID )  
    SELECT a.PRODUCT_CODE,@NSPID AS SP_ID,
	(CASE WHEN sor_terms_code='TAX' THEN item_net ELSE claimed_base_value END) AS NET_VALUE,
	(case when a.TAX_METHOD=2 then 1 else 2 end) tax_method,a.cmd_ROW_ID,a.QUANTITY,SLOC.GST_STATE_CODE AS LOC_STATE_CODE,SLOC.LOC_GST_NO AS LOC_GSTN_NO,
	SLOC.REGISTERED_GST AS LOCREGISTERED,a.PARTY_STATE_CODE,
	(CASE WHEN ISNULL(A.party_AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.AC_GST_NO ELSE '' END) AS 	PARTY_GSTN_NO,
	(CASE WHEN ISNULL(a.party_AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.REGISTERED_GST_DEALER ELSE 0 END) AS PARTYREGISTERED,
	(CASE WHEN a.CUSTOMER_CODE IN ('','000000000000') AND ISNULL(a.party_AC_CODE,'0000000000')  IN ('','0000000000')
			THEN 1 ELSE 0 END) AS LOCALBILL ,
		a.CM_DT	as CM_DT,b.MRP,cmm.location_code  FROM
	sor_pay_upload A (NOLOCK)
	JOIN sku b (NOLOCK) ON a.product_code=b.product_code
	JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_no=a.cm_no and cmm.cm_dt=a.cm_dt
	left outer join lmP01106 lm (NOLOCK) ON lm.ac_code=a.party_ac_code	
	LEFT OUTER JOIN location sloc (NOLOCK) ON sloc.dept_id=CMM.location_code 
	WHERE sp_id=@nSpId AND sor_terms_code<>'MRP'  ---- Now gst will always be recalculated for items with  because we are calculating item_net on the fly for handling weighted avg discount case of buy n get n schemes
							--(Discussed wit Pankaj and sir for Jay shoes : Date(22-12-2023
   
   SET @cStep='75'
	IF EXISTS (SELECT TOP 1 product_Code FROM GST_TAXINFO_CALC (NOLOCK) WHERE sp_id=@NSPID)
	BEGIN	
		print 'enter recalculate output gst'
					   
   		SET @cStep='80'
		EXEC SP3S_GST_TAX_CAL_BATCH
		@CXN_TYPE='SLS',
		@NSPID=@nSpId,
		@cLoginDeptId=@cLoginDeptId,
		@CERRMSG=@CERRORMSG OUTPUT

		SET @cStep='82'	   
		UPDATE a WITH (ROWLOCK) SET output_gst=b.cgst_amount+b.sgst_amount+b.igst_amount,
		taxable_value=b.xn_value_without_gst
		FROM sor_pay_upload A
		JOIN GST_TAXINFO_CALC b (NOLOCK) ON a.sp_id=b.sp_id AND a.cmd_row_id=b.row_id
		WHERE b.sp_id=@nSpId
	   
		UPDATE sor_pay_upload WITH (ROWLOCK) SET claimed_base_value=taxable_value 
		WHERE sp_id=@nSpId	AND sor_terms_code IN ('TAX')

	   SET @cStep='85'
	   DELETE FROM GST_TAXINFO_CALC with (rowLOCK) WHERE sp_id=@NSPID
	END


	IF @bCalledFromDashBoard=1
	BEGIN
		SET @cStep='87'	   
		DELETE FROM sor_pay_upload WITH (ROWLOCK) WHERE sp_id=@nSpId AND gm_per=0
	END

	SET @cStep='89'
   DECLARE @nLoopcNT int,@cDbName varchar(200),@bFound BIT,@cFinYear VARCHAR(10),@bExit BIT	
   
   SET @nLoopcNT=1
   SET @cFinYear='01'+DBO.fn_getfinyear(getdate())
   
   SET @cDbName=DB_NAME()
   
   SET @bFound=1
   WHILE @bFound=1
   BEGIN

      
		SET @cStep='92'
		SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET purchase_price=isnull(round(b.xn_value_without_gst/invoice_quantity,2),0),
		row_id=CONVERT(VARCHAR(36),NEWID()),
		input_gst=isnull(ROUND((b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2)*a.quantity,0),
		PURCHASE_BILL_NO=b.INV_NO , PURCHASE_BILL_DT=b.INV_dt,
		rate_diff_gst_percentage=b.gst_percentage
		FROM sor_pay_upload a
		JOIN 
		(
		select  LEFT(b.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',b.PRODUCT_CODE)-1,-1),LEN(b.PRODUCT_CODE ))) as Product_code,
			        b.xn_value_without_gst,invoice_quantity,b.cgst_amount,b.sgst_amount,b.igst_amount,C.INV_NO ,C.INV_dt,b.gst_percentage   ,
		            sr=ROW_NUMBER() over (partition by LEFT(b.PRODUCT_CODE,ISNULL(NULLIF(CHARINDEX (''@'',b.PRODUCT_CODE)-1,-1),LEN(b.PRODUCT_CODE ))) 
		        Order by inv_dt desc)
			from '+@cDbName+'.dbo.ind01106 b (NOLOCK)  
			JOIN '+@cDbName+'.dbo.inm01106 c (NOLOCK) ON c.inv_id=b.inv_id
			where inv_dt<='''+convert(varchar,@dToDt,112)+''' AND inv_mode=2 AND party_dept_id='''+@cLocId+''' AND c.cancelled=0
		union
		select  b.PRODUCT_CODE,
			        b.xn_value_without_gst,invoice_quantity,b.cgst_amount,b.sgst_amount,b.igst_amount,C.INV_NO ,C.INV_dt,b.gst_percentage   ,
		            sr=ROW_NUMBER() over (partition by  b.product_code
					 		        Order by inv_dt desc)
			from '+@cDbName+'.dbo.ind01106 b (NOLOCK)  
			JOIN '+@cDbName+'.dbo.inm01106 c (NOLOCK) ON c.inv_id=b.inv_id
			where inv_dt<='''+convert(varchar,@dToDt,112)+''' AND inv_mode=2 AND party_dept_id='''+@cLocId+''' AND c.cancelled=0

		) b on a.PRODUCT_CODE=b.product_code and b.sr=1
		WHERE sp_id='''+@nSpId+''' 	AND a.row_id=''LATER'' '
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd		  
			
		IF EXISTS (SELECT TOP 1  inv_id FROM  inm01106 a (NOLOCK) JOIN  location b (NOLOCK) ON a.ac_code=b.dept_ac_code
					WHERE b.dept_id=@cLocId AND A.INV_MODE=1 and  a.cancelled=0)
		BEGIN
			SET @cStep='92.5'
			SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET purchase_price=isnull(round(b.xn_value_without_gst/invoice_quantity,2),0),
			row_id=CONVERT(VARCHAR(36),NEWID()),
			input_gst=isnull(ROUND((b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2)*a.quantity,0),
			PURCHASE_BILL_NO=b.INV_NO , PURCHASE_BILL_DT=b.INV_dt,
			rate_diff_gst_percentage=b.gst_percentage
			FROM sor_pay_upload a
			JOIN 
			(
			select  LEFT(b.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',b.PRODUCT_CODE)-1,-1),LEN(b.PRODUCT_CODE ))) as Product_code,
			        b.xn_value_without_gst,invoice_quantity,b.cgst_amount,b.sgst_amount,b.igst_amount,C.INV_NO ,C.INV_dt,b.gst_percentage   ,
		            sr=ROW_NUMBER() over (partition by LEFT(b.PRODUCT_CODE,ISNULL(NULLIF(CHARINDEX (''@'',b.PRODUCT_CODE)-1,-1),LEN(b.PRODUCT_CODE ))) 
		        Order by inv_dt desc)
				from '+@cDbName+'.dbo.ind01106 b (NOLOCK) 
				JOIN '+@cDbName+'.dbo.inm01106 c (NOLOCK) ON c.inv_id=b.inv_id
				JOIN  location D (NOLOCK) ON c.ac_code=d.dept_ac_code
				where inv_dt<='''+convert(varchar,@dToDt,112)+''' AND inv_mode=1
				AND c.cancelled=0 AND d.dept_id='''+@cLocId+'''
				union
			select  b.PRODUCT_CODE,
			        b.xn_value_without_gst,invoice_quantity,b.cgst_amount,b.sgst_amount,b.igst_amount,C.INV_NO ,C.INV_dt,b.gst_percentage   ,
		            sr=ROW_NUMBER() over (partition by b.PRODUCT_CODE
		        Order by inv_dt desc)
				from '+@cDbName+'.dbo.ind01106 b (NOLOCK) 
				JOIN '+@cDbName+'.dbo.inm01106 c (NOLOCK) ON c.inv_id=b.inv_id
				JOIN  location D (NOLOCK) ON c.ac_code=d.dept_ac_code
				where inv_dt<='''+convert(varchar,@dToDt,112)+''' AND inv_mode=1
				AND c.cancelled=0 AND d.dept_id='''+@cLocId+'''
			) b on a.PRODUCT_CODE=b.product_code and b.sr=1
				
			WHERE sp_id='''+@nSpId+''' AND a.row_id=''LATER''
			'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd		     
		END
	    
		--- DOne this change for Jayshoes after discussion of Pankaj with Sir that Purchase price should be recalculated based upon mrp based marging
		--- only for those barcodes whose last challan in details is not available (Date:03-01-2024)
	   IF @bConsiderPPMDFromMrp=1 AND EXISTS (SELECT TOP 1 product_code FROM sor_pay_upload (NOLOCK) WHERE sp_id=@nSpId
												AND isnull(purchase_price,0)=0)
	   BEGIN
			--select @nMarkDownPct
	   		SET @cStep='92.8'
			UPDATE sor_pay_upload WITH (ROWLOCK) SET purchase_price=isnull(round(((mrp_value/quantity)-(mrp_value/quantity)*
			@nMarkDownPct/100),2),0),
			row_id=CONVERT(VARCHAR(36),NEWID()),ppfoundBlank=1
			WHERE sp_id=@nSpId AND isnull(purchase_price,0)=0
			
			SET @cStep='93.2'
			IF EXISTS (SELECT TOP 1 SP_ID FROM gst_xns_hsn (NOLOCK) WHERE sp_id=@NSPID)
				DELETE FROM gst_xns_hsn WITH (ROWLOCK) WHERE sp_id=@nSpId
			
			SET @cStep='93.5'

			;WITH CTE AS
			(
			SELECT a.sp_id,A.ROW_ID,B.HSN_CODE, c.tax_percentage,ISNULL(C.RATE_CUTOFF,0) AS RATE_CUTOFF,
					ISNULL(C.RATE_CUTOFF_TAX_PERCENTAGE,0) AS RATE_CUTOFF_TAX_PERCENTAGE,
					ISNULL(C.WEF,'') AS WEF,ISNULL(B.TAXABLE_ITEM,'') AS TAXABLE_ITEM,ISNULL(B.HSN_TYPE ,'') AS HSN_TYPE  ,
					SR=ROW_NUMBER() OVER (PARTITION BY A.ROW_ID ORDER BY C.WEF DESC),
					ISNULL(C.GST_CAL_BASIS,1) AS GST_CAL_BASIS,
					isnull(c.Rate_CutOff_Gst_Cess_Percentage,0) as Rate_CutOff_Gst_Cess_Percentage,
					isnull(c.Gst_Cess_Percentage,0) as Gst_Cess_Percentage
			FROM sor_pay_upload A (NOLOCK)
			JOIN HSN_MST B (NOLOCK) ON A.HSN_CODE =B.HSN_CODE 
			LEFT JOIN HSN_DET C (NOLOCK) ON B.HSN_CODE =C.HSN_CODE AND C.WEF  <=a.cm_DT AND ISNULL(C.DEPT_ID,'')=''
			WHERE A.SP_ID =LTRIM(RTRIM((@NSPID))) AND ppfoundBlank=1  
			)
			
			insert gst_xns_hsn (SP_ID,ROW_ID,HSN_CODE,TAX_PERCENTAGE,RATE_CUTOFF,
			RATE_CUTOFF_TAX_PERCENTAGE,WEF,TAXABLE_ITEM,HSN_TYPE,SR,GST_CAL_BASIS,Rate_CutOff_Gst_Cess_Percentage,Gst_Cess_Percentage)
			SELECT SP_ID,ROW_ID,HSN_CODE,TAX_PERCENTAGE,RATE_CUTOFF,
			RATE_CUTOFF_TAX_PERCENTAGE,WEF,TAXABLE_ITEM,HSN_TYPE,SR,GST_CAL_BASIS,
			Rate_CutOff_Gst_Cess_Percentage,Gst_Cess_Percentage
			FROM CTE WHERE SR=1

			SET @cStep='93.80'
			UPDATE a WITH (ROWLOCK) SET rate_diff_gst_percentage=(CASE WHEN purchase_price<=hm.RATE_CUTOFF
			THEN RATE_CUTOFF_TAX_PERCENTAGE ELSE TAX_PERCENTAGE END)
			FROM sor_pay_upload a 
			JOIN gst_xns_hsn HM (NOLOCK) ON hm.sp_id=a.sp_id and HM.HSN_CODE=a.HSN_CODE
			where A.SP_ID=@NsPID AND ppfoundBlank=1


			SET @cStep='93.85'
			UPDATE a WITH (ROWLOCK)
			SET input_gst=(purchase_price*quantity)*ISNULL(a.rate_diff_gst_percentage,0)/
			(100 + (CASE WHEN @nInputGstCalMethod=2 THEN ISNULL(a.rate_diff_gst_percentage,0) ELSE 0 END))
			FROM sor_pay_upload a 
			WHERE a.sp_id=@nSpId AND ppfoundBlank=1


       END

	   SET @cStep='94.2'
	   IF NOT EXISTS (SELECT TOP 1 * from sor_pay_upload (NOLOCK) WHERE sp_id=@nSpId AND ROW_ID='LATER')
			SET @bExit=1
	   

	   SET @cStep='96'
	   IF NOT EXISTS (SELECT TOP 1 * from sor_pay_upload (NOLOCK) WHERE sp_id=@nSpId AND ROW_ID='LATER')
			SET @bExit=1

	  
   lblStart:
	   SET @cStep='100'	
	   SET @nLoopcNT=@nLoopcNT+1
	   SET @cFinYear='01'+DBO.fn_getfinyear(DATEADD(DD,-365*@nLoopCnt,getdate()))
	   
	   IF ISNULL(@bExit,0)=1 OR @nLoopcNT>10
			BREAK

	  	SET @cStep='102'
	   SET @cDbName=DB_NAME()+'_'+@cFinYear
	   
 	   IF DB_ID(@cDbName) IS  NULL		
			GOTO lblStart
   END
	
			    		
   SET @cStep='107'	 
   UPDATE a WITH (ROWLOCK) SET claimed_base_gm_value=(claimed_base_value*gm_per/100),
				gst_diff=(input_gst-output_gst),
				PUR_VALUE=a.purchase_price*quantity ,
				eoss_scheme_name=(CASE WHEN ISNULL(eoss_scheme_name,'')='' 
				THEN (CASE WHEN discount_amount=0
				THEN 'FRESH' ELSE 'DISCOUNTED' END) ELSE eoss_scheme_name END) 
	FROM sor_pay_upload a 
	JOIN sku_names b (NOLOCK) ON a.product_code=b.product_code
	WHERE sp_id=@nSpId

	SET @cStep='110'	 
	UPDATE sor_pay_upload WITH (ROWLOCK) SET company_share=item_net-claimed_base_gm_value,
	company_share_with_outputgst=item_net-claimed_base_gm_value+output_gst,
	NET_PAYABLE=item_net-claimed_base_gm_value+
	(CASE WHEN sor_terms_code IN ('TAX') AND @cDonotConsiderGstDiffNpCalc='1' THEN 0 ELSE gst_diff END)	

	----Discarded below formula after confirmation by Pankaj and Sir agst. Ticket#06-0094(Date:01-06-2022)
	--company_share=claimed_base_value-claimed_base_gm_value,
	--company_share_with_outputgst=claimed_base_value-claimed_base_gm_value+output_gst,
	--NET_PAYABLE=claimed_base_value-claimed_base_gm_value+
	--(CASE WHEN sor_terms_code IN ('TAX') THEN 0 ELSE gst_diff END)
	WHERE sp_id=@nSpId

	IF @bCalledFromMulti=0
	BEGIN
		SET @cStep='115'
		INSERT sor_pay_upload (sp_id,product_code,subtotal,eoss_scheme_name,CM_NO,CM_DT,QUANTITY,
		mrp_value,PUR_VALUE,
		taxable_value,output_gst,DISCOUNT_AMOUNT,iTEM_NET,NET_PAYABLE,input_gst,claimed_base_value,
		EOSS_SHARING_DISCOUNT_AMOUNT,sor_terms_desc,purchase_bill_no,purchase_bill_dt,discount_percentage,
		scheme_discount_percentage,tax_method,party_ac_code,party_state_code,customer_code,
		weighted_avg_disc_amt,cmd_row_id,weighted_discount_percentage)
		SELECT sp_id,'' product_code,1 as subtotal,eoss_scheme_name+' Total ' EOSS_SCHEME_NAME,
		'' AS CM_NO,'' AS CM_DT,
		sum(QUANTITY) as quantity,sum(MRP_VALUE) as mrp_value,sum(pur_value) as pur_value,
		sum(taxable_value) as taxable_value,sum(output_gst) as output_gst,
		sum(DISCOUNT_AMOUNT) as discount_amount,sum(iTEM_NET) as item_net,sum(NET_PAYABLE) as net_payable,
		sum(input_gst) as input_gst,sum(claimed_base_value) as claimed_base_value,
		0 EOSS_SHARING_DISCOUNT_AMOUNT,'' sor_terms_desc,'' purchase_bill_no,'' purchase_bill_dt,
		0 discount_percentage,0 scheme_discount_percentage,0 tax_method,
		'' party_ac_code,'' party_state_code,'' customer_code,
		sum(weighted_avg_disc_amt) weighted_avg_disc_amt,
		'' cmd_row_id,0 weighted_discount_percentage
		FROM sor_pay_upload (NOLOCK) WHERE sp_id=@nSpId
		GROUP BY sp_id,eoss_scheme_name

	END
				
END TRY	

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_PENDING_EOSS_SOR_LOC at Step# '+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	

	IF @bCalledFromDashBoard=0 
	BEGIN
		IF @bUpdateSchemesData=1 
		BEGIN
			IF @@TRANCOUNT>0
			BEGIN
				if isnull(@cErrormsg,'')<>'' 
					ROLLBACK
				ELSE
					COMMIT
			END
			select @cErrormsg  as errmsg
		END
		ELSE
		if isnull(@cErrormsg,'')<>'' 
			select @cErrormsg  as errmsg
		else
		begin
			--DIscarded this formula as per discussion done today for Chique SOR (Sir,Ved & Pankaj) -- Date :30-05-2022
			--UPDATE sor_pay_upload with (rowlock) SET rate_diff=ROUND((purchase_price*quantity)-net_payable,2)+
			--(CASE WHEN @cAddInputGstRateDiff='1' THEN ISNULL(input_gst,0) ELSE 0 END) ,
			--rate_diff_gst_percentage=(CASE WHEN calc_gst_rate_diff_fcndn=0 THEN 0 ELSE rate_diff_gst_percentage END)
			--WHERE sp_id=@nSpid

			--DIscarded again this formula as per discussion done between Pankaj and Sir (for Norspin) and mail sent dated : 08-06-2022 
			--UPDATE sor_pay_upload with (rowlock) SET rate_diff=ROUND((purchase_price*quantity)-taxable_value,2),
			--rate_diff_gst_percentage=(CASE WHEN calc_gst_rate_diff_fcndn=0 THEN 0 ELSE rate_diff_gst_percentage END)
			--WHERE sp_id=@nSpid

			UPDATE sor_pay_upload with (rowlock) SET rate_diff=ROUND((purchase_price*quantity)-net_payable+ISNULL(input_gst,0),2),
			rate_diff_gst_percentage=(CASE WHEN calc_gst_rate_diff_fcndn=0 THEN 0 ELSE rate_diff_gst_percentage END)
			WHERE sp_id=@nSpid

			IF @bCalledFromMulti=0
			BEGIN
				SELECT  purchase_price as chk_pp,a.*,sn.*,'' as errmsg,mrp_value mrp
				FROM sor_pay_upload a (NOLOCK)
				JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.product_code
				where sp_id=@nSpId AND isnull(grandtotal,0)=0 
				order by eoss_scheme_name,subtotal,cm_dt,cm_no
			END
			
			--select 'check final data'
			SELECT purchase_price as chk_pp,  *,'' as errmsg,Convert(varchar(10),a.cm_dt,105) as display_cm_dt,mrp_value mrp,
			cmm.location_code  [LOC ID],b.dept_alias [LOC ALIAS],CITY,section_name [Section] ,
			sub_section_name [SubSection],article_no [Article],article_alias [article alias],
			Convert(varchar(10),a.PURCHASE_BILL_DT,105) as display_PURCHASE_BILL_DT
			FROM sor_pay_upload a (NOLOCK)  
			JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_no=a.cm_no and cmm.cm_dt=a.cm_dt
			JOIN location b (NOLOCK) ON b.dept_id=cmm.location_code 
			JOIN sku_names sn (nolock) on sn.product_Code=a.product_code
			JOIN  area (NOLOCK) ON area.area_code=b.area_code
			JOIN city (NOLOCK) ON city.city_code=area.city_code
			where sp_id=@nSpId AND isnull(a.subtotal,0)=0 and  isnull(grandtotal,0)=0

			SELECT  b.sor_terms_name sor_terms_desc,SUM(taxable_value) taxable_value,SUM(taxable_value+output_gst) NRV,
			(case when SUM(taxable_value)<>0 THEN  convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value))*100 ,2)) else 0 end) margin_pct_taxable,gm_per,sum(claimed_base_value) claimed_base_value,
			SUM(claimed_base_gm_value) claimed_base_gm_value,SUM(output_gst) output_gst,
			SUM(input_gst) input_gst,SUM(input_gst-output_gst) net_gst,SUM(net_payable) net_payable,
			(case when SUM(taxable_value+output_gst)<>0 THEN  convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value+output_gst))*100,2)) else 0 end) final_margin_pct,1 as disp_order,
			sum(isnull(rate_diff,0)) rate_diff,SUM(isnull(rate_diff_gst_amount,0)) rate_diff_gst_amount
			FROM sor_pay_upload a (NOLOCK)
			JOIN sor_terms_mst b (NOLOCK) ON b.sor_terms_code=a.sor_terms_code
			where SP_ID=@nSpId AND isnull(subtotal,0)=0
			GROUP BY b.sor_terms_name,gm_per
						
			UNION ALL
			SELECT  'Totals:' AS sor_terms_DESC,SUM(taxable_value) taxable_value,SUM(taxable_value+output_gst) NRV,
			(case when SUM(taxable_value)<>0 THEN convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value))*100 ,2)) ELSE 0 END) margin_pct_taxable,
			0 gm_per,sum(claimed_base_value) claimed_base_value,
			SUM(claimed_base_gm_value) claimed_base_gm_value,SUM(output_gst) output_gst,
			SUM(input_gst) input_gst,SUM(input_gst-output_gst) net_gst,SUM(net_payable) net_payable,
			(case when SUM(taxable_value+output_gst)<>0 THEN  convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value+output_gst))*100,2)) else 0 end) final_margin_pct,2 as disp_order,
			sum(isnull(rate_diff,0)) rate_diff,SUM(isnull(rate_diff_gst_amount,0)) rate_diff_gst_amount
			FROM sor_pay_upload (NOLOCK) where SP_ID=@nSpId AND isnull(subtotal,0)=0
			ORDER BY disp_order,sor_terms_DESC
			
		end
	END
	ELSE
	BEGIN
		SET @cCmd=N'INSERT #tSor
		SELECT 	'''+@CTABLENAME+''' as tableName,'''+@cErrormsg+''' as errmsg'

		print @cCmd
		EXEC SP_EXECUTESQL @CCMD
	END

	IF EXISTS (SELECT TOP 1 sp_id  FROM SOR_PAY_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId) 
		DELETE FROM SOR_PAY_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId
	--select 'check tsor',* from #tsor
END
--END OF PROCEDURE - SP3S_PENDING_EOSS_SOR_LOC
