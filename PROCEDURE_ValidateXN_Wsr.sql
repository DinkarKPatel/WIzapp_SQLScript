CREATE PROCEDURE VALIDATEXN_WSR
 @CXNID VARCHAR(50),	
 @NUPDATEMODE INT,	
 @BCALLEDFORPRINT BIT=0, 		  		 
 @CERRORMSG VARCHAR(200) OUTPUT
--WITH ENCRYPTION
AS
BEGIN
	
	
	DECLARE @CPRODUCTCODE VARCHAR(50),@CCMD NVARCHAR(MAX),@NSUMCNDNET NUMERIC(10,2),@NSUBTOTAL NUMERIC(10,2),
			@NCALCTOTALAMOUNT NUMERIC(10,2),@NCNMTOTALAMOUNT NUMERIC(10,2),@NCALCDISCOUNTAMT NUMERIC(10,2),
			@NDISCOUNTAMT NUMERIC(10,2),@NCALCTAXVAL NUMERIC(10,2),@NUPDTAXVAL NUMERIC(10,2),
			@NGSTCESSAMOUNT NUMERIC(10,2),@NPAYMODETOTAMT NUMERIC(10,2)
		
	SELECT TOP 1 @CPRODUCTCODE=PRODUCT_CODE FROM CND01106 WHERE CN_ID=@CXNID  AND RATE=0
			   
	IF ISNULL(@CPRODUCTCODE,'')<>'' AND  ISNULL(@BCALLEDFORPRINT,0)=0
	BEGIN
		SET @CERRORMSG = 'INVALID RATE FOR ITEM CODE : '+@CPRODUCTCODE  +' ..... CANNOT SAVE '
		RETURN
	END
	

	IF ISNULL(@BCALLEDFORPRINT,0)=0 AND @NUPDATEMODE<>3
	BEGIN	
		PRINT 'VALIDATING MEMO DATE start'
		EXEC SP_VALIDATE_MEMODATE_OPT
			@CXNTYPE='WSR',
			@CXNID=@CXNID,
			@CERRORMSG=@CERRORMSG OUTPUT

			PRINT 'VALIDATING MEMO DATE end'
			IF @CERRORMSG<>''
				RETURN
PRINT 'VALIDATING MEMO DATE finish'
	END					

	SELECT @NSUMCNDNET=SUM(A.net_rate*A.INVOICE_QUANTITY) 
	FROM CND01106 A
	WHERE CN_ID=@CXNID

	-- CHECKING DISCOUNT AMOUNT AT ITEM LEVEL
	SELECT TOP 1 @CPRODUCTCODE=PRODUCT_CODE
	,@NCALCDISCOUNTAMT=ROUND((INVOICE_QUANTITY*RATE)*DISCOUNT_PERCENTAGE/100,0)
	,@NDISCOUNTAMT=DISCOUNT_AMOUNT FROM CND01106 WHERE CN_ID=@CXNID AND 
	ABS(ROUND((INVOICE_QUANTITY*RATE)*DISCOUNT_PERCENTAGE/100,0)-@NDISCOUNTAMT)>1
	
	IF ISNULL(@CPRODUCTCODE,'')<>''
	BEGIN
		SET @CERRORMSG='ITEM CODE : '+@CPRODUCTCODE+' MISMATCH BETWEEN EXPECTED DISCOUNT AMOUNT ('+
						LTRIM(RTRIM(STR(ISNULL(@NCALCDISCOUNTAMT,0),10,2)))+') &
						UPDATED DISCOUNT AMOUNT ('+LTRIM(RTRIM(STR(ISNULL(@NDISCOUNTAMT,0),10,2)))+')..... CANNOT SAVE '
		RETURN
	END


	
	SELECT @NSUBTOTAL =SUBTOTAL FROM CNM01106 WHERE CN_ID=@CXNID



	IF ABS(ISNULL(@NSUMCNDNET,0)-ISNULL(@NSUBTOTAL,0))>1
	BEGIN
		SET @CERRORMSG = 'MISMATCH BETWEEN ITEM LEVEL TOTAL AMOUNT :'+ltrim(rtrim(str(@NSUMCNDNET)))+' & BILL LEVEL SUBTOTAL :'+ltrim(rtrim(str(@NSUBTOTAL,10,2)))+'..... CANNOT SAVE '
		RETURN
	END
	
	-- CHECKING DISCOUNT AMOUNT AT BILL LEVEL
	SELECT @NCALCDISCOUNTAMT = ROUND(SUBTOTAL*DISCOUNT_PERCENTAGE/100,0) FROM CNM01106 WHERE CN_ID=@CXNID
	
	SELECT @NDISCOUNTAMT = DISCOUNT_AMOUNT FROM  CNM01106 WHERE CN_ID=@CXNID
		
	IF 	ABS(@NDISCOUNTAMT-ISNULL(@NCALCDISCOUNTAMT,0))>1
	BEGIN
		SET @CERRORMSG='MISMATCH BETWEEN BILL LEVEL EXPECTED DISCOUNT AMOUNT ('+LTRIM(RTRIM(STR(
						ISNULL(@NCALCDISCOUNTAMT,0),10,2)))+') &
						UPDATED DISCOUNT AMOUNT ('+LTRIM(RTRIM(STR(ISNULL(@NDISCOUNTAMT,0),10,2)))+')..... CANNOT SAVE '

		RETURN
	END
	
	SELECT @NCALCTAXVAL=SUM(ITEM_TAX_AMOUNT+ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(CESS_AMOUNT,0)) ,
	       @NGSTCESSAMOUNT=SUM(ISNULL(GST_CESS_AMOUNT,0))
	FROM CND01106 
	WHERE CN_ID=@CXNID AND BILL_LEVEL_TAX_METHOD=1
	
	SELECT @NCALCTOTALAMOUNT = SUBTOTAL + FREIGHT+INSURANCE -DISCOUNT_AMOUNT + OTHER_CHARGES+ROUND_OFF+ISNULL(@NCALCTAXVAL,0)+isnull(@NGSTCESSAMOUNT,0)
		 +(CASE WHEN OH_TAX_METHOD=2 THEN 0 ELSE  (ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+
		 ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0)) 
	     +( ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0))
	     +ISNULL(INSURANCE_IGST_AMOUNT,0)+ISNULL(INSURANCE_CGST_AMOUNT,0)+ISNULL(INSURANCE_SGST_AMOUNT,0) END)
	FROM CNM01106 WHERE CN_ID=@CXNID	

	SELECT @NCNMTOTALAMOUNT=TOTAL_AMOUNT FROM CNM01106 WHERE CN_ID=@CXNID
	
	IF ABS(ISNULL(@NCNMTOTALAMOUNT,0)-ISNULL(@NCALCTOTALAMOUNT,0))>1
	BEGIN
		SET @CERRORMSG = 'MISMATCH BETWEEN CALCULATED NET AMOUNT '+LTRIM(RTRIM(STR(ISNULL(@NCALCTOTALAMOUNT,0),14,4)))+
					' & BILL LEVEL NET AMOUNT '+LTRIM(RTRIM(STR(ISNULL(@NCNMTOTALAMOUNT,0),14,4))) -- +'..... CANNOT SAVE '
		RETURN
	END
	
