CREATE PROCEDURE SP3S_CALTOTALS_PRT --(LocId 3 digit change only increased the parameter width by Sanjay:04-11-2024)
@nUpdatemode NUMERIC(2,0),
@nSpId VARCHAR(40)='',
@cRmId VARCHAR(40)='',
@NBOXUPDATEMODE NUMERIC(1,0)=0, 
@bcalledfrompackslip bit=0,
@CERRORMSG VARCHAR(MAX) OUTPUT,
@cLocationId varchar(4)=''
AS
BEGIN
	DECLARE @cStep VARCHAR(5),@DMEMO_DT datetime,@ApplyCDOnTotal varchar(5),@nDnType NUMERIC(1,0),@NMODE NUMERIC(1,0),	
	@cTerms VARCHAR(500),@nBaseAmount NUMERIC(20,2),@NTAX numeric(10,2),@CGSTCUTOFFDATE varchar(10),@gstdate datetime,@NEXCISEDUTY numeric(10,2),
	@nSubtotal numeric(14,2),@nPimDiscount numeric(14,2),@nTotalAmount numeric(14,2),@nTaxmethod numeric(1,0),@nTotalTax numeric(10,2),
	@NCASHDISCOUNTAMOUNT numeric(14,2),@cCmd NVARCHAR(MAX),@cTempMasterTable VARCHAR(200),@cTempDetailTable VARCHAR(200),
	@cInsSPId varchar(50),@cMstTable VARCHAR(200),@cDetTable VARCHAR(200),@cWhereClause VARCHAR(200),@cWhereClauseRmd VARCHAR(200),
	@cKeyField VARCHAR(200)


