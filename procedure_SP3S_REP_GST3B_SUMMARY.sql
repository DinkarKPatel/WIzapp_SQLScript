create PROCEDURE SP3S_REP_GST3B_SUMMARY
(
  @DFMDATE DATETIME,
  @DTODATE DATETIME,
  @CGSTN_NO VARCHAR(100)='',
  @CLOC_TYPE INT=0,
  @CDEPT_ID VARCHAR(5)='',
  @NGSTR3B INT =0
)
AS
BEGIN
     --PROCEDURE WILL BE RETURN ONLY OUTPUT GST
      
      
      IF OBJECT_ID('TEMPDB..#TMPHSNDETAILS','U') IS NOT NULL
         DROP TABLE #TMPHSNDETAILS

      SELECT CAST('SLS' AS VARCHAR(100)) AS XN_TYPE,
             CAST(A.CM_ID AS VARCHAR(100)) AS MEMO_ID,
             A.OTHER_CHARGES_HSN_CODE AS HSN_CODE,
             CAST(1 AS NUMERIC(10,2)) AS QTY,
             ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE,0)+ ISNULL(OTHER_CHARGES_IGST_AMOUNT ,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0) AS NET_AMOUNT  ,
             ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE,0)  AS TAXABLE_VALUE,
             A.OTHER_CHARGES_IGST_AMOUNT AS IGST_AMOUNT,
             A.OTHER_CHARGES_CGST_AMOUNT AS CGST_AMOUNT,
             A.OTHER_CHARGES_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             CASE WHEN ISNULL(cus_gst_no,'')<>'' THEN 1 ELSE 0 END AS  REGISTERED_GST_DEALER,
             a.location_Code 
      INTO #TMPHSNDETAILS
      FROM CMM01106 A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
      JOIN CUSTDYM CUST (NOLOCK) ON CUST .customer_code =A.CUSTOMER_CODE 
      WHERE A.CANCELLED =0
      AND A.CM_DT BETWEEN @DFMDATE AND @DTODATE
     -- AND (@CDEPT_ID='' OR LEFT (A.CM_ID,2)=@CDEPT_ID)
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND ISNULL(A.OTHER_CHARGES_GST_PERCENTAGE,0)>0
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
      
      
      
      INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code )
      SELECT 'SLS' AS XN_TYPE,
             A.CM_ID AS MEMO_ID,
             CMD.HSN_CODE AS HSN_CODE,
             CAST(CMD.QUANTITY  AS NUMERIC(10,2)) AS QTY,
             ISNULL(CMD.XN_VALUE_WITH_GST,0)  AS NET_AMOUNT,
             ISNULL(CMD.XN_VALUE_WITHOUT_GST,0)  AS TAXABLE_VALUE,
             CMD.IGST_AMOUNT AS IGST_AMOUNT,
             CMD.CGST_AMOUNT AS CGST_AMOUNT,
             CMD.SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CMD.PRODUCT_CODE  AS PRODUCT_CODE ,
             A.PARTY_STATE_CODE,
             CASE WHEN ISNULL(cus_gst_no,'')<>'' THEN 1 ELSE 0 END AS  REGISTERED_GST_DEALER,
             a.location_Code 
      FROM CMM01106 A (NOLOCK)
      JOIN CMD01106 CMD (NOLOCK) ON A.CM_ID=CMD.CM_ID
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
	  LEFT OUTER JOIN HSN_MST HM ON HM.HSN_CODE =CMD.HSN_CODE 
	  JOIN CUSTDYM CUST (NOLOCK) ON CUST .customer_code =A.CUSTOMER_CODE 
      WHERE A.CANCELLED =0 --AND ISNULL(TAXABLE_ITEM,0)=1
      AND A.CM_DT BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
     
      
       INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code )
       SELECT CAST('WSL' AS VARCHAR(100)) AS XN_TYPE,
             A.INV_ID AS MEMO_ID,
             A.OTHER_CHARGES_HSN_CODE AS HSN_CODE,
             CAST(1 AS NUMERIC(10,2)) AS QTY,
             ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE ,0)+ ISNULL(OTHER_CHARGES_IGST_AMOUNT ,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0) AS NET_AMOUNT ,
             ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE,0) AS TAXABLE_VALUE,
             A.OTHER_CHARGES_IGST_AMOUNT AS IGST_AMOUNT,
             A.OTHER_CHARGES_CGST_AMOUNT AS CGST_AMOUNT,
             A.OTHER_CHARGES_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             LMP.REGISTERED_GST_DEALER,a.location_Code 
      FROM INM01106 A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.PARTY_DEPT_ID 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
      WHERE A.CANCELLED =0
      AND A.INV_DT BETWEEN @DFMDATE AND @DTODATE
      --AND (@CDEPT_ID='' OR LEFT (A.INV_ID,2)=@CDEPT_ID)
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
      AND ISNULL(A.OTHER_CHARGES ,0)>0
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
     
     
      
       INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code )
       SELECT CAST('WSL' AS VARCHAR(100)) AS XN_TYPE,
             A.INV_ID AS MEMO_ID,
          A.FREIGHT_HSN_CODE AS HSN_CODE,
             CAST(1 AS NUMERIC(10,2)) AS QTY,
             ISNULL(A.FREIGHT_TAXABLE_VALUE ,0)+ ISNULL(FREIGHT_IGST_AMOUNT ,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0) AS NET_AMOUNT ,
             ISNULL(A.FREIGHT_TAXABLE_VALUE,0) AS TAXABLE_VALUE,
             A.FREIGHT_IGST_AMOUNT AS IGST_AMOUNT,
             A.FREIGHT_CGST_AMOUNT AS CGST_AMOUNT,
             A.FREIGHT_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER,a.location_Code
      FROM INM01106 A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.PARTY_DEPT_ID 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
      WHERE A.CANCELLED =0
      AND A.INV_DT BETWEEN @DFMDATE AND @DTODATE
     -- AND (@CDEPT_ID='' OR LEFT (A.INV_ID,2)=@CDEPT_ID)
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND ISNULL(A.FREIGHT,0)>0
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
       AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
     
       INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code)
       SELECT CAST('WSL' AS VARCHAR(100)) AS XN_TYPE,
             A.INV_ID AS MEMO_ID,
             A.INSURANCE_HSN_CODE AS HSN_CODE,
             CAST(1 AS NUMERIC(10,2)) AS QTY,
             ISNULL(A.INSURANCE_TAXABLE_VALUE ,0)+ ISNULL(INSURANCE_IGST_AMOUNT ,0)+ISNULL(INSURANCE_CGST_AMOUNT,0)+ISNULL(INSURANCE_SGST_AMOUNT,0)  AS NET_AMOUNT ,
             ISNULL(A.INSURANCE_TAXABLE_VALUE,0) AS TAXABLE_VALUE,
             A.INSURANCE_IGST_AMOUNT AS IGST_AMOUNT,
             A.INSURANCE_CGST_AMOUNT AS CGST_AMOUNT,
             A.INSURANCE_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER,a.location_Code
      FROM INM01106 A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.PARTY_DEPT_ID 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
      WHERE A.CANCELLED =0
      AND A.INV_DT BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND ISNULL(A.INSURANCE,0)>0
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
       AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
     
      
       INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code)
       SELECT CAST('WSL' AS VARCHAR(100)) AS XN_TYPE,
             A.INV_ID AS MEMO_ID,
             A.PACKING_HSN_CODE AS HSN_CODE,
             CAST(1 AS NUMERIC(10,2)) AS QTY,
             ISNULL(A.PACKING_TAXABLE_VALUE ,0)+ ISNULL(PACKING_IGST_AMOUNT ,0)+ISNULL(PACKING_CGST_AMOUNT,0)+ISNULL(PACKING_SGST_AMOUNT,0) AS NET_AMOUNT ,
             ISNULL(A.PACKING_TAXABLE_VALUE,0)  AS TAXABLE_VALUE,
             A.PACKING_IGST_AMOUNT AS IGST_AMOUNT,
             A.PACKING_CGST_AMOUNT AS CGST_AMOUNT,
             A.PACKING_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER,a.location_Code
      FROM INM01106 A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.PARTY_DEPT_ID 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
      WHERE A.CANCELLED =0
      AND A.INV_DT BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND ISNULL(A.PACKING,0)>0
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
       AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
     
      INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code)
      SELECT 'WSL' AS XN_TYPE,
             A.INV_ID AS MEMO_ID,
             B.HSN_CODE AS HSN_CODE,
             CAST(B.QUANTITY  AS NUMERIC(10,2)) AS QTY,
              ISNULL(B.XN_VALUE_WITH_GST,0)  AS NET_AMOUNT ,
             ISNULL(B.XN_VALUE_WITHOUT_GST,0)  AS TAXABLE_VALUE,
             B.IGST_AMOUNT AS IGST_AMOUNT,
             B.CGST_AMOUNT AS CGST_AMOUNT,
             B.SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             B.PRODUCT_CODE  AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER ,a.location_Code
      FROM INM01106 A (NOLOCK) 
      JOIN IND01106 B (NOLOCK)  ON A.INV_ID =B.INV_ID
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.PARTY_DEPT_ID 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      JOIN LOCATION C (NOLOCK) ON C.DEPT_ID =A.location_Code 
      JOIN GST_STATE_MST D (NOLOCK)  ON C.GST_STATE_CODE =D.GST_STATE_CODE 
      WHERE A.CANCELLED =0
      AND A.INV_DT  BETWEEN @DFMDATE AND @DTODATE
      --AND (@CDEPT_ID='' OR LEFT (A.INV_ID,2)=@CDEPT_ID)
      AND (@CGSTN_NO='' OR C.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
     -- AND ISNULL(B.GST_PERCENTAGE,0)>0
      AND ISNULL(B.HSN_CODE ,'') NOT IN('','0000000000')
      AND (@CLOC_TYPE=0 OR ISNULL(C.LOC_TYPE,0) =@CLOC_TYPE)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(C.LOC_GST_NO ,'')
       AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
     

	  --B2CS WHOSALE CREDIT NOTE
	  
     INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code)
	     SELECT 
             CAST('WSR' AS VARCHAR(100)) AS XN_TYPE,
             A.CN_ID AS MEMO_ID,
             A.OTHER_CHARGES_HSN_CODE AS HSN_CODE,
             -(1)*CAST(1 AS NUMERIC(10,2)) AS QTY,
             -(1)*ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE ,0)+ ISNULL(OTHER_CHARGES_IGST_AMOUNT ,0)+ISNULL(OTHER_CHARGES_CGST_AMOUNT,0)+ISNULL(OTHER_CHARGES_SGST_AMOUNT,0) AS NET_AMOUNT ,
            -(1)* ISNULL(A.OTHER_CHARGES_TAXABLE_VALUE,0) AS TAXABLE_VALUE,
            -(1)* A.OTHER_CHARGES_IGST_AMOUNT AS IGST_AMOUNT,
           -(1)*A.OTHER_CHARGES_CGST_AMOUNT AS CGST_AMOUNT,
            -(1)* A.OTHER_CHARGES_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE ,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER,a.location_Code
       FROM CNM01106 A (NOLOCK)
       JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
	   JOIN GST_STATE_MST LS (NOLOCK)  ON LS.GST_STATE_CODE  =B.GST_STATE_CODE
	   LEFT OUTER JOIN LMP01106 LMP (NOLOCK)  ON LMP.AC_CODE =A.AC_CODE
       LEFT JOIN GST_STATE_MST LMPS (NOLOCK)  ON LMPS.GST_STATE_CODE  =A.PARTY_STATE_CODE
	   LEFT OUTER JOIN LOCATION RML (NOLOCK) ON RML.DEPT_ID =A.PARTY_DEPT_ID 
       WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
       --AND A.CN_TYPE=1
	   AND A.RECEIPT_DT BETWEEN @DFMDATE AND @DTODATE
	   AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
	   AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
	   -- AND  ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'') =''
       AND ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE ISNULL(RML.LOC_GST_NO,'') END,'')<> B.LOC_GST_NO
       AND ISNULL(A.OTHER_CHARGES_GST_PERCENTAGE,0)>0
       AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
	  -- AND A.TOTAL_AMOUNT<250000
      UNION ALL
       SELECT CAST('WSR' AS VARCHAR(100)) AS XN_TYPE,
             A.CN_ID  AS MEMO_ID,
             A.FREIGHT_HSN_CODE AS HSN_CODE,
            -(1)* CAST(1 AS NUMERIC(10,2)) AS QTY,
            -(1)* ISNULL(A.FREIGHT_TAXABLE_VALUE ,0)+ ISNULL(FREIGHT_IGST_AMOUNT ,0)+ISNULL(FREIGHT_CGST_AMOUNT,0)+ISNULL(FREIGHT_SGST_AMOUNT,0) AS NET_AMOUNT ,
            -(1)* ISNULL(A.FREIGHT_TAXABLE_VALUE,0) AS TAXABLE_VALUE,
             -(1)*A.FREIGHT_IGST_AMOUNT AS IGST_AMOUNT,
            -(1)* A.FREIGHT_CGST_AMOUNT AS CGST_AMOUNT,
            -(1)* A.FREIGHT_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER,a.location_Code
       FROM CNM01106 A (NOLOCK)
       JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
	   JOIN GST_STATE_MST LS (NOLOCK)  ON LS.GST_STATE_CODE  =B.GST_STATE_CODE
	   LEFT OUTER JOIN LMP01106 LMP (NOLOCK)  ON LMP.AC_CODE =A.AC_CODE
       LEFT JOIN GST_STATE_MST LMPS (NOLOCK)  ON LMPS.GST_STATE_CODE  =LMP.AC_GST_STATE_CODE
	   LEFT OUTER JOIN LOCATION RML (NOLOCK) ON RML.DEPT_ID =A.PARTY_DEPT_ID 
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      --AND A.CN_TYPE=1
	  AND A.RECEIPT_DT BETWEEN @DFMDATE AND @DTODATE
	  AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
	  AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
	 -- AND  ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'') =''
      AND ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE ISNULL(RML.LOC_GST_NO,'') END,'')<> B.LOC_GST_NO
      AND ISNULL(A.FREIGHT_GST_PERCENTAGE,0)>0
	  AND A.TOTAL_AMOUNT<250000
	  AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
      UNION ALL
       SELECT CAST('WSR' AS VARCHAR(100)) AS XN_TYPE,
             A.CN_ID  AS MEMO_ID,
             A.INSURANCE_HSN_CODE AS HSN_CODE,
            -(1)* CAST(1 AS NUMERIC(10,2)) AS QTY,
            -(1)* ISNULL(A.INSURANCE_TAXABLE_VALUE ,0)+ ISNULL(INSURANCE_IGST_AMOUNT ,0)+ISNULL(INSURANCE_CGST_AMOUNT,0)+ISNULL(INSURANCE_SGST_AMOUNT,0)  AS NET_AMOUNT ,
            -(1)* ISNULL(A.INSURANCE_TAXABLE_VALUE,0) AS TAXABLE_VALUE,
            -(1)* A.INSURANCE_IGST_AMOUNT AS IGST_AMOUNT,
            -(1)* A.INSURANCE_CGST_AMOUNT AS CGST_AMOUNT,
            -(1)*A.INSURANCE_SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100)) AS PRODUCT_CODE,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER,a.location_Code
       FROM CNM01106 A (NOLOCK)
       JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
	   JOIN GST_STATE_MST LS (NOLOCK)  ON LS.GST_STATE_CODE  =B.GST_STATE_CODE
	   LEFT OUTER JOIN LMP01106 LMP (NOLOCK)  ON LMP.AC_CODE =A.AC_CODE
       LEFT JOIN GST_STATE_MST LMPS (NOLOCK)  ON LMPS.GST_STATE_CODE  =LMP.AC_GST_STATE_CODE
	   LEFT OUTER JOIN LOCATION RML (NOLOCK) ON RML.DEPT_ID =A.PARTY_DEPT_ID 
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      --AND A.CN_TYPE=1
	  AND A.RECEIPT_DT BETWEEN @DFMDATE AND @DTODATE
	  AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
	  AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
	  --AND  ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'') =''
      AND ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE ISNULL(RML.LOC_GST_NO,'') END,'')<> B.LOC_GST_NO
      AND ISNULL(A.INSURANCE_GST_PERCENTAGE,0)>0
      AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
	 -- AND A.TOTAL_AMOUNT<250000
      UNION ALL
      SELECT 'WSR' AS XN_TYPE,
             A.CN_ID AS MEMO_ID,
             CND.HSN_CODE AS HSN_CODE,
             -(1)*CAST(CND.QUANTITY  AS NUMERIC(10,2)) AS QTY,
             -(1)* ISNULL(CND.XN_VALUE_WITH_GST,0)  AS NET_AMOUNT ,
            -(1)* ISNULL(CND.XN_VALUE_WITHOUT_GST,0)  AS TAXABLE_VALUE,
             -(1)*CND.IGST_AMOUNT AS IGST_AMOUNT,
             -(1)*CND.CGST_AMOUNT AS CGST_AMOUNT,
             -(1)*CND.SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CND.PRODUCT_CODE  AS PRODUCT_CODE ,
             A.PARTY_STATE_CODE,
             lmp.REGISTERED_GST_DEALER,a.location_Code
       FROM CNM01106 A (NOLOCK)
	   JOIN CND01106 CND (NOLOCK) ON A.CN_ID=CND.CN_ID 
       JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.location_Code 
	   JOIN GST_STATE_MST LS (NOLOCK)  ON LS.GST_STATE_CODE  =B.GST_STATE_CODE
	   LEFT OUTER JOIN LMP01106 LMP (NOLOCK)  ON LMP.AC_CODE =A.AC_CODE
       LEFT JOIN GST_STATE_MST LMPS (NOLOCK)  ON LMPS.GST_STATE_CODE  =LMP.AC_GST_STATE_CODE
       --JOIN 
	  -- (
	  --   SELECT CN_ID ,CND.INV_NO AS BILL_NO,CND.INV_DT AS BILL_DT,
			--	   ISNULL(CND.GST_PERCENTAGE,0) AS RATE  ,
			--	   SUM(XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST,
			--	   SUM(XN_VALUE_WITH_GST) AS XN_VALUE_WITH_GST
		 --FROM CND01106   CND (NOLOCK) 
		 --GROUP BY CN_ID ,CND.INV_NO,CND.INV_DT,CND.GST_PERCENTAGE
	  -- )CND ON A.CN_ID =CND.CN_ID 
	   LEFT OUTER JOIN LOCATION RML (NOLOCK) ON RML.DEPT_ID =A.PARTY_DEPT_ID 
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      --AND A.CN_TYPE=1
	  AND A.RECEIPT_DT BETWEEN @DFMDATE AND @DTODATE
	  AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
	  AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
	  -- AND ISNULL(CND.GST_PERCENTAGE,0)>0
	 -- AND  ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'') =''
      AND ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE ISNULL(RML.LOC_GST_NO,'') END,'')<> B.LOC_GST_NO
      AND (@CDEPT_ID='' OR A.location_Code =@CDEPT_ID)
	 -- AND A.TOTAL_AMOUNT<250000
      
    
	--END OF B2CS

       INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code)
       SELECT CAST(CASE WHEN B.ARCT =2 THEN  'ADVANCE' 
                     WHEN B.ARCT =3 THEN  'GV VOUCHER' 
                     WHEN B.ARCT =4 THEN  'OTHER CHARGES'
                     WHEN B.ARCT =5 THEN  'DISC CARD'  
            ELSE '' END AS VARCHAR(100)) AS XN_TYPE,
             B.ADV_REC_ID AS MEMO_ID,
             B.HSN_CODE AS HSN_CODE,
             CAST(1  AS NUMERIC(10,2)) AS QTY,
             B.NET_AMOUNT ,
             ISNULL(B.TAXABLE_VALUE,0)  AS TAXABLE_VALUE,
             B.IGST_AMOUNT AS IGST_AMOUNT,
             B.CGST_AMOUNT AS CGST_AMOUNT,
             B.SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100))  AS PRODUCT_CODE,
             B.PARTY_STATE_CODE ,
             CASE WHEN ISNULL(cus_gst_no,'')<>'' THEN 1 ELSE 0 END AS  REGISTERED_GST_DEALER,
             b.location_Code
      FROM ARC01106   B (NOLOCK) 
      JOIN LOCATION C (NOLOCK) ON C.DEPT_ID =B.location_Code 
      JOIN GST_STATE_MST D (NOLOCK)  ON C.GST_STATE_CODE =D.GST_STATE_CODE 
      JOIN CUSTDYM CUST (NOLOCK) ON CUST .customer_code =b.CUSTOMER_CODE
      LEFT JOIN
      ( 
        SELECT PX.ADJ_MEMO_ID
        FROM ARC01106   B (NOLOCK) 
	    JOIN PAYMODE_XN_DET PX (NOLOCK) ON PX.ADJ_MEMO_ID=B.ADV_REC_ID
	    JOIN CMM01106 CM (NOLOCK) ON CM.CM_ID=PX.MEMO_ID
	    JOIN LOCATION C (NOLOCK) ON C.DEPT_ID =CM.location_Code 
	    WHERE B.CANCELLED =0 AND CM.CANCELLED=0 AND PAYMODE_CODE='0000002'
        AND ARC_TYPE =1 AND ARCT=2
        AND CM.CM_DT   BETWEEN @DFMDATE AND @DTODATE
        AND (@CGSTN_NO='' OR C.LOC_GST_NO=@CGSTN_NO)
        AND (@CLOC_TYPE=0 OR ISNULL(C.LOC_TYPE,0) =@CLOC_TYPE)
	    GROUP BY PX.ADJ_MEMO_ID
      ) ADJ ON B.ADV_REC_ID =ADJ.ADJ_MEMO_ID 
      WHERE B.CANCELLED =0
      AND ARC_TYPE =1 
      AND ARCT<>1
      AND B.ADV_REC_DT   BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR C.LOC_GST_NO=@CGSTN_NO)
      AND ADJ.ADJ_MEMO_ID IS NULL
      AND (ISNULL(B.CGST_AMOUNT ,0)+ ISNULL(B.SGST_AMOUNT ,0)+ ISNULL(B.IGST_AMOUNT ,0))<>0
      AND (@CLOC_TYPE=0 OR ISNULL(C.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR B.location_Code =@CDEPT_ID)
     
     
      INSERT INTO #TMPHSNDETAILS(XN_TYPE,MEMO_ID,HSN_CODE,QTY,NET_AMOUNT,TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,CESS_AMOUNT,PRODUCT_CODE,PARTY_STATE_CODE,REGISTERED_GST_DEALER,location_Code)
	 SELECT   'ADVANCE ADJUSTED' AS XN_TYPE ,
             B.ADV_REC_ID AS MEMO_ID,
             B.HSN_CODE AS HSN_CODE,
             CAST(1  AS NUMERIC(10,2)) AS QTY,
            (-1)* B.NET_AMOUNT ,
             (-1)*ISNULL(B.TAXABLE_VALUE,0)  AS TAXABLE_VALUE,
             (-1)*B.IGST_AMOUNT AS IGST_AMOUNT,
            (-1)* B.CGST_AMOUNT AS CGST_AMOUNT,
           (-1)*  B.SGST_AMOUNT AS SGST_AMOUNT,
             CAST(0 AS NUMERIC(10,2)) AS CESS_AMOUNT,
             CAST('' AS VARCHAR(100))  AS PRODUCT_CODE,
             B.PARTY_STATE_CODE ,
             CASE WHEN ISNULL(cus_gst_no,'')<>'' THEN 1 ELSE 0 END AS  REGISTERED_GST_DEALER,
             b.location_Code
	  FROM ARC01106   B (NOLOCK) 
	  JOIN PAYMODE_XN_DET PX (NOLOCK) ON PX.ADJ_MEMO_ID=B.ADV_REC_ID
	  JOIN CMM01106 CM (NOLOCK) ON CM.CM_ID=PX.MEMO_ID
	  JOIN LOCATION C (NOLOCK) ON C.DEPT_ID =CM.location_Code 
      JOIN CUSTDYM CUST (NOLOCK) ON CUST.CUSTOMER_CODE =B.CUSTOMER_CODE 
      LEFT JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE=B.AC_CODE 
      LEFT JOIN GST_STATE_MST LS (NOLOCK) ON LS.GST_STATE_CODE =LMP.AC_GST_STATE_CODE 
      JOIN GST_STATE_MST CS (NOLOCK) ON CS.GST_STATE_CODE =CM.PARTY_STATE_CODE 
      LEFT JOIN
      (
        SELECT DISTINCT  B.ADV_REC_ID 
        FROM ARC01106   B (NOLOCK) 
        JOIN LOCATION C (NOLOCK) ON C.DEPT_ID =B.location_Code 
        WHERE B.CANCELLED =0
        AND ARC_TYPE =1 AND ARCT<>1
        AND B.ADV_REC_DT   BETWEEN @DFMDATE AND @DTODATE
        AND (@CGSTN_NO='' OR C.LOC_GST_NO=@CGSTN_NO)
        AND (@CLOC_TYPE=0 OR ISNULL(C.LOC_TYPE,0) =@CLOC_TYPE)
      ) ADJ ON ADJ.ADV_REC_ID =B.ADV_REC_ID 
      WHERE B.CANCELLED =0 AND CM.CANCELLED=0 AND PAYMODE_CODE='0000002'
      AND ARC_TYPE =1 AND ARCT=2
      AND CM.CM_DT   BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR C.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(C.LOC_TYPE,0) =@CLOC_TYPE)
       AND ADJ.ADV_REC_ID IS NULL
      AND (ISNULL(B.CGST_AMOUNT ,0)+ ISNULL(B.SGST_AMOUNT ,0)+ ISNULL(B.IGST_AMOUNT ,0))<>0
      AND (@CDEPT_ID='' OR B.location_Code =@CDEPT_ID)

      
       IF OBJECT_ID('TEMPDB..#TMPHSNSUMMARY','U') IS NOT NULL
           DROP TABLE #TMPHSNSUMMARY
           
           SELECT A.XN_TYPE,A.MEMO_ID,
                  ISNULL(UOM.UOM_NAME,'OTH-OTHERS') AS UOM_NAME ,
                  A.HSN_CODE,
                  ISNULL(HM.DESCRIPTIONS,'')  AS DESCR,
                  A.QTY,A.NET_AMOUNT,A.TAXABLE_VALUE,
                  A.IGST_AMOUNT,A.CGST_AMOUNT,A.SGST_AMOUNT,A.CESS_AMOUNT,A.PRODUCT_CODE,
                  SR=ROW_NUMBER() OVER (PARTITION BY XN_TYPE,MEMO_ID,A.HSN_CODE,ISNULL(UOM.UOM_NAME,'') ORDER BY MEMO_ID),
                  A.PARTY_STATE_CODE,
                  REGISTERED_GST_DEALER,a.location_Code 
           INTO #TMPHSNSUMMARY
           FROM #TMPHSNDETAILS A
           JOIN HSN_MST HM ON HM.HSN_CODE =A.HSN_CODE 
           LEFT JOIN SKU (NOLOCK) ON SKU .PRODUCT_CODE =A.PRODUCT_CODE 
           LEFT JOIN ARTICLE ART (NOLOCK) ON ART.ARTICLE_CODE =SKU .ARTICLE_CODE 
           LEFT JOIN UOM (NOLOCK) ON UOM.UOM_CODE =ART.UOM_CODE 
         
          -- DROP TABLE TMPHSNSUMMARY
          --SELECT * INTO TMPHSNSUMMARY FROM #TMPHSNSUMMARY
          
          IF ISNULL(@NGSTR3B,0)=1
          BEGIN
              
              SELECT * 
              FROM #TMPHSNSUMMARY
              RETURN
          
          END
    

END

