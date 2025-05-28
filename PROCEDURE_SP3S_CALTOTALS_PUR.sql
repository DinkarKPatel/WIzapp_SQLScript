create PROCEDURE SP3S_CALTOTALS_PUR--(LocId 3 digit change by Sanjay:04-11-2024)
@nUpdatemode NUMERIC(2,0),
@nSpId VARCHAR(40)='',
@cMrrId VARCHAR(40)='',
@BCALLEDFROMEKAYA bit=0,
@NBOXUPDATEMODE NUMERIC(1,0)=0, 
@nrcm_applicable bit=0,
@EDIT_CLICKED BIT=0,
@nBoxNo NUMERIC(3,0)=0,
@CERRORMSG VARCHAR(MAX) OUTPUT,
@CDEPT_ID VARCHAR(4)='',
@NPARTY_AMOUNT_FORTCS NUMERIC(18,2)=0
AS
BEGIN
	DECLARE @cStep VARCHAR(50),@DMEMO_DT datetime,@ApplyCDOnTotal varchar(5),
	@cTerms VARCHAR(500),@nBaseAmount NUMERIC(20,2),@NTAX numeric(10,2),@CGSTCUTOFFDATE varchar(10),@gstdate datetime,
	 @nSubtotal numeric(14,2),@nPimDiscount numeric(14,2),@nTotalAmount numeric(14,2),@nTaxmethod numeric(1,0),@nTotalTax numeric(10,2),
			@NCASHDISCOUNTAMOUNT numeric(14,2)	,@TotalgstcessAmount numeric(10,2)
	
	
