CREATE VIEW VW_WL_CHALLANINLIST 
--WITH ENCRYPTION
AS     
SELECT   
 A.CHALLAN_ID AS 'CHALLAN_ID',  
 A.CHALLAN_NO AS 'MST_MEMO_NO',  
 A.CHALLAN_DT AS 'MST_XN_DT',  
 A.CHECKED_BY AS 'MST_CHECKED_BY',  
 A.REMARKS AS 'MST_REMARKS',  
 A.RECEIPT_DT AS 'MST_RECEIPT_DT',  
 A.DISCOUNT_AMOUNT AS 'CAL_DISCOUNT_PERCENTAGE',  
 A.DISCOUNT_AMOUNT AS 'CAL_DISCOUNT_AMOUNT',  
 A.OTHER_CHARGES AS 'CAL_OTHER_CHARGES',  
 A.FREIGHT AS 'CAL_FREIGHT',  
 A.TAX_PERCENTAGE AS 'CAL_TAX_PERCENTAGE',  
 A.TAX_AMOUNT AS 'CAL_BILL_LEVEL_TAX_AMOUNT',  
 A.ROUND_OFF AS 'CAL_ROUND_OFF',  
 A.TOTAL_AMOUNT AS 'CAL_TOTAL_AMOUNT',  
 A.SUBTOTAL AS 'CAL_SUBTOTAL',  
 B.FORM_NAME AS 'MST_FORM_NAME',  
 A.THROUGH AS 'MST_THROUGH',  
 A.GRLR_NO AS 'MST_GRLR_NO',  
 A.GRLR_DATE AS 'MST_GRLR_DATE',  
 C.USERNAME AS 'MST_USERNAME',  
 I.DEPT_ID + '-' + I.DEPT_NAME AS 'MST_SOURCE_DEPT_NAME',  
 J.DEPT_ID + '-' + J.DEPT_NAME AS 'MST_TARGET_DEPT_NAME',  
 A.FIN_YEAR AS 'MST_FIN_YEAR',
 
 D.PRODUCT_CODE AS 'PRODUCT_CODE',  
 F.ARTICLE_CODE AS 'ARTICLE_CODE',  
 F.ARTICLE_DESC AS 'ARTICLE_DESC',  
 F.ARTICLE_NAME AS 'ARTICLE_NAME',  
 F.ARTICLE_NO AS 'ARTICLE_NO',  
 G.SUB_SECTION_NAME AS 'SUB_SECTION_NAME',  
 H.SECTION_NAME AS 'SECTION_NAME',  
 P1.PARA1_NAME AS 'PARA1_NAME',  
 P2.PARA2_NAME AS 'PARA2_NAME',  
 P3.PARA3_NAME AS 'PARA3_NAME',  
 D.QUANTITY AS 'CAL_QUANTITY',  
 U.UOM_NAME AS 'UOM_NAME',  
 E.MRP AS 'CAL_MRP',  
 D.RATE AS 'CAL_RATE',  
 '' AS 'TAX_STATUS',  
 '' AS 'CAL_ITEM_LEVEL_TAX_AMOUNT',  
 D.QUANTITY * D.RATE AS 'CAL_AMOUNT'  
FROM CIM01106 A  
JOIN FORM (NOLOCK) B ON A.FORM_ID = B.FORM_ID  
JOIN USERS (NOLOCK) C ON A.USER_CODE = C.USER_CODE  
JOIN CID01106 (NOLOCK) D ON A.CHALLAN_ID = D.CHALLAN_ID  
JOIN SKU (NOLOCK) E ON D.PRODUCT_CODE = E.PRODUCT_CODE  
JOIN ARTICLE (NOLOCK) F ON E.ARTICLE_CODE = F.ARTICLE_CODE  
JOIN SECTIOND (NOLOCK) G ON F.SUB_SECTION_CODE = G.SUB_SECTION_CODE  
JOIN SECTIONM (NOLOCK) H ON G.SECTION_CODE = H.SECTION_CODE  
JOIN PARA1 (NOLOCK) P1 ON E.PARA1_CODE = P1.PARA1_CODE  
JOIN PARA2 (NOLOCK) P2 ON E.PARA2_CODE = P2.PARA2_CODE  
JOIN PARA3 (NOLOCK) P3 ON E.PARA3_CODE = P3.PARA3_CODE  
JOIN UOM (NOLOCK) U ON F.UOM_CODE = U.UOM_CODE  
JOIN LOCATION (NOLOCK) I ON LEFT(A.CHALLAN_NO ,2) = I.DEPT_ID  
JOIN LOCATION (NOLOCK) J ON SUBSTRING(A.CHALLAN_NO ,3,2) = J.DEPT_ID  
--*********************************************** END OF VIEW VW_WL_CHALLANINLIST
