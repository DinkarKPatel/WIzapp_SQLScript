CREATE PROCEDURE SP3S_GETPENDING_GRN
@NQUERYID NUMERIC(2,0),
@CACCODE CHAR(10)='',
@DLOGIN_DT DATETIME='',
@CDEPTID VARCHAR(5)='',
@CWHERECLAUSE VARCHAR(2000)=''

AS
BEGIN

IF @NQUERYID=1
	GOTO LBLMST
ELSE
IF @NQUERYID=2
	GOTO LBLDET	
ELSE
IF @NQUERYID=3
	GOTO LBLADJUSTEDMRRS
	
LBLMST:	

				
    IF OBJECT_ID('TEMPDB..#TMPPURCHALLAN','U') IS NOT NULL 
        DROP TABLE #TMPPURCHALLAN
        
    SELECT  CAST(0 AS BIT) AS BILLCHECK, SUM(B.QUANTITY ) AS TOTAL_QTY,  
            A.MEMO_NO AS PS_NO ,A.MEMO_DT AS PS_DT   ,A.MEMO_ID AS PS_ID,
			CAST('' AS NVARCHAR(10)) AS SRNO ,A.REMARKS 
			,A.MEMO_ID  ,A.MEMO_NO ,A.MEMO_DT  ,
			SUM(ISNULL(ISNULL(POD.PURCHASE_PRICE,E.PURCHASE_PRICE),0)* B.QUANTITY ) AS TOTAL_AMOUNT 			
			,CAST(0 AS NUMERIC(5,2)) AS TAX_PERCENTAGE 
			,C.AC_NAME,C.AC_CODE
	        ,A.REF_CONVERTED_MRR_ID,ISNULL(pd.party_inv_no,'') as inv_no,ISNULL(pd.party_inv_dt,'') as inv_dt
			INTO #TMPPURCHALLAN
			FROM GRN_PS_MST A (NOLOCK) 
			JOIN GRN_PS_DET  B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID 
			LEFT OUTER JOIN parcel_det pd (NOLOCK) ON pd.row_id=a.REF_PARCEL_ROW_ID
			JOIN LM01106 C (NOLOCK) ON A.AC_CODE=C.AC_CODE
			LEFT OUTER JOIN PIM01106 D (NOLOCK) ON D.MRR_ID=ISNULL(A.REF_CONVERTED_MRR_ID,0) AND D.CANCELLED=0
			LEFT OUTER JOIN POD01106 POD (NOLOCK) ON POD.ROW_ID =B.PO_ROW_ID 
			LEFT OUTER JOIN
			(
			 SELECT A.ROW_ID ,B.PURCHASE_PRICE   
			 FROM ASN_DET A (NOLOCK) 
			 JOIN POD01106 B ON A.PO_ROW_ID =B.ROW_ID 
			 GROUP BY A.ROW_ID ,B.PURCHASE_PRICE 
			) E ON E.ROW_ID =ISNULL(B.ASN_ROW_ID,'')
			WHERE A.AC_CODE=@CACCODE AND A.CANCELLED = 0 
			AND A.location_code = @CDEPTID AND  B.PRODUCT_CODE <> '' 
			AND (D.MRR_ID IS NULL OR D.MRR_ID=@CWHERECLAUSE)
			GROUP BY A.REMARKS ,A.MEMO_ID  ,A.MEMO_NO ,A.MEMO_DT,C.AC_NAME,C.AC_CODE
	        ,A.REF_CONVERTED_MRR_ID,ISNULL(pd.party_inv_no,'') ,ISNULL(pd.party_inv_dt,''),A.BIN_ID 

	
	SELECT D.*
	FROM #TMPPURCHALLAN D 
	ORDER BY D.AC_NAME
   --------------
	
	GOTO END_PROC   

