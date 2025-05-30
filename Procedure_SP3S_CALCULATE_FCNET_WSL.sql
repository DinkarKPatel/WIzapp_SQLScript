
create Procedure SP3S_CALCULATE_FCNET_WSL
(
 @CINVID VARCHAR(50),
 @BCALLEDFORLIST BIT=0

)
AS
BEGIN

		IF OBJECT_ID ('TEMPDB..#TMPFCRATE','U') IS  NULL
		BEGIN
		      SELECT ROW_ID  =CAST('' AS VARCHAR(100)),
					 CAST(0 AS NUMERIC(14,2)) AS FC_NET,
					 CAST(0 AS NUMERIC(14,2)) AS FC_GST_PERCENTAGE,
					 CAST(0 AS INT) AS FC_TAX_METHOD,
					 CAST(0 AS BIT) AS IS_IGST,
					 CAST(0 AS NUMERIC(14,2)) AS FC_XN_VALUE_WITHOUT_GST,
					 CAST(0 AS NUMERIC(10,2)) AS FC_IGST_AMOUNT,
					 CAST(0 AS NUMERIC(10,2)) AS FC_CGST_AMOUNT,
					 CAST(0 AS NUMERIC(10,2)) AS FC_SGST_AMOUNT,
					 CAST(0 AS NUMERIC(14,2)) AS FC_XN_VALUE_WITH_GST
			   INTO #TMPFCRATE
			   WHERE 1=2


		 END

	       INSERT INTO #TMPFCRATE(ROW_ID,FC_NET,FC_GST_PERCENTAGE,FC_TAX_METHOD,IS_IGST)
				SELECT A.ROW_ID ,
					   FC_NET = ((A.net_rate*A.INVOICE_QUANTITY)-A.INMDISCOUNTAMOUNT)/B.fc_rate,
					   A.GST_PERCENTAGE,B.bill_level_tax_method ,
					   CASE WHEN A.igst_amount <>0 THEN 1 ELSE 0 END AS IS_IGST
				FROM IND01106 A  (NOLOCK) 
				JOIN INM01106 B (NOLOCK) ON A.INV_ID=B.INV_ID 
				WHERE A.INV_ID = @CINVID  
				AND ISNULL(B.fc_rate,0)<>0

			UPDATE TMP SET 
			                FC_XN_VALUE_WITHOUT_GST =ROUND(FC_NET-(FC_NET*(CASE WHEN FC_TAX_METHOD=2 THEN ((ISNULL(TMP.FC_GST_PERCENTAGE,0))/  
			               (100 + ISNULL(TMP.FC_GST_PERCENTAGE,0))) ELSE 0 END)),2),

			               FC_XN_VALUE_WITH_GST= ROUND((FC_NET)+((FC_NET)*(CASE WHEN FC_TAX_METHOD=2 THEN 0   
                           ELSE ((ISNULL(TMP.FC_GST_PERCENTAGE,0))/100) END)) ,2)

			FROM #TMPFCRATE TMP

			UPDATE TMP SET 
			                FC_IGST_AMOUNT =CASE WHEN IS_IGST=1 THEN FC_XN_VALUE_WITH_GST-FC_XN_VALUE_WITHOUT_GST
							               ELSE 0 END ,
                             FC_CGST_AMOUNT =ROUND(CASE WHEN IS_IGST<>1 THEN FC_XN_VALUE_WITH_GST-FC_XN_VALUE_WITHOUT_GST
							               ELSE 0 END/2,2),
                             FC_SGST_AMOUNT=ROUND(CASE WHEN IS_IGST<>1 THEN FC_XN_VALUE_WITH_GST-FC_XN_VALUE_WITHOUT_GST
							               ELSE 0 END/2,2)
			FROM #TMPFCRATE TMP

		IF @BCALLEDFORLIST=0
		BEGIN
		    
		 DECLARE @NFCOTH NUMERIC(10,2),@NFCFREIGHT NUMERIC(10,2),@Ninsurance NUMERIC(10,2),@Npacking NUMERIC(10,2)

		   SELECT @NFCFREIGHT=ROUND(FREIGHT+CASE WHEN OH_TAX_METHOD =1 THEN  ISNULL(FREIGHT_IGST_AMOUNT,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0)
		        ELSE 0 END /ISNULL(FC_RATE,0),2)
		   FROM INM01106 WITH (NOLOCK) WHERE inv_id= @CINVID
		   AND FREIGHT <>0 AND ISNULL(FC_RATE,0)<>0

		   SELECT @NFCOTH=ROUND(other_charges+CASE WHEN OH_TAX_METHOD =1 THEN  ISNULL(OTHER_CHARGES_IGST_AMOUNT,0)+ISNULL(other_charges_CGST_AMOUNT,0)+ISNULL(other_charges_SGST_AMOUNT,0)
		        ELSE 0 END /ISNULL(FC_RATE,0),2)
		   FROM INM01106 WITH (NOLOCK) WHERE inv_id= @CINVID
		   AND other_charges <>0 AND ISNULL(FC_RATE,0)<>0

		   SELECT @Ninsurance=ROUND(insurance+CASE WHEN OH_TAX_METHOD =1 THEN  ISNULL(insurance_IGST_AMOUNT,0)+ISNULL(insurance_CGST_AMOUNT,0)+ISNULL(insurance_SGST_AMOUNT,0)
		        ELSE 0 END /ISNULL(FC_RATE,0),2)
		   FROM INM01106 WITH (NOLOCK) WHERE inv_id= @CINVID
		   AND insurance <>0 AND ISNULL(FC_RATE,0)<>0

		   
		   SELECT @Npacking=ROUND(PACKING+CASE WHEN OH_TAX_METHOD =1 THEN  ISNULL(PACKING_IGST_AMOUNT,0)+ISNULL(PACKING_CGST_AMOUNT,0)+ISNULL(PACKING_SGST_AMOUNT,0)
		        ELSE 0 END /ISNULL(FC_RATE,0),2)
		   FROM INM01106 WITH (NOLOCK) WHERE inv_id= @CINVID
		   AND PACKING <>0 AND ISNULL(FC_RATE,0)<>0

		   SELECT SUM(FC_XN_VALUE_WITH_GST)+isnull(@NFCOTH,0)+isnull(@NFCFREIGHT,0)+isnull(@Ninsurance,0)+isnull(@Npacking,0) AS FC_TOTAL_AMOUNT
		   from #TMPFCRATE

		END
	
	
		

END