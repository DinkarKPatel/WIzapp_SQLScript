CREATE VIEW VW_STRECON_FILTER      
--WITH ENCRYPTION
AS         
SELECT D.AC_NAME AS MST_SUPPLIER,      
  AR.AREA_NAME MST_AREA_NAME,CT.CITY AS MST_CITY,S.STATE AS MST_STATE,      
  C.ARTICLE_NO AS MST_ARTICLE_NO,P1.PARA1_NAME,P2.PARA2_NAME,P3.PARA3_NAME,      
  G.SECTION_NAME ,F.SUB_SECTION_NAME,      
  A.QUANTITY_IN_STOCK, B.MRP,  A.DEPT_ID, B.PRODUCT_CODE,A.REP_ID    
FROM PMT01106 A      
JOIN SKU B ON A.PRODUCT_CODE = B.PRODUCT_CODE       
JOIN ARTICLE C (NOLOCK) ON C.ARTICLE_CODE=B.ARTICLE_CODE      
JOIN LMV01106 D(NOLOCK) ON D.AC_CODE=B.AC_CODE          
JOIN PARA1 P1 (NOLOCK) ON P1.PARA1_CODE=B.PARA1_CODE      
JOIN PARA2 P2 (NOLOCK) ON P2.PARA2_CODE=B.PARA2_CODE      
JOIN PARA3 P3 (NOLOCK) ON P3.PARA3_CODE=B.PARA3_CODE      
JOIN SECTIOND F(NOLOCK) ON F.SUB_SECTION_CODE=C.SUB_SECTION_CODE        
JOIN SECTIONM G (NOLOCK) ON G.SECTION_CODE=F.SECTION_CODE    
JOIN AREA AR (NOLOCK) ON AR.AREA_CODE=D.AREA_CODE      
JOIN CITY CT (NOLOCK) ON CT.CITY_CODE=AR.CITY_CODE      
JOIN [STATE] S (NOLOCK) ON S.STATE_CODE=CT.STATE_CODE
