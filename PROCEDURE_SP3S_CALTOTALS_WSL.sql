create PROCEDURE SP3S_CALTOTALS_WSL--(LocId 3 digit change  by Sanjay:06-11-2024)
@nUpdatemode NUMERIC(2,0),
@nSpId VARCHAR(40)='',
@cInvId VARCHAR(40)='',
@bGstBill BIT,
@COUNTRY VARCHAR(50),
@NLOCREGISTER NUMERIC(1,0),
@bcallfrompackslip BIT=0,
@NBOXUPDATEMODE NUMERIC(1,0)=0,
@CERRORMSG VARCHAR(MAX) OUTPUT,
@CLOCID VARCHAR(4)='',
@EDIT_CLICKED bit=0,
@NPARTY_AMOUNT_FORTCS NUMERIC(18,2)=0
AS
BEGIN


	
BEGIN TRY
		DECLARE @NSUBTOTAL NUMERIC(14,2),@NTAX NUMERIC(14,4),@cStep VARCHAR(104),@cMstTable VARCHAR(200),
		@cDetTable VARCHAR(200),@cWhereClause VARCHAR(200),@cWhereClauseInd VARCHAR(200),@cCmd NVARCHAR(MAX),@cKeyField VARCHAR(200),@nTotalCustomDuty NUMERIC(10,2),
		@bGroupInv BIT,@cPayModeTable VARCHAR(200),@cPartyStatecode VARCHAR(50),@DINVDT DATETIME,@CERRPRODUCTCODE VARCHAR(50),
		@NGSTCESSAMOUNT NUMERIC(14,4),@lDonotRecalGst BIT,@bDoNotDebitGoodsTCS bit 

		SET @lDonotRecalGst=0
		set @bDoNotDebitGoodsTCS=0
		--IF (@EDIT_CLICKED=0 AND @nBoxUpdatemode=1) OR @NUPDATEMODE=1
		--	SET @lDonotRecalGst=1
		
		IF @nSpId=''
			SET @nSpId=CONVERT(VARCHAR(40),NEWID())

		SET @cStep = 195
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
		IF OBJECT_ID('tempdb..#tMstTable','U') IS NOT NULL
			DROP TABLE #tMstTable

		IF OBJECT_ID('tempdb..#tDetTable','U') IS NOT NULL
			DROP TABLE #tDetTable

		IF OBJECT_ID('tempdb..#tPaymode','U') IS NOT NULL
			DROP TABLE #tPaymode
			

			
		--SET @cStep = 195.2
		--EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

		CREATE TABLE #tMstTable  (inv_id VARCHAR(40),inv_dt DATETIME,SUBTOTAL NUMERIC(10,2),SUBTOTAL_MRP NUMERIC(10,2),TOTAL_QUANTITY_STR VARCHAR(500),
		DISCOUNT_PERCENTAGE NUMERIC(10,4),DISCOUNT_AMOUNT NUMERIC(10,2),MANUAL_DISCOUNT BIT,discount_percent_mrp NUMERIC(10,4),
		BILL_LEVEL_TAX_METHOD NUMERIC(1,0),party_dept_id varCHAR(4),DEPT_ID varCHAR(4),inv_mode NUMERIC(1,0),
		party_state_code VARCHAR(50),freight NUMERIC(10,2),other_charges NUMERIC(10,2),packing NUMERIC(10,2),
		insurance NUMERIC(10,2),OH_TAX_METHOD NUMERIC(1,0),DO_NOT_CALC_GST_OH BIT,ac_code CHAR(10),freight_hsn_code VARCHAR(50),
		other_charges_hsn_code VARCHAR(50),insurance_hsn_code VARCHAR(50),packing_hsn_code VARCHAR(50),
		freight_gst_percentage NUMERIC(6,2),insurance_gst_percentage NUMERIC(6,2),packing_gst_percentage NUMERIC(6,2),
		other_charges_gst_percentage NUMERIC(6,2),freight_taxable_value NUMERIC(10,2),freight_igst_amount NUMERIC(10,2)
		,freight_cgst_amount NUMERIC(10,2),freight_sgst_amount NUMERIC(10,2),other_charges_taxable_value NUMERIC(10,2),other_charges_igst_amount NUMERIC(10,2)
		,other_charges_cgst_amount NUMERIC(10,2),other_charges_sgst_amount NUMERIC(10,2),
		insurance_taxable_value NUMERIC(10,2),insurance_igst_amount NUMERIC(10,2)
		,insurance_cgst_amount NUMERIC(10,2),insurance_sgst_amount NUMERIC(10,2),packing_taxable_value NUMERIC(10,2),packing_igst_amount NUMERIC(10,2)
		,packing_cgst_amount NUMERIC(10,2),packing_sgst_amount NUMERIC(10,2),ROUND_OFF NUMERIC(6,2),EXCISE_DUTY_AMOUNT NUMERIC(10,2)
		,EXCISE_EDU_CESS_AMOUNT NUMERIC(10,2),EXCISE_HEDU_CESS_AMOUNT NUMERIC(10,2),net_amount numeric(14,2),TOTAL_QUANTITY numeric(10,2)
		,Total_Gst_Amount NUMERIC(10,2),TOTAL_PACKSLIP_NO NUMERIC(4,0),gst_round_off NUMERIC(6,2),
		MANUAL_ROUNDOFF BIT,OCTROI_AMOUNT NUMERIC(10,2),entry_mode NUMERIC(1,0),
		XN_ITEM_TYPE int,BILL_LEVEL_DISC_METHOD NUMERIC(1,0),
		Tcs_BaseAmount numeric(18,2),Tcs_Percentage numeric(10,3),Tcs_Amount numeric(12,2),
		Total_Gst_Cess_amount numeric(14,2),DOMESTIC_FOR_EXPORT int,SCRAP_SALE bit,shipping_ac_code varchar(10),
		MANUAL_GST_PER_FREIGHT bit,MANUAL_GST_PER_OTH bit
		)


		CREATE TABLE #tDetTable (ind_sp_id varchar(40), inv_id VARCHAR(40),PRODUCT_CODE VARCHAR(50),INVOICE_QUANTITY NUMERIC(10,3),QUANTITY NUMERIC(10,3),mrp NUMERIC(10,2),
		INMDISCOUNTAMOUNT NUMERIC(10,2),net_rate NUMERIC(10,2),rate NUMERIC(10,2),item_round_off NUMERIC(6,2),hsn_code VARCHAR(50),
		gst_percentage NUMERIC(6,2),igst_amount NUMERIC(10,2),cgst_amount NUMERIC(10,2),sgst_amount NUMERIC(10,2),
		xn_value_with_gst NUMERIC(10,2),xn_value_without_gst NUMERIC(10,2),CESS_AMOUNT NUMERIC(10,2),
		row_id varchar(50),ITEM_TAX_AMOUNT NUMERIC(10,2),total_custom_duty_amt NUMERIC(10,2),ps_id varchar(50),
		DISCOUNT_PERCENTAGE NUMERIC(10,4),DISCOUNT_AMOUNT NUMERIC(10,2),Gst_cess_Percentage numeric(14,2),Gst_cess_Amount numeric(14,2),WeightedQtyBillCount numeric(5,4) ,
		TAX_ROUND_OFF numeric(5,2) )
		
		CREATE TABLE #tPaymode (memo_id VARCHAR(40),PAYMODE_CODE CHAR(7),row_id VARCHAR(40),AMOUNT NUMERIC(10,2))

		SET @cStep = 195.4
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

		
		DECLARE @CFILTERCONDITION VARCHAR(1000),@CINSSPID VARCHAR(50)
		SET @CINSSPID=LEFT(@nSpId,38)+'ZZZ'

		IF @nUpdatemode NOT IN (1,2)
			SELECT @cMstTable='inm01106',@cDetTable='ind01106',@cWhereClause='b.inv_id='''+@cInvId+'''',
			@cKeyField='inv_id',@cPayModeTable='paymode_xn_det',
			@cWhereClauseInd='b.inv_id='''+@cInvId+''''
		ELSE
			SELECT @cMstTable='wsl_inm01106_upload',@cDetTable='wsl_ind01106_upload',@cPayModeTable='wsl_paymode_xn_det_upload',
			@cWhereClause='sp_id='''+@nSpId+'''',@cKeyField='sp_id',
			@cWhereClauseInd='sp_id='''+@nSpId+''''+(case when  ( @bcallfrompackslip=0  and @NBOXUPDATEMODE=0)
			then '' else ' or sp_id='''+@CINSSPID+'''' end)
		
		---- Commented this because of Issue of mismatch coming in case of Wls invoice agst Pack Slip generation
		--IF @nUpdatemode=2 AND (@NBOXUPDATEMODE=1 OR @bcallfrompackslip=1)
		--BEGIN
		--	SET @cStep = 195.6
		--	SELECT @CFILTERCONDITION=' b.inv_id='''+@cInvId+''''
			
			

		--	SET @cStep = 195.8
		--	PRINT 'gen tempdata for 3'
		--	EXEC UPDATEMASTERXN_MIRROR @CSOURCEDB='',@CSOURCETABLE='ind01106',@CDESTDB=''
		--								,@CDESTTABLE='wsl_ind01106_upload',@CKEYFIELD1='inv_id',@CKEYFIELD2='',@CKEYFIELD3=''
		--								,@LINSERTONLY=1,@CFILTERCONDITION=@CFILTERCONDITION,@LUPDATEONLY=0
		--								,@BALWAYSUPDATE=0,@BUPDATEXNS=1,@CINSSPID=@CINSSPID,@CSEARCHTABLE='ind01106'	
	
		--END

		SET @cStep = 196
		SET @cCmd=N'SELECT inv_id ,inv_dt,SUBTOTAL ,SUBTOTAL_MRP ,TOTAL_QUANTITY_STR ,
		DISCOUNT_PERCENTAGE ,DISCOUNT_AMOUNT ,MANUAL_DISCOUNT ,ISNULL(discount_percent_mrp,0) ,
		BILL_LEVEL_TAX_METHOD ,party_dept_id ,DEPT_ID ,inv_mode ,
		party_state_code ,freight ,other_charges ,packing ,
		insurance ,OH_TAX_METHOD ,DO_NOT_CALC_GST_OH ,ac_code ,freight_hsn_code ,
		other_charges_hsn_code ,insurance_hsn_code ,packing_hsn_code ,
		freight_gst_percentage ,insurance_gst_percentage ,packing_gst_percentage ,
		other_charges_gst_percentage ,freight_taxable_value ,freight_igst_amount 
		,freight_cgst_amount ,freight_sgst_amount ,other_charges_taxable_value ,other_charges_igst_amount 
		,other_charges_cgst_amount ,other_charges_sgst_amount ,
		insurance_taxable_value ,insurance_igst_amount 
		,insurance_cgst_amount ,insurance_sgst_amount ,packing_taxable_value ,packing_igst_amount 
		,packing_cgst_amount ,packing_sgst_amount ,ROUND_OFF ,EXCISE_DUTY_AMOUNT 
		,EXCISE_EDU_CESS_AMOUNT ,EXCISE_HEDU_CESS_AMOUNT ,net_amount ,TOTAL_QUANTITY 
		,Total_Gst_Amount ,TOTAL_PACKSLIP_NO ,gst_round_off,MANUAL_ROUNDOFF,octroi_amount,entry_mode,XN_ITEM_TYPE ,BILL_LEVEL_DISC_METHOD 
		,Tcs_BaseAmount,Tcs_Percentage,Tcs_Amount,b.DOMESTIC_FOR_EXPORT,b.SCRAP_SALE,shipping_ac_code,MANUAL_GST_PER_FREIGHT,MANUAL_GST_PER_OTH
		FROM '+
		@cMstTable+' b (NOLOCK) WHERE '+@cWhereClause

		print @CcMD +'DINKAR'


		
		INSERT #tMstTable (inv_id ,inv_dt,SUBTOTAL ,SUBTOTAL_MRP ,TOTAL_QUANTITY_STR ,
		DISCOUNT_PERCENTAGE ,DISCOUNT_AMOUNT ,MANUAL_DISCOUNT ,discount_percent_mrp ,
		BILL_LEVEL_TAX_METHOD ,party_dept_id ,DEPT_ID ,inv_mode ,
		party_state_code ,freight ,other_charges ,packing ,
		insurance ,OH_TAX_METHOD ,DO_NOT_CALC_GST_OH ,ac_code ,freight_hsn_code ,
		other_charges_hsn_code ,insurance_hsn_code ,packing_hsn_code ,
		freight_gst_percentage ,insurance_gst_percentage ,packing_gst_percentage ,
		other_charges_gst_percentage ,freight_taxable_value ,freight_igst_amount 
		,freight_cgst_amount ,freight_sgst_amount ,other_charges_taxable_value ,other_charges_igst_amount 
		,other_charges_cgst_amount ,other_charges_sgst_amount ,
		insurance_taxable_value ,insurance_igst_amount 
		,insurance_cgst_amount ,insurance_sgst_amount ,packing_taxable_value ,packing_igst_amount 
		,packing_cgst_amount ,packing_sgst_amount ,ROUND_OFF ,EXCISE_DUTY_AMOUNT 
		,EXCISE_EDU_CESS_AMOUNT ,EXCISE_HEDU_CESS_AMOUNT ,net_amount ,TOTAL_QUANTITY 
		,Total_Gst_Amount ,TOTAL_PACKSLIP_NO ,gst_round_off,MANUAL_ROUNDOFF,octroi_amount,entry_mode,
		XN_ITEM_TYPE,BILL_LEVEL_DISC_METHOD,Tcs_BaseAmount,Tcs_Percentage,Tcs_Amount,DOMESTIC_FOR_EXPORT,SCRAP_SALE,shipping_ac_code,
		MANUAL_GST_PER_FREIGHT,MANUAL_GST_PER_OTH)
		EXEC SP_EXECUTESQL @cCmd

		IF EXISTS (SELECT TOP 1 INV_ID FROM #tMstTable where discount_percentage<>0)
			SET @lDonotRecalGst=0
		
		SET @cStep = 196.2
		--EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

		SET @cCmd=N'SELECT '''+@cKeyField+''' ind_sp_id,inv_id ,PRODUCT_CODE ,INVOICE_QUANTITY ,QUANTITY ,mrp ,
		INMDISCOUNTAMOUNT ,DISCOUNT_PERCENTAGE ,DISCOUNT_AMOUNT ,net_rate ,rate,item_round_off ,hsn_code ,
		gst_percentage ,igst_amount ,cgst_amount ,sgst_amount ,
		xn_value_with_gst ,xn_value_without_gst ,CESS_AMOUNT ,
		row_id ,ITEM_TAX_AMOUNT ,total_custom_duty_amt ,ps_id,TAX_ROUND_OFF FROM '+@cDetTable+' b (NOLOCK) WHERE '+@cWhereClauseInd

		print @CcMD

		INSERT #tDetTable (ind_sp_id,inv_id ,PRODUCT_CODE ,INVOICE_QUANTITY ,QUANTITY ,mrp ,
		INMDISCOUNTAMOUNT ,DISCOUNT_PERCENTAGE ,DISCOUNT_AMOUNT ,net_rate ,rate,item_round_off ,hsn_code ,
		gst_percentage ,igst_amount ,cgst_amount ,sgst_amount ,
		xn_value_with_gst ,xn_value_without_gst ,CESS_AMOUNT ,
		row_id ,ITEM_TAX_AMOUNT ,total_custom_duty_amt ,ps_id,TAX_ROUND_OFF )
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep = 197
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

		SET @cCmd=N'SELECT memo_id ,PAYMODE_CODE ,AMOUNT,row_id FROM '+@cPayModeTable+' b (NOLOCK)
					WHERE '+REPLACE(@cWhereClause,'inv_id','memo_id')+' AND xn_type=''WSL'''
		INSERT #tPaymode (memo_id ,PAYMODE_CODE ,AMOUNT,ROW_ID )
		EXEC SP_EXECUTESQL @cCmd

		
		--select 'before inm', inv_id,subtotal,net_amount from #tMstTable

		--select 'before ind',sum(net_rate*quantity),sum(igst_amount+cgst_amount+sgst_amount) from #tdetTable 


		SET @cStep = 199
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
		-- UPDATING TOTALS IN PIM TABLE---changes on 29012015
		UPDATE A SET SUBTOTAL = ISNULL( B.SUBTOTAL ,0 ),SUBTOTAL_MRP =ISNULL( B.SUBTOTAL_MRP ,0 )
		FROM #tMstTable A WITH (ROWLOCK)
		LEFT OUTER JOIN
		( 	
			SELECT	inv_id, SUM(INVOICE_QUANTITY*NET_RATE) AS SUBTOTAL,SUM(INVOICE_QUANTITY*MRP) AS SUBTOTAL_MRP
			FROM #tDetTable WITH (NOLOCK)
			GROUP BY inv_id
		) B ON  A.inv_id = B.inv_id
		
			
		

		SET @cStep = 208
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
		
		DECLARE @STR VARCHAR(MAX),@STR1 VARCHAR(MAX)
		
		SET @STR=NULL
		
		SELECT  @STR =  COALESCE(@STR +  '/ ', ' ') + (''+C.UOM_NAME+': '+
			CAST(SUM(QUANTITY) AS VARCHAR) +' ')  
		   FROM #tDetTable A  (NOLOCK)
		   JOIN SKU S  (NOLOCK)ON S.PRODUCT_CODE=A.product_code
		   JOIN ARTICLE B (NOLOCK) ON S.ARTICLE_CODE=B.ARTICLE_CODE
		  JOIN UOM C ON C.UOM_CODE=B.UOM_CODE
		   GROUP BY C.UOM_NAME ,inv_id

		SET @cStep = 210
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1		   
		UPDATE #tMstTable SET TOTAL_QUANTITY_STR =@STR
				
		SET @cStep = 214
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

		IF @nUpdatemode IN (4,5,8)
			UPDATE #tMstTable SET MANUAL_DISCOUNT=0

		SET @cStep = 216
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1	
			   
		UPDATE #tMstTable WITH (ROWLOCK) SET DISCOUNT_AMOUNT = ROUND(SUBTOTAL*DISCOUNT_PERCENTAGE/100,2)
		WHERE MANUAL_DISCOUNT=0 AND DISCOUNT_PERCENT_MRP=0 

		UPDATE  #tMstTable  WITH (ROWLOCK) SET DISCOUNT_AMOUNT = ROUND(SUBTOTAL_mrp*DISCOUNT_PERCENT_MRP/100,2)
		WHERE  MANUAL_DISCOUNT=0 AND DISCOUNT_PERCENT_MRP<>0

		UPDATE  #tMstTable  WITH (ROWLOCK) SET DISCOUNT_AMOUNT = ROUND((CASE WHEN BILL_LEVEL_DISC_METHOD=2 THEN SUBTOTAL_mrp ELSE  SUBTOTAL END)*DISCOUNT_PERCENTAGE/100,2)
		WHERE  MANUAL_DISCOUNT=0 


		SET @cStep = 218
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
		
		UPDATE #tMstTable WITH (ROWLOCK) SET DISCOUNT_PERCENTAGE=(DISCOUNT_AMOUNT*100/(SUBTOTAL))
		WHERE MANUAL_DISCOUNT=1
		
		
		UPDATE #tMstTable WITH (ROWLOCK) SET DISCOUNT_PERCENTAGE=(DISCOUNT_AMOUNT*100/(SUBTOTAL))
		WHERE  MANUAL_DISCOUNT=1 and DISCOUNT_PERCENT_MRP<>0
		
		UPDATE #tMstTable WITH (ROWLOCK) SET DISCOUNT_PERCENTAGE=(DISCOUNT_AMOUNT*100/((CASE WHEN BILL_LEVEL_DISC_METHOD=2 THEN SUBTOTAL_mrp ELSE  SUBTOTAL END)))
		WHERE  MANUAL_DISCOUNT=1
		
		SET @cStep = 222
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
		

		--recalculate bill level discount amount in item level
	   UPDATE #tDetTable SET INMDISCOUNTAMOUNT=0 
			
	   DECLARE @NTOTAL_DISCOUNT_AMOUNT NUMERIC(10,2)
	   SELECT   @NTOTAL_DISCOUNT_AMOUNT= ISNULL(DISCOUNT_AMOUNT,0) from #tMstTable (NOLOCK)
 	   
	   SET @cStep = 226
	   EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1		   	   
	   UPDATE A SET INMDISCOUNTAMOUNT=ROUND((CASE WHEN B.SUBTOTAL=0 THEN 0 ELSE (B.DISCOUNT_AMOUNT/B.SUBTOTAL)*(a.net_rate*A.INVOICE_QUANTITY) END),2)
	   FROM #tDetTable  A
	   JOIN #tMstTable  B ON A.inv_id=b.inv_id
	   	   
	   --DISTRIBUTE BILL LEVEL DISCOUNT AMOUNT IN ALL ITEMS
	   if ISNULL(@NTOTAL_DISCOUNT_AMOUNT,0)<>0
	   begin
		   SET @cStep = 228
	       EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1   
		        
		   EXEC SP3S_REPROCESS_BILL_DISCOUNT 'WSL','',@NSPID,@CERRORMSG OUTPUT 
		   IF ISNULL(@CERRORMSG,'')<>''
				GOTO END_PROC  
	   end  

	    SET @cStep = 230
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
		UPDATE #tDetTable WITH (ROWLOCK) SET item_round_off=(NET_RATE-(RATE-(DISCOUNT_AMOUNT/INVOICE_QUANTITY)))
		WHERE  INVOICE_QUANTITY<>0 AND  item_round_off<>(NET_RATE-(RATE-(DISCOUNT_AMOUNT/INVOICE_QUANTITY)))

		UPDATE #tDetTable  WITH (ROWLOCK) SET item_round_off=0 WHERE  INVOICE_QUANTITY=0
			
			declare @nxnitemtype int 
			select @nxnitemtype=xn_item_type from #tMstTable

		IF (@bGstBill=1) 
		BEGIN
			print 'enter gst calc of wsl'
			SET @cStep=232
			EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
						
			--if @@spid=58
			--begin
			--	select 'check #tDetTable',@nSpId as nSpId,inv_id,INMDISCOUNTAMOUNT,* from #tDetTable
			--	select  'check #tMstTable',* from #tMstTable
			--end	
			DECLARE @nFreight NUMERIC(10,2),@nPacking NUMERIC(10,2),@nInsurance NUMERIC(10,2),@nOc NUMERIC(10,2)
				 			
			INSERT gst_taxinfo_calc	WITH (ROWLOCK) ( PRODUCT_CODE, sp_id ,net_value,tax_method,row_id,quantity,target_dept_id,source_dept_id,mrp)  
			SELECT PRODUCT_CODE,@nSpId AS sp_id,
			ROUND(((a.net_rate*a.invoice_quantity)
			-(ISNULL(A.INMDISCOUNTAMOUNT,0) )),2) AS net_value
			,b.bill_level_tax_method AS tax_method,
			row_id,invoice_quantity,b.party_dept_id,b.dept_id,a.mrp 
			FROM #tDetTable a (NOLOCK)
			JOIN #tMstTable b (NOLOCK) ON a.inv_id=b.inv_id

			SET @cStep = 234
			EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1		   
			DECLARE @CPARTY_GSTN_NO VARCHAR(20),@bRegistered BIT

			SELECT TOP 1 @CPARTY_GSTN_NO=case when a.inv_mode =1 then ac_gst_no else l.loc_gst_no end,
			@cPartyStatecode=party_state_code,
			@bGroupInv=(CASE WHEN inv_mode=2 THEN 1 ELSE 0 END),@nFreight=freight,@nOc=other_charges,
			@nPacking=packing,@nInsurance=insurance,@DINVDT=inv_dt,
			@bDoNotDebitGoodsTCS=DoNotDebitGoodsTCS
			FROM #tMstTable a (NOLOCK) 
			JOIN lmp01106 b (NOLOCK) ON a.ac_code=b.ac_code 
			LEFT JOIN LOCATION L ON L.DEPT_ID =A.PARTY_DEPT_ID 
			
			

			IF ISNULL(@CPARTY_GSTN_NO,'')<>'' and @CPARTYSTATECODE<>'96' 
			   SET @CPARTYSTATECODE=LEFT(@CPARTY_GSTN_NO,2)

			IF EXISTS (SELECT TOP 1 'U' FROM #TMSTTABLE  WHERE PARTY_STATE_CODE<>@CPARTYSTATECODE)
			BEGIN 

				  UPDATE #TMSTTABLE SET PARTY_STATE_CODE=@CPARTYSTATECODE
				  UPDATE A SET PARTY_STATE_CODE=@CPARTYSTATECODE FROM WSL_INM01106_UPLOAD A WITH (NOLOCK) WHERE SP_ID=@NSPID

			END

			SET @cStep = 236
			EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1		   				
			IF (@nFreight+@nOc+@nPacking+@nInsurance)<>0
			BEGIN
				INSERT gst_taxinfo_calc_oh	( sp_id,freight,other_charges,packing,insurance,OH_TAX_METHOD ,DO_NOT_CALC_GST_OH,
				                            other_charges_hsn_code, freight_hsn_code,MANUAL_GST_PER_FREIGHT,MANUAL_GST_PER_OTH,
											other_charges_gst_percentage,freight_gst_percentage)
				SELECT @nSpId,freight,other_charges,packing,insurance,OH_TAX_METHOD,DO_NOT_CALC_GST_OH ,
				       other_charges_hsn_code, freight_hsn_code,MANUAL_GST_PER_FREIGHT,MANUAL_GST_PER_OTH,
											other_charges_gst_percentage,freight_gst_percentage
				FROM #tMstTable (NOLOCK)
			END		

			SET @cStep=238
			EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
			IF @bGroupInv=1
				SELECT @bRegistered=ISNULL(registered_gst,0) FROM location a WITH (NOLOCK) 
				JOIN #tMstTable b WITH (NOLOCK) on a.dept_id=b.party_dept_id
			ELSE
				SELECT @bRegistered=ISNULL(registered_gst_dealer,0) FROM lmp01106 a WITH (NOLOCK) 
				JOIN #tMstTable b WITH (NOLOCK) on a.ac_code=b.ac_code
				


			SET @cStep = 238.2
			EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
			declare @bExportInvoice BIT,@nDOMESTIC_FOR_EXPORT int

			IF ISNULL(@COUNTRY,'')=''
				SELECT TOP 1 @COUNTRY=ISNULL(CON.COUNTRY_CODE,''),
				@bExportInvoice=ISNULL(b.export_gst_percentage_Applicable,0),
				@nDOMESTIC_FOR_EXPORT=ISNULL(a.DOMESTIC_FOR_EXPORT,0)
				FROM #tMstTable a (NOLOCK) JOIN lmp01106 b (NOLOCK) ON a.ac_code=b.ac_code 
				LEFT OUTER JOIN AREA AR (NOLOCK) ON AR.area_code =B.area_code 
				LEFT OUTER JOIN CITY CT (NOLOCK) ON CT.CITY_CODE =AR.city_code 
				LEFT OUTER JOIN state ST (NOLOCK) ON ST.state_code =CT.state_code 
				LEFT OUTER JOIN regionM R (NOLOCK) ON R.region_code =ST.region_code
				LEFT OUTER JOIN COUNTRY CON (NOLOCK) ON CON.COUNTRY_CODE=R.COUNTRY_CODE 
			
			declare @cALL_XN_IGST varchar(10),@CDONOT_CALCULATE_GST_SOR_LOC varchar(5)
			SELECT  @cALL_XN_IGST=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='ALL_XN_IGST' 
			
			if @bGroupInv=1
			begin
			
				IF EXISTS (SELECT TOP 1 'U' FROM LOCATION (NOLOCK) A
				           join #tMstTable b on a.dept_id =b.party_dept_id WHERE  SOR_LOC =1) 
				SELECT TOP 1 @CDONOT_CALCULATE_GST_SOR_LOC=VALUE FROM CONFIG WHERE CONFIG_OPTION ='DONOT_CALCULATE_GST_FOR_SOR_LOCATION'
				
			end
			
			



			IF ((ISNULL(@COUNTRY,'')  IN('0000000','') or isnull(@bExportInvoice,0)=1  or isnull(@cALL_XN_IGST,'')='1' or isnull(@nDOMESTIC_FOR_EXPORT,0)=2) and ISNULL(@NLOCREGISTER,0)=1 and isnull(@nxnitemtype,'')<>5) and ISNULL(@CDONOT_CALCULATE_GST_SOR_LOC,'')<>'1'
			BEGIN
				SET @cStep=240
				EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1


				    
				EXEC SP3S_GST_TAX_CAL
				@CXN_TYPE='WSL',
				@CMEMO_ID='',
				@DMEMO_DT=@DINVDT,
				@NSPID=@NSPID,
				@CPARTYSTATE_CODE=@CPARTYSTATECODE,
				@BPARTYREGISTERED=@BREGISTERED,
				@CPARTY_GSTN_NO=@CPARTY_GSTN_NO,
				@CERRMSG=@CERRORMSG OUTPUT,
				@cLocationId=@CLOCID
				
				--if @@spid=58
				--	select * from gst_taxinfo_calc where sp_id='1894e4ff492-0354-4bbe-848f-095a50bd2100'

				PRINT 'gst tax cal done from wsl'
				IF ISNULL(@CERRORMSG,'')<>''
						GOTO END_PROC
			END
			ELSE
			BEGIN
				SET @cStep=242
				EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

				UPDATE A SET HSN_CODE= CASE WHEN ISNULL(@COUNTRY,'')  IN('0000000','') and ISNULL(@CDONOT_CALCULATE_GST_SOR_LOC,'')<>'1' THEN  '0000000000' ELSE isnull(s.HSN_CODE,'0000000000') END ,
				GST_PERCENTAGE=0,IGST_AMOUNT=0,
				CGST_AMOUNT=0,SGST_AMOUNT=0,
				XN_VALUE_WITHOUT_GST=A.NET_VALUE,XN_VALUE_WITH_GST=A.NET_VALUE,  
				GST_CESS_Percentage=0, 
				GST_CESS_Amount=0
				FROM GST_TAXINFO_CALC A WITH (ROWLOCK)
				LEFT OUTER JOIN SKU S (NOLOCK) ON A.PRODUCT_CODE =S.PRODUCT_CODE 
				WHERE SP_ID=rtrim(ltrim(@NSPID))
				      
				update a set freight_taxable_value=isnull(freight,0),
							other_charges_taxable_value=ISNULL(other_charges,0),
							insurance_taxable_value=ISNULL(insurance,0),
							packing_taxable_value=ISNULL(packing,0),
							freight_gst_amount=0,
							other_charges_gst_amount=0,
							insurance_gst_amount=0,
							packing_gst_amount=0
				FROM GST_TAXINFO_CALC_oh A WITH (ROWLOCK)
				WHERE SP_ID=rtrim(ltrim(@NSPID))
				
			END
				  
			SET @cStep=244
			EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

			
			UPDATE #tDetTable WITH (ROWLOCK) SET hsn_code=b.hsn_code,gst_percentage=b.gst_percentage,igst_amount=b.igst_amount,
			cgst_amount=b.cgst_amount,sgst_amount=b.sgst_amount,
			xn_value_without_gst=b.xn_value_without_gst,xn_value_with_gst=b.xn_value_with_gst,
			CESS_AMOUNT =ISNULL(B.CESS_AMOUNT,0),
			GST_CESS_PERCENTAGE =ISNULL(B.GST_CESS_PERCENTAGE,0),
			GST_CESS_AMOUNT =ISNULL(B.GST_CESS_AMOUNT,0)
			FROM gst_taxinfo_calc b (NOLOCK) WHERE b.row_id=#tDetTable.row_id	
			AND b.sp_id=rtrim(ltrim(@NSPID))
			
		
			SET @cStep=246
			EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
            
            
            
			UPDATE a SET  freight_hsn_code=(case when b.freight_hsn_code is null and isnull(a.freight_hsn_code,'')<>'' then a.freight_hsn_code else ISNULL(b.freight_hsn_code,'0000000000') end ),
			other_charges_hsn_code=(case when b.other_charges_hsn_code is null and isnull(a.other_charges_hsn_code,'')<>'' then a.other_charges_hsn_code else ISNULL(b.other_charges_hsn_code,'0000000000') end ),
			packing_hsn_code=ISNULL(b.packing_hsn_code,'0000000000'),
			insurance_hsn_code=ISNULL(b.insurance_hsn_code,'0000000000'),
			
			freight_gst_percentage=ISNULL(b.freight_gst_percentage,0),other_charges_gst_percentage=ISNULL(b.other_charges_gst_percentage,0),
			insurance_gst_percentage=ISNULL(b.insurance_gst_percentage,0),packing_gst_percentage=ISNULL(b.packing_gst_percentage,0),
				
			freight_taxable_value=b.freight_taxable_value,
			freight_igst_amount=(CASE WHEN ISNULL(isIgst,0)=1 THEN b.freight_gst_amount ELSE 0 END),
			freight_cgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.freight_gst_amount/2 ELSE 0 END),
			freight_sgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.freight_gst_amount/2 ELSE 0 END),
				
			other_charges_taxable_value=b.other_charges_taxable_value,
			other_charges_igst_amount=(CASE WHEN ISNULL(isIgst,0)=1 THEN b.other_charges_gst_amount ELSE 0 END),
			other_charges_cgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.other_charges_gst_amount/2 ELSE 0 END),
			other_charges_sgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.other_charges_gst_amount/2 ELSE 0 END),
				
			insurance_taxable_value=b.insurance_taxable_value,
			insurance_igst_amount=(CASE WHEN ISNULL(isIgst,0)=1 THEN b.insurance_gst_amount ELSE 0 END),
			insurance_cgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.insurance_gst_amount/2 ELSE 0 END),
			insurance_sgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.insurance_gst_amount/2 ELSE 0 END),
				
			packing_taxable_value=b.packing_taxable_value,
			packing_igst_amount=(CASE WHEN ISNULL(isIgst,0)=1 THEN b.packing_gst_amount ELSE 0 END),
			packing_cgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.packing_gst_amount/2 ELSE 0 END),
			packing_sgst_amount=(CASE WHEN ISNULL(isIgst,0)=0 THEN b.packing_gst_amount/2 ELSE 0 END)									
				
			FROM #tmstTable a WITH (ROWLOCK)
			LEFT OUTER JOIN
			(SELECT * FROM  gst_taxinfo_calc_oh (NOLOCK) WHERE sp_id=rtrim(ltrim(@NSPID))) b ON 1=1
				
			

			--VALIDATING HSN Code
					
			if ISNULL(@NLOCREGISTER,0)=1 and ISNULL(@COUNTRY,'')  IN('0000000','')
			begin			
				SET @cStep=248
				EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

				SELECT TOP 1 @CERRPRODUCTCODE=PRODUCT_CODE FROM  #tDetTable
				WHERE ISNULL(hsn_code,'') IN ('','0000000000') and @nxnitemtype<>5

				IF ISNULL(@CERRPRODUCTCODE,'')<>'' 
				BEGIN
					SET @cErrormsg='ITEM CODE: '+@CERRPRODUCTCODE +'...HSN Code should not be blank..... CANNOT PROCEED'
					GOTO END_PROC
				END

				SET @cStep=250
				EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1					

				--VALIDATING GST Amount Columns
				SELECT TOP 1 @CERRPRODUCTCODE=PRODUCT_CODE FROM #tDetTable (NOLOCK)
				WHERE 		((ISNULL(igst_amount,0)<>0 AND (ISNULL(cgst_amount,0)<>0 OR ISNULL(sgst_amount,0)<>0))
							OR (ISNULL(cgst_amount,0)<>0 AND ISNULL(sgst_amount,0)=0)
							OR (ISNULL(sgst_amount,0)<>0 AND ISNULL(cgst_amount,0)=0))
								
				IF ISNULL(@CERRPRODUCTCODE,'')<>''
				BEGIN
					SET @cErrormsg='ITEM CODE: '+@CERRPRODUCTCODE +'...Invalid Values in Gst amount..... CANNOT PROCEED'
					GOTO END_PROC
				END	
			end
		END ---- End of IF @bGstBill=1
			
		SET @cStep=252
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
											
		------ We need to do this Process to verify Tax calculation		
		IF @bGstBill=0	
			EXEC SP3S_REPROCESS_TAX_CALCULATION
			@INV_ID='',
			@ERRMSG=@cErrormsg OUTPUT
		ELSE--new changes for hsn & percentage wise setoff
			EXEC SP3S_REPROCESS_GST_CALCULATION_WSL
			@cMemoId=@cInvId,
			@cXnType='WSL',
			@cErrormsg=@cErrormsg OUTPUT
		
		IF ISNULL(@cErrormsg,'')<>''
		   GOTO END_PROC


		SET @cStep=254
	    EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1
			
		SELECT @NSUBTOTAL=SUBTOTAL FROM #tmstTable
		
		update #tMstTable WITH (ROWLOCK) set SUBTOTAL=b.subtotal from 
		(select inv_id,SUM(net_rate*quantity) as subtotal from #tDetTable WITH (NOLOCK) 
		 group by inv_id) b
				
		SET @cStep = 258
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

		
		DECLARE @NTAXFLAG NUMERIC(1,0),@NOHGST NUMERIC(10,2)

		SELECT @NTAXFLAG=BILL_LEVEL_TAX_METHOD 
		FROM  #tMstTable  a WITH (NOLOCK)
		LEFT OUTER JOIN lmp01106 b WITH (NOLOCK) ON a.ac_code=b.ac_code
				
		SET @NTAXFLAG = (CASE WHEN ISNULL(@NTAXFLAG,0)=0 THEN 1 ELSE ISNULL(@NTAXFLAG,0) END)

		DECLARE @NTAXVALUE NUMERIC(14,2)

		
		SELECT @NTAX=SUM(ITEM_TAX_AMOUNT+ISNULL(igst_amount,0)+ISNULL(cgst_amount,0)+ISNULL(sgst_amount,0)+ISNULL(CESS_AMOUNT,0)),
		       @NGSTCESSAMOUNT=SUM(ISNULL(GST_cess_amount,0)),
			   @NTAXVALUE=SUM(ISNULL(XN_VALUE_WITHOUT_GST,0))
		FROM #tDetTable (NOLOCK)

		SET @NTAXVALUE=ISNULL(@NTAXVALUE,0)

		SELECT @NTAX=ISNULL(@NTAX,0)
		select @NGSTCESSAMOUNT=isnull(@NGSTCESSAMOUNT,0)
		
		SELECT @NOHGST=ISNULL(freight_igst_amount,0)+ISNULL(freight_cgst_amount,0)+ISNULL(freight_sgst_amount,0)
		+ISNULL(other_charges_igst_amount,0)+ISNULL(other_charges_cgst_amount,0)+ISNULL(other_charges_sgst_amount,0)
		+ISNULL(insurance_igst_amount,0)+ISNULL(insurance_cgst_amount,0)+ISNULL(insurance_sgst_amount,0)
		+ISNULL(packing_igst_amount,0)+ISNULL(packing_cgst_amount,0)+ISNULL(packing_sgst_amount,0)
		FROM #tMstTable (NOLOCK)

				
		SET @nTotalCustomDuty=ISNULL(@nTotalCustomDuty,0)


	  SELECT   @DINVDT=INV_DT FROM #TMSTTABLE A (NOLOCK) 
       --Tcs calculation 
	    Declare @NTAXABLEVALUE NUMERIC(18,2)
	   UPDATE #TMSTTABLE SET TCS_BASEAMOUNT=0,TCS_PERCENTAGE=0,TCS_AMOUNT=0 

       --if @bGroupInv=1 and isnull(@bDoNotDebitGoodsTCS,0)=1
	      --set @bDoNotDebitGoodsTCS=0
	      
	   IF EXISTS (SELECT TOP 1 'U' FROM LOCATION WHERE DEPT_ID =@CLOCID AND ISNULL(Enable_Tcs,0)=1)
	   and exists (select top 1 'u' from TCS_MST where Wef <=@DINVDT and isnull(Tcs_Type,0)=0 ) and isnull(@nxnitemtype,0)=1
	   and exists ( SELECT TOP 1 'U' FROM CONFIG WHERE CONFIG_OPTION='CALCULATE_TCS_AGAINST_INVOICING' AND VALUE='1') and @CPARTYSTATECODE not in('96')--export Invoice chnages as per pankaj sir discuss with client
	   and ISNULL(@bDoNotDebitGoodsTCS,0)=0
	   BEGIN
	        
			
			if exists (select top 1'u' from #tMstTable where isnull(SCRAP_SALE ,0)=1)
			begin

			      select @NTAXABLEVALUE=sum(xn_value_without_gst) from #tDetTable
			end
			else
			begin

				select  @NTAXABLEVALUE=(isnull(OTHER_CHARGES_taxable_value,0)+ISNULL(other_charges_igst_amount,0)+ 
				ISNULL(other_charges_cgst_amount,0)+ISNULL(other_charges_sgst_amount,0)+
				isnull(freight_taxable_value,0)+ISNULL(freight_igst_amount,0)+ 
				ISNULL(freight_cgst_amount,0)+ISNULL(freight_sgst_amount,0)+
				isnull(insurance_taxable_value,0)+ISNULL(insurance_igst_amount,0)+ 
				ISNULL(insurance_cgst_amount,0)+ISNULL(insurance_sgst_amount,0)+octroi_amount+packing+EXCISE_DUTY_AMOUNT+
				EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT+ROUND_OFF+b.net_amount_gst )
				FROM #tMstTable a WITH (ROWLOCK)
				JOIN (select a.inv_ID,sum(xn_value_without_gst+igst_amount+cgst_amount+sgst_amount+isnull(cess_amount,0)) as net_amount_gst
					  from #tDetTable a (nolock)
					  JOIN #tMstTable b (NOLOCK)  on a.inv_ID=b.inv_ID 
					  GROUP BY a.inv_ID
					 ) b ON 1=1
           

		   end


		  EXEC SP3S_TCSCAL 
		  @CXNTYPE='WSL',
		  @CLOCID=@CLOCID,
		  @NTAXABLEVALUE=@NTAXABLEVALUE,
		  @NPARTY_AMOUNT_FORTCS=@NPARTY_AMOUNT_FORTCS,
		  @CERRORMSG=@CERRORMSG OUTPUT

		  IF ISNULL(@cErrormsg,'')<>''
		   GOTO END_PROC


	   END


	  
	   --end of tcs calculation 



		
		SET @cStep = 260
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

		UPDATE #tMstTable WITH (ROWLOCK) SET ROUND_OFF=ROUND((SUBTOTAL + (CASE WHEN @NTAXFLAG=1 THEN ISNULL(@NTAX,0)+isnull(@NGSTCESSAMOUNT,0) ELSE 0 END)+isnull(TCS_AMOUNT,0)+
		(CASE WHEN oh_tax_method=2 THEN 0 ELSE ISNULL(@NOHGST,0) END)
		+OTHER_CHARGES+EXCISE_DUTY_AMOUNT+EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT+FREIGHT+INSURANCE+@nTotalCustomDuty ) - DISCOUNT_AMOUNT,0)-
	    (SUBTOTAL+(CASE WHEN @NTAXFLAG=1 THEN ISNULL(@NTAX,0)+isnull(@NGSTCESSAMOUNT,0) ELSE 0 END)+isnull(TCS_AMOUNT,0)+OTHER_CHARGES+FREIGHT+
	    (CASE WHEN oh_tax_method=2 THEN 0 ELSE ISNULL(@NOHGST,0) END) +
		EXCISE_DUTY_AMOUNT+EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT+@nTotalCustomDuty-DISCOUNT_AMOUNT+INSURANCE)
		WHERE  MANUAL_ROUNDOFF=0
		

		--IF @@spid=62
		--begin
		--	select 'chk totdisc',sum(inmdiscountamount),sum(xn_value_without_gst) from #tdettable
		--	select subtotal,discount_percentage,discount_amount,other_charges_cgst_amount,other_charges_igst_amount
		--	from #tMstTable
			
		--	select 'check tdet igst',product_code,ITEM_TAX_AMOUNT,igst_amount,cgst_amount,sgst_amount,CESS_AMOUNT,INMDISCOUNTAMOUNT
		--	from #tdetTable

		--	select sum(net_value) from gst_taxinfo_calc where sp_id=@nSpId
		--end

		SET @cStep = 262
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1

	

		UPDATE #tMstTable WITH (ROWLOCK) SET NET_AMOUNT=(SUBTOTAL +(CASE WHEN @NTAXFLAG=1 THEN ISNULL(@NTAX,0)+isnull(@NGSTCESSAMOUNT,0) ELSE 0 END) +
		(CASE WHEN oh_tax_method=2 THEN 0 ELSE ISNULL(@NOHGST,0) END)+isnull(TCS_AMOUNT,0) +  OTHER_CHARGES + FREIGHT+EXCISE_DUTY_AMOUNT+
		EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT+ROUND_OFF+OCTROI_AMOUNT+@nTotalCustomDuty)-DISCOUNT_AMOUNT+INSURANCE
		
		
		--if @@spid=364
		--	select 'check net from temp',	net_amount,SUBTOTAL ,ISNULL(@NTAX,0)  as tax,
		--(CASE WHEN oh_tax_method=2 THEN 0 ELSE ISNULL(@NOHGST,0) END) as ohgst,  OTHER_CHARGES,
		--other_charges_cgst_amount,other_charges_sgst_amount,other_charges_taxable_value,
		--FREIGHT,EXCISE_DUTY_AMOUNT,
		--EXCISE_EDU_CESS_AMOUNT,EXCISE_HEDU_CESS_AMOUNT,ROUND_OFF,OCTROI_AMOUNT,DISCOUNT_AMOUNT,INSURANCE from #tMstTable

		UPDATE A SET TOTAL_QUANTITY=B.QUANTITY ,
		Total_Gst_Amount=B.GST_AMOUNT ,
		TOTAL_PACKSLIP_NO=CASE WHEN A.ENTRY_MODE<>2 THEN 0 ELSE ISNULL(B.TOTAL_PACKSLIP_NO,0) END,
		Total_gst_cess_amount=b.GST_CESS_AMOUNT
		FROM 
		#tMstTable A WITH (ROWLOCK) 
		JOIN 
		(
		 SELECT inv_id ,SUM(QUANTITY) AS QUANTITY,
		         SUM(ISNULL(IGST_AMOUNT,0)+ ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)) AS GST_AMOUNT,
				 SUM(ISNULL(GST_CESS_AMOUNT,0)) AS GST_CESS_AMOUNT,
		         COUNT(DISTINCT PS_ID) AS TOTAL_PACKSLIP_NO 
		 FROM #tDetTable (NOLOCK)  
		 GROUP BY inv_id
		 )B ON A.inv_id =B.inv_id 

		
       	DECLARE @nTotAbsQty NUMERIC(10,2)
	    SELECT @nTotAbsQty=SUM(ABS(QUANTITY)) FROM #tDetTable 
	    
		UPDATE #tDetTable SET  WeightedQtyBillCount=  CONVERT(NUMERIC(6,4),CONVERT(NUMERIC(10,2),ABS(QUANTITY)) /
	    CONVERT(NUMERIC(10,2),@nTotAbsQty))

		SET @cStep = 262.2
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1							

		IF EXISTS (SELECT TOP 1 inv_id FROM #tMstTable (NOLOCK) WHERE inv_dt>='2017-07-01')				
			UPDATE a SET gst_round_off=(net_amount-(isnull(OTHER_CHARGES_taxable_value,0)+ISNULL(other_charges_igst_amount,0)+ 
			ISNULL(other_charges_cgst_amount,0)+ISNULL(other_charges_sgst_amount,0)+
			isnull(freight_taxable_value,0)+ISNULL(freight_igst_amount,0)+ 
			ISNULL(freight_cgst_amount,0)+ISNULL(freight_sgst_amount,0)+
			isnull(insurance_taxable_value,0)+ISNULL(insurance_igst_amount,0)+ 
			ISNULL(insurance_cgst_amount,0)+ISNULL(insurance_sgst_amount,0)+octroi_amount+packing+EXCISE_DUTY_AMOUNT+
			isnull(TCS_AMOUNT,0)+
					EXCISE_EDU_CESS_AMOUNT+EXCISE_HEDU_CESS_AMOUNT+ROUND_OFF+b.net_amount_gst+ISNULL(GST_CESS_AMOUNT,0) ))
			FROM #tMstTable a WITH (ROWLOCK)
			JOIN (select a.inv_ID,sum(xn_value_without_gst+igst_amount+cgst_amount+sgst_amount+isnull(cess_amount,0)) as net_amount_gst,
			                      sum(ISNULL(gst_CESS_AMOUNT,0)) as GST_CESS_AMOUNT
				  from #tDetTable a (nolock)
				  JOIN #tMstTable b (NOLOCK)  on a.inv_ID=b.inv_ID 
				  WHERE b.inv_Dt>='2017-07-01'
				  GROUP BY a.inv_ID
				 ) b ON 1=1

		SET @cStep=262.4
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1							 		
		--AUDIT_TRIAL REMOVED
		DECLARE @CCOUNT INT

		
		SELECT @CCOUNT=COUNT(PAYMODE_CODE) FROM #tPaymode A WITH (NOLOCK)
		
		IF @CCOUNT = 1
		BEGIN
			UPDATE A SET AMOUNT=B.NET_AMOUNT FROM #tPaymode A WITH (ROWLOCK)
			JOIN #tMstTable b ON a.memo_id=b.inv_id
			WHERE A.amount<>B.NET_AMOUNT
		END

		SET @cStep=262.6
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1							 		
		

		--if @@spid=58
		--	select 'after inm', inv_id,subtotal,net_amount from #tMstTable

		SET @cCmd=N'UPDATE a SET SUBTOTAL=B.SUBTOTAL,SUBTOTAL_MRP=B.SUBTOTAL_MRP,TOTAL_QUANTITY_STR=B.TOTAL_QUANTITY_STR,
		DISCOUNT_PERCENTAGE=B.DISCOUNT_PERCENTAGE,DISCOUNT_AMOUNT=B.DISCOUNT_AMOUNT,MANUAL_DISCOUNT=B.MANUAL_DISCOUNT,
		discount_percent_mrp=B.discount_percent_mrp,freight_hsn_code=B.freight_hsn_code,
		other_charges_hsn_code=B.other_charges_hsn_code,insurance_hsn_code=B.insurance_hsn_code,
		packing_hsn_code=B.packing_hsn_code,freight_gst_percentage=B.freight_gst_percentage,insurance_gst_percentage=B.insurance_gst_percentage,
		packing_gst_percentage=B.packing_gst_percentage,other_charges_gst_percentage=B.other_charges_gst_percentage,
		freight_taxable_value=B.freight_taxable_value,freight_igst_amount=B.freight_igst_amount,
		freight_cgst_amount=B.freight_cgst_amount,freight_sgst_amount=B.freight_sgst_amount,
		other_charges_taxable_value=B.other_charges_taxable_value,other_charges_igst_amount=B.other_charges_igst_amount,
		other_charges_cgst_amount=B.other_charges_cgst_amount,other_charges_sgst_amount=B.other_charges_sgst_amount,
		insurance_taxable_value=B.insurance_taxable_value,insurance_igst_amount=B.insurance_igst_amount,
		insurance_cgst_amount=B.insurance_cgst_amount,insurance_sgst_amount=B.insurance_sgst_amount,
		packing_taxable_value=B.packing_taxable_value,packing_igst_amount=B.packing_igst_amount,
		packing_cgst_amount=B.packing_cgst_amount,packing_sgst_amount=B.packing_sgst_amount,
		ROUND_OFF=B.ROUND_OFF,EXCISE_DUTY_AMOUNT=B.EXCISE_DUTY_AMOUNT,EXCISE_EDU_CESS_AMOUNT=B.EXCISE_EDU_CESS_AMOUNT,
		EXCISE_HEDU_CESS_AMOUNT=B.EXCISE_HEDU_CESS_AMOUNT,net_amount=B.net_amount,TOTAL_QUANTITY=B.TOTAL_QUANTITY,
		Total_Gst_Amount=B.Total_Gst_Amount,TOTAL_PACKSLIP_NO=B.TOTAL_PACKSLIP_NO,gst_round_off=B.gst_round_off,
		TCS_BASEAMOUNT=isnull(b.TCS_BASEAMOUNT,0),TCS_PERCENTAGE=isnull(b.TCS_PERCENTAGE,0),TCS_AMOUNT=isnull(b.TCS_AMOUNT,0) ,
		TOTAL_GST_CESS_AMOUNT=ISNULL(B.TOTAL_GST_CESS_AMOUNT,0),
		BROKER_COMM_AMOUNT='+RTRIM(LTRIM(STR(@NTAXVALUE)))+'*broker_comm_percentage/100,
		BROKER_tds_AMOUNT=(('+RTRIM(LTRIM(STR(@NTAXVALUE)))+'*broker_comm_percentage/100)*A.broker_tds_percentage/100)
		FROM '+@cMstTable+' (ROWLOCK) a JOIN #tMstTable b ON a.inv_id=b.inv_id WHERE '+@cWhereClauseInd

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep=262.8
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1		
		
	     
		 
		--if @@spid=160
		--	select 'check before caltotals', SUM(IGST_AMOUNT),SUM(XN_VALUE_WITHOUT_GST) FROM wsl_ind01106_upload 
		--	where sp_id=@nSpId

		SET @cCmd=N'UPDATE a SET INMDISCOUNTAMOUNT=B.INMDISCOUNTAMOUNT,item_round_off=B.item_round_off,hsn_code=B.hsn_code,
		gst_percentage=B.gst_percentage,igst_amount=B.igst_amount,cgst_amount=B.Cgst_amount,
		sgst_amount=B.Sgst_amount,xn_value_with_gst=B.xn_value_with_gst,xn_value_without_gst=B.xn_value_without_gst,
		CESS_AMOUNT=B.CESS_AMOUNT,
		GST_CESS_PERCENTAGE=B.GST_CESS_PERCENTAGE,
		GST_CESS_AMOUNT=B.GST_CESS_AMOUNT  ,
		TAX_ROUND_OFF=B.TAX_ROUND_OFF
		FROM '+@cDetTable+' a (ROWLOCK) JOIN #tDetTable b ON a.row_id=b.row_id
		WHERE '+@cWhereClauseInd
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		--if @@spid=364
		--	select 'check after caltotals', sum(cgst_amount),sum(sgst_amount), SUM(IGST_AMOUNT),SUM(XN_VALUE_WITHOUT_GST) FROM wsl_ind01106_upload 
		--	where sp_id=@nSpId

		SET @cStep=263
		EXEC SP_CHKXNSAVELOG 'wSL',@cStep,0,@nSpId,'',1			

		SET @cCmd=N'UPDATE a SET amount=b.amount from '+@cPayModeTable+' a (ROWLOCK)
					JOIN #tPaymode b ON a.row_id=b.row_id WHERE '+REPLACE(@cWhereClause,'inv_id','memo_id')
		PRINT @cCmd
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
		              TAX_ROUND_OFF=B.TAX_ROUND_OFF ,
		              hsn_code =b.hsn_code
		  FROM IND01106 A (NOLOCK)
		  JOIN #TDETTABLE B ON A.ROW_ID =B.ROW_ID 
		  WHERE A.INV_ID =@CINVID
		  and (a.CGST_AMOUNT+a.SGST_AMOUNT+a.IGST_AMOUNT)<>(b.CGST_AMOUNT+b.SGST_AMOUNT+b.IGST_AMOUNT)

	  END
		 
		--if @@spid=51
		--begin
		--	select 'after inm', inv_id,subtotal,net_amount from #tMstTable

		--	select 'after ind',sum(net_rate*quantity),sum(igst_amount+cgst_amount+sgst_amount) from #tdetTable 
		--end

		GOTO END_PROC
END TRY

BEGIN CATCH
	print 'enter catch of SP3S_CALTOTALS_WSL'+@cStep+' '+ERROR_MESSAGE()
	SET @CERRORMSG=' SPID : '+LTRIM(RTRIM((@nSpId)))+' || Error in SP3S_CALTOTALS_WSL at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END