BEGIN TRY


	
	SET @cStep=10

	SET @CINSSPID=LEFT(@nSpId,38)+'ZZZ'
	IF @nUpdatemode NOT IN (1,2)
		SELECT @cMstTable='rmm01106',@cDetTable='rmd01106',@cWhereClause='a.rm_id='''+@cRmId+'''',
		@cKeyField='rm_id',
		@cWhereClauseRmd='a.rm_id='''+@cRmId+''''
	ELSE
		SELECT @cMstTable='prt_rmm01106_upload',@cDetTable='prt_rmd01106_upload',
		@cWhereClause='sp_id='''+@nSpId+'''',@cKeyField='sp_id',
		@cWhereClauseRmd='sp_id='''+@nSpId+''''+(case when   @NBOXUPDATEMODE=0 AND @bcalledfrompackslip=0 then '' else ' or sp_id='''+@CINSSPID+'''' end)
	
	SET @cStep=10.4
	SELECT ac_code,party_dept_id,FREIGHT_HSN_CODE,OTHER_CHARGES_HSN_CODE,PARTY_STATE_CODE,EXCISE_DUTY_AMOUNT,DISCOUNT_AMOUNT,subtotal,rm_dt,
	 dn_type, TOTAL_QUANTITY_STR,TOTAL_QUANTITY,TOTAL_BOX_NO,Total_Gst_Amount,MANUAL_DISCOUNT,DISCOUNT_PERCENTAGE,
	 OTHER_CHARGES,round_off,manual_roundoff,OTHER_CHARGES_IGST_AMOUNT,OTHER_CHARGES_cGST_AMOUNT,OTHER_CHARGES_sGST_AMOUNT,
	FREIGHT_IGST_AMOUNT,FREIGHT_cGST_AMOUNT,FREIGHT_sGST_AMOUNT,OH_TAX_METHOD,GST_ROUND_OFF,total_amount,OTHER_CHARGES_TAXABLE_VALUE,
	FREIGHT_TAXABLE_VALUE,freight,mode,ACCOUNTS_DEPT_ID,RefMemoID,DO_NOT_CALC_GST_OH,FREIGHT_GST_PERCENTAGE,other_charges_gst_percentage,
	Total_Gst_cess_amount, broker_tds_percentage, broker_tds_Amount,broker_comm_amount ,SHIPPING_AC_CODE ,MANUAL_GST_PER_FREIGHT,MANUAL_GST_PER_OTH
	INTO  #tPrtMstTable FROM rmm01106 (NOLOCK) WHERE 1=2
	
	SET @cStep=10.6

	select hsn_code,GST_PERCENTAGE,igst_amount,cgst_amount,sgst_amount,xn_value_without_gst,xn_value_with_gst,bill_level_tax_method,
	RMMDISCOUNTAMOUNT,purchase_price,invoice_quantity,bill_dt,ITEM_EXCISE_DUTY_PERCENTAGE,excise_duty_amount,item_form_id,
	item_tax_percentage,item_tax_amount,product_code,dn_discount_amount,manual_discount,gross_purchase_price,dn_discount_percentage,
	PRTAmount,FDN_Rate,quantity,box_no,DISCOUNT_PERCENTAGE,DISCOUNT_amount,CESS_AMOUNT,row_id,
	Gst_cess_percentage,Gst_cess_amount,bill_no,TAX_ROUND_OFF
	into #tPrtDetTable FROM rmd01106 (NOLOCK) WHERE 1=2
	
	SET @cStep=10.8
	SET @cCmd=N'SELECT ac_code,party_dept_id,FREIGHT_HSN_CODE,OTHER_CHARGES_HSN_CODE,PARTY_STATE_CODE,EXCISE_DUTY_AMOUNT,DISCOUNT_AMOUNT,subtotal,rm_dt,
	 dn_type, TOTAL_QUANTITY_STR,TOTAL_QUANTITY,TOTAL_BOX_NO,Total_Gst_Amount,MANUAL_DISCOUNT,DISCOUNT_PERCENTAGE,
	 OTHER_CHARGES,freight,round_off,manual_roundoff,OTHER_CHARGES_IGST_AMOUNT,OTHER_CHARGES_cGST_AMOUNT,OTHER_CHARGES_sGST_AMOUNT,
	FREIGHT_IGST_AMOUNT,FREIGHT_cGST_AMOUNT,FREIGHT_sGST_AMOUNT,OH_TAX_METHOD,GST_ROUND_OFF,total_amount,mode,ACCOUNTS_DEPT_ID,
	RefMemoID,DO_NOT_CALC_GST_OH, broker_tds_percentage, broker_tds_Amount,broker_comm_amount ,a.SHIPPING_AC_CODE,MANUAL_GST_PER_FREIGHT,MANUAL_GST_PER_OTH,
	FREIGHT_GST_PERCENTAGE,other_charges_gst_percentage 
	FROM '+@cMstTable+' a WHERE '+@cWhereClause


	INSERT #tPrtMstTable (ac_code,party_dept_id,FREIGHT_HSN_CODE,OTHER_CHARGES_HSN_CODE,PARTY_STATE_CODE,EXCISE_DUTY_AMOUNT,DISCOUNT_AMOUNT,subtotal,rm_dt,
	 dn_type, TOTAL_QUANTITY_STR,TOTAL_QUANTITY,TOTAL_BOX_NO,Total_Gst_Amount,MANUAL_DISCOUNT,DISCOUNT_PERCENTAGE,
	 OTHER_CHARGES,freight,round_off,manual_roundoff,OTHER_CHARGES_IGST_AMOUNT,OTHER_CHARGES_cGST_AMOUNT,OTHER_CHARGES_sGST_AMOUNT,
	FREIGHT_IGST_AMOUNT,FREIGHT_cGST_AMOUNT,FREIGHT_sGST_AMOUNT,OH_TAX_METHOD,GST_ROUND_OFF,total_amount,mode,ACCOUNTS_DEPT_ID,RefMemoID,DO_NOT_CALC_GST_OH,
	 broker_tds_percentage, broker_tds_Amount,broker_comm_amount,SHIPPING_AC_CODE,MANUAL_GST_PER_FREIGHT,MANUAL_GST_PER_OTH,FREIGHT_GST_PERCENTAGE,other_charges_gst_percentage  )
	EXEC SP_EXECUTESQL @cCmd

	

	SET @cStep=12
	SET @cCmd=N'SELECT hsn_code,GST_PERCENTAGE,igst_amount,cgst_amount,sgst_amount,xn_value_without_gst,xn_value_with_gst,bill_level_tax_method,
	RMMDISCOUNTAMOUNT,purchase_price,invoice_quantity,bill_dt,ITEM_EXCISE_DUTY_PERCENTAGE,ISNULL(excise_duty_amount,0) AS excise_duty_amount,item_form_id,
	item_tax_percentage,item_tax_amount,product_code,
	isnull(dn_discount_amount,0) as dn_discount_amount,manual_discount,
	ISNULL(gross_purchase_price,0) as gross_purchase_price,
	dn_discount_percentage,
	PRTAmount,FDN_Rate,quantity,box_no,DISCOUNT_PERCENTAGE,
	isnull(DISCOUNT_amount,0) as DISCOUNT_amount,
	CESS_AMOUNT,row_id,bill_no,a.TAX_ROUND_OFF
	FROM '+@cDetTable+' a WHERE '+@cWhereClauseRmd
	

	
	--@cWhereClauseRmd change by @cWhereClause
	
	print @cCmd
	INSERT #tPrtDetTable (hsn_code,GST_PERCENTAGE,igst_amount,cgst_amount,sgst_amount,xn_value_without_gst,xn_value_with_gst,bill_level_tax_method,
	RMMDISCOUNTAMOUNT,purchase_price,invoice_quantity,bill_dt,ITEM_EXCISE_DUTY_PERCENTAGE,excise_duty_amount,item_form_id,
	item_tax_percentage,item_tax_amount,product_code,dn_discount_amount,manual_discount,gross_purchase_price,dn_discount_percentage,
	PRTAmount,FDN_Rate,quantity,box_no,DISCOUNT_PERCENTAGE,DISCOUNT_amount,CESS_AMOUNT,row_id,bill_no,TAX_ROUND_OFF)
	EXEC SP_EXECUTESQL @cCmd

	SET @cSTEP=12.6
	UPDATE #tPrtDetTable with (rowlock) SET HSN_CODE='0000000000',GST_PERCENTAGE=0,IGST_AMOUNT=0,CGST_AMOUNT=0,SGST_AMOUNT=0,
	XN_VALUE_WITHOUT_GST=0,
	XN_VALUE_WITH_GST=0  ,
    Gst_cess_Percentage=0,
	Gst_cess_Amount=0
	WHERE  ISNULL(HSN_CODE,'')=''
		
	SET @cStep=127
	SET @CCMD = N'UPDATE #tPrtMstTable  SET FREIGHT_HSN_CODE= CASE WHEN ISNULL(FREIGHT_HSN_CODE,'''')='''' THEN ''0000000000'' ELSE FREIGHT_HSN_CODE END,
		            OTHER_CHARGES_HSN_CODE= CASE WHEN ISNULL(OTHER_CHARGES_HSN_CODE,'''')='''' THEN ''0000000000'' ELSE OTHER_CHARGES_HSN_CODE END '
		              
	EXEC SP_EXECUTESQL @CCMD 
	
	
	
	
		SET @cStep=128
		SET @CCMD = 'UPDATE #tPrtMstTable  SET PARTY_STATE_CODE=''00'' WHERE ISNULL(PARTY_STATE_CODE,'''')='''''
		EXEC SP_EXECUTESQL @CCMD 
		
		SET @cStep=129
	
	
		SET @CCMD = 'UPDATE #tPrtDetTable   SET BILL_LEVEL_TAX_METHOD=2 where  BILL_LEVEL_TAX_METHOD=0 '
		EXEC SP_EXECUTESQL @CCMD
		
		

		--CALCULATE RMMDISCOUNTAMOUN

		UPDATE A SET SUBTOTAL = ISNULL(B.SUBTOTAL,0),
		             TOTAL_QUANTITY=ISNULL(B.INVOICE_QUANTITY,0),
		             TOTAL_BOX_NO=ISNULL(B.TOTAL_BOX_NO,0)
		             
		FROM #tPrtMstTable A LEFT OUTER JOIN
		( 	
			SELECT	SUM((CONVERT(NUMERIC(18,4),PURCHASE_PRICE)*INVOICE_QUANTITY)) AS SUBTOTAL, ---(INVOICE_QUANTITY*CONVERT(NUMERIC(18,4),FDN_RATE,0)))
			               SUM(QUANTITY) AS INVOICE_QUANTITY,COUNT(DISTINCT BOX_NO)TOTAL_BOX_NO
			FROM #tPrtDetTable
		) B ON  1=1

		


		UPDATE #tPrtMstTable SET DISCOUNT_AMOUNT =(CASE WHEN isnull(MANUAL_DISCOUNT,0)=0 OR @bcalledfrompackslip=1 OR @NBOXUPDATEMODE=1
		THEN (SUBTOTAL*DISCOUNT_PERCENTAGE/100) 	ELSE DISCOUNT_AMOUNT END)

		
       SET @cStep = 510
	   DECLARE @NTOTAL_DISCOUNT_AMOUNT NUMERIC(10,2)
	   SELECT   @NTOTAL_DISCOUNT_AMOUNT= ISNULL(DISCOUNT_AMOUNT,0)  FROM  #tPrtMstTable  A


    
	
	
       SET @CCMD = N'UPDATE A SET RMMDISCOUNTAMOUNT=ROUND((CASE WHEN B.SUBTOTAL=0 THEN 0 ELSE (B.DISCOUNT_AMOUNT/B.SUBTOTAL)*(A.PURCHASE_PRICE*A.INVOICE_QUANTITY) END),2)
	    FROM #tPrtDetTable A  with (rowlock)
	    JOIN  #tPrtMstTable  B (NOLOCK) ON 1=1'

		print @cCmd
	   EXEC SP_EXECUTESQL @CCMD 
	   
		IF ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)<>0
	   BEGIN 
	    
		   EXEC SP3S_REPROCESS_PRT_BILL_DISCOUNT @NSPID,@CERRORMSG OUTPUT 
		   IF ISNULL(@CERRORMSG,'')<>''
		   GOTO END_PROC  
	   END  
		   
		
		--GST CALCULATION
		DECLARE @DINV_DT DATETIME,@BCALCULATEGSTPRT BIT,@DONOTENFORCEBILLSELECTION BIT
        SELECT @CGSTCUTOFFDATE=VALUE FROM CONFIG WHERE CONFIG_OPTION ='GST_CUT_OFF_DATE'
        SELECT @DONOTENFORCEBILLSELECTION=VALUE FROM CONFIG (NOLOCK) WHERE CONFIG_OPTION='DO_NOT_ENFORCE_BILL_SELECTION' 
        SET @BCALCULATEGSTPRT=0
        SELECT @NMODE=MODE,@DMEMO_DT=RM_DT,@nDnType=DN_TYPE FROM #tPrtMstTable
	    		
		SET @cStep=130
	
		
		IF @DMEMO_DT>'2017-06-30' AND @nDnType=1 AND @DONOTENFORCEBILLSELECTION=0
		BEGIN
			IF EXISTS(SELECT TOP 1 'U'  FROM #tPrtDetTable (NOLOCK) WHERE BILL_DT='' )
			begin
				SET @CERRORMSG=' PURCHASE BILL DATE CAN NOT BE BLANK PLEASE CHECK '
				GOTO END_PROC	 
			end
        END
        	
        IF @CGSTCUTOFFDATE<>''
           SELECT @GSTDATE=CAST(@CGSTCUTOFFDATE AS DATETIME)
           SET @cStep=135
   
     --   SET @CCMD=N'SELECT TOP 1 @DINV_DT=BILL_DT FROM '+@CTEMPDETAILTABLE+' WHERE BILL_DT>''2017-06-30'''
	    --EXEC SP_EXECUTESQL @CCMD,N'@DINV_DT DATETIME OUTPUT ',@DINV_DT OUTPUT	 
		
	
        IF ISNULL(@DMEMO_DT ,'')>'2017-06-30'
			SET @BCALCULATEGSTPRT =1
		ELSE
			SET @BCALCULATEGSTPRT =0 --CONDITION ON ITEM LEVEL
		
        IF @BCALCULATEGSTPRT=1
        BEGIN
			SET @cStep=135.2
             DECLARE @BGROUP BIT
	         SET @BGROUP=0
	         
		     IF @NMODE=2
				 SET @BGROUP=1 
				 
			Declare @CDONOT_CALCULATE_GST_SOR_LOC varchar(5) 	
			
			if @NMODE=2
			begin
			
				IF EXISTS (SELECT TOP 1 'U' FROM LOCATION (NOLOCK) WHERE DEPT_ID=@cLocationId AND SOR_LOC =1)
				SELECT TOP 1 @CDONOT_CALCULATE_GST_SOR_LOC=VALUE FROM CONFIG WHERE CONFIG_OPTION ='DONOT_CALCULATE_GST_FOR_SOR_LOCATION'
				
			end 
			 
			if ISNULL(@CDONOT_CALCULATE_GST_SOR_LOC,'')<>'1'
			begin
			
				print 'Fdn gst-1'
				EXEC SP3S_GST_TAX_CAL 'PRT',@cRmId,@DMEMO_DT,@NSPID,'',0,@BGROUP,'',@CERRORMSG OUTPUT,@cLocationId=@cLocationId
				IF ISNULL(@CERRORMSG,'')<>''
				GOTO END_PROC 
				
			end 
			Else 
			begin
			    
			    SET @CCMD = N'UPDATE  a SET HSN_CODE=b.hsn_code ,GST_PERCENTAGE=0,IGST_AMOUNT=0,
				CGST_AMOUNT=0,SGST_AMOUNT=0,
				XN_VALUE_WITHOUT_GST=(a.purchase_price *a.quantity)-isnull(a.RMMDISCOUNTAMOUNT,0),
				XN_VALUE_WITH_GST=(a.purchase_price *a.quantity)-isnull(a.RMMDISCOUNTAMOUNT,0),
				GST_CESS_PERCENTAGE=0,GST_CESS_AMOUNT=0
				FROM #TPRTDETTABLE A
				JOIN SKU B (NOLOCK) ON A.PRODUCT_CODE=B.PRODUCT_CODE '
				EXEC SP_EXECUTESQL @CCMD 
			
			end

			print 'Fdn gst-2'
			SET @cStep=135.4
			SET @CCMD = N'UPDATE #tPrtDetTable SET ITEM_EXCISE_DUTY_PERCENTAGE=0 , EXCISE_DUTY_AMOUNT=0, 
			ITEM_FORM_ID=''0000000'', ITEM_TAX_PERCENTAGE=0, ITEM_TAX_AMOUNT=0 '
			PRINT @cCmd
			EXEC SP_EXECUTESQL @CCMD
	    
	    END
	    ELSE
	    BEGIN
	       	SET @cStep=135.6
			SET @CCMD = N'UPDATE #tPrtDetTable WITH (ROWLOCK) SET HSN_CODE=''0000000000'',GST_PERCENTAGE=0,IGST_AMOUNT=0,
			CGST_AMOUNT=0,SGST_AMOUNT=0,XN_VALUE_WITHOUT_GST=0,XN_VALUE_WITH_GST=0,Gst_cess_Percentage=0,Gst_cess_Amount=0 '
			EXEC SP_EXECUTESQL @CCMD 
			
			SET @CCMD = 'UPDATE #tPrtMstTable WITH (ROWLOCK) SET PARTY_STATE_CODE=''00'''
			EXEC SP_EXECUTESQL @CCMD 
	    
	    END
		
		SET @cStep=135.8
	    SET @CCMD = N'UPDATE #tPrtMstTable  WITH (ROWLOCK) SET 
	              OTHER_CHARGES_HSN_CODE=CASE WHEN OTHER_CHARGES=0 THEN ''0000000000'' ELSE OTHER_CHARGES_HSN_CODE END,
	              FREIGHT_HSN_CODE=CASE WHEN FREIGHT=0 THEN ''0000000000'' ELSE FREIGHT_HSN_CODE END
	              '
	  EXEC SP_EXECUTESQL @CCMD
		

