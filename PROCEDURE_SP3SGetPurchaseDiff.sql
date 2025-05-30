CREATE PROCEDURE SP3SGETPURCHASEDIFF
(
	  @DFROMDT DATETIME
	 ,@CLOC VARCHAR(5)=''
	 ,@DTODT DATETIME
)
--WITH ENCRYPTION 
AS 
BEGIN
/*EXEC SP3SGETPURCHASEDIFF 'HO0111600000HO00000003'*/

    IF OBJECT_ID('TEMPDB..#PURCHASEHEADERDETAILS','U') IS NOT NULL
		DROP TABLE #PURCHASEHEADERDETAILS

	SELECT 
		   --INVOICE DETAILS	
		   PIM.MRR_ID					AS INVOICE_ID
		  ,PIM.MRR_NO					AS INVOICE_NO
		  ,PIM.RECEIPT_DT				AS INVOICE_DATE
		  ,LMV.AC_NAME					AS INVOICE_SUPPLIER
		  ,PIM.SUBTOTAL					AS INVOICE_SUBTOTAL
		  ,PIM.DISCOUNT_PERCENTAGE		AS INVOICE_DISCOUNTPERCENTAGE	 
		  ,PIM.DISCOUNT_AMOUNT			AS INVOICE_DISCOUNTAMOUNT
		  ,PIM.EXCISE_DUTY_AMOUNT		AS INVOICE_EXCISEDUTYAMOUNT
		  ,SUM(PID.TAX_AMOUNT)			AS INVOICE_TAXAMOUNT
		  ,PIM.POSTTAXDISCOUNTAMOUNT	AS INVOICE_POSTTAXDISCOUNTAMOUNT
		  ,PIM.FREIGHT					AS INVOICE_FREIGHT
		  ,PIM.OTHER_CHARGES			AS INVOICE_OTHERCHARGES
		  ,PIM.ROUND_OFF				AS INVOICE_ROUNDOFF
		  ,PIM.TOTAL_AMOUNT				AS INVOICE_NETAMOUNT
		  ,SUM(PID.QUANTITY*PID.PURCHASE_PRICE)
										AS INVOICE_PURCHASEVALUE
		  ,SUM(PID.QUANTITY*PID.MRP)    AS INVOICE_MRPVALUE
		  ,CONVERT(NUMERIC(18,2),0)		AS INVOICE_MARKDOWN								
		  
		  --LEDGER DETAILS
		  ,PIM.SUBTOTAL				    AS LEDGER_SUBTOTAL 
		  ,ISNULL(LT.CD,0)				AS LEDGER_DISCOUNTPERCENTAGE	 
		  ,(CASE WHEN PIM.SUBTOTAL=0 THEN 0 ELSE
			CONVERT(NUMERIC(10,2),ISNULL(LT.CD,0)*PIM.SUBTOTAL/(100)) 
								   END) AS LEDGER_DISCOUNTAMOUNT
		  ,PIM.EXCISE_DUTY_AMOUNT		AS LEDGER_EXCISEDUTYAMOUNT
		  ,SUM(CASE WHEN PIM.BILL_LEVEL_TAX_METHOD=1 
					/*EXCLUSIVE TAX*/
					THEN ((PID.TAX_PERCENTAGE/100)*(PIM.SUBTOTAL-(CASE WHEN PIM.SUBTOTAL=0 THEN 0 ELSE
					CONVERT(NUMERIC(10,2),ISNULL(LT.CD,0)*PIM.SUBTOTAL/100) END)))
			ELSE
			/*INCLUSIVE TAX*/
			((PID.TAX_PERCENTAGE/(100+PID.TAX_PERCENTAGE))*(PIM.SUBTOTAL-(CASE WHEN PIM.SUBTOTAL=0 THEN 0 ELSE
			CONVERT(NUMERIC(10,2),ISNULL(LT.CD,0)*PIM.SUBTOTAL/100) END)))									   
								   END)			AS LEDGER_TAXAMOUNT
		  ,(CASE WHEN ISNULL(LT.REIMUBURSE_PURCHASE_TAX,0)=1 THEN SUM(PID.TAX_AMOUNT)
		  		ELSE 0 END)				AS LEDGER_POSTTAXDISCOUNTAMOUNT
		  ,(CASE WHEN ISNULL(LT.REIMUBURSE_FREIGHT,0)=0 THEN PIM.FREIGHT
						ELSE 0 END)		AS LEDGER_FREIGHT
		  ,(CASE WHEN ISNULL(LT.REIMUBURSE_INSURANCE,0)=0 THEN PIM.OTHER_CHARGES
						ELSE 0 END)		AS LEDGER_OTHERCHARGES
		  ,PIM.ROUND_OFF				AS LEDGER_ROUNDOFF
		  ,CONVERT(NUMERIC(18,2),0)		AS LEDGER_NETAMOUNT
		  ,SUM(PID.QUANTITY*PID.MRP)    AS LEDGER_MRPVALUE
		  ,CONVERT(NUMERIC(18,2),0)		AS LEDGER_PURCHASEVALUE
		  ,ISNULL(LT.GROSS_MARGIN,0)    AS LEDGER_MARKDOWN
		  ,PIM.DEPT_ID--19 FEB 2019	
	INTO #PURCHASEHEADERDETAILS
	FROM PIM01106 PIM(NOLOCK)
	JOIN LMV01106 LMV(NOLOCK) ON PIM.AC_CODE=LMV.AC_CODE
	JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
	LEFT OUTER JOIN LEDGER_TERMS LT(NOLOCK) ON PIM.TERMS=LT.TERMS
	GROUP BY PIM.MRR_ID,PIM.MRR_NO,PIM.RECEIPT_DT,LMV.AC_NAME,PIM.SUBTOTAL,PIM.DISCOUNT_PERCENTAGE,PIM.DISCOUNT_AMOUNT,PIM.EXCISE_DUTY_AMOUNT
		    ,PIM.POSTTAXDISCOUNTAMOUNT,PIM.FREIGHT,PIM.OTHER_CHARGES,PIM.ROUND_OFF
			,PIM.TOTAL_AMOUNT		  
		  --LEDGER DETAILS
		   ,ISNULL(LT.CD,0)
		  ,ISNULL(LT.REIMUBURSE_PURCHASE_TAX,0)
		  ,ISNULL(LT.REIMUBURSE_FREIGHT,0),ISNULL(LT.REIMUBURSE_INSURANCE,0)				
		  ,ISNULL(LT.GROSS_MARGIN,0)
		  ,PIM.DEPT_ID--19 FEB 2019	
		  
	--19 FEB 2019	
	DECLARE @SHOW_ALL BIT=0,@PUR_LOC BIT=0
    IF @CLOC='' SET @SHOW_ALL=1
    IF EXISTS(SELECT DEPT_ID FROM LOCATION (NOLOCK) WHERE DEPT_ID=@CLOC AND ISNULL(PUR_LOC,0)=1 AND @CLOC!='')
       SET @PUR_LOC=1

	IF @SHOW_ALL=0 
	   IF @PUR_LOC=1
	      DELETE #PURCHASEHEADERDETAILS WHERE DEPT_ID<>@CLOC
	   ELSE   
	      DELETE #PURCHASEHEADERDETAILS
	ALTER TABLE #PURCHASEHEADERDETAILS DROP COLUMN DEPT_ID
	--19 FEB 2019	
	
	UPDATE #PURCHASEHEADERDETAILS
			SET LEDGER_NETAMOUNT=LEDGER_SUBTOTAL-LEDGER_DISCOUNTAMOUNT+LEDGER_EXCISEDUTYAMOUNT
								 +LEDGER_TAXAMOUNT-LEDGER_POSTTAXDISCOUNTAMOUNT+LEDGER_FREIGHT
								 +LEDGER_OTHERCHARGES	
			   ,LEDGER_PURCHASEVALUE=LEDGER_MRPVALUE-(LEDGER_MRPVALUE*LEDGER_MARKDOWN/100.00)
			   ,INVOICE_MARKDOWN=(CASE WHEN INVOICE_MRPVALUE=0 THEN 0
									ELSE (((INVOICE_MRPVALUE-INVOICE_PURCHASEVALUE)/INVOICE_MRPVALUE)*100)
									END)
	UPDATE #PURCHASEHEADERDETAILS 
			SET  LEDGER_ROUNDOFF =ROUND(LEDGER_NETAMOUNT,0)-LEDGER_NETAMOUNT
				,LEDGER_NETAMOUNT=ROUND(LEDGER_NETAMOUNT,0)
	
	SELECT 
			--INVOICE DETAILS
			 INVOICE_NO
			,CONVERT(VARCHAR,INVOICE_DATE,105) AS INVOICE_DATE  
			,INVOICE_SUPPLIER
		  	,INVOICE_NETAMOUNT
		  	
		  	--LEDGER DETAILS
		  	,LEDGER_NETAMOUNT
		  	
		  	--DIFFERENCE CURSOR
		  	,(CASE WHEN INVOICE_NETAMOUNT>LEDGER_NETAMOUNT
		  		   THEN (INVOICE_NETAMOUNT - LEDGER_NETAMOUNT)
		  	  ELSE 0 END) AS DIFF_NETAMOUNT
	FROM #PURCHASEHEADERDETAILS
	WHERE INVOICE_NETAMOUNT>LEDGER_NETAMOUNT			
	ORDER BY INVOICE_DATE,INVOICE_NO
GOTO ENDPROC

ENDPROC:	
END
--END OF PROCEDURE - SP3SGETPURCHASEDIFF
