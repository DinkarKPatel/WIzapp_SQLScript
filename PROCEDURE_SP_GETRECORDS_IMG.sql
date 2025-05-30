CREATE PROCEDURE SP_GETRECORDS_IMG      
--WITH ENCRYPTION
AS      
BEGIN      
 DECLARE  @IMAGEREC TABLE  (PRODUCT_CODE VARCHAR(500),SKU_DT_CREATED VARCHAR(40) ,  
         ARTICLE_NO VARCHAR(100),ART_DT_CREATED  VARCHAR(40) ,       
         PARA3_NAME VARCHAR(500),PARA3_DT_CREATED  VARCHAR(40),   
         QTY NUMERIC(14,2))  
    
 INSERT INTO @IMAGEREC(PRODUCT_CODE,SKU_DT_CREATED ,ARTICLE_NO ,ART_DT_CREATED , PARA3_NAME ,  
 PARA3_DT_CREATED, QTY )  
 SELECT TOP 1 A.PRODUCT_CODE,A.DT_CREATED AS [SKU_DT_CREATED] ,       
 B.ARTICLE_NO,B.DT_CREATED AS [ART_DT_CREATED] ,       
 C.PARA3_NAME,C.DT_CREATED AS [PARA3_DT_CREATED]   ,ISNULL(PMT.QUANTITY_IN_STOCK,0) AS QTY    
 FROM SKU A (NOLOCK)       
 JOIN ARTICLE B (NOLOCK)  ON B.ARTICLE_CODE=A.ARTICLE_CODE       
 JOIN PARA3 C (NOLOCK)  ON C.PARA3_CODE=A.PARA3_CODE       
 JOIN PMT01106 PMT (NOLOCK) ON PMT.PRODUCT_CODE=A.PRODUCT_CODE    
 WHERE A.PRODUCT_CODE NOT IN (SELECT PRODUCT_CODE FROM IMG_LIST (NOLOCK))       
 AND A.PRODUCT_CODE NOT IN(SELECT IMG_NAME FROM IMG_NOTFOUND (NOLOCK) )       
 AND ISNULL(PMT.QUANTITY_IN_STOCK,0)>0  
 AND  
 ( 
 (ISNULL(A.DT_CREATED,'') <> '' AND LEFT(A.DT_CREATED,4) <> '1900')
 OR
 (ISNULL(B.DT_CREATED,'') <> '' AND LEFT(B.DT_CREATED,4) <> '1900')
 OR
 (ISNULL(C.DT_CREATED,'') <> '' AND LEFT(C.DT_CREATED,4) <> '1900')
 )
 ORDER BY [SKU_DT_CREATED] DESC,[ART_DT_CREATED] DESC,[PARA3_DT_CREATED] DESC     
 
    
 --IF @@ROWCOUNT=0    
 --BEGIN    
 -- INSERT INTO @IMAGEREC(PRODUCT_CODE,SKU_DT_CREATED ,ARTICLE_NO ,ART_DT_CREATED , PARA3_NAME ,  PARA3_DT_CREATED, QTY )  
 -- SELECT TOP 1 A.PRODUCT_CODE,A.DT_CREATED AS [SKU_DT_CREATED] ,       
 -- B.ARTICLE_NO,B.DT_CREATED AS [ART_DT_CREATED] ,       
 -- C.PARA3_NAME,C.DT_CREATED AS [PARA3_DT_CREATED]   ,ISNULL(PMT.QUANTITY_IN_STOCK,0) AS QTY    
 -- FROM SKU  A (NOLOCK)       
 -- JOIN ARTICLE B (NOLOCK)  ON B.ARTICLE_CODE=A.ARTICLE_CODE       
 -- JOIN PARA3 C (NOLOCK)  ON C.PARA3_CODE=A.PARA3_CODE       
 -- LEFT OUTER JOIN PMT01106 PMT (NOLOCK) ON PMT.PRODUCT_CODE=A.PRODUCT_CODE    
 -- WHERE A.PRODUCT_CODE NOT IN (SELECT PRODUCT_CODE FROM IMG_LIST(NOLOCK))       
 -- AND A.PRODUCT_CODE NOT IN(SELECT IMG_NAME FROM IMG_NOTFOUND (NOLOCK) )       
 -- ORDER BY [SKU_DT_CREATED] DESC,[ART_DT_CREATED] DESC,[PARA3_DT_CREATED] DESC    
 --END    
  
 SELECT * FROM @IMAGEREC  
   
END
