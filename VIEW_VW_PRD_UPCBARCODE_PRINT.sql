CREATE VIEW   VW_PRD_UPCBARCODE_PRINT
AS
SELECT B.MEMO_NO,B.MEMO_DT ,B.MEMO_ID,
       B.ARTICLE_SET_CODE ,AR.ARTICLE_NO ,AR.ARTICLE_NAME ,
       A.PARA1_CODE ,P1.PARA1_NAME ,
       A.PARA2_CODE  ,P2.PARA2_NAME,
       A.PRODUCT_CODE,
       SD.SUB_SECTION_NAME,
       SM.SECTION_NAME ,
       BM.ORDER_NO,BM.ORDER_DT,
       LM.AC_NAME ,
       BM.REMARKS 
FROM PRD_UPCPMT A
JOIN PRD_WO_MST B ON A.WO_ID =B.MEMO_ID 
JOIN (SELECT * FROM PRD_WO_ORDERS ) BO ON BO.MEMO_ID =B.MEMO_ID 
JOIN BUYER_ORDER_MST BM ON BM.ORDER_ID =BO.ORDER_ID 
JOIN LM01106 LM ON LM.AC_CODE =BM.AC_CODE 
JOIN ARTICLE (NOLOCK) AR ON B.ARTICLE_SET_CODE=AR.ARTICLE_CODE    
JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=AR.SUB_SECTION_CODE    
JOIN SECTIONM SM ON SD.SECTION_CODE=SM.SECTION_CODE   
JOIN PARA1 P1 ON P1.PARA1_CODE=A.PARA1_CODE    
JOIN PARA2 P2 ON P2.PARA2_CODE=A.PARA2_CODE     
WHERE B.CANCELLED =0
