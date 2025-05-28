
create PROCEDURE SP3S_REP_GSTR3B
(
  @DFMDATE DATETIME='2022-03-31',
  @DTODATE DATETIME='2022-03-31',
  @CGSTN_NO VARCHAR(100)='',
  @CLOC_TYPE INT=0,--0 FOR ALL 1 FOR ONLY COMPANY OWNED,
  @CDEPT_ID VARCHAR(5)=''
  
)
AS
BEGIN
     
     IF @DFMDATE<='2017-06-30'
     RETURN
     
     DECLARE @NYEAR INT 
     
     SET @NYEAR=(SELECT CASE WHEN MONTH(@DFMDATE)<=3  THEN   YEAR(@DFMDATE)-1
     ELSE YEAR(@DFMDATE) END )
     
     
     SELECT DISTINCT B.LOC_GST_NO AS GSTIN,com.COMPANY_NAME AS [LEGAL NAME OF THE REGISTERED PERSON],
            CAST(@NYEAR AS VARCHAR(10))+'-'+ CAST(RIGHT(@NYEAR,2)+1 AS VARCHAR(10)) AS [YEAR],
            DATENAME (MM,@DFMDATE) AS MONTH	

     FROM LOCATION B
     join COMPANY com on com.COMPANY_CODE ='01'
     WHERE  INACTIVE =0
     AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
     AND  B.LOC_GST_NO<>''
     
     --FOR 3.1 & 4 RCM & PURCHASE'
     
       IF OBJECT_ID ('TEMPDB..#TMPGSTR3B1','U') IS NOT NULL
        DROP TABLE #TMPGSTR3B1
     
     SELECT CAST('' AS  VARCHAR(50)) AS XN_TYPE,
            CAST('' AS  VARCHAR(50)) AS MEMO_ID,
            CAST('' AS  VARCHAR(50)) AS UOM_NAME,
            CAST('' AS  VARCHAR(50)) AS HSN_CODE,
            CAST('' AS  VARCHAR(1000)) AS DESCR,
            CAST(0 AS NUMERIC(10,2)) AS QTY,
             CAST(0 AS NUMERIC(14,2)) AS NET_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS TAXABLE_VALUE,
            CAST(0 AS NUMERIC(14,2)) AS IGST_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS CGST_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS SGST_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS CESS_AMOUNT,
            CAST('' AS  VARCHAR(50)) AS PRODUCT_CODE,
             CAST(0 AS INT) AS SR,
             CAST(0 AS INT) AS rcm_applicable,
			 cast(0 as numeric(12,2)) as RATE
			 --CAST('' AS  VARCHAR(5)) AS location_code
            INTO #TMPGSTR3B1
            WHERE 1=2
      INSERT INTO #TMPGSTR3B1
      EXEC  SP3S_hsn_GSTR2 @DFMDATE,@DTODATE,@CGSTN_NO,@CLOC_TYPE,@CDEPT_ID,1


     
     IF OBJECT_ID ('TEMPDB..#TMPGSTR3B','U') IS NOT NULL
        DROP TABLE #TMPGSTR3B
     
     SELECT CAST('' AS  VARCHAR(50)) AS XN_TYPE,
            CAST('' AS  VARCHAR(50)) AS MEMO_ID,
            CAST('' AS  VARCHAR(50)) AS UOM_NAME,
            CAST('' AS  VARCHAR(50)) AS HSN_CODE,
            CAST('' AS  VARCHAR(1000)) AS DESCR,
            CAST(0 AS NUMERIC(10,2)) AS QTY,
             CAST(0 AS NUMERIC(14,2)) AS NET_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS TAXABLE_VALUE,
            CAST(0 AS NUMERIC(14,2)) AS IGST_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS CGST_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS SGST_AMOUNT,
            CAST(0 AS NUMERIC(14,2)) AS CESS_AMOUNT,
            CAST('' AS  VARCHAR(50)) AS PRODUCT_CODE,
            CAST(0 AS INT) AS SR,
            CAST('' AS  VARCHAR(10)) AS PARTY_STATE_CODE,
            CAST(0 AS INT) AS REGISTERED_GST_DEALER,
			CAST('' AS  VARCHAR(5)) AS location_code
            INTO #TMPGSTR3B
            WHERE 1=2
            
    INSERT INTO #TMPGSTR3B        
    EXEC  SP3S_REP_GST3B_SUMMARY @DFMDATE,@DTODATE,@CGSTN_NO,@CLOC_TYPE,@CDEPT_ID,1

    
    ALTER TABLE #TMPGSTR3B ADD Nature_of_Supplies VARCHAR(1000)
    
       update #TMPGSTR3B set Nature_of_Supplies=case when ISNULL(IGST_AMOUNT  ,0)+ISNULL(CGST_AMOUNT  ,0)+ISNULL(SGST_AMOUNT  ,0)=0 then '( c) Other outward supplies, (Nil rated, exempted)'
     else '(a) Outward Taxable  supplies  (other than zero rated, nil rated and exempted)' end 
         
      SELECT '3.1' as sr,
            Nature_of_Supplies  as [Nature of Supplies],
            sum(isnull(A.TAXABLE_VALUE,0)) as [Total Taxable value],
            SUM(ISNULL(A.IGST_AMOUNT,0)) as [Integrated Tax],
            sum(ISNULL(A.CGST_AMOUNT,0)) as [Central Tax],
            SUM(ISNULL(A.SGST_AMOUNT,0)) AS [State/UT Tax],
            0 AS [Cess]
           
     FROM #TMPGSTR3B A
     group by Nature_of_Supplies
	-- order by Nature_of_Supplies
     UNION ALL
      SELECT '3.1' as sr,
            '(d) Inward supplies (liable to reverse charge)'  as [Nature of Supplies],
            sum(isnull(A.TAXABLE_VALUE,0)) as [Total Taxable value],
            SUM(ISNULL(A.IGST_AMOUNT,0)) as [Integrated Tax],
            sum(ISNULL(A.CGST_AMOUNT,0)) as [Central Tax],
            SUM(ISNULL(A.SGST_AMOUNT,0)) AS [State/UT Tax],
            0 AS [Cess]
           
     FROM #TMPGSTR3B1 A
     WHERE ISNULL(rcm_applicable,0)=1
     UNION ALL
     SELECT '3.1' as sr,
            'Total'  as [Nature of Supplies],
            sum(isnull(A.TAXABLE_VALUE,0)) as [Total Taxable value],
            SUM(ISNULL(A.IGST_AMOUNT,0)) as [Integrated Tax],
            sum(ISNULL(A.CGST_AMOUNT,0)) as [Central Tax],
            SUM(ISNULL(A.SGST_AMOUNT,0)) AS [State/UT Tax],
            0 AS [Cess]
      FROM
      (
       SELECT TAXABLE_VALUE,IGST_AMOUNT,CGST_AMOUNT,SGST_AMOUNT
       FROM #TMPGSTR3B
      
      )  A   
     ORDER BY [Nature of Supplies]
     
      SELECT '3.2' AS SR,
            -- (CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=0 THEN 1
            --       WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=2 THEN 2
            --       WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=1 THEN 3
            --ELSE 0 END)  AS [PRINT_SR],
            
            A.PARTY_STATE_CODE +'-'+GM.GST_STATE_NAME as [Place of Supply(State/UT)],
            SUM(CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=0 THEN ISNULL(A.TAXABLE_VALUE,0)
            ELSE 0 END)  AS [TOTAL TAXABLE VALUE],
            SUM(CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=0 THEN ISNULL(A.IGST_AMOUNT,0)
            ELSE 0 END)  AS [AMOUNT OF INTEGRATED TAX],
            
            SUM(CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=2 THEN ISNULL(A.TAXABLE_VALUE,0)
            ELSE 0 END)  AS [TOTAL TAXABLE VALUE],
            SUM(CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=2 THEN ISNULL(A.IGST_AMOUNT,0)
            ELSE 0 END)  AS [AMOUNT OF INTEGRATED TAX],
            0  AS [TOTAL TAXABLE VALUE],
            0  AS [AMOUNT OF INTEGRATED TAX]
            
            --SUM(CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=1 THEN ISNULL(A.TAXABLE_VALUE,0)
            --ELSE 0 END)  AS [TOTAL TAXABLE VALUE],
            --SUM(CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=1 THEN ISNULL(A.IGST_AMOUNT,0)
            --ELSE 0 END)  AS [AMOUNT OF INTEGRATED TAX]
           
     FROM #TMPGSTR3B  A
     JOIN GST_STATE_MST GM (NOLOCK) ON GM.GST_STATE_CODE =A.PARTY_STATE_CODE 
     JOIN LOCATION L ON L.DEPT_ID =A.location_code
     WHERE L.GST_STATE_CODE <>A.PARTY_STATE_CODE 
     GROUP BY  A.PARTY_STATE_CODE +'-'+GM.GST_STATE_NAME,
     (CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=0 THEN 1
                   WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=2 THEN 2
                   --WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=1 THEN 3
            ELSE 0 END)
            having SUM(CASE WHEN ISNULL(a.REGISTERED_GST_DEALER ,0)=0 THEN ISNULL(A.IGST_AMOUNT,0)
            ELSE 0 END)<>0
     
     
     
     
     SELECT '4' AS SR, '(3)Inward supplies'as [Details],
            SUM(ISNULL(A.IGST_AMOUNT,0)) AS [INTEGRATED TAX],
            SUM(ISNULL(A.CGST_AMOUNT,0)) AS [Central Tax],
            SUM(ISNULL(A.SGST_AMOUNT,0)) AS [State/ UT Tax],
            0 AS [Cess]
     FROM #TMPGSTR3B1 a
     WHERE ISNULL(rcm_applicable,0)=1
     HAVING (SUM(ISNULL(A.SGST_AMOUNT,0))<>0 OR SUM(ISNULL(A.IGST_AMOUNT,0))<>0)
     UNION ALL
     SELECT '4' AS SR, '(5) All other ITC'  as [Details],
            SUM(ISNULL(A.IGST_AMOUNT,0)) AS [INTEGRATED TAX],
            SUM(ISNULL(A.CGST_AMOUNT,0)) AS [Central Tax],
            SUM(ISNULL(A.SGST_AMOUNT,0)) AS [State/ UT Tax],
            0 AS [Cess]
     FROM #TMPGSTR3B1 a
	 join sku (nolock) on a.PRODUCT_CODE =sku.PRODUCT_CODE
	 join Article art (nolock) on art.article_code=sku.article_code
     WHERE ISNULL(rcm_applicable,0)=0 and  isnull(art.input_gst,0)=0
     UNION ALL
     SELECT '4' AS SR, '(C) Net ITC Available (A)-(B)'  as [Details],
            SUM(ISNULL(A.IGST_AMOUNT,0)) AS [INTEGRATED TAX],
            SUM(ISNULL(A.CGST_AMOUNT,0)) AS [Central Tax],
     SUM(ISNULL(A.SGST_AMOUNT,0)) AS [State/ UT Tax],
            0 AS [Cess]
     FROM #TMPGSTR3B1 a
	 join sku (nolock) on a.PRODUCT_CODE =sku.PRODUCT_CODE
	 join Article art (nolock) on art.article_code=sku.article_code
	 where  isnull(art.input_gst,0)=0
      UNION ALL
     SELECT '4' AS SR, '(1)   As per section 17(5) of CGST//SGST Act'  as [Details],
            SUM(ISNULL(A.IGST_AMOUNT,0)) AS [INTEGRATED TAX],
            SUM(ISNULL(A.CGST_AMOUNT,0)) AS [Central Tax],
            SUM(ISNULL(A.SGST_AMOUNT,0)) AS [State/ UT Tax],
            0 AS [Cess]
     FROM #TMPGSTR3B1 a
	 join sku (nolock) on a.PRODUCT_CODE =sku.PRODUCT_CODE
	 join Article art (nolock) on art.article_code=sku.article_code
	 where a.PRODUCT_CODE<>'' and isnull(art.input_gst,0)=1



	 IF OBJECT_ID('TEMPDB..#TMPnongstsupply','U') IS NOT NULL
         DROP TABLE #TMPnongstsupply

		

      SELECT CAST('PUR' AS VARCHAR(100)) AS XN_TYPE,
             CAST(A.mrr_id  AS VARCHAR(100)) AS MEMO_ID,
              CASE WHEN A.PARTY_STATE_CODE <>B.GST_STATE_CODE THEN A.OTHER_CHARGES_TAXABLE_VALUE  ELSE 0 END AS IGST_TAXABLEVALUE,
			 CASE WHEN A.PARTY_STATE_CODE =B.GST_STATE_CODE THEN A.OTHER_CHARGES_TAXABLE_VALUE ELSE 0 END AS INTRAGST_TAXABLEVALUE
      INTO #TMPnongstsupply
      FROM pim01106 A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(A.PUR_FOR_DEPT_ID,'')<>'' THEN PUR_FOR_DEPT_ID ELSE  LEFT (A.MRR_ID ,2) END 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
      LEFT JOIN LMP01106 LMP  (NOLOCK) ON LMP.AC_CODE =A.ac_code 
      LEFT JOIN location SL ON SL.dept_id =A.challan_source_location_code 
      WHERE A.CANCELLED =0
      AND A.BILL_DT BETWEEN @DFMDATE AND @DTODATE
     -- AND (@CDEPT_ID='' OR LEFT (A.CM_ID,2)=@CDEPT_ID)
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND ISNULL(A.OTHER_CHARGES_GST_PERCENTAGE,0)=0
	  and A.OTHER_CHARGES<>0
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR b.dept_id=@CDEPT_ID)
      AND LMP.AC_GST_NO <>CASE WHEN A.INV_MODE =1 THEN B.LOC_GST_NO ELSE b.LOC_GST_NO END
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
      union all
       
      SELECT CAST('PUR' AS VARCHAR(100)) AS XN_TYPE,
             CAST(A.mrr_id  AS VARCHAR(100)) AS MEMO_ID,
             CASE WHEN A.PARTY_STATE_CODE <>B.GST_STATE_CODE THEN A.FREIGHT_TAXABLE_VALUE  ELSE 0 END AS IGST_TAXABLEVALUE,
			 CASE WHEN A.PARTY_STATE_CODE =B.GST_STATE_CODE THEN A.FREIGHT_TAXABLE_VALUE ELSE 0 END AS INTRAGST_TAXABLEVALUE
      FROM pim01106 A (NOLOCK)
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(A.PUR_FOR_DEPT_ID,'')<>'' THEN PUR_FOR_DEPT_ID ELSE  LEFT (A.MRR_ID ,2) END 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
      LEFT JOIN LMP01106 LMP  (NOLOCK) ON LMP.AC_CODE =A.ac_code 
      LEFT JOIN location SL ON SL.dept_id =A.challan_source_location_code 
      WHERE A.CANCELLED =0
      AND A.BILL_DT  BETWEEN @DFMDATE AND @DTODATE
     -- AND (@CDEPT_ID='' OR LEFT (A.CM_ID,2)=@CDEPT_ID)
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND ISNULL(A.freight_gst_percentage ,0)=0
	  and freight <>0
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR b.dept_id=@CDEPT_ID)
       AND LMP.AC_GST_NO <>CASE WHEN A.INV_MODE =1 THEN B.LOC_GST_NO ELSE b.LOC_GST_NO END
      and ISNULL(LMP.AC_GST_NO,'')<>''
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
	   union all
      SELECT CAST('PUR' AS VARCHAR(100)) AS XN_TYPE,
             CAST(A.mrr_id  AS VARCHAR(100)) AS MEMO_ID,
	         CASE WHEN A.PARTY_STATE_CODE <>B.GST_STATE_CODE THEN PID.XN_VALUE_WITH_GST ELSE 0 END AS IGST_TAXABLEVALUE,
			 CASE WHEN A.PARTY_STATE_CODE =B.GST_STATE_CODE THEN PID.XN_VALUE_WITH_GST ELSE 0 END AS INTRAGST_TAXABLEVALUE
      FROM pim01106  A (NOLOCK)
      JOIN pid01106  pid (NOLOCK) ON A.mrr_id =pid.mrr_id
      JOIN LOCATION B (NOLOCK) ON B.DEPT_ID =CASE WHEN ISNULL(A.PUR_FOR_DEPT_ID,'')<>'' THEN PUR_FOR_DEPT_ID ELSE  A.location_Code  END 
      JOIN GST_STATE_MST C (NOLOCK)  ON B.GST_STATE_CODE =C.GST_STATE_CODE 
	  LEFT JOIN LMP01106 LMP  (NOLOCK) ON LMP.AC_CODE =A.ac_code 
      WHERE A.CANCELLED =0 
      AND A.BILL_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR B.LOC_GST_NO=@CGSTN_NO)
      AND ISNULL(A.MEMO_TYPE,0) IN(0,1)
      AND (@CLOC_TYPE=0 OR ISNULL(B.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR b.dept_id=@CDEPT_ID)
      AND LMP.AC_GST_NO <>CASE WHEN A.INV_MODE =1 THEN B.LOC_GST_NO ELSE b.LOC_GST_NO END
      and pid.gst_percentage =0
      AND ISNULL(A.BILL_CHALLAN_MODE,0)=0
      and ISNULL(A.RCM_APPLICABLE,0)=0

	  select '5' AS SR,  'From a supplier under composition scheme, Exempt  and Nil rated supply' [DETAILS],
	         SUM(case when L.gst_state_code<>isnull(LMP.ac_gst_state_code,'') and L.gst_state_code<>'00'  THEN DEBIT_AMOUNT-CREDIT_AMOUNT ELSE 0 END) AS [Inter-State supplies],
			 SUM(case when L.gst_state_code=LMP.ac_gst_state_code THEN DEBIT_AMOUNT-CREDIT_AMOUNT ELSE 0 END)  AS  [Intra-State supplies]
	  FROM VD01106 A (NOLOCK)
	  JOIN VM01106 B (NOLOCK) ON A.VM_ID =B.VM_ID 
	  join LM01106 lm (nolock) on a.AC_CODE =lm.AC_CODE 
	  left JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE=LM.AC_CODE 
	  join location l on l.dept_id=a.cost_center_dept_id
	  WHERE B.CANCELLED=0  AND LM.GSTR3B=1
	  AND B.VOUCHER_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR L.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(L.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR L.dept_id=@CDEPT_ID)
      AND isnull(LMP.AC_GST_NO,'') <>L.LOC_GST_NO
	  UNION ALL
	  select sr ,[DETAILS],sum(isnull([Inter-State supplies],0)) as [Inter-State supplies],
	             sum(isnull([Intra-State supplies],0)) as [Intra-State supplies]
	from
	(
	  SELECT '5' AS SR, 'Non GST supply' [DETAILS],
	         SUM(IGST_TAXABLEVALUE) AS  [Inter-State supplies],
			 SUM(INTRAGST_TAXABLEVALUE) AS  [Intra-State supplies]
	  FROM #TMPnongstsupply
      union all
      
	 select '5' AS SR,  'Non GST supply',
	         SUM(case when L.gst_state_code<>isnull(LMP.ac_gst_state_code,'') and L.gst_state_code<>'00' THEN DEBIT_AMOUNT-CREDIT_AMOUNT ELSE 0 END) AS [Inter-State supplies],
			 SUM(case when L.gst_state_code=LMP.ac_gst_state_code THEN DEBIT_AMOUNT-CREDIT_AMOUNT ELSE 0 END)  AS  [Intra-State supplies]
	  FROM VD01106 A (NOLOCK)
	  JOIN VM01106 B (NOLOCK) ON A.VM_ID =B.VM_ID 
	  join LM01106 lm (nolock) on a.AC_CODE =lm.AC_CODE 
	  left JOIN LMP01106 LMP (NOLOCK) ON LMP.AC_CODE=LM.AC_CODE 
	  join location l on l.dept_id=a.cost_center_dept_id
	  WHERE B.CANCELLED=0  AND LM.GSTR3B=2
	  AND B.VOUCHER_DT  BETWEEN @DFMDATE AND @DTODATE
      AND (@CGSTN_NO='' OR L.LOC_GST_NO=@CGSTN_NO)
      AND (@CLOC_TYPE=0 OR ISNULL(L.LOC_TYPE,0) =@CLOC_TYPE)
      AND (@CDEPT_ID='' OR L.dept_id=@CDEPT_ID)
      AND isnull(LMP.AC_GST_NO,'') <>L.LOC_GST_NO
	  ) a
	  group by sr ,[DETAILS]
      
END


