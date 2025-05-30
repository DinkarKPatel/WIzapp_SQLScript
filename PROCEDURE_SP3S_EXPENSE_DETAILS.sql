CREATE PROCEDURE SP3S_EXPENSE_DETAILS--(LocId 3 digit change by Sanjay:06-11-2024)
(
  @NQUERYID INT=0,
  @DFM_DT DATETIME,
  @DTODT DATETIME,
  @CMEMO_ID VARCHAR(50)='',
  @CXN_TYPE VARCHAR(5)='EXP',
  @CCURDEPT_ID VARCHAR(4)
)
AS
BEGIN
   DECLARE @CHODEPT_ID VARCHAR(4)

   SELECT TOP 1 @CHODEPT_ID=VALUE  FROM CONFIG WHERE CONFIG_OPTION ='HO_LOCATION_ID'
   
   IF @CCURDEPT_ID=''
   SELECT TOP 1 @CCURDEPT_ID=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
   ELSE
   SET @CCURDEPT_ID=ISNULL(@CCURDEPT_ID,'')
   
   IF @CHODEPT_ID<>@CCURDEPT_ID
      RETURN
      
   IF @NQUERYID=1
      GOTO LBLMST
   ELSE IF @NQUERYID=2
      GOTO LBLSUPPLIER
   ELSE 
      GOTO END_PROC
      
  LBLSUPPLIER:
  
	  SELECT AC_CODE,AC_NAME FROM LM01106  
	  ORDER BY AC_NAME 
	  
  GOTO END_PROC  
  
