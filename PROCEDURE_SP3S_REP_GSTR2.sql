
create PROCEDURE SP3S_REP_GSTR2
(
  @DFMDATE DATETIME='2022-12-01',
  @DTODATE DATETIME='2022-12-31',
  @CGSTN_NO VARCHAR(100)='',
  @CLOC_TYPE INT=0,--0 FOR ALL 1 FOR ONLY COMPANY OWNED,
  @CDEPT_ID VARCHAR(5)=''
  
)
AS
BEGIN
     

	 
	 
	  DECLARE @PICK_CN_NO_GST VARCHAR(10)
     SELECT @PICK_CN_NO_GST=value  FROM CONFIG  WHERE CONFIG_OPTION='PICK_CN_NO_GST'
      

     IF @DFMDATE<='2017-06-30'
     RETURN
     --1 PURCHASE
     DECLARE @TBLB2B TABLE (MEMO_ID VARCHAR(100),SR INT,RTYPE VARCHAR(10),XN_TYPE VARCHAR(100),GSTIN_UIN_RECIPIENT VARCHAR(100),INVOICE_NO VARCHAR(50),INVOICE_DT VARCHAR(10),
                            INVOICE_VALUE NUMERIC(12,2),PLACE_OF_SUPPLY VARCHAR(100),REVERSE_CHARGE CHAR(1),INVOICE_TYPE VARCHAR(10),
                            RATE NUMERIC(8,2),TAXABLE_VALUE NUMERIC(12,2),IGST_AMOUNT NUMERIC(12,2),CGST_AMOUNT NUMERIC(12,2),SGST_AMOUNT NUMERIC(12,2)
                            ,LOC_GST_NO VARCHAR(100),PARTY_REGISTERED INT,AC_NAME VARCHAR(100),SUPPLY_TYPE VARCHAR(100),xn_item_type int,rcm_applicable int,Cess_Amount numeric(14,2))
  
     --**** STATR B2B----(REGISTER PURCHASE)
     INSERT INTO @TBLB2B(MEMO_ID,SR ,RTYPE,XN_TYPE ,GSTIN_UIN_RECIPIENT ,INVOICE_NO ,INVOICE_DT ,INVOICE_VALUE ,PLACE_OF_SUPPLY ,
                  REVERSE_CHARGE,INVOICE_TYPE  ,RATE ,TAXABLE_VALUE ,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT,LOC_GST_NO,
                  PARTY_REGISTERED,AC_NAME ,SUPPLY_TYPE,xn_item_type,rcm_applicable ,Cess_Amount )
      SELECT A.MRR_ID,SR=CAST(2 AS INT),
            CAST('B2B' AS VARCHAR(100)) AS RTYPE,
            CAST(CASE WHEN A.INV_MODE =1 THEN 'PARTY PURCHASE' ELSE 'GROUP PURCHASE' END AS VARCHAR(100)) AS XN_TYPE,
            CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END  AS GSTIN_UIN_RECIPIENT,
            CAST(A.BILL_NO  AS VARCHAR(100)) AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.BILL_DT,6),' ','-')  AS INVOICE_DATE,
            A.TOTAL_AMOUNT   AS INVOICE_VALUE,
            C.GST_STATE_CODE+'-'+C.GST_STATE_NAME  AS PLACE_OF_SUPPLY,
            CAST('N' AS CHAR(1)) AS REVERSE_CHARGE,
            CAST('Regular' AS VARCHAR(10)) AS INVOICE_TYPE,
            A.OTHER_CHARGES_GST_PERCENTAGE AS RATE,
            A.OTHER_CHARGES_TAXABLE_VALUE  AS TAXABLE_VALUE,
            A.OTHER_CHARGES_IGST_AMOUNT  AS IGST_AMOUNT,
            A.OTHER_CHARGES_CGST_AMOUNT  AS CGST_AMOUNT,
            A.OTHER_CHARGES_SGST_AMOUNT  AS SGST_AMOUNT,
            ISNULL(B.LOC_GST_NO ,'') AS LOC_GST_NO,
            B.REGISTERED_GST ,
            LM.AC_NAME AS AC_NAME,
            CASE WHEN A.PARTY_STATE_CODE <>CASE WHEN INV_MODE =1 THEN B.GST_STATE_CODE ELSE  TS.GST_STATE_CODE END THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE,
            a.xn_item_type,
            a.rcm_applicable ,
			0 as Cess_Amount
      FROM PIM01106  A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(PUR_FOR_DEPT_ID,'')<>'' THEN  PUR_FOR_DEPT_ID ELSE  a.location_Code  END 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.challan_source_location_code  
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      LEFT JOIN GST_STATE_MST C (NOLOCK)  ON A.PARTY_STATE_CODE  =C.GST_STATE_CODE
      LEFT JOIN GST_STATE_MST TS (NOLOCK)  ON TL.GST_STATE_CODE  =TS.GST_STATE_CODE
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND A.BILL_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>''
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
      AND ISNULL(A.OTHER_CHARGES_GST_PERCENTAGE,0)>0
      AND (@CDEPT_ID='' OR A.challan_source_location_code=@CDEPT_ID) and a.XN_ITEM_TYPE <>5
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
      union all
      SELECT A.MRR_ID,SR=CAST(2 AS INT),
            CAST('B2B' AS VARCHAR(100)) AS RTYPE,
            CAST(CASE WHEN A.INV_MODE =1 THEN 'PARTY PURCHASE' ELSE 'GROUP PURCHASE' END AS VARCHAR(100)) AS XN_TYPE,
            CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END  AS GSTIN_UIN_RECIPIENT,
            CAST(A.bill_no   AS VARCHAR(100)) AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.BILL_DT,6),' ','-')  AS INVOICE_DATE,
            A.TOTAL_AMOUNT   AS INVOICE_VALUE,
            C.GST_STATE_CODE+'-'+C.GST_STATE_NAME  AS PLACE_OF_SUPPLY,
            CAST('N' AS CHAR(1)) AS REVERSE_CHARGE,
            CAST('Regular' AS VARCHAR(10)) AS INVOICE_TYPE,
            A.FREIGHT_GST_PERCENTAGE AS RATE,
            A.FREIGHT_TAXABLE_VALUE  AS TAXABLE_VALUE,
            A.FREIGHT_IGST_AMOUNT  AS IGST_AMOUNT,
            A.FREIGHT_CGST_AMOUNT  AS CGST_AMOUNT,
            A.FREIGHT_SGST_AMOUNT  AS SGST_AMOUNT,
            ISNULL(B.LOC_GST_NO ,'') AS LOC_GST_NO,
            B.registered_gst ,
            LM.AC_NAME AS AC_NAME,
            CASE WHEN A.PARTY_STATE_CODE <>CASE WHEN INV_MODE =1 THEN B.GST_STATE_CODE ELSE  TS.GST_STATE_CODE END THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE,
            a.xn_item_type,
            a.rcm_applicable ,
			0 as Cess_Amount
      FROM PIM01106  A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(PUR_FOR_DEPT_ID,'')<>'' THEN  PUR_FOR_DEPT_ID ELSE  a.location_Code END 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.challan_source_location_code  
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      LEFT JOIN GST_STATE_MST C (NOLOCK)  ON A.PARTY_STATE_CODE  =C.GST_STATE_CODE
      LEFT JOIN GST_STATE_MST TS (NOLOCK)  ON TL.GST_STATE_CODE  =TS.GST_STATE_CODE
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND A.BILL_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>''
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
      AND ISNULL(A.FREIGHT_GST_PERCENTAGE,0)>0
      AND (@CDEPT_ID='' OR A.challan_source_location_code =@CDEPT_ID) and a.XN_ITEM_TYPE <>5
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
      UNION ALL
      SELECT A.MRR_ID,SR=CAST(2 AS INT),
            CAST('B2B' AS VARCHAR(100)) AS RTYPE,
            CAST(CASE WHEN A.INV_MODE =1 THEN 'PARTY PURCHASE' ELSE 'GROUP PURCHASE' END AS VARCHAR(100)) AS XN_TYPE,
            CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END  AS GSTIN_UIN_RECIPIENT,
            CAST(A.bill_no   AS VARCHAR(100)) AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.BILL_DT,6),' ','-')  AS INVOICE_DATE,
            A.TOTAL_AMOUNT   AS INVOICE_VALUE,
            C.GST_STATE_CODE+'-'+C.GST_STATE_NAME  AS PLACE_OF_SUPPLY,
            CAST('N' AS CHAR(1)) AS REVERSE_CHARGE,
            CAST('Regular' AS VARCHAR(10)) AS INVOICE_TYPE,
            PID.RATE AS RATE,
            PID.XN_VALUE_WITHOUT_GST  AS TAXABLE_VALUE,
            PID.IGST_AMOUNT AS IGST_AMOUNT,
            PID.Cgst_amount  AS CGST_AMOUNT,
            PID.Sgst_amount   AS SGST_AMOUNT,
            ISNULL(B.LOC_GST_NO ,'') AS LOC_GST_NO,
            B.registered_gst ,
            LM.AC_NAME AS AC_NAME,
            CASE WHEN A.PARTY_STATE_CODE <>CASE WHEN INV_MODE =1 THEN B.GST_STATE_CODE ELSE  TS.GST_STATE_CODE END THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE,
            a.xn_item_type,
            a.rcm_applicable ,
			PID.Gst_cess_amount as Cess_Amount
      FROM PIM01106  A (NOLOCK)
      JOIN 
