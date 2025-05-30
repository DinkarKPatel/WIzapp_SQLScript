CREATE PROCEDURE SP_TH_PRODUCTCODE_NEW    
@NQUERYID NUMERIC (3,0) ,  
@CWHERE VARCHAR(50)    
--WITH ENCRYPTION

AS     
BEGIN  
IF @NQUERYID = 1    
GOTO PRODUCTCODELIST    
   
ELSE IF @NQUERYID = 2    
GOTO ARTICLELIST   

ELSE IF @NQUERYID = 3    
GOTO PARA3LIST   


 PRODUCTCODELIST:
 
  SELECT TOP 50 A.ARTICLE_CODE, A.ARTICLE_DESC, A.ARTICLE_NAME,A.ARTICLE_NO , A1.PRODUCT_CODE,A1.BARCODE_CODING_SCHEME AS CODING_SCHEME,      
  A1.PURCHASE_PRICE, A1.MRP,A1.WS_PRICE , A.MP_PERCENTAGE,A1.FIX_MRP ,D.SUB_SECTION_NAME,M.SECTION_NAME,
  A.ALIAS AS ARTICLE_ALIAS      
  FROM SKU  A1 (NOLOCK)      
  JOIN ARTICLE A (NOLOCK)   ON A.ARTICLE_CODE=A1.ARTICLE_CODE      
  JOIN SECTIOND D (NOLOCK) ON D.SUB_SECTION_CODE=A.SUB_SECTION_CODE      
  JOIN SECTIONM M (NOLOCK) ON M.SECTION_CODE=D.SECTION_CODE      
  WHERE  PRODUCT_CODE LIKE @CWHERE      
  ORDER BY PRODUCT_CODE  
  GOTO LAST
  
ARTICLELIST:
 
  SELECT TOP 50 A.ARTICLE_NO,A.ARTICLE_CODE,D.SUB_SECTION_NAME,M.SECTION_NAME,A.ARTICLE_DESC,A.ARTICLE_NAME,
  A.ALIAS AS ARTICLE_ALIAS          
  FROM ARTICLE A (NOLOCK)  
  JOIN SECTIOND D (NOLOCK) ON D.SUB_SECTION_CODE=A.SUB_SECTION_CODE      
  JOIN SECTIONM M (NOLOCK) ON M.SECTION_CODE=D.SECTION_CODE      
  WHERE A.INACTIVE=0 AND ARTICLE_NO LIKE @CWHERE      
  ORDER BY ARTICLE_NO  
  GOTO LAST
  
 PARA3LIST:
 
  SELECT TOP 50 A.PARA3_NAME, A.PARA3_CODE FROM PARA3 A    
  WHERE A.INACTIVE=0 AND PARA3_NAME LIKE @CWHERE      
  ORDER BY PARA3_NAME  
  GOTO LAST
  
  LAST:    
END