LBLMST:    
IF @CXN_TYPE='EXP'    
BEGIN
     
 IF @CMEMO_ID=''
  BEGIN
     IF OBJECT_ID('TEMPDB..#TMPRCM','U') IS NOT NULL
        DROP TABLE #TMPRCM
  
	SELECT CAST('EXP' AS VARCHAR(10)) AS XN_TYPE, LM.AC_NAME , A.AC_CODE,A.FIN_YEAR ,
	       L.LOC_GST_NO,A.MEMO_DT ,SUM(A.TOTAL_AMOUNT) AS TOTAL_AMOUNT,
	       '' AS HSN_CODE
	INTO #TMPRCM
	FROM SUPPLY_EXPENSE_XN_MST a (NOLOCK) 
	JOIN LOCATION L ON L.DEPT_ID =a.location_Code
	JOIN LMP01106 (NOLOCK) LMP ON LMP.AC_CODE =A.AC_CODE 
	JOIN  LM01106 (NOLOCK) LM ON LM.AC_CODE =A.AC_CODE 
	LEFT OUTER JOIN 
    ( SELECT B.MEMO_ID  FROM RCM01106 A
      JOIN  RCM_PUR_EXPENSE B ON A.MEMO_ID =B.RCM_MEMO_ID 
      WHERE A.CANCELLED =0 AND B.XN_TYPE='EXP'
    ) RCM ON RCM.MEMO_ID=A.MEMO_ID  
	WHERE A.CANCELLED =0
	AND ISNULL(LMP.REGISTERED_GST_DEALER,0) =0
	AND A.MEMO_DT BETWEEN @DFM_DT AND @DTODT
	AND RCM.MEMO_ID IS NULL
	GROUP BY LM.AC_NAME , A.AC_CODE,A.FIN_YEAR ,
	L.LOC_GST_NO,A.MEMO_DT  
	HAVING SUM(A.TOTAL_AMOUNT)>=5000
	
	
	
	 IF OBJECT_ID('TEMPDB..#TMPRCM1','U') IS NOT NULL
        DROP TABLE #TMPRCM1
    	
	SELECT  A.XN_TYPE,
	       '' AS MRR_NO,MEMO_DT AS MRR_DT, 
		   'LATER' AS MEMO_NO,
			CAST('' AS DATETIME) AS MEMO_DT,
			CAST('LATER' AS VARCHAR(22)) AS MEMO_ID,
			CAST(0 AS BIT) AS CANCELLED,
            A.XN_TYPE+A.AC_CODE +REPLACE(CONVERT(VARCHAR,A.MEMO_DT,105),'-','') +A.LOC_GST_NO  AS MRR_ID,
            0 AS FREIGHT,
            CAST('0000000000' AS VARCHAR(10)) FREIGHT_HSN_CODE,
            0 AS FREIGHT_GST_PERCENTAGE,
            0 AS FREIGHT_IGST_AMOUNT,0 AS FREIGHT_CGST_AMOUNT,0 AS FREIGHT_SGST_AMOUNT,
		    0 AS OTHER_CHARGES,
			0 AS OTHER_CHARGES_GST_PERCENTAGE,
			'0000000000' AS OTHER_CHARGES_HSN_CODE,
			0 AS OTHER_CHARGES_IGST_AMOUNT,
			0 AS OTHER_CHARGES_CGST_AMOUNT,
			0 AS OTHER_CHARGES_SGST_AMOUNT,
		    CAST(0 AS NUMERIC(12,2)) AS TOTAL_REVERSE_CHARGES  
			,A.FIN_YEAR
		    ,A.AC_CODE
			,A.AC_NAME,
			0 AS OH_TAX_METHOD,
			0 AS FREIGHT_TAXABLE_VALUE,
			0 AS OTHER_CHARGES_TAXABLE_VALUE,
			0 AS ROUND_OFF ,
			A.LOC_GST_NO,
			A.HSN_CODE , 
            A.TOTAL_AMOUNT 
	    INTO #TMPRCM1
		FROM #TMPRCM A
		ORDER BY A.XN_TYPE,A.AC_NAME
		
		
		  	
	SELECT  A.XN_TYPE,
	       '' AS MRR_NO,MEMO_DT AS MRR_DT, 
		   'LATER' AS MEMO_NO,
			CAST('' AS DATETIME) AS MEMO_DT,
			CAST('LATER' AS VARCHAR(22)) AS MEMO_ID,
			CAST(0 AS BIT) AS CANCELLED,
            A.MRR_ID,
            0 AS FREIGHT,
            CAST('0000000000' AS VARCHAR(10)) FREIGHT_HSN_CODE,
            0 AS FREIGHT_GST_PERCENTAGE,
            0 AS FREIGHT_IGST_AMOUNT,0 AS FREIGHT_CGST_AMOUNT,0 AS FREIGHT_SGST_AMOUNT,
		    0 AS OTHER_CHARGES,
			0 AS OTHER_CHARGES_GST_PERCENTAGE,
			'0000000000' AS OTHER_CHARGES_HSN_CODE,
			0 AS OTHER_CHARGES_IGST_AMOUNT,
			0 AS OTHER_CHARGES_CGST_AMOUNT,
			0 AS OTHER_CHARGES_SGST_AMOUNT,
		    CAST(0 AS NUMERIC(12,2)) AS TOTAL_REVERSE_CHARGES  
			,A.FIN_YEAR
		    ,A.AC_CODE
			,A.AC_NAME,
			0 AS OH_TAX_METHOD,
			0 AS FREIGHT_TAXABLE_VALUE,
			0 AS OTHER_CHARGES_TAXABLE_VALUE,
			0 AS ROUND_OFF 
		FROM #TMPRCM1 A
		ORDER BY A.XN_TYPE,A.AC_NAME
		
		
		IF OBJECT_ID('TEMPDB..#TMPRCD','U') IS NOT NULL
           DROP TABLE #TMPRCD
		
		SELECT  
		EX1.XN_TYPE+EX1.AC_CODE +REPLACE(CONVERT(VARCHAR,EX1.MEMO_DT,105),'-','') +EX1.LOC_GST_NO AS MRR_ID,
        CAST('LATER' AS VARCHAR(22)) AS MEMO_ID,
        HSN_CODE=B.HSN_CODE , 
        (B.QUANTITY) AS  QUANTITY,
        (B.XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST ,
        CAST(0 AS NUMERIC(6,2)) AS GST_PERCENTAGE ,
        CAST(0 AS NUMERIC(12,2))AS IGST_AMOUNT ,
        CAST(0 AS NUMERIC(12,2))AS SGST_AMOUNT ,
        CAST(0 AS NUMERIC(12,2))AS CGST_AMOUNT ,
        CAST(0 AS NUMERIC(12,2)) AS XN_VALUE_WITH_GST,
        CAST('LATER' AS VARCHAR(100)) AS ROW_ID,
        B.ROW_ID AS PID_ROW_ID,
        1 AS TAX_METHOD,
        A.FIN_YEAR ,
        EX1.AC_CODE ,EX1.MEMO_DT ,EX1.LOC_GST_NO 
        INTO #TMPRCD
		FROM SUPPLY_EXPENSE_XN_MST A (NOLOCK)
		JOIN SUPPLY_EXPENSE_XN_DET B (NOLOCK) ON A.MEMO_ID =B.MEMO_ID 
		JOIN LOCATION L ON L.DEPT_ID =a.location_Code
		JOIN #TMPRCM EX1 ON EX1.AC_CODE =A.AC_CODE AND EX1.MEMO_DT =A.MEMO_DT AND L.LOC_GST_NO =EX1.LOC_GST_NO 
		WHERE A.CANCELLED =0 AND EX1.XN_TYPE ='EXP'
		UNION ALL
		SELECT  A.XN_TYPE+A.AC_CODE +REPLACE(CONVERT(VARCHAR,A.MEMO_DT,105),'-','') +A.LOC_GST_NO AS MRR_ID,
        CAST('LATER' AS VARCHAR(22)) AS MEMO_ID,
        HSN_CODE=A.HSN_CODE , 
        1  AS  QUANTITY,
        (A.TOTAL_AMOUNT) AS XN_VALUE_WITHOUT_GST ,
        CAST(0 AS NUMERIC(6,2)) AS GST_PERCENTAGE ,
        CAST(0 AS NUMERIC(12,2))AS IGST_AMOUNT ,
        CAST(0 AS NUMERIC(12,2))AS SGST_AMOUNT ,
        CAST(0 AS NUMERIC(12,2))AS CGST_AMOUNT ,
        CAST(0 AS NUMERIC(12,2)) AS XN_VALUE_WITH_GST,
        CAST('LATER' AS VARCHAR(100)) AS ROW_ID,
        NEWID() AS PID_ROW_ID,
        1 AS TAX_METHOD,
        A.FIN_YEAR ,
        A.AC_CODE ,A.MEMO_DT ,A.LOC_GST_NO 
		FROM #TMPRCM A
		WHERE  A.XN_TYPE ='PTC'
		
		
		 IF OBJECT_ID('TEMPDB..#TMPHSN','U') IS NOT NULL
			   DROP TABLE #TMPHSN

			;WITH CTE AS
			(
			SELECT C.HSN_CODE,C.TAX_PERCENTAGE,C.RATE_CUTOFF,C.RATE_CUTOFF_TAX_PERCENTAGE,C.WEF,B.TAXABLE_ITEM,B.HSN_TYPE ,  
				  SR=ROW_NUMBER() OVER (PARTITION BY A.PID_ROW_ID ORDER BY WEF DESC)
			FROM #TMPRCD A
			JOIN HSN_MST B ON A.HSN_CODE =B.HSN_CODE 
			JOIN HSN_DET C ON B.HSN_CODE =C.HSN_CODE AND C.WEF  <=MEMO_DT 
			)

			SELECT * INTO #TMPHSN FROM CTE WHERE SR=1
	   
	   
	    UPDATE TMP SET GST_PERCENTAGE=CASE WHEN HM.RATE_CUTOFF<TMP.XN_VALUE_WITHOUT_GST/TMP.QUANTITY THEN HM.TAX_PERCENTAGE ELSE RATE_CUTOFF_TAX_PERCENTAGE END ,
				   IGST_AMOUNT=0, SGST_AMOUNT=0
		FROM #TMPRCD TMP
		JOIN #TMPHSN HM (NOLOCK) ON HM.HSN_CODE=TMP.HSN_CODE 
			
        UPDATE TMP SET XN_VALUE_WITH_GST=ROUND(XN_VALUE_WITHOUT_GST+(XN_VALUE_WITHOUT_GST*(CASE WHEN TAX_METHOD=2 THEN 0 ELSE ((ISNULL(TMP.GST_PERCENTAGE,0))/100) END)) ,2)	  
		FROM #TMPRCD TMP
				
        UPDATE TMP SET IGST_AMOUNT=0
                ,CGST_AMOUNT=ROUND(( XN_VALUE_WITHOUT_GST*(CASE WHEN TAX_METHOD=2 THEN (TMP.GST_PERCENTAGE/  
				 (100 + TMP.GST_PERCENTAGE)) ELSE (TMP.GST_PERCENTAGE/100) END) )/2,2)
				,SGST_AMOUNT=ROUND((XN_VALUE_WITHOUT_GST*(CASE WHEN TAX_METHOD=2 THEN (TMP.GST_PERCENTAGE/  
				 (100 + TMP.GST_PERCENTAGE)) ELSE (TMP.GST_PERCENTAGE/100) END) )/2,2)
        FROM #TMPRCD TMP
        
        
		
		 UPDATE TMP SET ROUND_OFF=ROUND(XN_VALUE_WITHOUT_GST ,0)-
         (XN_VALUE_WITHOUT_GST  ) 
        FROM #TMPRCM1 TMP
        JOIN
        (
          SELECT EX1.AC_CODE ,EX1.MEMO_DT ,EX1.LOC_GST_NO ,
                 SUM(ISNULL(XN_VALUE_WITHOUT_GST,0)) AS   XN_VALUE_WITHOUT_GST
          FROM #TMPRCD EX1
          GROUP BY EX1.AC_CODE ,EX1.MEMO_DT ,EX1.LOC_GST_NO 
        ) B ON TMP.AC_CODE=B.AC_CODE AND TMP.MEMO_DT=B.MEMO_DT AND TMP.LOC_GST_NO =B.LOC_GST_NO 	
        
        
        UPDATE TMP SET TOTAL_REVERSE_CHARGES=(XN_VALUE_WITHOUT_GST +ROUND_OFF) 
        FROM #TMPRCM1 TMP
        JOIN
        (
           SELECT EX1.AC_CODE ,EX1.MEMO_DT ,EX1.LOC_GST_NO ,
                 SUM(ISNULL(XN_VALUE_WITHOUT_GST,0)) AS   XN_VALUE_WITHOUT_GST
          FROM #TMPRCD EX1
          GROUP BY EX1.AC_CODE ,EX1.MEMO_DT ,EX1.LOC_GST_NO 
        ) B ON  TMP.AC_CODE=B.AC_CODE AND TMP.MEMO_DT=B.MEMO_DT AND TMP.LOC_GST_NO =B.LOC_GST_NO 	
    
		
		  SELECT '' AS MRR_NO,
               A.MRR_ID,
               CAST('LATER' AS VARCHAR(22)) AS MEMO_ID,
               A.HSN_CODE, 
               SUM(A.QUANTITY) AS  QUANTITY,
               SUM(A.XN_VALUE_WITHOUT_GST) AS XN_VALUE_WITHOUT_GST ,
               A.GST_PERCENTAGE ,
               CAST(SUM(IGST_AMOUNT) AS NUMERIC(12,2)) AS IGST_AMOUNT ,
               CAST(SUM(SGST_AMOUNT) AS NUMERIC(12,2)) AS SGST_AMOUNT ,
               CAST(SUM(CGST_AMOUNT) AS NUMERIC(12,2)) AS CGST_AMOUNT ,
               CAST(SUM(XN_VALUE_WITH_GST) AS NUMERIC(12,2)) AS XN_VALUE_WITH_GST,
               CAST('LATER' AS VARCHAR(100)) AS ROW_ID
               ,A.FIN_YEAR
               ,A.AC_CODE ,A.MEMO_DT ,A.LOC_GST_NO 
        FROM #TMPRCD A
        GROUP BY A.MRR_ID,A.HSN_CODE,A.GST_PERCENTAGE,A.FIN_YEAR ,A.AC_CODE ,A.MEMO_DT ,A.LOC_GST_NO 
		ORDER BY A.MRR_ID
		
		SELECT DISTINCT A.MEMO_ID, EX1.AC_NAME , A.AC_CODE,A.FIN_YEAR ,
	           L.LOC_GST_NO,A.MEMO_DT,
	            EX1.XN_TYPE+EX1.AC_CODE +REPLACE(CONVERT(VARCHAR,EX1.MEMO_DT,105),'-','') +EX1.LOC_GST_NO AS MRR_ID,
	            EX1.XN_TYPE
		FROM SUPPLY_EXPENSE_XN_MST A
		JOIN LOCATION L ON L.DEPT_ID =a.location_Code
		JOIN #TMPRCM EX1 ON EX1.AC_CODE =A.AC_CODE AND EX1.MEMO_DT =A.MEMO_DT AND L.LOC_GST_NO =EX1.LOC_GST_NO 
		WHERE EX1.XN_TYPE ='EXP'
		UNION ALL
		SELECT DISTINCT A.PEM_MEMO_ID, EX1.AC_NAME , B.AC_CODE,A.FIN_YEAR ,
	           L.LOC_GST_NO,A.PEM_MEMO_DT,
	            EX1.XN_TYPE+EX1.AC_CODE +REPLACE(CONVERT(VARCHAR,EX1.MEMO_DT,105),'-','') +EX1.LOC_GST_NO AS MRR_ID,
	            EX1.XN_TYPE
		FROM PEM01106  A
		JOIN PED01106 B ON A.PEM_MEMO_ID =B.PEM_MEMO_ID 
		JOIN LOCATION L ON L.DEPT_ID =a.location_Code
		JOIN #TMPRCM EX1 ON EX1.AC_CODE =B.AC_CODE AND EX1.MEMO_DT =A.PEM_MEMO_DT AND L.LOC_GST_NO =EX1.LOC_GST_NO 
		WHERE EX1.XN_TYPE ='PTC'
		
		
     END
     
     
     
     
END
END_PROC:
END