LBLDET:   

	DECLARE @CCMD NVARCHAR(MAX)
	IF OBJECT_ID('#GRNLIST','U') IS NOT NULL
		DROP TABLE #GRNLIST
	
	SELECT MEMO_ID  INTO #GRNLIST FROM GRN_PS_MST WHERE 1=2
	SET @CCMD=N' SELECT MEMO_ID FROM GRN_PS_MST WHERE MEMO_ID IN ('+ @CWHERECLAUSE +')'
	INSERT #GRNLIST
	EXEC SP_EXECUTESQL @CCMD
	
		
	IF OBJECT_ID('TEMPDB..#TMP','U') IS NOT NULL
        DROP TABLE #TMP
        
    SELECT CAST(0 AS BIT) AS BILLCHECK ,W1.QUANTITY AS INVOICE_QUANTITY
     ,W1.QUANTITY AS GRN_QTY
     ,W1.*,W1.MEMO_ID  AS PO_ID,W2.MEMO_NO ,W2.MEMO_DT 
     ,W2.MEMO_NO AS PS_NO ,W2.MEMO_DT AS PS_DT  ,W2.MEMO_ID AS PS_ID
	 ,ISNULL(POD.HSN_CODE,ASN.HSN_CODE) AS HSN_CODE,
	  ISNULL(POD.ARTICLE_CODE,ASN.ARTICLE_CODE ) AS ARTICLE_CODE
	 ,B.ARTICLE_NO ,B.ARTICLE_NAME  ,C.PARA1_CODE,D.PARA2_CODE ,
	 F.PARA3_CODE ,G.PARA4_CODE ,H.PARA5_CODE ,I.PARA6_CODE 
	 ,C.PARA1_NAME,D.PARA2_NAME ,F.PARA3_NAME,PARA4_NAME ,PARA5_NAME,PARA6_NAME  
	 ,E.UOM_NAME,E.UOM_TYPE,B.UOM_CODE
	 ,B.CODING_SCHEME
	 ,ISNULL(POD.PURCHASE_PRICE,ASN.PURCHASE_PRICE) AS PURCHASE_PRICE
	 ,ISNULL(POD.GROSS_PURCHASE_PRICE,ASN.GROSS_PURCHASE_PRICE) AS GROSS_PURCHASE_PRICE
	 ,ISNULL(POD.MRP ,ASN.MRP) AS MRP
	 ,SM.SECTION_NAME,SD.SUB_SECTION_NAME,B.STOCK_NA  
	 ,ISNULL(E.UOM_TYPE,0) AS [UOM_UOM_TYPE]  
	 ,ISNULL(B.DT_CREATED,'') AS [ART_DT_CREATED]  
	 ,F.DT_CREATED AS [PARA3_DT_CREATED]  
	 ,B.ALIAS AS ARTICLE_ALIAS 
	 ,CONVERT (NUMERIC(10,2), ISNULL(ISNULL(POD.PURCHASE_PRICE,ASN.PURCHASE_PRICE),0) * W1.QUANTITY)  	AS AMOUNT 
	 ,'0000000' AS FORM_ID
	 ,'' AS FORM_NAME
	
	 INTO #TMP
	 FROM GRN_PS_DET   W1 (NOLOCK)   
	 JOIN GRN_PS_MST W2 (NOLOCK) ON W1.MEMO_ID = W2.MEMO_ID 
	 JOIN #GRNLIST L ON L.MEMO_ID =W2.MEMO_ID
	 LEFT OUTER JOIN POD01106 POD (NOLOCK) ON POD.ROW_ID =W1.PO_ROW_ID 
	 LEFT OUTER JOIN
	 (
		SELECT A.ROW_ID ,C.PURCHASE_PRICE ,C.HSN_CODE,
		       C.ARTICLE_CODE,C.PARA1_CODE,C.PARA2_CODE,
		       C.PARA3_CODE,C.MRP,PARA4_CODE,C.PARA5_CODE,C.PARA6_CODE
               ,C.GROSS_PURCHASE_PRICE
		FROM ASN_DET A (NOLOCK) 
		JOIN ASN_MST B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
		JOIN POD01106 C ON A.PO_ROW_ID =C.ROW_ID 
		WHERE B.CANCELLED =0
		GROUP BY A.ROW_ID ,C.PURCHASE_PRICE ,C.HSN_CODE,
		C.ARTICLE_CODE,C.PARA1_CODE,C.PARA2_CODE,
		C.PARA3_CODE,C.MRP,PARA4_CODE,C.PARA5_CODE,C.PARA6_CODE
         ,C.GROSS_PURCHASE_PRICE
	) ASN ON ASN.ROW_ID =ISNULL(W1.ASN_ROW_ID,'')
	 JOIN ARTICLE B   (NOLOCK) ON ISNULL(POD.ARTICLE_CODE,ASN.ARTICLE_CODE ) = B.ARTICLE_CODE            
	 JOIN SECTIOND SD (NOLOCK) ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE          
	 JOIN SECTIONM SM (NOLOCK) ON SD.SECTION_CODE = SM.SECTION_CODE          
	 JOIN PARA1 C (NOLOCK) ON ISNULL(POD.PARA1_CODE,ASN.PARA1_CODE) = C.PARA1_CODE            
	 JOIN PARA2 D (NOLOCK) ON ISNULL(POD.PARA2_CODE,ASN.PARA2_CODE) = D.PARA2_CODE            
	 JOIN PARA3 F (NOLOCK) ON ISNULL(POD.PARA3_CODE,ASN.PARA3_CODE) = F.PARA3_CODE            
	 JOIN PARA4 G (NOLOCK) ON ISNULL(POD.PARA4_CODE,ASN.PARA4_CODE) = G.PARA4_CODE            
	 JOIN PARA5 H (NOLOCK) ON ISNULL(POD.PARA5_CODE,ASN.PARA5_CODE) = H.PARA5_CODE            
	 JOIN PARA6 I (NOLOCK) ON ISNULL(POD.PARA6_CODE,ASN.PARA6_CODE) = I.PARA6_CODE   
	 LEFT OUTER JOIN UOM E (NOLOCK) ON B.UOM_CODE = E.UOM_CODE       
	 LEFT OUTER JOIN SKU_OH(NOLOCK) ON SKU_OH.PRODUCT_CODE=W1.PRODUCT_CODE  
     
     
     
     --UPDATE #TMP SET DISCOUNT_AMOUNT=SKU_DISCOUNT_AMOUNT, DISCOUNT_PERCENTAGE=SKU_DISCOUNT_PERCENTAGE,
     --PURCHASE_PRICE=GROSS_PURCHASE_PRICE-SKU_DISCOUNT_AMOUNT
     
     SELECT * FROM #TMP
    	
	GOTO END_PROC

LBLADJUSTEDMRRS:
	SELECT MEMO_NO ,MEMO_DT ,MEMO_ID  FROM GRN_PS_MST (NOLOCK)
	WHERE REF_CONVERTED_MRR_ID=@CWHERECLAUSE
	
	
	GOTO END_PROC

END_PROC:
	
END

