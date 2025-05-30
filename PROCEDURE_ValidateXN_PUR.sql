create PROCEDURE VALIDATEXN_PUR
 @CXNID VARCHAR(50),	
 @NUPDATEMODE INT,
 @BCALLEDFORPRINT BIT=0, 		  			 
 @CERRORMSG VARCHAR(200) OUTPUT,
 @CDEPT_ID VARCHAR(5)/**//*Rohit 07-11-2024*/=''
-- WITH ENCRYPTION
AS
BEGIN
	DECLARE @CCMD NVARCHAR(4000),@NSUMPIDNET NUMERIC(14,2),@NSUBTOTAL NUMERIC(14,2),@NCALCTOTALAMOUNT NUMERIC(14,2),
	@NMSTTOTALAMOUNT NUMERIC(14,2), @NTAXVAL NUMERIC(14,2),@NCALCTAXVAL NUMERIC(14,2),
	@NMRPVAL NUMERIC(14,2),@NCALCDISCOUNTAMT NUMERIC(14,2),@NDISCOUNTAMT NUMERIC(14,2),
	@CITEMNAME VARCHAR(100),@CBATCHNO VARCHAR(20),@NCALCPURAMOUNT NUMERIC(14,2),@NPURAMOUNT NUMERIC(14,2),
	@CEXPRERRORMSG VARCHAR(MAX),@NTAX NUMERIC(20,2),@CcurLOCID varchar(5)/**//*Rohit 07-11-2024*/,@CHODEPT_ID varchar(5)/**//*Rohit 07-11-2024*/,
	@TotalgstcessAmount NUMERIC(10,2)
	
			
	SET @CERRORMSG=''

	
	  SELECT @CcurLOCID=VALUE FROM CONFIG WHERE CONFIG_OPTION ='LOCATION_ID'
     SELECT @CHODEPT_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'

	 IF @CcurLOCID=@CHODEPT_ID and @BCALLEDFORPRINT=1
	 return


	
	DECLARE @CPIMTABLE TABLE ( MRR_ID VARCHAR(50), MRR_NO VARCHAR(40), RECEIPT_DT DATETIME, 
							   INV_DT DATETIME, AC_CODE VARCHAR(10), FIN_YEAR VARCHAR(10),
							   CANCELLED BIT, SUBTOTAL NUMERIC(14,2), DISCOUNT_AMOUNT NUMERIC(18,2),
							   TAX_AMOUNT NUMERIC(18,2), FREIGHT NUMERIC(18,2), OTHER_CHARGES NUMERIC(18,2),
							   ROUND_OFF NUMERIC(18,2), TOTAL_AMOUNT NUMERIC(14,2), tcs_amount numeric(12,2),
							    DISCOUNT_PERCENTAGE NUMERIC(18,2), TAX_PERCENTAGE NUMERIC(7,3),
							    EXCISE_DUTY_AMOUNT NUMERIC(18,2),BILL_LEVEL_TAX_METHOD NUMERIC(5),MANUAL_DISCOUNT BIT 
							    ,POSTTAXDISCOUNTAMOUNT NUMERIC(18,2),freight_taxable_value numeric(10,2),other_charges_taxable_value numeric(10,2),
							    OTHER_CHARGES_IGST_AMOUNT NUMERIC(18,2),OTHER_CHARGES_CGST_AMOUNT  NUMERIC(18,2),OTHER_CHARGES_SGST_AMOUNT NUMERIC(18,2),
								FREIGHT_IGST_AMOUNT  NUMERIC(18,2),FREIGHT_CGST_AMOUNT NUMERIC(18,2),FREIGHT_SGST_AMOUNT  NUMERIC(18,2),OH_TAX_METHOD NUMERIC(5,0),
							   MRR_DT DATETIME,xn_item_type NUMERIC(1,0),pim_mode NUMERIC(1,0) )/*UNMERGED:10082015*/
	
	DECLARE @CPIDTABLE TABLE ( MRR_ID VARCHAR(50), PRODUCT_CODE VARCHAR(50), PURCHASE_PRICE NUMERIC(18,3),
							   INVOICE_QUANTITY NUMERIC(18,3),TAX_AMOUNT NUMERIC(14,4),
							   IGST_AMOUNT NUMERIC(14,4),
							   CGST_AMOUNT NUMERIC(14,4),
                               SGST_AMOUNT NUMERIC(14,4),
                               CESS_AMOUNT NUMERIC(14,4) ,
							   GST_CESS_AMOUNT NUMERIC(14,4) 
							   
							   )
	
	INSERT @CPIMTABLE
	SELECT	MRR_ID, MRR_NO, RECEIPT_DT, INV_DT, AC_CODE, FIN_YEAR, CANCELLED, SUBTOTAL, DISCOUNT_AMOUNT,
			TAX_AMOUNT, CASE WHEN ISNULL(FRIGHT_PAY_MODE,0)=2 THEN 0 ELSE  FREIGHT END, OTHER_CHARGES, ROUND_OFF, 
			TOTAL_AMOUNT,tcs_amount, DISCOUNT_PERCENTAGE, TAX_PERCENTAGE,
			EXCISE_DUTY_AMOUNT,BILL_LEVEL_TAX_METHOD,MANUAL_DISCOUNT,POSTTAXDISCOUNTAMOUNT,
			freight_taxable_value,other_charges_taxable_value,
			OTHER_CHARGES_IGST_AMOUNT,OTHER_CHARGES_CGST_AMOUNT,OTHER_CHARGES_SGST_AMOUNT,
			FREIGHT_IGST_AMOUNT,FREIGHT_CGST_AMOUNT,FREIGHT_SGST_AMOUNT,OH_TAX_METHOD,MRR_DT,xn_item_type,pim_mode
	FROM PIM01106 WHERE MRR_ID = @CXNID
	
	INSERT @CPIDTABLE 
	SELECT MRR_ID, PRODUCT_CODE, PURCHASE_PRICE, INVOICE_QUANTITY,TAX_AMOUNT,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,GST_CESS_AMOUNT
	FROM PID01106 WHERE MRR_ID = @CXNID
	

	if @NUPDATEMODE in(1,2)
	begin
	    IF EXISTS (SELECT TOP 1 'U' FROM   @CPIDTABLE A
		JOIN @CPIMTABLE PIM  ON A.MRR_ID=PIM.MRR_ID
		JOIN SKU B ON A.PRODUCT_CODE =B.PRODUCT_CODE
		JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE=B.ARTICLE_CODE 
		WHERE B.BARCODE_CODING_SCHEME=1 AND ISNULL(ART.STOCK_NA,0)=0
		and isnull(Pim.xn_item_type,0)<>2
		AND CHARINDEX ('@',A.PRODUCT_CODE)=0 ) 
		
		begin
		    	SET @CERRORMSG='FIXCODE CAN NOT SAVE WITHOUT BATCH CODING Please check'
			    RETURN

		end

	end

	if @NUPDATEMODE<>3
	BEGIN
	       IF EXISTS (SELECT TOP 1 'U' FROM   @CPIDTABLE A
			JOIN SKU B (nolock) ON A.PRODUCT_CODE =B.PRODUCT_CODE
			WHERE b.product_code <>''  AND RTRIM(LTRIM(b.ARTICLE_CODE)) IN ('','00000000','0000000'))
			begin
		    		SET @CERRORMSG='Blank Article Deatils Can Note Be Saved Please check'
					RETURN

			end
			
			IF EXISTS (SELECT TOP 1 'U' FROM @CPIMTABLE A
			join parcel_det b (nolock) on a.mrr_id =b.REF_MEMO_ID 
			join parcel_mst c (nolock) on b.parcel_memo_id =c.parcel_memo_id 
			where c.cancelled =0 and a.ac_code <>b.AC_CODE and c.xn_type ='PUR')
			begin
			    SET @CERRORMSG='Dispatch details and supplier of the Purchase are different, cannot be saved'
				RETURN
			
			end
			

			IF EXISTS (SELECT mrr_id FROM @CPIMTABLE WHERE pim_mode=7 AND xn_item_type<>4)
			BEGIN
				SET @cErrormsg='Parcel challans can only be converted in Service Purchase...Please check'
				RETURN
			END
			
			IF EXISTS (SELECT a.mrr_id FROM  @CPIMTABLE a WHERE pim_mode=7)
			BEGIN
				DECLARE @cServicePc VARCHAR(50)

				SELECT TOP 1 @cServicePc=value FROM config (NOLOCK)
				WHERE config_option='SERVICE_PC_PARCELCHALLANS'

				IF EXISTS (SELECT TOP 1 product_code FROM @CPIDTABLE WHERE product_code<>@cServicePc)
				BEGIN
					SET @cErrormsg='Bar codes other than :'+@cServicePc+' not allowed in Service Purchase of Parcel Challans...Please check'
					RETURN
				END
			END
	END
	
	IF exists (select top 1 MRR_ID FROM @CPIMTABLE where freight_taxable_value>freight or other_charges_taxable_value>other_charges)
	begin	
			SET @CERRORMSG='Overheads taxable value cannot be more that overhead itself ..... PLEASE CHECK'
			RETURN
	end

	IF exists (select top 1 MRR_ID FROM @CPIMTABLE where RECEIPT_DT>MRR_DT )
	begin	
			SET @CERRORMSG='Receipt Date can not be Greater than Mrr Date ..... PLEASE CHECK'
			RETURN
	end
	
	IF @NUPDATEMODE <>1
	BEGIN
		EXEC VALIDATEXN_PUR_BEFORE_EDIT @CXNID,0,@CERRORMSG OUTPUT,@CEXPRERRORMSG OUTPUT
		
		IF ISNULL(@CERRORMSG,'')<>''
		BEGIN
			
			IF ISNULL(@CEXPRERRORMSG,'')<>''
				EXEC SP_EXECUTESQL @CEXPRERRORMSG
			
			RETURN
		END
	END
   
        
    IF @NUPDATEMODE<>3
    BEGIN
	   --VALIDATE CALLING FOR GST
	   EXEC SP3S_VALIDATE_GSTCALC 'PUR',@CXNID,@CERRORMSG OUTPUT,@CDEPT_ID
	   IF ISNULL(@CERRORMSG,'')<>''		
		RETURN
	   
	   --VALIDATE CALLING FOR GST
	   EXEC SP3S_VALIDATE_CDCALC @CXNID,@CERRORMSG OUTPUT
	   IF ISNULL(@CERRORMSG,'')<>''		
			RETURN
    END	

	IF ISNULL(@BCALLEDFORPRINT,0)=0
	BEGIN
	-- IF CANCELLED MEMO THEN RETURN	
	IF EXISTS(SELECT A.AC_CODE FROM @CPIMTABLE A WHERE  CANCELLED=1)
		RETURN
