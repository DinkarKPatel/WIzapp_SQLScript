CREATE PROCEDURE SP3S_PENDING_RETAIL_ORDERS
(
	 @DORDER_DT DATETIME=''
	,@CCUSTOMER_CODE VARCHAR(12)=''
	,@BPOPENDING BIT=0
	,@BPURPENDING BIT=0
	,@BBILLPENDING BIT=0
	,@BURGENT BIT=0
)
--WITH ENCRYPTION
AS
BEGIN
		DECLARE @CCMD NVARCHAR(MAX),@CTABLENAME VARCHAR(100)
	
		IF OBJECT_ID('TEMPDB..#ALLPENDINGORDERS','U') IS NOT NULL
			DROP TABLE #ALLPENDINGORDERS
	    
	    IF OBJECT_ID ('TEMPDB..#ORDDLV','U') IS NOT NULL
           DROP TABLE #ORDDLV
           
    	SELECT A.CUSTOMER_CODE
			  ,A.CM_NO 
			  ,A.CM_DT 
			  ,B.PRODUCT_CODE   
			  ,B.QUANTITY
		INTO #ORDDLV	  	  
		FROM CMM01106 A (NOLOCK) 
		JOIN CMD01106 B (NOLOCK) ON A.CM_ID=B.CM_ID
		JOIN WSL_ORDER_DET WOD (NOLOCK) ON B.PRODUCT_CODE=
							(CASE WHEN WOD.ORDER_TYPE=0 THEN WOD.PRODUCT_CODE ELSE WOD.REF_PRODUCT_CODE END)
		JOIN WSL_ORDER_MST WOM (NOLOCK) ON WOD.ORDER_ID=WOM.ORDER_ID AND A.CUSTOMER_CODE=WOM.CUSTOMER_CODE
		WHERE A.CM_MODE = 1 AND B.RFNET>0 
		AND A.CANCELLED = 0 AND A.CUSTOMER_CODE <> '000000000000' 
		AND WOM.CANCELLED=0 AND ISNULL(WOD.CANCELLED,0)=0 


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
	    
		SELECT 
		--CUSTOMER DETAILS
		 CUS.USER_CUSTOMER_CODE 
		,CUS.CUSTOMER_FNAME+' '+CUS.CUSTOMER_LNAME AS CUSTOMER_NAME
		,CUS.MOBILE AS MOBILE
		--ORDER DETAILS
		,B.REF_NO
		,B.ORDER_NO
		,CONVERT(VARCHAR,B.ORDER_DT,105) AS ORDER_DT
		,CONVERT(VARCHAR,B.trail_dt,105) AS trail_dt
		,CONVERT(VARCHAR,B.DELIVERY_DT,105) AS DELIVERY_DT
		,DATEDIFF(DD,B.DELIVERY_DT,GETDATE()) AS DELIVERY_DAYS
		,(CASE WHEN A.ORDER_TYPE=1 THEN A.REF_PRODUCT_CODE ELSE A.PRODUCT_CODE END) AS PRODUCT_CODE  
		,A.ORDER_TYPE
		,ART.ARTICLE_NO
		--PURCHASE ORDER DETAILS
		,ISNULL(PO.PO_NO,'') AS PO_NO
		--,(CASE WHEN ISNULL(PO.PO_DT,'')='' THEN '' ELSE CONVERT(VARCHAR,ISNULL(PO.PO_DT,''),105) END) AS PO_DT 
		,CASE WHEN ISNULL(PO.PO_DT,'')='1900-01-01' THEN '' ELSE CONVERT(VARCHAR,PO.PO_DT,105) END AS PO_DT 
		,ISNULL(PO.AC_NAME,'') AS SUPPLIER
		--PURCHASE DETAILS
		,COALESCE(PUR.MRR_NO,GPUR.MRR_NO,'') AS MRR_NO
		--,(CASE WHEN COALESCE(PUR.RECEIPT_DT,GPUR.RECEIPT_DT,'')='' THEN '' ELSE CONVERT(VARCHAR,COALESCE(PUR.RECEIPT_DT,GPUR.RECEIPT_DT,''),105) END) AS MRR_DT 
		,CASE WHEN COALESCE(PUR.RECEIPT_DT,GPUR.RECEIPT_DT,'')='1900-01-01' THEN '' ELSE CONVERT(VARCHAR,COALESCE(PUR.RECEIPT_DT,GPUR.RECEIPT_DT,''),105) END AS MRR_DT 
		,P1.PARA1_NAME ,P3.PARA3_NAME 
		INTO #ALLPENDINGORDERS
		FROM WSL_ORDER_DET A (NOLOCK)
		JOIN WSL_ORDER_MST B (NOLOCK) ON A.ORDER_ID=B.ORDER_ID
		JOIN ARTICLE ART(NOLOCK) ON A.ARTICLE_CODE=ART.ARTICLE_CODE
		JOIN PARA1 P1(NOLOCK) ON A.PARA1_CODE =P1.PARA1_CODE 
		JOIN PARA3 P3(NOLOCK) ON A.PARA3_CODE =P3.PARA3_CODE 
		JOIN CUSTDYM CUS(NOLOCK) ON B.CUSTOMER_CODE=CUS.CUSTOMER_CODE
		LEFT JOIN 
		(
			SELECT POM.PO_NO,POM.PO_DT,LM.AC_NAME,POD.PRODUCT_CODE
			FROM POM01106 POM(NOLOCK)
			JOIN POD01106 POD(NOLOCK) ON POM.PO_ID=POD.PO_ID
			JOIN LM01106 LM(NOLOCK) ON POM.AC_CODE=LM.AC_CODE
			WHERE POM.CANCELLED=0 AND ISNULL(POD.PRODUCT_CODE,'')<>''
		)PO ON A.PRODUCT_CODE=PO.PRODUCT_CODE
		LEFT JOIN 
		(
			SELECT PIM.MRR_NO,PIM.RECEIPT_DT,PID.PRODUCT_CODE
			FROM PIM01106 PIM(NOLOCK)
			JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
			WHERE PIM.CANCELLED=0 AND PIM.INV_MODE=1 AND ISNULL(PID.PRODUCT_CODE,'')<>''/*ONLY PARTY INVOICE*/
		)PUR ON A.PRODUCT_CODE=PUR.PRODUCT_CODE
		LEFT JOIN 
		(
			SELECT PIM.MRR_NO,PIM.RECEIPT_DT,PID.PRODUCT_CODE
			FROM PIM01106 PIM(NOLOCK)
			JOIN PID01106 PID(NOLOCK) ON PIM.MRR_ID=PID.MRR_ID
			WHERE PIM.CANCELLED=0 AND PIM.INV_MODE=2 /*ONLY GROUP INVOICE*/
		)GPUR ON A.PRODUCT_CODE=GPUR.PRODUCT_CODE
		LEFT JOIN 
		(
			SELECT CMM.CM_NO,CMM.CM_DT,CMM.CUSTOMER_CODE,CMM.PRODUCT_CODE
			FROM #ORDDLV CMM(NOLOCK)
		)SLS ON SLS.PRODUCT_CODE=(CASE WHEN A.ORDER_TYPE=1 THEN A.REF_PRODUCT_CODE ELSE A.PRODUCT_CODE END)
		AND SLS.CUSTOMER_CODE=B.CUSTOMER_CODE
		WHERE 
		B.CANCELLED=0 --ORDER IS NOT CANCELLED
		AND ISNULL(A.CANCELLED,0)=0 --ORDER ITEM IS NOT CANCELLED
		AND (@DORDER_DT='' OR B.ORDER_DT<=@DORDER_DT) --ORDER BOOKED TILL DATE
		AND (@CCUSTOMER_CODE='' OR B.CUSTOMER_CODE=@CCUSTOMER_CODE) --CUSTOMER FILTER
		AND (@BURGENT=0 OR B.URGENT= @BURGENT )  --URGENTORDER
		AND SLS.CM_NO IS NULL --ORDER THAT IS NOT DELEIVERED
		
		---ORDERS PENDING FOR PO 
		SELECT  USER_CUSTOMER_CODE,CUSTOMER_NAME,MOBILE,REF_NO,ORDER_NO,CONVERT(VARCHAR,ORDER_DT,105) AS ORDER_DT,CONVERT(VARCHAR,DELIVERY_DT,105) AS DELIVERY_DT,DELIVERY_DAYS
			   ,PRODUCT_CODE,ARTICLE_NO,'PO PENDING' AS ITEM_STATUS,TRAIL_DT,SUPPLIER,
			   PARA1_NAME ,PARA3_NAME 
		FROM #ALLPENDINGORDERS
		WHERE ORDER_TYPE=0
		AND ((@BPOPENDING=0 AND 1=2) OR (@BPOPENDING=1 AND PO_NO=''))
		ORDER BY USER_CUSTOMER_CODE,ORDER_DT,ORDER_NO,PRODUCT_CODE
		
		---ORDERS PENDING FOR PUR WHOSE PO IS RAISED
		SELECT  USER_CUSTOMER_CODE,CUSTOMER_NAME,MOBILE,REF_NO,ORDER_NO,ORDER_DT,DELIVERY_DT,DELIVERY_DAYS
			   ,PRODUCT_CODE,ARTICLE_NO,PO_NO,PO_DT,SUPPLIER,'PUR PENDING' AS ITEM_STATUS,
			   TRAIL_DT ,PARA1_NAME ,PARA3_NAME 
		FROM #ALLPENDINGORDERS
		WHERE ORDER_TYPE=0
		AND ((@BPURPENDING=0 AND 1=2) OR (@BPURPENDING=1 AND PO_NO<>'' AND MRR_NO=''))
		ORDER BY USER_CUSTOMER_CODE,ORDER_DT,ORDER_NO,PRODUCT_CODE
		
		---ORDERS PENDING FOR BILLING WHOSE PUR IS RAISED
		SELECT  USER_CUSTOMER_CODE,CUSTOMER_NAME,MOBILE,REF_NO,ORDER_NO,ORDER_DT,DELIVERY_DT,DELIVERY_DAYS
			   ,PRODUCT_CODE,ARTICLE_NO,PO_NO,PO_DT,SUPPLIER,MRR_NO,MRR_DT,'BILL PENDING' AS ITEM_STATUS,
			   TRAIL_DT,PARA1_NAME ,PARA3_NAME 
		FROM #ALLPENDINGORDERS
		WHERE ((@BBILLPENDING=0 AND 1=2) OR (@BBILLPENDING=1 AND MRR_NO<>''))
		ORDER BY USER_CUSTOMER_CODE,ORDER_DT,ORDER_NO,PRODUCT_CODE
END
--END OF PROCEDURE - SP3S_PENDING_RETAIL_ORDERS
