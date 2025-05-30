CREATE PROCEDURE SP_PRODUCT_DETAILFORGDN  
(    
	@CPRODUCTCODE VARCHAR(50)    
)    
--WITH ENCRYPTION

AS     
BEGIN    
 SELECT TOP 1 M.MEMO_TYPE AS ER_FLAG,M.AC_CODE, F.UOM_TYPE, H.SECTION_NAME, G.SUB_SECTION_NAME, A.PRODUCT_CODE,    
 CONVERT(VARCHAR, M.INV_DT, 105) AS INV_DT, M.MRR_NO AS INV_NO,
 LM.AC_NAME,   A.GROSS_PURCHASE_PRICE AS PURCHASE_PRICE,     
 A.MRP, B.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, B.ARTICLE_DESC, C.PARA1_NAME, D.PARA2_NAME,         
 E.PARA3_NAME, P4.PARA4_NAME, P5.PARA5_NAME , P6.PARA6_NAME, F.UOM_CODE, F.UOM_NAME  
 , ISNULL(J.FREIGHT,0) AS FREIGHT 
 , CASE WHEN ISNULL(A.GROSS_PURCHASE_PRICE ,0) = 0 THEN 0 ELSE 
  CONVERT(NUMERIC(14,3),100-((((A.GROSS_PURCHASE_PRICE-(A.GROSS_PURCHASE_PRICE * (A.DISCOUNT_PERCENTAGE/100)))))-(((A.GROSS_PURCHASE_PRICE-(A.GROSS_PURCHASE_PRICE * (A.DISCOUNT_PERCENTAGE/100)))))*M.DISCOUNT_PERCENTAGE/100)*100/A.GROSS_PURCHASE_PRICE) END AS [DISCOUNT_PERCENTAGE]
 , ISNULL(A.DISCOUNT_AMOUNT,0) AS DISCOUNT_AMOUNT  
 , ISNULL(A.TAX_AMOUNT,0) AS TAX_AMOUNT  
 , I.FORM_ID  
 , I.FORM_NAME  
 , ISNULL(J.OTHER_CHARGES,0) AS OTHER_CHARGES  
 , I.TAX_PERCENTAGE, ISNULL(PMT.QUANTITY_IN_STOCK,0) AS [QUANTITY_IN_STOCK],    
  A.GROSS_PURCHASE_PRICE AS RATE ,      
 ISNULL(B.DT_CREATED,'') AS [ART_DT_CREATED],ISNULL(E.DT_CREATED,'') AS [PARA3_DT_CREATED] ,  
 M.MRR_NO ,B.CODING_SCHEME,B.DISCON,LM.CITY  
 ,ISNULL(J.ROUND_OFF,0) AS ROUND_OFF ,ISNULL(J.EXCISE_DUTY_AMOUNT,0) AS EXCISE_DUTY_AMOUNT,  
 A.WHOLESALE_PRICE AS WS_PRICE,
 M.INV_NO AS CHALLAN_NO,
 M.BILL_NO,
 A.GROSS_PURCHASE_PRICE,
 B.ALIAS AS ARTICLE_ALIAS
   
 FROM PID01106 A  
 JOIN PIM01106 M (NOLOCK)  ON M.MRR_ID=A.MRR_ID     
 JOIN ARTICLE B (NOLOCK) ON A.ARTICLE_CODE = B.ARTICLE_CODE          
 JOIN PARA1 C (NOLOCK) ON A.PARA1_CODE = C.PARA1_CODE          
 JOIN PARA2 D (NOLOCK) ON A.PARA2_CODE = D.PARA2_CODE         
 JOIN PARA3 E (NOLOCK) ON A.PARA3_CODE = E.PARA3_CODE          
 JOIN PARA4 P4 (NOLOCK) ON A.PARA4_CODE = P4.PARA4_CODE          
 JOIN PARA5 P5 (NOLOCK) ON A.PARA5_CODE = P5.PARA5_CODE          
 JOIN PARA6 P6 (NOLOCK) ON A.PARA6_CODE = P6.PARA6_CODE   
 JOIN UOM F (NOLOCK) ON B.UOM_CODE = F.UOM_CODE         
 JOIN SECTIOND G (NOLOCK) ON B.SUB_SECTION_CODE = G.SUB_SECTION_CODE          
 JOIN SECTIONM H (NOLOCK) ON G.SECTION_CODE = H.SECTION_CODE         
 JOIN FORM I (NOLOCK) ON A.FORM_ID = I.FORM_ID     
       
 LEFT OUTER JOIN SKU_OH J (NOLOCK) ON A.PRODUCT_CODE = J.PRODUCT_CODE        
 LEFT OUTER JOIN PMT01106 PMT (NOLOCK) ON PMT.PRODUCT_CODE=A.PRODUCT_CODE   
 JOIN LMV01106 LM (NOLOCK) ON M.AC_CODE = LM.AC_CODE     
 LEFT OUTER JOIN EAN_SYNC EN (NOLOCK) ON EN.PRODUCT_CODE=A.PRODUCT_CODE  
 WHERE A.PRODUCT_CODE = @CPRODUCTCODE  
 ORDER BY M.INV_DT  DESC
END