( 
        SELECT mrr_id  ,PID.GST_PERCENTAGE AS RATE  ,
               SUM(XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST,
               SUM(igst_amount ) AS igst_amount,
               SUM(Cgst_amount ) AS Cgst_amount,
               SUM(Sgst_amount ) AS Sgst_amount,
			   SUM(XN_VALUE_WITH_GST) AS XN_VALUE_WITH_GST,
			   SUM(isnull(Gst_cess_amount,0)) as Gst_cess_amount
        FROM pid01106  PID (NOLOCK) 
        GROUP BY mrr_id,PID.GST_PERCENTAGE 
      )PID ON A.MRR_ID =PID.MRR_ID 
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(PUR_FOR_DEPT_ID,'')<>'' THEN  PUR_FOR_DEPT_ID ELSE  A.location_Code  END 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =a.challan_source_location_code 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      LEFT JOIN GST_STATE_MST C (NOLOCK)  ON A.PARTY_STATE_CODE  =C.GST_STATE_CODE
      LEFT JOIN GST_STATE_MST TS (NOLOCK)  ON TL.GST_STATE_CODE  =TS.GST_STATE_CODE
	  JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID') LOC ON 1=1
      JOIN (SELECT TOP 1 VALUE FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID') HO ON 1=1 
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND A.BILL_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>''
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
      AND (@CDEPT_ID='' OR A.challan_source_location_code =@CDEPT_ID) and a.XN_ITEM_TYPE <>5
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
      and ISNULL(A.RCM_APPLICABLE,0)=0 AND (a.inv_mode IN (0,1) OR loc.value<>ho.value)
	    UNION ALL
      SELECT A.MRR_ID,SR=CAST(2 AS INT),
            CAST('B2B' AS VARCHAR(100)) AS RTYPE,
            CAST(CASE WHEN A.INV_MODE =1 THEN 'PARTY PURCHASE' ELSE 'GROUP PURCHASE' END AS VARCHAR(100)) AS XN_TYPE,
            CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END  AS GSTIN_UIN_RECIPIENT,
            CAST(A.bill_no   AS VARCHAR(100)) AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.BILL_DT,6),' ','-')  AS INVOICE_DATE,
            A.TOTAL_AMOUNT   AS INVOICE_VALUE,
            C.GST_STATE_CODE+'-'+C.GST_STATE_NAME  AS PLACE_OF_SUPPLY,
            CAST('N' AS CHAR(1)) AS REVERSE_CHARGE,
            CAST('Regular' AS VARCHAR(10)) AS INVOICE_TYPE,
            PID.RATE AS RATE,
            PID.XN_VALUE_WITHOUT_GST  AS TAXABLE_VALUE,
            PID.IGST_AMOUNT AS IGST_AMOUNT,
            PID.Cgst_amount  AS CGST_AMOUNT,
            PID.Sgst_amount   AS SGST_AMOUNT,
            ISNULL(B.LOC_GST_NO ,'') AS LOC_GST_NO,
            B.registered_gst ,
            LM.AC_NAME AS AC_NAME,
            CASE WHEN A.PARTY_STATE_CODE <>CASE WHEN INV_MODE =1 THEN B.GST_STATE_CODE ELSE  TS.GST_STATE_CODE END THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE,
            a.xn_item_type,
            a.rcm_applicable ,
			PID.Gst_cess_amount as Cess_Amount
      FROM PIM01106  A (NOLOCK)
      JOIN 
