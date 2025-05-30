CREATE PROCEDURE SAVETRAN_LOCATTR_MST --(LocId 3 digit change by Sanjay:06-11-2024) 
(  
 @SOURCE  VARCHAR(100),   
 @DEST  VARCHAR(100),  
 @CONFIG  VARCHAR(100),  
 @cLocId VARchar(4)=''
)    
AS    
BEGIN    
DECLARE @CCMD NVARCHAR(MAX),@TABLE_NAME VARCHAR(100),@SNO VARCHAR(4),@ERROR VARCHAR(MAX)='',@STEP FLOAT    
,@PRINT_ON BIT=1,@CODE_LEN INT=15,@MAX VARCHAR(15)    
SET NOCOUNT ON    
    
BEGIN TRY    
BEGIN TRANSACTION    
SET @STEP=0    
SET @CCMD='DELETE ['+@SOURCE+'] WHERE ISNULL(KEY_NAME,'''')='''';'    
IF @PRINT_ON=1 PRINT @CCMD  
EXEC SP_EXECUTESQL @CCMD    
     

SET @STEP=1    
SET @CCMD='IF NOT EXISTS(SELECT TOP 1 COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME=''GEN_KEY_CODE'' AND TABLE_NAME='''+@SOURCE+''')    
ALTER TABLE ['+@SOURCE+'] ADD GEN_KEY_CODE VARCHAR('+CAST(@CODE_LEN AS VARCHAR)+');'  
PRINT  @CCMD   
EXEC SP_EXECUTESQL @CCMD    


    
SET @STEP=1.1    

UPDATE CONFIG_LOCATTR SET TABLE_CAPTION=@CONFIG WHERE TABLE_NAME=@DEST  
    
	  
    
SET @STEP=3    
SET @SNO=SUBSTRING(@DEST,8,CHARINDEX('_',@DEST)-8)    
IF @PRINT_ON=1 PRINT '3--'+CHAR(13)+@SNO    
   
	  
  
DECLARE @CNEWKEYVAL VARCHAR(100),@LOC VARCHAR(10),@TAB VARCHAR(100),
@NAME VARCHAR(100),@CODE VARCHAR(100),@ID VARCHAR(100)  
if @cLOcId=''
	SELECT TOP 1 @LOC=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
else
	set @loc=@cLocId

if @loc=''
	SELECT TOP 1 @LOC=VALUE FROM CONFIG (nolock) WHERE CONFIG_OPTION='LOCATION_ID'

IF ISNULL(@LOC,'')=''
 BEGIN
    SET @ERROR =  ' LOCATION ID CAN NOT BE BLANK  '  
	GOTO END_PROC    
 END

IF OBJECT_ID('tempdb..##ATTR') IS NOT NULL DROP TABLE ##ATTR  
SET @CCMD=N'SELECT * INTO ##ATTR FROM ['+@SOURCE+'] WHERE KEY_CODE LIKE ''LATER%'''  
EXEC(@CCMD)  
  
DECLARE ATTR CURSOR FOR 
SELECT TABLE_NAME,KEY_NAME,KEY_CODE FROM ##ATTR  
OPEN ATTR  
FETCH NEXT FROM ATTR INTO @TAB,@NAME,@CODE  
WHILE @@FETCH_STATUS=0  
  BEGIN  
     SET @ID=REPLACE(@TAB,'_MST','_KEY_CODE') 
	 SET @ID=REPLACE(@ID,'LOC','') 

     EXEC GETNEXTKEY @TAB,@ID,7,@LOC,1,'',1,@CNEWKEYVAL OUTPUT    
     SET @CCMD=N'UPDATE ['+@SOURCE+'] SET GEN_KEY_CODE='''+@CNEWKEYVAL+''' WHERE KEY_CODE='''+@CODE+''''  
    	PRINT  @CCMD
	EXEC(@CCMD) 
	
     FETCH NEXT FROM ATTR INTO @TAB,@NAME,@CODE  
  END  
CLOSE ATTR  
DEALLOCATE ATTR  
    

 --SET @CCMD=N'SELECT KEY_CODE=CASE WHEN KEY_CODE LIKE ''LATER%'' OR KEY_CODE LIKE ''%-%'' THEN GEN_KEY_CODE ELSE KEY_CODE END,KEY_NAME,GEN_KEY_CODE,KEY_ALIAS,ISNULL(INACTIVE,0)INACTIVE FROM ['+@SOURCE+'] (NOLOCK)'  
 --   	PRINT  @CCMD
	--EXEC(@CCMD) 
  
SET @STEP=6    
SET @CCMD='MERGE ['+@DEST+'] D '+CHAR(13)    
SET @CCMD+='USING (SELECT KEY_CODE=CASE WHEN KEY_CODE LIKE ''LATER%'' OR KEY_CODE LIKE ''%-%'' THEN GEN_KEY_CODE ELSE KEY_CODE END,KEY_NAME,GEN_KEY_CODE,KEY_ALIAS,ISNULL(INACTIVE,0)INACTIVE FROM ['+@SOURCE+']) S ON D.ATTR'+@SNO+'_KEY_CODE=S.KEY_CODE '+CHAR(13)    
SET @CCMD+='WHEN MATCHED THEN UPDATE SET D.ATTR'+@SNO+'_KEY_NAME=S.KEY_NAME,D.ATTR'+@SNO+'_ALIAS=S.KEY_ALIAS,D.ATTR'+@SNO+'_INACTIVE=S.INACTIVE '+CHAR(13)    
SET @CCMD+='WHEN NOT MATCHED THEN INSERT (ATTR'+@SNO+'_KEY_CODE,ATTR'+@SNO+'_KEY_NAME,ATTR'+@SNO+'_ALIAS,ATTR'+@SNO+'_INACTIVE) VALUES(S.KEY_CODE,S.KEY_NAME,S.KEY_ALIAS,S.INACTIVE);'    
IF @PRINT_ON=1 PRINT '6--'+CHAR(13)+@CCMD    
EXEC SP_EXECUTESQL @CCMD    
    
    
SET @STEP=7    
SET @CCMD='IF OBJECT_ID('''+@SOURCE+''') IS NOT NULL DROP TABLE ['+@SOURCE+'];'    
IF @PRINT_ON=1 PRINT '7--'+CHAR(13)+@CCMD    
EXEC SP_EXECUTESQL @CCMD    
END TRY    
    
BEGIN CATCH    
  SET @ERROR='PROCEDURE SAVETRAN_ATTR_MST: STEP- ' + LTRIM(CAST(@STEP AS VARCHAR)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()    
END CATCH    
      
END_PROC:    
  
IF @@TRANCOUNT>0 AND @ERROR=''    
   COMMIT    
ELSE    
   ROLLBACK    
SELECT @ERROR ERR_MSG         

SET NOCOUNT OFF    
END--PROC 