begin try
  set @cstep=283.2
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
	
	

  CREATE TABLE #tMsttable (dept_id varchar(4),fin_year varchar(10),accounts_dept_id varchar(4),receipt_dt datetime,ac_code char(10),subtotal numeric(10,2),total_amount numeric(10,2),
  tcs_amount numeric(10,2),pim_mode NUMERIC(1,0),
  discount_amount numeric(10,2),discount_percentage numeric(7,3),bill_level_tax_method numeric(1,0),terms varchar(200),TOTAL_CASHDISCOUNTAMOUNT numeric(10,2),
  xn_item_type numeric(1,0),TOTAL_QUANTITY numeric(10,2),TOTAL_BOX_NO numeric(3,0),
  TOTAL_GST_AMOUNT numeric(10,2),TOTAL_QUANTITY_STR varchar(2000),round_off numeric(6,2), OH_TAX_METHOD numeric(1,0),
 FRIGHT_PAY_MODE numeric(1,0),freight numeric(10,2),excise_duty_amount numeric(10,2),POSTTAXDISCOUNTAMOUNT numeric(10,2),
  MANUAL_ROUNDOFF bit,OTHER_CHARGES numeric(10,2),OTHER_CHARGES_IGST_AMOUNT numeric(10,2),OTHER_CHARGES_cGST_AMOUNT numeric(10,2),
  OTHER_CHARGES_sGST_AMOUNT numeric(10,2),FREIGHT_IGST_AMOUNT numeric(10,2)    ,FREIGHT_cGST_AMOUNT numeric(10,2)
  ,FREIGHT_sGST_AMOUNT numeric(10,2),gst_round_off numeric(4,2),INPUT_GST_ROUND_OFF numeric(6,2),manual_discount bit,
  OTHER_CHARGES_HSN_CODE varchar(100),freight_hsn_code varchar(100),freight_gst_percentage numeric(6,2),other_charges_gst_percentage numeric(6,2),
  freight_taxable_value numeric(10,2),other_charges_taxable_value numeric(10,2),PUR_FOR_DEPT_ID VARCHAR(4),party_state_code varchar(10),total_Gst_cess_Amount numeric(10,2),
  GOODS_TDS_BASEAMOUNT numeric(18,2),GOODS_TDS_PERCENTAGE numeric(10,3),GOODS_TDS_AMOUNT numeric(12,2),
  TDS_PERCENTAGE numeric(10,3),TDS_AMOUNT numeric(12,2),memo_type int,supply_state_code VARCHAR(4),bill_challan_mode int
 
  
  )

   

  CREATE TABLE #tDettable (product_code varchar(50),article_code varchar(10),tax_amount numeric(10,2),XN_VALUE_WITHOUT_GST numeric(10,2),igst_amount numeric(10,2),
		cgst_amount numeric(10,2),sgst_amount numeric(10,2),mrp numeric(10,2),MANUAL_MDP bit,MANUAL_Mpp bit,
		 cashdiscountamount numeric(10,2),PIMPOSTTAXDISCOUNTAMOUNT numeric(10,2),PIMEXCISEDUTYAMOUNT numeric(10,2),hsn_code varchar(100),
		 md_percentage numeric(10,2),mp_percentage numeric(10,2),INVOICE_QUANTITY numeric(10,3),
		 purchase_price numeric(14,3),
		 box_no numeric(3,0),quantity numeric(10,3),cess_amount numeric(10,2),PIMDISCOUNTAMOUNT numeric(10,2),
		 XN_VALUE_WITH_GST numeric(10,2),gst_percentage numeric(6,2),ITEM_EXCISE_DUTY_PERCENTAGE numeric(6,2),
		 ITEM_EXCISE_DUTY_amount numeric(10,2),form_id char(7),TAX_PERCENTAGE numeric(6,2),ROW_ID VARCHAR(50),
		 Gst_Cess_Percentage numeric(6,2), gst_cess_Amount numeric(10,2),TAX_ROUND_OFF numeric(5,2)
		 )


	set @cstep=283.4
	EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    

	declare @cInsSpId varchar(50),@cMstTable varchar(200),@cDetTable varchar(200),@cKeyfield varchar(200),
	@cWhereclause varchar(500),@cWhereclausePid varchar(500),@cCmd nvarchar(max),@nBoxnoForGstCalc NUMERIC(3,0)

	SET @nBoxnoForGstCalc=0
	IF (@EDIT_CLICKED=0 AND @nBoxUpdatemode=1) OR @NUPDATEMODE=1
	BEGIN
		IF NOT EXISTS (SELECT TOP 1 mrr_id FROM PUR_pim01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId AND discount_percentage<>0)
			SELECT TOP 1 @nBoxnoForGstCalc=@nBoxNo
	END

	

	SET @CINSSPID=LEFT(@nSpId,38)+'ZZZ'
	IF @nUpdatemode NOT IN (1,2)
			SELECT @cMstTable='pim01106',@cDetTable='pid01106',@cWhereClause='b.mrr_id='''+@cMrrId+'''',
			@cKeyField='mrr_id',
			@cWhereClausePid='b.mrr_id='''+@cMrrId+''''
		ELSE
			SELECT @cMstTable='pur_pim01106_upload',@cDetTable='pur_pid01106_upload',
			@cWhereClause='sp_id='''+@nSpId+'''',@cKeyField='sp_id',
			@cWhereClausePid='sp_id='''+@nSpId+''''+(case when   @NBOXUPDATEMODE=0  then '' else ' or sp_id='''+@CINSSPID+'''' end)
		
  set @cstep=283.6
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
	
	

		set @cCmd=N'select dept_id,fin_year,accounts_dept_id,party_state_code,receipt_dt ,ac_code , discount_amount ,discount_percentage, bill_level_tax_method ,terms ,
    xn_item_type, OH_TAX_METHOD ,FRIGHT_PAY_MODE ,freight ,excise_duty_amount ,POSTTAXDISCOUNTAMOUNT , 
	MANUAL_ROUNDOFF ,OTHER_CHARGES,INPUT_GST_ROUND_OFF,manual_discount,PUR_FOR_DEPT_ID,subtotal	,other_charges_hsn_code,freight_hsn_code,round_off,
	tcs_amount,pim_mode, GOODS_TDS_BASEAMOUNT ,GOODS_TDS_PERCENTAGE ,GOODS_TDS_AMOUNT,TDS_PERCENTAGE ,TDS_AMOUNT ,b.memo_type,supply_state_code,b.bill_challan_mode
	from '+@CmSTtABLE+' b  (nolock) where '+@cWhereclause

	  set @cstep=283.8
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
  INSERT #tMsttable (dept_id,fin_year,accounts_dept_id,party_state_code,receipt_dt ,ac_code , discount_amount ,discount_percentage, bill_level_tax_method ,terms ,
    xn_item_type, OH_TAX_METHOD ,FRIGHT_PAY_MODE ,freight ,excise_duty_amount ,POSTTAXDISCOUNTAMOUNT ,
	MANUAL_ROUNDOFF ,OTHER_CHARGES,INPUT_GST_ROUND_OFF,manual_discount,PUR_FOR_DEPT_ID,subtotal,other_charges_hsn_code,freight_hsn_code,round_off,tcs_amount,pim_mode,
	 GOODS_TDS_BASEAMOUNT ,GOODS_TDS_PERCENTAGE ,GOODS_TDS_AMOUNT,TDS_PERCENTAGE ,TDS_AMOUNT ,memo_type,supply_state_code,bill_challan_mode
	) 
	EXEC SP_EXECUTESQL @cCmd



	--if @@spid=163
	--	select 'check caltotals_pur', @cMrrid,@cInsspid

	set @cstep=283.9
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
	set @cCmd=N'select product_code,tax_amount ,hsn_code ,article_code,iNVOICE_QUANTITY ,purchase_price ,
	box_no,quantity,mrp,MANUAL_MDP,MANUAL_MpP,ROW_ID,cashdiscountamount,
	XN_VALUE_WITHOUT_GST,cgst_amount,sgst_amount,igst_amount from '+@CdETtABLE+' b (nolock) where '+@cWhereClausePid 


	insert  #tDettable (product_code,tax_amount ,hsn_code ,article_code,iNVOICE_QUANTITY ,purchase_price ,
	box_no,quantity,mrp,MANUAL_MDP,MANUAL_Mpp,ROW_ID,cashdiscountamount,XN_VALUE_WITHOUT_GST,cgst_amount,sgst_amount,igst_amount)
	EXEC SP_EXECUTESQL @CcMD

	SELECT @DMEMO_DT=RECEIPT_DT FROM #tmsttable
  

	
	  set @cstep=283.10
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
  IF EXISTS (SELECT TOP 1 A.ARTICLE_CODE FROM ARTICLE A WITH (ROWLOCK) JOIN #tDettable B ON A.ARTICLE_CODE=B.ARTICLE_CODE
			 WHERE  ISNULL(B.HSN_CODE,'')<>'' AND a.hsn_code<>b.hsn_code)
	  UPDATE A SET HSN_CODE=B.HSN_CODE FROM ARTICLE A WITH (ROWLOCK) JOIN #tDettable B ON A.ARTICLE_CODE=B.ARTICLE_CODE
	  WHERE  ISNULL(B.HSN_CODE,'')<>'' AND a.hsn_code<>b.hsn_code
  
	 --UPDATE  MARK UP & MARK DOWN PERCENTAGE
    set @cstep=283.12
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    

	UPDATE A SET  
		  MD_PERCENTAGE=CONVERT(NUMERIC(10,2), ROUND(((MRP*QUANTITY)-(PURCHASE_PRICE *QUANTITY ) )/(MRP*QUANTITY)*100,2))
	FROM #tDettable A
	JOIN #tMsttable B (NOLOCK) ON 1=1
	WHERE  MRP<>PURCHASE_PRICE 
	AND MRP<>0
	AND ISNULL(MANUAL_MDP,0) =0 AND xn_item_type=1


	
	  set @cstep=283.15
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
	UPDATE A SET 
	MP_PERCENTAGE =CONVERT(NUMERIC(10,2), ROUND(((MRP*QUANTITY)-(PURCHASE_PRICE*QUANTITY))/(PURCHASE_PRICE*QUANTITY)*100,2) )      
	FROM #tDettable A
	JOIN #tMsttable B (NOLOCK) ON 1=1
	WHERE  MRP<>PURCHASE_PRICE 
	AND (PURCHASE_PRICE*QUANTITY)<>0
	AND ISNULL(MANUAL_MPP,0) =0
	 AND xn_item_type=1

	    set @cstep=283.17
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1          
	 
  
	
	  -- UPDATING TOTALS IN PIM TABLE  
	  UPDATE A SET SUBTOTAL = ROUND(ISNULL( B.SUBTOTAL ,0 ),2),
				   TOTAL_QUANTITY=B.INVOICE_QUANTITY,
				   TOTAL_BOX_NO=ISNULL(B.TOTAL_BOX_NO,0)
				   
	  FROM #tMstTable A  LEFT OUTER JOIN  
	  (    
		   SELECT  SUM(INVOICE_QUANTITY*PURCHASE_PRICE) AS SUBTOTAL ,
				  SUM(QUANTITY) AS INVOICE_QUANTITY,
				  COUNT(DISTINCT BOX_NO) AS TOTAL_BOX_NO
		   FROM #tDetTable

	  ) B ON 1=1
  
  set @cstep=283.19
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

	  UPDATE #tMstTable SET DISCOUNT_AMOUNT = ROUND(SUBTOTAL*DISCOUNT_PERCENTAGE/100,2)  
	  WHERE MANUAL_DISCOUNT =0   OR @NBOXUPDATEMODE=1

	  ---DISTRIBUTING BILL LEVEL DISCOUNT AND POSTTAXDISCOUNTAMOUNT AT ITEM LEVEL
	  UPDATE A
			 SET PIMPOSTTAXDISCOUNTAMOUNT=(CASE WHEN B.SUBTOTAL=0 THEN 0 ELSE (B.POSTTAXDISCOUNTAMOUNT/B.SUBTOTAL)*A.PURCHASE_PRICE END),
				PIMDISCOUNTAMOUNT=ROUND((CASE WHEN B.SUBTOTAL=0 THEN 0 ELSE (B.DISCOUNT_AMOUNT/B.SUBTOTAL)*(A.PURCHASE_PRICE*A.INVOICE_QUANTITY) END),2)
				,PIMEXCISEDUTYAMOUNT=(CASE WHEN B.SUBTOTAL=0 THEN 0 ELSE (B.EXCISE_DUTY_AMOUNT/B.SUBTOTAL)*A.PURCHASE_PRICE END)
			 FROM #tDettable A
			  JOIN #tMsttable B (NOLOCK) ON 1=1

  set @cstep=283.21
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    

     DECLARE @NTOTAL_DISCOUNT_AMOUNT NUMERIC(10,2)
    SELECT   @NTOTAL_DISCOUNT_AMOUNT= ISNULL(DISCOUNT_AMOUNT,0)  FROM #tMstTable
   

   IF ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)<>0
   BEGIN
	  set @cstep=283.23
	  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
       EXEC SP3S_REPROCESS_PUR_BILL_DISCOUNT '',@NSPID,@CERRORMSG OUTPUT 
	   IF ISNULL(@CERRORMSG,'')<>''
	   GOTO END_PROC  
   
   END  
   

  
 --  if @@spid=163
 --  begin
	--	select 'check tdet pimdisc after reporocess', box_no,product_code,igst_amount,cgst_amount,XN_VALUE_WITHOUT_GST,PIMDISCOUNTAMOUNT,
	--	iNVOICE_QUANTITY ,purchase_price from #tDetTable
	
	--end

  set @cstep=283.25
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
			  DECLARE @STR VARCHAR(MAX)
			  SET @STR=NULL
			  

			 SELECT  @STR =  COALESCE(@STR +  '/ ', ' ' ) + (''+C.UOM_NAME+': '+CAST(SUM(QUANTITY) AS VARCHAR) +' ')  
			 FROM #tDetTable A
			 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE=B.ARTICLE_CODE
			 JOIN UOM C (NOLOCK) ON C.UOM_CODE=B.UOM_CODE
			  GROUP BY C.UOM_NAME 
		 
			 UPDATE #tMstTable SET TOTAL_QUANTITY_STR =@STR
	
  set @cstep=283.28
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1   
  
     declare @nmemo_type int

	  SELECT @NSUBTOTAL=SUBTOTAL,@nmemo_type=memo_type FROM #tMsttable
         
	
  
    DECLARE @CCLACULATEGSTINCHALLAN VARCHAR(5),@NBILLCHALLANMODE numeric(1,0)
    
    SELECT TOP 1 @CCLACULATEGSTINCHALLAN=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION ='PUR_CALCULATE_GST_IN_CHALLAN' 
    
    
    IF ISNULL(@CCLACULATEGSTINCHALLAN,'')='1'
		SET @NBILLCHALLANMODE=0
   
    
    SELECT @CGSTCUTOFFDATE=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION ='GST_CUT_OFF_DATE'
    
    IF @CGSTCUTOFFDATE<>''
        SELECT @GSTDATE=CAST(@CGSTCUTOFFDATE AS DATETIME)
    
	IF (@DMEMO_DT>=@GSTDATE ) AND ISNULL(@NBILLCHALLANMODE,0)=0 and ISNULL(@nrcm_applicable,0)=0 and isnull(@nmemo_type,0)<>2
	BEGIN
	  set @cstep=283.30
	  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
	print 'calculating gst for purchase-started'
		EXEC SP3S_GST_TAX_CAL
		@CXN_TYPE='PUR',
		@CMEMO_ID=@cMrrId,
		@DMEMO_DT=@DMEMO_DT,
		@NSPID=@NSPID,
		@CPARTYSTATE_CODE='',
		@BLOCALBILL=0,
		@BPARTYREGISTERED=0,
		@CPARTY_GSTN_NO='',
		@cLocationId=@CDEPT_ID,
		@nBoxNo=@nBoxnoForGstCalc,
		@CERRMSG=@CERRORMSG OUTPUT
	


		print 'calculating gst for purchase-finished'
		
		IF ISNULL(@CERRORMSG,'')<>''
		   GOTO END_PROC  


		EXEC SP3S_PUR_CONVERT_FOREX_INR @NSPID,@CERRORMSG OUTPUT
	   IF ISNULL(@CERRORMSG,'')<>''
		 GOTO END_PROC

  	    UPDATE #tDetTable SET ITEM_EXCISE_DUTY_PERCENTAGE=0,ITEM_EXCISE_DUTY_AMOUNT=0,TAX_PERCENTAGE=0,TAX_AMOUNT=0,
		FORM_ID='0000000'

		IF @DMEMO_DT>='2017-07-01' 
		BEGIN    
	 
			  set @cstep=283.32
			  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    	

			  EXEC SP3S_REPROCESS_GST_CALCULATION '','PUR',@nSpId,@CERRORMSG OUTPUT 
			  IF ISNULL(@CERRORMSG,'')<>''
			  GOTO END_PROC

	      
			   --*********GST ROUND OFF CALCULATION ************ external field add
				DECLARE @BROUND_OFF_GST_AMT INT ,@INPUT_GST_ROUND_OFF numeric(10,2)
	      
				SELECT @BROUND_OFF_GST_AMT=ROUND_OFF_GST_AMT ,@INPUT_GST_ROUND_OFF=A.INPUT_GST_ROUND_OFF
				FROM  #tmsttable  A 
				JOIN LMP01106 B (NOLOCK) ON A.AC_CODE =B.AC_CODE 
			
			
			  set @cstep=283.35
			  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
			  	
				IF ISNULL(@BROUND_OFF_GST_AMT,0)=1 AND abs(ISNULL(@INPUT_GST_ROUND_OFF,0))>0
				BEGIN

					  EXEC SP3S_REPROCESS_GST_CALCULATION '','PUR',@nSpId,@CERRORMSG OUTPUT ,1
					  IF ISNULL(@CERRORMSG,'')<>''
					  GOTO END_PROC
				END

			
			
				--END OG GST ROUND OFF CALCULATION  
	      
		 END 
  
	 
	END
	ELSE
	BEGIN
		  set @cstep=283.37
		  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    
	    
		 UPDATE #tMstTable SET OTHER_CHARGES_HSN_CODE ='0000000000',FREIGHT_HSN_CODE='0000000000'
		
		 update a set HSN_CODE=CASE WHEN ISNULL(a.HSN_CODE,'') not in ('','0000000000') THEN a.HSN_CODE
		              WHEN ISNULL(b.HSN_CODE,'') not in ('','0000000000') THEN b.HSN_CODE
		   ELSE art.HSN_CODE END
		 FROM #tDetTable A 
		 LEFT JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE
		 LEFT JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE=B.ARTICLE_CODE 

		  set @cstep=283.39
		  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1    		 
		 UPDATE #tDetTable WITH (ROWLOCK) SET HSN_CODE=CASE WHEN ISNULL(HSN_CODE,'')='' 
		 THEN  '0000000000' ELSE HSN_CODE END,
		 GST_PERCENTAGE=0,IGST_AMOUNT=0,CGST_AMOUNT=0,SGST_AMOUNT=0,
		 Gst_Cess_Percentage  =0,gst_cess_Amount =0,
		 XN_VALUE_WITHOUT_GST=(((PURCHASE_PRICE*INVOICE_QUANTITY)-(ISNULL(PIMDISCOUNTAMOUNT,0))
				             )),XN_VALUE_WITH_GST=(((PURCHASE_PRICE*INVOICE_QUANTITY)-(ISNULL(PIMDISCOUNTAMOUNT,0))
				             )) 
	       
	END   

	
  set @cstep=283.41
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       
	   --SELECT PRODUCT_CODE ,TAX_AMOUNT FROM PID01106   WHERE MRR_ID=@CKEYFIELDVAL1  
	  IF @DMEMO_DT<@GSTDATE  
	  BEGIN
		  SELECT @NTAX=ROUND(SUM(TAX_AMOUNT),3) FROM #tDetTable
		  UPDATE #tMsttable WITH  (ROWLOCK) SET TAX_AMOUNT=ISNULL(@NTAX,0)
	  END 
	  ELSE
	  begin
		 SELECT @NTAX=ROUND(SUM(ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(CESS_AMOUNT,0)),3) ,
		        @TotalgstcessAmount=ROUND(SUM(ISNULL(gst_cess_Amount ,0)),3) 
		 FROM #tDettable

		 
		UPDATE #tMstTable SET TOTAL_GST_AMOUNT=isnull(@nTax ,0),total_Gst_cess_Amount =isnull(@TotalgstcessAmount,0)
		
	 end

	


	  set @cstep=283.55
	  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

	  UPDATE #tMsttable SET ROUND_OFF=ROUND((SUBTOTAL + (CASE WHEN BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(@NTAX,0)+ISNULL(@TotalgstcessAmount,0) END) +  OTHER_CHARGES +   
		  CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0) END +
		  EXCISE_DUTY_AMOUNT+CASE WHEN ISNULL(FRIGHT_PAY_MODE,0)=2 THEN 0 ELSE  FREIGHT END ) - DISCOUNT_AMOUNT - POSTTAXDISCOUNTAMOUNT,0)-(SUBTOTAL+ (CASE WHEN BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(@NTAX,0)+ISNULL(@TotalgstcessAmount,0) END) +OTHER_CHARGES+  
		  CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE  ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0) END+
		 CASE WHEN ISNULL(FRIGHT_PAY_MODE,0)=2 THEN 0 ELSE  FREIGHT END +EXCISE_DUTY_AMOUNT-DISCOUNT_AMOUNT-
		 POSTTAXDISCOUNTAMOUNT)  
	  WHERE  MANUAL_ROUNDOFF=0  
	  

	  set @cstep=283.60
	  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       



	  UPDATE #tMsttable SET TOTAL_AMOUNT=(SUBTOTAL +CASE WHEN BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(@NTAX,0)+ISNULL(@TotalgstcessAmount,0) END +  
	  OTHER_CHARGES + isnull(tcs_amount,0)+  
			 CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE  ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+
			 ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0) END+
		  CASE WHEN ISNULL(FRIGHT_PAY_MODE,0)=2 THEN 0 ELSE  FREIGHT END +EXCISE_DUTY_AMOUNT+isnull(ROUND_OFF,0)) - 
		  DISCOUNT_AMOUNT  - POSTTAXDISCOUNTAMOUNT


     
	  declare @NTAXABLEVALUE numeric(18,2),@nxnitemtype int,@nbill_challan_mode int
	 select @nxnitemtype=xn_item_type,@nbill_challan_mode=bill_challan_mode  from #tMsttable --changes tcs calculate on total amount

	
	  set @cstep=284.50
	 IF EXISTS (SELECT TOP 1 'U' FROM LOCATION WHERE DEPT_ID =@CDEPT_ID AND ISNULL(Enable_Tcs,0)=1)
	   and exists (select top 1 'u' from TCS_MST where Wef <=@DMEMO_DT and isnull(Tcs_Type,0)=1 ) and isnull(@nxnitemtype,0)=1 and ISNULL(@nbill_challan_mode,0)=0
	  
	   BEGIN
	        
			select @NTAXABLEVALUE=sum(xn_value_without_gst)  from #tDetTable a (nolock)

			

		  EXEC SP3S_TCSCAL_pur 
		  @CXNTYPE='PUR',
		  @CLOCID=@CDEPT_ID,
		  @NTAXABLEVALUE=@NTAXABLEVALUE,
		  @NPARTY_AMOUNT_FORTCS=@NPARTY_AMOUNT_FORTCS,
		  @CERRORMSG=@CERRORMSG OUTPUT

		  IF ISNULL(@cErrormsg,'')<>''
		   GOTO END_PROC


	   END

	    --UPDATE #TMSTTABLE SET broker_tds_Amount=round((@NTAXABLEVALUE*broker_tds_percentage /100),2)

		set @cstep=285.50

	  --- Cd should not be calculated 1st April 2021 onwards as discussed (Task#33)
	  IF EXISTS(SELECT TOP 1 'U' FROM #tMstTable WHERE SUBTOTAL<>0 AND ISNULL(TERMS,'')<>'' and pim_mode<>5 AND fin_year<='01121') 
	  BEGIN
  
		  set @cstep=283.45
		  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

			  SELECT @cTerms=terms,@nSubtotal=subtotal,@nPimDiscount=discount_amount,@nTotalAmount=total_amount,@nTaxmethod=bill_level_tax_method
			  fROM #tMstTable

			  select @nTotaltax=sum(isnull(tax_amount,0)+ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)),
			         @TotalgstcessAmount=ROUND(SUM(ISNULL(gst_cess_Amount ,0)),3) 
			  from #tDetTable

			   set @ApplyCDOnTotal=SUBSTRING(@cTerms,DBO.CHARINDEX_NTH('-',@cTerms,1,10)+1,1)
     

		  set @cstep=283.47
		  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

		
			SELECT @nBaseAmount=DBO.FN3SREADLEDGERTERMS(@cTerms,4)
			

		  set @cstep=283.49
		  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       
			--GET THE TOTAL CASH DISCOUNT AMOUNT ON THE PURCHASE
			SELECT @NCASHDISCOUNTAMOUNT=@nBaseAmount/100.00*
		 				  (CASE WHEN @ApplyCDOnTotal='N'
		 				  THEN (@nSubtotal-@nPimDiscount-SUM(CASE WHEN @nTaxMethod=2 
		 				   THEN @nTotaltax  ELSE 0 END)) 
						   ELSE @nTOTALAMOUNT END)
			

		  set @cstep=283.51
		  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

			SET @NCASHDISCOUNTAMOUNT=ISNULL(@NCASHDISCOUNTAMOUNT,0)
		

			UPDATE #tDettable
			 SET CASHDISCOUNTAMOUNT=(@NCASHDISCOUNTAMOUNT/@nSUBTOTAL)*PURCHASE_PRICE
			 
	  END			   
  


	  set @cstep=283.55
	  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

	  UPDATE #tDettable SET XN_VALUE_WITHOUT_GST=((PURCHASE_PRICE*INVOICE_QUANTITY)-ISNULL(PIMDISCOUNTAMOUNT,0))
	  WHERE  ISNULL(XN_VALUE_WITHOUT_GST,0)=0


	  set @cstep=283.63
	 EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

	  UPDATE A SET TOTAL_CASHDISCOUNTAMOUNT=ISNULL(B.CASHDISCOUNTAMOUNT,0),
	               TDS_AMOUNT =cast(isnull(b.XN_VALUE_WITHOUT_GST,0)*a.TDS_PERCENTAGE /100 as numeric(14,2))
	  FROM #tMsttable A LEFT OUTER JOIN  
	  
	  (    
		   SELECT  SUM(CASHDISCOUNTAMOUNT) AS CASHDISCOUNTAMOUNT,
		           sum(isnull(XN_VALUE_WITHOUT_GST,0)) as XN_VALUE_WITHOUT_GST
		   FROM #tDettable
		   
	  ) B ON  1=1

	  
    DECLARE @cRoundTds VARCHAR(4)
    SELECT TOP 1 @cRoundTds=value from config where config_option='TDS_ROUNDING_MODE'
    
    IF ISNULL(@cRoundTds,'') in('1','2')
	begin
		UPDATE #TMSTTABLE SET TDS_AMOUNT= CASE WHEN ISNULL(@CROUNDTDS,'') =1 THEN ROUND(TDS_AMOUNT,0) 
		                      WHEN ISNULL(@CROUNDTDS,'') =2 THEN CEILING(TDS_AMOUNT) ELSE TDS_AMOUNT  END,
			                  GOODS_TDS_AMOUNT=CASE WHEN ISNULL(@CROUNDTDS,'') =1 THEN ROUND(GOODS_TDS_AMOUNT,0) 
		                      WHEN ISNULL(@CROUNDTDS,'') =2 THEN CEILING(GOODS_TDS_AMOUNT) ELSE GOODS_TDS_AMOUNT  END
	end
  	

   
   
 --  if @@spid=163
 --  begin
	--	select 'check tdet', box_no,product_code,igst_amount,cgst_amount,XN_VALUE_WITHOUT_GST,PIMDISCOUNTAMOUNT,
	--	iNVOICE_QUANTITY ,purchase_price from #tDetTable
	--	select subtotal,total_amount,discount_amount from #tMsttable
	--end

	  IF @BCALLEDFROMEKAYA=0
	  BEGIN

		  set @cstep=283.65
		  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

		  IF EXISTS (SELECT TOP 1 receipt_dt FROM #tMstTable where RECEIPT_DT>='2017-07-01')
			  UPDATE A SET GST_ROUND_OFF=(TOTAL_AMOUNT-(OTHER_CHARGES +isnull(tcs_amount,0)+
			     (CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE  ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+
				 ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+
				 ISNULL(FREIGHT_SGST_AMOUNT,0) END)+(CASE WHEN ISNULL(FRIGHT_PAY_MODE,0)=2 THEN 0 ELSE  FREIGHT END) +
				 EXCISE_DUTY_AMOUNT+ROUND_OFF  - POSTTAXDISCOUNTAMOUNT+B.NET_AMOUNT_GST))
				FROM #tMsttable A
				JOIN (SELECT SUM(XN_VALUE_WITHOUT_GST+IGST_AMOUNT+CGST_AMOUNT+SGST_AMOUNT+isnull(cess_amount,0)+isnull(gst_cess_Amount,0)) AS NET_AMOUNT_GST
					  FROM #tDettable
					  
					 ) B ON 1=1
	  END			 


	  set @cstep=283.68
	  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       

	SET @cCmd=N'update a set discount_amount=b.discount_amount,discount_percentage=b.discount_percentage, 
    excise_duty_amount=b.excise_duty_amount ,POSTTAXDISCOUNTAMOUNT=b.POSTTAXDISCOUNTAMOUNT ,
	subtotal=b.subtotal,total_amount=b.total_amount,
  TOTAL_CASHDISCOUNTAMOUNT=b.TOTAL_CASHDISCOUNTAMOUNT,TOTAL_QUANTITY=b.tOTAL_QUANTITY ,TOTAL_BOX_NO=b.TOTAL_BOX_NO,
  TOTAL_GST_AMOUNT=b.TOTAL_GST_AMOUNT,TOTAL_QUANTITY_STR=b.TOTAL_QUANTITY_STR,round_off=b.round_off,
  OTHER_CHARGES_IGST_AMOUNT=b.OTHER_CHARGES_IGST_AMOUNT,OTHER_CHARGES_cGST_AMOUNT=b.OTHER_CHARGES_cGST_AMOUNT,
  OTHER_CHARGES_sGST_AMOUNT=b.OTHER_CHARGES_sGST_AMOUNT,FREIGHT_IGST_AMOUNT=b.FREIGHT_IGST_AMOUNT,
  FREIGHT_cGST_AMOUNT=b.FREIGHT_cGST_AMOUNT,FREIGHT_sGST_AMOUNT=b.FREIGHT_sGST_AMOUNT,gst_round_off=b.gst_round_off,
   OTHER_CHARGES_HSN_CODE=b.OTHER_CHARGES_HSN_CODE,freight_hsn_code=b.freight_hsn_code,
   freight_gst_percentage=b.freight_gst_percentage,other_charges_gst_percentage=b.other_charges_gst_percentage,
  freight_taxable_value=b.freight_taxable_value,other_charges_taxable_value=b.other_charges_taxable_value,
  party_state_code=b.party_state_code,
  total_gst_cess_amount=b.total_gst_cess_amount,
  GOODS_TDS_BASEAMOUNT=isnull(b.GOODS_TDS_BASEAMOUNT,0),GOODS_TDS_PERCENTAGE=isnull(b.GOODS_TDS_PERCENTAGE,0),GOODS_TDS_AMOUNT=isnull(b.GOODS_TDS_AMOUNT,0) ,
  broker_tds_Amount=round(broker_comm_amount*broker_tds_percentage/100,2),
  TDS_AMOUNT=b.tds_amount
  
  from '+@CMstTable+'  a with (rowlock) join #tmsttable b on 1=1
  where '+ replace(@cWhereclause,'b.','a.')
	
print @cCmd
	EXEC SP_EXECUTESQL @cCmd
  
  

  set @cstep=283.71
  EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@NSPID,'',1       


  SET @cCmd=N'update a set tax_amount=b.tax_amount ,XN_VALUE_WITHOUT_GST=b.XN_VALUE_WITHOUT_GST ,igst_amount=b.igst_amount ,
		cgst_amount=b.cgst_amount ,sgst_amount=b.sgst_amount,
		 cashdiscountamount=b.cashdiscountamount ,PIMPOSTTAXDISCOUNTAMOUNT=b.PIMPOSTTAXDISCOUNTAMOUNT ,
		 PIMEXCISEDUTYAMOUNT=b.PIMEXCISEDUTYAMOUNT ,
		 cess_amount=b.cess_amount ,PIMDISCOUNTAMOUNT=b.PIMDISCOUNTAMOUNT ,
		 Gst_Cess_Percentage=b.Gst_Cess_Percentage,Gst_cess_Amount=b.Gst_cess_Amount,
		 XN_VALUE_WITH_GST=b.XN_VALUE_WITH_GST ,gst_percentage=b.gst_percentage ,ITEM_EXCISE_DUTY_PERCENTAGE=b.ITEM_EXCISE_DUTY_PERCENTAGE ,
		 ITEM_EXCISE_DUTY_amount=b.ITEM_EXCISE_DUTY_amount,hsn_code=b.hsn_code,TAX_ROUND_OFF=B.TAX_ROUND_OFF
		 from '+@cDEtTable+' a WITH (ROWLOCK)
		 JOIN #tDetTable b ON a.row_id=b.row_id WHERE '+replace(@cWhereclausePid,'b.','a.')
print @cCmd
EXEC SP_EXECUTESQL @cCmd   


   --AFTER GST AMOUNT SETOFF SOME DIFFERENCE IN EXISTING gst amount need to overwite gst amount 
      IF @NUPDATEMODE =2 and @NBOXUPDATEMODE>0
	  BEGIN
	      
		  UPDATE A SET XN_VALUE_WITHOUT_GST =B.XN_VALUE_WITHOUT_GST ,
		               CGST_AMOUNT =B.CGST_AMOUNT ,
		               SGST_AMOUNT =B.SGST_AMOUNT ,
		               IGST_AMOUNT =B.IGST_AMOUNT,
		               GST_PERCENTAGE =B.GST_PERCENTAGE ,
		               xn_value_with_gst =b.xn_value_with_gst,
		              TAX_ROUND_OFF=B.TAX_ROUND_OFF 
		  FROM Pid01106 A (NOLOCK)
		  JOIN #TDETTABLE B ON A.ROW_ID =B.ROW_ID 
		  WHERE A.mrr_id =@cMrrId
		  and (a.CGST_AMOUNT+a.SGST_AMOUNT+a.IGST_AMOUNT)<>(b.CGST_AMOUNT+b.SGST_AMOUNT+b.IGST_AMOUNT)

	  END

		
END TRY

BEGIN CATCH
	print 'enter catch of sp3s_caltotals_pur'
	set @cErrormsg=' Error in Procedure sp3s_caltotals_pur at Step#'+@cStep+' '+error_message()
	goto end_proc
END CATCH

end_proc:
END