LBLRECALAMOUNT:
		

		 IF @BCALCULATEGSTPRT=1 
	     BEGIN    
			SET @cStep=136.1
			  EXEC SP3S_REPROCESS_GST_CALCULATION '','PRT',0,@CERRORMSG OUTPUT 
			  IF ISNULL(@CERRORMSG,'')<>''
			  GOTO END_PROC
	     END

		
	 
	 SET @cStep=136.3
		DECLARE @BSKIPRECAL BIT
		
		SET @BSKIPRECAL=0
		
		IF @nDnType=2
		BEGIN
			SET @BSKIPRECAL=1
			IF EXISTS (SELECT TOP 1 PRODUCT_CODE FROM #tPrtDetTable )
				SET @BSKIPRECAL=0
		END
		
		SET @cStep=136.5
		IF @BSKIPRECAL=1
			GOTO END_PROC
			
		SET @cStep = 155
		DECLARE @NEXCLTAX NUMERIC(10,2), @NGSTCESSAMOUNT NUMERIC(10,2),@ntotaltaxable_value numeric(18,2)
		
		SELECT @NEXCISEDUTY=SUM(EXCISE_DUTY_AMOUNT) ,
		       @ntotaltaxable_value=sum(xn_value_without_gst)
		FROM #tPrtDetTable
		
		SET @NEXCISEDUTY=ISNULL(@NEXCISEDUTY,0)
		
		UPDATE #tPrtDetTable SET DN_DISCOUNT_AMOUNT=(CASE WHEN MANUAL_DISCOUNT=0 THEN (GROSS_PURCHASE_PRICE*INVOICE_QUANTITY*DN_DISCOUNT_PERCENTAGE)/100 ELSE DN_DISCOUNT_AMOUNT END)
		
		
		UPDATE #tPrtDetTable SET PRTAMOUNT=FDN_RATE*INVOICE_QUANTITY
		
		
		SET @cStep = 156 --- DONT REMOVE IT (SUMIT)
		
		

		DECLARE @STR VARCHAR(MAX),@STR1 VARCHAR(MAX)
		SET @STR=NULL
		SET @STR1=NULL

		SELECT  @STR =  COALESCE(@STR +  '/ ', ' ' ) + (''+C.UOM_NAME+': '+CAST(SUM(QUANTITY) AS VARCHAR) +' ')  
		 FROM #tPrtDetTable A  
		 JOIN SKU S (NOLOCK) ON S.PRODUCT_CODE=A.PRODUCT_CODE
		 JOIN ARTICLE B (NOLOCK) ON S.ARTICLE_CODE=B.ARTICLE_CODE
		JOIN UOM C (NOLOCK) ON C.UOM_CODE=B.UOM_CODE
		 GROUP BY C.UOM_NAME
		
		
		UPDATE #tPrtMstTable SET TOTAL_QUANTITY_STR =@STR ,broker_tds_Amount=@ntotaltaxable_value*broker_tds_percentage/100
	
		
		
		SET @cStep = 157
		-- UPDATING TOTALS IN RMM TABLE
		UPDATE A SET Total_Gst_Amount=isnull(B.GST_AMOUNT ,0),subtotal=isnull(b.subtotal,0),
		             Total_Gst_cess_amount=isnull(b.GSt_Cess_Amount,0)
		FROM #tPrtMstTable A LEFT OUTER JOIN
		( 	
			SELECT	SUM((CONVERT(NUMERIC(18,4),PURCHASE_PRICE)*INVOICE_QUANTITY)) AS SUBTOTAL,
			             SUM(ISNULL(IGST_AMOUNT,0)+ ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)) AS GST_AMOUNT,
						 SUM(ISNULL(GSt_Cess_Amount,0)) as GSt_Cess_Amount
			FROM #tPrtDetTable
		) B ON  1=1

		
       
		
		SET @cStep = 160
		SELECT @NSUBTOTAL=SUBTOTAL FROM #tPrtMstTable
		
		--FIND GST CUT OFF DATE & AFTER 1 JULY 2017 CALCULATE GST
		
        	
			
		SET @cStep = 165
			
 
		IF NOT EXISTS (SELECT TOP 1 PRODUCT_CODE FROM #tPrtDetTable )
		BEGIN
			SET @cStep = 170
			UPDATE #tPrtMstTable with (rowlock)  SET OTHER_CHARGES=0,EXCISE_DUTY_AMOUNT=0,FREIGHT=0
			
		END
	
		SELECT @NEXCLTAX=SUM(ITEM_TAX_AMOUNT+ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(CESS_AMOUNT,0)) ,
		       @NGSTCESSAMOUNT=SUM(ISNULL(Gst_cess_amount,0))
		FROM #tPrtDetTable WHERE BILL_LEVEL_TAX_METHOD=1

		
		
		SET @cStep = 180		
		UPDATE #tPrtMstTable SET ROUND_OFF=(CASE WHEN MANUAL_ROUNDOFF=0 THEN (ROUND((SUBTOTAL +ISNULL(@NEXCLTAX,0) +isnull(@NGSTCESSAMOUNT,0)+  OTHER_CHARGES + 
		            CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE  ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0) END +
					 FREIGHT+@NEXCISEDUTY ) - DISCOUNT_AMOUNT,0)-
					 (SUBTOTAL+ISNULL(@NEXCLTAX,0)+isnull(@NGSTCESSAMOUNT,0)+OTHER_CHARGES+
					 CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0) END +
					 FREIGHT-DISCOUNT_AMOUNT+@NEXCISEDUTY))
					 ELSE ROUND_OFF END)
		
			
		SET @cStep=190
		
		UPDATE #tPrtMstTable SET EXCISE_DUTY_AMOUNT=@NEXCISEDUTY
		,TOTAL_AMOUNT=(SUBTOTAL +ISNULL(@NEXCLTAX,0) +isnull(@NGSTCESSAMOUNT,0)+  OTHER_CHARGES + 
		CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE  ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+
		ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+
		ISNULL(FREIGHT_SGST_AMOUNT,0) END + FREIGHT+ROUND_OFF) - DISCOUNT_AMOUNT+@NEXCISEDUTY
		

		
			
		SET @cStep=192	
		


		IF EXISTS (SELECT TOP 1 total_amount FROM #tPrtMstTable WHERE  RM_DT>='2017-07-01')		
			UPDATE A SET GST_ROUND_OFF=(TOTAL_AMOUNT-(ISNULL(OTHER_CHARGES_TAXABLE_VALUE,0)+ISNULL(FREIGHT_TAXABLE_VALUE,0)+
			ROUND_OFF+B.NET_AMOUNT_GST+isnull(b.GST_CESS_Amount,0)+ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0)
			+ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)
			))
			FROM #tPrtMstTable A 
			JOIN (SELECT SUM(XN_VALUE_WITHOUT_GST+IGST_AMOUNT+CGST_AMOUNT+SGST_AMOUNT+ISNULL(CESS_AMOUNT,0)) AS NET_AMOUNT_GST,
			             SUM(GST_CESS_Amount) AS GST_CESS_Amount
				  FROM #tPrtDetTable A
				  
				 ) B ON 1=1

		
		set @cStep=194
		   SET @cCmd=N' UPDATE a SET FREIGHT_HSN_CODE=b.FREIGHT_HSN_CODE,OTHER_CHARGES_HSN_CODE=b.OTHER_CHARGES_HSN_CODE,PARTY_STATE_CODE=b.PARTY_STATE_CODE,
			DISCOUNT_AMOUNT=b.DISCOUNT_AMOUNT,
			 TOTAL_QUANTITY_STR=b.TOTAL_QUANTITY_STR,SUBTOTAL=b.SUBTOTAL,TOTAL_QUANTITY=b.TOTAL_QUANTITY,TOTAL_BOX_NO=b.TOTAL_BOX_NO,
			 Total_Gst_Amount=b.Total_Gst_Amount,MANUAL_DISCOUNT=b.MANUAL_DISCOUNT,DISCOUNT_PERCENTAGE=b.DISCOUNT_PERCENTAGE,
			 EXCISE_DUTY_AMOUNT=b.EXCISE_DUTY_AMOUNT,round_off=b.round_off,OTHER_CHARGES_IGST_AMOUNT=b.OTHER_CHARGES_IGST_AMOUNT,
			 OTHER_CHARGES_cGST_AMOUNT=b.OTHER_CHARGES_cGST_AMOUNT,OTHER_CHARGES_sGST_AMOUNT=b.OTHER_CHARGES_sGST_AMOUNT,
			FREIGHT_IGST_AMOUNT=b.FREIGHT_IGST_AMOUNT,FREIGHT_cGST_AMOUNT=b.FREIGHT_cGST_AMOUNT,FREIGHT_sGST_AMOUNT=b.FREIGHT_sGST_AMOUNT,
			GST_ROUND_OFF=b.GST_ROUND_OFF,total_amount=b.total_amount,OTHER_CHARGES_TAXABLE_VALUE=b.OTHER_CHARGES_TAXABLE_VALUE,
			FREIGHT_TAXABLE_VALUE=b.FREIGHT_TAXABLE_VALUE,FREIGHT_GST_PERCENTAGE=b.FREIGHT_GST_PERCENTAGE,
			other_charges_gst_percentage=b.other_charges_gst_percentage,
			Total_Gst_cess_amount=b.Total_Gst_cess_amount,
			broker_tds_Amount=b.broker_tds_Amount,
			broker_comm_amount=isnull(b.broker_tds_Amount,0)*isnull(a.broker_comm_percentage,0)/100
			FROM '+@cMstTable+' A JOIN #tPrtMstTable b ON 1=1 WHERE '+@cWhereClause
			
			print @cCmd
			EXEC SP_EXECUTESQL @cCmd
		
		set @cStep=196
			SET @cCmd=N'UPDATE a SET hsn_code=b.hsn_code,GST_PERCENTAGE=b.GST_PERCENTAGE,igst_amount=b.igst_amount,cgst_amount=b.cgst_amount,
			sgst_amount=b.sgst_amount,xn_value_without_gst=b.xn_value_without_gst,xn_value_with_gst=b.xn_value_with_gst,bill_level_tax_method=b.bill_level_tax_method,
			RMMDISCOUNTAMOUNT=b.RMMDISCOUNTAMOUNT,ITEM_EXCISE_DUTY_PERCENTAGE=b.ITEM_EXCISE_DUTY_PERCENTAGE,excise_duty_amount=b.excise_duty_amount,
			item_form_id=b.item_form_id,item_tax_percentage=b.item_tax_percentage,item_tax_amount=b.item_tax_amount,dn_discount_amount=b.dn_discount_amount,
			PRTAmount=b.PRTAmount,DISCOUNT_PERCENTAGE=b.DISCOUNT_PERCENTAGE,DISCOUNT_amount=b.DISCOUNT_amount,CESS_AMOUNT=b.CESS_AMOUNT,
			Gst_cess_percentage=b.Gst_cess_percentage,Gst_cess_amount=b.Gst_cess_amount,TAX_ROUND_OFF=B.TAX_ROUND_OFF
			FROM  '+@cDetTable+' A JOIN #tPrtDetTable b ON a.row_id=b.row_id WHERE '+@cWhereClauseRmd
			print @cCmd

			EXEC SP_EXECUTESQL @cCmd
			
	IF @NUPDATEMODE =2 and @NBOXUPDATEMODE>0
	  BEGIN
	      
		  UPDATE A SET XN_VALUE_WITHOUT_GST =B.XN_VALUE_WITHOUT_GST ,
		               CGST_AMOUNT =B.CGST_AMOUNT ,
		               SGST_AMOUNT =B.SGST_AMOUNT ,
		               IGST_AMOUNT =B.IGST_AMOUNT,
		               GST_PERCENTAGE =B.GST_PERCENTAGE ,
		               xn_value_with_gst =b.xn_value_with_gst ,
		               TAX_ROUND_OFF=B.TAX_ROUND_OFF
		  FROM rmd01106  A (NOLOCK)
		  JOIN #tPrtDetTable B ON A.ROW_ID =B.ROW_ID 
		  WHERE A.rm_id  =@cRmId
		  and (a.CGST_AMOUNT+a.SGST_AMOUNT+a.IGST_AMOUNT)<>(b.CGST_AMOUNT+b.SGST_AMOUNT+b.IGST_AMOUNT)

	  END
	  
			--#tPrtDetTable
	
	--if @@spid=124
	--begin
	--	----select 'chk mst',rm_dt,@BCALCULATEGSTPRT as CALCULATEGSTPRT,total_amount,SUBTOTAL , ROUND_OFF , OTHER_CHARGES , FREIGHT - DISCOUNT_AMOUNT
	--	-- ,OTHER_CHARGES_IGST_AMOUNT,OTHER_CHARGES_CGST_AMOUNT,OTHER_CHARGES_SGST_AMOUNT,
	--	-- FREIGHT_IGST_AMOUNT,FREIGHT_CGST_AMOUNT,FREIGHT_SGST_AMOUNT,OH_TAX_METHOD from #tprtmsttable
	--	--	select 'chk tdet',product_code, * from #tprtdettable

	--	--	select 'chk gsttaxcalc ',hsn_code,* from gst_taxinfo_calc where sp_id=@nSpid
	--	--	select 'chk gsthsnm ',hsn_code,* from gst_xns_hsn where sp_id=@nSpid
			
	--end


END TRY

BEGIN CATCH
	print 'enter catch of sp3s_caltotals_prt'
	SET @CERRORMSG='Error in Procedure sp3s_caltotals_prt at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:        
   
END

