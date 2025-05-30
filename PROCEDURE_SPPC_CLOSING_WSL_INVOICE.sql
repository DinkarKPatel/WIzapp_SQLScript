CREATE PROCEDURE DBO.SPPC_CLOSING_WSL_INVOICE    
 (    
 @NQUERYID INT    
,@CAC_CODE VARCHAR(10)=''    
,@CBILL_NO VARCHAR(100) =''    
,@CMEMO_ID VARCHAR(100) ='' 
,@BO_DET_ROW_ID VARCHAR(100)=''
,@CFIN_YEAR VARCHAR(5)=''   
 )    
AS    
 BEGIN  
 --DROP TABLE TMP1
 --  SELECT @NQUERYID AS A
 --  INTO TMP1
   DECLARE @DSSMS NVARCHAR(MAX),@cHEAD_CODE VARCHAR(MAX),@cHEAD_CODE1 VARCHAR(MAX) 
   
   IF @NQUERYID IN (4,5)    
      BEGIN    
		IF OBJECT_ID('TEMPDB..#MAXJOB_DETAILS') IS NOT NULL     
		 DROP TABLE #MAXJOB_DETAILS    
		
        CREATE TABLE #MAXJOB_DETAILS    
		(    
		ORDER_ID VARCHAR(50)    
		,ROW_ID VARCHAR(100)    
		,JOB_CODE VARCHAR(50)    
		,JOB_ORDER INT    
		,BILL_NO  VARCHAR(100)    
        ,ARTICLE_CODE VARCHAR(100)
        ,RATE NUMERIC(10,2)
        ,CURRENCY_CODE VARCHAR(10)
		) 
		   
	  ---INSERT DETAILS WITH MAX JOB_ORDER---------------    
	    
	 SET @DSSMS=N' SELECT A.ORDER_ID ,A.ROW_ID, MAX(C.JOB_ORDER) AS [JOB_ORDER],B.BILL_NO 
            ,ARTICLE_CODE,RATE,A.CURRENCY_CODE       
			FROM PPC_BUYER_ORDER_DET A    
	  JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID =B.ORDER_ID     
	  JOIN PPC_BO_ART_JOBS C ON A.ROW_ID=C.REF_ROW_ID     
	  WHERE CANCELLED=0     
	  AND B.BILL_NO  '+ @CBILL_NO + '
	  GROUP BY A.ORDER_ID ,A.ROW_ID,B.BILL_NO ,ARTICLE_CODE,RATE ,A.CURRENCY_CODE    '
	  PRINT @DSSMS
	   INSERT INTO #MAXJOB_DETAILS(ORDER_ID,ROW_ID,JOB_ORDER,BILL_NO,ARTICLE_CODE,RATE,CURRENCY_CODE)
	    EXEC SP_EXECUTESQL  @DSSMS 
	  ---------UPDATE MAX JOB CODE-------------------    
	  UPDATE #MAXJOB_DETAILS SET JOB_CODE = (SELECT A.JOB_CODE FROM DBO.PPC_BO_ART_JOBS A WITH(NOLOCK)    
				  WHERE A.REF_ROW_ID =#MAXJOB_DETAILS.ROW_ID     
				  AND A.JOB_ORDER=#MAXJOB_DETAILS.JOB_ORDER    
				  )    
	                                                
	  --SELECT FIRST GRID DATA------------    
	  IF OBJECT_ID('TEMPDB..#TEMPTABLE') IS NOT NULL    
		 DROP TABLE #TEMPTABLE    
	  SELECT     
		  ART_ROW_ID=ART.ARTICLE_NO+SG.SIZEGROUP_NAME+P1.PARA1_NAME ,    
		  A.AC_CODE,LM.AC_NAME ,    
		  B.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,    
		  B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,    
		  B.PARA1_CODE,P1.PARA1_NAME AS COLOR,    
		  B.PARA3_CODE,P3.PARA3_NAME BUYER_STYLE_NO,    
		  SKU.PARA2_CODE,P2.PARA2_NAME SIZE,    
		  SKU.PRODUCT_CODE ,    
		  1 AS QUANTITY,    
		  PMT.QUANTITY_IN_STOCK,    
		  RATE AS RATE, 
		  TMP.CURRENCY_CODE,   
		  CAST(0 AS NUMERIC(10,2)) AS AMOUNT     
		 ,TMP.JOB_ORDER,TMP.JOB_CODE,TMP.BILL_NO    
		,B.BO_DET_ROW_ID,TMP.ROW_ID    
		INTO #TEMPTABLE    
		FROM PPC_FGBCG_MST A    
		JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID ---BO_DET_ROW_ID    
		JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID     
		JOIN PPC_FG_PMT PMT ON PMT.PRODUCT_CODE=SKU.PRODUCT_CODE     
		JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE     
		JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE     
		JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE     
		JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE     
		JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE     
		JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE     
		JOIN #MAXJOB_DETAILS TMP ON TMP.ROW_ID = B.BO_DET_ROW_ID  
		JOIN    
	   (    
	   SELECT B.AC_CODE ,A.PRODUCT_CODE ,B.JOB_CODE ,A.QUANTITY      
	   FROM PPC_AGENCY_REC_FG_DET A    
	   JOIN PPC_AGENCY_REC_FG_MST B ON A.MEMO_ID =B.MEMO_ID     
	   WHERE B.CANCELLED =0 AND ISNULL(MEMO_TYPE,0)=1    
	   )REC ON REC.PRODUCT_CODE =SKU.PRODUCT_CODE AND REC.JOB_CODE=TMP.JOB_CODE    
	  WHERE --PMT.QUANTITY_IN_STOCK=1    
	   SKU.PARA2_CODE<>'0000000'    
    END    
           
  --SET GOT OT THROUGH @NQUERYID PASSED BY PARAMATERS    
   IF @NQUERYID = 1          
    GOTO LBLGETCUSTOMERLIST      
   ELSE IF @NQUERYID = 2    
    GOTO LBLBILL_NO    
   ELSE IF @NQUERYID = 3    
    GOTO LBLINVMST_FILTER    
   ELSE IF @NQUERYID = 4    
    GOTO LBLDET    
   ELSE IF @NQUERYID = 5    
    GOTO LBLPARA2DET    
   ELSE IF @NQUERYID = 7    
    GOTO LBLBARCODEPRINT_CROSSTAB    
   ELSE IF @NQUERYID = 8 
    GOTO LBLAGENCYSUMMARY 
 LBLGETCUSTOMERLIST:    
	
	SET @cHEAD_CODE  =  DBO.FN_ACT_TRAVTREE ('0000000018') ----ADD VARIABLE BY GAURI ON 17/4/2019
	SET @cHEAD_CODE1 = DBO.FN_ACT_TRAVTREE ('0000000001')  ----ADD VARIABLE BY GAURI ON 17/4/2019
      
	SELECT  A.AC_CODE, A.HEAD_CODE, A.AC_NAME, ISNULL(A.CREDIT_DAYS, 0) AS CREDIT_DAYS, ISNULL(A.DISCOUNT_PERCENTAGE, 0) AS DISCOUNT_PERCENTAGE,         
		A.CITY, A.ADDRESS0 + ' ' + A.ADDRESS1 + ' ' + A.ADDRESS2 + ' ' + A.AREA_NAME + ' ' + A.CITY + ' ' + A.STATE + ' ' + A.MOBILE + ' ' AS SUPP_ADDRESS,         
		A.AC_NAME AS REPCOLNAME, A.DEFAULT_RATE_TYPE, A.DISCOUNT_PERCENTAGE            
		FROM LMV01106 A (NOLOCK)                   
		WHERE ( CHARINDEX ( HEAD_CODE, @cHEAD_CODE)>0    ----REPLACE VARIABLE FROM FUNCTION BY GAURI ON 17/4/2019     
		OR CHARINDEX ( HEAD_CODE,@cHEAD_CODE1)>0         ----REPLACE VARIABLE FROM FUNCTION BY GAURI ON 17/4/2019
		OR ALLOW_CREDITOR_DEBTOR = 1 )                   
		AND INACTIVE = 0 AND A.AC_CODE <> '0000000000' AND ISNULL(A.AC_NAME,'')<>''        
  --AND A.AC_NAME LIKE '%'+ @VNAME +'%'      
     
