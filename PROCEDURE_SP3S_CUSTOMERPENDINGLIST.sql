CREATE PROCEDURE SP3S_CUSTOMERPENDINGLIST--(LocId 3 digit change  by Sanjay:05-11-2024)
(
 @CDEPT_ID VARCHAR(4)='',
 @CCUSTOMERCODE VARCHAR(20)='',
 @DTO_DT DATETIME ='',
 @BORDER_XN INT =0
)
AS
BEGIN
    
     IF @DTO_DT=''
     SET @DTO_DT='2099-03-31'
       DECLARE @DTSQL1 NVARCHAR(MAX)
     --PENDIN CREDIT ISSUE'
       
       IF OBJECT_ID('TEMPDB..#TMPPENDING','U') IS NOT NULL
          DROP TABLE #TMPPENDING

        SELECT CAST('CI' AS VARCHAR(100)) AS TYP, CAST('SLS' AS VARCHAR(10)) AS XN_TYPE,	A.CM_ID AS MEMO_ID, 
        A.CM_NO AS MEMO_NO, A.CM_DT AS MEMO_DT,A.CUSTOMER_CODE ,
        CAST('' AS VARCHAR(100)) AS NARRATION,D.ADJ_MEMO_ID
        INTO #TMPPENDING
			FROM CMM01106 A (NOLOCK)
			JOIN
			(
				SELECT A.MEMO_ID, SUM(A.AMOUNT) AS CREDIT_AMOUNT 
				FROM PAYMODE_XN_DET A (NOLOCK)
				JOIN CMM01106 B (NOLOCK) ON A.MEMO_ID=B.CM_ID
				WHERE B.CANCELLED=0 AND XN_TYPE = 'SLS' 
				AND PAYMODE_CODE = '0000004' 
				AND A.AMOUNT > 0 
				AND (B.CUSTOMER_CODE = @CCUSTOMERCODE OR B.AC_CODE =@CCUSTOMERCODE)
				GROUP BY A.MEMO_ID
			)B ON A.CM_ID = B.MEMO_ID
			
		LEFT OUTER JOIN 
		(SELECT A.CM_ID,SUM(RECEIPT_AMOUNT) AS RECEIPT_AMT FROM CMM_CREDIT_RECEIPT A (NOLOCK)
		JOIN ARC01106 B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID
		 WHERE (@CCUSTOMERCODE='' OR (B.CUSTOMER_CODE=@CCUSTOMERCODE OR B.AC_CODE =@CCUSTOMERCODE))
		AND B.CANCELLED = 0
		GROUP BY A.CM_ID ) C ON C.CM_ID=A.CM_ID
		LEFT OUTER JOIN 
		
		( SELECT A.ADJ_MEMO_ID,SUM(ABS(A.AMOUNT)) AS CREDIT_REFUND_AMOUNT
			FROM PAYMODE_XN_DET A (NOLOCK)
			JOIN CMM01106 B (NOLOCK) ON A.MEMO_ID = B.CM_ID
			WHERE 
			(@CCUSTOMERCODE='' OR (B.CUSTOMER_CODE=@CCUSTOMERCODE OR B.AC_CODE =@CCUSTOMERCODE))
		--	AND B.CM_ID <> A.CM_ID
		    AND A.ADJ_MEMO_ID<>''
			AND B.CANCELLED = 0
			GROUP BY A.ADJ_MEMO_ID
		 ) D ON D.ADJ_MEMO_ID=A.CM_ID
		WHERE A.CANCELLED=0 AND 
		(@CCUSTOMERCODE='' OR (A.CUSTOMER_CODE = @CCUSTOMERCODE OR A.AC_CODE =@CCUSTOMERCODE))
		AND (@CDEPT_ID='' OR a.location_Code=@CDEPT_ID)
		AND A.CM_DT <=@DTO_DT
		AND (B.CREDIT_AMOUNT -  ( ISNULL(C.RECEIPT_AMT,0)+ ISNULL(D.CREDIT_REFUND_AMOUNT,0)))  > 0  
		
		--credit refund amount short 
		INSERT INTO #TMPPENDING(TYP,XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE )	
		SELECT 'DR' TYP,'SLS' AS XN_TYPE,
		A.MEMO_ID AS MEMO_ID, CMM.CM_NO  MEMO_NO,CMM.CM_DT  MEMO_DT,CMM.CUSTOMER_CODE 
		FROM PAYMODE_XN_DET  A
		JOIN #TMPPENDING B ON A.ADJ_MEMO_ID =B.ADJ_MEMO_ID 
		JOIN CMM01106 CMM ON CMM.cm_id =A.memo_id 
		WHERE B.ADJ_MEMO_ID <>'' AND CMM.CANCELLED =0
		
		
		--REC WITOUT BILL
		
		INSERT INTO #TMPPENDING(TYP,XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE )			
		SELECT 'DR' TYP,'ARC' AS XN_TYPE,
		A.adv_rec_id  AS MEMO_ID, A.adv_rec_no   MEMO_NO,A.adv_rec_dt   MEMO_DT,A.CUSTOMER_CODE   
		FROM  ARC01106 A (NOLOCK)
		LEFT JOIN CMM_CREDIT_RECEIPT B (NOLOCK) ON A.adv_rec_id =B.adv_rec_id 
		LEFT JOIN HBD_RECEIPT HBD (NOLOCK) ON A.adv_rec_id =HBD.adv_rec_id 
		WHERE A.cancelled =0 AND B.adv_rec_id IS NULL AND HBD.adv_rec_id IS NULL
		AND A.arc_type =1 AND A.arct =1
		AND (@CCUSTOMERCODE='' OR (A.CUSTOMER_CODE = @CCUSTOMERCODE OR A.AC_CODE =@CCUSTOMERCODE))
		AND (@CDEPT_ID='' OR a.location_code=@CDEPT_ID)
		AND A.adv_rec_dt  <=@DTO_DT
		UNION ALL
		SELECT 'DR' TYP,'ARC' AS XN_TYPE,
		A.adv_rec_id  AS MEMO_ID, A.adv_rec_no   MEMO_NO,A.adv_rec_dt   MEMO_DT,A.CUSTOMER_CODE   
		FROM  ARC01106 A (NOLOCK)
		JOIN HBD_RECEIPT HBD (NOLOCK) ON A.adv_rec_id =HBD.adv_rec_id 
		JOIN hold_back_deliver_mst MST ON MST.memo_id=HBD.MEMO_ID
		WHERE A.cancelled =0 
		AND A.arc_type =1 AND A.arct =1
		AND (@CCUSTOMERCODE='' OR (A.CUSTOMER_CODE = @CCUSTOMERCODE OR A.AC_CODE =@CCUSTOMERCODE))
		AND (@CDEPT_ID='' OR a.location_code=@CDEPT_ID)
		AND A.adv_rec_dt  <=@DTO_DT 
		AND MST.TOTAL_AMOUNT>A.net_amount
		

		--RECEIVING AGAINST PENDING CREDIT ISSUE
		INSERT INTO #TMPPENDING(TYP,XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE )	
		SELECT DISTINCT 'CR' AS TYP, 'ARC' AS XN_TYPE,B.ADV_REC_ID AS MEMO_ID,
		B.ADV_REC_NO AS MEMO_NO,B.ADV_REC_DT AS MEMO_DT,B.CUSTOMER_CODE 
		FROM CMM_CREDIT_RECEIPT A (NOLOCK)
		JOIN ARC01106 B (NOLOCK) ON A.ADV_REC_ID=B.ADV_REC_ID
		JOIN #TMPPENDING P ON P.MEMO_ID=A.CM_ID  AND P.TYP ='CI'
		WHERE (@CCUSTOMERCODE='' OR (B.CUSTOMER_CODE=@CCUSTOMERCODE OR B.AC_CODE =@CCUSTOMERCODE))
		AND B.CANCELLED = 0
	    UNION ALL
	    SELECT DISTINCT 'CR' AS TYP, 'SLS' AS XN_TYPE,B.CM_ID AS MEMO_ID,
		B.CM_NO AS MEMO_NO,B.CM_DT  AS MEMO_DT,B.CUSTOMER_CODE
		FROM PAYMODE_XN_DET A (NOLOCK)
		JOIN CMM01106 B (NOLOCK) ON A.MEMO_ID = B.CM_ID
		JOIN #TMPPENDING P ON P.MEMO_ID=B.CM_ID  AND P.TYP ='CI'
		WHERE (@CCUSTOMERCODE='' OR (B.CUSTOMER_CODE=@CCUSTOMERCODE OR B.AC_CODE =@CCUSTOMERCODE))
		--AND B.CM_ID <> P.MEMO_ID
		AND A.ADJ_MEMO_ID<>''
	    AND B.CANCELLED = 0
		
		--
		
		--PENDING CREDIT NOTES
		
		 --SELECT 'SLS' AS XN_TYPE,	A.CM_ID, A.CM_NO, A.CM_DT,A.CUSTOMER_CODE 
   --     INTO #TMPPENDING
        
	
			INSERT INTO #TMPPENDING(TYP,XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE,NARRATION )	
			SELECT 'CN ISSUE' AS TYP, 'SLS' AS XN_TYPE, 
			A.CM_ID,A.CM_NO,A.CM_DT,A.CUSTOMER_CODE,
			'CN ISSUE' AS NARRATION
			FROM CMM01106 (NOLOCK) A
			JOIN 
			(
			 SELECT MEMO_ID,ABS(SUM(AMOUNT)) AS [CN_AMOUNT] FROM DBO.PAYMODE_XN_DET WITH(NOLOCK)
			 WHERE PAYMODE_CODE ='0000004' AND AMOUNT< =0 AND XN_TYPE ='SLS'
			 GROUP BY MEMO_ID
			)P ON A.CM_ID = P.MEMO_ID
			
			LEFT OUTER JOIN
			(
			 SELECT PY.ADJ_MEMO_ID ,SUM(PY.AMOUNT) AS ADJ_AMOUNT 
			 FROM PAYMODE_XN_DET PY (NOLOCK)
			 JOIN CMM01106 CM ON CM.CM_ID = PY.MEMO_ID
			 WHERE PAYMODE_CODE='0000001' AND CM.CANCELLED = 0
			 AND (@CCUSTOMERCODE='' OR(CM.CUSTOMER_CODE = @CCUSTOMERCODE OR CM.AC_CODE =@CCUSTOMERCODE))
			 GROUP BY ADJ_MEMO_ID
			 
			) B ON A.CM_ID=B.ADJ_MEMO_ID
			 WHERE CM_DT <=@DTO_DT AND CANCELLED = 0 
			 AND (@CDEPT_ID='' OR a.location_code=@CDEPT_ID)
			 AND (@CCUSTOMERCODE='' OR(A.CUSTOMER_CODE = @CCUSTOMERCODE OR A.AC_CODE =@CCUSTOMERCODE))
			 AND SUBSTRING(A.CM_NO,len(a.location_code)+3,1) = 'N'
			AND A.CANCELLED=0
			AND (@CDEPT_ID='' OR a.location_code=@CDEPT_ID)
			AND CN_AMOUNT - ISNULL(ADJ_AMOUNT,0)  > 0  
		
		
			
	   IF OBJECT_ID('TEMPDB..#PENDING_ADVANCES','U') IS NOT NULL
		   DROP TABLE #PENDING_ADVANCES
		   
	  INSERT INTO #TMPPENDING(XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE )					
	   SELECT 'ARC' AS XN_TYPE,
	          A.ADV_REC_ID ,     
	   ADV_REC_NO AS MEMO_NO,ADV_REC_DT AS MEMO_DT,B.CUSTOMER_CODE AS CUSTOMER_CODE
	   FROM ARC01106 A     
	   JOIN CUSTDYM B ON A.CUSTOMER_CODE=B.CUSTOMER_CODE    
	   LEFT OUTER JOIN     
	  (
	   SELECT ADJ_MEMO_ID,SUM(A.AMOUNT) AS ADJ_AMOUNT  
	   FROM PAYMODE_XN_DET A     
	   JOIN CMM01106 B ON A.MEMO_ID=B.CM_ID  WHERE XN_TYPE='SLS'    
	   AND PAYMODE_CODE='0000002' AND B.CANCELLED=0 
	   GROUP BY ADJ_MEMO_ID
	   UNION ALL    
	   SELECT A.ADJ_MEMO_ID,SUM(A.AMOUNT) AS ADJ_AMOUNT  
	   FROM PAYMODE_XN_DET A     
	   JOIN ARC01106 B ON A.MEMO_ID=B.ADV_REC_ID
	   WHERE PAYMODE_CODE='0000002' AND B.CANCELLED=0 AND XN_TYPE='ARC' GROUP BY A.ADJ_MEMO_ID
	   ) C    ON A.ADV_REC_ID=C.ADJ_MEMO_ID 
	   WHERE A.CANCELLED=0 
	   AND A.ARC_TYPE=1 AND A.ADV_REC_DT<=@DTO_DT AND A.AMOUNT-ISNULL(C.ADJ_AMOUNT,0)<>0
	   AND (@CDEPT_ID='' OR a.location_code =@CDEPT_ID)
	   AND (@CCUSTOMERCODE='' OR A.CUSTOMER_CODE =@CCUSTOMERCODE)
	   AND A.AMOUNT-(ISNULL(C.ADJ_AMOUNT,0)) > 0 AND (B.CUSTOMER_CODE = @CCUSTOMERCODE OR @CCUSTOMERCODE='') 
	   AND A.ARCT=2
			
	   IF @BORDER_XN=1
	   BEGIN
	    ---GETTING RETAIL ORDER DETAIL
			IF OBJECT_ID('TEMPDB..#ORDER_DET','U') IS NOT NULL
				DROP TABLE #ORDER_DET
			
			IF OBJECT_ID('TEMPDB..#PENDING_ORDER','U') IS NOT NULL
				DROP TABLE #PENDING_ORDER
			
			--GETTING AMOUNT AGAINST EACH ORDER
			SELECT A.ORDER_ID   AS XN_ID
				  ,SUM(B.RFNET) AS TOTAL_AMOUNT  
				  ,CAST(0 AS NUMERIC(12,2)) AS RECEIPT_TILL_DT
				  ,'ORD'		AS  XN_TYPE
				  ,CONVERT(VARCHAR(22),'') AS ADV_REC_ID
				  ,A.CUSTOMER_CODE
			INTO #ORDER_DET      
			FROM WSL_ORDER_MST A  (NOLOCK)
			JOIN WSL_ORDER_DET B (NOLOCK) ON A.ORDER_ID=B.ORDER_ID
			WHERE A.CANCELLED = 0 AND ISNULL(B.CANCELLED,0)=0
			AND A.CUSTOMER_CODE <> '000000000000' 
			AND A.ORDER_DT <=@DTO_DT
			AND (@CDEPT_ID='' OR a.location_Code=@CDEPT_ID)
			AND (@CCUSTOMERCODE='' OR A.CUSTOMER_CODE =@CCUSTOMERCODE)
			GROUP BY A.ORDER_ID,A.CUSTOMER_CODE
			UNION ALL
			--GETTING ADVANCES RECEIVED AGAINST ORDERS
			SELECT A.ORDER_ID AS XN_ID
				  ,CASE WHEN A.ORDER_DT <=@DTO_DT THEN  -ISNULL(ARC.NET_AMOUNT,0) ELSE 0 END AS TOTAL_AMOUNT  
				  ,CASE WHEN A.ORDER_DT >@DTO_DT THEN  -ISNULL(ARC.NET_AMOUNT,0) ELSE 0 END AS RECEIPT_TILL_DT
				  ,'ADV' AS  XN_TYPE
				  ,ARC.ADV_REC_ID 
				  ,A.CUSTOMER_CODE
			FROM WSL_ORDER_MST A  (NOLOCK)
			JOIN WSL_ORDER_ADV_RECEIPT AR (NOLOCK) ON AR.ORDER_ID=A.ORDER_ID
			JOIN ARC01106 ARC (NOLOCK) ON AR.ADV_REC_ID=ARC.ADV_REC_ID
			WHERE A.CANCELLED = 0 
			AND A.CUSTOMER_CODE <> '000000000000' 
			AND A.ORDER_DT <=@DTO_DT --@DTO_DT
			AND (@CCUSTOMERCODE='' OR A.CUSTOMER_CODE =@CCUSTOMERCODE)
			/*IF FROM DATE IS CONSIDERED, DONOT CONSIDER SETTLEMENT DATE ELSE CONSIDER SETTLEMENT DATE*/
			AND ISNULL(ARC.CANCELLED,0)=0 
			AND (@CDEPT_ID='' OR a.location_Code=@CDEPT_ID)--
			
			--GETTING AMOUNT AGAINST BARCODES DELIEVERED IN CASH MEMO
			INSERT #ORDER_DET(XN_ID,TOTAL_AMOUNT,XN_TYPE,ADV_REC_ID,CUSTOMER_CODE)
			SELECT  WOM.ORDER_ID AS XN_ID
				  ,-SUM((WOD.RFNET/WOD.QUANTITY)*B.QUANTITY) AS TOTAL_AMOUNT  
				  ,'DVL' AS  XN_TYPE
				  ,A.CM_ID AS ADV_REC_ID 
				  ,A.CUSTOMER_CODE
			FROM CMM01106 A  (NOLOCK)
			JOIN CMD01106 B (NOLOCK) ON A.CM_ID=B.CM_ID
			JOIN WSL_ORDER_DET WOD (NOLOCK) ON B.PRODUCT_CODE=(CASE WHEN WOD.ORDER_TYPE=0 THEN WOD.PRODUCT_CODE ELSE WOD.REF_PRODUCT_CODE END)
			JOIN WSL_ORDER_MST WOM (NOLOCK) ON WOD.ORDER_ID=WOM.ORDER_ID AND A.CUSTOMER_CODE=WOM.CUSTOMER_CODE
			WHERE A.CANCELLED = 0 AND WOM.CANCELLED=0 AND ISNULL(WOD.CANCELLED,0)=0 AND A.CUSTOMER_CODE <> '000000000000' 
			AND B.QUANTITY>0
			AND A.CM_DT<=@DTO_DT
			AND (@CCUSTOMERCODE='' OR A.CUSTOMER_CODE =@CCUSTOMERCODE)
			AND (@CDEPT_ID='' OR a.location_code=@CDEPT_ID)
			/*IF FROM DATE IS CONSIDERED, DONOT CONSIDER SETTLEMENT DATE ELSE CONSIDER SETTLEMENT DATE*/
			GROUP BY WOM.ORDER_ID,A.CM_ID,A.CUSTOMER_CODE
			
			--GETTING LIST OF ORDERS WHOSE ADVANCES HAVE BEEN SETTLED
			INSERT #ORDER_DET(XN_ID,TOTAL_AMOUNT,XN_TYPE,ADV_REC_ID,CUSTOMER_CODE)
			SELECT A.XN_ID
				  ,SUM(B.AMOUNT) AS TOTAL_AMOUNT  
				  ,'DVL' AS  XN_TYPE
				  ,'' AS ADV_REC_ID 
				  ,A.CUSTOMER_CODE 
			FROM #ORDER_DET A  (NOLOCK)
			JOIN PAYMODE_XN_DET B (NOLOCK) ON A.ADV_REC_ID=B.MEMO_ID AND B.XN_TYPE='SLS'
			JOIN #ORDER_DET C (NOLOCK) ON B.ADJ_MEMO_ID=C.ADV_REC_ID AND C.XN_TYPE='ADV'
			WHERE A.XN_TYPE = 'DVL' 
			AND (@CCUSTOMERCODE='' OR A.CUSTOMER_CODE =@CCUSTOMERCODE)
			GROUP BY A.XN_ID ,A.CUSTOMER_CODE 
			
		   INSERT INTO #TMPPENDING(XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE )						
		   SELECT 'BO' AS XN_TYPE,
				  A.XN_ID AS CM_ID ,     
		   '' AS MEMO_NO,'' AS MEMO_DT,A.CUSTOMER_CODE
			FROM #ORDER_DET A
			WHERE @BORDER_XN=1
			AND A.CUSTOMER_CODE =@CCUSTOMERCODE
			GROUP BY XN_ID,A.CUSTOMER_CODE
			HAVING SUM(TOTAL_AMOUNT)>0

		   INSERT INTO #TMPPENDING(XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE )						
		   SELECT 'OPS' AS XN_TYPE,
				  '' AS CM_ID ,     
		   '' AS MEMO_NO,'' AS MEMO_DT,A.CUSTOMER_CODE
			FROM custdym A (nolock)
			WHERE A.CUSTOMER_CODE =@CCUSTOMERCODE
			and opening_balance<>0
	END
	
	INSERT INTO #TMPPENDING(XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE )	
	SELECT	
				'HBD' AS XN_TYPE 
				,A.MEMO_ID AS XN_ID
				,A.MEMO_NO
				,A.MEMO_DT AS XN_DT
				,A.customer_code
	    FROM HOLD_BACK_DELIVER_MST A  (NOLOCK)
	    LEFT JOIN
	    (
			SELECT AR.MEMO_ID,SUM(ARC.NET_AMOUNT) AS NET_AMOUNT
			FROM HBD_RECEIPT AR (NOLOCK) 
			JOIN ARC01106 ARC (NOLOCK) ON AR.ADV_REC_ID=ARC.ADV_REC_ID 
			AND ISNULL(ARC.CANCELLED,0)=0
			WHERE  (@CDEPT_ID='' OR arc.location_code=@CDEPT_ID)
			AND ARC.cancelled=0
			GROUP BY AR.MEMO_ID
		)ADV ON A.MEMO_ID=ADV.MEMO_ID
		JOIN custdym cus (NOLOCK) ON cus.customer_code=a.CUSTOMER_CODE
		WHERE A.CANCELLED = 0 
		AND A.CUSTOMER_CODE <> '000000000000' 
		AND A.Entry_mode=2 
		AND ISNULL(A.TOTAL_AMOUNT,0)<>0
		AND (ISNULL(@CCUSTOMERCODE,'')='' OR A.CUSTOMER_CODE=@CCUSTOMERCODE)
		AND (@CDEPT_ID='' OR cus.location_id=@CDEPT_ID)
		GROUP BY A.CUSTOMER_CODE,A.MEMO_NO,A.MEMO_ID,A.MEMO_DT,
		A.TOTAL_AMOUNT,ISNULL(ADV.NET_AMOUNT,0)
		HAVING A.TOTAL_AMOUNT-ISNULL(ADV.NET_AMOUNT,0)>0
		
	
	SELECT ISNULL(NARRATION ,'') AS NARRATION, XN_TYPE,MEMO_ID,MEMO_NO,MEMO_DT,CUSTOMER_CODE 
	FROM #TMPPENDING
	
		 
END


