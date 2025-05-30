CREATE VIEW VW_RETAILPS_PRINT_DET

AS
	SELECT A.CM_ID, A.PRODUCT_CODE,A.QUANTITY,A.MRP,A.NET,A.DISCOUNT_PERCENTAGE,A.DISCOUNT_AMOUNT,
	A.TAX_TYPE,'T'+(CASE WHEN A.TAX_PERCENTAGE=0 THEN 'F' WHEN ROUND(A.TAX_PERCENTAGE,0)=A.TAX_PERCENTAGE THEN LTRIM(RTRIM(STR(A.TAX_PERCENTAGE)))
							 ELSE LTRIM(RTRIM(STR(A.TAX_PERCENTAGE,6,2))) END) AS TAX_STATUS,A.TAX_PERCENTAGE,A.TAX_AMOUNT,A.EMP_CODE
	,ARTICLE_NO,ARTICLE_NAME,PARA1_NAME,PARA2_NAME,PARA3_NAME,UOM_NAME
	,SECTION_NAME,SUB_SECTION_NAME,PARA4_NAME,PARA5_NAME,PARA6_NAME,EMP_NAME,EMP_ALIAS
	,0 AS SR_NO,A.TS,S.PRODUCT_NAME    
	FROM RPS_DET A
	JOIN RPS_MST B ON B.CM_ID=A.CM_ID
--	JOIN PMV01106 C ON C.PRODUCT_CODE=A.PRODUCT_CODE --- OPTIMIZATION AFTER REMOVING VIEWS
	JOIN SKU S ON A.PRODUCT_CODE = S.PRODUCT_CODE     
	JOIN ARTICLE ART ON S.ARTICLE_CODE = ART.ARTICLE_CODE      
	JOIN SECTIOND SD ON ART.SUB_SECTION_CODE = SD.SUB_SECTION_CODE    
	JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE    
	JOIN PARA1 C ON S.PARA1_CODE = C.PARA1_CODE      
	JOIN PARA2 D ON S.PARA2_CODE = D.PARA2_CODE      
	JOIN PARA3 F ON S.PARA3_CODE = F.PARA3_CODE      
	JOIN PARA4 G ON S.PARA4_CODE = G.PARA4_CODE      
	JOIN PARA5 H ON S.PARA5_CODE = H.PARA5_CODE      
	JOIN PARA6 I ON S.PARA6_CODE = I.PARA6_CODE      
	JOIN UOM   E ON ART.UOM_CODE = E.UOM_CODE 	
	JOIN EMPLOYEE EMP ON EMP.EMP_CODE=A.EMP_CODE