GOTO PROC_END;    
    
 --SELECT LIST OF  ORDER NO    
 LBLBILL_NO:    
   SELECT BILL_NO AS ORDER_NO         
       FROM PPC_BUYER_ORDER_MST A        
       WHERE CANCELLED=0        
       AND (@CAC_CODE='' OR A.AC_CODE=@CAC_CODE)        
       GROUP BY BILL_NO    
 GOTO PROC_END;    
    
  LBLDET:    
	SELECT     
		CAST('LATER' AS VARCHAR(50)) AS MEMO_ID,    
		ROW_ID=CAST('LATER' AS VARCHAR(40))+CAST(NEWID() AS VARCHAR(100))            
		,A.AC_CODE,A.AC_NAME ,    
		A.BILL_NO,    
		A.ARTICLE_CODE,A.ARTICLE_NO,A.PARA1_CODE, A.COLOR AS [PARA1_NAME],A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,    
		A.PARA3_CODE,A.BUYER_STYLE_NO AS [PARA3_NAME]--,JOB_ORDER, --,A.PARA2_CODE,A.SIZE,    
		 ,A.BO_DET_ROW_ID    
		,SUM(A.QUANTITY) AS [ALLOTED_QTY],     
		SUM(A.QUANTITY) AS [SELECT_QUANTITY],     
		RATE AS [RATE],    
		0 AS [AMOUNT],    
		0 AS [QUANTITY],
		'' AS [MANUAL_INVOICE_NO]  ,
		ISNULL(A.CURRENCY_CODE,'') AS CURRENCY_CODE ,
		ISNULL(CM.CURRENCY_NAME,'') AS CURRENCY_NAME,
		BO.SHIPPING_MODE ,
		BO.SHIPPING_NAME 
		
	FROM #TEMPTABLE A  
	JOIN 
	(
	   SELECT A.ROW_ID ,A.SHIPPING_MODE,C.SHIPPING_NAME  
	   FROM PPC_BUYER_ORDER_DET A
	   JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID =B.ORDER_ID 
	   JOIN PPC_SHIPPING_DETAILS C ON A.SHIPPING_MODE =C.SHIPPING_MODE 
	   WHERE B.CANCELLED =0
	)  BO ON BO.ROW_ID =A.BO_DET_ROW_ID    
	LEFT OUTER JOIN PPC_CURRENCY_MST CM ON CM.CURRENCY_CODE=A.CURRENCY_CODE
	GROUP BY A.AC_CODE,A.AC_NAME ,    
		A.BILL_NO,    
		A.ARTICLE_CODE,A.ARTICLE_NO,A.PARA1_CODE, A.COLOR ,A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,    
		A.PARA3_CODE,A.BUYER_STYLE_NO,A.BO_DET_ROW_ID,RATE ,A.CURRENCY_CODE,CM.CURRENCY_NAME,BO.SHIPPING_MODE ,
		BO.SHIPPING_NAME      
       
 GOTO PROC_END;    
    
 LBLPARA2DET:  
 
  --GET VALUE FOR PPC_IND01106 FOR CALCULATE ISSUE QTY AND PENDING QTY
  IF OBJECT_ID('TEMPDB..#CALCULATE_ISSUE_PENDING_QTY') IS NOT NULL
   DROP TABLE #CALCULATE_ISSUE_PENDING_QTY

	CREATE TABLE #CALCULATE_ISSUE_PENDING_QTY
	(
	 BILL_NO VARCHAR(100)
	,ARTICLE_CODE VARCHAR(100)
	,PRODUCT_CODE VARCHAR(100)
	,PARA2_CODE VARCHAR(100)
	,ISSUED_QUANTITY INT
	,ROW_ID VARCHAR(100)
	)
	
  SET @DSSMS=N'SELECT D.BILL_NO,D.ARTICLE_CODE,D.PRODUCT_CODE,D.PARA2_CODE,D.QUANTITY,D.ROW_ID 
  FROM PPC_IND01106 D WITH(NOLOCK) 
  JOIN PPC_INM01106 M WITH(NOLOCK) ON D.INV_ID = M.INV_ID
  WHERE D.BILL_NO ' +@CBILL_NO+ ' AND M.CANCELLED = 0'
  PRINT @DSSMS
  INSERT INTO #CALCULATE_ISSUE_PENDING_QTY (BILL_NO,ARTICLE_CODE,PRODUCT_CODE,PARA2_CODE,ISSUED_QUANTITY,ROW_ID)
  EXEC SP_EXECUTESQL @DSSMS
  
  
  SELECT DISTINCT     
  CAST('LATER' AS VARCHAR(50)) AS MEMO_ID,T.ROW_ID    
        ,T.PARA2_CODE,T.SIZE AS [PARA2_NAME],T.BO_DET_ROW_ID    
  ,SUM(CAST(T.QUANTITY AS NUMERIC(10,0))) AS [ALLOTED_QTY] 
  ,CAST(0 AS NUMERIC(10,0)) AS [SELECT_QUANTITY]    
  , SUM(ISNULL(ISSUED_QUANTITY,0)) AS [ISSUED_QTY]
  ,(SUM(CAST(T.QUANTITY AS NUMERIC(10,0))) - SUM(ISNULL(ISSUED_QUANTITY,0))) AS [PENDING_QTY]
 FROM #TEMPTABLE  T
