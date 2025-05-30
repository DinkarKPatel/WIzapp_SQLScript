CREATE PROCEDURE SP_PRD_CUTTING_ORDER_DETAILS
(
 @CORDER_ID VARCHAR(100)
)
AS    
  
  IF OBJECT_ID ('TEMPDB..#TMPORDER','U') IS NOT NULL
     DROP TABLE #TMPORDER
     
  SELECT AR1.ARTICLE_NO AS FG_ARTICLE_NO,
         AR1.ARTICLE_NAME AS FG_ARTICLE_NAME,
         DET.QUANTITY AS FG_QTY,
         BM1.ORDER_NO AS BUYER_ORDER_NO,
         BM1.ORDER_DT AS BUYER_ORDER_DT,
         MST.MEMO_NO AS ORDER_NO,
		 MST.MEMO_DT  AS ORDER_DT,
		 PARA1.PARA1_CODE ,
		 PARA1.PARA1_NAME AS FG_COLOR,
		 PARA2.PARA2_CODE ,
		 PARA2.PARA2_NAME AS FG_SIZE,
		 MST.REMARKS AS FG_REMARKS,
		 AR.ARTICLE_NO AS COMPONENT,
		 C.ARTICLE_NO AS RM_NO,
		 C.ARTICLE_NAME AS RM_NAME,
		 RMP.PARA1_NAME AS RM_COLOR,
		 CAST(CONVERT(NUMERIC(10,3),A.AVG_QTY) AS VARCHAR(10))+' '+UOM.UOM_NAME AS AVG_QTY,
		 CAST(A.ADD_AVG_QTY AS VARCHAR(10))+' '+UOM.UOM_NAME AS ADD_AVG_QTY,
		 DET.QUANTITY,
		 CONVERT(NUMERIC(12,2),(A.AVG_QTY+ISNULL(A.ADD_AVG_QTY,0)) *(DET.QUANTITY))  AS TOTAL_QTY_CAL,
		 CAST(CONVERT(NUMERIC(12,2),(A.AVG_QTY+ISNULL(A.ADD_AVG_QTY,0)) *(DET.QUANTITY)) AS VARCHAR(10))+ ' '+UOM.UOM_NAME AS TOTAL_QTY,
		 UOM.UOM_NAME,
         COM.COMPANY_NAME,
         COM.LOGO_PATH,
         COM.ADDRESS1,
         COM.ADDRESS2,
         COM.CITY,
         COM.PHONES_FAX,
         LM.AC_NAME,
         MST.MEMO_ID AS ORDER_ID
    INTO #TMPORDER
	FROM PRD_WO_ART_BOM A (NOLOCK)      
	JOIN PRD_WO_DET B (NOLOCK) ON A.REF_ROW_ID = B.ROW_ID
	JOIN PRD_WO_MST MST (NOLOCK) ON B.MEMO_ID=MST.MEMO_ID
	JOIN ARTICLE AR (NOLOCK) ON AR.ARTICLE_CODE =B.ARTICLE_CODE
	JOIN ARTICLE AR1 (NOLOCK) ON AR1.ARTICLE_CODE =MST.ARTICLE_SET_CODE     
	JOIN PARA1 P1 (NOLOCK) ON A.PARA1_CODE=P1.PARA1_CODE
	JOIN PARA2 P2 (NOLOCK) ON A.PARA2_CODE=P2.PARA2_CODE
	JOIN
	(
	 SELECT PARA1_CODE,PARA2_CODE,REF_ROW_ID,SUM(QUANTITY) AS QUANTITY 
	 FROM PRD_WO_SUB_DET C
	 GROUP BY REF_ROW_ID,PARA1_CODE,PARA2_CODE
	) DET ON B.ROW_ID=DET.REF_ROW_ID
	JOIN ARTICLE C (NOLOCK) ON A.BOM_ARTICLE_CODE = C.ARTICLE_CODE 
	JOIN PARA1  (NOLOCK) ON DET.PARA1_CODE=PARA1.PARA1_CODE
	JOIN PARA2  (NOLOCK) ON DET.PARA2_CODE=PARA2.PARA2_CODE
	JOIN
	(
     SELECT MEMO_ID,ORDER_ID FROM PRD_WO_ORDERS A
     GROUP BY MEMO_ID,ORDER_ID
	)BM ON BM.MEMO_ID=MST.MEMO_ID
	JOIN BUYER_ORDER_MST BM1 ON BM.ORDER_ID=BM1.ORDER_ID
	JOIN LM01106 LM ON BM1.AC_CODE=LM.AC_CODE
	JOIN PARA1 RMP ON RMP.PARA1_CODE=A.PARA1_CODE
	JOIN UOM ON UOM.UOM_CODE=C.UOM_CODE
	JOIN COMPANY COM ON COM.COMPANY_CODE='01'
	WHERE  MST.MEMO_ID=@CORDER_ID
	
	
	
	SELECT A.*,
	B.COMP_QTY_PCS,B.COMP_QTY_MTR ,
	C.ORD_QTY_PCS,C.ORD_QTY_MTR
	FROM 
	#TMPORDER A
	JOIN 
	(
	 
	 SELECT  A.ORDER_ID,A.COMPONENT,A.PARA1_CODE,A.PARA2_CODE,
	 SUM(CASE WHEN UOM_NAME='PCS' THEN TOTAL_QTY_CAL ELSE 0 END)  AS COMP_QTY_PCS,
	 SUM(CASE WHEN UOM_NAME<>'PCS' THEN TOTAL_QTY_CAL ELSE 0 END)  AS COMP_QTY_MTR
	 FROM #TMPORDER A
	 GROUP BY A.ORDER_ID,A.COMPONENT,A.PARA1_CODE,A.PARA2_CODE
	) B ON A.ORDER_ID=B.ORDER_ID AND A.COMPONENT=B.COMPONENT
	AND A.PARA1_CODE =B.PARA1_CODE AND A.PARA2_CODE =B.PARA2_CODE 
	JOIN 
	(
	 
	 SELECT  A.ORDER_ID,A.PARA1_CODE,A.PARA2_CODE,
	 SUM(CASE WHEN UOM_NAME='PCS' THEN TOTAL_QTY_CAL ELSE 0 END) AS ORD_QTY_PCS,
	 SUM(CASE WHEN UOM_NAME<>'PCS' THEN TOTAL_QTY_CAL ELSE 0 END) AS ORD_QTY_MTR
	 FROM #TMPORDER A
	 GROUP BY A.ORDER_ID,A.PARA1_CODE,A.PARA2_CODE
	) C ON A.ORDER_ID=C.ORDER_ID AND A.PARA1_CODE=C.PARA1_CODE AND A.PARA2_CODE=C.PARA2_CODE
	ORDER BY A.ORDER_NO, A.COMPONENT,A.FG_COLOR,A.FG_SIZE,A.RM_NO
