CREATE PROC SP_LABELPRINT_VARIABLELIST   
(  
 @CMODULENAME VARCHAR(50)  
) 
--WITH ENCRYPTION
AS  
BEGIN  
 DECLARE @CCMD NVARCHAR(4000),  
   @CMSTTABLE VARCHAR(100),  
   @CDETTABLE VARCHAR(100),  
   @CMRP VARCHAR(100),  
   @CWSP VARCHAR(100),  
   @CKEYCOL VARCHAR(100)  
   
   SET @CMRP = 'A.MRP'
   SET @CWSP = 'A.WHOLESALE_PRICE AS WS_PRICE'
       
 SELECT @CMSTTABLE = (CASE WHEN @CMODULENAME = 'POM' THEN 'POM01106'   
         WHEN @CMODULENAME = 'PUR' THEN 'PIM01106'  
         WHEN @CMODULENAME = 'OPS' THEN 'OPS_MST'  
         WHEN @CMODULENAME = 'BRP' THEN 'IRM01106'
          END),  
   @CDETTABLE = (CASE WHEN @CMODULENAME = 'POM' THEN 'POD01106'   
         WHEN @CMODULENAME = 'PUR' THEN 'PID01106'  
         WHEN @CMODULENAME = 'OPS' THEN 'OPS_DET'  
         WHEN @CMODULENAME = 'BRP' THEN 'IRD01106'
           END),            
   @CKEYCOL =   (CASE WHEN @CMODULENAME = 'POM' THEN 'PO_ID'   
         WHEN @CMODULENAME = 'PUR' THEN 'MRR_ID'  
         WHEN @CMODULENAME = 'OPS' THEN 'MEMO_ID'  
    WHEN @CMODULENAME = 'BRP' THEN 'IRM_MEMO_ID'
           END)  
           
   IF(@CMODULENAME = 'BRP')
   BEGIN
	   SET @CMRP = 'A.NEW_MRP AS MRP'
	   SET @CWSP = 'A.NEW_WSP AS WS_PRICE'   
   END
           
 IF ISNULL(@CMSTTABLE,'') = ''  
  GOTO END_PROC  

  
  PRINT @CMRP
  PRINT @CWSP

 SET @CCMD =       
  'SELECT A.PRODUCT_CODE, ARTICLE_NO, ARTICLE_NAME, SUB_SECTION_NAME, SECTION_NAME, PARA1_NAME, PARA2_NAME,     
    PARA3_NAME, PARA4_NAME, PARA5_NAME, PARA6_NAME, ' + @CMRP + ', ' + @CWSP + ', PARA2_ORDER, D.ARTICLE_DESC,     
    LM.AC_NAME, SKU.INV_NO AS INV_NO, SKU.INV_DT, SKU.INV_NO AS CHALLAN_NO, LM.ALIAS,
    CONVERT(VARCHAR(MAX),'''') AS INV_DETAILS,CONVERT(NUMERIC(10,2),0) AS QTY ,
    SKU.BARCODE_CODING_SCHEME AS CODING_SCHEME, D.DISCON,SKU.PURCHASE_PRICE,SKU.INV_DT AS RECEIPT_DT,
    SKU.INV_DT AS VANDOR_BILL_DT,U.UOM_NAME
  FROM ' + @CDETTABLE + ' A  
  JOIN ' + @CMSTTABLE + ' C ON C.' + @CKEYCOL + ' = A.' + @CKEYCOL + '  
  JOIN ARTICLE D ON A.ARTICLE_CODE = D.ARTICLE_CODE  
  LEFT OUTER JOIN SECTIOND E ON E.SUB_SECTION_CODE = D.SUB_SECTION_CODE        
  LEFT OUTER JOIN SECTIONM F ON F.SECTION_CODE = E.SECTION_CODE         
  LEFT OUTER JOIN PARA1 G ON G.PARA1_CODE = A.PARA1_CODE         
  LEFT OUTER JOIN PARA2 H ON H.PARA2_CODE = A.PARA2_CODE        
  LEFT OUTER JOIN PARA3 I ON I.PARA3_CODE = A.PARA3_CODE        
  LEFT OUTER JOIN PARA4 J ON J.PARA4_CODE = A.PARA4_CODE        
  LEFT OUTER JOIN PARA5 K ON K.PARA5_CODE = A.PARA5_CODE        
  LEFT OUTER JOIN PARA6 L ON L.PARA6_CODE = A.PARA6_CODE        
  JOIN SKU ON SKU.PRODUCT_CODE=A.PRODUCT_CODE
  JOIN LM01106 LM ON SKU.AC_CODE=LM.AC_CODE
  JOIN UOM U (NOLOCK) ON U.UOM_CODE=D.UOM_CODE  
  WHERE 1=2'    
  
 PRINT @CCMD      
 IF @CCMD <> ''      
 BEGIN      
  EXEC SP_EXECUTESQL @CCMD      
 END      
  
END_PROC:  
  
END