LEFT JOIN #CALCULATE_ISSUE_PENDING_QTY C ON T.PRODUCT_CODE = C.PRODUCT_CODE
  GROUP BY T.ROW_ID,T.PARA2_CODE,T.SIZE,    
 T.BO_DET_ROW_ID  
     
GOTO PROC_END;    
    
LBLINVMST_FILTER:    
 
 SELECT DISTINCT  REPLACE(CONVERT(VARCHAR(11),M.INV_DT,106),' ','-') AS INV_DT , M.INV_ID AS [MEMO_ID],M.INV_NO AS [MEMO_NO],
 BILL_NO=(STUFF(( SELECT DISTINCT ', '+BILL_NO FROM PPC_IND01106 D  
                  WHERE M.INV_ID =D.INV_ID  FOR XML PATH('')),1,1,'')) ,
 L.AC_CODE,L.AC_NAME    
 ,CASE WHEN M.CANCELLED =0 THEN 'NO' ELSE 'YES' END AS CANCELLED   ,M.MANUAL_INV_NO,
 M.REMARKS,M.INV_DT AS DT
 FROM DBO.PPC_INM01106 M WITH(NOLOCK)    
-- JOIN DBO.PPC_IND01106 D WITH(NOLOCK) ON M.INV_ID= D.INV_ID    
 JOIN DBO.LM01106 L WITH(NOLOCK) ON L.AC_CODE = M.AC_CODE    
 WHERE (@CAC_CODE='' OR M.AC_CODE=@CAC_CODE) 
 AND (@CFIN_YEAR='' OR M.FIN_YEAR=@CFIN_YEAR) 
 ORDER BY M.INV_DT DESC ,M.INV_NO DESC
 GOTO PROC_END;    
    
