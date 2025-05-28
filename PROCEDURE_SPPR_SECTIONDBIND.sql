CREATE PROCEDURE [DBO].[SPPR_SECTIONDBIND]           
(          
 @NMODE     INT, --(0)-FILL DROPDOWN 'ARTILCE_NO, SECTION' (1) - VIEW FILTER DATA (2) - VIEW ARTILCE_NO WISE          
 @SUB_SECTION_CODE  VARCHAR(9)='',          
 @INACTIVE    VARCHAR(5)='',          
 @ERRMSG_OUT    VARCHAR(MAX)='' OUT         
)          
AS          
BEGIN          
 DECLARE @CSTEP INT, @CCMD NVARCHAR(MAX)          
           
 BEGIN TRY          
  SET @ERRMSG_OUT = ''          
            
  SET @CSTEP = 5          
  IF (@NMODE=0)          
  BEGIN          
   SET @CCMD=N'SELECT SUB_SECTION_NAME + ''- '' + SECTION_NAME AS SUB_SECTION_NAMES,* FROM  SECTIOND  AS SD  INNER JOIN SECTIONM AS SM ON SD.SECTION_CODE=SM.SECTION_CODE           
              ORDER BY SUB_SECTION_NAME '          
   PRINT @CCMD          
   EXEC SP_EXECUTESQL @CCMD          
  END          
            
  SET @CSTEP = 10          
  IF (@NMODE=1)          
  BEGIN          
   SET @CCMD=N'SELECT * FROM SECTIOND AS SD      
               JOIN SECTIONM AS SM ON SD.SECTION_CODE=SM.SECTION_CODE      
               WHERE SD.SUB_SECTION_CODE  = ''' + @SUB_SECTION_CODE + '''       
               ORDER BY SECTION_NAME '          
            
   PRINT @CCMD          
   EXEC SP_EXECUTESQL @CCMD          
  END          
            
        
            
 END TRY            
 BEGIN CATCH            
  SET @ERRMSG_OUT='ERROR: [P]: SPPR_SECTIONM, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()          
  PRINT @ERRMSG_OUT          
            
  GOTO END_PROC            
 END CATCH             
          
END_PROC:            
 IF  ISNULL(@ERRMSG_OUT,'')=''           
  SET @ERRMSG_OUT = ''          
END