IF ISNULL(@BCALLEDFORPRINT,0)=0
	BEGIN

		SELECT @NPAYMODETOTAMT = SUM(AMOUNT) FROM PAYMODE_XN_DET A (NOLOCK)  WHERE MEMO_ID=@CXNID AND XN_TYPE='WSR'
		SET @NPAYMODETOTAMT = ISNULL(@NPAYMODETOTAMT,0)  

		IF @NCNMTOTALAMOUNT<>@NPAYMODETOTAMT
		BEGIN  

			 SET @CERRORMSG='TOTAL AMOUNT '+STR(@NCNMTOTALAMOUNT,14,2)+' SHOULD BE EQUAL TO THE SUM OF ALL PAYMENT MODES '+STR(@NPAYMODETOTAMT,14,2)+'...PLEASE CHECK'  
			 RETURN
		END

   end



	IF EXISTS(SELECT TOP 1 A.cn_id FROM cnd01106 A (nolock) JOIN cnm01106  B ON  A.cn_id=B.cn_id
			  JOIN SKU (nolock) ON SKU.PRODUCT_CODE=A.PRODUCT_CODE
			  WHERE a.CN_ID=@CXNID	and  (ISNULL(B.MEMO_TYPE,0)<>2 AND ISNULL(SKU.ER_FLAG,0)=2) OR (ISNULL(B.MEMO_TYPE,0)=2 AND ISNULL(SKU.ER_FLAG,0)<>2))
	BEGIN
		
		 declare @CERRORPC varchar(50)
		SELECT TOP 1 @CERRORPC=A.PRODUCT_CODE FROM cnd01106 A (nolock) JOIN cnm01106  B (nolock) ON  A.cn_id=B.cn_id
 	    JOIN SKU ON SKU.PRODUCT_CODE=A.PRODUCT_CODE
		WHERE a.CN_ID=@CXNID and (ISNULL(B.MEMO_TYPE,0)<>2 AND ISNULL(SKU.ER_FLAG,0)=2) OR (ISNULL(B.MEMO_TYPE,0)=2 AND ISNULL(SKU.ER_FLAG,0)<>2)
			  
		SET @CERRORMSG='MEMO TYPE OF ITEM CODE :'+@CERRORPC+' DOES NOT MATCH WITH THAT OF MEMO....PLEASE CHECK'
		RETURN
	END


		
		
	
	
	    DECLARE @COUNTRY_CODE VARCHAR(10) 
        SELECT  TOP 1 @COUNTRY_CODE=ISNULL(C.COUNTRY_CODE,'')
		FROM CNM01106   A JOIN LMP01106 B ON A.AC_CODE=B.AC_CODE 
		LEFT OUTER JOIN AREA AR ON AR.AREA_CODE =B.AREA_CODE 
		LEFT OUTER JOIN CITY CT ON CT.CITY_CODE =AR.CITY_CODE 
		LEFT OUTER JOIN STATE ST ON ST.STATE_CODE =CT.STATE_CODE 
		LEFT OUTER JOIN REGIONM R ON R.REGION_CODE =ST.REGION_CODE
		LEFT OUTER JOIN COUNTRY C ON C.COUNTRY_CODE=R.COUNTRY_CODE
		WHERE A.CN_ID =@CXNID
     
	    
    IF @NUPDATEMODE<>3 AND ISNULL(@COUNTRY_CODE,'')  IN('0000000','')
    BEGIN

	   EXEC SP3S_VALIDATE_GSTCALC 'WSR',@CXNID,@CERRORMSG OUTPUT
		IF ISNULL(@CERRORMSG,'')<>''		
		RETURN
	END
		
	
	
	print 'end of validation wsr'
END 
------- 'END OF CREATING PROCEDURE VALIDATEXN_WSR'