END		
		
	-- BILL LEVEL SUBTOTAL VALIDATION
	SELECT @NSUMPIDNET=SUM(INVOICE_QUANTITY*PURCHASE_PRICE)
    FROM @CPIDTABLE 
	
	SELECT @NSUBTOTAL =SUBTOTAL FROM @CPIMTABLE 
    
    PRINT STR(ISNULL(@NSUMPIDNET,0))+STR(ISNULL(@NSUBTOTAL,0))
	IF ABS(ISNULL(@NSUMPIDNET,0)-ISNULL(@NSUBTOTAL,0))>2
	BEGIN
		SET @CERRORMSG='MISMATCH BETWEEN ITEM WISE TOTAL ('+LTRIM(RTRIM(STR(ISNULL(@NSUMPIDNET,0),10,2)))+') &
					    BILL LEVEL SUBTOTAL ('+LTRIM(RTRIM(STR(ISNULL(@NSUBTOTAL,0),10,2)))+')..... CANNOT SAVE '
		RETURN
	END
	
	IF EXISTS (SELECT MRR_ID FROM @CPIMTABLE WHERE ISNULL(MANUAL_DISCOUNT,0)=0)
	BEGIN
		-- CHECKING DISCOUNT AMOUNT AND DISCOUNT PERCENTAGE
		SELECT @NCALCDISCOUNTAMT = ROUND(SUBTOTAL*DISCOUNT_PERCENTAGE/100,0) FROM @CPIMTABLE
		
		SELECT @NDISCOUNTAMT = DISCOUNT_AMOUNT FROM @CPIMTABLE
			
		IF 	ABS(@NDISCOUNTAMT-ISNULL(@NCALCDISCOUNTAMT,0))>1
		BEGIN
			SET @CERRORMSG='MISMATCH BETWEEN EXPECTED DISCOUNT AMOUNT ('+LTRIM(RTRIM(STR(ISNULL(@NCALCDISCOUNTAMT,0),10,2)))+') &
							UPDATED DISCOUNT AMOUNT ('+LTRIM(RTRIM(STR(ISNULL(@NDISCOUNTAMT,0),10,2)))+')..... CANNOT SAVE '

			RETURN
		END
	END
	
	-- CHECKING  MISMATCH BETWEEN FOR NET AMOUNT
	
	--SELECT PRODUCT_CODE ,TAX_AMOUNT FROM @CPIDTABLE   WHERE MRR_ID=@CKEYFIELDVAL1  
	SELECT @NTAX=ROUND(SUM(TAX_AMOUNT+ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(CESS_AMOUNT,0)),3) ,
	       @TotalgstcessAmount=ROUND(SUM(ISNULL(GST_CESS_AMOUNT,0)),3) 
	FROM @CPIDTABLE


	SELECT @NCALCTOTALAMOUNT = (SUBTOTAL + isnull(tcs_amount,0)+
							   (CASE WHEN BILL_LEVEL_TAX_METHOD = 2 THEN 0 ELSE ISNULL(@NTAX,0)+ISNULL(@TotalgstcessAmount,0) END ) 
							   + isnull(ROUND_OFF,0) + OTHER_CHARGES + EXCISE_DUTY_AMOUNT+ FREIGHT ) 
							   - DISCOUNT_AMOUNT - POSTTAXDISCOUNTAMOUNT 
		  +(CASE WHEN ISNULL(OH_TAX_METHOD,0)=2 THEN 0 ELSE (ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0))
	      +( ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0)) END)
	FROM @CPIMTABLE 	

	SELECT @NMSTTOTALAMOUNT = TOTAL_AMOUNT FROM @CPIMTABLE WHERE MRR_ID=@CXNID
	
  
	
	
	IF ABS(ISNULL(@NMSTTOTALAMOUNT,0)-ISNULL(@NCALCTOTALAMOUNT,0))>5
	BEGIN
		SET @CERRORMSG = ' MISMATCH BETWEEN EXPECTED NET AMOUNT ('+LTRIM(RTRIM(STR(ISNULL(@NCALCTOTALAMOUNT,0),14,4)))+')
					 & EXISTING BILL LEVEL NET AMOUNT ('+LTRIM(RTRIM(STR(ISNULL(@NMSTTOTALAMOUNT,0),14,4))) +')..... CANNOT SAVE '
		RETURN
	END	
END	
--**************************************** END OF PROCEDURE VALIDATEXN_PUR