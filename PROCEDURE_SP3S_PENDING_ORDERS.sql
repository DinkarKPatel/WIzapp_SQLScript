CREATE PROCEDURE SP3S_PENDING_ORDERS
(
	 @BPENDING_PO BIT=0  /*RETURN BUYER ORDER WHOSE PO IS PENDING*/
	,@BPENDING_PUR BIT=0 /*RETURN BUYER ORDER WHOSE PO IS RAISED BUT MATERIAL NOT RECEIVED*/
	,@BPENDING_BILL BIT=0/*RETURN BUYER ORDER WHOSE PUR IS RAISED BUT MATERIAL NOT RECEIVED*/
	,@BSUMMARY BIT=1 /*1: RETURNS SUMMARY AND 0: RETURNS DETAILS*/
)
--WITH ENCRYPTION
AS	
BEGIN   
    IF @BPENDING_PO=1
    BEGIN
        IF OBJECT_ID('TEMPDB..#ORDER_RAISED','U') IS NOT NULL
				DROP TABLE #ORDER_RAISED
				
			SELECT A.ORDER_ID
			INTO #ORDER_RAISED
			FROM WSL_ORDER_MST A(NOLOCK)
			JOIN WSL_ORDER_DET B(NOLOCK) ON A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0 
			LEFT JOIN 
			(
				SELECT POD.PRODUCT_CODE,POD.QUANTITY,POD.MRP
				FROM POM01106 POM(NOLOCK)
				JOIN POD01106 POD(NOLOCK) ON POM.PO_ID=POD.PO_ID
				WHERE ISNULL(POD.PRODUCT_CODE,'')<>'' AND POM.CANCELLED=0
			)POD ON B.PRODUCT_CODE=POD.PRODUCT_CODE
			WHERE A.CANCELLED=0 AND A.APPROVED=1
			GROUP BY A.ORDER_ID
			HAVING SUM(B.QUANTITY)<>SUM(ISNULL(POD.QUANTITY,0)) /*ONLY PENDING ORDERS FOR PO */
			
			IF @BSUMMARY=1
				SELECT  'PO PENDING' AS PENDENCY_TYPE,A.ORDER_NO,A.REF_NO,CONVERT(VARCHAR,A.ORDER_DT,105) AS ORDER_DT
				,DATEDIFF(DD,A.ORDER_DT,GETDATE()) AS ORDER_AGE
				,CONVERT(VARCHAR,A.DELIVERY_DT,105) AS DELIVERY_DT
				,DATEDIFF(DD,A.DELIVERY_DT,GETDATE()) AS DELIVERY_DAYS
				,SUM(B.QUANTITY) AS ORDER_QTY
				,CAST(SUM(B.QUANTITY*B.GROSS_WSP) AS NUMERIC(18,2)) AS ORDER_VALUE
				,SUM(ISNULL(POD.QUANTITY ,0)) AS PO_QTY
				,CAST(SUM(ISNULL(POD.QUANTITY *POD.MRP,0)) AS NUMERIC(18,2)) AS PO_VALUE	 
				FROM #ORDER_RAISED T 
				JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID 
				JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0
				LEFT JOIN 
				(
					SELECT POD.PRODUCT_CODE,POD.QUANTITY,POD.MRP
					FROM POM01106 POM(NOLOCK)
					JOIN POD01106 POD(NOLOCK) ON POM.PO_ID=POD.PO_ID
					WHERE ISNULL(POD.PRODUCT_CODE,'')<>'' AND POM.CANCELLED=0
				)POD ON B.PRODUCT_CODE=POD.PRODUCT_CODE
				GROUP BY A.ORDER_NO,A.REF_NO,A.ORDER_DT,A.DELIVERY_DT
				ORDER BY ORDER_AGE DESC
			ELSE
				SELECT  'PO PENDING' AS PENDENCY_TYPE,A.ORDER_NO,A.REF_NO
				,CONVERT(VARCHAR,A.ORDER_DT,105) AS ORDER_DT
				,DATEDIFF(DD,A.ORDER_DT,GETDATE()) AS ORDER_AGE
				,CONVERT(VARCHAR,A.DELIVERY_DT,105) AS DELIVERY_DT
				,DATEDIFF(DD,A.DELIVERY_DT,GETDATE()) AS DELIVERY_DAYS
				,B.PRODUCT_CODE 
				,ART.ARTICLE_NO
				,(B.QUANTITY) AS ORDER_QTY
				,CAST((B.QUANTITY*B.GROSS_WSP) AS NUMERIC(18,2)) AS ORDER_VALUE
				,(ISNULL(POD.QUANTITY ,0)) AS PO_QTY
				,CAST((ISNULL(POD.QUANTITY *POD.MRP,0)) AS NUMERIC(18,2)) AS PO_VALUE
				FROM #ORDER_RAISED T 
				JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID 
				JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0
				LEFT JOIN 
				(
					SELECT POD.PRODUCT_CODE,POD.QUANTITY,POD.MRP
					FROM POM01106 POM(NOLOCK)
					JOIN POD01106 POD(NOLOCK) ON POM.PO_ID=POD.PO_ID
					WHERE ISNULL(POD.PRODUCT_CODE,'')<>'' AND POM.CANCELLED=0
				)POD ON B.PRODUCT_CODE=POD.PRODUCT_CODE
				JOIN ARTICLE ART ON ART.ARTICLE_CODE=B.ARTICLE_CODE 
				WHERE B.QUANTITY<>ISNULL(POD.QUANTITY ,0)
				ORDER BY ORDER_AGE DESC
    END
    ELSE 
    BEGIN
    IF @BSUMMARY=1
    BEGIN
    SELECT  'PO PENDING' AS PENDENCY_TYPE,ORDER_NO=CAST('' AS VARCHAR(100)),
             REF_NO=CAST('' AS VARCHAR(100)),ORDER_DT=GETDATE(),
				 ORDER_AGE=0
				,DELIVERY_DT=GETDATE()
				,DELIVERY_DAYS=0 
				,ORDER_QTY=0
				,ORDER_VALUE=0
				,PO_QTY=0
				,PO_VALUE=0
				WHERE 1>2
    
    END
    ELSE
    BEGIN
    SELECT  'PO PENDING' AS PENDENCY_TYPE,ORDER_NO='',REF_NO=''
				,ORDER_DT=GETDATE()
				,ORDER_AGE=0
				,DELIVERY_DT=GETDATE()
				, DELIVERY_DAYS=0
				,PRODUCT_CODE=''
				,ARTICLE_NO=''
				,ORDER_QTY=0
				,ORDER_VALUE=0
				,PO_QTY=0
				,PO_VALUE=0 WHERE 1>2
  
    END
    END
    
    IF @BPENDING_PUR=1
    BEGIN
          IF OBJECT_ID('TEMPDB..#PO_RAISEFORPI','U') IS NOT NULL
				DROP TABLE #PO_RAISEFORPI
		   IF OBJECT_ID('TEMPDB..#ORDER_PENDING_PUR','U') IS NOT NULL
				DROP TABLE #ORDER_PENDING_PUR		
				
		    SELECT DISTINCT A.ORDER_ID
			INTO #PO_RAISEFORPI
			FROM WSL_ORDER_MST A (NOLOCK)
			JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0
			LEFT JOIN 
			(
				SELECT POD.PRODUCT_CODE,POD.QUANTITY,
				CONVERT(VARCHAR,POM.PO_DT,105) AS PO_DT,
				MRP 
				FROM POM01106 POM(NOLOCK)
				JOIN POD01106 POD(NOLOCK) ON POM.PO_ID=POD.PO_ID
				WHERE ISNULL(POD.PRODUCT_CODE,'')<>'' AND POM.CANCELLED=0
			)POD ON B.PRODUCT_CODE=POD.PRODUCT_CODE
			WHERE A.CANCELLED =0 AND A.APPROVED=1 AND ISNULL(POD.QUANTITY,0)>0	
         
            SELECT A.ORDER_ID
            INTO #ORDER_PENDING_PUR
			FROM #PO_RAISEFORPI T
			JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID
			JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0
			LEFT JOIN 
			(
				SELECT PID.PRODUCT_CODE,PID.QUANTITY,MRP
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=1 /*ONLY PARTY INVOICE*/
			)PUR ON PUR.PRODUCT_CODE=B.PRODUCT_CODE
			LEFT JOIN 
			(
				SELECT PID.PRODUCT_CODE,PID.QUANTITY,MRP
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=2 /*ONLY GROUP INVOICE*/
			)GPUR ON GPUR.PRODUCT_CODE=B.PRODUCT_CODE
			WHERE A.CANCELLED =0
			GROUP BY A.ORDER_ID
			HAVING SUM(ISNULL(B.QUANTITY ,0)) <>(CASE WHEN (SUM(ISNULL(PUR.QUANTITY,0)))>0 THEN (SUM(ISNULL(PUR.QUANTITY,0))) ELSE (SUM(ISNULL(GPUR.QUANTITY,0))) END)/*PENDING ORDERS IN PUR */
			
			IF @BSUMMARY=1
			SELECT 'PI NOT RAISED' AS PENDENCY_TYPE,A.ORDER_NO,A.REF_NO,CONVERT(VARCHAR,A.ORDER_DT,105) AS ORDER_DT
			,DATEDIFF(DD,A.ORDER_DT,GETDATE()) AS ORDER_AGE
			,CONVERT(VARCHAR,A.DELIVERY_DT,105) AS DELIVERY_DT
			,DATEDIFF(DD,A.DELIVERY_DT,GETDATE()) AS DELIVERY_DAYS
			,SUM(ISNULL(B.QUANTITY ,0)) AS ORDER_QTY
			,ORDER_VALUE=CAST(SUM(ISNULL(B.QUANTITY,0)*ISNULL(B.GROSS_WSP,0)) AS NUMERIC(18,2))
			,(CASE WHEN (SUM(ISNULL(PUR.QUANTITY,0)))>0 THEN (SUM(ISNULL(PUR.QUANTITY,0))) ELSE (SUM(ISNULL(GPUR.QUANTITY,0))) END) AS PI_QTY
			,CAST((CASE WHEN (SUM(ISNULL(PUR.QUANTITY,0)))>0 THEN (SUM(ISNULL(PUR.QUANTITY,0)*ISNULL(PUR.MRP,0))) ELSE (SUM(ISNULL(GPUR.QUANTITY,0)*ISNULL(GPUR.MRP,0))) END) AS NUMERIC(18,2)) AS PI_VALUE 
			FROM #ORDER_PENDING_PUR T
            JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID
			JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0
            LEFT JOIN 
			(
				SELECT PID.PRODUCT_CODE,PID.QUANTITY,MRP
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=1 /*ONLY PARTY INVOICE*/
			)PUR ON PUR.PRODUCT_CODE=B.PRODUCT_CODE
			LEFT JOIN 
			(
				SELECT PID.PRODUCT_CODE,PID.QUANTITY,MRP
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=2 /*ONLY GROUP INVOICE*/
			)GPUR ON GPUR.PRODUCT_CODE=B.PRODUCT_CODE
			WHERE A.CANCELLED =0
			GROUP BY A.ORDER_NO,A.REF_NO,A.REF_NO,A.ORDER_DT,A.DELIVERY_DT
			HAVING SUM(ISNULL(B.QUANTITY ,0)) <>(CASE WHEN (SUM(ISNULL(PUR.QUANTITY,0)))>0 THEN (SUM(ISNULL(PUR.QUANTITY,0))) ELSE (SUM(ISNULL(GPUR.QUANTITY,0))) END)/*PENDING ORDERS IN PUR */
			ELSE
			SELECT 'PI NOT RAISED' AS PENDENCY_TYPE,A.ORDER_NO,A.REF_NO,CONVERT(VARCHAR,A.ORDER_DT,105) AS ORDER_DT
			,DATEDIFF(DD,A.ORDER_DT,GETDATE()) AS ORDER_AGE
			,CONVERT(VARCHAR,A.DELIVERY_DT,105) AS DELIVERY_DT
			,DATEDIFF(DD,A.DELIVERY_DT,GETDATE()) AS DELIVERY_DAYS
			,B.PRODUCT_CODE,ART.ARTICLE_NO
			,(ISNULL(B.QUANTITY ,0)) AS ORDER_QTY
			,ORDER_VALUE=CAST((ISNULL(B.QUANTITY,0)*ISNULL(B.GROSS_WSP,0)) AS NUMERIC(18,2))
			,(CASE WHEN (ISNULL(PUR.QUANTITY,0))>0 THEN (ISNULL(PUR.QUANTITY,0)) ELSE (ISNULL(GPUR.QUANTITY,0)) END) AS PI_QTY
			,CAST((CASE WHEN (ISNULL(PUR.QUANTITY,0))>0 THEN (ISNULL(PUR.QUANTITY,0)*ISNULL(PUR.MRP,0)) ELSE (ISNULL(GPUR.QUANTITY,0)*ISNULL(GPUR.MRP,0)) END) AS NUMERIC(18,2)) AS PI_VALUE 
			FROM #ORDER_PENDING_PUR T
            JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID
			JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0
            LEFT JOIN 
			(
				SELECT PID.PRODUCT_CODE,PID.QUANTITY,MRP
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=1 /*ONLY PARTY INVOICE*/
			)PUR ON PUR.PRODUCT_CODE=B.PRODUCT_CODE
			LEFT JOIN 
			(
				SELECT PID.PRODUCT_CODE,PID.QUANTITY,MRP
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=2 /*ONLY GROUP INVOICE*/
			)GPUR ON GPUR.PRODUCT_CODE=B.PRODUCT_CODE
			JOIN ARTICLE ART ON ART.ARTICLE_CODE=B.ARTICLE_CODE 
			WHERE A.CANCELLED =0
			AND (ISNULL(B.QUANTITY ,0)) <>(CASE WHEN (ISNULL(PUR.QUANTITY,0))>0 THEN (ISNULL(PUR.QUANTITY,0)) ELSE (ISNULL(GPUR.QUANTITY,0)) END)/*PENDING ORDERS IN PUR */
    END
    ELSE 
    BEGIN
    IF @BSUMMARY=1
    BEGIN
    SELECT  'PO PENDING' AS PENDENCY_TYPE,ORDER_NO=CAST('' AS VARCHAR(100)),
             REF_NO=CAST('' AS VARCHAR(100)),ORDER_DT=GETDATE(),
				 ORDER_AGE=0
				,DELIVERY_DT=GETDATE()
				,DELIVERY_DAYS=0 
				,ORDER_QTY=0
				,ORDER_VALUE=0
				,PI_QTY=0
				,PI_VALUE=0
				WHERE 1>2
    
    END
    ELSE
    BEGIN
    SELECT  'PO PENDING' AS PENDENCY_TYPE,ORDER_NO='',REF_NO=''
				,ORDER_DT=GETDATE()
				,ORDER_AGE=0
				,DELIVERY_DT=GETDATE()
				, DELIVERY_DAYS=0
				,PRODUCT_CODE=''
				,ARTICLE_NO=''
				,ORDER_QTY=0
				,ORDER_VALUE=0
				,PI_QTY=0
				,PI_VALUE=0 WHERE 1>2
  
    END
    END
    
     IF OBJECT_ID ('TEMPDB..#ORDDLV','U') IS NOT NULL
             DROP TABLE #ORDDLV
           
    	SELECT A.CUSTOMER_CODE
			  ,A.CM_NO 
			  ,A.CM_DT 
			  ,B.PRODUCT_CODE   
			  ,B.QUANTITY
			  ,MRP 
		INTO #ORDDLV	  	  
		FROM CMM01106 A (NOLOCK) 
		JOIN CMD01106 B (NOLOCK) ON A.CM_ID=B.CM_ID
		JOIN WSL_ORDER_DET WOD (NOLOCK) ON B.PRODUCT_CODE=
							(CASE WHEN WOD.ORDER_TYPE=0 THEN WOD.PRODUCT_CODE ELSE WOD.REF_PRODUCT_CODE END)
		JOIN WSL_ORDER_MST WOM (NOLOCK) ON WOD.ORDER_ID=WOM.ORDER_ID AND A.CUSTOMER_CODE=WOM.CUSTOMER_CODE
		WHERE A.CM_MODE = 1 AND B.RFNET>0 
		AND A.CANCELLED = 0 AND A.CUSTOMER_CODE <> '000000000000' AND WOM.CANCELLED=0 AND ISNULL(WOD.CANCELLED,0)=0


		;WITH CTE_REMOVEDUP AS
		(
			SELECT ROW_NUMBER() OVER(PARTITION BY PRODUCT_CODE,CUSTOMER_CODE ORDER BY CM_DT ASC,CM_NO ASC) AS SNO
				  ,CUSTOMER_CODE
				  ,CM_NO
				  ,PRODUCT_CODE
				  ,QUANTITY
			FROM #ORDDLV	  
		)
		DELETE CTE_REMOVEDUP WHERE SNO<>1
		
		CREATE INDEX IX_ORDDLV_PRODUCT_CODE  ON #ORDDLV(PRODUCT_CODE)
		CREATE INDEX IX_ORDDLV_CUSTOMER_CODE ON #ORDDLV(CUSTOMER_CODE)
		CREATE INDEX IX_ORDDLV_CM_NO ON #ORDDLV(CM_NO)	
	
	    
	IF @BPENDING_BILL=1
    BEGIN
         IF OBJECT_ID('TEMPDB..#PI_RAISED','U') IS NOT NULL
				DROP TABLE #PI_RAISED	
		 IF OBJECT_ID('TEMPDB..#ORDER_PENDING_BILL','U') IS NOT NULL
				DROP TABLE #ORDER_PENDING_BILL			
				
			SELECT A.ORDER_ID
			INTO #PI_RAISED
			FROM WSL_ORDER_MST A (NOLOCK)
			JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 AND B.ORDER_TYPE=0
			LEFT JOIN 
			(
				SELECT PIM.MRR_NO,
				CONVERT(VARCHAR,PIM.RECEIPT_DT,105) AS RECEIPT_DT,
				PID.PRODUCT_CODE,QUANTITY,MRP 
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID 
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=1 /*ONLY PARTY INVOICE*/
			)PUR ON B.PRODUCT_CODE=PUR.PRODUCT_CODE
			LEFT JOIN 
		    (
				SELECT PIM.MRR_NO,
				CONVERT(VARCHAR,PIM.RECEIPT_DT,105) AS RECEIPT_DT,
				PID.PRODUCT_CODE,QUANTITY,MRP
				FROM PIM01106 PIM(NOLOCK)
				JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
				WHERE ISNULL(PID.PRODUCT_CODE,'')<>'' AND PIM.CANCELLED=0 AND PIM.INV_MODE=2 /*ONLY GROUP INVOICE*/
		    )GPUR ON B.PRODUCT_CODE=GPUR.PRODUCT_CODE
			WHERE A.CANCELLED =0 AND A.APPROVED=1 AND 0<>(CASE WHEN (ISNULL(PUR.QUANTITY,0))>0 THEN (ISNULL(PUR.QUANTITY,0)) ELSE (ISNULL(GPUR.QUANTITY,0)) END)
			GROUP BY A.ORDER_ID
			/*ONLY PENDING ORDERS*/	
			
		   SELECT A.ORDER_ID 
		   INTO #ORDER_PENDING_BILL
	       FROM #PI_RAISED T
	       JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID
		   JOIN WSL_ORDER_DET B (NOLOCK) ON A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 
	       LEFT JOIN 
		   (
				SELECT CMM.CM_NO,CMM.CM_DT,CMM.PRODUCT_CODE,QUANTITY,MRP,CUSTOMER_CODE  
				FROM #ORDDLV CMM(NOLOCK)
		   )SLS ON SLS.PRODUCT_CODE=(CASE WHEN B.ORDER_TYPE=0 THEN B.PRODUCT_CODE ELSE B.REF_PRODUCT_CODE END)
		    AND SLS.CUSTOMER_CODE =A.CUSTOMER_CODE 
		   WHERE A.CANCELLED =0
		   GROUP BY A.ORDER_ID
		   HAVING SUM(ISNULL(B.QUANTITY ,0))<>(SUM(ISNULL(SLS.QUANTITY,0)))
		  
		  IF @BSUMMARY=1
		    SELECT 'BILL NOT RAISED' AS PENDENCY_TYPE,A.ORDER_NO,A.REF_NO,CONVERT(VARCHAR,A.ORDER_DT,105) AS ORDER_DT
			,DATEDIFF(DD,A.ORDER_DT,GETDATE()) AS ORDER_AGE
			,CONVERT(VARCHAR,A.DELIVERY_DT,105) AS DELIVERY_DT
			,DATEDIFF(DD,A.DELIVERY_DT,GETDATE()) AS DELIVERY_DAYS
			,(SUM(ISNULL(B.QUANTITY ,0))) AS ORDER_QTY
			,ORDER_VALUE=CAST((SUM(ISNULL(B.QUANTITY,0)*ISNULL(B.GROSS_WSP,0)))  AS NUMERIC(18,2))
			,(SUM(ISNULL(SLS.QUANTITY,0))) SLS_QTY
			,CAST((SUM(ISNULL(SLS.QUANTITY,0)*ISNULL(SLS.MRP,0))) AS NUMERIC(18,2)) SLS_VALUE 
	       FROM #ORDER_PENDING_BILL T
	       JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID
		   JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 
	       LEFT JOIN 
		  (
			SELECT CMM.CM_NO,CMM.CM_DT,CMM.PRODUCT_CODE,QUANTITY,MRP,CUSTOMER_CODE  
				FROM #ORDDLV CMM(NOLOCK)
		  )SLS ON SLS.PRODUCT_CODE=(CASE WHEN B.ORDER_TYPE=0 THEN B.PRODUCT_CODE ELSE B.REF_PRODUCT_CODE END)
		   AND A.CUSTOMER_CODE =SLS.CUSTOMER_CODE 
		  WHERE A.CANCELLED =0
		  GROUP BY A.ORDER_NO,A.REF_NO,A.ORDER_DT,A.DELIVERY_DT
		  HAVING SUM(ISNULL(B.QUANTITY ,0))<>(SUM(ISNULL(SLS.QUANTITY,0)))
		  
		  ELSE
		  
		    SELECT 'BILL NOT RAISED' AS PENDENCY_TYPE,A.ORDER_NO,A.REF_NO,CONVERT(VARCHAR,A.ORDER_DT,105) AS ORDER_DT
			,DATEDIFF(DD,A.ORDER_DT,GETDATE()) AS ORDER_AGE
			,CONVERT(VARCHAR,A.DELIVERY_DT,105) AS DELIVERY_DT
			,DATEDIFF(DD,A.DELIVERY_DT,GETDATE()) AS DELIVERY_DAYS
			,(CASE WHEN B.ORDER_TYPE=0 THEN B.PRODUCT_CODE ELSE B.REF_PRODUCT_CODE END) AS PRODUCT_CODE
			,ART.ARTICLE_NO
			,((ISNULL(B.QUANTITY ,0))) AS ORDER_QTY
			,ORDER_VALUE=CAST(((ISNULL(B.QUANTITY,0)*ISNULL(B.GROSS_WSP,0)))  AS NUMERIC(18,2))
			,((ISNULL(SLS.QUANTITY,0))) SLS_QTY
			,CAST(((ISNULL(SLS.QUANTITY,0)*ISNULL(SLS.MRP,0))) AS NUMERIC(18,2)) SLS_VALUE 
	       FROM #ORDER_PENDING_BILL T
	       JOIN WSL_ORDER_MST A (NOLOCK) ON A.ORDER_ID=T.ORDER_ID
		   JOIN WSL_ORDER_DET B (NOLOCK) ON  A.ORDER_ID=B.ORDER_ID AND ISNULL(B.CANCELLED,0)=0 
	       LEFT JOIN 
		   (
				SELECT CMM.CM_NO,CMM.CM_DT,CMM.PRODUCT_CODE,QUANTITY,MRP,CUSTOMER_CODE  
				FROM #ORDDLV CMM(NOLOCK)
		   )SLS ON SLS.PRODUCT_CODE=(CASE WHEN B.ORDER_TYPE=0 THEN B.PRODUCT_CODE ELSE B.REF_PRODUCT_CODE END)
		    AND A.CUSTOMER_CODE =SLS.CUSTOMER_CODE 
		   JOIN ARTICLE ART ON ART.ARTICLE_CODE=B.ARTICLE_CODE 
		  WHERE A.CANCELLED =0
		 AND (ISNULL(B.QUANTITY ,0))<>((ISNULL(SLS.QUANTITY,0)))
    END   
    ELSE 
    BEGIN
    IF @BSUMMARY=1
    BEGIN
    SELECT  'PO PENDING' AS PENDENCY_TYPE,ORDER_NO=CAST('' AS VARCHAR(100)),
             REF_NO=CAST('' AS VARCHAR(100)),ORDER_DT=CONVERT(VARCHAR,GETDATE(),105),
				 ORDER_AGE=0
				,DELIVERY_DT=CONVERT(VARCHAR,GETDATE(),105)
				,DELIVERY_DAYS=0 
				,ORDER_QTY=0
				,ORDER_VALUE=0
				,SLS_QTY=0
				,SLS_VALUE=0
				WHERE 1>2
    
    END
    ELSE
    BEGIN
    SELECT  'PO PENDING' AS PENDENCY_TYPE,ORDER_NO='',REF_NO=''
				,ORDER_DT=GETDATE()
				,ORDER_AGE=0
				,DELIVERY_DT=GETDATE()
				, DELIVERY_DAYS=0
				,PRODUCT_CODE=''
				,ARTICLE_NO=''
				,ORDER_QTY=0
				,ORDER_VALUE=0
				,SLS_QTY=0
				,SLS_VALUE=0 WHERE 1>2
  
    END
    END    			
END