( 
        SELECT ind.inv_id  ,ind.GST_PERCENTAGE AS RATE  ,
               SUM(XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST,
               SUM(igst_amount ) AS igst_amount,
               SUM(Cgst_amount ) AS Cgst_amount,
               SUM(Sgst_amount ) AS Sgst_amount,
			   SUM(XN_VALUE_WITH_GST) AS XN_VALUE_WITH_GST,
			   SUM(isnull(Gst_cess_amount,0)) as Gst_cess_amount
        FROM IND01106  ind (NOLOCK) 
		join inm01106 inm (nolock) on ind.inv_id =inm.inv_id 
		where inm.CANCELLED =0
        GROUP BY ind.inv_id,ind.GST_PERCENTAGE 
      )PID ON A.inv_id =PID.inv_id  
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(PUR_FOR_DEPT_ID,'')<>'' THEN  PUR_FOR_DEPT_ID ELSE  A.location_Code  END 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.challan_source_location_code 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      LEFT JOIN GST_STATE_MST C (NOLOCK)  ON A.PARTY_STATE_CODE  =C.GST_STATE_CODE
      LEFT JOIN GST_STATE_MST TS (NOLOCK)  ON TL.GST_STATE_CODE  =TS.GST_STATE_CODE
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND A.BILL_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE) 
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>''
      AND ISNULL(CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END,'')<>ISNULL(B.LOC_GST_NO ,'')
      AND (@CDEPT_ID='' OR A.challan_source_location_code =@CDEPT_ID) and a.XN_ITEM_TYPE <>5
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
      and ISNULL(A.RCM_APPLICABLE,0)=0 AND a.inv_mode=2

      UNION ALL
      SELECT A.MRR_ID,SR=CAST(2 AS INT),
            CAST('B2B' AS VARCHAR(100)) AS RTYPE,
            CAST(CASE WHEN A.INV_MODE =1 THEN 'PARTY PURCHASE' ELSE 'GROUP PURCHASE' END AS VARCHAR(100)) AS XN_TYPE,
            CASE WHEN A.INV_MODE =1 THEN  LMP.AC_GST_NO ELSE TL.LOC_GST_NO  END  AS GSTIN_UIN_RECIPIENT,
            CAST(A.rcm_memo_no    AS VARCHAR(100)) AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.BILL_DT,6),' ','-')  AS INVOICE_DATE,
            A.TOTAL_AMOUNT   AS INVOICE_VALUE,
            C.GST_STATE_CODE+'-'+C.GST_STATE_NAME  AS PLACE_OF_SUPPLY,
            CAST('N' AS CHAR(1)) AS REVERSE_CHARGE,
            CAST('Regular' AS VARCHAR(10)) AS INVOICE_TYPE,
            PID.RATE AS RATE,
            PID.XN_VALUE_WITHOUT_GST  AS TAXABLE_VALUE,
            RCM_IGST_AMOUNT AS IGST_AMOUNT,
            RCM_Cgst_amount  AS CGST_AMOUNT,
            RCM_Sgst_amount   AS SGST_AMOUNT,
            ISNULL(B.LOC_GST_NO ,'') AS LOC_GST_NO,
            B.registered_gst ,
            LM.AC_NAME AS AC_NAME,
            CASE WHEN A.PARTY_STATE_CODE <>CASE WHEN INV_MODE =1 THEN B.GST_STATE_CODE ELSE  TS.GST_STATE_CODE END THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE,
            a.xn_item_type,
            a.rcm_applicable ,
			0 as Cess_Amount
      FROM PIM01106  A (NOLOCK)
      JOIN 
      ( 
        SELECT mrr_id  ,PID.rcm_gst_percentage AS RATE  ,
               SUM(rcm_taxable_value) AS XN_VALUE_WITHOUT_GST,
               SUM(rcm_igst_amount ) AS rcm_igst_amount,
               SUM(rcM_Cgst_amount ) AS rcM_Cgst_amount,
               SUM(rcm_Sgst_amount ) AS rcm_Sgst_amount,
			   SUM(XN_VALUE_WITH_GST) AS XN_VALUE_WITH_GST
        FROM pid01106  PID (NOLOCK) 
        GROUP BY mrr_id,PID.rcm_gst_percentage 
      )PID ON A.MRR_ID =PID.MRR_ID 
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(PUR_FOR_DEPT_ID,'')<>'' THEN  PUR_FOR_DEPT_ID ELSE  A.location_Code  END 
      LEFT JOIN LOCATION TL (NOLOCK) ON TL.DEPT_ID =A.challan_source_location_code 
      LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
      LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
      LEFT JOIN GST_STATE_MST C (NOLOCK)  ON A.PARTY_STATE_CODE  =C.GST_STATE_CODE
      LEFT JOIN GST_STATE_MST TS (NOLOCK)  ON TL.GST_STATE_CODE  =TS.GST_STATE_CODE
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND A.BILL_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR A.challan_source_location_code =@CDEPT_ID) and a.XN_ITEM_TYPE <>5
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
      and ISNULL(A.RCM_APPLICABLE,0)=1

	  --as per ved ji discussion  with Roopkala
   --   union all
   --   SELECT A.receipt_id ,SR=CAST(2 AS INT),
   --         CAST('B2B' AS VARCHAR(100)) AS RTYPE,
   --         'JWR' AS XN_TYPE,
   --         LMP.AC_GST_NO  AS GSTIN_UIN_RECIPIENT,
   --         CAST(A.challan_no    AS VARCHAR(100)) AS INVOICE_NO,
   --         REPLACE(CONVERT(VARCHAR(9),A.challan_dt ,6),' ','-')  AS INVOICE_DATE,
   --         a.net_amount   AS INVOICE_VALUE,
   --         C.GST_STATE_CODE+'-'+C.GST_STATE_NAME  AS PLACE_OF_SUPPLY,
   --         CAST('N' AS CHAR(1)) AS REVERSE_CHARGE,
   --         CAST('Regular' AS VARCHAR(10)) AS INVOICE_TYPE,
   --         JWR.RATE AS RATE,
   --         JWR.XN_VALUE_WITHOUT_GST  AS TAXABLE_VALUE,
   --         JWR.igst_amount  AS IGST_AMOUNT,
   --         JWR.Cgst_amount  AS CGST_AMOUNT,
   --         JWR.Sgst_amount  AS SGST_AMOUNT,
   --         ISNULL(B.LOC_GST_NO ,'') AS LOC_GST_NO,
   --         B.registered_gst ,
   --         LM.AC_NAME AS AC_NAME,
   --         CASE WHEN A.PARTY_STATE_CODE <>C.GST_STATE_CODE THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE,
   --         4 AS XN_ITEM_TYPE,
   --         0 as rcm_applicable ,
			--JWR.Gst_cess_amount as Cess_Amount
   --   FROM jobwork_receipt_mst   A (NOLOCK)
   --   JOIN 
   --   ( SELECT receipt_id   ,PID.GST_PERCENTAGE AS RATE  ,
   --            SUM(XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST,
			--   SUM(XN_VALUE_WITH_GST) AS XN_VALUE_WITH_GST,
   --            SUM(igst_amount ) AS igst_amount,
   --            SUM(Cgst_amount ) AS Cgst_amount,
   --            SUM(Sgst_amount ) AS Sgst_amount,
			--   SUM(isnull(Gst_cess_amount,0)) as Gst_cess_amount
   --     FROM jobwork_receipt_det   PID (NOLOCK) 
   --     WHERE   ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)<>0
   --     GROUP BY receipt_id,PID.GST_PERCENTAGE 
   --   )JWR ON A.receipt_id =JWR.receipt_id 
   --   JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =LEFT (A.receipt_id,2)
   --   JOIN prd_agency_mst AM (NOLOCK) ON AM.agency_code =A.agency_code 
   --   LEFT JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =AM.AC_CODE 
   --   LEFT OUTER JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
   --   LEFT JOIN GST_STATE_MST C (NOLOCK)  ON A.PARTY_STATE_CODE  =C.GST_STATE_CODE
   --   WHERE A.CANCELLED =0 
	  --AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
   --   AND A.challan_dt   BETWEEN @DFMDATE AND @DTODATE
   --   AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
   --   AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
   --   AND (@CDEPT_ID='' OR LEFT(A.receipt_id ,2)=@CDEPT_ID)

	    union all
      SELECT A.memo_id  ,SR=CAST(3 AS INT),
            CAST('B2B' AS VARCHAR(100)) AS RTYPE,
            'supp' AS XN_TYPE,
            LMP.AC_GST_NO  AS GSTIN_UIN_RECIPIENT,
            CAST(A.bill_no     AS VARCHAR(100)) AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.bill_dt  ,6),' ','-')  AS INVOICE_DATE,
            A.total_amount     AS INVOICE_VALUE,
            C.GST_STATE_CODE+'-'+C.GST_STATE_NAME  AS PLACE_OF_SUPPLY,
            CAST('N' AS CHAR(1)) AS REVERSE_CHARGE,
            CAST('Regular' AS VARCHAR(10)) AS INVOICE_TYPE,
            det.gst_percentage  AS RATE,
            det.XN_VALUE_WITHOUT_GST  AS TAXABLE_VALUE,
            det.igst_amount  AS IGST_AMOUNT,
            det.Cgst_amount  AS CGST_AMOUNT,
            det.Sgst_amount  AS SGST_AMOUNT,
            ISNULL(B.LOC_GST_NO ,'') AS LOC_GST_NO,
            B.registered_gst ,
            LM.AC_NAME AS AC_NAME,
            CASE WHEN A.PARTY_STATE_CODE <>C.GST_STATE_CODE THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE,
            4 AS XN_ITEM_TYPE,
            0 as rcm_applicable,
			0 as Cess_Amount
            FROM SUPPLY_EXPENSE_XN_MST  A (NOLOCK)
			 JOIN SUPPLY_EXPENSE_XN_DET DET (NOLOCK) ON A.MEMO_ID  =DET.MEMO_ID  
			 JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =A.DEPT_ID
			 JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE
			 JOIN GST_STATE_MST PS (NOLOCK)  ON PS.GST_STATE_CODE =A.PARTY_STATE_CODE 
			 JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE =A.AC_CODE 
			 JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE =LM.AC_CODE 
			 WHERE A.CANCELLED =0 
		 AND A.bill_dt   BETWEEN @DFMDATE AND @DTODATE
		 AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
		 AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
		 AND (@CDEPT_ID='' OR A.location_Code=@CDEPT_ID)


      
     --1-inv
      
      SELECT RTYPE,GSTIN_UIN_RECIPIENT AS [GSTIN of Supplier],
	          AC_NAME as [Trade/Legal name],
             INVOICE_NO AS [Invoice Number],
             INVOICE_DT AS [Invoice date],
             INVOICE_VALUE AS [Invoice Value] ,
             PLACE_OF_SUPPLY AS [PLACE OF SUPPLY],
             REVERSE_CHARGE AS [REVERSE CHARGE],
             INVOICE_TYPE AS [INVOICE TYPE] , 
             RATE AS RATE,
             SUM(TAXABLE_VALUE) AS [TAXABLE VALUE] ,
             SUM(IGST_AMOUNT) AS [Integrated Tax Paid],
             SUM(CGST_AMOUNT) AS [Central Tax Paid],
             SUM(SGST_AMOUNT) AS [State/UT Tax Paid],
             sum(ISNULL(Cess_Amount,0)) AS [Cess Paid],
             case when a.xn_item_type  in(1,2) then 'Inputs'
                  when a.xn_item_type=3 then 'Capital goods'
                  when a.xn_item_type=4 then 'Input services'
                  ELSE 'Ineligible' END AS [Eligibility For ITC],
             --CAST('Ineligible' AS VARCHAR(100)) AS [Eligibility For ITC],
             SUM(IGST_AMOUNT) AS [Availed ITC Integrated Tax],
             SUM(CGST_AMOUNT) AS [Availed ITC Central Tax],
             SUM(SGST_AMOUNT) AS [Availed ITC State/UT Tax],
             CAST(sum(ISNULL(Cess_Amount,0)) AS NUMERIC(10,2)) AS [Availed ITC Cess]
			

      FROM @TBLB2B A
      WHERE ISNULL(GSTIN_UIN_RECIPIENT,'')<>''
      AND ISNULL(GSTIN_UIN_RECIPIENT,'')<>ISNULL(LOC_GST_NO,'') 
      and isnull(a.rcm_applicable ,0)=0
      GROUP BY RTYPE,GSTIN_UIN_RECIPIENT ,
      INVOICE_NO,INVOICE_DT ,AC_NAME,
      INVOICE_VALUE ,PLACE_OF_SUPPLY ,
      REVERSE_CHARGE ,INVOICE_TYPE  ,RATE ,
      case when a.xn_item_type  in(1,2) then 'Inputs'
                  when a.xn_item_type=3 then 'Capital goods'
                  when a.xn_item_type=4 then 'Input services'
                  ELSE 'Ineligible' END
      ORDER BY INVOICE_DT,INVOICE_NO
      
      
      select 'B2BUR' AS RTYPE,
             AC_NAME AS [Supplier Name],
             INVOICE_NO AS [Invoice Number],
             INVOICE_DT AS [Invoice date],
             INVOICE_VALUE AS [Invoice Value] ,
             PLACE_OF_SUPPLY AS [PLACE OF SUPPLY],
             SUPPLY_TYPE AS [Supply Type],
             RATE AS Rate,
             SUM(TAXABLE_VALUE) AS [TAXABLE VALUE] ,
             SUM(IGST_AMOUNT) AS [Integrated Tax Paid],
             SUM(CGST_AMOUNT) AS [Central Tax Paid],
             SUM(SGST_AMOUNT) AS [State/UT Tax Paid],
             sum(ISNULL(Cess_Amount,0)) AS [Cess Paid],
            case when a.xn_item_type  in(1,2) then 'Inputs'
                 when a.xn_item_type=3 then 'Capital goods'
                 when a.xn_item_type=4 then 'Input services'
                 ELSE 'Ineligible' END AS [Eligibility For ITC],
             
             SUM(IGST_AMOUNT) AS [Availed ITC Integrated Tax],
             SUM(CGST_AMOUNT) AS [Availed ITC Central Tax],
             SUM(SGST_AMOUNT) AS [Availed ITC State/UT Tax],
             CAST(sum(ISNULL(Cess_Amount,0)) AS NUMERIC(10,2)) AS [Availed ITC Cess]
             			
      FROM @TBLB2B A
      WHERE (ISNULL(GSTIN_UIN_RECIPIENT,'')=''  or isnull(a.rcm_applicable ,0)=1)
      GROUP BY AC_NAME ,INVOICE_NO ,INVOICE_DT ,
      INVOICE_VALUE  ,PLACE_OF_SUPPLY ,SUPPLY_TYPE ,RATE,
       case when a.xn_item_type  in(1,2) then 'Inputs'
                 when a.xn_item_type=3 then 'Capital goods'
                 when a.xn_item_type=4 then 'Input services'
                 ELSE 'Ineligible' END 
                 order by INVOICE_NO

      
      
      --START FOR CDNR---
      
     
    
    
      
       DECLARE  @TBLCDNR TABLE(MEMO_ID VARCHAR(100),Ac_name varchar(100),SR INT,RTYPE VARCHAR(10),XN_TYPE VARCHAR(100),GSTIN_UIN_RECIPIENT VARCHAR(100),INVOICE_NO VARCHAR(100),INVOICE_DT VARCHAR(10),
                            REF_VOUCHER_NO VARCHAR(100),REF_VOUCHER_DT VARCHAR(10),DOC_TYPE CHAR(1),REASON VARCHAR(1000),PLACE_OF_SUPPLY VARCHAR(100),
                            REF_VOUCHER_VALUE NUMERIC(12,2),RATE NUMERIC(8,2),TAXABLE_VALUE NUMERIC(12,2),CESS_AMOUNT NUMERIC(8,2),
                            PRE_GST CHAR(1),MEMO_DT DATETIME,IGST_AMOUNT NUMERIC(12,2),CGST_AMOUNT NUMERIC(12,2),SGST_AMOUNT NUMERIC(12,2)
                            ,LOC_GST_NO VARCHAR(100),PARTY_REGISTERED INT,SUPPLY_TYPE VARCHAR(100))
     
      
	    INSERT INTO @TBLCDNR (MEMO_ID,Ac_name,SR ,RTYPE ,XN_TYPE,GSTIN_UIN_RECIPIENT,INVOICE_NO ,INVOICE_DT ,REF_VOUCHER_NO ,REF_VOUCHER_DT ,
                           DOC_TYPE ,REASON ,PLACE_OF_SUPPLY ,REF_VOUCHER_VALUE ,RATE ,TAXABLE_VALUE ,CESS_AMOUNT ,PRE_GST,MEMO_DT,
                           IGST_AMOUNT ,CGST_AMOUNT ,SGST_AMOUNT ,LOC_GST_NO,PARTY_REGISTERED,SUPPLY_TYPE )                                              
     
        SELECT 
             A.RM_ID,lm.AC_NAME ,
             SR=CAST(1 AS INT),
            CAST('CDNR' AS VARCHAR(100)) AS RTYPE,
            'OC' AS XN_TYPE ,
            CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  B.LOC_GST_NO END AS GSTIN_UIN_RECIPIENT,
            'OC' AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.RM_DT ,6),' ','-')  AS INVOICE_DATE,
            A.RM_NO AS REF_VOUCHER_NO ,
            REPLACE(CONVERT(VARCHAR(9),A.RM_DT ,6),' ','-')  AS REF_VOUCHER_DT,
            'D' AS DOC_TYPE,
            ''   AS REASON,
            CASE WHEN A.MODE=1 THEN LMPS.GST_STATE_CODE+'-'+LMPS.GST_STATE_NAME ELSE  RMLS.GST_STATE_CODE+'-'+RMLS.GST_STATE_NAME END AS PLACE_OF_SUPPLY,
            A.TOTAL_AMOUNT AS REF_VOUCHER_VALUE,
            A.OTHER_CHARGES_GST_PERCENTAGE AS RATE  ,
			A.OTHER_CHARGES_TAXABLE_VALUE   AS TAXABLE_VALUE,
            0 AS CESS_AMOUNT,
            'N' AS PRE_GST,
            A.RM_DT ,
            A.OTHER_CHARGES_IGST_AMOUNT AS IGST_AMOUNT ,
            A.OTHER_CHARGES_CGST_AMOUNT AS CGST_AMOUNT ,
            A.OTHER_CHARGES_SGST_AMOUNT AS SGST_AMOUNT,
            B.LOC_GST_NO,
            b.registered_gst ,
            CASE WHEN A.PARTY_STATE_CODE <>ls.GST_STATE_CODE THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE
       
       FROM RMM01106 A (NOLOCK)
       JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(A.ACCOUNTS_DEPT_ID,'')<>'' THEN ISNULL(A.ACCOUNTS_DEPT_ID,'') ELSE   A.location_Code  END 
	   JOIN GST_STATE_MST LS (NOLOCK)  ON LS.GST_STATE_CODE  =B.GST_STATE_CODE
	   LEFT JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE 
	   LEFT OUTER JOIN LMP01106 LMP (NOLOCK)  ON LMP.AC_CODE =A.AC_CODE
       LEFT JOIN GST_STATE_MST LMPS (NOLOCK)  ON LMPS.GST_STATE_CODE  =LMP.AC_GST_STATE_CODE
	   LEFT OUTER JOIN LOCATION RML (NOLOCK) ON RML.DEPT_ID =A.PARTY_DEPT_ID 
	   LEFT JOIN GST_STATE_MST RMLS (NOLOCK)  ON RMLS.GST_STATE_CODE  =RML.GST_STATE_CODE
       WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
       AND (CASE WHEN ISNULL(A.GST_ITC_DT,'')<>'' THEN A.GST_ITC_DT ELSE A.RM_DT END ) BETWEEN @DFMDATE AND @DTODATE
	   AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
	   AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
	   --AND  ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'') <>''
    --   AND ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'')<>B.LOC_GST_NO
       AND ISNULL(A.OTHER_CHARGES_GST_PERCENTAGE,0)>0
	   and ISNULL(a.bill_challan_mode,0)=0
       AND (@CDEPT_ID='' OR b.dept_id=@CDEPT_ID)
      UNION ALL
      SELECT 
             A.RM_ID,lm.ac_name,
             SR=CAST(1 AS INT),
            CAST('CDNR' AS VARCHAR(100)) AS RTYPE,
            'FR' AS XN_TYPE ,
            CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  B.LOC_GST_NO END AS GSTIN_UIN_RECIPIENT,
            'FR' AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),A.RM_DT ,6),' ','-')  AS INVOICE_DATE,
            A.RM_NO AS REF_VOUCHER_NO ,
            REPLACE(CONVERT(VARCHAR(9),A.RM_DT ,6),' ','-')  AS REF_VOUCHER_DT,
            'D' AS DOC_TYPE,
            ''   AS REASON,
            CASE WHEN A.MODE=1 THEN LMPS.GST_STATE_CODE+'-'+LMPS.GST_STATE_NAME ELSE  RMLS.GST_STATE_CODE+'-'+RMLS.GST_STATE_NAME END AS PLACE_OF_SUPPLY,
            A.TOTAL_AMOUNT AS REF_VOUCHER_VALUE,
            A.freight_GST_PERCENTAGE  ,
			A.freight_TAXABLE_VALUE   AS TAXABLE_VALUE,
            0 AS CESS_AMOUNT,
            'N' AS PRE_GST,
            A.RM_DT ,
            A.freight_IGST_AMOUNT AS IGST_AMOUNT ,
            A.freight_CGST_AMOUNT AS CGST_AMOUNT ,
            A.freight_SGST_AMOUNT AS SGST_AMOUNT,
            B.LOC_GST_NO,
            b.registered_gst ,
            CASE WHEN A.PARTY_STATE_CODE <>ls.GST_STATE_CODE THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE
            
       FROM RMM01106 A (NOLOCK)
       JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(A.ACCOUNTS_DEPT_ID,'')<>'' THEN ISNULL(A.ACCOUNTS_DEPT_ID,'') ELSE   A.location_Code  END 
	   JOIN GST_STATE_MST LS (NOLOCK)  ON LS.GST_STATE_CODE  =B.GST_STATE_CODE
	   LEFT JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE 
	   LEFT OUTER JOIN LMP01106 LMP (NOLOCK)  ON LMP.AC_CODE =A.AC_CODE
       LEFT JOIN GST_STATE_MST LMPS (NOLOCK)  ON LMPS.GST_STATE_CODE  =LMP.AC_GST_STATE_CODE
	   LEFT OUTER JOIN LOCATION RML (NOLOCK) ON RML.DEPT_ID =A.PARTY_DEPT_ID 
	   LEFT JOIN GST_STATE_MST RMLS (NOLOCK)  ON RMLS.GST_STATE_CODE  =RML.GST_STATE_CODE
       WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
       AND (CASE WHEN ISNULL(A.GST_ITC_DT,'')<>'' THEN A.GST_ITC_DT ELSE A.RM_DT END ) BETWEEN @DFMDATE AND @DTODATE
	   AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
	   AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
	   --AND  ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'') <>''
    --   AND ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'')<>B.LOC_GST_NO
       AND ISNULL(A.freight_GST_PERCENTAGE,0)>0
	   and ISNULL(a.bill_challan_mode,0)=0
       AND (@CDEPT_ID='' OR b.dept_id=@CDEPT_ID)

      INSERT INTO @TBLCDNR (MEMO_ID,Ac_name,SR ,RTYPE ,XN_TYPE,GSTIN_UIN_RECIPIENT,INVOICE_NO ,INVOICE_DT ,REF_VOUCHER_NO ,REF_VOUCHER_DT ,
                           DOC_TYPE ,REASON ,PLACE_OF_SUPPLY ,REF_VOUCHER_VALUE ,RATE ,TAXABLE_VALUE ,CESS_AMOUNT ,PRE_GST,MEMO_DT,
                           IGST_AMOUNT ,CGST_AMOUNT ,SGST_AMOUNT ,LOC_GST_NO,PARTY_REGISTERED,SUPPLY_TYPE )                                              
     
      SELECT 
       A.rm_id ,LM.AC_NAME,
             SR=CAST(1 AS INT),
             CAST('CDNR' AS VARCHAR(100)) AS RTYPE,
            'DN' AS XN_TYPE ,
            CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  RML.LOC_GST_NO END AS GSTIN_UIN_RECIPIENT,
            RMD.BILL_NO AS INVOICE_NO,
            REPLACE(CONVERT(VARCHAR(9),RMD.BILL_DT,6),' ','-')  AS INVOICE_DATE,
            A.rm_NO AS REF_VOUCHER_NO ,
            REPLACE(CONVERT(VARCHAR(9),A.RM_DT ,6),' ','-')  AS REF_VOUCHER_DT,
            'D' AS DOC_TYPE,
            ''   AS REASON,
            CASE WHEN A.MODE=1 THEN LMPS.GST_STATE_CODE+'-'+LMPS.GST_STATE_NAME ELSE  RMLS.GST_STATE_CODE+'-'+RMLS.GST_STATE_NAME END AS PLACE_OF_SUPPLY,
            A.TOTAL_AMOUNT AS REF_VOUCHER_VALUE,
            RMD.RATE ,
			RMD.XN_VALUE_WITHOUT_GST  AS TAXABLE_VALUE,
          --  CND.XN_VALUE_WITHOUT_GST AS TAXABLE_VALUE,
            rmd.Gst_cess_amount AS CESS_AMOUNT,
            CASE WHEN rmd .BILL_DT BETWEEN '2017-01-01' AND '2017-06-30'  THEN 'Y' ELSE 'N' END AS PRE_GST,
            A.rm_dt  ,
            RMD.IGST_AMOUNT AS IGST_AMOUNT ,
            RMD.CGST_AMOUNT AS CGST_AMOUNT ,
            RMD.SGST_AMOUNT AS SGST_AMOUNT,
            B.LOC_GST_NO,
            b.registered_gst ,
            CASE WHEN A.PARTY_STATE_CODE <>ls.GST_STATE_CODE THEN 'Intra State' ELSE 'Inter State' END AS SUPPLY_TYPE
            
       FROM rmm01106  A (NOLOCK)
       left JOIN SOR_FDNFCN_LINK SOR (NOLOCK) ON SOR.refFdnMemoId =A.rm_id  
       JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(A.ACCOUNTS_DEPT_ID,'')<>'' THEN ISNULL(A.ACCOUNTS_DEPT_ID,'') ELSE   A.location_Code  END 
	   JOIN GST_STATE_MST LS (NOLOCK)  ON LS.GST_STATE_CODE  =B.GST_STATE_CODE
	   LEFT JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE 
	   LEFT OUTER JOIN LMP01106 LMP (NOLOCK)  ON LMP.AC_CODE =A.AC_CODE
       LEFT JOIN GST_STATE_MST LMPS (NOLOCK)  ON LMPS.GST_STATE_CODE  =LMP.AC_GST_STATE_CODE
       JOIN 
	   (
	     SELECT rm_id,RMD.BILL_NO AS BILL_NO,rmd.BILL_DT AS BILL_DT,
				   ISNULL(rmd.GST_PERCENTAGE,0) AS RATE  ,
				   SUM(XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST,
				   SUM(igst_amount ) AS igst_amount,
				   SUM(cgst_amount ) AS cgst_amount,
				   SUM(sgst_amount ) AS sgst_amount,
				   SUM(isnull(Gst_cess_amount,0)) as Gst_cess_amount
		 FROM rmd01106    rmd (NOLOCK) 
		 WHERE ISNULL(rmd.GST_PERCENTAGE,0)>0
		 GROUP BY rm_id  ,rmd.bill_no ,rmd.bill_dt ,rmd.GST_PERCENTAGE
	   )rmd ON A.rm_id =rmd.rm_id 
	   LEFT OUTER JOIN LOCATION RML (NOLOCK) ON RML.DEPT_ID =A.PARTY_DEPT_ID 
	   LEFT JOIN GST_STATE_MST RMLS (NOLOCK)  ON RMLS.GST_STATE_CODE  =RML.GST_STATE_CODE
      WHERE A.CANCELLED =0 AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
	  AND (CASE WHEN ISNULL(A.GST_ITC_DT,'')<>'' THEN A.GST_ITC_DT ELSE A.RM_DT END )  BETWEEN @DFMDATE AND @DTODATE
	  AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
	  AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
	  AND  ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'') <>''
      AND ISNULL(CASE WHEN A.MODE=1 THEN  LMP.AC_GST_NO ELSE  ISNULL(RML.LOC_GST_NO,'') END,'')<>B.LOC_GST_NO
      AND (@CDEPT_ID='' OR b.dept_id=@CDEPT_ID)
	  and ISNULL(a.bill_challan_mode,0)=0 and sor.refFdnMemoId is null
      
     --change according to ticket no 491 Saree Sansar donot show fr and oc in over head invoice as on(20240916)
     
     UPDATE A SET INVOICE_NO =B.INVOICE_NO  FROM @TBLCDNR A 
     JOIN @TBLCDNR B ON A.MEMO_ID=B.MEMO_ID AND B.XN_TYPE ='DN' AND A.RTYPE =B.RTYPE 
     WHERE A.RTYPE ='CDNR' AND  A.XN_TYPE IN('OC','FR')
   
	  UPDATE A SET INVOICE_DT =B.INVOICE_DT  FROM @TBLCDNR A   
     JOIN @TBLCDNR B ON A.MEMO_ID=B.MEMO_ID AND B.XN_TYPE ='DN' AND A.RTYPE =B.RTYPE  and A.RATE =B.RATE  
     WHERE A.RTYPE ='CDNR' AND  A.XN_TYPE IN('OC','FR')  
       
     
        SELECT RTYPE ,
             GSTIN_UIN_RECIPIENT AS [GSTIN of Supplier],
			 a.AC_NAME as [Trade/Legal name],
			 CASE WHEN ISNULL(@PICK_CN_NO_GST,'')='1' THEN RTRIM(LTRIM(REF_VOUCHER_NO)) ELSE 
             RTRIM(LTRIM(REF_VOUCHER_NO))+'/'+RTRIM(LTRIM(INVOICE_NO))+'/'+REPLACE(CAST (RATE AS VARCHAR(10)),'.00','') END  AS [NOTE/REFUND VOUCHER NUMBER],
             REF_VOUCHER_DT AS [Note/Refund Voucher date], 
             INVOICE_NO  AS [Invoice/Advance Payment Voucher Number],
             INVOICE_DT AS [Invoice/Advance Payment Voucher date],
             PRE_GST AS [PRE GST] ,
             DOC_TYPE AS [DOCUMENT TYPE],
             '01-Sales Return' AS [Reason For Issuing document],
             SUPPLY_TYPE AS [Supply Type],
             REF_VOUCHER_VALUE AS [NOTE/REFUND VOUCHER VALUE],
             RATE AS [RATE],
             SUM(TAXABLE_VALUE) AS [TAXABLE VALUE] ,
             SUM(IGST_AMOUNT) AS [Integrated Tax Paid],
             SUM(CGST_AMOUNT) AS [Central Tax Paid],
             SUM(SGST_AMOUNT) AS [State/UT Tax Paid],   
             REASON AS [REASON FOR ISSUING DOCUMENT],
            
          --   SUM(CESS_AMOUNT) AS [Cess Paid], 
             'Inputs' as [Eligibility For ITC],
             SUM(IGST_AMOUNT) as [Availed ITC Integrated Tax],
             SUM(CGST_AMOUNT)as [Availed ITC Central Tax],
             SUM(SGST_AMOUNT) as [Availed ITC State/UT Tax],
             SUM(isnull(cess_amount,0)) as [Availed ITC Cess]

      FROM @TBLCDNR A
      WHERE ISNULL(GSTIN_UIN_RECIPIENT,'')<>''
      AND ISNULL(GSTIN_UIN_RECIPIENT,'')<>ISNULL(LOC_GST_NO,'') 
      GROUP BY RTYPE ,GSTIN_UIN_RECIPIENT ,INVOICE_NO  ,INVOICE_DT ,a.AC_NAME,
      CASE WHEN ISNULL(@PICK_CN_NO_GST,'')='1' THEN RTRIM(LTRIM(REF_VOUCHER_NO)) ELSE 
      RTRIM(LTRIM(REF_VOUCHER_NO))+'/'+RTRIM(LTRIM(INVOICE_NO))+'/'+REPLACE(CAST (RATE AS VARCHAR(10)),'.00','') END ,
      REF_VOUCHER_DT , DOC_TYPE ,REASON ,PLACE_OF_SUPPLY ,
      REF_VOUCHER_VALUE ,RATE ,PRE_GST,SUPPLY_TYPE 
      ORDER BY DOC_TYPE,REF_VOUCHER_DT,
	  CASE WHEN ISNULL(@PICK_CN_NO_GST,'')='1' THEN RTRIM(LTRIM(REF_VOUCHER_NO)) ELSE 
             RTRIM(LTRIM(REF_VOUCHER_NO))+'/'+RTRIM(LTRIM(INVOICE_NO))+'/'+REPLACE(CAST (RATE AS VARCHAR(10)),'.00','') END,RATE
      
     											



       SELECT 'CDNUR' RTYPE ,
             --GSTIN_UIN_RECIPIENT AS [GSTIN/UIN OF RECIPIENT],
			 CASE WHEN ISNULL(@PICK_CN_NO_GST,'')='1' THEN RTRIM(LTRIM(REF_VOUCHER_NO)) ELSE
             RTRIM(LTRIM(REF_VOUCHER_NO))+'/'+RTRIM(LTRIM(INVOICE_NO))+'/'+REPLACE(CAST (RATE AS VARCHAR(10)),'.00','') 
              END AS [Note/Voucher Number],
             REF_VOUCHER_DT AS [Note/Voucher date], 
             INVOICE_NO  AS [Invoice/Advance Payment Voucher number],
             INVOICE_DT AS [Invoice/Advance Payment Voucher date],
             PRE_GST AS [Pre GST] ,
             DOC_TYPE AS [Document Type],
             '' AS [Reason For Issuing document],
             SUPPLY_TYPE AS [Supply Type],
             '' as [Invoice Type],
             REF_VOUCHER_VALUE AS [NOTE/REFUND VOUCHER VALUE],
             RATE AS [RATE],
             SUM(TAXABLE_VALUE) AS [TAXABLE VALUE] ,
             SUM(IGST_AMOUNT) AS [Integrated Tax Paid],
             SUM(CGST_AMOUNT) AS [Central Tax Paid],
             SUM(SGST_AMOUNT) AS [State/UT Tax Paid],   
             --REASON AS [REASON FOR ISSUING DOCUMENT],
             PLACE_OF_SUPPLY AS [PLACE OF SUPPLY] ,
             0 AS [Cess Paid] ,
             0 as [Eligibility For ITC],	
             0 as [Availed ITC Integrated Tax],
             0 as [Availed ITC Central Tax]	,
             0 as [Availed ITC State/UT Tax],
             0 as [Availed ITC Cess	]
             
      FROM @TBLCDNR A
      WHERE ISNULL(GSTIN_UIN_RECIPIENT,'')=''
      GROUP BY  CASE WHEN ISNULL(@PICK_CN_NO_GST,'')='1' THEN RTRIM(LTRIM(REF_VOUCHER_NO)) 
	  ELSE RTRIM(LTRIM(REF_VOUCHER_NO))+'/'+RTRIM(LTRIM(INVOICE_NO))+'/'+REPLACE(CAST (RATE AS VARCHAR(10)),'.00','') END ,
      REF_VOUCHER_DT,INVOICE_NO,INVOICE_DT,PRE_GST,DOC_TYPE,SUPPLY_TYPE,REF_VOUCHER_VALUE,RATE,PLACE_OF_SUPPLY
      
      
  
     EXEC SP3S_HSN_GSTR2 @DFMDATE,@DTODATE,@CGSTN_NO,@CLOC_TYPE,@CDEPT_ID
      
      
      
END



