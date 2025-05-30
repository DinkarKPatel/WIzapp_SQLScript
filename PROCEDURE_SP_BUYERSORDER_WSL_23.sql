CREATE PROCEDURE SP_BUYERSORDER_WSL_23
@CMEMOID VARCHAR(40),  
@CWHERE VARCHAR(500),  
@CFINYEAR VARCHAR(10),  
@NNAVMODE NUMERIC(2,0),
@CARTICLECODE CHAR(9)='',  
@CPARA2CODE CHAR(7)='',
@DTWHERE DATETIME ='',
@cLocId VARCHAR(5)=''
--WITH ENCRYPTION
 
AS    
BEGIN 
 DECLARE @NCOUNT INT     
 SET @NCOUNT = 0   
  
   
 SELECT @NCOUNT = COUNT(*) FROM ART_DET A    
 WHERE A.ARTICLE_CODE = @CARTICLECODE AND A.PARA2_CODE = @CPARA2CODE    
       
 PRINT @NCOUNT    
       
 IF ( @NCOUNT > 0 )     
       
        
      SELECT TOP 1 A.PURCHASE_PRICE, A.MRP, A.WS_PRICE FROM ART_DET A     
      WHERE A.ARTICLE_CODE = @CARTICLECODE AND A.PARA2_CODE = @CPARA2CODE    
      
 ELSE    
      
    SELECT TOP 1 A.PURCHASE_PRICE, A.MRP, A.WHOLESALE_PRICE AS WS_PRICE  
    FROM  ARTICLE A   
    WHERE A.ARTICLE_CODE = @CARTICLECODE 
END