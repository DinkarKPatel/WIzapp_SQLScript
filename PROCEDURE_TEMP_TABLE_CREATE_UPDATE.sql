CREATE PROC TEMP_TABLE_CREATE_UPDATE        
(        
@MODE AS INT,        
@SPID AS VARCHAR(100)='',       
@PARA_CODE AS VARCHAR(500)='',        
@OLD_PARA_NAME AS VARCHAR(500)='',        
@NEW_PARA_NAME AS VARCHAR(500)=''        
)        
AS BEGIN        
        
DECLARE @TSQL1 AS VARCHAR(MAX)        
DECLARE @TSQL2 AS VARCHAR(MAX)          
        
IF(@MODE=1)-- TO CREATE TEMP_TABLE_SPIDNO        
BEGIN        
 SET @SPID=@@SPID        
         
 SET @TSQL1='TEMP_TABLE_'+@SPID+''        
 IF OBJECT_ID(@TSQL1,'U') IS NOT NULL        
  BEGIN        
   SET @TSQL2='DROP TABLE '+@TSQL1+''        
   EXEC (@TSQL2)        
  END        
 -----------------------------------------        
 SET @TSQL2=        
 '        
 CREATE TABLE TEMP_TABLE_'+@SPID+'(        
  [PARA_CODE] [NVARCHAR](500) NULL,        
  [OLD_PARA_NAME] [NVARCHAR](500) NULL,        
  [NEW_PARA_NAME] [NVARCHAR](500) NULL        
 )         
 '        
 EXEC (@TSQL2)    
 SELECT @SPID      
END        
        
IF(@MODE=2)-- TO INSERT RECORD IN TEMP_TABLE_SPIDNO        
BEGIN        
        
 SET @TSQL1='TEMP_TABLE_'+@SPID+''        
 SET @TSQL2='INSERT INTO '+@TSQL1+' (PARA_CODE,OLD_PARA_NAME,NEW_PARA_NAME)        
    VALUES ('''+@PARA_CODE+''','''+@OLD_PARA_NAME+''','''+@NEW_PARA_NAME+''')'        
    
 EXEC (@TSQL2)    
         
         
END        
        
END 
--END OF PROCEDURE TEMP_TABLE_CREATE_UPDATE
