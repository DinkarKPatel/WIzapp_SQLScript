

IF NOT EXISTS (SELECT TOP 1 XN_TYPE FROM GST_ACCOUNTS_CONFIG_DET_OVERHEADS)
BEGIN
	
	
	IF OBJECT_ID('TEMPDB..#TMPGACDO','U') IS NOT NULL
		DROP TABLE #TMPGACDO
		
	SELECT XN_TYPE, GST_PERCENTAGE,IGST_XN_AC_CODE, LOCAL_GST_XN_AC_CODE, IGST_TAX_AC_CODE, CGST_TAX_AC_CODE, SGST_TAX_AC_CODE
	INTO #TMPGACDO FROM 
	(	SELECT *
		FROM 
		(
		SELECT A.XN_TYPE+(CASE WHEN B.COLUMNNAME='FREIGHT_AC_CODE' THEN 'FREIGHT'
		WHEN B.COLUMNNAME='OTHER_CHARGES_AC_CODE' THEN 'OC' ELSE 'INSURANCE' END) AS XN_TYPE , GST_PERCENTAGE ,
		B.COLUMNNAME,ISNULL(B.VALUE,'0000000000') AS VALUE
		FROM GST_ACCOUNTS_CONFIG_DET_2 A,GST_ACCOUNTS_CONFIG_DET_1 B
		WHERE A.XN_TYPE<>'IWS' AND A.XN_TYPE=B.XN_TYPE 
		AND B.COLUMNNAME IN ('FREIGHT_AC_CODE','OTHER_CHARGES_AC_CODE','INSURANCE_AC_CODE')
		GROUP BY A.XN_TYPE,A.GST_PERCENTAGE,B.COLUMNNAME,ISNULL(B.VALUE,'0000000000')
		) A
		PIVOT (MAX(VALUE) FOR COLUMNNAME IN ([CGST_TAX_AC_CODE],[IGST_TAX_AC_CODE],[IGST_XN_AC_CODE],[LOCAL_GST_XN_AC_CODE],[SGST_TAX_AC_CODE])) AS PTABLE
	) B WHERE GST_PERCENTAGE<100
	
	UPDATE A SET IGST_XN_AC_CODE=ISNULL(B.VALUE,'0000000000') ,LOCAL_GST_XN_AC_CODE=ISNULL(B.VALUE,'0000000000') FROM #TMPGACDO A
	JOIN GST_ACCOUNTS_CONFIG_DET_1 B ON LEFT(A.XN_TYPE,3)=B.XN_TYPE
	WHERE A.XN_TYPE LIKE '%FREIGHT%' AND B.COLUMNNAME='FREIGHT_AC_CODE'
	
	UPDATE A SET IGST_XN_AC_CODE=ISNULL(B.VALUE,'0000000000'),LOCAL_GST_XN_AC_CODE=ISNULL(B.VALUE,'0000000000') FROM #TMPGACDO A
	JOIN GST_ACCOUNTS_CONFIG_DET_1 B ON LEFT(A.XN_TYPE,3)=B.XN_TYPE
	WHERE A.XN_TYPE LIKE '%OC%' AND B.COLUMNNAME='OTHER_CHARGES_AC_CODE'

	UPDATE A SET IGST_XN_AC_CODE=ISNULL(B.VALUE,'0000000000'),LOCAL_GST_XN_AC_CODE=ISNULL(B.VALUE,'0000000000') FROM #TMPGACDO A
	JOIN GST_ACCOUNTS_CONFIG_DET_1 B ON LEFT(A.XN_TYPE,3)=B.XN_TYPE
	WHERE A.XN_TYPE LIKE '%INSURANCE%' AND B.COLUMNNAME='INSURANCE_AC_CODE'	

	UPDATE A SET IGST_TAX_AC_CODE=C.IGST_TAX_AC_CODE,CGST_TAX_AC_CODE=C.CGST_TAX_AC_CODE,
	SGST_TAX_AC_CODE=C.SGST_TAX_AC_CODE FROM 
	#TMPGACDO A
	JOIN 
	(SELECT XN_TYPE, GST_PERCENTAGE,ISNULL(IGST_TAX_AC_CODE,'0000000000') AS IGST_TAX_AC_CODE,
	 ISNULL(CGST_TAX_AC_CODE,'0000000000') AS CGST_TAX_AC_CODE ,
	 ISNULL(SGST_TAX_AC_CODE,'0000000000') AS SGST_TAX_AC_CODE
	FROM 
	(	SELECT *
		FROM 
		(
		SELECT XN_TYPE, GST_PERCENTAGE ,COLUMNNAME,ISNULL(VALUE,'0000000000') AS VALUE
		FROM GST_ACCOUNTS_CONFIG_DET_2
		WHERE XN_TYPE<>'IWS'
		GROUP BY XN_TYPE,GST_PERCENTAGE,COLUMNNAME,ISNULL(VALUE,'0000000000')
		) A
		PIVOT (MAX(VALUE) FOR COLUMNNAME IN ([CGST_TAX_AC_CODE],[IGST_TAX_AC_CODE],[SGST_TAX_AC_CODE])) AS PTABLE
	) B WHERE GST_PERCENTAGE<100
    ) C ON  C.XN_TYPE=LEFT(A.XN_TYPE,3)
	
	
	INSERT GST_ACCOUNTS_CONFIG_DET_OVERHEADS	( XN_TYPE, GST_PERCENTAGE, IGST_REVENUE_AC_CODE, LGST_REVENUE_AC_CODE, 
	IGST_TAX_AC_CODE, CGST_TAX_AC_CODE, SGST_TAX_AC_CODE )  
	SELECT XN_TYPE, GST_PERCENTAGE, ISNULL(IGST_XN_AC_CODE,'0000000000'), ISNULL(LOCAL_GST_XN_AC_CODE,'0000000000'), 
	ISNULL(IGST_TAX_AC_CODE,'0000000000'), ISNULL(CGST_TAX_AC_CODE,'0000000000'), ISNULL(SGST_TAX_AC_CODE,'0000000000')
	FROM #TMPGACDO
END
