CREATE PROCEDURE SP3S_PENDING_EOSS_SOr
(
	 @DFROMDT DATETIME
	,@DTODT DATETIME
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
		   ,@cInsCols VARCHAR(MAX),@cCols NVARCHAR(MAX),@cColsGrp VARCHAR(1000),@cErrSchemeName VARCHAR(400)

BEGIN TRY
	SET @cEossTemrsIdPara=@CEOSSTERMSID

	SET @cErrormsg=''
	SET @cStep='10'
	SET @bCalledFromDashBoard=0
	
	
	SET @cJoinStr=''

	IF @nSpId=''
		SET @nSpId=CONVERT(VARCHAR(40),NEWID())

	IF @cCurMemoId<>'LATER'
		SELECT @bGetSchemesData=0,@DFROMDT=PERIOD_FROM,@dToDt=PERIOD_to,@CEOSSTERMSID=id,@CAC_CODE=ac_code 
		FROM eosssorm (NOLOCK) WHERE memo_id=@cCurMemoId

	IF @CEOSSTERMSID<>''
	BEGIN		
		SELECT TOP 1 @CFILTER=ISNULL(A_FILTER,'') FROM TBL_EOSS_DISC_SHARE_MST (NOLOCK) WHERE ID=@CEOSSTERMSID
	
		SET @cStep='20'
		set @CFILTER = (CASE WHEN  ISNULL(@CFILTER,'')='' THEN ' 1=1 ' ELSE @CFILTER END)

		SET @CFILTER=@CFILTER+(CASE WHEN @cLocId<>'' THEN ' AND Cmm.location_code ='''+@cLocId+'''' ELSE ' AND sku.ac_code='''+@CAC_CODE+'''' END)
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
	
	IF @bUpdateSchemesData=1
	BEGIN
		SET @cStep='27'
		
		IF EXISTS (SELECT TOP 1 sp_id FROM  SOR_PAY_UPLOAD a (NOLOCK) WHERE sp_id=@nSpId AND ISNULL(a.sor_terms_code,'') IN  ('','000'))
		BEGIN
			SELECT TOP 1 @cErrSchemeName=scheme_name FROM SOR_PAY_UPLOAD a (NOLOCK) WHERE sp_id=@nSpId AND ISNULL(a.sor_terms_code,'') IN  ('','000')
			SET @cErrormsg='Sor Terms code cannot be blank for Scheme :'+ISNULL(@cErrSchemeName,'')
			GOTO END_PROC
		END

		BEGIN TRAN
		
		SET @cStep='30'	

		UPDATE a SET sor_terms_code=c.sor_terms_code FROM cmd01106 a WITH (ROWLOCK)
		JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
		JOIN SOR_PAY_UPLOAD c (NOLOCK) ON c.scheme_name=a.scheme_name
		WHERE sp_id=@nSpId AND b.cm_dt BETWEEN @DFROMDT AND @DTODT
		AND ISNULL(a.sor_terms_code,'')<>ISNULL(c.sor_terms_code,'')


		SET @cStep='32'
		DELETE FROM SOR_PAY_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId

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
		SELECT @cInsCols='SP_ID,scheme_name,sor_terms_code,SOR_TERMS_DESC',
			   @cCols=N''''+@NsPiD+''' sp_id,scheme_name,isnull(cmd.sor_terms_code,''000''),
					isnull(st.sor_terms_name,'''')  AS sor_terms_DESC' 
		SET @CFILTER=@CFILTER+(CASE WHEN @CFILTER<>'' THEN ' AND ' ELSE '' END)+ ' isnull(cmd.scheme_name,'''')<>'''' '
	END
	ELSE
	BEGIN


		SELECT @cInsCols='sp_id,product_code,SRNO,memo_id
					  ,subtotal	
					  ,hsn_code,bill_remarks,dt_name
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
					  ,ITEM_NET,BASIC_DISCOUNT_AMOUNT
					  ,sor_terms_DESC
					  ,gm_per
					  ,NET_PAYABLE
					  ,PUR_VALUE
					  ,input_gst
					  ,discount_percentage
					  ,weighted_discount_percentage
					  ,eoss_scheme_name
					  ,claimed_base_value
					  ,claimed_base_gm_value
					  ,gst_diff
					  ,tax_method,supplier_ac_code,party_ac_code
					  ,party_state_code,customer_Code
					  ,scheme_discount',
				 @cCols=N''''+@NsPiD+''' sp_id,cmd.product_code,0 AS SRNO,
					  '+(CASE WHEN @cCurMemoId='' THEN '''later''' ELSE ''''+@cCurMemoId+'''' END)+' memo_id
					  ,0 as subtotal	
					  ,cmd.hsn_code,cmm.remarks,dtm.dt_name
					  ,''LATER'' AS ROW_ID
					  ,0 final_margin_pct
					  ,0 grandtotal
					  ,CMM.CM_NO 
					  ,isnull(cmd.sor_terms_code,''000'')
					  ,cmd.row_id as cmd_row_id
					  ,CM_DT
					  ,CMD.QUANTITY
					  ,cmm_discount_amount
					  ,(CMD.MRP*CMD.QUANTITY) AS MRP_VALUE
					  ,xn_value_without_gst as taxable_value
					  ,(cgst_amount+sgst_amount+igst_amount) as output_gst
					  ,(CMD.BASIC_DISCOUNT_AMOUNT+ISNULL(cmm_discount_amount,0)+cmd.card_discount_amount) 
					    AS DISCOUNT_AMOUNT,
						(CASE WHEN dtm_type=2 THEN ISNULL(cmm_discount_amount,0) ELSE 0 END) as bill_discount_amount,
						(CASE WHEN isnull(dtm_type,0)<>2 THEN ISNULL(cmm_discount_amount,0) ELSE 0 END) as skip_bill_discount_amount,
						cmd.card_discount_amount
						---dtm_type : 1. Do not consider 2. Consider for Sharing
					  ,(CMD.BASIC_DISCOUNT_AMOUNT+(CASE WHEN dtm_type=2 THEN ISNULL(cmm_discount_amount,0) ELSE 0 END))
					    AS EOSS_SHARING_DISCOUNT_AMOUNT
					  ,weighted_avg_disc_amt
					  ,cmd.rfnet AS ITEM_NET,CMD.BASIC_DISCOUNT_AMOUNT
					  ,(CASE WHEN ISNULL(st.sor_terms_code,'''')='''' THEN ''NRV and Discounted Margin'' ELSE st.sor_terms_name END) AS sor_terms_DESC
					  ,0 as gm_per
					  ,0 AS NET_PAYABLE
					  ,(Sn.lc*cmd.quantity) AS PUR_VALUE
					  ,0 AS input_gst
					  ,cmd.discount_percentage
					  ,cmd.discount_percentage as weighted_discount_percentage
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
		 WHERE b.sp_id=a.sp_id AND b.scheme_name=a.scheme_name AND ISNULL(b.sor_terms_code,'')<>'')
		
		SET @cStep='45'			
		SELECT *,'' as errmsg FROM sor_pay_upload (NOLOCK) where sp_id=@nSpId ORDER BY scheme_name
		RETURN
	END
		
	SET @cStep='50'
	UPDATE sor_pay_upload WITH (ROWLOCK) SET Gm_per=0,discount_percentage=round((EOSS_SHARING_DISCOUNT_AMOUNT/mrp_value)*100,2),
	weighted_discount_percentage=round(((case when isnull(weighted_avg_disc_amt,0)=0
	then basic_discount_amount else isnull(weighted_avg_disc_amt,0) END)/mrp_value)*100,2)
	WHERE sp_id=@nSpId
	
	DECLARE @tTerms TABLE  (ac_code char(10),eoss_term_id varchar(20),filter_criteria VARCHAR(MAX))
	
	
	DECLARE @cTermsId VARCHAR(20),@cAcCode CHAR(10),@cPartyFilter VARCHAR(50)
	SET @cStep='55'
	set @cJoinStr=''

	IF @CEOSSTERMSID=''
	BEGIN

		INSERT @tTerms (eoss_term_id,ac_code,filter_criteria)
		SELECT  ID,a.ac_code,a_filter from TBL_EOSS_DISC_SHARE_MST a (NOLOCK)
		WHERE a.ac_code IN (SELECT DISTINCT supplier_ac_code FROM sor_pay_upload (NOLOCK) 
						    WHERE sp_id=@nSpId)
		union
		SELECT  DISTINCT '' as ID,a.supplier_ac_code,'' as a_filter from sor_pay_upload a (NOLOCK)
		left outer join TBL_EOSS_DISC_SHARE_MST	b (NOLOCK) ON a.supplier_ac_code=b.ac_code
		where a.sp_id=@nSpId AND b.ac_code is null
	
		SET @cJoinStr=' JOIN sku_names sn(nolock) ON sn.product_code=a.product_code'	
	END
	ELSE
		INSERT @tTerms (ac_code,eoss_term_id,filter_criteria)
		SELECT @CAC_CODE,@CEOSSTERMSID,@CFILTER
	


	IF @cCurMemoId NOT IN ('','LATER')
	BEGIN
		SET @cStep='55.7'
		UPDATE a WITH (ROWLOCK) SET 
		sor_terms_code=b.sor_terms_code FROM sor_pay_upload a
		JOIN eosssord b (NOLOCK) ON a.cmd_row_id=b.cmd_row_id
		WHERE b.memo_id=@cCurMemoId AND a.sp_id=@nSpId AND ISNULL(a.sor_terms_code,'') IN ('','000')
	END
	   

	WHILE EXISTS (SELECT top 1 * from @tTerms)
	BEGIN
		SET @cStep='57'
		IF @CEOSSTERMSID=''
		BEGIN
			SELECT TOP 1 @cTermsId=ltrim(rtrim(eoss_term_id)),@cAcCode=ac_code,@cFilter=filter_criteria FROM @tTerms ORDER BY eoss_term_id

			SET @cFilter = @cFilter+ (CASE WHEN @CFILTER<>'' THEN  ' AND ' ELSE '' END)+'  a.ac_code='''+ltrim(rtrim(@cAcCode))+''''

		END
		ELSE
			SELECT @cFilter=' 1=1 ', @cTermsId=ltrim(rtrim(@CEOSSTERMSID)),@cAcCode=''


	   SET @cStep='57.5'
	   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET 
	   sor_terms_code=b.fresh_sale_sor_terms_code FROM sor_pay_upload a
	   JOIN
		(SELECT fresh_sale_sor_terms_code FROM TBL_EOSS_DISC_SHARE_MST (NOLOCK)
		 WHERE ID='''+@CTERMSID+''') b ON 1=1 
		WHERE sp_id='''+@nSpId+''' AND '+@cFilter+' AND 
		(discount_amount-isnull(skip_bill_discount_amount,0)-isnull(card_discount_amount,0))=0  
		AND ISNULL(sor_terms_code,'''') IN ('''',''000'')
		'	 
	   PRINT @cCmd	
	   EXEC SP_EXECUTESQL @cCmd
		
	   SET @cStep='57.9'	
	   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET 
	   gm_per=ISNULL(EOSS_TERMS.gm_per,0) FROM sor_pay_upload a
	   LEFT OUTER JOIN 
		(SELECT base,DISCFROM,DISCTO,SUPP_SHARE_PER as gm_per FROM TBL_EOSS_DISC_SHARE_DET (NOLOCK)
		 WHERE ID='''+@CTERMSID+''') EOSS_TERMS ON 1=1 
		WHERE sp_id='''+@nSpId+''' AND '+@cFilter+' AND  
		((sor_terms_code IN (''NWM'',''NDM'',''TDM'') AND ISNULL(weighted_discount_percentage,0) BETWEEN isnull(EOSS_TERMS.DISCFROM,0)
		  AND isnull(EOSS_TERMS.DISCTO,100)) OR
		(sor_terms_code NOT IN (''NWM'',''NDM'',''TDM'') AND isnull(EOSS_TERMS.DISCFROM,0)=0
		 AND isnull(EOSS_TERMS.DISCTO,100)=0)
		)'	 
	   PRINT @cCmd	
	   EXEC SP_EXECUTESQL @cCmd



	  -- if @@spid=262
			--select 'check after updating gm per', gm_per,sor_terms_code, * from  sor_pay_upload where sp_id=@nSpId and product_code='WT292661-23@HO860240'

	   DELETE FROM @tTerms WHERE eoss_term_id=@cTermsId
	END

	SET @cStep='59'	
	UPDATE sor_pay_upload WITH (ROWLOCK) SET item_net=mrp_value-basic_discount_amount
	WHERE sp_id=@nSpId
  
	
    --select 'check taxable value',xn_value_without_gst,sor_terms_code,basic_discount_amount,scheme_discount,weighted_avg_disc_amt,taxable_value,* from  sor_pay_164

	SET @cStep='60.2'

	IF EXISTS (SELECT TOP 1 hsn_code FROM gst_taxinfo_calc (NOLOCK) WHERE sp_id=@NSPID)
		DELETE FROM gst_taxinfo_calc WITH (ROWLOCK) where sp_id=@nSpid

		
	
	
	SET @cStep='64.5'
	UPDATE sor_pay_upload WITH (ROWLOCK) SET 
	claimed_base_value=(case when sor_terms_code IN ('TFM','TDM') THEN taxable_value 
						     WHEN sor_terms_code IN ('NFM','NDM') THEN item_net-bill_discount_amount
							 WHEN sor_terms_code IN ('NWM') THEN (mrp_value-(CASE WHEN weighted_avg_disc_amt<>0
							 THEN weighted_avg_disc_amt ELSE BASIC_DISCOUNT_AMOUNT END)-bill_discount_amount)
							 ELSE mrp_value END)
	WHERE sp_id=@nSpId	
		
	SET @cStep='70'
	
	---- Restored code for recalculation of Gst after ZOOM meeting of Sir,Pankaj with Suvidha for SOR on 04-08-2020 
  
	INSERT GST_TAXINFO_CALC	( PRODUCT_CODE, SP_ID ,NET_VALUE,TAX_METHOD,ROW_ID,QUANTITY,
	LOC_STATE_CODE ,LOC_GSTN_NO,LOCREGISTERED,PARTY_STATE_CODE ,PARTY_GSTN_NO,PARTYREGISTERED,LOCALBILL,MEMO_DT,MRP,SOURCE_DEPT_ID )  
    SELECT a.PRODUCT_CODE,@NSPID AS SP_ID,
	claimed_base_value AS NET_VALUE,
	(case when a.TAX_METHOD=2 then 1 else 2 end) tax_method,a.cmd_ROW_ID,a.QUANTITY,SLOC.GST_STATE_CODE AS LOC_STATE_CODE,SLOC.LOC_GST_NO AS LOC_GSTN_NO,
	SLOC.REGISTERED_GST AS LOCREGISTERED,cmm.PARTY_STATE_CODE,
	(CASE WHEN ISNULL(A.party_AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.AC_GST_NO ELSE '' END) AS 	PARTY_GSTN_NO,
	(CASE WHEN ISNULL(a.party_AC_CODE,'0000000000') NOT IN ('','0000000000') THEN LM.REGISTERED_GST_DEALER ELSE 0 END) AS PARTYREGISTERED,
	(CASE WHEN a.CUSTOMER_CODE IN ('','000000000000') AND ISNULL(a.party_AC_CODE,'0000000000')  IN ('','0000000000')
			THEN 1 ELSE 0 END) AS LOCALBILL ,
		a.CM_DT	as CM_DT,b.MRP,cmm.location_code FROM
	sor_pay_upload A (NOLOCK)
	JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_no=a.cm_no and cmm.cm_dt=a.cm_dt
	JOIN sku b (NOLOCK) ON a.product_code=b.product_code
	left outer join lmP01106 lm (NOLOCK) ON lm.ac_code=a.party_ac_code	
	LEFT OUTER JOIN location sloc (NOLOCK) ON sloc.dept_id=cmm.location_code
	WHERE sp_id=@nSpId AND (skip_bill_discount_amount<>0 OR (sor_terms_code='MFM' AND 
	cmm_discount_amount=0) OR isnull(card_discount_amount,0)<>0)

   
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
	   
	   IF @cLocId=''
		   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET purchase_price=ISNULL(round((b.xn_value_without_gst+b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2),0),
		   row_id=CONVERT(VARCHAR(36),NEWID()),
		   input_gst=isnull(ROUND((b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2)*a.quantity,0)
		   FROM sor_pay_upload a
		   JOIN '+@cDbName+'.dbo.pid01106 b (NOLOCK) ON a.PRODUCT_CODE=b.product_code
		   JOIN '+@cDbName+'.dbo.pim01106 c (NOLOCK) ON c.mrr_id=b.mrr_id
		   WHERE sp_id='''+@nSpId+''' AND inv_mode=1 AND a.row_id=''LATER'''
	   ELSE
		   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET purchase_price=isnull(round((b.xn_value_without_gst+b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2),0),
		   row_id=CONVERT(VARCHAR(36),NEWID()),
		   input_gst=isnull(ROUND((b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2)*a.quantity,0),
		    pur_bill_no=C.INV_NO , pur_bill_dt=CONVERT(VARCHAR(10),C.INV_dt,105)
		   FROM sor_pay_upload a
		   JOIN '+@cDbName+'.dbo.ind01106 b ON a.PRODUCT_CODE=b.product_code
		   JOIN '+@cDbName+'.dbo.inm01106 c ON c.inv_id=b.inv_id
		   WHERE sp_id='''+@nSpId+''' AND inv_dt<='''+convert(varchar,@dToDt,112)+''' AND inv_mode=2 AND party_dept_id='''+@cLocId+''' 
		   AND a.row_id=''LATER'''

	   PRINT @cCmd
	   EXEC SP_EXECUTESQL @cCmd		     
	   
	   
	   SET @cStep='93.2'
	   IF NOT EXISTS (SELECT TOP 1 * from sor_pay_upload (NOLOCK) WHERE sp_id=@nSpId AND ROW_ID='LATER')
			SET @bExit=1
	   
	   IF ISNULL(@bExit,0)=0 AND @cLocId=''
	   BEGIN
		   SET @cStep='94.5'

		   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET purchase_price=ISNULL(round((b.xn_value_without_gst+b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2),0),
		   row_id=CONVERT(VARCHAR(36),NEWID()),
		   input_gst=isnull(ROUND((b.cgst_amount+b.sgst_amount+b.igst_amount)/invoice_quantity,2)*a.quantity,0)
		   FROM sor_pay_upload a
		   JOIN sku  (NOLOCK) ON sku.product_code=a.product_code
		   JOIN article art (NOLOCK) ON art.article_code=sku.article_code
		   JOIN '+@cDbName+'.dbo.pid01106 b (NOLOCK) ON a.PRODUCT_CODE=LEFT(b.PRODUCT_CODE, 
		   ISNULL(NULLIF(CHARINDEX (''@'',b.PRODUCT_CODE)-1,-1),LEN(b.PRODUCT_CODE )))
		   JOIN '+@cDbName+'.dbo.pim01106 c ON c.mrr_id=b.mrr_id AND c.inv_no=sku.inv_no AND c.inv_dt=sku.inv_dt
		   WHERE sp_id='''+@nSpId+''' AND inv_mode=1 AND a.row_id=''LATER'' AND (isnull(sku.barcode_coding_scheme,0)=1 OR art.coding_scheme=1)'

		   PRINT @cCmd
		   EXEC SP_EXECUTESQL @cCmd		     
	   END

	   SET @cStep='96'
	   IF NOT EXISTS (SELECT TOP 1 * from sor_pay_upload (NOLOCK) WHERE sp_id=@nSpId AND ROW_ID='LATER')
			SET @bExit=1

	   IF ISNULL(@bExit,0)=0 AND @cLocId=''
	   BEGIN
		   SET @cStep='98'

		   SET @cCmd=N'UPDATE a WITH (ROWLOCK) SET purchase_price=sku.purchase_price+isnull(b.tax_amount,0),
		   row_id=CONVERT(VARCHAR(36),NEWID()),input_gst=isnull(b.tax_amount*a.quantity,0)
		   FROM sor_pay_upload a
		   JOIN sku  (NOLOCK) ON sku.product_code=a.product_code
		   JOIN article art (NOLOCK) ON art.article_code=sku.article_code
		   LEFT JOIN sku_oh b (NOLOCK) ON a.PRODUCT_CODE=b.product_code
		   WHERE sp_id='''+@nSpId+''' AND a.row_id=''LATER'' '

		   PRINT @cCmd
		   EXEC SP_EXECUTESQL @cCmd		     
	   END	   
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
				THEN (CASE WHEN basic_discount_amount=0
				THEN 'FRESH' ELSE 'DISCOUNTED' END) ELSE eoss_scheme_name END) 
	FROM sor_pay_upload a 
	JOIN sku_names b (NOLOCK) ON a.product_code=b.product_code
	WHERE sp_id=@nSpId
	
	SET @cStep='110'	 
	----- Did special change of not deducting output gst component If Sor terms is based on Taxable Value (07-01-2021)
	----- as per told by Sir in Zoom meeting with Pankaj in Senior Support Room
	UPDATE sor_pay_upload WITH (ROWLOCK) SET NET_PAYABLE=claimed_base_value-claimed_base_gm_value+
	(gst_diff+(CASE WHEN sor_terms_code IN ('TDM','TFM') THEN output_gst ELSE 0 END))
	WHERE sp_id=@nSpId

	SET @cStep='112'	
	UPDATE sor_pay_upload WITH (ROWLOCK) SET  rate_diff=ROUND((purchase_price*quantity)-net_payable,2)
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
	SET @cErrormsg='Error in Procedure SP3S_PENDING_EOSS_SOR at Step# '+@cStep+' '+ERROR_MESSAGE()
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
			IF @bCalledFromMulti=0
			BEGIN
				SELECT  purchase_price as chk_pp,a.*,c.dept_alias, sn.*,'' as errmsg,mrp_value mrp
				FROM sor_pay_upload a (NOLOCK) 
				JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_no=a.cm_no and cmm.cm_dt=a.cm_dt
				JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.product_code
				JOIN location c (NOLOCK) ON c.dept_id=cmm.location_code
				where sp_id=@nSpId AND isnull(grandtotal,0)=0 
				order by eoss_scheme_name,subtotal,cm_dt,cm_no
			END


			--select 'check final data'
			SELECT purchase_price as chk_pp,c.dept_alias,  a.*,'' as errmsg,a.cm_dt as display_cm_dt,mrp_value mrp
			 FROM sor_pay_upload a (NOLOCK)  
			 JOIN cmm01106 cmm (NOLOCK) ON cmm.cm_no=a.cm_no and cmm.cm_dt=a.cm_dt
			JOIN location c (NOLOCK) ON c.dept_id=cmm.location_code
			where sp_id=@nSpId AND isnull(a.subtotal,0)=0 and  isnull(grandtotal,0)=0

			SELECT  sor_terms_desc,SUM(taxable_value) taxable_value,SUM(taxable_value+output_gst) NRV,
			(case when SUM(taxable_value)<>0 THEN  convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value))*100 ,2)) else 0 end) margin_pct_taxable,gm_per,sum(claimed_base_value) claimed_base_value,
			SUM(claimed_base_gm_value) claimed_base_gm_value,SUM(output_gst) output_gst,
			SUM(input_gst) input_gst,SUM(input_gst-output_gst) net_gst,SUM(net_payable) net_payable,
			(case when SUM(taxable_value+output_gst)<>0 THEN  convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value+output_gst))*100,2)) else 0 end) final_margin_pct,1 as disp_order
			FROM sor_pay_upload (NOLOCK) where SP_ID=@nSpId AND isnull(subtotal,0)=0
			GROUP BY sor_terms_desc,gm_per
						
			UNION ALL
			SELECT  'Totals:' AS sor_terms_DESC,SUM(taxable_value) taxable_value,SUM(taxable_value+output_gst) NRV,
			(case when SUM(taxable_value)<>0 THEN convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value))*100 ,2)) ELSE 0 END) margin_pct_taxable,
			0 gm_per,sum(claimed_base_value) claimed_base_value,
			SUM(claimed_base_gm_value) claimed_base_gm_value,SUM(output_gst) output_gst,
			SUM(input_gst) input_gst,SUM(input_gst-output_gst) net_gst,SUM(net_payable) net_payable,
			(case when SUM(taxable_value+output_gst)<>0 THEN  convert(numeric(6,2),
			ROUND((SUM(claimed_base_gm_value)/SUM(taxable_value+output_gst))*100,2)) else 0 end) final_margin_pct,2 as disp_order
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

	print 'delete now upload entries'
	IF EXISTS (SELECT TOP 1 sp_id  FROM SOR_PAY_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId)  and @@spid<>820
		DELETE FROM SOR_PAY_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId
	
	print 'deletion done upload entries'
END
--END OF PROCEDURE - SP3S_PENDING_EOSS_SOR