LBLBARCODEPRINT_CROSSTAB:    
  --DECLARE LOCAL VARIABLE----------
  DECLARE @SELECT_QTY INT,@RATE INT,@AMOUNT NUMERIC(10,2)    
               ,@SUBTOTAL NUMERIC(10,2)    
               ,@DISCOUNT_PERCENTAGE NUMERIC(10,2)    
               ,@DISCOUNT_AMOUNT NUMERIC(10,2)    
               ,@OTHER_CHARGE NUMERIC(10,2)   
               ,@QUANTITY INT 
               ,@ROUND_OFF NUMERIC(10,2)
               ,@INV_NO VARCHAR(50) 
  
  ---SET VALUE INTO LOCAL VARIABLE  FROM MASTER TABLE PPC_INM01106
  SELECT @SUBTOTAL=SUBTOTAL,@DISCOUNT_PERCENTAGE = DISCOUNT_PERCENTAGE     
     ,@DISCOUNT_AMOUNT=DISCOUNT_AMOUNT    
     ,@OTHER_CHARGE = OTHER_CHARGE, @ROUND_OFF=  ROUND_OFF  
     ,@INV_NO = INV_NO
  FROM PPC_INM01106 WITH(NOLOCK) WHERE INV_ID = @CMEMO_ID    
           
  ---CREATE TEMP TABLE FOR SELECT MAX JOB DETAIL----
  IF OBJECT_ID('TEMPDB..#MAXJOB_DETAILS1') IS NOT NULL     
     DROP TABLE #MAXJOB_DETAILS1    
  CREATE TABLE #MAXJOB_DETAILS1    
  (    
    ORDER_ID VARCHAR(50)    
   ,ROW_ID VARCHAR(100)    
   ,JOB_CODE VARCHAR(50)    
   ,JOB_ORDER INT    
   ,BILL_NO  VARCHAR(100)  
   ,CURRENCY_CODE VARCHAR(10)  
  )    
  ---INSERT DETAILS WITH MAX JOB_ORDER---------------    
   SET @DSSMS=N' SELECT A.ORDER_ID ,A.ROW_ID, MAX(C.JOB_ORDER) AS [JOB_ORDER],B.BILL_NO ,A.CURRENCY_CODE    
        FROM PPC_BUYER_ORDER_DET A    
  JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID =B.ORDER_ID     
  JOIN PPC_BO_ART_JOBS C ON A.ROW_ID=C.REF_ROW_ID     
  WHERE CANCELLED=0     
  AND B.BILL_NO '+ @CBILL_NO   + 
  ' GROUP BY A.ORDER_ID ,A.ROW_ID,B.BILL_NO,A.CURRENCY_CODE  '
  
  PRINT @DSSMS
  INSERT INTO #MAXJOB_DETAILS1(ORDER_ID,ROW_ID,JOB_ORDER,BILL_NO,CURRENCY_CODE)  
  EXEC SP_EXECUTESQL  @DSSMS 
     
  ---------UPDATE MAX JOB CODE-------------------    
  UPDATE #MAXJOB_DETAILS1 SET JOB_CODE = (SELECT A.JOB_CODE FROM DBO.PPC_BO_ART_JOBS A WITH(NOLOCK)    
              WHERE A.REF_ROW_ID =#MAXJOB_DETAILS1.ROW_ID     
             AND A.JOB_ORDER=#MAXJOB_DETAILS1.JOB_ORDER    
              )    
                                                                          
            
  --SELECT FIRST GRID DATA------------    
  IF OBJECT_ID('TEMPDB..#TEMPTABLE_DETAILS') IS NOT NULL    
     DROP TABLE #TEMPTABLE_DETAILS    
  SELECT     
		ART_ROW_ID=ART.ARTICLE_NO+SG.SIZEGROUP_NAME+P1.PARA1_NAME ,    
		A.AC_CODE,LM.AC_NAME ,    
		B.ARTICLE_CODE,ART.ARTICLE_NO,ART.ARTICLE_NAME,    
		B.SIZEGROUP_CODE,SG.SIZEGROUP_NAME ,    
		B.PARA1_CODE,P1.PARA1_NAME AS COLOR,    
		B.PARA3_CODE,P3.PARA3_NAME BUYER_STYLE_NO,    
		SKU.PARA2_CODE,P2.PARA2_NAME SIZE,    
		SKU.PRODUCT_CODE ,    
		PINM.QUANTITY AS QUANTITY,    
		CINM.QUANTITY AS SELECT_QTY,    
		PMT.QUANTITY_IN_STOCK,    
		CINM.RATE AS RATE,    
		ISNULL(CINM.QUANTITY,0)* ISNULL(CINM.RATE,0) AS AMOUNT     
		,TMP.JOB_ORDER,TMP.JOB_CODE,TMP.BILL_NO    
		,B.BO_DET_ROW_ID,TMP.ROW_ID ,
        CINM.MANUAL_INVOICE_NO ,
        1 AS [TOTAL_STOCK],
        TMP.CURRENCY_CODE   
    INTO #TEMPTABLE_DETAILS    
    FROM PPC_FGBCG_MST A    
    JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID ---BO_DET_ROW_ID    
    JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID     
    JOIN PPC_FG_PMT PMT ON PMT.PRODUCT_CODE=SKU.PRODUCT_CODE     
    JOIN ARTICLE ART ON ART.ARTICLE_CODE =SKU.ARTICLE_CODE     
    JOIN PARA1 P1 ON P1.PARA1_CODE =SKU.PARA1_CODE     
    JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE     
    JOIN PARA3 P3 ON P3.PARA3_CODE =SKU.PARA3_CODE     
    JOIN PPC_SIZEGROUP SG ON SG.SIZEGROUP_CODE =SKU.SIZEGROUP_CODE     
    JOIN LM01106 LM ON LM.AC_CODE =A.AC_CODE     
    JOIN #MAXJOB_DETAILS1 TMP ON TMP.ROW_ID = B.BO_DET_ROW_ID    
    JOIN    
   (    
   SELECT B.AC_CODE ,A.PRODUCT_CODE ,B.JOB_CODE ,A.QUANTITY      
   FROM PPC_AGENCY_REC_FG_DET A    
   JOIN PPC_AGENCY_REC_FG_MST B ON A.MEMO_ID =B.MEMO_ID     
   WHERE B.CANCELLED =0 AND ISNULL(MEMO_TYPE,0)=1    
   )REC ON REC.PRODUCT_CODE =SKU.PRODUCT_CODE AND REC.JOB_CODE=TMP.JOB_CODE    
   LEFT OUTER JOIN    
    (    
     SELECT A.PRODUCT_CODE,A.QUANTITY,A.MANUAL_INVOICE_NO ,ISNULL(A.RATE,0) AS [RATE]   
     FROM PPC_IND01106 A    
     JOIN PPC_INM01106 B ON A.INV_ID=B.INV_ID    
     WHERE B.CANCELLED=0    
     AND A.INV_ID= @CMEMO_ID    
     )CINM ON CINM.PRODUCT_CODE=PMT.PRODUCT_CODE    
   LEFT OUTER JOIN    
    (    
     SELECT A.PRODUCT_CODE,A.QUANTITY     
     FROM PPC_IND01106 A    
     JOIN PPC_INM01106 B ON A.INV_ID=B.INV_ID    
     WHERE B.CANCELLED=0    
     AND A.INV_ID<= @CMEMO_ID    
     )PINM ON PINM.PRODUCT_CODE=PMT.PRODUCT_CODE    
   WHERE A.CANCELLED=0 --AND ISNULL(PINM.QUANTITY ,0) <> 0    
    
    
      --SELECT DATA FOR MASTER TABLE PPC_INM01106 

	IF OBJECT_ID('TEMPDB..#STOCK_DETAILS') IS NOT NULL
	  DROP TABLE #STOCK_DETAILS

	SELECT DISTINCT     
	@CMEMO_ID AS MEMO_ID,TEM.ROW_ID    
	,TEM.PARA2_CODE,TEM.SIZE AS [PARA2_NAME],TEM.BO_DET_ROW_ID    
	,SUM(CAST(TEM.TOTAL_STOCK  AS NUMERIC(10,0))) AS [ALLOTED_QTY]    
	,SUM(CAST(ISNULL(TEM .SELECT_QTY,0) AS NUMERIC(10,0))) AS [SELECT_QUANTITY]
	,CAST(0 AS NUMERIC(10,0)) AS ISSUED_QTY   
	,CAST(0 AS NUMERIC(10,0)) AS PENDING_QTY
	,TEM.CURRENCY_CODE 
	INTO #STOCK_DETAILS
	FROM #TEMPTABLE_DETAILS TEM    
	-- WHERE ISNULL(TEM .SELECT_QTY,0) <> 0
	GROUP BY TEM.ROW_ID,TEM.PARA2_CODE,TEM.SIZE,    
	TEM.BO_DET_ROW_ID,TEM.CURRENCY_CODE    
    
    
    --SELECT * FROM #TEMPTABLE_DETAILS
    
    --SELECT * FROM #STOCK_DETAILS
    
    ---UPDATE ISSUE QUANTITY--------------
	UPDATE S SET S.ISSUED_QTY = ISNULL(SPD.SHIPED_QUANTITY,0)
	FROM #STOCK_DETAILS S 
	JOIN
	(
	SELECT T.BO_DET_ROW_ID, SUM(D.QUANTITY) AS [SHIPED_QUANTITY],T.SIZE FROM PPC_INM01106 M WITH(NOLOCK)
	JOIN PPC_IND01106 D WITH(NOLOCK) ON M.INV_ID =D.INV_ID
	LEFT JOIN #TEMPTABLE_DETAILS T ON D.PRODUCT_CODE = T.PRODUCT_CODE
	WHERE RIGHT(M.INV_NO,LEN(M.INV_NO)-2) < RIGHT(@INV_NO,LEN(@INV_NO)-2)
	AND M.CANCELLED = 0
	GROUP BY T.SIZE,T.BO_DET_ROW_ID 
	) SPD ON S.PARA2_NAME = SPD.SIZE AND S.BO_DET_ROW_ID=SPD.BO_DET_ROW_ID
   
    ---UPDATE PENDING QUANTITY-------------
    UPDATE #STOCK_DETAILS SET PENDING_QTY=ISNULL(ALLOTED_QTY,0) - ISNULL(ISSUED_QTY,0)

      
    ---SELECT MASTER DETAILS FOR MASTER LIST---------------
	SELECT     
		@CMEMO_ID AS MEMO_ID,    
		ROW_ID=CAST('LATER' AS VARCHAR(40))+CAST(NEWID() AS VARCHAR(100))            
		,A.AC_CODE,A.AC_NAME ,    
		A.BILL_NO,    
		A.ARTICLE_CODE,A.ARTICLE_NO,A.PARA1_CODE, A.COLOR AS [PARA1_NAME],A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,    
		A.PARA3_CODE,A.BUYER_STYLE_NO AS [PARA3_NAME]--,JOB_ORDER, --,A.PARA2_CODE,A.SIZE,    
		,A.BO_DET_ROW_ID    
		,SUM(A.QUANTITY) AS [ALLOTED_QTY]    
		,SUM(A.SELECT_QTY) AS [SELECT_QUANTITY]    
		, SUM(A.SELECT_QTY) AS  [QUANTITY]
		,A.RATE AS [RATE],SUM(A.AMOUNT) AS [AMOUNT] 
		,@SUBTOTAL AS [SUBTOTAL],@DISCOUNT_PERCENTAGE AS [DISCOUNT_PERCENTAGE]    
		,@DISCOUNT_AMOUNT AS [DISCOUNT_AMOUNT]    
		,@OTHER_CHARGE AS [OTHER_CHARGE]  
		,@ROUND_OFF AS [ROUND_OFF]  
		,((ISNULL(@SUBTOTAL,0)+ISNULL(@OTHER_CHARGE,0)) -(ISNULL(@ROUND_OFF,0)+(ISNULL(@DISCOUNT_AMOUNT,0)))) AS [NET_AMOUNT]
		,ISNULL(MANUAL_INVOICE_NO,'') AS MANUAL_INVOICE_NO
		,ISNULL(A.CURRENCY_CODE,'') AS CURRENCY_CODE
		,ISNULL(CM.CURRENCY_NAME,'') AS CURRENCY_NAME,
		CAST('' AS VARCHAR(100)) AS IMAGE_1,
		BO.SHIPPING_MODE ,
		BO.SHIPPING_NAME 
	FROM #TEMPTABLE_DETAILS A   
	JOIN 
	(
	   SELECT A.ROW_ID ,A.SHIPPING_MODE,C.SHIPPING_NAME  
	   FROM PPC_BUYER_ORDER_DET A
	   JOIN PPC_BUYER_ORDER_MST B ON A.ORDER_ID =B.ORDER_ID 
	   JOIN PPC_SHIPPING_DETAILS C ON A.SHIPPING_MODE =C.SHIPPING_MODE 
	   WHERE B.CANCELLED =0
	)  BO ON BO.ROW_ID =A.BO_DET_ROW_ID   
	LEFT OUTER JOIN PPC_CURRENCY_MST CM ON CM.CURRENCY_CODE=A.CURRENCY_CODE
	WHERE ISNULL(SELECT_QTY,0) <> 0     
	GROUP BY A.AC_CODE,A.AC_NAME ,    
		A.BILL_NO,    
		A.ARTICLE_CODE,A.ARTICLE_NO,A.PARA1_CODE, A.COLOR ,A.SIZEGROUP_CODE,A.SIZEGROUP_NAME ,    
		A.PARA3_CODE,A.BUYER_STYLE_NO,A.BO_DET_ROW_ID ,
		A.RATE,A.MANUAL_INVOICE_NO  ,ISNULL(A.CURRENCY_CODE,''),
		ISNULL(CM.CURRENCY_NAME,'')  ,BO.SHIPPING_MODE ,
		BO.SHIPPING_NAME 
               
    ---SELECT DATA FOR DISPLAY DETAILS---------------
    SELECT * FROM #STOCK_DETAILS
    
    GOTO PROC_END

    LBLAGENCYSUMMARY:
   
           --DROP TABLE TMPPRD
        --   SELECT * INTO TMPPRD FROM #TMPPRODUCT
     DECLARE @DTSQL NVARCHAR(MAX)
     
     IF OBJECT_ID('TEMPDB..#TEMPINV') IS NOT NULL    
     DROP TABLE #TEMPINV    
  SELECT PINM.MANUAL_INV_NO,PINM.INV_NO,PINM.INV_DT,
         SKU.PARA2_CODE, 
         P2.PARA2_NAME ,
         B.BO_DET_ROW_ID,
         PINM.AC_CODE,
         PINM.PRODUCT_CODE ,
         PINM.QUANTITY   
    INTO #TEMPINV    
    FROM PPC_FGBCG_MST A    
    JOIN PPC_FGBCG_DET B ON A.MEMO_ID =B.MEMO_ID ---BO_DET_ROW_ID    
    JOIN PPC_FG_SKU SKU ON SKU.PPC_FGBCG_DET_ROW_ID=B.ROW_ID     
    JOIN PPC_FG_PMT PMT ON PMT.PRODUCT_CODE=SKU.PRODUCT_CODE     
    JOIN    
    (    
     SELECT B.AC_CODE , B.MANUAL_INV_NO,INV_NO,INV_DT,A.PRODUCT_CODE ,
           A.QUANTITY AS QUANTITY
     FROM PPC_IND01106 A    
     JOIN PPC_INM01106 B ON A.INV_ID=B.INV_ID    
     WHERE B.CANCELLED=0    
     AND (@CMEMO_ID='' OR A.INV_ID<= @CMEMO_ID    )
     )PINM ON PINM.PRODUCT_CODE=PMT.PRODUCT_CODE 
     JOIN PARA2 P2 ON P2.PARA2_CODE =SKU.PARA2_CODE 
      
    WHERE A.CANCELLED=0 --AND ISNULL(PINM.QUANTITY ,0) <> 0    
    AND B.BO_DET_ROW_ID =@BO_DET_ROW_ID 
     
     DECLARE @CCOLNAME VARCHAR(MAX),@CTCOLNAME VARCHAR(MAX)
     SELECT @CCOLNAME=ISNULL(@CCOLNAME,'')+','+QUOTENAME( PARA2_NAME)
     FROM #TEMPINV A
     WHERE A.BO_DET_ROW_ID =@BO_DET_ROW_ID
     GROUP BY PARA2_NAME
     SET @CCOLNAME=SUBSTRING(@CCOLNAME,2,LEN(@CCOLNAME))
     
     SELECT @CTCOLNAME=ISNULL(@CTCOLNAME,'')+'+ ISNULL('+QUOTENAME( PARA2_NAME)+',0)' 
     FROM #TEMPINV A
     WHERE A.BO_DET_ROW_ID =@BO_DET_ROW_ID 
     GROUP BY PARA2_NAME
     SET @CTCOLNAME=SUBSTRING(@CTCOLNAME,2,LEN(@CTCOLNAME))+' AS TOTAL'
     
   
 
     IF OBJECT_ID('TEMPDB..#TMPAGENCY','U') IS NOT NULL
        DROP TABLE #TMPAGENCY
        
     SELECT B.AC_NAME AS BUYER_NAME,A.INV_NO, 
            REPLACE(CONVERT(VARCHAR(11),A.INV_DT,106),' ','-') AS INV_DT ,
            A.PARA2_NAME ,
            SUM([QUANTITY] ) AS ISSUE_QTY ,
            MANUAL_INV_NO
     INTO #TMPAGENCY
     FROM #TEMPINV A
     JOIN LM01106 B ON A.AC_CODE  =B.AC_CODE
     WHERE A.BO_DET_ROW_ID =@BO_DET_ROW_ID  
     GROUP BY B.AC_NAME ,MANUAL_INV_NO,
      A.INV_NO,A.PARA2_NAME,REPLACE(CONVERT(VARCHAR(11),A.INV_DT,106),' ','-')
     
    
   IF ISNULL(@CCOLNAME,'')<>''
   BEGIN
     SET @DTSQL=N' SELECT BUYER_NAME AS [BUYER NAME],MANUAL_INV_NO AS INVNO,INV_DT AS INVDT ,'+@CCOLNAME+' , '+@CTCOLNAME+'
    FROM #TMPAGENCY A
    PIVOT (SUM(ISSUE_QTY) FOR PARA2_NAME IN('+@CCOLNAME+')) AS P1
    '    
   END
   ELSE
   BEGIN
       SET @DTSQL=N' SELECT BUYER_NAME AS [BUYER NAME],MANUAL_INV_NO AS INVNO,INV_DT AS INVDT 
       FROM #TMPAGENCY A '
 
   END
   PRINT @DTSQL  
   EXEC SP_EXECUTESQL @DTSQL
    
    
   
             
    
 PROC_END:    
         
END
