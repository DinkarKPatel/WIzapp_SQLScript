CREATE PROCEDURE SP_CHECKSTOCK_CON  
 @CPRODUCTCODE VARCHAR(50), 
 @CDEPT_ID  CHAR(4)=''
--  WITH ENCRYPTION
AS  
BEGIN  
	DECLARE @NSTKQTY NUMERIC(10,3),@CPRDCODE VARCHAR(100)    
 
	--(dinkar) Replace  left(memoid,2) to Location_code 
	
	SELECT @CPRDCODE=PRODUCT_CODE FROM SKU WHERE PRODUCT_CODE=@CPRODUCTCODE    
   
   
	IF @CPRDCODE IS NULL    
		SELECT 'SELECTED BARCODE NOT FOUND....PLEASE CHECK' AS RETMSG    
	ELSE      
	BEGIN
		DECLARE @NITEMTYPE NUMERIC(1,0)
		
		SELECT @NITEMTYPE=SM.ITEM_TYPE FROM SKU A 
		JOIN ARTICLE B ON A.ARTICLE_CODE=B.ARTICLE_CODE
		JOIN SECTIOND SD ON SD.SUB_SECTION_CODE=B.SUB_SECTION_CODE
		JOIN SECTIONM SM ON SM.SECTION_CODE=SD.SECTION_CODE
		WHERE A.PRODUCT_CODE=@CPRODUCTCODE
		
		IF ISNULL(@NITEMTYPE,0)<>2 
		BEGIN
			SELECT 'BARCODE DOES NOT BELONG TO CONSUMABLE CATEGORY....PLEASE CHECK' AS RETMSG    
			RETURN
		END	
		
		SELECT @NSTKQTY = QUANTITY_IN_STOCK FROM PMT01106 (NOLOCK) WHERE  PRODUCT_CODE=@CPRDCODE
	                    
	 
	 
	 
		IF ISNULL(@NSTKQTY,0)>0
			SELECT '' AS RETMSG    
		ELSE    
			SELECT 'BARCODE NOT IN STOCK....PLEASE CHECK' AS RETMSG    
		    
		  
		SELECT  A.PRODUCT_CODE, B.ARTICLE_NO AS ITEM_CODE,B.ARTICLE_NAME AS ITEM_NAME , 
		B.ARTICLE_DESC AS ITEM_DESC, A.PARA1_CODE,    
		C.PARA1_NAME, A.PARA2_CODE, D.PARA2_NAME, A.PARA3_CODE, F.PARA3_NAME, E.UOM_NAME,       
		PMT.DEPT_ID, PMT.QUANTITY_IN_STOCK,    
		A.PURCHASE_PRICE,B.UOM_CODE,ISNULL(E.UOM_TYPE,0) AS [UOM_TYPE]   
		FROM SKU A   (NOLOCK)   
		LEFT OUTER JOIN  PMT01106 PMT (NOLOCK) ON A.PRODUCT_CODE=PMT.PRODUCT_CODE  
		JOIN ARTICLE  B  (NOLOCK) ON B.ARTICLE_CODE = A.ARTICLE_CODE
		JOIN PARA1 C  (NOLOCK) ON A.PARA1_CODE = C.PARA1_CODE      
		JOIN PARA2 D  (NOLOCK) ON A.PARA2_CODE = D.PARA2_CODE      
		JOIN PARA3 F  (NOLOCK) ON A.PARA3_CODE = F.PARA3_CODE		
		JOIN UOM E  (NOLOCK) ON B.UOM_CODE = E.UOM_CODE 
		WHERE  A.PRODUCT_CODE=@CPRDCODE
	END    
END
