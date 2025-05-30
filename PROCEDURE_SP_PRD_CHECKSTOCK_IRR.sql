CREATE PROCEDURE SP_PRD_CHECKSTOCK_IRR  
(       
 @CPRODUCTCODE VARCHAR(50),        
 @BDONOTCHECKSTOCK BIT=0,        
 @CDEPT_ID  CHAR(7)='',      
 @CWHERE VARCHAR(100)=''  
 )     
-- ---WITH ENCRYPTION    
       
AS        
BEGIN        
 DECLARE @NSTKQTY NUMERIC(10,3),@CPRDCODE VARCHAR(100)          
         
 IF @CPRDCODE IS NULL      
  SELECT @CPRDCODE=PRODUCT_CODE FROM PRD_SKU WHERE PRODUCT_CODE=@CPRODUCTCODE          
         
 IF @CPRDCODE IS NULL          
  SELECT 'SELECTED PRODUCT NOT FOUND....PLEASE CHECK' AS RETMSG          
 ELSE            
 BEGIN      
  SELECT @NSTKQTY = QUANTITY_IN_STOCK FROM PRD_PMT WHERE  PRODUCT_CODE=@CPRDCODE 
  AND DEPARTMENT_ID=@CDEPT_ID  AND QUANTITY_IN_STOCK>0        
      
  IF @BDONOTCHECKSTOCK=0        
   SELECT @BDONOTCHECKSTOCK = STOCK_NA FROM PRD_SKU A         
   JOIN ARTICLE B ON B.ARTICLE_CODE=A.ARTICLE_CODE AND A.PARA1_CODE=B.PARA1_CODE AND A.PARA2_CODE=B.PARA2_CODE     
   WHERE  A.PRODUCT_CODE=@CPRDCODE        
                                       
 
   
  IF ISNULL(@BDONOTCHECKSTOCK,0)<>1
  BEGIN      
  IF ISNULL(@NSTKQTY,0)>0         
   SELECT '' AS RETMSG          
  ELSE          
   SELECT 'PRODUCT CODE NOT IN STOCK....PLEASE CHECK' AS RETMSG          
  END   
  ELSE
  BEGIN
     SELECT '' AS RETMSG     
  
  END       
  --SELECT * FROM PMV01106 WHERE  PRODUCT_UID=@CPRODUCTCODE AND (DEPT_ID=@CDEPT_ID OR DEPT_ID='')         
  SELECT  A.PRODUCT_CODE,A.PRODUCT_UID, A.ARTICLE_CODE, B.ARTICLE_NO, B.ARTICLE_NAME, A.PARA1_CODE,          
  C.PARA1_NAME, A.PARA2_CODE, D.PARA2_NAME, A.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,             
  PMT.DEPARTMENT_ID, B.CODING_SCHEME,  B.INACTIVE, PMT.QUANTITY_IN_STOCK,          
  A.PURCHASE_PRICE,A.MRP AS MRP,CAST(A.MRP AS NUMERIC(10,2)) AS OLD_MRP,      
  A.WS_PRICE,        
  '' AS SCHEME_ID, SM.SECTION_NAME, SD.SUB_SECTION_NAME,          
  A.PARA4_CODE,A.PARA5_CODE,A.PARA6_CODE,          
  PARA4_NAME,PARA5_NAME,PARA6_NAME,B.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE],          
  B.DT_CREATED AS [ART_DT_CREATED],F.DT_CREATED AS [PARA3_DT_CREATED],A.DT_CREATED AS [SKU_DT_CREATED],          
  B.STOCK_NA,    
  F1.FORM_ID,F1.FORM_NAME,F1.TAX_PERCENTAGE,A.MRP AS RATE,A.MRP AS JOB_RATE   ,
  '000' AS BIN_ID ,
  '' AS BIN_NAME,
  '' AS VENDOR_EAN_NO,
  '' AS ONLINE_BAR_CODE,
  A.INV_DT,
  A.INV_NO,
  A.RECEIPT_DT 
  FROM PRD_PMT PMT            
  JOIN PRD_SKU A ON A.PRODUCT_CODE=PMT.PRODUCT_CODE  AND A.PRODUCT_UID=PMT.PRODUCT_UID       
  JOIN ARTICLE B ON A.ARTICLE_CODE = B.ARTICLE_CODE --AND A.PARA1_CODE=B.PARA1_CODE AND A.PARA2_CODE=B.PARA2_CODE         
  JOIN SECTIOND SD ON B.SUB_SECTION_CODE = SD.SUB_SECTION_CODE          
  JOIN SECTIONM SM ON SD.SECTION_CODE = SM.SECTION_CODE          
  JOIN PARA1 C ON A.PARA1_CODE = C.PARA1_CODE            
  JOIN PARA2 D ON A.PARA2_CODE = D.PARA2_CODE            
  JOIN PARA3 F ON A.PARA3_CODE = F.PARA3_CODE            
  JOIN PARA4 G ON A.PARA4_CODE = G.PARA4_CODE            
  JOIN PARA5 H ON A.PARA5_CODE = H.PARA5_CODE            
  JOIN PARA6 I ON A.PARA6_CODE = I.PARA6_CODE            
  JOIN UOM E ON B.UOM_CODE = E.UOM_CODE       
  JOIN FORM F1 ON A.FORM_ID=F1.FORM_ID       
  WHERE  PMT.PRODUCT_CODE=@CPRDCODE 
 -- AND (@CWHERE='' OR A.PRODUCT_UID=@CWHERE)
  AND PMT.QUANTITY_IN_STOCK >0
  AND (PMT.DEPARTMENT_ID=@CDEPT_ID OR PMT.DEPARTMENT_ID='')          
 END          
     
END
